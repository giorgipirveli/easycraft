extends GutTest
## Owner #70 and #73: grade 5 computing, art and music generators (SchoolGen "g5a.<name>", core/school/gen/g5_arts_gen.gd).
## Every answer is worked out again here from the exercise's code, pen program, spreadsheet, chart, picture, sound or
## prompt, with this test's own rules: an interpreter for the programs (variables, loops, IF, procedures), the pen's
## lines, a spreadsheet's formulas, the search engine's rules, the Greek orders, the buildings, light and shadow, the
## weaves, chords and scales by semitones, forms by their phrases, syllables and rhymes, the composers' years, beat
## grids, note values and conducting patterns.

const GENS: Array[String] = ["trace_game", "nested_count", "pen_loop", "call_count", "bounce_sim", "packet_count",
	"rank_results", "sheet_sum", "chart_read", "odd_shadow", "mosaic_tiles", "column_order", "building_facts",
	"light_and_shadow", "weave_next", "major_or_minor", "build_chord", "scale_steps", "form_count", "syllable_beats",
	"composer_years", "world_pattern", "melody_beats", "conduct", "loop_time"]
const SEEDS := 60
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
## This test's own facts.
const COMPOSERS := {"Vivaldi": [1678, 1741], "Bach": [1685, 1750], "Handel": [1685, 1759], "Haydn": [1732, 1809],
	"Mozart": [1756, 1791]}
const ORDER_LOOKS := {"doric": "plain", "ionic": "scrolls", "corinthian": "acanthus"}
const BUILDINGS := {"pyramid": ["the Great Pyramid of Giza", "Egypt"], "parthenon": ["the Parthenon", "Greece"],
	"pantheon": ["the Pantheon", "Italy"], "taj_mahal": ["the Taj Mahal", "India"], "aqueduct": ["a Roman aqueduct", ""],
	"cathedral": ["a Gothic cathedral", ""], "pagoda": ["a pagoda", ""], "skyscraper": ["a skyscraper", ""]}
const HELD_UP := {"lintel": "post and lintel", "parthenon": "post and lintel", "round_arch": "round arch",
	"aqueduct": "round arches", "pointed_arch": "pointed arch", "cathedral": "pointed arches", "pantheon": "a dome",
	"skyscraper": "a steel frame"}
const SYLLABLE_COUNT := {"cat": 1, "moon": 1, "garden": 2, "rainbow": 2, "tiger": 2, "sunshine": 2, "river": 2,
	"happy": 2, "mountain": 2, "castle": 2, "butterfly": 3, "elephant": 3, "banana": 3, "dinosaur": 3, "umbrella": 3,
	"adventure": 3, "wonderful": 3, "computer": 3, "caterpillar": 4, "helicopter": 4, "watermelon": 4, "the": 1, "a": 1,
	"in": 1, "sky": 1, "we": 1, "sail": 1, "across": 2, "sea": 1, "sings": 1, "my": 1, "is": 1, "green": 1, "flies": 1,
	"high": 1, "dance": 1, "buddies": 2}
const RHYME_ENDS := {"night": "ight", "light": "ight", "bright": "ight", "kite": "ight", "day": "ay", "play": "ay",
	"stay": "ay", "grey": "ay", "tree": "ee", "sea": "ee", "free": "ee", "bee": "ee", "star": "ar", "far": "ar",
	"car": "ar", "guitar": "ar", "cat": "at", "hat": "at", "bat": "at", "flat": "at", "sing": "ing", "ring": "ing",
	"king": "ing", "spring": "ing", "snow": "oh", "go": "oh", "slow": "oh", "glow": "oh", "fun": "un", "sun": "un",
	"run": "un", "done": "un"}
const BEATS := {"semibreve": 4.0, "dotted minim": 3.0, "minim": 2.0, "crotchet": 1.0, "quaver": 0.5}
const WAYS := {2: ["down", "up"], 3: ["down", "right", "up"], 4: ["down", "left", "right", "up"]}


func _all(gen: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make("g5a." + gen, s, level)
			ex["_level"] = level
			out.append(ex)
	return out


func _right(ex: Dictionary) -> Variant:
	return ex.choices[int(ex.answer)]


func _right_text(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(_right(ex))


func _value(ex: Dictionary) -> float:
	return NumberAnswer.value(str(ex.answer))


func test_every_generator_exists_and_is_valid() -> void:
	for gen in GENS:
		assert_true(SchoolGen.exists("g5a." + gen), gen)
		for ex in _all(gen):
			ex.erase("_level")
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [ex.id, ex])
			assert_true(ex.has("data") and str(ex.get("explain", "")) != "", "%s: data and a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.explain), "%s: the hint is a strategy" % ex.id)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % ex.id)
			for c: Variant in ex.get("choices", []):
				if c is Dictionary:
					assert_eq(SchoolPicture.problem(c.picture), "", "%s: a choice's picture" % ex.id)
	var names := {}
	for id in SchoolGen.ids():
		if id.begins_with("g5a."):
			names[id.trim_prefix("g5a.")] = true
	assert_eq(names.size(), GENS.size(), "every g5a generator is tested here")


# --- An interpreter for the code pictures ---------------------------------------------------------------------------

func _depth(line: String) -> int:
	return int((line.length() - line.lstrip(" ").length()) / 2.0)


func _inner(lines: Array, at: int) -> Array[int]:
	var out: Array[int] = []
	for j in range(at + 1, lines.size()):
		if _depth(str(lines[j])) <= _depth(str(lines[at])):
			break
		if _depth(str(lines[j])) == _depth(str(lines[at])) + 1:
			out.append(j)
	return out


## Runs a program: SET v TO n, CHANGE v BY n (or by another variable), REPEAT n (TIMES), IF v > n / < / = / ≥ with
## ELSE, DEFINE name (its lines run when a line is its name); every other line is an action. Returns {vars, runs: how
## many times each line ran}.
func _run(lines: Array) -> Dictionary:
	var st := {"vars": {}, "runs": {}, "procs": {}}
	var top: Array[int] = []
	for i in lines.size():
		if _depth(str(lines[i])) == 0:
			top.append(i)
			if str(lines[i]).begins_with("DEFINE "):
				st.procs[str(lines[i]).substr(7)] = i
	_do(lines, top, st, 0)
	return st


func _do(lines: Array, which: Array[int], st: Dictionary, calls: int) -> void:
	var k := 0
	while k < which.size():
		var i := which[k]
		var t := str(lines[i]).strip_edges()
		var w := t.split(" ")
		st.runs[i] = int(st.runs.get(i, 0)) + 1
		match w[0]:
			"DEFINE":
				st.runs[i] = 0
			"SET":
				st.vars[w[1]] = int(w[3])
			"CHANGE":
				var by: int = int(w[3]) if w[3].is_valid_int() else int(st.vars[w[3]])
				st.vars[w[1]] = int(st.vars.get(w[1], 0)) + by
			"REPEAT":
				for n in int(w[1]):
					_do(lines, _inner(lines, i), st, calls)
			"IF":
				var v := int(st.vars[w[1]])
				var n := int(w[3])
				var yes: bool = {">": v > n, "<": v < n, "=": v == n, "≥": v >= n}[w[2]]
				var else_at := which[k + 1] if k + 1 < which.size() and str(lines[which[k + 1]]).strip_edges() == "ELSE" else -1
				if yes:
					_do(lines, _inner(lines, i), st, calls)
				elif else_at >= 0:
					_do(lines, _inner(lines, else_at), st, calls)
				if else_at >= 0:
					k += 1
			_:
				if st.procs.has(t) and calls < 20:
					_do(lines, _inner(lines, int(st.procs[t])), st, calls + 1)
		k += 1


func test_the_interpreter_runs_programs() -> void:
	var r := _run(["SET y TO 6", "SET speed TO -3", "REPEAT 3 TIMES", "  CHANGE y BY speed", "  IF y = 0",
		"    SET speed TO 3"])
	assert_eq(int(r.vars.y), 3, "6, 3, 0 (bounce), 3")
	r = _run(["DEFINE hop", "  REPEAT 2 TIMES", "    JUMP", "REPEAT 3 TIMES", "  hop", "hop"])
	assert_eq(int(r.runs[2]), 8, "JUMP: 2 in each of 4 calls")


# --- Computing -------------------------------------------------------------------------------------------------------

func test_trace_game() -> void:
	for ex in _all("trace_game"):
		var r := _run(ex.picture.lines)
		assert_eq(_value(ex), float(r.vars[str(ex.data.var)]), "%s: %s" % [ex.id, ex.picture.lines])
		assert_string_contains(str(ex.prompt), str(ex.data.var), ex.id)


func test_nested_count_and_call_count_count_the_marked_line() -> void:
	for gen: String in ["nested_count", "call_count"]:
		for ex in _all(gen):
			var r := _run(ex.picture.lines)
			assert_eq(_value(ex), float(r.runs.get(int(ex.picture.mark), 0)), "%s: %s" % [ex.id, ex.picture.lines])
			assert_eq(int(ex.picture.mark), int(ex.data.mark), ex.id)


## The pen's drawn length: every FORWARD with the pen down, run through the loops.
func _pen_length(lines: Array) -> int:
	var st := {"pen": true, "len": 0}
	var top: Array[int] = []
	for i in lines.size():
		if _depth(str(lines[i])) == 0:
			top.append(i)
	_pen(lines, top, st)
	return int(st.len)


func _pen(lines: Array, which: Array[int], st: Dictionary) -> void:
	for i in which:
		var t := str(lines[i]).strip_edges()
		if t.begins_with("REPEAT "):
			for n in int(t.get_slice(" ", 1)):
				_pen(lines, _inner(lines, i), st)
		elif t.begins_with("FORWARD") and st.pen:
			st.len = int(st.len) + (int(t.get_slice(" ", 1)) if t.contains(" ") else 1)
		elif t == "PEN UP" or t == "PEN DOWN":
			st.pen = t == "PEN DOWN"


func _segments(lines: Array) -> Array:
	var t := SchoolPictureG5Arts.trace({"kind": "pen", "lines": lines, "cols": 8, "rows": 5})
	var out: Array = []
	for s: Array in t.segments:
		var a: Vector2i = s[0]
		var b: Vector2i = s[1]
		out.append("%d,%d-%d,%d" % [mini(a.x, b.x), mini(a.y, b.y), maxi(a.x, b.x), maxi(a.y, b.y)])
	out.sort()
	return out


func test_pen_loop() -> void:
	for ex in _all("pen_loop"):
		if int(ex._level) < 3:
			assert_eq(_value(ex), float(_pen_length(ex.picture.lines)), "%s: %s" % [ex.id, ex.picture.lines])
			continue
		assert_eq(Array(_right(ex).picture.lines), Array(ex.data.lines), "%s: the right drawing is the program's" % ex.id)
		assert_eq(Array(ex.picture.lines), Array(ex.data.lines), ex.id)
		var right := _segments(ex.data.lines)
		assert_false(right.is_empty(), ex.id)
		for i in (ex.choices as Array).size():
			if i != int(ex.answer):
				assert_ne(_segments(ex.choices[i].picture.lines), right, "%s: a wrong drawing looks the same" % ex.id)


func test_bounce_sim() -> void:
	for ex in _all("bounce_sim"):
		var r := _run(ex.picture.lines)
		assert_eq(_value(ex), float(r.vars[str(ex.data.var)]), "%s: %s" % [ex.id, ex.picture.lines])
		if int(ex._level) == 2:
			assert_true(str(ex.explain).contains(", 0,"), "%s: the ball reaches the floor: %s" % [ex.id, ex.explain])


func test_packet_count() -> void:
	for ex in _all("packet_count"):
		if int(ex._level) == 2:
			var message := str(ex.data.message)
			var said := ""
			for i: Variant in ex.answer:
				said += str(ex.items[int(i)])
			assert_eq(said.replace("·", " "), message, ex.id)
			var order: Array = ex.picture.order
			assert_ne(order, range(order.size()), "%s: they arrived in a muddle" % ex.id)
			continue
		var total := int(ex.data.total)
		var size := int(ex.data.size)
		var n := total / size + (1 if total % size != 0 else 0)
		assert_eq(_value(ex), float(n), ex.id)
		assert_string_contains(str(ex.prompt), str(total), ex.id)


func test_rank_results() -> void:
	for ex in _all("rank_results"):
		var pages: Array = ex.data.pages
		var words: Array = ex.data.words
		var links: Array = ex.data.links
		var ranked: Array = range(pages.size())
		ranked.sort_custom(func(a: int, b: int) -> bool:
			return int(words[a]) > int(words[b]) or (int(words[a]) == int(words[b]) and int(links[a]) > int(links[b])))
		var said: Array = []
		for i: Variant in ex.answer:
			said.append(str(ex.items[int(i)]))
		var want: Array = []
		for i: int in ranked:
			want.append(str(pages[i]))
		assert_eq(said, want, ex.id)
		var seen := {}
		for l: Variant in links:
			seen[int(l)] = true
		assert_eq(seen.size(), links.size(), "%s: no two pages tie on links too" % ex.id)
		if int(ex._level) > 1:
			var w := {}
			for x: Variant in words:
				w[int(x)] = true
			assert_lt(w.size(), words.size(), "%s: two pages tie on words" % ex.id)


## A cell's value (this test's own evaluator): numbers, =SUM/MAX/MIN(B2:B5), =B2*C2.
func _cell(cells: Array, ref: String) -> float:
	var col := ref.unicode_at(0) - 65
	var row := int(ref.substr(1)) - 1
	var t := str(cells[row][col])
	if not t.begins_with("="):
		return float(t)
	var m := RegEx.create_from_string("^=(SUM|MAX|MIN)\\(B(\\d+):B(\\d+)\\)$").search(t)
	if m != null:
		var vals: Array[float] = []
		for r in range(int(m.get_string(2)), int(m.get_string(3)) + 1):
			vals.append(_cell(cells, "B%d" % r))
		var out := 0.0
		match m.get_string(1):
			"SUM":
				for v in vals:
					out += v
			"MAX":
				out = vals.max()
			"MIN":
				out = vals.min()
		return out
	var p := RegEx.create_from_string("^=([A-E]\\d+)\\*([A-E]\\d+)$").search(t)
	return _cell(cells, p.get_string(1)) * _cell(cells, p.get_string(2))


func test_sheet_sum() -> void:
	for ex in _all("sheet_sum"):
		var cells: Array = (ex.picture.cells as Array).duplicate(true)
		assert_eq(cells, ex.data.cells, ex.id)
		if str(ex.data.get("changed", "")) != "":
			var ref := str(ex.data.changed)
			var m := RegEx.create_from_string("to (\\d+)\\.").search(str(ex.prompt))
			cells[int(ref.substr(1)) - 1][1] = m.get_string(1)
		assert_eq(_value(ex), _cell(cells, str(ex.data.cell)), "%s: %s" % [ex.id, ex.prompt])
		assert_string_contains(str(ex.prompt), str(ex.data.cell), ex.id)


func test_chart_read() -> void:
	for ex in _all("chart_read"):
		var bars: Array = ex.picture.bars
		var ask: Array = ex.data.ask
		var want := float(bars[int(ask[0])][1]) if ask.size() == 1 else float(bars[int(ask[0])][1]) - float(bars[int(ask[1])][1])
		assert_eq(_value(ex), want, ex.id)
		if int(ex._level) == 3:
			var from := float(ex.picture.from)
			var looks := (float(bars[1][1]) - from) / (float(bars[0][1]) - from)
			assert_string_contains(str(ex.prompt), "looks %d times" % int(looks), "%s: the bars look that many times as tall" % ex.id)
			assert_gt(from, 0.0, ex.id)


func test_odd_shadow() -> void:
	var ordinals: Array[String] = ["1st", "2nd", "3rd", "4th"]
	for ex in _all("odd_shadow"):
		assert_eq(_right_text(ex), "the %s from the left" % ordinals[int(ex.picture.odd)], ex.id)
		assert_string_contains(str(ex.prompt), "on the %s" % ex.picture.sun, ex.id)
		assert_eq((ex.choices as Array).size(), (ex.picture.things as Array).size(), ex.id)


# --- Art ---------------------------------------------------------------------------------------------------------------

func test_mosaic_tiles() -> void:
	for ex in _all("mosaic_tiles"):
		match int(ex._level):
			1:
				assert_eq(_value(ex), float(int(ex.data.w) * int(ex.data.h)), ex.id)
			_:
				var n := 0
				for row: String in ex.picture.rows:
					n += row.count("a")
				assert_eq(_value(ex), float(n), ex.id)
				assert_string_contains(str(ex.prompt), str(ex.picture.key.a) if int(ex._level) == 2 else "border", ex.id)


func test_column_order() -> void:
	for ex in _all("column_order"):
		var o := str(ex.data.order)
		for i in (ex.choices as Array).size():
			var c: Variant = ex.choices[i]
			var named := str(c.picture.orders[0]) if c is Dictionary else str(c).to_lower()
			assert_eq(named == o, i == int(ex.answer), ex.id)
		if ex.has("picture"):
			assert_eq(str(ex.picture.orders[0]), o, ex.id)
		if int(ex._level) == 2:
			var looks := {"doric": "plain", "ionic": "scrolls", "corinthian": "acanthus"}
			assert_string_contains(str(ex.prompt), looks[o], ex.id)


func test_building_facts() -> void:
	for ex in _all("building_facts"):
		var what := str(ex.picture.what)
		match int(ex._level):
			1:
				assert_eq(_right_text(ex), str(BUILDINGS[what][0]), ex.id)
			2:
				assert_ne(str(BUILDINGS[what][1]), "", "%s: only one famous building is asked where" % ex.id)
				assert_eq(_right_text(ex), str(BUILDINGS[what][1]), ex.id)
			3:
				assert_true(_right_text(ex).contains(str(HELD_UP[what])) or str(HELD_UP[what]).contains(_right_text(ex).trim_prefix("a ")),
					"%s: %s is held up by %s" % [ex.id, what, _right_text(ex)])


func test_light_and_shadow() -> void:
	for ex in _all("light_and_shadow"):
		var light := str(ex.data.light)
		var away := "right" if light == "left" else "left"
		if int(ex._level) < 3:
			assert_string_contains(_right_text(ex), away, ex.id)
			assert_eq(str(ex.picture.light), light, ex.id)
		else:
			assert_eq(str(_right(ex).picture.light), light, ex.id)
			for i in (ex.choices as Array).size():
				if i != int(ex.answer):
					assert_eq(str(ex.choices[i].picture.light), away, ex.id)


func _flip(r: String) -> String:
	var out := ""
	for ch in r:
		out += "u" if ch == "o" else "o"
	return out


func test_weave_next() -> void:
	for ex in _all("weave_next"):
		var rows: Array = ex.picture.rows
		var last := str(rows[-1])
		var want := ""
		match str(ex.data.rule):
			"plain weave":
				want = _flip(last)
			"twill":
				var before := str(rows[-2])
				var right_shift := last == before.right(1) + before.left(before.length() - 1)
				want = last.right(1) + last.left(last.length() - 1) if right_shift else last.substr(1) + last.left(1)
				assert_true(right_shift or last == before.substr(1) + before.left(1), "%s: a twill steps along" % ex.id)
			"basket weave":
				want = last if str(rows[-2]) != last else _flip(last)
		assert_eq(str(_right(ex).picture.rows[0]), want, "%s: %s" % [ex.id, rows])
		for i in (ex.choices as Array).size():
			if i != int(ex.answer):
				assert_ne(str(ex.choices[i].picture.rows[0]), want, ex.id)


# --- Music -------------------------------------------------------------------------------------------------------------

func _pitch(note: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([#b]?)([2-6])$").search(note.split(":")[0])
	return 12 * int(m.get_string(3)) + int(SEMIS[m.get_string(1)]) + (1 if m.get_string(2) == "#" else
		(-1 if m.get_string(2) == "b" else 0))


func test_major_or_minor() -> void:
	for ex in _all("major_or_minor"):
		var notes: Array = ex.sound.notes
		var first := str(notes[0]).split(":")[0]
		var third := -1
		if first.contains("+"):
			third = _pitch(first.split("+")[1]) - _pitch(first.split("+")[0])
		else:
			var home := posmod(_pitch(first), 12)
			for n: String in notes:
				var d := posmod(_pitch(n) - home, 12)
				if d == 3 or d == 4:
					assert_true(third == -1 or third == d, "%s: one third only" % ex.id)
					third = d
		assert_eq(_right_text(ex), "major" if third == 4 else "minor", "%s: %s" % [ex.id, notes])
		assert_true(third == 3 or third == 4, ex.id)


## The chord of a white-key root: skip a letter twice.
func _chord_letters(root: String) -> Array[String]:
	var at := "CDEFGAB".find(root)
	return ["CDEFGAB"[at], "CDEFGAB"[(at + 2) % 7], "CDEFGAB"[(at + 4) % 7]]


func _quality(letters: Array) -> String:
	var t := posmod(int(SEMIS[letters[1]]) - int(SEMIS[letters[0]]), 12)
	return "major" if t == 4 else ("minor" if t == 3 else "")


func test_build_chord() -> void:
	for ex in _all("build_chord"):
		if int(ex._level) < 3:
			var name := RegEx.create_from_string("the ([A-G]) (major|minor) chord").search(str(ex.prompt))
			var letters := _chord_letters(name.get_string(1))
			assert_eq(_quality(letters), name.get_string(2), ex.id)
			assert_eq(_right_text(ex), "%s, %s and %s" % letters, ex.id)
		else:
			var letters: Array = []
			for n: String in ex.picture.chords[0]:
				letters.append(n.left(1))
			assert_eq(letters, Array(_chord_letters(str(letters[0]))), "%s: a chord of thirds" % ex.id)
			assert_eq(_right_text(ex), "%s %s" % [letters[0], _quality(letters)], ex.id)


func test_scale_steps() -> void:
	for ex in _all("scale_steps"):
		match int(ex._level):
			1:
				var gap := _pitch(str(ex.data.to)) - _pitch(str(ex.data.from))
				assert_eq(_right_text(ex), "a tone" if gap == 2 else "a semitone", ex.id)
			2:
				assert_eq(_value(ex), float(_pitch(str(ex.data.to)) - _pitch(str(ex.data.from))), ex.id)
			3:
				var at := _pitch(str(ex.data.home))
				for step: int in [2, 2, 1, 2, 2, 2, 1].slice(0, int(ex.data.nth) - 1):
					at += step
				var right := _right_text(ex)
				var named := int(SEMIS[right.left(1)]) + (1 if right.contains("#") else (-1 if right.ends_with("b") else 0))
				assert_eq(posmod(named, 12), posmod(at, 12), "%s: %s" % [ex.id, right])
				for i in (ex.choices as Array).size():
					if i != int(ex.answer):
						var c := str(ex.choices[i])
						var v := int(SEMIS[c.left(1)]) + (1 if c.contains("#") else (-1 if c.ends_with("b") else 0))
						assert_ne(posmod(v, 12), posmod(at, 12), ex.id)


func test_form_count() -> void:
	var names := {"A B": "binary form", "A B A": "ternary form", "A B A C A": "rondo form"}
	for ex in _all("form_count"):
		match int(ex._level):
			1:
				assert_eq(_value(ex), float((ex.picture.sections as Array).count(str(ex.data.part))), ex.id)
			2:
				assert_eq(_right_text(ex), str(names[" ".join(PackedStringArray(ex.picture.sections))]), ex.id)
			3:
				var notes: Array = ex.sound.notes
				var seen: Array = []
				var letters: Array[String] = []
				for p in 3:
					var phrase := notes.slice(p * 4, p * 4 + 4)
					if not seen.has(phrase):
						seen.append(phrase)
					letters.append("ABC"[seen.find(phrase)])
				assert_eq(_right_text(ex), " ".join(letters), ex.id)


func test_syllable_beats() -> void:
	for ex in _all("syllable_beats"):
		if int(ex._level) < 3:
			var total := 0
			for w: String in ex.data.words:
				total += int(SYLLABLE_COUNT[w])
			assert_eq(_value(ex), float(total), ex.id)
			continue
		var word := str(ex.data.word)
		for i in (ex.choices as Array).size():
			assert_eq(RHYME_ENDS[str(ex.choices[i])] == RHYME_ENDS[word], i == int(ex.answer), "%s: %s" % [ex.id, ex.choices[i]])


func test_composer_years() -> void:
	for ex in _all("composer_years"):
		var who: Array = ex.data.who
		match int(ex._level):
			1:
				assert_eq(_value(ex), float(int(COMPOSERS[who[0]][1]) - int(COMPOSERS[who[0]][0])), ex.id)
			2:
				assert_eq(_value(ex), float(int(COMPOSERS[who[1]][0]) - int(COMPOSERS[who[0]][0])), ex.id)
				assert_gt(_value(ex), 0.0, ex.id)
			3:
				var year := int(ex.data.year)
				for i in (ex.choices as Array).size():
					var c := str(ex.choices[i])
					var alive: bool = int(COMPOSERS[c][0]) < year and year < int(COMPOSERS[c][1])
					assert_eq(alive, i == int(ex.answer), "%s: %s in %d" % [ex.id, c, year])
				for row: Array in ex.picture.people:
					assert_eq([int(row[1]), int(row[2])], COMPOSERS[str(row[0])], ex.id)


func test_world_pattern() -> void:
	for ex in _all("world_pattern"):
		match int(ex._level):
			1:
				assert_eq(str(ex.type), "rhythm", ex.id)
				assert_eq(ExerciseCheck.answer_of(ex), str(ex.data.pattern), ex.id)
				assert_true(str(ex.sound.pattern).begins_with("x"), ex.id)
				for i in str(ex.data.pattern).length():
					if str(ex.data.pattern)[i] == "x":
						assert_string_contains(str(ex.explain), str(i + 1), ex.id)
			2:
				assert_eq(_value(ex), float(str(ex.picture.rows[0][1]).count("x")), ex.id)
			3:
				var a := str(ex.picture.rows[0][1])
				var b := str(ex.picture.rows[1][1])
				var both := 0
				for i in a.length():
					both += 1 if a[i] == "x" and b[i] == "x" else 0
				assert_eq(_value(ex), float(both), ex.id)


func test_melody_beats() -> void:
	for ex in _all("melody_beats"):
		var beats := 0.0
		for v: String in ex.picture.values:
			beats += float(BEATS[v])
		if int(ex._level) < 3:
			assert_eq(_value(ex), beats, ex.id)
		else:
			assert_eq(fmod(beats, 3.0), 0.0, "%s: whole bars of 3/4" % ex.id)
			assert_eq(_value(ex), beats / 3.0, ex.id)
			assert_eq(str(ex.picture.time), "3/4", ex.id)


func test_conduct() -> void:
	for ex in _all("conduct"):
		var ways: Array = WAYS[int(ex.data.beats)]
		match int(ex._level):
			1:
				assert_eq(_right_text(ex), str(ways[int(ex.data.beat) - 1]), ex.id)
			2:
				assert_eq(_value(ex), float(int(ex.data.bars) * ways.size()), ex.id)
			3:
				var way := RegEx.create_from_string("hand go (\\w+)\\?").search(str(ex.prompt)).get_string(1)
				assert_eq(_value(ex), float(ways.find(way) + 1), ex.id)


func test_loop_time() -> void:
	for ex in _all("loop_time"):
		match int(ex._level):
			1:
				assert_eq(_value(ex), float(int(ex.data.bars) * int(ex.data.times)), ex.id)
			2:
				assert_eq(_value(ex), float(int(ex.data.bars)) * 4.0 * 60.0 / float(ex.data.tempo), ex.id)
			3:
				var n := 0
				for bar in int(ex.picture.bars):
					var every := true
					for t: Array in ex.picture.tracks:
						var here := false
						for c: Array in t[1]:
							here = here or (bar >= int(c[0]) and bar < int(c[0]) + int(c[1]))
						every = every and here
					n += 1 if every else 0
				assert_eq(_value(ex), float(n), ex.id)
