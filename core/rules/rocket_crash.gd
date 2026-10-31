class_name CrashRules
extends RefCounted
## Owner #106 (2026-10-15: "Even the rocket is falling like you and when it crashes down on to earth, some parts break
## and have to rebuild it. But it's random. But not catastrophic like 1 block survived and 99% is damaged"), as pure
## rules. A landing that came down too fast (FlightDescent) crashes; the crew's capsule brings everyone home and the
## rocket falls by the Launch Site and comes back to the pad damaged:
## - damage(): a random share of the rocket's parts breaks, between LEAST and MOST of them (never fewer than 1: that
##   wins for a rocket of 1 or 2 parts; never more than 35% otherwise), seeded per crash so a test can pin it. Which
##   ones: a weighted draw without putting back (WEIGHTS): engines, tanks and fins break most often, the capsule and the
##   parts the crew needs least. Only rocket parts break (RocketParts): a child's other blocks never.
## - words(): what the Mission Board says ("Your rocket crashed: 9 parts broke. Rebuild them: 120 gold.").
## - hearts_after(): where hearts count (Survivor) the child comes home with half of them, never a knock-out, never a
##   heal. The Sandbox has no harm: its cost is the parts (SANDBOX_WORDS).
## - FACT: real landers crashed too (the sources are in docs/devlog/parts/moon-landing.md).

const LEAST := 0.15
const MOST := 0.35
## The same shares in whole percents (integer sums: 0.15 × 20 is 3.0000000000000004 in floats).
const LEAST_PERCENT := 15
const MOST_PERCENT := 35

## How likely each part is to break, against the others (a weight; parts not listed: DEFAULT_WEIGHT). Engines, tanks
## and fins take the hit; the capsule and what keeps the crew going (air and water, power, the legs, the heat shield
## and the parachute) are built tough.
const WEIGHTS := {
	BlockIds.ROCKET_ENGINE: 3.0, BlockIds.SPACE_ENGINE: 3.0, BlockIds.FUEL_TANK: 3.0, BlockIds.ROCKET_FINS: 3.0,
	BlockIds.NOSE_CONE: 2.0, BlockIds.STAGE_SEPARATOR: 2.0,
	BlockIds.CREW_CAPSULE: 1.0, BlockIds.SERVICE_MODULE: 1.0, BlockIds.HEAT_SHIELD: 1.0, BlockIds.PARACHUTE_PACK: 1.0,
	BlockIds.LANDING_LEGS: 1.0, BlockIds.SOLAR_ARRAY: 1.0,
}
const DEFAULT_WEIGHT := 2.0

## Where hearts count (Survivor), once the child is home.
const HEARTS_WORDS := "Home safe, with half your hearts. Rest a little: they come back by themselves."
## The Sandbox: a knock-out costs nothing there (spec §12.15), so its hearts stay whole: the crash costs rocket parts.
const SANDBOX_WORDS := "Home safe! The Sandbox keeps your hearts: only some rocket parts broke."
## A real fact (the notes give the sources): kind, and a second try works.
const FACT := ("Real landers crashed too: Beresheet in 2019 and Luna 25 in 2023. India's lander crashed in 2019, and "
	+ "their next one landed on the Moon in 2023!")


## How many of `n` parts a crash with `seed` breaks.
static func broken_count(n: int, seed: int) -> int:
	if n <= 0:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return _count(n, rng)


## The crash of `rocket` ({Vector3i: block id}; its rocket parts count) with `seed`: {"broken": {Vector3i: id},
## "parts": {id: how many broke}, "count", "gold" (what buying them again costs)}.
static func damage(rocket: Dictionary, seed: int) -> Dictionary:
	var cells: Array[Vector3i] = []
	for c: Variant in rocket:
		if c is Vector3i and RocketParts.is_part(int(rocket[c])):
			cells.append(c)
	cells.sort()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var k := _count(cells.size(), rng)
	var keyed: Array = []   # [key, cell]: the k biggest keys u^(1/w) are a weighted draw without putting back
	for c in cells:
		keyed.append([pow(maxf(rng.randf(), 1e-9), 1.0 / weight(int(rocket[c]))), c])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var broken := {}
	for i in k:
		var c: Vector3i = keyed[i][1]
		broken[c] = int(rocket[c])
	var parts := RocketParts.count(broken)
	return {"broken": broken, "parts": parts, "count": k, "gold": RocketParts.cost(parts)}


static func weight(id: int) -> float:
	return float(WEIGHTS.get(id, DEFAULT_WEIGHT))


## The Mission Board's line: "Your rocket crashed: 9 parts broke. Rebuild them: 120 gold." (`gold` 0: the child's
## spare parts cover them).
static func words(count: int, gold: int) -> String:
	var broke := "1 part broke" if count == 1 else "%d parts broke" % count
	if gold <= 0:
		return "Your rocket crashed: %s. Your spare parts cover %s: BUILD IT FOR ME puts %s back." % [broke,
			"it" if count == 1 else "them", "it" if count == 1 else "them"]
	return "Your rocket crashed: %s. Rebuild %s: %d gold." % [broke, "it" if count == 1 else "them", gold]


## Gold to rebuild: the parts `needed` ({id: count}) beyond what the child `have`s.
static func rebuild_gold(needed: Dictionary, have: Dictionary) -> int:
	return RocketParts.cost(RocketParts.missing(needed, have))


## Hit points after a crash where hearts count: half of `max_hp` (rounded up) at most, never fewer than 1, never more
## than the child had.
static func hearts_after(hp: int, max_hp: int) -> int:
	if hp <= 0:
		return hp
	return maxi(mini(hp, (max_hp + 1) / 2), 1)


static func _count(n: int, rng: RandomNumberGenerator) -> int:
	var lo := maxi((n * LEAST_PERCENT + 99) / 100, 1)
	var hi := maxi((n * MOST_PERCENT) / 100, lo)
	return clampi(roundi(rng.randf_range(LEAST, MOST) * n), lo, hi)
