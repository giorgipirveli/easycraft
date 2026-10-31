extends GutTest
## Owner #101 (VR on the Meta Quest), P3's pure rules: where a teleport may land (TeleportRules: standable, at most 1
## block up, at most 6 m, in sight, never into a hiding spot or a game's area), the vignette for motion the child did not
## make (speed, falls, a ride's or a gadget's accelerations), the guest's mount predicted (an alpha-beta filter), the
## seated rocket's turn capped at 15° a second, the teleport stick, and the flight's shots in VR (no shake, softer flashes,
## the head free).

## A floor of stone under y 10, a 1-block step at x 3..4, a 2-block wall at x -3, a barrel at (0, 10, 4).
func _block(p: Vector3i) -> int:
	if p.y < 10:
		return BlockIds.STONE
	if p.y == 10 and p.x >= 3 and p.x <= 4 and p.z >= -1 and p.z <= 1:
		return BlockIds.STONE
	if p.x == -3 and p.y <= 11 and p.z >= -2 and p.z <= 2:
		return BlockIds.STONE
	if p == Vector3i(0, 10, 4):
		return BlockIds.BARREL
	return BlockIds.AIR


func _never(_at: Vector3) -> bool:
	return false


func _check(at: Vector3, refuse: Callable = _never) -> String:
	var feet := Vector3(0.5, 10.0, 0.5)
	return TeleportRules.check(feet, feet + Vector3(0, CameraRig.HEAD_HEIGHT, 0), at, 0.3, 2, _block, refuse)


func test_a_teleport_lands_on_ground_with_room_for_the_body() -> void:
	assert_eq(_check(Vector3(0.5, 10.0, -3.5)), "", "flat ground 4 m ahead")
	assert_eq(_check(Vector3(3.5, 11.0, 0.5)), "", "up one block: as a step")


func test_no_wall_climbing_and_no_gaps_over_6_m() -> void:
	assert_eq(_check(Vector3(-2.5, 12.0, 0.5)), TeleportRules.UP, "on top of a 2-block wall: walking can't")
	assert_eq(_check(Vector3(0.5, 10.0, -5.8)), TeleportRules.FAR, "6.3 m away")
	assert_eq(_check(Vector3(0.5, 10.0, -4.9)), "", "5.4 m: fine")
	assert_eq(_check(Vector3(0.9, 10.0, 0.5)), TeleportRules.NEAR, "where the child stands: nowhere to go")


func test_never_into_a_hiding_spot_nor_a_games_area() -> void:
	assert_eq(_check(Vector3(0.5, 11.0, 4.5)), TeleportRules.SPOT, "on a barrel")
	assert_eq(_check(Vector3(0.5, 10.0, -3.5), func(_at: Vector3) -> bool: return true), TeleportRules.AREA,
		"a race, a course or a game says no")


func test_never_inside_blocks_nor_out_of_sight() -> void:
	assert_eq(_check(Vector3(3.5, 10.0, 0.5)), TeleportRules.ROOM, "inside the step")
	assert_eq(_check(Vector3(-4.5, 10.0, 0.5)), TeleportRules.SIGHT, "behind the wall")


func test_the_arc_falls_from_the_hand_and_finds_where_it_lands() -> void:
	var feet := Vector3(0.5, 10.0, 0.5)
	var eye := feet + Vector3(0, CameraRig.HEAD_HEIGHT, 0)
	var hand := feet + Vector3(0.2, 1.1, -0.2)
	var t := TeleportRules.target(hand, Vector3(0, 0.4, -1).normalized(), feet, eye, 0.3, 2, _block, _never)
	assert_true(t.ok, "a throw ahead lands on the floor: %s" % t.why)
	assert_almost_eq((t.at as Vector3).y, 10.0, 0.001, "on top of the floor")
	assert_lt((t.at as Vector3).z, -1.0, "ahead")
	var pts: PackedVector3Array = t.points
	assert_gt(pts.size(), 3)
	assert_lt(pts[pts.size() - 1].y, pts[0].y, "it falls")
	var up := TeleportRules.target(hand, Vector3.UP, feet, eye, 0.3, 2, _block, _never)
	assert_false(up.ok, "straight up comes back down on the child: too close is nowhere to go")


func test_the_teleport_stick_aims_while_up_and_goes_on_release() -> void:
	var s := VrRules.teleport_step(0.9, false)
	assert_true(s.aim)
	assert_false(s.go)
	s = VrRules.teleport_step(0.6, s.aim)
	assert_true(s.aim, "held on: still aiming")
	s = VrRules.teleport_step(0.1, s.aim)
	assert_false(s.aim)
	assert_true(s.go, "let go: there")
	s = VrRules.teleport_step(-0.9, false)
	assert_false(s.aim, "down is nothing")


func test_the_vignette_darkens_for_motion_the_child_did_not_make() -> void:
	var walk := VrRules.vignette_motion("light", Vector3(6, 0, 0), 40.0, false, false)
	assert_eq(walk, VrRules.vignette("light", 6.0, false), "walking: the speed's, its own acceleration never counts")
	var ride := VrRules.vignette_motion("light", Vector3(3, 0, 0), 0.0, true, false)
	assert_gt(ride, VrRules.vignette_motion("light", Vector3(3, 0, 0), 0.0, false, false), "a ride: stronger")
	var pushed := VrRules.vignette_motion("light", Vector3.ZERO, 8.0, true, false)
	assert_gt(pushed, 0.0, "a ride speeding up, a hook's pull, a pad's throw")
	assert_eq(VrRules.vignette_motion("light", Vector3.ZERO, 8.0, false, false), 0.0)
	var fall := VrRules.vignette_motion("light", Vector3(0, -15, 0), 0.0, false, false)
	assert_eq(fall, VrRules.VIGNETTE_STRENGTH["light"], "a long fall: full")
	assert_eq(VrRules.vignette_motion("off", Vector3(0, -15, 0), 9.0, true, false), 0.0, "off is off")
	assert_lte(VrRules.vignette_motion("strong", Vector3(9, -20, 0), 50.0, true, false), 1.0)


func test_the_vignette_comes_quickly_and_goes_slowly() -> void:
	var up := VrRules.ease_vignette(0.0, 1.0, 0.05)
	var down := VrRules.ease_vignette(1.0, 0.0, 0.05)
	assert_gt(up, 1.0 - down, "it closes faster than it opens")
	assert_eq(VrRules.ease_vignette(0.3, 0.3, 0.05), 0.3)


func test_a_guests_mount_is_followed_smoothly_without_lagging_a_steady_ride() -> void:
	var x := Vector3.ZERO
	var v := Vector3.ZERO
	var dt := 1.0 / 60.0
	var speeds := 0.0
	var biggest_jump := 0.0
	for i in 240:   # 4 s at 5 m/s, the place arriving in steps of 10 a second (a creature's sync)
		var z := Vector3(floorf(i / 6.0) * 6.0 * dt * 5.0, 0, 0)
		var r := VrRules.alpha_beta(x, v, z, dt)
		if i >= 180:
			speeds += (r[1] as Vector3).x
			biggest_jump = maxf(biggest_jump, ((r[0] as Vector3) - x).x)
		x = r[0]
		v = r[1]
	assert_almost_eq(speeds / 60.0, 5.0, 0.3, "it knows the speed")
	assert_lt(biggest_jump, 6.0 * dt * 5.0 * 0.5, "never a step as big as the syncs' (it glides between them)")
	var truth := 239 * dt * 5.0
	assert_lt(absf(x.x - truth), 0.35, "it keeps up (no growing lag)")


func test_the_seated_turn_is_capped() -> void:
	var from := Basis()
	var to := Basis(Vector3.UP, deg_to_rad(90.0))
	var b := VrRules.turn_toward(from, to, deg_to_rad(VrRules.SEAT_TURN_DEGREES) * 0.5)
	assert_almost_eq(rad_to_deg(Quaternion(b).angle_to(Quaternion(from))), VrRules.SEAT_TURN_DEGREES * 0.5, 0.01,
		"half a second: 7.5°, not 90")
	assert_eq(VrRules.turn_toward(from, Basis(Vector3.UP, 0.01), 0.5), Basis(Vector3.UP, 0.01), "a small turn: there")


func test_in_vr_the_flight_never_shakes_and_its_flashes_are_softer() -> void:
	for phase: StringName in [FlightPlan.COUNTDOWN, FlightPlan.LIFTOFF, FlightPlan.ASCENT, FlightPlan.JUMP, FlightPlan.ENTRY,
			FlightPlan.LANDING, FlightPlan.WARP]:
		for q: float in [0.0, 0.2, 0.35, 0.45, 0.8, 1.0]:
			var flat := FlightShots.pose(phase, q, {"destination": SpaceRules.MARS, "waiting": FlightPlan.THROTTLE,
				"throttle": 1.0, "done": true})
			var vr := FlightShots.pose(phase, q, {"destination": SpaceRules.MARS, "waiting": FlightPlan.THROTTLE,
				"throttle": 1.0, "done": true, "vr": true})
			assert_eq(vr.shake, 0.0, "%s %s: no shake" % [phase, q])
			assert_lte(float(vr.flash), float(flat.flash) * 0.5 + 0.0001, "%s %s: half the flash" % [phase, q])
			assert_lte(float(vr.cloud), float(flat.cloud), "%s %s: a softer white-out" % [phase, q])
			assert_eq(vr.look_pitch, 0.0, "the head looks where the child looks")
