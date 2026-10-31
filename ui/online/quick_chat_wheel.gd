class_name QuickChatWheel
extends Control
## The quick-chat wheel (M4 Wave 2, Agent E; spec §5.13, §17.4): the eight picture phrases of
## OnlineChatRules.WHEEL in big round slots around the middle of the screen, each with its picture
## (ChatPictures) and word. A tap on a slot sends that phrase; the middle closes it. Everyone can use
## it; under-13 players chat with it only. Optional pills beside it open the chat commands or the
## emotes. While open it takes every touch (it hears them before the HUD's buttons); a tap outside
## closes it and says where (the chat panel may have a message there to mute or report). Pausing
## closes it. Drawn like the emote wheel, no image files.
## Owner 38: a child with bot friends of their own gets a BOTS pill: the wheel's BOTS page holds picture
## phrases for their friends only (BotTalkWheel); CHAT goes back.

signal chosen(phrase: String)
signal closed
signal commands_requested
signal emotes_requested
signal tapped_outside(at: Vector2)

const RADIUS := 226.0
const SLOT := 136.0
const MIDDLE := 76.0
const PILL := Vector2(236, 82)
const PILL_GAP := 20.0
const FONT_SIZE := 22
const PILL_WORDS := {&"commands": "/ COMMANDS", &"emotes": "EMOTES", &"bots": "BOTS", &"chat": "CHAT"}
const PILL_COLORS := {&"commands": UiKit.BLUE, &"bots": UiKit.GREEN}

var _down := -2          # the slot or pill a finger went down on (-1: the middle, -2: none or outside)
var _pills: Array[StringName] = []
## Owner 38: &"chat" (the phrases for everyone) or &"bots" (for the child's own bot friends).
var page := &"chat"
var _with_commands := false
var _with_emotes := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


## Opens the wheel; with the COMMANDS and/or EMOTES pills beside it.
func open(with_commands: bool = false, with_emotes: bool = false) -> void:
	_pills.clear()
	page = &"chat"
	_with_commands = with_commands
	_with_emotes = with_emotes
	if with_commands:
		_pills.append(&"commands")
	if with_emotes:
		_pills.append(&"emotes")
	if has_bot_page():
		_pills.append(&"bots")   # owner 38
	_down = -2
	visible = true
	queue_redraw()


func close() -> void:
	if not visible:
		return
	visible = false
	_down = -2
	closed.emit()


func phrases() -> Array[String]:
	return BotTalkWheel.PHRASES if page == &"bots" else OnlineChatRules.WHEEL


## Owner 38: this game's player has bot friends of their own to talk to (the BOTS pill shows).
func has_bot_page() -> bool:
	return Session.has_own_bots()


## Owner 38: the BOTS page: picture phrases for the child's own bot friends (CHAT goes back).
func open_bots() -> void:
	page = &"bots"
	_pills.clear()
	_pills.append(&"chat")
	_down = -2
	visible = true
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and visible:
		close()


## The slots' rectangles (screen space), clockwise from the top.
func slot_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var c := _centre()
	var n := phrases().size()
	for i in n:
		var a := -PI * 0.5 + TAU * i / n
		var at := c + Vector2(cos(a), sin(a)) * RADIUS
		out.append(Rect2(at - Vector2(SLOT, SLOT) * 0.5, Vector2(SLOT, SLOT)))
	return out


## The pills' rectangles (screen space), right of the wheel, top to bottom.
func pill_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var c := _centre()
	var top := c.y - (_pills.size() * PILL.y + (_pills.size() - 1) * PILL_GAP) * 0.5
	for i in _pills.size():
		out.append(Rect2(Vector2(c.x + RADIUS + SLOT * 0.5 + 34.0, top + i * (PILL.y + PILL_GAP)), PILL))
	return out


func _centre() -> Vector2:
	var area := get_global_rect()
	if area.size == Vector2.ZERO:
		area = get_viewport_rect()
	return area.get_center()


## -1: the middle; 0..7: a slot; 100 + i: pill i; -2: nothing (outside).
func _hit(pos: Vector2) -> int:
	if pos.distance_to(_centre()) <= MIDDLE * 0.6:
		return -1
	var rects := slot_rects()
	for i in rects.size():
		if rects[i].get_center().distance_to(pos) <= SLOT * 0.55:
			return i
	var pills := pill_rects()
	for i in pills.size():
		if pills[i].has_point(pos):
			return 100 + i
	return -2


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_down = _hit(t.position)
		else:
			var hit := _hit(t.position)
			var was := _down
			if hit >= 0 and hit == was:
				_pick(hit)
			elif hit == -2 and was == -2:
				close()
				tapped_outside.emit(t.position)
			else:
				close()   # the middle, or a finger that slid off
		if is_inside_tree():
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if is_inside_tree():
			get_viewport().set_input_as_handled()


func _pick(hit: int) -> void:
	if hit >= 100:
		var pill := _pills[hit - 100]
		if pill == &"bots":
			open_bots()
			return
		if pill == &"chat":
			open(_with_commands, _with_emotes)
			return
		close()
		if pill == &"commands":
			commands_requested.emit()
		else:
			emotes_requested.emit()
		return
	var phrase := phrases()[hit]
	close()
	chosen.emit(phrase)


func _draw() -> void:
	var origin := get_global_rect().position
	var c := _centre() - origin
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	draw_circle(c, RADIUS + SLOT * 0.62, Color(0.08, 0.1, 0.17, 0.55))
	var font := get_theme_default_font()
	var rects := slot_rects()
	for i in rects.size():
		var r := Rect2(rects[i].position - origin, rects[i].size)
		var pressed := i == _down
		draw_circle(r.get_center(), SLOT * 0.5, Color(1, 1, 1, 0.9) if pressed else Color(0.2, 0.26, 0.4, 0.95))
		draw_arc(r.get_center(), SLOT * 0.5 - 2.0, 0.0, TAU, 48, Color(1, 0.85, 0.2) if pressed else Color(1, 1, 1, 0.85), 4.0, true)
		var phrase := phrases()[i]
		var picture := Rect2(r.position + Vector2(SLOT * 0.24, SLOT * 0.1), Vector2(SLOT * 0.52, SLOT * 0.52))
		var ink := Color(0.1, 0.12, 0.2) if pressed else Color.WHITE
		if page == &"bots":
			BotTalkWheel.draw(self, BotTalkWheel.PICTURES[phrase], picture, ink)
		else:
			ChatPictures.draw(self, OnlineChatRules.PICTURES[phrase], picture, ink)
		var at := Vector2(r.position.x - 20, r.end.y - 18)
		draw_string_outline(font, at, atr(phrase), HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 40, FONT_SIZE, 6, Color(0, 0, 0, 0.85))
		draw_string(font, at, atr(phrase), HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 40, FONT_SIZE, Color.WHITE)   # M3 Task 21a
	var pills := pill_rects()
	for i in pills.size():
		var p := Rect2(pills[i].position - origin, pills[i].size)
		var box := StyleBoxFlat.new()
		box.bg_color = PILL_COLORS.get(_pills[i], OnlineUi.PURPLE)
		box.set_corner_radius_all(18)
		draw_style_box(box, p)
		var word := atr(str(PILL_WORDS.get(_pills[i], "")))   # M3 Task 21a
		draw_string(font, p.position + Vector2(0, p.size.y * 0.5 + 9), word, HORIZONTAL_ALIGNMENT_CENTER, p.size.x, 26, Color.WHITE)
	# the middle: a close cross
	draw_circle(c, MIDDLE * 0.5, Color(0.85, 0.27, 0.23, 0.95))
	var k := MIDDLE * 0.18
	draw_line(c - Vector2(k, k), c + Vector2(k, k), Color.WHITE, 6.0, true)
	draw_line(c + Vector2(-k, k), c + Vector2(k, -k), Color.WHITE, 6.0, true)
