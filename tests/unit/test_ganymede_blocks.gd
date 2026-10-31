extends GutTest
## Cosmos: Ganymede (world 28, spec §21b.2): its blocks, ids 736-747 on block atlas page 43 (748-751 free), drawn in both
## styles (data/blocks/pages/ganymede.png and its realistic twin), from what spacecraft saw (1979-2021): the bright grooved
## terrain's pale ice and its grooves' blue-grey floors, the old dark terrain's dark ice over its old, dusty ice, the
## brilliant fresh ice of a young crater's rays, the frost at its poles (white with a violet tint), glowing aurora crystals
## (the secrets, the frost's lights), a Jupiter globe (its bands and its Great Red Spot), an aurora lamp, a magnetometer
## (the Aurora Watch's and the lander's sensor: Ganymede is the only moon with its own magnetic field), the explorers'
## pale groove bricks and a fake grooved-ice door (the hidden room). Its crust under the ground is Pluto's water ice (as
## hard as rock in the cold); the landing pad and star gold are the Moon's; the lander's foil, dish, truss, lamps and solar
## panels and the drill's deep blue ice are other worlds' blocks.

const GLOWS: Array[int] = [BlockIds.AURORA_CRYSTAL, BlockIds.AURORA_LAMP]
## The world's ground: every step a child takes on Ganymede is on them (bots build there, a meteor may land there, the
## Magic Wand never wakes them).
const GROUND: Array[int] = [BlockIds.GROOVED_ICE, BlockIds.TROUGH_ICE, BlockIds.DARK_ICE, BlockIds.OLD_ICE,
	BlockIds.RAY_ICE, BlockIds.POLAR_FROST]
const BUILT: Array[int] = [BlockIds.JUPITER_GLOBE, BlockIds.AURORA_LAMP, BlockIds.MAGNETOMETER, BlockIds.GROOVE_BRICK]


func test_every_ganymede_block_is_on_page_43() -> void:
	assert_eq(GanymedeBlocks.PAGE, 43)
	for id: int in GanymedeBlocks.TILES:
		assert_between(id, 736, 751, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), GanymedeBlocks.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id), "%d is not the items'" % id)
	assert_eq(GanymedeBlocks.TILES.size(), 12, "ids 736-747 (748-751 free)")
	assert_gte(BlockIds.COUNT, 752, "past Ganymede's page")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 752, "the next block pages start past Ganymede's")
	assert_eq(BlockLibrary.page_of(752), 44, "Ganymede's page is followed by page 44")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, EuropaBlocks.PAGE,
			IoBlocks.PAGE, TitanBlocks.PAGE, MercuryBlocks.PAGE, VenusBlocks.PAGE, RingsBlocks.PAGE, PlutoBlocks.PAGE,
			TritonBlocks.PAGE, ColonyBlocks.PAGE, RocketPage.PAGE, ProspectPage.PAGE, LabPage.PAGE, DesertBlocks.PAGE,
			DragonBlocks.PAGE]:
		assert_ne(other, GanymedeBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in GanymedeBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = GanymedeBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(GanymedeBlocks.PAGE, kind),
			BlockIds.display_name(id))
	for id in range(748, 752):
		assert_true(lib.models[id] is VoxelBlockyModelEmpty, "id %d is free: an empty model" % id)


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in GanymedeBlocks.TILES:
		assert_eq(GanymedeBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s holds a child up" % BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(GanymedeBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(GanymedeBlocks.FILES, ["res://data/blocks/pages/ganymede.png",
		"res://data/blocks/pages/ganymede_albedo.png", "res://data/blocks/pages/ganymede_normal.png"])
	var pixel := (load(GanymedeBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(GanymedeBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(GanymedeBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(GanymedeBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in GanymedeBlocks.TILES:
		for i in 3:
			var t: Vector2i = GanymedeBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1,
				"%s tile %s is painted" % [BlockIds.display_name(id), t])


## Ganymede's real colours (spacecraft pictures, 1979-2021): the pale, slightly bluish grooved terrain with darker
## blue-grey groove floors, the old terrain's dark brownish-grey ice, a young crater's brilliant fresh ice, the poles'
## white frost with a violet tint; friendly, never gloomy (spec §3c).
func test_bright_grooves_dark_old_ground_fresh_rays_and_violet_frost() -> void:
	var pixel := (load(GanymedeBlocks.FILES[0]) as Texture2D).get_image()
	var grooved := _mean(pixel, GanymedeBlocks.TILES[BlockIds.GROOVED_ICE][0])
	assert_gt(grooved.get_luminance(), 0.7, "the bright terrain's pale ice (%s)" % grooved)
	assert_gte(grooved.b, grooved.r - 0.02, "cool, a little bluish (%s)" % grooved)
	var trough := _mean(pixel, GanymedeBlocks.TILES[BlockIds.TROUGH_ICE][0])
	assert_lt(trough.get_luminance(), grooved.get_luminance() - 0.06, "the grooves' floors are darker (%s)" % trough)
	assert_gte(trough.b, trough.r, "blue-grey (%s)" % trough)
	var dark := _mean(pixel, GanymedeBlocks.TILES[BlockIds.DARK_ICE][0])
	assert_lt(dark.get_luminance(), grooved.get_luminance() - 0.3, "the old dark terrain (%s)" % dark)
	assert_gt(dark.get_luminance(), 0.25, "dark, never gloomy (%s)" % dark)
	assert_gte(dark.r, dark.b, "brownish grey: ice mixed with dark dust (%s)" % dark)
	var old := _mean(pixel, GanymedeBlocks.TILES[BlockIds.OLD_ICE][0])
	assert_between(old.get_luminance(), dark.get_luminance(), grooved.get_luminance(), "old, dusty ice (%s)" % old)
	var ray := _mean(pixel, GanymedeBlocks.TILES[BlockIds.RAY_ICE][0])
	assert_gt(ray.get_luminance(), grooved.get_luminance(), "a young crater's fresh ice is the brightest (%s)" % ray)
	var frost := _mean(pixel, GanymedeBlocks.TILES[BlockIds.POLAR_FROST][0])
	assert_gt(frost.get_luminance(), 0.8, "the poles' white frost (%s)" % frost)
	assert_gt(frost.b, frost.g, "a violet tint (%s)" % frost)
	var crystal := _mean(pixel, GanymedeBlocks.TILES[BlockIds.AURORA_CRYSTAL][1])
	assert_gt(crystal.get_luminance(), 0.6, "a bright crystal (%s)" % crystal)


func test_the_jupiter_globe_the_aurora_lamp_and_the_magnetometer() -> void:
	var pixel := (load(GanymedeBlocks.FILES[0]) as Texture2D).get_image()
	var globe := GanymedeBlocks.TILES[BlockIds.JUPITER_GLOBE][1] as Vector2i
	var cream := 0
	var belts := 0
	var spot := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(globe.x * 16 + x, globe.y * 16 + y)
			if Vector2(x - 7.5, y - 7.5).length() > 7.0:
				continue
			if c.r > 0.8 and c.g > 0.7:
				cream += 1
			elif c.r > c.b + 0.15 and c.get_luminance() < 0.6 and c.g > 0.35:
				belts += 1
			if c.r > c.g + 0.25 and c.r > 0.6:
				spot += 1
	assert_gt(cream, 30, "Jupiter's pale zones (%d)" % cream)
	assert_gt(belts, 20, "its brown belts (%d)" % belts)
	assert_gt(spot, 3, "and its Great Red Spot (%d)" % spot)
	var lamp := _mean(pixel, GanymedeBlocks.TILES[BlockIds.AURORA_LAMP][1])
	assert_gt(lamp.g, lamp.r + 0.1, "an aurora's green glow (%s)" % lamp)
	assert_gt(lamp.get_luminance(), 0.5, "glowing (%s)" % lamp)
	var sensor := _mean(pixel, GanymedeBlocks.TILES[BlockIds.MAGNETOMETER][1])
	assert_gt(sensor.get_luminance(), 0.5, "a white sensor box with its copper coil (%s)" % sensor)
	var brick := _mean(pixel, GanymedeBlocks.TILES[BlockIds.GROOVE_BRICK][1])
	assert_gt(brick.get_luminance(), 0.6, "pale groove bricks (%s)" % brick)


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
	for id: int in GanymedeBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_block_id(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id) or ChatCommands.NEVER_GIVEN.has(id), "/give knows %s" % id)
	assert_eq(BlockIds.display_name(BlockIds.GROOVED_ICE), "Grooved Ice")
	assert_eq(BlockIds.display_name(BlockIds.TROUGH_ICE), "Trough Ice")
	assert_eq(BlockIds.display_name(BlockIds.DARK_ICE), "Dark Ice")
	assert_eq(BlockIds.display_name(BlockIds.OLD_ICE), "Old Ice")
	assert_eq(BlockIds.display_name(BlockIds.RAY_ICE), "Ray Ice")
	assert_eq(BlockIds.display_name(BlockIds.POLAR_FROST), "Polar Frost")
	assert_eq(BlockIds.display_name(BlockIds.AURORA_CRYSTAL), "Aurora Crystal")
	assert_eq(BlockIds.display_name(BlockIds.JUPITER_GLOBE), "Jupiter Globe")
	assert_eq(BlockIds.display_name(BlockIds.MAGNETOMETER), "Magnetometer")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_GROOVED_ICE), "Grooved Ice", "a hidden door is named like its wall")


## Gifts and showcases carry Ganymede's blocks (blocks up to 1023, the server's BuildRules the same since module 0.2.15).
func test_they_travel_in_gifts() -> void:
	for id: int in GanymedeBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.GROOVED_ICE, Vector3i(1, 0, 0): BlockIds.JUPITER_GLOBE})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i.ZERO), BlockIds.GROOVED_ICE, "a Ganymede block comes back as itself")
	assert_eq(back.get(Vector3i(1, 0, 0)), BlockIds.JUPITER_GLOBE)


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_GROOVED_ICE), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_GROOVED_ICE, GatherRules.NONE), BlockIds.GROOVED_ICE)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_GROOVED_ICE, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_GROOVED_ICE)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	assert_has(BotRules.NATURAL, BlockIds.AURORA_CRYSTAL, "Ganymede's own")
	assert_has(SurpriseRules.METEOR_REPLACES, BlockIds.AURORA_CRYSTAL)
	for id in BUILT:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))
