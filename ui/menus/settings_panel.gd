class_name SettingsPanel
extends VBoxContainer
## Graphics preset and style, view distance, volume, music volume and the sound effects volume,
## double/triple jump and the MUSIC style (game / classical / mix), FPS counter, Vibration, Reduce motion
## and Song names. Saves to the profile on every change. Fits a 1280 × 720 screen
## (test_settings_panel.gd): add new settings to an existing row rather than a new one.
## GROWN-UPS (beside BACK; M4 Wave 2, agent F) opens the grown-up area behind the parent gate.
## M3 Task 21a: two pages, GAME and HELP ("Read to me" and SIMPLE / CLASSIC controls; owner #52: English only),
## chosen by the buttons beside the title; the last row (BACK, GROWN-UPS) is on both.

signal closed

const ROW_GAP := 16
## The audio pass (owner feedback #31): the MUSIC button's word for each style (MusicPlan); a tap steps on.
const MUSIC_STYLE_WORDS := {"game": "GAME MUSIC", "classical": "CLASSICAL", "mix": "MIX"}
const MUSIC_STYLE_ORDER := ["game", "classical", "mix"]

## The online service the grown-up area uses (default: Session.online_service(); tests set one).
var make_service := Callable()
## Today's minutes of play for the grown-up area (default: Session's PlayClock; tests set one).
var play_minutes := Callable()
var _rows: Array[Control] = []   # the settings themselves, hidden while the grown-ups page shows
## Saves the profile after a change (default: Profile.save(); tests set a no-op: the file is shared).
var saver := Callable()
## M7: the page's install state and its install prompt (default: WebGlue's; tests set their own).
var install_state := Callable()
var request_install := Callable()
var _grownups: Control

var _preset_buttons := {}
var _jump_buttons := {}
var _style_buttons := {}
var _view_label := Label.new()


func _ready() -> void:
	add_theme_constant_override("separation", ROW_GAP)
	var s := Profile.data.settings
	add_child(_header())   # M3 Task 21a: the title and the two pages' buttons

	var presets := HBoxContainer.new()
	presets.add_theme_constant_override("separation", 12)
	presets.add_child(_row_label("Graphics"))
	# P5 (owner #108): a headset offers VR and VR PLUS (its own presets; a phone's mean nothing there), else as before.
	var in_use := GraphicsPreset.vr_preset(str(s.graphics)) if Vr.active() else str(s.graphics)
	for p: String in GraphicsPreset.choices(Vr.active()):
		var b := UiKit.big_button(GraphicsPreset.label(p), Color(), Vector2(170, 76))
		b.toggle_mode = true
		b.button_pressed = in_use == p
		b.pressed.connect(_on_preset.bind(p))
		_preset_buttons[p] = b
		presets.add_child(b)
	add_child(presets)

	var styles := HBoxContainer.new()
	styles.add_theme_constant_override("separation", 12)
	var style_row_label := _row_label("Style")
	style_row_label.custom_minimum_size.x = 0   # the row also holds SIMPLE / CLASSIC (owner #66) and, in a browser, the note
	styles.add_child(style_row_label)
	for st: String in GraphicsPreset.STYLES:
		var b := UiKit.big_button(st.to_upper(), Color(), Vector2(180, 76))
		b.name = "StyleButton_" + st
		b.toggle_mode = true
		b.button_pressed = s.style == st
		b.pressed.connect(_on_style.bind(st))
		_style_buttons[st] = b
		styles.add_child(b)
	# Owner #66: SIMPLE / CLASSIC in the page SETTINGS opens on (menu and pause menu: any time), beside the style (the
	# page is full: 711 of 720 px, so no row of its own).
	var controls_label := _row_label("Controls")
	controls_label.custom_minimum_size.x = 0
	styles.add_child(controls_label)
	var simple_on := bool(s.get("simple_controls", false))
	for simple: bool in [true, false]:
		var b := UiKit.big_button("SIMPLE" if simple else "CLASSIC", Color(), Vector2(180, 76))
		b.name = "SimpleButton" if simple else "ClassicButton"
		b.toggle_mode = true
		b.button_pressed = simple == simple_on
		b.pressed.connect(_on_controls.bind(simple))
		_controls_buttons[simple] = b
		styles.add_child(b)
	add_child(styles)

	var view := HBoxContainer.new()
	view.add_child(_row_label("View distance"))
	var view_slider := _slider(GraphicsPreset.MIN_VIEW_DISTANCE, GraphicsPreset.MAX_VIEW_DISTANCE, 16, s.view_distance)
	view_slider.value_changed.connect(_on_view_distance)
	view.add_child(view_slider)
	_view_label.text = str(s.view_distance)
	_view_label.custom_minimum_size.x = 80
	view.add_child(_view_label)
	add_child(view)

	var vol := HBoxContainer.new()
	vol.add_child(_row_label("Volume"))
	var vol_slider := _slider(0, 100, 5, int(float(s.volume) * 100.0))
	vol_slider.value_changed.connect(func(v: float) -> void: _store("volume", v / 100.0))
	vol.add_child(vol_slider)
	# M2 Task 11: the music's own volume, on the same row (the panel must fit a 720 px screen)
	var music_label := _row_label("Music")
	music_label.custom_minimum_size.x = 120
	music_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vol.add_child(music_label)
	var music_slider := _slider(0, 100, 5, roundi(float(s.music_volume) * 100.0))
	music_slider.name = "MusicSlider"
	music_slider.value_changed.connect(func(v: float) -> void: _store("music_volume", v / 100.0))
	vol.add_child(music_slider)
	# The audio pass: the SOUND EFFECTS volume, on the same row
	var sfx_label := _row_label("Effects")
	sfx_label.custom_minimum_size.x = 130
	sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vol.add_child(sfx_label)
	var sfx_slider := _slider(0, 100, 5, roundi(float(s.get("sfx_volume", 0.8)) * 100.0))
	sfx_slider.name = "SfxSlider"
	sfx_slider.value_changed.connect(func(v: float) -> void: _store("sfx_volume", v / 100.0))
	vol.add_child(sfx_slider)
	vol_slider.custom_minimum_size.x = 200
	music_slider.custom_minimum_size.x = 200
	sfx_slider.custom_minimum_size.x = 200
	add_child(vol)

	var jumps := HBoxContainer.new()
	jumps.add_theme_constant_override("separation", 12)
	jumps.add_child(_row_label("Jumps"))
	for n: int in [2, 3]:
		var b := UiKit.big_button("DOUBLE" if n == 2 else "TRIPLE", Color(), Vector2(200, 76))
		b.toggle_mode = true
		b.button_pressed = int(s.max_jumps) == n
		b.pressed.connect(_on_jumps.bind(n))
		_jump_buttons[n] = b
		jumps.add_child(b)
	# The audio pass (owner feedback #31): GAME MUSIC / CLASSICAL / MIX, one button that steps on
	var style_label := _row_label("Music")
	style_label.custom_minimum_size.x = 130
	style_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	jumps.add_child(style_label)
	var style := str(s.get("music_style", "mix"))
	var music_style := UiKit.big_button(MUSIC_STYLE_WORDS.get(style, "MIX"), UiKit.BLUE, Vector2(250, 76))
	music_style.name = "MusicStyleButton"
	music_style.pressed.connect(func() -> void:
		var next := next_music_style(str(Profile.data.settings.get("music_style", "mix")))
		music_style.text = MUSIC_STYLE_WORDS[next]
		_store("music_style", next))
	jumps.add_child(music_style)
	add_child(jumps)

	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 28)
	var fps := CheckButton.new()
	fps.text = "Show FPS"
	fps.button_pressed = s.show_fps
	fps.toggled.connect(func(on: bool) -> void: _store("show_fps", on))
	toggles.add_child(fps)
	# M2 Task 11 (Feel): the phone buzz and screen shake; Reduce motion (no shake or camera bob, softer flashes)
	var vibration := CheckButton.new()
	vibration.name = "VibrationToggle"
	vibration.text = "Vibration"
	vibration.button_pressed = bool(s.vibration)
	vibration.toggled.connect(func(on: bool) -> void:
		_store("vibration", on)
		Feel.vibrate(60))   # a little buzz to show it is on (nothing when off)
	toggles.add_child(vibration)
	var reduce := CheckButton.new()
	reduce.name = "ReduceMotionToggle"
	reduce.text = "Reduce motion"
	reduce.button_pressed = bool(s.reduce_motion)
	reduce.toggled.connect(func(on: bool) -> void: _store("reduce_motion", on))
	toggles.add_child(reduce)
	# The audio pass: a short "Now playing: <composer> - <piece>" when a classical piece starts
	var names := CheckButton.new()
	names.name = "SongNamesToggle"
	names.text = "Song names"
	names.button_pressed = bool(s.get("song_names", true))
	names.toggled.connect(func(on: bool) -> void: _store("song_names", on))
	toggles.add_child(names)
	add_child(toggles)

	for c in get_children():   # M3 Task 21a: everything so far but the header is the game page
		if c != _head:
			_game_rows.append(c)
	_add_words_page(s)
	_add_block_music(s)   # M3 Task 21c: beside Reduce motion (the last row is full)
	_add_more_music_note()   # M7: a browser before the music pack is in
	_add_realistic_note()   # M7: a browser before the realistic pack is in
	_add_access_page(s)   # M5 Task 1: BUTTONS & TEXT
	_add_vr_page(s)   # owner #101: VR COMFORT, only in a headset
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(260, 84))
	back.pressed.connect(func() -> void: closed.emit())
	var grownups := UiKit.big_button("GROWN-UPS", Color(), Vector2(260, 84))   # M4 F: behind the parent gate
	grownups.pressed.connect(_show_gate)
	var last := HBoxContainer.new()
	last.alignment = BoxContainer.ALIGNMENT_CENTER
	last.add_theme_constant_override("separation", 28)
	last.add_child(back)
	last.add_child(grownups)
	last.add_child(AccountsOverlay.settings_buttons())   # owner #99, #105: LOG OUT and PASSWORD (main menu only; ui/online/accounts_overlay.gd)
	last.add_child(_farm_note_toggle(s))   # M3 Task 10 (the toggles row is full since the audio pass)
	last.add_child(_install_button())   # M7: a browser only (hidden elsewhere: nothing moves on a phone)
	add_child(last)
	for c in get_children():
		_rows.append(c)
	show_page(_page)


# --- M4 F: the grown-up area (spec §5.14, §17.2) behind the parent gate ---

func _show_gate() -> void:
	var gate := GrownUpGate.new()
	gate.passed.connect(_show_grownups)
	gate.cancelled.connect(_back_to_settings)
	_swap_to(gate)


func _show_grownups() -> void:
	var area := GrownUpsPanel.new()
	area.service = make_service.call() if make_service.is_valid() else Session.online_service()
	if play_minutes.is_valid():
		area.play_minutes = play_minutes
	area.closed.connect(_back_to_settings)
	_swap_to(area)


## Owner #79 (spec §25.2): a friend's (class or family) code typed in SETTINGS, once; BACK comes back here.
func _show_code_box() -> void:
	var box := InviteCodeBox.new()
	box.service = make_service.call() if make_service.is_valid() else Session.online_service()
	box.at_start = false
	box.done.connect(func(_r: Dictionary) -> void: _back_to_settings())
	_swap_to(box)


func _swap_to(page: Control) -> void:
	if _grownups:
		remove_child(_grownups)
		_grownups.queue_free()
	for c in _rows:
		c.visible = false
	_grownups = page
	add_child(page)


func _back_to_settings() -> void:
	if _grownups:
		remove_child(_grownups)
		_grownups.queue_free()
		_grownups = null
	for c in _rows:
		c.visible = true
	show_page(_page)   # M3 Task 21a: only the page that was open


func _on_preset(preset: String) -> void:
	for p: String in _preset_buttons:
		(_preset_buttons[p] as Button).set_pressed_no_signal(p == preset)
	_store("graphics", preset)


func _on_style(st: String) -> void:
	for k: String in _style_buttons:
		(_style_buttons[k] as Button).set_pressed_no_signal(k == st)
	_store("style", st)
	_show_realistic_note()


func _on_jumps(n: int) -> void:
	for k: int in _jump_buttons:
		(_jump_buttons[k] as Button).set_pressed_no_signal(k == n)
	_store("max_jumps", n)


func _on_view_distance(v: float) -> void:
	_view_label.text = str(int(v))
	_store("view_distance", int(v))


## The style after `style` (GAME MUSIC -> CLASSICAL -> MIX -> GAME MUSIC; anything else -> GAME MUSIC).
static func next_music_style(style: String) -> String:
	var i := MUSIC_STYLE_ORDER.find(style)
	return MUSIC_STYLE_ORDER[(i + 1) % MUSIC_STYLE_ORDER.size()] if i >= 0 else MUSIC_STYLE_ORDER[0]


func _store(key: String, value: Variant) -> void:
	Profile.data.settings[key] = value
	if saver.is_valid():   # M3 Task 21a: tests never write the shared profile file
		saver.call()
	else:
		Profile.save()
	Game.apply_settings()


func _row_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size.x = 240
	return l


func _slider(lo: int, hi: int, step: int, value: int) -> HSlider:
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(360, 48)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return s

# --- M3 Task 10: the Gold Farm's "Your farm is full!" note (spec §5.6) ---

## Off by default; for an under-13 child only a grown-up turns it on (the parent gate first).
func _farm_note_toggle(s: Dictionary) -> CheckButton:
	var note := CheckButton.new()
	note.name = "FarmNoteToggle"
	note.text = "Farm note"
	note.button_pressed = FarmNotifyRules.wanted(s)
	note.toggled.connect(_on_farm_note.bind(note))
	return note


func _on_farm_note(on: bool, button: CheckButton) -> void:
	if on and AgeBand.effective(Profile.data.age_band) == AgeBand.UNDER_13:
		button.set_pressed_no_signal(false)
		var gate := GrownUpGate.new()
		gate.passed.connect(func() -> void:
			_back_to_settings()
			button.set_pressed_no_signal(true)
			_store("farm_note", true))
		gate.cancelled.connect(_back_to_settings)
		_swap_to(gate)
		return
	_store("farm_note", on)

# --- M3 Task 21c: block music ---

## Block music goes in HELP's Comfort row, beside Reduce motion: the last row and the game page's toggles are full.
func _add_block_music(s: Dictionary) -> void:
	var reduce := find_child("ReduceMotionToggle", true, false)
	var row: Node = reduce.get_parent() if reduce else null
	if row == null:
		row = _game_rows[_game_rows.size() - 1]
	row.add_child(_block_music_toggle(s))


## "Block music": every placed block sings a note of the pentatonic scale (BuildMelody); off, the plain pop.
func _block_music_toggle(s: Dictionary) -> CheckButton:
	var music := CheckButton.new()
	music.name = "BlockMusicToggle"
	music.text = "Block music"
	music.button_pressed = bool(s.get("build_notes", true))
	music.toggled.connect(func(on: bool) -> void: _store("build_notes", on))
	return music

# --- M3 Task 21a: HELP ("Read to me", Simple controls, comfort; owner #52 took its LANGUAGE out: English only) ---

const GAME := &"game"
const WORDS := &"words"

var _page: StringName = GAME
var _head: Control
var _game_rows: Array[Control] = []
var _words_rows: Array[Control] = []
var _page_buttons := {}
const PAGE_SHUT := Color("2b3553")   # the page button of the page that is not open
var _controls_buttons := {}


## Shows the GAME page or the HELP page (the header and the last row stay).
func show_page(page: StringName) -> void:
	_page = page
	for c in _game_rows:
		c.visible = page == GAME
	for c in _words_rows:
		c.visible = page == WORDS
	for c in _access_rows:   # M5 Task 1
		c.visible = page == ACCESS
	for c in _vr_rows:   # owner #101
		c.visible = page == VR
	for p: StringName in _page_buttons:
		(_page_buttons[p] as Button).set_pressed_no_signal(p == page)


func _header() -> Control:
	var row := HBoxContainer.new()
	row.name = "Header"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	row.add_child(ReadAloud.with_speaker(UiKit.title("Settings", 44), self))
	var pages: Array[StringName] = [GAME, WORDS, ACCESS]
	if Vr.active():
		pages.append(VR)   # owner #101: VR COMFORT, only in a headset
	for p: StringName in pages:   # M5 Task 1: BUTTONS & TEXT
		var b := UiKit.big_button(PAGE_WORDS[p], UiKit.BLUE, Vector2(200, 60))
		b.name = "Page_" + String(p)
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 22)
		# The open page's button is bright blue, the other one dark, under a finger too (touch leaves "hover"; seen on
		# the emulator 2026-09-25: both were the same blue). Thin boxes: the page must fit 720 px.
		b.add_theme_stylebox_override("normal", UiKit.box(PAGE_SHUT, 18, 10))
		b.add_theme_stylebox_override("hover", UiKit.box(PAGE_SHUT.lightened(0.08), 18, 10))
		b.add_theme_stylebox_override("pressed", UiKit.box(UiKit.BLUE.lightened(0.1), 18, 10))
		b.add_theme_stylebox_override("hover_pressed", UiKit.box(UiKit.BLUE.lightened(0.1), 18, 10))
		b.pressed.connect(show_page.bind(p))
		_page_buttons[p] = b
		row.add_child(b)
	_head = row
	return row


func _add_words_page(s: Dictionary) -> void:
	var read := HBoxContainer.new()
	read.add_theme_constant_override("separation", 18)
	read.add_child(_row_label("Read aloud"))
	var toggle := CheckButton.new()
	toggle.name = "ReadToMeToggle"
	toggle.text = "Read to me"
	toggle.button_pressed = bool(s.get("read_to_me", false))
	toggle.toggled.connect(func(on: bool) -> void: _store("read_to_me", on))
	read.add_child(toggle)
	read.add_child(ReadAloud.button(func() -> String: return "Hello! I can read the game's words to you.", 64.0))
	var no_voice := Label.new()
	no_voice.name = "NoVoice"
	no_voice.text = "This device has no voice to read with."
	no_voice.add_theme_font_size_override("font_size", 22)
	no_voice.visible = not ReadAloud.available()
	read.add_child(no_voice)
	_add_words_row(read)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	controls.add_child(_row_label("Lessons"))
	controls.add_child(_pip_lessons_button())   # M3 Task 15: PIP'S LESSONS (SIMPLE / CLASSIC: the GAME page, owner #66)
	# Owner #90: how fast a game controller's right stick looks round (GamepadRules.LOOK_SPEEDS), on this row (the page
	# must fit 720 px)
	var pad_look := _choices("Controller look", "pad_look", "PadLook_", GamepadRules.LOOK_SPEED_ORDER,
		{"slow": "SLOW", "normal": "NORMAL", "fast": "FAST"}, str(s.get("pad_look", "normal")))
	for c in pad_look.get_children():
		pad_look.remove_child(c)
		controls.add_child(c)
		if c is Button:
			(c as Button).custom_minimum_size = Vector2(140, 76)
			(c as Button).add_theme_font_size_override("font_size", 22)
		elif c is Label:
			(c as Label).custom_minimum_size.x = 0
	pad_look.free()
	_add_words_row(controls)
	var about := Label.new()
	about.text = "Controls (on the GAME page): SIMPLE hops you up steps and over holes, the camera follows you, and only " \
		+ "the buttons you need show. CLASSIC shows every button, and you move the camera."
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size.x = 980
	about.add_theme_font_size_override("font_size", 24)
	_add_words_row(about)
	if not Profile.data.invite.used:   # owner #79: a friend's code, once (the start offered it too)
		var friends := HBoxContainer.new()
		friends.add_theme_constant_override("separation", 18)
		friends.add_child(_row_label("Friends"))
		var code := UiKit.big_button("FRIEND'S CODE", OnlineUi.PURPLE, Vector2(300, 76))
		code.name = "FriendsCode"
		code.pressed.connect(_show_code_box)
		friends.add_child(code)
		_add_words_row(friends)
	var comfort := HBoxContainer.new()   # Reduce motion lives here: the game page's toggle row is full
	comfort.add_theme_constant_override("separation", 28)
	comfort.add_child(_row_label("Comfort"))
	var reduce := find_child("ReduceMotionToggle", true, false)
	if reduce:
		reduce.reparent(comfort)
	_add_words_row(comfort)


func _add_words_row(c: Control) -> void:
	add_child(c)
	_words_rows.append(c)


func _on_controls(simple: bool) -> void:
	for k: bool in _controls_buttons:
		(_controls_buttons[k] as Button).set_pressed_no_signal(k == simple)
	Profile.data.settings.simple_asked = true   # chosen here: the first-launch card is not needed
	_store("simple_controls", simple)

# --- M3 Task 15: PIP'S LESSONS (the tutorial with Pip again) ---

const PIP_LESSONS := "PIP'S LESSONS"
const PIP_COMING := "PIP IS COMING!"
const PIP_COMING_WORDS := "Pip will meet you in your next Survivor game!"


## The next solo Survivor game plays the tutorial again (from the pause menu: as soon as the game goes on). No second
## reward (TutorialRules.finish).
func _pip_lessons_button() -> Button:
	var b := UiKit.big_button(PIP_LESSONS, UiKit.GREEN, Vector2(250, 76))
	b.name = "PipLessonsButton"
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(func() -> void:
		TutorialRules.ask_replay(Profile.data.tutorial)
		if saver.is_valid():
			saver.call()
		else:
			Profile.save()
		b.text = PIP_COMING
		b.disabled = true
		ReadAloud.auto(PIP_COMING_WORDS))
	return b


# --- M5 Task 1: BUTTONS & TEXT (spec §15.1a) ---

const ACCESS := &"access"
const VR := &"vr"   # owner #101
const PAGE_WORDS := {GAME: "GAME", WORDS: "HELP", ACCESS: "BUTTONS & TEXT", VR: VrWords.PAGE}
const SIZE_WORDS := {"normal": "NORMAL", "big": "BIG", "bigger": "BIGGER"}
## MOVE BUTTONS' layer: over the menus, the pause menu and Feel's hurt flash (90).
const EDITOR_LAYER := 120

var _access_rows: Array[Control] = []
var _choice_rows := {}   # setting -> {value: its button}


## BUTTON SIZE, HANDS and MOVE BUTTONS, TEXT SIZE and Sound captions, and a line about them.
func _add_access_page(s: Dictionary) -> void:
	var sizes := _choices("Button size", "button_size", "ButtonSize_", ["normal", "big", "bigger"], SIZE_WORDS,
		str(s.get("button_size", "normal")))
	_add_access_row(sizes)
	var hands := _choices("Hands", "left_handed", "Hand_", [false, true], {false: "RIGHT HAND", true: "LEFT HAND"},
		bool(s.get("left_handed", false)), ["right", "left"])
	var move := UiKit.big_button("MOVE BUTTONS", UiKit.BLUE, Vector2(260, 76))
	move.name = "MoveButtons"
	move.pressed.connect(open_move_buttons)
	hands.add_child(move)
	_add_access_row(hands)
	var text := _choices("Text size", "text_size", "TextSize_", ["normal", "big"], SIZE_WORDS,
		str(s.get("text_size", "normal")))
	var captions := CheckButton.new()
	captions.name = "CaptionsToggle"
	captions.text = "Sound captions"
	captions.button_pressed = bool(s.get("captions", true))
	captions.toggled.connect(func(on: bool) -> void: _store("captions", on))
	text.add_child(captions)
	_add_access_row(text)
	var about := Label.new()
	about.text = "BIG and BIGGER grow JUMP, ATTACK, CROUCH and the stick. LEFT HAND puts them on the other side. " \
		+ "Sound captions show a little picture when a monster, a boss or the night is coming."
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size.x = 980
	about.add_theme_font_size_override("font_size", 24)
	_add_access_row(about)


## Owner #101 (VR on the Meta Quest): VR COMFORT (VrComfortPage: turning, the comfort view, text size, RECENTER), a page
## of its own that only a headset shows (nothing changes on a phone or a PC).
var _vr_rows: Array[Control] = []


func _add_vr_page(s: Dictionary) -> void:
	if not Vr.active():
		return
	var page := VrComfortPage.new(s)
	page.store = _store
	add_child(page)
	_vr_rows.append(page)


## A row of big toggle buttons, one per value, the chosen one lit; a tap stores the value.
func _choices(label: String, key: String, prefix: String, values: Array, words: Dictionary, chosen: Variant,
		ids: Array = []) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_row_label(label))
	var buttons := {}
	for i in values.size():
		var v: Variant = values[i]
		var b := UiKit.big_button(words[v], Color(), Vector2(200, 76))
		b.name = prefix + (str(ids[i]) if i < ids.size() else str(v))
		b.toggle_mode = true
		b.button_pressed = v == chosen
		b.pressed.connect(_on_choice.bind(key, v))
		buttons[v] = b
		row.add_child(b)
	_choice_rows[key] = buttons
	return row


func _on_choice(key: String, value: Variant) -> void:
	var buttons: Dictionary = _choice_rows[key]
	for v: Variant in buttons:
		(buttons[v] as Button).set_pressed_no_signal(v == value)
	_store(key, value)


func _add_access_row(c: Control) -> void:
	add_child(c)
	_access_rows.append(c)


## MOVE BUTTONS: the editor over everything (it works while the game is paused); DONE saves the profile.
func open_move_buttons() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HudEditorLayer"
	layer.layer = EDITOR_LAYER
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var editor := HudEditor.new()
	editor.name = "HudEditor"
	editor.saver = func() -> void:
		if saver.is_valid():
			saver.call()
		else:
			Profile.save()
		Game.apply_settings()
	editor.closed.connect(layer.queue_free)
	tree_exiting.connect(editor.cancel, CONNECT_ONE_SHOT)   # M5 Task 6 review: never left over the next screen
	layer.add_child(editor)
	UiLayers.route(layer, get_tree().root)   # owner #101: in VR on the panel
	PadFocus.take(editor)   # owner #90: a game controller's focus stays on the editor's buttons, not the page under it

# --- M7 (owner 2026-09-28): ADD TO THIS DEVICE, whenever the page can add the game (InstallOffer) ---

## The main menu's card does the same once in a while; this one is always here for a child who looks for it, also
## after 3 NOT NOWs. It hides once there is nothing more to add (never a dead button).
func _install_button() -> Button:
	var b := UiKit.big_button("ADD TO THIS DEVICE", UiKit.GREEN, Vector2(300, 84))
	b.name = "InstallButton"
	b.add_theme_font_size_override("font_size", 24)
	b.visible = _can_install()
	b.pressed.connect(func() -> void:
		if request_install.is_valid():
			request_install.call()
		else:
			WebGlue.request_install()   # right from the tap: browsers allow the prompt only just after one
		b.visible = _can_install())
	return b


func _can_install() -> bool:
	var state: Dictionary = install_state.call() if install_state.is_valid() else WebGlue.install_state()
	return InstallOffer.can_offer(PlatformRules.current(), state)


# --- M7: the web build's music pack (WebContent) ---

const MORE_MUSIC := "More music is on its way…"
## M7: a browser before its realistic pack is in (RealisticPack), beside the style buttons while REALISTIC is chosen.
const REALISTIC_COMING := "The realistic pictures are on their way…"


## In a browser the classical pieces come a little after the start (Music.more_music_coming): a small line beside Song
## names says so, and goes when they are in (Music.more_music_arrived). Nothing when all the music is here.
func _add_more_music_note() -> void:
	var names := find_child("SongNamesToggle", true, false)
	if names == null or not Music.more_music_coming():
		return
	var note := Label.new()
	note.name = "MoreMusicNote"
	note.text = MORE_MUSIC
	note.add_theme_font_size_override("font_size", 20)
	note.modulate = Color(1.0, 1.0, 1.0, 0.75)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	names.get_parent().add_child(note)
	Music.more_music_arrived.connect(note.hide)


## In a browser the REALISTIC style's pictures come a little after the start (RealisticPack): while REALISTIC is chosen
## and they are not in, a small line beside the style buttons says so (the blocks keep the pixel pictures meanwhile),
## and goes when they land. Nothing when they are here (phones, computers, a browser after the pack).
func _add_realistic_note() -> void:
	if not _style_buttons.has("realistic") or RealisticPack.present():
		return
	var note := Label.new()
	note.name = "RealisticNote"
	note.text = REALISTIC_COMING
	note.add_theme_font_size_override("font_size", 18)
	note.modulate = Color(1.0, 1.0, 1.0, 0.75)
	note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # a narrow block beside REALISTIC: the row also holds the controls
	note.custom_minimum_size.x = 150
	var realistic := _style_buttons.realistic as Control
	realistic.get_parent().add_child(note)
	realistic.get_parent().move_child(note, realistic.get_index() + 1)
	add_to_group(RealisticPack.GROUP)
	_show_realistic_note()


func _show_realistic_note() -> void:
	var note := find_child("RealisticNote", true, false) as Label
	if note:
		note.visible = str(Profile.data.settings.style) == "realistic" and not RealisticPack.present()


## RealisticPack.on_pack_loaded: the pictures are in.
func realistic_pictures_arrived() -> void:
	_show_realistic_note()
