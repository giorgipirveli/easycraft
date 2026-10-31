extends GutTest
## Owner #68, grade 5 maths: every written grade 5 maths unit is a full unit: a lesson of 3 or more cards, at least 8
## hand-written exercises, something to practise at every level (1-3), rounds that fill at every star count with at
## least two kinds of exercise and plenty of variety, and its standards and goals from the outline. (Every exercise's
## validity, answers, pictures and words are the shared content test's, test_school_content.gd.)

const GRADE := 5


func _written() -> Array[String]:
	var out: Array[String] = []
	for u: Dictionary in Curriculum.units(GRADE, "maths"):
		if Curriculum.has_content(str(u.id)):
			out.append(str(u.id))
	return out


func test_written_grade_5_maths_units_are_complete() -> void:
	gut.p("%d grade 5 maths units written" % _written().size())
	for id in _written():
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
		assert_gte((c.exercises as Array).size(), 8, "%s: 8 or more hand-written exercises" % id)
		var levels := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.get("level", 1))] = true
		for g: Dictionary in c.generators:
			levels[int(g.level)] = true
		assert_eq(levels.keys().size(), 3, "%s: something at every level" % id)
		var types := {}
		var distinct := {}
		for stars in [0, 1, 2]:
			for s in 20:
				var round := RoundPlan.plan(c, s * 7 + stars, stars)
				assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
				for ex in round:
					types[str(ex.type)] = true
					distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("grid", ""))] = true
		assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
		assert_gte(distinct.size(), 25, "%s: varied practice" % id)


func test_every_written_unit_uses_its_own_generators() -> void:
	for id in _written():
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with("g5"), "%s uses %s" % [id, g.gen])
