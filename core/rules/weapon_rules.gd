class_name WeaponRules
extends RefCounted
## Weapons as pure rules (M1b Task 11): one weapon table for everything that hits (M2 monsters
## use the same numbers), the melee swing cone with light aim assist, the host's checks (reach,
## cooldown), knockback without damage for players and buddies, arrow flight, the
## boomerang's out-and-back path, and the practice targets (bullseye rings, where they stand).

const MELEE := &"melee"
const BOW := &"bow"
const BOOMERANG := &"boomerang"
const POWER_FELL := &"fell"        # axe: a whole tree at once (ToolPowers.fell_tree)
const POWER_TUNNEL := &"tunnel"    # pickaxe: a player-sized 1x2 step (ToolPowers.tunnel)
const POWER_SMASH := &"smash"      # hammer: a 3x3 patch of ground (ToolPowers.smash)

## The bare hands' "weapon" id (owner feedback #29): negative, so no block or item id can ever be it.
const FISTS := -1

## damage per hit, reach in metres (melee: from the chest; bow and boomerang: their range),
## cooldown between attacks (s), knockback (push speed, m/s), arc (half-angle of the swing, degrees),
## max_hits (things one swing can hit), the tool's block power and its attack sound.
const WEAPONS := {
	ItemIds.SWORD: {"kind": MELEE, "damage": 4, "reach": 3.0, "cooldown": 0.35, "knockback": 6.0,
		"arc": 55.0, "max_hits": 3, "power": &"", "sound": &"swing"},
	ItemIds.BOW: {"kind": BOW, "damage": 5, "reach": 48.0, "cooldown": 0.45, "knockback": 4.0,
		"arc": 0.0, "max_hits": 1, "power": &"", "sound": &"bow"},
	ItemIds.BOOMERANG: {"kind": BOOMERANG, "damage": 21, "reach": 14.0, "cooldown": 0.6, "knockback": 5.0,
		"arc": 0.0, "max_hits": 4, "power": &"", "sound": &"whirr"},
	ItemIds.HAMMER: {"kind": MELEE, "damage": 6, "reach": 3.2, "cooldown": 1.1, "knockback": 14.0,
		"arc": 70.0, "max_hits": 5, "power": POWER_SMASH, "sound": &"swing"},
	ItemIds.AXE: {"kind": MELEE, "damage": 3, "reach": 2.8, "cooldown": 0.5, "knockback": 4.0,
		"arc": 30.0, "max_hits": 1, "power": POWER_FELL, "sound": &"swing"},
	ItemIds.PICKAXE: {"kind": MELEE, "damage": 2, "reach": 2.8, "cooldown": 0.4, "knockback": 3.0,
		"arc": 30.0, "max_hits": 1, "power": POWER_TUNNEL, "sound": &"swing"},
	# M2 Task 6 (spec §13.1): the spear thrusts far and narrow (and can be thrown), the mace is a slow,
	# heavy swing that shakes the ground. Their tiers are in TIERS. Owner #53: every fighting weapon's damage a
	# second follows its rarity (WeaponStrength.BANDS): the spear 4 -> 5, the mace 6 -> 8 and 0.9 -> 0.85 s, the
	# boomerang 3 -> 21 (one big hit a throw: it has to come back first).
	ItemIds.SPEAR: {"kind": MELEE, "damage": 5, "reach": 4.5, "cooldown": 0.55, "knockback": 7.0,
		"arc": 20.0, "max_hits": 2, "power": &"", "sound": &"swing"},
	ItemIds.MACE: {"kind": MELEE, "damage": 8, "reach": 3.0, "cooldown": 0.85, "knockback": 12.0,
		"arc": 50.0, "max_hits": 3, "power": &"", "sound": &"swing"},
	# Owner feedback #29: ATTACK with no weapon in the hotbar punches: small, short and quick. FISTS is
	# not an item (no hotbar, bag or shop holds it); it only travels with attacks to the host.
	FISTS: {"kind": MELEE, "damage": 1, "reach": 2.2, "cooldown": 0.3, "knockback": 3.0,
		"arc": 45.0, "max_hits": 1, "power": &"", "sound": &"swing"},
}


## What was hit: practice dummies, M2 monsters and (owner feedback #26) animals take damage. Players
## and buddies are pushed back but never hurt; the bullseye only scores arrows.
const DUMMY := &"dummy"
const BULLSEYE_TARGET := &"bullseye"
const ANIMAL := &"animal"
const PLAYER := &"player"
const BUDDY := &"buddy"
const MONSTER := &"monster"
const _DAMAGEABLE: Array[StringName] = [DUMMY, MONSTER, ANIMAL]

const REACH_TOLERANCE := 1.0       # host-side slack for network latency (m)
const COOLDOWN_SLACK := 0.8        # the host accepts attacks after 80% of the cooldown (jitter)
const ASSIST_ANGLE := 35.0         # melee: a target this close to the aim pulls the swing onto it
const RANGED_ASSIST_ANGLE := 8.0   # bow and boomerang (applied by the thrower's game)
const MAX_MELEE_RISE := 2.5        # a swing reaches this far up or down
const CLOSE := 0.5                 # anything this close counts as in front
const COMBO_WINDOW := 0.7          # seconds between sword swings that keep the combo going
const COMBO_STEPS := 3             # slash, slash, spin
const FINISHER_BONUS := 1.5        # the spin hits harder, pushes further and all around
const LIFT := 0.35                 # knockback also lifts a little: up = knockback * LIFT + 1

const ARROW_SPEED := 34.0          # at full draw (m/s)
const ARROW_GRAVITY := 14.0
const MIN_DRAW := 0.3              # a quick tap still shoots, at 30% speed
const DRAW_TIME := 0.7             # seconds to full draw

const BOOMERANG_SPEED := 16.0
const BOOMERANG_RETURN_FACTOR := 1.15
const BOOMERANG_CATCH := 1.0
const BOOMERANG_MAX_TIME := 5.0    # after this it is back in the hand, wherever it was
## The throw follows the aim up or down (so a dummy below the thrower is hit), but never steeper
## than this (the direction's y; about 37°), so even a throw straight down still flies out.
const BOOMERANG_MAX_PITCH := 0.6

const BULLSEYE_RADIUS := 0.6
const MAX_TARGETS := 16            # placed dummies and bullseyes per world


static func is_weapon(id: int) -> bool:
	return WEAPONS.has(base_of(id))


## Owner feedback #29: the hotbar slot ATTACK takes a weapon from when the hand holds none: the melee
## weapon that hits hardest per second (damage / cooldown; the first of equals), or -1 (then fists).
## Bows and boomerangs are left out: they need aiming, and a quick ATTACK is a swing.
static func best_melee_slot(hotbar: Array[int]) -> int:
	var best := -1
	var best_rate := 0.0
	for i in hotbar.size():
		var w := stats(hotbar[i])
		if w.is_empty() or w.kind != MELEE:
			continue
		var rate := float(w.damage) / float(w.cooldown)
		if rate > best_rate + 0.0001:
			best = i
			best_rate = rate
	return best


## A weapon's numbers; a tier item gets its kind's, with the damage times its tier (M2 Task 6).
static func stats(id: int) -> Dictionary:
	if WEAPONS.has(id):
		return WEAPONS[id]
	var base := base_of(id)
	if base == id or not WEAPONS.has(base):
		return {}
	if not _tier_stats.has(id):
		var w: Dictionary = (WEAPONS[base] as Dictionary).duplicate()
		w.damage = maxi(roundi(int(w.damage) * tier_multiplier(id)), 1)
		w.make_read_only()
		_tier_stats[id] = w
	return _tier_stats[id]


# --- Melee ---

## Is `target` inside the swing: within reach (plus the target's own radius), not too far above
## or below, and within `arc_deg` of the aim on the ground plane.
static func in_cone(origin: Vector3, dir: Vector3, target: Vector3, reach: float, arc_deg: float, radius: float = 0.0) -> bool:
	var to := target - origin
	if absf(to.y) > MAX_MELEE_RISE or to.length() > reach + radius:
		return false
	var flat := Vector2(to.x, to.z)
	if flat.length() < CLOSE or arc_deg >= 180.0:
		return true
	var aim := Vector2(dir.x, dir.z)
	if aim.length() < 0.001:
		return false
	return rad_to_deg(absf(aim.angle_to(flat))) <= arc_deg


## The aim, pulled onto the target closest to it if one is within `assist_deg` and `max_dist`.
## flat = true compares directions on the ground plane only (melee).
static func aim_assist(origin: Vector3, dir: Vector3, targets: Array, max_dist: float, assist_deg: float, flat: bool = false) -> Vector3:
	var aim := Vector3(dir.x, 0.0, dir.z) if flat else dir
	if aim.length() < 0.001:
		return dir
	var i := assist_target(origin, dir, targets, max_dist, assist_deg, flat)
	if i < 0:
		return aim.normalized()
	var to: Vector3 = targets[i] - origin
	if flat:
		to.y = 0.0
	return to.normalized()


## Index of the target that aim assist pulls onto (the one closest to the aim), or -1.
static func assist_target(origin: Vector3, dir: Vector3, targets: Array, max_dist: float, assist_deg: float, flat: bool = false) -> int:
	var aim := Vector3(dir.x, 0.0, dir.z) if flat else dir
	if aim.length() < 0.001:
		return -1
	var best := -1
	var best_angle := deg_to_rad(assist_deg)
	for i in targets.size():
		var to: Vector3 = targets[i] - origin
		if to.length() > max_dist:
			continue
		if flat:
			to.y = 0.0
		if to.length() < 0.001:
			continue
		var angle := aim.angle_to(to)
		if angle <= best_angle:
			best_angle = angle
			best = i
	return best


## Indices of the targets one swing hits, closest first, at most the weapon's max_hits.
## targets: [{pos: Vector3, radius: float}]. combo: the sword's swing number (the last one spins).
static func melee_hits(origin: Vector3, dir: Vector3, targets: Array, weapon_id: int, combo: int = 0) -> Array:
	var w := stats(weapon_id)
	if w.is_empty() or w.kind != MELEE:
		return []
	var finisher := base_of(weapon_id) == ItemIds.SWORD and combo == COMBO_STEPS - 1
	var arc := 180.0 if finisher else float(w.arc)
	var reach := float(w.reach)
	var near: Array = []
	for t: Dictionary in targets:
		if origin.distance_to(t.pos) <= reach + float(t.radius) + 1.0:
			near.append(t.pos)
	var aim := aim_assist(origin, dir, near, reach + 1.0, ASSIST_ANGLE, true)
	var hits: Array = []
	for i in targets.size():
		var t: Dictionary = targets[i]
		if in_cone(origin, aim, t.pos, reach, arc, float(t.radius)):
			hits.append(i)
	hits.sort_custom(func(a: int, b: int) -> bool:
		return origin.distance_to(targets[a].pos) < origin.distance_to(targets[b].pos))
	return hits.slice(0, int(w.max_hits))


## Host check: is a hit on `target` within the weapon's reach (plus latency slack)?
static func hit_in_reach(origin: Vector3, target: Vector3, weapon_id: int, radius: float = 0.0) -> bool:
	var w := stats(weapon_id)
	return not w.is_empty() and origin.distance_to(target) <= float(w.reach) + radius + REACH_TOLERANCE


## Host check: may a player attack with this weapon now? last_ms < 0 means never attacked.
static func cooldown_ok(last_ms: int, now_ms: int, weapon_id: int) -> bool:
	var w := stats(weapon_id)
	if w.is_empty():
		return false
	return last_ms < 0 or now_ms - last_ms >= float(w.cooldown) * 1000.0 * COOLDOWN_SLACK


## The sword's next swing number: 0, 1, 2 (the spin) while swings follow quickly; other weapons 0.
static func combo_next(weapon_id: int, previous: int, since_last: float) -> int:
	if base_of(weapon_id) != ItemIds.SWORD or since_last > COMBO_WINDOW:
		return 0
	return (previous + 1) % COMBO_STEPS


## The sword's spinning finisher and a thrown spear (combo THROW) hit harder and push further.
static func combo_bonus(weapon_id: int, combo: int) -> float:
	var base := base_of(weapon_id)
	if base == ItemIds.SWORD and combo == COMBO_STEPS - 1:
		return FINISHER_BONUS
	if base == ItemIds.SPEAR and combo == THROW:
		return SPEAR_THROW_BONUS
	return 1.0


## Damage dealt to a thing of `kind` (0 for players, buddies and the bullseye).
## power scales it for arrows (the draw).
static func damage_to(kind: StringName, weapon_id: int, combo: int = 0, power: float = 1.0) -> int:
	var w := stats(weapon_id)
	if w.is_empty() or not _DAMAGEABLE.has(kind):
		return 0
	return maxi(roundi(int(w.damage) * combo_bonus(weapon_id, combo) * clampf(power, MIN_DRAW, 1.0)), 1)


## Push velocity for a thing at `to` hit from `from`: away on the ground plane, and up a little.
static func knockback(from: Vector3, to: Vector3, weapon_id: int, combo: int = 0) -> Vector3:
	var w := stats(weapon_id)
	if w.is_empty():
		return Vector3.ZERO
	var away := Vector3(to.x - from.x, 0.0, to.z - from.z)
	away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	var force := float(w.knockback) * combo_bonus(weapon_id, combo)
	return away * force + Vector3.UP * (force * LIFT + 1.0)


# --- Arrows ---

## Draw power 0.3..1 after holding the bow for `held` seconds.
static func draw_power(held: float) -> float:
	return lerpf(MIN_DRAW, 1.0, clampf(held / DRAW_TIME, 0.0, 1.0))


static func arrow_velocity(dir: Vector3, power: float) -> Vector3:
	return dir.normalized() * ARROW_SPEED * clampf(power, MIN_DRAW, 1.0)


## One step of arrow flight under gravity (a thrown spear uses it too, with SPEAR_GRAVITY). Stops at
## the first solid block along the way: {pos, vel, stuck, cell} (cell: the block it stuck in).
static func arrow_step(pos: Vector3, vel: Vector3, delta: float, is_solid: Callable, gravity: float = ARROW_GRAVITY) -> Dictionary:
	var next_vel := vel + Vector3.DOWN * gravity * delta
	var move := (vel + next_vel) * 0.5 * delta
	var dist := move.length()
	if dist > 0.0001:
		var hit := GridRay.cast(pos, move, dist, is_solid)
		if hit:
			return {"pos": pos + move / dist * hit.distance, "vel": move / delta, "stuck": true, "cell": hit.position}
	return {"pos": pos + move, "vel": next_vel, "stuck": false, "cell": Vector3i.ZERO}


## Launch direction that lobs an arrow at `speed` from `from` onto `to` (the low arc). Out of range:
## the 45-degree shot towards it.
static func launch_direction(from: Vector3, to: Vector3, speed: float, gravity: float = ARROW_GRAVITY) -> Vector3:
	var d := to - from
	var flat := Vector3(d.x, 0.0, d.z)
	var x := flat.length()
	if x < 0.01:
		return Vector3.UP if d.y >= 0.0 else Vector3.DOWN
	var v2 := speed * speed
	var disc := v2 * v2 - gravity * (gravity * x * x + 2.0 * d.y * v2)
	var tan_angle := 1.0 if disc < 0.0 else (v2 - sqrt(disc)) / (gravity * x)
	return (flat / x + Vector3.UP * tan_angle).normalized()


## Where a segment p0 -> p1 crosses a disc (the bullseye face), or Vector3.INF.
static func segment_hits_disc(p0: Vector3, p1: Vector3, center: Vector3, normal: Vector3, radius: float) -> Vector3:
	var d := p1 - p0
	var denom := d.dot(normal)
	if absf(denom) < 0.00001:
		return Vector3.INF
	var t := (center - p0).dot(normal) / denom
	if t < 0.0 or t > 1.0:
		return Vector3.INF
	var hit := p0 + d * t
	return hit if hit.distance_to(center) <= radius else Vector3.INF


## Where along p0 -> p1 (0..1) it passes within `radius` of `center`, or -1.
static func segment_hits_sphere(p0: Vector3, p1: Vector3, center: Vector3, radius: float) -> float:
	var d := p1 - p0
	var len2 := d.length_squared()
	var t := 0.0 if len2 < 0.000001 else clampf((center - p0).dot(d) / len2, 0.0, 1.0)
	return t if (p0 + d * t).distance_to(center) <= radius else -1.0


# --- Boomerang ---

## Flight state: flies out along `dir` (pitch limited to BOOMERANG_MAX_PITCH) for the weapon's reach, then homes
## back onto the thrower and is caught.
## Seconds from a throw to the catch when nothing turns it back: out to its reach, then home a little faster.
static func boomerang_round_trip() -> float:
	var reach := float(stats(ItemIds.BOOMERANG).reach)
	return reach / BOOMERANG_SPEED + reach / (BOOMERANG_SPEED * BOOMERANG_RETURN_FACTOR)


static func boomerang_start(origin: Vector3, dir: Vector3) -> Dictionary:
	var d := dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	var flat := Vector2(d.x, d.z)
	if flat.length() < 0.001:
		flat = Vector2(0.0, -1.0)                     # thrown straight up or down: forwards
	var y := clampf(d.y, -BOOMERANG_MAX_PITCH, BOOMERANG_MAX_PITCH)
	var h := flat.normalized() * sqrt(1.0 - y * y)
	return {"pos": origin, "dir": Vector3(h.x, y, h.y), "t": 0.0, "out": 0.0, "returning": false, "caught": false}


## One step. On the way out a solid block turns it back; on the way back it flies through
## everything (it always comes home), and it is caught near the thrower or after BOOMERANG_MAX_TIME.
static func boomerang_step(state: Dictionary, thrower: Vector3, delta: float, is_solid: Callable) -> Dictionary:
	var s := state.duplicate()
	s.t = float(s.t) + delta
	if s.caught:
		return s
	if not s.returning:
		var step := BOOMERANG_SPEED * delta
		if GridRay.cast(s.pos, s.dir, step, is_solid) != null:
			s.returning = true
		else:
			s.pos = (s.pos as Vector3) + (s.dir as Vector3) * step
			s.out = float(s.out) + step
			if float(s.out) >= float(stats(ItemIds.BOOMERANG).reach) or float(s.t) >= BOOMERANG_MAX_TIME * 0.5:
				s.returning = true
		return s
	var to := thrower - (s.pos as Vector3)
	var move := BOOMERANG_SPEED * BOOMERANG_RETURN_FACTOR * delta
	if to.length() <= maxf(move, BOOMERANG_CATCH) or float(s.t) >= BOOMERANG_MAX_TIME:
		s.pos = thrower
		s.caught = true
	else:
		s.pos = (s.pos as Vector3) + to.normalized() * move
	return s


# --- Practice targets ---

## Bullseye rings: 10 in the middle down to 1 at the rim; 0 is a miss.
static func bullseye_score(offset: float, radius: float) -> int:
	if offset > radius:
		return 0
	return maxi(10 - int(offset / radius * 10.0), 1)


## A dummy or bullseye (two blocks tall) stands in `cell`: both cells empty air, solid ground below.
## block_at(pos: Vector3i) -> int.
static func target_spot_ok(cell: Vector3i, block_at: Callable) -> bool:
	return block_at.call(cell) == BlockIds.AIR and block_at.call(cell + Vector3i.UP) == BlockIds.AIR \
		and BlockIds.is_solid(block_at.call(cell + Vector3i.DOWN))


# --- Tiers, spear, mace and shields (M2 Task 6, spec §12.6, §13.1) ---------------------------------

const TIER_WOOD := 0
const TIER_STONE := 1
const TIER_IRON := 2
const TIER_CRYSTAL := 3
const TIER_COSMIC := 4
const TIER_NAMES: Array[String] = ["Wood", "Stone", "Iron", "Crystal", "Cosmic"]
## Damage and dig power per tier.
const TIER_MULTIPLIERS: Array[float] = [1.0, 1.5, 2.0, 3.0, 4.5]
## Every tiered kind, wood to cosmic. The first (wood) item is the kind: its stats, model and
## behaviour are every tier's (the M1b sword, bow, pickaxe and axe are the wood tier).
const TIERS := {
	ItemIds.SWORD: [ItemIds.SWORD, ItemIds.SWORD_STONE, ItemIds.SWORD_IRON, ItemIds.SWORD_CRYSTAL, ItemIds.SWORD_COSMIC],
	ItemIds.BOW: [ItemIds.BOW, ItemIds.BOW_STONE, ItemIds.BOW_IRON, ItemIds.BOW_CRYSTAL, ItemIds.BOW_COSMIC],
	ItemIds.PICKAXE: [ItemIds.PICKAXE, ItemIds.PICKAXE_STONE, ItemIds.PICKAXE_IRON, ItemIds.PICKAXE_CRYSTAL, ItemIds.PICKAXE_COSMIC],
	ItemIds.AXE: [ItemIds.AXE, ItemIds.AXE_STONE, ItemIds.AXE_IRON, ItemIds.AXE_CRYSTAL, ItemIds.AXE_COSMIC],
	ItemIds.SPEAR: [ItemIds.SPEAR, ItemIds.SPEAR_STONE, ItemIds.SPEAR_IRON, ItemIds.SPEAR_CRYSTAL, ItemIds.SPEAR_COSMIC],
	ItemIds.MACE: [ItemIds.MACE, ItemIds.MACE_STONE, ItemIds.MACE_IRON, ItemIds.MACE_CRYSTAL, ItemIds.MACE_COSMIC],
	ItemIds.SHIELD_WOOD: [ItemIds.SHIELD_WOOD, ItemIds.SHIELD_STONE, ItemIds.SHIELD_IRON, ItemIds.SHIELD_CRYSTAL, ItemIds.SHIELD_COSMIC],
}

## Shields (passive, ruling 5): the best shield owned takes this share off a blow from the front.
const SHIELD_BLOCK: Array[float] = [0.30, 0.40, 0.55, 0.70, 0.85]
const SHIELD_ARC := 60.0             # degrees each side of where the player faces
const SHIELD_MIN_SIDEWAYS := 0.2     # a blow falling straight down has no side a shield faces

## The spear's throw: hold ATTACK (or tap something beyond the thrust's reach), let go, and it
## flies a short arc, sticks where it lands and waits for its thrower to walk up and take it back.
const THROW := -1                    # the combo value of a throw (damage bonus and animation)
const SPEAR_THROW_SPEED := 17.0
const SPEAR_GRAVITY := 13.0
const SPEAR_THROW_BONUS := 1.5
const SPEAR_THROW_HOLD := 0.3        # seconds ATTACK is held before letting go throws
const SPEAR_THROW_RANGE := 20.0      # a tap on something farther than the thrust reach, up to this, throws
const SPEAR_PICKUP := 1.6            # the thrower walks this close (on the ground plane) to take it back
const SPEAR_PICKUP_RISE := 2.5
const SPEAR_RETURN_TIME := 20.0      # seconds stuck, then it poofs back to its thrower (never lost)
const SPEAR_MAX_FLIGHT := 5.0

## The mace's ground shake: this strong where it lands, nothing beyond MACE_SHAKE_RADIUS.
const MACE_SHAKE := 0.35
const MACE_SHAKE_RADIUS := 8.0
const MACE_IMPACT_AHEAD := 1.8

const _NO_TIER: Array = []
static var _tier_index := {}         # item id -> [kind, tier]
static var _tier_stats := {}         # tier item id -> its (read-only) stats


static func _tier_entry(id: int) -> Array:
	if _tier_index.is_empty():
		for kind: int in TIERS:
			var ids: Array = TIERS[kind]
			for t in ids.size():
				_tier_index[ids[t]] = [kind, t]
	return _tier_index.get(id, _NO_TIER)


## 0 (wood) .. 4 (cosmic), or -1 for things without tiers.
static func tier_of(id: int) -> int:
	var e := _tier_entry(id)
	return int(e[1]) if not e.is_empty() else -1


## The kind (its wood tier) of a tier item; anything else is its own base.
static func base_of(id: int) -> int:
	var e := _tier_entry(id)
	return int(e[0]) if not e.is_empty() else id


static func tier_multiplier(id: int) -> float:
	var t := tier_of(id)
	return TIER_MULTIPLIERS[t] if t >= 0 else 1.0


static func is_shield(id: int) -> bool:
	return base_of(id) == ItemIds.SHIELD_WOOD


## What a player can hold in the hand: weapons, tools and shields (M3 Task 14b: and blasters; 14a: and gadgets).
static func is_holdable(id: int) -> bool:
	return is_weapon(id) or is_shield(id) or BlasterRules.is_blaster(id) or GadgetRules.is_gadget(id)


## How fast a tool's block power works (axe, pickaxe, hammer): its tier's multiplier; 0 without one.
static func dig_power(id: int) -> float:
	return tier_multiplier(id) if stats(id).get("power", &"") != &"" else 0.0


## Seconds between two uses of a tool's block power: a better tier digs faster.
static func power_cooldown(id: int) -> float:
	var power := dig_power(id)
	return float(stats(id).cooldown) / power if power > 0.0 else 0.0


# --- Spear ---

## A tap on a point `distance` away from the chest throws the spear when it is beyond the thrust's
## reach and within the throw's range.
static func wants_throw(id: int, distance: float) -> bool:
	if base_of(id) != ItemIds.SPEAR:
		return false
	return distance > float(stats(id).reach) + 0.5 and distance <= SPEAR_THROW_RANGE


static func spear_throw_velocity(dir: Vector3) -> Vector3:
	var d := dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	return d * SPEAR_THROW_SPEED


## May the thrower standing at `feet` take back the spear stuck at `spear`?
static func can_pick_up(spear: Vector3, feet: Vector3) -> bool:
	var flat := Vector2(spear.x - feet.x, spear.z - feet.z).length()
	return flat <= SPEAR_PICKUP and absf(spear.y - feet.y) <= SPEAR_PICKUP_RISE


# --- Mace ---

## Where a mace swing from `origin` (the chest) along `dir` strikes the ground: ahead, at the feet.
static func mace_impact(origin: Vector3, dir: Vector3) -> Vector3:
	var flat := Vector3(dir.x, 0.0, dir.z)
	flat = flat.normalized() if flat.length() > 0.001 else Vector3.FORWARD
	return Vector3(origin.x, origin.y - 1.0, origin.z) + flat * MACE_IMPACT_AHEAD


## Camera shake felt `distance` away from the impact.
static func shake_strength(distance: float) -> float:
	if distance > MACE_SHAKE_RADIUS:
		return 0.0
	return MACE_SHAKE * (1.0 - distance / MACE_SHAKE_RADIUS)


# --- Shields ---

## The share of a blow a shield blocks (0..0.85). hit_dir: the way the blow travels (from its source
## towards the player); facing: where the player looks. Only blows from the front (within SHIELD_ARC
## of the facing, on the ground plane) are blocked.
static func shield_block(best_shield: int, hit_dir: Vector3, facing: Vector3) -> float:
	if not is_shield(best_shield) or not hit_dir.is_finite() or not facing.is_finite():
		return 0.0
	var toward := Vector2(-hit_dir.x, -hit_dir.z)     # from the player towards the blow's source
	var look := Vector2(facing.x, facing.z)
	if look.length() < 0.001 or toward.length() < 0.001 or toward.length() < SHIELD_MIN_SIDEWAYS * hit_dir.length():
		return 0.0
	if rad_to_deg(absf(look.angle_to(toward))) > SHIELD_ARC:
		return 0.0
	return SHIELD_BLOCK[tier_of(best_shield)]


## The best (highest tier) shield among `ids` (an inventory or a hotbar), or 0.
static func best_shield(ids: Array) -> int:
	var best := 0
	for id: Variant in ids:
		if id is int and is_shield(id) and (best == 0 or tier_of(id) > tier_of(best)):
			best = id
	return best


## A blow of `amount` with `block` taken off: whole hit points now, and the fraction left over for
## the next blow (carry), so small hits are blocked fairly on average. {damage: int, carry: float}
static func shielded_damage(amount: int, block: float, carry: float) -> Dictionary:
	if amount <= 0:
		return {"damage": 0, "carry": carry}
	var owed := amount * (1.0 - clampf(block, 0.0, 1.0)) + clampf(carry, 0.0, 0.999)
	var damage := floori(owed + 0.00001)
	return {"damage": damage, "carry": maxf(owed - damage, 0.0)}
