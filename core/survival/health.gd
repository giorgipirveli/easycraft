class_name Health
extends RefCounted
## A player's hearts (M2 §12.3): 20 HP (10 hearts). After REGEN_DELAY s without damage, 1 HP comes
## back every REGEN_EVERY s. At 0 HP the player is knocked out; revive() brings them back full, with
## PROTECTION s in which nothing hurts. No hunger, thirst or fall damage.

const MAX_HP := 20
const REGEN_DELAY := 5.0
const REGEN_EVERY := 3.0
const PROTECTION := 3.0

var hp := MAX_HP
var _quiet := 0.0          # seconds since the last damage
var _regen := 0.0
var _protected := 0.0


## Returns true when this damage knocked the player out.
func damage(n: int) -> bool:
	if n <= 0 or hp <= 0 or _protected > 0.0:
		return false
	hp = maxi(hp - n, 0)
	_quiet = 0.0
	_regen = 0.0
	return hp == 0


func heal(n: int) -> void:
	if n > 0 and hp > 0:
		hp = mini(hp + n, MAX_HP)


func revive() -> void:
	hp = MAX_HP
	_quiet = 0.0
	_regen = 0.0
	_protected = PROTECTION


## Nothing hurts for at least `seconds` (M2 Task 2: held while a revived player is still on the way home).
func protect(seconds: float) -> void:
	if is_finite(seconds):
		_protected = maxf(_protected, seconds)


func is_knocked_out() -> bool:
	return hp <= 0


func is_protected() -> bool:
	return _protected > 0.0


func tick(delta: float) -> void:
	_protected = maxf(_protected - delta, 0.0)
	if hp <= 0 or hp >= MAX_HP:
		return
	_quiet += delta
	if _quiet < REGEN_DELAY:
		return
	_regen += delta - maxf(REGEN_DELAY - (_quiet - delta), 0.0)
	while _regen >= REGEN_EVERY and hp < MAX_HP:
		_regen -= REGEN_EVERY
		hp += 1


## Hearts shown for hp (half hearts).
static func hearts(points: int) -> float:
	return points / 2.0
