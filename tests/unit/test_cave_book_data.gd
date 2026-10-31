extends GutTest
## Universe 6, the Glow Caves' Cave Book (owner #122): the wonders a child solved and the sights found, account-wide in
## the profile's books (WonderData.caves: a page's kind -> FOUND), kept by the server backup like the Wonders Passport.

const W := preload("res://core/rules/glow_wonder_rules.gd")


func test_a_page_is_found_once() -> void:
	var d := WonderData.new()
	assert_false(d.cave_found(W.DRIP))
	assert_true(d.find_cave(W.DRIP), "the first time")
	assert_false(d.find_cave(W.DRIP), "never twice")
	assert_true(d.cave_found(W.DRIP))
	assert_false(d.find_cave(&"volcano"), "only the Cave Book's pages")
	assert_false(d.is_empty())


func test_the_cave_book_survives_a_save_and_a_bad_file() -> void:
	var d := WonderData.new()
	d.find_cave(W.GROTTO)
	d.find_cave(W.LONGEST)
	var back := WonderData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_true(back.cave_found(W.GROTTO))
	assert_true(back.cave_found(W.LONGEST))
	assert_false(back.cave_found(W.ECHO))
	var bad := WonderData.from_dict({"caves": {"grotto": "yes", "nope": 1, "echo": 7, "lake": 1.5, "rain": 1}})
	assert_eq(bad.caves.keys(), ["rain"], "only known pages with a proper mark")


func test_the_backup_merge_keeps_both_copies_pages() -> void:
	var a := WonderData.new()
	a.find_cave(W.GROTTO)
	var b := WonderData.new()
	b.find_cave(W.LAKE)
	a.merge_from(b)
	assert_true(a.cave_found(W.GROTTO))
	assert_true(a.cave_found(W.LAKE))
