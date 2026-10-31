extends GutTest
## M3 Task 2 (spec §14.1 "pyramids with traps"; the brief: cactus "decide gently: it only pushes"): the
## desert's hazards as pure rules. A cactus pushes whoever walks into it a little (never hurts). An arrow
## slit shoots a dart across the pyramid's corridor when a child stands in its lane: a click first (the
## signal), the dart a moment later, so a child who keeps walking is past it.

const FLOOR := 10


func _cactus_at(cells: Array[Vector3i]) -> Callable:
	return func(p: Vector3i) -> int:
		if cells.has(p):
			return BlockIds.CACTUS
		return BlockIds.SAND if p.y < FLOOR else BlockIds.AIR


func test_a_cactus_pushes_whoever_walks_into_it_away() -> void:
	var at := _cactus_at([Vector3i(1, FLOOR, 0)] as Array[Vector3i])
	var push := DesertRules.cactus_push(Vector3(0.8, FLOOR, 0.5), at)     # pressed against its -x face
	assert_gt(push.length(), 0.0)
	assert_lt(push.x, 0.0, "away from it")
	assert_eq(push.z, 0.0)
	assert_gt(push.y, 0.0, "a little hop")
	assert_eq(DesertRules.cactus_push(Vector3(0.3, FLOOR, 0.5), at), Vector3.ZERO, "not touching it")
	var head := _cactus_at([Vector3i(0, FLOOR + 1, 1)] as Array[Vector3i])
	assert_gt(DesertRules.cactus_push(Vector3(0.5, FLOOR, 0.8), head).length(), 0.0, "at head height too")
	var standing_on := _cactus_at([Vector3i(0, FLOOR - 1, 0)] as Array[Vector3i])
	assert_gt(DesertRules.cactus_push(Vector3(0.5, FLOOR, 0.5), standing_on).y, 0.0, "off the top of one")
	assert_eq(DesertRules.CACTUS_DAMAGE, 0, "it never hurts")


func test_an_arrow_slits_lane_runs_across_the_corridor_at_head_and_body_height() -> void:
	var trap := {"cell": Vector3i(5, FLOOR + 1, 0), "dir": Vector3i(0, 0, 1)}
	assert_true(DesertRules.in_lane(trap, Vector3(5.5, FLOOR, 1.5)))
	assert_true(DesertRules.in_lane(trap, Vector3(5.5, FLOOR, 3.5)), "across the whole corridor")
	assert_false(DesertRules.in_lane(trap, Vector3(6.6, FLOOR, 1.5)), "a step beside it")
	assert_false(DesertRules.in_lane(trap, Vector3(5.5, FLOOR, -0.5)), "behind the slit")
	assert_false(DesertRules.in_lane(trap, Vector3(5.5, FLOOR, DesertRules.LANE + 1.5)), "beyond the far wall")
	assert_false(DesertRules.in_lane(trap, Vector3(5.5, FLOOR + 3, 1.5)), "far above")


func test_the_dart_is_signalled_and_gentle() -> void:
	assert_gte(DesertRules.DART_DELAY, 0.5, "the click comes first: time to step on")
	assert_lt(DesertRules.DART_DELAY, 1.0)
	assert_gt(DesertRules.DART_COOLDOWN, DesertRules.DART_DELAY)
	assert_between(DesertRules.DART_DAMAGE, 1, 2, "gentle")
