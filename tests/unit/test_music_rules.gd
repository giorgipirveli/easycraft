extends GutTest
## M2 Task 11 (spec §12.10): which track plays when, and how one track cross-fades into the next.


func test_calm_day_music_by_day() -> void:
	assert_eq(MusicRules.track_for(DayCycle.NOON, false), MusicRules.DAY)
	assert_eq(MusicRules.track_for(DayCycle.START, false), MusicRules.DAY)
	assert_eq(MusicRules.track_for(DayCycle.DUSK_START + 0.01, false), MusicRules.DAY)   # still light at early dusk


## The tense night music starts when the sun sets (mid-dusk), the moment night monsters may come
## (DayCycle.is_night), and the day music comes back when it rises (mid-dawn).
func test_tense_night_music_from_sunset_to_sunrise() -> void:
	assert_eq(MusicRules.track_for(DayCycle.SUNSET, false), MusicRules.NIGHT)
	assert_eq(MusicRules.track_for(DayCycle.MIDNIGHT, false), MusicRules.NIGHT)
	assert_eq(MusicRules.track_for(DayCycle.SUNRISE - 0.001, false), MusicRules.NIGHT)
	assert_eq(MusicRules.track_for(DayCycle.SUNRISE, false), MusicRules.DAY)
	assert_eq(MusicRules.track_for(DayCycle.SUNSET - 0.001, false), MusicRules.DAY)


func test_boss_theme_wins_day_and_night() -> void:
	assert_eq(MusicRules.track_for(DayCycle.NOON, true), MusicRules.BOSS)
	assert_eq(MusicRules.track_for(DayCycle.MIDNIGHT, true), MusicRules.BOSS)


func test_the_menu_plays_the_day_track() -> void:
	assert_eq(MusicRules.MENU, MusicRules.DAY)


func test_crossfade_takes_two_to_three_seconds() -> void:
	assert_between(MusicRules.CROSSFADE, 2.0, 3.0)


func test_first_track_fades_in_from_silence() -> void:
	var mix := MusicMix.new()
	assert_eq(mix.wanted, &"")
	mix.want(MusicRules.DAY)
	assert_eq(mix.gain(MusicRules.DAY), 0.0)
	mix.advance(MusicRules.CROSSFADE / 2.0)
	assert_almost_eq(mix.gain(MusicRules.DAY), 0.5, 0.001)
	mix.advance(MusicRules.CROSSFADE / 2.0)
	assert_eq(mix.gain(MusicRules.DAY), 1.0)


func test_crossfade_swaps_tracks_in_exactly_the_crossfade_time() -> void:
	var mix := _playing(MusicRules.DAY)
	mix.want(MusicRules.NIGHT)
	mix.advance(MusicRules.CROSSFADE * 0.25)
	assert_almost_eq(mix.gain(MusicRules.NIGHT), 0.25, 0.001)
	assert_almost_eq(mix.gain(MusicRules.DAY), 0.75, 0.001)
	mix.advance(MusicRules.CROSSFADE * 0.7)
	assert_gt(mix.gain(MusicRules.DAY), 0.0, "not silent before the crossfade time")
	mix.advance(MusicRules.CROSSFADE * 0.05)
	assert_eq(mix.gain(MusicRules.DAY), 0.0)
	assert_eq(mix.gain(MusicRules.NIGHT), 1.0)


## Equal-power fade: halfway through, both tracks play at 1/√2 (-3 dB), so the loudness stays even.
func test_crossfade_is_equal_power() -> void:
	var mix := _playing(MusicRules.DAY)
	mix.want(MusicRules.NIGHT)
	mix.advance(MusicRules.CROSSFADE / 2.0)
	assert_almost_eq(mix.amplitude(MusicRules.DAY), sqrt(0.5), 0.001)
	assert_almost_eq(mix.amplitude(MusicRules.NIGHT), sqrt(0.5), 0.001)
	var power := pow(mix.amplitude(MusicRules.DAY), 2) + pow(mix.amplitude(MusicRules.NIGHT), 2)
	assert_almost_eq(power, 1.0, 0.001)


func test_volume_db_is_silent_at_zero_and_full_at_one() -> void:
	var mix := _playing(MusicRules.DAY)
	assert_almost_eq(mix.volume_db(MusicRules.DAY), 0.0, 0.001)
	assert_eq(mix.volume_db(MusicRules.NIGHT), MusicMix.SILENT_DB)


## A boss arriving halfway through the dusk fade: night turns back from where it was, no jumps.
func test_a_change_of_mind_mid_fade_turns_around_smoothly() -> void:
	var mix := _playing(MusicRules.DAY)
	mix.want(MusicRules.NIGHT)
	mix.advance(MusicRules.CROSSFADE / 2.0)
	mix.want(MusicRules.BOSS)
	assert_almost_eq(mix.gain(MusicRules.NIGHT), 0.5, 0.001)
	mix.advance(MusicRules.CROSSFADE / 2.0)
	assert_eq(mix.gain(MusicRules.DAY), 0.0)
	assert_eq(mix.gain(MusicRules.NIGHT), 0.0)
	assert_almost_eq(mix.gain(MusicRules.BOSS), 0.5, 0.001)
	mix.advance(MusicRules.CROSSFADE / 2.0)
	assert_eq(mix.gain(MusicRules.BOSS), 1.0)


func test_wanting_the_playing_track_changes_nothing() -> void:
	var mix := _playing(MusicRules.NIGHT)
	mix.want(MusicRules.NIGHT)
	mix.advance(0.1)
	assert_eq(mix.gain(MusicRules.NIGHT), 1.0)
	assert_eq(mix.wanted, MusicRules.NIGHT)


func test_silence_fades_everything_out() -> void:
	var mix := _playing(MusicRules.BOSS)
	mix.want(&"")
	mix.advance(MusicRules.CROSSFADE)
	for track: StringName in MusicRules.TRACKS:
		assert_eq(mix.gain(track), 0.0, String(track))


func test_big_or_bad_steps_stay_in_range() -> void:
	var mix := MusicMix.new()
	mix.want(MusicRules.DAY)
	mix.advance(100.0)
	assert_eq(mix.gain(MusicRules.DAY), 1.0)
	mix.advance(-5.0)
	assert_eq(mix.gain(MusicRules.DAY), 1.0)
	mix.advance(NAN)
	assert_eq(mix.gain(MusicRules.DAY), 1.0)


func test_unknown_tracks_are_ignored() -> void:
	var mix := _playing(MusicRules.DAY)
	mix.want(&"disco")
	mix.advance(MusicRules.CROSSFADE)
	assert_eq(mix.wanted, MusicRules.DAY)
	assert_eq(mix.gain(MusicRules.DAY), 1.0)


func _playing(track: StringName) -> MusicMix:
	var mix := MusicMix.new()
	mix.want(track)
	mix.advance(MusicRules.CROSSFADE)
	return mix
