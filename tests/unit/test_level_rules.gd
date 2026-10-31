extends GutTest
## M3 Task 12 (spec §5.8, §14.11): XP per event, the gentle level curve, and titles for every play style.


func test_each_event_family_gives_its_xp() -> void:
	assert_eq(LevelRules.xp_for(&"monster_defeated"), 10)
	assert_eq(LevelRules.xp_for(&"secret_found"), 25)
	assert_eq(LevelRules.xp_for(&"block_placed"), 1)
	assert_eq(LevelRules.xp_for(&"wave_won"), 40)
	assert_eq(LevelRules.xp_for(&"boss_beaten"), 150)
	assert_eq(LevelRules.xp_for(&"buddy_woken"), 20)
	assert_eq(LevelRules.xp_for(&"animal_tamed"), 30)
	assert_eq(LevelRules.xp_for(&"photo_taken"), 5)
	assert_eq(LevelRules.xp_for(&"race_finished"), 25)
	assert_eq(LevelRules.xp_for(&"friend_played"), 15)
	assert_eq(LevelRules.xp_for(&"area_explored"), 5)
	assert_eq(LevelRules.xp_for(&"goal_done"), 50)


func test_a_detail_gives_its_familys_xp() -> void:
	assert_eq(LevelRules.xp_for(&"animal_tamed/dog"), 30)
	assert_eq(LevelRules.xp_for(&"secret_found/geode"), 25)
	assert_eq(LevelRules.family(&"animal_tamed/dog"), &"animal_tamed")
	assert_eq(LevelRules.family(&"photo_taken"), &"photo_taken")


func test_unknown_or_broken_kinds_count_nothing() -> void:
	for kind: StringName in [&"", &"logged_in", &"minutes_played", &"animal_tamed/", &"animal_tamed/Dog!",
			&"animal_tamed/a b", StringName("monster_defeated/" + "x".repeat(60))]:
		assert_false(LevelRules.is_kind(kind), String(kind))
		assert_eq(LevelRules.xp_for(kind), 0, String(kind))
	assert_eq(LevelRules.xp_for(&"photo_taken", 0), 0)
	assert_eq(LevelRules.xp_for(&"photo_taken", -3), 0)


## A stamp's 200 blocks are one event: a few XP, not 200 (building stays its own reward, research §1.8).
func test_a_big_batch_of_blocks_gives_a_few_xp() -> void:
	assert_eq(LevelRules.xp_for(&"block_placed", 3), 3)
	assert_eq(LevelRules.xp_for(&"block_placed", 200), 5)
	assert_eq(LevelRules.xp_for(&"monster_defeated", 1_000_000), 100, "any event is capped")


func test_the_curve_starts_gently_and_grows() -> void:
	assert_eq(LevelRules.xp_to_reach(1), 0)
	assert_eq(LevelRules.xp_to_reach(2), 100)
	assert_eq(LevelRules.xp_to_reach(3), 250)
	assert_eq(LevelRules.xp_to_reach(10), 2700)
	var step := 0
	for l in range(2, LevelRules.MAX_LEVEL + 1):
		var s := LevelRules.xp_to_reach(l) - LevelRules.xp_to_reach(l - 1)
		assert_gt(s, step, "level %d needs more than the one before" % l)
		step = s
	assert_eq(LevelRules.level_for(0), 1)
	assert_eq(LevelRules.level_for(99), 1)
	assert_eq(LevelRules.level_for(100), 2)
	assert_eq(LevelRules.level_for(2699), 9)
	assert_eq(LevelRules.level_for(2700), 10)
	assert_eq(LevelRules.level_for(1_000_000_000), LevelRules.MAX_LEVEL)


## Level 2 in about ten minutes of play, level 10 in a few hours (the task's numbers), at the typical
## rate of mixed play: a minute of it is a few blocks, a monster now and then, a photo, a new place.
func test_level_2_in_about_ten_minutes_and_level_10_in_a_few_hours() -> void:
	var minute := LevelRules.xp_for(&"block_placed") * 5 + LevelRules.xp_for(&"monster_defeated") * 0.2 \
		+ LevelRules.xp_for(&"area_explored") * 0.4 + LevelRules.xp_for(&"photo_taken") * 0.1 \
		+ LevelRules.xp_for(&"secret_found") * 0.06 + LevelRules.xp_for(&"animal_tamed") * 0.02
	assert_almost_eq(minute, LevelRules.TYPICAL_XP_PER_MINUTE, 1.5, "the documented typical rate matches a mix")
	var to_2 := LevelRules.xp_to_reach(2) / LevelRules.TYPICAL_XP_PER_MINUTE
	var to_10 := LevelRules.xp_to_reach(10) / LevelRules.TYPICAL_XP_PER_MINUTE / 60.0
	assert_between(to_2, 6.0, 14.0, "minutes to level 2")
	assert_between(to_10, 2.0, 5.0, "hours to level 10")


func test_the_xp_bar_fills_within_a_level() -> void:
	assert_eq(LevelRules.level_progress(0), Vector2i(0, 100))
	assert_eq(LevelRules.level_progress(130), Vector2i(30, 150))
	assert_eq(LevelRules.level_progress(LevelRules.xp_to_reach(LevelRules.MAX_LEVEL)), Vector2i.ZERO)


func test_every_family_but_goals_belongs_to_a_play_style() -> void:
	for f: StringName in LevelRules.XP:
		if f == LevelRules.GOAL:
			assert_eq(LevelRules.style_of(f), &"", "goals are every style's")
		else:
			assert_ne(LevelRules.style_of(f), &"", String(f))
	assert_eq(LevelRules.style_of(&"animal_tamed/cat"), &"animals")
	assert_eq(LevelRules.style_of(&"wave_won"), &"fighter")
	for s: StringName in LevelRules.STYLE_ORDER:
		assert_true(LevelRules.STYLES.has(s))
		assert_lte(LevelRules.title_text(s).split(" ").size(), 3, "a short title")


## Titles for every play style: the one played most (by XP) once earned; the child may pick another earned
## one; nothing is earned for logging in or for time played (research R5).
func test_the_title_follows_the_style_played_most() -> void:
	assert_eq(LevelRules.main_style({}), &"")
	assert_eq(LevelRules.title_text(&""), LevelRules.START_TITLE)
	assert_eq(LevelRules.main_style({"builder": 49}), &"", "not earned yet")
	assert_eq(LevelRules.main_style({"builder": 60, "hunter": 30}), &"builder")
	assert_eq(LevelRules.title_text(&"builder"), "Master Builder")
	assert_eq(LevelRules.main_style({"builder": 60, "hunter": 75}), &"hunter")
	assert_eq(LevelRules.title_text(&"hunter"), "Secret Hunter")
	assert_eq(LevelRules.main_style({"boss": 150, "builder": 120}), &"boss")
	assert_eq(LevelRules.title_text(&"boss"), "Boss Slayer")
	assert_eq(LevelRules.main_style({"animals": 60, "magic": 60}), &"animals", "a tie: the first style")
	assert_eq(LevelRules.title_text(&"animals"), "Animal Friend")
	assert_eq(LevelRules.title_text(&"explorer"), "Explorer")


func test_a_chosen_title_shows_only_when_earned() -> void:
	var xp := {"builder": 300, "photo": 55}
	assert_eq(LevelRules.earned_titles(xp), [&"builder", &"photo"] as Array[StringName])
	assert_eq(LevelRules.shown_title(xp, &""), &"builder")
	assert_eq(LevelRules.shown_title(xp, &"photo"), &"photo")
	assert_eq(LevelRules.shown_title(xp, &"boss"), &"builder", "not earned: the style played most")
	assert_eq(LevelRules.shown_title(xp, &"nonsense"), &"builder")


func test_the_name_tag_line() -> void:
	assert_eq(LevelRules.tag_line(5, &"builder"), "Lv 5 Master Builder")
	assert_eq(LevelRules.tag_line(1, &""), "Lv 1 Adventurer")
	assert_eq(LevelRules.tag_line(500, &"x"), "Lv 99 Adventurer")
