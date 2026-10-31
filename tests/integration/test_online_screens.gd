extends GutTest
## The online screens (M4 Wave 1, Agent C; spec §17.1-17.3) against the fake server: PLAY ONLINE's
## pages in order (stay-safe card, username claim, home), the grown-up's consent flow behind the
## parent gate, the friends page, the invite toast and the pause menu's INVITE page. Every page fits
## the menu's panel on the 1280 x 720 screen and every button is big enough for a child's finger.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."
## The main menu's panel: below the logo (offset 130) with the panel's 28 px margins.
const PANEL_CONTENT := Vector2(1280 - 56, 720 - 130 - 56)

var DIR := "user://test_online_screens_%d/" % OS.get_process_id()
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
	add_child_autofree(s)
	return s


## An under-13 player who has seen the card and claimed a name (not findable until consent).
func _young_service(device: String, username: String) -> OnlineService:
	var s := _service(device, username, AgeBand.UNDER_13)
	s.prefs.safe_card_seen = now
	await s.sign_in()
	await s.claim_username(username)
	return s


func _ready_service(device: String, username: String) -> OnlineService:
	server.make_account(device, username)
	var s := _service(device, username)
	s.prefs.safe_card_seen = now
	await s.sign_in()
	return s


## The screen inside a themed panel, like the main menu shows it.
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
	await wait_process_frames(3)


## Every page fits the panel and has big buttons.
func _check_page(screen: Control, what: String) -> void:
	await wait_process_frames(2)
	var size := screen.get_combined_minimum_size()
	assert_lte(size.y, PANEL_CONTENT.y, "%s fits the height (%d)" % [what, size.y])
	assert_lte(size.x, PANEL_CONTENT.x, "%s fits the width (%d)" % [what, size.x])
	for b in _buttons(screen):
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH, "%s: %s is wide enough" % [what, b.text])
		assert_gte(b.size.y, OnlineUi.MIN_HEIGHT, "%s: %s is tall enough" % [what, b.text])


# --- PLAY ONLINE's pages ---

func test_a_new_player_sees_the_card_then_claims_the_name_then_home() -> void:
	var s := _service("dev-a", "Pip")
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_SAFE_CARD)
	assert_true(screen.page is StaySafeCard)
	await _check_page(screen, "the stay-safe card")
	for rule: Array in StaySafeCard.RULES:
		assert_lte((rule[1] as String).split(" ").size(), 9, "short words: %s" % rule[1])
	await _press(screen, "I WILL")
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)
	await _check_page(screen, "the name claim")
	var claim := screen.page as UsernameClaim
	assert_eq(claim.edit.text, "Pip", "the profile's name, ready to claim")
	await _press(screen, "OK")
	await wait_process_frames(2)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)
	assert_not_null(_button(screen, "HOST MY"))
	assert_not_null(_button(screen, "FRIENDS"))
	await _check_page(screen, "home")


func test_a_taken_name_can_be_changed_on_the_spot() -> void:
	server.make_account("dev-b", "Pip")
	var s := _service("dev-a", "Pip")
	s.prefs.safe_card_seen = now
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)
	var claim := screen.page as UsernameClaim
	await _press(screen, "OK")
	# Owner #99: a taken name asks first whether it is this child's own, from another device; NO comes back here
	assert_true(claim.taken_box.visible, "the question")
	assert_eq(claim.taken_label.text, DeviceMoveRules.taken_text("Pip"))
	await _press(screen, DeviceMoveRules.NO_OTHER)
	assert_false(claim.taken_box.visible)
	assert_eq(claim.hint.text, DeviceMoveRules.PICK_ANOTHER)
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM, "still here")
	assert_not_null(_button(screen, "RANDOM"), "with RANDOM")
	claim.edit.text = "Pip_the_2nd"
	claim.edit.text_changed.emit(claim.edit.text)
	await _press(screen, "OK")
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)
	assert_eq(s.profile.username, "Pip_the_2nd")


func test_no_server_shows_plain_words_and_try_again() -> void:
	server.down = true
	var s := _service("dev-a", "Pip")
	var screen := await _screen(s)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_FAILED)
	assert_eq(screen.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.text == OnlineRules.message("network")).size(), 1)
	assert_eq(screen.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.text == OnlineRules.PLAY_ALONE).size(), 1, "owner #93: what works alone")
	server.down = false
	await _press(screen, "TRY AGAIN")
	await wait_process_frames(2)
	assert_eq(screen.view, OnlineRules.SCREEN_SAFE_CARD)


func test_a_build_without_a_server_says_coming_soon_and_never_connects() -> void:
	var s := _service("dev-a", "Pip")
	s.server = {"error": "there is no online server yet"}
	var screen := await _screen(s)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_SOON)
	assert_eq(server.calls.count("sign_in"), 0, "no connection is tried")
	assert_eq(screen.find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.text == OnlineRules.message("no_server")).size(), 1)
	assert_null(_button(screen, "TRY AGAIN"), "nothing to try again")
	assert_not_null(_button(screen, "BACK"))
	await _check_page(screen, "coming soon")


func test_host_my_world_asks_which_world() -> void:
	var s := await _ready_service("dev-a", "Pip")
	var screen := await _screen(s)
	watch_signals(screen)
	await _press(screen, "HOST MY")
	assert_eq(screen.view, PlayOnlineScreen.VIEW_HOST)
	await _check_page(screen, "which world")
	await _press(screen, "SURVIVOR")
	assert_signal_emitted_with_parameters(screen, "host_requested", [ModeRules.SURVIVOR])


func test_back_closes_the_screen() -> void:
	var s := await _ready_service("dev-a", "Pip")
	var screen := await _screen(s)
	watch_signals(screen)
	await _press(screen, "BACK")
	assert_signal_emitted(screen, "closed")


# --- Consent (§17.2) ---

func test_a_new_under_13_player_goes_card_name_then_ask_a_grown_up() -> void:
	var s := _service("dev-k", "Kit", AgeBand.UNDER_13)
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_SAFE_CARD)
	await _press(screen, "I WILL")
	assert_eq(screen.view, OnlineRules.SCREEN_CLAIM)
	await _press(screen, "OK")
	await wait_process_frames(2)
	assert_eq(screen.view, OnlineRules.SCREEN_ASK_GROWNUP)
	assert_null(_button(screen, "FRIENDS"))


func test_under_13_asks_a_grown_up_and_sees_nothing_social() -> void:
	var s := await _young_service("dev-k", "Kit")
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_ASK_GROWNUP)
	await _check_page(screen, "ask a grown-up")
	assert_null(_button(screen, "FRIENDS"), "no friends before consent")
	assert_null(_button(screen, "HOST"), "no hosting for friends before consent")
	await _press(screen, "GROWN-UP HERE")
	assert_eq(screen.view, PlayOnlineScreen.VIEW_GATE)
	await _check_page(screen, "the parent gate")
	var gate := screen.page as GrownUpGate
	var first_question := gate.question.duplicate()
	for key in str(int(first_question.answer) + 1):
		gate.press(key)
	gate.press("OK")
	await wait_process_frames(2)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_GATE, "a wrong answer stays at the gate")
	assert_true(gate.question_label.text.begins_with("Not quite"))
	for key in str(gate.question.answer):
		gate.press(key)
	gate.press("OK")
	await wait_process_frames(2)
	assert_eq(screen.view, PlayOnlineScreen.VIEW_GROWNUPS)
	var panel := screen.page as GrownUpsPanel
	assert_true(panel.needs_consent())
	await _check_page(screen, "the grown-up's page")
	assert_true(panel.check_button.disabled, "nothing to check before START")
	await _press(screen, "START")
	assert_eq(s.account.consent, OnlineRules.CONSENT_PENDING)
	assert_false(panel.check_button.disabled)
	await _press(screen, "CHECK")
	await wait_process_frames(2)
	panel = screen.page as GrownUpsPanel
	assert_false(panel.needs_consent(), "verified by the fake provider")
	assert_not_null(panel.save_button, "now the switches")
	assert_eq(panel.message.text, "Thank you! Online play is on.")
	assert_true((panel.online_buttons[true] as Button).button_pressed)
	assert_eq(panel.chat_buttons.keys(), [OnlineRules.CHAT_OFF, OnlineRules.CHAT_QUICK], "never free text for under-13")
	await _check_page(screen, "the grown-up's switches")
	await _press(screen, "DONE")
	await wait_process_frames(2)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME, "friends and hosting now")


func test_no_provider_on_the_server_says_coming_soon() -> void:
	server.provider_missing = true
	var s := await _young_service("dev-k", "Kit")
	var screen := await _screen(s)
	(screen as PlayOnlineScreen).call("_show_grownups")
	await wait_process_frames(2)
	var panel := screen.page as GrownUpsPanel
	assert_true(panel.start_button.disabled)
	assert_eq(panel.message.text, OnlineRules.message("no_provider"))


func test_a_provider_page_opens_for_the_grown_up() -> void:
	var s := await _young_service("dev-k", "Kit")
	var screen := await _screen(s)
	(screen as PlayOnlineScreen).call("_show_grownups")
	await wait_process_frames(2)
	var panel := screen.page as GrownUpsPanel
	var opened: Array = []
	panel.open_url = func(url: String) -> void: opened.append(url)
	# The fake provider has no page: nothing opens, the grown-up is told to tap CHECK.
	await _press(screen, "START")
	assert_eq(opened, [])
	assert_string_contains(panel.message.text, "CHECK")


func test_a_waiting_child_moves_on_when_a_grown_up_approves() -> void:
	var s := await _young_service("dev-k", "Kit")
	await s.start_consent()
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_WAIT_GROWNUP)
	await _check_page(screen, "waiting for a grown-up")
	server.consent_auto_verify = false
	await _press(screen, "CHECK")
	assert_eq(screen.view, OnlineRules.SCREEN_WAIT_GROWNUP)
	assert_eq(screen.message.text, "Not yet. A grown-up can tap GROWN-UPS.")
	var id: String = s.backend.user_id()
	server.accounts[id].consent = OnlineRules.CONSENT_VERIFIED
	server.accounts[id].online_allowed = true
	server.notify(id, OnlineRules.PARENT_APPROVED, {"what": "consent"})
	await wait_process_frames(3)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME, "notification 103 moves the child on")


func test_a_grown_up_switches_online_play_back_on() -> void:
	var s := await _ready_service("dev-a", "Pip")
	await s.set_parent_settings(false, OnlineRules.CHAT_OFF)
	var screen := await _screen(s)
	assert_eq(screen.view, OnlineRules.SCREEN_PARENT_OFF)
	await _press(screen, "GROWN-UPS")
	var gate := screen.page as GrownUpGate
	for key in str(gate.question.answer):
		gate.press(key)
	gate.press("OK")
	await wait_process_frames(2)
	var panel := screen.page as GrownUpsPanel
	(panel.online_buttons[true] as Button).pressed.emit()
	(panel.chat_buttons[OnlineRules.CHAT_FILTERED] as Button).pressed.emit()
	await _press(screen, "SAVE")
	assert_eq(panel.message.text, "Saved!")
	assert_true(s.account.online_allowed)
	assert_eq(s.account.chat, OnlineRules.CHAT_FILTERED)
	await _press(screen, "DONE")
	await wait_process_frames(2)
	assert_eq(screen.view, OnlineRules.SCREEN_HOME)


# --- Friends ---

func _friends_page(s: OnlineService) -> OnlineFriendsPanel:
	var screen := await _screen(s)
	await _press(screen, "FRIENDS")
	return screen.page as OnlineFriendsPanel


func _row(panel: Node, username: String) -> Control:
	var rows := panel.find_children("Friend_" + username, "", true, false)
	return rows[0] if not rows.is_empty() and (rows[0] as Control).is_visible_in_tree() else null


func test_the_friends_page_requests_dots_and_join() -> void:
	var pip := await _ready_service("dev-a", "Pip")
	var ann_id: String = server.make_account("dev-ann", "Ann")
	var bob := await _ready_service("dev-b", "Bob")
	server.befriend(pip.backend.user_id(), bob.backend.user_id())
	server.edges[ann_id] = {pip.backend.user_id(): 1}
	server.edges[pip.backend.user_id()][ann_id] = 2
	await bob.invite(pip.backend.user_id(), MATCH, "Survivor")
	var screen := await _screen(pip)
	assert_eq(_button(screen, "FRIENDS").text, "FRIENDS\n2 new", "a request and an invite")
	await _press(screen, "FRIENDS")
	var panel := screen.page as OnlineFriendsPanel
	await _check_page(screen, "friends")
	var ann := _row(panel, "Ann")
	assert_not_null(ann)
	assert_not_null(_button(ann, "YES"))
	assert_not_null(_button(ann, "NO"))
	var bob_row := _row(panel, "Bob")
	assert_true((bob_row.get_node("Dot") as OnlineDot).on, "Bob is online")
	watch_signals(screen)
	await _press(bob_row, "JOIN")
	assert_signal_emitted_with_parameters(screen, "join_requested", [MATCH])
	await _press(_row(panel, "Ann"), "YES")
	await wait_process_frames(2)
	assert_null(_button(_row(panel, "Ann"), "YES"), "friends now")
	assert_false((_row(panel, "Ann").get_node("Dot") as OnlineDot).on, "Ann is away: an empty ring")


func test_adding_a_friend_by_name() -> void:
	var pip := await _ready_service("dev-a", "Pip")
	server.make_account("dev-b", "Bob")
	var panel := await _friends_page(pip)
	panel.name_edit.text = "Nobody"
	await _press(panel, "ADD")
	assert_eq(panel.message.text, OnlineRules.message("no_such_player"))
	assert_eq(panel.name_edit.text, "Nobody", "kept to fix a typo")
	panel.name_edit.text = "Bob"
	await _press(panel, "ADD")
	assert_string_starts_with(panel.message.text, "Asked!")
	assert_eq(panel.name_edit.text, "")
	assert_not_null(_row(panel, "Bob"), "an asked row")


func test_mute_block_and_report() -> void:
	var pip := await _ready_service("dev-a", "Pip")
	var bob_id: String = server.make_account("dev-b", "Bob")
	var cyd_id: String = server.make_account("dev-c", "Cyd")
	server.befriend(pip.backend.user_id(), bob_id)
	server.befriend(pip.backend.user_id(), cyd_id)
	var panel := await _friends_page(pip)
	await _press(_row(panel, "Bob"), "MORE")
	await _check_page(panel.get_parent() as Control, "a friend's page")
	await _press(panel, "MUTE")
	assert_true(pip.is_muted(bob_id))
	assert_not_null(_button(panel, "UNMUTE"))
	await _press(panel, "REPORT")
	await _check_page(panel.get_parent() as Control, "what happened")
	await _press(panel, "MEAN WORDS")
	assert_eq(server.reports.size(), 1)
	assert_eq(server.reports[0].reason, "mean_words", "the server's reason code")
	assert_string_starts_with(panel.message.text, "Thank you")
	await _press(_row(panel, "Cyd"), "MORE")
	await _press(panel, "BLOCK")
	assert_not_null(_button(panel, "YES, BLOCK"), "asks first")
	await _press(panel, "YES, BLOCK")
	assert_null(_row(panel, "Cyd"), "blocked: gone")
	assert_not_null(_row(panel, "Bob"))


# --- The invite toast ---

func test_the_invite_toast_join_not_now_and_cancel() -> void:
	var pip := await _ready_service("dev-a", "Pip")
	var bob := await _ready_service("dev-b", "Bob")
	server.befriend(pip.backend.user_id(), bob.backend.user_id())
	var toast := InviteToast.new()
	toast.service = bob
	add_child_autofree(toast)
	await wait_process_frames(2)
	assert_false(toast.visible)
	await pip.invite(bob.backend.user_id(), MATCH, "Sandbox")
	await wait_process_frames(2)
	assert_true(toast.visible)
	assert_eq(toast.text_label.text, "Pip invites you to their world!")
	assert_eq(toast.world_label.text, "A Sandbox world")
	assert_lte(toast.get_combined_minimum_size().x, 1280.0 - 2 * 110.0, "clear of the pause button and the right column")
	assert_eq(toast.process_mode, Node.PROCESS_MODE_ALWAYS, "shows over the pause menu too")
	for b in [toast.join_button, toast.later_button]:
		assert_gte(b.size.x, OnlineUi.MIN_WIDTH)
	toast.later_button.pressed.emit()
	assert_false(toast.visible)
	assert_eq(bob.pending_invites().size(), 1, "NOT NOW keeps it in the friends list")
	await pip.invite(bob.backend.user_id(), MATCH, "Sandbox")
	server.notify(bob.backend.user_id(), OnlineRules.INVITE_CANCELLED, {"match_id": MATCH}, pip.backend.user_id())
	assert_false(toast.visible, "a cancelled invite goes away")
	await pip.invite(bob.backend.user_id(), MATCH, "Sandbox")
	watch_signals(toast)
	toast.join_button.pressed.emit()
	assert_signal_emitted(toast, "join_pressed")
	assert_false(toast.visible)
	assert_eq(bob.pending_invites().size(), 0)


func test_the_toast_slips_away_by_itself() -> void:
	var bob := await _ready_service("dev-b", "Bob")
	var toast := InviteToast.new()
	toast.service = bob
	add_child_autofree(toast)
	await wait_process_frames(1)
	toast.show_invite({"match_id": MATCH, "from_username": "Pip", "from_id": "u", "world_name": ""})
	assert_true(toast.visible)
	assert_false(toast.world_label.visible)
	(toast.find_children("*", "Timer", true, false)[0] as Timer).timeout.emit()
	assert_false(toast.visible)


# --- The pause menu's INVITE page ---

func test_the_invite_page_lists_friends_online_and_invites() -> void:
	var pip := await _ready_service("dev-a", "Pip")
	var bob := await _ready_service("dev-b", "Bob")
	var ann_id: String = server.make_account("dev-ann", "Ann")
	server.befriend(pip.backend.user_id(), bob.backend.user_id())
	server.befriend(pip.backend.user_id(), ann_id)   # away
	var got: Array = []
	bob.invite_received.connect(func(inv: Dictionary) -> void: got.append(inv))
	var holder := Control.new()
	holder.theme = UiKit.theme()
	add_child_autofree(holder)
	var panel := InvitePanel.new()
	panel.service = pip
	panel.match_id = MATCH
	panel.world_name = "Sandbox"
	panel.players = func() -> int: return 2
	holder.add_child(panel)
	await wait_process_frames(3)
	assert_eq(panel.players_label.text, "Players: 2 of 4")
	assert_not_null(_row(panel, "Bob"))
	assert_null(_row(panel, "Ann"), "only friends online")
	await _press(_row(panel, "Bob"), "INVITE")
	assert_eq(got.size(), 1)
	assert_eq(got[0].match_id, MATCH)
	var b := _button(_row(panel, "Bob"), "INVITED")
	assert_not_null(b)
	assert_true(b.disabled)
	assert_eq(panel.message.text, "Invited Bob!")
	panel.players = func() -> int: return 4
	panel.call("_fill")
	assert_true(_button(_row(panel, "Bob"), "INVITED").disabled)
	assert_eq(panel.message.text, OnlineRules.message("full"))
