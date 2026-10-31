extends GutTest
## Owner #70, #73 and #111 ("we want to have full school programs and sylabusse content in the game"; research §6.8):
## grade 8's computing, art and design and music are written for every unit of the outline, one step up from grade 7
## (the spiral). Each unit teaches with a lesson of 4 to 8 cards that opens with a memory question and ends with
## something to try in the world and what comes next (research §5.3 rules 1, 7 and 8), has at least 12 hand-written
## exercises at levels 1, 2 and 3 of at least two kinds, each with a hint (a strategy) and a worked answer, rounds that
## vary and never show a hand-written exercise twice, and meets the School's quality bar (test_school_quality.gd's
## `bar`: two pictures, three kinds of exercise, at most 70% choice or true-or-false, real hints and worked answers).
## Every music unit lets the child listen in at least 6 exercises. Owner #112, #115 and #117 (learn by doing): a unit
## whose topic is a Life or Success Experience ends by sending the child to it by name in the LIFE tab.
## The facts are worked out again with this test's own rules and tables: every text program is run by the tests' own
## interpreter (tests/fakes/text_code_runner.gd), machine code traced, character codes, file sizes and samples, logic
## circuits and truth tables, database queries, nearest neighbours, password counts, the people's years, frames and
## seconds, grids enlarged, mobiles balanced, scales, whole-tone and blues scales, transposed notes, beats and bars, and
## every label's line to its part.
## (Every exercise's validity, answers, pictures, sounds and words are the shared content test's, test_school_content.gd.)

const Runner := preload("res://tests/fakes/text_code_runner.gd")
const Quality := preload("res://tests/unit/test_school_quality.gd")
const GRADE := 8
const SUBJECTS: Array[String] = ["computing", "art", "music"]
const UNITS := {"computing": 11, "art": 9, "music": 9}   # research §6.8
const MIN_EXERCISES := 12
const MIN_CARDS := 4
const MIN_SOUNDS := 6
const OWN_GEN := "g8c."
## Owner #112, #115 and #117: the units whose topic is a Life or Success Experience end by naming it (its title in its
## data, read through LifeExperience.data, or the Tool Book) in the LIFE tab.
const LIFE_LINKS := {
	"g8.computing.cyber_security": ["Online City"],   # owner #118 (L3c): the card names Online City now
	"g8.computing.design_for_users": ["Success Stories"],
	"g8.computing.computing_society": ["Success Stories"],
	"g8.art.designing_objects": ["Tool Book"],
	"g8.art.installation": ["Real Builder"],
	"g8.art.exhibition": ["Talk & Deal"],
	"g8.music.music_identity": ["Calm Corner"],
	"g8.music.composition_project": ["The Goal Board"],
}
const PERSONAL := "(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)"


func _units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for subject in SUBJECTS:
		out.append_array(Curriculum.units(GRADE, subject))
	return out


func _texts(id: String) -> Array[String]:
	var out: Array[String] = []
	var c := Curriculum.content(id)
	for card: Dictionary in c.lesson:
		out.append(str(card.text))
	for ex: Dictionary in c.exercises:
		out.append_array([str(ex.prompt), str(ex.hint), str(ex.get("explain", ""))])
		for it: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []):
			out.append(ExerciseCheck.item_text(it))
	return out


func _subject_texts(subject: String) -> Array[String]:
	var out: Array[String] = []
	for u in Curriculum.units(GRADE, subject):
		if Curriculum.has_content(str(u.id)):
			out.append_array(_texts(str(u.id)))
	return out


func _exercises(subject: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in Curriculum.units(GRADE, subject):
		if Curriculum.has_content(str(u.id)):
			for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
				out.append(ex)
	return out


## Every picture of a subject's lessons and exercises (and the choices' pictures).
func _pictures(subject: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in Curriculum.units(GRADE, subject):
		if not Curriculum.has_content(str(u.id)):
			continue
		var c := Curriculum.content(str(u.id))
		for card: Dictionary in c.lesson:
			if card.get("picture") is Dictionary:
				out.append(card.picture)
		for ex: Dictionary in c.exercises:
			if ex.get("picture") is Dictionary:
				out.append(ex.picture)
			for ch: Variant in ex.get("choices", []):
				if ch is Dictionary and ch.get("picture") is Dictionary:
					out.append(ch.picture)
	return out


func _right(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 8 %s" % subject)


func test_grade_8_computing_art_music_are_written_for_every_unit() -> void:
	var exercises := 0
	for u in _units():
		var id := str(u.id)
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), MIN_CARDS, Curriculum.MAX_CARDS, "%s: a lesson of 4 to 8 cards" % id)
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
					distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", "")) + str(ex.get("board", ""))] = true
					if not str(ex.id).begins_with("gen:"):
						assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
						ids[ex.id] = true
		assert_gte(distinct.size(), 12, "%s: varied practice" % id)
	gut.p("%d hand-written exercises in grade 8 computing, art and music" % exercises)


## The School's quality bar (owner #94; test_school_quality.gd holds grades 3-7 to it, and grade 8's units meet it too).
func test_every_unit_meets_the_quality_bar() -> void:
	var q: Node = Quality.new()
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(q.bar(id, str(u.id).get_slice(".", 1)), [] as Array[String], "%s is under the bar" % id)
	q.free()


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" and "Do it in the world"; the spiral: each lesson names what comes next.
func test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		assert_true(str(cards[0].text).begins_with("Quick memory:") and str(cards[0].text).contains("?"),
			"%s: the first card asks a memory question" % id)
		assert_true(str(cards[-1].text).begins_with("Try it in the world:"), "%s: the last card is something to try in the world" % id)
		assert_true(str(cards[-1].text).contains("Next"), "%s: the last card says what comes next" % id)


func test_every_music_unit_lets_you_listen() -> void:
	for u in Curriculum.units(GRADE, "music"):
		var id := str(u.id)
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var sounds := 0
		for ex: Dictionary in Curriculum.content(id).exercises:
			if ex.get("sound") is Dictionary:
				sounds += 1
		assert_gte(sounds, MIN_SOUNDS, "%s: %d exercises to listen to" % [id, sounds])


## The generators these units use are their own ("g8c"), each exists, and every one of them is used here.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with(OWN_GEN), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	assert_gt(used.size(), 20, "the units practise with generators")
	for gen in SchoolGen.ids():
		if gen.begins_with(OWN_GEN):
			assert_true(used.has(gen), "%s is used by a grade 8 computing, art or music unit" % gen)


## Research §5.4 rule 6: online safety every grade, and never ask a child for personal details.
func test_the_lessons_never_ask_for_personal_details() -> void:
	var ask := RegEx.create_from_string(PERSONAL)
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			assert_null(ask.search(str(ex.prompt).to_lower()), "%s asks: %s" % [ex.id, ex.prompt])


## Owner #112, #115 and #117: the School and Life work together. A unit whose topic is a Life or Success Experience ends
## by naming it, in the LIFE tab; each name is a real Experience's title (or the Tool Book).
func test_the_life_experiences_are_named_where_the_topic_is_one() -> void:
	var titles: Array[String] = ["Tool Book"]
	for id: String in LifeExperience.IDS:
		var d := LifeExperience.data(id)
		assert_false(d.is_empty(), "%s's data" % id)
		titles.append(str(d.get("title", "")))
	for id: String in LIFE_LINKS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var last := str((Curriculum.content(id).lesson as Array)[-1].text)
		assert_true(last.contains("LIFE"), "%s: the last card sends the child to the LIFE tab" % id)
		for name: String in LIFE_LINKS[id]:
			assert_true(titles.has(name), "%s: '%s' is a Life Experience" % [id, name])
			assert_true(last.contains(name), "%s: the last card names %s" % [id, name])


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG8Arts.part_at, at the label
## box's size).
func test_every_label_points_at_its_part() -> void:
	var checked := 0
	for subject in SUBJECTS:
		for ex in _exercises(subject):
			if str(ex.type) != "label":
				continue
			assert_true(SchoolPictureG8Arts.KINDS.has(str(ex.picture.kind)), "%s: a grade 8 arts picture" % ex.id)
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part := SchoolPictureG8Arts.part_at(ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
	assert_gte(checked, 12, "labels were checked")


# --- Computing facts -------------------------------------------------------------------------------------------------

## Every text program in a picture runs (unless its exercise asks which line stops it), printing what its output panel
## shows.
func test_every_program_runs_as_its_picture_shows() -> void:
	var checked := 0
	var asks_line := {}
	for ex in _exercises("computing"):
		if str(ex.type) == "number" and ex.get("picture") is Dictionary \
				and RegEx.create_from_string("which line").search(str(ex.prompt).to_lower()) != null:
			asks_line[str(ex.picture.lines)] = true
	for p in _pictures("computing"):
		if str(p.kind) != "text_code":
			continue
		var st := Runner.run(p.lines)
		if not asks_line.has(str(p.lines)):
			assert_eq(str(st.error), "", "%s runs (%s on line %d)" % [p.lines, st.error, st.line])
		if p.has("output"):
			assert_eq(st.out, p.output, "%s prints what the picture shows" % [p.lines])
		checked += 1
	assert_gte(checked, 6, "programs were run")


## "What does this program print?", "This program prints N." and "Which line stops it?": worked out by running it.
func test_the_programs_do_what_the_exercises_say() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "text_code":
			continue
		var st := Runner.run(pic.lines)
		var low := str(ex.prompt).to_lower()
		if str(ex.type) == "number" and low.contains("which line"):
			assert_ne(str(st.error), "", "%s: the program has a mistake" % ex.id)
			assert_eq(NumberAnswer.value(str(ex.answer)), float(st.line), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif str(ex.type) == "number" and low.contains("print"):
			assert_eq((st.out as Array).size(), 1, "%s prints one line" % ex.id)
			assert_almost_eq(NumberAnswer.value(str(ex.answer)), float(st.out[0]), 0.0001, "%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif str(ex.type) == "truefalse":
			var claim := RegEx.create_from_string("prints (.+?)\\.?$").search(str(ex.prompt))
			if claim != null:
				assert_eq(claim.get_string(1) == ", ".join(st.out), bool(ex.answer), "%s: %s" % [ex.id, ex.prompt])
				checked += 1
	assert_gte(checked, 5, "programs were run for the exercises")


## The School's little machine (LOAD n, ADD n, SUB n, OUT, HALT), this test's own: the outputs and the instructions run.
func _machine(memory: Array) -> Dictionary:
	var acc := 0
	var out: Array[int] = []
	var ran := 0
	for row: Array in memory:
		ran += 1
		var op := str(row[1]).split(" ")
		if op[0] == "LOAD":
			acc = int(op[1])
		elif op[0] == "ADD":
			acc += int(op[1])
		elif op[0] == "SUB":
			acc -= int(op[1])
		elif op[0] == "OUT":
			out.append(acc)
		elif op[0] == "HALT":
			break
	return {"out": out, "ran": ran}


func test_the_little_machine_does_what_the_exercises_say() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or str(pic.get("kind", "")) != "cpu_cycle" \
				or (pic.get("memory", []) as Array).is_empty():
			continue
		var run := _machine(pic.memory)
		var low := str(ex.prompt).to_lower()
		var v := NumberAnswer.value(str(ex.answer))
		if low.contains("how many instructions"):
			assert_eq(v, float(run.ran), "%s: %s" % [ex.id, ex.prompt])
		elif low.contains("second out"):
			assert_eq(v, float(run.out[1]), "%s: %s" % [ex.id, ex.prompt])
		else:
			assert_eq(v, float(run.out[0]), "%s: %s" % [ex.id, ex.prompt])
		checked += 1
	assert_gte(checked, 4, "machine programs were run")


## "A is 65", "small a is 97", "CAT is stored as 67, 65, 84", the codes of a word chosen, and the code tables.
func test_the_ascii_codes_are_right() -> void:
	var checked := 0
	var is_code := RegEx.create_from_string("(?:\\b([A-Za-z]) is|\\b([A-Z]) =) (\\d{2,3})\\b(?! ?[+−×÷])")
	var stored := RegEx.create_from_string("\\b([A-Z]{2,}) is stored as ((?:\\d{2,3}, )+\\d{2,3})")
	for t in _subject_texts("computing"):
		for m in is_code.search_all(t):
			var letter := m.get_string(1) if m.get_string(1) != "" else m.get_string(2)
			assert_eq(int(m.get_string(3)), letter.unicode_at(0), t)
			checked += 1
		for m in stored.search_all(t):
			var codes: Array[String] = []
			for ch in m.get_string(1):
				codes.append(str(ch.unicode_at(0)))
			assert_eq(m.get_string(2), ", ".join(codes), t)
			checked += 1
	for ex in _exercises("computing"):
		var m := RegEx.create_from_string("store the word ([A-Z]+)").search(str(ex.prompt))
		if m != null and str(ex.type) == "choice":
			var codes: Array[String] = []
			for ch in m.get_string(1):
				codes.append(str(ch.unicode_at(0)))
			assert_eq(_right(ex), ", ".join(codes), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
	for p in _pictures("computing"):
		if str(p.kind) == "table" and str(p.rows[0][0]) == "character":
			for row: Array in (p.rows as Array).slice(1):
				assert_eq(int(row[1]), str(row[0]).unicode_at(0), "the table: %s" % [row])
				assert_eq(String.num_int64(int(row[1]), 2).lpad(7, "0"), str(row[2]), "the binary: %s" % [row])
				checked += 1
	assert_gte(checked, 8, "codes were checked")


## This test's own gates.
func _gate(e: Variant, inputs: Dictionary) -> int:
	if e is String:
		return int(inputs[e])
	if str(e[0]) == "NOT":
		return 1 - _gate(e[1], inputs)
	var a := _gate(e[1], inputs)
	var b := _gate(e[2], inputs)
	return (a * b) if str(e[0]) == "AND" else mini(a + b, 1)


## Every circuit asked about: "Will the lamp light?", "What is the output?" and "The lamp lights."
func test_the_circuits_light_right() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "gate_circuit":
			continue
		var v := _gate(pic.expr, pic.inputs)
		match str(ex.type):
			"choice":
				var right := _right(ex)
				if right.begins_with("yes") or right.begins_with("no"):
					assert_eq(right.begins_with("yes"), v == 1, "%s: %s" % [ex.id, pic.expr])
				else:
					assert_eq(right, str(v), "%s: %s" % [ex.id, pic.expr])
			"truefalse":
				assert_eq(bool(ex.answer), v == 1, "%s: %s" % [ex.id, pic.expr])
		checked += 1
	for p in _pictures("computing"):
		if str(p.kind) == "table" and (p.rows[0] as Array).size() == 3 and str(p.rows[0][2]).contains("AND"):
			for row: Array in (p.rows as Array).slice(1):
				assert_eq(int(row[2]), int(row[0]) * int(row[1]), "the truth table: %s" % [row])
				checked += 1
	assert_gte(checked, 8, "circuits were checked")


## This test's own WHERE (on a db_table picture): "f = 'x'", "f > n", "f < n", or two joined by AND or OR.
func _where(p: Dictionary, row: Array, cond: String) -> bool:
	if cond.contains(" AND "):
		return _where(p, row, cond.get_slice(" AND ", 0)) and _where(p, row, cond.get_slice(" AND ", 1))
	if cond.contains(" OR "):
		return _where(p, row, cond.get_slice(" OR ", 0)) or _where(p, row, cond.get_slice(" OR ", 1))
	var w := cond.split(" ", false, 2)
	var v: Variant = row[(p.fields as Array).find(w[0])]
	match w[1]:
		"=":
			return str(v) == w[2].replace("'", "")
		">":
			return float(v) > float(w[2])
	return float(v) < float(w[2])


func test_the_queries_find_the_right_records() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "db_table" or not pic.has("query"):
			continue
		var cond := str(pic.query).get_slice(" WHERE ", 1)
		var found: Array[String] = []
		for row: Array in pic.rows:
			if _where(pic, row, cond):
				found.append(str(row[1] if (pic.fields as Array).has("name") else row[0]))
		if str(ex.type) == "number":
			assert_eq(NumberAnswer.value(str(ex.answer)), float(found.size()), "%s: %s" % [ex.id, pic.query])
		elif str(ex.type) == "choice":
			assert_eq(_right(ex), " and ".join(found), "%s: %s" % [ex.id, pic.query])
		checked += 1
	assert_gte(checked, 5, "queries were run")


## The new example's label by its nearest examples (the ringed ones vote).
func test_the_nearest_examples_vote_right() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "scatter_learn" \
				or not pic.has("new"):
			continue
		var k := int(pic.get("near", 1))
		var near := SchoolPictureG8Arts.nearest(pic.points, float(pic.new[0]), float(pic.new[1]), k)
		var votes := [0, 0]
		for i in near:
			votes[int(pic.points[i][2])] += 1
		assert_eq(_right(ex), str(pic.groups[0 if votes[0] > votes[1] else 1]), "%s: %s" % [ex.id, ex.prompt])
		checked += 1
	assert_gte(checked, 2, "nearest examples were checked")


## "How many stops is it from Hill to Station?": the railway's own lines, by this test's breadth-first count.
func test_the_stops_are_counted_right() -> void:
	var lines := [["Hill", "Park", "Market", "Station", "Harbour"], ["School", "Market", "Castle"]]
	var stops := func(a: String, b: String) -> int:
		var dist := {a: 0}
		var queue: Array = [a]
		while not queue.is_empty():
			var s: String = queue.pop_front()
			for line: Array in lines:
				var i := line.find(s)
				for j: int in [i - 1, i + 1]:
					if i >= 0 and j >= 0 and j < line.size() and not dist.has(line[j]):
						dist[line[j]] = int(dist[s]) + 1
						queue.append(line[j])
		return int(dist.get(b, -1))
	var rule := RegEx.create_from_string("from (\\w+) to (\\w+)")
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or str(pic.get("kind", "")) != "abstract_map":
			continue
		var m := rule.search(str(ex.prompt))
		assert_not_null(m, "%s names two stops" % ex.id)
		if m != null:
			assert_eq(NumberAnswer.value(str(ex.answer)), float(stops.call(m.get_string(1), m.get_string(2))), str(ex.prompt))
			checked += 1
	assert_gte(checked, 3, "journeys were counted")


# --- People ------------------------------------------------------------------------------------------------------------

## The people of the past the units name, with their years (this test's own; every "Name (born-died)" agrees). No
## living person is named: each has the year they died.
const PEOPLE := {"Neumann": [1903, 1957], "Beck": [1902, 1974], "Shannon": [1916, 2001], "Braille": [1809, 1852],
	"Johnson": [1918, 2020], "Monet": [1840, 1926], "Morisot": [1841, 1895], "Pissarro": [1830, 1903],
	"Seurat": [1859, 1891], "Matisse": [1869, 1954], "Picasso": [1881, 1973], "Braque": [1882, 1963], "Dali": [1904, 1989],
	"Magritte": [1898, 1967], "Warhol": [1928, 1987], "Lichtenstein": [1923, 1997], "Amaral": [1886, 1973],
	"Sher-Gil": [1913, 1941], "al-Haytham": [965, 1040], "Dürer": [1471, 1528], "Rembrandt": [1606, 1669],
	"Kahlo": [1907, 1954], "Rivera": [1886, 1957], "Sullivan": [1856, 1924], "Breuer": [1902, 1981],
	"Yanagi": [1915, 2011], "Reiniger": [1899, 1981], "Hepworth": [1903, 1975], "Moore": [1898, 1986],
	"Bourgeois": [1911, 2010], "Calder": [1898, 1976], "Chopin": [1810, 1849], "Tchaikovsky": [1840, 1893],
	"Smetana": [1824, 1884], "Mendelssohn": [1805, 1847], "Schumann": [1819, 1896], "Debussy": [1862, 1918],
	"Armstrong": [1901, 1971], "Schoenberg": [1874, 1951], "Fitzgerald": [1917, 1996], "Marley": [1945, 1981],
	"Verdi": [1813, 1901]}


func test_the_peoples_years_are_right() -> void:
	var names := "|".join(PackedStringArray(PEOPLE.keys()))
	var rule := RegEx.create_from_string("\\b(" + names + ") \\((?:about )?(\\d{3,4})-(\\d{4})\\)")
	var any := RegEx.create_from_string("([A-Za-zü][A-Za-zü-]*) \\((?:about )?\\d{3,4}-\\d{4}\\)")
	var checked := 0
	for subject in SUBJECTS:
		for t in _subject_texts(subject):
			for m in rule.search_all(t):
				assert_eq([int(m.get_string(2)), int(m.get_string(3))], PEOPLE[m.get_string(1)], t)
				checked += 1
			for m in any.search_all(t):
				assert_true(PEOPLE.has(m.get_string(1)), "%s is a person this test knows: %s" % [m.get_string(1), t])
		for p in _pictures(subject):
			if str(p.kind) != "lifespans":
				continue
			for row: Array in p.people:
				var who := str(row[0]).get_slice(" ", str(row[0]).get_slice_count(" ") - 1)
				assert_true(PEOPLE.has(who), "the lifespans picture: %s" % [row])
				if PEOPLE.has(who):
					assert_eq([int(row[1]), int(row[2])], PEOPLE[who], "the lifespans picture: %s" % [row])
					checked += 1
	assert_gte(checked, 40, "the years were checked")


# --- Art facts ---------------------------------------------------------------------------------------------------------

const WHEEL: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red", "red-purple", "purple",
	"blue-purple", "blue", "blue-green", "green", "yellow-green"]


## "Blue and orange are complementary": opposite on the 12-colour wheel.
func test_the_complementary_colours_are_opposite() -> void:
	var rule := RegEx.create_from_string("(?i)\\b(yellow|orange|red|purple|blue|green) and (yellow|orange|red|purple|blue|green) are complementary")
	var checked := 0
	for t in _subject_texts("art"):
		for m in rule.search_all(t):
			assert_eq(posmod(WHEEL.find(m.get_string(2).to_lower()) - WHEEL.find(m.get_string(1).to_lower()), 12), 6, t)
			checked += 1
	assert_gte(checked, 1, "complementary colours were checked")


## A mobile: weight × distance on each side (this test's own sums): the hidden weight that balances it, and which way a
## still arm tips.
func test_the_mobiles_balance() -> void:
	var checked := 0
	for ex in _exercises("art"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "mobile_balance":
			continue
		var sums := {"left": 0, "right": 0}
		for side: String in ["left", "right"]:
			for wd: Array in pic[side]:
				sums[side] += int(wd[0]) * int(wd[1])
		if str(ex.type) == "number":
			var hidden: Array = pic[str(pic.hide[0])][int(pic.hide[1])]
			assert_eq(int(sums.left), int(sums.right), "%s balances" % ex.id)
			assert_eq(NumberAnswer.value(str(ex.answer)), float(hidden[0]), "%s: the hidden weight" % ex.id)
		else:
			var want := "left side down" if sums.left > sums.right else ("right side down" if sums.right > sums.left
				else "it balances")
			assert_eq(_right(ex), want, "%s: %s" % [ex.id, pic])
		checked += 1
	assert_gte(checked, 4, "mobiles were checked")


## The mural's squares left to paint, the gallery's visitors' path, and a label's medium.
func test_the_grids_plans_and_labels() -> void:
	var checked := 0
	for ex in _exercises("art"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary:
			continue
		var low := str(ex.prompt).to_lower()
		match str(pic.get("kind", "")):
			"grid_enlarge":
				if low.contains("left to paint"):
					var all := (pic.rows as Array).size() * str(pic.rows[0]).length()
					assert_eq(NumberAnswer.value(str(ex.answer)), float(all - int(pic.done)), str(ex.id))
					checked += 1
			"gallery_plan":
				if low.contains("second"):
					assert_eq(_right(ex), str(pic.works[int(pic.path[1])][0]), str(ex.id))
					checked += 1
			"wall_label":
				if low.contains("medium"):
					assert_eq(_right(ex).to_lower(), str(pic.medium).to_lower(), str(ex.id))
					checked += 1
	assert_gte(checked, 3, "grids, plans and labels were checked")


# --- Music facts -------------------------------------------------------------------------------------------------------

const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
## Ranges as the notes sound (this test's own), the lowest and highest pitch (C4 = 48).
const RANGE := {"flute": [48, 84], "clarinet": [38, 83], "trumpet": [40, 71], "trombone": [28, 65], "tuba": [14, 53],
	"violin": [43, 93], "viola": [36, 76], "cello": [24, 69], "double bass": [16, 55], "soprano": [48, 69],
	"alto": [41, 62], "tenor": [36, 57], "bass": [28, 52]}


func _pitch(note: String) -> int:
	var n := note.split(":")[0]
	var s := int(SEMIS[n.left(1)])
	if n.contains("#"):
		s += 1
	elif n.length() > 2 and n[1] == "b":
		s -= 1
	return 12 * int(n.right(1)) + s


## A tune's notes, with no rests or chords (for scales and melodies).
func _melody(sound: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for n: Variant in sound.notes:
		var s := str(n).split(":")[0]
		if s.begins_with("-") or s.contains("+"):
			continue
		out.append(_pitch(s))
	return out


## Which instruments can play a note, on the ranges chart.
func test_the_ranges_are_read_right() -> void:
	var checked := 0
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "choice" or not pic is Dictionary or str(pic.get("kind", "")) != "instrument_ranges":
			continue
		var p := _pitch(str(pic.note))
		var cannot := str(ex.prompt).contains("cannot")
		for i in (ex.choices as Array).size():
			var name := str(ex.choices[i]).trim_prefix("the ")
			var can: bool = p >= int(RANGE[name][0]) and p <= int(RANGE[name][1])
			assert_eq(can, (i == int(ex.answer)) != cannot, "%s: %s" % [ex.id, name])
		checked += 1
	assert_gte(checked, 2, "ranges were checked")


## Notes read on a stave: the tune heard matches (or not), which note is wrong, the beats, the leaps; and the sharp or
## flat a key signature makes.
func test_the_notes_are_read_right() -> void:
	var beats := {"semibreve": 4.0, "dotted minim": 3.0, "minim": 2.0, "crotchet": 1.0, "quaver": 0.5}
	var checked := 0
	for ex in _exercises("music"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary:
			continue
		var low := str(ex.prompt).to_lower()
		if str(pic.kind) == "stave":
			var written: Array[int] = []
			for n: Variant in pic.notes:
				written.append(_pitch(str(n)))
			if ex.get("sound") is Dictionary:
				var heard := _melody(ex.sound)
				if str(ex.type) == "truefalse":
					assert_eq(heard == written, bool(ex.answer), "%s: %s" % [ex.id, ex.prompt])
				elif low.contains("played wrong"):
					var wrong := -1
					for i in written.size():
						if heard[i] != written[i] and wrong < 0:
							wrong = i
					var ordinals: Array[String] = ["first", "second", "third", "fourth", "fifth"]
					assert_true(_right(ex).contains(ordinals[wrong]) or (wrong == written.size() - 1 and _right(ex).contains("last")),
						"%s: note %d is wrong" % [ex.id, wrong + 1])
				checked += 1
			elif low.contains("how many beats"):
				var total := 0.0
				for v: Variant in pic.get("values", []):
					total += float(beats[str(v)])
				if low.contains("bars"):
					assert_almost_eq(NumberAnswer.value(str(ex.answer)), total, 0.001, str(ex.id))
				else:
					assert_almost_eq(NumberAnswer.value(str(ex.answer)), total, 0.001, str(ex.id))
				checked += 1
			elif low.contains("leaps"):
				var leaps := 0
				for i in range(1, written.size()):
					var a := "CDEFGAB".find(str(pic.notes[i - 1]).left(1)) + 7 * int(str(pic.notes[i - 1]).right(1))
					var b := "CDEFGAB".find(str(pic.notes[i]).left(1)) + 7 * int(str(pic.notes[i]).right(1))
					if absi(b - a) > 1:
						leaps += 1
				assert_eq(NumberAnswer.value(str(ex.answer)), float(leaps), str(ex.id))
				checked += 1
		elif str(pic.kind) == "key_signature" and str(ex.type) == "choice":
			assert_eq(_right(ex), {"G": "F", "F": "B"}[str(pic.key)], "%s: the note the key changes" % ex.id)
			checked += 1
	assert_gte(checked, 8, "notes were read")


## Scales heard: whole-tone (every step a tone), major (tone, tone, semitone, tone, tone, tone, semitone), the blues scale
## (the root, a minor third, a fourth, a sharpened fourth, a fifth and a minor seventh), and how many notes a tune uses.
func test_the_scales_heard_are_named_right() -> void:
	var checked := 0
	for ex in _exercises("music"):
		if not ex.get("sound") is Dictionary or str(ex.sound.kind) != "notes":
			continue
		var right := _right(ex).to_lower() if str(ex.type) == "choice" else ""
		var mel := _melody(ex.sound)
		var steps: Array[int] = []
		for i in range(1, mel.size()):
			steps.append(mel[i] - mel[i - 1])
		if right.begins_with("a whole-tone scale") or right.begins_with("a major scale"):
			if right.contains("whole-tone"):
				assert_eq(steps, [2, 2, 2, 2, 2, 2] as Array[int], "%s: a whole-tone scale" % ex.id)
			else:
				assert_eq(steps, [2, 2, 1, 2, 2, 2, 1] as Array[int], "%s: a major scale" % ex.id)
			checked += 1
		elif right.contains("blues scale"):
			var classes := {}
			for p in mel:
				classes[posmod(p - mel[0], 12)] = true
			var keys: Array = classes.keys()
			keys.sort()
			assert_eq(keys, [0, 3, 5, 6, 7, 10], "%s: the blues scale" % ex.id)
			checked += 1
		elif str(ex.type) == "number" and str(ex.prompt).to_lower().contains("different notes"):
			var classes := {}
			for p in mel:
				classes[posmod(p, 12)] = true
			assert_eq(NumberAnswer.value(str(ex.answer)), float(classes.size()), str(ex.id))
			checked += 1
	assert_gte(checked, 4, "scales were heard")


## Textures heard: no parts is monophonic; a part of chords is homophonic; a part of single notes is polyphonic. And
## swing: long-short pairs.
func test_the_textures_and_swing_heard_are_named_right() -> void:
	var checked := 0
	for ex in _exercises("music"):
		if str(ex.type) != "choice" or not ex.get("sound") is Dictionary or str(ex.sound.kind) != "notes":
			continue
		var right := _right(ex)
		var parts: Array = ex.sound.get("parts", [])
		if right.contains("phonic"):
			var kind := "monophonic"
			if not parts.is_empty():
				kind = "homophonic" if str(parts[0].notes[0]).contains("+") else "polyphonic"
			assert_true(right.begins_with(kind), "%s: %s" % [ex.id, right])
			checked += 1
		elif right.begins_with("swung") or right.begins_with("straight"):
			var n: Array = ex.sound.notes
			assert_eq(right.begins_with("swung"), str(n[0]).ends_with(":2") and not str(n[1]).contains(":"), str(ex.id))
			checked += 1
	assert_gte(checked, 5, "textures and swing were heard")


## Loops of different lengths start together again after their lowest common multiple of beats.
func test_the_loops_meet_again_when_the_lessons_say() -> void:
	var nums := RegEx.create_from_string("(\\d+)(?=[- ](?:beat|and))")
	var checked := 0
	for ex in _exercises("music"):
		var low := str(ex.prompt).to_lower()
		if str(ex.type) != "number" or not (low.contains("together again") or low.contains("line up again")):
			continue
		var l := 1
		for m in nums.search_all(str(ex.prompt)):
			var v := int(m.get_string(1))
			var a := l
			var b := v
			while b != 0:
				var t := a % b
				a = b
				b = t
			l = l * v / a
		assert_eq(NumberAnswer.value(str(ex.answer)), float(l), str(ex.prompt))
		checked += 1
	assert_gte(checked, 3, "loops were counted")
