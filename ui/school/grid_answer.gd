class_name GridAnswer
extends VBoxContainer
## Owner #68, grade 5 maths (5.G.1-2): a "point" exercise's answer: tap a point on the coordinate grid (GridCheck, drawn
## as SchoolPictureG5's "grid"). A tap, with a finger or the mouse, picks the nearest crossing; the dot shows with its
## pair written under the grid ("You chose (4, 7)."), and another tap moves it; CHECK answers (ExercisePanel). A miss
## keeps the dot, so the child moves it; the second miss shows the right point. Every answer widget has: signal changed,
## response(), is_ready(), mark_wrong(), mark_right(), lock(), show_answer(answer).

signal changed

const AREA := Vector2(560, 380)
const PICK := Color("3a7be8")
const GOOD := Color("2fae4e")

var grid: Dictionary
var picked: Variant = null   # the Vector2i chosen
var view: GridView
var said: Label
var _locked := false
var _good := false


func _init(ex: Dictionary) -> void:
	grid = ex.get("grid", {})
	add_theme_constant_override("separation", 8)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view = GridView.new()
	view.owner_answer = self
	view.custom_minimum_size = AREA
	add_child(view)
	said = SchoolUi.words("Tap a point on the grid.", 26, AREA.x)
	said.name = "Chosen"
	add_child(said)


## Picks the grid's point p (a crossing of its lines).
func tap(p: Vector2i) -> void:
	if _locked or not GridCheck.on_grid(grid, p):
		return
	picked = p
	said.text = "You chose %s." % GridCheck.text(p)
	view.queue_redraw()
	changed.emit()


func response() -> Variant:
	return picked


func is_ready() -> bool:
	return picked != null


func mark_wrong() -> void:
	pass   # the dot stays, so the child can move it


func mark_right() -> void:
	_good = true
	view.queue_redraw()


func lock() -> void:
	_locked = true


func show_answer(answer: Variant) -> void:
	var p: Variant = GridCheck.point(answer)
	if p == null:
		return
	picked = p
	said.text = "The point is %s." % GridCheck.text(p)
	mark_right()


## The grid, drawn on a paper card; a press picks the nearest crossing (a finger is a mouse press: the project turns
## touches into mouse events).
class GridView:
	extends Control
	var owner_answer: GridAnswer
	## Owner #90: a game controller's cursor on the grid (a crossing), shown while the grid has the pad's focus.
	var pad_point := Vector2i.ZERO

	func _init() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	## Owner #90: the D-pad moves the cursor from crossing to crossing (past the grid's edge the focus moves on to the
	## buttons); Cross / A picks the point under it, as a tap there would.
	func pad_move(dir: Vector2i) -> bool:
		var f := frame()
		var s: Vector2i = f.step
		var n: Vector2i = f.lines
		var next := pad_point + Vector2i(dir.x * s.x, -dir.y * s.y)
		if next.x < 0 or next.y < 0 or next.x > n.x * s.x or next.y > n.y * s.y:
			return false
		pad_point = next
		queue_redraw()
		return true

	func pad_press() -> bool:
		owner_answer.tap(pad_point)
		return true

	func area() -> Rect2:
		return Rect2(Vector2.ZERO, size).grow(-SchoolPicture.MARGIN)

	func frame() -> Dictionary:
		return SchoolPictureG5.grid_frame(area(), owner_answer.grid)

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed:
			return
		var f := frame()
		var unit: float = f.unit
		var n: Vector2i = f.lines
		var corner := SchoolPictureG5.grid_at(f, Vector2i(0, 0))
		var reach := Rect2(corner - Vector2(0, n.y * unit), Vector2(n.x * unit, n.y * unit)).grow(maxf(unit * 0.6, 16.0))
		if reach.has_point(mb.position):
			owner_answer.tap(SchoolPictureG5.grid_value(f, mb.position))
		accept_event()

	func _draw() -> void:
		var paper := StyleBoxFlat.new()
		paper.bg_color = SchoolUi.PAPER
		paper.set_corner_radius_all(16)
		draw_style_box(paper, Rect2(Vector2.ZERO, size))
		var f := SchoolPictureG5.draw_grid(self, get_theme_default_font(), area(), owner_answer.grid)
		if has_focus(true):   # owner #90: the pad's cursor
			var cur := SchoolPictureG5.grid_at(f, pad_point)
			draw_arc(cur, clampf(float(f.unit) * 0.42, 12.0, 20.0), 0, TAU, 24, UiKit.FOCUS.darkened(0.25), 5.0, true)
		if owner_answer.picked is Vector2i:
			var at := SchoolPictureG5.grid_at(f, owner_answer.picked)
			var color := GOOD if owner_answer._good else PICK
			draw_arc(at, clampf(float(f.unit) * 0.34, 10.0, 17.0), 0, TAU, 24, color, 3.0, true)
			SchoolPictureG5.dot(self, at, float(f.unit) * 1.2, color)
