class_name RaceGhost
extends RefCounted
## A best run on a course, as a ghost friends race (M4 ghost races; spec §17.5, research T2). Made from the
## course's recorded run (RecordedRun, M3 Task 7: 10 samples a second) by sampling it 5 times a second, evenly
## over the run's time; kept in decimetres from the top of the START block (its middle, one block up). Sent in
## the server's format (server/modules/src/rules/ghost_rules.ts, GhostRules: int16 little-endian triplets in
## base64) and checked the way the server checks it, so the game offers only what the server will take: START
## and FINISH where it says, from START to FINISH, around the course, never faster than the game's fastest
## move, and "jumps" (a fall brought back to a checkpoint, a teleport pad's trip) only onto the top of a START,
## CHECKPOINT or TELEPORT_PAD. Played back smoothly, a jump as a blink; turned like a stamp for a gift.

const SAMPLE_MS := 200
const MIN_MS := 1000
const MAX_MS := 180000
const MAX_SAMPLES := MAX_MS / SAMPLE_MS + 1
const MAX_LOOK := 2048
const MAX_SPEED := 40.0          # m/s: the game's fastest move is a launch pad's 30 (test_race_ghost.gd)
const STEP_SLACK_DM := 10        # a block of slack on every step
const FIRST_REACH_DM := 30       # the first sample: within 3 blocks of START's top
const LAST_REACH_DM := 10        # the last: FINISH's top
const LAND_REACH_DM := 30        # a jump lands within 3 blocks of a landing block's top
const MAX_JUMPS := 64
const MARGIN := 4                # blocks around the course's box
const UP_MARGIN := 24
const DOWN_MARGIN := 16
const MAX_ID := 64
const LANDINGS: Array[int] = [BlockIds.START, BlockIds.CHECKPOINT, BlockIds.TELEPORT_PAD]

## The server's codes (GhostRules.check).
const BAD := "bad_ghost"
const NOT_ON_COURSE := "not_on_course"
const IMPOSSIBLE := "impossible_run"

var start := Vector3i.ZERO       # the START cell in its course's box (the showcase area, a gift's build)
var finish := Vector3i.ZERO
var ms := 0                      # the run's time
var points := PackedVector3Array()   # from START's top, in blocks, whole decimetres, evenly over `ms`
var look := ""                   # the racer's avatar look code ("" = the default look)
var id := ""                     # the server's ghost_id (a showcase ghost; "" for a gift's)
var owner_id := ""
var owner := ""


static func sample_count(run_ms: int) -> int:
	return roundi(run_ms / float(SAMPLE_MS)) + 1


## The ghost of a recorded run (its origin is START's top) that took `run_ms`, on a course whose START and
## FINISH are `start_cell` and `finish_cell` in the box it travels with. null without two samples.
static func from_run(run: RecordedRun, run_ms: int, start_cell: Vector3i, finish_cell: Vector3i, look_code: String) -> RaceGhost:
	if run == null or run.size() < 2 or run_ms <= 0:
		return null
	var g := RaceGhost.new()
	g.start = start_cell
	g.finish = finish_cell
	g.ms = run_ms
	g.look = look_code
	var n := sample_count(run_ms)
	var span := run.duration()
	for i in n:
		var p := _snapped(run, span * i / float(n - 1)) - run.origin
		g.points.append(Vector3(roundi(p.x * 10.0), roundi(p.y * 10.0), roundi(p.z * 10.0)) / 10.0)
	return g


## A recorded run at `t` seconds, but never between the two ends of a jump (a fall brought back to the
## checkpoint, a teleport pad): inside one it is already where it landed.
static func _snapped(run: RecordedRun, t: float) -> Vector3:
	var f := clampf(t / RecordedRun.DT, 0.0, run.size() - 1)
	var i := floori(f)
	if i >= run.size() - 1:
		return run.points[run.size() - 1]
	var a := run.points[i]
	var b := run.points[i + 1]
	if a.distance_to(b) > MAX_SPEED * RecordedRun.DT + STEP_SLACK_DM / 10.0:
		return b if f > i else a
	return a.lerp(b, f - i)


func path_text() -> String:
	var bytes := PackedByteArray()
	bytes.resize(points.size() * 6)
	for i in points.size():
		for k in 3:
			bytes.encode_s16(i * 6 + k * 2, clampi(roundi(points[i][k] * 10.0), -32768, 32767))
	return Marshalls.raw_to_base64(bytes)


## As share_ghost takes it: {"start", "finish", "ms", "path", "look"}.
func to_wire() -> Dictionary:
	return {"start": [start.x, start.y, start.z], "finish": [finish.x, finish.y, finish.z], "ms": ms,
		"path": path_text(), "look": look}


## A ghost from the server (list_ghosts, open_gift) or this device's book, or null when its shape is broken
## (the course's checks are check()'s). A list's entry keeps its ghost_id.
static func from_wire(d: Variant) -> RaceGhost:
	if not d is Dictionary:
		return null
	var w: Dictionary = d
	var s: Variant = _cell(w.get("start"))
	var f: Variant = _cell(w.get("finish"))
	var t: Variant = w.get("ms")
	var lk: Variant = w.get("look", "")
	var gid: Variant = w.get("ghost_id", "")
	if s == null or f == null or not _whole(t) or int(t) < MIN_MS or int(t) > MAX_MS or not is_look(lk) \
			or not gid is String or (gid as String).length() > MAX_ID:
		return null
	var pts := _decode(w.get("path"))
	if pts.size() < 2 or absi((pts.size() - 1) * SAMPLE_MS - int(t)) > SAMPLE_MS:
		return null
	var g := RaceGhost.new()
	g.start = s
	g.finish = f
	g.ms = int(t)
	g.points = pts
	g.look = lk
	g.id = gid
	return g


## "" (the default look) or a JSON object's text within MAX_LOOK (AvatarLook.from_code reads it carefully).
static func is_look(v: Variant) -> bool:
	if v is String and v == "":
		return true
	if not v is String or (v as String).length() > MAX_LOOK:
		return false
	var json := JSON.new()
	return json.parse(v) == OK and json.data is Dictionary


static func _decode(v: Variant) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not v is String or (v as String).length() % 4 != 0 or (v as String).length() > (MAX_SAMPLES * 6 / 3 + 1) * 4:
		return out
	if not _b64.search(v):
		return out
	var bytes := Marshalls.base64_to_raw(v)
	if bytes.size() % 6 != 0 or bytes.size() > MAX_SAMPLES * 6:
		return out
	for i in bytes.size() / 6:
		out.append(Vector3(bytes.decode_s16(i * 6), bytes.decode_s16(i * 6 + 2), bytes.decode_s16(i * 6 + 4)) / 10.0)
	return out


static var _b64 := RegEx.create_from_string("^[A-Za-z0-9+/]*={0,2}$")


static func _whole(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and float(v) == floorf(float(v))


static func _cell(v: Variant) -> Variant:
	if not v is Array or (v as Array).size() != 3:
		return null
	for x: Variant in v:
		if not _whole(x) or float(x) < 0.0 or float(x) > 255.0:
			return null
	return Vector3i(int(v[0]), int(v[1]), int(v[2]))


# --- The server's checks (GhostRules.check) ---

## "" when the server will take this ghost for a course whose box is `size`, reading its blocks through
## block_at(cell in the box) -> id; else BAD, NOT_ON_COURSE or IMPOSSIBLE.
func check(size: Vector3i, block_at: Callable) -> String:
	if not _inside(start, size) or not _inside(finish, size) or ms < MIN_MS or ms > MAX_MS or points.size() < 2 \
			or points.size() > MAX_SAMPLES or absi((points.size() - 1) * SAMPLE_MS - ms) > SAMPLE_MS or not is_look(look):
		return BAD
	if int(block_at.call(start)) != BlockIds.START or int(block_at.call(finish)) != BlockIds.FINISH:
		return NOT_ON_COURSE
	var dm := _decimetres()
	var to_finish := (finish - start) * 10
	if Vector3(dm[0]).length() > FIRST_REACH_DM or Vector3(dm[dm.size() - 1] - to_finish).length() > LAST_REACH_DM:
		return IMPOSSIBLE
	var lo := Vector3((-MARGIN - start.x - 0.5) * 10, (-DOWN_MARGIN - start.y - 1) * 10, (-MARGIN - start.z - 0.5) * 10)
	var hi := Vector3((size.x + MARGIN - start.x - 0.5) * 10, (size.y + UP_MARGIN - start.y - 1) * 10,
		(size.z + MARGIN - start.z - 0.5) * 10)
	var step := MAX_SPEED * (ms / float(points.size() - 1)) / 100.0 + STEP_SLACK_DM
	var jumps := 0
	for i in dm.size():
		var p := Vector3(dm[i])
		for a in 3:
			if p[a] < lo[a] or p[a] > hi[a]:
				return IMPOSSIBLE
		if i == 0 or Vector3(dm[i] - dm[i - 1]).length() <= step:
			continue
		jumps += 1
		if jumps > MAX_JUMPS or not _lands(p, size, block_at):
			return IMPOSSIBLE
	return ""


## A jump's landing `p` (decimetres from START's top) is within LAND_REACH_DM of the top of a landing block.
func _lands(p: Vector3, size: Vector3i, block_at: Callable) -> bool:
	var at := Vector3(start) + p / 10.0                 # the landing cell's corner, if it stood on a top
	var reach := ceili(LAND_REACH_DM / 10.0)
	var base := Vector3i(at.floor())
	for x in range(base.x - reach, base.x + reach + 1):
		for y in range(base.y - reach, base.y + reach + 1):
			for z in range(base.z - reach, base.z + reach + 1):
				var c := Vector3i(x, y, z)
				if _inside(c, size) and LANDINGS.has(int(block_at.call(c))) \
						and Vector3((c - start) * 10).distance_to(p) <= LAND_REACH_DM:
					return true
	return false


func _decimetres() -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for q in points:
		out.append(Vector3i(roundi(q.x * 10.0), roundi(q.y * 10.0), roundi(q.z * 10.0)))
	return out


static func _inside(c: Vector3i, size: Vector3i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.z >= 0 and c.x < size.x and c.y < size.y and c.z < size.z


# --- Playback ---

func duration() -> float:
	return ms / 1000.0


## Where the ghost is `t` seconds into its run (from START's top): between two samples, but a jump is a blink.
func sample_at(t: float) -> Vector3:
	if points.is_empty():
		return Vector3.ZERO
	if points.size() == 1 or ms <= 0:
		return points[0]
	var f := clampf(t * 1000.0 / (ms / float(points.size() - 1)), 0.0, points.size() - 1)
	var i := floori(f)
	if i >= points.size() - 1:
		return points[points.size() - 1]
	if _is_jump(i):
		return points[i] if f - i < 0.5 else points[i + 1]
	return points[i].lerp(points[i + 1], f - i)


## Whether the ghost blinks (a jump) between `t0` and `t1` seconds (a puff where it lands).
func jumps_between(t0: float, t1: float) -> bool:
	if points.size() < 2 or ms <= 0:
		return false
	var per := ms / float(points.size() - 1)
	for i in range(maxi(floori(t0 * 1000.0 / per), 0), mini(ceili(t1 * 1000.0 / per), points.size() - 1)):
		if _is_jump(i) and (i + 0.5) * per >= t0 * 1000.0 and (i + 0.5) * per < t1 * 1000.0:
			return true
	return false


func _is_jump(i: int) -> bool:
	var per := ms / float(points.size() - 1)
	return points[i].distance_to(points[i + 1]) > MAX_SPEED * per / 1000.0 + STEP_SLACK_DM / 10.0


## The level way it goes at `t` (ZERO standing still or blinking).
func facing_at(t: float) -> Vector3:
	var d := sample_at(t + 0.1) - sample_at(t - 0.1)
	d.y = 0.0
	return d.normalized() if d.length() > 0.001 and d.length() < MAX_SPEED * 0.2 else Vector3.ZERO


## An offset in the ghost's box turned the way a stamp placed facing `forward` turns its blocks (x to the right,
## z away from the child: Blueprints.to_world); ZERO: not turned (a showcase).
static func turned(offset: Vector3, forward: Vector3i) -> Vector3:
	if forward == Vector3i.ZERO:
		return offset
	var right := Vector3(-forward.z, 0, forward.x)
	return right * offset.x + Vector3.UP * offset.y + Vector3(forward) * offset.z
