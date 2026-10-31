class_name FrostGiantRules
extends RefCounted
## The Frost Giant, Frostpeak's boss (M3 Task 3, spec §14.1 "freezing stomp rings that make the ground icy;
## hide behind snow walls from his breath"), as pure rules. It climbs out of the snow, then walks towards the
## nearest child and attacks in a fixed order children can learn, a walk between, every attack signalled:
## - STOMP: a leg lifted high while frost gathers round it (1.2 s), then a freezing ring along the ground:
##   4 HP to whoever stands within STOMP_RADIUS (a jump clears it, like the Golem's slam), and the ground
##   there turns icy for ICY_TIME (IcyGround: slippery; never a changed block);
## - BREATH: it breathes in, head back, its mouth glowing (1.3 s), then breathes a cone of cold the way it
##   faces for 1.5 s: 1 HP every half second to whoever is in the cone with a clear line from its mouth (a
##   block in the way, a snow wall, shields); then it PANTS for 2 s and takes double damage;
## - SNOWBALL: a giant snowball held up (1 s), thrown in the Golem rock's arc: 3 HP where it lands.
## Health by team size like the Golem's (BossRules.TEAM_SHARE, TIRED_SHARE); the honest help, gold, portal
## and the end of a fight are the BossDirector's.

const BASE_HP := 420
const STOMP := &"stomp"
const BREATH := &"breath"
const SNOWBALL := &"snowball"
const ORDER: Array[StringName] = [STOMP, BREATH, SNOWBALL]
const DAMAGE := {STOMP: 4, BREATH: 1, SNOWBALL: 3}

enum Phase { RISE, WALK, STOMP_WARN, BREATH_WARN, BREATH, PANTING, THROW_WARN, DOWN }

const RISE_TIME := 2.2
const WALK_TIME := 2.0
const STOMP_WINDUP := 1.2
const BREATH_WINDUP := 1.3
const BREATH_TIME := 1.5
const BREATH_TICK := 0.5          # the breath hurts every half second ...
const BREATH_TICKS := 3           # ... this many times in one breath
const PANT_TIME := 2.0
const THROW_WINDUP := 1.0
const PANT_FACTOR := 2
const STOMP_RADIUS := 6.5
const STOMP_HEIGHT := 2.0
const ICY_RADIUS := 8.0           # the ground turns icy this far round the stomp ...
const ICY_TIME := 4.0             # ... for this long
const BREATH_LENGTH := 9.0        # the cone reaches this far (flat) ...
const BREATH_ANGLE := 35.0        # ... this many degrees to each side of where it faces ...
const BREATH_DROP := 6.0          # ... and this far down from its mouth (a child on a tower is above it)
const WALK_SPEED := 2.0           # slower than a walking child (6 m/s)

const NAME := "Frost Giant"
const TITLE := "FROST GIANT"
const TIRED_TITLE := "TIRED GIANT"
const WIN_MESSAGE := "You beat the Frost Giant!"
const TIRED_MESSAGE := "The Frost Giant is tired today: it has less health!"
const SUMMON_LINE := "%s woke the Frost Giant! Hide from its icy breath!"


static func max_hp(team: int, tired: bool = false) -> int:
	var hp := BASE_HP * (1.0 + BossRules.TEAM_SHARE * (maxi(team, 1) - 1))
	return roundi(hp * BossRules.TIRED_SHARE) if tired else roundi(hp)


static func damage(attack: StringName) -> int:
	return int(DAMAGE.get(attack, 0))


## The attack number `step` of a fight (0 = the first).
static func attack_at(step: int) -> StringName:
	return ORDER[posmod(step, ORDER.size())]


static func phase_time(phase: int) -> float:
	match phase:
		Phase.RISE:
			return RISE_TIME
		Phase.WALK:
			return WALK_TIME
		Phase.STOMP_WARN:
			return STOMP_WINDUP
		Phase.BREATH_WARN:
			return BREATH_WINDUP
		Phase.BREATH:
			return BREATH_TIME
		Phase.PANTING:
			return PANT_TIME
		Phase.THROW_WARN:
			return THROW_WINDUP
	return INF


## What comes after `phase`; `step` is the number of the next attack (for the wind-up after a walk). The
## stomp lands as STOMP_WARN ends, the snowball flies as THROW_WARN ends.
static func next_phase(phase: int, step: int) -> int:
	match phase:
		Phase.RISE, Phase.STOMP_WARN, Phase.PANTING, Phase.THROW_WARN:
			return Phase.WALK
		Phase.WALK:
			match attack_at(step):
				STOMP:
					return Phase.STOMP_WARN
				BREATH:
					return Phase.BREATH_WARN
			return Phase.THROW_WARN
		Phase.BREATH_WARN:
			return Phase.BREATH
		Phase.BREATH:
			return Phase.PANTING
	return Phase.DOWN


static func is_warning(phase: int) -> bool:
	return phase in [Phase.STOMP_WARN, Phase.BREATH_WARN, Phase.THROW_WARN]


## Standing (not climbing out, not down): weapons reach it.
static func hittable(phase: int) -> bool:
	return phase != Phase.RISE and phase != Phase.DOWN


static func hit_taken(amount: int, panting: bool) -> int:
	return maxi(amount, 0) * (PANT_FACTOR if panting else 1)


# Targets are [{pos: feet, grounded: bool}], as in BossRules; results are their indexes.

## The freezing ring from `center` (its feet): everyone on the ground within STOMP_RADIUS.
static func stomp_hits(center: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		if bool(targets[i].grounded) and Vector2(p.x - center.x, p.z - center.z).length() <= STOMP_RADIUS \
				and absf(p.y - center.y) <= STOMP_HEIGHT:
			out.append(i)
	return out


## Is a child whose chest is at `chest` in the breath from `mouth`, blowing `dir`? Inside the cone (flat:
## BREATH_LENGTH far, BREATH_ANGLE to each side; no higher than a little over its mouth, no lower than
## BREATH_DROP) and with no solid block in the way. is_solid(cell) -> bool.
static func in_breath(mouth: Vector3, dir: Vector3, chest: Vector3, is_solid: Callable) -> bool:
	var to := chest - mouth
	var flat := Vector2(to.x, to.z)
	var look := Vector2(dir.x, dir.z)
	if flat.length() > BREATH_LENGTH or to.y < -BREATH_DROP or to.y > 2.0 or look.length() < 0.001:
		return false
	if flat.length() > 0.5 and rad_to_deg(absf(look.angle_to(flat))) > BREATH_ANGLE:
		return false
	return MonsterRules.clear_line(mouth, chest, is_solid)
