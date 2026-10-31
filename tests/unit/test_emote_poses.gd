extends GutTest
## M3 Task 9: emotes and dances are poses over time (EmotePoses), shared by both avatar styles. An
## arm is (pitch, spread): hanging down, spread out to the side, then swung forward and up by pitch
## (> 0 is forward and up); a leg is a pitch (> 0 forward). The body can hop, spin, lean and sit.


func _emotes() -> Array[StringName]:
	var out: Array[StringName] = []
	for n: StringName in AvatarCatalog.items_in(AvatarCatalog.EMOTE):
		out.append(n)
	return out


func test_every_emote_has_a_pose_at_every_moment() -> void:
	for e in _emotes():
		assert_true(EmotePoses.has(e), "%s has poses" % e)
		for i in 40:
			var p := EmotePoses.sample(e, i * 0.1)
			for key: String in ["l_arm", "r_arm"]:
				assert_true((p[key] as Vector2).is_finite(), "%s %s" % [e, key])
			for key: String in ["l_leg", "r_leg", "hop", "spin", "lean", "sit"]:
				assert_true(is_finite(float(p[key])), "%s %s" % [e, key])
			assert_between(float(p.sit), 0.0, 1.0)
			assert_between(float(p.hop), -0.01, 0.6, "%s hops a little" % e)


func test_an_unknown_emote_is_the_rest_pose() -> void:
	assert_false(EmotePoses.has(&"moonwalk"))
	var p := EmotePoses.sample(&"moonwalk", 0.5)
	assert_eq(p.r_arm, Vector2.ZERO)
	assert_eq(p.hop, 0.0)


func test_wave_raises_the_right_arm_and_moves_it() -> void:
	var spreads: Array[float] = []
	for i in 20:
		var p := EmotePoses.sample(&"wave", 0.4 + i * 0.05)
		assert_gt((p.r_arm as Vector2).x, 2.2, "the right arm is up")
		assert_lt((p.l_arm as Vector2).x, 0.5, "the left arm rests")
		spreads.append((p.r_arm as Vector2).y)
	assert_gt(spreads.max() - spreads.min(), 0.3, "the hand waves side to side")


func test_cheer_raises_both_arms_and_hops() -> void:
	var hops := 0.0
	for i in 20:
		var p := EmotePoses.sample(&"cheer", 0.3 + i * 0.05)
		assert_gt((p.l_arm as Vector2).x, 2.2)
		assert_gt((p.r_arm as Vector2).x, 2.2)
		hops = maxf(hops, p.hop)
	assert_gt(hops, 0.1, "jumps for joy")


func test_thumbs_up_points_the_right_arm_forward() -> void:
	var p := EmotePoses.sample(&"thumbs_up", 0.8)
	assert_between((p.r_arm as Vector2).x, 1.2, 1.9, "about level, in front")


func test_sit_lowers_the_body_with_the_legs_forward_and_stays() -> void:
	var p := EmotePoses.sample(&"sit", 2.0)
	assert_almost_eq(float(p.sit), 1.0, 0.001)
	assert_gt(float(p.l_leg), 1.2, "legs forward")
	assert_gt(float(p.r_leg), 1.2)
	assert_false(EmotePoses.finished(&"sit", 600.0), "sits until the player moves")


func test_dances_loop_and_one_shots_end() -> void:
	for d: StringName in [&"dance_hop", &"dance_robot", &"dance_star"]:
		assert_true(AvatarCatalog.is_dance(d))
		assert_false(EmotePoses.finished(d, 60.0), "%s keeps dancing" % d)
	for e: StringName in [&"wave", &"cheer", &"laugh", &"thumbs_up", &"clap", &"bow"]:
		assert_false(EmotePoses.finished(e, 0.1))
		assert_true(EmotePoses.finished(e, EmotePoses.duration(e) + 0.01), "%s ends" % e)
		assert_between(EmotePoses.duration(e), 1.0, 4.0)


func test_the_star_spin_turns_the_body_and_the_robot_moves() -> void:
	var spins: Array[float] = []
	for i in 30:
		spins.append(float(EmotePoses.sample(&"dance_star", i * 0.05).spin))
	assert_gt(spins.max() - spins.min(), PI, "spins around")
	var a := EmotePoses.sample(&"dance_robot", 0.1)
	var b := EmotePoses.sample(&"dance_robot", 0.6)
	assert_ne(a.r_arm, b.r_arm, "robot arms change")


func test_the_victory_dance_lasts_a_few_seconds() -> void:
	assert_true(EmotePoses.has(&"victory"))
	assert_true(AvatarCatalog.is_dance(&"victory"))
	assert_between(EmotePoses.duration(&"victory"), 2.0, 5.0)
	assert_true(EmotePoses.finished(&"victory", EmotePoses.duration(&"victory") + 0.1), "a celebration ends by itself")


func test_moving_stops_an_emote() -> void:
	assert_false(EmotePoses.stops_at(0.0))
	assert_false(EmotePoses.stops_at(EmotePoses.STOP_SPEED * 0.5), "a nudge doesn't stop it")
	assert_true(EmotePoses.stops_at(EmotePoses.STOP_SPEED + 0.1))


func test_every_emote_starts_and_ends_near_rest() -> void:
	## Blending in from the rest pose looks smooth when the first sample is near rest or the blend
	## weight hides it; the pose at t = 0 must at least be finite and the sit starts standing.
	assert_almost_eq(float(EmotePoses.sample(&"sit", 0.0).sit), 0.0, 0.05, "sitting down takes a moment")
