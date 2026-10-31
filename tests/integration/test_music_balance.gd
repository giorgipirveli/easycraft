extends GutTest
## M5 Task 2 (spec §15.2): Music plays each universe's loops at their evened-out level (Loudness): the Candy
## Kingdom's day loop, 8 dB louder than Green Meadows' through a phone, comes down; Green Meadows' plays as before.


class FakeSky:
	extends Node
	var time := DayCycle.NOON


var _style: String


func before_each() -> void:
	Music.set_process(false)
	_style = str(Profile.data.settings.get("music_style", "mix"))
	Profile.data.settings.music_style = "game"
	Game.apply_settings()
	Music.reset()


func after_each() -> void:
	Music.reset()
	Music.set_process(true)
	Profile.data.settings.music_style = _style
	Game.apply_settings()


func _day_volume(tracks: Dictionary) -> float:
	var sky := FakeSky.new()
	add_child_autofree(sky)
	Music.use_tracks(tracks)
	Music.follow_sky(sky)
	Music.tick(0.0)
	Music.tick(MusicRules.CROSSFADE)
	return Music.player(MusicRules.DAY).volume_db


func test_a_universes_day_loop_plays_at_its_evened_out_level() -> void:
	var candy := UniverseRegistry.music(4)
	var db := _day_volume(candy)
	assert_almost_eq(db, Loudness.music_gain_db(str(candy.day)), 0.01, "the Candy Kingdom's day loop")
	assert_lt(db, -3.0, "comes down to Green Meadows'")


func test_green_meadows_plays_as_before() -> void:
	assert_almost_eq(_day_volume({}), 0.0, 0.01)
