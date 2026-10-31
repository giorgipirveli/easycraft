extends GutTest
## Plain words for every network problem (M4 Wave 1 A, spec §17.0): the raw reasons the online code
## produces become a few short codes, and each code has a kind sentence a child can read.

const JARGON := ["socket", "match", "rpc", "nakama", "peer", "packet", "http", "json", "error",
	"exception", "timeout", "timed out", "relay", "server key", "session", "404", "null"]


func test_every_code_has_short_kind_words_without_jargon() -> void:
	for code: StringName in NetWords.CODES:
		var words := NetWords.text(code)
		assert_ne(words, "", "%s has words" % code)
		assert_lte(words.length(), 110, "%s is short" % code)
		assert_true(words[0] == words[0].to_upper(), "%s starts like a sentence" % code)
		assert_true(words.ends_with(".") or words.ends_with("!") or words.ends_with("…"), "%s ends like a sentence" % code)
		for w: String in JARGON:
			assert_false(words.to_lower().contains(w), "%s says no '%s': %s" % [code, w, words])


func test_an_unknown_code_still_gets_kind_words() -> void:
	assert_eq(NetWords.text(&"no_such_code"), NetWords.text(NetWords.UNKNOWN))


func test_the_raw_reasons_of_the_online_code_map_to_codes() -> void:
	var cases := {
		"sign-in: HTTPRequest failed!": NetWords.NO_SERVER,
		"sign-in: Request cancelled": NetWords.NO_SERVER,
		"socket: HTTPRequest failed!": NetWords.NO_SERVER,
		"sign-in: not a device id": NetWords.SIGN_IN,
		"sign-in: Invalid credentials.": NetWords.SIGN_IN,
		"not signed in": NetWords.SIGN_IN,
		"no answer from the match in 5 s": NetWords.TIMEOUT,
		"sign-in: Request timed out": NetWords.TIMEOUT,
		"match: Match not found": NetWords.NO_WORLD,
		"join: not a match id": NetWords.NO_WORLD,
		"match: not_invited": NetWords.NOT_INVITED,
		"match: match_full": NetWords.WORLD_FULL,
		"match: Match is full": NetWords.WORLD_FULL,
		"the connection to the server closed": NetWords.LINK_LOST,
		"the host left": NetWords.HOST_LEFT,
		"version: newer": NetWords.NEWER_WORLD,   # owner #123: the online version check (NetVersionCheck)
		"version: older": NetWords.OLDER_WORLD,
		"": NetWords.UNKNOWN,
		"something nobody expected": NetWords.UNKNOWN,
	}
	for reason: String in cases:
		assert_eq(NetWords.code_for(reason), cases[reason], "'%s'" % reason)


func test_words_for_a_reason_are_the_words_of_its_code() -> void:
	assert_eq(NetWords.for_reason("match: Match not found"), NetWords.text(NetWords.NO_WORLD))


func test_the_reconnect_words_say_what_is_happening() -> void:
	assert_string_contains(NetWords.text(NetWords.LINK_LOST), "Trying again")
	assert_string_contains(NetWords.text(NetWords.GAVE_UP).to_lower(), "menu")
	assert_string_contains(NetWords.text(NetWords.SERVER_GONE).to_lower(), "keep playing")


## Owner #123: the version check's words say which game is behind and what fixes it.
func test_the_version_words_say_what_to_do() -> void:
	assert_string_contains(NetWords.text(NetWords.NEWER_WORLD), "newer")
	assert_string_contains(NetWords.text(NetWords.NEWER_WORLD), "open it again")
	assert_string_contains(NetWords.text(NetWords.OLDER_WORLD), "older")
	assert_string_contains(NetWords.text(NetWords.OLDER_WORLD), "friend")
	assert_string_contains(NetWords.text(NetWords.FRIEND_DIFFERENT), "different")
	assert_string_contains(NetWords.text(NetWords.MAYBE_DIFFERENT), "look different")
	for code: StringName in [NetWords.NEWER_WORLD, NetWords.OLDER_WORLD, NetWords.FRIEND_DIFFERENT, NetWords.MAYBE_DIFFERENT]:
		assert_has(NetWords.CODES, code)
