extends GutTest
## Cosmos: Mars (world 19, spec §21b.2): its blocks, ids 336-349 on block atlas page 18 (350-351 free), drawn in both
## styles (data/blocks/pages/mars.png and its realistic twin): red Mars dust (iron oxide: rust) over rusty regolith,
## dark basalt and deep basalt, pale layered rock (the dry river beds and the canyon's layers), white polar ice (water
## ice) and frosty dry ice (frozen carbon dioxide), glowing gypsum crystals, the rover's panels, wheels, solar panel
## and light, the old lander's gold foil, and a fake basalt door (the hidden room). The landing pad and star gold are
## the Moon's (every space world's).

const GLOWS: Array[int] = [BlockIds.GYPSUM, BlockIds.ROVER_LIGHT]
const GROUND: Array[int] = [BlockIds.MARS_DUST, BlockIds.MARS_REGOLITH, BlockIds.BASALT, BlockIds.DEEP_BASALT,
	BlockIds.MARS_SEDIMENT, BlockIds.POLAR_ICE, BlockIds.DRY_ICE]


func test_every_mars_block_is_on_page_18() -> void:
	assert_eq(MarsBlocks.PAGE, 18)
	for id: int in MarsBlocks.TILES:
		assert_between(id, 336, 351, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), MarsBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(MarsBlocks.TILES.size(), 14)
	assert_gte(BlockIds.COUNT, 352, "past Mars's page (the Lab's bench is 352, Europa's page 20 goes on to 383)")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, DesertBlocks.PAGE, DragonBlocks.PAGE]:
		assert_ne(other, MarsBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in MarsBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = MarsBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(MarsBlocks.PAGE, kind), BlockIds.display_name(id))


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in MarsBlocks.TILES:
		assert_eq(MarsBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(MarsBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(MarsBlocks.FILES, ["res://data/blocks/pages/mars.png", "res://data/blocks/pages/mars_albedo.png",
		"res://data/blocks/pages/mars_normal.png"])
	var pixel := (load(MarsBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(MarsBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(MarsBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(MarsBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in MarsBlocks.TILES:
		for i in 3:
			var t: Vector2i = MarsBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1, "%s tile %s is painted" % [BlockIds.display_name(id), t])


func test_mars_dust_is_red_and_the_ice_is_white() -> void:
	var pixel := (load(MarsBlocks.FILES[0]) as Texture2D).get_image()
	var dust := _mean(pixel, MarsBlocks.TILES[BlockIds.MARS_DUST][0])
	assert_gt(dust.r, dust.g + 0.15, "rusty red dust (%s)" % dust)
	assert_gt(dust.r, dust.b + 0.25)
	var basalt := _mean(pixel, MarsBlocks.TILES[BlockIds.BASALT][1])
	assert_lt(basalt.get_luminance(), 0.35, "dark basalt (%s)" % basalt)
	var ice := _mean(pixel, MarsBlocks.TILES[BlockIds.POLAR_ICE][0])
	assert_gt(ice.get_luminance(), 0.85, "white polar ice (%s)" % ice)
	var dry := _mean(pixel, MarsBlocks.TILES[BlockIds.DRY_ICE][0])
	assert_gt(dry.b, dry.r, "dry ice is frosty blue-white (%s)" % dry)


func _mean(img: Image, t: Vector2i) -> Color:
	var r := 0.0
	var g := 0.0
	var b := 0.0
	for y in 16:
		for x in 16:
			var c := img.get_pixel(t.x * 16 + x, t.y * 16 + y)
			r += c.r
			g += c.g
			b += c.b
	return Color(r / 256.0, g / 256.0, b / 256.0)


func test_names_and_validity() -> void:
	for id: int in MarsBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
	assert_eq(BlockIds.display_name(BlockIds.MARS_DUST), "Mars Dust")
	assert_eq(BlockIds.display_name(BlockIds.BASALT), "Basalt")
	assert_eq(BlockIds.display_name(BlockIds.POLAR_ICE), "Polar Ice")
	assert_eq(BlockIds.display_name(BlockIds.DRY_ICE), "Dry Ice")
	assert_eq(BlockIds.display_name(BlockIds.GYPSUM), "Gypsum Crystal")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_BASALT), "Basalt", "a hidden door is named like its wall")


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_BASALT), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_BASALT, GatherRules.NONE), BlockIds.BASALT)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_BASALT, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_BASALT)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
	for id: int in BlockIds.SPACE_GROUND:
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	assert_has(BotRules.NATURAL, BlockIds.GYPSUM)
	for id in [BlockIds.ROVER_PANEL, BlockIds.SOLAR_PANEL, BlockIds.LANDER_FOIL]:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))
