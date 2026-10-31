extends GutTest
## M2 Task 11 (spec §12.10): the Music autoload plays the day, night and boss loops on its own bus,
## cross-fading on dusk, dawn and boss fights; the settings' music volume sets that bus.
## Driven by hand (Music.tick) so the timing is exact; the real _process is off meanwhile.

const MAX_BYTES := 1572864        # 1.5 MB per track (mobile download size)


class FakeSky:
	extends Node
	var time := DayCycle.NOON


var _saved_volume: float
var _saved_style: String


## These tests are the GAME style's (the game's own loops); the audio pass's CLASSICAL and MIX styles are
## tests/integration/test_classical_music.gd's.
func before_each() -> void:
	Music.set_process(false)
	_saved_volume = float(Profile.data.settings.music_volume)
	_saved_style = str(Profile.data.settings.get("music_style", "mix"))
	Profile.data.settings.music_style = "game"
	Game.apply_settings()
	Music.reset()


func after_each() -> void:
	Music.reset()
	Music.set_process(true)
	Profile.data.settings.music_volume = _saved_volume
	Profile.data.settings.music_style = _saved_style
	Game.apply_settings()


func test_every_track_is_a_small_looping_ogg() -> void:
	for track: StringName in MusicRules.TRACKS:
		var path := "res://assets/music/%s.ogg" % track
		var stream := load(path) as AudioStreamOggVorbis
		assert_not_null(stream, path)
		if stream == null:
			continue
		assert_true(stream.loop, "%s loops" % path)
		assert_gt(stream.get_length(), 30.0, "%s is a real piece, not a jingle" % path)
		var size := FileAccess.get_file_as_bytes(path).size()
		assert_between(size, 1, MAX_BYTES, "%s is %d bytes" % [path, size])


func test_music_has_its_own_bus_under_master() -> void:
	var bus := AudioServer.get_bus_index(Music.BUS)
	assert_gt(bus, 0)
	assert_eq(AudioServer.get_bus_send(bus), &"Master")
	for track: StringName in MusicRules.TRACKS:
		assert_eq(Music.player(track).bus, Music.BUS)


func test_music_volume_setting_sets_the_music_bus() -> void:
	var bus := AudioServer.get_bus_index(Music.BUS)
	Profile.data.settings.music_volume = 0.25
	Game.apply_settings()
	assert_almost_eq(AudioServer.get_bus_volume_db(bus), linear_to_db(0.25), 0.01)
	assert_false(AudioServer.is_bus_mute(bus))
	Profile.data.settings.music_volume = 0.0
	Game.apply_settings()
	assert_true(AudioServer.is_bus_mute(bus), "0 is silent")


func test_silent_until_told_what_to_play() -> void:
	Music.tick(5.0)
	assert_eq(Music.current(), &"")
	for track: StringName in MusicRules.TRACKS:
		assert_false(Music.player(track).playing, String(track))


func test_the_menu_fades_in_the_day_track() -> void:
	Music.play_menu()
	Music.tick(0.0)
	assert_eq(Music.current(), MusicRules.DAY)
	assert_true(Music.player(MusicRules.DAY).playing)
	Music.tick(MusicRules.CROSSFADE)
	assert_almost_eq(Music.player(MusicRules.DAY).volume_db, 0.0, 0.01)
	assert_false(Music.player(MusicRules.NIGHT).playing)
	assert_false(Music.player(MusicRules.BOSS).playing)


func test_a_world_follows_its_sky_clock_and_crossfades_at_sunset() -> void:
	var sky := FakeSky.new()
	add_child_autofree(sky)
	Music.follow_sky(sky)
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.DAY)
	sky.time = DayCycle.SUNSET + 0.001
	Music.tick(MusicRules.CROSSFADE / 2.0)
	assert_eq(Music.current(), MusicRules.NIGHT)
	assert_true(Music.player(MusicRules.DAY).playing, "the day fades out, not stops")
	assert_true(Music.player(MusicRules.NIGHT).playing)
	assert_almost_eq(Music.player(MusicRules.DAY).volume_db, linear_to_db(sqrt(0.5)), 0.05)
	assert_almost_eq(Music.player(MusicRules.NIGHT).volume_db, linear_to_db(sqrt(0.5)), 0.05)
	Music.tick(MusicRules.CROSSFADE / 2.0)
	assert_false(Music.player(MusicRules.DAY).playing, "stopped once silent (no decoding)")
	assert_almost_eq(Music.player(MusicRules.NIGHT).volume_db, 0.0, 0.01)
	sky.time = DayCycle.SUNRISE
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.DAY)
	assert_false(Music.player(MusicRules.NIGHT).playing)


func test_boss_fight_theme_then_back_to_the_sky() -> void:
	var sky := FakeSky.new()
	sky.time = DayCycle.MIDNIGHT
	add_child_autofree(sky)
	Music.follow_sky(sky)
	Music.tick(MusicRules.CROSSFADE)
	Music.play_boss(true)
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.BOSS)
	assert_almost_eq(Music.player(MusicRules.BOSS).volume_db, 0.0, 0.01)
	assert_false(Music.player(MusicRules.NIGHT).playing)
	Music.play_boss(false)
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.NIGHT)


func test_a_track_fading_in_again_starts_from_the_beginning() -> void:
	Music.play_boss(true)
	Music.tick(MusicRules.CROSSFADE)
	Music.play_boss(false)
	Music.play_menu()
	Music.tick(MusicRules.CROSSFADE)
	assert_false(Music.player(MusicRules.BOSS).playing)
	Music.play_boss(true)
	Music.tick(0.1)
	assert_lt(Music.player(MusicRules.BOSS).get_playback_position(), 1.0)


func test_leaving_the_world_goes_back_to_the_menu_track_without_the_boss() -> void:
	var sky := FakeSky.new()
	sky.time = DayCycle.MIDNIGHT
	add_child(sky)
	Music.follow_sky(sky)
	Music.play_boss(true)
	Music.tick(MusicRules.CROSSFADE)
	sky.free()
	Music.play_menu()
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.MENU)


func test_a_freed_sky_falls_back_to_the_menu_track() -> void:
	var sky := FakeSky.new()
	sky.time = DayCycle.MIDNIGHT
	add_child(sky)
	Music.follow_sky(sky)
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.NIGHT)
	sky.free()
	Music.tick(MusicRules.CROSSFADE)
	assert_eq(Music.current(), MusicRules.MENU)


func test_music_keeps_playing_in_the_pause_menu() -> void:
	assert_eq(Music.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_the_main_menu_plays_the_menu_track() -> void:
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(2)
	Music.tick(0.0)
	assert_eq(Music.current(), MusicRules.MENU)
