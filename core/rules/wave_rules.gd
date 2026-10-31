class_name WaveRules
extends RefCounted
## The Monster Totem and its waves as pure rules (M2 spec §12.8, §12.15; research G6 "easier or
## again?"). Wave N brings 3 + 2N monsters (at most 20) of levels ⌈N/2⌉ … ⌈N/2⌉+1 (at most 5), the
## same monsters every time (children can learn a wave), from the edge of a 25-block circle around the
## Totem. It is won when every monster is defeated, and ends without a win after 3 minutes or once
## every player has been knocked out. Every player not knocked out during a won wave gets 10 × N gold;
## a win raises the Totem's N (saved per world); after a wave that was not won the Totem offers it
## again or one easier (a normal wave N-1, paid like any other). The boss is offered once wave 5 is
## won. Sandbox waves are gentle: level 2 at most, 8 monsters at most, no gold.
## The Totem stands on flat, dry ground 20 blocks from the world spawn, facing it, placed once from
## the seed and the terrain rules (like Tilly's stall, TraderRules) and kept clear of her stall.

const FIRST_WAVE := 1
const MAX_WAVE := 99
const BASE_SIZE := 3
const SIZE_PER_WAVE := 2
const MAX_SIZE := 20
const GENTLE_MAX_SIZE := 8
## M4 E (§12.8, §17.5): half again as many monsters for each player or bot friend beyond the first.
const TEAM_SHARE := 0.5
const GENTLE_MAX_LEVEL := MonsterRules.GENTLE_MAX_LEVEL
const GOLD_PER_WAVE := 10
const TIME_LIMIT := 180.0         # seconds
const COUNTDOWN := 5              # "Wave N starts in 5…"
const BOSS_AFTER := 5             # the boss is offered once this wave is won
const RING := 25.0                # monsters come from the edge of this circle around the Totem
## Where a wave monster may appear, nearest the edge first; the last ones come closer, so a Totem on
## a small island (sea all round the ring) still gets its wave.
const RING_RADII: Array[float] = [25.0, 24.0, 26.0, 23.0, 27.0, 22.0, 21.0, 18.0, 14.0, 10.0, 8.0]
const RING_NUDGES: Array[float] = [0.0, 0.1, -0.1, 0.2, -0.2]   # radians either side of its place

## Outcomes of a running wave.
const GOING := &""
const WON := &"won"
const TIME_UP := &"time_up"
const KNOCKED_OUT := &"knocked_out"

# --- The Totem's place --------------------------------------------------------------------------

const TOTEM_DISTANCE := 20
const RADII: Array[int] = [20, 19, 21, 18, 22, 17, 23, 16, 24]
const ANGLE_STEPS := 48
const CLEAR_RADIUS := 3           # no tree trunk this close (in columns)
const TRADER_CLEAR := 8.0         # blocks from Tilly's stall
const HEIGHT := 3.6               # the Totem's pole, feet to the top of its horns
const HALF_WIDTH := 0.9           # taps hit a box this wide around the pole
const TAP_REACH := 6.0            # a player's eye to the nearest point of the pole
const HOST_REACH := 8.0           # the host's check, with slack for network lag

# --- Words (short; never shaming, research G6) ----------------------------------------------------

const TRY_AGAIN := "Try again"
const TRY_EASIER := "Try an easier wave"
const BOSS_WORD := "The Stone Golem!"
const REFUSALS := {
	&"busy": "A wave is on right now!",
	&"boss": "The Stone Golem is here!",
	&"off": "Monsters are OFF in this world.",
	&"too_far": "Come closer to the Totem!",
	&"no_boss": "Win wave 5 to wake the Stone Golem!",
	&"asleep": "The Stone Golem is still asleep. Soon!",
	&"game": GameWords.WAVE_WAITS,   # M4 H: a co-op game's round is on
	&"auto": "Here the waves come by themselves!",   # Monster Wave (spec §12.20)
}


static func valid_wave(n: int) -> int:
	return clampi(n, FIRST_WAVE, MAX_WAVE)


## How many monsters wave n brings for a team of `team` (players and bot friends; M4 E): +50% for
## each one beyond the first, rounded up, at most MAX_SIZE (gentle: GENTLE_MAX_SIZE).
static func size(n: int, gentle: bool, team: int = 1) -> int:
	var base := BASE_SIZE + SIZE_PER_WAVE * valid_wave(n)
	var s := mini(ceili(base * (1.0 + TEAM_SHARE * (maxi(team, 1) - 1)) - 0.0001), MAX_SIZE)
	return mini(s, GENTLE_MAX_SIZE) if gentle else s


## The lowest and highest level in wave n: ⌈n/2⌉ and one more, at most 5 (gentle: 2).
static func levels(n: int, gentle: bool) -> Vector2i:
	var lo := mini(ceili(valid_wave(n) / 2.0), MonsterRules.MAX_LEVEL)
	var hi := mini(lo + 1, MonsterRules.MAX_LEVEL)
	if gentle:
		return Vector2i(mini(lo, GENTLE_MAX_LEVEL), mini(hi, GENTLE_MAX_LEVEL))
	return Vector2i(lo, hi)


## Wave n's monsters, always the same: [{kind, level}]. Every second one is the higher level; three
## in five are slimes (like the night, MonsterRules.SLIME_SHARE), the rest goblins. A team's wave is
## the one-player wave with more monsters after it (M4 E).
## M3 Task 2: `kinds` is the universe's pair (the Sandstorm Desert: mummies and scorpions), the first as the slimes.
static func roster(n: int, gentle: bool, team: int = 1, kinds: Array[StringName] = MonsterRules.MEADOWS_KINDS) -> Array[Dictionary]:
	var lv := levels(n, gentle)
	var pair: Array[StringName] = kinds if kinds.size() >= 2 else MonsterRules.MEADOWS_KINDS
	var out: Array[Dictionary] = []
	for i in size(n, gentle, team):
		out.append({"kind": pair[1] if i % 5 in [1, 3] else pair[0],
			"level": lv.y if i % 2 == 1 else lv.x})
	return out


## Gold for each player still standing when wave n is won; nothing in Sandbox (∞ gold).
static func reward(n: int, sandbox: bool) -> int:
	return 0 if sandbox else GOLD_PER_WAVE * valid_wave(n)


## The players who get the reward: everyone here who was not knocked out during the wave.
static func paid(players: Array[int], knocked: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for p in players:
		if not knocked.has(p):
			out.append(p)
	return out


## How a running wave stands: `left` monsters alive, `pending` still to appear, `elapsed` seconds,
## the players here and the ones knocked out during it. The last monster falling wins even as the
## last player falls (kind).
static func outcome(left: int, pending: int, elapsed: float, players: Array[int], knocked: Array[int]) -> StringName:
	if left <= 0 and pending <= 0:
		return WON
	if not players.is_empty() and paid(players, knocked).is_empty():
		return KNOCKED_OUT
	if elapsed >= TIME_LIMIT:
		return TIME_UP
	return GOING


static func is_win(result: StringName) -> bool:
	return result == WON


## The Totem's N after wave `played` ended: a win raises it past that wave, nothing lowers it.
static func next_wave(next: int, played: int, won: bool) -> int:
	return valid_wave(maxi(next, played + 1)) if won else valid_wave(next)


## After wave `played` was not won, the easier choice (never below wave 1).
static func easier(played: int) -> int:
	return valid_wave(played - 1)


static func offers_easier(played: int) -> bool:
	return played > FIRST_WAVE


## Which waves a tap may start: the Totem's N, or after a wave that was not won (`lost`, 0 = none)
## that wave again or one easier.
static func may_start(wave: int, next: int, lost: int) -> bool:
	if wave < FIRST_WAVE:
		return false
	return wave == valid_wave(next) or (lost >= FIRST_WAVE and (wave == lost or wave == easier(lost)))


## The Totem offers the boss once wave BOSS_AFTER has been won (its N is past it).
static func boss_ready(next: int) -> bool:
	return next > BOSS_AFTER


## Winning this wave brings the boss offer up (wave 5 and every wave after it).
static func offers_boss(played: int, won: bool) -> bool:
	return won and played >= BOSS_AFTER


## The columns (x, z) monster `index` of `count` may appear on, best first: its own place on the
## edge of the circle (the monsters spread evenly from `start` radians), a little either side, a
## little in or out, and last closer in.
static func spawn_columns(center: Vector3, index: int, count: int, start: float) -> Array[Vector2]:
	var base := start + TAU * index / maxi(count, 1)
	var out: Array[Vector2] = []
	for r in RING_RADII:
		for nudge in RING_NUDGES:
			var a := base + nudge
			out.append(Vector2(center.x + cos(a) * r, center.z + sin(a) * r))
	return out


# --- The Totem ------------------------------------------------------------------------------------

## {pos: Vector3 (feet, cell centre), yaw: float (its face, -Z, towards the spawn)} on the 20-block ring
## (then nearby rings), on 3 x 3 flat ground where ground_ok(x, z), no trunk within CLEAR_RADIUS and
## at least TRADER_CLEAR from `avoid` (Tilly's stall, INF = none). With no good spot, it still comes.
static func totem_spot(world_seed: int, spawn: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable, avoid: Vector3 = Vector3.INF) -> Dictionary:
	var start := absi(world_seed * 19349663 ^ 83492791) % ANGLE_STEPS
	for r in RADII:
		for i in ANGLE_STEPS:
			var c := _ring_cell(spawn, r, start + i)
			if _clear_of(c, avoid) and _good(c, height_at, ground_ok, tree_at):
				return _spot(c, spawn, height_at)
	for i in ANGLE_STEPS:
		var c := _ring_cell(spawn, TOTEM_DISTANCE, start + i)
		if _clear_of(c, avoid):
			return _spot(c, spawn, height_at)
	return _spot(_ring_cell(spawn, TOTEM_DISTANCE, start), spawn, height_at)


## The Totem in a real world: the generator's ground, never on beaches, rivers, sea or a cave mouth.
static func totem_for_world(world_seed: int, shape: MeadowsShape, spawn: Vector2i, avoid: Vector3 = Vector3.INF) -> Dictionary:
	var caves := CaveShape.new(world_seed)
	var ground_ok := func(x: int, z: int) -> bool:
		return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) and not caves.entrance_open(x, z)
	return totem_spot(world_seed, spawn, shape.height_at, ground_ok, shape.tree_at, avoid)


## Every world (Survivor and Sandbox) gets its Totem the first time, saved in `meta` from then on so
## it never moves; placed after Tilly's stall so it keeps clear of her. Returns true (it has one).
static func place_in(meta: WorldMeta, shape: MeadowsShape, spawn: Vector2i) -> bool:
	if not meta.has_totem():
		var spot := totem_for_world(meta.seed, shape, spawn, meta.trader_pos)
		meta.totem_pos = spot.pos
		meta.totem_yaw = spot.yaw
	return true


## What the host's spawner sends everyone for the Totem (Totem.setup).
static func spawn_data(meta: WorldMeta) -> Dictionary:
	return {"pos": meta.totem_pos, "yaw": meta.totem_yaw}


static func _ring_cell(spawn: Vector2i, r: int, step: int) -> Vector2i:
	var a := TAU * (step % ANGLE_STEPS) / ANGLE_STEPS
	return spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))


static func _clear_of(c: Vector2i, avoid: Vector3) -> bool:
	return not avoid.is_finite() or Vector2(c.x + 0.5 - avoid.x, c.y + 0.5 - avoid.z).length() >= TRADER_CLEAR


## 3 x 3 flat, dry cells, and no trunk within CLEAR_RADIUS.
static func _good(c: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> bool:
	var h := int(height_at.call(c.x, c.y))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if int(height_at.call(c.x + dx, c.y + dz)) != h or not ground_ok.call(c.x + dx, c.y + dz):
				return false
	for dx in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
		for dz in range(-CLEAR_RADIUS, CLEAR_RADIUS + 1):
			if tree_at.call(c.x + dx, c.y + dz):
				return false
	return true


static func _spot(c: Vector2i, spawn: Vector2i, height_at: Callable) -> Dictionary:
	var d := Vector2(spawn - c)
	return {"pos": Vector3(c.x + 0.5, float(height_at.call(c.x, c.y)), c.y + 0.5), "yaw": atan2(-d.x, -d.y)}


## The box around the Totem's pole that taps hit and reach is measured to.
static func tap_box(totem_pos: Vector3) -> AABB:
	return AABB(totem_pos - Vector3(HALF_WIDTH, 0, HALF_WIDTH), Vector3(HALF_WIDTH * 2.0, HEIGHT, HALF_WIDTH * 2.0))


## Is a player's eye within `reach` of the Totem's pole?
static func in_reach(eye: Vector3, totem_pos: Vector3, reach: float) -> bool:
	if not eye.is_finite():
		return false
	var box := tap_box(totem_pos)
	return eye.distance_to(eye.clamp(box.position, box.end)) <= reach


## How far along a tap ray (from, unit dir) the Totem's pole is, or -1 if it misses.
static func ray_hit(from: Vector3, dir: Vector3, totem_pos: Vector3) -> float:
	var box := tap_box(totem_pos)
	var t_near := -INF
	var t_far := INF
	for axis in 3:
		if absf(dir[axis]) < 0.000001:
			if from[axis] < box.position[axis] or from[axis] > box.end[axis]:
				return -1.0
			continue
		var t1 := (box.position[axis] - from[axis]) / dir[axis]
		var t2 := (box.end[axis] - from[axis]) / dir[axis]
		t_near = maxf(t_near, minf(t1, t2))
		t_far = minf(t_far, maxf(t1, t2))
	if t_near > t_far or t_far < 0.0:
		return -1.0
	return maxf(t_near, 0.0)


# --- Words ------------------------------------------------------------------------------------------

## The HUD's wave line (top-centre).
static func line(wave: int, left: int) -> String:
	return Lang.t("Wave %d — %d left") % [wave, left]


static func countdown_line(wave: int, seconds: int) -> String:
	return Lang.t("Wave %d starts in %d…") % [wave, seconds]


static func won_message(wave: int, gold: int) -> String:
	return Lang.t("Wave %d won! +%d gold") % [wave, gold] if gold > 0 else Lang.t("Wave %d won!") % wave


## A won wave, for a player who was knocked out during it (no gold for them).
static func no_gold_message(wave: int) -> String:
	return Lang.t("Wave %d won! Stay on your feet to earn gold.") % wave


static func lost_message(result: StringName) -> String:
	if result == KNOCKED_OUT:
		return "Ouch! The monsters went home. Try again at the Totem!"
	return "Time's up! The monsters went home. Try again at the Totem!"


static func refusal_message(key: StringName, boss_name: String = "Stone Golem") -> String:
	return str(REFUSALS.get(key, "")).replace("Stone Golem", boss_name)   # M3 Task 2: each universe's boss


## The Totem's boss button (M3 Task 2: each universe's boss).
static func boss_word(boss_name: String) -> String:
	return Lang.t("The %s!") % boss_name
