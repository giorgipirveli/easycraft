class_name PotionRules
extends RefCounted
## Potions (M2 spec §12.6): one use, drunk with a tap on their hotbar slot. The host decides every
## drink (Session.request_drink; Survivor takes one from the inventory, Sandbox is unlimited) and
## every game then runs the effect on that player (Player.potions, an Effects).
## Moon Jump: jumps 1.8 times as high for 60 s. Invisibility: monsters can't see you for 30 s
## (stealth visibility 0, §12.5). Speed: walking and swimming 1.5 times as fast for 60 s.
## A potion that is still working is not drunk again (a tap by mistake wastes nothing).

## In the order the HUD shows their timers.
const EFFECTS := {
	ItemIds.POTION_JUMP: {"seconds": 60.0, "name": "Moon Jump", "color": Color("8fd8ff")},
	ItemIds.POTION_INVIS: {"seconds": 30.0, "name": "Invisibility", "color": Color("c9b8ff")},
	ItemIds.POTION_SPEED: {"seconds": 60.0, "name": "Speed", "color": Color("ffb43a")},
}
const JUMP_HEIGHT := 1.8        # Moon Jump: jump height x 1.8 (take-off speed x sqrt(1.8))
const SPEED := 1.5


static func is_potion(id: int) -> bool:
	return EFFECTS.has(id)


static func seconds(id: int) -> float:
	return float(EFFECTS[id].seconds) if EFFECTS.has(id) else 0.0


static func effect_name(id: int) -> String:
	return str(EFFECTS[id].name) if EFFECTS.has(id) else ""


static func color(id: int) -> Color:
	return EFFECTS[id].color if EFFECTS.has(id) else Color.WHITE


## Host: why a player may not drink `id` now ("" = they may; "?" = not a potion, say nothing).
## unlimited: Sandbox (nothing is counted); have: how many the player owns (Survivor).
static func refusal(id: int, effects: Effects, unlimited: bool, have: int) -> String:
	if not is_potion(id):
		return "?"
	if effects.is_active(id):
		return Lang.t("%s is still working! %d s left.") % [effect_name(id), ceili(effects.time_left(id))]
	if not unlimited and have <= 0:
		return Lang.t("You have no %s left!") % Lang.t(ItemIds.display_name(id))
	return ""


## The potions working on one player: seconds left per potion. Ticked by the player every physics
## frame (on every game, so the host's monsters and the player's own movement agree).
class Effects:
	extends RefCounted

	var _left := {}   # potion id -> seconds left (> 0)

	## Starts a potion; false when it is not a potion or already working.
	func start(id: int) -> bool:
		if not PotionRules.is_potion(id) or is_active(id):
			return false
		_left[id] = PotionRules.seconds(id)
		return true

	## The host's word on the seconds left (a LAN guest's timer runs a little behind; a late joiner
	## hears it): clamped to the potion's time, a broken number means the full time, 0 ends it.
	func set_left(id: int, seconds: float) -> void:
		if not PotionRules.is_potion(id):
			return
		var full := PotionRules.seconds(id)
		var left := clampf(seconds, 0.0, full) if is_finite(seconds) else full
		if left > 0.0:
			_left[id] = left
		else:
			_left.erase(id)

	func tick(delta: float) -> void:
		if _left.is_empty():
			return
		for id: int in _left.keys():
			_left[id] = float(_left[id]) - delta
			if float(_left[id]) <= 0.0:
				_left.erase(id)

	func is_active(id: int) -> bool:
		return _left.has(id)

	func time_left(id: int) -> float:
		return float(_left.get(id, 0.0))

	## Working potions, in PotionRules.EFFECTS order.
	func active_ids() -> Array[int]:
		var ids: Array[int] = []
		for id: int in PotionRules.EFFECTS:
			if _left.has(id):
				ids.append(id)
		return ids

	func clear() -> void:
		_left.clear()

	## Multiplies the take-off speed of every jump.
	func jump_velocity_factor() -> float:
		return sqrt(PotionRules.JUMP_HEIGHT) if _left.has(ItemIds.POTION_JUMP) else 1.0

	func speed_factor() -> float:
		return PotionRules.SPEED if _left.has(ItemIds.POTION_SPEED) else 1.0

	func is_invisible() -> bool:
		return _left.has(ItemIds.POTION_INVIS)

	## Stealth's visibility factor (§12.5): 0 while invisible.
	func visibility() -> float:
		return 0.0 if is_invisible() else 1.0
