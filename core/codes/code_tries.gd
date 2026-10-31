class_name CodeTries
extends RefCounted
## The secret-code rate limit (M3 Task 13): MAX_WRONG wrong codes in a row lock the field for
## LOCK_MSEC, so mashing can't guess codes. A right code starts the count again; empty input and
## "already used" are not wrong guesses. Times are milliseconds from any steady clock.

const MAX_WRONG := 5
const LOCK_MSEC := 30_000

var wrong := 0          # wrong codes in a row since the last lock or right code
var _locked_until := 0


func is_locked(now_msec: int) -> bool:
	return now_msec < _locked_until


## Whole seconds left, rounded up (0 when not locked).
func wait_seconds(now_msec: int) -> int:
	return ceili((_locked_until - now_msec) / 1000.0) if is_locked(now_msec) else 0


func record_wrong(now_msec: int) -> void:
	wrong += 1
	if wrong >= MAX_WRONG:
		wrong = 0
		_locked_until = now_msec + LOCK_MSEC


func record_right() -> void:
	wrong = 0
