class_name PetEcho
extends RefCounted
## A parrot's words (M3 Task 11): the last few chat lines and quick phrases its own child sent from this
## device, which it squawks back in a bubble. Safety: it never learns another player's words (a parrot
## must never become a way to show someone else's text); the lines stay on this device, the bubble shows
## only here, and nothing about them is ever sent anywhere. The chat filter still applies.

const MAX_LINES := 6
const MAX_LENGTH := 28
const SQUAWK := "Squawk! %s"

var _lines: Array[String] = []


## A line `from_peer` sent; kept only when it is this device's own player (`my_peer`), not a command, and
## clean. True when kept.
func hear_own(text: String, from_peer: int, my_peer: int) -> bool:
	if from_peer == 0 or from_peer != my_peer:
		return false
	var t := ChatRules.clean(text)
	if t == "" or ChatCommands.is_command(t):
		return false
	if not ChatRules.is_quick_phrase(t) and ChatRules.filter_code(t) != "":
		return false
	if t.length() > MAX_LENGTH:
		t = t.substr(0, MAX_LENGTH - 1).strip_edges() + "…"
	_lines.append(t)
	while _lines.size() > MAX_LINES:
		_lines.pop_front()
	return true


func lines() -> Array[String]:
	return _lines.duplicate()


## What it squawks now: one of its lines picked by `roll` (0..1), or "" with none.
func squawk(roll: float) -> String:
	if _lines.is_empty():
		return ""
	return tr(SQUAWK) % _lines[clampi(int(roll * _lines.size()), 0, _lines.size() - 1)]
