class_name ArcherRules
extends RefCounted
## The goblin archers as pure rules (M3 Task 14b, spec §13.7: build-fight practice). A goblin with a bow
## shoots from 10 to 20 blocks and backs off from a child who comes close. It looks for a spot around it (a
## few candidates a decision, never a big search) where a block stands between it and the child (cover),
## with a free step beside it from where the shot is clear (the peek); higher spots score better (it likes
## high ground). It waits in cover, steps out, draws its bow for a whole second (the arrow's tip glows: the
## signal) and shoots a slow, big arrow lobbed onto where the child stands (no lead: a sidestep dodges it).
## Arrows fly like every arrow (WeaponRules.arrow_step) and stop at the first block: never through a wall,
## so a child learns to build a wall or take the high ground. It never changes a block (it only reads them).

const RANGE_MIN := 10.0
const RANGE_MAX := 20.0
const RANGE_RISE := 10.0          # ... and no more than this far up or down
const IDEAL := 14.0
const TOO_CLOSE := 6.0            # a child closer than this: it backs off
const WINDUP := 1.0               # the bow is drawn this long before the arrow flies (§13.7: signalled 1 s before)
const COOLDOWN := 2.6             # between two shots
const HIDE_TIME := 1.4            # it waits in cover this long before it steps out again
const ARROW_SPEED := 12.0         # slow: a child sees it coming and can step aside or duck behind a wall
const ARROW_GRAVITY := 6.0
const ARROW_LIFE := 3.0
const ARROW_HIT := 0.45           # an arrow hits a body whose chest comes this close
const EYE := 1.1                  # its eyes (and bow) over its feet
const CHEST := 1.0                # where it aims on a child (over the feet)
const STAND_RISE := 3             # a standing spot is looked for this far up or down
const NO_SPOT := -99999

# The spot search: two rings of eight directions around it, a couple a decision.
const RINGS: Array[int] = [2, 4]
const DIRECTIONS := 8
const CANDIDATES := 16
const SEARCH_PER_DECISION := 2
const SEARCH_EVERY := 2.5         # seconds before it looks for a better spot again

# How a spot scores.
const HEIGHT_WEIGHT := 1.0        # per block above the child
const COVER_BONUS := 3.0
const RANGE_WEIGHT := 0.2         # per block from IDEAL
const WALK_WEIGHT := 0.15         # per block to walk there

# Where archers come from.
const NIGHT_MIN_LEVEL := 2
const NIGHT_SHARE := 0.4          # this share of the night goblins of level 2 and up carry a bow
const WAVE_FROM := 4              # waves from this one on bring archers (every other goblin)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## May it shoot at a child whose feet are at `target` from `from` (its feet)?
static func in_range(from: Vector3, target: Vector3) -> bool:
	var d := _flat(from, target)
	return d >= RANGE_MIN and d <= RANGE_MAX and absf(target.y - from.y) <= RANGE_RISE


static func too_close(from: Vector3, target: Vector3) -> bool:
	return _flat(from, target) < TOO_CLOSE


## The arrow's velocity from `from` (its bow) onto `chest`: the low lob at ARROW_SPEED.
static func aim(from: Vector3, chest: Vector3) -> Vector3:
	return WeaponRules.launch_direction(from, chest, ARROW_SPEED, ARROW_GRAVITY) * ARROW_SPEED


## Does an arrow shot from `from` at `velocity` reach a body at `chest` before any block (is_solid(cell))?
## The arrow's own flight, step by step: a wall in the way always stops it.
static func shot_reaches(from: Vector3, velocity: Vector3, chest: Vector3, is_solid: Callable, dt: float = 1.0 / 30.0) -> bool:
	var pos := from
	var vel := velocity
	var t := 0.0
	while t < ARROW_LIFE:
		var s := WeaponRules.arrow_step(pos, vel, dt, is_solid, ARROW_GRAVITY)
		if WeaponRules.segment_hits_sphere(pos, s.pos, chest, ARROW_HIT) >= 0.0:
			return true
		if s.stuck:
			return false
		pos = s.pos
		vel = s.vel
		t += dt
	return false


## The candidate offset (x, z) number i of the spot search (0..CANDIDATES-1).
static func candidate(i: int) -> Vector2i:
	var ring: int = RINGS[clampi(i / DIRECTIONS, 0, RINGS.size() - 1)]
	return _DIRS[i % DIRECTIONS] * ring


const _DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0),
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]


## Where feet stand in column (x, z) near height `near_y`: the highest cell within STAND_RISE with room for a
## body (2 cells) on solid ground, or NO_SPOT. is_solid(cell) -> bool.
static func stand_y(x: int, z: int, near_y: int, is_solid: Callable) -> int:
	for y in range(near_y + STAND_RISE, near_y - STAND_RISE - 1, -1):
		if not is_solid.call(Vector3i(x, y, z)) and not is_solid.call(Vector3i(x, y + 1, z)) \
				and is_solid.call(Vector3i(x, y - 1, z)):
			return y
	return NO_SPOT


## How good standing at `feet` is for shooting at a child whose feet are at `target`, walking from `here`:
## {} when it is out of range or has no clear shot (neither from there nor from a step beside it), else
## {spot, peek (where it shoots from), cover (a block between spot and child), score}.
static func score_spot(feet: Vector3, target: Vector3, here: Vector3, is_solid: Callable) -> Dictionary:
	var d := _flat(feet, target)
	if d < RANGE_MIN or d > RANGE_MAX or absf(target.y - feet.y) > RANGE_RISE:
		return {}
	var chest := target + Vector3(0, CHEST, 0)
	var peek := feet
	var cover := not MonsterRules.clear_line(feet + Vector3(0, EYE, 0), chest, is_solid)
	if cover:
		peek = _peek(feet, target, chest, is_solid)
		if not peek.is_finite():
			return {}
	var score := HEIGHT_WEIGHT * (feet.y - target.y) - RANGE_WEIGHT * absf(d - IDEAL) - WALK_WEIGHT * _flat(here, feet)
	if cover:
		score += COVER_BONUS
	return {"spot": feet, "peek": peek, "cover": cover, "score": score}


## A step to either side of `feet` (across the line to the child), on the same ground, from where the shot at
## `chest` is clear; INF when there is none.
static func _peek(feet: Vector3, target: Vector3, chest: Vector3, is_solid: Callable) -> Vector3:
	var to := Vector2(target.x - feet.x, target.z - feet.z)
	if to.length() < 0.01:
		return Vector3.INF
	var side := Vector2(-to.y, to.x).normalized()
	var step := Vector2i(roundi(side.x), roundi(side.y))
	if step == Vector2i.ZERO:
		step = Vector2i(1, 0)
	var cell := Vector3i(feet.floor())
	for s in [1, -1]:
		var c := cell + Vector3i(step.x * s, 0, step.y * s)
		if is_solid.call(c) or is_solid.call(c + Vector3i.UP) or not is_solid.call(c + Vector3i.DOWN):
			continue
		var p := Vector3(c.x + 0.5, c.y, c.z + 0.5)
		if MonsterRules.clear_line(p + Vector3(0, EYE, 0), chest, is_solid):
			return p
	return Vector3.INF


## A night monster's kind: some goblins of level NIGHT_MIN_LEVEL and up come with a bow (roll 0..1).
static func night_kind(kind: StringName, level: int, roll: float) -> StringName:
	if kind == MonsterRules.GOBLIN and level >= NIGHT_MIN_LEVEL and roll < NIGHT_SHARE:
		return MonsterRules.ARCHER
	return kind


## A wave's monsters with archers: from WAVE_FROM on, every other goblin carries a bow (always the same ones,
## so a wave can be learned). Waves without goblins are unchanged.
static func wave_roster(roster: Array[Dictionary], wave: int) -> Array[Dictionary]:
	if wave < WAVE_FROM:
		return roster
	var out: Array[Dictionary] = []
	var goblins := 0
	for e in roster:
		var entry := e.duplicate()
		if entry.kind == MonsterRules.GOBLIN:
			if goblins % 2 == 1:
				entry.kind = MonsterRules.ARCHER
			goblins += 1
		out.append(entry)
	return out
