extends GutTest
## Owner #106: what the descent and the way home show (FlightShots.pose, FlightDials.read), as pure rules. The descent:
## the ground as far under the lander as the child's descent says, the flame as big as the throttle, the legs out, the
## pad to steer over. A crash: the lander tips over in the dust, then the capsule's rescue rockets lift it; the trip
## home (the Earth ahead and growing), a fiery re-entry ending in the clouds, the parachute in the real world beside the
## pad (never on the rocket standing there), the rocket falling by the Launch Site. In VR never a shake.


func _info(extra: Dictionary = {}) -> Dictionary:
	var i := {"destination": SpaceRules.MOON, "time": 1.0, "waiting": &"", "done": false, "throttle": 0.0,
		"auto_burn": false, "flown": true, "burn_at": 1.0}
	i.merge(extra, true)
	return i


func _descent(h: float, v: float, thr: float = 0.0, state: int = FlightDescent.FLYING) -> Dictionary:
	return {"descent": {"h": h, "v": v, "thr": thr, "state": state, "fuel": 1.0}, "waiting": FlightPlan.DESCEND,
		"throttle": thr}


func test_the_landing_brings_the_ground_to_where_the_descent_starts() -> void:
	var start := FlightShots.pose(FlightPlan.LANDING, 0.0, _info({"waiting": FlightPlan.LEGS}))
	var end := FlightShots.pose(FlightPlan.LANDING, 1.0, _info({"done": true}))
	assert_eq(start.ground_h, FlightShots.LAND_FROM)
	assert_almost_eq(float(end.ground_h), FlightDescent.START_HEIGHT, 0.01)
	var easy := FlightShots.pose(FlightPlan.LANDING, 1.0, _info({"done": true, "descent_from": FlightDescent.EASY_HEIGHT}))
	assert_almost_eq(float(easy.ground_h), FlightDescent.EASY_HEIGHT, 0.01, "the easy try starts lower")


func test_the_descent_shows_the_childs_height_and_throttle() -> void:
	var high := FlightShots.pose(FlightPlan.DESCENT, 0.0, _info(_descent(100.0, 8.0, 0.0)))
	assert_true(high.ground)
	assert_eq(high.ground_h, 100.0)
	assert_eq(high.legs, 1.0)
	assert_eq(high.target, &"pad")
	var burning := FlightShots.pose(FlightPlan.DESCENT, 0.0, _info(_descent(40.0, 3.0, 1.0)))
	assert_eq(burning.ground_h, 40.0)
	assert_gt(burning.fire, high.fire + 0.5, "the flame as big as the throttle")
	var dry := _descent(40.0, 3.0, 1.0)
	dry.descent.fuel = 0.0
	assert_eq(FlightShots.pose(FlightPlan.DESCENT, 0.0, _info(dry)).fire, 0.0, "out of fuel: no flame")
	var crashed := FlightShots.pose(FlightPlan.DESCENT, 0.3, _info(_descent(0.0, 12.0, 0.0, FlightDescent.CRASHED)))
	assert_gt(crashed.tilt, 10.0, "too fast: it tips over")
	assert_gt(crashed.shake, 0.1)
	var soft := FlightShots.pose(FlightPlan.DESCENT, 0.3, _info(_descent(0.0, 2.0, 0.4, FlightDescent.LANDED)))
	assert_eq(soft.tilt, 0.0, "a soft landing stands")


func test_the_crash_then_the_rescue_rockets_lift_the_capsule() -> void:
	var hit := FlightShots.pose(FlightPlan.CRASH, 0.1, _info())
	assert_true(hit.ground)
	assert_eq(hit.ground_h, 0.0)
	assert_gt(hit.tilt, 10.0)
	assert_eq(hit.fire, 0.0)
	var away := FlightShots.pose(FlightPlan.CRASH, 0.95, _info())
	assert_gt(away.ground_h, 30.0, "up and away")
	assert_gt(away.fire, 0.5)
	assert_lt(away.tilt, hit.tilt)


func test_home_the_earth_ahead_then_a_fiery_re_entry_into_the_clouds() -> void:
	var a := FlightShots.pose(FlightPlan.ESCAPE, 0.1, _info())
	var b := FlightShots.pose(FlightPlan.ESCAPE, 0.9, _info())
	assert_true(a.earth.show)
	assert_lt(float(b.earth.alt), float(a.earth.alt), "the Earth growing")
	assert_true(a.dest.show)
	assert_gt(float(b.dest.alt), float(a.dest.alt), "the Moon falling behind")
	assert_false(a.world)
	var entry := FlightShots.pose(FlightPlan.HOME_ENTRY, 0.5, _info())
	assert_gt(entry.heat, 0.8, "the heat shield glows")
	assert_true(entry.earth.show)
	assert_gt(FlightShots.pose(FlightPlan.HOME_ENTRY, 1.0, _info()).cloud, 0.9, "into the clouds: the world is under them")


func test_the_parachute_comes_down_beside_the_pad_in_the_real_world() -> void:
	var top := FlightShots.pose(FlightPlan.HOME_CHUTE, 0.0, _info())
	var down := FlightShots.pose(FlightPlan.HOME_CHUTE, 1.0, _info())
	assert_true(top.world, "the real world again")
	assert_eq(top.chute, 1.0)
	assert_gt(top.rise, 60.0)
	assert_almost_eq(float(down.rise), 0.0, 0.01, "touchdown on the ground")
	assert_gt(absf(float(top.side)), 4.0, "beside the pad, never on the rocket standing there")
	assert_eq(top.sky, 0.0, "the day's sky")


func test_the_rocket_falls_by_the_launch_site() -> void:
	var fall := FlightShots.pose(FlightPlan.WRECK, 0.2, _info())
	assert_true(fall.world)
	assert_between(float(fall.wreck), 0.0, 1.0)
	assert_eq(fall.look, &"pad", "the camera looks at the pad")
	assert_eq(float(fall.rise), 0.0, "the capsule on the ground")
	var hit := FlightShots.pose(FlightPlan.WRECK, FlightShots.WRECK_HIT + 0.02, _info())
	assert_gt(hit.shake, 0.1, "the ground shakes as it hits")
	assert_true(FlightShots.pose(FlightPlan.HOME, 0.5, _info()).world)


func test_no_shake_in_vr() -> void:
	for phase in [FlightPlan.CRASH, FlightPlan.HOME_ENTRY, FlightPlan.WRECK]:
		for q in [0.05, 0.5, FlightShots.WRECK_HIT + 0.02]:
			assert_eq(FlightShots.pose(phase, q, _info({"vr": true})).shake, 0.0, "%s %.2f" % [phase, q])
	var d := _info(_descent(0.0, 12.0, 0.0, FlightDescent.CRASHED))
	d["vr"] = true
	assert_eq(FlightShots.pose(FlightPlan.DESCENT, 0.2, d).shake, 0.0)


func test_the_dials_in_the_descent_and_on_the_way_home() -> void:
	var steps := FlightPlan.steps(SpaceRules.MOON, 2)
	var i := steps.size() - 2
	assert_eq(steps[i].phase, FlightPlan.DESCENT)
	var d := FlightDials.read(steps, i, 0.0, SpaceRules.MOON, 2, 0.0, 1, {"h": 60.0, "v": 4.0, "fuel": 0.5})
	assert_almost_eq(float(d.height), 0.06, 0.0001, "60 m")
	assert_almost_eq(float(d.speed), 0.004, 0.0001, "4 m/s")
	assert_eq(d.height_of, "the Moon")
	var full := FlightDials.read(steps, i, 0.0, SpaceRules.MOON, 2, 0.0, 1, {"h": 60.0, "v": 4.0, "fuel": 1.0})
	assert_almost_eq(float(d.fuel[1]), float(full.fuel[1]) * 0.5, 0.0001, "the lander's fuel is the descent's")
	assert_gt(float(full.fuel[1]), 0.5, "most of the lander's fuel is kept for the landing")
	var home := steps.slice(0, i + 1)
	home.append_array(FlightPlan.crash_steps(SpaceRules.MOON))
	var escape := FlightDials.read(home, i + 2, 0.2, SpaceRules.MOON, 2, 0.0, 1)
	var nearer := FlightDials.read(home, i + 2, 0.8, SpaceRules.MOON, 2, 0.0, 1)
	assert_true(escape.home, "the screen says TO EARTH")
	assert_eq(escape.height_of, "Earth")
	assert_lt(float(nearer.distance), float(escape.distance), "Earth nearer and nearer")
	var down := FlightDials.read(home, home.size() - 1, 0.5, SpaceRules.MOON, 2, 0.0, 1)
	assert_eq(float(down.height), 0.0)
	assert_eq(float(down.distance), 0.0)
