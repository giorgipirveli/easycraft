class_name G6NumberGen
extends RefCounted
## Owner #68 (spec §22.5): grade 6 maths generators for ratios, rates, percent and the number system (Common Core 6.RP,
## 6.NS; units 1-8 of the outline): SchoolGen "g6n.<name>", `static func <name>(rng: RandomNumberGenerator, level: int)
## -> Dictionary`, seeded, level 1-3, each with a hint, a worked answer and `data` (its inputs, for
## tests/unit/test_g6_maths_gen.gd). Decimals are worked in whole thousandths, never floats. Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]
const THINGS: Array = [["red blocks", "blue blocks"], ["cats", "dogs"], ["apples", "pears"], ["gold coins", "silver coins"],
	["oak trees", "pine trees"]]
## [the big unit, the small unit, how many small units make a big one]
const CONVERSIONS: Array = [["hours", "minutes", 60], ["minutes", "seconds", 60], ["days", "hours", 24], ["weeks", "days", 7],
	["years", "months", 12], ["m", "cm", 100], ["kg", "g", 1000], ["L", "mL", 1000]]


# --- Unit 1: ratios (6.RP.1, 6.RP.3a) -----------------------------------------------------------------------------------

## "There are 3 cats and 5 dogs. What is the ratio of dogs to cats?"
static func ratio_words(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pair: Array = THINGS[rng.randi_range(0, THINGS.size() - 1)]
	var a := rng.randi_range(2, 9)
	var b := rng.randi_range(2, 9)
	if a == b:
		b = a + 1
	var ask := "ab" if level == 1 else ("ba" if level == 2 else "a_all")
	var right := "%d : %d" % [a, b]
	var question := "the ratio of %s to %s" % [pair[0], pair[1]]
	if ask == "ba":
		right = "%d : %d" % [b, a]
		question = "the ratio of %s to %s" % [pair[1], pair[0]]
	elif ask == "a_all":
		right = "%d : %d" % [a, a + b]
		question = "the ratio of %s to all of them" % pair[0]
	var wrongs: Array = ["%d : %d" % [a, b], "%d : %d" % [b, a], "%d : %d" % [a + b, a], "%d : %d" % [b, a + b]]
	var ex := K.choice(rng, "There are %d %s and %d %s. What is %s?" % [a, pair[0], b, pair[1], question], right,
		wrongs.filter(func(w: String) -> bool: return w != right).slice(0, 3),
		"Write the numbers in the order the question names them.", "It is %s: %s." % [question, right])
	ex.data = {"a": a, "b": b, "ask": ask}
	return ex


## "2 : 3 = 8 : ?" — equal ratios, as in a ratio table.
static func ratio_table(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var r := rng.randi_range(1, 7)
	var s := rng.randi_range(2, 9)
	while NumberAnswer.gcd(r, s) != 1 or r == s:
		s += 1
	var k1 := 1 if level == 1 else rng.randi_range(2, 4)
	var k2 := rng.randi_range(2, 6 if level < 3 else 9)
	if k2 == k1:
		k2 += 1
	var missing := "s" if level == 1 or rng.randf() < 0.5 else "r"
	var shown := "%d : %d = %s : %s" % [k1 * r, k1 * s, str(k2 * r) if missing == "s" else "?", str(k2 * s) if missing == "r" else "?"]
	var answer := k2 * s if missing == "s" else k2 * r
	var ex := K.number(shown, str(answer), "What do you multiply by to get from one side to the other?",
		"%d : %d is the same as %d : %d, and %d : %d = %d : %d." % [k1 * r, k1 * s, r, s, r, s, k2 * r, k2 * s])
	ex.data = {"r": r, "s": s, "k1": k1, "k2": k2, "missing": missing}
	return ex


# --- Unit 2: rates and unit rates (6.RP.2, 6.RP.3b) ---------------------------------------------------------------------

## "A buddy lays 36 blocks in 4 minutes. How many blocks a minute?"; level 3: how long for so many.
static func unit_rate(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var name := NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var n := rng.randi_range(2, 9)
	var rate10 := rng.randi_range(2, 12) * 10
	if level == 2:
		rate10 = rng.randi_range(1, 9) * 10 + 5   # 1.5, 2.5 … 9.5
		n = rng.randi_range(1, 5) * 2
	var total10 := rate10 * n
	var ex: Dictionary
	if level < 3:
		ex = K.number("%s walks %s km in %d hours. How many km is that each hour?" % [name, _dec(total10 * 100), n], _dec(rate10 * 100),
			"Divide the distance by the hours.", "%s ÷ %d = %s km an hour." % [_dec(total10 * 100), n, _dec(rate10 * 100)])
		ex.data = {"rate10": rate10, "n": n, "ask": "rate"}
	else:
		var rate := rate10 / 10
		ex = K.number("A buddy lays %d blocks a minute. How many minutes does it take to lay %d blocks?" % [rate, rate * n], str(n),
			"How many groups of %d make %d?" % [rate, rate * n], "%d ÷ %d = %d minutes." % [rate * n, rate, n])
		ex.data = {"rate10": rate10, "n": n, "ask": "time"}
	return ex


## "Pack A: 4 gems for 20 coins. Pack B: 6 gems for 24 coins. Which is the better buy?"
static func better_buy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var count := 2 if level < 3 else 3
	var packs: Array = []
	var prices: Array[int] = []
	while packs.size() < count:
		var unit := rng.randi_range(2, 9)
		if prices.has(unit):
			continue
		prices.append(unit)
		var qty := rng.randi_range(2, 8 if level == 1 else 12)
		packs.append([qty, qty * unit])
	var words: Array[String] = []
	var best := 0
	for i in packs.size():
		words.append("Pack %s" % "ABC"[i])
		if prices[i] < prices[best]:
			best = i
	var list: Array[String] = []
	for i in packs.size():
		list.append("%s: %d gems for %d coins" % [words[i], packs[i][0], packs[i][1]])
	var said: Array[String] = []
	for i in packs.size():
		said.append("%s, %d coins a gem" % [words[i], prices[i]])
	var ex := K.choice(rng, "%s. Which is the better buy?" % ". ".join(list), words[best],
		words.filter(func(w: String) -> bool: return w != words[best]), "Find the price of one gem in each pack.",
		"%s. %s is the cheapest for each gem." % ["; ".join(said), words[best]])
	ex.data = {"packs": packs}
	return ex


# --- Unit 3: percent (6.RP.3c) ------------------------------------------------------------------------------------------

## "25% of 80 = ?"; level 3: "18 is 30% of what number?"
static func percent_of(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: int = [10, 25, 50][rng.randi_range(0, 2)] if level == 1 else rng.randi_range(1, 19) * 5
	var n := rng.randi_range(1, 20) * 20
	if level == 1:
		n = rng.randi_range(1, 10) * 20
	var part := p * n / 100
	var ex: Dictionary
	if level < 3:
		ex = K.number("%d%% of %d = ?" % [p, n], str(part), "%d%% means %d out of every 100." % [p, p],
			"%d ÷ 100 × %d = %d." % [n, p, part])
		ex.data = {"p": p, "n": n, "ask": "part"}
	else:
		ex = K.number("%d is %d%% of what number?" % [part, p], str(n), "If %d%% is %d, what is 1%%? Then 100%%?" % [p, part],
			"%d ÷ %d × 100 = %d." % [part, p, n])
		ex.data = {"p": p, "n": n, "ask": "whole"}
	return ex


## "A game costs 40 coins. It is 25% off. What is the sale price?"
static func percent_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: int = [10, 20, 25, 50][rng.randi_range(0, 3)] if level == 1 else rng.randi_range(1, 15) * 5
	var n := rng.randi_range(1, 10) * 20
	var off := p * n / 100
	var up := level == 3 and rng.randf() < 0.5
	var ex: Dictionary
	if up:
		ex = K.number("A town had %d buddies. The number grew by %d%%. How many buddies are there now?" % [n, p], str(n + off),
			"Find %d%% of %d, then add it." % [p, n], "%d%% of %d is %d; %d + %d = %d." % [p, n, off, n, off, n + off])
	else:
		ex = K.number("A kite costs %d coins. In the sale it is %d%% off. What is the sale price?" % [n, p], str(n - off),
			"Find %d%% of %d, then take it away." % [p, n], "%d%% of %d is %d; %d − %d = %d coins." % [p, n, off, n, off, n - off])
	ex.data = {"p": p, "n": n, "up": up}
	return ex


# --- Unit 4: converting with ratios (6.RP.3d) ---------------------------------------------------------------------------

## "3.5 hours = ? minutes", "150 minutes = ? hours"
static func convert_ratio(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c: Array = CONVERSIONS[rng.randi_range(0, CONVERSIONS.size() - 1)]
	var factor: int = c[2]
	var halves := factor % 2 == 0 and level > 1
	var k := rng.randi_range(2, 12)
	var small := k * factor
	if halves:
		small = (2 * k + 1) * factor / 2
	var to_small := level < 3
	var big := _dec(small * 1000 / factor)
	var ex: Dictionary
	if to_small:
		ex = K.number("%s %s = ? %s" % [big, c[0], c[1]], K.fmt(small), "1 %s = %s %s." % [_one(c[0]), K.fmt(factor), c[1]],
			"%s × %s = %s %s." % [big, K.fmt(factor), K.fmt(small), c[1]])
	else:
		ex = K.number("%s %s = ? %s" % [K.fmt(small), c[1], c[0]], big, "%s %s = 1 %s." % [K.fmt(factor), c[1], _one(c[0])],
			"%s ÷ %s = %s %s." % [K.fmt(small), K.fmt(factor), big, c[0]])
	ex.data = {"small": small, "factor": factor, "to_small": to_small}
	return ex


# --- Unit 5: dividing fractions (6.NS.1) --------------------------------------------------------------------------------

## "3/4 ÷ 1/8 = ?"; level 1: a whole number by a unit fraction; level 3: a story.
static func frac_divide(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var b := 1
	var c := 1
	var d := rng.randi_range(2, 8)
	if level > 1:
		b = [2, 3, 4, 5, 6, 8][rng.randi_range(0, 5)]
		a = rng.randi_range(1, 3 * b)
		d = [2, 3, 4, 6, 8, 10][rng.randi_range(0, 5)]
		c = rng.randi_range(1, d - 1)
	var q := _reduced(a * d, b * c)
	var answer := _frac_text(q)
	var left := str(a) if b == 1 else K.frac(a, b)
	var right := K.frac(c, d)
	var ex: Dictionary
	if level < 3:
		ex = K.number("%s ÷ %s = ?" % [left, right], answer, "Dividing by %s is the same as multiplying by %s." % [right, K.frac(d, c) if c > 1 else str(d)],
			"%s × %s = %s." % [left, K.frac(d, c) if c > 1 else str(d), answer])
	else:
		ex = K.number("A jug holds %s L of juice. Each cup takes %s L. How many cups can be filled?" % [left, right], answer,
			"How many %s are in %s?" % [right, left], "%s ÷ %s = %s cups." % [left, right, answer])
	var dec := _decimal(q)
	if dec != "":
		ex.accept = [dec]
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


# --- Unit 6: multi-digit and decimal operations (6.NS.2, 6.NS.3) -------------------------------------------------------

## "7,452 ÷ 23 = ?" (always exact)
static func long_divide(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d := rng.randi_range(3, 9) if level == 1 else rng.randi_range(12, 29 if level == 2 else 48)
	var q := rng.randi_range(21, 99) if level == 1 else rng.randi_range(101, 399 if level == 2 else 999)
	var ex := K.number("%s ÷ %d = ?" % [K.fmt(q * d), d], str(q), "Divide step by step, starting with the biggest place.",
		"%s ÷ %d = %s (check: %s × %d = %s)." % [K.fmt(q * d), d, K.fmt(q), K.fmt(q), d, K.fmt(q * d)])
	ex.data = {"q": q, "d": d}
	return ex


## "4.25 + 1.8 = ?", "1.2 × 3.5 = ?", "8.4 ÷ 0.4 = ?"
static func decimal_ops(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var op: String = ["+", "−"][rng.randi_range(0, 1)] if level == 1 else ("×" if level == 2 else "÷")
	var a := 0   # thousandths
	var b := 0
	var answer := 0
	match op:
		"+", "−":
			a = rng.randi_range(101, 9999) * 10
			b = rng.randi_range(11, 999) * 10
			if op == "−" and b > a:
				var t := a
				a = b
				b = t
			answer = a + b if op == "+" else a - b
		"×":
			a = rng.randi_range(11, 99) * 100   # tenths
			b = rng.randi_range(2, 9) * 1000 if rng.randf() < 0.5 else rng.randi_range(11, 49) * 100
			answer = a * b / 1000
		_:
			b = rng.randi_range(2, 9) * 100   # 0.2 … 0.9
			var q := rng.randi_range(3, 40)
			a = q * b
			answer = q * 1000
	var ex := K.number("%s %s %s = ?" % [_dec(a), op, _dec(b), ], _dec(answer),
		{"+": "Line up the decimal points.", "−": "Line up the decimal points.", "×": "Multiply as whole numbers, then count the decimal places.",
			"÷": "Multiply both numbers by 10 so you divide by a whole number."}[op],
		"%s %s %s = %s." % [_dec(a), op, _dec(b), _dec(answer)])
	ex.data = {"a": a, "b": b, "op": op}
	return ex


# --- Unit 7: common factors and multiples (6.NS.4) ----------------------------------------------------------------------

## The greatest common factor of two numbers.
static func gcf(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := rng.randi_range(2, 6 if level == 1 else 12)
	var m := rng.randi_range(1, 5 if level == 1 else 8)
	var n := rng.randi_range(m + 1, m + 6)
	while NumberAnswer.gcd(m, n) != 1:
		n += 1
	var ex := K.number("What is the greatest common factor of %d and %d?" % [g * m, g * n], str(g),
		"List the factors of each number and find the biggest one they share.",
		"%d = %d × %d and %d = %d × %d: the greatest common factor is %d." % [g * m, g, m, g * n, g, n, g])
	ex.data = {"a": g * m, "b": g * n}
	return ex


## The least common multiple; level 3: two buses.
static func lcm(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9 if level == 1 else 12)
	var b := rng.randi_range(2, 9 if level == 1 else 15)
	if a == b:
		b += 1
	var l := a * b / NumberAnswer.gcd(a, b)
	var ex: Dictionary
	if level < 3:
		ex = K.number("What is the least common multiple of %d and %d?" % [a, b], str(l), "Count up in %ds until you reach a multiple of %d." % [a, b],
			"%d is the first number in both times tables." % l)
	else:
		ex = K.number("A red bus leaves every %d minutes and a blue bus every %d. Both leave now. In how many minutes do they next leave together?" % [a, b],
			str(l), "Find the least common multiple.", "The least common multiple of %d and %d is %d minutes." % [a, b, l])
	ex.data = {"a": a, "b": b}
	return ex


## "36 + 48 = 12 × (3 + ?)"
static func factor_sum(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := rng.randi_range(2, 5 if level == 1 else 12)
	var m := rng.randi_range(1, 6)
	var n := rng.randi_range(m + 1, m + 7)
	while NumberAnswer.gcd(m, n) != 1:
		n += 1
	var ask_g := level == 3
	var shown := "%d + %d = %s × (%d + %s)" % [g * m, g * n, "?" if ask_g else str(g), m, str(n) if ask_g else "?"]
	var ex := K.number(shown, str(g) if ask_g else str(n), "The greatest common factor goes outside the brackets.",
		"%d + %d = %d × (%d + %d): %d × %d = %d and %d × %d = %d." % [g * m, g * n, g, m, n, g, m, g * m, g, n, g * n])
	ex.data = {"g": g, "m": m, "n": n, "ask_g": ask_g}
	return ex


# --- Unit 8: negative numbers (6.NS.5, 6.NS.6, 6.NS.7) -----------------------------------------------------------------

## "Which is colder?" / "Which is greatest?"; level 3 puts four in order.
static func compare_integers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var count := 2 if level == 1 else (3 if level == 2 else 4)
	var values: Array[int] = []
	while values.size() < count:
		var v := rng.randi_range(-15, 12)
		if not values.has(v):
			values.append(v)
	var ex: Dictionary
	if level == 1:
		var words: Array = values.map(func(v: int) -> String: return "%s°C" % _signed(v))
		var colder := 0 if values[0] < values[1] else 1
		ex = K.choice(rng, "Which temperature is colder: %s or %s?" % [words[0], words[1]], words[colder], [words[1 - colder]],
			"On a thermometer, colder is lower.", "%s is lower on the thermometer." % words[colder])
		ex.data = {"values": values, "ask": "min"}
	elif level == 2:
		var best := 0
		for i in values.size():
			if values[i] > values[best]:
				best = i
		var wrongs: Array = []
		for i in values.size():
			if i != best:
				wrongs.append(_signed(values[i]))
		ex = K.choice(rng, "Which number is the greatest: %s?" % ", ".join(values.map(func(v: int) -> String: return _signed(v))),
			_signed(values[best]), wrongs, "On a number line, the greatest is farthest to the right.",
			"%s is farthest to the right." % _signed(values[best]))
		ex.data = {"values": values, "ask": "max"}
	else:
		var sorted := values.duplicate()
		sorted.sort()
		ex = K.order(rng, "Put these in order, least first.", sorted.map(func(v: int) -> String: return _signed(v)),
			"Negative numbers farther from 0 are smaller.", "From least to greatest: %s." % ", ".join(sorted.map(func(v: int) -> String: return _signed(v))))
		ex.data = {"values": values, "ask": "order"}
	return ex


## "|−7| = ?"; level 3: how far apart two heights are.
static func absolute_value(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := -rng.randi_range(1, 30)
	var b := rng.randi_range(1, 30)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("|%s| = ?" % _signed(a), str(-a), "Absolute value is the distance from 0.", "%s is %d away from 0." % [_signed(a), -a])
			ex.data = {"a": a, "b": 0, "ask": "abs"}
		2:
			var farther := _signed(a) if -a > b else str(b)
			if -a == b:
				b += 1
				farther = str(b)
			ex = K.choice(rng, "Which is farther from 0: %s or %d?" % [_signed(a), b], farther, [str(b) if farther != str(b) else _signed(a)],
				"Compare their distances from 0.", "|%s| = %d and |%d| = %d." % [_signed(a), -a, b, b])
			ex.data = {"a": a, "b": b, "ask": "farther"}
		_:
			ex = K.number("A diver is at %s m and a gull flies at %d m. How far apart are they, in metres?" % [_signed(a), b], str(b - a),
				"Add the distances from sea level (0).", "%d + %d = %d m." % [-a, b, b - a])
			ex.data = {"a": a, "b": b, "ask": "apart"}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------------

## Thousandths as a decimal: 4250 -> "4.25".
static func _dec(thousandths: int) -> String:
	var neg := thousandths < 0
	var t := absi(thousandths)
	var whole := t / 1000
	var part := t % 1000
	var out := K.fmt(whole)
	if part != 0:
		out += "." + str(part).pad_zeros(3).rstrip("0")
	return ("-" if neg else "") + out


static func _reduced(num: int, den: int) -> Array:
	var g := NumberAnswer.gcd(absi(num), absi(den))
	return [num / g, den / g]


static func _frac_text(f: Array) -> String:
	return str(f[0]) if int(f[1]) == 1 else K.frac(int(f[0]), int(f[1]))


## The fraction as an exact decimal ("2.5"), or "" (none, or whole).
static func _decimal(f: Array) -> String:
	if int(f[1]) == 1:
		return ""
	for places in [1, 2, 3]:
		var scale := K.pow10(places)
		if (int(f[0]) * scale) % int(f[1]) == 0:
			return _dec(int(f[0]) * scale / int(f[1]) * 1000 / scale)
	return ""


## A number with a proper minus sign: -7 -> "−7".
static func _signed(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


## "hours" -> "hour" (for "1 hour = 60 minutes"); units like "m" stay.
static func _one(unit: String) -> String:
	return unit.trim_suffix("s") if unit.length() > 2 else unit
