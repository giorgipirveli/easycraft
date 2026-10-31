extends GutTest
## Missions (spec §21d.2): the rocket parts and the launch pad on block atlas page 32 (ids 560-573; 574-575 free; page
## 31, ids 544-559, is the colony domes'), drawn in both styles (data/blocks/pages/rockets.png
## and its realistic twin): engines with bell nozzles, a space engine with a golden bell, a white fuel tank with the
## brand's teal band, a red-tipped nose cone, a crew capsule with a round window, the service module, a heat shield, legs,
## fins, a stage separator, a solar array, a parachute pack, the pad's concrete and its yellow-and-black stripes.

const CUTOUTS: Array[int] = [BlockIds.ROCKET_ENGINE, BlockIds.SPACE_ENGINE, BlockIds.NOSE_CONE, BlockIds.CREW_CAPSULE,
	BlockIds.LANDING_LEGS, BlockIds.ROCKET_FINS]


func test_every_block_is_on_page_32() -> void:
	assert_eq(RocketPage.PAGE, 32)
	assert_eq(RocketPage.TILES.size(), 14, "12 parts and the pad's concrete and stripes")
	for id: int in RocketPage.TILES:
		assert_between(id, 560, 575, BlockIds.display_name(id))
		assert_eq(BlockLibrary.page_of(id), RocketPage.PAGE, BlockIds.display_name(id))
		assert_false(BlockIds.is_reserved(id))
	for id in RocketParts.ORDER:
		assert_true(RocketPage.TILES.has(id), BlockIds.display_name(id))
	assert_gte(BlockIds.COUNT, 576, "past the rockets' page (33-34 are the wonders', 35 is prospecting's)")
	assert_gte(BlockIds.NEXT_PAGE_FIRST_ID, 576)
	for other: int in [TitanBlocks.PAGE, MercuryBlocks.PAGE, LabPage.PAGE, MarsBlocks.PAGE, 31]:
		assert_ne(other, RocketPage.PAGE, "a page of its own")


## Page 31 went to the colony domes (spec §21c): every id there is the colony's, none a rocket part's.
func test_page_31_is_the_colony_domes() -> void:
	var lib := BlockLibrary.build()
	assert_eq(lib.models.size(), BlockIds.COUNT)
	for id in range(544, 560):
		assert_eq(BlockLibrary.page_of(id), 31)
		assert_true(ColonyBlocks.TILES.has(id), "id %d is the colony's" % id)
		assert_false(RocketPage.TILES.has(id), "id %d is no rocket part" % id)
	for id in [574, 575]:
		assert_true(lib.models[id] is VoxelBlockyModelEmpty, "id %d is free" % id)


func test_the_library_builds_each_part_with_its_pages_material() -> void:
	var lib := BlockLibrary.build()
	for id: int in RocketPage.TILES:
		var m := lib.models[id] as VoxelBlockyModelCube
		assert_not_null(m, "%s has a cube model" % BlockIds.display_name(id))
		var kind: StringName = RocketPage.TILES[id][3]
		assert_eq(kind, &"cutout" if CUTOUTS.has(id) else &"opaque", BlockIds.display_name(id))
		assert_same(m.get_material_override(0), BlockLibrary.page_material(RocketPage.PAGE, kind), BlockIds.display_name(id))
		assert_true(BlockIds.is_solid(id), "%s is solid: friends stand on it" % BlockIds.display_name(id))
		for i in 3:
			assert_true(Rect2i(Vector2i.ZERO, BlockLibrary.ATLAS_TILES).has_point(RocketPage.TILES[id][i]))


func test_both_styles_draw_every_tile() -> void:
	var pixel := (load(RocketPage.FILES[0]) as Texture2D).get_image()
	assert_eq(pixel.get_size(), Vector2i(128, 128), "8 x 8 tiles of 16 px")
	var real := (load(RocketPage.FILES[1]) as Texture2D).get_image()
	if real.is_compressed():
		real.decompress()
	assert_eq(real.get_width(), 2048)
	var rows := BlockLibrary.texture_rows(load(RocketPage.FILES[1]) as Texture2D)
	assert_eq(rows, 4, "the page draws four rows")
	for id: int in RocketPage.TILES:
		for i in 3:
			var t: Vector2i = RocketPage.TILES[id][i]
			var seen := 0
			for y in 16:
				for x in 16:
					if pixel.get_pixel(t.x * 16 + x, t.y * 16 + y).a > 0.1:
						seen += 1
			var want := 8 if CUTOUTS.has(id) else 250   # the nose cone's point, seen from above, is a dot
			assert_gt(seen, want, "%s tile %s is drawn (%d px)" % [BlockIds.display_name(id), t, seen])
		var side: Vector2i = RocketPage.TILES[id][1]
		var seen_real := 0
		for y in range(8, 248, 16):
			for x in range(8, 248, 16):
				if real.get_pixel(side.x * 256 + x, side.y * 256 + y).a > 0.1:
					seen_real += 1
		assert_gt(seen_real, 15 if CUTOUTS.has(id) else 200, "%s's side is painted realistic (%d)" % [BlockIds.display_name(id), seen_real])


## Our own look (spec §3c): a white tank with the brand's teal band, a red nose tip, golden space-engine bells, blue
## solar cells, grey concrete and yellow stripes; an engine's bell narrows at its throat (a shape, not a box).
func test_the_parts_look_like_themselves() -> void:
	var pixel := (load(RocketPage.FILES[0]) as Texture2D).get_image()
	var tank := _mean(pixel, RocketPage.TILES[BlockIds.FUEL_TANK][1])
	assert_gt(tank.get_luminance(), 0.75, "a white tank (%s)" % tank)
	var tip := pixel.get_pixel(RocketPage.TILES[BlockIds.NOSE_CONE][1].x * 16 + 7, RocketPage.TILES[BlockIds.NOSE_CONE][1].y * 16 + 2)
	assert_gt(tip.r, tip.g + 0.35, "a red nose tip (%s)" % tip)
	var gold := _mean(pixel, RocketPage.TILES[BlockIds.SPACE_ENGINE][1])
	assert_gt(gold.r, gold.b + 0.15, "a golden bell (%s)" % gold)
	var cells := _mean(pixel, RocketPage.TILES[BlockIds.SOLAR_ARRAY][1])
	assert_gt(cells.b, cells.r + 0.1, "blue solar cells (%s)" % cells)
	var concrete := _mean(pixel, RocketPage.TILES[BlockIds.PAD_CONCRETE][0])
	assert_lt(maxf(concrete.r, maxf(concrete.g, concrete.b)) - minf(concrete.r, minf(concrete.g, concrete.b)), 0.06, "grey concrete")
	var stripes := RocketPage.TILES[BlockIds.PAD_STRIPE][0] as Vector2i
	var yellow := 0
	var black := 0
	for y in 16:
		for x in 16:
			var c := pixel.get_pixel(stripes.x * 16 + x, stripes.y * 16 + y)
			if c.r > 0.8 and c.g > 0.7 and c.b < 0.4:
				yellow += 1
			elif c.get_luminance() < 0.2:
				black += 1
	assert_gt(yellow, 80, "yellow stripes (%d)" % yellow)
	assert_gt(black, 80, "and black (%d)" % black)
	var bell := RocketPage.TILES[BlockIds.ROCKET_ENGINE][1] as Vector2i
	var throat := 0
	var mouth := 0
	for x in 16:
		throat += 1 if pixel.get_pixel(bell.x * 16 + x, bell.y * 16 + 5).a > 0.1 else 0
		mouth += 1 if pixel.get_pixel(bell.x * 16 + x, bell.y * 16 + 15).a > 0.1 else 0
	assert_lt(throat, 10, "the bell's throat is narrow (%d)" % throat)
	assert_eq(mouth, 16, "its mouth is as wide as the block")


func _mean(img: Image, t: Vector2i) -> Color:
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var n := 0
	for y in 16:
		for x in 16:
			var c := img.get_pixel(t.x * 16 + x, t.y * 16 + y)
			if c.a < 0.1:
				continue
			r += c.r
			g += c.g
			b += c.b
			n += 1
	return Color(r / maxi(n, 1), g / maxi(n, 1), b / maxi(n, 1))


func test_names_validity_gifts_and_give() -> void:
	for id: int in RocketPage.TILES:
		assert_ne(BlockIds.display_name(id), "", str(id))
		assert_true(BlockIds.is_valid(id), BlockIds.display_name(id))
		assert_false(ItemIds.is_item(id))
		assert_true(ItemIds.is_hotbar_valid(id), "a hotbar slot holds %s" % BlockIds.display_name(id))
		assert_true(BuildCodec.is_block_id(id), "%s travels in gifts and showcases" % BlockIds.display_name(id))
		assert_true(ChatCommands.giveable_ids().has(id), "/give knows %s" % BlockIds.display_name(id))
		assert_false(PaintRules.paintable(id), "%s is never painted" % BlockIds.display_name(id))
	assert_eq(BlockIds.display_name(BlockIds.ROCKET_ENGINE), "Rocket Engine")
	assert_eq(BlockIds.display_name(BlockIds.CREW_CAPSULE), "Crew Capsule")
	assert_eq(BlockIds.display_name(BlockIds.PAD_STRIPE), "Pad Stripe")
	var text := BuildCodec.encode({Vector3i.ZERO: BlockIds.ROCKET_ENGINE, Vector3i(0, 1, 0): BlockIds.CREW_CAPSULE})
	var back := BuildCodec.decode(text, BuildCodec.GIFT)
	assert_eq(back.get(Vector3i(0, 1, 0)), BlockIds.CREW_CAPSULE, "a rocket comes back as itself")


func test_the_wand_never_wakes_the_pad_and_the_palette_has_a_space_row() -> void:
	assert_has(CaptureRules.GROUND, BlockIds.PAD_CONCRETE)
	assert_has(CaptureRules.GROUND, BlockIds.PAD_STRIPE)
	assert_eq(RocketPage.SPACE_ROW, RocketParts.ORDER, "every part, in the shop's order")
	assert_false(BlockIds.PLACEABLE.has(BlockIds.ROCKET_ENGINE), "the BLOCKS grid stays as it is: a row of their own")
