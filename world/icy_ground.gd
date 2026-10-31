class_name IcyGround
extends RefCounted
## The Frost Giant's icy ground (M3 Task 3, spec §14.1 "freezing stomp rings that make the ground icy"): for
## a few seconds after a stomp the ground in its ring is slippery. A state every game keeps (the stomp's RPC
## adds the ring on every peer, so each game slides its own player, and the host its monsters and animals);
## never a changed block. FrostRules.grip_at reads it.

const ICY_GRIP := 0.2             # as slippery as ice, a little less
const HEIGHT := 2.5               # a ring covers ground this far up or down from its middle

static var _zones: Array = []     # [center: Vector3, radius: float, until: float (seconds)]


## A ring of icy ground round `center` for `seconds` from `now` (seconds).
static func add(center: Vector3, radius: float, seconds: float, now: float) -> void:
	_prune(now)
	_zones.append([center, radius, now + seconds])


## The grip at `pos` now: ICY_GRIP inside a ring that has not melted yet, else 1.
static func grip_at(pos: Vector3, now: float) -> float:
	if _zones.is_empty():
		return 1.0
	for z: Array in _zones:
		if now < float(z[2]) and absf(pos.y - (z[0] as Vector3).y) <= HEIGHT \
				and Vector2(pos.x - z[0].x, pos.z - z[0].z).length() <= float(z[1]):
			return ICY_GRIP
	return 1.0


## Any ring still icy (the view's frost patches, tests).
static func active(now: float) -> bool:
	for z: Array in _zones:
		if now < float(z[2]):
			return true
	return false


static func clear() -> void:
	_zones.clear()


static func _prune(now: float) -> void:
	_zones = _zones.filter(func(z: Array) -> bool: return now < float(z[2]))
