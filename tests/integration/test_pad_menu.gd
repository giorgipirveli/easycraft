extends GutTest
## Owner #90: the main menu with a game controller. Its screens have the pad (PadFocus watches the menu's middle): the
## focus starts on SANDBOX, the D-pad reaches every button of the main screen, Cross / A opens SETTINGS with the focus
## in it, Circle / B is SETTINGS' BACK, and on the main screen Circle / B never quits the game (a phone's Back would).

var menu: Node
var pad: PadFocus
var quits := 0


func before_each() -> void:
	quits = 0
	pad = PadFocus.new()
	add_child_autofree(pad)
	menu = load("res://ui/menus/menu.tscn").instantiate()
	menu.set("quit_game", func() -> void: quits += 1)
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_main")
	await wait_process_frames(3)


func _tap(b: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = b
		e.pressed = pressed
		get_viewport().push_input(e)


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func _center() -> Control:
	return menu.get("_center") as Control


func test_the_main_screen_starts_on_sandbox_and_every_button_is_reachable() -> void:
	_tap(JOY_BUTTON_A)
	await wait_process_frames(3)
	assert_not_null(_focus())
	assert_true((_focus() as Button).text.begins_with("SANDBOX"), "the first big button: %s" % (_focus() as Button).text)
	var list := pad.candidates(_center())
	var rects := list.map(func(c: Control) -> Rect2: return c.get_global_rect())
	assert_eq(GamepadRules.reachable(list.find(_focus()), rects).size(), list.size(), "every button of the main screen")


func test_settings_opens_with_the_focus_in_it_and_circle_comes_back() -> void:
	_tap(JOY_BUTTON_A)
	await wait_process_frames(3)
	var settings: Button = null
	for b in pad.candidates(_center()):
		if b is Button and (b as Button).text == "SETTINGS":
			settings = b
	assert_not_null(settings)
	settings.grab_focus()
	_tap(JOY_BUTTON_A)
	await wait_process_frames(4)
	assert_eq(_focus().name, "Page_game", "SETTINGS has the focus")
	_tap(JOY_BUTTON_B)
	await wait_process_frames(4)
	assert_true((_focus() as Button).text.begins_with("SANDBOX"), "back on the main screen")


func test_circle_on_the_main_screen_never_quits() -> void:
	_tap(JOY_BUTTON_A)
	await wait_process_frames(3)
	_tap(JOY_BUTTON_B)
	await wait_process_frames(2)
	assert_eq(quits, 0, "a pad's Circle / B is not the phone's quit")
