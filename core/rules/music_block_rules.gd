class_name MusicBlockRules
extends RefCounted
## Owner #110 (VR round 4, idea 7; docs/devlog/parts/vr-ideas-research.md §5.3, the notes docs/devlog/parts/vr-r4-sound.md):
## the music blocks, pure. Two blocks (BlockIds.XYLOPHONE, DRUM; MusicPage): a tap plays them on a phone, the web and a
## PC, and in VR two mallets play them (MusicDirector). The School's Music links: the xylophone's bars are the C major
## scale (C5 D5 E5 F5 G5 A5 B5 C6, each bar's letter shows as it sounds; C D E G A is the pentatonic scale of grade 4's
## "step or leap"), longer bars are lower (grade 4 science: pitch and length), the bongos play rhythms (grade 3's ta,
## ti-ti and rests), and LOOP records four bars of four beats (grade 4: bars, beats and time signatures; ostinato
## layers; grade 5: loops in a music maker).
##
## A voice is a number (a loop's and the network's): 0-7 the xylophone's bars, BONGO_LOW, BONGO_HIGH, SHELL.

const BARS := 8
const NOTES: Array[String] = ["C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6"]
const BONGO_LOW := 8
const BONGO_HIGH := 9
const SHELL := 10
const VOICES := 11
## The drums' own pitches (Hz): the big skin, the small one, the wooden shell's click.
const DRUM_HZ := {BONGO_LOW: 196.0, BONGO_HIGH: 311.0, SHELL: 880.0}
## The bars' colours (a child's xylophone: the rainbow from red to violet, the top C red again; MusicPage draws them).
const BAR_COLORS: Array[Color] = [Color("e8413c"), Color("f08a1c"), Color("f5d032"), Color("5cc44a"),
	Color("23b5a8"), Color("3d7be0"), Color("8e57d6"), Color("e8413c")]
const TONES := "res://assets/audio/sfx/instrument_"
const _FILES := ["xylo_c5", "xylo_d5", "xylo_e5", "xylo_f5", "xylo_g5", "xylo_a5", "xylo_b5", "xylo_c6",
	"bongo_low", "bongo_high", "drum_shell"]

# --- Striking ---
## A mallet's round tip (m): it touches a face this far before its middle reaches it.
const TIP_RADIUS := 0.02
## Slower than this (m/s) a mallet only lies on it; from FULL_SPEED on a hit is as loud as it gets.
const MIN_SPEED := 0.3
const FULL_SPEED := 3.0
## A tap (a phone, the web, a PC, the laser) plays like a hit this fast: a good medium hit.
const TAP_SPEED := 1.6
## The quietest hit's loudness, as a share of the loudest's.
const QUIET := 0.2
## After a hit a mallet strikes again once its tip is this far out of the block (m) and this much later (s).
const REARM := 0.03
const MIN_GAP := 0.07
## Each voice's level (dB) on top of the hit's, and the cap nothing passes (the research: an instrument's volume is
## capped). The tones are rendered to one peak; through Loudness's way (EBU R128, the file looped 7 times; full band and
## through a phone speaker, two 500 Hz high-passes; 2026-10-16) they measured MEASURED (LUFS), the build notes'
## marimba -18.7 / -30.5 (played at -6 dB). VOICE_DB brings every bar's mean of the two to about -22 at a full hit (well
## over the build notes: an instrument is what the child listens to); the bongos are bass a phone barely plays, so
## they stay near the cap (louder in the Quest's speakers and on headphones).
const MEASURED := {0: [-12.5, -17.3], 4: [-13.3, -14.6], 7: [-11.9, -12.4], BONGO_LOW: [-18.4, -36.1],
	BONGO_HIGH: [-19.1, -29.6], SHELL: [-19.7, -20.4]}
const VOICE_DB := [-7.0, -7.3, -7.6, -8.0, -8.3, -8.7, -9.2, -9.8, -1.0, -2.5, -4.0]
const MAX_DB := -1.0
## The drums' buzzes (Hz): low enough to feel, the small skin higher, the shell's click higher still.
const DRUM_BUZZ_HZ := {BONGO_LOW: 60.0, BONGO_HIGH: 95.0, SHELL: 200.0}

# --- Where ---
## In VR the mallets come within this of a music block (m), and LOOP and STOP show on the HUD within LOOP_NEAR.
const MALLET_NEAR := 2.5
const LOOP_NEAR := 4.0
## A loop stops when its player is farther than this from the blocks it plays (a loop never follows a child about).
const LOOP_RANGE := 24.0
## The host plays a friend's note when the friend is this close to the block (m: a tap's reach and its network slack,
## PlacementRules.REACH + REACH_TOLERANCE) ...
const REACH := 12.0
## ... and at most this many of a friend's notes a second (a two-mallet drum roll, never a flood).
const NOTES_PER_SECOND := 16

# --- The loop ---
const TEMPO := 100.0
const BEATS_PER_BAR := 4
const LOOP_BARS := 4
const LOOP_BEATS := 16
const COUNT_IN_BEATS := 4
const MAX_LAYERS := 3
## Notes snap to the nearest half beat (grade 3's ti-ti); a take holds at most MAX_EVENTS notes.
const QUANTUM := 0.5
const MAX_EVENTS := 64


static func is_instrument(id: int) -> bool:
	return id == BlockIds.XYLOPHONE or id == BlockIds.DRUM


## A voice's pitch in Hz (a bar's note, a drum's own pitch).
static func frequency(voice: int) -> float:
	if voice >= 0 and voice < BARS:
		return SchoolSound.frequency(NOTES[voice])
	return float(DRUM_HZ.get(voice, 0.0))


## A bar's letter ("" for the drums).
static func letter(voice: int) -> String:
	return NOTES[voice].left(1) if voice >= 0 and voice < BARS else ""


## A bar's length across the block (m): the lowest the longest.
static func bar_length(voice: int) -> float:
	return lerpf(0.9, 0.55, float(clampi(voice, 0, BARS - 1)) / float(BARS - 1))


## The tone a voice plays ("" for none).
static func tone_file(voice: int) -> String:
	return TONES + str(_FILES[voice]) + ".wav" if voice >= 0 and voice < VOICES else ""


## Where a line from `from` along `dir` (block space: the block is the unit cube) first comes into the block grown by
## `grow` on every side, within `max_t` of dir: {"t", "point" (on the unit cube's face), "face" (its outward normal)};
## {} when it never does, or starts inside.
static func entry(from: Vector3, dir: Vector3, max_t: float, grow := 0.0) -> Dictionary:
	var lo := Vector3.ONE * -grow
	var hi := Vector3.ONE * (1.0 + grow)
	if from.x > lo.x and from.y > lo.y and from.z > lo.z and from.x < hi.x and from.y < hi.y and from.z < hi.z:
		return {}
	var t_in := -INF
	var t_out := INF
	var face := Vector3i.ZERO
	for axis in 3:
		var d := dir[axis]
		if absf(d) < 1e-9:
			if from[axis] < lo[axis] or from[axis] > hi[axis]:
				return {}
			continue
		var t0 := (lo[axis] - from[axis]) / d
		var t1 := (hi[axis] - from[axis]) / d
		var n := Vector3i.ZERO
		n[axis] = -1 if d > 0.0 else 1
		if t0 > t1:
			var s := t0
			t0 = t1
			t1 = s
		if t0 > t_in:
			t_in = t0
			face = n
		t_out = minf(t_out, t1)
	if t_in > t_out or t_in < 0.0 or t_in > max_t:
		return {}
	var p := from + dir * t_in
	return {"t": t_in, "point": p.clamp(Vector3.ZERO, Vector3.ONE), "face": face}


## The voice a strike on `face` at `point` (block space) of block `id` plays, -1 for none. The xylophone: the bar under
## it along x (the frame too: forgiving), the west and east sides their end bars, nothing underneath. The bongos: the
## west half of the top the big low skin, the east half the small high one, the sides the shell.
static func voice_at(id: int, face: Vector3i, point: Vector3) -> int:
	if face == Vector3i.DOWN:
		return -1
	if id == BlockIds.XYLOPHONE:
		if face == Vector3i(-1, 0, 0):
			return 0
		if face == Vector3i(1, 0, 0):
			return BARS - 1
		return clampi(floori(point.x * BARS), 0, BARS - 1)
	if id == BlockIds.DRUM:
		if face != Vector3i.UP:
			return SHELL
		return BONGO_LOW if point.x < 0.5 else BONGO_HIGH
	return -1


static func is_hit(speed: float) -> bool:
	return speed >= MIN_SPEED


## 0 (the softest hit) .. 1 (FULL_SPEED and faster).
static func strength(speed: float) -> float:
	return clampf((speed - MIN_SPEED) / (FULL_SPEED - MIN_SPEED), 0.0, 1.0)


## How loud a hit of `speed` on `voice` plays (dB), capped at MAX_DB.
static func volume_db(voice: int, speed: float) -> float:
	var db := linear_to_db(lerpf(QUIET, 1.0, strength(speed))) + float(VOICE_DB[clampi(voice, 0, VOICES - 1)])
	return minf(db, MAX_DB)


## The hand's buzz for a hit: [amplitude, seconds, frequency Hz]. A bar buzzes two octaves under its note (the same
## letter, low enough for the controller to play), a drum at its own low pitch; harder is stronger; always short.
static func haptic(voice: int, speed: float) -> Array:
	var k := strength(speed)
	var hz: float = frequency(voice) / 4.0 if voice < BARS else float(DRUM_BUZZ_HZ.get(voice, 0.0))
	return [lerpf(0.15, 0.6, k), lerpf(0.03, 0.05, k), hz]


## The host's budget for one friend's notes: `times` holds that friend's recent notes (the call keeps it); true (and
## the note counted) when one more may play at `now` (s).
static func may_play(times: Array, now: float) -> bool:
	while not times.is_empty() and now - float(times[0]) >= 1.0:
		times.pop_front()
	if times.size() >= NOTES_PER_SECOND:
		return false
	times.append(now)
	return true


static func beat_seconds() -> float:
	return 60.0 / TEMPO


static func loop_seconds() -> float:
	return LOOP_BEATS * beat_seconds()


## LOOP: four bars recorded, then played again and again under the child's playing; up to MAX_LAYERS takes stacked.
## Times are the caller's clock in seconds. A note is {"b": its beat in the loop (0 <= b < LOOP_BEATS), "v": voice,
## "c": the block's cell, "db": its loudness}.
class Loop:
	extends RefCounted
	const IDLE := &"idle"
	const COUNT_IN := &"count_in"
	const RECORDING := &"recording"
	const PLAYING := &"playing"
	const NO_TICK := -1000000

	var state: StringName = IDLE
	## The layers playing (each an Array of notes), and the take being recorded.
	var layers: Array = []
	var take: Array = []
	## The loop's beat 0 (s), and the beat (from it) where the take began.
	var origin := 0.0
	var rec_from := 0.0
	var _last := NAN
	var _beat := NO_TICK

	func beat_at(now: float) -> float:
		return (now - origin) / MusicBlockRules.beat_seconds()

	## LOOP pressed at `now`: the first take after a bar's count-in; with layers playing, a new take from the next bar
	## line. False while a take waits or records, or when MAX_LAYERS play.
	func record(now: float) -> bool:
		if state == COUNT_IN or state == RECORDING or layers.size() >= MusicBlockRules.MAX_LAYERS:
			return false
		take = []
		if layers.is_empty():
			origin = now + MusicBlockRules.COUNT_IN_BEATS * MusicBlockRules.beat_seconds()
			rec_from = 0.0
			_last = now
		else:
			var bar := float(MusicBlockRules.BEATS_PER_BAR)
			rec_from = ceilf(beat_at(now) / bar) * bar
		state = COUNT_IN
		_beat = floori(beat_at(now)) - 1
		return true

	## A note played at `now`: into the take (snapped to the nearest QUANTUM) while one waits or records; a note up to
	## half a quantum early is the take's first beat. True when it went in.
	func note(now: float, voice: int, cell: Vector3i, db: float) -> bool:
		if state != COUNT_IN and state != RECORDING:
			return false
		var b := beat_at(now) - rec_from
		if b < -MusicBlockRules.QUANTUM * 0.5 or b >= MusicBlockRules.LOOP_BEATS:
			return false
		if take.size() >= MusicBlockRules.MAX_EVENTS:
			return false
		var at := fposmod(rec_from + snappedf(b, MusicBlockRules.QUANTUM), float(MusicBlockRules.LOOP_BEATS))
		for e: Dictionary in take:
			if is_equal_approx(float(e.b), at) and int(e.v) == voice:
				return false   # the same note twice on one half beat: once
		take.append({"b": at, "v": voice, "c": cell, "db": db})
		return true

	## Time moves on to `now`: the count-in becomes the take, a take of LOOP_BEATS beats becomes a layer (an empty one is
	## dropped). Returns the layers' notes due since the last tick, in order.
	func tick(now: float) -> Array:
		var beat := beat_at(now)
		if state == COUNT_IN and beat >= rec_from:
			state = RECORDING
		if state == RECORDING and beat >= rec_from + MusicBlockRules.LOOP_BEATS:
			if not take.is_empty():
				layers.append(take)
			take = []
			state = PLAYING if not layers.is_empty() else IDLE
		var out: Array = []
		if not layers.is_empty() and not is_nan(_last) and now > _last:
			var a := beat_at(_last)
			var n := float(MusicBlockRules.LOOP_BEATS)
			for layer: Array in layers:
				for e: Dictionary in layer:
					var b0 := float(e.b)
					var k := floorf((a - b0) / n) + 1.0
					while b0 + k * n <= beat:
						if b0 + k * n > a and b0 + k * n >= 0.0:
							out.append({"at": b0 + k * n, "b": b0, "v": e.v, "c": e.c, "db": e.db})
						k += 1.0
			out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.at) < float(y.at))
		_last = now
		return out

	## The beat the metronome ticks now (while a take counts in or records), else NO_TICK; every beat once.
	func beat_tick(now: float) -> int:
		if state != COUNT_IN and state != RECORDING:
			return NO_TICK
		var b := floori(beat_at(now))
		if b <= _beat:
			return NO_TICK
		_beat = b
		return b

	## A bar's first beat (the metronome's louder tick).
	static func accented(beat: int) -> bool:
		return posmod(beat, MusicBlockRules.BEATS_PER_BAR) == 0

	## STOP: every layer and the take gone.
	func stop() -> void:
		layers = []
		take = []
		state = IDLE
		_last = NAN
		_beat = NO_TICK

	## The notes recorded so far (every layer's, and the take's).
	func note_count() -> int:
		var n := take.size()
		for layer: Array in layers:
			n += layer.size()
		return n
