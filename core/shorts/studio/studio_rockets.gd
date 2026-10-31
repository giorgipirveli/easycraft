class_name StudioRockets
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): the rockets a cinematic reel films, built from the missions' real parts
## (RocketParts, block page 32) the way a child builds them on a Launch Site's pad, so a reel never shows a rocket the
## game would not fly: test_reel_studio_rockets.gd runs RocketCheck on each for its mission.
## Cells are the pad's (x and z 0-8, the middle column at 4, 4; y up from the pad), bottom stage first:
## - "moon": three stages. Stage 1: nine kerosene engines under nine tanks, eight fins; a ring of separators. Stage 2:
##   five hydrogen space engines under five tanks (a plus), a separator. Stage 3, the lander: a space engine, a tank,
##   the service module with a solar array, the crew capsule and the nose cone, three landing legs.
## - "lander": the Moon rocket's third stage alone (what lands on the Moon).

const E := BlockIds.ROCKET_ENGINE
const V := BlockIds.SPACE_ENGINE
const T := BlockIds.FUEL_TANK
const N := BlockIds.NOSE_CONE
const C := BlockIds.CREW_CAPSULE
const S := BlockIds.SERVICE_MODULE
const L := BlockIds.LANDING_LEGS
const F := BlockIds.ROCKET_FINS
const X := BlockIds.STAGE_SEPARATOR
const P := BlockIds.SOLAR_ARRAY
const MIDDLE := Vector3i(4, 0, 4)


## Rocket `name`'s cells {Vector3i: block id} (pad coordinates).
static func cells(name: String) -> Dictionary:
	match name:
		"lander":
			return _lander(0)
	return _moon()


## Rocket `name` as the flight takes it (RocketStages.normalize: its stages bottom first).
static func rocket(name: String) -> Dictionary:
	var c := cells(name)
	var check := RocketCheck.check(c, MissionRules.for_world(SpaceRules.MOON))
	return RocketStages.normalize(RocketCheck.description(check, SpaceRules.MOON))


static func _moon() -> Dictionary:
	var c := {}
	_square(c, 0, E)
	_square(c, 1, T)
	_square(c, 2, X)
	for f: Vector3i in [Vector3i(2, 0, 4), Vector3i(6, 0, 4), Vector3i(4, 0, 2), Vector3i(4, 0, 6)]:
		c[f] = F
		c[f + Vector3i(0, 1, 0)] = F
	_plus(c, 3, V)
	_plus(c, 4, T)
	c[MIDDLE + Vector3i(0, 5, 0)] = X
	c.merge(_lander(6))
	return c


## The lander from layer `y`: a space engine with three legs round it, a tank, the service module (a solar array on its
## side), the capsule, the nose.
static func _lander(y: int) -> Dictionary:
	var c := {}
	c[MIDDLE + Vector3i(0, y, 0)] = V
	for leg: Vector3i in [Vector3i(-1, 0, 0), Vector3i(1, 0, 0), Vector3i(0, 0, 1)]:
		c[MIDDLE + leg + Vector3i(0, y, 0)] = L
	c[MIDDLE + Vector3i(0, y + 1, 0)] = T
	c[MIDDLE + Vector3i(0, y + 2, 0)] = S
	c[MIDDLE + Vector3i(-1, y + 2, 0)] = P
	c[MIDDLE + Vector3i(0, y + 3, 0)] = C
	c[MIDDLE + Vector3i(0, y + 4, 0)] = N
	return c


static func _square(c: Dictionary, y: int, id: int) -> void:
	for x in range(3, 6):
		for z in range(3, 6):
			c[Vector3i(x, y, z)] = id


static func _plus(c: Dictionary, y: int, id: int) -> void:
	for d: Vector3i in [Vector3i.ZERO, Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		c[MIDDLE + d + Vector3i(0, y, 0)] = id
