extends GutTest
## Owner feedback #49 (2026-09-24, playing online through the real server on phones, 0.3.2): "we need to
## improve chat, when you type you dont see the text, also text chats are not showing correctly".
## On the emulator's 2400 × 1080 screen and a 1280 × 720 phone, with a crowded Survivor HUD (a game's round
## line and clock, the Brave badge, the race clock, the gold) and a phone keyboard over the bottom 55 % of
## the screen: nothing on the HUD is drawn over the open chat (its field, buttons, lines or the wheel); the
## field, the phrase and command buttons and the newest lines stay above the keyboard; the lines stay clear
## of the quick-chat wheel; a friend's long line wraps inside the history and every line reads on any world
## (a dark backing, contrast at least 4.5); Georgian letters have glyphs in the game's own font chain.
## Pictures: tools/chat_shots.gd. Notes: docs/devlog/parts/owner-49-chat.md.

const SCREENS: Array[Vector2i] = [Vector2i(2400, 1080), Vector2i(1280, 720)]
## A phone's landscape keyboard covers about the bottom half of the screen (Gboard, Samsung Keyboard).
const KEYBOARD_SHARE := 0.55
const TYPED := "გამარჯობა! მოდი აქ, სახლს ვაშენებთ ერთად"
const LONG := "I found a cave with lots of shiny blocks and a waterfall behind the big tree near the river, come see it!"
## Every letter of the Georgian alphabet (Mkhedruli), as a child types it.
const GEORGIAN := "აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ"
## WCAG AA for normal text.
const MIN_CONTRAST := 4.5

var _window_size: Vector2i
var _band: StringName
var _mode: StringName


class AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


func before_all() -> void:
	_window_size = get_window().size
	_band = Profile.data.age_band
	_mode = Game.mode


func after_all() -> void:
	get_window().size = _window_size
	Profile.data.age_band = _band
	Game.mode = _mode


func after_each() -> void:
	Profile.data.age_band = _band
	Game.mode = _mode


func _player() -> Player:
	var w := AirWorld.new()
	autofree(w)
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	return p


## A 13+ player's HUD in a Survivor game on a phone: hearts, the Brave badge, a game's clock and round
## line, the race clock, the treasure compass, FPS on; ten lines in the chat (a long one, Georgian ones).
func _hud(screen: Vector2i, band: StringName = AgeBand.TEEN_PLUS) -> Hud:
	get_window().size = screen
	Game.mode = ModeRules.SURVIVOR
	Profile.data.age_band = band
	var hud := Hud.new()
	add_child_autofree(hud)
	hud.setup(_player(), "Kid", true, true)
	hud.add_health_controls()
	hud.add_secret_controls(null)
	hud.show_difficulty_badge(DifficultyRules.BRAVE)
	hud.add_game_clock()
	hud.game_clock.show_build(DayCycle.NOON, 3, 5, ShelterRules.OPEN)
	hud.game_line.show_line("Build to Survive: night in 0:50")
	hud.show_race_state({"on": true, "armed": false, "elapsed": 72300, "coins": 99, "event": "go"})
	for i in 10:
		match i % 4:
			0: hud.chat.add_line("line %d: %s" % [i, LONG], &"chat", "Pip")
			1: hud.chat.add_line("line %d: გამარჯობა! მოდი აქ" % i, &"chat", "Nika")
			2: hud.chat.add_line("line %d: Night is coming. Build a roof!" % i, &"system")
			3: hud.chat.add_line("line %d: კარგი! უკან მოგყვები!" % i, &"bot", "Mossy (bot)")
	await wait_process_frames(3)
	return hud


## The phone keyboard up: KEYBOARD_SHARE of the screen's height, in screen pixels. Returns its top edge
## (screen pixels).
func _keyboard(hud: Hud, share: float = KEYBOARD_SHARE) -> float:
	var h := get_window().size.y
	var px := int(round(h * share))
	hud.chat.keyboard_height = func() -> int: return px
	return float(h - px)


## A rectangle of the canvas on the screen (pixels).
func _on_screen(r: Rect2) -> Rect2:
	return get_viewport().get_final_transform() * r


## The newest line of the chat, drawn (its label), or null.
func _newest_label(chat: ChatPanel) -> Label:
	var at := chat.line_position(chat._lines.size() - 1)
	if not at.is_finite():
		return null
	for l in chat._labels:
		if l.visible and l.get_global_rect().has_point(at):
			return l
	return null


func _visible_lines(chat: ChatPanel) -> int:
	var n := 0
	for l in chat._labels:
		if l.visible:
			n += 1
	return n


## Where each piece of the open chat is on the screen, and that the phone keyboard leaves them alone.
func _check_above_keyboard(chat: ChatPanel, keyboard_top: float, what: String, least_lines: int) -> void:
	var field := _on_screen(chat._field.get_global_rect())
	assert_true(Rect2(Vector2.ZERO, get_window().size).encloses(field), "%s: the field is on the screen (%s)" % [what, field])
	assert_lte(field.end.y, keyboard_top, "%s: the field is above the keyboard" % what)
	if chat._choices_panel.visible:
		var choices := _on_screen(chat._choices_panel.get_global_rect())
		assert_lte(choices.end.y, keyboard_top, "%s: the phrase / command buttons are above the keyboard (%s)" % [what, choices])
	var newest := _newest_label(chat)
	assert_not_null(newest, "%s: the newest line shows" % what)
	if newest:
		assert_lte(_on_screen(newest.get_global_rect()).end.y, keyboard_top, "%s: the newest line is above the keyboard" % what)
	for l in chat._labels:
		if l.visible:
			assert_lte(_on_screen(l.get_global_rect()).end.y, keyboard_top, "%s: '%s' is above the keyboard" % [what, l.text])
	assert_gte(_visible_lines(chat), least_lines, "%s: at least %d lines to read" % [what, least_lines])


# --- The phone keyboard ---

func test_what_a_child_types_and_the_newest_lines_stay_above_the_keyboard() -> void:
	for screen in SCREENS:
		var hud := await _hud(screen)
		var top := _keyboard(hud)
		hud.chat.open()
		hud.chat._set_text(TYPED)
		await wait_process_frames(3)
		assert_eq(hud.chat._field.text, TYPED)
		assert_false(hud.chat._choices_panel.visible, "typing words: no buttons")
		_check_above_keyboard(hud.chat, top, "%s typing" % screen, 4)
		hud.queue_free()
		await wait_process_frames(1)


func test_the_phrase_and_command_buttons_and_the_newest_line_fit_above_the_keyboard() -> void:
	for screen in SCREENS:
		var hud := await _hud(screen)
		var top := _keyboard(hud)
		hud.chat.open()
		await wait_process_frames(3)
		assert_true(hud.chat._choices_panel.visible, "the phrases")
		_check_above_keyboard(hud.chat, top, "%s phrases" % screen, 1)
		hud.chat._set_text("/")
		await wait_process_frames(3)
		assert_true(hud.chat._choices_panel.visible, "the commands")
		_check_above_keyboard(hud.chat, top, "%s commands" % screen, 1)
		hud.queue_free()
		await wait_process_frames(1)


func test_the_chat_follows_the_keyboard_up_and_down() -> void:
	var hud := await _hud(SCREENS[0])
	hud.chat.open()
	hud.chat._set_text(TYPED)
	await wait_process_frames(3)
	var without := _visible_lines(hud.chat)
	var top := _keyboard(hud)   # the keyboard slides up while the bar is open
	await wait_process_frames(3)
	_check_above_keyboard(hud.chat, top, "keyboard up", 4)
	assert_lt(_visible_lines(hud.chat), without, "fewer lines fit above it")
	hud.chat.keyboard_height = func() -> int: return 0   # and down again (the Back key)
	await wait_process_frames(3)
	assert_eq(_visible_lines(hud.chat), without, "all the lines again")


# --- The HUD on top ---

## Draws before (under) the chat: the HUD's child that holds `c` comes before the chat panel.
func _under_chat(hud: Hud, c: Control) -> bool:
	var top: Node = c
	while top.get_parent() != hud:
		top = top.get_parent()
	return top.get_index() < hud.chat.get_index()


func _check_nothing_covers(hud: Hud, targets: Dictionary, what: String) -> void:
	for n in hud.find_children("*", "Control", true, false):
		var c := n as Control
		if c == hud.chat or hud.chat.is_ancestor_of(c) or not c.is_visible_in_tree() or c.size == Vector2.ZERO:
			continue
		var r := c.get_global_rect()
		for key: String in targets:
			if r.intersects(targets[key]):
				assert_true(_under_chat(hud, c), "%s: %s (%s) is drawn over the chat's %s" % [what, c.name, c.get_class(), key])


func test_nothing_on_the_hud_is_drawn_over_the_open_chat() -> void:
	for screen in SCREENS:
		var hud := await _hud(screen)
		hud.chat.open()
		hud.chat._set_text(TYPED)
		await wait_process_frames(3)
		_check_nothing_covers(hud, {"field": hud.chat._field.get_global_rect(), "bar": hud.chat._bar.get_global_rect()},
			"%s typing" % screen)
		hud.chat._set_text("")
		await wait_process_frames(3)
		var targets := {"buttons": hud.chat._choices_panel.get_global_rect()}
		for l in hud.chat._labels:
			if l.visible:
				targets["line '%s'" % l.text.left(12)] = l.get_global_rect()
		_check_nothing_covers(hud, targets, "%s phrases" % screen)
		hud.chat.open_wheel()
		await wait_process_frames(3)
		var wheel := {}
		for r in hud.chat.wheel.slot_rects() + hud.chat.wheel.pill_rects():
			wheel["wheel %s" % r] = r
		_check_nothing_covers(hud, wheel, "%s wheel" % screen)
		hud.chat.close()
		await wait_process_frames(1)
		assert_lt(hud.chat.get_index(), hud.palette.get_index(), "%s: closed, the chat is under the palette overlay again" % screen)
		hud.queue_free()
		await wait_process_frames(1)


func test_closed_lines_stay_readable_over_the_games_clock() -> void:
	for screen in SCREENS:
		var hud := await _hud(screen)
		var targets := {}
		for l in hud.chat._labels:
			if l.visible:
				targets["line '%s'" % l.text.left(12)] = l.get_global_rect()
		assert_gt(targets.size(), 0)
		for key: String in targets:
			if hud.game_clock.get_global_rect().intersects(targets[key]):
				assert_true(_under_chat(hud, hud.game_clock), "%s: the game clock is drawn over %s" % [screen, key])
		hud.queue_free()
		await wait_process_frames(1)


# --- The quick-chat wheel (under-13 players chat with it only) ---

func test_while_the_wheel_is_open_the_lines_stay_clear_of_it() -> void:
	for screen in SCREENS:
		var hud := await _hud(screen, AgeBand.UNDER_13)
		hud.chat.open()
		await wait_process_frames(3)
		assert_true(hud.chat.wheel.visible, "under-13: the wheel")
		var view := Rect2(Vector2.ZERO, hud.get_viewport_rect().size)
		assert_not_null(_newest_label(hud.chat), "%s: the newest line shows beside the wheel" % screen)
		assert_gte(_visible_lines(hud.chat), 4, "%s: lines to read" % screen)
		for l in hud.chat._labels:
			if not l.visible:
				continue
			var r := l.get_global_rect()
			assert_true(view.encloses(r), "%s: '%s' is on the screen" % [screen, l.text])
			for s in hud.chat.wheel.slot_rects() + hud.chat.wheel.pill_rects():
				assert_false(r.intersects(s), "%s: '%s' is clear of the wheel (%s)" % [screen, l.text.left(16), s])
			for b: Control in [hud.pause_button, hud.chat.button, hud.book_button]:
				assert_false(r.intersects(b.get_global_rect()), "%s: '%s' is clear of %s" % [screen, l.text.left(16), b.text])
		assert_gt(hud.chat._history.get_index(), hud.chat.wheel.get_index(), "the lines are drawn over the wheel's dim")
		hud.queue_free()
		await wait_process_frames(1)


# --- Friends' lines ---

## Relative luminance (WCAG 2).
func _luminance(c: Color) -> float:
	var l := func(v: float) -> float: return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * l.call(c.r) + 0.7152 * l.call(c.g) + 0.0722 * l.call(c.b)


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func test_a_friends_long_line_wraps_inside_the_history_and_reads_on_any_world() -> void:
	for screen in SCREENS:
		get_window().size = screen
		var panel := ChatPanel.new()
		add_child_autofree(panel)
		panel.setup("Kid", AgeBand.TEEN_PLUS)
		panel.add_line("Night is coming. Build a roof!", &"system")
		panel.add_line("Use the quick chat buttons to talk to friends.", &"error")
		panel.add_line(TYPED, &"bot", "Mossy (bot)")
		panel._team = "room"   # online: a friend's messages in the match's team room
		panel._on_team_message({"channel_id": "room", "id": "m1", "from_id": "u-pip", "from": "Pip", "text": LONG,
			"emote": &"", "mine": false, "time": 0})
		panel._on_team_message({"channel_id": "room", "id": "m2", "from_id": "u-nika", "from": "Nika", "text": "",
			"emote": &"wave", "mine": false, "time": 0})
		panel._team = ""
		panel.add_line("x".repeat(ChatRules.MAX_LENGTH), &"chat", "Pip")   # one long word, through the host's chat
		await wait_process_frames(3)
		var view := Rect2(Vector2.ZERO, panel.get_viewport_rect().size)
		var area := panel._history.get_global_rect()
		assert_gte(_visible_lines(panel), 2, "%s: closed, the newest lines show" % screen)
		assert_not_null(_newest_label(panel), "%s: closed, the newest line shows" % screen)
		for l in panel._labels:
			if l.visible:
				assert_true(area.encloses(l.get_global_rect()), "%s: closed, '%s' stays inside the history" % [screen, l.text.left(16)])
		panel.open()   # a computer: no keyboard
		panel._set_text("ok")
		await wait_process_frames(3)
		area = panel._history.get_global_rect()
		assert_gte(_visible_lines(panel), 5, "%s: open, the lines show" % screen)
		for l in panel._labels:
			if not l.visible:
				continue
			var r := l.get_global_rect()
			assert_true(view.encloses(r), "%s: '%s' is on the screen" % [screen, l.text.left(16)])
			assert_lte(r.end.x, area.end.x + 0.5, "%s: '%s' stays inside the history" % [screen, l.text.left(16)])
			assert_eq(l.get_visible_line_count(), l.get_line_count(), "%s: none of '%s' is cut" % [screen, l.text.left(16)])
			var back := l.get_theme_stylebox("normal") as StyleBoxFlat
			assert_not_null(back, "%s: '%s' has a backing" % [screen, l.text.left(16)])
			if back == null:
				continue
			var ink := l.get_theme_color("font_color")
			for world: Color in [Color.WHITE, Color(0.62, 0.8, 0.95), Color("f7f2e8"), Color.BLACK]:   # snow, sky, sand, a cave
				var under := world.lerp(Color(back.bg_color, 1.0), back.bg_color.a)
				assert_gte(_contrast(ink, under), MIN_CONTRAST, "%s: '%s' reads over %s" % [screen, l.text.left(16), world])
		var shown: Array[Label] = []
		for l in panel._labels:
			if l.visible:
				shown.append(l)
		var n := shown.size()
		assert_string_contains(shown[n - 3].text, "Pip: I found a cave")
		assert_gt(shown[n - 3].get_line_count(), 1, "the long line wraps")
		assert_eq(shown[n - 2].text, "Nika: *Wave*", "an emote shows as its word")
		assert_gt(shown[n - 1].get_line_count(), 1, "one long word wraps too")
		panel.free()
	for kind: StringName in ChatPanel.COLORS:   # every kind of line on its backing, over a white world
		var under := Color.WHITE.lerp(Color(ChatPanel.LINE_BACK, 1.0), ChatPanel.LINE_BACK.a)
		assert_gte(_contrast(ChatPanel.COLORS[kind], under), MIN_CONTRAST, "%s lines read over snow" % kind)


# --- Georgian letters ---

## A font on this computer with every Georgian letter (the test needs one; Android ships Noto Sans Georgian).
func _computer_has_georgian() -> bool:
	for path in OS.get_system_font_path_for_text("sans-serif", GEORGIAN, "ka", "Geor"):
		var f := FontFile.new()
		if f.load_dynamic_font(path) == OK and _covers(f, GEORGIAN):
			return true
	return false


func _covers(font: Font, text: String) -> bool:
	for ch in text:
		if not font.has_char(ch.unicode_at(0)):
			return false
	return true


func test_georgian_letters_have_glyphs_in_the_games_own_fonts() -> void:
	if not _computer_has_georgian():
		pending("no font with Georgian letters on this computer")
		return
	UiKit.theme()
	var panel := ChatPanel.new()
	add_child_autofree(panel)
	panel.setup("Kid", AgeBand.TEEN_PLUS)
	panel.add_line(TYPED, &"chat", "Nika")
	var field_font := panel._field.get_theme_font("font")
	assert_true(_covers(field_font, GEORGIAN), "the chat field draws every Georgian letter itself")
	assert_true(_covers(panel._labels[0].get_theme_font("font"), GEORGIAN), "the chat's lines too")
	assert_true(_covers(ThemeDB.fallback_font, GEORGIAN), "and every other Label, Button and name tag")
	var path: String = UiKit.script_font_paths.get(&"Geor", "")
	assert_true(path.is_absolute_path() and not path.begins_with("res://"),
		"the letters come from the device's own font, never a bundled one (CC0 only): %s" % path)


func test_on_android_the_georgian_font_is_found_by_its_file_too() -> void:
	var files: Array = UiKit.SCRIPT_FONTS[&"Geor"].files
	assert_eq(UiKit.SCRIPT_FONTS[&"Geor"].letters, GEORGIAN, "every letter is checked")
	assert_true(files.has("/system/fonts/NotoSansGeorgian-VF.ttf"), "Android 12 and later")
	assert_true(files.has("/system/fonts/NotoSansGeorgian-Regular.otf"), "older Android")
