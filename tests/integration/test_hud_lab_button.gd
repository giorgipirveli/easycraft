extends GutTest
## The LAB button (M3 Task 6, spec §14.3): Sandbox only, on touch screens, in the MORE panel (M2 Task
## 17: a button used now and then; top right before), as big as the others and under the palette.
## Tapping it cycles the Physics Lab; the WALK button shows the lab mode (MOON, ZERO-G, SLOW).


func after_each() -> void:
	Game.mode = ModeRules.SANDBOX


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	return hud


class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


func _player() -> Player:
	var w := AirWorld.new()
	autofree(w)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	return p


func test_the_lab_button_waits_in_the_more_panel() -> void:
	var hud := _hud()
	assert_true(hud.more.is_ancestor_of(hud.lab_button), "a button used now and then (M2 Task 17)")
	assert_eq(hud.lab_button.custom_minimum_size, Vector2(HudLayout.BUTTON, HudLayout.BUTTON), "as big as the others")
	assert_lt(hud.more.get_index(), hud.palette.get_index(), "the palette overlay covers it")
	assert_eq(hud.lab_button.text, "LAB")
	assert_eq(hud.lab_button.symbol, &"lab", "a flask over the word")


func test_the_lab_button_is_only_in_sandbox() -> void:
	var p := _player()
	var hud := _hud()
	hud._setup_lab_button(p, true)
	assert_true(hud.lab_button.visible, "sandbox, touch screen")
	assert_has(hud.look_area.blockers, hud.lab_button, "a tap on it never builds")
	Game.mode = ModeRules.SURVIVOR
	var survivor := _hud()
	survivor._setup_lab_button(p, true)
	assert_false(survivor.lab_button.visible, "Survivor keeps Normal and paid Fly")
	Game.mode = ModeRules.SANDBOX
	var desktop := _hud()
	desktop._setup_lab_button(p, false)
	assert_false(desktop.lab_button.visible, "desktop: the L key")


func test_tapping_lab_cycles_the_lab_and_says_what_it_does() -> void:
	var p := _player()
	var hud := _hud()
	p.physics_mode_changed.connect(hud._on_physics_mode_changed)
	hud._setup_lab_button(p, true)
	hud.lab_button.pressed.emit()
	assert_eq(p.lab_mode, LabRules.Mode.MOON)
	assert_eq(hud.physics_button.text, "MOON", "the mode shows where WALK/FLY/GHOST shows")
	assert_true(hud.lab_button.selected, "lit while a lab mode is on")
	assert_eq(hud._toast_label.text, LabRules.toast(LabRules.Mode.MOON))
	hud.lab_button.pressed.emit()
	assert_eq(hud.physics_button.text, "ZERO-G")
	assert_true(hud.fly_down_button.visible, "UP and DOWN thrust in zero-G")
	hud.lab_button.pressed.emit()
	assert_eq(hud.physics_button.text, "FLY")
	assert_false(hud.lab_button.selected, "plain flying is not a lab mode")
	for i in 3:
		hud.lab_button.pressed.emit()
	assert_eq(p.lab_mode, LabRules.Mode.NORMAL)
	assert_eq(hud.physics_button.text, "WALK")
