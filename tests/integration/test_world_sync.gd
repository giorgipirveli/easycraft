extends GutTest
## World sync by edits (M4 Wave 1 A, spec §17.0), end to end in one process: a host world and a guest
## world of the same seed, the host's packets handed straight to the guest. The guest generates its
## terrain itself and gets only the host's edits: chunk lists when a chunk comes into its view (the
## host's VoxelViewer for peer GUEST), then single changes. Its world must equal the host's, block
## for block, around a secret too (secrets, trees, caves and ores all come from the seed).

const SEED := 20260924
const GUEST := 5
const BOX := Vector3i(48, 32, 48)

var host: WorldService
var guest: WorldService
var nodes: Array[Node] = []
var sent: Array[int] = []   # packet sizes, in order
var dir := ""
var _physics_rate := Engine.physics_ticks_per_second


func before_each() -> void:
	sent = []
	nodes = []
	dir = "user://test_world_sync_%d" % OS.get_process_id()


func after_each() -> void:
	Engine.physics_ticks_per_second = _physics_rate
	for n in nodes:
		if is_instance_valid(n):
			n.free()
	host = null
	guest = null
	_delete_dir(dir)


func _delete_dir(path: String) -> void:
	var d := DirAccess.open(path)
	if d == null:
		return
	for f in d.get_files():
		d.remove(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _world(save_dir: String, client: bool) -> WorldService:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup(save_dir, SEED, client)
	add_child(w)
	nodes.append(w)
	return w


func _viewer(at: Vector3, peer: int = 0, distance: int = 48) -> VoxelViewer:
	var v := VoxelViewer.new()
	v.view_distance = distance
	v.requires_visuals = false
	v.requires_collisions = false
	if peer > 0:
		v.set_network_peer_id(peer)
		v.requires_data_block_notifications = true
	add_child(v)
	nodes.append(v)
	v.global_position = at
	return v


## The host's packets go straight to the guest (or are kept when there is no guest world yet).
func _connect(h: WorldService, at: Vector3) -> void:
	h.sync.backlog_of = func() -> int: return 0
	h.sync.position_of = func(_peer: int) -> Vector3: return at
	h.sync.send = func(_peer: int, packet: PackedByteArray) -> void:
		sent.append(packet.size())
		if guest != null:
			guest.sync.receive(packet)


func _loaded(w: WorldService, origin: Vector3i, size: Vector3i) -> bool:
	for c: Vector3i in [Vector3i.ZERO, Vector3i(size.x - 1, 0, 0), Vector3i(0, size.y - 1, size.z - 1), size - Vector3i.ONE]:
		if not w.is_editable(origin + c):
			return false
	return true


func _differences(origin: Vector3i, size: Vector3i) -> Dictionary:
	return EditLog.diff(guest.copy_box(origin, size), host.copy_box(origin, size))


## The middle of the first secret next to the world spawn: the check box holds generated secrets.
func _secret_spot(w: WorldService) -> Vector3i:
	var c := w.spawn_column()
	var rules := SecretRules.new(SEED, w.generator_shape())
	for s: Dictionary in rules.secrets_in_area(SecretRules.area_of(c.x, c.y)):
		return (Vector3i(s.lo) + Vector3i(s.hi)) / 2
	return Vector3i(c.x, w.surface_height(c.x, c.y), c.y)


## The lead (2026-09-30): the house's own cells can be edited (loaded and meshed) before it is built: the area waited for
## round the spot did not always hold the house's corner yet under load, so its set_block did nothing (1 run in 7:
## "the house is built" failed, and so did everything after it: nothing was saved, compared or sent).
func _house_place_ready(w: WorldService, at: Vector3i) -> void:
	await wait_until(func() -> bool: return w.is_editable(at) and w.is_editable(at + Vector3i(4, 3, 4)), 30.0,
		"the house's place can be edited")


func _build_house(w: WorldService, at: Vector3i) -> Array[Vector3i]:
	var cells: Array[Vector3i] = []
	for x in 5:
		for z in 5:
			for y in 4:
				if x == 0 or z == 0 or x == 4 or z == 4:
					var p := at + Vector3i(x, y, z)
					w.set_block(p, BlockIds.BRICK)
					cells.append(p)
	for x in 3:   # and a hole in the ground next to it
		w.set_block(at + Vector3i(6 + x, -1, 0), BlockIds.AIR)
	return cells


## Asks `pred` at the start of every frame (before any node's _process) until it holds; false after `seconds`.
func _until_each_frame(pred: Callable, seconds: float) -> bool:
	var until := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		if pred.call():
			return true
		await get_tree().process_frame
	return false


func _settle(frames: int = 5) -> void:
	await wait_frames(frames)
	await wait_until(func() -> bool: return host.sync.pending(GUEST) == 0, 15.0, "the host sent everything")
	await wait_frames(3)


func test_a_guest_builds_its_terrain_itself_and_gets_nothing_for_untouched_chunks() -> void:
	host = _world("", false)
	guest = _world("", true)
	var at := Vector3(_secret_spot(host))
	_connect(host, at)
	host.sync.guest_ready(GUEST)
	_viewer(at, GUEST)
	var origin := Vector3i(at) - BOX / 2
	await wait_until(func() -> bool: return _loaded(host, origin, BOX) and _loaded(guest, origin, BOX), 30.0, "both worlds load")
	await _settle()
	assert_eq(_differences(origin, BOX), {}, "the same terrain, secrets included, from the seed alone")
	assert_eq(sent.size(), 0, "no packets: nothing was edited")
	for child in guest.terrain().get_children() + host.terrain().get_children():
		assert_false(child is VoxelTerrainMultiplayerSynchronizer, "the old synchronizer that sent every block is gone")


func test_a_guests_world_equals_the_hosts_after_edits_before_and_after_it_came() -> void:
	host = _world("", false)
	var at := _secret_spot(host)
	_viewer(Vector3(at))   # the host's own player
	var origin := at - BOX / 2
	await wait_until(func() -> bool: return _loaded(host, origin, BOX), 30.0, "the host's world loads")
	await _house_place_ready(host, at + Vector3i(3, 0, 3))
	_build_house(host, at + Vector3i(3, 0, 3))
	host.set_block(at, BlockIds.GLASS)   # right inside the secret
	guest = _world("", true)
	_connect(host, Vector3(at))
	host.sync.guest_ready(GUEST)
	_viewer(Vector3(at), GUEST)
	await wait_until(func() -> bool: return _loaded(guest, origin, BOX), 30.0, "the guest's world loads")
	await _settle()
	assert_eq(_differences(origin, BOX), {}, "the lists made the guest's world the host's")
	# single changes while the guest is there: a new block, a changed one, and an undo
	host.set_block(at + Vector3i(0, 6, 0), BlockIds.RED)
	host.set_block(at + Vector3i(3, 0, 3), BlockIds.GLASS)
	var generated := host.get_block(at + Vector3i(-4, 0, -4))
	host.set_block(at + Vector3i(-4, 0, -4), BlockIds.BLUE)
	host.set_block(at + Vector3i(-4, 0, -4), generated)
	await _settle()
	assert_eq(_differences(origin, BOX), {}, "single changes too")
	var total := 0
	for s in sent:
		total += s
	assert_lt(total, 2000, "about 70 edited cells cost a few hundred bytes, not the chunks' 8 KB each")
	gut.p("world sync: %d packets, %d bytes" % [sent.size(), total])


func test_edits_from_an_earlier_session_reach_the_guest_by_a_diff() -> void:
	host = _world(dir, false)
	var at := _secret_spot(host)
	var origin := at - BOX / 2
	var v := _viewer(Vector3(at))
	await wait_until(func() -> bool: return _loaded(host, origin, BOX), 30.0, "the host's world loads")
	await _house_place_ready(host, at + Vector3i(-6, 0, 2))
	var house := _build_house(host, at + Vector3i(-6, 0, 2))
	await host.save_and_wait()
	nodes.erase(host)
	host.free()
	v.free()
	host = _world(dir, false)   # the next session: the log knows nothing, the save has the house
	_viewer(Vector3(at))
	await wait_until(func() -> bool: return _loaded(host, origin, BOX), 30.0, "the saved world loads")
	assert_eq(host.get_block(house[0]), BlockIds.BRICK, "the save kept the house")
	guest = _world("", true)
	_connect(host, Vector3(at))
	host.sync.guest_ready(GUEST)
	_viewer(Vector3(at), GUEST)
	await wait_until(func() -> bool: return _loaded(guest, origin, BOX), 30.0, "the guest's world loads")
	await _settle()
	assert_gt(host.sync.stats.diffs, 0, "the saved chunks were compared with the generator")
	assert_eq(_differences(origin, BOX), {})


## M4 Wave 2 A2: saved chunks are compared on worker threads; a change the host makes to a chunk
## while its comparison runs must still reach the guest (it is replayed over the result).
func test_a_change_while_a_saved_chunk_is_compared_off_the_main_thread_reaches_the_guest() -> void:
	host = _world(dir, false)
	var at := _secret_spot(host)
	var origin := at - BOX / 2
	var v := _viewer(Vector3(at))
	await wait_until(func() -> bool: return _loaded(host, origin, BOX), 30.0, "the host's world loads")
	await _house_place_ready(host, at + Vector3i(-6, 0, 2))
	var house := _build_house(host, at + Vector3i(-6, 0, 2))
	assert_eq(host.get_block(house[0]), BlockIds.BRICK, "the house is built")
	await host.save_and_wait()
	nodes.erase(host)
	host.free()
	v.free()
	host = _world(dir, false)
	_viewer(Vector3(at))
	await wait_until(func() -> bool: return _loaded(host, origin, BOX), 30.0, "the saved world loads")
	assert_eq(host.get_block(house[0]), BlockIds.BRICK, "the save kept the house")
	guest = _world("", true)
	_connect(host, Vector3(at))
	host.sync.guest_ready(GUEST)
	_viewer(Vector3(at), GUEST)
	# The frame spikes agent (2026-09-30): a comparison lives from one frame's WorldSync._process (started) to a later
	# one's (collected), a few ms; GUT's wait_until asks at the physics rate and missed every one about 1 run in 4
	# (then diffing()[0] on an empty array). Asked at the start of every frame it cannot miss one; the physics rate is
	# made slow here so a check at that rate would miss the window nearly every run (it did: 2 of 3).
	Engine.physics_ticks_per_second = 4
	var comparing: bool = await _until_each_frame(func() -> bool: return not host.sync.diffing().is_empty(), 30.0)
	Engine.physics_ticks_per_second = _physics_rate
	assert_true(comparing, "a saved chunk is being compared")
	if not comparing:
		var house_chunk := EditLog.chunk_of(at + Vector3i(-6, 0, 2))
		gut.p("DIAG stats=%s house_chunk=%s knows=%s edits=%s pending=%s host_block=%s" % [host.sync.stats, house_chunk,
			host.sync._log.knows(house_chunk), host.sync._log.edit_count(house_chunk) if host.sync._log.knows(house_chunk) else -1,
			host.sync.pending(GUEST), host.get_block(at + Vector3i(-6, 0, 2))])
		return
	var chunk: Vector3i = host.sync.diffing()[0]
	var cell := chunk * EditLog.CHUNK + Vector3i(8, 8, 8)
	host.set_block(cell, BlockIds.GLASS)   # while the worker compares its chunk
	await wait_until(func() -> bool: return guest.is_editable(cell), 30.0, "the guest has that chunk")
	await _settle()
	assert_eq(guest.get_block(cell), BlockIds.GLASS, "the change made during the comparison is on the guest")
	var o := chunk * EditLog.CHUNK
	assert_eq(EditLog.diff(guest.copy_box(o, Vector3i.ONE * 16), host.copy_box(o, Vector3i.ONE * 16)), {})
	assert_eq(_differences(origin, BOX), {})


## M4 Wave 2 A2 (found by the net test's rejoin): Voxel Tools tells about a chunk entering a
## viewer's area once; a viewer taken out and put back in the same frame is not told again. The host
## remembers which chunks came into each guest's view, also before its client_ready.
func test_chunks_that_came_into_view_before_the_guest_was_ready_are_sent() -> void:
	host = _world("", false)
	var at := _secret_spot(host)
	var origin := at - BOX / 2
	_viewer(Vector3(at))
	await wait_until(func() -> bool: return _loaded(host, origin, BOX), 30.0, "the host's world loads")
	await _house_place_ready(host, at + Vector3i(3, 0, 3))
	_build_house(host, at + Vector3i(3, 0, 3))
	_connect(host, Vector3(at))
	_viewer(Vector3(at), GUEST)   # the guest's player arrives on the host before its world is ready
	await wait_until(func() -> bool: return host.sync.stats.entered > 100, 15.0, "the guest's chunks came into view")
	await wait_frames(10)
	guest = _world("", true)
	host.sync.guest_ready(GUEST)
	await wait_until(func() -> bool: return _loaded(guest, origin, BOX), 30.0, "the guest's world loads")
	await _settle()
	assert_eq(_differences(origin, BOX), {}, "the house reached the guest")


func test_a_guest_that_comes_back_gets_its_world_again() -> void:
	host = _world("", false)
	var at := _secret_spot(host)
	var origin := at - BOX / 2
	_viewer(Vector3(at))
	await wait_until(func() -> bool: return _loaded(host, origin, BOX), 30.0, "the host's world loads")
	await _house_place_ready(host, at + Vector3i(3, 0, 3))
	_build_house(host, at + Vector3i(3, 0, 3))
	guest = _world("", true)
	_connect(host, Vector3(at))
	host.sync.guest_ready(GUEST)
	_viewer(Vector3(at), GUEST)
	await wait_until(func() -> bool: return _loaded(guest, origin, BOX), 30.0, "the guest's world loads")
	await _settle()
	assert_eq(_differences(origin, BOX), {})
	# The guest's link drops: its player (and viewer) stay on the host, which builds on meanwhile.
	host.sync.guest_gone(GUEST)
	nodes.erase(guest)
	guest.free()
	guest = null
	host.set_block(at + Vector3i(0, 6, 0), BlockIds.YELLOW)
	await wait_frames(5)
	# It comes back with a new world generated from the seed, and nothing of the host's edits.
	guest = _world("", true)
	host.sync.guest_ready(GUEST)
	await wait_until(func() -> bool: return _loaded(guest, origin, BOX), 30.0, "the guest's new world loads")
	await _settle()
	assert_eq(guest.get_block(at + Vector3i(0, 6, 0)), BlockIds.YELLOW, "the edit made while it was away")
	assert_eq(_differences(origin, BOX), {}, "and the house from before")


## M4 Task 10 review I: a guest's EditOverlay kept every chunk it ever got edits for. A chunk the guest's terrain unloads
## is forgotten (after WorldSync.FORGET_AFTER_MS; 0 here), and the host sends its list again when the chunk comes back
## into the guest's view, so the guest's world is still the host's.
func test_a_guest_forgets_the_edits_of_chunks_it_left_and_gets_them_again_when_it_comes_back() -> void:
	host = _world(dir, false)   # a save: the host's own unloaded chunks keep their edits
	guest = _world("", true)
	guest.sync.forget_after_ms = 0
	var at := _secret_spot(host)
	var origin := at - BOX / 2
	_connect(host, Vector3(at))
	host.sync.guest_ready(GUEST)
	var v := _viewer(Vector3(at), GUEST)
	await wait_until(func() -> bool: return _loaded(host, origin, BOX) and _loaded(guest, origin, BOX), 30.0, "both worlds load")
	await _settle()
	await _house_place_ready(host, at + Vector3i(3, 0, 3))
	var house := _build_house(host, at + Vector3i(3, 0, 3))
	await _settle()
	assert_eq(_differences(origin, BOX), {}, "the house reached the guest")
	var overlay := guest.sync.edit_overlay()
	var chunk := EditLog.chunk_of(house[0])
	assert_true(overlay.has_chunk(chunk))
	v.global_position = Vector3(at) + Vector3(640, 0, 0)   # the guest flies far away
	await wait_until(func() -> bool: return not guest.terrain().has_data_block(chunk) \
		and not host.terrain().has_data_block(chunk), 30.0, "both worlds unload the house")
	await wait_until(func() -> bool: return overlay.cell_count() == 0, 5.0, "the guest forgets its edits")
	assert_false(overlay.has_chunk(chunk))
	v.global_position = Vector3(at)   # and comes back
	await wait_until(func() -> bool: return _loaded(host, origin, BOX) and _loaded(guest, origin, BOX), 30.0, "back again")
	await _settle()
	assert_eq(host.get_block(house[0]), BlockIds.BRICK, "the host's save kept the house")
	assert_eq(_differences(origin, BOX), {}, "the host sent the house again")
	assert_true(overlay.has_chunk(chunk))


## M4 Task 10 review I: a chunk unloaded only for a moment keeps its edits (the host may not have seen it leave the
## guest's view, and would not send its list again).
func test_a_chunk_that_unloads_for_a_moment_keeps_its_edits() -> void:
	guest = _world("", true)
	var overlay := guest.sync.edit_overlay()
	var c := Vector3i(40, 1, -40)
	guest.sync.receive(EditCodec.seal(EditCodec.pack_list(c, PackedInt32Array([5, BlockIds.GLASS]))))
	assert_true(overlay.has_chunk(c))
	guest.terrain().block_unloaded.emit(c)
	await wait_frames(5)
	assert_gt(WorldSync.FORGET_AFTER_MS, 1000)
	assert_true(overlay.has_chunk(c), "not before FORGET_AFTER_MS")
	guest.terrain().block_loaded.emit(c)
	guest.sync.forget_after_ms = 0
	await wait_frames(5)
	assert_true(overlay.has_chunk(c), "loaded again: kept")
	guest.terrain().block_unloaded.emit(c)
	await wait_until(func() -> bool: return not overlay.has_chunk(c), 5.0, "unloaded for longer: forgotten")


func test_edits_that_arrive_before_a_chunk_loads_are_in_it() -> void:
	guest = _world("", true)
	var at := Vector3i(40, 20, -40)
	var cells := []
	for i in 10:
		cells.append([at + Vector3i(i, 0, 0), BlockIds.PURPLE])
	guest.sync.receive(EditCodec.seal(EditCodec.pack_cells(cells)))
	guest.sync.receive(EditCodec.seal(EditCodec.pack_list(EditLog.chunk_of(at + Vector3i(0, 5, 0)),
		PackedInt32Array([EditLog.cell_of(at + Vector3i(0, 5, 0)), BlockIds.GLASS]))))
	_viewer(Vector3(at))
	await wait_until(func() -> bool: return guest.is_editable(at) and guest.is_editable(at + Vector3i(9, 5, 0)), 30.0)
	await wait_frames(3)
	for i in 10:
		assert_eq(guest.get_block(at + Vector3i(i, 0, 0)), BlockIds.PURPLE)
	assert_eq(guest.get_block(at + Vector3i(0, 5, 0)), BlockIds.GLASS)


func test_a_big_build_goes_out_paced_over_several_frames() -> void:
	host = _world("", false)
	var at := _secret_spot(host) + Vector3i(0, 20, 0)
	var origin := at - BOX / 2
	_viewer(Vector3(at))
	await wait_until(func() -> bool: return _loaded(host, origin, BOX), 30.0, "the host's world loads")
	guest = _world("", true)
	_connect(host, Vector3(at))
	host.sync.guest_ready(GUEST)
	_viewer(Vector3(at), GUEST)
	await wait_until(func() -> bool: return _loaded(guest, origin, BOX), 30.0, "the guest's world loads")
	await _settle()
	sent.clear()
	for x in 20:   # a 20 × 4 × 20 slab: 1,600 cells, a stamp's worth, in one frame
		for y in 4:
			for z in 20:
				host.set_block(at + Vector3i(x - 10, y, z - 10), BlockIds.PLANKS if (x + z) % 2 else BlockIds.BRICK)
	await wait_frames(60)
	assert_gt(sent.size(), 1, "more than one packet")
	for s in sent:
		assert_lte(s, SyncPacer.BURST + EditCodec.cells_bytes(GuestSync.CELLS_PER_RECORD), "no packet much over a burst")
	await _settle()
	assert_eq(_differences(origin, BOX), {})
