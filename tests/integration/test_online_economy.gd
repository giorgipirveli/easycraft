extends GutTest
## The economy online and the parent controls against the fake server (M4 Wave 2, agent F; spec
## §17.2, §17.6): codes redeemed by the server when signed in (and on the phone when not), the Gold
## Farm's server clock, a grown-up approving an under-13 player's friends, and the store's age signal
## only ever making the band stricter.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const FIRST_CODE := "sasa192974"   # tests only; the game ships its hash
const FIRST_CODE_HASH := "a59f43a363322b8e2604d1c43fcb5005cf099fdf8e4230fb593e8a918ec46f0a"


class FakePlugin:
	extends Object
	signal age_signals_result(json: String)
	var answer := ""

	func requestAgeSignals() -> void:
		age_signals_result.emit(answer)


var DIR := "user://test_online_economy_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var msec := 100_000


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	msec = 100_000


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _service(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS, signals: AgeSignals = null) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = band
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + device + ".json"
	s.clock = func() -> int: return now
	s.msec_clock = func() -> int: return msec
	s.prefs.safe_card_seen = now
	s.age_signals = signals
	add_child_autofree(s)
	return s


func _player(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS) -> OnlineService:
	server.make_account(device, username, band, OnlineRules.CONSENT_VERIFIED if band == AgeBand.UNDER_13 else OnlineRules.CONSENT_NONE)
	var s := _service(device, username, band)
	assert_eq(await s.sign_in(), "")
	return s


# --- Codes (§17.6) ---

func test_signed_in_the_server_redeems_the_code_once_per_account() -> void:
	var s := await _player("dev-a", "Pip")
	var id: String = s.backend.user_id()
	var tries := CodeTries.new()
	var r: Dictionary = await s.redeem_code("  SASA192974 ", tries, 0)
	assert_eq(r.status, CodeRules.ACCEPTED, str(r))
	assert_eq(r.message, "Code accepted! +1,000 gold")
	assert_eq(s.profile.survivor_gold, ProfileData.START_GOLD + 1000, "a whole number from the server's JSON")
	assert_eq(s.profile.codes_redeemed, [FIRST_CODE_HASH] as Array[String], "the phone knows it too (offline)")
	assert_eq(int(server.wallets[id]), ProfileData.START_GOLD + 1000, "the server's ledger: the phone's gold (sign-in) and the code")
	var again: Dictionary = await s.redeem_code(FIRST_CODE, tries, 0)
	assert_eq(again.status, CodeRules.ALREADY_USED)
	assert_eq(s.profile.survivor_gold, ProfileData.START_GOLD + 1000)


func test_the_server_says_already_used_for_a_code_this_account_used_elsewhere() -> void:
	var s := await _player("dev-a", "Pip")
	server.server_codes[s.backend.user_id()] = [FIRST_CODE_HASH]
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ALREADY_USED)
	assert_eq(r.message, "You already used that code.")
	assert_eq(s.profile.survivor_gold, ProfileData.START_GOLD)


func test_wrong_codes_and_the_servers_lock() -> void:
	var s := await _player("dev-a", "Pip")
	var tries := CodeTries.new()
	var r: Dictionary = await s.redeem_code("banana", tries, 0)
	assert_eq(r.status, CodeRules.UNKNOWN)
	assert_eq(r.message, "That code doesn't work.")
	assert_eq(tries.wrong, 1, "the phone counts it too")
	server.fail_next["redeem_code"] = "locked"
	r = await s.redeem_code("banana2", tries, 0)
	assert_eq(r.status, CodeRules.LOCKED)
	assert_eq(r.wait, 30, "no wait from the server: 30 s")
	var empty: Dictionary = await s.redeem_code("   ", tries, 0)
	assert_eq(empty.status, CodeRules.EMPTY)


func test_offline_the_phone_redeems_it_and_the_server_hears_at_sign_in() -> void:
	var s := _service("dev-a", "Pip")
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ACCEPTED, "not signed in: CodeRules on the phone")
	assert_eq(server.calls.count("redeem_code"), 0)
	var id: String = server.make_account("dev-a", "Pip")
	assert_eq(await s.sign_in(), "")
	assert_eq(server.server_codes.get(id, []), [FIRST_CODE_HASH])


func test_a_network_failure_falls_back_to_the_phone() -> void:
	var s := await _player("dev-a", "Pip")
	server.fail_next["redeem_code"] = "network"
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ACCEPTED)
	assert_eq(s.profile.survivor_gold, ProfileData.START_GOLD + 1000)


func test_the_code_panel_uses_the_server_when_signed_in() -> void:
	var s := await _player("dev-a", "Pip")
	var panel := CodePanel.new()
	panel.profile = s.profile
	panel.save_profile = func() -> void: pass
	panel.tries = CodeTries.new()
	panel.service = s
	add_child_autofree(panel)
	panel.field.text = FIRST_CODE
	await panel.submit()
	assert_eq(panel.message.text, "Code accepted! +1,000 gold")
	assert_eq(server.calls.count("redeem_code"), 1, "the server decided")
	assert_eq(int(server.wallets[s.backend.user_id()]), ProfileData.START_GOLD + 1000)


func test_server_rewards_are_checked() -> void:
	assert_eq(OnlineService.server_reward({"kind": "gold", "amount": 1000.0}), {"kind": CodeRules.KIND_GOLD, "amount": 1000})
	assert_eq(OnlineService.server_reward({"kind": "cosmetic", "item": "hat.party"}), {"kind": CodeRules.KIND_COSMETIC, "item": "hat.party"})
	for bad: Variant in [null, "gold", {"kind": "gold", "amount": -5}, {"kind": "gold", "amount": INF}, {"kind": "gold"},
			{"kind": "gems", "amount": 5}, {"kind": "gold", "amount": 5e9}]:
		assert_eq(OnlineService.server_reward(bad), {}, str(bad))


# (Survivor gold online: tests/integration/test_online_wallets.gd.)


# --- The Gold Farm's clock (§17.6, for M3 Task 10) ---

func test_the_farm_clock_is_the_servers() -> void:
	var s := await _player("dev-a", "Pip")
	var start: Dictionary = await s.farm_start("survivor_1", 120)
	assert_true(start.ok, str(start))
	server.clock_ms += 30 * 60 * 1000
	var peek: Dictionary = await s.farm_peek("survivor_1")
	assert_eq(int(peek.earned), 60)
	var got: Dictionary = await s.farm_collect("survivor_1")
	assert_eq(int(got.earned), 60)
	var none: Dictionary = await s.farm_collect("survivor_1")
	assert_false(none.ok)
	assert_eq(none.error, "not_started")
	var offline := _service("dev-b", "Tom")
	var r: Dictionary = await offline.farm_peek("survivor_1")
	assert_eq(r.text, OnlineRules.message("not_signed_in"))


## M4 Task 10 review D (module 0.2.10): at most 20 farm clocks per player; the answer carries plain words.
func test_a_21st_farm_clock_is_refused_in_plain_words() -> void:
	var s := await _player("dev-a", "Pip")
	for i in 20:
		assert_true((await s.farm_start("w%d" % i, 10)).ok, "farm %d" % i)
	var r: Dictionary = await s.farm_start("w20", 10)
	assert_false(r.ok)
	assert_eq(r.get("error", ""), "too_many_farms")
	assert_eq(r.text, OnlineRules.message("too_many_farms"))
	assert_ne(r.text, OnlineRules.message(""), "words of its own")
	assert_true((await s.farm_start("w3", 10)).ok, "a world that has one starts it again")


# --- A grown-up approves an under-13 player's friends (§17.2) ---

func test_a_childs_friend_request_waits_for_a_grown_up() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var pip := await _player("dev-p", "Pip")
	assert_eq(await kit.add_friend("Pip"), OnlineRules.message("needs_grown_up"))
	assert_eq(pip.friends.size(), 0, "Pip sees nothing yet")
	var waiting: Dictionary = await kit.friend_approvals()
	assert_eq(waiting.text, "")
	assert_eq(waiting.requests.size(), 1)
	assert_eq(waiting.requests[0].username, "Pip")
	assert_eq(waiting.requests[0].direction, "out")
	var approved: Array = []
	kit.friend_approved.connect(func(id: String) -> void: approved.append(id))
	assert_eq(await kit.approve_friend(waiting.requests[0].user_id, true), "")
	await wait_process_frames(2)
	assert_eq(approved, [pip.backend.user_id()], "notification 103 {what: friend}")
	await pip.refresh_friends()
	assert_eq(pip.friends.size(), 1)
	assert_eq(pip.friends[0].state, OnlineRules.RECEIVED, "now Pip sees the request")
	assert_eq((await kit.friend_approvals()).requests, [])


func test_a_grown_up_says_yes_to_a_request_that_came_in() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var pip := await _player("dev-p", "Pip")
	assert_eq(await pip.add_friend("Kit"), "", "13+ players ask as before")
	await kit.refresh_friends()
	assert_eq(kit.friends[0].state, OnlineRules.RECEIVED)
	assert_eq(await kit.accept(kit.friends[0].id), OnlineRules.message("needs_grown_up"))
	var waiting: Dictionary = await kit.friend_approvals()
	assert_eq(waiting.requests[0].direction, "in")
	assert_eq(await kit.approve_friend(waiting.requests[0].user_id, true), "")
	assert_eq(kit.friends.size(), 1)
	assert_eq(kit.friends[0].state, OnlineRules.FRIEND)


func test_a_grown_up_says_no() -> void:
	var kit := await _player("dev-k", "Kit", AgeBand.UNDER_13)
	var pip := await _player("dev-p", "Pip")
	await pip.add_friend("Kit")
	await kit.refresh_friends()
	await kit.accept(kit.friends[0].id)
	var waiting: Dictionary = await kit.friend_approvals()
	assert_eq(await kit.approve_friend(waiting.requests[0].user_id, false), "")
	assert_eq(kit.friends.size(), 0, "the request is gone")
	assert_eq(await kit.approve_friend("nobody", true), OnlineRules.message("not_found"))


func test_approvals_list_is_checked() -> void:
	var list := OnlineService.approval_list([{"user_id": "u1", "username": "Pip", "direction": "in"},
		{"user_id": "", "username": "Pip", "direction": "in"}, {"user_id": "u2", "username": "x", "direction": "in"},
		{"user_id": "u3", "username": "Tom", "direction": "up"}, "junk"])
	assert_eq(list, [{"user_id": "u1", "username": "Pip", "direction": "in"}] as Array[Dictionary])
	assert_eq(OnlineService.approval_list(null), [] as Array[Dictionary])


# --- The store's age signal (§17.2) ---

func test_a_store_signal_under_13_makes_the_band_stricter() -> void:
	var plugin := FakePlugin.new()
	plugin.answer = '{"age_lower": 0, "age_upper": 12}'
	var s := _service("dev-a", "Pip", AgeBand.TEEN_PLUS, AndroidAgeSignals.new(plugin))
	assert_eq(s.profile.age_band, AgeBand.UNDER_13, "the store says under 13")
	await s.sign_in()
	assert_eq(await s.claim_username("Pip"), "")
	assert_eq(server.accounts[s.backend.user_id()].age_band, "under_13", "the first claim tells the server")
	plugin.free()


## M4 Task 10 review: the store's signal came after a 13+ claim. Before, only the phone's band changed and the
## server kept the account 13+ (free text, friends without a grown-up, no consent needed): now the server hears
## it at the next sign-in, and the account has under-13's rules everywhere.
func test_a_store_signal_after_a_13_plus_claim_makes_the_server_account_under_13() -> void:
	var id: String = server.make_account("dev-a", "Pip", AgeBand.TEEN_PLUS)
	var plugin := FakePlugin.new()
	plugin.answer = '{"age_lower": 0, "age_upper": 12}'
	var s := _service("dev-a", "Pip", AgeBand.TEEN_PLUS, AndroidAgeSignals.new(plugin))
	assert_eq(s.profile.age_band, AgeBand.UNDER_13, "the store says under 13")
	assert_eq(await s.sign_in(), "")
	assert_eq(server.accounts[id].age_band, "under_13", "the server heard it")
	assert_eq(server.accounts[id].online_allowed, false, "under-13's defaults: offline until a grown-up's consent")
	assert_eq(s.account.age_band, AgeBand.UNDER_13)
	assert_false(s.social_allowed(), "no friends, invites or chat without consent")
	assert_eq(s.chat_level(), OnlineRules.CHAT_OFF)
	assert_false(s.can_type())
	plugin.free()


func test_a_store_signal_while_signed_in_tells_the_server_at_once() -> void:
	var s := await _player("dev-a", "Pip")
	var id: String = s.backend.user_id()
	assert_true(s.social_allowed())
	await s._f_on_age_signal(AgeBand.UNDER_13)
	assert_eq(server.accounts[id].age_band, "under_13")
	assert_false(s.social_allowed())


func test_the_phone_keeps_under_13_rules_when_the_server_cant_hear_it_yet() -> void:
	var s := await _player("dev-a", "Pip")
	var id: String = s.backend.user_id()
	s.profile.age_band = AgeBand.UNDER_13
	server.fail_next["set_parent_settings"] = "network"
	assert_eq(await s.refresh_account(), "")
	assert_eq(server.accounts[id].age_band, "13_plus", "not heard yet (the next read of the account tries again)")
	assert_eq(s.account.age_band, AgeBand.UNDER_13, "the phone's stricter band wins meanwhile")
	assert_false(s.social_allowed())
	assert_eq(await s.refresh_account(), "")
	assert_eq(server.accounts[id].age_band, "under_13", "heard at the next read of the account")


func test_a_store_signal_never_lifts_under_13() -> void:
	var plugin := FakePlugin.new()
	plugin.answer = '{"age_lower": 18, "age_upper": null}'
	var s := _service("dev-a", "Kit", AgeBand.UNDER_13, AndroidAgeSignals.new(plugin))
	assert_eq(s.profile.age_band, AgeBand.UNDER_13)
	var none := _service("dev-b", "Tom", AgeBand.TEEN_PLUS)
	assert_eq(none.profile.age_band, AgeBand.TEEN_PLUS, "no signal on the desktop: nothing changes")
	plugin.free()
