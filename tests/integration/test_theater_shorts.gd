extends GutTest
## Owner #94 (spec §5.12b): EasyCraft Shorts in the Theater (the TV shows room). A SHORTS tab first among the tabs; the
## Theater opens on it, the feed under the tabs, a 9:16 Short in the middle with nothing over it; the channels are one
## tab away and back; a phone without the video plugin still has the Shorts; the grown-ups' switch covers them; the
## keys; LEARN IT's School page over the Theater, or the Mission Board and the Star Map in the world.

const KID := AgeBand.UNDER_13
const TEEN := AgeBand.TEEN_PLUS
const SCREEN := Vector2i(2400, 1080)

class FakeVoice:
	extends ReadAloud.Voice

	func has_voice(_language: String) -> bool:
		return true


var _window_size: Vector2i
var _voice: ReadAloud.Voice
var _saves := 0
var bundled: Dictionary


func before_all() -> void:
	_window_size = get_window().size
	bundled = TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)


func before_each() -> void:
	_saves = 0
	get_window().size = SCREEN
	_voice = ReadAloud.voice
	ReadAloud.voice = FakeVoice.new()


func after_each() -> void:
	ReadAloud.voice = _voice
	AudioServer.set_bus_mute(TheaterPanel.MASTER_BUS, false)
	ShortLibrary.clear_cache()
	Curriculum.clear_cache()


func after_all() -> void:
	get_window().size = _window_size


func _panel(band: StringName = TEEN, mobile: bool = false, switch: StringName = TheaterRules.SWITCH_AUTO) -> TheaterPanel:
	var p := ProfileData.new()
	p.age_band = band
	p.theater_switch = switch
	p.school.grade = 5
	var panel := TheaterPanel.new()
	panel.list = bundled
	panel.profile = p
	panel.save_profile = func() -> void: _saves += 1
	panel.is_mobile = mobile
	panel.keyboard = true
	panel.frees_mouse = false
	add_child_autofree(panel)
	await wait_process_frames(2)
	panel.open()
	await wait_process_frames(2)
	return panel


func _key(panel: TheaterPanel, code: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = true
	panel._unhandled_key_input(e)


func test_the_theater_opens_on_its_shorts_tab_first() -> void:
	var panel := await _panel()
	assert_eq(panel.view, TheaterPanel.VIEW_SHORTS)
	assert_eq(panel._tabs.get_child(0), panel.shorts_tab, "SHORTS is the first tab")
	assert_true(panel.shorts_tab.button_pressed)
	assert_eq(panel.shorts_tab.label.text, "SHORTS")
	assert_true(panel.shorts.is_visible_in_tree())
	assert_false(panel.shorts.player().playing, "walking in shows it still (nothing starts by itself)")
	assert_eq(panel.channel_buttons.size(), bundled.channels.size(), "the channels follow it")
	assert_false(panel.channel_buttons[0].disabled)
	for tab: Button in [panel.shorts_tab] + panel.channel_buttons:
		assert_gte(tab.size.x, 80.0, "%s is big" % tab.tooltip_text)
	assert_false(panel.still.is_visible_in_tree(), "the 16:9 player is away")
	assert_false(panel.next_button.is_visible_in_tree())


func test_the_short_is_portrait_in_the_middle_and_nothing_is_over_it() -> void:
	var panel := await _panel()
	var r := panel.shorts.window.get_global_rect()
	var vp := panel.get_viewport_rect()
	assert_almost_eq(r.size.x / r.size.y, 9.0 / 16.0, 0.01, "9:16")
	assert_almost_eq(r.get_center().x, vp.size.x / 2.0, 1.0, "in the middle")
	var buttons: Array = panel.find_children("*", "Button", true, false).filter(
		func(b: Node) -> bool: return (b as Control).is_visible_in_tree())
	assert_gt(buttons.size(), 20)
	for b: Button in buttons:
		assert_false(b.get_global_rect().intersects(r), "%s beside the Short" % b.name)
		assert_true(vp.encloses(b.get_global_rect()), "%s on screen" % b.name)
	for i in buttons.size():
		for j in range(i + 1, buttons.size()):
			var a: Button = buttons[i]
			var b: Button = buttons[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			assert_false(a.get_global_rect().grow(-0.5).intersects(b.get_global_rect().grow(-0.5)), "%s and %s overlap" % [a.name, b.name])
	for tab: Button in [panel.shorts_tab] + panel.channel_buttons:
		assert_lte(tab.get_global_rect().end.y, panel.shorts.get_global_rect().position.y + 0.5, "the tabs above the Shorts")
	assert_true(panel.blockers().has(panel.shorts) and panel.blockers().has(panel.school), "a tap on them never builds behind")


func test_a_channel_tab_leaves_the_shorts_and_shorts_comes_back() -> void:
	var panel := await _panel()
	panel.shorts.toggle_play()
	assert_true(panel.shorts.player().playing)
	watch_signals(panel)
	panel.channel_buttons[1].pressed.emit()
	assert_eq(panel.view, TheaterPanel.VIEW_PLAY)
	assert_false(panel.shorts.player().playing, "the Short stops")
	assert_false(panel.shorts.is_visible_in_tree())
	assert_true(panel.still.is_visible_in_tree(), "the channel's video")
	assert_true(panel.next_button.is_visible_in_tree())
	assert_false(panel.shorts_tab.button_pressed)
	assert_signal_emitted(panel, "layout_changed", "the HUD looks again")
	panel.shorts_tab.pressed.emit()
	assert_eq(panel.view, TheaterPanel.VIEW_SHORTS)
	assert_true(panel.shorts.is_visible_in_tree())
	assert_false(panel.next_button.is_visible_in_tree())


func test_a_phone_without_the_video_player_still_has_the_shorts() -> void:
	var panel := await _panel(TEEN, true)
	assert_eq(panel.view, TheaterPanel.VIEW_SHORTS, "no plugin: the channels would say Coming soon, the Shorts play")
	assert_true(panel.shorts_tab.visible)
	assert_true(panel.channel_buttons.is_empty())


func test_the_grown_ups_switch_covers_the_shorts_too() -> void:
	var off := await _panel(TEEN, false, TheaterRules.SWITCH_OFF)
	assert_eq(off.view, TheaterPanel.VIEW_ASK_PARENT)
	assert_false(off.shorts_tab.visible)
	assert_false(off.shorts.is_visible_in_tree())
	var child := await _panel(KID)
	assert_eq(child.view, TheaterPanel.VIEW_ASK_PARENT, "a child's Theater waits for a grown-up while the age rules are on")
	var on := await _panel(KID, false, TheaterRules.SWITCH_ON)
	assert_eq(on.view, TheaterPanel.VIEW_SHORTS)


func test_the_grown_ups_button_opens_the_gate() -> void:
	var panel := await _panel()
	panel.shorts.grownups_button.pressed.emit()
	assert_eq(panel.view, TheaterPanel.VIEW_GATE)
	assert_false(panel.shorts.is_visible_in_tree())


func test_keys_move_play_and_leave() -> void:
	var panel := await _panel()
	var first := panel.shorts.index
	_key(panel, KEY_DOWN)
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)
	assert_eq(panel.shorts.index, first + 1, "↓ the next Short")
	_key(panel, KEY_PAGEUP)
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)
	assert_eq(panel.shorts.index, first, "PageUp the last one")
	_key(panel, KEY_N)
	await wait_seconds(ShortsView.SNAP_SECONDS + 0.15)
	assert_eq(panel.shorts.index, first + 1, "N as on the channels")
	_key(panel, KEY_SPACE)
	var playing := panel.shorts.player().playing
	_key(panel, KEY_SPACE)
	assert_ne(panel.shorts.player().playing, playing, "Space plays and pauses")
	_key(panel, KEY_ESCAPE)
	assert_false(panel.is_open(), "Esc leaves the Theater")


func test_learn_it_on_a_lesson_opens_its_school_page_over_the_theater() -> void:
	var panel := await _panel()
	panel.shorts.set_filter(ShortFeed.LESSONS)
	var unit: String = panel.shorts.current_entry().unit
	panel.shorts.learn_button.pressed.emit()
	await wait_process_frames(2)
	assert_true(panel.school.is_open())
	assert_eq(panel.school.screen.unit_id, unit, "that unit's page")
	assert_eq(panel.school.screen.page, SchoolScreen.UNIT)
	assert_true(panel.is_open(), "the Theater stays")
	assert_false(panel.shorts.player().playing)
	_key(panel, KEY_DOWN)
	assert_true(panel.school.is_open(), "the Shorts' keys wait while the School is open")
	panel.school.screen.closed.emit()
	assert_false(panel.school.is_open(), "its BACK comes back to the Shorts")
	assert_true(panel.shorts.is_visible_in_tree())


func test_learn_it_on_a_rocket_short_leaves_for_the_mission_board() -> void:
	var panel := await _panel()
	panel.shorts.set_filter(ShortFeed.HAND)
	panel.shorts._jump(0, false)
	assert_eq(panel.shorts.current_entry().id, "rocket_parts")
	watch_signals(panel)
	panel.shorts.learn_button.pressed.emit()
	assert_signal_emitted_with_parameters(panel, "learn_requested", [{"board": true}])
	assert_signal_emitted(panel, "exit_requested")
	assert_false(panel.is_open(), "the board is in the world")


func test_a_menu_over_the_screen_pauses_the_short() -> void:
	var panel := await _panel()
	panel.shorts.toggle_play()
	panel.set_covered(true)
	assert_false(panel.shorts.player().playing)
	panel.set_covered(false)
	assert_true(panel.shorts.player().playing, "and it goes on")


func test_leaving_stops_the_short_and_its_voice() -> void:
	var panel := await _panel()
	panel.shorts.toggle_play()
	panel.close()
	assert_false(panel.shorts.player().playing)
	assert_false(panel.shorts.is_holding_music(), "the game's music comes back")
