class_name SchoolSound
extends RefCounted
## The research's "listen and choose" (docs/design/school-curriculum-research.md §5.3; the music subject): a sound on a
## lesson card or an exercise, made in code (no audio files, nothing to download). Kinds:
## - notes {notes: ["C4", "E4", "G4:2", "-"], beat?}: a tune; a note name (C-B, # or b, octave 2-6), ":n" for n beats
##   (1-4), "-" a beat of rest (grade 7: "-:n", n beats of rest). A soft, plucked tone (a little like a music box). Grade 5 (chords, major and minor):
##   2-4 note names joined by "+" sound together as a chord ("C4+E4+G4:2"), each a little softer so none clips.
## - rhythm {pattern: "x-x-xx--", tempo?}: claps; each letter half a beat, "x" a clap, "-" a rest; tempo 50-180 beats a
##   minute (default 100).
## Grade 6 (the science of sound): any sound may have a `volume` (0.1-1.0, default 1: the amplitude, so 0.5 is a wave
## half as tall), and a tune a `tone` (TONES: the timbre, the same notes with a different mix of harmonics: "plucked" the
## music box above, "pure" one frequency only (like a tuning fork), "bright" every harmonic (like a bowed string or a
## brass instrument), "hollow" the odd harmonics only (like a clarinet); the last three are held, not plucked).
## Grade 7 (a Baroque ground bass, a Classical melody over its accompaniment, a folk drone, balancing the parts of a band):
## a tune may have `parts`, 1-MAX_PARTS more tunes {notes, volume?, tone?} that play at the same time from its start, at
## its beat, each with its own volume and tone (the sound's `volume` scales them all); the sound lasts as long as its
## longest part, and every part is a little softer so the sum never clips (as a chord's notes are).
## problem() checks the data (the content test); stream() makes the AudioStreamWAV a LISTEN button plays.

const RATE := 22050
const BEAT := 0.5                  # s: a note's beat when a tune gives none
const MAX_NOTES := 16
const MAX_CHORD := 4               # notes sounding together ("C4+E4+G4+C5")
const MAX_SECONDS := 8.0
const NAMES := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
const TONES: Array[String] = ["plucked", "pure", "bright", "hollow"]
const MIN_VOLUME := 0.1
const MAX_PARTS := 3
## Each tone's harmonics: [which harmonic, its strength] (the fundamental is 1); the sum's peak is kept near 1.
const HARMONICS := {"plucked": [[1, 1.0], [2, 0.25]], "pure": [[1, 1.0]],
	"bright": [[1, 1.0], [2, 0.5], [3, 0.333], [4, 0.25], [5, 0.2], [6, 0.167], [7, 0.143], [8, 0.125]],
	"hollow": [[1, 1.0], [3, 0.333], [5, 0.2], [7, 0.143], [9, 0.111]]}
const TONE_GAIN := {"plucked": 1.0, "pure": 1.0, "bright": 0.62, "hollow": 0.9}

static var _note := RegEx.create_from_string("^([A-G])([#b]?)([2-6])(?::([1-4]))?$")


## A note name's pitch in Hz (A4 = 440), 0 for anything else.
static func frequency(name: String) -> float:
	var m := _note.search(name.split(":")[0])
	if m == null:
		return 0.0
	var semis := int(NAMES[m.get_string(1)]) + (1 if m.get_string(2) == "#" else -1 if m.get_string(2) == "b" else 0)
	var midi := 12 * (int(m.get_string(3)) + 1) + semis
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


## "" when `d` can be played; otherwise what is wrong.
static func problem(d: Variant) -> String:
	if not d is Dictionary:
		return "a sound is a dictionary"
	match str((d as Dictionary).get("kind", "")):
		"notes":
			var why := _tune_problem(d.get("notes"))
			if why != "":
				return why
			if d.has("parts"):
				var parts: Variant = d.parts
				if not parts is Array or (parts as Array).is_empty() or (parts as Array).size() > MAX_PARTS:
					return "a tune has 1-%d parts" % MAX_PARTS
				for part: Variant in parts:
					if not part is Dictionary:
						return "a part is a tune {notes, volume?, tone?}"
					why = _tune_problem((part as Dictionary).get("notes"))
					if why != "":
						return "a part: %s" % why
					if part.has("volume") and (typeof(part.volume) not in [TYPE_INT, TYPE_FLOAT] \
							or float(part.volume) < MIN_VOLUME or float(part.volume) > 1.0):
						return "a part's volume is %.1f-1.0" % MIN_VOLUME
					if part.has("tone") and not TONES.has(str(part.tone)):
						return "a part's tone is one of %s" % [TONES]
		"rhythm":
			var p: Variant = d.get("pattern")
			if not p is String or str(p) == "" or str(p).length() > 32 or not str(p).contains("x"):
				return "a rhythm is a pattern of x and - (up to 32)"
			for ch in str(p):
				if not ch in ["x", "-"]:
					return "a rhythm has only x (a clap) and - (a rest)"
			var t: Variant = d.get("tempo", 100)
			if typeof(t) not in [TYPE_INT, TYPE_FLOAT] or float(t) < 50.0 or float(t) > 180.0:
				return "a tempo is 50-180 beats a minute"
		_:
			return "a sound is notes or a rhythm"
	if d.has("parts") and str(d.kind) != "notes":
		return "only a tune has parts"
	if d.has("volume") and (typeof(d.volume) not in [TYPE_INT, TYPE_FLOAT] or float(d.volume) < MIN_VOLUME \
			or float(d.volume) > 1.0):
		return "a volume is %.1f-1.0" % MIN_VOLUME
	if d.has("tone") and (str(d.kind) != "notes" or not TONES.has(str(d.tone))):
		return "a tune's tone is one of %s" % [TONES]
	if duration(d) > MAX_SECONDS:
		return "a sound lasts at most %d seconds" % int(MAX_SECONDS)
	return ""


## Seconds the sound lasts.
static func duration(d: Dictionary) -> float:
	if str(d.get("kind", "")) == "rhythm":
		return str(d.get("pattern", "")).length() * 0.5 * 60.0 / float(d.get("tempo", 100))
	var beats := _beats(d.get("notes", []))
	var parts: Variant = d.get("parts", [])
	if parts is Array:
		for part: Variant in parts:
			if part is Dictionary:
				beats = maxi(beats, _beats((part as Dictionary).get("notes", [])))
	return beats * float(d.get("beat", BEAT))


static func _beats(notes: Variant) -> int:
	var beats := 0
	if notes is Array:
		for n: Variant in notes:
			var parts := str(n).split(":")
			beats += int(parts[1]) if parts.size() > 1 else 1
	return beats


## "" when `notes` is a tune's notes.
static func _tune_problem(notes: Variant) -> String:
	if not notes is Array or (notes as Array).is_empty() or (notes as Array).size() > MAX_NOTES:
		return "a tune has 1-%d notes" % MAX_NOTES
	for n: Variant in notes:
		if not n is String or (n != "-" and not n.begins_with("-:") and not _is_note_or_chord(n)) \
				or (n.begins_with("-:") and _note.search("C4" + n.substr(1)) == null):
			return "'%s' is not a note (C4, F#3, Bb4:2, - or -:2 for a rest, C4+E4+G4:2 a chord)" % str(n)
	return ""


## The sound as a 16-bit mono stream (null when problem() finds something wrong).
static func stream(d: Variant) -> AudioStreamWAV:
	if problem(d) != "":
		return null
	var samples := PackedFloat32Array()
	samples.resize(int(ceilf(duration(d) * RATE)))
	samples.fill(0.0)
	var volume := float(d.get("volume", 1.0))
	if str(d.kind) == "rhythm":
		var step := 0.5 * 60.0 / float(d.get("tempo", 100))
		var pattern := str(d.pattern)
		for i in pattern.length():
			if pattern[i] == "x":
				_clap(samples, int(i * step * RATE), step, volume)
	else:
		var beat := float(d.get("beat", BEAT))
		var parts: Array = d.get("parts", [])
		# Every voice softer when parts play together (0.61 for two, 0.5 for three, 0.43 for four), as a chord's notes.
		var together := 1.0 / sqrt((parts.size() + 1) * 1.35) if not parts.is_empty() else 1.0
		_tune(samples, d.notes, beat, str(d.get("tone", "plucked")), volume * together)
		for part: Dictionary in parts:
			_tune(samples, part.notes, beat, str(part.get("tone", "plucked")),
				volume * together * float(part.get("volume", 1.0)))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


## A tune's notes one after another from the start, `gain` for each (a chord's notes softer still).
static func _tune(samples: PackedFloat32Array, notes: Array, beat: float, tone: String, gain: float) -> void:
	var at := 0.0
	for n: String in notes:
		var parts := n.split(":")
		var beats := int(parts[1]) if parts.size() > 1 else 1
		if parts[0] != "-":
			var chord := parts[0].split("+")
			for name in chord:   # a chord: its notes together, each softer (0.61, 0.5, 0.43 of a note alone)
				_tone(samples, int(at * RATE), beats * beat, frequency(name), gain * (1.0 / sqrt(float(chord.size()) \
					* 1.35) if chord.size() > 1 else 1.0), tone)
		at += beats * beat


## A note ("C4", "F#3:2") or a chord of 2-MAX_CHORD notes joined by "+" ("C4+E4+G4:2"), its beats after the last.
static func _is_note_or_chord(n: String) -> bool:
	var parts := n.split(":")
	if parts.size() > 2 or (parts.size() == 2 and _note.search("C4:" + parts[1]) == null):
		return false
	var names := parts[0].split("+")
	if names.size() > MAX_CHORD:
		return false
	for name in names:
		if _note.search(name) == null or name.contains(":"):
			return false
	return true


## A tone: "plucked" (the default) rises fast and falls gently, with the note an octave up softly for a brighter sound;
## the other TONES are held (a quick rise, a slow fade, a short release) with their own HARMONICS (none above what the
## rate can play). `gain` below 1 for each note of a chord, and for a quieter sound.
static func _tone(out: PackedFloat32Array, start: int, seconds: float, hz: float, gain: float = 1.0,
		tone: String = "plucked") -> void:
	var n := mini(int(seconds * RATE), out.size() - start)
	var parts: Array = []
	for h: Array in HARMONICS.get(tone, HARMONICS.plucked):
		if hz * float(h[0]) < RATE * 0.45:
			parts.append(h)
	var level := gain * 0.45 * float(TONE_GAIN.get(tone, 1.0))
	var plucked := tone == "plucked"
	for i in n:
		var t := float(i) / RATE
		var env := minf(t / 0.01, 1.0) * exp(-3.0 * t / maxf(seconds, 0.1)) if plucked \
			else minf(t / 0.02, 1.0) * exp(-0.4 * t / maxf(seconds, 0.1))
		env *= clampf((seconds - t) / 0.03, 0.0, 1.0)
		var v := 0.0
		for h: Array in parts:
			v += float(h[1]) * sin(TAU * float(h[0]) * hz * t)
		out[start + i] += level * env * v


## A clap: a short burst of noise that dies away fast (`gain` below 1 for a quieter one).
static func _clap(out: PackedFloat32Array, start: int, seconds: float, gain: float = 1.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var n := mini(int(minf(seconds, 0.12) * RATE), out.size() - start)
	for i in n:
		var t := float(i) / RATE
		out[start + i] += gain * 0.6 * exp(-t / 0.025) * rng.randf_range(-1.0, 1.0)
