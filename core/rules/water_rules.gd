class_name WaterRules
extends RefCounted
## In water the player floats up slowly on their own; holding jump swims up faster.
## (M1b.) Since M2 Task 14 the player swims with SwimRules, which shares SWIM_UP_SPEED.

const FLOAT_SPEED := 0.8
const SWIM_UP_SPEED := 3.5
const DRIFT_ACCEL := 4.0


static func vertical_velocity(current: float, jump_held: bool, delta: float) -> float:
	if jump_held:
		return SWIM_UP_SPEED
	return move_toward(current, FLOAT_SPEED, DRIFT_ACCEL * delta)
