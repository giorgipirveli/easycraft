extends GutTest
## M5 Task 2 (spec §15.2): the loudness balance across universes. Loudness holds what tools/measure_loudness.py
## measured (EBU R128, full band and through a phone speaker, and the true peak) and turns it into gains: every
## universe's day and night loops as loud as Green Meadows' (the mean of the full-band and the phone difference),
## the pieces as loud as the loops they take turns with, every universe's day and night ambience as loud as the
## birds and the crickets, the monsters' idle voices as loud as the goblins' grunts through a phone. No gain pushes a
## file past -1 dBTP; a difference under MIN_STEP is left alone.

const MEADOWS_TRACKS := {"day": "res://assets/music/day.ogg", "night": "res://assets/music/night.ogg"}


## A boost stopped by the file's headroom (or none, when that headroom is under MIN_STEP).
func _capped(gain: float, room: float) -> bool:
	return is_equal_approx(gain, room) or (gain == 0.0 and room < Loudness.MIN_STEP)


func _music_path(u: int, track: String) -> String:
	return str(UniverseRegistry.music(u).get(track, MEADOWS_TRACKS[track]))


func _ambience(u: int, track: String) -> StringName:
	return UniverseRegistry.ambience(u).get(track, &"birds" if track == "day" else &"crickets")


func test_every_sound_a_universe_plays_is_measured_and_the_tool_lists_it() -> void:
	var tool := FileAccess.get_file_as_string("res://tools/measure_loudness.py")
	for u in range(1, UniverseRegistry.size() + 1):
		for track: String in ["day", "night"]:
			var path := _music_path(u, track)
			assert_true(Loudness.MUSIC.has(path.get_file()), "universe %d %s: %s measured" % [u, track, path])
			assert_true(tool.contains(path.get_file()), "the tool measures %s" % path.get_file())
			var loop := _ambience(u, track)
			assert_true(Loudness.AMBIENCE.has(loop), "universe %d %s ambience %s measured" % [u, track, loop])
			assert_true(tool.contains("\"%s\"" % loop), "the tool measures %s" % loop)
	for id: StringName in MusicPieces.ids():
		assert_true(Loudness.PIECES.has(id), "piece %s measured" % id)
	for kind: StringName in MonsterRules.KINDS:
		assert_true(Loudness.VOICES.has(kind), "%s's idle voice measured" % kind)


func test_every_universes_loops_are_as_loud_as_green_meadows() -> void:
	for u in range(2, UniverseRegistry.size() + 1):
		for track: String in ["day", "night"]:
			var path := _music_path(u, track)
			var ref: Array = Loudness.MUSIC[MEADOWS_TRACKS[track].get_file()]
			var m: Array = Loudness.MUSIC[path.get_file()]
			var g := Loudness.music_gain_db(path)
			var off := Loudness.balance_gap(m, ref) - g
			var capped := _capped(g, Loudness.headroom(m))
			gut.p("LOUDNESS universe %d %s %s: gap %+.1f dB, gain %+.1f dB" % [u, track, path.get_file(),
				Loudness.balance_gap(m, ref), g])
			assert_true(absf(off) <= Loudness.MIN_STEP or (off > 0.0 and capped),
				"universe %d %s is %+.1f dB off Green Meadows" % [u, track, off])


func test_pieces_meet_the_loops_they_take_turns_with() -> void:
	for id: StringName in MusicPieces.ids():
		var ref: Array = Loudness.MUSIC["boss.ogg" if MusicPieces.fits(id, MusicPieces.BOSS) else "day.ogg"]
		var m: Array = Loudness.PIECES[id]
		var g := Loudness.piece_gain_db(id)
		var off := Loudness.balance_gap(m, ref) - g
		assert_true(absf(off) <= Loudness.MIN_STEP or (off > 0.0 and _capped(g, Loudness.headroom(m))),
			"%s is %+.1f dB off" % [id, off])


func test_every_universes_ambience_is_as_loud_as_the_birds_and_crickets() -> void:
	for u in range(1, UniverseRegistry.size() + 1):
		for track: String in ["day", "night"]:
			var id := _ambience(u, track)
			var ref_id := &"birds" if track == "day" else &"crickets"
			var off := Loudness.ambience_gap(id, ref_id) - Loudness.ambience_gain_db(id)
			var capped := is_equal_approx(AmbienceSoundRules.volume_db(id), 0.0) \
				or _capped(Loudness.ambience_gain_db(id), Loudness.headroom(Loudness.AMBIENCE[id]) - AmbienceSoundRules.LOOPS[id])
			assert_true(absf(off) <= Loudness.MIN_STEP or (off > 0.0 and capped),
				"universe %d %s ambience (%s) is %+.1f dB off" % [u, track, id, off])


func test_the_sea_and_the_caves_are_left_as_they_were() -> void:
	assert_eq(Loudness.ambience_gain_db(&"waves"), 0.0, "the sea is the same in every universe")
	assert_eq(Loudness.ambience_gain_db(&"drips"), 0.0, "so are the caves")


func test_monster_idle_voices_are_even_through_a_phone() -> void:
	var ref: float = Loudness.VOICES[MonsterRules.GOBLIN][1]
	for kind: StringName in MonsterRules.KINDS:
		var v: Array = Loudness.VOICES[kind]
		var g := VoiceRules.monster_gain_db(kind)
		var off := ref - float(v[1]) - g
		assert_true(absf(off) <= Loudness.MIN_STEP or (off > 0.0 and (is_equal_approx(g, Loudness.VOICE_BOOST)
			or _capped(g, Loudness.headroom(v)))), "%s is %+.1f dB off the goblins" % [kind, off])
	assert_lt(VoiceRules.monster_gain_db(MonsterRules.ICE_BAT), -6.0, "the ice bat's screech was 9 dB over the grunts")


## (A file that already peaks a little over -1 dBTP, like the desert's day loop at -0.9, is left as it was.)
func test_no_gain_lifts_a_file_past_minus_one_dbtp() -> void:
	var lifted := func(m: Array, gain: float, what: String) -> void:
		if gain > 0.0:
			assert_lte(float(m[2]) + gain, Loudness.PEAK_LIMIT + 0.001, what)
	for f: String in Loudness.MUSIC:
		lifted.call(Loudness.MUSIC[f], Loudness.music_gain_db(f), f)
	for id: StringName in Loudness.PIECES:
		lifted.call(Loudness.PIECES[id], Loudness.piece_gain_db(id), String(id))
	for id: StringName in Loudness.AMBIENCE:
		lifted.call(Loudness.AMBIENCE[id], AmbienceSoundRules.volume_db(id), String(id))
		assert_lte(AmbienceSoundRules.volume_db(id), 0.0, "%s never louder than its file" % id)
	for kind: StringName in Loudness.VOICES:
		lifted.call(Loudness.VOICES[kind], VoiceRules.monster_gain_db(kind), String(kind))


func test_small_differences_are_left_alone_and_green_meadows_is_the_reference() -> void:
	assert_eq(Loudness.music_gain_db("res://assets/music/day.ogg"), 0.0)
	assert_eq(Loudness.music_gain_db("res://assets/music/night.ogg"), 0.0)
	assert_eq(Loudness.music_gain_db("res://assets/music/boss.ogg"), 0.0, "the boss loop is every universe's")
	assert_eq(Loudness.music_gain_db("res://assets/music/desert_day.ogg"), 0.0, "0.8 dB off: left alone")
	assert_eq(Loudness.music_gain_db("res://nothing.ogg"), 0.0, "an unmeasured file is left as it is")
	assert_lt(Loudness.music_gain_db("res://assets/music/candy_day.ogg"), -3.0, "the Candy Kingdom's day loop was the loudest")
