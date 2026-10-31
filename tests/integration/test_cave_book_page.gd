extends GutTest
## Universe 6, the Glow Caves: the Cave Book, the Secret Book's page for the caves' wonders and sights (owner #122:
## what a child found by playing is kept). A slot per page (GlowWonderRules.BOOK): its picture (a block of the place,
## dimmed until found), its name, and "???" until the child has found it; then its one-line fact. Account-wide (the
## profile's WonderData.caves).

const W := preload("res://core/rules/glow_wonder_rules.gd")

var _wonder: WonderData


func before_each() -> void:
	_wonder = Profile.data.wonder
	Profile.data.wonder = WonderData.new()


func after_each() -> void:
	Profile.data.wonder = _wonder


func _book() -> SecretBook:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_secret_controls(null)
	return hud.secret_book


func _cave_page(book: SecretBook) -> int:
	for i in book.page_count():
		book.show_page(i)
		if book.title.text == SecretBook.CAVE_TITLE:
			return i
	return -1


func test_the_cave_book_names_every_page_and_keeps_what_was_found() -> void:
	var book := _book()
	book.open()
	var page := _cave_page(book)
	assert_gt(page, 0, "a page of its own, after the Secret Book's first")
	var texts := book.slot_texts()
	assert_eq(texts.size(), W.BOOK.size())
	for i in W.BOOK.size():
		assert_true(texts[i].contains(W.name_of(W.BOOK[i])), "named: what to look for")
		assert_true(texts[i].contains("???"), "not found yet")
		assert_false(texts[i].contains(str(W.BOOK_LINES[W.BOOK[i]])), "no fact before the find")
		assert_not_null(book.slot_picture(i))
	Profile.data.wonder.find_cave(W.DRIP)
	book.show_page(page)
	texts = book.slot_texts()
	var drip := W.BOOK.find(W.DRIP)
	assert_true(texts[drip].contains(str(W.BOOK_LINES[W.DRIP])), "found: its fact")
	assert_false(texts[drip].contains("???"))
	assert_true(texts[0].contains("???"), "the others still to find")
	book.close()
	book.open()
	assert_eq(book.page, 0, "the book still opens on its first page")
