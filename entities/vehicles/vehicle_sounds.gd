class_name VehicleSounds
extends RefCounted
## Owner #109: the cars' sounds (tools/make_car_sfx.py, original procedural work): three horns (a go-kart's and a race
## car's quick "meep meep", a car's two tones, a bus's and a monster truck's deep honk) and the "vroom" of getting into the
## driver's seat go through Audio (its pool, its limits, the effects' volume); the engine's hum and the hover fans' whirr
## are loops each driven car plays itself (Vehicle: the pitch follows its speed), loaded once.

const START := &"car_start"
const HORNS := {CarKinds.SMALL_HORN: &"car_horn_small", CarKinds.HORN: &"car_horn", CarKinds.BIG_HORN: &"car_horn_big"}
const ENGINE := "res://assets/audio/sfx/car_engine.wav"
const HOVER := "res://assets/audio/sfx/hover_hum.wav"

static var _loops := {}


## The horn of a car of `kind` (an Audio sound).
static func horn(kind: StringName) -> StringName:
	return HORNS.get(CarKinds.horn(kind), &"car_horn")


## The loop a driven car of `kind` hums with (the flying cars' fans whirr), or null without its file.
static func engine(kind: StringName) -> AudioStream:
	var path := HOVER if CarKinds.flies(kind) else ENGINE
	if not _loops.has(path):
		_loops[path] = load(path) if ResourceLoader.exists(path) else null
	return _loops[path]
