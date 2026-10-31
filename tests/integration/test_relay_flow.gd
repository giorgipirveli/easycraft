extends GutTest
## The relay link under load and after a drop (M4 Wave 1 A, spec §17.0), against the development
## server (skipped when no Nakama answers on 127.0.0.1:7350):
## - flow control: a burst far bigger than the WebSocket's buffer arrives whole and in order (the
##   socket used to drop what did not fit without a word);
## - bytes are counted per guest;
## - a guest who comes back (the same device, so the same account) gets its old peer id, so the host's
##   game goes on with the same player; also when the server has not noticed the old link is gone.

const NakamaProbe := preload("res://tests/integration/nakama_probe.gd")
const SERVER := {"scheme": "http", "host": OnlineConfig.DEFAULT_HOST, "port": OnlineConfig.DEFAULT_PORT}

var _links: Array[NakamaLink] = []


func should_skip_script():   # untyped like GutTest's own (see test_nakama_link.gd)
	var why: String = await NakamaProbe.why_not_up(self)
	return false if why == "" else why


func after_each() -> void:
	for link in _links:
		if is_instance_valid(link):
			await link.leave()
	_links.clear()


func _link(device: String = "", buffer: int = 0) -> NakamaLink:
	var link := NakamaLink.new()
	if buffer > 0:
		link.socket_buffer_bytes = buffer
	add_child(link)
	_links.append(link)
	assert_eq(await link.sign_in(SERVER, device if device != "" else DeviceId.generate()), "", "signed in")
	return link


func _wait(cond: Callable, seconds: float = 5.0) -> bool:
	var give_up := Time.get_ticks_msec() + int(seconds * 1000)
	while not cond.call() and Time.get_ticks_msec() < give_up:
		await get_tree().process_frame
	return cond.call()


func test_a_burst_bigger_than_the_socket_buffer_arrives_whole_and_in_order() -> void:
	var host := await _link("", 64 * 1024)
	assert_eq(await host.create_match(), "")
	var guest := await _link()
	assert_eq(await guest.join_match(host.match_id()), "")
	var gid := guest.peer().get_unique_id()
	host.peer().set_target_peer(gid)
	var room := {"bytes": 0}   # the socket's buffer is full (on this PC the kernel takes everything)
	host.bridge.room_of = func() -> int: return room.bytes
	for i in 40:   # 40 × 20 KB = 800 KB in one frame
		var p := PackedByteArray()
		p.resize(20 * 1024)
		p.fill(i)
		host.peer().put_packet(p)
	host.peer().put_packet(PackedByteArray([99]))   # a small one after them must not overtake
	await wait_frames(5)
	assert_gt(host.backlog(), 800 * 1024, "all of it waits in line on the host")
	assert_eq(guest.peer().get_available_packet_count(), 0, "nothing was sent into a full buffer")
	room.bytes = 64 * 1024   # the network drains a little each frame
	var got: Array[int] = []
	var all_in := func() -> bool:
		while guest.peer().get_available_packet_count() > 0:
			got.append(guest.peer().get_packet()[0])
		return got.size() >= 41
	assert_true(await _wait(all_in, 30.0), "every packet arrived (%d of 41)" % got.size())
	var expected: Array[int] = []
	for i in 40:
		expected.append(i)
	expected.append(99)
	assert_eq(got, expected, "in order")
	assert_eq(host.backlog(), 0, "nothing left waiting")
	assert_eq(int(host.stats.refused), 0, "the socket never had to refuse one")


func test_the_link_counts_the_bytes_it_sends_each_guest() -> void:
	var host := await _link()
	assert_eq(await host.create_match(), "")
	var guest := await _link()
	assert_eq(await guest.join_match(host.match_id()), "")
	var gid := guest.peer().get_unique_id()
	host.peer().set_target_peer(gid)
	host.peer().put_packet(PackedByteArray([1, 2, 3, 4, 5]))
	host.peer().set_target_peer(0)
	host.peer().put_packet(PackedByteArray([1, 2, 3]))   # to everyone: counts for this guest too
	assert_eq(int(host.stats.sent_to.get(gid, 0)), 8)
	await wait_frames(5)
	assert_gt(int(host.stats.wire_bytes), 8, "base64 and JSON on the wire")


func test_small_packets_of_one_frame_share_one_message_and_keep_their_order() -> void:
	var host := await _link()
	assert_eq(await host.create_match(), "")
	var guest := await _link()
	assert_eq(await guest.join_match(host.match_id()), "")
	await wait_frames(5)
	var before := int(host.stats.messages)
	for i in 20:   # in one frame
		host.peer().set_target_peer(guest.peer().get_unique_id() if i % 2 else 0)   # to it, to everyone
		host.peer().put_packet(PackedByteArray([i]))
	var got: Array[int] = []
	var all_in := func() -> bool:
		while guest.peer().get_available_packet_count() > 0:
			got.append(guest.peer().get_packet()[0])
		return got.size() >= 20
	assert_true(await _wait(all_in), "all 20 arrived")
	assert_eq(got, Array(range(20), TYPE_INT, "", null), "in order")
	assert_eq(int(host.stats.messages) - before, 1, "one message: the only other player is everyone else")


func test_with_two_guests_packets_for_each_keep_the_order_of_everything() -> void:
	var host := await _link()
	assert_eq(await host.create_match(), "")
	var a := await _link()
	assert_eq(await a.join_match(host.match_id()), "")
	var b := await _link()
	assert_eq(await b.join_match(host.match_id()), "")
	await wait_frames(5)
	var ids := [a.peer().get_unique_id(), b.peer().get_unique_id()]
	for i in 30:   # to a, to b, to everyone, ...
		host.peer().set_target_peer([ids[0], ids[1], 0][i % 3])
		host.peer().put_packet(PackedByteArray([i]))
	var got_a: Array[int] = []
	var got_b: Array[int] = []
	var all_in := func() -> bool:
		while a.peer().get_available_packet_count() > 0:
			got_a.append(a.peer().get_packet()[0])
		while b.peer().get_available_packet_count() > 0:
			got_b.append(b.peer().get_packet()[0])
		return got_a.size() >= 20 and got_b.size() >= 20
	assert_true(await _wait(all_in), "each got its 20")
	var want_a: Array[int] = []
	var want_b: Array[int] = []
	for i in 30:
		if i % 3 != 1:
			want_a.append(i)
		if i % 3 != 0:
			want_b.append(i)
	assert_eq(got_a, want_a)
	assert_eq(got_b, want_b)


func test_a_guest_who_comes_back_gets_its_old_peer_id() -> void:
	var host := await _link()
	assert_eq(await host.create_match(), "")
	var device := DeviceId.generate()
	var first := await _link(device)
	assert_eq(await first.join_match(host.match_id()), "")
	var gid := first.peer().get_unique_id()
	var events: Array[String] = []
	host.peer().peer_disconnected.connect(func(id: int) -> void: events.append("gone %d" % id))
	host.peer().peer_connected.connect(func(id: int) -> void: events.append("back %d" % id))
	await first.leave()
	assert_true(await _wait(func() -> bool: return events.size() >= 1), "the host saw it go")
	var again := await _link(device)
	assert_eq(await again.join_match(host.match_id()), "")
	assert_eq(again.peer().get_unique_id(), gid, "the same peer id: the same player on the host")
	assert_eq(events, ["gone %d" % gid, "back %d" % gid])


func test_a_guest_back_before_the_server_saw_its_old_link_go_takes_its_place() -> void:
	var host := await _link()
	assert_eq(await host.create_match(), "")
	var device := DeviceId.generate()
	var old := await _link(device)
	assert_eq(await old.join_match(host.match_id()), "")
	var gid := old.peer().get_unique_id()
	var events: Array[String] = []
	host.peer().peer_disconnected.connect(func(id: int) -> void: events.append("gone %d" % id))
	host.peer().peer_connected.connect(func(id: int) -> void: events.append("back %d" % id))
	var again := await _link(device)   # the old link is still in the match
	assert_eq(await again.join_match(host.match_id()), "")
	assert_eq(again.peer().get_unique_id(), gid)
	assert_eq(events, ["gone %d" % gid, "back %d" % gid], "the old connection is replaced")
	await old.leave()   # the old link's leave arrives late: the player must stay connected
	await get_tree().create_timer(1.0).timeout
	assert_eq(events.size(), 2, "the late leave of the old link changes nothing: %s" % [events])
	again.peer().set_target_peer(1)
	again.peer().put_packet(PackedByteArray([9]))
	assert_true(await _wait(func() -> bool: return host.peer().get_available_packet_count() > 0))
	assert_eq(host.peer().get_packet_peer(), gid)
