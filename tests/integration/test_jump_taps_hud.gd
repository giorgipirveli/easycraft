extends GutTest
## Owner feedback #54 (2026-09-28, spec §3b) through the real controls: two quick taps of a finger on the touch HUD's
## JUMP button and two quick presses of a keyboard's Space bar do the same (both press the "jump" action): the player
## takes off flying, the WALK button then says FLY, JUMP says UP and DOWN shows, as with the FLY button. The HUD is in
## a 1280 × 720 SubViewport (the design space) so the touches land on the buttons; the player is on a stone floor.

class FlatWorld:
	extends WorldService

	func get_block(p: Vector3i) -> int:
		return BlockIds.STONE if p.y <= 9 else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return 10

	func is_area_ready(_center: Vector3) -> bool:
		return true


const QUICK := 9   # physics frames from one tap to the next: 0.15 s

var view: SubViewport
var hud: Hud
var player: Player
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX


func after_each() -> void:
	Input.action_release(&"jump")
	Game.mode = _mode_before
	Session.register_world(null)


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _setup() -> void:
	var world := FlatWorld.new()
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 10, 400)
	shape.shape = box
	shape.position = Vector3(0, 5, 0)
	ground.add_child(shape)
	world.add_child(ground)
	Session.register_world(world)
	player = load("res://entities/player/player.tscn").instantiate()
	player.name = str(multiplayer.get_unique_id())
	player.world = world
	add_child_autofree(player)
	view = SubViewport.new()
	view.size = Vector2i(1280, 720)
	add_child_autofree(view)
	hud = Hud.new()
	view.add_child(hud)
	hud.setup(player, "Kid", true, false)
	player.spawn_at(Vector3(0.5, 10.0, 0.5))
	await wait_until(func() -> bool: return player.is_spawned(), 2.0, "spawned")
	await wait_physics_frames(10)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _finger(pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = 0
	t.position = hud.jump_button.get_global_rect().get_center()
	t.pressed = pressed
	view.push_input(t, true)


func _space(pressed: bool) -> void:
	var k := InputEventKey.new()
	k.device = InputEvent.DEVICE_ID_KEYBOARD
	k.physical_keycode = KEY_SPACE
	k.keycode = KEY_SPACE
	k.pressed = pressed
	Input.parse_input_event(k)
	Input.flush_buffered_events()


## Two quick taps with `press` (a finger on JUMP, or Space), then a moment to take off and rise.
func _double_tap(press: Callable) -> void:
	for i in 2:
		press.call(true)
		await _frames(1)
		press.call(false)
		await _frames(QUICK - 1)
	await wait_physics_frames(60)


func _assert_flying_with_the_fly_buttons(what: String) -> void:
	assert_eq(player.physics_mode, PhysicsMode.Mode.FLY, "%s: flying" % what)
	assert_eq(hud.physics_button.text, "FLY", "%s: the WALK button says FLY" % what)
	assert_eq(hud.jump_button.text, "UP", "%s: JUMP is UP" % what)
	assert_true(hud.fly_down_button.visible, "%s: DOWN shows" % what)
	assert_gt(player.global_position.y - 10.0, 3.0, "%s: up in the air" % what)


func test_two_quick_taps_on_the_touch_jump_button_take_off() -> void:
	await _setup()
	assert_eq(hud.physics_button.text, "WALK")
	assert_eq(hud.jump_button.text, "JUMP")
	await _double_tap(_finger)
	_assert_flying_with_the_fly_buttons("a finger on JUMP")


func test_two_quick_presses_of_space_take_off_the_same_way() -> void:
	await _setup()
	await _double_tap(_space)
	_assert_flying_with_the_fly_buttons("Space")
