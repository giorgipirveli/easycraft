class_name BabbleRules
extends RefCounted
## Babble voices (M3 Task 21a, research F7: "Pip, Tilly, bots and buddies talk in cute babble, like Animal
## Crossing; tiny buddies squeak, giant ones rumble"), as pure rules. A speaker's line is a few nonsense syllables
## (Audio's &"babble" takes: tools/make_babble_sfx.py; never real words), as many as its words are long, at the
## speaker's own pitch: its kind, its size and a personality from its name. One budget per device, like the
## animals' chorus (owner #50): one line at a time with a gap after it, a speaker rests after talking, nobody
## beyond RADIUS of this device's listener is heard, far ones are quieter; an answer to the child's own tap is
## never held back. BabbleVoices (world/babble_voices.gd) plays them.

const SOUND := &"babble"
const MIN_SYLLABLES := 2
const MAX_SYLLABLES := 7
const LETTERS_PER_SYLLABLE := 7.0
const GAP_MIN := 0.11            # seconds from one syllable to the next
const GAP_MAX := 0.17
const TAIL := 0.18               # the last syllable's length
const RADIUS := VoiceRules.CALL_RADIUS   # blocks from the listener, like the animals' calls
const LINE_GAP := 1.0            # seconds of quiet after a line before the next speaker
const SPEAKER_REST := 4.0        # seconds a speaker waits after talking (unless it answers the child)
const NEAR := 6.0                # this close: a full voice
const BASE_DB := -5.0
const FAR_DB := -7.0             # this much quieter at RADIUS
const NORMAL_SIZE := 3.0         # blocks: a buddy this big talks at the voice's own pitch
const SPREAD := 0.12             # every speaker's own pitch: 1 ± this
const MIN_PITCH := 0.55
const MAX_PITCH := 2.2
## Each kind of speaker's base pitch (buddies as made; pets high and chirpy).
const KINDS := {&"buddy": 1.0, &"bot": 0.95, &"tilly": 1.12, &"giver": 1.0, &"pet": 1.45}

var _busy_until := -INF
var _rest := {}                  # speaker -> when it may talk again


## A speaker's pitch: its kind's, lower the bigger it is (by the square root of its size against NORMAL_SIZE
## blocks), and its own personality (-1..1: ± SPREAD); always between MIN_PITCH and MAX_PITCH.
static func pitch(kind: StringName, size: float, personality: float) -> float:
	var base := float(KINDS.get(kind, KINDS[&"buddy"]))
	var by_size := sqrt(NORMAL_SIZE / maxf(size, 0.05))
	return clampf(base * by_size * (1.0 + SPREAD * clampf(personality, -1.0, 1.0)), MIN_PITCH, MAX_PITCH)


## A speaker's personality from its name or id: -1..1, the same every time.
static func personality(id: String) -> float:
	var h := float(((hash(id) * 2654435761) >> 11) & 0xFFFF) / 65535.0
	return h * 2.0 - 1.0


## How many syllables a line of `text` babbles.
static func syllables(text: String) -> int:
	var n := ceili(text.strip_edges().length() / LETTERS_PER_SYLLABLE)
	return clampi(n, MIN_SYLLABLES, MAX_SYLLABLES)


## When each of `count` syllables starts (seconds from the line's start).
static func schedule(count: int, rng: RandomNumberGenerator) -> Array[float]:
	var out: Array[float] = []
	var t := 0.0
	for i in count:
		out.append(t)
		t += rng.randf_range(GAP_MIN, GAP_MAX)
	return out


## How long a scheduled line lasts.
static func line_seconds(at: Array[float]) -> float:
	return (at.back() if not at.is_empty() else 0.0) + TAIL


## A syllable's volume (dB, before Audio's distance fall-off): quieter when far.
static func volume_db(dist: float) -> float:
	return BASE_DB + FAR_DB * clampf((dist - NEAR) / (RADIUS - NEAR), 0.0, 1.0)


## True when `speaker`, `dist` blocks from the listener, may start a line at `now`; `answer`: it answers the
## child's own tap or words (never held back, but never from beyond RADIUS either).
func may_talk(speaker: String, now: float, dist: float, answer: bool) -> bool:
	if dist > RADIUS:
		return false
	if answer:
		return true
	return now >= _busy_until and now >= float(_rest.get(speaker, -INF))


## `speaker` started a line of `seconds` at `now`.
func talked(speaker: String, now: float, seconds: float) -> void:
	_busy_until = now + seconds + LINE_GAP
	_rest[speaker] = now + seconds + SPEAKER_REST
