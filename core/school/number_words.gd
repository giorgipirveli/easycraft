class_name NumberWords
extends RefCounted
## Owner #68: whole numbers in English words for the School (0 … 999,999,999), the British way the game speaks (spec
## §22.6 ruling 3): "three hundred and five", "two thousand and five", no commas.

const _ONES: Array[String] = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
const _TENS: Array[String] = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
const MAX := 999_999_999


static func say(n: int) -> String:
	n = clampi(n, 0, MAX)
	if n == 0:
		return _ONES[0]
	var parts: Array[String] = []
	var millions := int(n / 1_000_000.0)
	var thousands := int(n / 1000.0) % 1000
	var rest := n % 1000
	if millions > 0:
		parts.append(_hundreds(millions) + " million")
	if thousands > 0:
		parts.append(_hundreds(thousands) + " thousand")
	if rest > 0:
		var words := _hundreds(rest)
		if rest < 100 and not parts.is_empty():
			words = "and " + words
		parts.append(words)
	return " ".join(parts)


## 1 … 999 in words.
static func _hundreds(n: int) -> String:
	var h := int(n / 100.0)
	var t := n % 100
	if h == 0:
		return _tens(t)
	if t == 0:
		return _ONES[h] + " hundred"
	return "%s hundred and %s" % [_ONES[h], _tens(t)]


## 1 … 99 in words.
static func _tens(n: int) -> String:
	if n < 20:
		return _ONES[n]
	var tens := _TENS[int(n / 10.0)]
	return tens if n % 10 == 0 else "%s-%s" % [tens, _ONES[n % 10]]
