extends GutTest
## M3 Task 8 (spec §14.5): the paint bucket's 16 tints. Voxel Tools' blocky mesher colours by model, so a tint
## is a block id: 16 painted blocks on block atlas page 12 (ids 240-255) that a plain block turns into, painted
## by 16 paint items (ids 435-450). Blocks with a job (doors, beds, lights, smart blocks, portals...) are never
## painted; in Survivor paint costs nothing, but precious blocks (ores, gems) are never painted, and a painted
## block drops as itself, so painting is no way to farm or to lose a diamond.


func test_sixteen_tints_sixteen_paints_sixteen_painted_blocks() -> void:
	assert_eq(PaintRules.COUNT, 16)
	assert_eq(PaintRules.TINTS.size(), 16)
	assert_eq(ItemIds.PAINTS.size(), 16)
	var names := {}
	var colors := {}
	for t in PaintRules.COUNT:
		var item := PaintRules.item_of(t)
		var block := PaintRules.block_of(t)
		assert_eq(item, 435 + t, "paint items 435-450")
		assert_eq(block, 240 + t, "painted blocks 240-255")
		assert_eq(ItemIds.PAINTS[t], item)
		assert_true(ItemIds.is_item(item), "a paint is an item")
		assert_true(ItemIds.is_hotbar_valid(item))
		assert_true(BlockIds.is_valid(block), "a painted block is a block")
		assert_true(BlockIds.is_solid(block))
		assert_true(BlockIds.is_breakable(block))
		assert_false(ItemIds.is_item(block), "no item takes a painted block's id")
		assert_eq(BlockLibrary.page_of(block), PaintPage.PAGE, "on page 12")
		assert_eq(PaintRules.tint_of_item(item), t)
		assert_eq(PaintRules.tint_of_block(block), t)
		assert_eq(PaintRules.painted_by(item), block)
		assert_true(PaintRules.is_paint(item))
		assert_true(PaintRules.is_painted(block))
		assert_false(PaintRules.is_painted(item))
		assert_false(PaintRules.is_paint(block))
		var n := PaintRules.tint_name(t)
		assert_false(names.has(n), "its own name: %s" % n)
		names[n] = true
		assert_false(colors.has(PaintRules.color(t)), "its own colour: %s" % n)
		colors[PaintRules.color(t)] = true
		assert_eq(ItemIds.display_name(item), "%s Paint" % n)
		assert_eq(BlockIds.display_name(block), "Painted %s" % n)


func test_nothing_else_is_paint() -> void:
	for id in [0, BlockIds.STONE, BlockIds.SADDLE, 239, 256, ItemIds.WAND, 434, 451, ItemIds.LINE_TOOL, -1]:
		assert_false(PaintRules.is_paint(id), str(id))
		assert_eq(PaintRules.tint_of_item(id), -1, str(id))
		assert_eq(PaintRules.painted_by(id), BlockIds.AIR, str(id))
	for id in [0, BlockIds.STONE, 239, 256, 435, -1]:
		assert_false(PaintRules.is_painted(id), str(id))
		assert_eq(PaintRules.tint_of_block(id), -1, str(id))


func test_plain_blocks_are_painted_in_both_modes() -> void:
	for id in [BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.DIRT, BlockIds.SAND, BlockIds.GLASS,
			BlockIds.LOG, BlockIds.LEAVES, BlockIds.RED, BlockIds.DEEPSTONE, BlockIds.GRASS, BlockIds.SANDSTONE,
			BlockIds.SNOW_BRICK, BlockIds.CAKE, BlockIds.PAINTED_RED]:
		assert_true(PaintRules.paintable(id), BlockIds.display_name(id))
		assert_eq(PaintRules.refusal(id, BlockIds.PAINTED_BLUE, false), "", "Sandbox: %s" % BlockIds.display_name(id))
		assert_eq(PaintRules.refusal(id, BlockIds.PAINTED_BLUE, true), "", "Survivor: %s" % BlockIds.display_name(id))


func test_blocks_with_a_job_are_never_painted() -> void:
	for id in [BlockIds.AIR, BlockIds.WATER, BlockIds.BEDROCK, BlockIds.BED, BlockIds.DOOR, BlockIds.DOOR_OPEN,
			BlockIds.SPIKE_TRAP, BlockIds.LANTERN, BlockIds.LIGHT, BlockIds.CRYSTAL, BlockIds.BUSH, BlockIds.BARREL,
			BlockIds.CLOSET, BlockIds.FAKE_WALL, BlockIds.PRESSURE_PLATE, BlockIds.TROPHY, BlockIds.GOLD_LAMP,
			BlockIds.JUMP_PAD, BlockIds.SPEED_PAD, BlockIds.CACTUS, BlockIds.ICE, BlockIds.BLUE_ICE, BlockIds.GUMDROP,
			BlockIds.PORTAL_FRAME, BlockIds.PORTAL_CORE, BlockIds.CRAFTING_TABLE, BlockIds.FURNACE, BlockIds.ZIPLINE_POST,
			BlockIds.LAUNCH_PAD, BlockIds.SADDLE, BlockIds.BUTTON, BlockIds.LEVER, BlockIds.LAMP, BlockIds.START,
			BlockIds.FINISH, BlockIds.COIN, BlockIds.BOUNCE, BlockIds.TELEPORT_PAD, BlockIds.POWERED_DOOR,
			BlockIds.ARROW_SLIT, BlockIds.TRAP_SAND, BlockIds.FAKE_SANDSTONE, BlockIds.FAKE_SNOW, BlockIds.FAKE_CHOCOLATE,
			BlockIds.GOLDEN_CANDY, BlockIds.CANDY_LAMP, BlockIds.DESERT_LAMP, BlockIds.ICE_LANTERN, BlockIds.PYRAMID_GOLD]:
		assert_false(PaintRules.paintable(id), BlockIds.display_name(id))
		assert_eq(PaintRules.refusal(id, BlockIds.PAINTED_RED, false), PaintRules.CANT, "Sandbox: %d" % id)
	assert_eq(PaintRules.message(PaintRules.CANT, BlockIds.DOOR), "Doors can't be painted!")
	assert_eq(PaintRules.message(PaintRules.CANT, BlockIds.AIR), "Tap a block to paint it!")


## Survivor (spec §14.5): paint is free, so a precious block (Tilly buys it, or it needs a pickaxe) is never
## painted: painting a diamond is no way to lose it (nor, since a painted block is worth nothing, to farm).
func test_survivor_keeps_precious_blocks_safe() -> void:
	for id in [BlockIds.DIAMOND, BlockIds.GOLD, BlockIds.IRON, BlockIds.COAL, BlockIds.FROZEN_ORE]:
		assert_true(PaintRules.precious(id), BlockIds.display_name(id))
		assert_eq(PaintRules.refusal(id, BlockIds.PAINTED_RED, true), PaintRules.PRECIOUS, BlockIds.display_name(id))
		assert_eq(PaintRules.refusal(id, BlockIds.PAINTED_RED, false), "", "Sandbox has every block: %s" % id)
	assert_eq(PaintRules.message(PaintRules.PRECIOUS, BlockIds.DIAMOND), "Diamond is too precious to paint!")
	for id in [BlockIds.STONE, BlockIds.PLANKS, BlockIds.PAINTED_PINK]:
		assert_false(PaintRules.precious(id), BlockIds.display_name(id))


func test_the_same_colour_again_does_nothing_and_only_paint_paints() -> void:
	assert_eq(PaintRules.refusal(BlockIds.PAINTED_RED, BlockIds.PAINTED_RED, false), PaintRules.SAME)
	assert_eq(PaintRules.refusal(BlockIds.STONE, BlockIds.BRICK, false), PaintRules.NOT_PAINT)
	assert_eq(PaintRules.refusal(BlockIds.STONE, BlockIds.AIR, false), PaintRules.NOT_PAINT)
	assert_eq(PaintRules.message(PaintRules.SAME, BlockIds.PAINTED_RED), "")


## A painted block drops as itself and costs itself (GatherRules' defaults); Tilly never buys one.
func test_a_painted_block_is_worth_only_itself() -> void:
	for t in PaintRules.COUNT:
		var block := PaintRules.block_of(t)
		assert_eq(GatherRules.drop(block, GatherRules.NONE), block, "breaks by hand into itself")
		assert_eq(GatherRules.cost(block), block)
		assert_eq(ShopRules.sell_price(block), 0, "never sold for gold")
