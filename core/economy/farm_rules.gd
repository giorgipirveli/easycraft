class_name FarmRules
extends RefCounted
## The Gold Farm (spec §5.6, §14.8, §6; M3 Task 10) as pure rules. A Survivor world's owner buys a farm
## from Tilly (PRICE × 2^(u−1), like her other prices) and places it; one per world. If the owner's player
## is inside the farm when they leave or close the game, it makes rate_per_hour × 2^(u−1) gold for the
## time away, capped at cap_hours (12 h for a new farm). Upgrades raise the rate (more workers) and the cap,
## three levels each, at fixed prices. Nothing is random, nothing withers, a clock that goes backwards pays
## nothing and nothing ever takes gold.
##
## A farm is a Dictionary: {pos: Vector3i (the centre cell of its floor), facing: 0..3 (FarmSite), rate:
## 0..3, cap: 0..3, away?: {at: unix seconds when the owner left inside it, server: the server's clock
## was started too}}. {} is no farm; {packed: true, rate, cap} is one the owner picked up to move (the FARM
## item is back in their bag; it keeps its levels). The phone's rule pays exactly like the server's farm_collect
## (server/modules/src/rules/farm_rules.ts), so an online and an offline return pay alike.

const PRICE := 150
const RATES: Array[int] = [20, 30, 40, 50]           # gold an hour in Green Meadows, by rate level
const CAP_HOURS: Array[int] = [12, 16, 20, 24]       # the hours the barn holds, by cap level (the server's max is 24)
const RATE_PRICES: Array[int] = [200, 400, 800]      # the next rate level's price, from level 0
const CAP_PRICES: Array[int] = [150, 300, 600]
const WORKERS: Array[int] = [1, 2, 3, 3]             # farmers working the field, by rate level
const MAX_LEVEL := 3
const HOUR := 3600

const RATE := &"rate"
const CAP := &"cap"

const _MESSAGES := {
	"farm_one": "Your world has a farm already!",
	"farm_owner": "Only the world's owner can have a farm here.",
	"farm_none": "Build your farm first!",
	"farm_top": "Your farm can't grow any more. It's the best!",
	"gold": "You need more gold!",
	"survivor_only": "Farms are for Survivor worlds.",
}


static func wants_farm(mode: StringName) -> bool:
	return mode == ModeRules.SURVIVOR


static func new_farm(pos: Vector3i, facing: int, rate := 0, cap := 0) -> Dictionary:
	return {"pos": pos, "facing": posmod(facing, 4), "rate": _level(rate), "cap": _level(cap)}


## Tilly's price for a farm in universe u.
static func price(universe: int = 1) -> int:
	return UniverseRules.price(PRICE, universe)


static func rate_per_hour(level: int, universe: int = 1) -> int:
	return UniverseRules.gold(RATES[_level(level)], universe)


static func cap_hours(level: int) -> int:
	return CAP_HOURS[_level(level)]


static func workers(rate_level: int) -> int:
	return WORKERS[_level(rate_level)]


## Gold made in `away` seconds: floor(rate × 2^(u−1) × min(away, cap) / 1 h); 0 for no time or a clock
## that went backwards.
static func earned(rate_level: int, cap_level: int, universe: int, away: int) -> int:
	if away <= 0:
		return 0
	var paid := mini(away, cap_hours(cap_level) * HOUR)
	return RATES[_level(rate_level)] * UniverseRules.scale(universe) * paid / HOUR


## What the farm made while its owner was away (the device clock, `now` in unix seconds):
## {gold, away (seconds, never negative), capped}. Nothing without an away record (not inside when
## they left) or when the clock went backwards.
static func welcome(farm: Dictionary, now: int, universe: int) -> Dictionary:
	var out := {"gold": 0, "away": 0, "capped": false}
	if farm.is_empty() or not farm.has("away"):
		return out
	var away := now - int((farm.away as Dictionary).get("at", now))
	if away <= 0:
		return out
	out.away = away
	out.capped = away > cap_hours(int(farm.cap)) * HOUR
	out.gold = earned(int(farm.rate), int(farm.cap), universe, away)
	return out


## The owner left (or the world saved) with their player inside: a copy with the time (and whether the
## server's clock was started for this stay).
static func left_inside(farm: Dictionary, now: int, server: bool) -> Dictionary:
	var f := farm.duplicate()
	f.away = {"at": now, "server": server}
	return f


## The owner is outside the farm: nothing is owed for leaving now.
static func left_outside(farm: Dictionary) -> Dictionary:
	var f := farm.duplicate()
	f.erase("away")
	return f


## After the welcome-back paid: the record is gone, so it pays once.
static func paid(farm: Dictionary) -> Dictionary:
	return left_outside(farm)


static func can_upgrade(farm: Dictionary, kind: StringName) -> bool:
	return not farm.is_empty() and (kind == RATE or kind == CAP) and int(farm[String(kind)]) < MAX_LEVEL


## The next level of `kind` for gold in universe u; 0 = at the top (or not an upgrade).
static func upgrade_price(farm: Dictionary, kind: StringName, universe: int = 1) -> int:
	if not can_upgrade(farm, kind):
		return 0
	var level := int(farm[String(kind)])
	return UniverseRules.price(RATE_PRICES[level] if kind == RATE else CAP_PRICES[level], universe)


## A copy one level up in `kind` (never past the top).
static func upgraded(farm: Dictionary, kind: StringName) -> Dictionary:
	var f := farm.duplicate()
	if can_upgrade(farm, kind):
		f[String(kind)] = int(farm[String(kind)]) + 1
	return f


## Why a player can't buy a farm from Tilly ("" = they can): only the world's owner, and one per world.
static func buy_refusal(is_owner: bool, has_farm: bool) -> String:
	if not is_owner:
		return "farm_owner"
	if has_farm:
		return "farm_one"
	return ""


## Why an upgrade can't happen ("" = it can), a key for message().
static func upgrade_refusal(farm: Dictionary, kind: StringName, gold: int, universe: int, is_owner: bool) -> String:
	if not is_owner:
		return "farm_owner"
	if not standing(farm):
		return "farm_none"
	if not can_upgrade(farm, kind):
		return "farm_top"
	if gold < upgrade_price(farm, kind, universe):
		return "gold"
	return ""


static func message(key: String) -> String:
	return _MESSAGES.get(key, "")


static func welcome_text(gold: int) -> String:
	return Lang.t("Your farm made %s gold!") % CodeRules.thousands(gold)


## farm_collect's "start" payload for this farm in universe u (the server clamps it again).
static func server_start(farm: Dictionary, universe: int) -> Dictionary:
	return {"rate_per_hour": RATES[_level(int(farm.get("rate", 0)))], "universe": UniverseRules.valid(universe),
		"cap_hours": cap_hours(int(farm.get("cap", 0)))}


# --- Saving ---

static func to_save(farm: Dictionary) -> Dictionary:
	if farm.is_empty():
		return {}
	if not standing(farm):
		return packed(farm)
	var p: Vector3i = farm.pos
	var d := {"pos": [p.x, p.y, p.z], "facing": int(farm.facing), "rate": int(farm.rate), "cap": int(farm.cap)}
	if farm.has("away"):
		d.away = (farm.away as Dictionary).duplicate()
	return d


## A saved farm, or {} when the save is broken (the owner keeps their gold; a broken place is no farm).
## Levels are clamped; a broken away record is dropped (it pays nothing).
static func clean(v: Variant) -> Dictionary:
	if not v is Dictionary:
		return {}
	var d: Dictionary = v
	if d.get("packed") is bool and d.packed:
		return packed({"rate": int(clampf(float(d.rate), -1.0, 99.0)) if _whole(d.get("rate")) else 0,
			"cap": int(clampf(float(d.cap), -1.0, 99.0)) if _whole(d.get("cap")) else 0})
	var pos: Variant = d.get("pos")
	if not pos is Array or (pos as Array).size() != 3 or not (pos as Array).all(_whole):
		return {}
	if not _whole(d.get("facing")) or float(d.facing) < 0.0 or float(d.facing) > 3.0:
		return {}
	var f := new_farm(Vector3i(int(pos[0]), int(pos[1]), int(pos[2])), int(d.facing),
		int(clampf(float(d.rate), -1.0, 99.0)) if _whole(d.get("rate")) else 0,
		int(clampf(float(d.cap), -1.0, 99.0)) if _whole(d.get("cap")) else 0)
	var away: Variant = d.get("away")
	if away is Dictionary and _whole((away as Dictionary).get("at")) and float(away.at) >= 0.0 and float(away.at) < 1e12:
		f.away = {"at": int(away.at), "server": away.get("server") is bool and bool(away.server)}
	return f


static func _level(n: int) -> int:
	return clampi(n, 0, MAX_LEVEL)


## A finite whole number (JSON gives floats).
static func _whole(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and float(v) == floorf(float(v)) \
		and absf(float(v)) < 1e15

# --- Moving the farm ---

## The owner picked the farm up to move it: it stands nowhere (the FARM item is back in their bag) and keeps
## its levels; nothing is owed for leaving it.
static func packed(farm: Dictionary) -> Dictionary:
	return {"packed": true, "rate": _level(int(farm.get("rate", 0))), "cap": _level(int(farm.get("cap", 0)))}


## A farm standing in the world (not none, not picked up).
static func standing(farm: Dictionary) -> bool:
	return farm.has("pos")


## The farm placed at `pos`: a picked-up farm keeps its levels, else a new one.
static func placed_again(farm: Dictionary, pos: Vector3i, facing: int) -> Dictionary:
	return new_farm(pos, facing, int(farm.get("rate", 0)), int(farm.get("cap", 0)))
