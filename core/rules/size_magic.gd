class_name SizeMagic
extends RefCounted
## Size Magic: Tiny (1/4, explore builds like a bug, fit 1-block tunnels), Normal and Giant (3x).
## Speed and jump scale with size so movement still feels right.

enum Mode { NORMAL, TINY, GIANT }

const PLAYER_HEIGHT := 1.8
const _SCALE := {Mode.NORMAL: 1.0, Mode.TINY: 0.25, Mode.GIANT: 3.0}
const _SPEED := {Mode.NORMAL: 1.0, Mode.TINY: 0.6, Mode.GIANT: 1.7}
const _JUMP := {Mode.NORMAL: 1.0, Mode.TINY: 0.55, Mode.GIANT: 1.7}
const _LABEL := {Mode.NORMAL: "SIZE", Mode.TINY: "TINY", Mode.GIANT: "GIANT"}


static func scale(mode: int) -> float:
	return _SCALE.get(mode, 1.0)


static func next(mode: int) -> int:
	return (mode + 1) % Mode.size()


## Free blocks needed above the feet to stand.
static func clearance_blocks(mode: int) -> int:
	return ceili(PLAYER_HEIGHT * scale(mode))


static func walk_speed_factor(mode: int) -> float:
	return _SPEED.get(mode, 1.0)


static func jump_factor(mode: int) -> float:
	return _JUMP.get(mode, 1.0)


static func label(mode: int) -> String:
	return _LABEL.get(mode, "SIZE")
