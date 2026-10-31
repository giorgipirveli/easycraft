extends GutTest
## M3 Task 13 (spec §5.11, §14.10): the small black "admin panel" text at the bottom of the main
## menu opens the secret-code field (big input, OK / BACK). The field's own tests use a private
## profile, save hook, rate limiter and reward table, so they never touch the real profile.

const TEST_CODE := "test-gold"
const SCREEN := Vector2i(2400, 1080)   # the emulator's landscape screen

var menu: Node
var _window_size: Vector2i
var _saves := 0   # calls of the field's save hook


func before_all() -> void:
	_window_size = get_window().size


func before_each() -> void:
	_saves = 0


func after_all() -> void:
	get_window().size = _window_size


func _admin(from: Node) -> Button:
	return from.find_child("AdminPanel", true, false) as Button


func _code_panel(from: Node) -> CodePanel:
	for n in from.find_children("*", "", true, false):
		if n is CodePanel and (n as CodePanel).is_visible_in_tree():
			return n
	return null


func _button(from: Node, text: String) -> Button:
	for b in from.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null


func _open_menu() -> void:
	get_window().size = SCREEN
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_main")
	await wait_process_frames(2)


# --- The main menu's text ------------------------------------------------------------------

func test_the_main_menu_has_a_small_black_admin_panel_text_at_the_bottom() -> void:
	await _open_menu()
	var link := _admin(menu)
	assert_not_null(link, "the admin panel text")
	if link == null:
		return
	assert_true(link.is_visible_in_tree())
	assert_eq(link.text, "admin panel")
	assert_true(link.flat, "text, not a big button")
	assert_eq(link.get_theme_color("font_color"), Color.BLACK)
	assert_lte(link.get_theme_font_size("font_size"), 24, "small")
	var screen := link.get_viewport_rect().size
	var r := link.get_global_rect()
	gut.p("admin panel text at %s on a %s screen" % [r, screen])
	assert_gt(r.position.y, screen.y * 0.85, "at the bottom: %s" % r)
	assert_lte(r.end.y, screen.y, "on screen")
	for text: String in ["SETTINGS", "SANDBOX\nBuild anything!", "SURVIVOR\nSurvive the night!"]:
		var b := _button(menu, text)
		assert_not_null(b, text)
		if b:
			assert_false(b.get_global_rect().intersects(r), "does not cover %s" % text)


func test_the_admin_text_opens_the_code_field() -> void:
	await _open_menu()
	_admin(menu).pressed.emit()
	await wait_process_frames(2)
	var panel := _code_panel(menu)
	assert_not_null(panel, "the code field")
	if panel == null:
		return
	assert_true(panel.field.is_visible_in_tree())
	assert_gte(panel.field.custom_minimum_size.y, 80.0, "a big friendly input")
	assert_not_null(_button(panel, "OK"))
	assert_not_null(_button(panel, "BACK"))
	assert_false(_admin(menu).is_visible_in_tree(), "the text shows on the main screen only")


func test_back_returns_to_the_main_menu() -> void:
	await _open_menu()
	_admin(menu).pressed.emit()
	await wait_process_frames(2)
	_button(menu, "BACK").pressed.emit()
	await wait_process_frames(2)
	assert_null(_code_panel(menu))
	assert_not_null(_button(menu, "SETTINGS"), "back on the main screen")
	assert_true(_admin(menu).is_visible_in_tree())


func test_onboarding_screens_do_not_show_the_admin_text() -> void:
	await _open_menu()
	menu.call("_show_name")
	await wait_process_frames(2)
	assert_false(_admin(menu).is_visible_in_tree())


# --- The code field ---------------------------------------------------------------------------

func _panel(profile: ProfileData) -> CodePanel:
	var p := CodePanel.new()
	p.profile = profile
	p.save_profile = func() -> void: _saves += 1
	p.tries = CodeTries.new()
	p.rewards = {CodeRules.hash_code(TEST_CODE): {"kind": CodeRules.KIND_GOLD, "amount": 1000}}
	add_child_autofree(p)
	return p


func _type_and_ok(panel: CodePanel, code: String) -> void:
	panel.field.text = code
	panel.field.text_changed.emit(code)
	_button(panel, "OK").pressed.emit()


func test_ok_waits_for_a_code() -> void:
	var panel := _panel(ProfileData.new())
	await wait_process_frames(1)
	assert_true(panel.ok.disabled, "nothing typed yet")
	panel.field.text = "x"
	panel.field.text_changed.emit("x")
	assert_false(panel.ok.disabled)


func test_a_right_code_pays_saves_and_rains_coins() -> void:
	var profile := ProfileData.new()
	profile.survivor_gold = 25
	var panel := _panel(profile)
	await wait_process_frames(1)
	_type_and_ok(panel, "  Test-Gold ")
	assert_eq(panel.message.text, "Code accepted! +1,000 gold")
	assert_eq(profile.survivor_gold, 1025)
	assert_eq(_saves, 1, "the profile is saved right away")
	assert_eq(panel.field.text, "", "the field is cleared")
	var showers := panel.find_children("*", "", true, false).filter(func(n: Node) -> bool: return n is CoinShower)
	assert_eq(showers.size(), 1, "a coin shower")


func test_unknown_and_repeat_messages() -> void:
	var profile := ProfileData.new()
	var panel := _panel(profile)
	await wait_process_frames(1)
	_type_and_ok(panel, "banana")
	assert_eq(panel.message.text, "That code doesn't work.")
	_type_and_ok(panel, TEST_CODE)
	_type_and_ok(panel, TEST_CODE)
	assert_eq(panel.message.text, "You already used that code.")
	assert_eq(_saves, 1, "only the payout saves")


func test_five_wrong_codes_make_ok_wait() -> void:
	var panel := _panel(ProfileData.new())
	await wait_process_frames(1)
	for i in CodeTries.MAX_WRONG:
		_type_and_ok(panel, "guess%d" % i)
	assert_true(panel.ok.disabled, "OK waits")
	assert_true(panel.ok.text.begins_with("WAIT"), "and shows the countdown: %s" % panel.ok.text)
	panel.field.text_submitted.emit("guess")
	assert_eq(panel.message.text, "Too many tries! Wait 30 seconds.", "Enter can't get round it")


func test_ok_comes_back_when_the_wait_is_over() -> void:
	var panel := _panel(ProfileData.new())
	await wait_process_frames(1)
	for i in CodeTries.MAX_WRONG:
		_type_and_ok(panel, "guess%d" % i)
	assert_true(panel.is_processing(), "counting down")
	panel.tries = CodeTries.new()   # as if the 30 s were over
	await wait_process_frames(2)
	assert_eq(panel.ok.text, "OK")
	assert_false(panel.ok.disabled, "the last guess is still typed")
	assert_eq(panel.message.text, "", "the wait message is gone")
	assert_false(panel.is_processing(), "no per-frame work while unlocked")


# --- The coin shower --------------------------------------------------------------------------

func test_the_coin_shower_ignores_taps_and_frees_itself() -> void:
	var shower := CoinShower.new(12, 1.0)
	add_child(shower)
	assert_eq(shower.coin_count(), 12)
	assert_gt(shower.layer, 1, "over the menu")
	for c in shower.find_children("*", "Control", true, false):
		assert_eq((c as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE)
	await wait_process_frames(2)
	shower._process(2.0)
	await wait_process_frames(2)
	assert_false(is_instance_valid(shower), "gone after its time")
