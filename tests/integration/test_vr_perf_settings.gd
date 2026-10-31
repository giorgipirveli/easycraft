extends GutTest
## P5 (owner #108): the settings page's Graphics row offers VR and VR PLUS in a headset (beside each other; a phone's
## LOW, MEDIUM and HIGH mean nothing there), the one in use pressed; off VR it is LOW, MEDIUM and HIGH as before.
## Never the shared profile file: the panel's saver is a stand-in.

var _graphics := ""
var _saves := 0


func before_each() -> void:
	_graphics = str(Profile.data.settings.graphics)
	_saves = 0


func after_each() -> void:
	Vr.simulate(false)
	GraphicsPreset.headset = ""
	Profile.data.settings.graphics = _graphics
	Game.apply_settings()


func _panel() -> SettingsPanel:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	s.saver = func() -> void: _saves += 1
	box.add_child(s)
	add_child_autofree(box)
	return s


func _button(s: SettingsPanel, text: String) -> Button:
	for b: Node in s.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			return b as Button
	return null


func test_off_vr_the_row_is_low_medium_high() -> void:
	var s := _panel()
	for t: String in ["LOW", "MEDIUM", "HIGH"]:
		assert_not_null(_button(s, t), t)
	assert_null(_button(s, "VR PLUS"))


func test_a_headset_offers_vr_and_vr_plus_and_stores_the_pick() -> void:
	Vr.simulate(true)
	Profile.data.settings.graphics = "vr"
	var s := _panel()
	var vr := _button(s, "VR")
	var plus := _button(s, "VR PLUS")
	assert_not_null(vr)
	assert_not_null(plus)
	assert_null(_button(s, "MEDIUM"), "a phone's presets mean nothing in a headset")
	if vr == null or plus == null:
		return
	assert_true(vr.button_pressed)
	assert_false(plus.button_pressed)
	plus.pressed.emit()
	assert_eq(Profile.data.settings.graphics, "vr_plus")
	assert_true(plus.button_pressed)
	assert_false(vr.button_pressed)
	assert_eq(_saves, 1)


func test_a_phone_choice_in_a_headset_shows_the_headsets_own_pick() -> void:
	Vr.simulate(true)
	Profile.data.settings.graphics = "medium"
	GraphicsPreset.headset = "Quest 3"
	var s := _panel()
	assert_true(_button(s, "VR PLUS").button_pressed, "a Quest 3 reads its never-picked preset as vr_plus")
	assert_false(_button(s, "VR").button_pressed)
