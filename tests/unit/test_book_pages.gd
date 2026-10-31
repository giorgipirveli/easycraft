extends GutTest
## M3 Task 21b (research C4): completing a Secret Book page — every kind on it found — gives a fixed reward
## once: a sticker and an avatar item (AvatarUnlocks.earn), and an ornament on the Hub Tree. Never random.


func _profile_with_all_secrets() -> ProfileData:
	var p := ProfileData.new()
	for kind in SecretRules.KINDS:
		p.secret_book[String(kind)] = 1
	return p


func test_a_page_is_done_when_every_kind_on_it_was_found() -> void:
	var p := ProfileData.new()
	var d := ProgressData.new()
	assert_false(BookPages.complete(BookPages.SECRETS, p, d))
	assert_eq(BookPages.progress_of(BookPages.SECRETS, p, d), Vector2i(0, SecretRules.KINDS.size()))
	p = _profile_with_all_secrets()
	p.secret_book.erase(String(SecretRules.KINDS[0]))
	assert_false(BookPages.complete(BookPages.SECRETS, p, d), "one still missing")
	p.secret_book[String(SecretRules.KINDS[0])] = 3
	assert_true(BookPages.complete(BookPages.SECRETS, p, d))
	for kind in TreasurePlaces.KINDS:
		p.secret_book[String(kind)] = 1
	assert_true(BookPages.complete(BookPages.TREASURE, p, d))
	assert_false(BookPages.complete(BookPages.KEEPSAKES, p, d))
	for c: Dictionary in QuestRules.CHAINS:
		d.quests.done.append(String(c.id))
	assert_true(BookPages.complete(BookPages.KEEPSAKES, p, d))


func test_the_reward_comes_once() -> void:
	var p := _profile_with_all_secrets()
	var got := BookPages.claim(p, p.progress, p.wonder)
	assert_eq(got.size(), 1)
	assert_eq(got[0].page, BookPages.SECRETS)
	assert_has(got[0].items, "wings.fairy", "the Fairy Wings (AvatarCatalog.EARN_SECRET_PAGE)")
	assert_true(AvatarUnlocks.is_owned("wings.fairy", p.cosmetics))
	assert_eq(int(p.progress.stickers.get("page_secrets", 0)), 1, "its sticker")
	assert_eq(p.wonder.pages, [BookPages.SECRETS] as Array[String], "its ornament on the Hub Tree")
	assert_eq(BookPages.claim(p, p.progress, p.wonder), [] as Array[Dictionary], "never twice")
	assert_eq(int(p.progress.stickers.get("page_secrets", 0)), 1)
	var back := ProfileData.from_json(p.to_json())
	assert_eq(BookPages.claim(back, back.progress, back.wonder), [] as Array[Dictionary], "not after a reload either")


func test_every_page_has_its_own_fixed_reward() -> void:
	var events: Array[StringName] = []
	for page: Dictionary in BookPages.PAGES:
		assert_false(events.has(page.earn), "one item per page")
		events.append(page.earn)
		var items: Array[String] = []
		for id: String in AvatarCatalog.ITEMS:
			if AvatarCatalog.ITEMS[id].get("earn", &"") == page.earn:
				items.append(id)
		assert_gte(items.size(), 1, "page %s gives an avatar item" % page.id)
		for id in items:   # owner #36: the first page's event gives the Fairy costume too (a whole look, not a part)
			assert_true(AvatarCatalog.slot_of(id) == &"costume" or AvatarParts.has_part("%s_%s" % [AvatarCatalog.slot_of(id),
				AvatarCatalog.name_of(id)]), "it can be worn: %s" % id)
			assert_ne(AvatarCatalog.ITEMS[id].kind, AvatarCatalog.GOLD, "earned, never bought: %s" % id)
		assert_true(ProgressData.is_sticker(page.sticker), "its sticker is a real sticker")
		assert_true(AvatarCatalog.EARN_REASONS.has(page.earn), "the editor says how to earn it")
		assert_true(ProgressPictures.knows(page.picture))


func test_all_three_pages_at_once() -> void:
	var p := _profile_with_all_secrets()
	for kind in TreasurePlaces.KINDS:
		p.secret_book[String(kind)] = 1
	for c: Dictionary in QuestRules.CHAINS:
		p.progress.quests.done.append(String(c.id))
	var got := BookPages.claim(p, p.progress, p.wonder)
	assert_eq(got.size(), 3)
	assert_eq(p.wonder.pages, [BookPages.SECRETS, BookPages.TREASURE, BookPages.KEEPSAKES] as Array[String])
	for g: Dictionary in got:
		assert_ne(BookPages.reward_words(g), "")


func test_page_stickers_are_kept_like_the_others() -> void:
	var d := ProgressData.new()
	d.add_sticker("page_treasure")
	var back := ProgressData.from_dict(d.to_dict())
	assert_eq(int(back.stickers.get("page_treasure", 0)), 1)
