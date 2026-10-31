extends GutTest
## M3 Task 21a: a card at first launch, once: after the look, "Simple controls?" with two equal picture cards
## (research O8: no nudge). A child who played before sees it once at the next start. Choosing in SETTINGS counts
## too. (Its LANGUAGE card was removed by owner #52: English only.) The saver is a no-op here (the profile file is
## shared by every worktree).

const SCREEN := Vector2(1280, 720)
const KEYS := ["simple_controls", "simple_asked"]

var _saved := {}
var _locale := ""


func before_each() -> void:
	PlatformRules.simulated = {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}   # a phone's first launch
	for key: String in KEYS:
		_saved[key] = Profile.data.settings[key]
	_locale = TranslationServer.get_locale()


func after_each() -> void:
	PlatformRules.simulated = {}
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]
	TranslationServer.set_locale(_locale)


func _card(kind: StringName) -> Control:
	var box := PanelContainer.new()   # as the menu shows it
	box.theme = UiKit.theme()
	var c: Control = WelcomeCards.card(kind, func() -> void: pass)
	box.add_child(c)
	add_child_autofree(box)
	return c


func test_the_card_comes_once() -> void:
	assert_eq(WelcomeCards.due({"simple_asked": false}), [WelcomeCards.CONTROLS] as Array[StringName])
	assert_eq(WelcomeCards.due({"simple_asked": true}), [] as Array[StringName])
	assert_eq(WelcomeCards.due({"language": "", "simple_asked": true}), [] as Array[StringName],
		"owner #52: no language card, even for a profile saved with M3 Task 21a's LANGUAGE")


func test_simple_and_classic_are_equal_picture_cards() -> void:
	var c := _card(WelcomeCards.CONTROLS)
	var simple := c.find_child("SimpleCard", true, false) as Button
	var classic := c.find_child("ClassicCard", true, false) as Button
	assert_not_null(simple)
	assert_not_null(classic)
	if simple == null or classic == null:
		return
	assert_eq(simple.custom_minimum_size, classic.custom_minimum_size, "no nudge: the same size")
	assert_not_null(simple.find_child("Picture", true, false))
	assert_not_null(classic.find_child("Picture", true, false))


func test_choosing_simple_or_classic_saves_it_once() -> void:
	for pick_simple: bool in [true, false]:
		Profile.data.settings.simple_asked = false
		var c := _card(WelcomeCards.CONTROLS)
		var got: Array = []
		c.chosen.connect(func() -> void: got.append(true))
		(c.find_child("SimpleCard" if pick_simple else "ClassicCard", true, false) as Button).pressed.emit()
		assert_eq(Profile.data.settings.simple_controls, pick_simple)
		assert_true(Profile.data.settings.simple_asked)
		assert_eq(got.size(), 1)


func test_the_card_fits_the_screen() -> void:
	var c := _card(WelcomeCards.CONTROLS)
	var size := (c.get_parent() as Control).get_combined_minimum_size()
	assert_lte(size.x, SCREEN.x, "width")
	assert_lte(size.y, SCREEN.y - 130.0, "height (under the menu's logo)")


## The menu after the look: "How do you like to play?" when it was not asked yet (nothing is pressed here: a
## choice would write the shared profile file).
func test_the_menu_asks_after_the_look_step() -> void:
	get_window().size = SCREEN
	Profile.data.settings.simple_asked = false
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_look_step")
	await wait_process_frames(2)
	var step: LookChoice = null
	for n in menu.find_children("*", "", true, false):
		if n is LookChoice:
			step = n
	assert_not_null(step)
	if step == null:
		return
	step.profile = ProfileData.new()
	step.save_profile = func() -> void: pass
	step.choices()[0].pressed.emit()
	await wait_process_frames(2)
	var card: Node = null
	for n in menu.find_children("*", "", true, false):
		if n.name == "SimpleCard" and (n as Control).is_visible_in_tree():
			card = n
	assert_not_null(card, "the Simple controls card comes next")


## Owner #84: "Simple controls?" is a phone's question (the camera follows, fewer buttons); a PC plays with the keyboard
## and the mouse (SETTINGS still has it).
func test_a_pc_is_not_asked_about_simple_controls() -> void:
	PlatformRules.simulated = {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true}
	assert_eq(WelcomeCards.due({"simple_asked": false}), [] as Array[StringName])
	PlatformRules.simulated = {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}
	assert_eq(WelcomeCards.due({"simple_asked": false}), [WelcomeCards.CONTROLS] as Array[StringName])
	PlatformRules.simulated = {}
