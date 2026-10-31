extends GutTest
## The music chooser (owner feedback #31: "musics i like, please also add some clasical musics like
## bethhoven, mozart and etc."): a MUSIC setting — GAME (the game's own loops), CLASSICAL (only classical
## pieces) and MIX (the default: classical pieces take turns with the game's loops by day; night, boss
## fights and caves keep the game's moods, which tell the child what is going on). The menu plays a gentle
## piece; a sunrise in MIX plays Grieg's Morning Mood; no piece plays twice in a row.


func _plan(style: StringName, seed_value: int = 1) -> MusicPlan:
	var p := MusicPlan.new(seed_value)
	p.set_style(style)
	return p


## Runs `seconds` in steps of `step` in one mood; returns every cue that started, in order.
func _run(p: MusicPlan, mood: StringName, seconds: float, step: float = 1.0) -> Array[StringName]:
	var cues: Array[StringName] = []
	var t := 0.0
	while t < seconds:
		if p.update(mood, step) or cues.is_empty():
			cues.append(p.cue)
		t += step
	return cues


func test_moods_from_the_clock_the_boss_and_the_caves() -> void:
	assert_eq(MusicPlan.mood_for(DayCycle.NOON, false, false), MusicPlan.DAY)
	assert_eq(MusicPlan.mood_for(DayCycle.MIDNIGHT, false, false), MusicPlan.NIGHT)
	assert_eq(MusicPlan.mood_for(DayCycle.SUNSET + 0.01, false, false), MusicPlan.NIGHT)
	assert_eq(MusicPlan.mood_for(DayCycle.SUNRISE + 0.01, false, false), MusicPlan.MORNING)
	assert_eq(MusicPlan.mood_for(DayCycle.START, false, false), MusicPlan.DAY, "a new world starts in the day")
	assert_eq(MusicPlan.mood_for(DayCycle.NOON, false, true), MusicPlan.UNDERGROUND)
	assert_eq(MusicPlan.mood_for(DayCycle.MIDNIGHT, false, true), MusicPlan.UNDERGROUND)
	assert_eq(MusicPlan.mood_for(DayCycle.NOON, true, true), MusicPlan.BOSS, "a boss fight wins over everything")


func test_the_default_style_is_mix_and_unknown_styles_are_mix() -> void:
	assert_eq(MusicPlan.new().style, MusicPlan.MIX)
	assert_eq(MusicPlan.valid_style(&"jazz"), MusicPlan.MIX)
	assert_eq(MusicPlan.valid_style(&"classical"), MusicPlan.CLASSICAL)
	assert_eq(MusicPlan.valid_style(&"game"), MusicPlan.GAME)


func test_game_style_plays_the_games_own_loops() -> void:
	var p := _plan(MusicPlan.GAME)
	p.update(MusicPlan.MENU, 0.0)
	assert_eq(p.cue, MusicRules.DAY, "the menu plays the day loop")
	p.update(MusicPlan.DAY, 0.0)
	assert_eq(p.cue, MusicRules.DAY)
	p.update(MusicPlan.NIGHT, 0.0)
	assert_eq(p.cue, MusicRules.NIGHT)
	p.update(MusicPlan.UNDERGROUND, 0.0)
	assert_eq(p.cue, MusicRules.NIGHT, "caves: the Crystal Cave loop")
	p.update(MusicPlan.BOSS, 0.0)
	assert_eq(p.cue, MusicRules.BOSS)
	p.update(MusicPlan.MORNING, 0.0)
	assert_eq(p.cue, MusicRules.DAY)
	assert_eq(_run(p, MusicPlan.DAY, 1200.0), [MusicRules.DAY] as Array[StringName], "never a classical piece")


func test_silence_when_nothing_is_asked() -> void:
	var p := _plan(MusicPlan.MIX)
	p.update(&"", 1.0)
	assert_eq(p.cue, &"")


func test_classical_style_plays_only_pieces_that_fit_the_mood() -> void:
	for mood: StringName in [MusicPlan.MENU, MusicPlan.MORNING, MusicPlan.DAY, MusicPlan.NIGHT, MusicPlan.BOSS,
			MusicPlan.UNDERGROUND]:
		var p := _plan(MusicPlan.CLASSICAL)
		for cue: StringName in _run(p, mood, 1800.0):
			if cue == &"":
				continue   # a breath between two pieces
			assert_true(MusicPieces.has(cue), "%s: %s is a piece" % [mood, cue])
			assert_true(MusicPieces.fits(cue, mood), "%s fits %s" % [cue, mood])


func test_no_piece_plays_twice_in_a_row() -> void:
	for mood: StringName in [MusicPlan.MENU, MusicPlan.DAY, MusicPlan.NIGHT, MusicPlan.BOSS, MusicPlan.UNDERGROUND]:
		for s in 5:
			var p := _plan(MusicPlan.CLASSICAL, s)
			var last := &""
			for cue: StringName in _run(p, mood, 3600.0):
				if cue == &"":
					continue
				assert_ne(cue, last, "%s seed %d: %s twice in a row" % [mood, s, cue])
				last = cue


func test_every_fitting_piece_comes_before_one_repeats() -> void:
	var p := _plan(MusicPlan.CLASSICAL, 3)
	var seen := {}
	# (M5 Task 2: a universe's own pieces play only there: this plan has no favourites)
	var fitting := MusicPieces.for_mood(MusicPlan.DAY).filter(func(id: StringName) -> bool:
		return not MusicPieces.is_own(id)).size()
	for cue: StringName in _run(p, MusicPlan.DAY, 3600.0):
		if cue == &"":
			continue
		if seen.size() < fitting:
			assert_false(seen.has(cue), "%s again before all %d were heard" % [cue, fitting])
		seen[cue] = true
	assert_eq(seen.size(), fitting)


func test_classical_rests_a_breath_between_pieces() -> void:
	var p := _plan(MusicPlan.CLASSICAL)
	p.update(MusicPlan.NIGHT, 0.0)
	var first := p.cue
	p.update(MusicPlan.NIGHT, MusicPieces.length(first) + 0.01)
	assert_eq(p.cue, &"", "a rest")
	p.update(MusicPlan.NIGHT, MusicPlan.REST + 0.01)
	assert_true(MusicPieces.has(p.cue))
	assert_ne(p.cue, first)


func test_boss_fights_never_rest() -> void:
	var p := _plan(MusicPlan.CLASSICAL)
	p.update(MusicPlan.BOSS, 0.0)
	var first := p.cue
	p.update(MusicPlan.BOSS, MusicPieces.length(first) + 0.01)
	assert_true(MusicPieces.has(p.cue), "straight on to the next fight piece")
	assert_ne(p.cue, first)


func test_mix_takes_turns_by_day() -> void:
	var p := _plan(MusicPlan.MIX)
	var cues := _run(p, MusicPlan.DAY, 1200.0)
	assert_eq(cues[0], MusicRules.DAY, "a world starts with its own music")
	var pieces := 0
	var loops := 0
	for i in cues.size():
		if MusicPieces.has(cues[i]):
			pieces += 1
			assert_true(MusicPieces.fits(cues[i], MusicPlan.DAY))
			if i + 1 < cues.size():
				assert_eq(cues[i + 1], MusicRules.DAY, "after a piece the game's day loop comes back")
		elif cues[i] == MusicRules.DAY:
			loops += 1
			if i + 1 < cues.size():
				assert_true(MusicPieces.has(cues[i + 1]), "after the loop's turn a piece")
	assert_gte(pieces, 3, "20 minutes of day hear several pieces (%d)" % pieces)
	assert_gte(loops, 3)


func test_mix_keeps_the_games_moods_at_night_in_caves_and_in_boss_fights() -> void:
	var p := _plan(MusicPlan.MIX)
	assert_eq(_run(p, MusicPlan.NIGHT, 900.0), [MusicRules.NIGHT] as Array[StringName])
	p = _plan(MusicPlan.MIX)
	assert_eq(_run(p, MusicPlan.UNDERGROUND, 900.0), [MusicRules.NIGHT] as Array[StringName])
	p = _plan(MusicPlan.MIX)
	assert_eq(_run(p, MusicPlan.BOSS, 900.0), [MusicRules.BOSS] as Array[StringName])


func test_mix_sunset_goes_straight_to_the_night_loop() -> void:
	var p := _plan(MusicPlan.MIX)
	p.update(MusicPlan.DAY, 0.0)
	p.update(MusicPlan.DAY, MusicPlan.MIX_LOOP_TIME + 1.0)
	assert_true(MusicPieces.has(p.cue), "a day piece plays")
	p.update(MusicPlan.NIGHT, 1.0)
	assert_eq(p.cue, MusicRules.NIGHT, "the night loop tells the child night has come")


func test_the_sunrise_plays_morning_mood() -> void:
	for style: StringName in [MusicPlan.MIX, MusicPlan.CLASSICAL]:
		var p := _plan(style)
		p.update(MusicPlan.NIGHT, 0.0)
		p.update(MusicPlan.NIGHT, 30.0)
		p.update(MusicPlan.MORNING, 1.0)
		assert_eq(p.cue, &"morning_mood", String(style))


func test_the_menu_plays_a_gentle_piece() -> void:
	for style: StringName in [MusicPlan.MIX, MusicPlan.CLASSICAL]:
		var p := _plan(style)
		p.update(MusicPlan.MENU, 0.0)
		assert_true(MusicPieces.has(p.cue), String(style))
		assert_true(MusicPieces.fits(p.cue, MusicPlan.MENU))


func test_a_piece_that_fits_the_new_mood_keeps_playing() -> void:
	var p := _plan(MusicPlan.MIX)
	p.update(MusicPlan.MENU, 0.0)
	while not MusicPieces.fits(p.cue, MusicPlan.DAY):   # find a menu piece that is a day piece too
		p.update(MusicPlan.MENU, MusicPieces.length(p.cue) + MusicPlan.REST + 1.0)
	var piece := p.cue
	assert_false(p.update(MusicPlan.DAY, 1.0), "entering a daytime world")
	assert_eq(p.cue, piece, "no cut in the middle of the piece")


func test_the_universes_own_pieces_come_first() -> void:
	var p := _plan(MusicPlan.CLASSICAL, 7)
	p.favourites = [&"waltz_flowers"]
	p.update(MusicPlan.DAY, 0.0)
	assert_eq(p.cue, &"waltz_flowers", "the Candy Kingdom's Nutcracker")


func test_changing_the_style_changes_the_music_at_once() -> void:
	var p := _plan(MusicPlan.GAME)
	p.update(MusicPlan.DAY, 0.0)
	assert_eq(p.cue, MusicRules.DAY)
	p.set_style(MusicPlan.CLASSICAL)
	p.update(MusicPlan.DAY, 0.0)
	assert_true(MusicPieces.has(p.cue))
	p.set_style(MusicPlan.GAME)
	p.update(MusicPlan.DAY, 0.0)
	assert_eq(p.cue, MusicRules.DAY)


func test_bad_steps_are_ignored() -> void:
	var p := _plan(MusicPlan.CLASSICAL)
	p.update(MusicPlan.DAY, 0.0)
	var cue := p.cue
	p.update(MusicPlan.DAY, NAN)
	p.update(MusicPlan.DAY, -5.0)
	p.update(MusicPlan.DAY, INF)
	assert_eq(p.cue, cue)


## Owner #40's /music next: the next piece now, never the same one; nothing to skip in the game's own music.
func test_skip_starts_another_piece_where_pieces_play() -> void:
	var p := _plan(MusicPlan.CLASSICAL)
	_run(p, MusicPlan.DAY, 5.0)
	var was := p.cue
	assert_true(MusicPieces.has(was))
	assert_true(p.skip(), "a piece plays: skip")
	assert_true(MusicPieces.has(p.cue))
	assert_ne(p.cue, was, "never the same piece again")
	assert_eq(p.elapsed, 0.0, "from its start")


func test_skip_does_nothing_in_the_games_own_music() -> void:
	var p := _plan(MusicPlan.GAME)
	_run(p, MusicPlan.DAY, 5.0)
	var was := p.cue
	assert_false(p.skip())
	assert_eq(p.cue, was)
