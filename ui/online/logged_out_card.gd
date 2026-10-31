class_name LoggedOutCard
extends PanelContainer
## Owner #105: over every scene (the online service puts it on its own layer) when this device's account was logged in on
## another device: "You logged in on another device. LOG IN to play here." Everything played here stays on this device
## and goes up at the next log-in here. LOG IN opens LOG IN with the name (AccountsOverlay); LATER hides it (offline play
## goes on; PLAY ONLINE says it again). Owner #105 too: "Someone tried to log in as you on a new device. If it wasn't you, a
## grown-up can change your password." (OK).
## The final review's 3 and 7: NEW PLAYER asks first (NEW_PLAYER_ASK: YES / NO); LOG IN and NEW PLAYER show on the main
## menu only (in a world its files are open: "Go to the main menu to LOG IN."); the saved line names the account.

const WIDTH := 760.0

var service: OnlineService
var text_label: Label
var log_in_button: Button
var new_player_button: Button
var later_button: Button
var saved_label: Label
var menu_label: Label   # in a world: LOGGED_OUT_MENU
var asking := false     # NEW PLAYER asked: YES / NO
var _logged_out := false
## Whether the main menu is open (tests: a Callable () -> bool; default AccountsOverlay.on_main_menu).
var on_menu := Callable()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiKit.theme()
	add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.08, 0.22, 0.97), 22, 22))
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -WIDTH * 0.5
	offset_right = WIDTH * 0.5
	offset_top = 20
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	var v := OnlineUi.column(12)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	var pic := OnlineIcon.new(&"lock")
	pic.custom_minimum_size = Vector2(64, 64)
	top.add_child(pic)
	text_label = OnlineUi.words(PasswordRules.LOGGED_OUT, 28, WIDTH - 140)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(text_label)
	v.add_child(top)
	saved_label = OnlineUi.words(_saved_text(), 22, WIDTH - 60)
	saved_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # it has the name in it
	v.add_child(saved_label)
	menu_label = OnlineUi.words(PasswordRules.LOGGED_OUT_MENU, 24, 460)   # beside LATER: the card stays short
	menu_label.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	log_in_button = OnlineUi.button(DeviceMoveRules.LOG_IN, UiKit.GREEN, Vector2(220, 80), &"globe")
	log_in_button.pressed.connect(_log_in)
	# Owner #105 (the second review): a child whose account was deleted on another device would be stuck here (LOG IN can
	# never work, and the device can't tell "deleted" from "logged out"); NEW PLAYER is always a way on.
	new_player_button = OnlineUi.button(DeviceMoveRules.NEW_PLAYER, OnlineUi.PURPLE, Vector2(240, 80))
	new_player_button.add_theme_font_size_override("font_size", 22)
	new_player_button.pressed.connect(_new_player)
	later_button = OnlineUi.button(PasswordRules.LATER, UiKit.BLUE, Vector2(180, 80))
	later_button.pressed.connect(_later)
	v.add_child(OnlineUi.row([log_in_button, new_player_button, menu_label, later_button], 18))
	add_child(v)
	if Vr.active():   # owner #101: in a headset the card comes to the eye panel and the controllers reach its buttons
		PadFocus.watch(self)
	Vr.started.connect(func() -> void: PadFocus.watch(self))


## LOGGED_OUT (LOG IN and LATER) or another note (OK).
func show_text(text: String) -> void:
	if not is_node_ready():
		await ready
	_logged_out = text == PasswordRules.LOGGED_OUT
	asking = false
	text_label.text = text
	saved_label.text = _saved_text()
	new_player_button.text = DeviceMoveRules.NEW_PLAYER
	later_button.text = PasswordRules.LATER if _logged_out else "OK"
	_refresh()
	ReadAloud.auto(text)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_refresh()


## LOG IN and NEW PLAYER on the main menu only (the final review's 7); a world says where they are. Asking (NEW PLAYER's
## YES / NO) ends when a world opens.
func _refresh() -> void:
	var menu := _menu()
	if asking and not menu:
		show_text(PasswordRules.LOGGED_OUT)
		return
	saved_label.visible = _logged_out and not asking
	menu_label.visible = _logged_out and not menu
	log_in_button.visible = _logged_out and menu and not asking
	new_player_button.visible = _logged_out and menu


func _menu() -> bool:
	return bool(on_menu.call()) if on_menu.is_valid() else AccountsOverlay.on_main_menu(self)


func _saved_text() -> String:
	var name := service.prefs.account_name if service != null else ""
	return PasswordRules.LOGGED_OUT_SAVED % name if name != "" \
		else PasswordRules.LOGGED_OUT_SAVED.replace(" as %s", "")


## LATER (or OK) hides the card; NO (asking) shows it as it was.
func _later() -> void:
	if asking:
		show_text(PasswordRules.LOGGED_OUT)
		return
	(get_parent() as CanvasLayer).visible = false


func _log_in() -> void:
	if not _menu():
		return   # a world's files are open (the button is hidden there)
	(get_parent() as CanvasLayer).visible = false
	AccountsOverlay.open(self, service, AccountsFlow.VIEW_LOG_IN)


## Owner #105: a way on for a child whose account was deleted elsewhere (or who wants to start again): this device forgets
## the account and the player (the worlds stay), and the start screen opens. The account, if it still exists, is safe on
## the server: LOG IN brings it back.
func _new_player() -> void:
	if not _menu():
		return   # a world's files are open (the button is hidden there)
	if not asking:   # the final review's 3: asked first
		asking = true
		text_label.text = DeviceMoveRules.NEW_PLAYER_ASK
		new_player_button.text = DeviceMoveRules.YES
		later_button.text = DeviceMoveRules.NO
		_refresh()
		ReadAloud.auto(DeviceMoveRules.NEW_PLAYER_ASK)
		return
	asking = false
	(get_parent() as CanvasLayer).visible = false
	service.forget_player()
	AccountsOverlay.to_menu()


## The card's buttons, for the HUD's look area (a tap on them must not build).
func blockers() -> Array[Control]:
	return [self]
