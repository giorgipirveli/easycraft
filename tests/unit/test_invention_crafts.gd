extends GutTest
## Owner #78 (spec §21e): how each invented machine flies, true to its science. The kite pulls you up for a moment on a
## windy hill; the balloon rises while its air is heated, sinks slowly as it cools and drifts with the wind; the plane
## must keep moving (too slow in the air, the wings stop lifting); the jet is the fastest. Pure steps, 60 a second.

const DT := 1.0 / 60.0


func _run(craft: int, v: Vector3, steer: Vector3, vertical: float, seconds: float, on_floor := false,
		wind := Vector3.ZERO) -> Vector3:
	for i in int(seconds / DT):
		v = FlightCrafts.step(craft, v, steer, vertical, wind, on_floor, DT)
	return v


func test_the_crafts_and_their_inventions() -> void:
	assert_eq(FlightCrafts.of_invention(InventionLine.KITE), FlightCrafts.Craft.KITE)
	assert_eq(FlightCrafts.of_invention(InventionLine.BALLOON), FlightCrafts.Craft.BALLOON)
	assert_eq(FlightCrafts.of_invention(InventionLine.PLANE), FlightCrafts.Craft.PLANE)
	assert_eq(FlightCrafts.of_invention(InventionLine.JET), FlightCrafts.Craft.JET)
	assert_eq(FlightCrafts.of_invention(InventionLine.GLIDER), FlightCrafts.Craft.NONE, "the glider is the glide")
	assert_eq(FlightCrafts.invention_of(FlightCrafts.Craft.JET), InventionLine.JET)
	assert_true(FlightCrafts.flies(FlightCrafts.Craft.BALLOON))
	assert_false(FlightCrafts.flies(FlightCrafts.Craft.KITE), "the kite lifts, never flies")
	assert_false(FlightCrafts.flies(FlightCrafts.Craft.NONE))
	assert_eq(FlightCrafts.valid(99), FlightCrafts.Craft.NONE, "a tampered number is none")


func test_hot_air_rises_and_cool_air_sinks_slowly() -> void:
	var v := _run(FlightCrafts.Craft.BALLOON, Vector3.ZERO, Vector3.ZERO, 1.0, 4.0)
	assert_almost_eq(v.y, FlightCrafts.BALLOON_RISE, 0.05, "heated, it rises")
	assert_lt(FlightCrafts.BALLOON_RISE, 4.0, "slowly")
	v = _run(FlightCrafts.Craft.BALLOON, v, Vector3.ZERO, 0.0, 6.0)
	assert_almost_eq(v.y, -FlightCrafts.BALLOON_SINK, 0.05, "cooling, it sinks slowly")
	v = _run(FlightCrafts.Craft.BALLOON, v, Vector3.ZERO, -1.0, 4.0)
	assert_almost_eq(v.y, -FlightCrafts.BALLOON_VENT, 0.05, "the vent lets hot air out: it sinks faster")


func test_the_wind_carries_the_balloon() -> void:
	var wind := Vector3(FlightCrafts.WIND_SPEED, 0, 0)
	var v := _run(FlightCrafts.Craft.BALLOON, Vector3.ZERO, Vector3.ZERO, 0.0, 6.0, false, wind)
	assert_almost_eq(v.x, FlightCrafts.WIND_SPEED, 0.05)
	v = _run(FlightCrafts.Craft.BALLOON, Vector3.ZERO, Vector3(0, 0, -1), 0.0, 6.0, false, wind)
	assert_almost_eq(Vector2(v.x, v.z).length(), Vector2(FlightCrafts.WIND_SPEED, FlightCrafts.BALLOON_STEER).length(),
		0.1, "a little steering on top of the wind")


func test_the_plane_must_keep_moving() -> void:
	var v := _run(FlightCrafts.Craft.PLANE, Vector3.ZERO, Vector3(0, 0, -1), 0.0, 3.0)
	assert_almost_eq(Vector2(v.x, v.z).length(), FlightCrafts.PLANE_TOP, 0.1, "full speed ahead")
	v = _run(FlightCrafts.Craft.PLANE, v, Vector3.ZERO, 0.0, 3.0)
	assert_almost_eq(v.z, -FlightCrafts.PLANE_TOP * FlightCrafts.CRUISE_SHARE, 0.1,
		"let go, it flies on at its slowest: a plane can't stand still in the air")
	assert_gt(-v.z, FlightCrafts.STALL_SPEED, "fast enough to stay up")
	var slow := _run(FlightCrafts.Craft.PLANE, Vector3(0, 0, -1), Vector3.ZERO, 1.0, 0.3)
	assert_lt(slow.y, 0.0, "too slow in the air: the wings stop lifting, even pulling UP")
	var climb := _run(FlightCrafts.Craft.PLANE, Vector3(0, 0, -FlightCrafts.PLANE_TOP), Vector3(0, 0, -1), 1.0, 1.0)
	assert_almost_eq(climb.y, FlightCrafts.CLIMB, 0.1, "fast, it climbs")
	var roll := FlightCrafts.step(FlightCrafts.Craft.PLANE, Vector3(0, 0, -4), Vector3(0, 0, -1), 0.0, Vector3.ZERO, true, DT)
	assert_lte(roll.y, 0.0, "slow on the ground: it rolls along")
	var lift := _run(FlightCrafts.Craft.PLANE, Vector3(0, 0, -FlightCrafts.LIFT_OFF_SPEED - 1.0), Vector3(0, 0, -1), 0.0, 0.5,
		true)
	assert_gt(lift.y, 0.0, "fast enough on the ground: the wings lift it off")
	var ground := _run(FlightCrafts.Craft.PLANE, Vector3(0, 0, -10), Vector3.ZERO, 0.0, 2.0, true)
	assert_almost_eq(Vector2(ground.x, ground.z).length(), 0.0, 0.01, "on the ground it rolls to a stop")


func test_the_jet_is_the_fastest() -> void:
	var v := _run(FlightCrafts.Craft.JET, Vector3.ZERO, Vector3(1, 0, 0), 0.0, 4.0)
	assert_almost_eq(v.x, FlightCrafts.JET_TOP, 0.1)
	assert_gt(FlightCrafts.JET_TOP, FlightCrafts.PLANE_TOP)
	assert_gt(FlightCrafts.PLANE_TOP, 11.0, "faster than the classic flying")
	assert_lte(FlightCrafts.JET_TOP, 22.0, "the world streams in time (the emulator's check)")


func test_the_kite_lifts_you_on_a_windy_hill_and_lets_you_down_gently() -> void:
	assert_true(FlightCrafts.windy_hill(MeadowsShape.SEA_LEVEL + FlightCrafts.KITE_HILL + 1.0, MeadowsShape.SEA_LEVEL))
	assert_false(FlightCrafts.windy_hill(MeadowsShape.SEA_LEVEL + 2.0, MeadowsShape.SEA_LEVEL), "low ground: no wind")
	assert_eq(FlightCrafts.kite_velocity(-5.0, 0.5), FlightCrafts.KITE_RISE, "the pull")
	assert_eq(FlightCrafts.kite_velocity(-10.0, 0.0), -FlightCrafts.KITE_FALL, "then down gently")
	assert_eq(FlightCrafts.kite_velocity(2.0, 0.0), 2.0)
	var height := FlightCrafts.KITE_RISE * FlightCrafts.KITE_LIFT_TIME
	assert_between(height, 4.0, 8.0, "a short lift: a few blocks")


func test_the_wind_blows_from_one_way_for_a_while() -> void:
	var w := FlightCrafts.wind_dir(12345, 7)
	assert_almost_eq(w.length(), 1.0, 0.001)
	assert_eq(w.y, 0.0)
	assert_eq(FlightCrafts.wind_dir(12345, 7), w, "the same seed and time: the same wind")
	var seen := {}
	for slot in 40:
		seen[FlightCrafts.wind_dir(12345, slot)] = true
	assert_gt(seen.size(), 3, "it changes now and then")
	assert_eq(FlightCrafts.wind_words(Vector3(1, 0, 0)), "The wind blows from the west.")
	assert_eq(FlightCrafts.wind_words(Vector3(0, 0, 1)), "The wind blows from the north.")
	assert_true(FlightCrafts.downwind(Vector3(1, 0, 0), Vector3(1, 0, 0)), "back to the wind")
	assert_true(FlightCrafts.downwind(Vector3(1, 0, -0.5).normalized(), Vector3(1, 0, 0)))
	assert_false(FlightCrafts.downwind(Vector3(-1, 0, 0), Vector3(1, 0, 0)), "facing into the wind: the kite falls")
