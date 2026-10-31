extends GutTest
## Owner #116 (docs/superpowers/plans/2026-10-16-vr-round4.md "Round 4b"): real brickwork, true to size. Bricks are
## 215 x 102.5 x 65 mm with 10 mm joints (225 mm a brick along a course, 75 mm a course); the Little track's big blocks
## 440 x 100 x 215 mm (450 and 225). Walls are in stretcher bond: every course's joints sit half a brick from the joints
## below, the corners turn by taking turns, an opening's cut bricks are half bricks, and a lintel carries the bricks
## over a door or a window with at least 150 mm resting on the wall each side. A wall with straight joints is weak: the
## push test finds them.

const EPS := 0.0005


func _box(n: int, m: int, courses: int, openings: Array = []) -> Dictionary:
	return BrickBond.plan({"kind": "brick", "shape": "box", "length": n, "depth": m, "courses": courses,
		"openings": openings})


func _in_course(bricks: Array, run: String, course: int) -> Array:
	var out := bricks.filter(func(b: Dictionary) -> bool: return str(b.run) == run and int(b.course) == course)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.u0) < float(b.u0))
	return out


func test_real_sizes() -> void:
	var brick := BrickBond.unit("brick")
	assert_almost_eq(brick.size as Vector3, Vector3(0.215, 0.065, 0.1025), Vector3.ONE * EPS)
	assert_almost_eq(float(brick.pitch), 0.225, EPS)
	assert_almost_eq(float(brick.course), 0.075, EPS)
	var block := BrickBond.unit("block")
	assert_almost_eq(block.size as Vector3, Vector3(0.44, 0.215, 0.1), Vector3.ONE * EPS)
	assert_almost_eq(float(block.pitch), 0.45, EPS)
	assert_almost_eq(float(block.course), 0.225, EPS)


func test_a_little_wall_of_big_blocks_starts_every_other_row_with_a_half() -> void:
	var p := BrickBond.plan({"kind": "block", "shape": "wall", "length": 3, "courses": 3})
	var bricks: Array = p.bricks
	assert_eq(_in_course(bricks, "wall", 0).size(), 3)
	var second := _in_course(bricks, "wall", 1)
	assert_eq(second.size(), 4, "a half, two whole, a half")
	assert_true(bool(second[0].cut) and bool(second[3].cut))
	assert_almost_eq(float(second[0].u1) - float(second[0].u0), 0.215, EPS, "a half block")
	assert_eq(_in_course(bricks, "wall", 2).size(), 3)
	assert_almost_eq(float(p.length), 1.34, EPS, "3 x 440 mm and two 10 mm joints")
	assert_eq(BrickBond.straight_joints(bricks), [], "in bond")


func test_the_coachs_test_wall_has_straight_joints() -> void:
	var bricks := BrickBond.stacked_wall("block", 2, 3)
	var joints := BrickBond.straight_joints(bricks)
	assert_gt(joints.size(), 0, "one straight line of joints up the middle")
	assert_almost_eq(float(joints[0].u), 0.445, 0.002)


func test_a_box_turns_its_corners_in_bond() -> void:
	var p := _box(8, 6, 4)
	var bricks: Array = p.bricks
	assert_eq(_in_course(bricks, "front", 0).size(), 8, "the front owns the corners on even courses")
	assert_eq(_in_course(bricks, "front", 1).size(), 7)
	assert_almost_eq(float(_in_course(bricks, "front", 1)[0].u0), 0.1125, EPS, "half a brick in: the stagger")
	assert_eq(_in_course(bricks, "left", 0).size(), 5)
	assert_eq(_in_course(bricks, "left", 1).size(), 6, "the sides own them on odd courses")
	assert_eq(BrickBond.straight_joints(bricks), [], "in bond, corners too")
	assert_almost_eq(float(p.length), 1.79, EPS)
	assert_almost_eq(float(p.depth), 1.34, EPS)


func test_no_two_bricks_are_in_the_same_place() -> void:
	for p: Dictionary in [_box(8, 6, 4), _box(14, 10, 6, [{"run": "front", "from": 2, "width": 4, "sill": 0, "height": 4}])]:
		var bricks: Array = p.bricks
		for i in bricks.size():
			for j in range(i + 1, bricks.size()):
				if int(bricks[i].course) != int(bricks[j].course):
					continue
				assert_false(BrickBond.overlap(bricks[i], bricks[j]), "%s and %s" % [bricks[i].id, bricks[j].id])


func test_a_doorway_has_half_bricks_at_its_sides_on_alternate_courses() -> void:
	var p := _box(8, 6, 24, [{"run": "front", "from": 3, "width": 3, "sill": 0, "height": 22}])
	var even := _in_course(p.bricks, "front", 0)
	var odd := _in_course(p.bricks, "front", 1)
	assert_eq(even.size(), 5, "three bricks out for the doorway")
	assert_eq(odd.size(), 5)
	assert_almost_eq(float(odd[2].u1), 0.665, EPS, "the reveal")
	assert_almost_eq(float(odd[2].u1) - float(odd[2].u0), 0.1025, EPS, "a half brick at the reveal")
	assert_true(bool(odd[2].cut))
	for b: Dictionary in p.bricks:
		if str(b.run) == "front" and int(b.course) < 22:
			assert_false(float(b.u1) > 0.665 + EPS and float(b.u0) < 1.35 - EPS, "nothing in the doorway: %s" % b.id)
	assert_eq(BrickBond.straight_joints(p.bricks), [])


func test_a_lintel_carries_the_bricks_over_the_opening() -> void:
	var p := _box(8, 6, 24, [{"run": "front", "from": 3, "width": 3, "sill": 0, "height": 22}])
	var lintels: Array = p.lintels
	assert_eq(lintels.size(), 1)
	var l: Dictionary = lintels[0]
	assert_eq(int(l.course), 22, "right over the doorway")
	assert_gte(0.665 - float(l.u0), BrickBond.LINTEL_BEARING - EPS, "at least 150 mm rests on the wall at the left")
	assert_gte(float(l.u1) - 1.35, BrickBond.LINTEL_BEARING - EPS, "and at the right")
	for b: Dictionary in _in_course(p.bricks, "front", 22):
		assert_false(BrickBond.overlap(b, l), "no brick where the lintel lies: %s" % b.id)


func test_nothing_floats_every_brick_sits_on_something() -> void:
	var p := BrickBond.plan({"kind": "brick", "shape": "box", "length": 14, "depth": 10, "courses": 28, "openings": [
		{"run": "front", "from": 2, "width": 4, "sill": 0, "height": 26},
		{"run": "front", "from": 8, "width": 4, "sill": 12, "height": 12}]})
	assert_eq(BrickBond.floating(p), [] as Array[String])
	assert_eq(p.lintels.size(), 2, "the door's and the window's")
	assert_eq(BrickBond.straight_joints(p.bricks), [])


func test_a_floating_brick_is_found() -> void:
	var p := _box(8, 6, 4)
	(p.bricks as Array).append({"id": "x", "run": "front", "course": 9, "u0": 0.0, "u1": 0.215, "cut": false})
	assert_eq(BrickBond.floating(p), ["x"] as Array[String])


func test_a_brick_has_its_place_in_the_site() -> void:
	var p := BrickBond.plan({"kind": "brick", "shape": "box", "length": 8, "depth": 6, "courses": 2,
		"origin": Vector3(1, 0.3, 2)})
	var first: Dictionary = _in_course(p.bricks, "front", 0)[0]
	assert_almost_eq(first.centre as Vector3, Vector3(1.1075, 0.3 + 0.01 + 0.0325, 2.0 - 0.05125), Vector3.ONE * EPS,
		"on its bed of mortar")
	var side: Dictionary = _in_course(p.bricks, "left", 1)[0]
	assert_almost_eq(absf(float(side.yaw)), PI / 2.0, EPS, "a side brick runs along z")


func test_the_nearest_free_place_for_a_brick_in_the_hand() -> void:
	var p := BrickBond.plan({"kind": "block", "shape": "wall", "length": 3, "courses": 2})
	var course := _in_course(p.bricks, "wall", 1)
	var at := (course[1].centre as Vector3) + Vector3(0.05, 0.04, 0.03)
	assert_eq(BrickBond.nearest(course, at, 0.15), 1)
	assert_eq(BrickBond.nearest(course, at + Vector3(0, 0.5, 0), 0.15), -1, "too far from any place")
