class_name MorePanel
extends Control
## The HUD's MORE panel (M2 Task 17): the buttons a child needs now and then (emotes, photos, the
## camera view, Size Magic, Mirror, Undo, the Physics Lab) as big picture buttons in a box beside the
## MORE button, so the screen keeps only what is used every minute. While open it hears touches before
## the HUD's other buttons (it sits above them): a touch on the box stays in the box, a touch anywhere
## else closes it and does nothing else. A button that opens something else (the emote wheel, photo
## mode) closes it; the others leave it open, so the child sees what changed (SIZE says TINY, MIRROR
## lights up). Pausing closes it.

signal opened
signal closed

const COLUMNS := 3
const MAX_ROWS := 4   # owner #78: more buttons than this many rows of COLUMNS take one more column (a 720 px screen)
const GAP := 10
const PAD := 12

var box := PanelContainer.new()
var grid := GridContainer.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.17, 0.97)   # nothing behind shows through
	style.border_color = Color(1, 1, 1, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(PAD)
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_STOP   # the touch's emulated click stays in the box
	add_child(box)
	HudLayout.place(box, &"more_panel")
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN   # from the MORE button's side, leftwards
	box.grow_vertical = Control.GROW_DIRECTION_END
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(grid)


## Adds a button to the box (in order); `closes`: pressing it also closes the panel.
func add(b: TouchButton, closes := false) -> void:
	b.custom_minimum_size = Vector2(HudLayout.BUTTON, HudLayout.BUTTON)
	grid.add_child(b)
	if closes:
		b.pressed.connect(close)


## Owner #78: three columns while four rows hold them, else four (a phone's Sandbox has 13 now: INVENT joined).
static func columns_for(n: int) -> int:
	return COLUMNS if n <= COLUMNS * MAX_ROWS else COLUMNS + 1


## The buttons in the box that show on this device, in order.
func buttons() -> Array[TouchButton]:
	var out: Array[TouchButton] = []
	for c in grid.get_children():
		if c is TouchButton and (c as TouchButton).visible:
			out.append(c)
	return out


func is_open() -> bool:
	return visible


func open() -> void:
	if visible:
		return
	grid.columns = columns_for(buttons().size())
	visible = true
	UiMotion.pop_in(self)   # owner #94: every panel pops in the same way
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		close()


## A new finger outside the box closes it; either way the HUD's buttons and the world behind never
## hear it. Lifts and drags go on to whoever holds that finger (the MORE button that opened it).
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var t := event as InputEventScreenTouch
	if t == null or not t.pressed:
		return
	if not box.get_global_rect().has_point(t.position):
		close()
	get_viewport().set_input_as_handled()


## M5 Task 1: beside MORE on the left hand's side too: the box grows away from MORE (the Hud placed it again).
func relayout() -> void:
	box.grow_horizontal = Control.GROW_DIRECTION_END if HudLayout.left_handed else Control.GROW_DIRECTION_BEGIN
