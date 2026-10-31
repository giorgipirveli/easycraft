class_name EchoGame
extends RefCounted
## Echo, the alien villages' drum game (owner #86, spec §21f: "an alien village with homes and a game to play"), as
## pure rules: a memory-and-music game like the ones children clap at school. The chief plays a little song on the
## village's four drums (each its own colour and note of the pentatonic scale, BuildNotes); the child hops on the drums
## in the same order. Each round the song is one note longer, from FIRST_LENGTH to LAST_LENGTH notes; the whole song is
## a win. A wrong drum is never a loss: "Not yet! Listen again." and the same round plays again. No timer, no score to
## beat, nothing lost (the fair-fun rules). Hopping on the same drum again (Planet Boing's moss bounces a child who lands)
## counts once: the song never has one drum twice in a row.

const PADS := 4
const FIRST_LENGTH := 2
const LAST_LENGTH := 5

## What a hop did.
const RIGHT := &"right"           # the right drum; the song goes on
const ROUND_DONE := &"round_done" # the round's whole song: the next round is one note longer
const WON := &"won"               # the last round's song: the game is won
const NOT_YET := &"not_yet"       # a wrong drum: the round starts again (the chief plays it again)
const IDLE := &"idle"             # not the child's turn

## The whole song (LAST_LENGTH notes, pads 0..PADS-1, never the same drum twice in a row).
var song: Array[int] = []
## The round's song length now.
var length := FIRST_LENGTH
## How many of this round's notes the child has hopped right.
var at := 0
## The child's turn (the chief is not playing).
var listening := false
var won := false
var misses := 0
var _last := -1


## A new game from `game_seed` (the same seed, the same song).
func start(game_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = game_seed
	song.clear()
	var last := -1
	for i in LAST_LENGTH:
		var pad := rng.randi_range(0, PADS - 2)
		if pad >= last and last >= 0:
			pad += 1   # never the one before (a drum hopped twice in a row is hard to tell from one hop)
		song.append(pad)
		last = pad
	length = FIRST_LENGTH
	at = 0
	listening = false
	won = false
	misses = 0
	_last = -1


## The notes the chief plays this round.
func round_song() -> Array[int]:
	return song.slice(0, length)


## The chief finished playing: the child's turn.
func your_turn() -> void:
	if not won and not song.is_empty():
		listening = true
		at = 0
		_last = -1


## The child hopped on drum `pad`.
func hop(pad: int) -> StringName:
	if not listening or won or pad == _last:
		return IDLE   # (the same drum again: a bounce, counted once)
	_last = pad
	if pad != song[at]:
		misses += 1
		listening = false
		at = 0
		return NOT_YET
	at += 1
	if at < length:
		return RIGHT
	listening = false
	at = 0
	if length >= LAST_LENGTH:
		won = true
		return WON
	length += 1
	return ROUND_DONE


## Which round this is (1 ..) and how many there are.
func round_number() -> int:
	return length - FIRST_LENGTH + 1


static func rounds() -> int:
	return LAST_LENGTH - FIRST_LENGTH + 1


## Drum `pad`'s note: a degree of the pentatonic scale, spread over the drums (BuildNotes.pitch).
static func degree(pad: int) -> int:
	return [3, 5, 7, 9][clampi(pad, 0, PADS - 1)]
