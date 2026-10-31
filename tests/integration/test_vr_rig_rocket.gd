extends GutTest
## Owner #101 (VR on the Meta Quest), P3: the rocket flight in a headset (Vr.simulate). The child sits in the capsule
## from the start (a fade cut, never the boarding's glide), the view is INSIDE only, the seat carries the head with no
## shake and turns at most 15° a second however the rocket turns and the child steers, the head draws what the flight's
## camera would (its layers, space's environment) and the world again after, the capsule's dashboard is where VR-UI's
## quad goes, the trigger is the throttle while seated, and the flight still lands on the Moon. A crew member sits in its
## own seat. Off VR nothing of this exists (test_rocket_flight.gd, test_crew_flights.gd).

var flight: RocketFlight
var ui: Control
var stand: Node3D


func before_each() -> void:
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.make_current()
	ui = Control.new()
	ui.size = Vector2(1280, 720)
	add_child_autofree(ui)
	stand = Node3D.new()   # stands in for the player's feet
	add_child_autofree(stand)
	Vr.simulate(true)
	Vr.anchor(stand, &"feet")
	flight = RocketFlight.new()
	flight.auto_tick = false
	flight.ui_parent = ui
	add_child_autofree(flight)
	FlightTicket.parked = {}


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	FlightTicket.parked = {}
	FlightTicket.test_pending = 0
	Input.action_release(&"rocket_throttle")


## Plays the flight as test_rocket_flight's child does (presses what is asked, holds burns), steering hard to the
## right in every steering step; `each(t)` after every tick.
func _fly(each: Callable, max_seconds: float = 400.0, delta: float = 0.1) -> void:
	var t := 0.0
	while flight.is_active() and t < max_seconds:
		var waiting := flight.run.waiting_for()
		flight.cockpit.throttle = flight.run.test_throttle()   # owner #106: the descent flown well too
		flight.cockpit.stick = Vector2(1.0, 0.4)
		if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			flight.cockpit.action_pressed.emit()
		flight.tick(delta)
		t += delta
		each.call(t)


func test_the_child_sits_in_the_capsule_from_the_start() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	assert_true(Vr.seated(), "the seat is the anchor")
	assert_eq(Vr.anchor_node(), flight.get_node("VrSeat"))
	assert_eq(Vr.fade_amount(), 1.0, "a fade cut into it, no glide from the pad")
	var seat_at: Vector3 = flight.body.global_transform * flight.body.seat()
	assert_almost_eq(Vr.head_transform().origin.distance_to(seat_at), 0.0, 0.01, "the eye on the seat")
	assert_eq(get_viewport().get_camera_3d(), Vr.camera, "the head is the view, not the flight's camera")
	var dash := flight.vr_dashboard()
	assert_not_null(dash, "the dashboard for VR-UI's quad")
	assert_eq(flight.get_path_to(dash), NodePath("VrSeat/VrCapsule/Dashboard"), "the agreed path")
	var local := Vr.head_transform().affine_inverse() * dash.global_position
	assert_lt(local.z, 0.0, "ahead of the eyes")
	assert_lt(local.y, 0.0, "a little below them")


func test_the_view_is_inside_only_whatever_asks_for_the_chase() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	flight.view = FlightPlan.CHASE
	assert_eq(flight._view(), FlightPlan.INSIDE)
	flight._on_view_pressed()
	assert_eq(flight._view(), FlightPlan.INSIDE, "VIEW does nothing in VR")


func test_no_shake_and_the_seat_never_turns_faster_than_15_degrees_a_second() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var seat := flight.get_node("VrSeat") as Node3D
	# (a lambda's locals are copies: what it finds goes into this dictionary)
	var st := {"last": seat.global_basis, "fastest": 0.0, "off_seat": 0.0, "steered": false, "shakes": 0}
	_fly(func(_t: float) -> void:
		var b := seat.global_basis
		st.fastest = maxf(st.fastest, rad_to_deg(Quaternion(b).angle_to(Quaternion(st.last as Basis))) / 0.1)
		st.last = b
		st.steered = st.steered or flight.steering.off.length() > 5.0
		st.off_seat = maxf(st.off_seat, Vr.head_transform().origin.distance_to(seat.global_position))
		if float(flight.pose.shake) != 0.0:
			st.shakes += 1)
	assert_true(st.steered, "the child steered (the rocket's nose turned)")
	assert_eq(st.shakes, 0, "no shake in VR")
	assert_lte(st.fastest, VrRules.SEAT_TURN_DEGREES + 0.01, "at most 15° a second")
	assert_lt(st.off_seat, 0.01, "the head never leaves the seat (no shake, no blends)")
	assert_false(flight.is_active(), "and it landed")
	assert_eq(int(FlightTicket.parked.get("destination", -1)), SpaceRules.MOON)


func test_the_head_draws_what_the_flights_camera_would_and_the_world_after() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var t := 0.0
	while flight.is_active() and not flight._in_space and t < 200.0:
		var waiting := flight.run.waiting_for()
		flight.cockpit.throttle = flight.run.test_throttle()   # owner #106: the descent flown well too
		if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
			flight.cockpit.action_pressed.emit()
		flight.tick(0.1)
		t += 0.1
	assert_true(flight._in_space, "up in space")
	assert_not_null(Vr.camera.environment)
	assert_eq(Vr.camera.environment, flight.camera.environment, "space's black sky and stars")
	assert_eq(Vr.camera.cull_mask, flight.camera.cull_mask | VrRules.HANDS_LAYER, "the flight's layers and the child's hands (owner #126)")
	assert_gte(Vr.camera.far, RocketFlight.SPACE_FAR * 0.99, "far enough for the planets")
	flight.abort()
	assert_false(Vr.seated())
	assert_eq(Vr.anchor_node(), stand, "back at the feet")
	assert_null(Vr.camera.environment, "the world's own sky again")
	assert_eq(Vr.camera.far, VrRig.FAR)


func test_the_trigger_is_the_throttle_while_seated() -> void:
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	Vr.sim_input(VrRules.RIGHT, &"trigger", 1.0)
	Vr.input.step(0.016, null)
	Input.flush_buffered_events()
	assert_true(Input.is_action_pressed(&"rocket_throttle"), "the right trigger pushes the throttle")
	Vr.sim_input(VrRules.RIGHT, &"trigger", 0.0)
	Vr.input.step(0.016, null)
	Input.flush_buffered_events()
	assert_false(Input.is_action_pressed(&"rocket_throttle"))


func test_a_crew_member_sits_in_its_own_seat() -> void:
	flight.crew_size = 2
	flight.seat = 1
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	var middle: Vector3 = flight.body.global_transform * flight.body.seat()
	var at := Vr.head_transform().origin
	assert_almost_eq(at.distance_to(middle), RocketFlight.SEAT_GAP * 0.5, 0.01, "half a seat's gap from the middle")


func test_off_vr_a_flight_has_no_seat_nor_capsule() -> void:
	Vr.simulate(false)
	flight.start(RocketStages.test_rocket(SpaceRules.MOON, 2), 1)
	assert_null(flight.get_node_or_null("VrSeat"))
	assert_null(flight.vr_dashboard())
	assert_false(bool(flight._info().get("vr", true)), "the flat game's shots, shake and all")
