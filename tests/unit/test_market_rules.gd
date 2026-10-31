extends GutTest
## Owner #37 (spec §14.23): market day. A Survivor world counts its days (a day begins at sunrise); every 7th day,
## starting with the world's 2nd, Nico the traveller's cart stands beside Tilly's stall from sunrise to sunset,
## with the same village blocks every time at fixed prices × 2^(u−1). No countdown, nothing gone for ever.

const TILLY := Vector3(20.5, 30.0, 4.5)


static func _flat(_x: int, _z: int) -> int:
	return 30


static func _dry(_x: int, _z: int) -> bool:
	return true


static func _no_trees(_x: int, _z: int) -> bool:
	return false


func test_a_new_day_begins_at_sunrise() -> void:
	assert_eq(MarketRules.sunrises(DayCycle.START, DayCycle.NOON), 0, "a morning goes on")
	assert_eq(MarketRules.sunrises(0.1, 0.2), 1, "the sun came up")
	assert_eq(MarketRules.sunrises(0.95, 0.05), 0, "past midnight, still dark")
	assert_eq(MarketRules.sunrises(0.95, DayCycle.SUNRISE), 1, "sleeping until sunrise starts the next day")
	assert_eq(MarketRules.sunrises(DayCycle.SUNRISE, 0.3), 0, "the sunrise already counted")
	assert_eq(MarketRules.sunrises(0.5, 0.5), 0, "a clock standing still")


func test_market_day_is_every_seventh_day_from_the_second() -> void:
	var days: Array[int] = []
	for d in range(1, 31):
		if MarketRules.is_market_day(d):
			days.append(d)
	assert_eq(days, [2, 9, 16, 23, 30] as Array[int])
	for start in range(1, 40):
		var n := 0
		for d in range(start, start + 7):
			n += 1 if MarketRules.is_market_day(d) else 0
		assert_eq(n, 1, "once in every in-game week (from day %d)" % start)
	assert_false(MarketRules.is_market_day(0))
	assert_false(MarketRules.is_market_day(-5))


func test_the_cart_stands_from_sunrise_to_sunset_of_market_day() -> void:
	assert_true(MarketRules.is_open(2, DayCycle.SUNRISE))
	assert_true(MarketRules.is_open(2, DayCycle.NOON))
	assert_false(MarketRules.is_open(2, DayCycle.SUNSET), "gone at sunset")
	assert_false(MarketRules.is_open(2, 0.05), "not in the night")
	assert_false(MarketRules.is_open(3, DayCycle.NOON), "not on other days")


func test_the_stock_is_fixed_and_rare() -> void:
	var stock := MarketRules.stock()
	assert_gt(stock.size(), 8)
	assert_eq(stock, MarketRules.stock(), "the same things every market day")
	for id in stock:
		assert_true(Inventory.ownable(id), "%d can be owned" % id)
		assert_false(ShopRules.for_sale(id), "%s: nobody else sells it" % ItemIds.display_name(id))
		assert_gt(MarketRules.price(id), 0)
		assert_gt(MarketRules.amount(id), 0)
		assert_eq(ShopRules.sell_price(id), 0, "never bought back (no loop can mint gold)")
	for id: int in [BlockIds.STONE_BRICK, BlockIds.ROOF_TILES, BlockIds.PLASTER, BlockIds.HAY, BlockIds.GLOW_MUSHROOM]:
		assert_has(stock, id)
	assert_false(MarketRules.sells(BlockIds.DIAMOND))
	assert_false(MarketRules.sells(ItemIds.SWORD))


func test_prices_are_fixed_and_scale_with_the_universe() -> void:
	var id := BlockIds.STONE_BRICK
	var base := MarketRules.price(id)
	for u in range(1, 6):
		assert_eq(MarketRules.price(id, u), base * UniverseRules.scale(u))
	assert_eq(MarketRules.price(BlockIds.DIAMOND), 0, "not sold at the market")


func test_buying_takes_the_gold_and_gives_the_blocks_all_or_nothing() -> void:
	var id := BlockIds.ROOF_TILES
	var wallet := Wallet.new(MarketRules.price(id) + 3)
	var inv := Inventory.new()
	var r := MarketRules.buy(id, wallet, inv)
	assert_true(r.ok)
	assert_eq(wallet.balance, 3)
	assert_eq(inv.count(id), MarketRules.amount(id))
	assert_eq(r.count, MarketRules.amount(id))
	var poor := Wallet.new(0)
	r = MarketRules.buy(id, poor, inv)
	assert_false(r.ok)
	assert_eq(r.error, "gold")
	assert_eq(inv.count(id), MarketRules.amount(id), "nothing moved")
	var full := Inventory.new()
	full.add(id, Inventory.MAX_COUNT)
	r = MarketRules.buy(id, Wallet.new(999), full)
	assert_eq(r.error, "full")
	r = MarketRules.buy(BlockIds.DIAMOND, Wallet.new(999), Inventory.new())
	assert_eq(r.error, "not_for_sale")


func test_the_cart_stands_beside_tillys_stall_on_the_ground() -> void:
	var spot := MarketRules.cart_spot(TILLY, 0.7, _flat, _dry, _no_trees, [])
	var pos: Vector3 = spot.pos
	var d := Vector2(pos.x - TILLY.x, pos.z - TILLY.z).length()
	assert_between(d, 3.0, 6.5, "beside the stall, not in it")
	assert_eq(pos.y, 30.0, "on the ground")
	assert_almost_eq(float(spot.yaw), 0.7, 0.001, "facing the way Tilly faces")
	assert_eq(MarketRules.cart_spot(TILLY, 0.7, _flat, _dry, _no_trees, []), spot, "the same every time")


func test_the_cart_keeps_clear_of_landmarks_water_and_trees() -> void:
	var first: Vector3 = MarketRules.cart_spot(TILLY, 0.0, _flat, _dry, _no_trees, []).pos
	var marks: Array[Vector3] = [first]
	var other: Vector3 = MarketRules.cart_spot(TILLY, 0.0, _flat, _dry, _no_trees, marks).pos
	assert_gte(Vector2(other.x - first.x, other.z - first.z).length(), MarketRules.CLEAR_OF, "clear of a landmark")
	var wet := func(x: int, z: int) -> bool: return Vector2i(x, z).distance_to(Vector2i(floori(first.x), floori(first.z))) > 2.0
	var dry_spot: Vector3 = MarketRules.cart_spot(TILLY, 0.0, _flat, wet, _no_trees, []).pos
	assert_gt(Vector2(dry_spot.x - first.x, dry_spot.z - first.z).length(), 2.0, "never in water")
	var slope := func(x: int, _z: int) -> int: return 30 + x
	var s: Dictionary = MarketRules.cart_spot(TILLY, 0.0, slope, _dry, _no_trees, [])
	assert_eq(float(s.pos.y), float(30 + floori(s.pos.x)), "on the ground even on a slope (the fallback)")


func test_a_saved_market_reads_back_and_broken_ones_start_at_day_one() -> void:
	assert_eq(MarketRules.clean({"day": 12}), {"day": 12})
	assert_eq(MarketRules.clean({"day": -3}), {"day": 1})
	assert_eq(MarketRules.clean({"day": "x"}), {"day": 1})
	assert_eq(MarketRules.clean(null), {"day": 1})
	assert_eq(MarketRules.clean({"day": 1e20}), {"day": MarketRules.MAX_DAY})


func test_the_market_words_never_rush() -> void:
	var words := MarketRules.ARRIVED + " " + MarketRules.SHOP_TITLE
	for bad: String in ["hurry", "only today", "last chance", "left", "before"]:
		assert_false(words.to_lower().contains(bad), "no pressure: %s" % bad)
