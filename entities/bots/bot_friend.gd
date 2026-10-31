class_name BotFriend
extends CharacterBody3D
## A bot friend (M2 §12.14, owner feedback #18): a host-simulated companion with an avatar body
## (BotBlockyAvatar / BotRealisticAvatar, following this device's style like players), a made-up
## name under a robot badge, its own colours and a personality (BotRules): it follows the player
## at a comfortable distance and pops up next to them when left behind, wanders nearby, fights
## monsters near the player through the host's CombatDirector, builders put small builds next to
## the player's builds, explorers point at shiny things and at what Task 16's secrets show them
## (notice()), and it says a short line in the chat now and then (at most one per 20 s). Monsters
## hurt it through hurt(); knocked out, it bursts into confetti and comes back after 10 s.
## It never takes anything: no inventory, no gold, not a player (coins, bags and rewards skip it).
##
## Cost (the animals' rules, M1b): decisions AI_INTERVAL apart, rests when no player is near, one
## shared players and monsters list per physics frame, a standing bot skips the physics move, and
## its boxes and materials are shared with every other bot. Other peers see a synced copy.

const LAYER := 64                 # physics layer 7: bot friends (tap rays and players ignore it)
const GRAVITY := 24.0
const WALK_SPEED := 4.5
const RUN_SPEED := 6.5
const ACCEL := 30.0
const JUMP_VELOCITY := 8.5        # hops onto a 1-block ledge
const SWIM_UP := 2.5
const WATER_FACTOR := 0.6
const RADIUS := 0.3
const HEIGHT := 1.8
const CHEST := 1.0
const RUN_FROM := 8.0             # walking back from farther than this: runs
const STUCK_TIME := 3.0           # not getting closer this long: gives up (or pops up next to the player)
const MELEE_STOP := 1.4           # stands this far from a monster (plus its radius) to swing
const POINT_STOP := 2.0
const POINT_REACH := 3.0          # close enough to what it shows: points
const POINT_TIME := 5.0           # points this long
const SIGHT_TIME := 15.0          # gives up on something it can't reach after this
const BUILD_STOP := 2.0
const BUILD_REACH := 3.2
const BUILD_WAIT := 3.0           # somebody stands in the way this long: builds elsewhere later
const SCAN_EVERY := 2.0           # explorers look around this often
const SCAN_HALF := Vector3i(6, 4, 6)   # 13 x 9 x 13 cells: one bulk copy and a native search of its bytes
const ANIMAL_NOTICE := 10.0
const MEMORY := 256               # things an explorer remembers having shown
const HURT_PUSH := 4.0
const IDLE_CHAT := Vector2(45.0, 90.0)
const MONSTER_CENTER := CombatDirector.MONSTER_CENTER
const MONSTER_RADIUS := CombatDirector.MONSTER_RADIUS

var bot_id := ""
var bot_name := ""
var personality: StringName = BotRules.EXPLORER
var look := 0
var world: WorldService           # host: set by the spawner
var combat: CombatDirector        # host: resolves its swings
var director: BotDirector         # host: its builds go through it
var leader_peer := 1              # the player it plays with (the host's own)
var health := Health.new()        # host
## Synced to every peer (on change).
var held_item := 0
var knocked_out := false
var pointing := false

## Host: what it is doing, how many decisions it made, its own clock (s) for chat and timers.
var behaviour: StringName = BotRules.IDLE
var decisions := 0
var clock := 0.0

var avatar: AvatarModel
var _tag: Label3D
var _held: HeldItem
var _last_pos := Vector3.ZERO
var _aiming := false

var _rng := RandomNumberGenerator.new()
var _active := false              # nothing moves before the first decision
var _in_water := false
var _ai_t := 0.0
var _goal := Vector3.INF
var _stop_at := 1.0
var _speed := WALK_SPEED
var _face := Vector3.INF
var _best_d := INF
var _stuck_t := 0.0
var _last_said := -INF
var _idle_chat_t := 0.0
var _wander_t := 0.0
var _wander_spot := Vector3.INF
var _target_id := 0
var _hit_target := false
var _attack_t := 0.0
var _ko_t := 0.0
var _sight := Vector3.INF
var _sight_kind := &"shiny"
var _sight_text := ""
var _sight_t := 0.0
var _point_t := 0.0
var _scan_t := 0.0
var _seen := {}
var _build_t := BotRules.BUILD_FIRST
var _build_wait := 0.0
var _plan: Array = []

## Every player and every monster, looked up once per physics frame for all bots.
static var _players_frame := -1
static var _players: Array[Player] = []
static var _player_spots: Array[Vector3] = []
static var _monsters_frame := -1
static var _monsters: Array[Node3D] = []
static var _badge: ImageTexture


## data = {id, name, personality, look, pos, yaw} (the spawner's data, the same on every peer).
func setup(data: Dictionary) -> void:
	bot_id = str(data.get("id", "Bot"))
	name = bot_id
	bot_name = str(data.get("name", "Pip"))
	var p := StringName(str(data.get("personality", "")))
	personality = p if BotRules.valid_personality(p) else BotRules.EXPLORER
	var l := int(data.get("look", 0))
	look = l if BotRules.valid_look(l) else 0
	position = data.get("pos", Vector3.ZERO)
	rotation.y = float(data.get("yaw", 0.0))
	_rng.seed = hash(bot_id + bot_name)
	_ai_t = _rng.randf() * BotRules.AI_INTERVAL      # bots decide on different frames
	_idle_chat_t = _rng.randf_range(IDLE_CHAT.x, IDLE_CHAT.y)
	_wander_t = _rng.randf_range(3.0, 6.0)
	_build()
	mind = Mind.create(BotSpecies.table(), bot_name)   # M2 Task 18: learns its child's style


func _ready() -> void:
	if not Game.settings_applied.is_connected(_on_settings):
		Game.settings_applied.connect(_on_settings)


func _build() -> void:
	add_to_group(&"bots")            # monsters look for targets here (M2 Task 4 contract)
	add_to_group(&"bot_friends")     # every friend, knocked out or not (team size)
	collision_layer = LAYER
	collision_mask = 1
	floor_snap_length = 0.2
	var capsule := CapsuleShape3D.new()
	capsule.radius = RADIUS
	capsule.height = HEIGHT
	var shape := CollisionShape3D.new()
	shape.name = "Collision"
	shape.shape = capsule
	shape.position.y = HEIGHT * 0.5
	add_child(shape)
	set_avatar_style(str(Profile.data.settings.get("style", "blocky")))
	_tag = Label3D.new()
	_tag.name = "NameTag"
	_tag.text = tr("%s\n%s bot") % [bot_name, tr(personality)]
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.font_size = 36
	_tag.outline_size = 10
	_tag.pixel_size = 0.01
	_tag.modulate = Color("bfe9ff")
	_tag.position.y = 2.45
	add_child(_tag)
	var badge := Sprite3D.new()
	badge.name = "BotBadge"
	badge.texture = robot_badge()
	badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	badge.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	badge.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	badge.shaded = false
	badge.pixel_size = 0.025
	badge.position.y = 3.05
	add_child(badge)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	for prop in [".:position", ".:rotation", ".:held_item", ".:knocked_out", ".:pointing", ".:thought", ".:game_pose"]:
		cfg.add_property(NodePath(prop))
	for prop in [".:held_item", ".:knocked_out", ".:pointing", ".:thought", ".:game_pose"]:   # game_pose: M4 H
		cfg.property_set_replication_mode(NodePath(prop), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)
	held_item = BotRules.held_item(personality, BotRules.IDLE)
	_last_pos = position


## For WorldMeta.bots: who this friend is (it comes back next to the player).
func to_save() -> Dictionary:
	return {"name": bot_name, "personality": String(personality), "look": look, "mind": mind_save()}


func eye_position() -> Vector3:
	return global_position + Vector3(0, CameraRig.HEAD_HEIGHT, 0)


func chest() -> Vector3:
	return global_position + Vector3(0, CHEST, 0)


func is_knocked_out() -> bool:
	return knocked_out


## Players and bot friends together, knocked out or not: the Stone Golem's health counts every bot
## friend like a player (§12.9, BotRules.team_size).
static func team_size(tree: SceneTree) -> int:
	return BotRules.team_size(tree.get_nodes_in_group(&"players").size(), tree.get_nodes_in_group(&"bot_friends").size())


## Where a friend can stand next to the player at `near`: a free spot on the ground beside them
## (caves too), else the ground below them (a flying player); INF while that ground isn't loaded.
static func spot_near(w: WorldService, near: Vector3, start: int) -> Vector3:
	if w == null or not w.is_area_ready(near):
		return Vector3.INF
	var spot := AnimalRules.summon_spot(near, w.get_block, posmod(start, AnimalRules.SUMMON_SIDES.size()))
	var cell := Vector3i(spot.floor())
	if BlockIds.is_solid(w.get_block(cell + Vector3i.DOWN)) and not BlockIds.is_solid(w.get_block(cell)):
		return Vector3(spot.x, SpawnRules.spawn_y(cell.y), spot.z)
	var x := floori(near.x) + 1
	var z := floori(near.z) + 1
	return Vector3(x + 0.5, SpawnRules.spawn_y(w.find_standing_y(x, z)), z + 0.5)


# --- Chat ---

## Host: says a line of `kind` (BotRules.LINE_KINDS) when it may (one per CHAT_GAP). True if said.
func say(kind: StringName) -> bool:
	return say_text(BotRules.line(kind, personality, _rng.randi(), bot_name))


func say_text(text: String) -> bool:
	if text == "" or not BotRules.can_say(_last_said, clock):
		return false
	_last_said = clock
	Session.bot_say(bot_name, text)
	return true


## The last word when the player sends it home (always said).
func say_goodbye() -> void:
	Session.bot_say(bot_name, BotRules.line(&"bye", personality, 0, bot_name))
	_rpc_poof.rpc(global_position + Vector3(0, 1.0, 0))


## M4 E: a player joined a full online world; this friend steps out (it comes back for a free seat).
func say_make_room() -> void:
	Session.bot_say(bot_name, BotRules.MAKE_ROOM_LINE)
	_rpc_poof.rpc(global_position + Vector3(0, 1.0, 0))


# --- Hooks for monsters (Task 4), the boss (Task 10) and secrets (Task 16) ---

## Host: a monster (or the boss) hits this friend for `amount` from `from`. Knocked out at 0.
func hurt(amount: int, from: Vector3) -> void:
	if not multiplayer.is_server() or knocked_out or amount <= 0 or not Game.allows(ModeRules.DAMAGE):
		return
	var out := health.damage(amount)
	var away := global_position - from
	away.y = 0.0
	if away.length() > 0.01:
		velocity += away.normalized() * HURT_PUSH + Vector3.UP * 2.0
	_rpc_hurt_fx.rpc()
	if out:
		_knock_out()


## Host (Task 16's secrets call this): an explorer walks over to `point`, points at it and says
## `text` (or "Look! Something shiny over here!"). Only explorers answer, only for things near the
## player, and not while already pointing at something. True if this bot will show it.
func notice(point: Vector3, text: String = "") -> bool:
	if personality != BotRules.EXPLORER or knocked_out or pointing or not point.is_finite():
		return false
	var leader := _leader()
	if leader == null or leader.global_position.distance_to(point) > BotRules.NOTICE_RADIUS:
		return false
	_set_sight(point, &"shiny", text)
	if _mind_pick_find(false, false, true) == BotSpecies.FIND_SECRET:   # M2 Task 18
		_mind_pointed(BotSpecies.FIND_SECRET, BotRules.NO_CELL, null, point)
	return true


# --- Host simulation ---

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	clock += delta
	if knocked_out:
		_ko_t -= delta
		if _ko_t <= 0.0:
			_come_back()
		return
	if _race_tick(delta):   # M3 Task 7: racing a recorded run (section at the end)
		return
	health.tick(delta)
	_attack_t -= delta
	_build_t -= delta
	_scan_t -= delta
	_wander_t -= delta
	_idle_chat_t -= delta
	_point_t -= delta
	_sight_t -= delta
	_ai_t -= delta
	var decide := _ai_t <= 0.0
	if decide:
		_ai_t += BotRules.AI_INTERVAL
		_decide()
	if not _active:
		return                          # resting: nobody near, or waiting for the player's ground
	# Standing still on the ground: nothing to move until the next decision.
	if not decide and not _goal.is_finite() and not _in_water and is_on_floor() and velocity.is_zero_approx():
		return
	_move(delta)


func _decide() -> void:
	decisions += 1
	_talk_tick()   # owner 38: what the child asked for runs its course
	if game_brain.is_valid() and bool(game_brain.call(self)):
		return                          # M4 H: a co-op game steers this friend for now
	var leader := _leader()
	if leader == null or not leader.is_spawned() or world == null:
		_rest()
		return
	var lp := leader.global_position
	_active = BotRules.is_active(global_position, _spots())
	if BotRules.needs_catch_up(global_position, lp, _grounded(leader)) and not _talk_holds(lp):   # owner 38: waiting
		_catch_up(lp)
		return
	if not _active:
		_rest()
		return
	_in_water = world.get_block(Vector3i((global_position + Vector3(0, 0.6, 0)).floor())) == BlockIds.WATER
	if _sight.is_finite() and lp.distance_to(_sight) > BotRules.NOTICE_RADIUS:
		_clear_sight()                  # the player went on without it
	var target := _update_target(lp)
	if personality == BotRules.EXPLORER:
		_look_around()
	if personality == BotRules.BUILDER:
		_update_build(lp)
	# M2 Task 18: a child who keeps walking away gets more space (style.space, learned); owner 38: closer
	# when asked to follow
	var far := _talk_far(lp)
	var next := BotRules.choose_behaviour(personality, {
		"target": target != null,
		"far": far,
		"sight": _sight.is_finite(),
		"build_ready": not _plan.is_empty(),
		"wander_due": (_wander_t <= 0.0 or (behaviour == BotRules.WANDER and _wander_spot.is_finite())) and _talk_close_t <= 0.0,
		"order": _talk_order,      # owner 38: what the child asked for
		"asked_build": _plan_asked,
	})
	if next != behaviour:
		_enter(next)
	if behaviour == BotRules.FIGHT:
		_fight(target)
	elif behaviour == BotRules.POINT:
		_point()
	elif behaviour == BotRules.BUILD:
		_build_here()
	elif _talk_step(lp):   # owner 38: STAY, GUIDE, HIDE, DANCE
		pass
	elif behaviour == BotRules.FOLLOW:
		_go(lp, BotRules.FOLLOW_NEAR + style.space, RUN_SPEED if _flat(global_position, lp) > RUN_FROM else WALK_SPEED)
	elif behaviour == BotRules.WANDER and _wander_spot.is_finite():
		_go(_wander_spot, 1.0, WALK_SPEED)
		if _flat(global_position, _wander_spot) <= 1.2:
			_end_wander()
	else:
		_goal = Vector3.INF
		_face = lp
	_check_progress(lp)
	_mind_tick(leader, lp)   # M2 Task 18: what it learns about its child
	if _idle_chat_t <= 0.0 and behaviour in [BotRules.IDLE, BotRules.WANDER, BotRules.FOLLOW]:
		_idle_chat_t = _rng.randf_range(IDLE_CHAT.x, IDLE_CHAT.y)
		say(&"idle")


func _enter(next: StringName) -> void:
	_talk_enter(next)   # owner 38: a dance ends
	if behaviour == BotRules.POINT:
		pointing = false
	if next == BotRules.FIGHT:
		say(&"fight")
	if next == BotRules.WANDER and not _wander_spot.is_finite():
		var leader := _leader()
		var around := leader.global_position if leader else global_position
		var angle := _mind_guard(_rng.randf() * TAU)   # M2 Task 18: fighters stand guard where monsters come from
		_wander_spot = _mind_spaced(BotRules.wander_spot(personality, around, angle, _rng.randf()), around)
	behaviour = next
	held_item = BotRules.held_item(personality, next)
	_best_d = INF
	_stuck_t = 0.0


func _go(to: Vector3, stop_at: float, speed: float) -> void:
	_goal = to
	_stop_at = stop_at
	_speed = speed
	_face = to


func _rest() -> void:
	_active = false
	_goal = Vector3.INF
	velocity = Vector3.ZERO
	if behaviour != BotRules.IDLE:
		_enter(BotRules.IDLE)


## Walking towards a goal without getting closer for STUCK_TIME: a wall or a hole. Walking back to
## the player, it pops up next to them; anything else is given up.
func _check_progress(lp: Vector3) -> void:
	if not _goal.is_finite() or behaviour == BotRules.FIGHT:
		_stuck_t = 0.0
		_best_d = INF
		return
	var d := _flat(global_position, _goal)
	if d <= _stop_at + 0.5 or d < _best_d - 0.3:
		_best_d = d
		_stuck_t = 0.0
		return
	_stuck_t += BotRules.AI_INTERVAL
	if _stuck_t < STUCK_TIME:
		return
	_stuck_t = 0.0
	_best_d = INF
	if behaviour == BotRules.FOLLOW:
		_catch_up(lp)
	elif behaviour == BotRules.WANDER:
		_end_wander()
	elif behaviour == BotRules.POINT:
		_clear_sight()
	elif behaviour == BotRules.BUILD:
		_drop_plan()
	else:
		_talk_stuck()   # owner 38: a guide can't get through


func _end_wander() -> void:
	_wander_spot = Vector3.INF
	_wander_t = _rng.randf_range(2.0, 6.0)
	_goal = Vector3.INF


## Pops up next to the player (left behind, stuck, or fallen out of the world).
func _catch_up(lp: Vector3) -> void:
	var spot := spot_near(world, lp, _rng.randi())
	if not spot.is_finite():
		_rest()
		return
	global_position = spot
	velocity = Vector3.ZERO
	_active = true
	_goal = Vector3.INF
	_wander_spot = Vector3.INF
	_clear_sight()
	_enter(BotRules.IDLE)
	_rpc_poof.rpc(spot + Vector3(0, 0.2, 0))


# --- Fighting ---

## The monster to fight now (BotRules.choose_target), or null. Cheers once its monster is gone.
func _update_target(lp: Vector3) -> Node3D:
	var old := instance_from_id(_target_id) as Node3D if _target_id != 0 else null
	if _target_id != 0 and (old == null or old.is_queued_for_deletion() or not old.is_in_group(&"monsters")):
		if _hit_target:
			say(&"win")
		_target_id = 0
		_hit_target = false
	var monsters := _monsters_now()
	var spots: Array[Vector3] = []
	for m in monsters:
		spots.append(m.global_position)
	var i := BotRules.choose_target(personality, global_position, lp, spots, _talk_guard())   # owner 38: guard me
	var target: Node3D = monsters[i] if i >= 0 else null
	var id := target.get_instance_id() if target else 0
	if id != _target_id:
		_target_id = id
		_hit_target = false
		if target:
			_mind_saw_monster(target.global_position, lp)   # M2 Task 18
	return target


func _fight(target: Node3D) -> void:
	var center := _center_of(target)
	var radius := _radius_of(target)
	_go(target.global_position, MELEE_STOP + radius, RUN_SPEED)
	_face = center
	if _attack_t > 0.0 or chest().distance_to(center) > float(WeaponRules.stats(BotRules.WEAPON).reach) + radius:
		return
	_attack_t = BotRules.ATTACK_EVERY
	var dir := center - chest()
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 0.01 else -global_basis.z
	if combat:
		for hit: Dictionary in combat.bot_melee(chest(), dir, BotRules.WEAPON):
			if hit.node == target:
				_hit_target = true
	_rpc_swing.rpc()


static func _center_of(m: Node3D) -> Vector3:
	return m.call(&"hit_center") if m.has_method(&"hit_center") else m.global_position + Vector3(0, MONSTER_CENTER, 0)


static func _radius_of(m: Node3D) -> float:
	return float(m.call(&"hit_radius")) if m.has_method(&"hit_radius") else MONSTER_RADIUS


# --- Explorers ---

func _look_around() -> void:
	if _sight.is_finite() and _sight_t <= 0.0 and not pointing:
		_clear_sight()                  # couldn't get there
	if _sight.is_finite() or _scan_t > 0.0:
		return
	_scan_t = SCAN_EVERY
	if _seen.size() > MEMORY:
		_seen.clear()
	var center := Vector3i(global_position.floor())
	var origin := center - SCAN_HALF
	var finds := BotRules.find_in_buffer(world.copy_box(origin, SCAN_HALF * 2 + Vector3i.ONE), origin, BotRules.SHINY)
	var cell := BotRules.nearest_open(center, finds, world.get_block, _seen)
	var animal: Animal = null
	for n in get_tree().get_nodes_in_group(&"animals"):
		var a := n as Animal
		if a == null or a.is_pet() or a.is_queued_for_deletion() or _seen.has(a.animal_id):
			continue
		if AnimalRules.SPECIES[a.species].tameable and a.global_position.distance_to(global_position) <= ANIMAL_NOTICE:
			animal = a
			break
	# M2 Task 18: with both around, the mind shows first what its child follows (and shows less of
	# what the child keeps walking past).
	var kind := _mind_pick_find(cell != BotRules.NO_CELL, animal != null)
	if kind == BotSpecies.FIND_ORE:
		_seen[cell] = true
		_set_sight(Vector3(cell) + Vector3(0.5, 1.0, 0.5), &"shiny", "")
		_mind_pointed(kind, cell, null, Vector3(cell) + Vector3(0.5, 1.0, 0.5))
	elif kind == BotSpecies.FIND_ANIMAL:
		_seen[animal.animal_id] = true
		_set_sight(animal.global_position, &"animal", "")
		_mind_pointed(kind, BotRules.NO_CELL, animal, animal.global_position)


func _set_sight(point: Vector3, kind: StringName, text: String) -> void:
	_sight = point
	_sight_kind = kind
	_sight_text = text
	_sight_t = SIGHT_TIME
	pointing = false


func _clear_sight() -> void:
	_sight = Vector3.INF
	pointing = false


func _point() -> void:
	_go(_sight, POINT_STOP, WALK_SPEED)
	if _flat(global_position, _sight) > POINT_REACH or absf(global_position.y - _sight.y) > 6.0:
		return
	_goal = Vector3.INF
	if not pointing:
		pointing = true
		_point_t = POINT_TIME
		say_text(_sight_text if _sight_text != "" else BotRules.line(_sight_kind, personality, 0, bot_name))
		_rpc_sparkle.rpc(_sight)
	elif _point_t <= 0.0:
		_clear_sight()


# --- Builders ---

func _update_build(lp: Vector3) -> void:
	if not _plan.is_empty():
		if _flat(Vector3(_plan[0][0]), lp) > BotRules.BUILD_NEAR + 5.0:
			_drop_plan()                # the player went on: build next to their next build
		return
	if _build_t > 0.0 or director == null:
		return
	_build_t = BotRules.BUILD_RETRY
	var anchor := director.build_anchor(lp)
	if anchor == BotRules.NO_CELL:
		return
	var reader := world.box_reader(anchor - Vector3i(6, 5, 6), Vector3i(14, 13, 14))
	_plan = BotRules.plan_build(anchor, _mind_design(_rng.randi()), reader, _rng.randi(), _bodies())   # M2 Task 18: its child's style
	_build_wait = 0.0


func _build_here() -> void:
	if _talk_build_step():   # owner 38: a build the child asked for, a few blocks at a time
		return
	var base: Vector3i = _plan[0][0]
	var site := Vector3(base) + Vector3(0.5, 0.0, 0.5)
	_go(site, BUILD_STOP, WALK_SPEED)
	if _flat(global_position, site) > BUILD_REACH:
		return
	_goal = Vector3.INF
	if not BotRules.plan_fits(_plan, world.get_block, _bodies()):
		_build_wait += BotRules.AI_INTERVAL
		if _build_wait >= BUILD_WAIT or not BotRules.plan_fits(_plan, world.get_block, []):
			_drop_plan()                # somebody built there, or stays in the way
		return
	var placed := director.place(self, _plan) if director else Session.bot_set_blocks(_plan, eye_position())
	_mind_built(_plan)   # M2 Task 18: will the child keep it?
	_plan = []
	_build_t = asks.build_every(BotRules.BUILD_EVERY, clock)   # owner 38: sooner for a child who asks for builds
	if placed > 0:
		_rpc_swing.rpc()
		_rpc_poof.rpc(site + Vector3(0, 0.5, 0))
		say(&"build")


func _drop_plan() -> void:
	_plan = []
	_build_t = BotRules.BUILD_RETRY


## Every player's and every friend's body (no block goes where someone stands).
func _bodies() -> Array[AABB]:
	var out: Array[AABB] = []
	for p in _players_now():
		out.append(PlacementRules.player_aabb(p.global_position, p.size_scale()))
	for n in get_tree().get_nodes_in_group(&"bot_friends"):
		out.append(PlacementRules.player_aabb((n as Node3D).global_position))
	return out


# --- Knocked out and back ---

func _knock_out() -> void:
	knocked_out = true
	_ko_t = BotRules.KNOCKOUT_TIME
	velocity = Vector3.ZERO
	remove_from_group(&"bots")         # monsters stop chasing it
	collision_layer = 0
	_clear_sight()
	_plan = []
	_target_id = 0
	_goal = Vector3.INF
	_enter(BotRules.IDLE)
	visible = false
	say(&"knocked_out")
	_rpc_confetti.rpc(global_position + Vector3(0, 1.0, 0))


## Back next to the player with full hearts (and a moment of protection), once there is a player
## and ground to stand on.
func _come_back() -> void:
	var leader := _leader()
	var spot := spot_near(world, leader.global_position, _rng.randi()) if leader else Vector3.INF
	if not spot.is_finite():
		return
	global_position = spot
	velocity = Vector3.ZERO
	health.revive()
	knocked_out = false
	add_to_group(&"bots")
	collision_layer = LAYER
	visible = true
	_active = true
	say(&"back")
	_rpc_poof.rpc(spot + Vector3(0, 1.0, 0))


# --- Moving ---

func _move(delta: float) -> void:
	var dir := Vector3.ZERO
	if _goal.is_finite():
		var to := _goal - global_position
		to.y = 0.0
		var d := to.length()
		if d > _stop_at:
			dir = to / d
	var speed := _speed * (WATER_FACTOR if _in_water else 1.0)
	velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta)
	if _in_water:
		velocity.y = move_toward(velocity.y, SWIM_UP, 12.0 * delta)
	elif is_on_floor():
		if dir != Vector3.ZERO and is_on_wall():
			velocity.y = JUMP_VELOCITY        # a ledge in the way: hop onto it
	else:
		velocity.y -= GRAVITY * delta
	var look_at := dir
	if look_at == Vector3.ZERO and _face.is_finite():
		look_at = _face - global_position
		look_at.y = 0.0
	if look_at.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-look_at.x, -look_at.z), clampf(10.0 * delta, 0.0, 1.0))
	move_and_slide()


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func _grounded(p: Player) -> bool:
	return p.physics_mode == PhysicsMode.Mode.NORMAL and p.is_on_floor()


func _leader() -> Player:
	var fallback: Player = null
	for p in _players_now():
		if p.peer_id == leader_peer:
			return p
		if fallback == null:
			fallback = p
	return fallback


## Every player, refreshed once per physics frame and shared by all bots (like animals).
func _players_now() -> Array[Player]:
	var frame := Engine.get_physics_frames()
	if frame != _players_frame or not _players.all(is_instance_valid):
		_players_frame = frame
		_players.clear()
		_player_spots.clear()
		for n in get_tree().get_nodes_in_group(&"players"):
			var p := n as Player
			if p and not p.is_queued_for_deletion():
				_players.append(p)
				_player_spots.append(p.global_position)
	return _players


func _spots() -> Array[Vector3]:
	_players_now()
	return _player_spots


## Every monster that can still fight, refreshed once per physics frame and shared by all bots.
func _monsters_now() -> Array[Node3D]:
	var frame := Engine.get_physics_frames()
	var stale := frame != _monsters_frame
	for m in _monsters:
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			stale = true
			break
	if stale:
		_monsters_frame = frame
		_monsters.clear()
		for n in get_tree().get_nodes_in_group(&"monsters"):
			var m := n as Node3D
			if m and not m.is_queued_for_deletion():
				_monsters.append(m)
	return _monsters


# --- Every peer: looks ---

func _process(delta: float) -> void:
	visible = not knocked_out and game_pose != POSE_INSIDE   # M4 H: gone into a hiding spot
	if avatar == null:
		return
	_game_look()
	var speed: float
	var on_floor: bool
	if multiplayer.is_server():
		speed = Vector2(velocity.x, velocity.z).length()
		on_floor = is_on_floor() or _in_water or velocity.is_zero_approx()
	else:
		var moved := global_position - _last_pos
		speed = Vector2(moved.x, moved.z).length() / maxf(delta, 0.001)
		on_floor = absf(moved.y) / maxf(delta, 0.001) < 1.0
	_last_pos = global_position
	avatar.animate(speed, on_floor, delta)
	_mind_show()   # M2 Task 18: the thought bubble
	if pointing != _aiming and avatar.has_method(&"set_aiming"):
		_aiming = pointing
		avatar.call(&"set_aiming", pointing)     # both arms stretched out towards it
	_update_held()


## This device's graphics style (like players): the blocky body or a real-looking person.
func set_avatar_style(style: String) -> void:
	var realistic := style == "realistic" and RealisticAvatar.load_model() != null
	if avatar and (avatar is BotRealisticAvatar) == realistic:
		return
	var next: AvatarModel
	if realistic:
		var person := BotRealisticAvatar.new()
		person.bot_look = look
		next = person
	else:
		var blocky := BotBlockyAvatar.new()
		blocky.bot_look = look
		next = blocky
	if avatar:
		next.transform = avatar.transform
		if _held and _held.get_parent():
			_held.get_parent().remove_child(_held)
		remove_child(avatar)
		avatar.queue_free()
	next.name = "Avatar"
	add_child(next)
	avatar = next
	_aiming = false
	_update_held()


func _on_settings(settings: Dictionary) -> void:
	set_avatar_style(str(settings.get("style", "blocky")))


func _update_held() -> void:
	var hand := avatar.hand()
	if hand == null:
		return
	if _held == null:
		_held = HeldItem.new()
	if _held.get_parent() != hand:
		if _held.get_parent():
			_held.get_parent().remove_child(_held)
		hand.add_child(_held)
	if _held.item_id != held_item:
		_held.show_item(held_item)


## A little robot face over the name: bot friends are always shown as bots (lead's ruling).
static func robot_badge() -> ImageTexture:
	if _badge == null:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var metal := Color("d9e2ec")
		var dark := Color("2b3440")
		var eye := Color("46e0ff")
		var red := Color("ff5a4f")
		for y in range(0, 2):
			for x in range(7, 9):
				img.set_pixel(x, y, red)
		for y in range(2, 4):
			for x in range(7, 9):
				img.set_pixel(x, y, dark)
		for y in range(4, 15):
			for x in range(2, 14):
				img.set_pixel(x, y, dark if x == 2 or x == 13 or y == 4 or y == 14 else metal)
		for y in range(7, 11):
			img.set_pixel(1, y, dark)
			img.set_pixel(14, y, dark)
		for y in range(7, 9):
			for x in [5, 6, 9, 10]:
				img.set_pixel(x, y, eye)
		for x in range(5, 11):
			img.set_pixel(x, 11, dark)
		_badge = ImageTexture.create_from_image(img)
	return _badge


@rpc("authority", "call_local", "unreliable")
func _rpc_swing() -> void:
	var arm := avatar != null and avatar.has_method(&"play_attack")
	if arm:
		avatar.call(&"play_attack", held_item, 0)
	if _held:
		_held.play_attack(held_item, 0, arm)
	Audio.play(&"swing", global_position, -4.0)


@rpc("authority", "call_local", "unreliable")
func _rpc_hurt_fx() -> void:
	Fx.burst(get_tree().root, global_position + Vector3(0, 1.1, 0), Color("ff6b6b"), 8, 3.0, 0.1, 0.4, 8.0)
	Audio.play(&"hit", global_position, -4.0)


@rpc("authority", "call_local", "reliable")
func _rpc_confetti(at: Vector3) -> void:
	for c in [Color("ff5c8a"), Color("ffd23f"), Color("46e0ff"), Color("7ee06b")]:
		Fx.burst(get_tree().root, at, c, 10, 5.0, 0.12, 1.0, 6.0)
	Audio.play(&"air_jump", at)


@rpc("authority", "call_local", "unreliable")
func _rpc_poof(at: Vector3) -> void:
	Fx.burst(get_tree().root, at, Color(1, 1, 1, 0.9), 12, 2.5, 0.12, 0.45, 2.0)


@rpc("authority", "call_local", "reliable")
func _rpc_sparkle(at: Vector3) -> void:
	for i in 3:
		Fx.burst(get_tree().root, at + Vector3(0, 0.3 * i, 0), Color("ffe066"), 12, 2.5, 0.08, 0.9, 1.0)
	Audio.play(&"ding", at, -2.0)

# --- M2 Task 18: creature minds (owner feedback #24, spec §12.17) ---------------------------------
# A friend's Mind (BotSpecies, a net of its own) and BotStyle learn its child's style: a builder
# builds with the child's favourite blocks and shapes and keeps to designs the child keeps; an
# explorer shows first what the child follows (ores, animals, secrets) and less of what the child
# walks past; a child who keeps walking away gets more space; a fighter stands guard on the side
# the monsters come from. A lesson lights a bulb over its head. Its lines stay fixed (BotRules,
# BotSpecies.greeting) and it still never takes anything. Saved with it in WorldMeta.bots. Host only.

const KEPT_AFTER := 60.0          # a build still standing this long was kept
const FIND_WAIT := 45.0           # how long it watches what the child does with a find
const FOLLOWED_NEAR := 4.0        # the child came this close to a find: followed it
const USED_NEAR := 3.0            # ... this close to a secret: went to see it
const ARRIVE_WINDOW := 3.0        # the child walking off this soon after the friend came close
const SPACE_GAP := 8.0            # at most one space lesson this often
const SKIP_SCORE := -1.0          # a kind of find scored this low is often not shown at all
const THOUGHT_NEAR := 16.0
const THOUGHT_HEIGHT := 3.55      # above the robot badge

var mind: Mind
var style := BotStyle.new()
## Synced (on change): the picture over its head, Thought.NONE when there is none.
var thought := Thought.NONE
var _thought_t := 0.0
var _shown_thought := Thought.NONE
var _pick_action := -1
var _pick_hidden := PackedFloat32Array()
var _plan_action := -1
var _plan_hidden := PackedFloat32Array()
var _build_cells: Array[Vector3i] = []
var _build_action := -1
var _build_hidden := PackedFloat32Array()
var _build_at := 0.0
var _find_kind := &""
var _find_action := -1
var _find_hidden := PackedFloat32Array()
var _find_cell := BotRules.NO_CELL
var _find_node := 0
var _find_point := Vector3.INF
var _find_at := 0.0
var _find_followed := false
var _was_following := false
var _arrived_at := -INF
var _space_t := -INF


## For WorldMeta.bots: its mind (memory, drives, learning) and what it learned of its child's style.
func mind_save() -> Dictionary:
	var d := mind.to_save()
	d.s = style.to_save()
	d.a = asks.to_save(clock)   # owner 38: what its child asks for
	return d


func mind_load(saved: Variant) -> void:
	if not saved is Dictionary:
		return
	mind.load_save(saved)
	style = BotStyle.from_save((saved as Dictionary).get("s"))
	asks = BotAsks.from_save((saved as Dictionary).get("a"), clock)   # owner 38


## Host: says hello — by the child's name when it knows its child from a saved world — and keeps its
## child in its memory for good.
func mind_hello() -> void:
	var leader := _leader()
	var who := child_name(leader) if leader else ""
	if who != "" and mind.memory.knows(who):
		say_text(BotSpecies.greeting(who, bot_name, personality))
	else:
		say(&"hello")
	if who != "":
		mind.memory.pin(who)


## The child's username (their chat name; this game's own username for the host's player), or "".
func child_name(p: Player) -> String:
	var who := str(Session.chat_names.get(p.peer_id, ""))
	if who == "" and p.peer_id == multiplayer.get_unique_id():
		who = str(Profile.data.username)
	return who


## Host (the director): the child placed `id` at `cell` (their block before it: `prev`).
func mind_saw_block(id: int, cell: Vector3i, prev: Vector3i) -> void:
	style.saw_block(id, cell, prev)


## Host (the director): a block was broken at `cell`; one of its build's blocks: a lesson.
func mind_block_broken(cell: Vector3i) -> void:
	if _build_cells.has(cell):
		_build_cells.clear()
		_lesson(_build_action, _build_hidden, &"broken")


func _mind_tick(leader: Player, lp: Vector3) -> void:
	var t0 := Time.get_ticks_usec() if Mind.profiling else 0
	mind.tick(BotRules.AI_INTERVAL)
	_mind_space(leader, lp)
	if not _build_cells.is_empty() and mind.clock - _build_at >= KEPT_AFTER:
		_check_kept()
	if _find_kind != &"":
		_check_find(lp)
	_mind_thoughts()
	if Mind.profiling:
		Mind.note_cost(Time.get_ticks_usec() - t0)


## Which design to build next (the mind picks; Sandbox builds are made of the child's blocks,
## Survivor ones stay leaves: Task 15's ruling).
func _mind_design(pick: int) -> Array:
	var survivor := ModeRules.valid(Game.mode) == ModeRules.SURVIVOR
	var designs: Array = BotRules.SURVIVOR_DESIGNS if survivor else BotRules.SANDBOX_DESIGNS
	var i := BotSpecies.pick_design(mind, style, designs.size())
	if i < 0 or i >= designs.size():
		return BotRules.build_design(Game.mode, pick)
	_plan_action = i
	_plan_hidden = mind.last_hidden()
	return designs[i] if survivor else style.style_design(designs[i])


func _mind_built(plan: Array) -> void:
	_build_cells.clear()
	for cell: Array in plan:
		if world.get_block(cell[0]) == int(cell[1]):
			_build_cells.append(cell[0])
	_build_action = _plan_action
	_build_hidden = _plan_hidden
	_build_at = mind.clock


func _check_kept() -> void:
	var standing := 0
	for cell in _build_cells:
		if world.get_block(cell) != BlockIds.AIR:
			standing += 1
	var kept := standing * 2 >= _build_cells.size()
	_build_cells.clear()
	if kept:
		_lesson(_build_action, _build_hidden, &"kept")


## Which kind of find to show (FIND_ORE / FIND_ANIMAL / FIND_SECRET among those around), or &"".
func _mind_pick_find(ore: bool, animal: bool, secret := false) -> StringName:
	var kinds: Array[StringName] = []
	if ore:
		kinds.append(BotSpecies.FIND_ORE)
	if animal:
		kinds.append(BotSpecies.FIND_ANIMAL)
	if secret:
		kinds.append(BotSpecies.FIND_SECRET)
	if kinds.is_empty():
		return &""
	var kind := BotSpecies.pick_find(mind, BotSpecies.find_mask(kinds))
	_pick_action = mind.action
	_pick_hidden = mind.last_hidden()
	if not secret and kinds.size() == 1 and mind.scores[mind.action] < SKIP_SCORE and mind.roll() < 0.6:
		return &""                        # the child never follows these: not every time
	return kind


func _mind_pointed(kind: StringName, cell: Vector3i, animal: Animal, point: Vector3) -> void:
	if _find_kind != &"":
		_find_done(&"followed" if _find_followed else &"ignored")
	_find_kind = kind
	_find_action = _pick_action
	_find_hidden = _pick_hidden
	_find_cell = cell
	_find_node = animal.get_instance_id() if animal else 0
	_find_point = point
	_find_at = mind.clock
	_find_followed = false


## What the child did with the find: mined the ore, tamed the animal, went to the secret (used);
## came over (followed); or walked on.
func _check_find(lp: Vector3) -> void:
	var target := _find_point
	var used := false
	if _find_kind == BotSpecies.FIND_ORE:
		used = world.get_block(_find_cell) == BlockIds.AIR
	elif _find_kind == BotSpecies.FIND_ANIMAL:
		var a := instance_from_id(_find_node) as Animal if _find_node != 0 else null
		if a == null or a.is_queued_for_deletion():
			_find_kind = &""              # it went away: no lesson
			return
		used = a.is_pet()
		target = a.global_position
	else:
		used = lp.distance_to(_find_point) <= USED_NEAR
	if lp.distance_to(target) <= FOLLOWED_NEAR:
		_find_followed = true
	if used:
		_find_done(&"used")
	elif mind.clock - _find_at >= FIND_WAIT:
		_find_done(&"followed" if _find_followed else &"ignored")


func _find_done(event: StringName) -> void:
	_find_kind = &""
	_lesson(_find_action, _find_hidden, event)


func _lesson(action: int, hidden: PackedFloat32Array, event: StringName) -> void:
	mind.credit(action, hidden, float(BotSpecies.REWARDS.get(event, 0.0)))
	mind.show_thought(Thought.BULB, true)   # an answer to what the child did


## A monster to fight at `pos` near the child at `lp`: fighters remember the side.
func _mind_saw_monster(pos: Vector3, lp: Vector3) -> void:
	if personality == BotRules.FIGHTER and mind:
		style.note_danger(atan2(pos.z - lp.z, pos.x - lp.x))


## Where a fighter wanders: towards the side monsters come from (a little either way).
func _mind_guard(angle: float) -> float:
	var guard := style.guard_angle() if personality == BotRules.FIGHTER else NAN
	return angle if is_nan(guard) else guard + (angle - PI) * 0.08


## A wander spot around the child, moved out by the space the child likes.
func _mind_spaced(spot: Vector3, around: Vector3) -> Vector3:
	var out := Vector3(spot.x - around.x, 0.0, spot.z - around.z)
	if style.space <= 0.0 or out.length() < 0.01:
		return spot
	return spot + out.normalized() * style.space


## The child walking off right after the friend came close to them: more space; the child coming
## up close to a friend standing still: a little less.
func _mind_space(leader: Player, lp: Vector3) -> void:
	var d := _flat(global_position, lp)
	var v := Vector3(leader.velocity.x, 0.0, leader.velocity.z)
	var following := behaviour == BotRules.FOLLOW
	if _was_following and not following and d <= BotRules.FOLLOW_NEAR + style.space + 1.5 and v.length() < 0.5:
		_arrived_at = mind.clock
	_was_following = following
	if mind.clock - _space_t < SPACE_GAP or d < 0.01:
		return
	var away := v.dot(Vector3(lp.x - global_position.x, 0.0, lp.z - global_position.z) / d)
	if mind.clock - _arrived_at <= ARRIVE_WINDOW and away > 2.0 and d > BotRules.FOLLOW_NEAR + style.space + 1.0:
		style.walked_away()
		_space_t = mind.clock
		_arrived_at = -INF
		mind.show_thought(Thought.BULB, true)
	elif behaviour == BotRules.IDLE and away < -2.0 and d < 2.2:
		style.came_close()
		_space_t = mind.clock


func _mind_thoughts() -> void:
	if thought != Thought.NONE:
		_thought_t -= BotRules.AI_INTERVAL
		if _thought_t <= 0.0:
			thought = Thought.NONE
		return
	var t := mind.take_thought()
	if t == Thought.NONE:
		return
	for p in _spots():
		if p.distance_to(global_position) <= THOUGHT_NEAR:
			thought = t
			_thought_t = ThoughtBubble.SHOW_TIME
			return


## Every peer: shows or hides the bubble when the synced thought changes.
func _mind_show() -> void:
	if thought == _shown_thought:
		return
	_shown_thought = thought
	if thought == Thought.NONE:
		ThoughtBubble.hide_on(self)
	else:
		ThoughtBubble.show_on(self, thought, THOUGHT_HEIGHT)

# --- M3 Task 7: racing a recorded run ---------------------------------------------------------------

## Host: this friend finished its race (ms on its own clock: the recorded run's time at its speed).
signal race_done(bot: BotFriend, ms: int)

const RACE_WAIT := 60.0           # waits this long by START for a runner to start the course
const RACE_SIDE := Vector3(1.2, 0.0, 0.0)
const RACE_READY_LINE := "Ready! Step on START and let's race!"
const RACE_DONE_LINE := "I finished! Great race!"
const RACE_LATER_LINE := "Let's race another time!"

var _race_run: RecordedRun        # host: the best run it replays as its own (null: not racing)
var _race_speed := 1.0
var _race_t := -1.0               # seconds into its run; < 0 while it waits by START
var _race_wait := 0.0


## Host (CourseDirector.race_bot): stands by START and waits for a runner to start; then replays `run` at
## `speed` (a little faster or slower than the recording) as its own run. Cheap: no pathfinding, no physics.
func race_ready(run: RecordedRun, speed: float, wait: float = RACE_WAIT) -> void:
	if run == null or run.size() < 2:
		return
	_race_run = run
	_race_speed = clampf(speed, 0.5, 2.0)
	_race_t = -1.0
	_race_wait = wait
	_goal = Vector3.INF
	velocity = Vector3.ZERO
	global_position = run.sample_at(0.0) + RACE_SIDE
	say_text(RACE_READY_LINE)
	_rpc_poof.rpc(global_position + Vector3(0, 1.0, 0))


## Host: a runner started the course: go!
func race_go() -> void:
	if _race_run != null and _race_t < 0.0:
		_race_t = 0.0


func race_cancel() -> void:
	_race_run = null
	_race_t = -1.0
	velocity = Vector3.ZERO


func is_racing() -> bool:
	return _race_run != null


func race_running() -> bool:
	return _race_run != null and _race_t >= 0.0


## Host: one step of the race (true while racing: the friend's usual simulation waits).
func _race_tick(delta: float) -> bool:
	if _race_run == null:
		return false
	if _race_t < 0.0:
		velocity = Vector3.ZERO
		_race_wait -= delta
		if _race_wait <= 0.0:
			say_text(RACE_LATER_LINE)
			race_cancel()
		return true
	_race_t += delta * _race_speed
	var pos := _race_run.sample_at(_race_t)
	var moved := pos - global_position
	velocity = Vector3(moved.x, 0.0, moved.z) / maxf(delta, 0.001)
	global_position = pos
	var face := _race_run.facing_at(_race_t)
	if face != Vector3.ZERO:
		rotation.y = atan2(-face.x, -face.z)
	if _race_t >= _race_run.duration():
		var ms := roundi(_race_run.duration() / _race_speed * 1000.0)
		race_cancel()
		_rpc_confetti.rpc(global_position + Vector3(0, 1.0, 0))
		say_text(RACE_DONE_LINE)
		race_done.emit(self, ms)
	return true

# --- M4 H: co-op games (hide-and-seek, Storm Run, the team photo) ---------------------------------
# A game (the host's GamesDirector) steers a friend for a while: `game_brain` is asked first at every
# decision and returns true when it decided (the friend's own behaviour waits meanwhile). The brain moves
# it with game_go / game_hold and hides it with game_set_pose; the pose is synced, so every game shows
# it crouching, or gone into a barrel or closet (a hidden friend's name tag goes with it).

const POSE_NONE := 0
const POSE_CROUCH := 1
const POSE_INSIDE := 2
const NO_SPOT := Vector3i(0, -100000, 0)

## Host: (bot: BotFriend) -> bool; unset when no game needs this friend.
var game_brain: Callable
## Synced: POSE_NONE, POSE_CROUCH or POSE_INSIDE.
var game_pose := POSE_NONE
## Host: the barrel or closet this friend is inside (NO_SPOT: none).
var game_hidden_in := NO_SPOT

var _game_from := Vector3.INF
var _shown_pose := -1


## Host: walk (or run) to `to`, stopping `stop_at` away.
func game_go(to: Vector3, stop_at: float, speed: float) -> void:
	_active = true
	_go(to, stop_at, speed)


## Host: stand still, facing `face` (INF: as it is).
func game_hold(face: Vector3 = Vector3.INF) -> void:
	_active = game_pose != POSE_INSIDE   # inside a spot nothing moves (no gravity through the barrel)
	_goal = Vector3.INF
	velocity = Vector3(0.0, velocity.y, 0.0) if _active else Vector3.ZERO
	if face.is_finite():
		_face = face


## Host: the flat distance to `to`.
func game_distance(to: Vector3) -> float:
	return _flat(global_position, to)


## Host: crouch, stand, or go into the barrel or closet at `cell` (POSE_INSIDE) and come out of it on the
## side it went in.
func game_set_pose(pose: int, cell: Vector3i = NO_SPOT) -> void:
	if pose == POSE_INSIDE and cell != NO_SPOT:
		if game_hidden_in == NO_SPOT:
			_game_from = global_position
		game_hidden_in = cell
		collision_layer = 0
		collision_mask = 0
		velocity = Vector3.ZERO
		_active = false
		_goal = Vector3.INF
		global_position = Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)
	elif game_hidden_in != NO_SPOT:
		var was := game_hidden_in
		game_hidden_in = NO_SPOT
		collision_layer = LAYER if not knocked_out else 0
		collision_mask = 1
		var back := _game_from if _game_from.is_finite() else global_position
		if world:
			back = StealthRules.search_spot(was, back, func(c: Vector3i) -> bool: return BlockIds.is_solid(world.get_block(c)))
		global_position = back
		velocity = Vector3.ZERO
		_active = true
	game_pose = pose if pose != POSE_INSIDE or game_hidden_in != NO_SPOT else POSE_NONE


## The eyes a seeker's look aims at: lower while crouching.
func game_eye() -> Vector3:
	return global_position + Vector3(0, CameraRig.HEAD_HEIGHT * (StealthRules.CROUCH_EYE if game_pose == POSE_CROUCH else 1.0), 0)


## Every peer: a crouching friend's body is lower (like a crouching player's).
func _game_look() -> void:
	if game_pose == _shown_pose:
		return
	_shown_pose = game_pose
	avatar.scale.y = StealthRules.CROUCH_BODY if game_pose == POSE_CROUCH else 1.0
	if _tag:
		_tag.position.y = 2.45 * (StealthRules.CROUCH_BODY if game_pose == POSE_CROUCH else 1.0)

# --- Owner 38: talking with the child (spec §12.14a) ------------------------------------------------
# The child's words reach this friend through its director (BotDirector.hear, host only): it switches
# behaviour — BotRules' talk behaviours STAY, GUIDE, HIDE and DANCE, following closer, guarding a wider
# circle, a build the child asked for — and answers with a fixed line (BotAnswers) in the child's
# language. Its BotAsks remembers what its child asks for (saved with its mind). Answers are never held
# back by the 20 s chat gap; the host's rate limit on the child's words keeps them few.

var asks := BotAsks.new()
var _talk_order: StringName = &""    # STAY / GUIDE / HIDE / DANCE while the child's request lasts
var _talk_t := 0.0                   # the order's time left (s)
var _talk_point := Vector3.INF       # where it stays, leads to or runs to
var _talk_home := false              # waiting at the child's home: no time limit, no leash
var _talk_run := false               # hiding by running from monsters
var _talk_arrived := false           # a guide got there and points at it
var _talk_close_t := 0.0             # following close this long
var _talk_guard_t := 0.0             # guarding a wider circle this long
var _talk_lang: StringName = BotAnswers.EN
var _talk_picks := {}                # line key -> times said (answers take turns)
var _talk_way_t := 0.0
var _plan_asked := false             # the plan is a build the child asked for
var _plan_what: StringName = &""
var _build_step_t := 0.0


## What the child asked for that is still going on (&"" for none).
func talk_order() -> StringName:
	return _talk_order


## Building what the child asked for.
func talk_building() -> bool:
	return _plan_asked and not _plan.is_empty()


## What it is doing, for "what are you doing?" (a BotAnswers.DOING key).
func talk_doing() -> StringName:
	if is_racing():
		return &"race"
	if _talk_order == BotRules.STAY:
		return &"home" if _talk_home else &"stay"
	if _talk_order == BotRules.HIDE:
		return &"run" if _talk_run else &"hide"
	if _talk_order != &"":
		return _talk_order
	if talk_building():
		return &"build"
	if _talk_guard_t > 0.0 and behaviour != BotRules.FIGHT:
		return &"guard"
	return behaviour


## Waiting at the child's home.
func talk_at_home() -> bool:
	return _talk_order == BotRules.STAY and _talk_home


## The language of its answers: always English (owner #52: English only; BotIntents.parse's lang is EN).
func talk_language(_lang: StringName) -> void:
	_talk_lang = BotAnswers.EN


## Host: says `text` now, as an answer to its child; its own chatter waits CHAT_GAP after it.
func talk_reply(text: String) -> void:
	if text == "":
		return
	_last_said = clock
	Session.bot_say(bot_name, text)


## A line of `key` in its child's language (each key's lines in turn); `we`: several friends answer.
func talk_line(key: StringName, we: bool = false) -> String:
	var n := int(_talk_picks.get(key, 0))
	_talk_picks[key] = n + 1
	return BotAnswers.line(key, _talk_lang, n, we)


## "follow me", "come here", "look!": closer for `seconds`; whatever it was asked before ends.
func talk_follow(seconds: float = BotRules.CLOSE_TIME) -> void:
	_talk_end_order()
	_talk_close_t = maxf(_talk_close_t, seconds)
	_end_wander()
	if is_racing() and not race_running():
		race_cancel()


## "wait", "stay", "stop": stands at `at` (or waits at the child's home) until called.
func talk_stay(at: Vector3, home: bool = false, seconds: float = BotRules.STAY_TIME) -> void:
	_talk_set(BotRules.STAY, at, INF if home else seconds)
	_talk_home = home
	_talk_close_t = 0.0
	_clear_sight()
	if home and _flat(global_position, at) > BotRules.HOME_POP:
		var spot := spot_near(world, at, _rng.randi())
		if spot.is_finite():
			global_position = spot
			velocity = Vector3.ZERO
			_goal = Vector3.INF
			_rpc_poof.rpc(spot + Vector3(0, 1.0, 0))


## "give me space": keeps more space from now on and steps back from the child for a while.
func talk_space() -> void:
	for i in BotRules.SPACE_MORE:
		style.walked_away()
	var leader := _leader()
	if leader == null:
		return
	var lp := leader.global_position
	var away := Vector3(global_position.x - lp.x, 0.0, global_position.z - lp.z)
	if away.length() < 0.1:
		away = Vector3(1, 0, 0)
	talk_stay(lp + away.normalized() * (BotRules.follow_far(personality) + style.space * 0.5), false, BotRules.SPACE_TIME)


## "guard me", "protect me", "help!": close to the child, fighting monsters in a wider circle.
func talk_guard(seconds: float = BotRules.GUARD_TIME) -> void:
	talk_follow(seconds)
	_talk_guard_t = maxf(_talk_guard_t, seconds)


## "run away", "hide": runs away from `monsters` (spots near the child), or hides quietly behind the child.
func talk_hide(monsters: Array[Vector3]) -> void:
	var leader := _leader()
	if leader == null:
		return
	var lp := leader.global_position
	if monsters.is_empty():
		_talk_set(BotRules.HIDE, lp - facing_of(leader) * 2.5, BotRules.HIDE_TIME)
		return
	_talk_set(BotRules.HIDE, _run_spot(lp, monsters), BotRules.RUN_TIME)
	_talk_run = true


## "dance", "do a trick": plays a dance (or a trick) where it stands.
func talk_dance(trick: bool) -> void:
	_talk_set(BotRules.DANCE, global_position, BotRules.TRICK_TIME if trick else BotRules.DANCE_TIME)
	_goal = Vector3.INF
	velocity = Vector3(0.0, velocity.y, 0.0)
	var dance := BotRules.TRICK if trick else BotRules.DANCES[_rng.randi() % BotRules.DANCES.size()]
	_rpc_emote.rpc(dance)


## "find treasure", "where is Tilly?": leads the child to `to`, waiting when the child falls behind.
func talk_guide(to: Vector3) -> void:
	_talk_set(BotRules.GUIDE, to, BotRules.GUIDE_TIME)
	_clear_sight()
	_talk_way_t = 0.0


## "build a house / a tower / a wall" (BotIntents.HOUSE / TOWER / WALL; &"": a small design of its own) next
## to the child, `mine`: with the child's blocks (Sandbox; Survivor builds stay leaves). &"" when it will
## build, else why not (a BotAnswers line key).
func talk_build(what: StringName, mine: bool) -> StringName:
	var leader := _leader()
	if leader == null or world == null:
		return &"no_room"
	var survivor := ModeRules.valid(Game.mode) == ModeRules.SURVIVOR
	var block := _talk_block(leader, mine, survivor)
	var design: Array
	if what == &"":
		design = BotRules.build_design(Game.mode, _rng.randi())
		if block >= 0:
			design = BotRules.request_design(BotIntents.TOWER, block).slice(0, 3)
	else:
		design = BotRules.request_design(what, block)
	var anchor := Vector3i(leader.global_position.floor())
	var reader := world.box_reader(anchor - Vector3i(8, 6, 8), Vector3i(17, 16, 17))
	var plan := BotRules.plan_build(anchor, design, reader, _rng.randi(), _bodies())
	if plan.is_empty():
		return &"no_room"
	_talk_end_order()
	_plan = plan
	_plan_asked = true
	_plan_what = what
	_build_step_t = 0.0
	return &""


## Kind words from its child: it likes them a little more, and a heart shows.
func talk_kind(child: Player) -> void:
	var who := child_name(child) if child else ""
	if who != "":
		mind.memory.feel_about(who, 0.1, 0.0, mind.clock)
	mind.show_thought(Thought.HEART, true)


## "where are you?": a sparkle over its head, so the child finds it.
func talk_wave() -> void:
	_rpc_sparkle.rpc(global_position + Vector3(0, 2.6, 0))


## Where a player looks (their camera on their own game, else their body's turn), flat.
static func facing_of(p: Player) -> Vector3:
	var yaw: float = p.avatar.rotation.y if p.avatar else 0.0
	if p.is_local and p.rig:
		yaw = p.rig.yaw
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func _talk_set(order: StringName, point: Vector3, seconds: float) -> void:
	_talk_end_order()
	_talk_order = order
	_talk_point = point
	_talk_t = seconds


func _talk_end_order() -> void:
	if _talk_order == BotRules.DANCE:
		_rpc_emote.rpc(&"")
	if _talk_order == BotRules.GUIDE and _talk_arrived:
		pointing = false
	_talk_order = &""
	_talk_t = 0.0
	_talk_point = Vector3.INF
	_talk_home = false
	_talk_run = false
	_talk_arrived = false


## Every decision: the requests' clocks.
func _talk_tick() -> void:
	var dt := BotRules.AI_INTERVAL
	_talk_close_t = maxf(_talk_close_t - dt, 0.0)
	_talk_guard_t = maxf(_talk_guard_t - dt, 0.0)
	if _plan_asked and _plan.is_empty():
		_plan_asked = false
	if _talk_order == &"":
		return
	_talk_t -= dt
	if _talk_t > 0.0:
		return
	var waited := _talk_order == BotRules.STAY
	_talk_end_order()
	if waited:
		talk_reply(talk_line(&"coming"))


## Does what the child asked keep it from popping up next to them? (Waiting, unless the child went very far.)
func _talk_holds(lp: Vector3) -> bool:
	if _talk_order != BotRules.STAY or global_position.y < SpawnRules.FALL_LIMIT_Y:
		return false
	if _talk_home or _flat(_talk_point, lp) <= BotRules.STAY_LEASH:
		return true
	_talk_end_order()
	talk_reply(talk_line(&"coming"))
	return false


## Far enough from the child to walk back: its comfortable distance, closer when its child asks it to follow
## (now, or often lately), never closer than CLOSE_FOLLOW; once walking back, until FOLLOW_NEAR.
func _talk_far(lp: Vector3) -> bool:
	var d := _flat(global_position, lp) - style.space
	if behaviour == BotRules.FOLLOW:
		return d > BotRules.FOLLOW_NEAR
	var far := BotRules.follow_far(personality) - asks.closeness(clock)
	if _talk_close_t > 0.0:
		far = BotRules.CLOSE_FOLLOW
	return d > maxf(far, BotRules.CLOSE_FOLLOW)


## The circle it guards: wider when asked to guard; only itself while waiting; else its personality's (-1).
func _talk_guard() -> float:
	if _talk_guard_t > 0.0:
		return BotRules.GUARD_RADIUS
	return 0.0 if _talk_order == BotRules.STAY else -1.0


func _talk_enter(next: StringName) -> void:
	if behaviour == BotRules.DANCE and next != BotRules.DANCE:
		_rpc_emote.rpc(&"")


## One decision of a talk behaviour (true: it was one).
func _talk_step(lp: Vector3) -> bool:
	match behaviour:
		BotRules.STAY:
			if _flat(global_position, _talk_point) > 1.2:
				_go(_talk_point, 0.8, RUN_SPEED if _flat(global_position, _talk_point) > RUN_FROM else WALK_SPEED)
			else:
				_goal = Vector3.INF
				_face = lp if _flat(global_position, lp) < BotRules.CATCH_UP else Vector3.INF
		BotRules.GUIDE:
			_talk_guide_step(lp)
		BotRules.HIDE:
			if _talk_run:
				var near := _monsters_near(lp, BotRules.RUN_FROM_MONSTERS)
				if not near.is_empty():
					_talk_point = _run_spot(lp, near)
			if _flat(global_position, _talk_point) > 1.0:
				_go(_talk_point, 0.6, RUN_SPEED if _talk_run else WALK_SPEED)
			else:
				_goal = Vector3.INF
				_face = lp
		BotRules.DANCE:
			_goal = Vector3.INF
			_face = lp
		_:
			return false
	return true


func _talk_guide_step(lp: Vector3) -> void:
	if _talk_arrived:
		_goal = Vector3.INF
		_face = _talk_point
		return
	if _flat(global_position, _talk_point) <= POINT_REACH and absf(global_position.y - _talk_point.y) <= 6.0:
		_talk_arrived = true
		pointing = true
		_talk_t = POINT_TIME
		_goal = Vector3.INF
		_rpc_sparkle.rpc(_talk_point)
		talk_reply(talk_line(&"found_it"))
		return
	if _flat(global_position, lp) > BotRules.GUIDE_AHEAD:
		_goal = Vector3.INF          # the child fell behind: wait and call
		_face = lp
		_talk_way_t -= BotRules.AI_INTERVAL
		if _talk_way_t <= 0.0:
			_talk_way_t = 15.0
			say_text(talk_line(&"this_way"))
		return
	_go(_talk_point, 1.0, WALK_SPEED)


## Walking somewhere the child asked without getting closer (a wall, a hole): a guide says so and stops;
## waiting and hiding stay where they got to.
func _talk_stuck() -> void:
	if behaviour == BotRules.GUIDE and not _talk_arrived:
		_talk_end_order()
		talk_reply(talk_line(&"stuck"))
	elif behaviour == BotRules.STAY or behaviour == BotRules.HIDE:
		_talk_point = global_position
		_goal = Vector3.INF


## The block a build the child asked for is made of (-1: the design's own): leaves in Survivor (Task 15's
## ruling: never the child's counted blocks); "with my blocks": the child's favourite, else the one in hand.
func _talk_block(leader: Player, mine: bool, survivor: bool) -> int:
	if survivor:
		return BlockIds.LEAVES
	if not mine:
		return -1
	var favourite := style.favourite_blocks(1)
	if not favourite.is_empty():
		return favourite[0]
	return leader.held_item if BotStyle.is_build_block(leader.held_item) else -1


## A build the child asked for, from a spot beside it, MAX_BUILD_BLOCKS at a time (true: it is one).
func _talk_build_step() -> bool:
	if not _plan_asked or _plan.is_empty():
		return false
	var center := Vector3.ZERO
	for cell: Array in _plan:
		center += Vector3(cell[0] as Vector3i) + Vector3(0.5, 0.0, 0.5)
	center /= _plan.size()
	var reach := 0.0
	for cell: Array in _plan:
		reach = maxf(reach, _flat(Vector3(cell[0] as Vector3i) + Vector3(0.5, 0.0, 0.5), center))
	var out := Vector3(global_position.x - center.x, 0.0, global_position.z - center.z)
	if out.length() < 0.1:
		out = Vector3(1, 0, 0)
	var stand := center + out.normalized() * (reach + 1.4)
	stand.y = global_position.y
	if _flat(global_position, stand) > 0.9:
		_go(stand, 0.5, WALK_SPEED)
		return true
	_goal = Vector3.INF
	_face = center
	_build_step_t -= BotRules.AI_INTERVAL
	if _build_step_t > 0.0:
		return true
	_build_step_t = BotRules.BUILD_STEP
	var chunk := _plan.slice(0, BotRules.MAX_BUILD_BLOCKS)
	_plan = _plan.slice(BotRules.MAX_BUILD_BLOCKS)
	var placed := director.place(self, chunk) if director else Session.bot_set_blocks(chunk, eye_position())
	if placed > 0:
		_rpc_swing.rpc()
	if _plan.is_empty():
		_plan_asked = false
		_build_t = asks.build_every(BotRules.BUILD_EVERY, clock)
		_rpc_poof.rpc(center + Vector3(0, 1.0, 0))
		talk_reply(talk_line(StringName("built_%s" % (_plan_what if _plan_what != &"" else &"thing"))))
	return true


## Monsters within `radius` of the child at `lp`.
func _monsters_near(lp: Vector3, radius: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for m in _monsters_now():
		if m.global_position.distance_to(lp) <= radius:
			out.append(m.global_position)
	return out


## A spot RUN_DISTANCE from the child, away from the monsters.
func _run_spot(lp: Vector3, monsters: Array[Vector3]) -> Vector3:
	var middle := Vector3.ZERO
	for m in monsters:
		middle += m
	middle /= monsters.size()
	var away := Vector3(lp.x - middle.x, 0.0, lp.z - middle.z)
	if away.length() < 0.1:
		away = Vector3(-1, 0, 0)
	return lp + away.normalized() * BotRules.RUN_DISTANCE


@rpc("authority", "call_local", "reliable")
func _rpc_emote(emote_name: StringName) -> void:
	if avatar == null:
		return
	if emote_name == &"":
		avatar.stop_emote()
	else:
		avatar.play_emote(emote_name)
