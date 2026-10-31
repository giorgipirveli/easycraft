class_name SimpleControls
extends RefCounted
## Simple controls (M3 Task 21a, research A6 and O8: two-hand control is hard for 6-8-year-olds), as pure rules.
## Offered once at first launch (a picture card: SIMPLE or CLASSIC, equal pictures) and a switch in SETTINGS
## (settings.simple_controls). Simple:
## - auto-jump: up a 1-block step (every player has had that since M1b: StepRules) and also over a 1-block gap;
## - the camera turns to follow behind the child while the stick pushes sideways (never right after the child
##   turned it, never walking back towards it);
## - only the buttons that apply now: ATTACK with a weapon in the hand or a monster near, CROUCH with a monster
##   near (or while crouching). Classic keeps everything as it was.

const WALKING := 0.3          # the stick pushed at least this far is walking
const PROBE := StepRules.PROBE_MARGIN
const TURN_RATE := 1.8        # radians a second the camera turns with the stick fully sideways
const LOOK_REST := 1.5        # seconds after the child turned the camera before it follows again
const BACKWARD := 0.3         # the stick pulled back this far: walking towards the camera, no follow
const MONSTER_NEAR := 16.0    # blocks: a monster this near shows ATTACK and CROUCH in Simple


## True when a body walking along `dir` should jump now: a 1-block step ahead (both), or (Simple) a 1-block gap
## at least 2 deep with ground at the same level beyond it and room to hop over. `feet` stand on the ground.
static func auto_jump(simple: bool, feet: Vector3, dir: Vector3, radius: float, clearance: int, solid: Callable) -> bool:
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length() < WALKING:
		return false
	if StepRules.wants_step(feet, flat, radius, clearance, solid):
		return true
	return simple and gap_ahead(feet, flat.normalized(), radius, clearance, solid)


## A 1-block gap right ahead (2 or more deep) with ground on the other side at the feet's level, room to land and
## room over the gap for a hop.
static func gap_ahead(feet: Vector3, dir: Vector3, radius: float, clearance: int, solid: Callable) -> bool:
	var y := floori(feet.y + 0.1)
	var here := Vector3i(floori(feet.x), y, floori(feet.z))
	var a := feet + dir * (radius + PROBE)
	var gap := Vector3i(floori(a.x), y, floori(a.z))
	if gap == here:
		return false
	var b := feet + dir * (radius + PROBE + 1.0)
	var land := Vector3i(floori(b.x), y, floori(b.z))
	if land == gap:
		return false
	if solid.call(gap + Vector3i.DOWN) or solid.call(gap + Vector3i(0, -2, 0)):
		return false                        # no gap, or only a dip to walk through
	if not solid.call(land + Vector3i.DOWN):
		return false                        # nothing to land on
	for dy in range(0, clearance + 1):
		if solid.call(gap + Vector3i(0, dy, 0)) or solid.call(land + Vector3i(0, dy, 0)):
			return false
	return not solid.call(here + Vector3i(0, clearance, 0))


## The camera's yaw after `delta` seconds of following the child walking with `input` (the stick: x right, y
## back), `since_look` seconds after the child last turned the camera.
static func follow_yaw(yaw: float, input: Vector2, delta: float, since_look: float) -> float:
	if since_look < LOOK_REST or input.length() < WALKING or input.y > BACKWARD:
		return yaw
	return yaw - input.x * TURN_RATE * delta


## ATTACK shows in Classic always; in Simple with a weapon in the hand (`armed`), a monster near, or while held.
static func show_attack(simple: bool, armed: bool, monster_near: bool, held: bool) -> bool:
	return not simple or armed or monster_near or held


## CROUCH shows in Classic always; in Simple with a monster near, or while crouching (it stands you up).
static func show_crouch(simple: bool, monster_near: bool, crouching: bool) -> bool:
	return not simple or monster_near or crouching
