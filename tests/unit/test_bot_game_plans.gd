extends GutTest
## Bot friends in the co-op games, as pure choices (M4 Wave 3, agent H; spec §17.5): a hiding bot picks a
## free hiding spot within 30 blocks (a barrel or closet before a bush, never one taken, never right
## next to the counting spot), else a place the counting spot can't see; a seeking bot checks the spots
## it knows nearest first, walking a little slower than a child and looking into each spot for a moment
## (fair: it never knows where anyone is); a Storm Run bot goes for the nearest star nobody else is after.

const B := preload("res://core/games/bot_game_plans.gd")

const BASE := Vector3(0.5, 64, 0.5)


func test_a_hiding_bot_prefers_a_free_barrel_or_closet_then_a_bush() -> void:
	var spots := {Vector3i(10, 64, 0): BlockIds.BUSH, Vector3i(-12, 64, 3): BlockIds.BARREL,
		Vector3i(0, 64, 20): BlockIds.CLOSET, Vector3i(2, 64, 1): BlockIds.BARREL, Vector3i(45, 64, 0): BlockIds.BARREL}
	var pick := B.hide_choice(spots, [] as Array[Vector3i], BASE, 0)
	assert_true(pick in [Vector3i(-12, 64, 3), Vector3i(0, 64, 20)], "inside a barrel or closet (%s)" % pick)
	assert_ne(B.hide_choice(spots, [] as Array[Vector3i], BASE, 1), Vector3i(2, 64, 1), "never right next to the seeker")
	var taken: Array[Vector3i] = [Vector3i(-12, 64, 3), Vector3i(0, 64, 20)]
	assert_eq(B.hide_choice(spots, taken, BASE, 0), Vector3i(10, 64, 0), "both taken: the bush")
	taken.append(Vector3i(10, 64, 0))
	assert_eq(B.hide_choice(spots, taken, BASE, 0), B.NO_CELL, "the far barrel is out of the game's area")
	var picks := {}
	for roll in 12:
		picks[B.hide_choice(spots, [] as Array[Vector3i], BASE, roll)] = true
	assert_eq(picks.size(), 2, "different bots, different spots")


func test_without_spots_a_bot_hides_where_the_counting_spot_cant_see() -> void:
	var places: Array[Vector3] = [Vector3(10, 64, 0), Vector3(-15, 64, 4), Vector3(3, 64, 22)]
	var seen: Array[bool] = [true, false, true]
	assert_eq(B.open_choice(places, seen, 0), Vector3(-15, 64, 4), "behind cover")
	assert_eq(B.open_choice(places, [true, true, true] as Array[bool], 1), places[1], "none covered: any")
	assert_eq(B.open_choice([] as Array[Vector3], [] as Array[bool], 0), Vector3.INF)
	for p in B.open_places(BASE, 3):
		var d := Vector2(p.x - BASE.x, p.y - BASE.z).length()
		assert_between(d, B.MIN_HIDE, B.HIDE_RADIUS, "inside the area, away from the seeker")


func test_a_seeking_bot_is_fair_and_a_little_slower_than_a_child() -> void:
	assert_lt(B.SEEK_SPEED, Player.WALK_SPEED, "a little slower than a child")
	assert_gt(B.SEEK_SPEED, Player.WALK_SPEED * 0.5)
	assert_gt(B.LOOK_TIME, 0.5, "it looks into a spot for a moment")
	assert_lte(B.SPOT_STOP, HideSeekRound.SPOT_REACH - 1.0, "close enough to look inside")
	var spots: Array[Vector3] = [Vector3(20, 64, 0), Vector3(2, 64, 0), Vector3(9, 64, 0), Vector3(-20, 64, 0)]
	var route := B.search_route(spots, Vector3.ZERO, 0)
	assert_eq(route.size(), 4, "every spot once")
	assert_eq(route[0], Vector3(2, 64, 0), "nearest first")
	assert_eq(route[1], Vector3(9, 64, 0))
	assert_eq(route[2], Vector3(20, 64, 0))
	assert_eq(route[3], Vector3(-20, 64, 0))
	assert_eq(B.search_route(spots, Vector3.ZERO, 1)[0], Vector3(9, 64, 0), "another bot starts elsewhere")


func test_a_storm_bot_goes_for_the_nearest_star_nobody_else_is_after() -> void:
	var stars := {1: Vector3(5, 65, 0), 2: Vector3(2, 65, 0), 3: Vector3(30, 65, 0)}
	assert_eq(B.star_target(stars, Vector3.ZERO, [] as Array[int]), 2)
	assert_eq(B.star_target(stars, Vector3.ZERO, [2] as Array[int]), 1, "another bot is after star 2")
	assert_eq(B.star_target({}, Vector3.ZERO, [] as Array[int]), -1)
