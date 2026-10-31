extends GutTest
## Survivor gold online against the fake server (M4 Wave 2, agent F; spec §7.3, §17.1, §17.6, §6;
## the lead's review): the host starts a guest's wallet from the server (never the guest's own word),
## reports every change of every player in its match (batched, the server's limits), and the phone's
## gold is reconciled with the server's ledger when signed in (never backwards for the child).
## LAN stays as it was (trusted, §12.11).

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."
const FIRST_CODE := "sasa192974"   # tests only; the game ships its hash

var DIR := "user://test_online_wallets_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var msec := 100_000
var saves: Array[String] = []


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	msec = 100_000
	saves.clear()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	Session.use_online_wallets(null, false)


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _service(device: String, username: String, gold: int = ProfileData.START_GOLD) -> OnlineService:
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = device
	s.profile = ProfileData.new()
	s.profile.username = username
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.profile.survivor_gold = gold
	s.save_profile = func() -> void: saves.append(device)
	s.prefs_path = DIR + device + ".json"
	s.wallet_path = DIR + "wallet_" + device + ".json"
	s.clock = func() -> int: return now
	s.msec_clock = func() -> int: return msec
	s.prefs.safe_card_seen = now
	add_child_autofree(s)
	return s


func _player(device: String, username: String, gold: int = ProfileData.START_GOLD) -> OnlineService:
	server.make_account(device, username)
	var s := _service(device, username, gold)
	assert_eq(await s.sign_in(), "")
	return s


## A host signed in and hosting MATCH with one guest in it (as the server sees it).
func _hosting(guest_gold: int) -> Array:   # [host service, guest user id]
	var host := await _player("dev-h", "Hostie", 50)
	var guest_id: String = server.make_account("dev-g", "Guesty")
	server.wallets[guest_id] = guest_gold
	server.host_match(MATCH, host.backend.user_id(), [guest_id])
	return [host, guest_id]


func _wallets(host: OnlineService, guest_id: String) -> OnlineWallets:
	var w := OnlineWallets.new()
	w.service = host
	w.user_of = func(peer_id: int) -> String: return guest_id if peer_id == 2 else ""
	w.match_id = func() -> String: return MATCH
	return w


# --- The host and its guests' wallets ---

func test_the_host_starts_a_guests_wallet_from_the_server() -> void:
	var h := await _hosting(300)
	var w := _wallets(h[0], h[1])
	assert_eq(await w.starting_gold(2), 300, "the server's balance, not what the guest says")
	assert_eq(await w.starting_gold(3), -1, "a peer the relay doesn't know")
	server.fail_next["get_gold_of"] = "network"
	assert_eq(await w.starting_gold(2), -1, "no answer: the caller decides (LAN's trust)")


func test_the_host_reports_every_change_of_every_player_in_one_batch_each() -> void:
	var h := await _hosting(300)
	var host: OnlineService = h[0]
	var w := _wallets(host, h[1])
	var calls_before: int = server.calls.count("wallet_award")   # the host's own sign-in sync
	w.moved(2, 30)
	w.moved(2, 10)
	w.moved(2, -15)
	w.moved(1, 25)   # the host itself
	await wait_process_frames(2)
	assert_eq(server.calls.count("wallet_award"), calls_before, "not one call per coin")
	msec += WalletReport.BATCH_MSEC
	await wait_process_frames(4)
	assert_eq(int(server.wallets[h[1]]), 325, "the guest's balance on the server")
	assert_eq(int(server.wallets[host.backend.user_id()]), 50 + 25, "the host's own (its sign-in sync, then +25)")
	for e: Dictionary in server.ledger:
		assert_eq(e.by, host.backend.user_id(), "the host reported it")


func test_a_spend_the_server_refuses_is_dropped_and_a_lost_one_tried_again() -> void:
	var h := await _hosting(10)
	var host: OnlineService = h[0]
	host.report_gold(-50, h[1], MATCH)
	await host.send_wallet_report()
	assert_eq(int(server.wallets[h[1]]), 10, "not enough gold: the server says no")
	assert_eq(host.pending_reports(), 0)
	server.fail_next["wallet_award"] = "network"
	host.report_gold(40, h[1], MATCH)
	await host.send_wallet_report()
	assert_eq(host.pending_reports(), 40, "the network lost it: again with the next batch")
	await host.send_wallet_report()
	assert_eq(int(server.wallets[h[1]]), 50)


## M4 Task 10 review C (module 0.2.10): the server limits the spends a host reports for a guest (20,000 an hour in
## universe 1); one it refuses is dropped like its other refusals, and the guest keeps that gold on the server.
func test_a_guests_spend_over_the_servers_hour_limit_is_dropped() -> void:
	var h := await _hosting(100_000)
	var host: OnlineService = h[0]
	host.report_gold(-20_000, h[1], MATCH)
	await host.send_wallet_report()
	assert_eq(int(server.wallets[h[1]]), 80_000)
	host.report_gold(-1, h[1], MATCH)
	await host.send_wallet_report()
	assert_eq(int(server.wallets[h[1]]), 80_000, "spend_limit: the server says no")
	assert_eq(host.pending_reports(), 0, "not tried again")
	assert_eq(server.ledger.filter(func(e: Dictionary) -> bool: return e.user_id == h[1]).size(), 1, "one spend on the ledger")


func test_only_the_host_reports_for_others() -> void:
	var h := await _hosting(10)
	var stranger := await _player("dev-s", "Strngr")
	stranger.report_gold(40, h[1], MATCH)
	await stranger.send_wallet_report()
	assert_eq(int(server.wallets[h[1]]), 10, "not_host: nothing credited")


func test_nothing_is_reported_when_not_signed_in() -> void:
	var s := _service("dev-a", "Pip")
	s.report_gold(25)
	assert_eq(s.pending_reports(), 0)


# --- Session: online hosts seed from the server, LAN stays as it was ---

func test_an_online_host_seeds_a_guest_from_the_server_not_its_word() -> void:
	var h := await _hosting(300)
	Session.use_online_wallets(_wallets(h[0], h[1]), true)
	Session.call("_f_forget_wallet", 2)
	assert_true(Session.call("_f_seed_guest", 2, 999_999), "online: the server decides")
	await wait_process_frames(3)
	assert_eq(Session.gold_of(2), 300)
	Session.call("_f_forget_wallet", 2)


func test_a_lan_host_trusts_the_guest_as_before() -> void:
	Session.use_online_wallets(null, false)
	assert_false(Session.call("_f_seed_guest", 2, 77), "LAN: the guest's word (spec §12.11)")


func test_a_guest_online_keeps_its_own_gold_and_follows_the_hosts_changes() -> void:
	var before := Profile.data.survivor_gold
	var moved: Array = []
	var on_moved := func(delta: int) -> void: moved.append(delta)
	Session.own_gold_moved_online.connect(on_moved)
	Profile.data.survivor_gold = 120
	Session.call("_rpc_gold_moved", 5000, 30)   # the host's view is the server's: the phone adds the change
	assert_eq(Profile.data.survivor_gold, 150)
	Session.call("_rpc_gold_moved", 4000, -500)
	assert_eq(Profile.data.survivor_gold, 0, "never below zero")
	Session.own_gold_moved_online.disconnect(on_moved)
	Profile.data.survivor_gold = before
	assert_eq(moved, [30, -150])


# --- Reconciling the phone with the server's ledger (sign-in and changes while signed in) ---

func test_the_first_sync_sends_the_phones_gold_the_server_lacks() -> void:
	var s := await _player("dev-a", "Pip", 700)
	var id: String = s.backend.user_id()
	assert_eq(int(server.wallets.get(id, 0)), 700, "sent at sign-in")
	assert_eq(s.profile.survivor_gold, 700)
	assert_eq(WalletSync.marker_of(s.wallet_path, id), 700)


func test_spending_in_the_menu_goes_up_as_a_spend() -> void:
	var s := await _player("dev-a", "Pip", 700)
	var id: String = s.backend.user_id()
	s.profile.survivor_gold = 640   # a hat from the avatar editor
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 640)
	assert_eq(s.profile.survivor_gold, 640, "no gold back for shopping")


func test_a_server_with_more_gives_it_to_a_new_phone() -> void:
	var id: String = server.make_account("dev-a", "Pip")
	server.wallets[id] = 900
	var s := _service("dev-a", "Pip", ProfileData.START_GOLD)
	assert_eq(await s.sign_in(), "")
	assert_eq(s.profile.survivor_gold, 900, "gold never goes backwards")
	assert_true(saves.has("dev-a"), "saved on the phone")


func test_what_the_limit_refused_goes_up_later_and_the_phone_keeps_it() -> void:
	server.hour_limit = 20000
	var s := await _player("dev-a", "Pip", 50_000)
	var id: String = s.backend.user_id()
	assert_eq(int(server.wallets[id]), 20_000)
	assert_eq(s.profile.survivor_gold, 50_000)
	server.awarded_this_hour.clear()   # an hour later
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 40_000)


func test_changes_in_an_online_world_are_the_hosts_to_report() -> void:
	var s := await _player("dev-a", "Pip", 700)
	var id: String = s.backend.user_id()
	server.wallets[id] = 730   # the host reported +30 for this player
	s.profile.survivor_gold = 730
	s.call("_f_on_own_gold_moved_online", 30)
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 730, "not reported twice")


# --- Owner #67: one account on several devices; the phone follows the wallet ---

func test_gold_given_on_the_server_reaches_a_phone_that_synced_before() -> void:
	var s := await _player("dev-a", "Pip", 915)
	var id: String = s.backend.user_id()
	assert_eq(WalletSync.marker_of(s.wallet_path, id), 915, "this phone synced before")
	server.wallets[id] = 100_915   # the owner's gift (owner feedback #67), or gold earned on another device
	assert_eq(await s.sync_wallet(), "")
	assert_eq(s.profile.survivor_gold, 100_915)
	assert_true(saves.has("dev-a"), "saved on the phone")
	assert_eq(int(server.wallets[id]), 100_915, "nothing reported back")


func test_gold_spent_on_another_device_is_not_spent_twice() -> void:
	var s := await _player("dev-a", "Pip", 900)
	var id: String = s.backend.user_id()
	server.wallets[id] = 400   # 500 spent on the tablet
	s.profile.survivor_gold = 950   # +50 solo here meanwhile
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 450, "this phone's +50 went up")
	assert_eq(s.profile.survivor_gold, 450)


func test_no_sync_while_playing_in_an_online_world() -> void:
	var s := await _player("dev-a", "Pip", 700)
	var id: String = s.backend.user_id()
	s.in_online_world = func() -> bool: return true
	s.profile.survivor_gold = 760   # the host's +60, still in its 5 s batch
	s.call("_f_on_own_gold_moved_online", 60)
	assert_eq(await s.sync_wallet(), "")
	assert_eq(s.profile.survivor_gold, 760, "the phone keeps the host's word until the server has it")
	assert_eq(int(server.wallets[id]), 700, "and reports nothing itself")


func test_a_code_redeemed_by_the_server_is_not_reported_again() -> void:
	var s := await _player("dev-a", "Pip", 100)
	var id: String = s.backend.user_id()
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ACCEPTED)
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 1100, "the server paid the code once")
	assert_eq(s.profile.survivor_gold, 1100)


func test_the_server_gold_is_read_from_the_account() -> void:
	assert_eq(OnlineRules.account({"gold": 42.0}, AgeBand.TEEN_PLUS).gold, 42)
	assert_eq(OnlineRules.account({}, AgeBand.TEEN_PLUS).gold, -1, "an older server: unknown")
	assert_eq(OnlineRules.account({"gold": "lots"}, AgeBand.TEEN_PLUS).gold, -1)


## The lead (2026-10-01; test_nakama_account_key saw 2000 where 1000 was right, under load): a sync plans from the
## phone's gold it read at its start; if the gold changes while it waits for the server (signing in with a key brings
## the account's profile, with its gold), the planned change is stale and must not be added: the sync starts again.
func test_gold_that_changes_while_a_sync_waits_is_never_counted_twice() -> void:
	var id: String = server.make_account("dev-a", "Pip")
	server.wallets[id] = 1000
	var s := _service("dev-a", "Pip", 1000)
	assert_eq(await s.sign_in(), "")
	assert_eq(s.profile.survivor_gold, 1000)
	# A fresh browser's first sync on this account: no marker yet, the phone's gold not arrived yet.
	_forget_markers(s)
	s.profile.survivor_gold = 0
	s.backend.latency_frames = 4
	s.sync_wallet()   # waits for the server...
	await wait_process_frames(2)
	s.profile.survivor_gold = 1000   # ...while the account's profile arrives with its gold
	for i in 60:
		if not s.get("_f_syncing"):
			break
		await wait_process_frames(1)
	assert_eq(s.profile.survivor_gold, 1000, "the account's 1000, not 2000")
	assert_eq(int(server.wallets[id]), 1000, "the server's wallet untouched")


# --- The gold-double bug (2026-10-01, docs/devlog/parts/gold-double.md) ---
# test_nakama_account_key saw 2000 where 1000 was right: the phone claimed its name (the first backup went up, and
# `uploaded` started a wallet sync, the phone's first on that account: no marker), the test redeemed a code at once,
# and the two calls crossed: the server read the wallet for the sync (0) before it paid the code, but the code's
# answer reached the phone first. The sync then saw 1000 on the phone and 0 on the server and sent the code's 1000
# again. A gold move the server has already made (a code, a farm collected) must never overlap a sync's read.

## The phone's first sync on its account: no marker (JsonStore keeps the one before as .bak; that goes too).
func _forget_markers(s: OnlineService) -> void:
	DirAccess.remove_absolute(s.wallet_path)
	DirAccess.remove_absolute(s.wallet_path + ".bak")
	assert_eq(WalletSync.marker_of(s.wallet_path, s.backend.user_id()), -1, "no marker")


func _sync_done(s: OnlineService) -> void:
	for i in 60:
		if not s.get("_f_syncing"):
			return
		await wait_process_frames(1)


func test_a_code_paid_while_a_first_sync_reads_the_server_is_not_sent_again() -> void:
	var id: String = server.make_account("dev-a", "Pip")
	var s := _service("dev-a", "Pip", 0)
	assert_eq(await s.sign_in(), "")
	_forget_markers(s)   # the phone's first sync on this account (it has just claimed its name)
	s.backend.answer_frames = {"get_account_state": 4}   # the server reads its 0 at once; the answer comes late
	s.sync_wallet()
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)   # sent next, answered first
	assert_eq(r.status, CodeRules.ACCEPTED)
	await _sync_done(s)
	s.backend.answer_frames = {}
	assert_eq(int(server.wallets[id]), 1000, "the server paid the code once; the phone never sent it again")
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 1000)
	assert_eq(s.profile.survivor_gold, 1000, "the code's 1000, not 2000")


func test_a_code_paid_while_a_sync_reads_the_server_never_vanishes_from_the_phone() -> void:
	var s := await _player("dev-a", "Pip", 0)   # synced before: the marker is 0
	var id: String = s.backend.user_id()
	s.backend.answer_frames = {"get_account_state": 4}
	s.sync_wallet()
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ACCEPTED)
	await _sync_done(s)
	assert_eq(s.profile.survivor_gold, 1000, "the code's gold stays on the phone (not 0 until the next sync)")
	assert_eq(int(server.wallets[id]), 1000)


func test_a_code_answered_after_a_sync_read_the_server_is_not_given_twice() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	s.backend.answer_frames = {"redeem_code": 4}   # the server pays the code at once; its answer comes late
	s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(await s.sync_wallet(), "")   # reads the server's 1000 while the code's answer is on its way
	await wait_process_frames(8)
	assert_eq(s.profile.survivor_gold, 1000, "the code's 1000 once, not 2000")
	assert_eq(int(server.wallets[id]), 1000)
	assert_eq(await s.sync_wallet(), "")
	assert_eq(s.profile.survivor_gold, 1000)


func test_a_farm_collected_while_a_first_sync_reads_the_server_is_not_sent_again() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	_forget_markers(s)
	assert_true((await s.farm_start("survivor_1", 1000)).ok)
	server.clock_ms += 3_600_000   # an hour away: 1000 gold
	s.backend.answer_frames = {"get_account_state": 4}
	s.sync_wallet()
	var r: Dictionary = await s.farm_collect("survivor_1")   # the server pays at once and answers first
	assert_eq(int(r.earned), 1000)
	s.profile.survivor_gold += int(r.earned)   # as the farm director pays the phone (Session.farm_pay_collected)
	s.farm_paid_on_phone(int(r.earned))
	await _sync_done(s)
	s.backend.answer_frames = {}
	assert_eq(int(server.wallets[id]), 1000, "the farm's gold once")
	assert_eq(await s.sync_wallet(), "")
	assert_eq(s.profile.survivor_gold, 1000)
	assert_eq(int(server.wallets[id]), 1000)


func test_a_farm_answered_after_a_sync_read_the_server_is_not_given_twice() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	assert_true((await s.farm_start("survivor_1", 1000)).ok)
	server.clock_ms += 3_600_000
	s.backend.answer_frames = {"farm_collect": 4}   # the server pays at once; its answer comes late
	var collect := func() -> void:
		var r: Dictionary = await s.farm_collect("survivor_1")
		s.profile.survivor_gold += int(r.earned)   # as the farm director pays the phone (Session.farm_pay_collected)
		s.farm_paid_on_phone(int(r.earned))
	collect.call()
	assert_eq(await s.sync_wallet(), "")   # reads the server's 1000 while the farm's answer is on its way
	await wait_process_frames(8)
	assert_eq(s.profile.survivor_gold, 1000, "the farm's 1000 once, not 2000")
	assert_eq(int(server.wallets[id]), 1000)
	assert_eq(await s.sync_wallet(), "")
	assert_eq(s.profile.survivor_gold, 1000)


func test_a_sync_never_plans_from_a_server_read_older_than_a_code() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	_forget_markers(s)   # a first sync, like a sign-in's
	assert_eq(await s.refresh_account(), "")   # the sign-in read the server's 0...
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)   # ...then a code was paid
	assert_eq(r.status, CodeRules.ACCEPTED)
	assert_eq(await s.sync_wallet(false), "")   # the sign-in's sync, with the account it read
	assert_eq(int(server.wallets[id]), 1000, "the code paid once")
	assert_eq(s.profile.survivor_gold, 1000)


# --- The gold-double bug's leftovers (module 0.2.19, docs/devlog/parts/gold-double.md) ---
# 1. A code's answer lost on the network after the server paid it: the phone pays itself (its own check), and must
#    then never report that gold as its own: the server's word (redeem_code's "paid") settles it first.

func test_a_code_whose_answer_was_lost_is_paid_once() -> void:
	var s := await _player("dev-a", "Pip", 0)   # synced before: the marker is 0
	var id: String = s.backend.user_id()
	s.backend.lose_answers = {"redeem_code": 1}   # the server pays the code; its answer never arrives
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ACCEPTED, "no answer: the phone's own check gives it")
	assert_eq(s.profile.survivor_gold, 1000)
	assert_eq(int(server.wallets[id]), 1000, "the server paid it too")
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 1000, "not 2000: the phone never sends the code's gold as its own")
	assert_eq(s.profile.survivor_gold, 1000)
	assert_eq(s.profile.codes_unsettled, {}, "settled")
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 1000)
	assert_eq(s.profile.survivor_gold, 1000)


func test_a_lost_code_answer_is_settled_at_the_next_sign_in() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	s.backend.lose_answers = {"redeem_code": 1}
	await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	s.sign_out()   # the network went with the answer
	assert_eq(await s.sign_in(), "")   # record_offline_codes, then the sign-in's sync
	assert_eq(int(server.wallets[id]), 1000, "the code's gold once")
	assert_eq(s.profile.survivor_gold, 1000)
	assert_eq(s.profile.codes_unsettled, {})


func test_asking_again_after_a_lost_answer_never_pays_twice() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	s.backend.lose_answers = {"redeem_code": 1}
	await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	var again: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)   # "already paid: 1000 gold, at T"
	assert_eq(again.status, CodeRules.ALREADY_USED)
	assert_eq(s.profile.survivor_gold, 1000, "the phone pays nothing more")
	assert_eq(s.profile.codes_unsettled, {}, "the server's word settled it")
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 1000)
	assert_eq(s.profile.survivor_gold, 1000)


func test_a_code_answer_lost_while_a_sync_waits_is_never_sent_as_the_phones() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	s.backend.latency_frames = 2
	s.backend.lose_answers = {"redeem_code": 1}
	s.redeem_code(FIRST_CODE, CodeTries.new(), 0)   # on its way...
	s.sync_wallet()   # ...a sync waits for it, then must not count the phone's own payment as the phone's
	await _sync_done(s)
	assert_eq(int(server.wallets[id]), 1000)
	assert_eq(s.profile.survivor_gold, 1000)


func test_no_sync_reports_a_code_the_phone_paid_before_the_server_said_whose_it_is() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	s.backend.lose_answers = {"redeem_code": 2}   # the code's answer, and the settling record's
	await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_ne(await s.sync_wallet(), "", "no word from the server on the code: no sync now")
	assert_eq(int(server.wallets[id]), 1000, "nothing reported")
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 1000)
	assert_eq(s.profile.survivor_gold, 1000)


func test_a_code_paid_offline_then_paid_online_is_the_accounts_once() -> void:
	var s := await _player("dev-a", "Pip", 0)
	var id: String = s.backend.user_id()
	# The phone paid it by its own check (offline); before the server heard of it, the code was typed again online.
	CodeRules.redeem(s.profile, FIRST_CODE, CodeTries.new(), 0)
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ALREADY_USED, "this phone has it")
	assert_eq(int(server.wallets[id]), 1000, "the server paid it now")
	assert_eq(await s.sync_wallet(), "")
	assert_eq(int(server.wallets[id]), 1000, "once per account: the phone's 1000 is that gold")
	assert_eq(s.profile.survivor_gold, 1000)


func test_a_code_offline_the_server_never_saw_is_still_the_phones_own() -> void:
	var s := _service("dev-a", "Pip", 0)
	CodeRules.redeem(s.profile, FIRST_CODE, CodeTries.new(), 0)   # offline
	var id: String = server.make_account("dev-a", "Pip")
	assert_eq(await s.sign_in(), "")
	assert_eq(int(server.wallets[id]), 1000, "recorded (not paid by the server), and the phone's gold went up")
	assert_eq(s.profile.survivor_gold, 1000)
	assert_eq(s.profile.codes_unsettled, {})


func test_against_an_older_server_a_lost_answer_breaks_nothing() -> void:
	server.old_module = true   # module 0.2.18: no "paid"
	var s := await _player("dev-a", "Pip", 0)
	s.backend.lose_answers = {"redeem_code": 1}
	assert_eq((await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)).status, CodeRules.ACCEPTED)
	assert_eq(await s.sync_wallet(), "", "the older server's record settles it the old way")
	assert_eq(s.profile.codes_unsettled, {})
	assert_eq(s.profile.survivor_gold, int(server.wallets[s.backend.user_id()]), "the phone follows the wallet")


# 2. The host's last batch for a guest who left: the host sends it at once (the server takes it late, with its seq),
#    and the guest's game holds its sync until the server has heard the last seq the host told it (`hosted`).

## The host's game tells the guest's game a gold move (as Session._rpc_gold_moved does) and reports it (batched).
func _host_moves(host: OnlineService, guest: OnlineService, delta: int) -> void:
	host.report_gold(delta, guest.backend.user_id(), MATCH)
	guest.profile.survivor_gold += delta
	guest.call("_f_on_own_gold_moved_online", delta)
	guest.call("_f_on_host_seq", MATCH, host.report_seq(guest.backend.user_id()))


func test_a_guests_last_batch_reaches_the_server_after_it_left() -> void:
	var host := await _player("dev-h", "Hostie", 50)
	var guest := await _player("dev-g", "Guesty", 300)
	var gid: String = guest.backend.user_id()
	server.host_match(MATCH, host.backend.user_id(), [gid])
	assert_eq(int((await host.gold_of(gid, MATCH)).gold), 300, "the host seeds the guest (the server sees it there)")
	_host_moves(host, guest, 30)
	server.leave_match(MATCH, gid)   # the guest leaves before the host's 5 s batch...
	await host.send_wallet_report()   # ...which the host sends at once (Session: a guest left)
	assert_eq(int(server.wallets[gid]), 330, "taken late, with its seq")
	assert_eq(await guest.sync_wallet(), "")
	assert_eq(guest.profile.survivor_gold, 330, "the phone keeps the host's 30")
	assert_eq(int(server.wallets[gid]), 330, "and nothing twice")


func test_a_guest_waits_for_the_hosts_last_batch_before_it_trusts_the_wallet() -> void:
	var host := await _player("dev-h", "Hostie", 50)
	var guest := await _player("dev-g", "Guesty", 300)
	var gid: String = guest.backend.user_id()
	server.host_match(MATCH, host.backend.user_id(), [gid])
	await host.gold_of(gid, MATCH)
	_host_moves(host, guest, 30)
	_host_moves(host, guest, -10)
	server.leave_match(MATCH, gid)
	guest.sync_wallet()   # back at the menu at once: the host's batch is not on the server yet
	await wait_process_frames(3)
	assert_eq(guest.profile.survivor_gold, 320, "never the server's 300 meanwhile")
	await host.send_wallet_report()
	await wait_until(func() -> bool: return not guest.get("_f_syncing"), 5.0)
	assert_eq(guest.profile.survivor_gold, 320)
	assert_eq(int(server.wallets[gid]), 320)


func test_a_guest_waits_no_longer_than_the_host_can_still_report() -> void:
	var host := await _player("dev-h", "Hostie", 50)
	var guest := await _player("dev-g", "Guesty", 300)
	var gid: String = guest.backend.user_id()
	server.host_match(MATCH, host.backend.user_id(), [gid])
	await host.gold_of(gid, MATCH)
	_host_moves(host, guest, 30)
	host.sign_out()   # the host's game closes before it reports: the server never hears of the 30
	server.leave_match(MATCH, gid)
	guest.sync_wallet()
	await wait_process_frames(3)
	assert_true(guest.get("_f_syncing"), "waiting for the host's word")
	msec += OnlineService.HOST_WAIT_MSEC
	await wait_until(func() -> bool: return not guest.get("_f_syncing"), 5.0)
	assert_false(guest.get("_f_syncing"))
	assert_eq(guest.profile.survivor_gold, 300, "the host never told the server: the server's word stands")
	assert_eq(int(server.wallets[gid]), 300)


func test_whoever_asks_for_a_sync_never_waits_for_the_host() -> void:
	var host := await _player("dev-h", "Hostie", 50)
	var guest := await _player("dev-g", "Guesty", 300)
	var gid: String = guest.backend.user_id()
	server.host_match(MATCH, host.backend.user_id(), [gid])
	await host.gold_of(gid, MATCH)
	_host_moves(host, guest, 30)
	host.sign_out()   # its batch never comes
	server.leave_match(MATCH, gid)
	var done := [false]
	var ask := func() -> void:   # a sign-in's sync, an invite's welcome
		await guest.sync_wallet()
		done[0] = true
	ask.call()
	await wait_process_frames(10)
	assert_true(done[0], "the answer at once")
	assert_true(guest.get("_f_syncing"), "the sync waits for the host's word in the background")
	msec += OnlineService.HOST_WAIT_MSEC
	await wait_until(func() -> bool: return not guest.get("_f_syncing"), 5.0)
	assert_eq(guest.profile.survivor_gold, 300)


func test_a_guest_seen_in_another_match_since_waits_for_nothing() -> void:
	var host := await _player("dev-h", "Hostie", 50)
	var guest := await _player("dev-g", "Guesty", 300)
	var gid: String = guest.backend.user_id()
	server.host_match(MATCH, host.backend.user_id(), [gid])
	await host.gold_of(gid, MATCH)
	_host_moves(host, guest, 30)
	host.sign_out()   # never reported
	server.leave_match(MATCH, gid)
	var other := await _player("dev-o", "Othie", 0)
	var match2 := "5ecf6dca-ba73-4e08-a89e-8c538234f742."
	server.host_match(match2, other.backend.user_id(), [gid])
	await other.gold_of(gid, match2)   # the guest went on to another world: the server takes nothing late for MATCH
	server.leave_match(match2, gid)
	guest.sync_wallet()
	await wait_until(func() -> bool: return not guest.get("_f_syncing"), 3.0)
	assert_false(guest.get("_f_syncing"), "no wait: nothing more can come for the first world")
	assert_eq(guest.profile.survivor_gold, 300)


func test_an_older_server_never_makes_a_guest_wait() -> void:
	server.old_module = true   # module 0.2.18: no seq, no "hosted"
	var host := await _player("dev-h", "Hostie", 50)
	var guest := await _player("dev-g", "Guesty", 300)
	var gid: String = guest.backend.user_id()
	server.host_match(MATCH, host.backend.user_id(), [gid])
	_host_moves(host, guest, 30)
	await host.send_wallet_report()   # still in the match: credited as before
	assert_eq(await guest.sync_wallet(), "")
	assert_eq(guest.profile.survivor_gold, 330)
	assert_eq(int(server.wallets[gid]), 330)


func test_the_host_tells_the_server_a_guests_moves_that_netted_to_nothing() -> void:
	var h := await _hosting(300)
	var host: OnlineService = h[0]
	await host.gold_of(h[1], MATCH)
	host.report_gold(25, h[1], MATCH)
	host.report_gold(-25, h[1], MATCH)
	var ledger_before: int = server.ledger.size()
	await host.send_wallet_report()
	assert_eq(server.ledger.size(), ledger_before, "no gold moved")
	assert_eq(int(server.wallet_hosted[h[1]].seq), 2, "the host's word on both moves")
	assert_eq(host.report_seq(h[1]), 2)


func test_a_batch_the_network_lost_goes_again_with_its_seq() -> void:
	var h := await _hosting(300)
	var host: OnlineService = h[0]
	await host.gold_of(h[1], MATCH)
	host.report_gold(40, h[1], MATCH)
	server.fail_next["wallet_award"] = "network"
	await host.send_wallet_report()
	assert_eq(int(server.wallet_hosted[h[1]].seq), 0, "not heard")
	await host.send_wallet_report()
	assert_eq(int(server.wallets[h[1]]), 340)
	assert_eq(int(server.wallet_hosted[h[1]].seq), 1)


func test_the_hosts_own_last_batch_goes_up_before_its_sync_reads() -> void:
	var s := await _player("dev-h", "Hostie", 50)
	var id: String = s.backend.user_id()
	s.report_gold(40)   # the host's own +40 in its online world, still in its 5 s batch
	s.profile.survivor_gold += 40
	s.call("_f_on_own_gold_moved_online", 40)
	assert_eq(await s.sync_wallet(), "")   # the world closed: the menu's sync
	assert_eq(int(server.wallets[id]), 90, "the batch went up first, once")
	assert_eq(s.profile.survivor_gold, 90, "the phone keeps it")
	assert_eq(s.pending_reports(), 0)


func test_the_hosts_own_batch_on_its_way_lands_before_its_sync_reads() -> void:
	var s := await _player("dev-h", "Hostie", 50)
	var id: String = s.backend.user_id()
	s.report_gold(40)
	s.profile.survivor_gold += 40
	s.call("_f_on_own_gold_moved_online", 40)
	s.backend.call_frames = {"wallet_award": 6}   # the batch reaches the server late...
	s.send_wallet_report()   # ...sent when the world closed (Session._online_close)
	assert_eq(await s.sync_wallet(), "")   # the menu's sync starts while it is on its way
	assert_eq(int(server.wallets[id]), 90)
	assert_eq(s.profile.survivor_gold, 90, "never the server's 50 meanwhile")


func test_an_online_host_sends_a_leaving_players_batch_at_once() -> void:
	var h := await _hosting(300)
	var host: OnlineService = h[0]
	Session.use_online_wallets(_wallets(host, h[1]), true)
	await host.gold_of(h[1], MATCH)
	host.report_gold(30, h[1], MATCH)
	server.leave_match(MATCH, h[1])
	Session.call("_a_peer_disconnected", 2)   # the guest's peer left
	await wait_process_frames(3)
	assert_eq(int(server.wallets[h[1]]), 330, "not after the 5 s batch: now")


func test_a_guests_game_hears_the_hosts_count_with_each_gold_move() -> void:
	var before := Profile.data.survivor_gold
	var heard: Array = []
	var on_seq := func(match_id: String, seq: int) -> void: heard.append([match_id, seq])
	Session.hosted_gold_seq.connect(on_seq)
	Session.call("_rpc_gold_moved", 5000, 30, 7)
	Session.call("_rpc_gold_moved", 5000, 0, 8)   # no change, still the host's word
	Session.call("_rpc_gold_moved", 5000, 5)   # an older host: no count
	Session.hosted_gold_seq.disconnect(on_seq)
	Profile.data.survivor_gold = before
	assert_eq(heard, [[Session.online_match_id(), 7], [Session.online_match_id(), 8]])


func test_the_online_wallets_tell_a_guests_count() -> void:
	var h := await _hosting(300)
	var w := _wallets(h[0], h[1])
	assert_eq(w.seq_of(2), 0)
	w.moved(2, 30)
	w.moved(2, -5)
	assert_eq(w.seq_of(2), 2)
	assert_eq(w.seq_of(3), 0, "a peer the relay doesn't know")
