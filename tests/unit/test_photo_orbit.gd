extends GutTest
## Photo mode's free camera (M3 Task 16, spec §14.14): orbit, zoom and pan around the player with
## limits, and it never passes through or ends inside a block (so it can't peek into closed rooms).

const HEAD := Vector3(0.5, 11.55, 0.5)


static func _open_air(_cell: Vector3i) -> bool:
	return false


## Flat ground: every cell below y = 10 is solid.
static func _ground(cell: Vector3i) -> bool:
	return cell.y < 10


func _orbit(yaw: float = 0.0, pitch: float = 0.0, distance: float = 4.0) -> PhotoOrbit:
	var o := PhotoOrbit.new()
	o.yaw = yaw
	o.pitch = pitch
	o.distance = distance
	return o


func test_orbit_turns_with_the_finger_and_keeps_pitch_in_limits() -> void:
	var o := _orbit()
	o.orbit(Vector2(100, 0))
	assert_almost_eq(o.yaw, -100 * PhotoOrbit.ORBIT_SENSITIVITY, 0.0001, "drag right turns right")
	o.orbit(Vector2(0, -100000))
	assert_eq(o.pitch, PhotoOrbit.PITCH_MAX, "looking up stops")
	o.orbit(Vector2(0, 100000))
	assert_eq(o.pitch, PhotoOrbit.PITCH_MIN, "looking down stops")


func test_zoom_stays_between_the_near_and_far_limits() -> void:
	var o := _orbit()
	o.zoom(0.001)
	assert_eq(o.distance, PhotoOrbit.MIN_DISTANCE)
	o.zoom(1000.0)
	assert_eq(o.distance, PhotoOrbit.MAX_DISTANCE)
	o.zoom(0.5)
	assert_almost_eq(o.distance, PhotoOrbit.MAX_DISTANCE * 0.5, 0.0001, "a pinch zooms by its factor")


func test_zoom_ignores_broken_factors() -> void:
	var o := _orbit()
	for f: float in [0.0, -2.0, NAN, INF]:
		o.zoom(f)
		assert_eq(o.distance, 4.0, "factor %s" % f)


func test_limits_grow_with_a_giant_and_shrink_with_a_tiny_player() -> void:
	var giant := _orbit()
	giant.size_scale = SizeMagic.scale(SizeMagic.Mode.GIANT)
	giant.zoom(1000.0)
	assert_almost_eq(giant.distance, PhotoOrbit.MAX_DISTANCE * 3.0, 0.001)
	var tiny := _orbit()
	tiny.size_scale = SizeMagic.scale(SizeMagic.Mode.TINY)
	tiny.zoom(0.0001)
	assert_lt(tiny.distance, PhotoOrbit.MIN_DISTANCE, "a tiny player can come closer")
	assert_gt(tiny.distance, 0.0)


func test_pan_drags_the_picture_with_the_fingers() -> void:
	var o := _orbit()   # yaw 0, pitch 0: the camera looks along -Z, screen right is +X
	o.pan_by(Vector2(50, 0))
	assert_lt(o.pan.x, 0.0, "the picture moves right, so the look point moves left")
	assert_almost_eq(o.pan.y, 0.0, 0.0001)
	var up := _orbit()
	up.pan_by(Vector2(0, 50))
	assert_gt(up.pan.y, 0.0, "fingers down: the look point goes up")


func test_pan_never_goes_far_from_the_player() -> void:
	var o := _orbit()
	for i in 200:
		o.pan_by(Vector2(400, 300))
	assert_almost_eq(o.pan.length(), PhotoOrbit.MAX_PAN, 0.001)


func test_in_open_air_the_camera_sits_behind_the_look_point() -> void:
	var o := _orbit(0.0, 0.0, 5.0)
	var t := o.place(HEAD, _open_air)
	assert_almost_eq(t.origin.distance_to(HEAD + Vector3(0, 0, 5)), 0.0, 0.001)
	assert_almost_eq((-t.basis.z).dot(Vector3.FORWARD), 1.0, 0.001, "and looks at the player")


func test_a_wall_behind_stops_the_camera_in_front_of_it() -> void:
	var wall := func(cell: Vector3i) -> bool: return cell.z >= 3
	var t := _orbit(0.0, 0.0, 8.0).place(HEAD, wall)
	assert_lte(t.origin.z, 3.0 - PhotoOrbit.MARGIN + 0.001, "stops before the wall")
	assert_gt(t.origin.z, HEAD.z, "but still behind the player")


func test_a_thin_wall_hides_what_is_behind_it() -> void:
	var wall := func(cell: Vector3i) -> bool: return cell.z == 2
	var t := _orbit(0.0, 0.0, 10.0).place(HEAD, wall)
	assert_lt(t.origin.z, 2.0, "the camera never gets through to the other side")


func test_the_camera_never_goes_under_the_ground() -> void:
	for pitch: float in [PhotoOrbit.PITCH_MAX, 0.9, 0.4]:
		for yaw: float in [0.0, 1.3, -2.4]:
			var t := _orbit(yaw, pitch, PhotoOrbit.MAX_DISTANCE).place(HEAD, _ground)
			assert_gt(t.origin.y, 10.0, "pitch %s yaw %s" % [pitch, yaw])
			assert_false(PhotoOrbit.near_block(t.origin, _ground), "clear of the ground at pitch %s" % pitch)


func test_the_camera_never_ends_inside_a_block() -> void:
	# A narrow corridor along -Z..+Z with walls at x < 0 and x > 0, a floor and a low ceiling.
	var corridor := func(cell: Vector3i) -> bool: return cell.x != 0 or cell.y < 10 or cell.y > 12
	for yaw in range(0, 8):
		for pitch: float in [-1.2, -0.4, 0.0, 0.6]:
			var t := _orbit(yaw * PI / 4.0, pitch, 9.0).place(HEAD, corridor)
			assert_false(corridor.call(Vector3i(t.origin.floor())), "yaw %d pitch %s in a wall" % [yaw, pitch])


func test_panning_into_a_wall_stops_the_look_point_before_it() -> void:
	var wall := func(cell: Vector3i) -> bool: return cell.x >= 3
	var o := _orbit(0.0, 0.0, 0.0001)
	o.pan = Vector3(PhotoOrbit.MAX_PAN, 0, 0)
	var t := o.place(HEAD, wall)
	assert_lt(t.origin.x, 3.0, "never inside or past the wall")


func test_it_starts_where_the_game_camera_is() -> void:
	var b := Basis.from_euler(Vector3(-0.35, 0.8, 0.0))
	var cam := Transform3D(b, HEAD + b * Vector3(0, 0, 4.5))
	var o := PhotoOrbit.from_camera(cam, HEAD, 1.0)
	assert_almost_eq(o.yaw, 0.8, 0.0001)
	assert_almost_eq(o.pitch, -0.35, 0.0001)
	assert_almost_eq(o.distance, 4.5, 0.001)
	assert_eq(o.pan, Vector3.ZERO)
	var t := o.place(HEAD, _open_air)
	assert_almost_eq(t.origin.distance_to(cam.origin), 0.0, 0.001, "no jump when photo mode opens")


func test_from_first_person_it_steps_back_to_show_the_player() -> void:
	var cam := Transform3D(Basis.from_euler(Vector3(0.2, 1.0, 0.0)), HEAD)
	var o := PhotoOrbit.from_camera(cam, HEAD, 1.0)
	assert_eq(o.distance, PhotoOrbit.DEFAULT_DISTANCE)
