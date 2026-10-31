extends GutTest
## Swimming on a touch screen (M2 Task 14): JUMP becomes UP (swim up) and the DOWN button dives, as
## while flying.


func test_swimming_shows_up_and_down() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud._on_physics_mode_changed(PhysicsMode.Mode.NORMAL)
	assert_false(hud.fly_down_button.visible)
	hud.set_swimming(true)
	assert_true(hud.fly_down_button.visible, "DOWN dives")
	assert_eq(hud.jump_button.text, "UP")
	hud.set_swimming(false)
	assert_false(hud.fly_down_button.visible)
	assert_eq(hud.jump_button.text, "JUMP")


func test_flying_keeps_its_buttons_after_a_swim() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud._on_physics_mode_changed(PhysicsMode.Mode.FLY)
	hud.set_swimming(true)
	hud.set_swimming(false)
	assert_true(hud.fly_down_button.visible, "still flying")
	assert_eq(hud.jump_button.text, "UP")


func test_desktop_has_no_touch_buttons_in_water() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.jump_button.visible = false     # setup() hides the touch controls on desktop
	hud.set_swimming(true)
	assert_false(hud.fly_down_button.visible)
