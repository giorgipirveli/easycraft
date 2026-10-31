extends GutTest
## M3 Task 14a: the gadgets are free in the Sandbox palette's ARMORY page (a GADGETS column right of the
## tier rows: the glider, the hook, the orbs, the quick builds, the zipline post and the launch pad), each
## with its own picture; in Survivor the palette lists the ones the player owns, orbs with their count.

const SCREEN := Vector2(1280, 720)

var inv: Inventory
var _inv_before: Inventory


func before_each() -> void:
	_inv_before = Session.my_inventory
	inv = Inventory.new()
	Session.my_inventory = inv


func after_each() -> void:
	Session.my_inventory = _inv_before


func _palette(counted := false) -> BlockPalette:
	var p := BlockPalette.new()
	p.counted = counted
	add_child_autofree(p)
	return p


func _gadget_buttons(p: BlockPalette) -> Array[Button]:
	var list: Array[Button] = []
	for b in p.find_child("GADGETS", true, false).find_children("*", "Button", true, false):
		list.append(b as Button)
	return list


func test_the_armory_page_has_a_gadgets_column_with_everything_once() -> void:
	var p := _palette()
	var names: Array[String] = []
	for b in _gadget_buttons(p):
		names.append(b.tooltip_text)
	var wanted: Array[int] = ItemIds.GADGETS + BlockPalette.GADGET_BLOCKS
	assert_eq(names.size(), wanted.size())
	for id in wanted:
		assert_eq(names.count(ItemIds.display_name(id)), 1, ItemIds.display_name(id))
	var column := p.find_child("GADGETS", true, false) as Control
	assert_eq(column.get_parent(), p.find_child("ARMORY", true, false), "on the ARMORY page")
	assert_eq((column.get_child(0) as Label).text, "GADGETS")


func test_every_gadget_has_its_own_picture_and_a_golden_rim() -> void:
	var seen := {}
	for b in _gadget_buttons(_palette()):
		assert_not_null(b.icon, b.tooltip_text)
		assert_false(seen.has(b.icon), "its own picture: %s" % b.tooltip_text)
		seen[b.icon] = true
		assert_eq((b.get_theme_stylebox("normal") as StyleBoxFlat).border_color, BlockPalette.GADGET_COLOR)
		assert_gte(b.custom_minimum_size.x, 76.0, "big enough for small fingers")


func test_gadget_pictures_are_drawn() -> void:
	for id in ItemIds.GADGETS:
		var img := GadgetIcons.image(id)
		var filled := 0
		for y in 16:
			for x in 16:
				if img.get_pixel(x, y).a > 0.5:
					filled += 1
		assert_gt(filled, 30, ItemIds.display_name(id))


func test_picking_a_glider_puts_it_in_the_hotbar_slot() -> void:
	var p := _palette()
	watch_signals(p)
	for b in _gadget_buttons(p):
		if b.tooltip_text == "Glider":
			b.pressed.emit()
	assert_signal_emitted_with_parameters(p, "picked", [ItemIds.GLIDER])
	var pads := _palette()
	watch_signals(pads)
	for b in _gadget_buttons(pads):
		if b.tooltip_text == "Zipline Post":
			b.pressed.emit()
	assert_signal_emitted_with_parameters(pads, "picked", [BlockIds.ZIPLINE_POST])


func test_the_armory_page_still_fits_above_the_hotbar() -> void:
	var p := _palette()
	var panel := p.find_children("*", "PanelContainer", false, false)[0] as PanelContainer
	p.show_page(1)
	var need := panel.get_combined_minimum_size()
	assert_lte(need.x, panel.offset_right - panel.offset_left + 0.5)
	assert_lte(need.y, panel.offset_bottom - panel.offset_top + 0.5)
	assert_lte(panel.offset_right - panel.offset_left, SCREEN.x)
	assert_lte(SCREEN.y * 0.5 + panel.offset_bottom, SCREEN.y - 78.0)


func test_survivor_lists_the_gadgets_the_player_owns_with_orb_counts() -> void:
	inv.add(ItemIds.GRAPPLE, 1)
	inv.add(ItemIds.DANCE_ORB, 3)
	inv.add(BlockIds.ZIPLINE_POST, 2)
	var p := _palette(true)
	p.open()
	assert_eq(p.count_text(ItemIds.DANCE_ORB), "3")
	assert_eq(p.count_text(ItemIds.GRAPPLE), "", "one hook needs no number")
	assert_eq(p.count_text(BlockIds.ZIPLINE_POST), "2")
