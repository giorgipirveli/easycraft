extends GutTest
## Universe 6, the Glow Caves (spec §5.1; brief docs/superpowers/plans/2026-10-01-glow-caves-brief.md): its blocks,
## ids 768-783 on block atlas page 45, drawn in both styles (data/blocks/pages/glow.png and its realistic twin). Cave
## stone (limestone), glow moss, glowshroom stems and caps in two colours, the glow-worm ceiling, selenite (the Cave of
## Crystals' giant gypsum), flowstone, stalactites and stalagmites, cave lake stone, fungus planks, the spore lamp, cave
## pearls, and two blocks only the caves' secrets build: cave gold (a treasure) and fake cave stone (a hidden door).
## Universe 6's portal core stands with the others on page 10 (id 223).


func test_every_glow_block_is_on_page_45() -> void:
	assert_eq(GlowBlocks.PAGE, 45)
	for id: int in GlowBlocks.TILES:
		assert_between(id, 768, 783, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), GlowBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(GlowBlocks.TILES.size(), 16, "one page: 768-783, every id used")
	assert_eq(BlockIds.COUNT, 784, "COUNT past the page")
	assert_eq(BlockIds.NEXT_PAGE_FIRST_ID, 784, "the next page (46) begins at 784")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	for id: int in GlowBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModel
		assert_not_null(m, "%s has a model" % BlockIds.display_name(id))
		assert_same(m.get_material_override(0), BlockLibrary.block_material(GlowBlocks.PAGE, GlowBlocks.TILES[id]),
			BlockIds.display_name(id))
	assert_eq(BlockLibrary.tiles_of(BlockIds.CAVE_STONE), (GlowBlocks.TILES[BlockIds.CAVE_STONE] as Array).slice(0, 3))


func test_tiles_stay_inside_three_rows_of_the_page() -> void:
	for id: int in GlowBlocks.TILES:
		var t: Array = GlowBlocks.TILES[id]
		for i in 3:
			assert_true(Rect2i(0, 0, 8, 3).has_point(t[i]), "%s tile %d in rows 0-2" % [BlockIds.display_name(id), i])
		assert_true([&"opaque", &"cutout", &"glow"].has(t[3]), BlockIds.display_name(id))


func test_both_styles_have_the_page_files() -> void:
	assert_eq(GlowBlocks.FILES, ["res://data/blocks/pages/glow.png", "res://data/blocks/pages/glow_albedo.png",
		"res://data/blocks/pages/glow_normal.png"])
	var pixel := load(GlowBlocks.FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	var albedo := load(GlowBlocks.FILES[1]) as Texture2D
	assert_eq(albedo.get_width(), 2048)
	assert_eq(BlockLibrary.texture_rows(albedo), 3, "three rows kept (the APK size pass)")
	assert_eq((load(GlowBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")


func test_every_glow_tile_is_drawn_in_both_pages() -> void:
	var img := (load(GlowBlocks.FILES[0]) as Texture2D).get_image()
	var real := (load(GlowBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	for id: int in GlowBlocks.TILES:
		for i in 3:
			var t: Vector2i = GlowBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if img.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 20, "%s pixel tile %s is drawn" % [BlockIds.display_name(id), t])
			var painted := 0
			for p: Vector2i in [Vector2i(128, 128), Vector2i(128, 60), Vector2i(120, 200), Vector2i(128, 40)]:
				if real.get_pixel(t.x * 256 + p.x, t.y * 256 + p.y).a > 0.1:
					painted += 1
			assert_gt(painted, 0, "%s realistic tile %s is painted" % [BlockIds.display_name(id), t])


func test_names_and_validity() -> void:
	for id: int in GlowBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_breakable(id), BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.CAVE_STONE), "Cave Stone")
	assert_eq(BlockIds.display_name(BlockIds.GLOW_MOSS), "Glow Moss")
	assert_eq(BlockIds.display_name(BlockIds.SELENITE), "Selenite Crystal")
	assert_eq(BlockIds.display_name(BlockIds.GLOW_WORMS), "Glow-worm Ceiling")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_CAVE_STONE), "Cave Stone", "a hidden door is named like its wall")
	var names := {}
	for id: int in BlockIds._NAMES:
		if not GlowBlocks.TILES.has(id) or id == BlockIds.FAKE_CAVE_STONE:
			names[BlockIds._NAMES[id]] = id
	for id: int in GlowBlocks.TILES:
		if id != BlockIds.FAKE_CAVE_STONE and id != BlockIds.CAVE_STONE:
			assert_false(names.has(BlockIds.display_name(id)), "%s: a name no other block has" % BlockIds.display_name(id))


func test_no_glow_block_takes_an_item_id() -> void:
	for id in range(768, 784):
		assert_false(ItemIds.is_item(id), "%d is the Glow Caves' page" % id)
	assert_false(ItemIds.is_item(BlockIds.CORE_GLOW))


## Stalactites hang from the roof and stalagmites rise from the floor: two crossed pictures each, walked through, and
## never swaying like a flower (they are stone). A stalactite's pictures reach the cell's top (it hangs from the block
## above); a stalagmite's stand on its floor.
func test_stalactites_and_stalagmites_are_still_crossed_pictures() -> void:
	var lib := BlockLibrary.build()
	for id in [BlockIds.STALACTITE, BlockIds.STALAGMITE]:
		assert_false(BlockIds.is_solid(id), BlockIds.display_name(id))
		assert_true(BlockIds.NON_SOLID.has(id))
		var m := lib.models[id] as VoxelBlockyModelMesh
		assert_not_null(m, "%s is a crossed picture" % BlockIds.display_name(id))
		assert_true(m.collision_aabbs.is_empty())
		var extras: Dictionary = GlowBlocks.TILES[id][4]
		assert_true(extras.get("still", false), "%s never sways" % BlockIds.display_name(id))
		var was := BlockLibrary._sway_on
		BlockLibrary._sway_on = true
		assert_same(BlockLibrary.block_material(GlowBlocks.PAGE, GlowBlocks.TILES[id]),
			BlockLibrary.page_material(GlowBlocks.PAGE, &"cutout"), "the plain cut-out even on HIGH")
		BlockLibrary._sway_on = was
	var hang := (lib.models[BlockIds.STALACTITE] as VoxelBlockyModelMesh).mesh.get_aabb()
	assert_almost_eq(hang.end.y, 1.0, 0.001, "a stalactite touches the roof")
	var stand := (lib.models[BlockIds.STALAGMITE] as VoxelBlockyModelMesh).mesh.get_aabb()
	assert_almost_eq(stand.position.y, 0.0, 0.001, "a stalagmite stands on the floor")


func test_the_rest_is_solid() -> void:
	var lib := BlockLibrary.build()
	for id: int in GlowBlocks.TILES:
		if id == BlockIds.STALACTITE or id == BlockIds.STALAGMITE:
			continue
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		assert_false((lib.models[id] as VoxelBlockyModel).collision_aabbs.is_empty(), BlockIds.display_name(id))


## The glow is the blocks' own (unshaded, no real light per mushroom; the brief's budget): moss, caps, glow-worms,
## selenite, the spore lamp, pearls and gold.
func test_glowing_blocks_shine_by_themselves() -> void:
	for id in [BlockIds.GLOW_MOSS, BlockIds.BLUE_SHROOM, BlockIds.ROSE_SHROOM, BlockIds.GLOW_WORMS, BlockIds.SELENITE,
			BlockIds.SPORE_LAMP, BlockIds.CAVE_PEARL, BlockIds.CAVE_GOLD]:
		assert_eq(GlowBlocks.TILES[id][3], &"glow", BlockIds.display_name(id))
	for id in [BlockIds.CAVE_STONE, BlockIds.FLOWSTONE, BlockIds.LAKE_STONE, BlockIds.FUNGUS_PLANKS,
			BlockIds.SHROOM_STEM, BlockIds.FAKE_CAVE_STONE]:
		assert_eq(GlowBlocks.TILES[id][3], &"opaque", BlockIds.display_name(id))


func test_the_style_switch_restyles_the_glow_page() -> void:
	BlockLibrary.build()
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	assert_eq(BlockLibrary.page_material(GlowBlocks.PAGE, &"opaque").albedo_texture.resource_path, GlowBlocks.FILES[1])
	BlockLibrary.set_style("blocky")
	assert_eq(BlockLibrary.page_material(GlowBlocks.PAGE, &"opaque").albedo_texture.resource_path, GlowBlocks.FILES[0])
	BlockLibrary.set_style(before)


## Gathered and traded in the caves, never in the Sandbox palette; the two its secrets build are never given; a hidden
## door gives cave stone, glow moss gives cave stone (like grass gives dirt).
func test_glow_blocks_stay_out_of_the_palette_and_drop_what_they_look_like() -> void:
	for id: int in GlowBlocks.TILES:
		assert_false(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
	assert_eq(GatherRules.drop(BlockIds.FAKE_CAVE_STONE, GatherRules.NONE), BlockIds.CAVE_STONE)
	assert_eq(GatherRules.drop(BlockIds.GLOW_MOSS, GatherRules.NONE), BlockIds.GLOW_MOSS, "moss is carried to light a way")
	assert_eq(GatherRules.drop(BlockIds.CAVE_GOLD, GatherRules.WOOD), BlockIds.CAVE_GOLD, "a treasure")
	var giveable := ChatCommands.giveable_ids()
	for id in [BlockIds.CAVE_GOLD, BlockIds.FAKE_CAVE_STONE]:
		assert_false(giveable.has(id), "/give never hands out %s" % BlockIds.display_name(id))
	assert_eq(ChatCommands.parse("/give cave stone").get("id"), BlockIds.CAVE_STONE, "the look-alike never takes the name")
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_CAVE_STONE))
	assert_false(SecretRules.is_fake_wall(BlockIds.CAVE_STONE))


## The caves' natural ground is natural everywhere: bots build on it, a meteor lands on it, the wand never wakes it;
## the axe fells a giant glowshroom (its stem to its caps).
func test_the_glow_ground_is_natural_ground() -> void:
	for id in [BlockIds.CAVE_STONE, BlockIds.GLOW_MOSS, BlockIds.LAKE_STONE, BlockIds.FLOWSTONE]:
		assert_true(BlockIds.GLOW_GROUND.has(id), BlockIds.display_name(id))
	for id: int in BlockIds.GLOW_GROUND:
		assert_true(BotRules.GROUND.has(id), "bots build on %s" % BlockIds.display_name(id))
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
		assert_true(SurpriseRules.METEOR_REPLACES.has(id), BlockIds.display_name(id))
		assert_false(CaptureRules.is_capturable(id), "the wand never wakes %s" % BlockIds.display_name(id))
	assert_false(CaptureRules.is_capturable(BlockIds.FAKE_CAVE_STONE))
	for id in [BlockIds.SHROOM_STEM, BlockIds.BLUE_SHROOM, BlockIds.SELENITE, BlockIds.FUNGUS_PLANKS, BlockIds.SPORE_LAMP]:
		assert_true(CaptureRules.is_capturable(id), "%s can come alive" % BlockIds.display_name(id))
	assert_true(ToolPowers.GROUND.has(BlockIds.CAVE_STONE), "a giant glowshroom stands on cave stone")
	assert_true(ToolPowers.GROUND.has(BlockIds.GLOW_MOSS))
	assert_eq(ToolPowers.LEAVES_OF.get(BlockIds.SHROOM_STEM), BlockIds.BLUE_SHROOM)


func test_a_glow_block_gets_its_icon_from_its_page() -> void:
	BlockIcons._cache.erase(BlockIds.SELENITE)
	var icon := BlockIcons.icon(BlockIds.SELENITE) as AtlasTexture
	assert_not_null(icon)
	assert_eq(icon.atlas.resource_path, GlowBlocks.FILES[0])
	BlockIcons._cache.erase(BlockIds.SELENITE)


## Universe 6's portal core: the cores' row on page 10 (two tiles per id at 2 × (id − 208)), glowing.
func test_the_glow_portal_core_stands_with_the_other_cores() -> void:
	assert_eq(BlockIds.CORE_GLOW, 223)
	assert_eq(BlockLibrary.page_of(BlockIds.CORE_GLOW), PortalPage.PAGE)
	assert_eq(PortalPage.CORE_TILES[BlockIds.CORE_GLOW], [Vector2i(7, 3), Vector2i(6, 3), Vector2i(7, 3), &"glow"])
	assert_eq(BlockIds.display_name(BlockIds.CORE_GLOW), "Glow Portal Core")
	var img := (load(PortalPage.FILES[0]) as Texture2D).get_image()
	var seen := 0
	for y in 16:
		for x in 16:
			if img.get_pixel(6 * 16 + x, 3 * 16 + y).a > 0.1:
				seen += 1
	assert_gt(seen, 100, "its side tile is drawn")
