extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §2.3, §4.4; the lead's review, question 5): in VR the child swims
## through the leaf's thick air with their arms, Gorilla Tag's way: squeeze a grip and pull, and the body moves the other
## way (up to 2.5 m/s); let go and the thick air stops it within a quarter of a second (at a cell's size air really is
## thick, Purcell 1977, and stopping when you stop is the most comfortable VR movement there is). The laser's grapple
## glides the child to a door, a pipe or a cell in 0.6 s, eased.

const FRAME := 1.0 / 72.0   # the Quest's frame


func _swim(v: Vector3, pulls: Array[Vector3], seconds: float) -> Vector3:
	for i in int(round(seconds / FRAME)):
		v = LeafSwimRules.step(v, pulls, FRAME)
	return v


func test_a_pull_moves_the_body_the_other_way() -> void:
	var v := LeafSwimRules.step(Vector3.ZERO, [Vector3(0, 0, 1.2)] as Array[Vector3], FRAME)
	assert_almost_eq(v.z, -1.2, 0.0001, "the hand pulls back, the body goes forward")
	assert_almost_eq(v.x, 0.0, 0.0001)
	var up := LeafSwimRules.step(Vector3.ZERO, [Vector3(0, -0.8, 0)] as Array[Vector3], FRAME)
	assert_almost_eq(up.y, 0.8, 0.0001, "pull down to rise")


func test_two_hands_pulling_together_go_as_fast_as_one() -> void:
	var v := LeafSwimRules.step(Vector3.ZERO, [Vector3(0, 0, 1.0), Vector3(0, 0, 1.0)] as Array[Vector3], FRAME)
	assert_almost_eq(v.z, -1.0, 0.0001)
	var turn := LeafSwimRules.step(Vector3.ZERO, [Vector3(1.0, 0, 0), Vector3(-1.0, 0, 0)] as Array[Vector3], FRAME)
	assert_almost_eq(turn.length(), 0.0, 0.0001, "pulling apart goes nowhere")


func test_no_pull_and_the_thick_air_stops_the_body_within_a_quarter_second() -> void:
	var v := _swim(Vector3(0, 0, -2.5), [] as Array[Vector3], 0.25)
	assert_lt(v.length(), 0.05, "stopped (under 5 cm/s) within 0.25 s from top speed")
	var half := _swim(Vector3(0, 0, -2.5), [] as Array[Vector3], 0.05)
	assert_gt(half.length(), 0.5, "a soft stop, not a wall")


func test_the_speed_is_capped() -> void:
	var v := LeafSwimRules.step(Vector3.ZERO, [Vector3(0, 0, 6.0)] as Array[Vector3], FRAME)
	assert_almost_eq(v.length(), LeafSwimRules.MAX_SPEED, 0.0001)
	assert_almost_eq(LeafSwimRules.MAX_SPEED, 2.5, 0.0001)


func test_the_grapple_glides_there_in_0_6_s_eased() -> void:
	var from := Vector3(0, 1, 0)
	var to := Vector3(3, 2, -4)
	assert_eq(LeafSwimRules.glide(from, to, 0.0), from)
	assert_eq(LeafSwimRules.glide(from, to, LeafSwimRules.GLIDE), to)
	assert_eq(LeafSwimRules.glide(from, to, 5.0), to, "and stays")
	var last := -1.0
	for i in 13:
		var d := from.distance_to(LeafSwimRules.glide(from, to, i * 0.05))
		assert_gte(d, last, "always onwards")
		last = d
	var early := from.distance_to(LeafSwimRules.glide(from, to, 0.06)) / from.distance_to(to)
	assert_lt(early, 0.1, "it eases out of rest (no jolt)")
