extends GutTest
## The ATTACK touch button (M1b Task 11): placed clear of the other controls on a 1280x720 screen,
## under the palette overlay, and hidden until the HUD knows it is on a touch screen (owner feedback #29:
## then it always shows, whatever the hand holds; test_attack_always_attacks.gd). M2 Task 17: 200 px, above JUMP.

const SCREEN := Vector2(1280, 720)


## Where a corner-anchored control sits on a 1280x720 screen.
static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func test_attack_button_sits_clear_of_the_other_controls() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	var attack := _rect(hud.attack_button)
	assert_eq(attack.size, Vector2(200, 200), "a main button, nearly as big as JUMP (M2 Task 17)")
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(attack), "on screen")
	assert_lt(attack.end.y, _rect(hud.jump_button).position.y, "above JUMP, for the same thumb")
	for other: Control in [hud.jump_button, hud.fly_down_button, hud.crouch_button, hud.physics_button,
			hud.more_button, hud.hotbar]:
		assert_false(attack.intersects(_rect(other)), "overlaps %s" % other.get_class())


func test_attack_button_stays_under_the_palette_and_starts_hidden() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	assert_lt(hud.attack_button.get_index(), hud.palette.get_index(), "the palette overlay covers it")
	assert_false(hud.attack_button.visible)
