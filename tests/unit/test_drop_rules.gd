extends GutTest
## M3 Task 14b (spec §13.5): surprise drops as pure rules. A Party Piñata comes after at least 10 minutes of
## play since the last one (a little more, from the world's seed), never while one is still there; it lands
## 8-30 blocks from a player under its parachute; 3 hits burst it into supplies (blocks, a potion, ammo:
## never gold, the same for a given piñata). Supply balloons come in Survivor waves from wave 3: one drifts
## over the Totem and settles low beside it; popping it gives ammo and a potion.

const SEED := 20260924


func test_a_pinata_waits_at_least_10_minutes_of_play() -> void:
	for n in 20:
		var gap := DropRules.pinata_gap(SEED, n)
		assert_gte(gap, 600.0, "piñata %d" % n)
		assert_lte(gap, 600.0 + DropRules.PINATA_EXTRA)
		assert_false(DropRules.pinata_due(gap - 1.0, SEED, n, false))
		assert_true(DropRules.pinata_due(gap, SEED, n, false))
	assert_eq(DropRules.pinata_gap(SEED, 3), DropRules.pinata_gap(SEED, 3), "a world plays the same way")


func test_only_one_pinata_at_a_time() -> void:
	assert_false(DropRules.pinata_due(10000.0, SEED, 1, true), "one is still there")


func test_it_lands_8_to_30_blocks_from_a_player() -> void:
	var near := Vector3(100.5, 20, -40.5)
	for n in 10:
		for attempt in DropRules.PINATA_TRIES:
			var xz := DropRules.pinata_spot(SEED, n, near, attempt)
			var d := Vector2(xz.x - near.x, xz.y - near.z).length()
			assert_between(d, DropRules.PINATA_MIN_DISTANCE - 0.01, DropRules.PINATA_MAX_DISTANCE + 0.01)


func test_it_floats_down_slowly_then_rests_on_the_ground() -> void:
	var top := Vector3(3.5, 40.0, 3.5)
	var ground := 18.0
	assert_eq(DropRules.pinata_point(top, ground, 0.0).y, 40.0)
	var one := DropRules.pinata_point(top, ground, 1.0)
	assert_almost_eq(top.y - one.y, DropRules.PINATA_FALL, 0.01, "a slow parachute")
	assert_lte(DropRules.PINATA_FALL, 2.5)
	assert_false(DropRules.pinata_landed(top, ground, 1.0))
	var t := (top.y - ground) / DropRules.PINATA_FALL + 0.1
	assert_true(DropRules.pinata_landed(top, ground, t))
	assert_eq(DropRules.pinata_point(top, ground, t).y, ground)
	assert_eq(DropRules.pinata_point(top, ground, t + 100.0).y, ground, "it stays on the ground")
	assert_lt(Vector2(one.x - top.x, one.z - top.z).length(), 1.0, "it sways a little, no more")


func test_three_hits_burst_it_and_hits_count_apart() -> void:
	assert_eq(DropRules.PINATA_HITS, 3)
	assert_eq(DropRules.BALLOON_HITS, 1)
	assert_true(DropRules.hit_counts(-1.0, 5.0), "the first")
	assert_false(DropRules.hit_counts(5.0, 5.1), "a rocket's blast and its hit are one")
	assert_true(DropRules.hit_counts(5.0, 5.0 + DropRules.HIT_GAP))


func test_pinata_supplies_are_blocks_a_potion_and_ammo_never_gold() -> void:
	for n in 30:
		for survivor in [true, false]:
			var loot := DropRules.pinata_loot(LootRules.chest_key(SEED, Vector3i(n, 0, 0)), 1 + n % 4, survivor)
			assert_eq(int(loot.gold), 0, "never gold")
			var ids: Array = loot.items.map(func(e: Array) -> int: return int(e[0]))
			assert_true(ids.any(func(id: int) -> bool: return BlockIds.is_valid(id)), "blocks")
			assert_eq(ids.filter(func(id: int) -> bool: return PotionRules.is_potion(id)).size(), 1, "a potion")
			assert_gte(ids.filter(func(id: int) -> bool: return BlasterRules.is_ammo(id)).size(), 1, "ammo")
			for e: Array in loot.items:
				assert_gt(int(e[1]), 0)
	var key := LootRules.chest_key(SEED, Vector3i(7, 0, 0))
	assert_eq(DropRules.pinata_loot(key, 1, true), DropRules.pinata_loot(key, 1, true), "the same piñata, the same supplies")


func test_supply_balloons_only_in_survivor_waves_from_3() -> void:
	for n in [1, 2]:
		assert_false(DropRules.balloon_released(n, true), "wave %d" % n)
	for n in [3, 4, 9]:
		assert_true(DropRules.balloon_released(n, true), "wave %d" % n)
	assert_false(DropRules.balloon_released(5, false), "Sandbox waves: never (everything is free there)")


func test_the_balloon_drifts_over_the_totem_and_settles_low_beside_it() -> void:
	var totem := Vector3(10.5, 30.0, -4.5)
	var path := DropRules.balloon_path(totem, 1.2)
	var start: Vector3 = path.start
	assert_gt(Vector2(start.x - totem.x, start.z - totem.z).length(), 10.0, "it comes from afar")
	assert_gt(start.y, totem.y + 5.0, "high")
	var over := DropRules.balloon_point(path, DropRules.BALLOON_DRIFT)
	assert_lt(Vector2(over.x - totem.x, over.z - totem.z).length(), 0.6, "right over the Totem")
	var rest := DropRules.balloon_point(path, DropRules.BALLOON_DRIFT + DropRules.BALLOON_SETTLE + 1.0)
	assert_between(Vector2(rest.x - totem.x, rest.z - totem.z).length(), 2.0, 4.0, "beside it")
	assert_lte(rest.y - totem.y, 2.0, "low enough for a sword")
	assert_eq(DropRules.balloon_point(path, 999.0), rest, "and it waits there")


func test_a_balloon_gives_ammo_and_a_potion() -> void:
	for n in 20:
		var loot := DropRules.balloon_loot(LootRules.chest_key(SEED, Vector3i(n, 1, 0)))
		assert_eq(int(loot.gold), 0)
		var ids: Array = loot.items.map(func(e: Array) -> int: return int(e[0]))
		assert_eq(ids.filter(func(id: int) -> bool: return PotionRules.is_potion(id)).size(), 1)
		assert_gte(ids.filter(func(id: int) -> bool: return BlasterRules.is_ammo(id)).size(), 1)


func test_the_saved_clock_is_cleaned() -> void:
	assert_eq(DropRules.clean_save(null), {"clock": 0.0, "count": 0})
	assert_eq(DropRules.clean_save({"clock": 123.5, "count": 2}), {"clock": 123.5, "count": 2})
	assert_eq(DropRules.clean_save({"clock": "x", "count": -4}), {"clock": 0.0, "count": 0})
	assert_eq(DropRules.clean_save({"clock": INF, "count": 3.0}), {"clock": 0.0, "count": 3})
