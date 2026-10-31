extends GutTest
## Cosmos: Mercury (world 23, spec §21b.2): its blocks, ids 528-541 on block atlas page 30 (542-543 free; past the items'
## ids 400-511, after Titan's page 29), drawn in both styles (data/blocks/pages/mercury.png and its realistic twin):
## Mercury's grey dust over grey rock, patches of darker dust, the bright dust of a young crater's rays, the ice hiding in
## the shadowed craters near its poles and glowing ice crystals, the Sunshade Lander's white sunshade, its silvery heat
## blanket, its mirror panels and lamps, the explorers' thermometer (a tube and a glowing red bulb), the explorers'
## bricks and a fake rock door (the hidden room). The landing pad and star gold are the Moon's (every space world's).

const GLOWS: Array[int] = [BlockIds.ICE_CRYSTAL, BlockIds.EXPLORER_LAMP, BlockIds.THERMO_BULB]
const GROUND: Array[int] = [BlockIds.MERCURY_DUST, BlockIds.MERCURY_ROCK, BlockIds.DARK_DUST, BlockIds.RAY_DUST,
	BlockIds.SHADOW_ICE]


func test_every_mercury_block_is_on_page_30() -> void:
	assert_eq(MercuryBlocks.PAGE, 30)
	for id: int in MercuryBlocks.TILES:
		assert_between(id, 528, 543, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), MercuryBlocks.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id), "%d is not the items'" % id)
	assert_eq(MercuryBlocks.TILES.size(), 14)
	assert_gte(BlockIds.COUNT, 544, "past Mercury's page (page 31 is kept for the colony domes, 32 is the rockets')")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 544, "the next block pages start past Mercury's")
	assert_eq(BlockLibrary.page_of(544), 31, "Mercury's page is followed by page 31")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, EuropaBlocks.PAGE,
			IoBlocks.PAGE, TitanBlocks.PAGE, LabPage.PAGE, DesertBlocks.PAGE, DragonBlocks.PAGE]:
		assert_ne(other, MercuryBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in MercuryBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = MercuryBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(MercuryBlocks.PAGE, kind),
			BlockIds.display_name(id))
	for id in range(BlockIds.RESERVED_END, BlockIds.COUNT):
		var owned := false
		for page: int in BlockLibrary._pages:
			owned = owned or (BlockLibrary._pages[page].tiles as Dictionary).has(id)
		if not owned:   # page 31 (kept for the colony domes) and the free ids of every page
			assert_true(lib.models[id] is VoxelBlockyModelEmpty, "unowned id %d stays empty" % id)


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in MercuryBlocks.TILES:
		assert_eq(MercuryBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(MercuryBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(MercuryBlocks.FILES, ["res://data/blocks/pages/mercury.png", "res://data/blocks/pages/mercury_albedo.png",
		"res://data/blocks/pages/mercury_normal.png"])
	var pixel := (load(MercuryBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(MercuryBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(MercuryBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(MercuryBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in MercuryBlocks.TILES:
		for i in 3:
			var t: Vector2i = MercuryBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1,
				"%s tile %s is painted" % [BlockIds.display_name(id), t])


## Mercury's real colours (spec §21b.2: "grey craters"): grey dust and rock (a warmer, darker grey than the Moon's
## silver), darker patches, bright rays, pale ice; friendly, never gloomy (§3c).
func test_grey_dust_dark_patches_bright_rays_and_pale_ice() -> void:
	var pixel := (load(MercuryBlocks.FILES[0]) as Texture2D).get_image()
	var dust := _mean(pixel, MercuryBlocks.TILES[BlockIds.MERCURY_DUST][0])
	assert_lt(maxf(dust.r, maxf(dust.g, dust.b)) - minf(dust.r, minf(dust.g, dust.b)), 0.08, "grey dust (%s)" % dust)
	assert_between(dust.get_luminance(), 0.45, 0.72, "a bright, friendly grey (%s)" % dust)
	var moon_img := (load(MoonBlocks.FILES[0]) as Texture2D).get_image()
	var moon := _mean(moon_img, MoonBlocks.TILES[BlockIds.MOON_DUST][0])
	assert_lt(dust.get_luminance(), moon.get_luminance() - 0.08, "darker than the Moon's silver dust")
	assert_gte(dust.r, dust.b, "a warm grey, not the Moon's blue-silver")
	var dark := _mean(pixel, MercuryBlocks.TILES[BlockIds.DARK_DUST][0])
	assert_lt(dark.get_luminance(), dust.get_luminance() - 0.12, "darker patches (%s)" % dark)
	assert_gte(dark.b, dark.r, "a dark blue-grey (%s)" % dark)
	var ray := _mean(pixel, MercuryBlocks.TILES[BlockIds.RAY_DUST][0])
	assert_gt(ray.get_luminance(), dust.get_luminance() + 0.12, "a young crater's bright rays (%s)" % ray)
	var rock := _mean(pixel, MercuryBlocks.TILES[BlockIds.MERCURY_ROCK][1])
	assert_lt(rock.get_luminance(), dust.get_luminance(), "rock a little darker than the dust (%s)" % rock)
	var ice := _mean(pixel, MercuryBlocks.TILES[BlockIds.SHADOW_ICE][0])
	assert_gt(ice.get_luminance(), 0.8, "pale ice (%s)" % ice)
	assert_gt(ice.b, ice.r, "blue-white ice (%s)" % ice)
	var crystal := _mean(pixel, MercuryBlocks.TILES[BlockIds.ICE_CRYSTAL][1])
	assert_gt(crystal.get_luminance(), 0.7, "bright ice crystals (%s)" % crystal)


func test_the_sunshade_the_thermometer_and_its_red_bulb() -> void:
	var pixel := (load(MercuryBlocks.FILES[0]) as Texture2D).get_image()
	var shade := _mean(pixel, MercuryBlocks.TILES[BlockIds.SUNSHADE][1])
	assert_gt(shade.get_luminance(), 0.85, "a white sunshade (%s)" % shade)
	var bulb := _mean(pixel, MercuryBlocks.TILES[BlockIds.THERMO_BULB][1])
	assert_gt(bulb.r, bulb.g + 0.35, "a red bulb (%s)" % bulb)
	var tube := MercuryBlocks.TILES[BlockIds.THERMOMETER][1] as Vector2i
	var red := 0
	var marks := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(tube.x * 16 + x, tube.y * 16 + y)
			if c.r > 0.75 and c.g < 0.4 and c.b < 0.4:
				red += 1
			elif c.get_luminance() < 0.3:
				marks += 1
	assert_gt(red, 20, "the red line up the tube (%d)" % red)
	assert_gt(marks, 6, "and the marks beside it (%d)" % marks)
	var lamp := _mean(pixel, MercuryBlocks.TILES[BlockIds.EXPLORER_LAMP][1])
	assert_gt(lamp.get_luminance(), 0.6, "a bright lamp (%s)" % lamp)


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
	for id: int in MercuryBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_block_id(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id) or ChatCommands.NEVER_GIVEN.has(id), "/give knows %s" % id)
	assert_eq(BlockIds.display_name(BlockIds.MERCURY_DUST), "Mercury Dust")
	assert_eq(BlockIds.display_name(BlockIds.MERCURY_ROCK), "Mercury Rock")
	assert_eq(BlockIds.display_name(BlockIds.SHADOW_ICE), "Shadow Ice")
	assert_eq(BlockIds.display_name(BlockIds.SUNSHADE), "Sunshade")
	assert_eq(BlockIds.display_name(BlockIds.THERMOMETER), "Thermometer")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_MERCURY_ROCK), "Mercury Rock", "a hidden door is named like its wall")


## Gifts and showcases carry Mercury's blocks (blocks up to 1023, the server's BuildRules the same since module 0.2.15).
func test_they_travel_in_gifts() -> void:
	for id: int in MercuryBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.SUNSHADE, Vector3i(1, 0, 0): BlockIds.THERMO_BULB})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i.ZERO), BlockIds.SUNSHADE, "a Mercury block comes back as itself")
	assert_eq(back.get(Vector3i(1, 0, 0)), BlockIds.THERMO_BULB)


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_MERCURY_ROCK), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_MERCURY_ROCK, GatherRules.NONE), BlockIds.MERCURY_ROCK)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_MERCURY_ROCK, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_MERCURY_ROCK)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
	for id: int in BlockIds.SPACE_GROUND:
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	assert_has(BotRules.NATURAL, BlockIds.ICE_CRYSTAL, "the planet's own")
	for id in [BlockIds.SUNSHADE, BlockIds.HEAT_BLANKET, BlockIds.MIRROR_PANEL, BlockIds.EXPLORER_LAMP,
			BlockIds.THERMOMETER, BlockIds.THERMO_BULB, BlockIds.EXPLORER_BRICK]:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))
