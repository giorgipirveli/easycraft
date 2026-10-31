extends GutTest
## Owner #79 (spec §25.3): the flight is played, not watched. FlightRun plays FlightPlan's steps: at an action the
## rocket waits for the child (the throttle up at lift-off, STAGE, a burn held on the throttle, LEGS, CHUTE); the
## autopilot does it kindly after FlightPlan.ACTION_WAIT (never stuck, never a crash); stages fall away as they are let go.


var run: FlightRun
var started: Array[StringName] = []
var done: Array = []
var ended := 0


func _make(dest: int = SpaceRules.MOON, stages: int = 2) -> FlightRun:
	started.clear()
	done.clear()
	ended = 0
	run = FlightRun.new(FlightPlan.steps(dest, stages), stages)
	run.step_started.connect(func(_i: int) -> void: started.append(run.phase()))
	run.action_done.connect(func(a: StringName, auto: bool) -> void: done.append([a, auto]))
	run.finished.connect(func() -> void: ended += 1)
	run.start()
	return run


func _until(phase: StringName, max_seconds: float = 400.0) -> void:
	var t := 0.0
	while run.phase() != phase and t < max_seconds and not run.is_finished():
		run.tick(0.1)
		t += 0.1


func test_it_starts_at_the_boarding_and_steps_on_by_itself() -> void:
	_make()
	assert_eq(run.phase(), FlightPlan.BOARD)
	assert_eq(started, [FlightPlan.BOARD])
	for i in 31:
		run.tick(0.1)
	assert_eq(run.phase(), FlightPlan.COUNTDOWN, "3 s of boarding")
	assert_almost_eq(run.progress(), 0.01, 0.02)


func test_the_rocket_waits_on_the_pad_for_the_throttle() -> void:
	_make()
	_until(FlightPlan.LIFTOFF)
	assert_eq(run.waiting_for(), FlightPlan.THROTTLE)
	for i in 20:
		run.tick(0.1)
	assert_eq(run.phase(), FlightPlan.LIFTOFF)
	assert_eq(run.progress(), 0.0, "still on the pad")
	run.throttle = 0.5
	run.tick(0.1)
	assert_eq(run.progress(), 0.0, "half a throttle is not enough to lift off")
	run.throttle = 1.0
	run.tick(0.1)
	assert_eq(done, [[FlightPlan.THROTTLE, false]], "the child did it")
	run.tick(0.5)
	assert_gt(run.progress(), 0.0, "rising")


func test_the_autopilot_pushes_the_throttle_if_the_child_does_not() -> void:
	_make()
	_until(FlightPlan.LIFTOFF)
	for i in int(FlightPlan.ACTION_WAIT * 10) + 2:
		run.tick(0.1)
	assert_eq(done, [[FlightPlan.THROTTLE, true]])
	assert_eq(run.throttle, 1.0, "full power")


func test_the_big_button_is_the_throttle_too() -> void:
	_make()
	_until(FlightPlan.LIFTOFF)
	assert_true(run.act(FlightPlan.THROTTLE))
	assert_eq(run.throttle, 1.0)
	run.tick(0.1)
	assert_eq(done, [[FlightPlan.THROTTLE, false]])


func test_stage_is_pressed_only_when_asked_and_the_stage_falls_away() -> void:
	_make()
	_until(FlightPlan.STAGING)
	assert_false(run.act(FlightPlan.STAGE), "not yet: the stage is still burning")
	assert_eq(run.dropped(), 0)
	_until_waiting()
	assert_eq(run.waiting_for(), FlightPlan.STAGE)
	assert_false(run.act(FlightPlan.LEGS), "not the thing asked for")
	assert_true(run.act(FlightPlan.STAGE))
	assert_eq(run.dropped(), 1)
	assert_has(done, [FlightPlan.STAGE, false])


func test_a_burn_is_held_on_the_throttle() -> void:
	_make()
	_until(FlightPlan.ORBIT)
	_until_waiting()
	assert_eq(run.waiting_for(), FlightPlan.BURN)
	run.throttle = 1.0
	for i in int(FlightPlan.BURN_SECONDS * 10) - 3:
		run.tick(0.1)
	assert_eq(run.waiting_for(), FlightPlan.BURN, "not long enough yet")
	assert_between(run.burn_progress(), 0.7, 1.0)
	for i in 5:
		run.tick(0.1)
	assert_has(done, [FlightPlan.BURN, false])


func test_the_autopilot_burns_for_a_child_who_waits() -> void:
	_make()
	_until(FlightPlan.ORBIT)
	run.throttle = 0.0   # the lever springs back when let go (the cockpit sets it every frame)
	_until_waiting()
	for i in int((FlightPlan.ACTION_WAIT + FlightPlan.BURN_SECONDS) * 10) + 3:
		run.tick(0.1)
	assert_has(done, [FlightPlan.BURN, true])
	assert_true(run.autopilot_burning() or run.waiting_for() == &"", "the autopilot held the throttle")


## Owner #106: the autopilot still takes every step before the landing (a trip never sticks), but the descent is the
## child's: nobody touching anything crashes there and the trip comes home (test_landing_run.gd has the rest).
func test_nobody_touching_anything_gets_to_the_landing_then_crashes_and_comes_home() -> void:
	for dest in [SpaceRules.MOON, SpaceRules.MARS, SpaceRules.BOING]:
		_make(dest, 3)
		run.destination = dest
		var t := 0.0
		while not run.is_finished() and t < 600.0:
			run.tick(0.1)
			t += 0.1
		assert_true(run.is_finished(), "world %d" % dest)
		assert_eq(ended, 1, "finished once")
		assert_eq(run.dropped(), 2, "both lower stages let go")
		assert_has(started, FlightPlan.DESCENT, "the autopilot brought it to the landing")
		assert_true(run.crashed(), "nobody flew the descent")
		var steps := FlightPlan.steps(dest, 3)
		var actions := steps.filter(func(s: Dictionary) -> bool: return s.action != &"").size()
		assert_lt(t, FlightPlan.total_seconds(steps) + FlightPlan.total_seconds(FlightPlan.crash_steps(dest))
			+ actions * (FlightPlan.ACTION_WAIT + FlightPlan.BURN_SECONDS) + 15.0)
		assert_eq(started.back(), FlightPlan.HOME)


func test_a_child_who_does_what_is_asked_lands() -> void:
	_make(SpaceRules.MOON, 2)
	while not run.is_finished():
		var w := run.waiting_for()
		run.throttle = run.test_throttle()
		if w in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			run.act(w)
		run.tick(0.1)
	assert_false(run.crashed())
	assert_eq(started.back(), FlightPlan.LANDED)


func test_a_five_stage_rocket_lets_the_rest_go_at_the_second_staging() -> void:
	_make(SpaceRules.MOON, 5)
	var t := 0.0
	while not run.is_finished() and t < 600.0:
		run.tick(0.1)
		t += 0.1
	assert_eq(run.dropped(), 4, "only the lander lands")


func _until_waiting(max_seconds: float = 30.0) -> void:
	var t := 0.0
	while run.waiting_for() == &"" and t < max_seconds:
		run.tick(0.1)
		t += 0.1
