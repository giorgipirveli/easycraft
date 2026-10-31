extends GutTest
## M3 Task 12 (spec §5.8, research R4): the adventure board. Three picture goals the child picks from a
## list, progress counted from the moment one is picked, a fixed reward, then the child picks a new one.
## Nothing expires: no dates, no timers, no daily reset, no streaks.


func _data() -> ProgressData:
	var d := ProgressData.new()
	BoardRules.ensure_board(d)
	return d


## Task 12 had 23; owner #45a added more (test_board_goals_more checks at least 30 of them).
func test_many_goals_each_a_picture_and_four_words_at_most() -> void:
	assert_gte(BoardRules.GOALS.size(), 23)
	var ids := {}
	for g: Dictionary in BoardRules.GOALS:
		assert_false(ids.has(g.id), "one of each: %s" % g.id)
		ids[g.id] = true
		assert_lte(str(g.words).split(" ").size(), 4, str(g.words))
		assert_true(ProgressPictures.knows(g.picture), "%s has a picture" % g.id)
		assert_true(LevelRules.is_kind(g.kind), "%s counts a real event" % g.id)
		assert_gt(int(g.need), 0)
		assert_gte(int(g.gold), 0)


## Research §1.8: rewards for challenge and discovery, not for what children already love doing.
func test_creative_goals_give_a_sticker_and_no_gold() -> void:
	for g: Dictionary in BoardRules.GOALS:
		var f := LevelRules.family(g.kind)
		if f in [LevelRules.BLOCK, LevelRules.BUDDY, LevelRules.PHOTO, LevelRules.FRIEND, LevelRules.FED,
				LevelRules.RIDDEN, LevelRules.QUEST_DONE]:   # owner #45a's creative families too
			assert_eq(BoardRules.gold_for(g.id), 0, "%s is its own reward" % g.id)
		else:
			assert_gt(BoardRules.gold_for(g.id), 0, "%s pays a little gold in Survivor" % g.id)
	assert_eq(BoardRules.gold_for(&"no_such_goal"), 0)


func test_a_new_board_starts_with_three_easy_goals_once() -> void:
	var d := ProgressData.new()
	BoardRules.ensure_board(d)
	assert_eq(d.board.size(), BoardRules.SLOTS)
	for i in BoardRules.SLOTS:
		assert_eq(d.board[i].goal, String(BoardRules.STARTERS[i]))
		assert_lte(int(BoardRules.goal(BoardRules.STARTERS[i]).need), 3, "an easy starter")
	assert_true(d.board_set)
	d.board[1] = {"goal": "", "start": 0, "done": false}
	BoardRules.ensure_board(d)
	assert_eq(d.board[1].goal, "", "an emptied slot stays for the child to fill")


func test_picking_a_goal_counts_from_now() -> void:
	var d := _data()
	d.record(&"animal_tamed/dog")
	assert_true(BoardRules.pick(d, 0, &"tame_dogs"))
	assert_eq(d.board[0].goal, "tame_dogs")
	assert_eq(BoardRules.progress(d, 0), Vector2i(0, 2), "the dog tamed before does not count")
	d.record(&"animal_tamed/dog")
	assert_eq(BoardRules.progress(d, 0), Vector2i(1, 2))
	d.record(&"animal_tamed/cat")
	assert_eq(BoardRules.progress(d, 0), Vector2i(1, 2), "a cat is not a dog")


func test_bad_picks_are_refused() -> void:
	var d := _data()
	assert_false(BoardRules.pick(d, 3, &"tame_dogs"), "no fourth slot")
	assert_false(BoardRules.pick(d, -1, &"tame_dogs"))
	assert_false(BoardRules.pick(d, 0, &"no_such_goal"))
	assert_false(BoardRules.pick(d, 0, BoardRules.STARTERS[1]), "already on the board")
	assert_true(BoardRules.pick(d, 1, BoardRules.STARTERS[1]), "picking it again in its own slot is fine")


func test_the_list_offers_every_goal_not_on_the_board() -> void:
	var d := _data()
	var list := BoardRules.choices(d)
	var available := BoardRules.GOALS.filter(func(g: Dictionary) -> bool: return BoardRules.available(g.id)).size()
	assert_eq(list.size(), available - BoardRules.SLOTS, "owner #45a: goals waiting for their animal are not listed")
	for s: StringName in BoardRules.STARTERS:
		assert_does_not_have(list, s)
	assert_has(list, &"find_geode")


func test_a_goal_is_done_once_and_rewards_once() -> void:
	var d := _data()
	BoardRules.pick(d, 2, &"find_geode")
	assert_eq(BoardRules.check(d), [] as Array[StringName])
	d.record(&"secret_found/geode")
	assert_eq(BoardRules.check(d), [&"find_geode"] as Array[StringName])
	assert_true(d.board[2].done)
	assert_eq(BoardRules.progress(d, 2), Vector2i(1, 1), "a done goal stays full")
	d.record(&"secret_found/geode")
	assert_eq(BoardRules.check(d), [] as Array[StringName], "done is done: no second reward")
	assert_eq(BoardRules.gold_for(&"find_geode"), 60)


func test_after_a_goal_the_child_picks_a_new_one() -> void:
	var d := _data()
	BoardRules.pick(d, 0, &"take_photos")
	d.record(&"photo_taken", 5)
	BoardRules.check(d)
	assert_true(d.board[0].done)
	assert_has(BoardRules.choices(d), &"take_photos", "a done goal can be picked again")
	assert_true(BoardRules.pick(d, 0, &"find_geode"))
	assert_false(d.board[0].done)
	assert_eq(BoardRules.progress(d, 0), Vector2i(0, 1))


## Never expiring: a board has no dates, so no clock (a phone set a year ahead, a week away) can touch it.
func test_nothing_on_the_board_has_a_date_or_a_timer() -> void:
	var d := _data()
	BoardRules.pick(d, 0, &"find_geode")
	d.record(&"secret_found/geode")
	var saved := JSON.stringify(d.to_dict())
	for key in ["time", "date", "day", "expire", "deadline", "streak", "last_login", "reset"]:
		assert_false(saved.to_lower().contains(key), "no '%s' in the saved progress" % key)
	var later := ProgressData.from_dict(JSON.parse_string(saved))
	assert_eq(later.board, d.board, "loading later changes nothing")
	assert_eq(BoardRules.check(later), [&"find_geode"] as Array[StringName], "and the goal is still there to finish")


func test_progress_of_an_empty_or_bad_slot_is_nothing() -> void:
	var d := _data()
	d.board[0] = {"goal": "", "start": 0, "done": false}
	assert_eq(BoardRules.progress(d, 0), Vector2i.ZERO)
	assert_eq(BoardRules.progress(d, 7), Vector2i.ZERO)


func test_the_host_pays_a_players_goals_at_most_every_little_while() -> void:
	assert_true(BoardRules.host_allows(-1, 0))
	assert_false(BoardRules.host_allows(1000, 1000 + BoardRules.CLAIM_GAP_MS - 1))
	assert_true(BoardRules.host_allows(1000, 1000 + BoardRules.CLAIM_GAP_MS))
