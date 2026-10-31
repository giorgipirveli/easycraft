extends GutTest
## M3 Task 15 (spec §14.9): SETTINGS → HELP → PIP'S LESSONS plays the tutorial again: the next solo
## Survivor game starts it (from the pause menu: as soon as the game goes on). No second reward (TutorialRules).
## The page still fits 1280 × 720 (test_settings_words_page.gd measures it with the button).

var _tutorial: Dictionary
var saved := []


func before_each() -> void:
	_tutorial = Profile.data.tutorial.to_dict()
	saved.clear()


func after_each() -> void:
	Profile.data.tutorial = TutorialData.from_dict(_tutorial)


func _panel() -> SettingsPanel:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: saved.append(true)
	box.add_child(s)
	add_child_autofree(box)
	s.show_page(SettingsPanel.WORDS)
	return s


func test_pips_lessons_asks_for_the_tutorial_again() -> void:
	Profile.data.tutorial.replay = false
	var s := _panel()
	var b := s.find_child("PipLessonsButton", true, false) as Button
	assert_not_null(b, "on the HELP page")
	assert_true(b.is_visible_in_tree())
	assert_gte(minf(b.size.x, b.size.y), 60.0, "a big button")
	b.pressed.emit()
	assert_true(Profile.data.tutorial.replay, "the next solo Survivor game starts it")
	assert_eq(saved.size(), 1, "saved")
	assert_true(b.disabled, "once is enough")
	assert_eq(b.text, SettingsPanel.PIP_COMING)


func test_it_shows_only_on_the_help_page() -> void:
	var s := _panel()
	var b := s.find_child("PipLessonsButton", true, false) as Button
	s.show_page(SettingsPanel.GAME)
	assert_false(b.is_visible_in_tree())
