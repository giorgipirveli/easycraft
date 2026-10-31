class_name DragonRules
extends RefCounted
## The Dragon Realm's void (owner feedback #39, spec §14.2a), as pure rules. The realm's islands float over a starry
## void; fall off one and the wind carries you back to the island you fell from: never lost, no knock-out, no
## damage, nothing dropped, in every mode. A body remembers the last spot it stood on solid ground (SafeSpot, at
## most every SAFE_EVERY seconds); once its feet are below RESCUE_Y (under every island: DragonShape.MIN_BOTTOM),
## it goes back there. Animals, pets, bot friends and living buddies come back next to their child (or the world
## spawn); monsters puff away. A universe has a void when its descriptor says `has_void = true` (`void` is a
## GDScript keyword); Monster Wave's arena of it is flat ground, without one. Cosmos (spec §21b.2): a world may draw its
## own line (`void_y`: Venus's cloud city's lies far over its yellow clouds, which a child never reaches) and say its own
## words (`void_words`: a warm breeze there, not the realm's wind).

const RESCUE_Y := 4.0
const SAFE_EVERY := 0.5
const CARRIED_BACK := "Whoosh! The wind carried you back."
## What falls below the line.
const MONSTER := &"monster"
const ANIMAL := &"animal"
const PET := &"pet"
const BOT := &"bot"
const BUDDY := &"buddy"
## What happens to it.
const PUFF := &"puff"
const COME_BACK := &"come_back"
## Where fallen friends land around their child (or the spawn): a ring, each one a different spot.
const AROUND: Array[Vector2] = [Vector2(1.8, 0), Vector2(-1.8, 0), Vector2(0, 1.8), Vector2(0, -1.8),
	Vector2(1.3, 1.3), Vector2(-1.3, -1.3), Vector2(1.3, -1.3), Vector2(-1.3, 1.3)]


## A universe descriptor whose world floats over a void.
static func has_void(descriptor: Object) -> bool:
	return descriptor != null and descriptor.get("has_void") == true


## A world has the void: its universe does and it is not Monster Wave's flat arena.
static func world_has_void(descriptor: Object, arena: bool) -> bool:
	return has_void(descriptor) and not arena


## The line of world `descriptor` (its `void_y`; RESCUE_Y without one).
static func rescue_y(descriptor: Object) -> float:
	var v: Variant = descriptor.get("void_y") if descriptor != null else null
	return float(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) else RESCUE_Y


## What a child hears when carried back in world `descriptor` (its `void_words`; CARRIED_BACK without them).
static func carried_back_words(descriptor: Object) -> String:
	var v: Variant = descriptor.get("void_words") if descriptor != null else null
	return v if v is String and v != "" else CARRIED_BACK


static func fell_into_void(y: float, line: float = RESCUE_Y) -> bool:
	return y < line


## A spot worth remembering: standing on solid ground (a cloud, water or air holds nobody), above the line.
static func is_safe_spot(on_floor: bool, below_id: int, feet: Vector3, line: float = RESCUE_Y) -> bool:
	return on_floor and BlockIds.is_solid(below_id) and feet.y >= line


## Where the wind carries a fallen player: its last safe spot while the block it stood on is still there; else
## that column's ground (y NAN: spawn on the surface) when the column is an island; else home (a broken bridge
## over the void, or no safe spot yet: a game saved in mid-air). `home`: the player's own home (bed or spawn).
static func rescue_target(safe: Vector3, has_safe: bool, still_solid: bool, over_island: bool, home: Vector3) -> Vector3:
	if not has_safe:
		return home
	if still_solid:
		return safe
	if over_island:
		return Vector3(safe.x, NAN, safe.z)
	return home


static func fate(kind: StringName) -> StringName:
	return PUFF if kind == MONSTER else COME_BACK


## Where a fallen friend (animal, pet, bot, buddy) lands: beside its child when the child stands safely (`child_ok`),
## else beside the world spawn's ground; `index` picks the spot of the ring, so several never land on one another.
## A little above the ground: it lands.
static func return_spot(child_feet: Vector3, child_ok: bool, spawn_feet: Vector3, index: int) -> Vector3:
	var at := child_feet if child_ok else spawn_feet
	var o := AROUND[posmod(index, AROUND.size())]
	return Vector3(at.x + o.x, at.y + 1.0, at.z + o.y)


## A body's last safe spot (every body that the wind carries back keeps one).
class SafeSpot:
	extends RefCounted

	var spot := Vector3.ZERO
	var has := false
	var _since := INF

	## One step: true when this spot was remembered now (standing safely, SAFE_EVERY after the last one).
	func note(delta: float, on_floor: bool, below_id: int, feet: Vector3, line: float = DragonRules.RESCUE_Y) -> bool:
		_since += delta
		if not DragonRules.is_safe_spot(on_floor, below_id, feet, line) or _since < DragonRules.SAFE_EVERY:
			return false
		spot = feet
		has = true
		_since = 0.0
		return true
