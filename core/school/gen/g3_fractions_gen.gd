class_name G3FractionsGen
extends RefCounted
## Owner #70 (grade 3 maths, units 9-12 of the outline: fractions of a whole and of a set, fractions on a number line,
## equal fractions and comparing, money in the game's gold; Common Core 3.NF, 3.G.2 with England Year 4 and Singapore P3
## fractions and money). Each is `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary` (SchoolGen
## "g3f.<name>"), seeded, level 1-3, returning an exercise with a hint about the strategy, a worked answer and `data` (its
## inputs, for tests). Denominators 2, 3, 4, 5, 6, 8, 10, 12; whole gold coins (the research's ruling 5.5.6). Pictures of
## SchoolPictureG3 (ui/school/school_picture_g3.gd). Helpers start with "_".
## Numbers and operations: G3MathsGen ("g3m"); time, measures, shapes and graphs: G3MeasureGen ("g3g").

const K := preload("res://core/school/gen/gen_kit.gd")
const NAMES: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Pip", "Nell"]
const PARTS := {2: ["half", "halves"], 3: ["third", "thirds"], 4: ["quarter", "quarters"], 5: ["fifth", "fifths"],
	6: ["sixth", "sixths"], 8: ["eighth", "eighths"], 10: ["tenth", "tenths"], 12: ["twelfth", "twelfths"]}
const GRID_CUTS: Array[int] = [4, 6, 8, 9, 12]   # SchoolPictureG3.GRID_CUTS
## Things to buy, [one, many].
const ITEMS: Array = [["lantern", "lanterns"], ["map", "maps"], ["cake", "cakes"], ["hat", "hats"], ["kite", "kites"],
	["book", "books"], ["scarf", "scarves"], ["pie", "pies"], ["torch", "torches"], ["bucket", "buckets"]]


# --- Unit 9: fractions of a whole and of a set (3.NF.1, 3.G.2; SG P3) --------------------------------------------------

## "What fraction of the shape is shaded?" (level 3 also "… is not shaded?")
static func name_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var dens: Array = [[2, 3, 4], [2, 3, 4, 5, 6, 8], [3, 4, 5, 6, 8, 10, 12]][level - 1]
	var den: int = dens[rng.randi_range(0, dens.size() - 1)]
	var num := 1 if level == 1 else rng.randi_range(1, den - 1)
	var not_shaded := level == 3 and rng.randf() < 0.5
	var asked := den - num if not_shaded else num
	var ex := K.number("What fraction of the shape is %s?" % ("not shaded" if not_shaded else "shaded"), "%d/%d" % [asked, den],
		"Count all the equal parts: that is the bottom number. Count the %s parts: that is the top number." %
			("white" if not_shaded else "shaded"),
		"The shape has %d equal parts and %d of them %s %s: %d/%d." % [den, asked, "is" if asked == 1 else "are",
			"not shaded" if not_shaded else "shaded", asked, den], _fraction_picture(rng, num, den))
	ex.data = {"num": num, "den": den, "not_shaded": not_shaded}
	return ex


## "Which picture shows 3/4 shaded?" (the choices are shapes; the wrong ones have other counts or parts not equal)
static func pick_picture(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den := rng.randi_range(2, 4 if level == 1 else 8)
	if den == 7:
		den = 8
	var num := 1 if level == 1 else rng.randi_range(1, den - 1)
	var right := _fraction_picture(rng, num, den)
	var wrongs: Array = []
	var other_shade := num + 1 if num + 1 < den else num - 1
	if other_shade >= 1 and other_shade != num:
		var w := right.duplicate()
		w.shade = other_shade
		wrongs.append({"picture": w})
	var all_shaded := right.duplicate()
	all_shaded.shade = den
	wrongs.append({"picture": all_shaded})
	var other_den := den + 1 if den < 8 else den - 1
	wrongs.append({"picture": {"kind": "cut_shape", "shape": "circle", "parts": other_den, "shade": num}})
	if level > 1:
		wrongs.append({"picture": {"kind": "cut_shape", "shape": ["circle", "rectangle"][rng.randi_range(0, 1)], "parts": den,
			"shade": num, "unequal": true}})
	var ex := K.choice(rng, "Which picture shows %d/%d shaded?" % [num, den], {"picture": right}, wrongs,
		"Look for %d equal parts with %d of them shaded. Are the parts really equal?" % [den, num],
		"%d/%d means %d equal parts with %d shaded." % [num, den, den, num])
	ex.data = {"num": num, "den": den}
	return ex


## "What is 1/4 of 12?" (the groups picture; level 3 a story)
static func fraction_of_set(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den: int = rng.randi_range(2, 5) if level < 3 else [3, 4, 5, 6, 8, 10][rng.randi_range(0, 5)]
	var each := rng.randi_range(2, 5 if level < 3 else 6)
	var num := 1 if level == 1 else rng.randi_range(1 if level == 3 else 2, den - 1)
	if level == 2 and den == 2:
		den = 3
		num = 2
	var total := den * each
	var ex: Dictionary
	var explain := "Split %d into %d equal groups: %d in each. %d/%d is %d of those groups: %d." % [total, den, each, num, den,
		num, num * each]
	if level < 3:
		ex = K.number("What is %d/%d of %d?" % [num, den, total], num * each,
			"Share %d into %d equal groups. Then take %d of the groups." % [total, den, num], explain,
			{"kind": "groups", "groups": den, "each": each})
	else:
		var who := _who(rng)
		ex = K.number("%s has %d gems. %d/%d of them are blue. How many blue gems does %s have?" % [who, total, num, den, who],
			num * each, "Find 1/%d of %d first, then take %d of those." % [den, total, num], explain)
	ex.data = {"num": num, "den": den, "total": total}
	return ex


## "Is this shape cut into equal parts?" (level 2-3: "Each part is 1/4 of the shape." true or false)
static func equal_parts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var parts := rng.randi_range(2, 6)
	var unequal := rng.randf() < 0.45
	var pic: Dictionary
	if unequal:
		pic = {"kind": "cut_shape", "shape": ["circle", "rectangle"][rng.randi_range(0, 1)], "parts": parts, "unequal": true}
	else:
		pic = _fraction_picture(rng, 0, parts)
	var claim := 0
	var ex: Dictionary
	if level == 1:
		ex = K.truefalse("Is this shape cut into equal parts?", not unequal,
			"Equal parts are all the same size. Would each part cover the others exactly?",
			"Yes: all %d parts are the same size." % parts if not unequal else "No: some parts are bigger than others.", pic)
	else:
		claim = parts if rng.randf() < 0.5 else parts + [-1, 1][rng.randi_range(0, 1)]
		if claim < 2:
			claim = parts + 1
		var ok := not unequal and claim == parts
		var why := "Yes: %d equal parts, so each is 1/%d." % [parts, parts]
		if unequal:
			why = "No: the parts are not equal, so they are not %s." % _plural(claim)
		elif not ok:
			why = "No: there are %d equal parts, so each is 1/%d, not 1/%d." % [parts, parts, claim]
		ex = K.truefalse("Each part of this shape is 1/%d of the shape. True or false?" % claim, ok,
			"First check that the parts are equal. Then count them.", why, pic)
	ex.data = {"parts": parts, "unequal": unequal, "claim": claim}
	return ex


## "This wall has room for 8 blocks. Fill 3/4 of it." (the block board)
static func build_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den := rng.randi_range(2, 4)
	var num := 1
	var board := {"cols": 0, "rows": 1, "block": BlockIds.BRICK, "given": [], "view": "wall"}
	if level == 1:
		board.cols = den * rng.randi_range(1, 2)
	elif level == 2:
		den = rng.randi_range(3, 6)
		num = rng.randi_range(2, den - 1)
		board.cols = den * (2 if den <= 4 else 1) if rng.randf() < 0.5 else den
	else:
		den = [2, 3, 4, 6, 12][rng.randi_range(0, 4)]
		num = rng.randi_range(1, den - 1)
		board.cols = 6
		board.rows = 2
	var total := int(board.cols) * int(board.rows)
	var blocks := int(total * num / float(den))
	var ex := K.build("This wall has room for %d blocks. Fill %d/%d of it." % [total, num, den], board,
		{"kind": "fraction", "num": num, "den": den},
		"Split the %d spaces into %d equal parts. How many spaces are in one part? Fill %s." % [total, den,
			_n(num, "part", "parts")],
		"1/%d of %d is %d, so %d/%d is %d × %d = %s." % [den, total, int(total / float(den)), num, den, num,
			int(total / float(den)), _n(blocks, "block", "blocks")])
	ex.data = {"num": num, "den": den, "total": total}
	return ex


# --- Unit 10: fractions on a number line (3.NF.2, 3.NF.3c) ------------------------------------------------------------------

## "What fraction is at the dot?" (level 3 on a line from 0 to 2 or 3)
static func fraction_on_line(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var dens: Array = [[2, 3, 4], [3, 4, 5, 6, 8], [2, 3, 4]][level - 1]
	var den: int = dens[rng.randi_range(0, dens.size() - 1)]
	var to := 1 if level < 3 else rng.randi_range(2, 3)
	var k := rng.randi_range(1, den * to - (1 if level == 1 else 0))
	var line := {"kind": "number_line", "from": "0", "to": str(to), "step": "1/%d" % den, "dot": "%d/%d" % [k, den],
		"labels": "ends"}
	var whole := "" if k % den != 0 else " That is %d whole%s." % [int(k / float(den)), "" if k == den else "s"]
	var ex := K.number("What fraction is at the dot?", "%d/%d" % [k, den],
		"Each whole is cut into %d equal parts. Count the jumps from 0 to the dot." % den,
		"Each jump is 1/%d. The dot is %s from 0, so it is at %d/%d.%s" % [den, _n(k, "jump", "jumps"), k, den, whole], line)
	ex.data = {"num": k, "den": den, "to": to}
	return ex


## "Pip hops from 0 in jumps of 1/5. Where is Pip after 3 jumps?"
static func jumps(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var dens: Array = [[2, 3, 4], [3, 4, 5, 6, 8], [2, 3, 4, 5, 6]][level - 1]
	var den: int = dens[rng.randi_range(0, dens.size() - 1)]
	var k := rng.randi_range(1, den - 1) if level == 1 else (rng.randi_range(2, den) if level == 2 else rng.randi_range(den + 1, 2 * den))
	var to := 1 if k <= den else 2
	var who := _who(rng)
	var ex := K.number("%s hops along the line from 0 in jumps of 1/%d. Where is %s after %s?" % [who, den, who,
		_n(k, "jump", "jumps")], "%d/%d" % [k, den], "Each jump is 1/%d. Count %s along the line." % [den, _n(k, "jump", "jumps")],
		"%s of 1/%d %s %d/%d." % [_n(k, "jump", "jumps"), den, "makes" if k == 1 else "make", k, den],
		{"kind": "number_line", "from": "0", "to": str(to), "step": "1/%d" % den, "labels": "ends"})
	ex.data = {"num": k, "den": den}
	return ex


## Whole numbers as fractions: "4/4 = ?", "8/4 = ?", "3 = ?/1", "2 = ?/4"
static func whole_as_fraction(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var form := 0 if level == 1 else (rng.randi_range(1, 2) if level == 2 else rng.randi_range(1, 3))
	var den := rng.randi_range(2, 8)
	var w := rng.randi_range(2, 3 if form == 1 else 6)
	var prompt := ""
	var answer := 0
	var explain := ""
	var pic := {}
	match form:
		0:
			prompt = "%d/%d = ?" % [den, den]
			answer = 1
			explain = "%d of the %d equal parts is the whole thing: %d/%d = 1." % [den, den, den, den]
			pic = {"kind": "fraction_wall", "rows": [{"den": den, "shade": den}]}
		1:
			den = rng.randi_range(2, 4)
			prompt = "%d/%d = ?" % [w * den, den]
			answer = w
			explain = "%d parts make one whole, so %d parts make %d wholes: %d/%d = %d." % [den, w * den, w, w * den, den, w]
		2:
			prompt = "%d = ?/1" % w
			answer = w
			explain = "Cut each whole into 1 part: %d wholes are %d parts. %d = %d/1." % [w, w, w, w]
		_:
			prompt = "%d = ?/%d" % [w, den]
			answer = w * den
			explain = "Each whole is %d/%d, so %d wholes are %d × %d = %d parts: %d = %d/%d." % [den, den, w, w, den, w * den, w,
				w * den, den]
	var ex := K.number(prompt, answer, "One whole is 1/1, 2/2, 3/3 or 4/4: all of its parts. How many parts make the wholes here?",
		explain, pic)
	ex.data = {"form": form, "w": w, "den": den}
	return ex


## "Put these fractions in order, smallest first." (the same bottom number; level 3 past 1)
static func order_on_line(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den := rng.randi_range(4, 8) if level < 3 else rng.randi_range(2, 4)
	var top := den - 1 if level == 1 else (den if level == 2 else den * 2)
	var nums: Array[int] = []
	var tries := 0
	while nums.size() < 4 and tries < 200:
		tries += 1
		var n := rng.randi_range(1, top)
		if not nums.has(n):
			nums.append(n)
	if level == 2 and not nums.has(den):
		nums[0] = den
	nums.sort()
	var texts: Array = []
	for n in nums:
		texts.append("%d/%d" % [n, den])
	var ex := K.order(rng, "Put these fractions in order, smallest first.", texts,
		"They are all %s. The more %s, the bigger the fraction." % [_plural(den), _plural(den)],
		"Smallest first: %s." % ", ".join(texts))
	ex.data = {"nums": nums, "den": den}
	return ex


## "Is 5/4 less than 1, equal to 1 or more than 1?"
static func compare_to_one(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den := rng.randi_range(2, 8)
	var num := rng.randi_range(1, den) if level == 1 else rng.randi_range(1, 2 * den)
	var right := "equal to 1" if num == den else ("less than 1" if num < den else "more than 1")
	var ex := K.choice(rng, "Is %d/%d less than 1, equal to 1 or more than 1?" % [num, den], right,
		["less than 1", "equal to 1", "more than 1"], "%d/%d is one whole. Is %d more or less than %d?" % [den, den, num, den],
		"One whole is %d/%d. %d/%d is %s." % [den, den, num, den, right], {"kind": "number_line", "from": "0", "to": "2",
			"step": "1/%d" % den, "dot": "%d/%d" % [num, den], "labels": "all"} if level == 1 else {})
	ex.data = {"num": num, "den": den}
	return ex


# --- Unit 11: equal fractions and comparing (3.NF.3; SG P3) -------------------------------------------------------------------

## "1/2 = ?/4" with a fraction wall (level 3 also the other way, no wall)
static func equivalent_missing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 4)
	var a := rng.randi_range(1, b - 1)
	var m := 2 if level == 1 else rng.randi_range(2, 3)
	if b * m > 12:
		m = 2
	var form := rng.randi_range(0, 2) if level == 3 else 0
	var prompt := "%d/%d = ?/%d" % [a, b, b * m]
	var answer := a * m
	if form == 1:
		prompt = "%d/%d = ?/%d" % [a * m, b * m, b]
		answer = a
	elif form == 2:
		prompt = "%d/%d = %d/?" % [a, b, a * m]
		answer = b * m
	var pic := {"kind": "fraction_wall", "rows": [{"den": b, "shade": a}, {"den": b * m, "shade": a * m}]} if level < 3 else {}
	var ex := K.number(prompt, answer,
		"On the fraction wall, find where %d/%d ends. How many of the smaller parts fit up to there?" % [a, b] if level < 3 else
			"Multiply or divide the top and the bottom by the same number.",
		"%d/%d = %d/%d: each %s is split into %d, so there are %d times as many parts on top and on the bottom." % [a, b, a * m,
			b * m, PARTS[b][0], m, m], pic)
	ex.data = {"a": a, "b": b, "m": m, "form": form}
	return ex


## "2/3 = 4/6. True or false?" (the fraction wall at levels 1-2)
static func is_equivalent(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var b := rng.randi_range(2, 4)
	var a := rng.randi_range(1, b - 1)
	var m := rng.randi_range(2, 3)
	var d := b * m
	var c := a * m
	if rng.randf() < 0.5:
		c += 1 if c + 1 < d else -1
	var ok := a * d == b * c
	var pic := {"kind": "fraction_wall", "rows": [{"den": b, "shade": a}, {"den": d, "shade": c}]} if level < 3 else {}
	var ex := K.truefalse("%d/%d = %d/%d. True or false?" % [a, b, c, d], ok,
		"Do the two shaded parts end at the same place on the wall?" if level < 3 else
			"Multiply the top and the bottom of %d/%d by %d. Do you get %d/%d?" % [a, b, m, c, d],
		("True: %d/%d = %d/%d (both times %d)." % [a, b, c, d, m]) if ok else
			("False: %d/%d = %d/%d, not %d/%d." % [a, b, a * m, d, c, d]), pic)
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "Which sign makes this true?  3/8 ? 5/8" (level 1 the same bottom, level 2 the same top, level 3 either)
static func compare_fractions(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var same_bottom := level == 1 or (level == 3 and rng.randf() < 0.5)
	var a := 0
	var b := 0
	var c := 0
	var d := 0
	if same_bottom:
		b = rng.randi_range(3, 12)
		d = b
		a = rng.randi_range(1, b - 1)
		c = rng.randi_range(1, b - 1)
	else:
		a = rng.randi_range(1, 3)
		c = a
		var dens: Array = [2, 3, 4, 5, 6, 8, 10, 12].filter(func(x: int) -> bool: return x > a)
		b = dens[rng.randi_range(0, dens.size() - 1)]
		d = dens[rng.randi_range(0, dens.size() - 1)]
	var sign := "=" if a * d == b * c else (">" if a * d > b * c else "<")
	var pic := {"kind": "fraction_wall", "rows": [{"den": b, "shade": a}, {"den": d, "shade": c}]} if level < 3 else {}
	var hint := "The parts are the same size. Compare how many parts." if same_bottom else \
		"The same number of parts: the bigger the bottom number, the smaller each part."
	var ex := K.choice(rng, "Which sign makes this true?  %d/%d ? %d/%d" % [a, b, c, d], sign,
		[">", "<", "="].filter(func(x: String) -> bool: return x != sign), hint,
		"%d/%d %s %d/%d" % [a, b, sign, c, d], pic)
	ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## "2/5 + 1/5 = ?" (level 2 taking away, level 3 to a whole and past it)
static func add_same(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var den: int = [3, 4, 5, 6, 8, 10, 12][rng.randi_range(0, 6)]
	var add := level != 2 or rng.randf() < 0.3
	var a := rng.randi_range(1, den - 1)
	var b := rng.randi_range(1, den - 1)
	if level == 1:
		b = rng.randi_range(1, maxi(1, den - a - 1))
		if a + b >= den:
			a = 1
			b = 1
	elif level == 2 and not add and b > a:
		var t := a
		a = b
		b = t
	elif level == 3 and rng.randf() < 0.5:
		b = den - a   # to a whole
	if not add and a == b:
		a = mini(a + 1, den)
	var total := a + b if add else a - b
	var ex := K.number("%d/%d %s %d/%d = ?" % [a, den, "+" if add else "−", b, den], "%d/%d" % [total, den],
		"The parts are all %s: %s the top numbers and keep the bottom number." % [_plural(den), "add" if add else "take away"],
		"%d %s %s %d %s = %d %s: %d/%d%s." % [a, _plural(den) if a != 1 else PARTS[den][0], "+" if add else "−", b,
			_plural(den) if b != 1 else PARTS[den][0], total, _plural(den) if total != 1 else PARTS[den][0], total, den,
			" = 1 whole" if total == den else ""])
	ex.data = {"a": a, "b": b, "den": den, "add": add}
	return ex


## "Put these in order, smallest first: 1/3, 1/8, 1/2, 1/5" (level 3 the same top number, not 1)
static func order_unit_fractions(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var num := 1 if level < 3 else rng.randi_range(2, 3)
	var pool: Array = [2, 3, 4, 5, 6, 8, 10, 12].filter(func(x: int) -> bool: return x > num)
	K.shuffle(rng, pool)
	var dens: Array = pool.slice(0, 3 if level == 1 else 4)
	dens.sort()
	dens.reverse()   # the biggest bottom number is the smallest fraction
	var texts: Array = []
	for d: int in dens:
		texts.append("%d/%d" % [num, d])
	var ex := K.order(rng, "Put these fractions in order, smallest first.", texts,
		"The top numbers are the same. More parts means smaller parts: the biggest bottom number is the smallest fraction.",
		"Smallest first: %s." % ", ".join(texts))
	ex.data = {"num": num, "dens": dens}
	return ex


# --- Unit 12: money and change (SG P3 money; UK Y3-4; the game's gold, whole coins) -----------------------------------------

## "A lantern costs 35 gold and a map costs 48 gold. How much gold is that altogether?"
static func money_total(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var items := _items(rng, 3)
	var prices: Array[int] = []
	var qty: Array[int] = [1, 1]
	var prompt := ""
	if level == 1:
		prices = [rng.randi_range(5, 45), rng.randi_range(5, 45)]
		prompt = "A %s costs %d gold and a %s costs %d gold. How much gold is that altogether?" % [items[0][0], prices[0], items[1][0], prices[1]]
	elif level == 2:
		prices = [rng.randi_range(20, 250), rng.randi_range(20, 250), rng.randi_range(10, 99)]
		qty = [1, 1, 1]
		prompt = "%s buys a %s for %d gold, a %s for %d gold and a %s for %d gold. How much gold is that?" % [_who(rng),
			items[0][0], prices[0], items[1][0], prices[1], items[2][0], prices[2]]
	else:
		prices = [rng.randi_range(5, 30), rng.randi_range(20, 90)]
		qty = [rng.randi_range(2, 5), 1]
		prompt = "%s buys %d %s at %d gold each and a %s for %d gold. How much gold is that?" % [_who(rng), qty[0], items[0][1],
			prices[0], items[1][0], prices[1]]
	var total := 0
	var parts: Array[String] = []
	for i in prices.size():
		total += prices[i] * qty[i]
		parts.append(("%d × %d" % [qty[i], prices[i]]) if qty[i] > 1 else str(prices[i]))
	var ex := K.number(prompt, total, "Add the prices. When one thing is bought more than once, multiply first.",
		"%s = %s gold." % [" + ".join(parts), K.fmt(total)])
	ex.data = {"prices": prices, "qty": qty}
	return ex


## "Zara pays 100 gold for a hat that costs 64 gold. How much change does Zara get?"
static func money_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var items := _items(rng, 2)
	var pay := 0
	var prices: Array[int] = []
	var prompt := ""
	if level == 1:
		pay = [50, 100][rng.randi_range(0, 1)]
		prices = [rng.randi_range(11, pay - 3)]
	elif level == 2:
		pay = [500, 1000][rng.randi_range(0, 1)]
		prices = [rng.randi_range(120, pay - 15)]
	else:
		pay = [100, 500, 1000][rng.randi_range(0, 2)]
		prices = [rng.randi_range(10, int(pay * 0.4)), rng.randi_range(10, int(pay * 0.4))]
	if prices.size() == 1:
		prompt = "%s pays %s gold for a %s that costs %d gold. How much change does %s get?" % [who, K.fmt(pay), items[0][0],
			prices[0], who]
	else:
		prompt = "%s buys a %s for %d gold and a %s for %d gold, and pays with %s gold. How much change?" % [who, items[0][0],
			prices[0], items[1][0], prices[1], K.fmt(pay)]
	var spent := 0
	for p in prices:
		spent += p
	var ex := K.number(prompt, pay - spent, "Change is what you paid take away the cost. Or count on from the cost to %s." % K.fmt(pay),
		"%s − %s = %s gold change." % [K.fmt(pay), K.fmt(spent), K.fmt(pay - spent)] if prices.size() == 1 else
			"%d + %d = %s. %s − %s = %s gold change." % [prices[0], prices[1], K.fmt(spent), K.fmt(pay), K.fmt(spent), K.fmt(pay - spent)])
	ex.data = {"pay": pay, "prices": prices}
	return ex


## "Nell has 80 gold. Is that enough for a hat at 45 gold and a scarf at 38 gold?"
static func can_afford(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var items := _items(rng, 3)
	var count := 2 if level < 3 else 3
	var prices: Array[int] = []
	var spent := 0
	for i in count:
		prices.append(rng.randi_range(10, [45, 250, 300][level - 1]))
		spent += prices[i]
	var have := spent + rng.randi_range(-30, 30) * (1 if level == 1 else 5)
	if have <= 0:
		have = spent
	var words: Array[String] = []
	for i in count:
		words.append("a %s at %d gold" % [items[i][0], prices[i]])
	var ok := have >= spent
	var ex := K.truefalse("%s has %s gold. Is that enough for %s?" % [who, K.fmt(have), " and ".join(words)], ok,
		"Add up the prices first. Then compare the total with %s." % K.fmt(have),
		"The total is %s gold. %s %s %s, so %s." % [K.fmt(spent), K.fmt(have), ">" if have > spent else ("=" if have == spent else "<"),
			K.fmt(spent), "yes, it is enough" if ok else "no, it is not enough"])
	ex.data = {"have": have, "prices": prices}
	return ex


## A price list (the table picture): "How much do 2 lanterns and a map cost?" (level 3 with change)
static func price_list(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var items := _items(rng, 3)
	var prices: Array[int] = []
	var rows: Array = [["Item", "Price"]]
	for i in 3:
		prices.append(rng.randi_range(4, 30) if level < 3 else rng.randi_range(5, 15))
		rows.append([str(items[i][0]).capitalize(), "%d gold" % prices[i]])
	var a := rng.randi_range(0, 2)
	var b := (a + rng.randi_range(1, 2)) % 3
	var qa := 1 if level == 1 else rng.randi_range(2, 4)
	var cost := qa * prices[a] + prices[b]
	var pay := 0
	var prompt := "How much do %s and a %s cost?" % [("a %s" % items[a][0]) if qa == 1 else ("%d %s" % [qa, items[a][1]]), items[b][0]]
	var answer := cost
	if level == 3:
		pay = 100
		prompt = "%s buys %d %s and a %s, and pays with 100 gold. How much change?" % [_who(rng), qa, items[a][1], items[b][0]]
		answer = pay - cost
	var ex := K.number(prompt, answer, "Find each price in the table. Multiply when you buy more than one, then add.",
		("%d × %d + %d = %d gold." % [qa, prices[a], prices[b], cost] if qa > 1 else "%d + %d = %d gold." % [prices[a], prices[b], cost])
			+ (" 100 − %d = %d gold change." % [cost, answer] if level == 3 else ""), {"kind": "table", "rows": rows})
	ex.data = {"prices": prices, "a": a, "b": b, "qa": qa, "pay": pay}
	return ex



# --- Helpers -----------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return NAMES[rng.randi_range(0, NAMES.size() - 1)]


## "1 part", "3 parts"
static func _n(n: int, one: String, many: String) -> String:
	return "%d %s" % [n, one if n == 1 else many]


static func _plural(den: int) -> String:
	return str(PARTS.get(den, ["", "parts"])[1])


## `count` different things to buy.
static func _items(rng: RandomNumberGenerator, count: int) -> Array:
	var pool := ITEMS.duplicate()
	K.shuffle(rng, pool)
	return pool.slice(0, count)


## A shape cut into `den` equal parts with `num` shaded (a circle, a strip or grid rectangle, a square's diagonals, a
## hexagon or a triangle, whichever can show it).
static func _fraction_picture(rng: RandomNumberGenerator, num: int, den: int) -> Dictionary:
	var options: Array = [{"kind": "cut_shape", "shape": "circle", "parts": den, "shade": num},
		{"kind": "cut_shape", "shape": "rectangle", "parts": den, "shade": num}]
	if GRID_CUTS.has(den):
		options.append({"kind": "cut_shape", "shape": "rectangle", "way": "grid", "parts": den, "shade": num})
	if den in [2, 4]:
		options.append({"kind": "cut_shape", "shape": "square", "way": "diagonals", "parts": den, "shade": num})
	if den in [2, 3, 6]:
		options.append({"kind": "cut_shape", "shape": "hexagon", "parts": den, "shade": num})
	if den in [2, 3, 4]:
		options.append({"kind": "cut_shape", "shape": "triangle", "parts": den, "shade": num})
	return options[rng.randi_range(0, options.size() - 1)]
