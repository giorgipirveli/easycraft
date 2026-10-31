extends GutTest
## The phone's Survivor gold and the server's wallet ledger (M4 Wave 2, agent F; spec §17.1, §6;
## the lead's review): at sign-in (and after changes while signed in) the phone tells the server what
## changed off the server's watch (solo play, LAN, codes used offline, shopping in the menu), counted
## from a marker kept on the device: the gold the server already accounts for. A first sync on a
## device has no marker: only gold the server lacks goes up, and a server with more gives it to the
## phone. Owner #67 (one account on several devices): the phone follows the wallet, so gold the server
## got elsewhere (another device, a grown-up's gift) comes to the phone, and gold spent elsewhere is gone
## here too; the phone's own changes still wait on it until the server takes them.

var DIR := "user://test_wallet_sync_%d/" % OS.get_process_id()


func after_all() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)


func test_with_a_marker_the_change_since_goes_up_earned_or_spent() -> void:
	assert_eq(WalletSync.plan(560, 500, 500).report, 60, "earned offline")
	assert_eq(WalletSync.plan(440, 500, 500).report, -60, "spent in the menu")
	assert_eq(WalletSync.plan(500, 500, 900).report, 0, "nothing new on the phone")
	var s := WalletSync.settle(560, 500, 500, WalletSync.plan(560, 500, 500), 60)
	assert_eq(s, {"phone": 560, "marker": 560})


func test_what_the_server_did_not_take_goes_up_next_time() -> void:
	var plan := WalletSync.plan(50_000, 0, 0)
	var s := WalletSync.settle(50_000, 0, 0, plan, 20_000)   # the hour's limit
	assert_eq(s.phone, 50_000, "the child keeps it all")
	assert_eq(s.marker, 20_000)
	assert_eq(WalletSync.plan(50_000, s.marker, 20_000).report, 30_000, "the rest, later")


func test_a_first_sync_sends_only_what_the_server_lacks() -> void:
	var plan := WalletSync.plan(700, -1, 200)
	assert_eq(plan.report, 500)
	assert_eq(WalletSync.settle(700, -1, 200, plan, 500), {"phone": 700, "marker": 700})


func test_a_first_sync_with_more_on_the_server_gives_it_to_the_phone() -> void:
	var plan := WalletSync.plan(25, -1, 900)   # a reinstall: the ledger kept the gold
	assert_eq(plan.report, 0, "no spending is guessed")
	assert_eq(WalletSync.settle(25, -1, 900, plan, 0), {"phone": 900, "marker": 900})


func test_gold_never_goes_backwards_on_the_phone_unless_it_was_spent() -> void:
	for c: Array in [[100, -1, 50, 0], [100, 80, 900, 0], [0, -1, 0, 0], [100, 100, 100, 0], [560, 500, 500, 0]]:
		var plan := WalletSync.plan(c[0], c[1], c[2])
		var s := WalletSync.settle(c[0], c[1], c[2], plan, c[3])
		assert_gte(s.phone, c[0], str(c))


# --- Owner #67: the account on every device: the phone follows the wallet ---

func test_gold_the_server_got_elsewhere_reaches_the_phone() -> void:
	var plan := WalletSync.plan(915, 915, 100_915)   # the owner's gift on the server (#67), or another device's gold
	assert_eq(plan.report, 0)
	assert_eq(WalletSync.settle(915, 915, 100_915, plan, 0), {"phone": 100_915, "marker": 100_915})


func test_gold_earned_here_and_elsewhere_adds_up() -> void:
	var plan := WalletSync.plan(560, 500, 1500)   # +60 solo here, +1000 on the tablet
	assert_eq(plan.report, 60)
	assert_eq(WalletSync.settle(560, 500, 1500, plan, 60), {"phone": 1560, "marker": 1560})


func test_gold_spent_on_another_device_is_spent_here_too() -> void:
	var plan := WalletSync.plan(500, 500, 200)   # 300 spent on the tablet: never twice
	assert_eq(WalletSync.settle(500, 500, 200, plan, 0), {"phone": 200, "marker": 200})


func test_what_the_limit_keeps_back_stays_on_the_phone_with_the_rest() -> void:
	var plan := WalletSync.plan(50_000, 0, 1000)   # +50,000 here, +1000 elsewhere; the hour takes 20,000
	var s := WalletSync.settle(50_000, 0, 1000, plan, 20_000)
	assert_eq(s, {"phone": 51_000, "marker": 21_000})
	assert_eq(WalletSync.plan(s.phone, s.marker, 21_000).report, 30_000, "the rest, later")


func test_the_phone_never_goes_below_zero() -> void:
	var plan := WalletSync.plan(0, 500, 50)   # 500 spent here, 450 elsewhere: the server had only 50 left
	assert_eq(WalletSync.settle(0, 500, 50, plan, -50), {"phone": 0, "marker": 0})


func test_markers_are_kept_per_account_on_the_device() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := DIR + "wallet.json"
	assert_eq(WalletSync.marker_of(path, "u1"), -1, "none yet")
	WalletSync.set_marker(path, "u1", 560)
	WalletSync.set_marker(path, "u2", 7)
	assert_eq(WalletSync.marker_of(path, "u1"), 560)
	assert_eq(WalletSync.marker_of(path, "u2"), 7)
	for bad in ["", "nope", '{"u1": "lots"}', '{"u1": -5}', '{"u1": 1e30}']:
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(bad)
		f.close()
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
		assert_eq(WalletSync.marker_of(path, "u1"), -1, "bad file: %s" % bad)
