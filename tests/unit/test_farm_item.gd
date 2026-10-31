extends GutTest
## M3 Task 10: the Gold Farm is bought from Tilly (HOME section) as an item, FARM (491, from the lead's
## 491-494 for this task), and placed like a stamp. It is Survivor's only: never in the Sandbox palette's
## rows (not in ItemIds.ALL) and never given by /give; a bag holds one at most.


func test_the_farm_item_id() -> void:
	assert_eq(ItemIds.FARM, 491)
	assert_true(ItemIds.is_item(ItemIds.FARM))
	assert_true(ItemIds.is_hotbar_valid(ItemIds.FARM))
	assert_true(Inventory.ownable(ItemIds.FARM), "a Survivor bag can hold it")
	assert_false(BlockIds.is_valid(ItemIds.FARM))
	assert_false(ItemIds.is_stamp(ItemIds.FARM), "placed by the farm's own rules, not as blocks")


func test_it_is_in_no_palette_row() -> void:
	assert_false(ItemIds.ALL.has(ItemIds.FARM))
	for row: Array[int] in [ItemIds.MAGIC, ItemIds.TOOLS, ItemIds.ARMORY, ItemIds.TREASURES]:
		assert_false(row.has(ItemIds.FARM))
	assert_eq(ChatCommands.item_for_name("gold farm"), -1, "no /give")


func test_it_has_a_name_and_a_barn_icon_made_once() -> void:
	assert_eq(ItemIds.display_name(ItemIds.FARM), "Gold Farm")
	var icon := BlockIcons.icon(ItemIds.FARM)
	assert_not_null(icon)
	assert_same(BlockIcons.icon(ItemIds.FARM), icon)
	assert_eq(icon.get_size(), Vector2(32, 32))
	var img := icon.get_image()
	var red := 0
	var gold := 0
	for y in 32:
		for x in 32:
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.r > 0.6 and c.g < 0.35:
				red += 1
			if c.a > 0.5 and c.r > 0.85 and c.g > 0.7 and c.b < 0.4:
				gold += 1
	assert_gt(red, 60, "a red barn")
	assert_gt(gold, 8, "a gold coin")


func test_tilly_sells_one_farm_in_her_home_section() -> void:
	assert_true(ShopRules.catalog(ShopRules.HOME).has(ItemIds.FARM))
	assert_eq(ShopRules.price(ItemIds.FARM), FarmRules.PRICE)
	assert_eq(ShopRules.price(ItemIds.FARM, 2), FarmRules.price(2))
	assert_eq(ShopRules.amount(ItemIds.FARM), 1)
	assert_eq(ShopRules.sell_price(ItemIds.FARM), 0, "Tilly doesn't buy it back")
	var inv := Inventory.new()
	var wallet := Wallet.new(1000)
	var r := ShopRules.buy(ItemIds.FARM, wallet, inv)
	assert_true(r.ok)
	assert_eq(inv.count(ItemIds.FARM), 1)
	assert_eq(wallet.balance, 1000 - FarmRules.PRICE)
	assert_eq(ShopRules.buy_refusal(ItemIds.FARM, 1000, inv), "have_it", "one at a time")
	assert_true(ShopRules.one_only(ItemIds.FARM))
	assert_true(ShopRules.one_only(ItemIds.SWORD))
	assert_false(ShopRules.one_only(BlockIds.PLANKS))


func test_tillys_words_for_the_farm() -> void:
	assert_eq(ShopRules.message("farm_one"), FarmRules.message("farm_one"))
	assert_eq(ShopRules.message("farm_owner"), FarmRules.message("farm_owner"))
	assert_eq(ShopRules.done_message(true, ItemIds.FARM, 1, 150), "You got a Gold Farm!")
