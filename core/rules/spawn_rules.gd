class_name SpawnRules
extends RefCounted
## Where a player may stand: spawning, leaving Ghost mode inside blocks, and falling out of the world.

const FALL_LIMIT_Y := -64.0


## World y for a player whose feet are in block row `feet_block_y`.
static func spawn_y(feet_block_y: int) -> float:
	return feet_block_y + 0.05


static func has_fallen(y: float) -> bool:
	return y < FALL_LIMIT_Y


## First y >= start_y with `clearance` free rows from y upwards (2 for a normal player).
## is_solid: func(y: int) -> bool for the column being checked. Returns max_y if none found.
static func first_free_y(start_y: int, is_solid: Callable, max_y: int, clearance: int = 2) -> int:
	var y := start_y
	while y < max_y:
		var free := true
		for dy in clearance:
			if is_solid.call(y + dy):
				free = false
				break
		if free:
			return y
		y += 1
	return max_y


## Height to wait on before spawning at a saved position: a mid-air save (flying) waits for the
## ground below it, because empty air never produces a mesh to wait for.
static func readiness_probe_y(target_y: float, surface_height: int) -> float:
	return minf(target_y, surface_height + 1.0)
