extends GutTest
## Tool block powers (M1b Task 11): the axe fells one natural tree, the pickaxe digs a 1x2 step,
## the hammer smashes a 3x3 patch. All are EditBatch input and never touch bedrock.

## A tiny world: grass below y = 0, air above, plus the blocks in `edits`.
var blocks := {}


func before_each() -> void:
	blocks = {}


func _at(p: Vector3i) -> int:
	if blocks.has(p):
		return blocks[p]
	return BlockIds.GRASS if p.y < 0 else BlockIds.AIR


## A tree like the terrain generator's: a trunk of `height` logs on the ground and a round canopy.
func _tree(x: int, z: int, height: int = 5) -> void:
	var top := height
	for dy in range(-2, 2):
		var radius := 2 if dy < 0 else 1
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if radius == 2 and absi(dx) == 2 and absi(dz) == 2:
					continue
				if dy == 1 and absi(dx) + absi(dz) > 1:
					continue
				var p := Vector3i(x + dx, top + dy, z + dz)
				if not blocks.has(p):
					blocks[p] = BlockIds.LEAVES
	for y in range(0, top):
		blocks[Vector3i(x, y, z)] = BlockIds.LOG


func _cells(edits: Array) -> Dictionary:
	var out := {}
	for e: Array in edits:
		assert_eq(e[1], BlockIds.AIR, "tool powers only break blocks")
		out[e[0]] = true
	return out


func _tree_cells(x: int, z: int) -> Dictionary:
	var out := {}
	for p: Vector3i in blocks:
		if blocks[p] in [BlockIds.LOG, BlockIds.LEAVES] and absi(p.x - x) <= 2 and absi(p.z - z) <= 2:
			out[p] = true
	return out


# --- Axe ---

func test_axe_fells_exactly_the_logs_and_leaves_of_one_tree() -> void:
	_tree(0, 0)
	var expected := _tree_cells(0, 0)
	var edits := ToolPowers.fell_tree(Vector3i(0, 1, 0), _at)
	assert_eq(_cells(edits), expected)
	assert_eq(edits.size(), expected.size(), "no cell twice")
	assert_eq(EditBatch.sanitize(edits), edits, "valid EditBatch input")


## M3 (lead, after the desert merge): a palm in the Sandstorm Desert is a tree too: palm logs on
## (red) sand with palm leaves fall to the axe; a palm log never takes Meadows leaves with it.
func test_axe_fells_a_desert_palm() -> void:
	_tree(0, 0)
	for p: Vector3i in blocks.keys():
		blocks[p] = BlockIds.PALM_LOG if blocks[p] == BlockIds.LOG else BlockIds.PALM_LEAVES
	blocks[Vector3i(0, -1, 0)] = BlockIds.RED_SAND
	var expected := {}
	for p: Vector3i in blocks:
		if blocks[p] in [BlockIds.PALM_LOG, BlockIds.PALM_LEAVES]:
			expected[p] = true
	blocks[Vector3i(3, 5, 0)] = BlockIds.LEAVES   # a Meadows leaf touching the crown stays
	assert_eq(_cells(ToolPowers.fell_tree(Vector3i(0, 2, 0), _at)), expected)


func test_axe_leaves_the_neighbouring_tree_standing() -> void:
	_tree(0, 0)
	_tree(5, 0)                                    # canopies touch at x = 2 / 3
	var mine := _tree_cells(0, 0)
	var felled := _cells(ToolPowers.fell_tree(Vector3i(0, 0, 0), _at))
	assert_true(felled.has(Vector3i(0, 4, 0)), "the whole trunk")
	for p: Vector3i in felled:
		assert_lt(p.x, 3, "nothing of the other tree: %s" % p)
	for p: Vector3i in mine:
		if p.x <= 2:
			assert_true(felled.has(p), "all of this tree: %s" % p)


func test_axe_never_takes_the_players_planks() -> void:
	_tree(0, 0)
	for x in range(1, 4):                          # a tree-house floor nailed to the trunk
		for z in range(-1, 2):
			blocks[Vector3i(x, 2, z)] = BlockIds.PLANKS
	for e: Array in ToolPowers.fell_tree(Vector3i(0, 2, 0), _at):
		assert_true(_at(e[0]) in [BlockIds.LOG, BlockIds.LEAVES], "only wood and leaves: %s" % e[0])


func test_a_log_pillar_in_a_build_is_not_a_tree() -> void:
	for y in range(0, 4):                          # a house corner: logs on a plank floor, no leaves
		blocks[Vector3i(0, y, 0)] = BlockIds.LOG
		blocks[Vector3i(1, y, 0)] = BlockIds.PLANKS
	blocks[Vector3i(0, -1, 0)] = BlockIds.PLANKS
	assert_eq(ToolPowers.fell_tree(Vector3i(0, 1, 0), _at), [])
	blocks[Vector3i(0, -1, 0)] = BlockIds.GRASS    # on the ground, but still no leaves
	assert_eq(ToolPowers.fell_tree(Vector3i(0, 1, 0), _at), [])


## Review M2: a log cabin on the grass with a leafy roof looked like a tree, and the axe took
## the whole house down in one tap.
func test_a_log_cabin_with_a_leaf_roof_is_not_a_tree() -> void:
	for x in range(0, 5):
		for z in range(0, 5):
			if x == 0 or x == 4 or z == 0 or z == 4:
				for y in range(0, 3):
					blocks[Vector3i(x, y, z)] = BlockIds.LOG
			blocks[Vector3i(x, 3, z)] = BlockIds.LEAVES
	assert_eq(ToolPowers.fell_tree(Vector3i(0, 1, 0), _at), [], "the cabin stays")
	blocks.clear()
	for y in range(0, 5):                          # a player's thick 2 x 2 tree is still a tree
		for c: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			blocks[Vector3i(c.x, y, c.y)] = BlockIds.LOG
	blocks[Vector3i(0, 5, 0)] = BlockIds.LEAVES
	assert_eq(ToolPowers.fell_tree(Vector3i(0, 1, 0), _at).size(), 21)


func test_axe_needs_a_log_to_start() -> void:
	_tree(0, 0)
	assert_eq(ToolPowers.fell_tree(Vector3i(1, 4, 0), _at), [], "leaves")
	assert_eq(ToolPowers.fell_tree(Vector3i(0, -1, 0), _at), [], "ground")


func test_felling_is_capped_and_keeps_the_trunk() -> void:
	for y in range(0, 12):
		blocks[Vector3i(0, y, 0)] = BlockIds.LOG
	for x in range(-4, 5):                          # an enormous canopy
		for y in range(3, 16):
			for z in range(-4, 5):
				if not blocks.has(Vector3i(x, y, z)):
					blocks[Vector3i(x, y, z)] = BlockIds.LEAVES
	var felled := _cells(ToolPowers.fell_tree(Vector3i(0, 0, 0), _at))
	assert_eq(felled.size(), ToolPowers.MAX_TREE_BLOCKS)
	for y in range(0, 12):
		assert_true(felled.has(Vector3i(0, y, 0)), "trunk log %d" % y)
	assert_lte(ToolPowers.MAX_TREE_BLOCKS, EditBatch.MAX_BATCH)


# --- Pickaxe ---

func test_pickaxe_digs_a_1x2_step_in_the_facing_direction() -> void:
	for x in range(-8, 9):
		for y in range(0, 16):
			for z in range(-8, 9):
				blocks[Vector3i(x, y, z)] = BlockIds.STONE
	var feet_y := 10
	var east := _cells(ToolPowers.tunnel(Vector3i(5, 10, 0), Vector3i(-1, 0, 0), feet_y, _at))
	assert_eq(east, {Vector3i(5, 10, 0): true, Vector3i(5, 11, 0): true}, "tapped at the feet")
	var head := _cells(ToolPowers.tunnel(Vector3i(5, 11, 0), Vector3i(-1, 0, 0), feet_y, _at))
	assert_eq(head, east, "tapped at the head: the same player-sized step")
	var north := _cells(ToolPowers.tunnel(Vector3i(0, 10, -3), Vector3i(0, 0, 1), feet_y, _at))
	assert_eq(north, {Vector3i(0, 10, -3): true, Vector3i(0, 11, -3): true})
	var high := _cells(ToolPowers.tunnel(Vector3i(3, 13, 0), Vector3i(-1, 0, 0), feet_y, _at))
	assert_eq(high, {Vector3i(3, 13, 0): true, Vector3i(3, 14, 0): true}, "a wall above: dig where tapped")
	var down := _cells(ToolPowers.tunnel(Vector3i(0, 9, 0), Vector3i(0, 1, 0), feet_y, _at))
	assert_eq(down, {Vector3i(0, 9, 0): true, Vector3i(0, 8, 0): true}, "tapped the floor: a 2-deep hole")


func test_pickaxe_skips_air_and_water() -> void:
	blocks[Vector3i(5, 10, 0)] = BlockIds.STONE
	blocks[Vector3i(5, 11, 0)] = BlockIds.WATER
	assert_eq(_cells(ToolPowers.tunnel(Vector3i(5, 10, 0), Vector3i(-1, 0, 0), 10, _at)), {Vector3i(5, 10, 0): true})


# --- Hammer ---

func test_hammer_smash_breaks_a_3x3_patch() -> void:
	var smashed := _cells(ToolPowers.smash(Vector3i(4, -1, 7), _at))
	assert_eq(smashed.size(), 9)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			assert_true(smashed.has(Vector3i(4 + dx, -1, 7 + dz)))


func test_smash_skips_empty_cells() -> void:
	blocks[Vector3i(4, -1, 7)] = BlockIds.AIR
	assert_eq(ToolPowers.smash(Vector3i(4, -1, 7), _at).size(), 8)


# --- Which power a tool uses ---

func test_each_tool_uses_its_own_power() -> void:
	_tree(0, 0)
	var feet := 0
	var felled := ToolPowers.for_tool(ItemIds.AXE, Vector3i(0, 2, 0), Vector3i(-1, 0, 0), feet, _at)
	assert_eq(felled.size(), _tree_cells(0, 0).size(), "the axe fells the tree")
	var smashed := ToolPowers.for_tool(ItemIds.HAMMER, Vector3i(9, -1, 9), Vector3i.UP, feet, _at)
	assert_eq(smashed.size(), 9, "the hammer smashes 3x3")
	var dug := ToolPowers.for_tool(ItemIds.PICKAXE, Vector3i(9, -1, 9), Vector3i.UP, feet, _at)
	assert_eq(_cells(dug), {Vector3i(9, -1, 9): true, Vector3i(9, -2, 9): true}, "the pickaxe digs down")
	assert_eq(ToolPowers.for_tool(ItemIds.SWORD, Vector3i(9, -1, 9), Vector3i.UP, feet, _at), [], "no block power")


func test_the_axe_chops_one_block_that_is_not_a_tree() -> void:
	blocks[Vector3i(3, 0, 3)] = BlockIds.PLANKS
	assert_eq(ToolPowers.for_tool(ItemIds.AXE, Vector3i(3, 0, 3), Vector3i.UP, 0, _at), [[Vector3i(3, 0, 3), BlockIds.AIR]])
	blocks[Vector3i(3, 1, 3)] = BlockIds.LOG                # a lone log: not a tree
	assert_eq(ToolPowers.for_tool(ItemIds.AXE, Vector3i(3, 1, 3), Vector3i.UP, 0, _at), [[Vector3i(3, 1, 3), BlockIds.AIR]])
	assert_eq(ToolPowers.for_tool(ItemIds.AXE, Vector3i(3, 5, 3), Vector3i.UP, 0, _at), [], "nothing to chop")


# --- Bedrock ---

func test_tool_powers_never_include_bedrock() -> void:
	var bedrock := func(_p: Vector3i) -> int: return BlockIds.BEDROCK
	assert_eq(ToolPowers.smash(Vector3i(0, -64, 0), bedrock), [])
	assert_eq(ToolPowers.tunnel(Vector3i(0, -63, 0), Vector3i(0, 1, 0), -62, bedrock), [])
	assert_eq(ToolPowers.tunnel(Vector3i(3, -63, 0), Vector3i(-1, 0, 0), -63, bedrock), [])
	assert_eq(ToolPowers.fell_tree(Vector3i(0, -63, 0), bedrock), [])
	for tool in [ItemIds.AXE, ItemIds.PICKAXE, ItemIds.HAMMER]:
		assert_eq(ToolPowers.for_tool(tool, Vector3i(0, -63, 0), Vector3i.UP, -62, bedrock), [], ItemIds.display_name(tool))
	for x in range(-1, 2):                         # a patch half on bedrock
		blocks[Vector3i(x, -61, 0)] = BlockIds.BEDROCK
	for e: Array in ToolPowers.smash(Vector3i(0, -61, 0), _at):
		assert_ne(_at(e[0]), BlockIds.BEDROCK)
