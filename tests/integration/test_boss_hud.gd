extends GutTest
## M2 Task 10: the boss bar in the HUD (plan Allocations: top-centre, above the toasts): an icon and a
## bar (the health as a bar, not a number), hidden until a Golem fights, never taking a tap, clear of
## the hearts, the username and the gold counter.

const SCREEN := Vector2(1280, 720)


static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func test_the_boss_bar_sits_top_centre_above_the_toasts() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_health_controls()
	var bar := _rect(hud.boss_bar)
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(bar), "on screen")
	assert_almost_eq(bar.get_center().x, SCREEN.x * 0.5, 1.0, "centred")
	assert_lte(bar.end.y, hud._toast_panel.offset_top, "above the toasts")
	assert_eq(bar.size, BossBar.SIZE)
	for other: Control in [hud.hearts, hud.username_label, hud.gold_counter, hud.pause_button, hud.chat.button,
			hud.potion_timers, hud.more_button, hud.physics_button, hud.fps_label]:
		assert_false(bar.intersects(_rect(other)), "clear of %s %s" % [other.get_class(), _rect(other)])
	assert_false(hud.boss_bar.visible, "hidden until a Golem fights")
	assert_eq(hud.boss_bar.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never takes a tap")
	assert_lt(hud.boss_bar.get_index(), hud.palette.get_index(), "under the palette overlay")


## Found by the LAN test: a guest's copy of the Golem can outlive the win message by a frame (the host
## frees it in the same frame as the last hit), and its last health update must not wipe the result.
func test_a_result_stays_until_the_next_fight_starts() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	bar.start(false)
	bar.set_health(450, 450)
	bar.show_result(BossRules.WIN_MESSAGE, 0.0)
	bar.set_health(450, 450, false, false)
	assert_eq(bar.title(), BossRules.WIN_MESSAGE, "the win stays on the bar")
	assert_eq(bar.fraction(), 0.0)
	bar.start(true)
	assert_eq(bar.title(), BossBar.TIRED_TITLE, "a new fight starts afresh")
	bar.set_health(100, 225, true)
	assert_almost_eq(bar.fraction(), 100.0 / 225.0, 0.001)


func test_the_bar_shows_health_as_a_bar_not_a_number() -> void:
	var bar := BossBar.new()
	add_child_autofree(bar)
	bar.start(false)
	bar.set_health(75, 300)
	assert_almost_eq(bar.fraction(), 0.25, 0.001)
	var texts := bar.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
	for t: String in texts:
		assert_false(t.contains("75") or t.contains("%"), "no numbers while it fights: %s" % t)
	bar.set_health(0, 300)
	assert_eq(bar.fraction(), 0.0)
	bar.set_health(400, 300)
	assert_eq(bar.fraction(), 1.0, "never past full")
	bar.set_health(10, 0)
	assert_true(is_finite(bar.fraction()), "a broken maximum does not break the bar")
