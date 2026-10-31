class_name LogInPage
extends VBoxContainer
## Owner #99, #105 (spec §5.13 "As built (owner #99, #105)"): LOG IN with the online name and the password, on any device:
## PLAY ONLINE's I HAVE AN ACCOUNT and a taken name's YES, IT'S ME (this device's own player becomes the account), the
## main menu's and the start screen's LOG IN (AccountsFlow), and a logged-out device ("This device was logged out. LOG IN to
## play here."). Its other devices are logged out then. FORGOT PASSWORD? says what to do;
## USE A KEY is a grown-up's way in (the parent gate, then KeySignInPage). The host does the log-in (`log_in`).
## The final review's 2: when LOG IN would make this device's player's gold and progress go (`goes`), the first LOG IN asks:
## "Pip's gold and progress on this device will go. Your worlds stay. Log in as Anna?" YES / NO (NO: the page again).

signal log_in(username: String, password: String)
signal key_wanted(username: String)
signal closed   # BACK

var username := ""   # the name already typed (a taken name's, a logged-out device's)
var note := ""       # a line above (LOGGED_OUT)
## (the typed name) -> whose gold and progress LOG IN as it makes go, or "" (OnlineService.progress_goes); none: never asks.
var goes := Callable()
## The name asked about (GUEST_GOES): YES logs in; "" = not asking.
var asking := ""

var name_edit := LineEdit.new()
var password: PasswordField
var log_in_button: Button
var back_button: Button
var forgot_button: Button
var key_button: Button
var help_row: HBoxContainer   # FORGOT PASSWORD? and USE A KEY (hidden while asking)
var message: Label
var busy := false:
	set(v):
		busy = v
		_refresh()


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	var title := UiKit.title(PasswordRules.LOG_IN_TITLE)
	add_child(ReadAloud.with_speaker(title, self))
	var words := OnlineUi.words(note if note != "" else PasswordRules.LOG_IN_WORDS, 26, 1000)
	if note != "":
		words.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(words)
	var name_row := HBoxContainer.new()
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_theme_constant_override("separation", 14)
	var l := Label.new()
	l.text = "NAME"
	l.custom_minimum_size = Vector2(170, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_font_size_override("font_size", 26)
	name_row.add_child(l)
	name_edit.max_length = UsernameRules.MAX_LEN
	name_edit.custom_minimum_size = Vector2(420, 72)
	name_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_edit.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # a name stays a name
	name_edit.text = username
	name_edit.text_changed.connect(func(_t: String) -> void:
		_unask()
		_refresh())
	name_row.add_child(name_edit)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(150, 0)
	name_row.add_child(spacer)
	add_child(name_row)
	password = PasswordField.make(PasswordRules.PASSWORD)
	password.edit.text_changed.connect(func(_t: String) -> void:
		_unask()
		_refresh())
	password.submitted.connect(_go)
	add_child(password)
	message = OnlineUi.words(PasswordRules.ONE_DEVICE, 24, 1000)   # owner #105: said before it happens
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	back_button = OnlineUi.button("BACK", UiKit.BLUE, Vector2(200, 84))
	back_button.pressed.connect(_back)   # asking: NO
	log_in_button = OnlineUi.button(DeviceMoveRules.LOG_IN, UiKit.GREEN, Vector2(240, 84), &"globe")
	log_in_button.pressed.connect(_go)
	add_child(OnlineUi.row([back_button, log_in_button], 24))
	forgot_button = OnlineUi.button(PasswordRules.FORGOT, Color(), Vector2(300, 64))
	forgot_button.add_theme_font_size_override("font_size", 22)
	forgot_button.pressed.connect(func() -> void:
		message.text = PasswordRules.FORGOT_WORDS
		ReadAloud.auto(PasswordRules.FORGOT_WORDS))
	key_button = OnlineUi.button(DeviceMoveRules.USE_KEY, UiKit.ORANGE, Vector2(260, 64), &"grownup")
	key_button.add_theme_font_size_override("font_size", 22)
	key_button.pressed.connect(func() -> void: key_wanted.emit(typed()))
	help_row = OnlineUi.row([forgot_button, key_button], 20)
	add_child(help_row)
	_refresh()
	if username != "":
		password.edit.grab_focus.call_deferred()


func typed() -> String:
	return UsernameRules.normalize(name_edit.text)


func _refresh() -> void:
	if log_in_button:
		log_in_button.disabled = busy or UsernameRules.validate(typed()) != "" or password.text.length() < 1
		back_button.disabled = busy


func _go() -> void:
	if busy:
		return
	var name := typed()
	var code := UsernameRules.validate(name)
	if code != "":
		message.text = UsernameRules.message(code)
		return
	if password.text == "":
		message.text = PasswordRules.message("password_needed")
		return
	if asking == "" and goes.is_valid():
		var who := str(goes.call(name))
		if who != "":
			_ask(who, name)
			return
	_unask()
	message.add_theme_color_override("font_color", Color("ff8a80"))   # from now on: an answer, maybe a refusal
	message.text = PasswordRules.LOGGING_IN
	log_in.emit(name, password.text)


## The final review's 2: "Pip's gold and progress on this device will go. Your worlds stay. Log in as Anna?" YES / NO.
func _ask(who: String, name: String) -> void:
	asking = who
	message.add_theme_color_override("font_color", Color.WHITE)
	message.text = DeviceMoveRules.GUEST_GOES % [who, name]
	log_in_button.text = DeviceMoveRules.YES
	back_button.text = DeviceMoveRules.NO
	help_row.visible = false
	ReadAloud.auto(message.text)


## NO (or the name or the password changed): the page as it was.
func _unask() -> void:
	if asking == "":
		return
	asking = ""
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	message.text = PasswordRules.ONE_DEVICE
	log_in_button.text = DeviceMoveRules.LOG_IN
	back_button.text = "BACK"
	help_row.visible = true


## BACK, or NO while asking (the page as it was).
func _back() -> void:
	if asking != "":
		_unask()
	else:
		closed.emit()
