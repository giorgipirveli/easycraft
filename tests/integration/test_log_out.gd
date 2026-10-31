extends GutTest
## Owner #99, #104, #105 (spec §5.13 "As built"; the final review's simple model: one player on a device, no kept slots).
## LOG OUT is one tap and one YES / NO, never a grown-up's step (the owner, 2026-10-15 23:06: "why i need to go to grow up
## to logout?"), from the main menu, SETTINGS and PLAY ONLINE. It saves everything to the account first (offline: refused),
## makes the player make a password first when the account has none, unlinks this device on the server, and forgets the
## account and the player on this device (the worlds stay); then the start screen. LOG IN (the name and the password, or a
## grown-up's key) brings the account back on any device, logs its other devices out, and never doubles gold. Against the
## fake server, in a folder of this test's own.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
## The main menu's panel: below the logo (offset 130) with the panel's 28 px margins.
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)
const PW := FakeServer.FAKE_PASSWORD

var ROOT := "user://test_log_out_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var profile: ProfileData


func before_each() -> void:
	_remove(ROOT)
	DirAccess.make_dir_recursive_absolute(ROOT)
	server = FakeServer.new()
	profile = ProfileData.new()


func after_all() -> void:
	_remove(ROOT)


func _remove(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		for d in DirAccess.get_directories_at(path):
			_remove(path.path_join(d))
		for f in DirAccess.get_files_at(path):
			DirAccess.remove_absolute(path.path_join(f))
		DirAccess.remove_absolute(path)


func _service(p: ProfileData = null, root: String = "") -> OnlineService:
	var at := root if root != "" else ROOT
	DirAccess.make_dir_recursive_absolute(at)
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id_path = at + "device_id.json"
	s.prefs_path = at + "online.json"
	s.wallet_path = at + "wallet_sync.json"
	s.gift_book_path = at + "gifts.json"
	s.ghost_book_path = at + "ghosts.json"
	s.profile = p if p != null else profile
	var own := p if p != null else profile
	s.save_profile = func() -> void: JsonStore.write_atomic(at + "profile.json", own.to_json())
	s.clock = func() -> int: return now
	s.move_card = false
	s.logged_out_card = false
	add_child_autofree(s)
	s.prefs.safe_card_seen = now   # after _ready (it reads the prefs file)
	s.prefs.save_to(s.prefs_path)
	return s


func _named(name: String) -> void:
	profile.username = name
	profile.age_band = AgeBand.TEEN_PLUS
	profile.updated_at = now


## Anna, claimed (with the fake's password) and signed in on this device.
func _anna() -> OnlineService:
	_named("Anna_7")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.claim_username("Anna_7"), "")
	return s


func _flow(s: OnlineService, start_at: StringName = AccountsFlow.VIEW_LOG_OUT) -> AccountsFlow:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var f := AccountsFlow.new()
	f.service = s
	f.start_at = start_at
	f.open_menu = false
	box.add_child(f)
	add_child_autofree(box)
	await wait_process_frames(6)
	return f


func _press(root: Node, prefix: String) -> void:
	var b: Button = null
	for x in root.find_children("*", "Button", true, false):
		if (x as Button).is_visible_in_tree() and (x as Button).text.begins_with(prefix):
			b = x
			break
	assert_not_null(b, "a %s button" % prefix)
	if b:
		b.pressed.emit()
	await wait_process_frames(10)


func _words(root: Node) -> String:
	var out := ""
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out += (l as Label).text + "\n"
	return out


func _fits(root: Control, what: String) -> void:
	await wait_process_frames(2)
	var size := root.get_combined_minimum_size()
	gut.p("%s: %d x %d" % [what, size.x, size.y])   # the measurement for the notes
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and not (b is ReadAloud.ReadAloudSpeaker):
			assert_gte((b as Button).size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, (b as Button).text])


func _no_gate(root: Node, what: String) -> void:
	assert_eq(root.find_children("*", "HBoxContainer", true, false).filter(func(n: Node) -> bool: return n is GrownUpGate),
		[], what + ": never a grown-up's step")


## Types into a LOG IN page and presses LOG IN.
func _log_in(f: AccountsFlow, username: String, password: String) -> void:
	var p := f.page as LogInPage
	assert_not_null(p, "the LOG IN page")
	if p == null:
		return
	p.name_edit.text = username
	p.password.text = password
	await _press(f, DeviceMoveRules.LOG_IN)
	await wait_process_frames(10)


# --- LOG OUT: one tap and one YES / NO ---

func test_log_out_asks_once_and_never_a_grown_ups_step() -> void:
	var s := await _anna()
	var f := await _flow(s)
	assert_eq(f.view, AccountsFlow.VIEW_CONFIRM)
	assert_string_contains(_words(f), "Log out, Anna_7?")
	assert_string_contains(_words(f), DeviceMoveRules.LOG_OUT_SAVED_FIRST)
	_no_gate(f, "the question")
	await _fits(f, "the LOG OUT question")
	var closed := []
	f.closed.connect(func() -> void: closed.append(true))
	await _press(f, DeviceMoveRules.NO)
	assert_eq(closed, [true], "NO: she plays on")
	assert_eq(profile.username, "Anna_7")


func test_offline_it_refuses_with_plain_words_and_try_again() -> void:
	var s := await _anna()
	s.sign_out()
	s._set_status(OnlineService.OFFLINE)
	server.down = true
	var f := await _flow(s)
	await _press(f, DeviceMoveRules.YES_LOG_OUT)
	assert_eq(f.view, AccountsFlow.VIEW_LOG_OUT)
	assert_string_contains(_words(f), DeviceMoveRules.OFFLINE)
	assert_eq(profile.username, "Anna_7", "nothing changed")
	await _fits(f, "LOG OUT offline")
	server.down = false
	var switched := []
	f.switched.connect(func() -> void: switched.append(true))
	await _press(f, "TRY AGAIN")
	assert_eq(switched, [true], "logged out once the internet is back")


func test_everything_reaches_the_account_before_logging_out() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	assert_eq(await s.sync_wallet(true), "")
	profile.universe_unlocked = 4
	profile.survivor_gold += 300   # played alone meanwhile
	s.save_profile.call()
	s.profile_sync.mark_changed()
	var gold := profile.survivor_gold
	assert_eq(await s.log_out(), "")
	assert_string_contains(server.backup_of(me), "\"universe_unlocked\":4", "the profile backup has the latest")
	assert_eq(int(server.wallets.get(me, 0)), gold, "the gold is on the server")


func test_a_save_that_does_not_reach_the_server_keeps_the_player_here() -> void:
	var s := await _anna()
	profile.universe_unlocked = 4
	s.profile_sync.mark_changed()
	server.fail_next["write_storage"] = "busy"
	assert_eq(await s.log_out(), DeviceMoveRules.NOT_SAVED)
	assert_eq(profile.username, "Anna_7", "she plays on")
	assert_true(FileAccess.file_exists(ROOT + "device_id.json"), "nothing was forgotten")


func test_a_player_with_no_online_account_has_nothing_to_log_out() -> void:
	_named("Pip_3")   # never online
	var s := _service()
	assert_eq(await s.log_out(), DeviceMoveRules.NO_ACCOUNT)
	assert_eq(profile.username, "Pip_3", "nothing changed")


func test_an_account_without_a_password_makes_one_first_then_logs_out() -> void:
	server.claims_make_password = false
	var s := await _anna()
	var f := await _flow(s)
	await _press(f, DeviceMoveRules.YES_LOG_OUT)
	assert_eq(f.view, AccountsFlow.VIEW_PASSWORD, "a password first, so she can log back in")
	assert_string_contains(_words(f), DeviceMoveRules.MAKE_FIRST)
	assert_eq(profile.username, "Anna_7", "not logged out without one")
	await _fits(f, "make a password first")
	var page := f.page as PasswordPage
	page.new_field.text = "willow3comet"
	page.again_field.text = "willow3comet"
	page.ok_button.pressed.emit()
	await wait_process_frames(10)
	var switched := []
	f.switched.connect(func() -> void: switched.append(true))
	await _press(f, "OK")
	assert_eq(switched, [true], "then LOG OUT went on")
	assert_eq(profile.username, "", "a new player on this device")


# --- What LOG OUT does ---

func test_log_out_unlinks_this_device_and_forgets_the_account_and_the_player_but_keeps_the_worlds() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	var mine := OnlineService._pw_read_id(ROOT + "device_id.json")
	profile.survivor_gold = 120
	profile.universe_unlocked = 3
	s.save_profile.call()
	DirAccess.make_dir_recursive_absolute(ROOT + "worlds/w1")
	JsonStore.write_atomic(ROOT + "worlds/w1/world.json", "{}")
	assert_eq(await s.log_out(), "")
	assert_eq(server.log_outs, [me] as Array[String], "this device left the account on the server")
	assert_true(server.removed_devices.has(mine), "its id is tombstoned: it never signs in by itself again")
	assert_true(server.accounts.has(me), "the account is safe on the server")
	assert_false(FileAccess.file_exists(ROOT + "device_id.json"), "the device id goes")
	assert_false(FileAccess.file_exists(ROOT + "online.json"), "the online prefs go")
	assert_false(FileAccess.file_exists(ROOT + "wallet_sync.json"), "the wallet markers go")
	assert_eq(profile.username, "", "a fresh new player: the start screen")
	assert_eq(profile.survivor_gold, ProfileData.new().survivor_gold, "no gold left on this device")
	assert_eq(profile.universe_unlocked, ProfileData.new().universe_unlocked)
	assert_true(FileAccess.file_exists(ROOT + "worlds/w1/world.json"), "the worlds stay: they belong to the device")
	assert_eq(s.status, OnlineService.OFFLINE)
	assert_eq(s.prefs.account_name, "")


func test_log_in_after_log_out_brings_the_account_back_and_gold_never_doubles() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	profile.universe_unlocked = 6
	profile.survivor_gold = 250
	s.save_profile.call()
	s.profile_sync.mark_changed()
	assert_eq(await s.log_out(), "")
	var on_server: int = int(server.wallets.get(me, 0))
	assert_eq(on_server, 250)
	var f := await _flow(s, AccountsFlow.VIEW_LOG_IN)   # the start screen's LOG IN
	_no_gate(f, "LOG IN")
	await _fits(f, "LOG IN")
	var switched := []
	f.switched.connect(func() -> void: switched.append(true))
	await _log_in(f, "anna_7", PW)
	assert_eq(switched, [true])
	assert_eq(s.backend.user_id(), me, "her own account again")
	assert_eq(profile.username, "Anna_7")
	assert_eq(profile.universe_unlocked, 6, "her progress came down from the backup")
	assert_eq(profile.survivor_gold, 250, "her gold, once: never doubled")
	assert_eq(int(server.wallets.get(me, 0)), 250, "the server's gold unchanged")


func test_log_in_as_another_account_asks_first_then_starts_from_a_fresh_player_so_nothing_merges() -> void:
	# The final review's 2: a guest's gold and progress never go without asking ("Pip_3's gold and progress on this
	# device will go. Your worlds stay. Log in as Cleo_5?" YES / NO).
	_named("Pip_3")   # played alone here, never online: some gold and progress
	profile.survivor_gold = 500
	profile.universe_unlocked = 5
	var s := _service()
	s.save_profile.call()
	var cleo: String = server.make_account("cleo-device-000001", "Cleo_5")
	server.wallets[cleo] = 40
	var f := await _flow(s, AccountsFlow.VIEW_LOG_IN)
	var switched := []
	f.switched.connect(func() -> void: switched.append(true))
	await _log_in(f, "Cleo_5", PW)
	var p := f.page as LogInPage
	assert_eq(p.asking, "Pip_3", "asked first")
	assert_string_contains(_words(f), DeviceMoveRules.GUEST_GOES % ["Pip_3", "Cleo_5"])
	assert_eq(switched, [], "nothing happened yet")
	assert_eq(profile.username, "Pip_3")
	assert_ne(s.backend.user_id(), cleo)
	await _fits(f, "LOG IN's question")
	await _press(f, DeviceMoveRules.NO)
	assert_eq(p.asking, "", "NO: the page again")
	assert_eq(f.view, AccountsFlow.VIEW_LOG_IN)
	assert_string_contains(_words(f), PasswordRules.ONE_DEVICE)
	assert_eq(profile.survivor_gold, 500, "Pip's gold stays")
	await _press(f, DeviceMoveRules.LOG_IN)
	assert_eq(p.asking, "Pip_3", "asked again")
	await _press(f, DeviceMoveRules.YES)
	await wait_process_frames(10)
	assert_eq(switched, [true])
	assert_eq(s.backend.user_id(), cleo)
	assert_eq(profile.username, "Cleo_5")
	assert_eq(profile.survivor_gold, 40, "Pip's 500 never went into Cleo's account")
	assert_eq(int(server.wallets.get(cleo, 0)), 40, "Cleo's gold on the server is unchanged")
	assert_ne(profile.universe_unlocked, 5, "Pip's progress did not merge into Cleo's")


func test_a_new_player_with_nothing_played_yet_is_never_asked() -> void:
	_named("Pip_3")   # a name and the start gold: nothing to lose
	profile.hints_seen.append("jump")   # what the first minutes set is not progress
	var s := _service()
	s.save_profile.call()
	server.make_account("cleo-device-000001", "Cleo_5")
	assert_eq(s.progress_goes("Cleo_5"), "")
	var f := await _flow(s, AccountsFlow.VIEW_LOG_IN)
	var switched := []
	f.switched.connect(func() -> void: switched.append(true))
	await _log_in(f, "Cleo_5", PW)
	assert_eq((f.page as LogInPage).asking, "", "never asked")
	assert_eq(switched, [true], "straight in")
	assert_eq(profile.username, "Cleo_5")


func test_typing_again_after_the_question_asks_anew() -> void:
	_named("Pip_3")
	profile.universe_unlocked = 2
	var s := _service()
	s.save_profile.call()
	var f := await _flow(s, AccountsFlow.VIEW_LOG_IN)
	await _log_in(f, "Cleo_5", PW)
	var p := f.page as LogInPage
	assert_eq(p.asking, "Pip_3")
	p.name_edit.text = "Dora_2"
	p.name_edit.text_changed.emit(p.name_edit.text)
	assert_eq(p.asking, "", "another name: the question goes")
	assert_eq(p.log_in_button.text, DeviceMoveRules.LOG_IN)
	assert_eq(p.back_button.text, "BACK")
	assert_true(p.help_row.visible, "FORGOT PASSWORD? and USE A KEY again")


# --- The final review's blockers: LOG OUT never forgets what the server has not taken ---

func test_gold_over_the_servers_hourly_cap_is_never_forgotten_by_log_out() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	assert_eq(await s.sync_wallet(true), "")
	var before := int(server.wallets.get(me, 0))
	profile.survivor_gold += 30000   # a long offline play: more than the server takes in an hour
	s.save_profile.call()
	var gold := profile.survivor_gold
	assert_eq(await s.log_out(), DeviceMoveRules.GOLD_ON_ITS_WAY, "try again in an hour")
	assert_eq(profile.username, "Anna_7", "she plays on")
	assert_eq(profile.survivor_gold, gold, "every coin still on this device")
	assert_true(FileAccess.file_exists(ROOT + "device_id.json"), "nothing was forgotten")
	assert_lt(int(server.wallets.get(me, 0)), before + 30000, "the server took less this hour")
	server.awarded_this_hour.clear()   # an hour later
	assert_eq(await s.log_out(), "", "then LOG OUT goes")
	assert_eq(int(server.wallets.get(me, 0)), gold, "every coin on the server")


func test_the_hourly_cap_words_show_on_the_log_out_page() -> void:
	var s := await _anna()
	assert_eq(await s.sync_wallet(true), "")
	profile.survivor_gold += 30000
	s.save_profile.call()
	var f := await _flow(s)
	await _press(f, DeviceMoveRules.YES_LOG_OUT)
	await wait_process_frames(10)
	assert_eq(f.view, AccountsFlow.VIEW_LOG_OUT)
	assert_string_contains(_words(f), DeviceMoveRules.GOLD_ON_ITS_WAY)
	assert_eq(profile.username, "Anna_7")
	await _fits(f, "LOG OUT: gold on its way")


func test_a_wallet_blip_during_log_out_keeps_the_player_here() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	assert_eq(await s.sync_wallet(true), "")
	var before := int(server.wallets.get(me, 0))
	profile.survivor_gold += 300
	s.save_profile.call()
	server.fail_next["wallet_award"] = "network"
	assert_eq(await s.log_out(), DeviceMoveRules.NOT_SAVED)
	assert_eq(profile.username, "Anna_7", "refused: she plays on")
	assert_eq(profile.survivor_gold, before + 300, "her gold is still here")
	assert_eq(await s.log_out(), "", "the next try goes")
	assert_eq(int(server.wallets.get(me, 0)), before + 300, "every coin on the server")


func test_a_backup_the_server_refuses_keeps_the_player_here() -> void:
	var s := await _anna()
	profile.universe_unlocked = 7
	s.save_profile.call()
	s.profile_sync.mark_changed()
	server.fail_next["write_storage"] = "bad_profile"
	assert_eq(await s.log_out(), DeviceMoveRules.NOT_SAVED, "a refused backup is not saved either")
	assert_eq(profile.universe_unlocked, 7, "the only copy is kept")
	assert_eq(profile.username, "Anna_7")
	assert_true(FileAccess.file_exists(ROOT + "device_id.json"))


# --- The final review's checks: logged out and in again, a kill, another account, the start gold, DELETE ---

func test_a_logged_out_device_plays_on_then_logs_in_again_and_nothing_doubles() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	assert_eq(await s.sync_wallet(true), "")
	var start := int(server.wallets.get(me, 0))
	var tab := ProfileData.new()
	tab.username = "Tab_1"
	tab.age_band = AgeBand.TEEN_PLUS
	var t := _service(tab, ROOT + "tab/")
	assert_eq(await t.log_in("Anna_7", PW), "")
	assert_eq(t.backend.user_id(), me)
	assert_eq(tab.survivor_gold, start, "the tablet has Anna's gold")
	tab.survivor_gold -= 10   # spent on the tablet
	t.save_profile.call()
	assert_eq(await t.sync_wallet(true), "")
	assert_eq(int(server.wallets.get(me, 0)), start - 10)
	s._set_status(OnlineService.OFFLINE)   # the phone, logged out, plays on offline
	profile.survivor_gold += 100
	profile.universe_unlocked = 3
	s.save_profile.call()
	assert_eq(await s.sign_in(), PasswordRules.LOGGED_OUT)
	assert_eq(s.progress_goes("anna_7"), "", "her own account (known by its id): kept, never asked")
	assert_eq(s.progress_goes("Cleo_5"), "Anna_7", "another account would ask first")
	assert_eq(await s.log_in("Anna_7", PW), "")
	assert_eq(int(server.wallets.get(me, 0)), start - 10 + 100, "the phone's 100 once, the tablet's spend kept")
	assert_eq(profile.survivor_gold, start - 10 + 100)
	assert_eq(profile.universe_unlocked, 3, "what was played on the logged-out phone is kept")


func test_a_kill_right_after_the_servers_log_out_comes_back_logged_out_and_nothing_doubles() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	profile.survivor_gold = 80
	s.save_profile.call()
	assert_eq(await s.save_for_log_out(), "")
	var on_server := int(server.wallets.get(me, 0))
	var mine := OnlineService._pw_read_id(ROOT + "device_id.json")
	var r: Dictionary = await s.backend.call_rpc("log_out", {"device_id": mine})
	assert_true(r.get("ok", false))
	s.backend.sign_out()   # the game is killed here: a new service on the same files
	remove_child(s)
	s.free()
	var again := _service()
	assert_eq(await again.sign_in(), PasswordRules.LOGGED_OUT, "logged out, never a new account")
	assert_eq(again.prefs.account_name, "Anna_7")
	assert_eq(again.progress_goes("Anna_7"), "", "her own account: never asked")
	assert_eq(await again.log_in("Anna_7", PW), "")
	assert_eq(again.backend.user_id(), me)
	assert_eq(int(server.wallets.get(me, 0)), on_server)
	assert_eq(profile.survivor_gold, on_server)


func test_logged_out_of_one_account_and_in_as_another_mixes_nothing() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	assert_eq(await s.sync_wallet(true), "")
	var start := int(server.wallets.get(me, 0))
	var tab := ProfileData.new()
	tab.username = "Tab_1"
	var t := _service(tab, ROOT + "tab/")
	assert_eq(await t.log_in("Anna_7", PW), "")
	s._set_status(OnlineService.OFFLINE)
	profile.survivor_gold += 100
	profile.universe_unlocked = 4
	s.save_profile.call()
	assert_eq(await s.sign_in(), PasswordRules.LOGGED_OUT)
	var cleo: String = server.make_account("cleo-device-000001", "Cleo_5")
	server.wallets[cleo] = 40
	assert_eq(s.progress_goes("Cleo_5"), "Anna_7", "LOG IN asks first: what was played here since goes")
	assert_eq(await s.log_in("Cleo_5", PW), "")
	assert_eq(int(server.wallets.get(cleo, 0)), 40, "nothing of Anna's went into Cleo's account")
	assert_eq(int(server.wallets.get(me, 0)), start, "nor into Anna's from Cleo")
	assert_eq(profile.survivor_gold, 40)
	assert_ne(profile.universe_unlocked, 4)


func test_log_out_and_log_in_again_makes_no_gold_from_a_fresh_players_start_gold() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	assert_eq(await s.sync_wallet(true), "")
	profile.survivor_gold = 0   # spent everything
	s.save_profile.call()
	assert_eq(await s.log_out(), "")
	var before := int(server.wallets.get(me, 0))
	assert_eq(before, 0)
	assert_eq(await s.log_in("Anna_7", PW), "")
	assert_eq(int(server.wallets.get(me, 0)), before, "the fresh player's start gold is never reported as earned")
	assert_eq(profile.survivor_gold, before, "the account's gold, as the server has it")


func test_after_delete_the_next_sign_in_is_a_new_unnamed_player() -> void:
	var s := await _anna()
	var me: String = s.backend.user_id()
	var st: Dictionary = await s.delete_account_start()
	assert_eq(str(st.text), "")
	assert_eq(await s.delete_account(str(st.confirm), PW), "")
	s.forget_player()
	assert_false(server.accounts.has(me), "deleted on the server")
	assert_eq(profile.username, "")
	assert_eq(await s.sign_in(), "")
	assert_ne(s.backend.user_id(), me, "a new account")
	assert_false(s.claimed())


func test_a_name_that_is_another_account_now_starts_fresh() -> void:
	# The final review's 7: the same account is known by its user id, never by its name (a name deleted and claimed
	# again is another account: nothing of this device's player merges into it).
	var s := await _anna()
	var me: String = s.backend.user_id()
	assert_eq(s.prefs.account_id, me, "the account's id is noted with its name")
	profile.universe_unlocked = 5
	s.save_profile.call()
	s.prefs.account_id = "an-old-deleted-account"   # as if the Anna this device knew was deleted, the name claimed anew
	s.prefs.save_to(s.prefs_path)
	assert_eq(await s.log_in("Anna_7", PW), "")
	assert_eq(s.backend.user_id(), me)
	assert_ne(profile.universe_unlocked, 5, "a fresh start: nothing merged")
	assert_eq(profile.survivor_gold, int(server.wallets.get(me, 0)), "the account's own gold")
	assert_eq(s.prefs.account_id, me)


func test_log_in_logs_the_other_device_out() -> void:
	var cleo := ProfileData.new()
	cleo.username = "Cleo_5"
	cleo.age_band = AgeBand.TEEN_PLUS
	cleo.updated_at = now
	var phone_root := ROOT + "phone/"
	DirAccess.make_dir_recursive_absolute(phone_root)
	server.make_account("phone-device-0001", "Cleo_5")
	JsonStore.write_atomic(phone_root + "device_id.json", JSON.stringify({"device_id": "phone-device-0001"}))
	var phone := _service(cleo, phone_root)
	assert_eq(await phone.sign_in(), "")
	_named("Tab_1")
	var s := _service()
	assert_eq(await s.log_in("Cleo_5", PW), "")
	assert_false(phone.backend.is_signed_in(), "one device at a time: the phone is logged out")
	phone._set_status(OnlineService.OFFLINE)
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT, "it says so, and never makes a new account")


func test_a_grown_ups_key_logs_in_from_a_logged_out_device_too() -> void:
	# The final review's 3: the key sign-in asks with the device's own asking account, so a logged-out device can use it.
	var cleo := ProfileData.new()
	var phone_root := ROOT + "phone/"
	DirAccess.make_dir_recursive_absolute(phone_root)
	var cleo_id: String = server.make_account("phone-device-0001", "Cleo_5")
	JsonStore.write_atomic(phone_root + "device_id.json", JSON.stringify({"device_id": "phone-device-0001"}))
	cleo.username = "Cleo_5"
	var phone := _service(cleo, phone_root)
	assert_eq(await phone.sign_in(), "")
	_named("Tab_1")
	var s := _service()
	assert_eq(await s.log_in("Cleo_5", PW), "")   # the phone is logged out
	var made: Dictionary = await s.make_account_key()
	var key := str(made.get("key", ""))
	assert_ne(key, "")
	phone._set_status(OnlineService.OFFLINE)
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT)
	assert_eq(await phone.sign_in_with_key("Cleo_5", key), "", "the key works from the logged-out phone")
	assert_eq(phone.backend.user_id(), cleo_id)
	assert_false(s.backend.is_signed_in(), "one device at a time with a key too: the tablet is logged out")


# --- Online work on its way, and late answers ---

func test_log_in_and_log_out_wait_while_online_work_is_on_its_way() -> void:
	var s := await _anna()
	s._f_syncing = true
	assert_eq(await s.log_out(), DeviceMoveRules.SWITCH_BUSY)
	assert_eq(await s.log_in("Anna_7", PW), DeviceMoveRules.SWITCH_BUSY)
	assert_eq(profile.username, "Anna_7", "nothing changed")
	s._f_syncing = false


func test_a_late_answer_of_the_last_session_never_lands_after_a_log_out() -> void:
	var s := await _anna()
	s.backend.answer_frames = {"read_storage": 6}
	var started := func() -> void: await s.profile_sync.sync()
	started.call()   # on its way...
	s.forget_player()   # ...when this device leaves the account
	await wait_process_frames(12)
	assert_eq(profile.username, "", "Anna's backup never came back into the fresh player")


# --- Every LOG OUT and LOG IN entry, never a grown-up's step ---

func test_play_online_home_has_the_account_card_with_log_out_and_password() -> void:
	var s := await _anna()
	var screen := PlayOnlineScreen.new()
	screen.service = s
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	box.add_child(screen)
	add_child_autofree(box)
	await wait_process_frames(10)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)
	assert_string_contains(_words(screen), "You are Anna_7")
	await _fits(screen, "PLAY ONLINE's home with the account card")
	await _press(screen, PasswordRules.PASSWORD)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_PASSWORD)
	await _press(screen, "BACK")
	await _press(screen, DeviceMoveRules.LOG_OUT)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_ACCOUNTS)
	assert_eq((screen.page as AccountsFlow).view, AccountsFlow.VIEW_CONFIRM)
	_no_gate(screen, "PLAY ONLINE's LOG OUT")


func test_the_main_menus_button_says_log_out_or_log_in_and_opens_no_gate() -> void:
	var s := await _anna()
	var b := AccountsOverlay.menu_button(s)
	add_child_autofree(b)
	await wait_process_frames(2)
	assert_eq(b.text, DeviceMoveRules.LOG_OUT, "Anna has an online name here")
	s.prefs.account_name = ""
	remove_child(b)
	add_child(b)
	await wait_process_frames(2)
	assert_eq(b.text, DeviceMoveRules.LOG_IN, "no online name here: LOG IN")
	var logo := TextureRect.new()   # the menu's logo: a panel as tall as SETTINGS hides it, and this button with it
	add_child_autofree(logo)
	var follows := AccountsOverlay.menu_button(s, logo)
	add_child_autofree(follows)
	await wait_process_frames(2)
	assert_eq(follows.visible, Profile.data.is_onboarded())
	logo.visible = false
	await wait_process_frames(1)
	assert_false(follows.visible, "never over a tall panel's top row")


func test_the_start_screens_log_in_opens_log_in_with_no_gate() -> void:
	var s := _service()
	var b := AccountsOverlay.start_log_in_button(s)
	add_child_autofree(b)
	assert_eq(b.text, DeviceMoveRules.LOG_IN)
	b.pressed.emit()
	await wait_process_frames(8)
	var host: Node = get_tree().current_scene if get_tree().current_scene != null else get_tree().root
	var overlays := host.find_children("*", "CanvasLayer", false, false).filter(func(n: Node) -> bool: return n is AccountsOverlay)
	assert_eq(overlays.size(), 1, "the overlay opens")
	if overlays.size() == 1:
		var o := overlays[0] as AccountsOverlay
		assert_eq(o.flow.view, AccountsFlow.VIEW_LOG_IN)
		_no_gate(o, "the start screen's LOG IN")
		o.free()


func test_settings_log_out_and_password_show_on_the_main_menu_only_and_the_row_still_fits() -> void:
	var row := AccountsOverlay.settings_buttons()
	add_child_autofree(row)
	assert_false((row.get_child(0) as Button).visible, "not here (a world or a test scene): its files are open")
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var settings := SettingsPanel.new()
	settings.saver = func() -> void: pass
	box.add_child(settings)
	add_child_autofree(box)
	await wait_process_frames(2)
	var log_out := settings.find_child("LogOut", true, false) as Button
	var password := settings.find_child("Password", true, false) as Button
	assert_not_null(log_out, "beside GROWN-UPS")
	assert_not_null(password)
	if log_out == null or password == null:
		return
	log_out.visible = true   # as on the main menu with an account
	password.visible = true
	await wait_process_frames(2)
	var size := box.get_combined_minimum_size()
	gut.p("the settings with LOG OUT and PASSWORD: %d x %d" % [size.x, size.y])
	assert_lte(size.x, 1280.0, "the settings' last row still fits (%d)" % size.x)
	assert_lte(size.y, 720.0)
