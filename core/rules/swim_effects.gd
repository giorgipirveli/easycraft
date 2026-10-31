class_name SwimEffects
extends RefCounted
## When a body's water effects happen (M2 Task 14): a splash as it enters the water (its size from the
## entry speed), ripples around a swimmer or a wader, bubbles from a diver, drips for a moment after
## a swim, wet footsteps and swim strokes. One per body, on every peer, fed with the body's synced
## SwimRules.State and velocity; update() returns the effects due this frame.

const SPLASH_COOLDOWN := 0.6
const RIPPLE_MOVING := 0.3
const RIPPLE_IDLE := 1.1
const BUBBLE_EVERY := 0.45
const STROKE_EVERY := 0.9
const DRIP_TIME := 2.0        # seconds the body drips after climbing out
const WET_TIME := 6.0         # seconds of wet footsteps after leaving the water
const MOVING := 0.5           # m/s

## The strength (0..1) of the last splash.
var splash := 0.0

var _state: int = SwimRules.State.DRY
var _splash_cd := 0.0
var _ripple_t := 0.0
var _bubble_t := 0.0
var _stroke_t := 0.0
var _wet := 0.0
var _soaked := false          # swam since it last left the water: the whole body drips


## &"splash", &"ripple", &"bubbles", &"drips" and &"stroke", as they fall due.
func update(delta: float, state: int, velocity: Vector3) -> Array[StringName]:
	var events: Array[StringName] = []
	_splash_cd = maxf(_splash_cd - delta, 0.0)
	var was := _state
	_state = state
	if state == SwimRules.State.DRY:
		if was != SwimRules.State.DRY:
			_wet = WET_TIME
			if _soaked:
				events.append(&"drips")
			_soaked = false
		_wet = maxf(_wet - delta, 0.0)
		return events
	if state >= SwimRules.State.SWIMMING:
		_soaked = true
	if was == SwimRules.State.DRY:
		var strength := SwimRules.splash_strength(velocity)
		if strength >= SwimRules.SPLASH_MIN and _splash_cd <= 0.0:
			splash = strength
			_splash_cd = SPLASH_COOLDOWN
			events.append(&"splash")
	var moving := Vector2(velocity.x, velocity.z).length() > MOVING or absf(velocity.y) > MOVING
	if state == SwimRules.State.DIVING:
		_bubble_t -= delta
		if _bubble_t <= 0.0:
			_bubble_t = BUBBLE_EVERY
			events.append(&"bubbles")
	else:
		_bubble_t = BUBBLE_EVERY * 0.5   # the first bubbles soon after going under
		_ripple_t -= delta
		if _ripple_t <= 0.0 and (moving or state == SwimRules.State.SWIMMING):
			_ripple_t = RIPPLE_MOVING if moving else RIPPLE_IDLE
			events.append(&"ripple")
	if state >= SwimRules.State.SWIMMING and moving:
		_stroke_t -= delta
		if _stroke_t <= 0.0:
			_stroke_t = STROKE_EVERY
			events.append(&"stroke")
	return events


## Footsteps sound wet while wading and for WET_TIME after leaving the water.
func wet_feet() -> bool:
	return _state == SwimRules.State.WADING or (_state == SwimRules.State.DRY and _wet > 0.0)
