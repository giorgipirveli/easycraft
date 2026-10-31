extends GutTest
## The M4 Task 10 review's finding B (module 0.2.11): online, the host names its players and checks its relay chat
## and trades with the server's word (match_players), never a guest's own claim. The server's answer is read
## carefully: a player needs a user id; a name that is not a username is none (the host says "Player"); a band that
## is not one reads as under 13; a chat level that is not one reads as off.


func test_the_servers_answer_by_user_id() -> void:
	var out := MatchRoster.players_from({"ok": true, "players": [
		{"user_id": "u-mia", "username": "Mia", "age_band": "13_plus", "chat_level": "filtered"},
		{"user_id": "u-kid", "username": "Kiddo", "age_band": "under_13", "chat_level": "quick"},
	]})
	assert_eq(out.size(), 2)
	assert_eq(out["u-mia"], {"username": "Mia", "age_band": AgeBand.TEEN_PLUS, "chat_level": OnlineRules.CHAT_FILTERED})
	assert_eq(out["u-kid"], {"username": "Kiddo", "age_band": AgeBand.UNDER_13, "chat_level": OnlineRules.CHAT_QUICK})


func test_anything_odd_reads_as_the_strictest() -> void:
	var out := MatchRoster.players_from({"ok": true, "players": [
		{"user_id": "u-1", "username": "call me 5551234567", "age_band": "adult", "chat_level": "shout"},
		{"user_id": "u-2", "username": 7, "age_band": 13, "chat_level": null},
	]})
	for id: String in ["u-1", "u-2"]:
		assert_eq(out[id].username, "", "%s: not a username" % id)
		assert_eq(out[id].age_band, AgeBand.UNDER_13, "%s: the child's rules" % id)
		assert_eq(out[id].chat_level, OnlineRules.CHAT_OFF, "%s: no chat" % id)


func test_entries_without_a_user_id_and_failed_answers_give_nobody() -> void:
	var out := MatchRoster.players_from({"ok": true, "players": ["junk", {"username": "Mia"}, {"user_id": ""},
		{"user_id": 42, "username": "Num"}]})
	assert_eq(out, {})
	assert_eq(MatchRoster.players_from({"ok": false, "error": "not_host"}), {})
	assert_eq(MatchRoster.players_from({"ok": true, "players": "everyone"}), {})
	assert_eq(MatchRoster.players_from({}), {})
