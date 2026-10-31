extends GutTest
## The co-op games' shared rules and words (M4 Wave 3, agent H; spec §17.5, §6): who plays (players and
## bot friends, by key), when a round may start (no round, wave or boss on; hide-and-seek needs two),
## everyone's same sticker, and short, kind words on the HUD's round line (no rush, no losers).

const G := preload("res://core/games/game_rules.gd")
const W := preload("res://core/games/game_words.gd")


func test_players_and_bots_have_keys() -> void:
	assert_eq(G.player_key(7), "p7")
	assert_eq(G.bot_key("Pip"), "bPip")
	assert_eq(G.peer_of("p7"), 7)
	assert_eq(G.peer_of("bPip"), 0)
	assert_eq(G.peer_of("p"), 0)
	assert_eq(G.bot_of("bPip"), "Pip")
	assert_eq(G.bot_of("p7"), "")
	assert_true(G.is_bot("bPip"))
	assert_false(G.is_bot("p7"))


func test_a_round_starts_only_when_nothing_else_is_on() -> void:
	assert_eq(G.start_refusal(G.HIDE_SEEK, false, &"", 2), &"")
	assert_eq(G.start_refusal(G.STORM_RUN, false, &"", 1), &"", "Storm Run alone is fine")
	assert_eq(G.start_refusal(G.HIDE_SEEK, false, &"", 1), G.ALONE, "hide-and-seek needs a friend")
	assert_eq(G.start_refusal(G.HIDE_SEEK, true, &"", 3), G.RUNNING)
	assert_eq(G.start_refusal(G.STORM_RUN, false, &"wave", 3), G.WAVE)
	assert_eq(G.start_refusal(G.STORM_RUN, false, &"boss", 3), G.BOSS)
	assert_eq(G.start_refusal(&"tag", false, &"", 3), G.UNKNOWN)
	for key: StringName in [G.ALONE, G.RUNNING, G.WAVE, G.BOSS]:
		assert_ne(W.refusal(key), "", "%s has words" % key)
	assert_eq(W.refusal(G.UNKNOWN), "", "nothing to say to a request no game makes")


func test_everyone_gets_the_same_sticker() -> void:
	assert_eq(G.KINDS, [G.HIDE_SEEK, G.STORM_RUN] as Array[StringName])
	for kind in G.KINDS:
		assert_true(G.STICKERS.has(String(kind)), "%s has a sticker" % kind)
	var p := ProfileData.new()
	assert_eq(p.add_sticker(G.HIDE_SEEK), 1)
	assert_eq(p.add_sticker(G.HIDE_SEEK), 2)
	assert_eq(p.add_sticker(&"gold"), 0, "only the games' stickers")
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.stickers, {"hide_seek": 2}, "kept in the profile")
	var odd := ProfileData.from_json('{"stickers": {"hide_seek": -3, "storm_run": 2.0, "nope": 4, "x": "y"}}')
	assert_eq(odd.stickers, {"storm_run": 2}, "broken counts are dropped")
	var merged: ProfileData = ProfileBackup.merge(p, back.to_json().replace('"hide_seek": 2', '"hide_seek": 5')).profile
	assert_eq(int(merged.stickers.hide_seek), 5, "a backup never loses a sticker")


func test_the_round_line_is_short_and_kind() -> void:
	assert_eq(W.clock(161.2), "2:42")
	assert_eq(W.clock(0.0), "0:00")
	assert_eq(W.clock(-3.0), "0:00")
	var r := HideSeekRound.new()
	r.start(["p1", "p2", "bPip"] as Array[String], "p1", Vector3.ZERO)
	assert_eq(W.hide_line(r, "p2"), "Hide! 0:30")
	assert_eq(W.hide_line(r, "p1"), "Counting... 30")
	r.advance(HideSeekRound.COUNT_TIME + 1.0)
	r.find("p1", "p2")
	assert_eq(W.hide_line(r, "p1"), "Find them! 1 of 2 found · 2:59")
	assert_eq(W.hide_line(r, "bPip"), "Stay hidden! 2:59")
	assert_eq(W.hide_line(r, "p9"), "Hide-and-seek · 2:59", "someone watching")
	var s := StormRun.new()
	s.start([Vector2.ZERO] as Array[Vector2])
	s.best = 12
	s.take(s.add_star(Vector3(0, 65, 0)))
	assert_eq(W.storm_line(s), "Stars: 1 · 3:00 · Best 12")
	var lines: Array[String] = [W.found("Mia", "Pip (bot)"), W.found_you("Mia"), W.you_found("Max"), W.SEEK_START,
		W.HINT, W.end_hide(HideSeekRound.ALL_FOUND), W.end_hide(HideSeekRound.TIME_UP), W.end_hide(HideSeekRound.ENDED),
		W.end_storm(7, false), W.end_storm(9, true), W.sticker(G.HIDE_SEEK, 3), W.seeker_is("Mia"), W.YOU_SEEK,
		W.STORM_START, W.PUSHED, W.AREA, W.PHOTO_OFFER, W.SAY_CHEESE, W.BOT_COUNTING, W.BOT_SEEK, W.bot_found("Mia"),
		W.BOT_FOUND_ME, W.WAVE_WAITS, W.NOBODY, W.CLOSER, W.PHOTO_BUTTON, W.BOT_STAR, W.PUSHED]
	for l in lines:
		assert_ne(l, "")
		assert_lte(l.split(" ").size(), 10, l)
	assert_eq(W.end_storm(9, true), "Your team got 9 stars! A new best!")
	assert_eq(W.sticker(G.STORM_RUN, 1), "Everyone gets a Storm Run sticker! You have 1.")
