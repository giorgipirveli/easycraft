extends GutTest
## M3 Task 17 (spec §5.12, §14.12): the Shorts Theater's curated channel list; owner #89: the real list bundled with
## the game (data/theater/channels.json) and the server's copy. Parsing never fails and never lets a broken entry
## through. The sample list (placeholder ids, a TikTok channel) stays for the rules' tests.


func _list(channels: Array, extra: Dictionary = {}) -> String:
	var d := {"enabled": true, "source": "sample", "channels": channels}
	d.merge(extra, true)
	return JSON.stringify(d)


func _yt(id: String, videos: Array, title: String = "Channel") -> Dictionary:
	return {"id": id, "title": title, "platform": "youtube", "videos": videos}


func _video(id: String, kids: Variant = true, title: String = "A video") -> Dictionary:
	return {"id": id, "title": title, "made_for_kids": kids}


# --- The bundled lists -----------------------------------------------------------------------

func test_the_sample_list_parses() -> void:
	var list := TheaterChannels.load_path(TheaterChannels.SAMPLE_PATH)
	assert_true(list.enabled, "the Theater is on in the sample")
	assert_eq(list.source, TheaterChannels.SOURCE_SAMPLE)
	assert_gte(list.channels.size(), 4)
	assert_eq(list.channels[0].id, TheaterChannels.EASYCRAFT_TV, "EasyCraft TV is the first channel")
	assert_eq(list.channels[0].title, "EasyCraft TV")
	var platforms := {}
	for c: Dictionary in list.channels:
		platforms[c.platform] = true
		assert_gt(c.videos.size(), 0, "%s has videos" % c.id)
	assert_true(platforms.has(TheaterChannels.YOUTUBE))
	assert_true(platforms.has(TheaterChannels.TIKTOK), "the sample exercises the TikTok rules too")


## Owner #89: the list the game plays until it reads the server's: EasyCraft TV, then Space, Science, Nature and
## Animals, How Things Are Made, Music, Art, History; 6-12 real YouTube videos each, every one made for kids and
## named with its maker (each checked on its page: tools/theater_list.py check, docs/devlog/parts/tv-shows.md).
func test_the_bundled_list_is_real_and_made_for_kids() -> void:
	var list := TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)
	assert_true(list.enabled)
	assert_eq(list.source, TheaterChannels.SOURCE_BUNDLED)
	assert_eq(list.channels.map(func(c: Dictionary) -> String: return c.id),
		["easycraft_tv", "space", "science", "nature", "how_made", "music", "art", "history"])
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TheaterChannels.BUNDLED_PATH))
	var seen := {}
	var icons := {}
	for i in list.channels.size():
		var c: Dictionary = list.channels[i]
		assert_eq(c.platform, TheaterChannels.YOUTUBE, c.id)
		assert_between(c.videos.size(), 6, 12, "%s: 6-12 videos" % c.id)
		assert_eq(c.videos.size(), (raw.channels[i].videos as Array).size(), "%s: every video parses" % c.id)
		assert_false(icons.has(c.icon), "%s has a picture of its own" % c.id)
		icons[c.icon] = true
		for v: Dictionary in c.videos:
			assert_true(v.made_for_kids, "%s/%s made for kids" % [c.id, v.id])
			assert_ne(v.from, "", "%s/%s names its maker" % [c.id, v.id])
			assert_false(seen.has(v.id), "%s is in the list once" % v.id)
			seen[v.id] = true
	assert_gte(seen.size(), 60)


func test_no_list_holds_an_api_key() -> void:
	for path: String in [TheaterChannels.SAMPLE_PATH, TheaterChannels.BUNDLED_PATH]:
		var text := FileAccess.get_file_as_string(path)
		assert_ne(text, "", path)
		for word: String in ["key", "AIza", "secret", "token"]:
			assert_false(text.containsn("\"%s" % word) or text.contains(word + "\":"), "%s: no '%s' field" % [path, word])
		assert_false(text.contains("AIza"), "%s: no Google API key" % path)


func test_easycraft_tv_moves_to_the_front() -> void:
	var list := TheaterChannels.parse(_list([
		_yt("animals", [_video("AnimalSmpl1")]),
		_yt(TheaterChannels.EASYCRAFT_TV, [_video("ECtvSample1")], "EasyCraft TV"),
	]))
	assert_eq(list.channels.map(func(c: Dictionary) -> String: return c.id), [TheaterChannels.EASYCRAFT_TV, "animals"])


# --- Defensive parsing -------------------------------------------------------------------------

func test_broken_json_hides_the_theater() -> void:
	for text: String in ["", "{", "[]", "42", "null", "{\"channels\": 5}"]:
		var list := TheaterChannels.parse(text)
		assert_false(list.enabled, "fails closed: %s" % text)
		assert_eq(list.channels, [])


func test_the_kill_switch() -> void:
	var videos := [_video("ECtvSample1")]
	assert_false(TheaterChannels.parse(_list([_yt("a", videos)], {"enabled": false})).enabled)
	assert_false(TheaterChannels.parse(_list([_yt("a", videos)], {"enabled": "true"})).enabled, "a string is not a yes")
	assert_false(TheaterChannels.parse(_list([_yt("a", videos)], {"enabled": 1})).enabled, "a number is not a yes")
	var no_flag := JSON.stringify({"source": "sample", "channels": [_yt("a", videos)]})
	assert_false(TheaterChannels.parse(no_flag).enabled, "a list without the flag keeps the Theater hidden")
	assert_true(TheaterChannels.parse(_list([_yt("a", videos)])).enabled)


func test_the_source_is_sample_unless_it_says_server_or_bundled() -> void:
	var videos := [_video("ECtvSample1")]
	assert_eq(TheaterChannels.parse(_list([_yt("a", videos)], {"source": "server"})).source, TheaterChannels.SOURCE_SERVER)
	assert_eq(TheaterChannels.parse(_list([_yt("a", videos)], {"source": "bundled"})).source, TheaterChannels.SOURCE_BUNDLED)
	for source: Variant in ["Server", "", 3, null, "sample", "BUNDLED"]:
		assert_eq(TheaterChannels.parse(_list([_yt("a", videos)], {"source": source})).source, TheaterChannels.SOURCE_SAMPLE,
			"source %s" % [source])
	assert_false(TheaterChannels.is_real(TheaterChannels.parse(_list([_yt("a", videos)]))), "the sample is not real")
	assert_true(TheaterChannels.is_real(TheaterChannels.parse(_list([_yt("a", videos)], {"source": "bundled"}))))
	assert_true(TheaterChannels.is_real(TheaterChannels.parse(_list([_yt("a", videos)], {"source": "server"}))))


func test_video_ids_are_checked_per_platform() -> void:
	assert_true(TheaterChannels.is_video_id(TheaterChannels.YOUTUBE, "aqz-KE-bpKQ"))
	assert_true(TheaterChannels.is_video_id(TheaterChannels.YOUTUBE, "AB_cd-EF123"))
	assert_true(TheaterChannels.is_video_id(TheaterChannels.YOUTUBE, "--xEE7K67Xo"))
	assert_true(TheaterChannels.is_video_id(TheaterChannels.TIKTOK, "7000000000000000001"))
	for bad: String in ["", "short", "twelve_chars", "abc def ghi", "<script>xx>", "aqz-KE-bpK\"", "../../../...",
			"aqz-KE-bpK'", "aqz-KE-bp\\n"]:
		assert_false(TheaterChannels.is_video_id(TheaterChannels.YOUTUBE, bad), "youtube %s" % bad)
	for bad: String in ["", "12345", "7000000000000000001a", "-7000000000000", "1".repeat(30)]:
		assert_false(TheaterChannels.is_video_id(TheaterChannels.TIKTOK, bad), "tiktok %s" % bad)
	assert_false(TheaterChannels.is_video_id(&"vimeo", "12345678"), "unknown platform")


func test_bad_videos_and_channels_are_dropped() -> void:
	var list := TheaterChannels.parse(_list([
		_yt("good", [_video("ECtvSample1"), _video("bad id"), "not a dict", {"title": "no id"}, _video("ECtvSample1", true, "repeat")]),
		{"id": "Bad Id!", "title": "x", "platform": "youtube", "videos": [_video("ECtvSample2")]},
		{"id": "vimeo", "title": "x", "platform": "vimeo", "videos": [_video("ECtvSample2")]},
		{"id": "empty", "title": "x", "platform": "youtube", "videos": []},
		{"id": "novideos", "title": "x", "platform": "youtube", "videos": "lots"},
		_yt("good", [_video("ECtvSample3")]),
		"not a channel",
		{"id": "tt", "title": "x", "platform": "tiktok", "videos": [_video("ECtvSample2")]},
	]))
	assert_eq(list.channels.size(), 1, "only the first 'good' channel survives")
	assert_eq(list.channels[0].id, "good")
	assert_eq(list.channels[0].videos.size(), 1, "the bad and repeated videos are gone")
	assert_eq(list.channels[0].videos[0].id, "ECtvSample1")


func test_made_for_kids_must_be_a_real_yes() -> void:
	var list := TheaterChannels.parse(_list([_yt("c", [
		_video("KidsVideo01", true), _video("KidsVideo02", "true"), _video("KidsVideo03", 1),
		_video("KidsVideo04", false), {"id": "KidsVideo05", "title": "missing flag"}])]))
	var flags: Array = list.channels[0].videos.map(func(v: Dictionary) -> bool: return v.made_for_kids)
	assert_eq(flags, [true, false, false, false, false])


func test_titles_are_trimmed_capped_and_never_empty() -> void:
	var long_title := "A".repeat(200)
	var list := TheaterChannels.parse(_list([_yt("c", [_video("KidsVideo01", true, "  Hi  "), _video("KidsVideo02", true, long_title),
		{"id": "KidsVideo03", "made_for_kids": true, "title": 7}, _video("KidsVideo04", true, "   ")], "   ")]))
	var c: Dictionary = list.channels[0]
	assert_eq(c.title, "Channel", "an empty channel title gets a name")
	assert_eq(c.videos[0].title, "Hi")
	assert_eq(c.videos[1].title.length(), TheaterChannels.MAX_TITLE)
	assert_eq(c.videos[2].title, "7")
	assert_eq(c.videos[3].title, "Video")


func test_channel_colour_falls_back() -> void:
	var list := TheaterChannels.parse(_list([
		{"id": "a", "title": "A", "platform": "youtube", "color": "#2fae4e", "videos": [_video("KidsVideo01")]},
		{"id": "b", "title": "B", "platform": "youtube", "color": "rainbow", "videos": [_video("KidsVideo01")]},
		{"id": "c", "title": "C", "platform": "youtube", "videos": [_video("KidsVideo01")]}]))
	assert_eq(list.channels[0].color, Color("2fae4e"))
	assert_eq(list.channels[1].color, TheaterChannels.DEFAULT_COLOR)
	assert_eq(list.channels[2].color, TheaterChannels.DEFAULT_COLOR)


## Owner #89: a channel's picture for its tab (TheaterIcons draws it) and each video's maker (shown on its card).
func test_icons_and_makers() -> void:
	var list := TheaterChannels.parse(_list([
		{"id": "a", "title": "A", "platform": "youtube", "icon": "planet", "videos": [
			{"id": "KidsVideo01", "title": "x", "made_for_kids": true, "from": "  NASA Space Place  "},
			{"id": "KidsVideo02", "title": "x", "made_for_kids": true, "from": "M".repeat(80)},
			{"id": "KidsVideo03", "title": "x", "made_for_kids": true, "from": 42},
			{"id": "KidsVideo04", "title": "x", "made_for_kids": true}]},
		{"id": "b", "title": "B", "platform": "youtube", "icon": "skull", "videos": [_video("KidsVideo01")]},
		{"id": "c", "title": "C", "platform": "youtube", "icon": 3, "videos": [_video("KidsVideo01")]}]))
	assert_eq(list.channels[0].icon, &"planet")
	assert_eq(list.channels[1].icon, TheaterChannels.DEFAULT_ICON, "an unknown picture: the TV")
	assert_eq(list.channels[2].icon, TheaterChannels.DEFAULT_ICON)
	var makers: Array = list.channels[0].videos.map(func(v: Dictionary) -> String: return v.from)
	assert_eq(makers[0], "NASA Space Place")
	assert_eq((makers[1] as String).length(), TheaterChannels.MAX_FROM)
	assert_eq(makers[2], "", "a maker is words")
	assert_eq(makers[3], "")
	for icon: StringName in TheaterChannels.ICONS:
		var one := TheaterChannels.parse(_list([{"id": "a", "title": "A", "platform": "youtube", "icon": String(icon),
			"videos": [_video("KidsVideo01")]}]))
		assert_eq(one.channels[0].icon, icon, String(icon))


func test_lists_are_capped() -> void:
	var videos: Array = []
	for i in TheaterChannels.MAX_VIDEOS + 10:
		videos.append(_video("Video%06d" % i))
	var channels: Array = []
	for i in TheaterChannels.MAX_CHANNELS + 5:
		channels.append(_yt("c%d" % i, videos))
	var list := TheaterChannels.parse(_list(channels))
	assert_eq(list.channels.size(), TheaterChannels.MAX_CHANNELS)
	assert_eq(list.channels[0].videos.size(), TheaterChannels.MAX_VIDEOS)


func test_a_missing_file_hides_the_theater() -> void:
	var list := TheaterChannels.load_path("res://data/theater/does_not_exist.json")
	assert_false(list.enabled)
	assert_eq(list.channels, [])
