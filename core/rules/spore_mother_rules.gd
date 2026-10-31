class_name SporeMotherRules
extends RefCounted
## The Spore Mother, the Glow Caves' boss (universe 6, spec §5.1; brief docs/superpowers/plans/2026-10-01-glow-caves-
## brief.md), as pure rules: a giant glowing mushroom with a kind, sleepy face, in a domed cavern arena. To the
## BossDirector she is a StoneGolem (the same fight, bar, honest help, gold and portal). An enum state machine with a
## fixed rhythm (children learn it): RISE, then SWAY (she shuffles towards the nearest child) before each attack in
## ORDER, every attack signalled for a second or more, and after each her gills glow open (GILLS_OPEN: her weak spot,
## double damage):
## - SPORES: her cap glows and swells (SPORE_WARN) while rings show on the ground at each child's feet and a few round
##   her; the clouds land there: 1 HP and a slow (SLOW for SLOW_TIME) to whoever is still in a ring (a step out dodges
##   it); they linger CLOUD_LINGER (walking into one slows, never hurts).
## - RING: she spins with her rim glowing (RING_WARN), then a ring of spores rolls out along the ground: 2 HP to
##   whoever stands on the ground within RING_RADIUS (a jump clears it).
## - PUFF: she squats (PUFF_WARN), then hides in a big glittering puff (HIDDEN: weapons go through the glitter) and
##   glides PUFF_MOVE to a new spot; out of the puff her gills are open.
## Health by team size like the Golem's (BASE_HP × (1 + 0.5 per extra player or bot friend)); she never changes a block.

const BASE_HP := 460
const SPORES := &"spores"
const RING := &"ring"
const PUFF := &"puff"
const ORDER: Array[StringName] = [SPORES, RING, PUFF]
const DAMAGE := {SPORES: 1, RING: 2, PUFF: 0}

enum Phase { RISE, SWAY, SPORE_WARN, RING_WARN, PUFF_WARN, HIDDEN, GILLS_OPEN, DOWN }

const RISE_TIME := 2.0
const SWAY_TIME := 2.2
const SPORE_WINDUP := 1.4
const RING_WINDUP := 1.2
const PUFF_WINDUP := 0.9
const HIDDEN_TIME := 3.0
const GILLS_TIME := 2.6
const GILLS_FACTOR := 2
const CLOUDS := 4                 # spore clouds per volley: one on each child's feet first, the rest round her
const CLOUD_R := 1.6              # a cloud's ring (flat)
const CLOUD_HEIGHT := 2.5         # ... and how high it reaches
const CLOUD_ROUND := 5.0          # the spare clouds land this far round her
const CLOUD_LINGER := 4.0         # seconds a landed cloud lingers
const SLOW := 0.5                 # a slowed child walks at this share of their speed ...
const SLOW_TIME := 3.0            # ... for this long
const RING_RADIUS := 7.0
const RING_HEIGHT := 2.0
const PUFF_MOVE := 6.0
const ARENA_REACH := 14.0         # she and her clouds stay this close to the arena's middle (the Totem)

const NAME := "Spore Mother"
const TITLE := "SPORE MOTHER"
const TIRED_TITLE := "SLEEPY SPORE MOTHER"
const WIN_MESSAGE := "You beat the Spore Mother!"
const TIRED_MESSAGE := "The Spore Mother is sleepy today: she has less health!"
const SUMMON_LINE := "%s woke the Spore Mother! Step out of the glowing rings and hit her gills!"


static func max_hp(team: int, tired: bool = false) -> int:
	var hp := BASE_HP * (1.0 + BossRules.TEAM_SHARE * (maxi(team, 1) - 1))
	return roundi(hp * BossRules.TIRED_SHARE) if tired else roundi(hp)


static func attack_at(step: int) -> StringName:
	return ORDER[posmod(step, ORDER.size())]


static func damage(attack: StringName) -> int:
	return int(DAMAGE.get(attack, 0))


static func phase_time(phase: int) -> float:
	match phase:
		Phase.RISE:
			return RISE_TIME
		Phase.SWAY:
			return SWAY_TIME
		Phase.SPORE_WARN:
			return SPORE_WINDUP
		Phase.RING_WARN:
			return RING_WINDUP
		Phase.PUFF_WARN:
			return PUFF_WINDUP
		Phase.HIDDEN:
			return HIDDEN_TIME
		Phase.GILLS_OPEN:
			return GILLS_TIME
	return INF


## What comes after `phase`; `step` is the number of the next attack (for the warning after a sway). The clouds land
## as SPORE_WARN ends, the ring rolls as RING_WARN ends.
static func next_phase(phase: int, step: int) -> int:
	match phase:
		Phase.RISE, Phase.GILLS_OPEN:
			return Phase.SWAY
		Phase.SWAY:
			match attack_at(step):
				SPORES:
					return Phase.SPORE_WARN
				RING:
					return Phase.RING_WARN
			return Phase.PUFF_WARN
		Phase.SPORE_WARN, Phase.RING_WARN, Phase.HIDDEN:
			return Phase.GILLS_OPEN
		Phase.PUFF_WARN:
			return Phase.HIDDEN
	return Phase.DOWN


static func is_warning(phase: int) -> bool:
	return phase in [Phase.SPORE_WARN, Phase.RING_WARN, Phase.PUFF_WARN]


## Weapons reach her (not while she rises, hides in her puff or is down).
static func hittable(phase: int) -> bool:
	return not phase in [Phase.RISE, Phase.HIDDEN, Phase.DOWN]


static func gills_open(phase: int) -> bool:
	return phase == Phase.GILLS_OPEN


static func hit_taken(amount: int, phase: int) -> int:
	return maxi(amount, 0) * (GILLS_FACTOR if gills_open(phase) else 1)


# Targets are [{pos: feet, grounded: bool}], as in BossRules; results are their indexes.

## Where a volley's CLOUDS land (shown as rings when the warning starts): each child's feet first (where they stand
## then: a step out dodges it), then spots CLOUD_ROUND round her, turned by `step`; all within ARENA_REACH of
## `middle` (a child further out: the ring at the arena's edge on their side).
static func cloud_spots(middle: Vector3, feet: Array[Vector3], step: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for f in feet:
		if out.size() >= CLOUDS:
			break
		out.append(_inside(middle, f))
	var k := 0
	while out.size() < CLOUDS:
		var a := TAU * (k + 0.37 * step) / float(CLOUDS)
		out.append(_inside(middle, middle + Vector3(cos(a), 0.0, sin(a)) * CLOUD_ROUND))
		k += 1
	return out


static func _inside(middle: Vector3, p: Vector3) -> Vector3:
	var flat := Vector2(p.x - middle.x, p.z - middle.z)
	if flat.length() <= ARENA_REACH:
		return p
	flat = flat.normalized() * ARENA_REACH
	return Vector3(middle.x + flat.x, p.y, middle.z + flat.y)


## Does a cloud landing at `spot` reach a child whose feet are at `feet`?
static func cloud_hits(spot: Vector3, feet: Vector3) -> bool:
	return Vector2(feet.x - spot.x, feet.z - spot.z).length() <= CLOUD_R and feet.y - spot.y >= -1.0 \
		and feet.y - spot.y <= CLOUD_HEIGHT


## Is `feet` inside one of the lingering clouds ([[spot, seconds left]])? A faded one (0 left) slows nobody.
static func in_cloud(feet: Vector3, clouds: Array) -> bool:
	for c: Array in clouds:
		if float(c[1]) > 0.0 and cloud_hits(c[0], feet):
			return true
	return false


## The spore ring from `center` (her feet): everyone standing on the ground within RING_RADIUS.
static func ring_hits(center: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		if bool(targets[i].grounded) and Vector2(p.x - center.x, p.z - center.z).length() <= RING_RADIUS \
				and absf(p.y - center.y) <= RING_HEIGHT:
			out.append(i)
	return out


## Where her puff carries her from `from`: PUFF_MOVE away, round the arena's `middle` (a turn by `step`), never out of
## ARENA_REACH.
static func puff_spot(from: Vector3, middle: Vector3, step: int) -> Vector3:
	var away := Vector2(from.x - middle.x, from.z - middle.z)
	var base := away.angle() if away.length() > 0.01 else 0.0
	for k in 8:
		var a := base + PI * 0.5 + (step + k) * 2.4
		var to := from + Vector3(cos(a), 0.0, sin(a)) * PUFF_MOVE
		if Vector2(to.x - middle.x, to.z - middle.z).length() <= ARENA_REACH:
			return to
	var back := Vector3(middle.x - from.x, 0.0, middle.z - from.z).normalized() * PUFF_MOVE
	return from + back
