class_name PlayMake
extends RefCounted
## Owner #122 (docs/design/learning-is-play.md §5.1, Make it): a number answer is made with the world's things. A maker
## offers things of exact values (`pieces`: texts NumberAnswer reads), the child puts them on the build, and the made
## value is their exact sum (`total`, never through floats): the response ExerciseCheck referees.
## Makers (PlayBlock.MAKERS), chosen from the exercise (`maker`; a unit's play block may prefer one that fits):
## - tower: unit cubes stacked, for whole numbers to TOWER_MAX;
## - base_ten: base-ten blocks (ones, rods of ten, flats of a hundred, cubes of a thousand, crates beyond) and, for
##   decimals, tenths, hundredths and thousandths;
## - coins: gold coins for an amount of gold; jug: cups poured into a jug for millilitres or litres; scale: weights on a
##   scale for grams or kilograms (whole amounts);
## - fraction: fraction bars (wholes and three sizes of part, so choosing the size is part of it) for a fraction to twelfths;
## - frog: a frog's jumps along a number line, forwards and back below zero, for a negative number;
## - dial: the counting machine's keys (NumberPad's), for any number the others can't make within MAX_PIECES.
## `decompose` makes a right build from the pieces (the worked answer), `ghost_step` one step towards it (the coach's
## ghost), `compare` says whether the build is too little or too much (the world's reaction: the scale tips).

const MAX_PIECES := 40   # the most things on a build (the place stays small: a phone's budget)
const TOWER_MAX := 20
const COINS: Array[int] = [1000, 500, 100, 50, 20, 10, 5, 2, 1]
const CUPS: Array[int] = [1000, 500, 100, 50, 10, 5, 1]
const WEIGHTS: Array[int] = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1]
const FRACTION_SIZES: Array[int] = [2, 3, 4, 5, 6, 8, 10, 12]
const MAX_PLACE := 1_000_000
const MAX_DECIMALS := 3

static var _money := RegEx.create_from_string("\\b(gold|coins?)\\b")
static var _liquid := RegEx.create_from_string("\\b(ml|millilitres?|litres?)\\b")
static var _mass := RegEx.create_from_string("\\b(g|kg|grams?|kilograms?)\\b")


## The maker for an exercise: `preferred` (a unit's play block) when it can make the answer, else the first that can.
static func maker(ex: Dictionary, preferred: String = "") -> String:
	if preferred != "" and PlayBlock.MAKERS.has(preferred) and fits(ex, preferred):
		return preferred
	var a := _answer(ex)
	var v := NumberAnswer.parse(a)
	if v.is_empty():
		return "dial"
	var prompt := str(ex.get("prompt", "")).to_lower()
	var whole := int(v[1]) == 1
	var order: Array[String] = []
	if a.contains("/"):
		order = ["fraction", "base_ten"]
	elif int(v[0]) < 0:
		order = ["frog"]
	elif whole and _money.search(prompt) != null:
		order = ["coins", "tower", "base_ten"]
	elif whole and _liquid.search(prompt) != null:
		order = ["jug", "tower", "base_ten"]
	elif whole and _mass.search(prompt) != null:
		order = ["scale", "tower", "base_ten"]
	else:
		order = ["tower", "base_ten"]
	for m in order:
		if fits(ex, m):
			return m
	return "dial"


## Whether `m` can make the exercise's answer within MAX_PIECES.
static func fits(ex: Dictionary, m: String) -> bool:
	if m == "dial":
		return true
	var a := _answer(ex)
	var v := NumberAnswer.parse(a)
	if v.is_empty():
		return false
	var num := int(v[0])
	var den := int(v[1])
	match m:
		"tower":
			if den != 1 or num < 0 or num > TOWER_MAX:
				return false
		"coins", "jug", "scale":
			if den != 1 or num <= 0:
				return false
		"fraction":
			if num < 0 or den > FRACTION_SIZES[-1]:
				return false
		"base_ten":
			if num < 0 or not _terminates(den, MAX_DECIMALS):
				return false
		"frog":
			if not _terminates(den, 2):
				return false
		_:
			return false
	if num == 0:
		return true
	var build := decompose(a, pieces(ex, m))
	return not build.is_empty() and build.size() <= MAX_PIECES


## The values a maker offers for an exercise, the biggest first (exact texts).
static func pieces(ex: Dictionary, m: String) -> Array[String]:
	var out: Array[String] = []
	var a := _answer(ex)
	var v := NumberAnswer.parse(a)
	if v.is_empty():
		return out
	var mag := absf(float(v[0]) / float(v[1]))
	match m:
		"tower":
			out.append("1")
		"base_ten", "frog":
			var top := 1
			while top * 10 <= mag and top < MAX_PLACE:
				top *= 10
			if top < MAX_PLACE and (m == "base_ten" or top < 1000):
				top *= 10   # one place more than the answer needs: its size is not given away
			var places: Array[String] = []
			var p := top
			while p >= 1:
				places.append(str(p))
				p /= 10
			for d in _decimals(a, int(v[1])):
				places.append("0." + "0".repeat(d - 1) + "1")
			if m == "base_ten":
				out = places
			else:
				out = places.duplicate()
				places.reverse()
				for q in places:
					out.append("-" + q)
		"coins":
			out = _with_one_more(COINS, mag)
		"jug":
			out = _with_one_more(CUPS, mag)
		"scale":
			out = _with_one_more(WEIGHTS, mag)
		"fraction":
			var den := int(v[1])
			var sizes: Array[int] = []
			sizes.append(den if den > 1 else 2)
			var near := FRACTION_SIZES.duplicate()
			near.sort_custom(func(x: int, y: int) -> bool: return absi(x - sizes[0]) < absi(y - sizes[0]) \
				or (absi(x - sizes[0]) == absi(y - sizes[0]) and x < y))
			for s: int in near:
				if sizes.size() >= 3:
					break
				if not sizes.has(s):
					sizes.append(s)
			sizes.sort()
			out.append("1")
			for s in sizes:
				out.append("1/%d" % s)
	return out


## The exact sum of the things on the build, as text: a fraction when any of them is one, else a whole or a decimal.
static func total(placed: Array) -> String:
	var num := 0
	var den := 1
	var fractions := false
	for p: Variant in placed:
		var x := NumberAnswer.parse(str(p))
		if x.is_empty():
			continue
		fractions = fractions or str(p).contains("/")
		num = num * int(x[1]) + int(x[0]) * den
		den *= int(x[1])
		var g := NumberAnswer.gcd(absi(num), den)
		num /= g
		den /= g
	return text_of(num, den, fractions)


## A value as the text the pad would show: "347", "-12", "1.21", "3/4".
static func text_of(num: int, den: int, as_fraction: bool = false) -> String:
	if num == 0:
		return "0"
	if den == 1:
		return str(num)
	if as_fraction or not _terminates(den, 9):
		return "%d/%d" % [num, den]
	var k := 0
	var scale := 1
	while scale % den != 0:
		scale *= 10
		k += 1
	var scaled := absi(num) * (scale / den)
	var digits := str(scaled).pad_zeros(k + 1)
	return ("-" if num < 0 else "") + digits.left(digits.length() - k) + "." + digits.right(k)


## A right build of `target` from `pieces` (biggest first), [] when there is none (or the target is 0).
static func decompose(target: String, offered: Array) -> Array[String]:
	var out: Array[String] = []
	var t := NumberAnswer.parse(target)
	if t.is_empty() or int(t[0]) == 0:
		return out
	var den := int(t[1])
	if offered.has("1/%d" % den) and int(t[0]) > 0:   # fraction bars: wholes, then parts of the answer's own size
		var wholes := int(t[0]) / den if offered.has("1") else 0
		for i in wholes:
			out.append("1")
		for i in int(t[0]) - wholes * den:
			out.append("1/%d" % den)
		return out
	var sign := 1 if int(t[0]) > 0 else -1
	var left := [int(t[0]) * sign, den]   # what is left to make, positive
	var sorted: Array = offered.filter(func(p: Variant) -> bool:
		var x := NumberAnswer.parse(str(p))
		return not x.is_empty() and int(x[0]) * sign > 0)
	sorted.sort_custom(func(x: Variant, y: Variant) -> bool:
		return absf(NumberAnswer.value(str(x))) > absf(NumberAnswer.value(str(y))))
	for p: Variant in sorted:
		var x := NumberAnswer.parse(str(p))
		var pn := absi(int(x[0]))
		var pd := int(x[1])
		while _cmp(pn, pd, int(left[0]), int(left[1])) <= 0 and int(left[0]) > 0:
			out.append(str(p))
			left = _sub(int(left[0]), int(left[1]), pn, pd)
			if out.size() > MAX_PIECES * 4:
				return [] as Array[String]
	return out if int(left[0]) == 0 else ([] as Array[String])


## One step of the coach's ghost towards the answer: {"remove": a piece} when the build has one too many, else
## {"add": the next piece}; {} when the build is right (or there is no way).
static func ghost_step(target: String, offered: Array, placed: Array) -> Dictionary:
	var want := decompose(target, offered)
	var missing: Array = want.duplicate()
	var extra: Array = []
	for p: Variant in placed:
		var i := missing.find(str(p))
		if i >= 0:
			missing.remove_at(i)
		else:
			extra.append(str(p))
	if not extra.is_empty():
		return {"remove": extra[0]}
	if not missing.is_empty():
		return {"add": missing[0]}
	return {}


## -1 when the build makes less than the answer, 1 when more, 0 when the same.
static func compare(placed: Array, ex: Dictionary) -> int:
	var made := NumberAnswer.parse(total(placed))
	var want := NumberAnswer.parse(_answer(ex))
	if want.is_empty() or made.is_empty():
		return 0
	return _cmp(int(made[0]), int(made[1]), int(want[0]), int(want[1]))


## The counting machine's keys (dial): the digits, the extras the answer needs (NumberPad), DELETE.
static func keys(ex: Dictionary) -> Array[String]:
	var out: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
	out.append_array(ExerciseCheck.pad_keys(ex))
	out.append(NumberPad.DELETE)
	return out


static func type_key(current: String, key: String, ex: Dictionary) -> String:
	return NumberPad.press(current, key, ExerciseCheck.pad_keys(ex))


## The unit a maker's things are counted in ("gold", "ml", "g", …; "" for none).
static func unit_word(ex: Dictionary, m: String) -> String:
	var prompt := str(ex.get("prompt", "")).to_lower()
	match m:
		"coins":
			return "gold"
		"jug":
			var l := _liquid.search(prompt)
			return "ml" if l == null or str(l.get_string()).begins_with("m") else "l"
		"scale":
			var g := _mass.search(prompt)
			return "kg" if g != null and str(g.get_string()).begins_with("k") else "g"
	return ""


static func _answer(ex: Dictionary) -> String:
	return str(ex.get("answer", "")).replace(",", "").strip_edges()


## The decimal places a decimal answer needs (1 for tenths …), [] for a whole number.
static func _decimals(a: String, den: int) -> Array[int]:
	var out: Array[int] = []
	var places := 0
	if a.contains("."):
		places = a.get_slice(".", 1).length()
	elif den > 1:
		var scale := 1
		while scale % den != 0 and places < MAX_DECIMALS:
			scale *= 10
			places += 1
	for d in range(1, mini(places, MAX_DECIMALS) + 1):
		out.append(d)
	return out


static func _with_one_more(values: Array[int], mag: float) -> Array[String]:
	var out: Array[String] = []
	var bigger := -1
	for v in values:
		if float(v) <= mag:
			out.append(str(v))
		else:
			bigger = v
	if bigger > 0:
		out.push_front(str(bigger))
	return out


## Whether 1/den ends after at most `places` decimal places (den divides 10^places).
static func _terminates(den: int, places: int) -> bool:
	var scale := 1
	for i in places:
		scale *= 10
	return scale % den == 0


static func _cmp(an: int, ad: int, bn: int, bd: int) -> int:
	var l := an * bd
	var r := bn * ad
	return -1 if l < r else (1 if l > r else 0)


static func _sub(an: int, ad: int, bn: int, bd: int) -> Array:
	var n := an * bd - bn * ad
	var d := ad * bd
	var g := NumberAnswer.gcd(absi(n), d)
	return [n / g, d / g]
