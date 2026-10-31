extends GutTest
## Owner #78 (spec §24): the Wonders Passport (WonderData's stamps, WondersPassportRules) and each wonder's fact quiz:
## a stamp the first time a wonder is reached, saved in the profile and merged by the server backup without loss; a
## question answered right the first time pays EarnRules.FACT_QUIZ_GOLD once, a wrong first answer never pays, a
## question answered before never pays again (the fair-fun rules: never for time or for coming back).


func test_a_stamp_the_first_time_a_wonder_is_reached() -> void:
	var w := WonderData.new()
	assert_false(w.stamped(&"pyramid"))
	assert_true(w.stamp(&"pyramid"), "the first stamp")
	assert_false(w.stamp(&"pyramid"), "never twice")
	assert_true(w.stamped(&"pyramid"))
	assert_false(w.stamp(&"moon"), "not a wonder")
	assert_false(w.is_empty())
	assert_eq(WondersPassportRules.count_words(w), "1 of 21 stamps")
	assert_eq(WondersPassportRules.stamp_words(w), "Stamp! 1 of 21 wonders in your Wonders Passport.")
	for id in WonderFacts.ORDER:
		w.stamp(id)
	assert_string_contains(WondersPassportRules.stamp_words(w), "full")


func test_the_passport_saves_and_merges_without_loss() -> void:
	var a := WonderData.new()
	a.stamp(&"pyramid")
	a.answer("pyramid_1", true)
	var b := WonderData.new()
	b.stamp(&"colossus")
	b.answer("pyramid_1", false)
	b.answer("colossus_2", true)
	var back := WonderData.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	assert_true(back.stamped(&"pyramid"))
	assert_true(back.quiz_right("pyramid_1"))
	back.merge_from(b)
	assert_true(back.stamped(&"pyramid") and back.stamped(&"colossus"), "every stamp of both")
	assert_true(back.quiz_right("pyramid_1"), "a right answer stays right")
	assert_true(back.quiz_right("colossus_2"))
	var junk := WonderData.from_dict({"wonders": {"pyramid": 1, "moon": 1, "gardens": 99, "zeus": "x"},
		"quiz": {"pyramid_1": 1, "nope": 1, "zeus_1": 7}})
	assert_eq(junk.wonders, {"pyramid": 1}, "only real wonders and marks")
	assert_eq(junk.quiz, {"pyramid_1": 1})


func test_every_wonder_has_a_quiz_whose_answers_are_its_facts() -> void:
	var ids := {}
	for q in WonderFacts.questions():
		assert_false(ids.has(q.id), "one question per id: %s" % q.id)
		ids[q.id] = true
		assert_eq((q.choices as Array).size(), 3, str(q.id))
		assert_between(int(q.right), 0, 2)
		assert_true(str(q.id).begins_with(String(q.wonder)), str(q.id))
	for id in WonderFacts.ORDER:
		assert_gte(WondersPassportRules.questions(id).size(), 2, "%s has a quiz" % id)
	var rights := {0: 0, 1: 0, 2: 0}
	for q in WonderFacts.questions():
		rights[int(q.right)] += 1
	for k: int in rights:
		assert_gt(rights[k], 1, "the right answer is not always in the same place")


func test_a_question_right_the_first_time_pays_once() -> void:
	var w := WonderData.new()
	var r := WondersPassportRules.answer(w, "pyramid_1", 0)
	assert_true(r.right)
	assert_eq(r.gold, EarnRules.FACT_QUIZ_GOLD)
	assert_eq(r.words, "Right! +%d gold!" % EarnRules.FACT_QUIZ_GOLD)
	var again := WondersPassportRules.answer(w, "pyramid_1", 0)
	assert_true(again.right)
	assert_eq(again.gold, 0, "never paid again")
	var wrong := WondersPassportRules.answer(w, "pyramid_2", 0)
	assert_false(wrong.right)
	assert_eq(wrong.gold, 0)
	assert_string_contains(wrong.words, "The Great Pyramid", "it says the right answer")
	var later := WondersPassportRules.answer(w, "pyramid_2", 1)
	assert_true(later.right, "a child may try again to learn it")
	assert_eq(later.gold, 0, "but a wrong first answer never pays")
	assert_eq(WondersPassportRules.answer(w, "nope", 0).gold, 0)
	assert_eq(WondersPassportRules.stamps(w)[0].stars, 1, "one quiz star for the pyramid")


func test_the_quiz_opens_once_the_wonder_is_stamped_and_the_earn_row_pays() -> void:
	var w := WonderData.new()
	assert_false(WondersPassportRules.may_quiz(w, &"zeus"), "visit it first")
	w.stamp(&"zeus")
	assert_true(WondersPassportRules.may_quiz(w, &"zeus"))
	var row := {}
	for r: Dictionary in EarnRules.TABLE:
		if r.id == "fact_quiz":
			row = r
	assert_eq(row.by, "game", "the fact quiz pays now (owner #78)")
	assert_eq(int(row.gold), EarnRules.FACT_QUIZ_GOLD)


func test_the_guide_says_how_many_are_visited_and_which_is_next() -> void:
	var list: Array[Dictionary] = [{"id": &"a", "name": "Great Pyramid of Giza", "pos": Vector3(0, 0, 10), "found": true},
		{"id": &"b", "name": "Colossus of Rhodes", "pos": Vector3(0, 0, 20), "found": false}]
	assert_eq(WondersPassportRules.progress_words(list, Vector3.ZERO),
		"1 of 2 wonders visited! Next: the Colossus of Rhodes. Follow the arrow.")
	list[1].found = true
	assert_string_contains(WondersPassportRules.progress_words(list, Vector3.ZERO), "You visited all 2 wonders!")


func test_the_facts_are_honest_about_what_is_gone_and_what_is_believed() -> void:
	assert_eq(WonderFacts.status(&"pyramid"), WonderFacts.STANDING, "the only one still standing")
	assert_eq(WonderFacts.status(&"gardens"), WonderFacts.UNKNOWN, "no one knows for sure they existed")
	for id: StringName in [&"artemis", &"zeus", &"mausoleum", &"colossus", &"lighthouse"]:
		assert_eq(WonderFacts.status(id), WonderFacts.GONE, str(id))
		var said := " ".join(WonderFacts.of(id).facts as Array)
		assert_true(said.contains("gone") or said.contains("lost") or said.contains("knocked it down"),
			"%s's facts say it is gone" % id)
	assert_string_contains(" ".join(WonderFacts.of(&"gardens").facts as Array), "never found them")
	assert_string_contains(WonderFacts.of(&"gardens").sight, "no one knows for sure")
	for id: StringName in [&"artemis", &"zeus", &"colossus"]:
		assert_string_contains(WonderFacts.of(id).sight, "believed", "%s: religion as what people believed" % id)
	assert_string_contains(WonderFacts.TOUR_INTRO, "only the Great Pyramid still stands")


func test_every_line_is_short_enough_to_read() -> void:
	for id in WonderFacts.ORDER:
		var w := WonderFacts.of(id)
		for f: String in w.facts:
			assert_between(f.length(), 20, 120, "%s: %s" % [id, f])
		assert_lte(str(w.sight).length(), 150, str(w.sight))
		assert_lte(str(w.secret).length(), 180, str(w.secret))
		for q: Dictionary in w.quiz:
			assert_lte(str(q.q).length(), 80, str(q.q))
			for c: String in q.choices:
				assert_lte(c.length(), 40, c)
