extends GutTest
## M2 §12.2: what breaking a block gives in Survivor, which pickaxe it needs, and what one cell
## change costs or gives back (an undo is the exact reverse of the edit it undoes).


## Tier pickaxes become ownable in Task 6 (ItemIds.ALL, with their icons); until then the test puts
## one in directly.
static func _give(inv: Inventory, id: int, n: int) -> void:
	if inv.add(id, n) == 0:
		inv._counts[id] = inv.count(id) + n


func test_most_blocks_give_themselves() -> void:
	for id: int in [BlockIds.DIRT, BlockIds.STONE, BlockIds.SAND, BlockIds.LOG, BlockIds.PLANKS,
			BlockIds.GLASS, BlockIds.BRICK, BlockIds.RED, BlockIds.DEEPSTONE, BlockIds.BED]:
		assert_eq(GatherRules.drop(id, GatherRules.NONE), id, BlockIds.display_name(id))


func test_grass_gives_dirt_and_leaves_water_and_bedrock_give_nothing() -> void:
	assert_eq(GatherRules.drop(BlockIds.GRASS, GatherRules.NONE), BlockIds.DIRT)
	assert_eq(GatherRules.drop(BlockIds.LEAVES, GatherRules.COSMIC), BlockIds.AIR)
	assert_eq(GatherRules.drop(BlockIds.WATER, GatherRules.COSMIC), BlockIds.AIR)
	assert_eq(GatherRules.drop(BlockIds.BEDROCK, GatherRules.COSMIC), BlockIds.AIR)
	assert_eq(GatherRules.drop(BlockIds.AIR, GatherRules.COSMIC), BlockIds.AIR)


func test_an_open_door_gives_a_door() -> void:
	assert_eq(GatherRules.drop(BlockIds.DOOR_OPEN, GatherRules.NONE), BlockIds.DOOR)
	assert_eq(GatherRules.cost(BlockIds.DOOR_OPEN), BlockIds.DOOR, "and placing one uses a door")
	assert_eq(GatherRules.cost(BlockIds.STONE), BlockIds.STONE)


## Merge of Tasks 3 and 16: a secret room's fake wall and a temple's plates are stone underneath, so
## breaking them never hands out puzzle pieces.
## M3 Task 7: a pressure plate became a smart block children buy and place, so it gives a plate back (a
## temple's plates too; Tilly never buys plates, so they are worth no gold). A fake wall stays stone.
func test_fake_walls_give_stone_and_pressure_plates_a_plate() -> void:
	assert_eq(GatherRules.drop(BlockIds.FAKE_WALL, GatherRules.NONE), BlockIds.STONE)
	assert_eq(GatherRules.drop(BlockIds.PRESSURE_PLATE, GatherRules.NONE), BlockIds.PRESSURE_PLATE)


func test_coal_and_iron_need_any_pickaxe() -> void:
	for ore: int in [BlockIds.COAL, BlockIds.IRON]:
		assert_eq(GatherRules.refusal(ore, GatherRules.NONE), GatherRules.NEED_PICKAXE_MESSAGE)
		assert_eq(GatherRules.drop(ore, GatherRules.NONE), BlockIds.AIR, "nothing without a pickaxe")
		assert_eq(GatherRules.refusal(ore, GatherRules.WOOD), "")
		assert_eq(GatherRules.drop(ore, GatherRules.WOOD), ore)


func test_gold_diamond_and_crystal_need_an_iron_pickaxe_or_better() -> void:
	for ore: int in [BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.CRYSTAL]:
		for weak: int in [GatherRules.NONE, GatherRules.WOOD, GatherRules.STONE]:
			assert_eq(GatherRules.refusal(ore, weak), "You need an iron pickaxe for this!")
			assert_false(GatherRules.can_break(ore, weak))
		for strong: int in [GatherRules.IRON, GatherRules.CRYSTAL, GatherRules.COSMIC]:
			assert_eq(GatherRules.refusal(ore, strong), "")
			assert_eq(GatherRules.drop(ore, strong), ore)


func test_other_blocks_need_no_tool() -> void:
	for id: int in [BlockIds.GRASS, BlockIds.STONE, BlockIds.DEEPSTONE, BlockIds.LOG, BlockIds.LEAVES]:
		assert_true(GatherRules.can_break(id, GatherRules.NONE), BlockIds.display_name(id))


func test_the_best_pickaxe_owned_counts() -> void:
	var inv := Inventory.new()
	assert_eq(GatherRules.pickaxe_tier(inv), GatherRules.NONE)
	inv.add(ItemIds.PICKAXE, 1)
	assert_eq(GatherRules.pickaxe_tier(inv), GatherRules.WOOD, "the M1b pickaxe is the wood tier")
	_give(inv, ItemIds.PICKAXE_IRON, 1)
	_give(inv, ItemIds.PICKAXE_STONE, 1)
	assert_eq(GatherRules.pickaxe_tier(inv), GatherRules.IRON)
	_give(inv, ItemIds.PICKAXE_COSMIC, 1)
	assert_eq(GatherRules.pickaxe_tier(inv), GatherRules.COSMIC)
	assert_eq(GatherRules.tier_of(ItemIds.PICKAXE_CRYSTAL), GatherRules.CRYSTAL)
	assert_eq(GatherRules.tier_of(ItemIds.SWORD), GatherRules.NONE, "a sword is no pickaxe")


func test_placing_takes_one_and_breaking_gives_the_drop() -> void:
	assert_eq(GatherRules.change(BlockIds.AIR, BlockIds.STONE, false, GatherRules.NONE), {BlockIds.STONE: -1})
	assert_eq(GatherRules.change(BlockIds.STONE, BlockIds.AIR, false, GatherRules.NONE), {BlockIds.STONE: 1})
	assert_eq(GatherRules.change(BlockIds.GRASS, BlockIds.AIR, false, GatherRules.NONE), {BlockIds.DIRT: 1})
	assert_eq(GatherRules.change(BlockIds.LEAVES, BlockIds.AIR, false, GatherRules.NONE), {})
	assert_eq(GatherRules.change(BlockIds.WATER, BlockIds.PLANKS, false, GatherRules.NONE), {BlockIds.PLANKS: -1},
		"a block placed into water takes one and gives nothing")
	assert_eq(GatherRules.change(BlockIds.DIRT, BlockIds.DIRT, false, GatherRules.NONE), {}, "no change, no cost")
	assert_eq(GatherRules.change(BlockIds.DIRT, BlockIds.PLANKS, false, GatherRules.NONE),
		{BlockIds.DIRT: 1, BlockIds.PLANKS: -1}, "replacing is breaking and placing")


## An undo gives back exactly what its edit took and takes back exactly what its edit gave.
func test_an_undo_is_the_exact_reverse_of_its_edit() -> void:
	for id: int in [BlockIds.STONE, BlockIds.GRASS, BlockIds.LEAVES, BlockIds.GOLD, BlockIds.WATER, BlockIds.DOOR_OPEN]:
		var edits: Array = [[BlockIds.AIR, id], [id, BlockIds.AIR], [BlockIds.DIRT, id], [id, BlockIds.SAND]]
		for e: Array in edits:
			var done := GatherRules.change(e[0], e[1], false, GatherRules.COSMIC)
			var undone := GatherRules.change(e[1], e[0], true, GatherRules.COSMIC)
			var net := done.duplicate()
			for k: int in undone:
				net[k] = int(net.get(k, 0)) + int(undone[k])
				if net[k] == 0:
					net.erase(k)
			assert_eq(net, {}, "%s -> %s and back" % [BlockIds.display_name(e[0]), BlockIds.display_name(e[1])])


func test_undoing_a_placement_gives_the_block_itself_back_without_a_pickaxe() -> void:
	assert_eq(GatherRules.change(BlockIds.GOLD, BlockIds.AIR, true, GatherRules.NONE), {BlockIds.GOLD: 1},
		"a placed gold ore comes back even without an iron pickaxe")
	assert_eq(GatherRules.change(BlockIds.GRASS, BlockIds.AIR, true, GatherRules.NONE), {BlockIds.GRASS: 1},
		"placed grass comes back as grass, not dirt")


func test_undoing_a_break_takes_back_what_the_break_gave() -> void:
	assert_eq(GatherRules.change(BlockIds.AIR, BlockIds.STONE, true, GatherRules.NONE), {BlockIds.STONE: -1})
	assert_eq(GatherRules.change(BlockIds.AIR, BlockIds.GRASS, true, GatherRules.NONE), {BlockIds.DIRT: -1},
		"broken grass gave dirt, so putting it back costs the dirt")
	assert_eq(GatherRules.change(BlockIds.AIR, BlockIds.LEAVES, true, GatherRules.NONE), {},
		"broken leaves gave nothing, so putting them back is free")


## Task 8's door toggle, if it goes through Session like any edit, costs nothing in Survivor: opening a
## door gives the door back and uses it again.
func test_opening_or_closing_a_door_costs_nothing() -> void:
	assert_eq(GatherRules.change(BlockIds.DOOR, BlockIds.DOOR_OPEN, false, GatherRules.NONE), {})
	assert_eq(GatherRules.change(BlockIds.DOOR_OPEN, BlockIds.DOOR, false, GatherRules.NONE), {})
