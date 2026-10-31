extends GutTest
## Owner #70 and #73: grade 3 computing, art and music generators (SchoolGen "g3a.<name>", core/school/gen/g3_arts_gen.gd).
## Every answer is worked out again here from the exercise's `data`, its sound or its picture, with this test's own
## tables and its own robot: the claps in a rhythm, which note is higher, a tune's shape, claps getting faster or slower,
## paint mixing, the next in a pattern, and programs of FORWARD, TURN LEFT and TURN RIGHT that take a robot to its flag.

const GENS: Array[String] = ["count_claps", "which_rhythm", "claps_in_rhythm", "copy_rhythm", "higher_lower",
	"tune_direction", "mix_paint",
	"faster_slower", "mix_colour", "next_in_pattern", "robot_moves", "code_robot", "loop_count", "fix_the_bug"]
const SEEDS := 60
const CLAPS := {"crotchet": "x-", "quavers": "xx", "rest": "--"}
## Paint (this test's own table): two primaries make a secondary; white makes a tint, black a shade.
const MIX := {"red+yellow": "orange", "yellow+red": "orange", "yellow+blue": "green", "blue+yellow": "green",
	"blue+red": "purple", "red+blue": "purple"}
const TINT := {"red": "pink", "blue": "light blue", "green": "light green", "purple": "lilac", "yellow": "cream",
	"orange": "light orange"}
## Recipes, this test's own: the paints each colour needs (in equal shares).
const PAINTS := {"orange": ["red", "yellow"], "green": ["yellow", "blue"], "purple": ["red", "blue"],
	"pink": ["red", "white"], "light blue": ["blue", "white"], "cream": ["yellow", "white"], "dark red": ["red", "black"],
	"dark blue": ["blue", "black"], "brown": ["red", "yellow", "blue"], "light green": ["yellow", "blue", "white"],
	"lilac": ["red", "blue", "white"], "dark green": ["yellow", "blue", "black"], "grey": ["white", "black"]}
const SHADE := {"red": "dark red", "blue": "dark blue", "green": "dark green", "purple": "dark purple",
	"orange": "dark orange"}
## The robot (RobotCheck's rules, this test's own code): headings N, E, S, W; y grows downwards.
const HEADINGS: Array[String] = ["N", "E", "S", "W"]
const MOVE: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]


func _all(gen: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level in [1, 2, 3]:
		for s in SEEDS:
			out.append(SchoolGen.make("g3a." + gen, s, level))
	return out


func _pattern(beats: Array) -> String:
	var out := ""
	for b: Variant in beats:
		out += str(CLAPS[str(b)])
	return out


func _pitch(note: String) -> float:
	return SchoolSound.frequency(note.split(":")[0])


func test_every_generator_exists_and_is_valid() -> void:
	for gen in GENS:
		assert_true(SchoolGen.exists("g3a." + gen), gen)
		for ex in _all(gen):
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [ex.id, ex])
			assert_true(ex.has("data") and str(ex.get("explain", "")) != "", "%s: data and a worked answer" % ex.id)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % ex.id)
			for c: Variant in ex.get("choices", []):
				if c is Dictionary:
					assert_eq(SchoolPicture.problem(c.picture), "", "%s: a choice's picture" % ex.id)


func test_count_claps() -> void:
	for ex in _all("count_claps"):
		assert_eq(str(ex.sound.pattern), _pattern(ex.data.beats), ex.id)
		assert_eq(int(ex.answer), str(ex.sound.pattern).count("x"), ex.id)


func test_which_rhythm() -> void:
	for ex in _all("which_rhythm"):
		for i in (ex.choices as Array).size():
			var heard := _pattern(ex.choices[i].picture.beats) == str(ex.sound.pattern)
			assert_eq(heard, i == int(ex.answer), "%s: choice %d" % [ex.id, i])


func test_claps_in_rhythm() -> void:
	for ex in _all("claps_in_rhythm"):
		assert_eq(ex.picture.beats, ex.data.beats, ex.id)
		assert_eq(int(ex.answer), _pattern(ex.picture.beats).count("x"), ex.id)


func test_copy_rhythm() -> void:
	for ex in _all("copy_rhythm"):
		var pattern := str(ex.sound.pattern)
		assert_eq(str(ex.type), "rhythm", ex.id)
		assert_eq(pattern, _pattern(ex.data.beats), ex.id)
		assert_eq(pattern.length(), 2 * (int(ex.level) + 1), "%s: two boxes a beat" % ex.id)
		assert_true(pattern.begins_with("x"), "%s: it starts with a clap you can hear" % ex.id)
		assert_eq(ExerciseCheck.answer_of(ex), pattern, ex.id)
		var boxes: Array[String] = []
		for i in pattern.length():
			if pattern[i] == "x":
				boxes.append(str(i + 1))
		assert_true(str(ex.explain).contains(boxes[-1] + "."), "%s: the worked answer names the boxes" % ex.id)


func test_higher_lower() -> void:
	for ex in _all("higher_lower"):
		var notes: Array = ex.sound.notes
		var a := _pitch(str(notes[0]))
		var b := _pitch(str(notes[-1]))
		var right := "higher" if b > a * 1.001 else "lower" if b < a * 0.999 else "the same"
		assert_eq(ExerciseCheck.answer_text(ex), right, ex.id)
		assert_eq(str(ex.data.first), str(notes[0]).split(":")[0], ex.id)
		assert_eq(str(ex.data.second), str(notes[-1]).split(":")[0], ex.id)


func _shape(notes: Array) -> String:
	var ups := 0
	var downs := 0
	var turn := ""
	for i in range(1, notes.size()):
		var d := _pitch(str(notes[i])) - _pitch(str(notes[i - 1]))
		if d > 0.0:
			ups += 1
			if downs > 0 and turn == "":
				turn = "down, then up"
		elif d < 0.0:
			downs += 1
			if ups > 0 and turn == "":
				turn = "up, then down"
	if downs == 0:
		return "up"
	if ups == 0:
		return "down"
	return turn


func test_tune_direction() -> void:
	for ex in _all("tune_direction"):
		var shape := _shape(ex.sound.notes)
		assert_eq(shape, str(ex.data.shape), ex.id)
		var right: Variant = ex.choices[int(ex.answer)]
		if right is Dictionary:   # pictures of shapes: the right one is the tune heard; the others other shapes
			assert_eq(right.picture.notes, ex.sound.notes, ex.id)
			for i in (ex.choices as Array).size():
				if i != int(ex.answer):
					assert_ne(_shape(ex.choices[i].picture.notes), shape, "%s: choice %d" % [ex.id, i])
		else:
			assert_eq(str(right), shape, ex.id)


func test_faster_slower() -> void:
	for ex in _all("faster_slower"):
		var gaps: Array = []   # half beats from each clap to the next
		var last := -1
		var pattern := str(ex.sound.pattern)
		for i in pattern.length():
			if pattern[i] == "x":
				if last >= 0:
					gaps.append(i - last)
				last = i
		assert_eq(gaps, Array(ex.data.gaps).map(func(g: Variant) -> int: return int(g)), ex.id)
		var first: int = gaps[0] + gaps[1]
		var end: int = gaps[-1] + gaps[-2]
		var right := "faster" if end < first else "slower" if end > first else "stay the same"
		assert_eq(ExerciseCheck.answer_text(ex), right, ex.id)
		for i in range(1, gaps.size()):   # steadily one way: never back
			if right == "faster":
				assert_lte(int(gaps[i]), int(gaps[i - 1]), ex.id)
			elif right == "slower":
				assert_gte(int(gaps[i]), int(gaps[i - 1]), ex.id)
			else:
				assert_eq(int(gaps[i]), int(gaps[0]), ex.id)


func test_mix_colour() -> void:
	for ex in _all("mix_colour"):
		var d: Dictionary = ex.data
		var a := str(d.a)
		var b := str(d.b)
		var made := str(MIX.get(a + "+" + b, TINT.get(a, "") if b == "white" else SHADE.get(a, "") if b == "black" else ""))
		if a == "all three":
			made = "brown"
		assert_ne(made, "", "%s: %s" % [ex.id, d])
		assert_eq(made, str(d.made), ex.id)
		var right := ExerciseCheck.answer_text(ex)
		match str(d.ask):
			"made":
				if right == "":   # a swatch picture
					assert_eq(ex.choices[int(ex.answer)].picture.items, [made], ex.id)
				else:
					assert_eq(right, made, ex.id)
			"pair":
				assert_eq(right, "%s and %s" % [a, b], ex.id)
			"add":
				assert_eq(right, b, ex.id)


func test_mix_paint() -> void:
	for ex in _all("mix_paint"):
		var target := str(ex.target)
		assert_eq(str(ex.type), "mix", ex.id)
		assert_true(PAINTS.has(target), "%s: %s" % [ex.id, target])
		var drops := {}
		for p: String in PAINTS[target]:
			drops[p] = 2
		assert_true(ExerciseCheck.is_right(ex, drops), "%s: two drops of each of %s" % [ex.id, PAINTS[target]])
		var one_short: Dictionary = drops.duplicate()
		one_short[PAINTS[target][0]] = 1
		assert_false(ExerciseCheck.is_right(ex, one_short), "%s: the shares must match" % ex.id)
		assert_eq((PAINTS[target] as Array).size(), 3 if int(ex.level) == 3 and target != "grey" else 2,
			"%s: level 1 two primaries, level 2 a paint and white or black, level 3 three paints (or grey)" % ex.id)


func test_next_in_pattern() -> void:
	for ex in _all("next_in_pattern"):
		var unit: Array = ex.data.unit
		var shown: Array = (ex.picture.items as Array).slice(0, -1)
		assert_eq(str(ex.picture.items[-1]), "?", ex.id)
		for i in shown.size():
			assert_eq(str(shown[i]), str(unit[i % unit.size()]), ex.id)
		assert_eq(ex.choices[int(ex.answer)].picture.items, [unit[shown.size() % unit.size()]], ex.id)
		for i in (ex.choices as Array).size():
			if i != int(ex.answer):
				assert_ne(ex.choices[i].picture.items, [unit[shown.size() % unit.size()]], ex.id)


## "FORWARD 2, TURN RIGHT, FORWARD" -> ["F", "F", "R", "F"] ([] when it is not a program).
func _program(text: String) -> Array:
	var out: Array = []
	for part in text.split(", "):
		var w := part.strip_edges()
		if w == "TURN LEFT" or w == "TURN RIGHT":
			out.append("L" if w == "TURN LEFT" else "R")
		elif w == "FORWARD":
			out.append("F")
		elif w.begins_with("FORWARD ") and w.substr(8).is_valid_int() and int(w.substr(8)) >= 2:
			for i in int(w.substr(8)):
				out.append("F")
		else:
			return []
	return out


## This test's own robot: {ok (false when it leaves the board or bumps into a wall), end, facing, gems (picked up)}.
func _run(b: Dictionary, program: Array) -> Dictionary:
	var at := Vector2i(int(b.start[0]), int(b.start[1]))
	var facing := HEADINGS.find(str(b.get("facing", "E")))
	var walls := {}
	for w: Variant in b.get("walls", []):
		walls[Vector2i(int(w[0]), int(w[1]))] = true
	var gems := {}
	for g: Variant in b.get("gems", []):
		gems[Vector2i(int(g[0]), int(g[1]))] = false
	for c: Variant in program:
		if str(c) == "L":
			facing = (facing + 3) % 4
		elif str(c) == "R":
			facing = (facing + 1) % 4
		else:
			at += MOVE[facing]
			if at.x < 0 or at.y < 0 or at.x >= int(b.cols) or at.y >= int(b.rows) or walls.has(at):
				return {"ok": false, "end": at, "facing": facing, "gems": 0}
			if gems.has(at):
				gems[at] = true
	var got := 0
	for g: Vector2i in gems:
		got += 1 if gems[g] else 0
	return {"ok": true, "end": at, "facing": facing, "gems": got}


func _reaches(b: Dictionary, program: Array) -> bool:
	var r := _run(b, program)
	return r.ok and r.end == Vector2i(int(b.goal[0]), int(b.goal[1])) and int(r.gems) == (b.get("gems", []) as Array).size()


func _same_board(pic: Dictionary, b: Dictionary) -> bool:
	for k: String in ["cols", "rows", "start", "facing", "goal", "walls", "gems"]:
		if str(pic.get(k, [])) != str(b.get(k, [])):
			return false
	return true


func test_robot_moves() -> void:
	for ex in _all("robot_moves"):
		var b: Dictionary = ex.data.board
		assert_true(_same_board(ex.picture, b), "%s: the picture is the board" % ex.id)
		for i in (ex.choices as Array).size():
			var program := _program(str(ex.choices[i]))
			assert_false(program.is_empty(), "%s: a program: %s" % [ex.id, ex.choices[i]])
			assert_eq(_reaches(b, program), i == int(ex.answer), "%s: %s" % [ex.id, ex.choices[i]])


func test_code_robot() -> void:
	for ex in _all("code_robot"):
		assert_eq(str(ex.type), "robot", ex.id)
		var b: Dictionary = ex.board
		var best: Array = ExerciseCheck.answer_of(ex)
		assert_true(_reaches(b, best), "%s: the worked answer reaches the flag" % ex.id)
		assert_eq(str(ex.explain), "A program that works: %s." % _said(best), ex.id)
		if int(ex.level) == 3:
			assert_eq(int(ex.max), best.size(), "%s: level 3 asks for a shortest program" % ex.id)
		if int(ex.level) >= 2:
			assert_false((b.get("walls", []) as Array).is_empty(), "%s: walls in the way" % ex.id)


## "FORWARD 2, TURN RIGHT" (this test's own words for a program).
func _said(program: Array) -> String:
	var out: Array[String] = []
	var run := 0
	for i in program.size() + 1:
		var c := str(program[i]) if i < program.size() else ""
		if c == "F":
			run += 1
			continue
		if run > 0:
			out.append("FORWARD" if run == 1 else "FORWARD %d" % run)
			run = 0
		if c != "":
			out.append("TURN LEFT" if c == "L" else "TURN RIGHT")
	return ", ".join(out)


func test_loop_count() -> void:
	for ex in _all("loop_count"):
		var d: Dictionary = ex.data
		var program: Array = (d.first as Array).duplicate()
		for i in int(d.repeats):
			program.append_array(d.body)
		assert_eq(int(ex.answer), program.count("F"), "%s: every FORWARD is a square" % ex.id)
		assert_true(str(ex.prompt).contains("repeat %d times [%s]" % [int(d.repeats), _said(d.body)]), ex.id)
		var pic: Dictionary = ex.picture
		var r := _run(pic, program)
		assert_true(r.ok, "%s: the loop stays on the picture" % ex.id)
		if pic.has("goal"):
			assert_eq(r.end, Vector2i(int(pic.goal[0]), int(pic.goal[1])), "%s: it ends on the flag" % ex.id)
		else:
			assert_eq(r.end, Vector2i(int(pic.start[0]), int(pic.start[1])), "%s: it ends where it started" % ex.id)


func test_fix_the_bug() -> void:
	for ex in _all("fix_the_bug"):
		var d: Dictionary = ex.data
		assert_false(_reaches(d.board, d.buggy), "%s: the buggy program misses" % ex.id)
		assert_true(_reaches(d.board, d.program), "%s: the right program" % ex.id)
		for i in (ex.choices as Array).size():   # "step 2: TURN RIGHT"
			var text := str(ex.choices[i])
			var step := int(text.get_slice(":", 0).substr(5)) - 1
			var fixed: Array = (d.buggy as Array).duplicate()
			fixed[step] = _program(text.get_slice(": ", 1))[0]
			assert_eq(_reaches(d.board, fixed), i == int(ex.answer), "%s: %s" % [ex.id, text])
