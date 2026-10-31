extends GutTest
## M3 Task 17 (spec §5.12, §6, §16 H6): moving through the Theater's videos. Next and previous,
## channels, the end card ("That's the show!") after 5 videos for a child, and no rewards of any kind for
## watching. Owner #89: the video cards (pick_video), and nothing moves on by itself.

const KID := AgeBand.UNDER_13
const TEEN := AgeBand.TEEN_PLUS


func _list(channels: Array) -> Dictionary:
	return TheaterChannels.parse(JSON.stringify({"enabled": true, "source": "sample", "channels": channels}))


## Channel `id` with `n` kids' videos named <id>0000001 ... (11 characters).
func _channel(id: String, n: int, kids: bool = true, platform: String = "youtube") -> Dictionary:
	var videos: Array = []
	for i in n:
		var vid := ("%s%s" % [id, "0".repeat(11)]).left(9) + "%02d" % i
		if platform == "tiktok":
			vid = "70000000000%d" % (100 + i)
		videos.append({"id": vid, "title": "%s %d" % [id, i + 1], "made_for_kids": kids})
	return {"id": id, "title": id.capitalize(), "platform": platform, "videos": videos}


func _titles_while_next(s: TheaterSession, taps: int) -> Array:
	var out: Array = [s.current().title]
	for i in taps:
		s.next()
		out.append(s.current().title if s.state == TheaterSession.PLAYING else "END")
	return out


func test_it_starts_on_the_first_video_of_easycraft_tv() -> void:
	var s := TheaterSession.new(_list([_channel("animals", 2), _channel("easycraft_tv", 2)]), KID)
	assert_eq(s.state, TheaterSession.PLAYING)
	assert_eq(s.current().channel_id, "easycraft_tv")
	assert_eq(s.current().title, "easycraft_tv 1")
	assert_eq(s.current().platform, TheaterChannels.YOUTUBE)
	assert_eq(s.shown, 1)
	assert_false(s.can_go_back())


func test_next_and_previous_walk_through_channels_in_order() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 2), _channel("animals", 2)]), TEEN)
	assert_true(s.next())
	assert_eq(s.current().title, "easycraft_tv 2")
	assert_true(s.next())
	assert_eq(s.current().title, "animals 1", "the next channel follows")
	assert_true(s.can_go_back())
	assert_true(s.previous())
	assert_eq(s.current().title, "easycraft_tv 2", "back across the channel edge")
	assert_true(s.previous())
	assert_eq(s.current().title, "easycraft_tv 1")
	assert_false(s.previous(), "nothing before the first video")
	assert_eq(s.current().title, "easycraft_tv 1")


func test_the_end_card_after_5_videos_for_a_child() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 9)]), KID)
	var seen := _titles_while_next(s, 5)
	assert_eq(seen, ["easycraft_tv 1", "easycraft_tv 2", "easycraft_tv 3", "easycraft_tv 4", "easycraft_tv 5", "END"])
	assert_eq(s.state, TheaterSession.END_CARD)
	assert_eq(s.end_reason, TheaterSession.END_LIMIT)
	assert_false(s.next(), "the end card stays until the child chooses")
	assert_false(s.previous())
	assert_eq(s.state, TheaterSession.END_CARD)


func test_going_back_counts_too() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 9)]), KID)
	for i in 2:
		s.next()
	for i in 2:
		s.previous()
	assert_eq(s.shown, 5)
	s.next()
	assert_eq(s.state, TheaterSession.END_CARD, "5 videos shown, whichever way")


func test_more_shows_continues_and_counts_again() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 9)]), KID)
	for i in 5:
		s.next()
	s.more()
	assert_eq(s.state, TheaterSession.PLAYING)
	assert_eq(s.current().title, "easycraft_tv 6", "the next new video")
	assert_eq(s.shown, 1)
	assert_eq(_titles_while_next(s, 5)[-1], "END", "and the card comes again after 5 more")


func test_13_plus_has_a_later_end_card() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 30)]), TEEN)
	var limit := TheaterRules.end_card_after(TEEN)
	for i in limit - 1:
		assert_true(s.next())
		assert_eq(s.state, TheaterSession.PLAYING)
	s.next()
	assert_eq(s.state, TheaterSession.END_CARD)


func test_the_end_of_the_list_shows_the_card_and_more_starts_again() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 2)]), TEEN)
	s.next()
	s.next()
	assert_eq(s.state, TheaterSession.END_CARD)
	assert_eq(s.end_reason, TheaterSession.END_LIST)
	s.more()
	assert_eq(s.current().title, "easycraft_tv 1", "from the start, never an endless feed")


## Owner #89: nothing moves on by itself, for anyone: the session only moves when the child picks.
func test_the_session_never_moves_by_itself() -> void:
	assert_false(TheaterSession.new(_list([_channel("easycraft_tv", 3)]), TEEN).has_method("video_ended"),
		"the end of a video changes nothing here: the panel lights NEXT up")


## Owner #89: the cards under the player: a tap on one plays that video of the channel.
func test_picking_a_video_card() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 3), _channel("animals", 6)]), KID)
	assert_true(s.pick_channel(1))
	assert_true(s.pick_video(4))
	assert_eq(s.current().title, "animals 5")
	assert_eq(s.current().index, 4)
	assert_eq(s.current().count, 6)
	assert_eq(s.shown, 3, "a card counts like NEXT")
	assert_false(s.pick_video(6), "no such video")
	assert_false(s.pick_video(-1))
	assert_eq(s.current().title, "animals 5")
	assert_true(s.pick_video(0))
	assert_true(s.pick_video(1))
	assert_eq(s.shown, 5)
	assert_eq(s.state, TheaterSession.PLAYING)
	assert_true(s.pick_video(2))
	assert_eq(s.state, TheaterSession.END_CARD, "after 5 videos for a child, the next pick shows the card")


func test_the_current_video_says_what_its_card_shows() -> void:
	var list := TheaterChannels.parse(JSON.stringify({"enabled": true, "channels": [{"id": "space", "title": "Space",
		"platform": "youtube", "icon": "planet", "color": "#4b3fb0",
		"videos": [{"id": "mibxJwpennU", "title": "Paxi", "made_for_kids": true, "from": "European Space Agency, ESA"}]}]}))
	var v := TheaterSession.new(list, TEEN).current()
	assert_eq(v.channel, "Space")
	assert_eq(v.channel_id, "space")
	assert_eq(v.icon, &"planet")
	assert_eq(v.color, Color("4b3fb0"))
	assert_eq(v.id, "mibxJwpennU")
	assert_eq(v.from, "European Space Agency, ESA")
	assert_eq(v.index, 0)
	assert_eq(v.count, 1)


func test_picking_a_channel() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 3), _channel("animals", 3)]), KID)
	assert_true(s.pick_channel(1))
	assert_eq(s.current().title, "animals 1")
	assert_eq(s.channel, 1)
	assert_eq(s.shown, 2)
	assert_false(s.pick_channel(7), "no such channel")
	assert_false(s.pick_channel(-1))


func test_nobody_gets_tiktok_or_videos_not_made_for_kids() -> void:
	for band: StringName in [KID, TEEN]:
		var s := TheaterSession.new(_list([_channel("easycraft_tv", 2), _channel("grown", 3, false),
			_channel("tt", 2, true, "tiktok")]), band)
		assert_eq(s.channels.size(), 1, String(band))
		var seen := _titles_while_next(s, 4)
		for t: String in seen:
			assert_false(t.begins_with("grown") or t.begins_with("tt"), "%s: %s" % [band, t])


func test_an_empty_list() -> void:
	var s := TheaterSession.new(_list([_channel("grown", 2, false)]), KID)
	assert_true(s.is_empty())
	assert_eq(s.current(), {})
	assert_false(s.next())
	assert_false(s.previous())
	assert_false(s.pick_video(0))


func test_closing() -> void:
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 3)]), KID)
	s.close()
	assert_eq(s.state, TheaterSession.CLOSED)
	assert_false(s.next())


# --- No rewards for watching (spec §6) ----------------------------------------------------------

func test_watching_gives_nothing() -> void:
	var profile := ProfileData.new()
	var gold := profile.survivor_gold
	var s := TheaterSession.new(_list([_channel("easycraft_tv", 9)]), TEEN)
	for i in 20:
		s.next()
		s.pick_video(0)
		if s.state == TheaterSession.END_CARD:
			s.more()
	assert_eq(profile.survivor_gold, gold)
	for sig: Dictionary in s.get_signal_list():
		for word: String in ["gold", "reward", "xp", "coin", "prize", "earn"]:
			assert_false(String(sig.name).containsn(word), "no '%s' signal: %s" % [word, sig.name])


func test_theater_code_has_no_reward_hooks() -> void:
	var paths := ["res://core/theater/theater_channels.gd", "res://core/theater/theater_rules.gd",
		"res://core/theater/theater_session.gd", "res://core/theater/theater_embed.gd",
		"res://ui/theater/theater_panel.gd", "res://ui/theater/theater_still.gd",
		"res://ui/theater/theater_webview.gd", "res://entities/theater/theater_director.gd",
		"res://entities/theater/theater_building.gd", "res://core/theater/theater_feed.gd",
		"res://ui/theater/theater_web_player.gd", "res://ui/theater/theater_icons.gd"]
	var hooks := RegEx.create_from_string("(?i:\\b(gold|wallet|rewards?|xp|coins?|earn|prize)\\b)|\\bSession\\.|CoinShower")
	for path: String in paths:
		var text := FileAccess.get_file_as_string(path)
		assert_ne(text, "", "%s exists" % path)
		for line: String in text.split("\n"):
			var code := line.strip_edges()
			if code.begins_with("#"):
				continue
			var hit := hooks.search(code)
			assert_null(hit, "%s: a reward hook in code: %s" % [path.get_file(), code])
