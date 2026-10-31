class_name SwimRules
extends RefCounted
## Real water (M2 Task 14, owner feedback #17): in any water deep enough to reach the chest the
## player swims. It floats with the head above the surface, swims where it looks (look down and push
## forward to dive), JUMP swims up and DOWN dives, it never stands on the bottom, and pushing against
## a 1-block bank climbs out. Shallower water is waded through. Heights are for a body of size 1
## (SizeMagic scales them); block_at: func(cell: Vector3i) -> int.
## Owner feedback #30: pushing into a bank never dives (the swimmer floats up to it and climbs, whatever
## the view's tilt), UP alone next to a bank climbs it, and UP with a push climbs a wall 2 blocks high.

enum State { DRY, WADING, SWIMMING, DIVING }

const CHEST := 1.0            # the body swims once the water reaches this far above the feet
const EYES := 1.55            # CameraRig.HEAD_HEIGHT: under water from here up is diving
const FLOAT_DEPTH := 1.25     # floating still: the surface is this far above the feet (head out)
const LIFT_DEPTH := 1.1       # JUMP held at the surface lifts this high, the chest still in the water
const SPRING := 4.0           # 1/s: how fast the body settles at the float line
const FLOAT_UP_SPEED := 2.0   # m/s floating up from the deep
const SINK_SPEED := 1.5       # m/s sinking back to the float line (after a lift)
const DIVE_SPEED := 3.0       # DOWN
const VERTICAL_ACCEL := 10.0
const DRAG := 5.0             # 1/s: the water brakes a fast body (a jump in) more
const SWIM_SPEED := 3.6       # m/s (walking is 6)
const SWIM_ACCEL := 10.0      # a glide, not a walk
const LOOK_DEAD_DOWN := 0.5   # look pitch (rad) the camera may have without diving (third person rests at -0.35)
const LOOK_DEAD_UP := 0.3
const MAX_SWIM_PITCH := 1.25  # rad: the steepest a look dives or rises
const SURFACE_SCAN := 8       # blocks searched upwards for the surface
const AT_SURFACE := 0.6       # a swimmer this far under its float line still counts as at the surface
const CLIMB_REACH := 0.35     # how far past the body's edge a bank is felt
const CLIMB_SPEED := 4.0      # m/s pulling up onto a bank
const CLIMB_PUSH := 2.0       # m/s towards the bank while climbing
const CLIMB_OVER := 0.4       # climbs this far above the bank's top, then steps onto it
const CLIMB_TIMEOUT := 1.5
# Owner feedback #30 ("i cannt get from water without filying").
const CLIMB_UP_ROWS := 2      # with UP held, a wall this many blocks above the water is climbed
const CLIMB_REACH_UP := 0.6   # UP alone feels a bank this far past the body's edge
const CLIMB_STEP := 3.5       # m/s onto the bank once above it (a climb started by UP has no push)
const BANK_DEPTH := 3.0       # feet this far under the surface still feel a bank: they float up to it
const SIDES: Array[Vector3] = [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]
const SPLASH_FULL_SPEED := 16.0   # m/s into the water that makes the biggest splash (a 10 m fall)
const SPLASH_MIN := 0.08          # weaker entries make no splash (wading in)
const TREAD_TILT := 0.15      # rad: treading water leans a little forward
const TILT_FULL_SPEED := 1.5  # m/s at which the body follows its swim direction fully


## DRY, WADING (feet in the water), SWIMMING (the chest in it) or DIVING (the eyes under it). The feet
## are looked at first: on dry land (most frames) that is the only block lookup.
static func water_state(feet: Vector3, size: float, block_at: Callable) -> int:
	if not _water_at(feet, 0.05 * size, block_at):
		return State.DRY
	if _water_at(feet, EYES * size, block_at):
		return State.DIVING
	if _water_at(feet, CHEST * size, block_at):
		return State.SWIMMING
	return State.WADING


static func _water_at(feet: Vector3, height: float, block_at: Callable) -> bool:
	return block_at.call(Vector3i((feet + Vector3(0.0, height, 0.0)).floor())) == BlockIds.WATER


## The water's surface above the feet: the row of the first cell above them that is not water (a cave
## roof counts). Deep down the scan stops SURFACE_SCAN blocks up.
static func surface_y(feet: Vector3, block_at: Callable) -> float:
	var cell := Vector3i((feet + Vector3(0.0, 0.01, 0.0)).floor())
	for i in SURFACE_SCAN:
		if block_at.call(cell) != BlockIds.WATER:
			break
		cell.y += 1
	return float(cell.y)


## The look pitch as the swim's climb angle: level inside the dead zone, then steeper up to
## MAX_SWIM_PITCH at the camera's limits.
static func swim_pitch(look_pitch: float) -> float:
	if look_pitch < -LOOK_DEAD_DOWN:
		return -clampf((-look_pitch - LOOK_DEAD_DOWN) / (-CameraRig.PITCH_MIN - LOOK_DEAD_DOWN), 0.0, 1.0) * MAX_SWIM_PITCH
	if look_pitch > LOOK_DEAD_UP:
		return clampf((look_pitch - LOOK_DEAD_UP) / (CameraRig.PITCH_MAX - LOOK_DEAD_UP), 0.0, 1.0) * MAX_SWIM_PITCH
	return 0.0


## Where the swimmer wants to go: input (x right, y back, as Input.get_vector) turned by the camera
## yaw; the forward part follows the look up or down, sideways stays level.
static func swim_velocity(input: Vector2, yaw: float, look_pitch: float, speed: float) -> Vector3:
	var turn := Basis(Vector3.UP, yaw)
	var forward := -input.y
	var p := swim_pitch(look_pitch)
	var v := turn * Vector3(input.x, 0.0, 0.0) + turn * Vector3.FORWARD * (forward * cos(p)) + Vector3.UP * (forward * sin(p))
	return v * speed


## The vertical speed a swimmer heads for. depth: the surface above the feet; size: SizeMagic scale;
## k: its speed factor; look_vy: the climb from swim_velocity. DOWN dives; JUMP swims up but no higher
## than LIFT_DEPTH; a look up stops at the surface; otherwise the body floats to its float line.
static func vertical_target(depth: float, size: float, k: float, up: bool, down: bool, look_vy: float) -> float:
	if down:
		return -DIVE_SPEED * k
	var float_v := (depth - FLOAT_DEPTH * size) * SPRING
	var buoyancy := clampf(float_v, -SINK_SPEED * k, FLOAT_UP_SPEED * k)
	if up:
		return minf(WaterRules.SWIM_UP_SPEED * k, (depth - LIFT_DEPTH * size) * SPRING)
	if look_vy < 0.0:
		return look_vy
	if look_vy > 0.0:
		return maxf(minf(look_vy, float_v), buoyancy)
	return buoyancy


## The water turns the vertical speed towards `target`; fast bodies (a jump in) are braked harder.
static func vertical_velocity(current: float, target: float, delta: float) -> float:
	return move_toward(current, target, (VERTICAL_ACCEL + DRAG * absf(current)) * delta)


## The feet height of the bank a swimmer at the surface pushes against (walking along dir), or NAN.
## A bank is climbed when its top is at most 1 block above the water (a shelf under the surface or
## a beach level with it count too), with room for the whole body on top and above the swimmer.
## Owner feedback #30: with UP held (up) a wall up to CLIMB_UP_ROWS blocks above the water is climbed
## too. max_depth: how far under the surface the feet may be (a climb starts near the surface; the
## swimmer feels a bank from BANK_DEPTH and floats up to it instead of diving).
static func climb_target(feet: Vector3, dir: Vector3, radius: float, clearance: int, surface: float,
		size: float, solid: Callable, up: bool = false, max_depth: float = FLOAT_DEPTH + AT_SURFACE) -> float:
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length() < 0.3 or surface - feet.y > max_depth * size:
		return NAN
	var ahead := feet + flat.normalized() * (radius + CLIMB_REACH * size)
	var col := Vector2i(floori(ahead.x), floori(ahead.z))
	for y in range(floori(surface) + (CLIMB_UP_ROWS - 1 if up else 0), floori(feet.y) - 1, -1):
		if not solid.call(Vector3i(col.x, y, col.y)):
			continue
		var top := float(y + 1)
		if top <= feet.y + 0.05:
			return NAN
		for dy in clearance:
			if solid.call(Vector3i(col.x, y + 1 + dy, col.y)):
				return NAN
		for row in range(floori(feet.y), y + 1 + clearance):
			if solid.call(Vector3i(floori(feet.x), row, floori(feet.z))):
				return NAN
		return top
	return NAN


## Owner feedback #30: where a swimmer climbs out: {"top": the bank's top (feet height), "dir": the flat
## way to it}, or {} when there is none. push: the stick's direction; up / down: UP or DOWN held; look:
## where the camera faces. A push climbs the bank it meets; UP alone climbs the bank the view faces,
## else one right beside the body (a little further away counts: CLIMB_REACH_UP). DOWN never climbs.
static func climb_out(feet: Vector3, push: Vector3, up: bool, down: bool, look: Vector3, radius: float,
		clearance: int, surface: float, size: float, solid: Callable, max_depth: float = FLOAT_DEPTH + AT_SURFACE) -> Dictionary:
	if down:
		return {}
	var flat := Vector3(push.x, 0.0, push.z)
	var dirs: Array[Vector3] = []
	var reach := radius
	if flat.length() >= 0.3:
		dirs.append(flat.normalized())
	elif up:
		var view := Vector3(look.x, 0.0, look.z)
		if view.length() > 0.001:
			dirs.append(view.normalized())
		dirs.append_array(SIDES)
		reach = radius + (CLIMB_REACH_UP - CLIMB_REACH) * size
	for d in dirs:
		var top := climb_target(feet, d, reach, clearance, surface, size, solid, up, max_depth)
		if not is_nan(top):
			return {"top": top, "dir": d}
	return {}


## 0..1: how big a splash a body entering the water at `velocity` makes (falling in counts most).
static func splash_strength(velocity: Vector3) -> float:
	var speed := maxf(-velocity.y, 0.0) + 0.25 * Vector2(velocity.x, velocity.z).length()
	return clampf(speed / SPLASH_FULL_SPEED, 0.0, 1.0)


## True when the body shows the swim pose: on foot (not flying), swimming or diving, awake.
static func swim_pose(physics_mode: int, state: int, sleeping: bool) -> bool:
	return physics_mode == PhysicsMode.Mode.NORMAL and state >= State.SWIMMING and not sleeping


## How far the swimming body tips forward from upright (rad): 0 treads water upright, PI/2 lies flat
## swimming along, PI dives head first. Slow bodies lean towards treading water.
static func body_tilt(horizontal_speed: float, vertical_speed: float) -> float:
	var w := clampf(Vector2(horizontal_speed, vertical_speed).length() / TILT_FULL_SPEED, 0.0, 1.0)
	return lerpf(TREAD_TILT, atan2(horizontal_speed, vertical_speed), w)
