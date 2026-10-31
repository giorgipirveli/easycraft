class_name G8AlgebraGen
extends RefCounted
## Owner #68 (spec §22.5): grade 8 maths generators for the number system, expressions and equations, and functions
## (Common Core 8.NS, 8.EE, 8.F.1-3; units 1-8 of the outline): SchoolGen "g8n.<name>", `static func <name>(rng:
## RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a worked answer and `data`
## (its inputs, for tests/unit/test_g8_maths_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const RATIONAL: Array[String] = ["3/4", "0.5", "−7", "0.333…", "√16", "2.25", "√49", "1/9"]
const IRRATIONAL: Array[String] = ["√2", "√3", "π", "√5", "√10", "√7"]


# --- Unit 1: rational and irrational numbers (8.NS.1, 8.NS.2) -----------------------------------------------------------

## Which is irrational; levels 2-3: √n lies between which whole numbers?
static func irrational(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var right: String = IRRATIONAL[rng.randi_range(0, IRRATIONAL.size() - 1)]
		var wrongs: Array = RATIONAL.duplicate()
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "Which number is irrational?", right, wrongs.slice(0, 3),
			"An irrational number can't be written as a fraction; its decimal never ends or repeats.",
			"%s never ends or repeats; the others can be written as fractions." % right)
		ex.data = {"n": 0, "right": right}
	else:
		var lo := rng.randi_range(1, 12 if level == 2 else 20)
		var n := rng.randi_range(lo * lo + 1, (lo + 1) * (lo + 1) - 1)
		var right := "between %d and %d" % [lo, lo + 1]
		ex = K.choice(rng, "√%d lies between which two whole numbers?" % n, right,
			["between %d and %d" % [lo - 1, lo] if lo > 1 else "between %d and %d" % [lo + 2, lo + 3], "between %d and %d" % [lo + 1, lo + 2]],
			"Find the square numbers either side of %d." % n, "%d² = %d and %d² = %d, so √%d is between %d and %d." % [lo, lo * lo, lo + 1,
				(lo + 1) * (lo + 1), n, lo, lo + 1])
		ex.data = {"n": n, "right": right}
	return ex


# --- Unit 2: exponent rules (8.EE.1) ------------------------------------------------------------------------------------

## "2³ × 2⁴ = 2^?" and friends: the answer is the new exponent (or a value at level 3).
static func exponent_rules(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var base := rng.randi_range(2, 9)
	var a := rng.randi_range(2, 8)
	var b := rng.randi_range(2, 6)
	var rules: Array = ["times", "divide"] if level == 1 else ["times", "divide", "power"]
	var rule: String = rules[rng.randi_range(0, rules.size() - 1)]
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.5:
		var e := -rng.randi_range(1, 3) if rng.randf() < 0.7 else 0
		var v := _reduced(1, int(pow(mini(base, 5), -e))) if e < 0 else [1, 1]
		base = mini(base, 5)
		var shown_pow := "%d%s" % [base, _sup(e)] if e >= 0 else "%d to the power of −%d" % [base, -e]
		ex = K.number("%s = ?" % shown_pow, _frac_text(v), "A negative exponent means 1 over the power; any number to the 0 is 1.",
			"%s = %s." % [shown_pow, _frac_text(v)])
		ex.data = {"rule": "value", "base": base, "a": e, "b": 0}
		return ex
	if rule == "divide" and b >= a:
		a = b + rng.randi_range(1, 4)
	var shown := ""
	var e := 0
	match rule:
		"times":
			shown = "%d%s × %d%s" % [base, _sup(a), base, _sup(b)]
			e = a + b
		"divide":
			shown = "%d%s ÷ %d%s" % [base, _sup(a), base, _sup(b)]
			e = a - b
		_:
			shown = "(%d%s)%s" % [base, _sup(a), _sup(b)]
			e = a * b
	ex = K.number("%s = %d to the power of what?" % [shown, base], str(e),
		{"times": "Multiplying powers of the same number: add the exponents.", "divide": "Dividing: take away the exponents.",
			"power": "A power of a power: multiply the exponents."}[rule], "%s = %d%s." % [shown, base, _sup(e)])
	ex.data = {"rule": rule, "base": base, "a": a, "b": b}
	return ex


# --- Unit 3: square and cube roots (8.EE.2) -----------------------------------------------------------------------------

## "√144 = ?", "∛27 = ?" (written "the cube root of 27"), "x² = 81, x > 0"
static func roots(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var r := rng.randi_range(2, 15)
			ex = K.number("√%d = ?" % (r * r), str(r), "Which number times itself makes %d?" % (r * r), "%d × %d = %d." % [r, r, r * r])
			ex.data = {"kind": "square", "r": r}
		2:
			var r := rng.randi_range(2, 10)
			ex = K.number("What is the cube root of %d?" % (r * r * r), str(r), "Which number times itself three times makes %d?" % (r * r * r),
				"%d × %d × %d = %d." % [r, r, r, r * r * r])
			ex.data = {"kind": "cube", "r": r}
		_:
			var r := rng.randi_range(2, 12)
			var cube := rng.randf() < 0.4
			if cube:
				r = mini(r, 6)
				ex = K.number("Solve: x³ = %d. What is x?" % (r * r * r), str(r), "Find the cube root.", "%d³ = %d, so x = %d." % [r, r * r * r, r])
			else:
				ex = K.number("Solve: x² = %d, where x is positive. What is x?" % (r * r), str(r), "Find the square root.",
					"%d² = %d, so x = %d (and −%d also squares to %d)." % [r, r * r, r, r, r * r])
			ex.data = {"kind": "cube" if cube else "square", "r": r}
	return ex


# --- Unit 4: scientific notation (8.EE.3, 8.EE.4) -----------------------------------------------------------------------

## "45,000 = 4.5 × 10^?", "0.0003 = 3 × 10^?", "(3 × 10⁴) × (2 × 10³) = 6 × 10^?"
static func sci_notation(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var m10 := rng.randi_range(11, 99)   # the front number in tenths: 1.1 … 9.9
	if m10 % 10 == 0:
		m10 += 1
	var ex: Dictionary
	match level:
		1:
			var e := rng.randi_range(3, 8)
			var n := m10 * int(pow(10, e - 1))
			ex = K.number("%s = %s × 10 to the power of what?" % [K.fmt(n), _dec10(m10)], str(e),
				"Count how many places the decimal point moves.", "%s = %s × 10%s." % [K.fmt(n), _dec10(m10), _sup(e)])
			ex.data = {"kind": "big", "m10": m10, "e": e}
		2:
			var e := -rng.randi_range(2, 6)
			var zeros := -e - 1
			var text := "0." + "0".repeat(zeros) + str(m10).rstrip("0")
			ex = K.number("%s = %s × 10 to the power of what?" % [text, _dec10(m10)], str(e),
				"Small numbers have negative exponents: count the places the point moves right.",
				"%s = %s × 10 to the power of −%d." % [text, _dec10(m10), -e])
			ex.data = {"kind": "small", "m10": m10, "e": e}
		_:
			var a := rng.randi_range(1, 4)
			var b := rng.randi_range(1, 2)
			var p := rng.randi_range(2, 6)
			var q := rng.randi_range(2, 6)
			ex = K.number("(%d × 10%s) × (%d × 10%s) = %d × 10 to the power of what?" % [a, _sup(p), b, _sup(q), a * b], str(p + q),
				"Multiply the front numbers; add the exponents.", "%d × %d = %d and 10%s × 10%s = 10%s." % [a, b, a * b, _sup(p), _sup(q), _sup(p + q)])
			ex.data = {"kind": "times", "m10": a * b * 10, "e": p + q}
	return ex


# --- Unit 5: slope (8.EE.5, 8.EE.6) -------------------------------------------------------------------------------------

## The slope between two points, or read from y = mx + b.
static func slope(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var m := rng.randi_range(1, 6) * (1 if level == 1 or rng.randf() < 0.6 else -1)
	var b := rng.randi_range(-5, 8)
	var ex: Dictionary
	if level < 3:
		var x1 := rng.randi_range(0, 4)
		var x2 := x1 + rng.randi_range(1, 4)
		var y1 := m * x1 + b
		var y2 := m * x2 + b
		ex = K.number("What is the slope of the line through (%d, %s) and (%d, %s)?" % [x1, _signed(y1), x2, _signed(y2)], str(m),
			"Slope = change in y ÷ change in x.", "(%s − %s) ÷ (%d − %d) = %s." % [_signed(y2), _bracket(y1), x2, x1, _signed(m)])
		ex.data = {"m": m, "b": b, "ask": "m"}
	else:
		var ask := "m" if rng.randf() < 0.5 else "b"
		var eq := "y = %dx %s %d" % [m, "+" if b >= 0 else "−", absi(b)]
		ex = K.number("In %s, what is the %s?" % [eq, "slope" if ask == "m" else "y-intercept (where the line crosses the y-axis)"],
			str(m) if ask == "m" else str(b), "In y = mx + b, m is the slope and b is the y-intercept.",
			"The %s is %s." % ["slope" if ask == "m" else "y-intercept", _signed(m if ask == "m" else b)])
		ex.data = {"m": m, "b": b, "ask": ask}
	return ex


# --- Unit 6: linear equations (8.EE.7) ----------------------------------------------------------------------------------

## "5x + 3 = 2x + 12"; level 3: one, no or many solutions.
static func both_sides(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(3, 9)
	var c := rng.randi_range(1, a - 1)
	var x := rng.randi_range(-4 if level > 1 else 1, 10)
	var b := rng.randi_range(1, 15)
	var d := (a - c) * x + b
	var ex: Dictionary
	if level < 3:
		ex = K.number("Solve: %dx + %d = %dx %s %d. What is x?" % [a, b, c, "+" if d >= 0 else "−", absi(d)], str(x),
			"Get the x terms on one side and the numbers on the other.", "%dx = %s, so x = %s." % [a - c, _signed(d - b), _signed(x)])
		ex.data = {"a": a, "b": b, "c": c, "d": d, "kind": "one"}
	else:
		var kinds: Array[String] = ["one", "none", "many"]
		var kind := kinds[rng.randi_range(0, 2)]
		var left := "%dx + %d" % [a, b]
		var right := ""
		match kind:
			"one":
				right = "%dx + %d" % [c, b + (a - c) * 2]
			"none":
				right = "%dx + %d" % [a, b + rng.randi_range(1, 5)]
			_:
				right = "%dx + %d" % [a, b]
		var words := {"one": "exactly one solution", "none": "no solution", "many": "infinitely many solutions"}
		ex = K.choice(rng, "How many solutions does %s = %s have?" % [left, right], words[kind],
			(words.values() as Array).filter(func(w: String) -> bool: return w != words[kind]),
			"Compare the x terms, then the numbers.", "It has %s." % words[kind])
		ex.data = {"a": a, "b": b, "c": c, "d": 0, "kind": kind}
	return ex


# --- Unit 7: systems of equations (8.EE.8) ------------------------------------------------------------------------------

## "y = x + 3 and y = 2x": what is x (or y)?
static func system(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var x := rng.randi_range(-3 if level == 3 else 1, 8)
	var y := rng.randi_range(-3 if level == 3 else 1, 12)
	var m1 := rng.randi_range(1, 4)
	var m2 := m1 + rng.randi_range(1, 3)
	var b1 := y - m1 * x
	var b2 := y - m2 * x
	var ask := "x" if level == 1 or rng.randf() < 0.5 else "y"
	var eq1 := _line(m1, b1)
	var eq2 := _line(m2, b2)
	var ex := K.number("Solve together: %s and %s. What is %s?" % [eq1, eq2, ask], str(x if ask == "x" else y),
		"Set the two right-hand sides equal to find x.", "%s = %s gives x = %s, and then y = %s." % [eq1.trim_prefix("y = "), eq2.trim_prefix("y = "), _signed(x), _signed(y)])
	ex.data = {"x": x, "y": y, "m1": m1, "b1": b1, "m2": m2, "b2": b2, "ask": ask}
	return ex


# --- Unit 8: functions (8.F.1-3) ----------------------------------------------------------------------------------------

## Is a set of pairs a function? Level 3: linear or not from a table.
static func is_function(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var xs: Array[int] = [1, 2, 3, 4]
		var repeat := rng.randf() < 0.5
		var pairs: Array[String] = []
		for i in xs.size():
			var x := xs[i] if not (repeat and i == 3) else xs[1]
			pairs.append("(%d, %d)" % [x, rng.randi_range(1, 9) + i * 10])
		ex = K.truefalse("Is this set of (input, output) pairs a function: %s?" % ", ".join(pairs), not repeat,
			"A function gives exactly one output for each input.",
			("Yes: each input has one output." if not repeat else "No: the input 2 has two different outputs."))
		ex.data = {"repeat": repeat, "linear": false}
	else:
		var linear := rng.randf() < 0.5
		var m := rng.randi_range(2, 5)
		var c := rng.randi_range(0, 5)
		var pairs: Array[String] = []
		for x in range(1, 5):
			pairs.append("(%d, %d)" % [x, m * x + c if linear else x * x + c])
		ex = K.choice(rng, "Is the function with pairs %s linear?" % ", ".join(pairs), "yes, it goes up evenly" if linear else "no, it curves",
			["no, it curves" if linear else "yes, it goes up evenly"], "Does y go up by the same amount each time x goes up by 1?",
			("Yes: y goes up by %d each time." % m) if linear else "No: y goes up by more each time.")
		ex.data = {"repeat": false, "linear": linear}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------------

static func _signed(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


static func _bracket(v: int) -> String:
	return "(−%d)" % -v if v < 0 else str(v)


## Superscript digits (the font has no superscript minus: negative exponents are written in words).
static func _sup(n: int) -> String:
	var out := ""
	for ch in str(absi(n)):
		out += "⁰¹²³⁴⁵⁶⁷⁸⁹"[int(ch)]
	return out


static func _dec10(tenths: int) -> String:
	return str(tenths / 10) if tenths % 10 == 0 else "%d.%d" % [tenths / 10, tenths % 10]


static func _reduced(num: int, den: int) -> Array:
	var g := NumberAnswer.gcd(absi(num), absi(den))
	return [num / g, den / g]


static func _frac_text(f: Array) -> String:
	return str(f[0]) if int(f[1]) == 1 else "%d/%d" % [f[0], f[1]]


## "y = 2x + 3", "y = x − 1", "y = 3x"
static func _line(m: int, b: int) -> String:
	var mx := "x" if m == 1 else "%dx" % m
	if b == 0:
		return "y = %s" % mx
	return "y = %s %s %d" % [mx, "+" if b > 0 else "−", absi(b)]
