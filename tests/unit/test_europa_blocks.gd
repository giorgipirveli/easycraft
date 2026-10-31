extends GutTest
## Cosmos: Europa (world 20, spec §21b.2): its blocks, ids 368-380 on block atlas page 20 (381-383 free), drawn in both
## styles (data/blocks/pages/europa.png and its realistic twin): the smooth white Europa ice of its crust, the reddish
## ice of its long cracks (lineae) and the stained ice of their ridges, blue deep ice in layers (the cliffs and the ocean
## well's walls show them), the rocky seafloor under the ice, glowing blue ice (the well's rings), glowing sea salt
## crystals (Europa's ocean is salty), the geyser vent (a water plume throws you up), the Ice Lander's panel, melt probe
## and light, ice bricks (the explorers' ice station), and a fake deep-ice door (the hidden room). The landing pad and
## star gold are the Moon's (every space world's). A geyser vent is a pad: it throws a child up like a jump pad.

const GLOWS: Array[int] = [BlockIds.GLOW_ICE, BlockIds.SALT, BlockIds.GEYSER_VENT, BlockIds.PROBE_LIGHT]
const GROUND: Array[int] = [BlockIds.EUROPA_ICE, BlockIds.LINEA_ICE, BlockIds.BAND_ICE, BlockIds.DEEP_ICE,
	BlockIds.EUROPA_ROCK]


func test_every_europa_block_is_on_page_20() -> void:
	assert_eq(EuropaBlocks.PAGE, 20)
	for id: int in EuropaBlocks.TILES:
		assert_between(id, 368, 383, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), EuropaBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(EuropaBlocks.TILES.size(), 13)
	assert_gte(BlockIds.COUNT, 384, "the first id past Europa's page")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, DesertBlocks.PAGE,
			DragonBlocks.PAGE]:
		assert_ne(other, EuropaBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in EuropaBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = EuropaBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(EuropaBlocks.PAGE, kind), BlockIds.display_name(id))


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in EuropaBlocks.TILES:
		assert_eq(EuropaBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(EuropaBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(EuropaBlocks.FILES, ["res://data/blocks/pages/europa.png", "res://data/blocks/pages/europa_albedo.png",
		"res://data/blocks/pages/europa_normal.png"])
	var pixel := (load(EuropaBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(EuropaBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(EuropaBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(EuropaBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in EuropaBlocks.TILES:
		for i in 3:
			var t: Vector2i = EuropaBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1, "%s tile %s is painted" % [BlockIds.display_name(id), t])


func test_the_ice_is_white_its_cracks_reddish_and_the_deep_ice_blue() -> void:
	var pixel := (load(EuropaBlocks.FILES[0]) as Texture2D).get_image()
	var ice := _mean(pixel, EuropaBlocks.TILES[BlockIds.EUROPA_ICE][0])
	assert_gt(ice.get_luminance(), 0.82, "a smooth white crust (%s)" % ice)
	var linea := _mean(pixel, EuropaBlocks.TILES[BlockIds.LINEA_ICE][0])
	assert_gt(linea.r, linea.b + 0.15, "the cracks are reddish-brown (%s)" % linea)
	assert_lt(linea.get_luminance(), ice.get_luminance() - 0.2, "darker than the white ice")
	var band := _mean(pixel, EuropaBlocks.TILES[BlockIds.BAND_ICE][0])
	assert_gt(band.r, band.b, "the ridges are stained (%s)" % band)
	assert_between(band.get_luminance(), linea.get_luminance(), ice.get_luminance(), "between the crack and the ice")
	var deep := _mean(pixel, EuropaBlocks.TILES[BlockIds.DEEP_ICE][1])
	assert_gt(deep.b, deep.r + 0.08, "deep ice is blue (%s)" % deep)
	var glow := _mean(pixel, EuropaBlocks.TILES[BlockIds.GLOW_ICE][1])
	assert_gt(glow.b, glow.r, "glowing blue ice (%s)" % glow)
	assert_gt(glow.get_luminance(), 0.6, "bright, never dark and scary")


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
	for id: int in EuropaBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
	assert_eq(BlockIds.display_name(BlockIds.EUROPA_ICE), "Europa Ice")
	assert_eq(BlockIds.display_name(BlockIds.LINEA_ICE), "Reddish Ice")
	assert_eq(BlockIds.display_name(BlockIds.SALT), "Sea Salt")
	assert_eq(BlockIds.display_name(BlockIds.GEYSER_VENT), "Geyser Vent")
	assert_eq(BlockIds.display_name(BlockIds.EUROPA_ROCK), "Seafloor Rock")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_DEEP_ICE), "Deep Ice", "a hidden door is named like its wall")


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_DEEP_ICE), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_DEEP_ICE, GatherRules.NONE), BlockIds.DEEP_ICE)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_DEEP_ICE, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_DEEP_ICE)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
	for id: int in BlockIds.SPACE_GROUND:
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	for id in [BlockIds.SALT, BlockIds.GLOW_ICE, BlockIds.GEYSER_VENT]:
		assert_has(BotRules.NATURAL, id, "%s is the moon's own" % BlockIds.display_name(id))
	for id in [BlockIds.PROBE_PANEL, BlockIds.MELT_PROBE, BlockIds.ICE_BRICK]:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))


# --- The geyser vent: a water plume throws a child up ---

func test_a_geyser_vent_is_a_pad_that_throws_you_up() -> void:
	assert_true(PadRules.is_pad(BlockIds.GEYSER_VENT))
	var pads := PadRules.new()
	var fired := pads.touch(BlockIds.GEYSER_VENT, Vector3(2, 0, 0), Vector3.FORWARD)
	assert_eq(fired, BlockIds.GEYSER_VENT)
	var v := pads.apply(Vector3(2, 0, 0), fired)
	assert_eq(v.y, PadRules.GEYSER_SPEED, "up with the plume")
	assert_eq(v.x, 2.0, "keeping the run")
	assert_eq(PadRules.GEYSER_SPEED, PadRules.LAUNCH_SPEED, "as high as a jump pad (about 41 blocks on Europa)")
	assert_eq(pads.touch(BlockIds.GEYSER_VENT, Vector3.ZERO, Vector3.FORWARD), 0, "then it cools down like every pad")
	var under := PadRules.pad_under(Vector3(0.5, 5.0, 0.5), 0.3, func(c: Vector3i) -> int:
		return BlockIds.GEYSER_VENT if c == Vector3i(0, 4, 0) else BlockIds.AIR)
	assert_eq(under, BlockIds.GEYSER_VENT, "standing on it")
