extends GutTest
## Crew flights (spec §21d.6 phase 2): a crew member's FlightRun plays the pilot's, never its own (FlightRun.snapshot on
## the pilot's game, FlightRun.follow on each crew member's). A slow device catches up (straight to the pilot's step,
## the stages fallen), a fast one waits at the pilot's time, an action happens when the pilot's did (never by the crew
## member's own autopilot), and a crew member's run never holds the pilot's up.

var pilot: FlightRun
var crew: FlightRun
var started: Array[int] = []
var done: Array[StringName] = []


func before_each() -> void:
	var steps := FlightPlan.steps(SpaceRules.MOON, 3)
	pilot = FlightRun.new(steps, 3)
	crew = FlightRun.new(steps.duplicate(true), 3)
	started.clear()
	done.clear()
	crew.step_started.connect(func(i: int) -> void: started.append(i))
	crew.action_done.connect(func(a: StringName, _auto: bool) -> void: done.append(a))
	pilot.start()
	crew.start()


## Ticks the pilot until its phase is `phase` (acting at once like a child who presses what is asked).
func _pilot_to(phase: StringName, max_steps: int = 5000) -> void:
	for i in max_steps:
		if pilot.phase() == phase:
			return
		var w := pilot.waiting_for()
		pilot.throttle = 1.0 if w in [FlightPlan.THROTTLE, FlightPlan.BURN] else 0.0
		if w in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			pilot.act(w)
		pilot.tick(0.1)


func _index_of(phase: StringName, from: int = 0) -> int:
	for i in range(from, pilot.steps.size()):
		if pilot.steps[i].phase == phase:
			return i
	return -1


func test_the_snapshot_says_where_the_pilot_is() -> void:
	_pilot_to(FlightPlan.ASCENT)
	var s := pilot.snapshot()
	assert_eq(int(s.i), pilot.index)
	assert_almost_eq(float(s.t), pilot.t, 0.001)
	assert_eq(int(s.dropped), 0)
	assert_true(s.has("done") and s.has("burn") and s.has("auto") and s.has("thr"))


func test_a_crew_member_behind_goes_straight_to_the_pilots_step() -> void:
	_pilot_to(FlightPlan.ORBIT)
	var s := pilot.snapshot()
	crew.follow(0.1, s, float(s.t))
	assert_eq(crew.index, pilot.index, "caught up")
	assert_eq(crew.dropped(), pilot.dropped(), "the stage fell on the way")
	assert_eq(started.back(), pilot.index, "the step's words")
	assert_almost_eq(crew.t, float(s.t), 0.001)


func test_it_runs_on_but_never_past_the_pilots_time() -> void:
	_pilot_to(FlightPlan.ASCENT)
	var s := pilot.snapshot()
	crew.follow(0.0, s, float(s.t))
	var at := crew.t
	crew.follow(0.1, s, float(s.t) + 0.5)
	assert_almost_eq(crew.t, at + 0.1, 0.001, "time runs on")
	for i in 20:
		crew.follow(0.1, s, float(s.t) + 0.5)
	assert_almost_eq(crew.t, float(s.t) + 0.5, 0.001, "and holds at the pilot's time")
	assert_eq(crew.index, pilot.index)


func test_an_action_waits_for_the_pilot_never_for_its_own_autopilot() -> void:
	_pilot_to(FlightPlan.LIFTOFF)
	var s := pilot.snapshot()
	for i in 100:   # 10 s at the lift-off: the pilot has not pushed the throttle yet
		crew.follow(0.1, s, 99.0)
	assert_eq(crew.phase(), FlightPlan.LIFTOFF)
	assert_false(crew.action_done_here(), "never by the crew member's autopilot")
	assert_eq(done, [] as Array[StringName])
	pilot.throttle = 1.0
	pilot.tick(0.1)
	s = pilot.snapshot()
	assert_true(bool(s.done))
	crew.follow(0.1, s, float(s.t))
	assert_true(crew.action_done_here(), "the pilot pushed it: done here too")
	assert_eq(done, [FlightPlan.THROTTLE] as Array[StringName], "its sound and words")


func test_a_whole_trip_followed_lands_with_the_pilot() -> void:
	var finished := [false]
	crew.finished.connect(func() -> void: finished[0] = true)
	var guard := 0
	while not pilot.is_finished() and guard < 5000:
		guard += 1
		var w := pilot.waiting_for()
		pilot.throttle = pilot.test_throttle()   # owner #106: the descent flown well
		if w in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			pilot.act(w)
		pilot.tick(0.1)
		if guard % 3 == 0:   # the pilot's word comes 3 or 4 times a second
			var s := pilot.snapshot()
			crew.follow(0.3, s, float(s.t) + 0.05)
	var last := pilot.snapshot()
	for i in 20:
		crew.follow(0.1, last, CrewFlightRules.upto(float(last.t), 0.1 * i))
	assert_true(pilot.is_finished())
	assert_false(pilot.crashed(), "a soft landing")
	assert_false(crew.crashed())
	assert_true(finished[0], "the crew member's run lands too")
	assert_eq(crew.dropped(), pilot.dropped())


func test_a_skip_on_the_pilots_game_is_a_jump_on_the_crews() -> void:
	_pilot_to(FlightPlan.ASCENT)
	crew.follow(0.1, pilot.snapshot(), pilot.t)
	var land := _index_of(FlightPlan.DEORBIT)
	pilot.jump_to(land)
	var s := pilot.snapshot()
	crew.follow(0.1, s, float(s.t))
	assert_eq(crew.phase(), FlightPlan.DEORBIT)
	assert_eq(crew.dropped(), 2, "only the lander is left")


func test_the_pilot_is_never_held_up() -> void:
	_pilot_to(FlightPlan.ORBIT)
	assert_eq(pilot.phase(), FlightPlan.ORBIT, "the pilot flew on by itself; nobody waited for the crew")
	assert_eq(crew.index, 0, "the crew member was frozen all along")
