class_name CourseRules
extends RefCounted
## Game Blocks (M3 Task 7, spec §14.4, §3a): an obstacle course or race in 60 seconds, no code. Pure rules:
## - START arms a runner's clock (0.0 while they stand on it); stepping off starts it (CourseRun).
## - CHECKPOINT is where a fallen runner comes back: more than FALL_DEPTH blocks below it, in water, or out
##   of the world.
## - COIN blocks count once per run: the course's score, never Survivor gold.
## - FINISH stops the clock; the medal comes from the builder's goals (gold, silver, bronze times). The
##   first finished run sets them: × GOAL_FACTORS.

const FALL_DEPTH := 12.0
const WORLD_BOTTOM := -64.0
const MIN_GOAL_MS := 1000
const MAX_GOAL_MS := 30 * 60 * 1000
const GOAL_FACTORS: Array[float] = [1.0, 1.3, 1.6]
const RUN_MAX_MS := 15 * 60 * 1000       # a run left going this long stops by itself
const COURSE_RADIUS := 256.0             # ... and one that wanders this far from its START
const EDGE := 0.7                        # the footprint's corners checked, as a share of the body's radius

const GOLD := &"gold"
const SILVER := &"silver"
const BRONZE := &"bronze"
const NO_MEDAL := &""
const MEDALS: Array[StringName] = [GOLD, SILVER, BRONZE]

## Blocks a runner stands on for them to count (a coin is walked through instead).
const FLOOR_BLOCKS: Array[int] = [BlockIds.START, BlockIds.CHECKPOINT, BlockIds.FINISH, BlockIds.TELEPORT_PAD]


static func is_floor_block(id: int) -> bool:
	return FLOOR_BLOCKS.has(id)


## Where a runner stands on the block at `cell` (its top, in the middle).
static func top_of(cell: Vector3i) -> Vector3:
	return Vector3(cell) + Vector3(0.5, 1.0, 0.5)


## The Game Block (or teleport pad) under a body's feet: [cell, id], or [] for none. The centre first,
## then the footprint's corners, so a foot on its edge counts (like PadRules.pad_under).
static func floor_block(feet: Vector3, radius: float, block_at: Callable) -> Array:
	var y := floori(feet.y - 0.05)
	var r := radius * EDGE
	for c: Vector2 in [Vector2.ZERO, Vector2(r, r), Vector2(-r, r), Vector2(r, -r), Vector2(-r, -r)]:
		var cell := Vector3i(floori(feet.x + c.x), y, floori(feet.z + c.y))
		var id := int(block_at.call(cell))
		if is_floor_block(id):
			return [cell, id]
		if radius <= 0.0:
			break
	return []


## Gold, silver and bronze times from the first finished run (never under a second).
static func default_goals(ms: int) -> Array[int]:
	var base := maxi(ms, MIN_GOAL_MS)
	var out: Array[int] = []
	for f in GOAL_FACTORS:
		out.append(clampi(roundi(base * f), MIN_GOAL_MS, MAX_GOAL_MS))
	return out


## Three times, fastest first, each within MIN_GOAL_MS..MAX_GOAL_MS; [] when anything is broken.
static func clean_goals(goals: Variant) -> Array[int]:
	var out: Array[int] = []
	if not goals is Array or (goals as Array).size() != 3:
		return out
	for g: Variant in goals:
		if not typeof(g) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(g)):
			return [] as Array[int]
		out.append(int(clampf(float(g), MIN_GOAL_MS, MAX_GOAL_MS)))
	out.sort()
	return out


## The goals with medal `i`'s time moved by `delta_ms`; the others give way so the order holds.
static func step_goal(goals: Array[int], i: int, delta_ms: int) -> Array[int]:
	var out: Array[int] = goals.duplicate()
	if i < 0 or i >= out.size():
		return out
	out[i] = clampi(out[i] + delta_ms, MIN_GOAL_MS, MAX_GOAL_MS)
	for k in range(i + 1, out.size()):
		out[k] = maxi(out[k], out[i])
	for k in range(i - 1, -1, -1):
		out[k] = mini(out[k], out[i])
	return out


## The medal for a finished run of `ms` by these goals (no goals yet: gold, the run sets them).
static func medal(ms: int, goals: Array[int]) -> StringName:
	if goals.size() != 3:
		return GOLD
	for i in 3:
		if ms <= goals[i]:
			return MEDALS[i]
	return NO_MEDAL


## A runner fell: more than FALL_DEPTH below where they come back, in water, or out of the world.
static func fell(feet: Vector3, back_to: Vector3, in_water: bool) -> bool:
	return in_water or feet.y < back_to.y - FALL_DEPTH or feet.y < WORLD_BOTTOM


## "1:02.3"
static func format_time(ms: int) -> String:
	var t := maxi(ms, 0)
	return "%d:%02d.%d" % [t / 60000, (t / 1000) % 60, (t / 100) % 10]
