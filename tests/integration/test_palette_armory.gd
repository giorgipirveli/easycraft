extends GutTest
## The palette's ARMORY page (M2 Task 6): every tier of every weapon, tool and shield, and the
## potions, in rows by tier; tier names and button rims in the rarity colours (§13.2). Sandbox shows
## all of them. The BLOCKS page keeps the M1b blocks, MAGIC and TOOLS rows.

const SCREEN := Vector2(1280, 720)
const HOTBAR_TOP := 720.0 - 78.0


func _palette() -> BlockPalette:
	var p := BlockPalette.new()
	add_child_autofree(p)
	return p


func _armory(p: BlockPalette) -> Control:
	return p.find_child("ARMORY", true, false) as Control


func _buttons_in(node: Node) -> Array[Button]:
	var list: Array[Button] = []
	for b in node.find_children("*", "Button", true, false):
		list.append(b as Button)
	return list


func _id_of(name: String) -> int:
	for id in ItemIds.ALL:
		if ItemIds.display_name(id) == name:
			return id
	return -1


func test_the_palette_has_a_blocks_page_and_an_armory_page() -> void:
	var p := _palette()
	var tabs := p.tab_bar
	assert_eq(tabs.get_tab_count(), 9, "M3 Task 7: SMART; M4 I: GIFTS; CRAFT for Survivor (spec §12.19); M3 Task 11: PETS; M3 Task 8: BUILD; M3 Task 20b: STAMPS; owner #51: MOBS")
	assert_eq(tabs.get_tab_title(0), "BLOCKS")
	assert_eq(tabs.get_tab_title(1), "ARMORY")
	assert_eq(tabs.get_tab_title(2), "SMART")
	assert_eq(tabs.get_tab_title(3), "GIFTS")
	assert_eq(tabs.get_tab_title(BlockPalette.CRAFT_PAGE), "CRAFT")
	assert_eq(tabs.get_tab_title(BlockPalette.PETS_TAB), "PETS")
	assert_eq(tabs.current_tab, 0, "blocks first")
	assert_true(p.find_child("BLOCKS", true, false).visible)
	assert_false(_armory(p).visible)
	tabs.current_tab = 1                  # a tap on ARMORY
	assert_true(_armory(p).visible)
	assert_false(p.find_child("BLOCKS", true, false).visible)


func test_sandbox_palette_offers_every_tier_and_potion() -> void:
	var p := _palette()
	var armory: Array[int] = []
	var page := _armory(p)   # the tier grid, the BLASTERS column (M3 Task 14b), then GADGETS (14a, counted in its own test)
	for b in _buttons_in(page.get_child(0)) + _buttons_in(page.find_child("BLASTERS", false, false)):
		armory.append(_id_of(b.tooltip_text))
	assert_eq(armory.size(), ItemIds.ARMORY.size() + ItemIds.BLASTERS.size(), "M3 Task 14b: and the blasters")
	for id in ItemIds.ARMORY + ItemIds.BLASTERS:
		assert_true(armory.has(id), ItemIds.display_name(id))
	var everywhere: Array[String] = []
	for b in _buttons_in(p):
		everywhere.append(b.tooltip_text)
	for kind: int in WeaponRules.TIERS:
		for id: int in WeaponRules.TIERS[kind]:
			assert_eq(everywhere.count(ItemIds.display_name(id)), 1, "once: %s" % ItemIds.display_name(id))


func test_rows_go_by_tier_with_names_in_rarity_colours() -> void:
	var grid := _armory(_palette()).find_children("*", "GridContainer", true, false)[0] as GridContainer
	var labels: Array[Label] = []
	for c in grid.get_children():
		if c is Label:
			labels.append(c as Label)
	assert_eq(labels.size(), 6, "five tiers and the potions")
	for t in 5:
		assert_eq(labels[t].text, WeaponRules.TIER_NAMES[t].to_upper())
		assert_eq(labels[t].get_theme_color("font_color"), ItemRarity.color(t), labels[t].text)
	assert_eq(labels[5].text, "POTIONS")
	# Each tier row holds that tier's items: the cell after a label and before the next.
	var tier := -1
	for c in grid.get_children():
		if c is Label:
			tier += 1
		elif c is Button and tier < 5:
			assert_eq(WeaponRules.tier_of(_id_of((c as Button).tooltip_text)), tier, (c as Button).tooltip_text)


func test_tier_buttons_have_a_rim_in_their_rarity_colour() -> void:
	for b in _buttons_in(_armory(_palette())):
		var id := _id_of(b.tooltip_text)
		var box := b.get_theme_stylebox("normal") as StyleBoxFlat
		assert_not_null(box, b.tooltip_text)
		if WeaponRules.tier_of(id) >= 0:
			assert_eq(box.border_color, ItemRarity.color(ItemRarity.of_item(id)), b.tooltip_text)
		assert_gte(box.border_width_left, 3, "a clear rim: %s" % b.tooltip_text)


func test_every_page_fits_above_the_hotbar() -> void:
	var p := _palette()
	var panel := p.find_children("*", "PanelContainer", false, false)[0] as PanelContainer
	var height := panel.offset_bottom - panel.offset_top
	var width := panel.offset_right - panel.offset_left
	for i in p.tab_bar.get_tab_count():
		p.show_page(i)
		var need := panel.get_combined_minimum_size()
		assert_lte(need.y, height + 0.5, "page %d fits the height" % i)
		assert_lte(need.x, width + 0.5, "page %d fits the width" % i)
	assert_gte(SCREEN.y * 0.5 + panel.offset_top, 0.0)
	assert_lte(SCREEN.y * 0.5 + panel.offset_bottom, HOTBAR_TOP)
	assert_lte(width, SCREEN.x)


func test_armory_buttons_are_big_enough_for_small_fingers() -> void:
	for b in _buttons_in(_armory(_palette())):
		assert_gte(b.custom_minimum_size.x, 76.0, b.tooltip_text)


func test_picking_a_cosmic_sword_puts_it_in_the_hotbar_slot() -> void:
	var p := _palette()
	watch_signals(p)
	for b in _buttons_in(_armory(p)):
		if b.tooltip_text == "Cosmic Sword":
			b.pressed.emit()
	assert_signal_emitted_with_parameters(p, "picked", [ItemIds.SWORD_COSMIC])
	assert_false(p.visible)


# --- M3 Task 14b: the BLASTERS column (Sandbox: every blaster, free) ---

func test_the_armory_page_has_a_blasters_column_by_rarity() -> void:
	var p := _palette()
	var column := _armory(p).find_child("BLASTERS", true, false) as Control
	assert_not_null(column, "a BLASTERS column on the ARMORY page")
	var label := column.find_children("*", "Label", true, false)[0] as Label
	assert_eq(label.text, "BLASTERS")
	var ids: Array[int] = []
	for b in _buttons_in(column):
		ids.append(_id_of(b.tooltip_text))
		var box := b.get_theme_stylebox("normal") as StyleBoxFlat
		assert_eq(box.border_color, ItemRarity.color(BlasterRules.rarity(ids[-1])), "%s: its rarity rim" % b.tooltip_text)
		assert_gte(b.custom_minimum_size.x, 76.0)
	assert_eq(ids, ItemIds.BLASTERS, "common to legendary, top to bottom")


func test_picking_a_blaster_puts_it_in_the_hotbar_slot() -> void:
	var p := _palette()
	watch_signals(p)
	for b in _buttons_in(_armory(p)):
		if b.tooltip_text == "Confetti Rocket":
			b.pressed.emit()
	assert_signal_emitted_with_parameters(p, "picked", [ItemIds.CONFETTI_ROCKET])
