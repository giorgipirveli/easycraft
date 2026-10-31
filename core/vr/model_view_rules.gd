class_name ModelViewRules
extends RefCounted
## Owner #110, VR round 4 idea 6 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md, the research §5.3 "The Giant's Table",
## R6): MODEL VIEW as pure rules. The Sandbox only (R6); the child stands as a giant SCALE times their size (Size Magic's
## world scale) in their own world: the land loaded round them (64 blocks) is a model about 5 m across at their feet. The
## little figure of them (their own avatar) is picked up and dropped: it lands on the first block's top under it, and the
## child may go there when they could stand there (TeleportRules' own reasons: room for the body, never a hiding spot,
## never where a game says no), anywhere on the model's loaded land (RANGE), behind the black. Two hands twist the world
## round in TWIST_STEP steps (never smoothly: Meta's optic-flow rule).

const SCALE := 25.0
## The model is the land within RANGE blocks round the child (the head's far plane cuts it there: far_plane), about
## 3 m across in the child's metres; the figure lands only on it. A round model's edge, and the draws of the whole loaded
## land seen from above kept down (the VR budget: docs/devlog/parts/vr-r4-hands.md).
const RANGE := 40.0
const TWIST_STEP := 45.0
## A dropped figure looks this far down for a top to land on (blocks).
const FALL := 128


static func allowed(mode: StringName) -> bool:
	return mode == ModeRules.SANDBOX


## Where a figure let go at `from` lands: the first solid block's top straight under it (feet), INF for none (from inside
## the ground, or nothing under it within FALL).
static func landing(from: Vector3, block_at: Callable) -> Vector3:
	var c := Vector3i(from.floor())
	if BlockIds.is_solid(int(block_at.call(c))):
		return Vector3.INF
	for i in FALL:
		var below := c - Vector3i(0, i + 1, 0)
		if BlockIds.is_solid(int(block_at.call(below))):
			return Vector3(from.x, float(below.y + 1), from.z)
	return Vector3.INF


## Whether the child (feet at `feet`) may go to `at`: "" or TeleportRules' reason (NOWHERE, FAR, SPOT, STAND, ROOM,
## AREA). `radius`, `clearance`: the body's; `block_at(cell) -> id`; `refuse(at) -> bool`: a game's no.
static func check(feet: Vector3, at: Vector3, radius: float, clearance: int, block_at: Callable,
		refuse: Callable) -> String:
	if not at.is_finite():
		return TeleportRules.NOWHERE
	if Vector2(at.x - feet.x, at.z - feet.z).length() > RANGE:
		return TeleportRules.FAR
	var cell := Vector3i(at.floor())
	for k in range(-1, clearance):
		if StealthRules.is_hiding_block(int(block_at.call(cell + Vector3i(0, k, 0)))):
			return TeleportRules.SPOT
	if not BlockIds.is_solid(int(block_at.call(cell - Vector3i(0, 1, 0)))):
		return TeleportRules.STAND
	var solid := func(c: Vector3i) -> bool: return BlockIds.is_solid(int(block_at.call(c)))
	if StepRules.first_free_y(at, radius, clearance, TeleportRules.MAX_Y, solid) != cell.y:
		return TeleportRules.ROOM
	if refuse.is_valid() and bool(refuse.call(at)):
		return TeleportRules.AREA
	return ""


## The head's far plane for a giant whose eyes are `eye_height` (world m) over the ground: it reaches the ground RANGE
## blocks away round the feet (never nearer than the eyes' own height and a little).
static func far_plane(eye_height: float) -> float:
	var h := maxf(eye_height, 1.0)
	return sqrt(h * h + RANGE * RANGE)


## The world's turn for two hands whose line turned `angle` (radians): whole TWIST_STEP steps past half a step.
static func twist_steps(angle: float) -> int:
	var deg := rad_to_deg(angle)
	return int(roundi(deg / TWIST_STEP)) if absf(deg) >= TWIST_STEP * 0.5 + 0.0001 else 0
