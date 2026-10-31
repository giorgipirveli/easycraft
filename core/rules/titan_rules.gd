class_name TitanRules
extends RefCounted
## Titan's liquid methane (cosmos, spec §21b.2: "lakes of liquid methane (swim: very floaty)"), pure. Titan's lakes and
## sea are the game's WATER (they swim, flow and splash like water, and like all water in the game never hurt), shown as
## liquid methane in its world (the descriptor's `liquid`, BlockLibrary.set_liquid: an amber, glassy liquid), the view
## under it amber (methane_mood). Very floaty: a swimmer floating at its surface who presses JUMP leaps out like a
## dolphin (LEAP of a jump's speed: in Titan's gravity several blocks up and seconds in the air), the liquid letting the
## leap go for LEAP_COAST, and may leap again after LEAP_COOLDOWN back in it. A game rule, not a real fact: a real person
## would sink in liquid methane (it is about half as dense as water), so no fact the game says is about floating in it.

const METHANE := &"methane"
const LEAP := 0.75               # a leap out of the methane: this share of a jump's speed
const LEAP_COAST := 0.3          # s: the liquid does not brake a leap while the body leaves it
const LEAP_COOLDOWN := 0.6       # s back in the liquid before the next leap
const METHANE_COLOR := Color(0.4, 0.26, 0.1)       # the liquid's dark amber (the water shader's methane_color)
const METHANE_FOG := Color(0.42, 0.28, 0.12)
const METHANE_TINT := Color(0.5, 0.33, 0.12)


## A world's liquid (its descriptor's `liquid`) is floaty methane.
static func floaty(liquid: Variant) -> bool:
	return (liquid is StringName or liquid is String) and StringName(liquid) == METHANE


## Does a swimmer leap out now? In floaty methane, with JUMP held (`up`), floating at the surface (`depth`: the surface
## over the feet, within the float line and AT_SURFACE for a body of `size`), and not `cooling` down from the last leap.
static func leaps(is_floaty: bool, up: bool, depth: float, size: float, cooling: float) -> bool:
	return is_floaty and up and cooling <= 0.0 and depth <= (SwimRules.FLOAT_DEPTH + SwimRules.AT_SURFACE) * size


## How fast a leap throws a swimmer up (m/s), from the player's jump speed.
static func leap_speed(jump_velocity: float) -> float:
	return jump_velocity * LEAP


## The underwater view (AmbienceRules.mood's) under methane: the fog and the screen tint go amber as far as the view is
## under it (0..1). Out of it nothing changes.
static func methane_mood(m: Dictionary, underwater: float) -> Dictionary:
	var w := clampf(underwater, 0.0, 1.0)
	if w <= 0.0:
		return m
	var out := m.duplicate()
	out.fog_color = (m.fog_color as Color).lerp(METHANE_FOG, w)
	out.tint = Color(METHANE_TINT, (m.tint as Color).a)
	return out
