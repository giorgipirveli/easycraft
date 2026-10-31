class_name SandstormRules
extends RefCounted
## The Sandstorm Desert's weather as pure rules (M3 Task 2, spec §14.1 "sandstorms that lower
## visibility"). Calm spells and storms take turns, drawn from the world seed (the host keeps the clock);
## a warning comes WARNING seconds before a storm. In a full storm everyone outdoors is half as visible
## to monsters (StealthDirector multiplies the light by visibility()), the fog comes in to half the view
## distance, the sun dims and the screen turns sandy (Ambience applies mood()). Deep under a roof (caves,
## pyramids, a mesa's room) the storm doesn't reach: `underground` 0..1 as AmbienceRules measures it.

const CALM_MIN := 240.0           # seconds of calm between two storms ...
const CALM_MAX := 420.0
const STORM_MIN := 45.0           # ... and of storm
const STORM_MAX := 80.0
const FIRST_CALM := 150.0         # a new visit starts calm for at least this long
const WARNING := 10.0             # "A sandstorm is coming!" this long before it blows
const RATE := 0.3                 # strength per second: a storm blows up (and dies down) over ~3 s
const MIN_VISIBILITY := 0.5       # the brief: × 0.5
const VIEW_FACTOR := 0.5          # the fog's end comes in to half the view distance
const FOG_BEGIN_FACTOR := 0.15
const SUN_FACTOR := 0.7
const SAND_FOG := Color(0.86, 0.7, 0.45)
const SAND_TINT := Color(0.9, 0.68, 0.35, 0.22)

const WARN_TEXT := "A sandstorm is coming! Find shelter!"
const START_TEXT := "Sandstorm! Monsters can't see far either."
const END_TEXT := "The sandstorm is over."

# M3 Task 3: Frostpeak's snowstorms are the same storms in snow: white fog, a whiter screen, their own words
# and wind (SandstormDirector.snow). Visibility, timing and shelter are the same rules.
const SNOW_FOG := Color(0.9, 0.93, 0.97)
const SNOW_TINT := Color(0.96, 0.98, 1.0, 0.32)
const SNOW_WARN_TEXT := "A snowstorm is coming! Find shelter!"
const SNOW_START_TEXT := "Snowstorm! Monsters can't see far either."
const SNOW_END_TEXT := "The snowstorm is over."


## A storm's words and wind: the desert's sand, or Frostpeak's snow.
static func style(snow: bool) -> Dictionary:
	if snow:
		return {"warn": SNOW_WARN_TEXT, "start": SNOW_START_TEXT, "end": SNOW_END_TEXT,
			"wind": "res://assets/audio/sfx/snowstorm.wav"}
	return {"warn": WARN_TEXT, "start": START_TEXT, "end": END_TEXT, "wind": "res://assets/audio/sfx/sandstorm.wav"}


## Storm number n's spell: (calm seconds before it, storm seconds).
static func spell(world_seed: int, n: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(world_seed, n * 7919 + 17))
	var calm := rng.randf_range(CALM_MIN, CALM_MAX)
	var storm := rng.randf_range(STORM_MIN, STORM_MAX)
	return Vector2(calm, storm)


## How visible someone is (a factor on the light) at storm `strength` 0..1, `underground` 0..1.
static func visibility(strength: float, underground: float = 0.0) -> float:
	var s := clampf(strength, 0.0, 1.0) * (1.0 - clampf(underground, 0.0, 1.0))
	return lerpf(1.0, MIN_VISIBILITY, s)


## The storm on top of AmbienceRules.mood's view (the same keys): closer sandy fog, a dimmer sun, a sandy
## tint (snow: white fog and a whiter screen); under water the water's own view wins. `strength` should
## already be scaled by being outdoors.
static func mood(m: Dictionary, strength: float, snow: bool = false) -> Dictionary:
	var s := clampf(strength, 0.0, 1.0)
	if s <= 0.0:
		return m
	var out := m.duplicate()
	out.fog_color = (m.fog_color as Color).lerp(SNOW_FOG if snow else SAND_FOG, s)
	out.fog_end = lerpf(float(m.fog_end), float(m.fog_end) * VIEW_FACTOR, s)
	out.fog_begin = lerpf(float(m.fog_begin), float(m.fog_begin) * FOG_BEGIN_FACTOR, s)
	out.sun = lerpf(float(m.sun), float(m.sun) * SUN_FACTOR, s)
	var water: Color = m.tint
	if water.a < 0.01:
		var tint := SNOW_TINT if snow else SAND_TINT
		out.tint = Color(tint, tint.a * s)
	return out


## One step of the storm's strength towards on (1) or off (0).
static func approach(strength: float, on: bool, delta: float) -> float:
	return move_toward(strength, 1.0 if on else 0.0, RATE * maxf(delta, 0.0))
