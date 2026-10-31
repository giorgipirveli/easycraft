class_name NumberAnswer
extends RefCounted
## Owner #68 (spec §22.5): the exact value of a number a child typed on the School's pad, or of an answer in the data:
## a whole number (commas allowed, as the data writes big numbers), a decimal, a fraction, with a minus in front. Values
## are reduced fractions [numerator, denominator] (denominator > 0) of whole ints, so 0.5 = 1/2 = 5/10 exactly and
## nothing goes through floats. Anything else is not a number ([]), and never right.

const MAX_DIGITS := 15   # a whole int holds these safely, and a cross-multiplication of two answers stays exact

static var _whole := RegEx.create_from_string("^-?[0-9]+$")
static var _decimal := RegEx.create_from_string("^-?([0-9]*)\\.([0-9]*)$")
static var _fraction := RegEx.create_from_string("^-?([0-9]+)/([0-9]+)$")


## [numerator, denominator] reduced, or [] when `text` is not a number.
static func parse(text: String) -> Array:
	var t := text.strip_edges().replace(",", "")
	var digits := 0
	for ch in t:
		if ch >= "0" and ch <= "9":
			digits += 1
	if t == "" or digits == 0 or digits > MAX_DIGITS:
		return []
	var sign := -1 if t.begins_with("-") else 1
	if _whole.search(t):
		return _reduced(sign * int(t.trim_prefix("-")), 1)
	var d := _decimal.search(t)
	if d:
		var whole := d.get_string(1)
		var part := d.get_string(2)
		if whole == "" and part == "":
			return []
		var den := int(pow(10, part.length()))
		return _reduced(sign * (int(whole) * den + int(part)), den)
	var f := _fraction.search(t)
	if f:
		var den := int(f.get_string(2))
		if den == 0:
			return []
		return _reduced(sign * int(f.get_string(1)), den)
	return []


static func is_number(text: String) -> bool:
	return not parse(text).is_empty()


## True when both are numbers of the same value.
static func equal(a: String, b: String) -> bool:
	var x := parse(a)
	var y := parse(b)
	return not x.is_empty() and not y.is_empty() and int(x[0]) * int(y[1]) == int(y[0]) * int(x[1])


## The value as a float (for sorting and pictures), NAN when not a number.
static func value(text: String) -> float:
	var x := parse(text)
	return NAN if x.is_empty() else float(x[0]) / float(x[1])


static func _reduced(num: int, den: int) -> Array:
	if num == 0:
		return [0, 1]
	var g := gcd(absi(num), den)
	return [num / g, den / g]


static func gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return maxi(a, 1)
