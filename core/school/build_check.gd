class_name BuildCheck
extends RefCounted
## Owner #68 (spec §22.1, ruling 6): the block board's goals, "build the answer". A board is {cols, rows, block (the block
## id it builds with), given ([[x, y], …] blocks already there, never removed), view ("wall": y up from the ground row, or
## "farm": seen from above)}. The cells checked are Vector2i: every block on the board, given ones included. Nothing here
## knows the board is a picture: a build in the world can be checked the same way (plan task 12).
##
## Goals:
## - count {n}: exactly n blocks.
## - array {rows, cols, any_turn?}: a filled rectangle `rows` tall and `cols` wide (any_turn: either way round).
## - rectangle {area, perimeter?, min_side?}: a filled rectangle of that area (and perimeter, and no side shorter).
## - fraction {num, den}: num/den of the board's cells.
## - mirror {sum}: the build is the same in the mirror where column x meets column sum − x, and adds to the given blocks.
## - cube_net {}: 6 blocks that fold into a cube (CubeNet; grade 3 design and technology, "Boxes and nets").

const MAX_COLS := 12
const MAX_ROWS := 10
const KINDS: Array[String] = ["count", "array", "rectangle", "fraction", "mirror", "cube_net"]


static func check(goal: Dictionary, board: Dictionary, cells: Array) -> bool:
	var set := {}
	for c: Variant in cells:
		if not c is Vector2i or not inside(board, c):
			return false
		set[c] = true
	for g in given(board):
		if not set.has(g):
			return false
	var n := set.size()
	match str(goal.get("kind", "")):
		"count":
			return n == int(goal.get("n", -1))
		"array":
			var size := _filled_rect(set)
			var rows := int(goal.get("rows", 0))
			var cols := int(goal.get("cols", 0))
			if size == Vector2i(cols, rows):
				return true
			return bool(goal.get("any_turn", false)) and size == Vector2i(rows, cols)
		"rectangle":
			var size := _filled_rect(set)
			return size != Vector2i.ZERO and _rect_fits(goal, size)
		"fraction":
			var total := _total(board)
			var den := int(goal.get("den", 0))
			return den > 0 and n * den == total * int(goal.get("num", -1))
		"mirror":
			if n <= given(board).size():
				return false
			var sum := int(goal.get("sum", -1))
			for c: Vector2i in set:
				if not set.has(Vector2i(sum - c.x, c.y)):
					return false
			return true
		"cube_net":
			return CubeNet.folds(set.keys())
	return false


## A right answer (given blocks included), [] when the goal has none on this board.
static func example(goal: Dictionary, board: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = given(board)
	match str(goal.get("kind", "")):
		"count":
			return _fill_to(board, out, int(goal.get("n", -1)))
		"array":
			return _rect_with_given(board, int(goal.get("cols", 0)), int(goal.get("rows", 0)))
		"rectangle":
			for h in range(1, int(board.get("rows", 0)) + 1):
				for w in range(1, int(board.get("cols", 0)) + 1):
					if _rect_fits(goal, Vector2i(w, h)):
						var r := _rect_with_given(board, w, h)
						if not r.is_empty():
							return r
			return [] as Array[Vector2i]
		"fraction":
			var den := int(goal.get("den", 0))
			var total := _total(board)
			if den <= 0 or total % den != 0:
				return [] as Array[Vector2i]
			return _fill_to(board, out, int(total / float(den)) * int(goal.get("num", -1)))
		"mirror":
			var sum := int(goal.get("sum", -1))
			for g in given(board):
				var twin := Vector2i(sum - g.x, g.y)
				if not out.has(twin):
					out.append(twin)
			if out.size() > given(board).size():
				return out
		"cube_net":
			if out.size() <= 6:
				return _net_from(board, out, {})
	return [] as Array[Vector2i]


## "" when the goal fits the board and has a right answer; otherwise why not.
static func problem(goal: Dictionary, board: Dictionary) -> String:
	var cols := int(board.get("cols", 0))
	var rows := int(board.get("rows", 0))
	if cols < 1 or cols > MAX_COLS or rows < 1 or rows > MAX_ROWS:
		return "the board must be 1-%d wide and 1-%d tall" % [MAX_COLS, MAX_ROWS]
	if int(board.get("block", 0)) <= 0:
		return "the board needs a block"
	var raw: Variant = board.get("given", [])
	if not raw is Array:
		return "given must be a list"
	for g: Variant in raw:
		if not g is Array or (g as Array).size() != 2 or not inside(board, Vector2i(int(g[0]), int(g[1]))):
			return "a given block is off the board: %s" % [g]
	if not KINDS.has(str(goal.get("kind", ""))):
		return "unknown goal kind %s" % goal.get("kind", "")
	var ex := example(goal, board)
	if ex.is_empty() or not check(goal, board, ex):
		return "the goal %s cannot be built on this board" % [goal]
	return ""


## The board's given blocks.
static func given(board: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var raw: Variant = board.get("given", [])
	if raw is Array:
		for g: Variant in raw:
			if g is Array and (g as Array).size() == 2:
				var c := Vector2i(int(g[0]), int(g[1]))
				if not out.has(c):
					out.append(c)
	return out


static func inside(board: Dictionary, c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < int(board.get("cols", 0)) and c.y < int(board.get("rows", 0))


static func _total(board: Dictionary) -> int:
	return int(board.get("cols", 0)) * int(board.get("rows", 0))


## The size of the rectangle the cells fill exactly, or ZERO when they are not one filled rectangle.
static func _filled_rect(set: Dictionary) -> Vector2i:
	if set.is_empty():
		return Vector2i.ZERO
	var lo := Vector2i(1 << 30, 1 << 30)
	var hi := Vector2i(-(1 << 30), -(1 << 30))
	for c: Vector2i in set:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var size := hi - lo + Vector2i.ONE
	return size if size.x * size.y == set.size() else Vector2i.ZERO


static func _rect_fits(goal: Dictionary, size: Vector2i) -> bool:
	if size.x * size.y != int(goal.get("area", -1)):
		return false
	if goal.has("perimeter") and 2 * (size.x + size.y) != int(goal.perimeter):
		return false
	return mini(size.x, size.y) >= int(goal.get("min_side", 1))


## A w × h rectangle at the bottom-left corner, if every given block is inside it.
static func _rect_with_given(board: Dictionary, w: int, h: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if w < 1 or h < 1 or w > int(board.get("cols", 0)) or h > int(board.get("rows", 0)):
		return out
	for g in given(board):
		if g.x >= w or g.y >= h:
			return out
	for y in h:
		for x in w:
			out.append(Vector2i(x, y))
	return out


## A net of a cube on the board that keeps the cells of `start`: squares added next to the shape, one at a time, each
## shape tried once (`seen`); [] when there is none.
static func _net_from(board: Dictionary, start: Array[Vector2i], seen: Dictionary = {}) -> Array[Vector2i]:
	var none: Array[Vector2i] = []
	if start.size() == 6:
		return start if CubeNet.folds(start) else none
	var key: Array[Vector2i] = []
	key.assign(start)
	key.sort()
	if seen.has(key):
		return none
	seen[key] = true
	var next: Array[Vector2i] = []
	if start.is_empty():
		for y in int(board.get("rows", 0)):
			for x in int(board.get("cols", 0)):
				next.append(Vector2i(x, y))
	else:
		for c in start:
			for d: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
				if inside(board, c + d) and not start.has(c + d) and not next.has(c + d):
					next.append(c + d)
	for c in next:
		var grown: Array[Vector2i] = []
		grown.assign(start)
		grown.append(c)
		var found := _net_from(board, grown, seen)
		if not found.is_empty():
			return found
	return none


## `start` plus free cells (row by row from the ground) until there are n; [] when n does not fit.
static func _fill_to(board: Dictionary, start: Array[Vector2i], n: int) -> Array[Vector2i]:
	var out := start.duplicate()
	if n < out.size() or n > _total(board):
		return [] as Array[Vector2i]
	for y in int(board.get("rows", 0)):
		for x in int(board.get("cols", 0)):
			if out.size() >= n:
				return out
			var c := Vector2i(x, y)
			if not out.has(c):
				out.append(c)
	return out
