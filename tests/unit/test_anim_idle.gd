extends GutTest
## Owner #94 (the animations brief §1): the avatar's idle life and happy reactions. A child standing still looks round,
## stretches or thinks now and then (a sleepy yawn at night), and waves when a friend walks up; a secret, a quest step,
## an adventure goal, a tamed animal, a Wonders stamp or a rocket landing gets a happy little jump and spin (hooray).
## New emotes for the wheel: think, yawn and stretch (free). The head turns in the new poses (both bodies read "head").


func test_the_new_poses_are_poses_at_every_moment() -> void:
	for e: StringName in [&"think", &"yawn", &"stretch", &"look", &"hooray"]:
		assert_true(EmotePoses.has(e), "%s is an emote" % e)
		assert_between(EmotePoses.duration(e), 0.8, 4.0, "%s ends by itself" % e)
		for i in 40:
			var p := EmotePoses.sample(e, i * 0.1)
			assert_true((p.head as Vector3).is_finite())
			assert_between(float(p.hop), -0.01, 0.6)
	assert_eq(EmotePoses.rest().head, Vector3.ZERO, "the rest pose looks ahead")


func test_look_turns_the_head_both_ways_and_back() -> void:
	var yaws: Array[float] = []
	for i in 29:
		yaws.append((EmotePoses.sample(&"look", i * 0.1).head as Vector3).y)
	assert_gt(yaws.max(), 0.4, "one way")
	assert_lt(yaws.min(), -0.4, "then the other")
	assert_almost_eq((EmotePoses.sample(&"look", EmotePoses.duration(&"look")).head as Vector3).y, 0.0, 0.01, "ahead again")


func test_hooray_is_a_jump_and_a_whole_spin() -> void:
	var top := 0.0
	for i in 12:
		top = maxf(top, float(EmotePoses.sample(&"hooray", i * 0.1).hop))
	assert_gt(top, 0.3, "a little jump")
	var end := EmotePoses.sample(&"hooray", EmotePoses.duration(&"hooray"))
	assert_almost_eq(float(end.hop), 0.0, 0.001, "back on its feet")
	assert_almost_eq(fposmod(float(end.spin), TAU), 0.0, 0.001, "facing the way it was, one whole turn later")
	var mid := EmotePoses.sample(&"hooray", 0.4)
	assert_gt(absf(float(mid.spin)), 1.0, "it spins")


func test_think_yawn_and_stretch_are_free_for_the_wheel() -> void:
	for e: StringName in [&"think", &"yawn", &"stretch"]:
		assert_true(AvatarCatalog.has_item(AvatarCatalog.EMOTE, e), "%s is on the emote list" % e)
		assert_true(AvatarCatalog.is_free(AvatarCatalog.item_id(AvatarCatalog.EMOTE, e)), "%s is free" % e)
	assert_false(AvatarCatalog.has_item(AvatarCatalog.EMOTE, &"look"), "idle looks are the body's own, not the wheel's")
	assert_false(AvatarCatalog.has_item(AvatarCatalog.EMOTE, &"hooray"))
	for e: StringName in [&"wave", &"cheer", &"think", &"dance_hop"]:
		assert_has(AvatarCatalog.DEFAULT_WHEEL, e, "a new child's MORE > EMOTE wheel has %s" % e)
	assert_has(AvatarLook.new().emotes, &"think")


func test_a_still_child_fidgets_now_and_then() -> void:
	var idle := AnimIdle.new()
	var played: Array[StringName] = []
	for i in 60 * 40:   # 40 seconds at 60 frames a second
		var e := idle.step(1.0 / 60.0, true, true, false, false)
		if e != &"":
			played.append(e)
	assert_between(played.size(), 2, 6, "a few fidgets in 40 s, not a fidget show")
	for e in played:
		assert_true(AnimIdle.DAY_IDLES.has(e), "a day's fidget: %s" % e)
	assert_ne(played[0], played[1], "not the same twice in a row")


func test_nothing_while_moving_or_busy_and_the_clock_starts_again() -> void:
	var idle := AnimIdle.new()
	for i in 60 * 20:
		assert_eq(idle.step(1.0 / 60.0, false, true, false, false), &"", "never while walking")
	for i in 60 * 20:
		assert_eq(idle.step(1.0 / 60.0, true, false, false, false), &"", "never over an emote or a dance")
	idle = AnimIdle.new()
	for i in int(60 * (AnimIdle.FIRST_AFTER - 1.0)):
		assert_eq(idle.step(1.0 / 60.0, true, true, false, false), &"")
	idle.step(0.1, false, true, false, false)   # a step: the clock starts again
	for i in int(60 * (AnimIdle.FIRST_AFTER - 1.0)):
		assert_eq(idle.step(1.0 / 60.0, true, true, false, false), &"")


func test_a_sleepy_yawn_at_night() -> void:
	var idle := AnimIdle.new()
	var played: Array[StringName] = []
	for i in 60 * 40:
		var e := idle.step(1.0 / 60.0, true, true, true, false)
		if e != &"":
			played.append(e)
	assert_has(played, &"yawn", "at night it yawns")
	for e in played:
		assert_true(AnimIdle.NIGHT_IDLES.has(e))


func test_it_waves_when_a_friend_walks_up_once() -> void:
	var idle := AnimIdle.new()
	assert_eq(idle.step(0.5, true, true, false, false), &"")
	assert_eq(idle.step(0.1, true, true, false, true), &"wave", "a friend came close")
	for i in 60:
		assert_ne(idle.step(1.0 / 60.0, true, true, false, true), &"wave", "once, not while they stay")
	idle.step(0.1, true, true, false, false)
	assert_eq(idle.step(0.1, true, true, false, true), &"wave", "again when they come back")
	var walking := AnimIdle.new()
	walking.step(0.1, false, true, false, true)
	assert_ne(walking.step(0.1, true, true, false, true), &"wave", "a friend already there when it stopped: no wave")


func test_what_a_child_cheers_for() -> void:
	for k: StringName in [&"secret_found/cove", &"quest_step", &"quest_done/tilly_pets", &"goal_done", &"animal_tamed/dog"]:
		assert_true(AnimIdle.cheers_for(k), "hooray for %s" % k)
	for k: StringName in [&"block_placed", &"monster_defeated", &"area_explored", &"photo_taken"]:
		assert_false(AnimIdle.cheers_for(k), "not for %s (too often, or its own celebration)" % k)
