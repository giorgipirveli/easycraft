class_name CodeStation
extends PlayStation
## Owner #122 (G0), Code it (design §5.1): the School's robot board stands on the shelf, leaning back towards the child
## (row 0 at its top), with its walls, gems and flag, and the robot facing its way. FORWARD, TURN LEFT and TURN RIGHT are command cards at the front: a tap (VR: a
## hand or the laser) adds one to the program, TAKE ONE BACK the last; the program reads on the robot's sign. RUN THE
## ROBOT: the robot really runs it (RobotCheck); right, it reaches the flag; not yet, it stops where it went wrong and
## goes back to the start, and the program stays to be changed.

const COMMAND_WORDS := {"F": "FORWARD", "L": "TURN LEFT", "R": "TURN RIGHT"}
## The robot's turn on the board's face for each heading (N is up the board).
const TURN := {"N": 0.0, "E": -PI * 0.5, "S": PI, "W": PI * 0.5}
const TILT := 0.5

var board: Dictionary
var program: Array[String] = []
var robot: Node3D
var surface: Node3D
var cell := 0.1
var cols := 3
var rows := 3
var sign: Label3D


func build() -> void:
	board = ex.get("board", {})
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	shelf()
	cols = int(board.get("cols", 3))
	rows = int(board.get("rows", 3))
	cell = minf(0.2, minf(0.95 / cols, 0.56 / rows))
	surface = Node3D.new()
	surface.name = "Board"
	surface.position = Vector3(0, SHELF_TOP + 0.04 + rows * cell * 0.5 * cos(TILT), BACK_Z + 0.12)
	surface.rotation.x = -TILT
	add_child(surface)
	LifeRoomKit.box(surface, "Back", Vector3(cols * cell + 0.05, rows * cell + 0.05, 0.02), Vector3(0, 0, -0.012), Color("39445e"))
	# the squares are the board's lines (a draw each: the Quest's budget)
	LifeRoomKit.box(surface, "Squares", Vector3(cols * cell, rows * cell, 0.006), Vector3(0, 0, 0.002), Color("dfe6ee"))
	for x in cols + 1:
		LifeRoomKit.box(surface, "LineX", Vector3(0.008, rows * cell, 0.01), Vector3((x - cols * 0.5) * cell, 0, 0.004), Color("8a93a6"))
	for y in rows + 1:
		LifeRoomKit.box(surface, "LineY", Vector3(cols * cell, 0.008, 0.01), Vector3(0, (y - rows * 0.5) * cell, 0.004), Color("8a93a6"))
	for w: Variant in board.get("walls", []):
		LifeRoomKit.box(surface, "Wall", Vector3(cell * 0.9, cell * 0.9, cell * 0.6), _at(RobotCheck.cell(w)) + Vector3(0, 0, cell * 0.3),
			Color("8a6239"))
	for g: Variant in board.get("gems", []):
		LifeRoomKit.sphere(surface, "Gem", cell * 0.18, _at(RobotCheck.cell(g)) + Vector3(0, 0, cell * 0.2), Color("ffd23f"))
	var flag_at := _at(RobotCheck.cell(board.get("goal")))
	LifeRoomKit.box(surface, "Pole", Vector3(0.012, 0.012, cell * 0.9), flag_at + Vector3(0, 0, cell * 0.45), Color("39445e"))
	LifeRoomKit.box(surface, "Flag", Vector3(cell * 0.4, cell * 0.28, 0.01), flag_at + Vector3(cell * 0.2, 0, cell * 0.8),
		Color("d6475a"))
	robot = Node3D.new()
	robot.name = "Robot"
	surface.add_child(robot)
	LifeRoomKit.box(robot, "Body", Vector3(cell * 0.6, cell * 0.6, cell * 0.5), Vector3(0, 0, cell * 0.25), Color("3a7be8"))
	LifeRoomKit.box(robot, "Face", Vector3(cell * 0.4, 0.01, cell * 0.2), Vector3(0, cell * 0.3, cell * 0.3), Color("9fd8ff"))
	_robot_to(RobotCheck.cell(board.get("start")), str(board.get("facing", "N")))
	var xs := spread(3, 0.4)
	var k := 0
	for c: String in ["L", "F", "R"]:
		var card := PlayKit.card(self, "Command" + c, {"text": COMMAND_WORDS[c]}, Vector3(xs[k], ON_TABLE, FRONT_Z),
			Color("3f51b5"), Vector3(0.34, 0.1, 0.05))
		add("cmd_" + c, card, 0.13)
		k += 1
	var back := PlayKit.card(self, "Back", {"text": "TAKE ONE BACK"}, UTILITY_AT, Color("6b7a99"), UTILITY)
	add("back", back, 0.1)
	sign = PlayKit.words(surface, "Program", "", Vector3(0, -rows * cell * 0.5 - 0.07, 0.03), 0.0012, 44, Color("fff4b0"))
	sign.width = 1000
	add(GO, PlayKit.go_button(self, go_words(), GO_AT), 0.11)
	_refresh()


## A square's middle on the board's face (row 0 at the top).
func _at(c: Variant) -> Vector3:
	var v: Vector2i = c if c is Vector2i else Vector2i.ZERO
	return Vector3((v.x - (cols - 1) * 0.5) * cell, ((rows - 1) * 0.5 - v.y) * cell, 0.006)


func _robot_to(c: Variant, facing: String) -> void:
	robot.position = _at(c)
	robot.rotation.z = float(TURN.get(facing, 0.0))


func press(t: String) -> void:
	if t.begins_with("cmd_"):
		if program.size() < int(ex.get("max", RobotCheck.MAX_PROGRAM)):
			program.append(t.trim_prefix("cmd_"))
	elif t == "back":
		if not program.is_empty():
			program.pop_back()
	else:
		return
	_refresh()
	changed.emit()


func response() -> Variant:
	return program.duplicate()


func is_ready() -> bool:
	return not program.is_empty()


func ghost() -> Array[String]:
	if ExerciseCheck.is_right(ex, program):
		return [] as Array[String]
	var best := RobotCheck.shortest(board)
	for i in program.size():
		if i >= best.size() or program[i] != best[i]:
			return ["back"] as Array[String]
	return ["cmd_" + best[program.size()]] as Array[String]


func show_answer() -> void:
	program = RobotCheck.shortest(board)
	_refresh()


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT, PlayLoop.NOT_YET, PlayLoop.GHOST:
			_run(outcome == PlayLoop.RIGHT)
		PlayLoop.SHOWN:
			show_answer()
			_run(true)


## The robot runs the program square by square; when it is not right yet it comes back to the start.
func _run(stay: bool) -> void:
	var r := RobotCheck.run(board, program)
	var start: Variant = RobotCheck.cell(board.get("start"))
	var facing := str(board.get("facing", "N"))
	if UiMotion.calm() or not is_inside_tree():
		if stay:
			_robot_to(r.pos, str(r.facing))
		else:
			_robot_to(start, facing)
		return
	var tw := create_tween()
	for c: Variant in r.get("path", []):
		tw.tween_property(robot, "position", _at(c), 0.22)
	if not stay:
		tw.tween_interval(0.4)
		tw.tween_callback(func() -> void: _robot_to(start, facing))


func _refresh() -> void:
	var words: Array[String] = []
	for c in program:
		words.append(COMMAND_WORDS[c])
	sign.text = "Program: " + (", ".join(words) if not words.is_empty() else "(empty)")
