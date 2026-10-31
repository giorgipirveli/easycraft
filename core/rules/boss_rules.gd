class_name BossRules
extends RefCounted
## The Stone Golem as pure rules (M2 spec §12.9; research G3 "honest help", D8 "portal peek").
## - Health: 300 × (1 + 0.5 × (team − 1)), team = players + bot friends (BotFriend.team_size); a tired
##   Golem (after TIRED_AFTER lost fights) has a quarter less, and says so.
## - Attacks in a fixed order (children learn the rhythm), each signalled by a wind-up: SLAM (both fists
##   up 1.2 s, a shockwave ring of 7 blocks: 4 HP to everyone on the ground, nobody in the air), ROCK (a
##   glowing rock held up 1 s, then thrown in an arc: 3 HP where it lands), CHARGE (paws the ground 1 s,
##   then runs straight 12 blocks: 5 HP on its path). A walk (REST) comes between attacks. After a slam
##   it is DAZED for 2 s and takes double damage.
## - Defeat: 300 gold split among the players, and a portal at the Totem that unlocks universe 2
##   (Survivor only; no countdown, no "come back tomorrow").
## - Honest help: a lost fight shows how far the team got ("You got it to 20%!"); after three lost
##   fights the Golem arrives tired. The help resets after a win. Saved per world (clean_help).

const BASE_HP := 300
const TEAM_SHARE := 0.5           # each more player (or bot friend) adds half of BASE_HP
const GOLD := 300
const TIRED_AFTER := 3            # lost fights
const TIRED_SHARE := 0.75         # a tired Golem keeps 75% of its health
const MAX_LOSSES := 99
const TIRED_MESSAGE := "The Golem is tired today: it has less health!"
const WIN_MESSAGE := "You beat the Stone Golem!"
const PORTAL_MESSAGE := "Sandstorm Desert opens in the next update!"
const NEXT_UNIVERSE := 2          # the Golem's portal leads to universe 2 (M3 makes it lead there)

const SLAM := &"slam"
const ROCK := &"rock"
const CHARGE := &"charge"
const ORDER: Array[StringName] = [SLAM, ROCK, CHARGE]
const ATTACKS := {
	SLAM: {"windup": 1.2, "damage": 4},
	ROCK: {"windup": 1.0, "damage": 3},
	CHARGE: {"windup": 1.0, "damage": 5},
}

const SLAM_RADIUS := 7.0          # the shockwave ring (horizontal)
const SLAM_HEIGHT := 2.0          # ... along the ground: not up a tower
const ROCK_REACH := 1.4           # the rock hits within this of where it lands (horizontal)
const ROCK_SPEED := 12.0          # m/s along the ground
const ROCK_ARC := 2.5             # how high the arc rises above the straight line (+ a bit per block)
const CHARGE_DISTANCE := 12.0
const CHARGE_SPEED := 10.0        # m/s: 1.2 s of running
const CHARGE_REACH := 1.6         # hits whoever is this close to its path
const HIT_HEIGHT := 2.0           # rocks and charges reach this far up or down
const DAZE_TIME := 2.0
const DAZE_FACTOR := 2
const REST := 2.0                 # walking between two attacks
const RISE_TIME := 2.0            # it climbs out of the ground (no hits yet)

## Grounded: standing on a block (within GROUND_GAP above it), not moving up or down faster than
## AIRBORNE_SPEED, not flying.
const GROUND_GAP := 0.3
const AIRBORNE_SPEED := 1.5

const LEAVE_TIME := 10.0          # nobody near the Golem this long: the fight is over (lost)
const ARENA := 40.0               # "near": players this close to the Golem's spot

## The Golem's phases: the schedule next_phase follows. DOWN: defeated or gone back to sleep.
enum Phase { RISE, WALK, SLAM_WINDUP, DAZED, ROCK_WINDUP, CHARGE_WINDUP, CHARGE, DOWN }

const _WINDUP_PHASES := {SLAM: Phase.SLAM_WINDUP, ROCK: Phase.ROCK_WINDUP, CHARGE: Phase.CHARGE_WINDUP}


static func max_hp(team: int, tired: bool = false) -> int:
	var hp := BASE_HP * (1.0 + TEAM_SHARE * (maxi(team, 1) - 1))
	return roundi(hp * TIRED_SHARE) if tired else roundi(hp)


# --- The schedule ---------------------------------------------------------------------------------

## The attack number `step` of a fight (0 = the first).
static func attack_at(step: int) -> StringName:
	return ORDER[step % ORDER.size()] if step >= 0 else ORDER[0]


static func windup(attack: StringName) -> float:
	return float(ATTACKS[attack].windup) if ATTACKS.has(attack) else 0.0


static func damage(attack: StringName) -> int:
	return int(ATTACKS[attack].damage) if ATTACKS.has(attack) else 0


## How long a phase lasts before next_phase (INF: until something else ends it).
static func phase_time(phase: int) -> float:
	match phase:
		Phase.RISE:
			return RISE_TIME
		Phase.WALK:
			return REST
		Phase.SLAM_WINDUP:
			return windup(SLAM)
		Phase.ROCK_WINDUP:
			return windup(ROCK)
		Phase.CHARGE_WINDUP:
			return windup(CHARGE)
		Phase.DAZED:
			return DAZE_TIME
		Phase.CHARGE:
			return CHARGE_DISTANCE / CHARGE_SPEED
	return INF


## What comes after `phase`; `step` is the number of the next attack (for the wind-up after a walk).
## The slam lands as SLAM_WINDUP ends, the rock flies as ROCK_WINDUP ends.
static func next_phase(phase: int, step: int) -> int:
	match phase:
		Phase.RISE, Phase.DAZED, Phase.ROCK_WINDUP, Phase.CHARGE:
			return Phase.WALK
		Phase.WALK:
			return _WINDUP_PHASES[attack_at(step)]
		Phase.SLAM_WINDUP:
			return Phase.DAZED
		Phase.CHARGE_WINDUP:
			return Phase.CHARGE
	return Phase.DOWN


static func is_windup(phase: int) -> bool:
	return phase in [Phase.SLAM_WINDUP, Phase.ROCK_WINDUP, Phase.CHARGE_WINDUP]


## The attack a phase belongs to (its wind-up, or the run of a charge); &"" for the others.
static func attack_of(phase: int) -> StringName:
	match phase:
		Phase.SLAM_WINDUP:
			return SLAM
		Phase.ROCK_WINDUP:
			return ROCK
		Phase.CHARGE_WINDUP, Phase.CHARGE:
			return CHARGE
	return &""


# --- Who is hit ---------------------------------------------------------------------------------------
# Targets are [{pos: feet, grounded: bool}] (players and bot friends); the result is their indexes.

## Standing on a block, not jumping, not flying (the slam's "on the ground"). is_solid(cell) -> bool.
static func is_grounded(feet: Vector3, vel_y: float, flying: bool, is_solid: Callable) -> bool:
	if flying or absf(vel_y) > AIRBORNE_SPEED or not feet.is_finite():
		return false
	return is_solid.call(Vector3i(floori(feet.x), floori(feet.y - GROUND_GAP), floori(feet.z)))


## The shockwave from `center` (the Golem's feet): everyone on the ground within SLAM_RADIUS.
static func slam_hits(center: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		if bool(targets[i].grounded) and _flat(p, center) <= SLAM_RADIUS and absf(p.y - center.y) <= SLAM_HEIGHT:
			out.append(i)
	return out


## Where the rock lands: whoever is within ROCK_REACH, in the air or not.
static func rock_hits(impact: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		if _flat(p, impact) <= ROCK_REACH and absf(p.y - impact.y) <= HIT_HEIGHT:
			out.append(i)
	return out


## A charge from `from` to `to` (this step of its run): whoever is within CHARGE_REACH of the path.
static func charge_hits(from: Vector3, to: Vector3, targets: Array) -> Array[int]:
	var out: Array[int] = []
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	for i in targets.size():
		var p: Vector3 = targets[i].pos
		var q := Vector2(p.x, p.z)
		var d := q.distance_to(Geometry2D.get_closest_point_to_segment(q, a, b)) if a != b else q.distance_to(a)
		if d <= CHARGE_REACH and absf(p.y - from.y) <= HIT_HEIGHT:
			out.append(i)
	return out


## Where a charge that starts at `from` facing `dir` would stop (CHARGE_DISTANCE along the ground).
static func charge_end(from: Vector3, dir: Vector3) -> Vector3:
	var flat := Vector3(dir.x, 0.0, dir.z)
	return from + (flat.normalized() if flat.length() > 0.001 else Vector3.FORWARD) * CHARGE_DISTANCE


## The rock's flight time from the Golem's hand to where it lands.
static func rock_time(from: Vector3, to: Vector3) -> float:
	return clampf(_flat(from, to) / ROCK_SPEED, 0.5, 1.6)


## Where the rock is at t = 0..1 of its flight: a straight line lifted by an arc.
static func rock_point(from: Vector3, to: Vector3, t: float) -> Vector3:
	var k := clampf(t, 0.0, 1.0)
	var arc := (ROCK_ARC + _flat(from, to) * 0.12) * 4.0 * k * (1.0 - k)
	return from.lerp(to, k) + Vector3(0.0, arc, 0.0)


## A hit's damage to the Golem: double while it is dazed; never negative.
static func hit_taken(amount: int, dazed: bool) -> int:
	return maxi(amount, 0) * (DAZE_FACTOR if dazed else 1)


# --- Gold ------------------------------------------------------------------------------------------

## GOLD split among `players` (in the order the caller lists them): near-equal shares that add up to
## exactly GOLD; the first players get the odd coins.
static func gold_split(players: int, total: int = GOLD) -> Array[int]:
	var out: Array[int] = []
	for i in maxi(players, 0):
		out.append(total / players + (1 if i < total % players else 0))
	return out


# --- Honest help (G3) ---------------------------------------------------------------------------------

static func new_help() -> Dictionary:
	return {"losses": 0, "best": 100, "wins": 0}


## The Golem's health left, in percent rounded UP to fives (never more progress than the team made);
## 0 only when defeated.
static func percent_left(hp: int, max_health: int) -> int:
	if max_health <= 0:
		return 100
	if hp <= 0:
		return 0
	var pct := ceili(float(mini(hp, max_health)) * 100.0 / float(max_health))
	return clampi(ceili(pct / 5.0) * 5, 5, 100)


static func loss_message(percent: int) -> String:
	return Lang.t("You got it to %d%%!") % percent


static func after_loss(help: Dictionary, percent: int) -> Dictionary:
	var h := clean_help(help)
	h.losses = mini(h.losses + 1, MAX_LOSSES)
	h.best = mini(h.best, clampi(percent, 0, 100))
	return h


static func after_win(help: Dictionary) -> Dictionary:
	var h := clean_help(help)
	return {"losses": 0, "best": 100, "wins": mini(h.wins + 1, MAX_LOSSES)}


static func is_tired(help: Dictionary) -> bool:
	return int(help.get("losses", 0)) >= TIRED_AFTER


## Saved help from a world file: whole numbers in range; anything broken reads as no help yet.
static func clean_help(v: Variant) -> Dictionary:
	var h := new_help()
	if not v is Dictionary:
		return h
	var d: Dictionary = v
	h.losses = clampi(_int(d.get("losses"), 0), 0, MAX_LOSSES)
	var best := _int(d.get("best"), 100)
	h.best = best if best >= 0 and best <= 100 else 100
	h.wins = clampi(_int(d.get("wins"), 0), 0, MAX_LOSSES)
	return h


# --- The end of a fight ---------------------------------------------------------------------------------

## Lost when every player is knocked out at once (only where knock-outs count: `losses`, Survivor; in
## Sandbox players pop right back up) or when nobody has been near the Golem for LEAVE_TIME.
static func is_lost(players_up: int, away_time: float, losses: bool) -> bool:
	return (losses and players_up <= 0) or away_time >= LEAVE_TIME


## The profile's highest universe after a win: at least NEXT_UNIVERSE, never lowered.
static func unlocked_after_win(current: int) -> int:
	return maxi(current, NEXT_UNIVERSE)


## Only a real fight opens the next universe: a Sandbox Golem is summoned by a cheat.
static func unlocks_universe(mode: StringName) -> bool:
	return not ModeRules.allows(mode, ModeRules.CHEATS)


# --- Where things stand ---------------------------------------------------------------------------------

const GOLEM_OFFSET := Vector3(0, 0, -7)    # from the Totem: a few steps away, a moment to get ready
const PORTAL_OFFSET := Vector3(3, 0, 0)    # right by the Totem


const STAND_SEARCH := 8           # stand_y looks this far up and down


## The feet height of the place to stand in column (x, z) nearest `near_y`: air with room for the
## Golem's body (3 blocks, never in water) over a solid block. near_y when there is none within
## STAND_SEARCH. block_at(cell: Vector3i) -> int.
static func stand_y(x: float, z: float, near_y: float, block_at: Callable) -> float:
	var cx := floori(x)
	var cz := floori(z)
	var base := floori(near_y)
	for i in STAND_SEARCH * 2 + 1:
		var y := base + (i + 1) / 2 * (1 if i % 2 == 1 else -1)
		if BlockIds.is_solid(block_at.call(Vector3i(cx, y - 1, cz))) and _room(cx, y, cz, block_at):
			return float(y)
	return near_y


static func _room(x: int, y: int, z: int, block_at: Callable) -> bool:
	for dy in 3:
		var id: int = block_at.call(Vector3i(x, y + dy, z))
		if BlockIds.is_solid(id) or id == BlockIds.WATER:
			return false
	return true


static func golem_spot(totem: Vector3) -> Vector3:
	return totem + GOLEM_OFFSET


static func portal_spot(totem: Vector3) -> Vector3:
	return totem + PORTAL_OFFSET


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _int(v: Variant, default: int) -> int:
	if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and absf(float(v)) < 1e9:
		return int(v)
	if typeof(v) == TYPE_FLOAT and is_finite(float(v)):
		return MAX_LOSSES if float(v) > 0 else 0
	return default


# --- M3 Task 2: each universe's boss (the Sand Serpent in the Sandstorm Desert) -------------------------

const GOLEM := &"golem"
const SERPENT := &"serpent"
const FROST_GIANT := &"giant"     # M3 Task 3: Frostpeak's boss (/summon giant)
const CAKE := &"cake"             # M3 Task 4: the Candy Kingdom's Cake Monster (CakeRules)
const SKY_DRAGON := &"sky_dragon" # Owner 39: the Dragon Realm's Sky Dragon (SkyDragonRules; /summon skydragon)
const SPORE_MOTHER := &"spore_mother" # universe 6: the Glow Caves' Spore Mother (SporeMotherRules; /summon sporemother)


## A boss's words for the HUD and the messages: {name, title, tired_title, win, tired, summon}.
static func words(kind: StringName) -> Dictionary:
	if kind == SPORE_MOTHER:   # universe 6
		return {"name": SporeMotherRules.NAME, "title": SporeMotherRules.TITLE, "tired_title": SporeMotherRules.TIRED_TITLE,
			"win": SporeMotherRules.WIN_MESSAGE, "tired": SporeMotherRules.TIRED_MESSAGE, "summon": SporeMotherRules.SUMMON_LINE}
	if kind == SKY_DRAGON:   # Owner 39
		return {"name": SkyDragonRules.NAME, "title": SkyDragonRules.TITLE, "tired_title": SkyDragonRules.TIRED_TITLE,
			"win": SkyDragonRules.WIN_MESSAGE, "tired": SkyDragonRules.TIRED_MESSAGE, "summon": SkyDragonRules.SUMMON_LINE}
	if kind == CAKE:
		return {"name": CakeRules.NAME, "title": CakeRules.TITLE, "tired_title": CakeRules.TIRED_TITLE,
			"win": CakeRules.WIN_MESSAGE, "tired": CakeRules.TIRED_MESSAGE, "summon": CakeRules.SUMMON_LINE}
	if kind == SERPENT:
		return {"name": SerpentRules.NAME, "title": SerpentRules.TITLE, "tired_title": SerpentRules.TIRED_TITLE,
			"win": SerpentRules.WIN_MESSAGE, "tired": SerpentRules.TIRED_MESSAGE, "summon": SerpentRules.SUMMON_LINE}
	if kind == FROST_GIANT:
		return {"name": FrostGiantRules.NAME, "title": FrostGiantRules.TITLE, "tired_title": FrostGiantRules.TIRED_TITLE,
			"win": FrostGiantRules.WIN_MESSAGE, "tired": FrostGiantRules.TIRED_MESSAGE, "summon": FrostGiantRules.SUMMON_LINE}
	return {"name": "Stone Golem", "title": "STONE GOLEM", "tired_title": "TIRED GOLEM", "win": WIN_MESSAGE,
		"tired": TIRED_MESSAGE, "summon": "%s woke the Stone Golem! Watch its fists!"}


## A boss's health for a team (tired: the honest-help one).
static func max_hp_of(kind: StringName, team: int, tired: bool = false) -> int:
	if kind == FROST_GIANT:
		return FrostGiantRules.max_hp(team, tired)   # M3 Task 3
	if kind == CAKE:
		return CakeRules.max_hp(team, tired)   # M3 Task 4
	if kind == SKY_DRAGON:
		return SkyDragonRules.max_hp(team, tired)   # Owner 39
	if kind == SPORE_MOTHER:
		return SporeMotherRules.max_hp(team, tired)   # universe 6
	return SerpentRules.max_hp(team, tired) if kind == SERPENT else max_hp(team, tired)
