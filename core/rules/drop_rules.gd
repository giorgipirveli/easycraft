class_name DropRules
extends RefCounted
## Surprise drops as pure rules (M3 Task 14b, spec §13.5, the M2 Task 16 hooks). A Party Piñata comes now
## and then: after PINATA_GAP seconds of play (a little more, from the world's seed and its count, so a world
## plays the same way), never while one is still there; it floats down on a parachute 8-30 blocks from a
## player, and 3 hits burst it into supplies: blocks, a potion and blaster ammo. Never gold, never anything
## random for money (§6): what a piñata holds is fixed by the world and its count. In Survivor waves from
## wave 3 one supply balloon drifts in over the Totem and settles low beside it (a sword reaches it); popping
## it gives ammo and a potion.

const PINATA_GAP := 600.0         # seconds of play between two piñatas, at least (10 minutes)
const PINATA_EXTRA := 300.0       # ... and up to this much more
const PINATA_MIN_DISTANCE := 8.0
const PINATA_MAX_DISTANCE := 30.0
const PINATA_TRIES := 8
const PINATA_HEIGHT := 22.0       # it appears this high over the ground
const PINATA_FALL := 1.6          # m/s under its parachute (about 14 s down)
const PINATA_SWAY := 0.5          # it swings this far either way while it falls
const PINATA_HITS := 3
const PINATA_STAY := 300.0        # seconds on the ground; then it floats away (the clock goes on)
const SHARE_RADIUS := 12.0        # every player this close to a burst gets the supplies
const HIT_GAP := 0.25             # two hits count at least this far apart (a rocket's hit and blast are one)

const BALLOON_FROM := 3
const BALLOON_HITS := 1
const BALLOON_DELAY := 8.0        # seconds into the wave before it comes
const BALLOON_START := 16.0       # it comes from this far away ...
const BALLOON_HIGH := 8.0         # ... this high over the Totem's feet
const BALLOON_DRIFT := 14.0       # seconds to be right over the Totem
const BALLOON_SETTLE := 5.0       # then it sinks down beside it
const BALLOON_REST := 3.0         # blocks from the Totem
const BALLOON_REST_HIGH := 1.4    # ... this high: a sword reaches it
const BALLOON_SHARE := 16.0

## Supplies. The blocks come from the M2 Task 16 hook (LootRules' "pinata" table).
const AMMO_AMOUNTS := {ItemIds.FOAM_DARTS: 20, ItemIds.SNOWBALLS: 10, ItemIds.PAINT_BLOBS: 8, ItemIds.BUBBLE_SOAP: 5,
	ItemIds.PARTY_ROCKETS: 2}
const BALLOON_AMMO := 1           # kinds of ammo in a balloon
const PINATA_AMMO := 2            # ... in a piñata


## Seconds of play before the world's piñata number `n` (counted from 0).
static func pinata_gap(world_seed: int, n: int) -> float:
	return PINATA_GAP + float(_mix(world_seed, n, 11) % 1000) / 1000.0 * PINATA_EXTRA


## Is the next piñata due after `clock` seconds of play since the last one? Never while one is there.
static func pinata_due(clock: float, world_seed: int, n: int, has_one: bool) -> bool:
	return not has_one and clock >= pinata_gap(world_seed, n)


## Where piñata `n` might land (x, z) around a player at `near`; each try is another direction.
static func pinata_spot(world_seed: int, n: int, near: Vector3, attempt: int = 0) -> Vector2:
	var a := float(_mix(world_seed, n, 12) % 3600) / 3600.0 * TAU + attempt * TAU / PINATA_TRIES
	var d := lerpf(PINATA_MIN_DISTANCE, PINATA_MAX_DISTANCE, float(_mix(world_seed, n, 13) % 1000) / 1000.0)
	return Vector2(near.x + cos(a) * d, near.z + sin(a) * d)


## Where a piñata that started at `top` is `t` seconds later: floating down, swaying, then on the ground.
static func pinata_point(top: Vector3, ground_y: float, t: float) -> Vector3:
	var y := maxf(ground_y, top.y - PINATA_FALL * maxf(t, 0.0))
	if y <= ground_y:
		return Vector3(top.x, ground_y, top.z)
	return Vector3(top.x + sin(t * 1.3) * PINATA_SWAY, y, top.z + sin(t * 0.9) * PINATA_SWAY * 0.6)


static func pinata_landed(top: Vector3, ground_y: float, t: float) -> bool:
	return top.y - PINATA_FALL * t <= ground_y


## Does a hit at `now` count, the last one having counted at `last` (-1: none yet)?
static func hit_counts(last: float, now: float) -> bool:
	return last < 0.0 or now - last >= HIT_GAP - 0.0001


## What a piñata holds for `key` in universe u: {"gold": 0, "items": [[id, count], ...]}: blocks (LootRules'
## "pinata" table), always a potion, and ammo of PINATA_AMMO kinds. `survivor` changes nothing but is kept for
## LootRules (Sandbox gets the same things; nothing counts there).
static func pinata_loot(key: int, universe: int, survivor: bool) -> Dictionary:
	var base := LootRules.roll(&"pinata", key, universe, survivor)
	var items: Array = []
	for e: Array in base.items:
		if BlockIds.is_valid(int(e[0])):
			items.append(e)
	var rng := RandomNumberGenerator.new()
	rng.seed = key ^ 0x5eed
	items.append([ItemIds.POTIONS[rng.randi() % ItemIds.POTIONS.size()], 1])
	items.append_array(_ammo(rng, PINATA_AMMO))
	return {"gold": 0, "items": items, "rarity": LootRules.best_rarity(items)}


## Survivor waves from wave 3 bring one supply balloon.
static func balloon_released(wave: int, survivor: bool) -> bool:
	return survivor and wave >= BALLOON_FROM


## A balloon's way from afar (angle: where it comes from) over the Totem at `totem` (its feet) to its rest.
static func balloon_path(totem: Vector3, angle: float) -> Dictionary:
	var dir := Vector3(cos(angle), 0.0, sin(angle))
	return {"start": totem + dir * BALLOON_START + Vector3(0, BALLOON_HIGH, 0), "over": totem + Vector3(0, BALLOON_HIGH, 0),
		"rest": totem - dir * BALLOON_REST + Vector3(0, BALLOON_REST_HIGH, 0)}


static func balloon_point(path: Dictionary, t: float) -> Vector3:
	var start: Vector3 = path.start
	var over: Vector3 = path.over
	var rest: Vector3 = path.rest
	if t <= BALLOON_DRIFT:
		var k := clampf(t / BALLOON_DRIFT, 0.0, 1.0)
		return start.lerp(over, k) + Vector3(0, sin(t * 1.7) * 0.25, 0)
	var s := clampf((t - BALLOON_DRIFT) / BALLOON_SETTLE, 0.0, 1.0)
	return over.lerp(rest, smoothstep(0.0, 1.0, s))


## What a supply balloon holds: ammo and a potion.
static func balloon_loot(key: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = key ^ 0xba11
	var items: Array = [[ItemIds.POTIONS[rng.randi() % ItemIds.POTIONS.size()], 1]]
	items.append_array(_ammo(rng, BALLOON_AMMO))
	return {"gold": 0, "items": items, "rarity": LootRules.best_rarity(items)}


static func _ammo(rng: RandomNumberGenerator, kinds: int) -> Array:
	var pool: Array = ItemIds.AMMO.duplicate()
	var out: Array = []
	for i in kinds:
		var id: int = pool.pop_at(rng.randi() % pool.size())
		out.append([id, int(AMMO_AMOUNTS[id])])
	return out


## WorldMeta.drops: the piñata clock (seconds of play since the last one) and how many came.
static func clean_save(v: Variant) -> Dictionary:
	var clock := 0.0
	var count := 0
	if v is Dictionary:
		var c: Variant = (v as Dictionary).get("clock")
		if (c is float or c is int) and is_finite(float(c)) and float(c) >= 0.0:
			clock = float(c)
		var n: Variant = (v as Dictionary).get("count")
		if (n is float or n is int) and is_finite(float(n)) and float(n) >= 0.0:
			count = int(n)
	return {"clock": clock, "count": count}


static func _mix(world_seed: int, n: int, salt: int) -> int:
	return SurpriseRules._mix(world_seed, n, salt)
