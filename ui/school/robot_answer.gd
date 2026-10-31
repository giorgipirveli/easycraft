class_name RobotAnswer
extends VBoxContainer
## The research's "code the robot" (docs/design/school-curriculum-research.md §5.3): the board (RobotCheck) with the
## robot facing its way, walls, gems and the flag; beside it FORWARD, LEFT, RIGHT, UNDO and CLEAR write the program,
## shown under the board as numbered arrows. CHECK runs it; a miss keeps the program and draws where the robot went
## (and where it bumped), so the child can find the bug and fix it.

signal changed

const CELL_MAX := 40.0
const BOARD_MAX := Vector2(320, 320)
const BUTTON := Vector2(170, 64)

var board: Dictionary
var program: Array[String] = []
## The last run CHECK made (RobotCheck.run), {} before one.
var last_run := {}
var forward_button: Button
var left_button: Button
var right_button: Button
var undo_button: Button
var clear_button: Button
var view: BoardView
var strip: ProgramStrip
var _locked := false


func _init(ex: Dictionary) -> void:
	board = ex.get("board", {})
	add_theme_constant_override("separation", 10)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	view = BoardView.new(self)
	row.add_child(view)
	var keys := VBoxContainer.new()
	keys.add_theme_constant_override("separation", 6)
	forward_button = _key("FORWARD", "F", UiKit.GREEN)
	left_button = _key("LEFT", "L", UiKit.BLUE)
	right_button = _key("RIGHT", "R", UiKit.BLUE)
	undo_button = SchoolUi.button("UNDO", Color(), BUTTON)
	undo_button.pressed.connect(undo)
	clear_button = SchoolUi.button("CLEAR", Color(), BUTTON)
	clear_button.pressed.connect(clear)
	for b: Button in [forward_button, left_button, right_button, undo_button, clear_button]:
		b.add_theme_font_size_override("font_size", 24)
		keys.add_child(b)
	row.add_child(keys)
	add_child(row)
	strip = ProgramStrip.new(self)
	add_child(strip)


func _key(words: String, command: String, color: Color) -> Button:
	var b := SchoolUi.button(words, color, BUTTON)
	b.name = words.capitalize()
	b.pressed.connect(add.bind(command))
	return b


func add(command: String) -> void:
	if _locked or program.size() >= RobotCheck.MAX_PROGRAM or not RobotCheck.COMMANDS.has(command):
		return
	program.append(command)
	last_run = {}
	_redraw()
	changed.emit()


func undo() -> void:
	if _locked or program.is_empty():
		return
	program.pop_back()
	last_run = {}
	_redraw()
	changed.emit()


func clear() -> void:
	if _locked:
		return
	program.clear()
	last_run = {}
	_redraw()
	changed.emit()


func response() -> Variant:
	return program.duplicate()


func is_ready() -> bool:
	return not program.is_empty()


## A miss: the program stays; the robot's run shows where it went.
func mark_wrong() -> void:
	last_run = RobotCheck.run(board, program)
	_redraw()


func mark_right() -> void:
	last_run = RobotCheck.run(board, program)
	_redraw()


func lock() -> void:
	_locked = true
	for b: Button in [forward_button, left_button, right_button, undo_button, clear_button]:
		b.disabled = true


func show_answer(answer: Variant) -> void:
	program.clear()
	for c: Variant in answer:
		program.append(str(c))
	last_run = RobotCheck.run(board, program)
	_redraw()


func _redraw() -> void:
	view.queue_redraw()
	strip.queue_redraw()


## The board: squares, walls, gems, the flag, the robot; after a run, its path and where it bumped.
class BoardView:
	extends Control
	var owner_answer: RobotAnswer

	func _init(o: RobotAnswer) -> void:
		owner_answer = o
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_vertical = Control.SIZE_SHRINK_CENTER   # the board keeps its squares, however tall the keys are
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var b := o.board
		var cell := minf(minf(BOARD_MAX.x / float(b.get("cols", 5)), BOARD_MAX.y / float(b.get("rows", 5))), CELL_MAX)
		custom_minimum_size = Vector2(cell * float(b.get("cols", 5)), cell * float(b.get("rows", 5)))

	func _cell() -> float:
		return size.x / float(owner_answer.board.cols)

	func _centre(c: Vector2i) -> Vector2:
		var s := _cell()
		return Vector2((c.x + 0.5) * s, (c.y + 0.5) * s)

	func _draw() -> void:
		var b := owner_answer.board
		var s := _cell()
		draw_rect(Rect2(Vector2.ZERO, size), Color("fdf6e3"))
		for x in int(b.cols) + 1:
			draw_line(Vector2(x * s, 0), Vector2(x * s, size.y), Color(0.3, 0.3, 0.4, 0.5), 2.0)
		for y in int(b.rows) + 1:
			draw_line(Vector2(0, y * s), Vector2(size.x, y * s), Color(0.3, 0.3, 0.4, 0.5), 2.0)
		for w: Variant in b.get("walls", []):
			var c: Vector2i = RobotCheck.cell(w)
			draw_rect(Rect2(Vector2(c) * s + Vector2(3, 3), Vector2(s - 6, s - 6)), Color("8a5a3a"))
			draw_rect(Rect2(Vector2(c) * s + Vector2(3, 3), Vector2(s - 6, (s - 6) * 0.3)), Color("a8744c"))
		var run := owner_answer.last_run
		var picked: Array = run.get("gems", [])
		for g: Variant in b.get("gems", []):
			var c: Vector2i = RobotCheck.cell(g)
			if picked.has(c):
				continue
			var m := _centre(c)
			var r := s * 0.22
			draw_colored_polygon(PackedVector2Array([m + Vector2(0, -r), m + Vector2(r, 0), m + Vector2(0, r),
				m + Vector2(-r, 0)]), Color("2fc7e0"))
		var goal: Vector2i = RobotCheck.cell(b.goal)
		var gm := _centre(goal)
		draw_line(gm + Vector2(-s * 0.15, s * 0.32), gm + Vector2(-s * 0.15, -s * 0.32), Color("444444"), 3.0)
		draw_colored_polygon(PackedVector2Array([gm + Vector2(-s * 0.15, -s * 0.32), gm + Vector2(s * 0.3, -s * 0.18),
			gm + Vector2(-s * 0.15, -s * 0.04)]), Color("e8413b"))
		if not run.is_empty():
			var path: Array = run.path
			for i in path.size() - 1:
				draw_line(_centre(path[i]), _centre(path[i + 1]), Color(0.2, 0.55, 0.95, 0.8), 5.0)
		var at: Vector2i = run.get("pos", RobotCheck.cell(b.start))
		var facing := str(run.get("facing", b.facing))
		_robot(_centre(at), s, facing)
		if bool(run.get("crashed", false)):
			var bump := _centre(at) + Vector2(RobotCheck.STEP[facing]) * s * 0.5
			draw_line(bump + Vector2(-8, -8), bump + Vector2(8, 8), Color("e8413b"), 4.0)
			draw_line(bump + Vector2(-8, 8), bump + Vector2(8, -8), Color("e8413b"), 4.0)

	func _robot(m: Vector2, s: float, facing: String) -> void:
		var r := s * 0.34
		draw_rect(Rect2(m - Vector2(r, r), Vector2(r, r) * 2.0), Color("5b6b8a"))
		var d := Vector2(RobotCheck.STEP[facing])
		var side := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([m + d * r * 0.9, m - d * r * 0.3 + side * r * 0.6,
			m - d * r * 0.3 - side * r * 0.6]), Color("ffd23f"))


## The program under the board: a numbered chip per command, an arrow for its way.
class ProgramStrip:
	extends Control
	var owner_answer: RobotAnswer
	const CHIP := 38.0

	func _init(o: RobotAnswer) -> void:
		owner_answer = o
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(12 * (CHIP + 4), CHIP * 2 + 6)

	func _draw() -> void:
		var prog := owner_answer.program
		if prog.is_empty():
			var f := get_theme_default_font()
			draw_string(f, Vector2(4, CHIP * 0.7), "Tap FORWARD, LEFT or RIGHT to write the robot's program.",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.7))
			return
		for i in prog.size():
			var at := Vector2((i % 12) * (CHIP + 4), (i / 12) * (CHIP + 6))
			var bad := int(owner_answer.last_run.get("crash_step", -1)) == i
			draw_rect(Rect2(at, Vector2(CHIP, CHIP)), Color("e8413b") if bad else
				(Color("2fae4e") if prog[i] == "F" else Color("3a7be8")))
			var m := at + Vector2(CHIP, CHIP) * 0.5
			var d := Vector2(0, -1) if prog[i] == "F" else (Vector2(-1, 0) if prog[i] == "L" else Vector2(1, 0))
			var side := Vector2(-d.y, d.x)
			draw_colored_polygon(PackedVector2Array([m + d * 12.0, m - d * 6.0 + side * 9.0, m - d * 6.0 - side * 9.0]),
				Color.WHITE)
