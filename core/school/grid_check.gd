class_name GridCheck
extends RefCounted
## Owner #68, grade 5 maths (5.G.1, 5.G.2, 5.OA.3): the coordinate grid, the first quadrant. A grid is
## {x_max, y_max, x_step?, y_step?, points?: [{x, y, label?}], join?, x_name?, y_name?}: lines at 0, step, 2 × step … max
## on each axis (at most MAX_LINES steps), points on its crossings (a label of up to 3 letters), `join` draws a line
## through the points in order, and the axes may have short names. The same grid is a picture (SchoolPictureG5 "grid")
## and the board of a "point" exercise (ExerciseCheck: {type: "point", grid, answer: [x, y]}, answered by a tap,
## GridAnswer). Nothing here knows about drawing.

const MAX_LINES := 12
const MAX_POINTS := 12
const MAX_LABEL := 3
const MAX_NAME := 12


## "" when `grid` can be drawn and tapped; otherwise what is wrong with it.
static func problem(grid: Variant) -> String:
	if not grid is Dictionary:
		return "a grid is a dictionary"
	var g: Dictionary = grid
	for axis: String in ["x", "y"]:
		var top: Variant = g.get(axis + "_max")
		var step: Variant = g.get(axis + "_step", 1)
		if not _whole(top) or not _whole(step) or int(top) < 1 or int(step) < 1:
			return "%s_max and %s_step must be whole numbers above 0" % [axis, axis]
		if int(top) % int(step) != 0 or int(top) / int(step) > MAX_LINES:
			return "%s_max must be a multiple of %s_step, at most %d steps" % [axis, axis, MAX_LINES]
	for axis: String in ["x_name", "y_name"]:
		if g.has(axis) and (not g[axis] is String or str(g[axis]).length() > MAX_NAME):
			return "%s: a word of at most %d letters" % [axis, MAX_NAME]
	var points: Variant = g.get("points", [])
	if not points is Array or (points as Array).size() > MAX_POINTS:
		return "points: a list of at most %d" % MAX_POINTS
	for p: Variant in points:
		if not p is Dictionary or not _whole(p.get("x")) or not _whole(p.get("y")):
			return "a point is {x, y, label?}: %s" % [p]
		if not on_grid(g, Vector2i(int(p.x), int(p.y))):
			return "a point off the grid's crossings: %s" % [p]
		if p.has("label") and (not p.label is String or str(p.label).length() > MAX_LABEL):
			return "a point's label: at most %d letters" % MAX_LABEL
	return ""


## "" when a "point" exercise's grid and answer are complete; otherwise what is wrong.
static func point_problem(grid: Variant, answer: Variant) -> String:
	var why := problem(grid)
	if why != "":
		return why
	var p: Variant = point(answer)
	if p == null:
		return "the answer must be a point [x, y]"
	if not on_grid(grid, p):
		return "the answer %s is not on the grid's crossings" % [answer]
	return ""


## [x, y] (whole numbers) as a Vector2i, or null.
static func point(v: Variant) -> Variant:
	if v is Vector2i:
		return v
	if not v is Array or (v as Array).size() != 2 or not _whole(v[0]) or not _whole(v[1]):
		return null
	return Vector2i(int(v[0]), int(v[1]))


## The number of steps on each axis.
static func lines(grid: Dictionary) -> Vector2i:
	return Vector2i(int(grid.get("x_max", 1)) / step(grid).x, int(grid.get("y_max", 1)) / step(grid).y)


static func step(grid: Dictionary) -> Vector2i:
	return Vector2i(maxi(1, int(grid.get("x_step", 1))), maxi(1, int(grid.get("y_step", 1))))


## True when p is inside the grid and on a crossing of its lines.
static func on_grid(grid: Dictionary, p: Vector2i) -> bool:
	var s := step(grid)
	return p.x >= 0 and p.y >= 0 and p.x <= int(grid.get("x_max", 0)) and p.y <= int(grid.get("y_max", 0)) \
		and p.x % s.x == 0 and p.y % s.y == 0


## The crossing nearest to `at` (in the grid's own numbers), kept on the grid.
static func nearest(grid: Dictionary, at: Vector2) -> Vector2i:
	var s := step(grid)
	var n := lines(grid)
	return Vector2i(clampi(roundi(at.x / s.x), 0, n.x) * s.x, clampi(roundi(at.y / s.y), 0, n.y) * s.y)


## "(4, 7)"
static func text(p: Vector2i) -> String:
	return "(%d, %d)" % [p.x, p.y]


static func _whole(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and float(v) == floorf(float(v))
