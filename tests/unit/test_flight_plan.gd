extends GutTest
## Owner #79, #86 (spec §25.3, §21d.4): the flight's steps as pure rules (FlightPlan): sit at the controls, the
## countdown, lift-off, the climb, the stages falling away, orbit, the trip (the Moon's 3 days in seconds; the movie-style
## shortcuts to far worlds, with words that keep the science true), the slow-down, a fiery entry and a parachute where
## there is air, the landing. Each step: its seconds, the child's action and when the rocket waits for it, whether the
## child steers, the camera, its words. About 2-3 minutes of play.

const FILMS: Array[String] = ["star wars", "star trek", "enterprise", "millennium", "falcon", "jedi", "sith",
	"death star", "tardis", "interstellar", "hyperdrive", "hyperspace", "warp drive", "stargate", "apollo", "artemis",
	"saturn v", "spacex", "nasa", "starship", "gemini", "soyuz", "voyager", "new horizons", "juno", "cassini"]


func _phases(steps: Array[Dictionary]) -> Array[StringName]:
	var out: Array[StringName] = []
	for s in steps:
		out.append(s.phase)
	return out


func test_the_moon_trip_goes_in_the_real_order() -> void:
	var steps := FlightPlan.steps(SpaceRules.MOON, 2)
	assert_eq(_phases(steps), [FlightPlan.BOARD, FlightPlan.COUNTDOWN, FlightPlan.LIFTOFF, FlightPlan.ASCENT,
		FlightPlan.STAGING, FlightPlan.ORBIT, FlightPlan.CRUISE, FlightPlan.ARRIVE, FlightPlan.DEORBIT, FlightPlan.LANDING,
		FlightPlan.DESCENT, FlightPlan.LANDED])


func test_the_moon_trip_is_two_to_three_minutes() -> void:
	var steps := FlightPlan.steps(SpaceRules.MOON, 2)
	var play := FlightPlan.total_seconds(steps)
	assert_between(play, 100.0, 150.0, "the steps themselves")
	var actions := steps.filter(func(s: Dictionary) -> bool: return s.action != &"").size()
	assert_between(play + actions * FlightPlan.ACTION_WAIT, 110.0, 180.0, "with the child waiting at every action")


func test_one_stage_drops_nothing_and_three_stages_drop_two() -> void:
	assert_false(_phases(FlightPlan.steps(SpaceRules.MOON, 1)).has(FlightPlan.STAGING))
	assert_eq(_phases(FlightPlan.steps(SpaceRules.MOON, 3)).count(FlightPlan.STAGING), 2)
	assert_eq(_phases(FlightPlan.steps(SpaceRules.MOON, 5)).count(FlightPlan.STAGING), 2, "the rest fall with the second")


func test_mars_has_air_a_fiery_entry_and_a_parachute_and_a_shortcut() -> void:
	var p := _phases(FlightPlan.steps(SpaceRules.MARS, 2))
	for phase in [FlightPlan.JUMP, FlightPlan.WARP, FlightPlan.ENTRY, FlightPlan.CHUTE, FlightPlan.LANDING]:
		assert_has(p, phase)
	assert_false(p.has(FlightPlan.ARRIVE), "Mars's air slows the lander: no engine burn into orbit")
	assert_lt(p.find(FlightPlan.ENTRY), p.find(FlightPlan.CHUTE))
	assert_lt(p.find(FlightPlan.CHUTE), p.find(FlightPlan.LANDING))
	assert_true(FlightPlan.has_air(SpaceRules.MARS))
	assert_true(FlightPlan.has_air(SpaceRules.TITAN))
	assert_false(FlightPlan.has_air(SpaceRules.MOON))
	assert_false(FlightPlan.has_air(SpaceRules.EUROPA))


func test_each_kind_of_trip_has_its_movie_moments() -> void:
	assert_eq(FlightPlan.moments(SpaceRules.MOON), [] as Array[StringName], "the Moon: the real trip, no shortcut")
	assert_eq(FlightPlan.moments(SpaceRules.MARS), [FlightPlan.JUMP, FlightPlan.WARP])
	assert_eq(FlightPlan.moments(SpaceRules.EUROPA), [FlightPlan.JUMP, FlightPlan.ASTEROIDS, FlightPlan.WARP],
		"past the asteroid belt to Jupiter")
	assert_eq(FlightPlan.moments(SpaceRules.TITAN), [FlightPlan.JUMP, FlightPlan.ASTEROIDS, FlightPlan.WORMHOLE])
	assert_eq(FlightPlan.moments(SpaceRules.BOING), [FlightPlan.WORMHOLE, FlightPlan.NEBULA], "our own far planets")
	assert_eq(FlightPlan.moments(99), [FlightPlan.WORMHOLE, FlightPlan.NEBULA], "any other world")
	for u in [SpaceRules.MARS, SpaceRules.EUROPA, SpaceRules.TITAN, SpaceRules.BOING, SpaceRules.MERCURY]:
		var steps := FlightPlan.steps(u, 2)
		assert_between(FlightPlan.total_seconds(steps), 100.0, 160.0, "world %d" % u)


func test_every_step_says_something_and_waits_inside_itself() -> void:
	for u in [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.EUROPA, SpaceRules.TITAN, SpaceRules.BOING, 3]:
		for s in FlightPlan.steps(u, 3):
			assert_ne(str(s.words), "", "%s says something" % s.phase)
			assert_gt(float(s.seconds), 0.0)
			assert_has([FlightPlan.INSIDE, FlightPlan.CHASE, FlightPlan.LAUNCH], s.view)
			if s.action != &"":
				assert_between(float(s.at), 0.0, float(s.seconds) - 0.5, "%s waits inside its step" % s.phase)
				assert_ne(str(s.after), "", "%s says what happened" % s.phase)


func test_the_child_acts_at_the_big_moments() -> void:
	var steps := FlightPlan.steps(SpaceRules.MOON, 2)
	var actions := {}
	for s in steps:
		if s.action != &"":
			actions[s.phase] = s.action
	assert_eq(actions, {FlightPlan.LIFTOFF: FlightPlan.THROTTLE, FlightPlan.STAGING: FlightPlan.STAGE,
		FlightPlan.ORBIT: FlightPlan.BURN, FlightPlan.ARRIVE: FlightPlan.BURN, FlightPlan.LANDING: FlightPlan.LEGS,
		FlightPlan.DESCENT: FlightPlan.DESCEND})   # owner #106: the descent is the child's
	var mars := {}
	for s in FlightPlan.steps(SpaceRules.MARS, 2):
		if s.action != &"":
			mars[s.phase] = s.action
	assert_eq(mars.get(FlightPlan.CHUTE), FlightPlan.PARACHUTE)
	var steered := steps.filter(func(s: Dictionary) -> bool: return s.steer).map(func(s: Dictionary) -> StringName: return s.phase)
	for phase in [FlightPlan.ASCENT, FlightPlan.ORBIT, FlightPlan.CRUISE, FlightPlan.LANDING]:
		assert_has(steered, phase, "the child steers in %s" % phase)


func test_the_words_keep_the_science_true() -> void:
	assert_string_contains(FlightPlan.trip_words(SpaceRules.MOON), "3 days")
	assert_string_contains(FlightPlan.trip_words(SpaceRules.MARS), "7 months")
	assert_string_contains(FlightPlan.trip_words(SpaceRules.MARS).to_lower(), "faster than light")
	var jump := FlightPlan.steps(SpaceRules.MARS, 2).filter(func(s: Dictionary) -> bool: return s.phase == FlightPlan.JUMP)
	assert_string_contains(str(jump[0].words).to_lower(), "shortcut")
	var hole := FlightPlan.steps(SpaceRules.BOING, 2).filter(func(s: Dictionary) -> bool: return s.phase == FlightPlan.WORMHOLE)
	assert_string_contains(str(hole[0].words).to_lower(), "nobody has found one")
	assert_eq(FlightPlan.body_name(SpaceRules.MOON), "the Moon")
	assert_eq(FlightPlan.body_name(SpaceRules.MARS), "Mars")


func test_no_film_s_or_mission_s_name_anywhere() -> void:
	var texts: Array[String] = []
	for u in [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.EUROPA, SpaceRules.IO, SpaceRules.TITAN, SpaceRules.MERCURY,
			SpaceRules.BOING, SpaceRules.RAINBOW, 2]:
		texts.append(FlightPlan.trip_words(u))
		for s in FlightPlan.steps(u, 3) + FlightPlan.crash_steps(u):
			texts.append(str(s.words))
			texts.append(str(s.after))
	for t in texts:
		for film in FILMS:
			assert_false(t.to_lower().contains(film), "\"%s\" names %s" % [t, film])


## Owner #87 ("landing on mercury should be done like real landing"): the landing on its own, for the Star Map's LAND.
## Owner #106: its last 120 m are a practice descent the child flies (FlightRun.practice); the rest waits for nobody.
func test_a_landing_on_its_own_is_short_and_ends_with_a_practice_descent() -> void:
	for u in [SpaceRules.MERCURY, SpaceRules.MOON, SpaceRules.EUROPA]:
		var steps := FlightPlan.landing_steps(u)
		assert_eq(_phases(steps), [FlightPlan.DEORBIT, FlightPlan.LANDING, FlightPlan.DESCENT, FlightPlan.LANDED],
			"world %d" % u)
		assert_between(FlightPlan.total_seconds(steps), 8.0, 15.0, "the steps besides the descent itself")
		for s in steps:
			assert_eq(s.action, FlightPlan.DESCEND if s.phase == FlightPlan.DESCENT else &"",
				"the autopilot does the rest: %s" % s.phase)
		assert_string_contains(str(steps[2].words), "Practice")
	var mars := FlightPlan.landing_steps(SpaceRules.MARS)
	assert_eq(_phases(mars), [FlightPlan.ENTRY, FlightPlan.CHUTE, FlightPlan.LANDING, FlightPlan.DESCENT,
		FlightPlan.LANDED], "air: the fiery entry and the parachute")
	assert_between(FlightPlan.total_seconds(mars), 8.0, 15.0)
	assert_string_contains(str(FlightPlan.landing_steps(SpaceRules.MERCURY)[0].words), "Mercury")


func test_a_whole_flight_ends_with_the_same_landing() -> void:
	var steps := FlightPlan.steps(SpaceRules.MARS, 2)
	var tail := _phases(steps).slice(_phases(steps).find(FlightPlan.ENTRY))
	assert_eq(tail, _phases(FlightPlan.landing_steps(SpaceRules.MARS, true)))
