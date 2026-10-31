class_name BlasterRules
extends RefCounted
## The cartoon blasters as pure rules (M3 Task 14b, spec §13.4): clearly toy-like, never real-world guns;
## hits burst into confetti. One blaster per rarity (§13.2), each with its own ammo: the Foam Blaster
## (common: quick darts), the Snowball Launcher (uncommon: arcing, a small push), the Paint
## Splatter (rare: marks a monster, 30 % slower for 5 s, its mark seen through fog), the Bubble Cannon (epic:
## a monster of level 2 or less floats in a bubble for 4 s, bigger ones are slowed) and the Confetti Rocket
## (legendary: three rockets, a slow reload, each blast hits and pushes everything within 4 blocks). Owner #53:
## a blaster hits as hard as it is hard to get (WeaponStrength: its damage a second is in its rarity's band). A blaster fires a magazine at
## its rate, then reloads (a rest reloads it too). The host checks every shot with the same Magazine and a
## little slack for network jitter. Survivor shots use ammo (bought from Tilly or found); Sandbox never does.

const NONE := &""
const SNOW := &"snow"
const PAINT := &"paint"
const BUBBLE := &"bubble"
const CONFETTI := &"confetti"

## rarity (ItemRarity), its ammo, damage per hit, seconds between shots, shots per magazine, reload
## seconds, speed (m/s), gravity, seconds a shot flies, push (m/s), what a hit does, the area radius (the
## rocket), the shot's look and its sound.
const BLASTERS := {
	ItemIds.FOAM_BLASTER: {"rarity": ItemRarity.COMMON, "ammo": ItemIds.FOAM_DARTS, "damage": 3, "interval": 0.16,
		"magazine": 8, "reload": 1.2, "speed": 30.0, "gravity": 3.0, "life": 1.2, "push": 1.5, "effect": NONE,
		"radius": 0.0, "sound": &"foam_pop"},
	ItemIds.SNOWBALL_LAUNCHER: {"rarity": ItemRarity.UNCOMMON, "ammo": ItemIds.SNOWBALLS, "damage": 9, "interval": 0.45,
		"magazine": 5, "reload": 1.4, "speed": 17.0, "gravity": 14.0, "life": 1.8, "push": 4.5, "effect": SNOW,
		"radius": 0.0, "sound": &"snow_throw"},
	ItemIds.PAINT_SPLATTER: {"rarity": ItemRarity.RARE, "ammo": ItemIds.PAINT_BLOBS, "damage": 12, "interval": 0.35,
		"magazine": 6, "reload": 1.5, "speed": 22.0, "gravity": 7.0, "life": 1.4, "push": 1.0, "effect": PAINT,
		"radius": 0.0, "sound": &"paint_shot"},
	ItemIds.BUBBLE_CANNON: {"rarity": ItemRarity.EPIC, "ammo": ItemIds.BUBBLE_SOAP, "damage": 22, "interval": 0.5,
		"magazine": 3, "reload": 1.2, "speed": 11.0, "gravity": -0.4, "life": 2.2, "push": 0.0, "effect": BUBBLE,
		"radius": 0.0, "sound": &"bubble_shot"},
	ItemIds.CONFETTI_ROCKET: {"rarity": ItemRarity.LEGENDARY, "ammo": ItemIds.PARTY_ROCKETS, "damage": 50, "interval": 0.6,
		"magazine": 3, "reload": 2.4, "speed": 20.0, "gravity": 2.0, "life": 1.8, "push": 0.0, "effect": CONFETTI,
		"radius": 4.0, "sound": &"rocket_whoosh"},
}

## The host accepts a shot after this share of the interval or reload (network jitter, like WeaponRules).
const HOST_SLACK := 0.8
## A shot's sphere: it hits a thing whose body comes this close to its path (plus the thing's radius).
const SHOT_RADIUS := 0.15

# What a hit does.
const BUBBLE_TIME := 4.0          # a small monster floats in its bubble this long
const BUBBLE_MAX_LEVEL := 2       # ... up to this level; bigger ones are only slowed
const BUBBLE_SLOW := 0.5          # × its speed ...
const BUBBLE_SLOW_TIME := 4.0     # ... this long
const BUBBLE_RISE := 1.2          # a bubble floats up this far
const PAINT_SLOW := 0.7           # 30 % slower ...
const PAINT_TIME := 5.0           # ... and marked (seen through fog by everyone) this long
const LIFT := 0.35                # a push also lifts a little (WeaponRules.LIFT)
const AREA_PUSH := 9.0            # the rocket's blast pushes this hard (m/s) ...
const AREA_LIFT := 4.0            # ... and this much up

## Tilly's prices (gold, × 2^(u−1) per universe like everything she sells) by rarity, and the ammo packs:
## [gold, how many]. Owner #53: a rarer weapon never costs less than a commoner one, so the Confetti Rocket costs
## more than the crystal tools (400) and less than the cosmic ones (1200): 350 -> 500. Its rockets come in threes.
const PRICES: Array[int] = [20, 45, 90, 180, 500]
const AMMO_PACKS := {
	ItemIds.FOAM_DARTS: [5, 20], ItemIds.SNOWBALLS: [5, 10], ItemIds.PAINT_BLOBS: [8, 10],
	ItemIds.BUBBLE_SOAP: [8, 6], ItemIds.PARTY_ROCKETS: [18, 3],
}

static var _by_ammo := {}


static func is_blaster(id: int) -> bool:
	return BLASTERS.has(id)


static func is_ammo(id: int) -> bool:
	return AMMO_PACKS.has(id)


## A blaster's numbers, or {} for anything else.
static func stats(id: int) -> Dictionary:
	return BLASTERS.get(id, {})


static func ammo_of(blaster: int) -> int:
	return int(stats(blaster).get("ammo", 0))


## The blaster an ammo item is for, or 0.
static func blaster_of(ammo: int) -> int:
	if _by_ammo.is_empty():
		for b: int in BLASTERS:
			_by_ammo[int(BLASTERS[b].ammo)] = b
	return int(_by_ammo.get(ammo, 0))


## ItemRarity of a blaster or of its ammo, -1 for anything else.
static func rarity(id: int) -> int:
	var b := id if is_blaster(id) else blaster_of(id)
	return int(stats(b).get("rarity", -1))


static func damage(id: int) -> int:
	return int(stats(id).get("damage", 0))


static func interval(id: int) -> float:
	return float(stats(id).get("interval", 0.0))


static func magazine(id: int) -> int:
	return int(stats(id).get("magazine", 0))


static func reload_time(id: int) -> float:
	return float(stats(id).get("reload", 0.0))


static func speed(id: int) -> float:
	return float(stats(id).get("speed", 0.0))


static func gravity(id: int) -> float:
	return float(stats(id).get("gravity", 0.0))


## Seconds a shot flies before it is gone (its range is speed × life).
static func life(id: int) -> float:
	return float(stats(id).get("life", 0.0))


static func effect(id: int) -> StringName:
	return stats(id).get("effect", NONE)


static func area_radius(id: int) -> float:
	return float(stats(id).get("radius", 0.0))


static func sound(id: int) -> StringName:
	return stats(id).get("sound", &"")


static func velocity(id: int, dir: Vector3) -> Vector3:
	var d := dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	return d * speed(id)


## Host check of a requested aim.
static func aim_ok(dir: Vector3) -> bool:
	return dir.is_finite() and dir.length() > 0.001


# --- Hits ---

## Does a bubble trap a monster of this level (else it is only slowed)?
static func bubble_traps(level: int) -> bool:
	return level <= BUBBLE_MAX_LEVEL


## The push of a direct hit, along the shot's flight (dir) and up a little; nothing for a bubble.
static func push(id: int, dir: Vector3) -> Vector3:
	var k := float(stats(id).get("push", 0.0))
	if k <= 0.0:
		return Vector3.ZERO
	var flat := Vector3(dir.x, 0.0, dir.z)
	flat = flat.normalized() if flat.length() > 0.01 else Vector3.FORWARD
	return flat * k + Vector3.UP * (k * LIFT + 1.0)


## Indices of the things ([{pos, radius}]) within `radius` of a blast at `center` (a body touching it counts).
static func area_hits(center: Vector3, things: Array, radius: float) -> Array[int]:
	var out: Array[int] = []
	for i in things.size():
		var t: Dictionary = things[i]
		if center.distance_to(t.pos) <= radius + float(t.get("radius", 0.0)):
			out.append(i)
	return out


## The blast's push on a thing at `to`: away from it on the ground plane, and up.
static func area_push(center: Vector3, to: Vector3) -> Vector3:
	var away := Vector3(to.x - center.x, 0.0, to.z - center.z)
	away = away.normalized() if away.length() > 0.05 else Vector3.ZERO
	return away * AREA_PUSH + Vector3.UP * AREA_LIFT


# --- Ammo and Tilly ---

## Why a shot can't go ("" = it can; "?" = not a blaster). unlimited: Sandbox; count: the ammo owned.
static func ammo_refusal(blaster: int, unlimited: bool, count: int) -> String:
	if not is_blaster(blaster):
		return "?"
	if unlimited or count > 0:
		return ""
	return Lang.t("Out of %s! Tilly sells them, or pop a piñata.") % Lang.t(ItemIds.display_name(ammo_of(blaster)))


## Gold for one purchase from Tilly in universe 1 (0 = not sold).
static func shop_price(id: int) -> int:
	if is_blaster(id):
		return PRICES[rarity(id)]
	if is_ammo(id):
		return int(AMMO_PACKS[id][0])
	return 0


## How many one purchase gives.
static func pack(id: int) -> int:
	return int(AMMO_PACKS[id][1]) if is_ammo(id) else 1


## A blaster's magazine: shots at its rate, then a reload; resting reloads it too. The host keeps one per
## player and blaster with `slack` (HOST_SLACK), so a shot that arrives a little early still counts.
class Magazine:
	extends RefCounted

	var blaster := 0
	var left := 0
	var ready_ms := 0
	var last_ms := -1000000
	var slack := 1.0

	func _init(id: int, host_slack: float = 1.0) -> void:
		blaster = id
		slack = host_slack
		left = BlasterRules.magazine(id)

	func size() -> int:
		return BlasterRules.magazine(blaster)

	func _reload_ms() -> int:
		return int(BlasterRules.reload_time(blaster) * 1000.0 * slack)

	## Fills it once its reload is over, or when it rested that long.
	func refresh(now_ms: int) -> void:
		if left <= 0 and now_ms >= ready_ms:
			left = size()
		elif left < size() and now_ms - last_ms >= _reload_ms():
			left = size()

	func can_fire(now_ms: int) -> bool:
		refresh(now_ms)
		return left > 0 and now_ms >= ready_ms

	## One shot now, if it may: true when it went.
	func fire(now_ms: int) -> bool:
		if not can_fire(now_ms):
			return false
		left -= 1
		last_ms = now_ms
		if left <= 0:
			ready_ms = now_ms + _reload_ms()
		else:
			ready_ms = now_ms + int(BlasterRules.interval(blaster) * 1000.0 * slack)
		return true

	func reloading(now_ms: int) -> bool:
		refresh(now_ms)
		return left <= 0

	## Seconds until the reload is done (0 when it is not reloading).
	func reload_left(now_ms: int) -> float:
		if left > 0 or now_ms >= ready_ms:
			return 0.0
		return (ready_ms - now_ms) / 1000.0
