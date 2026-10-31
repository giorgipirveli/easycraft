extends GutTest
## M5 Task 1 (spec §15.1a): SETTINGS' third page, BUTTONS & TEXT: BUTTON SIZE (NORMAL / BIG / BIGGER), HANDS (RIGHT /
## LEFT), MOVE BUTTONS (the editor), TEXT SIZE (NORMAL / BIG) and Sound captions. Every page still fits 1280 × 720.
## The panel's saver is a no-op here (the profile file is shared by every worktree).

const SCREEN := Vector2(1280, 720)
const KEYS := ["button_size", "left_handed", "text_size", "captions"]

var _saved := {}
var _moves := {}


func before_each() -> void:
	for key: String in KEYS:
		_saved[key] = Profile.data.settings[key]
	_moves = Profile.data.hud_moves.duplicate(true)


func after_each() -> void:
	for key: String in _saved:
		Profile.data.settings[key] = _saved[key]
	Profile.data.hud_moves = _moves
	HudLayout.reset()
	for n in get_tree().root.find_children("HudEditor", "", true, false):
		n.queue_free()


func _panel() -> SettingsPanel:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: pass
	box.add_child(s)
	add_child_autofree(box)
	return s


func _fits(s: SettingsPanel, what: String) -> void:
	var size := (s.get_parent() as Control).get_combined_minimum_size()
	gut.p("%s: %s" % [what, size])
	assert_lte(size.y, SCREEN.y, "%s height %d" % [what, size.y])
	assert_lte(size.x, SCREEN.x, "%s width %d" % [what, size.x])


func _button(s: SettingsPanel, button_name: String) -> Button:
	return s.find_child(button_name, true, false) as Button


func test_every_page_fits_the_screen() -> void:
	var s := _panel()
	for page: StringName in [SettingsPanel.GAME, SettingsPanel.WORDS, SettingsPanel.ACCESS]:
		s.show_page(page)
		_fits(s, "page %s" % page)


func test_the_third_page_shows_only_its_own_settings() -> void:
	var s := _panel()
	var page := _button(s, "Page_access")
	assert_not_null(page, "a third page button beside GAME and HELP")
	if page == null:
		return
	assert_eq(page.text, "BUTTONS & TEXT")
	var big := _button(s, "ButtonSize_big")
	assert_false(big.is_visible_in_tree(), "the game page first")
	page.pressed.emit()
	assert_true(big.is_visible_in_tree())
	assert_true(page.button_pressed, "its page button is lit")
	assert_false(_button(s, "Page_game").button_pressed)
	assert_false((s.find_child("MusicSlider", true, false) as Control).is_visible_in_tree())
	assert_false((s.find_child("ReadToMeToggle", true, false) as Control).is_visible_in_tree())
	s.show_page(SettingsPanel.WORDS)
	assert_false(big.is_visible_in_tree())


func test_the_choices_show_and_change_the_settings() -> void:
	Profile.data.settings.button_size = "normal"
	Profile.data.settings.left_handed = false
	Profile.data.settings.text_size = "normal"
	Profile.data.settings.captions = true
	var s := _panel()
	s.show_page(SettingsPanel.ACCESS)
	assert_true(_button(s, "ButtonSize_normal").button_pressed)
	_button(s, "ButtonSize_bigger").pressed.emit()
	assert_eq(Profile.data.settings.button_size, "bigger")
	assert_true(_button(s, "ButtonSize_bigger").button_pressed)
	assert_false(_button(s, "ButtonSize_normal").button_pressed)
	_button(s, "Hand_left").pressed.emit()
	assert_true(Profile.data.settings.left_handed)
	assert_false(_button(s, "Hand_right").button_pressed)
	_button(s, "TextSize_big").pressed.emit()
	assert_eq(Profile.data.settings.text_size, "big")
	var captions := s.find_child("CaptionsToggle", true, false) as CheckButton
	assert_true(captions.button_pressed)
	captions.button_pressed = false
	assert_false(Profile.data.settings.captions)


func test_move_buttons_opens_the_editor_over_everything() -> void:
	var s := _panel()
	s.show_page(SettingsPanel.ACCESS)
	var move := _button(s, "MoveButtons")
	assert_not_null(move)
	move.pressed.emit()
	await wait_process_frames(2)
	var editors := get_tree().root.find_children("HudEditor", "", true, false)
	assert_eq(editors.size(), 1, "MOVE BUTTONS shows the editor")
	if editors.is_empty():
		return
	var layer := editors[0].get_parent() as CanvasLayer
	assert_not_null(layer, "on a layer of its own")
	assert_gt(layer.layer, 90, "over the menus and the pause menu")
	assert_eq(layer.process_mode, Node.PROCESS_MODE_ALWAYS, "it works while the game is paused")
	(editors[0] as HudEditor).reset_button.pressed.emit()
	(editors[0] as HudEditor).done_button.pressed.emit()
	await wait_process_frames(2)
	assert_eq(get_tree().root.find_children("HudEditor", "", true, false).size(), 0, "DONE closes it")
	assert_false(is_instance_valid(layer), "and its layer")
