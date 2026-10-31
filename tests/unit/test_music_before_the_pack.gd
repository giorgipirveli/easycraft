extends GutTest
## M7 (owner 2026-09-28: "make first download small, then after starting a game download continues in background"):
## a browser's first download leaves the classical pieces and the universes' loops out (the music pack, WebContent);
## they come a little later. Until then the music chooser plays the three core loops (day, night, boss) wherever it
## would have picked a piece: no silence, no "Now playing" for a piece that is not there. Once they are in, the next
## change of music may pick one (the song playing is never cut). MusicPieces.exists_check pretends files are missing.


func after_each() -> void:
	MusicPieces.exists_check = Callable()


func _plan(style: StringName, seed_value: int = 1) -> MusicPlan:
	var p := MusicPlan.new(seed_value)
	p.set_style(style)
	return p


func _no_pieces() -> void:
	MusicPieces.exists_check = func(path: String) -> bool: return not path.begins_with(MusicPieces.DIR)


func _only(ids: Array) -> void:
	MusicPieces.exists_check = func(path: String) -> bool:
		return not path.begins_with(MusicPieces.DIR) or ids.has(StringName(path.get_file().get_basename()))


## Runs `seconds` in steps of `step` in one mood; returns every cue that started, in order.
func _run(p: MusicPlan, mood: StringName, seconds: float, step: float = 1.0) -> Array[StringName]:
	var cues: Array[StringName] = []
	var t := 0.0
	while t < seconds:
		if p.update(mood, step) or cues.is_empty():
			cues.append(p.cue)
		t += step
	return cues


func test_every_piece_is_here_in_the_phone_and_desktop_builds() -> void:
	for id: StringName in MusicPieces.ids():
		assert_true(MusicPieces.present(id), String(id))
	assert_true(MusicPieces.all_present())
	assert_false(MusicPieces.present(&"no_such_piece"))


func test_the_check_can_pretend_the_pieces_are_missing() -> void:
	_no_pieces()
	assert_false(MusicPieces.present(&"fur_elise"))
	assert_false(MusicPieces.all_present())
	assert_true(MusicPieces.file_present("res://assets/music/day.ogg"), "the core loops are in the first download")
	MusicPieces.exists_check = Callable()
	assert_true(MusicPieces.present(&"fur_elise"), "the real check again")


func test_without_the_pieces_the_menu_plays_the_day_loop_in_every_style() -> void:
	_no_pieces()
	for style: StringName in MusicPlan.STYLES:
		var p := _plan(style)
		p.update(MusicPlan.MENU, 0.0)
		assert_eq(p.cue, MusicRules.DAY, String(style))


func test_without_the_pieces_classical_plays_each_moods_own_loop() -> void:
	_no_pieces()
	var p := _plan(MusicPlan.CLASSICAL)
	var want := {MusicPlan.MORNING: MusicRules.DAY, MusicPlan.DAY: MusicRules.DAY, MusicPlan.NIGHT: MusicRules.NIGHT,
		MusicPlan.UNDERGROUND: MusicRules.NIGHT, MusicPlan.BOSS: MusicRules.BOSS}
	for mood: StringName in want:
		p.update(mood, 0.0)
		assert_eq(p.cue, want[mood], String(mood))


func test_without_the_pieces_the_loop_plays_on_with_no_silence() -> void:
	_no_pieces()
	for style: StringName in [MusicPlan.CLASSICAL, MusicPlan.MIX]:
		for mood: StringName in [MusicPlan.MENU, MusicPlan.DAY, MusicPlan.NIGHT]:
			var cues := _run(_plan(style), mood, 1200.0)
			assert_eq(cues, [MusicPlan.game_track(mood)] as Array[StringName], "%s %s: one loop, never a gap" % [style, mood])


func test_nothing_to_skip_to_without_the_pieces() -> void:
	_no_pieces()
	var p := _plan(MusicPlan.CLASSICAL)
	p.update(MusicPlan.DAY, 0.0)
	assert_false(p.skip())
	assert_eq(p.cue, MusicRules.DAY)


func test_when_the_pieces_arrive_the_loops_next_turn_is_a_piece_and_nothing_is_cut() -> void:
	for style: StringName in [MusicPlan.CLASSICAL, MusicPlan.MIX]:
		for mood: StringName in [MusicPlan.MENU, MusicPlan.DAY]:
			_no_pieces()
			var p := _plan(style)
			p.update(mood, 0.0)
			assert_eq(p.cue, MusicRules.DAY)
			MusicPieces.exists_check = Callable()   # the music pack is in
			p.update(mood, MusicPlan.MIX_LOOP_TIME - 1.0)
			assert_eq(p.cue, MusicRules.DAY, "%s %s: the loop plays its turn out" % [style, mood])
			p.update(mood, 2.0)
			assert_true(MusicPieces.has(p.cue), "%s %s: then a piece (%s)" % [style, mood, p.cue])


func test_a_mood_change_after_the_pieces_arrive_picks_one_at_once_in_classical() -> void:
	_no_pieces()
	var p := _plan(MusicPlan.CLASSICAL)
	p.update(MusicPlan.DAY, 0.0)
	assert_eq(p.cue, MusicRules.DAY)
	MusicPieces.exists_check = Callable()
	p.update(MusicPlan.NIGHT, 0.0)
	assert_true(MusicPieces.fits(p.cue, MusicPlan.NIGHT), "a night piece: %s" % p.cue)


func test_only_the_pieces_that_are_there_are_chosen() -> void:
	_only([&"fur_elise", &"air"])
	var p := _plan(MusicPlan.CLASSICAL)
	for c: StringName in _run(p, MusicPlan.MENU, 1500.0):
		assert_true(c == &"fur_elise" or c == &"air" or c == &"", "only the pieces here: %s" % c)
	var q := _plan(MusicPlan.CLASSICAL)
	q.update(MusicPlan.BOSS, 0.0)
	assert_eq(q.cue, MusicRules.BOSS, "no fight piece here yet: the boss loop")
