class_name RobotCheck
extends RefCounted
## The research's "code the robot" (docs/design/school-curriculum-research.md §5.3; grade 3 computing: algorithms,
## sequences, debugging). A board is {cols, rows (3-8), start: [x, y], facing ("N", "E", "S" or "W"), goal: [x, y],
## walls?: [[x, y], …], gems?: [[x, y], …]}; y grows downwards (row 0 at the top). A program is a list of commands: "F"
## one square forward, "L" and "R" a quarter turn where the robot stands. It must reach the goal without bumping into
## a wall or leaving the board, picking up every gem on the way. The exercise is ExerciseCheck's
## {type: "robot", board, max?} (max: at most so many commands); its worked answer is a shortest program. No drawing
## here (RobotAnswer draws).

const MIN_SIDE := 3
const MAX_SIDE := 8
const MAX_PROGRAM := 24
const COMMANDS: Array[String] = ["F", "L", "R"]
const WORDS := {"F": "FORWARD", "L": "TURN LEFT", "R": "TURN RIGHT"}
const HEADINGS: Array[String] = ["N", "E", "S", "W"]
const STEP := {"N": Vector2i(0, -1), "E": Vector2i(1, 0), "S": Vector2i(0, 1), "W": Vector2i(-1, 0)}


static func cell(v: Variant) -> Variant:
	if v is Array and (v as Array).size() == 2 and typeof(v[0]) in [TYPE_INT, TYPE_FLOAT] \
			and typeof(v[1]) in [TYPE_INT, TYPE_FLOAT]:
		return Vector2i(int(v[0]), int(v[1]))
	return null


static func _inside(b: Dictionary, c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < int(b.cols) and c.y < int(b.rows)


static func _cells(b: Dictionary, key: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for v: Variant in b.get(key, []):
		var c: Variant = cell(v)
		if c != null:
			out.append(c)
	return out


## "" when the board can be played (and the goal can be reached); otherwise what is wrong.
static func problem(board: Variant) -> String:
	if not board is Dictionary:
		return "a board is a dictionary"
	var b: Dictionary = board
	for side: String in ["cols", "rows"]:
		var n: Variant = b.get(side)
		if typeof(n) not in [TYPE_INT, TYPE_FLOAT] or int(n) < MIN_SIDE or int(n) > MAX_SIDE:
			return "%s: %d-%d squares" % [side, MIN_SIDE, MAX_SIDE]
	if not HEADINGS.has(str(b.get("facing", ""))):
		return "facing: N, E, S or W"
	var start: Variant = cell(b.get("start"))
	var goal: Variant = cell(b.get("goal"))
	if start == null or goal == null or not _inside(b, start) or not _inside(b, goal) or start == goal:
		return "the start and the goal: two different squares on the board"
	var walls := _cells(b, "walls")
	var gems := _cells(b, "gems")
	if walls.size() != (b.get("walls", []) as Array).size() or gems.size() != (b.get("gems", []) as Array).size():
		return "walls and gems are squares [x, y]"
	for c in walls + gems:
		if not _inside(b, c):
			return "a wall or a gem off the board"
	if walls.has(start) or walls.has(goal):
		return "the start or the goal is in a wall"
	for g in gems:
		if walls.has(g):
			return "a gem in a wall"
	if gems.size() > 4:
		return "at most 4 gems"
	if shortest(b).is_empty():
		return "the robot can't reach the goal"
	return ""


## Runs `program` from the start: {pos, facing, path (every square it stood on), crashed, crash_step (the command that
## bumped, -1), gems (picked up)}.
static func run(board: Dictionary, program: Array) -> Dictionary:
	var pos: Vector2i = cell(board.start)
	var facing := str(board.facing)
	var walls := _cells(board, "walls")
	var gems := _cells(board, "gems")
	var picked: Array[Vector2i] = []
	var path: Array[Vector2i] = [pos]
	for i in program.size():
		var c := str(program[i])
		if c == "L" or c == "R":
			facing = HEADINGS[(HEADINGS.find(facing) + (3 if c == "L" else 1)) % 4]
		elif c == "F":
			var next: Vector2i = pos + STEP[facing]
			if not _inside(board, next) or walls.has(next):
				return {"pos": pos, "facing": facing, "path": path, "crashed": true, "crash_step": i, "gems": picked}
			pos = next
			path.append(pos)
			if gems.has(pos) and not picked.has(pos):
				picked.append(pos)
		else:
			return {"pos": pos, "facing": facing, "path": path, "crashed": true, "crash_step": i, "gems": picked}
	return {"pos": pos, "facing": facing, "path": path, "crashed": false, "crash_step": -1, "gems": picked}


## The program ends on the goal, with no bump and every gem picked up.
static func reaches(board: Dictionary, program: Array) -> bool:
	if program.size() > MAX_PROGRAM:
		return false
	var r := run(board, program)
	return not r.crashed and r.pos == cell(board.goal) and (r.gems as Array).size() == _cells(board, "gems").size()


## A shortest program that reaches the goal ([] when none can): a search over square, heading and gems picked up.
static func shortest(board: Dictionary) -> Array[String]:
	var start: Vector2i = cell(board.start)
	var goal: Vector2i = cell(board.goal)
	var walls := _cells(board, "walls")
	var gems := _cells(board, "gems")
	var all_gems := (1 << gems.size()) - 1
	var first := [start, str(board.facing), 0]
	var seen := {_key(first): true}
	var queue: Array = [[first, [] as Array[String]]]
	var head := 0
	while head < queue.size():
		var entry: Array = queue[head]
		head += 1
		var state: Array = entry[0]
		var prog: Array[String] = entry[1]
		if state[0] == goal and int(state[2]) == all_gems:
			return prog
		if prog.size() >= MAX_PROGRAM:
			continue
		for c: String in COMMANDS:
			var pos: Vector2i = state[0]
			var facing: String = state[1]
			var mask: int = state[2]
			if c == "F":
				pos += STEP[facing]
				if not _inside(board, pos) or walls.has(pos):
					continue
				var g := gems.find(pos)
				if g >= 0:
					mask |= 1 << g
			else:
				facing = HEADINGS[(HEADINGS.find(facing) + (3 if c == "L" else 1)) % 4]
			var next := [pos, facing, mask]
			if seen.has(_key(next)):
				continue
			seen[_key(next)] = true
			var longer: Array[String] = prog.duplicate()
			longer.append(c)
			queue.append([next, longer])
	return [] as Array[String]


static func _key(state: Array) -> String:
	return "%d,%d,%s,%d" % [state[0].x, state[0].y, state[1], state[2]]


## A program in words: "FORWARD, FORWARD, TURN RIGHT".
static func words(program: Array) -> String:
	var out: Array[String] = []
	for c: Variant in program:
		out.append(str(WORDS.get(str(c), str(c))))
	return ", ".join(out)
