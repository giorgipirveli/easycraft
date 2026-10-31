extends GutTest
## Owner #132 (W1), stage 2: discovery crystals are a grown-up's choice. The grown-up area's PLAY & PHOTOS page (behind
## the parent gate, no online account needed) has "Discovery crystals" ON / OFF, on unless a grown-up turns it off,
## saved at once in the profile's settings (DiscoveryCrystalRules.SETTING); the page still fits the menu's panel.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)

var DIR := "user://test_discovery_grown_ups_%d/" % OS.get_process_id()
var saves := 0


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	saves = 0


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _offline() -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(FakeServer.new())
	s.profile = ProfileData.new()
	s.profile.username = "Kit"
	s.profile.age_band = AgeBand.UNDER_13
	s.save_profile = func() -> void: saves += 1
	s.prefs_path = DIR + "offline.json"
	s.device_id_path = DIR + "no_device.json"
	add_child_autofree(s)
	return s


func _area(s: OnlineService) -> GrownUpsPanel:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var area := GrownUpsPanel.new()
	area.service = s
	area.play_minutes = func() -> int: return 42
	panel.add_child(area)
	await wait_process_frames(3)
	area.show_page(GrownUpsPanel.PAGE_TIME)
	await wait_process_frames(3)
	return area


func test_the_switch_is_on_by_default() -> void:
	var area := await _area(_offline())
	assert_eq(area.crystal_buttons.size(), 2, "ON and OFF")
	assert_true((area.crystal_buttons[true] as Button).button_pressed)
	assert_false((area.crystal_buttons[false] as Button).button_pressed)


func test_a_grown_up_turns_them_off_and_it_is_saved_at_once() -> void:
	var s := _offline()
	var area := await _area(s)
	(area.crystal_buttons[false] as Button).pressed.emit()
	assert_false(DiscoveryCrystalRules.switched_on(s.profile.settings))
	assert_eq(saves, 1)
	assert_true((area.crystal_buttons[false] as Button).button_pressed)
	(area.crystal_buttons[true] as Button).pressed.emit()
	assert_true(DiscoveryCrystalRules.switched_on(s.profile.settings))


func test_the_setting_survives_a_save() -> void:
	var p := ProfileData.new()
	p.settings[DiscoveryCrystalRules.SETTING] = false
	var back := ProfileData.from_json(p.to_json())
	assert_false(DiscoveryCrystalRules.switched_on(back.settings))
	assert_true(DiscoveryCrystalRules.switched_on(ProfileData.from_json(ProfileData.new().to_json()).settings))


func test_the_page_still_fits() -> void:
	var area := await _area(_offline())
	await wait_process_frames(2)
	var size := area.get_combined_minimum_size()
	assert_lte(size.y, PANEL_CONTENT.y, "fits the height (%d)" % size.y)
	assert_lte(size.x, PANEL_CONTENT.x)
