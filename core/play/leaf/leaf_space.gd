class_name LeafSpace
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.11, §4.3, ruling 31): the leaf's inside at the child's size (rung
## 5, about x85,000): HALF x 2 metres across, the leaf pressed to ROOF metres tall (21 m at true scale). One pure layout,
## from the setting and a seed: where every door (stoma), round cell, tall column, the vein and its two pipes' mouths, the
## sugar spots and (the cactus) the jars are. LeafPlace draws from it and the flyer is pushed out of the same shapes (no
## physics bodies), so what a child sees is what stops them. The composition is designed (the doors in an arc in front of
## the child, the vein crossing behind them like an aqueduct, the round cells around the open air cave, the colonnade of
## columns under the glass roof); the seed moves and sizes the cells a little, and every cell keeps clear of the doors'
## headroom, the sugar spots, the pipes' mouths and the child's way in (`_fits`), so any seed plays.
## Units are metres; the floor (the leaf's lower skin, with the doors) is y = 0; the child comes in facing -Z.

const HALF := 8.0
const ROOF := 10.0
## The tall columns (palisade cells) stand from here to the roof.
const COLUMNS_FROM := 5.0
const COLUMNS_TO := 9.9
## Room kept free above each door (to hover, squeeze and see it), sideways and up.
const DOOR_ROOM := 1.9
const DOOR_ROOM_UP := 2.4
## The flyer's height above the door it came in by.
const ARRIVE := 1.2
## The skylight in the columns over the doors (half-widths across and along, its middle's z), and the way in: no
## column stands nearer the child's side than WAY_IN.
const SKYLIGHT := Vector2(5.0, 4.6)
const SKYLIGHT_AT := -0.8
const WAY_IN := 3.4

var setting := "sunflower"
var seed := 0
## {at (in the floor), yaw (its long axis turned from +X), length (the pore), pit (sunk, the cactus)}
var doors: Array[Dictionary] = []
## {at, radius, kind ("spongy"; the cactus's "store" (big, see-through, its jars inside) and "pale" (small water cells)),
## squash (y scale), turn}
var cells: Array[Dictionary] = []
## {at (its base), top, radius}
var columns: Array[Dictionary] = []
## {from, to, radius, blue, gold (each pipe's axis offset), gold_mouth, blue_mouth}
var vein := {}
var sugar_spots: Array[Vector3] = []
## The cactus's jars (in its store cells' water).
var jars: Array[Vector3] = []
var entry_door := 0
var start := Vector3.ZERO


static func make(leaf_setting: String = "sunflower", leaf_seed: int = 0) -> LeafSpace:
	var s := LeafSpace.new()
	s.setting = leaf_setting
	s.seed = leaf_seed
	if leaf_setting == "cactus":
		s._cactus()
	else:
		s._sunflower()
	var e: Vector3 = s.doors[s.entry_door].at
	s.start = Vector3(e.x, ARRIVE, e.z)
	return s


# --- The designs ---------------------------------------------------------------------------------------------------

func _sunflower() -> void:
	var rng := _rng()
	for d: Array in [[0.0, 1.6, 0.0], [-3.7, 0.3, 18.0], [3.7, 0.3, -15.0], [-5.0, -3.4, 25.0], [0.3, -3.2, -8.0],
			[5.0, -3.2, -22.0]]:
		doors.append({"at": Vector3(d[0], 0, d[1]), "yaw": deg_to_rad(d[2]), "length": 1.7, "pit": 0.0})
	entry_door = 0
	_vein(-5.4, 2.2)
	for p: Vector3 in [Vector3(-2.2, 3.0, -1.0), Vector3(2.3, 3.1, -0.9), Vector3(-4.3, 2.7, -1.6),
			Vector3(4.4, 2.8, -1.5), Vector3(-1.5, 3.4, -3.9), Vector3(2.0, 3.5, -3.7), Vector3(-0.2, 3.9, -1.9),
			Vector3(0.2, 2.6, -0.3)]:
		sugar_spots.append(p)
	# The round cells: the back row behind the vein, the two side walls, a few islands in the air cave, the top row
	# under the columns.
	var anchors: Array = [
		[-6.6, 1.6, -7.2, 1.35], [-3.6, 1.3, -7.4, 1.3], [-0.6, 1.4, -7.5, 1.25], [2.6, 1.3, -7.4, 1.3],
		[5.8, 1.6, -7.2, 1.35], [-5.0, 4.0, -7.0, 1.2], [-1.8, 4.3, -7.2, 1.15], [1.6, 4.2, -7.1, 1.2],
		[4.8, 4.0, -7.0, 1.2], [-7.2, 1.5, -2.6, 1.3], [-7.0, 3.9, -0.6, 1.2], [-7.3, 1.6, 1.6, 1.3],
		[-6.9, 4.0, 3.4, 1.2], [-7.1, 1.5, 5.4, 1.25], [7.2, 1.5, -2.2, 1.3], [7.0, 3.9, 0.2, 1.2],
		[7.2, 1.4, 2.4, 1.3], [6.9, 4.1, -4.0, 1.15], [7.0, 1.6, 5.2, 1.25], [-2.6, 3.9, -2.6, 0.95],
		[2.9, 4.0, -2.4, 0.95], [-4.6, 4.3, 1.4, 1.0], [4.7, 4.3, 1.6, 1.0], [-3.3, 4.4, -5.0, 0.9],
		[3.5, 4.4, -5.0, 0.9], [0.4, 4.6, -6.0, 0.85],
	]
	for a: Array in anchors:
		_add_cell(rng, Vector3(a[0], a[1], a[2]), float(a[3]), "spongy")
	_colonnade(rng, 2.4, 0.62)


func _cactus() -> void:
	var rng := _rng()
	for d: Array in [[-4.4, 1.8, 10.0], [0.2, 1.9, 0.0], [4.6, 1.8, -12.0], [-4.8, -3.0, 20.0], [-0.2, -3.1, -6.0],
			[4.4, -3.0, -18.0]]:
		doors.append({"at": Vector3(d[0], 0, d[1]), "yaw": deg_to_rad(d[2]), "length": 1.5, "pit": 0.35})
	entry_door = 1
	_vein(-6.8, 1.5)
	for p: Vector3 in [Vector3(-2.2, 2.6, -0.6), Vector3(2.4, 2.7, -0.5), Vector3(-2.4, 2.8, 4.0),
			Vector3(2.4, 2.9, 4.1), Vector3(-1.8, 3.2, -4.6), Vector3(2.0, 3.3, -4.5), Vector3(0.0, 2.4, -1.0),
			Vector3(4.2, 3.4, 2.4)]:
		sugar_spots.append(p)
	# The big pale water stores, see-through: two jars in each one's water.
	var stores: Array = [[-7.0, 3.2, -0.6, 2.4], [7.0, 3.2, -0.4, 2.4], [-3.6, 4.7, -6.2, 2.25], [3.8, 4.7, -6.2, 2.25]]
	for a: Array in stores:
		var c := _add_cell(rng, Vector3(a[0], a[1], a[2]), float(a[3]), "store", 0.0)
		if c.is_empty():
			continue
		var at: Vector3 = c.at
		var r := float(c.radius)
		var toward := Vector3(-at.x, 0, 2.0 - at.z).normalized()
		var side := toward.cross(Vector3.UP).normalized()
		for k: float in [-1.0, 1.0]:
			jars.append(at + toward * r * 0.4 + side * k * r * 0.32 + Vector3(0, -r * 0.25, 0))
	for a: Array in [[-6.8, 3.4, 5.0, 2.25], [6.8, 3.4, 5.2, 2.25]]:
		_add_cell(rng, Vector3(a[0], a[1], a[2]), float(a[3]), "store", 0.0)
	for a: Array in [[-7.3, 1.3, 2.6, 1.1], [7.3, 1.3, 2.8, 1.1], [-0.4, 3.9, -7.6, 1.1], [-7.0, 1.3, -4.4, 1.1],
			[7.0, 1.3, -4.2, 1.1], [0.2, 4.3, -4.6, 0.9]]:
		_add_cell(rng, Vector3(a[0], a[1], a[2]), float(a[3]), "pale")
	# The green outer cells under the waxy roof (the cactus builds its sugar in its stem's skin).
	_colonnade(rng, 2.9, 0.75)


func _vein(z: float, y: float) -> void:
	vein = {"from": Vector3(-HALF, y, z), "to": Vector3(HALF, y, z), "radius": 1.0,
		"blue": Vector3(0, -0.28, -0.22), "gold": Vector3(0, 0.3, 0.28), "pipe": 0.36,
		"gold_mouth": Vector3(0.9, y + 0.4, z + 1.35), "blue_mouth": Vector3(-1.4, y - 0.3, z + 1.35)}


## The tall columns on a loose grid, open over the doors (the skylight: the light falls on them, the roof and the bud
## show) and at the way in (nothing hangs over the child's view).
func _colonnade(rng: RandomNumberGenerator, spacing: float, radius: float) -> void:
	var n := int(floor(HALF * 2.0 / spacing))
	var first := -spacing * (n - 1) * 0.5
	for i in n:
		for j in n:
			var x := first + i * spacing + rng.randf_range(-0.22, 0.22)
			var z := first + j * spacing + rng.randf_range(-0.22, 0.22)
			if pow(x / SKYLIGHT.x, 2) + pow((z - SKYLIGHT_AT) / SKYLIGHT.y, 2) < 1.0 or z > WAY_IN:
				continue
			var r := radius * rng.randf_range(0.9, 1.1)
			columns.append({"at": Vector3(x, COLUMNS_FROM, z), "top": COLUMNS_TO, "radius": r,
				"turn": rng.randf_range(0.0, TAU)})


## A cell near `at` of about `radius`, moved and sized a little by the seed, shrunk or nudged until it fits ({} when it
## can't).
func _add_cell(rng: RandomNumberGenerator, at: Vector3, radius: float, kind: String, wobble: float = 0.3) -> Dictionary:
	var p := at + Vector3(rng.randf_range(-wobble, wobble), rng.randf_range(-wobble, wobble) * 0.5,
		rng.randf_range(-wobble, wobble))
	var r := radius * rng.randf_range(0.92, 1.08)
	var squash := rng.randf_range(0.82, 0.96)
	var turn := rng.randf_range(0.0, TAU)
	for i in 12:
		if _fits(p, r):
			var c := {"at": p, "radius": r, "kind": kind, "squash": squash, "turn": turn}
			cells.append(c)
			return c
		r *= 0.93
		p.y += 0.12
	return {}


## Whether a cell (a ball at `p` of radius `r`) keeps clear of the doors' headroom, the sugar spots, the pipes' mouths,
## the way in, the vein and the walls.
func _fits(p: Vector3, r: float) -> bool:
	if p.y - r < -0.2 or absf(p.x) > HALF + 0.6 or absf(p.z) > HALF + 0.6:
		return false
	for d in doors:
		var a: Vector3 = d.at
		for h: float in [0.0, 0.6, 1.2, 1.8, DOOR_ROOM_UP]:
			if Vector3(a.x, h, a.z).distance_to(p) < r + 0.55:
				return false
		if Vector2(a.x, a.z).distance_to(Vector2(p.x, p.z)) < DOOR_ROOM and p.y - r < DOOR_ROOM_UP:
			return false
	for s in sugar_spots:
		if s.distance_to(p) < r + 0.55:
			return false
	for m: Vector3 in [vein.gold_mouth, vein.blue_mouth]:
		if m.distance_to(p) < r + 0.6:
			return false
	if _to_segment(p, vein.from, vein.to) < r + float(vein.radius) - 0.25:
		return false
	return true


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [setting, seed])
	return rng


# --- The flyer and sight -------------------------------------------------------------------------------------------

## Whether a ball of `radius` at `p` is in the open (inside the walls, between the floor and the roof, in no cell,
## column or the vein).
func free_at(p: Vector3, radius: float) -> bool:
	if p.y < radius - 0.0001 or p.y > ROOF - radius + 0.0001:
		return false
	if absf(p.x) > HALF - radius + 0.0001 or absf(p.z) > HALF - radius + 0.0001:
		return false
	for c in cells:
		if p.distance_to(c.at) < float(c.radius) + radius - 0.0001:
			return false
	for k in columns:
		if _to_column(p, k) < float(k.radius) + radius - 0.0001:
			return false
	return _to_segment(p, vein.from, vein.to) >= float(vein.radius) + radius - 0.0001


## `p` moved the least way out of every solid, for a flyer of `radius` (the walls, the floor and the roof hold it in).
func push_out(p: Vector3, radius: float) -> Vector3:
	var q := p
	for pass_i in 4:
		for c in cells:
			q = _out_of_ball(q, c.at, float(c.radius) + radius)
		for k in columns:
			var a: Vector3 = k.at
			var on := Vector3(a.x, clampf(q.y, a.y, float(k.top)), a.z)
			var aside := Vector3(-a.x, 0, -a.z).normalized() if Vector2(a.x, a.z).length() > 0.01 else Vector3.RIGHT
			q = _out_of_ball(q, on, float(k.radius) + radius, aside)
		var v_on := _closest_on_segment(q, vein.from, vein.to)
		q = _out_of_ball(q, v_on, float(vein.radius) + radius)
		q.x = clampf(q.x, -HALF + radius, HALF - radius)
		q.z = clampf(q.z, -HALF + radius, HALF - radius)
		q.y = clampf(q.y, radius, ROOF - radius)
	return q


## Whether nothing solid stands between `a` and `b` (see-through store cells don't hide what is in them when
## `see_through`).
func clear_line(a: Vector3, b: Vector3, see_through: bool = true) -> bool:
	for c in cells:
		if see_through and str(c.kind) == "store":
			continue
		if _to_segment(c.at, a, b) < float(c.radius) - 0.02:
			return false
	for k in columns:
		var base: Vector3 = k.at
		var top := Vector3(base.x, float(k.top), base.z)
		if _segment_gap(a, b, base, top) < float(k.radius) - 0.02:
			return false
	return _segment_gap(a, b, vein.from, vein.to) >= float(vein.radius) - 0.02


## Out of a ball round `centre` (a column's axis point for a column); `fallback` when exactly at its middle.
static func _out_of_ball(q: Vector3, centre: Vector3, reach: float, fallback: Vector3 = Vector3.UP) -> Vector3:
	var d := q - centre
	var dist := d.length()
	if dist >= reach:
		return q
	if dist < 0.0001:
		d = fallback
		dist = 1.0
	return centre + d / dist * reach


func _to_column(p: Vector3, k: Dictionary) -> float:
	var a: Vector3 = k.at
	return p.distance_to(Vector3(a.x, clampf(p.y, a.y, float(k.top)), a.z))


static func _closest_on_segment(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
	var ab := b - a
	var len2 := ab.length_squared()
	if len2 < 0.000001:
		return a
	return a + ab * clampf((p - a).dot(ab) / len2, 0.0, 1.0)


static func _to_segment(p: Vector3, a: Vector3, b: Vector3) -> float:
	return p.distance_to(_closest_on_segment(p, a, b))


## The closest two segments come (p1-q1 and p2-q2).
static func _segment_gap(p1: Vector3, q1: Vector3, p2: Vector3, q2: Vector3) -> float:
	var pair := Geometry3D.get_closest_points_between_segments(p1, q1, p2, q2)
	return (pair[0] as Vector3).distance_to(pair[1])
