extends GutTest


func test_item_ids_never_collide_with_blocks() -> void:
	for id in ItemIds.ALL:
		assert_false(BlockIds.is_valid(id), str(id))
		assert_gte(id, 100)


func test_stamps_are_items() -> void:
	for id in ItemIds.STAMPS:
		assert_true(ItemIds.is_stamp(id))
		assert_true(ItemIds.is_item(id))
	assert_false(ItemIds.is_stamp(ItemIds.WAND))


func test_every_item_has_a_name_and_icon() -> void:
	for id in ItemIds.ALL:
		assert_ne(ItemIds.display_name(id), "", str(id))
		assert_not_null(BlockIcons.icon(id), str(id))


func test_hotbar_validity() -> void:
	assert_true(ItemIds.is_hotbar_valid(BlockIds.BRICK))
	assert_true(ItemIds.is_hotbar_valid(ItemIds.WAND))
	assert_false(ItemIds.is_hotbar_valid(BlockIds.AIR))
	assert_false(ItemIds.is_hotbar_valid(999))


# --- Weapons, tools and targets (M1b Task 11) ---

func test_weapon_and_tool_ids_are_allocated() -> void:
	assert_eq([ItemIds.SWORD, ItemIds.BOW, ItemIds.BOOMERANG, ItemIds.HAMMER, ItemIds.AXE, ItemIds.PICKAXE,
		ItemIds.DUMMY, ItemIds.BULLSEYE], [110, 111, 112, 113, 114, 115, 116, 117])
	for id in ItemIds.TOOLS:
		assert_true(ItemIds.is_item(id), str(id))
		assert_true(ItemIds.is_hotbar_valid(id), str(id))
		assert_false(ItemIds.is_stamp(id), str(id))


## The palette's MAGIC and TOOLS rows, (M2 Task 6) its ARMORY page and (M3 Task 11) its PETS page show every item
## except the treasure-only ones (M2 Task 16), which are only ever found, and the crafted-only ones (spec §12.19).
## Blaster ammo is Survivor's only (Sandbox blasters need none), so it has no palette row. M3 Task 8: the BUILD
## page's tools and paints.
func test_magic_and_tools_rows_cover_every_item_once() -> void:
	var seen := {}
	for id in ItemIds.MAGIC + ItemIds.TOOLS + ItemIds.ARMORY + ItemIds.TREASURES + ItemIds.CRAFTED + ItemIds.BLASTERS + ItemIds.AMMO + ItemIds.GADGETS + ItemIds.TREATS \
			+ ItemIds.BUILD_TOOLS + ItemIds.PAINTS + ItemIds.CRYSTALS:   # owner 39: the PORTALS row
		assert_false(seen.has(id), "listed twice: %d" % id)
		seen[id] = true
	assert_eq(seen.size(), ItemIds.ALL.size())
	for id in ItemIds.ALL:
		assert_true(seen.has(id), str(id))


func test_targets_are_placeable_items() -> void:
	assert_eq(ItemIds.TARGETS, [ItemIds.DUMMY, ItemIds.BULLSEYE])
	assert_true(ItemIds.is_target(ItemIds.DUMMY))
	assert_false(ItemIds.is_target(ItemIds.SWORD))
	assert_eq(ItemIds.display_name(ItemIds.SWORD), "Sword")
	assert_eq(ItemIds.display_name(ItemIds.BULLSEYE), "Bullseye")


func test_tool_icons_are_drawn_in_atlas_row_5() -> void:
	var img := BlockLibrary.ATLAS.get_image()
	for i in ItemIds.TOOLS.size():
		var id: int = ItemIds.TOOLS[i]
		assert_eq(BlockIcons.ITEM_TILES.get(id), Vector2i(i, 5), ItemIds.display_name(id))
		var filled := 0
		for y in 16:
			for x in 16:
				if img.get_pixel(i * 16 + x, 5 * 16 + y).a > 0.5:
					filled += 1
		assert_gt(filled, 20, "icon drawn: %s" % ItemIds.display_name(id))


# --- Secrets and treasures (M2 Task 16) ---

func test_the_treasure_map_is_a_treasure_only_item() -> void:
	assert_eq(ItemIds.TREASURE_MAP, 170)
	assert_eq(ItemIds.TREASURES, [ItemIds.TREASURE_MAP])
	assert_true(ItemIds.is_item(ItemIds.TREASURE_MAP))
	assert_true(ItemIds.is_hotbar_valid(ItemIds.TREASURE_MAP))
	assert_false(ItemIds.MAGIC.has(ItemIds.TREASURE_MAP), "never in the palette: found, never picked")
	assert_false(ItemIds.TOOLS.has(ItemIds.TREASURE_MAP))
	assert_eq(ItemIds.display_name(ItemIds.TREASURE_MAP), "Treasure Map")
	assert_eq(BlockIcons.ITEM_TILES.get(ItemIds.TREASURE_MAP), Vector2i(4, 7), "drawn in the secrets' atlas row")
