extends GutTest
## M3 Task 5 (spec §14.2): portal frames and cores in a world (Sandbox too), through the host's
## PortalDirector: two whole frames with cores link and swirl (one shared material); walking into one
## doorway brings the player out in front of the other (the host decides from its own positions, the
## player's own game moves them, a whoosh at both ends); a broken frame, a walled-in exit or a lone frame
## refuses kindly; no bouncing straight back; the links and frames are saved and loaded.

const F := BlockIds.PORTAL_FRAME
const C := BlockIds.PORTAL_CORE
const FLOOR := 20
const A_LO := Vector3i(0, FLOOR, 0)
const B_LO := Vector3i(40, FLOOR, 10)

var cells := {}
var _told: Array = []
var _trips: Array = []


func before_each() -> void:
	cells = {}
	_told = []
	_trips = []


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _at(p: Vector3i) -> int:
	if cells.has(p):
		return cells[p]
	return BlockIds.STONE if p.y < FLOOR else BlockIds.AIR


func _put(d: PortalDirector, p: Vector3i, id: int) -> void:
	var old := _at(p)
	if id == BlockIds.AIR and p.y < FLOOR:
		cells[p] = BlockIds.AIR
	else:
		cells[p] = id
	d.note_block(p, old, id)
	d.flush()


## A 1 x 2 doorway along X at `lo` (bottom-left opening cell), built block by block like a child would:
## the core last. Returns the core.
func _build(d: PortalDirector, lo: Vector3i) -> Vector3i:
	for c in [lo + Vector3i(-1, -1, 0), lo + Vector3i(1, -1, 0), lo + Vector3i(-1, 0, 0), lo + Vector3i(1, 0, 0),
			lo + Vector3i(-1, 1, 0), lo + Vector3i(1, 1, 0), lo + Vector3i(-1, 2, 0), lo + Vector3i(0, 2, 0),
			lo + Vector3i(1, 2, 0)]:
		_put(d, c, F)
	_put(d, lo + Vector3i(0, -1, 0), C)
	return lo + Vector3i(0, -1, 0)


func _director() -> PortalDirector:
	var d := PortalDirector.new()
	d.name = "PortalFrames"
	d.block_at = _at
	d.tell = func(peer: int, text: String) -> void: _told.append([peer, text])
	d.traveled.connect(func(peer: int, from: Vector3i, to: Vector3i) -> void: _trips.append([peer, from, to]))
	add_child_autofree(d)
	d.set_process(false)
	d.start({})
	return d


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _step(d: PortalDirector) -> void:
	d.tick(PortalDirector.CHECK_EVERY + 0.01)


func _in_doorway(lo: Vector3i) -> Vector3:
	return Vector3(lo) + Vector3(0.5, 0.0, 0.5)


# --- Linking ---

func test_two_whole_frames_link_and_swirl() -> void:
	var d := _director()
	var a := _build(d, A_LO)
	assert_eq(d.links.partner_of(a), null, "one frame waits")
	assert_eq(d.swirls().size(), 0, "no swirl without a partner")
	var b := _build(d, B_LO)
	assert_eq(d.links.partner_of(a), b)
	assert_true(d.links.works(a))
	assert_eq(d.swirls().size(), 2, "both doorways swirl")
	for s in d.swirls():
		assert_same(s.material_override, PortalSwirl.material(), "one shared swirl material")
		assert_same(s.mesh, PortalSwirl.quad(), "one shared quad")


func test_a_core_placed_before_its_frame_links_once_the_frame_is_whole() -> void:
	var d := _director()
	_build(d, A_LO)
	_put(d, B_LO + Vector3i(0, -1, 0), C)   # the core first
	assert_eq(d.swirls().size(), 0)
	for c in [B_LO + Vector3i(-1, -1, 0), B_LO + Vector3i(1, -1, 0), B_LO + Vector3i(-1, 0, 0), B_LO + Vector3i(1, 0, 0),
			B_LO + Vector3i(-1, 1, 0), B_LO + Vector3i(1, 1, 0), B_LO + Vector3i(-1, 2, 0), B_LO + Vector3i(0, 2, 0),
			B_LO + Vector3i(1, 2, 0)]:
		_put(d, c, F)
	assert_eq(d.swirls().size(), 2)


# --- Travelling ---

func test_walking_in_brings_you_out_in_front_of_the_other_doorway() -> void:
	var d := _director()
	var a := _build(d, A_LO)
	var b := _build(d, B_LO)
	var me := _player(Vector3(A_LO) + Vector3(0.5, 0, 3.5))
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips, [], "in front of it, not in it")
	me.global_position = _in_doorway(A_LO)
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips, [[me.peer_id, a, b]])
	var exit: Vector3 = d.links.shape_of(b).exit
	assert_almost_eq(me._spawn_target, exit, Vector3.ONE * 0.01, "out in front of the other doorway")
	assert_false(BlockIds.is_solid(_at(Vector3i(exit.floor()))), "not in a wall")
	assert_false(BlockIds.is_solid(_at(Vector3i(exit.floor()) + Vector3i.UP)))
	var forward := Vector3(-sin(me.rig.yaw), 0, -cos(me.rig.yaw))
	assert_gt(forward.dot(exit - PortalRules.center(d.links.shape_of(b))), 0.0, "looking away from the doorway")


func test_no_bouncing_straight_back() -> void:
	var d := _director()
	_build(d, A_LO)
	_build(d, B_LO)
	var me := _player(_in_doorway(A_LO))
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips.size(), 1)
	me._spawned = true   # arrived (the terrain there was ready)
	me.global_position = _in_doorway(B_LO)   # stepped straight into the other doorway
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips.size(), 1, "not until they stepped out and a moment passed")
	me.global_position = Vector3(B_LO) + Vector3(0.5, 0, 4.0)
	await get_tree().physics_frame
	for i in 12:
		_step(d)
	me.global_position = _in_doorway(B_LO)
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips.size(), 2, "and back")


func test_a_late_position_never_sends_a_guest_twice() -> void:
	var d := _director()
	_build(d, A_LO)
	_build(d, B_LO)
	var me := _player(_in_doorway(A_LO))
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips.size(), 1)
	me._spawned = true
	me.global_position = Vector3(B_LO) + Vector3(0.5, 0, 3.0)   # the host sees it arrive ...
	await get_tree().physics_frame
	_step(d)
	me.global_position = _in_doorway(A_LO)                      # ... then an older position comes in late
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips.size(), 1, "one trip per walk-in")


func test_a_broken_frame_refuses() -> void:
	var d := _director()
	_build(d, A_LO)
	_build(d, B_LO)
	_put(d, B_LO + Vector3i(1, 1, 0), BlockIds.AIR)   # a frame block of the other portal broken
	assert_eq(d.swirls().size(), 0, "no swirl on either side")
	var me := _player(_in_doorway(A_LO))
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips, [], "no trip")
	assert_eq(me._spawn_target, Vector3.ZERO, "not moved")
	_put(d, B_LO + Vector3i(1, 1, 0), F)   # mended
	assert_eq(d.swirls().size(), 2)


func test_a_lone_frame_says_it_needs_a_partner() -> void:
	var d := _director()
	_build(d, A_LO)
	var me := _player(_in_doorway(A_LO))
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips, [])
	assert_eq(_told, [[me.peer_id, PortalDirector.NEEDS_PARTNER]])
	_step(d)
	assert_eq(_told.size(), 1, "said once while they stand there")


func test_never_into_a_wall() -> void:
	var d := _director()
	_build(d, A_LO)
	_build(d, B_LO)
	_put(d, B_LO + Vector3i(0, 1, 1), BlockIds.STONE)    # walled in on both sides of the other doorway
	_put(d, B_LO + Vector3i(0, 1, -1), BlockIds.STONE)
	var me := _player(_in_doorway(A_LO))
	await get_tree().physics_frame
	_step(d)
	assert_eq(_trips, [])
	assert_eq(_told, [[me.peer_id, PortalDirector.BLOCKED]])


func test_breaking_a_core_unlinks_and_the_next_core_links() -> void:
	var d := _director()
	var a := _build(d, A_LO)
	var b := _build(d, B_LO)
	_put(d, b, BlockIds.AIR)
	assert_eq(d.links.partner_of(a), null)
	assert_false(d.links.has(b))
	var c := _build(d, Vector3i(-30, FLOOR, -20))
	assert_eq(d.links.partner_of(a), c)


# --- Every peer, and saving ---

func test_the_swirls_come_from_the_hosts_list() -> void:
	var d := _director()
	d._rpc_active([[Vector3i(5, 30, 5), Vector2i(2, 3), PortalRules.AXIS_Z]])
	assert_eq(d.swirls().size(), 1)
	var s := d.swirls()[0]
	assert_almost_eq(s.global_position, Vector3(5.5, 31.5, 6.0), Vector3.ONE * 0.01, "in the doorway's middle")
	assert_almost_eq(s.scale, Vector3(2, 3, 1), Vector3.ONE * 0.01)
	d._rpc_active([])
	assert_eq(d.swirls().size(), 0)
	d._rpc_active("junk")
	assert_eq(d.swirls().size(), 0, "a broken list shows nothing")


func test_links_and_frames_are_saved_and_work_after_loading_unseen() -> void:
	var d := _director()
	var a := _build(d, A_LO)
	var b := _build(d, B_LO)
	var saved := d.to_save()
	var meta := WorldMeta.new_random()
	meta.portals = saved
	var loaded := WorldMeta.from_json(meta.to_json())
	var d2 := PortalDirector.new()
	d2.name = "PortalFrames2"
	d2.block_at = func(_p: Vector3i) -> int: return BlockIds.AIR   # nothing loaded around them yet
	d2.area_ready = func(_p: Vector3i) -> bool: return false
	d2.traveled.connect(func(peer: int, from: Vector3i, to: Vector3i) -> void: _trips.append([peer, from, to]))
	add_child_autofree(d2)
	d2.set_process(false)
	d2.start(loaded.portals)
	assert_eq(d2.links.partner_of(a), b)
	assert_eq(d2.swirls().size(), 2)
	_player(_in_doorway(A_LO))
	await get_tree().physics_frame
	d2.tick(PortalDirector.CHECK_EVERY + 0.01)
	assert_eq(_trips, [[multiplayer.get_unique_id(), a, b]], "the far end isn't loaded: the saved frame counts")


func test_a_broken_save_is_no_portals() -> void:
	assert_eq(WorldMeta.from_json('{"seed": 1, "portals": "lots"}').portals, [])
	assert_eq(WorldMeta.new_random().portals, [])
