extends GutTest
## M3 Task 20a: getting on and off (RideDirector, node "Rides" in the sandbox). The RIDE context button shows only
## next to a saddled buddy nobody rides, and as HOP OFF while riding; the host decides every ride (a saddle, near
## it, free, the rider able to ride) and whose stick moves which buddy (only its rider's); getting off (RIDE again,
## JUMP off anything but a flyer) puts the rider beside the buddy, never inside blocks; riders who can't ride any
## more get off; a Survivor flight ends when the dragon lands. LAN: a guest only asks, the host decides.

const S := BlockIds.SADDLE
const P := BlockIds.PLANKS
const DT := 1.0 / 60.0
const ME_AT := Vector3(0.5, 10.0, 0.5)


class CellWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		if cells.has(pos):
			return cells[pos]
		return BlockIds.STONE if pos.y < 10 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 9

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block


## A network peer that is always connected and sends its packets nowhere (it notes who they were for).
class FakePeer:
	extends MultiplayerPeerExtension
	var id := 2
	var server := false
	var sent_to: Array[int] = []
	var _target := 0

	func _get_unique_id() -> int:
		return id

	func _is_server() -> bool:
		return server

	func _get_connection_status() -> MultiplayerPeer.ConnectionStatus:
		return MultiplayerPeer.CONNECTION_CONNECTED

	func _put_packet_script(_buffer: PackedByteArray) -> Error:
		sent_to.append(_target)
		return OK

	func _get_packet_script() -> PackedByteArray:
		return PackedByteArray()

	func _get_available_packet_count() -> int:
		return 0

	func _get_max_packet_size() -> int:
		return 1 << 20

	func _set_target_peer(peer: int) -> void:
		_target = peer

	func _get_packet_peer() -> int:
		return 1

	func _get_packet_mode() -> MultiplayerPeer.TransferMode:
		return MultiplayerPeer.TRANSFER_MODE_RELIABLE

	func _get_packet_channel() -> int:
		return 0

	func _set_transfer_channel(_channel: int) -> void:
		pass

	func _set_transfer_mode(_mode: MultiplayerPeer.TransferMode) -> void:
		pass

	func _get_transfer_mode() -> MultiplayerPeer.TransferMode:
		return MultiplayerPeer.TRANSFER_MODE_RELIABLE


var world: CellWorld
var root: Node3D
var director: RideDirector
var me: Player
var hud: Hud
var said: Array = []
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	world = CellWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	root = Node3D.new()
	root.name = "Buddies"
	add_child_autofree(root)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0, 9.5, 0)
	add_child_autofree(ground)
	said = []
	Session.magic_feedback.connect(_heard)


func after_each() -> void:
	Session.magic_feedback.disconnect(_heard)
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	Session.register_world(null)
	Game.mode = _mode_before
	for a: StringName in [&"jump", &"crouch", &"move_forward"]:
		Input.action_release(a)


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _heard(text: String) -> void:
	said.append(text)


func _player(peer: int, feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.global_position = feet
	p._spawned = true
	return p


func _local(with_hud := true) -> void:
	me = _player(multiplayer.get_unique_id(), ME_AT)
	director = RideDirector.new()
	director.name = "Rides"
	director.buddies_root = root
	director.host_checks = false   # the test calls host_check()
	add_child_autofree(director)
	director.set_process(false)
	if with_hud:
		hud = Hud.new()
		add_child_autofree(hud)
		hud.setup(me, "Kid", true, false)
	director.setup_local(me, hud if with_hud else null)


func _buddy(blocks: Dictionary, pos: Vector3, buddy_name: String) -> Buddy:
	var b := Buddy.new()
	b.setup({"flat": Buddy.pack(blocks), "name": buddy_name, "owner": 1, "pos": pos, "yaw": 0.0, "id": buddy_name})
	root.add_child(b)
	b.set_physics_process(false)
	return b


static func _pony() -> Dictionary:
	return {Vector3i(0, 0, 0): P, Vector3i(0, 1, 0): S}


static func _dragon() -> Dictionary:
	return {Vector3i(2, 0, 0): P, Vector3i(2, 1, 0): P, Vector3i(0, 2, 0): P, Vector3i(1, 2, 0): P, Vector3i(2, 2, 0): S,
		Vector3i(3, 2, 0): P, Vector3i(4, 2, 0): P, Vector3i(0, 2, 1): P, Vector3i(1, 2, 1): P, Vector3i(2, 2, 1): P,
		Vector3i(3, 2, 1): P, Vector3i(4, 2, 1): P}


func _free_spot(at: Vector3) -> bool:
	var feet := Vector3i(at.floor())
	return not BlockIds.is_solid(world.get_block(feet)) and not BlockIds.is_solid(world.get_block(feet + Vector3i.UP))


# --- The RIDE button -----------------------------------------------------------------------------------

func test_ride_shows_only_next_to_a_saddled_buddy_nobody_rides() -> void:
	_local()
	var pony := _buddy(_pony(), Vector3(2.5, 10, 0.5), "Pony")
	var plain := _buddy({Vector3i.ZERO: P, Vector3i(0, 1, 0): P}, Vector3(-20, 10, 0.5), "Plain")
	director.scan()
	assert_eq(director.nearby, pony)
	assert_true(hud.ride_button.visible, "RIDE shows next to the saddled buddy")
	assert_eq(hud.ride_button.text, "RIDE")
	assert_false(hud.ride_button.selected)
	me.global_position = Vector3(30, 10, 0.5)
	director.scan()
	assert_false(hud.ride_button.visible, "not from far away")
	me.global_position = plain.global_position + Vector3(1.5, 0, 0)
	director.scan()
	assert_false(hud.ride_button.visible, "not next to a buddy without a saddle")
	me.global_position = ME_AT
	pony.rider_peer = 5
	director.scan()
	assert_false(hud.ride_button.visible, "not when a friend rides it")
	pony.rider_peer = 0
	me.knocked_out = true
	director.scan()
	assert_false(hud.ride_button.visible, "not while knocked out")


func test_ride_gets_on_and_hop_off_gets_off_beside_it() -> void:
	_local()
	var pony := _buddy(_pony(), Vector3(2.5, 10, 0.5), "Pony")
	director.scan()
	director.press_ride()
	assert_eq(pony.rider_peer, me.peer_id, "the host said yes")
	assert_true(me.is_riding())
	assert_has(said, RideRules.mount_line(RideRules.Kind.WALK), "a short line")
	director.scan()
	assert_true(hud.ride_button.visible)
	assert_eq(hud.ride_button.text, "HOP OFF")
	assert_true(hud.ride_button.selected, "lit while riding")
	me._process(DT)
	assert_almost_eq(me.global_position, pony.seat_position(), Vector3.ONE * 0.001, "on the saddle")
	director.press_ride()
	assert_eq(pony.rider_peer, 0)
	assert_false(me.is_riding())
	assert_true(_free_spot(me.global_position), "never inside blocks: %s" % me.global_position)
	assert_gt(Vector2(me.global_position.x - 2.5, me.global_position.z - 0.5).length(), 0.9, "beside it")
	assert_almost_eq(me.global_position.y, 10.0, 0.05, "on the ground")


func test_riding_a_dragon_shows_up_and_down() -> void:
	_local()
	_buddy(_dragon(), Vector3(3.5, 10, 0.5), "Dragon")
	director.scan()
	director.press_ride()
	assert_true(me.is_riding())
	assert_eq(hud.jump_button.text, "UP", "JUMP climbs")
	assert_true(hud.fly_down_button.visible, "DOWN dives")
	director.press_ride()
	assert_eq(hud.jump_button.text, "JUMP")


## Getting off a dragon high up: beside it in the air, drifting down gently; nobody is hurt by a fall. And while
## riding, the child sits (an emote that ended sits down again) and no bed offers SLEEP.
## Owner #45a: a ride that begins counts for the rider ("Ride a buddy", "Fly a buddy dragon" on the board).
func test_a_ride_counts_for_the_riders_progress() -> void:
	_local(false)
	_buddy(_dragon(), Vector3(3.5, 40, 0.5), "Dragon")
	me.global_position = Vector3(3.5, 40, 3.0)
	var data := ProgressData.new()
	Progress.begin(data)
	assert_eq(director.host_ride(me.peer_id, "Far away"), "no_saddle")
	assert_eq(data.count(&"buddy_ridden"), 0, "a refused ride counts nothing")
	assert_eq(director.host_ride(me.peer_id, "Dragon"), "")
	Progress.end()
	assert_eq(data.count(&"buddy_ridden/fly"), 1)
	assert_eq(data.count(&"buddy_ridden"), 1)


func test_off_in_the_air_drifts_down_and_nothing_hurts() -> void:
	_local(false)
	var dragon := _buddy(_dragon(), Vector3(3.5, 40, 0.5), "Dragon")
	me.global_position = Vector3(3.5, 40, 3.0)
	var hearts := me.health.hp
	assert_eq(director.host_ride(me.peer_id, "Dragon"), "")
	me.avatar.stop_emote(true)
	me._process(DT)
	assert_eq(me.avatar.emote(), &"sit", "back on the saddle, sitting")
	director.host_ride_off(me.peer_id)
	assert_false(me.is_riding())
	assert_gt(me.global_position.y, 35.0, "beside the dragon, up in the air")
	assert_true(me.soft_falling(), "a gentle drift down")
	assert_eq(me.health.hp, hearts, "no damage")
	assert_ne(me.avatar.emote(), &"sit", "standing up again")
	assert_eq(dragon.rider_peer, 0)


func test_no_sleep_button_while_riding() -> void:
	_local()
	world.cells[Vector3i(1, 10, 0)] = BlockIds.BED
	var sleep := SleepDirector.new()
	sleep.world = world
	sleep.player = me
	sleep.hud = hud
	add_child_autofree(sleep)
	sleep.set_process(false)
	var pony := _buddy(_pony(), Vector3(2.5, 10, 0.5), "Pony")
	me.velocity = Vector3(0, -1, 0)
	me.move_and_slide()   # standing on the ground
	sleep._process(1.0)
	assert_eq(sleep.nearby_bed, Vector3i(1, 10, 0), "SLEEP beside the bed, standing")
	assert_eq(director.host_ride(me.peer_id, "Pony"), "")
	sleep._scan_t = 0.0
	sleep._process(1.0)
	assert_eq(sleep.nearby_bed, BedRules.NO_BED, "no SLEEP on a buddy")
	assert_false(hud.sleep_button.visible)
	pony.free()


func test_the_host_refuses_what_it_cant_allow() -> void:
	_local(false)
	var pony := _buddy(_pony(), Vector3(2.5, 10, 0.5), "Pony")
	var far := _buddy(_pony(), Vector3(40.5, 10, 0.5), "Far")
	_buddy({Vector3i.ZERO: P}, Vector3(-1.5, 10, 0.5), "Plain")
	assert_eq(director.host_ride(me.peer_id, "Far"), "too_far")
	assert_eq(director.host_ride(me.peer_id, "Plain"), "no_saddle")
	assert_eq(director.host_ride(me.peer_id, "Nobody"), "no_saddle")
	pony.rider_peer = 5
	assert_eq(director.host_ride(me.peer_id, "Pony"), "taken")
	pony.rider_peer = 0
	me.sleeping = true
	assert_eq(director.host_ride(me.peer_id, "Pony"), "busy", "asleep")
	me.sleeping = false
	assert_eq(director.host_ride(me.peer_id, "Pony"), "")
	far.global_position = Vector3(4.5, 10, 0.5)
	assert_eq(director.host_ride(me.peer_id, "Far"), "busy", "one ride at a time")
	assert_eq(far.rider_peer, 0)
	assert_eq(director.host_ride(9, "Far"), "busy", "nobody with that id")


func test_jump_gets_off_a_walker_but_climbs_on_a_dragon() -> void:
	_local(false)
	var pony := _buddy(_pony(), Vector3(2.5, 10, 0.5), "Pony")
	assert_eq(director.host_ride(me.peer_id, "Pony"), "")
	Input.action_press(&"jump")
	me._physics_process(DT)
	Input.action_release(&"jump")
	assert_false(me.is_riding(), "JUMP hops off")
	assert_eq(pony.rider_peer, 0)
	var dragon := _buddy(_dragon(), Vector3(3.5, 10, 4.5), "Dragon")
	me.global_position = Vector3(3.5, 10, 2.0)
	assert_eq(director.host_ride(me.peer_id, "Dragon"), "")
	Input.action_press(&"jump")
	me._physics_process(DT)
	assert_true(me.is_riding(), "a dragon climbs instead")
	assert_eq(dragon.ride_input.y, 1.0, "the stick went to the host: up")
	Input.action_release(&"jump")


func test_the_rider_sends_its_stick_at_most_20_times_a_second() -> void:
	_local(false)
	var dragon := _buddy(_dragon(), Vector3(3.5, 10, 0.5), "Dragon")
	assert_eq(director.host_ride(me.peer_id, "Dragon"), "")
	var heard: Array = []
	var note := func(_peer: int, _name: String, wish: Vector3) -> void: heard.append(wish)
	Session.ride_input_received.connect(note)
	Input.action_press(&"move_forward")
	for i in 60:   # one second
		me._physics_process(DT)
	Input.action_release(&"move_forward")
	Session.ride_input_received.disconnect(note)
	assert_between(heard.size(), 4, 20, "a held stick: every quarter second, not every frame")
	assert_lt((heard[0] as Vector3).z, -0.5, "ahead (the camera looks along -z)")
	assert_eq(dragon.rider_peer, me.peer_id)


# --- The host decides ------------------------------------------------------------------------------------

func test_riders_who_cant_ride_any_more_get_off() -> void:
	_local(false)
	var pony := _buddy(_pony(), Vector3(2.5, 10, 0.5), "Pony")
	assert_eq(director.host_ride(me.peer_id, "Pony"), "")
	me._process(DT)
	me.knocked_out = true
	director.host_check()
	assert_eq(pony.rider_peer, 0, "knocked out: off")
	assert_true(_free_spot(me.global_position))
	me.knocked_out = false
	var friend := _player(5, Vector3(2.5, 10, 2.5))
	assert_eq(director.host_ride(5, "Pony"), "")
	friend.free()
	director.host_check()
	assert_eq(pony.rider_peer, 0, "a rider who left: off")


func test_a_survivor_flight_ends_when_the_dragon_lands() -> void:
	for mode: StringName in [ModeRules.SANDBOX, ModeRules.SURVIVOR]:
		Game.mode = mode
		_local(false)
		var dragon := _buddy(_dragon(), Vector3(3.5, 10.2, 0.5), "Dragon")
		await get_tree().physics_frame
		assert_eq(director.host_ride(me.peer_id, "Dragon"), "")
		for i in 60:   # up ...
			dragon.set_ride_input(Vector3(0, 1, 0))
			dragon._physics_process(DT)
			director.host_check()
		assert_true(dragon.was_airborne(), "%s: it took off" % mode)
		assert_eq(dragon.rider_peer, me.peer_id, "%s: still riding in the air" % mode)
		var landed := false
		for i in 90:   # ... and down
			dragon.set_ride_input(Vector3(0, -1, 0))
			dragon._physics_process(DT)
			landed = landed or dragon.is_on_floor()
			director.host_check()
			if dragon.rider_peer == 0:
				break
		assert_true(landed, "%s: landed" % mode)
		if mode == ModeRules.SURVIVOR:
			assert_eq(dragon.rider_peer, 0, "Survivor: the flight is over at landing")
			assert_has(said, "Nice landing!")
			assert_true(_free_spot(me.global_position))
		else:
			assert_eq(dragon.rider_peer, me.peer_id, "Sandbox: land and take off as you like")
		dragon.free()
		me.free()
		director.free()


# --- LAN: the host decides a guest's ride ------------------------------------------------------------------

func test_a_guest_only_asks_the_host() -> void:
	var peer := FakePeer.new()
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(1)
	var pony := _buddy(_pony(), Vector3(2.5, 10, 0.5), "Pony")
	Session.request_ride("Pony")
	Session.ride_input("Pony", Vector3(0, 0, -1))
	Session.request_ride_off()
	assert_eq(pony.rider_peer, 0, "nothing changes before the host says so")
	assert_false(peer.sent_to.is_empty(), "requests went out")
	for to in peer.sent_to:
		assert_eq(to, 1, "to the host only")


func test_the_host_decides_a_guests_ride_and_only_its_stick_steers() -> void:
	var peer := FakePeer.new()
	peer.id = 1
	peer.server = true
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(2)
	peer.peer_connected.emit(3)
	_local(false)
	var guest := _player(2, Vector3(2.5, 10, 2.5))
	var pony := _buddy(_pony(), Vector3(2.5, 10, 0.5), "Pony")
	assert_eq(director.host_ride(2, "Pony"), "", "the guest near it gets on")
	assert_eq(pony.rider_peer, 2)
	assert_eq(guest.riding, pony, "the host's game shows the guest on the saddle")
	director.host_ride_input(3, "Pony", Vector3(0, 0, -1))
	assert_eq(pony.ride_input, Vector3.ZERO, "someone else's stick does nothing")
	director.host_ride_input(2, "Pony", Vector3(3, 0, -4))
	assert_true(pony.ride_input.is_equal_approx(Vector3(0.6, 0, -0.8)), "the rider's stick, cleaned")
	director.host_ride_input(2, "Pony", Vector3(NAN, 0, 1))
	assert_eq(pony.ride_input, Vector3.ZERO, "never a broken number")
	var guest_at := guest.global_position
	peer.sent_to.clear()
	director.host_ride_off(2)
	assert_eq(pony.rider_peer, 0)
	assert_has(peer.sent_to, 2, "the guest's own game is told where to stand")
	assert_eq(guest.global_position, guest_at, "the host never moves a guest's body itself")
