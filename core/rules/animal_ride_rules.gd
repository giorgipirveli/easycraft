class_name AnimalRideRules
extends RefCounted
## Riding a horse or a camel (owner feedback #41, spec §14.19), as pure rules on top of M3 Task 20a's RideRules:
## a tamed horse or camel that got a SADDLE (Tilly's, or the Sandbox's MAGIC row) can be ridden with the RIDE
## button (RideDirector). A horse GALLOPs, a camel TREKs (RideRules.SPEED); a camel keeps its pace in a
## sandstorm, a horse slows. A ridden animal never walks into water or off a drop of more than MAX_DROP blocks
## (nobody takes fall damage, but a child should never be carried off a cliff); getting off is RideRules'
## dismount_spot (beside it, never inside blocks).

const SADDLE := BlockIds.SADDLE
const MAX_DROP := 4
## A horse in a full sandstorm goes this share of its speed; a camel all of it.
const STORM_SLOW := 0.7

const KINDS := {&"horse": RideRules.Kind.GALLOP, &"camel": RideRules.Kind.TREK}
## Where the rider's feet go, in the animal's own space (its feet at y = 0, facing -z): on a horse's back, on
## top of a camel's hump. Matches the saddles of BlockyAnimal.dress_boxes.
const SEATS := {&"horse": Vector3(0, 1.32, 0.02), &"camel": Vector3(0, 1.63, 0.1)}


static func takes_saddle(species: StringName) -> bool:
	return KINDS.has(species)


## What it does when ridden: GALLOP, TREK, or NONE (not a mount, or no saddle yet).
static func kind_of(species: StringName, saddled: bool) -> int:
	return int(KINDS[species]) if saddled and KINDS.has(species) else RideRules.Kind.NONE


static func seat_offset(species: StringName) -> Vector3:
	var size: Vector3 = AnimalRules.SPECIES.get(species, {}).get("size", Vector3.ONE)
	return SEATS.get(species, Vector3(0, size.y, 0))


## Its size in whole blocks (RideRules' mounting reach and getting-off spots).
static func size_blocks(species: StringName) -> Vector3i:
	var size: Vector3 = AnimalRules.SPECIES.get(species, {}).get("size", Vector3.ONE)
	return Vector3i(ceili(size.x), ceili(size.y), ceili(size.z))


## × its speed at sandstorm strength 0..1 (SandstormDirector.strength): a camel is steady.
static func storm_factor(species: StringName, storm: float) -> float:
	if species == &"camel":
		return 1.0
	return lerpf(1.0, STORM_SLOW, clampf(storm, 0.0, 1.0))


## May a ridden animal step into the cell `target` (at its feet)? Never into water, never off a drop of more
## than MAX_DROP; a wall is the body's (it hops a 1-block step, RideRules.wants_hop).
static func can_ride_step(target: Vector3i, block_at: Callable) -> bool:
	if block_at.call(target) == BlockIds.WATER:
		return false
	for d in range(1, MAX_DROP + 2):
		var below: int = block_at.call(target - Vector3i(0, d, 0))
		if below == BlockIds.WATER:
			return false
		if below != BlockIds.AIR:
			return true
	return false
