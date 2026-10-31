extends GutTest
## M5 Task 1 (spec §15.1a): MOVE BUTTONS. A picture of the HUD where JUMP, ATTACK, CROUCH and the stick follow a finger;
## a place that covers another control, a label or the hotbar, or leaves the screen, is not taken (the control goes
## back); DONE saves this button size's moves in the profile, RESET puts all four back. The left hand drags in a
## mirror. Real touches are pushed into a 1280 × 720 view. The profile here is a fresh one (the file is shared).

var _view: SubViewport
var _profile: ProfileData
var _saves := []


func after_each() -> void:
	HudLayout.reset()


func _editor(size_step := "normal", left := false, moves := {}) -> HudEditor:
	_profile = ProfileData.new()
	_profile.settings.button_size = size_step
	_profile.settings.left_handed = left
	_profile.hud_moves = moves
	_saves = []
	_view = SubViewport.new()
	_view.size = Vector2i(1280, 720)
	add_child_autofree(_view)
	var e := HudEditor.new()
	e.profile = _profile
	e.saver = func() -> void: _saves.append(_profile.hud_moves.duplicate(true))
	_view.add_child(e)
	await wait_process_frames(2)
	return e


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = pos
	t.pressed = pressed
	_view.push_input(t, true)


func _drag_to(index: int, pos: Vector2, rel: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = index
	d.position = pos
	d.relative = rel
	_view.push_input(d, true)


## A finger on `spot`'s middle, moved by `by` in steps, and lifted.
func _drag(e: HudEditor, spot: StringName, by: Vector2, index := 0) -> void:
	var at := e.piece_rect(spot).get_center()
	_touch(index, at, true)
	for i in 4:
		_drag_to(index, at + by * (i + 1) / 4.0, by / 4.0)
	_touch(index, at + by, false)
	await wait_process_frames(1)


func test_it_shows_the_four_controls_where_the_hud_has_them() -> void:
	for size_step: String in ["normal", "big", "bigger"]:
		for left: bool in [false, true]:
			var e := await _editor(size_step, left)
			for spot: StringName in HudLayout.MOVABLE:
				HudLayout.configure_from(_profile, Vector2(1280, 720))
				assert_eq(e.piece_rect(spot), HudLayout.rect(spot, Vector2(1280, 720)), "%s %s %s" % [size_step, left, spot])
			assert_not_null(e.done_button)
			assert_not_null(e.reset_button)
			_view.queue_free()
			await wait_process_frames(1)


func test_a_drag_moves_jump_and_done_saves_it() -> void:
	var e := await _editor()
	watch_signals(e)
	var before := e.piece_rect(&"jump")
	await _drag(e, &"jump", Vector2(-10, -8))
	assert_eq(e.piece_rect(&"jump").position, before.position + Vector2(-10, -8), "JUMP followed the finger")
	assert_eq(_saves, [], "nothing saved before DONE")
	e.done_button.pressed.emit()
	assert_eq(_profile.hud_moves, {"normal": {"jump": [-10.0, -8.0]}})
	assert_eq(_saves.size(), 1)
	assert_signal_emitted(e, "closed")


func test_a_place_that_covers_something_is_not_taken() -> void:
	var e := await _editor()
	var home := e.piece_rect(&"attack")
	await _drag(e, &"attack", Vector2(0, 180))   # onto JUMP
	assert_eq(e.piece_rect(&"attack"), home, "ATTACK went back")
	await _drag(e, &"attack", Vector2(300, 0))   # off the screen
	assert_eq(e.piece_rect(&"attack"), home)
	assert_true(e.said_no_room, "it says there is no room there")
	e.done_button.pressed.emit()
	assert_eq(_profile.hud_moves, {}, "no move saved")


func test_while_dragging_it_follows_the_finger_and_shows_when_there_is_no_room() -> void:
	var e := await _editor()
	var home := e.piece_rect(&"attack")
	var at := home.get_center()
	_touch(0, at, true)
	_drag_to(0, at + Vector2(0, 180), Vector2(0, 180))
	await wait_process_frames(1)
	assert_true(e.dragging(&"attack"))
	assert_false(e.fits_now(&"attack"), "over JUMP: no room (drawn crossed out, not only in a colour)")
	_drag_to(0, at + Vector2(0, -6), Vector2(0, -186))
	assert_true(e.fits_now(&"attack"))
	_touch(0, at + Vector2(0, -6), false)
	assert_eq(e.piece_rect(&"attack").position.y, home.position.y - 6.0, "it stays where it fits")


func test_reset_puts_all_four_back() -> void:
	var e := await _editor("normal", false, {"normal": {"jump": [-10.0, -8.0]}, "big": {"attack": [-4.0, 0.0]}})
	var moved := e.piece_rect(&"jump")
	e.reset_button.pressed.emit()
	await wait_process_frames(1)
	assert_ne(e.piece_rect(&"jump"), moved)
	var home: Array = HudLayout.SPOTS[&"jump"]
	assert_eq(e.piece_rect(&"jump").position, (home[0] as Vector2) * Vector2(1280, 720) + (home[1] as Vector2))
	e.done_button.pressed.emit()
	assert_eq(_profile.hud_moves, {"big": {"attack": [-4.0, 0.0]}}, "only this size's moves go")


func test_the_left_hand_drags_in_a_mirror() -> void:
	var e := await _editor("normal", true)
	var before := e.piece_rect(&"jump")
	assert_lt(before.get_center().x, 640.0, "the left hand's JUMP is on the left")
	await _drag(e, &"jump", Vector2(10, -8))
	assert_eq(e.piece_rect(&"jump").position, before.position + Vector2(10, -8))
	e.done_button.pressed.emit()
	assert_eq(_profile.hud_moves, {"normal": {"jump": [-10.0, -8.0]}}, "kept in the right hand's frame")


func test_the_stick_moves_too_and_two_fingers_drag_two_controls() -> void:
	var e := await _editor("bigger")
	var stick := e.piece_rect(&"joystick")
	var jump := e.piece_rect(&"jump")
	var s_at := stick.get_center()
	var j_at := jump.get_center()
	_touch(0, s_at, true)
	_touch(1, j_at, true)
	_drag_to(0, s_at + Vector2(8, 0), Vector2(8, 0))   # BIGGER: HELP UP is 10 px to the right
	_drag_to(1, j_at + Vector2(0, -6), Vector2(0, -6))
	_touch(0, s_at + Vector2(8, 0), false)
	_touch(1, j_at + Vector2(0, -6), false)
	await wait_process_frames(1)
	assert_eq(e.piece_rect(&"joystick").position, stick.position + Vector2(8, 0))
	assert_eq(e.piece_rect(&"jump").position, jump.position + Vector2(0, -6))


func test_a_touch_on_empty_ground_moves_nothing() -> void:
	var e := await _editor()
	var before := {}
	for spot: StringName in HudLayout.MOVABLE:
		before[spot] = e.piece_rect(spot)
	_touch(0, Vector2(640, 380), true)
	_drag_to(0, Vector2(700, 400), Vector2(60, 20))
	_touch(0, Vector2(700, 400), false)
	for spot: StringName in HudLayout.MOVABLE:
		assert_eq(e.piece_rect(spot), before[spot])


func test_it_has_a_speaker_and_its_words() -> void:
	var e := await _editor()
	var words := ReadAloud.words_of(e)
	assert_string_contains(words, "Move the buttons")
	assert_eq(e.find_children("ReadAloud", "", true, false).size(), 1, "a speaker reads it")
