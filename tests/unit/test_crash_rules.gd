extends GutTest
## Owner #106 ("when it crashes down on to earth, some parts break and have to rebuild it. But it's random. But not
## catastrophic like 1 block survived and 99% is damaged"): CrashRules, pure. A crash breaks a random share of the
## rocket's parts, between 15% and 35% (never fewer than 1, never more than 35%), seeded per crash so a test pins it;
## the capsule and the parts the crew needs break less often than engines, tanks and fins; only rocket parts break.
## The words never shame; a crash costs half the hearts where hearts count (never a knock-out, never a heal).


func _moon_plan() -> Dictionary:
	return RocketPlan.cells(MissionRules.for_world(SpaceRules.MOON), 1)


func test_a_crash_breaks_between_15_and_35_percent_of_the_parts() -> void:
	var rocket := _moon_plan()
	var n := rocket.size()
	assert_gt(n, 20, "Mission Control's Moon rocket")
	var seen := {}
	for s in 200:
		var d := CrashRules.damage(rocket, s)
		var k := int(d.count)
		assert_eq((d.broken as Dictionary).size(), k)
		assert_gte(float(k) / n, CrashRules.LEAST - 0.0001, "seed %d: at least 15%%" % s)
		assert_lte(float(k) / n, CrashRules.MOST + 0.0001, "seed %d: at most 35%%" % s)
		seen[k] = true
	assert_gt(seen.size(), 3, "random: different crashes break different amounts (%s)" % [seen.keys()])


func test_mission_controls_moon_rocket_loses_6_to_12_parts() -> void:
	var rocket := _moon_plan()
	var lo := 1 << 30
	var hi := 0
	var gold_lo := 1 << 30
	var gold_hi := 0
	for s in 1000:
		var d := CrashRules.damage(rocket, s)
		lo = mini(lo, int(d.count))
		hi = maxi(hi, int(d.count))
		gold_lo = mini(gold_lo, int(d.gold))
		gold_hi = maxi(gold_hi, int(d.gold))
	gut.p("Moon plan: %d parts, %d-%d broke, %d-%d gold to rebuild" % [rocket.size(), lo, hi, gold_lo, gold_hi])
	assert_eq(rocket.size(), 36)
	assert_eq([lo, hi], [6, 12])
	assert_lt(gold_hi, RocketPlan.gold(MissionRules.for_world(SpaceRules.MOON), 1), "never the whole rocket's price")


func test_never_fewer_than_one_part_and_never_more_than_35_percent() -> void:
	assert_eq(CrashRules.broken_count(1, 7), 1, "a single part: that one (never fewer than 1 wins)")
	assert_eq(CrashRules.broken_count(3, 7), 1)
	for s in 50:
		assert_between(CrashRules.broken_count(20, s), 3, 7, "20 parts: 3 (15%%) to 7 (35%%)")
		assert_between(CrashRules.broken_count(100, s), 15, 35)
	assert_eq(CrashRules.broken_count(0, 3), 0, "nothing to break")


func test_the_same_seed_breaks_the_same_parts() -> void:
	var rocket := _moon_plan()
	assert_eq(CrashRules.damage(rocket, 42), CrashRules.damage(rocket, 42), "seeded: a test can pin a crash")
	var differ := false
	for s in range(1, 20):
		if (CrashRules.damage(rocket, s).broken as Dictionary) != (CrashRules.damage(rocket, 0).broken as Dictionary):
			differ = true
	assert_true(differ, "another crash breaks other parts")


func test_the_broken_parts_are_the_rockets_own_cells() -> void:
	var rocket := _moon_plan()
	var d := CrashRules.damage(rocket, 5)
	for c: Vector3i in d.broken:
		assert_true(rocket.has(c), "a cell of the rocket")
		assert_eq(int(d.broken[c]), int(rocket[c]), "with its own part")
	assert_eq(d.parts, RocketParts.count(d.broken), "the counts per part")
	assert_eq(int(d.gold), RocketParts.cost(d.parts), "what rebuilding them costs")


func test_only_rocket_parts_break() -> void:
	var cells := {}
	for y in 10:
		cells[Vector3i(0, y, 0)] = BlockIds.FUEL_TANK
		cells[Vector3i(1, y, 0)] = BlockIds.STONE
	for s in 30:
		for c: Vector3i in CrashRules.damage(cells, s).broken:
			assert_eq(int(cells[c]), BlockIds.FUEL_TANK, "a stone is no rocket part")
	assert_between(int(CrashRules.damage(cells, 1).count), 2, 3, "15-35% of the 10 parts")


func test_the_crews_parts_break_less_often_than_engines_tanks_and_fins() -> void:
	var cells := {}
	var ids := [BlockIds.ROCKET_ENGINE, BlockIds.FUEL_TANK, BlockIds.ROCKET_FINS, BlockIds.CREW_CAPSULE,
		BlockIds.SERVICE_MODULE, BlockIds.HEAT_SHIELD]
	for i in ids.size():
		for k in 10:
			cells[Vector3i(i, k, 0)] = ids[i]
	var broke := {}
	for s in 300:
		for c: Vector3i in CrashRules.damage(cells, s).broken:
			broke[cells[c]] = int(broke.get(cells[c], 0)) + 1
	var sturdy := int(broke.get(BlockIds.CREW_CAPSULE, 0)) + int(broke.get(BlockIds.SERVICE_MODULE, 0)) \
		+ int(broke.get(BlockIds.HEAT_SHIELD, 0))
	var fragile := int(broke.get(BlockIds.ROCKET_ENGINE, 0)) + int(broke.get(BlockIds.FUEL_TANK, 0)) \
		+ int(broke.get(BlockIds.ROCKET_FINS, 0))
	assert_gt(fragile, sturdy * 2, "engines, tanks and fins break far more often (%d vs %d)" % [fragile, sturdy])
	assert_gt(sturdy, 0, "but a capsule can break too")
	assert_lt(CrashRules.weight(BlockIds.CREW_CAPSULE), CrashRules.weight(BlockIds.ROCKET_ENGINE))
	assert_lt(CrashRules.weight(BlockIds.LANDING_LEGS), CrashRules.weight(BlockIds.FUEL_TANK))


func test_the_board_says_what_broke_and_the_gold_to_rebuild() -> void:
	assert_eq(CrashRules.words(9, 120), "Your rocket crashed: 9 parts broke. Rebuild them: 120 gold.")
	assert_eq(CrashRules.words(1, 25), "Your rocket crashed: 1 part broke. Rebuild it: 25 gold.")
	assert_string_contains(CrashRules.words(4, 0), "spare parts")
	assert_eq(CrashRules.rebuild_gold({BlockIds.ROCKET_ENGINE: 3, BlockIds.FUEL_TANK: 4},
		{BlockIds.ROCKET_ENGINE: 1}), 2 * RocketParts.price(BlockIds.ROCKET_ENGINE) + 4 * RocketParts.price(BlockIds.FUEL_TANK),
		"only what the child does not have yet")


func test_a_crash_leaves_half_the_hearts_never_a_knock_out_never_a_heal() -> void:
	assert_eq(CrashRules.hearts_after(20, 20), 10, "full: half")
	assert_eq(CrashRules.hearts_after(15, 20), 10)
	assert_eq(CrashRules.hearts_after(6, 20), 6, "never a heal")
	assert_eq(CrashRules.hearts_after(1, 20), 1, "never a knock-out")
	assert_eq(CrashRules.hearts_after(19, 19), 10, "half, rounded up")


func test_the_words_are_kind() -> void:
	var all: Array[String] = [CrashRules.words(9, 120), CrashRules.words(2, 0), CrashRules.HEARTS_WORDS,
		CrashRules.SANDBOX_WORDS, CrashRules.FACT]
	for w in all:
		for bad in ["fail", "loser", "your fault", "stupid", "bad pilot", "game over"]:
			assert_false(w.to_lower().contains(bad), "\"%s\" says %s" % [w, bad])
	assert_string_contains(CrashRules.FACT, "Beresheet")
	assert_string_contains(CrashRules.FACT, "2019")
	assert_string_contains(CrashRules.FACT, "Luna 25")
	assert_string_contains(CrashRules.FACT, "2023")
