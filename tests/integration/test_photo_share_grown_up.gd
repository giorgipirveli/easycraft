extends GutTest
## M5 store readiness F1 (spec §5.9, §5.14, §14.14, §17.2): a child could send a photo out of the game through the
## phone's share sheet with nobody's say. SHARE now follows a grown-up's switch: in photo mode the SHARE chip shows
## only where sharing is allowed (off by default for under-13, on for 13+), and share() never opens the sheet
## otherwise; the shutter still saves to the gallery. The switch is on the grown-up area's PLAY & PHOTOS page (the
## parent corner on this device, behind the parent gate), works without an online account and is saved at once.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
## The main menu's panel: below the logo (offset 130) with the panel's 28 px margins (as test_grown_up_area.gd).
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)
const T := {"year": 2026, "month": 9, "day": 25, "hour": 12, "minute": 0, "second": 1}

var DIR := "user://test_photo_share_grown_up_%d/" % OS.get_process_id()
var allowed := false
var shared: Array[String] = []
var saves := 0
var _band: StringName
var _switch: StringName


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	allowed = false
	shared.clear()
	saves = 0
	_band = Profile.data.age_band
	_switch = Profile.data.photo_share


func after_each() -> void:
	get_tree().paused = false
	Profile.data.age_band = _band   # nothing here saves the shared profile file
	Profile.data.photo_share = _switch
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


# --- Photo mode ---

static func _ground(cell: Vector3i) -> bool:
	return cell.y < 10


## Photo mode in its own 1280 x 720 view, on LAN (nothing pauses), sharing asked of `allowed`, the share sheet
## recorded instead of opened. `own_rule`: keep photo mode's own default (the Profile autoload).
func _photo(own_rule: bool = false) -> PhotoMode:
	var view := SubViewport.new()
	view.size = Vector2i(1280, 720)
	add_child_autofree(view)
	var target := Node3D.new()
	view.add_child(target)
	target.position = Vector3(0.5, 10.0, 0.5)
	var hud := Control.new()
	view.add_child(hud)
	var photo := PhotoMode.new()
	view.add_child(photo)
	photo.setup(target, hud, _ground)
	photo.folders = PackedStringArray([DIR])
	photo.clock = func() -> Dictionary: return T
	if not own_rule:
		photo.share_allowed = func() -> bool: return allowed
	photo.sharer = func(_png: PackedByteArray, path: String) -> StringName:
		shared.append(path)
		return &"sheet"
	return photo


## The SHARE (FOLDER on desktop) chip, when it shows.
func _share_chip(photo: PhotoMode) -> PhotoChip:
	for c in photo.find_children("*", "PhotoChip", true, false):
		var chip := c as PhotoChip
		if chip.text in ["SHARE", "FOLDER"] and chip.is_visible_in_tree():
			return chip
	return null


func _shoot(photo: PhotoMode) -> void:
	photo.take_photo()
	await wait_for_signal(photo.photo_saved, 10, "the photo is saved")


func test_where_sharing_is_off_photo_mode_only_saves() -> void:
	var photo := _photo()
	var old_game := Game.net_mode
	Game.net_mode = &"host"
	photo.open()
	assert_null(_share_chip(photo), "no SHARE for a child without a grown-up's yes")
	await _shoot(photo)
	assert_true(FileAccess.file_exists(photo.last_path), "the shutter still saves the photo")
	photo.share()   # even a call that slips through opens nothing
	assert_eq(shared.size(), 0, "the share sheet never opens")
	photo.close()
	Game.net_mode = old_game


func test_where_sharing_is_on_share_is_there() -> void:
	allowed = true
	var photo := _photo()
	var old_game := Game.net_mode
	Game.net_mode = &"host"
	photo.open()
	assert_not_null(_share_chip(photo), "SHARE shows")
	await _shoot(photo)
	photo.share()
	assert_eq(shared, [photo.last_path] as Array[String], "the share sheet opens with the photo")
	photo.close()
	Game.net_mode = old_game


func test_the_switch_is_read_each_time_photo_mode_opens() -> void:
	var photo := _photo()
	var old_game := Game.net_mode
	Game.net_mode = &"host"
	photo.open()
	assert_null(_share_chip(photo))
	photo.close()
	allowed = true   # a grown-up turned it on meanwhile (SETTINGS -> GROWN-UPS, from the pause menu)
	photo.open()
	assert_not_null(_share_chip(photo), "on at the next open")
	photo.close()
	allowed = false
	photo.open()
	assert_null(_share_chip(photo), "and off again")
	photo.close()
	Game.net_mode = old_game


func test_by_default_photo_mode_follows_the_profile() -> void:
	var photo := _photo(true)
	var old_game := Game.net_mode
	Game.net_mode = &"host"
	Profile.data.age_band = AgeBand.UNDER_13
	Profile.data.photo_share = PhotoRules.SHARE_AUTO
	photo.open()
	assert_null(_share_chip(photo), "a child: off by default")
	photo.close()
	Profile.data.photo_share = PhotoRules.SHARE_ON
	photo.open()
	assert_not_null(_share_chip(photo), "a grown-up's ON")
	photo.close()
	Profile.data.age_band = AgeBand.TEEN_PLUS
	Profile.data.photo_share = PhotoRules.SHARE_AUTO
	photo.open()
	assert_not_null(_share_chip(photo), "13+: on by default")
	photo.close()
	Profile.data.photo_share = PhotoRules.SHARE_OFF
	photo.open()
	assert_null(_share_chip(photo), "a grown-up's OFF for a 13+ player")
	photo.close()
	Game.net_mode = old_game


# --- The grown-up area's PLAY & PHOTOS page ---

## A service that never signed in (no online account on this device), with its own profile.
func _offline(band: StringName) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(FakeServer.new())
	s.profile = ProfileData.new()
	s.profile.username = "Kit"
	s.profile.age_band = band
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
	return area


func _button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and (b as Button).text == text:
			return b
	return null


func _words(root: Node) -> String:
	var out := ""
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out += (l as Label).text + "\n"
	return out


func _check_fits(area: Control, what: String) -> void:
	await wait_process_frames(2)
	var size := area.get_combined_minimum_size()
	gut.p("%s: %s" % [what, size])
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	for b in area.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			assert_gte((b as Button).size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, (b as Button).text])
			assert_gte((b as Button).size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, (b as Button).text])


func _open_photos_page(area: GrownUpsPanel) -> void:
	var tab := _button(area, "PLAY & PHOTOS")
	assert_not_null(tab, "the PLAY & PHOTOS tab (was PLAY TIME)")
	if tab:
		tab.pressed.emit()
	await wait_process_frames(3)


func test_the_page_shows_play_time_and_the_photo_switch_off_for_a_child() -> void:
	var area := await _area(_offline(AgeBand.UNDER_13))
	await _open_photos_page(area)
	assert_eq(area.page, GrownUpsPanel.PAGE_TIME)
	var words := _words(area)
	assert_string_contains(words, "Played today: 42 minutes", "play time stays on the page")
	assert_string_contains(words, "Photo sharing")
	assert_eq(area.photo_buttons.size(), 2, "ON and OFF")
	assert_false((area.photo_buttons[true] as Button).button_pressed)
	assert_true((area.photo_buttons[false] as Button).button_pressed, "off for a child until a grown-up says")
	await _check_fits(area, "play & photos")


func test_a_grown_up_turns_photo_sharing_on_and_photo_mode_offers_share() -> void:
	var s := _offline(AgeBand.UNDER_13)
	var area := await _area(s)
	await _open_photos_page(area)
	(area.photo_buttons[true] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(s.profile.photo_share, PhotoRules.SHARE_ON)
	assert_eq(saves, 1, "saved at once (no SAVE button: it is this phone's setting)")
	assert_true((area.photo_buttons[true] as Button).button_pressed)
	assert_false((area.photo_buttons[false] as Button).button_pressed)
	assert_string_contains(area.message.text, "on")
	var photo := _photo()
	photo.share_allowed = func() -> bool: return PhotoRules.may_share(s.profile.age_band, s.profile.photo_share)
	var old_game := Game.net_mode
	Game.net_mode = &"host"
	photo.open()
	assert_not_null(_share_chip(photo), "the child's photo mode has SHARE now")
	photo.close()
	Game.net_mode = old_game


func test_13_plus_starts_on_and_a_grown_up_can_turn_it_off() -> void:
	var s := _offline(AgeBand.TEEN_PLUS)
	var area := await _area(s)
	await _open_photos_page(area)
	assert_true((area.photo_buttons[true] as Button).button_pressed, "13+: on by default")
	(area.photo_buttons[false] as Button).pressed.emit()
	await wait_process_frames(2)
	assert_eq(s.profile.photo_share, PhotoRules.SHARE_OFF)
	assert_eq(saves, 1)
	assert_false(PhotoRules.may_share(s.profile.age_band, s.profile.photo_share))
	area.show_page(GrownUpsPanel.PAGE_ONLINE)
	await wait_process_frames(2)
	await _open_photos_page(area)
	assert_true((area.photo_buttons[false] as Button).button_pressed, "the choice shows when the page opens again")
