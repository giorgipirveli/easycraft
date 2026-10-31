extends GutTest
## OnlineService against the in-memory fake server (M4 Wave 1, Agent C; spec §17.1-17.3): signing
## in, the account and its PLAY ONLINE screen, the username claim, consent for under-13, friends
## (add, accept, decline, block, mute, report, online dots), invites and every error in plain words.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_online_service_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var saves: Array[String] = []


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	saves.clear()


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
	s.save_profile = func() -> void: saves.append(device)
	s.prefs_path = DIR + device + ".json"
	s.clock = func() -> int: return now
	add_child_autofree(s)
	return s


## A player who has claimed a name and seen the card.
func _ready_player(device: String, username: String) -> OnlineService:
	server.make_account(device, username)
	var s := _service(device, username)
	s.prefs.safe_card_seen = now
	assert_eq(await s.sign_in(), "")
	return s


## The player `id` is signed in on another device (a bare connection, no service).
func _online_elsewhere(id: String) -> void:
	var b: OnlineBackend = FakeBackend.new(server)
	add_child_autofree(b)
	server.clients[id] = [b]


func _friend(s: OnlineService, username: String) -> Dictionary:
	for f: Dictionary in s.friends:
		if f.username == username:
			return f
	return {}


# --- Signing in and the account ---

func test_a_new_teen_signs_in_then_sees_the_card_then_claims_the_name() -> void:
	var s := _service("dev-a", "Pip")
	watch_signals(s)
	assert_eq(s.status, OnlineService.OFFLINE)
	assert_eq(await s.sign_in(), "")
	assert_eq(s.status, OnlineService.ONLINE)
	assert_signal_emitted(s, "status_changed")
	assert_eq(s.screen(), OnlineRules.SCREEN_SAFE_CARD, "the stay-safe card comes first")
	s.mark_card_seen()
	assert_eq(s.screen(), OnlineRules.SCREEN_CLAIM)
	assert_eq(await s.claim_username("Pip"), "")
	assert_eq(s.screen(), OnlineRules.SCREEN_HOME)
	assert_true(s.social_allowed())
	assert_eq(OnlinePrefs.load_from(DIR + "dev-a.json").safe_card_seen, now, "the card is remembered on this device")


func test_no_server_reads_as_the_internet_in_plain_words() -> void:
	server.down = true
	var s := _service("dev-a", "Pip")
	var text: String = await s.sign_in()
	assert_eq(text, OnlineRules.message("network"))
	assert_eq(s.status, OnlineService.OFFLINE)
	assert_false(s.social_allowed())


func test_a_build_without_a_server_says_coming_soon() -> void:
	var s := _service("dev-a", "Pip")
	s.server = {"error": "there is no online server yet"}   # a release build before the owner's VPS
	assert_false(s.has_server())
	assert_eq(await s.sign_in(), OnlineRules.message("no_server"))
	assert_eq(OnlineRules.message("no_server"), "Online play is coming soon!")
	assert_eq(server.calls.count("sign_in"), 0, "nothing is tried")
	assert_eq(s.status, OnlineService.OFFLINE)


func test_signing_in_twice_at_once_signs_in_once() -> void:
	var s := _service("dev-a", "Pip")
	(s.backend as FakeBackend).latency_frames = 2
	s.sign_in()
	assert_eq(s.status, OnlineService.CONNECTING)
	assert_eq(await s.sign_in(), "", "the second call waits for the first")
	assert_eq(server.calls.count("sign_in"), 1)
	assert_eq(s.status, OnlineService.ONLINE)
	await wait_process_frames(6)   # the first call still reads the friends list


func test_the_connection_closing_goes_offline() -> void:
	var s := await _ready_player("dev-a", "Pip")
	watch_signals(s)
	(s.backend as FakeBackend).drop()
	assert_eq(s.status, OnlineService.OFFLINE)
	assert_signal_emitted(s, "status_changed")


# --- The username claim ---

func test_a_taken_name_says_so_kindly() -> void:
	server.make_account("dev-b", "Pip")
	var s := _service("dev-a", "pip")
	await s.sign_in()
	assert_eq(await s.claim_username("pip"), OnlineRules.message("taken"), "uniqueness ignores case")
	assert_false(s.claimed())


func test_a_bad_name_never_leaves_the_phone() -> void:
	var s := _service("dev-a", "Pip")
	await s.sign_in()
	var before: int = server.calls.size()
	assert_eq(await s.claim_username("x"), UsernameRules.message("too_short"))
	assert_eq(await s.claim_username("call5551234567"), UsernameRules.message("personal_info"))
	assert_eq(server.calls.size(), before, "checked on the phone first")


func test_claiming_another_name_makes_it_the_profiles_name() -> void:
	server.make_account("dev-b", "Pip")
	var s := _service("dev-a", "Pip")
	await s.sign_in()
	assert_eq(await s.claim_username("Pip_2"), "")
	assert_eq(s.profile.username, "Pip_2", "one name everywhere")
	assert_eq(saves, ["dev-a"] as Array[String], "the profile is saved")
	assert_true(s.claimed())


# --- Consent for under-13 (§17.2) ---

## A new under-13 player: the card, then the name (unfindable until consent), then the grown-up.
func _young(device: String, username: String) -> OnlineService:
	var s := _service(device, username, AgeBand.UNDER_13)
	s.prefs.safe_card_seen = now
	await s.sign_in()
	assert_eq(await s.claim_username(username), "")
	return s


func test_under_13_claims_a_name_then_asks_a_grown_up_before_anything_social() -> void:
	var s := _service("dev-a", "Kit", AgeBand.UNDER_13)
	await s.sign_in()
	assert_eq(s.screen(), OnlineRules.SCREEN_SAFE_CARD)
	s.mark_card_seen()
	assert_eq(s.screen(), OnlineRules.SCREEN_CLAIM, "the server needs the claim first: it sets the band")
	assert_eq(await s.claim_username("Kit"), "")
	assert_eq(server.accounts[s.backend.user_id()].age_band, "under_13", "the band goes with the claim")
	assert_eq(s.screen(), OnlineRules.SCREEN_ASK_GROWNUP)
	assert_false(s.social_allowed())
	assert_false(server.can_play(s.backend.user_id()), "the name is not findable before consent")
	var pip := await _ready_player("dev-p", "Pip")
	assert_eq(await pip.add_friend("Kit"), OnlineRules.message("no_such_player"), "nobody finds the child")


func test_the_consent_flow_with_the_fake_provider() -> void:
	var s := await _young("dev-a", "Kit")
	var started: Dictionary = await s.start_consent()
	assert_eq(started.text, "")
	assert_eq(s.screen(), OnlineRules.SCREEN_WAIT_GROWNUP)
	assert_eq(await s.check_consent(), "")
	assert_eq(s.account.consent, OnlineRules.CONSENT_VERIFIED)
	assert_eq(s.screen(), OnlineRules.SCREEN_HOME, "the provider's yes turns online play on")
	assert_true(s.social_allowed())
	assert_eq(s.account.chat, OnlineRules.CHAT_QUICK)


func test_consent_needs_the_name_first() -> void:
	var s := _service("dev-a", "Kit", AgeBand.UNDER_13)
	await s.sign_in()
	var started: Dictionary = await s.start_consent()
	assert_eq(started.text, OnlineRules.message("not_claimed"))


func test_no_provider_says_it_is_coming_soon() -> void:
	server.provider_missing = true
	var s := await _young("dev-a", "Kit")
	assert_false(s.account.consent_available, "the server says no provider is set up")
	var started: Dictionary = await s.start_consent()
	assert_eq(started.text, OnlineRules.message("no_provider"))
	assert_eq(s.screen(), OnlineRules.SCREEN_ASK_GROWNUP)


func test_a_provider_page_is_handed_to_the_grown_up() -> void:
	var s := await _young("dev-a", "Kit")
	var started: Dictionary = await s.start_consent()
	assert_eq(started.url, "", "the fake provider has no page")
	assert_eq(OnlineService.consent_url({"ok": true, "url": "https://kids.example/c"}), "https://kids.example/c")
	assert_eq(OnlineService.consent_url({"ok": true, "url": "javascript:alert(1)"}), "", "only https pages")
	assert_eq(OnlineService.consent_url({"ok": true, "url": 5}), "")


func test_a_parent_approval_notification_refreshes_the_account() -> void:
	var s := await _young("dev-a", "Kit")
	var id: String = s.backend.user_id()
	server.accounts[id].consent = OnlineRules.CONSENT_VERIFIED
	server.accounts[id].online_allowed = true
	server.notify(id, OnlineRules.PARENT_APPROVED, {"what": "consent"})
	await wait_process_frames(2)
	assert_eq(s.account.consent, OnlineRules.CONSENT_VERIFIED)


func test_parent_settings() -> void:
	var s := await _ready_player("dev-a", "Pip")
	assert_eq(await s.set_parent_settings(false, OnlineRules.CHAT_OFF), "")
	assert_eq(s.screen(), OnlineRules.SCREEN_PARENT_OFF)
	assert_false(s.social_allowed())
	assert_eq(await s.set_parent_settings(true, OnlineRules.CHAT_FILTERED), "")
	assert_eq(s.screen(), OnlineRules.SCREEN_HOME)
	var young := await _young("dev-y", "Kit")
	assert_eq(await young.set_parent_settings(true, OnlineRules.CHAT_QUICK), OnlineRules.message("consent_needed"),
		"online play for under-13 needs consent first")


# --- Friends ---

func test_a_friend_request_accepted_makes_friends_with_online_dots() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var bo := await _ready_player("dev-b", "Bob")
	watch_signals(bo)
	assert_eq(await pip.add_friend("Bob"), "")
	assert_eq(_friend(pip, "Bob").state, OnlineRules.SENT)
	await wait_process_frames(2)
	assert_signal_emitted(bo, "friends_changed", "Nakama's friend-request notification refreshes the list")
	assert_eq(_friend(bo, "Pip").state, OnlineRules.RECEIVED)
	assert_eq(await bo.accept(_friend(bo, "Pip").id), "")
	assert_eq(_friend(bo, "Pip").state, OnlineRules.FRIEND)
	await wait_process_frames(2)
	assert_eq(_friend(pip, "Bob").state, OnlineRules.FRIEND)
	assert_true(_friend(pip, "Bob").online)
	(bo.backend as FakeBackend).drop()
	assert_false(_friend(pip, "Bob").online, "presence: Bo left")


func test_adding_friends_by_name_errors() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	assert_eq(await pip.add_friend("Nobody"), OnlineRules.message("no_such_player"))
	assert_eq(await pip.add_friend("pip"), OnlineRules.message("self"))
	assert_eq(await pip.add_friend("  "), OnlineRules.message("empty_name"))
	assert_eq(await pip.add_friend("bad name!"), OnlineRules.message("no_such_player"))


func test_the_list_puts_requests_first_then_online_friends_and_hides_blocked() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var ids := {}
	for n: String in ["Ann", "Bob", "Cyd", "Dee", "Eve"]:
		ids[n] = server.make_account("dev-" + n, n)
	server.befriend(server.id_of("Pip"), ids.Ann)                  # offline friend
	server.befriend(server.id_of("Pip"), ids.Bob)
	_online_elsewhere(ids.Bob)                                       # online friend
	server.edges[ids.Cyd] = {server.id_of("Pip"): 1}                 # Cy asked Pip
	server.edges[server.id_of("Pip")][ids.Cyd] = 2
	server.edges[server.id_of("Pip")][ids.Dee] = 1                  # Pip asked Dee
	server.edges[server.id_of("Pip")][ids.Eve] = 3                  # blocked
	assert_eq(await pip.refresh_friends(), "")
	var names: Array[String] = []
	for f: Dictionary in pip.friends:
		names.append(f.username)
	assert_eq(names, ["Cyd", "Bob", "Ann", "Dee"] as Array[String])


func test_declining_removes_the_request_on_both_sides() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var bo := await _ready_player("dev-b", "Bob")
	await pip.add_friend("Bob")
	await bo.refresh_friends()
	assert_eq(await bo.decline(_friend(bo, "Pip").id), "")
	assert_eq(_friend(bo, "Pip"), {})
	await pip.refresh_friends()
	assert_eq(_friend(pip, "Bob"), {})


func test_block_removes_and_keeps_them_away() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var bo := await _ready_player("dev-b", "Bob")
	server.befriend(pip.backend.user_id(), bo.backend.user_id())
	await pip.refresh_friends()
	assert_eq(await pip.block(_friend(pip, "Bob").id), "")
	assert_eq(_friend(pip, "Bob"), {}, "gone from the list")
	await bo.add_friend("Pip")
	await pip.refresh_friends()
	assert_eq(_friend(pip, "Bob"), {}, "a blocked player can't ask again")


func test_mute_is_on_this_device_and_silences_invites() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var bo := await _ready_player("dev-b", "Bob")
	server.befriend(pip.backend.user_id(), bo.backend.user_id())
	await bo.refresh_friends()
	bo.mute(pip.backend.user_id())
	assert_true(bo.is_muted(pip.backend.user_id()))
	assert_true(OnlinePrefs.load_from(DIR + "dev-b.json").is_muted(pip.backend.user_id()), "kept on the device")
	watch_signals(bo)
	assert_eq(await pip.invite(bo.backend.user_id(), MATCH, "Sandbox"), "", "the server still delivers it")
	assert_signal_not_emitted(bo, "invite_received", "a muted friend's invite never shows")
	bo.unmute(pip.backend.user_id())
	await pip.invite(bo.backend.user_id(), MATCH, "Sandbox")
	assert_signal_emitted(bo, "invite_received")


func test_report_goes_to_the_server_and_mutes() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var bo_id: String = server.make_account("dev-b", "Bob")
	assert_eq(await pip.report(bo_id, OnlineService.REPORT_MEAN), "")
	assert_eq(server.reports.size(), 1)
	assert_eq(server.reports[0].user_id, bo_id)
	assert_eq(server.reports[0].reason, OnlineService.REPORT_MEAN)
	assert_true(pip.is_muted(bo_id), "a reported player is muted here too")
	assert_eq(await pip.report(bo_id, "anything"), "", "an unknown reason is sent as other")
	assert_eq(server.reports[1].reason, OnlineService.REPORT_OTHER)


# --- Invites ---

func test_an_invite_reaches_the_friend_and_can_be_cancelled() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var bo := await _ready_player("dev-b", "Bob")
	server.befriend(pip.backend.user_id(), bo.backend.user_id())
	watch_signals(bo)
	assert_eq(await pip.invite(bo.backend.user_id(), MATCH, "Survivor"), "")
	assert_signal_emitted(bo, "invite_received")
	var inv: Dictionary = bo.invite_from(pip.backend.user_id())
	assert_eq(inv.match_id, MATCH)
	assert_eq(inv.from_username, "Pip")
	assert_eq(inv.world_name, "Survivor")
	assert_eq(bo.pending_invites().size(), 1)
	server.notify(bo.backend.user_id(), OnlineRules.INVITE_CANCELLED, {"match_id": MATCH}, pip.backend.user_id())
	assert_signal_emitted_with_parameters(bo, "invite_cancelled", [MATCH])
	assert_eq(bo.pending_invites().size(), 0)
	assert_eq(bo.invite_from(pip.backend.user_id()), {})


func test_old_invites_go_away_by_themselves() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var bo := await _ready_player("dev-b", "Bob")
	server.befriend(pip.backend.user_id(), bo.backend.user_id())
	await pip.invite(bo.backend.user_id(), MATCH, "Sandbox")
	now += OnlineService.INVITE_SECONDS + 1
	assert_eq(bo.pending_invites().size(), 0)


func test_invite_errors_in_plain_words() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var bo_id: String = server.make_account("dev-b", "Bob")
	assert_eq(await pip.invite(bo_id, MATCH, "Sandbox"), OnlineRules.message("not_friends"))
	server.befriend(pip.backend.user_id(), bo_id)
	assert_eq(await pip.invite(bo_id, MATCH, "Sandbox"), OnlineRules.message("offline"))
	_online_elsewhere(bo_id)
	server.match_players[MATCH] = 4
	assert_eq(await pip.invite(bo_id, MATCH, "Sandbox"), OnlineRules.message("full"))


func test_under_13_without_consent_gets_no_friends_and_no_invites() -> void:
	var pip := await _ready_player("dev-a", "Pip")
	var kit := await _young("dev-k", "Kit")
	server.befriend(pip.backend.user_id(), kit.backend.user_id())   # (a server bug or an old edge)
	assert_eq(await kit.refresh_friends(), OnlineRules.message("consent_needed"))
	assert_eq(kit.friends.size(), 0, "no friends list")
	assert_eq(await kit.add_friend("Pip"), OnlineRules.message("consent_needed"))
	watch_signals(kit)
	server.notify(kit.backend.user_id(), OnlineRules.INVITE,
		{"match_id": MATCH, "from_username": "Pip", "world_name": "Sandbox"}, pip.backend.user_id())
	assert_signal_not_emitted(kit, "invite_received", "no invite shows before consent")
	assert_eq(kit.pending_invites().size(), 0)
	assert_eq(await kit.invite(pip.backend.user_id(), MATCH, "Sandbox"), OnlineRules.message("consent_needed"))


func test_a_broken_invite_is_ignored() -> void:
	var bo := await _ready_player("dev-b", "Bob")
	watch_signals(bo)
	server.notify(bo.backend.user_id(), OnlineRules.INVITE, {"match_id": "nope", "from_username": "Pip"}, "u-x")
	assert_signal_not_emitted(bo, "invite_received")


func test_a_blocked_players_invite_is_ignored() -> void:
	var bo := await _ready_player("dev-b", "Bob")
	var pip_id: String = server.make_account("dev-a", "Pip")
	server.edges[bo.backend.user_id()] = {pip_id: 3}
	await bo.refresh_friends()
	watch_signals(bo)
	server.notify(bo.backend.user_id(), OnlineRules.INVITE, {"match_id": MATCH, "from_username": "Pip"}, pip_id)
	assert_signal_not_emitted(bo, "invite_received")
