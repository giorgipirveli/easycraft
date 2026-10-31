class_name SerpentRules
extends RefCounted
## The Sand Serpent, the Sandstorm Desert's boss (M3 Task 2, spec §14.1 "dives through sand, surfaces
## with signalled bursts"), as pure rules. It rises from the sand, then in a fixed order children can learn:
## - DIVE: under the sand it swims towards the nearest child (slower than a child walks); nobody can hit
##   it, but a mound of sand and a rumble show where it is;
## - WARN: the sand shakes in a ring where the child stood (1.4 s: time to step away);
## - BURST: it bursts out there: 4 HP to whoever is still within BURST_RADIUS;
## - UP: out of the sand: now it can be hit; then, in turn, a TAIL SWEEP (it rears and rattles its tail for
##   1.1 s, then the tail sweeps a ring of SWEEP_RADIUS along the ground: 4 HP, jump over it) after which it
##   is DIZZY for 2 s (double damage), or a SAND BALL (head back for 1 s, then a ball of sand flies to where
##   its target stands, the Golem's rock arc: 3 HP there), and back under the sand.
## Health by team size like the Golem's (BossRules.TEAM_SHARE, TIRED_SHARE); the honest help, gold, portal
## and the end of a fight are the Golem's (BossRules, BossDirector).

const BASE_HP := 360
const BURST := &"burst"
const SWEEP := &"sweep"
const SPIT := &"spit"
const DAMAGE := {BURST: 4, SWEEP: 4, SPIT: 3}

enum Phase { RISE, DIVE, WARN, BURST, UP, SWEEP_WARN, DIZZY, SPIT_WARN, DOWN }

const RISE_TIME := 2.0
const DIVE_TIME := 2.6
const WARN_TIME := 1.4
const BURST_TIME := 0.35
const UP_TIME := 1.6
const SWEEP_WINDUP := 1.1
const DIZZY_TIME := 2.0
const SPIT_WINDUP := 1.0
const DIVE_SPEED := 4.5           # m/s under the sand: a walking child (6) gets away
const ROAM := 24.0                # it never swims further than this from where it rose
const BURST_RADIUS := 2.5
const BURST_HEIGHT := 3.0
const SWEEP_RADIUS := 5.5
const SWEEP_HEIGHT := 2.0
const DIZZY_FACTOR := 2

const NAME := "Sand Serpent"
const TITLE := "SAND SERPENT"
const TIRED_TITLE := "TIRED SERPENT"
const WIN_MESSAGE := "You beat the Sand Serpent!"
const TIRED_MESSAGE := "The Sand Serpent is tired today: it has less health!"
const SUMMON_LINE := "%s woke the Sand Serpent! Watch the sand!"


static func max_hp(team: int, tired: bool = false) -> int:
	var hp := BASE_HP * (1.0 + BossRules.TEAM_SHARE * (maxi(team, 1) - 1))
	return roundi(hp * BossRules.TIRED_SHARE) if tired else roundi(hp)


static func damage(attack: StringName) -> int:
	return int(DAMAGE.get(attack, 0))


static func phase_time(phase: int) -> float:
	match phase:
		Phase.RISE:
			return RISE_TIME
		Phase.DIVE:
			return DIVE_TIME
		Phase.WARN:
			return WARN_TIME
		Phase.BURST:
			return BURST_TIME
		Phase.UP:
			return UP_TIME
		Phase.SWEEP_WARN:
			return SWEEP_WINDUP
		Phase.DIZZY:
			return DIZZY_TIME
		Phase.SPIT_WARN:
			return SPIT_WINDUP
	return INF


## What comes after `phase`; `turn` counts the times it has been up (even: the tail, odd: the sand ball).
## The sweep lands as SWEEP_WARN ends, the ball flies as SPIT_WARN ends, the burst as WARN ends.
static func next_phase(phase: int, turn: int) -> int:
	match phase:
		Phase.RISE, Phase.BURST:
			return Phase.UP
		Phase.DIVE:
			return Phase.WARN
		Phase.WARN:
			return Phase.BURST
		Phase.UP:
			return Phase.SWEEP_WARN if turn % 2 == 0 else Phase.SPIT_WARN
		Phase.SWEEP_WARN:
			return Phase.DIZZY
		Phase.DIZZY, Phase.SPIT_WARN:
			return Phase.DIVE
	return Phase.DOWN


static func is_warning(phase: int) -> bool:
	return phase in [Phase.WARN, Phase.SWEEP_WARN, Phase.SPIT_WARN]


## Out of the sand (not rising, not down): weapons reach it.
static func hittable(phase: int) -> bool:
	return phase in [Phase.BURST, Phase.UP, Phase.SWEEP_WARN, Phase.DIZZY, Phase.SPIT_WARN]


static func hit_taken(amount: int, dizzy: bool) -> int:
	return maxi(amount, 0) * (DIZZY_FACTOR if dizzy else 1)


## One step under the sand towards `to` (flat), never past it.
static func dive_step(from: Vector3, to: Vector3, delta: float) -> Vector3:
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	var step := DIVE_SPEED * maxf(delta, 0.0)
	if flat.length() <= step:
		return Vector3(to.x, from.y, to.z)
	return from + flat.normalized() * step


## Back inside ROAM of its lair.
static func keep_in_arena(pos: Vector3, home: Vector3) -> Vector3:
	var off := Vector2(pos.x - home.x, pos.z - home.z)
	if off.length() <= ROAM:
		return pos
	off = off.normalized() * ROAM
	return Vector3(home.x + off.x, pos.y, home.z + off.y)


# Targets are [{pos: feet, grounded: bool}], as in BossRules; results are their indexes.

## Out of the sand at `spot`: everyone within BURST_RADIUS (in the air too).
static func burst_hits(spot: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		if Vector2(p.x - spot.x, p.z - spot.z).length() <= BURST_RADIUS and absf(p.y - spot.y) <= BURST_HEIGHT:
			out.append(i)
	return out


## The tail sweeps the ground round it: everyone standing within SWEEP_RADIUS; a jump clears it.
static func sweep_hits(center: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		if bool(targets[i].grounded) and Vector2(p.x - center.x, p.z - center.z).length() <= SWEEP_RADIUS \
				and absf(p.y - center.y) <= SWEEP_HEIGHT:
			out.append(i)
	return out
