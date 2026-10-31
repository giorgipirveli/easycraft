extends GutTest
## M2 Task 17: a Brave Survivor world wears a badge under the hearts, right of the eye (the research's
## Cozy / Normal / Brave: pride for brave players, and no mark at all on Cozy or Normal worlds). Right of
## the hearts it ran into the wave line and the boss bar on a 16:9 phone (the HUD pass).

const SCREEN := Vector2(1280, 720)


static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func test_only_a_brave_world_shows_the_badge_under_the_hearts() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_health_controls()
	hud.show_difficulty_badge(DifficultyRules.BRAVE)
	assert_true(hud.brave_badge.visible)
	assert_string_contains(hud.brave_badge.text, "BRAVE")
	var r := _rect(hud.brave_badge)
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(r), "on screen")
	assert_gte(r.position.x, _rect(hud.stealth_meter).end.x, "right of the eye")
	assert_gte(r.position.y, _rect(hud.hearts).end.y, "under the hearts")
	assert_lt(r.end.y, 96.0, "above the toasts")
	for other: Control in [hud.pause_button, hud.chat.button, hud.username_label, hud.gold_counter, hud.more_button,
			hud.potion_timers, hud.wave_line, hud.boss_bar, hud.stealth_meter, hud.hearts]:
		assert_false(r.intersects(_rect(other)), "overlaps %s" % other.name)
	for d: StringName in [DifficultyRules.COZY, DifficultyRules.NORMAL]:
		hud.show_difficulty_badge(d)
		assert_false(hud.brave_badge.visible, String(d))
