extends GutTest
## M3 Task 21b: the books' part of the profile (WonderData, ProfileData.wonder): the Animal Book's entries,
## the saving list, the Secret Book pages rewarded and the universes explored (the Hub Tree). Saved in the
## profile, parsed field by field, old profiles load, the server backup never loses any of it, and nothing in
## it has a date or a clock.


func test_a_new_profile_has_empty_books() -> void:
	var p := ProfileData.new()
	assert_true(p.wonder.is_empty())
	assert_eq(p.wonder.animals, {})
	assert_eq(p.wonder.saving, [] as Array[Dictionary])
	assert_eq(p.wonder.pages, [] as Array[String])
	assert_eq(p.wonder.universes, [] as Array[int])


func test_the_books_are_saved_in_the_profile() -> void:
	var p := ProfileData.new()
	AnimalBookRules.record(p.wonder, &"dog", WonderData.FED)
	SavingRules.toggle(p.wonder, SavingRules.LOOK, "hat.crown")
	SavingRules.toggle(p.wonder, SavingRules.SHOP, str(ItemIds.SWORD_STONE))
	p.wonder.pages.append(BookPages.SECRETS)
	assert_true(p.wonder.explore(3))
	var back := ProfileData.from_json(p.to_json())
	assert_eq(AnimalBookRules.flags(back.wonder, &"dog"), WonderData.MET | WonderData.FED)
	assert_true(SavingRules.has(back.wonder, SavingRules.LOOK, "hat.crown"))
	assert_true(SavingRules.has(back.wonder, SavingRules.SHOP, str(ItemIds.SWORD_STONE)))
	assert_eq(back.wonder.pages, [BookPages.SECRETS] as Array[String])
	assert_eq(back.wonder.universes, [3] as Array[int])


func test_an_old_profile_without_books_loads() -> void:
	var p := ProfileData.from_json("{\"version\": 1, \"username\": \"Mia\", \"survivor_gold\": 40}")
	assert_eq(p.username, "Mia")
	assert_true(p.wonder.is_empty())


func test_broken_book_data_falls_back_field_by_field() -> void:
	var w := WonderData.from_dict({"animals": {"dog": 3, "unicorn": 1, "cat": "lots", "cow": 99, "pig": -1},
		"saving": [{"kind": "look", "id": "hat.crown"}, {"kind": "look", "id": "hat.cap"}, "x",
			{"kind": "shop", "id": 131.0}, {"kind": "moon", "id": "1"}],
		"pages": ["secrets", "secrets", "nope", 4], "universes": [2, 2, 0, -3, 999, "5", 5.0]})
	assert_eq(w.animals, {"dog": 3}, "known kinds with good marks only")
	assert_eq(w.saving.size(), 2, "the free cap and the broken rows go")
	assert_true(SavingRules.has(w, SavingRules.SHOP, "131"), "a JSON number is read back as the item")
	assert_eq(w.pages, ["secrets"] as Array[String])
	assert_eq(w.universes, [2, 5] as Array[int])
	for bad: Variant in [null, 3, "x", []]:
		assert_true(WonderData.from_dict(bad).is_empty())


func test_nothing_in_the_books_has_a_date_or_a_clock() -> void:
	var p := ProfileData.new()
	AnimalBookRules.record(p.wonder, &"cat", WonderData.FRIEND)
	SavingRules.toggle(p.wonder, SavingRules.LOOK, "hat.crown")
	p.wonder.explore(2)
	var text := JSON.stringify(p.wonder.to_dict()).to_lower()
	for word in ["date", "time", "day", "expire", "deadline", "streak", "until", "left"]:
		assert_false(text.contains(word), "no '%s' in %s" % [word, text])


func test_exploring_counts_each_universe_once() -> void:
	var w := WonderData.new()
	assert_true(w.explore(1))
	assert_false(w.explore(1))
	assert_true(w.explore(4))
	assert_false(w.explore(0), "not a universe")
	assert_eq(w.universes, [1, 4] as Array[int])


func test_the_backup_keeps_the_best_of_both_copies() -> void:
	var phone := ProfileData.new()
	phone.username = "Mia"
	phone.updated_at = 100
	AnimalBookRules.record(phone.wonder, &"dog", WonderData.FED)
	AnimalBookRules.record(phone.wonder, &"owl", WonderData.MET)
	phone.wonder.explore(1)
	phone.wonder.pages.append(BookPages.SECRETS)
	var server := ProfileData.new()
	server.username = "Mia"
	server.updated_at = 200
	AnimalBookRules.record(server.wonder, &"dog", WonderData.FRIEND)
	AnimalBookRules.record(server.wonder, &"cow", WonderData.MET)
	server.wonder.explore(2)
	SavingRules.toggle(server.wonder, SavingRules.LOOK, "hat.crown")
	var merged: ProfileData = ProfileBackup.merge(phone, ProfileBackup.to_backup(server)).profile
	assert_eq(AnimalBookRules.flags(merged.wonder, &"dog"), WonderData.MET | WonderData.FED | WonderData.FRIEND,
		"the marks of both copies")
	assert_eq(AnimalBookRules.flags(merged.wonder, &"cow"), WonderData.MET)
	assert_eq(AnimalBookRules.flags(merged.wonder, &"owl"), WonderData.MET, "the older copy's animal too")
	assert_eq(merged.wonder.universes, [1, 2] as Array[int])
	assert_eq(merged.wonder.pages, [BookPages.SECRETS] as Array[String], "a rewarded page stays rewarded")
	assert_true(SavingRules.has(merged.wonder, SavingRules.LOOK, "hat.crown"))


func test_a_profile_with_book_entries_is_not_new() -> void:
	var p := ProfileData.new()
	assert_true(ProfileBackup.is_new(p))
	AnimalBookRules.record(p.wonder, &"dog", WonderData.MET)
	assert_false(ProfileBackup.is_new(p), "a met animal is progress a reinstall must not lose")
