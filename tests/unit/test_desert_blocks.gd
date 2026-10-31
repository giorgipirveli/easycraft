extends GutTest
## M3 Task 2 (spec §14.1): the Sandstorm Desert's blocks, ids 64-79 on block atlas page 1, drawn in both
## styles (data/blocks/pages/desert.png and its realistic twin). Sandstone, cut and chiselled sandstone,
## red sand and red sandstone, cactus, a dead bush you walk through, desert glass, the oasis palm, the
## pyramid's golden tip, desert lamps, and three blocks only the desert builds: arrow slits, trap sand
## (a sand pit's lid: it looks like sand and holds nobody) and fake sandstone (a hidden door).


func test_every_desert_block_is_on_page_1() -> void:
	assert_eq(DesertBlocks.PAGE, 1)
	for id: int in DesertBlocks.TILES:
		assert_between(id, 64, 79, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), DesertBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(DesertBlocks.TILES.size(), 15, "15 blocks (79 is free)")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	for id: int in DesertBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		# its kind's material, or the sway material of its palm leaves (the visuals brief, test_look_sway.gd)
		assert_same(m.get_material_override(0), BlockLibrary.block_material(DesertBlocks.PAGE, DesertBlocks.TILES[id]),
			BlockIds.display_name(id))
	assert_eq(BlockLibrary.tiles_of(BlockIds.SANDSTONE), (DesertBlocks.TILES[BlockIds.SANDSTONE] as Array).slice(0, 3))


func test_tiles_stay_inside_the_8_by_8_page() -> void:
	for id: int in DesertBlocks.TILES:
		var t: Array = DesertBlocks.TILES[id]
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t[i]), "%s tile %d" % [BlockIds.display_name(id), i])
		assert_true([&"opaque", &"cutout", &"glow"].has(t[3]), BlockIds.display_name(id))


func test_both_styles_have_the_page_files() -> void:
	assert_eq(DesertBlocks.FILES, ["res://data/blocks/pages/desert.png", "res://data/blocks/pages/desert_albedo.png",
		"res://data/blocks/pages/desert_normal.png"])
	var pixel := load(DesertBlocks.FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for f: String in [DesertBlocks.FILES[1], DesertBlocks.FILES[2]]:
		var tex := load(f) as Texture2D
		assert_not_null(tex, f)
		assert_eq(tex.get_width(), 2048 if f == DesertBlocks.FILES[1] else 1024, "8 tiles of 256 px across (the normal map imported at half size; rows: test_page_sizes.gd): %s" % f)


func test_the_style_switch_restyles_the_desert_page() -> void:
	BlockLibrary.build()
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	var mat := BlockLibrary.page_material(DesertBlocks.PAGE, &"opaque")
	assert_eq(mat.albedo_texture.resource_path, DesertBlocks.FILES[1])
	assert_true(mat.normal_enabled)
	BlockLibrary.set_style("blocky")
	assert_eq(BlockLibrary.page_material(DesertBlocks.PAGE, &"opaque").albedo_texture.resource_path, DesertBlocks.FILES[0])
	assert_false(BlockLibrary.page_material(DesertBlocks.PAGE, &"opaque").normal_enabled)
	BlockLibrary.set_style(before)


func test_every_desert_tile_is_drawn_in_the_pixel_page() -> void:
	var img := (load(DesertBlocks.FILES[0]) as Texture2D).get_image()
	for id: int in DesertBlocks.TILES:
		for i in 3:
			var t: Vector2i = DesertBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if img.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 20, "%s tile %s is drawn" % [BlockIds.display_name(id), t])


func test_names_and_validity() -> void:
	for id: int in DesertBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_breakable(id), BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.SANDSTONE), "Sandstone")
	assert_eq(BlockIds.display_name(BlockIds.CACTUS), "Cactus")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_SANDSTONE), "Sandstone", "a hidden door is named like the wall it hides in")
	assert_eq(BlockIds.display_name(BlockIds.TRAP_SAND), "Sand", "a sand pit's lid is named like sand")
	assert_false(BlockIds.is_valid(79), "79 has no block yet")
	assert_gte(BlockIds.COUNT, 80)


func test_walk_through_blocks_have_no_collision() -> void:
	var lib := BlockLibrary.build()
	for id in [BlockIds.DEAD_BUSH, BlockIds.TRAP_SAND]:
		assert_false(BlockIds.is_solid(id), BlockIds.display_name(id))
		var m := lib.models[id] as VoxelBlockyModel
		assert_true(m.collision_aabbs.is_empty(), "%s: no box" % BlockIds.display_name(id))
		assert_false(m.is_mesh_collision_enabled(0), "%s: no physics surface" % BlockIds.display_name(id))
	for id in [BlockIds.SANDSTONE, BlockIds.CACTUS, BlockIds.DESERT_GLASS, BlockIds.ARROW_SLIT, BlockIds.FAKE_SANDSTONE]:
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		assert_false((lib.models[id] as VoxelBlockyModel).collision_aabbs.is_empty(), BlockIds.display_name(id))


func test_see_through_and_glowing_blocks() -> void:
	for id in [BlockIds.DEAD_BUSH, BlockIds.DESERT_GLASS, BlockIds.PALM_LEAVES]:
		assert_eq(DesertBlocks.TILES[id][3], &"cutout", BlockIds.display_name(id))
	for id in [BlockIds.PYRAMID_GOLD, BlockIds.DESERT_LAMP]:
		assert_eq(DesertBlocks.TILES[id][3], &"glow", BlockIds.display_name(id))
	var lib := BlockLibrary.build()
	assert_false((lib.models[BlockIds.DEAD_BUSH] as VoxelBlockyModel).culls_neighbors, "the ground shows through a bush")
	assert_gt((lib.models[BlockIds.DESERT_GLASS] as VoxelBlockyModel).transparency_index, 0, "glass next to glass keeps its faces")


## The desert's own blocks are gathered and traded in the desert; the three it builds for its secrets are
## never picked, and breaking them gives what they look like.
func test_desert_blocks_stay_out_of_the_sandbox_palette_and_drop_what_they_look_like() -> void:
	for id: int in DesertBlocks.TILES:
		assert_false(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
	assert_eq(GatherRules.drop(BlockIds.TRAP_SAND, GatherRules.NONE), BlockIds.SAND)
	assert_eq(GatherRules.drop(BlockIds.FAKE_SANDSTONE, GatherRules.NONE), BlockIds.SANDSTONE)
	assert_eq(GatherRules.drop(BlockIds.ARROW_SLIT, GatherRules.NONE), BlockIds.CUT_SANDSTONE)
	assert_eq(GatherRules.drop(BlockIds.PALM_LEAVES, GatherRules.NONE), BlockIds.AIR, "like leaves")
	assert_eq(GatherRules.drop(BlockIds.SANDSTONE, GatherRules.NONE), BlockIds.SANDSTONE)
	assert_eq(GatherRules.drop(BlockIds.PYRAMID_GOLD, GatherRules.WOOD), BlockIds.PYRAMID_GOLD, "the pyramid's tip is a treasure")
	var giveable := ChatCommands.giveable_ids()
	for id in [BlockIds.PYRAMID_GOLD, BlockIds.ARROW_SLIT, BlockIds.TRAP_SAND, BlockIds.FAKE_SANDSTONE]:
		assert_false(giveable.has(id), "/give never hands out %s" % BlockIds.display_name(id))
	assert_eq(ChatCommands.parse("/give sandstone").get("id"), BlockIds.SANDSTONE, "the look-alikes never take the name")
	assert_eq(ChatCommands.parse("/give sand").get("id"), BlockIds.SAND)


## The Magic Wand never wakes the desert's natural ground (a build on a dune comes alive without the dune).
func test_the_desert_ground_never_comes_alive() -> void:
	for id in [BlockIds.SANDSTONE, BlockIds.RED_SAND, BlockIds.RED_SANDSTONE, BlockIds.TRAP_SAND]:
		assert_false(CaptureRules.is_capturable(id), BlockIds.display_name(id))
	for id in [BlockIds.CUT_SANDSTONE, BlockIds.CACTUS, BlockIds.PALM_LOG, BlockIds.DESERT_GLASS]:
		assert_true(CaptureRules.is_capturable(id), "%s can be built with and brought to life" % BlockIds.display_name(id))


func test_a_desert_block_gets_its_icon_from_its_page() -> void:
	BlockIcons._cache.erase(BlockIds.CACTUS)
	var icon := BlockIcons.icon(BlockIds.CACTUS) as AtlasTexture
	assert_not_null(icon)
	assert_eq(icon.atlas.resource_path, DesertBlocks.FILES[0])
	var side: Vector2i = DesertBlocks.TILES[BlockIds.CACTUS][1]
	assert_eq(icon.region, Rect2(side.x * 16, side.y * 16, 16, 16))
	BlockIcons._cache.erase(BlockIds.CACTUS)
