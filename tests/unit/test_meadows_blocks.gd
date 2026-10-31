extends GutTest
## Owner feedback #45b (spec §14.18): the wild meadows' blocks, ids 256-271 on block atlas page 13, drawn in
## both styles (data/blocks/pages/meadows.png and its realistic twin): birch and dark trees, flowers, lily pads,
## mud, stone and mossy bricks, white plaster, roof tiles, hay, wheat, sail cloth, glowing mushroom caps and
## dirt paths. Every page up to 255 was taken, so the page sits past the old 255 limit (items own 100-175 and
## 400+ only).


func test_every_meadows_block_is_on_page_13() -> void:
	assert_eq(MeadowsBlocks.PAGE, 13)
	assert_eq(BlockLibrary.page_of(256), 13)
	assert_eq(BlockLibrary.page_of(271), 13)
	for id: int in MeadowsBlocks.TILES:
		assert_between(id, 256, 271, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), MeadowsBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(MeadowsBlocks.TILES.size(), 16, "the whole page: 256-271")
	assert_gte(BlockIds.COUNT, 272)


func test_no_item_takes_a_page_13_id() -> void:
	for id in range(256, 272):
		assert_false(ItemIds.is_item(id), "%d is a block of page 13" % id)
		assert_false(ItemIds.is_gift_stamp(id), str(id))


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in MeadowsBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModel
		assert_not_null(m, "%s has a model" % BlockIds.display_name(id))
		assert_false(m is VoxelBlockyModelEmpty, BlockIds.display_name(id))
		# its kind's material, or the sway material of its leaves and plants (the visuals brief, test_look_sway.gd)
		assert_same(m.get_material_override(0), BlockLibrary.block_material(MeadowsBlocks.PAGE, MeadowsBlocks.TILES[id]),
			BlockIds.display_name(id))
	assert_eq(BlockLibrary.tiles_of(BlockIds.BIRCH_LOG), (MeadowsBlocks.TILES[BlockIds.BIRCH_LOG] as Array).slice(0, 3))


func test_tiles_stay_inside_the_8_by_8_page() -> void:
	for id: int in MeadowsBlocks.TILES:
		var t: Array = MeadowsBlocks.TILES[id]
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t[i]), "%s tile %d" % [BlockIds.display_name(id), i])
		assert_true([&"opaque", &"cutout", &"glow", &"pass"].has(t[3]), BlockIds.display_name(id))


func test_both_styles_have_the_page_files() -> void:
	assert_eq(MeadowsBlocks.FILES, ["res://data/blocks/pages/meadows.png", "res://data/blocks/pages/meadows_albedo.png",
		"res://data/blocks/pages/meadows_normal.png"])
	var pixel := load(MeadowsBlocks.FILES[0]) as Texture2D
	assert_not_null(pixel)
	if pixel:
		assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for f: String in [MeadowsBlocks.FILES[1], MeadowsBlocks.FILES[2]]:
		var tex := load(f) as Texture2D
		assert_not_null(tex, f)
		if tex:
			assert_eq(tex.get_width(), 2048 if f == MeadowsBlocks.FILES[1] else 1024, "8 tiles of 256 px across (the normal map imported at half size; rows: test_page_sizes.gd): %s" % f)


func test_every_meadows_tile_is_drawn_in_the_pixel_page() -> void:
	var tex := load(MeadowsBlocks.FILES[0]) as Texture2D
	assert_not_null(tex)
	if tex == null:
		return
	var img := tex.get_image()
	for id: int in MeadowsBlocks.TILES:
		for i in 3:
			var t: Vector2i = MeadowsBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if img.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 12, "%s tile %s is drawn" % [BlockIds.display_name(id), t])


func test_the_realistic_twin_has_every_tile_too() -> void:
	var tex := load(MeadowsBlocks.FILES[1]) as Texture2D
	assert_not_null(tex)
	if tex == null:
		return
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	for id: int in MeadowsBlocks.TILES:
		var t: Vector2i = MeadowsBlocks.TILES[id][1]
		var painted := 0
		for p: Vector2i in [Vector2i(128, 128), Vector2i(40, 60), Vector2i(128, 200), Vector2i(200, 128), Vector2i(60, 180)]:
			if img.get_pixel(t.x * 256 + p.x, t.y * 256 + p.y).a > 0.1:
				painted += 1
		assert_gt(painted, 0, "%s side tile %s is painted" % [BlockIds.display_name(id), t])


func test_the_style_switch_restyles_the_meadows_page() -> void:
	BlockLibrary.build()
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	var mat := BlockLibrary.page_material(MeadowsBlocks.PAGE, &"opaque")
	assert_eq(mat.albedo_texture.resource_path, MeadowsBlocks.FILES[1])
	assert_true(mat.normal_enabled)
	BlockLibrary.set_style("blocky")
	assert_eq(BlockLibrary.page_material(MeadowsBlocks.PAGE, &"opaque").albedo_texture.resource_path, MeadowsBlocks.FILES[0])
	BlockLibrary.set_style(before)


func test_names_and_validity() -> void:
	for id: int in MeadowsBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_breakable(id), BlockIds.display_name(id))
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar holds %s" % BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.BIRCH_LOG), "Birch Wood")
	assert_eq(BlockIds.display_name(BlockIds.GLOW_MUSHROOM), "Glow Mushroom")
	assert_eq(ChatCommands.parse("/give birch wood").get("id"), BlockIds.BIRCH_LOG, "/give knows them")
	assert_eq(ChatCommands.parse("/give lily pad").get("id"), BlockIds.LILY_PAD)


## Flowers and wheat are two crossed pictures you walk through; a lily pad is a thin pad on the water you can
## stand on; the rest are whole blocks.
func test_flowers_and_wheat_are_crossed_pictures_you_walk_through() -> void:
	var lib := BlockLibrary.build()
	for id in [BlockIds.FLOWERS, BlockIds.WHEAT]:
		assert_false(BlockIds.is_solid(id), BlockIds.display_name(id))
		var m := lib.models[id] as VoxelBlockyModelMesh
		assert_not_null(m, "%s is a mesh model (crossed pictures)" % BlockIds.display_name(id))
		if m == null:
			continue
		assert_true(m.collision_aabbs.is_empty(), "no box")
		assert_false(m.is_mesh_collision_enabled(0), "no physics surface")
		assert_false(m.culls_neighbors, "the ground shows through it")
		var mesh := m.mesh as ArrayMesh
		assert_not_null(mesh)
		var aabb := mesh.get_aabb()
		assert_true(AABB(Vector3.ZERO, Vector3.ONE).grow(0.001).encloses(aabb), "inside its cell: %s" % aabb)
		assert_gt(aabb.size.x, 0.5)
		assert_gt(aabb.size.y, 0.5)
	var pad := lib.models[BlockIds.LILY_PAD] as VoxelBlockyModelCube
	assert_not_null(pad)
	if pad:
		assert_almost_eq(pad.height, MeadowsBlocks.PAD_HEIGHT, 0.0001, "a thin pad")
	assert_true(BlockIds.is_solid(BlockIds.LILY_PAD), "you can stand on a lily pad")
	for id in [BlockIds.BIRCH_LOG, BlockIds.MUD, BlockIds.STONE_BRICK, BlockIds.ROOF_TILES, BlockIds.HAY, BlockIds.PATH]:
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		assert_true(lib.models[id] is VoxelBlockyModelCube, BlockIds.display_name(id))


func test_see_through_and_glowing_blocks() -> void:
	var lib := BlockLibrary.build()
	for id in [BlockIds.BIRCH_LEAVES, BlockIds.DARK_LEAVES]:
		assert_eq(MeadowsBlocks.TILES[id][3], &"cutout", BlockIds.display_name(id))
		assert_eq((lib.models[id] as VoxelBlockyModel).transparency_index, 1, "leaves next to leaves hide their faces")
	assert_eq(MeadowsBlocks.TILES[BlockIds.GLOW_MUSHROOM][3], &"glow")


## Breaking gives the block itself, except leaves (nothing, like oak leaves).
func test_gathering_the_new_blocks() -> void:
	assert_eq(GatherRules.drop(BlockIds.BIRCH_LEAVES, GatherRules.NONE), BlockIds.AIR)
	assert_eq(GatherRules.drop(BlockIds.DARK_LEAVES, GatherRules.NONE), BlockIds.AIR)
	for id in [BlockIds.BIRCH_LOG, BlockIds.DARK_LOG, BlockIds.FLOWERS, BlockIds.MUD, BlockIds.STONE_BRICK, BlockIds.HAY,
			BlockIds.WHEAT, BlockIds.GLOW_MUSHROOM, BlockIds.PATH]:
		assert_eq(GatherRules.drop(id, GatherRules.NONE), id, BlockIds.display_name(id))
	for id: int in MeadowsBlocks.TILES:
		assert_false(BlockIds.PLACEABLE.has(id), "the BLOCKS grid keeps its size: %s" % BlockIds.display_name(id))


## The lists of natural blocks know the wild meadows: bots build on mud, the axe fells birch and dark trees, a
## meteor lands on mud, the wand never wakes the ground.
func test_the_wild_meadows_are_natural_everywhere() -> void:
	assert_true(BotRules.GROUND.has(BlockIds.MUD))
	for id in [BlockIds.MUD, BlockIds.BIRCH_LOG, BlockIds.BIRCH_LEAVES, BlockIds.DARK_LOG, BlockIds.DARK_LEAVES,
			BlockIds.FLOWERS, BlockIds.LILY_PAD, BlockIds.GLOW_MUSHROOM]:
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
	for id in [BlockIds.STONE_BRICK, BlockIds.PLASTER, BlockIds.ROOF_TILES, BlockIds.SAIL]:
		assert_false(BotRules.NATURAL.has(id), "%s is built, not natural" % BlockIds.display_name(id))
		assert_true(CaptureRules.is_capturable(id), "%s can come alive" % BlockIds.display_name(id))
	assert_true(SurpriseRules.METEOR_REPLACES.has(BlockIds.MUD))
	assert_false(CaptureRules.is_capturable(BlockIds.MUD), "the ground never comes alive")
	assert_eq(ToolPowers.LEAVES_OF.get(BlockIds.BIRCH_LOG), BlockIds.BIRCH_LEAVES)
	assert_eq(ToolPowers.LEAVES_OF.get(BlockIds.DARK_LOG), BlockIds.DARK_LEAVES)
	assert_true(ToolPowers.GROUND.has(BlockIds.MUD), "a swamp tree stands on mud")


## Gifts and showcases carry them (the game's and the server's limit rose to 399; cosmos: blocks go on past the items'
## 400-511, up to 1023).
func test_they_travel_in_gifts() -> void:
	for id: int in MeadowsBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	assert_eq(BuildCodec.BLOCK_MAX, 1023)
	assert_false(BuildCodec.is_block_id(400), "400-511 are items")


func test_a_meadows_block_gets_its_icon_from_its_page() -> void:
	BlockIcons._cache.erase(BlockIds.BIRCH_LOG)
	var icon := BlockIcons.icon(BlockIds.BIRCH_LOG) as AtlasTexture
	assert_not_null(icon)
	if icon:
		assert_eq(icon.atlas.resource_path, MeadowsBlocks.FILES[0])
		var side: Vector2i = MeadowsBlocks.TILES[BlockIds.BIRCH_LOG][1]
		assert_eq(icon.region, Rect2(side.x * 16, side.y * 16, 16, 16))
	BlockIcons._cache.erase(BlockIds.BIRCH_LOG)
