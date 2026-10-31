extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.4): grade 4's history
## (the first civilisations), geography and citizenship are written for every unit of the outline. Each unit teaches
## with a lesson of 3 or more cards that opens with a memory question, ends with something to try in the world and names
## what comes next (research §5.3 rules 1, 7 and 8), has at least 12 hand-written exercises at levels 1, 2 and 3 of at
## least two kinds, each with a hint (a strategy) and a worked answer, and rounds that vary and never show a
## hand-written exercise twice. (Every exercise's validity, answers, pictures and words are the shared content test's,
## test_school_content.gd; the generators' answers are test_g4_humanities_gen.gd's.)

const GRADE := 4
const SUBJECTS: Array[String] = ["history", "geography", "citizenship"]
const UNITS := {"history": 10, "geography": 10, "citizenship": 11}   # research §6.4
const MIN_EXERCISES := 12
## Every generator a grade 4 humanities unit uses is its own source's ("g4h").
const SOURCE := "g4h."


func _units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for subject in SUBJECTS:
		out.append_array(Curriculum.units(GRADE, subject))
	return out


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 4 %s" % subject)


func test_grade_4_history_geography_citizenship_are_written_for_every_unit() -> void:
	var exercises := 0
	for u in _units():
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
		assert_gte((c.exercises as Array).size(), MIN_EXERCISES, "%s: at least %d hand-written exercises" % [id, MIN_EXERCISES])
		exercises += (c.exercises as Array).size()
		var levels := {}
		var types := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.level)] = true
			types[str(ex.type)] = true
		assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
		assert_gte(types.size(), 2, "%s: at least two kinds of hand-written exercise" % id)
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
		assert_gte(distinct.size(), 12, "%s: varied practice" % id)
	gut.p("%d hand-written exercises in grade 4 history, geography and citizenship" % exercises)


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from earlier), "Spiral" (name what comes next) and "Do it in the
## world" (a challenge to try).
func test_every_lesson_starts_with_memory_and_ends_in_the_world_with_what_comes_next() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		assert_true(str(cards[0].text).begins_with("Quick memory:") and str(cards[0].text).contains("?"),
			"%s: the first card asks a memory question" % id)
		var last := str(cards[-1].text)
		assert_true(last.begins_with("Try it in the world:"), "%s: the last card is something to try in the world" % id)
		assert_true(last.contains("Next"), "%s: the last card says what comes next" % id)


## A hand-written exercise's prompt appears once in a unit (a round never shows the same question twice by another id).
func test_no_unit_asks_the_same_question_twice() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var seen := {}
		for ex: Dictionary in Curriculum.content(id).exercises:
			var key := str(ex.prompt) + str(ex.get("picture", ""))
			assert_false(seen.has(key), "%s asks twice: %s" % [id, ex.prompt])
			seen[key] = true


## The generators these units use are grade 4 humanities' own ("g4h"), and each unit's generators exist.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with(SOURCE), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			assert_true(used.has(gen), "%s is used by a grade 4 humanities unit" % gen)
