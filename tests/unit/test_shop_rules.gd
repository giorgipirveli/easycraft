extends GutTest
## M2 Task 7: Tilly's price table (spec §12.7) and trades against a Wallet and an Inventory.


func test_tool_tiers_cost_5_30_120_400_1200() -> void:
	for line: Array in [[ItemIds.SWORD, ItemIds.SWORD_STONE, ItemIds.SWORD_IRON, ItemIds.SWORD_CRYSTAL, ItemIds.SWORD_COSMIC],
			[ItemIds.BOW, ItemIds.BOW_STONE, ItemIds.BOW_IRON, ItemIds.BOW_CRYSTAL, ItemIds.BOW_COSMIC],
			[ItemIds.PICKAXE, ItemIds.PICKAXE_STONE, ItemIds.PICKAXE_IRON, ItemIds.PICKAXE_CRYSTAL, ItemIds.PICKAXE_COSMIC],
			[ItemIds.AXE, ItemIds.AXE_STONE, ItemIds.AXE_IRON, ItemIds.AXE_CRYSTAL, ItemIds.AXE_COSMIC],
			[ItemIds.SHIELD_WOOD, ItemIds.SHIELD_STONE, ItemIds.SHIELD_IRON, ItemIds.SHIELD_CRYSTAL, ItemIds.SHIELD_COSMIC]]:
		var prices: Array[int] = []
		for id: int in line:
			prices.append(ShopRules.price(id))
			assert_eq(ShopRules.amount(id), 1, "one tool per purchase")
			assert_true(ShopRules.is_tool_item(id))
			assert_eq(ShopRules.base_tool(id), line[0])
		assert_eq(prices, [5, 30, 120, 400, 1200] as Array[int], ItemIds.display_name(line[0]))


func test_spear_and_mace_are_priced_like_the_other_tools_once_task_6_adds_them() -> void:
	var ids: Dictionary = (ItemIds as GDScript).get_script_constant_map()
	if not ids.has("SPEAR"):
		pass_test("Task 6 not merged here: the spear and mace lines are found by name when it is")
		return
	for line_name: String in ["SPEAR", "MACE"]:
		var prices: Array[int] = []
		for suffix: String in ["", "_STONE", "_IRON", "_CRYSTAL", "_COSMIC"]:
			prices.append(ShopRules.price(int(ids[line_name + suffix])))
		assert_eq(prices, [5, 30, 120, 400, 1200] as Array[int], line_name)


func test_potions_cost_25_40_30() -> void:
	assert_eq(ShopRules.price(ItemIds.POTION_JUMP), 25)
	assert_eq(ShopRules.price(ItemIds.POTION_INVIS), 40)
	assert_eq(ShopRules.price(ItemIds.POTION_SPEED), 30)
	assert_false(ShopRules.is_tool_item(ItemIds.POTION_JUMP), "potions stack")


func test_home_and_defense_prices() -> void:
	var expected := {BlockIds.BED: 20, BlockIds.LANTERN: 5, BlockIds.DOOR: 10, BlockIds.SPIKE_TRAP: 15,
		BlockIds.BARREL: 10, BlockIds.CLOSET: 20, BlockIds.BUSH: 3}
	for id: int in expected:
		assert_eq(ShopRules.price(id), expected[id], BlockIds.display_name(id))
		assert_eq(ShopRules.amount(id), 2 if id == BlockIds.DOOR else 1, BlockIds.display_name(id))


func test_building_blocks_are_four_for_one_gold() -> void:
	for id: int in [BlockIds.DIRT, BlockIds.STONE, BlockIds.PLANKS, BlockIds.GLASS, BlockIds.BRICK, BlockIds.RED, BlockIds.LOG]:
		assert_eq(ShopRules.price(id), 1, BlockIds.display_name(id))
		assert_eq(ShopRules.amount(id), 4)


func test_ores_water_bedrock_and_magic_are_not_sold() -> void:
	for id: int in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.CRYSTAL,
			BlockIds.WATER, BlockIds.BEDROCK, BlockIds.AIR, BlockIds.DOOR_OPEN, ItemIds.WAND, ItemIds.STAMP_HOUSE, 9999, -1]:
		assert_eq(ShopRules.price(id), 0, "id %d" % id)
		assert_false(ShopRules.for_sale(id))


func test_sell_prices_coal_1_iron_3_gold_8_crystal_12_diamond_20() -> void:
	assert_eq(ShopRules.sell_price(BlockIds.COAL), 1)
	assert_eq(ShopRules.sell_price(BlockIds.IRON), 3)
	assert_eq(ShopRules.sell_price(BlockIds.GOLD), 8)
	assert_eq(ShopRules.sell_price(BlockIds.CRYSTAL), 12)
	assert_eq(ShopRules.sell_price(BlockIds.DIAMOND), 20)
	for id: int in [BlockIds.DIRT, BlockIds.STONE, BlockIds.PLANKS, BlockIds.LANTERN, ItemIds.SWORD, ItemIds.POTION_JUMP]:
		assert_eq(ShopRules.sell_price(id), 0, "others are not sellable: id %d" % id)


func test_nothing_can_be_bought_cheaper_than_it_sells_so_gold_is_never_minted() -> void:
	var checked := 0
	for id in range(-1, 256):
		if ShopRules.sell_price(id) > 0:
			checked += 1
			var unit_price := float(ShopRules.price(id)) / ShopRules.amount(id)
			assert_true(ShopRules.price(id) == 0 or unit_price >= ShopRules.sell_price(id), "id %d" % id)
	assert_eq(checked, 5, "the five ores")


func test_catalog_sections_list_only_things_the_inventory_can_hold() -> void:
	var all: Array[int] = []
	for section: StringName in ShopRules.SECTIONS:
		for id in ShopRules.catalog(section):
			assert_true(ShopRules.for_sale(id), "id %d" % id)
			assert_true(Inventory.ownable(id), "id %d" % id)
			assert_does_not_have(all, id, "listed once")
			all.append(id)
	assert_has(ShopRules.catalog(ShopRules.HOME), BlockIds.LANTERN)
	assert_has(ShopRules.catalog(ShopRules.HOME), BlockIds.BED)
	assert_has(ShopRules.catalog(ShopRules.BLOCKS), BlockIds.PLANKS)
	assert_has(ShopRules.catalog(ShopRules.TOOLS), ItemIds.SWORD)
	# Tier and potion ids become items (with icons) in Task 6; until then they are not listed.
	assert_eq(ShopRules.catalog(ShopRules.TOOLS).has(ItemIds.SWORD_IRON), Inventory.ownable(ItemIds.SWORD_IRON))
	assert_eq(ShopRules.catalog(ShopRules.POTIONS).has(ItemIds.POTION_SPEED), Inventory.ownable(ItemIds.POTION_SPEED))


func test_buying_takes_the_gold_and_gives_the_thing() -> void:
	var wallet := Wallet.new(12)
	var inv := Inventory.new()
	var r := ShopRules.buy(BlockIds.LANTERN, wallet, inv)
	assert_true(r.ok)
	assert_eq(wallet.balance, 7)
	assert_eq(inv.count(BlockIds.LANTERN), 1)
	assert_eq([r.gold, r.id, r.count], [5, BlockIds.LANTERN, 1])
	r = ShopRules.buy(BlockIds.PLANKS, wallet, inv)
	assert_true(r.ok)
	assert_eq(wallet.balance, 6)
	assert_eq(inv.count(BlockIds.PLANKS), 4, "building blocks come four at a time")


func test_buying_without_enough_gold_changes_nothing() -> void:
	var wallet := Wallet.new(19)
	var inv := Inventory.new()
	var r := ShopRules.buy(BlockIds.BED, wallet, inv)
	assert_false(r.ok)
	assert_eq(r.error, "gold")
	assert_eq(wallet.balance, 19)
	assert_false(inv.has(BlockIds.BED))


func test_buying_into_a_full_stack_changes_nothing() -> void:
	var wallet := Wallet.new(100)
	var inv := Inventory.new()
	inv.add(BlockIds.PLANKS, Inventory.MAX_COUNT - 2)
	var r := ShopRules.buy(BlockIds.PLANKS, wallet, inv)
	assert_false(r.ok, "four would not fit: all or nothing")
	assert_eq(r.error, "full")
	assert_eq(wallet.balance, 100)
	assert_eq(inv.count(BlockIds.PLANKS), Inventory.MAX_COUNT - 2)


func test_a_tool_you_already_have_is_not_sold_twice() -> void:
	var wallet := Wallet.new(100)
	var inv := Inventory.starter_kit()
	var r := ShopRules.buy(ItemIds.SWORD, wallet, inv)
	assert_false(r.ok)
	assert_eq(r.error, "have_it")
	assert_eq(wallet.balance, 100)
	assert_true(ShopRules.buy(ItemIds.BOW, wallet, inv).ok)
	assert_eq(wallet.balance, 95)


func test_things_that_are_not_for_sale_are_refused() -> void:
	var wallet := Wallet.new(100)
	var inv := Inventory.new()
	for id: int in [BlockIds.DIAMOND, ItemIds.WAND, 9999]:
		var r := ShopRules.buy(id, wallet, inv)
		assert_false(r.ok)
		assert_eq(r.error, "not_for_sale")
	assert_eq(wallet.balance, 100)
	assert_eq(inv.ids(), [] as Array[int])


func test_selling_gives_gold_and_takes_the_blocks() -> void:
	var wallet := Wallet.new(0)
	var inv := Inventory.new()
	inv.add(BlockIds.DIAMOND, 3)
	var r := ShopRules.sell(BlockIds.DIAMOND, 2, wallet, inv)
	assert_true(r.ok)
	assert_eq(wallet.balance, 40)
	assert_eq(inv.count(BlockIds.DIAMOND), 1)
	assert_eq([r.gold, r.id, r.count], [40, BlockIds.DIAMOND, 2])


func test_selling_what_you_do_not_have_or_what_tilly_does_not_buy_is_refused() -> void:
	var wallet := Wallet.new(5)
	var inv := Inventory.new()
	inv.add(BlockIds.COAL, 2)
	inv.add(BlockIds.DIRT, 10)
	assert_eq(ShopRules.sell(BlockIds.COAL, 3, wallet, inv).error, "none", "only two")
	assert_eq(ShopRules.sell(BlockIds.COAL, 0, wallet, inv).error, "none")
	assert_eq(ShopRules.sell(BlockIds.COAL, -4, wallet, inv).error, "none", "a negative count would mint blocks")
	assert_eq(ShopRules.sell(BlockIds.IRON, 1, wallet, inv).error, "none")
	assert_eq(ShopRules.sell(BlockIds.DIRT, 1, wallet, inv).error, "not_sellable")
	assert_eq(wallet.balance, 5)
	assert_eq(inv.count(BlockIds.COAL), 2)
	assert_eq(inv.count(BlockIds.DIRT), 10)


func test_the_sell_list_is_what_you_own_that_tilly_buys() -> void:
	var inv := Inventory.new()
	inv.add(BlockIds.DIRT, 10)
	inv.add(BlockIds.GOLD, 1)
	inv.add(BlockIds.COAL, 4)
	assert_eq(ShopRules.sellable(inv), [BlockIds.COAL, BlockIds.GOLD] as Array[int], "in price order, cheapest first")


func test_a_done_trade_says_what_happened() -> void:
	assert_eq(ShopRules.done_message(true, BlockIds.PLANKS, 4, 1), "You got 4 Planks!")
	assert_eq(ShopRules.done_message(true, ItemIds.BOW, 1, 5), "You got a Bow!")
	assert_eq(ShopRules.done_message(false, BlockIds.DIAMOND, 2, 40), "Sold! +40 gold")


func test_every_refusal_has_a_friendly_message() -> void:
	for key: String in ["gold", "full", "have_it", "not_for_sale", "not_sellable", "none", "too_far", "survivor_only"]:
		assert_ne(ShopRules.message(key), "", key)


## Merge of Tasks 7 and 16: treasure is only ever found — Tilly never sells it or buys it.
func test_treasure_only_things_are_never_sold_or_bought() -> void:
	for id: int in LootRules.TREASURE_ONLY:
		assert_false(ShopRules.for_sale(id), "not for sale: %d" % id)
		assert_eq(ShopRules.sell_price(id), 0, "not bought: %d" % id)

## M2 Task 8: a doorway is two doors stacked, so Tilly sells doors in pairs: one doorway for the spec's
## 10 gold. They go into the inventory as blocks you place (and get back when you break them).
func test_doors_come_in_pairs_for_a_doorway() -> void:
	var wallet := Wallet.new(25)
	var inv := Inventory.new()
	var r := ShopRules.buy(BlockIds.DOOR, wallet, inv)
	assert_true(r.ok)
	assert_eq(inv.count(BlockIds.DOOR), 2)
	assert_eq(wallet.balance, 15)
	assert_eq(ShopRules.done_message(true, BlockIds.DOOR, 2, 10), "You got 2 Doors!")
	for id in [BlockIds.SPIKE_TRAP, BlockIds.LANTERN]:
		assert_true(ShopRules.buy(id, Wallet.new(99), inv).ok, BlockIds.display_name(id))
		assert_eq(inv.count(id), 1)
