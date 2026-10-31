extends GutTest
## M3 Task 3 (spec §14.1): Frostpeak's blocks, ids 80-95 on block atlas page 2, drawn in both styles
## (data/blocks/pages/frost.png and its realistic twin): snow, snowy grass, packed snow, ice and blue ice
## (slippery), pine wood and pine needles (leaves: a snowy top), frozen ore, snow bricks, an ice lantern
## (glows), frosted glass, and the one block only Frostpeak's secrets build: a fake packed-snow floor (a
## hidden way down, like the fake wall).


func test_every_frost_block_is_on_page_2() -> void:
	assert_eq(FrostBlocks.PAGE, 2)
	for id: int in FrostBlocks.TILES:
		assert_between(id, 80, 95, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), FrostBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(FrostBlocks.TILES.size(), 12, "12 blocks (92-95 are free)")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	for id: int in FrostBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = FrostBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(FrostBlocks.PAGE, kind), BlockIds.display_name(id))
	assert_eq(BlockLibrary.tiles_of(BlockIds.SNOW), (FrostBlocks.TILES[BlockIds.SNOW] as Array).slice(0, 3))


func test_tiles_stay_inside_the_8_by_8_page() -> void:
	for id: int in FrostBlocks.TILES:
		var t: Array = FrostBlocks.TILES[id]
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t[i]), "%s tile %d" % [BlockIds.display_name(id), i])
		assert_true([&"opaque", &"cutout", &"glow"].has(t[3]), BlockIds.display_name(id))


func test_both_styles_have_the_page_files() -> void:
	assert_eq(FrostBlocks.FILES, ["res://data/blocks/pages/frost.png", "res://data/blocks/pages/frost_albedo.png",
		"res://data/blocks/pages/frost_normal.png"])
	var pixel := load(FrostBlocks.FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for f: String in [FrostBlocks.FILES[1], FrostBlocks.FILES[2]]:
		var tex := load(f) as Texture2D
		assert_not_null(tex, f)
		assert_eq(tex.get_width(), 2048 if f == FrostBlocks.FILES[1] else 1024, "8 tiles of 256 px across (the normal map imported at half size; rows: test_page_sizes.gd): %s" % f)


func test_the_style_switch_restyles_the_frost_page() -> void:
	BlockLibrary.build()
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	var mat := BlockLibrary.page_material(FrostBlocks.PAGE, &"opaque")
	assert_eq(mat.albedo_texture.resource_path, FrostBlocks.FILES[1])
	assert_true(mat.normal_enabled)
	BlockLibrary.set_style("blocky")
	assert_eq(BlockLibrary.page_material(FrostBlocks.PAGE, &"opaque").albedo_texture.resource_path, FrostBlocks.FILES[0])
	assert_false(BlockLibrary.page_material(FrostBlocks.PAGE, &"opaque").normal_enabled)
	BlockLibrary.set_style(before)


func _drawn(img: Image, t: Vector2i) -> int:
	var seen := 0
	for y in 16:
		for x in 16:
			if img.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
				seen += 1
	return seen


func test_every_frost_tile_is_drawn_in_both_pages() -> void:
	var pixel := (load(FrostBlocks.FILES[0]) as Texture2D).get_image()
	var real := (load(FrostBlocks.FILES[1]) as Texture2D).get_image()
	real.decompress()
	real.resize(128, 128, Image.INTERPOLATE_NEAREST)
	for id: int in FrostBlocks.TILES:
		for i in 3:
			var t: Vector2i = FrostBlocks.TILES[id][i]
			assert_gt(_drawn(pixel, t), 20, "%s tile %s is drawn (blocky)" % [BlockIds.display_name(id), t])
			assert_gt(_drawn(real, t), 20, "%s tile %s is drawn (realistic)" % [BlockIds.display_name(id), t])


## Snow is white and ice is blue in both styles (a child tells them apart at a glance).
func test_snow_looks_white_and_ice_looks_blue() -> void:
	for f: String in [FrostBlocks.FILES[0], FrostBlocks.FILES[1]]:
		var img := (load(f) as Texture2D).get_image()
		img.decompress()
		img.resize(128, 128, Image.INTERPOLATE_BILINEAR)
		var snow := _mean(img, FrostBlocks.TILES[BlockIds.SNOW][0])
		var ice := _mean(img, FrostBlocks.TILES[BlockIds.ICE][1])
		var blue := _mean(img, FrostBlocks.TILES[BlockIds.BLUE_ICE][1])
		assert_gt(snow.v, 0.8, "%s: snow is bright" % f)
		assert_lt(snow.s, 0.15, "%s: snow is white" % f)
		assert_gt(ice.b, ice.r + 0.08, "%s: ice is blue" % f)
		assert_gt(blue.s, ice.s, "%s: blue ice is bluer than ice" % f)


func _mean(img: Image, t: Vector2i) -> Color:
	var sum := Color(0, 0, 0, 0)
	for y in 16:
		for x in 16:
			sum += img.get_pixel(t.x * 16 + x, t.y * 16 + y)
	return Color(sum.r / 256.0, sum.g / 256.0, sum.b / 256.0)


func test_names_and_validity() -> void:
	for id: int in FrostBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_breakable(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s is solid" % BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.SNOW), "Snow")
	assert_eq(BlockIds.display_name(BlockIds.ICE), "Ice")
	assert_eq(BlockIds.display_name(BlockIds.PINE_LOG), "Pine Wood")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_SNOW), "Packed Snow", "a hidden way down is named like the floor it hides in")
	for free in range(92, 96):
		assert_false(BlockIds.is_valid(free), "%d has no block yet" % free)


func test_see_through_and_glowing_blocks() -> void:
	for id in [BlockIds.PINE_NEEDLES, BlockIds.FROSTED_GLASS]:
		assert_eq(FrostBlocks.TILES[id][3], &"cutout", BlockIds.display_name(id))
	assert_eq(FrostBlocks.TILES[BlockIds.ICE_LANTERN][3], &"glow")
	var lib := BlockLibrary.build()
	assert_false((lib.models[BlockIds.PINE_NEEDLES] as VoxelBlockyModel).culls_neighbors, "the trunk shows through the needles")
	assert_eq((lib.models[BlockIds.PINE_NEEDLES] as VoxelBlockyModel).transparency_index,
		(lib.models[BlockIds.LEAVES] as VoxelBlockyModel).transparency_index, "needles are leaves")
	assert_gt((lib.models[BlockIds.FROSTED_GLASS] as VoxelBlockyModel).transparency_index, 0, "glass next to glass keeps its faces")
	var needles: Array = FrostBlocks.TILES[BlockIds.PINE_NEEDLES]
	assert_ne(needles[0], needles[1], "snow lies on the needles' top")


## Frostpeak's blocks are gathered and traded there; its secret floor is never picked and breaks into
## what it looks like; pine needles drop nothing, like leaves.
func test_frost_blocks_stay_out_of_the_sandbox_palette_and_drop_what_they_look_like() -> void:
	for id: int in FrostBlocks.TILES:
		assert_false(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
	assert_eq(GatherRules.drop(BlockIds.FAKE_SNOW, GatherRules.NONE), BlockIds.PACKED_SNOW)
	assert_eq(GatherRules.drop(BlockIds.PINE_NEEDLES, GatherRules.NONE), BlockIds.AIR, "like leaves")
	assert_eq(GatherRules.drop(BlockIds.SNOWY_GRASS, GatherRules.NONE), BlockIds.DIRT, "like grass")
	assert_eq(GatherRules.drop(BlockIds.SNOW, GatherRules.NONE), BlockIds.SNOW)
	assert_eq(GatherRules.drop(BlockIds.ICE, GatherRules.NONE), BlockIds.ICE)
	assert_eq(GatherRules.drop(BlockIds.FROZEN_ORE, GatherRules.NONE), BlockIds.AIR, "an ore needs a pickaxe")
	assert_eq(GatherRules.drop(BlockIds.FROZEN_ORE, GatherRules.WOOD), BlockIds.FROZEN_ORE)
	assert_false(ChatCommands.giveable_ids().has(BlockIds.FAKE_SNOW), "/give never hands out the secret floor")
	assert_eq(ChatCommands.parse("/give packed snow").get("id"), BlockIds.PACKED_SNOW, "the look-alike never takes the name")
	assert_eq(ChatCommands.parse("/give ice").get("id"), BlockIds.ICE)


## The Magic Wand never wakes Frostpeak's natural ground (a snowman on a snowfield comes alive without
## the field); what children build with (packed snow, snow bricks, blue ice, pine wood) can come alive.
func test_the_frost_ground_never_comes_alive() -> void:
	for id: int in BlockIds.FROST_GROUND:
		assert_false(CaptureRules.is_capturable(id), BlockIds.display_name(id))
	for id in [BlockIds.SNOW, BlockIds.SNOWY_GRASS, BlockIds.ICE, BlockIds.FAKE_SNOW]:
		assert_false(CaptureRules.is_capturable(id), BlockIds.display_name(id))
	for id in [BlockIds.PACKED_SNOW, BlockIds.SNOW_BRICK, BlockIds.BLUE_ICE, BlockIds.PINE_LOG, BlockIds.ICE_LANTERN]:
		assert_true(CaptureRules.is_capturable(id), "%s can be built with and brought to life" % BlockIds.display_name(id))


## The lists of natural blocks know Frostpeak (the lead's desert rule, dc17713): builder friends build on
## its ground and lean on its trees, falling stars land on it, and the axe fells pines.
func test_the_natural_block_lists_know_frostpeak() -> void:
	for id: int in BlockIds.FROST_GROUND:
		assert_true(BotRules.GROUND.has(id), "a builder builds on %s" % BlockIds.display_name(id))
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
		assert_true(SurpriseRules.METEOR_REPLACES.has(id), "a star lands on %s" % BlockIds.display_name(id))
	for id in [BlockIds.PINE_LOG, BlockIds.PINE_NEEDLES, BlockIds.FROZEN_ORE]:
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
	for id in [BlockIds.SNOW_BRICK, BlockIds.FROSTED_GLASS, BlockIds.ICE_LANTERN, BlockIds.PACKED_SNOW]:
		assert_false(BotRules.NATURAL.has(id), "%s is built, not natural" % BlockIds.display_name(id))
		assert_false(SurpriseRules.METEOR_REPLACES.has(id), "a star never smashes %s" % BlockIds.display_name(id))
	assert_eq(ToolPowers.LEAVES_OF.get(BlockIds.PINE_LOG), BlockIds.PINE_NEEDLES, "a pine's needles fall with it")
	for id in [BlockIds.SNOW, BlockIds.SNOWY_GRASS]:
		assert_true(ToolPowers.GROUND.has(id), "a pine stands on %s" % BlockIds.display_name(id))


func test_a_frost_block_gets_its_icon_from_its_page() -> void:
	BlockIcons._cache.erase(BlockIds.ICE)
	var icon := BlockIcons.icon(BlockIds.ICE) as AtlasTexture
	assert_not_null(icon)
	assert_eq(icon.atlas.resource_path, FrostBlocks.FILES[0])
	var side: Vector2i = FrostBlocks.TILES[BlockIds.ICE][1]
	assert_eq(icon.region, Rect2(side.x * 16, side.y * 16, 16, 16))
	BlockIcons._cache.erase(BlockIds.ICE)
