extends GutTest
## M4 ghost races: a course keeps the world owner's own best run too ("a player's best run on a course they
## built"), apart from the course's best of anyone (a LAN friend's or a bot's may be faster): that is the run
## the child can share as a ghost. Saved with the course; one recording when both are the same run.

const START := Vector3i(10, 20, 30)
const FINISH := Vector3i(20, 20, 30)


func _path(seconds: float) -> RecordedRun:
	var r := RecordedRun.new(CourseRules.top_of(START))
	for i in roundi(seconds / RecordedRun.DT) + 1:
		r.add(CourseRules.top_of(START).lerp(CourseRules.top_of(FINISH), i / (seconds / RecordedRun.DT)))
	return r


func test_the_owners_own_best_is_kept_apart_from_anyones_best() -> void:
	var book := CourseBook.new()
	var mine := _path(5.0)
	var res := book.finished(START, FINISH, 5000, "Kid", mine, true)
	assert_true(res.mine_best, "the owner's first run is their best")
	assert_eq(book.mine_ms(START), 5000)
	assert_eq(book.mine(START), mine)
	var friend := _path(4.0)
	res = book.finished(START, FINISH, 4000, "Pal", friend, false)
	assert_false(res.mine_best, "a friend's run is not the owner's")
	assert_eq(book.best(START), 4000, "the course's best is the friend's")
	assert_eq(book.ghost(START), friend, "bots race the course's best")
	assert_eq(book.mine(START), mine, "the owner keeps their own run to share")
	assert_false(book.finished(START, FINISH, 6000, "Kid", _path(6.0), true).mine_best, "slower: not a new best")
	assert_eq(book.mine_ms(START), 5000)
	var faster := _path(4.5)
	assert_true(book.finished(START, FINISH, 4500, "Kid", faster, true).mine_best)
	assert_eq(book.mine(START), faster)
	assert_eq(book.mine_ms(Vector3i.ZERO), 0, "no such course")
	assert_null(book.mine(Vector3i.ZERO))


func test_saved_with_the_course_once_when_it_is_also_the_best() -> void:
	var book := CourseBook.new()
	var mine := _path(5.0)
	book.finished(START, FINISH, 5000, "Kid", mine, true)
	var saved := book.to_save()
	var course: Dictionary = saved.courses[0]
	assert_eq(course.mine_ms, 5000)
	assert_true(course.get("mine_is_best", false), "one recording for both")
	assert_false(course.has("mine"))
	var back := CourseBook.from_save(JSON.parse_string(JSON.stringify(saved)))
	assert_eq(back.mine_ms(START), 5000)
	assert_not_null(back.mine(START))
	assert_eq(back.mine(START).size(), mine.size())
	book.finished(START, FINISH, 4000, "Pal", _path(4.0), false)
	back = CourseBook.from_save(JSON.parse_string(JSON.stringify(book.to_save())))
	assert_eq(back.mine(START).size(), mine.size(), "its own recording once a friend's is the best")
	assert_eq(back.ghost(START).size(), _path(4.0).size())


func test_a_run_too_long_to_record_keeps_its_time_but_no_ghost() -> void:
	var book := CourseBook.new()
	var long := RecordedRun.new(CourseRules.top_of(START))
	for i in RecordedRun.MAX_SAMPLES + 1:
		long.add(CourseRules.top_of(START))
	assert_true(long.full)
	book.finished(START, FINISH, 200000, "Kid", long, true)
	assert_eq(book.mine_ms(START), 200000)
	assert_null(book.mine(START))


func test_broken_saves_of_the_owners_run_are_dropped() -> void:
	var saved := {"courses": [{"start": [10, 20, 30], "goals": [1000, 2000, 3000], "best": 5000, "best_name": "Kid",
		"mine_ms": "fast", "mine": {"o": [0, 0, 0], "p": "!!"}}]}
	var back := CourseBook.from_save(saved)
	assert_eq(back.mine_ms(START), 0)
	assert_null(back.mine(START))
	assert_eq(back.best(START), 5000, "the rest of the course is fine")
