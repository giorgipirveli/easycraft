class_name G4MathsGen
extends RefCounted
## Owner #68 (spec §22.5): grade 4 maths generators for whole numbers and operations (Common Core 4.NBT, 4.OA; units 1-8
## of the outline). Each is `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary` (SchoolGen
## "g4m.<name>"), seeded, level 1-3 (easier to harder), returning an exercise with a hint, a worked answer and `data`
## (its inputs, for tests). Whole numbers stay at most 1,000,000. Helpers start with "_".
## Fractions and decimals: G4FractionsGen ("g4f"); measurement and geometry: G4MeasureGen ("g4g").

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]


# --- Unit 1: big numbers (4.NBT.1, 4.NBT.2) ----------------------------------------------------------------------

## "What is the value of the 7 in 472,305?"
static func digit_value(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits := 3 + level
	var n := 0
	var pos := 0
	for _try in 100:
		n = K.with_digits(rng, digits)
		pos = rng.randi_range(0, digits - 1)
		var t := str(n)
		if t[pos] != "0" and t.count(t[pos]) == 1:
			break
	var s := str(n)
	var d := int(s[pos])
	var place := digits - 1 - pos
	var wrongs: Array = []
	for k in digits:
		if k != place:
			wrongs.append(K.fmt(d * K.pow10(k)))
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "What is the value of the %d in %s?" % [d, K.fmt(n)], K.fmt(d * K.pow10(place)),
		wrongs.slice(0, 3), "The %d is in the %s place." % [d, K.PLACES[place]],
		"The %d is in the %s place, so it is worth %s." % [d, K.PLACES[place], K.fmt(d * K.pow10(place))])
	ex.data = {"n": n, "place": place}
	return ex


## "400,000 + 70,000 + 2,000 + 300 + 5 = ?"
static func expanded_form(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := _with_some_zeros(rng, 3 + level)
	var parts := _parts(n)
	var ex := K.number("%s = ?" % " + ".join(parts), n, "Put each part in its place: the biggest part first.",
		"%s makes %s." % [" + ".join(parts), K.fmt(n)])
	ex.data = {"n": n}
	return ex


## "Which is 47,305 in expanded form?"
static func to_expanded(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := _with_some_zeros(rng, 3 + level)
	var right := " + ".join(_parts(n))
	var s := str(n)
	var shifted: Array[String] = []   # every part one place too small
	for i in s.length():
		if s[i] != "0" and s.length() - 2 - i >= 0:
			shifted.append(K.fmt(int(s[i]) * K.pow10(s.length() - 2 - i)))
		elif s[i] != "0":
			shifted.append(s[i])
	var digits_only: Array[String] = []   # the digits without their places
	for ch in s:
		if ch != "0":
			digits_only.append(ch)
	var bigger: Array[String] = []
	for p in _parts(n):
		bigger.append(K.fmt(int(p.replace(",", "")) * 10))
	var ex := K.choice(rng, "Which is %s in expanded form?" % K.fmt(n), right,
		[" + ".join(shifted), " + ".join(digits_only), " + ".join(bigger)],
		"Each digit is worth its place: count the places after it.", "%s = %s" % [K.fmt(n), right])
	ex.data = {"n": n}
	return ex


## "Which number is forty-two thousand six hundred and five?"
static func number_words(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := _with_some_zeros(rng, 3 + level)
	var wrongs := _digit_mixups(rng, n, 3)
	var ex := K.choice(rng, "Which number is \"%s\"?" % NumberWords.say(n), K.fmt(n), wrongs,
		"Find the thousands first, then the hundreds, tens and ones.", "\"%s\" is %s." % [NumberWords.say(n), K.fmt(n)])
	ex.data = {"n": n}
	return ex


## "The 3 in 3,000 is worth how many times the 3 in 300?"
static func ten_times(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var d := rng.randi_range(1, 9)
	var k := rng.randi_range(1, 4)
	if level == 3:
		var big := d * K.pow10(k + 1)
		var ex3 := K.number("%s is 10 times what number?" % K.fmt(big), d * K.pow10(k),
			"Ten times a number moves each digit one place to the left. Go one place back.",
			"%s × 10 = %s, so the answer is %s." % [K.fmt(d * K.pow10(k)), K.fmt(big), K.fmt(d * K.pow10(k))])
		ex3.data = {"d": d, "k": k, "level": 3}
		return ex3
	var gap := 1 if level == 1 else 2
	var a := d * K.pow10(k + gap)
	var b := d * K.pow10(k)
	var ex := K.number("The %d in %s is worth how many times the %d in %s?" % [d, K.fmt(a), d, K.fmt(b)], K.pow10(gap),
		"Each place to the left is worth ten times as much.",
		"%s is %d places to the left, so it is worth %s times as much." % [K.fmt(a), gap, K.fmt(K.pow10(gap))])
	ex.data = {"d": d, "k": k, "gap": gap}
	return ex


## Base-ten blocks: "What number do the blocks show?"
static func blocks_number(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t := rng.randi_range(1, 3) if level == 3 else 0
	var h := rng.randi_range(1 if level == 1 else 0, 5)
	var te := rng.randi_range(0, 9 if level > 1 else 6)
	var o := rng.randi_range(0, 9)
	if level > 1 and rng.randf() < 0.4:
		te = 0
	var n := t * 1000 + h * 100 + te * 10 + o
	if n == 0:
		o = 3
		n = 3
	var ex := K.number("What number do the blocks show?", n, "A big cube is 1,000, a flat is 100, a rod is 10 and a small cube is 1.",
		"%d thousands, %d hundreds, %d tens and %d ones make %s." % [t, h, te, o, K.fmt(n)],
		{"kind": "blocks", "thousands": t, "hundreds": h, "tens": te, "ones": o})
	ex.data = {"n": n}
	return ex


# --- Unit 2: compare and round (4.NBT.2, 4.NBT.3) -------------------------------------------------------------

## "Which sign makes this true? 45,302 ? 45,230"
static func compare(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits := 3 + level
	var a := K.with_digits(rng, digits)
	var b := a
	var roll := rng.randf()
	if roll < 0.15:
		b = a
	else:
		var place := rng.randi_range(0, mini(level, digits - 2))   # a difference in a low place is harder to see
		var p := K.pow10(place)
		var delta := rng.randi_range(1, 8) * p * (1 if rng.randf() < 0.5 else -1)
		b = clampi(a + delta, K.pow10(digits - 1), K.pow10(digits) - 1)
		if b == a:
			b = a + p if a + p < K.pow10(digits) else a - p
	var sign := "=" if a == b else (">" if a > b else "<")
	var ex := K.choice(rng, "Which sign makes this true?  %s ? %s" % [K.fmt(a), K.fmt(b)], sign,
		[">", "<", "="].filter(func(x: String) -> bool: return x != sign),
		"Compare the digits from the left. The first place where they differ decides.",
		"%s %s %s" % [K.fmt(a), sign, K.fmt(b)])
	ex.data = {"a": a, "b": b}
	return ex


## "Put these numbers in order, smallest first."
static func order_numbers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits := 3 + level
	var base := K.with_digits(rng, digits)
	var nums: Array[int] = [base]
	var tries := 0
	while nums.size() < 4 and tries < 100:
		tries += 1
		var place := rng.randi_range(0, digits - 2)
		var v := clampi(base + rng.randi_range(-9, 9) * K.pow10(place), K.pow10(digits - 1), K.pow10(digits) - 1)
		if not nums.has(v):
			nums.append(v)
	nums.sort()
	var texts: Array = []
	for v in nums:
		texts.append(K.fmt(v))
	var ex := K.order(rng, "Put these numbers in order, smallest first.", texts,
		"Compare the digits from the left, place by place.", "Smallest to largest: %s." % ", ".join(texts))
	ex.data = {"nums": nums}
	return ex


## "Round 46,732 to the nearest thousand." (with its number line)
static func round_to(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits := rng.randi_range(2 + level, 3 + level)
	var n := K.with_digits(rng, digits)
	var place := rng.randi_range(1, 2) if level == 1 else (rng.randi_range(2, 3) if level == 2 else rng.randi_range(3, 5))
	place = mini(place, digits - 1)
	var p := K.pow10(place)
	if n % p == 0:
		n += int(p / 2.0) - 1
	var lower := int(n / float(p)) * p
	var rounded := lower + p if n - lower >= int(p / 2.0) else lower
	var names := {1: "ten", 2: "hundred", 3: "thousand", 4: "ten thousand", 5: "hundred thousand"}
	var next_digit := int((n % p) / (p / 10.0))
	var line := {"kind": "number_line", "from": str(lower), "to": str(lower + p), "step": str(int(p / 10.0)), "dot": str(n),
		"labels": "ends"}
	var ex := K.number("Round %s to the nearest %s." % [K.fmt(n), names[place]], rounded,
		"Look at the digit after the %ss place. 5 or more rounds up; 4 or less rounds down." % names[place],
		"%s is between %s and %s. The next digit is %d, so it rounds %s to %s." % [K.fmt(n), K.fmt(lower), K.fmt(lower + p),
			next_digit, "up" if rounded > lower else "down", K.fmt(rounded)], line)
	ex.data = {"n": n, "place": place}
	return ex


## "46,732 rounded to the nearest thousand is 46,000." True or false?
static func round_true_false(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var r := round_to(rng, level)
	var n := int(r.data.n)
	var p := K.pow10(int(r.data.place))
	var right := int(r.answer)
	var claimed := right if rng.randf() < 0.5 else (right - p if right - p >= 0 and right - p != right else right + p)
	var names := {1: "ten", 2: "hundred", 3: "thousand", 4: "ten thousand", 5: "hundred thousand"}
	var ex := K.truefalse("%s rounded to the nearest %s is %s." % [K.fmt(n), names[int(r.data.place)], K.fmt(claimed)],
		claimed == right, str(r.hint), str(r.explain), r.picture)
	ex.data = r.data
	return ex


# --- Unit 3: add and subtract (4.NBT.4, 4.OA.3) --------------------------------------------------------------------

static func add_big(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits: int = [0, 4, 5, 6][level]
	var a := K.with_digits(rng, digits)
	var b := K.with_digits(rng, digits - rng.randi_range(0, 1))
	if a + b > 1_000_000:
		a = 1_000_000 - b - rng.randi_range(1, 999)
	var ex := K.number("%s + %s = ?" % [K.fmt(a), K.fmt(b)], a + b,
		"Add the ones first, then the tens, hundreds and on. Carry a 1 when a column makes 10 or more.",
		"%s + %s = %s" % [K.fmt(a), K.fmt(b), K.fmt(a + b)])
	ex.data = {"a": a, "b": b}
	return ex


static func sub_big(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits: int = [0, 4, 5, 6][level]
	var a := K.with_digits(rng, digits)
	if level == 3 and rng.randf() < 0.5:
		a = int(a / 10000.0) * 10000   # zeros to subtract across: 60,000 − 23,457
	var b := rng.randi_range(K.pow10(digits - 2), a - 1)
	var ex := K.number("%s − %s = ?" % [K.fmt(a), K.fmt(b)], a - b,
		"Take away the ones first. When the top digit is smaller, exchange 1 from the next place.",
		"%s − %s = %s. Check: %s + %s = %s." % [K.fmt(a), K.fmt(b), K.fmt(a - b), K.fmt(a - b), K.fmt(b), K.fmt(a)])
	ex.data = {"a": a, "b": b}
	return ex


## "3,450 + ? = 8,000"
static func missing_addend(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var total := rng.randi_range(2, 9) * K.pow10(level + 2) if level < 3 else K.with_digits(rng, 5)
	var a := rng.randi_range(int(total / 5.0), total - 1)
	var ex := K.number("%s + ? = %s" % [K.fmt(a), K.fmt(total)], total - a, "Take %s away from %s." % [K.fmt(a), K.fmt(total)],
		"%s − %s = %s" % [K.fmt(total), K.fmt(a), K.fmt(total - a)])
	ex.data = {"a": a, "total": total}
	return ex


## Story problems: one step (levels 1-2) or two steps (level 3).
static func add_sub_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var size: int = [0, 1000, 10000, 100000][level]
	var a := rng.randi_range(size, size * 9)
	var b := rng.randi_range(int(size / 4.0), a - 1)
	var ex: Dictionary
	match rng.randi_range(0, 2 if level < 3 else 3):
		0:
			ex = K.number("%s had %s gold. %s earned %s more gold at the market. How much gold does %s have now?" % [who,
				K.fmt(a), who, K.fmt(b), who], a + b, "More gold: add.", "%s + %s = %s gold." % [K.fmt(a), K.fmt(b), K.fmt(a + b)])
		1:
			ex = K.number("A castle needs %s blocks. %s has placed %s. How many more blocks are needed?" % [K.fmt(a), who,
				K.fmt(b)], a - b, "How many more: take away what is done from the whole.",
				"%s − %s = %s blocks." % [K.fmt(a), K.fmt(b), K.fmt(a - b)])
		2:
			ex = K.number("%s counted %s snowflakes on Monday and %s on Tuesday. How many more on Monday?" % [who, K.fmt(a),
				K.fmt(b)], a - b, "Compare: take the smaller count away from the bigger one.",
				"%s − %s = %s more on Monday." % [K.fmt(a), K.fmt(b), K.fmt(a - b)])
		_:
			b = rng.randi_range(int(size / 4.0), int(a / 2.0))
			var c := rng.randi_range(int(size / 10.0), int((a - b) / 2.0))
			ex = K.number("%s baked %s cupcakes, gave %s to the bakery and %s to friends. How many are left?" % [who,
				K.fmt(a), K.fmt(b), K.fmt(c)], a - b - c, "Two steps: take away the first gift, then the second.",
				"%s − %s − %s = %s cupcakes left." % [K.fmt(a), K.fmt(b), K.fmt(c), K.fmt(a - b - c)])
			ex.data = {"a": a, "b": b, "c": c}
			return ex
	ex.data = {"a": a, "b": b}
	return ex


## "Zara added 4,875 + 3,110 and got 17,985. Is that reasonable?"
static func estimate_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var digits := level + 3
	var a := K.with_digits(rng, digits)
	var b := K.with_digits(rng, digits)
	var right := a + b
	var ok := rng.randf() < 0.5
	var claimed := right if ok else right + K.pow10(digits) * (1 if rng.randf() < 0.5 else -1)
	if claimed <= 0:
		claimed = right + K.pow10(digits)
		ok = false
	var p := K.pow10(digits - 1)
	var ra := roundi(a / float(p)) * p
	var rb := roundi(b / float(p)) * p
	var yes := "Yes: about %s + %s = %s" % [K.fmt(ra), K.fmt(rb), K.fmt(ra + rb)]
	var no := "No: it should be about %s" % K.fmt(ra + rb)
	var ex := K.choice(rng, "%s added %s + %s and got %s. Is that reasonable?" % [who, K.fmt(a), K.fmt(b), K.fmt(claimed)],
		yes if ok else no, [no if ok else yes], "Round each number and add them in your head.",
		"%s + %s is about %s + %s = %s." % [K.fmt(a), K.fmt(b), K.fmt(ra), K.fmt(rb), K.fmt(ra + rb)])
	ex.data = {"a": a, "b": b, "claimed": claimed}
	return ex


# --- Unit 4: times as many (4.OA.1, 4.OA.2) ------------------------------------------------------------------------

static func times_as_many(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := _two_names(rng)
	var n := rng.randi_range(2, 9)
	var times := rng.randi_range(2, 9 if level > 1 else 5)
	var things: String = ["gems", "shells", "carrots", "lanterns", "cupcakes"][rng.randi_range(0, 4)]
	var ex: Dictionary
	match level:
		1:
			ex = K.number("%s has %d %s. %s has %d times as many. How many %s does %s have?" % [names[0], n, things, names[1],
				times, things, names[1]], n * times, "%d times as many as %d means %d × %d." % [times, n, times, n],
				"%d × %d = %d %s." % [times, n, n * times, things])
		2:
			ex = K.number("%s has %d %s. That is %d times as many as %s has. How many does %s have?" % [names[0], n * times,
				things, times, names[1], names[1]], n, "Which number times %d makes %d?" % [times, n * times],
				"%d × %d = %d, so %s has %d." % [times, n, n * times, names[1], n])
		_:
			ex = K.number("A dragon has %d scales on its tail and %d on its nose. How many times as many are on its tail?" % [
				n * times, n], times, "How many %ds make %d?" % [n, n * times],
				"%d × %d = %d, so %d times as many." % [times, n, n * times, times])
	ex.data = {"n": n, "times": times}
	return ex


## "Which sentence means 28 = 7 × 4?" / "Which equation shows 36 is 4 times as many as 9?"
static func comparison_sentence(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9)
	var b := rng.randi_range(2, 9)
	while b == a:
		b = rng.randi_range(2, 9)
	var p := a * b
	var ex: Dictionary
	if level == 1 or rng.randf() < 0.5:
		ex = K.choice(rng, "Which sentence means %d = %d × %d?" % [p, a, b], "%d is %d times as many as %d." % [p, a, b],
			["%d is %d more than %d." % [p, a, b], "%d is %d times as many as %d." % [b, a, p], "%d is %d more than %d." % [p, b, a]],
			"A × sign compares by times as many, not by more.", "%d = %d × %d says %d is %d times as many as %d." % [p, a, b, p, a, b])
	else:
		ex = K.choice(rng, "Which equation shows \"%d is %d times as many as %d\"?" % [p, a, b], "%d = %d × %d" % [p, a, b],
			["%d = %d + %d" % [p, a, b], "%d = %d × %d" % [b, a, p], "%d = %d − %d" % [p, a, b]],
			"Times as many means multiply.", "%d is %d times as many as %d: %d = %d × %d." % [p, a, b, p, a, b])
	ex.data = {"a": a, "b": b}
	return ex


## "Pip has 6 blocks. Tilly has 3 times as many. Zara has 3 more than Pip. Who has more?"
static func times_or_more(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var names := _three_names(rng)
	var n := rng.randi_range(2, 8)
	var k := rng.randi_range(2, 5)
	var times := n * k
	var more := n + k
	var right: String = names[1] if times > more else (names[2] if more > times else "They have the same")
	var ex := K.choice(rng, "%s has %d blocks. %s has %d times as many. %s has %d more than %s. Who has more?" % [names[0], n,
		names[1], k, names[2], k, names[0]], right, [names[1], names[2], "They have the same"].filter(
			func(x: String) -> bool: return x != right), "Work out both: %d × %d and %d + %d." % [k, n, n, k],
		"%s has %d × %d = %d. %s has %d + %d = %d." % [names[1], k, n, times, names[2], n, k, more])
	ex.data = {"n": n, "k": k}
	return ex


## "Pip's tower is 2 blocks tall. Build a tower 3 times as tall."
static func build_times(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(1, 3 if level == 1 else 4)
	var k := rng.randi_range(2, 3 if level == 1 else 4)
	while n * k > 10:
		k -= 1
	var who: String = NAMES[rng.randi_range(0, NAMES.size() - 1)]
	var ex := K.build("%s's tower is %d block%s tall. Build a tower %d times as tall." % [who, n, "" if n == 1 else "s", k],
		{"cols": 5, "rows": 10, "block": BlockIds.BRICK, "given": [], "view": "wall"},
		{"kind": "array", "rows": n * k, "cols": 1}, "%d times as tall as %d is %d × %d." % [k, n, k, n],
		"%d × %d = %d blocks, one on top of another." % [k, n, n * k])
	ex.data = {"n": n, "k": k}
	return ex


# --- Unit 5: multiply bigger numbers (4.NBT.5) ------------------------------------------------------------------

## "600 × 7 = ?", "40 × 50 = ?"
static func mult_tens(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 9) * K.pow10(rng.randi_range(1, 2 if level > 1 else 1))
	var b := rng.randi_range(2, 9) * (10 if level == 3 else 1)
	var ex := K.number("%s × %s = ?" % [K.fmt(a), K.fmt(b)], a * b, "Multiply the digits that are not zero, then add the zeros.",
		"%s × %s = %s" % [K.fmt(a), K.fmt(b), K.fmt(a * b)])
	ex.data = {"a": a, "b": b}
	return ex


static func mult_1digit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := K.with_digits(rng, level + 1)
	var b := rng.randi_range(2, 9)
	var s := str(a)
	var parts: Array[String] = []
	for i in s.length():
		if s[i] != "0":
			parts.append("%d × %s" % [b, K.fmt(int(s[i]) * K.pow10(s.length() - 1 - i))])
	var ex := K.number("%s × %d = ?" % [K.fmt(a), b], a * b, "Split %s into its places and multiply each part by %d." % [K.fmt(a), b],
		"%s = %s" % [" + ".join(parts), K.fmt(a * b)])
	ex.data = {"a": a, "b": b}
	return ex


static func mult_2x2(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(11, 49 if level < 3 else 99)
	var b := rng.randi_range(11, 29 if level < 3 else 99)
	var tens := int(b / 10.0) * 10
	var ones := b % 10
	var ex := K.number("%d × %d = ?" % [a, b], a * b, "Split %d into %d + %d. Multiply %d by each part and add." % [b, tens, ones, a],
		"%d × %d = %s and %d × %d = %d. %s + %d = %s." % [a, tens, K.fmt(a * tens), a, ones, a * ones, K.fmt(a * tens), a * ones,
			K.fmt(a * b)], {"kind": "rect", "w": 10, "h": 4, "grid": false, "label_w": "%d" % b, "label_h": "%d" % a})
	ex.data = {"a": a, "b": b}
	return ex


static func mult_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var per: int = [0, rng.randi_range(12, 48), rng.randi_range(105, 350), rng.randi_range(1050, 2400)][level]
	var n := rng.randi_range(3, 9)
	var ex := K.number("Each treasure chest holds %s coins. How many coins are in %d chests?" % [K.fmt(per), n], per * n,
		"%d chests of %s: multiply." % [n, K.fmt(per)], "%d × %s = %s coins." % [n, K.fmt(per), K.fmt(per * n)])
	ex.data = {"per": per, "n": n}
	return ex


## "Build an array that shows 4 × 3."
static func array_build(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 4 if level == 1 else 5)
	var b := rng.randi_range(2, 6 if level == 1 else 8)
	var ex := K.build("Build an array that shows %d × %d." % [a, b], {"cols": 8, "rows": 5, "block": BlockIds.PLANKS,
		"given": [], "view": "wall"}, {"kind": "array", "rows": a, "cols": b, "any_turn": true},
		"Make %d rows with %d blocks in each." % [a, b], "%d rows of %d blocks: %d × %d = %d." % [a, b, a, b, a * b])
	ex.data = {"a": a, "b": b}
	return ex


# --- Unit 6: divide with remainders (4.NBT.6, 4.OA.3) -----------------------------------------------------------

static func div_exact(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 9)
	var q := K.with_digits(rng, level) if level > 1 else rng.randi_range(11, 24)
	var a := b * q
	var ex := K.number("%s ÷ %d = ?" % [K.fmt(a), b], q, "Which number times %d makes %s? Share the thousands, hundreds, tens and ones." % [b, K.fmt(a)],
		"%d × %s = %s, so %s ÷ %d = %s." % [b, K.fmt(q), K.fmt(a), K.fmt(a), b, K.fmt(q)])
	ex.data = {"a": a, "b": b}
	return ex


## "47 ÷ 5 = ?" with remainders as choices.
static func div_remainder(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(3, 9)
	var q := rng.randi_range(3, 9) if level == 1 else rng.randi_range(12, 99 if level == 2 else 999)
	var r := rng.randi_range(1, b - 1)
	var a := b * q + r
	var right := "%d remainder %d" % [q, r]
	var wrongs := ["%d remainder %d" % [q, (r + 1) % b if (r + 1) % b != r else r - 1],
		"%d remainder %d" % [q - 1, r + b], "%d remainder %d" % [q + 1, r]]
	var ex := K.choice(rng, "%s ÷ %d = ?" % [K.fmt(a), b], right, wrongs,
		"How many whole %ds fit in %s? What is left over must be less than %d." % [b, K.fmt(a), b],
		"%d × %s = %s, and %s − %s = %d left over." % [b, K.fmt(q), K.fmt(b * q), K.fmt(a), K.fmt(b * q), r])
	ex.data = {"a": a, "b": b}
	return ex


## "29 children, 4 in each boat": the boats needed, the full boats or the children left.
static func remainder_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(3, 8)
	var q := rng.randi_range(4, 12) if level < 3 else rng.randi_range(12, 40)
	var r := rng.randi_range(1, b - 1)
	var n := b * q + r
	var ex: Dictionary
	match rng.randi_range(0, 2):
		0:
			ex = K.number("%d children want a boat ride. Each boat holds %d. How many boats are needed so everyone gets a ride?" % [
				n, b], q + 1, "%d ÷ %d leaves some children over. They need a boat too." % [n, b],
				"%d ÷ %d = %d remainder %d: %d full boats and one more for the %d left." % [n, b, q, r, q, r])
		1:
			ex = K.number("%s packs %d eggs into boxes of %d. How many boxes are full?" % [NAMES[rng.randi_range(0, 5)], n, b], q,
				"Only full boxes count: the remainder is not a full box.", "%d ÷ %d = %d remainder %d: %d full boxes." % [n, b, q, r, q])
		_:
			ex = K.number("%d gems are shared equally by %d friends. How many gems are left over?" % [n, b], r,
				"Share as many as you can, then count what is left.", "%d ÷ %d = %d remainder %d: %d left over." % [n, b, q, r, r])
	ex.data = {"n": n, "b": b}
	return ex


# --- Unit 7: factors, multiples and primes (4.OA.4) --------------------------------------------------------------

static func is_factor(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var top: int = [0, 36, 60, 100][level]
	var n := rng.randi_range(12, top)
	var f := rng.randi_range(2, 12)
	if rng.randf() < 0.5:
		var fs := _factors(n).filter(func(x: int) -> bool: return x > 1 and x < n)
		if not fs.is_empty():
			f = fs[rng.randi_range(0, fs.size() - 1)]
	var yes := n % f == 0
	var ex := K.truefalse("%d is a factor of %d." % [f, n], yes, "Does %d go into %d with nothing left over?" % [f, n],
		("%d × %d = %d, so %d is a factor." % [f, int(n / float(f)), n, f]) if yes else ("%d ÷ %d leaves %d over, so %d is not a factor." % [n,
			f, n % f, f]))
	ex.data = {"n": n, "f": f}
	return ex


static func not_factor(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var options: Array[int] = [36, 40, 42, 48, 60, 72, 84, 90, 96, 100]
	if level == 1:
		options = [12, 18, 20, 24, 30, 36]
	var n: int = options[rng.randi_range(0, options.size() - 1)]
	var fs: Array = _factors(n).filter(func(x: int) -> bool: return x > 1 and x < n)
	K.shuffle(rng, fs)
	var wrong := n
	for _t in 100:
		wrong = rng.randi_range(2, mini(n - 1, 15))
		if n % wrong != 0:
			break
	var ex := K.choice(rng, "Which number is NOT a factor of %d?" % n, str(wrong), fs.slice(0, 3).map(func(x: int) -> String: return str(x)),
		"A factor goes into %d with nothing left over. Try dividing by each." % n,
		"%d ÷ %d leaves %d over. The others go into %d exactly." % [n, wrong, n % wrong, n])
	ex.data = {"n": n, "wrong": wrong}
	return ex


static func is_multiple(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var k := rng.randi_range(3, 9)
	var right := k * rng.randi_range(3, 11 if level < 3 else 14)
	var wrongs: Array = []
	for _t in 100:
		var v := right + rng.randi_range(-k + 1, k - 1)
		if v % k != 0 and v > 0 and not wrongs.has(str(v)):
			wrongs.append(str(v))
		if wrongs.size() == 3:
			break
	var ex := K.choice(rng, "Which number is a multiple of %d?" % k, str(right), wrongs,
		"Count in %ds, or check which one divides by %d with nothing left over." % [k, k],
		"%d × %d = %d." % [k, int(right / float(k)), right])
	ex.data = {"k": k, "right": right}
	return ex


static func prime_composite(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(2, [0, 30, 60, 100][level])
	var prime := _factors(n).size() == 2
	var fs := _factors(n)
	var ex := K.choice(rng, "Is %d prime or composite?" % n, "prime" if prime else "composite",
		["composite" if prime else "prime"], "A prime number has exactly two factors: 1 and itself.",
		("%d has only 1 and %d as factors, so it is prime." % [n, n]) if prime else ("%d has the factors %s, so it is composite." % [
			n, ", ".join(fs.map(func(x: int) -> String: return str(x)))]))
	ex.data = {"n": n}
	return ex


static func factor_pairs_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var options: Array[int] = [24, 30, 36, 40, 48, 60, 64, 72, 100]
	if level < 3:
		options = [6, 8, 10, 12, 15, 16, 18, 20]
	var n: int = options[rng.randi_range(0, options.size() - 1)]
	var pairs: Array[String] = []
	for f in _factors(n):
		if f * f <= n:
			pairs.append("%d × %d" % [f, int(n / float(f))])
	var ex := K.number("How many factor pairs does %d have?" % n, pairs.size(), "Start with 1 × %d, then try 2, 3, 4… until the pairs meet." % n,
		"%s: %d pairs." % [", ".join(pairs), pairs.size()])
	ex.data = {"n": n}
	return ex


## "Build a rectangle with 12 blocks."
static func rectangle_build(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n: int = [6, 8, 10, 12, 15, 16, 18, 20][rng.randi_range(0, 7)] if level < 3 else [12, 16, 18, 20, 24][rng.randi_range(0, 4)]
	var goal := {"kind": "rectangle", "area": n}
	var prompt := "Build a rectangle with %d blocks." % n
	if level >= 2:
		goal.min_side = 2
		prompt = "Build a rectangle with %d blocks. Make it at least 2 blocks tall and 2 wide." % n
	var pairs: Array[String] = []
	for f in _factors(n):
		if f * f <= n and (level < 2 or f >= 2):
			pairs.append("%d by %d" % [f, int(n / float(f))])
	var ex := K.build(prompt, {"cols": 10, "rows": 5, "block": BlockIds.PLANKS, "given": [], "view": "wall"}, goal,
		"A rectangle's rows are all the same length: try a factor of %d for the height." % n,
		"%d blocks make these rectangles: %s." % [n, ", ".join(pairs)])
	ex.data = {"n": n}
	return ex


# --- Unit 8: patterns and rules (4.OA.5) ---------------------------------------------------------------------------

static func next_term(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var terms: Array[int] = []
	var rule := ""
	var start := rng.randi_range(1, 20)
	var step := rng.randi_range(2, 12)
	if level == 2 and rng.randf() < 0.5:
		var k := rng.randi_range(2, 3)
		start = rng.randi_range(1, 5)
		for i in 5:
			terms.append(start * int(pow(k, i)))
		rule = "multiply by %d" % k
	elif level == 2:
		start = rng.randi_range(60, 99)
		for i in 5:
			terms.append(start - i * step)
		rule = "subtract %d" % step
	else:
		for i in 5:
			terms.append(start + i * step)
		rule = "add %d" % step
	if level == 3:
		var nth := rng.randi_range(8, 12)
		var value := start + (nth - 1) * step
		var ex3 := K.number("The rule is \"start at %d and add %d\". What is the %s number?" % [start, step, _ordinal(nth)], value,
			"The %s number is %d plus %d more steps of %d." % [_ordinal(nth), start, nth - 1, step],
			"%d + %d × %d = %d" % [start, nth - 1, step, value])
		ex3.data = {"start": start, "step": step, "nth": nth}
		return ex3
	var shown: Array[String] = []
	for i in 4:
		shown.append(str(terms[i]))
	var ex := K.number("What comes next?  %s, ?" % ", ".join(shown), terms[4], "Find the rule: how does each number change?",
		"The rule is %s: the next number is %d." % [rule, terms[4]])
	ex.data = {"terms": terms}
	return ex


static func find_rule(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := rng.randi_range(2, 6)
	var k := rng.randi_range(2, 3)
	var step := rng.randi_range(2, 9)
	var terms: Array[String] = []
	var right := ""
	var wrongs: Array = []
	if level > 1 and rng.randf() < 0.5:
		for i in 4:
			terms.append(str(start * int(pow(k, i))))
		right = "multiply by %d" % k
		wrongs = ["add %d" % (start * k - start), "add %d" % start, "multiply by %d" % (k + 1)]
	else:
		for i in 4:
			terms.append(str(start + i * step))
		right = "add %d" % step
		wrongs = ["add %d" % (step + 1), "multiply by 2", "add %d" % start if start != step else "add %d" % (step + 2)]
	var ex := K.choice(rng, "What is the rule?  %s" % ", ".join(terms), right, wrongs,
		"Check the rule on every step, not just the first.",
		"The rule \"%s\" works for every step: %s." % [right, ", ".join(terms)])
	ex.data = {"terms": terms}
	return ex


## "Start at 1 and add 2 each time. Will every number be odd?"
static func odd_even_pattern(rng: RandomNumberGenerator, _level: int) -> Dictionary:
	var start := rng.randi_range(1, 20)
	var step := rng.randi_range(2, 9)
	var seq: Array[String] = []
	for i in 4:
		seq.append(str(start + i * step))
	var claims := ["every number will be odd", "every number will be even", "the numbers will take turns odd and even"]
	var truth := "the numbers will take turns odd and even" if step % 2 == 1 else (
		"every number will be odd" if start % 2 == 1 else "every number will be even")
	var claim: String = claims[rng.randi_range(0, 2)]
	var ex := K.truefalse("Start at %d and add %d each time: %s… True or false: %s." % [start, step, ", ".join(seq), claim],
		claim == truth, "Adding an even number keeps odd odd and even even. Adding an odd number swaps them.",
		"%d is %s and %d is %s, so %s." % [start, "odd" if start % 2 == 1 else "even", step, "odd" if step % 2 == 1 else "even", truth])
	ex.data = {"start": start, "step": step}
	return ex


## Growing towers: "How many blocks will the next tower have?"
static func tower_pattern(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start := rng.randi_range(1, 3)
	var step := rng.randi_range(1, 3)
	var heights: Array[int] = []
	for i in 3:
		heights.append(start + i * step)
	var ask := 4 if level < 3 else rng.randi_range(6, 9)
	var value := start + (ask - 1) * step
	var ex := K.number("Each tower grows by the same number of blocks. How many blocks will tower %d have?" % ask, value,
		"How many blocks are added each time? Keep adding them.",
		"The towers grow by %d: tower %d has %d + %d × %d = %d." % [step, ask, start, ask - 1, step, value],
		{"kind": "towers", "heights": heights, "missing": ask == 4})
	ex.data = {"start": start, "step": step, "ask": ask}
	return ex


# --- Helpers -------------------------------------------------------------------------------------------------------

## A number with `digits` digits and a zero or two inside (the harder places to read).
static func _with_some_zeros(rng: RandomNumberGenerator, digits: int) -> int:
	var s := str(K.with_digits(rng, digits))
	for _i in rng.randi_range(0, 2):
		var p := rng.randi_range(1, digits - 1)
		s = s.substr(0, p) + "0" + s.substr(p + 1)
	return int(s)


## 47305 -> ["40,000", "7,000", "300", "5"]
static func _parts(n: int) -> Array[String]:
	var out: Array[String] = []
	var s := str(n)
	for i in s.length():
		if s[i] != "0":
			out.append(K.fmt(int(s[i]) * K.pow10(s.length() - 1 - i)))
	return out


## Numbers that are easy to mix up with n (digits swapped or a place missed), as text.
static func _digit_mixups(rng: RandomNumberGenerator, n: int, count: int) -> Array:
	var out: Array = []
	var s := str(n)
	var tries := 0
	while out.size() < count and tries < 100:
		tries += 1
		var t := s
		var i := rng.randi_range(0, s.length() - 2)
		match rng.randi_range(0, 2):
			0:
				t = s.substr(0, i) + s[i + 1] + s[i] + s.substr(i + 2)
			1:
				t = s.substr(0, i + 1) + "0" + s.substr(i + 1, s.length() - i - 2)
			_:
				t = str(n + K.pow10(rng.randi_range(0, s.length() - 1)))
		var v := int(t)
		if t != s and not t.begins_with("0") and v != n and not out.has(K.fmt(v)):
			out.append(K.fmt(v))
	return out


static func _factors(n: int) -> Array:
	var out: Array = []
	for f in range(1, n + 1):
		if n % f == 0:
			out.append(f)
	return out


static func _two_names(rng: RandomNumberGenerator) -> Array[String]:
	var list: Array[String] = NAMES.duplicate()
	K.shuffle(rng, list)
	return list.slice(0, 2)


static func _three_names(rng: RandomNumberGenerator) -> Array[String]:
	var list: Array[String] = NAMES.duplicate()
	K.shuffle(rng, list)
	return list.slice(0, 3)


static func _ordinal(n: int) -> String:
	var words := {1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth", 7: "seventh", 8: "eighth",
		9: "ninth", 10: "tenth", 11: "eleventh", 12: "twelfth"}
	return words.get(n, "%dth" % n)
