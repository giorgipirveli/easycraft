extends GutTest
## Owner #70 and #73: grade 4 computing, art and music generators (SchoolGen "g4a.<name>", core/school/gen/g4_arts_gen.gd).
## Every answer is worked out again here from the exercise's code, table, stave, sound, picture or prompt, with this
## test's own rules: an interpreter for the programs, the robot, the colour wheel, paint recipes, tones, note values,
## the stave's letters, steps and leaps, and who sings what in a round.

const GENS: Array[String] = ["event_turns", "if_else", "trace_variable", "plan_route", "table_query", "complement",
	"warm_cool", "mix_wheel", "tone_scale", "pixel_count", "which_print", "note_beats", "fill_the_bar", "count_the_bar",
	"name_the_note", "step_or_leap", "round_parts", "ostinato_count"]
const SEEDS := 60
const HEADINGS: Array[String] = ["north", "east", "south", "west"]
## The painters' wheel (this test's own): opposite colours are 6 apart.
const WHEEL: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red", "red-purple", "purple",
	"blue-purple", "blue", "blue-green", "green", "yellow-green"]
const WARM: Array[String] = ["red", "orange", "yellow", "red-orange", "yellow-orange"]
const COOL: Array[String] = ["blue", "green", "purple", "blue-green", "blue-purple"]
## Recipes (this test's own): drops of each paint.
const RECIPE := {"orange": {"red": 1, "yellow": 1}, "green": {"yellow": 1, "blue": 1}, "purple": {"red": 1, "blue": 1},
	"red-orange": {"red": 2, "yellow": 1}, "yellow-orange": {"yellow": 2, "red": 1}, "yellow-green": {"yellow": 2, "blue": 1},
	"blue-green": {"blue": 2, "yellow": 1}, "blue-purple": {"blue": 2, "red": 1}, "red-purple": {"red": 2, "blue": 1}}
## How light each tone is (bigger is lighter).
const LIGHT := {"white": 10, "light grey": 8, "grey": 5, "dark grey": 3, "black": 0, "pink": 8, "red": 5, "dark red": 2,
	"light blue": 8, "blue": 5, "dark blue": 2, "light green": 8, "green": 5, "dark green": 2, "lilac": 8, "purple": 5,
	"dark purple": 2}
const BEATS := {"semibreve": 4, "dotted minim": 3, "minim": 2, "crotchet": 1, "quavers": 1, "rest": 1}
const ONE_NOTE := {"a crotchet": 1, "a minim": 2, "a dotted minim": 3, "a semibreve": 4}
const CLAPS := {"crotchet": "x-", "quavers": "xx", "rest": "--"}
const LETTERS := "CDEFGAB"


func _all(gen: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make("g4a." + gen, s, level)
			ex["_level"] = level
			out.append(ex)
	return out


func _right(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func test_every_generator_exists_and_is_valid() -> void:
	for gen in GENS:
		assert_true(SchoolGen.exists("g4a." + gen), gen)
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
		if id.begins_with("g4a."):
			names[id.trim_prefix("g4a.")] = true
	assert_eq(names.size(), GENS.size(), "every g4a generator is tested here")


# --- Computing -------------------------------------------------------------------------------------------------------

func test_event_turns() -> void:
	for ex in _all("event_turns"):
		var facing := str(ex.data.start)
		for t: String in ex.data.taps:
			facing = HEADINGS[(HEADINGS.find(facing) + {"LEFT": 3, "RIGHT": 1, "BACK": 2}[t]) % 4]
		assert_eq(_right(ex), facing, ex.id)
		assert_string_contains(str(ex.prompt), "faces %s" % ex.data.start, ex.id)
		assert_string_contains(str(ex.prompt), ", then ".join(ex.data.taps), ex.id)
		var lines: Array = ex.picture.lines
		assert_true(lines.has("WHEN LEFT is tapped") and lines.has("  TURN LEFT"), ex.id)
		if (ex.data.taps as Array).has("BACK"):
			assert_true(lines.has("WHEN BACK is tapped"), ex.id)


## A tiny interpreter for the programs in the code pictures: SET, CHANGE … BY, REPEAT n TIMES, IF (>, <, =, ≥), ELSE,
## SAY. Returns {vars, said}.
func _run(lines: Array) -> Dictionary:
	var state := {"vars": {}, "said": []}
	_block(lines, 0, lines.size(), 0, state)
	return state


func _depth(line: String) -> int:
	return int((line.length() - line.lstrip(" ").length()) / 2.0)


## The lines from `from` up to (not including) `to` at `depth`, their inner lines one deeper.
func _block(lines: Array, from: int, to: int, depth: int, state: Dictionary) -> void:
	var i := from
	while i < to:
		var line := str(lines[i]).strip_edges()
		var inner_end := i + 1
		while inner_end < to and _depth(str(lines[inner_end])) > depth:
			inner_end += 1
		var words := line.split(" ")
		match words[0]:
			"SET":
				state.vars[words[1]] = int(words[3])
			"CHANGE":
				state.vars[words[1]] = int(state.vars.get(words[1], 0)) + int(words[3])
			"SAY":
				(state.said as Array).append(line.substr(4))
			"REPEAT":
				for k in int(words[1]):
					_block(lines, i + 1, inner_end, depth + 1, state)
			"IF":
				var v := int(state.vars[words[1]])
				var n := int(words[3])
				var yes: bool = {">": v > n, "<": v < n, "=": v == n, "≥": v >= n}[words[2]]
				var else_at := -1
				var else_end := inner_end
				if inner_end < to and str(lines[inner_end]).strip_edges() == "ELSE" and _depth(str(lines[inner_end])) == depth:
					else_at = inner_end
					else_end = else_at + 1
					while else_end < to and _depth(str(lines[else_end])) > depth:
						else_end += 1
				if yes:
					_block(lines, i + 1, inner_end, depth + 1, state)
				elif else_at >= 0:
					_block(lines, else_at + 1, else_end, depth + 1, state)
				inner_end = else_end
		i = inner_end


func test_the_interpreter_runs_a_program() -> void:
	var r := _run(["SET score TO 2", "REPEAT 3 TIMES", "  CHANGE score BY 4", "CHANGE score BY -1", "IF score > 13",
		"  SAY big", "ELSE", "  IF score = 13", "    SAY thirteen", "  ELSE", "    SAY small"])
	assert_eq(int(r.vars.score), 13)
	assert_eq(r.said, ["thirteen"])


func test_if_else() -> void:
	for ex in _all("if_else"):
		var r := _run(ex.picture.lines)
		assert_eq((r.said as Array).size(), 1, "%s: one SAY runs" % ex.id)
		assert_eq(_right(ex), str(r.said[0]), ex.id)
		for i in (ex.choices as Array).size():
			if i != int(ex.answer):
				assert_ne(str(ex.choices[i]), str(r.said[0]), ex.id)


func test_trace_variable() -> void:
	for ex in _all("trace_variable"):
		var r := _run(ex.picture.lines)
		assert_eq(NumberAnswer.value(str(ex.answer)), float(r.vars[str(ex.data.var)]), "%s: %s" % [ex.id, ex.picture.lines])
		assert_gte(int(r.vars[str(ex.data.var)]), 0, ex.id)
		assert_string_contains(str(ex.prompt), "What is %s" % ex.data.var, ex.id)


## "FORWARD 2, TURN LEFT" as commands.
func _program(text: String) -> Array:
	var out: Array = []
	for part in text.split(", "):
		var w := part.strip_edges()
		if w == "TURN LEFT" or w == "TURN RIGHT":
			out.append("L" if w == "TURN LEFT" else "R")
		elif w == "FORWARD":
			out.append("F")
		elif w.begins_with("FORWARD "):
			for k in int(w.substr(8)):
				out.append("F")
	return out


## This test's own robot: the squares it stands on, or [] when it bumps.
func _walk(b: Dictionary, program: Array) -> Array:
	var pos := Vector2i(int(b.start[0]), int(b.start[1]))
	var h := ["N", "E", "S", "W"].find(str(b.facing))
	var moves: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	var walls := {}
	for w: Variant in b.get("walls", []):
		walls[Vector2i(int(w[0]), int(w[1]))] = true
	var path: Array = [pos]
	for c: Variant in program:
		if str(c) == "L":
			h = (h + 3) % 4
		elif str(c) == "R":
			h = (h + 1) % 4
		else:
			pos += moves[h]
			if pos.x < 0 or pos.y < 0 or pos.x >= int(b.cols) or pos.y >= int(b.rows) or walls.has(pos):
				return []
			path.append(pos)
	return path


func _shortest_length(b: Dictionary) -> int:
	var gems: Array[Vector2i] = []
	for g: Variant in b.get("gems", []):
		gems.append(Vector2i(int(g[0]), int(g[1])))
	var start := [Vector2i(int(b.start[0]), int(b.start[1])), ["N", "E", "S", "W"].find(str(b.facing)), 0]
	var seen := {str(start): true}
	var frontier: Array = [start]
	var goal := Vector2i(int(b.goal[0]), int(b.goal[1]))
	for steps in 30:
		var next: Array = []
		for st: Array in frontier:
			if st[0] == goal and int(st[2]) == (1 << gems.size()) - 1:
				return steps
			for c in ["F", "L", "R"]:
				var b2 := b.duplicate()
				b2.start = [st[0].x, st[0].y]
				b2.facing = ["N", "E", "S", "W"][int(st[1])]
				var p := _walk(b2, [c])
				if p.is_empty():
					continue
				var pos: Vector2i = p[-1]
				var h := int(st[1])
				if c == "L":
					h = (h + 3) % 4
				elif c == "R":
					h = (h + 1) % 4
				var mask := int(st[2])
				if gems.has(pos):
					mask |= 1 << gems.find(pos)
				var s2 := [pos, h, mask]
				if not seen.has(str(s2)):
					seen[str(s2)] = true
					next.append(s2)
		frontier = next
	return -1


func test_plan_route() -> void:
	for ex in _all("plan_route"):
		var b: Dictionary = ex.board
		assert_gte((b.gems as Array).size(), 1, "%s: gems to plan for" % ex.id)
		var prog := _program(str(ex.explain).get_slice(": ", 1).trim_suffix("."))
		var path := _walk(b, prog)
		assert_false(path.is_empty(), "%s: the worked answer never bumps" % ex.id)
		if path.is_empty():
			continue
		assert_eq(path[-1], Vector2i(int(b.goal[0]), int(b.goal[1])), "%s: it ends on the flag" % ex.id)
		for g: Variant in b.gems:
			assert_true(path.has(Vector2i(int(g[0]), int(g[1]))), "%s: it picks up %s" % [ex.id, g])
		assert_eq(prog.size(), _shortest_length(b), "%s: the worked answer is a shortest program" % ex.id)
		if ex.has("max"):
			assert_eq(int(ex.max), prog.size(), ex.id)
			assert_string_contains(str(ex.prompt), "at most %d" % int(ex.max), ex.id)


func test_table_query() -> void:
	var sort_q := RegEx.create_from_string("^Sort the table by (\\w+), (biggest|smallest) first")
	var filter_q := RegEx.create_from_string("(?i)keep only the rows where (\\w+) is (more than )?(\\w+)")
	var then_q := RegEx.create_from_string("then sort by (\\w+), (biggest|smallest) first")
	for ex in _all("table_query"):
		var rows: Array = ex.picture.rows
		var head: Array = rows[0]
		var data: Array = rows.slice(1)
		var kept: Array = data.duplicate()
		var f := filter_q.search(str(ex.prompt))
		if f != null:
			var col := _col(head, f.get_string(1))
			kept = data.filter(func(r: Array) -> bool:
				return int(r[col]) > int(f.get_string(3)) if f.get_string(2) != "" else str(r[col]) == f.get_string(3))
		var s := sort_q.search(str(ex.prompt))
		if s == null:
			s = then_q.search(str(ex.prompt))
		if s == null:
			assert_eq(int(ex.answer), kept.size(), "%s: rows left" % ex.id)
			assert_gt(kept.size(), 0, ex.id)
			continue
		var col := _col(head, s.get_string(1))
		var best: Array = kept[0]
		for r: Array in kept:
			if (s.get_string(2) == "biggest" and int(r[col]) > int(best[col])) or (s.get_string(2) == "smallest" and int(r[col]) < int(best[col])):
				best = r
		assert_eq(_right(ex), str(best[0]), "%s: %s" % [ex.id, ex.prompt])
		var ties := kept.filter(func(r: Array) -> bool: return int(r[col]) == int(best[col])).size()
		assert_eq(ties, 1, "%s: one row comes first" % ex.id)


func _col(head: Array, name: String) -> int:
	for i in head.size():
		if str(head[i]).to_lower() == name.to_lower():
			return i
	return -1


# --- Art -------------------------------------------------------------------------------------------------------------

func _opposite(c: String) -> String:
	return WHEEL[(WHEEL.find(c) + 6) % 12]


func test_complement() -> void:
	var of_q := RegEx.create_from_string("(?:opposite|colour of) ([a-z-]+)(?: on the colour wheel)?[?]")
	for ex in _all("complement"):
		var m := of_q.search(str(ex.prompt))
		if m != null:
			assert_eq(_right(ex), _opposite(m.get_string(1)), "%s: %s" % [ex.id, ex.prompt])
			if ex.has("picture") and ex.picture.has("blank"):
				assert_eq(ex.picture.blank, [_right(ex)], ex.id)
			continue
		for i in (ex.choices as Array).size():   # which two are complementary
			var pair := str(ex.choices[i]).split(" and ")
			assert_eq(_opposite(pair[0]) == pair[1], i == int(ex.answer), "%s: %s" % [ex.id, ex.choices[i]])


func test_warm_cool() -> void:
	for ex in _all("warm_cool"):
		for i in (ex.items as Array).size():
			var c := str(ex.items[i])
			assert_true(WARM.has(c) or COOL.has(c), "%s: %s is clearly warm or cool" % [ex.id, c])
			assert_eq(int(ex.answer[i]), 0 if WARM.has(c) else 1, "%s: %s" % [ex.id, c])


func test_mix_wheel() -> void:
	for ex in _all("mix_wheel"):
		var recipe: Dictionary = RECIPE[str(ex.target)]
		assert_true(ExerciseCheck.is_right(ex, recipe), "%s: %s" % [ex.id, ex.target])
		for paint: String in ["red", "yellow", "blue", "white", "black"]:
			var named := RegEx.create_from_string("\\b%s\\b" % paint).search(str(ex.explain).get_slice(":", str(ex.explain).count(":"))) != null
			assert_eq(named, recipe.has(paint), "%s: %s" % [ex.id, ex.explain])
		if int(ex._level) == 2:
			var parts := (RECIPE[str(ex.target)] as Dictionary).keys()
			assert_string_contains(str(ex.prompt), "twice as much", ex.id)
			for p: String in parts:
				assert_string_contains(str(ex.prompt), p, ex.id)


func test_tone_scale() -> void:
	for ex in _all("tone_scale"):
		var in_order: Array = []
		for i: int in ex.answer:
			in_order.append(str(ex.items[i]))
		var dark_first := str(ex.prompt).contains("darkest first")
		for i in range(1, in_order.size()):
			var a := int(LIGHT[in_order[i - 1]])
			var b := int(LIGHT[in_order[i]])
			assert_true(a < b if dark_first else a > b, "%s: %s" % [ex.id, in_order])
		assert_eq(ex.picture.items, ex.items, "%s: the patches in the items' order" % ex.id)


func test_pixel_count() -> void:
	var dims := RegEx.create_from_string("(\\d+) pixels wide and (\\d+) tall")
	var colour := RegEx.create_from_string("How many (\\w+) pixels")
	for ex in _all("pixel_count"):
		var d := dims.search(str(ex.prompt))
		if d != null:
			assert_eq(int(ex.answer), 2 * int(d.get_string(1)) * 2 * int(d.get_string(2)), ex.id)
			continue
		var rows: Array = ex.picture.rows
		var c := colour.search(str(ex.prompt))
		if c == null:
			assert_eq(int(ex.answer), rows.size() * str(rows[0]).length(), ex.id)
			continue
		var letter := ""
		for k: String in ex.picture.key:
			if str(ex.picture.key[k]) == c.get_string(1):
				letter = k
		var n := 0
		for r: String in rows:
			n += r.count(letter)
		assert_eq(int(ex.answer), n, ex.id)
		assert_gt(n, 0, ex.id)


func test_which_print() -> void:
	for ex in _all("which_print"):
		var block: Dictionary = ex.picture.items[0]
		assert_eq([str(block.on), str(block.flip)], ["block", "mirror"], ex.id)
		for i in (ex.choices as Array).size():
			var it: Dictionary = ex.choices[i].picture.items[0]
			assert_eq(str(it.on), "paper", ex.id)
			# a print is the block's mirror image: the mirrored letters come out the right way round
			var right := str(it.text) == str(block.text) and str(it.get("flip", "none")) == "none"
			assert_eq(right, i == int(ex.answer), "%s: choice %d %s" % [ex.id, i, it])


# --- Music -----------------------------------------------------------------------------------------------------------

func test_note_beats() -> void:
	for ex in _all("note_beats"):
		var n := 0
		for b: String in ex.picture.beats:
			n += int(BEATS[b])
		assert_eq(int(ex.answer), n, ex.id)


func test_fill_the_bar() -> void:
	for ex in _all("fill_the_bar"):
		var have := 0
		for b: String in ex.picture.beats:
			have += int(BEATS[b])
		var per_bar := int(str(ex.picture.time).get_slice("/", 0))
		var missing := per_bar - have
		assert_gt(missing, 0, "%s: the bar is not full" % ex.id)
		if str(ex.type) == "number":
			assert_eq(int(ex.answer), missing, ex.id)
		else:
			assert_eq(int(ONE_NOTE[_right(ex)]), missing, "%s: %s" % [ex.id, ex.prompt])
			assert_string_contains(str(ex.prompt), str(ex.picture.time), ex.id)


func test_count_the_bar() -> void:
	for ex in _all("count_the_bar"):
		var lows: Array[int] = []
		var notes: Array = ex.sound.notes
		for i in notes.size():
			if int(str(notes[i]).right(1)) <= 3:
				lows.append(i)
		var gap := lows[1] - lows[0]
		for k in range(1, lows.size()):
			assert_eq(lows[k] - lows[k - 1], gap, "%s: every bar as long" % ex.id)
		assert_eq(notes.size() % gap, 0, ex.id)
		var right := _right(ex)
		if right.begins_with("a "):
			assert_eq(right, "a march" if gap == 2 else "a waltz", ex.id)
		else:
			assert_eq(right, "%d beats" % gap, ex.id)


func test_name_the_note() -> void:
	# this test's own stave: the lines from the bottom are E4 G4 B4 D5 F5, the spaces F4 A4 C5 E5; C4 below on a ledger
	var stave := ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5"]
	for ex in _all("name_the_note"):
		var letters := ""
		for n: String in ex.picture.notes:
			assert_true(stave.has(n), "%s: %s is on the stave" % [ex.id, n])
			letters += n.left(1)
		assert_eq(_right(ex), letters, ex.id)
		for i in (ex.choices as Array).size():
			if i != int(ex.answer):
				assert_ne(str(ex.choices[i]), letters, ex.id)


func _apart(a: String, b: String) -> int:
	return absi(LETTERS.find(a.left(1)) + 7 * int(a.right(1)) - LETTERS.find(b.left(1)) - 7 * int(b.right(1)))


func test_step_or_leap() -> void:
	for ex in _all("step_or_leap"):
		var notes: Array = ex.data.notes
		for n: String in notes:
			assert_true(["C", "D", "E", "G", "A"].has(n.left(1)), "%s: %s is in the pentatonic scale" % [ex.id, n])
		var played: Array = (ex.sound.notes as Array).filter(func(n: String) -> bool: return n != "-")
		for i in notes.size():
			assert_eq(str(played[i]).get_slice(":", 0), str(notes[i]), "%s: the sound plays the notes" % ex.id)
		if str(ex.type) == "number":
			var leaps := 0
			for i in range(1, notes.size()):
				if _apart(str(notes[i - 1]), str(notes[i])) > 1:
					leaps += 1
			assert_eq(int(ex.answer), leaps, ex.id)
		else:
			assert_eq(_right(ex), "a step" if _apart(str(notes[0]), str(notes[1])) == 1 else "a leap", ex.id)


func test_round_parts() -> void:
	var q := RegEx.create_from_string("when group 1 sings line (\\d+), what does group (\\d+) sing")
	var n_q := RegEx.create_from_string("has (\\d+) lines. (\\d+) groups")
	for ex in _all("round_parts"):
		var m := q.search(str(ex.prompt))
		if m == null:
			var n := n_q.search(str(ex.prompt))
			assert_eq(int(ex.answer), int(n.get_string(1)) + int(n.get_string(2)) - 1, ex.id)
			continue
		var rows: Array = ex.picture.rows
		var col := (rows[1] as Array).find("line %s" % m.get_string(1))
		assert_gt(col, 0, "%s: group 1 sings it in the table" % ex.id)
		assert_eq(_right(ex), str(rows[int(m.get_string(2))][col]), ex.id)
		for r in range(1, rows.size()):   # every group sings the same lines, one line later than the group before
			for c in range(1, (rows[r] as Array).size()):
				var want := c - (r - 1)
				var cell := str(rows[r][c])
				if want >= 1 and cell.begins_with("line"):
					assert_eq(cell, "line %d" % want, ex.id)


func test_ostinato_count() -> void:
	for ex in _all("ostinato_count"):
		var pattern := ""
		for b: String in ex.picture.beats:
			pattern += str(CLAPS[b])
		assert_eq(pattern, str(ex.data.pattern), "%s: the picture is the pattern" % ex.id)
		var heard := str(ex.sound.pattern)
		assert_eq(heard.length() % pattern.length(), 0, ex.id)
		var times := int(heard.length() / float(pattern.length()))
		if str(ex.type) == "number":
			assert_eq(heard, pattern.repeat(times), ex.id)
			assert_eq(int(ex.answer), times, ex.id)
			continue
		var odd: Array[int] = []
		for k in times:
			if heard.substr(k * pattern.length(), pattern.length()) != pattern:
				odd.append(k + 1)
		assert_eq(odd.size(), 1, "%s: one time round is different" % ex.id)
		assert_ne(odd[0], 1, "%s: the first time round is the pattern" % ex.id)
		assert_eq(_right(ex), "the %s" % ["first", "second", "third", "fourth"][odd[0] - 1], ex.id)
