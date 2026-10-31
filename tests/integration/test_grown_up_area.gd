extends GutTest
## The grown-up area (M4 Wave 2, agent F; spec §5.14, §17.2) behind the parent gate, from SETTINGS
## and from PLAY ONLINE's "Ask a grown-up": online play and chat switches with the consent state,
## an under-13 player's friend requests to approve, and today's play time on this device. Plain
## adult words, big buttons, and every page fits the menu's panel on the 1280 x 720 screen.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
## The main menu's panel: below the logo (offset 130) with the panel's 28 px margins.
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)

var DIR := "user://test_grown_up_area_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000


func before_each() -> void:
	ParentGate.reset_tries()   # M4 Task 10 review E: the gates share one lock for the app run
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _service(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = band
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.clock = func() -> int: return now
	s.prefs.safe_card_seen = now
	add_child_autofree(s)
	return s


func _player(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS,
		consent: String = OnlineRules.CONSENT_VERIFIED) -> OnlineService:
	server.make_account(device, username, band, consent if band == AgeBand.UNDER_13 else OnlineRules.CONSENT_NONE,
		band == AgeBand.TEEN_PLUS or consent == OnlineRules.CONSENT_VERIFIED)
	var s := _service(device, username, band)
	assert_eq(await s.sign_in(), "")
	return s


## The area inside a themed panel, as the menus show it.
func _area(s: OnlineService, minutes: int = 0) -> GrownUpsPanel:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var area := GrownUpsPanel.new()
	area.service = s
	area.play_minutes = func() -> int: return minutes
	panel.add_child(area)
	await wait_process_frames(3)
	return area


func _buttons(root: Node) -> Array[Button]:
	var out: Array[Button] = []
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			out.append(b)
	return out


func _button(root: Node, prefix: String) -> Button:
	for b in _buttons(root):
		if b.text.begins_with(prefix):
			return b
	return null


func _press(root: Node, prefix: String) -> void:
	var b := _button(root, prefix)
	assert_not_null(b, "a %s button" % prefix)
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
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	for b in _buttons(area):
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, b.text])
		assert_gte(b.size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, b.text])


# --- The pages ---

func test_three_pages_and_done_each_fits_the_panel() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var area := await _area(kit, 42)
	assert_eq(area.page, GrownUpsPanel.PAGE_ONLINE, "online play first")
	await _check_fits(area, "online play")
	await _press(area, "FRIEND REQUESTS")
	assert_eq(area.page, GrownUpsPanel.PAGE_FRIENDS)
	await _check_fits(area, "friend requests")
	await _press(area, "PLAY & PHOTOS")
	assert_eq(area.page, GrownUpsPanel.PAGE_TIME)
	await _check_fits(area, "play time")
	var closed: Array = []
	area.closed.connect(func() -> void: closed.append(true))
	await _press(area, "DONE")
	assert_eq(closed, [true])


func test_the_consent_state_in_plain_words() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var area := await _area(kit)
	assert_string_contains(_words(area), "Parental consent: given")
	var waiting := await _player("dev-w", "Wren", AgeBand.UNDER_13, OnlineRules.CONSENT_PENDING)
	assert_string_contains(_words(await _area(waiting)), "Parental consent: waiting for you")
	var none := await _player("dev-n", "Nia", AgeBand.UNDER_13, OnlineRules.CONSENT_NONE)
	assert_string_contains(_words(await _area(none)), "Parental consent: not asked yet")
	var teen := await _player("dev-t", "Tom")
	assert_string_contains(_words(await _area(teen)), "13 or older: no parental consent needed")


func test_play_time_today_in_plain_words() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var area := await _area(kit, 42)
	await _press(area, "PLAY & PHOTOS")
	assert_string_contains(_words(area), "Played today: 42 minutes")
	assert_string_contains(_words(area), "on this device")


# --- Friend requests (under-13) ---

func test_a_grown_up_approves_a_friend_request_the_child_sent() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var pip := await _player("dev-p", "Pip")
	await kit.add_friend("Pip")
	var area := await _area(kit)
	await _press(area, "FRIEND REQUESTS")
	await wait_process_frames(2)
	assert_string_contains(_words(area), "Kit wants to be friends with Pip")
	await _press(area, "YES")
	await wait_process_frames(2)
	assert_eq(area.message.text, "Pip gets a friend request now.")
	assert_null(_button(area, "YES"), "nothing waits now")
	assert_string_contains(_words(area), "No friend requests are waiting.")
	await pip.refresh_friends()
	assert_eq(pip.friends[0].state, OnlineRules.RECEIVED)


func test_a_grown_up_approves_or_declines_requests_that_came_in() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var pip := await _player("dev-p", "Pip")
	var tom := await _player("dev-t", "Tom")
	for other: OnlineService in [pip, tom]:
		await other.add_friend("Kit")
	await kit.refresh_friends()
	for f in kit.friends.duplicate():
		await kit.accept(f.id)
	var area := await _area(kit)
	await _press(area, "FRIEND REQUESTS")
	await wait_process_frames(2)
	assert_string_contains(_words(area), "Pip wants to be friends with Kit")
	assert_string_contains(_words(area), "Tom wants to be friends with Kit")
	await _check_fits(area, "two requests")
	var row := area.find_child("Request_Pip", true, false)
	assert_not_null(row)
	(_button(row, "YES") as Button).pressed.emit()
	await wait_process_frames(3)
	assert_eq(area.message.text, "Kit and Pip are friends now.")
	row = area.find_child("Request_Tom", true, false)
	(_button(row, "NO") as Button).pressed.emit()
	await wait_process_frames(3)
	assert_eq(area.message.text, "Tom's request was declined.")
	await kit.refresh_friends()
	assert_eq(kit.friends.size(), 1)
	assert_eq(kit.friends[0].username, "Pip")


func test_13_plus_needs_no_approvals() -> void:
	var teen := await _player("dev-t", "Tom")
	var area := await _area(teen)
	await _press(area, "FRIEND REQUESTS")
	assert_string_contains(_words(area), "Players 13 and older add friends themselves.")
	assert_null(_button(area, "YES"))


# --- Not signed in (from SETTINGS) ---

func test_from_settings_the_area_signs_in_by_itself() -> void:
	server.make_account("dev-k", "Kit", AgeBand.UNDER_13, OnlineRules.CONSENT_VERIFIED)
	var kit := _service("dev-k", "Kit", AgeBand.UNDER_13)
	assert_eq(kit.status, OnlineService.OFFLINE)
	var area := await _area(kit, 5)
	await wait_process_frames(3)
	assert_eq(kit.status, OnlineService.ONLINE)
	assert_not_null(area.save_button, "the switches after signing in")
	assert_string_contains(_words(area), "Parental consent: given")


func test_without_a_server_play_time_still_shows() -> void:
	var kit := _service("dev-k", "Kit", AgeBand.UNDER_13)
	kit.server = {"error": "no release server yet"}
	var area := await _area(kit, 7)
	assert_string_contains(_words(area), OnlineRules.message("no_server"))
	assert_null(area.save_button)
	await _press(area, "PLAY & PHOTOS")
	assert_string_contains(_words(area), "Played today: 7 minutes")
	await _check_fits(area, "no server")


func test_the_server_unreachable_offers_try_again() -> void:
	server.down = true
	var kit := _service("dev-k", "Kit", AgeBand.UNDER_13)
	var area := await _area(kit)
	assert_string_contains(_words(area), OnlineRules.message("network"))
	server.down = false
	server.make_account("dev-k", "Kit", AgeBand.UNDER_13, OnlineRules.CONSENT_VERIFIED)
	await _press(area, "TRY AGAIN")
	await wait_process_frames(3)
	assert_not_null(area.save_button)


# --- SETTINGS -> GROWN-UPS -> the gate -> the area ---

func _settings(s: OnlineService) -> SettingsPanel:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var panel := SettingsPanel.new()
	panel.make_service = func() -> OnlineService: return s
	panel.play_minutes = func() -> int: return 3
	box.add_child(panel)
	add_child_autofree(box)
	await wait_process_frames(3)
	return panel


func test_settings_has_grown_ups_behind_the_parent_gate() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var settings := await _settings(kit)
	var size := (settings.get_parent() as Control).get_combined_minimum_size()
	assert_lte(size.y, 720.0, "the settings still fit (height %d)" % size.y)
	await _press(settings, "GROWN-UPS")
	var gate := settings.find_children("*", "GrownUpGate", true, false)
	assert_eq(gate.size(), 1, "the parent gate first")
	assert_null(_button(settings, "GROWN-UPS"), "the settings rows are hidden")
	var g := gate[0] as GrownUpGate
	for key in str(int(g.question.answer) + 1):
		g.press(key)
	g.press("OK")
	await wait_process_frames(2)
	assert_eq(settings.find_children("*", "GrownUpsPanel", true, false).size(), 0, "a wrong answer stays at the gate")
	for key in str(g.question.answer):
		g.press(key)
	g.press("OK")
	await wait_process_frames(3)
	var areas := settings.find_children("*", "GrownUpsPanel", true, false)
	assert_eq(areas.size(), 1, "the grown-up area")
	await _press(settings, "DONE")
	await wait_process_frames(2)
	assert_eq(settings.find_children("*", "GrownUpsPanel", true, false).size(), 0)
	assert_not_null(_button(settings, "GROWN-UPS"), "back to the settings")


func test_the_gates_back_returns_to_the_settings() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var settings := await _settings(kit)
	await _press(settings, "GROWN-UPS")
	await _press(settings, "BACK")
	assert_eq(settings.find_children("*", "GrownUpGate", true, false).size(), 0)
	assert_not_null(_button(settings, "GROWN-UPS"))
