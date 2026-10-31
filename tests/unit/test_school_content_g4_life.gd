extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"), the grade 4 life agent: every HEALTH AND PE,
## DESIGN AND TECHNOLOGY and PROJECTS unit of grade 4's outline (docs/design/school-curriculum-research.md §6.4: England
## PE, RSHE and D&T, SHAPE America, NHES, CASEL, Finland's, Estonia's and Japan's crafts, Finland's modules, the IB) is
## written: a lesson of 3 or more cards that opens with a quick memory question and ends with something to try in the
## world (research §5.3), at least 12 hand-written exercises, each with a strategy hint and a worked answer, at levels 1,
## 2 and 3 and of two kinds or more, and rounds that fill at every star count, vary with the seed and never show a
## hand-written exercise twice. (Every exercise's validity, answers, pictures, sounds and words are the shared content
## test's, test_school_content.gd.) Health is taught kindly: no talk of weight or of good and bad bodies or foods, nothing
## about puberty or reproduction (research §5.4 rule 4), and drugs, alcohol, smoking and gambling wait for grade 5 (rule 5).

const GRADE := 4
const UNITS := {"health_pe": 11, "design_tech": 9, "projects": 3}
const MIN_EXERCISES := 12
const MIN_DISTINCT := 12
## Grade 4 generators these units use: their own ("g4w", G4HealthGen).
const OWN_GEN := "g4w."
## Words a health lesson for 9-year-olds never uses (research §5.4 rules 4 and 5; no weight talk, no shaming about food;
## drugs, alcohol, smoking and gambling from grade 5). (A recipe may still "weigh" its flour; a shelter holds a "load".)
const NOT_IN_HEALTH: Array[String] = ["weight", "weights", "overweight", "underweight", "skinny", "fat people", "calorie",
	"calories", "junk", "naughty", "bad food", "bad foods", "diet", "dieting", "puberty", "reproduction", "sex", "drug",
	"drugs", "alcohol", "beer", "wine", "cigarette", "cigarettes", "smoking", "vape", "vaping", "gambling", "gamble",
	"betting"]


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


func _lesson(id: String) -> String:
	var out := ""
	for card: Dictionary in Curriculum.content(id).lesson:
		out += str(card.text) + " "
	return out.to_lower()


## Every picture of a unit (on its cards, its exercises and their choices), with its generators' at every level.
func _pictures(id: String, seeds: int = 0) -> Array:
	var out: Array = []
	var c := Curriculum.content(id)
	var exercises: Array = (c.exercises as Array).duplicate()
	for g: Dictionary in c.generators:
		for s in seeds:
			exercises.append(SchoolGen.make(str(g.gen), s, int(g.level)))
	for card: Dictionary in c.lesson:
		if card.has("picture"):
			out.append(card.picture)
	for ex: Dictionary in exercises:
		if ex.has("picture"):
			out.append(ex.picture)
		for ch: Variant in ex.get("choices", []):
			if ch is Dictionary and ch.has("picture"):
				out.append(ch.picture)
	return out


func test_grade_4_health_dt_projects_are_written_for_every_unit() -> void:
	for subject: String in UNITS:
		var units := _units(subject)
		assert_eq(units.size(), UNITS[subject], "grade 4 %s: the outline's units" % subject)
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


## The outline keeps its standards and goals, and every unit names its own grade 4 file.
func test_the_files_are_their_own() -> void:
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			var name := str(u.id).split(".")[2]
			assert_eq(str(u.get("file", "")), "g4/%s/%s.json" % [subject, name], "%s's file" % u.id)
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


## The units use grade 4's own health, D&T and projects generators ("g4w"), each of which exists, and every "g4w"
## generator is used by one of them.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			for g: Dictionary in Curriculum.content(str(u.id)).generators:
				var gen := str(g.gen)
				assert_true(gen.begins_with(OWN_GEN), "%s uses %s" % [u.id, gen])
				assert_true(SchoolGen.exists(gen), "%s: %s exists" % [u.id, gen])
				used[gen] = true
	var own := 0
	for gen in SchoolGen.ids():
		if gen.begins_with(OWN_GEN):
			own += 1
			assert_true(used.has(gen), "%s is used by a grade 4 health, D&T or project unit" % gen)
	assert_gt(own, 0, "grade 4's health, D&T and projects generators exist")


## The facts a child's safety and health depend on are in the lessons (research §6.4 goals; checked against the NHS,
## the RNLI, the Food Standards Agency and St John Ambulance, docs/devlog/parts/m8-grade4-life.md).
func test_the_safety_facts_are_taught() -> void:
	var must := {
		"g4.health_pe.water_safety": ["red and yellow", "red flag", "float", "999", "coastguard", "throw"],
		"g4.health_pe.first_aid_basics": ["danger", "20 minutes", "running water", "press", "cold", "999"],
		"g4.health_pe.personal_safety": ["trusted", "secret", "surprise", "body belongs to you", "keep telling"],
		"g4.health_pe.food_labels": ["per 100 g", "sugar", "salt", "fat", "green", "red", "water"],
		"g4.health_pe.big_feelings": ["breath", "anger", "worry", "sad", "talk"],
		"g4.health_pe.fitness_parts": ["stamina", "strength", "speed", "flexibility", "warm", "cool down"],
		"g4.design_tech.electric_products": ["circuit", "switch", "battery", "never", "sockets"],
		"g4.design_tech.bread_grains": ["wheat", "flour", "yeast", "gas", "knead"],
	}
	for id: String in must:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var lesson := _lesson(id)
		for fact: String in must[id]:
			assert_true(lesson.contains(fact.to_lower()), "%s's lesson says '%s'" % [id, fact])


## Research §5.4 rules 4 and 5 and the brief: never shaming about bodies or food, no weight talk, nothing about puberty,
## and nothing about drugs, alcohol, smoking or gambling before grade 5.
func test_health_is_taught_kindly() -> void:
	var found: Array[String] = []
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			var c := Curriculum.content(str(u.id))
			var texts := _texts(c)
			for g: Dictionary in c.generators:
				for s in 12:
					var ex := SchoolGen.make(str(g.gen), s, int(g.level))
					texts.append_array([str(ex.prompt), str(ex.hint), str(ex.get("explain", ""))])
			for t in texts:
				for w in NOT_IN_HEALTH:
					if RegEx.create_from_string("\\b" + w + "\\b").search(t.to_lower()):
						found.append("%s: '%s' in: %s" % [u.id, w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


## The units that need a picture to be taught have theirs: beach flags, food labels, circuits, a vehicle's axles, players
## finding space, an orienteering map, the helping hand, and the grade 3 kinds reused (the plate, poses, frames,
## stitches).
func test_the_units_are_drawn() -> void:
	var need := {"g4.health_pe.water_safety": ["beach_flags", 4], "g4.health_pe.food_labels": ["food_label", 4],
		"g4.design_tech.electric_products": ["circuit", 5], "g4.design_tech.wheels_axles": ["chassis", 3],
		"g4.health_pe.invasion_games": ["pitch", 3], "g4.health_pe.striking_fielding": ["pitch", 2],
		"g4.health_pe.outdoor_adventure": ["site_plan", 3], "g4.health_pe.personal_safety": ["hand", 1],
		"g4.projects.river_town": ["site_plan", 2], "g4.projects.light_and_sound_show": ["circuit", 2],
		"g4.design_tech.balanced_meal": ["plate", 2], "g4.health_pe.gymnastics_sequence": ["pose", 3],
		"g4.health_pe.athletics": ["pose", 2], "g4.design_tech.shelters_frames": ["frame", 2],
		"g4.design_tech.textile_bag": ["stitch", 2]}
	for id: String in need:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var n := 0
		for p: Variant in _pictures(id, 6):
			n += 1 if str((p as Dictionary).get("kind", "")) == str(need[id][0]) else 0
		assert_gte(n, int(need[id][1]), "%s: %s pictures" % [id, need[id][0]])


## The light and sound show plays tunes (LISTEN), and every project has a build on the block board.
func test_the_show_can_be_heard_and_projects_have_builds() -> void:
	var id := "g4.projects.light_and_sound_show"
	if Curriculum.has_content(id):
		var sounds := 0
		var c := Curriculum.content(id)
		for card: Dictionary in c.lesson:
			sounds += 1 if card.has("sound") else 0
		for ex: Dictionary in c.exercises:
			if ex.has("sound"):
				sounds += 1
				assert_eq(SchoolSound.problem(ex.sound), "", "%s: its sound" % ex.id)
		assert_gte(sounds, 4, "%s: tunes to listen to" % id)
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
