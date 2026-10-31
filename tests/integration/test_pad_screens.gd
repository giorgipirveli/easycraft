extends GutTest
## Owner #90: every screen a child meets works with a game controller. On each one the focus starts somewhere sensible
## and the D-pad reaches every button (GamepadRules.reachable with PadFocus's own candidates: a slider or a row of
## pages keeps left and right for itself); Cross / A and Circle / B do what a tap and Back do. The menu's screens and
## SETTINGS, the pause menu, the School (its map, a unit, a round and a build answer), the Star Map and a body's card,
## the planet guide, the block palette, MORE's picture buttons, the CONTROLLER card; the HUD's touch buttons hide while
## a pad plays.

const SCREEN := Vector2i(1280, 720)

var view: SubViewport
var pad: PadFocus


class Recorder:
	extends Node
	var back_requests := 0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_WM_GO_BACK_REQUEST:
			back_requests += 1


func before_each() -> void:
	view = SubViewport.new()
	view.size = SCREEN
	add_child_autofree(view)
	pad = PadFocus.new()
	view.add_child(pad)


func after_each() -> void:
	get_tree().paused = false
	UniverseRegistry.reset()
	Curriculum.clear_cache()


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


## Wakes the pad on the active panel (the first press only shows the focus).
func _wake() -> void:
	_tap(JOY_BUTTON_A)
	await _frames(3)


## Every candidate of `root` the D-pad reaches from the focus; the names of those it cannot.
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


func _centered(c: Control) -> CenterContainer:
	var holder := CenterContainer.new()
	holder.size = Vector2(SCREEN)
	holder.theme = UiKit.theme()
	holder.add_child(c)
	view.add_child(holder)
	return holder


# --- SETTINGS ---

func test_every_settings_page_can_be_reached() -> void:
	var panel := SettingsPanel.new()
	panel.saver = func() -> void: pass
	var holder := _centered(panel)
	PadFocus.watch(holder)
	await _frames(2)
	await _wake()
	assert_eq(_focus().name, "Page_game", "the page buttons first (then the page under them)")
	for page: StringName in [SettingsPanel.GAME, SettingsPanel.WORDS, SettingsPanel.ACCESS]:
		panel.show_page(page)
		await _frames(2)
		assert_eq(_unreachable(holder), [], "page %s" % page)
	var back := panel.find_children("*", "Button", true, false).filter(func(b: Node) -> bool:
		return (b as Button).text == "BACK")[0] as Button
	watch_signals(panel)
	_tap(JOY_BUTTON_B)
	assert_signal_emitted(panel, "closed", "Circle / B is SETTINGS' BACK")
	assert_not_null(back)


func test_settings_sliders_slide_with_the_d_pad() -> void:
	var saved: float = Profile.data.settings.volume
	var panel := SettingsPanel.new()
	panel.saver = func() -> void: pass
	var holder := _centered(panel)
	PadFocus.watch(holder)
	await _frames(2)
	await _wake()
	var slider: HSlider = null
	for s in panel.find_children("*", "HSlider", true, false):
		if (s as HSlider).max_value == 100 and (s as HSlider).name != "MusicSlider" and (s as HSlider).name != "SfxSlider":
			slider = s
	slider.grab_focus()
	var before := slider.value
	_tap(JOY_BUTTON_DPAD_LEFT)
	assert_eq(slider.value, maxf(before - 5.0, 0.0), "left: quieter")
	Profile.data.settings.volume = saved

# --- The pause menu ---

func test_the_pause_menu_resume_first_and_circle_resumes() -> void:
	var menu := PauseMenu.new()
	view.add_child(menu)
	await _frames(1)
	menu.open()
	await _frames(2)
	await _wake()
	assert_eq((_focus() as Button).text, "RESUME")
	assert_eq(_unreachable(menu), [])
	var settings := menu.find_children("*", "Button", true, false).filter(func(b: Node) -> bool:
		return (b as Button).text == "SETTINGS")[0] as Button
	settings.grab_focus()
	_tap(JOY_BUTTON_A)
	await _frames(3)
	assert_not_null(menu.find_children("*", "SettingsPanel", true, false).front(), "SETTINGS opened")
	assert_eq(_focus().name, "Page_game", "the focus moved into SETTINGS")
	_tap(JOY_BUTTON_B)
	await _frames(3)
	assert_true(menu.visible, "Circle / B in SETTINGS goes back to the menu's buttons, not out of the pause")
	assert_eq((_focus() as Button).text, "RESUME")
	_tap(JOY_BUTTON_B)
	assert_false(menu.visible, "Circle / B on the buttons resumes")
	assert_false(get_tree().paused)


func test_the_pause_menu_offers_the_controller_card() -> void:
	var menu := PauseMenu.new()
	view.add_child(menu)
	await _frames(1)
	_tap(JOY_BUTTON_X)   # a pad plays
	menu.open()
	await _frames(3)
	var help := menu.find_child("Help", true, false) as Button
	assert_not_null(help, "CONTROLLER beside BOARD")
	assert_eq(help.text, "CONTROLLER")
	help.pressed.emit()
	await _frames(3)
	var card := menu.find_children("*", "KeysCard", true, false).front() as KeysCard
	assert_not_null(card)
	assert_ne(card.family, &"", "the controller's card")
	assert_eq((_focus() as Button).text, "CLOSE")
	_tap(JOY_BUTTON_B)
	await _frames(3)
	assert_eq((_focus() as Button).text, "RESUME", "CLOSE, back to the menu")

# --- The School ---

const UNIT := "g4.maths.big_numbers"
const CONTENT := {"id": UNIT, "lesson": [{"text": "A digit's place tells what it is worth."}],
	"exercises": [
		{"type": "build", "prompt": "Build 2 rows of 3.", "board": {"cols": 6, "rows": 3, "block": 9, "given": []},
			"goal": {"kind": "array", "rows": 2, "cols": 3}, "hint": "A row of 3 first.", "level": 1},
		{"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 0,
			"hint": "No hundreds.", "level": 3}],
	"generators": []}


func _school() -> SchoolScreen:
	Curriculum.clear_cache()
	Curriculum.put_content(UNIT, CONTENT)
	var profile := ProfileData.new()
	profile.school.grade = 4
	var screen := SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: pass
	screen.today = func() -> int: return 20_000
	screen.next_seed = func() -> int: return 7
	var holder := _centered(screen)
	PadFocus.watch(holder)
	await _frames(3)
	return screen


func test_the_school_s_pages_can_be_reached_and_circle_goes_back() -> void:
	var screen := await _school()
	screen.show_map("maths")
	await _frames(3)
	await _wake()
	var holder := screen.get_parent() as Control
	assert_false(GamepadRules.is_back_word((_focus() as Button).text), "never BACK first")
	assert_eq(_unreachable(holder), [], "the map")
	screen.show_unit(UNIT)
	await _frames(3)
	assert_eq(_unreachable(holder), [], "a unit")
	_tap(JOY_BUTTON_B)
	await _frames(3)
	assert_true(holder.find_children("*", "Button", true, false).any(func(b: Node) -> bool:
		return (b as Button).is_visible_in_tree() and (b as Button).text == "GRADE"), "Circle / B: back to the map")


func test_a_build_answer_is_built_with_the_d_pad() -> void:
	var screen := await _school()
	screen.show_round(UNIT)
	await _frames(3)
	await _wake()
	var board := screen.find_children("*", "BuildBoard", true, false).front() as BuildBoard
	if board == null:
		pass_test("this round started with another exercise")
		return
	board.view.grab_focus()
	_tap(JOY_BUTTON_A)
	assert_eq(board.placed.size(), 1, "Cross / A places a block under the cursor")
	_tap(JOY_BUTTON_DPAD_RIGHT)
	_tap(JOY_BUTTON_A)
	assert_eq(board.placed.size(), 2, "the next cell")
	_tap(JOY_BUTTON_A)
	assert_eq(board.placed.size(), 1, "again: taken away")
	for i in 3:
		_tap(JOY_BUTTON_DPAD_DOWN)
	assert_ne(_focus(), board.view, "past the board's edge the focus moves on to the buttons")

# --- The Star Map, a body's card, the planet guide ---

func test_the_star_map_starts_on_the_child_s_planet_and_its_card_backs_out() -> void:
	var rec := Recorder.new()
	add_child_autofree(rec)
	var map := SpacePanel.new()
	map.size = Vector2(SCREEN)
	view.add_child(map)
	await _frames(1)
	var built: Array[int] = [16, 17, 18]
	map.open(1, 1, built, 2)
	await _frames(2)
	await _wake()
	var here := map.here_body()
	assert_not_null(here)
	assert_eq(_focus(), here, "the planet the child flew up from")
	var others := pad.candidates(map).filter(func(c: Control) -> bool: return c is StarBody)
	assert_eq(others.size(), map.bodies.size(), "every body can take the focus")
	_tap(JOY_BUTTON_DPAD_RIGHT)
	var moved := _focus()
	assert_true(moved is StarBody and moved != here, "the D-pad goes to another body")
	_tap(JOY_BUTTON_A)
	await _frames(3)
	assert_true(map.card_open(), "Cross / A opens its card")
	assert_true(_focus() == map.action_button or _focus() == map.map_button, "the card's buttons have the focus")
	_tap(JOY_BUTTON_B)
	await _frames(3)
	assert_false(map.card_open(), "Circle / B closes the card first")
	assert_eq(_focus(), moved, "back on that body")
	_tap(JOY_BUTTON_B)
	assert_eq(rec.back_requests, 1, "then the game's Back (the director closes the map)")


func test_the_planet_guide_s_let_s_go() -> void:
	var list: Array[Dictionary] = [{"name": "The long cliff", "found": false}]
	var card := PlanetGuideCard.new("Mercury", list)
	view.add_child(card)
	await _frames(2)
	await _wake()
	assert_eq(_focus(), card.go_button)
	watch_signals(card)
	_tap(JOY_BUTTON_B)
	assert_signal_emitted(card, "closed", "Circle / B: LET'S GO too")

# --- The HUD: the palette, MORE, the touch buttons ---

func test_the_block_palette_starts_on_a_block_and_turns_pages() -> void:
	var palette := BlockPalette.new()
	view.add_child(palette)
	PadFocus.watch(palette)
	await _frames(1)
	palette.open()
	await _frames(3)
	await _wake()
	assert_true(_focus() is Button and not (_focus() is TabBar), "a block, not the page row")
	assert_eq(palette.tab_bar.current_tab, 0)
	_tap(JOY_BUTTON_RIGHT_SHOULDER)
	assert_ne(palette.tab_bar.current_tab, 0, "R1: the next page")
	_tap(JOY_BUTTON_LEFT_SHOULDER)
	assert_eq(palette.tab_bar.current_tab, 0, "L1: back")
	palette.show_page(0)
	await _frames(2)
	assert_eq(_unreachable(palette), [], "every block on the page")


func test_more_s_picture_buttons_press_with_cross() -> void:
	var more := MorePanel.new()
	view.add_child(more)
	PadFocus.watch(more)
	var buttons: Array[TouchButton] = []
	for w in ["MAP", "PHOTO", "SIZE", "UNDO"]:
		var b := TouchButton.new()
		b.text = w
		b.symbol = &"map"
		more.add(b)
		buttons.append(b)
	await _frames(1)
	more.open()
	await _frames(3)
	await _wake()
	assert_eq(_focus(), buttons[0])
	assert_eq(_unreachable(more), [])
	watch_signals(buttons[1])
	_tap(JOY_BUTTON_DPAD_RIGHT)
	_tap(JOY_BUTTON_A)
	assert_signal_emitted(buttons[1], "pressed", "Cross / A taps a picture button")


func test_the_touch_buttons_hide_while_a_pad_plays_on_a_phone() -> void:
	var hud := Hud.new()
	view.add_child(hud)
	await _frames(1)
	hud._touch_base = true   # a phone (setup's show_touch)
	hud.set_pad(true)
	for c: Control in [hud.joystick, hud.look_area, hud.jump_button, hud.physics_button]:
		assert_false(c.visible, "%s hides" % c.name)
	assert_false(hud.crouch_button.visible)
	assert_true(hud.size_button.visible, "MORE keeps its picture buttons")
	hud.set_pad(false)
	for c: Control in [hud.joystick, hud.look_area, hud.jump_button, hud.physics_button]:
		assert_true(c.visible, "%s is back for the finger" % c.name)


func test_a_pc_s_more_gets_its_picture_buttons_for_the_pad() -> void:
	var hud := Hud.new()
	view.add_child(hud)
	await _frames(1)
	hud._touch_base = false   # a PC: the keys have SIZE, CAM, UNDO, MIRROR
	hud.set_pad(false)
	assert_false(hud.size_button.visible)
	hud.set_pad(true)
	for c: Control in [hud.size_button, hud.camera_button, hud.undo_button, hud.mirror_button]:
		assert_true(c.visible, "%s: the pad reaches it through MORE" % c.name)
	assert_false(hud.joystick.visible, "a PC never shows the stick")


# --- The Mission Board (spec §21d) ---

func test_the_mission_board_s_pages_can_be_reached_and_circle_closes_it() -> void:
	var board := MissionBoard.new()
	board.read_rocket = func() -> Dictionary: return {}
	board.owned = func() -> Variant: return {}
	board.have = func(_id: int) -> int: return 0
	board.gold = func() -> int: return 500
	board.buy = func(_id: int, _n: int) -> String: return ""
	board.launch = func(_r: Dictionary) -> String: return ""
	board.route = func() -> Array[int]: return [] as Array[int]
	var open_worlds: Array[int] = [16, 17, 18]
	board.available = func() -> Array[int]: return open_worlds
	view.add_child(board)
	PadFocus.watch(board)
	await _frames(1)
	board.open()
	await _frames(3)
	await _wake()
	assert_not_null(_focus())
	assert_false(PadFocus.is_back_button(_focus()), "never X first")
	for page in 3:
		board.show_page(page)
		await _frames(3)
		assert_eq(_unreachable(board), [], "page %d" % page)
	watch_signals(board)
	_tap(JOY_BUTTON_B)
	assert_signal_emitted(board, "closed", "Circle / B is its X")


# --- The Gold Shop (owner #79, #83: in the menu, so the menu's watch covers it) ---

func test_the_gold_shop_can_be_reached_and_circle_goes_back() -> void:
	SpendRules.clear_extra()
	var profile := ProfileData.new()
	profile.survivor_gold = 500
	var shop := GoldShop.new()
	shop.profile = profile
	shop.save_profile = func() -> void: pass
	var holder := _centered(shop)
	PadFocus.watch(holder)
	await _frames(3)
	await _wake()
	assert_not_null(_focus())
	assert_false(PadFocus.is_back_button(_focus()), "never BACK first")
	assert_eq(_unreachable(holder), [], "every shelf button")
	watch_signals(shop)
	_tap(JOY_BUTTON_B)
	await _frames(2)
	assert_signal_emitted(shop, "closed", "Circle / B is its BACK")
	SpendRules.clear_extra()


# --- The Theater (owner #89): its screen has the pad inside; Circle / B stops a video, then leaves ---

func test_the_theater_s_screen_and_circle_leaves() -> void:
	var profile := ProfileData.new()
	profile.username = "Tester"
	profile.age_band = AgeBand.TEEN_PLUS
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
	await _wake()
	assert_not_null(_focus())
	assert_ne(_focus(), panel.exit_button, "never EXIT first")
	assert_eq(_unreachable(panel), [])
	watch_signals(panel)
	_tap(JOY_BUTTON_B)
	await _frames(2)
	assert_signal_emitted(panel, "exit_requested", "Circle / B: EXIT (no video playing)")
	assert_false(panel.visible)
