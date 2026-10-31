class_name SkyDragonRules
extends RefCounted
## The Sky Dragon, the Dragon Realm's boss (owner feedback #39, spec §14.2a; our own design), as pure rules. A big,
## friendly-fierce dragon that flies:
## - It ARRIVES from the sky, then CIRCLES high over the arena (out of a sword's reach; arrows and thrown spears
##   reach it), round the middle at CIRCLE_RADIUS.
## - The DIVE: it picks a child, climbs and glows while a line shows on the ground where it will dive (DIVE_WARN,
##   1.4 s, every screen sees it), then swoops along that line: whoever stands on the line (feet within DIVE_REACH)
##   when it passes low takes DIVE_DAMAGE and a push off the line (never out of the arena); a step off the line
##   dodges it. The line starts under it, runs through the child and on past them, and never leaves the arena.
## - After a dive it GLIDES low and slow towards the middle (the window to hit it with a sword); after every second
##   dive it LANDS and RESTS (double damage, like the Golem's daze), then TAKES OFF and circles again.
## - Crystal towers rise round the arena when it has arrived and once more at a third of its health: each heals it
##   a little every second (heal_per_second) until the team breaks it with TOWER_HITS hits. Towers never hurt.
## Health by team size and honest help like the Golem's (BossRules.TEAM_SHARE, TIRED_SHARE); a tired dragon also
## raises fewer towers and is slower. It never leaves the arena circle (ARENA_LIMIT from the middle), flies above
## the ground and cover under it (floor_under), and never changes a block.

const BASE_HP := 480
const DIVE_DAMAGE := 4

const NAME := "Sky Dragon"
const TITLE := "SKY DRAGON"
const TIRED_TITLE := "TIRED DRAGON"
const WIN_MESSAGE := "You beat the Sky Dragon!"
const TIRED_MESSAGE := "The Sky Dragon is tired today: less health and fewer sun lanterns!"
const SUMMON_LINE := "%s called the Sky Dragon! Step off its dive line!"
const TOWER_LINE := "Break the sun lanterns — they heal the Sky Dragon!"   # owner #43: never crystals on dark pillars
const TOWER_LINE_AGAIN := "New sun lanterns! Break them — they heal the Sky Dragon!"

enum Phase { RISE, CIRCLE, DIVE_WARN, DIVE, GLIDE, CLIMB, LAND, REST, TAKE_OFF, DOWN }

## Heights of its feet over the ground under it.
const ARRIVE_HEIGHT := 18.0       # it comes down from this high
const FLY_HEIGHT := 8.0           # circling: over a jumping child and any cover
const WARN_RISE := 1.5            # it climbs this much more while its line shows
const DIVE_LOW := 0.4             # the bottom of the swoop
const GLIDE_HEIGHT := 1.2         # after a dive: low enough for a sword

const CIRCLE_RADIUS := 12.0
const CIRCLE_SPEED := 6.0         # m/s along the circle
const ARENA_LIMIT := 30.0         # never farther than this (flat) from the arena's middle
const DIVE_SPEED := 13.0          # m/s along the line (a child walks 6)
const TIRED_SPEED := 0.8          # a tired dragon dives this much slower
const DIVE_OVERSHOOT := 7.0       # the line goes on past the child
const DIVE_MIN := 10.0            # never a shorter line
const DIVE_REACH := 1.3           # feet this close to the line (flat) are on it ...
const LINE_HALF_WIDTH := 1.4      # ... and the line drawn on the ground is a little wider: off it is always safe
const DIVE_BAND_BELOW := 1.6      # it hits a child whose feet are up to this far under its own ...
const DIVE_BAND_ABOVE := 2.0      # ... or this far over them (inside its body): it is low enough
const DIVE_PUSH := 7.0            # m/s off the line
const PUSH_INWARD_BEYOND := 20.0  # a child farther out than this is pushed back towards the middle
const GLIDE_SPEED := 3.0
const GLIDE_STOP := 5.0           # it glides towards the middle, up to this far from it
const DIVES_BEFORE_REST := 2
const REST_FACTOR := 2            # double damage while it rests

const TIMES := {Phase.RISE: 2.5, Phase.CIRCLE: 3.0, Phase.DIVE_WARN: 1.4, Phase.GLIDE: 2.5, Phase.CLIMB: 1.5,
	Phase.LAND: 1.0, Phase.REST: 3.5, Phase.TAKE_OFF: 1.2}
const TIRED_TIMES := {Phase.CIRCLE: 4.0, Phase.DIVE_WARN: 1.5, Phase.GLIDE: 3.2, Phase.REST: 4.5}

const TOWERS := 4
const TIRED_TOWERS := 3
const TOWER_HITS := 4             # hits (any weapon) that break a tower
const TOWER_RING := 10.0          # towers stand this far from the middle
const HEAL_EVERY := 1.0
const HEAL_SHARE := 0.005         # each standing tower heals this share of its health every second (at least 1)

const FLOOR_SCAN := 24            # column_floor looks at most this many blocks up or down
const FOOTPRINT := 0.9            # floor_under_body looks this far round its feet (its body)
const PLATEAU := 1.5              # smooth_floors: cover raises the swoop this far before and after it
const DIVE_SAMPLE := 0.5          # the ground along a dive's line is read every this many metres ...
const DIVE_SIDE := 0.9            # ... on the line and this far to each side of it


static func max_hp(team: int, tired: bool = false) -> int:
	var hp := BASE_HP * (1.0 + BossRules.TEAM_SHARE * (maxi(team, 1) - 1))
	return roundi(hp * BossRules.TIRED_SHARE) if tired else roundi(hp)


# --- The schedule ---------------------------------------------------------------------------------------------

## How long `phase` lasts (tired: its own times); DIVE lasts as long as its line (`dive_length`) takes.
static func phase_time(phase: int, tired: bool = false, dive_length: float = 0.0) -> float:
	if phase == Phase.DIVE:
		return dive_length / dive_speed(tired)
	if tired and TIRED_TIMES.has(phase):
		return float(TIRED_TIMES[phase])
	return float(TIMES.get(phase, INF))


## What comes after `phase`; `dives` is the number of dives since it last rested (the one just made included).
static func next_phase(phase: int, dives: int) -> int:
	match phase:
		Phase.RISE, Phase.CLIMB, Phase.TAKE_OFF:
			return Phase.CIRCLE
		Phase.CIRCLE:
			return Phase.DIVE_WARN
		Phase.DIVE_WARN:
			return Phase.DIVE
		Phase.DIVE:
			return Phase.GLIDE
		Phase.GLIDE:
			return Phase.LAND if dives >= DIVES_BEFORE_REST else Phase.CLIMB
		Phase.LAND:
			return Phase.REST
		Phase.REST:
			return Phase.TAKE_OFF
	return Phase.DOWN


static func is_warning(phase: int) -> bool:
	return phase == Phase.DIVE_WARN


static func is_resting(phase: int) -> bool:
	return phase == Phase.REST


## Weapons reach it (not while it arrives or is gone).
static func hittable(phase: int) -> bool:
	return phase != Phase.RISE and phase != Phase.DOWN


static func hit_taken(amount: int, resting: bool) -> int:
	return maxi(amount, 0) * (REST_FACTOR if resting else 1)


static func dive_speed(tired: bool) -> float:
	return DIVE_SPEED * (TIRED_SPEED if tired else 1.0)


# --- The dive -------------------------------------------------------------------------------------------------

## The dive's line on the ground [from, to]: from right under the dragon (`start`), through the child's feet
## (`target`) and DIVE_OVERSHOOT past them, at least DIVE_MIN long, cut where it would leave the arena circle.
static func dive_line(start: Vector3, target: Vector3, center: Vector3) -> Array[Vector3]:
	var from := keep_in(Vector3(start.x, target.y, start.z), center)
	var d := Vector3(target.x - from.x, 0.0, target.z - from.z)
	var reach := d.length()
	if reach < 0.5:
		d = Vector3(target.x - center.x, 0.0, target.z - center.z)
		if d.length() < 0.5:
			d = Vector3(center.x - from.x, 0.0, center.z - from.z)
		if d.length() < 0.5:
			d = Vector3.FORWARD
		reach = 0.0
	var dir := d.normalized()
	var to := from + dir * maxf(reach + DIVE_OVERSHOOT, DIVE_MIN)
	return [from, _clip(from, to, center)]


## Where the segment from→to (from inside) leaves the arena circle, or `to` when it stays inside.
static func _clip(from: Vector3, to: Vector3, center: Vector3) -> Vector3:
	var f := Vector2(from.x - center.x, from.z - center.z)
	var v := Vector2(to.x - from.x, to.z - from.z)
	if (f + v).length() <= ARENA_LIMIT:
		return to
	var a := v.dot(v)
	var b := 2.0 * v.dot(f)
	var c := f.dot(f) - ARENA_LIMIT * ARENA_LIMIT
	var disc := b * b - 4.0 * a * c
	if a < 0.0001 or disc < 0.0:
		return keep_in(to, center)
	var t := clampf((-b + sqrt(disc)) / (2.0 * a), 0.0, 1.0)
	return keep_in(from + (to - from) * t, center)


## Its height over the ground at `s` metres along the line: from `start_height` (where it hovered) down to
## DIVE_LOW, reached before the child (who stands `target_s` along), and low from there on.
static func dive_height(s: float, target_s: float, start_height: float) -> float:
	var descent := clampf(target_s * 0.8, 2.0, 9.0)
	var k := 1.0 - clampf(s / descent, 0.0, 1.0)
	return DIVE_LOW + maxf(start_height - DIVE_LOW, 0.0) * k * k


## This step of the swoop, from `from` to `to` (its feet): the indexes of the targets ([{pos: feet}]) on the line
## (feet within DIVE_REACH, flat) and within its height band (it is low enough to hit them).
static func dive_hits(from: Vector3, to: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	var low := minf(from.y, to.y)
	var high := maxf(from.y, to.y)
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		var q := Vector2(p.x, p.z)
		var d := q.distance_to(Geometry2D.get_closest_point_to_segment(q, a, b)) if a != b else q.distance_to(a)
		if d <= DIVE_REACH and p.y >= low - DIVE_BAND_BELOW and p.y <= high + DIVE_BAND_ABOVE:
			out.append(i)
	return out


## The push for a child hit at `child` by the dragon at `dragon` diving along `dir`: sideways off the line on the
## child's side (and a little along), with a hop; a child far out is pushed back towards the middle instead.
static func dive_push(dir: Vector3, child: Vector3, dragon: Vector3, center: Vector3) -> Vector3:
	var flat := Vector3(dir.x, 0.0, dir.z)
	flat = flat.normalized() if flat.length() > 0.001 else Vector3.FORWARD
	var side := Vector3(-flat.z, 0.0, flat.x)
	if side.dot(child - dragon) < 0.0:
		side = -side
	var out := Vector3(child.x - center.x, 0.0, child.z - center.z)
	if out.length() > PUSH_INWARD_BEYOND and side.dot(out) > 0.0:
		side = -side
	return (side + flat * 0.3).normalized() * DIVE_PUSH + Vector3.UP * 4.0


# --- Where it flies -------------------------------------------------------------------------------------------

## `pos` moved sideways back into the arena circle (ARENA_LIMIT from `center`); its height is kept.
static func keep_in(pos: Vector3, center: Vector3, limit: float = ARENA_LIMIT) -> Vector3:
	var off := Vector2(pos.x - center.x, pos.z - center.z)
	if off.length() <= limit:
		return pos
	off = off.normalized() * limit
	return Vector3(center.x + off.x, pos.y, center.z + off.y)


## Its spot on the circle at `angle` (radians round the middle), at height `y`.
static func circle_point(center: Vector3, angle: float, y: float) -> Vector3:
	return Vector3(center.x + cos(angle) * CIRCLE_RADIUS, y, center.z + sin(angle) * CIRCLE_RADIUS)


## The top of the ground in column (x, z), found from `guess` (the ground it knew nearby): up while the cell at the
## guess is ground, down while the one under it is air, at most FLOOR_SCAN each way. Ground is a solid block or water
## (it never flies into either). Over the void it keeps `guess`. On flat ground it reads two cells. block_at(cell).
static func column_floor(x: float, z: float, guess: float, block_at: Callable) -> float:
	var cx := floori(x)
	var cz := floori(z)
	var y := floori(guess)
	if _ground(block_at.call(Vector3i(cx, y, cz))):
		for i in FLOOR_SCAN:
			y += 1
			if not _ground(block_at.call(Vector3i(cx, y, cz))):
				break
		return float(y)
	for i in FLOOR_SCAN:
		if _ground(block_at.call(Vector3i(cx, y - 1, cz))):
			return float(y)
		y -= 1
	return guess


static func _ground(id: int) -> bool:
	return BlockIds.is_solid(id) or id == BlockIds.WATER


## The highest ground under its body: a 3 × 3 grid of columns `reach` apart round (x, z) (its footprint plus how far
## it moves before it looks again); reach 0: its feet's column only (high in the air).
static func floor_under_body(x: float, z: float, guess: float, block_at: Callable, reach: float = FOOTPRINT) -> float:
	if reach <= 0.0:
		return column_floor(x, z, guess, block_at)
	var best := -INF
	for dx in [-reach, 0.0, reach]:
		for dz in [-reach, 0.0, reach]:
			best = maxf(best, column_floor(x + dx, z + dz, guess, block_at))
	return best


## The ground along a dive's line for its swoop, from `raw` floors sampled every `spacing` metres: each raised to the
## highest within PLATEAU metres, then sloping down 1 m per metre on both sides (it rises over cover early and comes
## down after it, never into it).
static func smooth_floors(raw: PackedFloat32Array, spacing: float = 1.0) -> PackedFloat32Array:
	var n := raw.size()
	var w := ceili(PLATEAU / maxf(spacing, 0.01))
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var best: float = raw[i]
		for j in range(maxi(i - w, 0), mini(i + w, n - 1) + 1):
			best = maxf(best, raw[j])
		out[i] = best
	for i in range(1, n):
		out[i] = maxf(out[i], out[i - 1] - spacing)
	for i in range(n - 2, -1, -1):
		out[i] = maxf(out[i], out[i + 1] - spacing)
	return out


# --- Crystal towers -------------------------------------------------------------------------------------------

## Its health in thirds: 3 above two thirds, 2 above a third, 1 above none, 0 beaten.
static func stage(hp: int, max_health: int) -> int:
	if hp <= 0:
		return 0
	if max_health <= 0:
		return 3
	if hp > max_health * 2.0 / 3.0:
		return 3
	if hp > max_health / 3.0:
		return 2
	return 1


## Towers rise once more when it is down to a third (the first rise comes when it has arrived).
static func towers_due(rises_done: int, hp: int, max_health: int) -> bool:
	return rises_done == 1 and stage(hp, max_health) == 1


static func tower_count(tired: bool) -> int:
	return TIRED_TOWERS if tired else TOWERS


## Where the towers of rise number `rise` (0 = the first) stand: evenly round the middle at TOWER_RING, each rise
## turned half a step so the new ones stand in new places. y is the middle's (the host puts them on the ground).
static func tower_spots(center: Vector3, rise: int, count: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var n := maxi(count, 1)
	for i in count:
		var a := TAU * i / n + PI / 4.0 + rise * PI / n
		out.append(Vector3(center.x + cos(a) * TOWER_RING, center.y, center.z + sin(a) * TOWER_RING))
	return out


static func tower_standing(hits: int) -> bool:
	return hits < TOWER_HITS


## Towers still standing, from their hits.
static func standing(hits: PackedByteArray) -> int:
	var n := 0
	for h in hits:
		if tower_standing(h):
			n += 1
	return n


## Its healing every second from `towers` standing towers: a small share of its health each (at least 1).
static func heal_per_second(max_health: int, towers: int) -> int:
	return maxi(roundi(max_health * HEAL_SHARE), 1) * maxi(towers, 0)


## Its health after one second of healing (never above its max; a beaten dragon stays beaten).
static func healed(hp: int, max_health: int, towers: int) -> int:
	if hp <= 0:
		return hp
	return mini(hp + heal_per_second(max_health, towers), maxi(max_health, hp))
