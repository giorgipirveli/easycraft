extends GutTest
## M3 Task 5 (spec §14.1): Tilly's prices scale × 2^(u−1) in universe u, buying and selling alike (so no
## loop mints gold in any universe), and each universe's descriptor adds its own local things to her shop.

const FAKE := preload("res://tests/fakes/fake_universe.gd")


func after_each() -> void:
	UniverseRegistry.reset()


func test_prices_double_with_every_universe() -> void:
	for u in range(1, 5):
		var k := UniverseRules.scale(u)
		assert_eq(ShopRules.price(ItemIds.PICKAXE_STONE, u), 30 * k, "stone pickaxe, universe %d" % u)
		assert_eq(ShopRules.price(BlockIds.LANTERN, u), 5 * k)
		assert_eq(ShopRules.price(BlockIds.PLANKS, u), 1 * k, "building blocks: 4 for 1 gold in Green Meadows")
		assert_eq(ShopRules.sell_price(BlockIds.DIAMOND, u), 20 * k, "selling scales too")
	assert_eq(ShopRules.price(ItemIds.PICKAXE_STONE), 30, "universe 1 when not said")
	assert_eq(ShopRules.price(BlockIds.BEDROCK, 3), 0, "not for sale stays not for sale")


func test_buying_never_costs_less_than_selling_pays_in_any_universe() -> void:
	UniverseRegistry.use(2, FAKE.new())   # sells coal, which Tilly also buys
	var checked := 0
	for u in range(1, 5):
		for id in range(0, 256):
			if ShopRules.sell_price(id, u) > 0 and ShopRules.price(id, u) > 0:
				var unit := float(ShopRules.price(id, u)) / ShopRules.amount(id)
				assert_gte(unit, float(ShopRules.sell_price(id, u)), "id %d universe %d" % [id, u])
				checked += 1
	assert_gt(checked, 0, "a local thing Tilly also buys was checked")


func test_a_trade_in_universe_2_moves_twice_the_gold() -> void:
	var wallet := Wallet.new(100)
	var inv := Inventory.new()
	var r := ShopRules.buy(BlockIds.LANTERN, wallet, inv, 2)
	assert_true(r.ok)
	assert_eq(r.gold, 10)
	assert_eq(wallet.balance, 90)
	assert_eq(ShopRules.buy_refusal(ItemIds.PICKAXE_STONE, 59, inv, 2), "gold", "60 in the desert")
	assert_eq(ShopRules.buy_refusal(ItemIds.PICKAXE_STONE, 60, inv, 2), "")
	inv.add(BlockIds.GOLD, 2)
	var s := ShopRules.sell(BlockIds.GOLD, 2, wallet, inv, 2)
	assert_eq(s.gold, 32)
	assert_eq(wallet.balance, 90 + 32)


func test_a_universe_adds_its_local_things_to_the_shop() -> void:
	UniverseRegistry.use(2, FAKE.new())   # trader_stock {COAL: 2}
	var stock: Dictionary = FAKE.new().trader_stock
	var id: int = stock.keys()[0]
	assert_true(ShopRules.catalog(ShopRules.BLOCKS, 2).has(id), "in the desert's shop")
	assert_eq(ShopRules.price(id, 2), UniverseRules.price(stock[id], 2), "its own price, scaled")
	assert_eq(ShopRules.catalog(ShopRules.BLOCKS, 2).count(id), 1, "listed once")
	var r := ShopRules.buy(id, Wallet.new(100), Inventory.new(), 2)
	assert_true(r.ok)
	assert_eq(r.gold, 4)
	assert_eq(r.count, 1, "one local thing per purchase")


func test_local_things_stay_in_their_universe() -> void:
	UniverseRegistry.use(2, FAKE.new())
	UniverseRegistry.use(3, null)
	assert_eq(ShopRules.catalog(ShopRules.BLOCKS, 1), ShopRules.catalog(ShopRules.BLOCKS), "Green Meadows' shop is M2's")
	assert_eq(ShopRules.catalog(ShopRules.BLOCKS, 3), ShopRules.catalog(ShopRules.BLOCKS), "a missing universe adds nothing")
