extends GutTest
## Owner #90: menus with a controller, for every screen through general means (PadFocus): a panel that is watched or
## takes the focus gets it on its first big button (never BACK) once a pad is used; the D-pad and the left stick move it
## by GamepadRules' rules and never out of the panel; Cross / A presses; Circle / B goes back (the panel's pad_back, its
## BACK / CLOSE / X button, else the phone's Back); L1 / R1 turn a panel's pages; a slider slides. While a menu has the
## pad the world's pad inputs are set aside (Cross / A never jumps behind a menu, the stick never walks), and buttons
## made unfocusable for the mouse (FOCUS_NONE) take the pad's focus and give it back to the mouse. The triggers break
## and place once per squeeze. The ring follows the focus.

const SCREEN := Vector2i(1280, 720)

var view: SubViewport
var pad: PadFocus
var outside: Button


class Recorder:
	extends Node
	var back_requests := 0
	var breaks := 0
	var break_ups := 0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST:
			back_requests += 1

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed(&"break"):
			breaks += 1
		elif event.is_action_released(&"break"):
			break_ups += 1


class BackPanel:
	extends VBoxContainer
	var backs := 0

	func pad_back() -> bool:
		backs += 1
		return true


class PadCanvas:
	extends Control
	var moves: Array[Vector2i] = []
	var presses := 0

	func _init() -> void:
		custom_minimum_size = Vector2(300, 200)

	func pad_move(dir: Vector2i) -> bool:
		moves.append(dir)
		return dir != Vector2i.DOWN   # at its bottom edge: the focus leaves it downwards

	func pad_press() -> bool:
		presses += 1
		return true


func before_each() -> void:
	view = SubViewport.new()
	view.size = SCREEN
	view.gui_disable_input = false
	add_child_autofree(view)
	pad = PadFocus.new()
	view.add_child(pad)
	outside = Button.new()   # a HUD button behind the panel: the pad's focus never goes there
	outside.text = "HUD"
	outside.position = Vector2(1100, 600)
	outside.size = Vector2(120, 80)
	view.add_child(outside)


func after_each() -> void:
	for a: StringName in [&"jump", &"move_forward"]:
		Input.action_release(a)


## A panel: a column of rows of buttons (texts), at (100, 60).
func _panel(rows: Array, parent: Node = null) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.position = Vector2(100, 60)
	v.add_theme_constant_override("separation", 20)
	for row: Array in rows:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 20)
		for t: String in row:
			var b := Button.new()
			b.name = t.replace(" ", "_")
			b.text = t
			b.custom_minimum_size = Vector2(64, 64) if t == "SPEAK" else Vector2(240, 90)
			h.add_child(b)
		v.add_child(h)
	(parent if parent else view).add_child(v)
	return v


func _button(event_button: JoyButton, pressed: bool, device := 0) -> void:
	var e := InputEventJoypadButton.new()
	e.device = device
	e.button_index = event_button
	e.pressed = pressed
	view.push_input(e)


func _tap(b: JoyButton) -> void:
	_button(b, true)
	_button(b, false)


func _axis(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.device = 0
	e.axis = axis
	e.axis_value = value
	view.push_input(e)


func _key(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = true
	view.push_input(e)
	var up := e.duplicate() as InputEventKey
	up.pressed = false
	view.push_input(up)


func _focus() -> Control:
	return view.gui_get_focus_owner()


## Drawn frames (GUT's wait_frames counts physics steps, several of which can run in one drawn frame at the start).
func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


## The pad wakes (its first press only shows where the focus is) and the focus settles.
func _wake() -> void:
	_tap(JOY_BUTTON_A)
	await _frames(3)


func test_the_last_input_decides_pad_or_not() -> void:
	watch_signals(pad)
	assert_false(pad.pad)
	_button(JOY_BUTTON_X, true)
	assert_true(pad.pad, "a pad's button")
	assert_signal_emitted_with_parameters(pad, "device_changed", [true])
	_key(KEY_W)
	assert_false(pad.pad, "a key")
	_axis(JOY_AXIS_LEFT_X, 0.9)
	assert_true(pad.pad, "a stick pushed")
	var t := InputEventScreenTouch.new()
	t.pressed = true
	view.push_input(t)
	assert_false(pad.pad, "a finger")
	assert_true(PadFocus.instance == pad)


func test_a_watched_panel_gets_the_focus_on_its_first_big_button() -> void:
	var panel := _panel([["BACK", "SPEAK"], ["SANDBOX", "SURVIVOR"], ["SETTINGS"]])
	PadFocus.watch(panel)
	await _frames(2)
	assert_null(_focus(), "nothing is focused before a pad is used (the mouse and fingers never see a ring)")
	await _wake()
	assert_eq(_focus(), panel.find_child("SANDBOX", true, false), "never BACK or the little speaker")
	assert_eq(pad.ring.target, _focus(), "the ring shows it")
	assert_true(PadFocus.menu_has_pad())


func test_the_d_pad_moves_the_focus_and_never_out_of_the_panel() -> void:
	var panel := _panel([["SANDBOX", "SURVIVOR"], ["SETTINGS", "AVATAR"]])
	PadFocus.watch(panel)
	await _wake()
	_tap(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_focus().name, "SURVIVOR")
	_tap(JOY_BUTTON_DPAD_DOWN)
	assert_eq(_focus().name, "AVATAR")
	_tap(JOY_BUTTON_DPAD_RIGHT)
	_tap(JOY_BUTTON_DPAD_DOWN)
	assert_eq(_focus().name, "AVATAR", "the edge: it stays (the HUD's button behind is never reached)")
	_tap(JOY_BUTTON_DPAD_LEFT)
	_tap(JOY_BUTTON_DPAD_UP)
	assert_eq(_focus().name, "SANDBOX")


func test_the_left_stick_steps_once_then_repeats_while_held() -> void:
	var panel := _panel([["ONE"], ["TWO"], ["THREE"], ["FOUR"]])
	PadFocus.watch(panel)
	await _wake()
	_axis(JOY_AXIS_LEFT_Y, 0.3)
	_axis(JOY_AXIS_LEFT_Y, 0.7)
	_axis(JOY_AXIS_LEFT_Y, 0.9)
	_axis(JOY_AXIS_LEFT_Y, 1.0)
	assert_eq(_focus().name, "TWO", "one push, one step (not one per stick event)")
	pad.step(GamepadRules.REPEAT_WAIT + 0.01)
	assert_eq(_focus().name, "THREE", "held: it goes on")
	_axis(JOY_AXIS_LEFT_Y, 0.0)
	pad.step(2.0)
	assert_eq(_focus().name, "THREE", "let go: it stops")


func test_cross_presses_the_focused_button() -> void:
	var panel := _panel([["PLAY"]])
	PadFocus.watch(panel)
	await _wake()
	var play := panel.find_child("PLAY", true, false) as Button
	watch_signals(play)
	_tap(JOY_BUTTON_A)
	assert_signal_emitted(play, "pressed")


func test_the_first_press_only_shows_the_focus() -> void:
	var panel := _panel([["PLAY"]])
	PadFocus.watch(panel)
	await _frames(2)
	var play := panel.find_child("PLAY", true, false) as Button
	watch_signals(play)
	_tap(JOY_BUTTON_A)
	await _frames(2)
	assert_signal_not_emitted(play, "pressed", "the press that woke the pad did not press PLAY unseen")
	assert_eq(_focus(), play)


func test_circle_presses_the_panel_s_back_button() -> void:
	var panel := _panel([["◀ BACK", "SPEAK"], ["LESSON 1", "LESSON 2"]])
	PadFocus.watch(panel)
	await _wake()
	var back := panel.find_child("◀_BACK", true, false) as Button
	watch_signals(back)
	_tap(JOY_BUTTON_B)
	assert_signal_emitted(back, "pressed")


func test_circle_asks_the_panel_first() -> void:
	var panel := BackPanel.new()
	_panel([["CLOSE", "OK"]], panel)
	view.add_child(panel)
	PadFocus.watch(panel)
	await _wake()
	var close := panel.find_child("CLOSE", true, false) as Button
	watch_signals(close)
	_tap(JOY_BUTTON_B)
	assert_eq(panel.backs, 1, "its pad_back() said it went back")
	assert_signal_not_emitted(close, "pressed")


func test_circle_without_a_back_button_is_the_phone_s_back() -> void:
	var rec := Recorder.new()
	add_child_autofree(rec)
	var panel := _panel([["RESUME"], ["SETTINGS"]])
	PadFocus.watch(panel)
	await _wake()
	_tap(JOY_BUTTON_B)
	assert_eq(rec.back_requests, 1, "the game's Back (Android's) goes round the tree")
	assert_false(PadFocus.back_from_pad, "only while it goes round")


func test_a_menu_sets_the_world_s_pad_inputs_aside() -> void:
	var a := GamepadRules.make_event({"button": JOY_BUTTON_A})
	var panel := _panel([["PLAY"]])
	panel.visible = false
	PadFocus.watch(panel)
	await _frames(2)
	assert_true(InputMap.action_has_event(&"jump", a), "playing: Cross / A jumps")
	panel.visible = true
	await _frames(2)
	assert_false(InputMap.action_has_event(&"jump", a), "a menu has the pad: Cross / A never jumps behind it")
	assert_true(InputMap.action_has_event(&"ui_accept", a), "and presses the menu's button")
	assert_true(InputMap.action_has_event(&"pause", GamepadRules.make_event({"button": JOY_BUTTON_START})),
		"Options still closes the menu")
	assert_true(KeysRules.key_text("jump") == "Space", "the keys stay")
	panel.visible = false
	await _frames(2)
	assert_true(InputMap.action_has_event(&"jump", a), "closed: back to playing")


func test_leaving_the_game_gives_the_inputs_back() -> void:
	var a := GamepadRules.make_event({"button": JOY_BUTTON_A})
	var panel := _panel([["PLAY"]])
	PadFocus.watch(panel)
	await _frames(2)
	assert_false(InputMap.action_has_event(&"jump", a))
	pad.queue_free()
	await _frames(2)
	assert_true(InputMap.action_has_event(&"jump", a), "never left without its pad inputs")


func test_mouse_only_buttons_take_the_pad_s_focus_and_give_it_back() -> void:
	var panel := _panel([["LAND", "MAP"]])
	for b in panel.find_children("*", "Button", true, false):
		(b as Button).focus_mode = Control.FOCUS_NONE
	PadFocus.watch(panel)
	await _wake()
	var land := panel.find_child("LAND", true, false) as Button
	assert_eq(_focus(), land, "a FOCUS_NONE button takes the pad's focus")
	_tap(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_focus().name, "MAP")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(5, 5)
	view.push_input(click)
	assert_false(pad.pad)
	assert_null(_focus(), "the mouse again: no focus left for Space to press")
	assert_eq(land.focus_mode, Control.FOCUS_NONE, "made mouse-only again")
	assert_eq((panel.find_child("MAP", true, false) as Button).focus_mode, Control.FOCUS_NONE)


func test_the_newest_panel_has_the_pad_and_the_one_under_remembers() -> void:
	var under := _panel([["ONE", "TWO"]])
	PadFocus.watch(under)
	await _wake()
	_tap(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(_focus().name, "TWO")
	var over := _panel([["YES", "NO"]])
	over.position = Vector2(400, 300)
	PadFocus.take(over)
	await _frames(2)
	assert_eq(_focus().name, "YES", "the new panel has the pad")
	over.visible = false
	await _frames(2)
	assert_eq(_focus().name, "TWO", "closed: back where the child was")


func test_new_content_in_a_panel_gets_the_focus() -> void:
	var holder := CenterContainer.new()
	holder.size = Vector2(SCREEN)
	view.add_child(holder)
	PadFocus.watch(holder)
	_panel([["SCHOOL"]], holder)
	await _wake()
	assert_eq(_focus().name, "SCHOOL")
	for c in holder.get_children():
		c.queue_free()
	_panel([["BACK"], ["MATHS", "SCIENCE"]], holder)
	await _frames(3)
	assert_eq(_focus().name, "MATHS", "the next screen's first big button")


func test_l1_and_r1_turn_a_panel_s_pages() -> void:
	var panel := VBoxContainer.new()
	var tabs := TabBar.new()
	for t in ["BLOCKS", "ARMORY", "SMART"]:
		tabs.add_tab(t)
	tabs.set_tab_hidden(1, true)
	panel.add_child(tabs)
	_panel([["STONE", "DIRT"]], panel)
	view.add_child(panel)
	PadFocus.watch(panel)
	await _wake()
	_tap(JOY_BUTTON_RIGHT_SHOULDER)
	assert_eq(tabs.current_tab, 2, "the next page a child can see")
	_tap(JOY_BUTTON_LEFT_SHOULDER)
	assert_eq(tabs.current_tab, 0)


func test_left_and_right_slide_a_slider() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(100, 100)
	var s := HSlider.new()
	s.custom_minimum_size = Vector2(300, 40)
	s.max_value = 100
	s.step = 5
	s.value = 50
	s.set_meta(&"pad_first", true)
	panel.add_child(s)
	view.add_child(panel)
	PadFocus.watch(panel)
	await _wake()
	assert_eq(_focus(), s)
	_tap(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(s.value, 55.0)
	_tap(JOY_BUTTON_DPAD_LEFT)
	_tap(JOY_BUTTON_DPAD_LEFT)
	assert_eq(s.value, 45.0)


func test_a_drawn_panel_takes_the_d_pad_and_cross_itself() -> void:
	var panel := VBoxContainer.new()
	panel.position = Vector2(100, 60)
	var canvas := PadCanvas.new()
	panel.add_child(canvas)
	_panel([["CHECK"]], panel)
	view.add_child(panel)
	PadFocus.take(panel, canvas)
	await _wake()
	assert_eq(_focus(), canvas)
	_tap(JOY_BUTTON_DPAD_RIGHT)
	assert_eq(canvas.moves, [Vector2i.RIGHT])
	_tap(JOY_BUTTON_A)
	assert_eq(canvas.presses, 1)
	_tap(JOY_BUTTON_DPAD_DOWN)
	assert_eq(_focus().name, "CHECK", "past its edge the focus moves on")


func test_playing_the_triggers_break_once_per_squeeze() -> void:
	var rec := Recorder.new()
	view.add_child(rec)
	for v: float in [0.2, 0.55, 0.7, 0.9, 1.0, 0.8, 0.6]:
		_axis(JOY_AXIS_TRIGGER_RIGHT, v)
	for v: float in [0.3, 0.1, 0.0]:
		_axis(JOY_AXIS_TRIGGER_RIGHT, v)
	assert_eq(rec.breaks, 1, "one squeeze, one block")
	assert_eq(rec.break_ups, 1)
	assert_false(PadFocus.menu_has_pad())
	assert_true(PadFocus.playing_with_pad())


func test_playing_leaves_no_hidden_focus_for_cross() -> void:
	outside.grab_focus()
	_tap(JOY_BUTTON_A)
	assert_null(_focus(), "a button clicked earlier never takes Cross / A while playing")
