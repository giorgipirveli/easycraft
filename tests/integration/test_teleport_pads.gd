extends GutTest
## M3 Task 7 (spec §14.4): teleport pads. The two nearest free pads a player placed link; stepping on one
## (the player's own game tells the host, Session.request_smart_touch; the host checks the pad is there and
## the player is on it) brings them out on top of the other. No bouncing straight back: the pad they arrive
## on waits until they step off it. A lone pad or a blocked partner says why. The pairs are saved.

const ME_AT := Vector3(0.5, 10.0, 0.5)
const A := Vector3i(0, 9, 0)        # under the player's feet
const B := Vector3i(30, 9, 4)


class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 9


var world: EditWorld
var me: Player
var smart: SmartDirector
var clock := [0]
var _told: Array = []


func before_each() -> void:
	world = EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	clock[0] = 0
	Session.smart_now_ms = func() -> int: return clock[0]
	_told = []
	me = _player(multiplayer.get_unique_id(), ME_AT)
	smart = _director({})


func after_each() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Session.register_world(null)
	Session.smart_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _director(saved: Dictionary) -> SmartDirector:
	var d := SmartDirector.new()
	d.name = "Smart"
	d.block_at = world.get_block
	d.tell = func(peer: int, text: String) -> void: _told.append([peer, text])
	add_child_autofree(d)
	d.set_process(false)
	d.start(saved)
	world.block_changed.connect(d.note_block)
	return d


func _player(peer: int, feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.global_position = feet
	p._spawned = true
	return p


func _pads() -> void:
	world.set_block(A, BlockIds.TELEPORT_PAD)
	world.set_block(B, BlockIds.TELEPORT_PAD)


func test_two_pads_link_and_carry_a_player_across() -> void:
	_pads()
	assert_eq(smart.links.partner_of(A), B)
	watch_signals(smart)
	assert_true(Session.request_smart_touch(BlockIds.TELEPORT_PAD, A))
	assert_signal_emitted_with_parameters(smart, "teleported", [me.peer_id, A, B])
	assert_eq(me.global_position, CourseRules.top_of(B), "out on top of the other pad")


func test_a_lone_pad_says_so() -> void:
	world.set_block(A, BlockIds.TELEPORT_PAD)
	Session.request_smart_touch(BlockIds.TELEPORT_PAD, A)
	assert_eq(_told, [[me.peer_id, SmartDirector.LONE_PAD]])
	assert_eq(me.global_position, ME_AT)


func test_the_arrival_pad_waits_until_they_step_off() -> void:
	_pads()
	Session.request_smart_touch(BlockIds.TELEPORT_PAD, A)
	me._spawned = true
	clock[0] = 100
	Session.request_smart_touch(BlockIds.TELEPORT_PAD, B)   # their feet land on the arrival pad
	assert_eq(me.global_position, CourseRules.top_of(B), "no bouncing straight back")
	smart.tick(2.0)                                         # long after the cooldown, still standing on it
	clock[0] = 5000
	Session.request_smart_touch(BlockIds.TELEPORT_PAD, B)
	assert_eq(me.global_position, CourseRules.top_of(B), "still standing on the arrival pad: nothing")
	me.global_position = CourseRules.top_of(B) + Vector3(2, 0, 0)   # steps off
	smart.tick(SmartDirector.CHECK_EVERY + 0.01)
	me.global_position = CourseRules.top_of(B)                     # and back on
	clock[0] = 6000
	Session.request_smart_touch(BlockIds.TELEPORT_PAD, B)
	assert_eq(me.global_position, CourseRules.top_of(A), "stepping on again goes back")


func test_a_blocked_partner_refuses_kindly() -> void:
	_pads()
	world.cells[B + Vector3i(0, 2, 0)] = BlockIds.STONE
	Session.request_smart_touch(BlockIds.TELEPORT_PAD, A)
	assert_eq(_told, [[me.peer_id, SmartDirector.PAD_BLOCKED]])
	assert_eq(me.global_position, ME_AT)


func test_a_broken_pad_unlinks_its_partner() -> void:
	_pads()
	world.set_block(B, BlockIds.AIR)
	assert_eq(smart.links.partner_of(A), null)
	Session.request_smart_touch(BlockIds.TELEPORT_PAD, A)
	assert_eq(_told, [[me.peer_id, SmartDirector.LONE_PAD]])


func test_a_touch_the_host_cant_believe_is_refused() -> void:
	_pads()
	me.global_position = ME_AT + Vector3(12, 0, 0)
	assert_false(Session.request_smart_touch(BlockIds.TELEPORT_PAD, A), "far from the pad")
	me.global_position = ME_AT
	world.cells[A] = BlockIds.STONE
	assert_false(Session.request_smart_touch(BlockIds.TELEPORT_PAD, A), "no pad there")
	assert_false(Session.request_smart_touch(BlockIds.STONE, A), "not a thing to touch")


func test_pairs_are_saved_with_the_world() -> void:
	_pads()
	var saved := smart.to_save()
	var again := _director(saved)
	assert_eq(again.links.partner_of(B), A)


func test_friends_ride_too_each_from_their_own_game() -> void:
	_pads()
	var sent: Array = []
	smart.arrive = func(peer: int, exit: Vector3) -> void: sent.append([peer, exit])
	var guest := _player(5, ME_AT + Vector3(0.3, 0, 0.2))
	assert_true(Session.host_smart_touch(5, BlockIds.TELEPORT_PAD, A, false), "the host believes the guest on the pad")
	assert_eq(sent, [[5, CourseRules.top_of(B)]], "the guest's own game is told where to come out")
	assert_eq(guest.global_position, ME_AT + Vector3(0.3, 0, 0.2), "the host never moves a guest's body itself")
