class_name LifeReach
extends RefCounted
## Owner #112, #113 (docs/design/life-skills.md §4, §10: "big, forgiving targets"): where hands, a laser, a finger and
## the head are, in the practice rooms' terms. Pure geometry; the room host (LifeRoomHost) reads the hands and the head
## from Vr and the finger from the screen, and turns them into a step's sample (LifeCheck).

## A hand touches a thing up to this much beyond its radius (m).
const HAND_SLACK := 0.06
## A finger on the screen reaches a thing at least this far from its middle (px of the 1280 × 720 canvas: a child's
## fingertip and a bit; the research's 2 cm targets).
const FINGER_PX := 56.0
## The head is low (under the smoke) this far below where it stood at the start (m).
const LOW_DROP := 0.3
## Both hands cover the face within this distance of the eyes (m).
const FACE_REACH := 0.28


static func touching(hand: Vector3, target: Vector3, radius: float) -> bool:
	return hand.distance_to(target) <= radius + HAND_SLACK


## How far along the ray a round target is hit (m), or -1 when missed (or behind the hand).
static func ray_hit(origin: Vector3, dir: Vector3, centre: Vector3, radius: float) -> float:
	var d := dir.normalized()
	var along := (centre - origin).dot(d)
	if along <= 0.0:
		return -1.0
	var closest := origin + d * along
	return along if closest.distance_to(centre) <= radius else -1.0


## Where across a target (along `right`, -1 at its left edge, 1 at its right) the laser crosses the plane through its
## middle facing the ray; NAN when it misses the target's width or height.
static func across(origin: Vector3, dir: Vector3, centre: Vector3, right: Vector3, half_width: float) -> float:
	var d := dir.normalized()
	var normal := -d
	var denom := d.dot(normal)
	if absf(denom) < 0.0001:
		return NAN
	var t := (centre - origin).dot(normal) / denom
	if t <= 0.0:
		return NAN
	var hit := origin + d * t - centre
	var r := right.normalized()
	var u := hit.dot(r) / half_width
	var up := (hit - r * hit.dot(r)).length()
	if absf(u) > 1.3 or up > half_width * 1.3:
		return NAN
	return clampf(u, -1.0, 1.0)


## The target a finger at `tap` picks: the nearest whose screen middle (`at`) is within its screen radius, or at least
## FINGER_PX; "" when none.
static func screen_pick(tap: Vector2, at: Dictionary, radius: Dictionary) -> String:
	var best := ""
	var best_d := INF
	for name: String in at:
		var d := tap.distance_to(at[name])
		if d <= maxf(float(radius.get(name, 0.0)), FINGER_PX) and d < best_d:
			best = name
			best_d = d
	return best


static func head_low(head_y: float, standing_y: float) -> bool:
	return standing_y - head_y >= LOW_DROP


static func hands_at_face(left: Vector3, right: Vector3, head: Transform3D) -> bool:
	return left.distance_to(head.origin) <= FACE_REACH and right.distance_to(head.origin) <= FACE_REACH


## Stop, drop and roll in VR: rolling is the head going side to side while low: three swings of at least ROLL m (one
## way, back, and that way again), from wherever the head starts.
class Roll:
	extends RefCounted
	const ROLL := 0.12
	const SWINGS := 3

	var turn := NAN   # the furthest the head has gone in the way it is moving
	var dir := 0
	var swings := 0

	## The head's sideways place (m, along the room's right); true once it has swung side to side three times.
	func feed(x: float) -> bool:
		if is_nan(turn):
			turn = x
			return false
		if dir == 0:
			if absf(x - turn) >= ROLL:
				dir = 1 if x > turn else -1
				swings = 1
				turn = x
			return false
		if (x - turn) * dir > 0.0:
			turn = x
		elif (turn - x) * dir >= ROLL:
			dir = -dir
			swings += 1
			turn = x
		return swings >= SWINGS
