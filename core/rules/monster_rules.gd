class_name MonsterRules
extends RefCounted
## The monsters of Green Meadows as pure rules (M2 spec §12.4, §12.15): the stats table (slime: a
## jumper that splits at level 3 and up; goblin: a chaser with a club), universe scaling, level looks
## (bigger and a different colour per level, plus one spike or horn per level), night spawns (on the
## surface in the dark, 18-40 blocks from a player, never near a lantern or a home bed, caps), the
## level by distance from the world spawn, the sunrise puff, coins, and the simple sight rule that
## Task 5 (stealth) replaces. Sandbox monsters are gentle: at most 8, levels 1-2, no gold.

const SLIME := &"slime"
const GOBLIN := &"goblin"
const MUMMY := &"mummy"           # M3 Task 2 (Sandstorm Desert): a slow tank
const SCORPION := &"scorpion"     # M3 Task 2: a spitter
const YETI := &"yeti"             # M3 Task 3 (Frostpeak): a tank that throws snowballs
const ICE_BAT := &"bat"           # M3 Task 3: the flyer (/summon bat)
const GUMMY := &"gummy"           # M3 Task 4 (Candy Kingdom): a gummy bear, a jumper that bounces off walls
const SNEAKER := &"sneaker"       # M3 Task 4: a candy sneaker, invisible in the dark
const ARCHER := &"archer"         # M3 Task 14b: the goblin archer (build-fight practice; ArcherRules)
const SHADOW_BAT := &"shadow_bat" # owner #39 (Dragon Realm): a flyer that swoops (/summon shadowbat)
const WISP := &"wisp"             # owner #39: a floating light that throws a slow spark
const SPORE_PUFF := &"spore_puff" # universe 6 (Glow Caves): a puffball that hides in the dark and sees only light
const CRAWLER := &"crawler"       # universe 6: a blind cave beetle that hears (/summon crawler)
const KINDS: Array[StringName] = [SLIME, GOBLIN, MUMMY, SCORPION, YETI, ICE_BAT, GUMMY, SNEAKER, ARCHER, SHADOW_BAT, WISP,
	SPORE_PUFF, CRAWLER]
## Each universe's night monsters (the first is three in five of them; UniverseRegistry.monster_kinds).
const MEADOWS_KINDS: Array[StringName] = [SLIME, GOBLIN]
const DESERT_KINDS: Array[StringName] = [MUMMY, SCORPION]
const FROST_KINDS: Array[StringName] = [YETI, ICE_BAT]
const CANDY_KINDS: Array[StringName] = [GUMMY, SNEAKER]
const DRAGON_KINDS: Array[StringName] = [SHADOW_BAT, WISP]   # owner #39: the Dragon Realm (universe 5)
const GLOW_KINDS: Array[StringName] = [SPORE_PUFF, CRAWLER]   # universe 6: the Glow Caves
const JUMPER := &"jumper"
const CHASER := &"chaser"
const TANK := &"tank"
const SPITTER := &"spitter"
const FLYER := &"flyer"
const SNEAKS := &"sneaker"        # M3 Task 4: §5.2's sneaker behaviour (unseen in the dark)
const SHOOTER := &"shooter"       # M3 Task 14b: shoots arrows from cover
const MAX_LEVEL := 5

## Walking and chasing (m/s) and how each kind sounds. Goblins chase at CHASE_SPEED plus
## SPEED_PER_LEVEL a level (slower than a walking player, 6 m/s); slimes hop at HOP_SPEED.
const KIND := {
	SLIME: {"behaviour": JUMPER, "wander": 1.6, "speed": 2.8, "size": Vector3(0.75, 0.6, 0.75), "sound": &"squish"},
	GOBLIN: {"behaviour": CHASER, "wander": 1.4, "speed": 3.4, "size": Vector3(0.5, 1.3, 0.45), "sound": &"growl"},
	MUMMY: {"behaviour": TANK, "wander": 1.0, "speed": 2.2, "size": Vector3(0.6, 1.5, 0.5), "sound": &"moan"},
	SCORPION: {"behaviour": SPITTER, "wander": 1.4, "speed": 3.0, "size": Vector3(0.8, 0.5, 1.0), "sound": &"hiss"},
	YETI: {"behaviour": TANK, "wander": 0.9, "speed": 1.9, "size": Vector3(0.9, 1.8, 0.7), "sound": &"yeti_roar"},
	ICE_BAT: {"behaviour": FLYER, "wander": 2.2, "speed": 4.0, "size": Vector3(0.7, 0.35, 0.45), "sound": &"screech"},
	GUMMY: {"behaviour": JUMPER, "wander": 1.6, "speed": 3.2, "size": Vector3(0.6, 0.8, 0.5), "sound": &"gummy"},
	SNEAKER: {"behaviour": SNEAKS, "wander": 1.2, "speed": 3.0, "size": Vector3(0.55, 1.2, 0.45), "sound": &"jingle"},
	ARCHER: {"behaviour": SHOOTER, "wander": 1.4, "speed": 3.2, "size": Vector3(0.5, 1.3, 0.45), "sound": &"growl"},
	SHADOW_BAT: {"behaviour": FLYER, "wander": 2.0, "speed": 3.8, "size": Vector3(0.7, 0.35, 0.45), "sound": &"shadow_squeak"},
	WISP: {"behaviour": FLYER, "wander": 1.2, "speed": 2.6, "size": Vector3(0.5, 0.55, 0.5), "sound": &"wisp_chime"},
	SPORE_PUFF: {"behaviour": SNEAKS, "wander": 1.0, "speed": 2.6, "size": Vector3(0.7, 0.75, 0.7), "sound": &"spore_puff"},
	CRAWLER: {"behaviour": CHASER, "wander": 1.3, "speed": 3.0, "size": Vector3(0.8, 0.45, 1.0), "sound": &"crawler_click"},
}
const SPEED_PER_LEVEL := 0.2
const SLIME_SHARE := 0.6          # night spawns: 60% slimes, 40% goblins

## Level looks: size grows, and the colour is one of the Okabe-Ito colours (told apart with every
## common kind of colour blindness); the number of spikes or horns is the level.
const LEVEL_COLORS: Array[Color] = [Color("009e73"), Color("56b4e9"), Color("f0e442"), Color("e69f00"), Color("d55e00")]
const SPLIT_COUNT := 2
const SPLIT_LEVEL := 1

# Night spawns (§12.4) and Sandbox limits (§12.15).
const SPAWN_MIN := 18.0
const SPAWN_MAX := 40.0
const LIGHT_CLEAR := 8.0          # no spawn this close to a lantern (or a light block)
const HOME_CLEAR := 8.0           # ... or to a bed that is someone's home
## Blocks that make a spot bright: lanterns (§12.4) and the light block (ruling: "in the dark").
const LIGHT_BLOCKS: Array[int] = [BlockIds.LANTERN, BlockIds.LIGHT, BlockIds.SPORE_LAMP]   # universe 6: the spore lamp
const MAX_TOTAL := 20
const MAX_PER_PLAYER := 10
const GENTLE_MAX := 8
const GENTLE_MAX_LEVEL := 2
const LEVEL_STEP := 150.0         # one level per 150 blocks from the world spawn
const NEAR_PLAYER := 48.0         # monsters this close to a player count as that player's
## Only monsters this close to a player are simulated (the animals' cost rule).
const ACTIVE_DISTANCE := AnimalRules.ACTIVE_DISTANCE
const DESPAWN_DISTANCE := 64.0

# Coins (§12.4).
const MAX_COINS_PER_DEFEAT := 5
const COIN_PICKUP := 2.0

# Sight and attacks.
const SIGHT := 16.0               # blocks (§12.5 without the stealth factors)
const VIEW_ANGLE := 120.0         # degrees, centred on where the monster faces
const NOTICE := 3.0               # a player this close is noticed from any side
const MEMORY := 5.0               # seconds a monster keeps chasing a player it lost sight of
const GIVE_UP := 28.0             # ... and never beyond this distance
const GOBLIN_WINDUP := 0.8        # the club goes up this long before it swings (§12.4)
const ATTACK_RANGE := 1.6         # a goblin starts its wind-up this close (horizontal)
const STRIKE_REACH := 2.4         # the swing lands if the player is still this close
const ATTACK_COOLDOWN := 1.4
const TOUCH_COOLDOWN := 1.2       # a slime hurts on touch, then waits this long
const MAX_RISE := 2.0             # attacks reach this far up or down
const MAX_DROP := 3               # a monster never steps down more than this


static func level_of(level: int) -> int:
	return clampi(level, 1, MAX_LEVEL)


## Gold, monster health and hits in universe u are multiplied by 2^(u-1) (spec §5.1).
static func universe_scale(universe: int) -> int:
	return UniverseRules.scale(universe)   # the ladder's one rule (M3 Task 5)


## Health: [at level 1, more per level] by kind (M3 Task 2: the mummy is a tank). A mummy's half (M3
## Task 2) has half a level-1 mummy's.
const HP_TABLE := {SLIME: [4, 3], GOBLIN: [6, 4], MUMMY: [10, 5], SCORPION: [5, 3], YETI: [14, 7], ICE_BAT: [3, 2],
	GUMMY: [5, 3], SNEAKER: [6, 3],
	ARCHER: [5, 3],   # M3 Task 14b: weaker than a goblin up close
	SHADOW_BAT: [3, 2], WISP: [4, 2],   # owner #39
	SPORE_PUFF: [5, 3], CRAWLER: [6, 3]}   # universe 6
const GOLD_PER_LEVEL := {SLIME: 2, GOBLIN: 3, MUMMY: 4, SCORPION: 3, YETI: 5, ICE_BAT: 3, GUMMY: 2, SNEAKER: 4, ARCHER: 3,
	SHADOW_BAT: 3, WISP: 3, SPORE_PUFF: 3, CRAWLER: 3}


static func hp(kind: StringName, level: int, universe: int = 1, half: int = 0) -> int:
	var t: Array = HP_TABLE.get(kind, HP_TABLE[SLIME])
	var base: int = t[0] + t[1] * (level_of(level) - 1)
	if half != WHOLE:
		base = maxi(int(t[0]) / 2, 1)
	return base * universe_scale(universe)


## Slimes, scorpions, ice bats, gummy bears, archers, shadow bats and wisps nip (1 + l/2); goblins, mummies, yetis
## and sneakers hit hard (2 + (l-1)).
static func hit(kind: StringName, level: int, universe: int = 1) -> int:
	var l := level_of(level)
	var base := 1 + l / 2 if kind == SLIME or kind == SCORPION or kind == ICE_BAT or kind == GUMMY or kind == ARCHER \
		or kind == SHADOW_BAT or kind == WISP or kind == SPORE_PUFF or kind == CRAWLER else 2 + (l - 1)
	return base * universe_scale(universe)


static func gold(kind: StringName, level: int, universe: int = 1, half: int = 0) -> int:
	var per: int = GOLD_PER_LEVEL.get(kind, 2)
	var base := per / 2 if half != WHOLE else per * level_of(level)
	return base * universe_scale(universe)


static func behaviour(kind: StringName) -> StringName:
	return KIND.get(kind, KIND[SLIME]).behaviour


## Chasing (goblin) or hopping (slime) speed at a level; a mummy's half is lighter, so faster.
static func speed(kind: StringName, level: int, half: int = 0) -> float:
	var v := float(KIND.get(kind, KIND[SLIME]).speed) + SPEED_PER_LEVEL * (level_of(level) - 1)
	return v + HALF_SPEED if half != WHOLE else v


static func size_scale(level: int) -> float:
	return 0.8 + 0.15 * (level_of(level) - 1)


static func level_color(level: int) -> Color:
	return LEVEL_COLORS[level_of(level) - 1]


## The box a monster of this kind and level fills (x, y, z blocks); a mummy's half is shorter.
static func size_of(kind: StringName, level: int, half: int = 0) -> Vector3:
	var v := (KIND.get(kind, KIND[SLIME]).size as Vector3) * size_scale(level)
	match half:
		HALF_TOP:
			return v * Vector3(1.0, 0.42, 1.2)    # the top half crawls on its hands
		HALF_LEGS:
			return v * Vector3(0.85, 0.5, 0.8)
	return v


## Big slimes split and big mummies unwrap (M3 Task 2) when defeated; their small ones never do again.
static func splits(kind: StringName, level: int, half: int = 0) -> bool:
	return (kind == SLIME or kind == MUMMY) and level >= 3 and half == WHOLE


# --- M3 Task 2: the desert's monsters (mummy halves, wind-ups, the scorpion's spit) -----------------

## A whole monster, or one of a mummy's two halves (its crawling top, its walking legs).
const WHOLE := 0
const HALF_TOP := 1
const HALF_LEGS := 2
const HALF_SPEED := 1.0           # a half is lighter: this much faster
const MUMMY_WINDUP := 1.1         # the slow grab: arms up this long
const SCORPION_WINDUP := 0.9      # the tail goes up and glows this long before the spit
const MUMMY_PUSH := 0.35          # a tank: weapons push it this much

## What a split leaves: two small slimes, or a mummy's top and legs.
static func halves(kind: StringName) -> Array[int]:
	var out: Array[int] = [WHOLE, WHOLE]
	if kind == MUMMY:
		out = [HALF_TOP, HALF_LEGS]
	return out


## How long its attack is signalled before it lands (0: none, a slime just bumps).
static func windup(kind: StringName) -> float:
	match kind:
		GOBLIN:
			return GOBLIN_WINDUP
		MUMMY:
			return MUMMY_WINDUP
		SCORPION:
			return SCORPION_WINDUP
		YETI:
			return YETI_WINDUP
		ICE_BAT:
			return BAT_WINDUP
		SNEAKER:
			return SNEAKER_WINDUP   # M3 Task 4
		ARCHER:
			return ArcherRules.WINDUP   # M3 Task 14b: the bow is drawn, the arrow glows, a second before it flies
		SHADOW_BAT:
			return SHADOW_WINDUP        # owner #39: wings flare, eyes brighten, a squeak
		WISP:
			return WISP_WINDUP          # owner #39: it brightens, chimes and grows a ring
		SPORE_PUFF:
			return PUFF_WINDUP          # universe 6: it swells up, its spots glow
		CRAWLER:
			return CRAWLER_WINDUP       # universe 6: its feelers go up and it clicks
	return 0.0


static func winds_up(kind: StringName) -> bool:
	return windup(kind) > 0.0


## How much of a weapon's push it takes.
static func push_scale(kind: StringName) -> float:
	match kind:
		MUMMY:
			return MUMMY_PUSH
		YETI:
			return YETI_PUSH
	return 1.0


const SPIT_RANGE := 10.0          # a scorpion spits at a target this close (flat) ...
const SPIT_RISE := 4.0            # ... and no more than this far up or down
const SPIT_KEEP := 5.0            # it stays about this far from its target
const SPIT_TOO_CLOSE := 3.0       # closer than this it backs off
const SPIT_SPEED := 9.0           # m/s along the ground: a child sees it coming
const SPIT_MIN_TIME := 0.5
const SPIT_MAX_TIME := 1.6
const SPIT_ARC := 1.2
const MAX_LEAD := 3.0             # it leads a runner by at most this many blocks
const SPIT_REACH := 1.0           # the glob hits within this of where it lands (flat) ...
const SPIT_HEIGHT := 1.5          # ... and this far up or down
const SPIT_COOLDOWN := 2.4


static func may_spit(from: Vector3, target: Vector3) -> bool:
	return _flat_between(from, target) <= SPIT_RANGE and absf(target.y - from.y) <= SPIT_RISE


## Where the glob should land to meet a child standing at `target` (feet) moving at `vel`: where they will
## be after the glob's flight (one refinement), at most MAX_LEAD ahead, on the ground they stand over.
static func spit_aim(from: Vector3, target: Vector3, vel: Vector3) -> Vector3:
	var flat := Vector3(vel.x, 0.0, vel.z)
	var p := target
	for i in 2:
		p = target + (flat * spit_time(from, p)).limit_length(MAX_LEAD)
	return Vector3(p.x, target.y, p.z)


static func spit_time(from: Vector3, to: Vector3) -> float:
	return clampf(_flat_between(from, to) / SPIT_SPEED, SPIT_MIN_TIME, SPIT_MAX_TIME)


## The glob at t = 0..1 of its flight: a straight line lifted by a small arc.
static func spit_point(from: Vector3, to: Vector3, t: float) -> Vector3:
	var k := clampf(t, 0.0, 1.0)
	if k >= 1.0:
		return to
	return from.lerp(to, k) + Vector3(0.0, (SPIT_ARC + _flat_between(from, to) * 0.08) * 4.0 * k * (1.0 - k), 0.0)


## Does the glob that landed at `landing` hit someone whose feet are at `feet`?
static func spit_hits(landing: Vector3, feet: Vector3) -> bool:
	return _flat_between(landing, feet) <= SPIT_REACH and absf(feet.y - landing.y) <= SPIT_HEIGHT


static func _flat_between(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- M3 Task 3: Frostpeak's yeti (snowballs) and ice bat (the flyer) --------------------------------

const YETI_WINDUP := 1.2          # a big snowball goes up over its head this long
const YETI_PUSH := 0.3            # a tank: weapons push it this much
const THROW_RANGE := 12.0         # it throws at a target this close (flat) ...
const THROW_MIN := 2.5            # ... and no closer: up close it smashes the snowball down instead
const THROW_RISE := 5.0           # ... and no more than this far up or down
const THROW_COOLDOWN := 3.0
const SNOWBALL_REACH := 1.5       # a big snowball splashes: it hits within this of where it lands
const HAND_HEIGHT := 2.1          # the snowball leaves its hands this high (× its size)
const BAT_WINDUP := 0.8           # hovering, flapping hard and screeching before a dive
const BAT_CRUISE := 3.5           # it flutters this high over the ground
const BAT_HOVER := 3.5            # ... and over the feet of a child it is after
const BAT_CIRCLE := 4.0           # ... this far to their side
const BAT_LOOK_DOWN := 12         # it looks this far down for the ground
const BAT_DIVE_AT := 0.9          # it dives at a child's chest
const BAT_DIVE_SPEED := 8.0
const BAT_DIVE_TIME := 1.2        # a dive lasts at most this long
const BAT_DIVE_REACH := 0.8       # the dive hits a child whose body is this close
const BAT_LOW_TIME := 1.4         # after a dive it flutters at head height this long (swords reach it)
const BAT_DIVE_COOLDOWN := 2.5
const BAT_ACCEL := 10.0
const BAT_PERCH_UP := 5           # a tired bat looks this far up for a ceiling or a branch
const BAT_FLY_TIME := Vector2(18.0, 30.0)   # it flies this long before it rests ...
const BAT_REST_TIME := Vector2(6.0, 10.0)   # ... and hangs this long


static func may_throw(from: Vector3, target: Vector3) -> bool:
	var d := _flat_between(from, target)
	return d >= THROW_MIN and d <= THROW_RANGE and absf(target.y - from.y) <= THROW_RISE


## Where the yeti's snowball should land for a child at `feet` moving at `vel`, thrown from its hands at
## `from`: where they will be (the scorpion's lead, spit_aim) when nothing is in the way; at their feet when
## only the lead is blocked; INF (no throw) when a wall stands between. is_solid(cell) -> bool.
static func throw_aim(from: Vector3, feet: Vector3, vel: Vector3, is_solid: Callable) -> Vector3:
	var aim := spit_aim(from, feet, vel)
	if clear_line(from, aim + Vector3(0, 0.5, 0), is_solid):
		return aim
	if clear_line(from, feet + Vector3(0, 0.5, 0), is_solid):
		return feet
	return Vector3.INF


## Does the snowball that landed at `landing` hit someone whose feet are at `feet`? Within SNOWBALL_REACH,
## and never through a wall.
static func snowball_hits(landing: Vector3, feet: Vector3, is_solid: Callable) -> bool:
	if _flat_between(landing, feet) > SNOWBALL_REACH or absf(feet.y - landing.y) > SPIT_HEIGHT:
		return false
	return clear_line(landing + Vector3(0, 0.5, 0), feet + Vector3(0, 0.5, 0), is_solid)


## No solid block on the straight line from `a` to `b` (the grid ray; `a`'s own cell is not looked at).
static func clear_line(a: Vector3, b: Vector3, is_solid: Callable) -> bool:
	var d := a.distance_to(b)
	return d < 0.001 or GridRay.cast(a, b - a, d, is_solid) == null


## The feet height of the ground under `pos` (the top of the first solid block within BAT_LOOK_DOWN), or
## BAT_LOOK_DOWN under it when there is none.
static func ground_below(pos: Vector3, is_solid: Callable) -> float:
	var c := Vector3i(pos.floor())
	for i in BAT_LOOK_DOWN + 1:
		if is_solid.call(c - Vector3i(0, i, 0)):
			return float(c.y - i + 1)
	return pos.y - BAT_LOOK_DOWN


## A flying bat's height over ground at `ground_y`.
static func cruise_y(ground_y: float) -> float:
	return ground_y + BAT_CRUISE


## Where a bat after a child whose feet are at `target` flies: BAT_HOVER over them, BAT_CIRCLE to the side it
## is on already.
static func hover_spot(target: Vector3, bat: Vector3) -> Vector3:
	var side := Vector2(bat.x - target.x, bat.z - target.z)
	side = side.normalized() if side.length() > 0.01 else Vector2(1, 0)
	return Vector3(target.x + side.x * BAT_CIRCLE, target.y + BAT_HOVER, target.z + side.y * BAT_CIRCLE)


## What a bat dives at: the chest of a child whose feet are at `feet` (where they stand as the dive
## starts: no lead, so a sidestep dodges it).
static func dive_aim(feet: Vector3) -> Vector3:
	return feet + Vector3(0, BAT_DIVE_AT, 0)


## Does a diving bat at `bat` touch a child whose feet are at `feet` (their body from the knees to the head)?
static func dive_hits(bat: Vector3, feet: Vector3) -> bool:
	var y := clampf(bat.y, feet.y + 0.2, feet.y + 1.6)
	return bat.distance_to(Vector3(feet.x, y, feet.z)) <= BAT_DIVE_REACH


## Where a tired bat of `height` hangs: under the first solid block within BAT_PERCH_UP above it (a ceiling
## or a branch), or INF in the open sky.
static func perch_spot(pos: Vector3, is_solid: Callable, height: float = 0.35 * 0.8) -> Vector3:
	var c := Vector3i(pos.floor())
	for i in range(1, BAT_PERCH_UP + 1):
		if is_solid.call(c + Vector3i(0, i, 0)):
			return Vector3(c.x + 0.5, c.y + i - height, c.z + 0.5)
	return Vector3.INF


# --- Night spawns ------------------------------------------------------------------------------

## Does this world get monsters by itself? Survivor always; Sandbox while its setting is ON.
static func spawns_enabled(mode: StringName, monsters_on: bool) -> bool:
	if not ModeRules.allows(mode, ModeRules.MONSTER_SPAWNS):
		return false
	return monsters_on or not ModeRules.allows(mode, ModeRules.GENTLE_MONSTERS)


## ... and right now (time of day t): only at night.
static func spawns_now(mode: StringName, monsters_on: bool, t: float) -> bool:
	return spawns_enabled(mode, monsters_on) and DayCycle.is_night(t)


static func cap_total(gentle: bool) -> int:
	return GENTLE_MAX if gentle else MAX_TOTAL


static func cap_per_player(gentle: bool) -> int:
	return mini(MAX_PER_PLAYER, cap_total(gentle))


## How many more may come for a player who has `near_player` near them, with `total` in the world.
static func spawn_budget(total: int, near_player: int, gentle: bool) -> int:
	return maxi(mini(cap_total(gentle) - total, cap_per_player(gentle) - near_player), 0)


## Level 1 + one per LEVEL_STEP blocks from the world spawn (max 5), changed by `roll` (-1, 0 or 1).
## Gentle (Sandbox) monsters are level 1 or 2.
static func level_for(distance_from_spawn: float, roll: int, gentle: bool) -> int:
	var base := mini(1 + floori(maxf(distance_from_spawn, 0.0) / LEVEL_STEP), MAX_LEVEL)
	var l := level_of(base + clampi(roll, -1, 1))
	return mini(l, GENTLE_MAX_LEVEL) if gentle else l


## A column on the ring around `center`: angle in radians, t 0..1 from SPAWN_MIN to SPAWN_MAX.
## Returns (x, z).
static func ring_spot(center: Vector3, angle: float, t: float) -> Vector2:
	var d := lerpf(SPAWN_MIN, SPAWN_MAX, clampf(t, 0.0, 1.0))
	return Vector2(center.x + cos(angle) * d, center.z + sin(angle) * d)


## Why a monster may not appear at `pos` (&"" = it may): too close to a player (&"too_close"), no
## player within SPAWN_MAX (&"too_far"), near a light (&"light") or near a home bed (&"home").
static func spot_refusal(pos: Vector3, players: Array[Vector3], lights: Array[Vector3i], homes: Array[Vector3i]) -> StringName:
	var near := false
	for p in players:
		var d := Vector2(p.x - pos.x, p.z - pos.z).length()
		if d < SPAWN_MIN:
			return &"too_close"
		if d <= SPAWN_MAX:
			near = true
	if not near:
		return &"too_far"
	for l in lights:
		if (Vector3(l) + Vector3(0.5, 0.5, 0.5)).distance_to(pos) <= LIGHT_CLEAR:
			return &"light"
	for h in homes:
		if (Vector3(h) + Vector3(0.5, 0.5, 0.5)).distance_to(pos) <= HOME_CLEAR:
			return &"home"
	return &""


## The kind of a night monster: the universe's first kind three times in five (M3 Task 2: `kinds`).
static func pick_kind(roll: float, kinds: Array[StringName] = MEADOWS_KINDS) -> StringName:
	if kinds.size() < 2:
		return SLIME if roll < SLIME_SHARE else GOBLIN
	return kinds[0] if roll < SLIME_SHARE else kinds[1]


## Where a monster stands on the surface of column (x, z): the first cell from start_y up with room
## for a 2-block body, on solid ground that is not leaves. Vector3.INF on water, tree tops or when
## there is no room below max_y. block_at(pos: Vector3i) -> int.
static func surface_spot(x: int, z: int, start_y: int, block_at: Callable, max_y: int) -> Vector3:
	var y := SpawnRules.first_free_y(start_y, func(yy: int) -> bool: return BlockIds.is_solid(block_at.call(Vector3i(x, yy, z))), max_y)
	if y >= max_y:
		return Vector3.INF
	var below: int = block_at.call(Vector3i(x, y - 1, z))
	if not BlockIds.is_solid(below) or below == BlockIds.LEAVES or block_at.call(Vector3i(x, y, z)) == BlockIds.WATER:
		return Vector3.INF
	return Vector3(x + 0.5, y, z + 0.5)


# --- Activity, leaving, the sunrise puff ----------------------------------------------------------

static func is_active(pos: Vector3, players: Array[Vector3]) -> bool:
	return _nearest(pos, players) <= ACTIVE_DISTANCE


static func should_despawn(pos: Vector3, players: Array[Vector3]) -> bool:
	return not players.is_empty() and _nearest(pos, players) > DESPAWN_DISTANCE   # nobody around for a moment (a knock-out): stay


## Wild monsters puff away once the sun is up (no gold); summoned (and wave) monsters stay.
static func puffs(t: float, wild: bool) -> bool:
	return wild and not DayCycle.is_night(t)


static func _nearest(pos: Vector3, players: Array[Vector3]) -> float:
	var best := INF
	for p in players:
		best = minf(best, Vector2(p.x - pos.x, p.z - pos.z).length())
	return best


# --- Coins ---------------------------------------------------------------------------------------

## The coins a defeat drops for `amount` gold: at most MAX_COINS_PER_DEFEAT, nearly equal, adding up.
static func coin_values(amount: int) -> Array[int]:
	var out: Array[int] = []
	if amount <= 0:
		return out
	var count := mini(amount, MAX_COINS_PER_DEFEAT)
	for i in count:
		out.append(amount / count + (1 if i < amount % count else 0))
	return out


## Index of the player a coin at `coin` flies to: the nearest within COIN_PICKUP, or -1.
static func collector(coin: Vector3, players: Array[Vector3]) -> int:
	var best := -1
	var best_d := COIN_PICKUP
	for i in players.size():
		var d := players[i].distance_to(coin)
		if d <= best_d:
			best_d = d
			best = i
	return best


# --- Sight and moving ----------------------------------------------------------------------------

## Does a monster whose eyes are at `eye`, facing `facing`, see `target`? Within SIGHT, inside its
## VIEW_ANGLE (a player within NOTICE is noticed from any side) and with a clear line through the
## blocks (grid ray). is_solid(cell: Vector3i) -> bool. Task 5 (stealth) scales SIGHT by visibility.
static func can_see(eye: Vector3, facing: Vector3, target: Vector3, is_solid: Callable, sight: float = SIGHT) -> bool:
	var to := target - eye
	var dist := to.length()
	if dist > sight:
		return false
	if dist > NOTICE:
		var look := Vector2(facing.x, facing.z)
		var flat := Vector2(to.x, to.z)
		if look.length() > 0.001 and flat.length() > 0.001 and rad_to_deg(absf(look.angle_to(flat))) > VIEW_ANGLE * 0.5:
			return false
	if dist < 0.001:
		return true
	var hit := GridRay.cast(eye, to, dist, is_solid)
	return hit == null or hit.position == Vector3i(target.floor())


## May a monster step into cell `target` (its feet)? Never into water, never down more than MAX_DROP.
static func can_step(target: Vector3i, block_at: Callable) -> bool:
	if block_at.call(target) == BlockIds.WATER:
		return false
	for d in range(1, MAX_DROP + 2):
		var below: int = block_at.call(target - Vector3i(0, d, 0))
		if below == BlockIds.WATER:
			return false
		if below != BlockIds.AIR:
			return true
	return false


## Does a swing (or a slime's touch) from `from` reach a player standing at `to`?
static func strike_lands(from: Vector3, to: Vector3, reach: float) -> bool:
	return Vector2(to.x - from.x, to.z - from.z).length() <= reach and absf(to.y - from.y) <= MAX_RISE


# --- /summon -------------------------------------------------------------------------------------

const SUMMON_DISTANCE := 4        # a summoned monster appears this far away: a moment to get ready

## Where a summoned monster appears: standing on dry ground SUMMON_DISTANCE blocks from `near` (one of
## eight directions, starting at `start`), at the player's height or up to 2 blocks up or down; next
## to the player (AnimalRules.summon_spot) when there is no such place.
static func summon_spot(near: Vector3, block_at: Callable, start: int) -> Vector3:
	var feet := Vector3i(near.floor())
	var sides := AnimalRules.SUMMON_SIDES
	for i in sides.size():
		var side: Vector2i = sides[posmod(start + i, sides.size())]
		for dy in [0, 1, -1, 2, -2]:
			var cell := feet + Vector3i(side.x * SUMMON_DISTANCE, dy, side.y * SUMMON_DISTANCE)
			var below: int = block_at.call(cell + Vector3i.DOWN)
			if BlockIds.is_solid(below) and not BlockIds.is_solid(block_at.call(cell)) \
					and block_at.call(cell) != BlockIds.WATER and not BlockIds.is_solid(block_at.call(cell + Vector3i.UP)):
				return Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)
	return AnimalRules.summon_spot(near, block_at, posmod(start, sides.size()))


# --- M3 Task 4: the Candy Kingdom's gummy bear and candy sneaker ----------------------------------------

const SLIME_HOP_UP := 6.5         # m/s up: a slime's hop (Monster.HOP_UP), about a block high
const GUMMY_HOP_UP := 8.0         # a gummy bear hops higher
const BOUNCE_KEEP := 0.8          # off a wall a gummy bear keeps this share of its speed into it ...
const BOUNCE_UP := 2.5            # ... with at least this much hop up (m/s)
const BOUNCE_MAX := 8.0           # and never flies off faster than this (flat)
const WALL_MAX_Y := 0.3           # a surface whose normal points up more than this is a floor or a slope
const SNEAKER_WINDUP := 1.0       # the sneaker shimmers and jingles this long before its lollipop swings
const SNEAK_DARK := 0.5           # light (StealthRules) below this is dark: night outdoors, caves
const SHIMMER_NEAR := 6.0         # in the dark a sneaker shimmers when a player is this close
## How a sneaker shows on a screen (sneaker_look).
const SEEN := 0
const SHIMMER := 1
const HIDDEN := 2


## How fast a jumper hops up (m/s).
static func hop_up(kind: StringName) -> float:
	return GUMMY_HOP_UP if kind == GUMMY else SLIME_HOP_UP


## A gummy bear flying into a wall (its surface normal `normal`) bounces off it: the part of its flat speed
## into the wall turns round (BOUNCE_KEEP of it), the part along the wall stays, and it gets at least
## BOUNCE_UP of hop. Floors, slopes and walls it moves away from change nothing.
static func wall_bounce(velocity: Vector3, normal: Vector3) -> Vector3:
	if absf(normal.y) > WALL_MAX_Y:
		return velocity
	var n := Vector3(normal.x, 0.0, normal.z).normalized()
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var into := flat.dot(n)
	if into >= 0.0 or n == Vector3.ZERO:
		return velocity
	var out := (flat - n * into * (1.0 + BOUNCE_KEEP)).limit_length(BOUNCE_MAX)
	return Vector3(out.x, maxf(velocity.y, BOUNCE_UP), out.z)


## Is it dark where a sneaker stands (its light, StealthRules.light_level)?
static func sneaker_dark(light: float) -> bool:
	return light < SNEAK_DARK


## SEEN in the light; in the dark a SHIMMER within SHIMMER_NEAR of this screen's player, and always while it
## winds up (the fair signal before every attack); else HIDDEN.
static func sneaker_look(dark: bool, winding: bool, distance: float) -> int:
	if not dark:
		return SEEN
	if winding or distance <= SHIMMER_NEAR:
		return SHIMMER
	return HIDDEN

# --- Owner #39: the Dragon Realm's shadow bat and wisp spirit ------------------------------------------------
# Both fly (FLYER: no gravity, the ice bat's flight). The shadow bat swoops like the ice bat after a longer signal
# (wings flare, eyes brighten, a squeak), then flies up and away to rest. The wisp keeps its distance, brightens,
# chimes and grows a ring, then throws a slow spark in a straight line at the chest where the child stood (no
# lead): slower than a walking child, stopped by a wall. Over the void (nothing within BAT_LOOK_DOWN below) a
# flyer keeps its height and goes back to where there was ground; below VOID_Y over nothing it puffs away.

const SHADOW_WINDUP := 1.0        # the shadow bat's signal: longer than an ice bat's (it is hard to see in the dark)
const SHADOW_AWAY := 7.0          # after a swoop it flies this far from the child (flat) ...
const SHADOW_AWAY_UP := 5.0       # ... and this high over their feet ...
const SHADOW_REST := 3.0          # ... and rests there this long before it comes back
const WISP_WINDUP := 1.2          # the wisp brightens, chimes and grows its ring this long
const WISP_FLOAT := 2.5           # it drifts this high over the ground
const WISP_HOVER := 3.0           # ... and this high over the feet of a child it is after
const WISP_KEEP := 7.0            # ... this far from them (flat)
const WISP_TOO_CLOSE := 4.0       # a child closer than this: it drifts back first, and throws only from further
const WISP_RANGE := 11.0          # it throws at a chest this close (a straight line)
const SPARK_SPEED := 5.0          # m/s: slower than a walking child (Player.WALK_SPEED 6)
const SPARK_AT := 0.9             # it flies at the chest ...
const SPARK_REACH := 0.6          # ... and touches a body this close
const SPARK_COOLDOWN := 3.5
const FLY_BACK_OFF := 10.0        # a hurt Dragon Realm flyer backing off (its mind's tactic) goes this far (flat) ...
const FLY_BACK_UP := 5.0          # ... and this high
const VOID_Y := 0.0               # below this, over nothing, a flyer puffs away
## The sound of each flyer's signal (every screen plays it as the wind-up starts).
const WINDUP_SOUND := {ICE_BAT: &"screech", SHADOW_BAT: &"shadow_squeak", WISP: &"wisp_charge"}


## How high a flyer keeps over the ground while it wanders (a wisp floats lower than a bat).
static func cruise_height(kind: StringName) -> float:
	return WISP_FLOAT if kind == WISP else BAT_CRUISE


## The flat way from the child at `feet` towards `from`; +X when right over them.
static func _side_of(feet: Vector3, from: Vector3) -> Vector2:
	var side := Vector2(from.x - feet.x, from.z - feet.z)
	return side.normalized() if side.length() > 0.01 else Vector2(1, 0)


static func _spot_on_side(feet: Vector3, from: Vector3, flat: float, up: float) -> Vector3:
	var side := _side_of(feet, from)
	return Vector3(feet.x + side.x * flat, feet.y + up, feet.z + side.y * flat)


## Where a shadow bat rests after its swoop: SHADOW_AWAY from the child at `feet` on its own side, SHADOW_AWAY_UP up.
static func shadow_rest_spot(feet: Vector3, bat: Vector3) -> Vector3:
	return _spot_on_side(feet, bat, SHADOW_AWAY, SHADOW_AWAY_UP)


## Where a hurt Dragon Realm flyer backs off to (its mind's BACK_OFF): further and higher on its own side.
static func back_off_spot(feet: Vector3, flyer: Vector3) -> Vector3:
	return _spot_on_side(feet, flyer, FLY_BACK_OFF, FLY_BACK_UP)


## Where a wisp after a child at `feet` floats: WISP_KEEP away on its own side, WISP_HOVER above their feet.
static func wisp_spot(feet: Vector3, wisp: Vector3) -> Vector3:
	return _spot_on_side(feet, wisp, WISP_KEEP, WISP_HOVER)


## What a spark flies at: the chest of a child whose feet are at `feet` as it is thrown (no lead).
static func spark_aim(feet: Vector3) -> Vector3:
	return feet + Vector3(0, SPARK_AT, 0)


static func may_spark(from: Vector3, to: Vector3) -> bool:
	return from.distance_to(to) <= WISP_RANGE


## Seconds a spark takes from `from` to `to`.
static func spark_time(from: Vector3, to: Vector3) -> float:
	return maxf(from.distance_to(to) / SPARK_SPEED, 0.05)


## Where a spark is `age` seconds after it left `from`: a straight line to `to`, never past it.
static func spark_point(from: Vector3, to: Vector3, age: float) -> Vector3:
	return from.move_toward(to, maxf(age, 0.0) * SPARK_SPEED)


## Does a spark at `spark` touch a child whose feet are at `feet` (their body from the knees to the head)?
static func spark_hits(spark: Vector3, feet: Vector3) -> bool:
	var y := clampf(spark.y, feet.y + 0.2, feet.y + 1.6)
	return spark.distance_to(Vector3(feet.x, y, feet.z)) <= SPARK_REACH


## Nothing solid within BAT_LOOK_DOWN under `pos` (ground_below found no ground: it returned `ground`).
static func over_void(pos: Vector3, ground: float) -> bool:
	return ground <= pos.y - BAT_LOOK_DOWN + 0.01


## A flyer below VOID_Y with nothing under it is lost in the void: it puffs away.
static func lost_in_void(pos: Vector3, ground: float) -> bool:
	return pos.y < VOID_Y and over_void(pos, ground)

# --- Universe 6: the Glow Caves' spore puff and cave crawler --------------------------------------------------------
# The spore puff is a sneaker (SNEAKS: the candy sneaker's walk, swing and darkness) that sees only by light: the
# visibility meter. In the dark the child's own lantern shows it within PUFF_LIT, a shimmer within PUFF_SHIMMER (and
# always while it swells up). The cave crawler is a chaser that is blind: it never sees anybody; it hears a moving
# child within the noise's radius (StealthRules.move_noise: running far, walking near, a crouch-walk almost nothing)
# and feels one within FEEL: the noise meter. Both nip (1 + l/2) after a signal.

const PUFF_WINDUP := 1.0          # the puff swells up and its spots glow this long before it bumps
const CRAWLER_WINDUP := 0.9       # the crawler raises its feelers and clicks this long before it nips
const PUFF_LIT := 4.0             # in the dark a puff this close to this screen's player shows in its lantern ...
const PUFF_SHIMMER := 8.0         # ... and shimmers this close
const FEEL := 1.5                 # a blind crawler feels a child this close, quiet or not


## The kinds that come golden now and then at night (§12.16 #4: one in SurpriseRules.GOLDEN_SLIME_ONE_IN; it glows,
## runs from a child and, caught, gives a pile of gold): Green Meadows' slimes, the Glow Caves' spore puffs.
const GOLDEN_KINDS: Array[StringName] = [SLIME, SPORE_PUFF]


static func can_be_golden(kind: StringName) -> bool:
	return GOLDEN_KINDS.has(kind)


## The kinds that hide in the dark (only a shimmer near a child): the candy sneaker and the spore puff.
static func hides_in_dark(kind: StringName) -> bool:
	return kind == SNEAKER or kind == SPORE_PUFF


## The kinds that never see: they hear (and feel).
static func blind(kind: StringName) -> bool:
	return kind == CRAWLER


## How a monster that hides in the dark shows on a screen whose player is `distance` away: the candy sneaker's rule
## (sneaker_look), the spore puff's own (the child's lantern lights it close by).
static func dark_look(kind: StringName, dark: bool, winding: bool, distance: float) -> int:
	if kind != SPORE_PUFF:
		return sneaker_look(dark, winding, distance)
	if not dark or distance <= PUFF_LIT:
		return SEEN
	if winding or distance <= PUFF_SHIMMER:
		return SHIMMER
	return HIDDEN


## Does a blind monster find a child `distance` away whose moving makes `noise` (blocks it is heard; 0: still)? Heard
## within the noise's radius, felt within FEEL. A monster that is not blind never finds anybody this way.
static func heard_as_found(kind: StringName, distance: float, noise: float) -> bool:
	if not blind(kind):
		return false
	return distance <= FEEL or (noise > 0.0 and distance <= noise)
