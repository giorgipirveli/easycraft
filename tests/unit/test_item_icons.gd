extends GutTest
## The item icon atlas and tier icons (M2 Task 6): data/items/item_icons.png (tools/make_item_icons.gd),
## tier icons made from a kind's picture with the rarity colour on the metal, a rarity rim and 1-5
## tier pips (colour is never the only sign: lead's accessibility ruling).

const TIERED_KINDS := [ItemIds.SWORD, ItemIds.BOW, ItemIds.PICKAXE, ItemIds.AXE, ItemIds.SPEAR, ItemIds.MACE, ItemIds.SHIELD_WOOD]


func _opaque(img: Image, rect: Rect2i) -> int:
	var n := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if img.get_pixel(x, y).a > 0.5:
				n += 1
	return n


func _is_grey(c: Color) -> bool:
	return c.a > 0.5 and c.r8 == c.g8 and c.g8 == c.b8


func test_the_atlas_is_8_by_8_tiles_of_16_px() -> void:
	var atlas: Image = BlockIcons.ITEM_ATLAS
	assert_not_null(atlas)
	assert_eq(atlas.get_size(), Vector2i(128, 128))


func test_rows_4_to_7_are_left_free_for_other_tasks() -> void:
	var atlas: Image = BlockIcons.ITEM_ATLAS
	assert_eq(_opaque(atlas, Rect2i(0, 64, 128, 64)), 0, "row 4 is Task 16's, row 5 Task 15's, rows 6-7 free")


func test_every_kind_has_a_picture_with_tintable_metal_and_room_for_pips() -> void:
	var atlas: Image = BlockIcons.ITEM_ATLAS
	for kind: int in TIERED_KINDS:
		var tile: Vector2i = BlockIcons.KIND_TILES[kind]
		assert_eq(tile.y, 0, "row 0: %s" % ItemIds.display_name(kind))
		var pic := BlockIcons.item_picture(tile)
		assert_gt(_opaque(pic, Rect2i(0, 0, 16, 16)), 20, "drawn: %s" % ItemIds.display_name(kind))
		assert_eq(_opaque(pic, Rect2i(0, 0, 13, 3)), 0, "the pip band is empty: %s" % ItemIds.display_name(kind))
		var greys := 0
		for y in 16:
			for x in 16:
				if _is_grey(pic.get_pixel(x, y)):
					greys += 1
		assert_gt(greys, 2, "has metal to tint: %s" % ItemIds.display_name(kind))
	assert_eq(atlas.get_size(), Vector2i(128, 128))


func test_potions_are_drawn_in_row_1() -> void:
	for id in ItemIds.POTIONS:
		var tile: Vector2i = BlockIcons.POTION_TILES[id]
		assert_eq(tile.y, 1, ItemIds.display_name(id))
		assert_gt(_opaque(BlockIcons.item_picture(tile), Rect2i(0, 0, 16, 16)), 40, ItemIds.display_name(id))


func test_tier_icons_carry_one_to_five_pips() -> void:
	for tier in 5:
		var img := BlockIcons.tier_image(ItemIds.SWORD, tier)
		assert_eq(img.get_size(), Vector2i(32, 32))
		for i in 5:
			var c := img.get_pixelv(BlockIcons.pip_center(i))
			if i <= tier:
				assert_eq(c, BlockIcons.PIP_COLOR, "tier %d has pip %d" % [tier, i + 1])
			else:
				assert_ne(c, BlockIcons.PIP_COLOR, "tier %d has no pip %d" % [tier, i + 1])


func test_tier_icons_have_a_rim_in_their_rarity_colour() -> void:
	for tier in 5:
		var img := BlockIcons.tier_image(ItemIds.MACE, tier)
		var rim := ItemRarity.color(ItemRarity.of_tier(tier))
		var found := 0
		for y in range(8, 32):          # below the pips
			for x in 32:
				if img.get_pixel(x, y).is_equal_approx(rim):
					found += 1
		assert_gt(found, 30, "a rim of %s" % ItemRarity.label(tier))


func test_the_metal_takes_the_tier_colour_and_the_wood_stays() -> void:
	var wood := BlockIcons.tier_image(ItemIds.AXE, WeaponRules.TIER_WOOD)
	var iron := BlockIcons.tier_image(ItemIds.AXE, WeaponRules.TIER_IRON)
	var greys_wood := 0
	var greys_iron := 0
	var blue_iron := 0
	for y in range(8, 32):
		for x in 32:
			if _is_grey(wood.get_pixel(x, y)):
				greys_wood += 1
			var c := iron.get_pixel(x, y)
			if _is_grey(c):
				greys_iron += 1
			elif c.a > 0.5 and c.b > c.r + 0.15:
				blue_iron += 1
	assert_gt(greys_wood, 10, "the wood tier keeps the steel look")
	assert_eq(greys_iron, 0, "every metal pixel is tinted")
	assert_gt(blue_iron, 10, "iron is blue (rare)")
	var handle := BlockIcons.item_picture(BlockIcons.KIND_TILES[ItemIds.AXE]).get_pixel(3, 13)
	assert_eq(iron.get_pixel(6, 26), handle, "the wooden handle keeps its colour")


func test_every_item_icon_is_cached() -> void:
	for id in ItemIds.ALL:
		var tex := BlockIcons.icon(id)
		assert_not_null(tex, ItemIds.display_name(id))
		assert_same(BlockIcons.icon(id), tex, "made once: %s" % ItemIds.display_name(id))
	assert_eq(BlockIcons.icon(ItemIds.SWORD_COSMIC).get_size(), Vector2(32, 32))
	assert_eq(BlockIcons.icon(ItemIds.POTION_SPEED).get_size(), Vector2(16, 16))
