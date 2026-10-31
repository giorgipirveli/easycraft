extends GutTest
## Owner feedback #39 (spec §14.2a): the Dragon Realm's blocks, ids 224-239 on block atlas page 11, drawn in both
## styles (data/blocks/pages/dragon.png and its realistic twin). Sky grass (the islands' violet moss), floatstone and
## deep floatstone (the islands' rock), glowing crystal spires, giant mushrooms (a stem and a glowing cap), emerald
## dragon scales and red ember scales, starglass, moon lamps, clouds you walk through, the nests dragon eggs lie in,
## floatstone bricks, and two blocks only the realm's secrets build: dragon gold (a treasure) and fake floatstone (a
## hidden door).


func test_every_dragon_block_is_on_page_11() -> void:
	assert_eq(DragonBlocks.PAGE, 11)
	for id: int in DragonBlocks.TILES:
		assert_between(id, 224, 239, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), DragonBlocks.PAGE, BlockIds.display_name(id))
	assert_lte(DragonBlocks.TILES.size(), 16, "one page: 224-239")
	assert_gte(DragonBlocks.TILES.size(), 13)
	assert_gte(BlockIds.COUNT, 240)


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	for id: int in DragonBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = DragonBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(DragonBlocks.PAGE, kind), BlockIds.display_name(id))
	assert_eq(BlockLibrary.tiles_of(BlockIds.SKY_GRASS), (DragonBlocks.TILES[BlockIds.SKY_GRASS] as Array).slice(0, 3))


func test_tiles_stay_inside_the_8_by_8_page() -> void:
	for id: int in DragonBlocks.TILES:
		var t: Array = DragonBlocks.TILES[id]
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t[i]), "%s tile %d" % [BlockIds.display_name(id), i])
		assert_true([&"opaque", &"cutout", &"glow"].has(t[3]), BlockIds.display_name(id))


func test_both_styles_have_the_page_files() -> void:
	assert_eq(DragonBlocks.FILES, ["res://data/blocks/pages/dragon.png", "res://data/blocks/pages/dragon_albedo.png",
		"res://data/blocks/pages/dragon_normal.png"])
	var pixel := load(DragonBlocks.FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	for f: String in [DragonBlocks.FILES[1], DragonBlocks.FILES[2]]:
		var tex := load(f) as Texture2D
		assert_not_null(tex, f)
		assert_eq(tex.get_width(), 2048 if f == DragonBlocks.FILES[1] else 1024, "8 tiles of 256 px across (the normal map imported at half size; rows: test_page_sizes.gd): %s" % f)


func test_the_style_switch_restyles_the_dragon_page() -> void:
	BlockLibrary.build()
	var before := BlockLibrary.style
	BlockLibrary.set_style("realistic")
	var mat := BlockLibrary.page_material(DragonBlocks.PAGE, &"opaque")
	assert_eq(mat.albedo_texture.resource_path, DragonBlocks.FILES[1])
	assert_true(mat.normal_enabled)
	BlockLibrary.set_style("blocky")
	assert_eq(BlockLibrary.page_material(DragonBlocks.PAGE, &"opaque").albedo_texture.resource_path, DragonBlocks.FILES[0])
	assert_false(BlockLibrary.page_material(DragonBlocks.PAGE, &"opaque").normal_enabled)
	BlockLibrary.set_style(before)


func test_every_dragon_tile_is_drawn_in_the_pixel_page() -> void:
	var img := (load(DragonBlocks.FILES[0]) as Texture2D).get_image()
	for id: int in DragonBlocks.TILES:
		for i in 3:
			var t: Vector2i = DragonBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if img.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 20, "%s tile %s is drawn" % [BlockIds.display_name(id), t])


func test_the_realistic_twin_has_every_tile_too() -> void:
	var img := (load(DragonBlocks.FILES[1]) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	for id: int in DragonBlocks.TILES:
		for i in 3:
			var t: Vector2i = DragonBlocks.TILES[id][i]
			var painted := 0
			for p: Vector2i in [Vector2i(128, 128), Vector2i(40, 60), Vector2i(12, 12), Vector2i(200, 90), Vector2i(90, 210)]:
				if img.get_pixel(t.x * 256 + p.x, t.y * 256 + p.y).a > 0.1:
					painted += 1
			assert_gt(painted, 0, "%s tile %s is painted" % [BlockIds.display_name(id), t])


func test_names_and_validity() -> void:
	for id: int in DragonBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_breakable(id), BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.SKY_GRASS), "Sky Grass")
	assert_eq(BlockIds.display_name(BlockIds.FLOATSTONE), "Floatstone")
	assert_eq(BlockIds.display_name(BlockIds.DRAGON_SCALE), "Dragon Scale")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_FLOATSTONE), "Floatstone", "a hidden door is named like the wall it hides in")


## Blocks and items share one id space (hotbars, bags): no block of the page may take an item's id.
func test_no_dragon_block_takes_an_item_id() -> void:
	for id: int in DragonBlocks.TILES:
		assert_false(ItemIds.is_item(id), "%d (%s) is an item id" % [id, BlockIds.display_name(id)])
	for id in range(224, 240):
		assert_false(ItemIds.is_item(id), "%d is the Dragon Realm's page" % id)


## The portal cores of owner 39 live on page 10 (212-215, 222): the realm's page never reaches back there.
func test_the_realm_leaves_page_10_alone() -> void:
	for id: int in DragonBlocks.TILES:
		assert_false(id >= 208 and id <= 223, BlockIds.display_name(id))


func test_clouds_are_walked_through_and_the_rest_is_solid() -> void:
	var lib := BlockLibrary.build()
	assert_false(BlockIds.is_solid(BlockIds.CLOUD))
	assert_true(BlockIds.NON_SOLID.has(BlockIds.CLOUD))
	var m := lib.models[BlockIds.CLOUD] as VoxelBlockyModel
	assert_true(m.collision_aabbs.is_empty(), "no box")
	assert_false(m.is_mesh_collision_enabled(0), "no physics surface")
	for id: int in DragonBlocks.TILES:
		if id == BlockIds.CLOUD:
			continue
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		assert_false((lib.models[id] as VoxelBlockyModel).collision_aabbs.is_empty(), BlockIds.display_name(id))


func test_see_through_and_glowing_blocks() -> void:
	for id in [BlockIds.CLOUD, BlockIds.STARGLASS]:
		assert_eq(DragonBlocks.TILES[id][3], &"cutout", BlockIds.display_name(id))
	for id in [BlockIds.CRYSTAL_SPIRE, BlockIds.GLOW_CAP, BlockIds.MOON_LAMP, BlockIds.DRAGON_GOLD]:
		assert_eq(DragonBlocks.TILES[id][3], &"glow", BlockIds.display_name(id))
	var lib := BlockLibrary.build()
	var glass := lib.models[BlockIds.STARGLASS] as VoxelBlockyModel
	assert_gt(glass.transparency_index, 0, "starglass next to starglass keeps its faces")
	assert_false((lib.models[BlockIds.CLOUD] as VoxelBlockyModel).culls_neighbors, "an island shows through a cloud's gaps")


## Starglass's transparency index is its own: no other page's see-through block has it.
func test_starglass_has_a_transparency_index_no_other_page_uses() -> void:
	var mine: int = (DragonBlocks.TILES[BlockIds.STARGLASS][4] as Dictionary).transparency
	var others: Array[int] = []
	others.append_array(BlockLibrary.TRANSPARENCY.values())
	for tiles: Dictionary in [DesertBlocks.TILES, FrostBlocks.TILES, CandyBlocks.TILES]:
		for id: int in tiles:
			var t: Array = tiles[id]
			if t.size() > 4 and (t[4] as Dictionary).has("transparency"):
				others.append(int(t[4].transparency))
	assert_false(others.has(mine), "index %d is free (others: %s)" % [mine, others])


## The realm's blocks are gathered and traded there; the two its secrets build are never picked, and breaking
## them gives what they look like (dragon gold is a treasure: it gives itself); sky grass gives floatstone, like
## grass gives dirt.
func test_dragon_blocks_stay_out_of_the_sandbox_palette_and_drop_what_they_look_like() -> void:
	for id: int in DragonBlocks.TILES:
		assert_false(BlockIds.PLACEABLE.has(id), BlockIds.display_name(id))
	assert_eq(GatherRules.drop(BlockIds.FAKE_FLOATSTONE, GatherRules.NONE), BlockIds.FLOATSTONE)
	assert_eq(GatherRules.drop(BlockIds.SKY_GRASS, GatherRules.NONE), BlockIds.FLOATSTONE)
	assert_eq(GatherRules.drop(BlockIds.DRAGON_SCALE, GatherRules.NONE), BlockIds.DRAGON_SCALE)
	assert_eq(GatherRules.drop(BlockIds.CLOUD, GatherRules.NONE), BlockIds.CLOUD, "a cloud to build with")
	assert_eq(GatherRules.drop(BlockIds.DRAGON_GOLD, GatherRules.WOOD), BlockIds.DRAGON_GOLD, "a treasure")
	var giveable := ChatCommands.giveable_ids()
	for id in [BlockIds.DRAGON_GOLD, BlockIds.FAKE_FLOATSTONE]:
		assert_false(giveable.has(id), "/give never hands out %s" % BlockIds.display_name(id))
	assert_eq(ChatCommands.parse("/give floatstone").get("id"), BlockIds.FLOATSTONE, "the look-alike never takes the name")
	assert_eq(ChatCommands.parse("/give dragon scale").get("id"), BlockIds.DRAGON_SCALE)


## The Magic Wand never wakes the realm's natural ground or its clouds; scales, mushrooms and spires can come
## alive, like logs and leaves.
func test_the_dragon_ground_never_comes_alive() -> void:
	for id: int in BlockIds.DRAGON_GROUND:
		assert_false(CaptureRules.is_capturable(id), BlockIds.display_name(id))
	for id in [BlockIds.FAKE_FLOATSTONE, BlockIds.CLOUD]:
		assert_false(CaptureRules.is_capturable(id), BlockIds.display_name(id))
	for id in [BlockIds.DRAGON_SCALE, BlockIds.EMBER_SCALE, BlockIds.MUSHROOM_STEM, BlockIds.GLOW_CAP,
			BlockIds.CRYSTAL_SPIRE, BlockIds.STARGLASS, BlockIds.MOON_LAMP]:
		assert_true(CaptureRules.is_capturable(id), "%s can be built with and brought to life" % BlockIds.display_name(id))


## The lists of natural blocks know the realm: bot builders build on its ground and lean on its mushrooms, a
## falling star lands on it, the axe fells a giant mushroom.
func test_dragon_ground_is_natural_ground_everywhere() -> void:
	assert_true(BlockIds.DRAGON_GROUND.has(BlockIds.SKY_GRASS))
	assert_true(BlockIds.DRAGON_GROUND.has(BlockIds.FLOATSTONE))
	for id: int in BlockIds.DRAGON_GROUND:
		assert_true(BotRules.GROUND.has(id), "bots build on %s" % BlockIds.display_name(id))
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
		assert_true(SurpriseRules.METEOR_REPLACES.has(id), "a meteor lands on %s" % BlockIds.display_name(id))
	for id in [BlockIds.MUSHROOM_STEM, BlockIds.GLOW_CAP, BlockIds.CRYSTAL_SPIRE, BlockIds.CLOUD]:
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
	for id in [BlockIds.DRAGON_SCALE, BlockIds.STARGLASS, BlockIds.MOON_LAMP, BlockIds.FLOATSTONE_BRICK]:
		assert_false(BotRules.NATURAL.has(id), "%s is built, not natural" % BlockIds.display_name(id))
		assert_false(SurpriseRules.METEOR_REPLACES.has(id), "a meteor never smashes %s" % BlockIds.display_name(id))
	assert_true(ToolPowers.GROUND.has(BlockIds.SKY_GRASS), "a giant mushroom stands on sky grass")
	assert_eq(ToolPowers.LEAVES_OF.get(BlockIds.MUSHROOM_STEM), BlockIds.GLOW_CAP)


func test_fake_floatstone_is_a_fake_wall_a_knock_opens() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_FLOATSTONE))
	assert_false(SecretRules.is_fake_wall(BlockIds.FLOATSTONE))


func test_a_dragon_block_gets_its_icon_from_its_page() -> void:
	BlockIcons._cache.erase(BlockIds.DRAGON_SCALE)
	var icon := BlockIcons.icon(BlockIds.DRAGON_SCALE) as AtlasTexture
	assert_not_null(icon)
	assert_eq(icon.atlas.resource_path, DragonBlocks.FILES[0])
	var side: Vector2i = DragonBlocks.TILES[BlockIds.DRAGON_SCALE][1]
	assert_eq(icon.region, Rect2(side.x * 16, side.y * 16, 16, 16))
	BlockIcons._cache.erase(BlockIds.DRAGON_SCALE)
