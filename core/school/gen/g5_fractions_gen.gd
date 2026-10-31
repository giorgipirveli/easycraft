class_name G5FractionsGen
extends RefCounted
## Owner #68 (spec §22.5): grade 5 maths generators for fractions (Common Core 5.NF; units 8-12 of the outline):
## SchoolGen "g5f.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level
## 1-3, each with a hint, a worked answer and `data` (its inputs, for tests/unit/test_g5_maths_gen.gd). Fractions are
## [top, bottom] of whole ints; a number answer may be any equal fraction (NumberAnswer compares values), and answers
## that are mixed numbers ("2 3/4") are choices, since the pad has no space. Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const DENS: Array[int] = [2, 3, 4, 5, 6, 8, 10, 12]
const WORDS := {2: "halves", 3: "thirds", 4: "quarters", 5: "fifths", 6: "sixths", 7: "sevenths", 8: "eighths",
	9: "ninths", 10: "tenths", 12: "twelfths", 15: "fifteenths", 16: "sixteenths", 18: "eighteenths", 20: "twentieths",
	24: "twenty-fourths", 30: "thirtieths", 36: "thirty-sixths", 40: "fortieths", 60: "sixtieths"}
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]


# --- Unit 8: fractions with different denominators (5.NF.1, 5.NF.2) ------------------------------------------------

## "1/2 + 1/3 = ?"
static func add_unlike(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f := _pair(rng, level)
	var a: int = f[0]
	var b: int = f[1]
	var c: int = f[2]
	var d: int = f[3]
	var l := _lcm(b, d)
	var top := a * int(l / float(b)) + c * int(l / float(d))
	var pic := {}
	if level == 1 and l <= 16:
		pic = {"kind": "bar", "bars": [{"den": b, "num": a}, {"den": d, "num": c}, {"den": l, "num": mini(top, l)}]}
	var ex := K.number("%d/%d + %d/%d = ?" % [a, b, c, d], "%d/%d" % [top, l], _common_hint(a, b, c, d),
		"%s. %d/%d + %d/%d = %d/%d%s." % [_both(a, b, c, d), a * int(l / float(b)), l, c * int(l / float(d)), l, top, l,
			_as_mixed(top, l)], pic)
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "3/4 − 1/6 = ?"
static func subtract_unlike(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	var c := 0
	var d := 0
	for _t in 80:
		var f := _pair(rng, level)
		a = f[0]
		b = f[1]
		c = f[2]
		d = f[3]
		if a * d > c * b:
			break
		if c * b > a * d:
			var t := [a, b]
			a = c
			b = d
			c = t[0]
			d = t[1]
			break
	var l := _lcm(b, d)
	var top := a * int(l / float(b)) - c * int(l / float(d))
	var ex := K.number("%d/%d − %d/%d = ?" % [a, b, c, d], "%d/%d" % [top, l], _common_hint(a, b, c, d),
		"%s. %d/%d − %d/%d = %d/%d." % [_both(a, b, c, d), a * int(l / float(b)), l, c * int(l / float(d)), l, top, l])
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "To add 1/4 and 1/6, what is the smallest denominator both can be changed to?"
static func common_denominator(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f := _pair(rng, level)
	var b: int = f[1]
	var d: int = f[3]
	var l := _lcm(b, d)
	var ex := K.number("To add %d/%d and %d/%d, what is the smallest denominator both can be changed to?" % [f[0], b, f[2], d],
		l, "Count up in %ds until you find a number that %d goes into too." % [maxi(b, d), mini(b, d)],
		"%d is the smallest number that both %d and %d go into: %d = %d × %d = %d × %d." % [l, b, d, l, b, int(l / float(b)),
			d, int(l / float(d))])
	ex.data = {"b": b, "d": d}
	return ex


## "2 1/2 + 1 1/3 = ?" as choices of mixed numbers.
static func add_mixed_unlike(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	var c := 0
	var d := 0
	for _t in 80:
		var f := _pair(rng, level)
		a = f[0]
		b = f[1]
		c = f[2]
		d = f[3]
		var over := a * d + c * b >= b * d
		if (level == 3) == over:
			break
	var w1 := rng.randi_range(1, 4)
	var w2 := rng.randi_range(1, 3)
	var l := _lcm(b, d)
	var total := (w1 + w2) * l + a * int(l / float(b)) + c * int(l / float(d))
	var right := _mixed(total, l)
	var wrongs: Array = []
	for w: String in [_mixed_text(w1 + w2, a + c, b + d), _mixed(total + l, l), _mixed(total - l, l),
			_mixed_text(w1 + w2, a * int(l / float(b)) + c * int(l / float(d)), l * 2)]:
		if _value(w) != _value(right) and not wrongs.has(w):
			wrongs.append(w)
	var ex := K.choice(rng, "%d %d/%d + %d %d/%d = ?" % [w1, a, b, w2, c, d], right, wrongs.slice(0, 3),
		"Add the wholes. Then change the fractions to %s and add them." % _parts_word(l),
		"%d + %d = %d. %s: %d/%d + %d/%d = %d/%d. Together: %s." % [w1, w2, w1 + w2, _both(a, b, c, d),
			a * int(l / float(b)), l, c * int(l / float(d)), l, a * int(l / float(b)) + c * int(l / float(d)), l, right])
	ex.data = {"w1": w1, "a": a, "b": b, "w2": w2, "c": c, "d": d}
	return ex


## "Is 2/5 + 1/2 more than, less than or equal to 1?" (level 1-2 against 1/2 or 1).
static func benchmark_sum(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f := _pair(rng, level)
	var a: int = f[0]
	var b: int = f[1]
	var c: int = f[2]
	var d: int = f[3]
	var target := [1, 1] if level > 1 or rng.randf() < 0.5 else [1, 2]
	var t := "1" if target == [1, 1] else "1/2"
	var sum_top := a * d + c * b
	var sum_bot := b * d
	var cmp := sum_top * int(target[1]) - int(target[0]) * sum_bot
	var answer := ("exactly %s" % t) if cmp == 0 else (("more than %s" % t) if cmp > 0 else ("less than %s" % t))
	var ex := K.choice(rng, "Without adding exactly: is %d/%d + %d/%d more than, less than or exactly %s?" % [a, b, c, d, t],
		answer, ["more than %s" % t, "less than %s" % t, "exactly %s" % t].filter(func(x: String) -> bool: return x != answer),
		"Compare each part with 1/2: is %d/%d more or less than 1/2? And %d/%d?" % [a, b, c, d],
		"%d/%d + %d/%d = %d/%d, which is %s." % [a, b, c, d, sum_top, sum_bot, answer])
	ex.data = {"a": a, "b": b, "c": c, "d": d, "target": target}
	return ex


## "Bram says 2/5 + 1/2 = 3/7." true or false (adding the tops and the bottoms is a common mix-up).
static func sum_mistake(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f := _pair(rng, level)
	var a: int = f[0]
	var b: int = f[1]
	var c: int = f[2]
	var d: int = f[3]
	var l := _lcm(b, d)
	var top := a * int(l / float(b)) + c * int(l / float(d))
	var right := rng.randf() < 0.5
	var shown := "%d/%d" % [top, l] if right else "%d/%d" % [a + c, b + d]
	var ex := K.truefalse("Bram says %d/%d + %d/%d = %s." % [a, b, c, d, shown], right,
		"Is %s bigger than both %d/%d and %d/%d? A sum should be." % [shown, a, b, c, d],
		"%s, so %d/%d + %d/%d = %d/%d.%s" % [_both(a, b, c, d), a, b, c, d, top, l,
			"" if right else " Adding the tops and the bottoms does not work: %s is less than %s." % [shown,
				"%d/%d" % [a, b] if a * d > c * b else "%d/%d" % [c, d]]])
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


static func unlike_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var f := _pair(rng, level)
	var a: int = f[0]
	var b: int = f[1]
	var c: int = f[2]
	var d: int = f[3]
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var op := "+" if rng.randf() < 0.5 or a * d == c * b else "-"
	if op == "-" and a * d < c * b:
		var t := [a, b]
		a = c
		b = d
		c = t[0]
		d = t[1]
	var l := _lcm(b, d)
	var top := a * int(l / float(b)) + (1 if op == "+" else -1) * c * int(l / float(d))
	var ex: Dictionary
	if op == "+":
		ex = K.number("%s walks %d/%d km to the farm, then %d/%d km to the river. How far does %s walk, in km?" % [who, a, b,
			c, d, who], "%d/%d" % [top, l], _common_hint(a, b, c, d), "%s. %d/%d + %d/%d = %d/%d km." % [_both(a, b, c, d),
			a * int(l / float(b)), l, c * int(l / float(d)), l, top, l])
	else:
		ex = K.number("A jug holds %d/%d L of juice. %s pours out %d/%d L. How much juice is left, in litres?" % [a, b, who,
			c, d], "%d/%d" % [top, l], _common_hint(a, b, c, d), "%s. %d/%d − %d/%d = %d/%d L." % [_both(a, b, c, d),
			a * int(l / float(b)), l, c * int(l / float(d)), l, top, l])
	ex.data = {"a": a, "b": b, "c": c, "d": d, "op": op}
	return ex


# --- Unit 9: fractions as division (5.NF.3) ---------------------------------------------------------------------------

## "5 ÷ 8 = ?" (5/8)
static func division_to_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := DENS[rng.randi_range(1, DENS.size() - 1)]
	var a := rng.randi_range(1, b - 1) if level == 1 else rng.randi_range(b + 1, 3 * b)
	if a % b == 0:
		a += 1
	var ex := K.number("%d ÷ %d = ?" % [a, b], "%d/%d" % [a, b], "A division can be written as a fraction: the first number goes on top.",
		"%d ÷ %d = %d/%d%s" % [a, b, a, b, _as_mixed(a, b)])
	ex.data = {"a": a, "b": b}
	return ex


## "Which division is the same as 7/3?"
static func fraction_to_division(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := DENS[rng.randi_range(1, DENS.size() - 1)]
	var a := rng.randi_range(1, b - 1) if level == 1 else rng.randi_range(b + 1, 3 * b)
	if a == b:
		a += 1
	var ex := K.choice(rng, "Which division is the same as %d/%d?" % [a, b], "%d ÷ %d" % [a, b], ["%d ÷ %d" % [b, a],
		"%d × %d" % [a, b], "%d − %d" % [a, b]], "The fraction bar means \"divided by\".",
		"%d/%d means %d shared into %d equal parts: %d ÷ %d." % [a, b, a, b, a, b])
	ex.data = {"a": a, "b": b}
	return ex


## "4 buddies share 3 pies equally. How much pie does each buddy get?"
static func share_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p := rng.randi_range(2, 8)
	var n := rng.randi_range(1, p - 1) if level == 1 else rng.randi_range(p + 1, p * 3)
	if n % p == 0:
		n += 1
	var names := NAMES.duplicate()
	K.shuffle(rng, names)
	var ex: Dictionary
	if level == 1 or rng.randf() < 0.5:
		ex = K.number("%d buddies share %d pies equally. How much pie does each buddy get?" % [p, n], "%d/%d" % [n, p],
			"Share %d by %d: %d ÷ %d." % [n, p, n, p], "%d ÷ %d = %d/%d of a pie each%s." % [n, p, n, p, _as_mixed(n, p)])
	else:
		ex = K.number("%s shares %d kg of clay equally among %d children. How many kg does each child get?" % [names[0], n, p],
			"%d/%d" % [n, p], "Divide the clay by the number of children.", "%d ÷ %d = %d/%d kg each%s." % [n, p, n, p,
				_as_mixed(n, p)])
	ex.data = {"n": n, "p": p}
	return ex


## "7 ÷ 3 is between which two whole numbers?"
static func between_wholes(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 9)
	var a := rng.randi_range(b + 1, b * (4 if level < 3 else 9))
	if a % b == 0:
		a += 1
	var q := int(a / float(b))
	var ex := K.choice(rng, "%d ÷ %d is between which two whole numbers?" % [a, b], "%d and %d" % [q, q + 1],
		["%d and %d" % [q + 1, q + 2], "%d and %d" % [maxi(q - 1, 0), maxi(q, 1)] if q > 1 else "%d and %d" % [q + 2, q + 3],
			"%d and %d" % [b, b + 1] if b != q else "%d and %d" % [a, a + 1]],
		"How many whole %ds fit into %d?" % [b, a], "%d × %d = %d and %d × %d = %d, so %d ÷ %d = %s: between %d and %d." % [b,
			q, b * q, b, q + 1, b * (q + 1), a, b, _mixed(a, b), q, q + 1])
	ex.data = {"a": a, "b": b}
	return ex


## "Share 11 m of rope equally among 4 friends. How much does each get?" (mixed numbers)
static func share_mixed(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p := rng.randi_range(2, 6 if level < 3 else 9)
	var n := rng.randi_range(p + 1, p * 4)
	if n % p == 0:
		n += 1
	var right := _mixed(n, p) + " m"
	var wrongs: Array = []
	for w: String in ["%d/%d m" % [p, n], _mixed(n + p, p) + " m", _mixed_text(int(n / float(p)), p - n % p, p) + " m",
			_mixed(n - p, p) + " m"]:
		if _value(w.trim_suffix(" m")) != _value(right.trim_suffix(" m")) and not wrongs.has(w):
			wrongs.append(w)
	var ex := K.choice(rng, "Share %d m of rope equally among %d friends. How much rope does each friend get?" % [n, p], right,
		wrongs.slice(0, 3), "%d ÷ %d = %d/%d. How many wholes is that, and what is left?" % [n, p, n, p],
		"%d ÷ %d = %d/%d = %s each." % [n, p, n, p, right])
	ex.data = {"n": n, "p": p}
	return ex


## Cakes shared among buddies, drawn as bars: each buddy gets the shaded part of every cake.
static func sharing_picture(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(2, 4)
	var p := rng.randi_range(n + 1, 8) if level < 3 else rng.randi_range(n + 1, 12)
	var bars: Array = []
	for i in n:
		bars.append({"den": p, "num": 1})
	var ex := K.number("%d cakes are shared equally among %d buddies. Each cake is cut into %d, and each buddy gets the shaded part of every cake. How much cake is that?" % [
		n, p, p], "%d/%d" % [n, p], "One piece of each cake is 1/%d. How many pieces does a buddy get?" % p,
		"%d pieces of 1/%d make %d/%d: %d ÷ %d = %d/%d." % [n, p, n, p, n, p, n, p], {"kind": "bar", "bars": bars})
	ex.data = {"n": n, "p": p}
	return ex


# --- Unit 10: multiply fractions (5.NF.4, 5.NF.6) ------------------------------------------------------------------------

## "2/3 × 12 = ?"
static func fraction_of_number(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := DENS[rng.randi_range(0, 5)]
	var a := rng.randi_range(1, b - 1)
	var n := b * rng.randi_range(2, 6) if level < 3 else rng.randi_range(2, 9)
	if level == 3 and n % b == 0:
		n += 1
	var pic := {"kind": "groups", "groups": b, "each": int(n / float(b))} if level == 1 and n / float(b) <= 12 and b <= 10 else {}
	var ex := K.number("%d/%d × %d = ?" % [a, b, n], "%d/%d" % [a * n, b] if (a * n) % b != 0 else str(int(a * n / float(b))),
		"%d/%d of %d: split %d into %d equal parts, then take %d of them." % [a, b, n, n, b, a],
		"%d ÷ %d = %s, and %d × %s = %s." % [n, b, _frac_text(n, b), a, _frac_text(n, b), _frac_text(a * n, b)], pic)
	ex.data = {"a": a, "b": b, "n": n}
	return ex


## "2/3 × 3/4 = ?"
static func fraction_times_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := DENS[rng.randi_range(0, 5)]
	var d := DENS[rng.randi_range(0, 5)]
	var a := 1 if level == 1 else rng.randi_range(1, b - 1)
	var c := 1 if level == 1 else rng.randi_range(1, d - 1)
	if level == 3:
		a = rng.randi_range(b + 1, 2 * b)   # a fraction more than 1
	var ex := K.number("%d/%d × %d/%d = ?" % [a, b, c, d], "%d/%d" % [a * c, b * d],
		"Multiply the tops, then multiply the bottoms.", "(%d × %d)/(%d × %d) = %d/%d" % [a, c, b, d, a * c, b * d])
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## The square cut both ways: "The square shows 2/3 × 3/4. What is the product?"
static func area_model_product(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 6)
	var d := rng.randi_range(2, 6)
	var a := rng.randi_range(1, b - 1)
	var c := rng.randi_range(1, d - 1)
	var prompt := "The square shows %d/%d × %d/%d. What is the product?" % [a, b, c, d]
	if level > 1:
		prompt = "What fraction of the whole square is shaded both ways?"
	var ex := K.number(prompt, "%d/%d" % [a * c, b * d], "Count the parts shaded both ways, and all the parts of the square.",
		"%d × %d = %d parts are shaded both ways, out of %d × %d = %d: %d/%d × %d/%d = %d/%d." % [a, c, a * c, b, d, b * d, a,
			b, c, d, a * c, b * d], {"kind": "fraction_area", "cols": d, "rows": b, "shade_cols": c, "shade_rows": a,
			"w": "%d/%d" % [c, d], "h": "%d/%d" % [a, b]})
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "A garden is 3/4 m long and 2/5 m wide. What is its area, in square metres?"
static func fraction_rectangle(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 6)
	var d := rng.randi_range(2, 6)
	var a := rng.randi_range(1, b - 1)
	var c := rng.randi_range(1, d - 1)
	var pic := {"kind": "fraction_area", "cols": d, "rows": b, "shade_cols": c, "shade_rows": a, "w": "%d/%d m" % [c, d],
		"h": "%d/%d m" % [a, b]}
	var long := "%d/%d m" % [c, d]
	if level == 3:
		c = d + rng.randi_range(1, d - 1)   # one side longer than 1 m
		long = "%s m" % _mixed(c, d)
		pic = {}
	var ex := K.number("A garden is %s long and %d/%d m wide. What is its area, in square metres?" % [long, a, b],
		"%d/%d" % [a * c, b * d], "Area = length × width. Multiply the tops and the bottoms.",
		"%d/%d × %d/%d = %d/%d square metres." % [c, d, a, b, a * c, b * d], pic)
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "Zara has 3/4 of a pizza. She eats 1/2 of it. How much of a whole pizza does she eat?"
static func fraction_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := DENS[rng.randi_range(0, 4)]
	var d := DENS[rng.randi_range(0, 4)]
	var a := rng.randi_range(1, b - 1)
	var c := 1 if level == 1 else rng.randi_range(1, d - 1)
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var ex: Dictionary
	if rng.randf() < 0.5:
		ex = K.number("%s has %d/%d of a pizza and eats %d/%d of it. How much of a whole pizza does %s eat?" % [who, c, d, a, b,
			who], "%d/%d" % [a * c, b * d], "%d/%d of %d/%d means %d/%d × %d/%d." % [a, b, c, d, a, b, c, d],
			"%d/%d × %d/%d = %d/%d of the pizza." % [a, b, c, d, a * c, b * d])
	else:
		ex = K.number("%d/%d of a field is planted with carrots. %d/%d of the carrots are orange. What fraction of the field has orange carrots?" % [
			c, d, a, b], "%d/%d" % [a * c, b * d], "Find %d/%d of %d/%d: multiply." % [a, b, c, d],
			"%d/%d × %d/%d = %d/%d of the field." % [a, b, c, d, a * c, b * d])
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## The block board as one whole: "Fill 2/3 × 3/4 of the board."
static func build_product(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 4)
	var d := rng.randi_range(2, 5 if level < 3 else 6)
	var a := rng.randi_range(1, b - 1)
	var c := rng.randi_range(1, d - 1)
	var board := {"cols": d, "rows": b, "block": BlockIds.PLANKS, "given": [], "view": "farm"}
	var ex := K.build("This farm is one whole. Plant %d/%d × %d/%d of it: %d/%d of %d/%d of the farm." % [a, b, c, d, a, b, c, d],
		board, {"kind": "fraction", "num": a * c, "den": b * d},
		"Take %d of the %d columns, then %d of the %d rows of those." % [c, d, a, b],
		"%d/%d × %d/%d = %d/%d, so plant %d of the %d squares." % [a, b, c, d, a * c, b * d, a * c, b * d])
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


# --- Unit 11: multiplying as scaling (5.NF.5) --------------------------------------------------------------------------

## "Without working it out: is 7 × 5/6 more than, less than or equal to 7?"
static func scale_compare(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(3, 20) if level < 3 else rng.randi_range(21, 999)
	var b := DENS[rng.randi_range(0, DENS.size() - 1)]
	var roll := rng.randf()
	var a := rng.randi_range(1, b - 1) if roll < 0.45 else (b if roll < 0.6 else rng.randi_range(b + 1, 2 * b))
	var answer := "equal to %d" % n if a == b else ("more than %d" % n if a > b else "less than %d" % n)
	var ex := K.choice(rng, "Without working it out: is %d × %d/%d more than, less than or equal to %d?" % [n, a, b, n], answer,
		["more than %d" % n, "less than %d" % n, "equal to %d" % n].filter(func(x: String) -> bool: return x != answer),
		"Is %d/%d more than 1, less than 1, or equal to 1?" % [a, b],
		"%d/%d is %s 1, so %d × %d/%d is %s." % [a, b, "equal to" if a == b else ("more than" if a > b else "less than"), n, a,
			b, answer])
	ex.data = {"n": n, "a": a, "b": b}
	return ex


## "Put these in order, smallest first: 8 × 3/4, 8 × 5/4, 8 × 1"
static func scale_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(3, 30)
	var b := DENS[rng.randi_range(1, DENS.size() - 1)]
	var tops: Array = [rng.randi_range(1, b - 1), b, rng.randi_range(b + 1, 2 * b)]
	if level > 1:
		var more := rng.randi_range(1, 2 * b)
		for _t in 20:
			if not tops.has(more):
				break
			more = rng.randi_range(1, 2 * b)
		if not tops.has(more):
			tops.append(more)
	tops.sort()
	var in_order: Array = []
	for t: int in tops:
		in_order.append("%d × %s" % [n, "1" if t == b and level == 1 else "%d/%d" % [t, b]])
	var ex := K.order(rng, "Without working them out, put these in order, smallest first.", in_order,
		"Compare each fraction with 1: less than 1 makes %d smaller, more than 1 makes it bigger." % n,
		"The bigger the fraction, the bigger the product: %s." % ", ".join(in_order))
	ex.data = {"n": n}
	return ex


## "9 × 7/5 is less than 9." true or false.
static func scale_truefalse(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(3, 50) if level < 3 else rng.randi_range(51, 999)
	var b := DENS[rng.randi_range(0, DENS.size() - 1)]
	var a := rng.randi_range(1, b - 1) if rng.randf() < 0.5 else rng.randi_range(b + 1, 2 * b)
	var more := rng.randf() < 0.5
	var claim := "%d × %d/%d is %s than %d." % [n, a, b, "more" if more else "less", n]
	var truth := (a > b) if more else (a < b)
	var ex := K.truefalse(claim, truth, "Is %d/%d more or less than 1?" % [a, b],
		"%d/%d is %s than 1, so %d × %d/%d is %s than %d: %s." % [a, b, "more" if a > b else "less", n, a, b,
			"more" if a > b else "less", n, "true" if truth else "false"])
	ex.data = {"n": n, "a": a, "b": b}
	return ex


## "A buddy's tower is 3/4 as tall as Bram's. Which tower is taller?"; level 3: "How long is Zara's rope?"
static func scale_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := DENS[rng.randi_range(0, 5)]
	var names := NAMES.duplicate()
	K.shuffle(rng, names)
	var ex: Dictionary
	var a := 0
	if level < 3:
		var roll := rng.randf()
		a = rng.randi_range(1, b - 1) if roll < 0.45 else (b if roll < 0.55 else rng.randi_range(b + 1, 2 * b))
		var ref := "%s's tower" % names[0]
		var other := "the buddy's tower"
		var answer := "They are the same height" if a == b else (ref if a < b else other)
		ex = K.choice(rng, "A buddy's tower is %d/%d as tall as %s. Which tower is taller?" % [a, b, ref], answer,
			[ref, other, "They are the same height"].filter(func(x: String) -> bool: return x != answer),
			"Is %d/%d more than 1, less than 1, or equal to 1?" % [a, b],
			"%d/%d is %s 1, so the buddy's tower is %s." % [a, b, "equal to" if a == b else ("less than" if a < b else
				"more than"), "just as tall" if a == b else ("shorter" if a < b else "taller")])
		ex.data = {"a": a, "b": b, "ref": ref, "other": other}
	else:
		a = rng.randi_range(1, 2 * b)
		if a == b:
			a += 1
		var n := b * rng.randi_range(2, 6)
		ex = K.number("%s's rope is %d m long. %s's rope is %d/%d as long. How long is %s's rope, in metres?" % [names[0], n,
			names[1], a, b, names[1]], int(n * a / float(b)), "%d/%d of %d: split %d into %d equal parts and take %d." % [a,
			b, n, n, b, a], "%d × %d/%d = %d m, %s than %d m because %d/%d is %s than 1." % [n, a, b, int(n * a / float(b)),
			"longer" if a > b else "shorter", n, a, b, "more" if a > b else "less"])
		ex.data = {"a": a, "b": b, "n": n}
	return ex


## "Which number makes 20 × ? smaller than 20?"
static func scale_factor(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(5, 50)
	var smaller := rng.randf() < 0.5
	var b := DENS[rng.randi_range(1, DENS.size() - 1)]
	var below := "%d/%d" % [rng.randi_range(1, b - 1), b]
	var above := "%d/%d" % [b + rng.randi_range(1, b), b] if level > 1 else str(rng.randi_range(2, 5))
	var one := "%d/%d" % [b, b] if level > 1 else "1"
	var right := below if smaller else above
	var wrongs: Array = [above if smaller else below, one]
	if level == 3:
		wrongs.append(str(rng.randi_range(2, 5)) if smaller else "%d/%d" % [rng.randi_range(1, b - 1), b + 1])
	var ex := K.choice(rng, "Which number makes %d × ? %s than %d?" % [n, "smaller" if smaller else "bigger", n], right, wrongs,
		"Multiplying by a number %s than 1 makes a number %s." % ["less" if smaller else "more", "smaller" if smaller else
			"bigger"], "%s is %s than 1, so %d × %s is %s than %d." % [right, "less" if smaller else "more", n, right,
			"smaller" if smaller else "bigger", n])
	ex.data = {"n": n, "smaller": smaller}
	return ex


# --- Unit 12: dividing with unit fractions (5.NF.7) ----------------------------------------------------------------------

## "1/3 ÷ 2 = ?"
static func unit_divided(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 5 if level == 1 else 8)
	var n := rng.randi_range(2, 4 if level == 1 else 6)
	var pic := {"kind": "bar", "bars": [{"den": b, "num": 1}, {"den": b * n, "num": 1}]} if b * n <= 16 and level < 3 else {}
	var ex := K.number("1/%d ÷ %d = ?" % [b, n], "1/%d" % (b * n), "Share one %s into %d equal parts. How many of those parts make a whole?" % [
		_one(b), n], "Each %s splits into %d, so a whole has %d × %d = %d parts: 1/%d ÷ %d = 1/%d. Check: 1/%d × %d = 1/%d." % [
		_one(b), n, b, n, b * n, b, n, b * n, b * n, n, b], pic)
	ex.data = {"b": b, "n": n}
	return ex


## "4 ÷ 1/3 = ?"
static func whole_divided(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 5 if level == 1 else 10)
	var n := rng.randi_range(2, 4 if level < 3 else 12)
	var bars: Array = []
	for i in n:
		bars.append({"den": b, "num": b})
	var pic := {"kind": "bar", "bars": bars} if n <= 4 and b <= 16 and level < 3 else {}
	var ex := K.number("%d ÷ 1/%d = ?" % [n, b], n * b, "How many %s fit in %d? Each whole has %d." % [WORDS.get(b, "parts"), n, b],
		"Each whole has %d %s, so %d wholes have %d × %d = %d. Check: %d × 1/%d = %d." % [b, WORDS.get(b, "parts"), n, n, b,
			n * b, n * b, b, n], pic)
	ex.data = {"n": n, "b": b}
	return ex


static func unit_divide_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 6 if level < 3 else 10)
	var n := rng.randi_range(2, 8)
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var ex: Dictionary
	var kind := "bags" if rng.randf() < 0.5 else "share"
	if kind == "bags":
		ex = K.number("%s has %d kg of seeds. How many bags of 1/%d kg can %s fill?" % [who, n, b, who], n * b,
			"How many 1/%d kg bags make 1 kg? Then %d kg?" % [b, n], "%d ÷ 1/%d = %d bags, because %d × 1/%d = %d." % [n, b, n * b,
				n * b, b, n])
	else:
		ex = K.number("1/%d L of juice is shared equally among %d friends. How much does each friend get, in litres?" % [b, n],
			"1/%d" % (b * n), "Share 1/%d into %d equal parts." % [b, n], "1/%d ÷ %d = 1/%d L each, because 1/%d × %d = 1/%d." % [b,
				n, b * n, b * n, n, b])
	ex.data = {"kind": kind, "n": n, "b": b}
	return ex


## "Which multiplication checks 1/5 ÷ 4 = 1/20?"
static func divide_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 8)
	var n := rng.randi_range(2, 6)
	var ex: Dictionary
	if level < 3 or rng.randf() < 0.5:
		ex = K.choice(rng, "Which multiplication checks 1/%d ÷ %d = 1/%d?" % [b, n, b * n], "1/%d × %d = 1/%d" % [b * n, n, b],
			["1/%d ÷ %d = 1/%d" % [b * n, n, b], "1/%d × %d = 1/%d" % [b, n, b * n], "%d × %d = %d" % [b, n, b * n + 1]],
			"Multiplication undoes division: the answer times %d should give 1/%d." % [n, b],
			"1/%d × %d = %d/%d = 1/%d, so the division was right." % [b * n, n, n, b * n, b])
	else:
		ex = K.choice(rng, "Which multiplication checks %d ÷ 1/%d = %d?" % [n, b, n * b], "%d × 1/%d = %d" % [n * b, b, n],
			["%d × %d = %d" % [n, b, n * b + b], "1/%d × %d = %d" % [b, n, n * b], "%d × 1/%d = %d" % [n, b, n * b]],
			"The answer times 1/%d should give %d." % [b, n], "%d × 1/%d = %d/%d = %d, so the division was right." % [n * b, b,
				n * b, b, n])
	ex.data = {"b": b, "n": n}
	return ex


## "6 ÷ 1/2 = 3" true or false (dividing by a half is not halving).
static func divide_truefalse(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 5)
	var n := b * rng.randi_range(1, 4) if level == 1 else rng.randi_range(2, 9)
	var ex: Dictionary
	var right := rng.randf() < 0.5
	if level < 3 or rng.randf() < 0.5:
		var shown := n * b if right else (int(n / float(b)) if n % b == 0 else n * b + b)
		ex = K.truefalse("%d ÷ 1/%d = %d" % [n, b, shown], shown == n * b,
			"How many %s fit in %d?" % [WORDS.get(b, "parts"), n], "%d ÷ 1/%d = %d, because each whole has %d %s." % [n, b, n * b,
				b, WORDS.get(b, "parts")])
	else:
		var shown := "1/%d" % (b * n) if right else "%d/%d" % [n, b]
		ex = K.truefalse("1/%d ÷ %d = %s" % [b, n, shown], right, "Sharing makes each part smaller than 1/%d." % b,
			"1/%d ÷ %d = 1/%d: one %s shared into %d." % [b, n, b * n, _one(b), n])
	ex.data = {"b": b, "n": n}
	return ex


# --- Helpers -------------------------------------------------------------------------------------------------------

## Two fractions a/b and c/d with different bottoms (level 1: one bottom a multiple of the other; 2: small bottoms that
## share nothing; 3: any); returns [a, b, c, d], every fraction below 1.
static func _pair(rng: RandomNumberGenerator, level: int) -> Array:
	var pairs1: Array = [[2, 4], [2, 6], [2, 8], [3, 6], [4, 8], [3, 12], [4, 12], [5, 10], [2, 10], [6, 12]]
	var pairs2: Array = [[2, 3], [3, 4], [2, 5], [3, 5], [4, 5], [5, 6], [3, 8], [5, 8]]
	var pairs3: Array = [[4, 6], [6, 8], [4, 10], [6, 9], [8, 12], [6, 10], [10, 12], [3, 10], [9, 12]]
	var pool: Array = [pairs1, pairs2, pairs3][level - 1]
	var pair: Array = pool[rng.randi_range(0, pool.size() - 1)].duplicate()
	if rng.randf() < 0.5:
		pair.reverse()
	var b: int = pair[0]
	var d: int = pair[1]
	return [rng.randi_range(1, b - 1), b, rng.randi_range(1, d - 1), d]


static func _lcm(a: int, b: int) -> int:
	return int(a * b / float(NumberAnswer.gcd(a, b)))


static func _common_hint(a: int, b: int, c: int, d: int) -> String:
	var l := _lcm(b, d)
	return "Make the parts the same size first: change both fractions into %s." % _parts_word(l) if l != b and l != d \
		else "Change %d/%d into %s first." % ([a, b, _parts_word(l)] if b != l else [c, d, _parts_word(l)])


## "1/2 = 3/6 and 1/3 = 2/6"
static func _both(a: int, b: int, c: int, d: int) -> String:
	var l := _lcm(b, d)
	return "%d/%d = %d/%d and %d/%d = %d/%d" % [a, b, a * int(l / float(b)), l, c, d, c * int(l / float(d)), l]


static func _parts_word(den: int) -> String:
	return WORDS.get(den, "%dths" % den)


static func _one(den: int) -> String:
	return {2: "half", 3: "third", 4: "quarter", 5: "fifth", 6: "sixth", 7: "seventh", 8: "eighth", 9: "ninth",
		10: "tenth"}.get(den, "part")


## 11/4 -> "2 3/4", 8/4 -> "2", 3/4 -> "3/4" (the fraction part in lowest terms).
static func _mixed(num: int, den: int) -> String:
	var w := int(num / float(den))
	var r := num % den
	if r == 0:
		return str(w)
	var g := NumberAnswer.gcd(r, den)
	return "%d/%d" % [r / g, den / g] if w == 0 else "%d %d/%d" % [w, r / g, den / g]


## w and top/den written as a mixed number, however big the top ("3 5/7").
static func _mixed_text(w: int, top: int, den: int) -> String:
	return "%d %d/%d" % [w, top, den] if top > 0 else str(w)


## " (that is 2 3/4)" when num/den is more than 1.
static func _as_mixed(num: int, den: int) -> String:
	return " (that is %s)" % _mixed(num, den) if num > den else ""


## "12/3" -> "4", "15/4" -> "15/4"
static func _frac_text(num: int, den: int) -> String:
	return str(int(num / float(den))) if num % den == 0 else "%d/%d" % [num, den]


## The exact value of "2 3/4", "3/4" or "5" as a float for comparing choices (they are small fractions).
static func _value(text: String) -> float:
	var parts := text.split(" ")
	if parts.size() == 2:
		return NumberAnswer.value(parts[0]) + NumberAnswer.value(parts[1])
	return NumberAnswer.value(text)
