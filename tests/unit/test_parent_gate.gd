extends GutTest
## M3 Task 17 (spec §5.12, §5.14): the parent gate in front of the Theater's switch. A sum a grown-up
## solves at a glance, written in words so a young child can't just copy digits; and the switch in
## the profile.


func before_each() -> void:
	ParentGate.reset_tries()


func after_each() -> void:
	ParentGate.reset_tries()


func test_the_question_is_written_in_words() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 30:
		var q := ParentGate.make(rng)
		assert_between(int(q.a), ParentGate.MIN_A, ParentGate.MAX_A)
		assert_between(int(q.b), ParentGate.MIN_B, ParentGate.MAX_B)
		assert_eq(q.answer, int(q.a) * int(q.b))
		assert_string_contains(q.text, ParentGate.words(q.a))
		assert_string_contains(q.text, ParentGate.words(q.b))
		assert_false(RegEx.create_from_string("[0-9]").search(q.text) != null, "no digits to copy: %s" % q.text)


func test_numbers_in_words() -> void:
	assert_eq(ParentGate.words(6), "six")
	assert_eq(ParentGate.words(13), "thirteen")
	assert_eq(ParentGate.words(20), "twenty")
	assert_eq(ParentGate.words(27), "twenty-seven")
	assert_eq(ParentGate.words(99), "ninety-nine")


func test_checking_the_answer() -> void:
	var q := {"a": 14, "b": 7, "answer": 98, "text": "x"}
	assert_true(ParentGate.check(q, "98"))
	assert_true(ParentGate.check(q, " 98 "))
	for wrong: String in ["", "97", "9 8", "98.0", "ninety-eight", "-98", "098x"]:
		assert_false(ParentGate.check(q, wrong), "'%s'" % wrong)
	assert_false(ParentGate.check({}, "0"), "no question, no pass")


func test_the_profile_keeps_the_switch() -> void:
	var p := ProfileData.new()
	assert_eq(p.theater_switch, TheaterRules.SWITCH_AUTO, "a new profile: on for 13+, off for children")
	p.theater_switch = TheaterRules.SWITCH_ON
	assert_eq(ProfileData.from_json(p.to_json()).theater_switch, TheaterRules.SWITCH_ON)
	p.theater_switch = TheaterRules.SWITCH_OFF
	assert_eq(ProfileData.from_json(p.to_json()).theater_switch, TheaterRules.SWITCH_OFF)
	for bad: String in ['{"theater_switch": "yes"}', '{"theater_switch": 1}', '{"theater_switch": true}', '{}']:
		assert_eq(ProfileData.from_json(bad).theater_switch, TheaterRules.SWITCH_AUTO, bad)


# --- M4 Task 10 review E: three wrong answers lock every gate for a minute ---

func test_three_wrong_answers_in_a_row_lock_the_gate_for_a_minute() -> void:
	assert_eq(ParentGate.MAX_WRONG, 3)
	assert_eq(ParentGate.LOCK_MSEC, 60_000)
	assert_false(ParentGate.record_wrong(1000))
	assert_false(ParentGate.record_wrong(2000))
	assert_false(ParentGate.is_locked(2000), "two wrong answers: another question")
	assert_true(ParentGate.record_wrong(3000), "the third one locks it")
	assert_true(ParentGate.is_locked(3000))
	assert_eq(ParentGate.wait_seconds(3000), 60)
	assert_eq(ParentGate.wait_seconds(62_500), 1, "rounded up")
	assert_true(ParentGate.is_locked(62_999))
	assert_false(ParentGate.is_locked(63_000))
	assert_eq(ParentGate.wait_seconds(63_000), 0)
	assert_false(ParentGate.record_wrong(63_000), "a new count after the lock")


func test_a_right_answer_starts_the_count_again() -> void:
	ParentGate.record_wrong(1000)
	ParentGate.record_wrong(2000)
	ParentGate.record_right()
	assert_false(ParentGate.record_wrong(3000))
	assert_false(ParentGate.record_wrong(4000))
	assert_false(ParentGate.is_locked(4000))


func test_the_lock_line_is_kind_and_says_when_to_try_again() -> void:
	var t := ParentGate.locked_text(45)
	assert_string_contains(t, "45 seconds")
	assert_true(t.to_lower().contains("grown-up"), "it speaks to the grown-up: %s" % t)
	assert_string_contains(ParentGate.locked_text(1), "1 second.")
	for unkind: String in ["wrong", "fail", "error", "stupid", "cheat", "locked out"]:
		assert_false(t.to_lower().contains(unkind), "\"%s\" in: %s" % [unkind, t])
