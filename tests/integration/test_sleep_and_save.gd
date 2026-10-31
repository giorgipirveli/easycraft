extends GutTest
## M2 Task 17 (research: natural stopping points, no pressure to keep playing): while you sleep, two
## equal buttons offer WAKE UP and STOP FOR TODAY; stopping saves the world and goes to the menu.

const SCREEN := Vector2(1280, 720)


static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_sleep_controls()
	return hud


func test_asleep_shows_wake_up_and_stop_for_today_as_equals() -> void:
	var hud := _hud()
	hud.show_sleep_button(true, "WAKE UP")
	hud.set_sleeping(true)
	assert_true(hud.stop_button.visible)
	assert_eq(hud.stop_button.text, "STOP FOR TODAY")
	var wake := _rect(hud.sleep_button)
	var stop := _rect(hud.stop_button)
	assert_eq(stop.size, wake.size, "equal buttons: neither is the 'right' answer")
	assert_eq(stop.position.y, wake.position.y, "side by side")
	assert_false(stop.intersects(wake))
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(stop) and Rect2(Vector2.ZERO, SCREEN).encloses(wake))
	assert_has(hud.look_area.blockers, hud.stop_button, "a tap on it never places a block")


func test_stop_for_today_asks_to_save_and_leave() -> void:
	var hud := _hud()
	hud.set_sleeping(true)
	watch_signals(hud)
	hud.stop_button.pressed.emit()
	assert_signal_emitted(hud, "stop_for_today")


func test_awake_there_is_only_the_sleep_button_in_the_middle() -> void:
	var hud := _hud()
	hud.set_sleeping(true)
	hud.set_sleeping(false)
	hud.show_sleep_button(true, "SLEEP")
	assert_false(hud.stop_button.visible)
	var r := _rect(hud.sleep_button)
	assert_almost_eq(r.get_center().x, SCREEN.x * 0.5, 1.0)
