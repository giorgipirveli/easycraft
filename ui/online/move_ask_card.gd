class_name MoveAskCard
extends PanelContainer
## Owner #99 (spec §5.13 "As built (owner #99)"; module 0.2.20): on every device of the account, over every scene (the
## online service puts it on its own layer), when another device asks to play as this account: "Someone wants to play
## as Anna on a computer. If it's you, a grown-up types the code from that screen. Never type a code someone tells you."
## TYPE THE CODE opens the parent gate (as making a key does: ruling #67's safety), then a number pad for the 6 digits
## (OnlineService.move_approve: three wrong codes end the ask); NOT ME ends it. When the game went to another device it
## says so: "Your game is on a computer now too." (move_news). Pictures first, big buttons; it runs while paused.

const WIDTH := 760.0
const BYE_SECONDS := 4.0
const NEWS_SECONDS := 10.0
const KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "DEL", "0", "OK"]

const ASK := &"ask"
const GATE := &"gate"
const PAD := &"pad"
const BYE := &"bye"     # a last line (done, over, no), then it goes
const NEWS := &"news"

var service: OnlineService:
	set(s):
		if is_instance_valid(service):
			service.move_asks_changed.disconnect(_on_asks_changed)
			service.move_news.disconnect(show_news)
		service = s
		if is_instance_valid(s):
			s.move_asks_changed.connect(_on_asks_changed)
			s.move_news.connect(show_news)

var view := &""
var ask: Dictionary = {}       # the ask on the card
var box: VBoxContainer         # what the card shows now
var text_label: Label
var message: Label
var entry: Label
var type_button: Button
var not_me_button: Button
var gate: GrownUpGate
var pad_keys := {}             # key text -> Button

var _typed := ""
var _busy := false
var _timer := Timer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiKit.theme()
	visible = false
	add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.08, 0.22, 0.97), 22, 22))
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -WIDTH * 0.5
	offset_right = WIDTH * 0.5
	offset_top = 20
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	_timer.one_shot = true
	_timer.timeout.connect(_after_line)
	add_child(_timer)
	_on_asks_changed()


## The asks changed: the newest open one shows (while a grown-up types, the card stays with its ask).
func _on_asks_changed() -> void:
	if service == null:
		return
	if view in [GATE, PAD] and not _still_open(ask):
		_bye(DeviceMoveRules.ENDED_HERE)   # it ended meanwhile (5 minutes, or NEW CODE on the other device)
		return
	if view in [GATE, PAD, BYE, NEWS]:
		return
	if service.move_asks.is_empty():
		_hide()
		return
	show_ask(service.move_asks[service.move_asks.size() - 1])


func _still_open(a: Dictionary) -> bool:
	for x in service.move_asks:
		if x.id == a.get("id"):
			return true
	return false


func show_ask(a: Dictionary) -> void:
	ask = a
	var v := _page(ASK, &"lock")
	text_label = OnlineUi.words(DeviceMoveRules.ask_text(_name(), str(a.get("kind", ""))), 28, WIDTH - 140)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	(v.get_child(0) as HBoxContainer).add_child(text_label)
	var words := OnlineUi.words(DeviceMoveRules.ASK_IF, 24, WIDTH - 60)
	v.add_child(words)
	var never := OnlineUi.words(DeviceMoveRules.ASK_NEVER, 24, WIDTH - 60)
	never.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	v.add_child(never)
	type_button = OnlineUi.button(DeviceMoveRules.TYPE_CODE, UiKit.GREEN, Vector2(320, 84), &"grownup")
	type_button.pressed.connect(_show_gate)
	not_me_button = OnlineUi.button(DeviceMoveRules.NOT_ME, UiKit.RED, Vector2(240, 84))
	not_me_button.pressed.connect(_not_me)
	v.add_child(OnlineUi.row([type_button, not_me_button], 24))
	v.add_child(ReadAloud.button(func() -> String: return " ".join([text_label.text, words.text, never.text]), 56.0))
	ReadAloud.auto(text_label.text + " " + DeviceMoveRules.ASK_NEVER)


func _show_gate() -> void:
	var v := _page(GATE, &"")
	gate = GrownUpGate.new()
	gate.passed.connect(show_pad)
	gate.cancelled.connect(func() -> void: show_ask(ask))
	v.add_child(gate)


## The number pad for the 6 digits from the other screen.
func show_pad() -> void:
	_typed = ""
	var v := _page(PAD, &"")
	v.add_child(OnlineUi.words(DeviceMoveRules.PAD_PROMPT, 28, WIDTH - 60))
	entry = OnlineUi.words("_", 56, WIDTH - 60)
	entry.name = "Entry"
	v.add_child(entry)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	pad_keys.clear()
	for key in KEYS:
		var b := OnlineUi.button(key, UiKit.GREEN if key == "OK" else Color(), Vector2(150, 64))
		b.add_theme_font_size_override("font_size", 30)
		b.pressed.connect(press.bind(key))
		pad_keys[key] = b
		grid.add_child(b)
	var centre := CenterContainer.new()
	centre.add_child(grid)
	v.add_child(centre)
	var back := OnlineUi.button("BACK", UiKit.BLUE, Vector2(220, 64))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: show_ask(ask))
	v.add_child(back)
	_refresh_entry()


## A key of the pad (tests press them too).
func press(key: String) -> void:
	if view != PAD or _busy:
		return
	match key:
		"DEL":
			_typed = _typed.left(-1)
		"OK":
			_send()
			return
		_:
			if _typed.length() < DeviceMoveRules.CODE_DIGITS:
				_typed += key
	_refresh_entry()


func _refresh_entry() -> void:
	var shown := _typed + "_".repeat(DeviceMoveRules.CODE_DIGITS - _typed.length())
	entry.text = DeviceMoveRules.pretty_code(shown)
	(pad_keys["OK"] as Button).disabled = _typed.length() != DeviceMoveRules.CODE_DIGITS


func _send() -> void:
	if _typed.length() != DeviceMoveRules.CODE_DIGITS:
		return
	_busy = true
	var r: Dictionary = await service.move_approve(str(ask.get("id", "")), _typed)
	_busy = false
	if not is_inside_tree():
		return
	if r.get("done", false) or r.get("over", false):
		_bye(str(r.text))
		return
	message.text = str(r.text)   # a wrong code (tries left), or the network
	ReadAloud.auto(message.text)
	_typed = ""
	_refresh_entry()


func _not_me() -> void:
	if _busy:
		return
	_busy = true
	var err: String = await service.move_decline(str(ask.get("id", "")))
	_busy = false
	if is_inside_tree():
		_bye(err if err != "" else DeviceMoveRules.DECLINED_HERE)


## "Your game is on a computer now too." for a while (OK closes it sooner).
func show_news(text: String) -> void:
	if view in [GATE, PAD]:
		return   # a grown-up is typing: the news can wait for the card to close
	var v := _page(NEWS, &"friends")
	var l := OnlineUi.words(text, 28, WIDTH - 140)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	(v.get_child(0) as HBoxContainer).add_child(l)
	var ok := OnlineUi.button("OK", UiKit.GREEN, Vector2(200, 72))
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok.pressed.connect(_after_line)
	v.add_child(ok)
	ReadAloud.auto(text)
	_timer.start(NEWS_SECONDS)


func _bye(text: String) -> void:
	var v := _page(BYE, &"")
	v.add_child(OnlineUi.words(text, 28, WIDTH - 60))
	ReadAloud.auto(text)
	_timer.start(BYE_SECONDS)


func _after_line() -> void:
	_timer.stop()
	view = &""
	ask = {}
	_on_asks_changed()
	if view == &"":
		_hide()


func _hide() -> void:
	visible = false
	view = &""
	ask = {}
	if box:
		remove_child(box)
		box.queue_free()
		box = null


## A fresh content for the card; `icon` (or none) opens its first row.
func _page(v: StringName, icon: StringName) -> VBoxContainer:
	if box:
		remove_child(box)
		box.queue_free()
	view = v
	box = OnlineUi.column(12)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	if icon != &"":
		var pic := OnlineIcon.new(icon)
		pic.custom_minimum_size = Vector2(64, 64)
		top.add_child(pic)
	box.add_child(top)
	message = OnlineUi.words("", 24, WIDTH - 60)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(box)
	box.add_child(message)
	visible = true
	return box


func _name() -> String:
	var n := str(service.account.get("username", "")) if service else ""
	return n if n != "" else (service.profile.username if service and service.profile else "")


## The card's buttons, for the HUD's look area (a tap on them must not build).
func blockers() -> Array[Control]:
	return [self]
