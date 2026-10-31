extends GutTest
## Owner #109 (spec §3b "Cars"): the pure rules of driving and flying a car, getting in and out, where a called car goes,
## the garage's limits and what the save keeps. Driving is arcade and kind: the stick's forward and back speed it up and
## slow it down (never past its top speed), left and right turn it (a little even standing still, so a child is never
## stuck); it never slides sideways; a flying car climbs, dives and hovers, never over the flight ceiling.

const DT := 1.0 / 60.0


func _drive(kind: StringName, seconds: float, steer: float, throttle: float, v := Vector3.ZERO, yaw := 0.0) -> Dictionary:
	var r := {"velocity": v, "yaw": yaw}
	for i in int(seconds / DT):
		r = VehicleRules.drive_step(kind, r.velocity, r.yaw, steer, throttle, true, DT)
	return r


func _fly(kind: StringName, seconds: float, steer: float, throttle: float, vertical: float, v := Vector3.ZERO) -> Dictionary:
	var r := {"velocity": v, "yaw": 0.0}
	for i in int(seconds / DT):
		r = VehicleRules.fly_step(kind, r.velocity, r.yaw, steer, throttle, vertical, DT)
	return r


static func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


# --- Driving ---------------------------------------------------------------------------------------------

func test_forward_speeds_up_to_the_top_speed_and_never_past_it() -> void:
	for kind in CarKinds.ORDER:
		var r := _drive(kind, 8.0, 0.0, 1.0)
		assert_almost_eq(_flat(r.velocity), CarKinds.speed(kind), 0.01, "%s reaches its top speed" % kind)
		assert_lt((r.velocity as Vector3).z, 0.0, "%s goes forward (-z)" % kind)
		assert_almost_eq(float(r.yaw), 0.0, 0.0001, "straight on")
	var kart := _drive(CarKinds.GO_KART, 0.5, 0.0, 1.0)
	var bus := _drive(CarKinds.BUS, 0.5, 0.0, 1.0)
	assert_gt(_flat(kart.velocity), _flat(bus.velocity), "a go-kart is quicker off the mark than a bus")
	var fast := VehicleRules.drive_step(CarKinds.RACE_CAR, Vector3(0, 0, -40), 0.0, 0.0, 1.0, true, DT)
	assert_lte(_flat(fast.velocity), CarKinds.GROUND_TOP + 0.001, "never past 14 m/s, whatever came in")


func test_back_reverses_slowly_and_letting_go_rolls_to_a_stop() -> void:
	var r := _drive(CarKinds.OFF_ROADER, 6.0, 0.0, -1.0)
	assert_gt((r.velocity as Vector3).z, 0.0, "backwards")
	assert_almost_eq(_flat(r.velocity), CarKinds.reverse_speed(CarKinds.OFF_ROADER), 0.01)
	var going := _drive(CarKinds.OFF_ROADER, 6.0, 0.0, 1.0)
	var coast := _drive(CarKinds.OFF_ROADER, 1.0, 0.0, 0.0, going.velocity)
	assert_lt(_flat(coast.velocity), CarKinds.speed(CarKinds.OFF_ROADER), "it slows by itself")
	assert_gt(_flat(coast.velocity), 0.5, "rolls on a little")
	var braked := _drive(CarKinds.OFF_ROADER, 1.0, 0.0, -1.0, going.velocity)
	assert_lt(_flat(braked.velocity), _flat(coast.velocity), "back brakes harder than letting go")
	var stopped := _drive(CarKinds.OFF_ROADER, 6.0, 0.0, 0.0, going.velocity)
	assert_almost_eq(_flat(stopped.velocity), 0.0, 0.001, "and stops")
	var parked := {"velocity": going.velocity, "yaw": 0.0}
	for i in int(1.0 / DT):
		parked = VehicleRules.drive_step(CarKinds.OFF_ROADER, parked.velocity, parked.yaw, 0.0, 0.0, true, DT, -1.0, true)
	assert_almost_eq(_flat(parked.velocity), 0.0, 0.001, "with nobody driving it stops at once (never rolls off alone)")


func test_left_and_right_turn_it_and_it_never_slides_sideways() -> void:
	var r := _drive(CarKinds.RACE_CAR, 1.0, 1.0, 1.0)
	assert_lt(float(r.yaw), -0.1, "right turns right (yaw goes down)")
	var l := _drive(CarKinds.RACE_CAR, 1.0, -1.0, 1.0)
	assert_gt(float(l.yaw), 0.1, "left turns left")
	var forward := Basis(Vector3.UP, float(r.yaw)) * Vector3.FORWARD
	var going := r.velocity as Vector3
	var side := Vector2(going.x, going.z) - Vector2(forward.x, forward.z) * Vector2(going.x, going.z).dot(Vector2(forward.x, forward.z))
	assert_lt(side.length(), 1.5, "it goes where it faces, nearly")
	var still := _drive(CarKinds.BUS, 1.0, 1.0, 0.0)
	assert_lt(float(still.yaw), -0.05, "even standing still it turns a little: never stuck")
	var kart := _drive(CarKinds.GO_KART, 1.0, 1.0, 1.0)
	var bus := _drive(CarKinds.BUS, 1.0, 1.0, 1.0)
	assert_lt(float(kart.yaw), float(bus.yaw), "the go-kart turns sharper")
	var back := _drive(CarKinds.GO_KART, 1.0, 1.0, -1.0)
	assert_gt(float(back.yaw), 0.0, "backing up, right swings the front left, as in a real car")


func test_in_the_air_a_ground_car_keeps_going_and_does_not_steer() -> void:
	var v := Vector3(0, -3, -8)
	var r := VehicleRules.drive_step(CarKinds.OFF_ROADER, v, 0.0, 1.0, 1.0, false, DT)
	assert_eq(r.velocity, v, "no grip in the air")
	assert_eq(float(r.yaw), 0.0)


func test_a_dirty_stick_is_cleaned() -> void:
	assert_eq(VehicleRules.clean_input(Vector3(NAN, 0, 1)), Vector3.ZERO)
	assert_eq(VehicleRules.clean_input(Vector3(3, -5, 0.5)), Vector3(1, -1, 0.5))
	var r := VehicleRules.drive_step(CarKinds.GO_KART, Vector3.ZERO, 0.0, 9.0, 9.0, true, DT)
	var ok := VehicleRules.drive_step(CarKinds.GO_KART, Vector3.ZERO, 0.0, 1.0, 1.0, true, DT)
	assert_eq(r.velocity, ok.velocity, "more than full stick is full stick")


# --- Steps, walls, people ------------------------------------------------------------------------------------

func test_each_kind_hops_the_steps_it_climbs_and_bumps_off_higher_ones() -> void:
	for kind in CarKinds.ORDER:
		for h in range(1, 4):
			assert_eq(VehicleRules.wants_hop(kind, h), h <= CarKinds.climb(kind), "%s, a %d-block step" % [kind, h])
		assert_false(VehicleRules.wants_hop(kind, 0), "flat ground is no step")
	var g := VehicleRules.GRAVITY
	for h in range(1, 4):
		var v := VehicleRules.hop_velocity(h, g)
		var top := v * v / (2.0 * g)
		assert_gt(top, float(h), "a %d-block hop clears the step" % h)
		assert_lt(top, h + 0.6, "and not much more")
	var bumped := RideRules.bump(Vector3(0, 0, -10), Vector3(0, 0, 1))
	assert_gt(bumped.z, 0.0, "a wall bumps it back (the rides' gentle bump)")


func test_a_body_in_the_way_is_pushed_gently_aside() -> void:
	var push := VehicleRules.push_aside(Vector3(0, 0, -8), Vector3(0, 0, 0), Vector3(0.4, 0, -2.0))
	assert_gt(push.x, 0.0, "to the side it stands on")
	assert_lte(Vector2(push.x, push.z).length(), VehicleRules.PUSH + 0.001, "gently")
	assert_gt(push.y, 0.0, "a little hop")
	var other := VehicleRules.push_aside(Vector3(0, 0, -8), Vector3(0, 0, 0), Vector3(-0.4, 0, -2.0))
	assert_lt(other.x, 0.0)
	var dead := VehicleRules.push_aside(Vector3(0, 0, -8), Vector3(0, 0, 0), Vector3(0, 0, -2.0))
	assert_gt(Vector2(dead.x, dead.z).length(), 0.5, "right in front: still aside, never under the car")


# --- Flying --------------------------------------------------------------------------------------------------

func test_a_flying_car_climbs_dives_and_hovers_gently() -> void:
	for kind in CarKinds.FLYING:
		var up := _fly(kind, 3.0, 0.0, 0.0, 1.0)
		assert_almost_eq((up.velocity as Vector3).y, VehicleRules.FLY_CLIMB, 0.01, "%s climbs" % kind)
		var down := _fly(kind, 3.0, 0.0, 0.0, -1.0)
		assert_almost_eq((down.velocity as Vector3).y, -VehicleRules.FLY_DIVE, 0.01, "%s dives" % kind)
		var hover := _fly(kind, 3.0, 0.0, 0.0, 0.0, Vector3(0, 4, 0))
		assert_almost_eq((hover.velocity as Vector3).y, 0.0, 0.01, "%s hovers when let go" % kind)
		var ahead := _fly(kind, 8.0, 0.0, 1.0, 0.0)
		assert_almost_eq(_flat(ahead.velocity), CarKinds.fly_speed(kind), 0.01, "%s flies at its speed" % kind)
		assert_lte(_flat(ahead.velocity), CarKinds.FLY_TOP + 0.001, "never past the paid Fly")
		var turn := _fly(kind, 1.0, 1.0, 0.0, 0.0)
		assert_lt(float(turn.yaw), -0.5, "%s turns on the spot in the air" % kind)
	assert_lte(VehicleRules.FLY_CLIMB, RideRules.FLY_CLIMB, "gentler than the dragon")
	assert_lte(VehicleRules.FLY_DIVE, RideRules.FLY_DIVE)


func test_never_over_the_flight_ceiling() -> void:
	assert_lt(VehicleRules.FLY_CEILING, SpaceRules.CLIMB_FROM, "under the sky's darkening")
	assert_lt(VehicleRules.FLY_CEILING, SpaceRules.SPACE_Y, "a car never reaches the space line")
	assert_eq(VehicleRules.ceiling_y(CarKinds.HOVER_CAR, 30.0), 30.0 + CarKinds.above_ground(CarKinds.HOVER_CAR))
	assert_eq(VehicleRules.ceiling_y(CarKinds.SKY_TAXI, 140.0), VehicleRules.FLY_CEILING, "the ceiling holds over a peak")
	var v := VehicleRules.held_under(Vector3(3, 5, 0), 60.0, 54.0)
	assert_lt(v.y, 0.0, "over the ceiling it sinks back")
	assert_lt(v.y, VehicleRules.held_under(Vector3(3, 5, 0), 54.5, 54.0).y, "faster the further over (a cliff below)")
	assert_gte(v.y, -VehicleRules.FLY_DIVE, "never faster than a dive")
	assert_eq(v.x, 3.0)
	assert_eq(VehicleRules.held_under(Vector3(0, 5, 0), 54.0, 54.0).y, 0.0, "at it: no higher")
	assert_eq(VehicleRules.held_under(Vector3(0, 5, 0), 40.0, 54.0).y, 5.0, "under it: free")


# --- Getting in and out ----------------------------------------------------------------------------------------

func test_getting_in_near_the_car() -> void:
	var at := Vector3(10, 5, 10)
	var kind := CarKinds.BUS
	assert_true(VehicleRules.can_board(at + Vector3(2.0, 0, 0), at, kind, 0.0), "beside it")
	assert_true(VehicleRules.can_board(at + Vector3(0, 0, 4.5), at, kind, 0.0), "at the back of a long bus")
	assert_false(VehicleRules.can_board(at + Vector3(0, 0, 9.0), at, kind, 0.0), "too far")
	assert_true(VehicleRules.can_board(at + Vector3(4.5, 0, 0), at, kind, PI * 0.5), "a turned bus: its back is that way")
	assert_false(VehicleRules.can_board(at + Vector3(0, 9, 0), at, kind, 0.0), "not from high above")
	assert_false(VehicleRules.can_board(Vector3(INF, 0, 0), at, kind, 0.0))
	assert_false(VehicleRules.can_board(at + Vector3(0, 0, 5.9), at, kind, 0.0))
	assert_true(VehicleRules.can_board(at + Vector3(0, 0, 5.9), at, kind, 0.0, VehicleRules.HOST_TOLERANCE),
		"the host allows a little more (a guest's lag)")


func test_seats_driver_first() -> void:
	var seats := VehicleRules.empty_seats(CarKinds.OFF_ROADER)
	assert_eq(seats, PackedInt32Array([0, 0, 0, 0]))
	assert_eq(VehicleRules.free_seat(seats), 0, "the first in drives")
	assert_eq(VehicleRules.board_word(seats), "DRIVE")
	seats[0] = 5
	assert_eq(VehicleRules.free_seat(seats), 1, "then the passengers' seats")
	assert_eq(VehicleRules.board_word(seats), "GET IN")
	assert_eq(VehicleRules.seat_of(seats, 5), 0)
	assert_eq(VehicleRules.seat_of(seats, 7), -1)
	seats = PackedInt32Array([5, 6, 7, 8])
	assert_eq(VehicleRules.free_seat(seats), -1, "full")
	assert_eq(VehicleRules.board_word(seats), "")
	assert_eq(VehicleRules.riders(seats), [5, 6, 7, 8] as Array[int])
	assert_eq(VehicleRules.clean_seats(PackedInt32Array([1, -4, 2]), 2), PackedInt32Array([1, 0]),
		"a synced list with nonsense is cleaned to the car's seats")


# --- Where a car goes ------------------------------------------------------------------------------------------

func test_a_called_car_comes_in_front_on_free_ground() -> void:
	var flat := func(c: Vector3i) -> bool: return c.y < 0
	var spot := VehicleRules.place_spot(Vector3(0.5, 0, 0.5), 0.0, CarKinds.PICKUP, flat, [])
	assert_false(spot.is_empty())
	assert_lt((spot.pos as Vector3).z, -2.0, "in front (-z)")
	assert_almost_eq((spot.pos as Vector3).y, 0.0, 0.01, "on the ground")
	assert_almost_eq(float(spot.yaw), 0.0, 0.001, "facing the way the child looks")
	var wall := func(c: Vector3i) -> bool: return c.y < 0 or (c.z < -1 and c.z > -9)
	var side := VehicleRules.place_spot(Vector3(0.5, 0, 0.5), 0.0, CarKinds.PICKUP, wall, [])
	assert_false(side.is_empty(), "a wall in front: beside or behind the child")
	assert_true(VehicleRules.box_free(side.pos, float(side.yaw), CarKinds.PICKUP, wall, []))
	var boxed := func(c: Vector3i) -> bool: return c.y < 0 or absi(c.x) > 1 or absi(c.z) > 1
	assert_true(VehicleRules.place_spot(Vector3(0.5, 0, 0.5), 0.0, CarKinds.BUS, boxed, []).is_empty(), "no room: none")
	var child := AABB(Vector3(-0.5, 0, -4.5), Vector3(1, 1.8, 1))
	var around := VehicleRules.place_spot(Vector3(0.5, 0, 0.5), 0.0, CarKinds.PICKUP, flat, [child])
	assert_false(around.is_empty())
	assert_false(VehicleRules.car_aabb(around.pos, float(around.yaw), CarKinds.PICKUP).intersects(child),
		"never on top of a friend")
	var step := func(c: Vector3i) -> bool: return c.y < (1 if c.z < -1 else 0)
	var up := VehicleRules.place_spot(Vector3(0.5, 0, 0.5), 0.0, CarKinds.GO_KART, step, [])
	assert_almost_eq((up.pos as Vector3).y, 1.0, 0.01, "up on a step in front")


## Wherever it comes, the child can get in from where they stand (a car out of reach is no help).
func test_a_called_car_is_always_within_reach() -> void:
	var feet := Vector3(0.5, 0, 0.5)
	var worlds := [
		func(c: Vector3i) -> bool: return c.y < 0,
		func(c: Vector3i) -> bool: return c.y < 0 or (c.z < -1 and c.z > -9),
		func(c: Vector3i) -> bool: return c.y < 0 or c.z < -1 or c.x > 1,
		func(c: Vector3i) -> bool: return c.y < 0 or c.z < -1 or c.x > 1 or c.x < -1,
	]
	for kind in CarKinds.ORDER:
		for i in worlds.size():
			var spot := VehicleRules.place_spot(feet, 0.0, kind, worlds[i], [AABB(Vector3(0, 0, 0), Vector3(1, 1.8, 1))])
			if spot.is_empty():
				continue
			assert_true(VehicleRules.can_board(feet, spot.pos, kind, float(spot.yaw)), "%s, world %d: in reach" % [kind, i])


# --- The garage's limits -----------------------------------------------------------------------------------------

func test_which_car_goes_home_when_a_child_has_too_many_out() -> void:
	var cars: Array[Dictionary] = []
	for i in VehicleRules.PER_PLAYER - 1:
		cars.append({"owner": "Ana", "born": i, "ridden": false})
	cars.append({"owner": "Bo", "born": 50, "ridden": false})
	assert_eq(VehicleRules.goes_home(cars, "Ana"), -1, "room for one more")
	cars.append({"owner": "Ana", "born": 60, "ridden": false})
	assert_eq(VehicleRules.goes_home(cars, "Ana"), 0, "the oldest parked one")
	cars[0].ridden = true
	assert_eq(VehicleRules.goes_home(cars, "Ana"), 1, "never one somebody rides")
	assert_eq(VehicleRules.goes_home(cars, "Bo"), -1)
	assert_eq(VehicleRules.MAX_CARS, 12)


func test_owned_cars_live_in_the_profile() -> void:
	assert_eq(VehicleRules.owned_id(CarKinds.BUS), "car:bus")
	var bought: Array[String] = ["lesson:g4_math_1", "car:bus", "car:spaceship", "car:go_kart"]
	assert_eq(VehicleRules.owned_kinds(bought), [CarKinds.GO_KART, CarKinds.BUS] as Array[StringName],
		"known kinds only, in the garage's order")
	assert_eq(VehicleRules.may_get(CarKinds.BUS, true, []), "", "the Sandbox: every car, free")
	assert_eq(VehicleRules.may_get(CarKinds.BUS, false, [CarKinds.BUS]), "", "Survivor: an owned one")
	assert_eq(VehicleRules.may_get(CarKinds.RACE_CAR, false, [CarKinds.BUS]), "not_owned")
	assert_eq(VehicleRules.may_get(&"spaceship", true, []), "unknown")
	assert_ne(VehicleRules.words("not_owned", CarKinds.RACE_CAR), "")
	assert_string_contains(VehicleRules.words("not_owned", CarKinds.RACE_CAR), "Race Car")


func test_the_save_keeps_parked_cars_and_drops_nonsense() -> void:
	var saved := [
		{"kind": "bus", "colour": 2, "owner": "Ana", "pos": [1.5, 9.0, -3.0], "yaw": 0.5, "cargo": []},
		{"kind": "spaceship", "colour": 0, "owner": "Ana", "pos": [0, 0, 0], "yaw": 0.0},
		{"kind": "bus", "colour": 1, "owner": "Ana", "pos": [5, 9, 5], "yaw": 0.0},
		{"kind": "pickup", "colour": 77, "owner": "Bo", "pos": [NAN, 0, 0], "yaw": 0.0},
		{"kind": "pickup", "colour": 77, "owner": "Bo", "pos": [2, 3, 4], "yaw": INF, "cargo": [BlockIds.BRICK, 8, 99999, 5]},
		"junk",
	]
	var clean := VehicleRules.clean_save(saved)
	assert_eq(clean.size(), 2, "one car of a kind per child; unknown kinds and broken places dropped")
	assert_eq(clean[0].kind, "bus")
	assert_eq(clean[0].colour, 2)
	assert_eq(clean[1].colour, 0, "an unknown colour: the first")
	assert_eq(clean[1].yaw, 0.0)
	assert_eq(clean[1].cargo, [BlockIds.BRICK, 8], "only real blocks in the bed")
	var many := []
	for i in 30:
		many.append({"kind": String(CarKinds.ORDER[i % 8]), "colour": 0, "owner": "Kid%d" % i, "pos": [i, 0, 0], "yaw": 0.0})
	assert_eq(VehicleRules.clean_save(many).size(), VehicleRules.MAX_CARS, "never more than a world holds")
	assert_eq(VehicleRules.clean_save(null), [])


# --- The pickup's bed ---------------------------------------------------------------------------------------------

func test_the_pickup_s_bed_holds_a_load_of_blocks() -> void:
	var r := VehicleRules.cargo_add(PackedInt32Array(), BlockIds.BRICK, VehicleRules.LOAD_STEP)
	assert_eq(r.added, 8)
	assert_eq(VehicleRules.cargo_total(r.cargo), 8)
	r = VehicleRules.cargo_add(r.cargo, BlockIds.BRICK, 8)
	assert_eq(r.cargo, PackedInt32Array([BlockIds.BRICK, 16]), "the same block stacks")
	r = VehicleRules.cargo_add(r.cargo, BlockIds.GLASS, 30)
	assert_eq(r.added, VehicleRules.CARGO_MAX - 16, "a full bed takes no more")
	assert_eq(VehicleRules.cargo_total(r.cargo), VehicleRules.CARGO_MAX)
	assert_eq(VehicleRules.cargo_add(r.cargo, BlockIds.STONE, 1).added, 0)
	assert_eq(VehicleRules.cargo_add(PackedInt32Array(), ItemIds.SWORD, 1).added, 0, "only blocks")
	assert_eq(VehicleRules.cargo_add(PackedInt32Array(), BlockIds.WATER, 1).added, 0, "never water")
	var shown := VehicleRules.cargo_shown(PackedInt32Array([BlockIds.BRICK, 3, BlockIds.GLASS, 20]))
	assert_eq(shown.size(), VehicleRules.CARGO_SHOWN, "a few cubes show the load")
	assert_eq(shown.slice(0, 3), [BlockIds.BRICK, BlockIds.BRICK, BlockIds.BRICK] as Array[int])


func test_tipping_a_load_out_makes_a_pile_behind_the_truck() -> void:
	var solid := func(c: Vector3i) -> bool: return c.y < 0
	var cells := VehicleRules.tip_cells(Vector3(0.5, 0, 3.5), 12, func(c: Vector3i) -> bool: return not solid.call(c), solid)
	assert_eq(cells.size(), 12)
	var lowest := 99
	for c: Vector3i in cells:
		lowest = mini(lowest, c.y)
		assert_lte(Vector2(c.x + 0.5 - 0.5, c.z + 0.5 - 3.5).length(), 2.0, "close together: %s" % c)
	assert_eq(lowest, 0, "on the ground")
	assert_eq(cells.count(cells[0]), 1)
	var boxed := VehicleRules.tip_cells(Vector3(0.5, 0, 3.5), 5, func(_c: Vector3i) -> bool: return false, solid)
	assert_eq(boxed.size(), 0, "no room: nothing")


# --- The camera ----------------------------------------------------------------------------------------------------

func test_the_camera_follows_behind_a_moving_car() -> void:
	assert_eq(VehicleRules.chase_yaw(0.0, 1.0, 0.5, 10.0, 0.1), 0.0, "standing: the child looks round freely")
	assert_eq(VehicleRules.chase_yaw(0.0, 1.0, 8.0, 0.2, 0.1), 0.0, "just turned by the child: it waits")
	var y := VehicleRules.chase_yaw(0.0, 1.0, 8.0, 10.0, 0.1)
	assert_gt(y, 0.0, "driving: it swings round behind")
	assert_lt(y, 1.0, "gently")
	var round := VehicleRules.chase_yaw(3.1, -3.1, 8.0, 10.0, 0.01)
	assert_gt(absf(round), 3.1, "the short way round (through PI, never back through 0)")


# --- The keys a driver hears -----------------------------------------------------------------------------------------

func test_a_pc_driver_hears_the_keys_and_a_pad_driver_the_buttons() -> void:
	var pc := VehicleRules.drive_hint(false, VehicleRules.KEYBOARD)
	assert_string_contains(pc, "W A S D")
	assert_string_contains(pc, "H")
	assert_string_contains(pc, "E")
	assert_false(pc.contains("Space"), "a ground car has no FLY")
	assert_string_contains(VehicleRules.drive_hint(true, VehicleRules.KEYBOARD), "Space", "a flying car's FLY")
	var pad := VehicleRules.drive_hint(true, VehicleRules.PAD)
	assert_string_contains(pad, "stick")
	assert_string_contains(pad, "Y", "Triangle / Y hops off")
	assert_eq(VehicleRules.drive_hint(false, VehicleRules.TOUCH), "", "a phone has its buttons on the screen")
