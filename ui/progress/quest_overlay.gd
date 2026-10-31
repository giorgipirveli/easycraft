class_name QuestOverlay
extends Control
## Owner #45a: the base of the quest pages (the giver's card, the quest book): a dimmed screen with a box
## in the middle. While open it takes every new finger before the HUD's buttons and the world behind (it
## sits after the HUD in the canvas layer and takes touches in `_input`, like MorePanel); a finger outside
## the box closes it. Buttons in the box get the touch's mouse click as usual. Pausing closes it.

signal closed

const WIDTH := 1060.0
const WOOD := Color(0.12, 0.09, 0.16, 0.97)
const HINT := Color("c9d6ff")
const GOLD := Color("ffd23f")

var box := PanelContainer.new()
var content := VBoxContainer.new()
var box_width := WIDTH


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_stylebox_override("panel", UiKit.box(WOOD, 22, 16))
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.custom_minimum_size.x = box_width
	add_child(box)
	content.add_theme_constant_override("separation", 12)
	box.add_child(content)


func is_open() -> bool:
	return visible


func show_overlay() -> void:
	visible = true


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func blockers() -> Array[Control]:
	return [self]


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		close()


## A new finger outside the box closes the page; either way nothing behind it hears the touch.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var t := event as InputEventScreenTouch
	if t == null:
		if event is InputEventScreenDrag:
			get_viewport().set_input_as_handled()
		return
	if t.pressed and not box.get_global_rect().has_point(t.position):
		close()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()


func clear() -> void:
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()


## Every word on the page, labels and buttons (the tests read them).
func texts() -> Array[String]:
	var out: Array[String] = []
	for n in content.find_children("*", "Label", true, false):
		out.append((n as Label).text)
	for n in content.find_children("*", "Button", true, false):
		out.append((n as Button).text)
	return out


# --- Pieces ------------------------------------------------------------------------------------------

static func words(text: String, font: int, width: float = 0.0, color: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = width
	return l


static func row(gap: int = 14) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", gap)
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	return r


static func button(text: String, color: Color, min_size: Vector2, button_name: String) -> Button:
	var b := UiKit.big_button(text, color, min_size)
	b.name = button_name
	b.add_theme_font_size_override("font_size", 26)
	return b


## A step's little tile: its picture, a tick when done, a frame when it is the one being done.
static func step_tile(step: Dictionary, done: bool, current: bool, side: float = 76.0) -> PanelContainer:
	var p := PanelContainer.new()
	var col := Color(0.18, 0.5, 0.28, 0.95) if done else (Color(0.95, 0.62, 0.15, 0.95) if current else Color(0.25, 0.22, 0.3, 0.9))
	p.add_theme_stylebox_override("panel", UiKit.box(col, 14, 6))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := ProgressPicture.new(step.get("picture", &"question"), side)
	pic.dim = not done and not current
	p.add_child(pic)
	if done:
		var tick := Tick.new()
		tick.custom_minimum_size = Vector2(side, side)
		p.add_child(tick)
	return p


## A drawn tick over a done step's picture (no font needs the glyph).
class Tick:
	extends Control

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var u := minf(size.x, size.y)
		var pts := PackedVector2Array([Vector2(0.52, 0.72) * u, Vector2(0.68, 0.88) * u, Vector2(0.96, 0.56) * u])
		draw_polyline(pts, Color(0, 0, 0, 0.7), u * 0.16)
		draw_polyline(pts, Color("b9f6ca"), u * 0.1)
