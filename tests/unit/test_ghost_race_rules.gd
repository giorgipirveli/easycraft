extends GutTest
## Racing a friend's ghost (M4 ghost races; research T2: "my friend races my ghost and gets bronze; I have
## gold"): medals against the ghost's time, names only for viewers who may see them (spec §17.2), kind words.


func test_medals_against_the_ghosts_time() -> void:
	assert_eq(GhostRaceRules.goals(40000), [40000, 52000, 64000] as Array[int], "its time is gold, then x1.3 and x1.6")
	assert_eq(GhostRaceRules.medal(40000, 40000), CourseRules.GOLD, "as fast as the ghost: gold (the owner has gold)")
	assert_eq(GhostRaceRules.medal(30000, 40000), CourseRules.GOLD)
	assert_eq(GhostRaceRules.medal(50000, 40000), CourseRules.SILVER)
	assert_eq(GhostRaceRules.medal(60000, 40000), CourseRules.BRONZE, "the friend's bronze")
	assert_eq(GhostRaceRules.medal(70000, 40000), CourseRules.NO_MEDAL, "finished (a star, no shame words)")
	assert_true(GhostRaceRules.beat(39900, 40000))
	assert_false(GhostRaceRules.beat(40000, 40000))


func test_names_only_for_viewers_who_may_see_them() -> void:
	assert_true(GhostRaceRules.shows_names(AgeBand.TEEN_PLUS, OnlineRules.CONSENT_NONE))
	assert_true(GhostRaceRules.shows_names(AgeBand.UNDER_13, OnlineRules.CONSENT_VERIFIED))
	assert_false(GhostRaceRules.shows_names(AgeBand.UNDER_13, OnlineRules.CONSENT_NONE), "under 13 without consent")
	assert_false(GhostRaceRules.shows_names(AgeBand.UNDER_13, OnlineRules.CONSENT_PENDING))
	assert_false(GhostRaceRules.shows_names(&"", ""), "unknown: the strictest")
	assert_eq(GhostRaceRules.ghost_name("Mia_2", true), "Mia_2's ghost")
	assert_eq(GhostRaceRules.ghost_name("Mia_2", false), "A friend's ghost")


func test_the_finish_words_are_kind() -> void:
	assert_eq(GhostRaceRules.result_line(30000, 40000, "Mia_2", true), "You beat Mia_2's ghost!  GOLD!")
	assert_eq(GhostRaceRules.result_line(30000, 40000, "Mia_2", false), "You beat a friend's ghost!  GOLD!")
	assert_eq(GhostRaceRules.result_line(40000, 40000, "Mia_2", true), "Side by side with Mia_2's ghost!  GOLD!")
	assert_eq(GhostRaceRules.result_line(60000, 40000, "Mia_2", true), "Mia_2's ghost got there first. Race again!  BRONZE!")
	assert_eq(GhostRaceRules.result_line(90000, 40000, "Mia_2", false), "A friend's ghost got there first. Race again!")
	for line in [GhostRaceRules.result_line(90000, 40000, "Mia_2", true), GhostRaceRules.result_line(60000, 40000, "M", true)]:
		for bad in ["lose", "lost", "loser", "failed", "slow", "hurry", "bad"]:
			assert_false(line.to_lower().contains(bad), "%s: %s" % [bad, line])


func test_every_answer_has_plain_words() -> void:
	for code in ["no_showcase", "not_on_course", "not_in_showcase", "bad_ghost", "impossible_run", "too_many_ghosts",
			"no_run", "offline", "too_fast", "not_friends", "not_allowed_online", "network"]:
		var text := GhostRaceRules.message(code)
		assert_ne(text, "", code)
		assert_false(text.contains("_"), "never the code itself: %s" % text)
		assert_lte(text.split(" ").size(), 14, "short enough to read aloud: %s" % text)


func test_a_list_answer_is_read_carefully() -> void:
	var good := {"ghost_id": "h1_abc", "start": [1, 0, 1], "finish": [8, 0, 8], "ms": 1000,
		"path": "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "look": "", "updated_ms": 5}
	var list := GhostRaceRules.ghosts_of([good, {"ghost_id": "h2"}, 7, good.merged({"ghost_id": ""}, true)], "u1", "Mia_2")
	assert_eq(list.size(), 1, "only whole ghosts with an id")
	assert_eq([list[0].id, list[0].owner_id, list[0].owner], ["h1_abc", "u1", "Mia_2"])
	assert_eq(GhostRaceRules.ghosts_of("nope", "u1", "Mia_2").size(), 0)
