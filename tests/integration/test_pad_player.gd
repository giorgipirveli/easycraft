extends GutTest
## Owner #90, on a real Player and HUD: the right stick turns the camera (at SETTINGS' speed, the stick to the right turns
## right), never while a menu has the pad (its actions are out of the input map then); L1 / R1 step through the hotbar
## (GamepadRules.next_slot, round from the last to the first); a pad playing on a phone hides the touch buttons.

class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


var p: Player
var hud: Hud
var _speed: Variant


func before_each() -> void:
	_speed = Profile.data.settings.get("pad_look", "normal")
	var w := AirWorld.new()
	autofree(w)
	p = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 80, 0.5)
	hud = Hud.new()
	add_child_autofree(hud)
	hud.setup(p, "Hopper", true, false)
	await wait_process_frames(2)


func after_each() -> void:
	Profile.data.settings.pad_look = _speed
	for a: StringName in [&"look_left", &"look_right", &"look_up", &"look_down"]:
		Input.action_release(a)


func test_the_right_stick_turns_the_camera() -> void:
	Profile.data.settings.pad_look = "normal"
	var yaw := p.rig.yaw
	Input.action_press(&"look_right", 1.0)
	p._pad_look(0.1)
	var normal_turn := yaw - p.rig.yaw
	assert_almost_eq(normal_turn, GamepadRules.LOOK_SPEED * 0.1, 0.001, "full tilt: LOOK_SPEED a second, to the right")
	Profile.data.settings.pad_look = "fast"
	yaw = p.rig.yaw
	p._pad_look(0.1)
	assert_almost_eq(yaw - p.rig.yaw, normal_turn * 1.5, 0.001, "FAST turns faster")
	Input.action_release(&"look_right")
	yaw = p.rig.yaw
	p._pad_look(0.1)
	assert_eq(p.rig.yaw, yaw, "let go: still")


func test_the_look_stops_while_a_menu_has_the_pad() -> void:
	var pad := PadFocus.new()
	add_child_autofree(pad)
	var panel := Button.new()
	panel.text = "RESUME"
	add_child_autofree(panel)
	PadFocus.watch(panel)
	await wait_process_frames(2)
	Input.action_press(&"look_right", 1.0)
	assert_false(InputMap.action_has_event(&"look_right",
		GamepadRules.make_event({"axis": JOY_AXIS_RIGHT_X, "value": 1.0})), "the menu took the stick's look out")
	panel.visible = false
	await wait_process_frames(2)
	assert_true(InputMap.action_has_event(&"look_right",
		GamepadRules.make_event({"axis": JOY_AXIS_RIGHT_X, "value": 1.0})), "and gave it back")


func test_l1_and_r1_step_round_the_hotbar() -> void:
	assert_eq(GamepadRules.next_slot(0, 1, 9), 1)
	assert_eq(GamepadRules.next_slot(8, 1, 9), 0, "past the last: the first")
	assert_eq(GamepadRules.next_slot(0, -1, 9), 8, "before the first: the last")
	assert_eq(GamepadRules.next_slot(0, 1, 0), 0)


func test_a_pad_on_a_phone_hides_the_touch_buttons() -> void:
	assert_true(hud.joystick.visible, "a phone's HUD")
	hud.set_pad(true)
	assert_false(hud.joystick.visible)
	assert_false(hud.jump_button.visible)
	assert_false(hud.attack_button.visible)
	assert_false(hud.fly_down_button.visible)
	hud.set_pad(false)
	assert_true(hud.joystick.visible, "a finger brings them back")
	assert_true(hud.jump_button.visible)
