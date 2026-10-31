extends GutTest
## Owner #94 (spec §5.12b): the SHORTS tab's feed. A finger swipes the Shorts up and down and they snap; the mouse
## wheel, the keys and a controller's D-pad move too; a tap plays and pauses, a double tap gives a heart; the heart and
## the seen marks are kept in the profile; filters (hand-made, a grade's lessons, liked); LEARN IT; a break card after
## a while (never an endless feed); the game's music rests while a Short plays; and it is cheap per frame.

class FakeVoice:
	extends ReadAloud.Voice

	func has_voice(_language: String) -> bool:
		return true


var _voice: ReadAloud.Voice
var _saves := 0
var _t := 1000
var profile: ProfileData


func before_each() -> void:
	_voice = ReadAloud.voice
	ReadAloud.voice = FakeVoice.new()
	_saves = 0
	profile = ProfileData.new()
	profile.school.grade = 4


func after_each() -> void:
	ReadAloud.voice = _voice
	Curriculum.clear_cache()
	ShortLibrary.clear_cache()
	var bus := AudioServer.get_bus_index(ShortsView.MUSIC_BUS)
	if bus >= 0:
		AudioServer.set_bus_mute(bus, false)


func _view() -> ShortsView:
	var v := ShortsView.new()
	v.profile = profile
	v.save_profile = func() -> void: _saves += 1
	v.clock = func() -> int:
		_t += 1
		return _t
	add_child_autofree(v)
	await wait_process_frames(1)
	v.open()
	await wait_process_frames(2)
	return v


func _touch(v: ShortsView, pressed: bool, at: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.pressed = pressed
	e.position = at
	v._window_input(e)


func _drag(v: ShortsView, to: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = to
	v._window_input(e)


## A finger from `from` moving `dy` in `steps` over `seconds`, then up.
func _swipe(v: ShortsView, dy: float, steps: int = 8, seconds: float = 0.4) -> void:
	var from := Vector2(140, 300)
	_touch(v, true, from)
	for i in steps:
		await wait_seconds(seconds / steps)
		_drag(v, from + Vector2(0, dy * (i + 1) / steps))
	_touch(v, false, from + Vector2(0, dy))
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)


func test_it_opens_on_the_first_short_not_seen_still() -> void:
	profile.shorts.mark_seen(ShortLibrary.hand_ids()[0])
	var v := await _view()
	assert_eq(v.filter, ShortFeed.HAND, "the hand-made Shorts first")
	assert_eq(v.current_entry().id, v.feed[ShortFeed.start_index(v.feed)].id)
	assert_ne(v.current_entry().id, ShortLibrary.hand_ids()[0], "a seen one is not where it starts")
	assert_false(v.player().playing, "nothing starts by itself")
	assert_eq(v.position_label.text, "%d of %d" % [v.index + 1, v.feed.size()])
	assert_eq(v.title_label.text, v.current_entry().title)
	assert_eq(v.player().size, ShortsView.PLAYER_SIZE)
	assert_almost_eq(v.player().size.x / v.player().size.y, 9.0 / 16.0, 0.001, "portrait, 9:16")


func test_a_swipe_up_snaps_the_next_short_in_and_it_plays() -> void:
	var v := await _view()
	var first := v.index
	await _swipe(v, -200.0)
	assert_eq(v.index, first + 1, "the next Short")
	assert_true(v.player().playing, "it plays as it snaps in")
	assert_almost_eq(v.player().position.y, 0.0, 0.5, "snapped into place")
	await _swipe(v, 200.0)
	assert_eq(v.index, first, "a swipe down brings the last one back")


func test_a_small_drag_springs_back_and_a_flick_moves() -> void:
	var v := await _view()
	var first := v.index
	await _swipe(v, -40.0, 8, 0.6)
	assert_eq(v.index, first, "a small, slow drag springs back")
	assert_almost_eq(v.player().position.y, 0.0, 0.5)
	await _swipe(v, -60.0, 3, 0.03)
	assert_eq(v.index, first + 1, "a quick flick moves on")


func test_the_first_short_springs_back_from_a_pull_down() -> void:
	var v := await _view()
	v.set_filter(ShortFeed.HAND)
	v._jump(0, false)
	await _swipe(v, 250.0)
	assert_eq(v.index, 0, "nothing before the first")
	assert_almost_eq(v.player().position.y, 0.0, 0.5)


func test_the_wheel_the_buttons_and_the_pad_move_too() -> void:
	var v := await _view()
	var first := v.index
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	v._window_input(wheel)
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)
	assert_eq(v.index, first + 1, "the wheel")
	v.next_button.pressed.emit()
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)
	assert_eq(v.index, first + 2, "NEXT")
	v.back_button.pressed.emit()
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)
	assert_eq(v.index, first + 1, "BACK")
	assert_true(v.window.pad_move(Vector2i(0, -1)), "the D-pad's up")
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)
	assert_eq(v.index, first)
	assert_false(v.window.pad_move(Vector2i(1, 0)), "left and right move the focus on")
	assert_true(v.window.has_meta(&"pad_first"), "the pad starts on the Short")
	assert_true(v.player().playing, "it plays as it snaps in")
	v.window.pad_press()
	assert_false(v.player().playing, "Cross / A pauses")
	v.window.pad_press()
	assert_true(v.player().playing, "and plays")


func test_a_tap_plays_and_pauses_and_a_double_tap_gives_a_heart() -> void:
	var v := await _view()
	_touch(v, true, Vector2(140, 250))
	_touch(v, false, Vector2(140, 250))
	assert_true(v.player().playing, "a tap plays")
	await wait_seconds(0.5)
	_touch(v, true, Vector2(140, 250))
	_touch(v, false, Vector2(140, 250))
	_touch(v, true, Vector2(140, 250))
	_touch(v, false, Vector2(140, 250))
	assert_true(profile.shorts.is_liked(v.current_entry().id), "a double tap: a heart")
	assert_true(v.player().playing, "and it goes on playing")
	assert_eq(v.like_button.text, "LIKED")
	assert_gt(_saves, 0, "kept in the profile")
	await wait_seconds(0.5)
	_touch(v, true, Vector2(140, 250))
	_touch(v, false, Vector2(140, 250))
	assert_false(v.player().playing, "a tap pauses")


func test_the_heart_button_and_the_liked_list() -> void:
	var v := await _view()
	var id: String = v.current_entry().id
	v.like_button.pressed.emit()
	assert_true(profile.shorts.is_liked(id))
	assert_eq(v.like_button.text, "LIKED")
	v.filter_buttons[ShortFeed.LIKED].pressed.emit()
	assert_eq(v.feed.size(), 1)
	assert_eq(v.current_entry().id, id, "the liked Short waits there")
	v.like_button.pressed.emit()
	assert_false(profile.shorts.is_liked(id), "a second tap takes the heart back")
	v.set_filter(ShortFeed.LIKED)
	assert_true(v.feed.is_empty())
	assert_true(v.empty_label.visible, "an empty list says how to fill it")
	assert_true(v.like_button.disabled and v.learn_button.disabled)


func test_half_way_through_a_short_is_seen() -> void:
	var v := await _view()
	var id: String = v.current_entry().id
	v.player().play()
	v.player().advance(v.player().length() * 0.3)
	v._process(0.0)
	assert_false(profile.shorts.is_seen(id))
	v.player().advance(v.player().length() * 0.25)
	v._process(0.0)
	assert_true(profile.shorts.is_seen(id), "seen at half-way")
	assert_true(v.feed[v.index].seen)
	var row := v.rows[v.index - v._list_top]
	assert_true(row._tick.visible, "ticked in the list")


func test_the_lessons_filter_is_a_grades_lessons() -> void:
	var v := await _view()
	v.filter_buttons[ShortFeed.LESSONS].pressed.emit()
	assert_eq(v.grade, 4, "the School's grade")
	assert_true(v.grade_buttons[1].visible and v.grade_buttons[1].button_pressed)
	assert_gt(v.feed.size(), 100)
	assert_true(str(v.current_entry().id).begins_with("lesson:g4."))
	assert_string_contains(v.topic_label.text, "Grade 4")
	assert_true(v.player().is_built(), "the Lesson in a minute is made when it is shown")
	v.grade_buttons[3].pressed.emit()
	assert_true(str(v.current_entry().id).begins_with("lesson:g6."), "grade 6")
	v.filter_buttons[ShortFeed.HAND].pressed.emit()
	assert_false(v.grade_buttons[0].visible, "the grades only with the lessons")


func test_a_row_of_the_list_jumps_there() -> void:
	var v := await _view()
	v._jump(0, false)
	v.rows[3].pressed.emit()
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)
	assert_eq(v.index, 3)
	assert_true(v.player().playing)
	assert_eq(v.current_entry().id, v.feed[3].id)
	assert_true(v.rows[3 - v._list_top].current, "framed in the list")


func test_learn_it_asks_for_what_the_short_teaches() -> void:
	var v := await _view()
	watch_signals(v)
	v.learn_button.pressed.emit()
	assert_signal_emitted_with_parameters(v, "learn_requested", [v.current_entry().link])
	v.set_filter(ShortFeed.LESSONS)
	v.learn_button.pressed.emit()
	assert_signal_emitted_with_parameters(v, "learn_requested", [{"unit": v.current_entry().unit}])


func test_a_break_card_after_a_while_with_two_equal_choices() -> void:
	var v := await _view()
	v.set_filter(ShortFeed.LESSONS)
	for i in ShortsView.BREAK_AFTER:
		assert_true(v.step(1), "Short %d" % (i + 1))
		await wait_seconds(ShortsView.SNAP_SECONDS + 0.1)
	assert_false(v.step(1), "then a break")
	assert_true(v.on_break and v.break_card.visible)
	assert_false(v.player().playing)
	assert_eq(v.break_buttons.size(), 2)
	assert_eq(v.break_buttons[0].size, v.break_buttons[1].size, "two equal choices")
	var at := v.index
	v.break_buttons[1].pressed.emit()
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.1)
	assert_eq(v.index, at + 1, "MORE SHORTS goes on")
	watch_signals(v)
	v.shown = ShortsView.BREAK_AFTER
	v.step(1)
	v.break_buttons[0].pressed.emit()
	assert_signal_emitted(v, "exit_requested", "BACK TO MY WORLD")


func test_the_music_rests_while_a_short_plays() -> void:
	var v := await _view()
	var bus := AudioServer.get_bus_index(ShortsView.MUSIC_BUS)
	if bus < 0:
		pass_test("no music bus in this run")
		return
	v.toggle_play()
	assert_true(AudioServer.is_bus_mute(bus), "the game's music rests")
	v.toggle_play()
	assert_false(AudioServer.is_bus_mute(bus), "and comes back")
	v.toggle_play()
	v.leave()
	assert_false(AudioServer.is_bus_mute(bus), "leaving brings it back")


func test_the_voice_can_be_turned_off() -> void:
	var v := await _view()
	v.voice_button.pressed.emit()
	assert_false(v.player().voice_on)
	assert_eq(v.voice_button.text, "VOICE OFF")


func test_every_button_is_inside_the_view_and_none_overlap() -> void:
	var v := await _view()
	for f: StringName in [ShortFeed.HAND, ShortFeed.LESSONS]:
		v.set_filter(f)
		await wait_process_frames(2)
		var buttons: Array = v.find_children("*", "Button", true, false).filter(
			func(b: Node) -> bool: return (b as Control).is_visible_in_tree())
		assert_gt(buttons.size(), 12)
		var box := Rect2(v.global_position, ShortsView.SIZE).grow(0.5)
		for b: Button in buttons:
			assert_true(box.encloses(b.get_global_rect()), "%s inside the view" % b.name)
			assert_false(b.get_global_rect().intersects(v.window.get_global_rect()), "%s beside the Short, never over it" % b.name)
			assert_gte(b.size.y, 40.0, "%s big enough for a finger" % b.name)
		for i in buttons.size():
			for j in range(i + 1, buttons.size()):
				var a: Button = buttons[i]
				var b: Button = buttons[j]
				if a.is_ancestor_of(b) or b.is_ancestor_of(a):
					continue
				assert_false(a.get_global_rect().grow(-0.5).intersects(b.get_global_rect().grow(-0.5)), "%s and %s overlap" % [a.name, b.name])


## Performance (spec §5.12b): 2D only; a frame of playing or snapping costs little, and building the next Short
## (in its own frame) too. Phones are 3-5 times slower than this PC: 6 ms here is about 30 ms there.
func test_a_frame_is_cheap_while_playing_and_swiping() -> void:
	var v := await _view()
	v.set_filter(ShortFeed.LESSONS)
	var worst := 0
	var total := 0
	var frames := 0
	var builds: Array[int] = []
	for k in 6:
		v.player().play(true)
		for i in 40:
			var t0 := Time.get_ticks_usec()
			v.player().advance(1.0 / 60.0)
			v._process(1.0 / 60.0)
			var dt := Time.get_ticks_usec() - t0
			worst = maxi(worst, dt)
			total += dt
			frames += 1
		v.step(1)
		for i in 30:
			var t0 := Time.get_ticks_usec()
			v._process(1.0 / 60.0)
			var dt := Time.get_ticks_usec() - t0
			worst = maxi(worst, dt)
			total += dt
			frames += 1
	# Making and building a Short (what a neighbour costs, in a frame of its own): every hand-made one, and lessons.
	var fresh := ShortPlayer.new()
	fresh.size = ShortsView.PLAYER_SIZE
	add_child_autofree(fresh)
	var ids: Array[String] = []
	ids.append_array(ShortLibrary.hand_ids())
	for i in 12:
		ids.append(str(v.feed[i * 9].id))
	var makes: Array[int] = []
	for id in ids:
		var m0 := Time.get_ticks_usec()
		var s := ShortLibrary.get_short(id)
		makes.append(Time.get_ticks_usec() - m0)
		var b0 := Time.get_ticks_usec()
		fresh.build(s)
		builds.append(Time.get_ticks_usec() - b0)
	var avg := total / float(frames)
	gut.p("SHORTS_BENCH frames %d avg %.2f ms worst %.2f ms; build max %.2f ms avg %.2f ms; make max %.2f ms" % [frames,
		avg / 1000.0, worst / 1000.0, builds.max() / 1000.0, builds.reduce(func(a: int, b: int) -> int: return a + b) / 1000.0 / builds.size(),
		makes.max() / 1000.0])
	assert_lt(avg, 6000.0, "an average frame under 6 ms on this PC")
	assert_lt(builds.max(), 60000, "building a Short under 60 ms (it happens in a frame of its own)")
