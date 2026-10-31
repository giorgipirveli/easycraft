extends GutTest
## The palette's GIFTS page (M4 Wave 3, agent I): friends' builds as stamps, each with who sent it;
## picking one puts it in the hotbar slot like the M1 stamps; the small x deletes one after SURE?; in
## Survivor the tabs are BLOCKS and GIFTS only; the page keeps the palette's size.


func _cube(n: int, id: int = BlockIds.PLANKS) -> String:
	var b := {}
	for x in n:
		for y in n:
			for z in n:
				b[Vector3i(x, y, z)] = id
	return BuildCodec.encode(b)


func _palette(book: GiftStampBook) -> BlockPalette:
	var p := BlockPalette.new()
	p.use_gift_book(book)
	add_child_autofree(p)
	return p


func test_the_gifts_tab_lists_every_gift_stamp_with_its_sender() -> void:
	var book := GiftStampBook.new()
	book.add(_cube(2), "Mia_2", "uid-mia")
	book.add(_cube(3, BlockIds.BRICK), "Pip_7", "uid-pip")
	var p := _palette(book)
	assert_eq(p.tab_bar.get_tab_title(BlockPalette.GIFTS_TAB), "GIFTS")
	p.open()
	p.show_page(BlockPalette.GIFTS_TAB)
	await wait_process_frames(2)
	assert_eq(p.gifts_grid.get_child_count(), 2)
	var first := p.gifts_grid.get_child(0)
	assert_eq((first.find_child("Pick", true, false) as Button).tooltip_text, "Gift from Mia_2")
	assert_not_null((first.find_child("Pick", true, false) as Button).icon, "a gift box")
	var who := first.find_children("*", "Label", true, false)
	assert_eq((who[0] as Label).text, "Mia_2")
	watch_signals(p)
	(first.find_child("Pick", true, false) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(p, "picked", [GiftStampBook.item_of(0)])


func test_the_small_x_asks_then_deletes() -> void:
	var book := GiftStampBook.new()
	book.add(_cube(2), "Mia_2", "uid-mia")
	var p := _palette(book)
	p.open()
	var x := p.gifts_grid.get_child(0).find_child("Delete", true, false) as Button
	x.pressed.emit()
	assert_eq(x.text, "SURE?", "one tap asks")
	assert_eq(book.slots(), [0] as Array[int])
	x.pressed.emit()
	assert_eq(book.slots(), [] as Array[int])
	assert_eq(p.gifts_grid.get_child_count(), 0)


func test_no_gift_stamps_a_hint_says_where_they_come_from() -> void:
	var p := _palette(GiftStampBook.new())
	p.open()
	p.show_page(BlockPalette.GIFTS_TAB)
	var hints := p.find_children("*", "Label", true, false).filter(func(l: Label) -> bool:
		return l.is_visible_in_tree() and l.text.contains("PRESENTS"))
	assert_eq(hints.size(), 1)


func test_survivor_shows_blocks_craft_build_and_gifts_only() -> void:
	var book := GiftStampBook.new()
	var p := _palette(book)
	p.counted = true
	p.open()
	assert_true(p.tab_bar.visible, "Survivor always has CRAFT (spec §12.19), so the tabs show")
	for i in p.tab_bar.tab_count:
		assert_eq(p.tab_bar.is_tab_hidden(i), i != 0 and i != BlockPalette.CRAFT_PAGE and i != BlockPalette.BUILD_TAB
			and i != BlockPalette.STAMPS_TAB,
			"no gift stamps: " + p.tab_bar.get_tab_title(i))   # M3 Task 8: BUILD (paint) in Survivor too; M3 Task 20b: STAMPS
	book.add(_cube(2), "Mia_2", "uid-mia")
	p.open()
	for i in p.tab_bar.tab_count:
		assert_eq(p.tab_bar.is_tab_hidden(i), i != 0 and i != BlockPalette.CRAFT_PAGE and i != BlockPalette.GIFTS_TAB
			and i != BlockPalette.BUILD_TAB and i != BlockPalette.STAMPS_TAB, p.tab_bar.get_tab_title(i))
	p.counted = false
	p.open()
	for i in p.tab_bar.tab_count:
		assert_eq(p.tab_bar.is_tab_hidden(i), i == BlockPalette.CRAFT_PAGE, "Sandbox: " + p.tab_bar.get_tab_title(i))


func test_twenty_stamps_still_fit_the_palette() -> void:
	var book := GiftStampBook.new()
	for i in GiftStampBook.SLOTS:
		book.add(_cube(1 + i % 4), "Mia_2", "uid-mia")
	var p := _palette(book)
	var panel := p.find_children("*", "PanelContainer", false, false)[0] as PanelContainer
	var before := panel.get_combined_minimum_size()
	p.open()
	p.show_page(BlockPalette.GIFTS_TAB)
	await wait_process_frames(2)
	assert_eq(p.gifts_grid.get_child_count(), 20)
	assert_eq(panel.get_combined_minimum_size(), before, "the page scrolls; the palette keeps its size")
