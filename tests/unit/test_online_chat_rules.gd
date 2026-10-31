extends GutTest
## Online chat as pure rules (M4 Wave 2, Agent E; spec §5.13, §17.4): the quick-chat wheel's phrases
## (the server's own list), who may type, what a channel message may hold, reading messages from the
## server (never trusting them), history for 13+ only and kind words for every refusal.

const R := preload("res://core/net/online_chat_rules.gd")
const SERVER_RULES := "res://server/modules/src/rules/chat_rules.ts"
const ME := "00000000-0000-4000-8000-000000000001"
const PIP := "00000000-0000-4000-8000-000000000002"


func _server_phrases() -> Array[String]:
	var src := FileAccess.get_file_as_string(SERVER_RULES)
	var m := RegEx.create_from_string("QUICK_PHRASES: string\\[\\] = \\[([^\\]]*)\\]").search(src)
	var out: Array[String] = []
	if m == null:
		return out
	for s in RegEx.create_from_string("\"([^\"]*)\"").search_all(m.get_string(1)):
		out.append(s.get_string(1))
	return out


func _msg(content: String, sender: String = PIP, username: String = "Pip", code: int = 0) -> Dictionary:
	return {"channel_id": "4.%s.%s." % [ME, PIP], "message_id": "m1", "sender_id": sender, "username": username,
		"content": content, "create_time": "2026-09-24T12:00:00Z", "code": code}


func test_the_wheel_has_eight_short_kind_phrases_from_the_servers_list() -> void:
	var server := _server_phrases()
	assert_eq(server.size(), 13, "the server's list was read")
	assert_eq(Array(ChatRules.QUICK_PHRASES), Array(server), "the game's quick phrases are the server's")
	assert_eq(R.WHEEL.size(), 8)
	for phrase in R.WHEEL:
		assert_true(server.has(phrase), "%s is one of the server's quick phrases" % phrase)
		assert_lte(phrase.length(), 14, "short: %s" % phrase)
		assert_true(R.PICTURES.has(phrase), "%s has a picture" % phrase)
	for phrase in ["Hi!", "Follow me!", "Look!", "Help!", "Thanks!", "Good job!", "Let's build!", "Bye!"]:
		assert_true(R.WHEEL.has(phrase), phrase)


func test_only_13_plus_with_filtered_chat_may_type() -> void:
	var teen := {"age_band": AgeBand.TEEN_PLUS, "consent": "none", "online_allowed": true, "chat": "filtered"}
	var kid := {"age_band": AgeBand.UNDER_13, "consent": "verified", "online_allowed": true, "chat": "quick"}
	assert_eq(R.chat_level(teen), OnlineRules.CHAT_FILTERED)
	assert_true(R.can_type(teen))
	assert_eq(R.chat_level(kid), OnlineRules.CHAT_QUICK)
	assert_false(R.can_type(kid), "under-13: only the wheel")
	var quiet := teen.duplicate()
	quiet.chat = "quick"
	assert_false(R.can_type(quiet), "a grown-up chose quick chat for a teen")
	var off := kid.duplicate()
	off.chat = "off"
	assert_eq(R.chat_level(off), OnlineRules.CHAT_OFF)
	var no_consent := kid.duplicate()
	no_consent.consent = "none"
	assert_eq(R.chat_level(no_consent), OnlineRules.CHAT_OFF, "no chat before a grown-up's consent")
	var odd := kid.duplicate()
	odd.chat = "filtered"
	assert_eq(R.chat_level(odd), OnlineRules.CHAT_QUICK, "never free text under 13, whatever the server says")
	assert_eq(R.chat_level({}), OnlineRules.CHAT_OFF)


func test_history_is_kept_for_13_plus_only() -> void:
	assert_true(R.keeps_history(AgeBand.TEEN_PLUS))
	assert_false(R.keeps_history(AgeBand.UNDER_13))
	assert_false(R.keeps_history(&""))


func test_what_a_player_may_send() -> void:
	assert_eq(R.check_send("hello there", OnlineRules.CHAT_FILTERED), {"content": {"text": "hello there"}})
	assert_eq(R.check_send("  Hi!  ", OnlineRules.CHAT_QUICK), {"content": {"text": "Hi!"}})
	assert_eq(R.check_send("hello there", OnlineRules.CHAT_QUICK), {"error": "quick_chat_only"})
	assert_eq(R.check_send("call me 555 123 4567", OnlineRules.CHAT_FILTERED), {"error": "personal_info"})
	assert_eq(R.check_send("", OnlineRules.CHAT_FILTERED), {"error": "empty"})
	assert_eq(R.check_send("Hi!", OnlineRules.CHAT_OFF), {"error": "chat_off"})
	assert_eq(R.emote_content(&"wave"), {"emote": "wave"})
	assert_eq(R.emote_content(&"Not An Emote"), {}, "only the emote ids the server takes")


func test_a_message_from_the_server_is_read_carefully() -> void:
	var m := R.parse(_msg("{\"text\":\"Hi!\"}"), ME, AgeBand.TEEN_PLUS)
	assert_eq(m.text, "Hi!")
	assert_eq(m.from, "Pip")
	assert_eq(m.from_id, PIP)
	assert_eq(m.id, "m1")
	assert_false(m.mine)
	assert_eq(R.line(m), "Pip: Hi!")
	assert_true(R.parse(_msg("{\"text\":\"Hi!\"}", ME, "Me"), ME, AgeBand.TEEN_PLUS).mine)
	var emote := R.parse(_msg("{\"emote\":\"wave\"}"), ME, AgeBand.UNDER_13)
	assert_eq(emote.emote, &"wave")
	assert_eq(R.line(emote), "Pip: *Wave*")
	assert_eq(R.parse(_msg("{\"emote\":\"no_such_move\"}"), ME, AgeBand.TEEN_PLUS), {}, "unknown emotes are dropped")
	assert_eq(R.parse(_msg("not json"), ME, AgeBand.TEEN_PLUS), {})
	assert_eq(R.parse(_msg("{\"text\":\"Hi!\",\"extra\":1}"), ME, AgeBand.TEEN_PLUS), {})
	assert_eq(R.parse(_msg("{\"text\":\"Hi!\"}", PIP, "Pip", 2), ME, AgeBand.TEEN_PLUS), {}, "Nakama's own notices (code != 0)")
	assert_eq(R.parse(_msg("{\"text\":\"hello there\"}"), ME, AgeBand.UNDER_13), {},
		"under-13 never reads free text, even if a server sent it")
	var bad_name := R.parse(_msg("{\"text\":\"Hi!\"}", PIP, "call 5551234567"), ME, AgeBand.TEEN_PLUS)
	assert_eq(bad_name.from, R.SOMEONE, "a name that is not a username is not shown")
	var long := R.parse(_msg(JSON.stringify({"text": "a".repeat(500)})), ME, AgeBand.TEEN_PLUS)
	assert_eq(long.text.length(), ChatRules.MAX_LENGTH)


func test_old_messages_go_after_30_days() -> void:
	var now := int(Time.get_unix_time_from_datetime_string("2026-09-24T12:00:00"))
	var fresh := {"time": now - 29 * 86400}
	var old := {"time": now - 31 * 86400}
	var list: Array[Dictionary] = [old, fresh]
	assert_eq(R.recent(list, now), [fresh] as Array[Dictionary])
	assert_eq(R.unix_time("2026-09-24T12:00:00Z"), now)
	assert_eq(R.unix_time("2026-09-24T12:00:00.123456Z"), now)
	assert_eq(R.unix_time("nonsense"), 0)


func test_every_refusal_is_short_and_kind() -> void:
	for code in ["quick_chat_only", "personal_info", "blocked_word", "empty", "too_fast", "chat_off", "not_friends",
			"room_not_allowed", "not_in_channel", "bad_message", "network", "not_signed_in", "something_new"]:
		var words := R.message(code)
		assert_ne(words, "", code)
		assert_lte(words.split(" ").size(), 12, "%s: %s" % [code, words])
		assert_false(words.contains("_"), "no codes on screen: %s" % words)
	assert_eq(R.message("chat_off"), "A grown-up turned chat off.")
	assert_eq(R.message("personal_info"), ChatRules.message("personal_info"), "the chat's words, not the username's")


func test_nakama_channel_names() -> void:
	assert_eq(R.TYPE_ROOM, 1)
	assert_eq(R.TYPE_DM, 2)
	assert_eq(R.team_room("3DCF6DCA-BA73-4E08-A89E-8C538234F741."), "3dcf6dca-ba73-4e08-a89e-8c538234f741.")
	assert_eq(R.team_room("not a match"), "")
