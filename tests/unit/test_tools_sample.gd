extends GutTest
## Owner #117 (docs/design/life-skills.md §13): one API for VR and the phone. ToolSample turns a held tool's tip (VR) or
## a finger's ray (flat) into the same sample in the work's own frame, so ToolMotion never knows which it was.


func test_a_work_frame_has_x_along_the_work_and_y_out_of_it() -> void:
	var f := ToolSample.work_frame(Vector3(1, 2, 3), Vector3(0, 0, 5), Vector3.UP)
	assert_almost_eq(f.origin, Vector3(1, 2, 3), Vector3.ONE * 0.001)
	assert_almost_eq(f.basis.x, Vector3(0, 0, 1), Vector3.ONE * 0.001)
	assert_almost_eq(f.basis.y, Vector3.UP, Vector3.ONE * 0.001)
	assert_almost_eq(f.basis.determinant(), 1.0, 0.001, "right-handed, no scale")


func test_a_frame_along_a_slanted_line_is_still_square() -> void:
	var f := ToolSample.work_frame(Vector3.ZERO, Vector3(1, 0.3, 0), Vector3.UP)
	assert_almost_eq(f.basis.x.dot(f.basis.y), 0.0, 0.001)
	assert_almost_eq(f.basis.y, Vector3.UP, Vector3.ONE * 0.001, "the surface's normal wins")


func test_vr_the_tools_tip_in_the_works_frame() -> void:
	var f := ToolSample.work_frame(Vector3(1, 2, 3), Vector3.RIGHT, Vector3.UP)
	var tip := Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), Vector3(1.5, 2.1, 3.0))
	var s := ToolSample.vr(f, tip, 0.7, 0.02)
	assert_almost_eq(s.at as Vector3, Vector3(0.5, 0.1, 0.0), Vector3.ONE * 0.001)
	assert_almost_eq(s.axis as Vector3, Vector3.DOWN, Vector3.ONE * 0.001, "pointing into the surface")
	assert_almost_eq(float(s.trigger), 0.7, 0.001)
	assert_false(bool(s.flat))
	assert_eq(float(s.dt), 0.02)


func test_vr_a_turned_frame_turns_the_sample() -> void:
	var f := ToolSample.work_frame(Vector3.ZERO, Vector3.BACK, Vector3.UP)   # along +z
	var s := ToolSample.vr(f, Transform3D(Basis(), Vector3(0, 0, 0.4)), 0.0, 0.02)
	assert_almost_eq((s.at as Vector3).x, 0.4, 0.001, "0.4 m along the work")


func test_vr_a_jug_tipped_over_is_tilted() -> void:
	var f := ToolSample.work_frame(Vector3.ZERO, Vector3.RIGHT, Vector3.UP)
	var upright := ToolSample.vr(f, Transform3D(Basis(), Vector3.ZERO), 0.0, 0.02)
	assert_almost_eq(float(upright.tilt), 0.0, 0.001)
	var tipped := ToolSample.vr(f, Transform3D(Basis(Vector3.FORWARD, PI / 2.0), Vector3.ZERO), 0.0, 0.02)
	assert_almost_eq(float(tipped.tilt), PI / 2.0, 0.001)


func test_vr_a_twist_turns_the_side_round_the_surfaces_normal() -> void:
	var f := ToolSample.work_frame(Vector3.ZERO, Vector3.RIGHT, Vector3.UP)
	var down := Basis.looking_at(Vector3.DOWN, Vector3.FORWARD)
	var a := ToolSample.vr(f, Transform3D(down, Vector3.ZERO), 0.0, 0.02)
	var b := ToolSample.vr(f, Transform3D(Basis(Vector3.UP, -0.5) * down, Vector3.ZERO), 0.0, 0.02)
	var angle_a := atan2((a.side as Vector3).z, (a.side as Vector3).x)
	var angle_b := atan2((b.side as Vector3).z, (b.side as Vector3).x)
	assert_almost_eq(wrapf(angle_b - angle_a, -PI, PI), 0.5, 0.001,
		"turned clockwise seen from above (a screw tightens): the side's angle grows")


func test_vr_the_other_hand_comes_along_for_the_claw() -> void:
	var f := ToolSample.work_frame(Vector3(0, 1, 0), Vector3.RIGHT, Vector3.UP)
	var s := ToolSample.vr(f, Transform3D(), 0.0, 0.02, Vector3(0.2, 1.0, 0))
	assert_almost_eq(s.other as Vector3, Vector3(0.2, 0, 0), Vector3.ONE * 0.001)
	assert_false(ToolSample.vr(f, Transform3D(), 0.0, 0.02).has("other"))


func test_flat_a_finger_on_the_surface() -> void:
	var f := ToolSample.work_frame(Vector3(0, 0.5, 0), Vector3.RIGHT, Vector3.UP)
	var s := ToolSample.flat(f, Vector3(0.3, 2.0, 1.0), (Vector3(0.3, 0.5, 0.2) - Vector3(0.3, 2.0, 1.0)).normalized(),
		true, 0.02, 0.03)
	assert_almost_eq(s.at as Vector3, Vector3(0.3, 0.0, 0.2), Vector3.ONE * 0.001)
	assert_true(bool(s.touch))
	assert_true(bool(s.flat))
	assert_eq(float(s.trigger), 1.0, "a finger down is a full squeeze")
	assert_eq(float(s.reach), 0.03)


func test_flat_a_finger_up_still_says_where_it_is() -> void:
	var f := ToolSample.work_frame(Vector3.ZERO, Vector3.RIGHT, Vector3.UP)
	var s := ToolSample.flat(f, Vector3(0, 1, 0), Vector3.DOWN, false, 0.02, 0.03)
	assert_false(bool(s.touch))
	assert_eq(float(s.trigger), 0.0)


func test_flat_a_ray_along_the_surface_or_away_from_it_finds_nothing() -> void:
	var f := ToolSample.work_frame(Vector3.ZERO, Vector3.RIGHT, Vector3.UP)
	assert_false(ToolSample.flat(f, Vector3(0, 1, 0), Vector3.RIGHT, true, 0.02, 0.03).has("at"), "along it")
	assert_false(ToolSample.flat(f, Vector3(0, 1, 0), Vector3.UP, true, 0.02, 0.03).has("at"), "away from it")


func test_both_samples_drive_the_same_motion() -> void:
	var f := ToolSample.work_frame(Vector3(2, 0, 2), Vector3.RIGHT, Vector3.UP)
	var vr_m := ToolMotion.new("press")
	var flat_m := ToolMotion.new("press")
	var tip := Transform3D(Basis(), Vector3(2.0, -0.02, 2.0))
	assert_true(bool(vr_m.feed(ToolSample.vr(f, tip, 0.0, 0.02)).done), "a hand pushes it in")
	assert_true(bool(flat_m.feed(ToolSample.flat(f, Vector3(2, 1, 2), Vector3.DOWN, true, 0.02, 0.03)).done),
		"a finger presses it")
