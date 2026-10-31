class_name BrickBond
extends RefCounted
## Owner #116 (docs/superpowers/plans/2026-10-16-vr-round4.md "Round 4b", Real Builder): real brickwork, true to size, as
## pure rules. A brick is 215 x 102.5 x 65 mm laid with 10 mm joints (its place along a course is 225 mm, a course 75 mm:
## the work sizes of BS EN 771-1 and the Brick Development Association); the Little track's big concrete blocks 440 x 100
## x 215 mm (450 and 225: one block takes the place of six bricks). Walls are laid in **stretcher bond**: each course's
## joints sit half a brick from the joints below, so each brick sits across two (a free wall's every other course starts
## with a half; a building's corners take turns: the front and back walls own the corners on even courses, the sides on
## odd ones, which gives the half-brick stagger by itself). Openings (a door, a window) are cut on the joints, so their
## cut bricks are half bricks; a **lintel** in the course above carries the bricks over the opening, resting at least
## LINTEL_BEARING on the wall each side. A wall whose joints line up course over course has **straight joints** and
## splits there: the push test (straight_joints).
##
## plan(spec): spec {kind ("brick" / "block"), shape ("wall": one free-standing run; "box": four walls), length and
## depth (in whole bricks along the front and the side), courses, origin (the front-left outer corner on the footing),
## openings [{run, from (whole bricks from the run's start), width (bricks), sill (its first course), height
## (courses)}]} -> {kind, unit, shape, length (m), depth (m), courses, height (m), origin, runs {id: {from, dir,
## length}}, bricks [{id, run, course, u0, u1 (m along the run), cut, centre (Vector3), size, yaw}], lintels [the same
## shape], openings [{run, u_a, u_b, c0, c1}]}.

const JOINT := 0.01
const UNITS := {
	"brick": {"size": Vector3(0.215, 0.065, 0.1025), "pitch": 0.225, "course": 0.075},
	"block": {"size": Vector3(0.44, 0.215, 0.1), "pitch": 0.45, "course": 0.225},
}
## A lintel rests at least this far on the wall at each end (m).
const LINTEL_BEARING := 0.15
## Joints in two courses closer than this line up: a straight joint (m).
const STRAIGHT_JOINT := 0.05
## A brick needs something under this share of it.
const SUPPORT := 0.5
const EPS := 0.0005


static func unit(kind: String) -> Dictionary:
	return (UNITS.get(kind, UNITS.brick) as Dictionary).duplicate()


static func plan(spec: Dictionary) -> Dictionary:
	var kind := str(spec.get("kind", "brick"))
	var u := unit(kind)
	var size: Vector3 = u.size
	var pitch := float(u.pitch)
	var shape := str(spec.get("shape", "wall"))
	var n := int(spec.get("length", 4))
	var m := int(spec.get("depth", 0))
	var courses := int(spec.get("courses", 1))
	var origin: Vector3 = spec.get("origin", Vector3.ZERO)
	var length := n * pitch - JOINT
	var depth := m * pitch - JOINT if shape == "box" else size.z
	var t := size.z
	var runs := {}
	if shape == "box":
		runs.front = {"from": origin + Vector3(0, 0, -t * 0.5), "dir": Vector3.RIGHT, "length": length, "even": true}
		runs.back = {"from": origin + Vector3(0, 0, -depth + t * 0.5), "dir": Vector3.RIGHT, "length": length, "even": true}
		runs.left = {"from": origin + Vector3(t * 0.5, 0, 0), "dir": Vector3.FORWARD, "length": depth, "even": false}
		runs.right = {"from": origin + Vector3(length - t * 0.5, 0, 0), "dir": Vector3.FORWARD, "length": depth, "even": false}
	else:
		runs.wall = {"from": origin + Vector3(0, 0, -t * 0.5), "dir": Vector3.RIGHT, "length": length, "free": true}
	var openings: Array[Dictionary] = []
	for o: Variant in spec.get("openings", []):
		if not o is Dictionary or not runs.has(str(o.get("run", ""))):
			continue
		var from := int(o.get("from", 1))
		var w := int(o.get("width", 1))
		var c0 := int(o.get("sill", 0))
		openings.append({"run": str(o.run), "u_a": from * pitch - JOINT, "u_b": (from + w) * pitch, "c0": c0,
			"c1": c0 + int(o.get("height", 1))})
	var bricks: Array[Dictionary] = []
	var lintels: Array[Dictionary] = []
	for run_id: String in runs:
		var run: Dictionary = runs[run_id]
		for c in courses:
			var spans := _course_spans(run, c, size.x, pitch)
			for o in openings:
				if str(o.run) != run_id:
					continue
				if c >= int(o.c0) and c < int(o.c1):
					spans = _cut(spans, float(o.u_a), float(o.u_b))
				elif c == int(o.c1):
					var l := _lintel_span(spans, float(o.u_a), float(o.u_b), float(run.length))
					spans = l[0]
					lintels.append(_piece(run_id, run, c, float(l[1].x), float(l[1].y), u, "lintel_%s_%d" % [run_id, c], true))
			var i := 0
			for s: Vector2 in spans:
				bricks.append(_piece(run_id, run, c, s.x, s.y, u, "%s_c%d_%d" % [run_id, c, i],
					s.y - s.x < size.x - EPS))
				i += 1
	return {"kind": kind, "unit": u, "shape": shape, "length": length, "depth": depth, "courses": courses,
		"height": courses * float(u.course), "origin": origin, "runs": runs, "bricks": bricks, "lintels": lintels,
		"openings": openings}


## The coach's quick test wall for the push test: `n` bricks long, every course laid the same (no stagger at all).
static func stacked_wall(kind: String, n: int, courses: int, origin: Vector3 = Vector3.ZERO) -> Array[Dictionary]:
	var u := unit(kind)
	var run := {"from": origin + Vector3(0, 0, -(u.size as Vector3).z * 0.5), "dir": Vector3.RIGHT,
		"length": n * float(u.pitch) - JOINT}
	var out: Array[Dictionary] = []
	for c in courses:
		for i in n:
			var u0 := i * float(u.pitch)
			out.append(_piece("test", run, c, u0, u0 + (u.size as Vector3).x, u, "test_c%d_%d" % [c, i], false))
	return out


## Where the joints line up course over course: [{run, u, course (the lower one)}]. [] for a wall in bond.
static func straight_joints(bricks: Array) -> Array:
	var joints := {}   # run -> course -> [u]
	var by := {}
	for b: Variant in bricks:
		var key := "%s|%d" % [b.run, b.course]
		if not by.has(key):
			by[key] = []
		(by[key] as Array).append(b)
	for key: String in by:
		var list: Array = by[key]
		list.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.u0) < float(y.u0))
		var parts := key.split("|")
		if not joints.has(parts[0]):
			joints[parts[0]] = {}
		var us: Array[float] = []
		for i in range(1, list.size()):
			var gap := float(list[i].u0) - float(list[i - 1].u1)
			if gap < JOINT * 2.0:
				us.append((float(list[i].u0) + float(list[i - 1].u1)) * 0.5)
		joints[parts[0]][int(parts[1])] = us
	var out := []
	for run: String in joints:
		var courses: Dictionary = joints[run]
		for c: int in courses:
			if not courses.has(c + 1):
				continue
			for a: float in courses[c]:
				for b: float in courses[c + 1]:
					if absf(a - b) < STRAIGHT_JOINT:
						out.append({"run": run, "u": a, "course": c})
	out.sort_custom(func(x: Dictionary, y: Dictionary) -> bool:
		if str(x.run) != str(y.run):
			return str(x.run) < str(y.run)
		if int(x.course) != int(y.course):
			return int(x.course) < int(y.course)
		return float(x.u) < float(y.u))
	return out


## Two pieces in the same place (the same run and course: their spans; else their boxes).
static func overlap(a: Dictionary, b: Dictionary) -> bool:
	if int(a.get("course", -1)) != int(b.get("course", -2)):
		return false
	if str(a.get("run", "")) == str(b.get("run", "")):
		return minf(float(a.u1), float(b.u1)) - maxf(float(a.u0), float(b.u0)) > EPS
	if not a.has("centre") or not b.has("centre"):
		return false
	var ra := _rect(a)
	var rb := _rect(b)
	var i := ra.intersection(rb)
	return i.size.x > EPS and i.size.y > EPS


## The bricks with too little under them ([] when every one sits on a brick, a lintel or the footing).
static func floating(p: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var below := {}   # course -> [Rect2]
	for b: Dictionary in (p.bricks as Array) + (p.lintels as Array):
		var c := int(b.course)
		if not below.has(c):
			below[c] = []
		(below[c] as Array).append(_rect_in(p, b))
	for b: Dictionary in p.bricks:
		var c := int(b.course)
		if c == 0:
			continue
		var r := _rect_in(p, b)
		var under := 0.0
		for o: Rect2 in below.get(c - 1, []):
			var i := r.intersection(o)
			under += maxf(i.size.x, 0.0) * maxf(i.size.y, 0.0)
		if under < r.get_area() * SUPPORT:
			out.append(str(b.id))
	return out


## The index of the place nearest to `at` (their centres) within `reach`, -1 for none.
static func nearest(places: Array, at: Vector3, reach: float) -> int:
	var best := -1
	var d := reach
	for i in places.size():
		var c: Vector3 = places[i].centre
		var di := c.distance_to(at)
		if di <= d:
			d = di
			best = i
	return best


# --- Building a course ---------------------------------------------------------------------------------------------

## A course's bricks along a run as [u0, u1] spans: a free wall starts every other course with a half; a corner run
## owns its corners on its own courses (even or odd) and fills between the other walls' ends on the rest.
static func _course_spans(run: Dictionary, c: int, brick: float, pitch: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var length := float(run.length)
	var half := pitch * 0.5
	if bool(run.get("free", false)):
		var u0 := 0.0
		if c % 2 == 1:
			out.append(Vector2(0.0, half - JOINT))
			u0 = half
		while u0 + brick <= length + EPS:
			out.append(Vector2(u0, u0 + brick))
			u0 += pitch
		if u0 < length - EPS:
			out.append(Vector2(u0, length))
		return out
	var owns := (c % 2 == 0) == bool(run.even)
	var start := 0.0 if owns else half
	var end := length if owns else length - half
	var u := start
	while u + brick <= end + EPS:
		out.append(Vector2(u, u + brick))
		u += pitch
	if u < end - EPS:
		out.append(Vector2(u, end))
	return out


## The spans with [u_a, u_b] cut out (a brick across the edge is cut there: a half brick on the joint grid).
static func _cut(spans: Array[Vector2], u_a: float, u_b: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for s in spans:
		if s.y <= u_a + EPS or s.x >= u_b - EPS:
			out.append(s)
			continue
		if s.x < u_a - 0.05:
			out.append(Vector2(s.x, u_a))
		if s.y > u_b + 0.05:
			out.append(Vector2(u_b, s.y))
	return out


## The lintel's course: the bricks within LINTEL_BEARING of the opening come out and the lintel fills from the brick
## before to the brick after. [the kept spans, Vector2(lintel u0, u1)].
static func _lintel_span(spans: Array[Vector2], u_a: float, u_b: float, length: float) -> Array:
	var kept: Array[Vector2] = []
	var from := 0.0
	var to := length
	for s in spans:
		if s.y <= u_a - LINTEL_BEARING + EPS:
			kept.append(s)
			from = maxf(from, s.y + JOINT)
		elif s.x >= u_b + LINTEL_BEARING - EPS:
			kept.append(s)
			to = minf(to, s.x - JOINT)
	return [kept, Vector2(from, to)]


static func _piece(run_id: String, run: Dictionary, c: int, u0: float, u1: float, u: Dictionary, id: String,
		cut: bool) -> Dictionary:
	var size: Vector3 = u.size
	var dir: Vector3 = run.dir
	var centre: Vector3 = (run.from as Vector3) + dir * ((u0 + u1) * 0.5) \
		+ Vector3(0, c * float(u.course) + JOINT + size.y * 0.5, 0)
	return {"id": id, "run": run_id, "course": c, "u0": u0, "u1": u1, "cut": cut, "centre": centre,
		"size": Vector3(u1 - u0, size.y, size.z), "yaw": atan2(-dir.z, dir.x)}


## A piece's footprint (x, z) from its centre, size and yaw (the runs are square to the axes).
static func _rect(b: Dictionary) -> Rect2:
	var c: Vector3 = b.centre
	var s: Vector3 = b.size
	var along_z := absf(sin(float(b.get("yaw", 0.0)))) > 0.5
	var ext := Vector2(s.z, s.x) if along_z else Vector2(s.x, s.z)
	return Rect2(Vector2(c.x, c.z) - ext * 0.5, ext)


## A piece's footprint from its run's line (works for a piece without a centre).
static func _rect_in(p: Dictionary, b: Dictionary) -> Rect2:
	var run: Dictionary = (p.runs as Dictionary).get(str(b.run), {})
	if run.is_empty():
		return _rect(b) if b.has("centre") else Rect2()
	var t: float = ((p.unit as Dictionary).size as Vector3).z
	var dir: Vector3 = run.dir
	var a: Vector3 = (run.from as Vector3) + dir * float(b.u0)
	var e: Vector3 = (run.from as Vector3) + dir * float(b.u1)
	var side := Vector3(-dir.z, 0, dir.x) * t * 0.5
	var pts := [a + side, a - side, e + side, e - side]
	var r := Rect2(Vector2(pts[0].x, pts[0].z), Vector2.ZERO)
	for q: Vector3 in pts:
		r = r.expand(Vector2(q.x, q.z))
	return r
