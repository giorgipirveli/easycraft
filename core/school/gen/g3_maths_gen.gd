class_name G3MathsGen
extends RefCounted
## Owner #70 (grade 3 maths, units 1-8 of the outline: numbers to 10,000 and Roman numerals, adding and taking away,
## equal groups and arrays, sharing and grouping, times tables to 12 × 12, multiplying made easier, multiplying and
## dividing by one digit, two-step problems with bar models; Common Core 3.NBT, 3.OA with England Year 4 and Singapore
## P3). Each is `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary` (SchoolGen "g3m.<name>"),
## seeded, level 1-3 (easier to harder), returning an exercise with a hint about the strategy, a worked answer and `data`
## (its inputs, for tests). Whole numbers stay at most 10,000. Helpers start with "_".
## Fractions, money, time, measures, shapes and graphs: G3MeasureGen ("g3g").

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]
const PLACES: Array[String] = ["ones", "tens", "hundreds", "thousands"]
const ROMAN: Array = [[100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
## Containers and what is in them, [one, many].
const BOXES: Array = [["box", "boxes"], ["bag", "bags"], ["basket", "baskets"], ["chest", "chests"], ["crate", "crates"]]
const THINGS: Array = [["apple", "apples"], ["egg", "eggs"], ["gem", "gems"], ["shell", "shells"], ["carrot", "carrots"],
	["seed", "seeds"], ["lantern", "lanterns"], ["cookie", "cookies"]]


# --- Unit 1: numbers to 10,000 (3.NBT.1; UK Y4 place value and Roman numerals) ------------------------------------------

## "What is the value of the 7 in 4,735?"
static func place_value(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits := 3 if level == 1 else 4
	var n := 0
	var pos := 0
	for _try in 200:
		n = K.with_digits(rng, digits)
		if level == 3:   # a zero in the number makes the places harder to see
			var s := str(n)
			var z := rng.randi_range(1, digits - 1)
			n = int(s.left(z) + "0" + s.substr(z + 1))
		pos = rng.randi_range(0, digits - 1)
		var t := str(n)
		if t[pos] != "0" and t.count(t[pos]) == 1:
			break
	var d := int(str(n)[pos])
	var place := digits - 1 - pos
	var wrongs: Array = []
	for k in 4:
		if k != place:
			wrongs.append(K.fmt(d * K.pow10(k)))
	var ex := K.choice(rng, "What is the value of the %d in %s?" % [d, K.fmt(n)], K.fmt(d * K.pow10(place)), wrongs,
		"Count the places from the right: ones, tens, hundreds, thousands. Which place is the %d in?" % d,
		"The %d is in the %s place, so it is worth %s." % [d, PLACES[place], K.fmt(d * K.pow10(place))])
	ex.data = {"n": n, "place": place}
	return ex


## Base-ten blocks: "What number do the blocks show?" (level 3: "… 100 more than the blocks show?")
static func blocks_number(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t := rng.randi_range(1, 3 if level == 2 else 4) if level > 1 else 0
	var h := rng.randi_range(0 if level > 1 else 1, 6 if level > 1 else 9)
	var te := rng.randi_range(0, 9)
	var o := rng.randi_range(0, 9)
	if level > 1 and rng.randf() < 0.35:
		te = 0
	var n := t * 1000 + h * 100 + te * 10 + o
	var pic := {"kind": "blocks", "thousands": t, "hundreds": h, "tens": te, "ones": o}
	var read := "%s, %s, %s and %s make %s." % [_n(t, "thousand", "thousands"), _n(h, "hundred", "hundreds"),
		_n(te, "ten", "tens"), _n(o, "one", "ones"), K.fmt(n)]
	if t == 0:
		read = "%s, %s and %s make %s." % [_n(h, "hundred", "hundreds"), _n(te, "ten", "tens"), _n(o, "one", "ones"), K.fmt(n)]
	if level < 3:
		var ex := K.number("What number do the blocks show?", n,
			"A big cube is 1,000, a flat is 100, a rod is 10 and a small cube is 1. Count each kind.", read, pic)
		ex.data = {"n": n, "add": 0}
		return ex
	var step: int = [1, 10, 100, 1000][rng.randi_range(0, 3)]
	var add := step if rng.randf() < 0.6 else -step
	var ex3 := K.number("What number is %s %s than the blocks show?" % [K.fmt(step), "more" if add > 0 else "less"], n + add,
		"Read the blocks first. Then change only the %s: one more or one less." % PLACES[str(step).length() - 1],
		"The blocks show %s. %s %s %s = %s." % [K.fmt(n), K.fmt(n), "+" if add > 0 else "−", K.fmt(step), K.fmt(n + add)], pic)
	ex3.data = {"n": n, "add": add}
	return ex3


## "4,000 + 700 + 30 + 5 = ?" (level 3: a zero place, the parts in any order)
static func expanded(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits := 3 if level == 1 else 4
	var n := K.with_digits(rng, digits)
	if level == 3:
		var s := str(n)
		var z := rng.randi_range(1, digits - 2)
		n = int(s.left(z) + "0" + s.substr(z + 1))
	var parts := _parts(n)
	var shown := parts.duplicate()
	if level == 3:
		for _i in 4:
			K.shuffle(rng, shown)
			if shown != parts:
				break
	var ex := K.number("%s = ?" % " + ".join(shown), n, "Each part fills one place. Start with the biggest part: the thousands.",
		"%s = %s" % [" + ".join(parts), K.fmt(n)])
	ex.data = {"n": n}
	return ex


## "Which sign makes this true?  4,735 ? 4,753"
static func compare(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits := 3 if level == 1 else 4
	var a := K.with_digits(rng, digits)
	var b := a
	if rng.randf() >= 0.15:
		var place := digits - 1 - rng.randi_range(0, 1)   # level 1: the hundreds or tens differ
		if level == 2:
			place = rng.randi_range(1, 2)
		elif level == 3:
			place = rng.randi_range(0, 1)
		var p := K.pow10(place)
		var delta := rng.randi_range(1, 8) * p * (1 if rng.randf() < 0.5 else -1)
		b = clampi(a + delta, K.pow10(digits - 1), K.pow10(digits) - 1)
		if b == a:
			b = a + p if a + p < K.pow10(digits) else a - p
	var sign := "=" if a == b else (">" if a > b else "<")
	var ex := K.choice(rng, "Which sign makes this true?  %s ? %s" % [K.fmt(a), K.fmt(b)], sign,
		[">", "<", "="].filter(func(x: String) -> bool: return x != sign),
		"Line up the places. Compare from the left: the first place where the digits are different decides.",
		"%s %s %s. The sign opens towards the bigger number." % [K.fmt(a), sign, K.fmt(b)])
	ex.data = {"a": a, "b": b}
	return ex


## "Put these numbers in order, smallest first." (level 3: greatest first)
static func order_numbers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var digits := 3 if level == 1 else 4
	var base := K.with_digits(rng, digits)
	var nums: Array[int] = [base]
	var tries := 0
	while nums.size() < 4 and tries < 200:
		tries += 1
		var place := rng.randi_range(0 if level == 3 else 1, digits - 2)
		var v := clampi(base + rng.randi_range(-9, 9) * K.pow10(place), K.pow10(digits - 1), K.pow10(digits) - 1)
		if not nums.has(v):
			nums.append(v)
	nums.sort()
	var greatest := level == 3
	if greatest:
		nums.reverse()
	var texts: Array = []
	for v in nums:
		texts.append(K.fmt(v))
	var ex := K.order(rng, "Put these numbers in order, %s first." % ("greatest" if greatest else "smallest"), texts,
		"Compare the thousands, then the hundreds, then the tens, then the ones.",
		"%s first: %s." % ["Greatest" if greatest else "Smallest", ", ".join(texts)])
	ex.data = {"nums": nums, "greatest_first": greatest}
	return ex


## "Round 4,735 to the nearest hundred." (with its number line)
static func round_number(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var to := 10
	var n := rng.randi_range(11, 499)
	if level == 2:
		to = [10, 100][rng.randi_range(0, 1)]
		n = rng.randi_range(101, 999) if to == 100 else rng.randi_range(101, 2999)
	elif level == 3:
		to = [100, 1000][rng.randi_range(0, 1)]
		n = rng.randi_range(1001, 9899)
	while n % to == 0:
		n += 1
	var lower := n - n % to
	var rounded := lower + to if n % to >= int(to / 2.0) else lower
	var words := {10: "ten", 100: "hundred", 1000: "thousand"}
	var next_place := PLACES[str(to).length() - 2]
	var line := {"kind": "number_line", "from": str(lower), "to": str(lower + to), "step": str(int(to / 10.0)), "dot": str(n),
		"labels": "ends"}
	var ex := K.number("Round %s to the nearest %s." % [K.fmt(n), words[to]], rounded,
		"Which two %ss is it between? Look at the %s digit: 5 or more rounds up, 4 or less rounds down." % [words[to], next_place],
		"%s is between %s and %s. It is nearer to %s, so it rounds to %s." % [K.fmt(n), K.fmt(lower), K.fmt(lower + to),
			K.fmt(rounded), K.fmt(rounded)], line)
	ex.data = {"n": n, "to": to}
	return ex


## "The Roman numeral XLVII is which number?" or "Which is 47 in Roman numerals?"
static func roman(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var top: int = [20, 50, 100][level - 1]
	var n := rng.randi_range(1 if level == 1 else 11, top)
	var r := _roman(n)
	var hint := "I = 1, V = 5, X = 10, L = 50, C = 100. A smaller one before a bigger one is taken away: IV = 4, XL = 40."
	var sum := "%s = %s = %d" % [r, " + ".join(_roman_values(n)), n]
	if rng.randf() < 0.5:
		var ex := K.number("The Roman numeral %s is which number?" % r, n, hint, sum + ".")
		ex.data = {"n": n, "to_roman": false}
		return ex
	var wrongs: Array = [_roman(n + 1), _additive(n)]
	if n > 1:
		wrongs.append(_roman(n - 1))
	wrongs.append(_roman(n + 10) if n + 10 <= 100 else _roman(n - 10))
	var ex2 := K.choice(rng, "Which is %d in Roman numerals?" % n, r, wrongs, hint, sum + ".")
	ex2.data = {"n": n, "to_roman": true}
	return ex2


# --- Unit 2: add and subtract to 10,000 (3.NBT.2; UK Y4) ------------------------------------------------------------------

## Number bonds: "? + 37 = 100", "650 + ? = 1,000", "3,700 + ? = 10,000"
static func bond(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var total := 100
	var a := rng.randi_range(11, 89)
	if level == 2:
		total = 1000
		a = rng.randi_range(11, 89) * 10
	elif level == 3:
		if rng.randf() < 0.5:
			total = 1000
			a = rng.randi_range(101, 899)
		else:
			total = 10000
			a = rng.randi_range(11, 89) * 100
	var prompt := ("%s + ? = %s" if rng.randf() < 0.5 else "? + %s = %s") % [K.fmt(a), K.fmt(total)]
	var ex := K.number(prompt, total - a, "Count on from %s: first to the next ten or hundred, then on to %s." % [K.fmt(a), K.fmt(total)],
		"%s + %s = %s" % [K.fmt(a), K.fmt(total - a), K.fmt(total)])
	ex.data = {"a": a, "total": total}
	return ex


## Friendly numbers: "457 + 199 = ?" (add 200, take away 1)
static func mental(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var nears: Array = [[9, 10], [19, 20], [29, 30], [39, 40], [11, 10], [21, 20]]
	var a := rng.randi_range(41, 89)
	if level == 2:
		nears = [[99, 100], [199, 200], [299, 300], [98, 100], [101, 100], [201, 200]]
		a = rng.randi_range(310, 790)
	elif level == 3:
		nears = [[999, 1000], [1999, 2000], [998, 1000], [2999, 3000], [1001, 1000], [2001, 2000]]
		a = rng.randi_range(3100, 6900)
	var pair: Array = nears[rng.randi_range(0, nears.size() - 1)]
	var b: int = pair[0]
	var friend: int = pair[1]
	var add := rng.randf() < 0.5
	var answer := a + b if add else a - b
	var fix := absi(friend - b)
	var more := b < friend   # b is the friendly number minus fix
	var hint := "%s is %s %s %d. %s %s, then %s %d." % [K.fmt(b), K.fmt(friend), "−" if more else "+", fix,
		"Add" if add else "Take away", K.fmt(friend), ("take away" if more else "add") if add else ("add" if more else "take away"), fix]
	var first := a + friend if add else a - friend
	var ex := K.number("%s %s %s = ?" % [K.fmt(a), "+" if add else "−", K.fmt(b)], answer, hint,
		"%s %s %s = %s, then %s %s %d = %s." % [K.fmt(a), "+" if add else "−", K.fmt(friend), K.fmt(first), K.fmt(first),
			"+" if answer > first else "−", fix, K.fmt(answer)])
	ex.data = {"a": a, "b": b, "add": add}
	return ex


## Column adding with carrying (the column picture): "2,456 + 1,378 = ?"
static func column_add(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	for _try in 200:
		if level == 1:
			a = rng.randi_range(100, 499)
			b = rng.randi_range(100, 499)
		elif level == 2:
			a = rng.randi_range(1000, 5999)
			b = rng.randi_range(100, 999)
		else:
			a = rng.randi_range(1000, 4999)
			b = rng.randi_range(1000, 4999)
		if _carries(a, b) >= (2 if level == 3 else 1):
			break
	var ex := K.number("%s + %s = ?" % [K.fmt(a), K.fmt(b)], a + b,
		"Line up the places. Add the ones first. When a place makes 10 or more, carry 1 to the next place.",
		_add_steps(a, b), {"kind": "column", "rows": [K.fmt(a), "+ " + K.fmt(b)], "lines": [1]})
	ex.data = {"a": a, "b": b}
	return ex


## Column taking away with exchanging (level 3 across zeros): "4,003 − 1,258 = ?"
static func column_subtract(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	for _try in 200:
		if level == 1:
			a = rng.randi_range(300, 999)
			b = rng.randi_range(100, a - 100)
		elif level == 2:
			a = rng.randi_range(1200, 9999)
			b = rng.randi_range(100, 999)
		else:
			a = rng.randi_range(2, 9) * 1000 + [0, 0, 3, 20, 5, 40][rng.randi_range(0, 5)]
			b = rng.randi_range(1100, a - 100)
		if _exchanges(a, b) >= (2 if level == 3 else 1):
			break
	var ex := K.number("%s − %s = ?" % [K.fmt(a), K.fmt(b)], a - b,
		"Start with the ones. When the top digit is smaller, exchange 1 from the next place: 1 ten is 10 ones.",
		"%s − %s = %s. Check with the inverse: %s + %s = %s." % [K.fmt(a), K.fmt(b), K.fmt(a - b), K.fmt(a - b), K.fmt(b), K.fmt(a)],
		{"kind": "column", "rows": [K.fmt(a), "− " + K.fmt(b)], "lines": [1]})
	ex.data = {"a": a, "b": b}
	return ex


## "Bram says 732 − 285 = 447. Check with an adding: is Bram right?"
static func check_inverse(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var a := rng.randi_range(300, 999) if level == 1 else rng.randi_range(1000, 9999)
	var b := rng.randi_range(100, mini(a - 50, 999 if level < 3 else 9999))
	var add := level > 1 and rng.randf() < 0.4
	var right := a + b if add else a - b
	if add and right > 10000:
		a -= right - 10000
		right = a + b
	var claimed := right
	if rng.randf() < 0.5:
		claimed = right + [10, -10, 100, -100, 1, -1][rng.randi_range(0, 5)]
		if claimed < 0:
			claimed = right + 100
	var ok := claimed == right
	var ex: Dictionary
	if add:
		ex = K.truefalse("%s says %s + %s = %s. Check with a take-away. Is %s right?" % [who, K.fmt(a), K.fmt(b), K.fmt(claimed), who],
			ok, "Take %s away from the answer. You should get back to %s." % [K.fmt(b), K.fmt(a)],
			("%s − %s = %s, so yes." % [K.fmt(claimed), K.fmt(b), K.fmt(a)]) if ok else
				("%s − %s = %s, not %s. The answer is %s." % [K.fmt(claimed), K.fmt(b), K.fmt(claimed - b), K.fmt(a), K.fmt(right)]))
	else:
		ex = K.truefalse("%s says %s − %s = %s. Check with an adding. Is %s right?" % [who, K.fmt(a), K.fmt(b), K.fmt(claimed), who],
			ok, "Add the answer and %s. You should get back to %s." % [K.fmt(b), K.fmt(a)],
			("%s + %s = %s, so yes." % [K.fmt(claimed), K.fmt(b), K.fmt(a)]) if ok else
				("%s + %s = %s, not %s. The answer is %s." % [K.fmt(claimed), K.fmt(b), K.fmt(claimed + b), K.fmt(a), K.fmt(right)]))
	ex.data = {"a": a, "b": b, "add": add, "claimed": claimed}
	return ex


## One-step adding and taking-away stories.
static func add_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var a := rng.randi_range(300, 700)
	var b := rng.randi_range(100, 290)
	if level == 2:
		a = rng.randi_range(1200, 6000)
		b = rng.randi_range(100, 999)
	elif level == 3:
		a = rng.randi_range(2000, 6000)
		b = rng.randi_range(1100, 3900)
	var kind := rng.randi_range(0, 4)
	if kind >= 2 and b > a:
		var t := a
		a = b
		b = t
	var prompt := ""
	var add := kind < 2
	match kind:
		0:
			prompt = "%s built with %s blocks on Monday and %s blocks on Tuesday. How many blocks is that in all?" % [who, K.fmt(a), K.fmt(b)]
		1:
			prompt = "A farm grew %s carrots and %s potatoes. How many vegetables is that altogether?" % [K.fmt(a), K.fmt(b)]
		2:
			prompt = "The market had %s lanterns and sold %s. How many lanterns are left?" % [K.fmt(a), K.fmt(b)]
		3:
			prompt = "%s needs %s blocks for a castle and has %s. How many more blocks are needed?" % [who, K.fmt(a), K.fmt(b)]
		_:
			prompt = "A tower is %s blocks tall and a wall is %s blocks tall. How much taller is the tower?" % [K.fmt(a), K.fmt(b)]
	var answer := a + b if add else a - b
	var ex := K.number(prompt, answer,
		"Do you put together (add) or find what is left or the difference (take away)?" if add else
			"Find what is left or the difference: take away. Check with an adding.",
		"%s %s %s = %s." % [K.fmt(a), "+" if add else "−", K.fmt(b), K.fmt(answer)])
	ex.data = {"a": a, "b": b, "add": add}
	return ex


# --- Unit 3: equal groups and arrays (3.OA.1, 3.OA.3) ------------------------------------------------------------------------

## "There are 4 boxes with 6 blocks in each. How many blocks are there?" (the groups picture)
static func groups_total(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := rng.randi_range(2, [4, 6, 8][level - 1])
	var e := rng.randi_range(2, [5, 8, 10][level - 1])
	var box: Array = BOXES[rng.randi_range(0, BOXES.size() - 1)]
	var ex := K.number("There are %d %s with %d blocks in each. How many blocks are there?" % [g, box[1], e], g * e,
		"%d groups of %d is %d × %d. Count in %ds, or use a times fact you know." % [g, e, g, e, e],
		"%d groups of %d: %d × %d = %d blocks." % [g, e, g, e, g * e], {"kind": "groups", "groups": g, "each": e})
	ex.data = {"groups": g, "each": e}
	return ex


## "Which multiplication matches the picture?" (equal groups, or at level 3 an array)
static func groups_sentence(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := rng.randi_range(2, 6)
	var e := rng.randi_range(2, 8)
	while e == g:
		e = rng.randi_range(2, 8)
	var array := level == 3
	var pic := {"kind": "array", "rows": g, "cols": e} if array else {"kind": "groups", "groups": g, "each": e}
	var right := "%d × %d" % [g, e]
	var wrongs: Array = ["%d + %d" % [g, e], "%d × %d" % [g, e + 1], "%d × %d" % [g + 1, e]]
	if level > 1:
		wrongs.append("%d + %d" % [g, g])
	var ex := K.choice(rng, "Which multiplication matches the %s?" % ("array" if array else "picture"), right, wrongs,
		"How many %s? How many in each? The number of %s comes first." % (["rows", "rows"] if array else ["groups", "groups"]),
		"%d %s of %d: %d × %d = %d." % [g, "rows" if array else "groups", e, g, e, g * e], pic)
	ex.data = {"groups": g, "each": e}
	return ex


## "Build an array: 3 rows of 4 blocks." on the block board (level 3: "… 24 blocks in 4 equal rows")
static func array_build(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows := rng.randi_range(2, [3, 5, 6][level - 1])
	var cols := rng.randi_range(2, [5, 8, 9][level - 1])
	var prompt := "Build an array of %d rows with %d blocks in each row." % [rows, cols]
	if level == 2:
		prompt = "Build %d × %d as an array: %d rows of %d." % [rows, cols, rows, cols]
	elif level == 3:
		prompt = "Build %d blocks in %d equal rows, as an array." % [rows * cols, rows]
	var ex := K.build(prompt, {"cols": 10, "rows": 6, "block": BlockIds.BRICK, "given": [], "view": "wall"},
		{"kind": "array", "rows": rows, "cols": cols},
		"Make the rows one on top of another, each with the same number of blocks." if level < 3 else
			"Which number times %d makes %d? That many blocks go in each row." % [rows, rows * cols],
		"%d rows of %d blocks: %d × %d = %d." % [rows, cols, rows, cols, rows * cols])
	ex.data = {"rows": rows, "cols": cols}
	return ex


## "6 + 6 + 6 + 6 = ? × 6"
static func repeated_add(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var e := rng.randi_range(2, [5, 9, 12][level - 1])
	var n := rng.randi_range(2, [4, 6, 8][level - 1])
	var sum := " + ".join(PackedStringArray(_repeat(str(e), n)))
	var ask := rng.randi_range(0, 2) if level > 1 else rng.randi_range(0, 1)
	var prompt := ""
	var answer := 0
	match ask:
		0:
			prompt = "%s = ? × %d" % [sum, e]
			answer = n
		1:
			prompt = "%s = %d × ?" % [sum, n]
			answer = e
		_:
			prompt = "%s = ?" % sum
			answer = n * e
	var ex := K.number(prompt, answer, "Count how many times %d is added. That many groups of %d." % [e, e],
		"%d is added %d times: %s = %d × %d = %d." % [e, n, sum, n, e, n * e])
	ex.data = {"n": n, "each": e, "ask": ask}
	return ex


## Equal-groups stories: "Tilly has 5 bags with 8 apples in each. How many apples?"
static func groups_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var g := rng.randi_range(2, [5, 9, 12][level - 1])
	var e := rng.randi_range(2, [5, 9, 12][level - 1])
	var box: Array = BOXES[rng.randi_range(0, BOXES.size() - 1)]
	var thing: Array = THINGS[rng.randi_range(0, THINGS.size() - 1)]
	var kind := rng.randi_range(0, 2)
	var prompt := ""
	match kind:
		0:
			prompt = "%s has %d %s with %d %s in each. How many %s does %s have?" % [who, g, box[1], e, thing[1], thing[1], who]
		1:
			prompt = "A farm has %d rows of carrots with %d carrots in each row. How many carrots are there?" % [g, e]
		_:
			prompt = "%d buddies each find %d %s. How many %s do they find in all?" % [g, e, thing[1], thing[1]]
	var ex := K.number(prompt, g * e, "How many groups are there, and how many in each group? Then multiply.",
		"%d groups of %d: %d × %d = %d." % [g, e, g, e, g * e])
	ex.data = {"groups": g, "each": e}
	return ex


# --- Unit 4: sharing and grouping (3.OA.2, 3.OA.4, 3.OA.6) --------------------------------------------------------------

## Sharing: "Share 24 blocks equally into 4 boxes. How many blocks go in each box?" (the empty boxes)
static func share(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := rng.randi_range(2, [5, 8, 10][level - 1])
	var e := rng.randi_range(2, [5, 8, 10][level - 1])
	var total := g * e
	var box: Array = BOXES[rng.randi_range(0, BOXES.size() - 1)]
	var ex := K.number("Share %d blocks equally into %d %s. How many blocks go in each %s?" % [total, g, box[1], box[0]], e,
		"Give one block to each %s in turn until none are left. Or think: %d × ? = %d." % [box[0], g, total],
		"%d ÷ %d = %d, because %d × %d = %d." % [total, g, e, g, e, total], {"kind": "groups", "groups": g, "each": 0})
	ex.data = {"total": total, "groups": g}
	return ex


## Grouping: "How many groups of 6 can you make from 30 blocks?"
static func grouping(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var size := rng.randi_range(2, [5, 9, 12][level - 1])
	var n := rng.randi_range(2, [5, 9, 12][level - 1])
	var total := size * n
	var thing: Array = THINGS[rng.randi_range(0, THINGS.size() - 1)]
	var ex := K.number("%d %s are put in groups of %d. How many groups are there?" % [total, thing[1], size], n,
		"Count in %ds up to %d, or think: ? × %d = %d." % [size, total, size, total],
		"%d ÷ %d = %d groups, because %d × %d = %d." % [total, size, n, n, size, total])
	ex.data = {"total": total, "size": size}
	return ex


## "Share 12 blocks into 3 equal rows. Build them." on the block board
static func divide_build(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows := rng.randi_range(2, [3, 5, 6][level - 1])
	var cols := rng.randi_range(2, [4, 6, 9][level - 1])
	var total := rows * cols
	var ex := K.build("Share %d blocks into %d equal rows. Build them." % [total, rows],
		{"cols": 10, "rows": 6, "block": BlockIds.PLANKS, "given": [], "view": "wall"}, {"kind": "array", "rows": rows, "cols": cols},
		"Put one block in each row, again and again, until you have used %d. Or think: %d × ? = %d." % [total, rows, total],
		"%d ÷ %d = %d: %d rows of %d blocks." % [total, rows, cols, rows, cols])
	ex.data = {"total": total, "rows": rows}
	return ex


## The unknown number: "8 × ? = 48", "? × 7 = 42", "56 ÷ ? = 8", "? ÷ 6 = 9"
static func unknown_factor(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var tables: Array = [[2, 5, 10], [3, 4, 6], [7, 8, 9]][level - 1]
	var a: int = tables[rng.randi_range(0, tables.size() - 1)]
	var b := rng.randi_range(2, 10)
	var c := a * b
	var form := rng.randi_range(0, 1) if level == 1 else rng.randi_range(0, 3)
	var prompt := ""
	var answer := 0
	match form:
		0:
			prompt = "%d × ? = %d" % [a, c]
			answer = b
		1:
			prompt = "? × %d = %d" % [a, c]
			answer = b
		2:
			prompt = "%d ÷ ? = %d" % [c, a]
			answer = b
		_:
			prompt = "? ÷ %d = %d" % [a, b]
			answer = c
	var hint := "Count in %ds up to %d, or think of the %d times table." % [a, c, a]
	var explain := "%d × %d = %d, so the missing number is %d." % [a, b, c, answer]
	if form == 2:
		hint = "%d times what makes %d?" % [a, c]
		explain = "%d × %d = %d, so %d ÷ %d = %d." % [a, b, c, c, b, a]
	elif form == 3:
		hint = "Undo the division: multiply %d × %d." % [b, a]
		explain = "%d × %d = %d, so %d ÷ %d = %d." % [b, a, c, c, a, b]
	var ex := K.number(prompt, answer, hint, explain)
	ex.data = {"a": a, "b": b, "form": form}
	return ex


## "Which division goes with 6 × 7 = 42?" (level 3: which multiplication goes with a division)
static func fact_family(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, [5, 9, 12][level - 1])
	var b := rng.randi_range(2, [5, 9, 12][level - 1])
	while b == a:
		b = rng.randi_range(2, [5, 9, 12][level - 1])
	var c := a * b
	var ex: Dictionary
	if level < 3:
		ex = K.choice(rng, "Which division goes with %d × %d = %d?" % [a, b, c], "%d ÷ %d = %d" % [c, b, a],
			["%d ÷ %d = %d" % [a, b, c], "%d ÷ %d = %d" % [c, b, b], "%d − %d = %d" % [c, b, a]],
			"A division undoes a times: start with the biggest number, %d." % c,
			"%d groups of %d make %d, so %d shared into groups of %d gives %d: %d ÷ %d = %d." % [a, b, c, c, b, a, c, b, a])
	else:
		ex = K.choice(rng, "Which multiplication goes with %d ÷ %d = %d?" % [c, b, a], "%d × %d = %d" % [a, b, c],
			["%d × %d = %d" % [c, b, a], "%d × %d = %d" % [a, a, c], "%d + %d = %d" % [a, b, c]],
			"Multiply the answer by the number you divided by. Do you get back to %d?" % c,
			"%d ÷ %d = %d because %d × %d = %d." % [c, b, a, a, b, c])
	ex.data = {"a": a, "b": b, "c": c, "divide": level < 3}
	return ex


## Sharing and grouping stories.
static func divide_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var by := rng.randi_range(2, [5, 9, 10][level - 1])
	var q := rng.randi_range(2, [5, 9, 12][level - 1])
	var total := by * q
	var thing: Array = THINGS[rng.randi_range(0, THINGS.size() - 1)]
	var grouping := rng.randf() < 0.5
	var prompt := ""
	if grouping:
		prompt = "%d buddies go on a boat ride. Each boat holds %d buddies. How many boats are filled?" % [total, by]
		if rng.randf() < 0.5:
			prompt = "%s packs %d %s into bags of %d. How many bags does %s fill?" % [who, total, thing[1], by, who]
	else:
		prompt = "%s shares %d %s equally among %d friends. How many %s does each friend get?" % [who, total, thing[1], by, thing[1]]
	var ex := K.number(prompt, q, ("Grouping: how many groups of %d fit in %d?" if grouping else
		"Sharing: split %d into %d equal groups.") % ([by, total] if grouping else [total, by]),
		"%d ÷ %d = %d, because %d × %d = %d." % [total, by, q, q, by, total])
	ex.data = {"total": total, "by": by, "grouping": grouping}
	return ex


# --- Unit 5: times tables to 12 × 12 (3.OA.7, 3.OA.9; UK Y4) ---------------------------------------------------------------

## "7 × 8 = ?"
static func times_fact(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := _table(rng, level)
	var b := rng.randi_range(1 if level == 1 else 2, 12)
	var swap := rng.randf() < 0.5
	var x := b if swap else a
	var y := a if swap else b
	var ex := K.number("%d × %d = ?" % [x, y], a * b, _times_hint(a, b), "%d × %d = %d" % [x, y, a * b])
	ex.data = {"a": a, "b": b}
	return ex


## "56 ÷ 8 = ?"
static func divide_fact(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := _table(rng, level)
	var b := rng.randi_range(1 if level == 1 else 2, 12)
	var ex := K.number("%d ÷ %d = ?" % [a * b, a], b, "Think of the %d times table: %d × ? = %d." % [a, a, a * b],
		"%d × %d = %d, so %d ÷ %d = %d." % [a, b, a * b, a * b, a, b])
	ex.data = {"a": a, "b": b}
	return ex


## A times grid with one number hidden: "Which number is hidden?"
static func grid_hidden(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows := 4
	var cols := 5
	var r0 := rng.randi_range(1, 4)
	var c0 := rng.randi_range(1, 4)
	if level == 2:
		r0 = rng.randi_range(5, 9)
		c0 = rng.randi_range(3, 8)
	elif level == 3:
		r0 = rng.randi_range(8, 9)
		c0 = rng.randi_range(7, 8)
	var r := r0 + rng.randi_range(0, rows - 1)
	var c := c0 + rng.randi_range(0, cols - 1)
	var ex := K.number("Which number is hidden in the times grid?", r * c,
		"Find its row number and its column number, then multiply. Or count on from its neighbour: each step adds %d." % r,
		"It is in row %d and column %d: %d × %d = %d." % [r, c, r, c, r * c],
		{"kind": "times_grid", "rows": rows, "cols": cols, "r0": r0, "c0": c0, "hide": [[r, c]]})
	ex.data = {"row": r, "col": c}
	return ex


## "Is 7 × 9 even or odd?"
static func even_odd(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, [5, 9, 12][level - 1])
	var b := rng.randi_range(2, [5, 9, 12][level - 1])
	if rng.randf() < 0.45:   # odd × odd as often as not (only 1 in 4 pairs is odd × odd)
		a = [3, 5, 7, 9, 11][rng.randi_range(0, [1, 3, 4][level - 1])]
		b = [3, 5, 7, 9, 11][rng.randi_range(0, [1, 3, 4][level - 1])]
	var even := (a * b) % 2 == 0
	var right := "even" if even else "odd"
	var why := "odd × odd is always odd" if not even else "a number times an even number is always even"
	var ex := K.choice(rng, "Is %d × %d even or odd?" % [a, b], right, ["odd" if even else "even"],
		"Is %d even or odd? Is %d? Only odd × odd makes an odd number." % [a, b],
		"%d × %d = %d, which is %s: %s." % [a, b, a * b, right, why])
	ex.data = {"a": a, "b": b}
	return ex


## "Which number is in the 6 times table?"
static func in_table(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t := _table(rng, level)
	var right := t * rng.randi_range(2, 12)
	var wrongs: Array = []
	var tries := 0
	while wrongs.size() < 3 and tries < 200:
		tries += 1
		var v := right + rng.randi_range(-t + 1, t - 1) + (rng.randi_range(-2, 2) * t)
		if v > 1 and v % t != 0 and not wrongs.has(v):
			wrongs.append(v)
	var texts: Array = []
	for w: int in wrongs:
		texts.append(str(w))
	var ex := K.choice(rng, "Which number is in the %d times table?" % t, str(right), texts,
		"Count in %ds, or check each one: which one is %d × something?" % [t, t],
		"%d = %d × %d. The others are not in the %d times table." % [right, t, int(right / float(t)), t])
	ex.data = {"table": t, "right": right, "wrongs": wrongs}
	return ex


## "What comes next? 7, 14, 21, 28, ?"
static func skip_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t := _table(rng, level)
	var start := rng.randi_range(1, 3 if level == 1 else 7)
	var shown: Array[String] = []
	for i in 4:
		shown.append(str(t * (start + i)))
	var down := level == 3 and rng.randf() < 0.5
	var answer := t * (start + 4)
	if down:
		shown.reverse()
		answer = t * (start - 1)
		if answer <= 0:
			down = false
			shown.reverse()
			answer = t * (start + 4)
	var ex := K.number("What comes next?  %s, ?" % ", ".join(shown), answer,
		"How much does it %s by each time? That is the rule." % ("go down" if down else "go up"),
		"The rule is %s %d each time: %s %s %d = %d." % ["take away" if down else "add", t, shown[3], "−" if down else "+", t, answer])
	ex.data = {"table": t, "start": start, "down": down}
	return ex


# --- Unit 6: multiplying made easier (3.OA.5) ---------------------------------------------------------------------------------

## Swapping: "6 × 4 = 4 × ?" or which sums and products can be swapped (true or false)
static func swap(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, [9, 12, 12][level - 1])
	var b := rng.randi_range(2, [9, 12, 12][level - 1])
	while b == a:
		b = rng.randi_range(2, 12)
	if level == 1:
		var ex := K.number("%d × %d = %d × ?" % [a, b, b], a, "Multiplying works in any order: the numbers can swap places.",
			"%d × %d = %d × %d = %d" % [a, b, b, a, a * b], {"kind": "array", "rows": mini(a, 12), "cols": mini(b, 12)})
		ex.data = {"a": a, "b": b, "op": "×"}
		return ex
	var ops: Array[String] = ["×", "+", "−", "÷"]
	var op := ops[rng.randi_range(0, 3)]
	var x := maxi(a, b)
	var y := mini(a, b)
	if op == "÷":
		x = a * b
		y = b
	var ok := op in ["×", "+"]
	var ex2 := K.truefalse("%d %s %d = %d %s %d" % [x, op, y, y, op, x], ok,
		"Adding and multiplying can swap their numbers. Can taking away and dividing?",
		("Yes: %d %s %d and %d %s %d both make %d." % [x, op, y, y, op, x, x * y if op == "×" else x + y]) if ok else
			("No: %d %s %d is not the same as %d %s %d. Only adding and multiplying can swap." % [x, op, y, y, op, x]))
	ex2.data = {"a": x, "b": y, "op": op}
	return ex2


## Splitting (the distributive property): "8 × 7 = 8 × 5 + 8 × ?", "7 × 12 = 7 × 10 + 7 × 2 = ?"
static func split(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(3, 9)
	var b := rng.randi_range(6, 9) if level < 3 else rng.randi_range(11, 12)
	var p := 5 if b < 10 else 10
	var q := b - p
	var pic := {"kind": "area_model", "cols": [str(p), str(q)], "rows": [str(a)], "cells": [[str(a * p), "?" if level == 1 else str(a * q)]]}
	if level == 1:
		var ex := K.number("%d × %d = %d × %d + %d × ?" % [a, b, a, p, a], q,
			"Split %d into %d and %d. Multiply %d by each part." % [b, p, q, a],
			"%d = %d + %d, so %d × %d = %d × %d + %d × %d = %d + %d = %d." % [b, p, q, a, b, a, p, a, q, a * p, a * q, a * b], pic)
		ex.data = {"a": a, "b": b, "p": p}
		return ex
	if level == 2:
		var ex2 := K.number("%d × %d = %d × %d + %d × %d = ?" % [a, b, a, p, a, q], a * b,
			"Work out each part: %d × %d and %d × %d. Then add them." % [a, p, a, q],
			"%d + %d = %d, so %d × %d = %d." % [a * p, a * q, a * b, a, b, a * b], pic)
		ex2.data = {"a": a, "b": b, "p": p}
		return ex2
	var right := "%d × %d + %d × %d" % [a, p, a, q]
	var wrongs: Array = []
	for w: Array in [["%d × %d + %d" % [a, p, q], a * p + q], ["%d × %d + %d × %d" % [a, p, b, q], a * p + b * q],
			["%d + %d × %d" % [a, p, q], a + p * q], ["%d × %d + %d × %d" % [a, p, a, q + 1], a * p + a * (q + 1)]]:
		if int(w[1]) != a * b:
			wrongs.append(w[0])
	var ex3 := K.choice(rng, "Which is the same as %d × %d?" % [a, b], right, wrongs,
		"Split %d into %d + %d. Both parts must be multiplied by %d." % [b, p, q, a],
		"%d × %d = %d × %d + %d × %d = %d + %d = %d." % [a, b, a, p, a, q, a * p, a * q, a * b])
	ex3.data = {"a": a, "b": b, "p": p}
	return ex3


## Grouping three numbers (the associative property): "2 × 7 × 5 = ?" (2 × 5 first)
static func group_three(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pairs: Array = [[2, 5], [5, 2], [2, 5]]
	if level == 2:
		pairs = [[2, 5], [4, 5], [2, 3], [3, 3]]
	elif level == 3:
		pairs = [[4, 5], [2, 6], [3, 4], [5, 6]]
	var pair: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
	var x: int = pair[0]
	var z: int = pair[1]
	var y := rng.randi_range(2, 9)
	var nums: Array[int] = [x, y, z]
	if level > 1 and rng.randf() < 0.5:
		nums = [y, x, z]
	var product := x * y * z
	var ex := K.number("%d × %d × %d = ?" % [nums[0], nums[1], nums[2]], product,
		"You can multiply in any order. Which two make an easy number? Try %d × %d first." % [x, z],
		"%d × %d = %d, and %d × %d = %d." % [x, z, x * z, x * z, y, product])
	ex.data = {"nums": nums}
	return ex


## The area model: "What is 7 × 13?" split into 7 × 10 and 7 × 3 (level 3: the parts not written in)
static func split_area(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(3, 9)
	var b := rng.randi_range(11, 19) if level > 1 else rng.randi_range(11, 14)
	var p := 10
	var q := b - p
	var cells: Array = [[str(a * p), str(a * q)]]
	if level == 2:
		cells = [[str(a * p), "?"]]
	var pic := {"kind": "area_model", "cols": [str(p), str(q)], "rows": [str(a)]}
	if level < 3:
		pic.cells = cells
	var ex := K.number("The rectangle is %d by %d. What is %d × %d?" % [a, b, a, b], a * b,
		"Work out each part of the rectangle: %d × %d and %d × %d. Then add them." % [a, p, a, q],
		"%d × %d = %d and %d × %d = %d. %d + %d = %d." % [a, p, a * p, a, q, a * q, a * p, a * q, a * b], pic)
	ex.data = {"a": a, "b": b}
	return ex


# --- Unit 7: multiply and divide by one digit (3.NBT.3; UK Y4 short multiplication) ---------------------------------------

## "4 × 30 = ?" (level 3 also "? × 60 = 420")
static func times_tens(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 5 if level == 1 else 9)
	var t := rng.randi_range(1, 5 if level == 1 else 9)
	var tens := t * 10
	var form := rng.randi_range(0, 1) if level == 3 else 0
	var prompt := "%d × %d = ?" % [a, tens]
	var answer := a * tens
	if form == 1:
		if rng.randf() < 0.5:
			prompt = "? × %d = %d" % [tens, a * tens]
			answer = a
		else:
			prompt = "%d × ? = %d" % [a, a * tens]
			answer = tens
	var ex := K.number(prompt, answer, "%d tens is %d. Work out %d × %d, then make it tens." % [t, tens, a, t],
		"%d × %d = %d, so %d × %d tens = %d tens = %d." % [a, t, a * t, a, t, a * t, a * tens])
	ex.data = {"a": a, "tens": tens, "form": form}
	return ex


## Short multiplication in columns: "47 × 6 = ?" (level 3: 3 digits)
static func short_multiply(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 0
	var b := 0
	for _try in 100:
		b = rng.randi_range(2, 4 if level == 1 else 9)
		a = rng.randi_range(11, 44) if level == 1 else (rng.randi_range(13, 99) if level == 2 else rng.randi_range(102, 999))
		var carry := (a % 10) * b >= 10
		if (level == 1 and not carry) or (level > 1 and carry):
			break
	var ex := K.number("%s × %d = ?" % [K.fmt(a), b], a * b,
		"Multiply the ones first, then the tens, then the hundreds. Carry any tens to the next place.",
		_times_steps(a, b), {"kind": "column", "rows": [K.fmt(a), "× %d" % b], "lines": [1]})
	ex.data = {"a": a, "b": b}
	return ex


## Short division without a remainder: "72 ÷ 3 = ?" (level 3: 3 digits)
static func short_divide(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var by := 0
	var q := 0
	for _try in 100:
		by = rng.randi_range(2, 4 if level == 1 else 9)
		q = rng.randi_range(11, 33) if level == 1 else (rng.randi_range(12, 49) if level == 2 else rng.randi_range(102, 330))
		var total := by * q
		if total >= (100 if level < 3 else 1000):
			continue
		var exchange := int(total / 10.0) % by != 0 or (level == 3 and int(total / 100.0) % by != 0)
		if (level == 1 and not exchange) or (level > 1 and exchange):
			break
	var t := by * q
	var ex := K.number("%s ÷ %d = ?" % [K.fmt(t), by], q,
		"Share the biggest place first. What cannot be shared is exchanged into the next place: 1 ten is 10 ones.",
		"%s ÷ %d = %s. Check: %s × %d = %s." % [K.fmt(t), by, K.fmt(q), K.fmt(q), by, K.fmt(t)])
	ex.data = {"total": t, "by": by}
	return ex


## Division with a remainder: "29 ÷ 4 = 7 remainder ?" (or the number of each)
static func remainder(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var by := rng.randi_range(2, 5 if level == 1 else 9)
	var q := rng.randi_range(2, 9) if level == 1 else (rng.randi_range(3, 11) if level == 2 else rng.randi_range(12, 99))
	var left := rng.randi_range(1, by - 1)
	var total := by * q + left
	var ask_left := rng.randf() < 0.5
	var prompt := "%s ÷ %d = %s remainder ?" % [K.fmt(total), by, K.fmt(q)] if ask_left else \
		"%s ÷ %d = ? remainder %d" % [K.fmt(total), by, left]
	var ex := K.number(prompt, left if ask_left else q,
		"How many whole groups of %d fit in %s? What is left over is the remainder; it is always less than %d." % [by, K.fmt(total), by],
		"%d × %s = %s, and %s − %s = %d. So %s ÷ %d = %s remainder %d." % [by, K.fmt(q), K.fmt(by * q), K.fmt(total),
			K.fmt(by * q), left, K.fmt(total), by, K.fmt(q), left])
	ex.data = {"total": total, "by": by, "ask_left": ask_left}
	return ex


## What a remainder means in a story: boats needed (round up), boxes filled (round down) or what is left over.
static func remainder_story(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var by := rng.randi_range(3, 6 if level < 3 else 9)
	var q := rng.randi_range(3, 9 if level < 3 else 15)
	var left := rng.randi_range(1, by - 1)
	var total := by * q + left
	var ask := rng.randi_range(0, 2)
	var prompt := ""
	var answer := 0
	var why := ""
	match ask:
		0:
			prompt = "%d buddies ride in boats. Each boat holds %d. Every buddy needs a seat. How many boats are needed?" % [total, by]
			answer = q + 1
			why = "%d full boats carry %d buddies. The %s left over %s one more boat: %d boats." % [q, by * q,
				"buddy" if left == 1 else "%d buddies" % left, "needs" if left == 1 else "need", q + 1]
		1:
			prompt = "%s packs %d eggs into boxes of %d. How many boxes can %s fill?" % [who, total, by, who]
			answer = q
			why = "%d boxes of %d use %d eggs. The %s left over cannot fill a box: %d boxes." % [q, by, by * q,
				"egg" if left == 1 else "%d eggs" % left, q]
		_:
			prompt = "%s shares %d cookies equally among %d friends. How many cookies are left over?" % [who, total, by]
			answer = left
			why = "Each friend gets %d: %d × %d = %d. %d − %d = %d: %s left over." % [q, q, by, by * q, total, by * q, left,
				"1 cookie is" if left == 1 else "%d cookies are" % left]
	var ex := K.number(prompt, answer, "Work out %d ÷ %d with a remainder. Then think: what does the remainder mean here?" % [total, by],
		"%d ÷ %d = %d remainder %d. %s" % [total, by, q, left, why])
	ex.data = {"total": total, "by": by, "ask": ask}
	return ex


# --- Unit 8: two-step problems with bar models (3.OA.8; SG P3 model drawing) ------------------------------------------------

## Two-step stories (the bar model where it helps). kind 0: a + b − c; 1: a × b + c; 2: a × b − c; 3: a ÷ b − c;
## 4: a and b fewer, together; 5: (a + b) ÷ c.
static func two_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var kind := rng.randi_range(0, 5) if level > 1 else rng.randi_range(0, 2)
	var big: int = [50, 200, 900][level - 1]
	var a := 0
	var b := 0
	var c := 0
	var prompt := ""
	var answer := 0
	var steps := ""
	var pic := {}
	match kind:
		0:
			a = rng.randi_range(12, big)
			b = rng.randi_range(5, big)
			c = rng.randi_range(5, a + b - 5)
			answer = a + b - c
			prompt = "%s had %s blocks and found %s more. Then %s used %s blocks. How many blocks are left?" % [who, K.fmt(a), K.fmt(b), who, K.fmt(c)]
			steps = "%s + %s = %s, then %s − %s = %s." % [K.fmt(a), K.fmt(b), K.fmt(a + b), K.fmt(a + b), K.fmt(c), K.fmt(answer)]
		1:
			a = rng.randi_range(2, [5, 8, 9][level - 1])
			b = rng.randi_range(3, [6, 9, 12][level - 1])
			c = rng.randi_range(2, [9, 30, 90][level - 1])
			answer = a * b + c
			prompt = "%s buys %d bags of %d apples and %d more apples. How many apples is that?" % [who, a, b, c]
			steps = "%d × %d = %d, then %d + %d = %d." % [a, b, a * b, a * b, c, answer]
		2:
			a = rng.randi_range(3, [6, 9, 12][level - 1])
			b = rng.randi_range(3, [6, 9, 12][level - 1])
			c = rng.randi_range(2, a * b - 1)
			answer = a * b - c
			prompt = "A farm has %d rows of %d seeds. %d seeds do not grow. How many seeds grow?" % [a, b, c]
			steps = "%d × %d = %d, then %d − %d = %d." % [a, b, a * b, a * b, c, answer]
		3:
			b = rng.randi_range(2, [5, 8, 9][level - 1])
			var each := rng.randi_range(4, [9, 12, 12][level - 1])
			a = b * each
			c = rng.randi_range(1, each - 1)
			answer = each - c
			prompt = "%s shares %d gems equally among %d friends. One friend gives %d away. How many gems does that friend have now?" % [who, a, b, c]
			steps = "%d ÷ %d = %d, then %d − %d = %d." % [a, b, each, each, c, answer]
		4:
			a = rng.randi_range(20, big + 20)
			b = rng.randi_range(5, a - 5)
			answer = a + (a - b)
			prompt = "Mimi has %s shells. Pip has %s fewer than Mimi. How many shells do they have together?" % [K.fmt(a), K.fmt(b)]
			steps = "Pip has %s − %s = %s. Together: %s + %s = %s." % [K.fmt(a), K.fmt(b), K.fmt(a - b), K.fmt(a), K.fmt(a - b), K.fmt(answer)]
			pic = {"kind": "bar_model", "bars": [{"name": "Mimi", "parts": [{"text": K.fmt(a), "size": a}]},
				{"name": "Pip", "parts": [{"text": "?", "size": a - b}]}], "diff": K.fmt(b)}
		_:
			c = rng.randi_range(2, [5, 6, 9][level - 1])
			var per := rng.randi_range(3, [9, 12, 12][level - 1])
			a = rng.randi_range(1, c * per - 1)
			b = c * per - a
			answer = per
			prompt = "%s has %d red beads and %d blue beads, and puts them into %d bags with the same number in each. How many beads go in each bag?" % [who, a, b, c]
			steps = "%d + %d = %d, then %d ÷ %d = %d." % [a, b, a + b, a + b, c, per]
	var ex := K.number(prompt, answer, "Two steps: what do you need to find first? A bar model can show it.", steps, pic)
	ex.data = {"kind": kind, "a": a, "b": b, "c": c}
	return ex


## A letter for the unknown: "Zara had 45 blocks and used some. 28 are left: 45 − n = 28. What is n?"
static func letter_unknown(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var form := rng.randi_range(0, 1) if level == 1 else rng.randi_range(0, 3)
	var who := _who(rng)
	var prompt := ""
	var answer := 0
	var explain := ""
	var known := 0    # the number in the sentence besides n and the result
	var result := 0
	var hi: int = [60, 300, 900][level - 1]
	match form:
		0:
			var a := rng.randi_range(10, hi)
			answer = rng.randi_range(5, hi)
			prompt = "%s has %s blocks and finds n more. Now there are %s: %s + n = %s. What is n?" % [who, K.fmt(a), K.fmt(a + answer), K.fmt(a), K.fmt(a + answer)]
			explain = "n = %s − %s = %s." % [K.fmt(a + answer), K.fmt(a), K.fmt(answer)]
			known = a
			result = a + answer
		1:
			var a := rng.randi_range(20, hi)
			answer = rng.randi_range(5, a - 5)
			prompt = "%s had %s blocks and used n. %s are left: %s − n = %s. What is n?" % [who, K.fmt(a), K.fmt(a - answer), K.fmt(a), K.fmt(a - answer)]
			explain = "n = %s − %s = %s." % [K.fmt(a), K.fmt(a - answer), K.fmt(answer)]
			known = a
			result = a - answer
		2:
			var b := rng.randi_range(2, 9)
			answer = rng.randi_range(2, 12)
			prompt = "n bags hold %d apples each: %d apples in all. n × %d = %d. What is n?" % [b, b * answer, b, b * answer]
			explain = "n = %d ÷ %d = %d, because %d × %d = %d." % [b * answer, b, answer, answer, b, b * answer]
			known = b
			result = b * answer
		_:
			var b := rng.randi_range(2, 9)
			answer = rng.randi_range(2, 12)
			prompt = "%d gems are shared among n friends, %d each: %d ÷ n = %d. What is n?" % [b * answer, b, b * answer, b]
			explain = "%d × %d = %d, so n = %d." % [answer, b, b * answer, answer]
			known = b
			result = b * answer
	var ex := K.number(prompt, answer, "n stands for the number you do not know. Use the other operation to undo the one in the sentence.",
		explain)
	ex.data = {"form": form, "known": known, "result": result}
	return ex


## "Bram says 298 + 405 = 1,003. Round to the nearest hundred to check: could that be right?"
static func estimate_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var a := rng.randi_range(110, 890) if level < 3 else rng.randi_range(1100, 5900)
	var b := rng.randi_range(110, 890) if level < 3 else rng.randi_range(1100, 3900)
	var add := level == 1 or rng.randf() < 0.5
	if not add and b > a:
		var t := a
		a = b
		b = t
	var right := a + b if add else a - b
	var claimed := right
	if rng.randi_range(0, 1) == 0:
		var off: int = [300, 400, 500][rng.randi_range(0, 2)] if level < 3 else [2000, 3000][rng.randi_range(0, 1)]
		claimed = right + off if rng.randf() < 0.5 else right - off
		if claimed <= 0 or claimed > 9999:
			claimed = right - off if claimed > right else right + off
	var to := 100 if level < 3 else 1000
	var ra := _round(a, to)
	var rb := _round(b, to)
	var guess := ra + rb if add else ra - rb
	var ok := claimed == right
	var ex := K.truefalse("%s says %s %s %s = %s. Round each number to the nearest %s. Could %s be right?" % [who, K.fmt(a),
		"+" if add else "−", K.fmt(b), K.fmt(claimed), "hundred" if to == 100 else "thousand", who], ok,
		"%s rounds to %s and %s rounds to %s. Is the answer near %s %s %s?" % [K.fmt(a), K.fmt(ra), K.fmt(b), K.fmt(rb), K.fmt(ra),
			"+" if add else "−", K.fmt(rb)],
		"%s %s %s = %s, so the answer is near %s. %s %s %s = %s, so %s." % [K.fmt(ra), "+" if add else "−", K.fmt(rb), K.fmt(guess),
			K.fmt(guess), K.fmt(a), "+" if add else "−", K.fmt(b), K.fmt(right), "yes" if ok else "no"])
	ex.data = {"a": a, "b": b, "add": add, "claimed": claimed}
	return ex


## "Which number sentence matches the bar model?"
static func model_sentence(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kind := rng.randi_range(0, 2) if level == 1 else rng.randi_range(0, 3)
	var a := rng.randi_range(15, [60, 200, 900][level - 1])
	var b := rng.randi_range(10, a - 5)
	var n := rng.randi_range(3, 6)
	var e := rng.randi_range(3, 12)
	var pic := {}
	var right := ""
	var wrongs: Array = []
	match kind:
		0:   # parts to the whole
			pic = {"kind": "bar_model", "bars": [{"parts": [{"text": K.fmt(a), "size": a}, {"text": K.fmt(b), "size": b}], "total": "?"}]}
			right = "%s + %s = ?" % [K.fmt(a), K.fmt(b)]
			wrongs = ["%s − %s = ?" % [K.fmt(a), K.fmt(b)], "%s × %s = ?" % [K.fmt(a), K.fmt(b)], "%s + ? = %s" % [K.fmt(a), K.fmt(b)]]
		1:   # a missing part
			pic = {"kind": "bar_model", "bars": [{"parts": [{"text": K.fmt(b), "size": b}, {"text": "?", "size": a - b}], "total": K.fmt(a)}]}
			right = "%s − %s = ?" % [K.fmt(a), K.fmt(b)]
			wrongs = ["%s + %s = ?" % [K.fmt(a), K.fmt(b)], "%s − %s = ?" % [K.fmt(b), K.fmt(a)], "? − %s = %s" % [K.fmt(a), K.fmt(b)]]
		2:   # equal parts
			var parts: Array = []
			for _i in n:
				parts.append({"text": str(e), "size": 1})
			pic = {"kind": "bar_model", "bars": [{"parts": parts, "total": "?"}]}
			right = "%d × %d = ?" % [n, e]
			wrongs = ["%d + %d = ?" % [n, e], "%d × %d = ?" % [n, e + 1], "%d × %d = ?" % [n + 1, e]]
		_:   # comparing two bars
			pic = {"kind": "bar_model", "bars": [{"name": "Zara", "parts": [{"text": K.fmt(a), "size": a}]},
				{"name": "Bram", "parts": [{"text": K.fmt(b), "size": b}]}], "diff": "?"}
			right = "%s − %s = ?" % [K.fmt(a), K.fmt(b)]
			wrongs = ["%s + %s = ?" % [K.fmt(a), K.fmt(b)], "%s − %s = ?" % [K.fmt(a), K.fmt(a - b)], "%s × 2 = ?" % K.fmt(b)]
	var ex := K.choice(rng, "Which number sentence matches the bar model?", right, wrongs,
		"Find the \"?\" in the model. Is it the whole, a part, or the difference between two bars?",
		"%s The model shows %s." % [right, ["two parts making the whole", "the whole take away the part you know",
			"%d equal parts" % n, "the difference between the bars"][kind]], pic)
	ex.data = {"kind": kind, "a": a, "b": b, "n": n, "e": e}
	return ex


# --- Helpers -----------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return NAMES[rng.randi_range(0, NAMES.size() - 1)]


## "1 ten", "3 tens"
static func _n(n: int, one: String, many: String) -> String:
	return "%d %s" % [n, one if n == 1 else many]


## A times table for the level: 1: 2, 3, 4, 5, 10; 2: 6, 7, 8, 9; 3: 11, 12 or any.
static func _table(rng: RandomNumberGenerator, level: int) -> int:
	var tables: Array = [[2, 3, 4, 5, 10], [6, 7, 8, 9], [11, 12, 6, 7, 8, 9]][level - 1]
	return int(tables[rng.randi_range(0, tables.size() - 1)])


## A strategy for a times fact.
static func _times_hint(a: int, b: int) -> String:
	if a == 2 or b == 2:
		return "Times 2 is double: add the number to itself."
	if a == 10 or b == 10:
		return "Times 10: the digits move one place to the left, and a 0 fills the ones."
	if a == 5 or b == 5:
		return "Times 5 is half of times 10."
	if a == 4 or b == 4:
		return "Times 4 is double, then double again."
	if a == 9 or b == 9:
		return "Times 9 is times 10, then take away the number once."
	if a == 11 or b == 11:
		return "Times 11 is times 10, then add the number once more."
	if a == 12 or b == 12:
		return "Times 12 is times 10 plus times 2."
	return "Use a fact you know and count on or back: %d × %d is %d more than %d × %d." % [a, b, a, a, b - 1]


static func _parts(n: int) -> Array[String]:
	var out: Array[String] = []
	var s := str(n)
	for i in s.length():
		if s[i] != "0":
			out.append(K.fmt(int(s[i]) * K.pow10(s.length() - 1 - i)))
	return out


static func _repeat(text: String, n: int) -> Array[String]:
	var out: Array[String] = []
	for _i in n:
		out.append(text)
	return out


static func _round(n: int, to: int) -> int:
	var lower := n - n % to
	return lower + to if n % to >= int(to / 2.0) else lower


## 47 -> "XLVII"
static func _roman(n: int) -> String:
	var out := ""
	for pair: Array in ROMAN:
		while n >= int(pair[0]):
			out += str(pair[1])
			n -= int(pair[0])
	return out


## 47 -> ["40", "5", "1", "1"] (the values of XL, V, I, I)
static func _roman_values(n: int) -> Array[String]:
	var out: Array[String] = []
	for pair: Array in ROMAN:
		while n >= int(pair[0]):
			out.append(str(pair[0]))
			n -= int(pair[0])
	return out


## Roman numerals without taking away (a common slip): 4 -> "IIII", 49 -> "XXXXVIIII".
static func _additive(n: int) -> String:
	var out := ""
	for pair: Array in [[100, "C"], [50, "L"], [10, "X"], [5, "V"], [1, "I"]]:
		while n >= int(pair[0]):
			out += str(pair[1])
			n -= int(pair[0])
	return out


## How many places carry when adding a and b.
static func _carries(a: int, b: int) -> int:
	var n := 0
	var carry := 0
	while a > 0 or b > 0:
		var s := a % 10 + b % 10 + carry
		carry = 1 if s >= 10 else 0
		n += carry
		a = int(a / 10.0)
		b = int(b / 10.0)
	return n


## How many places need an exchange when taking b from a.
static func _exchanges(a: int, b: int) -> int:
	var n := 0
	var borrow := 0
	while a > 0 or b > 0:
		var d := a % 10 - borrow - b % 10
		borrow = 1 if d < 0 else 0
		n += borrow
		a = int(a / 10.0)
		b = int(b / 10.0)
	return n


## Column adding in words: "Ones: 6 + 8 = 14, write 4, carry 1. Tens: …"
static func _add_steps(a: int, b: int) -> String:
	var words: Array[String] = []
	var carry := 0
	var place := 0
	var x := a
	var y := b
	while x > 0 or y > 0:
		var s := x % 10 + y % 10 + carry
		var sum := "%d + %d%s = %d" % [x % 10, y % 10, " + 1" if carry > 0 else "", s]
		if s >= 10 and (int(x / 10.0) > 0 or int(y / 10.0) > 0):
			words.append("%s: %s, write %d, carry 1." % [PLACES[place].capitalize(), sum, s % 10])
		else:
			words.append("%s: %s." % [PLACES[place].capitalize(), sum])
		carry = 1 if s >= 10 else 0
		x = int(x / 10.0)
		y = int(y / 10.0)
		place += 1
	return " ".join(words) + " So %s." % K.fmt(a + b)


## Short multiplication in words: "Ones: 7 × 6 = 42, write 2, carry 4. Tens: 4 × 6 + 4 = 28. So 282."
static func _times_steps(a: int, b: int) -> String:
	var words: Array[String] = []
	var carry := 0
	var place := 0
	var x := a
	while x > 0:
		var p := (x % 10) * b + carry
		var sum := "%d × %d%s = %d" % [x % 10, b, " + %d" % carry if carry > 0 else "", p]
		if p >= 10 and int(x / 10.0) > 0:
			words.append("%s: %s, write %d, carry %d." % [PLACES[place].capitalize(), sum, p % 10, int(p / 10.0)])
		else:
			words.append("%s: %s." % [PLACES[place].capitalize(), sum])
		carry = int(p / 10.0)
		x = int(x / 10.0)
		place += 1
	return " ".join(words) + " So %s." % K.fmt(a * b)
