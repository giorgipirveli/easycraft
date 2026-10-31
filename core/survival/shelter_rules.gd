class_name ShelterRules
extends RefCounted
## Build to Survive's shelter rule (spec §12.18), pure. A player whose feet are in cell `feet` (the head is
## the cell above) is sheltered when
## - a roof: a solid block within ROOF_REACH above the head, and
## - walls: at the head's level and at the feet's, a flood through the open cells around them (four sides at
##   a time, so a crack where two blocks only touch at an edge stays closed) never reaches a cell
##   WALL_REACH or more blocks away (along x or z).
## The flood is the exact form of "every flat ray from the head meets a solid block within 6": a fixed set
## of rays misses a window that lies between two of them, and a monster walks round a bend that no straight
## ray does (ruling in docs/devlog/parts/survivor-games-crafting.md). `solid_at(cell) -> bool` says what is
## solid (BlockIds.is_solid: closed doors, glass and leaves are; open doors, water, bushes and air are not).
## Every cell it reads lies in box(feet), so one bulk copy of that box serves a whole check.

const SAFE := &"safe"         # a roof and closed walls
const NO_ROOF := &"no_roof"   # closed walls, no roof
const GAP := &"gap"           # a roof, but a way out
const OPEN := &"open"         # neither
const ROOF_REACH := 4
const WALL_REACH := 6

const _HINTS := {SAFE: "Safe inside!", NO_ROOF: "Add a roof!", GAP: "Close the gap!", OPEN: "Build walls and a roof!"}
const _SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## SAFE, NO_ROOF, GAP or OPEN for a player whose feet are in `feet`.
static func check(feet: Vector3i, solid_at: Callable) -> StringName:
	var roof := has_roof(feet, solid_at)
	var walls := walls_closed(feet, solid_at) and walls_closed(feet + Vector3i.UP, solid_at)
	if roof and walls:
		return SAFE
	if walls:
		return NO_ROOF
	return GAP if roof else OPEN


## check() == SAFE, looking at the walls only when there is a roof.
static func is_sheltered(feet: Vector3i, solid_at: Callable) -> bool:
	return has_roof(feet, solid_at) and walls_closed(feet + Vector3i.UP, solid_at) and walls_closed(feet, solid_at)


## A solid block 1..ROOF_REACH above the head.
static func has_roof(feet: Vector3i, solid_at: Callable) -> bool:
	for dy in range(2, 2 + ROOF_REACH):
		if solid_at.call(feet + Vector3i(0, dy, 0)):
			return true
	return false


## Walls close `cell` in at its level: the flood from it never gets WALL_REACH blocks away.
static func walls_closed(cell: Vector3i, solid_at: Callable) -> bool:
	var seen := {Vector2i.ZERO: true}
	var todo: Array[Vector2i] = [Vector2i.ZERO]
	while not todo.is_empty():
		var at: Vector2i = todo.pop_back()
		for side in _SIDES:
			var next: Vector2i = at + side
			if seen.has(next):
				continue
			seen[next] = true
			if solid_at.call(cell + Vector3i(next.x, 0, next.y)):
				continue
			if maxi(absi(next.x), absi(next.y)) >= WALL_REACH:
				return false
			todo.append(next)
	return true


## The words under the clock's house picture.
static func hint(state: StringName) -> String:
	return _HINTS.get(state, "")


## The cell a body's feet (its position) are in.
static func feet_cell(pos: Vector3) -> Vector3i:
	return Vector3i(pos.floor())


## [origin, size] of every cell a check of `feet` may read (for WorldService.box_reader / copy_box).
static func box(feet: Vector3i) -> Array:
	return [feet - Vector3i(WALL_REACH, 0, WALL_REACH), Vector3i(2 * WALL_REACH + 1, 2 + ROOF_REACH, 2 * WALL_REACH + 1)]
