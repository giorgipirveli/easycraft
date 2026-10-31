extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.5): grade 5's maths, science
## and English get the research's new units: percentages, and angles in triangles and quadrilaterals (Singapore P5,
## England Y6); friction, air resistance and machines, electric systems, how living things reproduce, and breathing and
## the heart (England Y5-Y6, Singapore P5); and quoting to prove it, many sources, writing opinions, explanations and
## stories, and speaking and presenting (Common Core RL/RI/W/SL.5, England Y6). Each unit teaches with a lesson of 4-8
## cards that opens with a memory question and ends with something to try in the world and what comes next (research
## §5.3 rules 1, 7 and 8), has at least 12 hand-written exercises at levels 1, 2 and 3 of at least two kinds, each with
## a hint (a strategy) and a worked answer, and rounds that vary and never show a hand-written exercise twice. The
## Science Lab's circuit experiment, which lists the electric systems unit, matches its lesson.
## (Every exercise's validity, answers, pictures and words are the shared content test's, test_school_content.gd; the
## generators' answers are test_g5_core_gen.gd's.)

const GRADE := 5
const UNITS := {
	"maths": ["percent_intro", "angles_triangles_quads"],
	"science": ["forces_machines", "electric_systems", "reproduction_life", "breathing_heart"],
	"english": ["quote_to_prove", "many_sources", "write_opinion", "write_explain", "story_techniques", "present_speak"],
}
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## Every unit's generators are this source's ("g5c": grade 5 core).
const SOURCE := "g5c."
## Picture kinds each unit teaches with (in its lesson or its hand-written exercises).
const PICTURES := {
	"g5.maths.percent_intro": ["hundred_square", "bar_model"],
	"g5.maths.angles_triangles_quads": ["angle_facts"],
	"g5.science.forces_machines": ["force_arrows", "lever", "pulleys", "gears"],
	"g5.science.electric_systems": ["circuit_symbols", "lab_circuit"],
	"g5.science.reproduction_life": ["flower_parts", "life_cycle"],
	"g5.science.breathing_heart": ["lungs", "blood_loop"],
}
## Words the science units must not use (research §5.4 rules 4 and 5): nothing about puberty or human reproduction;
## tobacco, vaping, alcohol and other drugs only in health and PE's "Medicines and harmful substances" (as grade 5's life
## units rule, test_school_content_g5_life.gd).
const NOT_IN_REPRODUCTION: Array[String] = ["puberty", "sex", "pregnan", "womb", "sperm", "human reproduction"]
const SUBSTANCES: Array[String] = ["drug", "drugs", "alcohol", "cigarette", "cigarettes", "tobacco", "smoking", "smoker",
	"vape", "vaping", "nicotine"]


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


## Every text a unit shows: its cards, and its exercises' prompts, hints, worked answers, choices, items and matches.
func _all_text(id: String) -> String:
	var parts: Array[String] = [_lesson_text(id)]
	for ex: Dictionary in Curriculum.content(id).exercises:
		parts.append_array([str(ex.prompt), str(ex.hint), str(ex.get("explain", ""))])
		for c: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []):
			parts.append(ExerciseCheck.item_text(c))
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


## Grade 5's maths, science and English: every unit of the outline is written now (16 + 2, 13 + 4, 12 + 6).
func test_grade_5_maths_science_and_english_are_complete() -> void:
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
	gut.p("%d lesson cards and %d hand-written exercises in grade 5's new maths, science and English units" % [cards,
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


## Every unit uses "g5c", and every g5c generator is used by one of them; the maths units' generators give endless
## practice at every level.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var gens: Array = Curriculum.content(id).generators
		assert_false(gens.is_empty(), "%s has generators" % id)
		var levels := {}
		for g: Dictionary in gens:
			assert_true(str(g.gen).begins_with(SOURCE), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
			levels[int(g.level)] = true
		if id.begins_with("g5.maths."):
			assert_eq(levels.keys().size(), 3, "%s: generators at every level" % id)
	var sources := 0
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			sources += 1
			assert_true(used.has(gen), "%s is used by a grade 5 maths, science or English unit" % gen)
	assert_gte(sources, 20, "g5c has its generators")


## Every picture kind a unit is about appears in it (a hundred square, angle facts, forces, circuit symbols, …).
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


## A percentage is out of 100: the unit draws hundred squares, and an exercise's square never names its own answer (no
## label), while the lesson's may.
func test_percentages_are_drawn_on_hundred_squares() -> void:
	var id := "g5.maths.percent_intro"
	if not Curriculum.has_content(id):
		fail_test("%s is not written" % id)
		return
	var c := Curriculum.content(id)
	var squares := 0
	for x: Dictionary in (c.lesson as Array) + (c.exercises as Array):
		if x.has("picture") and str(x.picture.kind) == "hundred_square":
			squares += 1
			if x.has("prompt"):
				assert_eq(str(x.picture.get("label", "none")), "none", "%s: the square does not give the answer" % x.prompt)
	assert_gte(squares, 3, "hundred squares to read")
	for level in [1, 2, 3]:
		for s in 20:
			var ex := SchoolGen.make("g5c.percent_square", s, level)
			assert_eq(str(ex.picture.kind), "hundred_square")
			assert_eq(str(ex.picture.get("label", "none")), "none", "a generated square does not give the answer")
	assert_true(_lesson_text(id).contains("out of 100"), "per cent means out of 100")
	assert_true(_lesson_text(id).contains("gold"), "a discount in gold")


## The angle facts the unit teaches are stated in its lesson with their sums.
func test_the_angle_facts_are_taught() -> void:
	var id := "g5.maths.angles_triangles_quads"
	if not Curriculum.has_content(id):
		fail_test("%s is not written" % id)
		return
	var text := _lesson_text(id)
	for w: String in ["straight line", "180°", "360°", "vertically opposite", "triangle", "quadrilateral"]:
		assert_true(text.contains(w), "the lesson says '%s'" % w)
	var figures := {}
	for x: Dictionary in (Curriculum.content(id).lesson as Array) + (Curriculum.content(id).exercises as Array):
		if x.has("picture") and str(x.picture.kind) == "angle_facts":
			figures[str(x.picture.figure)] = true
	for f: String in ["straight", "point", "cross", "triangle", "quad"]:
		assert_true(figures.has(f), "the unit draws a %s" % f)


## Spec §23: the Lab's circuit experiment lists the electric systems unit, so its page shows TRY IT IN THE LAB and its
## lesson says what the Lab lets the child do, in the Lab's own words: close the switch, make a gap, add a second bulb,
## and both glow more dimly.
func test_the_lab_experiment_matches_the_lesson() -> void:
	var linked := 0
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		for e_id in LabExperiments.for_unit(id):
			linked += 1
			var scene: Dictionary = LabExperiments.experiment(e_id).get("scene", {})
			var text := _lesson_text(id)
			assert_true(text.contains("TRY IT IN THE LAB"), "%s: the lesson points to the Lab's %s" % [id, e_id])
			if str(scene.get("kind", "")) == "circuit":
				for w: String in ["switch", "gap", "second bulb", "dimly"]:
					assert_true(text.contains(w), "%s: the lesson says '%s' as the Lab does" % [id, w])
	assert_eq(linked, 1, "the Lab lists electric systems")


## Research §5.3: circuits are drawn with symbols, in series and in parallel.
func test_circuits_are_drawn_in_series_and_in_parallel() -> void:
	var id := "g5.science.electric_systems"
	if not Curriculum.has_content(id):
		fail_test("%s is not written" % id)
		return
	var series := 0
	var parallel := 0
	var keys := 0
	for x: Dictionary in (Curriculum.content(id).lesson as Array) + (Curriculum.content(id).exercises as Array):
		if not x.has("picture") or str(x.picture.kind) != "circuit_symbols":
			continue
		if x.picture.has("symbols"):
			keys += 1
		elif x.picture.has("branches"):
			parallel += 1
		else:
			series += 1
	assert_gte(keys, 2, "the symbols named")
	assert_gte(series, 3, "series circuits")
	assert_gte(parallel, 3, "parallel circuits")


## Speaking and presenting teaches listening (research §5.3 "listen and choose"): exercises to listen to.
func test_speaking_and_presenting_is_listened_to() -> void:
	var id := "g5.english.present_speak"
	if not Curriculum.has_content(id):
		fail_test("%s is not written" % id)
		return
	var c := Curriculum.content(id)
	var cards := (c.lesson as Array).filter(func(card: Dictionary) -> bool: return card.has("sound"))
	var exercises := (c.exercises as Array).filter(func(ex: Dictionary) -> bool: return ex.has("sound"))
	assert_gte(cards.size(), 1, "a lesson card to listen to")
	assert_gte(exercises.size(), 2, "exercises to listen to")


## Research §5.4: electricity is taught with its safety rules; reproduction is plants' and animals' only; breathing and
## the heart leave harmful substances to health and PE's own unit.
func test_safety() -> void:
	var electric := "g5.science.electric_systems"
	var life := "g5.science.reproduction_life"
	var body := "g5.science.breathing_heart"
	for id: String in [electric, life, body]:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			return
	var e := _lesson_text(electric)
	for w: String in ["socket", "water", "button batter"]:
		assert_true(e.contains(w), "electric systems: the lesson says '%s'" % w)
	var all_life := _all_text(life).to_lower()
	for w in NOT_IN_REPRODUCTION:
		assert_false(all_life.contains(w), "reproduction: nothing about %s" % w)
	for w: String in ["plant", "mammal", "amphibian", "insect", "bird", "pollen", "seed", "spore"]:
		assert_true(_lesson_text(life).to_lower().contains(w), "reproduction: the lesson teaches %s" % w)
	var all_body := _all_text(body).to_lower()
	for w in SUBSTANCES:
		assert_false(RegEx.create_from_string("\\b" + w + "\\b").search(all_body) != null,
			"breathing and the heart: '%s' is taught only in health and PE" % w)
