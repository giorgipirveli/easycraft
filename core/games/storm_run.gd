class_name StormRun
extends RefCounted
## Storm Run as pure rules (M4 Wave 3, agent H; spec §13.7, §17.5): a glowing circle shrinks from
## RADIUS_START to RADIUS_END over TIME while its centre drifts along waypoints (LEGS legs, never more
## than DRIFT from the start, slower than walking); stars appear inside it (at most MAX_STARS at once)
## and anyone can take one for the team; outside the circle a body is gently pushed back in (no damage,
## nobody out). The host keeps the round; every game gets a copy (to_state / from_state) and draws the
## same circle from the same clock.

const TIME := 180.0
const RADIUS_START := 40.0
const RADIUS_END := 8.0
const LEGS := 6                   # a new waypoint every 30 s
const DRIFT := 16.0               # blocks the centre may wander from the start
const LEG_MAX := 12.0             # blocks per leg: under half a block a second
const LEG_MIN := 5.0
const WAYPOINT_TRIES := 10
const STAR_EVERY := 1.5           # seconds between new stars
const MAX_STARS := 10             # the pool of star meshes
const STAR_INSIDE := 0.85         # new stars within this share of the radius
const STAR_REACH := 1.6           # blocks from the body's middle to a star's centre
const STAR_SLACK := 1.5           # the host's slack for a guest's request (latency)
const BODY_MIDDLE := 0.9
const PUSH_SPEED := 5.0           # m/s back in, just outside
const PUSH_PER_BLOCK := 1.5       # ... and this much more for every block further out
const PUSH_MAX := 12.0

var elapsed := 0.0
var waypoints: Array[Vector2] = []
var stars := {}                   # id -> Vector3 (the star's centre)
var score := 0
var best := 0

var _running := false
var _spawn_t := 0.0
var _next_id := 1
var _new_best := false


## The circle's radius `t` seconds into the round.
static func radius_at(t: float) -> float:
	return lerpf(RADIUS_START, RADIUS_END, clampf(t / TIME, 0.0, 1.0))


## LEGS + 1 points, the first `start`: each within LEG_MAX of the last and DRIFT of the start, and
## good ground (is_good(Vector2) -> bool: not water, not a cliff); none found: the centre stays.
static func make_waypoints(start: Vector2, roll: int, is_good: Callable) -> Array[Vector2]:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([roll, start])
	var out: Array[Vector2] = [start]
	for i in LEGS:
		var last := out[-1]
		var next := last
		for t in WAYPOINT_TRIES:
			var p := last + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(LEG_MIN, LEG_MAX)
			if p.distance_to(start) <= DRIFT and bool(is_good.call(p)):
				next = p
				break
		out.append(next)
	return out


## The circle's centre `t` seconds in: along the waypoints, easing in and out of each.
static func centre_at(t: float, ways: Array[Vector2]) -> Vector2:
	if ways.is_empty():
		return Vector2.ZERO
	var leg_time := TIME / float(maxi(ways.size() - 1, 1))
	var legs := clampf(t, 0.0, TIME) / leg_time
	var i := mini(floori(legs), ways.size() - 1)
	if i >= ways.size() - 1:
		return ways[-1]
	return ways[i].lerp(ways[i + 1], smoothstep(0.0, 1.0, legs - float(i)))


## How far outside a circle (flat) a body at `pos` is; 0 or less inside.
static func outside_by(pos: Vector3, centre: Vector2, radius: float) -> float:
	return Vector2(pos.x, pos.z).distance_to(centre) - radius


## The gentle push back in for a body at `pos` (a flat velocity, m/s; ZERO inside).
static func push(pos: Vector3, centre: Vector2, radius: float) -> Vector3:
	var out := outside_by(pos, centre, radius)
	if out <= 0.0 or not pos.is_finite():
		return Vector3.ZERO
	var dir := (centre - Vector2(pos.x, pos.z)).normalized()
	var speed := minf(PUSH_SPEED + out * PUSH_PER_BLOCK, PUSH_MAX)
	return Vector3(dir.x, 0.0, dir.y) * speed


## Where a new star goes (flat): inside the circle, spread over its area (rolls 0..1).
static func star_spot(centre: Vector2, radius: float, roll_angle: float, roll_dist: float) -> Vector2:
	return centre + Vector2.from_angle(roll_angle * TAU) * sqrt(clampf(roll_dist, 0.0, 1.0)) * radius * STAR_INSIDE


## Does a body standing at `feet` touch the star at `star`? (`slack`: the host's, for a guest.)
static func can_take(feet: Vector3, star: Vector3, slack: float = 0.0) -> bool:
	return feet.is_finite() and (feet + Vector3(0, BODY_MIDDLE, 0)).distance_to(star) <= STAR_REACH + slack


# --- A round (the host's; every game keeps a copy) ---

func start(ways: Array[Vector2]) -> void:
	waypoints = ways.duplicate()
	elapsed = 0.0
	stars.clear()
	score = 0
	_running = not waypoints.is_empty()
	_spawn_t = 0.0
	_new_best = false


func running() -> bool:
	return _running


func time_left() -> float:
	return maxf(TIME - elapsed, 0.0) if _running else 0.0


func circle_centre() -> Vector2:
	return centre_at(elapsed, waypoints)


func circle_radius() -> float:
	return radius_at(elapsed)


## Moves the clock: {"spawn": a star is due (the host picks its spot and calls add_star), "gone": ids of
## stars now outside the circle (removed), "over": the round just ended (best updated)}.
func advance(dt: float) -> Dictionary:
	var step := {"spawn": false, "gone": [], "over": false}
	if not _running:
		return step
	elapsed += dt
	if elapsed >= TIME:
		elapsed = TIME
		_running = false
		_new_best = score > best
		best = maxi(best, score)
		step.over = true
		return step
	var c := circle_centre()
	var r := circle_radius()
	for id: int in stars.keys():
		if outside_by(stars[id], c, r) > 0.0:
			stars.erase(id)
			(step.gone as Array).append(id)
	_spawn_t -= dt
	if _spawn_t <= 0.0 and stars.size() < MAX_STARS:
		_spawn_t = STAR_EVERY
		step.spawn = true
	return step


## A new star at `pos`; its id, or -1 (no round, or the pool is full).
func add_star(pos: Vector3) -> int:
	if not _running or stars.size() >= MAX_STARS or not pos.is_finite():
		return -1
	var id := _next_id
	_next_id += 1
	stars[id] = pos
	return id


## Someone took star `id` for the team. True when it was there.
func take(id: int) -> bool:
	if not _running or not stars.has(id):
		return false
	stars.erase(id)
	score += 1
	return true


## The round that just ended beat the world's best.
func new_best() -> bool:
	return _new_best


func to_state() -> Dictionary:
	var ways: Array = []
	for w in waypoints:
		ways.append([w.x, w.y])
	var s := {}
	for id: int in stars:
		var p: Vector3 = stars[id]
		s[id] = [p.x, p.y, p.z]
	return {"elapsed": elapsed, "waypoints": ways, "stars": s, "score": score, "best": best, "running": _running}


## A copy from the host's state; anything broken is no round.
static func from_state(d: Dictionary) -> StormRun:
	var r := StormRun.new()
	var e: Variant = d.get("elapsed")
	var ways: Variant = d.get("waypoints")
	if not typeof(e) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(e)) or not ways is Array:
		return r
	for w: Variant in ways:
		if w is Array and (w as Array).size() == 2 and (w as Array).all(_finite) and r.waypoints.size() <= LEGS:
			r.waypoints.append(Vector2(float(w[0]), float(w[1])))
	r.elapsed = clampf(float(e), 0.0, TIME)
	var s: Variant = d.get("stars")
	if s is Dictionary:
		for id: Variant in s:
			var p: Variant = s[id]
			if typeof(id) in [TYPE_INT, TYPE_FLOAT] and p is Array and (p as Array).size() == 3 and (p as Array).all(_finite) \
					and r.stars.size() < MAX_STARS:
				r.stars[int(id)] = Vector3(float(p[0]), float(p[1]), float(p[2]))
	r.score = maxi(int(d.get("score", 0)), 0) if typeof(d.get("score")) in [TYPE_INT, TYPE_FLOAT] else 0
	r.best = maxi(int(d.get("best", 0)), 0) if typeof(d.get("best")) in [TYPE_INT, TYPE_FLOAT] else 0
	r._running = d.get("running") is bool and bool(d.running) and not r.waypoints.is_empty()
	return r


static func _finite(x: Variant) -> bool:
	return typeof(x) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(x))
