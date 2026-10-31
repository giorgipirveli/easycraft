extends GutTest
## Owner #122 (docs/design/learning-is-play.md §4, "use it in the world"): a unit's world task is a quest card the child
## takes with them. The cards are kept on the device only (the unit's id, the task's words, done or not: nothing
## personal), newest first, at most MAX; a taken card can be ticked DONE.

var path := ""


func before_each() -> void:
	path = "user://test_play_quests_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func after_each() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func test_a_taken_card_is_kept_and_comes_back_after_a_restart() -> void:
	var q := PlayQuests.open_at(path)
	q.take("g4.maths.big_numbers", "Build a tower of 347 blocks.")
	q.save()
	var again := PlayQuests.open_at(path)
	assert_eq(again.cards.size(), 1)
	assert_eq(str(again.cards[0].task), "Build a tower of 347 blocks.")
	assert_true(again.has("g4.maths.big_numbers"))
	assert_false(bool(again.cards[0].done))


func test_newest_first_once_each_and_done_ticks() -> void:
	var q := PlayQuests.open_at(path)
	q.take("g4.maths.a", "A.")
	q.take("g4.maths.b", "B.")
	q.take("g4.maths.a", "A.")
	assert_eq(q.cards.size(), 2)
	assert_eq(str(q.cards[0].unit), "g4.maths.a")
	q.tick("g4.maths.b")
	assert_true(bool(q.cards[1].done))
	assert_eq(q.open_cards().size(), 1)


func test_at_most_max_cards_the_oldest_done_one_goes_first() -> void:
	var q := PlayQuests.open_at(path)
	for i in PlayQuests.MAX:
		q.take("g4.maths.u%d" % i, "Task %d." % i)
	q.tick("g4.maths.u5")
	q.take("g4.maths.new", "New.")
	assert_eq(q.cards.size(), PlayQuests.MAX)
	assert_false(q.has("g4.maths.u5"), "a done card makes room first")
	assert_true(q.has("g4.maths.u0"))


func test_a_broken_file_is_an_empty_list() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	assert_eq(PlayQuests.open_at(path).cards.size(), 0)
