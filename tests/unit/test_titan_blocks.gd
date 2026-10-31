extends GutTest
## Cosmos: Titan (world 22, spec §21b.2): its blocks, ids 512-522 on block atlas page 29 (523-527 free; the first block
## page past the items' ids 400-511), drawn in both styles (data/blocks/pages/titan.png and its realistic twin): Titan's
## orange-brown soil, ice pebbles on it (the rounded pebbles of water ice a probe saw where it landed), the dark grains of
## its dunes, the wet shore round its methane lakes and sea, its icy rock (water ice as hard as stone), glowing shore
## crystals (the bright rings a drying lake leaves), the Landing Probe's shell, its parachute and its lamps, the
## explorers' station bricks and a fake icy-rock door (the hidden room). The landing pad and star gold are the Moon's
## (every space world's). Its lakes are the game's WATER shown as liquid methane (BlockLibrary.set_liquid): no block id.

const GLOWS: Array[int] = [BlockIds.SHORE_CRYSTAL, BlockIds.PROBE_LAMP]
const GROUND: Array[int] = [BlockIds.TITAN_SOIL, BlockIds.ICE_PEBBLES, BlockIds.DUNE_SAND, BlockIds.WET_SHORE,
	BlockIds.ICY_ROCK]


func test_every_titan_block_is_on_page_29_past_the_items_ids() -> void:
	assert_eq(TitanBlocks.PAGE, 29)
	for id: int in TitanBlocks.TILES:
		assert_between(id, 512, 527, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), TitanBlocks.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id), "%d is not the items'" % id)
	assert_eq(TitanBlocks.TILES.size(), 11)
	assert_gte(BlockIds.COUNT, 528, "past Titan's page (Mercury's page 30 goes on to 543)")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 528, "the next block pages start past Titan's")
	assert_eq(BlockLibrary.page_of(528), 30, "Titan's page is followed by page 30 (Mercury's)")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, EuropaBlocks.PAGE,
			IoBlocks.PAGE, LabPage.PAGE, DesertBlocks.PAGE, DragonBlocks.PAGE]:
		assert_ne(other, TitanBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in TitanBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = TitanBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(TitanBlocks.PAGE, kind), BlockIds.display_name(id))


## The big gap: ids 400-511 are the items' (never blocks), so the library holds empty models there and Titan's cubes
## after them, and none of those ids is solid, placeable or a block.
func test_the_items_ids_stay_empty_in_the_library() -> void:
	var lib := BlockLibrary.build()
	for id in range(BlockIds.RESERVED_FIRST, BlockIds.RESERVED_END):
		assert_true(lib.models[id] is VoxelBlockyModelEmpty, "id %d is the items': an empty model" % id)
		assert_false(BlockIds.is_solid(id), "id %d is not solid" % id)
		assert_false(BlockIds.is_valid(id), "id %d is never placed" % id)
	for id in range(BlockIds.RESERVED_END, BlockIds.COUNT):
		if not _owned(id):   # Mercury's page 30, the rockets' page 32 (spec §21d) after it; page 31 kept empty
			assert_true(lib.models[id] is VoxelBlockyModelEmpty, "unowned id %d stays empty" % id)


## Some registered page owns block `id` (the gaps between pages stay empty, whoever adds a page).
func _owned(id: int) -> bool:
	for page: int in BlockLibrary._pages:
		if (BlockLibrary._pages[page].tiles as Dictionary).has(id):
			return true
	return false


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in TitanBlocks.TILES:
		assert_eq(TitanBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(TitanBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(TitanBlocks.FILES, ["res://data/blocks/pages/titan.png", "res://data/blocks/pages/titan_albedo.png",
		"res://data/blocks/pages/titan_normal.png"])
	var pixel := (load(TitanBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(TitanBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(TitanBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(TitanBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in TitanBlocks.TILES:
		for i in 3:
			var t: Vector2i = TitanBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1, "%s tile %s is painted" % [BlockIds.display_name(id), t])


## Titan's real colours (spec §21b.2): orange-brown ground under an orange haze, dark dune grains, pale ice pebbles and
## icy rock; friendly, never gloomy (§3c).
func test_orange_brown_soil_dark_dunes_and_pale_ice() -> void:
	var pixel := (load(TitanBlocks.FILES[0]) as Texture2D).get_image()
	var soil := _mean(pixel, TitanBlocks.TILES[BlockIds.TITAN_SOIL][0])
	assert_gt(soil.r, soil.g + 0.1, "orange-brown soil (%s)" % soil)
	assert_gt(soil.g, soil.b + 0.1, "orange, not red (%s)" % soil)
	assert_between(soil.get_luminance(), 0.35, 0.75, "a warm, bright ground")
	var dune := _mean(pixel, TitanBlocks.TILES[BlockIds.DUNE_SAND][0])
	assert_lt(dune.get_luminance(), soil.get_luminance() - 0.12, "the dunes' grains are darker (%s)" % dune)
	assert_gte(dune.r, dune.b, "a dark brown, never blue")
	var rock := _mean(pixel, TitanBlocks.TILES[BlockIds.ICY_ROCK][1])
	assert_gt(rock.get_luminance(), 0.55, "pale icy rock (%s)" % rock)
	assert_gte(rock.b, rock.r - 0.02, "grey-blue ice, not brown (%s)" % rock)
	var pebbles := _mean(pixel, TitanBlocks.TILES[BlockIds.ICE_PEBBLES][0])
	assert_gt(pebbles.get_luminance(), soil.get_luminance(), "pale pebbles over the soil (%s)" % pebbles)
	var shore := _mean(pixel, TitanBlocks.TILES[BlockIds.WET_SHORE][0])
	assert_lt(shore.get_luminance(), soil.get_luminance(), "a darker wet shore (%s)" % shore)
	var crystal := _mean(pixel, TitanBlocks.TILES[BlockIds.SHORE_CRYSTAL][1])
	assert_gt(crystal.get_luminance(), 0.7, "bright shore crystals (%s)" % crystal)


func test_the_probe_its_parachute_and_its_lamps() -> void:
	var pixel := (load(TitanBlocks.FILES[0]) as Texture2D).get_image()
	var chute := TitanBlocks.TILES[BlockIds.PARACHUTE][0] as Vector2i
	var orange := 0
	var white := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(chute.x * 16 + x, chute.y * 16 + y)
			if c.r > 0.8 and c.g < 0.65 and c.b < 0.4:
				orange += 1
			elif c.get_luminance() > 0.85:
				white += 1
	assert_gt(orange, 50, "orange stripes (%d)" % orange)
	assert_gt(white, 50, "and white ones (%d)" % white)
	var lamp := _mean(pixel, TitanBlocks.TILES[BlockIds.PROBE_LAMP][1])
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
	for id: int in TitanBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_true(BlockIds.is_block_id(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id) or ChatCommands.NEVER_GIVEN.has(id), "/give knows %s" % id)
	assert_eq(BlockIds.display_name(BlockIds.TITAN_SOIL), "Titan Soil")
	assert_eq(BlockIds.display_name(BlockIds.ICE_PEBBLES), "Ice Pebbles")
	assert_eq(BlockIds.display_name(BlockIds.DUNE_SAND), "Dune Grains")
	assert_eq(BlockIds.display_name(BlockIds.ICY_ROCK), "Icy Rock")
	assert_eq(BlockIds.display_name(BlockIds.SHORE_CRYSTAL), "Shore Crystal")
	assert_eq(BlockIds.display_name(BlockIds.PARACHUTE), "Parachute")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_ICY_ROCK), "Icy Rock", "a hidden door is named like its wall")


## Gifts and showcases carry Titan's blocks (the game's and the server's limit: blocks up to 1023, never the items'
## 400-511); the items still never travel.
func test_they_travel_in_gifts_and_items_never_do() -> void:
	for id: int in TitanBlocks.TILES:
		assert_true(BuildCodec.is_block_id(id), BlockIds.display_name(id))
	for id in [400, 451, 460, 499, 511, ItemIds.GLIDER]:
		assert_false(BuildCodec.is_block_id(id), "%d is the items'" % id)
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.DUNE_SAND, Vector3i(1, 0, 0): BlockIds.PARACHUTE})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i.ZERO), BlockIds.DUNE_SAND, "a Titan block comes back as itself")


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_ICY_ROCK), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_ICY_ROCK, GatherRules.NONE), BlockIds.ICY_ROCK)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_ICY_ROCK, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_ICY_ROCK)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
	for id: int in BlockIds.SPACE_GROUND:
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	assert_has(BotRules.NATURAL, BlockIds.SHORE_CRYSTAL, "the moon's own")
	for id in [BlockIds.PROBE_SHELL, BlockIds.PARACHUTE, BlockIds.PROBE_LAMP, BlockIds.TITAN_BRICK]:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))
