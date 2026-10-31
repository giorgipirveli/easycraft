extends GutTest
## M7, the browser's freezes (docs/devlog/parts/m7-freezes.md): every world switch built each hidden panel of the HUD at
## once, in one frame (the block palette ~330 nodes, the Secret Book with its tabs ~500): 3-4 s frozen in a phone's
## browser. The HUD's palette and book are built the first time they open; what they show then is what they showed
## before.

var _book_before := {}


func before_each() -> void:
	_book_before = Profile.data.secret_book.duplicate()


func after_each() -> void:
	Profile.data.secret_book = _book_before


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_secret_controls(null)
	return hud


func _buttons(c: Control) -> Array[String]:
	var out: Array[String] = []
	for b in c.find_children("*", "Button", true, false):
		out.append((b as Button).tooltip_text)
	out.sort()
	return out


func test_the_huds_palette_is_built_when_it_first_opens() -> void:
	var hud := _hud()
	assert_eq(_buttons(hud.palette).size(), 0, "nothing built while it waits hidden")
	hud.palette.open()
	assert_gt(_buttons(hud.palette).size(), 100, "every block, item and page once it opens")
	assert_true(hud.palette.visible)


func test_the_palette_opened_later_offers_what_one_built_at_once_does() -> void:
	var at_once := BlockPalette.new()
	add_child_autofree(at_once)
	var hud := _hud()
	hud.palette.open()
	assert_eq(_buttons(hud.palette), _buttons(at_once))


func test_the_huds_palette_shows_a_page_asked_for_before_it_ever_opened() -> void:
	var hud := _hud()
	hud.palette.show_page(BlockPalette.SMART_PAGE)
	assert_eq(hud.palette.tab_bar.current_tab, BlockPalette.SMART_PAGE)
	assert_gt(_buttons(hud.palette).size(), 100)


func test_the_huds_book_is_built_when_it_first_opens() -> void:
	var hud := _hud()
	assert_eq(hud.secret_book.find_children("*", "Label", true, false).size(), 0, "nothing built while it waits hidden")
	hud.secret_book.open()
	assert_true(hud.secret_book.visible)
	assert_eq(hud.secret_book.slot_texts().size(), SecretRules.KINDS.size() + 1, "the first page's slots")


func test_the_book_opened_later_shows_what_one_built_at_once_does() -> void:
	Profile.data.secret_book = {"temple": 2}
	var at_once := SecretBook.new()
	add_child_autofree(at_once)
	at_once.open()
	var book := _hud().secret_book
	book.open()
	assert_eq(book.page_count(), at_once.page_count())
	assert_eq(book.slot_texts(), at_once.slot_texts())
	assert_eq(book.title.text, at_once.title.text)


func test_the_huds_book_opens_on_a_tab_before_it_ever_opened() -> void:
	var book := _hud().secret_book
	book.open_tab(SecretBook.MEMORIES_TAB)
	assert_eq(book.tab, SecretBook.MEMORIES_TAB)
	assert_true(book.memory_page.is_visible_in_tree())
