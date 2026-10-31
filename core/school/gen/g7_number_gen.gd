class_name G7NumberGen
extends RefCounted
## Owner #68 (spec §22.5): grade 7 maths generators for proportional relationships, percent, the rational numbers and
## algebra (Common Core 7.RP, 7.NS, 7.EE; units 1-8 of the outline): SchoolGen "g7n.<name>", `static func <name>(rng:
## RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint, a worked answer and `data`
## (its inputs, for tests/unit/test_g7_maths_gen.gd). Fractions are worked as [top, bottom], never floats. Helpers
## start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]


# --- Unit 1: proportional relationships (7.RP.1, 7.RP.2) ----------------------------------------------------------------

## "A snail crawls 1/2 m in 1/4 hour. How many metres an hour?"
static func unit_rate_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(1, 5)
	var b: int = 1 if level == 1 else [2, 3, 4][rng.randi_range(0, 2)]
	var c := 1
	var d: int = [2, 3, 4, 5][rng.randi_range(0, 3)]
	if level == 3:
		c = rng.randi_range(2, 3)
		d = c + rng.randi_range(1, 3)
	var q := _reduced(a * d, b * c)
	var dist := str(a) if b == 1 else K.frac(a, b)
	var time := K.frac(c, d)
	var ex := K.number("A snail crawls %s m in %s of an hour. How many metres is that in one hour?" % [dist, time], _frac_text(q),
		"Divide the distance by the time.", "%s ÷ %s = %s m an hour." % [dist, time, _frac_text(q)])
	var dec := _decimal(q)
	if dec != "":
		ex.accept = [dec]
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "Is y proportional to x? (1, 3), (2, 6), (4, 12)"
static func is_proportional(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var k := rng.randi_range(2, 9)
	var c := 0 if rng.randf() < 0.5 else rng.randi_range(1, 5)
	var ex: Dictionary
	if level < 3:
		var xs: Array = [1, 2, rng.randi_range(3, 6)] if level == 1 else [2, rng.randi_range(3, 5), rng.randi_range(6, 9)]
		var pairs: Array[String] = []
		for x in xs:
			pairs.append("(%d, %d)" % [x, k * x + c])
		ex = K.truefalse("Is y proportional to x in these pairs: %s?" % ", ".join(pairs), c == 0,
			"Proportional means y ÷ x is the same for every pair.",
			("Yes: y ÷ x is always %d." % k) if c == 0 else "No: y ÷ x changes (%d ÷ %d is not %d ÷ %d)." % [k * xs[0] + c, xs[0], k * xs[1] + c, xs[1]])
	else:
		var eq := "y = %dx" % k if c == 0 else "y = %dx + %d" % [k, c]
		ex = K.truefalse("Is %s a proportional relationship?" % eq, c == 0, "A proportional graph is a straight line through (0, 0).",
			("Yes: when x = 0, y = 0." if c == 0 else "No: when x = 0, y = %d, so it doesn't pass through (0, 0)." % c))
	ex.data = {"k": k, "c": c}
	return ex


## "(2, 7), (4, 14), (6, 21): the constant of proportionality?"
static func constant_k(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var k10 := rng.randi_range(2, 9) * 10 if level == 1 else rng.randi_range(3, 19) * 5
	var xs: Array = [2, 4, 6] if level < 3 else [2, 6, 10]
	var pairs: Array[String] = []
	for x in xs:
		pairs.append("(%d, %s)" % [x, _dec10(k10 * x)])
	var ex := K.number("The pairs %s are proportional. What is the constant of proportionality (y ÷ x)?" % ", ".join(pairs), _dec10(k10),
		"Divide any y by its x.", "%s ÷ %d = %s." % [_dec10(k10 * xs[0]), xs[0], _dec10(k10)])
	ex.data = {"k10": k10}
	return ex


# --- Unit 2: percent problems (7.RP.3) ----------------------------------------------------------------------------------

## "A price rises from 40 to 50 coins. By what percent?"
static func percent_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var up := level == 1 or (level == 3 and rng.randf() < 0.5)
	var p := rng.randi_range(1, 10) * 5
	if not up:
		p = mini(p, 45)
	var old := rng.randi_range(1, 10) * 20
	var change := old * p / 100
	var now := old + change if up else old - change
	var what := "rises" if up else "falls"
	var ex := K.number("A price %s from %d to %d coins. By what percent did it %s?" % [what, old, now, "rise" if up else "fall"], str(p),
		"Find the change, then divide by the old price.", "The change is %d; %d ÷ %d = %d%%." % [change, change, old, p])
	ex.data = {"old": old, "now": now}
	return ex


## Discounts, tax and simple interest.
static func discount_tax(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(2, 20) * 20
	var p := rng.randi_range(1, 6) * 5
	var ex: Dictionary
	match level:
		1:
			var sale := n - n * p / 100
			ex = K.number("A %d-coin kite is %d%% off. What is the sale price?" % [n, p], str(sale), "Find %d%% of %d and take it away." % [p, n],
				"%d%% of %d is %d; %d − %d = %d coins." % [p, n, n * p / 100, n, n * p / 100, sale])
			ex.data = {"kind": "discount", "n": n, "p": p, "years": 0}
		2:
			var total := n + n * p / 100
			ex = K.number("A %d-coin bike has %d%% tax added. What is the total?" % [n, p], str(total), "Find %d%% of %d and add it." % [p, n],
				"%d%% of %d is %d; %d + %d = %d coins." % [p, n, n * p / 100, n, n * p / 100, total])
			ex.data = {"kind": "tax", "n": n, "p": p, "years": 0}
		_:
			var years := rng.randi_range(2, 5)
			var interest := n * p * years / 100
			ex = K.number("%d gold is saved at %d%% simple interest a year. How much interest after %d years?" % [n, p, years], str(interest),
				"Find one year's interest, then times the years.", "%d%% of %d is %d a year; × %d = %d gold." % [p, n, n * p / 100, years, interest])
			ex.data = {"kind": "interest", "n": n, "p": p, "years": years}
	return ex


# --- Units 3 and 4: integers (7.NS.1, 7.NS.2) ---------------------------------------------------------------------------

## "−7 + 12 = ?", "5 − (−3) = ?", "−4 + 9 − 13 = ?"
static func add_integers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var terms: Array[int] = [rng.randi_range(-15, 15), rng.randi_range(-15, 15)]
	var ops: Array[String] = ["+"]
	if level == 1:
		terms[0] = -rng.randi_range(1, 12)
		terms[1] = rng.randi_range(1, 15)
	elif level == 2:
		ops = ["−"]
		terms[1] = -rng.randi_range(1, 12)
	else:
		ops = ["+" if rng.randf() < 0.5 else "−", "+" if rng.randf() < 0.5 else "−"]
		terms.append(rng.randi_range(-15, 15))
	var total := terms[0]
	var shown := _signed(terms[0])
	for i in ops.size():
		total += terms[i + 1] if ops[i] == "+" else -terms[i + 1]
		shown += " %s %s" % [ops[i], _bracket(terms[i + 1])]
	var ex := K.number("%s = ?" % shown, str(total), "Taking away a negative is the same as adding a positive.",
		"%s = %s." % [shown, _signed(total)])
	ex.data = {"terms": terms, "ops": ops}
	return ex


## "−6 × 4", "−8 × (−3)", "−42 ÷ 7"; level 3 has three factors.
static func multiply_integers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := _nonzero(rng, 12)
	var b := _nonzero(rng, 12)
	var op := "×" if level != 2 or rng.randf() < 0.4 else "÷"
	var factors: Array[int] = [a, b]
	var answer := a * b
	var shown := "%s × %s" % [_signed(a), _bracket(b)]
	if op == "÷":
		shown = "%s ÷ %s" % [_signed(a * b), _bracket(b)]
		answer = a
	elif level == 3:
		var c := _nonzero(rng, 5)
		factors.append(c)
		answer = a * b * c
		shown += " × %s" % _bracket(c)
	var negatives := 0
	for f in factors:
		if f < 0:
			negatives += 1
	var ex := K.number("%s = ?" % shown, str(answer), "An even number of negatives makes a positive; an odd number, a negative.",
		"%s = %s." % [shown, _signed(answer)])
	ex.data = {"factors": factors, "op": op}
	return ex


# --- Unit 5: rational numbers (7.NS.2d, 7.NS.3) --------------------------------------------------------------------------

## "3/8 as a decimal"; level 2: does it end or repeat?
static func frac_decimal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var dens: Array = [2, 4, 5, 8, 10, 20, 25] if level != 2 else [3, 6, 7, 9, 11, 4, 8, 5, 12]
	var d: int = dens[rng.randi_range(0, dens.size() - 1)]
	var n := rng.randi_range(1, d - 1)
	var g := NumberAnswer.gcd(n, d)
	n /= g
	d /= g
	if d == 1:
		d = 8
		n = 3
	var ex: Dictionary
	if level != 2:
		var dec := _decimal([n, d])
		if dec == "":
			d = 8
			n = 3
			dec = "0.375"
		ex = K.number("Write %s as a decimal." % K.frac(n, d), dec, "Divide %d by %d." % [n, d], "%d ÷ %d = %s." % [n, d, dec])
	else:
		var ends := _terminates(d)
		ex = K.choice(rng, "Does the decimal for %s end or repeat?" % K.frac(n, d), "it ends" if ends else "it repeats",
			["it repeats" if ends else "it ends"], "It ends only when the bottom number's factors are 2s and 5s.",
			"%d = %s, so the decimal %s." % [d, _factor_words(d), "ends" if ends else "repeats"])
	ex.data = {"n": n, "d": d}
	return ex


## "−1/2 + 3/4 = ?", "−2/3 × 3/5 = ?"
static func rational_ops(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b: int = [2, 3, 4, 5, 6][rng.randi_range(0, 4)]
	var d: int = [2, 3, 4, 5, 6][rng.randi_range(0, 4)]
	var a := -rng.randi_range(1, b - 1)
	var c := rng.randi_range(1, d - 1)
	var op: String = ["+", "−"][rng.randi_range(0, 1)] if level == 1 else (["×", "÷"][rng.randi_range(0, 1)] if level == 2 else ["+", "×", "÷"][rng.randi_range(0, 2)])
	var q: Array = []
	match op:
		"+":
			q = _reduced(a * d + c * b, b * d)
		"−":
			q = _reduced(a * d - c * b, b * d)
		"×":
			q = _reduced(a * c, b * d)
		_:
			q = _reduced(a * d, b * c)
	var shown := "%s %s %s" % [_frac_signed(a, b), op, K.frac(c, d)]
	var ex := K.number("%s = ?" % shown, _frac_text(q), {"+": "Use a common bottom number.", "−": "Use a common bottom number.",
		"×": "Multiply the tops and the bottoms; one negative makes a negative.", "÷": "Flip the second fraction and multiply."}[op],
		"%s = %s." % [shown, _frac_text(q)])
	var dec := _decimal(q)
	if dec != "":
		ex.accept = [dec]
	ex.data = {"a": a, "b": b, "c": c, "d": d, "op": op}
	return ex


# --- Unit 6: expressions (7.EE.1, 7.EE.2) --------------------------------------------------------------------------------

## "3(2x − 4) + 5x" -> "11x − 12"; level 3: factor.
static func expand_simplify(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 6)
	var b := rng.randi_range(1, 5)
	var c := rng.randi_range(1, 9)
	while NumberAnswer.gcd(b, c) != 1:   # so a is the greatest common factor
		c += 1
	var e := rng.randi_range(1, 9) if level > 1 else 0
	var x := a * b + e
	var k := a * c
	var ex: Dictionary
	if level < 3:
		var shown := "%d(%sx − %d)" % [a, "" if b == 1 else str(b), c]
		if e > 0:
			shown += " + %dx" % e
		var right := "%dx − %d" % [x, k]
		ex = K.choice(rng, "Simplify: %s" % shown, right, ["%dx − %d" % [x, c], "%dx + %d" % [x, k], "%dx − %d" % [a * b, k + e]],
			"Multiply out the brackets, then add the x terms.", "%d × %sx − %d × %d%s = %s." % [a, "" if b == 1 else str(b), a, c,
				(" + %dx" % e) if e > 0 else "", right])
	else:
		var right := "%d(%sx + %d)" % [a, "" if b == 1 else str(b), c]
		ex = K.choice(rng, "Factor: %dx + %d" % [a * b, k], right, ["%d(%dx + %d)" % [a, a * b, c], "%d(%sx + %d)" % [a + 1, "" if b == 1 else str(b), c],
			"%dx(%d + %d)" % [a, b, c]], "Find the greatest number that divides both.", "%d divides %d and %d: %s." % [a, a * b, k, right])
	ex.data = {"a": a, "b": b, "c": c, "e": e}
	return ex


# --- Unit 7: two-step equations (7.EE.3, 7.EE.4a) ------------------------------------------------------------------------

## "3x + 5 = 20", "x/4 − 2 = 3", "−2x + 7 = 15"
static func two_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var x := rng.randi_range(1, 12)
	var b := rng.randi_range(1, 20)
	var shown := ""
	var form := "ax+b"
	if level == 1:
		shown = "%dx + %d = %d" % [a, b, a * x + b]
	elif level == 2:
		form = "x/a-b"
		x = a * rng.randi_range(1, 9)
		shown = "x ÷ %d − %d = %d" % [a, b, x / a - b]
		if x / a - b < 0:
			shown = "x ÷ %d − %d = %s" % [a, b, _signed(x / a - b)]
	else:
		form = "-ax+b"
		x = -rng.randi_range(1, 9) if rng.randf() < 0.5 else rng.randi_range(1, 9)
		shown = "−%dx + %d = %s" % [a, b, _signed(-a * x + b)]
	var ex := K.number("Solve: %s. What is x?" % shown, str(x), "Undo the adding or taking away first, then the multiplying or dividing.",
		"x = %s (check it in the equation)." % _signed(x))
	ex.data = {"form": form, "a": a, "b": b, "x": x}
	return ex


# --- Unit 8: inequalities (7.EE.4b) --------------------------------------------------------------------------------------

## "2x − 3 > 7" -> "x > 5"; level 3 divides by a negative (the sign flips).
static func solve_inequality(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 6)
	var x := rng.randi_range(-5, 10)
	var b := rng.randi_range(1, 12)
	var ops: Array[String] = [">", "<", "≥", "≤"]
	var op := ops[rng.randi_range(0, 1 if level == 1 else 3)]
	var flip := {">": "<", "<": ">", "≥": "≤", "≤": "≥"}
	var shown := ""
	var right := ""
	if level < 3:
		shown = "%dx − %d %s %s" % [a, b, op, _signed(a * x - b)]
		right = "x %s %s" % [op, _signed(x)]
	else:
		shown = "−%dx + %d %s %s" % [a, b, op, _signed(-a * x + b)]
		right = "x %s %s" % [flip[op], _signed(x)]
	var wrongs: Array = ["x %s %s" % [flip[op], _signed(x)], "x %s %s" % [op, _signed(x + 1)]]
	if level == 3:
		wrongs = ["x %s %s" % [op, _signed(x)], "x %s %s" % [flip[op], _signed(-x)] if x != 0 else "x %s 1" % flip[op]]
	var ex := K.choice(rng, "Solve: %s" % shown, right, wrongs.filter(func(w: String) -> bool: return w != right),
		"Solve it like an equation. Dividing by a negative flips the sign." if level == 3 else "Solve it like an equation.",
		"The answer is %s." % right)
	ex.data = {"a": a, "b": b, "x": x, "op": op, "negative": level == 3}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------------

static func _nonzero(rng: RandomNumberGenerator, top: int) -> int:
	var v := rng.randi_range(1, top)
	return v if rng.randf() < 0.5 else -v


static func _signed(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


## A negative after an operator goes in brackets: "(−3)".
static func _bracket(v: int) -> String:
	return "(−%d)" % -v if v < 0 else str(v)


static func _reduced(num: int, den: int) -> Array:
	if den < 0:
		num = -num
		den = -den
	var g := NumberAnswer.gcd(absi(num), absi(den))
	return [num / g, den / g]


## A fraction for the answer pad: "-3/4", "5".
static func _frac_text(f: Array) -> String:
	return str(f[0]) if int(f[1]) == 1 else "%d/%d" % [f[0], f[1]]


static func _frac_signed(a: int, b: int) -> String:
	return ("−%s" % K.frac(-a, b)) if a < 0 else K.frac(a, b)


## Tenths as a decimal: 35 -> "3.5".
static func _dec10(tenths: int) -> String:
	return str(tenths / 10) if tenths % 10 == 0 else "%d.%d" % [tenths / 10, tenths % 10]


## The fraction as an exact decimal ("-0.75"), or "" (none, or whole).
static func _decimal(f: Array) -> String:
	if int(f[1]) == 1:
		return ""
	for places in [1, 2, 3]:
		var scale := K.pow10(places)
		if (int(f[0]) * scale) % int(f[1]) == 0:
			var v := int(f[0]) * scale / int(f[1])
			var t := absi(v)
			var digits := str(t % scale).pad_zeros(places).rstrip("0")
			return ("-" if v < 0 else "") + "%d.%s" % [t / scale, digits]
	return ""


static func _terminates(d: int) -> bool:
	while d % 2 == 0:
		d /= 2
	while d % 5 == 0:
		d /= 5
	return d == 1


static func _factor_words(d: int) -> String:
	var parts: Array[String] = []
	var n := d
	for p in [2, 3, 5, 7, 11]:
		while n % p == 0:
			parts.append(str(p))
			n /= p
	if n > 1:
		parts.append(str(n))
	return " × ".join(parts)
