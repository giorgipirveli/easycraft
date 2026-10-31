extends GutTest
## M5 Task 4 (store readiness, finding F3): Google Play's User Data policy wants the privacy policy inside the app as
## well as in Play Console. The grown-up area (behind the parent gate) has a PRIVACY page, one tap from every page:
## the trust promise (docs/store/trust-promise.md, spec §16) and buttons that open the privacy policy and the
## "delete your data" page on the game's own server (the pages tools/make_store_pages.py makes and Caddy serves).
## It needs no online account and no connection to show, like PLAY & PHOTOS (PLAY TIME before M5 F1).

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
## The main menu's panel: below the logo (offset 130) with the panel's 28 px margins (as test_grown_up_area.gd).
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)

var DIR := "user://test_grown_up_privacy_%d/" % OS.get_process_id()
var server: RefCounted
var opened: Array[String] = []


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	opened.clear()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


## A service that never signed in (no online account on this device).
func _offline() -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.profile = ProfileData.new()
	s.profile.username = "Kit"
	s.profile.age_band = AgeBand.UNDER_13
	s.save_profile = func() -> void: pass
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
	area.play_minutes = func() -> int: return 5
	area.open_url = func(url: String) -> void: opened.append(url)
	panel.add_child(area)
	await wait_process_frames(3)
	return area


func _buttons(root: Node) -> Array[Button]:
	var out: Array[Button] = []
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			out.append(b)
	return out


func _button(root: Node, text: String) -> Button:
	for b in _buttons(root):
		if b.text == text:
			return b
	return null


func _press(root: Node, text: String) -> void:
	var b := _button(root, text)
	assert_not_null(b, "a %s button" % text)
	if b:
		b.pressed.emit()
	await wait_process_frames(3)


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
	for b in _buttons(area):
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, b.text])
		assert_gte(b.size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, b.text])


func test_privacy_is_one_tap_away_on_every_page_and_shows_the_trust_promise() -> void:
	var area := await _area(_offline())
	for p: StringName in [GrownUpsPanel.PAGE_ONLINE, GrownUpsPanel.PAGE_TIME, GrownUpsPanel.PAGE_SHOP]:
		area.show_page(p)
		await wait_process_frames(2)
		assert_not_null(_button(area, "PRIVACY"), "PRIVACY on the %s page" % p)
	await _press(area, "PRIVACY")
	assert_eq(area.page, GrownUpsPanel.PAGE_PRIVACY)
	var words := _words(area)
	for line: String in GrownUpsPanel.PROMISE:
		assert_string_contains(words, line)
	assert_string_contains(words, OnlineConfig.SUPPORT_EMAIL, "whom to write to")
	assert_true(_button(area, "PRIVACY").button_pressed, "the PRIVACY button is lit on its page")
	await _check_fits(area, "the privacy page")
	await _press(area, "PLAY & PHOTOS")
	assert_eq(area.page, GrownUpsPanel.PAGE_TIME, "the other pages still open")


func test_the_buttons_open_our_privacy_policy_and_deletion_pages() -> void:
	var area := await _area(_offline())
	area.show_page(GrownUpsPanel.PAGE_PRIVACY)
	await wait_process_frames(2)
	await _press(area, "PRIVACY POLICY")
	await _press(area, "DELETING DATA")
	assert_eq(opened, [OnlineConfig.RELEASE_SERVER + "/privacy", OnlineConfig.RELEASE_SERVER + "/delete-account"] as Array[String])
	assert_eq(OnlineConfig.privacy_url(), "https://178-104-20-64.sslip.io/privacy", "the URL in Play Console")


func test_the_pages_are_the_ones_the_server_serves() -> void:
	var caddy := FileAccess.get_file_as_string("res://server/deploy/caddy/Caddyfile")
	var tool := FileAccess.get_file_as_string("res://tools/make_store_pages.py")
	for path: String in [OnlineConfig.PRIVACY_PAGE, OnlineConfig.DELETE_PAGE]:
		assert_string_contains(caddy, " " + path + " ", "Caddy serves %s" % path)
		assert_string_contains(tool, "\"%s\":" % path.trim_prefix("/"), "make_store_pages.py makes %s" % path)
	var policy := FileAccess.get_file_as_string("res://docs/store/privacy-policy.md")
	assert_string_contains(policy, OnlineConfig.delete_account_url(), "the policy links the deletion page")
	assert_string_contains(policy, OnlineConfig.SUPPORT_EMAIL, "the policy and the game name the same address")

