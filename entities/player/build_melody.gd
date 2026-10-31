class_name BuildMelody
extends Node
## Building sounds and melody (M3 Task 21c, spec §16): the local player's placed blocks sing. Each block kind has a
## soft note of its own (BuildNotes: a marimba, or a bell for glass, crystal, ice and lights), blocks placed one
## after another in a row climb the pentatonic scale, and the budget (BuildNotes.Melody.may_play) keeps the notes
## from flooding the mix. One note per tap or tool step (a LINE, a FILL, a paste, a stamp, a paint tap), never one
## per cell. The notes play from a small pool of positional players made once (POOL; it never grows, and never
## takes a player from Audio's pools), on the Effects bus at the scale's exact pitch (no random wobble). The "Block
## music" setting (settings.build_notes, on in a new profile) turns them off: the plain pop plays as before.
## A child of the BlockInteractor; only this game's own player places blocks through it.

const POOL := 4
const VOLUME_DB := -6.0
## The name the notes are reported under (Audio.sound_played: owner #50's counting tools and tests).
const SOUND := &"build_note"
const STREAMS := {
	BuildNotes.WOOD: preload("res://assets/audio/sfx/build_note_wood.wav"),
	BuildNotes.BELL: preload("res://assets/audio/sfx/build_note_bell.wav"),
}

## The clock, in milliseconds (tests set their own).
var now_ms: Callable = func() -> int: return Time.get_ticks_msec()
## Notes played and notes the budget held back (tests and diagnostics); the last note's pitch and voice.
var played := 0
var skipped := 0
var last_pitch := 1.0
var last_voice: StringName = &""

var _melody := BuildNotes.Melody.new()
var _players: Array[AudioStreamPlayer3D] = []
var _next := 0


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 6.0
		p.max_distance = Audio.HEARING
		p.bus = Audio.BUS
		add_child(p)
		_players.append(p)


## Is block music on (the setting; on unless turned off)?
static func notes_on() -> bool:
	return bool(Profile.data.settings.get("build_notes", true))


## Something was placed at `at` (a block `id`, a stamp, a tool's whole step with its block): its note, or the plain
## pop when block music is off. True when a note played.
func place(at: Vector3, id: int) -> bool:
	if not notes_on():
		Audio.play(&"place", at)
		return false
	var now := int(now_ms.call())
	var degree := _melody.next(id, Vector3i(at.floor()), now)
	if not _melody.may_play(now):
		skipped += 1
		return false
	var p := _players[_pick()]
	_next = (_players.find(p) + 1) % _players.size()
	last_voice = BuildNotes.voice(id)
	last_pitch = BuildNotes.pitch(degree)
	p.stream = STREAMS[last_voice]
	p.pitch_scale = last_pitch
	p.volume_db = VOLUME_DB
	if p.is_inside_tree():
		p.global_position = at
	p.play()
	played += 1
	Audio.sound_played.emit(SOUND, at, VOLUME_DB)
	return true


func player_count() -> int:
	return _players.size()


func playing_count() -> int:
	var n := 0
	for p in _players:
		n += int(p.playing)
	return n


## A free player from the next one on, else the next one (the oldest in the round).
func _pick() -> int:
	for i in _players.size():
		var k := (_next + i) % _players.size()
		if not _players[k].playing:
			return k
	return _next
