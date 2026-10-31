extends GutTest
## M4 ghost races: this player's own best runs as ghosts to share (GhostShare): on the showcase with the area
## around the course, or with a picked build that holds the whole course; only what the server will take.

const START := Vector3i(10, 20, 30)
const FINISH := Vector3i(16, 20, 30)
const FLOOR_Y := 20

var cells := {}


func before_each() -> void:
	cells = {}
	for x in range(8, 19):
		cells[Vector3i(x, FLOOR_Y, 30)] = BlockIds.PLANKS
	cells[START] = BlockIds.START
	cells[FINISH] = BlockIds.FINISH


func _block_at(c: Vector3i) -> int:
	return int(cells.get(c, BlockIds.AIR))


func _run(seconds: float) -> RecordedRun:
	var r := RecordedRun.new(CourseRules.top_of(START))
	var n := roundi(seconds / RecordedRun.DT)
	for i in n + 1:
		r.add(CourseRules.top_of(START).lerp(CourseRules.top_of(FINISH), i / float(n)))
	return r


func _book(own: bool = true) -> CourseBook:
	var book := CourseBook.new()
	book.finished(START, FINISH, 3000, "Kid", _run(3.0), own)
	return book


func test_a_course_inside_the_showcase_area_shares_the_owners_run() -> void:
	var origin := Vector3i(0, 12, 20)
	var list := GhostShare.showcase_ghosts(_book(), origin, Vector3i(32, 32, 32), _block_at, "{\"hat\":\"cap\"}")
	assert_eq(list.size(), 1)
	var g: RaceGhost = list[0].ghost
	assert_eq(list[0].start, START)
	assert_eq(g.start, START - origin, "in the area's cells")
	assert_eq(g.finish, FINISH - origin)
	assert_eq(g.ms, 3000)
	assert_eq(g.look, "{\"hat\":\"cap\"}")
	assert_eq(g.points[g.points.size() - 1], Vector3(6, 0, 0), "ends on FINISH's top")


func test_only_the_owners_own_run_and_only_a_whole_course_in_the_area() -> void:
	assert_eq(GhostShare.showcase_ghosts(_book(false), Vector3i(0, 12, 20), Vector3i(32, 32, 32), _block_at, "").size(), 0,
		"a friend's (or a bot's) run is theirs to share")
	assert_eq(GhostShare.showcase_ghosts(_book(), Vector3i(-18, 12, 20), Vector3i(32, 32, 32), _block_at, "").size(), 0,
		"FINISH outside the area")
	cells[FINISH] = BlockIds.PLANKS
	assert_eq(GhostShare.showcase_ghosts(_book(), Vector3i(0, 12, 20), Vector3i(32, 32, 32), _block_at, "").size(), 0,
		"the FINISH was broken since: the server would refuse it")


func test_at_most_three_courses_on_a_showcase_the_most_lately_raced() -> void:
	var book := CourseBook.new()
	for i in 5:
		var s := START + Vector3i(0, 0, i * 2)
		var f := FINISH + Vector3i(0, 0, i * 2)
		cells[s] = BlockIds.START
		cells[f] = BlockIds.FINISH
		var r := RecordedRun.new(CourseRules.top_of(s))
		for k in 31:
			r.add(CourseRules.top_of(s).lerp(CourseRules.top_of(f), k / 30.0))
		book.finished(s, f, 3000, "Kid", r, true)
	var list := GhostShare.showcase_ghosts(book, Vector3i(0, 12, 20), Vector3i(32, 32, 32), _block_at, "")
	assert_eq(list.size(), GhostRaceRules.PER_SHOWCASE)
	assert_eq(list[0].start, START + Vector3i(0, 0, 8), "the course raced last first")


func test_a_picked_build_with_the_whole_course_takes_the_ghost_along() -> void:
	var picked := {}
	for c: Vector3i in cells:
		if c.x >= 10 and c.x <= 16:
			picked[c] = cells[c]
	var g := GhostShare.gift_ghost(_book(), picked, "")
	assert_not_null(g)
	assert_eq(g.start, Vector3i(0, 0, 0), "from the build's lowest corner")
	assert_eq(g.finish, Vector3i(6, 0, 0))
	picked.erase(FINISH)
	assert_null(GhostShare.gift_ghost(_book(), picked, ""), "no FINISH in the build: no ghost")
	assert_null(GhostShare.gift_ghost(_book(), {}, ""))


## A gift's stamp placed at `anchor` facing `forward` puts the course's START where Blueprints puts that block:
## the ghost races from there, turned with it.
func test_a_stamped_gifts_start_is_where_the_stamp_puts_it() -> void:
	var blocks := {Vector3i(0, 0, 0): BlockIds.PLANKS, Vector3i(1, 0, 0): BlockIds.START, Vector3i(2, 0, 3): BlockIds.FINISH,
		Vector3i(4, 1, 2): BlockIds.PLANKS}
	var g := RaceGhost.new()
	g.start = Vector3i(1, 0, 0)
	g.finish = Vector3i(2, 0, 3)
	var stamp := GiftStampBook.item_of(0)
	for forward: Vector3i in [Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0)]:
		var anchor := Vector3i(50, 12, -30)
		var start := GhostShare.stamped_start(g, blocks, anchor, forward)
		var placed := {}
		var local := Blueprints.gift_local(blocks)
		for p: Vector3i in local:
			placed[Blueprints.to_world(p, anchor, forward)] = local[p]
		assert_eq(placed.get(start), BlockIds.START, "facing %s" % forward)
	assert_eq(stamp, ItemIds.GIFT_STAMP_FIRST)


## A new best on a course inside my showcase replaces its ghost there; anywhere else, or when the one there is as
## fast, nothing is sent.
func test_a_new_best_replaces_the_ghost_on_my_showcase() -> void:
	var book := _book()
	var ghosts := GhostBook.new()
	var origin := Vector3i(0, 12, 20)
	assert_null(GhostShare.replacement(book, ghosts, "w", START, _block_at, ""), "no showcase of mine")
	ghosts.set_mine("w", origin, Vector3i(32, 32, 32))
	var g := GhostShare.replacement(book, ghosts, "w", START, _block_at, "")
	assert_not_null(g, "the course is in my showcase")
	assert_eq(g.start, START - origin)
	assert_null(GhostShare.replacement(book, ghosts, "other", START, _block_at, ""), "another world")
	ghosts.note_shared("w", START, "h1", 3000)
	assert_null(GhostShare.replacement(book, ghosts, "w", START, _block_at, ""), "the one there is as fast")
	ghosts.note_shared("w", START, "h1", 4000)
	assert_not_null(GhostShare.replacement(book, ghosts, "w", START, _block_at, ""), "mine is faster now")
