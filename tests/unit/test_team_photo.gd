extends GutTest
## The team photo after a boss as pure rules (M4 Wave 3, agent H; spec §17.5, research T5): the offer
## lasts 20 s; everyone near the one who asked lines up side by side facing a camera in front of them, the
## one who asked in the middle; the camera sees the whole line and never stands inside a block; they
## cheer, and the shot is taken while the cheer plays.

const T := preload("res://core/games/team_photo.gd")


func _air(_cell: Vector3i) -> bool:
	return false


func test_the_offer_lasts_twenty_seconds() -> void:
	assert_eq(T.OFFER_TIME, 20.0)
	assert_true(T.offer_open(105.0, 100.0))
	assert_false(T.offer_open(120.5, 100.0))
	assert_false(T.offer_open(100.0, -1.0), "no boss beaten: no offer")


func test_everyone_near_is_in_the_photo() -> void:
	assert_true(T.is_near(Vector3(0, 64, 0), Vector3(20, 66, 5)))
	assert_false(T.is_near(Vector3(0, 64, 0), Vector3(30, 64, 0)))
	assert_false(T.is_near(Vector3(0, 64, 0), Vector3.INF))


func test_the_one_who_asked_stands_in_the_middle() -> void:
	var keys: Array[String] = ["p1", "p5", "bPip", "bBolt"]
	var order := T.order(keys, "p5")
	assert_eq(order.size(), 4)
	assert_eq(order[order.size() / 2], "p5")
	for k in keys:
		assert_has(order, k, "everyone once")
	assert_eq(T.order(["p1"] as Array[String], "p1"), ["p1"] as Array[String])
	assert_eq(T.order(["p1", "bPip"] as Array[String], "p9").size(), 2, "the asker left: the rest still line up")


func test_the_line_stands_side_by_side_across_the_view() -> void:
	var center := Vector3(10, 64, -3)
	var yaw := 0.7
	var spots := T.line_up(center, yaw, 5)
	assert_eq(spots.size(), 5)
	var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
	var middle := Vector3.ZERO
	for s in spots:
		middle += s / 5.0
		assert_eq(s.y, center.y, "all on the same ground height")
		assert_almost_eq((s - center).dot(forward), 0.0, 0.001, "a line across, not towards the camera")
	assert_almost_eq(middle.distance_to(center), 0.0, 0.001, "centred on the one who asked")
	assert_almost_eq(spots[0].distance_to(spots[1]), T.SPACING, 0.001)


func test_the_camera_stands_in_front_and_sees_everyone() -> void:
	var center := Vector3(10, 64, -3)
	for n in [1, 3, 7]:
		var yaw := 1.2
		var spots := T.line_up(center, yaw, n)
		var view := T.camera_view(center, yaw, n, 70.0, _air)
		var forward := Basis(Vector3.UP, yaw) * Vector3.FORWARD
		assert_gt((view.origin - center).dot(forward), 2.0, "in front of the line")
		var cam := Camera3D.new()
		cam.fov = 70.0
		var h_half := atan(tan(deg_to_rad(35.0)) * 16.0 / 9.0)
		for s in spots:
			var local := view.affine_inverse() * (s + Vector3(0, 1.0, 0))
			assert_lt(local.z, 0.0, "in front of the lens")
			assert_lt(absf(atan2(local.x, -local.z)), h_half, "%d people: everyone in the picture" % n)
		cam.free()
	var face := T.face_yaw(1.2)
	var facing := Basis(Vector3.UP, face) * Vector3.FORWARD
	var to_camera := (T.camera_view(center, 1.2, 3, 70.0, _air).origin - center)
	to_camera.y = 0.0
	assert_gt(facing.dot(to_camera.normalized()), 0.99, "they face the camera")


func test_the_camera_never_stands_inside_a_block() -> void:
	var center := Vector3(0.5, 64, 0.5)
	var open := T.camera_view(center, 0.0, 3, 70.0, _air)
	var wall_z := floori(open.origin.z)
	var wall := func(cell: Vector3i) -> bool: return cell.z == wall_z
	var view := T.camera_view(center, 0.0, 3, 70.0, wall)
	assert_false(wall.call(Vector3i(view.origin.floor())), "moved out of the wall")
	assert_gte(center.distance_to(view.origin), T.MIN_DISTANCE - 0.01, "never in anyone's face")


func test_they_cheer_and_the_shot_comes_while_they_do() -> void:
	assert_true(EmotePoses.has(T.EMOTE))
	assert_gt(T.EMOTE_AT, 0.5, "a moment to line up first")
	assert_gt(T.SHOT_AT, T.EMOTE_AT)
	assert_lt(T.SHOT_AT - T.EMOTE_AT, float(EmotePoses.DURATIONS[T.EMOTE]), "mid-cheer")
