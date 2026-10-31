extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.6), the grade 6 core agent:
## grade 6's maths, science and English get the research's last units: the problem-solving toolkit (Singapore P6
## heuristics, Polya's four steps); skeleton and muscles, nutrition and digestion, classifying life, light travels,
## energy changes and engineering design (England KS3 and Y6, Singapore P6, NGSS MS-ETS1); and reading closely,
## writing arguments, information and narratives, research and sources, and discussing and presenting (Common Core
## RL/RI/W/SL.6). After them, every unit of grade 6's maths (18), science (17) and English (18) is written. Each unit
## teaches with a lesson of 4 to 8 cards that opens with a memory question naming an earlier grade and ends with
## something to try in the world and what comes next (research §5.3 rules 1, 7 and 8), has at least 12 hand-written
## exercises at levels 1, 2 and 3 of two kinds or more, each with a strategy hint and a worked answer, and rounds that
## fill, vary and never show a hand-written exercise twice. The facts each lesson must teach are listed below (their
## sources: docs/devlog/parts/m8-grade6-core.md); the answers the pictures show (a function machine run backwards,
## handshakes, growing patterns, shadows, reflected angles, an energy flow's parts) are worked out again here.
## (Every exercise's validity, answers, pictures, sounds and words are the shared content test's, test_school_content.gd;
## the generators' answers are test_g6_core_gen.gd's; the pictures' rules test_school_picture_g6core.gd's.)

const GRADE := 6
const UNITS := {
	"maths": ["problem_solving_toolkit"],
	"science": ["skeleton_muscles", "nutrition_digestion", "classification", "light_travels", "energy_changes",
		"engineering_design"],
	"english": ["read_closely", "write_argument", "write_informative", "write_narrative", "research_sources",
		"discuss_present"],
}
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## Every unit's generators are this source's ("g6k": grade 6 core, G6CoreGen).
const SOURCE := "g6k."
## The facts each lesson must say (research §6.6 goals; lower case).
const MUST := {
	"g6.maths.problem_solving_toolkit": ["understand", "plan", "look back", "polya", "draw a model", "work backwards",
		"systematic list", "guess and check", "pattern"],
	"g6.science.skeleton_muscles": ["206", "support", "protect", "movement", "blood cells", "marrow", "joint",
		"ligament", "tendon", "contract", "pairs", "biceps", "triceps", "calcium"],
	"g6.science.nutrition_digestion": ["carbohydrate", "protein", "fat", "vitamin", "mineral", "fibre", "water",
		"balanced diet", "enzyme", "amylase", "protease", "lipase", "small intestine", "iodine"],
	"g6.science.classification": ["vertebrate", "invertebrate", "fish", "amphibian", "reptile", "bird", "mammal",
		"kingdom", "fungi", "bacteria", "linnaeus", "species", "key"],
	"g6.science.light_travels": ["straight lines", "source", "reflect", "shadow", "opaque", "transparent",
		"translucent", "mirror", "angle of incidence", "angle of reflection", "normal", "never look", "periscope"],
	"g6.science.energy_changes": ["chemical", "electrical", "kinetic", "light", "sound", "heat", "gravitational",
		"elastic", "joules", "never made or destroyed", "wasted", "efficien"],
	"g6.science.engineering_design": ["criteria", "constraints", "prototype", "test", "decision matrix", "improve",
		"fair", "wright"],
	"g6.english.read_closely": ["evidence", "infer", "quote", "explicit", "compare", "story", "fact"],
	"g6.english.write_argument": ["claim", "reason", "evidence", "counterclaim", "formal", "conclusion"],
	"g6.english.write_informative": ["introduction", "heading", "definition", "example", "precise", "caption",
		"conclusion"],
	"g6.english.write_narrative": ["hook", "tension", "pacing", "dialogue", "vivid", "climax", "resolution"],
	"g6.english.research_sources": ["source", "reliable", "own words", "paraphrase", "plagiarism", "quote", "author"],
	"g6.english.discuss_present": ["discussion", "build on", "listen", "evidence", "chart", "eye contact", "pace"],
}
## The pictures each unit needs, over its lesson, its exercises and its generators ([kind, how many], …).
const DRAWS := {
	"g6.maths.problem_solving_toolkit": [["op_chain", 3], ["bar_model", 3], ["handshakes", 2], ["towers", 2]],
	"g6.science.skeleton_muscles": [["skeleton", 4], ["joint", 3], ["muscle_pair", 3]],
	"g6.science.nutrition_digestion": [["food_test", 3], ["enzyme_cut", 3], ["digestion", 2]],
	"g6.science.classification": [["key_tree", 3], ["kingdoms", 2], ["taxon_levels", 1], ["icon", 3]],
	"g6.science.light_travels": [["shadow_rays", 3], ["reflection", 3], ["light_device", 2]],
	"g6.science.energy_changes": [["energy_chain", 4], ["sankey", 3]],
	"g6.science.engineering_design": [["table", 3], ["life_cycle", 1], ["column_chart", 1]],
	"g6.english.read_closely": [["table", 1]],
	"g6.english.write_argument": [["argument_map", 3]],
	"g6.english.write_informative": [["info_page", 3]],
	"g6.english.write_narrative": [["story_arc", 3]],
	"g6.english.research_sources": [["table", 2]],
	"g6.english.discuss_present": [["column_chart", 1]],
}
## Units whose label exercises must exist (label the diagram), with how many.
const LABELS := {"g6.science.skeleton_muscles": 2, "g6.science.light_travels": 1, "g6.english.write_argument": 1,
	"g6.english.write_informative": 1, "g6.english.write_narrative": 1}
## The body units are taught kindly (research §5.4 rule 4; the grade 6 health test's words): no weight talk, no
## shaming about food, nothing about puberty or reproduction.
const BODY_UNITS: Array[String] = ["g6.science.skeleton_muscles", "g6.science.nutrition_digestion"]
const NOT_IN_BODY: Array[String] = ["weight", "weights", "overweight", "underweight", "skinny", "fat people", "calorie",
	"calories", "junk", "bad food", "bad foods", "dieting", "obese", "obesity"]
const NOT_ANYWHERE: Array[String] = ["puberty", "sex", "pregnant", "pregnancy", "womb", "sperm", "drug", "drugs",
	"alcohol", "ethanol", "cigarette", "tobacco", "smoking", "vape", "vaping", "nicotine", "gambling"]
const PERSONAL := "(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)"


func _ids() -> Array[String]:
	var out: Array[String] = []
	for subject: String in UNITS:
		for name: String in UNITS[subject]:
			out.append("g%d.%s.%s" % [GRADE, subject, name])
	return out


func _lesson(id: String) -> String:
	var parts: Array[String] = []
	for card: Dictionary in Curriculum.content(id).lesson:
		parts.append(str(card.get("text", "")))
	return " ".join(parts)


func _ex_texts(ex: Dictionary) -> Array[String]:
	var out: Array[String] = [str(ex.get("prompt", "")), str(ex.get("hint", "")), str(ex.get("explain", ""))]
	for t: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []) \
			+ ex.get("labels", []):
		out.append(ExerciseCheck.item_text(t))
	return out


## A unit's hand-written exercises and its generators' at every level (12 seeds each).
func _exercises(id: String, seeds: int = 12) -> Array[Dictionary]:
	var c := Curriculum.content(id)
	var out: Array[Dictionary] = []
	for ex: Dictionary in c.exercises:
		out.append(ex)
	for g: Dictionary in c.generators:
		for s in seeds:
			out.append(SchoolGen.make(str(g.gen), s, int(g.level)))
	return out


## Every text a unit shows: its cards, its exercises' and its generators'.
func _all_texts(id: String) -> String:
	var parts: Array[String] = [_lesson(id)]
	for ex in _exercises(id):
		parts.append_array(_ex_texts(ex))
	return " ".join(parts)


func _pictures(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card: Dictionary in Curriculum.content(id).lesson:
		if card.has("picture"):
			out.append(card.picture)
	for ex in _exercises(id):
		if ex.has("picture"):
			out.append(ex.picture)
		for c: Variant in ex.get("choices", []):
			if c is Dictionary and c.has("picture"):
				out.append(c.picture)
	return out


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


## Grade 6's maths, science and English: every unit of the outline is written now (17 + 1, 11 + 6, 12 + 6).
func test_grade_6_maths_science_and_english_are_complete() -> void:
	var counts := {"maths": 18, "science": 17, "english": 18}
	for subject: String in counts:
		var units := Curriculum.units(GRADE, subject)
		assert_eq(units.size(), int(counts[subject]), "grade 6 %s's units" % subject)
		for u: Dictionary in units:
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
	gut.p("%d lesson cards and %d hand-written exercises in grade 6's new maths, science and English units" % [cards,
		exercises])


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from an earlier grade, named), "Spiral" (what comes next) and
## "Do it in the world" (a challenge to try).
func test_every_lesson_starts_with_memory_and_ends_in_the_world_with_what_comes_next() -> void:
	var grade := RegEx.create_from_string("\\bgrades? [3-6]\\b")
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var lesson: Array = Curriculum.content(id).lesson
		var first := str(lesson[0].text)
		assert_true(first.begins_with("Quick memory:") and first.contains("?"), "%s: the first card asks a memory question" % id)
		assert_true(grade.search(first) != null, "%s: the memory question names the grade it recalls" % id)
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


## Every unit uses "g6k", and every g6k generator is used by one of them; the maths unit's generators give endless
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
		assert_eq(levels.keys().size(), 3, "%s: generators at every level" % id)
	var sources := 0
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			sources += 1
			assert_true(used.has(gen), "%s is used by a grade 6 maths, science or English unit" % gen)
	assert_gte(sources, 30, "g6k has its generators")


func test_every_lesson_teaches_its_facts() -> void:
	for id: String in MUST:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var text := _lesson(id).to_lower()
		for w: String in MUST[id]:
			assert_true(text.contains(w), "%s: the lesson says '%s'" % [id, w])


func test_every_unit_is_taught_with_its_pictures() -> void:
	for id: String in DRAWS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var counts := {}
		for p in _pictures(id):
			counts[str(p.kind)] = int(counts.get(str(p.kind), 0)) + 1
		for need: Array in DRAWS[id]:
			assert_gte(int(counts.get(str(need[0]), 0)), int(need[1]), "%s: %s pictures" % [id, need[0]])


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG6Core.part_at, at the label
## box's size), so the pins can be trusted; and the units that label have their label exercises.
func test_every_label_points_at_its_part() -> void:
	var checked := 0
	for id: String in LABELS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var n := 0
		for ex: Dictionary in Curriculum.content(id).exercises:
			if str(ex.type) != "label":
				continue
			n += 1
			assert_true(SchoolPictureG6Core.KINDS.has(str(ex.picture.kind)), "%s: a grade 6 core picture" % ex.id)
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part := SchoolPictureG6Core.part_at(ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
		assert_gte(n, int(LABELS[id]), "%s: label exercises" % id)
	assert_gte(checked, 16, "labels were checked")


## The maths the pictures show, worked out again with this test's own rules: a function machine run backwards gives the
## start, n people shake hands n(n − 1) ÷ 2 times, a growing pattern goes up by the same step; a shadow is as many times
## taller than the card as the screen is farther from the lamp than the card; the angle of reflection equals the angle
## of incidence (and each is 90° take away its angle to the mirror); an energy flow's parts add up to what goes in.
func test_the_pictures_answers_are_worked_out_again() -> void:
	var checked := 0
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			if str(ex.type) != "number" or not ex.has("picture"):
				continue
			var p: Dictionary = ex.picture
			var want := NAN
			match str(p.kind):
				"op_chain":
					if str(p.start) == "?":
						want = _undo(float(p.end), p.ops)
					elif str(p.end) == "?":
						want = _run(float(p.start), p.ops)
				"handshakes":
					var n := int(p.n)
					want = n * (n - 1) / 2.0
				"towers":
					var h: Array = p.heights
					var step := int(h[1]) - int(h[0])
					var nth := RegEx.create_from_string("(\\d+)(st|nd|rd|th) (tower|pattern|term)").search(str(ex.prompt))
					var k := int(nth.get_string(1)) if nth else h.size() + 1
					want = int(h[0]) + step * (k - 1)
				"shadow_rays":
					var shadow := float(p.size) * float(p.far) / float(p.near)
					match str(p.get("hide", "shadow")):
						"shadow":
							want = shadow
						"size":
							want = float(p.size)
						"near":
							want = float(p.near)
				"reflection":
					var i := float(p.i)
					match str(p.get("unknown", "")):
						"i", "r":
							want = i
						"mi", "mr":
							want = 90.0 - i
						"both":
							want = 2.0 * i
				"sankey":
					var total := float(p.total)
					var useful := 0.0
					for u: Array in p.useful:
						useful += float(u[1])
					if str(ex.prompt).to_lower().contains("efficien"):
						want = useful * 100.0 / total
					elif p.has("hide"):
						var values: Array = [total]
						for u: Array in p.useful:
							values.append(float(u[1]))
						for w: Array in p.wasted:
							values.append(float(w[1]))
						want = values[int(p.hide)]
			if is_nan(want):
				continue
			checked += 1
			assert_almost_eq(NumberAnswer.value(str(ex.answer)), want, 0.001, "%s: %s" % [ex.id, ex.prompt])
	assert_gte(checked, 12, "the pictures' answers were checked")


## A function machine's steps ("+ 5", "× 2", "− 3", "÷ 4") run forwards …
func _run(x: float, ops: Array) -> float:
	for o: Variant in ops:
		x = _apply(x, str(o), false)
	return x


## … and backwards, each step undone, last first.
func _undo(x: float, ops: Array) -> float:
	for i in range(ops.size() - 1, -1, -1):
		x = _apply(x, str(ops[i]), true)
	return x


func _apply(x: float, op: String, back: bool) -> float:
	var sign := op.substr(0, 1)
	var n := float(op.substr(1).strip_edges())
	if back:
		sign = {"+": "−", "−": "+", "×": "÷", "÷": "×"}[sign]
	match sign:
		"+":
			return x + n
		"−":
			return x - n
		"×":
			return x * n
	return x / n


## Discussing and presenting teaches listening (research §5.3 "listen and choose"): a pace and a volume to hear.
func test_speaking_is_listened_to() -> void:
	var id := "g6.english.discuss_present"
	if not Curriculum.has_content(id):
		fail_test("%s is not written" % id)
		return
	var c := Curriculum.content(id)
	var cards := (c.lesson as Array).filter(func(card: Dictionary) -> bool: return card.has("sound"))
	var exercises := (c.exercises as Array).filter(func(ex: Dictionary) -> bool: return ex.has("sound"))
	assert_gte(cards.size(), 1, "a lesson card to listen to")
	assert_gte(exercises.size(), 3, "exercises to listen to")
	var quiet := exercises.filter(func(ex: Dictionary) -> bool: return float(ex.sound.get("volume", 1.0)) < 0.5)
	assert_gte(quiet.size(), 1, "a speaker too quiet for the back of the room")


## Research §5.4: the body units are kind (no weight talk, no shaming about food); nothing about puberty, reproduction,
## drugs, alcohol, smoking or gambling in any of these units (they belong to health and PE's own units, and never to
## grade 6 science); no personal questions; light's safety (never look at the Sun).
func test_safety() -> void:
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var all := _all_texts(id).to_lower()
		for w in NOT_ANYWHERE:
			assert_null(RegEx.create_from_string("\\b" + w + "\\b").search(all), "%s: nothing about '%s'" % [id, w])
		assert_null(RegEx.create_from_string(PERSONAL).search(all), "%s: no personal questions" % id)
		if BODY_UNITS.has(id):
			for w in NOT_IN_BODY:
				assert_null(RegEx.create_from_string("\\b" + w + "\\b").search(all), "%s: no '%s'" % [id, w])
	if Curriculum.has_content("g6.science.light_travels"):
		assert_true(_lesson("g6.science.light_travels").to_lower().contains("never look straight at the sun"),
			"light: never look straight at the Sun")
