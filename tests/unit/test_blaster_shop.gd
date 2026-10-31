extends GutTest
## M3 Task 14b: Tilly sells the blasters (one of each, by rarity) and their ammo in packs, in her TOOLS
## section, at fixed prices × 2^(u−1) per universe like everything she sells.


func test_tilly_sells_every_blaster_and_its_ammo_in_the_tools_section() -> void:
	var tools := ShopRules.catalog(ShopRules.TOOLS)
	for id in ItemIds.BLASTERS + ItemIds.AMMO:
		assert_true(tools.has(id), ItemIds.display_name(id))
		assert_true(ShopRules.for_sale(id))
		assert_eq(ShopRules.price(id), BlasterRules.shop_price(id))
		assert_eq(ShopRules.price(id, 3), BlasterRules.shop_price(id) * 4, "× 2^(u−1)")
	assert_eq(ShopRules.amount(ItemIds.FOAM_DARTS), BlasterRules.pack(ItemIds.FOAM_DARTS))
	assert_eq(ShopRules.amount(ItemIds.FOAM_BLASTER), 1)


func test_nobody_needs_two_of_a_blaster_but_ammo_is_bought_again_and_again() -> void:
	var wallet := Wallet.new(1000)
	var inv := Inventory.new()
	var r := ShopRules.buy(ItemIds.FOAM_BLASTER, wallet, inv)
	assert_true(r.ok)
	assert_eq(ShopRules.buy(ItemIds.FOAM_BLASTER, wallet, inv).error, "have_it")
	assert_true(ShopRules.buy(ItemIds.FOAM_DARTS, wallet, inv).ok)
	assert_true(ShopRules.buy(ItemIds.FOAM_DARTS, wallet, inv).ok)
	assert_eq(inv.count(ItemIds.FOAM_DARTS), BlasterRules.pack(ItemIds.FOAM_DARTS) * 2)
	assert_eq(ShopRules.done_message(true, ItemIds.FOAM_DARTS, 20, 5), "You got 20 Foam Darts!")


func test_tilly_never_buys_them_back() -> void:
	for id in ItemIds.BLASTERS + ItemIds.AMMO:
		assert_eq(ShopRules.sell_price(id), 0, "no loop can mint gold")
