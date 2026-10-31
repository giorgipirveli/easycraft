extends GutTest
## RealisticAvatar's pure rules (M1b Task 13): which animation fits a speed and floor state, how fast
## the stride plays, and which skin a player wears.


func test_standing_still_is_idle() -> void:
	assert_eq(RealisticAvatar.animation_for(0.0, true), &"idle")
	assert_eq(RealisticAvatar.animation_for(RealisticAvatar.WALK_FROM - 0.01, true), &"idle", "drifting to a stop")


func test_slow_is_walk_and_fast_is_run() -> void:
	assert_eq(RealisticAvatar.animation_for(RealisticAvatar.WALK_FROM, true), &"walk")
	assert_eq(RealisticAvatar.animation_for(2.0, true), &"walk", "half-tilted joystick")
	assert_eq(RealisticAvatar.animation_for(Player.WALK_SPEED * Player.WATER_SPEED_FACTOR, true), &"walk", "wading")
	assert_eq(RealisticAvatar.animation_for(RealisticAvatar.RUN_FROM, true), &"run")
	assert_eq(RealisticAvatar.animation_for(Player.WALK_SPEED, true), &"run", "full stick or keyboard")


func test_in_the_air_is_fall_at_any_speed() -> void:
	for speed: float in [0.0, 2.0, 8.0]:
		assert_eq(RealisticAvatar.animation_for(speed, false), &"fall")


func test_the_stride_speeds_up_with_speed_and_slows_down_with_size() -> void:
	var slow := RealisticAvatar.playback_speed(&"walk", 2.0, 1.0)
	var fast := RealisticAvatar.playback_speed(&"run", 6.0, 1.0)
	assert_gt(fast, slow)
	assert_lt(RealisticAvatar.playback_speed(&"run", 6.0, 3.0), fast, "a giant takes longer strides")
	assert_almost_eq(RealisticAvatar.playback_speed(&"run", RealisticAvatar.STRIDE_SPEED, 1.0), 1.0, 0.001)
	assert_lte(RealisticAvatar.playback_speed(&"run", 50.0, 0.25), RealisticAvatar.MAX_PLAYBACK)
	assert_gte(RealisticAvatar.playback_speed(&"walk", 0.5, 3.0), RealisticAvatar.MIN_PLAYBACK)
	assert_eq(RealisticAvatar.playback_speed(&"idle", 0.0, 1.0), 1.0)
	assert_eq(RealisticAvatar.playback_speed(&"fall", 9.0, 1.0), 1.0)


func test_players_wear_different_skins() -> void:
	assert_eq(RealisticAvatar.skin_for(1), 0, "the host (and solo) wears the first skin")
	assert_ne(RealisticAvatar.skin_for(1), RealisticAvatar.skin_for(2), "the first guest looks different")
	for peer: int in [1, 2, 3, 1880412, 2147483647]:
		var s := RealisticAvatar.skin_for(peer)
		assert_between(s, 0, RealisticAvatar.SKINS.size() - 1)
