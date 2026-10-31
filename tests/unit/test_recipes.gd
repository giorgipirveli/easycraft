extends GutTest
## Crafting's recipe table (owner feedback #34, spec §12.19): one table, validated. Every result and
## ingredient is a real block or item a bag can hold, every count is positive, the recipe graph has no
## loops (nothing is made from nothing), and no result sells to Tilly for more than its ingredients and
## fuel cost from her (crafting never makes gold). Never gold, never random.


func test_about_twenty_five_recipes_with_unique_ids() -> void:
	assert_eq(Recipes.LIST.size(), 63)   # spec §23: the lab bench; §21d: five rocket parts; §26: ten refining steps;
	# §26.5: seventeen steps of living off the land on the Moon and Mars; owner #110: the xylophone and the bongos
	var seen := {}
	for r: Dictionary in Recipes.LIST:
		assert_false(seen.has(r.id), "twice: %s" % r.id)
		seen[r.id] = true
		assert_eq(Recipes.find(r.id), r)
	assert_eq(Recipes.find(&"no_such_thing"), {})


func test_the_table_is_valid() -> void:
	assert_eq(Recipes.problems(Recipes.LIST), [] as Array[String])


func test_the_validator_catches_broken_recipes() -> void:
	var broken := [
		{"id": &"a", "at": Recipes.HAND, "needs": {BlockIds.LOG: 1}, "makes": 9999, "count": 1},
		{"id": &"b", "at": Recipes.HAND, "needs": {BlockIds.LOG: 0}, "makes": BlockIds.PLANKS, "count": 1},
		{"id": &"c", "at": Recipes.HAND, "needs": {}, "makes": BlockIds.PLANKS, "count": 1},
		{"id": &"d", "at": &"cauldron", "needs": {BlockIds.LOG: 1}, "makes": BlockIds.PLANKS, "count": 1},
		{"id": &"e", "at": Recipes.HAND, "needs": {BlockIds.BEDROCK: 1}, "makes": BlockIds.PLANKS, "count": 1},
		{"id": &"f", "at": Recipes.HAND, "needs": {BlockIds.LOG: 1}, "makes": BlockIds.PLANKS, "count": 0},
	]
	assert_eq(Recipes.problems(broken).size(), 6, "one problem each")


func test_no_loops_so_nothing_comes_from_nothing() -> void:
	assert_false(Recipes.has_loop(Recipes.LIST))
	var loop := [
		{"id": &"x", "at": Recipes.HAND, "needs": {BlockIds.LOG: 1}, "makes": BlockIds.PLANKS, "count": 4},
		{"id": &"y", "at": Recipes.HAND, "needs": {BlockIds.PLANKS: 1}, "makes": BlockIds.LOG, "count": 1},
	]
	assert_true(Recipes.has_loop(loop), "logs to planks to logs")
	assert_false(Recipes.problems(loop).is_empty())
	for r: Dictionary in Recipes.LIST:
		assert_false((r.needs as Dictionary).has(r.makes), "%s makes one of its own ingredients" % r.id)


## Only coal (charcoal) is a result Tilly buys: 3 logs and a log to burn cost 1 gold (logs stay 4 a gold in
## every game), coal sells for 1.
func test_crafting_never_makes_gold_at_tillys() -> void:
	var checked := 0
	for r: Dictionary in Recipes.LIST:
		var sells := ShopRules.sell_price(r.makes) * int(r.count)
		if sells <= 0:
			continue
		for g: StringName in SurvivorGames.CHOICES:
			var cost := 0.0
			var buyable := true
			var needs: Dictionary = (r.needs as Dictionary).duplicate()
			if r.at == Recipes.FURNACE:
				needs[BlockIds.LOG] = int(needs.get(BlockIds.LOG, 0)) + 1   # the cheapest fuel Tilly sells
			for id: int in needs:
				if not ShopRules.for_sale(id):
					buyable = false
					break
				cost += float(ShopRules.price(id, 1, g)) / ShopRules.amount(id, g) * int(needs[id])
			if buyable:
				assert_gte(cost, float(sells), "%s in %s" % [r.id, g])
				checked += 1
	assert_gt(checked, 0, "charcoal is checked")


func test_by_hand_logs_planks_sticks_and_the_table() -> void:
	var planks := Recipes.find(&"planks")
	assert_eq(planks.at, Recipes.HAND)
	assert_eq(planks.needs, {BlockIds.LOG: 1})
	assert_eq([planks.makes, planks.count], [BlockIds.PLANKS, 4])
	var sticks := Recipes.find(&"sticks")
	assert_eq(sticks.needs, {BlockIds.PLANKS: 2})
	assert_eq([sticks.makes, sticks.count], [ItemIds.STICK, 4])
	var table := Recipes.find(&"crafting_table")
	assert_eq(table.at, Recipes.HAND)
	assert_eq(table.needs, {BlockIds.PLANKS: 4})
	assert_eq(table.makes, BlockIds.CRAFTING_TABLE)
	var hand := 0
	for r: Dictionary in Recipes.LIST:
		if r.at == Recipes.HAND:
			hand += 1
	assert_eq(hand, 6, "most recipes need the table or the furnace (spec §26: panning and drying salt are by hand; §26.5: sieving blueberries)")


func test_the_furnace_makes_glass_bricks_and_charcoal() -> void:
	for pair: Array in [[&"glass", BlockIds.SAND, BlockIds.GLASS], [&"bricks", BlockIds.STONE, BlockIds.BRICK],
			[&"charcoal", BlockIds.LOG, BlockIds.COAL]]:
		var r := Recipes.find(pair[0])
		assert_eq(r.at, Recipes.FURNACE, str(pair[0]))
		assert_true((r.needs as Dictionary).has(pair[1]))
		assert_eq(r.makes, pair[2])
	assert_eq(Recipes.FUELS, [BlockIds.COAL, BlockIds.LOG] as Array[int], "coal first, then a log")


## The tiers of §12.6 from sticks and a material: wood (planks), stone, iron, crystal (diamond), cosmic
## (gold and crystal); swords and pickaxes in all five, axes in three. The same items Tilly sells.
func test_tools_and_weapons_come_in_the_tiers() -> void:
	var material := {0: BlockIds.PLANKS, 1: BlockIds.STONE, 2: BlockIds.IRON, 3: BlockIds.DIAMOND}
	for line: Array in [ShopRules.TOOL_LINES[0], ShopRules.TOOL_LINES[2]]:   # swords, pickaxes
		for tier in 5:
			var r := Recipes.for_result(line[tier])
			assert_false(r.is_empty(), ItemIds.display_name(line[tier]))
			assert_eq(r.at, Recipes.TABLE)
			assert_true((r.needs as Dictionary).has(ItemIds.STICK))
			if tier < 4:
				assert_true((r.needs as Dictionary).has(material[tier]), ItemIds.display_name(line[tier]))
			else:
				assert_true((r.needs as Dictionary).has(BlockIds.GOLD) and (r.needs as Dictionary).has(BlockIds.CRYSTAL))
	for tier in 3:
		assert_false(Recipes.for_result(ShopRules.TOOL_LINES[3][tier]).is_empty(), "axe tier %d" % tier)
	assert_eq(Recipes.find(&"sword").needs, {BlockIds.PLANKS: 2, ItemIds.STICK: 1})
	assert_eq(Recipes.find(&"pickaxe_iron").needs, {BlockIds.IRON: 3, ItemIds.STICK: 2})


func test_home_things_at_the_table() -> void:
	for id in [BlockIds.FURNACE, BlockIds.DOOR, BlockIds.BED, BlockIds.LIGHT, BlockIds.LANTERN, BlockIds.BARREL,
			BlockIds.CLOSET, BlockIds.SPIKE_TRAP, ItemIds.SHIELD_WOOD]:
		var r := Recipes.for_result(id)
		assert_false(r.is_empty(), ItemIds.display_name(id))
		assert_eq(r.at, Recipes.TABLE, ItemIds.display_name(id))
	assert_eq(Recipes.for_result(BlockIds.DOOR).count, 2, "a doorway")
	assert_eq(Recipes.for_result(BlockIds.LANTERN).needs, {BlockIds.COAL: 1, ItemIds.STICK: 1, BlockIds.GLASS: 1})


func test_the_stick_and_the_two_stations() -> void:
	assert_eq(ItemIds.STICK, 451)
	assert_true(ItemIds.is_item(ItemIds.STICK))
	assert_eq(ItemIds.display_name(ItemIds.STICK), "Stick")
	assert_true(ItemIds.CRAFTED.has(ItemIds.STICK))
	assert_true(Inventory.ownable(ItemIds.STICK))
	assert_not_null(BlockIcons.icon(ItemIds.STICK))
	assert_eq(BlockIds.CRAFTING_TABLE, 220)
	assert_eq(BlockIds.FURNACE, 221)
	for id in [BlockIds.CRAFTING_TABLE, BlockIds.FURNACE]:
		assert_true(BlockIds.is_valid(id))
		assert_true(BlockIds.is_solid(id))
		assert_true(BlockIds.PLACEABLE.has(id))
		assert_eq(BlockLibrary.page_of(id), PortalPage.PAGE)
		assert_false(ItemIds.is_item(id))
	assert_eq(BlockIds.display_name(BlockIds.CRAFTING_TABLE), "Workbench")   # owner #43
	assert_eq(BlockIds.display_name(BlockIds.FURNACE), "Clay Oven")
	assert_eq(Recipes.station_block(Recipes.TABLE), BlockIds.CRAFTING_TABLE)
	assert_eq(Recipes.station_block(Recipes.FURNACE), BlockIds.FURNACE)
	assert_eq(Recipes.station_block(Recipes.HAND), BlockIds.AIR)
