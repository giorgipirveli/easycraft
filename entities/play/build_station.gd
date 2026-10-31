class_name BuildStation
extends PlayStation
## Owner #122 (G0), Build it (design §5.1): the School's block board in the place: a wall standing up (row 0 on the ground,
## leaning back a little towards the child) or a farm lying on the table (seen from above), with the given blocks already
## there. A tap on a square (VR: the hand or the laser) places a block or takes it away; a mirror build shows the game's
## Mirror as a line; CLEAR empties it. CHECK THE BUILD asks BuildCheck (ExerciseCheck's referee for a build): right, the
## blocks hop; not yet, the build stays to be changed.

const BLOCK := Color("c98d4f")
const GIVEN := Color("8a6239")
const EMPTY := Color(1, 1, 1, 0.22)
const TILT := 0.3

var board: Dictionary
var goal: Dictionary
var given: Array[Vector2i] = []
var placed: Array[Vector2i] = []
var wall := true
var cell := 0.09
var cols := 1
var rows := 1
var surface: Node3D
var _blocks := {}


func build() -> void:
	board = ex.get("board", {})
	goal = ex.get("goal", {})
	given = BuildCheck.given(board)
	wall = str(board.get("view", "wall")) != "farm"
	cols = int(board.get("cols", 1))
	rows = int(board.get("rows", 1))
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	surface = Node3D.new()
	surface.name = "Board"
	add_child(surface)
	if wall:
		cell = minf(0.12, minf(1.0 / cols, 0.8 / rows))
		surface.position = Vector3(0, TABLE_TOP + 0.05 + rows * cell * 0.5, 0.24)
		surface.rotation.x = -TILT
		LifeRoomKit.box(surface, "Backboard", Vector3(cols * cell + 0.06, rows * cell + 0.06, 0.02), Vector3(0, 0, -0.02),
			Color("39445e"))
	else:
		cell = minf(0.1, minf(1.2 / cols, 0.42 / rows))
		surface.position = Vector3(0, TABLE_TOP + 0.01, 0.4)
		surface.rotation.x = -PI * 0.5
	# the board's squares are its lines (a draw each: the Quest's budget), each square a target of its own
	LifeRoomKit.box(surface, "Squares", Vector3(cols * cell, rows * cell, 0.004), Vector3(0, 0, -0.004), EMPTY)
	for x in cols + 1:
		LifeRoomKit.box(surface, "LineX", Vector3(0.006, rows * cell, 0.008), Vector3((x - cols * 0.5) * cell, 0, 0), Color("6b7a99"))
	for y in rows + 1:
		LifeRoomKit.box(surface, "LineY", Vector3(cols * cell, 0.006, 0.008), Vector3(0, (y - rows * 0.5) * cell, 0), Color("6b7a99"))
	for y in rows:
		for x in cols:
			var square := Node3D.new()
			square.name = "Cell_%d_%d" % [x, y]
			square.position = _cell_at(Vector2i(x, y))
			surface.add_child(square)
			add("cell_%d_%d" % [x, y], square, cell * 0.5)
	if str(goal.get("kind", "")) == "mirror":   # the game's Mirror: where column x meets column sum - x
		var axis := (float(goal.get("sum", 0)) * 0.5 - (cols - 1) * 0.5) * cell
		LifeRoomKit.box(surface, "Mirror", Vector3(0.012, rows * cell + 0.04, 0.03), Vector3(axis, 0, 0.01),
			Color(0.7, 0.9, 1.0, 0.75))
	var clear := PlayKit.card(self, "Clear", {"text": "CLEAR"}, UTILITY_AT + Vector3(0, 0, 0.18), Color("6b7a99"), UTILITY)
	add("clear", clear, 0.1)
	add(GO, PlayKit.go_button(self, go_words(), GO_AT), 0.11)
	_refresh()


## A square's middle on the board's surface (row 0 at the bottom of a wall, nearest the child on a farm).
func _cell_at(c: Vector2i) -> Vector3:
	return Vector3((c.x - (cols - 1) * 0.5) * cell, (c.y - (rows - 1) * 0.5) * cell, 0)


func press(t: String) -> void:
	if t == "clear":
		placed.clear()
	elif t.begins_with("cell_"):
		var c := Vector2i(int(t.get_slice("_", 1)), int(t.get_slice("_", 2)))
		if given.has(c):
			return
		if placed.has(c):
			placed.erase(c)
		else:
			placed.append(c)
	else:
		return
	_refresh()
	changed.emit()


func response() -> Variant:
	var out: Array[Vector2i] = given.duplicate()
	out.append_array(placed)
	return out


func is_ready() -> bool:
	return not placed.is_empty()


func readout() -> String:
	var n := given.size() + placed.size()
	return "%d block%s" % [n, Lang.plural_s(n)]


func ghost() -> Array[String]:
	if BuildCheck.check(goal, board, response()):
		return [] as Array[String]
	var want := BuildCheck.example(goal, board)
	for c in placed:
		if not want.has(c):
			return ["cell_%d_%d" % [c.x, c.y]] as Array[String]
	for c in want:
		if not given.has(c) and not placed.has(c):
			return ["cell_%d_%d" % [c.x, c.y]] as Array[String]
	return [] as Array[String]


func show_answer() -> void:
	placed.clear()
	for c in BuildCheck.example(goal, board):
		if not given.has(c):
			placed.append(c)
	_refresh()


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT:
			hop(surface)
		PlayLoop.SHOWN:
			show_answer()


func _refresh() -> void:
	for c: Vector2i in _blocks.keys():
		if not placed.has(c) and not given.has(c):
			(_blocks[c] as Node3D).queue_free()
			_blocks.erase(c)
	for c in given + placed:
		if _blocks.has(c):
			continue
		_blocks[c] = LifeRoomKit.box(surface, "Block_%d_%d" % [c.x, c.y], Vector3.ONE * cell * 0.92,
			_cell_at(c) + Vector3(0, 0, cell * 0.46), GIVEN if given.has(c) else BLOCK)
