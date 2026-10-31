class_name StoneGolem
extends CharacterBody3D
## The Stone Golem, the Green Meadows boss (M2 Task 10, spec §12.9; rules in BossRules). The host
## simulates it: it climbs out of the ground, then walks towards the nearest player or bot friend and
## attacks in a fixed order, each attack clearly signalled by a wind-up every peer sees:
## - SLAM: both fists up for 1.2 s, then a shockwave ring of 7 blocks: 4 HP to everyone on the ground
##   (nobody in the air). Then it is DAZED for 2 s (stars over its head) and takes double damage.
## - ROCK: a glowing rock held up for 1 s, then thrown in an arc at where its target stands: 3 HP to
##   whoever is still there when it lands.
## - CHARGE: it paws the ground for 1 s, then runs straight 12 blocks: 5 HP to whoever is on its path.
## Players are hurt through Session.hurt_player (shields block from the front), bot friends through
## their hurt(amount, from). Weapons and bot friends hit it like any monster (group "monsters",
## take_hit, hit_center, hit_radius). It never changes a block (the tested rule): it only reads the
## world through block_at. Cost: decisions at 10 Hz, one body with a small footprint, shared meshes;
## the boss music plays while it is in the world (Music.play_boss) on every peer.

signal defeated(golem: StoneGolem)

const LAYER := Monster.LAYER
const GRAVITY := 20.0
const ACCEL := 10.0
const WALK_SPEED := 2.2           # slower than a walking child (6 m/s)
const TURN := 5.0
const AI_INTERVAL := 0.1
const STOP_AT := 3.0              # walks up to this far from its target
const HOME_REACH := 2.0
const BODY := Vector3(1.6, 2.8, 1.6)   # collision box: a small footprint (Buddy.MAX_FOOTPRINT)
const HIT_CENTER := 1.5
const HIT_RADIUS := 1.4
const STEP_HOP := 1.25
const SLAM_PUSH := 5.0
const ROCK_PUSH := 3.0
const CHARGE_PUSH := 8.0
const HAND := Vector3(-1.22, 4.0, -0.5)   # the rock held over its head (local, before its turn)
const SINK_TIME := 1.6            # going back to sleep after a lost fight
const RING_REACH := 0.75          # Fx.ripple's ring ends at this × its size
const DUST := Color("b9a58a")
const RAISED := 2.9               # arms over the head (radians around the shoulder)

var golem_id := ""
var max_hp := BossRules.BASE_HP
var hp := BossRules.BASE_HP       # synced on change
var tired := false
var phase: int = BossRules.Phase.RISE   # synced on change: every peer animates from it
var home := Vector3.ZERO          # where it rose; it walks back when nobody is near
## block_at(pos: Vector3i) -> int: the host's world, read only (set by the BossDirector).
var block_at: Callable

var _phase_t := 0.0
var _step := 0                    # the next attack's number in BossRules.ORDER
var _ai_t := 0.0
var _target: Node3D
var _charge_dir := Vector3.FORWARD
var _charged := {}                # instance ids this charge already hit
var _charge_safe := true          # the ground ahead of the charge (looked at ten times a second)
var _walk_dir := Vector3.ZERO     # planned ten times a second
var _rocks: Array = []            # host: [seconds until it lands, where]
var _defeated := false
var _sleeping := false
var _sink_t := 0.0

var _body := Node3D.new()         # visual root: rises, sinks, leans, bobs
var _arm_l := Node3D.new()
var _arm_r := Node3D.new()
var _held_rock := MeshInstance3D.new()
var _stars := MeshInstance3D.new()
var _look_phase := -1
var _look_t := 0.0
var _shown_hp := 0
var _squash := 0.0
var _last_pos := Vector3.ZERO
var _walk_t := 0.0
var _recoil := 0.0                # every peer (M5 Task 2): seconds left of its lean back after a hit
var _idle_t := 0.0                # every peer (M5 Task 2): its breath's clock


## data = {id, pos, yaw, max_hp, tired}
func setup(data: Dictionary) -> void:
	golem_id = str(data.get("id", "golem"))
	name = golem_id
	position = data.get("pos", Vector3.ZERO)
	rotation.y = float(data.get("yaw", 0.0))
	max_hp = maxi(int(data.get("max_hp", BossRules.BASE_HP)), 1)
	hp = max_hp
	tired = bool(data.get("tired", false))
	home = position
	_shown_hp = hp
	_last_pos = position
	_build()


## Golems in the tree on this peer: the boss music plays while there is one (a lost fight's Golem may
## still be sinking when the next fight begins).
static var _in_tree := 0


func _ready() -> void:
	Music.play_boss(true)
	Audio.play(&"golem_roar", global_position)


func _enter_tree() -> void:
	_in_tree += 1


func _exit_tree() -> void:
	_in_tree = maxi(_in_tree - 1, 0)
	if _in_tree == 0:
		Music.play_boss(false)


func hit_center() -> Vector3:
	return global_position + Vector3(0, HIT_CENTER, 0)


## Which boss this is (BossRules.words; M3 Task 2's Sand Serpent is a StoneGolem to the BossDirector).
func boss_kind() -> StringName:
	return BossRules.GOLEM


func hit_radius() -> float:
	return HIT_RADIUS


func facing() -> Vector3:
	return Vector3(-sin(rotation.y), 0.0, -cos(rotation.y))


func is_dazed() -> bool:
	return phase == BossRules.Phase.DAZED


## Down: defeated, or going back to sleep after a lost fight.
func is_down() -> bool:
	return phase == BossRules.Phase.DOWN


## Where the rock leaves its hand.
func hand_position() -> Vector3:
	return global_position + HAND.rotated(Vector3.UP, rotation.y)


## Host: rocks thrown that have not landed yet.
func rocks_in_flight() -> int:
	return _rocks.size()


func _build() -> void:
	add_to_group(&"monsters")
	collision_layer = LAYER
	collision_mask = 1
	max_slides = 4
	var box := BoxShape3D.new()
	box.size = BODY
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = BODY.y * 0.5
	add_child(shape)
	add_child(_body)
	_add_mesh(_body, GolemModels.body_mesh())
	_add_mesh(_body, GolemModels.eyes_mesh())
	for arm: Node3D in [_arm_l, _arm_r]:
		arm.position = GolemModels.arm_pivot(arm == _arm_r)
		_add_mesh(arm, GolemModels.arm_mesh())
		_body.add_child(arm)
	_arm_l.name = "ArmL"
	_arm_r.name = "ArmR"
	_held_rock.mesh = GolemModels.rock_mesh()
	_held_rock.position = Vector3(0, -1.95, 0)
	_held_rock.visible = false
	_arm_r.add_child(_held_rock)
	_stars.mesh = GolemModels.stars_mesh()
	_stars.position = Vector3(0, GolemModels.HEIGHT + 0.45, 0)
	_stars.visible = false
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_stars)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	for prop in [".:position", ".:rotation", ".:hp", ".:phase"]:
		cfg.add_property(NodePath(prop))
	for prop in [".:hp", ".:phase"]:   # rare changes: sent with the spawn, then on a change
		cfg.property_set_replication_mode(NodePath(prop), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


static func _add_mesh(parent: Node3D, mesh: Mesh) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	parent.add_child(mi)


# --- Hits (host) ---------------------------------------------------------------------------------

## A weapon's hit (CombatDirector or a bot friend): double while dazed; nothing while it rises or is
## down. At 0 HP it announces `defeated` once and is gone.
func take_hit(damage: int, _from: Vector3, _knockback: Vector3) -> void:
	if _defeated or _sleeping or not multiplayer.is_server():
		return
	if phase == BossRules.Phase.RISE or phase == BossRules.Phase.DOWN:
		return
	hp = maxi(hp - BossRules.hit_taken(damage, is_dazed()), 0)
	if hp == 0:
		_defeated = true
		phase = BossRules.Phase.DOWN
		defeated.emit(self)
		queue_free()


## Host: a lost fight: it sinks back into the ground and is gone.
func go_to_sleep() -> void:
	if _defeated or _sleeping:
		return
	_sleeping = true
	phase = BossRules.Phase.DOWN
	collision_layer = 0
	_sink_t = 0.0


# --- Simulation (host) ---------------------------------------------------------------------------

## Host: begins `p` now (the director and tests use it too).
func start_phase(p: int) -> void:
	phase = p
	_phase_t = 0.0
	_walk_dir = Vector3.ZERO           # planned again at the next decision
	if p == BossRules.Phase.CHARGE:
		_charge_dir = facing()
		_charged.clear()
		_charge_safe = block_at.is_valid() and _safe_ahead(_charge_dir, BossRules.CHARGE_SPEED)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or block_at.is_null():
		return
	if _sleeping:
		_sink(delta)
		return
	if _defeated:
		return
	if _dance_hold(delta):   # M3 Task 14a: the Dance Orb: its schedule waits, rocks in flight still land
		return
	_phase_t += delta
	_ai_t -= delta
	if _ai_t <= 0.0:
		_ai_t += AI_INTERVAL
		_decide()
	_land_rocks(delta)
	var from := global_position
	match phase:
		BossRules.Phase.WALK:
			_walk_step(delta)
		BossRules.Phase.CHARGE:
			_charge_step()
		_:
			_stand(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if not (is_on_floor() and velocity.is_zero_approx()):
		move_and_slide()
	if phase == BossRules.Phase.CHARGE:
		_charge_hits(from, global_position)
		var moved := Vector2(global_position.x - from.x, global_position.z - from.z).length()
		if _phase_t > 0.1 and moved < BossRules.CHARGE_SPEED * delta * 0.3:
			start_phase(BossRules.Phase.WALK)   # ran into a wall: it stops (it never breaks blocks)
			return
	if _phase_t >= BossRules.phase_time(phase):
		_advance()


## The end of a phase: the slam lands, the rock flies, and the schedule goes on.
func _advance() -> void:
	var old := phase
	if old == BossRules.Phase.SLAM_WINDUP:
		_slam()
	elif old == BossRules.Phase.ROCK_WINDUP:
		_throw_rock()
	var next := BossRules.next_phase(old, _step)
	if old == BossRules.Phase.WALK:
		_step += 1
	start_phase(next)


## Host, ten times a second: the nearest player or bot friend near its spot.
func _decide() -> void:
	var best: Node3D = null
	var best_d := INF
	for n in _targets_now():
		if Vector2(n.global_position.x - home.x, n.global_position.z - home.z).length() > BossRules.ARENA:
			continue
		var d := n.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = n
	_target = best
	if phase == BossRules.Phase.WALK:
		_plan_walk()
	elif phase == BossRules.Phase.CHARGE:
		_charge_safe = _safe_ahead(_charge_dir, BossRules.CHARGE_SPEED)


func _target_node() -> Node3D:
	return _target if is_instance_valid(_target) and not _target.is_queued_for_deletion() else null


## Host, at a decision: where to walk: towards its target (up to STOP_AT) or back to its spot, never
## into water or off a cliff (the ground ahead is read here, ten times a second, not every step).
func _plan_walk() -> void:
	var t := _target_node()
	var goal := t.global_position if t else home
	var to := Vector3(goal.x - global_position.x, 0.0, goal.z - global_position.z)
	var stop := STOP_AT if t else HOME_REACH
	_walk_dir = to.normalized() if to.length() > stop else Vector3.ZERO
	if _walk_dir != Vector3.ZERO and not _safe_ahead(_walk_dir, WALK_SPEED):
		_walk_dir = Vector3.ZERO


## Walks the planned way, hopping up 1-block steps, and turns towards its target.
func _walk_step(delta: float) -> void:
	velocity.x = move_toward(velocity.x, _walk_dir.x * WALK_SPEED, ACCEL * delta)
	velocity.z = move_toward(velocity.z, _walk_dir.z * WALK_SPEED, ACCEL * delta)
	if is_on_floor() and _walk_dir != Vector3.ZERO and is_on_wall():
		velocity.y = sqrt(2.0 * GRAVITY * STEP_HOP)
	var t := _target_node()
	_turn_to(t.global_position - global_position if t else _walk_dir, delta)


## Rising, winding up or dazed: it stands. In a wind-up it keeps turning towards its target, so the
## attack goes where the child can see it looking.
func _stand(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ACCEL * 2.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, ACCEL * 2.0 * delta)
	var t := _target_node()
	if t and BossRules.is_windup(phase):
		_turn_to(t.global_position - global_position, delta)


func _turn_to(dir: Vector3, delta: float) -> void:
	if Vector2(dir.x, dir.z).length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(TURN * delta, 0.0, 1.0))


func _charge_step() -> void:
	if not _charge_safe:
		start_phase(BossRules.Phase.WALK)
		velocity.x = 0.0
		velocity.z = 0.0
		return
	velocity.x = _charge_dir.x * BossRules.CHARGE_SPEED
	velocity.z = _charge_dir.z * BossRules.CHARGE_SPEED


func _safe_ahead(dir: Vector3, speed: float) -> bool:
	var ahead := global_position + dir * (BODY.x * 0.5 + 0.4 + speed * AI_INTERVAL)
	return MonsterRules.can_step(Vector3i(Vector3(ahead.x, global_position.y + 0.1, ahead.z).floor()), block_at)


# --- Attacks (host) ------------------------------------------------------------------------------

func _slam() -> void:
	var nodes := _targets_now()
	var info := _info(nodes, true)
	for i in BossRules.slam_hits(global_position, info):
		var away := Vector3(nodes[i].global_position.x - global_position.x, 0.0, nodes[i].global_position.z - global_position.z)
		_hurt(nodes[i], BossRules.damage(BossRules.SLAM), away.normalized() * SLAM_PUSH + Vector3.UP * 4.0)
	_rpc_slam.rpc(global_position)


func _throw_rock() -> void:
	var t := _target_node()
	var to := t.global_position if t else global_position + facing() * 8.0
	var from := hand_position()
	_rocks.append([BossRules.rock_time(from, to), to])
	_rpc_rock.rpc(from, to)


func _land_rocks(delta: float) -> void:
	if _rocks.is_empty():
		return
	for r: Array in _rocks.duplicate():
		r[0] -= delta
		if r[0] > 0.0:
			continue
		_rocks.erase(r)
		var nodes := _targets_now()
		for i in BossRules.rock_hits(r[1], _info(nodes)):
			var away := Vector3(nodes[i].global_position.x - r[1].x, 0.0, nodes[i].global_position.z - r[1].z)
			_hurt(nodes[i], BossRules.damage(BossRules.ROCK), away.normalized() * ROCK_PUSH + Vector3.UP * 3.0)


func _charge_hits(from: Vector3, to: Vector3) -> void:
	var nodes := _targets_now()
	for i in BossRules.charge_hits(from, to, _info(nodes)):
		var id := nodes[i].get_instance_id()
		if _charged.has(id):
			continue
		_charged[id] = true
		var side := Vector3(-_charge_dir.z, 0.0, _charge_dir.x)
		var off := nodes[i].global_position - global_position
		if side.dot(off) < 0.0:
			side = -side
		_hurt(nodes[i], BossRules.damage(BossRules.CHARGE), (side + _charge_dir * 0.5).normalized() * CHARGE_PUSH + Vector3.UP * 4.0)


## Players through the host's hearts (shields block from the front), bot friends through hurt().
func _hurt(n: Node3D, amount: int, push: Vector3) -> void:
	if n is Player:
		var p := n as Player
		Session.hurt_player(p.peer_id, amount, global_position)
		Session.send_knockback(p.peer_id, push)
	elif n.has_method(&"hurt"):
		n.call(&"hurt", amount, global_position)


## Everyone it can hit now: players who are up and bot friends who are up.
func _targets_now() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for p in Monster.players_now(get_tree()):
		if not p.knocked_out:
			out.append(p)
	for b in get_tree().get_nodes_in_group(&"bots"):
		if b is Node3D and not b.is_queued_for_deletion():
			out.append(b)
	return out


## BossRules' view of them: where their feet are and (for the slam: one block read each) whether they
## stand on the ground.
func _info(nodes: Array[Node3D], ground: bool = false) -> Array:
	var out: Array = []
	for n in nodes:
		var grounded := false
		if ground:
			var flying := n is Player and (n as Player).physics_mode != PhysicsMode.Mode.NORMAL
			var vy := (n as CharacterBody3D).velocity.y if n is CharacterBody3D else 0.0
			grounded = BossRules.is_grounded(n.global_position, vy, flying, _is_solid)
		out.append({"pos": n.global_position, "grounded": grounded})
	return out


func _is_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(block_at.call(cell))


func _sink(delta: float) -> void:
	_sink_t += delta
	if CreatureMoves.cheering(_sink_t):
		return                        # M5 Task 2: it won: it cheers first (every screen), then sinks
	global_position.y -= GolemModels.HEIGHT / SINK_TIME * delta
	if _sink_t >= CreatureMoves.WIN_TIME + SINK_TIME:
		queue_free()


# --- Everyone: the attacks' effects ---------------------------------------------------------------

## The slam lands: a shockwave ring on the ground, dust, a boom, and a shake felt by this device's
## player by its distance (Feel.slam: full inside the ring, fading out to 20 blocks).
@rpc("authority", "call_local", "reliable")
func _rpc_slam(center: Vector3) -> void:
	var root := get_tree().root
	Fx.ripple(root, center + Vector3(0, 0.05, 0), BossRules.SLAM_RADIUS / RING_REACH)
	Fx.burst(root, center + Vector3(0, 0.25, 0), DUST, 28, 8.0, 0.2, 0.8, 12.0, 80.0)
	Audio.play(&"golem_slam", center)
	var me := _local_player()
	if me:
		Feel.slam(Vector2(me.global_position.x - center.x, me.global_position.z - center.z).length())


## A rock leaves its hand (every peer flies the same arc).
@rpc("authority", "call_local", "reliable")
func _rpc_rock(from: Vector3, to: Vector3) -> void:
	if not (from.is_finite() and to.is_finite()):
		return
	var r := GolemRock.new()
	r.setup(from, to)
	add_child(r)
	Audio.play(&"golem_throw", from)


func _local_player() -> Player:
	for p in Monster.players_now(get_tree()):
		if p.is_local:
			return p
	return null


# --- Looks (every peer) ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if phase != _look_phase:
		_enter_look()
	_look_t += delta
	var moved := global_position - _last_pos
	_last_pos = global_position
	if hp < _shown_hp:
		_took_hit_look()            # a hit: a little squash and a lean back on every screen
	_shown_hp = hp
	var s := Vector3.ONE
	if _squash > 0.0:
		_squash -= delta
		var k := clampf(_squash / 0.15, 0.0, 1.0)
		s = Vector3(1.0 + 0.06 * k, 1.0 - 0.08 * k, 1.0 + 0.06 * k)
	if not _body.scale.is_equal_approx(s):
		_body.scale = s
	_pose(delta, moved)


## A new phase on this screen: its sound, the rock in its hand, the stars.
func _enter_look() -> void:
	_look_phase = phase
	_look_t = 0.0
	_held_rock.visible = phase == BossRules.Phase.ROCK_WINDUP
	_stars.visible = phase == BossRules.Phase.DAZED
	match phase:
		BossRules.Phase.SLAM_WINDUP:
			Audio.play(&"golem_roar", global_position, -4.0)
		BossRules.Phase.CHARGE_WINDUP:
			Audio.play(&"golem_stomp", global_position)
		BossRules.Phase.DOWN:
			_win_roar()


func _pose(delta: float, moved: Vector3) -> void:
	var arms := 0.0                 # both arms (radians forward and up around the shoulders)
	var right := NAN                # the right arm, when it does something else
	var lean := 0.0
	var lift := 0.0
	var wobble := 0.0
	var k := _look_t
	match phase:
		BossRules.Phase.RISE:
			var r := clampf(k / BossRules.RISE_TIME, 0.0, 1.0)
			lift = -GolemModels.HEIGHT * (1.0 - r) * (1.0 - r)
			arms = 0.6 * r
		BossRules.Phase.WALK:
			var walking := delta > 0.0 and Vector2(moved.x, moved.z).length() / delta > 0.3
			_walk_t = _walk_t + delta if walking else 0.0
			var swing := sin(_walk_t * 6.0) * 0.4 if walking else 0.0
			arms = swing
			right = -swing
			lift = absf(sin(_walk_t * 6.0)) * 0.08 if walking else 0.0
			if not walking:               # M5 Task 2: standing, it breathes
				_idle_t += delta
				var b := CreatureMoves.breath(_idle_t)
				lift = b.x * 2.0
				arms = b.y
				right = b.y
				lean = b.z
		BossRules.Phase.SLAM_WINDUP:
			var w := clampf(k / BossRules.windup(BossRules.SLAM), 0.0, 1.0)
			arms = RAISED * (1.0 - (1.0 - w) * (1.0 - w))
			lean = -0.12 * w
		BossRules.Phase.DAZED:
			arms = lerpf(-0.4, 0.0, clampf(k / 0.4, 0.0, 1.0)) if k > 0.08 else lerpf(RAISED, -0.4, k / 0.08)
			wobble = sin(k * 5.0) * 0.07
			_stars.rotation.y = k * 4.0
		BossRules.Phase.ROCK_WINDUP:
			var w := clampf(k / BossRules.windup(BossRules.ROCK), 0.0, 1.0)
			right = RAISED * (1.0 - (1.0 - w) * (1.0 - w))
			arms = 0.2
		BossRules.Phase.CHARGE_WINDUP:
			lean = 0.22
			lift = absf(sin(k * 16.0)) * 0.1   # pawing the ground
			arms = -0.5
		BossRules.Phase.CHARGE:
			lean = 0.35
			lift = absf(sin(k * 14.0)) * 0.12
			arms = -0.9
		BossRules.Phase.DOWN:
			arms = 1.2
			if CreatureMoves.cheering(k):   # M5 Task 2: it won: arms up and pumping, a hop, chest out
				var c := CreatureMoves.cheer(k)
				arms = c.y
				lift = c.x
				lean = c.z
	lean += _recoil_lean(delta)
	# A transform write costs even when nothing changes (the monsters' lesson): write only changes.
	if _arm_l.rotation.x != arms:
		_arm_l.rotation.x = arms
	var r := arms if is_nan(right) else right
	if _arm_r.rotation.x != r:
		_arm_r.rotation.x = r
	if _body.position.y != lift:
		_body.position.y = lift
	var tilt := Vector3(lean, 0.0, wobble)
	if _body.rotation != tilt:
		_body.rotation = tilt

# --- M5 Task 2: shared boss moves (spec §15.2; CreatureMoves) ------------------------------------------------------

## The roar it cheers with when it wins a fight (each boss its own).
func win_sound() -> StringName:
	return &"golem_roar"


## Every screen: a hit landed: a little squash and a lean back.
func _took_hit_look() -> void:
	_squash = 0.15
	_recoil = CreatureMoves.RECOIL_TIME


## Every screen: how far it leans back now after a hit (radians, 0 when done).
func _recoil_lean(delta: float) -> float:
	if _recoil <= 0.0:
		return 0.0
	_recoil = maxf(_recoil - delta, 0.0)
	return CreatureMoves.recoil(_recoil / CreatureMoves.RECOIL_TIME, CreatureMoves.BOSS_RECOIL)


## Every screen, as it goes down: its roar when it won the fight (a defeated boss is gone at once, never heard here).
## A defeat is known on every screen by its synced hearts (0): `_defeated` is the host's own (M5 Task 6 review).
func _win_roar() -> void:
	if hp > 0 and not _defeated and not is_queued_for_deletion():
		Audio.play(win_sound(), global_position, -2.0)

# --- M3 Task 14a: the Dance Orb (a boss dances 2 s, at most once in 20 s: GadgetDirector) ----------------------

## Host: seconds it still dances: its attack schedule waits (no phase runs on), rocks already thrown land.
var dance_left := 0.0
var _dance_t := 0.0
var _dance_yaw := 0.0


func dance(seconds: float) -> void:
	if not multiplayer.is_server() or _defeated or _sleeping or seconds <= 0.0:
		return
	if dance_left <= 0.0:
		_dance_t = 0.0
		_dance_yaw = rotation.y
	dance_left = maxf(dance_left, seconds)


func is_dancing() -> bool:
	return dance_left > 0.0


## The sub-bosses' _physics_process calls it too (SandSerpent, FrostGiant): true while dancing.
func _dance_hold(delta: float) -> bool:
	if dance_left <= 0.0:
		return false
	dance_left -= delta
	_dance_t += delta
	rotation.y = _dance_yaw + sin(_dance_t * TAU / 0.8) * 0.5 if dance_left > 0.0 else _dance_yaw
	_land_rocks(delta)
	return true
