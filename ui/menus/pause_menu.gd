class_name PauseMenu
extends Control
## In-game pause overlay: Resume, Settings, Save & Quit. Pauses the tree while open.
## Sandbox worlds (on the host) also have the world setting MONSTERS: ON / OFF (M2 Task 4, §12.15).

signal save_and_quit_requested
signal opened
signal monsters_toggled(on: bool)

var _center := CenterContainer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_center)
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	PadFocus.watch(self)   # owner #90: RESUME first with a game controller; Circle / B resumes (pad_back)
	Vr.focus_changed.connect(_on_vr_focus)   # owner #101: the headset's own menu or the headset off pauses the game


func open() -> void:
	visible = true
	UiMotion.pop_in(self)   # owner #94: every panel pops in the same way
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_buttons()
	opened.emit()


## Owner #101: the headset lost the focus (the Quest's menu, the headset taken off): pause, as a phone does in the
## background; the focus back leaves the menu open (the child resumes when ready).
func _on_vr_focus(focused: bool) -> void:
	if not focused and not visible and is_inside_tree():
		open()


func close() -> void:
	visible = false
	get_tree().paused = false


## Owner #90: a game controller's Circle / B on the buttons resumes; on a page (SETTINGS, AVATAR…) its own BACK goes back.
func pad_back() -> bool:
	if not visible or not _on_buttons:
		return false
	close()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()


func _show_buttons() -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.add_child(ReadAloud.with_speaker(UiKit.title("Paused"), v))   # M3 Task 21a: the speaker reads the menu
	var resume := UiKit.big_button("RESUME", UiKit.GREEN, Vector2(WIDTH, 96))
	resume.pressed.connect(close)
	if discover_on:   # owner #132 (W1): DISCOVER, a picture beside RESUME (the menu keeps its height)
		v.add_child(_discover_row(resume))
	else:
		v.add_child(resume)
	var avatar := UiKit.big_button("AVATAR", UiKit.BLUE)   # M3 Task 9
	avatar.pressed.connect(_show_avatar)
	var settings := UiKit.big_button("SETTINGS", Color())
	settings.pressed.connect(_show_settings)
	v.add_child(_pair([avatar, settings]))
	# The world's own settings, side by side: MONSTERS (Sandbox, M2 Task 4) and FRIENDS (host, Task 15).
	var world_row: Array[Button] = []
	if _monsters_setting:
		world_row.append(_monsters_button())
	var friends_button := _friends_button()
	if friends_button:
		world_row.append(friends_button)
	if not world_row.is_empty():
		v.add_child(_pair(world_row))
	var me_row: Array[Button] = [_board_button()]   # M3 Task 12: the adventure board and trophies
	var invite := _invite_button()   # M4 C: the online host invites friends
	if invite:
		me_row.append(invite)
	var help := _help_button()   # owner #84, #90: KEYS on a PC, CONTROLLER with a game controller
	if help:
		me_row.append(help)
	v.add_child(_pair(me_row))
	var quit := UiKit.big_button("SAVE & QUIT", UiKit.ORANGE, Vector2(WIDTH, 86))
	quit.pressed.connect(func() -> void: save_and_quit_requested.emit())
	v.add_child(quit)
	_set_content(v)
	_on_buttons = true


const WIDTH := 420.0
const PAIR_GAP := 12


## One, two or three buttons on a row as wide as RESUME (the menu stays inside 720 px with every row).
func _pair(buttons: Array[Button]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PAIR_GAP)
	var w := (WIDTH - PAIR_GAP * (buttons.size() - 1)) / buttons.size()
	for b in buttons:
		b.custom_minimum_size = Vector2(w, 86)
		if buttons.size() > 1:
			b.add_theme_font_size_override("font_size", 24 if buttons.size() == 2 else 19)
		row.add_child(b)
	return row


## Owner #132 (W1): learning inside the world. The sandbox turns it on (every world but Monster Wave's arena); DISCOVER
## resumes and asks for the School over the world (DiscoveryDirector.open_discover).
signal discover_requested
var discover_on := false
const DISCOVER_WIDTH := 150.0


func _discover_row(resume: Button) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PAIR_GAP)
	resume.custom_minimum_size = Vector2(WIDTH - PAIR_GAP - DISCOVER_WIDTH, 96)
	row.add_child(resume)
	var discover := DiscoverButton.make(Vector2(DISCOVER_WIDTH, 96), 19)
	discover.pressed.connect(func() -> void:
		close()
		discover_requested.emit())
	row.add_child(discover)
	return row


## The avatar editor (M3 Task 9). In a Survivor world the host takes the gold for purchases.
func _show_avatar() -> void:
	var editor := AvatarEditor.new()
	editor.world_economy = Game.mode == ModeRules.SURVIVOR
	editor.closed.connect(_show_buttons)
	_set_content(editor)


func _show_settings() -> void:
	var s := SettingsPanel.new()
	s.closed.connect(_show_buttons)
	_set_content(s)


func _set_content(content: Control) -> void:
	_on_buttons = false
	for c in _center.get_children():
		c.queue_free()
	if content is KeysCard:   # a card of its own (owner #84, #90)
		_center.add_child(content)
		return
	var panel := PanelContainer.new()
	panel.add_child(content)
	_center.add_child(panel)

# --- Owner #84, #90: KEYS (a PC) or CONTROLLER (a game controller is plugged in or was used last) ---

var _on_buttons := false


## KEYS on a PC, CONTROLLER when a game controller is connected or was used last; null on a phone without one.
func _help_button() -> Button:
	var pad := PadFocus.pad_active() or not Input.get_connected_joypads().is_empty()
	if not pad and not PlatformRules.keyboard_first(PlatformRules.current()):
		return null
	var b := UiKit.big_button("CONTROLLER" if pad else "KEYS", UiKit.BLUE)
	b.name = "Help"
	b.pressed.connect(func() -> void: _show_help(pad))
	return b


func _show_help(pad: bool) -> void:
	var card := KeysCard.new(PadFocus.current_family() if pad else &"")
	card.closed.connect(_show_buttons)
	_set_content(card)

# --- M2 Task 4: the Sandbox world setting "Monsters: ON / OFF" ---

var _monsters_setting := false
var _monsters_on := true


## Shows the MONSTERS button (Sandbox worlds, host only), starting at `on`.
func show_monsters_setting(on: bool) -> void:
	_monsters_setting = true
	_monsters_on = on


func _monsters_button() -> Button:
	var b := UiKit.big_button(_monsters_text(), UiKit.BLUE)
	b.pressed.connect(func() -> void:
		_monsters_on = not _monsters_on
		b.text = _monsters_text()
		monsters_toggled.emit(_monsters_on))
	return b


func _monsters_text() -> String:
	return "MONSTERS: ON" if _monsters_on else "MONSTERS: OFF"

# --- M2 Task 15: the FRIENDS row (bot friends) ---

## The host's (and solo) bot friends; null on a LAN guest, whose menu has no FRIENDS row.
var friends: BotDirector


## FRIENDS n/3 (null on a LAN guest); it opens the FriendsPanel.
func _friends_button() -> Button:
	if friends == null:
		return null
	var b := UiKit.big_button(tr("FRIENDS  %d/%d") % [friends.bots().size(), BotRules.MAX_BOTS], UiKit.BLUE)
	b.name = "Friends"
	b.pressed.connect(_show_friends)
	return b


func _show_friends() -> void:
	var panel := FriendsPanel.new()
	panel.director = friends
	panel.closed.connect(_show_buttons)
	panel.raced.connect(close)   # M3 Task 7: off to START
	_set_content(panel)

# --- M4 C: the INVITE row (the host of an online world) ---

## Set by the sandbox once this game hosts a relayed match (Session.online_match_ready).
var online: OnlineService
var online_match := ""
var online_world := ""
var online_players := func() -> int: return Session.online_players()


## INVITE FRIENDS while hosting online with friends allowed (never for under-13 without consent).
func _invite_button() -> Button:
	if online == null or online_match == "" or not online.social_allowed():
		return null
	var b := UiKit.big_button("INVITE FRIENDS", OnlineUi.PURPLE)
	b.name = "Invite"
	b.pressed.connect(_show_invite)
	return b


func _show_invite() -> void:
	var panel := InvitePanel.new()
	panel.service = online
	panel.match_id = online_match
	panel.world_name = online_world
	panel.players = online_players
	panel.closed.connect(_show_buttons)
	_set_content(panel)

# --- M3 Task 12: the BOARD row (the adventure board, titles, presents and the trophy room) ---

## BOARD opens the adventure board. It shares its row with INVITE, so every menu still fits 720 px.
func _board_button() -> Button:
	var b := UiKit.big_button("BOARD", UiKit.GREEN)
	b.name = "Board"
	b.pressed.connect(_show_board)
	return b


func _show_board() -> void:
	var board := AdventureBoard.new()
	board.closed.connect(_show_buttons)
	_set_content(board)
