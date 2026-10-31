extends GutTest
## The block palette: every block, the MAGIC row and the TOOLS row (M1b Task 11), on a 1280x720 screen.

const SCREEN := Vector2(1280, 720)
const HOTBAR_TOP := 720.0 - 78.0


func _palette() -> BlockPalette:
	var p := BlockPalette.new()
	add_child_autofree(p)
	return p


func _panel(p: BlockPalette) -> PanelContainer:
	return p.find_children("*", "PanelContainer", false, false)[0] as PanelContainer


func test_palette_offers_every_block_and_item_once() -> void:
	var names: Array[String] = []
	for b in _palette().find_children("*", "Button", true, false):
		names.append((b as Button).tooltip_text)
	assert_eq(names.size(), BlockIds.PLACEABLE.size() + ItemIds.ALL.size() - ItemIds.TREASURES.size() - ItemIds.CRAFTED.size() - ItemIds.AMMO.size()
		+ SmartPage.SMART_ROW.size() + SmartPage.GAME_ROW.size()   # M3 Task 7: the SMART page; a stick is only crafted
		+ BlockPalette.GADGET_BLOCKS.size()   # M3 Task 14a: the zipline post and the launch pad (ARMORY's GADGETS)
		+ BlockPalette.MAGIC_BLOCKS.size()   # M3 Task 20a: the saddle in the MAGIC row
		+ BlockPalette.HOME_BLOCKS.size()   # M3 Task 21b: the shelves in the SMART page's HOME row
		+ RocketPage.SPACE_ROW.size()   # spec §21d: the rocket parts in the SMART page's SPACE row
		+ 1 - ItemIds.CRYSTALS.size() + CrystalRules.sandbox_crystals(Profile.data.universe_unlocked).size()   # owner 39: PORTALS
		+ 1   # M3 Task 20b: the STAMPS page's NEW STAMP (its stamps are listed when it opens)
		+ BlockPalette.mob_animals().size() + ChatCommands.MONSTERS.size() + ChatCommands.BOSSES.size())   # owner #51: MOBS
	for id in ItemIds.ALL:
		# treasure is found, never picked (M2 Task 16); a stick is only crafted (spec §12.19); blaster ammo is
		# Survivor's only (M3 Task 14b); owner 39: a crystal once its universe is reached
		var shown := 0 if ItemIds.TREASURES.has(id) or ItemIds.CRAFTED.has(id) or ItemIds.AMMO.has(id) else 1
		if CrystalRules.is_crystal(id):
			shown = 1 if CrystalRules.earned(CrystalRules.universe_of(id), Profile.data.universe_unlocked) else 0
		assert_eq(names.count(ItemIds.display_name(id)), shown, ItemIds.display_name(id))


## M3 Task 20a: the saddle (a block) sits in the MAGIC row beside the wand: build it into a buddy and ride.
func test_the_saddle_is_in_the_magic_row() -> void:
	var p := _palette()
	var magic := p.find_children("*", "HBoxContainer", true, false)[0] as HBoxContainer
	assert_eq((magic.get_child(0) as Label).text, "MAGIC")
	var names: Array[String] = []
	for b in magic.get_children():
		if b is Button:
			names.append((b as Button).tooltip_text)
	assert_has(names, "Saddle")
	assert_has(names, ItemIds.display_name(ItemIds.WAND))
	assert_has(BlockPalette.MAGIC_BLOCKS, BlockIds.SADDLE)


func test_tools_row_is_below_the_magic_row() -> void:
	var p := _palette()
	var rows := p.find_children("*", "HBoxContainer", true, false)
	assert_eq(rows.size(), 2, "MAGIC and TOOLS rows")
	var tools := rows[1] as HBoxContainer
	assert_eq((tools.get_child(0) as Label).text, "TOOLS")
	assert_eq(tools.get_child_count(), 1 + ItemIds.TOOLS.size())
	assert_gt(tools.get_index(), rows[0].get_index())


func test_palette_fits_a_1280x720_screen_above_the_hotbar() -> void:
	var panel := _panel(_palette())
	var content := panel.get_combined_minimum_size()
	var top := SCREEN.y * 0.5 + panel.offset_top
	var bottom := SCREEN.y * 0.5 + panel.offset_bottom
	assert_gte(top, 0.0)
	assert_lte(bottom, HOTBAR_TOP, "the panel stays above the hotbar")
	assert_lte(content.y, panel.offset_bottom - panel.offset_top + 0.5, "every row fits the panel height")
	assert_lte(content.x, panel.offset_right - panel.offset_left + 0.5, "the TOOLS row fits the panel width")
	assert_lte(panel.offset_right - panel.offset_left, SCREEN.x)


## M2 Task 8: more blocks (doors, spike traps, lanterns; later Task 5's hiding spots) make the block grid
## wider, never taller than three rows, so the palette stays above the hotbar.
func test_the_blocks_take_at_most_three_rows() -> void:
	var p := _palette()
	var grid := p.find_children("*", "GridContainer", true, false)[0] as GridContainer
	assert_eq(grid.get_child_count(), BlockIds.PLACEABLE.size())
	assert_lte(ceili(grid.get_child_count() / float(grid.columns)), 3)
	assert_gte(grid.columns, 8)
