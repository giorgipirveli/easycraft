extends GutTest
## M4 Task 10 review E: the parent gate in front of the grown-up pages (GrownUpGate) was a speed bump with unlimited
## tries. Three wrong answers in a row now lock every gate for a minute, with a kind line saying when a grown-up can try
## again; closing the gate and opening it again keeps the lock (one lock for the app run, ParentGate). It stays an
## adult check: the same multiplication in words, nothing turned into a child's puzzle.

var t := 500_000


func before_each() -> void:
	ParentGate.reset_tries()
	t = 500_000


func after_each() -> void:
	ParentGate.reset_tries()


func _gate() -> GrownUpGate:
	var g := GrownUpGate.new()
	g.msec = func() -> int: return t
	add_child_autofree(g)
	await wait_process_frames(1)
	return g


func _answer(g: GrownUpGate, right: bool) -> void:
	for key in str(int(g.question.answer) + (0 if right else 1)):
		g.press(key)
	g.press("OK")


func test_three_wrong_answers_lock_the_gate_for_a_minute_with_a_kind_line() -> void:
	var g := await _gate()
	watch_signals(g)
	_answer(g, false)
	_answer(g, false)
	assert_true(g.question_label.text.begins_with("Not quite"), "two wrong answers: a new question")
	assert_false(g.keys["OK"].disabled)
	_answer(g, false)
	assert_eq(g.question_label.text, ParentGate.locked_text(60))
	for key: String in g.keys:
		assert_true((g.keys[key] as Button).disabled, "the pad rests: %s" % key)
	assert_false(g.back_button.disabled, "BACK still works")
	_answer(g, true)
	assert_signal_not_emitted(g, "passed", "not even the right answer while it rests")
	t += 30_000
	await wait_process_frames(2)
	assert_eq(g.question_label.text, ParentGate.locked_text(30), "it counts down")
	t += 30_000
	await wait_process_frames(2)
	assert_false(g.keys["OK"].disabled, "a minute later the pad works again")
	assert_string_contains(g.question_label.text, str(g.question.text))
	_answer(g, true)
	assert_signal_emitted(g, "passed")


func test_closing_the_gate_and_opening_it_again_keeps_the_lock() -> void:
	var g := await _gate()
	for i in 3:
		_answer(g, false)
	g.free()
	t += 10_000
	var again := await _gate()
	assert_eq(again.question_label.text, ParentGate.locked_text(50))
	assert_true(again.keys["OK"].disabled)
	watch_signals(again)
	_answer(again, true)
	assert_signal_not_emitted(again, "passed")


func test_a_right_answer_starts_the_count_again() -> void:
	var g := await _gate()
	watch_signals(g)
	_answer(g, false)
	_answer(g, false)
	_answer(g, true)
	assert_signal_emitted(g, "passed")
	var again := await _gate()
	_answer(again, false)
	_answer(again, false)
	assert_true(again.question_label.text.begins_with("Not quite"), "two more wrong answers do not lock it")
	assert_false(again.keys["OK"].disabled)
