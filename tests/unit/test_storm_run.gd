extends GutTest
## Storm Run as pure rules (M4 Wave 3, agent H; spec §13.7, §17.5): a glowing circle of radius 40 shrinks
## to 8 over 3 minutes while its centre drifts slowly (never far from where it started); stars appear
## inside it and anyone can take one (a team score); outside the circle you are gently pushed back in (no
## damage, nobody out); the best team score is kept.

const S := preload("res://core/games/storm_run.gd")

const START := Vector2(100, -40)


func _any(_p: Vector2) -> bool:
	return true


func _round() -> StormRun:
	var r := S.new()
	r.start(S.make_waypoints(START, 7, _any))
	return r


func test_the_circle_shrinks_from_forty_to_eight_in_three_minutes() -> void:
	assert_eq(S.TIME, 180.0)
	assert_eq(S.radius_at(0.0), 40.0)
	assert_almost_eq(S.radius_at(90.0), 24.0, 0.01)
	assert_eq(S.radius_at(S.TIME), 8.0)
	assert_eq(S.radius_at(999.0), 8.0, "never smaller")
	assert_eq(S.radius_at(-5.0), 40.0)
	var before := S.radius_at(0.0)
	for i in range(1, 181):
		var r := S.radius_at(float(i))
		assert_lt(r, before, "always shrinking")
		assert_lte(before - r, 0.2, "slowly: a child can walk in")
		before = r


func test_the_centre_drifts_slowly_and_stays_near_the_start() -> void:
	var ways := S.make_waypoints(START, 3, _any)
	assert_eq(ways.size(), S.LEGS + 1)
	assert_eq(ways[0], START)
	assert_eq(S.centre_at(0.0, ways), START)
	assert_eq(S.centre_at(S.TIME, ways), ways[-1])
	assert_eq(S.centre_at(S.TIME + 60.0, ways), ways[-1])
	var last := START
	for i in range(1, 181):
		var c := S.centre_at(float(i), ways)
		assert_lte(c.distance_to(START), S.DRIFT + 0.01, "near where it started")
		assert_lt(c.distance_to(last), 1.5, "slower than walking (6 blocks a second)")
		last = c
	assert_eq(S.make_waypoints(START, 3, _any), ways, "the same roll: the same path")
	assert_ne(S.make_waypoints(START, 4, _any), ways, "another roll: another path")


func test_the_centre_only_goes_where_it_may() -> void:
	var nowhere := S.make_waypoints(START, 5, func(_p: Vector2) -> bool: return false)
	for w in nowhere:
		assert_eq(w, START, "no good ground: it stays put")
	var east_only := S.make_waypoints(START, 5, func(p: Vector2) -> bool: return p.x >= START.x)
	for w in east_only:
		assert_gte(w.x, START.x, "never over the water to the west")


func test_outside_the_circle_you_are_pushed_gently_back_in() -> void:
	var c := Vector2(0, 0)
	assert_eq(S.push(Vector3(10, 64, 0), c, 20.0), Vector3.ZERO, "inside: nothing")
	var p := S.push(Vector3(22, 70, 0), c, 20.0)
	assert_lt(p.x, 0.0, "towards the centre")
	assert_eq(p.y, 0.0, "never up or down")
	assert_almost_eq(p.length(), S.PUSH_SPEED + 2.0 * S.PUSH_PER_BLOCK, 0.01)
	assert_gt(p.length(), 6.0, "stronger than walking away")
	assert_eq(S.push(Vector3(500, 64, 0), c, 20.0).length(), S.PUSH_MAX, "never a hard shove")
	assert_eq(S.outside_by(Vector3(25, 0, 0), c, 20.0), 5.0)


func test_stars_appear_inside_the_circle() -> void:
	for i in 200:
		var spot := S.star_spot(START, 30.0, float(i) / 200.0, fmod(float(i) * 0.37, 1.0))
		assert_lte(spot.distance_to(START), 30.0 * S.STAR_INSIDE + 0.001)
	assert_true(S.can_take(Vector3(0, 64, 0), Vector3(1.0, 65.0, 0.5)), "touching it")
	assert_false(S.can_take(Vector3(0, 64, 0), Vector3(3.0, 65.0, 0.0)), "too far")
	assert_true(S.can_take(Vector3(0, 64, 0), Vector3(3.0, 65.0, 0.0), 1.5), "the host's slack for a guest")


func test_a_round_brings_stars_counts_them_together_and_ends() -> void:
	var r := _round()
	assert_true(r.running())
	var spawns := 0
	for i in 20:
		if r.advance(0.5).spawn:
			spawns += 1
	assert_gt(spawns, 3, "stars keep coming")
	var id := r.add_star(Vector3(100, 65, -40))
	assert_gte(id, 0)
	assert_true(r.stars.has(id))
	assert_true(r.take(id))
	assert_eq(r.score, 1, "one team score")
	assert_false(r.take(id), "a star is taken once")
	assert_false(r.take(999))
	for i in S.MAX_STARS + 3:
		r.add_star(Vector3(100, 65, -40))
	assert_eq(r.stars.size(), S.MAX_STARS, "never more than the pool")
	assert_eq(r.add_star(Vector3(100, 65, -40)), -1)
	assert_false(r.advance(0.5).spawn, "full: no new star")


func test_stars_left_outside_the_shrinking_circle_go() -> void:
	var r := _round()
	var far := r.add_star(Vector3(START.x + 60, 65, START.y))
	var near := r.add_star(Vector3(START.x + 1, 65, START.y))
	var gone: Array = r.advance(100.0).gone
	assert_has(gone, far)
	assert_does_not_have(gone, near)
	assert_false(r.stars.has(far))


func test_the_round_ends_after_three_minutes_and_keeps_the_best() -> void:
	var r := _round()
	r.best = 5
	for i in 7:
		r.take(r.add_star(Vector3(100, 65, -40)))
	var step: Dictionary = r.advance(S.TIME)
	assert_true(step.over)
	assert_false(r.running())
	assert_true(r.new_best(), "7 beats 5")
	assert_eq(r.best, 7)
	assert_false(r.take(r.add_star(Vector3(100, 65, -40))), "no stars after the end")
	var s := _round()
	s.best = 9
	s.take(s.add_star(Vector3(100, 65, -40)))
	s.advance(S.TIME)
	assert_false(s.new_best())
	assert_eq(s.best, 9)


func test_the_state_goes_to_every_game() -> void:
	var r := _round()
	r.advance(42.0)
	var id := r.add_star(Vector3(101, 66, -39))
	r.take(r.add_star(Vector3(100, 65, -40)))
	var copy := S.from_state(r.to_state())
	assert_true(copy.running())
	assert_almost_eq(copy.elapsed, 42.0, 0.001)
	assert_eq(copy.score, 1)
	assert_eq(copy.waypoints, r.waypoints)
	assert_eq(copy.stars[id], Vector3(101, 66, -39))
	assert_eq(copy.circle_centre(), r.circle_centre())
	var broken := S.from_state({"waypoints": "x", "elapsed": NAN})
	assert_false(broken.running(), "a broken state is no round")
