extends GutTest
## Owner #109 (spec §3b "Cars"): a ready-made car in the world (Vehicle). It keeps one compact collision box, solid like
## the world (players bump into it); it syncs who sits where, whether it flies, its colour and its load. The host moves it
## with the driver's stick (VehicleRules): forward and back, turning, never past its top speed; it hops up the steps it
## climbs (a go-kart 1, an off-roader 2, a monster truck 3) and bumps off higher walls; a body in its way stops it; in
## water a ground car floats slowly, a hover car glides over; a flying car takes off, climbs, never over its ceiling,
## and lands; a parked car sleeps (no physics) until someone gets in or the ground under it goes; a car that falls out of
## the world is carried back to safe ground.

const DT := 1.0 / 60.0


class CellWorld:
	extends WorldService
	var cells := {}
	var floor_y := 10   # every cell below this is stone

	func get_block(pos: Vector3i) -> int:
		if cells.has(pos):
			return cells[pos]
		return BlockIds.STONE if pos.y < floor_y else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return floor_y - 1

	var loaded := true

	func is_loaded(_pos: Vector3i) -> bool:
		return loaded


var world: CellWorld
var knocks: Array = []


func before_each() -> void:
	world = CellWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	knocks = []
	Session.knocked_back.connect(_knocked)


func after_each() -> void:
	Session.knocked_back.disconnect(_knocked)
	Session.register_world(null)


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _knocked(impulse: Vector3) -> void:
	knocks.append(impulse)


func _car(kind: StringName, pos: Vector3, car_name := "Car1", yaw := 0.0) -> Vehicle:
	var v := Vehicle.new()
	v.setup({"kind": String(kind), "colour": 1, "owner": "Kid", "pos": pos, "yaw": yaw, "id": car_name})
	add_child_autofree(v)
	v.set_physics_process(false)   # stepped by hand
	return v


func _ground(top: float, size := Vector3(200, 1, 200), at := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(at.x, top - size.y * 0.5, at.z)
	add_child_autofree(body)
	return body


## A step `h` blocks high across the way from z `z0` on (cells and a matching collider).
func _step(h: int, z0: int) -> void:
	for x in range(-6, 7):
		for z in range(-60, z0 + 1):
			for y in range(10, 10 + h):
				world.cells[Vector3i(x, y, z)] = BlockIds.STONE
	_ground(10.0 + h, Vector3(13, h, 60 + z0 + 1), Vector3(0.5, 0, (z0 + 1 - 60) * 0.5))


func _drive(v: Vehicle, seconds: float, wish: Vector3) -> void:
	for i in int(seconds / DT):
		v.set_input(wish)
		v._physics_process(DT)


static func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


# --- What it is -----------------------------------------------------------------------------------------------

func test_one_compact_solid_box_its_look_and_what_it_syncs() -> void:
	for kind in CarKinds.ORDER:
		var v := _car(kind, Vector3(0, 30, 0), "Car_" + String(kind))
		assert_eq(v.kind, kind)
		assert_eq(v.colour, 1)
		assert_eq(v.owner_name, "Kid")
		var shapes := v.find_children("*", "CollisionShape3D", true, false)
		assert_eq(shapes.size(), 1, "%s: one shape" % kind)
		assert_eq(((shapes[0] as CollisionShape3D).shape as BoxShape3D).size, CarKinds.box(kind))
		assert_eq(v.collision_layer, Vehicle.LAYER, "solid like the world: children bump into it")
		assert_true(v.collision_mask & Player.WORLD_COLLISION_MASK != 0, "it stands on the world")
		assert_true(v.collision_mask & 2 != 0, "players stop it")
		assert_true(v.collision_mask & Animal.LAYER != 0, "animals and monsters stop it")
		assert_eq(v.seats.size(), CarKinds.seats(kind))
		assert_eq(v.seat_nodes().size(), CarKinds.seats(kind), "%s: a seat node per seat" % kind)
		assert_eq(v.wheel_nodes().size(), CarKinds.wheels(kind).size())
		assert_eq(v.look().mesh, CarModels.body(kind, 1), "%s: its cached look in its colour" % kind)
		var cfg := (v.get_node("Sync") as MultiplayerSynchronizer).replication_config
		for prop: String in ["position", "rotation", "seats", "flying", "colour", "cargo"]:
			assert_true(cfg.has_property(NodePath(".:" + prop)), "%s syncs %s" % [kind, prop])
	var taxi := _car(CarKinds.SKY_TAXI, Vector3(10, 30, 0), "Taxi")
	assert_eq(taxi.rotor_nodes().size(), 4, "the sky taxi's rotors")
	var bus := _car(CarKinds.BUS, Vector3(20, 30, 0), "Bus")
	bus.colour = 3
	assert_eq(bus.look().mesh, CarModels.body(CarKinds.BUS, 3), "a new colour is a new look at once")


func test_a_seat_is_where_its_rider_s_feet_go_wherever_it_faces() -> void:
	var v := _car(CarKinds.OFF_ROADER, Vector3(10, 20, 10))
	assert_almost_eq(v.seat_spot(0), Vector3(10, 20, 10) + CarKinds.seat_offsets(CarKinds.OFF_ROADER)[0],
		Vector3.ONE * 0.001)
	v.rotation.y = PI
	var back_left: Vector3 = CarKinds.seat_offsets(CarKinds.OFF_ROADER)[2]
	assert_almost_eq(v.seat_spot(2), Vector3(10 - back_left.x, 20 + back_left.y, 10 - back_left.z), Vector3.ONE * 0.001)
	assert_eq(v.seat_nodes()[1].global_position, v.seat_spot(1), "the seat node is the seat (VR follows the rider on it)")
	v.seats = PackedInt32Array([7, 0, 9, 0])
	assert_eq(v.seat_position(9), v.seat_spot(2))
	assert_false(v.seat_position(5).is_finite(), "no seat for a stranger")
	assert_eq(v.driver(), 7)
	assert_true(v.has_rider(9))
	v.seats = PackedInt32Array([0, -3, 4])
	assert_eq(v.seats, PackedInt32Array([0, 0, 4, 0]), "a synced list is cleaned to its seats")


# --- Driving --------------------------------------------------------------------------------------------------

func test_the_host_drives_it_with_the_driver_s_stick() -> void:
	_ground(10.0)
	var v := _car(CarKinds.RACE_CAR, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	v.host_board(7)
	var top := 0.0
	for i in 300:
		v.set_input(Vector3(0, 0, 1))
		v._physics_process(DT)
		top = maxf(top, _flat(v.velocity))
	assert_lt(v.global_position.z, -30.0, "it drove ahead")
	assert_almost_eq(top, CarKinds.GROUND_TOP, 0.05, "up to its top speed")
	assert_lte(top, CarKinds.GROUND_TOP + 0.001, "never past it")
	assert_almost_eq(v.global_position.y, 10.0, 0.1, "on the ground")
	var yaw := v.rotation.y
	_drive(v, 1.0, Vector3(1, 0, 1))
	assert_lt(v.rotation.y, yaw - 0.5, "right turns it right")
	assert_almost_eq(v.rotation.x, 0.0, 0.0001, "it never tips")
	assert_almost_eq(v.rotation.z, 0.0, 0.0001, "and never rolls")


func test_a_stick_not_heard_for_a_while_lets_go_and_nobody_steers_an_empty_car() -> void:
	_ground(10.0)
	var v := _car(CarKinds.GO_KART, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	v.host_board(7)
	_drive(v, 1.0, Vector3(0, 0, 1))
	assert_gt(_flat(v.velocity), 5.0)
	for i in int((VehicleRules.INPUT_STALE + 4.0) / DT):
		v._physics_process(DT)
	assert_almost_eq(_flat(v.velocity), 0.0, 0.01, "the driver's game went quiet: it rolls to a stop")
	var empty := _car(CarKinds.GO_KART, Vector3(10.5, 10.02, 0.5), "Car2")
	await get_tree().physics_frame
	_drive(empty, 1.0, Vector3(0, 0, 1))
	assert_almost_eq(empty.global_position, Vector3(10.5, 10.0, 0.5), Vector3(0.01, 0.05, 0.01), "no driver, no driving")


func test_each_kind_climbs_its_own_steps_and_bumps_off_higher_ones() -> void:
	for case: Array in [[CarKinds.GO_KART, 1, true], [CarKinds.GO_KART, 2, false], [CarKinds.OFF_ROADER, 2, true],
			[CarKinds.OFF_ROADER, 3, false], [CarKinds.MONSTER_TRUCK, 3, true]]:
		await _climb(case[0], case[1], case[2])


func _climb(kind: StringName, h: int, climbs: bool) -> void:
	var w := CellWorld.new()
	add_child_autofree(w)
	world = w
	Session.register_world(w)
	var base := _ground(10.0)
	_step(h, -8)
	var v := _car(kind, Vector3(0.5, 10.02, 0.5), "Climber")
	await get_tree().physics_frame
	v.host_board(7)
	var bumped := false
	for i in 360:
		v.set_input(Vector3(0, 0, 1))
		v._physics_process(DT)
		bumped = bumped or v.velocity.z > 0.5
	var what := "%s, a %d-block step" % [kind, h]
	if climbs:
		assert_gt(v.global_position.y, 10.0 + h - 0.2, "%s: up it goes" % what)
		assert_lt(v.global_position.z, -12.0, "%s: and on" % what)
	else:
		assert_lt(v.global_position.y, 10.5, "%s: too high" % what)
		assert_true(bumped, "%s: it bumps back gently" % what)
		var half := CarKinds.box(kind).z * 0.5
		assert_gt(v.global_position.z, -7.0 + half - 0.2, "%s: never through it" % what)
	v.free()
	for n in get_children():
		if n is StaticBody3D:
			n.free()
	base = null


func test_a_body_in_the_way_stops_it_and_is_pushed_gently_aside() -> void:
	_ground(10.0)
	var me: Player = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = Vector3(0.9, 10.0, -8.0)
	me._spawned = true
	var v := _car(CarKinds.PICKUP, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	await get_tree().physics_frame
	v.host_board(7)
	for i in 240:
		v.set_input(Vector3(0, 0, 1))
		v._physics_process(DT)
	var front := v.global_position.z - CarKinds.box(CarKinds.PICKUP).z * 0.5
	assert_gt(front, -8.0 - 0.1, "it never drives through a child")
	assert_gt(knocks.size(), 0, "the child is pushed aside")
	assert_gt((knocks[0] as Vector3).x, 0.0, "to the side the child stands on")
	assert_lte(Vector2(knocks[0].x, knocks[0].z).length(), VehicleRules.PUSH + 0.001, "gently")
	var many := knocks.size()
	assert_lt(many, 240 * DT / VehicleRules.PUSH_EVERY + 2, "not every frame")


func test_another_car_is_a_wall_it_bumps_off_and_never_shoves() -> void:
	_ground(10.0)
	var parked := _car(CarKinds.BUS, Vector3(0.5, 10.02, -12.0), "Parked")
	var v := _car(CarKinds.GO_KART, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	for i in 10:
		parked._physics_process(DT)
	var parked_at := parked.global_position
	v.host_board(7)
	var played: Array = []
	v.fx_played.connect(func(what: StringName) -> void: played.append(what))
	var bumped := false
	for i in 240:
		v.set_input(Vector3(0, 0, 1))
		v._physics_process(DT)
		parked._physics_process(DT)
		bumped = bumped or v.velocity.z > 0.5
	assert_true(bumped, "it bumps back off the bus")
	assert_has(played, &"thud")
	assert_false(played.has(&"beep"), "a car is no body to push aside")
	assert_almost_eq(parked.global_position, parked_at, Vector3.ONE * 0.05, "the parked bus stays where it is")


# --- Water ----------------------------------------------------------------------------------------------------

func _lake() -> void:
	world.floor_y = 7
	for x in range(-8, 9):
		for z in range(-60, 8):
			for y in range(7, 10):
				world.cells[Vector3i(x, y, z)] = BlockIds.WATER
	_ground(7.0)


func test_in_water_a_ground_car_floats_slowly_and_a_hover_car_glides_over() -> void:
	_lake()
	var v := _car(CarKinds.OFF_ROADER, Vector3(0.5, 7.05, 0.5))
	var h := _car(CarKinds.HOVER_CAR, Vector3(6.5, 7.05, 0.5), "Hover")
	await get_tree().physics_frame
	v.host_board(7)
	h.host_board(8)
	var top := 0.0
	var hover_top := 0.0
	for i in 360:
		v.set_input(Vector3(0, 0, 1))
		h.set_input(Vector3(0, 0, 1))
		v._physics_process(DT)
		h._physics_process(DT)
		if i > 120:
			top = maxf(top, _flat(v.velocity))
			hover_top = maxf(hover_top, _flat(h.velocity))
	assert_almost_eq(v.global_position.y, 10.0 - RideRules.DRAFT, 0.2, "the car floats on the top")
	assert_lt(v.global_position.z, -3.0, "paddling ahead")
	assert_lte(top, VehicleRules.FLOAT_SPEED + 0.001, "slowly")
	assert_gt(h.global_position.y, 9.8, "the hover car is over the water")
	assert_gt(hover_top, VehicleRules.FLOAT_SPEED + 3.0, "at its speed")


# --- Flying ---------------------------------------------------------------------------------------------------

func test_a_flying_car_takes_off_climbs_never_over_its_ceiling_and_lands() -> void:
	_ground(10.0)
	var v := _car(CarKinds.HOVER_CAR, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	v.host_board(7)
	_drive(v, 0.5, Vector3(0, 1, 0))
	assert_true(v.flying, "JUMP on the ground takes off")
	_drive(v, 9.0, Vector3(0, 1, 0))
	_drive(v, 3.0, Vector3(0, 1, 1))
	var ceiling := VehicleRules.ceiling_y(CarKinds.HOVER_CAR, world.surface_height(0, 0) + 1.0)
	assert_lte(v.global_position.y, ceiling + 0.3, "never over the hover car's ceiling")
	assert_gt(v.global_position.y, ceiling - 1.0, "but up there")
	assert_lte(_flat(v.velocity), CarKinds.fly_speed(CarKinds.HOVER_CAR) + 0.001)
	_drive(v, 1.0, Vector3(0, 0, 0))
	assert_almost_eq(v.velocity.y, 0.0, 0.05, "let go, it hovers")
	v.host_fly(false)
	for i in int(12.0 / DT):
		v._physics_process(DT)
		if not v.flying:
			break
	assert_false(v.flying, "LAND brings it down and it drives again")
	assert_almost_eq(v.global_position.y, 10.0, 0.15)


func test_a_flying_car_lands_on_a_lake_and_floats() -> void:
	_lake()
	var v := _car(CarKinds.SKY_TAXI, Vector3(0.5, 7.05, 0.5))
	await get_tree().physics_frame
	v.host_board(7)
	v.host_fly(true)
	_drive(v, 3.0, Vector3(0, 1, 0))
	assert_gt(v.global_position.y, 14.0, "up over the lake")
	v.host_fly(false)
	for i in int(10.0 / DT):
		v._physics_process(DT)
		if not v.flying:
			break
	assert_false(v.flying, "LAND on water: it comes down onto the water's top and floats")
	_drive(v, 2.0, Vector3(0, 0, 0))
	assert_almost_eq(v.global_position.y, 10.0 - RideRules.DRAFT, 0.25, "floating like a boat")


func test_the_sky_taxi_flies_higher_but_never_over_the_flight_ceiling() -> void:
	world.floor_y = 140
	_ground(140.0)
	var v := _car(CarKinds.SKY_TAXI, Vector3(0.5, 140.02, 0.5))
	await get_tree().physics_frame
	v.host_board(7)
	v.host_fly(true)
	assert_true(v.flying, "FLY lifts it")
	_drive(v, 8.0, Vector3(0, 1, 0))
	assert_lte(v.global_position.y, VehicleRules.FLY_CEILING + 0.3, "under the sky's darkening, far from space")
	assert_gt(v.global_position.y, VehicleRules.FLY_CEILING - 1.0)


func test_a_flying_car_comes_down_gently_when_its_driver_hops_off() -> void:
	_ground(10.0)
	var v := _car(CarKinds.SKY_TAXI, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	v.host_board(7)
	_drive(v, 0.5, Vector3(0, 1, 0))
	_drive(v, 3.0, Vector3(0, 1, 0))
	assert_gt(v.global_position.y, 18.0)
	v.host_leave(7)
	var fastest := 0.0
	for i in int(10.0 / DT):
		v._physics_process(DT)
		fastest = minf(fastest, v.velocity.y)
	assert_false(v.flying, "it landed by itself")
	assert_almost_eq(v.global_position.y, 10.0, 0.15)
	assert_gte(fastest, -VehicleRules.LAND_SPEED - 0.5, "gently, never a drop")


# --- Parked ---------------------------------------------------------------------------------------------------

func test_a_parked_car_sleeps_until_the_ground_under_it_goes() -> void:
	_ground(10.0)
	var v := _car(CarKinds.BUS, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	for i in 30:
		v._physics_process(DT)
	assert_true(v.asleep(), "parked: no physics at all")
	world.floor_y = 0   # the ground was dug away under it (the collider below stays for the fall's end)
	for c in get_children():
		if c is StaticBody3D:
			c.position.y -= 6.0
	await get_tree().physics_frame
	for i in 120:
		v._physics_process(DT)
	assert_lt(v.global_position.y, 9.0, "it fell to the ground below")


func test_a_parked_car_far_from_everyone_waits_for_its_ground_to_load() -> void:
	_ground(10.0)
	var v := _car(CarKinds.PICKUP, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	for i in 30:
		v._physics_process(DT)
	assert_true(v.asleep())
	world.loaded = false   # nobody near: its chunk is not loaded (it reads as air, and has no collider)
	world.floor_y = 0
	for c in get_children():
		if c is StaticBody3D:
			c.position.y -= 6.0
	await get_tree().physics_frame
	for i in 60:
		v._physics_process(DT)
	assert_true(v.asleep(), "it never falls through ground that is just not loaded")
	assert_almost_eq(v.global_position.y, 10.0, 0.05)


func test_a_car_that_falls_out_of_the_world_is_carried_back_to_safe_ground() -> void:
	_ground(10.0, Vector3(20, 1, 20))
	var v := _car(CarKinds.GO_KART, Vector3(0.5, 10.02, 0.5))
	await get_tree().physics_frame
	v.host_board(7)
	_drive(v, 1.0, Vector3(0, 0, 0))
	var safe := v.global_position
	v.global_position = Vector3(0.5, SpawnRules.FALL_LIMIT_Y - 5.0, 0.5)
	for i in 12:
		v._physics_process(DT)
	assert_almost_eq(v.global_position.y, safe.y, 0.6, "back on the ground it last stood on")
	assert_true(v.has_rider(7), "with its driver still in it")


func test_a_monster_truck_bounces_when_it_lands() -> void:
	_ground(10.0)
	var v := _car(CarKinds.MONSTER_TRUCK, Vector3(0.5, 16.0, 0.5))
	await get_tree().physics_frame
	v.host_board(7)
	var bounced := false
	var landed := false
	for i in 180:
		v._physics_process(DT)
		landed = landed or v.is_on_floor()
		bounced = bounced or (landed and v.velocity.y > 1.0)
	assert_true(bounced, "boing!")
	var kart := _car(CarKinds.GO_KART, Vector3(10.5, 16.0, 0.5), "Kart")
	await get_tree().physics_frame
	kart.host_board(8)
	var kart_bounced := false
	var kart_landed := false
	for i in 180:
		kart._physics_process(DT)
		kart_landed = kart_landed or kart.is_on_floor()
		kart_bounced = kart_bounced or (kart_landed and kart.velocity.y > 1.0)
	assert_false(kart_bounced, "a go-kart just lands")
