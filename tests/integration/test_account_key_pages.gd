extends GutTest
## Owner #67 (spec §5.13, §17.1): the pages of the account on every device, against the fake server. In the grown-up
## area (behind the parent gate) ONLINE PLAY -> OTHER DEVICES: MAKE A KEY shows the child's name and the key big, a
## key made before is said (a new one stops it), and SIGN OUT OTHER DEVICES is a hold. In PLAY ONLINE the name claim
## offers I HAVE AN ACCOUNT: the parent gate, then the name and the key sign this device in, and the account's home
## shows. Every page fits the menu's panel at 1280 x 720 with big buttons. Owner #99: I HAVE AN ACCOUNT opens LOG IN (the
## name), then MOVE YOUR GAME HERE (the code from the other device); its USE A KEY is the way to the key here.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
## The main menu's panel: below the logo (offset 130) with the panel's 28 px margins.
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)

var DIR := "user://test_account_key_pages_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000


func before_each() -> void:
	ParentGate.reset_tries()
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
	s.device_id_path = DIR + device + "_device_id.json"
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = band
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.wallet_path = DIR + "wallet_" + device + ".json"
	s.clock = func() -> int: return now
	add_child_autofree(s)
	s.prefs.safe_card_seen = now   # after _ready (it loads the prefs file)
	return s


func _claimed(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS) -> OnlineService:
	server.make_account(device, username, band, OnlineRules.CONSENT_VERIFIED if band == AgeBand.UNDER_13 else OnlineRules.CONSENT_NONE)
	var s := _service(device, username, band)
	assert_eq(await s.sign_in(), "")
	return s


func _holder() -> PanelContainer:
	var holder := Control.new()
	holder.theme = UiKit.theme()
	holder.size = Vector2(1280, 720)
	add_child_autofree(holder)
	var panel := PanelContainer.new()
	holder.add_child(panel)
	return panel


func _area(s: OnlineService) -> GrownUpsPanel:
	var area := GrownUpsPanel.new()
	area.service = s
	area.play_minutes = func() -> int: return 5
	area.in_online_world = func() -> bool: return false
	_holder().add_child(area)
	await wait_process_frames(3)
	return area


func _screen(s: OnlineService) -> PlayOnlineScreen:
	var screen := PlayOnlineScreen.new()
	screen.service = s
	_holder().add_child(screen)
	await wait_process_frames(3)
	return screen


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
	await wait_process_frames(4)


func _words(root: Node) -> String:
	var out := ""
	for l in root.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out += (l as Label).text + "\n"
	return out


func _check_fits(root: Control, what: String) -> void:
	await wait_process_frames(2)
	var size := root.get_combined_minimum_size()
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	for b in _buttons(root):
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, b.text])
		assert_gte(b.size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, b.text])


## Owner #99, #105: I HAVE AN ACCOUNT opens LOG IN (the name and the password); its USE A KEY is a grown-up's step to the
## key page (the name typed before comes along).
func _to_key_gate(screen: PlayOnlineScreen, username: String) -> void:
	await _press(screen, "I HAVE AN ACCOUNT")
	assert_eq(screen.view, PlayOnlineScreen.VIEW_LOG_IN, "the name first")
	var log_in := screen.page as LogInPage
	if log_in == null:
		return
	log_in.name_edit.text = username
	log_in.name_edit.text_changed.emit(username)
	await _press(screen, DeviceMoveRules.USE_KEY)   # owner #105: the name and a password, or a grown-up's key


func _pass_gate(screen: PlayOnlineScreen) -> void:
	var gate := screen.page as GrownUpGate
	assert_not_null(gate, "the parent gate first")
	if gate == null:
		return
	for key in str(gate.question.answer):
		gate.press(key)
	gate.press("OK")
	await wait_process_frames(3)


# --- The grown-up area: OTHER DEVICES ---

func test_online_play_leads_to_other_devices_which_explains_and_fits() -> void:
	for band: StringName in [AgeBand.UNDER_13, AgeBand.TEEN_PLUS]:
		var s := await _claimed("dev-" + band, "Kid" if band == AgeBand.UNDER_13 else "Teen", band)
		var area := await _area(s)
		await _check_fits(area, "online play with OTHER DEVICES (%s)" % band)
		await _press(area, "OTHER DEVICES")
		assert_eq(area.page, GrownUpsPanel.PAGE_KEY)
		var words := _words(area)
		for said: String in ["another phone", "I HAVE AN ACCOUNT", "key"]:
			assert_string_contains(words, said)
		await _check_fits(area, "the other devices page (%s)" % band)
		await _press(area, "BACK")
		assert_eq(area.page, GrownUpsPanel.PAGE_ONLINE)


func test_make_a_key_shows_the_name_and_the_key_big() -> void:
	var s := await _claimed("dev-a", "Sasa_7", AgeBand.UNDER_13)
	var area := await _area(s)
	await _press(area, "OTHER DEVICES")
	await _press(area, "MAKE A KEY")
	var id: String = s.backend.user_id()
	var key: String = server.keys[id]
	var words := _words(area)
	assert_string_contains(words, "Sasa_7")
	assert_string_contains(words, key.substr(0, 4) + "-" + key.substr(4))
	assert_string_contains(words, "password")
	await _check_fits(area, "the page with a key")
	assert_not_null(_button(area, "MAKE A NEW KEY"), "the next one replaces it")


func test_a_key_made_before_is_said_and_a_new_one_stops_it() -> void:
	var s := await _claimed("dev-a", "Sasa_7")
	await s.make_account_key()
	var area := await _area(s)
	await _press(area, "OTHER DEVICES")
	var words := _words(area)
	assert_string_contains(words, "A key was made")
	assert_string_contains(words, "stops")
	var old: String = server.keys[s.backend.user_id()]
	await _press(area, "MAKE A NEW KEY")
	assert_ne(server.keys[s.backend.user_id()], old)


func test_signing_other_devices_out_is_a_hold() -> void:
	var s := await _claimed("dev-a", "Sasa_7")
	var id: String = s.backend.user_id()
	server.link_device(id, "lost-phone-0001")
	var area := await _area(s)
	await _press(area, "OTHER DEVICES")
	var holds := area.find_children("*", "HoldButton", true, false)
	assert_eq(holds.size(), 1, "one hold-to-confirm button")
	var hold := holds[0] as HoldButton
	hold.set_process(false)
	hold.button_down.emit()
	hold.step(0.5)
	hold.button_up.emit()
	await wait_process_frames(3)
	assert_true(server.linked.has("lost-phone-0001"), "a tap or a short hold does nothing")
	hold.button_down.emit()
	hold.step(hold.hold_seconds)
	await wait_process_frames(8)
	assert_false(server.linked.has("lost-phone-0001"))
	assert_eq(s.status, OnlineService.ONLINE, "this device signed in again")
	assert_string_contains(_words(area), "signed out")


func test_no_other_devices_before_a_name_is_claimed() -> void:
	var s := _service("dev-new", "Pip")
	assert_eq(await s.sign_in(), "")
	var area := await _area(s)
	assert_null(_button(area, "OTHER DEVICES"))


# --- PLAY ONLINE: I HAVE AN ACCOUNT ---

func _child_with_key() -> String:
	var phone := await _claimed("phone-1", "Sasa_7", AgeBand.UNDER_13)
	var progress := ProfileData.new()
	progress.username = "Sasa_7"
	progress.age_band = AgeBand.UNDER_13
	progress.universe_unlocked = 4
	phone.profile = progress
	await phone.profile_sync.sync()
	return str((await phone.make_account_key()).key)


func test_the_name_claim_offers_i_have_an_account_behind_the_gate_and_signs_in() -> void:
	var key := await _child_with_key()
	var s := _service("browser-1", "Hopper", AgeBand.UNDER_13)
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)
	await _check_fits(screen, "the name claim with I HAVE AN ACCOUNT")
	await _to_key_gate(screen, "sasa_7")
	assert_eq(screen.view, PlayOnlineScreen.VIEW_GATE, "a grown-up's step")
	await _pass_gate(screen)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_KEY)
	assert_true(screen.page is KeySignInPage)
	await _check_fits(screen, "the sign-in-with-a-key page")
	var page := screen.page as KeySignInPage
	assert_eq(page.name_edit.text, "sasa_7", "the name typed before")
	page.key_edit.text = key.to_lower()
	await _press(screen, "SIGN IN")
	await wait_process_frames(6)
	assert_true(s.claimed())
	assert_eq(s.profile.username, "Sasa_7")
	assert_eq(s.profile.universe_unlocked, 4, "the account's progress came")
	assert_eq(screen.view, OnlineRules.screen(s.account, true, false), "the account's own page next")


func test_the_keys_sign_in_asks_first_when_this_players_progress_would_go() -> void:
	# The final review's 2: a guest with progress is asked (GUEST_GOES) before a key brings another account here.
	var key := await _child_with_key()
	var s := _service("browser-4", "Hopper")
	s.profile.universe_unlocked = 3   # played here, never online
	var screen := await _screen(s)
	await _to_key_gate(screen, "Sasa_7")
	await _pass_gate(screen)
	var page := screen.page as KeySignInPage
	page.key_edit.text = key
	page.key_edit.text_changed.emit(key)
	await _press(screen, "SIGN IN")
	assert_eq(page.asking, "Hopper", "asked first")
	assert_string_contains(_words(screen), DeviceMoveRules.GUEST_GOES % ["Hopper", "Sasa_7"])
	assert_false(s.claimed(), "nothing happened yet")
	await _check_fits(screen, "the key page's question")
	await _press(screen, DeviceMoveRules.NO)
	assert_eq(page.asking, "", "NO: the page again")
	assert_eq(screen.view, PlayOnlineScreen.VIEW_KEY)
	assert_eq(s.profile.universe_unlocked, 3)
	await _press(screen, "SIGN IN")
	await _press(screen, DeviceMoveRules.YES)
	await wait_process_frames(6)
	assert_true(s.claimed())
	assert_eq(s.profile.username, "Sasa_7")
	assert_eq(s.profile.universe_unlocked, 4, "the account's progress, nothing of Hopper's")


func test_a_wrong_key_says_so_on_the_page() -> void:
	await _child_with_key()
	var s := _service("browser-2", "Hopper")
	var screen := await _screen(s)
	await _to_key_gate(screen, "Sasa_7")
	await _pass_gate(screen)
	var page := screen.page as KeySignInPage
	page.key_edit.text = "0000-0000"
	await _press(screen, "SIGN IN")
	assert_eq(screen.view, PlayOnlineScreen.VIEW_KEY, "stays")
	assert_string_contains(_words(screen), OnlineRules.message("wrong_key"))
	assert_false(s.claimed())
	await _press(screen, "BACK")
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)


func test_sign_in_waits_for_both_fields() -> void:
	var s := _service("browser-3", "Hopper")
	var screen := await _screen(s)
	await _to_key_gate(screen, "Sasa_7")
	await _pass_gate(screen)
	var page := screen.page as KeySignInPage
	page.name_edit.text = ""
	page.name_edit.text_changed.emit("")
	assert_true(page.sign_in_button.disabled)
	page.name_edit.text = "Sasa_7"
	page.name_edit.text_changed.emit(page.name_edit.text)
	assert_true(page.sign_in_button.disabled)
	page.key_edit.text = "7K3M-Q9TD"
	page.key_edit.text_changed.emit(page.key_edit.text)
	assert_false(page.sign_in_button.disabled)
