extends GutTest
## M7 (owner 2026-09-28): in a browser the classical pieces and the universes' loops come in the music pack a little
## after the start (WebContent). Until then the Music autoload plays the three core loops (day, night, boss) with no
## "Now playing"; a universe's missing loop is Green Meadows'. When the pack is in (Music.on_pack_loaded), a universe's
## loop plays from its next start (the one playing is not cut) and more_music_coming() turns false.
## MusicPieces.exists_check pretends the files are missing. Driven by hand (Music.tick); the real _process is off.


class FakeSky:
	extends Node
	var time := DayCycle.NOON


var _saved := {}


func before_each() -> void:
	Music.set_process(false)
	for key: String in ["music_style", "song_names"]:
		_saved[key] = Profile.data.settings.get(key)
	Music.reset()


func after_each() -> void:
	MusicPieces.exists_check = Callable()
	Music.use_tracks({})
	Music.reset()
	Music.set_process(true)
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]
	Game.apply_settings()


func _style(s: String) -> void:
	Profile.data.settings.music_style = s
	Profile.data.settings.song_names = true
	Game.apply_settings()


## The first download's music only: the three core loops.
func _first_download() -> void:
	MusicPieces.exists_check = func(path: String) -> bool:
		return path.get_file() in ["day.ogg", "night.ogg", "boss.ogg"]


## Ticks (and lets the loader thread work) until `done` says true; false after 10 s.
func _until(done: Callable) -> bool:
	for i in 600:
		Music.tick(0.0)
		if done.call():
			return true
		await wait_process_frames(1)
	return false


func _sky(time: float) -> FakeSky:
	var sky := FakeSky.new()
	sky.time = time
	add_child_autofree(sky)
	return sky


func test_before_the_pack_the_menu_plays_the_day_loop_with_no_now_playing() -> void:
	_first_download()
	for style: String in ["classical", "mix"]:
		_style(style)
		Music.reset()
		Music.play_menu()
		Music.tick(0.0)
		Music.tick(MusicRules.CROSSFADE)
		assert_eq(Music.current(), MusicRules.DAY, style)
		assert_true(Music.player(MusicRules.DAY).playing, "%s: no silence" % style)
		assert_false(Music.now_playing_visible(), "%s: no piece to name" % style)
		assert_false(Music.next_piece(), "%s: nothing to skip to yet" % style)


func test_more_music_is_coming_until_the_pack_is_in() -> void:
	assert_false(Music.more_music_coming(), "the phone and desktop builds have it all")
	_first_download()
	assert_true(Music.more_music_coming())
	MusicPieces.exists_check = Callable()
	assert_false(Music.more_music_coming())


func test_the_music_pack_arriving_is_told() -> void:
	watch_signals(Music)
	Music.on_pack_loaded("other")
	assert_signal_not_emitted(Music, "more_music_arrived", "another pack is not the music")
	Music.on_pack_loaded(Music.PACK)
	assert_signal_emitted(Music, "more_music_arrived")


func test_a_universe_loop_not_in_yet_is_green_meadows_then_its_own_from_its_next_start() -> void:
	_style("game")
	_first_download()
	var candy := UniverseRegistry.music(4)
	var meadows_day: AudioStream = Music.STREAMS[MusicRules.DAY]
	var meadows_night: AudioStream = Music.STREAMS[MusicRules.NIGHT]
	var sky := _sky(DayCycle.NOON)
	Music.use_tracks(candy)
	Music.follow_sky(sky)
	Music.tick(0.0)
	Music.tick(MusicRules.CROSSFADE)
	var day := Music.player(MusicRules.DAY)
	var night := Music.player(MusicRules.NIGHT)
	assert_eq(day.stream, meadows_day, "the Candy Kingdom's day loop is not in yet")
	assert_true(day.playing)
	assert_almost_eq(day.volume_db, 0.0, 0.01, "at Green Meadows' level")
	var at := day.get_playback_position()

	MusicPieces.exists_check = Callable()   # the music pack is in
	Music.on_pack_loaded(Music.PACK)
	assert_eq(day.stream, meadows_day, "the loop playing is not cut")
	assert_eq(night.stream, meadows_night, "no load on the main thread: the loader thread brings it")
	assert_true(await _until(func() -> bool: return night.stream.resource_path == str(candy.night)),
		"a silent loop takes the universe's as soon as it is loaded")
	assert_eq(day.stream, meadows_day, "the loop playing is still not cut")
	assert_true(day.playing)
	assert_gte(day.get_playback_position(), at, "not started again")
	Music.tick(MusicRules.CROSSFADE)
	assert_almost_eq(day.volume_db, 0.0, 0.01, "still Green Meadows' level while it plays")

	sky.time = DayCycle.MIDNIGHT   # dusk: the day loop fades out and stops, the night loop comes in
	Music.tick(0.1)
	Music.tick(MusicRules.CROSSFADE)
	assert_false(day.playing)
	assert_true(await _until(func() -> bool: return day.stream.resource_path == str(candy.day)),
		"its next start is the Candy Kingdom's")
	assert_true(night.playing)
	assert_almost_eq(night.volume_db, Loudness.music_gain_db(str(candy.night)), 0.01, "at its evened-out level")
	assert_ne(night.stream, meadows_night)

	sky.time = DayCycle.NOON
	Music.tick(0.1)
	Music.tick(MusicRules.CROSSFADE)
	assert_true(day.playing)
	assert_eq(day.stream.resource_path, str(candy.day))
	assert_almost_eq(day.volume_db, Loudness.music_gain_db(str(candy.day)), 0.01)


func test_leaving_the_universe_forgets_a_loop_that_was_waiting() -> void:
	_style("game")
	_first_download()
	var sky := _sky(DayCycle.NOON)
	Music.use_tracks(UniverseRegistry.music(4))
	Music.follow_sky(sky)
	Music.tick(0.0)
	Music.tick(MusicRules.CROSSFADE)
	MusicPieces.exists_check = Callable()
	Music.on_pack_loaded(Music.PACK)
	Music.use_tracks({})   # back to Green Meadows before dusk (and before the loads are done)
	sky.time = DayCycle.MIDNIGHT
	Music.tick(0.1)
	Music.tick(MusicRules.CROSSFADE)
	for i in 30:
		Music.tick(0.0)
		await wait_process_frames(1)
	assert_eq(Music.player(MusicRules.DAY).stream, Music.STREAMS[MusicRules.DAY], "Green Meadows' day loop stays")
	assert_eq(Music.player(MusicRules.NIGHT).stream, Music.STREAMS[MusicRules.NIGHT])


# --- the settings (the MUSIC button's page) --------------------------------------------------------------------------

func _panel() -> SettingsPanel:
	var box := PanelContainer.new()        # as the menus show it: themed, in a panel
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass       # never writes the shared profile
	box.add_child(s)
	add_child_autofree(box)
	return s


func test_the_settings_say_more_music_is_on_its_way_until_it_comes() -> void:
	_first_download()
	var s := _panel()
	var note := s.find_child("MoreMusicNote", true, false) as Label
	assert_not_null(note, "a small line on the music's page")
	if note == null:
		return
	assert_true(note.is_visible_in_tree())
	assert_eq(note.text, SettingsPanel.MORE_MUSIC)
	var size := (s.get_parent() as Control).get_combined_minimum_size()
	assert_lte(size.x, 1280.0, "still fits a 1280 x 720 screen: %s" % size)
	assert_lte(size.y, 720.0, "still fits a 1280 x 720 screen: %s" % size)
	MusicPieces.exists_check = Callable()
	Music.on_pack_loaded(Music.PACK)
	assert_false(note.visible, "gone once the music is in")


func test_the_settings_say_nothing_when_all_the_music_is_here() -> void:
	var s := _panel()
	var note := s.find_child("MoreMusicNote", true, false) as Label
	assert_true(note == null or not note.visible)
