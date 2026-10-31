extends GutTest
## Owner #37 (spec §14.23): finding Tilly (MORE → SHOP) and the helpers' stands. The SHOP card points at the
## nearest full shop (Tilly's stall or a villager who trades) with the distance and the way; the shop opens by itself
## once the child is there; the first-time tip comes once per profile, in Survivor. Each helper of universes 2–4
## keeps a stand with the universe's own things beside them, on the ground.


static func _flat(_x: int, _z: int) -> int:
	return 20


static func _dry(_x: int, _z: int) -> bool:
	return true


static func _no_trees(_x: int, _z: int) -> bool:
	return false


func test_the_nearest_shop_is_tilly_or_a_nearer_villager() -> void:
	var tilly := Vector3(12, 20, 0)
	var villager := Vector3(300, 20, 0)
	var shops: Array = [{"pos": tilly, "what": "Tilly"}, {"pos": villager, "what": "Rosa"}]
	assert_eq(ShopGuide.nearest(shops, Vector3.ZERO).what, "Tilly")
	assert_eq(ShopGuide.nearest(shops, Vector3(290, 20, 0)).what, "Rosa")
	assert_true(ShopGuide.nearest([], Vector3.ZERO).is_empty())
	assert_true(ShopGuide.nearest([{"pos": Vector3.INF, "what": "x"}], Vector3.ZERO).is_empty())


func test_the_way_and_the_distance() -> void:
	var w := ShopGuide.way(Vector3(0, 20, 0), 0.0, Vector3(0, 20, -42))
	assert_eq(w.distance, 42)
	assert_almost_eq(float(w.angle), 0.0, 0.001, "straight ahead")
	w = ShopGuide.way(Vector3(0, 20, 0), 0.0, Vector3(10, 20, 0))
	assert_almost_eq(float(w.angle), PI / 2.0, 0.001, "to the right")
	assert_eq(ShopGuide.distance_words(42), "42 m")


func test_the_shop_opens_once_the_child_is_there() -> void:
	var tilly := Vector3(12, 20, 0)
	assert_true(ShopGuide.there(tilly + Vector3(0, 1.6, -3), tilly))
	assert_false(ShopGuide.there(tilly + Vector3(0, 1.6, -(TraderRules.TAP_REACH + 1)), tilly))
	assert_false(ShopGuide.there(Vector3.INF, tilly))


func test_the_first_time_tip_comes_once_per_profile_in_survivor() -> void:
	var seen: Array[String] = []
	assert_true(ShopGuide.wants_tip(seen, ModeRules.SURVIVOR))
	assert_false(ShopGuide.wants_tip(seen, ModeRules.SANDBOX), "no shop in the Sandbox")
	assert_false(ShopGuide.wants_tip(seen, ModeRules.WAVE))
	seen.append(ShopGuide.TIP)
	assert_false(ShopGuide.wants_tip(seen, ModeRules.SURVIVOR), "once")


func test_every_universe_helper_keeps_a_stand() -> void:
	assert_false(StandRules.has_stand(1), "Green Meadows' stand is Tilly's stall")
	for u in [2, 3, 4]:
		assert_true(StandRules.has_stand(u), "universe %d" % u)
	for u in range(2, UniverseRegistry.size() + 1):
		var helper := QuestRules.giver_in(u)
		assert_eq(StandRules.has_stand(u), helper != &"" and not UniverseRegistry.trader_stock(u).is_empty(),
			"universe %d: a stand exactly where a helper stands" % u)
		for id in StandRules.stock(u):
			assert_true(UniverseRegistry.trader_stock(u).has(id), "the universe's own things")
			assert_gt(ShopRules.price(id, u), 0, "at Tilly's prices of that universe")
	assert_eq(StandRules.giver_in(2), &"zara")
	assert_eq(StandRules.title(2), "Zara's stand")
	assert_eq(StandRules.title(3), "Bram's stand")
	assert_eq(StandRules.title(4), "Mimi's stand")


func test_the_stand_stands_beside_the_helper_on_the_ground() -> void:
	var helper := Vector3(30.5, 20.0, 10.5)
	var spot := StandRules.stand_spot(helper, 0.4, _flat, _dry, _no_trees)
	var pos: Vector3 = spot.pos
	var d := Vector2(pos.x - helper.x, pos.z - helper.z).length()
	assert_between(d, 1.8, 3.6, "beside, not on top of the helper")
	assert_eq(pos.y, 20.0)
	assert_almost_eq(float(spot.yaw), 0.4, 0.001, "facing the way the helper faces")
	var steps := func(x: int, _z: int) -> int: return 20 if x < 31 else 25
	var s: Dictionary = StandRules.stand_spot(helper, 0.0, steps, _dry, _no_trees)
	assert_lt(float(s.pos.x), 31.0, "on the helper's level, not up a cliff")
	var dry_on_the_left := func(x: int, _z: int) -> bool: return x < 31
	s = StandRules.stand_spot(helper, 0.0, _flat, dry_on_the_left, _no_trees)
	assert_lt(float(s.pos.x), 31.0, "never in water (the water is on the helper's right)")
