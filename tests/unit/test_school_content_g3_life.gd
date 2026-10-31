extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"), the grade 3 life agent: every HEALTH AND PE,
## DESIGN AND TECHNOLOGY and PROJECTS unit of grade 3's outline (docs/design/school-curriculum-research.md §6.3: England
## PE, RSHE and D&T, SHAPE America, NHES, CASEL, Finland's crafts and modules) is written: a lesson of 3 or more cards
## that opens with a quick memory question and ends with something to try in the world (research §5.3), at least 12
## hand-written exercises (a project at least 10), each with a strategy hint and a worked answer, at levels 1, 2 and 3
## and of two kinds or more, and rounds that fill at every star count, vary with the seed and never show a hand-written
## exercise twice. (Every exercise's validity, answers, pictures, sounds and words are the shared content test's,
## test_school_content.gd.) Health is taught kindly: no talk of weight or of good and bad bodies or foods, and nothing
## about puberty or reproduction (research §5.4 rule 4).

const GRADE := 3
const UNITS := {"health_pe": 11, "design_tech": 9, "projects": 3}
const MIN_EXERCISES := {"health_pe": 12, "design_tech": 12, "projects": 10}
const MIN_DISTINCT := 12
## Grade 3 generators these units may use: their own ("g3p"), and a project may borrow grade 3 humanities' ("g3h": grid
## references for mapping a village).
const OWN_GEN := "g3p."
const PROJECT_GEN: Array[String] = ["g3p.", "g3h."]
## Words a health lesson for 8-year-olds never uses (research §5.4 rule 4; no weight talk, no shaming about food).
## (A recipe may still "weigh" its flour; a structure holds a "load".)
const NOT_IN_HEALTH: Array[String] = ["weight", "weights", "overweight", "underweight", "skinny", "fat people", "calorie",
	"calories", "junk", "naughty", "bad food", "bad foods", "puberty", "reproduction", "sex"]


func _units(subject: String) -> Array[Dictionary]:
	return Curriculum.units(GRADE, subject)


func _texts(c: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for card: Dictionary in c.lesson:
		out.append(str(card.get("text", "")))
	for ex: Dictionary in c.exercises:
		out.append_array([str(ex.get("prompt", "")), str(ex.get("hint", "")), str(ex.get("explain", ""))])
		for t: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []):
			out.append(ExerciseCheck.item_text(t))
	return out


func test_grade_3_health_dt_projects_are_written_for_every_unit() -> void:
	for subject: String in UNITS:
		var units := _units(subject)
		assert_eq(units.size(), UNITS[subject], "grade 3 %s: the outline's units" % subject)
		for u: Dictionary in units:
			var id := str(u.id)
			assert_true(Curriculum.has_content(id), "%s is written" % id)
			if not Curriculum.has_content(id):
				continue
			assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
			var c := Curriculum.content(id)
			assert_between((c.lesson as Array).size(), 3, Curriculum.MAX_CARDS, "%s: a lesson of 3 or more cards" % id)
			assert_gte((c.exercises as Array).size(), int(MIN_EXERCISES[subject]), "%s: at least %d hand-written exercises"
				% [id, MIN_EXERCISES[subject]])
			var levels := {}
			var types := {}
			for ex: Dictionary in c.exercises:
				levels[int(ex.level)] = true
				types[str(ex.type)] = true
			assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
			assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
			var distinct := {}
			for stars in [0, 1, 2]:
				for s in 20:
					var round := RoundPlan.plan(c, s * 7 + stars, stars)
					assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
					var ids := {}
					for ex in round:
						distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", ""))] = true
						if not str(ex.id).begins_with("gen:"):
							assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
							ids[ex.id] = true
			assert_gte(distinct.size(), MIN_DISTINCT, "%s: varied practice" % id)


## The outline keeps its standards and goals, and every unit names its own grade 3 file.
func test_the_files_are_their_own() -> void:
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			var name := str(u.id).split(".")[2]
			assert_eq(str(u.get("file", "")), "g3/%s/%s.json" % [subject, name], "%s's file" % u.id)
			assert_gt((u.get("standards", []) as Array).size(), 0, "%s: its standards" % u.id)
			assert_gt((u.get("goals", []) as Array).size(), 0, "%s: its goals" % u.id)


## Research §5.3: every exercise has a strategy hint (not the answer itself) and a worked answer.
func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
				assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
				assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
				assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from earlier) and "Do it in the world" (a challenge to try).
func test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world() -> void:
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			var cards: Array = Curriculum.content(str(u.id)).lesson
			assert_true(str(cards[0].text).contains("?"), "%s: the first card asks a memory question" % u.id)
			assert_true(str(cards[-1].text).to_lower().contains("world"), "%s: the last card is something to try in the world"
				% u.id)


## The units use grade 3's own generators ("g3p"; a project may borrow "g3h"), each of which exists, and every "g3p"
## generator is used by one of them.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			for g: Dictionary in Curriculum.content(str(u.id)).generators:
				var gen := str(g.gen)
				var ok := gen.begins_with(OWN_GEN)
				if subject == "projects":
					ok = PROJECT_GEN.any(func(p: String) -> bool: return gen.begins_with(p))
				assert_true(ok, "%s uses %s" % [u.id, gen])
				assert_true(SchoolGen.exists(gen), "%s: %s exists" % [u.id, gen])
				used[gen] = true
	for gen in SchoolGen.ids():
		if gen.begins_with(OWN_GEN):
			assert_true(used.has(gen), "%s is used by a grade 3 health, D&T or project unit" % gen)


## The brief: dance to a beat (rhythm sounds help), and feel the heart speed up (a heartbeat to hear).
func test_dance_and_the_heart_can_be_heard() -> void:
	for pair: Array in [["g3.health_pe.dance_moves", 4], ["g3.health_pe.heart_exercise", 2]]:
		var id: String = pair[0]
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var c := Curriculum.content(id)
		var sounds := 0
		for card: Dictionary in c.lesson:
			sounds += 1 if card.has("sound") else 0
		for ex: Dictionary in c.exercises:
			if ex.has("sound"):
				sounds += 1
				assert_eq(SchoolSound.problem(ex.sound), "", "%s: its sound" % ex.id)
		assert_gte(sounds, int(pair[1]), "%s: sounds to listen to" % id)


## The brief's facts, where a child's safety depends on them: the emergency numbers (and "learn yours with a grown-up"),
## hand washing for about 20 seconds, and 9 to 12 hours of sleep.
func test_the_safety_facts_are_taught() -> void:
	var must := {"g3.health_pe.getting_help": ["999", "911", "112", "grown-up", "where"],
		"g3.health_pe.germs_hygiene": ["20 seconds", "soap"], "g3.health_pe.sleep_rest": ["9 to 12 hours"],
		"g3.health_pe.staying_safe": ["look", "listen", "float", "shade"]}
	for id: String in must:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var lesson := ""
		for card: Dictionary in Curriculum.content(id).lesson:
			lesson += str(card.text) + " "
		for fact: String in must[id]:
			assert_true(lesson.to_lower().contains(fact.to_lower()), "%s's lesson says '%s'" % [id, fact])


## Research §5.4 rule 4 and the brief: never shaming about bodies or food, no weight talk, nothing about puberty.
func test_health_is_taught_kindly() -> void:
	var found: Array[String] = []
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			for t in _texts(Curriculum.content(str(u.id))):
				for w in NOT_IN_HEALTH:
					if RegEx.create_from_string("\\b" + w + "\\b").search(t.to_lower()):
						found.append("%s: '%s' in: %s" % [u.id, w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


## The brief: nets are taught with pictures, and each project has a build on the block board.
func test_nets_have_pictures_and_projects_have_builds() -> void:
	var id := "g3.design_tech.boxes_nets"
	if Curriculum.has_content(id):
		var nets := 0
		for ex: Dictionary in Curriculum.content(id).exercises:
			if str(ex.get("picture", {}).get("kind", "")) == "net":
				nets += 1
			for ch: Variant in ex.get("choices", []):
				if ch is Dictionary and str(ch.get("picture", {}).get("kind", "")) == "net":
					nets += 1
		assert_gte(nets, 4, "%s: nets drawn" % id)
	else:
		fail_test("%s is not written" % id)
	for u: Dictionary in _units("projects"):
		if not Curriculum.has_content(str(u.id)):
			fail_test("%s is not written" % u.id)
			continue
		var builds := 0
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			builds += 1 if str(ex.type) == "build" else 0
		assert_gte(builds, 1, "%s: a build on the block board" % u.id)
