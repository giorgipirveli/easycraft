extends GutTest
## Cosmos: Venus's cloud city (world 24, spec §21b.2): its blocks, ids 656-671 on block atlas page 38 (after the wonders'
## pages 36-37), drawn in both styles (data/blocks/pages/venus.png and its realistic twin): the pale yellow cloud tops far
## below and the deeper clouds under them, the city's cream decks and silvery float hulls (full of the air we breathe),
## its sky gardens' turf and honey-coloured bridges, its warm lamps and white frames, the homes' peach panels, the
## Research Blimp's white skin, teal stripe, gondola and solar film, glowing cloud crystals (the secrets), the
## telescopes of the cloud scope and the west lookout, and a fake hull door (the hidden room). The landing pad and star
## gold are the Moon's (every space world's).

const GLOWS: Array[int] = [BlockIds.CLOUD_LAMP, BlockIds.CLOUD_CRYSTAL]
## The world's ground: the clouds, and the city's decks, hulls and garden turf (every step a child takes on Venus is on
## them: bots build there, a meteor may land there, the Magic Wand never wakes them; ruling in the notes).
const GROUND: Array[int] = [BlockIds.VENUS_CLOUD, BlockIds.DEEP_CLOUD, BlockIds.CLOUD_DECK, BlockIds.FLOAT_HULL,
	BlockIds.SKY_TURF]
const BUILT: Array[int] = [BlockIds.SKY_BRIDGE, BlockIds.CLOUD_LAMP, BlockIds.SKY_FRAME, BlockIds.HOME_PANEL,
	BlockIds.BLIMP_SKIN, BlockIds.BLIMP_STRIPE,
	BlockIds.GONDOLA, BlockIds.SOLAR_FILM, BlockIds.TELESCOPE]


func test_every_venus_block_is_on_page_38() -> void:
	assert_eq(VenusBlocks.PAGE, 38)
	for id: int in VenusBlocks.TILES:
		assert_between(id, 656, 671, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), VenusBlocks.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id), "%d is not the items'" % id)
	assert_eq(VenusBlocks.TILES.size(), 16, "the whole page: ids 656-671")
	assert_gte(BlockIds.COUNT, 672, "past Venus's page")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 672, "the next block pages start past Venus's")
	assert_eq(BlockLibrary.page_of(672), 39, "Venus's page is followed by page 39")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, EuropaBlocks.PAGE,
			IoBlocks.PAGE, TitanBlocks.PAGE, MercuryBlocks.PAGE, ColonyBlocks.PAGE, RocketPage.PAGE, ProspectPage.PAGE,
			LabPage.PAGE, DesertBlocks.PAGE, DragonBlocks.PAGE]:
		assert_ne(other, VenusBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in VenusBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = VenusBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(VenusBlocks.PAGE, kind),
			BlockIds.display_name(id))


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in VenusBlocks.TILES:
		assert_eq(VenusBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s holds a child up" % BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(VenusBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(VenusBlocks.FILES, ["res://data/blocks/pages/venus.png", "res://data/blocks/pages/venus_albedo.png",
		"res://data/blocks/pages/venus_normal.png"])
	var pixel := (load(VenusBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(VenusBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(VenusBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(VenusBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in VenusBlocks.TILES:
		for i in 3:
			var t: Vector2i = VenusBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1,
				"%s tile %s is painted" % [BlockIds.display_name(id), t])


## Venus's real colours (spec §21b.2: "yellow clouds"): pale yellow cloud tops (the sulfuric acid clouds seen from above),
## deeper ochre clouds under them; the city bright and friendly (§3c): cream decks, green gardens, warm lamps.
func test_yellow_clouds_under_a_bright_city() -> void:
	var pixel := (load(VenusBlocks.FILES[0]) as Texture2D).get_image()
	var cloud := _mean(pixel, VenusBlocks.TILES[BlockIds.VENUS_CLOUD][0])
	assert_gt(cloud.get_luminance(), 0.7, "bright cloud tops (%s)" % cloud)
	assert_gt(cloud.r, cloud.b + 0.25, "yellow, not white (%s)" % cloud)
	assert_gt(cloud.g, cloud.b + 0.15, "yellow, not orange (%s)" % cloud)
	var deep := _mean(pixel, VenusBlocks.TILES[BlockIds.DEEP_CLOUD][1])
	assert_lt(deep.get_luminance(), cloud.get_luminance() - 0.08, "deeper clouds under the tops (%s)" % deep)
	assert_gt(deep.r, deep.b + 0.3, "an ochre haze (%s)" % deep)
	var deck := _mean(pixel, VenusBlocks.TILES[BlockIds.CLOUD_DECK][0])
	assert_gt(deck.get_luminance(), 0.8, "a bright cream deck (%s)" % deck)
	var hull := _mean(pixel, VenusBlocks.TILES[BlockIds.FLOAT_HULL][1])
	assert_gt(hull.get_luminance(), 0.75, "a silvery-white float hull (%s)" % hull)
	assert_gte(hull.b, hull.r - 0.02, "silver, not yellow (%s)" % hull)
	var turf := _mean(pixel, VenusBlocks.TILES[BlockIds.SKY_TURF][0])
	assert_gt(turf.g, turf.r + 0.15, "a green garden (%s)" % turf)
	var bridge := _mean(pixel, VenusBlocks.TILES[BlockIds.SKY_BRIDGE][0])
	assert_gt(bridge.r, bridge.b + 0.2, "honey-coloured planks (%s)" % bridge)
	var lamp := _mean(pixel, VenusBlocks.TILES[BlockIds.CLOUD_LAMP][1])
	assert_gt(lamp.get_luminance(), 0.7, "a warm bright lamp (%s)" % lamp)
	var crystal := _mean(pixel, VenusBlocks.TILES[BlockIds.CLOUD_CRYSTAL][1])
	assert_gt(crystal.get_luminance(), 0.75, "a bright crystal (%s)" % crystal)


func test_the_blimp_is_white_with_a_teal_stripe_and_a_window() -> void:
	var pixel := (load(VenusBlocks.FILES[0]) as Texture2D).get_image()
	var skin := _mean(pixel, VenusBlocks.TILES[BlockIds.BLIMP_SKIN][1])
	assert_gt(skin.get_luminance(), 0.85, "a white skin (%s)" % skin)
	var stripe := _mean(pixel, VenusBlocks.TILES[BlockIds.BLIMP_STRIPE][1])
	assert_gt(stripe.g, stripe.r + 0.2, "the brand's teal (%s)" % stripe)
	var film := _mean(pixel, VenusBlocks.TILES[BlockIds.SOLAR_FILM][0])
	assert_gt(film.b, film.r + 0.1, "dark blue solar cells (%s)" % film)
	assert_lt(film.get_luminance(), 0.45, "dark (%s)" % film)
	var gondola := VenusBlocks.TILES[BlockIds.GONDOLA][1] as Vector2i
	var blue := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(gondola.x * 16 + x, gondola.y * 16 + y)
			if c.b > c.r + 0.15 and c.b > 0.6:
				blue += 1
	assert_gt(blue, 20, "a round blue window in the gondola's side (%d)" % blue)
	var tube := _mean(pixel, VenusBlocks.TILES[BlockIds.TELESCOPE][1])
	assert_gt(tube.r, tube.b + 0.25, "a brass telescope (%s)" % tube)


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
	for id: int in VenusBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_block_id(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id) or ChatCommands.NEVER_GIVEN.has(id), "/give knows %s" % id)
	assert_eq(BlockIds.display_name(BlockIds.VENUS_CLOUD), "Yellow Cloud")
	assert_eq(BlockIds.display_name(BlockIds.CLOUD_DECK), "Cloud Deck")
	assert_eq(BlockIds.display_name(BlockIds.FLOAT_HULL), "Float Hull")
	assert_eq(BlockIds.display_name(BlockIds.BLIMP_SKIN), "Blimp Skin")
	assert_eq(BlockIds.display_name(BlockIds.TELESCOPE), "Telescope")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_FLOAT_HULL), "Float Hull", "a hidden door is named like its wall")


## Gifts and showcases carry Venus's blocks (blocks up to 1023, the server's BuildRules the same since module 0.2.15).
func test_they_travel_in_gifts() -> void:
	for id: int in VenusBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.BLIMP_SKIN, Vector3i(1, 0, 0): BlockIds.CLOUD_LAMP})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i.ZERO), BlockIds.BLIMP_SKIN, "a Venus block comes back as itself")
	assert_eq(back.get(Vector3i(1, 0, 0)), BlockIds.CLOUD_LAMP)


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_FLOAT_HULL), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_FLOAT_HULL, GatherRules.NONE), BlockIds.FLOAT_HULL)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_FLOAT_HULL, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_FLOAT_HULL)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	assert_has(BotRules.NATURAL, BlockIds.CLOUD_CRYSTAL, "the planet's own")
	for id in BUILT:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))
