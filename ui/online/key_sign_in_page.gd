class_name KeySignInPage
extends VBoxContainer
## Owner #67 (spec §5.13, §17.1): PLAY ONLINE -> I HAVE AN ACCOUNT, after the parent gate. A grown-up types the
## child's online name and the sign-in key made in GROWN-UPS -> ONLINE PLAY -> OTHER DEVICES on a device where the
## child plays; OnlineService.sign_in_with_key links this device to that account, and the account's name, progress,
## looks and gold come here. The words are for grown-ups.
## Owner #99: MOVE YOUR GAME HERE's USE A KEY and LOG IN's USE A KEY open it with the name typed there (`username`);
## `finish` replaces the default sign-in (service.sign_in_with_key). The final review's 2: when the sign-in would make this
## device's player's gold and progress go (`goes`), the first SIGN IN asks (GUEST_GOES): YES / NO.

signal done     # signed in to the account
signal closed   # BACK

var service: OnlineService
var username := ""        # owner #99: the name typed before
## Owner #99: (username, key) -> "" or plain words; default service.sign_in_with_key.
var finish := Callable()
## (the typed name) -> whose gold and progress the sign-in makes go, or "" (OnlineService.progress_goes); none: never asks.
var goes := Callable()
var asking := ""   # the name asked about: YES signs in
var name_edit := LineEdit.new()
var key_edit := LineEdit.new()
var sign_in_button: Button
var back_button: Button
var message: Label
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	add_child(UiKit.title("Sign in with a key"))
	add_child(OnlineUi.words("Type your child's online name and the key made on the device where they play (GROWN-UPS, ONLINE PLAY, OTHER DEVICES). Their name, progress, looks and gold come to this device.", 24, 1100))
	_field(name_edit, "NAME", UsernameRules.MAX_LEN, "")
	name_edit.text = username
	_field(key_edit, "KEY", 12, "XXXX-XXXX")
	back_button = OnlineUi.button("BACK", UiKit.BLUE, Vector2(240, 88))
	back_button.pressed.connect(_back)   # asking: NO
	sign_in_button = OnlineUi.button("SIGN IN", UiKit.GREEN, Vector2(260, 88))
	sign_in_button.pressed.connect(_sign_in)
	add_child(OnlineUi.row([back_button, sign_in_button], 28))
	message = OnlineUi.words("", 24, 1000)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)
	_refresh()


func _field(edit: LineEdit, label: String, max_length: int, placeholder: String) -> void:
	var l := Label.new()
	l.text = label
	l.custom_minimum_size = Vector2(120, 0)
	l.add_theme_font_size_override("font_size", 28)
	edit.max_length = max_length
	edit.placeholder_text = placeholder
	edit.custom_minimum_size = Vector2(440, 76)
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.text_changed.connect(func(_t: String) -> void:
		_unask()
		_refresh())
	edit.text_submitted.connect(func(_t: String) -> void: if not sign_in_button.disabled: _sign_in())
	add_child(OnlineUi.row([l, edit]))


## SIGN IN once both fields could be right.
func ready_to_sign_in() -> bool:
	return UsernameRules.validate(UsernameRules.normalize(name_edit.text)) == "" \
		and key_edit.text.replace("-", "").replace(" ", "").length() == 8


func _refresh() -> void:
	if sign_in_button:
		sign_in_button.disabled = _busy or not ready_to_sign_in()


func _sign_in() -> void:
	if _busy:
		return
	if not ready_to_sign_in():
		message.text = "Type the online name and the key's 8 letters and numbers."
		return
	var name := UsernameRules.normalize(name_edit.text)
	if asking == "" and goes.is_valid():
		var who := str(goes.call(name))
		if who != "":
			asking = who
			message.text = DeviceMoveRules.GUEST_GOES % [who, name]
			sign_in_button.text = DeviceMoveRules.YES
			back_button.text = DeviceMoveRules.NO
			ReadAloud.auto(message.text)
			return
	_unask()
	_busy = true
	_refresh()
	message.text = "Signing in..."
	var err: String
	if finish.is_valid():
		err = await finish.call(name_edit.text, key_edit.text)
	else:
		err = await service.sign_in_with_key(name_edit.text, key_edit.text)
	_busy = false
	if not is_inside_tree():
		return
	_refresh()
	if err == "":
		done.emit()
		return
	message.text = err


## NO (or a field changed): the page as it was.
func _unask() -> void:
	if asking == "":
		return
	asking = ""
	message.text = ""
	sign_in_button.text = "SIGN IN"
	back_button.text = "BACK"


## BACK, or NO while asking (the page as it was).
func _back() -> void:
	if asking != "":
		_unask()
	else:
		closed.emit()
