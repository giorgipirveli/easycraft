class_name ChatPanel
extends Control
## The game chat (spec §3b, §5.13). The CHAT button (T or Enter on a keyboard; "/" opens it with
## "/" already typed) opens a chat bar at the top of the screen. Under the bar are tappable buttons:
## the quick-chat phrases, and after "/" the commands and then their choices, so children never
## have to remember them. The last lines stay in a small history that fades while the bar is closed.
## While the bar is open, a see-through layer takes taps on the world (a tap there closes the chat)
## and the keyboard's game keys are switched off, so typing never moves the player.
## Text only: emoji may not render in the default font.
## M4 E: the quick-chat wheel (under-13 players chat with it only; 13+ reach it with QUICK); in an
## online match the chat talks in the match's team room (OnlineService, the server's rules) instead
## of the host's relay chat; a grown-up's "chat off" holds; a line from someone else opens MUTE /
## REPORT (line_menu).
## Owner 38: what the child types and taps also reaches their own bot friends (Session.request_bot_talk:
## the host decides who hears); an under-13 player's typed words and the wheel's BOTS page go to their
## friends only, never to other people.

signal command_entered(text: String)
## M3 Task 11: this player said something (typed or a quick phrase) — their parrot may repeat it, on this
## device only (PetDirector.hear_own). Never other players' lines.
signal own_line_sent(text: String)

const HISTORY_CLOSED := 6         # lines shown while the bar is closed (they fade)
const HISTORY_OPEN := 10          # lines shown while the bar is open
const KEEP_LINES := 30
const FADE_AFTER := 8.0           # seconds a line stays before it fades (bar closed)
const FADE_TIME := 1.5
const BUTTON_FONT := 24
const LINE_FONT := 22
const HISTORY_WIDTH := 500.0
## Layout on the 1280x720 canvas (M2 Task 17, HudLayout): the CHAT button sits under pause, the Secret
## Book beside it. The bar runs right of pause; the choices and the history sit right of BOOK, clear of
## the joystick (bottom left), JUMP (bottom right) and WALK and MORE (top right).
const BAR_LEFT := 161.0
const BAR_TOP := 12.0
const BAR_HEIGHT := 76.0
const CHOICES_LEFT := 306.0
const CHOICES_TOP := 96.0
const CHOICES_HEIGHT := 190.0
const CHOICES_RIGHT := 306.0       # keeps clear of WALK and MORE
const HISTORY_CLOSED_POS := Vector2(306, 172)   # below the tip/feedback toast (y 96..~156), right of BOOK
const COLORS := {&"chat": Color.WHITE, &"system": Color("ffd23f"), &"error": Color("ff9e8f"), &"bot": Color("8fd8ff")}

var button := TouchButton.new()
var band: StringName = AgeBand.unknown()

var _open := false
var _catcher := Control.new()
var _bar := PanelContainer.new()
var _field := LineEdit.new()
var _choices_panel := PanelContainer.new()
var _hint := Label.new()
var _choices := HFlowContainer.new()
var _history := VBoxContainer.new()
var _labels: Array[Label] = []
var _lines: Array[Dictionary] = []   # {"text": String, "kind": StringName, "time": float}
var _stashed_keys := {}              # action -> its events, while the bar is open
var _opened_at := 0.0

# M4 E: the quick-chat wheel, online team chat, and mute / report from a line.
var wheel := QuickChatWheel.new()
var quick_button: Button
var line_menu := PanelContainer.new()
var online: OnlineService            # set by use_team_chat in an online match
var _team := ""                      # the team room's channel id while it is open
var _chat_off := false               # a grown-up switched chat off (online)
var _online_world := false           # M4 Task 10 review B: an online match (never the relay chat in the room's place)
var _room_match := ""                # the match whose team room this chat talks in
var _trying_room := false            # a try to open the room is on its way
var _menu_msg: Dictionary = {}
var _menu_body := VBoxContainer.new()
var _touch_line := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UiKit.theme()

	_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_catcher.visible = false
	_catcher.gui_input.connect(_on_catcher_input)
	add_child(_catcher)

	_history.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_history.add_theme_constant_override("separation", int(LINE_GAP))
	for i in HISTORY_OPEN:
		var l := _line_label()   # owner 49: on a dark backing
		l.visible = false
		_history.add_child(l)
		_labels.append(l)
	add_child(_history)
	_measure.visible = false   # owner 49: measures lines before they show
	add_child(_measure)

	_build_bar()
	_build_choices()
	_build_wheel_and_menu()   # M4 E
	move_child(_history, wheel.get_index() + 1)   # owner 49: the lines over the wheel's dim, under the line menu

	button.text = "CHAT"
	button.symbol = &"chat"
	HudLayout.place(button, &"chat")
	# Toggle on release: the touch-down also produces an emulated mouse press (see BlockPalette).
	button.released.connect(_toggle)
	add_child(button)
	_built = true   # owner 49
	_place_history()


## Band = this player's age band (under_13 gets quick chat only). Registers with the host.
func setup(username: String, age_band: StringName) -> void:
	band = ChatRules.effective_band(age_band)
	_my_name = username
	_field.placeholder_text = "Type / for commands" if band != AgeBand.TEEN_PLUS else "Say something, or type / for commands"
	Session.chat_received.connect(_on_chat_received)
	Session.chat_join(username, band)


## Controls that keep touches from building or looking around behind them (M4 E: the wheel and the
## line menu; a touch on a friend's line is taken in _input, before the look area hears it).
func blockers() -> Array[Control]:
	return [button, _catcher, _bar, _choices_panel, wheel, line_menu]


## The bar or the wheel is open.
func is_open() -> bool:
	return _open or wheel.visible


func _toggle() -> void:
	if is_open():
		close()
	else:
		open()


## Opens the bar (with `prefill` typed); a player who chats with the wheel only gets the wheel.
func open(prefill: String = "") -> void:
	if _open or not is_visible_in_tree():
		return
	_retry_room()   # M4 Task 10 review B
	if prefill == "" and _wheel_only():
		open_wheel()
		return
	wheel.close()
	_open = true
	_opened_at = _now()
	_switch_game_keys(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_catcher.visible = true
	_bar.visible = true
	button.selected = true
	_set_text(prefill)
	_fill_history()


func close() -> void:
	wheel.close()
	line_menu.visible = false
	if not _open:
		return
	_open = false
	_field.unedit()
	_field.release_focus()
	_field.text = ""
	_catcher.visible = false
	_bar.visible = false
	_choices_panel.visible = false
	button.selected = false
	_switch_game_keys(true)
	_place_history()
	_fill_history()


## A line in the history; from = the player who said it ("" for system lines and replies).
func add_line(text: String, kind: StringName = &"system", from: String = "") -> void:
	text = in_my_language(text, kind)   # M3 Task 21a
	_lines.append({"text": "%s: %s" % [from, text] if from != "" else text, "kind": kind, "time": _now()})
	while _lines.size() > KEEP_LINES:
		_lines.pop_front()
	_fill_history()


func clear_history() -> void:
	_lines.clear()
	_fill_history()


func _on_chat_received(from: String, text: String, kind: StringName) -> void:
	if kind == &"chat" and (_team != "" or _chat_off):
		return   # online, players talk in the team room (or chat is off)
	if kind == &"chat" and _online_world and not ChatRules.is_quick_phrase(text):
		return   # M4 Task 10 review B: online, the host's relay carries quick phrases only
	add_line(text, kind, from)


# --- Typing and buttons -----------------------------------------------------------------------

func _submit(text: String) -> void:
	var t := text.strip_edges()
	if t == "":
		if _now() - _opened_at > 0.4:   # not the auto-repeat of the Enter that opened the bar
			close()
		return
	if ChatCommands.is_command(t):
		close()
		command_entered.emit(t)
		return
	if _chat_off:
		add_line(OnlineChatRules.message("chat_off"), &"error")
		_set_text("")
		return
	var result := ChatRules.check(t, band)   # the host checks again; this only saves a round trip
	if result.has("error"):
		if result.error == "quick_chat_only" and _to_own_bots(t):   # owner 38: words for their own friends
			return
		add_line(ChatRules.message(result.error), &"error")
		if result.error == "quick_chat_only":
			_set_text("")
		return
	if _resting() and not ChatRules.is_quick_phrase(result.text):   # M4 Task 10 review B: words wait for the room
		if _to_own_bots(t):
			return
		add_line(OnlineChatRules.message("chat_resting"), &"error")
		_set_text("")
		return
	if _team != "":
		var online_check := OnlineChatRules.check_send(t, online.chat_level())
		if online_check.has("error"):
			add_line(OnlineChatRules.message(online_check.error), &"error")
			_set_text("")
			return
		close()
		var err := await online.send_text(_team, t)
		if err != "":
			add_line(err, &"error")
		_bots_hear(t)   # owner 38: after the child's own line
		return
	close()
	Session.request_chat(t)
	_bots_hear(t)   # owner 38


## Buttons under the bar: quick-chat phrases on an empty bar, then after "/" the commands, then the
## choices of the command being typed.
func _refresh_choices() -> void:
	for c in _choices.get_children():
		_choices.remove_child(c)
		c.queue_free()
	var text := _field.text
	var hint := ""
	if text.strip_edges() == "":
		hint = "Tap a phrase, or type / for commands." if band != AgeBand.TEEN_PLUS \
			else "Type a message, tap a phrase, or type / for commands."
		for phrase in ChatRules.QUICK_PHRASES:
			_add_choice(phrase, UiKit.GREEN, _send_phrase.bind(phrase))
		_add_choice("/ COMMANDS", UiKit.BLUE, _set_text.bind("/"))
	elif ChatCommands.is_command(text):
		var body := text.strip_edges(true, false).substr(1)
		var command := ChatCommands.command_name(body.get_slice(" ", 0))
		var why := ChatCommands.refusal(command, Session.commands_enabled, Game.mode) if command != &"" else ""
		var list: Array[String] = []
		if why == "":
			list = ChatCommands.suggestions(text, _other_names(), _command_context())
		if why != "":
			hint = why   # owner feedback #40: a command this child can't use here says why
		elif command != &"" and (body.contains(" ") or list.size() == 1):
			hint = "%s   %s" % [ChatCommands.usage(command), ChatCommands.about(command)]
		elif list.is_empty():
			hint = "I don't know that command. Try /help"
		else:
			hint = "Tap a command:"
		for s in list:
			var label := s if not body.contains(" ") else s.substr(s.find(" ") + 1)
			_add_choice(label, UiKit.BLUE, _pick.bind(s))
	_hint.text = hint
	_choices_panel.visible = _open and hint != ""
	_place_history()


func _pick(suggestion: String) -> void:
	if ChatCommands.parse(suggestion).has("error"):
		_set_text(suggestion + " ")   # the command needs a choice: show them
	else:
		close()
		command_entered.emit(suggestion)


func _send_phrase(phrase: String) -> void:
	close()
	if BotTalkWheel.PHRASES.has(phrase) and _to_own_bots(phrase):   # owner 38: the wheel's BOTS page
		return
	if _chat_off:
		add_line(OnlineChatRules.message("chat_off"), &"error")
	elif _team != "":
		var err := await online.send_phrase(_team, phrase)
		if err != "":
			add_line(err, &"error")
	else:
		Session.request_chat(phrase)
	_bots_hear(phrase)   # owner 38: the child's friends hear the wheel's phrases too (after the child's line)


func _set_text(text: String) -> void:
	_field.text = text
	_field.caret_column = text.length()
	_refresh_choices()
	_field.grab_focus()
	_field.edit()   # also brings up the on-screen keyboard on phones


func _add_choice(text: String, color: Color, action: Callable) -> void:
	var b := UiKit.big_button(text, color, Vector2(0, 58))
	b.focus_mode = Control.FOCUS_NONE   # the bar keeps the focus (and the phone keyboard stays up)
	b.add_theme_font_size_override("font_size", BUTTON_FONT)
	b.pressed.connect(action)
	_choices.add_child(b)


## Owner feedback #40: what the command buttons may show here (the mode, the universe's weather, the open
## universes, the bot friends' names).
func _command_context() -> Dictionary:
	var bots: Array = []
	if is_inside_tree():
		for b in get_tree().get_nodes_in_group(&"bot_friends"):
			bots.append(str(b.get("bot_name")))
	return ChatCommands.context(Game.mode, Session.commands_enabled, Game.universe, Profile.data.universe_unlocked, bots)


func _other_names() -> Array:
	var names := []
	for id: int in Session.chat_names:
		if id != multiplayer.get_unique_id():
			names.append(Session.chat_names[id])
	return names


func _on_catcher_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null:
		return
	# A press on the CHAT button is left to the button (it toggles on release).
	if mb.pressed and not button.get_global_rect().has_point(mb.global_position):
		var i := _line_at(mb.global_position)
		if i >= 0 and _reportable(i):
			close()
			open_line_menu(_lines[i].msg)   # M4 E: mute / report from the line
		else:
			close()
	_catcher.accept_event()


func _input(event: InputEvent) -> void:
	if (is_open() or line_menu.visible) and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and not is_open() and not line_menu.visible:
		_touch_on_lines(event as InputEventScreenTouch)


func _unhandled_input(event: InputEvent) -> void:
	if is_open() or not is_visible_in_tree():
		return
	if event.is_action_pressed(&"chat_command"):
		open("/")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"chat"):
		open()
		get_viewport().set_input_as_handled()


## While typing, the keyboard's game keys must not play the game (Input polling ignores GUI focus):
## their events leave the Input Map while the bar is open and come back when it closes. The ui_*
## actions stay, so typing, Enter and Escape still work.
func _switch_game_keys(on: bool) -> void:
	if on:
		for action: StringName in _stashed_keys:
			if InputMap.has_action(action):
				for e: InputEvent in _stashed_keys[action]:
					InputMap.action_add_event(action, e)
		_stashed_keys.clear()
		return
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		_stashed_keys[action] = InputMap.action_get_events(action)
		InputMap.action_erase_events(action)
		Input.action_release(action)


func _exit_tree() -> void:
	if _open:
		_switch_game_keys(true)
	Session.chat_reset()   # the game is over for this player: forget names and bands
	if online and _team != "":
		online.close_chat(_team)   # M4 E: out of the team room
		_team = ""


# --- History ----------------------------------------------------------------------------------

## Owner 49: the newest lines that fit where the history is now (above the phone keyboard, beside the wheel),
## each label as wide as its words; the chat goes over the rest of the HUD while it is open.
func _fill_history() -> void:
	if not _built or not is_inside_tree():
		return
	_raise(_history_open())
	if _open:
		_place_choices()
	var area := _history_area()
	_place(_history, Vector2.ZERO, area.position, area.size)
	var count := HISTORY_OPEN if _history_open() else HISTORY_CLOSED
	var shown := _fitting(_lines.slice(maxi(_lines.size() - count, 0)), area.size)
	_first_shown = _lines.size() - shown.size()
	for i in _labels.size():
		var l := _labels[i]
		if i < shown.size():
			l.text = _shown_text(shown[i][0])   # M5 Task 1: with its kind's mark
			l.add_theme_color_override("font_color", COLORS.get(shown[i][0].kind, Color.WHITE))
			l.custom_minimum_size.x = shown[i][1]
		l.set_meta(&"time", shown[i][0].time if i < shown.size() else -INF)
	_fade_history()


## Lines fade FADE_AFTER seconds after they arrive, unless the bar is open.
func _fade_history() -> void:
	var now := _now()
	for l in _labels:
		var age := now - float(l.get_meta(&"time", -INF))
		var alpha := 1.0 if _history_open() else clampf((FADE_AFTER + FADE_TIME - age) / FADE_TIME, 0.0, 1.0)
		l.modulate.a = alpha
		l.visible = alpha > 0.0 and is_finite(age)


## Closed: right of BOOK, under the toasts; open: under the bar and its buttons, above the phone keyboard;
## with the wheel: left of it (owner 49, _history_area).
func _place_history() -> void:
	_fill_history()


func _process(_delta: float) -> void:
	if not _history_open():
		_fade_history()
	if _open:
		_follow_keyboard()   # owner 49


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


# --- Building ---------------------------------------------------------------------------------

func _build_bar() -> void:
	_bar.add_theme_stylebox_override("panel", UiKit.box(UiKit.DARK, 18, 8))
	_bar.anchor_right = 1.0
	_bar.offset_left = BAR_LEFT
	_bar.offset_right = -24
	_bar.offset_top = BAR_TOP
	_bar.offset_bottom = BAR_TOP + BAR_HEIGHT
	_bar.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_bar.add_child(row)
	_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field.max_length = ChatRules.MAX_LENGTH
	TextSize.mark(_field, 28)   # M5 Task 1: TEXT SIZE
	_field.virtual_keyboard_enabled = true
	_field.virtual_keyboard_show_on_focus = true
	_field.keep_editing_on_text_submit = true
	_field.text_changed.connect(func(_t: String) -> void: _refresh_choices())
	_field.text_submitted.connect(_submit)
	row.add_child(_field)
	var send := UiKit.big_button("SEND", UiKit.GREEN, Vector2(110, 58))
	send.pressed.connect(func() -> void: _submit(_field.text))
	quick_button = UiKit.big_button("QUICK", OnlineUi.PURPLE, Vector2(120, 58))   # M4 E: the wheel
	quick_button.name = "Quick"
	quick_button.pressed.connect(open_wheel)
	var close_button := UiKit.big_button("X", UiKit.RED, Vector2(64, 58))
	close_button.pressed.connect(close)
	for b: Button in [send, quick_button, close_button]:
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", BUTTON_FONT)
		row.add_child(b)
	add_child(_bar)


func _build_choices() -> void:
	_choices_panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.8), 18, 12))
	_choices_panel.anchor_right = 1.0
	_choices_panel.offset_left = CHOICES_LEFT
	_choices_panel.offset_right = -CHOICES_RIGHT
	_choices_panel.offset_top = CHOICES_TOP
	_choices_panel.offset_bottom = CHOICES_TOP + CHOICES_HEIGHT
	_choices_panel.visible = false
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	TextSize.mark(_hint, LINE_FONT)   # M5 Task 1: TEXT SIZE
	_hint.add_theme_color_override("font_color", COLORS[&"system"])
	_hint.clip_text = not Vr.active()
	if Vr.active():   # owner #101: its words are 24 px in a headset (VrReadability): a second line, never cut off
		_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choices.add_theme_constant_override("h_separation", 8)
	_choices.add_theme_constant_override("v_separation", 8)
	scroll.add_child(_choices)
	column.add_child(scroll)
	_choices_panel.add_child(column)
	add_child(_choices_panel)


# --- M4 E: the quick-chat wheel, online team chat, mute and report from a line -------------------

const THANKS := "Thank you for telling us. A grown-up will look at it."
const MENU_SIZE := Vector2(680, 196)


## Opens the quick-chat wheel (with a COMMANDS pill for the chat commands).
func open_wheel() -> void:
	if not is_visible_in_tree():
		return
	_retry_room()   # M4 Task 10 review B
	if _open:
		close()
	line_menu.visible = false
	wheel.open(true, false)
	button.selected = true
	_fill_history()


## Chatting with the wheel only: under-13, or online without text chat (a grown-up's setting), or online while the
## team room is not open (M4 Task 10 review B).
func _wheel_only() -> bool:
	return band != AgeBand.TEEN_PLUS or (_team != "" and not online.can_type()) or _resting()


## In an online match: talk in the match's team room (the server checks every message at the
## strictest level of its players). A grown-up's "chat off" stops chatting here (commands still
## work). M4 Task 10 review B: if the room can't open, the chat says it is resting: typed words wait for the room
## (the host's relay chat trusted each guest's own name and band), the quick phrases still go through the host
## (which passes quick phrases only online), and the room is tried again whenever the chat opens.
func use_team_chat(service: OnlineService, match_id: String) -> void:
	online = service
	_online_world = true
	_room_match = match_id
	if not await _open_room() and is_inside_tree() and not _chat_off:
		add_line(OnlineChatRules.message("chat_resting"))


func team_chat_on() -> bool:
	return _team != ""


## Online, the team room is not open (the server, the network, or not in the match as the server sees it yet).
func _resting() -> bool:
	return _online_world and _team == "" and not _chat_off


## Signs in if needed and joins the team room; true when it is open. One try at a time.
func _open_room() -> bool:
	if _trying_room or online == null:
		return false
	_trying_room = true
	var service := online
	if service.status != OnlineService.ONLINE:
		await service.sign_in()
	if service.status != OnlineService.ONLINE or not is_inside_tree():
		_trying_room = false
		return false
	if service.chat_level() == OnlineRules.CHAT_OFF:
		_chat_off = true
		_trying_room = false
		return false
	var r: Dictionary = await service.open_team(_room_match)
	_trying_room = false
	if r.has("error"):
		print("CHAT team room not open: %s" % r.error)
		return false
	if not is_inside_tree():
		service.close_chat(r.channel_id)
		return false
	_team = r.channel_id
	if not service.chat_message.is_connected(_on_team_message):
		service.chat_message.connect(_on_team_message)
	if not service.status_changed.is_connected(_on_online_status):
		service.status_changed.connect(_on_online_status)
	return true


## Opening the chat while it rests tries the team room again (quietly).
func _retry_room() -> void:
	if _resting() and not _trying_room:
		_open_room()


func _on_online_status(status: StringName) -> void:
	if status != OnlineService.ONLINE:
		_team = ""   # the server went away: the chat rests (quick phrases through the host) until the room opens


func _on_team_message(msg: Dictionary) -> void:
	if msg.get("channel_id", "") != _team or _team == "":
		return
	_lines.append({"text": OnlineChatRules.line(msg), "kind": &"chat", "time": _now(), "msg": msg})
	while _lines.size() > KEEP_LINES:
		_lines.pop_front()
	_fill_history()


func _history_open() -> bool:
	return _open or wheel.visible or line_menu.visible


## The index (in _lines) of the history line shown at `pos` (screen), or -1.
func _line_at(pos: Vector2) -> int:
	for i in _labels.size():
		if _first_shown + i < _lines.size() and _labels[i].visible and _labels[i].get_global_rect().has_point(pos):
			return _first_shown + i
	return -1


## Where history line `index` (of _lines) is on the screen (its label's centre), or INF.
func line_position(index: int) -> Vector2:
	var i := index - _first_shown
	if i < 0 or i >= _labels.size() or not _labels[i].visible:
		return Vector2.INF
	return _labels[i].get_global_rect().get_center()


func _reportable(i: int) -> bool:
	return online != null and _lines[i].has("msg") and online.can_report(_lines[i].msg)


## A tap on the history: a line from someone else opens MUTE / REPORT.
func tap_line(pos: Vector2) -> void:
	if not pos.is_finite():
		return
	var i := _line_at(pos)
	if i >= 0 and _reportable(i):
		open_line_menu(_lines[i].msg)


## A finger on a line from someone else is the chat's (used up, so the world never hears it); any
## other touch is left to the world.
func _touch_on_lines(t: InputEventScreenTouch) -> void:
	var i := _line_at(t.position)
	if t.pressed:
		_touch_line = i if i >= 0 and _reportable(i) else -1
		if _touch_line >= 0 and is_inside_tree():
			get_viewport().set_input_as_handled()
		return
	if _touch_line >= 0:
		if i == _touch_line:
			open_line_menu(_lines[i].msg)
		if is_inside_tree():
			get_viewport().set_input_as_handled()
	_touch_line = -1


## MUTE and REPORT for someone else's message.
func open_line_menu(msg: Dictionary) -> void:
	if online == null or not online.can_report(msg):
		return
	_menu_msg = msg
	_menu_main()
	line_menu.visible = true
	_fill_history()


func menu_text() -> String:
	var l := _menu_body.find_child("What", true, false) as Label
	return l.text if l else ""


func menu_button(button_name: String) -> Button:
	return _menu_body.find_child(button_name, true, false) as Button


func _menu_main() -> void:
	_clear_menu()
	_menu_body.add_child(_menu_words(OnlineChatRules.line(_menu_msg)))
	_menu_row([_menu_button("MUTE", Color(), "Mute", _mute_from_menu),
		_menu_button("REPORT", UiKit.ORANGE, "Report", _menu_reasons),
		_menu_button("X", UiKit.RED, "Close", _close_menu)])


func _menu_reasons() -> void:
	_clear_menu()
	_menu_body.add_child(_menu_words("What happened?"))
	var buttons: Array = []
	for reason: String in OnlineService.REPORT_REASONS:
		buttons.append(_menu_button(OnlineFriendsPanel.REASONS[reason], UiKit.ORANGE, "Reason_" + reason,
			_report_from_menu.bind(reason)))
	_menu_row(buttons)


func _mute_from_menu() -> void:
	var id := str(_menu_msg.get("from_id", ""))
	online.mute_sender(_menu_msg)
	_close_menu()
	_forget_lines_from(id)


func _report_from_menu(reason: String) -> void:
	var msg := _menu_msg
	_close_menu()
	var err: String = await online.report_message(msg, reason)
	_forget_lines_from(str(msg.get("from_id", "")))
	add_line(err if err != "" else THANKS, &"error" if err != "" else &"system")


func _close_menu() -> void:
	line_menu.visible = false
	_menu_msg = {}
	_fill_history()


func _forget_lines_from(user_id: String) -> void:
	var kept: Array[Dictionary] = []
	for l in _lines:
		if not (l.has("msg") and str(l.msg.get("from_id", "")) == user_id):
			kept.append(l)
	_lines = kept
	_fill_history()


func _clear_menu() -> void:
	for c in _menu_body.get_children():
		_menu_body.remove_child(c)
		c.queue_free()


func _menu_words(text: String) -> Label:
	var l := Label.new()
	l.name = "What"
	l.text = text
	l.clip_text = true
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 26)
	return l


func _menu_button(text: String, color: Color, button_name: String, action: Callable) -> Button:
	var b := UiKit.big_button(text, color, Vector2(150, 72))
	b.name = button_name
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(action)
	return b


func _menu_row(buttons: Array) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for b: Button in buttons:
		row.add_child(b)
	_menu_body.add_child(row)


func _build_wheel_and_menu() -> void:
	add_child(wheel)
	wheel.chosen.connect(_send_phrase)
	wheel.commands_requested.connect(open.bind("/"))
	wheel.closed.connect(func() -> void:
		if not _open:
			button.selected = false
		_fill_history())
	wheel.tapped_outside.connect(tap_line)
	line_menu.add_theme_stylebox_override("panel", UiKit.box(UiKit.DARK, 18, 12))
	_place(line_menu, Vector2(0.5, 0), Vector2(-MENU_SIZE.x * 0.5, CHOICES_TOP), MENU_SIZE)
	line_menu.mouse_filter = Control.MOUSE_FILTER_STOP
	line_menu.visible = false
	_menu_body.add_theme_constant_override("separation", 10)
	line_menu.add_child(_menu_body)
	add_child(line_menu)


static func _place(c: Control, anchor: Vector2, offset: Vector2, size: Vector2) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + size.x
	c.offset_bottom = offset.y + size.y


# --- Owner 38: talking to the child's own bot friends ---------------------------------------------------

var _my_name := ""


## The child's friends hear what the child says (the host decides who: Session.request_bot_talk).
func _bots_hear(text: String) -> void:
	own_line_sent.emit(text)   # M3 Task 11: the parrot hears its own child
	if Session.has_own_bots():
		Session.request_bot_talk(text)


## Words for the child's own friends only (an under-13 player's typing, the wheel's BOTS page): never sent
## to other people; the chat filter still applies. False when the child has no friends of their own.
func _to_own_bots(text: String) -> bool:
	if not Session.has_own_bots():
		return false
	var code := ChatRules.filter_code(ChatRules.clean(text))
	if code != "":
		add_line(ChatRules.message(code), &"error")
		return true
	close()
	add_line(text, &"chat", tr(BOT_TALK_FROM) % (_my_name if _my_name != "" else "You"))
	Session.request_bot_talk(text)
	own_line_sent.emit(text)   # M3 Task 11
	return true


const BOT_TALK_FROM := "%s (to your bots)"


# --- Owner 49: a chat a child can read (the phone keyboard, the HUD on top, the wheel, contrast) ---------
# On phones (0.3.2, online): the HUD pieces added after the chat (a game's round line, the wave and boss
# lines, the Brave badge, the gold, the game clock, ATTACK) were drawn over the open bar, so the words being
# typed vanished under them; a landscape keyboard covers about the bottom half of the screen, where the
# newest lines were; the wheel's slots covered the lines; white words had only an outline over a bright sky.

## Behind every line: the words read on snow, sky, sand or a cave (contrast at least 4.5).
const LINE_BACK := Color(0.05, 0.06, 0.1, 0.9)
const LINE_PAD := Vector2(8, 2)
const LINE_GAP := 4.0
const EDGE := 8.0                   # between the chat's pieces, and above the keyboard
const MIN_CHOICES := 110.0          # the phrase and command buttons shrink to about one row (they scroll)
const LINES_ROOM := 76.0            # two lines kept above the keyboard while the buttons show
const HISTORY_WIDE := 760.0         # the open history is as wide as the buttons, up to this
const HISTORY_OPEN_HEIGHT := 380.0
const HISTORY_CLOSED_HEIGHT := 260.0

## The phone keyboard's height in screen pixels (0 while it is down, on a computer, and in a browser). Tests set it.
var keyboard_height: Callable = func() -> int:
	return keyboard_px(PlatformRules.is_web(PlatformRules.current()),
		DisplayServer.has_feature(DisplayServer.FEATURE_VIRTUAL_KEYBOARD), DisplayServer.virtual_keyboard_get_height)
var _keyboard_px := 0
var _built := false
var _first_shown := 0               # the index in _lines of the first label shown
var _measure := _line_label()
var _raised := false
var _home_prev: Node                # the chat's neighbours in the HUD while it is closed
var _home_next: Node


## The keyboard's height from `measure` when the game runs as a phone app with a keyboard, else 0. In a browser the page
## shrinks above the keyboard (web/shell.html) and Godot's web display server has no height to give: asking printed a
## warning at every frame (2026-09-28).
static func keyboard_px(web: bool, has_keyboard: bool, measure: Callable) -> int:
	if web or not has_keyboard:
		return 0
	return int(measure.call())


## Where the phone keyboard's top edge is on the canvas (the screen's bottom while it is down).
func keyboard_top() -> float:
	var view := get_viewport_rect().size
	var px := int(keyboard_height.call())
	var screen_h := float(get_window().size.y) if get_window() else 0.0
	if px <= 0 or screen_h <= 0.0:
		return view.y
	return view.y - px * view.y / screen_h


func _follow_keyboard() -> void:
	var px := int(keyboard_height.call())
	if px != _keyboard_px:
		_keyboard_px = px
		_fill_history()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fill_history()


## Open: under the bar (and its buttons) down to the keyboard; with the wheel: the column left of it, under
## CHAT (the wheel takes every touch meanwhile); closed: right of BOOK, under the toasts. (M5 Task 1: the right
## hand's; _history_area() mirrors it for the left.)
func _history_area_right_hand() -> Rect2:
	var view := get_viewport_rect().size
	if _open:
		var top := _choices_panel.offset_bottom + EDGE if _choices_panel.visible else CHOICES_TOP
		var bottom := minf(top + HISTORY_OPEN_HEIGHT, keyboard_top() - EDGE)
		var width := clampf(view.x - CHOICES_LEFT - CHOICES_RIGHT, HISTORY_WIDTH, HISTORY_WIDE)
		return Rect2(CHOICES_LEFT, top, width, maxf(bottom - top, 0.0))
	if wheel.visible:
		var left := wheel.get_global_rect().get_center().x - QuickChatWheel.RADIUS - QuickChatWheel.SLOT * 0.62
		var top := button.get_global_rect().end.y + EDGE
		return Rect2(EDGE * 2, top, clampf(left - EDGE * 4, 200.0, HISTORY_WIDTH), maxf(view.y - EDGE * 2 - top, 0.0))
	return Rect2(HISTORY_CLOSED_POS, Vector2(HISTORY_WIDTH, HISTORY_CLOSED_HEIGHT))


## The phrase and command buttons end high enough to leave two lines above the keyboard.
func _place_choices() -> void:
	var lowest := keyboard_top() - EDGE * 2 - LINES_ROOM
	_choices_panel.offset_bottom = clampf(lowest, CHOICES_TOP + MIN_CHOICES, CHOICES_TOP + CHOICES_HEIGHT)


## The newest of `lines` that fit in `area`, oldest first, each as [line, its label's width].
func _fitting(lines: Array, area: Vector2) -> Array:
	var out := []
	var used := 0.0
	for i in range(lines.size() - 1, -1, -1):
		var text := _shown_text(lines[i])   # M5 Task 1: measured as shown, with its mark
		var width := minf(_measure.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			TextSize.px(LINE_FONT)).x + LINE_PAD.x * 2 + 4.0, area.x)   # M5 Task 1: at the size the line shows
		_measure.text = text
		_measure.size = Vector2(width, 0)
		var height := _measure.get_minimum_size().y
		if used + height > area.y + 0.5:
			break
		used += height + LINE_GAP
		out.push_front([lines[i], ceilf(width)])
	return out


## A history line: words on a dark backing, as wide as they are (wrapping inside the history).
func _line_label() -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # M3 Task 21a: a player's words are never changed
	TextSize.mark(l, LINE_FONT)   # M5 Task 1: TEXT SIZE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var back := UiKit.box(LINE_BACK, 8, 0)
	back.border_width_bottom = 0
	back.content_margin_left = LINE_PAD.x
	back.content_margin_right = LINE_PAD.x
	back.content_margin_top = LINE_PAD.y
	back.content_margin_bottom = LINE_PAD.y
	l.add_theme_stylebox_override("normal", back)
	return l


## While it is open (the bar, the wheel or the line menu), the chat is the HUD's last child: drawn over every
## HUD piece and hearing touches first (the see-through layer closes it). Closed, it goes back between its
## neighbours, under the overlays (the palette, the MORE panel) as before.
func _raise(on: bool) -> void:
	var parent := get_parent()
	if parent == null or on == _raised:
		return
	_raised = on
	if on:
		var i := get_index()
		_home_prev = parent.get_child(i - 1) if i > 0 else null
		_home_next = parent.get_child(i + 1) if i + 1 < parent.get_child_count() else null
		parent.move_child(self, -1)
	elif is_instance_valid(_home_next) and _home_next.get_parent() == parent:
		parent.move_child(self, _home_next.get_index())
	elif is_instance_valid(_home_prev) and _home_prev.get_parent() == parent:
		parent.move_child(self, _home_prev.get_index() + 1)

# --- M3 Task 21a: the game's lines in the child's language ------------------------------------------------------

## The game's own lines (replies, bot friends, errors) and the preset quick-chat phrases in this game's language;
## what a player typed stays exactly as typed (the history's labels never translate by themselves).
func in_my_language(text: String, kind: StringName) -> String:
	if kind != &"chat" or ChatRules.QUICK_PHRASES.has(text) or OnlineChatRules.WHEEL.has(text):
		return tr(text)
	return text

# --- M5 Task 1: the left hand's mirror (spec §15.1a) ---

## The Hud placed CHAT again: the bar runs right of pause, or (the left hand's mirror) from the left edge to pause;
## the lines follow.
func relayout() -> void:
	_bar.offset_left = 24.0 if HudLayout.left_handed else BAR_LEFT
	_bar.offset_right = -BAR_LEFT if HudLayout.left_handed else -24.0
	_fill_history()


## Where the lines go: the right hand's place, in a mirror for the left hand.
func _history_area() -> Rect2:
	var r := _history_area_right_hand()
	if HudLayout.left_handed:
		r.position.x = get_viewport_rect().size.x - r.end.x
	return r

## Never colour alone (M5 Task 1): the game's lines, errors and bot friends' lines carry a mark as well as their colour
## (in the game's own font); players' words are shown as they are.
const KIND_MARKS := {&"system": "» ", &"error": "! ", &"bot": "(bot) "}


static func mark(kind: StringName) -> String:
	return KIND_MARKS.get(kind, "")


func _shown_text(line: Dictionary) -> String:
	return mark(line.get("kind", &"chat")) + str(line.text)
