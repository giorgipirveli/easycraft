class_name BottlePage
extends VBoxContainer
## Bottle mail (M4 Wave 3, agent I; research D5): the child picks a quick-chat phrase (the wheel's eight,
## with their pictures; never free text) and maybe one of their tiny builds (at most 4 x 4 x 4) to put in
## the bottle, then SEND. The bottle floats up near the friend's spawn next time they play.

signal send_requested(phrase: String, build: String)

var shelf: Array = []             # tiny builds (BuildCodec texts) the child may add
var friend_name := ""
var phrase := ""
var build := ""

var _phrases: Array[Button] = []
var _builds: Array[Button] = []
var _send: Button


func _ready() -> void:
	add_theme_constant_override("separation", 12)
	add_child(OnlineUi.words(tr("A bottle for %s: what does it say?") % friend_name, 26, 900))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for p in OnlineChatRules.WHEEL:
		var b := OnlineUi.button(p, Color(), Vector2(210, 56))
		b.name = "Phrase_" + p.replace("!", "").replace("'", "").replace(" ", "_")
		b.add_theme_font_size_override("font_size", 24)
		b.toggle_mode = true
		b.pressed.connect(_pick_phrase.bind(p))
		grid.add_child(b)
		_phrases.append(b)
	var centre := CenterContainer.new()
	centre.add_child(grid)
	add_child(centre)
	var row: Array = []   # the tiny builds and SEND share one row
	if not shelf.is_empty():
		row.append(OnlineUi.words("A tiny build too?", 22, 200))
		for i in mini(shelf.size(), 3):
			var t: String = shelf[shelf.size() - 1 - i]
			var b := OnlineUi.button(tr("BUILD %d") % (i + 1), UiKit.GREEN, Vector2(170, 64))
			b.name = "Tiny%d" % (i + 1)
			b.toggle_mode = true
			b.pressed.connect(_pick_build.bind(t, b))
			_builds.append(b)
			row.append(b)
	_send = OnlineUi.button("SEND", UiKit.ORANGE, Vector2(220, 64))
	_send.name = "Send"
	_send.disabled = true
	_send.pressed.connect(func() -> void: send_requested.emit(phrase, build))
	row.append(_send)
	add_child(OnlineUi.row(row, 12))


func _pick_phrase(p: String) -> void:
	phrase = p
	for b in _phrases:
		b.button_pressed = b.text == p
	_send.disabled = false


func _pick_build(t: String, pressed: Button) -> void:
	build = "" if build == t else t
	for b in _builds:
		b.button_pressed = b == pressed and build != ""
