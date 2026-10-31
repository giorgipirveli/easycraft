class_name MoveGamePage
extends VBoxContainer
## Owner #99 (spec §5.13 "As built (owner #99)"; module 0.2.20): MOVE YOUR GAME HERE, on the new device, with proof and
## never by the name alone. It asks the server for the account named (OnlineService.move_start) and shows the 6-digit
## code it gets, big: "On your other device: open EasyCraft, and type this code there." The account's own devices show a
## card where a grown-up types it (MoveAskCard). Once that code is right, the server hands this device a one-time key
## (move_status: a look every POLL_SECONDS, and at once when notification 110 says so) and `finish` signs in with it:
## "Welcome back, Anna! Your name, progress, looks and gold are here." A grown-up's key works too (USE A KEY: the parent
## gate, then KeySignInPage). The lead's security review (2026-10-15): this page is never told whether the other device
## is online or what it did, so it says only that the code works for 5 minutes; NEW CODE starts again at any time.

signal done                          # this device plays as the account now (OK on the welcome)
signal closed                        # BACK
signal key_wanted(username: String)  # USE A KEY

const ASKING := &"asking"
const WAITING := &"waiting"
const MOVING := &"moving"
const WELCOME := &"welcome"
const ENDED := &"ended"
const FAILED := &"failed"

var service: OnlineService
var username := ""
## How the move ends with the one-time key: (username, key) -> "" or plain words. Default: service.move_sign_in
## (this device's own new player becomes the account: a taken name's YES, IT'S ME). (The move rests: DeviceMoveRules.enabled.)
var finish := Callable()
var poll_seconds := DeviceMoveRules.POLL_SECONDS
var auto_poll := true   # tests: false (they call poll())

var state := &""
var ask_id := ""
var code := ""
var name_label: Label
var there_label: Label
var code_label: Label
var status_label: Label
var key_line: Label
var back_button: Button
var again_button: Button
var key_button: Button
var ok_button: Button

var _timer := Timer.new()
var _polling := false


func _ready() -> void:
	add_theme_constant_override("separation", 14)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 16)
	var pic := OnlineIcon.new(&"globe")
	pic.custom_minimum_size = Vector2(64, 64)
	head.add_child(pic)
	head.add_child(ReadAloud.with_speaker(UiKit.title(DeviceMoveRules.MOVE_TITLE), self, _read_aloud))
	add_child(head)
	name_label = OnlineUi.words(username, 34)
	name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # a name stays a name
	add_child(name_label)
	there_label = OnlineUi.words(DeviceMoveRules.TYPE_THERE, 28, 1000)
	add_child(there_label)
	code_label = OnlineUi.words("", 84, 700)
	code_label.name = "Code"
	code_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	code_label.add_theme_color_override("font_color", Color("ffffff"))
	add_child(code_label)
	status_label = OnlineUi.words("", 26, 1000)
	status_label.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(status_label)
	key_line = OnlineUi.words(DeviceMoveRules.HAVE_KEY, 22, 1000)
	add_child(key_line)
	back_button = OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 84))
	back_button.pressed.connect(_back)
	again_button = OnlineUi.button(DeviceMoveRules.NEW_CODE, UiKit.GREEN, Vector2(260, 84))
	again_button.pressed.connect(start)
	key_button = OnlineUi.button(DeviceMoveRules.USE_KEY, UiKit.ORANGE, Vector2(260, 84), &"grownup")
	key_button.add_theme_font_size_override("font_size", 24)
	key_button.pressed.connect(_use_key)
	ok_button = OnlineUi.button("OK", UiKit.GREEN, Vector2(260, 90))
	ok_button.pressed.connect(func() -> void: done.emit())
	add_child(OnlineUi.row([back_button, again_button, key_button, ok_button], 24))
	_timer.wait_time = poll_seconds
	_timer.timeout.connect(poll)
	add_child(_timer)
	if service and not service.move_nudged.is_connected(_on_nudged):
		service.move_nudged.connect(_on_nudged)
	start()


## Asks the server for a code (again: NEW CODE).
func start() -> void:
	if state == ASKING or state == MOVING:
		return
	if ask_id != "" and state == WAITING:
		service.move_cancel(ask_id)   # the old code stops (the account's card for it goes)
	ask_id = ""
	code = ""
	_show(ASKING, DeviceMoveRules.GETTING_CODE)
	var r: Dictionary = await service.move_start(username)
	if not is_inside_tree():
		return
	if str(r.get("text", "")) != "":
		_show(FAILED, str(r.text))
		return
	ask_id = str(r.id)
	code = str(r.code)
	_show(WAITING, DeviceMoveRules.WAITING)
	ReadAloud.auto(DeviceMoveRules.TYPE_THERE)
	if auto_poll:
		_timer.start()


## Looks at the ask once (the timer, a notification, tests).
func poll() -> void:
	if state != WAITING or _polling or ask_id == "":
		return
	_polling = true
	var r: Dictionary = await service.move_status(ask_id)
	_polling = false
	if not is_inside_tree() or state != WAITING:
		return
	match str(r.get("state", "")):
		"approved":
			await _finish(str(r.get("username", "")), str(r.get("key", "")))
		"ended", "done":
			_show(ENDED, DeviceMoveRules.ended_text(str(r.get("why", ""))))
		_:
			pass   # still waiting (or the network: the next look tries again)


func _on_nudged(_what: String) -> void:
	poll()


func _finish(account_name: String, key: String) -> void:
	_show(MOVING, DeviceMoveRules.MOVING)
	var named := account_name if UsernameRules.validate(account_name) == "" else username
	var err: String
	if finish.is_valid():
		err = await finish.call(named, key)
	else:
		err = await service.move_sign_in(named, key)
	if not is_inside_tree():
		return
	if err != "":
		_show(FAILED, err)
		return
	username = named
	_show(WELCOME, DeviceMoveRules.welcome_text(named))
	ReadAloud.auto(status_label.text)


func _use_key() -> void:
	if state == MOVING:
		return
	if ask_id != "" and state == WAITING:
		service.move_cancel(ask_id)
	ask_id = ""
	_timer.stop()
	key_wanted.emit(username)


func _back() -> void:
	if state == MOVING:
		return
	if ask_id != "" and state == WAITING:
		service.move_cancel(ask_id)
	_timer.stop()
	closed.emit()


func _show(s: StringName, words: String) -> void:
	state = s
	if s != WAITING:
		_timer.stop()
	status_label.text = words
	name_label.text = username
	code_label.text = DeviceMoveRules.pretty_code(code) if s == WAITING else ""
	code_label.visible = s == WAITING
	there_label.visible = s in [ASKING, WAITING]
	key_line.visible = s in [ASKING, WAITING, ENDED, FAILED]
	back_button.visible = s != WELCOME
	back_button.disabled = s == MOVING
	again_button.visible = s in [ENDED, FAILED]
	key_button.visible = s in [ASKING, WAITING, ENDED, FAILED]
	ok_button.visible = s == WELCOME


func _read_aloud() -> String:
	if state == WAITING:   # the digits one by one, so they can be typed while listening
		return "%s %s %s" % [Lang.t(DeviceMoveRules.TYPE_THERE), " ".join(code.split("")), Lang.t(DeviceMoveRules.WAITING)]
	return ReadAloud.words_of(self)
