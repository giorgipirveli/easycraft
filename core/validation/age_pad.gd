class_name AgePad
extends RefCounted
## The game's own number pad for "How old are you?" (owner #57: "just window to type age"): no phone keyboard, so it
## works the same on every phone and browser (iPhone browsers open their keyboard only for a tapped HTML box). Up to
## two digits, no leading zero.

const DELETE := "DELETE"
const MAX_DIGITS := 2


## The text after pressing `key` (a digit or DELETE).
static func press(current: String, key: String) -> String:
	if key == DELETE:
		return current.left(current.length() - 1)
	if key.length() != 1 or not key.is_valid_int():
		return current
	if current.is_empty() and key == "0":
		return current
	if current.length() >= MAX_DIGITS:
		return current
	return current + key


static func is_complete(text: String) -> bool:
	return value(text) > 0


static func value(text: String) -> int:
	return int(text) if text.is_valid_int() else 0
