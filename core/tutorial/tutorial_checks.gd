class_name TutorialChecks
extends RefCounted
## Each tutorial step's check (M3 Task 15, spec §14.9), pure, from what the child really does: the TutorialDirector
## feeds them the player's place, camera, floor contact, hiding and the world's cells ten times a second.

## Move and look: this far walked and this much turned (either way).
const WALK := 3.0
const TURN := PI * 0.5
## A jump in place between two looks further than this is a respawn or a teleport, not a walk.
const TELEPORT := 5.0
## Hidden this long (while the practice slime is near and can't see the child): it lost them.
const HIDE_HOLD := 1.5
## The practice slime counts as near within this many blocks.
const SLIME_NEAR := 16.0


## Walked and looked around (the camera's yaw, radians).
class LookWatch:
	extends RefCounted
	var walked := 0.0
	var turned := 0.0
	var _pos := Vector3.INF
	var _yaw := NAN

	func feed(pos: Vector3, yaw: float) -> void:
		if _pos.is_finite():
			var step := Vector2(pos.x - _pos.x, pos.z - _pos.z).length()
			if step <= TELEPORT:
				walked += step
		if not is_nan(_yaw):
			turned += absf(wrapf(yaw - _yaw, -PI, PI))
		_pos = pos
		_yaw = yaw

	func done() -> bool:
		return walked >= WALK and turned >= TURN


## The jump: standing on this side of the hole (its lip too: a body standing at the edge has its middle over the
## hole's first column), then the next time on the ground past it. Landing anywhere else (in the hole: `fell`, or
## beside the playground) starts over.
class JumpWatch:
	extends RefCounted
	var armed := false
	var fell := false

	## `zone`: TutorialCourse.zone of the feet; true once the jump is done.
	func feed(zone: int, on_floor: bool) -> bool:
		if not on_floor:
			return false
		if zone == TutorialCourse.NEAR or zone == TutorialCourse.GAP:
			armed = true
		elif zone == TutorialCourse.FAR:
			return armed
		elif zone == TutorialCourse.PIT:
			fell = true
			armed = false
		else:
			armed = false
		return false


## Hiding: crouched in a bush (Player.is_hidden) while the practice slime is near and can't see them, HIDE_HOLD.
class HideWatch:
	extends RefCounted
	var held := 0.0

	func feed(delta: float, hidden: bool, slime_near: bool, slime_sees: bool) -> bool:
		if hidden and slime_near and not slime_sees:
			held += delta
		else:
			held = 0.0
		return held >= HIDE_HOLD


## Three blocks across the bridge's hole, in one row, top layer (anything you can stand on).
static func bridge_done(site: Dictionary, block_at: Callable) -> bool:
	for s in range(-TutorialCourse.S_HALF, TutorialCourse.S_HALF + 1):
		var row := true
		for a in range(TutorialCourse.BRIDGE_FROM, TutorialCourse.BRIDGE_TO + 1):
			if not BlockIds.is_solid(int(block_at.call(TutorialCourse.cell(site, a, s, -1)))):
				row = false
				break
		if row:
			return true
	return false


## A way through the wall: both blocks of one column gone.
static func wall_open(site: Dictionary, block_at: Callable) -> bool:
	for s in range(-TutorialCourse.S_HALF, TutorialCourse.S_HALF + 1):
		var open := true
		for dy in TutorialCourse.WALL_HIGH:
			if BlockIds.is_solid(int(block_at.call(TutorialCourse.cell(site, TutorialCourse.WALL_A, s, dy)))):
				open = false
				break
		if open:
			return true
	return false


## The host's answer to a craft (Session.craft_done): sticks were made.
static func crafted_stick(ok: bool, id: int) -> bool:
	return ok and id == ItemIds.STICK


## At Tilly's shop: within the tap's reach of her (ShopGuide.there).
static func at_tilly(eye: Vector3, tilly_pos: Vector3) -> bool:
	return tilly_pos.is_finite() and eye.is_finite() and ShopGuide.there(eye, tilly_pos)
