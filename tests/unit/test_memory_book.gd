extends GutTest
## M3 Task 21b (research R2, C5): the Memory Book — the child's big moments collected by themselves (the first
## buddy woken, the first night, the Golem beaten, a friend played with...), each once, with its date and, when
## the child took one soon after, their photo. Kept on this device only (never in the profile or its server
## backup), never shared by itself.

var DIR := "user://test_memory_book_%d/" % OS.get_process_id()


func after_all() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)


func test_counted_events_are_moments() -> void:
	assert_eq(MemoryRules.for_event(&"buddy_woken"), [&"first_buddy"] as Array[StringName])
	assert_eq(MemoryRules.for_event(&"animal_tamed/dog"), [&"first_pet"] as Array[StringName], "by its family")
	assert_eq(MemoryRules.for_event(&"boss_beaten/golem"), [&"boss_golem"] as Array[StringName])
	assert_eq(MemoryRules.for_event(&"boss_beaten/sky_dragon"), [&"boss_sky_dragon"] as Array[StringName])
	assert_eq(MemoryRules.for_event(&"block_placed"), [] as Array[StringName], "not every event is a moment")
	assert_eq(MemoryRules.for_event(&"friend_played"), [&"first_friend"] as Array[StringName], "a friend visited")


func test_every_moment_has_words_and_a_picture() -> void:
	var ids: Array[StringName] = []
	for m: Dictionary in MemoryRules.MOMENTS:
		ids.append(m.id)
	ids.append_array([&"first_night", &"universe_2", &"universe_5", &"page_secrets", &"level_5", &"boss_golem",
		&"boss_giant", &"boss_cake"])
	for id in ids:
		assert_true(MemoryRules.is_moment(id), String(id))
		assert_ne(MemoryRules.words_of(id), "", String(id))
		assert_true(ProgressPictures.knows(MemoryRules.picture_of(id)), "%s: %s" % [id, MemoryRules.picture_of(id)])
	assert_eq(MemoryRules.words_of(&"boss_golem"), "We beat the Stone Golem!")
	assert_eq(MemoryRules.words_of(&"universe_2"), "I found a new world: %s!" % UniverseRegistry.display_name(2))
	assert_false(MemoryRules.is_moment(&"universe_1"), "the first universe is home")
	assert_false(MemoryRules.is_moment(&"level_7"), "only the round levels")
	assert_false(MemoryRules.is_moment(&"nonsense"))


func test_a_moment_is_kept_once_with_its_date() -> void:
	var book := MemoryBook.new()
	assert_true(book.add(&"first_buddy", "2026-09-25", 1000))
	assert_false(book.add(&"first_buddy", "2026-09-26", 2000), "once")
	assert_false(book.add(&"nonsense", "2026-09-26", 2000), "only real moments")
	assert_true(book.has(&"first_buddy"))
	assert_eq(book.entries[0].date, "2026-09-25")
	assert_eq(MemoryRules.date_words("2026-09-25"), "25 Sep 2026")
	assert_eq(MemoryRules.date_words("junk"), "")
	assert_eq(MemoryRules.today({"year": 2026, "month": 1, "day": 5}), "2026-01-05")


func test_newest_first_and_a_cap() -> void:
	var book := MemoryBook.new()
	book.add(&"first_buddy", "2026-09-25", 100)
	book.add(&"first_pet", "2026-09-25", 300)
	book.add(&"first_secret", "2026-09-25", 200)
	var order: Array[StringName] = []
	for e: Dictionary in book.newest_first():
		order.append(StringName(e.id))
	assert_eq(order, [&"first_pet", &"first_secret", &"first_buddy"] as Array[StringName])
	assert_lte(MemoryRules.MAX, 128)


func test_a_photo_taken_soon_after_goes_with_the_newest_moment() -> void:
	var book := MemoryBook.new()
	book.add(&"first_buddy", "2026-09-25", 1000)
	book.add(&"boss_golem", "2026-09-25", 1100)
	assert_eq(MemoryRules.photo_target(book.entries, 1100 + MemoryRules.PHOTO_WINDOW + 1), &"", "too late")
	assert_eq(MemoryRules.photo_target(book.entries, 1200), &"boss_golem")
	assert_true(book.attach_photo(&"boss_golem", "boss_golem.png"))
	assert_eq(MemoryRules.photo_target(book.entries, 1200), &"first_buddy", "the next one still without a photo")
	assert_false(book.attach_photo(&"boss_golem", "other.png"), "a memory keeps its first photo")
	assert_false(book.attach_photo(&"first_pet", "x.png"), "no such memory")
	assert_false(book.attach_photo(&"first_buddy", "../../escape.png"), "only a plain file name")


func test_the_book_is_saved_on_the_device() -> void:
	var path := DIR.path_join("memories.json")
	var book := MemoryBook.new()
	book.add(&"first_night", "2026-09-24", 50)
	book.add(&"universe_2", "2026-09-25", 60)
	book.attach_photo(&"universe_2", "universe_2.png")
	assert_eq(book.save_to(path), OK)
	var back := MemoryBook.load_from(path)
	assert_eq(back.entries.size(), 2)
	assert_eq(back.photo_of(&"universe_2"), "universe_2.png")
	assert_eq(back.photo_path(&"universe_2", path), DIR.path_join("universe_2.png"))
	assert_eq(MemoryBook.load_from(DIR.path_join("none.json")).entries.size(), 0, "no file: an empty book")


func test_broken_files_load_what_they_can() -> void:
	var b := MemoryBook.from_json("{\"version\": 1, \"entries\": [{\"id\": \"first_buddy\", \"date\": \"2026-09-25\", \"t\": 5},"
		+ " {\"id\": \"nonsense\"}, 7, {\"id\": \"first_pet\", \"date\": \"yesterday\", \"t\": \"x\", \"photo\": \"../a.png\"},"
		+ " {\"id\": \"first_buddy\", \"date\": \"2026-09-26\", \"t\": 6}]}")
	assert_eq(b.entries.size(), 2)
	assert_eq(b.entries[1].date, "", "a bad date is left out")
	assert_eq(b.entries[1].photo, "", "a bad photo name is left out")
	for bad in ["", "junk", "[]", "{\"entries\": 5}"]:
		assert_eq(MemoryBook.from_json(bad).entries.size(), 0, bad)


func test_the_memory_book_never_reaches_the_profile() -> void:
	var p := ProfileData.new()
	assert_false(p.to_json().contains("first_buddy"))
	assert_false(ProfileBackup.to_backup(p).contains("memor"), "not in the server backup")
