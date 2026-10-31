extends GutTest
## The game's side of gifts, showcases, stickers and bottles (M4 Wave 3, agent I): the preset stickers
## (the server's list), the plain words for every answer, and careful reading of what the server sends
## (never a name that is not a username, never a broken build, never a sticker or phrase off the lists).

const GIFT_TS := "res://server/modules/src/rules/gift_rules.ts"


func _cube(n: int) -> String:
	var b := {}
	for x in n:
		for y in n:
			for z in n:
				b[Vector3i(x, y, z)] = BlockIds.PLANKS
	return BuildCodec.encode(b)


func test_the_stickers_are_the_servers_with_a_picture_word_each() -> void:
	var ts := FileAccess.get_file_as_string(GIFT_TS)
	var m := RegEx.create_from_string("export const STICKERS: string\\[\\] = \\[([^\\]]*)\\];").search(ts)
	assert_not_null(m)
	if m:
		var names: Array[String] = []
		for part in m.get_string(1).split(","):
			names.append(part.strip_edges().trim_prefix("\"").trim_suffix("\""))
		assert_eq(GiftRules.STICKERS, names)
	for s in GiftRules.STICKERS:
		assert_ne(GiftRules.sticker_word(s), "", s)
	for pair: Array in [["GIFTS_PER_FRIEND", GiftRules.GIFTS_PER_FRIEND], ["BOTTLES_PER_FRIEND", GiftRules.BOTTLES_PER_FRIEND],
			["GUESTBOOK_MAX", GiftRules.GUESTBOOK_MAX], ["KEEP_DAYS", GiftRules.KEEP_DAYS]]:
		var n := RegEx.create_from_string("export const %s = (\\d+);" % pair[0]).search(ts)
		assert_not_null(n, pair[0])
		if n:
			assert_eq(int(n.get_string(1)), pair[1], pair[0])


func test_every_answer_has_kind_plain_words() -> void:
	for code in ["too_many_gifts", "too_many_bottles", "inbox_full", "too_fast", "bad_build", "too_big", "empty_build",
			"no_showcase", "bad_sticker", "bad_phrase", "bad_buddy", "cannot_gift_self", "cannot_sign_own", "not_friends",
			"not_found", "gift_gone", "book_full", "not_allowed_online", "network"]:
		var words := GiftRules.message(code)
		assert_ne(words, "", code)
		assert_ne(words, OnlineRules.message(""), "its own words: %s" % code)
	assert_eq(GiftRules.message("socket: connection closed"), OnlineRules.message("network"))


func test_a_gift_list_is_read_carefully() -> void:
	var list := GiftRules.gift_list([
		{"gift_id": "g1_abc", "from_user_id": "uid-1", "from_username": "Mia_2", "count": 27, "size": [3, 3, 3], "created_ms": 5000},
		{"gift_id": "g2", "from_user_id": "uid-2", "from_username": "call me 555 1234", "count": 1, "size": [1, 1, 1]},
		{"gift_id": 5, "from_user_id": "uid-3", "from_username": "Pip_7"},
		{"gift_id": "g4", "from_user_id": "", "from_username": "Pip_7"},
		"junk"])
	assert_eq(list.size(), 1)
	assert_eq(list[0], {"id": "g1_abc", "from_id": "uid-1", "from": "Mia_2", "count": 27, "at": 5, "ghost": false})
	assert_true(GiftRules.gift_list([{"gift_id": "g", "from_user_id": "u", "from_username": "Mia_2", "ghost": true}])[0].ghost,
		"M4 ghost races: a race comes with it")
	assert_eq(GiftRules.gift_list("junk"), [])


func test_an_opened_gift_or_bottle_is_read_carefully() -> void:
	var g := GiftRules.opened({"gift_id": "g1", "from_user_id": "uid-1", "from_username": "Mia_2", "build": _cube(2)})
	assert_eq(g.build, _cube(2))
	assert_eq(g.from, "Mia_2")
	assert_eq(GiftRules.opened({"gift_id": "g1", "from_user_id": "uid-1", "from_username": "Mia_2", "build": "junk"}), {})
	var b := GiftRules.opened_bottle({"bottle_id": "b1", "from_user_id": "uid-1", "from_username": "Mia_2", "phrase": "Hi!"})
	assert_eq(b.phrase, "Hi!")
	assert_eq(b.build, "")
	assert_eq(GiftRules.opened_bottle({"bottle_id": "b1", "from_user_id": "u", "from_username": "Mia_2", "phrase": "meet me"}), {},
		"only quick-chat phrases")
	var with_build := GiftRules.opened_bottle({"bottle_id": "b1", "from_user_id": "u", "from_username": "Mia_2", "phrase": "Wow!",
		"build": _cube(4)})
	assert_eq(with_build.build, _cube(4))
	var too_big := GiftRules.opened_bottle({"bottle_id": "b1", "from_user_id": "u", "from_username": "Mia_2", "phrase": "Wow!",
		"build": _cube(5)})
	assert_eq(too_big.build, "", "a build bigger than a bottle's is left out; the phrase still arrives")


func test_a_showcase_and_its_guestbook_are_read_carefully() -> void:
	var s := GiftRules.showcase({"owner_id": "uid-1", "owner_username": "Mia_2", "build": _cube(3),
		"buddy": {"build": _cube(2), "at": [1, 0, 1]}, "updated_ms": 9000,
		"guestbook": [{"entry_id": "e1", "from_user_id": "uid-2", "from_username": "Pip_7", "sticker": "star", "at_ms": 7000},
			{"entry_id": "e2", "from_user_id": "uid-3", "from_username": "Pip_7", "sticker": "a rude word", "at_ms": 7000}]})
	assert_eq(s.owner, "Mia_2")
	assert_eq(s.build, _cube(3))
	assert_eq(s.buddy.at, Vector3i(1, 0, 1))
	assert_eq(s.guestbook.size(), 1)
	assert_eq(s.guestbook[0], {"id": "e1", "from_id": "uid-2", "from": "Pip_7", "sticker": "star", "at": 7})
	var no_buddy := GiftRules.showcase({"owner_id": "u", "owner_username": "Mia_2", "build": _cube(3),
		"buddy": {"build": _cube(2), "at": [40, 0, 1]}})
	assert_true(no_buddy.buddy.is_empty(), "a buddy outside the area is left out")
	assert_eq(GiftRules.showcase({"owner_id": "u", "owner_username": "Mia_2", "build": "junk"}), {})
