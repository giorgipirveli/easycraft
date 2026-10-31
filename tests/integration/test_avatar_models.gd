extends GutTest
## Both player bodies implement AvatarModel (M1b Task 13). The realistic one is a CC0 rigged person
## that matches the blocky body: faces -Z, feet at y = 0, 1.8 blocks tall, hand on the right.


func _make(kind: GDScript) -> AvatarModel:
	var a: AvatarModel = kind.new()
	add_child_autofree(a)
	return a


func _both() -> Array[AvatarModel]:
	return [_make(BlockyAvatar), _make(RealisticAvatar)]


## A bone's rest position in the avatar's space.
func _rest_point(a: RealisticAvatar, bone: String) -> Vector3:
	var skel := a.skeleton()
	var i := skel.find_bone(bone)
	assert_gte(i, 0, "bone %s" % bone)
	return a.to_local(skel.to_global(skel.get_bone_global_rest(i).origin))


func test_both_avatars_implement_the_interface() -> void:
	for a in _both():
		assert_true(a is AvatarModel)
		a.animate(3.0, true, 0.016)
		a.animate(0.0, false, 0.5)
		a.play_jump(1)
		a.play_jump(2)
		a.set_pose(&"sleep")
		a.set_pose(&"stand")
		a.animate(6.0, true, 0.016)
		assert_not_null(a.hand())


func test_hand_is_inside_the_avatar_at_the_right_hand() -> void:
	var avatars := _both()
	await wait_frames(3)   # bone attachments follow the animated skeleton
	for a in avatars:
		var h := a.hand()
		assert_true(a.is_ancestor_of(h), "%s: held items move with the body" % a.get_script().get_global_name())
		var p := a.to_local(h.global_position)
		assert_gt(p.x, 0.1, "%s: the right hand is on +X (the avatar faces -Z)" % a.get_script().get_global_name())
		assert_between(p.y, 0.3, 1.7, "%s: at hand height" % a.get_script().get_global_name())
		assert_almost_eq(h.global_basis.get_scale().x, 1.0, 0.01, "held items keep their own size")


func test_the_hand_follows_size_magic() -> void:
	for a in _both():
		a.scale = Vector3.ONE * 3.0
		assert_almost_eq(a.hand().global_basis.get_scale().x, 3.0, 0.05, "a giant holds a giant sword")


func test_the_realistic_body_matches_the_blocky_one() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	var mesh := a.body_mesh()
	var box := a.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
	assert_almost_eq(box.position.y, 0.0, 0.05, "feet on the ground (y = 0)")
	assert_almost_eq(box.end.y, SizeMagic.PLAYER_HEIGHT, 0.1, "as tall as the blocky avatar and the capsule")
	assert_lt(_rest_point(a, "LeftToes_end").z, _rest_point(a, "LeftFoot").z, "toes point forward (-Z)")
	assert_gt(_rest_point(a, "RightHand").x, 0.3, "right hand on +X")
	assert_lt(_rest_point(a, "LeftHand").x, -0.3, "left hand on -X")


func test_one_skinned_mesh_with_one_textured_material() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	assert_eq(a.find_children("*", "MeshInstance3D", true, false).size(), 1, "one draw call")
	var mesh := a.body_mesh()
	assert_not_null(mesh.skin, "skinned")
	assert_eq(mesh.mesh.get_surface_count(), 1)
	var mat := mesh.get_active_material(0) as StandardMaterial3D
	assert_not_null(mat)
	assert_not_null(mat.albedo_texture, "wears a skin texture")
	assert_lte(mat.albedo_texture.get_width(), 1024)
	assert_eq(a.find_children("*", "Light3D", true, false).size(), 0, "no extra lights")


func test_the_animation_player_has_every_animation_and_it_drives_the_skeleton() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	var ap := a.animation_player()
	for n: StringName in [&"idle", &"walk", &"run", &"jump", &"fall"]:
		assert_true(ap.has_animation(n), "has %s" % n)
	for n: StringName in [&"idle", &"walk", &"run", &"fall"]:
		assert_ne(ap.get_animation(n).loop_mode, Animation.LOOP_NONE, "%s loops" % n)
	var root := ap.get_node(ap.root_node)
	var anim := ap.get_animation(&"run")
	assert_gt(anim.get_track_count(), 10)
	for t in anim.get_track_count():
		var path := anim.track_get_path(t)
		var skel := root.get_node_or_null(NodePath(path.get_concatenated_names())) as Skeleton3D
		assert_not_null(skel, "track %s reaches the skeleton" % path)
		if skel:
			assert_gte(skel.find_bone(path.get_concatenated_subnames()), 0, "track %s reaches a bone" % path)


func test_animate_plays_the_animation_for_the_state() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	var ap := a.animation_player()
	a.animate(0.0, true, 0.016)
	assert_eq(ap.current_animation, "idle")
	a.animate(2.0, true, 0.016)
	assert_eq(ap.current_animation, "walk")
	a.animate(Player.WALK_SPEED, true, 0.016)
	assert_eq(ap.current_animation, "run")
	assert_gt(ap.speed_scale, 1.0, "full speed strides faster than the clip")
	a.animate(Player.WALK_SPEED, false, 0.05)
	assert_eq(ap.current_animation, "run", "a short hop (stepping down) keeps running")
	for i in 5:
		a.animate(Player.WALK_SPEED, false, 0.05)
	assert_eq(ap.current_animation, "fall")
	a.animate(0.0, true, 0.016)
	assert_eq(ap.current_animation, "fall", "one frame at a (remote) jump's apex is not a landing")
	for i in 4:
		a.animate(0.0, true, 0.016)
	assert_eq(ap.current_animation, "idle", "landing")


func test_a_jump_plays_jump_until_landing() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	var ap := a.animation_player()
	a.animate(Player.WALK_SPEED, true, 0.016)
	a.play_jump(1)
	assert_eq(ap.current_animation, "jump")
	for i in 10:
		a.animate(Player.WALK_SPEED, false, 0.05)
	assert_eq(ap.current_animation, "jump", "the jump flows into the air")
	for i in 5:
		a.animate(Player.WALK_SPEED, true, 0.016)
	assert_eq(ap.current_animation, "run", "landing")


func test_air_jumps_flip_and_come_back_upright() -> void:
	for a in _both():
		a.play_jump(3)
		# The lead (2026-10-01): watched every frame, not read at 0.12 s by the clock (under load one slow frame went
		# past the whole flip, and the test failed now and then).
		var deepest := 0.0
		var until := Time.get_ticks_msec() + 600
		while Time.get_ticks_msec() < until:
			deepest = minf(deepest, a.body_pivot().rotation.x)
			await wait_process_frames(1)
		assert_lt(deepest, -0.3, "%s flips forward" % a.get_script().get_global_name())
		assert_almost_eq(a.body_pivot().rotation.x, 0.0, 0.001, "and lands upright")


func test_the_sleep_pose_lies_down_and_stand_gets_up() -> void:
	for a in _both():
		a.set_pose(&"sleep")
		a.animate(3.0, true, 0.016)
		var up := a.body_pivot().global_basis.y.normalized()
		assert_lt(absf(up.dot(Vector3.UP)), 0.2, "%s lies flat" % a.get_script().get_global_name())
		assert_lt(a.to_local(a.body_pivot().global_position).y, 0.5, "close to the bed, not floating")
		a.set_pose(&"stand")
		assert_almost_eq(a.body_pivot().global_basis.y.normalized().dot(Vector3.UP), 1.0, 0.001, "upright")


# --- Swimming (M2 Task 14, owner feedback #17) ------------------------------------------------

## Swims `a` for `frames` frames of 1/30 s at (horizontal, vertical) speed; returns the right hand's
## positions in the avatar's space (after each frame, so the skeleton has followed).
func _swim(a: AvatarModel, horizontal: float, vertical: float, frames: int) -> Array[Vector3]:
	var hands: Array[Vector3] = []
	for i in frames:
		a.swim(horizontal, vertical, 1.0 / 30.0)
		await wait_frames(1)
		hands.append(a.to_local(a.hand().global_position))
	return hands


func _name(a: AvatarModel) -> String:
	return a.get_script().get_global_name()


func test_swimming_along_lies_flat_at_the_surface_with_arm_strokes() -> void:
	for a in _both():
		a.set_pose(AvatarModel.POSE_SWIM)
		assert_eq(a.pose, AvatarModel.POSE_SWIM)
		var hands := await _swim(a, 3.0, 0.0, 45)
		var pivot := a.body_pivot()
		var head_way := pivot.basis * Vector3.UP
		assert_lt(head_way.z, -0.9, "%s: the body tips forward, head first (-Z)" % _name(a))
		assert_between(pivot.position.y, 1.05, 1.35, "%s: along the surface, the head out (float line %.2f)" % [_name(a), SwimRules.FLOAT_DEPTH])
		var zs := hands.map(func(h: Vector3) -> float: return h.z)
		var reach: float = zs.max() - zs.min()
		assert_gt(reach, 0.6, "%s: the arm strokes from far ahead to the hip (%.2f)" % [_name(a), reach])


func test_treading_water_stays_upright_with_the_arms_out() -> void:
	for a in _both():
		a.set_pose(AvatarModel.POSE_SWIM)
		var hands := await _swim(a, 0.0, 0.0, 45)
		var up := a.body_pivot().basis * Vector3.UP
		assert_gt(up.y, 0.9, "%s: upright, the head above the water" % _name(a))
		var xs := hands.map(func(h: Vector3) -> float: return h.x)
		assert_gt(xs.max(), 0.45, "%s: the arm sculls out to the side" % _name(a))


func test_diving_points_the_head_down() -> void:
	for a in _both():
		a.set_pose(AvatarModel.POSE_SWIM)
		await _swim(a, 0.0, -3.0, 45)
		assert_lt((a.body_pivot().basis * Vector3.UP).y, -0.7, "%s dives head first" % _name(a))


func test_climbing_out_stands_up_again() -> void:
	for a in _both():
		a.set_pose(AvatarModel.POSE_SWIM)
		await _swim(a, 3.0, 0.0, 20)
		a.set_pose(AvatarModel.POSE_STAND)
		a.animate(3.0, true, 0.016)
		assert_almost_eq((a.body_pivot().basis * Vector3.UP).y, 1.0, 0.001, "%s: upright" % _name(a))
		assert_almost_eq(a.body_pivot().position.y, 0.9, 0.001, "%s: standing height" % _name(a))


## The Kenney clips have no swim; the strokes are posed on the skeleton (SwimStrokes, a skeleton
## modifier over the idle clip). Its poses are applied for drawing and the bone attachments, then the
## skeleton restores the clip's poses, so the hand (a bone attachment) shows them.
func test_the_realistic_strokes_move_the_arm_only_while_swimming() -> void:
	var a := _make(RealisticAvatar) as RealisticAvatar
	await wait_frames(3)
	var in_body := func() -> Vector3: return a.body_pivot().to_local(a.hand().global_position)
	var idle: Vector3 = in_body.call()
	a.set_pose(AvatarModel.POSE_SWIM)
	var farthest := 0.0
	for i in 30:
		a.swim(3.0, 0.0, 1.0 / 30.0)
		await wait_frames(1)
		farthest = maxf(farthest, (in_body.call() as Vector3).distance_to(idle))
	assert_gt(farthest, 0.4, "the stroke swings the arm around the shoulder")
	a.set_pose(AvatarModel.POSE_STAND)
	a.animate(0.0, true, 0.016)
	await wait_frames(3)
	assert_lt((in_body.call() as Vector3).distance_to(idle), 0.12, "back to the idle clip")
