extends GutTest
## Owner #105 (2026-10-15 23:14; spec §5.13 "As built (owner #99, #105)"): "when starting playing create a password. so
## when logging in another device you can use password and username again to login, but if you login another device you
## should logout automatically from old device". Against the fake server (module 0.2.20's answers), in a folder of this
## test's own: the password right after the name (no LATER), an old account asked once (LATER), LOG IN with the name and
## the password (I HAVE AN ACCOUNT, a taken name's YES), the other device logged out (it never makes a new account),
## FORGOT PASSWORD, a grown-up's change with a key, a new device's wrong try told to the account, and DELETE taking this
## player off this device (owner #99, 23:06: "when i delete my account it is not deleting").

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
## The main menu's panel: below the logo (offset 130) with the panel's 28 px margins.
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)
const PW := FakeServer.FAKE_PASSWORD
const PHONE := "phone-device-0001"

var ROOT := "user://test_account_password_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var profile: ProfileData
var menus := 0


func before_each() -> void:
	ParentGate.reset_tries()
	_remove(ROOT)
	DirAccess.make_dir_recursive_absolute(ROOT)
	server = FakeServer.new()
	server.claims_make_password = false   # this test makes the passwords itself, as the game's pages do
	profile = ProfileData.new()
	menus = 0


func after_all() -> void:
	_remove(ROOT)


func _remove(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		for d in DirAccess.get_directories_at(path):
			_remove(path.path_join(d))
		for f in DirAccess.get_files_at(path):
			DirAccess.remove_absolute(path.path_join(f))
		DirAccess.remove_absolute(path)


## A device's service with its files in `root` (default ROOT, the tablet's), the stay-safe card seen (kept in its prefs).
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
	s.save_profile = _save if p == null else func() -> void: pass
	s.clock = func() -> int: return now
	s.move_card = false
	s.logged_out_card = false
	add_child_autofree(s)
	s.prefs.safe_card_seen = now   # after _ready (it reads the prefs file)
	s.prefs.save_to(s.prefs_path)
	return s


func _save() -> void:
	JsonStore.write_atomic(ROOT + "profile.json", profile.to_json())


func _named(name: String) -> void:
	profile.username = name
	profile.age_band = AgeBand.TEEN_PLUS
	profile.updated_at = now


## Cleo's phone: her account (with the fake's password), signed in from its own folder. Its profile is `cleo`.
func _phone(cleo: ProfileData) -> OnlineService:
	server.make_account(PHONE, "Cleo_5")
	cleo.username = "Cleo_5"
	cleo.age_band = AgeBand.TEEN_PLUS
	cleo.updated_at = now
	var root := ROOT + "phone/"
	DirAccess.make_dir_recursive_absolute(root)
	JsonStore.write_atomic(root + "device_id.json", JSON.stringify({"device_id": PHONE}))
	var phone := _service(cleo, root)
	assert_eq(await phone.sign_in(), "")
	return phone


func _screen(s: OnlineService) -> PlayOnlineScreen:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var screen := PlayOnlineScreen.new()
	screen.service = s
	panel.add_child(screen)
	await wait_process_frames(8)
	return screen


func _press(root: Node, prefix: String) -> void:
	var b: Button = null
	for x in root.find_children("*", "Button", true, false):
		if (x as Button).is_visible_in_tree() and (x as Button).text.begins_with(prefix):
			b = x
			break
	assert_not_null(b, "a %s button" % prefix)
	if b:
		b.pressed.emit()
	await wait_process_frames(8)


func _words(root: Node) -> String:
	var out := ""
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out += (l as Label).text + "\n"
	return out


func _fits(root: Control, what: String, room: Vector2 = PANEL_CONTENT) -> void:
	await wait_process_frames(2)
	var size := root.get_combined_minimum_size()
	gut.p("%s: %d x %d" % [what, size.x, size.y])   # the measurement for the notes
	assert_lte(size.y, room.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, room.x, "%s fits the width (%d)" % [what, size.x])
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and not (b is ReadAloud.ReadAloudSpeaker):
			assert_gte((b as Button).size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, (b as Button).text])


func _no_gate(root: Node, what: String) -> void:
	assert_eq(root.find_children("*", "HBoxContainer", true, false).filter(func(n: Node) -> bool: return n is GrownUpGate),
		[], what + ": never a grown-up's step")


## Types a new password twice on the page and presses MAKE IT / CHANGE IT.
func _type(page: PasswordPage, text: String, again: String, old: String = "") -> void:
	if page.old_field != null:
		page.old_field.text = old
	page.new_field.text = text
	page.again_field.text = again
	page.ok_button.pressed.emit()
	await wait_process_frames(8)


## Types the name and the password on a LOG IN page and presses LOG IN.
func _log_in(p: LogInPage, username: String, password: String) -> void:
	p.name_edit.text = username
	p.name_edit.text_changed.emit(username)
	p.password.text = password
	p.password.edit.text_changed.emit(password)
	assert_false(p.log_in_button.disabled, "LOG IN once both are typed")
	p.log_in_button.pressed.emit()
	await wait_process_frames(12)


# --- Starting: the name, then the password ---

func test_a_new_name_goes_straight_on_to_make_a_password_with_no_later() -> void:
	_named("Pip_4")
	var s := _service()
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)
	await _press(screen, "OK")
	assert_eq(screen.view, PlayOnlineScreen.VIEW_PASSWORD, "right after the name")
	var page := screen.page as PasswordPage
	assert_not_null(page)
	if page == null:
		return
	assert_eq(page.mode, PasswordPage.Mode.MAKE)
	assert_false(page.back_button.visible, "no LATER: the first password is made now")
	assert_string_contains(_words(screen), PasswordRules.NEVER_TELL)
	assert_string_contains(_words(screen), PasswordRules.IDEA)
	assert_true(page.new_field.edit.secret, "typed in secret")
	page.new_field.toggle()
	assert_false(page.new_field.edit.secret, "SHOW lets the child check it")
	assert_eq(page.new_field.show_button.text, PasswordRules.HIDE)
	await _fits(screen, "making the password")
	var me: String = s.backend.user_id()
	await _type(page, "willow3comet", "willow3cornet")
	assert_eq(page.message.text, PasswordRules.message("mismatch"))
	await _type(page, "123456", "123456")
	assert_eq(page.message.text, PasswordRules.message("too_common"))
	await _type(page, "xqwertyx", "xqwertyx")
	assert_eq(page.message.text, PasswordRules.message("straight_run"))
	await _type(page, "moon7tiger", "moon7tiger")
	assert_eq(page.message.text, PasswordRules.message("too_common"), "the example the game shows is never usable")
	await _type(page, "pip_4_2024", "pip_4_2024")
	assert_eq(page.message.text, PasswordRules.message("is_name"))
	await _type(page, "pip", "pip")
	assert_eq(page.message.text, PasswordRules.message("too_short"))
	assert_false(server.passwords.has(me), "nothing weak reached the server")
	await _type(page, "willow3comet", "willow3comet")
	assert_eq(server.passwords.get(me, ""), "willow3comet")
	assert_eq(s.has_password, 1)
	assert_string_contains(_words(screen), PasswordRules.SAVED)
	await _press(screen, "OK")
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)


func test_the_server_refuses_a_weak_password_too() -> void:
	_named("Pip_4")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.claim_username("Pip_4"), "")
	var r: Dictionary = await s.backend.call_rpc("password", {"action": "set", "password": "123456"})
	assert_eq(str(r.get("error", "")), "too_common", "not only the game's page checks")


func test_an_account_without_a_password_is_asked_once_with_later() -> void:
	var id := DeviceId.generate()
	JsonStore.write_atomic(ROOT + "device_id.json", JSON.stringify({"device_id": id}))
	server.make_account(id, "Ola_6", AgeBand.TEEN_PLUS, OnlineRules.CONSENT_NONE, true, "")   # from before #105
	_named("Ola_6")
	var s := _service()
	var screen := await _screen(s)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_PASSWORD, "asked")
	var page := screen.page as PasswordPage
	assert_not_null(page)
	if page == null:
		return
	assert_true(page.asked)
	assert_string_contains(_words(screen), PasswordRules.MAKE_WHY)
	assert_true(page.back_button.visible, "LATER")
	assert_eq(page.back_button.text, PasswordRules.LATER)
	await _fits(screen, "asked once for a password")
	await _press(screen, PasswordRules.LATER)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)
	assert_gt(s.prefs.password_asked, 0)
	var again := await _screen(s)
	assert_eq(again.view, OnlineRules.SCREEN_HOME, "asked once only")
	await _press(again, PasswordRules.PASSWORD)   # the account card: make it later
	assert_eq(again.view, PlayOnlineScreen.VIEW_PASSWORD)
	assert_eq((again.page as PasswordPage).mode, PasswordPage.Mode.MAKE)
	await _type(again.page as PasswordPage, "maple8otter", "maple8otter")
	assert_eq(server.passwords.get(s.backend.user_id(), ""), "maple8otter")


# --- LOG IN with the name and the password ---

func test_i_have_an_account_logs_in_here_and_a_wrong_password_says_so() -> void:
	var phone := await _phone(ProfileData.new())
	var cleo_id: String = phone.backend.user_id()
	_named("Cleo")   # this tablet's first-launch name
	var s := _service()
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)
	await _press(screen, "I HAVE AN ACCOUNT")
	assert_eq(screen.view, PlayOnlineScreen.VIEW_LOG_IN)
	_no_gate(screen, "LOG IN")
	var p := screen.page as LogInPage
	assert_string_contains(_words(screen), PasswordRules.LOG_IN_WORDS)
	assert_eq(p.message.text, PasswordRules.ONE_DEVICE, "said before it happens")
	await _fits(screen, "LOG IN from PLAY ONLINE")
	await _press(screen, PasswordRules.FORGOT)
	assert_eq(p.message.text, PasswordRules.FORGOT_WORDS, "FORGOT PASSWORD? says what to do")
	await _log_in(p, "Cleo_5", "not-her-password-3")
	assert_eq(p.message.text, PasswordRules.WRONG)
	assert_ne(s.backend.user_id(), cleo_id, "nothing changed")
	await _log_in(p, "Nobody_9", PW)
	assert_eq(p.message.text, PasswordRules.WRONG, "the same words for a name that is nobody's")
	await _log_in(p, "cleo_5", PW)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)
	assert_eq(s.backend.user_id(), cleo_id, "this tablet plays as Cleo's account")
	assert_eq(profile.username, "Cleo_5", "with her name")
	assert_false(phone.backend.is_signed_in(), "one device at a time: the phone is logged out")


func test_a_taken_names_yes_opens_log_in_with_the_name_typed() -> void:
	var phone := await _phone(ProfileData.new())
	var cleo_id: String = phone.backend.user_id()
	_named("Cleo_5")
	var s := _service()
	var screen := await _screen(s)
	await _press(screen, "OK")
	assert_true((screen.page as UsernameClaim).taken_box.visible, "a taken name asks")
	await _press(screen, DeviceMoveRules.YES_ME)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_LOG_IN, "the move by code is off: LOG IN")
	var p := screen.page as LogInPage
	assert_eq(p.name_edit.text, "Cleo_5")
	await _log_in(p, "Cleo_5", PW)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)
	assert_eq(s.backend.user_id(), cleo_id)


# --- The other device is logged out ---

func test_the_old_device_is_logged_out_and_never_makes_a_new_account() -> void:
	var cleo := ProfileData.new()
	var phone := await _phone(cleo)
	var cleo_id: String = phone.backend.user_id()
	assert_eq(phone.prefs.account_name, "Cleo_5", "kept with this player")
	_named("Cleo")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.log_in("Cleo_5", PW), "")
	assert_eq(s.backend.user_id(), cleo_id)
	assert_false(phone.backend.is_signed_in())
	watch_signals(phone)
	var accounts: int = server.accounts.size()
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT, "it says so")
	assert_true(phone.logged_out)
	assert_signal_emitted(phone, "logged_out_elsewhere")
	assert_eq(server.accounts.size(), accounts, "and never makes a new account")
	var calls: int = server.calls.size()
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT)
	assert_eq(server.calls.size(), calls, "it does not even ask again until LOG IN")


func test_play_online_on_a_logged_out_device_logs_in_again_and_keeps_what_was_played_here() -> void:
	var cleo := ProfileData.new()
	var phone := await _phone(cleo)
	var cleo_id: String = phone.backend.user_id()
	_named("Cleo")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.log_in("Cleo_5", PW), "")
	cleo.universe_unlocked = 8   # played on the phone meanwhile, offline
	var screen := await _screen(phone)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_LOG_IN, "LOG IN to play here")
	assert_string_contains(_words(screen), PasswordRules.LOGGED_OUT)
	var p := screen.page as LogInPage
	assert_eq(p.name_edit.text, "Cleo_5", "her name typed already")
	await _fits(screen, "LOG IN on a logged-out device")
	await _log_in(p, "Cleo_5", PW)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)
	assert_eq(phone.backend.user_id(), cleo_id)
	assert_false(phone.logged_out)
	assert_eq(cleo.universe_unlocked, 8, "what was played here stays")
	assert_false(s.backend.is_signed_in(), "now the tablet is the one logged out")


func test_the_logged_out_card_says_it_over_every_scene_and_later_hides_it() -> void:
	var phone := await _phone(ProfileData.new())
	phone.logged_out_card = true
	_named("Cleo")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.log_in("Cleo_5", PW), "")
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT)
	await wait_process_frames(4)
	var layer := phone.find_child("LoggedOutLayer", false, false) as CanvasLayer
	assert_not_null(layer, "the card's layer")
	if layer == null:
		return
	assert_true(layer.visible)
	var card := layer.get_child(0) as LoggedOutCard
	assert_eq(card.text_label.text, PasswordRules.LOGGED_OUT)
	assert_true(card.saved_label.visible, "what was played here is kept")
	assert_eq(card.saved_label.text, PasswordRules.LOGGED_OUT_SAVED % "Cleo_5", "it names the account")
	assert_false(card.log_in_button.visible, "not on the main menu (a test scene, as a world): its files are open")
	assert_false(card.new_player_button.visible)
	assert_true(card.menu_label.visible, "it says where LOG IN is")
	await wait_process_frames(2)
	var in_world := card.get_combined_minimum_size()
	gut.p("the logged-out card in a world: %d x %d" % [in_world.x, in_world.y])
	assert_lte(in_world.y, 300.0, "a card at the top, never over the whole game")
	card.on_menu = func() -> bool: return true   # the main menu
	await wait_process_frames(2)
	assert_true(card.log_in_button.visible)
	assert_true(card.new_player_button.visible)
	assert_false(card.menu_label.visible)
	var size := card.get_combined_minimum_size()
	gut.p("the logged-out card: %d x %d" % [size.x, size.y])
	assert_lte(size.x, 1280.0 - 32)
	assert_lte(size.y, 300.0, "a card at the top, never over the whole game")
	card.later_button.pressed.emit()
	assert_false(layer.visible, "LATER: offline play goes on")


func test_the_logged_out_cards_new_player_asks_first() -> void:
	var phone := await _phone(ProfileData.new())
	phone.logged_out_card = true
	_named("Cleo")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.log_in("Cleo_5", PW), "")
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT)
	await wait_process_frames(4)
	var layer := phone.find_child("LoggedOutLayer", false, false) as CanvasLayer
	assert_not_null(layer)
	if layer == null:
		return
	var card := layer.get_child(0) as LoggedOutCard
	card.on_menu = func() -> bool: return true
	await wait_process_frames(2)
	card.new_player_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(card.asking, "asked first")
	assert_eq(card.text_label.text, DeviceMoveRules.NEW_PLAYER_ASK)
	assert_eq(card.new_player_button.text, DeviceMoveRules.YES)
	assert_eq(card.later_button.text, DeviceMoveRules.NO)
	assert_false(card.log_in_button.visible)
	var size := card.get_combined_minimum_size()
	gut.p("the logged-out card's question: %d x %d" % [size.x, size.y])
	assert_lte(size.y, 300.0)
	card.later_button.pressed.emit()   # NO
	await wait_process_frames(2)
	assert_false(card.asking)
	assert_eq(card.text_label.text, PasswordRules.LOGGED_OUT, "NO: the card as it was")
	assert_true(layer.visible)
	assert_eq(phone.prefs.account_name, "Cleo_5", "nothing forgotten")
	card.new_player_button.pressed.emit()
	await wait_process_frames(2)
	card.on_menu = func() -> bool: return false   # a world opened meanwhile: the question ends
	await wait_process_frames(2)
	assert_false(card.asking)
	assert_false(card.new_player_button.visible)
	card.on_menu = func() -> bool: return true
	await wait_process_frames(2)
	var scenes: Array[String] = []
	var change := Game.change_scene
	Game.change_scene = func(path: String) -> void: scenes.append(path)
	card.new_player_button.pressed.emit()
	card.new_player_button.pressed.emit()   # YES
	Game.change_scene = change
	assert_eq(scenes, [Game.MENU_SCENE] as Array[String], "the start screen")
	assert_eq(phone.prefs.account_name, "", "a new player on this device")
	assert_eq(phone.profile.username, "")


func test_an_old_profile_with_a_claimed_name_logged_out_elsewhere_never_makes_a_new_account() -> void:
	# D (the third review's N3): a profile from before 8f4fcde6 kept no account name in its prefs, only its username.
	var cleo := ProfileData.new()
	var phone := await _phone(cleo)
	phone.prefs.account_name = ""   # as an old build left it
	phone.prefs.save_to(phone.prefs_path)
	_named("Cleo")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.log_in("Cleo_5", PW), "")   # the phone is logged out
	phone.sign_out()
	phone._set_status(OnlineService.OFFLINE)
	var accounts: int = server.accounts.size()
	assert_eq(await phone.sign_in(), PasswordRules.LOGGED_OUT, "the logged-out words, not a fresh account")
	assert_eq(server.accounts.size(), accounts, "no new account made")
	assert_eq(phone.prefs.account_name, "Cleo_5", "LOG IN prefills the name from the profile")


func test_log_in_remakes_the_asking_id_once_when_its_account_is_gone() -> void:
	# C (the third review's N2): the device's own asking account was cleaned up (13 months): LOG IN makes a fresh one.
	var phone := await _phone(ProfileData.new())
	var cleo_id: String = phone.backend.user_id()
	_named("Cleo")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	s.prepare_log_in()
	await wait_process_frames(4)
	var before := FileAccess.get_file_as_string(ROOT + "login_device.json")
	server.sign_in_fails = 1   # the asking id's sign-in fails once
	assert_eq(await s.log_in("Cleo_5", PW), "", "LOG IN still works")
	assert_eq(s.backend.user_id(), cleo_id)
	assert_ne(FileAccess.get_file_as_string(ROOT + "login_device.json"), before, "a fresh asking id was made")


func test_a_device_whose_empty_account_went_starts_online_anew() -> void:
	var gone := DeviceId.generate()   # never named: the retention clean-up deleted it
	JsonStore.write_atomic(ROOT + "device_id.json", JSON.stringify({"device_id": gone}))
	_named("Pip_4")
	var s := _service()
	var accounts: int = server.accounts.size()
	assert_eq(await s.sign_in(), "")
	assert_eq(s.status, OnlineService.ONLINE)
	assert_false(s.logged_out)
	assert_eq(server.accounts.size(), accounts + 1, "a fresh account, as a new device")
	assert_ne(OnlineService._pw_read_id(s.device_id_path), gone, "with a new id")


# --- CHANGE it: the old one and a new one; FORGOT PASSWORD: a grown-up changes it ---

func test_the_account_card_changes_the_password_with_the_old_one() -> void:
	var cleo := ProfileData.new()
	var phone := await _phone(cleo)
	var me: String = phone.backend.user_id()
	var screen := await _screen(phone)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)
	await _press(screen, PasswordRules.PASSWORD)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_PASSWORD)
	var page := screen.page as PasswordPage
	assert_eq(page.mode, PasswordPage.Mode.CHANGE)
	assert_true(page.back_button.visible, "BACK")
	await _fits(screen, "changing the password")
	await _type(page, "cedar6falcon", "cedar6falcon", "not-the-old-one-1")
	assert_eq(page.message.text, PasswordRules.WRONG_OWN)
	assert_eq(server.passwords.get(me, ""), PW, "nothing changed")
	await _type(page, "cedar6falcon", "cedar6falcon", PW)
	assert_eq(server.passwords.get(me, ""), "cedar6falcon")
	assert_string_contains(_words(screen), PasswordRules.CHANGED)
	await _press(screen, "OK")
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)


func test_grown_ups_change_the_password_with_a_key_when_it_is_forgotten() -> void:
	var cleo := ProfileData.new()
	var phone := await _phone(cleo)
	var me: String = phone.backend.user_id()
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	var area := GrownUpsPanel.new()
	area.service = phone
	area.play_minutes = func() -> int: return 12
	area.in_online_world = func() -> bool: return false
	panel.add_child(area)
	await wait_process_frames(4)
	area.show_page(GrownUpsPanel.PAGE_ONLINE)
	await wait_process_frames(4)
	await _press(area, "CHANGE PASSWORD")
	var pages := area.find_children("*", "VBoxContainer", true, false).filter(func(n: Node) -> bool: return n is PasswordPage)
	assert_eq(pages.size(), 1, "the grown-up's page")
	if pages.size() != 1:
		return
	var page := pages[0] as PasswordPage
	assert_eq(page.mode, PasswordPage.Mode.GROWN_UP)
	assert_string_contains(_words(area), PasswordRules.GROWN_UP_KEY)
	await _fits(area, "the grown-up's CHANGE PASSWORD")
	await _type(page, "cedar6falcon", "cedar6falcon", "not-the-old-one-1")
	assert_eq(page.message.text, PasswordRules.WRONG_OWN, "a wrong old one")
	await _type(page, "cedar6falcon", "cedar6falcon", "")
	assert_eq(server.passwords.get(me, ""), "cedar6falcon", "a key made on this device proved it")
	assert_ne(str(server.keys.get(me, "")), "", "the key")
	assert_string_contains(_words(area), PasswordRules.CHANGED)
	_named("Cleo")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq((await s.log_in_with_password("Cleo_5", PW)).text, PasswordRules.WRONG, "the old one stopped")
	assert_eq((await s.log_in_with_password("Cleo_5", "cedar6falcon")).text, "")


# --- A new device's wrong try is told to the account ---

func test_a_wrong_try_from_a_new_device_is_told_at_most_once_an_hour() -> void:
	var phone := await _phone(ProfileData.new())
	await wait_process_frames(2)
	watch_signals(phone)
	_named("Mallory_2")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq((await s.log_in_with_password("Cleo_5", "guess-one-1")).text, PasswordRules.WRONG)
	await wait_process_frames(8)
	assert_signal_emitted_with_parameters(phone, "tried_note", [PasswordRules.TRIED])
	assert_eq((await s.log_in_with_password("Cleo_5", "guess-two-2")).text, PasswordRules.WRONG)
	await wait_process_frames(8)
	assert_signal_emit_count(phone, "tried_note", 1, "once an hour at most")
	phone.sign_out()
	phone._set_status(OnlineService.OFFLINE)
	server.clock_ms += 3_600_001
	assert_eq((await s.log_in_with_password("Cleo_5", "guess-three-3")).text, PasswordRules.WRONG)
	assert_eq(await phone.sign_in(), "")
	await wait_process_frames(4)
	assert_signal_emit_count(phone, "tried_note", 2, "told at the next sign-in when it was away")
	phone.sign_out()
	phone._set_status(OnlineService.OFFLINE)
	assert_eq(await phone.sign_in(), "")
	await wait_process_frames(4)
	assert_signal_emit_count(phone, "tried_note", 2, "never twice for the same try")
	assert_true(phone.backend.is_signed_in(), "a wrong try never logs anyone out")


# --- DELETE deletes, and this player goes from this device ---

func _delete_page(s: OnlineService, forget: Callable) -> DeleteAccountPage:
	var box := PanelContainer.new()
	box.theme = UiKit.theme()
	var page := DeleteAccountPage.new()
	page.service = s
	page.in_online_world = func() -> bool: return false
	page.forget_player = forget
	page.open_menu = func() -> void: menus += 1
	box.add_child(page)
	add_child_autofree(box)
	await wait_process_frames(10)
	return page


func _hold(page: DeleteAccountPage) -> void:
	page.hold.set_process(false)
	page.hold.button_down.emit()
	page.hold.step(page.hold.hold_seconds + 0.1)
	await wait_process_frames(10)


func test_delete_needs_the_password_and_takes_this_player_off_this_device() -> void:
	_named("Anna_7")
	profile.universe_unlocked = 5
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.claim_username("Anna_7"), "")
	assert_eq(await s.make_password("willow3comet", "willow3comet"), "")
	var me: String = s.backend.user_id()
	profile.invite.code = "ANNA-7777"   # why it signed in again by itself before (owner #99, 23:06)
	_save()
	DirAccess.make_dir_recursive_absolute(ROOT + "worlds/w1")
	JsonStore.write_atomic(ROOT + "worlds/w1/world.json", "{}")
	var page := await _delete_page(s, s.forget_player)   # the service's own: the account files and the player go
	assert_not_null(page.password, "the password, once the account has one")
	await _fits(page, "DELETE with the password")
	await _hold(page)
	assert_eq(page.message.text, PasswordRules.DELETE_PASSWORD, "asked before the server is")
	page.password.text = "willow3comt"
	await _hold(page)
	assert_string_contains(page.message.text, PasswordRules.WRONG_OWN)
	assert_string_contains(page.message.text, "Nothing was deleted.")
	assert_true(server.accounts.has(me))
	page.password.text = "willow3comet"
	await _hold(page)
	assert_false(server.accounts.has(me), "deleted on the server")
	assert_string_contains(_words(page), DeleteAccountPage.DONE_WORDS)
	assert_eq(profile.username, "", "a new player: the first-launch screens next")
	assert_eq(profile.universe_unlocked, ProfileData.new().universe_unlocked, "her progress went from this device")
	assert_true(profile.invite.is_empty(), "nothing left to sign in with by itself")
	assert_eq(OnlinePrefs.load_from(ROOT + "online.json").safe_card_seen, 0, "no autostart")
	assert_false(FileAccess.file_exists(ROOT + "device_id.json"))
	assert_true(FileAccess.file_exists(ROOT + "worlds/w1/world.json"), "worlds on this device stay")
	await _press(page, "OK")
	assert_eq(menus, 1, "the main menu again, for a new player")
	var accounts: int = server.accounts.size()
	assert_eq(await s.sign_in(), "", "PLAY ONLINE later is a new player's")
	assert_false(s.claimed(), "never the same name made again from what was left")
	assert_ne(str(s.account.get("username", "")), "Anna_7")
	assert_eq(server.accounts.size(), accounts + 1)


func test_delete_offline_says_plainly_that_nothing_was_deleted() -> void:
	_named("Anna_7")
	var s := _service()
	assert_eq(await s.sign_in(), "")
	assert_eq(await s.claim_username("Anna_7"), "")
	s.sign_out()
	s._set_status(OnlineService.OFFLINE)
	server.down = true
	var forgot := []
	var page := await _delete_page(s, func() -> void: forgot.append(true))
	assert_string_contains(_words(page), DeleteAccountPage.CANT_NOW)
	assert_null(page.hold, "nothing to hold")
	assert_eq(forgot, [], "this player stays")
	assert_eq(profile.username, "Anna_7")


func test_delete_without_an_account_here_says_there_is_nothing_to_delete() -> void:
	_named("Pip_4")
	var s := _service()
	var page := await _delete_page(s, func() -> void: pass)
	assert_string_contains(_words(page), DeleteAccountPage.NO_ACCOUNT)
