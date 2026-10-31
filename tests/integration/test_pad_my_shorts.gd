extends GutTest
## MAKE MY SHORT with a game controller (owner #90's rule: every screen works with a pad): in the Theater's MY SHORTS
## the D-pad reaches MAKE A SHORT, CHANGE and DELETE; in the maker it reaches every choice of every step; Cross / A
## picks; Circle / B goes a step back (the first step closes the maker, the Theater stays).

const SCREEN := Vector2i(1280, 720)

var view: SubViewport
var pad: PadFocus
var _root := ""


func before_each() -> void:
	view = SubViewport.new()
	view.size = SCREEN
	add_child_autofree(view)
	pad = PadFocus.new()
	view.add_child(pad)
	_root = "user://test_pad_my_shorts_%d" % OS.get_process_id()
	MyShortAlbum.use(_root, PackedStringArray())
	for i in 3:
		var img := Image.create(320, 180, false, Image.FORMAT_RGB8)
		img.fill(Color(0.2, 0.3 * i, 0.6))
		MyShortAlbum.keep_png_now(img.save_png_to_buffer(), "p_20261001_00000%d.jpg" % i)


func after_each() -> void:
	MyShortAlbum.forget()
	MyShortAlbum.use(MyShortAlbum.ROOT)
	var d := _root.path_join("photos")
	if DirAccess.dir_exists_absolute(d):
		for f in DirAccess.get_files_at(d):
			DirAccess.remove_absolute(d.path_join(f))
		DirAccess.remove_absolute(d)
	DirAccess.remove_absolute(_root)
	var bus := AudioServer.get_bus_index(ShortsView.MUSIC_BUS)
	if bus >= 0:
		AudioServer.set_bus_mute(bus, false)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _tap(b: JoyButton) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventJoypadButton.new()
		e.device = 0
		e.button_index = b
		e.pressed = pressed
		view.push_input(e)


func _focus() -> Control:
	return view.gui_get_focus_owner()


func _wake() -> void:
	_tap(JOY_BUTTON_A)
	await _frames(3)


func _unreachable(root: Control) -> Array:
	var list := pad.candidates(root)
	var rects := []
	var own := []
	for i in list.size():
		rects.append(list[i].get_global_rect())
		if PadFocus.sideways_own(list[i]):
			own.append(i)
	var start := list.find(_focus())
	assert_gte(start, 0, "the focus is one of the panel's")
	if start < 0:
		return []
	var seen := GamepadRules.reachable(start, rects, own)
	var out := []
	for i in list.size():
		if not seen.has(i):
			out.append("%s '%s'" % [list[i].name, list[i].get("text")])
	return out


func _panel() -> TheaterPanel:
	var profile := ProfileData.new()
	profile.username = "Tester"
	profile.age_band = AgeBand.TEEN_PLUS
	profile.my_shorts.add({"template": "facts", "subject": {"kind": "planet", "id": "mars"}}, 1)
	var panel := TheaterPanel.new()
	panel.list = TheaterChannels.load_path(TheaterChannels.SAMPLE_PATH)
	panel.profile = profile
	panel.save_profile = func() -> void: pass
	panel.frees_mouse = false
	view.add_child(panel)
	await _frames(2)
	PadFocus.watch(panel)
	panel.exit_button.set_meta(&"pad_back", true)   # as the sandbox's pad_theater
	panel.open()
	await _frames(3)
	return panel


func test_my_shorts_and_every_step_of_the_maker_can_be_reached() -> void:
	var panel := await _panel()
	panel.shorts.set_filter(ShortFeed.MINE)
	await _frames(2)
	await _wake()
	assert_eq(_unreachable(panel), [], "MY SHORTS: MAKE A SHORT, CHANGE, DELETE and the rest")
	var m := panel.shorts.maker
	panel.shorts.open_maker()
	await _frames(3)
	await _wake()
	assert_true(m.is_ancestor_of(_focus()), "the maker has the pad")
	assert_eq(_unreachable(m), [], "KIND")
	m.choose_template(MyShortRules.BUILT)
	await _frames(3)
	assert_eq(_unreachable(m), [], "the photos")
	m.toggle_photo(0)
	m.toggle_photo(1)
	m.next()
	await _frames(3)
	assert_eq(_unreachable(m), [], "WORDS")
	m.next()
	await _frames(3)
	assert_eq(_unreachable(m), [], "LOOK")
	m.next()
	await _frames(3)
	assert_eq(_unreachable(m), [], "SAVE")


func test_cross_picks_and_circle_goes_a_step_back() -> void:
	var panel := await _panel()
	var m := panel.shorts.maker
	panel.shorts.open_maker()
	await _frames(3)
	await _wake()
	var card := _focus()
	assert_true(card != null and str(card.name).begins_with("Kind_"), "the focus starts on a kind: %s" % card)
	_tap(JOY_BUTTON_A)
	await _frames(3)
	assert_eq(m.step, MyShortMakerView.PICK, "Cross picks the kind")
	_tap(JOY_BUTTON_B)
	await _frames(3)
	assert_eq(m.step, MyShortMakerView.KIND, "Circle: a step back")
	_tap(JOY_BUTTON_B)
	await _frames(3)
	assert_false(m.is_open(), "Circle on the first step closes the maker")
	assert_true(panel.visible, "the Theater stays")
