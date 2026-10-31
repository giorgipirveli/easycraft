extends GutTest
## Owner #132 (W1), stage 1: the pause menu's DISCOVER, a picture beside RESUME in every world but Monster Wave's
## arena (the sandbox turns it on). It resumes the game and asks for the School over the world; its word is spoken when
## a pointer (a mouse, the headset's laser) or a game controller's focus comes to it (owner #133: no child has to read).
## The menu still fits a 720 px screen with every row.

class RecordingVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


var menu: PauseMenu
var voice: RecordingVoice
var _old_voice: ReadAloud.Voice


func before_each() -> void:
	_old_voice = ReadAloud.voice
	voice = RecordingVoice.new()
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	menu = PauseMenu.new()
	add_child_autofree(menu)


func after_each() -> void:
	get_tree().paused = false
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()


func _discover() -> DiscoverButton:
	var found := menu.find_children("Discover", "DiscoverButton", true, false)
	return null if found.is_empty() else found[0] as DiscoverButton


func test_no_discover_unless_the_world_has_it() -> void:
	menu.open()
	assert_null(_discover())


func test_discover_sits_beside_resume() -> void:
	menu.discover_on = true
	menu.open()
	var b := _discover()
	assert_not_null(b)
	var row := b.get_parent()
	var resume: Button = null
	for c in row.get_children():
		if c is Button and (c as Button).text == "RESUME":
			resume = c
	assert_not_null(resume, "on RESUME's row")


func test_discover_resumes_and_asks_for_the_school() -> void:
	menu.discover_on = true
	menu.open()
	watch_signals(menu)
	_discover().pressed.emit()
	assert_signal_emitted(menu, "discover_requested")
	assert_false(menu.visible)
	assert_false(get_tree().paused)


func test_its_word_is_spoken_when_pointed_at() -> void:
	menu.discover_on = true
	menu.open()
	_discover().mouse_entered.emit()
	assert_eq(voice.said.back(), DiscoveryRules.DISCOVER_WORD)
	voice.said.clear()
	_discover().focus_entered.emit()
	assert_eq(voice.said.back(), DiscoveryRules.DISCOVER_WORD, "a game controller's focus too")


func test_it_is_a_picture_with_one_word() -> void:
	menu.discover_on = true
	menu.open()
	assert_lte(DiscoveryRules.word_count(ReadAloud.words_of(_discover())), 1)
	assert_true(_discover().picture != null and _discover().picture.symbol == &"discover", "the magnifying glass")


func test_the_menu_still_fits_a_720_px_screen() -> void:
	menu.discover_on = true
	menu.show_monsters_setting(true)
	menu.open()
	await wait_process_frames(3)
	var panel := menu.find_children("*", "PanelContainer", true, false)[0] as PanelContainer
	assert_lte(panel.get_combined_minimum_size().y, 720.0)
