extends GutTest
## Cosmos: Saturn's rings (world 25, spec §21b.2): its blocks, ids 688-703 on block atlas page 40 (page 39, ids 672-687,
## is the riches of the Moon and Mars), drawn in both styles (data/blocks/pages/rings.png and its realistic twin): the
## rings' chunks of clean water ice with frosty tops, the darker dusty ice of the C ring and the Cassini Division, rock
## bits, Pan's pale moonlet ice and the dust piled on its ridge, glowing ring crystals (the secrets), the Ring Station's
## white panels, round windows and warm lamps, a radio dish, the Ring Explorer's glowing power pack and dark truss, the
## teal ring beacons at the sights, Saturn's banded clouds (a block for building a Saturn), and a fake ice door (the
## hidden room). The landing pad and star gold are the Moon's (every space world's).

const GLOWS: Array[int] = [BlockIds.RING_CRYSTAL, BlockIds.STATION_LAMP, BlockIds.POWER_PACK, BlockIds.RING_BEACON]
## The world's ground: the chunks' ice, frost, dusty ice and rock, and Pan's ice and ridge dust (every step a child takes
## in the rings is on them: bots build there, a meteor may land there, the Magic Wand never wakes them).
const GROUND: Array[int] = [BlockIds.RING_ICE, BlockIds.RING_FROST, BlockIds.DUSTY_ICE, BlockIds.RING_ROCK,
	BlockIds.MOONLET_ICE, BlockIds.RIDGE_DUST]
const BUILT: Array[int] = [BlockIds.STATION_PANEL, BlockIds.STATION_WINDOW, BlockIds.STATION_LAMP, BlockIds.RADIO_DISH,
	BlockIds.POWER_PACK, BlockIds.TRUSS, BlockIds.RING_BEACON, BlockIds.SATURN_BAND]


func test_every_rings_block_is_on_page_40() -> void:
	assert_eq(RingsBlocks.PAGE, 40)
	for id: int in RingsBlocks.TILES:
		assert_between(id, 688, 703, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), RingsBlocks.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id), "%d is not the items'" % id)
	assert_eq(RingsBlocks.TILES.size(), 16, "the whole page: ids 688-703")
	assert_gte(BlockIds.COUNT, 704, "past the rings' page")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 704, "the next block pages start past the rings'")
	assert_eq(BlockLibrary.page_of(704), 41, "the rings' page is followed by page 41")
	assert_eq(BlockLibrary.page_of(688), 40)
	for id in range(672, 688):
		assert_false(RingsBlocks.TILES.has(id), "page 39 (%d) is the riches of the Moon and Mars" % id)
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, EuropaBlocks.PAGE,
			IoBlocks.PAGE, TitanBlocks.PAGE, MercuryBlocks.PAGE, VenusBlocks.PAGE, ColonyBlocks.PAGE, RocketPage.PAGE,
			ProspectPage.PAGE, LabPage.PAGE, DesertBlocks.PAGE, DragonBlocks.PAGE]:
		assert_ne(other, RingsBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in RingsBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = RingsBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(RingsBlocks.PAGE, kind),
			BlockIds.display_name(id))


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in RingsBlocks.TILES:
		assert_eq(RingsBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s holds a child up" % BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(RingsBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(RingsBlocks.FILES, ["res://data/blocks/pages/rings.png", "res://data/blocks/pages/rings_albedo.png",
		"res://data/blocks/pages/rings_normal.png"])
	var pixel := (load(RingsBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(RingsBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(RingsBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(RingsBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in RingsBlocks.TILES:
		for i in 3:
			var t: Vector2i = RingsBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1,
				"%s tile %s is painted" % [BlockIds.display_name(id), t])


## The rings' real colours (NASA: "chunks of ice and rock"; the B and A rings are bright, albedo 0.4-0.6, the C ring and
## the Cassini Division darker, 0.12-0.4: NSSDC's rings fact sheet): bright white ice with a cool tint, frost brighter
## still, the dusty ice clearly darker and a little tan, rock darker again.
func test_bright_ice_darker_dusty_ice_and_rock() -> void:
	var pixel := (load(RingsBlocks.FILES[0]) as Texture2D).get_image()
	var ice := _mean(pixel, RingsBlocks.TILES[BlockIds.RING_ICE][1])
	assert_gt(ice.get_luminance(), 0.72, "bright water ice (%s)" % ice)
	assert_gte(ice.b, ice.r - 0.02, "white-blue ice, not yellow (%s)" % ice)
	var frost := _mean(pixel, RingsBlocks.TILES[BlockIds.RING_FROST][0])
	assert_gt(frost.get_luminance(), ice.get_luminance() - 0.02, "a frosty top as bright as the ice (%s)" % frost)
	var dusty := _mean(pixel, RingsBlocks.TILES[BlockIds.DUSTY_ICE][0])
	assert_lt(dusty.get_luminance(), ice.get_luminance() - 0.15, "the C ring's ice is darker (%s)" % dusty)
	assert_gt(dusty.r, dusty.b, "dusty: a little tan (%s)" % dusty)
	var rock := _mean(pixel, RingsBlocks.TILES[BlockIds.RING_ROCK][1])
	assert_lt(rock.get_luminance(), dusty.get_luminance(), "rock is darker still (%s)" % rock)
	var moonlet := _mean(pixel, RingsBlocks.TILES[BlockIds.MOONLET_ICE][0])
	assert_gt(moonlet.get_luminance(), 0.6, "Pan: pale ice (%s)" % moonlet)
	var crystal := _mean(pixel, RingsBlocks.TILES[BlockIds.RING_CRYSTAL][1])
	assert_gt(crystal.get_luminance(), 0.7, "a bright crystal (%s)" % crystal)
	var band := _mean(pixel, RingsBlocks.TILES[BlockIds.SATURN_BAND][1])
	assert_gt(band.r, band.b + 0.15, "Saturn's pale gold bands (%s)" % band)


func test_the_station_is_white_with_windows_lamps_and_a_teal_beacon() -> void:
	var pixel := (load(RingsBlocks.FILES[0]) as Texture2D).get_image()
	var panel := _mean(pixel, RingsBlocks.TILES[BlockIds.STATION_PANEL][1])
	assert_gt(panel.get_luminance(), 0.75, "white panels (%s)" % panel)
	var lamp := _mean(pixel, RingsBlocks.TILES[BlockIds.STATION_LAMP][1])
	assert_gt(lamp.get_luminance(), 0.75, "a warm bright lamp (%s)" % lamp)
	var beacon := _mean(pixel, RingsBlocks.TILES[BlockIds.RING_BEACON][1])
	assert_gt(beacon.g, beacon.r + 0.15, "the brand's teal (%s)" % beacon)
	var power := _mean(pixel, RingsBlocks.TILES[BlockIds.POWER_PACK][1])
	assert_gt(power.r, power.b + 0.2, "a warm glowing power pack (%s)" % power)
	var truss := _mean(pixel, RingsBlocks.TILES[BlockIds.TRUSS][1])
	assert_lt(truss.get_luminance(), 0.5, "a dark metal truss (%s)" % truss)
	var window := RingsBlocks.TILES[BlockIds.STATION_WINDOW][1] as Vector2i
	var blue := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(window.x * 16 + x, window.y * 16 + y)
			if c.b > c.r + 0.15 and c.b > 0.5:
				blue += 1
	assert_gt(blue, 20, "a round window in the station's wall (%d)" % blue)


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
	for id: int in RingsBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_block_id(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id) or ChatCommands.NEVER_GIVEN.has(id), "/give knows %s" % id)
	assert_eq(BlockIds.display_name(BlockIds.RING_ICE), "Ring Ice")
	assert_eq(BlockIds.display_name(BlockIds.DUSTY_ICE), "Dusty Ice")
	assert_eq(BlockIds.display_name(BlockIds.MOONLET_ICE), "Moonlet Ice")
	assert_eq(BlockIds.display_name(BlockIds.SATURN_BAND), "Saturn Band")
	assert_eq(BlockIds.display_name(BlockIds.RADIO_DISH), "Radio Dish")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_RING_ICE), "Ring Ice", "a hidden door is named like its wall")


## Gifts and showcases carry the rings' blocks (blocks up to 1023, the server's BuildRules the same since module 0.2.15).
func test_they_travel_in_gifts() -> void:
	for id: int in RingsBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.RING_ICE, Vector3i(1, 0, 0): BlockIds.SATURN_BAND})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i.ZERO), BlockIds.RING_ICE, "a rings block comes back as itself")
	assert_eq(back.get(Vector3i(1, 0, 0)), BlockIds.SATURN_BAND)


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_RING_ICE), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_RING_ICE, GatherRules.NONE), BlockIds.RING_ICE)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_RING_ICE, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_RING_ICE)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	assert_has(BotRules.NATURAL, BlockIds.RING_CRYSTAL, "the rings' own")
	for id in BUILT:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))
