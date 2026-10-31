extends GutTest
## Owner #68 (spec §22.1): a practice round is 6 exercises, easy to harder, from the unit's hand-written exercises and
## its generators (seeded: every round is new, the same seed gives the same round). More stars, harder rounds.


func _tf(level: int, i: int) -> Dictionary:
	return {"type": "truefalse", "prompt": "Statement %d at level %d." % [i, level], "answer": i % 2 == 0,
		"hint": "Think.", "level": level, "id": "u#%d" % i}


func _content(hand: int, gens: Array) -> Dictionary:
	var ex: Array = []
	for i in hand:
		ex.append(_tf(1 + i % 3, i))
	return {"id": "g4.maths.test", "lesson": [], "exercises": ex, "generators": gens}


func test_a_round_is_six_exercises_from_easy_to_hard() -> void:
	var round := RoundPlan.plan(_content(12, []), 1, 0)
	assert_eq(round.size(), MasteryRules.ROUND_SIZE)
	var levels: Array[int] = []
	for ex in round:
		levels.append(int(ex.level))
	assert_eq(levels, [1, 1, 2, 2, 2, 3] as Array[int])


func test_more_stars_harder_rounds() -> void:
	var levels: Array[int] = []
	for ex in RoundPlan.plan(_content(12, []), 1, 2):
		levels.append(int(ex.level))
	assert_eq(levels, [2, 2, 3, 3, 3, 3] as Array[int])


func test_hand_written_exercises_are_not_repeated_in_a_round_when_there_are_enough() -> void:
	var ids := {}
	for ex in RoundPlan.plan(_content(18, []), 7, 1):
		assert_false(ids.has(ex.id), "%s twice" % ex.id)
		ids[ex.id] = true


func test_the_same_seed_gives_the_same_round_and_others_differ() -> void:
	var content := _content(4, [{"gen": "g4m.digit_value", "level": 1}, {"gen": "g4m.digit_value", "level": 2},
		{"gen": "g4m.digit_value", "level": 3}])
	var a := RoundPlan.plan(content, 42, 0)
	assert_eq(a, RoundPlan.plan(content, 42, 0))
	var different := 0
	for s in range(1, 20):
		if RoundPlan.plan(content, s, 0) != a:
			different += 1
	assert_gt(different, 15, "rounds change with the seed")


func test_generated_exercises_are_valid_and_carry_their_level() -> void:
	var content := _content(0, [{"gen": "g4m.digit_value", "level": 1}, {"gen": "g4m.digit_value", "level": 3}])
	for s in 30:
		for ex in RoundPlan.plan(content, s, 1):
			assert_eq(ExerciseCheck.problem(ex), "", str(ex))
			assert_true(str(ex.id).begins_with("gen:g4m.digit_value:"))


func test_a_level_the_unit_lacks_uses_the_nearest() -> void:
	var only_easy := {"id": "g4.maths.test", "exercises": [_tf(1, 0), _tf(1, 2), _tf(1, 4), _tf(1, 6)], "generators": []}
	var round := RoundPlan.plan(only_easy, 3, 2)
	assert_eq(round.size(), 6, "a small unit still fills a round (repeating)")


func test_an_empty_unit_gives_no_round() -> void:
	assert_eq(RoundPlan.plan({"id": "g4.maths.test"}, 1, 0), [] as Array[Dictionary])
	assert_eq(RoundPlan.plan({"id": "g4.maths.test", "generators": [{"gen": "g4m.nope", "level": 1}]}, 1, 0),
		[] as Array[Dictionary], "an unknown generator makes nothing")


func test_school_gen_knows_its_generators() -> void:
	assert_true(SchoolGen.exists("g4m.digit_value"))
	assert_false(SchoolGen.exists("g4m._pick"), "helpers are not generators")
	assert_false(SchoolGen.exists("g4m.nope"))
	assert_false(SchoolGen.exists("zz.digit_value"))
	assert_true(SchoolGen.ids().has("g4m.digit_value"))
	assert_eq(SchoolGen.make("g4m.nope", 1, 1), {})


# --- Owner #68, grade 4 agent: hand-written choices are written with the right one first; a round mixes them ---------

func _choice(level: int, i: int) -> Dictionary:
	return {"type": "choice", "prompt": "Pick %d." % i, "choices": ["right", "b", "c", "d"], "answer": 0, "hint": "Think.",
		"level": level, "id": "u#%d" % i}


func test_a_hand_written_choice_is_shown_with_its_choices_mixed() -> void:
	var content := {"id": "g4.maths.test", "exercises": [_choice(1, 0), _choice(2, 1), _choice(3, 2)], "generators": []}
	var first := 0
	var n := 0
	for s in 40:
		for ex in RoundPlan.plan(content, s, 0):
			assert_eq(ExerciseCheck.problem(ex), "", str(ex))
			assert_eq(ExerciseCheck.answer_text(ex), "right", "the answer follows its choice")
			assert_eq((ex.choices as Array).size(), 4)
			first += int(int(ex.answer) == 0)
			n += 1
	assert_lt(first, n / 2, "the right choice is not always the first button (%d of %d)" % [first, n])
	assert_eq(content.exercises[0].answer, 0, "the unit's own data is not changed")


func test_mixing_the_choices_keeps_the_same_round_for_a_seed() -> void:
	var content := {"id": "g4.maths.test", "exercises": [_choice(1, 0), _choice(1, 1), _choice(2, 2), _choice(2, 3),
		_tf(2, 4), _choice(3, 5), _tf(3, 6)], "generators": []}
	assert_eq(RoundPlan.plan(content, 9, 0), RoundPlan.plan(content, 9, 0), "the same seed, the same round")
