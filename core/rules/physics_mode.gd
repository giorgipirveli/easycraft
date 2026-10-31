class_name PhysicsMode
extends RefCounted
## The physics switch: NORMAL (gravity + collision), FLY (no gravity), GHOST (no gravity, no collision).

enum Mode { NORMAL, FLY, GHOST }


## The next mode of the switch; without ghost_allowed (Survivor, M2 §12.1) GHOST is skipped.
static func next(mode: int, ghost_allowed: bool) -> int:
	var n := (mode + 1) % Mode.size()
	if n == Mode.GHOST and not ghost_allowed:
		n = Mode.NORMAL
	return n


static func has_gravity(mode: int) -> bool:
	return mode == Mode.NORMAL


static func has_collision(mode: int) -> bool:
	return mode != Mode.GHOST


static func display_name(mode: int) -> String:
	match mode:
		Mode.FLY:
			return "Fly"
		Mode.GHOST:
			return "Ghost"
		_:
			return "Normal"
