extends GutTest
## Owner #112, #113 (docs/design/life-skills.md §3, §10): a run of an Experience. One step at a time; the coach steps in
## by showing after about 10 s without progress (20 s on the Expert try), and when the child asks; a miss shows the step
## and goes again; the run always ends well. Stamps: Done it (finished), By myself (no hint at all), Expert (the Expert
## try with no hint). Each step's time and whether it needed a hint are logged for the device's measurements.

const STEPS: Array[Dictionary] = [
	{"id": "hello", "kind": "info", "say": "This is practice."},
	{"id": "phone", "kind": "touch", "target": "phone", "say": "Pick up the phone."},
	{"id": "safe", "kind": "choose", "say": "Is it safe?", "answer": 0, "choices": [{"text": "yes"}, {"text": "no"}]},
]


func _run(expert: bool = false) -> LifeRun:
	return LifeRun.new(STEPS.duplicate(true), expert)


func test_it_starts_on_the_first_step() -> void:
	var r := _run()
	assert_eq(r.index, 0)
	assert_eq(str(r.current().id), "hello")
	assert_false(r.finished)


func test_steps_go_one_after_another_to_the_end() -> void:
	var r := _run()
	var e := r.feed({"ok": true, "dt": 0.1})
	assert_true(e.next)
	assert_eq(str(r.current().id), "phone")
	r.feed({"pressed": ["phone"], "dt": 0.1})
	var last := r.feed({"answer": 0, "dt": 0.1})
	assert_true(last.finished)
	assert_true(r.finished)


func test_the_coach_shows_after_ten_seconds_without_progress() -> void:
	var r := _run()
	r.feed({"ok": true, "dt": 0.1})
	var coached := false
	for i in 99:
		coached = coached or bool(r.feed({"dt": 0.1}).coach)
	assert_false(coached, "9.9 s: not yet")
	assert_true(r.feed({"dt": 0.2}).coach, "about 10 s: the coach shows")
	assert_eq(r.hints_on(1), 1)
	for i in 99:
		r.feed({"dt": 0.1})
	assert_true(r.feed({"dt": 0.2}).coach, "and again 10 s later")


func test_progress_resets_the_coachs_clock() -> void:
	var r := LifeRun.new([{"id": "dial", "kind": "sequence", "targets": ["key_1", "key_1", "key_2"], "say": "Dial."}], false)
	for i in 80:
		r.feed({"dt": 0.1})
	r.feed({"pressed": ["key_1"], "dt": 0.1})
	var coached := false
	for i in 80:
		coached = coached or bool(r.feed({"dt": 0.1}).coach)
	assert_false(coached)


func test_an_info_step_never_counts_a_hint() -> void:
	var r := _run()
	for i in 300:
		r.feed({"dt": 0.1})
	assert_eq(r.hints_on(0), 0)


func test_show_me_is_a_hint() -> void:
	var r := _run()
	r.feed({"ok": true, "dt": 0.1})
	r.show_me()
	assert_eq(r.hints_on(1), 1)


func test_a_miss_is_a_hint_and_the_step_goes_again() -> void:
	var r := _run()
	r.feed({"ok": true, "dt": 0.1})
	r.feed({"pressed": ["phone"], "dt": 0.1})
	var e := r.feed({"answer": 1, "dt": 0.1})
	assert_true(e.miss)
	assert_true(e.coach, "a miss shows the step")
	assert_eq(str(r.current().id), "safe", "the same step again")
	assert_eq(r.hints_on(2), 1)


func test_a_run_with_no_hint_is_by_myself() -> void:
	var r := _run()
	r.feed({"ok": true, "dt": 1.0})
	r.feed({"pressed": ["phone"], "dt": 2.0})
	r.feed({"answer": 0, "dt": 3.0})
	var o := r.outcome()
	assert_true(o.finished)
	assert_eq(int(o.stamps), LifeData.DONE | LifeData.SELF)
	assert_eq(int(o.hints), 0)
	assert_almost_eq(float(o.seconds), 6.0, 0.01)


func test_a_run_with_a_hint_is_done_it() -> void:
	var r := _run()
	r.feed({"ok": true, "dt": 0.1})
	r.show_me()
	r.feed({"pressed": ["phone"], "dt": 0.1})
	r.feed({"answer": 0, "dt": 0.1})
	assert_eq(int(r.outcome().stamps), LifeData.DONE)


func test_the_expert_try_with_no_hint_earns_every_stamp() -> void:
	var r := _run(true)
	r.feed({"ok": true, "dt": 0.1})
	r.feed({"pressed": ["phone"], "dt": 0.1})
	r.feed({"answer": 0, "dt": 0.1})
	assert_eq(int(r.outcome().stamps), LifeData.DONE | LifeData.SELF | LifeData.EXPERT)


func test_the_expert_coach_waits_twenty_seconds() -> void:
	var r := _run(true)
	r.feed({"ok": true, "dt": 0.1})
	var coached := false
	for i in 150:
		coached = coached or bool(r.feed({"dt": 0.1}).coach)
	assert_false(coached)
	for i in 60:
		coached = coached or bool(r.feed({"dt": 0.1}).coach)
	assert_true(coached)


func test_an_unfinished_run_earns_nothing() -> void:
	var r := _run()
	r.feed({"ok": true, "dt": 0.1})
	var o := r.outcome()
	assert_false(o.finished)
	assert_eq(int(o.stamps), 0)


func test_the_log_has_each_steps_time_and_hint() -> void:
	var r := _run()
	r.feed({"ok": true, "dt": 1.5})
	r.show_me()
	r.feed({"pressed": ["phone"], "dt": 2.5})
	r.feed({"answer": 0, "dt": 0.5})
	assert_eq(r.steps_log.size(), 3)
	assert_eq(str(r.steps_log[1].id), "phone")
	assert_true(bool(r.steps_log[1].hinted))
	assert_false(bool(r.steps_log[2].hinted))
	assert_almost_eq(float(r.steps_log[1].seconds), 2.5, 0.01)


func test_the_coach_shows_the_one_next_thing() -> void:
	var r := _run()
	r.feed({"ok": true, "dt": 0.1})
	assert_eq(r.next_targets(), ["phone"] as Array[String])
