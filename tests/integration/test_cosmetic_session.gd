extends GutTest
## M3 Task 9: in a Survivor world the host decides every gold change (M2 §12.11), so an avatar item
## bought from the pause menu is paid through Session (gold_spend), at its fixed price. Sandbox gold
## never buys account-wide items (§5.9), and earned items can't be bought at all.

var _gold_before := 0
var _mode_before: StringName
var _owned_before: Array[String]
var _results: Array = []


func before_each() -> void:
	_gold_before = Profile.data.survivor_gold
	_mode_before = Game.mode
	_owned_before = Profile.data.cosmetics.duplicate()
	Game.mode = ModeRules.SURVIVOR
	Profile.data.cosmetics = [] as Array[String]
	_results.clear()
	Session.cosmetic_result.connect(_on_result)


func after_each() -> void:
	Session.cosmetic_result.disconnect(_on_result)
	Profile.data.survivor_gold = _gold_before
	Profile.data.cosmetics = _owned_before
	Game.mode = _mode_before
	Session.survivor_reset()


func _on_result(item: String, status: StringName) -> void:
	_results.append([item, status])


func test_the_host_buys_an_item_with_survivor_gold() -> void:
	var item := "hat.crown"
	Profile.data.survivor_gold = AvatarCatalog.price(item) + 5
	Session.request_cosmetic_buy(item)
	assert_eq(Profile.data.survivor_gold, 5, "the fixed price")
	assert_true(AvatarUnlocks.is_owned(item, Profile.data.cosmetics))
	assert_eq(_results, [[item, AvatarUnlocks.OK]])


func test_not_enough_gold_is_refused() -> void:
	Profile.data.survivor_gold = 10
	Session.request_cosmetic_buy("wings.dragon")
	assert_eq(Profile.data.survivor_gold, 10)
	assert_false(AvatarUnlocks.is_owned("wings.dragon", Profile.data.cosmetics))
	assert_eq(_results, [["wings.dragon", AvatarUnlocks.NOT_ENOUGH]])


func test_sandbox_gold_never_buys_items() -> void:
	Game.mode = ModeRules.SANDBOX
	Profile.data.survivor_gold = 5000
	Session.request_cosmetic_buy("hat.crown")
	assert_eq(Profile.data.survivor_gold, 5000)
	assert_false(AvatarUnlocks.is_owned("hat.crown", Profile.data.cosmetics))
	assert_eq(_results, [["hat.crown", AvatarUnlocks.NOT_FOR_SALE]])


func test_earned_and_unknown_items_are_not_sold() -> void:
	Profile.data.survivor_gold = 99_999
	Session.request_cosmetic_buy("outfit.cosmic")
	Session.request_cosmetic_buy("hat.gold_bar")
	assert_eq(Profile.data.survivor_gold, 99_999)
	assert_eq(_results, [["outfit.cosmic", AvatarUnlocks.NOT_FOR_SALE], ["hat.gold_bar", AvatarUnlocks.UNKNOWN]])


func test_an_owned_item_is_never_charged_twice() -> void:
	Profile.data.survivor_gold = 1000
	AvatarUnlocks.grant(Profile.data, "cape.royal")
	Session.request_cosmetic_buy("cape.royal")
	assert_eq(Profile.data.survivor_gold, 1000)
	assert_eq(_results, [["cape.royal", AvatarUnlocks.OWNED]])


func test_a_guest_pays_from_the_hosts_wallet_for_them() -> void:
	var guest := 7070
	Session._wallets[guest] = Wallet.new(500)
	var status := Session._host_cosmetic_buy(guest, "wings.bat")
	for e in get_errors():   # the answer RPC has no real guest to reach in a test
		e.handled = true
	assert_eq(status, AvatarUnlocks.OK)
	assert_eq(Session.gold_of(guest), 500 - AvatarCatalog.price("wings.bat"))
	assert_false(AvatarUnlocks.is_owned("wings.bat", Profile.data.cosmetics), "the host's own profile is not given it")


func test_the_guest_game_takes_the_hosts_answer() -> void:
	Session._rpc_cosmetic_result("wings.bat", String(AvatarUnlocks.OK))
	assert_true(AvatarUnlocks.is_owned("wings.bat", Profile.data.cosmetics))
	Session._rpc_cosmetic_result("wings.angel", String(AvatarUnlocks.NOT_ENOUGH))
	assert_false(AvatarUnlocks.is_owned("wings.angel", Profile.data.cosmetics))
	assert_eq(_results, [["wings.bat", AvatarUnlocks.OK], ["wings.angel", AvatarUnlocks.NOT_ENOUGH]])
