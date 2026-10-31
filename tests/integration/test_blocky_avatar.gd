extends GutTest
## The avatar faces -Z. In the air both arms must reach up and FORWARD (owner feedback 2026-09-23).


func _arm_dir(avatar: BlockyAvatar, arm: Node3D) -> Vector3:
	return (arm.global_transform.basis * Vector3.DOWN).normalized()


func test_arms_reach_forward_and_up_when_airborne() -> void:
	var avatar := BlockyAvatar.new()
	add_child_autofree(avatar)
	for i in 30:
		avatar.animate(0.0, false, 0.05)
	for arm in [avatar._left_arm, avatar._right_arm]:
		var d := _arm_dir(avatar, arm)
		assert_gt(d.y, 0.3, "arm points up")
		assert_lt(d.z, -0.2, "arm points forward (-Z), not behind")
