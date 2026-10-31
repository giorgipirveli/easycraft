extends GutTest
## The Buddy Album (M3 Task 20b, spec §14.21, research C2): every buddy the child woke, with its name, a small
## picture of its front (BuddyPicture, drawn from its blocks), where and when; kept in the profile (capped: the
## oldest are summarised as a count). The profile also keeps the secret shapes found, the bosses' mini-buddies
## and the tricks the profile's own pets learned (BuddyMagicData), and a backup merge never loses any of it.


func _snowman() -> Dictionary:
	return {Vector3i(0, 0, 0): BlockIds.PAINTED_WHITE, Vector3i(0, 1, 0): BlockIds.PAINTED_WHITE,
		Vector3i(0, 2, 0): BlockIds.PAINTED_WHITE, Vector3i(1, 2, 0): BlockIds.PAINTED_ORANGE}


# --- The picture ---

func test_the_picture_is_the_front_of_the_build() -> void:
	var b := _snowman()
	b[Vector3i(0, 1, 1)] = BlockIds.PLANKS                   # behind the body: hidden by it
	var code := BuddyPicture.code_of(b)
	var pic := BuddyPicture.decode(code)
	assert_eq(pic.w, 2)
	assert_eq(pic.h, 3)
	assert_eq(Array(pic.cells), [BlockIds.PAINTED_WHITE, BlockIds.PAINTED_ORANGE, BlockIds.PAINTED_WHITE, 0,
		BlockIds.PAINTED_WHITE, 0], "row by row from the top left; the front block of each column")


func test_the_front_is_the_side_with_the_eyes() -> void:
	var b := {Vector3i(0, 0, 0): BlockIds.RED, Vector3i(0, 0, 1): BlockIds.BLUE}
	assert_eq(Array(BuddyPicture.decode(BuddyPicture.code_of(b)).cells), [BlockIds.RED], "z = 0 is the face (-Z)")


func test_a_big_build_becomes_a_small_picture() -> void:
	var b := {}
	for x in 17:
		for y in 12:
			b[Vector3i(x, y, 0)] = BlockIds.GREEN if (x + y) % 2 == 0 else BlockIds.YELLOW
	var code := BuddyPicture.code_of(b)
	var pic := BuddyPicture.decode(code)
	assert_eq(pic.w, BuddyPicture.MAX)
	assert_eq(pic.h, BuddyPicture.MAX)
	assert_lte(code.length(), BuddyPicture.MAX_CODE)


func test_a_plain_build_packs_small() -> void:
	var b := {}
	for x in 8:
		for y in 8:
			b[Vector3i(x, y, 0)] = BlockIds.BRICK
	assert_lte(BuddyPicture.code_of(b).length(), 12, "runs of one block pack into a few letters")


func test_broken_pictures_decode_to_nothing() -> void:
	for bad in ["", "x", "3.2:1,1", "2.2:1,1,1,1,1", "0.0:", "9.9:" + "1,".repeat(81), "2.1:1,99999", "2.1:1*5",
			"1.1:-4", "2.1:3,abc"]:
		assert_true(BuddyPicture.decode(bad).is_empty(), "'%s'" % bad)
	assert_false(BuddyPicture.decode("2.1:1,0").is_empty())
	assert_false(BuddyPicture.decode("2.1:1*2").is_empty())


# --- The album ---

func test_a_woken_buddy_goes_into_the_album() -> void:
	var m := BuddyMagicData.new()
	m.add_album("Frosty", &"snowman", BuddyPicture.code_of(_snowman()), 3, 1790000000)
	assert_eq(m.album.size(), 1)
	assert_eq(m.woken, 1)
	var e: Dictionary = m.album[0]
	assert_eq(e.name, "Frosty")
	assert_eq(e.recipe, "snowman")
	assert_eq(e.u, 3)
	assert_eq(e.at, 1790000000)
	assert_eq(BuddyMagicData.where_words(e), "Frostpeak")
	assert_ne(BuddyMagicData.when_words(e), "")


func test_the_album_keeps_the_newest_and_counts_the_older_ones() -> void:
	var m := BuddyMagicData.new()
	for i in BuddyMagicData.ALBUM_MAX + 7:
		m.add_album("B%d" % i, &"", "", 1, 1000 + i)
	assert_eq(m.album.size(), BuddyMagicData.ALBUM_MAX, "capped")
	assert_eq(m.older, 7, "the oldest are summarised as a count")
	assert_eq(m.woken, BuddyMagicData.ALBUM_MAX + 7)
	assert_eq(m.album[0].name, "B7", "the oldest kept")
	assert_eq(m.album[-1].name, "B%d" % (BuddyMagicData.ALBUM_MAX + 6), "the newest last")


func test_album_entries_are_cleaned() -> void:
	var m := BuddyMagicData.new()
	m.add_album("A very very long buddy name that goes on", &"nonsense", "broken", 99, -5)
	var e: Dictionary = m.album[0]
	assert_lte(str(e.name).length(), BuddyMagicData.NAME_MAX)
	assert_eq(e.recipe, "", "an unknown recipe is a plain buddy")
	assert_eq(e.pic, "", "a broken picture is dropped")
	assert_eq(e.u, 1)
	assert_eq(e.at, 0)


# --- Secret shapes found ---

func test_each_secret_shape_is_found_once() -> void:
	var m := BuddyMagicData.new()
	assert_true(m.add_found(&"snowman"))
	assert_false(m.add_found(&"snowman"), "only the first time")
	assert_false(m.add_found(&"nonsense"))
	assert_false(m.add_found(&""))
	assert_true(m.has_found(&"snowman"))
	assert_false(m.has_found(&"castle"))


# --- Saving ---

func test_it_round_trips_through_the_profile() -> void:
	var p := ProfileData.new()
	p.buddy_magic.add_found(&"castle")
	p.buddy_magic.add_album("Melody", &"castle", "1.1:9", 1, 42)
	p.buddy_magic.minis["golem"] = MiniRules.record(&"golem")
	p.buddy_magic.tricks["pip"] = ["wave", "cheer"]
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.buddy_magic.found, ["castle"] as Array[String])
	assert_eq(back.buddy_magic.album.size(), 1)
	assert_eq(back.buddy_magic.album[0].pic, "1.1:9")
	assert_eq(back.buddy_magic.woken, 1)
	assert_eq(str(back.buddy_magic.minis["golem"].name), "Pebble")
	assert_eq(back.buddy_magic.tricks["pip"], ["wave", "cheer"])


func test_a_hand_edited_save_never_breaks_it() -> void:
	for bad: Variant in [null, 5, "x", [], {"found": "snowman", "album": 3, "older": "a", "woken": -2, "minis": [],
			"tricks": 7},
			{"found": ["snowman", 4, "nope", "snowman"], "album": [5, {"name": 3}, {}], "minis": {"nope": {}, "golem": 3},
			"tricks": {"pip": ["wave", "nope", 5], "BAD KEY!": ["wave"], "baby_dragon": "wave"}}]:
		var m := BuddyMagicData.from_dict(bad)
		assert_not_null(m)
		assert_gte(m.older, 0)
		assert_gte(m.woken, m.album.size())
	var m := BuddyMagicData.from_dict({"found": ["snowman", 4, "nope", "snowman"], "minis": {"nope": {}, "golem": {}},
		"tricks": {"pip": ["wave", "nope", 5], "BAD KEY!": ["wave"]}})
	assert_eq(m.found, ["snowman"] as Array[String])
	assert_false(m.minis.has("nope"))
	assert_eq(m.tricks.get("pip"), ["wave"])
	assert_false(m.tricks.has("BAD KEY!"))


func test_a_new_profile_has_no_buddy_magic_and_one_with_any_is_not_new() -> void:
	var p := ProfileData.new()
	assert_true(p.buddy_magic.is_empty())
	assert_true(ProfileBackup.is_new(p))
	p.buddy_magic.add_found(&"fairy")
	assert_false(ProfileBackup.is_new(p), "a secret shape found is progress")


func test_the_backup_merge_never_loses_buddy_magic() -> void:
	var phone := ProfileData.new()
	phone.username = "Kid"
	phone.updated_at = 100
	phone.buddy_magic.add_found(&"snowman")
	phone.buddy_magic.add_album("Frosty", &"snowman", "", 1, 10)
	phone.buddy_magic.tricks["pip"] = ["wave"]
	var server := ProfileData.new()
	server.username = "Kid"
	server.updated_at = 200                                    # the newer one wins ...
	server.buddy_magic.add_found(&"castle")
	server.buddy_magic.add_album("Melody", &"castle", "", 2, 20)
	server.buddy_magic.minis["golem"] = MiniRules.record(&"golem")
	server.buddy_magic.tricks["pip"] = ["cheer"]
	var out: ProfileData = ProfileBackup.merge(phone, ProfileBackup.to_backup(server)).profile
	var found := out.buddy_magic.found
	found.sort()
	assert_eq(found, ["castle", "snowman"] as Array[String], "... but a shape found on either is kept")
	assert_eq(out.buddy_magic.album.map(func(e: Dictionary) -> String: return e.name), ["Frosty", "Melody"],
		"both albums, oldest first")
	assert_true(out.buddy_magic.minis.has("golem"))
	var tricks: Array = out.buddy_magic.tricks["pip"]
	tricks.sort()
	assert_eq(tricks, ["cheer", "wave"], "every trick learned")
	assert_gte(out.buddy_magic.woken, 2)
