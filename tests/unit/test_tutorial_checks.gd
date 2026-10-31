extends GutTest
## M3 Task 15 (spec §14.9): each step's check, from what the child really does — walked and turned the camera,
## jumped from this side of the hole and landed past it (a fall into it starts over), three blocks across the
## bridge's hole, a way through the wall, crouched in a bush while the practice slime is near and can't see them.

const SITE := {"origin": Vector3i(0, 40, 0), "dir": 0}


func _feet(a: int, s: int = 0, dy: float = 0.0) -> Vector3:
	return Vector3(TutorialCourse.cell(SITE, a, s, 0)) + Vector3(0.5, dy, 0.5)


# --- Move and look ---

func test_walking_and_turning_the_camera() -> void:
	var w := TutorialChecks.LookWatch.new()
	w.feed(Vector3(0, 40, 0), 0.0)
	w.feed(Vector3(0, 40, 2), 0.2)
	assert_false(w.done(), "walked 2, turned a little")
	w.feed(Vector3(0, 40, 4), 1.0)
	assert_false(w.done(), "walked 4 but turned only 1 rad")
	w.feed(Vector3(0, 40, 4), 1.8)
	assert_true(w.done(), "walked and looked around")


func test_turning_counts_both_ways_and_across_the_wrap() -> void:
	var w := TutorialChecks.LookWatch.new()
	w.feed(Vector3.ZERO, 3.0)
	w.feed(Vector3(0, 0, 5), -3.0)    # across ±PI: a small turn, not 6 rad
	assert_lt(w.turned, 0.5)
	w.feed(Vector3(0, 0, 5), -1.4)
	assert_true(w.done())


func test_a_teleport_is_no_walk() -> void:
	var w := TutorialChecks.LookWatch.new()
	w.feed(Vector3.ZERO, 0.0)
	w.feed(Vector3(0, 0, 50), 2.0)    # a respawn or /tp
	assert_false(w.done())


# --- The jump ---

func test_a_jump_from_this_side_that_lands_past_the_hole() -> void:
	var j := TutorialChecks.JumpWatch.new()
	assert_false(j.feed(TutorialCourse.zone(SITE, _feet(1)), true), "standing at the edge")
	assert_false(j.feed(TutorialCourse.zone(SITE, _feet(4, 0, 1.5)), false), "in the air over the hole")
	assert_true(j.feed(TutorialCourse.zone(SITE, _feet(9)), true), "landed past it")


func test_a_fall_into_the_hole_starts_over() -> void:
	var j := TutorialChecks.JumpWatch.new()
	j.feed(TutorialCourse.NEAR, true)
	assert_false(j.feed(TutorialCourse.zone(SITE, _feet(5, 0, -2.0)), true), "down in the hole")
	assert_true(j.fell, "Pip says: jump out and try again")
	assert_false(j.feed(TutorialCourse.FAR, true), "climbing out on the far side is no jump")
	j.feed(TutorialCourse.NEAR, true)
	assert_true(j.feed(TutorialCourse.FAR, true))


func test_running_down_onto_the_pad_and_jumping_counts() -> void:
	var j := TutorialChecks.JumpWatch.new()
	j.feed(TutorialCourse.zone(SITE, _feet(-3, 0, 2.0)), true)   # the ground behind the pad is higher
	assert_false(j.feed(TutorialCourse.zone(SITE, _feet(0, 0, 1.0)), false), "dropping onto the pad, in the air")
	assert_true(j.feed(TutorialCourse.zone(SITE, _feet(9)), true))


func test_standing_on_the_holes_lip_is_this_side() -> void:
	var j := TutorialChecks.JumpWatch.new()
	j.feed(TutorialCourse.zone(SITE, _feet(-3)), true)
	j.feed(TutorialCourse.zone(SITE, _feet(2)), true)   # on the edge: the body is wider than its column
	assert_true(j.armed, "the lip of the hole is this side")
	assert_true(j.feed(TutorialCourse.zone(SITE, _feet(9)), true))


func test_walking_round_the_hole_is_no_jump() -> void:
	var j := TutorialChecks.JumpWatch.new()
	j.feed(TutorialCourse.NEAR, true)
	j.feed(TutorialCourse.zone(SITE, _feet(5, 3)), true)   # beside the playground
	assert_false(j.feed(TutorialCourse.FAR, true))


# --- The bridge and the wall ---

func test_three_blocks_across_the_hole_make_the_bridge() -> void:
	var cells := {}
	var block_at := func(p: Vector3i) -> int: return int(cells.get(p, BlockIds.AIR))
	assert_false(TutorialChecks.bridge_done(SITE, block_at))
	cells[TutorialCourse.cell(SITE, TutorialCourse.BRIDGE_FROM, 1, -1)] = BlockIds.PLANKS
	cells[TutorialCourse.cell(SITE, TutorialCourse.BRIDGE_FROM + 1, 1, -1)] = BlockIds.DIRT
	assert_false(TutorialChecks.bridge_done(SITE, block_at), "two of three")
	cells[TutorialCourse.cell(SITE, TutorialCourse.BRIDGE_FROM + 2, 0, -1)] = BlockIds.PLANKS
	assert_false(TutorialChecks.bridge_done(SITE, block_at), "not in one line")
	cells[TutorialCourse.cell(SITE, TutorialCourse.BRIDGE_FROM + 2, 1, -1)] = BlockIds.STONE
	assert_true(TutorialChecks.bridge_done(SITE, block_at), "any row across, any blocks")
	var bush := {}
	for a in range(TutorialCourse.BRIDGE_FROM, TutorialCourse.BRIDGE_TO + 1):
		bush[TutorialCourse.cell(SITE, a, 0, -1)] = BlockIds.BUSH
	assert_false(TutorialChecks.bridge_done(SITE, func(p: Vector3i) -> int: return int(bush.get(p, 0))), "you can't walk on bushes")


func test_a_way_through_the_wall() -> void:
	var cells := {}
	for s in range(-TutorialCourse.S_HALF, TutorialCourse.S_HALF + 1):
		for dy in 2:
			cells[TutorialCourse.cell(SITE, TutorialCourse.WALL_A, s, dy)] = BlockIds.DIRT
	var block_at := func(p: Vector3i) -> int: return int(cells.get(p, BlockIds.AIR))
	assert_false(TutorialChecks.wall_open(SITE, block_at))
	cells.erase(TutorialCourse.cell(SITE, TutorialCourse.WALL_A, 2, 0))
	assert_false(TutorialChecks.wall_open(SITE, block_at), "one block: not a way through yet")
	cells.erase(TutorialCourse.cell(SITE, TutorialCourse.WALL_A, 2, 1))
	assert_true(TutorialChecks.wall_open(SITE, block_at))


# --- Hiding ---

func test_hiding_in_the_bush_while_the_slime_is_near_and_cannot_see() -> void:
	var h := TutorialChecks.HideWatch.new()
	assert_false(h.feed(1.0, false, true, false), "not hidden")
	assert_false(h.feed(1.0, true, false, false), "no slime near")
	assert_false(h.feed(1.0, true, true, true), "it still sees them")
	assert_false(h.feed(1.0, true, true, false))
	assert_true(h.feed(TutorialChecks.HIDE_HOLD, true, true, false), "hidden a moment: it lost them")


func test_standing_up_starts_the_moment_again() -> void:
	var h := TutorialChecks.HideWatch.new()
	h.feed(TutorialChecks.HIDE_HOLD * 0.8, true, true, false)
	h.feed(0.1, false, true, false)
	assert_false(h.feed(TutorialChecks.HIDE_HOLD * 0.5, true, true, false))


# --- Crafting and Tilly ---

func test_sticks_and_only_sticks() -> void:
	assert_true(TutorialChecks.crafted_stick(true, ItemIds.STICK))
	assert_false(TutorialChecks.crafted_stick(false, ItemIds.STICK), "a refused craft")
	assert_false(TutorialChecks.crafted_stick(true, BlockIds.CRAFTING_TABLE))


func test_at_tillys_shop() -> void:
	var tilly := Vector3(10, 40, 10)
	assert_true(TutorialChecks.at_tilly(Vector3(10, 41.6, 13), tilly))
	assert_false(TutorialChecks.at_tilly(Vector3(10, 41.6, 30), tilly))
	assert_false(TutorialChecks.at_tilly(Vector3(10, 41.6, 13), Vector3.INF), "no Tilly")
