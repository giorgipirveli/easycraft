extends GutTest
## Owner #70 and #73 ("start from grade 3 and finish all grades accordingly"; research §6.6): grade 6's computing, art
## and design and music are written for every unit of the outline, building on grades 3, 4 and 5. Each unit teaches with
## a lesson of 4 or more cards that opens with a memory question and ends with something to try in the world (research
## §5.3 rules 1 and 8), has at least 12 hand-written exercises at levels 1, 2 and 3 of at least two kinds, each with a
## hint (a strategy) and a worked answer, and rounds that vary and never show a hand-written exercise twice. The music
## units that teach listening let the child listen (a tune, chords, claps, SchoolSound) in at least 6 exercises each.
## The facts the lessons state are checked where a test can work them out (this test's own tables and rules): binary
## numbers, colours of light, logic gates and truth tables, what a program outputs, a spreadsheet's formulas, the angles
## of tessellating shapes and rotating patterns, major scales and key signatures, intervals by their letters and by
## ear, the blues scale, chords, the composers' years, frequencies in hertz, and every label's line to its part.
## (Every exercise's validity, answers, pictures and words are the shared content test's, test_school_content.gd.)

const GRADE := 6
const SUBJECTS: Array[String] = ["computing", "art", "music"]
const UNITS := {"computing": 11, "art": 9, "music": 9}   # research §6.6
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## Music units that teach listening, and the sounds they must use: "rhythm" (claps), "notes" (a tune or chords) or "any".
## early_music and instruments_world are taught in words, pictures and a few sounds.
const LISTENING := {"g6.music.scales_keys": "notes", "g6.music.intervals": "notes", "g6.music.blues": "notes",
	"g6.music.syncopation": "rhythm", "g6.music.theme_variations": "notes", "g6.music.keyboard_skills": "notes",
	"g6.music.sound_science": "notes"}
const MIN_SOUNDS := 6
## Semitones above C of each letter (this test's own).
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const LETTERS := "CDEFGAB"
const MAJOR_SCALE: Array[int] = [2, 2, 1, 2, 2, 2, 1]
const MINOR_SCALE: Array[int] = [2, 1, 2, 2, 1, 2, 2]
## The key signatures (this test's own): a major key's sharps or flats, in the order they are written.
const KEY_SIGNATURES := {"C": [], "G": ["F#"], "D": ["F#", "C#"], "A": ["F#", "C#", "G#"], "F": ["Bb"],
	"Bb": ["Bb", "Eb"]}
const INTERVALS: Array[String] = ["unison", "second", "third", "fourth", "fifth", "sixth", "seventh", "octave"]
const BLUES_SCALE: Array[int] = [0, 3, 5, 6, 7, 10]
## Composers and musicians of the past (this test's own; every "Name (born-died)" and lifespans picture agrees).
const PEOPLE := {"Hildegard": [1098, 1179], "Tallis": [1505, 1585], "Palestrina": [1525, 1594], "Byrd": [1540, 1623],
	"Monteverdi": [1567, 1643], "Joplin": [1868, 1917], "Handy": [1873, 1958], "Smith": [1894, 1937],
	"Haydn": [1732, 1809], "Mozart": [1756, 1791], "Beethoven": [1770, 1827], "Brahms": [1833, 1897],
	"Elgar": [1857, 1934], "Bach": [1685, 1750], "Handel": [1685, 1759], "Vivaldi": [1678, 1741],
	"Hokusai": [1760, 1849], "Escher": [1898, 1972], "Munch": [1863, 1944], "Picasso": [1881, 1973],
	"Bruegel": [1525, 1569], "Vermeer": [1632, 1675], "Kahlo": [1907, 1954], "Smithson": [1938, 1973]}
## Colours of light (this test's own): each channel off (0) or full (255).
const LIGHT := {"000": "black", "100": "red", "010": "green", "001": "blue", "110": "yellow", "011": "cyan",
	"101": "magenta", "111": "white"}
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


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject in SUBJECTS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 6 %s" % subject)


func test_grade_6_computing_art_music_are_written_for_every_unit() -> void:
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
	gut.p("%d hand-written exercises in grade 6 computing, art and music" % exercises)


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from earlier) and "Do it in the world" (a challenge to try);
## the spiral: each lesson names what comes next.
func test_every_lesson_starts_with_a_memory_question_and_ends_in_the_world() -> void:
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var cards: Array = Curriculum.content(id).lesson
		assert_true(str(cards[0].text).contains("?"), "%s: the first card asks a memory question" % id)
		assert_true(str(cards[-1].text).to_lower().contains("world"), "%s: the last card is something to try in the world" % id)
		assert_true(str(cards[-1].text).contains("Next"), "%s: the last card says what comes next" % id)


func test_the_music_units_let_you_listen() -> void:
	for id: String in LISTENING:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var sounds := 0
		for ex: Dictionary in Curriculum.content(id).exercises:
			if ex.get("sound") is Dictionary and (LISTENING[id] == "any" or str(ex.sound.kind) == LISTENING[id]):
				sounds += 1
		assert_gte(sounds, MIN_SOUNDS, "%s: %d exercises to listen to" % [id, sounds])


## The generators these units use are their own ("g6c"), each exists, and every one of them is used here.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for g: Dictionary in Curriculum.content(id).generators:
			assert_true(str(g.gen).begins_with("g6c."), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
	assert_gt(used.size(), 0, "the units practise with generators")
	for gen in SchoolGen.ids():
		if gen.begins_with("g6c."):
			assert_true(used.has(gen), "%s is used by a grade 6 computing, art or music unit" % gen)


## Research §5.4 rule 6: online safety every grade, and never ask a child for personal details.
func test_the_lessons_never_ask_for_personal_details() -> void:
	var ask := RegEx.create_from_string(PERSONAL)
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			assert_null(ask.search(str(ex.prompt).to_lower()), "%s asks: %s" % [ex.id, ex.prompt])


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG6Arts.part_at, at the
## label box's size), so the pins can be trusted.
func test_every_label_points_at_its_part() -> void:
	var checked := 0
	for subject in SUBJECTS:
		for ex in _exercises(subject):
			if str(ex.type) != "label" or not SchoolPictureG6Arts.KINDS.has(str(ex.picture.kind)):
				continue
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part := SchoolPictureG6Arts.part_at(ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
	assert_gte(checked, 12, "labels were checked")


# --- Computing facts -------------------------------------------------------------------------------------------------

func _binary(bits: String) -> int:
	var n := 0
	for ch in bits:
		n = n * 2 + (1 if ch == "1" else 0)
	return n


## Every "10110 in binary is 22" and "22 is 10110 in binary" the lessons state, and every "what number do the cards
## show", by place values that double (1, 2, 4, 8, 16 …).
func test_the_binary_numbers_are_right() -> void:
	var checked := 0
	var is_value := RegEx.create_from_string("\\b([01]{2,8}) in binary is (\\d+)\\b")
	var in_binary := RegEx.create_from_string("\\b(\\d+) (?:is|in binary is) ([01]{2,8})(?: in binary)?\\b")
	for t in _subject_texts("computing"):
		for m in is_value.search_all(t):
			assert_eq(_binary(m.get_string(1)), int(m.get_string(2)), t)
			checked += 1
		for m in in_binary.search_all(t):
			if not t.substr(m.get_start(), m.get_end() - m.get_start() + 10).contains("binary"):
				continue
			if m.get_string(1).length() > 3 or int(m.get_string(1)) > 255:
				continue
			assert_eq(_binary(m.get_string(2)), int(m.get_string(1)), t)
			checked += 1
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) == "number" and pic is Dictionary and str(pic.get("kind", "")) == "bit_cards":
			assert_eq(NumberAnswer.value(str(ex.answer)), float(_binary(str(pic.bits))), "%s: %s" % [ex.id, pic.bits])
			checked += 1
	assert_gte(checked, 10, "binary numbers were checked")


## "(255, 255, 0) makes yellow": the colours of light add (red and green light make yellow), checked for channels that
## are off or full; and every rgb_mix picture a choice names.
func test_the_colours_of_light_are_right() -> void:
	var rule := RegEx.create_from_string("\\((\\d{1,3}), (\\d{1,3}), (\\d{1,3})\\) (?:is|makes|gives|shows) (black|red|green|blue|yellow|cyan|magenta|white)\\b")
	var checked := 0
	for t in _subject_texts("computing"):
		for m in rule.search_all(t):
			var key := ""
			var pure := true
			for k in [1, 2, 3]:
				var v := int(m.get_string(k))
				pure = pure and (v == 0 or v == 255)
				key += "1" if v == 255 else "0"
			if pure:
				assert_eq(LIGHT[key], m.get_string(4), t)
				checked += 1
	assert_gte(checked, 4, "colours of light were checked")


func _gate(gate: String, inputs: Array) -> int:
	match gate:
		"AND":
			return 1 if int(inputs[0]) == 1 and int(inputs[1]) == 1 else 0
		"OR":
			return 1 if int(inputs[0]) == 1 or int(inputs[1]) == 1 else 0
	return 1 - int(inputs[0])


## Every logic gate's output asked about, and every truth table's rows (A, B and "A AND B", "A OR B", "NOT A").
func test_the_logic_is_right() -> void:
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary:
			continue
		if str(pic.kind) == "logic_gate" and str(ex.type) == "number":
			var out := _gate(str(pic.gate), pic.inputs)
			if str(pic.get("then", "")) == "NOT":
				out = 1 - out
			assert_eq(NumberAnswer.value(str(ex.answer)), float(out), "%s: %s" % [ex.id, pic])
			checked += 1
	for subject in ["computing"]:
		for p in _pictures(subject):
			if str(p.kind) != "table":
				continue
			var head: Array = p.rows[0]
			var op := str(head[-1])
			if not (op.contains(" AND ") or op.contains(" OR ") or op.begins_with("NOT ")):
				continue
			for r in range(1, (p.rows as Array).size()):
				var row: Array = p.rows[r]
				if str(row[-1]) == "?":
					continue
				var ins: Array = []
				for c in row.size() - 1:
					ins.append(1 if str(row[c]) in ["1", "TRUE"] else 0)
				var gate := "NOT" if op.begins_with("NOT ") else ("AND" if op.contains(" AND ") else "OR")
				var want := _gate(gate, ins)
				assert_eq(1 if str(row[-1]) in ["1", "TRUE"] else 0, want, "the truth table %s, row %s" % [op, row])
				checked += 1
	assert_gte(checked, 8, "gates and truth tables were checked")


# A small interpreter for the code pictures' pseudocode (this test's own): SET v TO expression, CHANGE v BY n,
# REPEAT n TIMES, REPEAT UNTIL condition, IF condition (with ELSE), OUTPUT expression. Expressions: whole numbers, text
# in quotes, TRUE and FALSE, variables, a + b, a - b, a * b; conditions: a > b, a < b, a = b, a ≥ b, a ≤ b, joined by
# AND or OR, and NOT.

func _run(lines: Array) -> Dictionary:
	var st := {"vars": {}, "out": [], "steps": 0}
	var top: Array[int] = []
	for i in lines.size():
		if _depth(str(lines[i])) == 0:
			top.append(i)
	_block(lines, top, st)
	return st


func _depth(line: String) -> int:
	return int((line.length() - line.lstrip(" ").length()) / 2.0)


func _inner(lines: Array, at: int) -> Array[int]:
	var out: Array[int] = []
	var d := _depth(str(lines[at]))
	for j in range(at + 1, lines.size()):
		if _depth(str(lines[j])) <= d:
			break
		if _depth(str(lines[j])) == d + 1:
			out.append(j)
	return out


func _block(lines: Array, which: Array[int], st: Dictionary) -> void:
	var k := 0
	while k < which.size():
		st.steps = int(st.steps) + 1
		if int(st.steps) > 5000:
			return
		var i := which[k]
		var t := str(lines[i]).strip_edges()
		if t.begins_with("SET "):
			var name := t.substr(4, t.find(" TO ") - 4)
			st.vars[name] = _value(t.substr(t.find(" TO ") + 4), st.vars)
		elif t.begins_with("CHANGE "):
			var parts := t.split(" ")
			st.vars[parts[1]] = int(st.vars.get(parts[1], 0)) + int(_value(parts[3], st.vars))
		elif t.begins_with("REPEAT UNTIL "):
			var guard := 0
			while not _cond(t.substr(13), st.vars) and guard < 100:
				_block(lines, _inner(lines, i), st)
				guard += 1
		elif t.begins_with("REPEAT "):
			for n in int(t.get_slice(" ", 1)):
				_block(lines, _inner(lines, i), st)
		elif t.begins_with("IF "):
			var has_else := k + 1 < which.size() and str(lines[which[k + 1]]).strip_edges() == "ELSE"
			if _cond(t.substr(3), st.vars):
				_block(lines, _inner(lines, i), st)
			elif has_else:
				_block(lines, _inner(lines, which[k + 1]), st)
			if has_else:
				k += 1
		elif t.begins_with("OUTPUT "):
			(st.out as Array).append(str(_value(t.substr(7), st.vars)))
		k += 1


func _value(e: String, vars: Dictionary) -> Variant:
	e = e.strip_edges()
	for op in [" + ", " - ", " * "]:
		var at := e.rfind(op)
		if at > 0 and not e.begins_with("\""):
			var a: Variant = _value(e.substr(0, at), vars)
			var b: Variant = _value(e.substr(at + 3), vars)
			if op == " + ":
				return str(a) + str(b) if (a is String or b is String) else int(a) + int(b)
			return int(a) - int(b) if op == " - " else int(a) * int(b)
	if e.begins_with("\"") and e.ends_with("\""):
		return e.substr(1, e.length() - 2)
	if e == "TRUE" or e == "FALSE":
		return e == "TRUE"
	if e.is_valid_int():
		return int(e)
	return vars.get(e, 0)


func _cond(c: String, vars: Dictionary) -> bool:
	c = c.strip_edges()
	if c.begins_with("(") and c.ends_with(")") and c.count("(") == 1:
		c = c.substr(1, c.length() - 2)
	if c.contains(" OR "):
		return _cond(c.substr(0, c.find(" OR ")), vars) or _cond(c.substr(c.find(" OR ") + 4), vars)
	if c.contains(" AND "):
		return _cond(c.substr(0, c.find(" AND ")), vars) and _cond(c.substr(c.find(" AND ") + 5), vars)
	if c.begins_with("NOT "):
		return not _cond(c.substr(4), vars)
	for op in [" ≥ ", " ≤ ", " > ", " < ", " = "]:
		if c.contains(op):
			var a: Variant = _value(c.substr(0, c.find(op)), vars)
			var b: Variant = _value(c.substr(c.find(op) + 3), vars)
			match op:
				" ≥ ":
					return int(a) >= int(b)
				" ≤ ":
					return int(a) <= int(b)
				" > ":
					return int(a) > int(b)
				" < ":
					return int(a) < int(b)
			return str(a) == str(b)
	var v: Variant = _value(c, vars)
	return v is bool and v


func test_the_interpreter_runs_pseudocode() -> void:
	var st := _run(["SET total TO 0", "SET n TO 1", "REPEAT UNTIL n > 4", "  SET total TO total + n", "  CHANGE n BY 1",
		"IF total > 9 AND NOT (n = 3)", "  OUTPUT \"big\"", "ELSE", "  OUTPUT total"])
	assert_eq(st.vars.total, 10)
	assert_eq(st.out, ["big"])
	assert_eq(_run(["SET a TO \"5\"", "SET b TO \"5\"", "OUTPUT a + b"]).out, ["55"], "text joins")
	assert_eq(_run(["SET a TO 5", "SET b TO 5", "OUTPUT a + b"]).out, ["10"], "numbers add")


## "What does the program output?" and "What is x when the program ends?" about a code picture: worked out by running it.
func test_the_programs_do_what_the_lessons_say() -> void:
	var checked := 0
	var ends := RegEx.create_from_string("what is (\\w+) when (?:the program|it) ends")
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if not pic is Dictionary or str(pic.get("kind", "")) != "code" or pic.has("mark"):
			continue
		var low := str(ex.prompt).to_lower()
		var st := _run(pic.lines)
		var m := ends.search(low)
		if str(ex.type) == "number" and m != null:
			assert_eq(NumberAnswer.value(str(ex.answer)), float(st.vars.get(m.get_string(1), NAN)), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif low.contains("output") and (st.out as Array).size() > 0:
			var said := ", ".join(st.out)
			if str(ex.type) == "number":
				assert_eq(str(NumberAnswer.value(str(ex.answer))), str(float(said)) if said.is_valid_float() else said,
					"%s: %s" % [ex.id, ex.prompt])
				checked += 1
			elif str(ex.type) == "choice":
				assert_eq(ExerciseCheck.item_text(ex.choices[int(ex.answer)]).replace("\"", ""), said, "%s: %s" % [ex.id, ex.prompt])
				checked += 1
	assert_gte(checked, 8, "programs were run")


## A cell's value in a spreadsheet picture (this test's own): a number, =SUM(B2:B5), =MAX(…), =MIN(…), =AVERAGE(…),
## or =B2+C2, =B2-C2, =B2*C2, =B2/C2 with cells or numbers.
func _cell(p: Dictionary, ref: String, depth: int = 0) -> float:
	var col := ref.unicode_at(0) - "A".unicode_at(0)
	var row := int(ref.substr(1)) - 1
	var rows: Array = p.cells
	if depth > 20 or row < 0 or row >= rows.size() or col < 0 or col >= (rows[row] as Array).size():
		return NAN
	var t := str(rows[row][col]).strip_edges()
	if not t.begins_with("="):
		return float(t) if t.is_valid_float() else NAN
	var f := t.substr(1)
	var fn := RegEx.create_from_string("^(SUM|MAX|MIN|AVERAGE)\\(([A-E])(\\d+):([A-E])(\\d+)\\)$").search(f)
	if fn != null:
		var values: Array[float] = []
		for c in range(fn.get_string(2).unicode_at(0), fn.get_string(4).unicode_at(0) + 1):
			for r in range(int(fn.get_string(3)), int(fn.get_string(5)) + 1):
				values.append(_cell(p, String.chr(c) + str(r), depth + 1))
		var s := 0.0
		for v in values:
			s += v
		match fn.get_string(1):
			"SUM":
				return s
			"MAX":
				return values.max()
			"MIN":
				return values.min()
		return s / values.size()
	var op := RegEx.create_from_string("^([A-E]\\d+|\\d+)([+*/-])([A-E]\\d+|\\d+)$").search(f)
	if op != null:
		var a := float(op.get_string(1)) if op.get_string(1).is_valid_int() else _cell(p, op.get_string(1), depth + 1)
		var b := float(op.get_string(3)) if op.get_string(3).is_valid_int() else _cell(p, op.get_string(3), depth + 1)
		match op.get_string(2):
			"+":
				return a + b
			"-":
				return a - b
			"*":
				return a * b
		return a / b
	return NAN


## "What does B5 show?" about a spreadsheet: its formula worked out.
func test_the_spreadsheet_models_are_worked_out() -> void:
	var cell := RegEx.create_from_string("\\b(?:does|will) ([A-E]\\d+) show")
	var checked := 0
	for ex in _exercises("computing"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or str(pic.get("kind", "")) != "sheet":
			continue
		var m := cell.search(str(ex.prompt))
		if m == null:
			continue
		assert_almost_eq(NumberAnswer.value(str(ex.answer)), _cell(pic, m.get_string(1)), 0.001, "%s: %s" % [ex.id, ex.prompt])
		checked += 1
	assert_gte(checked, 5, "spreadsheet formulas were worked out")


# --- Art facts -------------------------------------------------------------------------------------------------------

const SHAPE_SIDES := {"triangle": 3, "square": 4, "pentagon": 5, "hexagon": 6, "octagon": 8, "decagon": 10,
	"dodecagon": 12}


## Every "a regular hexagon's angles are 120°" and "6 equilateral triangles fit round a point" (360° round a point).
func test_the_tessellation_angles_are_right() -> void:
	var angle := RegEx.create_from_string("regular (triangle|square|pentagon|hexagon|octagon|decagon|dodecagon)(?:'s| has) (?:angles are|each angle is|angles of|inside angles are) (\\d+)°")
	var fit := RegEx.create_from_string("\\b(\\d+) (?:equilateral triangles|squares|regular hexagons|hexagons) (?:fit|meet) (?:round|around|at) (?:a|one|each) point")
	var checked := 0
	for t in _subject_texts("art"):
		for m in angle.search_all(t):
			var n := int(SHAPE_SIDES[m.get_string(1)])
			assert_eq(int(m.get_string(2)), 180 * (n - 2) / n, t)
			checked += 1
		for m in fit.search_all(t):
			var word := m.get_string(0)
			var n := 3 if word.contains("triangle") else (4 if word.contains("square") else 6)
			assert_eq(int(m.get_string(1)) * 180 * (n - 2) / n, 360, t)
			checked += 1
	for ex in _exercises("art"):
		var pic: Variant = ex.get("picture")
		if str(ex.type) != "number" or not pic is Dictionary or str(pic.get("kind", "")) != "rotation_motif":
			continue
		var low := str(ex.prompt).to_lower()
		if low.contains("angle") or low.contains("degrees"):
			assert_eq(NumberAnswer.value(str(ex.answer)), 360.0 / int(pic.order), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
		elif low.contains("order"):
			assert_eq(NumberAnswer.value(str(ex.answer)), float(pic.order), "%s: %s" % [ex.id, ex.prompt])
			checked += 1
	assert_gte(checked, 6, "tessellation and rotation facts were checked")


# --- Music facts -----------------------------------------------------------------------------------------------------

## A note's pitch in semitones ("C4" = 48, "Eb4" = 51, "F#3" = 42); -1 for a rest or anything else.
func _pitch(note: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([#b]?)([2-6])$").search(note.split(":")[0])
	if m == null:
		return -1
	var s := int(SEMIS[m.get_string(1)]) + (1 if m.get_string(2) == "#" else -1 if m.get_string(2) == "b" else 0)
	return 12 * int(m.get_string(3)) + s


## "F sharp" -> semitones above C (0-11).
func _named(name: String) -> int:
	var s := int(SEMIS[name.left(1)])
	if name.ends_with(" sharp") or name.ends_with("#"):
		s += 1
	elif name.ends_with(" flat") or (name.length() == 2 and name.ends_with("b")):
		s -= 1
	return posmod(s, 12)


## Every "The G major scale is G, A, B, C, D, E, F sharp, G" goes up T T S T T T S; every keyboard with a marked scale
## of eight notes goes up by the major or natural minor pattern; every "G major has one sharp: F sharp" and every key
## signature picture is the key's own.
func test_the_scales_and_keys_are_right() -> void:
	var checked := 0
	var scale := RegEx.create_from_string("\\b([A-G](?: flat| sharp)?) major scale is ((?:[A-G](?: flat| sharp)?, ){5,7}[A-G](?: flat| sharp)?(?:,? and [A-G](?: flat| sharp)?)?)")
	var count := RegEx.create_from_string("\\b([A-G](?: flat)?) major has (no|one|two|three) (sharps?|flats?)")
	var words := {"no": 0, "one": 1, "two": 2, "three": 3}
	for t in _subject_texts("music"):
		for m in scale.search_all(t):
			var names := m.get_string(2).replace(", and ", ", ").replace(" and ", ", ").split(", ")
			assert_eq(names[0], m.get_string(1), t)
			for i in 7:
				if i + 1 < names.size():
					assert_eq(posmod(_named(names[i + 1]) - _named(names[i]), 12), MAJOR_SCALE[i], "%s: step %d" % [t, i + 1])
			checked += 1
		for m in count.search_all(t):
			var key := m.get_string(1).replace(" flat", "b")
			assert_true(KEY_SIGNATURES.has(key), t)
			if KEY_SIGNATURES.has(key):
				assert_eq((KEY_SIGNATURES[key] as Array).size(), int(words[m.get_string(2)]), t)
				if int(words[m.get_string(2)]) > 0:
					assert_eq(m.get_string(3).begins_with("sharp"), str(KEY_SIGNATURES[key][0]).ends_with("#"), t)
			checked += 1
	for p in _pictures("music"):
		if str(p.kind) == "keyboard" and (p.get("mark", []) as Array).size() == 8:
			var steps: Array[int] = []
			for i in 7:
				steps.append(_pitch(str(p.mark[i + 1])) - _pitch(str(p.mark[i])))
			assert_true(steps == MAJOR_SCALE or steps == MINOR_SCALE, "%s: steps %s" % [p.mark, steps])
			if str(p.get("scale", "")) == "major":
				assert_eq(steps, MAJOR_SCALE, "%s: a major scale" % [p.mark])
			checked += 1
		if str(p.kind) == "key_signature":
			assert_eq(SchoolPictureG6Arts.key_accidentals(str(p.key)), KEY_SIGNATURES[str(p.key)], "%s's signature" % p.key)
			checked += 1
	assert_gte(checked, 10, "scales and keys were checked")


## An interval by its letters, counted from the lower note (both count: C up to E is a third); an octave is the same
## letter eight notes up.
func _interval(a: String, b: String) -> String:
	var lo := a if _pitch(a) <= _pitch(b) else b
	var hi := b if lo == a else a
	var steps := LETTERS.find(hi.left(1)) - LETTERS.find(lo.left(1)) + 7 * (int(hi.right(1)) - int(lo.right(1)))
	return INTERVALS[steps] if steps >= 0 and steps < INTERVALS.size() else ""


## Every "C up to G is a fifth" the lessons state, every interval heard (two notes, one after the other or together)
## and every interval read from two marked keys or two stave notes: the right choice is the interval's name.
func test_the_intervals_are_named_right() -> void:
	var checked := 0
	var rule := RegEx.create_from_string("\\b([A-G]) (?:up )?to (?:the next )?([A-G]) (?:above )?is an? (second|third|fourth|fifth|sixth|seventh|octave)\\b")
	for t in _subject_texts("music"):
		for m in rule.search_all(t):
			var a := LETTERS.find(m.get_string(1))
			var b := LETTERS.find(m.get_string(2))
			var steps := posmod(b - a, 7)
			if steps == 0:
				steps = 7
			assert_eq(INTERVALS[steps], m.get_string(3), t)
			checked += 1
	for ex in _exercises("music"):
		if str(ex.type) != "choice":
			continue
		var words: Array[String] = []
		for c: Variant in ex.choices:
			words.append(ExerciseCheck.item_text(c).to_lower().trim_prefix("a ").trim_prefix("an "))
		var named := 0
		for w in words:
			if INTERVALS.has(w) or w == "step":
				named += 1
		if named < 2:
			continue
		var notes: Array[String] = []
		if ex.get("sound") is Dictionary and str(ex.sound.kind) == "notes" and (ex.sound.notes as Array).size() <= 2:
			for n: String in ex.sound.notes:
				for part in n.split(":")[0].split("+"):
					if _pitch(part) >= 0:
						notes.append(part)
		elif ex.get("picture") is Dictionary and str(ex.picture.kind) in ["keyboard", "stave"]:
			var pic: Dictionary = ex.picture
			for n: Variant in pic.get("mark", []) if str(pic.kind) == "keyboard" else pic.get("notes", []):
				notes.append(str(n))
		if notes.size() != 2:
			continue
		var name := _interval(notes[0], notes[1])
		var right := words[int(ex.answer)]
		assert_true(right == name or (right == "step" and name == "second"), "%s: %s is a %s, the answer %s" % [ex.id,
			notes, name, right])
		checked += 1
	assert_gte(checked, 10, "intervals were checked")


## "The C blues scale is C, E flat, F, F sharp, G and B flat" (up 3, 2, 1, 1, 3 semitones, then 2 to C); the 12-bar
## blues pictures follow I I I I, IV IV I I, V IV I I in their key; the major and minor chords named are built right.
func test_the_blues_and_chords_are_right() -> void:
	var checked := 0
	var blues := RegEx.create_from_string("\\b([A-G]) blues scale is ((?:[A-G](?: flat| sharp)?, ){3,5}[A-G](?: flat| sharp)?(?:,? and [A-G](?: flat| sharp)?)?)")
	var chord := RegEx.create_from_string("\\b([A-G]) (major|minor) chord is ([A-G]), ([A-G]) and ([A-G])\\b")
	for t in _subject_texts("music"):
		for m in blues.search_all(t):
			var names := m.get_string(2).replace(", and ", ", ").replace(" and ", ", ").split(", ")
			var home := _named(m.get_string(1))
			var got: Array[int] = []
			for n in names:
				got.append(posmod(_named(n) - home, 12))
			assert_eq(got, BLUES_SCALE, t)
			checked += 1
		for m in chord.search_all(t):
			var root := int(SEMIS[m.get_string(3)])
			var third := posmod(int(SEMIS[m.get_string(4)]) - root, 12)
			var fifth := posmod(int(SEMIS[m.get_string(5)]) - root, 12)
			assert_eq(m.get_string(1), m.get_string(3), t)
			assert_eq(fifth, 7, t)
			assert_eq(third, 4 if m.get_string(2) == "major" else 3, t)
			checked += 1
	for p in _pictures("music"):
		if str(p.kind) != "twelve_bar":
			continue
		var key := str(p.key)
		var letters := "CDEFGAB"
		var four := letters[(letters.find(key.left(1)) + 3) % 7]
		var five := letters[(letters.find(key.left(1)) + 4) % 7]
		var want: Array[String] = [key, key, key, key, four, four, key, key, five, four, key, key]
		assert_eq(SchoolPictureG6Arts.twelve_bar_chords(key), want, "the 12-bar blues in %s" % key)
		checked += 1
	assert_gte(checked, 5, "the blues and chords were checked")


## Every "Hildegard of Bingen (1098-1179)" and every lifespans picture has the person's years.
func test_the_years_are_right() -> void:
	var names := "|".join(PackedStringArray(PEOPLE.keys()))
	var rule := RegEx.create_from_string("\\b(" + names + ")(?: of Bingen)? \\((?:about )?(\\d{4})-(\\d{4})\\)")
	var checked := 0
	for subject in ["music", "art"]:
		for t in _subject_texts(subject):
			for m in rule.search_all(t):
				assert_eq([int(m.get_string(2)), int(m.get_string(3))], PEOPLE[m.get_string(1)], t)
				checked += 1
		for p in _pictures(subject):
			if str(p.kind) != "lifespans":
				continue
			for row: Array in p.people:
				var who := str(row[0]).get_slice(" ", str(row[0]).get_slice_count(" ") - 1)
				if PEOPLE.has(who):
					assert_eq([int(row[1]), int(row[2])], PEOPLE[who], "the lifespans picture: %s" % [row])
					checked += 1
	assert_gte(checked, 6, "the years were checked")


## Every "A4 is 440 Hz" (a note's frequency, SchoolSound's own tuning, to the nearest hertz) and every "an octave up
## doubles": 220 Hz, 440 Hz, 880 Hz.
func test_the_frequencies_are_right() -> void:
	var rule := RegEx.create_from_string("\\b([A-G][#b]?[2-6]) (?:is|vibrates at|has a frequency of|sounds at) (?:about )?([\\d,]+) Hz")
	var checked := 0
	for t in _subject_texts("music"):
		for m in rule.search_all(t):
			assert_almost_eq(float(m.get_string(2).replace(",", "")), SchoolSound.frequency(m.get_string(1)), 1.0, t)
			checked += 1
	assert_gte(checked, 3, "frequencies were checked")


## "Copy the rhythm": at most 8 boxes, starting with a clap you can hear, and the worked answer names the boxes.
func test_the_rhythms_to_copy_start_with_a_clap() -> void:
	var n := 0
	for ex in _exercises("music"):
		if str(ex.type) != "rhythm":
			continue
		n += 1
		var p := str(ex.sound.pattern)
		assert_true(p.begins_with("x") and p.length() <= 8, "%s: %s" % [ex.id, p])
		assert_true(str(ex.explain).contains("box"), "%s: the worked answer names the boxes" % ex.id)
	assert_gte(n, 4, "syncopation copies rhythms")
