class_name FlyCost
extends RefCounted
## Flying in Survivor (M2 spec §12.7): 10 gold a minute, which the host charges every 6 s of flight
## while a player is in FLY mode. The first 6 s are paid at take-off, and landing never restarts the
## clock, so short hops can't fly for free. With no gold left the player lands gently and FLY is
## refused. Sandbox flies free (ModeRules.FREE_FLY). One meter per player, on the host.

const GOLD_PER_MINUTE := 10
const CHARGE_EVERY := 6.0
const GOLD_PER_CHARGE := 1   # GOLD_PER_MINUTE * CHARGE_EVERY / 60
const REFUSED_MESSAGE := "You need gold to fly! Flying costs 10 gold a minute."
const LANDED_MESSAGE := "Out of gold! Down you go, gently."

var _paid_left := 0.0   # seconds of flight already paid for


## Advances the flight clock by delta; pay(gold: int) -> bool takes the gold. Returns false when a
## charge could not be paid: the player must land.
func tick(delta: float, flying: bool, pay: Callable) -> bool:
	if not flying:
		return true
	if is_finite(delta) and delta > 0.0:
		_paid_left -= delta
	while _paid_left <= 0.0:
		if not pay.call(GOLD_PER_CHARGE):
			_paid_left = 0.0
			return false
		_paid_left += CHARGE_EVERY
	return true


## May a player with `gold` take off in universe u? Always where flying is free.
static func can_take_off(free_fly: bool, gold: int, universe: int = 1) -> bool:
	return free_fly or gold >= charge(universe)


## M3 Task 5 (§4.3: "scaled by universe"): one charge in universe u, GOLD_PER_CHARGE × 2^(u−1).
static func charge(universe: int) -> int:
	return UniverseRules.price(GOLD_PER_CHARGE, universe)


## "You need gold to fly! Flying costs 20 gold a minute." in universe 2.
static func refused_message(universe: int) -> String:
	return Lang.t("You need gold to fly! Flying costs %d gold a minute.") % UniverseRules.price(GOLD_PER_MINUTE, universe)
