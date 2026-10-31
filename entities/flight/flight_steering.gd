class_name FlightSteering
extends RefCounted
## Steering the rocket (owner #79, spec §25.3: "the child steers (tilt, a gentle turn; the autopilot keeps it safe: never
## a crash, kind corrections)"), as pure rules. `off` is where the target (the green ring on the climb, the Moon, the
## landing pad) is from the rocket's nose, in degrees (x right, y up). The child's stick (keys, a drag; -1..1 each way)
## turns the nose toward it at TURN_RATE. While a steering step runs (`active`) and nobody steers, the aim wanders a
## little (DRIFT_RATE, a new way every DRIFT_CHANGE s: something to do); off the target for AUTOPILOT_AFTER s the
## autopilot brings it back itself, and the child's stick takes the controls back at once. It never gets farther than
## MAX_OFF: the target never leaves the window, nothing is ever missed. Outside steering steps the autopilot flies
## straight. hint(): kind words ("Nudge left to aim at the Moon!", "Right on target!").

const MAX_OFF := 25.0
const TURN_RATE := 35.0           # degrees a second at a full stick
const DRIFT_RATE := 3.0
const DRIFT_CHANGE := 3.5
const ON_TARGET := 4.0
const HELP_AFTER := 2.5           # seconds off target before a hint
const AUTOPILOT_AFTER := 6.0
const AUTOPILOT_RATE := 12.0
const STRAIGHT_RATE := 30.0       # outside steering steps
const PRAISE_AFTER := 0.8         # seconds on target before "Right on target!"

var off := Vector2.ZERO
var active := false
var autopilot := false
var target_name := "the Moon"

var _rng := RandomNumberGenerator.new()
var _drift := Vector2.RIGHT
var _drift_t := 0.0
var _off_t := 0.0
var _on_t := 0.0


func _init(seed: int = 1) -> void:
	_rng.seed = seed


func tick(delta: float, stick: Vector2) -> void:
	var s := stick.limit_length(1.0)
	if not active:
		autopilot = false
		off = off.move_toward(Vector2.ZERO, STRAIGHT_RATE * delta)
		_off_t = 0.0
		_on_t = 0.0
		return
	var steering := s.length() > 0.1
	if steering:
		autopilot = false
		off -= s * TURN_RATE * delta
	elif autopilot:
		off = off.move_toward(Vector2.ZERO, AUTOPILOT_RATE * delta)
	else:
		_drift_t -= delta
		if _drift_t <= 0.0:
			_drift_t = DRIFT_CHANGE
			_drift = Vector2.RIGHT.rotated(_rng.randf() * TAU)
		off += _drift * DRIFT_RATE * delta
	off = off.limit_length(MAX_OFF)
	if on_target():
		_on_t += delta
		_off_t = 0.0
		autopilot = false
	else:
		_on_t = 0.0
		_off_t = 0.0 if steering else _off_t + delta
		if _off_t >= AUTOPILOT_AFTER:
			autopilot = true


func on_target() -> bool:
	return off.length() <= ON_TARGET


## Kind words for now ("" for none).
func hint() -> String:
	if not active:
		return ""
	if autopilot:
		return "Autopilot helps: aiming at %s." % target_name
	if on_target():
		return "Right on target!" if _on_t >= PRAISE_AFTER else ""
	if _off_t < HELP_AFTER:
		return ""
	var way := ""
	if absf(off.x) >= absf(off.y):
		way = "left" if off.x < 0.0 else "right"
	else:
		way = "up" if off.y > 0.0 else "down"
	return "Nudge %s to aim at %s!" % [way, target_name]
