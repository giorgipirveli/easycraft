extends GutTest
## M2 Task 11 (spec §12.10) and the lead's child-psychology notes: screen shake, phone buzz and hurt
## flashes, as pure rules.


func test_shake_starts_at_its_strength_and_decays_to_zero() -> void:
	assert_almost_eq(FeelRules.shake_amplitude(0.2, 0.5, 0.0), 0.2, 0.0001)
	var last := INF
	for i in 11:
		var a := FeelRules.shake_amplitude(0.2, 0.5, i * 0.05)
		assert_lte(a, last, "never grows (t=%.2f)" % (i * 0.05))
		last = a
	assert_eq(FeelRules.shake_amplitude(0.2, 0.5, 0.5), 0.0)
	assert_eq(FeelRules.shake_amplitude(0.2, 0.5, 3.0), 0.0)


func test_no_shake_without_time_or_strength_and_never_huge() -> void:
	assert_eq(FeelRules.shake_amplitude(0.2, 0.0, 0.0), 0.0)
	assert_eq(FeelRules.shake_amplitude(0.0, 0.5, 0.0), 0.0)
	assert_eq(FeelRules.shake_amplitude(-1.0, 0.5, 0.0), 0.0)
	assert_eq(FeelRules.shake_amplitude(NAN, 0.5, 0.0), 0.0)
	assert_eq(FeelRules.shake_amplitude(50.0, 0.5, 0.0), FeelRules.MAX_SHAKE)


func test_shake_offset_stays_within_the_amplitude_and_is_zero_at_rest() -> void:
	assert_eq(FeelRules.shake_offset(0.0, 1.234), Vector2.ZERO)
	for i in 200:
		var off := FeelRules.shake_offset(0.1, i * 0.013)
		assert_lte(absf(off.x), 0.1 + 0.0001)
		assert_lte(absf(off.y), 0.1 + 0.0001)


## The Vibration setting turns off the phone buzz and the screen shake; Reduce motion the shake.
func test_shake_needs_vibration_on_and_reduce_motion_off() -> void:
	assert_true(FeelRules.can_shake(true, false))
	assert_false(FeelRules.can_shake(false, false))
	assert_false(FeelRules.can_shake(true, true))
	assert_false(FeelRules.can_shake(false, true))


func test_vibration_is_off_when_the_setting_is_off() -> void:
	assert_eq(FeelRules.vibration_ms(80, false, true), 0)
	assert_eq(FeelRules.vibration_ms(80, true, true), 80)


func test_vibration_only_on_a_phone_and_capped() -> void:
	assert_eq(FeelRules.vibration_ms(80, true, false), 0)
	assert_eq(FeelRules.vibration_ms(0, true, true), 0)
	assert_eq(FeelRules.vibration_ms(-5, true, true), 0)
	assert_eq(FeelRules.vibration_ms(100000, true, true), FeelRules.MAX_BUZZ_MS)


func test_a_hit_gives_a_small_shake_buzz_and_flash() -> void:
	var f := FeelRules.hurt_feel(20, 17)
	assert_false(f.is_empty())
	assert_gt(f.shake, 0.0)
	assert_gt(f.seconds, 0.0)
	assert_gt(f.buzz_ms, 0)
	assert_gt(f.flash, 0.0)


func test_a_knock_out_feels_bigger_than_any_hit() -> void:
	var ko := FeelRules.hurt_feel(3, 0)
	var big_hit := FeelRules.hurt_feel(20, 1)
	assert_gt(ko.shake, big_hit.shake)
	assert_gt(ko.seconds, big_hit.seconds)
	assert_gt(ko.buzz_ms, big_hit.buzz_ms)


func test_a_harder_hit_shakes_at_least_as_much() -> void:
	assert_gte(FeelRules.hurt_feel(20, 12).shake, FeelRules.hurt_feel(20, 19).shake)


## Heals, regeneration and a respawn with full hearts come through the same signal: no feel.
func test_heals_and_respawns_feel_like_nothing() -> void:
	assert_true(FeelRules.hurt_feel(10, 11).is_empty())
	assert_true(FeelRules.hurt_feel(0, Health.MAX_HP).is_empty())
	assert_true(FeelRules.hurt_feel(12, 12).is_empty())


## Photosensitivity guidance (the lead's notes): never more than 3 flashes in any one second, even
## when hits come every frame.
func test_never_more_than_three_flashes_a_second() -> void:
	var starts: Array[float] = []
	var last := -INF
	var t := 0.0
	while t < 5.0:
		if FeelRules.can_flash(t, last):
			starts.append(t)
			last = t
		t += 1.0 / 60.0
	assert_gt(starts.size(), 5)
	for s in starts:
		var in_window := starts.filter(func(u: float) -> bool: return u >= s and u <= s + 1.0).size()
		assert_lte(in_window, 3, "flashes in the second from %.2f" % s)


func test_reduce_motion_softens_flashes() -> void:
	assert_eq(FeelRules.flash_alpha(0.3, false), 0.3)
	assert_lt(FeelRules.flash_alpha(0.3, true), 0.3 * 0.5)
	assert_gt(FeelRules.flash_alpha(0.3, true), 0.0)
	assert_gt(FeelRules.flash_time(true), FeelRules.flash_time(false), "reduced flashes fade gently")


func test_a_flash_fades_out_to_nothing() -> void:
	assert_almost_eq(FeelRules.flash_alpha_at(0.3, 0.0, 0.3), 0.3, 0.0001)
	assert_lt(FeelRules.flash_alpha_at(0.3, 0.15, 0.3), 0.3)
	assert_eq(FeelRules.flash_alpha_at(0.3, 0.3, 0.3), 0.0)
	assert_eq(FeelRules.flash_alpha_at(0.3, 9.0, 0.3), 0.0)


## The Stone Golem's slam (Task 10, §12.9): full shake and a buzz inside its 7-block shockwave,
## a fading shake out to SLAM_REACH, nothing beyond.
func test_slam_feel_by_distance() -> void:
	var near := FeelRules.slam_feel(3.0)
	assert_eq(near.shake, FeelRules.SLAM_SHAKE)
	assert_eq(near.buzz_ms, FeelRules.SLAM_BUZZ_MS)
	assert_eq(FeelRules.slam_feel(FeelRules.SLAM_RADIUS).shake, FeelRules.SLAM_SHAKE)
	var mid := FeelRules.slam_feel((FeelRules.SLAM_RADIUS + FeelRules.SLAM_REACH) / 2.0)
	assert_almost_eq(float(mid.shake), FeelRules.SLAM_SHAKE / 2.0, 0.0001)
	assert_eq(mid.buzz_ms, 0, "only the shockwave buzzes")
	assert_true(FeelRules.slam_feel(FeelRules.SLAM_REACH).is_empty())
	assert_true(FeelRules.slam_feel(INF).is_empty())
	assert_true(FeelRules.slam_feel(NAN).is_empty())
