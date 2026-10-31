class_name SandSerpent
extends StoneGolem
## The Sand Serpent, the Sandstorm Desert's boss (M3 Task 2, spec §14.1; rules in SerpentRules). To the
## BossDirector it is a StoneGolem (the same fight, health bar, honest help, gold, portal, win and loss);
## its own schedule, attacks and looks are here. The host simulates it: it rises out of the sand, then in a
## fixed order it swims under the sand towards the nearest child (a mound of sand moves over it; nobody can
## hit it), shakes the sand in a ring where the child stood (WARN: step away!), bursts out there, and while
## it is up it can be hit; then it rattles its tail and sweeps the ground round it (jump!) and is dizzy
## after (double damage), or it throws its head back and spits a ball of sand (step aside). Players are
## hurt through Session.hurt_player, bot friends through hurt(). It never moves a block: under the sand it
## is only a picture (no body in the way, no physics move), and it only reads the world through block_at.

const P := SerpentRules.Phase
const NECK := Vector3(1.4, 4.2, 1.4)   # the neck out of the sand (a small footprint)
const HIT_HEIGHT := 2.6
const HEAD_Y := SerpentModels.SEGMENTS * SerpentModels.SEGMENT + 0.3
const PUFF_EVERY := 0.25          # sand puffs over it while it swims (the shared Fx material)
const RING_EVERY := 0.45          # the shaking ring while it warns
const BURST_PUSH := 6.0
const SWEEP_PUSH := 7.0
const SAND_DUST := SerpentModels.SAND
const SAND_DARK_DUST := SerpentModels.SAND_DARK

var _turn := 0                    # host: times it has been up (the tail, then the ball, then the tail...)
var _ground_y := NAN              # host: the sand's height under it (looked at ten times a second)
var _segments: Array[MeshInstance3D] = []
var _head := Node3D.new()
var _head_mesh := MeshInstance3D.new()
var _tail := MeshInstance3D.new()
var _mound := MeshInstance3D.new()
var _fx_t := 0.0
var _underground_shown := -1


func boss_kind() -> StringName:
	return BossRules.SERPENT


func win_sound() -> StringName:
	return &"serpent_roar"


func _build() -> void:
	add_to_group(&"monsters")
	collision_layer = 0               # rising: not a target yet
	collision_mask = 1
	for unused: Node in [_arm_l, _arm_r, _held_rock]:   # the Golem's parts: not a serpent's
		unused.free()
	var box := BoxShape3D.new()
	box.size = NECK
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = NECK.y * 0.5
	add_child(shape)
	add_child(_body)
	for i in SerpentModels.SEGMENTS:
		var seg := MeshInstance3D.new()
		seg.mesh = SerpentModels.segment_mesh()
		seg.position.y = SerpentModels.SEGMENT * (i + 0.5)
		_body.add_child(seg)
		_segments.append(seg)
	_head.name = "Head"
	_head.position.y = HEAD_Y
	_head_mesh.mesh = SerpentModels.head_mesh()
	_head.add_child(_head_mesh)
	var eyes := MeshInstance3D.new()
	eyes.mesh = SerpentModels.eyes_mesh()
	_head.add_child(eyes)
	_body.add_child(_head)
	_tail.mesh = SerpentModels.tail_mesh()
	_body.add_child(_tail)
	_stars.mesh = GolemModels.stars_mesh()
	_stars.position = Vector3(0, HEAD_Y + 0.9, 0)
	_stars.visible = false
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_stars)
	_mound.mesh = SerpentModels.mound_mesh()
	_mound.visible = false
	add_child(_mound)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	for prop in [".:position", ".:rotation", ".:hp", ".:phase"]:
		cfg.add_property(NodePath(prop))
	for prop in [".:hp", ".:phase"]:
		cfg.property_set_replication_mode(NodePath(prop), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


func _ready() -> void:
	Music.play_boss(true)
	Audio.play(&"serpent_roar", global_position)


func hit_center() -> Vector3:
	return global_position + Vector3(0, HIT_HEIGHT, 0)


func hit_radius() -> float:
	return 1.4


func is_dazed() -> bool:
	return phase == P.DIZZY


func is_down() -> bool:
	return phase == P.DOWN


## Where it will burst (every peer: it waits right under the shaking ring).
func burst_spot() -> Vector3:
	return global_position


# --- Hits (host) -------------------------------------------------------------------------------------

## Only while it is out of the sand; double while dizzy. At 0 HP it announces `defeated` once and is gone.
func take_hit(damage: int, _from: Vector3, _knockback: Vector3) -> void:
	if _defeated or _sleeping or not multiplayer.is_server() or not SerpentRules.hittable(phase):
		return
	hp = maxi(hp - SerpentRules.hit_taken(damage, is_dazed()), 0)
	if hp == 0:
		_defeated = true
		phase = P.DOWN
		defeated.emit(self)
		queue_free()


## Host: a lost fight: it sinks into the sand and is gone.
func go_to_sleep() -> void:
	if _defeated or _sleeping:
		return
	_sleeping = true
	phase = P.DOWN
	collision_layer = 0
	_sink_t = 0.0


# --- Simulation (host) ---------------------------------------------------------------------------------

func start_phase(p: int) -> void:
	phase = p
	_phase_t = 0.0
	collision_layer = LAYER if SerpentRules.hittable(p) else 0
	if p == P.WARN:
		_mark_spot()


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or block_at.is_null():
		return
	if _sleeping:
		_sink(delta)
		return
	if _defeated:
		return
	if _dance_hold(delta):   # M3 Task 14a: the Dance Orb (StoneGolem)
		return
	_phase_t += delta
	_ai_t -= delta
	if _ai_t <= 0.0:
		_ai_t += AI_INTERVAL
		_decide_serpent()
	_land_rocks(delta)
	if phase == P.DIVE:
		_swim(delta)
	elif SerpentRules.hittable(phase):
		var t := _target_node()
		if t:
			_turn_to(t.global_position - global_position, delta)
	if _phase_t >= SerpentRules.phase_time(phase):
		_next()


func _next() -> void:
	var old := phase
	if old == P.SWEEP_WARN:
		_sweep()
	elif old == P.SPIT_WARN:
		_spit_ball()
	var next := SerpentRules.next_phase(old, _turn)
	if old == P.UP:
		_turn += 1
	start_phase(next)
	if next == P.BURST:
		_burst()


## Ten times a second: the nearest child or bot friend near its lair, and the sand's height under it.
func _decide_serpent() -> void:
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
	if phase == P.DIVE:
		_ground_y = BossRules.stand_y(global_position.x, global_position.z, global_position.y, block_at)


## Under the sand, towards its target (never far from its lair), along the sand's surface.
func _swim(delta: float) -> void:
	var t := _target_node()
	if t == null:
		return
	var goal := SerpentRules.keep_in_arena(t.global_position, home)
	var next := SerpentRules.dive_step(global_position, goal, delta)
	if is_finite(_ground_y):
		next.y = move_toward(global_position.y, _ground_y, 8.0 * delta)
	global_position = next
	_turn_to(goal - global_position, delta)


## The sand starts to shake where the child stands now: it waits right under that spot.
func _mark_spot() -> void:
	var t := _target_node()
	if t == null:
		return
	var spot := SerpentRules.keep_in_arena(t.global_position, home)
	spot.y = BossRules.stand_y(spot.x, spot.z, t.global_position.y, block_at)
	global_position = spot


func _burst() -> void:
	var nodes := _targets_now()
	for i in SerpentRules.burst_hits(global_position, _info(nodes)):
		var away := Vector3(nodes[i].global_position.x - global_position.x, 0.0, nodes[i].global_position.z - global_position.z)
		_hurt(nodes[i], SerpentRules.damage(SerpentRules.BURST), away.normalized() * BURST_PUSH + Vector3.UP * 5.0)
	_rpc_burst.rpc(global_position)


func _sweep() -> void:
	var nodes := _targets_now()
	for i in SerpentRules.sweep_hits(global_position, _info(nodes, true)):
		var away := Vector3(nodes[i].global_position.x - global_position.x, 0.0, nodes[i].global_position.z - global_position.z)
		_hurt(nodes[i], SerpentRules.damage(SerpentRules.SWEEP), away.normalized() * SWEEP_PUSH + Vector3.UP * 3.0)
	_rpc_sweep.rpc(global_position)


func _spit_ball() -> void:
	var t := _target_node()
	var to := t.global_position if t else global_position + facing() * 8.0
	var from := global_position + Vector3(0, HEAD_Y, 0) + facing() * 0.6
	_rocks.append([BossRules.rock_time(from, to), to])
	_rpc_ball.rpc(from, to)


# --- Everyone: the attacks' effects ------------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func _rpc_burst(at: Vector3) -> void:
	var root := get_tree().root
	Fx.burst(root, at + Vector3(0, 0.4, 0), SAND_DUST, 30, 9.0, 0.22, 0.9, 12.0, 70.0)
	Fx.burst(root, at + Vector3(0, 0.4, 0), SAND_DARK_DUST, 16, 6.0, 0.28, 0.9, 12.0, 70.0)
	Audio.play(&"serpent_burst", at)
	var me := _local_player()
	if me:
		Feel.slam(Vector2(me.global_position.x - at.x, me.global_position.z - at.z).length())


@rpc("authority", "call_local", "reliable")
func _rpc_sweep(center: Vector3) -> void:
	var root := get_tree().root
	Fx.ripple(root, center + Vector3(0, 0.05, 0), SerpentRules.SWEEP_RADIUS / RING_REACH)
	Fx.burst(root, center + Vector3(0, 0.25, 0), SAND_DUST, 26, 8.0, 0.2, 0.8, 12.0, 80.0)
	Audio.play(&"golem_slam", center, -3.0)


@rpc("authority", "call_local", "reliable")
func _rpc_ball(from: Vector3, to: Vector3) -> void:
	if not (from.is_finite() and to.is_finite()):
		return
	var r := GolemRock.new()
	r.look = SerpentModels.ball_mesh()
	r.dust = [SAND_DUST, SAND_DARK_DUST]
	r.setup(from, to)
	add_child(r)
	Audio.play(&"spit", from)


# --- Looks (every peer) -----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if phase != _look_phase:
		_enter_phase_look()
	_look_t += delta
	var under := phase == P.DIVE or phase == P.WARN
	if int(under) != _underground_shown:
		_underground_shown = int(under)
		_body.visible = not under
		_mound.visible = under
	if hp < _shown_hp:
		_took_hit_look()   # M5 Task 2: a squash and a lean back
	_shown_hp = hp
	if under:
		_sand_signals(delta)
		return
	_pose_serpent(delta)


## A new phase on this screen: its sound, its lit mouth, the stars.
func _enter_phase_look() -> void:
	_look_phase = phase
	_look_t = 0.0
	_fx_t = 0.0
	_stars.visible = phase == P.DIZZY
	_head_mesh.mesh = SerpentModels.head_mesh(phase == P.SPIT_WARN)
	match phase:
		P.WARN:
			Audio.play(&"serpent_rumble", global_position)
		P.SWEEP_WARN:
			Audio.play(&"hiss", global_position)
		P.DIVE:
			Audio.play(&"serpent_rumble", global_position, -8.0)
		P.DOWN:
			_win_roar()   # M5 Task 2


## Under the sand: puffs of sand over it; while it warns, a ring of shaking sand too (the signal).
func _sand_signals(delta: float) -> void:
	_fx_t -= delta
	if _fx_t > 0.0:
		return
	var warn := phase == P.WARN
	_fx_t = RING_EVERY if warn else PUFF_EVERY
	var root := get_tree().root
	var at := global_position + Vector3(0, 0.2, 0)
	if warn:
		Fx.ripple(root, at, SerpentRules.BURST_RADIUS / RING_REACH)
		Fx.burst(root, at, SAND_DUST, 10, 3.0, 0.16, 0.5, 12.0, 60.0)
	else:
		Fx.burst(root, at, SAND_DUST, 5, 2.0, 0.14, 0.4, 12.0, 50.0)


## Out of the sand: the neck sways; it rises, rears back for the sweep (the tail rattles), throws its head
## back for the ball, wobbles while dizzy, and sinks when it dives or goes back to sleep.
func _pose_serpent(delta: float) -> void:
	var k := _look_t
	var lift := 0.0
	var lean := 0.0
	var wobble := 0.0
	var rattle := 0.0
	match phase:
		P.RISE:
			var r := clampf(k / SerpentRules.RISE_TIME, 0.0, 1.0)
			lift = -HEAD_Y * (1.0 - r) * (1.0 - r)
		P.BURST:
			lift = -HEAD_Y * (1.0 - clampf(k / SerpentRules.BURST_TIME, 0.0, 1.0))
		P.SWEEP_WARN:
			lean = 0.25 * clampf(k / 0.3, 0.0, 1.0)
			rattle = sin(k * 40.0) * 0.35
		P.SPIT_WARN:
			lean = 0.35 * clampf(k / SerpentRules.SPIT_WINDUP, 0.0, 1.0)
		P.DIZZY:
			wobble = sin(k * 5.0) * 0.12
			_stars.rotation.y = k * 4.0
		P.DOWN:
			lift = -HEAD_Y * clampf((k - CreatureMoves.WIN_TIME) / SINK_TIME, 0.0, 1.0)
			if CreatureMoves.cheering(k):   # M5 Task 2: it won: it rears up, bobs and rattles its tail
				var c := CreatureMoves.cheer(k)
				lift = c.x * 2.0
				lean = -c.z * 2.0
				rattle = sin(k * 40.0) * 0.35 * c.y / CreatureMoves.CHEER_ARMS
	for i in _segments.size():
		var t := float(i) / _segments.size()
		var sway := sin(k * 2.2 + i * 0.7) * 0.12 * t
		var p := Vector3(sway, SerpentModels.SEGMENT * (i + 0.5), lean * t * t * 2.0)
		if not _segments[i].position.is_equal_approx(p):
			_segments[i].position = p
	var head := Vector3(sin(k * 2.2 + _segments.size() * 0.7) * 0.12, HEAD_Y, lean * 2.0)
	if not _head.position.is_equal_approx(head):
		_head.position = head
	var tilt := Vector3(-lean * 1.2 + _recoil_lean(delta), 0.0, wobble)
	if _head.rotation != tilt:
		_head.rotation = tilt
	if _tail.rotation.y != rattle:
		_tail.rotation.y = rattle
	var s := Vector3.ONE
	if _squash > 0.0:
		_squash -= delta
		var q := clampf(_squash / 0.15, 0.0, 1.0)
		s = Vector3(1.0 + 0.08 * q, 1.0 - 0.1 * q, 1.0 + 0.08 * q)
	if not _body.scale.is_equal_approx(s):
		_body.scale = s
	if _body.position.y != lift:
		_body.position.y = lift
