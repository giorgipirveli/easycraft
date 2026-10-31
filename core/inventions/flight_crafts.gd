class_name FlightCrafts
extends RefCounted
## Owner #78 (spec §21e): how each invented flying machine moves, true to its science, in pure steps (the Player calls
## them; the numbers are the rulings' constants, docs/devlog/parts/invent-flight.md):
## - the KITE never flies: on a windy hill (high ground) its pull lifts you for a moment, then lets you down gently;
## - the BALLOON rises while its air is heated (UP), sinks slowly as it cools and faster through the vent (DOWN), and
##   drifts with the wind (a little steering on top: real pilots pick a height whose wind blows their way);
## - the PLANE flies fast and must keep moving: let go, it flies on at its slowest; too slow in the air, the wings stop
##   lifting and it sinks, whatever UP says; on the ground it rolls (to a stop when let go), and fast enough along the
##   ground its wings lift it off by themselves (the take-off run);
## - the JET is the plane's step with the highest speed.
## NONE is the classic free flying (the Sandbox's, owner #54 and #75), which the Player moves itself.
## The wind: one of eight compass points from the world's seed and the time, changing every WIND_CHANGE seconds.

enum Craft { NONE, KITE, BALLOON, PLANE, JET }

const NAMES := {Craft.NONE: "free flying", Craft.KITE: "the kite", Craft.BALLOON: "the balloon", Craft.PLANE: "the plane",
	Craft.JET: "the jet"}

const BALLOON_RISE := 2.5     # m/s up while the burner heats the air
const BALLOON_SINK := 0.6     # m/s down as the air cools
const BALLOON_VENT := 2.5     # m/s down with the vent open
const BALLOON_STEER := 2.0    # m/s of steering on top of the wind
const BALLOON_ACCEL := 1.6    # m/s²: a balloon answers slowly
const WIND_SPEED := 2.0       # m/s: a gentle breeze carries the balloon

const PLANE_TOP := 15.0       # m/s (the classic flying is 11)
const JET_TOP := 20.0         # m/s: the fastest (the world must stream in time on a phone: the emulator's check)
const PLANE_ACCEL := 12.0
const JET_ACCEL := 16.0
const CRUISE_SHARE := 0.4     # let go of the stick in the air: it flies on at this share of its top speed
const STALL_SPEED := 5.0      # m/s: slower than this in the air, the wings stop lifting
const STALL_SINK := 3.0       # m/s down while too slow
const CLIMB := 6.0            # m/s up or down with UP or DOWN
const LIFT_OFF_SPEED := 8.0   # m/s along the ground: the wings lift the plane off by themselves

const KITE_HILL := 10.0       # blocks over the sea: high ground, where the wind blows freely
const KITE_RISE := 5.0        # m/s up while the kite pulls
const KITE_LIFT_TIME := 1.2   # s of pull (about 6 blocks)
const KITE_FALL := 2.5        # m/s down at most while the kite holds you

const WIND_CHANGE := 300.0    # s between wind changes
const DOWNWIND_COS := 0.64    # facing within about 50° of the way the wind blows: your back to the wind
const _POINTS: Array[String] = ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]


static func valid(c: int) -> int:
	return c if c >= Craft.NONE and c <= Craft.JET else Craft.NONE


static func of_invention(id: StringName) -> int:
	match id:
		InventionLine.KITE:
			return Craft.KITE
		InventionLine.BALLOON:
			return Craft.BALLOON
		InventionLine.PLANE:
			return Craft.PLANE
		InventionLine.JET:
			return Craft.JET
	return Craft.NONE


static func invention_of(c: int) -> StringName:
	match c:
		Craft.KITE:
			return InventionLine.KITE
		Craft.BALLOON:
			return InventionLine.BALLOON
		Craft.PLANE:
			return InventionLine.PLANE
		Craft.JET:
			return InventionLine.JET
	return &""


## A machine the body flies in (FLY mode): the balloon, the plane, the jet.
static func flies(c: int) -> bool:
	return c == Craft.BALLOON or c == Craft.PLANE or c == Craft.JET


static func top_speed(c: int) -> float:
	match c:
		Craft.PLANE:
			return PLANE_TOP
		Craft.JET:
			return JET_TOP
		Craft.BALLOON:
			return BALLOON_STEER + WIND_SPEED
	return 0.0


## One step of flying machine `c`: `steer` the stick's flat direction (length up to 1), `vertical` UP (1) or DOWN (-1),
## `wind` the wind's flat velocity. Returns the new velocity.
static func step(c: int, v: Vector3, steer: Vector3, vertical: float, wind: Vector3, on_floor: bool, delta: float) -> Vector3:
	if not is_finite(delta) or delta <= 0.0 or not v.is_finite():
		return v if v.is_finite() else Vector3.ZERO
	steer = Vector3(steer.x, 0.0, steer.z).limit_length(1.0)
	vertical = clampf(vertical, -1.0, 1.0) if is_finite(vertical) else 0.0
	match valid(c):
		Craft.BALLOON:
			return _balloon(v, steer, vertical, wind if wind.is_finite() else Vector3.ZERO, delta)
		Craft.PLANE, Craft.JET:
			return _plane(c, v, steer, vertical, on_floor, delta)
	return v


static func _balloon(v: Vector3, steer: Vector3, heat: float, wind: Vector3, delta: float) -> Vector3:
	var up := -BALLOON_SINK
	if heat > 0.1:
		up = BALLOON_RISE
	elif heat < -0.1:
		up = -BALLOON_VENT
	var flat := Vector3(wind.x, 0.0, wind.z) + steer * BALLOON_STEER
	var target := Vector3(flat.x, up, flat.z)
	return v.move_toward(target, BALLOON_ACCEL * delta)


static func _plane(c: int, v: Vector3, steer: Vector3, vertical: float, on_floor: bool, delta: float) -> Vector3:
	var top := top_speed(c)
	var accel := JET_ACCEL if c == Craft.JET else PLANE_ACCEL
	var flat := Vector3(v.x, 0.0, v.z)
	var target_flat := Vector3.ZERO
	if steer.length() > 0.05:
		target_flat = steer * top
	elif not on_floor and flat.length() > 0.1:
		target_flat = flat.normalized() * top * CRUISE_SHARE   # a plane can't stand still in the air
	flat = flat.move_toward(target_flat, accel * delta)
	var up := vertical * CLIMB
	if on_floor and vertical == 0.0 and flat.length() >= LIFT_OFF_SPEED:
		up = CLIMB * 0.5   # the take-off run: fast enough, the wings lift it off the ground
	if not on_floor and flat.length() < STALL_SPEED:
		up = minf(up, -STALL_SINK)   # too slow: the wings stop lifting
	var vy := move_toward(v.y, up, accel * delta)
	return Vector3(flat.x, vy, flat.z)


# --- The kite ---

## High ground, where the wind blows freely: a kite lifts you there.
static func windy_hill(feet_y: float, sea_level: float) -> bool:
	return is_finite(feet_y) and feet_y >= sea_level + KITE_HILL


## The body's upward speed while a kite holds it: the pull while `lift_left` lasts, then a gentle way down.
static func kite_velocity(vy: float, lift_left: float) -> float:
	if lift_left > 0.0:
		return KITE_RISE
	return maxf(vy, -KITE_FALL)


# --- The wind ---

## Where the wind blows (a flat unit vector), one of eight compass points, from the seed and the time slot
## (floor(seconds / WIND_CHANGE)).
static func wind_dir(world_seed: int, slot: int) -> Vector3:
	var h := absi(hash([world_seed, slot, "wind"])) % 8
	var a := h * TAU / 8.0   # 0 = towards the north (-z), clockwise: east is +x
	return Vector3(sin(a), 0.0, -cos(a)).normalized()


static func wind_slot(unix_seconds: float) -> int:
	return int(floor(unix_seconds / WIND_CHANGE)) if is_finite(unix_seconds) else 0


## "The wind blows from the west." (it comes from the side opposite to where it blows).
static func wind_words(towards: Vector3) -> String:
	var from := -Vector2(towards.x, towards.z)
	if from.length() < 0.001:
		return "There is no wind."
	var a := fposmod(atan2(from.x, -from.y), TAU)
	return "The wind blows from the %s." % _POINTS[int(roundi(a / (TAU / 8.0))) % 8]


## Facing the way the wind blows (your back to the wind): a kite flies out in front of you.
static func downwind(facing: Vector3, wind: Vector3) -> bool:
	var f := Vector2(facing.x, facing.z)
	var w := Vector2(wind.x, wind.z)
	if f.length() < 0.001 or w.length() < 0.001:
		return false
	return f.normalized().dot(w.normalized()) >= DOWNWIND_COS
