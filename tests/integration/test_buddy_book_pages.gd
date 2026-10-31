extends GutTest
## The Secret Book's buddy pages (M3 Task 20b, spec §14.21): "Buddy Recipes" (a slot per secret buddy shape: its
## silhouette and a picture riddle until found, then its picture in colour and its name) and "Buddy Album" (every
## buddy this child woke: its picture, name, where and when; the newest first; the older ones as a count). Both fit
## the screen, and the book still opens on its first page.

var _magic: BuddyMagicData


func before_each() -> void:
	_magic = Profile.data.buddy_magic
	Profile.data.buddy_magic = BuddyMagicData.new()


func after_each() -> void:
	Profile.data.buddy_magic = _magic


func _book() -> SecretBook:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_secret_controls(null)
	return hud.secret_book


func _page(book: SecretBook, title: String) -> int:
	for i in book.page_count():
		book.show_page(i)
		if book.title.text == title:
			return i
	return -1


func test_the_book_has_a_buddy_recipes_page_and_a_buddy_album() -> void:
	var book := _book()
	assert_eq(book.page_count(), 6, "the M2 page, the treasure hunt, the keepsakes, buddy magic's two, then the Cave Book")
	assert_eq(_page(book, SecretBook.RECIPES_TITLE), 3)
	assert_eq(_page(book, SecretBook.ALBUM_TITLE), 4)
	book.close()
	book.open()
	assert_eq(book.page, 0, "it still opens on the first page")


func test_unfound_recipes_show_a_silhouette_and_a_riddle() -> void:
	var book := _book()
	book.show_page(_page(book, SecretBook.RECIPES_TITLE))
	var texts := book.slot_texts()
	assert_eq(texts.size(), BuddyRecipes.RECIPES.size(), "a slot per secret shape")
	for i in BuddyRecipes.RECIPES.size():
		var r: Dictionary = BuddyRecipes.RECIPES[i]
		assert_eq(texts[i], r.hint, str(r.id))
		var pic := book.recipe_picture(i)
		assert_true(pic.shadow, "%s: a silhouette until found" % r.id)
		assert_eq(pic.cells.size(), pic.w * pic.h)
		assert_eq(Vector2i(pic.w, pic.h), Vector2i(BuddyRecipes.silhouette(r.id).w, BuddyRecipes.silhouette(r.id).h))


func test_a_found_recipe_shows_its_picture_and_name() -> void:
	Profile.data.buddy_magic.add_found(&"castle")
	var book := _book()
	book.show_page(_page(book, SecretBook.RECIPES_TITLE))
	var i := BuddyRecipes.RECIPES.find(BuddyRecipes.recipe(&"castle"))
	assert_eq(book.slot_texts()[i], "Singing Castle")
	var pic := book.recipe_picture(i)
	assert_false(pic.shadow)
	assert_true(pic.cells.has(BuddyRecipes.block_of(BuddyRecipes.WALL)), "in its blocks' colours")
	assert_string_contains(book.recipes_line.text, "1 of %d" % BuddyRecipes.RECIPES.size())


func test_the_album_shows_every_buddy_newest_first() -> void:
	var m := Profile.data.buddy_magic
	m.add_album("Bobble", &"", BuddyPicture.code_of({Vector3i.ZERO: BlockIds.RED}), 1, 1790000000)
	m.add_album("Frosty", &"snowman", "", 3, 1790100000)
	var book := _book()
	book.show_page(_page(book, SecretBook.ALBUM_TITLE))
	var cards := book.album_cards()
	assert_eq(cards.size(), 2)
	assert_string_contains(cards[0], "Frosty", "the newest first")
	assert_string_contains(cards[0], "Frostpeak", "where")
	assert_string_contains(cards[1], "Bobble")
	assert_string_contains(cards[1], "Green Meadows")
	assert_eq(book.album_picture(1).cells, PackedInt32Array([BlockIds.RED]), "its picture from its blocks")


func test_an_empty_album_says_how_to_fill_it_and_a_full_one_counts_the_older() -> void:
	var book := _book()
	book.show_page(_page(book, SecretBook.ALBUM_TITLE))
	assert_eq(book.album_cards().size(), 0)
	assert_string_contains(book.album_line.text, "wand")
	var m := Profile.data.buddy_magic
	for i in BuddyMagicData.ALBUM_MAX + 3:
		m.add_album("B%d" % i, &"", "", 1, 1000 + i)
	book.refresh()
	assert_eq(book.album_cards().size(), BuddyMagicData.ALBUM_MAX)
	assert_string_contains(book.album_line.text, "3 older")


func test_the_buddy_pages_fit_the_screen() -> void:
	var m := Profile.data.buddy_magic
	for i in BuddyMagicData.ALBUM_MAX:
		m.add_album("Buddy number %d" % i, &"", "", 5, 1790000000 + i)
	for r: Dictionary in BuddyRecipes.RECIPES:
		m.add_found(r.id)
	var book := _book()
	book.open()
	for i in book.page_count():
		book.show_page(i)
		var need := book.page_panel.get_combined_minimum_size()
		assert_lte(need.x, 1280.0, "page %d wide %d" % [i + 1, need.x])
		assert_lte(need.y, 700.0, "page %d tall %d" % [i + 1, need.y])
