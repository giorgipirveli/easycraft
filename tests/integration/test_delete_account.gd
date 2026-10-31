extends GutTest
## DELETE MY ONLINE ACCOUNT in the grown-up area (M4 Task 8b, agent G; spec §5.14, §17.2; Google
## Play's account-deletion rule, COPPA parents' rights), against the fake server: plain adult words on
## what goes and what stays, a hold-to-confirm button, the server's two calls, then the game forgets
## its online link (device id, online prefs, wallet markers) while offline play keeps working.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
## The main menu's panel: below the logo (offset 130) with the panel's 28 px margins.
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)
const FIRST_CODE := "sasa192974"   # only in tests

var DIR := "user://test_delete_account_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var _gold_before := 0
var _mode_before: StringName


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode


func after_each() -> void:
	Session.use_online_service(null)
	Profile.data.survivor_gold = _gold_before
	Game.mode = _mode_before
	Session.survivor_reset()
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


## A signed-in player whose device id and online files live in this test's folder (in Session, as
## the game's own service, or added to the test).
func _player(username: String, band: StringName = AgeBand.TEEN_PLUS, in_session := false) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id_path = DIR + username + "_device_id.json"
	var device := DeviceId.load_or_create(s.device_id_path)
	server.make_account(device, username, band, OnlineRules.CONSENT_VERIFIED if band == AgeBand.UNDER_13 else OnlineRules.CONSENT_NONE)
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = band
	s.profile.survivor_gold = 250
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + username + "_online.json"
	s.clock = func() -> int: return now
	if in_session:
		Session.use_online_service(s)
	else:
		add_child_autofree(s)
	assert_eq(await s.sign_in(), "")
	s.prefs.safe_card_seen = now
	s.prefs.mute("someone-else")
	s.prefs.save_to(s.prefs_path)
	WalletSync.set_marker(s._f_wallet_path(), s.backend.user_id(), 250)
	WalletSync.set_marker(s._f_wallet_path(), s.backend.user_id(), 260)   # a .bak beside it too
	return s


func _area(s: OnlineService, in_world := false) -> GrownUpsPanel:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var area := GrownUpsPanel.new()
	area.service = s
	area.play_minutes = func() -> int: return 12
	area.in_online_world = func() -> bool: return in_world
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


func _hold(area: GrownUpsPanel, seconds: float) -> void:
	for f in area.find_children("*", "HBoxContainer", true, false):
		if f is PasswordField:   # owner #105: the password once the account has one (the fake's accounts have)
			(f as PasswordField).text = FakeServer.FAKE_PASSWORD
	var hold := area.find_children("*", "HoldButton", true, false)
	assert_eq(hold.size(), 1, "one hold-to-confirm button")
	if hold.is_empty():
		return
	var b := hold[0] as HoldButton
	b.set_process(false)
	b.button_down.emit()
	b.step(seconds)
	if seconds < b.hold_seconds:
		b.button_up.emit()
	await wait_process_frames(4)


func _check_fits(area: Control, what: String) -> void:
	await wait_process_frames(2)
	var size := area.get_combined_minimum_size()
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	for b in _buttons(area):
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, b.text])
		assert_gte(b.size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, b.text])


func _gone(path: String) -> bool:
	return not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak") \
		and not FileAccess.file_exists(path + ".tmp")


# --- The page ---

func test_online_play_leads_to_the_page_which_says_what_goes_and_what_stays_and_fits() -> void:
	for band: StringName in [AgeBand.UNDER_13, AgeBand.TEEN_PLUS]:
		var s := await _player("Kit" if band == AgeBand.UNDER_13 else "Tom", band)
		var area := await _area(s)
		await _check_fits(area, "online play with the delete button (%s)" % band)
		await _press(area, "DELETE MY ONLINE ACCOUNT")
		assert_eq(area.page, GrownUpsPanel.PAGE_DELETE)
		await wait_process_frames(3)
		var words := _words(area)
		for goes: String in ["online name", "friends", "chat", "backup"]:
			assert_string_contains(words, goes, "says it deletes the %s" % goes)
		for stays: String in ["Worlds", "on this device", "Sandbox", "Survivor"]:
			assert_string_contains(words, stays, "says %s stays" % stays)
		assert_string_contains(words, "Reports", "says reports stay without the child's name")
		assert_string_contains(words, "can't be undone")
		await _check_fits(area, "the delete page (%s)" % band)
		assert_not_null(_button(area, "BACK"))
		await _press(area, "BACK")
		assert_eq(area.page, GrownUpsPanel.PAGE_ONLINE)


func test_a_tap_or_a_short_hold_deletes_nothing() -> void:
	var s := await _player("Tom")
	var id := s.backend.user_id()
	var area := await _area(s)
	await _press(area, "DELETE MY ONLINE ACCOUNT")
	await wait_process_frames(3)
	await _press(area, "HOLD")
	await _hold(area, 2.0)
	assert_true(server.accounts.has(id), "still there")
	assert_eq(s.status, OnlineService.ONLINE)
	assert_eq(server.calls.count("delete_account"), 1, "only the first call: a confirmation, nothing deleted")


func test_holding_three_seconds_deletes_the_account_and_the_device_forgets_its_online_link() -> void:
	var s := await _player("Tom")
	var id := s.backend.user_id()
	var pal := await _player("Pal")
	server.befriend(id, pal.backend.user_id())
	var files: Array[String] = [s.device_id_path, s.prefs_path, s._f_wallet_path()]
	for f in files:
		assert_true(FileAccess.file_exists(f), "kept before: %s" % f)
	var area := await _area(s)
	await _press(area, "DELETE MY ONLINE ACCOUNT")
	await wait_process_frames(3)
	watch_signals(s)
	await _hold(area, 3.0)
	await wait_process_frames(3)
	assert_false(server.accounts.has(id), "the server's account is gone")
	assert_eq(server.deleted, [id] as Array[String])
	assert_false(server.edges.get(pal.backend.user_id(), {}).has(id), "gone from the friend's list")
	assert_signal_emitted(s, "account_deleted")
	assert_eq(s.status, OnlineService.OFFLINE)
	assert_eq(s.account, {}, "no cached account")
	assert_eq(s.friends, [] as Array[Dictionary])
	for f in files:
		assert_true(_gone(f), "forgotten: %s (and its .bak)" % f)
	assert_eq(s.prefs.safe_card_seen, 0, "a new online account starts with the stay-safe card")
	assert_false(s.prefs.is_muted("someone-else"))
	assert_eq(s.profile.username, "Tom", "the profile on this device stays")
	assert_eq(s.profile.survivor_gold, 250, "gold on this device stays")
	assert_string_contains(_words(area), "deleted")
	await _press(area, "OK")
	assert_eq(area.page, GrownUpsPanel.PAGE_ONLINE)
	assert_string_contains(_words(area), "no online account")


func test_after_deletion_the_grown_up_area_makes_no_new_account_by_itself() -> void:
	var s := await _player("Tom")
	assert_eq(await s.delete_account((await s.delete_account_start()).confirm, FakeServer.FAKE_PASSWORD), "")
	var signins: int = server.calls.count("sign_in")
	var area := await _area(s)
	await wait_process_frames(5)
	assert_eq(server.calls.count("sign_in"), signins, "no sign-in: it would make a new account")
	assert_string_contains(_words(area), "no online account")
	assert_null(_button(area, "DELETE MY ONLINE ACCOUNT"))
	await _press(area, "PLAY & PHOTOS")
	assert_string_contains(_words(area), "Played today: 12 minutes", "play time on this device still shows")


func test_a_late_hold_asks_for_a_new_confirmation() -> void:
	var s := await _player("Tom")
	var id := s.backend.user_id()
	var area := await _area(s)
	await _press(area, "DELETE MY ONLINE ACCOUNT")
	await wait_process_frames(3)
	server.fail_next["delete_account"] = "confirm_expired"
	await _hold(area, 3.0)
	await wait_process_frames(3)
	assert_true(server.accounts.has(id))
	assert_string_contains(_words(area), "took too long")
	assert_eq(server.calls.count("delete_account"), 3, "a first confirmation, the late try, a new confirmation")
	await _hold(area, 3.0)
	await wait_process_frames(3)
	assert_false(server.accounts.has(id), "held again: deleted")


func test_from_play_online_the_screen_closes_after_deletion_and_makes_no_new_account() -> void:
	var s := await _player("Tom")
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var screen := PlayOnlineScreen.new()
	screen.service = s
	panel.add_child(screen)
	await wait_process_frames(3)
	screen.call("_show_grownups")
	await wait_process_frames(2)
	var area := screen.page as GrownUpsPanel
	area.in_online_world = func() -> bool: return false
	await _press(area, "DELETE MY ONLINE ACCOUNT")
	await wait_process_frames(3)
	var closed: Array = []
	screen.closed.connect(func() -> void: closed.append(true))
	var signins: int = server.calls.count("sign_in")
	await _hold(area, 3.0)
	await wait_process_frames(3)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_GROWNUPS, "the grown-up still sees that it worked")
	assert_string_contains(_words(area), "deleted")
	await _press(area, "OK")
	await _press(area, "DONE")
	assert_eq(closed, [true], "PLAY ONLINE closes: its pages belonged to the deleted account")
	assert_eq(server.calls.count("sign_in"), signins, "and it makes no new account by itself")


func test_in_an_online_world_it_asks_to_leave_first() -> void:
	var s := await _player("Tom")
	var area := await _area(s, true)
	await _press(area, "DELETE MY ONLINE ACCOUNT")
	await wait_process_frames(3)
	assert_string_contains(_words(area), "Leave the online world first")
	assert_eq(area.find_children("*", "HoldButton", true, false).size(), 0)


func test_the_server_says_no_in_plain_words() -> void:
	var s := await _player("Tom")
	var area := await _area(s)
	server.fail_next["delete_account"] = "server_error"
	await _press(area, "DELETE MY ONLINE ACCOUNT")
	await wait_process_frames(3)
	assert_string_contains(_words(area), OnlineRules.message("server_error"))
	var hold := area.find_children("*", "HoldButton", true, false)
	assert_true(hold.is_empty() or (hold[0] as HoldButton).disabled, "nothing to confirm with")


# --- The offline game after deletion ---

func test_offline_play_keeps_working_after_deletion() -> void:
	var s := await _player("Tom", AgeBand.TEEN_PLUS, true)
	var keep := DIR + "world.json"
	JsonStore.write_atomic(keep, "{\"seed\": 42}")
	assert_eq(await s.delete_account((await s.delete_account_start()).confirm, FakeServer.FAKE_PASSWORD), "")
	assert_true(FileAccess.file_exists(keep), "only the online files go")
	# Survivor gold: the host (this game) keeps the child's gold; nothing waits for a server.
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 30
	var me := multiplayer.get_unique_id()
	Session.gold_add(me, 12, "slime")
	assert_eq(Profile.data.survivor_gold, 42)
	assert_true(Session.gold_spend(me, 40))
	assert_eq(s.pending_reports(), 0, "no reports for a server")
	# Codes: the phone decides, as before online play.
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 1000)
	assert_eq(r.status, CodeRules.ACCEPTED, "codes work offline")
	# LAN (home Wi-Fi) starts as before.
	assert_eq(Session.host_lan(47_000 + OS.get_process_id() % 1000), OK)
	Session.close()
	# No sign-in by itself at the next start (the stay-safe card was never seen on this link).
	assert_eq(OnlinePrefs.load_from(s.prefs_path).safe_card_seen, 0)
	# PLAY ONLINE later: a new account with a new device id, from the start (the card, then a name).
	var old_device: int = server.accounts.size()
	assert_eq(await s.sign_in(), "")
	assert_eq(server.accounts.size(), old_device + 1, "a fresh account")
	assert_true(FileAccess.file_exists(s.device_id_path), "a new device id")
	assert_eq(s.screen(), OnlineRules.SCREEN_SAFE_CARD)


# --- A report keeps the message the child saw ---

func test_reporting_a_message_sends_the_message_as_shown() -> void:
	var pip := await _player("Pip")
	var max := await _player("Max")
	server.now_unix = now
	server.befriend(pip.backend.user_id(), max.backend.user_id())
	await pip.refresh_friends()
	await max.refresh_friends()
	var a := await pip.open_dm(max.backend.user_id())
	await max.open_dm(pip.backend.user_id())
	await max.send_text(a.channel_id, "you are silly")
	var msg: Dictionary = pip.messages(a.channel_id)[0]
	assert_eq(await pip.report_message(msg, OnlineService.REPORT_MEAN), "")
	var report: Dictionary = server.reports.back()
	assert_eq(report.message_id, msg.id)
	assert_eq(report.message, {"text": "you are silly", "at_ms": now * 1000})
	await max.send_emote(a.channel_id, &"wave")
	# (muted now: pip no longer sees max's messages; report straight from the message)
	assert_eq(await pip.report_message({"id": "m2", "from_id": max.backend.user_id(), "channel_id": a.channel_id,
		"text": "", "emote": &"wave", "time": now, "mine": false}, OnlineService.REPORT_OTHER), "")
	assert_eq(server.reports.back().message, {"emote": "wave", "at_ms": now * 1000})
