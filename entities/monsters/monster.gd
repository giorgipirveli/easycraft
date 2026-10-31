class_name Monster
extends CharacterBody3D
## A monster of Green Meadows (M2 Task 4, spec §12.4): a slime (jumper) or a goblin (chaser) of
## level 1-5. The host simulates it with the animals' cost rules: it rests while no player is within
## MonsterRules.ACTIVE_DISTANCE, decides ten times a second (staggered between monsters), shares one
## player lookup per physics frame with every monster and coin, and skips the physics move while it
## stands still. Stealth (M2 Task 5, §12.5): at every look it sees players and bot friends by their
## visibility (StealthRules.sight: 16 blocks × visibility, a 120° view, a clear line) and hears them
## (their movement, and the StealthDirector's log of landings, broken blocks and attacks); its awareness
## (StealthRules.Awareness, `awareness`) goes wander → ? (walks to the noise) → ! (chases and attacks
## what it sees) → search the last known spot for 6 s → wander. While it chases, its creature mind
## picks a fair tactic (M2 Task 18, section at the end). Hidden and knocked-out players, and knocked-out bots,
## are never targets, and it only attacks what it sees. Players are hurt through Session.hurt_player
## (the host decides every heart), bot friends through hurt(n, from): the goblin raises its club for
## MonsterRules.GOBLIN_WINDUP before the swing, the slime hurts on touch. Weapons hit it through the
## CombatDirector (take_hit): a short hit-stop, a squash, a push; at 0 HP it announces `defeated` (the
## MonsterDirector turns that into confetti and coins) and is gone.
## Every peer shows the level looks (shared meshes), the club wind-up, the slime's squash and
## stretch, a squash on every hit, a health bar once hurt and the ? or ! over its head (synced).
## Monsters never change blocks (lead ruling): they only read the world through block_at.

signal defeated(monster: Monster)
## Owner #39: it flew below MonsterRules.VOID_Y with nothing under it (the void): the director puffs it away.
signal lost(monster: Monster)

## WANDER, CHASE (the awareness's "!"), WINDUP (the goblin's club), SUSPICIOUS (walks to a noise: "?"),
## SEARCH (looks around the last known spot: "?").
enum State { WANDER, CHASE, WINDUP, SUSPICIOUS, SEARCH }

## The animals' physics layer: weapon taps find it; players, animals and the world ignore it.
const LAYER := Animal.LAYER
const GRAVITY := 20.0
const ACCEL := 14.0
const FRICTION := 10.0
const AI_INTERVAL := 0.1          # host: decisions ten times a second
const PERCEIVE_EVERY := 0.3       # host: looks for players three times a second (grid rays cost)
const STOP_SHORT := 1.1           # a chasing goblin stops this close to its target and stands still
const PERSONAL_SPACE := 0.9       # moving monsters keep about this far apart
const THINK_MIN := 1.5
const THINK_MAX := 4.5
const HIT_STOP := 0.05            # a hit freezes it for a moment (hit feel), then it flies back
const STUN_TIME := 0.35           # ... and it does not steer while pushed
const MAX_PUSH := 20.0
const STEP_HOP := 1.25            # goblins hop up 1-block steps
const HOP_UP := 6.5               # a slime's hop (m/s up: about a block high)
const HOP_WAIT := 1.4             # a wandering slime rests this long between hops
const HOP_WAIT_CHASE := 0.7
const TOUCH_REACH := 0.7          # a slime touches a player this far past its side
const TOUCH_BOUNCE := 3.0
const CLUB_PUSH := 5.0            # the club pushes the player back a little
const WINDUP_ANGLE := 2.6         # the club arm raised over the head (radians)
const SQUASH_TIME := 0.18
const SOUND_DISTANCE := 20.0
# Stealth (M2 Task 5).
const WARY_SPEED := 0.6           # walking to a noise or searching: this share of the chase speed
const SEARCH_RADIUS := 3.0        # a search stays this close to the spot
const SEARCH_STOPS := 0.4         # ... and stops to look this share of the time
const PERCEIVE_RANGE := StealthRules.SIGHT * StealthRules.HALF_SEEN   # nothing further is seen or heard
const MARK_HEIGHT := 0.75         # the ? or ! floats this far over its head

var kind: StringName = MonsterRules.SLIME
var level := 1
var universe := 1
var wild := true                  # night monsters puff away at sunrise; summoned ones stay
var golden := false               # §12.16 #4: runs away, never hurts; caught, it gives a pile of gold
var last_hit_from := Vector3.INF  # host: where the last hit came from (who caught a golden slime)
var monster_id := ""
var hp := 1                       # synced on change
var max_hp := 1
var winding := false              # synced on change: the goblin's club is going up
var state: State = State.WANDER
## Synced on change: what floats over its head (StealthRules.MARK_*), and whose danger arrow it is
## (the peer id of the player it sees while "!", 0 otherwise).
var alert := StealthRules.MARK_NONE
var alert_peer := 0
## Host: what it knows (StealthRules.Awareness: the state, the spot it goes to, whether it sees its
## target). Named `mind` until M2 Task 18 gave monsters a creature Mind (`mind`, section at the end).
var awareness := StealthRules.Awareness.new()
## block_at(pos: Vector3i) -> int: the host's world, read only (set by the MonsterDirector).
var block_at: Callable

var _body := Node3D.new()         # visual root: squash, stretch and the walking bob
var _arm: Node3D                  # the goblin's club arm (MonsterModels.arm_pivot)
var _bar: Node3D
var _bar_fill: MeshInstance3D
var _rng := RandomNumberGenerator.new()
var _dir := Vector3.ZERO
var _target: Node3D               # a Player or a bot friend (group "bots")
var _clue := Vector3.INF          # the last look: where it heard or half-saw someone
var _best: Node3D                 # ... the nearest one it saw, and how far (squared) they and the clue were
var _best_d := INF
var _clue_d := INF
var _here := Vector3.ZERO         # ... where it stood, its eyes and where it faced (once per look)
var _look_eye := Vector3.ZERO
var _look_facing := Vector3.FORWARD
var _mark: MeshInstance3D         # the ? or ! over its head
var _shown_alert := StealthRules.MARK_NONE
var _think := 0.0
var _cool := 0.0
var _stun := 0.0
var _freeze := 0.0
var _hop := 0.0
var _windup_t := 0.0
var _ai_t := 0.0
var _look_t := 0.0               # a new monster looks at its first decision (looks are staggered like decisions)
var _active := false
var _defeated := false
var _shown_hp := 0                # every peer: the hp last shown (a drop is a hit: squash)
var _squash := 0.0
var _last_pos := Vector3.ZERO
var _was_winding := false
var _walk_t := 0.0
var _recoil := 0.0                # every peer (M5 Task 2): seconds left of its lean back after a hit
var _crouch_t := 0.0              # every peer (M5 Task 2): how long a jumper has been crouching (its wind-up)

## Every spawned player (and where they stand), looked up once per physics frame and shared by all
## monsters and coins.
## Every monster in the tree (host: they keep a little apart), without a group query.
static var _all: Array[Monster] = []
static var _players_frame := -1
static var _players: Array[Player] = []
static var _player_spots: Array[Vector3] = []
## Every bot friend that is up (group "bots"), looked up once per physics frame too (M2 Task 5).
static var _bots_frame := -1
static var _bots: Array[Node3D] = []


## data = {kind, level, id, pos, yaw, wild, universe}
func setup(data: Dictionary) -> void:
	var k := StringName(str(data.get("kind", MonsterRules.SLIME)))
	kind = k if MonsterRules.KINDS.has(k) else MonsterRules.SLIME
	level = MonsterRules.level_of(int(data.get("level", 1)))
	universe = maxi(int(data.get("universe", 1)), 1)
	half = clampi(int(data.get("half", 0)), 0, 2) if kind == MonsterRules.MUMMY else MonsterRules.WHOLE   # M3 Task 2
	wild = bool(data.get("wild", true))
	golden = MonsterRules.can_be_golden(kind) and bool(data.get("golden", false))   # universe 6: golden spore puffs too
	monster_id = str(data.id)
	name = monster_id
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	max_hp = MonsterRules.hp(kind, level, universe, half)
	hp = max_hp
	_shown_hp = hp
	_last_pos = position
	_rng.seed = hash(monster_id)
	_ai_t = _rng.randf() * AI_INTERVAL   # monsters decide on different frames
	_hop = _rng.randf_range(0.2, 0.6)
	_setup_wave(data)   # M2 Task 9
	practice = kind == MonsterRules.SLIME and bool(data.get("practice", false))   # M3 Task 15: the tutorial's
	_build()


func _enter_tree() -> void:
	_all.append(self)


func _exit_tree() -> void:
	_all.erase(self)


func size() -> Vector3:
	return MonsterRules.size_of(kind, level, half)


## Where weapons aim and hit it, and how big it is for them (CombatDirector.hittables).
func hit_center() -> Vector3:
	return global_position + Vector3(0, size().y * 0.5, 0)


## One sphere around hit_center for the whole body: generous (children aim loosely), and big
## enough to take in most of a tall goblin.
func hit_radius() -> float:
	var s := size()
	return clampf(maxf(maxf(s.x, s.z), s.y * 0.8) * 0.5 + 0.1, 0.35, 0.9)


func eye() -> Vector3:
	return global_position + Vector3(0, size().y * 0.8, 0)


## Where it looks (models face -Z).
func facing() -> Vector3:
	return Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))


## The player or bot friend it is after, or null.
func target() -> Node3D:
	return _target if is_instance_valid(_target) else null


func _build() -> void:
	add_to_group(&"monsters")
	collision_layer = LAYER
	collision_mask = 1
	max_slides = 4
	add_child(_body)
	var mi := MeshInstance3D.new()
	mi.mesh = MonsterModels.mesh_for(kind, level, half)
	if golden:
		mi.material_override = Animal.golden_material()   # the one shared gold of golden animals
	_body.add_child(mi)
	_body_mesh = mi   # owner #39: a wisp's body lights up as it winds up
	var arm_mesh := MonsterModels.arm_mesh_for(kind, level, half)
	if arm_mesh:
		_arm = Node3D.new()
		_arm.name = "Arm"
		_arm.position = MonsterModels.arm_pivot_for(kind, level, half)
		var am := MeshInstance3D.new()
		am.mesh = arm_mesh
		_arm.add_child(am)
		_body.add_child(_arm)
	var s := size()
	var box := BoxShape3D.new()
	box.size = Vector3(minf(s.x, 0.9), s.y * 0.95, minf(s.z, 0.9))
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = s.y * 0.475
	add_child(shape)
	_build_bar(s.y)
	_mark = MeshInstance3D.new()
	_mark.name = "AlertMark"
	_mark.position.y = s.y + MARK_HEIGHT
	_mark.visible = false
	_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mark)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	var rare := [".:hp", ".:winding", ".:alert", ".:alert_peer"]   # rare changes: sent with the spawn, then on a change
	if _flyer():
		rare.append(".:perched")   # M3 Task 3: a bat hanging under a ceiling
	for prop in [".:position", ".:rotation"] + rare:
		cfg.add_property(NodePath(prop))
	for prop in rare:
		cfg.property_set_replication_mode(NodePath(prop), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	_build_candy(cfg)   # M3 Task 4: a sneaker's darkness is synced; its shimmer
	sync.replication_config = cfg
	add_child(sync)


## A dark bar with a green fill above the head, hidden until the monster is hurt. It turns to the
## camera by itself (only while shown), so it needs no billboard material of its own.
func _build_bar(height: float) -> void:
	_bar = Node3D.new()
	_bar.name = "HealthBar"
	_bar.position.y = height + 0.35
	_bar.visible = false
	var back := MeshInstance3D.new()
	back.name = "Back"
	back.mesh = MonsterModels.bar_back_mesh()
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar.add_child(back)
	_bar_fill = MeshInstance3D.new()
	_bar_fill.name = "Fill"
	_bar_fill.mesh = MonsterModels.bar_fill_mesh()
	_bar_fill.position.z = 0.02
	_bar_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bar.add_child(_bar_fill)
	add_child(_bar)


# --- Hits (host) ---------------------------------------------------------------------------------

## A weapon hit (CombatDirector, host): damage, a push, a short freeze. A goblin hit during its
## wind-up drops its swing. It turns on whoever hit it. At 0 HP: `defeated`, then it is gone.
func take_hit(damage: int, from: Vector3, knockback: Vector3) -> void:
	if _defeated or not multiplayer.is_server():
		return
	if practice:
		damage = 0   # M3 Task 15: a practice slime bounces off, never beaten (no coins)
	hp = maxi(hp - maxi(damage, 0), 0)
	if knockback.is_finite():
		velocity += knockback.limit_length(MAX_PUSH) * MonsterRules.push_scale(kind)   # M3 Task 2: the mummy
	_freeze = HIT_STOP
	_stun = STUN_TIME
	if state == State.WINDUP:
		_stop_windup()
		_cool = MonsterRules.ATTACK_COOLDOWN * 0.5
	if from.is_finite():
		last_hit_from = from
		_notice(from)
	if perched:
		_wake()                   # M3 Task 3: a hit knocks a resting bat off its perch
	_mind_took_hit(hp == 0)   # M2 Task 18: a lesson for its tactic
	if hp == 0:
		_defeated = true
		defeated.emit(self)
		queue_free()


## A hit: it turns on the player or bot friend nearest to where the hit came from (a melee attacker,
## unless hidden or invisible). Otherwise (an arrow or a spear from far away) it heard the attack: "?"
## and it goes to see where the shot came from (the StealthDirector's log), or where the hit came from.
func _notice(from: Vector3) -> void:
	var best: Node3D = null
	var best_d := MonsterRules.NOTICE + 1.0
	for list: Array in [_players_now(), bots_now(get_tree())]:
		for c: Node3D in list:
			var d := c.global_position.distance_to(from)
			if d < best_d and not _gone(c):
				best_d = d
				best = c
	if best and visibility_of(best) > 0.0:
		_target = best
		awareness.see(best.global_position)
		if state != State.WINDUP:
			state = State.CHASE
	elif not awareness.sees:
		var shot := StealthDirector.last_attack_near(global_position, Time.get_ticks_msec() / 1000.0)
		awareness.hear(shot if shot.is_finite() else from)
	_sync_alert()


# --- Simulation (host) ---------------------------------------------------------------------------

## Cost matters (the animals' lesson, M1b: ~20 bodies simulated in full every step made frames of up
## to 150 ms on the emulator): it rests far from players, decides AI_INTERVAL apart, and skips the
## physics move while it stands still on the ground.
func _physics_process(delta: float) -> void:
	if _defeated or block_at.is_null() or not multiplayer.is_server():
		return
	if global_position.y < SpawnRules.FALL_LIMIT_Y:
		_defeated = true
		queue_free()
		return
	_ai_t -= delta
	var decide := _ai_t <= 0.0
	if decide:
		_ai_t += AI_INTERVAL
		_active = MonsterRules.is_active(global_position, _spots())
	if not _active:
		return                          # resting far from everyone: keeps its spot and pose
	_land_globs(delta)                  # M3 Task 2: the scorpion's spit in flight
	_fly_sparks(delta)                  # owner #39: a wisp's sparks in flight
	if _freeze > 0.0:
		_freeze -= delta                # hit-stop
		return
	if _blast_tick(delta):
		return                          # M3 Task 14b: floating in a bubble
	if _dance_step(delta):              # M3 Task 14a: the Dance Orb: it dances, never walks or attacks
		return
	_cool -= delta
	_stun -= delta
	_think -= delta
	if decide:
		_decide()
	if state == State.WINDUP:
		_windup_t += delta
		if _windup_t >= _windup_time():
			_strike()
	if MonsterRules.behaviour(kind) == MonsterRules.JUMPER:
		_hop_step(delta)
	elif _flyer():
		if not _fly_step(delta):
			return                      # M3 Task 3: hanging from its perch: nothing moves
	else:
		_walk_step(delta)
	_turn(delta)
	if not decide and not _flyer() and is_on_floor() and velocity.is_zero_approx():
		return                          # nothing to move until the next decision
	var before := velocity
	move_and_slide()
	_bounce_off_walls(before)           # M3 Task 4: a gummy bear bounces off walls


## Host, every AI_INTERVAL: look and listen (every PERCEIVE_EVERY), follow what its awareness says (chase
## what it sees, walk to a noise, search the last known spot, or wander), attack what it sees when
## close, and keep off water and cliffs.
func _decide() -> void:
	_mind_tick()   # M2 Task 18
	if not _flyer():
		update_grip()   # M3 Task 3: ice under its feet
	_look_t -= AI_INTERVAL
	if _look_t <= 0.0:
		_look_t += PERCEIVE_EVERY
		_look()
	var t := target()
	if t and (_gone(t) or _flat_distance(t.global_position) > MonsterRules.GIVE_UP):
		_forget()                         # knocked out, gone, or far away: it gives up at once
		t = null
	elif t and awareness.sees:
		awareness.spot = t.global_position     # followed between looks
	if state == State.WINDUP:
		return
	if _flyer():
		_decide_flyer(t)                  # M3 Task 3: the ice bat flies its own way
		return
	if _archer() and awareness.state == StealthRules.Alert.ALERT:
		_decide_archer(t)                 # M3 Task 14b: the goblin archer shoots from cover
		return
	if golden:   # §12.16 #4: it never chases or hurts; it runs from a child close by
		state = State.WANDER
		var away := SurpriseRules.golden_flee(global_position, _spots())
		if away != Vector3.ZERO:
			_dir = away
		elif _think <= 0.0:
			_think = _rng.randf_range(THINK_MIN, THINK_MAX)
			_dir = Vector3.ZERO if _rng.randf() < 0.4 else Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)
		_keep_safe()
		return
	match awareness.state:
		StealthRules.Alert.ALERT:
			state = State.CHASE
			var seeing := t != null and awareness.sees
			if not _tactic_steer(t, seeing):   # M2 Task 18: a fair tactic its mind picked, or straight at it
				_go_to(awareness.spot, seeing)
				if seeing:
					_attack(t)
			elif seeing and _spitter() and tactic != MonsterSpecies.BACK_OFF:
				_attack(t)                    # M3 Task 2: it spits on the way, whatever its tactic
		StealthRules.Alert.SUSPICIOUS:
			state = State.SUSPICIOUS
			_go_to(awareness.spot, false)
		StealthRules.Alert.SEARCH:
			state = State.SEARCH
			_search_around()
		_:
			state = State.WANDER
			if _think <= 0.0:
				_think = _rng.randf_range(THINK_MIN, THINK_MAX)
				_dir = Vector3.ZERO if _rng.randf() < 0.4 else Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)
			_head_for_goal()   # M2 Task 9: a wave monster far from the Totem walks to it
	_mind_defenses()   # M2 Task 8: weak monsters keep away from lanterns
	_keep_safe()


## One look (M2 Task 5): who it sees now and what it hears or half-sees, into its awareness.
func _look() -> void:
	var was := awareness.state
	var seen := perceive()
	if seen:
		if was != StealthRules.Alert.ALERT and kind != MonsterRules.SLIME:
			_sound(MonsterRules.KIND[kind].sound)   # a goblin's growl, a mummy's moan, a scorpion's hiss
		_target = seen
	awareness.update(PERCEIVE_EVERY, seen.global_position if seen else Vector3.INF, _clue, _here)
	_measure_dark()   # M3 Task 4: a candy sneaker hides in the dark
	if awareness.state == StealthRules.Alert.NONE:
		_target = null
	_sync_alert()


## Which player or bot friend this monster sees now: the nearest one (StealthRules.sight at its
## visibility), or null. On the way it notes where it heard or half-saw someone (the clue for "?").
## Knocked-out players and bots, hidden and invisible players are never seen.
func perceive() -> Node3D:
	_clue = Vector3.INF
	_best = null
	_best_d = INF
	_clue_d = INF
	_here = global_position
	_look_eye = eye()
	_look_facing = Vector3.ZERO if perched else facing()   # M3 Task 3: a hanging bat looks all around
	for p in _players_now():
		if not p.knocked_out:
			_consider(p)
	for b in bots_now(get_tree()):
		_consider(b)
	var heard := StealthDirector.heard_at(_here, Time.get_ticks_msec() / 1000.0)
	if heard.is_finite() and heard.distance_squared_to(_here) < _clue_d:
		_clue = heard
	return _best


## One candidate of a look: the nearest one seen so far wins; the nearest heard or half-seen one is the clue.
func _consider(c: Node3D) -> void:
	var pos := c.global_position
	var d := pos.distance_squared_to(_here)
	if d > PERCEIVE_RANGE * PERCEIVE_RANGE:
		return
	if MonsterRules.blind(kind):   # universe 6: a cave crawler never sees: it hears and feels (never one in hiding)
		if not (c is Player and (c as Player).is_hiding()) and d < _best_d \
				and MonsterRules.heard_as_found(kind, sqrt(d), noise_of(c)):
			_best = c
			_best_d = d
		return
	var vis := visibility_of(c)
	if vis > 0.0 and d < _best_d:
		match StealthRules.sight(_look_eye, _look_facing, eye_of(c), vis, _blocks_sight):
			StealthRules.Sight.FULL:
				_best = c
				_best_d = d
				return
			StealthRules.Sight.HALF:
				if d < _clue_d:
					_clue = pos
					_clue_d = d
	var noise := noise_of(c)
	if noise > 0.0 and d <= noise * noise and d < _clue_d:
		_clue = pos
		_clue_d = d


## How visible a player (Player.stealth_visibility) or a bot friend (the light around it, which the
## StealthDirector keeps in its "stealth_light" meta; bots never crouch or hide) is.
static func visibility_of(c: Node3D) -> float:
	if c is Player:
		return (c as Player).stealth_visibility()
	return StealthRules.visibility(float(c.get_meta(&"stealth_light", 1.0)), false, false, false)


## Where a monster looks at: a player's eyes (lower while crouching), a bot friend's chest.
static func eye_of(c: Node3D) -> Vector3:
	if c is Player:
		return (c as Player).stealth_eye()
	if c.has_method(&"chest"):
		return c.call(&"chest")
	return c.global_position + Vector3(0, 1.0, 0)


## How far away its moving is heard (StealthRules.move_noise); nothing from inside a hiding spot.
static func noise_of(c: Node3D) -> float:
	var body := c as CharacterBody3D
	if body == null:
		return 0.0
	var crouching := false
	if c is Player:
		if (c as Player).is_hiding():
			return 0.0
		crouching = (c as Player).crouching
	return StealthRules.move_noise(Vector2(body.velocity.x, body.velocity.z).length(), crouching)


## Knocked out, gone, or a bot friend that is down (it leaves the group "bots").
static func _gone(c: Node3D) -> bool:
	if not is_instance_valid(c) or c.is_queued_for_deletion():
		return true
	if c is Player:
		return not (c as Player).is_spawned() or (c as Player).knocked_out
	return not c.is_in_group(&"bots")


## Its target went into a barrel or closet while it was after them (the StealthDirector says so):
## it goes to `spot`, next to it, and searches there. Fair: it never finds a hidden player.
func saw_hide(who: Node3D, spot: Vector3) -> void:
	if who == target() and awareness.state == StealthRules.Alert.ALERT:
		awareness.saw_hide(spot)
		_sync_alert()


func _forget() -> void:
	_target = null
	awareness.forget()
	_sync_alert()


## What every game shows over its head, and whose danger arrow it is (synced on change).
func _sync_alert() -> void:
	var a := awareness.mark()
	var peer := 0
	var t := target()
	if a == StealthRules.MARK_BANG and t is Player:
		peer = (t as Player).peer_id
	if alert != a:
		alert = a
	if alert_peer != peer:
		alert_peer = peer


## Towards `spot`; a goblin next to a target it sees, level with it, stops a step short (above or
## below it, it keeps going: down a ledge, up a step, until it can reach).
func _go_to(spot: Vector3, seeing: bool) -> void:
	if not spot.is_finite():
		_dir = Vector3.ZERO
		return
	var to := spot - global_position
	to.y = 0.0
	var level_with := absf(spot.y - global_position.y) < 1.0
	if seeing and _spitter():             # M3 Task 2: it keeps its distance, and backs off from a child close by
		if to.length() < MonsterRules.SPIT_TOO_CLOSE:
			_dir = _spread(-to.normalized()) if to.length() > 0.01 else Vector3.ZERO
		else:
			_dir = _spread(to.normalized()) if to.length() > MonsterRules.SPIT_KEEP else Vector3.ZERO
		return
	var melee := kind == MonsterRules.GOBLIN or kind == MonsterRules.MUMMY or kind == MonsterRules.YETI \
		or kind == MonsterRules.SNEAKER \
		or kind == MonsterRules.SPORE_PUFF or kind == MonsterRules.CRAWLER   # M3 Tasks 3 and 4; universe 6
	var stop := STOP_SHORT if seeing and melee and level_with else 0.3
	_dir = _spread(to.normalized()) if to.length() > stop else Vector3.ZERO


## Searching: short walks in every direction around the spot, never far off, with stops to look
## (a standing monster costs no physics move).
func _search_around() -> void:
	var to := awareness.spot - global_position
	to.y = 0.0
	if to.length() > SEARCH_RADIUS:
		_dir = to.normalized()
	elif _think <= 0.0:
		_think = _rng.randf_range(0.6, 1.4)
		_dir = Vector3.ZERO if _rng.randf() < SEARCH_STOPS else Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)


## Moving monsters step a little apart instead of piling onto one spot.
func _spread(dir: Vector3) -> Vector3:
	var push := Vector3.ZERO
	for m in _all:
		if m == self:
			continue
		var away := Vector3(global_position.x - m.global_position.x, 0.0, global_position.z - m.global_position.z)
		var d := away.length()
		if d < PERSONAL_SPACE and d > 0.001:
			push += away / d * (PERSONAL_SPACE - d) / PERSONAL_SPACE
	return (dir + push).normalized() if push != Vector3.ZERO else dir


func _blocks_sight(cell: Vector3i) -> bool:
	return StealthRules.blocks_sight(block_at.call(cell))


## Only what it sees gets attacked (a hidden or invisible target never does).
func _attack(t: Node3D) -> void:
	if _cool > 0.0 or _stun > 0.0 or visibility_of(t) <= 0.0 or practice:   # M3 Task 15: practice never hurts
		return
	if _spitter():                        # M3 Task 2: the tail goes up, then it spits
		if MonsterRules.may_spit(global_position, t.global_position):
			_start_windup()
	elif _thrower():                      # M3 Task 3: the snowball goes up: a smash up close, a throw from afar
		if MonsterRules.strike_lands(global_position, t.global_position, MonsterRules.ATTACK_RANGE) \
				or (MonsterRules.may_throw(global_position, t.global_position) and _throw_aim(t).is_finite()):
			_start_windup()
	elif MonsterRules.winds_up(kind):     # a goblin's club, a mummy's grab
		if MonsterRules.strike_lands(global_position, t.global_position, MonsterRules.ATTACK_RANGE):
			_start_windup()
	elif MonsterRules.strike_lands(global_position, t.global_position, size().x * 0.5 + TOUCH_REACH):
		_cool = MonsterRules.TOUCH_COOLDOWN
		_hurt(t)
		var away := Vector3(global_position.x - t.global_position.x, 0.0, global_position.z - t.global_position.z)
		if is_on_floor():
			velocity = away.normalized() * TOUCH_BOUNCE + Vector3.UP * 3.0   # boing
		_sound(&"squish")


## The end of the wind-up: the club comes down and hits if the target is still close and not hidden.
func _strike() -> void:
	_stop_windup()
	var t := target()
	if _jumper():
		_pounce(t)                        # M5 Task 2: the crouch ends in a pounce (its touch hurts, as before)
		return
	_cool = MonsterRules.ATTACK_COOLDOWN
	if _archer():
		_archer_shoot(t)                  # M3 Task 14b: the arrow flies
		return
	if _spitter():
		_cool = MonsterRules.SPIT_COOLDOWN
		if t and not _gone(t) and visibility_of(t) > 0.0:
			_spit(t)
		return
	if _flyer():
		if kind == MonsterRules.WISP:
			_throw_spark(t)               # owner #39: the wisp's slow spark
		else:
			_start_dive(t)                # M3 Task 3: the bat dives (owner #39: the shadow bat too)
		return
	if _thrower() and t and not _gone(t) and visibility_of(t) > 0.0 \
			and not MonsterRules.strike_lands(global_position, t.global_position, MonsterRules.STRIKE_REACH):
		_cool = MonsterRules.THROW_COOLDOWN   # M3 Task 3: out of reach of a smash: the snowball flies
		_throw(t)
		return
	if t and not _gone(t) and visibility_of(t) > 0.0 \
			and MonsterRules.strike_lands(global_position, t.global_position, MonsterRules.STRIKE_REACH):
		_hurt(t)
		if t is Player:
			var away := Vector3(t.global_position.x - global_position.x, 0.0, t.global_position.z - global_position.z)
			Session.send_knockback((t as Player).peer_id, away.normalized() * CLUB_PUSH + Vector3.UP * 3.0)


func _stop_windup() -> void:
	winding = false
	state = State.CHASE


## Players through the host's hearts (Session.hurt_player); bot friends through their own hurt().
func _hurt(t: Node3D) -> void:
	_mind_landed()   # M2 Task 18
	var amount := MonsterRules.hit(kind, level, universe)
	if t is Player:
		Session.hurt_player((t as Player).peer_id, amount, global_position)
	elif t.has_method(&"hurt"):
		t.call(&"hurt", amount, global_position)


## A goblin walks (hopping up 1-block steps); pushed, it slides and does not steer. On ice it slides (M3
## Task 3: the grip under its feet, looked at every decision).
func _walk_step(delta: float) -> void:
	var speed := _move_speed()
	var g := _ground_grip()
	if _stun > 0.0 or state == State.WINDUP:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * g * delta)
			velocity.z = move_toward(velocity.z, 0.0, FRICTION * g * delta)
	else:
		velocity.x = move_toward(velocity.x, _dir.x * speed, ACCEL * g * delta)
		velocity.z = move_toward(velocity.z, _dir.z * speed, ACCEL * g * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif _dir != Vector3.ZERO and speed > 0.0 and _stun <= 0.0 and is_on_wall() and not _door_ahead() and not _door_at_wall():
		velocity.y = sqrt(2.0 * GRAVITY * STEP_HOP)


## A slime hops: it rests on the ground, then jumps towards where it wants to go.
func _hop_step(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		return
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * 2.0 * _ground_grip() * delta)
	velocity.z = move_toward(velocity.z, 0.0, FRICTION * 2.0 * _ground_grip() * delta)
	if _stun > 0.0 or state == State.WINDUP:
		return                          # pushed, or crouching before a pounce (M5 Task 2)
	_hop -= delta
	if _hop > 0.0:
		return
	if _pounce_due():
		_start_windup()                 # M5 Task 2: it crouches first, every screen sees it (synced `winding`)
		return
	_hop = (HOP_WAIT_CHASE if state == State.CHASE else HOP_WAIT) * _rng.randf_range(0.85, 1.15)
	if _dir == Vector3.ZERO:
		return
	if _door_ahead():
		return                          # M2 Task 8: never onto or over a closed door
	velocity = _dir * _move_speed() + Vector3.UP * MonsterRules.hop_up(kind)   # M3 Task 4: gummies hop higher
	_sound(&"squish", -8.0)


## Chasing at full speed, walking to a noise or searching warily, wandering slowly (M3 Task 14b: slower
## while a blaster's paint or bubble slows it).
func _move_speed() -> float:
	return _base_speed() * blast_speed()


func _base_speed() -> float:
	if golden:   # always a little slower than a walking child
		return SurpriseRules.golden_speed(MonsterRules.speed(kind, level))
	match state:
		State.CHASE:
			return MonsterRules.speed(kind, level)
		State.SUSPICIOUS, State.SEARCH:
			return MonsterRules.speed(kind, level) * WARY_SPEED
		State.WANDER:
			return float(MonsterRules.KIND[kind].wander)
	return 0.0


## Faces where it goes, or its target while it winds up or waits (the last known spot when it no
## longer sees them: it never gives away a hidden player).
func _turn(delta: float) -> void:
	var look := Vector3.ZERO if tactic == MonsterSpecies.BACK_OFF or (kind == MonsterRules.WISP and state == State.CHASE) \
		else _dir   # M2 Task 18: steps back facing you (owner #39: a wisp keeping its distance watches you)
	var t := target()
	if t and (state == State.WINDUP or look == Vector3.ZERO):
		look = (t.global_position if awareness.sees or not awareness.spot.is_finite() else awareness.spot) - global_position
		look.y = 0.0
	if look.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), clampf(8.0 * delta, 0.0, 1.0))


## Never into water or off a cliff: a wanderer turns round, a chaser stops at the edge.
func _keep_safe() -> void:
	if _dir == Vector3.ZERO:
		return
	if _safe_ahead():
		return
	if state == State.WANDER or state == State.SEARCH:
		_dir = -_dir
		_think = 1.0
		if _safe_ahead():
			return
	_dir = Vector3.ZERO


func _safe_ahead() -> bool:
	var speed := MonsterRules.speed(kind, level)
	var reach := speed * 2.0 * MonsterRules.hop_up(kind) / GRAVITY if MonsterRules.behaviour(kind) == MonsterRules.JUMPER \
		else size().z * 0.5 + 0.45 + speed * AI_INTERVAL
	var ahead := global_position + _dir * reach
	return MonsterRules.can_step(Vector3i(Vector3(ahead.x, global_position.y + 0.1, ahead.z).floor()), block_at)


func _is_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(block_at.call(cell))


func _flat_distance(to: Vector3) -> float:
	return Vector2(to.x - global_position.x, to.z - global_position.z).length()


func _sound(sound: StringName, volume_db: float = 0.0) -> void:
	for p in _spots():
		if p.distance_to(global_position) < SOUND_DISTANCE:
			Audio.play(sound, global_position, volume_db)
			return


# --- Looks (every peer) ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	_candy_looks(delta)   # M3 Task 4: the sneaker's darkness and shimmer (on every screen)
	var moved := global_position - _last_pos
	if moved == Vector3.ZERO and hp == _shown_hp and _squash <= 0.0 and not winding and not _was_winding \
			and _recoil <= 0.0 and _body.rotation.x == 0.0 \
			and not _bar.visible and _body.scale == Vector3.ONE and _body.position.y == (size().y if perched else 0.0) \
			and (_arm == null or _arm.rotation.x == 0.0) and alert == _shown_alert and not _mark.visible \
			and (not _flyer() or perched) and perched == _shown_perched:
		return                          # nothing to show: standing still, resting (a bat hanging) or far away
	_update_mark()   # M2 Task 5
	_last_pos = global_position
	if hp < _shown_hp:
		_squash = SQUASH_TIME          # a hit: squash (hit feel), on every peer
		_recoil = CreatureMoves.RECOIL_TIME   # M5 Task 2: and it leans back
		_sound(VoiceRules.monster_hurt(kind), -2.0)   # the audio pass: and a cry
	_shown_hp = hp
	_recoil_look(delta)
	_crouch_t = _crouch_t + delta if winding and _jumper() else 0.0
	var target_scale := Vector3.ONE
	if _squash > 0.0:
		_squash -= delta
		var k := clampf(_squash / SQUASH_TIME, 0.0, 1.0)
		target_scale = Vector3(1.0 + 0.25 * k, 1.0 - 0.3 * k, 1.0 + 0.25 * k)
	elif _crouch_t > 0.0:
		target_scale = CreatureMoves.crouch(_crouch_t / CreatureMoves.POUNCE_WINDUP)   # M5 Task 2: the pounce's wind-up
	elif MonsterRules.behaviour(kind) == MonsterRules.JUMPER and delta > 0.0:
		var stretch := clampf(moved.y / delta * 0.04, -0.2, 0.25)   # up: tall and thin; landing: flat
		target_scale = Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
	if not _body.scale.is_equal_approx(target_scale):   # a transform write costs, even an unchanged one
		_body.scale = target_scale
	if kind == MonsterRules.WISP:
		_animate_wisp(delta)            # owner #39: it bobs, lights up and grows its ring
	elif _flyer():
		_animate_bat(delta)             # M3 Task 3: flapping wings, hanging upside down
	elif _arm:
		_animate_goblin(delta, moved)
	_update_bar()


## The club goes up during the wind-up and comes down fast; the body bobs while walking.
func _animate_goblin(delta: float, moved: Vector3) -> void:
	var angle := MonsterModels.windup_angle(kind)   # M3 Task 2: a mummy's arms, a scorpion's tail
	var goal := angle if winding else 0.0
	var rate := absf(angle) / maxf(MonsterRules.windup(kind), 0.1) if winding else 14.0
	if _arm.rotation.x != goal:
		_arm.rotation.x = move_toward(_arm.rotation.x, goal, rate * delta)
	if winding != _was_winding and MonsterModels.lights_up(kind):   # the glow (M3 Task 3: the yeti's snowball)
		(_arm.get_child(0) as MeshInstance3D).mesh = MonsterModels.arm_mesh_for(kind, level, half, winding)
	if winding and not _was_winding and kind == MonsterRules.CRAWLER:
		Audio.play(&"crawler_chitter", global_position)   # universe 6: its feelers go up, clicking faster
	if _was_winding and not winding and not _archer():   # (an archer's bow twangs with its arrow, BlasterDirector)
		Audio.play(&"spit" if _spitter() else (&"snow_throw" if _thrower() else \
			(&"bubble_pop" if kind == MonsterRules.SPORE_PUFF else &"swing")), global_position)
	_was_winding = winding
	var walking := delta > 0.0 and Vector2(moved.x, moved.z).length() / delta > 0.3
	_walk_t = _walk_t + delta if walking else 0.0
	var bob := absf(sin(_walk_t * 10.0)) * 0.06 if walking else 0.0
	if _body.position.y != bob:
		_body.position.y = bob


func _update_bar() -> void:
	var show := hp > 0 and hp < max_hp
	if _bar.visible != show:
		_bar.visible = show
	if not show:
		return
	var f := clampf(float(hp) / float(max_hp), 0.001, 1.0)
	_bar_fill.scale.x = f
	_bar_fill.position.x = -(1.0 - f) * MonsterModels.BAR_WIDTH * 0.5
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam:
		_bar.global_basis = cam.global_basis


## The ? or ! over its head (shared meshes, AlertMarks), turned to the camera while shown.
func _update_mark() -> void:
	if alert != _shown_alert:
		_shown_alert = alert
		_mark.mesh = AlertMarks.mesh(alert)
		_mark.visible = _mark.mesh != null
	if _mark.visible:
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam:
			_mark.global_basis = cam.global_basis


# --- Players and bot friends, looked up once per physics frame -------------------------------------

## Every monster in the tree (the StealthDirector tells them who went into a hiding spot).
static func all_monsters() -> Array[Monster]:
	return _all


## Every bot friend that is up (group "bots": a knocked-out one leaves it), refreshed once per physics
## frame and shared by all monsters (M2 Task 5).
static func bots_now(tree: SceneTree) -> Array[Node3D]:
	var frame := Engine.get_physics_frames()
	if frame != _bots_frame or not _bots.all(is_instance_valid):
		_bots_frame = frame
		_bots.clear()
		for n in tree.get_nodes_in_group(&"bots"):
			var b := n as Node3D
			if b and not b.is_queued_for_deletion():
				_bots.append(b)
	return _bots

func _players_now() -> Array[Player]:
	return players_now(get_tree())


func _spots() -> Array[Vector3]:
	return player_spots(get_tree())


## Every spawned player, refreshed once per physics frame and shared by all monsters and coins.
static func players_now(tree: SceneTree) -> Array[Player]:
	var frame := Engine.get_physics_frames()
	if frame != _players_frame or not _players.all(is_instance_valid):
		_players_frame = frame
		_players.clear()
		_player_spots.clear()
		for n in tree.get_nodes_in_group(&"players"):
			var p := n as Player
			if p and not p.is_queued_for_deletion() and p.is_spawned():
				_players.append(p)
				_player_spots.append(p.global_position)
	return _players


## Where those players stand (the same frame's lookup).
static func player_spots(tree: SceneTree) -> Array[Vector3]:
	players_now(tree)
	return _player_spots

# --- M2 Task 9: Totem wave monsters ------------------------------------------------------------------

## A wave monster this close to its goal (the Totem) wanders around it like any monster.
const GOAL_NEAR := 4.0

var wave := 0                     # the Totem wave it belongs to (0 = none): it never leaves for distance
var goal := Vector3.INF           # where it heads while it has nobody to chase (the Totem)


func _setup_wave(data: Dictionary) -> void:
	wave = maxi(int(data.get("wave", 0)), 0)
	var g: Variant = data.get("goal", Vector3.INF)
	goal = g if g is Vector3 and (g as Vector3).is_finite() else Vector3.INF


## Host, deciding while it chases nobody: far from its goal, it walks there (keeping apart).
func _head_for_goal() -> void:
	if not goal.is_finite() or _flat_distance(goal) <= GOAL_NEAR:
		return
	var to := goal - global_position
	to.y = 0.0
	_dir = _spread(to.normalized())

# --- M2 Task 8: defenses (doors and lanterns) -------------------------------------------------------

## Host: the lanterns near this monster (weak monsters only), kept up to date by the DefenseDirector.
var lanterns: Array[Vector3i] = []
var _door_state := 0              # the door check of this decision: 0 not made yet, 1 clear, 2 a door
var _wall_door_state := 0         # ... and the one of the wall it presses (_door_at_wall), the same way


## Every decision: a weak monster stops before it would come within 6 blocks of a lantern and walks
## away from one that is closer (DefenseRules.lantern_dir); the door check is made again.
func _mind_defenses() -> void:
	_door_state = 0
	_wall_door_state = 0
	if not lanterns.is_empty():
		_dir = DefenseRules.lantern_dir(global_position, _dir, level, lanterns, _lookahead())


## M3 Task 3: a closed door in the wall it is pressed against, or a block to either side of where it
## presses (a crowd keeping apart slides a walker sideways, so a hop next to a doorway could land on the
## door, found with six walking kinds in test_monster_defenses): near a door it never hops. Every cell of that band and
## under its feet counts (DefenseRules.door_in_way; universe 6's crowd of 20: a door right beside it was skipped).
## Worked out once a decision, like _door_ahead (it is asked every tick while it presses a wall).
func _door_at_wall() -> bool:
	if _wall_door_state == 0:
		var into := -get_wall_normal()
		var r := minf(size().x, 0.9) * 0.5
		_wall_door_state = 2 if DefenseRules.door_in_way(global_position, into, r + 0.6, r + 1.0, block_at, r) else 1
	return _wall_door_state == 2


## How far one decision's move can carry it: a slime's whole hop, or a step and the stop after it.
func _lookahead() -> float:
	var speed := MonsterRules.speed(kind, level)
	if MonsterRules.behaviour(kind) == MonsterRules.JUMPER:
		return speed * 2.0 * MonsterRules.hop_up(kind) / GRAVITY + 0.2
	return speed * (AI_INTERVAL + speed / (2.0 * ACCEL)) + 0.2


## Monsters cannot open doors: a closed door in its way at its feet is never stepped up onto or hopped
## over (DefenseRules.door_in_way). Checked only when it would climb or hop, once per decision.
func _door_ahead() -> bool:
	if _door_state == 0:
		var reach := _lookahead() if MonsterRules.behaviour(kind) == MonsterRules.JUMPER else minf(size().x, 0.9) * 0.5 + 0.6
		_door_state = 2 if DefenseRules.door_in_way(global_position, _dir, reach, minf(size().x, 0.9) * 0.5, block_at) else 1
	return _door_state == 2

# --- M2 Task 18: creature minds (monster tactics; owner feedback #24, spec §12.17) ------------------
# While it chases what it sees, a monster's Mind (MonsterSpecies, its kind's table in this world,
# MindBook) picks a fair, signalled tactic: straight at you, zigzag (a weave), go round to your side
# (a curve), wait by cover (a stop), back off when hurt (a step back), call a friend (a growl or squish:
# a quiet monster near comes with "?"). A tactic only steers: speed, sight, hits and hearts stay
# §12.4/§12.5's, the stealth marks and Task 8's lantern fear and door checks still apply, and within
# TACTIC_NEAR every monster comes straight in to attack as before. Lessons: landing a hit (good); being
# hit, shot from far or defeated (bad). MonsterMinds holds the guards (Cozy: no learning; Sandbox: slow;
# easing off after a child's knock-outs) and the one-time hint. Golden slimes never think. Host only.

const TACTIC_NEAR := 3.0          # this close to its target every tactic comes straight in
const ZIGZAG_ANGLE := 0.8         # radians off the straight line
const ZIGZAG_EVERY := 0.6         # seconds on each side
const ROUND_SIDE := 4.0           # going round aims this far to the child's side
const WAIT_BREAK := 4.0           # a waiting monster that the child comes this close to thinks again
const BACK_OFF_TO := 7.0          # backing off goes no further than this from its target
const BACK_OFF_GAP := 8.0         # and not again for this long (the child can chase it)
const CALL_RADIUS := 12.0
const CALL_FRIENDS := 2
const CALL_GAP := 20.0
const FAR_HIT := 5.0              # a hit with nobody this close came from far (an arrow)
const SHOT_MEMORY := 10.0         # seconds it keeps in mind that it was shot from far
const THREAT_MEMORY := 5.0

## Host: its creature mind (made at its first decision; golden slimes have none) and its tactic
## (MonsterSpecies action, &"" while it isn't chasing what it sees).
var mind: Mind
var tactic := &""
var _tactic_of: Node3D
var _zig_t := 0.0
var _zig_side := 1.0
var _round_side := 1.0
var _wait_spot := Vector3.INF
var _back_t := 0.0
var _call_t := 0.0
var _shot_t := 0.0
var _threat_t := 0.0
var _reached := false


## Host: takes up `name` (a MonsterSpecies tactic) now, as if its mind had picked it (tests, the bench).
func use_tactic(name: StringName, t: Node3D) -> void:
	_mind_ready()
	var i := MonsterSpecies.index(name)
	if mind == null or i < 0 or t == null:
		return
	mind.hold(i)
	_start_tactic(name, t)


func _mind_ready() -> void:
	if mind == null and not golden and not practice:   # M3 Task 15: a practice slime teaches the world's slimes nothing
		var table := MonsterSpecies.table(kind)
		var net := MindBook.current.net_for(table)
		MonsterSpecies.cap(net, universe)
		mind = Mind.create(table, monster_id, net)


func _mind_tick() -> void:
	_mind_ready()
	if mind == null:
		return
	if awareness.state != StealthRules.Alert.ALERT:
		tactic = &""                      # tactics are for a chase
	mind.tick(AI_INTERVAL)
	_zig_t -= AI_INTERVAL
	_back_t -= AI_INTERVAL
	_call_t -= AI_INTERVAL
	_shot_t -= AI_INTERVAL
	_threat_t -= AI_INTERVAL


## Steers by its tactic while it sees its target; false when it just comes straight in (and attacks,
## the caller's usual path): no mind, not seeing, close enough, or the straight tactic.
func _tactic_steer(t: Node3D, seeing: bool) -> bool:
	if mind == null or t == null or not seeing:
		tactic = &""
		return false
	var d := _flat_distance(t.global_position)
	if tactic == &"" or t != _tactic_of or mind.due():
		_pick_tactic(t, d)
	if tactic == MonsterSpecies.BACK_OFF:
		state = State.SUSPICIOUS          # the wary pace (never more than the spec's speed)
		_dir = _spread(-_flat_dir_to(t.global_position)) if d < BACK_OFF_TO else Vector3.ZERO
		return true
	if d <= TACTIC_NEAR:
		tactic = MonsterSpecies.STRAIGHT   # close: in it comes (the lessons still go to the picked approach)
		if not _reached:
			_reached = true
			_lesson(&"reached")
		return false
	match tactic:
		MonsterSpecies.ZIGZAG:
			if _zig_t <= 0.0:
				_zig_t = ZIGZAG_EVERY
				_zig_side = -_zig_side
			_dir = _spread(_flat_dir_to(t.global_position).rotated(Vector3.UP, _zig_side * ZIGZAG_ANGLE))
			return true
		MonsterSpecies.GO_ROUND:
			if d <= ROUND_SIDE + 1.0:
				return false                  # beside the child now: in it comes
			var to := _flat_dir_to(t.global_position)
			var aim := t.global_position + Vector3(-to.z, 0.0, to.x) * _round_side * ROUND_SIDE
			_dir = _spread(_flat_dir_to(aim))
			return true
		MonsterSpecies.WAIT:
			if d < WAIT_BREAK:
				mind.interrupt()              # the child came close: think again
			if _wait_spot.is_finite() and _flat_distance(_wait_spot) > 0.5:
				_dir = _spread(_flat_dir_to(_wait_spot))
			else:
				_dir = Vector3.ZERO           # it waits, facing the child (_turn)
			return true
	return false                          # straight (and after a call)


func _pick_tactic(t: Node3D, d: float) -> void:
	var peer := (t as Player).peer_id if t is Player else 0
	var held: Variant = t.get(&"held_item")
	var weapon := MonsterSpecies.weapon_class(int(held) if held is int else 0)
	var facing := _faces_me(t)
	var health := float(hp) / float(maxi(max_hp, 1))
	var friend := _quiet_friend() != null
	var s := mind.senses
	s.fill(0.0)
	s[MonsterSpecies.S_NEAR] = clampf(1.0 - d / 16.0, 0.0, 1.0)
	s[MonsterSpecies.S_FACING] = 1.0 if facing else 0.0
	s[MonsterSpecies.S_RANGED] = 1.0 if weapon == MonsterSpecies.RANGED else 0.0
	s[MonsterSpecies.S_MELEE] = 1.0 if weapon == MonsterSpecies.MELEE else 0.0
	s[MonsterSpecies.S_HEALTH] = health
	s[MonsterSpecies.S_KIN] = 1.0 if friend else 0.0
	s[MonsterSpecies.S_THREAT] = 1.0 if _threat_t > 0.0 else 0.0
	s[MonsterSpecies.S_SHOT] = 1.0 if _shot_t > 0.0 else 0.0
	var mask := MonsterSpecies.allowed(d, weapon == MonsterSpecies.RANGED, facing, health, _call_t > 0.0, friend)
	if _back_t > 0.0:
		mask &= ~MonsterSpecies.bit(MonsterSpecies.BACK_OFF)
	mask = MonsterMinds.current.restrict(mask, peer, mind.roll())
	mind.learning = MonsterMinds.current.learning(peer)
	_start_tactic(MonsterSpecies.ACTIONS[mind.think(mask)], t)


func _start_tactic(name: StringName, t: Node3D) -> void:
	var fresh := t != _tactic_of
	tactic = name
	_tactic_of = t
	if fresh:
		_reached = false
	match name:
		MonsterSpecies.ZIGZAG:
			_zig_side = 1.0 if mind.roll() < 0.5 else -1.0
			_zig_t = ZIGZAG_EVERY * 0.5
		MonsterSpecies.GO_ROUND:
			# round the side it is on already (from where the child looks)
			var to_me := global_position - t.global_position
			var look := _facing_of(t)
			_round_side = 1.0 if look.x * to_me.z - look.z * to_me.x >= 0.0 else -1.0
		MonsterSpecies.WAIT:
			_wait_spot = _cover_spot(t.global_position)
		MonsterSpecies.BACK_OFF:
			_back_t = BACK_OFF_GAP
		MonsterSpecies.CALL:
			_call_t = CALL_GAP
			_call_friends(t)


## A spot two blocks away with a solid block between it and the child at eye height (cover), or INF.
func _cover_spot(from: Vector3) -> Vector3:
	var here := Vector3i(global_position.floor())
	var toward := _flat_dir_to(from)
	var step := Vector3i(roundi(toward.x), 0, roundi(toward.z))
	for i in 8:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, i * TAU / 8.0)
		var feet := here + Vector3i(roundi(dir.x * 2.0), 0, roundi(dir.z * 2.0))
		if _is_solid(feet) or _is_solid(feet + Vector3i.UP) or not _is_solid(feet + Vector3i.DOWN):
			continue
		if _is_solid(feet + step + Vector3i.UP):
			return Vector3(feet.x + 0.5, feet.y, feet.z + 0.5)
	return Vector3.INF


## A call: a growl (goblin) or a squish (slime) the child hears, and up to CALL_FRIENDS quiet monsters
## near come to see (their "?", never straight to "!").
func _call_friends(t: Node3D) -> void:
	_sound(MonsterRules.KIND[kind].sound)
	var answered := 0
	for m in _all:
		if answered >= CALL_FRIENDS:
			break
		if m == self or m.golden or m._defeated or m.awareness.state != StealthRules.Alert.NONE:
			continue
		if m.global_position.distance_to(global_position) <= CALL_RADIUS:
			m.awareness.hear(t.global_position)
			m._sync_alert()
			answered += 1
	if answered > 0:
		_lesson(&"answered")


func _quiet_friend() -> Monster:
	for m in _all:
		if m != self and not m.golden and not m._defeated and m.awareness.state == StealthRules.Alert.NONE \
				and m.global_position.distance_squared_to(global_position) <= CALL_RADIUS * CALL_RADIUS:
			return m
	return null


## Does the child (or bot) look its way?
func _faces_me(t: Node3D) -> bool:
	var to_me := global_position - t.global_position
	to_me.y = 0.0
	return to_me.length() > 0.01 and _facing_of(t).dot(to_me.normalized()) > 0.7


static func _facing_of(t: Node3D) -> Vector3:
	var yaw := t.rotation.y
	if t is Player and (t as Player).avatar:
		yaw = (t as Player).avatar.rotation.y
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _flat_dir_to(p: Vector3) -> Vector3:
	var v := Vector3(p.x - global_position.x, 0.0, p.z - global_position.z)
	return v.normalized() if v.length() > 0.01 else Vector3.ZERO


## Landing a hit: its tactic worked.
func _mind_landed() -> void:
	if mind and tactic != &"":
		_lesson(&"landed")


## A hit (or its defeat): a lesson for the tactic it was using. Nobody close means an arrow from far.
func _mind_took_hit(out: bool) -> void:
	if mind == null:
		return
	var far := true
	for list: Array in [_players_now(), bots_now(get_tree())]:
		for c: Node3D in list:
			if c.global_position.distance_to(global_position) <= FAR_HIT:
				far = false
	if far:
		_shot_t = SHOT_MEMORY
	_threat_t = THREAT_MEMORY
	if tactic != &"" or out:
		_lesson(&"defeated" if out else (&"shot" if far else &"hit"))
	mind.interrupt()


## A lesson from `event` (MonsterSpecies.REWARDS) for its last tactic, as much as the guards allow for
## its target (MonsterMinds: Cozy, Sandbox, easing off); then, has this world's table learned something
## to tell the children (once)?
func _lesson(event: StringName) -> void:
	var t := target()
	mind.learning = MonsterMinds.current.learning((t as Player).peer_id if t is Player else 0)
	mind.feel(event)
	MonsterMinds.current.check_hints(kind, mind.net)

# --- M3 Task 2: the Sandstorm Desert's mummy and scorpion ------------------------------------------------
# The mummy is a slow tank (MonsterRules: more health, a longer wind-up for its grab, a smaller push) and
# walks like a goblin; at level 3+ the director unwraps it into a crawling top and walking legs (`half`).
# The scorpion is a spitter: it keeps SPIT_KEEP from what it sees and backs off from a child close by;
# its wind-up raises a glowing tail (synced `winding`), then a glob flies to where the child will be
# (MonsterRules.spit_aim: it leads a runner a little). Every game flies the same glob (SpitGlob, by RPC);
# the host decides who it hits when it lands. Nothing here changes a block.

## WHOLE, or one of a mummy's halves (MonsterRules.HALF_TOP / HALF_LEGS); in the spawn data.
var half := 0
var _globs: Array = []            # host: [seconds until it lands, where]


func _spitter() -> bool:
	return MonsterRules.behaviour(kind) == MonsterRules.SPITTER


func _start_windup() -> void:
	state = State.WINDUP
	winding = true
	_windup_t = 0.0
	_dir = Vector3.ZERO


## Host: globs thrown that have not landed yet (tests).
func globs_in_flight() -> int:
	return _globs.size()


## Host: where glob `i` will land (tests).
func glob_landing(i: int) -> Vector3:
	return _globs[i][1] if i >= 0 and i < _globs.size() else Vector3.INF


## Where the glob leaves the tail's tip.
func stinger() -> Vector3:
	return global_position + (Vector3(0, 0.75, 0.2) * MonsterRules.size_scale(level)).rotated(Vector3.UP, rotation.y)


func _spit(t: Node3D) -> void:
	var vel := (t as CharacterBody3D).velocity if t is CharacterBody3D else Vector3.ZERO
	var from := stinger()
	var to := MonsterRules.spit_aim(from, t.global_position, vel)
	_globs.append([MonsterRules.spit_time(from, to), to])
	_rpc_spit.rpc(from, to)


func _land_globs(delta: float) -> void:
	if _globs.is_empty():
		return
	for g: Array in _globs.duplicate():
		g[0] -= delta
		if g[0] > 0.0:
			continue
		_globs.erase(g)
		for list: Array in [_players_now(), bots_now(get_tree())]:
			for c: Node3D in list:
				if _gone(c):
					continue
				if MonsterRules.snowball_hits(g[1], c.global_position, _is_solid) if _thrower() \
						else MonsterRules.spit_hits(g[1], c.global_position):   # M3 Task 3: never through a wall
					_hurt(c)


## A glob leaves the tail (every game flies the same one).
@rpc("authority", "call_local", "reliable")
func _rpc_spit(from: Vector3, to: Vector3) -> void:
	if not (from.is_finite() and to.is_finite()):
		return
	var g := SpitGlob.new()
	g.setup(from, to)
	add_child(g)

# --- M3 Task 3: Frostpeak's yeti and ice bat ------------------------------------------------------------
# The yeti is a tank (MonsterRules: much health, a long wind-up, a small push) that walks like a mummy. Its
# wind-up lifts a snowball over its head (a second shared arm mesh, like the scorpion's glowing tail): up
# close it smashes it down (a club's hit), from afar it throws it where the child will be (the scorpion's
# lead, MonsterRules.throw_aim): never through a wall, and it hits only where it lands and only with a clear
# line (MonsterRules.snowball_hits). Every game flies the same snowball (SpitGlob with its look, by RPC).
# The ice bat is the flyer: no gravity, no navmesh. Ten times a second it picks a point to fly to (over the
# ground while it wanders, over the side of a child it chases) and steers there; next to that point it hovers
# and flaps hard with glowing wings (the wind-up), then dives in a straight line at where the child stood
# (a sidestep dodges it), stays low for a moment (swords reach it) and climbs back. Tired, it hangs under a
# ceiling or a branch (synced `perched`: upside down, no physics move) until it sees or hears a child, or is
# hit. Weak bats keep away from lanterns like the walkers do. Nothing here changes a block.

const FLAP := 0.09                # seconds per wing frame (twice as fast while it signals a dive)

## Synced on change: an ice bat hanging from its perch.
var perched := false
var _shown_perched := false
var _flight := &"fly"             # host, a bat: &"fly", &"perching", &"dive", &"low"
var _fly_goal := Vector3.INF      # host: where it flies to (decided ten times a second)
var _fly_t := -1.0                # host: seconds of flying before it gets tired (-1: not drawn yet)
var _rest_t := 0.0
var _perch_at := Vector3.INF
var _dive_to := Vector3.INF
var _dive_t := 0.0
var _low_t := 0.0
var _dived := {}                  # instance ids a dive already hit
var _wander_dir := Vector3.ZERO
var _ground := NAN                # host, a bat: the ground's height under it (ground_below)
var _ground_t := 0.0
var _flap_t := 0.0
var _shown_frame := -1


func _flyer() -> bool:
	return MonsterRules.behaviour(kind) == MonsterRules.FLYER


var _grip := -1.0                 # host: the grip under its feet (FrostRules), -1 until first looked at


## Host: looks at the ground under its feet (ice is slippery: FrostRules.grip_at; every decision).
func update_grip() -> void:
	_grip = FrostRules.grip_at(global_position, block_at) if block_at.is_valid() else 1.0


func _ground_grip() -> float:
	if _grip < 0.0:
		update_grip()
	return _grip


func _thrower() -> bool:
	return kind == MonsterRules.YETI


## Tests and tools: a bat that has flown long enough to want a rest.
func tire() -> void:
	_fly_t = 0.0


## Where the yeti's snowball leaves its hands (held over its head).
func hand() -> Vector3:
	return global_position + (Vector3(0, MonsterRules.HAND_HEIGHT, -0.2) * MonsterRules.size_scale(level)).rotated(Vector3.UP, rotation.y)


func _throw_aim(t: Node3D) -> Vector3:
	var vel := (t as CharacterBody3D).velocity if t is CharacterBody3D else Vector3.ZERO
	return MonsterRules.throw_aim(hand(), t.global_position, vel, _is_solid)


func _throw(t: Node3D) -> void:
	var to := _throw_aim(t)
	if not to.is_finite():
		return                            # the child went behind a wall during the wind-up
	var from := hand()
	_globs.append([MonsterRules.spit_time(from, to), to])
	_rpc_snowball.rpc(from, to)


## A snowball leaves the yeti's hands (every game flies the same one).
@rpc("authority", "call_local", "reliable")
func _rpc_snowball(from: Vector3, to: Vector3) -> void:
	if not (from.is_finite() and to.is_finite()):
		return
	var g := SpitGlob.new()
	g.look = MonsterModels.snowball_mesh()
	g.splat = MonsterModels.SNOWBALL
	g.sound = &"snow_splat"
	g.setup(from, to)
	add_child(g)


# --- The flyer (host) ---

## Every AI_INTERVAL: rest on its perch, or pick where to fly: over a child's side (and signal a dive when it
## is there), towards a noise, round the last known spot, or wandering over the ground; tired, to a perch.
func _decide_flyer(t: Node3D) -> void:
	if _fly_t < 0.0:
		_fly_t = _rng.randf_range(MonsterRules.BAT_FLY_TIME.x, MonsterRules.BAT_FLY_TIME.y)
	var here := global_position
	if perched:
		_rest_t -= AI_INTERVAL
		if awareness.state == StealthRules.Alert.NONE and _rest_t > 0.0:
			return
		_wake()
	if _flight == &"dive" or _flight == &"low":
		return                            # the step flies these
	_fly_t -= AI_INTERVAL
	_ground_t -= AI_INTERVAL
	if _ground_t <= 0.0 or not is_finite(_ground):
		_ground_t = PERCEIVE_EVERY        # the ground under it and ahead, three times a second (block reads)
		_ground = MonsterRules.ground_below(here, _is_solid)
		_void = MonsterRules.over_void(here, _ground)   # owner #39: floating islands over the void
		if not _void:
			_home = here
		elif MonsterRules.lost_in_void(here, _ground):
			_lose()
			return
		_void_ahead = false
		if _dir != Vector3.ZERO:          # a hill ahead: rise over it instead of pressing into it
			var ahead := here + _dir * 1.5 + Vector3(0, 2, 0)
			var ahead_ground := MonsterRules.ground_below(ahead, _is_solid)
			_void_ahead = MonsterRules.over_void(ahead, ahead_ground)
			if not _void_ahead:
				_ground = maxf(_ground, ahead_ground)
	# Over the void it keeps its height (never sinks into it): its "ground" is its cruise height under it.
	var ground := here.y - MonsterRules.cruise_height(kind) if _void else _ground
	var aim_at := Vector3.INF
	if _flight == &"away":                # owner #39: a shadow bat resting up and away after its swoop
		_away_t -= AI_INTERVAL
		if _away_t > 0.0 and _away_at.is_finite():
			_fly_goal = _lantern_goal(here, _away_at)
			var to := Vector3(_fly_goal.x - here.x, 0.0, _fly_goal.z - here.z)
			_dir = to.normalized() if to.length() > 0.2 else Vector3.ZERO
			return
		_flight = &"fly"
	match awareness.state:
		StealthRules.Alert.ALERT:
			state = State.CHASE
			var seeing := t != null and awareness.sees
			var feet: Vector3 = t.global_position if seeing else awareness.spot
			if _dragon_flyer():
				aim_at = _dragon_aim(t if seeing else null, feet, here)   # owner #39: its spot, steered by its mind
				if seeing and _ready_to_attack(t, here, aim_at):
					_start_windup()
					return
			else:
				aim_at = _hover_at(feet, here)
				if seeing and _ready_to_dive(t, here, aim_at):
					_start_windup()
					return
		StealthRules.Alert.SUSPICIOUS:
			state = State.SUSPICIOUS
			aim_at = Vector3(awareness.spot.x, ground + MonsterRules.cruise_height(kind), awareness.spot.z)
		StealthRules.Alert.SEARCH:
			state = State.SEARCH
			if _think <= 0.0:
				_think = _rng.randf_range(0.8, 1.6)
				_wander_dir = Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)
			var spot := awareness.spot + _wander_dir * MonsterRules.BAT_CIRCLE
			aim_at = Vector3(spot.x, ground + MonsterRules.cruise_height(kind), spot.z)
		_:
			state = State.WANDER
			aim_at = _wander_goal(here, ground)
	if _flight == &"perching" and awareness.state != StealthRules.Alert.NONE:
		_flight = &"fly"
	_fly_goal = _lantern_goal(here, aim_at)
	var flat := Vector3(_fly_goal.x - here.x, 0.0, _fly_goal.z - here.z)
	_dir = flat.normalized() if flat.length() > 0.2 else Vector3.ZERO


## Wandering: now and then a new way to flutter, over the ground; a wave bat heads for its Totem; a tired
## one flies to a ceiling or a branch above it, when there is one.
func _wander_goal(here: Vector3, ground: float) -> Vector3:
	if _flight == &"perching" and _perch_at.is_finite():
		return _perch_at
	if _fly_t <= 0.0 and _ground_t >= PERCEIVE_EVERY - 0.01 and kind != MonsterRules.WISP:   # (a wisp never rests)
		var perch := MonsterRules.perch_spot(here, _is_solid, size().y)
		if perch.is_finite():
			_perch_at = perch
			_flight = &"perching"
			return perch
	if _think <= 0.0:
		_think = _rng.randf_range(THINK_MIN, THINK_MAX)
		_wander_dir = Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)
	if _void and _home.is_finite():       # owner #39: out over the void: back to the last ground it flew over
		var back := _flat_dir_to(_home)
		if back != Vector3.ZERO:
			_wander_dir = back
	elif _void_ahead:                     # ... and it turns round at the island's edge
		_void_ahead = false
		_wander_dir = -_dir if _dir != Vector3.ZERO else -_wander_dir
		_think = maxf(_think, THINK_MIN)
	var ahead := here + _wander_dir * 2.0
	if goal.is_finite() and _flat_distance(goal) > GOAL_NEAR:
		ahead = here + _flat_dir_to(goal) * 2.0   # M2 Task 9: a wave monster far from the Totem flies to it
	return Vector3(ahead.x, ground + MonsterRules.cruise_height(kind), ahead.z)


## Where it hovers over a child whose feet are at `feet`: MonsterRules.hover_spot on its own side; when a hill
## or a wall fills that spot, a quarter turn round the child (up to three), then right over them (found by
## the smoke run on real terrain: a spot inside a hill was never reached, so the bat never dived).
func _hover_at(feet: Vector3, here: Vector3) -> Vector3:
	return _open_side(feet, MonsterRules.hover_spot(feet, here))


## `spot` (beside and above a child at `feet`), or a quarter turn round them when a hill or a wall fills it (up to
## three), else right over them at the same height (owner #39: the wisp's spot too).
func _open_side(feet: Vector3, spot: Vector3) -> Vector3:
	var side := Vector3(spot.x - feet.x, 0.0, spot.z - feet.z)
	var up := Vector3(0, spot.y - feet.y, 0)
	for i in 4:
		var s := feet + side.rotated(Vector3.UP, PI * 0.5 * i) + up
		var c := Vector3i(s.floor())
		if not _is_solid(c) and not _is_solid(c + Vector3i.DOWN):
			return s
	return feet + up


## Next to its hover spot (or close over the child), its dive ready, the child in plain view and no lantern's
## light in the way.
func _ready_to_dive(t: Node3D, here: Vector3, spot: Vector3) -> bool:
	if _cool > 0.0 or _stun > 0.0 or visibility_of(t) <= 0.0:
		return false
	var above := here.y - t.global_position.y
	if here.distance_to(spot) > 1.5 and not (_flat_distance(t.global_position) <= MonsterRules.BAT_CIRCLE + 1.0 and above >= 1.5):
		return false
	var aim := MonsterRules.dive_aim(t.global_position)
	return MonsterRules.clear_line(here + Vector3(0, size().y * 0.5, 0), aim, _is_solid) and not _in_lantern_light(aim)


## A weak bat never flies into a lantern's light (DefenseRules.LANTERN_KEEP_AWAY, like the walkers): it
## stops where the next step would come too close, and flies away from one that is closer.
func _lantern_goal(here: Vector3, to_point: Vector3) -> Vector3:
	if lanterns.is_empty() or not DefenseRules.fears_lanterns(level) or not to_point.is_finite():
		return to_point
	var near := DefenseRules.nearest(here, lanterns, 1)
	var center := Vector3(near[0]) + Vector3(0.5, 0.5, 0.5)
	if center.distance_to(here) < DefenseRules.LANTERN_KEEP_AWAY:
		var away := Vector3(here.x - center.x, 0.0, here.z - center.z)
		return here + (away.normalized() if away.length() > 0.01 else Vector3.FORWARD) * 2.0 + Vector3(0, 0.5, 0)
	var speed := MonsterRules.speed(kind, level)
	var look := speed * (AI_INTERVAL + speed / (2.0 * MonsterRules.BAT_ACCEL)) + 0.4
	return here if _in_lantern_light(here + (to_point - here).limit_length(look)) else to_point


## Is `point` in the light a weak bat keeps away from?
func _in_lantern_light(point: Vector3) -> bool:
	if not DefenseRules.fears_lanterns(level):
		return false
	for l in lanterns:
		if (Vector3(l) + Vector3(0.5, 0.5, 0.5)).distance_to(point) < DefenseRules.LANTERN_KEEP_AWAY:
			return true
	return false


## One physics step of a bat: steering to its goal, hovering while it signals, a dive, the low flutter after
## it. False while it hangs from its perch (nothing to move).
func _fly_step(delta: float) -> bool:
	if perched:
		return false
	if _stun > 0.0:
		velocity = velocity.move_toward(Vector3.ZERO, FRICTION * delta)   # pushed by a hit: it tumbles
		if _flight == &"dive":
			_end_dive()
		return true
	match _flight:
		&"dive":
			_dive_t -= delta
			var to := _dive_to - hit_center()
			velocity = to.normalized() * MonsterRules.BAT_DIVE_SPEED if to.length() > 0.3 else Vector3.ZERO
			_dive_hits()
			if _flight == &"dive" and (_dive_t <= 0.0 or to.length() <= 0.3 \
					or (is_on_floor() and _dive_t < MonsterRules.BAT_DIVE_TIME - 0.1)):
				_end_dive()
		&"low":
			_low_t -= delta
			velocity = velocity.move_toward(Vector3.ZERO, MonsterRules.BAT_ACCEL * 2.0 * delta)
			if _low_t <= 0.0:
				_flight = &"fly"
				if kind == MonsterRules.SHADOW_BAT:
					_fly_away()               # owner #39: up and away to rest before the next swoop
		_:
			if state == State.WINDUP:
				velocity = velocity.move_toward(Vector3.ZERO, MonsterRules.BAT_ACCEL * 2.0 * delta)   # it hovers
			elif _fly_goal.is_finite():
				var to := _fly_goal - global_position
				var want := to.normalized() * minf(_move_speed(), to.length() * 2.0) if to.length() > 0.05 else Vector3.ZERO
				velocity = velocity.move_toward(want, MonsterRules.BAT_ACCEL * delta)
				if _flight == &"perching" and to.length() < 0.3:
					_perch()
	return true


## The end of its wind-up: it dives at where the child stands now.
func _start_dive(t: Node3D) -> void:
	_cool = MonsterRules.BAT_DIVE_COOLDOWN
	if t == null or _gone(t) or visibility_of(t) <= 0.0:
		return
	_flight = &"dive"
	_dive_t = MonsterRules.BAT_DIVE_TIME
	_dive_to = MonsterRules.dive_aim(t.global_position)
	_dived.clear()


## Whoever the diving bat touches now is hit once, and the dive ends there.
func _dive_hits() -> void:
	var at := hit_center()
	for list: Array in [_players_now(), bots_now(get_tree())]:
		for c: Node3D in list:
			if _gone(c) or _dived.has(c.get_instance_id()) or visibility_of(c) <= 0.0:
				continue
			if MonsterRules.dive_hits(at, c.global_position):
				_dived[c.get_instance_id()] = true
				_hurt(c)
				_end_dive()
				return


func _end_dive() -> void:
	_flight = &"low"
	_low_t = MonsterRules.BAT_LOW_TIME
	velocity *= 0.2


func _perch() -> void:
	perched = true
	_flight = &"fly"
	global_position = _perch_at
	velocity = Vector3.ZERO
	_rest_t = _rng.randf_range(MonsterRules.BAT_REST_TIME.x, MonsterRules.BAT_REST_TIME.y)


## Off its perch: flying again, rested.
func _wake() -> void:
	perched = false
	_perch_at = Vector3.INF
	_fly_t = _rng.randf_range(MonsterRules.BAT_FLY_TIME.x, MonsterRules.BAT_FLY_TIME.y)


# --- The flyer (every peer) ---

## Wings up and down (two shared meshes, faster and icy while it signals a dive); upside down on its perch.
func _animate_bat(delta: float) -> void:
	if perched != _shown_perched:
		_shown_perched = perched
		_body.rotation.z = PI if perched else 0.0
		_body.position.y = size().y if perched else 0.0
	var frame := 0
	if not perched:
		_flap_t += delta * (2.0 if winding else 1.0)
		frame = int(_flap_t / FLAP) % 2
	if frame != _shown_frame or winding != _was_winding:
		if winding and not _was_winding:
			Audio.play(MonsterRules.WINDUP_SOUND.get(kind, &"screech"), global_position)   # the dive's signal (owner #39: a squeak)
		_shown_frame = frame
		_was_winding = winding
		if _arm:
			(_arm.get_child(0) as MeshInstance3D).mesh = MonsterModels.arm_mesh_for(kind, level, half, winding, frame)

# --- M3 Task 4: the Candy Kingdom's gummy bear and candy sneaker -------------------------------------------
# The gummy bear is a jumper (the slime's hops, higher) that bounces off walls: flying into one, its speed into
# the wall turns round (MonsterRules.wall_bounce). The candy sneaker walks and swings a lollipop like the
# goblin, but where the light is low (the host measures it at every look through `light_at`: night outdoors,
# caves) it is `dark` (synced): every screen hides its body and shows only a shimmer within
# MonsterRules.SHIMMER_NEAR of that screen's player, and always a shimmer and a jingle while it winds up (the
# fair signal before every attack). Its ? and ! marks and health bar still show (fairness first). Nothing here
# changes a block.

## Host: light_at(feet: Vector3) -> float, the light where it stands (StealthDirector.light_at; tests stub it).
var light_at: Callable
## Synced on change (sneakers): it stands in the dark.
var dark := false
## Every screen: jingles played (tests).
var jingles := 0
var _shimmer: Node3D
var _shimmer_check := 0.0
var _jingled := false
var _dark_t := 0.0
const DARK_EVERY := 1.0           # host: a sneaker measures its light this often (a ceiling scan, the lantern index)


func _build_candy(cfg: SceneReplicationConfig) -> void:
	if not MonsterRules.hides_in_dark(kind):   # universe 6: the spore puff too
		return
	var path := NodePath(".:dark")
	cfg.add_property(path)
	cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	_body.name = "Body"
	_shimmer = Node3D.new()
	_shimmer.name = "Shimmer"
	_shimmer.visible = false
	var mi := MeshInstance3D.new()
	mi.mesh = MonsterModels.shimmer_mesh(level, kind)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shimmer.add_child(mi)
	add_child(_shimmer)


## Host, at its looks (once a second): is it dark where the sneaker stands?
func _measure_dark() -> void:
	if not MonsterRules.hides_in_dark(kind) or light_at.is_null():
		return
	_dark_t -= PERCEIVE_EVERY
	if _dark_t > 0.0:
		return
	_dark_t = DARK_EVERY
	var now := MonsterRules.sneaker_dark(float(light_at.call(global_position))) and not golden   # a golden one glows
	if dark != now:
		dark = now


## Host, after a move: flying into a wall, a gummy bear bounces back off it.
func _bounce_off_walls(before: Vector3) -> void:
	if kind != MonsterRules.GUMMY or is_on_floor() or not is_on_wall():
		return
	var after := MonsterRules.wall_bounce(before, get_wall_normal())
	if after != before:
		velocity = after
		_sound(&"gummy", -6.0)


## Every screen: the sneaker's body in the light, a shimmer in the dark near this screen's player or while it
## winds up, nothing otherwise; a jingle as every wind-up starts. The player is looked up 10 times a second.
func _candy_looks(delta: float) -> void:
	if _shimmer == null:
		return
	if winding and not _jingled:
		_jingled = true
		jingles += 1
		Audio.play(&"spore_swell" if kind == MonsterRules.SPORE_PUFF else &"jingle", global_position)   # universe 6
	elif not winding:
		_jingled = false
	_shimmer_check -= delta
	if _shimmer_check <= 0.0:
		_shimmer_check = 0.1
		var look := MonsterRules.dark_look(kind, dark, winding, _distance_to_me())   # universe 6: the puff's own
		var body := look == MonsterRules.SEEN
		if _body.visible != body:
			_body.visible = body
		if _shimmer.visible != (look == MonsterRules.SHIMMER):
			_shimmer.visible = look == MonsterRules.SHIMMER
	if _shimmer.visible:                  # it twinkles: a slow turn and a pulse
		_shimmer.rotation.y += delta * 2.5
		var k := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.012)
		_shimmer.scale = Vector3(k, 1.0, k)


## How far this screen's own player is (INF when there is none).
func _distance_to_me() -> float:
	for p in players_now(get_tree()):
		if p.is_local:
			return p.global_position.distance_to(global_position)
	return INF

# --- M3 Task 14b: blaster hits (a bubble, paint, a slow) -------------------------------------------------
# The BlasterDirector (host) calls these after take_hit: a small monster floats up in a soap bubble for a few
# seconds (no moving, no deciding, no attacking; a wind-up is dropped), paint slows it and marks it (the mark
# itself is the director's, on every game), a big one hit by a bubble is only slowed. Host only; the body's
# place is synced as always.

var _bubble_t := 0.0
var _bubble_y := 0.0
var _bubble_pop := 0                  # damage it takes when its bubble pops (owner #53's strong bubble)
var _bubble_from := Vector3.INF
var _slow_t := 0.0
var _slow := 1.0
var _paint_t := 0.0


## Host: floats in a bubble for `seconds` (BlasterRules.BUBBLE_TIME); `pop_damage` (from `from`) lands when it pops.
func blast_bubble(seconds: float, pop_damage: int = 0, from: Vector3 = Vector3.INF) -> void:
	if _defeated or not is_finite(seconds):
		return
	_bubble_pop += maxi(pop_damage, 0)
	if from.is_finite():
		_bubble_from = from
	if state == State.WINDUP:
		_stop_windup()
	_bubble_t = maxf(_bubble_t, seconds)
	_bubble_y = global_position.y + BlasterRules.BUBBLE_RISE
	_dir = Vector3.ZERO


## Host: moves at `factor` × its speed for `seconds` (the slowest slow wins while it lasts).
func blast_slow(factor: float, seconds: float) -> void:
	if not is_finite(factor) or not is_finite(seconds):
		return
	_slow = clampf(factor, 0.1, 1.0) if _slow_t <= 0.0 else minf(_slow, clampf(factor, 0.1, 1.0))
	_slow_t = maxf(_slow_t, seconds)


## Host: painted for `seconds`: slowed (BlasterRules.PAINT_SLOW) and marked.
func blast_paint(seconds: float) -> void:
	if not is_finite(seconds):
		return
	_paint_t = maxf(_paint_t, seconds)
	blast_slow(BlasterRules.PAINT_SLOW, seconds)


func bubbled() -> bool:
	return _bubble_t > 0.0


func painted() -> bool:
	return _paint_t > 0.0


## Its speed factor now (1 = not slowed).
func blast_speed() -> float:
	return _slow if _slow_t > 0.0 else 1.0


## Host, every simulated step: the blasters' timers; true while it floats in its bubble (the rest of the
## step is skipped). When the bubble pops it falls back down.
func _blast_tick(delta: float) -> bool:
	if _slow_t > 0.0:
		_slow_t -= delta
	if _paint_t > 0.0:
		_paint_t -= delta
	if _bubble_t <= 0.0:
		return false
	_bubble_t -= delta
	velocity = Vector3(0.0, clampf((_bubble_y - global_position.y) * 3.0, -2.0, 2.0), 0.0)
	if _bubble_t <= 0.0:
		velocity = Vector3.ZERO           # pop: it drops (gravity takes it from here)
		if _bubble_pop > 0:               # and the bubble's hits land now
			var hit := _bubble_pop
			_bubble_pop = 0
			take_hit(hit, _bubble_from if _bubble_from.is_finite() else global_position, Vector3.ZERO)
			if _defeated or is_queued_for_deletion():
				return true
	move_and_slide()
	return true

# --- M3 Task 14b: the goblin archer (build-fight practice, spec §13.7) ---------------------------------------
# While it chases a child it sees, the archer keeps 10-20 blocks away (ArcherRules): it backs off from a child
# who comes closer and walks up to one further off. A couple of spots around it are scored every decision
# (ArcherRules.score_spot: cover, a peek beside it, high ground), a new round every few seconds; it walks to
# the best, waits there (behind its block when it has one), steps out to the peek, draws its bow for a whole
# second (synced `winding`: the arm comes up level, the arrow's tip glows) and shoots a slow arrow onto where
# the child stands, then goes back into cover. The arrow flies in the BlasterDirector's pool (shoot_arrow);
# it stops at the first block, and the archer never shoots when the flight would end in a wall. Host only;
# nothing here changes a block.

## Host: shoot_arrow(from: Vector3, velocity: Vector3, damage: int) -> int (BlasterDirector.monster_arrow;
## MonsterDirector sets it). Without one the archer only aims.
var shoot_arrow: Callable
var _plan := {}                   # the spot it holds: ArcherRules.score_spot's {spot, peek, cover, score}
var _plan_t := 0.0                # seconds since it chose it (it gives up a spot it can't reach)
var _search_i := ArcherRules.CANDIDATES
var _search_best := {}
var _search_t := 0.0
var _peeking := false
var _hide_t := 0.0

const PLAN_REACH := 0.45          # this close to a spot counts as there
const PLAN_GIVE_UP := 6.0         # seconds to reach a spot before it looks for another


func _archer() -> bool:
	return kind == MonsterRules.ARCHER


## Where its arrow leaves the bow.
func bow() -> Vector3:
	return global_position + Vector3(0, ArcherRules.EYE * MonsterRules.size_scale(level), 0) + facing() * 0.35


## The spot it holds now ({} while it has none: tests).
func archer_plan() -> Dictionary:
	return _plan


func _decide_archer(t: Node3D) -> void:
	state = State.CHASE
	var seeing := t != null and awareness.sees
	var feet: Vector3 = t.global_position if seeing else awareness.spot
	if not feet.is_finite():
		_dir = Vector3.ZERO
		return
	_search_spots(feet)
	var d := _flat_distance(feet)
	if d < ArcherRules.RANGE_MIN:
		_plan = {}                        # too close: it backs off (a brave child can chase it)
		_dir = _spread(-_flat_dir_to(feet)) if d > 0.01 else -facing()
	elif _plan.is_empty():
		_dir = _spread(_flat_dir_to(feet)) if d > ArcherRules.RANGE_MAX - 1.0 else Vector3.ZERO
		if _dir == Vector3.ZERO:
			_try_shot(t, seeing)          # in range in the open: it shoots from where it stands
	else:
		_plan_t += AI_INTERVAL
		var goal: Vector3 = _plan.peek if _peeking else _plan.spot
		if _flat_distance(goal) > PLAN_REACH:
			_dir = _spread(_flat_dir_to(goal))
			if _plan_t > PLAN_GIVE_UP:
				_plan = {}                # it can't get there: another spot next round
		else:
			_dir = Vector3.ZERO
			if _peeking:
				_try_shot(t, seeing)
			else:
				_hide_t -= AI_INTERVAL
				if _hide_t <= 0.0 and _cool <= 0.0:
					_peeking = true       # out it steps
	_mind_defenses()                      # weak archers keep away from lanterns too
	_keep_safe()


## At its spot with a clear, reachable shot: the bow comes up (a second's signal before the arrow).
func _try_shot(t: Node3D, seeing: bool) -> void:
	if not seeing or t == null or _cool > 0.0 or _stun > 0.0 or visibility_of(t) <= 0.0:
		return
	if not ArcherRules.in_range(global_position, t.global_position):
		return
	if not MonsterRules.clear_line(bow(), _chest_of(t), _is_solid):
		return
	_start_windup()


func _chest_of(t: Node3D) -> Vector3:
	if t is Player:
		return CombatDirector.chest(t as Player)
	return t.call(&"chest") if t.has_method(&"chest") else t.global_position + Vector3(0, ArcherRules.CHEST, 0)


## The end of the wind-up: the arrow flies onto where the child stands now, unless a wall is in the way.
func _archer_shoot(t: Node3D) -> void:
	_cool = ArcherRules.COOLDOWN
	_peeking = false
	_hide_t = ArcherRules.HIDE_TIME
	if t == null or _gone(t) or visibility_of(t) <= 0.0 or not shoot_arrow.is_valid():
		return
	var from := bow()
	var chest := _chest_of(t)
	var v := ArcherRules.aim(from, chest)
	if not ArcherRules.shot_reaches(from, v, chest, _is_solid):
		return                            # the child ducked behind a wall: no arrow at all
	shoot_arrow.call(from, v, MonsterRules.hit(kind, level, universe))


## A couple of spots a decision (ArcherRules.CANDIDATES in a round, a new round every SEARCH_EVERY): the best
## becomes its plan when the round is done.
func _search_spots(target_feet: Vector3) -> void:
	_search_t -= AI_INTERVAL
	if _search_i >= ArcherRules.CANDIDATES:
		if _search_t > 0.0 and not _plan.is_empty():
			return
		_search_i = 0
		_search_best = {}
		var here_cell := Vector3i(global_position.floor())
		var here := Vector3(global_position.x, here_cell.y, global_position.z)
		_consider_spot(here, target_feet)   # where it stands counts too
	var cell := Vector3i(global_position.floor())
	for k in ArcherRules.SEARCH_PER_DECISION:
		if _search_i >= ArcherRules.CANDIDATES:
			break
		var off := ArcherRules.candidate(_search_i)
		var ring := maxi(absi(off.x), absi(off.y))
		_search_i += 1
		var y := ArcherRules.stand_y(cell.x + off.x, cell.z + off.y, cell.y, _is_solid)
		if y == ArcherRules.NO_SPOT or y > cell.y + ring / 2:
			continue                      # too high to climb to from here
		var spot := Vector3(cell.x + off.x + 0.5, y, cell.z + off.y + 0.5)
		if not MonsterRules.can_step(Vector3i(spot.floor()), block_at):
			continue                      # never into water or off a cliff
		_consider_spot(spot, target_feet)
	if _search_i >= ArcherRules.CANDIDATES:
		_search_t = ArcherRules.SEARCH_EVERY
		var better := not _search_best.is_empty() and (_plan.is_empty() or float(_search_best.score) > float(_plan.score) + 0.5 \
			or (_search_best.spot as Vector3).distance_to(_plan.spot) < 0.1)
		if better:
			var fresh := _plan.is_empty() or (_search_best.spot as Vector3).distance_to(_plan.spot) > 0.1
			_plan = _search_best
			if fresh:
				_plan_t = 0.0
				_peeking = false
				_hide_t = ArcherRules.HIDE_TIME * 0.5
		elif _search_best.is_empty():
			_plan = {}


func _consider_spot(spot: Vector3, target_feet: Vector3) -> void:
	var s := ArcherRules.score_spot(spot, target_feet, global_position, _is_solid)
	if not s.is_empty() and (_search_best.is_empty() or float(s.score) > float(_search_best.score)):
		_search_best = s

# --- M3 Task 14a: the Dance Orb ------------------------------------------------------------------------------

const DANCE_WIGGLE := 0.9         # radians it turns left and right
const DANCE_HOP := 3.0            # m/s up: a little hop on the beat
const DANCE_BEAT := 0.6

## Host: seconds it still dances (GadgetDirector): it turns left and right and hops on the beat (its synced
## turn and place show it in every game), never walks, winds up or attacks, and a hit still counts.
var dance_left := 0.0
var _dance_t := 0.0
var _dance_yaw := 0.0


func dance(seconds: float) -> void:
	if not multiplayer.is_server() or _defeated or seconds <= 0.0:
		return
	if dance_left <= 0.0:
		_dance_t = 0.0
		_dance_yaw = rotation.y
	dance_left = maxf(dance_left, seconds)
	if state == State.WINDUP:
		_stop_windup()
	winding = false


func is_dancing() -> bool:
	return dance_left > 0.0


func _dance_step(delta: float) -> bool:
	if dance_left <= 0.0:
		return false
	dance_left -= delta
	_dance_t += delta
	rotation.y = _dance_yaw + sin(_dance_t * TAU / DANCE_BEAT) * DANCE_WIGGLE
	if dance_left <= 0.0:
		rotation.y = _dance_yaw
	velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
	if is_on_floor():
		if fmod(_dance_t, DANCE_BEAT) < delta and not _flyer():
			velocity.y = DANCE_HOP
	elif not _flyer():
		velocity.y -= GRAVITY * delta
	move_and_slide()
	return true

# --- Owner #39: the Dragon Realm's shadow bat and wisp spirit ---------------------------------------------------
# Both fly the ice bat's way (the flyer above: a point to fly to ten times a second, steering, hovering while they
# signal). The shadow bat's swoop is the ice bat's dive after a longer signal (wings flare, eyes brighten, a squeak);
# after it, it flies up and away (MonsterRules.shadow_rest_spot) and rests SHADOW_REST before it comes back. The wisp
# floats lower, keeps WISP_KEEP from a child it sees (watching them), and when it has a clear line (never from closer
# than WISP_TOO_CLOSE) it brightens, chimes and grows its ring (synced `winding`), then throws a slow spark in a
# straight line at the chest where the child stands: the host flies it (a wall stops it, one built while it flies
# too; it hurts the first child it touches) and every game shows it (SpitGlob, straight). While they see a child,
# their creature minds pick a fair tactic that only moves where they fly (their attack keeps its signal). Over the
# void (floating islands) every flyer keeps its height and goes back to where there was ground; one below VOID_Y over
# nothing is lost (`lost`: the director puffs it away). Nothing here changes a block.

const WISP_BOB := 0.08            # every screen: a wisp bobs this much ...
const WISP_BOB_SPEED := 2.4       # ... this fast (radians a second)
const WISP_RING_FROM := 0.35      # its ring starts this small and grows to full size over its wind-up
const SPARK_NEAR := 4.0           # (squared) only bodies whose feet are within 2 blocks of a spark are looked at closely

var _body_mesh: MeshInstance3D
var _void := false                # host, a flyer: nothing within BAT_LOOK_DOWN under it (looked at with the ground)
var _void_ahead := false          # ... nothing under where it is going
var _home := Vector3.INF          # ... the last place it had ground under it
var _away_t := 0.0                # host, a shadow bat: seconds it still rests up and away ...
var _away_at := Vector3.INF       # ... and where
var _hold_at := Vector3.INF       # host: where a Dragon Realm flyer waits (its mind's WAIT)
var _sparks: Array = []           # host, a wisp: [id, age, from, to, cell] for each spark in flight
var _spark_id := 0
## Host (tests): where the last spark ended.
var last_spark_end := Vector3.INF
var _bob_t := 0.0
var _ring_t := 0.0


func _dragon_flyer() -> bool:
	return kind == MonsterRules.SHADOW_BAT or kind == MonsterRules.WISP


## Host: sparks thrown that are still flying (tests).
func sparks_in_flight() -> int:
	return _sparks.size()


## Lost in the void: the director puffs it away (a monster on its own just goes).
func _lose() -> void:
	_defeated = true
	if lost.get_connections().is_empty():
		queue_free()
	else:
		lost.emit(self)


## After its swoop and the low flutter, a shadow bat flies up and away (from the child it swooped at) to rest.
func _fly_away() -> void:
	var t := target()
	var feet: Vector3 = t.global_position if t else awareness.spot
	if not feet.is_finite():
		return
	_flight = &"away"
	_away_t = MonsterRules.SHADOW_REST
	_away_at = MonsterRules.shadow_rest_spot(feet, global_position)


## Where a Dragon Realm flyer after a child at `feet` flies: its usual spot (a shadow bat over the child's side, a
## wisp WISP_KEEP away), or where its mind's tactic steers it while it sees them (`t`): a weave on the way, round
## to the side the child isn't looking, waiting where it is, or backing off up and away when hurt.
func _dragon_aim(t: Node3D, feet: Vector3, here: Vector3) -> Vector3:
	var wisp := kind == MonsterRules.WISP
	var spot := _open_side(feet, MonsterRules.wisp_spot(feet, here) if wisp else MonsterRules.hover_spot(feet, here))
	if t == null or mind == null:
		tactic = &""
		return spot
	var was := tactic
	var d := _flat_distance(feet)
	if tactic == &"" or t != _tactic_of or mind.due():
		_pick_tactic(t, d)
	if tactic != MonsterSpecies.WAIT:
		_hold_at = Vector3.INF
	if tactic == MonsterSpecies.BACK_OFF:
		return MonsterRules.back_off_spot(feet, here)
	if d <= TACTIC_NEAR:
		tactic = MonsterSpecies.STRAIGHT     # close: its usual spot
		if not _reached:
			_reached = true
			_lesson(&"reached")
		return spot
	match tactic:
		MonsterSpecies.ZIGZAG:
			if here.distance_to(spot) > 3.0:
				if _zig_t <= 0.0:
					_zig_t = ZIGZAG_EVERY
					_zig_side = -_zig_side
				return here + (spot - here).rotated(Vector3.UP, _zig_side * ZIGZAG_ANGLE)
		MonsterSpecies.GO_ROUND:
			var look := _facing_of(t)
			var side := Vector3(-look.z, 0.0, look.x) * _round_side
			var r := MonsterRules.WISP_KEEP if wisp else MonsterRules.BAT_CIRCLE
			var up := MonsterRules.WISP_HOVER if wisp else MonsterRules.BAT_HOVER
			return _open_side(feet, feet + side * r + Vector3(0, up, 0))
		MonsterSpecies.WAIT:
			if was != MonsterSpecies.WAIT or not _hold_at.is_finite():
				_hold_at = here
			if d < WAIT_BREAK:
				mind.interrupt()              # the child came close: think again
			return _hold_at
	return spot


## Its signal may start: never while backing off; a wisp with a clear line in range, a shadow bat by its usual
## rule (next to where it hovers, or close over the child).
func _ready_to_attack(t: Node3D, here: Vector3, spot: Vector3) -> bool:
	if tactic == MonsterSpecies.BACK_OFF:
		return false
	if kind == MonsterRules.WISP:
		return _ready_to_spark(t)
	if tactic == MonsterSpecies.WAIT or tactic == MonsterSpecies.ZIGZAG:
		spot = _hover_at(t.global_position, here)   # a waiting or weaving bat swoops only from its usual spot
	return _ready_to_dive(t, here, spot)


## A wisp throws only at a child it sees, from WISP_TOO_CLOSE or further, in range and with a clear line.
func _ready_to_spark(t: Node3D) -> bool:
	if _cool > 0.0 or _stun > 0.0 or visibility_of(t) <= 0.0:
		return false
	if _flat_distance(t.global_position) < MonsterRules.WISP_TOO_CLOSE:
		return false
	var from := hit_center()
	var to := MonsterRules.spark_aim(t.global_position)
	return MonsterRules.may_spark(from, to) and MonsterRules.clear_line(from, to, _is_solid)


## The end of its wind-up: the spark leaves for the chest where the child stands now, unless a wall came between.
func _throw_spark(t: Node3D) -> void:
	_cool = MonsterRules.SPARK_COOLDOWN
	if t == null or _gone(t) or visibility_of(t) <= 0.0:
		return
	var from := hit_center()
	var to := MonsterRules.spark_aim(t.global_position)
	if not MonsterRules.may_spark(from, to) or not MonsterRules.clear_line(from, to, _is_solid):
		return                            # the child hid behind a wall during the signal: no spark at all
	_spark_id += 1
	_sparks.append([_spark_id, 0.0, from, to, Vector3i(from.floor())])   # [id, age, from, to, the cell it is in]
	_rpc_spark.rpc(_spark_id, from, to)


## Host, every simulated step: each spark moves on its straight line; a solid block stops it, the first child or
## friend it touches is hit, and where the child stood it fizzles.
func _fly_sparks(delta: float) -> void:
	var i := _sparks.size() - 1           # (no copy of the list and no temporary arrays: this runs every step)
	while i >= 0:
		var s: Array = _sparks[i]
		s[1] += delta
		var at := MonsterRules.spark_point(s[2], s[3], s[1])
		var cell := Vector3i(at.floor())
		var blocked := false
		if cell != s[4]:                  # a block is read only when it flies into a new cell
			s[4] = cell
			blocked = _is_solid(cell)
		if blocked:
			_end_spark(i, at)             # a wall (one built while it flew too)
		else:
			var who := _spark_touches(at)
			if who:
				_hurt(who)
				_end_spark(i, at)
			elif at.is_equal_approx(s[3]):
				_end_spark(i, at)
		i -= 1


func _spark_touches(at: Vector3) -> Node3D:
	for p in _players_now():
		if p.global_position.distance_squared_to(at) < SPARK_NEAR and not _gone(p) \
				and MonsterRules.spark_hits(at, p.global_position) and visibility_of(p) > 0.0:
			return p
	for b in bots_now(get_tree()):
		if b.global_position.distance_squared_to(at) < SPARK_NEAR and not _gone(b) \
				and MonsterRules.spark_hits(at, b.global_position) and visibility_of(b) > 0.0:
			return b
	return null


func _end_spark(i: int, at: Vector3) -> void:
	var id := int(_sparks[i][0])
	_sparks.remove_at(i)
	last_spark_end = at
	_rpc_spark_end.rpc(id, at)


## A spark leaves the wisp (every game flies the same one, straight and slow).
@rpc("authority", "call_local", "reliable")
func _rpc_spark(id: int, from: Vector3, to: Vector3) -> void:
	if not (from.is_finite() and to.is_finite()):
		return
	var g := SpitGlob.new()
	g.name = "Spark%d" % id
	g.look = MonsterModels.spark_mesh()
	g.splat = MonsterModels.WISP_LIGHT
	g.sound = &"spark_pop"
	g.straight = true
	g.setup(from, to)
	add_child(g)


## The host says where a spark ended (a wall, a child, or where it was going): every game bursts it there.
@rpc("authority", "call_local", "reliable")
func _rpc_spark_end(id: int, at: Vector3) -> void:
	var g := get_node_or_null(NodePath("Spark%d" % id)) as SpitGlob
	if g and at.is_finite():
		g.end_at(at)


## Every screen: a wisp bobs gently; as it winds up it lights up, chimes, and its ring grows round the orb.
func _animate_wisp(delta: float) -> void:
	_bob_t += delta
	var bob := sin(_bob_t * WISP_BOB_SPEED) * WISP_BOB
	if _body.position.y != bob:
		_body.position.y = bob
	if winding != _was_winding:
		_was_winding = winding
		_ring_t = 0.0
		if winding:
			Audio.play(MonsterRules.WINDUP_SOUND[kind], global_position)
		if _arm:
			(_arm.get_child(0) as MeshInstance3D).mesh = MonsterModels.arm_mesh_for(kind, level, half, winding)
		if _body_mesh and not golden:
			_body_mesh.mesh = MonsterModels.wisp_body(level, winding)
	var ring := 1.0
	if winding:
		_ring_t += delta
		ring = lerpf(WISP_RING_FROM, 1.0, clampf(_ring_t / MonsterRules.WISP_WINDUP, 0.0, 1.0))
	if _arm and _arm.scale.x != ring:
		_arm.scale = Vector3.ONE * ring

# --- M3 Task 15: the tutorial's practice slime -------------------------------------------------------------------
# Spawned by the TutorialDirector ({"practice": true}): a real slime that sees, chases and loses a hidden child, but
# never touches to hurt, is never beaten by a hit (no coins, no defeat) and has no creature mind. Solo only.

var practice := false

# --- M5 Task 2: the jumpers' pounce and the recoil (spec §15.2; CreatureMoves) ---------------------------------------

func _jumper() -> bool:
	return MonsterRules.behaviour(kind) == MonsterRules.JUMPER


## How long its attack is signalled: the kind's wind-up (MonsterRules), a jumper's crouch before a pounce.
func _windup_time() -> float:
	return CreatureMoves.POUNCE_WINDUP if _jumper() else MonsterRules.windup(kind)


## Host: a chasing jumper whose next hop is due crouches first when it sees its target within POUNCE_RANGE (out of
## touch: close enough to touch, the touch hurts as before). A golden slime never does (it never chases).
func _pounce_due() -> bool:
	if not _jumper() or golden or state != State.CHASE or not awareness.sees or _cool > 0.0:
		return false
	var t := target()
	if t == null or _gone(t) or visibility_of(t) <= 0.0:
		return false
	var d := _flat_distance(t.global_position)
	return (d <= CreatureMoves.POUNCE_RANGE and d > size().x * 0.5 + TOUCH_REACH
		and absf(t.global_position.y - global_position.y) <= MonsterRules.MAX_RISE)


## Host: the crouch is over: it jumps at where its target stands now (a child who stepped aside is missed).
func _pounce(t: Node3D) -> void:
	_hop = HOP_WAIT_CHASE * _rng.randf_range(0.85, 1.15)
	var dir := _dir
	if t and not _gone(t):
		var to := Vector3(t.global_position.x - global_position.x, 0.0, t.global_position.z - global_position.z)
		if to.length() > 0.01:
			dir = to.normalized()
	if dir == Vector3.ZERO or not is_on_floor():
		return
	velocity = dir * _move_speed() * CreatureMoves.POUNCE_BOOST + Vector3.UP * MonsterRules.hop_up(kind)
	_sound(&"squish", -6.0)


## Every peer: the lean back after a hit (the body's x rotation; models face -Z), easing home.
func _recoil_look(delta: float) -> void:
	var lean := 0.0
	if _recoil > 0.0:
		_recoil = maxf(_recoil - delta, 0.0)
		lean = CreatureMoves.recoil(_recoil / CreatureMoves.RECOIL_TIME, CreatureMoves.MONSTER_RECOIL)
	if _body.rotation.x != lean:
		_body.rotation.x = lean
