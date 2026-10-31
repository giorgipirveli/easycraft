extends GutTest
## M3 Task 21a (simple controls): on a real Player and HUD. Simple hides ATTACK while the hands are empty and no
## monster is near and CROUCH until a monster comes near; the camera follows behind a child walking sideways.
## Classic shows them as before. (Auto-jump's rules: test_simple_controls.gd.)

class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


var p: Player
var hud: Hud
var interactor: BlockInteractor
var _simple := false
var _mode_before: StringName


func before_each() -> void:
	_simple = bool(Profile.data.settings.simple_controls)
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
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
	interactor = p.get_node("BlockInteractor")
	interactor.hotbar = WorldMeta._default_hotbar()
	interactor.select_slot(2)                          # planks in the hand
	hud = Hud.new()
	add_child_autofree(hud)
	hud.setup(p, "Hopper", true, false)
	await wait_process_frames(2)


func after_each() -> void:
	Profile.data.settings.simple_controls = _simple
	Game.mode = _mode_before


func _refresh() -> void:
	hud._simple_look_at = 0   # look for monsters now
	hud._process(0.016)


func _monster_at(at: Vector3) -> Node3D:
	var m := Node3D.new()
	m.add_to_group(&"monsters")
	add_child_autofree(m)
	m.global_position = at
	return m


func test_classic_shows_attack_and_crouch_as_before() -> void:
	Profile.data.settings.simple_controls = false
	_refresh()
	assert_true(hud.attack_button.visible)
	assert_true(hud.crouch_button.visible)


func test_simple_hides_them_until_they_apply() -> void:
	Profile.data.settings.simple_controls = true
	_refresh()
	assert_false(hud.attack_button.visible, "empty hands, no monster: no ATTACK")
	assert_false(hud.crouch_button.visible, "no monster: no CROUCH")
	var m := _monster_at(p.global_position + Vector3(6, 0, 0))
	_refresh()
	assert_true(hud.attack_button.visible, "a monster near: ATTACK")
	assert_true(hud.crouch_button.visible, "a monster near: CROUCH to sneak")
	m.global_position = p.global_position + Vector3(SimpleControls.MONSTER_NEAR + 4.0, 0, 0)
	_refresh()
	assert_false(hud.attack_button.visible)
	interactor.hotbar[3] = ItemIds.SWORD
	interactor.select_slot(3)
	_refresh()
	assert_true(hud.attack_button.visible, "a sword in the hand: ATTACK")


func test_simple_camera_follows_a_child_walking_sideways() -> void:
	p.rig._looked_at = -100000
	var yaw := p.rig.yaw
	Profile.data.settings.simple_controls = false
	p._simple_follow(Vector2(1, 0), 0.1)
	assert_eq(p.rig.yaw, yaw, "Classic: the camera stays")
	Profile.data.settings.simple_controls = true
	p._simple_follow(Vector2(1, 0), 0.1)
	assert_lt(p.rig.yaw, yaw, "Simple: it turns to follow")
	yaw = p.rig.yaw
	p.rig.look(Vector2(5, 0), CameraRig.TOUCH_SENSITIVITY)
	yaw = p.rig.yaw
	p._simple_follow(Vector2(1, 0), 0.1)
	assert_eq(p.rig.yaw, yaw, "not right after the child turned it")
