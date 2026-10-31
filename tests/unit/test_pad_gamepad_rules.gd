extends GutTest
## Owner #90 (spec §20.3): a PlayStation or Xbox controller plays the whole game. GamepadRules is the pure part: the
## button table (every action through the input map), which pad it is by its name and the words its buttons have, the
## right stick's look, which input came last (a pad or the keyboard, mouse and fingers), and the focus rules every menu
## follows (where the focus starts, where the D-pad takes it, the stick's steps and repeats, which button is BACK).


# --- The table ---

func test_the_table_gives_every_playing_action_a_pad_input() -> void:
	for action: StringName in [&"move_forward", &"move_back", &"move_left", &"move_right", &"look_up", &"look_down",
			&"look_left", &"look_right", &"jump", &"break", &"place", &"hotbar_prev", &"hotbar_next", &"attack",
			&"physics_mode", &"fly_up", &"fly_down", &"crouch", &"camera_toggle", &"size_mode", &"pause", &"map",
			&"blocks", &"more", &"ui_accept"]:
		assert_false(GamepadRules.specs_for(action).is_empty(), "%s has a pad input" % action)


func test_the_buttons_are_the_brief_s() -> void:
	assert_eq(GamepadRules.specs_for(&"jump"), [{"button": JOY_BUTTON_A}], "Cross / A jumps")
	assert_eq(GamepadRules.specs_for(&"break"), [{"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}], "R2 / RT breaks")
	assert_eq(GamepadRules.specs_for(&"place"), [{"axis": JOY_AXIS_TRIGGER_LEFT, "value": 1.0}], "L2 / LT places")
	assert_eq(GamepadRules.specs_for(&"hotbar_prev"), [{"button": JOY_BUTTON_LEFT_SHOULDER}])
	assert_eq(GamepadRules.specs_for(&"hotbar_next"), [{"button": JOY_BUTTON_RIGHT_SHOULDER}])
	assert_eq(GamepadRules.specs_for(&"attack"), [{"button": JOY_BUTTON_X}], "Square / X attacks")
	assert_eq(GamepadRules.specs_for(&"physics_mode"), [{"button": JOY_BUTTON_Y}], "Triangle / Y: walk, fly or ghost")
	assert_eq(GamepadRules.specs_for(&"fly_up"), [{"button": JOY_BUTTON_DPAD_UP}])
	assert_eq(GamepadRules.specs_for(&"fly_down"), [{"button": JOY_BUTTON_DPAD_DOWN}])
	assert_eq(GamepadRules.specs_for(&"pause"), [{"button": JOY_BUTTON_START}], "Options / Menu pauses")
	assert_eq(GamepadRules.specs_for(&"map"), [{"button": JOY_BUTTON_BACK}, {"button": JOY_BUTTON_TOUCHPAD}],
		"the touchpad (and Create) / View opens the map")
	assert_eq(GamepadRules.specs_for(&"ui_accept"), [{"button": JOY_BUTTON_A}], "Cross / A presses in menus")


func test_one_button_one_job_while_playing() -> void:
	var seen := {}
	var rocket := {}   # the cockpit's own (the rocket flight): live only while the child flies, when the world's are not
	for b: Dictionary in GamepadRules.BINDINGS:
		if b.action == &"ui_accept":
			continue   # the menus' press shares Cross / A with JUMP (a menu sets the world's inputs aside)
		var key := str(b.spec)
		var in_use := rocket if str(b.action).begins_with("rocket_") else seen
		assert_false(in_use.has(key), "%s is also %s" % [b.action, in_use.get(key, "")])
		in_use[key] = b.action


func test_the_world_s_actions_are_set_aside_in_menus_but_not_the_menu_s_own() -> void:
	var world := GamepadRules.world_actions()
	assert_has(world, &"jump")
	assert_has(world, &"move_forward")
	assert_has(world, &"look_left")
	assert_has(world, &"crouch")
	assert_does_not_have(world, &"pause", "Options still opens and closes the pause menu")
	assert_does_not_have(world, &"map", "the map button still closes the map")
	assert_does_not_have(world, &"ui_accept", "Cross / A presses the menu's buttons")


func test_events_are_built_from_the_table_and_match_it() -> void:
	var a := GamepadRules.make_event({"button": JOY_BUTTON_A}) as InputEventJoypadButton
	assert_eq(a.button_index, JOY_BUTTON_A)
	assert_eq(a.device, -1, "every pad")
	var rt := GamepadRules.make_event({"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0}) as InputEventJoypadMotion
	assert_eq(rt.axis, JOY_AXIS_TRIGGER_RIGHT)
	assert_eq(rt.axis_value, 1.0)
	assert_eq(rt.device, -1)
	assert_true(GamepadRules.is_pad_event(a))
	assert_false(GamepadRules.is_pad_event(InputEventKey.new()))

# --- Which pad ---

func test_the_pad_s_name_tells_playstation_from_xbox() -> void:
	for n: String in ["PS5 Controller", "DualSense Wireless Controller", "PS4 Controller", "Wireless Controller",
			"Sony Interactive Entertainment Wireless Controller",
			"DualSense Wireless Controller (STANDARD GAMEPAD Vendor: 054c Product: 0ce6)",
			"054c-09cc-Wireless Controller", "DUALSHOCK 4 Wireless Controller"]:
		assert_eq(GamepadRules.family(n), GamepadRules.PLAYSTATION, n)
	for n: String in ["Xbox Series X Controller", "Xbox One Controller", "XInput Gamepad (GLFW)",
			"Xbox 360 Controller (XInput STANDARD GAMEPAD)", "Microsoft X-Box 360 pad", "045e-0b13-Xbox Wireless Controller"]:
		assert_eq(GamepadRules.family(n), GamepadRules.XBOX, n)
	for n: String in ["", "Standard Gamepad", "USB Gamepad", "Logitech Dual Action"]:
		assert_eq(GamepadRules.family(n), GamepadRules.GENERIC, n)


func test_each_pad_s_own_words_for_its_buttons() -> void:
	var ps := GamepadRules.PLAYSTATION
	var xb := GamepadRules.XBOX
	assert_eq(GamepadRules.button_word(JOY_BUTTON_A, ps), "Cross")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_B, ps), "Circle")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_X, ps), "Square")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_Y, ps), "Triangle")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_START, ps), "Options")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_TOUCHPAD, ps), "Touchpad")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_LEFT_SHOULDER, ps), "L1")
	assert_eq(GamepadRules.axis_word(JOY_AXIS_TRIGGER_RIGHT, ps), "R2")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_A, xb), "A")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_B, xb), "B")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_START, xb), "Menu")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_BACK, xb), "View")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_RIGHT_SHOULDER, xb), "RB")
	assert_eq(GamepadRules.axis_word(JOY_AXIS_TRIGGER_LEFT, xb), "LT")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_A, GamepadRules.GENERIC), "A", "any other pad: the Xbox letters")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_DPAD_UP, ps), "D-pad up")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_RIGHT_STICK, ps), "R3")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_RIGHT_STICK, xb), "RS")


func test_the_card_s_lines_name_the_pad_s_buttons() -> void:
	assert_gte(GamepadRules.CARD_LINES.size(), 14)
	var words := {}
	for line: Array in GamepadRules.CARD_LINES:
		words[str(line[1])] = GamepadRules.line_words(line[0], GamepadRules.PLAYSTATION)
		assert_ne(words[str(line[1])], "", str(line[1]))
	assert_eq(words["Walk"], "Left stick")
	assert_eq(words["Look around"], "Right stick")
	assert_eq(GamepadRules.line_words([&"jump"], GamepadRules.PLAYSTATION), "Cross")
	assert_eq(GamepadRules.line_words([&"jump"], GamepadRules.XBOX), "A")
	assert_eq(GamepadRules.line_words([&"hotbar_prev", &"hotbar_next"], GamepadRules.PLAYSTATION), "L1 / R1")
	assert_eq(GamepadRules.line_words([&"hotbar_prev", &"hotbar_next"], GamepadRules.XBOX), "LB / RB")
	assert_eq(GamepadRules.line_words([&"break"], GamepadRules.XBOX), "RT")
	assert_eq(GamepadRules.line_words([&"map"], GamepadRules.PLAYSTATION), "Touchpad", "a PlayStation's map: its touchpad")
	assert_eq(GamepadRules.line_words([&"map"], GamepadRules.XBOX), "View")
	assert_eq(GamepadRules.line_words([&"fly_up", &"fly_down"], GamepadRules.XBOX), "D-pad up / down")


func test_every_card_line_is_a_real_binding() -> void:
	for line: Array in GamepadRules.CARD_LINES:
		for a: StringName in line[0]:
			if String(a).begins_with("menu:") or String(a).begins_with("stick:"):
				continue
			assert_false(GamepadRules.specs_for(a).is_empty(), "%s is bound" % a)

# --- Which input came last ---

func test_a_pad_press_or_a_real_push_counts_as_the_pad() -> void:
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_A
	b.pressed = true
	assert_eq(GamepadRules.device_of(b), GamepadRules.PAD)
	b.pressed = false
	assert_eq(GamepadRules.device_of(b), &"", "a release tells nothing")
	var m := InputEventJoypadMotion.new()
	m.axis = JOY_AXIS_LEFT_X
	m.axis_value = 0.2
	assert_eq(GamepadRules.device_of(m), &"", "a stick resting a little off the middle is not a child playing")
	m.axis_value = -0.8
	assert_eq(GamepadRules.device_of(m), GamepadRules.PAD)


func test_keys_clicks_and_fingers_count_as_the_other_hands() -> void:
	var k := InputEventKey.new()
	k.pressed = true
	k.keycode = KEY_W
	assert_eq(GamepadRules.device_of(k), GamepadRules.OTHER)
	var c := InputEventMouseButton.new()
	c.pressed = true
	c.button_index = MOUSE_BUTTON_LEFT
	assert_eq(GamepadRules.device_of(c), GamepadRules.OTHER)
	var t := InputEventScreenTouch.new()
	t.pressed = true
	assert_eq(GamepadRules.device_of(t), GamepadRules.OTHER)
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(30, 0)
	assert_eq(GamepadRules.device_of(move), &"", "a mouse moving (or a PlayStation's touchpad as a mouse) never switches")

# --- The right stick's look ---

func test_the_look_has_a_dead_middle_and_a_soft_start() -> void:
	assert_eq(GamepadRules.look_curve(Vector2(0.1, 0.05)), Vector2.ZERO, "inside the dead zone: still")
	var half := GamepadRules.look_curve(Vector2(0.56, 0.0))
	var full := GamepadRules.look_curve(Vector2(1.0, 0.0))
	assert_almost_eq(full.x, 1.0, 0.001, "full tilt: full speed")
	assert_lt(half.x, 0.5, "half a tilt turns slower than half speed (fine aiming)")
	assert_gt(half.x, 0.0)
	assert_almost_eq(GamepadRules.look_curve(Vector2(0.0, -1.0)).y, -1.0, 0.001)
	assert_almost_eq(GamepadRules.look_curve(Vector2(0.9, 0.9)).length(), 1.0, 0.001, "never past full speed")


func test_the_look_turns_at_the_chosen_speed() -> void:
	var dt := 0.5
	var normal := GamepadRules.look_step(Vector2(1, 0), dt, "normal")
	assert_almost_eq(normal.x, GamepadRules.LOOK_SPEED * dt, 0.0001, "radians sideways")
	assert_almost_eq(GamepadRules.look_step(Vector2(1, 0), dt, "slow").x, normal.x * 0.6, 0.0001)
	assert_almost_eq(GamepadRules.look_step(Vector2(1, 0), dt, "fast").x, normal.x * 1.5, 0.0001)
	assert_almost_eq(GamepadRules.look_step(Vector2(1, 0), dt, "unknown").x, normal.x, 0.0001)
	var up := GamepadRules.look_step(Vector2(0, -1), dt, "normal")
	assert_almost_eq(up.y, -GamepadRules.LOOK_SPEED * GamepadRules.LOOK_PITCH_SHARE * dt, 0.0001,
		"up and down a little slower than sideways")
	assert_eq(GamepadRules.look_step(Vector2.ZERO, dt, "normal"), Vector2.ZERO)
	assert_has(GamepadRules.LOOK_SPEEDS.keys(), "normal")
	assert_eq(GamepadRules.LOOK_SPEED_ORDER, ["slow", "normal", "fast"])


func test_the_look_moves_the_camera_like_the_mouse() -> void:
	var rig := CameraRig.new()
	var arm := SpringArm3D.new()
	arm.name = "SpringArm3D"
	rig.add_child(arm)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	arm.add_child(cam)
	add_child_autofree(rig)
	var yaw := rig.yaw
	var pitch := rig.pitch
	rig.look(GamepadRules.look_step(Vector2(1, 0), 0.1, "normal"), 1.0)
	assert_lt(rig.yaw, yaw, "the stick to the right turns right (as the mouse to the right)")
	rig.look(GamepadRules.look_step(Vector2(0, -1), 0.1, "normal"), 1.0)
	assert_gt(rig.pitch, pitch, "the stick pushed up looks up (never upside down)")

# --- Focus: where it starts ---

func _item(r: Rect2, back := false, first := false) -> Dictionary:
	return {"rect": r, "back": back, "first": first}


func test_the_focus_starts_on_the_first_big_button_in_reading_order() -> void:
	var items := [
		_item(Rect2(40, 20, 150, 64), true),        # BACK, top left
		_item(Rect2(500, 24, 56, 56)),              # the speaker beside the title
		_item(Rect2(100, 200, 300, 120)),           # SANDBOX
		_item(Rect2(420, 200, 300, 120)),           # SURVIVOR
		_item(Rect2(420, 360, 260, 76)),            # SETTINGS
	]
	assert_eq(GamepadRules.first_focus(items), 2, "never BACK, never the little speaker")
	items[4]["first"] = true
	assert_eq(GamepadRules.first_focus(items), 4, "a panel's own choice wins")
	assert_eq(GamepadRules.first_focus([_item(Rect2(0, 0, 100, 60), true)]), 0, "only BACK: BACK")
	assert_eq(GamepadRules.first_focus([]), -1)


func test_reading_order_is_rows_then_left_to_right() -> void:
	var rects := [Rect2(300, 104, 100, 50), Rect2(20, 100, 100, 60), Rect2(20, 300, 100, 50), Rect2(160, 96, 100, 60)]
	assert_eq(GamepadRules.reading_order(rects), [1, 3, 0, 2])

# --- Focus: where the D-pad takes it ---

func test_down_goes_to_the_button_below_not_the_one_beside() -> void:
	# a 3 x 2 grid of 100 x 60 buttons, 20 apart
	var rects: Array[Rect2] = []
	for row in 2:
		for col in 3:
			rects.append(Rect2(col * 120, row * 80, 100, 60))
	assert_eq(GamepadRules.next_focus(rects[0], Vector2i.DOWN, rects), 3)
	assert_eq(GamepadRules.next_focus(rects[1], Vector2i.DOWN, rects), 4)
	assert_eq(GamepadRules.next_focus(rects[4], Vector2i.RIGHT, rects), 5)
	assert_eq(GamepadRules.next_focus(rects[4], Vector2i.UP, rects), 1)
	assert_eq(GamepadRules.next_focus(rects[3], Vector2i.LEFT, rects), -1, "the edge: it stays")
	assert_eq(GamepadRules.next_focus(rects[2], Vector2i.UP, rects), -1)


func test_from_a_wide_button_down_to_the_nearest_of_a_row() -> void:
	var resume := Rect2(100, 100, 420, 96)
	var avatar := Rect2(100, 214, 204, 86)
	var settings := Rect2(316, 214, 204, 86)
	var rects: Array[Rect2] = [resume, avatar, settings]
	assert_eq(GamepadRules.next_focus(resume, Vector2i.DOWN, rects), 1)
	assert_eq(GamepadRules.next_focus(settings, Vector2i.UP, rects), 0)


func test_a_row_below_wins_over_a_neighbour_a_little_lower() -> void:
	var here := Rect2(100, 100, 100, 60)
	var beside := Rect2(220, 108, 100, 60)    # the same row, drawn a little lower
	var below := Rect2(110, 200, 100, 60)
	assert_eq(GamepadRules.next_focus(here, Vector2i.DOWN, [here, beside, below]), 2)
	assert_eq(GamepadRules.next_focus(here, Vector2i.RIGHT, [here, beside, below]), 1)


func test_every_button_of_a_ragged_page_can_be_reached() -> void:
	# a settings-like page: rows of different widths and counts
	var rects: Array[Rect2] = [Rect2(400, 10, 200, 60), Rect2(620, 10, 200, 60), Rect2(840, 10, 200, 60),
		Rect2(200, 100, 170, 76), Rect2(390, 100, 170, 76), Rect2(580, 100, 170, 76),
		Rect2(120, 200, 180, 76), Rect2(320, 200, 180, 76), Rect2(700, 200, 180, 76), Rect2(900, 200, 180, 76),
		Rect2(300, 300, 200, 40), Rect2(800, 300, 60, 40), Rect2(500, 400, 240, 76)]
	assert_eq(GamepadRules.reachable(0, rects).size(), rects.size())

# --- The stick's steps, and a held direction repeating ---

func test_the_stick_steps_once_past_the_middle_and_again_after_coming_back() -> void:
	var d := GamepadRules.stick_direction(Vector2(0.3, 0.0), Vector2i.ZERO)
	assert_eq(d, Vector2i.ZERO, "a small push is not a step")
	d = GamepadRules.stick_direction(Vector2(0.8, 0.1), d)
	assert_eq(d, Vector2i.RIGHT)
	d = GamepadRules.stick_direction(Vector2(0.45, 0.1), d)
	assert_eq(d, Vector2i.RIGHT, "held a bit less: still the same step (no flicker)")
	d = GamepadRules.stick_direction(Vector2(0.1, 0.0), d)
	assert_eq(d, Vector2i.ZERO, "back to the middle")
	assert_eq(GamepadRules.stick_direction(Vector2(-0.2, -0.9), Vector2i.ZERO), Vector2i.UP)
	assert_eq(GamepadRules.stick_direction(Vector2(0.1, 0.7), Vector2i.ZERO), Vector2i.DOWN)


func test_a_held_direction_repeats_after_a_wait() -> void:
	var r := GamepadRules.Repeat.new()
	assert_true(r.hold(Vector2i.DOWN), "a new direction steps at once")
	assert_false(r.hold(Vector2i.DOWN), "the same held direction does not step again by itself")
	assert_false(r.advance(GamepadRules.REPEAT_WAIT - 0.05))
	assert_true(r.advance(0.1), "after the wait it steps")
	assert_false(r.advance(GamepadRules.REPEAT_EVERY * 0.5))
	assert_true(r.advance(GamepadRules.REPEAT_EVERY * 0.6), "then every little while")
	r.hold(Vector2i.ZERO)
	assert_false(r.advance(5.0), "let go: nothing")

# --- Which button is BACK ---

func test_back_words() -> void:
	for w: String in ["BACK", "Close", "X", "✕", "CANCEL", "NOT NOW", " back ", "◀ BACK", "< BACK"]:
		assert_true(GamepadRules.is_back_word(w), w)
	for w: String in ["PLAY", "DONE", "BACKPACK", "EXIT", "OK", ""]:
		assert_false(GamepadRules.is_back_word(w), w)


## The rocket flight with a controller (owner #90 with #79): the left stick steers, R2 / RT is the throttle, Cross / A
## the action (LIFT-OFF, STAGE, BURN, LEGS, CHUTE), R3 / RS the view; the CONTROLLER card says so.
func test_the_rocket_flies_with_a_controller() -> void:
	for a: StringName in [&"rocket_steer_up", &"rocket_steer_down", &"rocket_steer_left", &"rocket_steer_right",
			&"rocket_throttle", &"rocket_action", &"rocket_view"]:
		assert_false(GamepadRules.specs_for(a).is_empty(), "%s has a pad input" % a)
	assert_eq(GamepadRules.specs_for(&"rocket_action")[0], {"button": JOY_BUTTON_A})
	assert_eq(GamepadRules.specs_for(&"rocket_throttle")[0], {"axis": JOY_AXIS_TRIGGER_RIGHT, "value": 1.0})
	var card := GamepadRules.CARD_LINES.map(func(l: Array) -> String: return str(l[1]))
	assert_true(card.any(func(t: String) -> bool: return t.begins_with("Rocket")), "the card tells the rocket")
