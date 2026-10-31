class_name EmoteWheel
extends Control
## The emote wheel (M3 Task 9): eight big round slots around the middle of the screen, each with a
## little figure doing its emote (they move) and a short word. Tap one to do it; tap the middle or
## anywhere else to close. While open it takes every touch (it hears them before the HUD's buttons),
## so nothing behind it moves or builds. Pausing closes it.

signal chosen(emote_name: StringName)

const RADIUS := 215.0
const SLOT := 128.0
const MIDDLE := 70.0

## The emotes on the wheel, clockwise from the top (the look's wheel).
var emotes: Array[StringName] = []

var _t := 0.0
var _down := -2          # the slot a finger went down on (-1: the middle or outside)
var _font_size := 20


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false


func open(wheel: Array[StringName]) -> void:
	emotes = wheel.duplicate()
	_t = 0.0
	_down = -2
	visible = true
	UiMotion.pop_in(self)   # owner #94: every panel pops in the same way
	queue_redraw()


func close() -> void:
	visible = false
	_down = -2


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED and visible:
		close()


## The slots' rectangles (screen space), clockwise from the top.
func slot_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var c := _centre()
	for i in AvatarCatalog.WHEEL_SLOTS:
		var a := -PI * 0.5 + TAU * i / AvatarCatalog.WHEEL_SLOTS
		var at := c + Vector2(cos(a), sin(a)) * RADIUS
		out.append(Rect2(at - Vector2(SLOT, SLOT) * 0.5, Vector2(SLOT, SLOT)))
	return out


func _centre() -> Vector2:
	var area := get_global_rect()
	if area.size == Vector2.ZERO:
		area = get_viewport_rect()
	return area.get_center()


func _slot_at(pos: Vector2) -> int:
	var rects := slot_rects()
	for i in rects.size():
		if rects[i].get_center().distance_to(pos) <= SLOT * 0.55:
			return i
	return -1


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_down = _slot_at(t.position)
		elif _down == -2:
			return   # the finger that opened the wheel (on the button's touch-down) lifts: not ours
		else:
			var i := _slot_at(t.position)
			if i >= 0 and i == _down and i < emotes.size():
				var e := emotes[i]
				close()
				chosen.emit(e)
			else:
				close()   # the middle, outside, or a finger that slid off
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var c := _centre() - get_global_rect().position
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	draw_circle(c, RADIUS + SLOT * 0.62, Color(0.08, 0.1, 0.17, 0.55))
	var font := get_theme_default_font()
	var look := AvatarLook.new().resolve()
	var rects := slot_rects()
	for i in mini(rects.size(), emotes.size()):
		var r := Rect2(rects[i].position - get_global_rect().position, rects[i].size)
		var pressed := i == _down
		draw_circle(r.get_center(), SLOT * 0.5, Color(1, 1, 1, 0.9) if pressed else Color(0.2, 0.26, 0.4, 0.95))
		draw_arc(r.get_center(), SLOT * 0.5 - 2.0, 0.0, TAU, 48, Color(1, 0.85, 0.2) if pressed else Color(1, 1, 1, 0.85), 4.0, true)
		AvatarIcon.figure(self, Rect2(r.position + Vector2(SLOT * 0.18, SLOT * 0.04), Vector2(SLOT * 0.64, SLOT * 0.7)),
			look, EmotePoses.sample(emotes[i], _t))
		var word := atr(AvatarCatalog.display_name(AvatarCatalog.item_id(AvatarCatalog.EMOTE, emotes[i])))   # M3 Task 21a
		var at := Vector2(r.position.x - 20, r.end.y - 14)
		draw_string_outline(font, at, word, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 40, _font_size, 6, Color(0, 0, 0, 0.85))
		draw_string(font, at, word, HORIZONTAL_ALIGNMENT_CENTER, r.size.x + 40, _font_size, Color.WHITE)
	# the middle: a close cross
	draw_circle(c, MIDDLE * 0.5, Color(0.85, 0.27, 0.23, 0.95))
	var k := MIDDLE * 0.18
	draw_line(c - Vector2(k, k), c + Vector2(k, k), Color.WHITE, 6.0, true)
	draw_line(c + Vector2(-k, k), c + Vector2(k, -k), Color.WHITE, 6.0, true)
