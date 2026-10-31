extends GutTest
## Cave mood and underwater view: how underground / underwater the player is, smoothing, and the
## resulting light, fog, lantern and tint.

const BASE := {"sun": 1.0, "ambient": 0.65, "fog_color": Color(0.68, 0.84, 1.0), "fog_begin": 90.0, "fog_end": 128.0}


func test_camera_in_water_is_underwater() -> void:
	assert_eq(AmbienceRules.underwater_target(BlockIds.WATER), 1.0)
	assert_eq(AmbienceRules.underwater_target(BlockIds.AIR), 0.0)


func test_deep_under_a_ceiling_is_underground() -> void:
	assert_eq(AmbienceRules.underground_target(20.0, 60, true), 1.0)


func test_open_sky_is_never_underground() -> void:
	assert_eq(AmbienceRules.underground_target(20.0, 60, false), 0.0, "an open pit stays bright")


func test_a_roof_near_the_surface_is_not_a_cave() -> void:
	assert_eq(AmbienceRules.underground_target(59.0, 60, true), 0.0, "under a tree or a roof")
	var halfway := AmbienceRules.underground_target(60.0 - AmbienceRules.START_DEPTH - AmbienceRules.RAMP * 0.5, 60, true)
	assert_almost_eq(halfway, 0.5, 0.001, "darkness ramps in with depth")


func test_approach_moves_toward_the_target_without_overshooting() -> void:
	var v := 0.0
	for i in 200:
		var next := AmbienceRules.approach(v, 1.0, 0.016)
		assert_true(next >= v and next <= 1.0)
		v = next
	assert_eq(v, 1.0, "reaches the target")
	assert_eq(AmbienceRules.approach(0.3, 0.3, 0.016), 0.3)


func test_open_air_keeps_the_base_look() -> void:
	var m := AmbienceRules.mood(0.0, 0.0, BASE)
	assert_eq(m.sun, BASE.sun)
	assert_eq(m.ambient, BASE.ambient)
	assert_eq(m.fog_color, BASE.fog_color)
	assert_eq(m.fog_end, BASE.fog_end)
	assert_eq(m.lantern, 0.0)
	assert_eq((m.tint as Color).a, 0.0)


func test_caves_are_dark_with_a_warm_lantern_but_never_pitch_black() -> void:
	var m := AmbienceRules.mood(1.0, 0.0, BASE)
	assert_lt(m.sun, 0.15 * BASE.sun)
	assert_lt(m.ambient, 0.3 * BASE.ambient)
	assert_gt(m.ambient, 0.0, "never pitch black")
	assert_gt(m.lantern, 1.0)
	assert_lt(m.fog_end, BASE.fog_end, "darkness hides the far cave")


func test_underwater_is_blue_and_foggy() -> void:
	var m := AmbienceRules.mood(0.0, 1.0, BASE)
	var fog: Color = m.fog_color
	assert_gt(fog.b, fog.r)
	assert_lt(m.fog_end, 30.0)
	assert_gt((m.tint as Color).a, 0.0)
	assert_gt((m.tint as Color).b, (m.tint as Color).r)
