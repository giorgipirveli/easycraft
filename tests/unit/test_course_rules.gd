extends GutTest
## M3 Task 7 (spec §14.4, §3a "an obstacle course or race in 60 seconds, no code"): Game Blocks. Stepping
## on START arms a runner's clock (0.0 while they stand there) and stepping off starts it; a CHECKPOINT is
## where a fallen runner (more than 12 blocks below it, in water or out of the world) comes back; COIN
## blocks count once per run (course score only, never gold); FINISH stops the clock and gives a medal by
## the builder's goals (the first finished run sets them: × 1.0 / 1.3 / 1.6).

const START := Vector3i(0, 10, 0)
const CHECK := Vector3i(20, 14, 0)
const FINISH := Vector3i(40, 10, 0)


# --- CourseRules ---

func test_what_the_feet_stand_on() -> void:
	var at := func(p: Vector3i) -> int:
		if p == START:
			return BlockIds.START
		return BlockIds.STONE if p.y < 10 else BlockIds.AIR
	assert_eq(CourseRules.floor_block(Vector3(0.5, 11.0, 0.5), 0.3, at), [START, BlockIds.START])
	assert_eq(CourseRules.floor_block(Vector3(1.15, 11.0, 0.5), 0.3, at), [START, BlockIds.START], "a foot on its edge")
	assert_eq(CourseRules.floor_block(Vector3(2.5, 11.0, 0.5), 0.3, at), [], "next to it: stone is nothing")
	assert_true(CourseRules.is_floor_block(BlockIds.TELEPORT_PAD))
	for id in [BlockIds.START, BlockIds.CHECKPOINT, BlockIds.FINISH, BlockIds.TELEPORT_PAD]:
		assert_true(CourseRules.is_floor_block(id), BlockIds.display_name(id))
	assert_false(CourseRules.is_floor_block(BlockIds.COIN), "a coin is walked through, not stood on")
	assert_eq(CourseRules.top_of(START), Vector3(0.5, 11.0, 0.5), "a runner stands on its middle")


func test_default_goals_come_from_the_first_finished_run() -> void:
	assert_eq(CourseRules.default_goals(40000), [40000, 52000, 64000])
	assert_eq(CourseRules.default_goals(100), [CourseRules.MIN_GOAL_MS, 1300, 1600], "never below a second")


func test_the_medal_by_the_goals() -> void:
	var goals: Array[int] = [30000, 40000, 50000]
	assert_eq(CourseRules.medal(29000, goals), CourseRules.GOLD)
	assert_eq(CourseRules.medal(30000, goals), CourseRules.GOLD, "on the goal counts")
	assert_eq(CourseRules.medal(35000, goals), CourseRules.SILVER)
	assert_eq(CourseRules.medal(45000, goals), CourseRules.BRONZE)
	assert_eq(CourseRules.medal(60000, goals), CourseRules.NO_MEDAL, "finished all the same")
	assert_eq(CourseRules.medal(1000, []), CourseRules.GOLD, "no goals yet: the first run sets them")


func test_goals_stay_in_order_and_in_range() -> void:
	assert_eq(CourseRules.clean_goals([50000, 30000, 40000]), [30000, 40000, 50000], "sorted")
	assert_eq(CourseRules.clean_goals([10, 20, 30]), [1000, 1000, 1000], "at least a second")
	assert_eq(CourseRules.clean_goals([1, 2]), [], "three or nothing")
	assert_eq(CourseRules.clean_goals(["a", 2, 3]), [])
	assert_eq(CourseRules.clean_goals([INF, 2, 3]), [])
	assert_eq(CourseRules.clean_goals([99999999, 99999999, 99999999])[2], CourseRules.MAX_GOAL_MS)
	var g: Array[int] = [30000, 40000, 50000]
	assert_eq(CourseRules.step_goal(g, 0, 1000), [31000, 40000, 50000])
	assert_eq(CourseRules.step_goal(g, 0, 20000), [50000, 50000, 50000], "gold never slower than silver: they move together")
	assert_eq(CourseRules.step_goal(g, 2, -30000), [20000, 20000, 20000], "bronze never faster than gold")
	assert_eq(CourseRules.step_goal(g, 5, 1000), g, "a medal that doesn't exist changes nothing")


func test_a_runner_falls_12_blocks_below_the_checkpoint_or_into_water_or_the_void() -> void:
	var spot := CourseRules.top_of(CHECK)
	assert_false(CourseRules.fell(spot + Vector3(3, -11.5, 0), spot, false), "11.5 below: still running")
	assert_true(CourseRules.fell(spot + Vector3(3, -12.5, 0), spot, false), "over 12 below")
	assert_true(CourseRules.fell(spot + Vector3(1, 0, 0), spot, true), "in water")
	assert_true(CourseRules.fell(Vector3(0, -70, 0), Vector3(0, -60, 0), false), "out of the world")
	assert_false(CourseRules.fell(spot + Vector3(0, 30, 0), spot, false), "high above is fine")


func test_times_read_like_a_clock() -> void:
	assert_eq(CourseRules.format_time(0), "0:00.0")
	assert_eq(CourseRules.format_time(42350), "0:42.3")
	assert_eq(CourseRules.format_time(61000), "1:01.0")
	assert_eq(CourseRules.format_time(-5), "0:00.0")


# --- CourseRun: one runner's run ---

func test_start_arms_the_clock_and_stepping_off_starts_it() -> void:
	var r := CourseRun.new()
	r.arm(START, 1000)
	assert_true(r.armed)
	assert_eq(r.elapsed(5000), 0, "standing on START: 0.0")
	r.go(5000)
	assert_false(r.armed)
	assert_eq(r.elapsed(7500), 2500)
	assert_eq(r.spot, CourseRules.top_of(START), "a fall before any checkpoint comes back to START")


func test_checkpoints_move_the_way_back() -> void:
	var r := CourseRun.new()
	r.arm(START, 0)
	r.go(0)
	assert_true(r.checkpoint(CHECK))
	assert_eq(r.spot, CourseRules.top_of(CHECK))
	assert_false(r.checkpoint(CHECK), "the same checkpoint again is nothing new")


func test_coins_count_once_per_run() -> void:
	var r := CourseRun.new()
	r.arm(START, 0)
	r.go(0)
	assert_true(r.coin(Vector3i(5, 11, 0)))
	assert_false(r.coin(Vector3i(5, 11, 0)), "once")
	assert_true(r.coin(Vector3i(6, 11, 0)))
	assert_eq(r.coins, 2)
	r.arm(START, 100)
	assert_eq(r.coins, 0, "a new run collects them again")
	assert_true(r.coin(Vector3i(5, 11, 0)))


func test_finish_needs_a_started_run() -> void:
	var r := CourseRun.new()
	assert_eq(r.finish(5000), -1, "never passed START")
	r.arm(START, 0)
	r.go(1000)
	assert_eq(r.finish(43000), 42000)
	assert_eq(r.finish(44000), -1, "a run finishes once")


func test_a_run_records_its_way_at_10_hz_up_to_3_minutes() -> void:
	var r := CourseRun.new()
	r.arm(START, 0)
	r.go(0)
	for i in 30:
		r.record(Vector3(i * 0.5, 11, 0))
	assert_eq(r.path.size(), 30)
	assert_eq(r.path.origin, CourseRules.top_of(START))


# --- CourseBook: the world's courses ---

func test_the_first_finished_run_sets_the_goals_and_gets_gold() -> void:
	var book := CourseBook.new()
	var res := book.finished(START, FINISH, 40000, "Kid", null)
	assert_eq(res.medal, CourseRules.GOLD)
	assert_true(res.best)
	assert_eq(book.goals(START), [40000, 52000, 64000])
	assert_eq(book.best(START), 40000)
	assert_eq(book.start_of_finish(FINISH), START, "tapping FINISH finds its course")
	var slower := book.finished(START, FINISH, 55000, "Pal", null)
	assert_eq(slower.medal, CourseRules.BRONZE)
	assert_false(slower.best)
	assert_eq(book.best(START), 40000)
	assert_eq(book.course(START).best_name, "Kid")


func test_the_builder_sets_the_goals() -> void:
	var book := CourseBook.new()
	book.finished(START, FINISH, 40000, "Kid", null)
	assert_true(book.set_goals(START, [30000, 35000, 45000]))
	assert_eq(book.goals(START), [30000, 35000, 45000])
	assert_false(book.set_goals(START, [1, 2]), "broken goals change nothing")
	assert_false(book.set_goals(Vector3i(9, 9, 9), [30000, 35000, 45000]), "no such course")
	assert_eq(book.finished(START, FINISH, 34000, "Kid", null).medal, CourseRules.SILVER)


func test_the_best_run_is_kept_for_bots_to_race() -> void:
	var book := CourseBook.new()
	var path := RecordedRun.new(CourseRules.top_of(START))
	for i in 50:
		path.add(Vector3(i, 11, 0))
	book.finished(START, FINISH, 5000, "Kid", path)
	assert_same(book.ghost(START), path)
	var slower := RecordedRun.new(CourseRules.top_of(START))
	slower.add(Vector3.ZERO)
	slower.add(Vector3.ONE)
	book.finished(START, FINISH, 9000, "Kid", slower)
	assert_same(book.ghost(START), path, "a slower run doesn't replace the best one")
	assert_eq(book.nearest_with_ghost(Vector3(3, 11, 0), 64.0), START)
	assert_eq(book.nearest_with_ghost(Vector3(300, 11, 0), 64.0), CourseBook.NONE, "too far away")


func test_the_book_is_saved_compact_and_checked_when_loaded() -> void:
	var book := CourseBook.new()
	var path := RecordedRun.new(CourseRules.top_of(START))
	for i in 100:
		path.add(Vector3(i * 0.3, 11, 0))
	book.finished(START, FINISH, 30000, "Kid", path)
	var text := JSON.stringify(book.to_save())
	var back := CourseBook.from_save(JSON.parse_string(text))
	assert_eq(back.goals(START), book.goals(START))
	assert_eq(back.best(START), 30000)
	assert_eq(back.course(START).best_name, "Kid")
	assert_eq(back.start_of_finish(FINISH), START)
	assert_eq(back.ghost(START).size(), 100)
	assert_almost_eq(back.ghost(START).sample_at(9.9), path.sample_at(9.9), Vector3.ONE * 0.06)


func test_loading_a_broken_book_never_fails() -> void:
	for bad: Variant in [null, 1, "x", [], {"a": 1}, {"courses": [{"start": "x"}]},
			{"courses": [{"start": [0, 1, 2], "goals": ["a"], "best": -5, "ghost": {"o": [0, 0, 0], "p": "!!"}}]}]:
		var b := CourseBook.from_save(bad)
		assert_not_null(b, str(bad))
	var odd := CourseBook.from_save({"courses": [{"start": [0, 10, 0], "goals": [3, 2, 1], "best": -5,
		"best_name": 42, "ghost": {"o": [0, 0, 0], "p": "!!"}}]})
	assert_eq(odd.goals(START), [1000, 1000, 1000], "cleaned")
	assert_eq(odd.best(START), 0, "a broken best is no best")
	assert_null(odd.ghost(START), "a broken recording is dropped")
	var many := {"courses": []}
	for i in CourseBook.MAX_COURSES + 5:
		many.courses.append({"start": [i * 3, 10, 0], "goals": [1000, 2000, 3000], "best": 1000})
	assert_eq(CourseBook.from_save(many).starts().size(), CourseBook.MAX_COURSES)


func test_a_world_keeps_a_bounded_number_of_courses_and_recordings() -> void:
	var book := CourseBook.new()
	for i in CourseBook.MAX_COURSES + 4:
		var s := Vector3i(i * 10, 10, 0)
		var path := RecordedRun.new(CourseRules.top_of(s))
		path.add(Vector3(s))
		path.add(Vector3(s) + Vector3.ONE)
		book.finished(s, s + Vector3i(5, 0, 0), 3000, "Kid", path)
	assert_eq(book.starts().size(), CourseBook.MAX_COURSES)
	var ghosts := 0
	for s in book.starts():
		if book.ghost(s) != null:
			ghosts += 1
	assert_lte(ghosts, CourseBook.MAX_GHOSTS)
	assert_not_null(book.ghost(Vector3i((CourseBook.MAX_COURSES + 3) * 10, 10, 0)), "the newest keeps its recording")
