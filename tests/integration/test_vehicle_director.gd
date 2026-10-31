extends GutTest
## Owner #109 (spec §3b "Cars"): the cars in a world (VehicleDirector, node "Vehicles" in the sandbox). The garage brings
## a child's car in front of them: the Sandbox every kind free, Survivor the kinds bought with Survivor gold (the child's
## own for good, in the profile); one of each kind per child (GET IT again brings that one, in the colour picked), at
## most 4 out at once (the oldest parked one goes home), 12 in a world, none in Monster Wave's arena. The host decides
## every seat (RIDE says DRIVE or GET IN next to a car with a free seat, HOP OFF in it; near it, free, able to ride),
## HOP OFF puts the rider beside the car (never inside blocks), riders who can't ride any more get out, only the
## driver flies a flying car, the horn sounds on every game. The pickup's bed loads blocks (Survivor: from the bag)
## and unloads them (Survivor: back into the bag; the Sandbox tips them out behind it). Parked cars are saved.

const DT := 1.0 / 60.0
const ME_AT := Vector3(0.5, 10.0, 0.5)


class CellWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		if cells.has(pos):
			return cells[pos]
		return BlockIds.STONE if pos.y < 10 else BlockIds.AIR

	func set_block(pos: Vector3i, id: int) -> void:
		cells[pos] = id

	func surface_height(_x: int, _z: int) -> int:
		return 9


## A network peer that is always connected and sends its packets nowhere (it notes who they were for).
class FakePeer:
	extends MultiplayerPeerExtension
	var id := 2
	var sent_to: Array[int] = []
	var _target := 0

	func _get_unique_id() -> int:
		return id

	func _is_server() -> bool:
		return false

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
var director: VehicleDirector
var rides: RideDirector
var me: Player
var hud: Hud
var said: Array = []
var _mode_before: StringName
var _gold_before := 0
var _bought_before: Array[String] = []
var _name_before := ""


func before_each() -> void:
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	_bought_before = Profile.data.bought.duplicate()
	_name_before = Profile.data.username
	Profile.data.username = "Kid"
	Game.mode = ModeRules.SANDBOX
	world = CellWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
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
	Profile.data.survivor_gold = _gold_before
	Profile.data.bought = _bought_before
	Profile.data.username = _name_before
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
	p.peer_id = peer
	p.is_local = peer == multiplayer.get_unique_id()
	p.world = world
	add_child_autofree(p)
	p.set_physics_process(false)
	p.global_position = feet
	p._spawned = true
	return p


func _local(with_hud := true) -> void:
	me = _player(multiplayer.get_unique_id(), ME_AT)
	director = VehicleDirector.new()
	director.name = "Vehicles"
	director.host_checks = false   # the test calls host_check()
	director.save_profile = func() -> void: pass   # never the real profile file
	add_child_autofree(director)
	director.set_process(false)
	rides = RideDirector.new()
	rides.name = "Rides"
	rides.host_checks = false
	rides.cars = director
	add_child_autofree(rides)
	rides.set_process(false)
	if with_hud:
		hud = Hud.new()
		add_child_autofree(hud)
		hud.setup(me, "Kid", true, false)
	rides.setup_local(me, hud if with_hud else null)
	director.setup_local(me, hud if with_hud else null, self)


func _cars() -> Array[Vehicle]:
	return director.cars()


# --- The garage brings cars --------------------------------------------------------------------------------------

func test_the_sandbox_brings_every_kind_free_in_front_of_the_child() -> void:
	_local(false)
	assert_eq(director.host_car(me.peer_id, CarKinds.BUS, 2, 0.0), "")
	var bus := director.car_of("Kid", CarKinds.BUS)
	assert_not_null(bus, "the bus came out")
	assert_eq(bus.colour, 2, "in the colour picked")
	assert_lt(bus.global_position.z, ME_AT.z - 2.0, "in front of the child (they look along -z)")
	assert_almost_eq(bus.global_position.y, 10.0, 0.05, "on the ground")
	assert_eq(director.host_car(me.peer_id, CarKinds.BUS, 0, PI), "", "again: that bus comes")
	assert_eq(_cars().size(), 1, "one of each kind per child")
	assert_eq(bus.colour, 0, "repainted")
	assert_gt(bus.global_position.z, ME_AT.z + 2.0, "now in front the other way")
	assert_eq(director.host_car(me.peer_id, CarKinds.GO_KART, 0, 0.0), "")
	assert_eq(_cars().size(), 2, "another kind is another car")


func test_a_called_car_never_lands_on_a_parked_one() -> void:
	_local(false)
	director.host_spawn({"kind": "bus", "colour": 0, "owner": "Friend", "pos": Vector3(0.5, 10.0, -3.0), "yaw": 0.0})
	var parked := director.car_of("Friend", CarKinds.BUS)
	assert_eq(director.host_car(me.peer_id, CarKinds.PICKUP, 0, 0.0), "")
	var mine := director.car_of("Kid", CarKinds.PICKUP)
	var a := VehicleRules.car_aabb(parked.global_position, parked.rotation.y, parked.kind)
	var b := VehicleRules.car_aabb(mine.global_position, mine.rotation.y, mine.kind)
	assert_false(a.intersects(b), "beside the bus, never inside it")


func test_a_child_has_at_most_four_out_and_a_world_twelve() -> void:
	_local(false)
	var kinds := [CarKinds.GO_KART, CarKinds.RACE_CAR, CarKinds.OFF_ROADER, CarKinds.PICKUP]
	for i in kinds.size():
		me.global_position = ME_AT + Vector3(i * 12.0, 0, 0)
		assert_eq(director.host_car(me.peer_id, kinds[i], 0, 0.0), "")
	assert_eq(_cars().size(), 4)
	me.global_position = ME_AT + Vector3(60, 0, 0)
	assert_eq(director.host_car(me.peer_id, CarKinds.BUS, 0, 0.0), "")
	assert_eq(_cars().size(), 4, "the fifth sends the oldest parked one home")
	assert_null(director.car_of("Kid", CarKinds.GO_KART), "the go-kart went back to the garage")
	assert_not_null(director.car_of("Kid", CarKinds.BUS))
	director.host_put_away(me.peer_id, CarKinds.BUS)
	await wait_process_frames(2)
	for i in VehicleRules.MAX_CARS - 3:
		director.host_spawn({"kind": "go_kart", "colour": 0, "owner": "Friend%d" % i, "pos": Vector3(-50 - i * 4, 10, 30),
			"yaw": 0.0})
	assert_eq(_cars().size(), VehicleRules.MAX_CARS)
	me.global_position = ME_AT + Vector3(-30, 0, -30)
	assert_eq(director.host_car(me.peer_id, CarKinds.MONSTER_TRUCK, 0, 0.0), "world_full",
		"three out and a full world: no more")
	assert_has(said, VehicleRules.words("world_full"), "the child hears why")


func test_survivor_cars_are_bought_with_gold_once_and_kept_in_the_profile() -> void:
	Game.mode = ModeRules.SURVIVOR
	Profile.data.bought = []
	Profile.data.survivor_gold = 10
	_local(false)
	assert_eq(director.host_car(me.peer_id, CarKinds.RACE_CAR, 0, 0.0), "not_owned")
	assert_has(said, VehicleRules.words("not_owned", CarKinds.RACE_CAR))
	assert_eq(director.host_buy(me.peer_id, CarKinds.RACE_CAR, 1, 0.0), "gold", "not enough gold")
	assert_eq(Profile.data.survivor_gold, 10, "nothing spent")
	Profile.data.survivor_gold = 1000
	assert_eq(director.host_buy(me.peer_id, CarKinds.RACE_CAR, 1, 0.0), "")
	assert_eq(Profile.data.survivor_gold, 1000 - CarKinds.price(CarKinds.RACE_CAR), "its price")
	assert_has(Profile.data.bought, VehicleRules.owned_id(CarKinds.RACE_CAR), "the child's own for good")
	assert_not_null(director.car_of("Kid", CarKinds.RACE_CAR), "and here it is")
	assert_eq(director.host_buy(me.peer_id, CarKinds.RACE_CAR, 1, 0.0), "owned", "never sold twice")
	assert_eq(Profile.data.survivor_gold, 1000 - CarKinds.price(CarKinds.RACE_CAR))
	director.host_put_away(me.peer_id, CarKinds.RACE_CAR)
	await wait_process_frames(2)
	assert_null(director.car_of("Kid", CarKinds.RACE_CAR), "PUT AWAY sends it back to the garage")
	assert_eq(director.host_car(me.peer_id, CarKinds.RACE_CAR, 0, 0.0), "", "CALL MY CAR brings it again, free")


func test_no_cars_in_the_arena() -> void:
	Game.mode = ModeRules.WAVE
	_local()
	assert_false(hud.more.buttons().has(director.cars_button), "no CARS in MORE")
	assert_eq(director.host_car(me.peer_id, CarKinds.GO_KART, 0, 0.0), "arena")
	assert_eq(_cars().size(), 0)


func test_no_room_no_car() -> void:
	_local(false)
	for x in range(-8, 9):
		for z in range(-8, 9):
			for y in range(10, 14):
				if absi(x) > 0 or absi(z) > 0:
					world.cells[Vector3i(x, y, z)] = BlockIds.STONE
	assert_eq(director.host_car(me.peer_id, CarKinds.BUS, 0, 0.0), "no_room")
	assert_eq(_cars().size(), 0)


# --- Getting in and out ------------------------------------------------------------------------------------------

func test_ride_says_drive_next_to_a_car_and_hop_off_in_it() -> void:
	_local()
	director.host_car(me.peer_id, CarKinds.OFF_ROADER, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.OFF_ROADER)
	await get_tree().physics_frame
	rides.scan()
	assert_eq(rides.nearby, car, "the car next to the child")
	assert_true(hud.ride_button.visible)
	assert_eq(hud.ride_button.text, "DRIVE")
	assert_eq(hud.ride_button.symbol, &"car")
	rides.press_ride()
	assert_eq(car.driver(), me.peer_id, "the first in drives")
	assert_true(me.is_riding())
	assert_true(me.in_car())
	me._process(DT)
	assert_almost_eq(me.global_position, car.seat_position(me.peer_id), Vector3.ONE * 0.001, "on the driver's seat")
	rides.scan()
	assert_eq(hud.ride_button.text, "HOP OFF")
	assert_true(hud.horn_button.visible, "HORN in a car")
	assert_false(hud.car_fly_button.visible, "no FLY in a ground car")
	rides.press_ride()
	assert_false(me.in_car())
	assert_eq(car.driver(), 0)
	var feet := Vector3i(me.global_position.floor())
	assert_false(BlockIds.is_solid(world.get_block(feet)), "never inside blocks")
	assert_false(VehicleRules.car_aabb(car.global_position, car.rotation.y, car.kind).has_point(me.global_position + Vector3(0, 0.5, 0)),
		"beside the car, not in it")


func test_friends_take_the_free_seats() -> void:
	_local(false)
	director.host_car(me.peer_id, CarKinds.PICKUP, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.PICKUP)
	var friend := _player(5, car.global_position + Vector3(2.0, 0, 0))
	var third := _player(6, car.global_position + Vector3(-2.0, 0, 0))
	me.global_position = car.global_position + Vector3(0, 0, 3.0)
	assert_eq(director.host_get_in(friend.peer_id, String(car.name)), "")
	assert_eq(car.driver(), 5, "the first in drives, whoever it is")
	assert_eq(director.host_get_in(me.peer_id, String(car.name)), "")
	assert_eq(VehicleRules.seat_of(car.seats, me.peer_id), 1, "the next one rides along")
	assert_eq(director.host_get_in(third.peer_id, String(car.name)), "full", "two seats")
	assert_eq(director.host_get_in(me.peer_id, String(car.name)), "busy", "already in it")
	friend.global_position = car.global_position
	friend._process(DT)
	assert_eq(friend.global_position, car.seat_position(5), "friends sit in their seats on every game")
	director.host_get_out(5)
	assert_eq(car.driver(), 0, "the driver's seat is free again")
	assert_eq(VehicleRules.seat_of(car.seats, me.peer_id), 1, "the passenger stays")


func test_the_host_refuses_what_it_cant_allow() -> void:
	_local(false)
	director.host_car(me.peer_id, CarKinds.GO_KART, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.GO_KART)
	me.global_position = car.global_position + Vector3(20, 0, 0)
	assert_eq(director.host_get_in(me.peer_id, String(car.name)), "too_far")
	me.global_position = car.global_position + Vector3(1.5, 0, 0)
	me.knocked_out = true
	assert_eq(director.host_get_in(me.peer_id, String(car.name)), "busy", "knocked out")
	me.knocked_out = false
	assert_eq(director.host_get_in(me.peer_id, "Nobody"), "unknown")
	assert_eq(director.host_get_in(9, String(car.name)), "busy", "nobody with that id")
	assert_eq(director.host_get_in(me.peer_id, String(car.name)), "")


func test_riders_who_cant_ride_any_more_get_out() -> void:
	_local(false)
	director.host_car(me.peer_id, CarKinds.BUS, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.BUS)
	var friend := _player(5, car.global_position + Vector3(2.0, 0, 0))
	me.global_position = car.global_position + Vector3(-2.0, 0, 0)
	director.host_get_in(me.peer_id, String(car.name))
	director.host_get_in(friend.peer_id, String(car.name))
	me.sleeping = true
	director.host_check()
	assert_false(car.has_rider(me.peer_id), "asleep: out")
	friend.queue_free()
	await wait_process_frames(1)
	director.host_check()
	assert_false(car.has_rider(5), "gone: the seat is free")


func test_only_the_driver_steers_and_flies() -> void:
	_local(false)
	director.host_car(me.peer_id, CarKinds.SKY_TAXI, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.SKY_TAXI)
	var friend := _player(5, car.global_position + Vector3(2.5, 0, 0))
	me.global_position = car.global_position + Vector3(-2.5, 0, 0)
	director.host_get_in(me.peer_id, String(car.name))
	director.host_get_in(friend.peer_id, String(car.name))
	car._heard_input(5, Vector3(0, 0, 1))
	assert_eq(car.input, Vector3.ZERO, "a passenger's stick moves nothing")
	car._heard_input(me.peer_id, Vector3(0, 0, 1))
	assert_eq(car.input, Vector3(0, 0, 1), "the driver's does")
	director.host_fly(5, true)
	assert_false(car.flying, "a passenger can't fly it")
	director.host_fly(me.peer_id, true)
	assert_true(car.flying, "the driver's FLY lifts it")


func test_the_horn_sounds_on_every_game_not_every_frame() -> void:
	_local(false)
	director.host_car(me.peer_id, CarKinds.BUS, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.BUS)
	var played: Array = []
	car.fx_played.connect(func(what: StringName) -> void: played.append(what))
	assert_eq(director.host_horn(me.peer_id), "not_in_a_car")
	me.global_position = car.global_position + Vector3(2.0, 0, 0)
	director.host_get_in(me.peer_id, String(car.name))
	played.clear()
	assert_eq(director.host_horn(me.peer_id), "")
	assert_eq(director.host_horn(me.peer_id), "wait", "a horn now and then")
	assert_eq(played.count(&"horn"), 1)


# --- The pickup's bed --------------------------------------------------------------------------------------------

func test_the_sandbox_pickup_loads_blocks_and_tips_them_out_behind() -> void:
	_local(false)
	director.host_car(me.peer_id, CarKinds.PICKUP, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.PICKUP)
	me.global_position = car.global_position + Vector3(2.0, 0, 0)
	assert_eq(director.host_load(me.peer_id, String(car.name), BlockIds.BRICK), "")
	assert_eq(VehicleRules.cargo_total(car.cargo), VehicleRules.LOAD_STEP)
	assert_eq(director.host_load(me.peer_id, String(car.name), ItemIds.SWORD), "not_a_block")
	var go := director.car_of("Kid", CarKinds.PICKUP)
	assert_eq(director.host_unload(me.peer_id, String(go.name)), "")
	assert_eq(car.cargo.size(), 0, "the bed is empty")
	var bricks := 0
	for c: Vector3i in world.cells:
		if world.cells[c] == BlockIds.BRICK:
			bricks += 1
			assert_gt(float(c.z) + 0.5, car.global_position.z, "behind the truck (its back is +z)")
	assert_eq(bricks, VehicleRules.LOAD_STEP, "tipped out as real blocks")


func test_the_survivor_pickup_takes_blocks_from_the_bag_and_gives_them_back() -> void:
	Game.mode = ModeRules.SURVIVOR
	Profile.data.bought = [VehicleRules.owned_id(CarKinds.PICKUP)]
	_local(false)
	var bag := Inventory.new()
	bag.add(BlockIds.PLANKS, 5)
	Session.set_inventory(me.peer_id, bag)
	director.host_car(me.peer_id, CarKinds.PICKUP, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.PICKUP)
	me.global_position = car.global_position + Vector3(2.0, 0, 0)
	assert_eq(director.host_load(me.peer_id, String(car.name), BlockIds.PLANKS), "")
	assert_eq(VehicleRules.cargo_total(car.cargo), 5, "all five planks from the bag")
	assert_eq(bag.count(BlockIds.PLANKS), 0)
	assert_eq(director.host_load(me.peer_id, String(car.name), BlockIds.PLANKS), "no_blocks")
	assert_eq(director.host_unload(me.peer_id, String(car.name)), "")
	assert_eq(bag.count(BlockIds.PLANKS), 5, "back into the bag")
	assert_eq(world.cells.size(), 0, "Survivor never makes free blocks")


# --- The save -----------------------------------------------------------------------------------------------------

func test_parked_cars_are_saved_with_the_world() -> void:
	_local(false)
	director.host_car(me.peer_id, CarKinds.PICKUP, 3, 0.0)
	var car := director.car_of("Kid", CarKinds.PICKUP)
	me.global_position = car.global_position + Vector3(2.0, 0, 0)
	director.host_load(me.peer_id, String(car.name), BlockIds.GLASS)
	director.host_spawn({"kind": "bus", "colour": 1, "owner": "Friend", "pos": Vector3(30, 10, 30), "yaw": 1.0})
	var saved := director.to_save()
	assert_eq(saved.size(), 2)
	for c in _cars():
		c.free()
	director.restore(VehicleRules.clean_save(saved))
	assert_eq(_cars().size(), 2, "both parked cars back")
	var back := director.car_of("Kid", CarKinds.PICKUP)
	assert_not_null(back)
	assert_eq(back.colour, 3)
	assert_eq(VehicleRules.cargo_total(back.cargo), VehicleRules.LOAD_STEP, "its load too")
	assert_almost_eq(director.car_of("Friend", CarKinds.BUS).rotation.y, 1.0, 0.001)


# --- LAN: a guest asks, the host decides --------------------------------------------------------------------------

func test_a_guest_only_asks() -> void:
	var peer := FakePeer.new()
	multiplayer.multiplayer_peer = peer
	peer.peer_connected.emit(1)
	_local(false)
	director.request_car(CarKinds.BUS, 0)
	director.request_get_in("Car1")
	director.request_horn()
	assert_eq(_cars().size(), 0, "nothing happens on the guest's own game")
	assert_false(peer.sent_to.is_empty(), "its asks went out")
	for to in peer.sent_to:
		assert_eq(to, 1, "to the host")


# --- The local game --------------------------------------------------------------------------------------------------

func test_a_flying_car_s_driver_gets_fly_then_land_and_up_and_down() -> void:
	_local()
	director.host_car(me.peer_id, CarKinds.HOVER_CAR, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.HOVER_CAR)
	me.global_position = car.global_position + Vector3(2.0, 0, 0)
	director.host_get_in(me.peer_id, String(car.name))
	director.local_step(DT)
	assert_true(hud.car_fly_button.visible, "FLY for a flying car's driver")
	assert_eq(hud.car_fly_button.text, "FLY")
	assert_eq(hud.jump_button.text, "JUMP", "on the ground")
	hud.car_fly_button.pressed.emit()
	assert_true(car.flying)
	director.local_step(DT)
	assert_eq(hud.car_fly_button.text, "LAND")
	assert_eq(hud.jump_button.text, "UP", "in the air JUMP climbs")
	assert_true(hud.fly_down_button.visible, "and DOWN dives")


func test_the_garage_opens_from_more() -> void:
	_local()
	assert_not_null(director.cars_button)
	assert_has(hud.more.buttons(), director.cars_button, "MORE → CARS")
	director.cars_button.pressed.emit()
	assert_true(director.garage_open(), "the garage")
	director.close_garage()
	assert_false(director.garage_open())


func test_keys_h_honks_and_e_hops_off() -> void:
	_local(false)
	director.host_car(me.peer_id, CarKinds.GO_KART, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.GO_KART)
	me.global_position = car.global_position + Vector3(1.5, 0, 0)
	director.host_get_in(me.peer_id, String(car.name))
	var played: Array = []
	car.fx_played.connect(func(what: StringName) -> void: played.append(what))
	var h := InputEventKey.new()
	h.physical_keycode = KEY_H
	h.pressed = true
	director._unhandled_input(h)
	assert_has(played, &"horn")
	var e := InputEventKey.new()
	e.physical_keycode = KEY_E
	e.pressed = true
	director._unhandled_input(e)
	assert_false(me.in_car(), "E hops off")


func test_a_pc_driver_hears_its_keys_on_getting_in() -> void:
	PlatformRules.simulated = {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}
	_local()
	director.host_car(me.peer_id, CarKinds.HOVER_CAR, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.HOVER_CAR)
	me.global_position = car.global_position + Vector3(2.0, 0, 0)
	director.host_get_in(me.peer_id, String(car.name))
	PlatformRules.simulated = {}
	await wait_process_frames(1)
	assert_string_contains(hud._toast_label.text, "W A S D", "the keys, once, as it starts")
	assert_string_contains(hud._toast_label.text, "Space")
