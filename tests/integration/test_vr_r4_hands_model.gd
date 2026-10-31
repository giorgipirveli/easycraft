extends GutTest
## Owner #110, VR round 4 idea 6 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md): MODEL VIEW with fake hands (Vr.simulate)
## on a real Player. The child becomes a giant over their world (behind a blink, the ground at the real floor), the body
## waits where it stood; the little figure of them is taken (near, or pulled up by the laser) and put down: on a good
## spot they go there at their own size, on a bad one it goes back; two hands twist the world in 45° steps; MORE → MODEL
## VIEW again ends it; the Sandbox only; nothing off VR.

const ME_AT := Vector3(0.5, 10.0, 0.5)
const DT := 1.0 / 72.0


class GrassWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)


var p: Player
var _mode_before: StringName
var _settings := {}


func before_each() -> void:
	_settings = Profile.data.settings.duplicate()
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	var w := GrassWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.set_process_unhandled_input(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = ME_AT
	(p.get_node("BlockInteractor") as BlockInteractor).set_process_unhandled_input(false)
	Vr.simulate(true)
	Vr.anchor(p, &"feet")
	_frame()


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)
	Input.flush_buffered_events()
	Game.mode = _mode_before
	Profile.data.settings.clear()
	Profile.data.settings.merge(_settings)


func _frame() -> void:
	Vr.step_physics()
	Vr.step(DT)
	Input.flush_buffered_events()
	p.rig._process(DT)
	p._process(DT)


func _hand_at(side: StringName, world_at: Vector3) -> void:
	# the fake trackers are the play space's, before the world scale (XRServer.world_scale)
	Vr.sim_hand(side, Transform3D(Basis(), (Vr.rig.global_transform.affine_inverse() * world_at) / Vr.world_scale()))
	_frame()


func test_model_view_makes_the_child_a_giant_over_their_world_behind_a_blink() -> void:
	assert_true(Vr.toggle_model_view(), "open in the Sandbox")
	assert_true(Vr.model_view_open())
	assert_eq(Vr.world_scale(), ModelViewRules.SCALE, "25 times their size")
	assert_gt(Vr.fade_amount(), 0.5, "behind a blink")
	_frame()
	var head_up := Vr.head_transform().origin.y - ME_AT.y
	assert_almost_eq(head_up, Vr.PREVIEW_EYE * ModelViewRules.SCALE, 1.0, "standing on the ground: the head 40 m up")
	assert_null(Vr.local_player(), "the origin's anchor is a still spot, not the body")
	assert_true(Vr.body_waits())


func test_the_body_waits_where_it_stood() -> void:
	Vr.toggle_model_view()
	Vr.sim_input(VrRules.LEFT, &"primary", Vector2(0.0, 1.0))   # the walking stick pushed
	Vr.sim_input(VrRules.RIGHT, &"ax_button", true)              # A: jump
	_frame()
	assert_eq(Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back"), Vector2.ZERO, "no walking")
	assert_false(Input.is_action_pressed(&"jump"), "no jumping")
	Vr.sim_input(VrRules.LEFT, &"primary", Vector2.ZERO)
	Vr.sim_input(VrRules.RIGHT, &"ax_button", false)
	_frame()
	assert_almost_eq(p.global_position.distance_to(ME_AT), 0.0, 0.001)


func test_the_sandbox_only() -> void:
	Game.mode = ModeRules.SURVIVOR
	assert_false(Vr.toggle_model_view(), "R6: not in Survivor")
	assert_false(Vr.model_view_open())


func _take_the_figure() -> VrModelView:
	Vr.toggle_model_view()
	_frame()
	var mv := Vr.model_view
	_hand_at(VrRules.RIGHT, mv.pin.global_position)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_frame()
	return mv


func test_the_figure_put_down_on_a_good_spot_takes_the_child_there() -> void:
	var mv := _take_the_figure()
	assert_eq(mv.pin.held_by(), VrRules.RIGHT, "the little figure in the giant's hand")
	_hand_at(VrRules.RIGHT, Vector3(12.5, 14.0, 0.5))   # over the grass 12 m away
	assert_true(mv.landing_ok, "a green ring: the child could stand there")
	assert_almost_eq(mv.landing, Vector3(12.5, 10.0, 0.5), Vector3.ONE * 0.01)
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	_frame()
	assert_almost_eq(p.global_position, Vector3(12.5, 10.0, 0.5), Vector3.ONE * 0.01, "there, at their own size")
	assert_false(Vr.model_view_open())
	assert_eq(Vr.world_scale(), 1.0)
	assert_eq(Vr.local_player(), p, "the body is the anchor again")
	assert_gt(Vr.fade_amount(), 0.5, "behind the black")


func test_a_figure_put_down_where_the_child_cant_stand_goes_back() -> void:
	var mv := _take_the_figure()
	_hand_at(VrRules.RIGHT, Vector3(300.5, 14.0, 0.5))   # past the model's land
	assert_false(mv.landing_ok, "a red ring")
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	_frame()
	assert_true(Vr.model_view_open(), "still the giant")
	assert_almost_eq(mv.figure.global_position, p.global_position, Vector3.ONE * 0.01, "the figure back at the body")
	assert_almost_eq(p.global_position, ME_AT, Vector3.ONE * 0.001)


func test_the_laser_pulls_the_figure_up_off_the_floor() -> void:
	Vr.toggle_model_view()
	_frame()
	var mv := Vr.model_view
	var hand := Vr.hand_grip(VrRules.RIGHT).origin
	var dir := (mv.pin.global_position - hand).normalized()
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis.looking_at(Vr.rig.global_basis.inverse() * dir), (Vr.rig.global_transform.affine_inverse() * hand) / Vr.world_scale()))
	_frame()
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	for i in ceili((VrGrabRules.PULL_HOLD + VrGrabRules.PULL_TIME + 0.1) / DT):
		_frame()
	assert_eq(mv.pin.held_by(), VrRules.RIGHT, "no bending down: it came up to the hand")


func test_two_hands_twist_the_world_in_45_degree_steps() -> void:
	Vr.toggle_model_view()
	_frame()
	var yaw0 := Vr.rig.yaw
	Vr.sim_hand(VrRules.LEFT, Transform3D(Basis(), Vector3(-0.3, 1.2, -0.3)))
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.3, 1.2, -0.3)))
	_frame()
	Vr.sim_input(VrRules.LEFT, &"grip", 1.0)
	Vr.sim_input(VrRules.RIGHT, &"grip", 1.0)
	_frame()
	var a := deg_to_rad(50.0)
	Vr.sim_hand(VrRules.LEFT, Transform3D(Basis(), Vector3(-0.3 * cos(a), 1.2, -0.3 + 0.3 * sin(a))))
	Vr.sim_hand(VrRules.RIGHT, Transform3D(Basis(), Vector3(0.3 * cos(a), 1.2, -0.3 - 0.3 * sin(a))))
	_frame()
	assert_almost_eq(absf(angle_difference(yaw0, Vr.rig.yaw)), deg_to_rad(45.0), 0.01, "one 45° step, at once")
	Vr.sim_input(VrRules.LEFT, &"grip", 0.0)
	Vr.sim_input(VrRules.RIGHT, &"grip", 0.0)
	_frame()


func test_model_view_again_ends_it() -> void:
	Vr.toggle_model_view()
	_frame()
	assert_true(Vr.toggle_model_view())
	assert_false(Vr.model_view_open())
	assert_eq(Vr.world_scale(), 1.0, "their size again")
	assert_eq(Vr.local_player(), p)
	assert_false(Vr.body_waits())
	assert_almost_eq(p.global_position, ME_AT, Vector3.ONE * 0.001, "where they stood")


func test_nothing_stays_in_a_hand_or_on_the_table_across_the_giants_scale() -> void:
	Vr.open_build_table()
	Vr.bricks.call(&"_hold", VrRules.RIGHT, BlockIds.STONE)
	assert_eq(Vr.bricks.held(VrRules.RIGHT), BlockIds.STONE)
	assert_true(Vr.toggle_model_view())
	assert_eq(Vr.bricks.held(VrRules.RIGHT), 0, "the brick went back to the bag")
	assert_null(Vr.build_table, "the table is closed")


func test_off_vr_there_is_no_model_view() -> void:
	Vr.simulate(false)
	assert_false(Vr.toggle_model_view())
	assert_false(Vr.body_waits())
