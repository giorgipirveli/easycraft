extends GutTest
## The hearts row and the knock-out fade (M2 Task 2, spec §12.3): 10 hearts with halves, top left
## right of pause (above CHAT since M2 Task 17), in both modes; a flash and shake when hurt, a gentle
## pulse while the hearts come back; driven by Session.player_hurt for this game's player only.

const SCREEN := Vector2(1280, 720)


static func _rect(c: Control) -> Rect2:
	var anchor := Vector2(c.anchor_left, c.anchor_top) * SCREEN
	return Rect2(anchor + Vector2(c.offset_left, c.offset_top), Vector2(c.offset_right - c.offset_left, c.offset_bottom - c.offset_top))


func test_each_heart_is_full_half_or_empty() -> void:
	for i in HeartsBar.HEARTS:
		assert_eq(HeartsBar.fill(Health.MAX_HP, i), 1.0)
		assert_eq(HeartsBar.fill(0, i), 0.0)
	assert_eq(HeartsBar.HEARTS, 10)
	assert_eq(HeartsBar.fill(15, 6), 1.0)
	assert_eq(HeartsBar.fill(15, 7), 0.5, "15 HP = 7 and a half hearts")
	assert_eq(HeartsBar.fill(15, 8), 0.0)
	assert_eq(HeartsBar.fill(1, 0), 0.5)
	assert_eq(HeartsBar.fill(-3, 0), 0.0)
	assert_eq(HeartsBar.fill(99, 9), 1.0)


func test_a_hurt_flashes_and_shakes_then_settles() -> void:
	var bar := HeartsBar.new()
	add_child_autofree(bar)
	bar.set_hp(Health.MAX_HP)
	assert_false(bar.is_flashing())
	bar.set_hp(14)
	assert_eq(bar.hp, 14)
	assert_true(bar.is_flashing(), "hurt: flash")
	assert_ne(bar.shake_offset(), Vector2.ZERO, "and shake")
	bar.tick(HeartsBar.FLASH_TIME + 0.01)
	assert_false(bar.is_flashing())
	assert_eq(bar.shake_offset(), Vector2.ZERO, "still again")
	bar.set_hp(15)
	assert_false(bar.is_flashing(), "a heal never flashes")


func test_the_heart_being_refilled_pulses_while_hearts_come_back() -> void:
	var bar := HeartsBar.new()
	add_child_autofree(bar)
	bar.set_hp(11)
	assert_false(bar.is_regenerating(), "not right after a hit")
	bar.tick(Health.REGEN_DELAY - 0.1)
	assert_false(bar.is_regenerating())
	bar.tick(0.2)
	assert_true(bar.is_regenerating(), "quiet long enough: hearts come back")
	assert_eq(bar.pulse_index(), 5, "11 HP: the sixth heart is filling")
	bar.set_hp(12)
	assert_true(bar.is_regenerating(), "a heal keeps the pulse going")
	assert_eq(bar.pulse_index(), 6)
	bar.set_hp(Health.MAX_HP)
	assert_false(bar.is_regenerating(), "full: no pulse")
	bar.set_hp(0)
	bar.tick(Health.REGEN_DELAY + 1.0)
	assert_false(bar.is_regenerating(), "knocked out: no pulse")


func test_hearts_sit_right_of_pause_clear_of_the_other_controls() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.add_health_controls()
	var hearts := _rect(hud.hearts)
	assert_true(Rect2(Vector2.ZERO, SCREEN).encloses(hearts), "on screen")
	assert_gte(hearts.position.x, _rect(hud.pause_button).end.x, "right of pause (M2 Task 17: CHAT is under pause)")
	assert_lt(hearts.end.y, _rect(hud.chat.button).position.y, "above CHAT")
	assert_lt(hearts.end.y, 96.0, "above the toasts (y 96)")
	assert_eq(hearts.size, hud.hearts.bar_size())
	for other: Control in [hud.pause_button, hud.chat.button, hud.username_label, hud.fps_label, hud.physics_button,
			hud.more_button, hud.wave_line, hud.boss_bar]:
		assert_false(hearts.intersects(_rect(other)), "overlaps %s %s" % [other.get_class(), _rect(other)])
	assert_true(hud.hearts.visible, "both modes have hearts")
	assert_lt(hud.hearts.get_index(), hud.chat.get_index(), "the open chat bar covers them")
	assert_lt(hud.knockout_overlay.get_index(), hud._toast_panel.get_index(), "the fade never hides messages")
	assert_lt(hud.knockout_overlay.get_index(), hud.palette.get_index())


func test_the_hud_follows_this_players_hearts_only() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	var p := Player.new()   # never added to the tree: only its peer id and health are read
	p.peer_id = 7
	hud.player = p
	hud.add_health_controls()
	assert_eq(hud.hearts.hp, Health.MAX_HP)
	Session.player_hurt.emit(7, 13, Vector3.ZERO)
	assert_eq(hud.hearts.hp, 13)
	assert_true(hud.hearts.is_flashing())
	Session.player_hurt.emit(8, 2, Vector3.ZERO)
	assert_eq(hud.hearts.hp, 13, "someone else's hearts")
	p.free()


func test_the_knockout_fade_shows_the_message_and_clears() -> void:
	var overlay := KnockoutOverlay.new()
	add_child_autofree(overlay)
	assert_false(overlay.visible)
	overlay.knock_out("You were knocked out!")
	assert_true(overlay.visible)
	assert_true(overlay.is_down())
	assert_eq(overlay.message(), "You were knocked out!")
	overlay.get_up()
	assert_false(overlay.is_down())
	await wait_seconds(KnockoutOverlay.GET_UP_TIME + 0.2)
	assert_false(overlay.visible, "gone once faded")


func test_the_fade_shows_one_picture_tip() -> void:
	var overlay := KnockoutOverlay.new()
	add_child_autofree(overlay)
	overlay.knock_out("You were knocked out!", KnockoutRules.TIPS[1])
	assert_eq(overlay.tip_text(), KnockoutRules.TIPS[1].text)
	assert_eq(overlay.tip_icon(), BlockIcons.icon(KnockoutRules.TIPS[1].icon), "the lantern's picture")
	overlay.knock_out("Oops! Back on your feet!")
	assert_eq(overlay.tip_text(), "", "no tip given, none shown")
	assert_null(overlay.tip_icon())
