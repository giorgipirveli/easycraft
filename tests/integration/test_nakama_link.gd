extends GutTest
## NakamaLink against the development server (server/dev.sh up; M4 early spike). The whole script
## is skipped when no Nakama answers on 127.0.0.1:7350, so the suite passes without Docker.

const NakamaProbe := preload("res://tests/integration/nakama_probe.gd")

const SERVER := {"scheme": "http", "host": OnlineConfig.DEFAULT_HOST, "port": OnlineConfig.DEFAULT_PORT}

var _links: Array[NakamaLink] = []


func should_skip_script():   # untyped like GutTest's own: "-> Variant" fails to parse in a full run
	var why: String = await NakamaProbe.why_not_up(self)
	return false if why == "" else why


func after_each() -> void:
	for link in _links:
		if is_instance_valid(link):
			await link.leave()
	_links.clear()


func _signed_in_link() -> NakamaLink:
	var link := NakamaLink.new()
	add_child(link)
	_links.append(link)
	var err := await link.sign_in(SERVER, DeviceId.generate())
	assert_eq(err, "", "signed in")
	return link


func test_signs_in_with_a_device_id_and_the_healthcheck_answers() -> void:
	var link := await _signed_in_link()
	assert_false(link.session.user_id.is_empty(), "an account for this device")
	var answer := await link.call_rpc("healthcheck")
	assert_eq(answer.get("ok"), true, "healthcheck: %s" % answer)
	assert_eq(answer.get("module"), "easycraft")
	assert_eq(answer.get("user_id"), link.session.user_id, "the server knows who asked")


func test_the_same_device_signs_in_to_the_same_account() -> void:
	var device := DeviceId.generate()
	var first := NakamaLink.new()
	add_child(first)
	_links.append(first)
	assert_eq(await first.sign_in(SERVER, device), "")
	var again := NakamaLink.new()
	add_child(again)
	_links.append(again)
	assert_eq(await again.sign_in(SERVER, device), "")
	assert_eq(again.session.user_id, first.session.user_id)


## The server's RPCs (M4 B, server/README.md) answer an empty request with a plain error code the
## game turns into words, never a crash or "not yet".
func test_the_server_rpcs_refuse_an_empty_request_with_an_error_code() -> void:
	var link := await _signed_in_link()
	var expected := {"redeem_code": "bad_request", "farm_collect": "bad_request", "report_user": "not_found"}
	for rpc: String in expected:
		var answer := await link.call_rpc(rpc, "{}")
		assert_eq(answer.get("ok"), false, rpc)
		assert_eq(answer.get("error"), expected[rpc], rpc)


func test_a_guest_joins_the_hosts_relayed_match_and_packets_cross_the_relay() -> void:
	var host := await _signed_in_link()
	assert_eq(await host.create_match(), "", "match created")
	assert_true(OnlineConfig.is_match_id(host.match_id()), "a match id: %s" % host.match_id())
	assert_eq(host.peer().get_unique_id(), 1, "the host is peer 1")
	var joined: Array[int] = []
	host.peer().peer_connected.connect(func(id: int) -> void: joined.append(id))

	var guest := await _signed_in_link()
	assert_eq(await guest.join_match(host.match_id()), "", "joined")
	var guest_id := guest.peer().get_unique_id()
	assert_gt(guest_id, 1, "the guest got its own peer id from the host")
	assert_eq(guest.peer().get_connection_status(), MultiplayerPeer.CONNECTION_CONNECTED)
	assert_eq(joined, [guest_id], "the host saw the guest arrive")

	var to_guest := PackedByteArray([1, 2, 3, 250])
	host.peer().set_target_peer(guest_id)
	host.peer().put_packet(to_guest)
	assert_true(await _wait_for_packet(guest.peer()), "a packet from the host arrived")
	assert_eq(guest.peer().get_packet_peer(), 1)
	assert_eq(guest.peer().get_packet(), to_guest)

	var to_host := PackedByteArray(range(200))
	guest.peer().set_target_peer(1)
	guest.peer().put_packet(to_host)
	assert_true(await _wait_for_packet(host.peer()), "a packet from the guest arrived")
	assert_eq(host.peer().get_packet_peer(), guest_id)
	assert_eq(host.peer().get_packet(), to_host)


func test_a_packet_bigger_than_the_servers_message_limit_crosses_in_pieces() -> void:
	var host := await _signed_in_link()
	assert_eq(await host.create_match(), "")
	var guest := await _signed_in_link()
	assert_eq(await guest.join_match(host.match_id()), "")
	var big := PackedByteArray()
	big.resize(600 * 1024)   # the host's voxel sync sent 537 KB at once when a guest joined
	for i in big.size():
		big[i] = (i * 31 + 7) % 256
	host.peer().set_target_peer(guest.peer().get_unique_id())
	host.peer().put_packet(big)
	host.peer().put_packet(PackedByteArray([42]))   # and what comes after it still arrives, in order
	assert_true(await _wait_for_packet(guest.peer()), "the big packet arrived")
	var got := guest.peer().get_packet()
	assert_eq(got.size(), big.size())
	assert_true(got == big, "byte for byte")   # (assert_eq would print 600 KB on a failure)
	assert_true(await _wait_for_packet(guest.peer()), "the next one too")
	assert_eq(guest.peer().get_packet(), PackedByteArray([42]))
	assert_true(host.socket.is_connected_to_host(), "the server kept the host's session")
	assert_gt(host.stats.max_sent, RelayPieces.PIECE_BYTES, "stats count Godot packets, before pieces")


func test_a_guest_who_leaves_takes_its_unread_packets_along() -> void:
	var host := await _signed_in_link()
	assert_eq(await host.create_match(), "")
	var guest := await _signed_in_link()
	assert_eq(await guest.join_match(host.match_id()), "")
	var guest_id := guest.peer().get_unique_id()
	var gone: Array[int] = []
	host.peer().peer_disconnected.connect(func(id: int) -> void: gone.append(id))
	guest.peer().set_target_peer(1)
	for i in 3:
		guest.peer().put_packet(PackedByteArray([i]))
	assert_true(await _wait_for_packet(host.peer()), "the guest's packets arrived")
	await guest.leave()
	var give_up := Time.get_ticks_msec() + 3000
	while gone.is_empty() and Time.get_ticks_msec() < give_up:
		await get_tree().process_frame
	assert_eq(gone, [guest_id], "the host heard the guest leave")
	assert_eq(host.peer().get_available_packet_count(), 0,
		"nothing left from a peer the multiplayer API no longer knows (\"!connected_peers.has(sender)\")")


func test_joining_a_match_that_is_not_there_fails_with_a_reason() -> void:
	var guest := await _signed_in_link()
	var err := await guest.join_match("3dcf6dca-ba73-4e08-a89e-8c538234f741.")
	assert_ne(err, "", "refused")


func _wait_for_packet(peer: MultiplayerPeer) -> bool:
	var give_up := Time.get_ticks_msec() + 3000
	while peer.get_available_packet_count() == 0 and Time.get_ticks_msec() < give_up:
		await get_tree().process_frame
	return peer.get_available_packet_count() > 0
