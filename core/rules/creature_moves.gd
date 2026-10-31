class_name CreatureMoves
extends RefCounted
## The moves every monster and boss shares (M5 Task 2, spec §15.2), as plain numbers each body turns into its own
## pose: a jumper's crouch before it pounces (the slime's and the gummy bear's wind-up), the lean back when a hit
## lands, a boss's breath while it stands, and its cheer when it wins a fight. Poses only: no materials, nothing
## allocated. Models face -Z, so a positive x rotation leans the top back.

## A slime or gummy bear crouches this long before it pounces at a child it sees within POUNCE_RANGE (flat).
const POUNCE_WINDUP := 0.3
const POUNCE_RANGE := 3.0
const POUNCE_BOOST := 1.25        # a pounce flies this much faster than a hop
## A hit: the body leans back this far (radians) and eases home over RECOIL_TIME.
const RECOIL_TIME := 0.3
const MONSTER_RECOIL := 0.35
const BOSS_RECOIL := 0.12
## A boss breathes once every BREATH_PERIOD seconds while it stands.
const BREATH_PERIOD := 2.6
const BREATH_LIFT := 0.03         # its body rises this much of a block (on the model's own scale)
const BREATH_ARMS := 0.07         # radians its arms sway
const BREATH_LEAN := 0.02
## A boss that won a fight cheers this long before it sinks or flies away.
const WIN_TIME := 2.0
const CHEER_PUMPS := 3            # arm pumps (and hops) in a cheer
const CHEER_ARMS := 2.5           # radians: arms over the head
const CHEER_HOP := 0.25           # blocks


## A jumper's body scale `w` of the way through its crouch (0 before, 1 at the bottom and after).
static func crouch(w: float) -> Vector3:
	var k := clampf(w, 0.0, 1.0)
	k = 1.0 - (1.0 - k) * (1.0 - k)   # quick down, then held
	var down := 1.0 - 0.3 * k
	var wide := 1.0 / sqrt(down)
	return Vector3(wide, down, wide)


## How far (radians, + = back) a body leans `k` of the way through a recoil's time left (1 at the hit, 0 done),
## at most `angle`: back at once, then home with a little ease.
static func recoil(k: float, angle: float) -> float:
	var left := clampf(k, 0.0, 1.0)
	if left >= 0.8:
		return angle * (0.6 + 0.4 * (1.0 - left) / 0.2)   # the first moments: all the way back
	return angle * sin(left / 0.8 * PI * 0.5)


## A boss's breath `t` seconds into standing: x = lift (blocks), y = arms (radians), z = lean (radians).
static func breath(t: float) -> Vector3:
	var a := TAU * fposmod(t, BREATH_PERIOD) / BREATH_PERIOD
	return Vector3(BREATH_LIFT * (0.5 - 0.5 * cos(a)), BREATH_ARMS * sin(a), BREATH_LEAN * (0.5 - 0.5 * cos(a)))


## Whether a boss that won `t` seconds ago still cheers.
static func cheering(t: float) -> bool:
	return t >= 0.0 and t < WIN_TIME


## A boss's cheer `t` seconds after it won: x = hop (blocks), y = arms (radians, over the head and pumping), z = lean
## (radians, chest out); from rest and back to rest.
static func cheer(t: float) -> Vector3:
	if not cheering(t):
		return Vector3.ZERO
	var u := t / WIN_TIME
	var envelope := smoothstep(0.0, 0.12, u) * (1.0 - smoothstep(0.85, 1.0, u))
	var beat := u * CHEER_PUMPS
	var pump := 0.5 - 0.5 * cos(TAU * beat)                  # 0 at each beat's start, 1 halfway
	var hop := absf(sin(PI * beat)) * CHEER_HOP
	return Vector3(hop, CHEER_ARMS * (0.75 + 0.25 * pump), 0.12) * envelope
