extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"), the grade 5 life agent: every HEALTH AND PE,
## DESIGN AND TECHNOLOGY and PROJECTS unit of grade 5's outline (docs/design/school-curriculum-research.md §6.5: England
## PE, RSHE and D&T, SHAPE America, NHES, CASEL, Finland's crafts, Finland's modules, Cambridge Global Perspectives, the
## IB) is written: a lesson of 3 or more cards that opens with a quick memory question and ends with something to try in
## the world (research §5.3), at least 12 hand-written exercises, each with a strategy hint and a worked answer, at levels
## 1, 2 and 3 and of two kinds or more, and rounds that fill at every star count, vary with the seed and never show a
## hand-written exercise twice. (Every exercise's validity, answers, pictures, sounds and words are the shared content
## test's, test_school_content.gd.) Health is taught kindly: no talk of weight or of good and bad bodies or foods, nothing
## about puberty or reproduction (research §5.4 rule 4); tobacco, vaping, alcohol and other drugs are taught only in
## "Medicines and harmful substances", factually: health, the law and saying no, nothing that shows use (rule 5).

const GRADE := 5
const UNITS := {"health_pe": 11, "design_tech": 9, "projects": 3}
const MIN_EXERCISES := 12
const MIN_DISTINCT := 12
## Grade 5 generators these units use: their own ("g5w", G5HealthGen).
const OWN_GEN := "g5w."
## Words a health lesson for 10-year-olds never uses (research §5.4 rule 4; no weight talk, no shaming about food). (A
## recipe may still "weigh" its flour; a bridge holds a "load".)
const NOT_IN_HEALTH: Array[String] = ["weight", "weights", "overweight", "underweight", "skinny", "fat people", "calorie",
	"calories", "junk", "naughty", "bad food", "bad foods", "diet", "dieting", "puberty", "reproduction", "sex"]
## Harmful substances and gambling (research §5.4 rule 5): from grade 5, only in the unit that teaches them factually.
const SUBSTANCES: Array[String] = ["drug", "drugs", "alcohol", "beer", "wine", "cigarette", "cigarettes", "tobacco",
	"smoking", "smoker", "smokers", "vape", "vapes", "vaping", "nicotine", "gambling", "gamble", "betting"]
const SUBSTANCES_UNIT := "g5.health_pe.medicines_harmful"
## Words that would show or invite use (rule 5: "nothing shows use").
const SHOWS_USE: Array[String] = ["how to smoke", "light a cigarette", "take a puff", "have a sip", "try a sip",
	"try a vape", "try vaping", "try smoking", "cool to smoke", "cool to vape"]


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


## A unit's texts with its generators' at every level.
func _all_texts(id: String, seeds: int = 12) -> Array[String]:
	var c := Curriculum.content(id)
	var texts := _texts(c)
	for g: Dictionary in c.generators:
		for s in seeds:
			var ex := SchoolGen.make(str(g.gen), s, int(g.level))
			texts.append_array([str(ex.prompt), str(ex.hint), str(ex.get("explain", ""))])
			for t: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []):
				texts.append(ExerciseCheck.item_text(t))
	return texts


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


func _found(t: String, words: Array[String]) -> String:
	for w in words:
		if RegEx.create_from_string("\\b" + w + "\\b").search(t.to_lower()):
			return w
	return ""


func test_grade_5_health_dt_projects_are_written_for_every_unit() -> void:
	for subject: String in UNITS:
		var units := _units(subject)
		assert_eq(units.size(), UNITS[subject], "grade 5 %s: the outline's units" % subject)
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


## The outline keeps its standards and goals, and every unit names its own grade 5 file.
func test_the_files_are_their_own() -> void:
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			var name := str(u.id).split(".")[2]
			assert_eq(str(u.get("file", "")), "g5/%s/%s.json" % [subject, name], "%s's file" % u.id)
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


## The units use grade 5's own health, D&T and projects generators ("g5w"), each of which exists, and every "g5w"
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
			assert_true(used.has(gen), "%s is used by a grade 5 health, D&T or project unit" % gen)
	assert_gt(own, 0, "grade 5's health, D&T and projects generators exist")


## The facts a child's safety and health depend on are in the lessons (research §6.5 goals; checked against the NHS,
## St John Ambulance, the British Red Cross, the UK's laws on age of sale and the Chief Medical Officers' advice,
## docs/devlog/parts/m8-grade5-life.md).
func test_the_safety_facts_are_taught() -> void:
	var must := {
		"g5.health_pe.emergency_first_aid": ["danger", "response", "airway", "breathing", "999", "recovery position",
			"choking", "cough", "grown-up"],
		"g5.health_pe.medicines_harmful": ["trusted adult", "label", "never", "18", "nicotine", "addictive", "alcohol",
			"vap", "tobacco", "say no", "lungs"],
		"g5.health_pe.allergies_illness": ["allergen", "peanuts", "anaphylaxis", "999", "auto-injector", "wash", "38"],
		"g5.health_pe.sleep_screens": ["9 to 12 hours", "screens", "hour before", "light", "bedtime"],
		"g5.health_pe.changing_friendships": ["healthy", "peer pressure", "say no", "trusted"],
		"g5.health_pe.self_esteem": ["self-esteem", "self-talk", "every body", "yet", "edited"],
		"g5.health_pe.orienteering": ["set the map", "compass", "north", "scale"],
		"g5.design_tech.seasonal_cooking": ["season", "wash", "claw", "oven gloves", "grown-up"],
		"g5.design_tech.gears_pulleys": ["teeth", "opposite", "pulley", "belt"],
		"g5.design_tech.bridges": ["compression", "tension", "arch", "truss", "beam", "triangle"],
		"g5.design_tech.control_with_code": ["input", "output", "sensor", "if", "loop"],
	}
	for id: String in must:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var lesson := _lesson(id)
		for fact: String in must[id]:
			assert_true(lesson.contains(fact.to_lower()), "%s's lesson says '%s'" % [id, fact])


## Research §5.4 rule 4 and the brief: never shaming about bodies or food, no weight talk, nothing about puberty or
## reproduction, in any card, exercise or generated exercise.
func test_health_is_taught_kindly() -> void:
	var found: Array[String] = []
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			for t in _all_texts(str(u.id)):
				var w := _found(t, NOT_IN_HEALTH)
				if w != "":
					found.append("%s: '%s' in: %s" % [u.id, w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


## Research §5.4 rule 5: tobacco, vaping, alcohol and other drugs from grade 5, only in the unit that teaches them
## factually (health, the law and saying no), with nothing that shows or invites use; and that unit teaches all of them.
func test_harmful_substances_are_taught_only_factually_in_their_own_unit() -> void:
	var found: Array[String] = []
	for subject: String in UNITS:
		for u: Dictionary in _units(subject):
			if not Curriculum.has_content(str(u.id)):
				continue
			for t in _all_texts(str(u.id)):
				var w := _found(t, SUBSTANCES)
				if w != "" and str(u.id) != SUBSTANCES_UNIT:
					found.append("%s: '%s' in: %s" % [u.id, w, t])
				var use := _found(t, SHOWS_USE)
				if use != "":
					found.append("%s: '%s' in: %s" % [u.id, use, t])
	assert_eq(found, [] as Array[String], "\n".join(found))
	if not Curriculum.has_content(SUBSTANCES_UNIT):
		fail_test("%s is not written" % SUBSTANCES_UNIT)
		return
	var lesson := _lesson(SUBSTANCES_UNIT)
	for w: String in ["tobacco", "vaping", "alcohol", "against the law", "under 18", "say no", "trusted adult"]:
		assert_true(lesson.contains(w), "%s's lesson says '%s'" % [SUBSTANCES_UNIT, w])
	for p: Variant in _pictures(SUBSTANCES_UNIT, 6):   # nothing drawn that shows use: no figures, only words and tables
		assert_false(str((p as Dictionary).get("kind", "")) in ["pose", "lying"], "%s: no figures" % SUBSTANCES_UNIT)


## The units that need a picture to be taught have theirs: a net court, players finding a clear pass, dance shapes, a
## fitness graph, the recovery position and the first aid checks, a compass and a map, gears and pulleys, cams, bridges,
## a build's views, code, a weave, a Roman grid, a food web, and a fair's price list.
func test_the_units_are_drawn() -> void:
	var need := {"g5.health_pe.net_wall_games": ["net_court", 4], "g5.health_pe.tactics": ["pitch", 3],
		"g5.health_pe.create_a_dance": ["pose", 2], "g5.health_pe.personal_best": ["bar_graph", 3],
		"g5.health_pe.emergency_first_aid": ["lying", 2], "g5.health_pe.orienteering": ["compass", 4],
		"g5.health_pe.sleep_screens": ["digital_clock", 3], "g5.design_tech.gears_pulleys": ["gears", 5],
		"g5.design_tech.cams_toys": ["cam", 5], "g5.design_tech.bridges": ["bridge", 5],
		"g5.design_tech.design_on_screen": ["views", 5], "g5.design_tech.control_with_code": ["code", 4],
		"g5.design_tech.fabrics_clothes": ["weave", 3], "g5.design_tech.test_and_review": ["table", 3],
		"g5.projects.roman_town": ["grid", 3], "g5.projects.biome_expedition": ["food_web", 3],
		"g5.projects.fair_with_budget": ["table", 3]}
	for id: String in need:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var n := 0
		for p: Variant in _pictures(id, 6):
			n += 1 if str((p as Dictionary).get("kind", "")) == str(need[id][0]) else 0
		assert_gte(n, int(need[id][1]), "%s: %s pictures" % [id, need[id][0]])


## The dance can be heard (claps to copy), the model is programmed (the robot), the Roman town is found on its grid
## (tap a point), and every project has a build on the block board.
func test_the_dance_is_heard_the_model_coded_and_projects_built() -> void:
	var need := {"g5.health_pe.create_a_dance": ["rhythm", 2], "g5.design_tech.control_with_code": ["robot", 2],
		"g5.projects.roman_town": ["point", 2]}
	for id: String in need:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var n := 0
		var c := Curriculum.content(id)
		for ex: Dictionary in c.exercises:
			n += 1 if str(ex.type) == str(need[id][0]) else 0
		assert_gte(n, int(need[id][1]), "%s: %s exercises" % [id, need[id][0]])
	var dance := "g5.health_pe.create_a_dance"
	if Curriculum.has_content(dance):
		var sounds := 0
		for card: Dictionary in Curriculum.content(dance).lesson:
			sounds += 1 if card.has("sound") else 0
		assert_gte(sounds, 2, "%s: beats to listen to in the lesson" % dance)
	for u: Dictionary in _units("projects"):
		if not Curriculum.has_content(str(u.id)):
			fail_test("%s is not written" % u.id)
			continue
		var builds := 0
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			builds += 1 if str(ex.type) == "build" else 0
		assert_gte(builds, 1, "%s: a build on the block board" % u.id)
