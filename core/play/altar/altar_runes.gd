class_name AltarRunes
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.6's fade, §3.8 "How the voice carries the symbols", rulings
## 10-12, §4.3): the rune line carved on the altar's plaque under the pans, at a stage of the fade, and how Hoot reads it.
## The line changes with every move; every rune says its name when touched; the reading is at most 12 words. Pure.
##
## The stages (the grade sets the start, play moves it: AltarProgress):
## - PICTURES: the crystal's icon and gem dots in fives ("◇ + ●●● = ●●●●● ●●"), read as a description ("A crystal and
##   three gems weigh seven gems.");
## - NUMBERS: numerals ("◇ + 3 = 7"), read in maths words ("A crystal plus three equals seven.");
## - LETTERS: the crystal's rune becomes x, standard notation ("x + 3 = 7"; "x plus three equals seven.");
## - RUNES: the same line, the pans in mist (the fog altars, phase C).
## The crystal is never "c" (ruling 10). Balloons are minus; crystal balloons (wing 7) minus a crystal.

const PICTURES := 1
const NUMBERS := 2
const LETTERS := 3
const RUNES := 4
## The kinds of rune.
const CRYSTAL := "crystal"
const GEMS := "gems"
const PLUS := "plus"
const MINUS := "minus"
const EQUALS := "equals"
const CRYSTAL_ICON := "◇"
const GEM_DOT := "●"
const MINUS_SIGN := "−"

const _ONES: Array[String] = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
const _TENS: Array[String] = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]


## The runes of the line, left pan, the equals sign, right pan: {rune, n, pan, glyph, name} (n: the crystals or gems
## a rune stands for; pan: LEFT, RIGHT, or -1 for the equals sign; glyph: what is carved at this stage; name: what it
## says when touched).
static func tokens(s: AltarState, stage: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append_array(_pan_tokens(s.lc, s.lk, AltarState.LEFT, stage))
	out.append({"rune": EQUALS, "n": 0, "pan": -1, "glyph": "=", "name": "equals"})
	out.append_array(_pan_tokens(s.rc, s.rk, AltarState.RIGHT, stage))
	return out


## The line as text ("x + 3 = 7"; the no-voice words and the tests).
static func line(s: AltarState, stage: int) -> String:
	return " ".join(tokens(s, stage).map(func(t: Dictionary) -> String: return str(t.glyph)))


## How Hoot reads the line (R1 at the pictures stage, R3 after): at most 12 words.
static func say(s: AltarState, stage: int) -> String:
	if stage <= PICTURES:
		var left := _describe(s.lc, s.lk)
		var verb := "weighs" if absi(s.lc) + absi(s.lk) <= 1 else "weigh"
		return _sentence("%s %s %s" % [left, verb, _describe(s.rc, s.rk)])
	return _sentence("%s equals %s" % [_maths(s.lc, s.lk, stage), _maths(s.rc, s.rk, stage)])


## The answer read at the free (R2): "One crystal weighs four gems." ("" while the crystal is not free).
static func answer_say(s: AltarState) -> String:
	if not s.freed():
		return ""
	var w := s.shown_weight()
	if w < 0:
		return "One crystal weighs minus %s." % count_words(-w, "gem")
	return "One crystal weighs %s." % count_words(w, "gem")


## "one gem", "four gems".
static func count_words(n: int, noun: String) -> String:
	return "%s %s%s" % [number_word(n), noun, "" if n == 1 else "s"]


static func number_word(n: int) -> String:
	if n < 0:
		return "minus " + number_word(-n)
	if n < 20:
		return _ONES[n]
	if n < 100:
		var tens := _TENS[n / 10]
		return tens if n % 10 == 0 else "%s-%s" % [tens, _ONES[n % 10]]
	return str(n)


static func _pan_tokens(c: int, k: int, pan: int, stage: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if c == 0 and k == 0:
		out.append({"rune": GEMS, "n": 0, "pan": pan, "glyph": "0", "name": "zero"})
		return out
	if c != 0:
		if c < 0:
			out.append(_sign(MINUS, pan))
		out.append(_crystal(absi(c), pan, stage))
		if k != 0:
			out.append(_sign(PLUS if k > 0 else MINUS, pan))
	elif k < 0:
		out.append(_sign(MINUS, pan))
	if k != 0:
		out.append(_gems(absi(k), pan, stage))
	return out


static func _sign(kind: String, pan: int) -> Dictionary:
	return {"rune": kind, "n": 0, "pan": pan, "glyph": "+" if kind == PLUS else MINUS_SIGN, "name": kind}


static func _crystal(c: int, pan: int, stage: int) -> Dictionary:
	var glyph := ""
	var name := ""
	if stage >= LETTERS:
		glyph = "x" if c == 1 else "%dx" % c
		name = "x" if c == 1 else "%s x" % number_word(c)
	else:
		glyph = CRYSTAL_ICON.repeat(c) if stage <= PICTURES else (CRYSTAL_ICON if c == 1 else "%d%s" % [c, CRYSTAL_ICON])
		name = "crystal" if c == 1 else "%s crystals" % number_word(c)
	return {"rune": CRYSTAL, "n": c, "pan": pan, "glyph": glyph, "name": name}


static func _gems(n: int, pan: int, stage: int) -> Dictionary:
	var glyph := str(n)
	if stage <= PICTURES:
		var groups: Array[String] = []
		var left := n
		while left > 0:
			groups.append(GEM_DOT.repeat(mini(left, 5)))
			left -= 5
		glyph = " ".join(groups)
	return {"rune": GEMS, "n": n, "pan": pan, "glyph": glyph, "name": number_word(n)}


## A pan described at the pictures stage: "a crystal and three gems", "seven gems", "nothing".
static func _describe(c: int, k: int) -> String:
	var parts: Array[String] = []
	if c != 0:
		var noun := "crystal" if c > 0 else "crystal balloon"
		parts.append(("a " + noun) if absi(c) == 1 else count_words(absi(c), noun))
	if k != 0:
		var noun := "gem" if k > 0 else "balloon"
		parts.append(("a " + noun) if absi(k) == 1 else count_words(absi(k), noun))
	return "nothing" if parts.is_empty() else " and ".join(parts)


## A pan in maths words: "a crystal plus three" (numbers), "two x minus one" (letters), "seven", "zero".
static func _maths(c: int, k: int, stage: int) -> String:
	var out := ""
	if c != 0:
		var n := absi(c)
		if stage >= LETTERS:
			out = "x" if n == 1 else "%s x" % number_word(n)
		else:
			out = "a crystal" if n == 1 else "%s crystals" % number_word(n)
		if c < 0:
			out = "minus " + out
		if k != 0:
			out += " %s %s" % ["plus" if k > 0 else "minus", number_word(absi(k))]
		return out
	return number_word(k)


static func _sentence(text: String) -> String:
	if text.begins_with("x"):
		return text + "."
	return text.substr(0, 1).to_upper() + text.substr(1) + "."
