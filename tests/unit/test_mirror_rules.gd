extends GutTest


func test_mirror_across_x_plane() -> void:
	assert_eq(MirrorRules.mirror(Vector3i(12, 5, 3), MirrorRules.Axis.X, 10), Vector3i(8, 5, 3))


func test_mirror_across_z_plane() -> void:
	assert_eq(MirrorRules.mirror(Vector3i(1, 2, -4), MirrorRules.Axis.Z, 0), Vector3i(1, 2, 4))


func test_block_on_the_plane_mirrors_to_itself() -> void:
	assert_eq(MirrorRules.mirror(Vector3i(10, 7, 9), MirrorRules.Axis.X, 10), Vector3i(10, 7, 9))


func test_mirroring_twice_returns_the_original() -> void:
	var p := Vector3i(-7, 30, 15)
	assert_eq(MirrorRules.mirror(MirrorRules.mirror(p, MirrorRules.Axis.Z, 3), MirrorRules.Axis.Z, 3), p)


func test_axis_flips_what_is_left_and_right_for_the_camera() -> void:
	assert_eq(MirrorRules.axis_for_yaw(0.0), MirrorRules.Axis.X, "facing -Z: left/right is X")
	assert_eq(MirrorRules.axis_for_yaw(PI / 2.0), MirrorRules.Axis.Z, "facing -X: left/right is Z")
