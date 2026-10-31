extends GutTest
## M3 Task 21b: the BOOK button opens one book with picture tabs — SECRETS (the Secret Book), ANIMALS (the Animal
## Book), MEMORIES (the Memory Book), IDEAS (idea cards), SAVING (the saving list) and, owner #72/#74 (spec §21b.2),
## SPACE (the Space Book: every body of the Star Map). No new HUD button; every tab
## fits the 1280 × 720 screen; each page shows what the child did.

var DIR := "user://test_books_tabs_%d/" % OS.get_process_id()
var _wonder_before: WonderData
var _gold_before := 0
var _owned_before: Array[String] = []


func before_each() -> void:
	_wonder_before = Profile.data.wonder
	_gold_before = Profile.data.survivor_gold
	Profile.data.wonder = WonderData.new()
	_owned_before = Profile.data.cosmetics.duplicate()
	Profile.data.cosmetics = [] as Array[String]   # another test may have given the shared profile a crown
	MemoryBook.use(MemoryBook.new(), DIR.path_join("memories.json"))


func after_each() -> void:
	Profile.data.wonder = _wonder_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.cosmetics = _owned_before
	MemoryBook.use(null)


func after_all() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)


func _book() -> SecretBook:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_secret_controls(null)
	return hud.secret_book


func test_the_book_opens_on_the_secrets_and_has_eight_big_tabs() -> void:
	var book := _book()
	book.open()
	assert_eq(book.tab, SecretBook.SECRETS_TAB)
	assert_eq(book.page, 0)
	assert_eq(book.tab_buttons.size(), 8, "spec §23 added the LAB tab, owner #78 the WONDERS tab")
	for t: StringName in SecretBook.TABS:
		var b: Button = book.tab_buttons[t]
		assert_gte(b.custom_minimum_size.y, 64.0, "big enough for small fingers")
		assert_gte(b.custom_minimum_size.x, 100.0)
	book.show_tab(SecretBook.ANIMALS_TAB)
	book.close()
	book.open()
	assert_eq(book.tab, SecretBook.SECRETS_TAB, "it opens on the Secret Book again")


func test_each_tab_shows_its_own_page() -> void:
	var book := _book()
	book.open()
	var pages := {SecretBook.ANIMALS_TAB: book.animal_page, SecretBook.MEMORIES_TAB: book.memory_page,
		SecretBook.IDEAS_TAB: book.idea_page, SecretBook.SAVING_TAB: book.saving_page, SecretBook.SPACE_TAB: book.space_page}
	for t: StringName in pages:
		(book.tab_buttons[t] as Button).pressed.emit()
		assert_eq(book.tab, t)
		for other: StringName in pages:
			assert_eq((pages[other] as Control).visible, other == t, "%s on %s" % [other, t])
		assert_false(book.title.is_visible_in_tree(), "the Secret Book's pages hide on %s" % t)
	(book.tab_buttons[SecretBook.SECRETS_TAB] as Button).pressed.emit()
	assert_true(book.title.is_visible_in_tree())


func test_every_tab_fits_the_screen() -> void:
	Profile.data.wonder.saving.clear()
	for id in ["hat.crown", "wings.bat", "cape.royal", "outfit.knight", "trail.rainbow", "hat.top_hat"]:
		SavingRules.toggle(Profile.data.wonder, SavingRules.LOOK, id)
	for i in 8:
		MemoryBook.current().add(MemoryRules.MOMENTS[i].id, "2026-09-25", 100 + i)
	var book := _book()
	book.open()
	for t: StringName in SecretBook.TABS:
		book.show_tab(t)
		var pages := book.page_count() if t == SecretBook.SECRETS_TAB else 1
		for i in pages:
			if t == SecretBook.SECRETS_TAB:
				book.show_page(i)
			var need := book.page_panel.get_combined_minimum_size()
			assert_lte(need.x, 1280.0, "%s %d wide %d" % [t, i, need.x])
			assert_lte(need.y, 700.0, "%s %d tall %d" % [t, i, need.y])
	book.show_tab(SecretBook.ANIMALS_TAB)
	book.animal_page.open_card(&"dog")
	var need := book.page_panel.get_combined_minimum_size()
	assert_lte(need.y, 700.0, "an animal's card, %d tall" % need.y)


## Owner #72/#74 (spec §21b.2): the Space Book. A tile for every body of the Star Map: its picture and name once its
## card was opened in space, "???" and a shadow until then, a flag once the child landed there; a tap opens its card
## with its three facts (or where to find it).
func test_the_space_book_shows_what_the_child_saw_and_landed_on() -> void:
	Profile.data.wonder.see_body(&"jupiter")
	Profile.data.wonder.land_on_world(SpaceRules.MOON)
	var book := _book()
	book.open()
	book.show_tab(SecretBook.SPACE_TAB)
	var page := book.space_page
	var ids: Array[StringName] = []
	for b: Dictionary in StarMap.bodies():
		ids.append(b.id)
	assert_eq(page.tiles().size(), ids.size(), "a tile for every body of the Star Map")
	var jupiter := ids.find(&"jupiter")
	var moon := ids.find(&"moon")
	var pluto := ids.find(&"pluto")
	assert_eq(page.tile_words(jupiter), "Jupiter")
	assert_false(page.tile_dim(jupiter))
	assert_false(page.tile_flag(jupiter), "seen, not landed on")
	assert_true(page.tile_flag(moon), "landed on the Moon")
	assert_eq(page.tile_words(pluto), "???")
	assert_true(page.tile_dim(pluto))
	assert_eq(page.count_label.text, SpaceBookRules.count_words(Profile.data.wonder))
	page.open_card(&"jupiter")
	assert_eq(page.detail_name.text, "Jupiter")
	assert_eq(page.detail_facts.text.count("•"), 3, "its three facts")
	page.open_card(&"pluto")
	assert_eq(page.detail_name.text, "???")
	assert_string_contains(page.detail_facts.text, "Fly up to space")
	var need := book.page_panel.get_combined_minimum_size()
	assert_lte(need.y, 700.0, "a body's card, %d tall" % need.y)
	page.close_card()


func test_the_animal_book_shows_what_the_child_met() -> void:
	AnimalBookRules.record(Profile.data.wonder, &"cow", WonderData.MET)
	AnimalBookRules.record(Profile.data.wonder, &"dog", WonderData.FRIEND)
	var book := _book()
	book.open()
	book.show_tab(SecretBook.ANIMALS_TAB)
	var page := book.animal_page
	var kinds := AnimalBookRules.species()
	assert_eq(page.tiles().size(), kinds.size(), "a tile for every kind in the species table")
	var cow := kinds.find(&"cow")
	var pig := kinds.find(&"pig")
	assert_eq(page.tile_words(cow), "Cow")
	assert_false(page.tile_dim(cow))
	assert_eq(page.tile_words(pig), "???", "a pig not met yet")
	assert_true(page.tile_dim(pig), "a silhouette")
	assert_eq(page.count_label.text, "2 of %d animals" % kinds.size())
	page.tiles()[kinds.find(&"dog")].pressed.emit()
	assert_eq(page.shown_species, &"dog")
	assert_eq(page.detail_fact.text, AnimalBookRules.fact_of(&"dog"))
	assert_string_contains(page.detail_marks.text, "Your pet ✓")
	page.back_button.pressed.emit()
	assert_eq(page.shown_species, &"")
	page.open_card(&"pig")
	assert_eq(page.detail_name.text, "???")
	assert_ne(page.detail_fact.text, AnimalBookRules.fact_of(&"pig"), "the fact waits until it is met")


func test_the_memory_book_shows_the_newest_moments_with_their_dates_and_photos() -> void:
	var b := MemoryBook.current()
	b.add(&"first_buddy", "2026-09-24", 100)
	b.add(&"boss_golem", "2026-09-25", 200)
	var img := Image.create_empty(32, 18, false, Image.FORMAT_RGB8)
	img.fill(Color.ORANGE)
	DirAccess.make_dir_recursive_absolute(DIR)
	img.save_png(DIR.path_join("boss_golem.png"))
	b.attach_photo(&"boss_golem", "boss_golem.png")
	var book := _book()
	book.open_tab(SecretBook.MEMORIES_TAB)
	var shown := book.memory_page.shown()
	assert_eq(shown.size(), 2)
	assert_eq(shown[0].words, "We beat the Stone Golem!", "newest first")
	assert_eq(shown[0].date, "25 Sep 2026")
	assert_true(shown[0].photo, "the child's photo")
	assert_false(shown[1].photo, "no photo: the moment's picture")
	assert_false(book.memory_page.empty_label.visible)


func test_an_empty_memory_book_says_what_will_come() -> void:
	var book := _book()
	book.open_tab(SecretBook.MEMORIES_TAB)
	assert_true(book.memory_page.empty_label.visible)
	assert_eq(book.memory_page.shown().size(), 0)


func test_idea_cards_flip_round() -> void:
	var book := _book()
	book.open_tab(SecretBook.IDEAS_TAB)
	var page := book.idea_page
	assert_eq(page.words.text, str(IdeaCards.card(0).words))
	page.next_button.pressed.emit()
	assert_eq(page.words.text, str(IdeaCards.card(1).words))
	page.prev_button.pressed.emit()
	page.prev_button.pressed.emit()
	assert_eq(page.words.text, str(IdeaCards.card(IdeaCards.count() - 1).words), "round and round")
	assert_eq(page.count_label.text, "%d / %d" % [IdeaCards.count(), IdeaCards.count()])


func test_the_saving_page_shows_bars_and_takes_things_off() -> void:
	Profile.data.survivor_gold = 100
	SavingRules.toggle(Profile.data.wonder, SavingRules.LOOK, "hat.crown")
	SavingRules.toggle(Profile.data.wonder, SavingRules.SHOP, str(ItemIds.SWORD_IRON))
	var book := _book()
	book.saving_page.universe = func() -> int: return 1
	book.open_tab(SecretBook.SAVING_TAB)
	var rows := book.saving_page.rows()
	assert_eq(rows.size(), 2)
	assert_eq(rows[0].bar, "100 / %d" % AvatarCatalog.price("hat.crown"))
	assert_eq(rows[1].bar, SavingRules.bar_words(Vector2i(mini(100, ShopRules.price(ItemIds.SWORD_IRON)),
		ShopRules.price(ItemIds.SWORD_IRON))))
	(rows[0].remove as Button).pressed.emit()
	assert_false(SavingRules.has(Profile.data.wonder, SavingRules.LOOK, "hat.crown"), "the child's choice")
	assert_eq(book.saving_page.rows().size(), 1)
	for b in book.find_children("*", "Button", true, false):
		assert_false(str((b as Button).text).to_upper().contains("BUY"), "nothing here buys")


## M3 Task 21a: every page of the books has a speaker beside its title (hidden where there is no voice).
func test_every_page_can_be_read_aloud() -> void:
	var book := _book()
	book.open()   # M7: the HUD's book is built when it first opens
	for page: Control in [book.animal_page, book.memory_page, book.idea_page, book.saving_page]:
		var speakers := page.find_children("ReadAloud", "Button", true, false)
		assert_eq(speakers.size(), 1, "%s has its speaker" % page.get_class())


func test_no_page_of_the_book_counts_down() -> void:
	var book := _book()
	book.open()
	for t: StringName in SecretBook.TABS:
		book.show_tab(t)
	assert_eq(book.find_children("*", "Timer", true, false).size(), 0, "no timers anywhere in the book")
