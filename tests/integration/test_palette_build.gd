extends GutTest
## M3 Task 8: the palette's BUILD tab (no new HUD button): a TOOLS row (LINE, FILL, COPY, REWIND) and the 16 paint
## buckets, each with its own picture. Survivor (spec §14.5: paint in both modes) shows the tab with REWIND and
## the paints; the power tools are the Sandbox's.

const HOTBAR_TOP := 720.0 - 78.0

var _inv_before: Inventory


func before_each() -> void:
	_inv_before = Session.my_inventory
	Session.my_inventory = Inventory.new()


func after_each() -> void:
	Session.my_inventory = _inv_before


func _palette(counted := false) -> BlockPalette:
	var p := BlockPalette.new()
	p.counted = counted
	p.use_gift_book(GiftStampBook.new())
	add_child_autofree(p)
	return p


func _buttons(p: BlockPalette) -> Array[Button]:
	var list: Array[Button] = []
	for b in p.find_child("BUILD", true, false).find_children("*", "Button", true, false):
		list.append(b as Button)
	return list


func _named(p: BlockPalette, id: int) -> Button:
	for b in _buttons(p):
		if b.tooltip_text == ItemIds.display_name(id):
			return b
	return null


func test_a_build_tab_with_the_tools_and_sixteen_paints() -> void:
	var p := _palette()
	assert_eq(p.tab_bar.get_tab_title(BlockPalette.BUILD_TAB), "BUILD")
	var names: Array[String] = []
	for b in _buttons(p):
		names.append(b.tooltip_text)
	var wanted: Array[int] = ItemIds.BUILD_TOOLS + ItemIds.PAINTS
	assert_eq(names.size(), wanted.size())
	for id in wanted:
		assert_eq(names.count(ItemIds.display_name(id)), 1, ItemIds.display_name(id))


func test_every_tool_and_paint_has_its_own_picture() -> void:
	var seen := {}
	for b in _buttons(_palette()):
		assert_not_null(b.icon, b.tooltip_text)
		assert_false(seen.has(b.icon), "its own picture: %s" % b.tooltip_text)
		seen[b.icon] = true
		assert_gte(b.custom_minimum_size.x, 76.0, "big enough for small fingers")
	var bucket := BuildToolIcons.image(ItemIds.PAINT_RED)
	assert_eq(bucket.get_pixel(5, 4), PaintRules.color(PaintRules.tint_of_item(ItemIds.PAINT_RED)), "red paint in the bucket")


func test_picking_a_paint_puts_it_in_the_hand() -> void:
	var p := _palette()
	var got: Array = []
	p.picked.connect(func(id: int) -> void: got.append(id))
	p.show_page(BlockPalette.BUILD_TAB)
	_named(p, ItemIds.PAINT_TEAL).pressed.emit()
	_named(p, ItemIds.FILL_TOOL).pressed.emit()
	assert_eq(got, [ItemIds.PAINT_TEAL, ItemIds.FILL_TOOL])


func test_survivor_paints_and_rewinds_but_the_power_tools_are_the_sandboxs() -> void:
	var p := _palette(true)
	p.open()
	assert_false(p.tab_bar.is_tab_hidden(BlockPalette.BUILD_TAB), "Survivor has the BUILD tab")
	p.show_page(BlockPalette.BUILD_TAB)
	for id in ItemIds.PAINTS + [ItemIds.REWIND]:
		assert_true(_named(p, id).is_visible_in_tree(), ItemIds.display_name(id))
	for id in [ItemIds.LINE_TOOL, ItemIds.FILL_TOOL, ItemIds.COPY_TOOL]:
		assert_false(_named(p, id).is_visible_in_tree(), "Sandbox only: %s" % ItemIds.display_name(id))
	p.counted = false
	p.open()
	p.show_page(BlockPalette.BUILD_TAB)
	for id in ItemIds.BUILD_TOOLS:
		assert_true(_named(p, id).is_visible_in_tree(), "Sandbox: %s" % ItemIds.display_name(id))


func test_the_palette_still_fits_above_the_hotbar() -> void:
	var p := _palette()
	var panel := p.find_children("*", "PanelContainer", false, false)[0] as PanelContainer
	p.show_page(BlockPalette.BUILD_TAB)
	var content := panel.get_combined_minimum_size()
	assert_lte(720.0 * 0.5 + panel.offset_bottom, HOTBAR_TOP, "above the hotbar")
	assert_lte(content.y, panel.offset_bottom - panel.offset_top + 0.5)
	assert_lte(content.x, panel.offset_right - panel.offset_left + 0.5)
