extends GutTest
## Cosmos: Io (world 21, spec §21b.2): its blocks, ids 384-398 on block atlas page 21 (399 free; the last page under
## the items' ids), drawn in both styles (data/blocks/pages/io.png and its realistic twin): yellow sulphur, orange
## sulphur, white sulphur frost (frozen sulphur dioxide) and red sulphur (the rings round a plume), Io's rock under them,
## black lava rock (cooled lava), the glowing lava crust of its lava lakes (black with glowing cracks: safe to walk on),
## hot lava (bright: a warm bounce throws a child out, never hurts), the volcano vent (a plume throws you up), glowing
## sulphur crystals, the Volcano Lander's heat tiles, legs and heat camera, sulphur bricks (the explorers' station) and a
## fake Io-rock door (the hidden room). The landing pad and star gold are the Moon's (every space world's).

const GLOWS: Array[int] = [BlockIds.LAVA_CRUST, BlockIds.HOT_LAVA, BlockIds.VOLCANO_VENT, BlockIds.SULPHUR_CRYSTAL,
	BlockIds.HEAT_CAMERA]
const GROUND: Array[int] = [BlockIds.SULPHUR, BlockIds.ORANGE_SULPHUR, BlockIds.SULPHUR_FROST, BlockIds.RED_SULPHUR,
	BlockIds.IO_ROCK, BlockIds.BLACK_LAVA]


func test_every_io_block_is_on_page_21() -> void:
	assert_eq(IoBlocks.PAGE, 21)
	for id: int in IoBlocks.TILES:
		assert_between(id, 384, 399, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), IoBlocks.PAGE, BlockIds.display_name(id))
	assert_eq(IoBlocks.TILES.size(), 15)
	assert_eq(BlockIds.RESERVED_FIRST, 400, "the first id past Io's page: the items' ids start there")
	assert_gt(BlockIds.COUNT, BlockIds.RESERVED_END, "later pages go on past the items' (Titan's page 29)")
	for other: int in [MoonBlocks.PAGE, BoingBlocks.PAGE, RainbowBlocks.PAGE, MarsBlocks.PAGE, EuropaBlocks.PAGE,
			LabPage.PAGE, DesertBlocks.PAGE, DragonBlocks.PAGE]:
		assert_ne(other, IoBlocks.PAGE, "a page of its own")


func test_the_page_is_registered_before_any_library_is_built() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id: int in IoBlocks.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = IoBlocks.TILES[id][3]
		assert_same(m.get_material_override(0), BlockLibrary.page_material(IoBlocks.PAGE, kind), BlockIds.display_name(id))


func test_the_glowing_ones_glow_and_every_block_is_solid() -> void:
	for id: int in IoBlocks.TILES:
		assert_eq(IoBlocks.TILES[id][3], &"glow" if GLOWS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(IoBlocks.TILES[id][i]),
				"%s tile %d inside the page" % [BlockIds.display_name(id), i])


func test_both_styles_draw_every_tile() -> void:
	assert_eq(IoBlocks.FILES, ["res://data/blocks/pages/io.png", "res://data/blocks/pages/io_albedo.png",
		"res://data/blocks/pages/io_normal.png"])
	var pixel := (load(IoBlocks.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(IoBlocks.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq((load(IoBlocks.FILES[1]) as Texture2D).get_width(), 2048)
	assert_eq((load(IoBlocks.FILES[2]) as Texture2D).get_width(), 1024, "the normal map imported at half size")
	for id: int in IoBlocks.TILES:
		for i in 3:
			var t: Vector2i = IoBlocks.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			assert_gt(seen, 200, "%s tile %s is drawn" % [BlockIds.display_name(id), t])
			assert_gt(real.get_pixel(t.x * 256 + 128, t.y * 256 + 128).a, 0.1, "%s tile %s is painted" % [BlockIds.display_name(id), t])


## Io's real colours (spec §21b.2): sulphur yellow and orange, white frost, red rings, black lava; bright, never gloomy.
func test_yellow_and_orange_sulphur_white_frost_red_rings_and_black_lava() -> void:
	var pixel := (load(IoBlocks.FILES[0]) as Texture2D).get_image()
	var sulphur := _mean(pixel, IoBlocks.TILES[BlockIds.SULPHUR][0])
	assert_gt(sulphur.r, sulphur.b + 0.35, "sulphur is yellow (%s)" % sulphur)
	assert_gt(sulphur.g, sulphur.b + 0.3, "yellow, not red (%s)" % sulphur)
	assert_gt(sulphur.get_luminance(), 0.65, "bright yellow plains")
	var orange := _mean(pixel, IoBlocks.TILES[BlockIds.ORANGE_SULPHUR][0])
	assert_gt(orange.r, orange.g + 0.15, "orange (%s)" % orange)
	assert_gt(orange.g, orange.b + 0.1, "orange, not red (%s)" % orange)
	var frost := _mean(pixel, IoBlocks.TILES[BlockIds.SULPHUR_FROST][0])
	assert_gt(frost.get_luminance(), 0.82, "white frost (%s)" % frost)
	var red := _mean(pixel, IoBlocks.TILES[BlockIds.RED_SULPHUR][0])
	assert_gt(red.r, red.g + 0.3, "red sulphur (%s)" % red)
	var black := _mean(pixel, IoBlocks.TILES[BlockIds.BLACK_LAVA][1])
	assert_lt(black.get_luminance(), 0.3, "black lava rock (%s)" % black)
	var rock := _mean(pixel, IoBlocks.TILES[BlockIds.IO_ROCK][1])
	assert_between(rock.get_luminance(), black.get_luminance() + 0.05, 0.7, "Io's rock, lighter than black lava")


func test_the_lava_crust_is_black_with_glowing_cracks_and_hot_lava_bright() -> void:
	var pixel := (load(IoBlocks.FILES[0]) as Texture2D).get_image()
	var t: Vector2i = IoBlocks.TILES[BlockIds.LAVA_CRUST][0]
	var dark := 0
	var glowing := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(t.x * 16 + x, t.y * 16 + y)
			if c.get_luminance() < 0.25:
				dark += 1
			elif c.r > 0.85 and c.g > 0.3 and c.b < 0.35:
				glowing += 1
	assert_gt(dark, 140, "mostly a black crust (%d)" % dark)
	assert_gt(glowing, 20, "cracks glowing orange (%d)" % glowing)
	var hot := _mean(pixel, IoBlocks.TILES[BlockIds.HOT_LAVA][0])
	assert_gt(hot.get_luminance(), 0.55, "bright, glowing lava (%s)" % hot)
	assert_gt(hot.r, hot.b + 0.5, "orange-yellow (%s)" % hot)
	var crystal := _mean(pixel, IoBlocks.TILES[BlockIds.SULPHUR_CRYSTAL][1])
	assert_gt(crystal.r, crystal.b + 0.3, "yellow crystals (%s)" % crystal)
	assert_gt(crystal.get_luminance(), 0.65)


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
	for id: int in IoBlocks.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id), "%d is not an item id" % id)
	assert_eq(BlockIds.display_name(BlockIds.SULPHUR), "Sulphur")
	assert_eq(BlockIds.display_name(BlockIds.SULPHUR_FROST), "Sulphur Frost")
	assert_eq(BlockIds.display_name(BlockIds.LAVA_CRUST), "Lava Crust")
	assert_eq(BlockIds.display_name(BlockIds.HOT_LAVA), "Hot Lava")
	assert_eq(BlockIds.display_name(BlockIds.VOLCANO_VENT), "Volcano Vent")
	assert_eq(BlockIds.display_name(BlockIds.BLACK_LAVA), "Black Lava Rock")
	assert_eq(BlockIds.display_name(BlockIds.FAKE_IO_ROCK), "Io Rock", "a hidden door is named like its wall")


func test_the_secrets_and_ground_are_wired_like_every_universes() -> void:
	assert_true(SecretRules.is_fake_wall(BlockIds.FAKE_IO_ROCK), "a knock opens it")
	assert_eq(GatherRules.drop(BlockIds.FAKE_IO_ROCK, GatherRules.NONE), BlockIds.IO_ROCK)
	assert_has(ChatCommands.NEVER_GIVEN, BlockIds.FAKE_IO_ROCK, "found, never given")
	assert_has(CaptureRules.GROUND, BlockIds.FAKE_IO_ROCK)
	for id: int in GROUND:
		assert_has(BlockIds.SPACE_GROUND, id, "%s is a planet's ground" % BlockIds.display_name(id))
	for id: int in BlockIds.SPACE_GROUND:
		assert_has(BotRules.GROUND, id)
		assert_has(BotRules.NATURAL, id)
		assert_has(SurpriseRules.METEOR_REPLACES, id)
		assert_has(CaptureRules.GROUND, id, "the wand never wakes a planet's ground")
	for id in [BlockIds.LAVA_CRUST, BlockIds.HOT_LAVA, BlockIds.VOLCANO_VENT, BlockIds.SULPHUR_CRYSTAL]:
		assert_has(BotRules.NATURAL, id, "%s is the moon's own" % BlockIds.display_name(id))
	for id in [BlockIds.HOT_LAVA, BlockIds.VOLCANO_VENT]:
		assert_false(SurpriseRules.METEOR_REPLACES.has(id), "a meteor never paves over %s" % BlockIds.display_name(id))
	for id in [BlockIds.HEAT_TILE, BlockIds.LANDER_LEG, BlockIds.SULPHUR_BRICK]:
		assert_false(BlockIds.SPACE_GROUND.has(id), "%s is built, not ground" % BlockIds.display_name(id))


# --- The volcano vent throws a child up; hot lava bounces them out (never hurts) ---

func test_a_volcano_vent_is_a_pad_that_throws_you_up() -> void:
	assert_true(PadRules.is_pad(BlockIds.VOLCANO_VENT))
	var pads := PadRules.new()
	var fired := pads.touch(BlockIds.VOLCANO_VENT, Vector3(2, 0, 0), Vector3.FORWARD)
	assert_eq(fired, BlockIds.VOLCANO_VENT)
	var v := pads.apply(Vector3(2, 0, 0), fired)
	assert_eq(v.y, PadRules.GEYSER_SPEED, "up with the plume, like Europa's")
	assert_eq(v.x, 2.0, "keeping the run")
	var up := _height(v.y, 0.18)
	assert_between(up, 20.0, 35.0, "about 30 blocks up on Io (%.1f), a long float down" % up)


func test_hot_lava_bounces_a_child_out_and_never_hurts() -> void:
	assert_true(PadRules.is_pad(BlockIds.HOT_LAVA), "a warm bounce, like a pad")
	var pads := PadRules.new()
	var fired := pads.touch(BlockIds.HOT_LAVA, Vector3(0, -3, 1), Vector3.FORWARD)
	assert_eq(fired, BlockIds.HOT_LAVA)
	var v := pads.apply(Vector3(0, -3, 1), fired)
	assert_eq(v.y, PadRules.LAVA_SPEED)
	assert_eq(v.z, 1.0, "keeping the run: out the way the child was going")
	var up := _height(PadRules.LAVA_SPEED, 0.18)
	assert_gt(up, float(IoTerrain.MOAT_DEPTH) + 1.0, "high enough to leave the lava lake's moat (%.1f blocks)" % up)
	assert_lt(up, _height(Player.JUMP_VELOCITY, 0.18), "gentler than a jump there")
	var air := 2.0 * PadRules.LAVA_SPEED / (Player.GRAVITY * 0.18)
	assert_gt(air, 3.0, "seconds in the air to steer away (%.1f s)" % air)
	assert_lt(PadRules.LAVA_SPEED, PadRules.LAUNCH_SPEED, "softer than a jump pad")


func _height(v: float, g: float) -> float:
	return v * v / (2.0 * Player.GRAVITY * g)
