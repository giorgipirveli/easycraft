extends GutTest
## M7 (owner 2026-09-28: "remember when user start playing, they should get shortcut on the app so next time they just
## click and open it", "it must be very user friendly"): many players tap PLAY on the page before they see its "Add
## EasyCraft to this device", so the game offers it too. The main menu shows a picture card (the buddy, the title, one
## line, ADD and NOT NOW) in a browser that can add the game, after some play, once a run (InstallOffer); SETTINGS has
## ADD TO THIS DEVICE. Nothing here writes the shared profile file (the savers are stand-ins) or reaches a page.

const PHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}
const IPHONE_SAFARI := {PlatformRules.WEB: true, PlatformRules.WEB_IOS: true, PlatformRules.TOUCH_SCREEN: true}
const ANDROID := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}
const CAN := {"can_install": true, "needs_guide": false, "installed": false}
const GUIDE := {"can_install": true, "needs_guide": true, "installed": false}
const CANNOT := {"can_install": false, "needs_guide": false, "installed": false}
const INSTALLED := {"can_install": false, "needs_guide": false, "installed": true}
const SCREEN := Vector2(1280, 720)
const LOGO_ROOM := 130.0   # the menu's panels sit under the wordmark

var _profile: ProfileData
var _worlds_left := 0
var _change_scene: Callable
var _window: Vector2i
var _requests: Array[int] = [0]
var _saves: Array[int] = [0]


func before_all() -> void:
	_window = get_window().size


func after_all() -> void:
	get_window().size = _window


func before_each() -> void:
	PlatformRules.shader_warmup = false   # its menus pretend to be a browser: no shader warm-up under the root here
	_profile = Profile.data
	Profile.data = _player()
	_worlds_left = Game.worlds_left
	_change_scene = Game.change_scene
	InstallOffer.shown_this_run = false
	_requests = [0]
	_saves = [0]


func after_each() -> void:
	Profile.data = _profile
	Game.worlds_left = _worlds_left
	Game.change_scene = _change_scene
	InstallOffer.shown_this_run = false
	PlatformRules.simulated = {}
	PlatformRules.shader_warmup = true


## A child who has been through the first-launch questions.
func _player() -> ProfileData:
	var p := ProfileData.new()
	p.username = "Mia"
	p.age_band = AgeBand.UNDER_13
	p.settings.simple_asked = true
	return p


func _menu(state: Dictionary) -> Node:
	get_window().size = Vector2i(SCREEN)
	var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
	menu.set("install_state", func() -> Dictionary: return state)
	menu.set("request_install", func() -> void: _requests[0] += 1)
	menu.set("save_profile", func() -> void: _saves[0] += 1)
	add_child_autofree(menu)
	await wait_process_frames(3)
	return menu


func _card(root: Node) -> InstallCard:
	for n in root.find_children("*", "", true, false):
		if n is InstallCard and not n.is_queued_for_deletion():
			return n
	return null


func _visible_texts(root: Node, type: String) -> PackedStringArray:
	var out := PackedStringArray()
	for c in root.find_children("*", type, true, false):
		if (c as Control).is_visible_in_tree() and not c.is_queued_for_deletion():
			out.append(str(c.get("text")))
	return out


func _on_the_games(menu: Node) -> bool:
	return _visible_texts(menu, "Label").has("Choose your game")


func _press(card: InstallCard, button_name: String) -> void:
	var b := card.find_child(button_name, true, false) as Button
	assert_not_null(b, button_name)
	if b:
		b.pressed.emit()


# --- The main menu's card ---

func test_after_playing_a_browser_menu_offers_to_add_the_game() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 1
	var menu: Node = await _menu(CAN)
	var card := _card(menu)
	assert_not_null(card, "the card, not the games")
	if card == null:
		return
	assert_true(card.is_visible_in_tree())
	assert_false(_on_the_games(menu))
	var labels := _visible_texts(card, "Label")
	assert_true(labels.has("Add EasyCraft to this device"), "%s" % [labels])
	assert_true(labels.has("Next time, one tap opens it, full screen, like an app."))
	var buttons := _visible_texts(card, "Button")
	assert_true(buttons.has("ADD"), "%s" % [buttons])
	assert_true(buttons.has("NOT NOW"))
	var picture := card.find_child("Picture", true, false) as TextureRect
	assert_not_null(picture, "the buddy first")
	if picture:
		assert_eq(picture.texture.resource_path, "res://icon.png")
		assert_true(card.get_child(0).is_ancestor_of(picture), "the picture comes first, above every word")
	assert_true(InstallOffer.shown_this_run)


func test_on_safari_the_line_says_it_shows_how() -> void:
	PlatformRules.simulated = IPHONE_SAFARI
	Game.worlds_left = 1
	var card := _card(await _menu(GUIDE))
	assert_not_null(card)
	if card:
		var labels := _visible_texts(card, "Label")
		assert_true(labels.has("We'll show you how: it takes 3 taps."), "%s" % [labels])
		assert_false(labels.has("Next time, one tap opens it, full screen, like an app."))


func test_a_first_visit_goes_straight_to_the_games() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 0
	var menu: Node = await _menu(CAN)
	assert_null(_card(menu), "play first")
	assert_true(_on_the_games(menu))
	assert_false(InstallOffer.shown_this_run)


func test_a_child_who_played_before_gets_it_at_the_start() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 0
	Profile.data.progress.xp = 40
	assert_not_null(_card(await _menu(CAN)))


func test_add_asks_the_page_and_closes_the_card() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 1
	var menu: Node = await _menu(CAN)
	var card := _card(menu)
	assert_not_null(card)
	if card == null:
		return
	var before := int(Time.get_unix_time_from_system())
	_press(card, "AddButton")
	await wait_process_frames(2)
	assert_eq(_requests[0], 1, "the browser's prompt (or Safari's guide) was asked for")
	assert_eq(int(Profile.data.settings.install_not_now), 0, "ADD is no NOT NOW")
	assert_gte(int(Profile.data.settings.install_asked_at), before, "the card waits 3 days")
	assert_eq(_saves[0], 1, "the profile was saved")
	assert_null(_card(menu), "the card closed")
	assert_true(_on_the_games(menu))


func test_not_now_counts_and_goes_to_the_games() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 1
	var menu: Node = await _menu(CAN)
	var card := _card(menu)
	assert_not_null(card)
	if card == null:
		return
	_press(card, "NotNowButton")
	await wait_process_frames(2)
	assert_eq(_requests[0], 0, "nothing asked of the page")
	assert_eq(int(Profile.data.settings.install_not_now), 1)
	assert_gt(int(Profile.data.settings.install_asked_at), 0)
	assert_eq(_saves[0], 1)
	assert_null(_card(menu))
	assert_true(_on_the_games(menu))


func test_once_a_run() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 1
	var menu: Node = await _menu(CAN)
	assert_not_null(_card(menu))
	menu.call("_route")   # Back to the start
	await wait_process_frames(2)
	assert_null(_card(menu), "not twice")
	Game.worlds_left = 2
	var next: Node = await _menu(CAN)   # back from another world
	assert_null(_card(next), "not twice in a run")
	assert_true(_on_the_games(next))


func test_never_outside_a_browser() -> void:
	Game.worlds_left = 1
	for f: Dictionary in [{}, ANDROID]:
		PlatformRules.simulated = f
		var menu: Node = await _menu(CAN)
		assert_null(_card(menu), "%s" % [f])
		assert_true(_on_the_games(menu))


func test_not_when_the_page_cannot_add_it() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 1
	for state: Dictionary in [CANNOT, INSTALLED]:
		var menu: Node = await _menu(state)
		assert_null(_card(menu), "%s" % [state])


func test_never_during_the_first_launch_questions() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 1
	Profile.data.progress.xp = 40
	Profile.data.username = ""
	var menu: Node = await _menu(CAN)
	assert_null(_card(menu), "the name first")
	assert_true(_visible_texts(menu, "Label").has("Pick your name"))
	Profile.data.username = "Mia"
	Profile.data.settings.simple_asked = false
	menu.call("_route")
	await wait_process_frames(2)
	assert_null(_card(menu), "the Simple controls card first")
	assert_true(_visible_texts(menu, "Label").has("How do you like to play?"))


func test_the_card_fits_under_the_logo_with_a_speaker() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Game.worlds_left = 1
	var card := _card(await _menu(CAN))
	assert_not_null(card)
	if card == null:
		return
	var size := (card.get_parent() as Control).get_combined_minimum_size()
	gut.p("install card %s" % size)
	assert_lte(size.x, SCREEN.x, "width")
	assert_lte(size.y, SCREEN.y - LOGO_ROOM, "height")
	assert_not_null(card.find_child("ReadAloud", true, false), "the speaker beside the title, like every screen")


# --- Coming back from a world counts as having played ---

func test_leaving_a_world_is_counted() -> void:
	var scenes: Array[String] = []
	Game.change_scene = func(path: String) -> void: scenes.append(path)
	var before := Game.worlds_left
	Game.quit_to_menu()
	assert_eq(Game.worlds_left, before + 1)
	assert_eq(scenes, [Game.MENU_SCENE] as Array[String])


# --- SETTINGS: ADD TO THIS DEVICE (whenever the page can add the game, also after 3 NOT NOWs) ---

func _settings(state: Array) -> SettingsPanel:
	var box := PanelContainer.new()   # as the menus show it
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass
	s.install_state = func() -> Dictionary: return state[0]
	s.request_install = func() -> void: _requests[0] += 1
	box.add_child(s)
	add_child_autofree(box)
	return s


func _install_button(s: SettingsPanel) -> Button:
	return s.find_child("InstallButton", true, false) as Button


func test_settings_offers_it_in_a_browser_that_can_add_the_game() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	Profile.data.settings.install_not_now = InstallOffer.MAX_NOT_NOW   # the menu stopped asking
	var state := [CAN]
	var s := _settings(state)
	var b := _install_button(s)
	assert_not_null(b)
	if b == null:
		return
	assert_true(b.is_visible_in_tree(), "on the first page")
	assert_eq(b.text, "ADD TO THIS DEVICE")
	state[0] = CANNOT   # Chrome: the prompt is used up once shown
	b.pressed.emit()
	assert_eq(_requests[0], 1, "the page was asked")
	assert_false(b.visible, "never a dead button")


func test_on_safari_the_button_stays_for_the_guide() -> void:
	PlatformRules.simulated = IPHONE_SAFARI
	var s := _settings([GUIDE])
	var b := _install_button(s)
	assert_not_null(b)
	if b:
		b.pressed.emit()
		assert_eq(_requests[0], 1)
		assert_true(b.visible, "the steps can be shown again")


func test_settings_has_no_button_where_nothing_can_be_added() -> void:
	for c: Array in [[{}, CAN], [ANDROID, CAN], [PHONE_BROWSER, CANNOT], [PHONE_BROWSER, INSTALLED]]:
		PlatformRules.simulated = c[0]
		var b := _install_button(_settings([c[1]]))
		assert_true(b == null or not b.is_visible_in_tree(), "%s" % [c])


func test_settings_with_the_button_fits_the_screen() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var s := _settings([CAN])
	for page: StringName in [SettingsPanel.GAME, SettingsPanel.WORDS, SettingsPanel.ACCESS]:
		s.show_page(page)
		var size := (s.get_parent() as Control).get_combined_minimum_size()
		gut.p("settings %s with ADD TO THIS DEVICE: %s" % [page, size])
		assert_lte(size.x, SCREEN.x, "%s width" % page)
		assert_lte(size.y, SCREEN.y, "%s height" % page)
