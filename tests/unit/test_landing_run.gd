extends GutTest
## Owner #106: the landing is the child's (every mission, the Moon first). A flight's last steps are the legs (LEGS, the
## autopilot still helps there: a trip never sticks before the landing), then the DESCENT the child flies (DESCEND:
## no autopilot; FlightDescent's rules), then the touchdown. Too fast is a crash: the rest of the trip becomes the way
## home (FlightPlan.crash_steps: the crash, the capsule's trip home, a fiery re-entry, the parachute by the Launch
## Site, the rocket falling there too), nothing waits on the way, and the run says it crashed. The crew's run follows
## the pilot's descent and crashes with it. The Star Map's LAND is a practice landing: a crash tries again, and after
## PRACTICE_TRIES Mission Control lands it (never stuck).

var run: FlightRun
var phases: Array[StringName] = []
var over: Array[bool] = []


func _make(dest: int = SpaceRules.MOON, stages: int = 2, steps: Array[Dictionary] = []) -> FlightRun:
	phases.clear()
	over.clear()
	var list := steps if not steps.is_empty() else FlightPlan.steps(dest, stages)
	run = FlightRun.new(list, stages)
	run.destination = dest
	run.step_started.connect(func(_i: int) -> void: phases.append(run.phase()))
	run.descent_over.connect(func(ok: bool) -> void: over.append(ok))
	run.start()
	return run


## Plays the trip: the actions done at once, the burns held; in the descent `pilot` (the throttle) flies.
func _play(pilot: Callable, most: float = 600.0) -> float:
	var t := 0.0
	while not run.is_finished() and t < most:
		var w := run.waiting_for()
		run.throttle = float(pilot.call(run)) if w == FlightPlan.DESCEND else run.test_throttle()
		if w in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			run.act(w)
		run.tick(0.1)
		t += 0.1
	return t


func _phases_of(list: Array[Dictionary]) -> Array[StringName]:
	var out: Array[StringName] = []
	for s in list:
		out.append(s.phase)
	return out


func test_every_flight_ends_with_a_descent_the_child_flies() -> void:
	for u in [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.EUROPA, SpaceRules.TITAN, SpaceRules.BOING]:
		var p := _phases_of(FlightPlan.steps(u, 2))
		assert_eq(p.slice(p.size() - 3), [FlightPlan.LANDING, FlightPlan.DESCENT, FlightPlan.LANDED] as Array[StringName],
			"world %d" % u)
		var descent: Dictionary = FlightPlan.steps(u, 2)[p.size() - 2]
		assert_eq(descent.action, FlightPlan.DESCEND)
		assert_eq(float(descent.at), 0.0)
		assert_string_contains(str(descent.words), "throttle")


func test_a_good_pilot_lands_and_the_trip_ends_landed() -> void:
	_make()
	_play(func(r: FlightRun) -> float: return FlightDescent.test_pilot(r.descent))
	assert_true(run.is_finished())
	assert_false(run.crashed())
	assert_eq(phases.back(), FlightPlan.LANDED)
	assert_eq(over, [true])
	assert_eq(run.descent.state, FlightDescent.LANDED)


func test_no_autopilot_on_the_final_descent() -> void:
	_make()
	var t := 0.0
	while run.phase() != FlightPlan.DESCENT and t < 400.0:   # a child who never presses anything
		run.throttle = 0.0
		run.tick(0.1)
		t += 0.1
	assert_eq(run.phase(), FlightPlan.DESCENT, "the earlier steps' autopilot brought it here")
	assert_eq(run.waiting_for(), FlightPlan.DESCEND)
	assert_eq(run.descent.height, FlightDescent.START_HEIGHT)
	while not run.descent.done():
		run.tick(0.1)
	assert_eq(run.descent.state, FlightDescent.CRASHED, "nobody flew it: it crashed")
	assert_true(run.crashed())


func test_a_crash_makes_the_rest_of_the_trip_the_way_home() -> void:
	_make()
	var t := _play(func(_r: FlightRun) -> float: return 0.0)
	assert_true(run.is_finished(), "nothing waits on the way home")
	assert_true(run.crashed())
	assert_eq(over, [false])
	var home := phases.slice(phases.find(FlightPlan.DESCENT) + 1)
	assert_eq(home, [FlightPlan.CRASH, FlightPlan.ESCAPE, FlightPlan.HOME_ENTRY, FlightPlan.HOME_CHUTE, FlightPlan.WRECK,
		FlightPlan.HOME] as Array[StringName])
	assert_false(phases.has(FlightPlan.LANDED), "it never landed")
	assert_lt(t, 220.0)


func test_the_way_home_waits_for_nobody_and_says_what_happens() -> void:
	for u in [SpaceRules.MOON, SpaceRules.MARS]:
		var home := FlightPlan.crash_steps(u)
		assert_between(FlightPlan.total_seconds(home), 18.0, 35.0, "a short way home")
		for s in home:
			assert_eq(s.action, &"", "%s waits for nobody" % s.phase)
			assert_ne(str(s.words), "", "%s says something" % s.phase)
			assert_has([FlightPlan.INSIDE, FlightPlan.CHASE, FlightPlan.LAUNCH], s.view)
		assert_string_contains(str(home[0].words), "safe", "first: everyone is safe")
		assert_string_contains(str(home[1].words), "Beresheet", "a real fact on the way")
	for s in FlightPlan.crash_steps(SpaceRules.MOON):
		for bad in ["fail", "loser", "your fault", "game over", "hurry"]:
			assert_false(str(s.words).to_lower().contains(bad), str(s.words))


func test_the_crew_crashes_with_the_pilot() -> void:
	_make(SpaceRules.MOON, 3)
	var crew := FlightRun.new(FlightPlan.steps(SpaceRules.MOON, 3), 3)
	crew.destination = SpaceRules.MOON
	var crew_over: Array[bool] = []
	crew.descent_over.connect(func(ok: bool) -> void: crew_over.append(ok))
	crew.start()
	var guard := 0
	while not run.is_finished() and guard < 8000:
		guard += 1
		var w := run.waiting_for()
		run.throttle = 0.0 if w == FlightPlan.DESCEND else run.test_throttle()
		if w in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			run.act(w)
		run.tick(0.1)
		if guard % 3 == 0:
			var s := run.snapshot()
			crew.follow(0.3, s, float(s.t) + 0.05)
		if crew.phase() == FlightPlan.DESCENT and crew.descent != null and run.descent != null and not run.descent.done():
			assert_almost_eq(crew.descent.height, run.descent.height, 10.0, "the crew sees the pilot's height")
	var last := run.snapshot()
	for i in 40:
		crew.follow(0.1, last, CrewFlightRules.upto(float(last.t), 0.1 * i))
	assert_true(run.crashed())
	assert_true(crew.crashed(), "everyone on board crashes together")
	assert_eq(crew_over, [false])
	assert_true(crew.is_finished(), "and comes home with the pilot")
	assert_eq(crew.steps.size(), run.steps.size(), "the same way home")


func test_a_practice_landing_tries_again_then_mission_control_lands_it() -> void:
	_make(SpaceRules.MOON, 1, FlightPlan.landing_steps(SpaceRules.MOON))
	run.practice = true
	assert_has(_phases_of(run.steps), FlightPlan.DESCENT, "the Star Map's LAND is a practice landing")
	var t := _play(func(_r: FlightRun) -> float: return 0.0)
	assert_true(run.is_finished(), "never stuck")
	assert_false(run.crashed(), "a practice never crashes the trip")
	assert_eq(over.size(), FlightRun.PRACTICE_TRIES)
	assert_eq(over.back(), true, "Mission Control landed the last one")
	assert_true(run.helped())
	assert_eq(phases.back(), FlightPlan.LANDED)
	assert_lt(t, 90.0)


func test_a_practice_flown_well_lands_on_the_first_try() -> void:
	_make(SpaceRules.MERCURY, 1, FlightPlan.landing_steps(SpaceRules.MERCURY))
	run.practice = true
	var t := _play(func(r: FlightRun) -> float: return FlightDescent.test_pilot(r.descent))
	assert_eq(over, [true])
	assert_false(run.helped())
	assert_between(t, 12.0, 40.0)


func test_the_first_try_is_the_easy_one() -> void:
	_make()
	run.descent_easy = true
	run.lander_tanks = 2
	while run.phase() != FlightPlan.DESCENT:
		run.throttle = run.test_throttle()
		run.tick(0.1)
	assert_true(run.descent.easy)
	assert_eq(run.descent.fuel_max, FlightDescent.fuel_for(2, true), "the lander's own tanks")
	assert_true(run.descent.held(), "its hint card first")
