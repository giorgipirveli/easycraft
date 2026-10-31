extends GutTest
## Owner #37 (spec §14.23): trading between players, the pure rules. An offer is up to 8 kinds of tradable things
## and some Survivor gold; the swap is all or nothing (each still owns what they offered, each bag has room); the
## under-13 friends rule online; the chat line both traders get.


func _inv(pairs: Array) -> Inventory:
	var inv := Inventory.new()
	for p: Array in pairs:
		inv.add(p[0], p[1])
	return inv


func _offer(pairs: Array, gold: int = 0) -> Dictionary:
	return TradeRules.clean_offer(pairs, gold)


func test_blocks_items_and_tools_are_tradable_but_not_crystals_or_the_farm() -> void:
	for id: int in [BlockIds.STONE, BlockIds.DIAMOND, ItemIds.SWORD, ItemIds.POTION_JUMP, ItemIds.TREAT_FISH, BlockIds.BED]:
		assert_true(TradeRules.tradable(id), "%s trades" % ItemIds.display_name(id))
	for id: int in ItemIds.CRYSTALS:
		assert_false(TradeRules.tradable(id), "a universe crystal is earned by reaching its universe")
	assert_false(TradeRules.tradable(ItemIds.FARM), "the Gold Farm is one per world, its owner's")
	assert_false(TradeRules.tradable(BlockIds.AIR))
	assert_false(TradeRules.tradable(BlockIds.BEDROCK))
	assert_false(TradeRules.tradable(99999))


func test_an_offer_is_cleaned_up_whatever_a_game_sends() -> void:
	var o := TradeRules.clean_offer([[BlockIds.STONE, 10], [BlockIds.STONE, 5], [ItemIds.CRYSTAL_DESERT, 1],
		[BlockIds.DIRT, -3], ["x", 2], [BlockIds.GLASS, 5000], 7, [BlockIds.SAND]], 42)
	assert_eq(o.items, {BlockIds.STONE: 15, BlockIds.GLASS: Inventory.MAX_COUNT})
	assert_eq(o.gold, 42)
	assert_eq(TradeRules.clean_offer("nonsense", "x").items, {})
	assert_eq(TradeRules.clean_offer([], -5).gold, 0)
	assert_eq(TradeRules.clean_offer([], 1e12).gold, TradeRules.gold_cap(1), "gold at most the cap")
	assert_eq(TradeRules.clean_offer([], 1e12, 3).gold, TradeRules.gold_cap(3))
	assert_eq(TradeRules.gold_cap(3), TradeRules.GOLD_BASE_MAX * 4, "× 2^(u−1) like every price")
	var many: Array = []
	for id: int in ShopRules.BUILDING_BLOCKS:
		many.append([id, 1])
	assert_eq(TradeRules.clean_offer(many, 0).items.size(), TradeRules.MAX_KINDS, "at most 8 kinds")
	assert_true(TradeRules.is_empty(TradeRules.empty_offer()))


func test_an_offer_shrinks_to_what_its_owner_still_has() -> void:
	var o := _offer([[BlockIds.STONE, 10], [ItemIds.SWORD, 1]], 30)
	var c := TradeRules.covered(o, _inv([[BlockIds.STONE, 4]]), 12)
	assert_eq(c.items, {BlockIds.STONE: 4})
	assert_eq(c.gold, 12)
	assert_true(TradeRules.same(o, _offer([[ItemIds.SWORD, 1], [BlockIds.STONE, 10]], 30)))
	assert_false(TradeRules.same(o, c))


func test_a_swap_moves_both_sides_at_once() -> void:
	var ia := _inv([[BlockIds.STONE, 20], [ItemIds.SWORD, 1]])
	var ib := _inv([[BlockIds.DIAMOND, 3]])
	var wa := Wallet.new(50)
	var wb := Wallet.new(10)
	var r := TradeRules.swap(ia, wa, _offer([[BlockIds.STONE, 15]], 20), ib, wb, _offer([[BlockIds.DIAMOND, 2]], 5))
	assert_true(r.ok)
	assert_eq(ia.count(BlockIds.STONE), 5)
	assert_eq(ia.count(BlockIds.DIAMOND), 2)
	assert_eq(ib.count(BlockIds.STONE), 15)
	assert_eq(ib.count(BlockIds.DIAMOND), 1)
	assert_eq(wa.balance, 35)
	assert_eq(wb.balance, 25)
	assert_eq(ia.count(ItemIds.SWORD), 1, "what was not offered stays")


func test_a_swap_never_copies_anything() -> void:
	var ia := _inv([[BlockIds.STONE, 20]])
	var ib := _inv([[BlockIds.STONE, 999]])
	var wa := Wallet.new(0)
	var wb := Wallet.new(0)
	var total := ia.count(BlockIds.STONE) + ib.count(BlockIds.STONE)
	var r := TradeRules.swap(ia, wa, _offer([[BlockIds.STONE, 20]]), ib, wb, _offer([[BlockIds.STONE, 999]]))
	assert_true(r.ok, "the same block both ways: each side's gives are taken before anything is added")
	assert_eq(ia.count(BlockIds.STONE) + ib.count(BlockIds.STONE), total)
	assert_eq(ia.count(BlockIds.STONE), 999)


func test_nothing_moves_when_one_side_no_longer_has_its_offer() -> void:
	var ia := _inv([[BlockIds.STONE, 3]])
	var ib := _inv([[BlockIds.DIAMOND, 3]])
	var wa := Wallet.new(5)
	var wb := Wallet.new(5)
	var r := TradeRules.swap(ia, wa, _offer([[BlockIds.STONE, 10]]), ib, wb, _offer([[BlockIds.DIAMOND, 1]]))
	assert_false(r.ok)
	assert_eq(r.error, "not_owned")
	assert_eq(r.side, 0, "it is about the first trader")
	r = TradeRules.swap(ia, wa, _offer([[BlockIds.STONE, 1]]), ib, wb, _offer([], 9))
	assert_eq([r.error, r.side], ["not_owned", 1], "gold counts too")
	assert_eq([ia.count(BlockIds.STONE), ib.count(BlockIds.DIAMOND), wa.balance, wb.balance], [3, 3, 5, 5])


func test_nothing_moves_when_a_bag_has_no_room() -> void:
	var ia := _inv([[BlockIds.STONE, 10]])
	var ib := _inv([[BlockIds.STONE, 995]])
	var r := TradeRules.swap(ia, Wallet.new(0), _offer([[BlockIds.STONE, 10]]), ib, Wallet.new(0), _offer([], 0))
	assert_false(r.ok)
	assert_eq([r.error, r.side, r.id], ["no_room", 1, BlockIds.STONE], "the second trader's bag is full of Stone")
	assert_eq([ia.count(BlockIds.STONE), ib.count(BlockIds.STONE)], [10, 995])
	r = TradeRules.swap(ia, Wallet.new(0), _offer([], 0), ib, Wallet.new(0), _offer([]))
	assert_eq(r.error, "empty", "nothing for nothing is no trade")
	var rich := Wallet.new(Wallet.MAX_GOLD)
	r = TradeRules.swap(ia, rich, _offer([], 0), ib, Wallet.new(100), _offer([], 50))
	assert_eq([r.error, r.side], ["gold_room", 0])


func test_a_present_one_way_is_fine() -> void:
	var ia := _inv([[ItemIds.SWORD, 1]])
	var ib := Inventory.new()
	assert_true(TradeRules.swap(ia, Wallet.new(0), _offer([[ItemIds.SWORD, 1]]), ib, Wallet.new(0), TradeRules.empty_offer()).ok)
	assert_eq(ib.count(ItemIds.SWORD), 1)


func test_under_13_players_trade_online_only_with_their_friends() -> void:
	var kid := AgeBand.UNDER_13
	var teen := AgeBand.TEEN_PLUS
	assert_eq(TradeRules.age_refusal(teen, teen, false, false, true), "", "13+ with anyone in the world")
	assert_eq(TradeRules.age_refusal(kid, teen, false, true, true), "friends_only")
	assert_eq(TradeRules.age_refusal(kid, teen, true, false, true), "", "on the child's own friends list")
	assert_eq(TradeRules.age_refusal(teen, kid, true, false, true), "friends_only", "either side")
	assert_eq(TradeRules.age_refusal(kid, kid, true, true, true), "")
	assert_eq(TradeRules.age_refusal(&"", teen, false, false, true), "friends_only", "no band counts as under 13")
	assert_eq(TradeRules.age_refusal(kid, kid, false, false, false), "", "LAN: together at home")


func test_the_chat_line_says_what_moved() -> void:
	var gave := _offer([[BlockIds.STONE, 10]], 5)
	var got := _offer([[ItemIds.SWORD_IRON, 1]])
	var line := TradeRules.log_line("Bob", gave, got)
	assert_eq(line, "You traded with Bob: you gave 10 Stone and 5 gold; you got 1 %s." % ItemIds.display_name(ItemIds.SWORD_IRON))
	assert_eq(TradeRules.describe(TradeRules.empty_offer()), "nothing")


func test_the_wire_form_round_trips() -> void:
	var o := _offer([[BlockIds.STONE, 10], [ItemIds.SWORD, 1]], 7)
	var w := TradeRules.to_wire(o)
	assert_true(w.items is Array)
	assert_true(TradeRules.same(TradeRules.clean_offer(w.items, w.gold), o))


func test_every_message_is_kind() -> void:
	for key: String in TradeRules.MESSAGES:
		var text := TradeRules.message(key, "Bob", BlockIds.STONE)
		assert_ne(text, "")
		assert_false(text.contains("%"), "%s fills its blanks" % key)
		for bad: String in ["hurry", "loser", "failed", "last chance"]:
			assert_false(text.to_lower().contains(bad))
