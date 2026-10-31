extends GutTest
## Owner feedback #55 (spec §21.2): the Moon's blocks, ids 288-298 on block atlas page 15, drawn in both styles
## (data/blocks/pages/moon.png and its realistic twin): silvery moon dust over moon rock and deep moon rock, glowing
## moon crystals, moon cheese (the hidden rooms' walls), the Moon Base's silver panels, portholes and lights, the teal
## landing pad with its golden star, and two blocks only the secrets build: star gold (a treasure) and fake moon rock
## (a hidden door).

const GLOWS: Array[int] = [BlockIds.MOON_CRYSTAL, BlockIds.PORTHOLE, BlockIds.LANDING_PAD, BlockIds.STAR_GOLD,
	BlockIds.BASE_LIGHT]


func test_every_moon_block_is_on_page_15() -> void:
	assert_eq(MoonBlocks.PAGE, 15)
	for id: int in MoonBlocks.TILES:
		assert_between(id, 288, 303, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), MoonBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(MoonBlocks.TILES.size(), 11)
	assert_gte(BlockIds.COUNT, 299)


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	for id: int in MoonBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = MoonBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(MoonBlocks.PAGE, kind), BlockIds.display_name(id))


func test_the_glowing_ones_glow_and_the_rest_are_solid_cubes() -> void:
	for id: int in MoonBlocks.TILES:
		assert_eq(MoonBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))


func test_tiles_stay_inside_the_8_by_8_page() -> void:
	for id: int in MoonBlocks.TILES:
		var t: Array = MoonBlocks.TILES[id]
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(t[i]), "%s tile %d" % [BlockIds.display_name(id), i])


func test_both_styles_have_the_page_files() -> void:
	assert_eq(MoonBlocks.FILES, ["res://data/blocks/pages/moon.png", "res://data/blocks/pages/moon_albedo.png",
		"res://data/blocks/pages/moon_normal.png"])
	var pixel := load(MoonBlocks.FILES[0]) as Texture2D
	assert_eq(pixel.get_size(), Vector2(128, 128), "8 x 8 tiles of 16 px")
	assert_eq((load(MoonBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(MoonBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")


func test_every_moon_tile_is_drawn_in_both_pages() -> void:
	var img := (load(MoonBlocks.FILES[0]) as Texture2D).get_image()
	var real := (load(MoonBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	for id: int in MoonBlocks.TILES:
		for i in 3:
			var t: Vector2i = MoonBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if img.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1, "%s tile %s is painted" % [BlockIds.display_name(id), t])


func test_names_and_validity() -> void:
	for id: int in MoonBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
	assert_eq(BlockIds.display_name(BlockIds.MOON_DUST), "Moon Dust")
	assert_eq(BlockIds.display_name(BlockIds.LANDING_PAD), "Landing Pad")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_MOON_ROCK), "Moon Rock", "a hidden door is named like its wall")


func test_the_moons_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_MOON_ROCK))
	assert_eq(GatherRules.drop(BlockIds.FAKE_MOON_ROCK, GatherRules.NONE), BlockIds.MOON_ROCK)
	assert_eq(GatherRules.drop(BlockIds.STAR_GOLD, GatherRules.WOOD), BlockIds.STAR_GOLD, "a treasure")
	for id in [BlockIds.STAR_GOLD, BlockIds.FAKE_MOON_ROCK]:
		assert_has(ChatCommands.NEVER_GIVEN, id, "found, never given")
	for id: int in BlockIds.SPACE_GROUND:
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes the Moon's ground")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_MOON_ROCK)
	assert_has(BotRules.NATURAL, BlockIds.MOON_CRYSTAL)
