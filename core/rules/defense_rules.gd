class_name DefenseRules
extends RefCounted
## Doors, spike traps and lanterns (M2 Task 8, spec §12.6) as pure rules.
## - A door is one block, closed (DOOR, solid) or open (DOOR_OPEN, walk-through). A doorway is two
##   doors stacked; a tap opens or closes the whole stack (at most MAX_DOOR_STACK). The host applies
##   the toggle like any edit (Session, "M2 Task 8"). Monsters never open doors, never step up onto a
##   closed one and never hop over it (door_in_way); an open door is a way in.
## - A spike trap hurts a monster standing on it or in it TRAP_DAMAGE every TRAP_INTERVAL, from the
##   first step; never players, bot friends or animals (only group `monsters` is hurt).
## - Monsters of level LANTERN_FEAR_MAX_LEVEL or less keep LANTERN_KEEP_AWAY blocks from a lantern:
##   they stop before they would come closer and walk away when one is already closer. Night spawns
##   stay MonsterRules.LIGHT_CLEAR (8) blocks from lanterns (MonsterRules.spot_refusal).

const MAX_DOOR_STACK := 3
const TRAP_DAMAGE := 2
const TRAP_INTERVAL := 1.0
const NO_TRAP := Vector3i(-2147483648, -2147483648, -2147483648)
const LANTERN_KEEP_AWAY := 6.0
const LANTERN_FEAR_MAX_LEVEL := 2
const _STEP := 0.3                # door_in_way samples the way this far apart ...
const _LANE := 0.5                # ... and across the body at most this far apart (no cell between its sides skipped)
const _EPSILON := 0.0001


# --- Doors ------------------------------------------------------------------------------------------

static func is_door(id: int) -> bool:
	return id == BlockIds.DOOR or id == BlockIds.DOOR_OPEN


## Closed <-> open; anything else stays itself.
static func toggled(id: int) -> int:
	if id == BlockIds.DOOR:
		return BlockIds.DOOR_OPEN
	if id == BlockIds.DOOR_OPEN:
		return BlockIds.DOOR
	return id


## The doors stacked with the one at `pos`, from the bottom up (at most MAX_DOOR_STACK, always
## holding `pos`); [] when `pos` is not a door. block_at(pos: Vector3i) -> int.
static func door_stack(pos: Vector3i, block_at: Callable) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if not is_door(block_at.call(pos)):
		return out
	var bottom := pos
	while pos.y - bottom.y < MAX_DOOR_STACK - 1 and is_door(block_at.call(bottom + Vector3i.DOWN)):
		bottom += Vector3i.DOWN
	var cell := bottom
	while out.size() < MAX_DOOR_STACK and is_door(block_at.call(cell)):
		out.append(cell)
		cell += Vector3i.UP
	return out


## What a tap on the door at `pos` changes: [[cell, id], ...] for its whole stack, every door set to
## the tapped one's other state (a half-open stack follows the tapped door). [] for a non-door.
static func toggle_changes(pos: Vector3i, block_at: Callable) -> Array:
	var to := toggled(block_at.call(pos))
	var out: Array = []
	for cell in door_stack(pos, block_at):
		out.append([cell, to])
	return out


## Is a closed door in the way of a body at `feet` (radius `radius`) going `dir` for `reach` blocks,
## at the level of its feet (a door there would be climbed or hopped over)? A door higher up is a
## wall like any other; an open door is a way in. Every cell under the body's square is looked at, then every cell
## between its two sides ahead (lanes at most _LANE apart: with a wide radius a door between the middle and a side was
## skipped), at the feet's level and the one under them (a body standing on a sliver of a door's top still has it under
## its feet): 2026-10-18, a crowd of the game's 20 at a single closed door got a big spore puff, yeti, goblin or crawler
## over it through those gaps.
## `body`: the body's own half-width for the cells under it (the feet's square; default `radius`).
static func door_in_way(feet: Vector3, dir: Vector3, reach: float, radius: float, block_at: Callable,
		body: float = -1.0) -> bool:
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length() < 0.01:
		return false
	flat = flat.normalized()
	var across := Vector3(-flat.z, 0.0, flat.x)
	var lanes := maxi(1, ceili(radius / _LANE))   # side lanes each way
	var y := floori(feet.y + 0.1)
	var seen: Array[Vector3i] = []
	var half := radius if body < 0.0 else body
	for below in 2:   # under the body: every cell its square stands over or touches (a door under its feet's edge)
		for cz in range(floori(feet.z - half), floori(feet.z + half) + 1):
			for cx in range(floori(feet.x - half), floori(feet.x + half) + 1):
				var under := Vector3i(cx, y - below, cz)
				seen.append(under)
				var id: int = block_at.call(under)
				if id == BlockIds.DOOR or id == BlockIds.POWERED_DOOR:
					return true
	var d := _STEP   # then ahead
	while d <= reach + _EPSILON:
		var p := feet + flat * d
		for k in range(-lanes, lanes + 1):   # M5 Task 3: no array made per step
			var q: Vector3 = p + across * (radius * k / lanes)
			for below in 2:   # the feet's level, then the one under them
				var cell := Vector3i(floori(q.x), y - below, floori(q.z))
				if seen.has(cell):
					continue
				seen.append(cell)
				var id: int = block_at.call(cell)   # M5 Task 3: one read a cell (it was read twice when not a door)
				if id == BlockIds.DOOR or id == BlockIds.POWERED_DOOR:   # M3 Task 7: powered too
					return true
		d += _STEP
	return false


# --- Spike traps --------------------------------------------------------------------------------------

## The spike trap a body with its feet at `feet` stands on (the cell below) or in, else NO_TRAP.
static func trap_under(feet: Vector3, block_at: Callable) -> Vector3i:
	var cell := Vector3i((feet + Vector3(0.0, 0.05, 0.0)).floor())
	if block_at.call(cell) == BlockIds.SPIKE_TRAP:
		return cell
	if block_at.call(cell + Vector3i.DOWN) == BlockIds.SPIKE_TRAP:
		return cell + Vector3i.DOWN
	return NO_TRAP


## One check of a monster against the traps, `delta` seconds after the last: {cooldown, hit}. A hit
## comes at once on the first step and then every TRAP_INTERVAL while it stays; the wait keeps
## running off the trap, so hopping off and on never hurts faster.
static func trap_tick(cooldown: float, on_trap: bool, delta: float) -> Dictionary:
	var c := maxf(cooldown - delta, 0.0)
	if on_trap and c <= _EPSILON:
		return {"cooldown": TRAP_INTERVAL, "hit": true}
	return {"cooldown": c, "hit": false}


# --- Lanterns -----------------------------------------------------------------------------------------

static func fears_lanterns(level: int) -> bool:
	return level <= LANTERN_FEAR_MAX_LEVEL


## Where a monster of `level` at `pos` may go instead of `dir`, with lanterns at `lanterns`: away from
## a lantern closer than LANTERN_KEEP_AWAY, nowhere (ZERO) when `lookahead` blocks along `dir` would
## come that close, else `dir`. Strong monsters always keep `dir`.
static func lantern_dir(pos: Vector3, dir: Vector3, level: int, lanterns: Array[Vector3i], lookahead: float) -> Vector3:
	if not fears_lanterns(level) or lanterns.is_empty():
		return dir
	var near := nearest(pos, lanterns, 1)
	var center := Vector3(near[0]) + Vector3(0.5, 0.5, 0.5)
	if center.distance_to(pos) < LANTERN_KEEP_AWAY:
		var away := Vector3(pos.x - center.x, 0.0, pos.z - center.z)
		return away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	if dir == Vector3.ZERO:
		return dir
	var ahead := pos + Vector3(dir.x, 0.0, dir.z).normalized() * lookahead
	for l in lanterns:
		if (Vector3(l) + Vector3(0.5, 0.5, 0.5)).distance_to(ahead) < LANTERN_KEEP_AWAY:
			return Vector3.ZERO
	return dir


## The `n` cells nearest to `from` (cell middles), nearest first.
static func nearest(from: Vector3, cells: Array[Vector3i], n: int) -> Array[Vector3i]:
	var sorted := cells.duplicate()
	sorted.sort_custom(func(a: Vector3i, b: Vector3i) -> bool:
		return (Vector3(a) + Vector3(0.5, 0.5, 0.5)).distance_squared_to(from) < (Vector3(b) + Vector3(0.5, 0.5, 0.5)).distance_squared_to(from))
	var out: Array[Vector3i] = []
	for i in mini(n, sorted.size()):
		out.append(sorted[i])
	return out
