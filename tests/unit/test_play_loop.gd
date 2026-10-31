extends GutTest
## Owner #122 (docs/design/learning-is-play.md §4): a unit's play is a loop: the hook (a problem in the place), the try
## (the round's first challenge, before any words), see why (the coach's one line after the try), play (the rest of the
## round), use it in the world (the world task), then the end. A challenge: a miss is "not yet" (the world reacts, the
## hint), the second miss has the ghost do one step, the third shows the worked answer. Only a challenge right the first
## try with no help counts towards the stars (MasteryRules, unchanged). Owner #133, #134: only what a child can play
## without reading comes into play (PlayReadless): a written choice or a claim stays in the School.

const CONTENT := {"id": "g4.maths.big_numbers", "lesson": [
		{"text": "Quick memory: what is 3 × 4?"},
		{"text": "A digit's place tells what it is worth."},
		{"text": "We read big numbers in groups of three."},
		{"text": "Try it in the world: build a tower of 347 blocks. Next: tables."}],
	"exercises": [
		{"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens place.", "level": 1},
		{"type": "order", "prompt": "Smallest to biggest.", "items": ["120", "99", "347"], "answer": [1, 0, 2],
			"hint": "Look at the hundreds.", "level": 1},
		{"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Put the parts together.", "level": 2},
		{"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 0,
			"hint": "No hundreds.", "level": 3},
		{"type": "sort", "prompt": "More than 100 or not?", "hint": "Hundreds.", "groups": ["more", "not more"],
			"items": ["347", "99", "120"], "answer": [0, 1, 0], "level": 3}]}


func _loop(stars: int = 0) -> PlayLoop:
	return PlayLoop.make(CONTENT, 7, stars, {"title": "Big numbers", "goals": ["Read big numbers"]})


func test_a_loop_is_a_round_of_six_that_starts_with_its_hook() -> void:
	var l := _loop()
	assert_eq(l.challenges.size(), MasteryRules.ROUND_SIZE)
	assert_eq(l.phase, PlayLoop.HOOK)
	assert_eq(int(l.current().level), 1, "the try is at level 1 for a new unit")
	assert_ne(l.hook_line, "")
	assert_eq(l.world_task, "Build a tower of 347 blocks.")
	assert_eq(l.coach_lines, ["A digit's place tells what it is worth.", "We read big numbers in groups of three."] as Array[String])


func test_the_try_comes_before_any_words_then_see_why_then_play() -> void:
	var l := _loop()
	l.start()
	assert_eq(l.phase, PlayLoop.TRY)
	assert_eq(l.answer(true), PlayLoop.RIGHT)
	assert_eq(l.next(), PlayLoop.WHY, "the coach's line comes after the try")
	assert_eq(l.see_why(), "A digit's place tells what it is worth.")
	l.play_on()
	assert_eq(l.phase, PlayLoop.PLAY)
	assert_eq(l.index, 1)
	for i in 5:
		l.answer(true)
		l.next()
	assert_eq(l.phase, PlayLoop.WORLD, "then the world task")
	assert_eq(l.right_first, 6)
	l.finish()
	assert_eq(l.phase, PlayLoop.END)


func test_misses_say_not_yet_then_the_ghost_shows_then_the_answer() -> void:
	var l := _loop()
	l.start()
	assert_eq(l.answer(false), PlayLoop.NOT_YET)
	assert_false(l.answered)
	assert_eq(l.answer(false), PlayLoop.GHOST, "shown, not told: the ghost does one step")
	assert_false(l.answered)
	assert_eq(l.answer(false), PlayLoop.SHOWN, "the worked answer")
	assert_true(l.answered)
	assert_eq(l.answer(true), "", "nothing more once it is shown")
	assert_eq(l.right_first, 0)


func test_only_right_the_first_try_with_no_help_counts() -> void:
	var l := _loop()
	l.start()
	l.answer(false)
	assert_eq(l.answer(true), PlayLoop.RIGHT)
	assert_false(l.first_try)
	l.next()
	l.play_on()
	l.show_me()
	l.answer(true)
	assert_false(l.first_try, "SHOW ME is help")
	l.next()
	l.answer(true)
	assert_true(l.first_try)
	assert_eq(l.right_first, 1)


func test_a_challenge_moves_on_only_once_answered() -> void:
	var l := _loop()
	l.start()
	assert_eq(l.next(), PlayLoop.TRY, "not answered yet: it stays")
	assert_eq(l.index, 0)


func test_the_coach_says_why_after_each_right_answer_in_play() -> void:
	var l := _loop()
	assert_eq(l.why_after(0), "", "the try's why is the see-why card")
	assert_eq(l.why_after(1), "We read big numbers in groups of three.")
	assert_eq(l.why_after(2), "", "one idea each: no more lines, no line")


func test_a_review_starts_at_the_unit_s_own_level() -> void:
	var l := _loop(2)
	assert_eq(int(l.current().level), 2, "come back: a harder round (RoundPlan)")


func test_the_same_seed_makes_the_same_loop() -> void:
	assert_eq(_loop().challenges, _loop().challenges)


func test_written_choices_and_claims_never_come_into_play() -> void:
	for seed in [1, 7, 99, 1234]:
		for ex: Dictionary in PlayLoop.make(CONTENT, seed, 0).challenges:
			assert_true(PlayReadless.plays(ex), "%s plays without reading" % ex.get("type"))
			assert_false(str(ex.type) in ["choice", "truefalse"])


func test_a_short_round_is_the_first_few_challenges() -> void:
	var l := PlayLoop.make(CONTENT, 7, 0, {}, 3)
	assert_eq(l.challenges.size(), 3)
	assert_eq(l.challenges, _loop().challenges.slice(0, 3))


func test_a_unit_with_nothing_to_play_without_reading_has_no_round() -> void:
	var c := {"id": "g4.history.x", "lesson": [{"text": "A card."}], "exercises": [
		{"type": "truefalse", "prompt": "The Nile floods.", "answer": true, "hint": "Summer.", "level": 1}]}
	assert_true(PlayLoop.make(c, 7, 0).challenges.is_empty())
