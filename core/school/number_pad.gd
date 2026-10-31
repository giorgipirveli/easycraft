class_name NumberPad
extends RefCounted
## Owner #68 (spec §22.1): the School's own number pad, like the age question's AgePad (owner #57: no phone keyboard,
## so it works the same on every phone and browser). Digits and DELETE always; `.`, `/` and `-` only when the answer
## has one (keys_for), and only where they make sense: one dot, never in a fraction; a slash after a digit, once;
## a minus first.

const DELETE := "DELETE"
const DOT := "."
const SLASH := "/"
const MINUS := "-"
const EXTRAS: Array[String] = [DOT, SLASH, MINUS]
const MAX_CHARS := 9


## The extra keys an answer needs, in the pad's order (DOT, SLASH, MINUS).
static func keys_for(answer: String) -> Array[String]:
	var out: Array[String] = []
	for k in EXTRAS:
		if answer.contains(k):
			out.append(k)
	return out


## The text after pressing `key` (a digit, DELETE or one of `extras`).
static func press(current: String, key: String, extras: Array) -> String:
	if key == DELETE:
		return current.left(current.length() - 1)
	if key.length() == 1 and key >= "0" and key <= "9":
		return current + key if current.length() < MAX_CHARS else current
	if not extras.has(key) or current.length() >= MAX_CHARS:
		return current
	match key:
		DOT:
			if current.contains(DOT) or current.contains(SLASH):
				return current
			return current + "0." if current == "" or current == MINUS else current + DOT
		SLASH:
			if current.contains(SLASH) or current.contains(DOT) or current == "" or not current.right(1).is_valid_int():
				return current
			return current + SLASH
		MINUS:
			return MINUS if current == "" else current
	return current


## What the pad's box shows: "?" for nothing, whole parts grouped by thousands ("472,305", "12,345.67"), unless
## `grouped` is false (a year: "1850").
static func shown(text: String, grouped := true) -> String:
	if text == "":
		return "?"
	if text.contains(SLASH):
		return text
	if not grouped:
		return text
	var sign := MINUS if text.begins_with(MINUS) else ""
	var body := text.trim_prefix(MINUS)
	var whole := body.get_slice(DOT, 0)
	var rest := body.substr(whole.length())
	return sign + group(whole) + rest


## "1234567" -> "1,234,567" (digits only).
static func group(digits: String) -> String:
	var out := ""
	var n := digits.length()
	for i in n:
		if i > 0 and (n - i) % 3 == 0:
			out += ","
		out += digits[i]
	return out
