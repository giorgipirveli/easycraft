class_name G5MeasureGen
extends RefCounted
## Owner #68 (spec §22.5): grade 5 maths generators for units 13-16 of the outline: volume (5.MD.3-5), converting units
## and line plots (5.MD.1-2), the coordinate grid (5.G.1-2, 5.OA.3) and shape families (5.G.3-4): SchoolGen
## "g5m.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with
## a hint, a worked answer and `data` (its inputs, for tests/unit/test_g5_measure_gen.gd). Amounts are worked in whole
## small units (cm, g, mL), never floats. Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]
## [the big unit, the small unit, how many small units make a big one, what it measures]
const UNITS: Array = [["m", "cm", 100, "long"], ["km", "m", 1000, "long"], ["cm", "mm", 10, "long"],
	["kg", "g", 1000, "heavy"], ["L", "mL", 1000, "much"]]
## What a line plot measures: [the things, the unit].
const PLOTS: Array = [["ribbons", "m"], ["jugs of water", "L"], ["bags of flour", "kg"], ["planks", "m"]]
const PROPERTY_LEVELS := {1: ["right_angles", "equal_sides"], 2: ["right_angles", "equal_sides", "two_parallel",
	"opposite_equal"], 3: ["right_angles", "equal_sides", "two_parallel", "opposite_equal", "one_parallel", "adjacent_equal"]}


# --- Unit 13: volume (5.MD.3, 5.MD.4, 5.MD.5) ---------------------------------------------------------------------------

## A box of unit cubes (two at level 3): "How many unit cubes make this box?"
static func cube_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var boxes: Array = []
	for _i in (2 if level == 3 else 1):
		var top := 3 if level == 1 else 5
		boxes.append([rng.randi_range(2, top), rng.randi_range(2, mini(top, 4)), rng.randi_range(2, mini(top, 4))])
	var shown: Array = []
	var volumes: Array[int] = []
	for b: Array in boxes:
		shown.append({"l": b[0], "w": b[1], "h": b[2]})
		volumes.append(int(b[0]) * int(b[1]) * int(b[2]))
	var b0: Array = boxes[0]
	var layer := "%d × %d = %d cubes in each layer, and %d layers: %d cubes." % [b0[0], b0[1], int(b0[0]) * int(b0[1]), b0[2], volumes[0]]
	var ex: Dictionary
	if boxes.size() == 1:
		ex = K.number("How many unit cubes make this box? That is its volume.", str(volumes[0]),
			"Count the cubes in one layer (length × width), then times the number of layers.", layer, {"kind": "cubes", "boxes": shown})
	else:
		var b1: Array = boxes[1]
		ex = K.number("Two boxes stand side by side. What is their total volume, in unit cubes?", str(volumes[0] + volumes[1]),
			"Find each box's volume (length × width × height), then add them.",
			"%d × %d × %d = %d, and %d × %d × %d = %d. Together: %d." % [b0[0], b0[1], b0[2], volumes[0], b1[0], b1[1], b1[2],
				volumes[1], volumes[0] + volumes[1]], {"kind": "cubes", "boxes": shown})
	ex.data = {"boxes": boxes}
	return ex


## "A box is 5 cm long, 3 cm wide and 4 cm high. What is its volume in cm³?"; level 3: the missing height.
static func volume_formula(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var l := rng.randi_range(2, 6 if level == 1 else 10)
	var w := rng.randi_range(2, 5 if level == 1 else 8)
	var h := rng.randi_range(2, 6 if level == 1 else 9)
	var unit := "cm" if level == 1 or rng.randf() < 0.6 else "m"
	var v := l * w * h
	var ex: Dictionary
	if level < 3:
		ex = K.number("A box is %d %s long, %d %s wide and %d %s high. What is its volume in %s³?" % [l, unit, w, unit, h, unit, unit],
			str(v), "Volume = length × width × height.", "%d × %d × %d = %d %s³." % [l, w, h, v, unit])
		ex.data = {"l": l, "w": w, "h": h, "unknown": ""}
	else:
		ex = K.number("A box has a volume of %d %s³. It is %d %s long and %d %s wide. How high is it, in %s?" % [v, unit, l, unit, w, unit, unit],
			str(h), "Find the area of the bottom (length × width), then divide the volume by it.",
			"The bottom is %d × %d = %d %s². %d ÷ %d = %d %s high." % [l, w, l * w, unit, v, l * w, h, unit],
			{"kind": "cubes", "boxes": [{"l": l, "w": w, "h": h}], "labels": true, "unit": unit, "unknown": "h", "grid": false})
		ex.data = {"l": l, "w": w, "h": h, "unknown": "h"}
	return ex


## "A 2 × 3 × 4 box holds 24 unit cubes." True or false?
static func volume_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var top := 4 if level == 1 else 8
	var l := rng.randi_range(2, top)
	var w := rng.randi_range(2, top)
	var h := rng.randi_range(2, top)
	var v := l * w * h
	var claimed := v
	if rng.randf() < 0.5:
		var slips: Array = [l * w + h, (l + w) * h, v + l * w, v - w * h, l + w + h]
		slips = slips.filter(func(n: int) -> bool: return n != v and n > 0)
		claimed = int(slips[rng.randi_range(0, slips.size() - 1)])
	var ex := K.truefalse("A box %d cubes long, %d wide and %d high holds %d unit cubes." % [l, w, h, claimed], claimed == v,
		"Multiply all three: length × width × height.", "%d × %d × %d = %d." % [l, w, h, v])
	ex.data = {"l": l, "w": w, "h": h, "claimed": claimed}
	return ex


# --- Unit 14: converting units and line plots (5.MD.1, 5.MD.2) -------------------------------------------------------------

## "4 m = ? cm", "2.5 kg = ? g", "450 cm = ? m"
static func change_units(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var u: Array = UNITS[rng.randi_range(0, UNITS.size() - 1)]
	var factor: int = u[2]
	var to_small := level == 1 or (level == 2 and rng.randf() < 0.6)
	var small := 0
	if level == 1:
		small = rng.randi_range(2, 20) * factor
	elif level == 2 and to_small:   # a big amount with one decimal place
		small = rng.randi_range(11, 99) * factor / 10
		if small % factor == 0:
			small += factor / 10
	elif level == 2:   # a whole number of big units
		small = rng.randi_range(2, 20) * factor
	else:   # small units that make a decimal of big units
		small = rng.randi_range(factor + 1, factor * 10 - 1)
		if small % factor == 0:
			small += 1
		if not to_small and rng.randf() < 0.3:
			small = rng.randi_range(1, factor - 1)   # less than one big unit: 0.35 m
	var big := _dec(small, factor)
	var ex: Dictionary
	if to_small:
		ex = K.number("%s %s = ? %s" % [big, u[0], u[1]], K.fmt(small), "1 %s = %s %s." % [u[0], K.fmt(factor), u[1]],
			"%s × %s = %s, so %s %s = %s %s." % [big, K.fmt(factor), K.fmt(small), big, u[0], K.fmt(small), u[1]])
	else:
		ex = K.number("%s %s = ? %s" % [K.fmt(small), u[1], u[0]], big, "%s %s = 1 %s." % [K.fmt(factor), u[1], u[0]],
			"%s ÷ %s = %s, so %s %s = %s %s." % [K.fmt(small), K.fmt(factor), big, K.fmt(small), u[1], big, u[0]])
	ex.data = {"small": small, "factor": factor, "to_small": to_small}
	return ex


## "Which is longer? 1.2 m or 95 cm"
static func compare_units(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var u: Array = UNITS[rng.randi_range(0, UNITS.size() - 1)]
	var factor: int = u[2]
	var count := 2 if level == 1 else 3
	var amounts: Array[int] = []
	var tries := 0
	while amounts.size() < count and tries < 100:
		tries += 1
		var a := factor + rng.randi_range(-factor / 2, factor / 2) if level < 3 else rng.randi_range(factor / 2, factor * 3)
		if level == 1:
			a = a / (factor / 10) * (factor / 10) if factor >= 100 else a
		if a > 0 and not amounts.has(a):
			amounts.append(a)
	var words: Array[String] = []
	for i in amounts.size():
		var in_big := (i % 2 == 0) if level == 1 else rng.randf() < 0.5
		words.append("%s %s" % [_dec(amounts[i], factor), u[0]] if in_big else "%s %s" % [K.fmt(amounts[i]), u[1]])
	var best := 0
	for i in amounts.size():
		if amounts[i] > amounts[best]:
			best = i
	var asks := {"long": ["Which is longer?", "Which is the longest?"], "heavy": ["Which is heavier?", "Which is the heaviest?"],
		"much": ["Which is more?", "Which is the most?"]}
	var ask: Array = asks[u[3]]
	var wrongs: Array = []
	for i in words.size():
		if i != best:
			wrongs.append(words[i])
	var said: Array[String] = []
	for a: int in amounts:
		said.append("%s %s" % [K.fmt(a), u[1]])
	var ex := K.choice(rng, str(ask[0 if count == 2 else 1]), words[best], wrongs,
		"Change them all to %s first (1 %s = %s %s)." % [u[1], u[0], K.fmt(factor), u[1]],
		"In %s: %s. The biggest is %s." % [u[1], ", ".join(said), words[best]])
	ex.data = {"small": amounts, "words": words}
	return ex


## A line plot's measurements, added up (level 3: shared out equally).
static func plot_total(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var what: Array = PLOTS[rng.randi_range(0, PLOTS.size() - 1)]
	var dens: Array = [2, 4] if level == 1 else [2, 4, 8]
	var count := rng.randi_range(3, 4)
	var parts: Array = []
	for _i in count:
		var den: int = dens[rng.randi_range(0, dens.size() - 1)]
		parts.append([rng.randi_range(1, den - 1), den])
	var num := 0
	var den := 1
	var shown: Array[String] = []
	for f: Array in parts:
		num = num * int(f[1]) + int(f[0]) * den
		den *= int(f[1])
		shown.append("%s %s" % [K.frac(f[0], f[1]), what[1]])
	var share := count if level == 3 else 1
	var list := ", ".join(shown.slice(0, shown.size() - 1)) + " and " + shown[-1]
	var name := NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var total := _reduced(num, den)
	var each := _reduced(num, den * share)
	var ex: Dictionary
	if share == 1:
		ex = K.number("%s's line plot shows %d %s: %s. What is the total, in %s?" % [name, count, what[0], list, what[1]],
			K.frac(total[0], total[1]) if total[1] > 1 else str(total[0]),
			"Change them to the same bottom number, then add.",
			"Added up: %s %s%s." % [K.frac(total[0], total[1]) if total[1] > 1 else str(total[0]), what[1], _mixed_words(total)])
	else:
		ex = K.number("%s's line plot shows %d %s: %s. Shared equally among the %d, how much would each have, in %s?" % [name,
			count, what[0], list, count, what[1]], K.frac(each[0], each[1]) if each[1] > 1 else str(each[0]),
			"Add them all up, then divide by %d." % count,
			"The total is %s %s; ÷ %d = %s %s each." % [K.frac(total[0], total[1]) if total[1] > 1 else str(total[0]), what[1], count,
				K.frac(each[0], each[1]) if each[1] > 1 else str(each[0]), what[1]])
	var accept := _decimal(each[0], each[1])
	if accept != "":
		ex.accept = [accept]
	ex.data = {"parts": parts, "share": share}
	return ex


# --- Unit 15: the coordinate grid (5.G.1, 5.G.2, 5.OA.3) --------------------------------------------------------------------

## "Tap the point (3, 5)."
static func plot_point(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var grid := _grid(level)
	var x := rng.randi_range(1 if level == 1 else 0, int(grid.x_max) / int(grid.get("x_step", 1))) * int(grid.get("x_step", 1))
	var y := rng.randi_range(1 if level == 1 else 0, int(grid.y_max))
	if x == 0 and y == 0:
		x = int(grid.get("x_step", 1))
	var ex := {"type": "point", "prompt": "Tap the point (%d, %d)." % [x, y], "grid": grid, "answer": [x, y],
		"hint": "The first number tells you how far along; the second, how far up.",
		"explain": "Go %d along the x-axis, then %d up: (%d, %d)." % [x, y, x, y]}
	ex.data = {"x": x, "y": y}
	return ex


## "Start at (2, 3). Move 4 right and 2 up. Tap where you land."
static func move_point(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var top := 6 if level == 1 else 10
	var x := rng.randi_range(0, top)
	var y := rng.randi_range(0, top)
	var dx := rng.randi_range(1, top - x) if x < top else 0
	var dy := rng.randi_range(1, top - y) if y < top else 0
	if level > 1:
		if rng.randf() < 0.5 and x > 0:
			dx = -rng.randi_range(1, x)
		if rng.randf() < 0.5 and y > 0:
			dy = -rng.randi_range(1, y)
	if dx == 0 and dy == 0:
		dx = 1 if x < top else -1
	var moves: Array[String] = []
	if dx != 0:
		moves.append("%d %s" % [absi(dx), "right" if dx > 0 else "left"])
	if dy != 0:
		moves.append("%d %s" % [absi(dy), "up" if dy > 0 else "down"])
	var grid := {"x_max": top, "y_max": top, "points": [{"x": x, "y": y, "label": "S"}]}
	var ex := {"type": "point", "prompt": "Start at S (%d, %d). Move %s. Tap where you land." % [x, y, " and ".join(moves)],
		"grid": grid, "answer": [x + dx, y + dy], "hint": "Right and left change the first number; up and down, the second.",
		"explain": "(%d %s %d, %d %s %d) = (%d, %d)." % [x, "+" if dx >= 0 else "−", absi(dx), y, "+" if dy >= 0 else "−", absi(dy),
			x + dx, y + dy]}
	ex.data = {"x": x, "y": y, "dx": dx, "dy": dy}
	return ex


## A point A on the grid: "What are the coordinates of A?"
static func read_point(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var top := 6 if level == 1 else 10
	var x := rng.randi_range(1 if level < 3 else 0, top)
	var y := rng.randi_range(1, top)
	if x == y:
		y = y - 1 if y > 1 else y + 1
	var right := "(%d, %d)" % [x, y]
	var wrongs: Array = ["(%d, %d)" % [y, x]]
	for d: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		if wrongs.size() >= 3:
			break
		var p := Vector2i(x, y) + d
		var w := "(%d, %d)" % [p.x, p.y]
		if p.x >= 0 and p.y >= 0 and w != right and not wrongs.has(w):
			wrongs.append(w)
	var ex := K.choice(rng, "What are the coordinates of point A?", right, wrongs,
		"Read along the x-axis first, then up the y-axis.", "A is %d along and %d up: %s." % [x, y, right],
		{"kind": "grid", "x_max": top, "y_max": top, "points": [{"x": x, "y": y, "label": "A"}]})
	ex.data = {"x": x, "y": y}
	return ex


## Two number patterns from 0: "Rule A adds 2; rule B adds 6…"
static func two_rules(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(1, 5)
	var k := rng.randi_range(2, 4)
	var b := a * k if level == 3 else rng.randi_range(1, 10)
	if b == a:
		b = a + rng.randi_range(1, 4)
	var n := rng.randi_range(3, 5 if level == 1 else 8)
	var ex: Dictionary
	if level < 3:
		var terms_a: Array[String] = []
		var terms_b: Array[String] = []
		for i in range(1, 4):
			terms_a.append(str(a * i))
			terms_b.append(str(b * i))
		ex = K.number("Rule A: start at 0 and add %d (%s…). Rule B: start at 0 and add %d (%s…). When A is %d, what is B?" % [a,
			", ".join(terms_a), b, ", ".join(terms_b), a * n], str(b * n), "How many steps does A take to reach %d?" % (a * n),
			"A reaches %d after %d steps (%d × %d). After %d steps, B is %d × %d = %d." % [a * n, n, n, a, n, n, b, b * n])
	else:
		var wrongs: Array = ["%d times" % (k + 1), "%d more" % k]
		if k > 2:
			wrongs.append("%d times" % (k - 1))
		ex = K.choice(rng, "Rule A adds %d each time; rule B adds %d, both from 0. How does each B term compare with its A term?" % [a, b],
			"%d times" % k, wrongs, "Write the first few pairs: (%d, %d), (%d, %d)…" % [a, b, 2 * a, 2 * b],
			"Pairs (%d, %d), (%d, %d), (%d, %d): each B term is %d times its A term." % [a, b, 2 * a, 2 * b, 3 * a, 3 * b, k])
	ex.data = {"a": a, "b": b, "n": n}
	return ex


# --- Unit 16: shape families (5.G.3, 5.G.4) ----------------------------------------------------------------------------------

## "True or false: every square is a rectangle."
static func family_true(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pairs: Array = []
	for x: String in ShapeFamily.NODES:
		for y: String in ShapeFamily.NODES:
			if x == y or ShapeFamily.is_a(x, y) == ShapeFamily.DEPENDS:
				continue
			var near := ShapeFamily.parents(x).has(y) or ShapeFamily.parents(y).has(x)
			if level == 1 and not near:
				continue
			pairs.append([x, y])
	var pick: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
	var x: String = pick[0]
	var y: String = pick[1]
	var yes := ShapeFamily.is_a(x, y) == ShapeFamily.ALWAYS
	var why := "a %s has everything a %s has: it sits below it in the family tree." % [x, y]
	if not yes:
		why = "they are different families."
		for p: String in ShapeFamily.PROPERTIES:
			if ShapeFamily.has(y, p) and not ShapeFamily.has(x, p):
				why = "every %s has %s, but a %s doesn't always." % [y, ShapeFamily.PROPERTIES[p][0], x]
				break
	var picture := {"kind": "family", "mark": x} if level < 3 else {}
	var ex := K.truefalse("True or false: every %s is a %s." % [x, y], yes, "Find the %s in the family tree. Is the %s above it?" % [x, y],
		("True: " if yes else "False: ") + why, picture)
	ex.data = {"x": x, "y": y}
	return ex


## "Which shape always has 4 right angles?"
static func family_property(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var props: Array = PROPERTY_LEVELS[level]
	var p: String = props[rng.randi_range(0, props.size() - 1)]
	var with_it: Array = []
	var without: Array = []
	for n: String in ShapeFamily.NODES:
		(with_it if ShapeFamily.has(n, p) else without).append(n)
	var right: String = with_it[rng.randi_range(0, with_it.size() - 1)]
	K.shuffle(rng, without)
	var ex := K.choice(rng, "Which shape always has %s?" % ShapeFamily.PROPERTIES[p][0], right, without.slice(0, 3),
		"Think of the family each shape belongs to.",
		"Every %s has %s. So do: %s." % [right, ShapeFamily.PROPERTIES[p][0], ", ".join(with_it)])
	ex.data = {"property": p}
	return ex


## "A triangle has sides of 5 cm, 5 cm and 3 cm. What kind is it?"
static func triangle_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var by_sides := level == 1 or (level == 3 and rng.randf() < 0.5)
	var ex: Dictionary
	if by_sides:
		var kind: String = ShapeFamily.TRIANGLE_SIDES[rng.randi_range(0, 2)]
		var s := rng.randi_range(3, 9)
		var sides: Array = [s, s, s]
		if kind == "isosceles":
			var t := rng.randi_range(2, 2 * s - 1)
			if t == s:
				t = s + 1
			sides = [s, s, t]
		elif kind == "scalene":
			sides = [s, s + rng.randi_range(1, 3), s + rng.randi_range(4, 6)]
			if int(sides[0]) + int(sides[1]) <= int(sides[2]):
				sides[2] = int(sides[0]) + int(sides[1]) - 1
		K.shuffle(rng, sides)
		ex = K.choice(rng, "A triangle has sides of %d cm, %d cm and %d cm. What kind of triangle is it?" % sides, kind,
			ShapeFamily.TRIANGLE_SIDES.filter(func(k: String) -> bool: return k != kind),
			"Equilateral: 3 equal sides. Isosceles: 2 equal sides. Scalene: no equal sides.",
			"%s: %s." % [kind.capitalize(), {"equilateral": "all 3 sides are equal", "isosceles": "exactly 2 sides are equal",
				"scalene": "no two sides are equal"}[kind]])
		ex.data = {"sides": sides}
	else:
		var kind: String = ShapeFamily.TRIANGLE_ANGLES[rng.randi_range(0, 2)]
		var big := 90
		if kind == "obtuse":
			big = rng.randi_range(10, 14) * 10
		elif kind == "acute":
			big = rng.randi_range(7, 8) * 10
		var rest := 180 - big
		var a := rng.randi_range(rest - big + 1, big - 1) if kind == "acute" else rng.randi_range(10, rest - 10)
		var angles: Array = [big, a, rest - a]
		K.shuffle(rng, angles)
		ex = K.choice(rng, "A triangle has angles of %d°, %d° and %d°. What kind of triangle is it?" % angles, kind,
			ShapeFamily.TRIANGLE_ANGLES.filter(func(k: String) -> bool: return k != kind),
			"Right: one angle is 90°. Obtuse: one angle is more than 90°. Acute: all angles are less than 90°.",
			"%s: %s." % [kind.capitalize(), {"right": "one angle is exactly 90°", "obtuse": "one angle is more than 90°",
				"acute": "every angle is less than 90°"}[kind]])
		ex.data = {"angles": angles}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------------

## `small` small units in big ones (`factor` small units each), as a decimal: 250, 100 -> "2.5".
static func _dec(small: int, factor: int) -> String:
	var whole := small / factor
	var part := small % factor
	if part == 0:
		return K.fmt(whole)
	var digits := str(factor).length() - 1
	var frac_text := str(part).pad_zeros(digits).rstrip("0")
	return "%s.%s" % [K.fmt(whole), frac_text]


static func _reduced(num: int, den: int) -> Array:
	var g := NumberAnswer.gcd(num, den)
	return [num / g, den / g]


## " (1 3/4)" for an improper fraction, "" otherwise.
static func _mixed_words(f: Array) -> String:
	if int(f[1]) == 1 or int(f[0]) < int(f[1]):
		return ""
	return " (%d %s)" % [int(f[0]) / int(f[1]), K.frac(int(f[0]) % int(f[1]), int(f[1]))] if int(f[0]) % int(f[1]) != 0 else ""


## The fraction as an exact decimal ("1.75"), or "" when it has none (or is whole).
static func _decimal(num: int, den: int) -> String:
	if den == 1:
		return ""
	for places in [1, 2, 3]:
		var scale := K.pow10(places)
		if (num * scale) % den == 0:
			return _dec(num * scale / den, scale)
	return ""


## The grid for a level: 0-6, 0-10, or 0-20 along in steps of 2.
static func _grid(level: int) -> Dictionary:
	match level:
		1:
			return {"x_max": 6, "y_max": 6}
		2:
			return {"x_max": 10, "y_max": 10}
	return {"x_max": 20, "x_step": 2, "y_max": 10}
