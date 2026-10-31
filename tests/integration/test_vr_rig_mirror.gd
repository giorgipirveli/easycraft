extends GutTest
## Owner #101 (VR on the Meta Quest), P4: VrMirror's reflection is a true mirror for an eye anywhere in front of it
## (not only straight ahead of the middle): its camera on the eye mirrored through the glass, its off-axis frustum
## exactly the glass (the glass's corners are the picture's corners), and a point in the room shows on the glass where
## the eye sees its mirror image, left and right swapped by the glass's UVs.

var mirror: VrMirror


func before_each() -> void:
	mirror = VrMirror.new()
	add_child_autofree(mirror)
	mirror.use_world(get_viewport().world_3d)
	mirror.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED   # (the sums only: nothing to draw)
	mirror.stand_before(Transform3D(Basis(Vector3.UP, 0.4), Vector3(2.0, 81.6, -3.0)))


## Where on the glass's picture (0..1 across, 0..1 down) the reflection camera draws `p`.
func _in_picture(p: Vector3) -> Vector2:
	return mirror.camera.unproject_position(p) / Vector2(VrMirror.PIXELS)


## The glass's UV at the point where the eye sees `p`'s mirror image (the line from the eye to the image crosses it),
## as the glass's material reads the picture (its uv1 scale and offset: the flip).
func _seen_at(eye: Vector3, p: Vector3) -> Vector2:
	var g := mirror.glass.global_transform
	var n := g.basis.z.normalized()
	var image := p - n * 2.0 * (p - g.origin).dot(n)
	var k := (eye - g.origin).dot(n) / (eye - image).dot(n)
	var hit := eye + (image - eye) * k
	var local := g.affine_inverse() * hit
	var uv := Vector2(0.5 + local.x / VrMirror.SIZE.x, 0.5 - local.y / VrMirror.SIZE.y)   # the quad's own UV
	var mat := mirror.glass.material_override as StandardMaterial3D
	return uv * Vector2(mat.uv1_scale.x, mat.uv1_scale.y) + Vector2(mat.uv1_offset.x, mat.uv1_offset.y)


func test_the_glass_corners_are_the_pictures_corners_for_an_eye_off_to_the_side() -> void:
	var g := mirror.glass.global_transform
	var eye := g * Vector3(0.45, 0.5, 1.3)   # off to the right and above the middle
	mirror.reflect(eye)
	var half := VrMirror.SIZE * 0.5
	var corners := {Vector2(1, 0): Vector3(-half.x, half.y, 0), Vector2(0, 0): Vector3(half.x, half.y, 0),
		Vector2(1, 1): Vector3(-half.x, -half.y, 0), Vector2(0, 1): Vector3(half.x, -half.y, 0)}
	for want: Vector2 in corners:
		var got := _in_picture(g * (corners[want] as Vector3))
		assert_almost_eq(got.distance_to(want), 0.0, 0.01, "the glass's corner %s" % str(corners[want]))


func test_a_point_in_the_room_shows_where_the_eye_sees_its_image() -> void:
	var g := mirror.glass.global_transform
	for eye_local: Vector3 in [Vector3(0, 0.35, 1.6), Vector3(-0.5, 0.2, 1.1), Vector3(0.3, -0.4, 2.2)]:
		var eye := g * eye_local
		mirror.reflect(eye)
		for p_local: Vector3 in [Vector3(0.2, -0.3, 1.4), Vector3(-0.4, 0.1, 2.5), Vector3(0.0, -0.6, 0.8)]:
			var p := g * p_local   # the child's hand, the room behind them
			var want := _seen_at(eye, p)
			var got := _in_picture(p)
			assert_almost_eq(got.distance_to(want), 0.0, 0.01, "eye %s, point %s" % [eye_local, p_local])


func test_the_camera_looks_back_through_the_glass_from_the_mirrored_eye() -> void:
	var g := mirror.glass.global_transform
	var eye := g * Vector3(0.2, 0.1, 1.5)
	mirror.reflect(eye)
	var local := g.affine_inverse() * mirror.camera.global_position
	assert_almost_eq(local, Vector3(0.2, 0.1, -1.5), Vector3.ONE * 0.001, "the eye mirrored through the glass")
	assert_gt((-mirror.camera.global_basis.z).dot(g.basis.z.normalized()), 0.999, "looking at the room")
	assert_almost_eq(mirror.camera.near, 1.5, 0.001, "its near plane on the glass (nothing behind the glass shows)")


func test_an_eye_behind_the_glass_leaves_the_camera_alone() -> void:
	var g := mirror.glass.global_transform
	mirror.reflect(g * Vector3(0.0, 0.0, 1.5))
	var before := mirror.camera.global_transform
	mirror.reflect(g * Vector3(0.0, 0.0, -0.5))
	assert_eq(mirror.camera.global_transform, before)
