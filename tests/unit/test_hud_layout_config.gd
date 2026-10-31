extends GutTest
## M5 Task 1 (spec §15.1a): the HUD table at three button sizes (the thumb controls grow; BIG and BIGGER have their
## own spots), the left hand's mirror of the whole table, and moved controls (JUMP, ATTACK, CROUCH and the stick),
## which stay only where they cover nothing and keep on the screen.

const SCREENS: Array[Vector2] = [Vector2(1280, 720), Vector2(1600, 720)]
const THUMBS := {&"jump": HudLayout.JUMP, &"attack": HudLayout.ATTACK, &"crouch": HudLayout.BUTTON,
	&"glide": HudLayout.BUTTON}


func after_each() -> void:
	HudLayout.reset()


func test_normal_and_right_handed_is_the_table_as_it_was() -> void:
	HudLayout.configure(HudLayout.NORMAL, false, {}, SCREENS[0])
	for spot: StringName in HudLayout.SPOTS:
		assert_eq(HudLayout.spot(spot), HudLayout.SPOTS[spot], String(spot))
	assert_eq(HudLayout.factor(), 1.0)
	assert_false(HudLayout.left_handed)


func test_big_and_bigger_grow_the_thumb_controls_and_keep_the_top_buttons() -> void:
	for step: StringName in [HudLayout.BIG, HudLayout.BIGGER]:
		HudLayout.configure(step, false, {}, SCREENS[0])
		var f: float = HudLayout.FACTORS[step]
		assert_gt(f, 1.0)
		for spot: StringName in THUMBS:
			var r := HudLayout.rect(spot, SCREENS[0])
			assert_gte(minf(r.size.x, r.size.y), float(THUMBS[spot]) * f - 0.5, "%s %s grows ×%s" % [step, spot, f])
		for spot: StringName in [&"pause", &"chat", &"book", &"ride", &"physics", &"more"]:
			assert_eq(HudLayout.rect(spot, SCREENS[0]).size, Vector2(135, 135), "%s %s keeps its size" % [step, spot])
	assert_lt(HudLayout.FACTORS[HudLayout.BIG], HudLayout.FACTORS[HudLayout.BIGGER])


func test_no_two_things_that_show_together_overlap_at_any_size_hand_or_screen() -> void:
	for step: StringName in HudLayout.STEPS:
		for left: bool in [false, true]:
			for screen in SCREENS:
				HudLayout.configure(step, left, {}, screen)
				assert_eq(HudLayout.clashes(screen), [] as Array[String], "%s %s %s" % [step, "left" if left else "right", screen])


func test_the_left_hand_sees_the_whole_table_in_a_mirror() -> void:
	for step: StringName in HudLayout.STEPS:
		for screen in SCREENS:
			HudLayout.configure(step, false, {}, screen)
			var right := {}
			for spot: StringName in HudLayout.SPOTS:
				right[spot] = HudLayout.rect(spot, screen, Vector2(10, 10))
			HudLayout.configure(step, true, {}, screen)
			for spot: StringName in HudLayout.SPOTS:
				var r: Rect2 = right[spot]
				var m := HudLayout.rect(spot, screen, Vector2(10, 10))
				assert_almost_eq(m.get_center().x, screen.x - r.get_center().x, 0.01, "%s %s mirrored" % [step, spot])
				assert_almost_eq(m.position.y, r.position.y, 0.01)
				assert_eq(m.size, r.size)
	HudLayout.configure(HudLayout.NORMAL, true, {}, SCREENS[0])
	assert_lt(HudLayout.rect(&"jump", SCREENS[0]).get_center().x, 640.0, "JUMP under the left thumb")
	assert_gt(HudLayout.rect(&"joystick", SCREENS[0]).get_center().x, 640.0, "the stick under the right thumb")


func test_a_move_that_covers_nothing_is_kept() -> void:
	var screen := SCREENS[0]
	HudLayout.configure(HudLayout.NORMAL, false, {&"jump": Vector2(0, -8)}, screen)
	var r := HudLayout.rect(&"jump", screen)
	assert_eq(r.position, Vector2(1280 - 241, 720 - 241 - 8), "JUMP a little higher")
	assert_eq(HudLayout.rejected, [] as Array[StringName])


func test_a_move_onto_another_control_or_off_the_screen_is_ignored() -> void:
	var screen := SCREENS[0]
	var home := HudLayout.rect(&"attack", screen)
	HudLayout.configure(HudLayout.NORMAL, false, {&"attack": Vector2(0, 150)}, screen)   # onto JUMP
	assert_eq(HudLayout.rect(&"attack", screen), home, "ATTACK stays home")
	assert_eq(HudLayout.rejected, [&"attack"] as Array[StringName])
	HudLayout.configure(HudLayout.NORMAL, false, {&"attack": Vector2(100, 0)}, screen)   # off the right edge
	assert_eq(HudLayout.rect(&"attack", screen), home)
	HudLayout.configure(HudLayout.NORMAL, false, {&"attack": Vector2(-620, -150)}, screen)   # onto the game clock
	assert_eq(HudLayout.rect(&"attack", screen), home)


func test_a_move_is_checked_again_on_each_screen() -> void:
	# CROUCH 100 px to the left: room on the emulator's wide screen, STOP FOR TODAY's place on a 16:9 phone
	var moves := {&"crouch": Vector2(-100, 0)}
	HudLayout.configure(HudLayout.NORMAL, false, moves, SCREENS[1])
	assert_eq(HudLayout.rejected, [] as Array[StringName], "fits 1600 wide")
	HudLayout.configure(HudLayout.NORMAL, false, moves, SCREENS[0])
	assert_eq(HudLayout.rejected, [&"crouch"] as Array[StringName], "not 1280 wide")


func test_the_left_hand_sees_a_move_mirrored() -> void:
	var screen := SCREENS[0]
	HudLayout.configure(HudLayout.NORMAL, false, {&"jump": Vector2(-10, -8)}, screen)
	var right := HudLayout.rect(&"jump", screen)
	HudLayout.configure(HudLayout.NORMAL, true, {&"jump": Vector2(-10, -8)}, screen)
	var left := HudLayout.rect(&"jump", screen)
	assert_almost_eq(left.get_center().x, screen.x - right.get_center().x, 0.01)
	assert_eq(left.position.y, right.position.y)


func test_only_the_thumb_controls_and_the_stick_move() -> void:
	assert_eq(HudLayout.MOVABLE, [&"jump", &"attack", &"crouch", &"joystick"] as Array[StringName])
	var screen := SCREENS[0]
	var home := HudLayout.rect(&"pause", screen)
	HudLayout.configure(HudLayout.NORMAL, false, {&"pause": Vector2(0, 300)}, screen)
	assert_eq(HudLayout.rect(&"pause", screen), home)


func test_moves_are_kept_per_button_size_and_bad_data_is_dropped() -> void:
	var saved := {"normal": {"jump": [-10, -8], "pause": [0, 300], "attack": ["x", 2], "crouch": [INF, 0]},
		"bigger": {"joystick": [30, 0]}, "huge": {"jump": [1, 1]}, "big": "nonsense"}
	var clean := HudLayout.sanitize_moves(saved)
	assert_eq(clean, {"normal": {"jump": [-10.0, -8.0]}, "bigger": {"joystick": [30.0, 0.0]}})
	assert_eq(HudLayout.moves_for(clean, HudLayout.NORMAL), {&"jump": Vector2(-10, -8)})
	assert_eq(HudLayout.moves_for(clean, HudLayout.BIG), {})
	assert_eq(HudLayout.sanitize_moves("nope"), {})
	var far := HudLayout.sanitize_moves({"normal": {"jump": [99999, 0]}})
	assert_eq(far, {}, "a move bigger than any screen is not a move")


func test_the_settings_choose_the_layout() -> void:
	var p := ProfileData.new()
	assert_eq(p.settings.button_size, "normal", "normal on a new profile")
	assert_false(p.settings.left_handed)
	p.settings.button_size = "bigger"
	p.settings.left_handed = true
	p.hud_moves = {"bigger": {"jump": [-10.0, -8.0]}}
	HudLayout.configure_from(p, SCREENS[0])
	assert_eq(HudLayout.step, HudLayout.BIGGER)
	assert_true(HudLayout.left_handed)
	p.settings.button_size = "enormous"
	HudLayout.configure_from(p, SCREENS[0])
	assert_eq(HudLayout.step, HudLayout.NORMAL, "an unknown size is normal")


func test_the_profile_keeps_the_moves() -> void:
	var p := ProfileData.new()
	p.hud_moves = {"big": {"attack": [-12.0, 4.0]}}
	p.settings.button_size = "big"
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.hud_moves, {"big": {"attack": [-12.0, 4.0]}})
	assert_eq(back.settings.button_size, "big")
	var bad := ProfileData.from_json('{"settings": {"button_size": "tiny", "left_handed": "yes"}, "hud_moves": [1]}')
	assert_eq(bad.settings.button_size, "normal")
	assert_false(bad.settings.left_handed)
	assert_eq(bad.hud_moves, {})
