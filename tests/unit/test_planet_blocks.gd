extends GutTest
## Owner feedback #55 (spec §21.2): Planet Boing's blocks (ids 304-312, page 16) and Rainbow Planet's (ids 320-330, page
## 17), drawn in both styles. Boing: lime boing moss over teal soil and purple rock, pink jelly, spring mushrooms (a
## stem and a cap), glowing bulbs, lilac bricks and a fake rock door; boing moss, jelly and spring caps bounce a child
## who lands on them. Rainbow: prism grass over rock in six rainbow stripes, glowing prism crystals, prism bricks and
## lamps, and a fake stripe door.

const PAGES := {16: "boing", 17: "rainbow"}


func _table(page: int) -> Dictionary:
	return BoingBlocks.TILES if page == 16 else RainbowBlocks.TILES


func _files(page: int) -> Array:
	return BoingBlocks.FILES if page == 16 else RainbowBlocks.FILES


func test_every_block_is_on_its_page_and_registered() -> void:
	assert_eq(BoingBlocks.PAGE, 16)
	assert_eq(RainbowBlocks.PAGE, 17)
	var lib := BlockLibrary.build()
	for page: int in PAGES:
		for id: int in _table(page):
			assert_eq(BlockLibrary.page_of(id), page, BlockIds.display_name(id))
			assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
			assert_ne(BlockIds.display_name(id), "")
			assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
			var m := lib.models[id] as VoxelBlockyModelCube
			assert_not_null(m, BlockIds.display_name(id))
			var kind: StringName = _table(page)[id][3]
			assert_same(m.get_material_override(0), BlockLibrary.page_material(page, kind), BlockIds.display_name(id))
			for i in 3:
				assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(_table(page)[id][i]))
	assert_eq(BoingBlocks.TILES.size(), 9)
	assert_eq(RainbowBlocks.TILES.size(), 11)
	assert_gte(BlockIds.COUNT, 331)


func test_both_styles_have_every_tile() -> void:
	for page: int in PAGES:
		var files: Array = _files(page)
		assert_eq(files[0], "res://data/blocks/pages/%s.png" % PAGES[page])
		var pixel := (load(files[0]) as Texture2D).get_image()
		var real := (load(files[1]) as Texture2D).get_image()
		if real.is_compressed():
			real.decompress()
		assert_eq((load(files[2]) as Texture2D).get_width(), 1024, "the normal map at half size")
		for id: int in _table(page):
			for i in 3:
				var t: Vector2i = _table(page)[id][i]
				var seen := 0
				for y in 16:
					for x in 16:
						if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
							seen += 1
				assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
				assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1, "%s tile %s is painted" % [BlockIds.display_name(id), t])


func test_the_bouncy_blocks_bounce() -> void:
	for id in [BlockIds.BOING_MOSS, BlockIds.JELLY, BlockIds.SPRING_CAP]:
		assert_true(CandyRules.is_gumdrop(id), "%s bounces (the gumdrop rule)" % BlockIds.display_name(id))
	for id in [BlockIds.BOING_SOIL, BlockIds.BOING_ROCK, BlockIds.PRISM_GRASS, BlockIds.MOON_DUST]:
		assert_false(CandyRules.is_gumdrop(id), BlockIds.display_name(id))


func test_the_glowing_ones_glow() -> void:
	for id in [BlockIds.BOING_GLOW, BlockIds.PRISM_CRYSTAL, BlockIds.PRISM_LAMP]:
		var page := BlockLibrary.page_of(id)
		assert_eq(_table(page)[id][3], &"glow", BlockIds.display_name(id))


func test_the_rainbow_has_six_stripes_in_order() -> void:
	assert_eq(RainbowBlocks.STRIPES, [BlockIds.RAINBOW_RED, BlockIds.RAINBOW_ORANGE, BlockIds.RAINBOW_YELLOW,
		BlockIds.RAINBOW_GREEN, BlockIds.RAINBOW_BLUE, BlockIds.RAINBOW_VIOLET] as Array[int])


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	for id in [BlockIds.FAKE_BOING_ROCK, BlockIds.FAKE_RAINBOW]:
		assert_true(SecretRules.is_fake_wall(id), BlockIds.display_name(id))
		assert_has(ChatCommands.NEVER_GIVEN, id)
		assert_has(CaptureRules.GROUND, id)
	assert_eq(GatherRules.drop(BlockIds.FAKE_BOING_ROCK, GatherRules.NONE), BlockIds.BOING_ROCK)
	assert_eq(GatherRules.drop(BlockIds.FAKE_RAINBOW, GatherRules.NONE), BlockIds.RAINBOW_BLUE)
	assert_eq(BlockIds.display_name(BlockIds.FAKE_RAINBOW), BlockIds.display_name(BlockIds.RAINBOW_BLUE), "named like its wall")
	assert_eq(GatherRules.drop(BlockIds.BOING_MOSS, GatherRules.NONE), BlockIds.BOING_SOIL, "moss is soil underneath")
	for id: int in BlockIds.SPACE_GROUND:
		assert_has(BotRules.GROUND, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	for id in [BlockIds.BOING_MOSS, BlockIds.JELLY, BlockIds.PRISM_GRASS, BlockIds.RAINBOW_RED, BlockIds.RAINBOW_VIOLET]:
		assert_has(BlockIds.SPACE_GROUND, id)
