class_name MusicMix
extends RefCounted
## The cross-fade between music tracks, as pure state (M2 §12.10). Every track has a gain 0..1: the
## wanted one rises and all others fall at 1 / CROSSFADE per second, so a change takes exactly
## MusicRules.CROSSFADE seconds and a change of mind halfway turns around from where it is. The
## gain is heard as an equal-power amplitude (sin), so two tracks halfway through are as loud together
## as one alone. Wanting &"" fades everything out.

const SILENT_DB := -80.0
const SNAP := 0.0001              # a gain this close to its end is there (float steps never add up exactly)

var wanted: StringName = &""
var _gains := {}                  # track -> 0..1


func _init() -> void:
	for track: StringName in MusicRules.TRACKS:
		_gains[track] = 0.0


## A cue beyond the game's tracks (a classical piece, the audio pass), silent until wanted.
func add(cue: StringName) -> void:
	if cue != &"" and not _gains.has(cue):
		_gains[cue] = 0.0


## Forgets a cue that is not wanted (a piece that has faded out).
func remove(cue: StringName) -> void:
	if cue != wanted and not MusicRules.TRACKS.has(cue):
		_gains.erase(cue)


func has(cue: StringName) -> bool:
	return _gains.has(cue)


func want(track: StringName) -> void:
	if track == &"" or _gains.has(track):
		wanted = track


func advance(delta: float, fade: float = MusicRules.CROSSFADE) -> void:
	if not is_finite(delta) or delta <= 0.0:
		return
	var step := delta / maxf(fade, 0.001)
	for track: StringName in _gains:
		var target := 1.0 if track == wanted else 0.0
		var g := move_toward(_gains[track], target, step)
		_gains[track] = target if absf(g - target) < SNAP else g


func gain(track: StringName) -> float:
	return _gains.get(track, 0.0)


func amplitude(track: StringName) -> float:
	return sin(gain(track) * PI * 0.5)


func volume_db(track: StringName) -> float:
	var a := amplitude(track)
	return SILENT_DB if a <= 0.0 else maxf(linear_to_db(a), SILENT_DB)


func is_silent(track: StringName) -> bool:
	return gain(track) <= 0.0
