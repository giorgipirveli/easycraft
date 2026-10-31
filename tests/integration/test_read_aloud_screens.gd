extends GutTest
## M5 Task 1 (spec §5.15, §15.1a): read aloud on every screen. Each menu screen, the pause menu, SETTINGS' pages, MOVE
## BUTTONS and the HUD's panels a child reads have a speaker that reads them (M3 Task 21a's ReadAloud; the speakers
## show where the device has a voice: a fake voice here), and what it reads has words. The menu's screens are also read
## by "Read to me" (their titles).

class FakeVoice:
	extends ReadAloud.Voice

	func has_voice(_language: String) -> bool:
		return true


var menu: Node
var _old_voice: ReadAloud.Voice
var _unlocked := 1


func before_each() -> void:
	_old_voice = ReadAloud.voice
	ReadAloud.voice = FakeVoice.new()
	_unlocked = Profile.data.universe_unlocked


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	Profile.data.universe_unlocked = _unlocked
	UniverseRegistry.reset()


## The speaker buttons in `root` (ReadAloud names them "ReadAloud").
func _speakers(root: Node) -> Array:
	return root.find_children("ReadAloud", "", true, false).filter(
		func(b: Node) -> bool: return (b as Control).visible and not b.is_queued_for_deletion())


func _check(root: Node, what: String) -> void:
	assert_gt(_speakers(root).size(), 0, "%s: a speaker reads it" % what)
	assert_ne(ReadAloud.words_of(root).strip_edges(), "", "%s: it has words to read" % what)


## The screen the menu shows now (its middle panel's content).
func _screen() -> Node:
	var center: Node = menu.get("_center")
	for c in center.get_children():
		if not c.is_queued_for_deletion() and c.get_child_count() > 0:
			return c.get_child(0)
	return null


func test_every_menu_screen_has_a_speaker() -> void:
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	var screens := {"how old are you": ["_show_age"],
		"your name": ["_show_name"], "boy or girl": ["_show_look_step"], "choose your game": ["_show_main"],
		"sandbox worlds": ["_show_mode", ModeRules.SANDBOX], "survivor worlds": ["_show_mode", ModeRules.SURVIVOR],
		"monster wave": ["_show_wave"], "settings": ["_show_settings"], "secret codes": ["_show_codes"],
		"the avatar editor": ["_show_avatar"]}
	for what: String in screens:
		var call: Array = screens[what]
		menu.callv(call[0], call.slice(1))
		await wait_process_frames(2)
		var screen := _screen()
		assert_not_null(screen, what)
		if screen:
			_check(screen, what)


func test_the_universe_hubs_have_a_speaker() -> void:
	Profile.data.universe_unlocked = 2
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_hub")
	await wait_process_frames(2)
	_check(_screen(), "the portal hub")


func test_the_pause_menu_and_every_settings_page_have_a_speaker() -> void:
	var pause := PauseMenu.new()
	add_child_autofree(pause)
	await wait_process_frames(2)
	pause.visible = true
	pause.call("_show_buttons")   # what open() shows (open() would pause the tests' tree)
	await wait_process_frames(1)
	_check(pause, "the pause menu")
	var box := PanelContainer.new()
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass
	box.add_child(s)
	add_child_autofree(box)
	for page: StringName in [SettingsPanel.GAME, SettingsPanel.WORDS, SettingsPanel.ACCESS]:
		s.show_page(page)
		_check(s, "SETTINGS page %s" % page)


func test_the_huds_reading_panels_have_a_speaker() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	await wait_process_frames(2)
	hud.add_secret_controls(null)
	await wait_process_frames(1)
	hud.secret_book.open()
	await wait_process_frames(1)
	_check(hud.secret_book, "the Secret Book")
	hud.secret_book.visible = false
	hud.show_note("Follow the arrows to the treasure.", [0, 1])
	await wait_process_frames(1)
	_check(hud.riddle_panel, "a note")
	hud.riddle_panel.visible = false
	var trader := Trader.new()
	trader.setup({"pos": Vector3.ZERO, "yaw": 0.0})
	add_child_autofree(trader)
	hud.open_shop(trader)
	await wait_process_frames(1)
	_check(hud.shop, "Tilly's shop")
	hud.shop.close()
	var totem := Totem.new()
	add_child_autofree(totem)
	hud.open_totem(totem)
	await wait_process_frames(1)
	_check(hud.totem_panel, "the Monster Totem")
