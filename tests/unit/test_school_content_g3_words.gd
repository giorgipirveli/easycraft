extends GutTest
## Owner #70 ("start from grade 3 and finish all grades accordingly"), the grade 3 science and English agent: every
## science and English unit of grade 3's outline (docs/design/school-curriculum-research.md §6.3: NGSS, Common Core ELA,
## England Year 4 and Singapore P3 merged) is written: a lesson of 3 or more cards, at least 12 hand-written exercises,
## each with a hint and a worked answer, at levels 1, 2 and 3 and of two kinds or more, and rounds that fill at every
## star count, vary with the seed and never show a hand-written exercise twice. (Every exercise's validity, answers,
## pictures and words are the shared content test's, test_school_content.gd.)

const GRADE := 3
const SUBJECTS: Array[String] = ["science", "english"]
const UNITS := {"science": 18, "english": 18}
const MIN_EXERCISES := 12
const MIN_DISTINCT := 12


func test_grade_3_science_and_english_are_written_for_every_unit() -> void:
	for subject in SUBJECTS:
		var units := Curriculum.units(GRADE, subject)
		assert_eq(units.size(), UNITS[subject], "grade 3 %s: the outline's units" % subject)
		for u: Dictionary in units:
			var id := str(u.id)
			assert_true(Curriculum.has_content(id), "%s is written" % id)
			if not Curriculum.has_content(id):
				continue
			assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
			var c := Curriculum.content(id)
			assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
			assert_gte((c.exercises as Array).size(), MIN_EXERCISES, "%s: at least %d hand-written exercises" % [id,
				MIN_EXERCISES])
			var levels := {}
			var types := {}
			for ex: Dictionary in c.exercises:
				levels[int(ex.level)] = true
				types[str(ex.type)] = true
				assert_true(str(ex.get("hint", "")).strip_edges() != "", "%s: a hint" % ex.id)
				assert_true(str(ex.get("explain", "")).strip_edges() != "", "%s: a worked answer" % ex.id)
			assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
			assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
			var distinct := {}
			for stars in [0, 1, 2]:
				for s in 20:
					var round := RoundPlan.plan(c, s * 7 + stars, stars)
					assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
					var ids := {}
					for ex in round:
						distinct[str(ex.prompt) + str(ex.get("picture", ""))] = true
						if not str(ex.id).begins_with("gen:"):
							assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
							ids[ex.id] = true
			assert_gte(distinct.size(), MIN_DISTINCT, "%s: varied practice" % id)


## The outline keeps its standards and goals, and every written unit names its own grade 3 file.
func test_grade_3_science_and_english_files_are_their_own() -> void:
	for subject in SUBJECTS:
		for u: Dictionary in Curriculum.units(GRADE, subject):
			var name := str(u.id).split(".")[2]
			assert_eq(str(u.get("file", "")), "g3/%s/%s.json" % [subject, name], "%s's file" % u.id)
			assert_gt((u.get("standards", []) as Array).size(), 0, "%s: its standards" % u.id)


## A written unit uses grade 3's own generators only (g3s for science, g3e for English), and every one of them.
func test_grade_3_units_use_grade_3_generators() -> void:
	var prefix := {"science": "g3s.", "english": "g3e."}
	var used := {}
	for subject in SUBJECTS:
		for u: Dictionary in Curriculum.units(GRADE, subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			for g: Dictionary in Curriculum.content(str(u.id)).generators:
				assert_true(str(g.gen).begins_with(prefix[subject]), "%s uses %s" % [u.id, g.gen])
				used[str(g.gen)] = true
	for gen in SchoolGen.ids():
		if gen.begins_with("g3s.") or gen.begins_with("g3e."):
			assert_true(used.has(gen), "%s is used by a grade 3 unit" % gen)
	assert_gte(used.size(), 30, "grade 3's generators")
