extends GutTest
## Classical music in the game (owner feedback #31): the MUSIC setting's CLASSICAL and MIX styles in the
## Music autoload, the piece files, a short "Now playing" toast when a piece starts (the Song names setting
## hides it), caves, and the universe's own pieces. Driven by hand (Music.tick); the real _process is off.

const MAX_BYTES := 2621440        # 2.5 MB per piece (mobile download size)
const MAX_TOTAL := 20 * 1048576   # all the pieces together


class FakeSky:
	extends Node
	var time := DayCycle.NOON


var _saved := {}


func before_each() -> void:
	Music.set_process(false)
	for key: String in ["music_style", "song_names", "music_volume"]:
		_saved[key] = Profile.data.settings.get(key)
	_style("classical")
	Music.reset()


func after_each() -> void:
	Music.reset()
	Music.set_process(true)
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]
	Game.apply_settings()


func _style(s: String, names: bool = true) -> void:
	Profile.data.settings.music_style = s
	Profile.data.settings.song_names = names
	Game.apply_settings()


func test_every_piece_is_a_small_ogg_that_plays_once_and_is_as_long_as_the_catalogue_says() -> void:
	var total := 0
	for id: StringName in MusicPieces.ids():
		var path := MusicPieces.path(id)
		var stream := load(path) as AudioStreamOggVorbis
		assert_not_null(stream, path)
		if stream == null:
			continue
		assert_false(stream.loop, "%s plays once" % path)
		assert_almost_eq(stream.get_length(), MusicPieces.length(id), 1.0, path)
		var size := FileAccess.get_file_as_bytes(path).size()
		assert_between(size, 1, MAX_BYTES, "%s is %d bytes" % [path, size])
		total += size
	assert_lte(total, MAX_TOTAL, "all pieces: %d bytes" % total)


## Pieces load on the loader thread: a frame or two after they are chosen they play.
func _until_playing() -> AudioStreamPlayer:
	for i in 600:
		Music.tick(0.0)
		var p := Music.piece_player(Music.current())
		if p:
			return p
		await wait_process_frames(1)
	return null


func test_the_menu_plays_a_gentle_piece() -> void:
	Music.play_menu()
	Music.tick(0.0)
	var cue := Music.current()
	assert_true(MusicPieces.fits(cue, MusicPlan.MENU), "menu piece: %s" % cue)
	var p := await _until_playing()
	assert_not_null(p)
	if p:
		assert_true(p.playing)
		assert_eq(p.bus, Music.BUS)
		assert_eq((p.stream as AudioStream).resource_path, MusicPieces.path(cue))
	Music.tick(MusicRules.CROSSFADE)
	if p:
		assert_almost_eq(p.volume_db, Loudness.piece_gain_db(cue), 0.01, "faded in (at its evened-out level, M5 Task 2)")


func test_the_mix_menu_plays_a_piece_too() -> void:
	_style("mix")
	Music.play_menu()
	Music.tick(0.0)
	assert_true(MusicPieces.has(Music.current()))


func test_pieces_follow_each_other_on_two_players_only() -> void:
	var sky := FakeSky.new()
	add_child_autofree(sky)
	Music.follow_sky(sky)
	var heard := {}
	var last := &""
	for i in 1500:   # 25 minutes of day in steps of a second
		Music.tick(1.0)
		var cue := Music.current()
		if MusicPieces.has(cue):
			if cue != last:
				assert_ne(cue, last)
				heard[cue] = true
			last = cue
	assert_gte(heard.size(), 5, "many pieces were heard: %s" % [heard.keys()])
	assert_eq(Music.piece_player_count(), 2, "two players cross-fade every piece; none is ever added")
	var playing := 0
	for n in Music.get_children():
		if n is AudioStreamPlayer and (n as AudioStreamPlayer).playing:
			playing += 1
	assert_lte(playing, 2, "never more than two streams decoding")


func test_a_piece_start_shows_now_playing_once() -> void:
	Music.play_menu()
	Music.tick(0.0)
	var cue := Music.current()
	assert_true(Music.now_playing_visible())
	assert_eq(Music.now_playing_text(), "Now playing: " + MusicPieces.label(cue))
	Music.tick(Music.NOW_PLAYING_TIME + 1.0)
	assert_false(Music.now_playing_visible(), "short: it goes away by itself")
	Music.tick(1.0)
	assert_false(Music.now_playing_visible(), "once per piece")


func test_song_names_off_hides_now_playing() -> void:
	_style("classical", false)
	Music.play_menu()
	Music.tick(0.0)
	assert_true(MusicPieces.has(Music.current()))
	assert_false(Music.now_playing_visible())


func test_the_game_style_never_shows_now_playing() -> void:
	_style("game")
	Music.play_menu()
	Music.tick(0.0)
	assert_eq(Music.current(), MusicRules.DAY)
	assert_false(Music.now_playing_visible())


func test_changing_the_music_setting_changes_the_music() -> void:
	_style("game")
	Music.play_menu()
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.DAY)
	_style("classical")
	Music.tick(0.1)
	assert_true(MusicPieces.has(Music.current()))


func test_the_mix_sunrise_plays_morning_mood() -> void:
	_style("mix")
	var sky := FakeSky.new()
	sky.time = DayCycle.MIDNIGHT
	add_child_autofree(sky)
	Music.follow_sky(sky)
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.NIGHT)
	sky.time = DayCycle.SUNRISE + 0.01
	Music.tick(0.1)
	assert_eq(Music.current(), &"morning_mood")


func test_caves_play_the_cave_loop_in_mix() -> void:
	_style("mix")
	var sky := FakeSky.new()
	add_child_autofree(sky)
	Music.follow_sky(sky)
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.DAY)
	Music.set_underground(true)
	Music.tick(0.1)
	assert_eq(Music.current(), MusicRules.NIGHT, "the Crystal Cave loop")
	Music.set_underground(false)
	Music.tick(0.1)
	assert_eq(Music.current(), MusicRules.DAY)


func test_the_universes_own_pieces_come_first() -> void:
	var sky := FakeSky.new()
	add_child_autofree(sky)
	Music.use_favourites([&"waltz_flowers"])
	Music.follow_sky(sky)
	Music.tick(0.0)
	assert_eq(Music.current(), &"waltz_flowers")


func test_the_menu_forgets_the_universes_favourites() -> void:
	Music.use_favourites([&"waltz_flowers"])
	Music.play_menu()
	assert_eq(Music.favourites(), [] as Array[StringName])
