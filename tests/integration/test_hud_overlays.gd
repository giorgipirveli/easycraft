extends GutTest
## Found on the emulator (M2 acceptance, 15:14): with Tilly's shop open, the CROUCH button (added by a
## later task) sat over the shop's BUY button. An open overlay (the shop, the Totem's panel) is above
## every HUD button, so a child's tap on it never reaches a button underneath.


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	return hud


func _buttons_above(hud: Hud, overlay: Control) -> Array[String]:
	var out: Array[String] = []
	for c in hud.get_children():
		if (c is BaseButton or c is TouchButton) and c.visible and c.get_index() > overlay.get_index():
			out.append(str(c.name if c.name != "" else c.get_class()))
	return out


func test_an_open_shop_is_above_every_hud_button() -> void:
	var hud := _hud()
	var trader := Trader.new()
	trader.setup({"pos": Vector3.ZERO, "yaw": 0.0})
	add_child_autofree(trader)
	hud.open_shop(trader)
	assert_eq(_buttons_above(hud, hud.shop), [] as Array[String])


func test_an_open_totem_panel_is_above_every_hud_button() -> void:
	var hud := _hud()
	var totem := Totem.new()
	add_child_autofree(totem)
	hud.open_totem(totem)
	assert_eq(_buttons_above(hud, hud.totem_panel), [] as Array[String])


## M3 Task 7: a course's goals panel (a tap on its FINISH) is above every HUD button too.
func test_an_open_course_panel_is_above_every_hud_button() -> void:
	var hud := _hud()
	hud.open_course({"cell": Vector3i.ZERO, "none": false, "start": Vector3i.ZERO, "goals": [30000, 39000, 48000],
		"best": 30000, "best_name": "Kid", "ghost": true})
	assert_true(hud.course_panel.visible)
	assert_eq(_buttons_above(hud, hud.course_panel), [] as Array[String])
