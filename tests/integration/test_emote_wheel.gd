extends GutTest
## M3 Task 9: the emote wheel. A button (in the MORE panel since M2 Task 17) opens a wheel of the
## player's 8 emotes; tapping one plays it (and tells everyone); tapping outside or the middle closes
## it. The wheel takes every touch while it is open.

var _wheel_before: Array[StringName]


func before_each() -> void:
	_wheel_before = Profile.data.avatar.emotes.duplicate()


func after_each() -> void:
	Profile.data.avatar.emotes = _wheel_before


func _touch(target: Node, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.position = pos
	t.pressed = pressed
	t.index = 0
	target.get_viewport().push_input(t, true)   # viewport coordinates, not the window's


## M2 Task 17: the emote button waits in the MORE panel (a button used now and then; the left column
## before), first in it, as big as the others, the little figure over its word.
func test_the_emote_button_waits_first_in_the_more_panel() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	assert_true(hud.more.is_ancestor_of(hud.emote_button))
	assert_eq(hud.more.buttons()[0], hud.emote_button, "first in the panel")
	assert_eq(hud.emote_button.custom_minimum_size, Vector2(HudLayout.BUTTON, HudLayout.BUTTON))
	assert_eq(hud.emote_button.text, "EMOTE")
	assert_true(HudIcons.knows(hud.emote_button.symbol))
	assert_lt(hud.more.get_index(), hud.palette.get_index(), "under the palette overlay")
	hud.more.open()
	hud.emote_button.pressed.emit()
	assert_true(hud.emote_wheel.visible, "it opens the wheel")
	assert_false(hud.more.is_open(), "and the panel closes")


func test_the_button_opens_a_wheel_of_the_players_eight_emotes() -> void:
	Profile.data.avatar.emotes[3] = &"dance_star"
	var hud := Hud.new()
	add_child_autofree(hud)
	assert_false(hud.emote_wheel.visible)
	hud.emote_button.pressed.emit()
	assert_true(hud.emote_wheel.visible)
	assert_eq(hud.emote_wheel.emotes, Profile.data.avatar.emotes)
	assert_eq(hud.emote_wheel.slot_rects().size(), AvatarCatalog.WHEEL_SLOTS)
	for r: Rect2 in hud.emote_wheel.slot_rects():
		assert_gte(r.size.x, 100.0, "big slots")


func test_tapping_a_slot_chooses_it_and_closes() -> void:
	var wheel := EmoteWheel.new()
	add_child_autofree(wheel)
	wheel.open(AvatarCatalog.DEFAULT_WHEEL)
	await wait_process_frames(1)
	watch_signals(wheel)
	var r: Rect2 = wheel.slot_rects()[2]
	_touch(wheel, r.get_center(), true)
	_touch(wheel, r.get_center(), false)
	assert_signal_emitted_with_parameters(wheel, "chosen", [AvatarCatalog.DEFAULT_WHEEL[2]])
	assert_false(wheel.visible)


## Found in M2 Task 17: the wheel opens on the emote button's touch-down, and the same finger's lift
## closed it at once (the wheel had not seen that finger go down). That lift is not the wheel's.
func test_the_finger_that_opened_the_wheel_can_lift() -> void:
	var wheel := EmoteWheel.new()
	add_child_autofree(wheel)
	wheel.open(AvatarCatalog.DEFAULT_WHEEL)
	await wait_process_frames(1)
	_touch(wheel, Vector2(20, 20), false)
	assert_true(wheel.visible, "still open after the opening finger lifts")
	watch_signals(wheel)
	var r: Rect2 = wheel.slot_rects()[1]
	_touch(wheel, r.get_center(), true)
	_touch(wheel, r.get_center(), false)
	assert_signal_emitted_with_parameters(wheel, "chosen", [AvatarCatalog.DEFAULT_WHEEL[1]])
	assert_false(wheel.visible)


func test_tapping_outside_or_the_middle_closes_without_choosing() -> void:
	var wheel := EmoteWheel.new()
	add_child_autofree(wheel)
	for pos: Vector2 in [Vector2(20, 20), wheel.get_viewport_rect().size * 0.5]:
		wheel.open(AvatarCatalog.DEFAULT_WHEEL)
		await wait_process_frames(1)
		watch_signals(wheel)
		_touch(wheel, pos, true)
		_touch(wheel, pos, false)
		assert_signal_not_emitted(wheel, "chosen")
		assert_false(wheel.visible)


func test_the_wheel_blocks_the_look_area_and_buttons_while_open() -> void:
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.emote_button.pressed.emit()
	assert_true(hud.emote_wheel.is_visible_in_tree())
	assert_true(hud.emote_wheel.get_global_rect().has_point(Vector2(640, 360)), "covers the screen")
	assert_gt(hud.emote_wheel.get_index(), hud.jump_button.get_index(), "above the buttons, so it hears touches first")


func test_a_chosen_emote_plays_on_the_player() -> void:
	var world: WorldService = load("res://world/world.tscn").instantiate()
	world.setup("", 42)
	add_child_autofree(world)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = world
	add_child_autofree(p)
	p._spawned = true
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(p, "Hopper", true, false)
	hud.emote_wheel.chosen.emit(&"cheer")
	assert_eq(p.avatar.emote(), &"cheer")
