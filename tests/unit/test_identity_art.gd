extends GutTest
## Owner feedback #43 (spec §3c, docs/design/identity-audit.md): the audit's fixes that change the game's pictures
## and words. Portals are golden and rainbow (never purple swirls in dark frames), the Dragon Realm is a sunrise sky
## (never a black-and-purple void), the Sky Dragon heals from sun lanterns, the crafting stations are our own
## Workbench and Clay Oven, the grass side is a soft rounded cap and the ores are round gems. Checked in both styles
## where the style has the tile.

const PIXEL := 0
const REALISTIC := 1


func _page_image(files: Array, style: int) -> Image:
	var img := (load(files[style]) as Texture2D).get_image()
	if img.is_compressed():
		img.decompress()
	return img


## The mean colour of a tile's drawn pixels (the realistic tile's 240 px inside its 8 px border).
func _mean(img: Image, tile: Vector2i, rect := Rect2(0, 0, 1, 1)) -> Color:
	var s := img.get_width() / 8
	var pad := 0 if s == 16 else 8
	var inner := s - 2 * pad
	var step := maxi(inner / 32, 1)
	var sum := Vector3.ZERO
	var n := 0
	var x0 := int(rect.position.x * inner)
	var y0 := int(rect.position.y * inner)
	for y in range(y0, y0 + int(rect.size.y * inner), step):
		for x in range(x0, x0 + int(rect.size.x * inner), step):
			var c := img.get_pixel(tile.x * s + pad + x, tile.y * s + pad + y)
			if c.a > 0.5:
				sum += Vector3(c.r, c.g, c.b)
				n += 1
	if n == 0:
		return Color(0, 0, 0, 0)
	sum /= n
	return Color(sum.x, sum.y, sum.z)


func _violet(c: Color) -> bool:
	return c.s > 0.2 and c.h > 0.66 and c.h < 0.88


## Warm: red, orange, gold or peach (hue near 0 or up to about 60 degrees).
func _warm(c: Color) -> bool:
	return c.s > 0.2 and (c.h < 0.17 or c.h > 0.94)


func _describe(c: Color) -> String:
	return "%s (h %.2f s %.2f v %.2f)" % [c.to_html(false), c.h, c.s, c.v]

# --- Portals: gold and rainbow ---------------------------------------------------------------------------

func test_the_portal_frame_and_core_are_golden_in_both_styles() -> void:
	for style in [PIXEL, REALISTIC]:
		var img := _page_image(PortalPage.FILES, style)
		for tile: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]:
			var c := _mean(img, tile)
			assert_false(_violet(c), "style %d tile %s is not violet: %s" % [style, tile, _describe(c)])
			assert_true(_warm(c), "style %d tile %s is golden: %s" % [style, tile, _describe(c)])


func test_universe_cores_sit_in_a_golden_setting() -> void:
	for style in [PIXEL, REALISTIC]:
		var img := _page_image(PortalPage.FILES, style)
		for id: int in PortalPage.CORE_TILES:
			var side: Vector2i = PortalPage.CORE_TILES[id][1]
			var corner := _mean(img, side, Rect2(0.0, 0.0, 0.12, 0.12))
			assert_true(_warm(corner), "style %d %s: the setting's corner is gold: %s"
				% [style, BlockIds.display_name(id), _describe(corner)])


func test_no_portal_swirls_in_purple() -> void:
	for u: int in CrystalRules.SWIRLS:
		for c: Color in CrystalRules.swirl_colors(u):
			assert_false(_violet(c), "universe %d swirl colour %s" % [u, _describe(c)])
	# The plain portal (a linked pair, the hub's floor): gold, with rainbow arms.
	var plain := PortalSwirl.material()
	for p: StringName in [&"deep", &"bright", &"rim"]:
		var c: Variant = plain.get_shader_parameter(p)
		assert_true(c is Color, "the plain swirl sets its %s" % p)
		if c is Color:
			assert_false(_violet(c), "the plain swirl's %s: %s" % [p, _describe(c)])
			assert_true(_warm(c), "the plain swirl's %s is golden: %s" % [p, _describe(c)])
	assert_gt(float(plain.get_shader_parameter(&"rainbow") if plain.get_shader_parameter(&"rainbow") != null else 0.0), 0.5,
		"the plain portal's arms are a rainbow")
	var code := PortalSwirl.SHADER.code
	assert_string_contains(code, "uniform float rainbow")
	for old: String in ["vec4(0.22, 0.07, 0.5", "vec4(0.88, 0.55, 1.0"]:
		assert_false(code.contains(old), "the shader's defaults are not the old purple (%s)" % old)


func test_universe_portals_keep_their_own_colours_without_the_rainbow_arms() -> void:
	for u in range(1, 6):
		var m := PortalSwirl.material_for(u)
		assert_eq(m.get_shader_parameter(&"rainbow"), 0.0, "universe %d swirls in its own colours" % u)
	assert_ne(CrystalRules.swirl_colors(5)[1], CrystalRules.swirl_colors(2)[1], "the realm is not the desert")

# --- The Dragon Realm: a sunrise sky ---------------------------------------------------------------------

func test_the_dragon_realm_ground_is_sunrise_coloured_in_both_styles() -> void:
	var tiles := {BlockIds.SKY_GRASS: 0, BlockIds.FLOATSTONE: 0, BlockIds.DEEP_FLOATSTONE: 0,
		BlockIds.CRYSTAL_SPIRE: 1, BlockIds.FLOATSTONE_BRICK: 0}
	for style in [PIXEL, REALISTIC]:
		var img := _page_image(DragonBlocks.FILES, style)
		for id: int in tiles:
			var t: Vector2i = DragonBlocks.TILES[id][tiles[id]]
			var c := _mean(img, t)
			assert_false(_violet(c), "style %d %s: %s" % [style, BlockIds.display_name(id), _describe(c)])
		var moss := _mean(img, DragonBlocks.TILES[BlockIds.SKY_GRASS][0])
		assert_true(_warm(moss), "style %d: the islands' moss is a sunrise colour: %s" % [style, _describe(moss)])
		var spire := _mean(img, DragonBlocks.TILES[BlockIds.CRYSTAL_SPIRE][1])
		assert_true(_warm(spire), "style %d: golden crystal spires: %s" % [style, _describe(spire)])


func test_the_dragon_realm_sky_is_a_sunrise_over_a_sea_of_clouds() -> void:
	var sky := UniverseRegistry.sky(5)
	for key: String in sky:
		assert_false(_violet(sky[key]), "%s: %s" % [key, _describe(sky[key])])
	assert_gt((sky.ground_bottom as Color).get_luminance(), 0.75, "below the islands: bright clouds, not a dark void")
	assert_true(_warm(sky.sky_horizon), "a golden horizon: %s" % _describe(sky.sky_horizon))


func test_the_sky_dragon_heals_from_sun_lanterns() -> void:
	for mesh: ArrayMesh in [SkyDragonModels.tower_base_mesh(), SkyDragonModels.tower_crystal_mesh(),
			SkyDragonModels.beam_mesh(), SkyDragonModels.spark_mesh()]:
		for s in mesh.get_surface_count():
			for c: Color in mesh.surface_get_arrays(s)[Mesh.ARRAY_COLOR]:
				assert_false(_violet(c), "a tower colour: %s" % _describe(c))
	assert_string_contains(SkyDragonRules.TOWER_LINE, "sun lanterns")
	assert_string_contains(SkyDragonRules.TOWER_LINE_AGAIN, "sun lanterns")
	assert_false(SkyDragonRules.TIRED_MESSAGE.contains("crystal"), SkyDragonRules.TIRED_MESSAGE)

# --- The Workbench and the Clay Oven ---------------------------------------------------------------------

func test_the_stations_have_our_own_names() -> void:
	assert_eq(BlockIds.display_name(BlockIds.CRAFTING_TABLE), "Workbench")
	assert_eq(BlockIds.display_name(BlockIds.FURNACE), "Clay Oven")
	assert_eq(CraftRules.message("table", Recipes.find(&"sword"), Inventory.new()), "Stand next to a Workbench!")
	assert_eq(CraftRules.message("furnace", Recipes.find(&"glass"), Inventory.new()), "Stand next to a Clay Oven!")


func test_the_workbench_has_a_teal_painted_top_with_a_star_and_no_hanging_tools() -> void:
	var top: Vector2i = PortalPage.CRAFT_TILES[BlockIds.CRAFTING_TABLE][0]
	var side: Vector2i = PortalPage.CRAFT_TILES[BlockIds.CRAFTING_TABLE][1]
	for style in [PIXEL, REALISTIC]:
		var img := _page_image(PortalPage.FILES, style)
		var mat := _mean(img, top, Rect2(0.15, 0.55, 0.3, 0.3))
		assert_true(mat.s > 0.25 and mat.h > 0.42 and mat.h < 0.55, "style %d: a teal work mat: %s" % [style, _describe(mat)])
		var star := _mean(img, top, Rect2(0.45, 0.45, 0.1, 0.1))
		assert_true(star.s > 0.4 and star.h > 0.1 and star.h < 0.17, "style %d: a golden star stamp in the middle: %s"
			% [style, _describe(star)])
	var pixel := _page_image(PortalPage.FILES, PIXEL)
	var metal := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(side.x * 16 + x, side.y * 16 + y)
			if c.s < 0.12 and c.v > 0.6:
				metal += 1
	assert_eq(metal, 0, "no grey saw or hammer on the side")


func test_the_clay_oven_is_warm_clay_with_a_round_window() -> void:
	var top: Vector2i = PortalPage.CRAFT_TILES[BlockIds.FURNACE][0]
	var side: Vector2i = PortalPage.CRAFT_TILES[BlockIds.FURNACE][1]
	for style in [PIXEL, REALISTIC]:
		var img := _page_image(PortalPage.FILES, style)
		for t: Vector2i in [top, side]:
			var c := _mean(img, t, Rect2(0.0, 0.0, 1.0, 0.25))
			assert_true(_warm(c) and c.s > 0.3, "style %d tile %s is clay, not grey cobbles: %s" % [style, t, _describe(c)])
		var fire := _mean(img, side, Rect2(0.44, 0.56, 0.12, 0.12))
		assert_true(fire.v > 0.8 and _warm(fire), "style %d: fire in the round window: %s" % [style, _describe(fire)])
		var below := _mean(img, side, Rect2(0.44, 0.82, 0.12, 0.06))
		assert_lt(below.v, fire.v - 0.1, "style %d: the window is round, not a mouth down to the floor: %s" % [style, _describe(below)])

# --- Monsters -----------------------------------------------------------------------------------------------

func test_the_slime_is_a_jelly_dome_not_a_cube() -> void:
	for level in range(1, 6):
		var layers := {}   # the body's wide boxes: height of the top -> width
		for b: Array in MonsterModels.boxes(MonsterRules.SLIME, level):
			var size: Vector3 = b[1]
			var center: Vector3 = b[0]
			if b[3] == &"" and size.x >= 0.3 * MonsterRules.size_scale(level):
				layers[snappedf(center.y + size.y * 0.5, 0.001)] = size.x
		var tops := layers.keys()
		tops.sort()
		assert_gte(tops.size(), 3, "level %d: stacked layers, not one cube: %s" % [level, layers])
		for i in range(1, tops.size()):
			assert_lt(layers[tops[i]], layers[tops[i - 1]] + 0.001, "level %d: each layer up is narrower: %s" % [level, layers])
		assert_lt(layers[tops.back()], layers[tops[0]] * 0.65, "level %d: a round top: %s" % [level, layers])

# --- Page 0: the grass side and the ores ------------------------------------------------------------------

func _is_grass(c: Color) -> bool:
	return c.a > 0.5 and c.h > 0.2 and c.h < 0.42 and c.s > 0.35


## Dirt (and its pebbles): a mid brown, darker than a yellow flower.
func _is_dirt(c: Color) -> bool:
	return c.h > 0.03 and c.h < 0.14 and c.s > 0.4 and c.v < 0.72


func test_the_grass_side_is_a_soft_rounded_cap_with_little_flowers() -> void:
	var img := BlockLibrary.ATLAS.get_image()
	var tile: Vector2i = BlockLibrary.TILES[BlockIds.GRASS][1]
	var depths: Array[int] = []
	var flowers := 0
	for x in 16:
		var d := 0   # the first dirt pixel down the column: where the cap ends
		while d < 16 and not _is_dirt(img.get_pixel(tile.x * 16 + x, tile.y * 16 + d)):
			d += 1
		depths.append(d)
		for y in d:
			var c := img.get_pixel(tile.x * 16 + x, tile.y * 16 + y)
			if not _is_grass(c) and c.s > 0.3:
				flowers += 1
	for x in range(1, 16):
		assert_lte(absi(depths[x] - depths[x - 1]), 1, "a smooth, rounded edge at x %d: %s" % [x, depths])
	assert_gt(flowers, 0, "little flowers in the grass")


func test_ores_are_round_gems_with_a_glint() -> void:
	var img := BlockLibrary.ATLAS.get_image()
	for id: int in [BlockIds.COAL, BlockIds.IRON, BlockIds.GOLD, BlockIds.DIAMOND]:
		var t: Vector2i = BlockLibrary.TILES[id][1]
		var glints := 0
		var solid := 0   # 2 x 2 squares of the gem's own (non-stone) colour
		var stone := img.get_pixel(t.x * 16, t.y * 16)
		for y in 15:
			for x in 15:
				var c := img.get_pixel(t.x * 16 + x, t.y * 16 + y)
				if c.get_luminance() > 0.92:
					glints += 1
				var all_gem := true
				for p: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
					var q := img.get_pixel(t.x * 16 + x + p.x, t.y * 16 + y + p.y)
					if absf(q.get_luminance() - stone.get_luminance()) < 0.12 and absf(q.s - stone.s) < 0.12:
						all_gem = false
				if all_gem:
					solid += 1
		assert_gt(glints, 0, "%s: a white glint" % BlockIds.display_name(id))
		assert_gt(solid, 6, "%s: chunky gems, not specks" % BlockIds.display_name(id))
