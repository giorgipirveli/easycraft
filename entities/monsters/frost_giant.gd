class_name FrostGiant
extends StoneGolem
## The Frost Giant, Frostpeak's boss (M3 Task 3, spec §14.1; rules in FrostGiantRules). To the BossDirector
## it is a StoneGolem (the same fight, health bar, honest help, gold, portal, win and loss); its own
## schedule, attacks and looks are here. The host simulates it: it climbs out of the snow, walks towards the
## nearest child and, a walk between each, in a fixed order: lifts a leg while frost gathers, then stomps a
## freezing ring along the ground (a jump clears it) that leaves the ground icy for a few seconds (IcyGround
## on every game: slippery, never a block); breathes in with its mouth glowing, then breathes a cone of cold
## the way it faced (a snow wall between shields a child: FrostGiantRules.in_breath), then pants (double
## damage); holds up a giant snowball and throws it (the Golem's rock arc). Players are hurt through
## Session.hurt_player, bot friends through hurt(). It only reads the world through block_at.

const P := FrostGiantRules.Phase
const GIANT_BODY := Vector3(1.6, 3.8, 1.6)   # collision box: a small footprint (Buddy.MAX_FOOTPRINT)
const GIANT_HIT_CENTER := 2.2
const GIANT_HAND := Vector3(-1.3, 5.2, -0.4)  # the snowball held over its head (local, before its turn)
const STOMP_PUSH := 5.0
const RAISED_LEG := -1.35         # the right leg lifted forward (radians round the hip)
const FROST_EVERY := 0.3          # frost gathers round its feet while it lifts its leg
const BREATH_FX_EVERY := 0.2      # snowflakes blow from its mouth while it breathes
const CHEST := 1.0                # a child is chilled at this height over their feet
const FROST_DUST := GiantModels.FROST

var _leg := Node3D.new()
var _eyes := MeshInstance3D.new()
var _breath_dir := Vector3.FORWARD
var _breath_ticks := 0
var _fx_t := 0.0


func boss_kind() -> StringName:
	return BossRules.FROST_GIANT


func win_sound() -> StringName:
	return &"giant_roar"


func _build() -> void:
	add_to_group(&"monsters")
	collision_layer = 0               # climbing out: not a target yet
	collision_mask = 1
	max_slides = 4
	var box := BoxShape3D.new()
	box.size = GIANT_BODY
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = GIANT_BODY.y * 0.5
	add_child(shape)
	add_child(_body)
	_add_mesh(_body, GiantModels.body_mesh())
	_eyes.mesh = GiantModels.eyes_mesh()
	_body.add_child(_eyes)
	for arm: Node3D in [_arm_l, _arm_r]:
		arm.position = GiantModels.arm_pivot(arm == _arm_r)
		_add_mesh(arm, GiantModels.arm_mesh())
		_body.add_child(arm)
	_arm_l.name = "ArmL"
	_arm_r.name = "ArmR"
	_leg.name = "Leg"
	_leg.position = GiantModels.HIP
	_add_mesh(_leg, GiantModels.leg_mesh())
	_body.add_child(_leg)
	_held_rock.mesh = GiantModels.snowball_mesh()
	_held_rock.position = Vector3(0, -1.9, 0)
	_held_rock.visible = false
	_arm_r.add_child(_held_rock)
	_stars.mesh = GolemModels.stars_mesh()
	_stars.position = Vector3(0, GiantModels.HEIGHT + 0.5, 0)
	_stars.visible = false
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_stars)
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
	Audio.play(&"giant_roar", global_position)


func hit_center() -> Vector3:
	return global_position + Vector3(0, GIANT_HIT_CENTER, 0)


func hit_radius() -> float:
	return 1.5


func is_dazed() -> bool:
	return phase == P.PANTING


func is_down() -> bool:
	return phase == P.DOWN


func hand_position() -> Vector3:
	return global_position + GIANT_HAND.rotated(Vector3.UP, rotation.y)


## Where its breath leaves: its mouth.
func mouth() -> Vector3:
	return global_position + GiantModels.MOUTH_AT.rotated(Vector3.UP, rotation.y)


# --- Hits (host) -------------------------------------------------------------------------------------

## Once it stands (not while it climbs out or is down); double while it pants. At 0 HP it announces
## `defeated` once and is gone.
func take_hit(damage: int, _from: Vector3, _knockback: Vector3) -> void:
	if _defeated or _sleeping or not multiplayer.is_server() or not FrostGiantRules.hittable(phase):
		return
	hp = maxi(hp - FrostGiantRules.hit_taken(damage, is_dazed()), 0)
	if hp == 0:
		_defeated = true
		phase = P.DOWN
		defeated.emit(self)
		queue_free()


## Host: a lost fight: it sinks back into the snow and is gone.
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
	_walk_dir = Vector3.ZERO
	collision_layer = LAYER if FrostGiantRules.hittable(p) else 0
	if p == P.BREATH:
		_breath_dir = facing()
		_breath_ticks = 0


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
		_decide_giant()
	_land_rocks(delta)
	if phase == P.WALK:
		_walk_step(delta)
	else:
		_stand_giant(delta)
	if phase == P.BREATH:
		_breathe()
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if not (is_on_floor() and velocity.is_zero_approx()):
		move_and_slide()
	if _phase_t >= FrostGiantRules.phase_time(phase):
		_next()


func _next() -> void:
	var old := phase
	if old == P.STOMP_WARN:
		_stomp()
	elif old == P.THROW_WARN:
		_throw_snowball()
	var next := FrostGiantRules.next_phase(old, _step)
	if old == P.WALK:
		_step += 1
	start_phase(next)


## Ten times a second: the nearest child or bot friend near its spot, and where to walk.
func _decide_giant() -> void:
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
	if phase == P.WALK:
		_plan_walk()


## Climbing out, winding up, breathing or panting: it stands. In a wind-up it keeps turning towards its
## target (the attack goes where the child sees it looking); while it breathes it holds its aim.
func _stand_giant(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ACCEL * 2.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, ACCEL * 2.0 * delta)
	var t := _target_node()
	if t and FrostGiantRules.is_warning(phase):
		_turn_to(t.global_position - global_position, delta)


func _stomp() -> void:
	var nodes := _targets_now()
	for i in FrostGiantRules.stomp_hits(global_position, _info(nodes, true)):
		var away := Vector3(nodes[i].global_position.x - global_position.x, 0.0, nodes[i].global_position.z - global_position.z)
		_hurt(nodes[i], FrostGiantRules.damage(FrostGiantRules.STOMP), away.normalized() * STOMP_PUSH + Vector3.UP * 4.0)
	_rpc_stomp.rpc(global_position)


## The breath's chills: BREATH_TICKS in one breath, BREATH_TICK apart, to whoever is in the cone now.
func _breathe() -> void:
	while _breath_ticks < FrostGiantRules.BREATH_TICKS and _phase_t + 0.0001 >= (_breath_ticks + 1) * FrostGiantRules.BREATH_TICK:
		_breath_ticks += 1
		var from := mouth()
		for n in _targets_now():
			if FrostGiantRules.in_breath(from, _breath_dir, n.global_position + Vector3(0, CHEST, 0), _is_solid):
				_hurt(n, FrostGiantRules.damage(FrostGiantRules.BREATH), _breath_dir * 1.5)


func _throw_snowball() -> void:
	var t := _target_node()
	var to := t.global_position if t else global_position + facing() * 8.0
	var from := hand_position()
	_rocks.append([BossRules.rock_time(from, to), to])
	_rpc_snowball.rpc(from, to)


# --- Everyone: the attacks' effects -------------------------------------------------------------------

## The stomp lands: a freezing ring on the ground, snow flying, a thud and cracking ice, a shake felt by
## this device's player; the ground round it is icy for a few seconds (IcyGround) and shows it (a flat
## ring of frost that melts away). Every game keeps the icy ground, so every game slides its own player.
@rpc("authority", "call_local", "reliable")
func _rpc_stomp(center: Vector3) -> void:
	if not center.is_finite():
		return
	IcyGround.add(center, FrostGiantRules.ICY_RADIUS, FrostGiantRules.ICY_TIME, Time.get_ticks_msec() / 1000.0)
	var root := get_tree().root
	Fx.ripple(root, center + Vector3(0, 0.05, 0), FrostGiantRules.STOMP_RADIUS / RING_REACH)
	Fx.burst(root, center + Vector3(0, 0.25, 0), GiantModels.SNOW, 30, 8.0, 0.2, 0.8, 12.0, 80.0)
	Fx.burst(root, center + Vector3(0, 0.25, 0), GiantModels.ICE, 18, 6.0, 0.14, 0.9, 12.0, 80.0)
	Audio.play(&"giant_stomp", center)
	Audio.play(&"ice_crackle", center, -4.0)
	var ring := IceRing.new()
	ring.position = center + Vector3(0, 0.03, 0)
	root.add_child(ring)
	var me := _local_player()
	if me:
		Feel.slam(Vector2(me.global_position.x - center.x, me.global_position.z - center.z).length())


## A giant snowball leaves its hands (every game flies the same arc).
@rpc("authority", "call_local", "reliable")
func _rpc_snowball(from: Vector3, to: Vector3) -> void:
	if not (from.is_finite() and to.is_finite()):
		return
	var r := GolemRock.new()
	r.look = GiantModels.snowball_mesh()
	r.dust = [GiantModels.SNOW, GiantModels.ICE]
	r.sound = &"snow_splat"
	r.setup(from, to)
	add_child(r)
	Audio.play(&"snow_throw", from)


# --- Looks (every peer) --------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if phase != _look_phase:
		_enter_giant_look()
	_look_t += delta
	var moved := global_position - _last_pos
	_last_pos = global_position
	if hp < _shown_hp:
		_took_hit_look()   # M5 Task 2: a squash and a lean back
	_shown_hp = hp
	var s := Vector3.ONE
	if _squash > 0.0:
		_squash -= delta
		var k := clampf(_squash / 0.15, 0.0, 1.0)
		s = Vector3(1.0 + 0.06 * k, 1.0 - 0.08 * k, 1.0 + 0.06 * k)
	if not _body.scale.is_equal_approx(s):
		_body.scale = s
	_signals(delta)
	_pose_giant(delta, moved)


## A new phase on this screen: its sound, the snowball in its hand, a glowing mouth, the stars.
func _enter_giant_look() -> void:
	_look_phase = phase
	_look_t = 0.0
	_fx_t = 0.0
	_held_rock.visible = phase == P.THROW_WARN
	_stars.visible = phase == P.PANTING
	_eyes.mesh = GiantModels.eyes_mesh(phase == P.BREATH_WARN or phase == P.BREATH)
	match phase:
		P.STOMP_WARN:
			Audio.play(&"ice_crackle", global_position)
		P.BREATH_WARN:
			Audio.play(&"giant_roar", global_position, -8.0)
		P.BREATH:
			Audio.play(&"giant_breath", mouth())
		P.DOWN:
			_win_roar()   # M5 Task 2


## The signals children learn: frost gathering round its feet as it lifts its leg, snowflakes blowing from
## its mouth while it breathes (the shared Fx material; a few bursts a second).
func _signals(delta: float) -> void:
	if phase != P.STOMP_WARN and phase != P.BREATH:
		return
	_fx_t -= delta
	if _fx_t > 0.0:
		return
	var root := get_tree().root
	if phase == P.STOMP_WARN:
		_fx_t = FROST_EVERY
		Fx.burst(root, global_position + Vector3(0, 0.2, 0), FROST_DUST, 10, 2.5, 0.12, 0.5, 2.0, 70.0)
	else:
		_fx_t = BREATH_FX_EVERY
		var p := Fx.burst(root, mouth(), GiantModels.SNOW, 14, FrostGiantRules.BREATH_LENGTH * 1.2, 0.12, 0.8, 0.5,
			FrostGiantRules.BREATH_ANGLE * 0.8)
		p.direction = facing() + Vector3(0, -0.15, 0)


func _pose_giant(delta: float, moved: Vector3) -> void:
	var arms := 0.0
	var right := NAN
	var leg := 0.0
	var lean := 0.0
	var lift := 0.0
	var wobble := 0.0
	var k := _look_t
	match phase:
		P.RISE:
			var r := clampf(k / FrostGiantRules.RISE_TIME, 0.0, 1.0)
			lift = -GiantModels.HEIGHT * (1.0 - r) * (1.0 - r)
			arms = 0.6 * r
		P.WALK:
			var walking := delta > 0.0 and Vector2(moved.x, moved.z).length() / delta > 0.3
			_walk_t = _walk_t + delta if walking else 0.0
			var swing := sin(_walk_t * 5.0) * 0.4 if walking else 0.0
			arms = swing
			right = -swing
			leg = -swing * 0.8
			lift = absf(sin(_walk_t * 5.0)) * 0.08 if walking else 0.0
			if not walking:               # M5 Task 2: standing, it breathes (frosty puffs are the breath attack's)
				_idle_t += delta
				var b := CreatureMoves.breath(_idle_t)
				lift = b.x * 2.0
				arms = b.y
				right = b.y
				lean = b.z
		P.STOMP_WARN:
			var w := clampf(k / FrostGiantRules.STOMP_WINDUP, 0.0, 1.0)
			leg = RAISED_LEG * (1.0 - (1.0 - w) * (1.0 - w))
			arms = 0.8 * w
			lean = -0.08 * w
		P.BREATH_WARN:
			var w := clampf(k / FrostGiantRules.BREATH_WINDUP, 0.0, 1.0)
			lean = -0.25 * w                 # head back, breathing in
			arms = -0.3 * w
		P.BREATH:
			lean = 0.15
			arms = -0.5
		P.PANTING:
			wobble = sin(k * 4.0) * 0.06
			lean = 0.12 + sin(k * 9.0) * 0.03
			arms = -0.2
			_stars.rotation.y = k * 4.0
		P.THROW_WARN:
			var w := clampf(k / FrostGiantRules.THROW_WINDUP, 0.0, 1.0)
			right = RAISED * (1.0 - (1.0 - w) * (1.0 - w))
			arms = 0.2
		P.DOWN:
			arms = 1.2
			if CreatureMoves.cheering(k):   # M5 Task 2: it won: arms up and pumping, a stomp-hop, chest out
				var c := CreatureMoves.cheer(k)
				arms = c.y
				lift = c.x
				lean = c.z
				leg = c.x * 1.5
	lean += _recoil_lean(delta)
	if _arm_l.rotation.x != arms:
		_arm_l.rotation.x = arms
	var r2 := arms if is_nan(right) else right
	if _arm_r.rotation.x != r2:
		_arm_r.rotation.x = r2
	if _leg.rotation.x != leg:
		_leg.rotation.x = leg
	if _body.position.y != lift:
		_body.position.y = lift
	var tilt := Vector3(lean, 0.0, wobble)
	if _body.rotation != tilt:
		_body.rotation = tilt
