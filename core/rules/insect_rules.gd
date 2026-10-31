class_name InsectRules
extends RefCounted
## Bees and butterflies over Green Meadows (owner feedback #41, spec §14.19), as pure rules: they fly by day,
## outdoors, while this game's player stands over the meadow's grass or bushes (the game has no flower block: the
## meadow is its flowers). MeadowInsects shows them.

const FLOWERS: Array[int] = [BlockIds.GRASS, BlockIds.BUSH, BlockIds.LEAVES]
const UNDERGROUND := 0.3          # deeper under a roof than this (Ambience.underground): none


static func on(time_of_day: float, underground: float, ground: int) -> bool:
	return not DayCycle.is_night(time_of_day) and underground < UNDERGROUND and FLOWERS.has(ground)
