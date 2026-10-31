extends GutTest
## M3 Task 7: Sandbox's block palette has a SMART tab beside BLOCKS and ARMORY: a row of smart blocks and a
## row of Game Blocks, each block once with its picture, as big as the other pages' buttons; picking one puts
## it in the hotbar slot. The BLOCKS page keeps its size (the palette's fit tests stay green).


func _palette() -> BlockPalette:
	var p := BlockPalette.new()
	add_child_autofree(p)
	return p


func _smart(p: BlockPalette) -> Control:
	return p.find_child("SMART", true, false) as Control


func test_the_smart_tab_offers_every_smart_and_game_block_with_a_picture() -> void:
	var p := _palette()
	assert_false(_smart(p).visible, "blocks first")
	p.tab_bar.current_tab = 2                 # a tap on SMART
	assert_true(_smart(p).visible)
	assert_false(p.find_child("BLOCKS", true, false).visible)
	var names: Array[String] = []
	for b in _smart(p).find_children("*", "Button", true, false):
		var button := b as Button
		names.append(button.tooltip_text)
		assert_not_null(button.icon, "%s has its picture" % button.tooltip_text)
		assert_gte(button.custom_minimum_size.x, 80.0, "big enough for small fingers")
	for id: int in SmartPage.SMART_ROW + SmartPage.GAME_ROW:
		assert_eq(names.count(ItemIds.display_name(id)), 1, ItemIds.display_name(id))
	assert_eq(names.size(), SmartPage.SMART_ROW.size() + SmartPage.GAME_ROW.size()
		+ 1 + CrystalRules.sandbox_crystals(Profile.data.universe_unlocked).size()   # owner 39: PORTALS (a frame, crystals)
		+ BlockPalette.HOME_BLOCKS.size()   # M3 Task 21b: HOME (the shelves)
		+ RocketPage.SPACE_ROW.size())   # spec §21d: SPACE (the rocket parts)


func test_its_rows_have_words() -> void:
	var p := _palette()
	var words: Array[String] = []
	for l in _smart(p).find_children("*", "Label", true, false):
		words.append((l as Label).text)
	assert_has(words, "SMART")
	assert_has(words, "GAME")
	assert_has(words, "PORTALS")   # owner 39
	assert_has(words, "SPACE")   # spec §21d: the rocket parts


func test_picking_a_start_block_puts_it_in_the_hand() -> void:
	var p := _palette()
	p.open()
	p.show_page(2)
	watch_signals(p)
	for b in _smart(p).find_children("*", "Button", true, false):
		if (b as Button).tooltip_text == ItemIds.display_name(BlockIds.START):
			(b as Button).pressed.emit()
	assert_signal_emitted_with_parameters(p, "picked", [BlockIds.START])
	assert_false(p.visible)
