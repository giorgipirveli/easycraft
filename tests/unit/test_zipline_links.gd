extends GutTest
## Which zipline posts are linked (M3 Task 14a): a post a player places links with the nearest post that
## player placed that has no line yet, up to 48 blocks away and with a clear line between; a broken post
## frees its partner; the links are saved with the world and read back defensively.

var links: ZiplineLinks


func before_each() -> void:
	links = ZiplineLinks.new()


func test_two_posts_of_one_player_link() -> void:
	assert_true(links.add(Vector3i(0, 10, 0), "Ana"))
	assert_null(links.partner_of(Vector3i(0, 10, 0)), "alone, it waits")
	assert_true(links.add(Vector3i(0, 10, 20), "Ana"))
	assert_eq(links.partner_of(Vector3i(0, 10, 0)), Vector3i(0, 10, 20))
	assert_eq(links.partner_of(Vector3i(0, 10, 20)), Vector3i(0, 10, 0))
	assert_eq(links.lines(), [[Vector3i(0, 10, 0), Vector3i(0, 10, 20)]])


func test_posts_of_different_players_never_link() -> void:
	links.add(Vector3i(0, 10, 0), "Ana")
	links.add(Vector3i(0, 10, 10), "Ben")
	assert_null(links.partner_of(Vector3i(0, 10, 0)))
	links.add(Vector3i(5, 10, 10), "Ben")
	assert_eq(links.partner_of(Vector3i(0, 10, 10)), Vector3i(5, 10, 10), "Ben's two")


func test_the_nearest_free_post_wins() -> void:
	links.add(Vector3i(0, 10, 40), "Ana")
	links.add(Vector3i(0, 10, 10), "Ana")   # links with the first (the only free one)
	links.add(Vector3i(0, 10, 0), "Ana")
	assert_null(links.partner_of(Vector3i(0, 10, 0)), "the near ones are taken")
	links.add(Vector3i(0, 10, 3), "Ana")
	assert_eq(links.partner_of(Vector3i(0, 10, 3)), Vector3i(0, 10, 0))


func test_posts_more_than_48_blocks_apart_do_not_link() -> void:
	links.add(Vector3i(0, 10, 0), "Ana")
	links.add(Vector3i(0, 10, 49), "Ana")
	assert_null(links.partner_of(Vector3i(0, 10, 0)))
	links.add(Vector3i(0, 10, 48), "Ana")
	assert_eq(links.partner_of(Vector3i(0, 10, 48)), Vector3i(0, 10, 0), "48 is fine")


func test_a_blocked_line_does_not_link() -> void:
	var never := func(_a: Vector3i, _b: Vector3i) -> bool: return false
	links.add(Vector3i(0, 10, 0), "Ana", never)
	links.add(Vector3i(0, 10, 10), "Ana", never)
	assert_null(links.partner_of(Vector3i(0, 10, 0)))
	assert_eq(links.posts().size(), 2, "both are known and wait")


func test_a_broken_post_frees_its_partner_for_the_next_one() -> void:
	links.add(Vector3i(0, 10, 0), "Ana")
	links.add(Vector3i(0, 10, 20), "Ana")
	links.remove(Vector3i(0, 10, 20))
	assert_false(links.has(Vector3i(0, 10, 20)))
	assert_null(links.partner_of(Vector3i(0, 10, 0)))
	assert_eq(links.lines(), [])
	links.add(Vector3i(10, 10, 0), "Ana")
	assert_eq(links.partner_of(Vector3i(0, 10, 0)), Vector3i(10, 10, 0))


func test_a_post_is_known_once_and_there_is_a_cap() -> void:
	assert_true(links.add(Vector3i(0, 10, 0), "Ana"))
	assert_false(links.add(Vector3i(0, 10, 0), "Ana"))
	for i in ZiplineLinks.MAX - 1:
		links.add(Vector3i(i * 3, 20, 100), "Ana")
	assert_false(links.add(Vector3i(0, 40, 0), "Ana"), "at most MAX posts in a world")


func test_links_are_saved_and_read_back() -> void:
	links.add(Vector3i(0, 10, 0), "Ana")
	links.add(Vector3i(0, 10, 20), "Ana")
	links.add(Vector3i(5, 11, 5), "Ben")
	var back := ZiplineLinks.from_save(JSON.parse_string(JSON.stringify(links.to_save())))
	assert_eq(back.partner_of(Vector3i(0, 10, 0)), Vector3i(0, 10, 20))
	assert_eq(back.owner_of(Vector3i(5, 11, 5)), "Ben")
	assert_null(back.partner_of(Vector3i(5, 11, 5)))
	back.add(Vector3i(5, 11, 15), "Ben")
	assert_eq(back.partner_of(Vector3i(5, 11, 5)), Vector3i(5, 11, 15), "a waiting post still links after a reload")


func test_broken_saves_never_crash_and_one_sided_links_are_dropped() -> void:
	for bad: Variant in [null, 3, "x", {}, [[1, 2]], [["a", 1, 2, "x"]], [[1, 2, 3, 4]], [[NAN, 1, 2, "a"]]]:
		assert_eq(ZiplineLinks.from_save(bad).posts().size(), 0, str(bad))
	var one_sided := [[0, 10, 0, "Ana", 0, 10, 20], [0, 10, 20, "Ana"]]
	var l := ZiplineLinks.from_save(one_sided)
	assert_eq(l.posts().size(), 2)
	assert_null(l.partner_of(Vector3i(0, 10, 0)), "a partner that doesn't link back is forgotten")
	var far := [[0, 10, 0, "Ana", 0, 10, 90], [0, 10, 90, "Ana", 0, 10, 0]]
	assert_null(ZiplineLinks.from_save(far).partner_of(Vector3i(0, 10, 0)), "too long a line is dropped")


func test_the_world_save_keeps_the_links() -> void:
	links.add(Vector3i(0, 10, 0), "Ana")
	links.add(Vector3i(0, 10, 20), "Ana")
	var m := WorldMeta.new_random()
	m.ziplines = links.to_save()
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(ZiplineLinks.from_save(back.ziplines).partner_of(Vector3i(0, 10, 20)), Vector3i(0, 10, 0))
	assert_eq(WorldMeta.from_json("{}").ziplines, [], "worlds saved before have none")
	assert_eq(WorldMeta.from_json('{"ziplines": "junk"}').ziplines, [])
