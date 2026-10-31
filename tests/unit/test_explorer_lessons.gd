extends GutTest
## Owner #83 (spec §25.5): Explorer lessons are School units marked "bonus": true with a price, beyond a grade's own
## units (which stay free and open). Every Explorer lesson is written to the School's bar (a lesson, at least 12
## hand-written exercises at levels 1, 2 and 3 of two kinds or more, rounds that fill), costs a price in SpendRules'
## bounds, and is on the Gold Shop's shelf. The first: "How rockets work" (grade 4 science), the core loop's own lesson.

func before_each() -> void:
	Curriculum.clear_cache()


func after_each() -> void:
	Curriculum.clear_cache()


func test_the_first_explorer_lesson_is_how_rockets_work() -> void:
	var ids: Array[String] = []
	for u in SpendRules.bonus_units():
		ids.append(str(u.id))
	assert_has(ids, "g4.science.rockets_explorer")
	var u := Curriculum.unit("g4.science.rockets_explorer")
	assert_eq(str(u.title), "How rockets work")
	assert_eq(SpendRules.lesson_price(u), 150)


func test_every_explorer_lesson_meets_the_school_s_bar() -> void:
	for u in SpendRules.bonus_units():
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, id)
		assert_gte((c.exercises as Array).size(), 12, "%s: at least 12 hand-written exercises" % id)
		var levels := {}
		var types := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.level)] = true
			types[str(ex.type)] = true
			assert_ne(str(ex.get("hint", "")), "", "%s: every exercise has a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")), "", "%s: and a worked answer" % ex.id)
		assert_eq(levels.keys().size(), 3, "%s: levels 1, 2 and 3" % id)
		assert_gte(types.size(), 2, id)
		for stars in [0, 1, 2]:
			for s in 10:
				assert_eq(RoundPlan.plan(c, s * 7 + stars, stars).size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
		var p := SpendRules.lesson_price(u)
		assert_between(p, SpendRules.LESSON_PRICE_MIN, SpendRules.LESSON_PRICE_MAX, id)


func test_a_new_profile_finds_explorer_lessons_closed_and_the_grade_s_own_open() -> void:
	var p := ProfileData.new()
	assert_false(SpendRules.lesson_open(p, "g4.science.rockets_explorer"))
	assert_true(SpendRules.lesson_open(p, "g4.science.hazards"), "a grade's own unit")
