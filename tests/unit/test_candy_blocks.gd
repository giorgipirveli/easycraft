extends GutTest
## M3 Task 4 (spec §14.1): the Candy Kingdom's blocks, ids 176-191 on block atlas page 8, drawn in both
## styles (data/blocks/pages/candy.png and its realistic twin). Frosting, cake sponge, chocolate, candy
## cane, lollipop, green and red gumdrops (bouncy), cream and jam (a cake mountain's layers), sugar glass,
## gingerbread, candy lamps, cotton candy you walk through, sprinkles, and two blocks only the kingdom's
## secrets build: golden candy (a treasure) and fake chocolate (a hidden door).


func test_every_candy_block_is_on_page_8() -> void:
	assert_eq(CandyBlocks.PAGE, 8)
	for id: int in CandyBlocks.TILES:
		assert_between(id, 176, 191, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), CandyBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(CandyBlocks.TILES.size(), 16, "the whole page: 176-191")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	for id: int in CandyBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = CandyBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(CandyBlocks.PAGE, kind), BlockIds.display_name(id))
	assert_eq(BlockLibrary.tiles_of(BlockIds.FROSTING), (CandyBlocks.TILES[BlockIds.FROSTING] as Array).slice(0, 3))


func test_tiles_stay_inside_the_8_by_8_page() -> void:
	for id: int in CandyBlocks.TILES:
		var t: Array = CandyBlocks.TILES[id]
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t[i]), "%s tile %d" % [BlockIds.display_name(id), i])
		assert_true([&"opaque", &"cutout", &"glow"].has(t[3]), BlockIds.display_name(id))


func test_both_styles_have_the_page_files() -> void:
	assert_eq(CandyBlocks.FILES, ["res://data/blocks/pages/candy.png", "res://data/blocks/pages/candy_albedo.png",
		"res://data/blocks/pages/candy_normal.png"])
	var pixel := load(CandyBlocks.FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for f: String in [CandyBlocks.FILES[1], CandyBlocks.FILES[2]]:
		var tex := load(f) as Texture2D
		assert_not_null(tex, f)
		assert_eq(tex.get_width(), 2048 if f == CandyBlocks.FILES[1] else 1024, "8 tiles of 256 px across (the normal map imported at half size; rows: test_page_sizes.gd): %s" % f)


func test_the_style_switch_restyles_the_candy_page() -> void:
	BlockLibrary.build()
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	var mat := BlockLibrary.page_material(CandyBlocks.PAGE, &"opaque")
	assert_eq(mat.albedo_texture.resource_path, CandyBlocks.FILES[1])
	assert_true(mat.normal_enabled)
	BlockLibrary.set_style("blocky")
	assert_eq(BlockLibrary.page_material(CandyBlocks.PAGE, &"opaque").albedo_texture.resource_path, CandyBlocks.FILES[0])
	assert_false(BlockLibrary.page_material(CandyBlocks.PAGE, &"opaque").normal_enabled)
	BlockLibrary.set_style(before)


func test_every_candy_tile_is_drawn_in_the_pixel_page() -> void:
	var img := (load(CandyBlocks.FILES[0]) as Texture2D).get_image()
	for id: int in CandyBlocks.TILES:
		for i in 3:
			var t: Vector2i = CandyBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if img.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 20, "%s tile %s is drawn" % [BlockIds.display_name(id), t])


func test_the_realistic_twin_has_every_tile_too() -> void:
	var img := (load(CandyBlocks.FILES[1]) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	for id: int in CandyBlocks.TILES:
		var t: Vector2i = CandyBlocks.TILES[id][1]
		var c := img.get_pixel(t.x * 256 + 128, t.y * 256 + 128)
		var edge := img.get_pixel(t.x * 256 + 40, t.y * 256 + 60)
		var frame := img.get_pixel(t.x * 256 + 12, t.y * 256 + 12)   # see-through blocks have a frame
		assert_true(c.a > 0.1 or edge.a > 0.1 or frame.a > 0.1, "%s side tile %s is painted" % [BlockIds.display_name(id), t])


func test_names_and_validity() -> void:
	for id: int in CandyBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_breakable(id), BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.FROSTING), "Frosting")
	assert_eq(BlockIds.display_name(BlockIds.CANDY_CANE), "Candy Cane")
	assert_eq(BlockIds.display_name(BlockIds.GUMDROP), "Green Gumdrop")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_CHOCOLATE), "Chocolate", "a hidden door is named like the wall it hides in")
	assert_gte(BlockIds.COUNT, 192)


func test_cotton_candy_is_walked_through_and_the_rest_is_solid() -> void:
	var lib := BlockLibrary.build()
	assert_false(BlockIds.is_solid(BlockIds.COTTON_CANDY))
	var m := lib.models[BlockIds.COTTON_CANDY] as VoxelBlockyModel
	assert_true(m.collision_aabbs.is_empty(), "no box")
	assert_false(m.is_mesh_collision_enabled(0), "no physics surface")
	for id in [BlockIds.FROSTING, BlockIds.CHOCOLATE, BlockIds.GUMDROP, BlockIds.SUGAR_GLASS, BlockIds.FAKE_CHOCOLATE,
			BlockIds.LOLLIPOP]:
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		assert_false((lib.models[id] as VoxelBlockyModel).collision_aabbs.is_empty(), BlockIds.display_name(id))


func test_see_through_and_glowing_blocks() -> void:
	for id in [BlockIds.COTTON_CANDY, BlockIds.SUGAR_GLASS]:
		assert_eq(CandyBlocks.TILES[id][3], &"cutout", BlockIds.display_name(id))
	for id in [BlockIds.GOLDEN_CANDY, BlockIds.CANDY_LAMP]:
		assert_eq(CandyBlocks.TILES[id][3], &"glow", BlockIds.display_name(id))
	var lib := BlockLibrary.build()
	assert_false((lib.models[BlockIds.COTTON_CANDY] as VoxelBlockyModel).culls_neighbors, "the ground shows through it")
	assert_gt((lib.models[BlockIds.SUGAR_GLASS] as VoxelBlockyModel).transparency_index, 0, "glass next to glass keeps its faces")


## The kingdom's own blocks are gathered and traded there; the two its secrets build are never picked,
## and breaking them gives what they look like (golden candy is a treasure: it gives itself).
func test_candy_blocks_stay_out_of_the_sandbox_palette_and_drop_what_they_look_like() -> void:
	for id: int in CandyBlocks.TILES:
		assert_false(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
	assert_eq(GatherRules.drop(BlockIds.FAKE_CHOCOLATE, GatherRules.NONE), BlockIds.CHOCOLATE)
	assert_eq(GatherRules.drop(BlockIds.FROSTING, GatherRules.NONE), BlockIds.FROSTING, "pink and pretty: kept")
	assert_eq(GatherRules.drop(BlockIds.GOLDEN_CANDY, GatherRules.WOOD), BlockIds.GOLDEN_CANDY, "a treasure")
	var giveable := ChatCommands.giveable_ids()
	for id in [BlockIds.GOLDEN_CANDY, BlockIds.FAKE_CHOCOLATE]:
		assert_false(giveable.has(id), "/give never hands out %s" % BlockIds.display_name(id))
	assert_eq(ChatCommands.parse("/give chocolate").get("id"), BlockIds.CHOCOLATE, "the look-alike never takes the name")
	assert_eq(ChatCommands.parse("/give frosting").get("id"), BlockIds.FROSTING)


## The Magic Wand never wakes the kingdom's natural ground (a build on a gumdrop hill comes alive without
## the hill); candy canes, lollipops, gingerbread and sugar glass can come alive, like logs and leaves.
func test_the_candy_ground_never_comes_alive() -> void:
	for id: int in BlockIds.CANDY_GROUND:
		assert_false(CaptureRules.is_capturable(id), BlockIds.display_name(id))
	for id in [BlockIds.CANDY_CANE, BlockIds.LOLLIPOP, BlockIds.GINGERBREAD, BlockIds.SUGAR_GLASS, BlockIds.CANDY_LAMP]:
		assert_true(CaptureRules.is_capturable(id), "%s can be built with and brought to life" % BlockIds.display_name(id))


## The lists of natural blocks know the kingdom (like the lead did for the desert): bot builders build on
## its ground and lean on its trees, a falling star lands on it, the axe fells a lollipop tree.
func test_candy_ground_is_natural_ground_everywhere() -> void:
	for id: int in BlockIds.CANDY_GROUND:
		assert_true(BotRules.GROUND.has(id), "bots build on %s" % BlockIds.display_name(id))
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
		assert_true(SurpriseRules.METEOR_REPLACES.has(id), "a meteor lands on %s" % BlockIds.display_name(id))
	for id in [BlockIds.CANDY_CANE, BlockIds.LOLLIPOP, BlockIds.COTTON_CANDY]:
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
	for id in [BlockIds.GINGERBREAD, BlockIds.SUGAR_GLASS, BlockIds.CANDY_LAMP]:
		assert_false(BotRules.NATURAL.has(id), "%s is built, not natural" % BlockIds.display_name(id))
		assert_false(SurpriseRules.METEOR_REPLACES.has(id), "a meteor never smashes %s" % BlockIds.display_name(id))
	assert_true(ToolPowers.GROUND.has(BlockIds.FROSTING), "a lollipop tree stands on frosting")
	assert_eq(ToolPowers.LEAVES_OF.get(BlockIds.CANDY_CANE), BlockIds.LOLLIPOP)


func test_a_candy_block_gets_its_icon_from_its_page() -> void:
	BlockIcons._cache.erase(BlockIds.CANDY_CANE)
	var icon := BlockIcons.icon(BlockIds.CANDY_CANE) as AtlasTexture
	assert_not_null(icon)
	assert_eq(icon.atlas.resource_path, CandyBlocks.FILES[0])
	var side: Vector2i = CandyBlocks.TILES[BlockIds.CANDY_CANE][1]
	assert_eq(icon.region, Rect2(side.x * 16, side.y * 16, 16, 16))
	BlockIcons._cache.erase(BlockIds.CANDY_CANE)
