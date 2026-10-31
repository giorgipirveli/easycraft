class_name SchoolSpeech
extends RefCounted
## Owner #68 (spec §22.1): maths as it is said. Lessons and exercises are written for the eye ("3/4", "×", "= ?",
## "5 km") and read aloud by the system's voice (ReadAloud), which would say "3 slash 4" or a date: this turns them into
## words ("3 quarters", "times", "equals what", "5 kilometres"). British words (spec §22.6 ruling 3).

## Denominator -> [one, many].
const PARTS := {2: ["half", "halves"], 3: ["third", "thirds"], 4: ["quarter", "quarters"], 5: ["fifth", "fifths"],
	6: ["sixth", "sixths"], 8: ["eighth", "eighths"], 10: ["tenth", "tenths"], 12: ["twelfth", "twelfths"],
	100: ["hundredth", "hundredths"]}
## A unit after a number -> [one, many].
const UNITS := {"km": ["kilometre", "kilometres"], "cm": ["centimetre", "centimetres"], "mm": ["millimetre", "millimetres"],
	"m": ["metre", "metres"], "kg": ["kilogram", "kilograms"], "g": ["gram", "grams"], "mL": ["millilitre", "millilitres"],
	"L": ["litre", "litres"]}
const SIGNS := [["×", " times "], ["÷", " divided by "], ["≤", " is less than or equal to "],
	["≥", " is greater than or equal to "], [" < ", " is less than "], [" > ", " is greater than "], ["=", " equals "],
	["+", " plus "], ["−", " minus "], [" - ", " minus "], ["°C", " degrees Celsius"], ["°", " degrees"],
	["√", " the square root of "], ["π", "pi"], ["½", "a half"], ["¼", "a quarter"], ["¾", "3 quarters"], ["%", " percent"]]

static var _fraction := RegEx.create_from_string("(\\d+|\\?)/(\\d+)")
static var _unit := RegEx.create_from_string("(\\d|\\?|[½¼¾]) (km|cm|mm|kg|mL|m|g|L)\\b")   # grade 3: "2½ cm"
static var _mixed := RegEx.create_from_string("(\\d)([½¼¾])")   # grade 3's line plots: "2½" is "2 and a half"
static var _blank := RegEx.create_from_string("(^|[\\s(])\\?(?=$|[\\s.,!)])")
static var _spaces := RegEx.create_from_string(" {2,}")
static var _cubic := RegEx.create_from_string("(?:(\\d|\\?) )?\\b(km|cm|mm|m)([²³])")   # "24 cm³" (5.MD.4), "in cm²" (6.G.1)
static var _letter_power := RegEx.create_from_string("\\b([a-z])([²³])")   # grades 6-8: "x²", "r³"
static var _power := RegEx.create_from_string("(\\d)([⁰¹²³⁴⁵⁶⁷⁸⁹]+)")          # grade 5: "10³" (5.NBT.2)
const _SUPERSCRIPTS := "⁰¹²³⁴⁵⁶⁷⁸⁹"


static func spoken(text: String) -> String:
	var t := _replace_powers(_replace_letter_powers(_replace_cubic(_say_codes(text))))
	t = _replace_units(t)
	t = _replace_fractions(t)
	t = _mixed.sub(t, "$1 and $2", true)
	for pair: Array in SIGNS:
		t = t.replace(pair[0], pair[1])
	t = _spaces.sub(t, " ", true).strip_edges()
	if t == "?" or t.ends_with(" ?"):
		t = t.left(-1) + "what?"   # "3 × 4 = ?" asks "3 times 4 equals what?"
	t = _blank.sub(t, "$1what", true)
	return t.replace(" ,", ",").replace(" .", ".").replace("( ", "(")   # "(°C)": "(degrees Celsius)"


static func _replace_fractions(t: String) -> String:
	var out := ""
	var at := 0
	for m in _fraction.search_all(t):
		out += t.substr(at, m.get_start() - at)
		var top := m.get_string(1)
		var den := int(m.get_string(2))
		if top == "?" or not PARTS.has(den):
			out += "%s over %d" % [top, den]
		else:
			out += "%s %s" % [top, PARTS[den][0] if top == "1" else PARTS[den][1]]
		at = m.get_end()
	return out + t.substr(at)


static func _replace_units(t: String) -> String:
	var out := ""
	var at := 0
	for m in _unit.search_all(t):
		var start := m.get_start(2)
		out += t.substr(at, start - at)
		var before := t.substr(0, m.get_start(1) + 1)
		var one := before.ends_with(" 1") or before == "1"
		out += UNITS[m.get_string(2)][0 if one else 1]
		at = m.get_end()
	return out + t.substr(at)


# --- Codes (owner #68, the grade 4 agent: science's "Sending messages with patterns") ------------------------------

static var _signals := RegEx.create_from_string("[•—](?: [•—])*(?: / [•—](?: [•—])*)*")
static var _bits := RegEx.create_from_string("\\b[01]+(?: / [01]+)+\\b")


## Codes are said the way they are sent: "• • • / — —" is "short short short, long long" (only in a text with a •, so a
## dash in a sentence stays), and a picture's rows of 1s and 0s "101 / 011" are "1 0 1, 0 1 1".
static func _say_codes(t: String) -> String:
	if t.contains("•"):
		t = _each_match(_signals, t, func(code: String) -> String:
			return code.replace(" / ", ", ").replace("•", "short").replace("—", "long"))
	return _each_match(_bits, t, func(rows: String) -> String:
		var said: Array[String] = []
		for row in rows.split(" / "):
			said.append(" ".join(row.split("", false)))
		return ", ".join(said))


static func _each_match(re: RegEx, t: String, say: Callable) -> String:
	var out := ""
	var at := 0
	for m in re.search_all(t):
		out += t.substr(at, m.get_start() - at) + str(say.call(m.get_string()))
		at = m.get_end()
	return out + t.substr(at)


## "24 cm³" -> "24 cubic centimetres" (before the plain units).
## "24 cm³" -> "24 cubic centimetres", "in m²" -> "in square metres" (before the plain units).
static func _replace_cubic(t: String) -> String:
	var out := ""
	var at := 0
	for m in _cubic.search_all(t):
		out += t.substr(at, m.get_start(2) - at)
		var one := false
		if m.get_start(1) >= 0:
			var before := t.substr(0, m.get_start(1) + 1)
			one = before.ends_with(" 1") or before == "1"
		out += ("cubic " if m.get_string(3) == "³" else "square ") + UNITS[m.get_string(2)][0 if one else 1]
		at = m.get_end()
	return out + t.substr(at)


## "x²" -> "x squared", "r³" -> "r cubed".
static func _replace_letter_powers(t: String) -> String:
	var out := ""
	var at := 0
	for m in _letter_power.search_all(t):
		out += t.substr(at, m.get_start() - at) + m.get_string(1) + (" squared" if m.get_string(2) == "²" else " cubed")
		at = m.get_end()
	return out + t.substr(at)


## "10³" -> "10 to the power of 3".
static func _replace_powers(t: String) -> String:
	var out := ""
	var at := 0
	for m in _power.search_all(t):
		out += t.substr(at, m.get_start(2) - at)
		var digits := ""
		for ch in m.get_string(2):
			digits += str(_SUPERSCRIPTS.find(ch))
		out += " to the power of " + digits
		at = m.get_end()
	return out + t.substr(at)
