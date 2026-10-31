class_name TeleportRules
extends RefCounted
## Owner #101 (VR on the Meta Quest, P3): where a teleport may land, as pure rules. The turning stick pushed up aims a
## falling arc from the pointing hand (arc: thrown at SPEED, gravity GRAVITY); where it first touches a block's top is
## the spot. A spot is good when the child could have walked there: on top of a solid block with room for the body
## (StepRules, the size's clearance), at most MAX_UP above the feet (no climbing walls that walking can't), MAX_DISTANCE
## from the feet at most (no gaps jumped), MIN_DISTANCE at least, in sight of the eyes (no going round a wall the child
## can't see past), never on or into a hiding spot (hide-and-seek), and never where a game says no (`refuse`: a race,
## a course, the Gold Farm's games may refuse a skip).

const SPEED := 7.0          # m/s the arc leaves the hand
const GRAVITY := 9.8
const STEP := 0.04          # s between the arc's points
const MAX_TIME := 2.0
const MAX_DISTANCE := 6.0
const MIN_DISTANCE := 1.0
const MAX_UP := 1.0
const MAX_Y := 512

## Why a spot is no good ("" when it is).
const NOWHERE := "nowhere"  # the arc touched no block's top
const NEAR := "near"
const FAR := "far"
const UP := "up"
const STAND := "stand"      # nothing solid under the feet
const ROOM := "room"        # no room for the body
const SPOT := "spot"        # a hiding spot
const SIGHT := "sight"
const AREA := "area"


## The arc's points from `origin` thrown along `dir`.
static func arc(origin: Vector3, dir: Vector3) -> PackedVector3Array:
	var v := dir.normalized() * SPEED
	var out := PackedVector3Array()
	var t := 0.0
	while t <= MAX_TIME:
		out.append(origin + v * t + Vector3(0.0, -0.5 * GRAVITY * t * t, 0.0))
		t += STEP
	return out


## Where the arc first touches the top of a block `is_target` stops at: {hit, at (the feet's spot), points (the arc up
## to there)}; a side it touches first ends it with no spot (hit false).
static func land(points: PackedVector3Array, is_target: Callable) -> Dictionary:
	var drawn := PackedVector3Array()
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		drawn.append(a)
		var seg := b - a
		var hit := GridRay.cast(a, seg, seg.length(), is_target)
		if hit == null:
			continue
		var p := a + seg.normalized() * hit.distance
		drawn.append(p)
		var top := hit.previous_position.y == hit.position.y + 1
		return {"hit": top, "at": Vector3(p.x, hit.position.y + 1.0, p.z), "points": drawn}
	if not points.is_empty():
		drawn.append(points[points.size() - 1])
	return {"hit": false, "at": Vector3.INF, "points": drawn}


## Whether a child with feet at `feet` and eyes at `eye` may stand at `at` (feet): "" or why not. `radius` and
## `clearance` (blocks) are the body's (its size); `block_at(cell) -> id`; `refuse(at) -> bool` is a game's say.
static func check(feet: Vector3, eye: Vector3, at: Vector3, radius: float, clearance: int, block_at: Callable,
		refuse: Callable) -> String:
	if not at.is_finite():
		return NOWHERE
	var d := at.distance_to(feet)
	if d < MIN_DISTANCE:
		return NEAR
	if d > MAX_DISTANCE:
		return FAR
	if at.y - feet.y > MAX_UP + 0.01:
		return UP
	var cell := Vector3i(at.floor())
	if StealthRules.is_hiding_block(int(block_at.call(cell - Vector3i(0, 1, 0)))):
		return SPOT
	for k in clearance:
		if StealthRules.is_hiding_block(int(block_at.call(cell + Vector3i(0, k, 0)))):
			return SPOT
	if not BlockIds.is_solid(int(block_at.call(cell - Vector3i(0, 1, 0)))):
		return STAND
	var solid := func(c: Vector3i) -> bool: return BlockIds.is_solid(int(block_at.call(c)))
	if StepRules.first_free_y(at, radius, clearance, MAX_Y, solid) != cell.y:
		return ROOM
	var look := at + Vector3(0.0, 0.5, 0.0) - eye
	var blocked := GridRay.cast(eye, look, look.length() - 0.05, solid)
	if blocked != null:
		return SIGHT
	if refuse.is_valid() and bool(refuse.call(at)):
		return AREA
	return ""


## The whole aim: the arc from the hand, where it lands and whether the child may go there: {ok, at, points, why}.
static func target(origin: Vector3, dir: Vector3, feet: Vector3, eye: Vector3, radius: float, clearance: int,
		block_at: Callable, refuse: Callable) -> Dictionary:
	var solid := func(c: Vector3i) -> bool: return BlockIds.is_solid(int(block_at.call(c)))
	var l := land(arc(origin, dir), solid)
	var why := check(feet, eye, l.at, radius, clearance, block_at, refuse) if l.hit else NOWHERE
	return {"ok": why == "", "at": l.at, "points": l.points, "why": why}
