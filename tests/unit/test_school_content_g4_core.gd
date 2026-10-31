extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.4): grade 4's maths, science
## and English get the research's new units: tables, line graphs and pie charts (Singapore P4); electric circuits,
## heat and temperature, solids, liquids and gases, sound and hearing, digestion and teeth (England Y4, Singapore P4);
## myths and traditional tales, accounts and evidence, and writing opinions, reports and narratives (Common Core W.4).
## Each unit teaches with a lesson of 4-8 cards that opens with a memory question and ends with something to try in the
## world and what comes next (research §5.3 rules 1, 7 and 8), has at least 12 hand-written exercises at levels 1, 2 and
## 3 of at least two kinds, each with a hint (a strategy) and a worked answer, and rounds that vary and never show a
## hand-written exercise twice. The Science Lab's experiments that list a unit (TRY IT IN THE LAB) match its lesson.
## (Every exercise's validity, answers, pictures and words are the shared content test's, test_school_content.gd; the
## generators' answers are test_g4_data_gen.gd's and test_g4_core_gen.gd's.)

const GRADE := 4
const UNITS := {
	"maths": ["tables_line_graphs"],
	"science": ["circuits", "heat_temperature", "states_of_matter", "sound", "digestion_teeth"],
	"english": ["myths_tales", "accounts_evidence", "write_opinion", "write_report", "write_narrative"],
}
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## The maths unit's generators are its own source's ("g4d": tables, line graphs, pie charts); the science and English
## units' are "g4c".
const DATA_SOURCE := "g4d."
const CORE_SOURCE := "g4c."
## Picture kinds each unit teaches with (in its lesson or its hand-written exercises).
const PICTURES := {
	"g4.maths.tables_line_graphs": ["table", "line_graph", "pie_chart"],
	"g4.science.circuits": ["lab_circuit"],
	"g4.science.heat_temperature": ["thermometer"],
	"g4.science.states_of_matter": ["states", "thermometer"],
	"g4.science.sound": ["wave"],
	"g4.science.digestion_teeth": ["digestion", "teeth"],
}


func _ids() -> Array[String]:
	var out: Array[String] = []
	for subject: String in UNITS:
		for name: String in UNITS[subject]:
			out.append("g%d.%s.%s" % [GRADE, subject, name])
	return out


func _lesson_text(id: String) -> String:
	var parts: Array[String] = []
	for card: Dictionary in Curriculum.content(id).lesson:
		parts.append(str(card.get("text", "")))
	return " ".join(parts)


func test_the_outline_has_the_research_units() -> void:
	for subject: String in UNITS:
		var ids := {}
		for u: Dictionary in Curriculum.units(GRADE, subject):
			ids[str(u.id)] = u
		for name: String in UNITS[subject]:
			var id := "g%d.%s.%s" % [GRADE, subject, name]
			assert_true(ids.has(id), "%s is in the outline" % id)
			if ids.has(id):
				assert_eq(str(ids[id].get("file", "")), "g%d/%s/%s.json" % [GRADE, subject, name], "%s names its file" % id)


## Grade 4's maths, science and English: every unit of the outline is written now (17 + 1, 12 + 5, 13 + 5).
func test_grade_4_maths_science_and_english_are_complete() -> void:
	for subject: String in ["maths", "science", "english"]:
		for u: Dictionary in Curriculum.units(GRADE, subject):
			assert_true(Curriculum.has_content(str(u.id)), "%s is written" % u.id)


func test_every_unit_is_written_and_meets_the_bar() -> void:
	var exercises := 0
	var cards := 0
	for id in _ids():
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), MIN_CARDS, Curriculum.MAX_CARDS, "%s: a lesson of 4-8 cards" % id)
		cards += (c.lesson as Array).size()
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
					distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", ""))] = true
					if not str(ex.id).begins_with("gen:"):
						assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
						ids[ex.id] = true
		assert_gte(distinct.size(), 12, "%s: varied practice" % id)
	gut.p("%d lesson cards and %d hand-written exercises in grade 4's new maths, science and English units" % [cards,
		exercises])


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from earlier), "Spiral" (name what comes next) and "Do it in the
## world" (a challenge to try).
func test_every_lesson_starts_with_memory_and_ends_in_the_world_with_what_comes_next() -> void:
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var lesson: Array = Curriculum.content(id).lesson
		assert_true(str(lesson[0].text).begins_with("Quick memory:") and str(lesson[0].text).contains("?"),
			"%s: the first card asks a memory question" % id)
		var last := str(lesson[-1].text)
		assert_true(last.begins_with("Try it in the world:"), "%s: the last card is something to try in the world" % id)
		assert_true(last.contains("Next"), "%s: the last card says what comes next" % id)


func test_no_unit_asks_the_same_question_twice() -> void:
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var seen := {}
		for ex: Dictionary in Curriculum.content(id).exercises:
			var key := str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", ""))
			assert_false(seen.has(key), "%s asks twice: %s" % [id, ex.prompt])
			seen[key] = true


## The maths unit uses "g4d" (and every g4d generator is used by it); the science and English units use "g4c" (every
## one used by one of them).
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var source := DATA_SOURCE if id.begins_with("g4.maths.") else CORE_SOURCE
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with(source), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	var sources := 0
	for gen in SchoolGen.ids():
		if gen.begins_with(DATA_SOURCE) or gen.begins_with(CORE_SOURCE):
			sources += 1
			assert_true(used.has(gen), "%s is used by a grade 4 maths, science or English unit" % gen)
	assert_gte(sources, 10, "g4d and g4c have their generators")
	var maths := Curriculum.content("g4.maths.tables_line_graphs")
	if not maths.is_empty():
		var levels := {}
		for g: Dictionary in maths.generators:
			levels[int(g.level)] = true
		assert_eq(levels.keys().size(), 3, "the maths unit's generators give endless practice at every level")


## Every picture kind a unit is about appears in it (a circuit, a thermometer, a line graph, …).
func test_every_unit_is_taught_with_its_pictures() -> void:
	for id: String in PICTURES:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var c := Curriculum.content(id)
		var kinds := {}
		for card: Dictionary in c.lesson:
			if card.has("picture"):
				kinds[str(card.picture.kind)] = true
		for ex: Dictionary in c.exercises:
			if ex.has("picture"):
				kinds[str(ex.picture.kind)] = true
		for k: String in PICTURES[id]:
			assert_true(kinds.has(k), "%s is taught with a %s picture" % [id, k])


## Sound is taught by listening (research §5.3 "listen and choose"): a lesson card and three or more exercises play
## sounds.
func test_sound_and_hearing_is_listened_to() -> void:
	var id := "g4.science.sound"
	if not Curriculum.has_content(id):
		fail_test("%s is not written" % id)
		return
	var c := Curriculum.content(id)
	var cards := (c.lesson as Array).filter(func(card: Dictionary) -> bool: return card.has("sound"))
	var exercises := (c.exercises as Array).filter(func(ex: Dictionary) -> bool: return ex.has("sound"))
	assert_gte(cards.size(), 1, "a lesson card to listen to")
	assert_gte(exercises.size(), 3, "exercises to listen to")


## Spec §23: an experiment that lists a unit shows TRY IT IN THE LAB on its page, so the unit's lesson says what the Lab
## lets the child do, with the experiment's own facts: the circuit's switch, a gap and two dimmer bulbs; the heat
## scene's melting (and, for the states of matter, boiling) temperatures.
func test_the_lab_experiments_match_the_lessons() -> void:
	var linked := 0
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		for e_id in LabExperiments.for_unit(id):
			linked += 1
			var e := LabExperiments.experiment(e_id)
			var text := _lesson_text(id)
			assert_true(text.contains("TRY IT IN THE LAB"), "%s: the lesson points to the Lab's %s" % [id, e_id])
			var scene: Dictionary = e.get("scene", {})
			match str(scene.get("kind", "")):
				"circuit":
					for w: String in ["switch", "gap", "second bulb", "dimly"]:
						assert_true(text.contains(w), "%s: the lesson says '%s' as the Lab does" % [id, w])
				"heat":
					assert_true(text.contains("%d °C" % int(scene.melt)), "%s: ice melts at %d °C" % [id, int(scene.melt)])
					if id.ends_with("states_of_matter"):
						assert_true(text.contains("%d °C" % int(scene.boil)), "%s: water boils at %d °C" % [id, int(scene.boil)])
	assert_eq(linked, 3, "the Lab lists circuits, heat and temperature, and the states of matter")


## Research §5.4: electricity is taught with its safety rules; the digestive system leaves out human reproduction.
func test_safety() -> void:
	var circuits := "g4.science.circuits"
	var body := "g4.science.digestion_teeth"
	if not Curriculum.has_content(circuits) or not Curriculum.has_content(body):
		fail_test("circuits and digestion are not written")
		return
	assert_true(_lesson_text(circuits).contains("socket"), "circuits: never play with plugs or sockets")
	var all := JSON.stringify(Curriculum.content(body)).to_lower()
	for w: String in ["puberty", "reproduc", "sex"]:
		assert_false(all.contains(w), "digestion and teeth: nothing about %s" % w)
