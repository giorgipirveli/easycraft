extends GutTest
## Owner #79 (spec §25.3): the dials show the real numbers — speed in km/s, the height, the fuel of every stage, the
## distance to the Moon counting down from 384,400 km, the trip's real clock (3 days to the Moon) — as pure rules
## (FlightDials.read) of the step, its progress and the burn.


func _read(dest: int, stages: int, phase: StringName, p: float, burn: float = 0.0, dropped: int = 0,
		nth: int = 0) -> Dictionary:
	var steps := FlightPlan.steps(dest, stages)
	var seen := 0
	for i in steps.size():
		if steps[i].phase == phase:
			if seen == nth:
				return FlightDials.read(steps, i, p, dest, stages, burn, dropped)
			seen += 1
	return {}


func test_on_the_pad_nothing_moves_and_the_moon_is_384400_km_away() -> void:
	var d := _read(SpaceRules.MOON, 2, FlightPlan.COUNTDOWN, 0.5)
	assert_eq(d.speed, 0.0)
	assert_eq(d.height, 0.0)
	assert_eq(d.distance, 384400.0)
	assert_eq(d.height_of, "Earth")
	assert_false(d.light_speed)


func test_the_distance_to_the_moon_only_counts_down() -> void:
	var steps := FlightPlan.steps(SpaceRules.MOON, 2)
	var last := INF
	for i in steps.size():
		for p in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var d := FlightDials.read(steps, i, p, SpaceRules.MOON, 2, 1.0 if p > 0.6 else 0.0, 1 if i > 4 else 0)
			assert_lte(d.distance, last, "%s at %.2f" % [steps[i].phase, p])
			last = d.distance
	assert_eq(last, 0.0, "touchdown")


func test_orbit_is_almost_8_km_a_second_and_the_burn_takes_us_to_11() -> void:
	var before := _read(SpaceRules.MOON, 2, FlightPlan.ORBIT, 0.5)
	assert_between(before.speed, 6.0, 7.9)
	var burned := _read(SpaceRules.MOON, 2, FlightPlan.ORBIT, 0.6, 1.0)
	assert_almost_eq(burned.speed, 10.9, 0.05, "fast enough to leave for the Moon")
	var half := _read(SpaceRules.MOON, 2, FlightPlan.ORBIT, 9.0 / 16.0, 0.5)
	assert_between(half.speed, 8.5, 10.0, "the burn speeds us up as it goes")


func test_the_trip_takes_3_real_days() -> void:
	var d := _read(SpaceRules.MOON, 2, FlightPlan.CRUISE, 1.0)
	assert_eq(d.clock, "3 days")
	assert_lt(d.distance, 10000.0)
	assert_eq(_read(SpaceRules.MOON, 2, FlightPlan.ASCENT, 1.0).clock, "3 min")
	assert_eq(_read(SpaceRules.MARS, 2, FlightPlan.CRUISE, 1.0).clock, "7 months")


func test_on_the_moon_it_all_comes_to_rest() -> void:
	var d := _read(SpaceRules.MOON, 2, FlightPlan.LANDED, 0.5, 0.0, 1)
	assert_eq(d.speed, 0.0)
	assert_eq(d.height, 0.0)
	assert_eq(d.distance, 0.0)
	assert_eq(d.height_of, "the Moon")
	var landing := _read(SpaceRules.MOON, 2, FlightPlan.LANDING, 0.5, 0.0, 1)
	assert_eq(landing.height_of, "the Moon")
	assert_between(landing.height, 1.0, 110.0)


func test_light_speed_is_light_speed() -> void:
	var d := _read(SpaceRules.MARS, 2, FlightPlan.JUMP, 0.7, 0.0, 1)
	assert_true(d.light_speed)
	assert_eq(d.speed, FlightDials.LIGHT_SPEED)
	assert_false(_read(SpaceRules.MARS, 2, FlightPlan.CRUISE, 0.5, 0.0, 1).light_speed)


func test_a_make_believe_planet_is_too_far_to_say() -> void:
	var d := _read(SpaceRules.BOING, 2, FlightPlan.CRUISE, 0.2, 0.0, 1)
	assert_eq(d.distance, -1.0, "unknown")
	assert_eq(d.clock, "")


func test_every_stage_has_its_fuel_and_a_dropped_stage_shows_as_gone() -> void:
	var start := _read(SpaceRules.MOON, 2, FlightPlan.COUNTDOWN, 0.0)
	assert_eq(start.fuel, [1.0, 1.0])
	var climb := _read(SpaceRules.MOON, 2, FlightPlan.ASCENT, 0.5)
	assert_lt(climb.fuel[0], 1.0, "the first stage burns")
	assert_eq(climb.fuel[1], 1.0, "the lander waits")
	var empty := _read(SpaceRules.MOON, 2, FlightPlan.STAGING, 0.0)
	assert_lt(empty.fuel[0], 0.1, "empty when it is let go")
	var gone := _read(SpaceRules.MOON, 2, FlightPlan.STAGING, 0.5, 0.0, 1)
	assert_eq(gone.fuel[0], -1.0, "fallen away")
	var landed := _read(SpaceRules.MOON, 2, FlightPlan.LANDED, 1.0, 0.0, 1)
	assert_gt(landed.fuel[1], 0.05, "fuel left for the way home")
	var steps := FlightPlan.steps(SpaceRules.MOON, 3)
	var last := [1.0, 1.0, 1.0]
	for i in steps.size():
		var d := FlightDials.read(steps, i, 0.5, SpaceRules.MOON, 3, 0.5, 0)
		for k in 3:
			assert_lte(d.fuel[k], last[k] + 0.0001, "stage %d never fills up (%s)" % [k, steps[i].phase])
		last = d.fuel


func test_one_stage_does_it_all() -> void:
	var d := _read(SpaceRules.MOON, 1, FlightPlan.LANDED, 1.0)
	assert_eq(d.fuel.size(), 1)
	assert_between(d.fuel[0], 0.05, 0.2)
