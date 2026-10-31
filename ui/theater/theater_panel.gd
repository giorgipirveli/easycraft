class_name TheaterPanel
extends Control
## The Shorts Theater's screen (spec §5.12, §14.12, research H6; M3 Task 17; owner #89 "finish tv shows"). In
## the middle of the landscape screen, never over the world's corners (the HUD's thumbs stay):
##
##   the channels as big picture tabs (EasyCraft TV first)
##   the video's title, and CLOSE (stops the video)
##   BACK | the player, 16:9 | NEXT
##   Grown-ups           | EXIT
##   the channel's videos as cards with their titles and makers, a page at a time
##
## Nothing is ever drawn over the player. On Android the player is YouTube's embedded player in the
## EasyCraftWebView plugin, in the browser the page's own block (TheaterWebPlayer): either is `backend`, placed
## exactly over the screen area. Desktop, headless and tests draw `TheaterStill` there instead. A video starts when
## the child picks it (a tab, a card, NEXT, BACK, the poster's PLAY); walking in shows it still, and its end lights
## NEXT up (TheaterRules). While a video is on the screen, the game holds its own sound.
##
## Only when no video plays, cards show in the middle: "Coming soon", "Ask a grown-up" (a child's Theater is off
## until a grown-up opens it, while the age rules are on), the parent gate (three wrong answers rest it for a
## minute: ParentGate) and switch, and the end card ("That's the show!" with a picture of the world, and two equal
## choices). Mouse and keys on a PC (Esc leaves, N next, B back; opening frees the mouse), touch on a phone.
##
## profile / save_profile / backend / is_mobile / live / picture_provider can be swapped (tests,
## TheaterDirector). No gold, points or anything else is ever given for watching.
##
## Owner #94 (spec §5.12b): EasyCraft Shorts. A SHORTS tab first among the tabs; the Theater opens on it
## (`opens_on_shorts`) and shows ShortsView under the tabs instead of the 16:9 player: our own short learning animations,
## swiped up and down (no internet, no player plugin: they play on every phone, even where the channels say "Coming
## soon"). The grown-ups' switch covers it with the rest. LEARN IT on a School Short opens the School's unit over the
## Theater (ShortsSchool); on the Mission Board or the Star Map it leaves the Theater and asks for it (learn_requested).
## ↑ / ↓ (and PageUp / PageDown, N / B) move through the Shorts on a PC, Space plays and pauses.

signal exit_requested
## Owner #94: LEARN IT asks for the Mission Board ({board: true}) or the Star Map ({star_map: true}); the sandbox opens it.
signal learn_requested(link: Dictionary)
## The view under the tabs changed (the Shorts or the channels): the HUD tucks the buttons under it again.
signal layout_changed

## The layout in the 1280 × 720 design space, relative to the top centre of the screen.
const WIDTH := 780.0
const TABS_TOP := 8.0
const TAB_H := 88.0
const TAB_GAP := 6.0      # owner #94: nine tabs (SHORTS and the eight channels) keep 80 px each
const TAB_MAX_W := 120.0
const HEAD_TOP := 104.0
const HEAD_H := 44.0
const CLOSE_W := 150.0
const SCREEN_TOP := 152.0
const SCREEN_SIZE := Vector2(480, 270)   # 16:9, YouTube's own shape
const SIDE_GAP := 10.0
const SIDE_WIDTH := 140.0
const SIDE_BUTTON_H := 130.0
const STRIP_TOP := 430.0
const STRIP_H := 190.0
const CARDS := 4
const CARD_GAP := 10.0
const ARROW_W := 60.0
const MAX_TYPED := 4
const POLL_SECONDS := 0.25
const MASTER_BUS := 0

const VIEW_CLOSED := &"closed"
const VIEW_PLAY := &"play"
const VIEW_END_CARD := &"end_card"
const VIEW_ASK_PARENT := &"ask_parent"
const VIEW_COMING_SOON := &"coming_soon"
const VIEW_EMPTY := &"empty"
const VIEW_GATE := &"gate"
const VIEW_SWITCH := &"switch"
const VIEW_SHORTS := &"shorts"   # owner #94
## Owner #101: in a headset the TV (an Android view, the page's player) is not in the VR frame: its sign (VrWords).
const VIEW_VR_TV := &"vr_tv"

## Card buttons (card_button(id)).
const GROWN_UPS := &"grown_ups"
const TURN_ON := &"turn_on"
const TURN_OFF := &"turn_off"
const BACK_TO_WORLD := &"back_to_world"
const MORE_SHOWS := &"more_shows"
const WATCH_SHORTS := &"watch_shorts"   # owner #101: the TV's sign in VR

const CANT_PLAY := "This one can't play here. Try NEXT!"

var list: Dictionary = {}
var profile: ProfileData                 # default: Profile.data
var save_profile := Callable()           # default: Profile.save
var is_mobile := not PlatformRules.shows_stand_ins(PlatformRules.current())   # M7: a browser has no webview either
## The check build ("Android Theater" preset, feature `theater_live`) plays the sample list.
var live := OS.has_feature("theater_live")
var backend: Object = null               # a TheaterWebView or TheaterWebPlayer, or null for the placeholder
var picture_provider := Callable()       # () -> Texture2D: a picture of the world for the end card
## A PC: the keys show on their buttons (Esc, N, B), and opening frees the mouse.
var keyboard := PlatformRules.keyboard_first(PlatformRules.current())
var frees_mouse := PlatformRules.captures_mouse(PlatformRules.current())
## Owner #94: the Theater opens on its SHORTS tab (tests of the channels set it false).
var opens_on_shorts := true
var shorts := ShortsView.new()
var shorts_tab: ShortsTab
var school := ShortsSchool.new()

var view: StringName = VIEW_CLOSED
var session: TheaterSession
var gate_question: Dictionary = {}
var msec := Callable()   # () -> int msec for the gate's rest; default Time.get_ticks_msec (tests)
## A video is on the screen (the backend's player), not stopped.
var player_on := false
## The video on the screen ended: NEXT lights up (nothing starts by itself).
var next_glows := false
## The page of cards under the player (CARDS a page).
var page := 0

var still := TheaterStill.new()
var title_label := Label.new()
var card_label := Label.new()
var next_button: Button
var prev_button: Button
var exit_button: Button
var close_button: Button
var grownups_button: Button
var page_prev_button: Button
var page_next_button: Button
var channel_buttons: Array[Button] = []   # the tabs
var video_cards: Array[VideoCard] = []
var pad_buttons: Dictionary = {}

var _tabs := HBoxContainer.new()
var _frame := Panel.new()
var _screen := Control.new()
var _poster := Button.new()
var _card_frame := Panel.new()
var _card := VBoxContainer.new()
var _card_box := VBoxContainer.new()
var _card_buttons: Dictionary = {}
var _picture := TextureRect.new()
var _entry := Label.new()
var _left := VBoxContainer.new()
var _right := VBoxContainer.new()
var _strip := HBoxContainer.new()
var _typed := ""
var _covered := false
var _connected: Object = null
var _rng := RandomNumberGenerator.new()
var _shown_wait := -1   # the seconds the gate's rest line shows (-1: not resting)
var _poll_wait := 0.0
var _holding_sound := false
var _sound_was_muted := false
var _next_normal: StyleBox


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_rng.randomize()
	set_process(false)

	_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.add_theme_constant_override("separation", int(TAB_GAP))
	_tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_center(_tabs, Rect2(Vector2(-WIDTH * 0.5, TABS_TOP), Vector2(WIDTH, TAB_H)))
	add_child(_tabs)

	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_center(title_label, Rect2(Vector2(-SCREEN_SIZE.x * 0.5 + 4, HEAD_TOP), Vector2(SCREEN_SIZE.x - CLOSE_W - 12, HEAD_H)))
	add_child(title_label)
	close_button = UiKit.big_button("CLOSE", UiKit.RED, Vector2(CLOSE_W, HEAD_H))
	close_button.icon = _icon(&"exit")
	close_button.expand_icon = false
	close_button.add_theme_font_size_override("font_size", 20)
	close_button.add_theme_constant_override("icon_max_width", 26)
	for state: String in ["normal", "hover", "pressed"]:   # slim: the header is one line
		var c := UiKit.RED.lightened(0.12) if state == "hover" else (UiKit.RED.darkened(0.15) if state == "pressed" else UiKit.RED)
		close_button.add_theme_stylebox_override(state, UiKit.box(c, 12, 6))
	close_button.pressed.connect(_stop_video)
	close_button.visible = false
	_place_center(close_button, Rect2(Vector2(SCREEN_SIZE.x * 0.5 - CLOSE_W, HEAD_TOP), Vector2(CLOSE_W, HEAD_H)))
	add_child(close_button)

	var frame_box := UiKit.box(Color(0.05, 0.05, 0.09, 0.97), 16, 0)
	frame_box.border_color = Color("7b4bd6")
	frame_box.set_border_width_all(6)
	_frame.add_theme_stylebox_override("panel", frame_box)
	_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_place_center(_frame, Rect2(Vector2(-SCREEN_SIZE.x * 0.5 - 6, SCREEN_TOP - 6), SCREEN_SIZE + Vector2(12, 12)))
	add_child(_frame)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.clip_contents = true
	_place_center(_screen, Rect2(Vector2(-SCREEN_SIZE.x * 0.5, SCREEN_TOP), SCREEN_SIZE))
	add_child(_screen)
	still.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(still)
	_poster.flat = true
	_poster.focus_mode = Control.FOCUS_NONE
	_poster.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_poster.tooltip_text = "Play"
	_poster.visible = false
	_poster.pressed.connect(_play_again)
	_screen.add_child(_poster)

	var column := Vector2(SIDE_WIDTH, SCREEN_SIZE.y)
	_place_center(_left, Rect2(Vector2(-SCREEN_SIZE.x * 0.5 - SIDE_GAP - SIDE_WIDTH, SCREEN_TOP), column))
	_place_center(_right, Rect2(Vector2(SCREEN_SIZE.x * 0.5 + SIDE_GAP, SCREEN_TOP), column))
	for c: VBoxContainer in [_left, _right]:
		c.add_theme_constant_override("separation", 10)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
	prev_button = _side_button("BACK", &"back", UiKit.BLUE, SIDE_BUTTON_H, "B")
	prev_button.pressed.connect(_on_prev)
	_left.add_child(prev_button)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left.add_child(gap)
	grownups_button = UiKit.big_button("Grown-ups", Color(), Vector2(SIDE_WIDTH, 56))
	grownups_button.add_theme_font_size_override("font_size", 20)
	grownups_button.pressed.connect(_show_gate)
	_left.add_child(grownups_button)
	next_button = _side_button("NEXT", &"next", UiKit.GREEN, SIDE_BUTTON_H, "N")
	next_button.pressed.connect(_on_next)
	_next_normal = next_button.get_theme_stylebox("normal")
	exit_button = _side_button("EXIT", &"exit", UiKit.RED, SIDE_BUTTON_H, "Esc")
	exit_button.pressed.connect(_exit)
	_right.add_child(next_button)
	_right.add_child(exit_button)

	_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	_strip.add_theme_constant_override("separation", int(CARD_GAP))
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_center(_strip, Rect2(Vector2(-WIDTH * 0.5, STRIP_TOP), Vector2(WIDTH, STRIP_H)))
	add_child(_strip)
	page_prev_button = _arrow_button(&"back")
	page_prev_button.pressed.connect(_turn_page.bind(-1))
	_strip.add_child(page_prev_button)
	var card_w := floorf((WIDTH - 2.0 * (ARROW_W + CARD_GAP) - (CARDS - 1) * CARD_GAP) / CARDS)
	for i in CARDS:
		var card := VideoCard.new(Vector2(card_w, STRIP_H))
		card.pressed.connect(_on_card.bind(i))
		video_cards.append(card)
		_strip.add_child(card)
	page_next_button = _arrow_button(&"next")
	page_next_button.pressed.connect(_turn_page.bind(1))
	_strip.add_child(page_next_button)

	var card_frame_box := UiKit.box(Color(0.05, 0.05, 0.09, 0.97), 22, 0)
	card_frame_box.border_color = Color("7b4bd6")
	card_frame_box.set_border_width_all(6)
	_card_frame.add_theme_stylebox_override("panel", card_frame_box)
	_card_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_place_center(_card_frame, Rect2(Vector2(-SCREEN_SIZE.x * 0.5, HEAD_TOP), Vector2(SCREEN_SIZE.x, STRIP_TOP + STRIP_H - HEAD_TOP)))
	_card_frame.visible = false
	add_child(_card_frame)
	_build_card()
	shorts_tab = ShortsTab.new(Vector2(TAB_MAX_W, TAB_H))
	_style_tab(shorts_tab, ShortsTab.COLOUR)
	shorts_tab.pressed.connect(_show_shorts)
	shorts_tab.visible = false
	_tabs.add_child(shorts_tab)
	shorts.visible = false
	_place_center(shorts, Rect2(Vector2(-WIDTH * 0.5, HEAD_TOP), ShortsView.SIZE))
	shorts.learn_requested.connect(_on_learn)
	shorts.exit_requested.connect(_exit)
	shorts.grown_ups_requested.connect(_show_gate)
	shorts.layout_changed.connect(func() -> void: layout_changed.emit())
	add_child(shorts)
	add_child(school)
	get_viewport().size_changed.connect(_on_viewport_resized)


## The screen area in canvas coordinates.
func screen_rect() -> Rect2:
	return _screen.get_global_rect()


## Where the cards (messages, the gate, the end card) show, in canvas coordinates.
func card_rect() -> Rect2:
	return _card_frame.get_global_rect()


## The screen area in window pixels, where the player goes.
func pixel_rect() -> Rect2i:
	var xf := get_viewport().get_final_transform() * _screen.get_global_transform_with_canvas()
	return TheaterRules.pixel_rect(Rect2(Vector2.ZERO, _screen.size), xf)


## CLOSE in window pixels (the browser's player puts its own CLOSE there).
func close_pixel_rect() -> Rect2i:
	var xf := get_viewport().get_final_transform() * close_button.get_global_transform_with_canvas()
	return TheaterRules.pixel_rect(Rect2(Vector2.ZERO, close_button.size), xf)


## What the HUD's look-and-build layer must leave alone (it reads touches before the GUI does).
func blockers() -> Array[Control]:
	return [_tabs, title_label, close_button, _frame, _screen, _left, _right, _strip, _card_frame, shorts, school]


func is_open() -> bool:
	return view != VIEW_CLOSED


func open() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	_connect_backend()
	visible = true
	_covered = false
	if frees_mouse:   # a PC: click the buttons (a click on the world looks around again)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start()


func close() -> void:
	if view == VIEW_CLOSED:
		return
	if backend:
		backend.close()
	player_on = false
	_hold_sound(false)
	shorts.leave()
	school.close()
	if session:
		session.close()
	view = VIEW_CLOSED
	visible = false
	set_process(false)


## A menu (pause, block palette, chat) is over the middle of the screen: the player is a native view (Android)
## or a page element (the browser) above the game, so it has to step aside, and the game's sound comes back.
func set_covered(covered: bool) -> void:
	if covered == _covered:
		return
	_covered = covered
	if view == VIEW_SHORTS:   # owner #94: a menu over the Shorts pauses them
		shorts.set_covered(covered)
	if backend and view == VIEW_PLAY and player_on:
		if covered:
			backend.hide()
		else:
			backend.reveal()
		_hold_sound(not covered)


func card_button(id: StringName) -> Button:
	var b: Variant = _card_buttons.get(id)
	if b == null or not is_instance_valid(b) or not (b as Button).is_visible_in_tree():
		return null
	return b


func _exit_tree() -> void:
	_hold_sound(false)


# --- Views -------------------------------------------------------------------------------------

## The band the rules use: the player's own while the age rules are on, 13+ while they are off (AgeBand).
func _band() -> StringName:
	return AgeBand.effective(profile.age_band)


func _start() -> void:
	var kind := TheaterRules.screen(list, _band(), profile.theater_switch, is_mobile, backend != null, live)
	_set_channels([])
	session = null
	# Owner #94: the Shorts are ours and need no player, so they play wherever the Theater is open (not behind the
	# grown-ups' switch, not with the kill-switch).
	shorts_tab.visible = kind in [TheaterRules.SCREEN_PLAY, TheaterRules.SCREEN_COMING_SOON, TheaterRules.SCREEN_EMPTY]
	if shorts_tab.visible and kind == TheaterRules.SCREEN_PLAY:
		session = TheaterSession.new(list, _band())
		_set_channels(session.channels)
	if shorts_tab.visible and opens_on_shorts:
		_show_shorts()
		return
	match kind:
		TheaterRules.SCREEN_PLAY:
			_show_current(TheaterRules.STARTS_ON_OPEN)
		TheaterRules.SCREEN_ASK_PARENT:
			_show_card(VIEW_ASK_PARENT, "The Theater is closed.\nAsk a grown-up to open it!", [[GROWN_UPS, "GROWN-UPS"]])
		TheaterRules.SCREEN_COMING_SOON:
			_show_card(VIEW_COMING_SOON, "Coming soon!\nShows are on their way in an update.", [])
		TheaterRules.SCREEN_EMPTY:
			_show_card(VIEW_EMPTY, "No shows for you right now.", [])
		_:
			visible = false
			view = VIEW_CLOSED


## The session's video on the screen: with a backend its player (`autoplay`: the child picked it), else the still.
func _show_current(autoplay: bool) -> void:
	if Vr.active():   # owner #101: the TV plays on a phone or tablet; the Shorts play here
		_show_card(VIEW_VR_TV, VrWords.TV_SIGN + "\n" + VrWords.TV_SHORTS,
			[[WATCH_SHORTS, VrWords.WATCH_SHORTS], [BACK_TO_WORLD, "BACK TO MY WORLD"]])
		return
	_leave_shorts()
	var v := session.current()
	view = VIEW_PLAY
	_show_play_parts(true)
	title_label.text = v.title
	page = floori(float(v.index) / CARDS)
	_glow_next(false)
	if backend:
		_play(v, autoplay)
	else:
		still.visible = true
		still.show_video(v)
		_poster.visible = false
	_refresh_strip()
	_refresh_buttons()


func _play(v: Dictionary, autoplay: bool) -> void:
	still.visible = false
	_poster.visible = false
	close_button.visible = true
	backend.play(v, autoplay, pixel_rect(), close_pixel_rect())
	player_on = true
	_hold_sound(not _covered)
	_poll_wait = POLL_SECONDS
	set_process(true)


## CLOSE (the game's, or the browser page's): the video stops and its poster waits; PLAY on it starts it again.
func _stop_video() -> void:
	if not player_on:
		return
	if backend:
		backend.close()
	player_on = false
	close_button.visible = false
	_hold_sound(false)
	if view == VIEW_PLAY:
		still.visible = true
		still.show_video(session.current())
		_poster.visible = true


func _play_again() -> void:
	if view == VIEW_PLAY and backend and not player_on:
		_play(session.current(), TheaterRules.PICKED_VIDEO_STARTS)


func _after_move() -> void:
	if session.state == TheaterSession.PLAYING:
		_show_current(TheaterRules.PICKED_VIDEO_STARTS)
	elif session.state == TheaterSession.END_CARD:
		_show_end_card()


func _show_end_card() -> void:
	var picture: Texture2D = picture_provider.call() if picture_provider.is_valid() else null
	var text := "That's the show!" if session.end_reason == TheaterSession.END_LIMIT else "That's the show!\nYou saw them all."
	_show_card(VIEW_END_CARD, text, [[BACK_TO_WORLD, "BACK TO MY WORLD"], [MORE_SHOWS, "MORE SHOWS"]], picture)


## A message (and choices) in the middle; never over a playing video (the player closes first).
func _show_card(v: StringName, text: String, buttons: Array, picture: Texture2D = null) -> void:
	_leave_shorts()
	if backend and player_on:
		backend.close()
	player_on = false
	_hold_sound(false)
	view = v
	_show_play_parts(false)
	title_label.text = ""
	card_label.text = text
	_picture.texture = picture
	_picture.visible = picture != null
	_entry.visible = false
	_clear_card_box()
	for entry: Array in buttons:
		var b := UiKit.big_button(entry[1], Color(), Vector2(SCREEN_SIZE.x - 80, 76))
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(_on_card_button.bind(entry[0]))
		_card_buttons[entry[0]] = b
		_card_box.add_child(b)
	_refresh_buttons()


## The player's parts (header, screen, cards) or the message card.
func _show_play_parts(on: bool) -> void:
	title_label.visible = on
	close_button.visible = on and player_on
	_frame.visible = on
	_screen.visible = on
	_strip.visible = on
	_card_frame.visible = not on
	if not on:
		still.visible = false
		_poster.visible = false


func _show_gate() -> void:
	if not AgeBand.restrictions:   # the owner, 2026-09-29: no grown-up confirmations for now
		_show_switch()
		return
	gate_question = ParentGate.make(_rng)
	_typed = ""
	if ParentGate.is_locked(_now()):   # M4 Task 10 review E: three wrong answers rest every gate for a minute
		_shown_wait = ParentGate.wait_seconds(_now())
		_show_card(VIEW_GATE, ParentGate.locked_text(_shown_wait), [])
		set_process(true)
		return
	_shown_wait = -1
	_show_card(VIEW_GATE, "Grown-ups only!\n" + str(gate_question.text), [])
	_entry.visible = true
	_entry.text = "_"
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	pad_buttons.clear()
	for key: String in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "DEL", "0", "OK"]:
		var color := UiKit.GREEN if key == "OK" else Color(0.16, 0.2, 0.32, 0.95)
		var b := UiKit.big_button(key, Color(), Vector2(86, 56))
		b.add_theme_font_size_override("font_size", 26)
		for state: String in ["normal", "hover", "pressed"]:   # slim keys, so the pad fits the card
			var box := UiKit.box(color.lightened(0.12) if state == "hover" else color, 14, 6)
			b.add_theme_stylebox_override(state, box)
		b.pressed.connect(_on_pad.bind(key))
		pad_buttons[key] = b
		grid.add_child(b)
	_card_box.add_child(grid)


func _show_switch() -> void:
	var now := "ON" if TheaterRules.is_allowed(_band(), profile.theater_switch) else "OFF"
	_show_card(VIEW_SWITCH, tr("The Theater for this player\nis %s now.") % now, [[TURN_ON, "TURN ON"], [TURN_OFF, "TURN OFF"]])


# --- Buttons and keys --------------------------------------------------------------------------

func _on_next() -> void:
	if view == VIEW_PLAY and session.next():
		_after_move()


func _on_prev() -> void:
	if view == VIEW_PLAY and session.previous():
		_after_move()


func _on_channel(i: int) -> void:
	if view in [VIEW_PLAY, VIEW_SHORTS] and session != null and session.pick_channel(i):
		_after_move()


func _on_card(i: int) -> void:
	var k := page * CARDS + i
	if view != VIEW_PLAY:
		return
	if k == session.index:
		_play_again()   # the video on the screen: plays again only after CLOSE
	elif session.pick_video(k):
		_after_move()


func _turn_page(step: int) -> void:
	if view != VIEW_PLAY:
		return
	page = clampi(page + step, 0, _pages() - 1)
	_refresh_strip()


## The player reported the end of the video: NEXT lights up, nothing starts by itself.
func _on_video_ended() -> void:
	if view == VIEW_PLAY and player_on:
		_glow_next(true)


func _on_video_failed(_code: String) -> void:
	if view == VIEW_PLAY and player_on:
		title_label.text = CANT_PLAY


func _on_card_button(id: StringName) -> void:
	match id:
		GROWN_UPS:
			_show_gate()
		TURN_ON, TURN_OFF:
			profile.theater_switch = TheaterRules.SWITCH_ON if id == TURN_ON else TheaterRules.SWITCH_OFF
			save_profile.call()
			_start()
		BACK_TO_WORLD:
			_exit()
		MORE_SHOWS:
			session.more()
			_after_move()
		WATCH_SHORTS:
			_show_shorts()


func _on_pad(key: String) -> void:
	match key:
		"DEL":
			_typed = _typed.left(-1)
		"OK":
			if ParentGate.check(gate_question, _typed):
				ParentGate.record_right()
				_show_switch()
				return
			var resting := ParentGate.record_wrong(_now())
			_show_gate()
			if not resting:
				card_label.text = "Not quite. Try again!\n" + str(gate_question.text)
			return
		_:
			if _typed.length() < MAX_TYPED:
				_typed += key
	_entry.text = _typed if _typed != "" else "_"


## A PC: Esc leaves the Theater (before the pause menu hears it), N is NEXT, B is BACK.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if not visible or view == VIEW_CLOSED or _covered or k == null or not k.pressed or k.echo:
		return
	if school.is_open():
		return   # the School over the Shorts takes its own keys (Esc closes it)
	if view == VIEW_SHORTS and shorts.is_making():   # MAKE MY SHORT: the maker takes the keys; Esc is a step back
		if event.is_action_pressed(&"pause"):
			shorts.back_if_making()
			get_viewport().set_input_as_handled()
		return
	if view == VIEW_SHORTS and _shorts_key(k):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"pause"):
		_exit()
	elif k.physical_keycode == KEY_N or k.keycode == KEY_N:
		_on_next()
	elif k.physical_keycode == KEY_B or k.keycode == KEY_B:
		_on_prev()
	else:
		return
	get_viewport().set_input_as_handled()


## The gate's rest counts down (then a new question), and the browser's player is asked for its events.
func _process(delta: float) -> void:
	var busy := false
	if view == VIEW_GATE and _shown_wait >= 0:
		busy = true
		if ParentGate.is_locked(_now()):
			var wait := ParentGate.wait_seconds(_now())
			if wait != _shown_wait:
				_shown_wait = wait
				card_label.text = ParentGate.locked_text(wait)
		else:
			_show_gate()
	else:
		_shown_wait = -1
	if player_on and backend and backend.has_method("poll"):
		busy = true
		_poll_wait -= delta
		if _poll_wait <= 0.0:
			_poll_wait = POLL_SECONDS
			backend.poll()
	if not busy:
		set_process(false)


func _now() -> int:
	return int(msec.call()) if msec.is_valid() else Time.get_ticks_msec()


func _exit() -> void:
	close()
	exit_requested.emit()


func _refresh_buttons() -> void:
	var playing := view == VIEW_PLAY
	next_button.disabled = not playing
	prev_button.disabled = not playing or not session.can_go_back()
	for i in channel_buttons.size():
		channel_buttons[i].disabled = not (playing or view == VIEW_SHORTS)
		channel_buttons[i].button_pressed = playing and session.channel == i
	shorts_tab.button_pressed = view == VIEW_SHORTS
	for c in video_cards:
		c.disabled = not playing


func _pages() -> int:
	if session == null:
		return 1
	return maxi(1, ceili(float(session.videos().size()) / CARDS))


func _refresh_strip() -> void:
	var vids: Array = session.videos() if session else []
	var pages := _pages()
	page = clampi(page, 0, pages - 1)
	page_prev_button.visible = pages > 1
	page_next_button.visible = pages > 1
	page_prev_button.disabled = page <= 0
	page_next_button.disabled = page >= pages - 1
	var c: Dictionary = session.channels[session.channel] if session and not session.channels.is_empty() else {}
	for i in CARDS:
		var k := page * CARDS + i
		var card := video_cards[i]
		card.visible = k < vids.size()
		if card.visible:
			card.show_video(vids[k], k + 1, k == session.index, c.get("color", TheaterChannels.DEFAULT_COLOR),
				c.get("icon", TheaterChannels.DEFAULT_ICON))


## The tabs: one big picture button per channel.
func _set_channels(channels: Array) -> void:
	for b in channel_buttons:
		b.visible = false
		b.queue_free()
	channel_buttons.clear()
	var n := channels.size() + 1   # owner #94: the SHORTS tab first
	var w := minf(TAB_MAX_W, floorf((WIDTH - (n - 1) * TAB_GAP) / n))
	shorts_tab.custom_minimum_size = Vector2(w, TAB_H)
	shorts_tab.size = shorts_tab.custom_minimum_size
	for i in channels.size():
		var c: Dictionary = channels[i]
		var b := ChannelTab.new(c.title, c.icon, Vector2(w, TAB_H))
		_style_tab(b, c.color)
		b.pressed.connect(_on_channel.bind(i))
		_tabs.add_child(b)
		channel_buttons.append(b)


func _style_tab(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", _tab_box(color.darkened(0.35), false))
	b.add_theme_stylebox_override("hover", _tab_box(color.darkened(0.15), false))
	b.add_theme_stylebox_override("pressed", _tab_box(color, true))
	b.add_theme_stylebox_override("hover_pressed", _tab_box(color.lightened(0.08), true))
	b.add_theme_stylebox_override("disabled", _tab_box(color.darkened(0.6), false))


func _tab_box(color: Color, chosen: bool) -> StyleBoxFlat:
	var box := UiKit.box(color, 14, 6)
	if chosen:
		box.border_color = Color("ffd23f")
		box.set_border_width_all(4)
	return box


func _glow_next(on: bool) -> void:
	next_glows = on
	next_button.add_theme_stylebox_override("normal", UiKit.box(Color("ffd23f").darkened(0.1), 18, 8) if on else _next_normal)


func _connect_backend() -> void:
	if backend == null or backend == _connected:
		return
	_connected = backend
	if backend.has_signal("ended"):
		backend.connect("ended", _on_video_ended)
	if backend.has_signal("failed"):
		backend.connect("failed", _on_video_failed)
	if backend.has_signal("stopped"):
		backend.connect("stopped", _stop_video)


## The game's own sound pauses while a video is on the screen (the master bus, as it was before).
func _hold_sound(on: bool) -> void:
	if on == _holding_sound:
		return
	_holding_sound = on
	if on:
		_sound_was_muted = AudioServer.is_bus_mute(MASTER_BUS)
		AudioServer.set_bus_mute(MASTER_BUS, true)
	else:
		AudioServer.set_bus_mute(MASTER_BUS, _sound_was_muted)


func is_holding_sound() -> bool:
	return _holding_sound


func _on_viewport_resized() -> void:
	_update_rect.call_deferred()


func _update_rect() -> void:
	if backend and view == VIEW_PLAY and player_on:
		backend.set_rect(pixel_rect(), close_pixel_rect())


# --- Owner #94: EasyCraft Shorts ---------------------------------------------------------------------------------

## The SHORTS tab: the feed under the tabs (a video on the screen stops first).
func _show_shorts() -> void:
	if backend and player_on:
		backend.close()
	player_on = false
	_hold_sound(false)
	_glow_next(false)
	view = VIEW_SHORTS
	_show_play_parts(false)
	_card_frame.visible = false
	_left.visible = false
	_right.visible = false
	shorts.profile = profile
	shorts.save_profile = save_profile
	shorts.visible = true
	shorts.open()
	_refresh_buttons()
	layout_changed.emit()


## Anything else on the screen: the Shorts stop (their voice too) and the channels' columns come back.
func _leave_shorts() -> void:
	if not shorts.visible:
		return
	shorts.leave()
	shorts.visible = false
	school.close()
	_left.visible = true
	_right.visible = true
	layout_changed.emit()


## LEARN IT: a School unit opens over the Theater (its BACK comes back to the Shorts); the Mission Board and the Star
## Map are in the world, so the Theater closes and asks for them.
func _on_learn(link: Dictionary) -> void:
	if link.has(ShortRules.LINK_UNIT):
		school.open_unit(str(link.unit), profile, save_profile)
		return
	_exit()
	learn_requested.emit(link)


## The Shorts' keys on a PC: ↑ / PageUp / B back, ↓ / PageDown / N on, Space plays and pauses, Esc leaves (below). The
## arrows walk in the world too, so they are let go there (the child stays in the Theater).
func _shorts_key(k: InputEventKey) -> bool:
	var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
	match code:
		KEY_UP, KEY_PAGEUP, KEY_B:
			shorts.step(-1)
		KEY_DOWN, KEY_PAGEDOWN, KEY_N:
			shorts.step(1)
		KEY_SPACE:
			shorts.toggle_play()
		_:
			return false
	for action: StringName in [&"move_forward", &"move_back", &"jump"]:
		if InputMap.has_action(action):
			Input.action_release(action)
	return true


# --- Building ----------------------------------------------------------------------------------

func _build_card() -> void:
	_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_card.offset_left = 20
	_card.offset_right = -20
	_card.offset_top = 20
	_card.offset_bottom = -20
	_card.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_theme_constant_override("separation", 14)
	card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_label.add_theme_font_size_override("font_size", 28)
	card_label.custom_minimum_size = Vector2(SCREEN_SIZE.x - 40, 0)
	_card.add_child(card_label)
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_picture.custom_minimum_size = Vector2(SCREEN_SIZE.x - 80, 150)
	_picture.visible = false
	_card.add_child(_picture)
	_entry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_entry.add_theme_font_size_override("font_size", 40)
	_entry.visible = false
	_card.add_child(_entry)
	_card_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_card_box.add_theme_constant_override("separation", 12)
	_card.add_child(_card_box)
	_card_frame.add_child(_card)


func _clear_card_box() -> void:
	for c in _card_box.get_children():
		(c as Control).visible = false   # out of the layout now, freed at the end of the frame
		c.queue_free()
	_card_buttons.clear()
	pad_buttons.clear()


## An icon-first side button with its word underneath (spec §5.15); on a PC its key in a corner. Slim margins and a
## 40 px icon, so it fits its 130 px (UiKit's margins made it 148).
func _side_button(word: String, icon: StringName, color: Color, height: float, key: String) -> Button:
	var b := UiKit.big_button(word, color, Vector2(SIDE_WIDTH, height))
	for state: String in ["normal", "hover", "pressed"]:
		var c := color.lightened(0.12) if state == "hover" else (color.darkened(0.15) if state == "pressed" else color)
		b.add_theme_stylebox_override(state, UiKit.box(c, 18, 8))
	b.add_theme_stylebox_override("disabled", UiKit.box(Color(0.22, 0.22, 0.26, 0.75), 18, 8))
	b.icon = _icon(icon)
	b.add_theme_constant_override("icon_max_width", 40)
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	if keyboard:
		var cap := Label.new()
		cap.name = "Key"
		cap.text = key
		cap.add_theme_font_size_override("font_size", 15)
		cap.add_theme_color_override("font_color", Color(0.1, 0.12, 0.2))
		cap.add_theme_constant_override("outline_size", 0)
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 1, 1, 0.92)
		box.set_corner_radius_all(6)
		box.set_content_margin_all(3)
		box.content_margin_left = 6
		box.content_margin_right = 6
		cap.add_theme_stylebox_override("normal", box)
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cap.anchor_left = 1.0
		cap.anchor_right = 1.0
		cap.offset_left = -48
		cap.offset_right = -6
		cap.offset_top = 6
		cap.offset_bottom = 28
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_child(cap)
	return b


func _arrow_button(icon: StringName) -> Button:
	var b := UiKit.big_button("", Color(0.16, 0.2, 0.32, 0.95), Vector2(ARROW_W, STRIP_H))
	b.icon = _icon(icon)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.focus_mode = Control.FOCUS_NONE
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var c := Color(0.16, 0.2, 0.32, 0.95)
		b.add_theme_stylebox_override(state, UiKit.box(c.lightened(0.12) if state == "hover" else c, 14, 4))
	return b


## Places `c` by a rectangle relative to the top centre of the screen.
func _place_center(c: Control, r: Rect2) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 0.0
	c.anchor_bottom = 0.0
	c.offset_left = r.position.x
	c.offset_right = r.end.x
	c.offset_top = r.position.y
	c.offset_bottom = r.end.y


static var _icons: Dictionary = {}


## White arrow and cross icons, drawn once.
static func _icon(kind: StringName) -> Texture2D:
	if _icons.has(kind):
		return _icons[kind]
	var n := 48
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in n:
		for x in n:
			var p := Vector2(x + 0.5, y + 0.5) / n
			var on := false
			match kind:
				&"next":
					on = p.x > 0.25 and p.x < 0.8 and absf(p.y - 0.5) < (0.8 - p.x) * 0.75
				&"back":
					on = p.x < 0.75 and p.x > 0.2 and absf(p.y - 0.5) < (p.x - 0.2) * 0.75
				&"exit":
					on = p.x > 0.18 and p.x < 0.82 and p.y > 0.18 and p.y < 0.82 \
						and (absf(p.x - p.y) < 0.09 or absf(p.x + p.y - 1.0) < 0.09)
			if on:
				img.set_pixel(x, y, Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	_icons[kind] = tex
	return tex


## A channel's tab: its picture over its name (at most two lines), always its own size.
class ChannelTab:
	extends Button

	var title := ""
	var picture := TextureRect.new()
	var label := Label.new()

	func _init(p_title: String, icon_name: StringName, size_px: Vector2) -> void:
		title = p_title
		tooltip_text = p_title
		custom_minimum_size = size_px
		clip_contents = true
		toggle_mode = true
		focus_mode = Control.FOCUS_NONE
		var column := VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.offset_left = 4
		column.offset_right = -4
		column.offset_top = 6
		column.offset_bottom = -4
		column.alignment = BoxContainer.ALIGNMENT_BEGIN
		column.add_theme_constant_override("separation", 2)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(column)
		picture.texture = TheaterIcons.icon(icon_name, 36)
		picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		picture.custom_minimum_size = Vector2(0, 36)
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(picture)
		label.text = p_title
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.max_lines_visible = 2
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_constant_override("line_spacing", -2)
		label.size_flags_vertical = Control.SIZE_EXPAND_FILL   # room for two lines
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)


## One video under the player: its number and the channel's picture, its title and its maker. The one on the
## screen has a yellow frame.
class VideoCard:
	extends Button

	var video: Dictionary = {}
	var current := false
	var _thumb := Panel.new()
	var _icon_rect := TextureRect.new()
	var _number := Label.new()
	var _title := Label.new()
	var _from := Label.new()

	func _init(size_px: Vector2) -> void:
		custom_minimum_size = size_px
		clip_contents = true
		focus_mode = Control.FOCUS_NONE
		var column := VBoxContainer.new()
		column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		column.offset_left = 8
		column.offset_right = -8
		column.offset_top = 8
		column.offset_bottom = -8
		column.add_theme_constant_override("separation", 4)
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(column)
		_thumb.custom_minimum_size = Vector2(0, 72)
		_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_thumb)
		_icon_rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		_icon_rect.offset_left = -22
		_icon_rect.offset_right = 22
		_icon_rect.offset_top = -22
		_icon_rect.offset_bottom = 22
		_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_thumb.add_child(_icon_rect)
		_number.position = Vector2(6, 2)
		_number.add_theme_font_size_override("font_size", 18)
		_number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_thumb.add_child(_number)
		_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_title.max_lines_visible = 3
		_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_title.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_title.add_theme_font_size_override("font_size", 16)
		_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_title)
		_from.add_theme_font_size_override("font_size", 12)
		_from.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		_from.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_from.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(_from)

	func show_video(v: Dictionary, number: int, is_current: bool, color: Color, icon_name: StringName) -> void:
		video = v
		current = is_current
		_title.text = str(v.get("title", ""))
		_from.text = str(v.get("from", ""))
		_number.text = str(number)
		_icon_rect.texture = TheaterIcons.icon(icon_name, 48)
		var thumb := StyleBoxFlat.new()
		thumb.bg_color = color.darkened(0.2)
		thumb.set_corner_radius_all(8)
		_thumb.add_theme_stylebox_override("panel", thumb)
		var base := color.darkened(0.55)
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			var box := UiKit.box(base.lightened(0.1) if state == "hover" else base, 12, 0)
			if is_current:
				box.border_color = Color("ffd23f")
				box.set_border_width_all(4)
			add_theme_stylebox_override(state, box)
