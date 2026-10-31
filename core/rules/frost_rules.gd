class_name FrostRules
extends RefCounted
## Frostpeak's slippery ground as a pure rule (M3 Task 3, spec §14.1 "ice lakes (slippery)"): the grip of
## the block under a walker's feet scales how fast it speeds up and slows down, for players, animals and
## monsters alike. On ice a body slides a few blocks after it stops walking; on blue ice further; everywhere
## else nothing changes. The Frost Giant's icy ground (IcyGround) counts too: never a changed block.

## Grip by block: how much of its usual speeding up and slowing down a walker keeps there.
const GRIP := {BlockIds.ICE: 0.15, BlockIds.BLUE_ICE: 0.08}


static func grip(block_id: int) -> float:
	return float(GRIP.get(block_id, 1.0))


## The cell a body with its feet at `feet` stands on.
static func floor_cell(feet: Vector3) -> Vector3i:
	return Vector3i(floori(feet.x), floori(feet.y - 0.1), floori(feet.z))


## The grip under feet at `feet`: the block's (block_at(cell) -> id), or the Frost Giant's icy ground when
## that is more slippery. `now`: seconds (Time.get_ticks_msec() / 1000 when left out).
static func grip_at(feet: Vector3, block_at: Callable, now: float = -1.0) -> float:
	var g := grip(block_at.call(floor_cell(feet)))
	var t := now if now >= 0.0 else Time.get_ticks_msec() / 1000.0
	return minf(g, IcyGround.grip_at(feet, t))


## How far a body going `speed` slides before it stops, slowing down at `accel` × `grip_share`.
static func stop_distance(speed: float, accel: float, grip_share: float) -> float:
	return speed * speed / (2.0 * accel * maxf(grip_share, 0.001))
