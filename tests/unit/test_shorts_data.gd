extends GutTest
## Owner #94 (spec §5.12b): the Shorts a child liked (a heart: kept on the device, no counts, no one else sees it) and
## the ones already seen (marked in the feed), in the profile and its backup.


func test_a_heart_likes_and_unlikes() -> void:
	var d := ShortsData.new()
	assert_false(d.is_liked("rocket_parts"))
	assert_true(d.like("rocket_parts", 100))
	assert_true(d.is_liked("rocket_parts"))
	d.unlike("rocket_parts", 200)
	assert_false(d.is_liked("rocket_parts"))
	assert_true(d.toggle_like("rocket_parts", 300), "toggled back on")
	assert_true(d.is_liked("rocket_parts"))


func test_the_liked_list_is_newest_first() -> void:
	var d := ShortsData.new()
	d.like("moon_phases", 100)
	d.like("lesson:g4.science.circuits", 300)
	d.like("water_cycle", 200)
	d.like("lever", 250)
	d.unlike("lever", 260)
	assert_eq(d.liked_ids(), ["lesson:g4.science.circuits", "water_cycle", "moon_phases"] as Array[String])


func test_seen_is_marked_once() -> void:
	var d := ShortsData.new()
	assert_false(d.is_seen("rocket_parts"))
	d.mark_seen("rocket_parts")
	d.mark_seen("rocket_parts")
	assert_true(d.is_seen("rocket_parts"))
	assert_eq(d.seen.size(), 1)


func test_bad_ids_are_refused() -> void:
	var d := ShortsData.new()
	assert_false(d.like("", 1))
	assert_false(d.like("Has Spaces", 1))
	assert_false(d.like("x".repeat(80), 1))
	d.mark_seen("<script>")
	assert_true(d.is_empty())


func test_it_keeps_at_most_its_limits() -> void:
	var d := ShortsData.new()
	for i in ShortsData.MAX_SEEN + 20:
		d.mark_seen("s%d" % i)
	assert_eq(d.seen.size(), ShortsData.MAX_SEEN)
	assert_true(d.is_seen("s%d" % (ShortsData.MAX_SEEN + 19)), "the newest are kept")
	for i in ShortsData.MAX_LIKED + 20:
		d.like("l%d" % i, 1000 + i)
	assert_eq(d.liked.size(), ShortsData.MAX_LIKED)
	assert_true(d.is_liked("l%d" % (ShortsData.MAX_LIKED + 19)))


func test_it_round_trips_and_cleans_junk() -> void:
	var d := ShortsData.new()
	d.like("rocket_parts", 100)
	d.unlike("moon_phases", 90)
	d.mark_seen("lesson:g3.maths.numbers_to_10000")
	var back := ShortsData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_true(back.is_liked("rocket_parts"))
	assert_false(back.is_liked("moon_phases"))
	assert_true(back.is_seen("lesson:g3.maths.numbers_to_10000"))
	var junk := ShortsData.from_dict({"liked": {"ok_one": 5, "Bad Id": 5, "nan_one": "x", "inf": INF}, "seen": [3, "fine", null]})
	assert_eq(junk.liked.keys(), ["ok_one"])
	assert_eq(junk.seen, ["fine"] as Array[String])
	assert_true(ShortsData.from_dict("nonsense").is_empty())


func test_the_profile_keeps_them() -> void:
	var p := ProfileData.new()
	p.shorts.like("rocket_parts", 100)
	p.shorts.mark_seen("water_cycle")
	var back := ProfileData.from_json(p.to_json())
	assert_true(back.shorts.is_liked("rocket_parts"))
	assert_true(back.shorts.is_seen("water_cycle"))
	assert_true(ProfileData.from_json("{}").shorts.is_empty(), "an old profile has none")


func test_the_backup_merges_seen_and_the_newest_heart_wins() -> void:
	var here := ProfileData.new()
	here.username = "Kid"
	here.updated_at = 500
	here.shorts.like("rocket_parts", 100)
	here.shorts.unlike("moon_phases", 400)   # un-liked here after the other device liked it
	here.shorts.mark_seen("rocket_parts")
	var there := ProfileData.new()
	there.username = "Kid"
	there.updated_at = 900   # the newer copy
	there.shorts.like("moon_phases", 300)
	there.shorts.like("water_cycle", 350)
	there.shorts.mark_seen("water_cycle")
	var merged: ProfileData = ProfileBackup.merge(here, ProfileBackup.to_backup(there)).profile
	assert_true(merged.shorts.is_liked("rocket_parts"), "a heart only here stays")
	assert_true(merged.shorts.is_liked("water_cycle"), "a heart only there comes")
	assert_false(merged.shorts.is_liked("moon_phases"), "the later un-heart wins, whichever copy is newer")
	assert_true(merged.shorts.is_seen("rocket_parts") and merged.shorts.is_seen("water_cycle"), "seen from both")
