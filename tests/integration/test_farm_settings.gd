extends GutTest
## M3 Task 10: the "Your farm is full!" note is opt-in (spec §5.6): a switch in SETTINGS, off by default,
## and for an under-13 child only a grown-up turns it on (the parent gate first). The test only reads the
## panel: turning a setting on saves the shared profile file (test_settings_panel.gd's rule).

var _saved := {}
var _band: StringName


func before_each() -> void:
	ParentGate.reset_tries()   # M4 Task 10 review E: the gates share one lock for the app run
	_saved = Profile.data.settings.duplicate()
	_band = Profile.data.age_band


func after_each() -> void:
	Profile.data.settings = _saved
	Profile.data.age_band = _band


func _panel() -> SettingsPanel:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var s := SettingsPanel.new()
	box.add_child(s)
	add_child_autofree(box)
	return s


func test_the_note_is_off_by_default() -> void:
	assert_eq(ProfileData.DEFAULT_SETTINGS.farm_note, false)
	assert_false(ProfileData.from_json("{}").settings.farm_note)
	Profile.data.settings.farm_note = false
	var toggle := _panel().find_child("FarmNoteToggle", true, false) as CheckButton
	assert_not_null(toggle)
	if toggle:
		assert_false(toggle.button_pressed)
		assert_eq(toggle.text, "Farm note")


func test_the_switch_shows_the_setting() -> void:
	Profile.data.settings.farm_note = true
	var toggle := _panel().find_child("FarmNoteToggle", true, false) as CheckButton
	assert_true(toggle.button_pressed)


func test_an_under_13_child_needs_a_grown_up_to_turn_it_on() -> void:
	Profile.data.settings.farm_note = false
	Profile.data.age_band = AgeBand.UNDER_13
	var s := _panel()
	var toggle := s.find_child("FarmNoteToggle", true, false) as CheckButton
	toggle.button_pressed = true   # the child taps it
	assert_false(toggle.button_pressed, "it stays off")
	assert_false(Profile.data.settings.farm_note, "nothing saved")
	assert_eq(s.find_children("*", "GrownUpGate", true, false).size(), 1, "the parent gate asks first")
	assert_false(toggle.is_visible_in_tree(), "the settings step aside for the gate")


func test_the_panel_still_fits_the_screen() -> void:
	var s := _panel()
	var size := (s.get_parent() as Control).get_combined_minimum_size()
	assert_lte(size.x, 1280.0, "width %d" % size.x)
	assert_lte(size.y, 720.0, "height %d" % size.y)


func test_a_saved_profile_keeps_the_switch_and_the_last_note() -> void:
	var p := ProfileData.new()
	p.settings.farm_note = true
	p.farm_note_at = 1_800_000_000
	var back := ProfileData.from_json(p.to_json())
	assert_true(back.settings.farm_note)
	assert_eq(back.farm_note_at, 1_800_000_000)
	assert_eq(ProfileData.from_json('{"farm_note_at": "soon"}').farm_note_at, 0)
	assert_eq(ProfileData.from_json('{"settings": {"farm_note": "yes"}}').settings.farm_note, false)
