extends GutTest
## Friends' ghosts on this device (GhostBook, user://ghosts.json; M4 ghost races): "works offline against ghosts
## already downloaded". A friend's showcase ghosts come with the showcase's build (a visit works offline); a
## gift's ghost belongs to its stamp's slot and to the places it was stamped in this player's worlds; the child's
## best against each; this player's own showcase (which world, where) and the ghosts shared on it. Read
## carefully, capped, forgotten with the online account; a report forgets everything of that player.

var DIR := "user://test_ghost_book_%d/" % OS.get_process_id()
const COURSE_BUILD := "AQEBAQHLAQ=="   # any build text: the book keeps it as it came


func before_all() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func after_all() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)


func _ghost(id: String, ms: int = 1000) -> RaceGhost:
	var g := RaceGhost.new()
	g.id = id
	g.start = Vector3i(1, 0, 1)
	g.finish = Vector3i(8, 0, 8)
	g.ms = ms
	for i in RaceGhost.sample_count(ms):
		g.points.append(Vector3(7, 0, 7) * i / float(RaceGhost.sample_count(ms) - 1))
	g.points = PackedVector3Array(Array(g.points).map(func(p: Vector3) -> Vector3: return (p * 10.0).round() / 10.0))
	g.look = "{\"hat\":\"cap\"}"
	return g


func test_a_friends_showcase_ghosts_are_kept_with_its_build_for_offline_races() -> void:
	var book := GhostBook.new()
	book.keep_showcase("u-mia", "Mia_2", COURSE_BUILD, [_ghost("h1_a"), _ghost("h2_b", 2000)] as Array[RaceGhost], 100)
	var back := GhostBook.from_json(book.to_json())
	var s := back.showcase_for("u-mia")
	assert_eq(s.owner_id, "u-mia")
	assert_eq(s.owner, "Mia_2")
	assert_eq(s.build, COURSE_BUILD)
	assert_true(s.offline, "a visit from this device's copy")
	assert_eq(s.buddy, {})
	var ghosts: Array = s.ghosts
	assert_eq(ghosts.size(), 2)
	assert_eq([(ghosts[0] as RaceGhost).id, (ghosts[1] as RaceGhost).ms], ["h1_a", 2000])
	assert_eq((ghosts[0] as RaceGhost).points, _ghost("h1_a").points, "the path as it came")
	assert_eq((ghosts[0] as RaceGhost).owner, "Mia_2")
	assert_eq(back.showcase_for("u-nobody"), {})
	# Visiting again: the list replaces what was there (a ghost taken down goes); the best against a kept one stays.
	assert_true(back.note_result(GhostBook.showcase_key("h1_a"), 1500, 200), "a first time against it")
	assert_false(back.note_result(GhostBook.showcase_key("h1_a"), 1600, 210), "slower: not a new best")
	back.keep_showcase("u-mia", "Mia_2", COURSE_BUILD, [_ghost("h1_a")] as Array[RaceGhost], 300)
	assert_eq(back.showcase_for("u-mia").ghosts.size(), 1)
	assert_eq(int(back.entry(GhostBook.showcase_key("h1_a")).best), 1500)
	back.keep_showcase("u-mia", "Mia_2", COURSE_BUILD, [] as Array[RaceGhost], 400)
	assert_eq(back.showcase_for("u-mia"), {}, "no ghosts left: the copy goes too")


func test_at_most_12_ghosts_and_6_showcases_the_least_lately_raced_go_first() -> void:
	var book := GhostBook.new()
	for i in 7:
		var list: Array[RaceGhost] = [_ghost("h%d_a" % i), _ghost("h%d_b" % i)]
		book.keep_showcase("u%d" % i, "Pal_%d" % i, COURSE_BUILD, list, 100 + i)
	assert_eq(book.showcase_owners().size(), GhostBook.MAX_SHOWCASES)
	assert_lte(book.ghosts.size(), GhostBook.MAX_GHOSTS)
	assert_eq(book.showcase_for("u0"), {}, "the oldest went")
	assert_false(book.showcase_for("u6").is_empty())
	for e: Dictionary in book.ghosts:
		assert_true(book.showcases.has(e.owner_id), "no ghost without its showcase's build")


func test_a_gifts_ghost_belongs_to_its_stamp_and_the_places_it_was_stamped() -> void:
	var book := GhostBook.new()
	book.keep_gift(3, "u-mia", "Mia_2", _ghost(""), 100)
	var key := GhostBook.gift_key(3)
	assert_eq(book.gift_entry(3).key, key)
	book.place(key, "sandbox_1:42", Vector3i(10, 20, 30), Vector3i(0, 0, -1))
	book.place(key, "sandbox_1:42", Vector3i(10, 20, 30), Vector3i(0, 0, -1))
	book.place(key, "survivor_1:7", Vector3i(1, 2, 3), Vector3i(1, 0, 0))
	var here := book.placed_in("sandbox_1:42")
	assert_eq(here.size(), 1, "the same place once")
	assert_eq([here[0].start, here[0].forward], [Vector3i(10, 20, 30), Vector3i(0, 0, -1)])
	assert_eq((here[0].ghost as RaceGhost).owner, "Mia_2")
	var back := GhostBook.from_json(book.to_json())
	assert_eq(back.placed_in("survivor_1:7").size(), 1)
	# A new gift in the same slot is a new stamp: the old places don't race its ghost.
	back.keep_gift(3, "u-leo", "Leo_4", _ghost("", 2000), 200)
	assert_eq(back.placed_in("sandbox_1:42").size(), 0)
	assert_eq(back.gift_entry(3).owner, "Leo_4")
	back.forget_slot(3)
	assert_eq(back.gift_entry(3), {})
	back.keep_gift(1, "u-mia", "Mia_2", _ghost(""), 300)
	for i in GhostBook.MAX_PLACED + 3:
		back.place(GhostBook.gift_key(1), "w", Vector3i(i, 0, 0), Vector3i(0, 0, 1))
	assert_eq(back.placed_in("w").size(), GhostBook.MAX_PLACED, "the newest places")


func test_a_report_forgets_everything_of_that_player() -> void:
	var book := GhostBook.new()
	book.keep_showcase("u-mia", "Mia_2", COURSE_BUILD, [_ghost("h1_a")] as Array[RaceGhost], 100)
	book.keep_gift(2, "u-mia", "Mia_2", _ghost(""), 100)
	book.place(GhostBook.gift_key(2), "w", Vector3i.ONE, Vector3i(0, 0, 1))
	book.keep_gift(4, "u-leo", "Leo_4", _ghost(""), 100)
	assert_eq(book.remove_owner("u-mia"), 2)
	assert_eq(book.showcase_for("u-mia"), {})
	assert_eq(book.gift_entry(2), {})
	assert_eq(book.placed_in("w").size(), 0)
	assert_false(book.gift_entry(4).is_empty(), "other friends' stay")


func test_my_own_showcase_where_it_is_and_what_is_shared_on_it() -> void:
	var book := GhostBook.new()
	book.set_mine("sandbox_1:42", Vector3i(100, 10, 200), Vector3i(32, 32, 32))
	assert_true(book.in_my_showcase("sandbox_1:42", Vector3i(101, 18, 201)))
	assert_false(book.in_my_showcase("sandbox_1:42", Vector3i(132, 18, 201)), "outside the area")
	assert_false(book.in_my_showcase("survivor_1:7", Vector3i(101, 18, 201)), "another world")
	book.note_shared("sandbox_1:42", Vector3i(101, 18, 201), "h9_z", 42000)
	var back := GhostBook.from_json(book.to_json())
	assert_eq(back.shared_at("sandbox_1:42", Vector3i(101, 18, 201)), {"id": "h9_z", "ms": 42000})
	assert_eq(back.shared_at("sandbox_1:42", Vector3i(5, 5, 5)), {})
	back.set_mine("sandbox_1:42", Vector3i(0, 0, 0), Vector3i(32, 32, 32))
	assert_eq(back.shared_at("sandbox_1:42", Vector3i(101, 18, 201)), {}, "a new showcase: nothing shared on it yet")
	back.unshare("h9_z")
	back.clear_mine()
	assert_false(back.in_my_showcase("sandbox_1:42", Vector3i(1, 1, 1)))


func test_a_tampered_book_is_read_carefully() -> void:
	var book := GhostBook.new()
	book.keep_showcase("u-mia", "Mia_2", COURSE_BUILD, [_ghost("h1_a")] as Array[RaceGhost], 100)
	book.keep_gift(2, "u-mia", "Mia_2", _ghost(""), 100)
	var d: Dictionary = JSON.parse_string(book.to_json())
	d.ghosts.append({"key": "s:h7", "kind": "showcase", "owner_id": "u-x", "owner": "bad name!", "ghost": d.ghosts[0].ghost})
	d.ghosts.append({"key": "g99", "kind": "gift", "slot": 99, "owner_id": "u-x", "owner": "Leo_4", "ghost": d.ghosts[0].ghost})
	d.ghosts.append({"key": "s:h8", "kind": "showcase", "owner_id": "u-mia", "owner": "Mia_2", "ghost": {"path": "!!"}})
	d.placed = [{"key": "nope", "world": "w", "start": [1, 2, 3], "forward": [0, 0, 1]}, 5]
	var back := GhostBook.from_json(JSON.stringify(d))
	assert_eq(back.ghosts.size(), 2, "only the whole ones")
	assert_eq(back.placed_in("w").size(), 0, "a place of no ghost is dropped")
	assert_eq(GhostBook.from_json("not json").ghosts.size(), 0)
	assert_eq(GhostBook.from_json("").ghosts.size(), 0)


func test_saved_on_this_device_atomically() -> void:
	var book := GhostBook.new()
	book.names_ok = true
	book.keep_gift(0, "u-mia", "Mia_2", _ghost(""), 100)
	assert_eq(book.save_to(DIR + "ghosts.json"), OK)
	var back := GhostBook.load_from(DIR + "ghosts.json")
	assert_true(back.names_ok, "the last known consent (names shown offline)")
	assert_eq(back.gift_entry(0).owner, "Mia_2")
	assert_eq(GhostBook.load_from(DIR + "missing.json").ghosts.size(), 0)
