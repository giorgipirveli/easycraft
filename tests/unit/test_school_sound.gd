extends GutTest
## The research's "listen and choose" (docs/design/school-curriculum-research.md §5.3; the music subject): a lesson card
## or an exercise may carry a sound, made in code (no audio files): "notes" (a tune: note names, each a beat or more,
## "-" a rest) or "rhythm" (claps: "x" a clap, "-" a rest, each a half beat). Checked like a picture; played by a LISTEN
## button.

const TUNE := {"kind": "notes", "notes": ["C4", "E4", "G4", "C5:2"]}
const CLAPS := {"kind": "rhythm", "pattern": "x-x-xx--", "tempo": 90}


func test_note_names_are_their_pitches() -> void:
	assert_almost_eq(SchoolSound.frequency("A4"), 440.0, 0.01)
	assert_almost_eq(SchoolSound.frequency("C4"), 261.63, 0.01, "middle C")
	assert_almost_eq(SchoolSound.frequency("A5"), 880.0, 0.01, "an octave up: twice as fast")
	assert_almost_eq(SchoolSound.frequency("F#4"), 369.99, 0.01)
	assert_almost_eq(SchoolSound.frequency("Bb3"), 233.08, 0.01)
	assert_eq(SchoolSound.frequency("H9"), 0.0, "not a note")


func test_good_sounds_pass_and_odd_ones_say_why() -> void:
	assert_eq(SchoolSound.problem(TUNE), "")
	assert_eq(SchoolSound.problem(CLAPS), "")
	assert_eq(SchoolSound.problem({"kind": "notes", "notes": ["C4", "-", "G4"]}), "", "a rest")
	for bad: Variant in [{"kind": "notes", "notes": []}, {"kind": "notes", "notes": ["Q4"]}, {"kind": "drone"},
			{"kind": "rhythm", "pattern": "xyz"}, {"kind": "rhythm", "pattern": "x", "tempo": 500},
			{"kind": "notes", "notes": ["C4:9"]}, "C4", {"kind": "notes", "notes": ["C9"]}]:
		assert_ne(SchoolSound.problem(bad), "", str(bad))
	var long := []
	for i in 40:
		long.append("C4")
	assert_ne(SchoolSound.problem({"kind": "notes", "notes": long}), "", "at most a few seconds")


func test_how_long_a_sound_lasts() -> void:
	assert_almost_eq(SchoolSound.duration(TUNE), 5 * SchoolSound.BEAT, 0.001, "four notes, the last two beats long")
	assert_almost_eq(SchoolSound.duration(CLAPS), 8 * 0.5 * 60.0 / 90.0, 0.001, "eight half beats at 90 a minute")


func test_it_makes_a_stream_to_play() -> void:
	var s := SchoolSound.stream(TUNE)
	assert_not_null(s)
	assert_eq(s.mix_rate, SchoolSound.RATE)
	assert_almost_eq(s.get_length(), SchoolSound.duration(TUNE), 0.05)
	assert_null(SchoolSound.stream({"kind": "drone"}), "an odd sound makes nothing")


func test_a_sound_on_an_exercise_is_checked() -> void:
	var ex := {"type": "choice", "prompt": "Which is higher: the first note or the second?", "hint": "Listen again.",
		"choices": ["the first", "the second"], "answer": 1, "sound": {"kind": "notes", "notes": ["C4", "G4"]}}
	assert_eq(ExerciseCheck.problem(ex), "")
	ex.sound = {"kind": "notes", "notes": ["Z1"]}
	assert_string_contains(ExerciseCheck.problem(ex), "sound")


## Grade 5 music (chords, major and minor): notes joined by "+" sound together, as a chord ("C4+E4+G4:2", two beats).
func test_a_chord_is_notes_played_together() -> void:
	var chords := {"kind": "notes", "notes": ["C4+E4+G4:2", "F4+A4+C5:2", "G4+B4+D5", "C4+E4+G4+C5"]}
	assert_eq(SchoolSound.problem(chords), "")
	assert_almost_eq(SchoolSound.duration(chords), 6 * SchoolSound.BEAT, 0.001, "a chord's beats count once")
	for bad: Variant in [["C4+"], ["+E4"], ["C4+Q4"], ["C4++E4"], ["C4+E4+G4+B4+D5"], ["-+C4"], ["C4:2+E4"]]:
		assert_ne(SchoolSound.problem({"kind": "notes", "notes": bad}), "", str(bad))
	assert_eq(SchoolSound.frequency("C4+E4+G4"), 0.0, "a chord is not one pitch")
	var one := SchoolSound.stream({"kind": "notes", "notes": ["C4:2"]})
	var three := SchoolSound.stream({"kind": "notes", "notes": ["C4+E4+G4:2"]})
	assert_not_null(three)
	if three == null:
		return
	assert_almost_eq(three.get_length(), one.get_length(), 0.01, "a chord lasts as long as one note")
	var loudest := 0
	for i in range(0, three.data.size(), 2):
		loudest = maxi(loudest, absi(three.data.decode_s16(i)))
	assert_lt(loudest, 30000, "three notes together never clip")
	assert_ne(three.data, one.data, "the chord sounds its three notes")


func _peak(s: AudioStreamWAV) -> int:
	var loudest := 0
	for i in range(0, s.data.size(), 2):
		loudest = maxi(loudest, absi(s.data.decode_s16(i)))
	return loudest


## Grade 6 music (the science of sound): `volume` is the amplitude (a quieter sound is a smaller wave), and `tone` is
## the timbre: the same note with a different mix of harmonics ("pure" one frequency, "bright" every harmonic, "hollow"
## the odd ones only, "plucked" the default).
func test_a_sound_can_be_quieter_and_have_its_own_tone() -> void:
	var loud := {"kind": "notes", "notes": ["A4:2"]}
	var soft := {"kind": "notes", "notes": ["A4:2"], "volume": 0.4}
	assert_eq(SchoolSound.problem(soft), "")
	var a := SchoolSound.stream(loud)
	var b := SchoolSound.stream(soft)
	assert_not_null(b)
	if b == null:
		return
	assert_almost_eq(float(_peak(b)) / float(_peak(a)), 0.4, 0.03, "volume 0.4: a wave 0.4 as tall")
	assert_almost_eq(b.get_length(), a.get_length(), 0.01, "as long")
	var claps := {"kind": "rhythm", "pattern": "x-x-", "volume": 0.5}
	assert_eq(SchoolSound.problem(claps), "")
	assert_almost_eq(float(_peak(SchoolSound.stream(claps))) / float(_peak(SchoolSound.stream({"kind": "rhythm",
		"pattern": "x-x-"}))), 0.5, 0.03, "quieter claps")
	var seen := {}
	for tone: String in SchoolSound.TONES:
		var d := {"kind": "notes", "notes": ["A3:2"], "tone": tone}
		assert_eq(SchoolSound.problem(d), "", tone)
		var s := SchoolSound.stream(d)
		assert_almost_eq(s.get_length(), a.get_length(), 0.01, "%s lasts as long" % tone)
		assert_lt(_peak(s), 30000, "%s never clips" % tone)
		seen[s.data] = true
	assert_eq(seen.size(), SchoolSound.TONES.size(), "every tone sounds different")
	for bad: Variant in [{"kind": "notes", "notes": ["C4"], "volume": 0.0}, {"kind": "notes", "notes": ["C4"], "volume": 2},
			{"kind": "notes", "notes": ["C4"], "volume": "loud"}, {"kind": "notes", "notes": ["C4"], "tone": "kazoo"},
			{"kind": "rhythm", "pattern": "x-", "tone": "pure"}]:
		assert_ne(SchoolSound.problem(bad), "", str(bad))


## A pure tone is one frequency: its wave crosses the middle line twice a cycle, 2 × 220 times a second for A3.
func test_a_pure_tone_is_one_frequency() -> void:
	var s := SchoolSound.stream({"kind": "notes", "notes": ["A3:2"], "tone": "pure", "beat": 1.0})
	assert_not_null(s)
	if s == null:
		return
	var crossings := 0
	var last := 0
	for i in range(int(0.2 * SchoolSound.RATE), int(1.2 * SchoolSound.RATE)):
		var v := s.data.decode_s16(i * 2)
		if v != 0 and last != 0 and signi(v) != signi(last):
			crossings += 1
		if v != 0:
			last = v
	assert_almost_eq(crossings, 440, 4, "220 cycles in a second")


## Grade 7 music (Baroque ground bass, the Classical melody and accompaniment, a folk drone, balancing parts when
## performing together): a tune may have `parts`, other tunes that play at the same time from the start, each with its
## own volume and tone, so a melody can be heard over a quieter bass (or drowned by a louder one).
func test_parts_play_together_with_the_tune() -> void:
	var melody := {"kind": "notes", "notes": ["E5", "D5", "C5:2"]}
	var both := {"kind": "notes", "notes": ["E5", "D5", "C5:2"], "parts": [{"notes": ["C3:4"], "volume": 0.4}]}
	assert_eq(SchoolSound.problem(both), "")
	assert_almost_eq(SchoolSound.duration(both), 4 * SchoolSound.BEAT, 0.001, "as long as the longest part")
	var longer := {"kind": "notes", "notes": ["C5"], "parts": [{"notes": ["C3:2", "G2:2"]}]}
	assert_almost_eq(SchoolSound.duration(longer), 4 * SchoolSound.BEAT, 0.001, "a part may last longer than the tune")
	var a := SchoolSound.stream(melody)
	var b := SchoolSound.stream(both)
	assert_not_null(b)
	if b == null:
		return
	assert_ne(a.data, b.data, "the bass sounds too")
	assert_lt(_peak(b), 30000, "two parts never clip")
	var three := {"kind": "notes", "notes": ["C5+E5+G5:4"], "parts": [{"notes": ["C4:4"], "tone": "hollow"},
		{"notes": ["C3:4"], "tone": "bright"}]}
	assert_eq(SchoolSound.problem(three), "")
	assert_lt(_peak(SchoolSound.stream(three)), 30000, "a chord over two parts never clips")
	var soft_bass := SchoolSound.stream({"kind": "notes", "notes": ["-:4"], "parts": [{"notes": ["C3:4"], "volume": 0.3}]})
	var loud_bass := SchoolSound.stream({"kind": "notes", "notes": ["-:4"], "parts": [{"notes": ["C3:4"]}]})
	assert_not_null(soft_bass, "a rest over a bass part")
	if soft_bass == null or loud_bass == null:
		return
	assert_almost_eq(float(_peak(soft_bass)) / float(_peak(loud_bass)), 0.3, 0.03, "a part's volume is its own")
	for bad: Variant in [{"kind": "notes", "notes": ["C4"], "parts": []},
			{"kind": "notes", "notes": ["C4"], "parts": [{"notes": ["Q4"]}]},
			{"kind": "notes", "notes": ["C4"], "parts": [{"notes": ["C3"], "volume": 3}]},
			{"kind": "notes", "notes": ["C4"], "parts": [{"notes": ["C3"], "tone": "kazoo"}]},
			{"kind": "notes", "notes": ["C4"], "parts": [{"notes": ["C3"]}, {"notes": ["C3"]}, {"notes": ["C3"]},
				{"notes": ["C3"]}]},
			{"kind": "notes", "notes": ["C4"], "parts": ["C3"]},
			{"kind": "rhythm", "pattern": "x-x-", "parts": [{"notes": ["C3"]}]},
			{"kind": "notes", "notes": ["C4"], "parts": [{"notes": ["C3:4", "C3:4", "C3:4", "C3:4", "C3:4"]}]}]:
		assert_ne(SchoolSound.problem(bad), "", str(bad))
