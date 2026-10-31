extends GutTest
## Owner #98: no other universe may be needed for the rocket. The jet and the rocket inventions need Kerosene (owner
## #78's inventions stay), which came only from the Sandstorm Desert's oil (universe 2, after the Golem). Now Tilly sells
## it in the first universe too (her HOME shelf, where a Survivor child already buys), dearer than she buys it back so no
## loop mints gold; the Desert's oil stays the free way.


func test_tilly_sells_kerosene_in_the_first_universe() -> void:
	assert_true(ShopRules.for_sale(BlockIds.KEROSENE, 1), "for sale in Green Meadows")
	assert_has(ShopRules.catalog(ShopRules.HOME, 1), BlockIds.KEROSENE)
	assert_gt(ShopRules.price(BlockIds.KEROSENE, 1), ShopRules.sell_price(BlockIds.KEROSENE, 1), "never mints gold")
	var need := int(InventionLine.needs_of(InventionLine.JET).get(&"kerosene", 0)) \
		+ int(InventionLine.needs_of(InventionLine.ROCKET).get(&"kerosene", 0))
	assert_eq(need, 4, "the jet's 2 and the rocket's 2")
	assert_lte(ShopRules.price(BlockIds.KEROSENE, 1) * need, 60, "a little gold, not a quest in another universe")


func test_the_invention_book_says_where_kerosene_comes_from() -> void:
	var hint := str((InventionLine.MATERIALS[&"kerosene"] as Dictionary).get("hint", ""))
	assert_string_contains(hint, "Tilly")
	assert_string_contains(hint, "Refinery", "the oil's free way stays")
