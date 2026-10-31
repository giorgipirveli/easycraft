extends GutTest
## Owner #109 in VR (the Quest; Vr.simulate's fakes): a child sits in the car as on a ride: the origin follows the seated
## body (the car's seat), a black blink on getting in and out, facing the car's front as one gets in, the comfort
## vignette's stronger rule for motion the child did not make (Player.vr_passive_motion), the walking stick drives, and
## the camera never swings round by itself (no camera move the child did not make).

class FloorWorld:
	extends WorldService

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 10 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 9


var p: Player
var director: VehicleDirector
var _name_before := ""


func before_each() -> void:
	_name_before = Profile.data.username
	Profile.data.username = "Kid"
	var w := FloorWorld.new()
	add_child_autofree(w)
	Session.register_world(w)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200, 1, 200)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0, 9.5, 0)
	add_child_autofree(ground)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 10, 0.5)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	director = VehicleDirector.new()
	director.name = "Vehicles"
	director.host_checks = false
	director.save_profile = func() -> void: pass
	add_child_autofree(director)
	director.set_process(false)
	director.setup_local(p, null, self)
	var rides := RideDirector.new()
	rides.name = "Rides"
	rides.host_checks = false
	rides.cars = director
	add_child_autofree(rides)
	rides.set_process(false)
	rides.setup_local(p, null)


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Session.register_world(null)
	Profile.data.username = _name_before


func _frame() -> void:
	Vr.step_physics()
	Vr.step(1.0 / 72.0)


func test_getting_in_blinks_faces_the_front_and_sits_on_the_seat() -> void:
	director.host_car(p.peer_id, CarKinds.OFF_ROADER, 0, 1.0)
	var car := director.car_of("Kid", CarKinds.OFF_ROADER)
	assert_not_null(car)
	await get_tree().physics_frame
	for i in 20:
		_frame()
	assert_lt(Vr.fade_amount(), 0.5, "clear before")
	assert_eq(director.host_get_in(p.peer_id, String(car.name)), "")
	assert_gt(Vr.fade_amount(), 0.5, "a black blink on getting in")
	assert_almost_eq(angle_difference(VrRules.yaw_of(Vr.head_transform().basis), car.rotation.y), 0.0, 0.05,
		"facing the car's front")
	p._process(1.0 / 72.0)
	assert_almost_eq(p.global_position, car.seat_position(p.peer_id), Vector3.ONE * 0.001, "the body on the seat")
	assert_eq(Vr.anchor_node(), p, "the origin follows the seated body, as on a ride")
	assert_true(p.vr_passive_motion(), "a car's motion is one the child did not make: the vignette's stronger rule")
	assert_false(p.vr_may_teleport(), "no teleport from a seat")


func test_the_camera_never_swings_by_itself_in_vr_and_getting_out_blinks() -> void:
	director.host_car(p.peer_id, CarKinds.RACE_CAR, 0, 0.0)
	var car := director.car_of("Kid", CarKinds.RACE_CAR)
	await get_tree().physics_frame
	director.host_get_in(p.peer_id, String(car.name))
	for i in 40:
		_frame()
	car.rotation.y = 1.2
	car.shown_speed = 12.0
	var yaw := p.rig.yaw
	director.local_step(0.5)
	assert_eq(p.rig.yaw, yaw, "never a camera move the child did not make")
	for i in 40:
		_frame()
	assert_lt(Vr.fade_amount(), 0.5)
	director.host_get_out(p.peer_id)
	assert_false(p.in_car())
	assert_gt(Vr.fade_amount(), 0.5, "a black blink on getting out")
