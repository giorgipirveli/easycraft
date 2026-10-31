class_name CandyRules
extends RefCounted
## The Candy Kingdom's world rules (M3 Task 4, spec §14.1), pure:
## - gumdrops are bouncy: landing on one from a fall (not walking over it) bounces you back up with BOUNCE_KEEP
##   of the landing speed, never higher than BOUNCE_MAX; each bounce is lower, so it settles by itself;
## - sprinkles fall at night under the open sky (not deep in a cave);
## - the kingdom's water is chocolate (WATER blocks shown brown: they flow and swim like water, M2 Task 14):
##   under it the view is chocolate-brown instead of blue.

const BOUNCE_FROM := 5.0          # m/s: landings slower than this (a walk off a step: ~6.9 at 1 block) ...
const BOUNCE_KEEP := 0.75         # ... bounce back with this share of the landing speed
const BOUNCE_MAX := 16.0          # a jump pad's throw (PadRules.LAUNCH_SPEED)
const SPRINKLES_UNDERGROUND := 0.5   # sprinkles stop this far into a cave (AmbienceRules' underground 0..1)
const CHOCOLATE := Color(0.42, 0.23, 0.12)
const CHOCOLATE_FOG := Color(0.3, 0.16, 0.08)
const CHOCOLATE_TINT := Color(0.45, 0.24, 0.1)


## A block that bounces a landing child: the gumdrops, and Planet Boing's moss, jelly and spring caps (owner #55,
## BoingBlocks.BOUNCY).
static func is_gumdrop(id: int) -> bool:
	return id == BlockIds.GUMDROP or id == BlockIds.RED_GUMDROP or BoingBlocks.BOUNCY.has(id)


## How fast a landing at `landing_speed` (m/s down, positive) on a gumdrop throws you back up (0: no bounce).
static func gumdrop_bounce(landing_speed: float) -> float:
	if landing_speed < BOUNCE_FROM:
		return 0.0
	return minf(landing_speed * BOUNCE_KEEP, BOUNCE_MAX)


## Do sprinkles fall now (time of day t) for a player `underground` 0..1 (AmbienceRules)?
static func sprinkles_on(t: float, underground: float) -> bool:
	return DayCycle.is_night(t) and underground < SPRINKLES_UNDERGROUND


## The underwater view (AmbienceRules.mood's) turned chocolate: the fog and the screen tint go brown as far
## as the view is under water (0..1). Out of it nothing changes.
static func chocolate_mood(m: Dictionary, underwater: float) -> Dictionary:
	var w := clampf(underwater, 0.0, 1.0)
	if w <= 0.0:
		return m
	var out := m.duplicate()
	out.fog_color = (m.fog_color as Color).lerp(CHOCOLATE_FOG, w)
	out.tint = Color(CHOCOLATE_TINT, (m.tint as Color).a)
	return out
