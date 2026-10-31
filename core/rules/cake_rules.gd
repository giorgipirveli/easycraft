class_name CakeRules
extends RefCounted
## The Cake Monster, the Candy Kingdom's boss (M3 Task 4, spec §14.1 "layers fall off as it is hurt; each
## layer changes its attack"), as pure rules. A walking three-tier cake:
## - three tiers: it squishes down and sends a FROSTING WAVE along the ground (4 HP within WAVE_RADIUS; a jump
##   clears it);
## - at two thirds of its health the top tier falls off; two tiers: a cherry glows on top, then it throws
##   three CHERRIES in an arc, one where the child stands and one each side (3 HP each: keep moving);
## - at a third the middle tier falls; one tier: it leans back and SPINS at you like a top, straight for
##   SPIN_DISTANCE (5 HP on its path: jump aside).
## Every attack is signalled by a wind-up of a second or more; after it the cake is DIZZY (double damage). A
## falling layer is a pause (no hits, no attacks) with a line that says what comes next, and a hit never skips
## a layer (after_hit), so every attack gets its turn. Health by team size like the Golem's; the honest help,
## gold, the end of a fight are the BossDirector's. It never changes a block.

const BASE_HP := 420
const LAYERS := 3
const WAVE := &"wave"
const CHERRIES := &"cherries"
const SPIN := &"spin"
const DAMAGE := {WAVE: 4, CHERRIES: 3, SPIN: 5}
const ATTACKS: Array[StringName] = [SPIN, CHERRIES, WAVE]   # by layers left - 1

enum Phase { RISE, WALK, WAVE_WARN, CHERRY_WARN, SPIN_WARN, SPIN, DIZZY, LAYER_DROP, DOWN }

const RISE_TIME := 2.0
const WALK_TIME := 2.0
const WAVE_WINDUP := 1.3
const CHERRY_WINDUP := 1.1
const SPIN_WINDUP := 1.2
const DIZZY_TIME := 2.2
const DROP_TIME := 1.5
const WAVE_RADIUS := 6.5          # the frosting wave along the ground (flat) ...
const WAVE_HEIGHT := 2.0          # ... not up a tower
const CHERRY_SPREAD := 2.5        # the side cherries land this far to each side of the child
const SPIN_DISTANCE := 12.0
const SPIN_SPEED := 9.0           # m/s: a walking child (6) can step out of its way after the wind-up
const DIZZY_FACTOR := 2

const NAME := "Cake Monster"
const TITLE := "CAKE MONSTER"
const TIRED_TITLE := "TIRED CAKE"
const WIN_MESSAGE := "You beat the Cake Monster!"
const TIRED_MESSAGE := "The Cake Monster is tired today: it has less health!"
const SUMMON_LINE := "%s woke the Cake Monster! Watch the frosting!"
## The last universe's boss is beaten: the grand celebration's words (and a rainbow portal to every universe).
const GRAND_WIN := "Every universe is yours! A rainbow portal opened by the Totem!"
## What a falling layer says (by layers left): the next attack, so children know what to do.
const LAYER_LINES := {
	2: "A layer fell off! Now it throws cherries: keep moving!",
	1: "Another layer fell off! Now it spins at you: jump aside!",
}


static func max_hp(team: int, tired: bool = false) -> int:
	var hp := BASE_HP * (1.0 + BossRules.TEAM_SHARE * (maxi(team, 1) - 1))
	return roundi(hp * BossRules.TIRED_SHARE) if tired else roundi(hp)


## Tiers still standing at `hp` of `max_health`: 3 above two thirds, 2 above a third, 1 above none.
static func layers_left(hp: int, max_health: int) -> int:
	if hp <= 0:
		return 0
	if max_health <= 0:
		return LAYERS
	if hp > max_health * 2.0 / 3.0:
		return 3
	if hp > max_health / 3.0:
		return 2
	return 1


## Its health after a hit of `damage`: a hit that takes a tier off ends at that tier's line (never two at once).
static func after_hit(hp: int, damage: int, max_health: int) -> int:
	var l := layers_left(hp, max_health)
	var line := floori(max_health * (l - 1) / 3.0) if l > 1 else 0
	return maxi(hp - maxi(damage, 0), line)


static func attack_for(layers: int) -> StringName:
	return ATTACKS[clampi(layers, 1, LAYERS) - 1]


static func damage(attack: StringName) -> int:
	return int(DAMAGE.get(attack, 0))


static func phase_time(phase: int) -> float:
	match phase:
		Phase.RISE:
			return RISE_TIME
		Phase.WALK:
			return WALK_TIME
		Phase.WAVE_WARN:
			return WAVE_WINDUP
		Phase.CHERRY_WARN:
			return CHERRY_WINDUP
		Phase.SPIN_WARN:
			return SPIN_WINDUP
		Phase.SPIN:
			return SPIN_DISTANCE / SPIN_SPEED
		Phase.DIZZY:
			return DIZZY_TIME
		Phase.LAYER_DROP:
			return DROP_TIME
	return INF


## What comes after `phase` for a cake of `layers` tiers. The wave lands as WAVE_WARN ends, the cherries fly
## as CHERRY_WARN ends.
static func next_phase(phase: int, layers: int) -> int:
	match phase:
		Phase.RISE, Phase.DIZZY, Phase.LAYER_DROP:
			return Phase.WALK
		Phase.WALK:
			match attack_for(layers):
				WAVE:
					return Phase.WAVE_WARN
				CHERRIES:
					return Phase.CHERRY_WARN
			return Phase.SPIN_WARN
		Phase.WAVE_WARN, Phase.CHERRY_WARN, Phase.SPIN:
			return Phase.DIZZY
		Phase.SPIN_WARN:
			return Phase.SPIN
	return Phase.DOWN


static func is_warning(phase: int) -> bool:
	return phase in [Phase.WAVE_WARN, Phase.CHERRY_WARN, Phase.SPIN_WARN]


## Weapons reach it (not while it rises, drops a layer or is down).
static func hittable(phase: int) -> bool:
	return not phase in [Phase.RISE, Phase.LAYER_DROP, Phase.DOWN]


static func hit_taken(amount: int, dizzy: bool) -> int:
	return maxi(amount, 0) * (DIZZY_FACTOR if dizzy else 1)


# Targets are [{pos: feet, grounded: bool}], as in BossRules; results are their indexes.

## The frosting wave from `center` (its feet): everyone standing on the ground within WAVE_RADIUS.
static func wave_hits(center: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		if bool(targets[i].grounded) and Vector2(p.x - center.x, p.z - center.z).length() <= WAVE_RADIUS \
				and absf(p.y - center.y) <= WAVE_HEIGHT:
			out.append(i)
	return out


## Where the three cherries land: at the child (`at`), and CHERRY_SPREAD to each side across the throw.
static func cherry_spots(from: Vector3, at: Vector3) -> Array[Vector3]:
	var dir := Vector3(at.x - from.x, 0.0, at.z - from.z)
	dir = dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	var side := Vector3(-dir.z, 0.0, dir.x) * CHERRY_SPREAD
	return [at, at + side, at - side]
