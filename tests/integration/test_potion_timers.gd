extends GutTest
## The potion timers on the HUD (M2 Task 6): a small chip per working potion (its icon and the
## seconds left), top-centre-left, clear of the other controls and under the palette overlay.
## Nothing blinks (lead's ruling: no flashing more than 3 times a second); the last seconds turn orange.

const SCREEN := Vector2(1280, 720)


static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func _player() -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	return p


func test_the_timers_sit_top_centre_left_clear_of_everything() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	var timers := _rect(hud.potion_timers)
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(timers), "on screen")
	assert_lt(timers.end.x, SCREEN.x * 0.5, "left of the middle")
	assert_lt(timers.position.y, SCREEN.y * 0.25, "near the top")
	assert_gte(timers.position.y, 96.0, "below the hearts and stealth rows (Tasks 2 and 5)")
	for other: Control in [hud.pause_button, hud.chat.button, hud.username_label, hud.jump_button, hud.hotbar,
			hud.physics_button, hud.more_button, hud.attack_button]:
		assert_false(timers.intersects(_rect(other)), "overlaps %s" % other.get_class())
	assert_lt(hud.potion_timers.get_index(), hud.palette.get_index(), "under the palette overlay")
	assert_eq(hud.potion_timers.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never eats a tap")


func test_a_chip_per_working_potion_with_its_seconds() -> void:
	var timers := PotionTimers.new()
	add_child_autofree(timers)
	var p := _player()
	timers.player = p
	timers._process(0.016)
	assert_eq(timers.shown(), [] as Array[int], "nothing working")
	p.drink(ItemIds.POTION_SPEED)
	p.drink(ItemIds.POTION_JUMP)
	p.potions.tick(12.3)
	timers._process(0.016)
	assert_eq(timers.shown(), [ItemIds.POTION_JUMP, ItemIds.POTION_SPEED] as Array[int])
	assert_eq(timers.seconds_text(ItemIds.POTION_SPEED), "48")
	p.potions.tick(44.0)
	timers._process(0.016)
	assert_eq(timers.seconds_text(ItemIds.POTION_SPEED), "4")
	assert_eq(timers.text_color(ItemIds.POTION_SPEED), PotionTimers.LOW_COLOR, "the last seconds are orange, steady")
	p.potions.tick(5.0)
	timers._process(0.016)
	assert_eq(timers.shown(), [] as Array[int], "gone when it wears off")


func test_no_player_no_problem() -> void:
	var timers := PotionTimers.new()
	add_child_autofree(timers)
	timers._process(0.016)
	assert_eq(timers.shown(), [] as Array[int])
