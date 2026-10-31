class_name PetPerks
extends RefCounted
## What pets' perks do (M3 Task 11, spec §14.7), as pure rules: a perk works only for a tamed pet near its
## owner. Glow: a cat (and Pip) glows in caves and at night; one shared light goes to the glowing pet
## nearest the player who looks (PetGlow). Coins: a dog pulls the coins within COIN_PULL of it to its owner.
## Bark: a dog barks when a monster comes within BARK_RANGE (once per monster, BARK_GAP apart). Point: a
## parrot points its beak at the nearest secret nobody found within POINT_RANGE, every POINT_EVERY.
## The host decides (PetDirector); every game sees the effects. Which kind has which perk: PetRules.

const NEAR_OWNER := 16.0          # perks work while the pet is this close to its owner (sideways)
const GLOW_RANGE := 24.0          # the light goes to a glowing pet this close to the player who looks
const GLOW_DARK := 0.5            # this far underground (Ambience.underground) counts as a cave
const COIN_PULL := 4.0
const BARK_RANGE := 16.0
const BARK_GAP := 8.0             # seconds between barks
const POINT_RANGE := 24.0
const POINT_EVERY := 15.0
const POINT_HOLD := 2.5           # seconds it holds the pose, beak towards the secret


## A tamed pet (is_pet) whose owner is in the game (owner_pos finite) and within NEAR_OWNER.
static func active(is_pet: bool, pet_pos: Vector3, owner_pos: Vector3) -> bool:
	return is_pet and owner_pos.is_finite() and _flat(pet_pos, owner_pos) <= NEAR_OWNER


## Does a pet of `species` glow now? In a cave (underground ≥ GLOW_DARK) or at night.
static func glows(species: StringName, underground: float, night: bool) -> bool:
	return PetRules.has_perk(species, PetRules.GLOW) and (underground >= GLOW_DARK or night)


## Index of the glowing pet nearest `from` within GLOW_RANGE, or -1.
static func glow_pick(from: Vector3, pets: Array[Vector3]) -> int:
	var best := -1
	var best_d := GLOW_RANGE
	for i in pets.size():
		var d := pets[i].distance_to(from)
		if d <= best_d:
			best_d = d
			best = i
	return best


## Whose a coin at `coin` becomes: the owner of the nearest dog within COIN_PULL (dogs[i] is owned by
## owners[i]), or 0.
static func coin_owner(coin: Vector3, dogs: Array[Vector3], owners: Array[int]) -> int:
	var best := 0
	var best_d := COIN_PULL
	for i in dogs.size():
		var d := dogs[i].distance_to(coin)
		if d <= best_d:
			best_d = d
			best = owners[i]
	return best


## A dog at `dog` and the monsters around ({id: position}): `known` holds the monsters within range it
## barked about. Returns {"bark": bool, "known": the new set}: it barks when one it doesn't know comes
## within BARK_RANGE and its last bark (`last`, seconds) was at least BARK_GAP before `now`. A monster that
## leaves the range is forgotten (coming back is barked at again); one it could not bark at yet stays new.
static func bark(dog: Vector3, monsters: Dictionary, known: Dictionary, now: float, last: float) -> Dictionary:
	var near := {}
	var fresh := false
	for id: Variant in monsters:
		if _flat(monsters[id], dog) <= BARK_RANGE:
			near[id] = true
			if not known.has(id):
				fresh = true
	var barks := fresh and now - last >= BARK_GAP
	if barks:
		return {"bark": true, "known": near}
	var kept := {}
	for id: Variant in near:
		if known.has(id):
			kept[id] = true
	return {"bark": false, "known": kept}


## The nearest of `secrets` (secrets nobody found) within POINT_RANGE of the parrot, or INF.
static func point_target(parrot: Vector3, secrets: Array[Vector3]) -> Vector3:
	var best := Vector3.INF
	var best_d := POINT_RANGE
	for s in secrets:
		var d := s.distance_to(parrot)
		if d <= best_d:
			best_d = d
			best = s
	return best


## The yaw that turns a pet at `from` to face `to` (models face -Z).
static func point_yaw(from: Vector3, to: Vector3) -> float:
	return atan2(-(to.x - from.x), -(to.z - from.z))


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
