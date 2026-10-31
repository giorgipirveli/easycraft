extends GutTest
## Owner #110 (VR round 4, idea 7; docs/devlog/parts/vr-r4-sound.md): the music blocks' pure rules. The xylophone's eight
## bars are the C major scale from C5 to C6, low on the west (-X) end; the bongos are a big low skin on the west half
## and a small high one on the east half, their wooden shell a click. A strike is where a ray or a mallet's tip comes
## into the block and how fast; a faster hit is louder and buzzes the hand harder; the loop records four bars at 100
## beats a minute, snapped to half beats, and plays them back under up to three layers.




func test_the_xylophone_is_the_c_major_scale_with_longer_bars_lower() -> void:
	assert_eq(MusicBlockRules.BARS, 8)
	assert_eq(MusicBlockRules.NOTES, ["C5", "D5", "E5", "F5", "G5", "A5", "B5", "C6"] as Array[String])
	assert_almost_eq(MusicBlockRules.frequency(0), 523.25, 0.05, "C5")
	assert_almost_eq(MusicBlockRules.frequency(7), 1046.5, 0.05, "C6: an octave up, twice as fast")
	for v in range(1, MusicBlockRules.BARS):
		assert_gt(MusicBlockRules.frequency(v), MusicBlockRules.frequency(v - 1), "bar %d is higher than the one before" % v)
		assert_lt(MusicBlockRules.bar_length(v), MusicBlockRules.bar_length(v - 1), "and shorter")
	assert_eq(MusicBlockRules.letter(4), "G")
	assert_eq(MusicBlockRules.letter(MusicBlockRules.BONGO_LOW), "", "drums have no letter")


func test_every_voice_has_its_own_tone_file() -> void:
	var seen := {}
	for v in MusicBlockRules.VOICES:
		var f := MusicBlockRules.tone_file(v)
		assert_true(f.begins_with("res://assets/audio/sfx/instrument_"), f)
		assert_true(f.ends_with(".wav"), f)
		assert_false(seen.has(f), "one file a voice")
		seen[f] = true
	assert_eq(MusicBlockRules.tone_file(MusicBlockRules.VOICES), "", "no such voice")


func test_only_the_two_music_blocks_are_instruments() -> void:
	assert_true(MusicBlockRules.is_instrument(BlockIds.XYLOPHONE))
	assert_true(MusicBlockRules.is_instrument(BlockIds.DRUM))
	assert_false(MusicBlockRules.is_instrument(BlockIds.PLANKS))
	assert_false(MusicBlockRules.is_instrument(BlockIds.AIR))


func test_a_ray_comes_into_the_block_through_the_face_it_meets_first() -> void:
	var down := MusicBlockRules.entry(Vector3(0.3, 2.0, 0.5), Vector3.DOWN, 10.0)
	assert_eq(down.face, Vector3i.UP, "from above: the top")
	assert_almost_eq((down.point as Vector3).distance_to(Vector3(0.3, 1.0, 0.5)), 0.0, 0.0001)
	var side := MusicBlockRules.entry(Vector3(0.5, 0.5, 3.0), Vector3(0, 0, -1), 10.0)
	assert_eq(side.face, Vector3i(0, 0, 1), "from the south: the south face")
	assert_eq(MusicBlockRules.entry(Vector3(0.5, 2.0, 0.5), Vector3.UP, 10.0), {}, "going away: no entry")
	assert_eq(MusicBlockRules.entry(Vector3(0.5, 3.0, 0.5), Vector3.DOWN, 1.0), {}, "too short to reach it")
	assert_eq(MusicBlockRules.entry(Vector3(0.5, 0.5, 0.5), Vector3.DOWN, 1.0), {}, "already inside: nothing comes in")
	var grown := MusicBlockRules.entry(Vector3(0.5, 1.5, 0.5), Vector3.DOWN, 0.49, MusicBlockRules.TIP_RADIUS)
	assert_eq(grown.face, Vector3i.UP, "a mallet's tip touches the top a tip's radius before its middle does")


func test_which_bar_or_skin_a_strike_plays() -> void:
	var x := BlockIds.XYLOPHONE
	assert_eq(MusicBlockRules.voice_at(x, Vector3i.UP, Vector3(0.01, 1.0, 0.5)), 0, "the west end: low C")
	assert_eq(MusicBlockRules.voice_at(x, Vector3i.UP, Vector3(0.99, 1.0, 0.5)), 7, "the east end: high C")
	assert_eq(MusicBlockRules.voice_at(x, Vector3i.UP, Vector3(0.55, 1.0, 0.1)), 4,
		"x alone picks the bar (forgiving: the frame too)")
	assert_eq(MusicBlockRules.voice_at(x, Vector3i(0, 0, 1), Vector3(0.3, 0.9, 1.0)), 2, "a bar's end on the long side")
	assert_eq(MusicBlockRules.voice_at(x, Vector3i(-1, 0, 0), Vector3(0.0, 0.9, 0.5)), 0, "the west side: the lowest bar")
	assert_eq(MusicBlockRules.voice_at(x, Vector3i(1, 0, 0), Vector3(1.0, 0.9, 0.5)), 7, "the east side: the highest bar")
	assert_eq(MusicBlockRules.voice_at(x, Vector3i.DOWN, Vector3(0.5, 0.0, 0.5)), -1, "nothing under it")
	var d := BlockIds.DRUM
	assert_eq(MusicBlockRules.voice_at(d, Vector3i.UP, Vector3(0.25, 1.0, 0.5)), MusicBlockRules.BONGO_LOW,
		"the big skin: low")
	assert_eq(MusicBlockRules.voice_at(d, Vector3i.UP, Vector3(0.75, 1.0, 0.5)), MusicBlockRules.BONGO_HIGH,
		"the small skin: high")
	assert_eq(MusicBlockRules.voice_at(d, Vector3i(0, 0, -1), Vector3(0.5, 0.5, 0.0)), MusicBlockRules.SHELL,
		"the wooden shell clicks")
	assert_eq(MusicBlockRules.voice_at(BlockIds.STONE, Vector3i.UP, Vector3(0.5, 1.0, 0.5)), -1, "stone is no instrument")


func test_a_harder_hit_is_louder_and_buzzes_harder_and_a_resting_mallet_plays_nothing() -> void:
	assert_false(MusicBlockRules.is_hit(MusicBlockRules.MIN_SPEED * 0.5), "a mallet laid on it")
	assert_true(MusicBlockRules.is_hit(MusicBlockRules.MIN_SPEED))
	var soft := MusicBlockRules.volume_db(4, MusicBlockRules.MIN_SPEED)
	var hard := MusicBlockRules.volume_db(4, MusicBlockRules.FULL_SPEED)
	assert_lt(soft, hard, "harder is louder")
	assert_almost_eq(MusicBlockRules.volume_db(4, MusicBlockRules.FULL_SPEED * 3.0), hard, 0.001,
		"never louder than a full hit")
	for v in MusicBlockRules.VOICES:
		assert_lte(MusicBlockRules.volume_db(v, 100.0), MusicBlockRules.MAX_DB, "voice %d: capped" % v)
	var tap := MusicBlockRules.volume_db(4, MusicBlockRules.TAP_SPEED)
	assert_gt(tap, soft, "a phone's tap: a good medium hit")
	assert_lt(tap, hard)
	var buzz_soft: Array = MusicBlockRules.haptic(4, MusicBlockRules.MIN_SPEED)
	var buzz_hard: Array = MusicBlockRules.haptic(4, MusicBlockRules.FULL_SPEED)
	assert_lt(float(buzz_soft[0]), float(buzz_hard[0]), "a harder buzz")
	assert_lte(float(buzz_hard[0]), 1.0)
	assert_lte(float(buzz_hard[1]), 0.06, "a short tap of a buzz, never a long one")


func test_each_note_buzzes_at_its_own_frequency_the_higher_note_higher() -> void:
	var hz := []
	for v in MusicBlockRules.BARS:
		hz.append(float(MusicBlockRules.haptic(v, 1.0)[2]))
	for i in range(1, hz.size()):
		assert_gt(hz[i], hz[i - 1], "bar %d buzzes higher" % i)
	assert_almost_eq(hz[0], MusicBlockRules.frequency(0) / 4.0, 0.01, "two octaves under the note: the same letter")
	assert_lt(float(MusicBlockRules.haptic(MusicBlockRules.BONGO_LOW, 1.0)[2]),
		float(MusicBlockRules.haptic(MusicBlockRules.BONGO_HIGH, 1.0)[2]), "the low skin buzzes lower")


func test_the_host_lets_through_a_drum_roll_but_not_a_flood() -> void:
	var times: Array = []
	var let := 0
	for i in 40:   # 40 notes in one second
		if MusicBlockRules.may_play(times, i * 0.025):
			let += 1
	assert_eq(let, MusicBlockRules.NOTES_PER_SECOND, "at most NOTES_PER_SECOND a second")
	assert_true(MusicBlockRules.may_play(times, 2.0), "a second later: notes again")


# --- The loop -------------------------------------------------------------------------------------------------------

func test_the_loop_is_four_bars_of_four_beats_at_100_a_minute() -> void:
	assert_eq(MusicBlockRules.LOOP_BEATS, 16)
	assert_almost_eq(MusicBlockRules.beat_seconds(), 0.6, 0.0001)
	assert_almost_eq(MusicBlockRules.loop_seconds(), 9.6, 0.0001)
	assert_eq(MusicBlockRules.MAX_LAYERS, 3, "the research's cap: no hearing risk from stacked loops")


func test_a_take_counts_in_a_bar_records_four_bars_snapped_to_half_beats_and_plays_them_back() -> void:
	var b := MusicBlockRules.beat_seconds()
	var loop := MusicBlockRules.Loop.new()
	assert_eq(loop.state, MusicBlockRules.Loop.IDLE)
	assert_true(loop.record(10.0), "LOOP at 10 s")
	assert_eq(loop.state, MusicBlockRules.Loop.COUNT_IN)
	assert_false(loop.record(10.1), "one take at a time")
	var start := 10.0 + 4.0 * b   # a bar's count-in
	loop.tick(start - 0.01)
	assert_eq(loop.state, MusicBlockRules.Loop.COUNT_IN, "still counting in")
	assert_true(loop.note(start - 0.1, 0, Vector3i(1, 2, 3), -6.0), "a touch early: the take's first beat")
	loop.tick(start + 0.01)
	assert_eq(loop.state, MusicBlockRules.Loop.RECORDING)
	assert_true(loop.note(start + 2.1 * b, 4, Vector3i(1, 2, 3), -3.0), "beat 2.1 snaps to 2")
	assert_true(loop.note(start + 5.3 * b, 9, Vector3i(4, 2, 3), -8.0), "beat 5.3 snaps to 5.5")
	assert_eq(loop.take.map(func(e: Dictionary) -> float: return e.b), [0.0, 2.0, 5.5])
	assert_eq(loop.tick(start + 15.9 * b), [], "the take plays nothing back while it records (the child just played it)")
	var heard: Array = loop.tick(start + 16.0 * b + 0.001)
	assert_eq(loop.state, MusicBlockRules.Loop.PLAYING, "after four bars it plays")
	assert_eq(loop.layers.size(), 1)
	var t := start + 16.0 * b + 0.001
	while t < start + 31.5 * b:
		t += 0.05
		heard.append_array(loop.tick(t))
	assert_eq(heard.map(func(e: Dictionary) -> int: return e.v), [0, 4, 9], "the second pass: every note once, in order")
	assert_eq(heard[2].c, Vector3i(4, 2, 3), "at the block it was played on")
	assert_almost_eq(float(heard[1].db), -3.0, 0.001, "as loud as it was played")


func test_notes_outside_a_take_are_not_recorded_and_an_empty_take_is_dropped() -> void:
	var b := MusicBlockRules.beat_seconds()
	var loop := MusicBlockRules.Loop.new()
	assert_false(loop.note(1.0, 3, Vector3i.ZERO, 0.0), "no take: nothing records")
	loop.record(0.0)
	assert_false(loop.note(0.5 * b, 3, Vector3i.ZERO, 0.0), "the count-in's first beats are not the take")
	loop.tick(4.0 * b + 0.01)
	loop.tick(20.0 * b + 0.01)
	assert_eq(loop.layers.size(), 0, "nothing played: no layer")
	assert_eq(loop.state, MusicBlockRules.Loop.IDLE)


func test_a_new_layer_starts_at_the_next_bar_and_three_is_the_most() -> void:
	var b := MusicBlockRules.beat_seconds()
	var loop := MusicBlockRules.Loop.new()
	var t := 0.0
	for layer in 3:
		assert_true(loop.record(t), "layer %d" % (layer + 1))
		var from := loop.rec_from
		if layer > 0:
			assert_eq(fmod(from, float(MusicBlockRules.BEATS_PER_BAR)), 0.0, "on a bar line")
			assert_gte(loop.origin + from * b, t, "the next one, not one gone by")
			assert_lt(loop.origin + from * b - t, MusicBlockRules.BEATS_PER_BAR * b + 0.001, "within a bar")
		var at := loop.origin + (from + 1.0) * b
		loop.tick(at)
		assert_true(loop.note(at, layer, Vector3i.ZERO, 0.0))
		t = loop.origin + (from + MusicBlockRules.LOOP_BEATS) * b + 0.01
		loop.tick(t)
	assert_eq(loop.layers.size(), 3)
	assert_false(loop.record(t), "three layers: LOOP takes no more")
	loop.stop()
	assert_eq(loop.state, MusicBlockRules.Loop.IDLE)
	assert_eq(loop.layers.size(), 0, "STOP clears them")


func test_the_beat_ticks_through_the_count_in_and_the_take_with_the_bars_first_beat_accented() -> void:
	var b := MusicBlockRules.beat_seconds()
	var loop := MusicBlockRules.Loop.new()
	assert_eq(loop.beat_tick(0.0), MusicBlockRules.Loop.NO_TICK, "idle: no ticks")
	loop.record(0.0)
	var ticks: Array = []
	var t := 0.0
	while t < 21.0 * b:
		var n := loop.beat_tick(t)
		if n != MusicBlockRules.Loop.NO_TICK:
			ticks.append(n)
		t += 0.02
		loop.tick(t)
	assert_eq(ticks.slice(0, 5), [-4, -3, -2, -1, 0], "the count-in's four, then the take's first beat")
	assert_eq(ticks.size(), 20, "four counts and sixteen beats; none while it plays")
	assert_true(MusicBlockRules.Loop.accented(0) and MusicBlockRules.Loop.accented(4)
		and MusicBlockRules.Loop.accented(-4))
	assert_false(MusicBlockRules.Loop.accented(2))
