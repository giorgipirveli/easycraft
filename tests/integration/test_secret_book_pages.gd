extends GutTest
## Owner feedback #42 (spec §12.16b): the Secret Book's second page, "Treasure Hunt", with a slot per kind of
## the treasure pack; until a kind is found its slot shows a picture riddle (where to look, a few words),
## then its own picture, name and count. Big page buttons ◀ ▶; the first page stays the M2 page.

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


func test_the_book_has_three_pages_and_opens_on_the_first() -> void:
	var book := _hud().secret_book
	book.open()
	assert_eq(book.page_count(), 6,
		"owner #45a added the keepsakes page; M3 Task 20b the buddy recipes and album; universe 6 the Cave Book")
	assert_eq(book.page, 0)
	assert_eq(book.slot_texts().size(), SecretRules.KINDS.size() + 1, "the M2 page first (M3 Task 21c: and the mouse village)")
	book.show_page(1)
	assert_eq(book.slot_texts().size(), TreasurePlaces.KINDS.size(), "a slot per kind of the treasure pack")
	assert_eq(book.title.text, "Treasure Hunt")
	book.show_page(2)
	assert_eq(book.title.text, "Keepsakes")
	assert_eq(book.slot_texts().size(), QuestRules.CHAINS.size(), "a shelf spot per story")


## Owner #45a (spec §14.17): every story done puts its keepsake on the Secret Book's shelf; the others wait
## as shadows that say whose story it is.
func test_the_keepsakes_page_shows_what_the_stories_gave() -> void:
	var d := ProgressData.new()
	d.quests.done.append("zara_scarab")
	Progress.begin(d)
	var book := _hud().secret_book
	book.open()
	book.show_page(2)
	var texts := book.slot_texts()
	Progress.end()
	for i in QuestRules.CHAINS.size():
		var c: Dictionary = QuestRules.CHAINS[i]
		if c.id == &"zara_scarab":
			assert_eq(texts[i], "A golden scarab")
		else:
			assert_eq(texts[i], "Ask %s" % QuestRules.giver(c.giver).name, String(c.id))


func test_unfound_kinds_show_a_picture_riddle() -> void:
	Profile.data.secret_book = {"shipwreck": 2}
	var book := _hud().secret_book
	book.show_page(1)
	var texts := book.slot_texts()
	for i in TreasurePlaces.KINDS.size():
		var kind := TreasurePlaces.KINDS[i]
		if kind == TreasurePlaces.SHIPWRECK:
			assert_eq(texts[i], "Shipwreck\n× 2")
			assert_eq(book.slot_picture(i), Pictures.texture(TreasureRules.SHIPWRECK_PICTURE))
		else:
			assert_eq(texts[i], TreasureRules.BOOK_RIDDLES[kind].text, String(kind))
			assert_eq(book.slot_picture(i), Pictures.texture(int(TreasureRules.BOOK_RIDDLES[kind].picture)),
				"a picture of where to look: %s" % kind)


func test_the_page_buttons_turn_the_pages_and_are_big() -> void:
	var hud := _hud()
	var book := hud.secret_book
	book.open()
	assert_gte(book.next_button.custom_minimum_size.x, 90.0, "big enough for small fingers")
	assert_gte(book.prev_button.custom_minimum_size.y, 90.0)
	assert_true(book.prev_button.disabled, "on the first page")
	book.next_button.pressed.emit()
	assert_eq(book.page, 1)
	book.next_button.pressed.emit()
	assert_eq(book.page, 2)
	book.next_button.pressed.emit()
	book.next_button.pressed.emit()   # M3 Task 20b: the buddy recipes and the album
	book.next_button.pressed.emit()   # universe 6: the Cave Book
	assert_eq(book.page, 5)
	assert_true(book.next_button.disabled, "on the last page")
	assert_eq(book.page_label.text, "6 / 6")
	for i in 5:
		book.prev_button.pressed.emit()
	assert_eq(book.page, 0)
	book.close()
	book.open()
	assert_eq(book.page, 0, "it opens on the first page again")


## The base screen is 1280 x 720 (the canvas stretches wider on phones): both pages fit on it.
func test_both_pages_fit_the_screen() -> void:
	var book := _hud().secret_book
	book.open()
	for i in book.page_count():
		book.show_page(i)
		var need := book.page_panel.get_combined_minimum_size()
		assert_lte(need.x, 1280.0, "page %d wide %d" % [i + 1, need.x])
		assert_lte(need.y, 700.0, "page %d tall %d" % [i + 1, need.y])


func test_taps_on_the_open_book_or_a_riddle_never_build_behind_them() -> void:
	var hud := _hud()
	var middle := hud.get_viewport().get_visible_rect().size * 0.5
	assert_false(hud.look_area._blocked(middle), "a closed book blocks nothing")
	hud.secret_book.open()
	assert_true(hud.look_area._blocked(middle), "the open book takes the tap")
	hud.secret_book.close()
	hud.riddle_panel.show_note("Hi", [])
	assert_true(hud.look_area._blocked(middle), "and a riddle")


func test_the_pack_kinds_are_saved_in_the_profile() -> void:
	Profile.data.secret_book = {}
	assert_eq(Profile.data.record_secret(TreasurePlaces.VAULT), 1)
	assert_eq(Profile.data.record_secret(&"nonsense"), 0)
	var back := ProfileData.from_json(Profile.data.to_json())
	assert_eq(int(back.secret_book.get("vault", 0)), 1, "account-wide, like the M2 kinds")


## M3 Task 21c: the mouse village's slot on the first page: a picture riddle (a tiny door in a hill) until one is
## found, then the mouse's picture, its name and the count; the book still fits the screen.
func test_the_mouse_village_has_a_slot_with_a_picture_riddle() -> void:
	Profile.data.secret_book.erase(String(MouseVillages.KIND))
	var book := _hud().secret_book
	book.open()
	var i := SecretRules.KINDS.size()
	assert_eq(book.slot_texts()[i], MouseVillages.BOOK_RIDDLE)
	assert_eq((book.slot_picture(i) as AtlasTexture).atlas, TinyPictures.atlas(), "the tiny door picture")
	Profile.data.secret_book[String(MouseVillages.KIND)] = 2
	book.refresh()
	assert_eq(book.slot_texts()[i], "%s\n× 2" % MouseVillages.NAME)
	assert_eq((book.slot_picture(i) as AtlasTexture).region.position, Vector2(0, 0), "the mouse's face")
	var need := book.page_panel.get_combined_minimum_size()
	assert_lte(need.y, 700.0, "the book fits the screen (%d)" % need.y)
