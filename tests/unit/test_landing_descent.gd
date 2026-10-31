extends GutTest
## Owner #106 ("landing a rocket to the moon is simply too easy"): the final descent is the child's own skill
## (FlightDescent, pure). Height, falling speed and the lander's fuel (from its real tanks); the throttle slows the
## fall; touching down at or under SAFE_SPEED (3 m/s: the real Moon landers' legs were built for 3.05 m/s) lands,
## faster or out of fuel above the ground crashes. No autopilot: nobody touching the throttle crashes. The colours say
## what to do (green safe, yellow careful, red too fast), the beep quickens near the ground, the words are short and kind.
## A first try is easier (lower, slower, more fuel) and holds for its hint card until GO.


## Ticks `d` with the throttle `thr(d)` until it touches down (or `most` seconds pass).
func _fly(d: FlightDescent, thr: Callable, delta: float = 0.1, most: float = 300.0) -> float:
	var t := 0.0
	while not d.done() and t < most:
		d.tick(delta, float(thr.call(d)))
		t += delta
	return t


func test_it_starts_high_and_falling_with_the_landers_fuel() -> void:
	var d := FlightDescent.new(SpaceRules.MOON)
	assert_eq(d.height, FlightDescent.START_HEIGHT)
	assert_eq(d.speed, FlightDescent.START_SPEED, "falling already")
	assert_eq(d.fuel_fraction(), 1.0, "full")
	assert_false(d.done())
	assert_eq(d.state, FlightDescent.FLYING)
	assert_almost_eq(d.gravity, 1.62, 0.001, "the Moon's real pull")
	assert_almost_eq(d.thrust, 1.62 * FlightDescent.THRUST, 0.001)


func test_the_safe_speed_is_3_metres_a_second() -> void:
	assert_eq(FlightDescent.SAFE_SPEED, 3.0)


func test_nobody_touching_the_throttle_crashes_no_autopilot() -> void:
	for u in [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.EUROPA, SpaceRules.PLUTO]:
		var d := FlightDescent.new(u)
		var t := _fly(d, func(_d: FlightDescent) -> float: return 0.0)
		assert_eq(d.state, FlightDescent.CRASHED, "world %d" % u)
		assert_gt(d.touchdown_speed, FlightDescent.SAFE_SPEED * 3.0, "much too fast")
		assert_lt(t, 15.0, "it falls by itself")


func test_a_good_pilot_lands_on_every_world_with_fuel_left() -> void:
	for u in [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.MERCURY, SpaceRules.VENUS, SpaceRules.EUROPA, SpaceRules.IO,
			SpaceRules.TITAN, SpaceRules.GANYMEDE, SpaceRules.PLUTO, SpaceRules.TRITON, SpaceRules.RINGS, SpaceRules.BOING,
			SpaceRules.RAINBOW]:
		for easy in [false, true]:
			var d := FlightDescent.new(u, easy)
			var t := _fly(d, FlightDescent.test_pilot)
			assert_eq(d.state, FlightDescent.LANDED, "world %d easy %s" % [u, easy])
			assert_lte(d.touchdown_speed, FlightDescent.SAFE_SPEED)
			assert_gt(d.fuel_fraction(), 0.2, "fuel left")
			assert_between(t, 6.0, 40.0, "a short, real descent (%.1f s)" % t)


func test_at_or_under_the_safe_speed_lands_faster_crashes() -> void:
	for speed in [0.5, 2.9, 3.0]:
		var d := FlightDescent.new(SpaceRules.MOON)
		d.height = 0.05
		d.speed = speed
		_fly(d, func(x: FlightDescent) -> float: return x.gravity / x.thrust, 0.02)   # hovering: the speed stays
		assert_eq(d.state, FlightDescent.LANDED, "%.1f m/s lands" % speed)
		assert_almost_eq(d.touchdown_speed, speed, 0.001)
	for speed in [3.2, 5.0, 12.0]:
		var d := FlightDescent.new(SpaceRules.MOON)
		d.height = 0.05
		d.speed = speed
		_fly(d, func(x: FlightDescent) -> float: return x.gravity / x.thrust, 0.02)
		assert_eq(d.state, FlightDescent.CRASHED, "%.1f m/s crashes" % speed)


func test_the_throttle_slows_the_fall_and_burns_fuel() -> void:
	var a := FlightDescent.new(SpaceRules.MOON)
	var b := FlightDescent.new(SpaceRules.MOON)
	for i in 20:
		a.tick(0.1, 0.0)
		b.tick(0.1, 1.0)
	assert_gt(a.speed, FlightDescent.START_SPEED, "falling faster and faster")
	assert_lt(b.speed, FlightDescent.START_SPEED, "the engine slows it")
	assert_eq(a.fuel_fraction(), 1.0, "no throttle, no fuel used")
	assert_lt(b.fuel_fraction(), 1.0)
	var hover := FlightDescent.new(SpaceRules.MOON)
	hover.speed = 0.0
	for i in 10:
		hover.tick(0.1, 1.0 / FlightDescent.THRUST)
	assert_almost_eq(hover.speed, 0.0, 0.01, "at 40% it hovers")


func test_out_of_fuel_above_the_ground_crashes() -> void:
	var d := FlightDescent.new(SpaceRules.MOON)
	d.height = 40.0
	d.speed = 1.0
	d.fuel = 0.0
	assert_string_contains(d.words(), "Out of fuel")
	var t := _fly(d, func(_d: FlightDescent) -> float: return 1.0)
	assert_eq(d.state, FlightDescent.CRASHED, "an empty engine cannot slow it")
	assert_lt(t, 10.0)


func test_full_throttle_all_the_way_climbs_runs_dry_and_crashes() -> void:
	var d := FlightDescent.new(SpaceRules.MOON)
	var top := 0.0
	var rising := false
	while not d.done():
		d.tick(0.1, 1.0)
		top = maxf(top, d.height)
		rising = rising or d.zone() == FlightDescent.UP
	assert_true(rising, "it went up")
	assert_lte(top, FlightDescent.START_HEIGHT + FlightDescent.CEILING + 0.01, "never higher than the ceiling")
	assert_eq(d.fuel, 0.0)
	assert_eq(d.state, FlightDescent.CRASHED)


func test_the_colours_say_what_to_do() -> void:
	var d := FlightDescent.new(SpaceRules.MOON)
	d.height = 100.0
	d.speed = 5.0
	assert_eq(d.zone(), FlightDescent.GREEN, "plenty of room to slow down")
	d.speed = 18.5
	assert_eq(d.zone(), FlightDescent.YELLOW, "careful: slow down now")
	d.speed = 30.0
	assert_eq(d.zone(), FlightDescent.RED, "too fast")
	d.height = 0.5
	d.speed = 2.5
	assert_eq(d.zone(), FlightDescent.GREEN, "near the ground green is a safe touchdown")
	d.speed = 4.0
	assert_ne(d.zone(), FlightDescent.GREEN, "and faster is not")
	d.speed = -2.0
	assert_eq(d.zone(), FlightDescent.UP)
	for z in [FlightDescent.GREEN, FlightDescent.YELLOW, FlightDescent.RED, FlightDescent.UP]:
		assert_true(FlightDescent.COLORS.has(z))
	assert_true(FlightDescent.COLORS[FlightDescent.GREEN].g > FlightDescent.COLORS[FlightDescent.GREEN].r)
	assert_true(FlightDescent.COLORS[FlightDescent.RED].r > FlightDescent.COLORS[FlightDescent.RED].g)


## The lead (2026-10-16, VR-RIG's finding): green must mean "you will land". A child who only keeps the dial green
## (full throttle when it is not green, none when it is), reacting up to 0.3 s late, lands on every world.
func test_a_child_who_keeps_the_dial_green_lands_on_every_world() -> void:
	for u in [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.MERCURY, SpaceRules.VENUS, SpaceRules.EUROPA, SpaceRules.IO,
			SpaceRules.TITAN, SpaceRules.GANYMEDE, SpaceRules.PLUTO, SpaceRules.TRITON, SpaceRules.RINGS, SpaceRules.BOING,
			SpaceRules.RAINBOW]:
		for lag in [0.0, 0.1, 0.2, 0.3]:
			var d := FlightDescent.new(u)
			var seen: Array[StringName] = []   # what the child saw, `lag` seconds ago
			var steps := int(round(lag / 0.05))
			while not d.done():
				seen.append(d.zone())
				var z: StringName = seen[maxi(seen.size() - 1 - steps, 0)]
				d.tick(0.05, 1.0 if z == FlightDescent.YELLOW or z == FlightDescent.RED else 0.0)
			assert_eq(d.state, FlightDescent.LANDED, "world %d, %.1f s late: touched down at %.2f m/s" % [u, lag,
				d.touchdown_speed])


func test_green_leaves_room_for_a_childs_reaction() -> void:
	var d := FlightDescent.new(SpaceRules.MOON)
	d.height = 10.0
	d.speed = 5.5   # the old dial's green (half the brake from now on) left no time to react
	assert_eq(d.zone(), FlightDescent.YELLOW, "careful: slow down now, while there is time")
	d.speed = 4.0
	assert_eq(d.zone(), FlightDescent.GREEN)
	d.height = 0.3
	d.speed = 2.6   # the ground before a child reacts: it lands as it falls
	assert_eq(d.zone(), FlightDescent.GREEN)
	d.speed = 3.5
	assert_ne(d.zone(), FlightDescent.GREEN)


func test_short_kind_words() -> void:
	var d := FlightDescent.new(SpaceRules.MOON)
	d.height = 60.0
	d.speed = 30.0
	assert_eq(d.words(), "Slow down! Hold the throttle!")
	d.speed = 3.0
	d.height = 10.0
	assert_eq(d.words(), "Good: gently now.")
	d.speed = -3.0
	assert_string_contains(d.words(), "Ease off")
	d.speed = 2.0
	d.height = 60.0
	d.fuel = d.fuel_max * 0.1
	assert_string_contains(d.words(), "seconds of fuel")
	for w in [d.words(), FlightDescent.HINT, FlightDescent.LANDED_WORDS, FlightDescent.CRASH_WORDS]:
		for bad in ["fail", "loser", "stupid", "hurry"]:
			assert_false(w.to_lower().contains(bad), w)


func test_the_beep_quickens_near_the_ground() -> void:
	var d := FlightDescent.new(SpaceRules.MOON)
	var high := d.beep_every()
	d.height = 10.0
	var low := d.beep_every()
	assert_lt(low, high * 0.5, "faster beeps (%.2f s against %.2f s)" % [low, high])
	assert_gt(low, 0.1, "never a buzz")


func test_more_tanks_in_the_lander_more_fuel() -> void:
	assert_eq(FlightDescent.fuel_for(0), FlightDescent.FUEL_SECONDS)
	assert_gt(FlightDescent.fuel_for(3), FlightDescent.fuel_for(1))
	assert_eq(FlightDescent.fuel_for(100), FlightDescent.FUEL_MOST, "a lander's tanks go so far")
	assert_gt(FlightDescent.fuel_for(0, true), FlightDescent.fuel_for(0), "the easy first try")
	var lander := {Vector3i(0, 0, 0): BlockIds.ROCKET_ENGINE, Vector3i(0, 1, 0): BlockIds.FUEL_TANK,
		Vector3i(0, 2, 0): BlockIds.FUEL_TANK, Vector3i(0, 3, 0): BlockIds.CREW_CAPSULE}
	assert_eq(FlightDescent.tanks_of(lander), 2)
	assert_eq(FlightDescent.new(SpaceRules.MOON, false, 2).fuel_max, FlightDescent.fuel_for(2))


func test_the_first_try_is_easier_and_waits_for_its_card() -> void:
	var d := FlightDescent.new(SpaceRules.MOON, true)
	assert_eq(d.height, FlightDescent.EASY_HEIGHT)
	assert_eq(d.speed, FlightDescent.EASY_SPEED)
	assert_true(d.held(), "the hint card first")
	d.tick(1.0, 0.0)
	assert_eq(d.height, FlightDescent.EASY_HEIGHT, "nothing moves while the card shows")
	d.release()
	assert_false(d.held())
	d.tick(0.5, 0.0)
	assert_lt(d.height, FlightDescent.EASY_HEIGHT, "GO: it falls")
	var waits := FlightDescent.new(SpaceRules.MOON, true)
	waits.tick(FlightDescent.HINT_HOLD + 0.5, 0.0)
	assert_false(waits.held(), "the card never holds it for ever")
	assert_false(FlightDescent.new(SpaceRules.MOON).held(), "no card on later tries")


func test_the_pull_is_real_but_kept_playable() -> void:
	assert_almost_eq(FlightDescent.gravity_of(SpaceRules.MARS), 3.71, 0.001)
	assert_eq(FlightDescent.gravity_of(SpaceRules.PLUTO), FlightDescent.G_LEAST, "Pluto's 0.62 would take a minute")
	assert_eq(FlightDescent.gravity_of(SpaceRules.VENUS), FlightDescent.G_MOST, "Venus's thick air brakes its 8.87")
	assert_almost_eq(FlightDescent.real_gravity(SpaceRules.VENUS), 8.87, 0.001)


func test_a_crew_members_descent_shows_the_pilots() -> void:
	var pilot := FlightDescent.new(SpaceRules.MOON)
	for i in 30:
		pilot.tick(0.1, 0.5)
	var crew := FlightDescent.new(SpaceRules.MOON, true)
	crew.follow(pilot.snapshot())
	assert_almost_eq(crew.height, pilot.height, 0.001)
	assert_almost_eq(crew.speed, pilot.speed, 0.001)
	assert_almost_eq(crew.fuel_fraction(), pilot.fuel_fraction(), 0.001)
	assert_false(crew.held(), "the pilot's card is the pilot's")
	while not pilot.done():
		pilot.tick(0.1, 0.0)
	crew.follow(pilot.snapshot())
	assert_eq(crew.state, FlightDescent.CRASHED, "the crew crashes with the pilot")


func test_a_practice_try_starts_again_from_the_top() -> void:
	var d := FlightDescent.new(SpaceRules.MOON)
	_fly(d, func(_d: FlightDescent) -> float: return 0.0)
	assert_true(d.done())
	d.reset()
	assert_false(d.done())
	assert_eq(d.height, FlightDescent.START_HEIGHT)
	assert_eq(d.fuel_fraction(), 1.0)
