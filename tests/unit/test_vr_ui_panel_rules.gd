extends GutTest
## Owner #101 (VR on the Meta Quest), the panel side: where the VR canvas (the game's 1280×720 of 2D UI) shows in the
## world and how a hand's ray lands on it (VrPanelRules, pure). The EYE panel: 1.6 × 0.9 m, 1.4 m ahead, level with the
## eyes' yaw (never pitched or rolled with the head), re-centred only past 50°. The TRAY: 1 m wide, 0.9 m away, 35°
## below the eyes, facing them, lazily following the head's yaw. Only the front of a panel takes a pointer.


func _head(yaw_deg: float, pitch_deg: float = 0.0, at := Vector3(2, 1.6, -3)) -> Transform3D:
	var b := Basis(Vector3.UP, deg_to_rad(yaw_deg)) * Basis(Vector3.RIGHT, deg_to_rad(pitch_deg))
	return Transform3D(b, at)


func test_the_heads_yaw_ignores_pitch_and_survives_looking_straight_down() -> void:
	for yaw: float in [0.0, 45.0, 90.0, -135.0]:
		for pitch: float in [0.0, -40.0, 30.0]:
			assert_almost_eq(rad_to_deg(VrPanelRules.head_yaw(_head(yaw, pitch))), yaw, 0.01, "yaw %s pitch %s" % [yaw, pitch])
	assert_almost_eq(rad_to_deg(VrPanelRules.head_yaw(_head(60.0, -90.0))), 60.0, 0.5, "looking at the feet")
	assert_almost_eq(rad_to_deg(VrPanelRules.head_yaw(_head(-30.0, 89.0))), -30.0, 0.5, "looking at the sky")


func test_the_eye_panel_stands_ahead_level_and_faces_the_child() -> void:
	var head := _head(90.0, -30.0)   # turned left, looking down
	var p := VrPanelRules.eye_transform(head)
	var flat := Vector3(p.origin.x - head.origin.x, 0.0, p.origin.z - head.origin.z)
	assert_almost_eq(flat.length(), VrPanelRules.EYE_DISTANCE, 0.001, "1.4 m away")
	assert_almost_eq(flat.normalized().dot(Vector3.LEFT), 1.0, 0.001, "where the head looks (its yaw)")
	assert_almost_eq(p.origin.y, head.origin.y - VrPanelRules.EYE_DROP, 0.001, "a little below the eyes, whatever the pitch")
	assert_almost_eq(p.basis.y.dot(Vector3.UP), 1.0, 0.001, "never tilted")
	var to_head := (head.origin - p.origin)
	to_head.y = 0.0
	assert_almost_eq(p.basis.z.dot(to_head.normalized()), 1.0, 0.001, "its front (+Z) faces the child")


func test_the_eye_panel_is_re_centred_only_past_fifty_degrees() -> void:
	assert_false(VrPanelRules.needs_recentre(0.0, deg_to_rad(49.0)))
	assert_true(VrPanelRules.needs_recentre(0.0, deg_to_rad(51.0)))
	assert_true(VrPanelRules.needs_recentre(deg_to_rad(170.0), deg_to_rad(-120.0)), "across the back (70°)")
	assert_false(VrPanelRules.needs_recentre(deg_to_rad(170.0), deg_to_rad(-170.0)), "20° across ±180")


func test_the_tray_sits_low_and_faces_the_eyes() -> void:
	var head := _head(-45.0)
	var t := VrPanelRules.tray_transform(head.origin, deg_to_rad(-45.0))
	var off := t.origin - head.origin
	assert_almost_eq(off.length(), VrPanelRules.TRAY_DISTANCE, 0.001)
	assert_almost_eq(rad_to_deg(asin(-off.y / off.length())), VrPanelRules.TRAY_DOWN_DEGREES, 0.01, "35° below the eyes")
	assert_almost_eq(t.basis.z.dot((head.origin - t.origin).normalized()), 1.0, 0.001, "tilted to face the eyes")
	var flat := Vector3(off.x, 0, off.z).normalized()
	assert_almost_eq(flat.dot((-head.basis.z).normalized()), 1.0, 0.001, "in front of the head's yaw")


func test_the_tray_waits_inside_its_slack_then_catches_up() -> void:
	var r := VrPanelRules.tray_yaw(0.0, deg_to_rad(20.0), false, 0.1)
	assert_eq(r[0], 0.0, "a glance aside (20°) leaves the tray where it is")
	assert_false(r[1])
	var yaw := 0.0
	var following := false
	for i in 120:   # turned 60° and held: it follows, then rests in front again
		var step := VrPanelRules.tray_yaw(yaw, deg_to_rad(60.0), following, 1.0 / 60.0)
		yaw = step[0]
		following = step[1]
	assert_almost_eq(rad_to_deg(yaw), 60.0, 2.5, "caught up within two seconds")
	assert_false(following, "and rests")


func test_a_ray_from_the_front_lands_on_the_canvas_pixel() -> void:
	var head := _head(0.0)
	var p := VrPanelRules.eye_transform(head)
	var size := VrPanelRules.EYE_SIZE
	# Straight at the middle.
	var mid := VrPanelRules.hit(p, size, head.origin + Vector3(0, -VrPanelRules.EYE_DROP, 0), Vector3.FORWARD)
	assert_almost_eq(Vector2(mid.x, mid.y), Vector2(0.5, 0.5), Vector2(0.001, 0.001))
	assert_almost_eq(mid.z, VrPanelRules.EYE_DISTANCE, 0.001, "the distance to the panel (the laser stops there)")
	# At its top-left quarter: 0.4 m left and 0.225 m up of the middle.
	var corner := p.origin + Vector3(-0.4, 0.225, 0)
	var origin := Vector3(0.3, 0.9, 1.0)
	var q := VrPanelRules.hit(p, size, origin, (corner - origin).normalized())
	assert_almost_eq(Vector2(q.x, q.y), Vector2(0.25, 0.25), Vector2(0.001, 0.001))
	assert_eq(VrPanelRules.pixel(Vector2(q.x, q.y)), Vector2(320, 180), "canvas pixels (1280×720)")


func test_a_ray_that_misses_or_comes_from_behind_takes_nothing() -> void:
	var p := VrPanelRules.eye_transform(_head(0.0))
	var size := VrPanelRules.EYE_SIZE
	assert_eq(VrPanelRules.hit(p, size, Vector3(0, 1.5, 0), Vector3.UP), VrPanelRules.MISS, "parallel / away")
	assert_eq(VrPanelRules.hit(p, size, Vector3(3, 1.5, 0), Vector3.FORWARD), VrPanelRules.MISS, "beside it")
	assert_eq(VrPanelRules.hit(p, size, p.origin + Vector3(0, 0, -1), Vector3.BACK), VrPanelRules.MISS, "from behind")
	assert_eq(VrPanelRules.hit(p, size, Vector3(0, 1.5, 0), Vector3.BACK), VrPanelRules.MISS, "pointing the other way")


func test_the_eye_panel_shows_for_menus_pauses_and_loading_else_the_tray() -> void:
	assert_eq(VrPanelRules.place_for(true, false, false), VrPanelRules.EYE, "a panel has the pad")
	assert_eq(VrPanelRules.place_for(false, true, false), VrPanelRules.EYE, "paused")
	assert_eq(VrPanelRules.place_for(false, false, true), VrPanelRules.EYE, "a world loads")
	assert_eq(VrPanelRules.place_for(false, false, false), VrPanelRules.TRAY, "playing: the HUD on the tray")


func test_the_eye_panel_is_about_one_canvas_pixel_per_quest_2_pixel() -> void:
	# Quest 2: about 20 pixels a degree. 1280 px over the panel's width as seen from 1.4 m.
	var degrees := rad_to_deg(2.0 * atan(VrPanelRules.EYE_SIZE.x * 0.5 / VrPanelRules.EYE_DISTANCE))
	var per_degree := VrPanelRules.CANVAS.x / degrees
	gut.p("eye panel: %.1f° wide, %.1f canvas px a degree" % [degrees, per_degree])
	assert_between(per_degree, 18.0, 26.0)
	assert_almost_eq(VrPanelRules.EYE_SIZE.x / VrPanelRules.EYE_SIZE.y, 16.0 / 9.0, 0.001, "the canvas's shape")
	assert_almost_eq(VrPanelRules.TRAY_SIZE.x / VrPanelRules.TRAY_SIZE.y, 16.0 / 9.0, 0.001)
