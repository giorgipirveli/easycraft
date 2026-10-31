extends GutTest
## Owner #70 and #73: grade 6 computing, art and music generators (SchoolGen "g6c.<name>", core/school/gen/g6_arts_gen.gd).
## Every answer is worked out again here from the exercise's data, picture, sound or prompt with this test's own rules:
## binary place values, colours of light, logic and gates, an interpreter for the programs, flowcharts, data types, a
## spreadsheet's formulas, codes and passwords, clues of trick emails, what is private, what a computer learned,
## angles round a point, rotational symmetry, ink lightness, Fibonacci numbers, the steps of looking at art, major
## scales by semitones, intervals by letters, the 12-bar blues, music's periods, off-beat claps, variations, chords,
## instrument families and places, and sound's numbers.

const GENS: Array[String] = ["binary_value", "to_binary", "image_bits", "light_colour", "logic_check", "gate_output",
	"trace_program", "flow_path", "data_type", "game_decision", "storage_size", "sheet_model", "guess_count",
	"phish_check", "public_private", "ai_guess", "tile_angles", "turn_angle", "print_order", "nature_numbers",
	"critique_step", "principle_spot", "scale_notes", "interval_size", "blues_bar", "music_period", "offbeat_rhythm",
	"variation_change", "chord_fit", "instrument_family", "sound_numbers"]
const SEEDS := 50
const SEMIS := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const LETTERS := "CDEFGAB"
const LIGHT := {"000": "black", "100": "red", "010": "green", "001": "blue", "110": "yellow", "011": "cyan",
	"101": "magenta", "111": "white"}
const PRIVATE: Array[String] = ["your home address", "your password", "your phone number", "your full birthday",
	"where you are right now", "your school's name", "a photo in school uniform", "a photo of your street"]
const STEPS := {"There is a huge blue wave.": "describe", "Three long boats are under the wave.": "describe",
	"A small mountain is far away.": "describe", "The sky is a pale yellow.": "describe",
	"The wave's curve leads your eye to the mountain.": "analyse", "Blue and white make strong contrast.": "analyse",
	"The big wave makes the mountain look tiny.": "analyse", "The foam's claws repeat, giving rhythm.": "analyse",
	"It shows how small people are next to nature.": "interpret", "The wave is about to crash, so it feels tense.": "interpret",
	"The boatmen seem brave as they hold on.": "interpret", "I think it works: my eye keeps moving round it.": "judge",
	"In my view the contrast makes it powerful.": "judge", "I think it is great because it feels alive.": "judge"}
const PRINCIPLE_WORDS := {"symmetry": "symmetrical balance", "asymmetry": "asymmetrical balance", "radial": "radial balance",
	"contrast": "contrast", "emphasis": "emphasis", "rhythm": "rhythm", "unity": "unity", "variety": "variety",
	"movement": "movement", "pattern": "pattern"}
const INTERVALS: Array[String] = ["unison", "second", "third", "fourth", "fifth", "sixth", "seventh", "octave"]
## The families (Hornbostel and Sachs) and homes of the instruments (this test's own).
const FAMILY := {"sitar": "chordophone", "koto": "chordophone", "kora": "chordophone", "erhu": "chordophone",
	"djembe": "membranophone", "tabla": "membranophone", "bodhran": "membranophone", "bagpipes": "aerophone",
	"didgeridoo": "aerophone", "shakuhachi": "aerophone", "steelpan": "idiophone", "balafon": "idiophone",
	"gamelan gong": "idiophone"}
const SOUNDS_BY := {"chordophone": "strings that vibrate", "membranophone": "a stretched skin that vibrates",
	"aerophone": "air that vibrates in a tube", "idiophone": "the instrument itself vibrates"}
const HOME := {"sitar": "India", "koto": "Japan", "kora": "West Africa", "erhu": "China", "djembe": "West Africa",
	"tabla": "India", "bodhran": "Ireland", "bagpipes": "Scotland", "didgeridoo": "northern Australia",
	"shakuhachi": "Japan", "steelpan": "Trinidad and Tobago", "balafon": "West Africa", "gamelan gong": "Indonesia"}


func _all(gen: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make("g6c." + gen, s, level)
			ex["_level"] = level
			out.append(ex)
	return out


func _right_text(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func _value(ex: Dictionary) -> float:
	return NumberAnswer.value(str(ex.answer))


func _texts(ex: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for c: Variant in ex.choices:
		out.append(ExerciseCheck.item_text(c))
	return out


func test_every_generator_exists_and_is_valid() -> void:
	for gen in GENS:
		assert_true(SchoolGen.exists("g6c." + gen), gen)
		for ex in _all(gen):
			ex.erase("_level")
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [ex.id, ex])
			assert_true(ex.has("data") and str(ex.get("explain", "")) != "", "%s: data and a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.explain), "%s: the hint is a strategy" % ex.id)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % ex.id)
	var names := {}
	for id in SchoolGen.ids():
		if id.begins_with("g6c."):
			names[id.trim_prefix("g6c.")] = true
	assert_eq(names.size(), GENS.size(), "every g6c generator is tested here")


# --- Computing -------------------------------------------------------------------------------------------------------

func _binary(bits: String) -> int:
	var n := 0
	for ch in bits:
		n = n * 2 + (1 if ch == "1" else 0)
	return n


func test_binary_cards_are_read_by_their_place_values() -> void:
	for ex in _all("binary_value"):
		var bits := str(ex.picture.bits)
		assert_eq(bits, str(ex.data.bits))
		assert_eq(_value(ex), float(_binary(bits)), "%s: %s" % [ex.id, bits])
		assert_eq(bits.length(), [0, 4, 5, 8][int(ex._level)] if int(ex._level) > 1 else bits.length())


func test_numbers_are_written_in_binary() -> void:
	for ex in _all("to_binary"):
		var n := int(str(ex.prompt).get_slice(" ", 2))
		assert_eq(n, int(ex.data.n))
		for i in (ex.choices as Array).size():
			var t := ExerciseCheck.item_text(ex.choices[i])
			assert_eq(_binary(t) == n, i == int(ex.answer), "%s: %s for %d" % [ex.id, t, n])


func test_pictures_are_counted_in_pixels_and_bits() -> void:
	for ex in _all("image_bits"):
		match int(ex._level):
			1:
				var rows: Array = ex.picture.rows
				assert_eq(_value(ex), float(rows.size() * str(rows[0]).length()), ex.id)
			2:
				var bits := int(ex.data.bits)
				var colours := 1
				for i in bits:
					colours *= 2
				assert_eq(int(ex.data.colours), colours)
				assert_eq(_value(ex), float(colours if str(ex.prompt).contains("How many different colours") else bits), ex.id)
			_:
				assert_eq(_value(ex), float(int(ex.data.w) * int(ex.data.h) * int(ex.data.bits)) / 8.0, ex.id)
				assert_true(str(ex.prompt).contains("%d pixels wide and %d tall" % [ex.data.w, ex.data.h]), ex.id)


func _light(key: String) -> String:
	return LIGHT[key]


func test_light_adds_up() -> void:
	var num := RegEx.create_from_string("\\((\\d+), (\\d+), (\\d+)\\)")
	for ex in _all("light_colour"):
		match int(ex._level):
			1:
				var sum: Vector3i = ex.data.rgb
				assert_eq(_right_text(ex), _light("%d%d%d" % [sum.x, sum.y, sum.z]), ex.id)
				assert_false(_texts(ex).count(_right_text(ex)) > 1)
			2:
				var m := num.search(str(ex.prompt))
				var key := ("1" if m.get_string(1) == "255" else "0") + ("1" if m.get_string(2) == "255" else "0") \
					+ ("1" if m.get_string(3) == "255" else "0")
				assert_eq(_right_text(ex), _light(key), ex.id)
			_:
				var want := str(ex.prompt).get_slice("make ", 1).get_slice(" light", 0)
				for i in (ex.choices as Array).size():
					var m := num.search(ExerciseCheck.item_text(ex.choices[i]))
					var key := ("1" if m.get_string(1) == "255" else "0") + ("1" if m.get_string(2) == "255" else "0") \
						+ ("1" if m.get_string(3) == "255" else "0")
					assert_eq(_light(key) == want, i == int(ex.answer), "%s: %s" % [ex.id, ex.choices[i]])


## This test's own conditions: comparisons, AND, OR, NOT, brackets round one comparison.
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
			var a := _val(c.substr(0, c.find(op)), vars)
			var b := _val(c.substr(c.find(op) + 3), vars)
			match op:
				" ≥ ":
					return a >= b
				" ≤ ":
					return a <= b
				" > ":
					return a > b
				" < ":
					return a < b
			return a == b
	return false


func _val(t: String, vars: Dictionary) -> int:
	t = t.strip_edges()
	return int(t) if t.is_valid_int() else int(vars.get(t, 0))


func test_conditions_are_worked_out() -> void:
	for ex in _all("logic_check"):
		assert_eq(ex.answer, _cond(str(ex.data.cond), ex.data.vars), "%s: %s with %s" % [ex.id, ex.data.cond, ex.data.vars])
		assert_true(str(ex.prompt).contains(str(ex.data.cond)), ex.id)
		if int(ex._level) == 3:
			assert_true(str(ex.data.cond).contains("NOT"), ex.id)


func _gate(gate: String, ins: Array) -> int:
	if gate == "AND":
		return 1 if int(ins[0]) + int(ins[1]) == 2 else 0
	if gate == "OR":
		return 1 if int(ins[0]) + int(ins[1]) >= 1 else 0
	return 1 - int(ins[0])


func test_gates_and_truth_tables() -> void:
	for ex in _all("gate_output"):
		var want := _gate(str(ex.data.gate), ex.data.inputs)
		if str(ex.data.get("then", "")) == "NOT":
			want = 1 - want
		assert_eq(_value(ex), float(want), "%s: %s" % [ex.id, ex.data])
		if str(ex.picture.kind) == "table":
			for r in range(1, 5):
				var row: Array = ex.picture.rows[r]
				if str(row[2]) != "?":
					assert_eq(int(row[2]), _gate(str(ex.data.gate), [int(row[0]), int(row[1])]), "%s: row %s" % [ex.id, row])
				else:
					assert_eq([int(row[0]), int(row[1])], [int(ex.data.inputs[0]), int(ex.data.inputs[1])])
		else:
			assert_eq(ex.picture.inputs, ex.data.inputs)


# This test's own interpreter: SET v TO a number, a variable or "a op n", CHANGE v BY n, REPEAT n TIMES, REPEAT UNTIL,
# IF condition with ELSE, OUTPUT "text".

func _run(lines: Array) -> Dictionary:
	var st := {"vars": {}, "out": []}
	var top: Array[int] = []
	for i in lines.size():
		if _depth(str(lines[i])) == 0:
			top.append(i)
	_block(lines, top, st, 0)
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


func _block(lines: Array, which: Array[int], st: Dictionary, guard: int) -> void:
	var k := 0
	while k < which.size() and guard < 1000:
		var t := str(lines[which[k]]).strip_edges()
		var w := t.split(" ")
		if w[0] == "SET":
			var e := t.get_slice(" TO ", 1)
			var parts := e.split(" ")
			var v := _val(parts[0], st.vars)
			if parts.size() == 3:
				var b := _val(parts[2], st.vars)
				v = v + b if parts[1] == "+" else (v - b if parts[1] == "-" else v * b)
			st.vars[w[1]] = v
		elif w[0] == "CHANGE":
			st.vars[w[1]] = int(st.vars.get(w[1], 0)) + int(w[3])
		elif t.begins_with("REPEAT UNTIL "):
			var n := 0
			while not _cond(t.substr(13), st.vars) and n < 100:
				_block(lines, _inner(lines, which[k]), st, guard + 1)
				n += 1
		elif w[0] == "REPEAT":
			for n in int(w[1]):
				_block(lines, _inner(lines, which[k]), st, guard + 1)
		elif w[0] == "IF":
			var has_else := k + 1 < which.size() and str(lines[which[k + 1]]).strip_edges() == "ELSE"
			if _cond(t.substr(3), st.vars):
				_block(lines, _inner(lines, which[k]), st, guard + 1)
			elif has_else:
				_block(lines, _inner(lines, which[k + 1]), st, guard + 1)
			if has_else:
				k += 1
		elif w[0] == "OUTPUT":
			(st.out as Array).append(t.substr(7).replace("\"", ""))
		k += 1


func test_programs_are_run() -> void:
	for ex in _all("trace_program"):
		var st := _run(ex.picture.lines)
		assert_eq(_value(ex), float(st.vars[str(ex.data.var)]), "%s: %s" % [ex.id, ex.picture.lines])
	for ex in _all("game_decision"):
		var st := _run(ex.picture.lines)
		assert_eq(st.out.size(), 1, ex.id)
		assert_eq(_right_text(ex), str(st.out[0]), "%s: %s" % [ex.id, ex.picture.lines])


func test_flowcharts_are_followed() -> void:
	for ex in _all("flow_path"):
		var steps: Array = ex.picture.steps
		if int(ex._level) < 3:
			var q := str(steps[2].text)   # "score > 40?"
			var score := int(str(ex.prompt).get_slice("score is ", 1).get_slice(".", 0))
			var yes := _cond(q.trim_suffix("?"), {"score": score})
			var said := str(steps[3].text).trim_prefix("SAY ") if yes else str(steps[2].no).trim_prefix("SAY ")
			assert_eq(_right_text(ex), said, "%s: %s with %d" % [ex.id, q, score])
		else:
			var count := int(str(steps[1].text).get_slice(" TO ", 1))
			var target := int(str(steps[3].text).trim_prefix("count = ").trim_suffix("?"))
			var claps := 0
			while true:   # clap, add 1, then check: the "no" arrow goes back to the clap
				claps += 1
				count += 1
				if count == target or claps > 50:
					break
			assert_eq(_value(ex), float(claps), ex.id)


func test_data_types_and_what_plus_does() -> void:
	for ex in _all("data_type"):
		if int(ex._level) < 3:
			var v := str(ex.data.value)
			var want := "whole number (integer)"
			if v.begins_with("\""):
				want = "text (string)"
			elif v in ["TRUE", "FALSE"]:
				want = "true or false (Boolean)"
			elif v.contains("."):
				want = "decimal (real)"
			assert_eq(_right_text(ex), want, "%s: %s" % [ex.id, v])
		else:
			var shown := str(ex.prompt).get_slice("OUTPUT ", 1).trim_suffix(" show?")
			var a := shown.get_slice(" + ", 0)
			var b := shown.get_slice(" + ", 1)
			var want := a.replace("\"", "") + b.replace("\"", "") if a.begins_with("\"") else str(int(a) + int(b))
			assert_eq(_right_text(ex), want, "%s: %s" % [ex.id, shown])


func test_storage_sizes() -> void:
	for ex in _all("storage_size"):
		var p := str(ex.prompt)
		match int(ex._level):
			1:
				assert_eq(_value(ex), float(int(ex.data.bytes) * 8 if p.begins_with("How many bits") else int(ex.data.bytes)), ex.id)
			2:
				assert_eq(_value(ex), float(int(ex.data.kb) * 1000 if p.contains("How many bytes") else int(ex.data.kb)), ex.id)
			_:
				assert_eq(_value(ex), float(int(ex.data.gb) * 1000 / int(ex.data.each)), ex.id)


func _cell(p: Array, ref: String, depth: int = 0) -> float:
	var col := ref.unicode_at(0) - "A".unicode_at(0)
	var row := int(ref.substr(1)) - 1
	var t := str(p[row][col]).strip_edges()
	if depth > 20:
		return NAN
	if not t.begins_with("="):
		return float(t) if t.is_valid_float() else NAN
	var f := t.substr(1)
	var fn := RegEx.create_from_string("^(SUM|AVERAGE)\\(([A-E])(\\d+):([A-E])(\\d+)\\)$").search(f)
	if fn != null:
		var s := 0.0
		var n := 0
		for r in range(int(fn.get_string(3)), int(fn.get_string(5)) + 1):
			s += _cell(p, fn.get_string(2) + str(r), depth + 1)
			n += 1
		return s if fn.get_string(1) == "SUM" else s / n
	var op := RegEx.create_from_string("^([A-E]\\d+)\\*([A-E]\\d+)$").search(f)
	return _cell(p, op.get_string(1), depth + 1) * _cell(p, op.get_string(2), depth + 1)


func test_spreadsheet_models() -> void:
	for ex in _all("sheet_model"):
		assert_eq(_value(ex), _cell(ex.data.cells, str(ex.data.ref)), "%s: %s" % [ex.id, ex.data])
		assert_eq(_value(ex), roundf(_value(ex)), "%s: a whole number" % ex.id)
		if int(ex._level) < 3:
			assert_eq(SchoolPictureG5Arts.value(ex.picture, str(ex.data.ref)), _value(ex), "%s: the picture agrees" % ex.id)


func _pow(b: int, e: int) -> int:
	var out := 1
	for i in e:
		out *= b
	return out


func test_codes_and_passwords() -> void:
	for ex in _all("guess_count"):
		var d: Dictionary = ex.data
		if d.has("speed"):
			assert_eq(_value(ex), float(_pow(10, int(d.digits)) / int(d.speed)), ex.id)
		elif d.has("letters"):
			assert_eq(_value(ex), float(_pow(26, int(d.letters))), ex.id)
		elif d.has("more"):
			assert_eq(_value(ex), 10.0, ex.id)
		else:
			assert_eq(_value(ex), float(_pow(10, int(d.digits))), ex.id)


func test_trick_emails() -> void:
	var why := {"from": "sender", "urgent": "rushes", "password": "password", "prize": "prize", "link": "link"}
	for ex in _all("phish_check"):
		var clues: Array = ex.data.clues
		if str(ex.type) == "truefalse":
			assert_eq(ex.answer, not clues.is_empty(), ex.id)
			if clues.has("link"):
				assert_true(ex.picture.has("link"), ex.id)
		else:
			assert_eq(clues.size(), 1)
			assert_string_contains(_right_text(ex), str(why[str(clues[0])]), ex.id)
			for i in (ex.choices as Array).size():
				if i != int(ex.answer):
					for w: String in why.values():
						assert_false(ExerciseCheck.item_text(ex.choices[i]).contains(w), "%s: a wrong choice names a clue" % ex.id)


func test_private_things_stay_private() -> void:
	for ex in _all("public_private"):
		for i in (ex.items as Array).size():
			assert_eq(int(ex.answer[i]), 1 if PRIVATE.has(str(ex.items[i])) else 0, "%s: %s" % [ex.id, ex.items[i]])
		assert_eq((ex.items as Array).size(), [0, 4, 5, 6][int(ex._level)])


## What every example of one group shares, and no example of the other group has.
func test_the_computer_learns_what_the_examples_share() -> void:
	for ex in _all("ai_guess"):
		var examples: Array = ex.data.examples
		var first := str(examples[0][2])
		var found := -1
		var value := ""
		for f in [0, 1]:   # 0: the shape, 1: the colour
			var v := str(examples[0][f])
			var ok := true
			for e: Array in examples:
				if (str(e[2]) == first) != (str(e[f]) == v):
					ok = false
			if ok:
				found = f
				value = v
		assert_ne(found, -1, "%s: one feature decides" % ex.id)
		var other := ""
		for e: Array in examples:
			if str(e[2]) != first:
				other = str(e[2])
		var want := first if str(ex.data.new[found]) == value else other
		assert_eq(_right_text(ex), want, "%s: %s" % [ex.id, ex.data])


# --- Art -------------------------------------------------------------------------------------------------------------

func test_angles_round_a_point() -> void:
	for ex in _all("tile_angles"):
		var n := int(ex.data.sides)
		var angle := 180.0 * (n - 2) / n
		match int(ex._level):
			1:
				assert_eq(_value(ex), 360.0 / angle, ex.id)
			2:
				assert_eq(_value(ex), angle, ex.id)
			_:
				if str(ex.type) == "number":
					assert_eq(_value(ex), 360.0 - 2.0 * 135.0, ex.id)
				else:
					assert_eq(ex.answer, is_equal_approx(fposmod(360.0, angle), 0.0), "%s: %d sides" % [ex.id, n])


func test_rotational_symmetry() -> void:
	for ex in _all("turn_angle"):
		var order := int(ex.data.order)
		if ex.has("picture"):
			assert_eq(int(ex.picture.order), order)
		assert_eq(_value(ex), 360.0 / order if int(ex._level) == 2 else float(order), ex.id)


func test_prints_go_lightest_first() -> void:
	for ex in _all("print_order"):
		var last := 2.0
		for i: Variant in ex.answer:
			var c: Color = SchoolPictureArts.COLOURS[str(ex.items[int(i)])]
			assert_lt(c.get_luminance(), last, "%s: %s is darker than the ink before" % [ex.id, ex.items[int(i)]])
			last = c.get_luminance()
		assert_eq((ex.items as Array).size(), [0, 3, 4, 5][int(ex._level)])


func test_numbers_in_nature() -> void:
	var fib: Array[int] = [1, 1]
	while fib.size() < 16:
		fib.append(fib[-1] + fib[-2])
	for ex in _all("nature_numbers"):
		match int(ex._level):
			1:
				var run: Array = ex.data.run
				assert_eq(_value(ex), float(int(run[-1]) + int(run[-2])), ex.id)
				assert_true(fib.has(int(run[-1])), ex.id)
			2:
				var at := fib.find(int(ex.data.spirals), 2)
				assert_eq(_value(ex), float(fib[at + 1]), ex.id)
			_:
				assert_eq(_value(ex), 360.0 / int(ex.data.stones), ex.id)


func test_the_steps_of_looking_at_art() -> void:
	for ex in _all("critique_step"):
		for i in (ex.items as Array).size():
			assert_eq(str(ex.groups[int(ex.answer[i])]), STEPS[str(ex.items[i])], "%s: %s" % [ex.id, ex.items[i]])


func test_the_principles_of_design() -> void:
	for ex in _all("principle_spot"):
		assert_eq(_right_text(ex), PRINCIPLE_WORDS[str(ex.picture.show)], ex.id)


# --- Music -----------------------------------------------------------------------------------------------------------

## A note name's pitch class ("F sharp" 6, "B flat" 10).
func _named(n: String) -> int:
	var s := int(SEMIS[n.left(1)])
	if n.ends_with("sharp"):
		s += 1
	elif n.ends_with("flat"):
		s -= 1
	return posmod(s, 12)


func _scale(key: String) -> Array[String]:
	var steps: Array[int] = [2, 2, 1, 2, 2, 2, 1]
	var at := _named(key.replace("b", " flat"))
	var li := LETTERS.find(key.left(1))
	var out: Array[String] = []
	for i in 8:
		var letter := LETTERS[(li + i) % 7]
		var diff := posmod(at - int(SEMIS[letter]) + 6, 12) - 6
		out.append(letter + (" sharp" if diff == 1 else (" flat" if diff == -1 else "")))
		if i < 7:
			at = posmod(at + steps[i], 12)
	return out


func test_major_scales() -> void:
	for ex in _all("scale_notes"):
		var key := str(ex.data.key)
		var names := _scale(key)
		var changed: Array[String] = []
		for n in names.slice(0, 7):
			if n.contains(" "):
				changed.append(n)
		assert_eq(G6ArtsGen._scale_names(key), names, key)
		if ex.data.has("degree"):
			assert_eq(_right_text(ex), names[int(ex.data.degree)], ex.id)
		elif ex.data.has("step"):
			assert_eq(_value(ex), float(posmod(_named(names[int(ex.data.step) + 1]) - _named(names[int(ex.data.step)]), 12)), ex.id)
		elif str(ex.type) == "number":
			assert_eq(_value(ex), float(changed.size()), ex.id)
		elif ex.has("picture"):
			assert_eq(_right_text(ex), key.replace("b", " flat") + " major", ex.id)
		else:
			for c in changed:
				assert_string_contains(_right_text(ex), c, ex.id)


func test_intervals() -> void:
	for ex in _all("interval_size"):
		var low := str(ex.data.low)
		var high := str(ex.data.high)
		var steps := LETTERS.find(high.left(1)) - LETTERS.find(low.left(1)) + 7 * (int(high.right(1)) - int(low.right(1)))
		var name := INTERVALS[steps]
		var said := _right_text(ex).trim_prefix("a ").trim_prefix("an ")
		assert_true(said == name or (said == "step" and name == "second"), "%s: %s to %s is a %s, not %s" % [ex.id, low,
			high, name, said])
		if ex.has("sound"):
			assert_eq(ex.sound.notes, [low + ":2", high + ":2"])
		elif str(ex.picture.kind) == "stave":
			assert_eq(ex.picture.notes, [low, high])
		else:
			assert_eq(ex.picture.mark, [low, high])


func test_the_twelve_bar_blues() -> void:
	for ex in _all("blues_bar"):
		if int(ex._level) == 3:
			assert_eq(_value(ex), float(12 * int(ex.data.times) * int(ex.data.beats)), ex.id)
			continue
		var key := str(ex.data.key)
		var four := LETTERS[(LETTERS.find(key) + 3) % 7]
		var five := LETTERS[(LETTERS.find(key) + 4) % 7]
		var bars: Array[String] = [key, key, key, key, four, four, key, key, five, four, key, key]
		assert_eq(_right_text(ex), bars[int(ex.data.bar)], ex.id)


func test_the_periods_of_music() -> void:
	for ex in _all("music_period"):
		var y := int(ex.data.year)
		var want := "Medieval" if y < 1400 else ("Renaissance" if y < 1600 else ("Baroque" if y < 1750 else "Classical"))
		assert_eq(_right_text(ex), want, "%s: %d" % [ex.id, y])
		assert_false((y > 1390 and y < 1410) or (y > 1590 and y < 1610) or (y > 1740 and y < 1760), "%s: not near a border" % ex.id)


func test_off_beat_claps() -> void:
	for ex in _all("offbeat_rhythm"):
		var p := str(ex.data.pattern)
		assert_true(p.begins_with("x") and p.length() == 8, p)
		var off := 0
		for i in p.length():
			if p[i] == "x" and i % 2 == 1:
				off += 1
		assert_gt(off, 0, "%s: syncopated" % p)
		if int(ex._level) == 1:
			assert_eq(_value(ex), float(off), ex.id)
		else:
			assert_eq(str(ex.sound.pattern), p)
			assert_string_contains(str(ex.explain), "box", ex.id)


func _pitch(n: String) -> int:
	var m := RegEx.create_from_string("^([A-G])([#b]?)([2-6])").search(n)
	return 12 * int(m.get_string(3)) + int(SEMIS[m.get_string(1)]) + (1 if m.get_string(2) == "#" else (-1 if m.get_string(2) == "b" else 0))


func test_variations_are_heard() -> void:
	var said := {"rhythm": "the rhythm (the notes' lengths)", "higher": "the pitch: the same tune higher",
		"minor": "the harmony: major to minor", "backwards": "the order: it goes backwards"}
	for ex in _all("variation_change"):
		var notes: Array = ex.sound.notes
		var gap := notes.find("-")
		var theme: Array = notes.slice(0, gap)
		var variation: Array = notes.slice(gap + 1)
		var tp: Array = theme.map(func(n: String) -> int: return _pitch(n))
		var vp: Array = variation.map(func(n: String) -> int: return _pitch(n))
		var change := ""
		if vp == tp and variation != theme:
			change = "rhythm"
		elif vp == tp.map(func(p: int) -> int: return p + 12):
			change = "higher"
		else:
			var rev := tp.duplicate()
			rev.reverse()
			if vp == rev:
				change = "backwards"
			else:
				var minor := true
				for i in tp.size():
					var d := int(vp[i]) - int(tp[i])
					minor = minor and (d == 0 or (d == -1 and posmod(int(tp[i]), 12) == 4))
				change = "minor" if minor and vp != tp else "?"
		assert_eq(_right_text(ex), said.get(change, "?"), "%s: %s then %s" % [ex.id, theme, variation])


func test_chords_fit_the_melody() -> void:
	var chords := {"C": {"C": ["C", "E", "G"], "F": ["F", "A", "C"], "G": ["G", "B", "D"]},
		"G": {"G": ["G", "B", "D"], "C": ["C", "E", "G"], "D": ["D", "F#", "A"]}}
	for ex in _all("chord_fit"):
		var table: Dictionary = chords[str(ex.data.key)]
		var fits: Array[String] = []
		for c: String in table:
			var all_in := true
			for n: String in ex.data.notes:
				all_in = all_in and (table[c] as Array).has(n)
			if all_in:
				fits.append(c)
		assert_eq(fits.size(), 1, "%s: one chord fits %s" % [ex.id, ex.data.notes])
		assert_eq(_right_text(ex), fits[0], ex.id)
		var shown: Array = ex.picture.notes
		assert_eq(shown.size(), (ex.data.notes as Array).size())


func test_instruments_of_the_world() -> void:
	for ex in _all("instrument_family"):
		var what := str(ex.data.instrument)
		match int(ex._level):
			1:
				assert_eq(_right_text(ex), SOUNDS_BY[FAMILY[what]], ex.id)
			2:
				assert_eq(_right_text(ex), FAMILY[what], ex.id)
			_:
				assert_eq(_right_text(ex), HOME[what], ex.id)


func test_sound_in_numbers() -> void:
	for ex in _all("sound_numbers"):
		var d: Dictionary = ex.data
		match int(ex._level):
			1:
				assert_eq(_value(ex), float(int(d.hz) * 2) if bool(d.up) else float(int(d.hz) / 2), ex.id)
			2:
				assert_eq(_value(ex), float(int(d.count) / int(d.seconds)), ex.id)
			_:
				assert_eq(_value(ex), float(int(d.seconds)) / 3.0, ex.id)
