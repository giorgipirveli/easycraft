extends GutTest
## M3 Task 12 (spec §14.11, research C5): about twenty badges for the trophy room, each unlocked once by
## play (never for logging in or for time played), each with a picture and a few words.


func test_about_twenty_badges_with_pictures_and_short_words() -> void:
	assert_between(AchievementRules.BADGES.size(), 18, 26)
	var ids := {}
	for b: Dictionary in AchievementRules.BADGES:
		assert_false(ids.has(b.id), "one of each: %s" % b.id)
		ids[b.id] = true
		assert_lte(str(b.words).split(" ").size(), 4, str(b.words))
		assert_true(ProgressPictures.knows(b.picture), "%s has a picture" % b.id)
		assert_true(b.kind == AchievementRules.LEVEL or LevelRules.is_kind(b.kind), "%s counts real play" % b.id)
		assert_gt(int(b.need), 0)
	assert_true(AchievementRules.badge(&"first_pet").size() > 0)
	assert_eq(AchievementRules.badge(&"no_such_badge"), {})


func test_a_badge_unlocks_once() -> void:
	var d := ProgressData.new()
	assert_eq(AchievementRules.check(d), [] as Array[StringName])
	d.record(&"animal_tamed/dog")
	assert_eq(AchievementRules.check(d), [&"first_pet"] as Array[StringName])
	assert_eq(d.achievements, ["first_pet"] as Array[String])
	d.record(&"animal_tamed/cat")
	assert_eq(AchievementRules.check(d), [] as Array[StringName], "never twice")
	assert_eq(d.achievements, ["first_pet"] as Array[String])


func test_several_badges_can_come_at_once_in_list_order() -> void:
	var d := ProgressData.new()
	d.record(&"secret_found/geode")
	var got := AchievementRules.check(d)
	assert_eq(got, [&"first_secret", &"crystal_cave"] as Array[StringName])


func test_counted_badges_wait_for_their_number() -> void:
	var d := ProgressData.new()
	d.record(&"block_placed", 99)
	assert_does_not_have(AchievementRules.check(d), &"builder")
	d.record(&"block_placed", 1)
	assert_has(AchievementRules.check(d), &"builder")
	assert_eq(AchievementRules.progress(d, &"big_builder"), Vector2i(100, 1000))


func test_level_badges_follow_the_level() -> void:
	var d := ProgressData.new()
	d.xp = LevelRules.xp_to_reach(5) - 1
	assert_does_not_have(AchievementRules.check(d), &"level_5")
	d.xp += 1
	assert_has(AchievementRules.check(d), &"level_5")
	assert_eq(AchievementRules.progress(d, &"level_10"), Vector2i(5, 10))


func test_no_badge_is_for_logging_in_or_time_played() -> void:
	for b: Dictionary in AchievementRules.BADGES:
		var words := str(b.words).to_lower() + " " + String(b.kind)
		for w in ["login", "log in", "day", "daily", "minute", "hour", "played for", "streak"]:
			assert_false(words.contains(w), "%s: %s" % [b.id, w])


func test_unlocked_counts_for_the_room() -> void:
	var d := ProgressData.new()
	d.achievements = ["first_pet", "first_secret"] as Array[String]
	assert_eq(AchievementRules.unlocked_count(d), 2)
	d.achievements.append("made_up")
	assert_eq(AchievementRules.unlocked_count(d), 2, "only real badges count")
