class_name CubeNet
extends RefCounted
## Grade 3 design and technology, "Boxes and nets" (research §6.3): does a flat shape of squares, joined edge to edge,
## fold into a cube? The cube is rolled across the shape, square by square, from the first one: each square gets the
## face of the cube that lands on it. The shape is a net when it has 6 squares, all joined, with no 2 × 2 block (four
## faces cannot meet round one corner) and every square gets a different face. BuildCheck's "cube_net" goal and the
## grade 3 generators (G3HealthGen) use it; tests/unit/test_cube_net.gd checks it against the 11 nets of the 35
## hexominoes.

## A face of the cube: which way it looks when the cube sits on the first square.
enum Face { BOTTOM, TOP, NORTH, SOUTH, EAST, WEST }
const OPPOSITE := {Face.BOTTOM: Face.TOP, Face.TOP: Face.BOTTOM, Face.NORTH: Face.SOUTH, Face.SOUTH: Face.NORTH,
	Face.EAST: Face.WEST, Face.WEST: Face.EAST}
const STEPS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]


static func folds(cells: Array) -> bool:
	return not faces(cells).is_empty()


## Each square (Vector2i) -> the Face it becomes; {} when the squares do not fold into a cube.
static func faces(cells: Array) -> Dictionary:
	var set := {}
	for c: Variant in cells:
		if not c is Vector2i:
			return {}
		set[c] = true
	if set.size() != 6 or cells.size() != 6:
		return {}
	for c: Vector2i in set:
		if set.has(c + Vector2i.RIGHT) and set.has(c + Vector2i.DOWN) and set.has(c + Vector2i.ONE):
			return {}
	# where each face looks: [bottom, top, north (y - 1), south (y + 1), east (x + 1), west (x - 1)]
	var start: Vector2i = cells[0]
	var state := {start: [Face.BOTTOM, Face.TOP, Face.NORTH, Face.SOUTH, Face.EAST, Face.WEST]}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d in STEPS:
			var p := c + d
			if set.has(p) and not state.has(p):
				state[p] = _roll(state[c], d)
				queue.append(p)
	if state.size() != 6:
		return {}
	var out := {}
	var seen := {}
	for c: Vector2i in state:
		var face: int = state[c][0]
		if seen.has(face):
			return {}
		seen[face] = true
		out[c] = face
	return out


## True when squares a and b of the net become opposite faces of the cube.
static func opposite(cells: Array, a: Vector2i, b: Vector2i) -> bool:
	var f := faces(cells)
	return f.has(a) and f.has(b) and int(OPPOSITE[f[a]]) == int(f[b])


## The cube rolled one square in direction d: which face now looks each way.
static func _roll(s: Array, d: Vector2i) -> Array:
	var b: int = s[0]
	var t: int = s[1]
	var n: int = s[2]
	var so: int = s[3]
	var e: int = s[4]
	var w: int = s[5]
	match d:
		Vector2i.RIGHT:
			return [e, w, n, so, t, b]
		Vector2i.LEFT:
			return [w, e, n, so, b, t]
		Vector2i.UP:
			return [n, so, t, b, e, w]
	return [so, n, b, t, e, w]   # Vector2i.DOWN
