extends GutTest
## Cosmos: Pluto (world 26, spec §21b.2): its blocks, ids 704-716 on block atlas page 41 (717-719 free), drawn in both
## styles (data/blocks/pages/pluto.png and its realistic twin): the heart's pale nitrogen ice and the darker edges of its
## churning cells, Pluto's water ice (frozen as hard as rock: its bedrock and its mountains), the uplands' peach frost,
## the dark red-brown tholin dust and the red-stained ice under it, bright methane snow, glowing frost crystals (the
## secrets), the Balloon Lander's silvery drag balloon, a Charon globe (grey with its red cap), pink heart beacons, the
## explorers' frost bricks and a fake water-ice door (the hidden room). The landing pad and star gold are the Moon's
## (every space world's); the lander's gold foil, dish, power pack, truss and lamps and the lookout's telescope are
## other worlds' blocks.

const GLOWS: Array[int] = [BlockIds.FROST_CRYSTAL, BlockIds.HEART_BEACON]
## The world's ground: every step a child takes on Pluto is on them (bots build there, a meteor may land there, the
## Magic Wand never wakes them).
const GROUND: Array[int] = [BlockIds.NITROGEN_ICE, BlockIds.CELL_EDGE, BlockIds.WATER_ICE, BlockIds.PLUTO_FROST,
	BlockIds.THOLIN_DUST, BlockIds.RED_ICE, BlockIds.METHANE_SNOW]
const BUILT: Array[int] = [BlockIds.DRAG_BALLOON, BlockIds.CHARON_GLOBE, BlockIds.HEART_BEACON, BlockIds.FROST_BRICK]


func test_every_pluto_block_is_on_page_41() -> void:
	assert_eq(PlutoBlocks.PAGE, 41)
	for id: int in PlutoBlocks.TILES:
		assert_between(id, 704, 719, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), PlutoBlocks.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id), "%d is not the items'" % id)
	assert_eq(PlutoBlocks.TILES.size(), 13, "ids 704-716 (717-719 free)")
	assert_gte(BlockIds.COUNT, 720, "past Pluto's page")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 720, "the next block pages start past Pluto's (Triton took 42)")
	assert_eq(BlockLibrary.page_of(720), 42, "Pluto's page is followed by page 42")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, EuropaBlocks.PAGE,
			IoBlocks.PAGE, TitanBlocks.PAGE, MercuryBlocks.PAGE, VenusBlocks.PAGE, RingsBlocks.PAGE, ColonyBlocks.PAGE,
			RocketPage.PAGE, ProspectPage.PAGE, LabPage.PAGE, DesertBlocks.PAGE, DragonBlocks.PAGE]:
		assert_ne(other, PlutoBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in PlutoBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = PlutoBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(PlutoBlocks.PAGE, kind),
			BlockIds.display_name(id))
	for id in range(717, 720):
		assert_true(lib.models[id] is VoxelBlockyModelEmpty, "id %d is free: an empty model" % id)


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in PlutoBlocks.TILES:
		assert_eq(PlutoBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s holds a child up" % BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(PlutoBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(PlutoBlocks.FILES, ["res://data/blocks/pages/pluto.png", "res://data/blocks/pages/pluto_albedo.png",
		"res://data/blocks/pages/pluto_normal.png"])
	var pixel := (load(PlutoBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(PlutoBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(PlutoBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(PlutoBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in PlutoBlocks.TILES:
		for i in 3:
			var t: Vector2i = PlutoBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1,
				"%s tile %s is painted" % [BlockIds.display_name(id), t])


## Pluto's real colours (New Horizons, 2015): the heart's bright, creamy nitrogen ice, the cells' darker edges, the
## peach-tan frost of the uplands, the dark red-brown tholins, bright white methane snow, and water ice as pale blue-grey
## "rock"; friendly, never gloomy (spec §3c).
func test_a_pale_heart_red_brown_lands_and_bright_snow() -> void:
	var pixel := (load(PlutoBlocks.FILES[0]) as Texture2D).get_image()
	var ice := _mean(pixel, PlutoBlocks.TILES[BlockIds.NITROGEN_ICE][0])
	assert_gt(ice.get_luminance(), 0.78, "the heart's bright nitrogen ice (%s)" % ice)
	assert_gte(ice.r, ice.b, "creamy, a little warm (%s)" % ice)
	var edge := _mean(pixel, PlutoBlocks.TILES[BlockIds.CELL_EDGE][0])
	assert_lt(edge.get_luminance(), ice.get_luminance() - 0.12, "the cells' edges are darker (%s)" % edge)
	var frost := _mean(pixel, PlutoBlocks.TILES[BlockIds.PLUTO_FROST][0])
	assert_gt(frost.r, frost.b + 0.08, "peach-tan frost (%s)" % frost)
	assert_between(frost.get_luminance(), 0.5, 0.85, "a warm, bright ground (%s)" % frost)
	var tholin := _mean(pixel, PlutoBlocks.TILES[BlockIds.THOLIN_DUST][0])
	assert_gt(tholin.r, tholin.g + 0.1, "red-brown tholins (%s)" % tholin)
	assert_gt(tholin.g, tholin.b - 0.02, "brown, not purple (%s)" % tholin)
	assert_lt(tholin.get_luminance(), frost.get_luminance() - 0.2, "the dark lands are dark (%s)" % tholin)
	var red := _mean(pixel, PlutoBlocks.TILES[BlockIds.RED_ICE][1])
	assert_gt(red.r, red.b + 0.08, "ice stained red (%s)" % red)
	var snow := _mean(pixel, PlutoBlocks.TILES[BlockIds.METHANE_SNOW][0])
	assert_gt(snow.get_luminance(), 0.85, "bright methane snow (%s)" % snow)
	var water := _mean(pixel, PlutoBlocks.TILES[BlockIds.WATER_ICE][1])
	assert_gte(water.b, water.r, "water ice: blue-grey, not brown (%s)" % water)
	assert_between(water.get_luminance(), 0.45, 0.85, "pale ice as hard as rock (%s)" % water)
	var crystal := _mean(pixel, PlutoBlocks.TILES[BlockIds.FROST_CRYSTAL][1])
	assert_gt(crystal.get_luminance(), 0.7, "a bright crystal (%s)" % crystal)


func test_the_balloon_the_charon_globe_and_the_heart_beacon() -> void:
	var pixel := (load(PlutoBlocks.FILES[0]) as Texture2D).get_image()
	var balloon := _mean(pixel, PlutoBlocks.TILES[BlockIds.DRAG_BALLOON][0])
	assert_gt(balloon.get_luminance(), 0.65, "a shiny silvery film (%s)" % balloon)
	var globe := PlutoBlocks.TILES[BlockIds.CHARON_GLOBE][1] as Vector2i
	var grey := 0
	var cap := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(globe.x * 16 + x, globe.y * 16 + y)
			if absf(c.r - c.b) < 0.08 and c.get_luminance() > 0.35:
				grey += 1
			elif c.r > c.b + 0.15 and c.r < 0.75:
				cap += 1
	assert_gt(grey, 80, "Charon's grey face (%d)" % grey)
	assert_gt(cap, 20, "and its red cap (%d)" % cap)
	var beacon := _mean(pixel, PlutoBlocks.TILES[BlockIds.HEART_BEACON][1])
	assert_gt(beacon.r, beacon.g + 0.1, "a pink heart (%s)" % beacon)
	assert_gt(beacon.get_luminance(), 0.55, "glowing (%s)" % beacon)
	var brick := _mean(pixel, PlutoBlocks.TILES[BlockIds.FROST_BRICK][1])
	assert_gt(brick.get_luminance(), 0.6, "pale frost bricks (%s)" % brick)


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
	for id: int in PlutoBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_block_id(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id) or ChatCommands.NEVER_GIVEN.has(id), "/give knows %s" % id)
	assert_eq(BlockIds.display_name(BlockIds.NITROGEN_ICE), "Nitrogen Ice")
	assert_eq(BlockIds.display_name(BlockIds.WATER_ICE), "Water Ice")
	assert_eq(BlockIds.display_name(BlockIds.THOLIN_DUST), "Tholin Dust")
	assert_eq(BlockIds.display_name(BlockIds.METHANE_SNOW), "Methane Snow")
	assert_eq(BlockIds.display_name(BlockIds.CHARON_GLOBE), "Charon Globe")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_WATER_ICE), "Water Ice", "a hidden door is named like its wall")


## Gifts and showcases carry Pluto's blocks (blocks up to 1023, the server's BuildRules the same since module 0.2.15).
func test_they_travel_in_gifts() -> void:
	for id: int in PlutoBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.NITROGEN_ICE, Vector3i(1, 0, 0): BlockIds.CHARON_GLOBE})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i.ZERO), BlockIds.NITROGEN_ICE, "a Pluto block comes back as itself")
	assert_eq(back.get(Vector3i(1, 0, 0)), BlockIds.CHARON_GLOBE)


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_WATER_ICE), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_WATER_ICE, GatherRules.NONE), BlockIds.WATER_ICE)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_WATER_ICE, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_WATER_ICE)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	assert_has(BotRules.NATURAL, BlockIds.FROST_CRYSTAL, "Pluto's own")
	for id in BUILT:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))
