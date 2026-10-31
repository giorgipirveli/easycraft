class_name G4ArtsGen
extends RefCounted
## Owner #70 and #73 (research §6.4): grade 4 computing, art and music generators: SchoolGen "g4a.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a
## strategy, never the answer), a worked answer and `data` (tests/unit/test_g4_arts_gen.gd works every answer out again,
## reading the code, the table, the stave, the sound or the picture with its own rules).
## - Computing: event_turns (events: which way the robot faces after taps), if_else (a program's choice), trace_variable
##   (a score kept in a variable), plan_route (the "code the robot" type: every gem, then the flag), table_query (sort
##   and filter a table).
## - Art: complement (opposites on the colour wheel), warm_cool (the "sort" type), mix_wheel (the "mix" type: secondary
##   and tertiary colours), tone_scale (lightest to darkest), pixel_count (pixels and resolution), which_print (a relief
##   block prints its mirror image).
## - Music: note_beats (semibreves to quavers), fill_the_bar (time signatures), count_the_bar (hear oom-pah-pah),
##   name_the_note (the treble stave), step_or_leap (the pentatonic scale), round_parts (who sings what in a round),
##   ostinato_count (hear a pattern repeat).

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Juno"]
const HEADINGS: Array[String] = ["north", "east", "south", "west"]
const STEP := {"north": Vector2i(0, -1), "east": Vector2i(1, 0), "south": Vector2i(0, 1), "west": Vector2i(-1, 0)}

# --- Computing -------------------------------------------------------------------------------------------------------

## Events: WHEN LEFT is tapped the robot turns left, WHEN RIGHT is tapped it turns right (level 3: WHEN BACK is tapped
## it turns right twice). After the taps, which way does it face?
static func event_turns(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lines: Array[String] = ["WHEN LEFT is tapped", "  TURN LEFT", "WHEN RIGHT is tapped", "  TURN RIGHT"]
	var keys: Array[String] = ["LEFT", "RIGHT"]
	if level == 3:
		lines.append_array(["WHEN BACK is tapped", "  TURN RIGHT", "  TURN RIGHT"])
		keys.append("BACK")
	var start := HEADINGS[rng.randi_range(0, 3)]
	var taps: Array[String] = []
	for i in [rng.randi_range(1, 2), rng.randi_range(3, 4), rng.randi_range(3, 5)][level - 1]:
		taps.append(keys[rng.randi_range(0, keys.size() - 1)])
	if level == 3 and not taps.has("BACK"):
		taps[rng.randi_range(0, taps.size() - 1)] = "BACK"
	var facing := start
	var steps: Array[String] = []
	for t in taps:
		var turn := {"LEFT": 3, "RIGHT": 1, "BACK": 2}[t] as int
		facing = HEADINGS[(HEADINGS.find(facing) + turn) % 4]
		steps.append("%s: %s" % [t, facing])
	var who := NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var said := ", then ".join(taps)
	var wrongs: Array = HEADINGS.filter(func(h: String) -> bool: return h != facing)
	var ex := K.choice(rng, "The robot faces %s. %s taps %s. Which way does it face now?" % [start, who, said], facing,
		wrongs, "Each tap is an event: it runs only the steps under its own WHEN. Turn your own body for each tap.",
		"It starts facing %s. %s. It faces %s." % [start, ". ".join(steps), facing], {"kind": "code", "lines": lines})
	ex.data = {"start": start, "taps": taps}
	return ex


## IF … THEN … ELSE: which does the program say? Level 1: > or < well away from the number; level 2: also = and ≥, the
## value sometimes the number itself; level 3: an IF inside the ELSE (three answers).
static func if_else(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		return _nested_if(rng)
	# [variable, the conditions that make sense, what it says when true, when false, the numbers' range]
	var cases: Array = [["gems", [">", "≥"], "Open the gate", "Find more gems", 3, 12],
		["score", [">", "≥"], "Gold star!", "Keep going!", 10, 40],
		["apples", ["=", "≥"], "The basket is full", "Pick more apples", 4, 12],
		["temp", [">"], "Wear a T-shirt", "Wear a coat", 10, 25], ["temp", ["<"], "Wear a coat", "Wear a T-shirt", 10, 25]]
	if level == 1:   # only > and <
		cases = cases.filter(func(k: Array) -> bool: return (k[1] as Array).has(">") or (k[1] as Array).has("<"))
	var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
	var ops: Array = (c[1] as Array).filter(func(o: String) -> bool: return level > 1 or o == ">" or o == "<")
	var op := str(ops[rng.randi_range(0, ops.size() - 1)])
	c = [c[0], c[2], c[3], c[4], c[5]]
	var n := rng.randi_range(int(c[3]), int(c[4]))
	var v := n
	if level == 1 or rng.randi() % 2 == 0:
		while absi(v - n) < 2:
			v = rng.randi_range(maxi(0, n - 8), n + 8)
	var yes := _compare(v, op, n)
	var var_name := str(c[0])
	var lines: Array[String] = ["SET %s TO %d" % [var_name, v], "IF %s %s %d" % [var_name, op, n], "  SAY %s" % c[1],
		"ELSE", "  SAY %s" % c[2]]
	var said := str(c[1]) if yes else str(c[2])
	var ex := K.choice(rng, "What does this program say?", said, [str(c[2]) if yes else str(c[1])],
		"First put the number into the condition. Is it true or false? True runs the part under IF; false runs the ELSE part.",
		"%s is %d, and %d %s %d is %s, so it runs the %s part: it says “%s”." % [var_name, v, v, op, n,
			"true" if yes else "false", "IF" if yes else "ELSE", said], {"kind": "code", "lines": lines})
	ex.data = {"var": var_name, "value": v, "op": op, "n": n}
	return ex


static func _nested_if(rng: RandomNumberGenerator) -> Dictionary:
	var cases: Array = [["temp", "Hot", "Warm", "Cold", 25, 12, 0, 35], ["score", "Gold", "Silver", "Bronze", 80, 50, 0, 100],
		["gems", "Castle", "House", "Tent", 20, 10, 0, 30]]
	var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
	var hi := int(c[4])
	var lo := int(c[5])
	var v := rng.randi_range(int(c[6]), int(c[7]))
	var var_name := str(c[0])
	var lines: Array[String] = ["SET %s TO %d" % [var_name, v], "IF %s > %d" % [var_name, hi], "  SAY %s" % c[1], "ELSE",
		"  IF %s > %d" % [var_name, lo], "    SAY %s" % c[2], "  ELSE", "    SAY %s" % c[3]]
	var said := str(c[1]) if v > hi else (str(c[2]) if v > lo else str(c[3]))
	var how := "%d > %d is true: it says %s." % [v, hi, said] if v > hi else \
		"%d > %d is false, so it goes to ELSE. There %d > %d is %s: it says %s." % [v, hi, v, lo,
			"true" if v > lo else "false", said]
	var wrongs: Array = [str(c[1]), str(c[2]), str(c[3])].filter(func(w: String) -> bool: return w != said)
	var ex := K.choice(rng, "What does this program say?", said, wrongs,
		"Go down the program line by line. At each IF, is the condition true or false? Only one SAY runs.",
		"%s is %d. %s" % [var_name, v, how], {"kind": "code", "lines": lines})
	ex.data = {"var": var_name, "value": v, "hi": hi, "lo": lo}
	return ex


static func _compare(a: int, op: String, b: int) -> bool:
	match op:
		">":
			return a > b
		"<":
			return a < b
		"=":
			return a == b
		"≥":
			return a >= b
	return false


## A variable keeps a score: SET puts a value in, CHANGE … BY adds (or takes away), REPEAT runs its lines again.
## What is the variable at the end? Level 1: SET and adding; level 2: a loop and taking away; level 3: a second SET
## that replaces the value, or a loop of two changes.
static func trace_variable(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var vars: Array[String] = ["score", "gold", "gems", "stars", "jumps", "points"]
	var v := vars[rng.randi_range(0, vars.size() - 1)]
	var lines: Array[String] = []
	var work: Array[String] = []
	var value := 0
	match level:
		1:
			value = rng.randi_range(0, 10)
			lines.append("SET %s TO %d" % [v, value])
			work.append("%s starts at %d." % [v, value])
			for i in rng.randi_range(1, 2):
				var b := rng.randi_range(1, 10)
				lines.append("CHANGE %s BY %d" % [v, b])
				work.append("%d + %d = %d." % [value, b, value + b])
				value += b
		2:
			value = rng.randi_range(0, 10)
			var n := rng.randi_range(2, 4)
			var b := rng.randi_range(2, 5)
			lines.append_array(["SET %s TO %d" % [v, value], "REPEAT %d TIMES" % n, "  CHANGE %s BY %d" % [v, b]])
			work.append("%s starts at %d. The loop adds %d, %d times: %d × %d = %d, and %d + %d = %d." % [v, value, b, n, n, b,
				n * b, value, n * b, value + n * b])
			value += n * b
			var c := rng.randi_range(1, mini(value, 9))
			lines.append("CHANGE %s BY -%d" % [v, c])
			work.append("Then it takes away %d: %d − %d = %d." % [c, value, c, value - c])
			value -= c
		3:
			if rng.randi() % 2 == 0:
				var a := rng.randi_range(5, 20)
				var b := rng.randi_range(2, 9)
				var reset := rng.randi_range(0, 5)
				var n := rng.randi_range(2, 4)
				var d := rng.randi_range(2, 6)
				lines.append_array(["SET %s TO %d" % [v, a], "CHANGE %s BY %d" % [v, b], "SET %s TO %d" % [v, reset],
					"REPEAT %d TIMES" % n, "  CHANGE %s BY %d" % [v, d]])
				work.append("%d + %d = %d, but then SET puts %d in the box instead. The loop adds %d, %d times: %d × %d = %d, and %d + %d = %d." % [
					a, b, a + b, reset, d, n, n, d, n * d, reset, n * d, reset + n * d])
				value = reset + n * d
			else:
				var a := rng.randi_range(0, 10)
				var n := rng.randi_range(2, 4)
				var up := rng.randi_range(4, 9)
				var down := rng.randi_range(1, up - 1)
				lines.append_array(["SET %s TO %d" % [v, a], "REPEAT %d TIMES" % n, "  CHANGE %s BY %d" % [v, up],
					"  CHANGE %s BY -%d" % [v, down]])
				work.append("Each time round adds %d and takes away %d: %d more. %d times round: %d × %d = %d, and %d + %d = %d." % [
					up, down, up - down, n, n, up - down, n * (up - down), a, n * (up - down), a + n * (up - down)])
				value = a + n * (up - down)
	var ex := K.number("What is %s when the program ends?" % v, value,
		"Keep the variable's value on paper and change it line by line. SET replaces the value; CHANGE adds (a minus takes away).",
		" ".join(work), {"kind": "code", "lines": lines})
	ex.data = {"var": v, "lines": lines}
	return ex


## "Code the robot" planned: pick up every gem, then go to the flag. Level 1: one gem on open ground; level 2: two gems
## and a wall or two; level 3: two or three gems, walls, and at most a shortest program's number of commands.
static func plan_route(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var board := {}
	var best: Array[String] = []
	for _try in 400:
		board = _gem_board(rng, level)
		if board.is_empty():
			continue
		best = RobotCheck.shortest(board)
		if best.size() >= [3, 6, 8][level - 1] and best.size() <= [10, 14, 16][level - 1]:
			break
	if best.is_empty():
		board = {"cols": 4, "rows": 4, "start": [0, 3], "facing": "N", "goal": [3, 0], "gems": [[0, 0]]}
		best = RobotCheck.shortest(board)
	var gems := (board.gems as Array).size()
	var prompt := "Plan the robot's path: first to the gem, then to the flag. Then write the program." if gems == 1 else \
		"Plan the robot's path: which gem first? Pick up every gem, then go to the flag."
	if level == 3:
		prompt = "Plan the shortest way: pick up every gem, then go to the flag, in at most %d commands." % best.size()
	var ex := {"type": "robot", "prompt": prompt, "board": board,
		"hint": "Plan before you code: trace a path with your finger through the gems to the flag, then turn it into FORWARD, TURN LEFT and TURN RIGHT.",
		"explain": "A program that works: %s." % _said(best)}
	if level == 3:
		ex.max = best.size()
	ex.data = {"board": board}
	return ex


static func _gem_board(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var cols := rng.randi_range(4, 5) if level == 1 else rng.randi_range(5, 6)
	var rows := rng.randi_range(4, 5) if level == 1 else rng.randi_range(4, 6)
	var used := {}
	var pick := func() -> Vector2i:
		for _i in 50:
			var c := Vector2i(rng.randi_range(0, cols - 1), rng.randi_range(0, rows - 1))
			if not used.has(c):
				used[c] = true
				return c
		return Vector2i(-1, -1)
	var start: Vector2i = pick.call()
	var goal: Vector2i = pick.call()
	var b := {"cols": cols, "rows": rows, "start": [start.x, start.y], "goal": [goal.x, goal.y],
		"facing": RobotCheck.HEADINGS[rng.randi_range(0, 3)]}
	var gems: Array = []
	for i in [1, 2, rng.randi_range(2, 3)][level - 1]:
		var g: Vector2i = pick.call()
		gems.append([g.x, g.y])
	b.gems = gems
	if level >= 2:
		var walls: Array = []
		for i in (rng.randi_range(1, 2) if level == 2 else rng.randi_range(2, 4)):
			var w: Vector2i = pick.call()
			walls.append([w.x, w.y])
		b.walls = walls
	if RobotCheck.problem(b) != "":
		return {}
	return b


## Sort and filter a table (the base "table" picture). Level 1: sort by a number, who comes first; level 2: filter,
## how many rows are left; level 3: filter, then sort, who comes first.
static func table_query(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var themes: Array = [
		["Name", "Blocks", "Team", ["Tilly", "Zara", "Bram", "Mimi", "Juno"], ["red", "blue"], 5, 45],
		["Farm", "Cows", "Land", ["Hill Farm", "Oak Farm", "Mill Farm", "Pond Farm", "Sun Farm"], ["hills", "flat"], 3, 30],
		["Buddy", "Gems", "World", ["Pip", "Moss", "Fizz", "Bolt", "Lumo"], ["desert", "snow"], 2, 25]]
	var t: Array = themes[rng.randi_range(0, themes.size() - 1)]
	var names: Array = (t[3] as Array).duplicate()
	K.shuffle(rng, names)
	var numbers: Array = []
	while numbers.size() < 5:
		var v := rng.randi_range(int(t[5]), int(t[6]))
		if not numbers.has(v):
			numbers.append(v)
	var groups: Array = []
	for i in 5:
		groups.append(str((t[4] as Array)[rng.randi_range(0, 1)]))
	if not groups.has(str(t[4][0])) or not groups.has(str(t[4][1])):
		groups[rng.randi_range(0, 4)] = str(t[4][0]) if not groups.has(str(t[4][0])) else str(t[4][1])
	var rows: Array = [[str(t[0]), str(t[1]), str(t[2])]]
	for i in 5:
		rows.append([str(names[i]), str(numbers[i]), str(groups[i])])
	var picture := {"kind": "table", "rows": rows}
	var hint := "Do one step at a time: first cross out the rows the filter takes away, then put the rest in order."
	var ex := {}
	match level:
		1:
			var most := rng.randi() % 2 == 0
			var best := 0
			for i in 5:
				if (most and int(numbers[i]) > int(numbers[best])) or (not most and int(numbers[i]) < int(numbers[best])):
					best = i
			var wrongs: Array = names.filter(func(n: Variant) -> bool: return str(n) != str(names[best])).slice(0, 3)
			ex = K.choice(rng, "Sort the table by %s, %s first. Which %s comes first?" % [str(t[1]).to_lower(),
				"biggest" if most else "smallest", str(t[0]).to_lower()], str(names[best]), wrongs,
				"Sorting puts the rows in order. Look down the %s column for the %s number." % [str(t[1]), "biggest" if most else "smallest"],
				"Sorted by %s, %s first: %s has %s, so it comes first." % [str(t[1]).to_lower(), "biggest" if most else "smallest",
					names[best], numbers[best]], picture)
		2:
			var by_group := rng.randi() % 2 == 0
			var n := 0
			var prompt := ""
			var explain := ""
			if by_group:
				var g := str(groups[rng.randi_range(0, 4)])
				n = groups.count(g)
				prompt = "Filter the table: keep only the rows where %s is %s. How many rows are left?" % [str(t[2]).to_lower(), g]
				explain = "The rows with %s: %s. That is %d rows." % [g, ", ".join(_where(names, groups, g)), n]
			else:
				var sorted_numbers := numbers.duplicate()
				sorted_numbers.sort()
				var cut := int(sorted_numbers[rng.randi_range(0, 3)])
				var kept: Array = []
				for i in 5:
					if int(numbers[i]) > cut:
						kept.append(str(names[i]))
				n = kept.size()
				prompt = "Filter the table: keep only the rows where %s is more than %d. How many rows are left?" % [
					str(t[1]).to_lower(), cut]
				explain = "More than %d: %s. That is %d rows." % [cut, ", ".join(kept), n]
			ex = K.number(prompt, n, hint, explain, picture)
		3:
			var g := str(groups[rng.randi_range(0, 4)])
			var kept_i: Array = []
			for i in 5:
				if str(groups[i]) == g:
					kept_i.append(i)
			if kept_i.size() < 2:   # a filter that keeps one row sorts nothing: use the other group
				g = str(t[4][0]) if g == str(t[4][1]) else str(t[4][1])
				kept_i.clear()
				for i in 5:
					if str(groups[i]) == g:
						kept_i.append(i)
			var most := rng.randi() % 2 == 0
			var best: int = kept_i[0]
			for i: int in kept_i:
				if (most and int(numbers[i]) > int(numbers[best])) or (not most and int(numbers[i]) < int(numbers[best])):
					best = i
			var overall := 0   # the first in the whole table, a tempting wrong answer
			for i in 5:
				if (most and int(numbers[i]) > int(numbers[overall])) or (not most and int(numbers[i]) < int(numbers[overall])):
					overall = i
			var wrongs: Array = []
			if overall != best:
				wrongs.append(str(names[overall]))
			for i in 5:
				if i != best and wrongs.size() < 3 and not wrongs.has(str(names[i])):
					wrongs.append(str(names[i]))
			var kept_names: Array = []
			for i: int in kept_i:
				kept_names.append("%s (%s)" % [names[i], numbers[i]])
			ex = K.choice(rng, "Keep only the rows where %s is %s, then sort by %s, %s first. Which %s comes first?" % [
				str(t[2]).to_lower(), g, str(t[1]).to_lower(), "biggest" if most else "smallest", str(t[0]).to_lower()],
				str(names[best]), wrongs, hint, "The filter keeps %s. Of these, %s has the %s number." % [
					", ".join(kept_names), names[best], "biggest" if most else "smallest"], picture)
	ex.data = {"rows": rows, "level": level}
	return ex


static func _where(names: Array, groups: Array, g: String) -> Array[String]:
	var out: Array[String] = []
	for i in names.size():
		if str(groups[i]) == g:
			out.append(str(names[i]))
	return out


## A robot program in words: "FORWARD 2, TURN LEFT, FORWARD".
static func _said(program: Array) -> String:
	var out: Array[String] = []
	var run := 0
	for c: Variant in program + [""]:
		if str(c) == "F":
			run += 1
			continue
		if run > 0:
			out.append("FORWARD" if run == 1 else "FORWARD %d" % run)
			run = 0
		if str(c) != "":
			out.append(str(RobotCheck.WORDS[str(c)]))
	return ", ".join(out)


# --- Art -------------------------------------------------------------------------------------------------------------

const WHEEL6: Array[String] = ["yellow", "orange", "red", "purple", "blue", "green"]
const WHEEL12: Array[String] = ["yellow", "yellow-orange", "orange", "red-orange", "red", "red-purple", "purple",
	"blue-purple", "blue", "blue-green", "green", "yellow-green"]
const TERTIARY: Array[String] = ["yellow-orange", "red-orange", "red-purple", "blue-purple", "blue-green", "yellow-green"]
const WARM: Array[String] = ["red", "orange", "yellow", "red-orange", "yellow-orange"]
const COOL: Array[String] = ["blue", "green", "purple", "blue-green", "blue-purple"]
## The two paints of each secondary and tertiary colour (the first one twice for a tertiary).
const MADE_OF := {"orange": ["red", "yellow"], "green": ["yellow", "blue"], "purple": ["red", "blue"],
	"red-orange": ["red", "yellow"], "yellow-orange": ["yellow", "red"], "yellow-green": ["yellow", "blue"],
	"blue-green": ["blue", "yellow"], "blue-purple": ["blue", "red"], "red-purple": ["red", "blue"]}


## "Red-orange" (String.capitalize would say "Red Orange").
static func _cap(t: String) -> String:
	return t.left(1).to_upper() + t.substr(1)


static func _opposite(c: String) -> String:
	return WHEEL12[(WHEEL12.find(c) + 6) % 12]


## Complementary colours: opposite each other on the wheel. Level 1: read the wheel of 6; level 2: from memory;
## level 3: a tertiary's opposite on the wheel of 12, worked out from its neighbours.
static func complement(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1:
			var c := WHEEL6[rng.randi_range(0, 5)]
			var right := _opposite(c)
			var wrongs: Array = WHEEL6.filter(func(w: String) -> bool: return w != c and w != right)
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which colour is opposite %s on the colour wheel?" % c, right, wrongs.slice(0, 2),
				"Put your finger on %s, then go straight across the middle of the wheel." % c,
				"Straight across from %s is %s: they are complementary colours." % [c, right],
				{"kind": "colour_wheel", "size": 6, "mark": [c]})
			ex.data = {"colour": c}
		2:
			if rng.randi() % 2 == 0:
				var c := WHEEL6[rng.randi_range(0, 5)]
				var right := _opposite(c)
				var wrongs: Array = WHEEL6.filter(func(w: String) -> bool: return w != c and w != right)
				K.shuffle(rng, wrongs)
				ex = K.choice(rng, "What is the complementary colour of %s?" % c, right, wrongs.slice(0, 3),
					"Picture the colour wheel. A primary's opposite is the secondary made from the other two primaries.",
					"The complementary colour of %s is %s: opposite it on the colour wheel." % [c, right])
				ex.data = {"colour": c}
			else:
				var pairs: Array = [["red", "green"], ["yellow", "purple"], ["blue", "orange"]]
				var p: Array = pairs[rng.randi_range(0, 2)]
				var wrongs: Array = []
				for i in 6:   # neighbours on the wheel are never opposite
					var a := WHEEL6[i]
					var b := WHEEL6[(i + 1) % 6]
					wrongs.append("%s and %s" % [a, b])
				K.shuffle(rng, wrongs)
				var right := "%s and %s" % [p[0], p[1]]
				ex = K.choice(rng, "Which two are complementary colours?", right, wrongs.slice(0, 3),
					"Complementary colours sit opposite each other on the colour wheel, not side by side.",
					"%s and %s are complementary: opposite each other on the wheel." % [_cap(str(p[0])), p[1]])
				ex.data = {"pair": p}
		3:
			var c := TERTIARY[rng.randi_range(0, 5)]
			var right := _opposite(c)
			var i := WHEEL12.find(c)
			var n1 := WHEEL12[(i + 11) % 12]
			var n2 := WHEEL12[(i + 1) % 12]
			var wrongs: Array = TERTIARY.filter(func(w: String) -> bool: return w != c and w != right)
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which colour goes in the empty space, opposite %s?" % c, right, wrongs.slice(0, 3),
				"Find the colours on each side of %s. Their opposites sit on each side of the empty space." % c,
				"%s sits between %s and %s. Their opposites are %s and %s, and between them is %s." % [_cap(c), n1,
					n2, _opposite(n1), _opposite(n2), right],
				{"kind": "colour_wheel", "size": 12, "mark": [c], "blank": [right]})
			ex.data = {"colour": c}
	return ex


## Warm or cool (the "sort" type). Level 1: four of the primaries and secondaries; level 2: five with tertiaries;
## level 3: six.
static func warm_cool(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = ["red", "orange", "yellow", "blue", "green", "purple"] if level == 1 else WARM + COOL
	var items: Array = []
	for _try in 50:
		items = pool.duplicate()
		K.shuffle(rng, items)
		items = items.slice(0, level + 3)
		var warm := items.filter(func(c: String) -> bool: return WARM.has(c)).size()
		if warm >= 1 and warm < items.size():
			break
	var answer: Array = []
	var warm_list: Array[String] = []
	var cool_list: Array[String] = []
	for c: String in items:
		answer.append(0 if WARM.has(c) else 1)
		if WARM.has(c):
			warm_list.append(c)
		else:
			cool_list.append(c)
	var ex := {"type": "sort", "prompt": "Sort these colours: warm or cool?", "groups": ["warm", "cool"], "items": items,
		"answer": answer,
		"hint": "Warm colours are the colours of fire and the sun. Cool colours are the colours of water, ice and leaves.",
		"explain": "Warm: %s. Cool: %s." % [", ".join(warm_list), ", ".join(cool_list)]}
	ex.data = {"items": items}
	return ex


## "Mix the colour" on the wheel (the "mix" type). Level 1: a secondary from two primaries; level 2: a tertiary, its
## rule in the question; level 3: a tertiary from its name only.
static func mix_wheel(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var target := ""
	var prompt := ""
	var explain := ""
	if level == 1:
		target = ["orange", "green", "purple"][rng.randi_range(0, 2)]
		var p: Array = MADE_OF[target]
		prompt = "Mix %s, a secondary colour, in the bowl." % target
		explain = "%s is 1 %s and 1 %s." % [_cap(target), p[0], p[1]]
	else:
		target = TERTIARY[rng.randi_range(0, 5)]
		var p: Array = MADE_OF[target]
		var drops := {str(p[0]): 2, str(p[1]): 1}
		prompt = "Mix %s: twice as much %s as %s." % [target, p[0], p[1]] if level == 2 else \
			"Mix %s, a tertiary colour, in the bowl." % target
		explain = "%s is a tertiary colour: %s." % [_cap(target), ColourMix.words(drops)]
	var hint := "Which two primary colours sit on each side of it on the colour wheel?"
	if level > 1:
		hint = "Which primaries make it? The primary named first in a tertiary colour gets twice as many drops as the other one."
	var ex := {"type": "mix", "prompt": prompt, "target": target, "explain": explain, "hint": hint}
	ex.data = {"target": target}
	return ex


## A scale of tones (the "order" type): lightest to darkest (or darkest to lightest at level 3). Level 1: a tint, the
## colour and its shade; level 2: four greys; level 3: five greys.
static func tone_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var tones: Array = []
	var names := ""
	match level:
		1:
			var sets: Array = [["pink", "red", "dark red"], ["light blue", "blue", "dark blue"],
				["light green", "green", "dark green"], ["lilac", "purple", "dark purple"]]
			tones = sets[rng.randi_range(0, sets.size() - 1)]
		2:
			var greys: Array = ["white", "light grey", "grey", "dark grey", "black"]
			greys.remove_at(rng.randi_range(0, 4))
			tones = greys
		3:
			tones = ["white", "light grey", "grey", "dark grey", "black"]
	var dark_first := level == 3 and rng.randi() % 2 == 0
	var in_order: Array = tones.duplicate()
	if dark_first:
		in_order.reverse()
	names = ", ".join(PackedStringArray(in_order))
	var ex := K.order(rng, "Put these tones in order, %s first." % ("darkest" if dark_first else "lightest"), in_order,
		"Squint at the patches: which has the most white in it? Which has the most black?",
		"From %s to %s: %s." % ["darkest" if dark_first else "lightest", "lightest" if dark_first else "darkest", names])
	ex.picture = {"kind": "swatches", "items": ex.items}
	ex.data = {"tones": tones, "dark_first": dark_first}
	return ex


## Pixels and resolution. Level 1: every pixel of a picture (rows × columns); level 2: the pixels of one colour;
## level 3: twice as wide and twice as tall.
static func pixel_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	match level:
		1, 2:
			var w := rng.randi_range(4, 8) if level == 1 else rng.randi_range(5, 8)
			var h := rng.randi_range(3, 6) if level == 1 else rng.randi_range(4, 6)
			var colours: Array = [["r", "red"], ["b", "blue"], ["g", "green"], ["y", "yellow"], ["p", "purple"]]
			K.shuffle(rng, colours)
			var key := {str(colours[0][0]): str(colours[0][1]), str(colours[1][0]): str(colours[1][1])}
			var rows: Array = []
			var count := 0
			for y in h:
				var row := ""
				for x in w:
					var roll := rng.randi_range(0, 9)
					var ch := "." if roll < 3 else (str(colours[0][0]) if roll < 7 else str(colours[1][0]))
					row += ch
				rows.append(row)
			var pic := {"kind": "pixel_art", "rows": rows, "key": key}
			if level == 1:
				ex = K.number("How many pixels (squares) does this picture have, empty ones too?", w * h,
					"Count the squares in one row, then count the rows, and multiply.",
					"%d pixels in a row and %d rows: %d × %d = %d pixels." % [w, h, w, h, w * h], pic)
			else:
				var ch := str(colours[0][0])
				for row: String in rows:
					count += row.count(ch)
				if count == 0:
					rows[0] = ch + str(rows[0]).substr(1)
					count = 0
					for row: String in rows:
						count += row.count(ch)
				pic.rows = rows
				var per_row: Array[String] = []
				for row: String in rows:
					per_row.append(str(row.count(ch)))
				ex = K.number("How many %s pixels does this picture have?" % key[ch], count,
					"Go row by row: count the %s squares in each row, then add the rows up." % key[ch],
					"Row by row: %s = %d %s pixels." % [" + ".join(per_row), count, key[ch]], pic)
			ex.data = {"rows": rows, "key": key}
		3:
			var w: int = [8, 10, 12, 16, 20][rng.randi_range(0, 4)]
			var h: int = [6, 8, 10, 12][rng.randi_range(0, 3)]
			ex = K.number("A pixel picture is %d pixels wide and %d tall. Its artist makes it twice as wide and twice as tall. How many pixels does it have now?" % [w, h],
				4 * w * h, "Work out the new width and the new height first, then multiply them.",
				"The new picture is %d wide and %d tall: %d × %d = %d pixels, 4 times as many as before." % [2 * w, 2 * h,
					2 * w, 2 * h, 4 * w * h])
			ex.data = {"w": w, "h": h}
	return ex


## A relief block prints its mirror image: the letter carved backwards prints the right way round. Level 1: two
## prints to choose from; level 2: three; level 3: two letters (they swap places in the mirror too).
static func which_print(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var letters: Array[String] = ["F", "G", "J", "K", "L", "P", "Q", "R", "2", "3", "4", "5", "7"]
	var text := letters[rng.randi_range(0, letters.size() - 1)]
	if level == 3:
		var second := text
		while second == text:
			second = letters[rng.randi_range(0, letters.size() - 1)]
		text += second
	var paper := func(t: String, flip: String) -> Dictionary:
		return {"picture": {"kind": "print", "items": [{"text": t, "on": "paper", "flip": flip}]}}
	var wrongs: Array = [paper.call(text, "mirror")]
	if level >= 2:
		wrongs.append(paper.call(text, "upside down"))
	if level == 3:
		wrongs.append(paper.call(text.reverse(), "none"))
	var ex := K.choice(rng, "This block is inked and pressed onto paper. Which print does it make?", paper.call(text, "none"),
		wrongs, "A print is the block's mirror image. Picture the block flipped over like a page, face down on the paper.",
		"The block is carved backwards, so the print is the right way round: %s." % text,
		{"kind": "print", "items": [{"text": text, "on": "block", "flip": "mirror"}]})
	ex.data = {"text": text}
	return ex


# --- Music -----------------------------------------------------------------------------------------------------------

const VALUE_BEATS := {"semibreve": 4, "dotted minim": 3, "minim": 2, "crotchet": 1, "quavers": 1, "rest": 1}
const VALUE_WORDS := {"semibreve": "a semibreve", "dotted minim": "a dotted minim", "minim": "a minim",
	"crotchet": "a crotchet", "quavers": "two quavers", "rest": "a crotchet rest"}
const TIMES := {"2/4": 2, "3/4": 3, "4/4": 4}


## How many beats do these notes last? Level 1: minims and crotchets; level 2: semibreves and quavers too; level 3:
## dotted minims and rests, over two bars.
static func note_beats(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = [["minim", "crotchet"], ["semibreve", "minim", "crotchet", "quavers"],
		["semibreve", "dotted minim", "minim", "crotchet", "quavers", "rest"]][level - 1]
	var count := [2, rng.randi_range(3, 4), rng.randi_range(3, 5)][level - 1] as int
	var most := [4, 6, 8][level - 1] as int
	var notes: Array = []
	var total := 0
	for _try in 100:
		notes.clear()
		total = 0
		for i in count:
			var v := str(pool[rng.randi_range(0, pool.size() - 1)])
			notes.append(v)
			total += int(VALUE_BEATS[v])
		if total <= most and (level == 1 or notes.has("semibreve") or notes.has("dotted minim") or notes.has("quavers")):
			break
	if total > most:
		notes = ["minim", "crotchet"]
		total = 3
	var parts: Array[String] = []
	for v: String in notes:
		parts.append(str(VALUE_BEATS[v]))
	var ex := K.number("How many beats do these notes last altogether?", total,
		"Say each note's beats as you point to it: a semibreve 4, a minim 2, a crotchet 1. Then add them up.",
		"%s: %s = %d beats." % [", ".join(notes.map(func(v: String) -> String: return VALUE_WORDS[v])), " + ".join(parts),
			total], {"kind": "notation", "beats": notes, "words": level == 1})
	ex.data = {"notes": notes}
	return ex


## A bar that is not full yet. Level 1: how many more beats a 4/4 bar needs; level 2: which one note fills it; level 3:
## the same in 3/4 or 2/4.
static func fill_the_bar(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var time: String = "4/4" if level < 3 else ["3/4", "2/4"][rng.randi_range(0, 1)]
	var per_bar := int(TIMES[time])
	var missing := rng.randi_range(1, mini(3, per_bar - 1))
	var have := per_bar - missing
	var notes: Array = []
	var left := have
	while left > 0:
		var fits: Array = ["crotchet", "quavers"]
		if left >= 2:
			fits.append("minim")
		var v := str(fits[rng.randi_range(0, fits.size() - 1)])
		notes.append(v)
		left -= int(VALUE_BEATS[v])
	var one := {1: "a crotchet", 2: "a minim", 3: "a dotted minim"}
	var pic := {"kind": "notation", "beats": notes, "time": time}
	var ex := {}
	if level == 1:
		ex = K.number("This bar is in 4/4 time. How many more beats does it need?", missing,
			"The top number of 4/4 says how many beats fill a bar. Count the beats already there.",
			"4/4 has 4 beats in a bar. It has %d, so it needs 4 − %d = %d more." % [have, have, missing], pic)
	else:
		var wrongs: Array = []
		for b: int in [1, 2, 3, 4]:
			if b != missing:
				wrongs.append({1: "a crotchet", 2: "a minim", 3: "a dotted minim", 4: "a semibreve"}[b])
		ex = K.choice(rng, "This bar is in %s time. Which one note fills it?" % time, one[missing], wrongs.slice(0, 3),
			"The time signature's top number is the beats in a bar. How many are missing? Which note lasts that long?",
			"%s has %d beats in a bar. The notes there last %d, so %d %s missing: %s." % [time, per_bar, have, missing,
				"beat is" if missing == 1 else "beats are", one[missing]], pic)
	ex.data = {"time": time, "notes": notes}
	return ex


## Hear an "oom-pah" accompaniment: a low note on the first beat of every bar, higher notes on the others. How many
## beats in a bar? Level 1: 2 or 3 (a march or a waltz); level 2: 3 or 4; level 3: 2, 3 or 4.
static func count_the_bar(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var options: Array = [[2, 3], [3, 4], [2, 3, 4]][level - 1]
	var beats := int(options[rng.randi_range(0, options.size() - 1)])
	var bars := {2: 6, 3: 4, 4: 4}[beats] as int
	var chords: Array = [["C3", "E4"], ["G2", "D4"], ["F2", "C4"], ["C3", "G4"]]
	var notes: Array[String] = []
	for b in bars:
		var ch: Array = chords[(b + rng.randi_range(0, 1)) % 4] if b > 0 else chords[0]
		notes.append(str(ch[0]))
		for i in beats - 1:
			notes.append(str(ch[1]))
	var words := {2: "2 beats: oom-pah, like a march", 3: "3 beats: oom-pah-pah, like a waltz",
		4: "4 beats: oom-pah-pah-pah"}
	var ex := {}
	if level == 1:
		ex = K.choice(rng, "Listen. Is this a march (2 beats in a bar) or a waltz (3 beats in a bar)?",
			"a march" if beats == 2 else "a waltz", ["a waltz" if beats == 2 else "a march"],
			"Count from one low note to the next: 1, 2, … How many beats before the next low note?",
			"A low note starts every bar, then %d higher: %s." % [beats - 1, words[beats]])
	else:
		var wrongs: Array = []
		for b: int in [2, 3, 4]:
			if b != beats:
				wrongs.append("%d beats" % b)
		ex = K.choice(rng, "Listen. How many beats are in each bar?", "%d beats" % beats, wrongs,
			"Count from one low note to the next: 1, 2, … How many beats before the next low note?",
			"A low note starts every bar, then %d higher: %s." % [beats - 1, words[beats]])
	ex.sound = {"kind": "notes", "notes": notes, "beat": 0.4}
	ex.data = {"beats": beats}
	return ex


## The treble stave. Level 1: a note in a space (F A C E) or on a line (E G B D F) of the stave; level 2: any note from
## middle C to the C above; level 3: the word the notes spell.
static func name_the_note(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	if level < 3:
		var pool: Array = ["E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5"] if level == 1 else \
			["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5"]
		var note := str(pool[rng.randi_range(0, pool.size() - 1)])
		var letter := note.left(1)
		var letters: Array = ["A", "B", "C", "D", "E", "F", "G"].filter(func(l: String) -> bool: return l != letter)
		K.shuffle(rng, letters)
		var step := SchoolPictureG4Arts.stave_step(note)
		var where := ""
		if step == -2:
			where = "on its own short line below the stave: middle C"
		elif step == -1:
			where = "just under the bottom line: D"
		elif step % 2 == 0:
			where = "on line %d from the bottom (E, G, B, D, F): %s" % [int(step / 2.0) + 1, letter]
		else:
			where = "in space %d from the bottom (F, A, C, E): %s" % [int((step + 1) / 2.0), letter]
		ex = K.choice(rng, "Which note is this?", letter, letters.slice(0, 3),
			"Is it on a line or in a space? Lines from the bottom: E, G, B, D, F. Spaces: F, A, C, E.",
			"It is %s." % where, {"kind": "stave", "notes": [note], "values": ["minim"]})
		ex.data = {"notes": [note]}
	else:
		var words: Array = ["BAG", "CAB", "BED", "EGG", "ADD", "DAD", "BEE", "ACE", "FED", "BEG", "CAGE", "FACE", "FEED",
			"BEAD", "FADE", "CAFE", "EDGE", "BADGE", "ADDED", "FACED", "CAGED", "FADED"]
		var word := str(words[rng.randi_range(0, words.size() - 1)])
		var notes: Array = []
		var letters: Array[String] = []
		for ch in word:   # inside the stave: E4 (the bottom line) up to D5
			notes.append({"C": "C5", "D": "D5", "E": "E4", "F": "F4", "G": "G4", "A": "A4", "B": "B4"}[ch])
			letters.append(ch)
		var same: Array = words.filter(func(w: String) -> bool: return w.length() == word.length() and w != word)
		K.shuffle(rng, same)
		ex = K.choice(rng, "Name each note. Which word do they spell?", word, same.slice(0, 3),
			"Name the notes one at a time, left to right. Lines: E, G, B, D, F. Spaces: F, A, C, E.",
			"The notes are %s: %s." % [", ".join(letters), word],
			{"kind": "stave", "notes": notes})
		ex.data = {"notes": notes}
	return ex


## Steps and leaps in the pentatonic scale (C, D, E, G, A). A step moves to the next letter (C to D); a leap jumps over
## at least one (E to G, C to A). Level 1: a step or a big leap; level 2: a step or any leap; level 3: how many leaps in
## a tune of five notes.
static func step_or_leap(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var scale: Array[String] = ["C4", "D4", "E4", "G4", "A4", "C5", "D5", "E5"]
	var ex := {}
	if level < 3:
		var a := 0
		var b := 0
		var is_step := rng.randi() % 2 == 0
		for _try in 100:
			a = rng.randi_range(0, scale.size() - 1)
			b = rng.randi_range(0, scale.size() - 1)
			if a == b:
				continue
			var gap := _letters_apart(scale[a], scale[b])
			if is_step and gap == 1:
				break
			if not is_step and gap >= (4 if level == 1 else 2):
				break
		var gap := _letters_apart(scale[a], scale[b])
		is_step = gap == 1
		ex = K.choice(rng, "Listen to two notes of the pentatonic scale. Is it a step or a leap?", "a step" if is_step else "a leap",
			["a leap" if is_step else "a step"], "Say the letter names in order: C, D, E, F, G, A, B. Does the tune go to the next letter, or jump over some?",
			"%s to %s: %s." % [scale[a].left(1), scale[b].left(1), "the next letter, a step" if is_step else
				"it jumps over %d letter%s, a leap" % [gap - 1, "" if gap == 2 else "s"]])
		ex.sound = {"kind": "notes", "notes": [scale[a] + ":2", "-", scale[b] + ":2"]}
		ex.data = {"notes": [scale[a], scale[b]]}
	else:
		var tune: Array[String] = []
		var i := rng.randi_range(0, 4)
		tune.append(scale[i])
		for k in 4:
			var j := i
			while j == i:
				j = clampi(i + rng.randi_range(-3, 3), 0, scale.size() - 1)
			tune.append(scale[j])
			i = j
		var leaps := 0
		var said: Array[String] = []
		for k in 4:
			var gap := _letters_apart(tune[k], tune[k + 1])
			if gap > 1:
				leaps += 1
			said.append("%s to %s %s" % [tune[k].left(1), tune[k + 1].left(1), "a step" if gap == 1 else "a leap"])
		var played: Array[String] = []
		for n in tune:
			played.append(n)
		played[4] = tune[4] + ":2"
		ex = K.number("Listen and look. How many leaps are in this tune?", leaps,
			"Go from each note to the next and say the letters. Next letter: a step. Jumping over a letter: a leap.",
			"%s: %d leap%s." % [", ".join(said), leaps, "" if leaps == 1 else "s"], {"kind": "melody", "notes": tune})
		ex.sound = {"kind": "notes", "notes": played}
		ex.data = {"notes": tune}
	return ex


## Letters apart on the stave (C4 to D4 is 1, E4 to G4 is 2, C4 to C5 is 7).
static func _letters_apart(a: String, b: String) -> int:
	var order := "CDEFGAB"
	var pa := order.find(a.left(1)) + 7 * int(a.substr(1))
	var pb := order.find(b.left(1)) + 7 * int(b.substr(1))
	return absi(pa - pb)


## A round: every group sings the same lines, starting a line apart (a table: groups down, time across). Level 1: two
## groups; level 2: three; level 3: how long the whole round lasts.
static func round_parts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex := {}
	if level < 3:
		var groups := level + 1
		var lines := rng.randi_range(3, 4)
		var rows: Array = [["", "1st", "2nd", "3rd", "4th", "5th"]]
		for g in groups:
			var row: Array = ["Group %d" % (g + 1)]
			for t in 5:
				var line := t - g + 1
				row.append("line %d" % line if line >= 1 and line <= lines else "wait" if line < 1 else "done")
			rows.append(row)
		var who := rng.randi_range(1, groups - 1)
		var line1 := rng.randi_range(who + 1, mini(5, lines))   # group 1's line: sung at time line1
		var sung := line1 - who
		var wrongs: Array = []
		for l in range(1, lines + 1):
			if l != sung:
				wrongs.append("line %d" % l)
		ex = K.choice(rng, "In this round, when group 1 sings line %d, what does group %d sing?" % [line1, who + 1],
			"line %d" % sung, wrongs.slice(0, 3),
			"Find group 1's line in the table, then look straight down that column to group %d." % (who + 1),
			"Group %d started %d line%s later, so it is %d line%s behind: %d − %d = %d, line %d." % [who + 1, who,
				"" if who == 1 else "s", who, "" if who == 1 else "s", line1, who, sung, sung], {"kind": "table", "rows": rows})
		ex.data = {"groups": groups, "lines": lines, "line": line1, "group": who + 1}
	else:
		var lines := rng.randi_range(3, 5)
		var groups := rng.randi_range(2, 4)
		var total := lines + groups - 1
		ex = K.number("A round has %d lines. %d groups sing it once each, and each group starts one line after the one before. How many lines long is the whole song?" % [
			lines, groups], total,
			"The first group sings all the lines. How many lines later does the last group start? It still sings every line.",
			"The last group starts %d line%s after the first and sings all %d: %d + %d = %d lines." % [groups - 1,
				"" if groups == 2 else "s", lines, groups - 1, lines, total])
		ex.data = {"groups": groups, "lines": lines}
	return ex


## An ostinato: a rhythm that repeats. Level 1: how many times a short pattern repeats; level 2: a longer one; level 3:
## which time round one clap changed.
static func ostinato_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var cells: Array = ["x-", "xx", "--"]
	var beats := 2 if level == 1 else 4
	var pattern := ""
	for _try in 100:   # it starts with a clap, has 2 claps or more, and is not all the same beat
		pattern = ["x-", "xx"][rng.randi_range(0, 1)]
		for b in beats - 1:
			pattern += str(cells[rng.randi_range(0, 2)])
		if pattern.count("x") >= 2 and pattern != pattern.substr(0, 2).repeat(beats):
			break
	var times := rng.randi_range(3, 5) if level == 1 else rng.randi_range(2, 4)
	var ex := {}
	if level < 3:
		ex = K.number("Listen to the ostinato. How many times do you hear the pattern?", times,
			"The picture shows the pattern once. Tap along, and hold up a finger each time it starts again.",
			"The pattern %s comes %d times, one after another: that is what makes it an ostinato." % [_ta(pattern), times],
			{"kind": "notation", "beats": _beats_of(pattern)})
		ex.sound = {"kind": "rhythm", "pattern": pattern.repeat(times), "tempo": 110 if level == 1 else 120}
		ex.data = {"pattern": pattern, "times": times}
	else:
		times = rng.randi_range(3, 4)
		var odd := rng.randi_range(2, times)
		var beat := rng.randi_range(1, beats - 1)   # one beat (never the first) becomes another of ta, ti-ti, rest
		var was := pattern.substr(beat * 2, 2)
		var others: Array = cells.filter(func(k: String) -> bool: return k != was)
		var changed := pattern.substr(0, beat * 2) + str(others[rng.randi_range(0, 1)]) + pattern.substr(beat * 2 + 2)
		var sound := ""
		for k in times:
			sound += changed if k + 1 == odd else pattern
		var wrongs: Array = []
		for k in range(1, times + 1):
			if k != odd:
				wrongs.append(_nth(k))
		ex = K.choice(rng, "Listen. The ostinato repeats, but one time round it changes. Which time?", _nth(odd), wrongs,
			"Clap the pattern in the picture along with the sound. Where do your claps stop matching?",
			"The pattern is %s. The %s time round, beat %d changes: %s." % [_ta(pattern), _nth(odd).trim_prefix("the "),
				beat + 1, _ta(changed)], {"kind": "notation", "beats": _beats_of(pattern)})
		ex.sound = {"kind": "rhythm", "pattern": sound, "tempo": 120}
		ex.data = {"pattern": pattern, "times": times, "changed": odd}
	return ex


static func _beats_of(pattern: String) -> Array:
	var out: Array = []
	for i in range(0, pattern.length(), 2):
		out.append({"x-": "crotchet", "xx": "quavers", "--": "rest"}[pattern.substr(i, 2)])
	return out


static func _ta(pattern: String) -> String:
	var out: Array[String] = []
	for i in range(0, pattern.length(), 2):
		out.append(str({"x-": "ta", "xx": "ti-ti", "--": "rest"}[pattern.substr(i, 2)]))
	return ", ".join(out)


static func _nth(k: int) -> String:
	return "the %s" % ["first", "second", "third", "fourth", "fifth"][k - 1]
