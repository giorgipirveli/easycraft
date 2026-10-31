class_name BuildBoard
extends VBoxContainer
## Owner #68 (spec §22.1, ruling 6): "build the answer" with the game's blocks on a small board: tap a cell to place a
## block, tap it again to take it away, or slide a finger to paint (or clear) a line. A "wall" is built up from the
## ground (row 0 at the bottom); a "farm" is seen from above. Given blocks are there from the start and stay. The count
## shows as the child builds. BuildCheck checks it.

signal changed

const AREA := Vector2(560, 360)
const MAX_CELL := 56.0

var board: Dictionary
var goal: Dictionary
var given: Array[Vector2i] = []
var placed: Array[Vector2i] = []
var view: BoardView
var count_label: Label
var clear_button: Button
var _locked := false
var _answer_shown := false


func _init(ex: Dictionary) -> void:
	board = ex.get("board", {})
	goal = ex.get("goal", {})
	given = BuildCheck.given(board)
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	view = BoardView.new()
	view.owner_board = self
	view.custom_minimum_size = AREA
	add_child(view)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	count_label = SchoolUi.words("", 28, 260)
	row.add_child(count_label)
	clear_button = SchoolUi.button("CLEAR", UiKit.BLUE, Vector2(200, 64))
	clear_button.pressed.connect(clear)
	row.add_child(clear_button)
	add_child(row)
	_refresh()


func toggle(c: Vector2i) -> void:
	paint(c, not placed.has(c))


## Places (on) or takes away (off) the block at c; given blocks never go.
func paint(c: Vector2i, on: bool) -> void:
	if _locked or given.has(c) or not BuildCheck.inside(board, c) or placed.has(c) == on:
		return
	if on:
		placed.append(c)
	else:
		placed.erase(c)
	_refresh()
	changed.emit()


func clear() -> void:
	if _locked:
		return
	placed.clear()
	_refresh()
	changed.emit()


## Every block on the board, given ones included.
func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = given.duplicate()
	out.append_array(placed)
	return out


func response() -> Variant:
	return cells()


func is_ready() -> bool:
	return not placed.is_empty()


func mark_wrong() -> void:
	pass   # the build stays, so the child can change it


func mark_right() -> void:
	view.good = true
	view.queue_redraw()


func lock() -> void:
	_locked = true
	clear_button.disabled = true


func show_answer(answer: Variant) -> void:
	placed.clear()
	for c: Variant in answer:
		if c is Vector2i and not given.has(c):
			placed.append(c)
	_answer_shown = true
	mark_right()
	_refresh()


func _refresh() -> void:
	var n := cells().size()
	if str(goal.get("kind", "")) == "fraction":
		count_label.text = "%d of %d blocks" % [n, int(board.get("cols", 0)) * int(board.get("rows", 0))]
	else:
		count_label.text = Lang.blocks(n)
	view.queue_redraw()


## The board's cells, drawn with the board's block; taps and slides go back to the BuildBoard.
class BoardView:
	extends Control
	var owner_board: BuildBoard
	var good := false
	var _painting := false
	var _paint_on := true
	## Owner #90: a game controller's cursor on the board (a cell), shown while the board has the pad's focus.
	var pad_cell := Vector2i.ZERO

	func _init() -> void:
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	## Owner #90: the D-pad moves the cursor from cell to cell (past the board's edge the focus moves on to CLEAR and
	## CHECK); Cross / A places a block there or takes it away, as a tap would.
	func pad_move(dir: Vector2i) -> bool:
		var up_is_more := str(owner_board.board.get("view", "wall")) == "wall"   # a wall's row 0 is at the bottom
		var next := pad_cell + Vector2i(dir.x, -dir.y if up_is_more else dir.y)
		if not BuildCheck.inside(owner_board.board, next):
			return false
		pad_cell = next
		queue_redraw()
		return true

	func pad_press() -> bool:
		owner_board.toggle(pad_cell)
		return true

	func cell_size() -> float:
		var b := owner_board.board
		return minf(MAX_CELL, minf(size.x / maxi(int(b.get("cols", 1)), 1), size.y / maxi(int(b.get("rows", 1)), 1)))

	func origin() -> Vector2:
		var b := owner_board.board
		var c := cell_size()
		return (size - Vector2(int(b.get("cols", 1)), int(b.get("rows", 1))) * c) * 0.5

	## The cell under a point, or (-1, -1).
	func cell_at(p: Vector2) -> Vector2i:
		var b := owner_board.board
		var c := cell_size()
		var local := (p - origin()) / c
		if local.x < 0 or local.y < 0:
			return Vector2i(-1, -1)
		var x := int(local.x)
		var row_from_top := int(local.y)
		var rows := int(b.get("rows", 1))
		var y := rows - 1 - row_from_top if str(b.get("view", "wall")) == "wall" else row_from_top
		return Vector2i(x, y)

	func cell_rect(cell: Vector2i) -> Rect2:
		var b := owner_board.board
		var c := cell_size()
		var rows := int(b.get("rows", 1))
		var top := rows - 1 - cell.y if str(b.get("view", "wall")) == "wall" else cell.y
		return Rect2(origin() + Vector2(cell.x, top) * c, Vector2(c, c))

	func _gui_input(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb and mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				var cell := cell_at(mb.position)
				if BuildCheck.inside(owner_board.board, cell):
					_painting = true
					_paint_on = not owner_board.cells().has(cell)
					owner_board.paint(cell, _paint_on)
			else:
				_painting = false
			accept_event()
		var mm := event as InputEventMouseMotion
		if mm and _painting and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT):
			var cell := cell_at(mm.position)
			if BuildCheck.inside(owner_board.board, cell):
				owner_board.paint(cell, _paint_on)
			accept_event()

	func _draw() -> void:
		var b := owner_board.board
		var cols := int(b.get("cols", 1))
		var rows := int(b.get("rows", 1))
		var c := cell_size()
		var o := origin()
		var wall := str(b.get("view", "wall")) == "wall"
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("bfe3f5") if wall else Color("a5d67a")
		bg.set_corner_radius_all(12)
		draw_style_box(bg, Rect2(o - Vector2(10, 10), Vector2(cols, rows) * c + Vector2(20, 20)))
		if wall:
			draw_rect(Rect2(o + Vector2(-10, rows * c), Vector2(cols * c + 20, 10)), Color("5a9a32"))
		for y in rows:
			for x in cols:
				draw_rect(cell_rect(Vector2i(x, y)).grow(-2), Color(1, 1, 1, 0.35), false, 1.5)
		var tex := BlockIcons.icon(int(b.get("block", BlockIds.BRICK)))
		for cell in owner_board.given:
			var r := cell_rect(cell).grow(-1)
			if tex:
				draw_texture_rect(tex, r, false, Color(0.62, 0.62, 0.68))
			draw_rect(r, SchoolUi.INK, false, 2.0)
		for cell in owner_board.placed:
			var r := cell_rect(cell).grow(-1)
			if tex:
				draw_texture_rect(tex, r, false)
			else:
				draw_rect(r, UiKit.ORANGE)
			draw_rect(r, Color("2fae4e") if good else Color(0, 0, 0, 0.4), false, 3.0 if good else 1.5)
		if has_focus(true):   # owner #90: the pad's cursor
			draw_rect(cell_rect(pad_cell).grow(3), UiKit.FOCUS, false, 5.0)
		var mirror := str(owner_board.goal.get("kind", "")) == "mirror"
		if mirror:
			var mx := o.x + (int(owner_board.goal.get("sum", cols - 1)) + 1) * 0.5 * c
			draw_dashed_line(Vector2(mx, o.y - 8), Vector2(mx, o.y + rows * c + 8), Color("d9463b"), 3.0, 10.0)
