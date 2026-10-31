extends GutTest
## M3 Task 12: the progress part of the profile (XP, counts, the board, badges, stickers, the present
## clock), parsed defensively: old profiles load, bad data never breaks the rest of the profile.


func test_an_event_counts_its_family_and_its_detail_and_gives_xp() -> void:
	var d := ProgressData.new()
	assert_eq(d.level(), 1)
	assert_eq(d.record(&"animal_tamed/dog"), 30)
	assert_eq(d.count(&"animal_tamed/dog"), 1)
	assert_eq(d.count(&"animal_tamed"), 1)
	assert_eq(d.count(&"animal_tamed/cat"), 0)
	d.record(&"animal_tamed/cat")
	assert_eq(d.count(&"animal_tamed"), 2)
	assert_eq(d.xp, 60)
	assert_eq(int(d.style_xp.get("animals", 0)), 60)


func test_a_batch_counts_every_block_but_its_xp_is_capped() -> void:
	var d := ProgressData.new()
	assert_eq(d.record(&"block_placed", 200), 5)
	assert_eq(d.count(&"block_placed"), 200)
	assert_eq(d.xp, 5)


func test_unknown_kinds_count_nothing() -> void:
	var d := ProgressData.new()
	assert_eq(d.record(&"minutes_played", 30), 0)
	assert_eq(d.record(&"photo_taken", 0), 0)
	assert_eq(d.counts, {})
	assert_eq(d.xp, 0)


func test_goals_give_xp_but_no_style() -> void:
	var d := ProgressData.new()
	d.record(&"goal_done")
	assert_eq(d.xp, 50)
	assert_eq(d.style_xp, {})


func test_round_trip() -> void:
	var d := ProgressData.new()
	d.record(&"secret_found/geode", 2)
	d.record(&"block_placed", 3)
	d.title = &"hunter"
	d.board = [{"goal": "find_geode", "start": 1, "done": false}, {"goal": "", "start": 0, "done": false},
		{"goal": "take_photo", "start": 0, "done": true}]
	d.board_set = true
	d.achievements = ["first_secret", "crystal_cave"] as Array[String]
	d.stickers = {"take_photo": 2, "gift_flower": 1}
	d.present_s = 321.5
	d.presents = 4
	d.present_waiting = true
	var e := ProgressData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_eq(e.xp, d.xp)
	assert_eq(e.counts, d.counts)
	assert_eq(e.style_xp, d.style_xp)
	assert_eq(e.title, &"hunter")
	assert_eq(e.board, d.board)
	assert_true(e.board_set)
	assert_eq(e.achievements, d.achievements)
	assert_eq(e.stickers, d.stickers)
	assert_almost_eq(e.present_s, 321.5, 0.001)
	assert_eq(e.presents, 4)
	assert_true(e.present_waiting)


func test_bad_data_falls_back_field_by_field() -> void:
	var e := ProgressData.from_dict({"xp": "lots", "counts": {"photo_taken": 3, "cheat": 999, "block_placed": -4,
		"secret_found": NAN, "monster_defeated/slime": 2.0}, "style_xp": {"builder": 40, "nope": 5, "photo": INF},
		"title": 7, "board": [{"goal": "take_photo", "start": "x"}, "junk", {"goal": "no_such_goal", "start": 0},
		{"goal": "find_geode", "start": 1, "done": true}, {"goal": "take_photos", "start": 0}],
		"achievements": ["first_pet", 3, "first_pet", "made_up"], "stickers": {"take_photo": 2, "zzz": 1, "gift_star": -1},
		"present_s": -50, "presents": "many", "present_waiting": "yes"})
	assert_eq(e.xp, 0)
	assert_eq(e.counts, {"photo_taken": 3, "monster_defeated/slime": 2}, "known kinds with finite counts above 0")
	assert_eq(e.style_xp, {"builder": 40})
	assert_eq(e.title, &"")
	assert_eq(e.board.size(), BoardRules.SLOTS, "always three slots")
	assert_eq(e.board[0], {"goal": "take_photo", "start": 0, "done": false}, "a bad start is 0")
	assert_eq(e.board[1], {"goal": "", "start": 0, "done": false}, "an unknown goal leaves the slot empty")
	assert_eq(e.board[2], {"goal": "", "start": 0, "done": false})
	assert_eq(e.achievements, ["first_pet"] as Array[String])
	assert_eq(e.stickers, {"take_photo": 2})
	assert_eq(e.present_s, 0.0)
	assert_eq(e.presents, 0)
	assert_false(e.present_waiting)


func test_not_a_dictionary_is_a_new_start() -> void:
	for v: Variant in [null, 3, "progress", [1, 2]]:
		var e := ProgressData.from_dict(v)
		assert_eq(e.xp, 0)
		assert_true(e.is_empty())


func test_an_absurd_xp_is_capped_at_the_top_level() -> void:
	var e := ProgressData.from_dict({"xp": 999999999, "counts": {"photo_taken": 2}})
	assert_eq(e.xp, ProgressData.MAX_XP)
	assert_eq(ProgressData.MAX_XP, LevelRules.xp_to_reach(LevelRules.MAX_LEVEL))
	assert_eq(e.level(), LevelRules.MAX_LEVEL)


func test_the_profile_keeps_progress() -> void:
	var p := ProfileData.new()
	p.username = "Hopper"
	p.progress.record(&"photo_taken")
	p.progress.achievements.append("say_cheese")
	var q := ProfileData.from_json(p.to_json())
	assert_eq(q.progress.xp, 5)
	assert_eq(q.progress.count(&"photo_taken"), 1)
	assert_eq(q.progress.achievements, ["say_cheese"] as Array[String])
	assert_eq(q.username, "Hopper", "other fields survive")


func test_an_old_profile_without_progress_starts_fresh() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop","age_band":"13_plus","survivor_gold":40}')
	assert_eq(q.progress.xp, 0)
	assert_true(q.progress.is_empty())
	assert_eq(q.survivor_gold, 40)
	assert_true(q.is_onboarded())


func test_broken_progress_never_breaks_the_profile() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop","age_band":"13_plus","survivor_gold":40,"progress":"lots"}')
	assert_true(q.progress.is_empty())
	assert_eq(q.username, "Hop")
	assert_eq(q.survivor_gold, 40)


## The server backup (M4 F) never loses progress: whichever copy wins, the best of both is kept.
func test_the_backup_merge_keeps_the_best_of_both() -> void:
	var local := ProfileData.new()
	local.username = "Hop"
	local.age_band = AgeBand.TEEN_PLUS
	local.updated_at = 2000
	local.progress.record(&"block_placed", 3)
	local.progress.achievements.append("builder")
	local.progress.stickers["take_photo"] = 1
	var remote := ProfileData.new()
	remote.username = "Hop"
	remote.age_band = AgeBand.TEEN_PLUS
	remote.updated_at = 1000
	remote.progress.record(&"secret_found/geode")
	remote.progress.record(&"secret_found/geode")
	remote.progress.achievements.append("crystal_cave")
	remote.progress.stickers["take_photo"] = 3
	var out: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(remote)).profile
	assert_eq(out.progress.count(&"block_placed"), 3)
	assert_eq(out.progress.count(&"secret_found/geode"), 2)
	assert_eq(out.progress.xp, 53, "each style's best XP: 3 building + 50 secrets")
	assert_has(out.progress.achievements, "builder")
	assert_has(out.progress.achievements, "crystal_cave")
	assert_eq(int(out.progress.stickers["take_photo"]), 3)


func test_a_profile_with_progress_is_not_new() -> void:
	var p := ProfileData.new()
	assert_true(ProfileBackup.is_new(p))
	p.progress.record(&"photo_taken")
	assert_false(ProfileBackup.is_new(p))
