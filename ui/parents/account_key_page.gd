class_name AccountKeyPage
extends VBoxContainer
## OTHER DEVICES, a page of the grown-up area behind the parent gate (owner #67; spec §5.13, §17.1): the account on
## every device. MAKE A KEY shows the child's online name and a sign-in key (8 letters and numbers) once, big; on a
## new phone, a tablet or a browser, PLAY ONLINE -> I HAVE AN ACCOUNT takes the two, and the name, progress, looks
## and gold come there. A new key stops the one before. SIGN OUT OTHER DEVICES (held 2 s) is for a lost phone: every
## other device of the account stops signing in. The server keeps only the key's salted hash.

signal closed   # BACK

const HOLD_SECONDS := 2.0

var service: OnlineService
var make_button: Button
var back_button: Button
var hold: HoldButton
var key_label: Label
var state_label: Label
var message: Label
var _busy := false


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	if service == null or service.status != OnlineService.ONLINE:
		add_child(_line(OnlineRules.message("not_signed_in")))
		_buttons([])
		return
	add_child(_line("To play on another phone, tablet or computer with this account, make a key. There: PLAY ONLINE, I HAVE AN ACCOUNT, then the name and the key. Name, progress, looks and gold come along; worlds stay on each device."))
	key_label = OnlineUi.words("", 34, 1100)
	key_label.visible = false
	add_child(key_label)
	state_label = _line("")
	add_child(state_label)
	make_button = OnlineUi.button("MAKE A KEY", UiKit.GREEN, Vector2(300, 84))
	make_button.pressed.connect(_make)
	hold = HoldButton.new()
	hold.text = "HOLD: SIGN OUT OTHER DEVICES"
	hold.hold_seconds = HOLD_SECONDS
	hold.add_theme_font_size_override("font_size", 22)
	hold.custom_minimum_size = Vector2(440, 84)
	hold.held.connect(_sign_out_others)
	_buttons([make_button, hold])
	_load_state()


func _buttons(extra: Array) -> void:
	back_button = OnlineUi.button("BACK", UiKit.BLUE, Vector2(200, 84))
	back_button.pressed.connect(func() -> void: closed.emit())
	add_child(OnlineUi.row([back_button] + extra, 24))
	message = OnlineUi.words("", 24, 1100)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(message)


func _line(text: String) -> Label:
	return OnlineUi.words(text, 24, 1100)


func _load_state() -> void:
	_busy = true
	var r: Dictionary = await service.account_key_state()
	_busy = false
	if not is_inside_tree():
		return
	if r.text != "":
		message.text = r.text
		return
	_show_state(bool(r.get("has_key", false)), int(r.get("devices", 1)))


func _show_state(has_key: bool, devices: int) -> void:
	var said := "A key was made before: a new key stops the old one." if has_key else "No key yet."
	state_label.text = "%s Devices signed in now: %d." % [said, devices]
	make_button.text = "MAKE A NEW KEY" if has_key else "MAKE A KEY"


func _make() -> void:
	if _busy:
		return
	_busy = true
	make_button.disabled = true
	message.text = "One moment..."
	var r: Dictionary = await service.make_account_key()
	_busy = false
	if not is_inside_tree():
		return
	make_button.disabled = false
	if r.text != "":
		message.text = r.text
		return
	key_label.text = "%s   %s" % [str(r.get("username", "")), str(r.get("key", ""))]
	key_label.visible = true
	_show_state(true, int(r.get("devices", 1)))
	state_label.visible = false   # the key in its place (the page fits the menu's panel)
	message.text = "Write it down. Keep it safe like a password: the name and the key open your child's account."


func _sign_out_others() -> void:
	if _busy:
		return
	_busy = true
	hold.disabled = true
	message.text = "Signing out the other devices..."
	var err: String = await service.sign_out_other_devices()
	_busy = false
	if not is_inside_tree():
		return
	hold.disabled = false
	if err != "":
		message.text = err
		return
	message.text = "Every other device is signed out. This one stays signed in."
	_load_state()
