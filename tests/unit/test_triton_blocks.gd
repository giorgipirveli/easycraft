extends GutTest
## Cosmos: Triton (world 27, spec §21b.2): its blocks, ids 720-733 on block atlas page 42 (734-735 free), drawn in both
## styles (data/blocks/pages/triton.png and its realistic twin), from what Voyager 2 saw in 1989: the bright band's fresh
## nitrogen frost (bluish white), the south polar cap's pink nitrogen ice (sunlight turns its methane pink) with its
## darker mottled patches, the geysers' dark dust (the streaks the thin wind drew across the cap), a nitrogen geyser's vent
## (a pad: it puffs a child up), the cantaloupe terrain's dimpled ice and its ridges, the frozen ice lava of the walled
## plains, glowing nitrogen crystals (the secrets), the Hopper Lander's white nitrogen tank, a Neptune globe (deep blue
## with its dark spot), blue beacons, the explorers' pale pink cap bricks and a fake pink-ice door (the hidden room).
## Under the frost Triton shares Pluto's nitrogen ice and water ice (page 41: cousins from the Kuiper Belt); the landing
## pad and star gold are the Moon's; the lander's foil, dish, power pack, truss and lamps are other worlds' blocks.

const GLOWS: Array[int] = [BlockIds.NITROGEN_GEYSER, BlockIds.NITROGEN_CRYSTAL, BlockIds.BLUE_BEACON]
## The world's ground: every step a child takes on Triton is on them (bots build there, a meteor may land there, the
## Magic Wand never wakes them).
const GROUND: Array[int] = [BlockIds.TRITON_FROST, BlockIds.PINK_ICE, BlockIds.MOTTLED_ICE, BlockIds.GEYSER_DUST,
	BlockIds.CANTALOUPE_ICE, BlockIds.RIDGE_ICE, BlockIds.ICE_LAVA]
const BUILT: Array[int] = [BlockIds.NITROGEN_TANK, BlockIds.NEPTUNE_GLOBE, BlockIds.BLUE_BEACON, BlockIds.CAP_BRICK]


func test_every_triton_block_is_on_page_42() -> void:
	assert_eq(TritonBlocks.PAGE, 42)
	for id: int in TritonBlocks.TILES:
		assert_between(id, 720, 735, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), TritonBlocks.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id), "%d is not the items'" % id)
	assert_eq(TritonBlocks.TILES.size(), 14, "ids 720-733 (734-735 free)")
	assert_gte(BlockIds.COUNT, 736, "past Triton's page")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 736, "the next block pages start past Triton's")
	assert_eq(BlockLibrary.page_of(736), 43, "Triton's page is followed by page 43")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, EuropaBlocks.PAGE,
			IoBlocks.PAGE, TitanBlocks.PAGE, MercuryBlocks.PAGE, VenusBlocks.PAGE, RingsBlocks.PAGE, PlutoBlocks.PAGE,
			ColonyBlocks.PAGE, RocketPage.PAGE, ProspectPage.PAGE, LabPage.PAGE, DesertBlocks.PAGE, DragonBlocks.PAGE]:
		assert_ne(other, TritonBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in TritonBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = TritonBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(TritonBlocks.PAGE, kind),
			BlockIds.display_name(id))
	for id in range(734, 736):
		assert_true(lib.models[id] is VoxelBlockyModelEmpty, "id %d is free: an empty model" % id)


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in TritonBlocks.TILES:
		assert_eq(TritonBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s holds a child up" % BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(TritonBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(TritonBlocks.FILES, ["res://data/blocks/pages/triton.png", "res://data/blocks/pages/triton_albedo.png",
		"res://data/blocks/pages/triton_normal.png"])
	var pixel := (load(TritonBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(TritonBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(TritonBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(TritonBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in TritonBlocks.TILES:
		for i in 3:
			var t: Vector2i = TritonBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1,
				"%s tile %s is painted" % [BlockIds.display_name(id), t])


## Triton's real colours (Voyager 2, 1989): the bright, bluish frost of its band, the south polar cap's pink ices, the
## dark streaks of geyser dust over them, the greyish-green cantaloupe terrain, the smooth pale ice lava; friendly, never
## gloomy (spec §3c).
func test_a_bright_frost_a_pink_cap_and_dark_streaks() -> void:
	var pixel := (load(TritonBlocks.FILES[0]) as Texture2D).get_image()
	var frost := _mean(pixel, TritonBlocks.TILES[BlockIds.TRITON_FROST][0])
	assert_gt(frost.get_luminance(), 0.8, "fresh nitrogen frost, very bright (%s)" % frost)
	assert_gte(frost.b, frost.r, "a little bluish (%s)" % frost)
	var pink := _mean(pixel, TritonBlocks.TILES[BlockIds.PINK_ICE][0])
	assert_gt(pink.r, pink.g + 0.06, "the cap's pink ice (%s)" % pink)
	assert_gt(pink.r, pink.b, "pink, not lilac (%s)" % pink)
	assert_gt(pink.get_luminance(), 0.6, "bright ice (%s)" % pink)
	var mottle := _mean(pixel, TritonBlocks.TILES[BlockIds.MOTTLED_ICE][0])
	assert_lt(mottle.get_luminance(), pink.get_luminance() - 0.04, "darker mottled patches (%s)" % mottle)
	var dust := _mean(pixel, TritonBlocks.TILES[BlockIds.GEYSER_DUST][0])
	assert_lt(dust.get_luminance(), pink.get_luminance() - 0.25, "the geysers' dark dust (%s)" % dust)
	var melon := _mean(pixel, TritonBlocks.TILES[BlockIds.CANTALOUPE_ICE][0])
	assert_gte(melon.g, melon.b, "greyish green, like a melon's rind (%s)" % melon)
	assert_between(melon.get_luminance(), 0.45, 0.85, "(%s)" % melon)
	var ridge := _mean(pixel, TritonBlocks.TILES[BlockIds.RIDGE_ICE][0])
	assert_gt(ridge.get_luminance(), melon.get_luminance(), "paler ridges between the dimples (%s)" % ridge)
	var lava := _mean(pixel, TritonBlocks.TILES[BlockIds.ICE_LAVA][0])
	assert_gte(lava.b, lava.r, "icy lava: pale blue-grey (%s)" % lava)
	assert_gt(lava.get_luminance(), 0.6, "(%s)" % lava)
	var crystal := _mean(pixel, TritonBlocks.TILES[BlockIds.NITROGEN_CRYSTAL][1])
	assert_gt(crystal.get_luminance(), 0.75, "a bright crystal (%s)" % crystal)


func test_the_geyser_vent_the_tank_the_neptune_globe_and_the_beacon() -> void:
	var pixel := (load(TritonBlocks.FILES[0]) as Texture2D).get_image()
	var vent := _mean(pixel, TritonBlocks.TILES[BlockIds.NITROGEN_GEYSER][0])
	assert_lt(vent.get_luminance(), 0.55, "a dark hole in the ice (%s)" % vent)
	var tank := _mean(pixel, TritonBlocks.TILES[BlockIds.NITROGEN_TANK][1])
	assert_gt(tank.get_luminance(), 0.65, "a white tank (%s)" % tank)
	var globe := TritonBlocks.TILES[BlockIds.NEPTUNE_GLOBE][1] as Vector2i
	var blue := 0
	var spot := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(globe.x * 16 + x, globe.y * 16 + y)
			if c.b > c.r + 0.3 and c.get_luminance() > 0.3:
				blue += 1
			elif c.b > c.r and c.get_luminance() < 0.3 and Vector2(x - 7.5, y - 7.5).length() < 7.0:
				spot += 1
	assert_gt(blue, 80, "Neptune's deep blue (%d)" % blue)
	assert_gt(spot, 4, "and its dark spot (%d)" % spot)
	var beacon := _mean(pixel, TritonBlocks.TILES[BlockIds.BLUE_BEACON][1])
	assert_gt(beacon.b, beacon.r + 0.15, "a blue beacon (%s)" % beacon)
	assert_gt(beacon.get_luminance(), 0.5, "glowing (%s)" % beacon)
	var brick := _mean(pixel, TritonBlocks.TILES[BlockIds.CAP_BRICK][1])
	assert_gt(brick.get_luminance(), 0.6, "pale cap bricks (%s)" % brick)
	assert_gte(brick.r, brick.b, "a little pink (%s)" % brick)


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
	for id: int in TritonBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_block_id(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id) or ChatCommands.NEVER_GIVEN.has(id), "/give knows %s" % id)
	assert_eq(BlockIds.display_name(BlockIds.TRITON_FROST), "Triton Frost")
	assert_eq(BlockIds.display_name(BlockIds.PINK_ICE), "Pink Ice")
	assert_eq(BlockIds.display_name(BlockIds.GEYSER_DUST), "Geyser Dust")
	assert_eq(BlockIds.display_name(BlockIds.NITROGEN_GEYSER), "Nitrogen Geyser")
	assert_eq(BlockIds.display_name(BlockIds.CANTALOUPE_ICE), "Cantaloupe Ice")
	assert_eq(BlockIds.display_name(BlockIds.ICE_LAVA), "Ice Lava")
	assert_eq(BlockIds.display_name(BlockIds.NEPTUNE_GLOBE), "Neptune Globe")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_PINK_ICE), "Pink Ice", "a hidden door is named like its wall")


## Gifts and showcases carry Triton's blocks (blocks up to 1023, the server's BuildRules the same since module 0.2.15).
func test_they_travel_in_gifts() -> void:
	for id: int in TritonBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.PINK_ICE, Vector3i(1, 0, 0): BlockIds.NEPTUNE_GLOBE})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i.ZERO), BlockIds.PINK_ICE, "a Triton block comes back as itself")
	assert_eq(back.get(Vector3i(1, 0, 0)), BlockIds.NEPTUNE_GLOBE)


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_PINK_ICE), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_PINK_ICE, GatherRules.NONE), BlockIds.PINK_ICE)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_PINK_ICE, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_PINK_ICE)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	for id: int in [BlockIds.NITROGEN_CRYSTAL, BlockIds.NITROGEN_GEYSER]:
		assert_has(BotRules.NATURAL, id, "Triton's own")
	for id in BUILT:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))


## A nitrogen geyser is a pad (PadRules): a gentle puff throws a child up and the thin wind carries it north-east, the
## way the real plumes' dark dust drifted (tested with the pads in test_triton_geysers).
func test_the_geyser_vent_is_a_pad() -> void:
	assert_true(PadRules.is_pad(BlockIds.NITROGEN_GEYSER))
	assert_false(PadRules.is_pad(BlockIds.GEYSER_DUST), "the dust round it is plain ground")
