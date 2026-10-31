class_name G6AlgebraGen
extends RefCounted
## Owner #68 (spec §22.5): grade 6 maths generators for the coordinate plane, expressions and equations, geometry and
## statistics (Common Core 6.NS.6-8, 6.EE, 6.G, 6.SP; units 9-17 of the outline): SchoolGen "g6a.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a
## worked answer and `data` (its inputs, for tests/unit/test_g6_maths_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const QUADRANTS: Array[String] = ["the first (top right)", "the second (top left)", "the third (bottom left)",
	"the fourth (bottom right)"]
## [words, the right expression, wrong ones] (6.EE.2a)
const PHRASES: Array = [
	["5 less than a number n", "n − 5", ["5 − n", "n + 5", "5n"]],
	["the product of 4 and y", "4y", ["4 + y", "y − 4", "y ÷ 4"]],
	["twice the sum of x and 3", "2(x + 3)", ["2x + 3", "x + 3 × 2", "2 + x + 3"]],
	["a number m divided by 6", "m ÷ 6", ["6 ÷ m", "6m", "m − 6"]],
	["7 more than 3 times a number k", "3k + 7", ["7k + 3", "3(k + 7)", "3 + k + 7"]],
	["the difference of p and 9", "p − 9", ["9 − p", "p + 9", "9p"]],
	["half of a number w", "w ÷ 2", ["2w", "w − 2", "2 ÷ w"]],
	["8 times the difference of a and 1", "8(a − 1)", ["8a − 1", "8 − a − 1", "a − 8"]],
]
## [a statistical question, questions that are not] (6.SP.1)
const STAT_QUESTIONS: Array = [
	["How many pets do the pupils in my class have?", ["How many pets do I have?", "Is my dog brown?"]],
	["How tall are the school garden's sunflowers?", ["How tall is the school door?", "What colour is the gate?"]],
	["How long do pupils in Year 6 sleep each night?", ["How long did I sleep last night?", "What time is it now?"]],
	["How many books did each pupil read this term?", ["How many pages has this book got?", "Who wrote this book?"]],
	["How far do the village buddies walk each day?", ["How far is it to the shop?", "Is the shop open?"]],
]


# --- Unit 9: the coordinate plane (6.NS.6c, 6.NS.8, 6.G.3) --------------------------------------------------------------

## "In which quadrant is (−3, 4)?"; level 3: a point reflected across an axis.
static func quadrant(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var x := _nonzero(rng, 9)
	var y := _nonzero(rng, 9)
	var ex: Dictionary
	if level < 3:
		var q := _quadrant_of(x, y)
		ex = K.choice(rng, "In which quadrant is the point (%s, %s)?" % [_signed(x), _signed(y)], QUADRANTS[q],
			QUADRANTS.filter(func(w: String) -> bool: return w != QUADRANTS[q]), "Is x positive or negative? Is y?",
			"x is %s and y is %s, so (%s, %s) is in %s quadrant." % ["positive" if x > 0 else "negative", "positive" if y > 0 else "negative",
				_signed(x), _signed(y), QUADRANTS[q]])
		ex.data = {"x": x, "y": y, "ask": "quadrant"}
	else:
		var axis := "x" if rng.randf() < 0.5 else "y"
		var rx := x if axis == "x" else -x
		var ry := -y if axis == "x" else y
		var right := "(%s, %s)" % [_signed(rx), _signed(ry)]
		ex = K.choice(rng, "The point (%s, %s) is reflected across the %s-axis. Where does it land?" % [_signed(x), _signed(y), axis], right,
			["(%s, %s)" % [_signed(-rx), _signed(-ry)], "(%s, %s)" % [_signed(x), _signed(y)], "(%s, %s)" % [_signed(ry), _signed(rx)]],
			"Reflecting across the %s-axis changes the sign of the %s number." % [axis, "y" if axis == "x" else "x"],
			"Only the %s number changes sign: %s." % ["y" if axis == "x" else "x", right])
		ex.data = {"x": x, "y": y, "ask": axis}
	return ex


## "(2, 5) and (2, −3): how far apart?"
static func axis_distance(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var same := rng.randi_range(-8, 8)
	var p := rng.randi_range(1 if level == 1 else -9, 9)
	var q := rng.randi_range(-9, 9) if level > 1 else rng.randi_range(1, 9)
	if q == p:
		q = p - 3 if p > -6 else p + 3
	var vertical := rng.randf() < 0.5
	var a := Vector2i(same, p) if vertical else Vector2i(p, same)
	var b := Vector2i(same, q) if vertical else Vector2i(q, same)
	var dist := absi(p - q)
	var ex := K.number("How far apart are the points (%s, %s) and (%s, %s)?" % [_signed(a.x), _signed(a.y), _signed(b.x), _signed(b.y)], str(dist),
		"They share the %s number: count along the other one." % ("x" if vertical else "y"),
		"From %s to %s is %d." % [_signed(mini(p, q)), _signed(maxi(p, q)), dist])
	ex.data = {"a": [a.x, a.y], "b": [b.x, b.y]}
	return ex


# --- Unit 10: exponents and expressions (6.EE.1, 6.EE.2) ----------------------------------------------------------------

## "3⁴ = ?"; level 3: two powers added.
static func power_value(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var terms: Array = []
	for _i in (2 if level == 3 else 1):
		var base := rng.randi_range(2, 5 if level == 1 else 9)
		var e := rng.randi_range(2, 3 if level == 1 else 4)
		if base > 6 and e > 3:
			e = 3
		terms.append([base, e])
	var total := 0
	var shown: Array[String] = []
	var worked: Array[String] = []
	for t: Array in terms:
		var v := int(pow(int(t[0]), int(t[1])))
		total += v
		shown.append("%d%s" % [t[0], _sup(int(t[1]))])
		var times: Array[String] = []
		for _j in int(t[1]):
			times.append(str(t[0]))
		worked.append("%s = %d" % [" × ".join(times), v])
	var ex := K.number("%s = ?" % " + ".join(shown), str(total), "The small number says how many times to multiply the base by itself.",
		"%s%s." % ["; ".join(worked), (", so %d" % total) if terms.size() > 1 else ""])
	ex.data = {"terms": terms}
	return ex


## "3x + 4 when x = 5"
static func evaluate(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var b := rng.randi_range(1, 12)
	var x := rng.randi_range(1, 10)
	var y := rng.randi_range(1, 10)
	var form: String = ["ax+b", "a(x+b)", "ax+by"][level - 1]
	var shown := ""
	var v := 0
	match form:
		"ax+b":
			shown = "%dx + %d when x = %d" % [a, b, x]
			v = a * x + b
		"a(x+b)":
			shown = "%d(x + %d) when x = %d" % [a, b, x]
			v = a * (x + b)
		_:
			shown = "%dx + %dy when x = %d and y = %d" % [a, b, x, y]
			v = a * x + b * y
	var ex := K.number("Work out %s." % shown, str(v), "Put the numbers in place of the letters, then follow the order of operations.",
		"%s = %d." % [shown.get_slice(" when", 0).replace("x", "(%d)" % x).replace("y", "(%d)" % y), v])
	ex.data = {"form": form, "a": a, "b": b, "x": x, "y": y}
	return ex


## "5 less than a number n" -> "n − 5"
static func write_expression(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = range(PHRASES.size()) if level == 3 else range(level * 3)
	var i: int = pool[rng.randi_range(0, pool.size() - 1)]
	var row: Array = PHRASES[i]
	var ex := K.choice(rng, "Which expression means \"%s\"?" % row[0], row[1], row[2], "Read the words in order and turn each one into maths.",
		"\"%s\" is %s." % [row[0], row[1]])
	ex.data = {"i": i}
	return ex


# --- Unit 11: equivalent expressions (6.EE.3, 6.EE.4) -------------------------------------------------------------------

## "3(x + 4) = ?"; level 3: factor it.
static func distribute(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var b := 1 if level == 1 else rng.randi_range(2, 5)
	var c := rng.randi_range(1, 9)
	var minus := level > 1 and rng.randf() < 0.5
	var sign := "−" if minus else "+"
	var inside := "%sx %s %d" % ["" if b == 1 else str(b), sign, c]
	var right := "%dx %s %d" % [a * b, sign, a * c]
	var ex: Dictionary
	if level < 3:
		ex = K.choice(rng, "Which is equal to %d(%s)?" % [a, inside], right,
			["%dx %s %d" % [a * b, sign, c], "%sx %s %d" % ["" if b == 1 else str(b), sign, a * c], "%dx %s %d" % [a + b, sign, a + c]],
			"Multiply everything inside the brackets by %d." % a, "%d × %sx = %dx and %d × %d = %d: %s." % [a, "" if b == 1 else str(b), a * b, a, c, a * c, right])
	else:
		ex = K.choice(rng, "Which is equal to %s?" % right, "%d(%s)" % [a, inside],
			["%d(%dx %s %d)" % [a, a * b, sign, c], "%d(%s)" % [a + 1, inside], "%dx(%d %s %d)" % [a, b, sign, c]],
			"Find the greatest number that goes into both parts.", "%d goes into %d and %d: %d(%s)." % [a, a * b, a * c, a, inside])
	ex.data = {"a": a, "b": b, "c": c, "minus": minus}
	return ex


## "2x + 5x = ?", "4a + 3 + 2a = ?"
static func like_terms(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var coefs: Array[int] = [rng.randi_range(1, 9), rng.randi_range(1, 9)]
	var consts: Array[int] = []
	if level > 1:
		consts.append(rng.randi_range(1, 9))
	if level == 3:
		coefs[1] = -rng.randi_range(1, coefs[0])
		consts.append(-rng.randi_range(1, consts[0]))
	var total := coefs[0] + coefs[1]
	var c_total := 0
	for c in consts:
		c_total += c
	var parts: Array[String] = ["%s" % _term(coefs[0])]
	if not consts.is_empty():
		parts.append("+ %d" % consts[0])
	parts.append(("+ %s" % _term(coefs[1])) if coefs[1] > 0 else ("− %s" % _term(-coefs[1])))
	if consts.size() > 1:
		parts.append("− %d" % -consts[1])
	var right := _term(total) if c_total == 0 else "%s + %d" % [_term(total), c_total]
	if total == 0:
		right = str(c_total)
	var wrongs: Array = ["%s + %d" % [_term(total + 1), c_total] if c_total != 0 else _term(total + 1),
		"%dx" % (total + c_total) if c_total != 0 else _term(maxi(1, total - 1) if total != 2 else 3),
		"%s + %d" % [_term(coefs[0]), absi(coefs[1]) + c_total]]
	var ex := K.choice(rng, "Simplify: %s" % " ".join(parts), right, wrongs.filter(func(w: String) -> bool: return w != right),
		"Add the x terms together and the numbers together.", "x terms: %d; numbers: %d. So %s." % [total, c_total, right])
	ex.data = {"coefs": coefs, "consts": consts}
	return ex


## "4(x + 2) = 4x + 8" true or false.
static func equivalent_tf(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var c := rng.randi_range(1, 9)
	var claimed := a * c
	if rng.randf() < 0.5:
		claimed = c if a * c != c else c + 1
	var right := claimed == a * c
	var ex := K.truefalse("%d(x + %d) = %dx + %d" % [a, c, a, claimed], right, "Multiply both parts inside the brackets by %d." % a,
		"%d(x + %d) = %dx + %d, so it is %s." % [a, c, a, a * c, "true" if right else "false"])
	ex.data = {"a": a, "c": c, "claimed": claimed}
	return ex


# --- Unit 12: equations and inequalities (6.EE.5-8) ---------------------------------------------------------------------

## "x + 7 = 12", "3x = 21", "x ÷ 4 = 6"; level 3 has decimal answers.
static func solve_one_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ops: Array = ["+", "×"] if level == 1 else ["+", "−", "×", "÷"]
	var op: String = ops[rng.randi_range(0, ops.size() - 1)]
	var a := rng.randi_range(2, 12)
	var x1000 := rng.randi_range(1, 15) * 1000
	if level == 3:
		x1000 = rng.randi_range(3, 39) * 500   # halves: 1.5, 2, 2.5 …
		if op == "÷":
			op = "×"
	var shown := ""
	var r1000 := 0
	match op:
		"+":
			r1000 = x1000 + a * 1000
			shown = "x + %d = %s" % [a, _dec(r1000)]
		"−":
			r1000 = x1000 - a * 1000
			if r1000 <= 0:
				x1000 += a * 1000
				r1000 = x1000 - a * 1000
			shown = "x − %d = %s" % [a, _dec(r1000)]
		"×":
			r1000 = x1000 * a
			shown = "%dx = %s" % [a, _dec(r1000)]
		_:
			r1000 = x1000 / a if x1000 % a == 0 else 0
			if r1000 == 0:
				x1000 = rng.randi_range(1, 10) * a * 1000
				r1000 = x1000 / a
			shown = "x ÷ %d = %s" % [a, _dec(r1000)]
	var undo: String = {"+": "take away %d" % a, "−": "add %d" % a, "×": "divide by %d" % a, "÷": "multiply by %d" % a}[op]
	var ex := K.number("Solve: %s. What is x?" % shown, _dec(x1000), "Do the opposite: %s on both sides." % undo,
		"%s both sides: x = %s." % [undo.capitalize(), _dec(x1000)])
	ex.data = {"op": op, "a": a, "x1000": x1000}
	return ex


## "Which value makes x > 5 true?"
static func inequality(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ops: Array = [">", "<"] if level == 1 else [">", "<", "≥", "≤"]
	var op: String = ops[rng.randi_range(0, ops.size() - 1)]
	var n := rng.randi_range(2, 15)
	var ex: Dictionary
	if level < 3:
		var yes := 0
		var nos: Array = []
		match op:
			">":
				yes = n + rng.randi_range(1, 5)
				nos = [n, n - rng.randi_range(1, 2)]
			"<":
				yes = n - rng.randi_range(1, 2)
				nos = [n, n + rng.randi_range(1, 5)]
			"≥":
				yes = n
				nos = [n - 1, n - rng.randi_range(2, 4)]
			_:
				yes = n
				nos = [n + 1, n + rng.randi_range(2, 4)]
		ex = K.choice(rng, "Which value of x makes x %s %d true?" % [op, n], str(yes), nos.map(func(v: int) -> String: return str(v)),
			"Try each value in place of x.", "%d %s %d is true." % [yes, op, n])
		ex.data = {"op": op, "n": n}
	else:
		var rows: Array = [["at least %d players" % n, "p ≥ %d" % n], ["fewer than %d players" % n, "p < %d" % n],
			["more than %d players" % n, "p > %d" % n], ["at most %d players" % n, "p ≤ %d" % n]]
		var pick := rng.randi_range(0, rows.size() - 1)
		var wrongs: Array = []
		for i in rows.size():
			if i != pick:
				wrongs.append(rows[i][1])
		ex = K.choice(rng, "A team needs %s. Which inequality shows this?" % rows[pick][0], rows[pick][1], wrongs,
			"\"At least\" includes the number; \"more than\" doesn't.", "\"%s\" is %s." % [rows[pick][0], rows[pick][1]])
		ex.data = {"op": str(rows[pick][1]).get_slice(" ", 1), "n": n}
	return ex


# --- Unit 13: variables that change together (6.EE.9) -------------------------------------------------------------------

## "y = 3x + 1. When x = 4, y = ?"; level 3: which equation fits a table.
static func table_rule(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var m := rng.randi_range(2, 9)
	var c := 0 if level == 1 else rng.randi_range(1, 9)
	var x := rng.randi_range(2, 12)
	var ex: Dictionary
	var rule := "y = %dx" % m if c == 0 else "y = %dx + %d" % [m, c]
	if level < 3:
		if level == 1:
			ex = K.number("%s. When x = %d, what is y?" % [rule, x], str(m * x + c), "Put %d in place of x." % x,
				"y = %d × %d%s = %d." % [m, x, (" + %d" % c) if c > 0 else "", m * x + c])
		else:
			var pairs: Array[String] = []
			for i in range(1, 4):
				pairs.append("(%d, %d)" % [i, m * i + c])
			ex = K.number("A table of (x, y) pairs: %s. The rule stays the same. What is y when x = %d?" % [", ".join(pairs), x],
				str(m * x + c), "How much does y go up each time x goes up by 1?",
				"y goes up by %d each time, so the rule is %s; y = %d." % [m, rule, m * x + c])
	else:
		var pairs: Array[String] = []
		for i in range(1, 4):
			pairs.append("(%d, %d)" % [i, m * i + c])
		ex = K.choice(rng, "Which equation fits the pairs %s?" % ", ".join(pairs), rule,
			["y = %dx + %d" % [c, m] if c != m else "y = %dx + %d" % [m + 1, c], "y = x + %d" % (m + c), "y = %dx" % (m + c)],
			"Check each equation with x = 1, then x = 2.", "%s gives %s." % [rule, ", ".join(pairs)])
	ex.data = {"m": m, "c": c, "x": x}
	return ex


# --- Unit 14: area (6.G.1) -----------------------------------------------------------------------------------------------

## The area of a triangle, a parallelogram or a trapezium; level 3 adds a trapezium or a two-part shape.
static func area(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var shapes: Array = ["triangle"] if level == 1 else (["triangle", "parallelogram"] if level == 2 else ["trapezium", "house"])
	var shape: String = shapes[rng.randi_range(0, shapes.size() - 1)]
	var b := rng.randi_range(2, 12) * 2
	var h := rng.randi_range(2, 12)
	var t := rng.randi_range(1, 6) * 2   # the trapezium's top, or the roof's height
	var ex: Dictionary
	match shape:
		"triangle":
			ex = K.number("A triangle has a base of %d cm and a height of %d cm. What is its area in cm²?" % [b, h], str(b * h / 2),
				"A triangle is half of a rectangle.", "½ × %d × %d = %d cm²." % [b, h, b * h / 2])
		"parallelogram":
			ex = K.number("A parallelogram has a base of %d cm and a height of %d cm. What is its area in cm²?" % [b, h], str(b * h),
				"Cut off a triangle and move it: it makes a rectangle.", "%d × %d = %d cm²." % [b, h, b * h])
		"trapezium":
			var top := b - t if b - t > 0 else b + t
			ex = K.number("A trapezium has parallel sides of %d cm and %d cm and a height of %d cm. What is its area in cm²?" % [top, b, h],
				str((top + b) * h / 2), "Add the parallel sides, halve it, then multiply by the height.",
				"(%d + %d) ÷ 2 × %d = %d cm²." % [top, b, h, (top + b) * h / 2])
		_:
			ex = K.number("A house shape is a rectangle %d cm wide and %d cm tall with a triangle roof %d cm high on top. What is its area in cm²?" % [b, h, t],
				str(b * h + b * t / 2), "Find the rectangle and the triangle, then add.",
				"%d × %d = %d, and ½ × %d × %d = %d: %d cm²." % [b, h, b * h, b, t, b * t / 2, b * h + b * t / 2])
	ex.data = {"shape": shape, "b": b, "h": h, "t": t}
	return ex


# --- Unit 15: volume and surface area (6.G.2, 6.G.4) -------------------------------------------------------------------

## A box with fraction edges; level 3: how many small cubes fill it.
static func volume_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var edges: Array = [[1, 2], [rng.randi_range(1, 6), 1], [rng.randi_range(2, 6), 1]]
	if level > 1:
		edges[1] = [rng.randi_range(1, 5) * 2 + 1, 2]
	var num := 1
	var den := 1
	for e: Array in edges:
		num *= int(e[0])
		den *= int(e[1])
	var v := _reduced(num, den)
	var shown := " × ".join(edges.map(func(e: Array) -> String: return str(e[0]) if int(e[1]) == 1 else K.frac(int(e[0]), int(e[1]))))
	var ex: Dictionary
	if level < 3:
		ex = K.number("A box is %s m. What is its volume in m³?" % shown.replace(" × ", " m by ").trim_suffix(" m"), _frac_text(v),
			"Volume = length × width × height, fractions too.", "%s = %s m³." % [shown, _frac_text(v)])
		var dec := _decimal(v)
		if dec != "":
			ex.accept = [dec]
		ex.data = {"edges": edges, "cube": 1}
	else:
		var cubes := num * 8 / den   # half-unit cubes: 2 × 2 × 2 = 8 in each unit cube
		ex = K.number("A box is %s cm. How many cubes with ½ cm edges fill it?" % shown.replace(" × ", " cm by ").trim_suffix(" cm"), str(cubes),
			"Each 1 cm cube holds 8 cubes with ½ cm edges.", "Its volume is %s cm³, and %s × 8 = %d cubes." % [_frac_text(v), _frac_text(v), cubes])
		ex.data = {"edges": edges, "cube": 2}
	return ex


## The surface area of a cube or a box, from its net.
static func surface_area(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var l := rng.randi_range(2, 9)
	var w := l if level == 1 else rng.randi_range(2, 9)
	var h := l if level == 1 else rng.randi_range(2, 9)
	var s := 2 * (l * w + l * h + w * h)
	var what := "A cube has edges of %d cm." % l if level == 1 else "A box is %d cm long, %d cm wide and %d cm high." % [l, w, h]
	var ex := K.number("%s What is its surface area in cm²?" % what, str(s), "Unfold it into a net: add the areas of all 6 faces.",
		"2 × (%d × %d + %d × %d + %d × %d) = %d cm²." % [l, w, l, h, w, h, s])
	ex.data = {"l": l, "w": w, "h": h}
	return ex


# --- Unit 16: statistics (6.SP.1-3, 6.SP.5) -------------------------------------------------------------------------------

## The mean, median, range or interquartile range of a small data set.
static func centre_spread(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var asks: Array = ["range", "median"] if level == 1 else (["mean", "median"] if level == 2 else ["iqr", "mean"])
	var ask: String = asks[rng.randi_range(0, asks.size() - 1)]
	var n := 8 if ask == "iqr" else rng.randi_range(5, 7)
	var values: Array[int] = []
	for _i in n:
		values.append(rng.randi_range(1, 20))
	if ask == "mean":
		var total := 0
		for v in values:
			total += v
		values[0] += (n - total % n) % n   # a whole-number mean
	var sorted := values.duplicate()
	sorted.sort()
	var answer := ""
	var how := ""
	match ask:
		"range":
			answer = str(sorted[-1] - sorted[0])
			how = "%d − %d = %s." % [sorted[-1], sorted[0], answer]
		"median":
			answer = _half_text(_median2(sorted))
			how = "In order: %s. The middle is %s." % [", ".join(sorted.map(func(v: int) -> String: return str(v))), answer]
		"mean":
			var total := 0
			for v in values:
				total += v
			answer = str(total / n)
			how = "%d ÷ %d = %s." % [total, n, answer]
		_:
			var q1 := _median2(sorted.slice(0, 4))
			var q3 := _median2(sorted.slice(4, 8))
			answer = _half_text(q3 - q1)
			how = "In order: %s. Q1 = %s, Q3 = %s, so %s." % [", ".join(sorted.map(func(v: int) -> String: return str(v))), _half_text(q1),
				_half_text(q3), answer]
	var word: String = {"range": "range", "median": "median", "mean": "mean", "iqr": "interquartile range"}[ask]
	var ex := K.number("Data: %s. What is the %s?" % [", ".join(values.map(func(v: int) -> String: return str(v))), word], answer,
		{"range": "Biggest take away smallest.", "median": "Put them in order and find the middle.",
			"mean": "Add them all, then divide by how many.", "iqr": "Find the middle of each half, then subtract."}[ask], how)
	ex.data = {"values": values, "ask": ask}
	return ex


## "Which is a statistical question?"
static func stat_question(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var i := rng.randi_range(0, STAT_QUESTIONS.size() - 1)
	var row: Array = STAT_QUESTIONS[i]
	var ex := K.choice(rng, "Which is a statistical question?" if level < 3 else "Which question expects answers that vary?", row[0], row[1],
		"A statistical question has many different answers to collect.", "\"%s\" collects many answers that vary." % row[0])
	ex.data = {"i": i}
	return ex


# --- Unit 17: dot plots, histograms and box plots (6.SP.4) -------------------------------------------------------------

## A box plot's five numbers: the range, the interquartile range, or what the box holds.
static func box_plot(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var five: Array[int] = [rng.randi_range(0, 10)]
	for _i in 4:
		five.append(five[-1] + rng.randi_range(1, 8))
	var shown := "smallest %d, lower quartile %d, median %d, upper quartile %d, largest %d" % five
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A box plot shows: %s. What is the median?" % shown, str(five[2]), "The line inside the box.",
				"The median is %d." % five[2])
		2:
			ex = K.number("A box plot shows: %s. What is the interquartile range?" % shown, str(five[3] - five[1]),
				"Upper quartile take away lower quartile.", "%d − %d = %d." % [five[3], five[1], five[3] - five[1]])
		_:
			ex = K.choice(rng, "A box plot shows: %s. About what part of the data is between %d and %d?" % [shown, five[1], five[3]], "half",
				["a quarter", "all of it", "none of it"], "The box goes from one quartile to the other.",
				"The box holds the middle half of the data.")
	ex.data = {"five": five}
	return ex


## A dot plot or a histogram bar, counted from the data.
static func dot_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 7 if level == 1 else 10
	var values: Array[int] = []
	var lo := 0
	var hi := 0
	var ex: Dictionary
	if level < 3:
		for _i in n:
			values.append(rng.randi_range(1, 6))
		var v := values[rng.randi_range(0, n - 1)]
		var count := values.count(v)
		lo = v
		hi = v
		ex = K.number("Pets owned by %d pupils: %s. On a dot plot, how many dots stand above %d?" % [n, ", ".join(values.map(func(x: int) -> String: return str(x))), v],
			str(count), "Count how many times %d appears." % v, "%d appears %d times." % [v, count])
	else:
		for _i in n:
			values.append(rng.randi_range(120, 159))
		lo = [120, 130, 140, 150][rng.randi_range(0, 3)]
		hi = lo + 9
		var count := 0
		for x in values:
			if x >= lo and x <= hi:
				count += 1
		ex = K.number("Heights in cm: %s. A histogram has a bar for %d to %d cm. How tall is that bar (how many pupils)?" % [", ".join(values.map(func(x: int) -> String: return str(x))), lo, hi],
			str(count), "Count the heights from %d to %d." % [lo, hi], "%d heights are from %d to %d." % [count, lo, hi])
	ex.data = {"values": values, "lo": lo, "hi": hi}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------------

static func _nonzero(rng: RandomNumberGenerator, top: int) -> int:
	var v := rng.randi_range(1, top)
	return v if rng.randf() < 0.5 else -v


## 0-3: the quadrant of a point off the axes.
static func _quadrant_of(x: int, y: int) -> int:
	if x > 0:
		return 0 if y > 0 else 3
	return 1 if y > 0 else 2


static func _signed(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


static func _sup(n: int) -> String:
	var out := ""
	for ch in str(n):
		out += "⁰¹²³⁴⁵⁶⁷⁸⁹"[int(ch)]
	return out


## "x", "3x", "−2x"
static func _term(c: int) -> String:
	if c == 1:
		return "x"
	if c == -1:
		return "−x"
	return ("−%dx" % -c) if c < 0 else "%dx" % c


## Thousandths as a decimal: 4500 -> "4.5".
static func _dec(thousandths: int) -> String:
	var t := absi(thousandths)
	var out := K.fmt(t / 1000)
	if t % 1000 != 0:
		out += "." + str(t % 1000).pad_zeros(3).rstrip("0")
	return ("-" if thousandths < 0 else "") + out


static func _reduced(num: int, den: int) -> Array:
	var g := NumberAnswer.gcd(absi(num), absi(den))
	return [num / g, den / g]


static func _frac_text(f: Array) -> String:
	return str(f[0]) if int(f[1]) == 1 else K.frac(int(f[0]), int(f[1]))


static func _decimal(f: Array) -> String:
	if int(f[1]) == 1:
		return ""
	for places in [1, 2, 3]:
		var scale := K.pow10(places)
		if (int(f[0]) * scale) % int(f[1]) == 0:
			return _dec(int(f[0]) * scale / int(f[1]) * 1000 / scale)
	return ""


## Twice the median of sorted whole numbers (so a half stays whole).
static func _median2(sorted: Array) -> int:
	var n := sorted.size()
	if n % 2 == 1:
		return 2 * int(sorted[n / 2])
	return int(sorted[n / 2 - 1]) + int(sorted[n / 2])


## A doubled value as text: 15 -> "7.5", 14 -> "7".
static func _half_text(twice: int) -> String:
	return str(twice / 2) if twice % 2 == 0 else "%d.5" % (twice / 2)
