extends GutTest
## Owner #90: every controller action goes through the game's input map (project.godot, written by
## tools/setup_input_map.gd from GamepadRules.BINDINGS): the pad's events sit beside the keys, the keys stay as they
## were, and Cross / A also presses a menu's focused button (ui_accept).


func test_every_pad_binding_is_in_the_input_map() -> void:
	for b: Dictionary in GamepadRules.BINDINGS:
		assert_true(InputMap.has_action(b.action), "%s exists" % b.action)
		assert_true(InputMap.action_has_event(b.action, GamepadRules.make_event(b.spec)),
			"%s has %s" % [b.action, b.spec])


func test_the_keys_and_the_mouse_stay() -> void:
	assert_eq(KeysRules.key_text("jump"), "Space")
	assert_eq(KeysRules.key_text("move_forward"), "W")
	assert_eq(KeysRules.key_text("pause"), "Esc")
	assert_eq(KeysRules.key_text("break"), "Left click")
	assert_eq(KeysRules.key_text("place"), "Right click")
	var accept_keys := InputMap.action_get_events(&"ui_accept").filter(func(e: InputEvent) -> bool:
		return e is InputEventKey).map(func(e: InputEvent) -> Key: return (e as InputEventKey).keycode)
	for k: Key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		assert_has(accept_keys, k, "ui_accept keeps its keys")


func test_the_pad_s_own_actions_have_no_keys() -> void:
	for a: StringName in GamepadRules.PAD_ONLY:
		for e: InputEvent in InputMap.action_get_events(a):
			assert_true(GamepadRules.is_pad_event(e), "%s: only pad events (%s)" % [a, e.as_text()])


func test_the_triggers_press_half_way() -> void:
	assert_almost_eq(InputMap.action_get_deadzone(&"break"), GamepadRules.TRIGGER_DEADZONE, 0.001)
	assert_almost_eq(InputMap.action_get_deadzone(&"place"), GamepadRules.TRIGGER_DEADZONE, 0.001)


func test_a_pad_press_presses_the_action() -> void:
	var e := InputEventJoypadButton.new()
	e.device = 0
	e.button_index = JOY_BUTTON_A
	e.pressed = true
	assert_true(e.is_action_pressed(&"jump"))
	assert_true(e.is_action_pressed(&"ui_accept"))
	var t := InputEventJoypadMotion.new()
	t.device = 0
	t.axis = JOY_AXIS_TRIGGER_RIGHT
	t.axis_value = 0.3
	assert_false(t.is_action_pressed(&"break"), "a trigger touched lightly does not break")
	t.axis_value = 0.9
	assert_true(t.is_action_pressed(&"break"))
