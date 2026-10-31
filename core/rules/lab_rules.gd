class_name LabRules
extends RefCounted
## The Physics Lab (M3 Task 6, spec §14.3): the LAB button's modes (Sandbox only), what each game mode
## allows, and each mode's movement rules.
## - MOON: gravity × 0.35, so the same jump goes almost 3 times as high and hangs as long.
## - ZERO_G: no gravity. The body drifts on with slight damping; the stick, JUMP and DOWN thrust
##   gently, and moving into a wall or block kicks off it (the fast way to get around).
## - SLOW: the player's own body runs at 0.4 time (movement, gravity, jumps, pads, animation); the
##   world, animals, monsters and other players keep their own time (LAN stays fair).
## - FLY and GHOST are the physics switch's modes (PhysicsMode); NORMAL is plain walking.
## Each lab mode moves the body like one PhysicsMode (physics_mode), so everything that asks "is this
## player walking?" keeps working.

enum Mode { NORMAL, MOON, ZERO_G, FLY, GHOST, SLOW }

## The LAB button's order.
const CYCLE: Array[int] = [Mode.NORMAL, Mode.MOON, Mode.ZERO_G, Mode.FLY, Mode.GHOST, Mode.SLOW]

const MOON_GRAVITY := 0.35
const SLOW_TIME := 0.4

const ZERO_G_DAMPING := 0.3      # per second: a drift loses about a quarter of its speed each second
const THRUST_ACCEL := 4.0        # m/s² from the stick, JUMP (up) or DOWN
const THRUST_SPEED := 3.0        # thrust alone never goes faster than this (walking is 6)
const PUSH_OFF_SPEED := 7.0      # kicking off a wall, floor or ceiling
const PUSH_DOT := 0.5            # how straight into the surface a push must go (cos 60°)
const PUSH_COOLDOWN := 0.3       # one kick per touch
const ZERO_G_MAX_SPEED := 18.0   # a jump pad's launch still fits

const _LABELS := {
	Mode.NORMAL: "WALK", Mode.MOON: "MOON", Mode.ZERO_G: "ZERO-G",
	Mode.FLY: "FLY", Mode.GHOST: "GHOST", Mode.SLOW: "SLOW",
}
const _TOASTS := {
	Mode.NORMAL: "Normal walking",
	Mode.MOON: "Moon gravity: big floaty jumps!",
	Mode.ZERO_G: "Zero-G: float, and push off walls!",
	Mode.FLY: "Fly: up and down buttons",
	Mode.GHOST: "Ghost: fly through anything",
	Mode.SLOW: "Slow motion!",
}


static func valid(mode: int) -> int:
	return mode if mode >= 0 and mode < Mode.size() else Mode.NORMAL


## Survivor (M2 §12.1) keeps Normal and paid Fly; the Sandbox has the whole lab.
static func allowed(mode: int, game_mode: StringName) -> bool:
	match valid(mode):
		Mode.NORMAL, Mode.FLY:
			return true
		Mode.GHOST:
			return ModeRules.allows(game_mode, ModeRules.GHOST)
		_:
			return ModeRules.allows(game_mode, ModeRules.PHYSICS_LAB)


## The LAB button's next mode, skipping what `game_mode` does not allow.
static func next(mode: int, game_mode: StringName) -> int:
	var i := CYCLE.find(valid(mode))
	for step in CYCLE.size():
		var m := CYCLE[(i + 1 + step) % CYCLE.size()]
		if allowed(m, game_mode):
			return m
	return Mode.NORMAL


## Moon, Zero-G and Slow motion: the modes only the lab has.
static func is_lab_only(mode: int) -> bool:
	return mode in [Mode.MOON, Mode.ZERO_G, Mode.SLOW]


## How the body moves in `mode` (PhysicsMode: walking, flying, or a ghost).
static func physics_mode(mode: int) -> int:
	match valid(mode):
		Mode.ZERO_G, Mode.FLY:
			return PhysicsMode.Mode.FLY
		Mode.GHOST:
			return PhysicsMode.Mode.GHOST
		_:
			return PhysicsMode.Mode.NORMAL


## The plain lab mode for a physics switch mode (the WALK/FLY/GHOST button, /walk, /fly, /ghost).
static func from_physics(physics: int) -> int:
	match physics:
		PhysicsMode.Mode.FLY:
			return Mode.FLY
		PhysicsMode.Mode.GHOST:
			return Mode.GHOST
		_:
			return Mode.NORMAL


static func label(mode: int) -> String:
	return _LABELS[valid(mode)]


static func toast(mode: int) -> String:
	return _TOASTS[valid(mode)]


## Owner #55 (spec §21): the gravity of the world this game plays in (UniverseRegistry.gravity: the Moon 0.35), set by
## the world scene and put back to 1 when it goes. Every lab mode's gravity is × this.
static var world_gravity := 1.0


## Gravity × this. Slow motion slows time, not gravity (time_factor). The world's own gravity multiplies it.
static func gravity_factor(mode: int) -> float:
	match valid(mode):
		Mode.MOON:
			return MOON_GRAVITY * world_gravity
		Mode.NORMAL, Mode.SLOW:
			return world_gravity
		_:
			return 0.0


## The body's own time runs at this rate.
static func time_factor(mode: int) -> float:
	return SLOW_TIME if valid(mode) == Mode.SLOW else 1.0


## A frame of the body's own time.
static func body_delta(mode: int, delta: float) -> float:
	return delta * time_factor(mode)


## How high a jump with `jump_velocity` goes (INF without gravity).
static func jump_height(mode: int, jump_velocity: float, gravity: float) -> float:
	var g := gravity * gravity_factor(mode)
	return INF if g <= 0.0 else jump_velocity * jump_velocity / (2.0 * g)


## Cosmos (Europa, spec §21b.2; friendly, §3c): the push of the hop onto a 1-block ledge (Player's auto-step) in gravity
## × `gravity_factor`. Down to the Moon's gravity it is `velocity` as ever; lower (Europa's 0.13: a 9-block hop that
## floated 5 seconds) it is gentler, so the hop is as high as on the Moon. Zero gravity keeps it (no hop there).
static func step_velocity(velocity: float, gravity_factor: float) -> float:
	if gravity_factor <= 0.0 or gravity_factor >= MOON_GRAVITY:
		return velocity
	return velocity * sqrt(gravity_factor / MOON_GRAVITY)


## How long that jump stays in the air, in real seconds (INF without gravity).
static func air_time(mode: int, jump_velocity: float, gravity: float) -> float:
	var g := gravity * gravity_factor(mode)
	return INF if g <= 0.0 else 2.0 * jump_velocity / g / time_factor(mode)


## Where the player wants to go in zero-G: the stick (camera-relative, flat) plus up (JUMP) or down
## (DOWN), never more than full thrust.
static func wish(stick: Vector3, vertical: float) -> Vector3:
	return (stick + Vector3.UP * vertical).limit_length(1.0)


## One zero-G step: the drift fades a little, and thrust (wish, up to length 1) pushes gently towards
## THRUST_SPEED × k along the wish. Thrust never brakes a faster drift. k: the body's size factor.
static func zero_g_velocity(v: Vector3, wish_dir: Vector3, delta: float, k: float = 1.0) -> Vector3:
	var out := v * exp(-ZERO_G_DAMPING * delta)
	var w := wish_dir.limit_length(1.0)
	if w.length() > 0.001:
		var d := w.normalized()
		var room := THRUST_SPEED * k * w.length() - out.dot(d)
		if room > 0.0:
			out += d * minf(room, THRUST_ACCEL * k * delta)
	return out.limit_length(ZERO_G_MAX_SPEED)


## Moving into a surface (its normal points out of it) kicks off it.
static func wants_push_off(normal: Vector3, wish_dir: Vector3) -> bool:
	return wish_dir.length() > 0.3 and wish_dir.normalized().dot(normal) < -PUSH_DOT


## The kick: straight away from the surface, keeping the slide along it.
static func push_off_velocity(v: Vector3, normal: Vector3, k: float = 1.0) -> Vector3:
	var n := normal.normalized()
	return v - n * v.dot(n) + n * PUSH_OFF_SPEED * k
