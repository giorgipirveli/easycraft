extends GutTest
## Owner #118 (docs/design/life-skills.md §14, "Dangerous things, learned safely"; Life L3a): the safe mistake. On the
## Middle and Big tracks a step may let the child try the wrong way (a target, a picture or a body action marked as the
## mistake): the rules say so (`mistake`), the run counts it (never a miss on a normal try, so the By myself stamp stays:
## trying the wrong way and seeing why is learning, not help; on the Expert try it counts as a hint), the step goes on
## and the child does it right. A step may also name its wrong-but-harmless taps (`not`: kind words, a miss), and a
## danger moment may want the action within its seconds of the room's time (`within`: the time scale slows the room on
## the first tries; real time on the Expert try).


func _step(extra: Dictionary) -> Dictionary:
	var s := {"id": "s", "kind": "touch", "target": "ring", "say": "Throw the float.", "done": "Good."}
	s.merge(extra, true)
	return s


func _mistake(try: String = "jump_in") -> Dictionary:
	return {"wrong": "jumping in after someone", "try": try, "event": "two_in_water", "icon": "two_in_water",
		"why": "Someone in trouble grabs anything, even a helper: then two people need help.",
		"right": "Reach or throw from the side."}


func test_pressing_the_wrong_thing_is_a_safe_mistake_not_a_miss() -> void:
	var step := _step({"safe_mistake": _mistake()})
	var state := LifeCheck.begin(step)
	var r := LifeCheck.feed(step, state, {"dt": 0.1, "pressed": ["jump_in"]})
	assert_true(r.mistake, "the wrong way was tried")
	assert_false(r.miss, "never a miss")
	assert_false(r.done)
	assert_eq(int(state.mistakes), 1)
	r = LifeCheck.feed(step, state, {"dt": 0.1, "pressed": ["ring"]})
	assert_true(r.done, "then the child does it right")
	assert_false(r.mistake)


func test_a_step_without_a_safe_mistake_ignores_other_things() -> void:
	var step := _step({})
	var r := LifeCheck.feed(step, LifeCheck.begin(step), {"dt": 0.1, "pressed": ["jump_in"]})
	assert_false(r.mistake)
	assert_false(r.miss)


func test_a_picture_marked_as_the_mistake_is_a_safe_mistake() -> void:
	var step := {"id": "c", "kind": "choose", "say": "Your friend is in the water. What do you do?", "answer": 0,
		"choices": [{"text": "Throw a float", "icon": "ring_buoy"}, {"text": "Jump in", "icon": "jump_in", "mistake": true},
			{"text": "Walk away", "icon": "cross", "why": "Stay and get help."}],
		"safe_mistake": {"wrong": "jumping in", "event": "two_in_water", "why": "Two people would need help.",
			"right": "Throw something that floats."}}
	var state := LifeCheck.begin(step)
	var r := LifeCheck.feed(step, state, {"dt": 0.1, "answer": 1})
	assert_true(r.mistake)
	assert_false(r.miss)
	r = LifeCheck.feed(step, state, {"dt": 0.1, "answer": 2})
	assert_true(r.miss, "another wrong picture is still a kind miss")
	assert_false(r.mistake)
	assert_eq(r.said, "Stay and get help.")
	assert_true(LifeCheck.feed(step, state, {"dt": 0.1, "answer": 0}).done)


## Thin ice: standing up on the ice is the mistake. In VR the head rises (no longer low) after being low; flat, the
## STAND UP picture button (the action "stand").
func test_standing_up_on_the_ice_is_a_safe_mistake() -> void:
	var step := {"id": "roll", "kind": "action", "action": "roll", "low": true, "say": "Roll away from the hole.",
		"safe_mistake": _mistake("action:stand")}
	var state := LifeCheck.begin(step)
	var r := LifeCheck.feed(step, state, {"dt": 0.1, "low": false})
	assert_false(r.mistake, "not low yet at the start: it waits (kindly), never a mistake")
	assert_false(r.done)
	r = LifeCheck.feed(step, state, {"dt": 0.1, "low": true})
	assert_false(r.mistake)
	r = LifeCheck.feed(step, state, {"dt": 0.1, "low": false})
	assert_true(r.mistake, "low, then the head came up: standing on the ice")
	r = LifeCheck.feed(step, state, {"dt": 0.1, "low": false})
	assert_false(r.mistake, "once: it waits for the child to be low again")
	r = LifeCheck.feed(step, state, {"dt": 0.1, "low": true, "action": "stand", "action_tap": true})
	assert_true(r.mistake, "flat: the STAND UP button")
	r = LifeCheck.feed(step, state, {"dt": 0.1, "low": true, "action": "roll", "action_tap": true})
	assert_true(r.done, "then rolling away")


func test_a_harmless_wrong_tap_says_why_kindly() -> void:
	var step := _step({"target": "mo", "not": {"pip": "Pip-pop is waving and laughing: she is playing."}})
	var state := LifeCheck.begin(step)
	var r := LifeCheck.feed(step, state, {"dt": 0.1, "pressed": ["pip"]})
	assert_true(r.miss)
	assert_eq(r.said, "Pip-pop is waving and laughing: she is playing.")
	assert_true(LifeCheck.feed(step, state, {"dt": 0.1, "pressed": ["mo"]}).done)
	assert_has(LifeCheck.targets_of(step), "pip", "the room must have it")


func test_the_targets_of_a_step_include_its_mistake() -> void:
	assert_has(LifeCheck.targets_of(_step({"safe_mistake": _mistake()})), "jump_in")
	assert_does_not_have(LifeCheck.targets_of(_step({"safe_mistake": _mistake("action:stand")})), "action:stand")


## A danger moment wants the action in time (in the room's time): too late is a kind miss and the clock starts again.
func test_within_counts_the_rooms_time() -> void:
	var step := {"id": "drop", "kind": "action", "action": "low", "within": 4.0, "late": "Quickly: drop down now.",
		"say": "Drop!"}
	var state := LifeCheck.begin(step)
	var said := []
	for i in 7:   # 7 frames of a second at half speed: 3.5 s of the room's time
		var r := LifeCheck.feed(step, state, {"dt": 1.0, "room_dt": 0.5})
		assert_false(r.miss, "%d s: still in time at half speed" % i)
	var r := LifeCheck.feed(step, state, {"dt": 1.0, "room_dt": 0.5})
	assert_true(r.miss, "4 s of the room's time")
	assert_eq(r.said, "Quickly: drop down now.")
	assert_false(LifeCheck.feed(step, state, {"dt": 1.0, "room_dt": 0.5}).miss, "its clock started again")
	said.append(r.said)


func test_problems_of_a_safe_mistake() -> void:
	assert_eq(LifeCheck.problem(_step({"safe_mistake": _mistake()})), "")
	var no_why := _mistake()
	no_why.erase("why")
	assert_string_contains(LifeCheck.problem(_step({"safe_mistake": no_why})), "why")
	var no_try := _mistake()
	no_try.erase("try")
	assert_eq(LifeCheck.problem(_step({"safe_mistake": no_try})), "", "only shaped (round 4b's Real Builder): valid...")
	assert_false(LifeCheck.tries_mistake(_step({"safe_mistake": no_try})), "...but there is no wrong way to try")
	assert_true(LifeCheck.tries_mistake(_step({"safe_mistake": _mistake()})))
	assert_string_contains(LifeCheck.problem(_step({"safe_mistake": _mistake("action:fly")})), "fly")
	assert_string_contains(LifeCheck.problem(_step({"safe_mistake": _mistake("ring")})), "the right one",
		"the wrong way is never the step's own target")
	var choose := {"id": "c", "kind": "choose", "say": "?", "answer": 0, "safe_mistake": {"wrong": "w", "event": "e",
		"why": "y", "right": "r"}, "choices": [{"text": "a", "icon": "tick"}, {"text": "b", "icon": "cross"}]}
	assert_false(LifeCheck.tries_mistake(choose), "a choice step marks its mistake picture")
	choose.choices[1]["mistake"] = true
	assert_eq(LifeCheck.problem(choose), "")
	assert_true(LifeCheck.tries_mistake(choose))
	choose.choices[0]["mistake"] = true
	assert_string_contains(LifeCheck.problem(choose), "never the right one")
	assert_string_contains(LifeCheck.problem(_step({"not": {"ring": "no"}})), "not",
		"the right target is never one of the wrong taps")


# --- The run ---------------------------------------------------------------------------------------------------------

func _run(expert: bool) -> LifeRun:
	var steps: Array[Dictionary] = [_step({"safe_mistake": _mistake()}),
		{"id": "end", "kind": "info", "say": "Well done."}]
	return LifeRun.new(steps, expert)


func test_a_safe_mistake_keeps_the_by_myself_stamp_on_a_normal_try() -> void:
	var run := _run(false)
	var e := run.feed({"dt": 0.1, "pressed": ["jump_in"]})
	assert_true(e.mistake)
	assert_false(e.coach, "the freeze explains: the coach doesn't show it as a hint")
	assert_eq(run.total_hints(), 0)
	assert_eq(run.total_mistakes(), 1)
	run.feed({"dt": 0.1, "pressed": ["ring"]})
	run.feed({"dt": 0.1, "ok": true})
	assert_true(run.finished)
	assert_eq(int(run.outcome().stamps) & LifeData.SELF, LifeData.SELF, "trying the wrong way is learning, not help")
	assert_eq(int(run.outcome().mistakes), 1)
	assert_eq(int(run.steps_log[0].mistakes), 1, "the device's measurement: how often the wrong way is tried")
	assert_false(bool(run.steps_log[0].hinted))


func test_on_the_expert_try_a_safe_mistake_counts_as_a_hint() -> void:
	var run := _run(true)
	run.feed({"dt": 0.1, "pressed": ["jump_in"]})
	assert_eq(run.total_hints(), 1, "the Expert stamp waits for a try without one")
	run.feed({"dt": 0.1, "pressed": ["ring"]})
	run.feed({"dt": 0.1, "ok": true})
	assert_eq(int(run.outcome().stamps) & LifeData.EXPERT, 0)


func test_the_time_scale_is_slow_on_the_first_tries_and_real_on_the_expert_try() -> void:
	assert_eq(LifeRun.time_scale(0, false), LifeRun.SLOW_FIRST, "the first try")
	assert_eq(LifeRun.time_scale(1, false), LifeRun.SLOW_FIRST, "the second try")
	assert_eq(LifeRun.time_scale(2, false), LifeRun.SLOW_LATER, "later tries: a little slow")
	assert_eq(LifeRun.time_scale(0, true), 1.0, "the Expert try: real time")
	assert_eq(LifeRun.time_scale(0, false, true), 1.0, "a grown-up's 'more real' (Big): real time")
	assert_lt(LifeRun.SLOW_FIRST, LifeRun.SLOW_LATER)
	assert_lt(LifeRun.SLOW_LATER, 1.0)
