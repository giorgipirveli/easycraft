class_name G4FractionsGen
extends RefCounted
## Owner #68 (spec §22.5): grade 4 maths generators for fractions and decimals (Common Core 4.NF; units 9-12 of the
## outline): SchoolGen "g4f.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded,
## level 1-3, each with a hint, a worked answer and `data` (its inputs, for tests). Denominators stay in grade 4's
## 2, 3, 4, 5, 6, 8, 10, 12 and 100. Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const DENS: Array[int] = [2, 3, 4, 5, 6, 8, 10, 12]
## Pairs of denominators where the second is a multiple of the first (equivalent fractions).
const PAIRS: Array = [[2, 4], [2, 6], [2, 8], [2, 10], [2, 12], [3, 6], [3, 12], [4, 8], [4, 12], [5, 10], [6, 12],
	[10, 100], [4, 100], [5, 100], [2, 100]]
const WORDS := {2: "halves", 3: "thirds", 4: "quarters", 5: "fifths", 6: "sixths", 8: "eighths", 10: "tenths",
	12: "twelfths", 100: "hundredths"}
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]


# --- Unit 9: equal fractions (4.NF.1, 4.NF.2) --------------------------------------------------------------------

## "2/3 = ?/12" (level 3 also the other way: "8/12 = 2/?").
static func equivalent_missing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pair: Array = PAIRS[rng.randi_range(0, 4 if level == 1 else PAIRS.size() - 1)]
	var b: int = pair[0]
	var d: int = pair[1]
	var k := int(d / float(b))
	var a := rng.randi_range(1, b - 1)
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.5:
		ex = K.number("%d/%d = %d/?" % [a * k, d, a], b, "Divide the top and the bottom by the same number: %d ÷ %d = %d." % [
			a * k, k, a], "%d/%d = %d/%d: the top and the bottom were both divided by %d." % [a * k, d, a, b, k])
	else:
		var pic := {"kind": "bar", "bars": [{"den": b, "num": a}, {"den": d, "num": 0}]} if level == 1 and d <= 16 else {}
		ex = K.number("%d/%d = ?/%d" % [a, b, d], a * k, "%d × %d = %d, so multiply the top by %d too." % [b, k, d, k],
			"%d/%d = %d/%d: the top and the bottom were both multiplied by %d." % [a, b, a * k, d, k], pic)
	ex.data = {"a": a, "b": b, "d": d}
	return ex


## "3/4 is equal to 6/8." True or false? (with the fraction walls)
static func is_equivalent(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pair: Array = PAIRS[rng.randi_range(0, 10)]
	var b: int = pair[0]
	var d: int = pair[1]
	var k := int(d / float(b))
	var a := rng.randi_range(1, b - 1)
	var c := a * k
	if rng.randf() < 0.5:
		c += 1 if c + 1 < d else -1
	var same := a * d == c * b
	var pic := {"kind": "bar", "bars": [{"den": b, "num": a}, {"den": d, "num": c}]} if level < 3 else {}
	var ex := K.truefalse("%d/%d is equal to %d/%d." % [a, b, c, d], same,
		"Multiply %d/%d's top and bottom by %d. Do you get %d/%d?" % [a, b, k, c, d],
		"%d/%d = %d/%d, so it is %s." % [a, b, a * k, d, "true" if same else "false: %d/%d is not %d/%d" % [c, d, a, b]], pic)
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "Which is bigger?" (the same bottom, the same top, or neither)
static func compare_fractions(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	var c := 0
	var d := 0
	for _t in 50:
		match level:
			1:
				b = DENS[rng.randi_range(1, DENS.size() - 1)]
				d = b
				a = rng.randi_range(1, b - 1)
				c = rng.randi_range(1, b - 1)
			2:
				b = DENS[rng.randi_range(0, DENS.size() - 1)]
				d = DENS[rng.randi_range(0, DENS.size() - 1)]
				a = rng.randi_range(1, mini(b, d) - 1) if mini(b, d) > 1 else 1
				c = a
			_:
				b = DENS[rng.randi_range(0, DENS.size() - 1)]
				d = DENS[rng.randi_range(0, DENS.size() - 1)]
				a = rng.randi_range(1, b - 1)
				c = rng.randi_range(1, d - 1)
		if "%d/%d" % [a, b] != "%d/%d" % [c, d] and a < b and c < d:
			break
	var left := "%d/%d" % [a, b]
	var right := "%d/%d" % [c, d]
	var cmp := a * d - c * b
	var answer := "They are equal" if cmp == 0 else (left if cmp > 0 else right)
	var ex := K.choice(rng, "Which is bigger: %s or %s?" % [left, right], answer, [left, right, "They are equal"].filter(
		func(x: String) -> bool: return x != answer), _compare_hint(a, b, c, d),
		"%s = %d/%d and %s = %d/%d: %s." % [left, a * d, b * d, right, c * b, b * d, "they are equal" if cmp == 0 else
			answer + " is bigger"])
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "Is 5/8 more or less than 1/2?"
static func benchmark_half(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var b: int = DENS[rng.randi_range(1, DENS.size() - 1)]
	var a := rng.randi_range(1, b - 1)
	var twice := 2 * a
	var answer := "exactly 1/2" if twice == b else ("more than 1/2" if twice > b else "less than 1/2")
	var ex := K.choice(rng, "Is %d/%d more or less than 1/2?" % [a, b], answer, ["more than 1/2", "less than 1/2",
		"exactly 1/2"].filter(func(x: String) -> bool: return x != answer),
		"Half of %d is %s. Is %d more or less than that?" % [b, _half_text(b), a],
		"Half of %d/%d would be %s/%d. %d is %s, so %d/%d is %s." % [b, b, _half_text(b), b, a,
			"the same" if twice == b else ("more" if twice > b else "less"), a, b, answer])
	ex.data = {"a": a, "b": b}
	return ex


## "Which picture shows 3/4?" (the choices are fraction walls)
static func pick_picture(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b: int = [2, 3, 4, 6, 8][rng.randi_range(0, 4)] if level < 3 else [5, 6, 8, 10, 12][rng.randi_range(0, 4)]
	var a := rng.randi_range(1, b - 1)
	var right := {"picture": {"kind": "bar", "den": b, "num": a}}
	var wrongs: Array = []
	for cand: Array in [[b, b - a], [b, a + 1], [b, a - 1], [a + 1, a], [b + 1, a]]:
		var den: int = cand[0]
		var num: int = cand[1]
		if den >= 2 and den <= 12 and num >= 1 and num < den and not (den == b and num == a) and num * b != a * den:
			var w := {"picture": {"kind": "bar", "den": den, "num": num}}
			if not wrongs.has(w):
				wrongs.append(w)
	var ex := K.choice(rng, "Which wall shows %d/%d?" % [a, b], right, wrongs.slice(0, 3),
		"Count the parts of the wall (the bottom number) and the shaded parts (the top number).",
		"%d/%d: %d equal parts, %d of them shaded." % [a, b, b, a])
	ex.data = {"a": a, "b": b}
	return ex


# --- Unit 10: add and subtract fractions (4.NF.3) ----------------------------------------------------------------

static func add_same(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d: int = DENS[rng.randi_range(1, DENS.size() - 1)]
	var parts: Array[int] = []
	for i in (3 if level == 3 else 2):
		parts.append(rng.randi_range(1, d - 1))
	var sum := 0
	for p in parts:
		sum += p
	if level == 1 and sum > d:
		parts = [maxi(1, int(d / 3.0)), maxi(1, int(d / 3.0))]
		sum = parts[0] + parts[1]
	var texts: Array[String] = []
	for p in parts:
		texts.append("%d/%d" % [p, d])
	var ex := K.number("%s = ?" % " + ".join(texts), "%d/%d" % [sum, d], "The parts are all %s: add the tops, keep the bottom." % WORDS[d],
		"%s = %d/%d%s" % [" + ".join(texts), sum, d, "" if sum <= d else " (that is %s)" % _mixed(sum, d)])
	ex.data = {"parts": parts, "d": d}
	return ex


static func sub_same(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d: int = DENS[rng.randi_range(1, DENS.size() - 1)]
	var a := rng.randi_range(2, d if level < 3 else d + d - 1)
	var b := rng.randi_range(1, a - 1)
	var ex := K.number("%d/%d − %d/%d = ?" % [a, d, b, d], "%d/%d" % [a - b, d], "Take away the tops, keep the bottom.",
		"%d/%d − %d/%d = %d/%d" % [a, d, b, d, a - b, d])
	ex.data = {"a": a, "b": b, "d": d}
	return ex


## "Which sum is the same as 5/6?"
static func decompose(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var d: int = DENS[rng.randi_range(2, DENS.size() - 1)]
	var n := rng.randi_range(3, d - 1)
	var right := _split(rng, n, d)
	var wrongs: Array = [_split(rng, n - 1, d), _split(rng, n + 1, d)]
	var halves: Array[String] = []   # adding the bottoms too: a common mix-up
	for part in right.split(" + "):
		halves.append("%s/%d" % [part.get_slice("/", 0), maxi(2, int(d / 2.0))])
	wrongs.append(" + ".join(halves))
	var ex := K.choice(rng, "Which sum is the same as %d/%d?" % [n, d], right, wrongs,
		"Add the tops of each sum. Which makes %d %s?" % [n, WORDS[d]], "%s = %d/%d" % [right, n, d])
	ex.data = {"n": n, "d": d}
	return ex


## "How many quarters are in 2 1/4?"
static func mixed_to_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d: int = DENS[rng.randi_range(0, 3 if level == 1 else DENS.size() - 1)]
	var w := rng.randi_range(1, 3 if level < 3 else 6)
	var a := rng.randi_range(1, d - 1)
	var ex := K.number("How many %s are in %d %d/%d?" % [WORDS[d], w, a, d], w * d + a,
		"Each whole is %d %s." % [d, WORDS[d]], "%d wholes are %d %s, and %d more make %d." % [w, w * d, WORDS[d], a, w * d + a])
	ex.data = {"w": w, "a": a, "d": d}
	return ex


## "1 2/5 + 2 1/5 = ?" as choices of mixed numbers.
static func add_mixed(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d: int = DENS[rng.randi_range(1, DENS.size() - 1)]
	var w1 := rng.randi_range(1, 4)
	var w2 := rng.randi_range(1, 4)
	var a := rng.randi_range(1, d - 1)
	var b := rng.randi_range(1, d - 1)
	if level < 3 and a + b >= d:
		b = maxi(1, d - a - 1) if d - a - 1 >= 1 else 1
		if a + b >= d:
			a = 1
			b = 1
	var total := (w1 + w2) * d + a + b
	var right := _mixed(total, d)
	var wrongs: Array = [_mixed(total + d, d), _mixed(total - 1, d), "%d %d/%d" % [w1 + w2, a + b, d + d]]
	var ex := K.choice(rng, "%d %d/%d + %d %d/%d = ?" % [w1, a, d, w2, b, d], right, wrongs,
		"Add the wholes, then the %s. If the %s make a whole, carry it." % [WORDS[d], WORDS[d]],
		"%d + %d = %d wholes and %d/%d + %d/%d = %d/%d: together %s." % [w1, w2, w1 + w2, a, d, b, d, a + b, d, right])
	ex.data = {"total": total, "d": d}
	return ex


static func fraction_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d: int = [4, 6, 8, 10, 12][rng.randi_range(0, 4)]
	var a := rng.randi_range(1, d - 2)
	var b := rng.randi_range(1, d - 1 - a)
	var names := NAMES.duplicate()
	K.shuffle(rng, names)
	var ex: Dictionary
	if level == 1 or rng.randf() < 0.5:
		ex = K.number("%s ate %d/%d of a cake and %s ate %d/%d. How much of the cake did they eat together?" % [names[0], a, d,
			names[1], b, d], "%d/%d" % [a + b, d], "Add the %s: add the tops." % WORDS[d],
			"%d/%d + %d/%d = %d/%d of the cake." % [a, d, b, d, a + b, d])
	else:
		var total := a + b
		ex = K.number("A path is %d/%d km long. %s has walked %d/%d km. How much further is it to the end?" % [total, d,
			names[0], a, d], "%d/%d" % [b, d], "Take the part walked away from the whole path.",
			"%d/%d − %d/%d = %d/%d km." % [total, d, a, d, b, d])
	ex.data = {"a": a, "b": b, "d": d}
	return ex


## "This wall has 8 blocks. Fill 3/8 of it."
static func build_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d: int = [4, 6, 8, 10, 12][rng.randi_range(0, 4)]
	var a := rng.randi_range(1, d - 1)
	var board := {"cols": d, "rows": 1, "block": BlockIds.BRICK, "given": [], "view": "wall"}
	var prompt := "This wall has room for %d blocks. Fill %d/%d of it." % [d, a, d]
	if level == 2 and d <= 6:
		board = {"cols": d * 2, "rows": 1, "block": BlockIds.BRICK, "given": [], "view": "wall"}
		prompt = "This wall has room for %d blocks. Fill %d/%d of it." % [d * 2, a, d]
	elif level == 3 and a > 1:
		var first := rng.randi_range(1, a - 1)
		prompt = "This wall has room for %d blocks. Fill %d/%d + %d/%d of it." % [d, first, d, a - first, d]
	var total := int(board.cols)
	var blocks := int(total * a / float(d))
	var ex := K.build(prompt, board, {"kind": "fraction", "num": a, "den": d},
		"Split the wall into %d equal parts. How many blocks is one part?" % d,
		"%d/%d of %d blocks is %d blocks." % [a, d, total, blocks])
	ex.data = {"a": a, "d": d, "total": total}
	return ex


# --- Unit 11: fractions times whole numbers (4.NF.4) ---------------------------------------------------------------

static func unit_times(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var d: int = DENS[rng.randi_range(0, DENS.size() - 1)]
	var n := rng.randi_range(2, 9)
	var ex := K.number("%d × 1/%d = ?" % [n, d], "%d/%d" % [n, d], "%d lots of 1/%d is %d %s." % [n, d, n, WORDS[d]],
		"%d × 1/%d = %d/%d" % [n, d, n, d])
	ex.data = {"n": n, "d": d}
	return ex


static func frac_times(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d: int = DENS[rng.randi_range(1, DENS.size() - 1)]
	var a := rng.randi_range(2, d - 1)
	var n := rng.randi_range(2, 5 if level < 3 else 9)
	var ex := K.number("%d × %d/%d = ?" % [n, a, d], "%d/%d" % [n * a, d], "%d/%d is %d × 1/%d. So %d × %d/%d is %d × %d %s." % [
		a, d, a, d, n, a, d, n, a, WORDS[d]], "%d × %d/%d = %d/%d" % [n, a, d, n * a, d])
	ex.data = {"n": n, "a": a, "d": d}
	return ex


## "3/5 = ? × 1/5"
static func as_unit_multiple(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var d: int = DENS[rng.randi_range(1, DENS.size() - 1)]
	var a := rng.randi_range(2, d + 3)
	var ex := K.number("%d/%d = ? × 1/%d" % [a, d, d], a, "How many %s make %d/%d?" % [WORDS[d], a, d],
		"%d/%d is %d lots of 1/%d." % [a, d, a, d])
	ex.data = {"a": a, "d": d}
	return ex


static func times_story(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var d: int = [2, 3, 4, 5, 8, 10][rng.randi_range(0, 5)]
	var a := rng.randi_range(1, d - 1)
	var n := rng.randi_range(2, 8)
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var ex: Dictionary
	if rng.randf() < 0.5:
		ex = K.number("A potion needs %d/%d of a cup of berries. How many cups of berries are needed for %d potions?" % [a, d, n],
			"%d/%d" % [n * a, d], "%d potions: %d × %d/%d." % [n, n, a, d], "%d × %d/%d = %d/%d cups%s." % [n, a, d, n * a, d,
				"" if n * a < d else " (%s)" % _mixed(n * a, d)])
	else:
		ex = K.number("One lap of the race track is %d/%d km. %s runs %d laps. How far does %s run in km?" % [a, d, who, n, who],
			"%d/%d" % [n * a, d], "%d laps: %d × %d/%d." % [n, n, a, d], "%d × %d/%d = %d/%d km." % [n, a, d, n * a, d])
	ex.data = {"n": n, "a": a, "d": d}
	return ex


## "5 × 3/8 is between which two whole numbers?"
static func times_between(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var d := 0
	var a := 0
	var n := 0
	for _t in 50:
		d = DENS[rng.randi_range(1, DENS.size() - 1)]
		a = rng.randi_range(1, d - 1)
		n = rng.randi_range(2, 9)
		if (n * a) % d != 0 and n * a > d:
			break
	var lo := int((n * a) / float(d))
	var right := "%d and %d" % [lo, lo + 1]
	var wrongs: Array = ["%d and %d" % [lo + 1, lo + 2], "%d and %d" % [maxi(lo - 1, 0), maxi(lo, 1)] if lo >= 1 else "%d and %d" % [
		lo + 2, lo + 3], "%d and %d" % [n, n + 1]]
	var ex := K.choice(rng, "%d × %d/%d is between which two whole numbers?" % [n, a, d], right, wrongs,
		"Work out %d × %d/%d as a fraction. How many whole %ds fit in the top?" % [n, a, d, d],
		"%d × %d/%d = %d/%d = %s, which is between %s." % [n, a, d, n * a, d, _mixed(n * a, d), right])
	ex.data = {"n": n, "a": a, "d": d}
	return ex


# --- Unit 12: tenths and hundredths (4.NF.5, 4.NF.6, 4.NF.7) --------------------------------------------------------

## "3/10 = ?/100"
static func tenths_to_hundredths(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var a := rng.randi_range(1, 9)
	var ex := K.number("%d/10 = ?/100" % a, a * 10, "Each tenth is 10 hundredths.", "%d/10 = %d/100" % [a, a * 10],
		{"kind": "bar", "bars": [{"den": 10, "num": a}, {"den": 100, "num": a * 10}]})
	ex.data = {"a": a}
	return ex


## "3/10 + 4/100 = ?/100"
static func add_tenths_hundredths(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(1, 9)
	var b := rng.randi_range(1, 99 if level == 3 else 9)
	if a * 10 + b > 100:
		b = 100 - a * 10
	var ex := K.number("%d/10 + %d/100 = ?/100" % [a, b], a * 10 + b, "Change %d/10 into hundredths first." % a,
		"%d/10 = %d/100, and %d/100 + %d/100 = %d/100." % [a, a * 10, a * 10, b, a * 10 + b])
	ex.data = {"a": a, "b": b}
	return ex


## "Write 62/100 as a decimal."
static func fraction_to_decimal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var a := rng.randi_range(1, 9)
			ex = K.number("Write %d/10 as a decimal." % a, "0.%d" % a, "Tenths go in the first place after the point.",
				"%d/10 = 0.%d" % [a, a])
		2:
			var a := rng.randi_range(1, 99)
			ex = K.number("Write %d/100 as a decimal." % a, "0.%02d" % a, "Hundredths go in the second place after the point.",
				"%d/100 = 0.%02d" % [a, a])
		_:
			var w := rng.randi_range(1, 9)
			var a := rng.randi_range(1, 99)
			ex = K.number("Write %d %d/100 as a decimal." % [w, a], "%d.%02d" % [w, a],
				"The whole number goes before the point, the hundredths after it.", "%d %d/100 = %d.%02d" % [w, a, w, a])
	ex.data = {"answer": ex.answer}
	return ex


## "0.45 = ?/100"
static func decimal_to_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var a := rng.randi_range(1, 9)
		ex = K.number("0.%d = ?/10" % a, a, "The first place after the point is tenths.", "0.%d = %d/10" % [a, a])
	elif level == 2:
		var a := rng.randi_range(11, 99)
		ex = K.number("0.%02d = ?/100" % a, a, "Two places after the point are hundredths.", "0.%02d = %d/100" % [a, a])
	else:
		var a := rng.randi_range(1, 9)
		ex = K.number("0.%d = ?/100" % a, a * 10, "0.%d is %d tenths. How many hundredths is that?" % [a, a],
			"0.%d = %d/10 = %d/100" % [a, a, a * 10])
	ex.data = {"answer": ex.answer}
	return ex


## "Which is greater: 0.5 or 0.45?"
static func compare_decimals(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var x := 0
	var y := 0
	var xs := ""
	var ys := ""
	match level:
		1:
			x = rng.randi_range(1, 9) * 10
			y = rng.randi_range(1, 9) * 10
		2:
			x = rng.randi_range(1, 9) * 10
			y = rng.randi_range(1, 99)
		_:
			x = rng.randi_range(1, 9)
			y = rng.randi_range(1, 9) * 10
	if x == y:
		y = (y + 10 if y <= 80 else y - 10) if level == 1 else (y + 1 if y < 99 else y - 1)
	xs = _decimal(x)
	ys = _decimal(y)
	if rng.randf() < 0.15 and x % 10 == 0:
		ys = "0.%02d" % x   # 0.5 and 0.50
		y = x
	var answer := "They are equal" if x == y else (xs if x > y else ys)
	if rng.randf() < 0.5:
		var t := xs
		xs = ys
		ys = t
	var ex := K.choice(rng, "Which is greater: %s or %s?" % [xs, ys], answer, [xs, ys, "They are equal"].filter(
		func(v: String) -> bool: return v != answer), "Compare the tenths first. If they are the same, compare the hundredths.",
		"%s is %d hundredths and %s is %d hundredths." % [_decimal(x), x, _decimal(y), y])
	ex.data = {"x": x, "y": y}
	return ex


## "What decimal is at the dot?" on a number line of tenths.
static func decimal_on_line(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := 0 if level == 1 else rng.randi_range(1, 4)
	var a := rng.randi_range(1, 9)
	var value := "%d.%d" % [w, a]
	var ex := K.number("What decimal is at the dot?", value, "The line is cut into tenths. Count the steps from %d." % w,
		"The dot is %d tenths after %d: %s." % [a, w, value],
		{"kind": "number_line", "from": str(w), "to": str(w + 1), "step": "0.1", "dot": value, "labels": "ends"})
	ex.data = {"value": value}
	return ex


## "This wall has 10 blocks. Fill 0.6 of it."
static func build_tenths(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(1, 9)
	var rows := 1 if level == 1 else 2
	var ex := K.build("This wall has room for %d blocks. Fill %s of it." % [10 * rows, _decimal(a * 10)],
		{"cols": 10, "rows": rows, "block": BlockIds.BRICK, "given": [], "view": "wall"},
		{"kind": "fraction", "num": a, "den": 10}, "%s is %d tenths. How many blocks is one tenth of this wall?" % [_decimal(a * 10), a],
		"%s of %d blocks is %d blocks." % [_decimal(a * 10), 10 * rows, a * rows])
	ex.data = {"a": a, "rows": rows}
	return ex


# --- Helpers -------------------------------------------------------------------------------------------------------

## A fraction as a whole number and a fraction: 11/4 -> "2 3/4", 8/4 -> "2".
static func _mixed(num: int, den: int) -> String:
	var w := int(num / float(den))
	var r := num % den
	if r == 0:
		return str(w)
	return "%d/%d" % [r, den] if w == 0 else "%d %d/%d" % [w, r, den]


## n/d as a sum of 2 or 3 fractions with the same bottom: "1/6 + 1/6 + 3/6".
static func _split(rng: RandomNumberGenerator, n: int, d: int) -> String:
	var parts: Array[String] = []
	var left := n
	var pieces := rng.randi_range(2, 3) if n >= 3 else 2
	for i in pieces - 1:
		var p := rng.randi_range(1, maxi(1, left - (pieces - 1 - i)))
		parts.append("%d/%d" % [p, d])
		left -= p
	parts.append("%d/%d" % [maxi(left, 1), d])
	return " + ".join(parts)


## Hundredths as a decimal: 40 -> "0.4", 45 -> "0.45", 5 -> "0.05".
static func _decimal(hundredths: int) -> String:
	if hundredths % 10 == 0:
		return "0.%d" % int(hundredths / 10.0)
	return "0.%02d" % hundredths


static func _half_text(b: int) -> String:
	return str(int(b / 2.0)) if b % 2 == 0 else "%d and a half" % int(b / 2.0)


static func _compare_hint(a: int, b: int, c: int, d: int) -> String:
	if b == d:
		return "The parts are the same size: more parts is bigger."
	if a == c:
		return "The same number of parts: bigger parts (a smaller bottom number) make more."
	return "Make the bottoms the same: %d/%d = %d/%d and %d/%d = %d/%d." % [a, b, a * d, b * d, c, d, c * b, b * d]
