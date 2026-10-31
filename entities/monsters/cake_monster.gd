class_name CakeMonster
extends StoneGolem
## The Cake Monster, the Candy Kingdom's boss (M3 Task 4, spec §14.1; rules in CakeRules). To the BossDirector
## it is a StoneGolem (the same fight, health bar, honest help, gold, portal, win and loss); its own schedule,
## attacks and looks are here. The host simulates it: it rises out of the frosting, walks towards the nearest
## child and attacks by the tiers it has left, each attack signalled by a wind-up every screen sees:
## - three tiers: its arms go up and it squishes down (WAVE_WARN), then a FROSTING WAVE rolls along the ground
##   round it (a jump clears it);
## - two tiers: a cherry on top glows (CHERRY_WARN), then three CHERRIES fly, at the child and to each side;
## - one tier: it leans back and whirrs (SPIN_WARN), then SPINS straight at the child like a top.
## After each attack it is DIZZY (stars; double damage). At two thirds and a third of its health a tier falls
## off (LAYER_DROP: no hits, no attacks; a line says what comes next; every screen sees the tier tumble off and
## burst into crumbs, from the synced health). Players are hurt through Session.hurt_player, bot friends
## through hurt(). It never changes a block: it only reads the world through block_at.

const P := CakeRules.Phase
const FOOT := 1.7                 # the collision box's width (a small footprint)
const WAVE_PUSH := 5.0
const CHERRY_PUSH := 3.0
const SPIN_PUSH := 8.0
const WALK_FAST := 3.0            # one tier left: lighter, it hurries (still slower than a child)
const FALL_TIME := 0.9            # every screen: a fallen tier tumbles off this long, then bursts
const CRUMBS := [CakeModels.SPONGE, CakeModels.PINK, CakeModels.CREAM]

var _layers := CakeRules.LAYERS   # host: the tiers standing (follows hp)
var _shape: CollisionShape3D
var _box := BoxShape3D.new()
var _tier_nodes: Array[Node3D] = []
var _cherry := MeshInstance3D.new()
var _arms: Array[Node3D] = []
var _shown_layers := CakeRules.LAYERS
var _falling := {}                # every screen: tier index -> seconds it has been falling
var _spin_dir := Vector3.FORWARD
var _spun := {}
var _spin_safe := true


func boss_kind() -> StringName:
	return BossRules.CAKE


func win_sound() -> StringName:
	return &"cake_roar"


## Tiers standing now (from the synced health: the same on every screen).
func layers() -> int:
	return maxi(CakeRules.layers_left(hp, max_hp), 1) if hp > 0 else 0


## Its height with the tiers it has left.
func height() -> float:
	return CakeModels.HEIGHTS[clampi(layers(), 1, CakeRules.LAYERS)]


## Tiers this screen still shows (a fallen one is gone once it has tumbled off).
func tiers_shown() -> int:
	var n := 0
	for t in _tier_nodes:
		if t.visible:
			n += 1
	return n


func _build() -> void:
	add_to_group(&"monsters")
	collision_layer = LAYER
	collision_mask = 1
	for unused: Node in [_arm_l, _arm_r, _held_rock]:   # the Golem's parts: not a cake's
		unused.free()
	_shape = CollisionShape3D.new()
	_shape.shape = _box
	add_child(_shape)
	_fit_box(CakeRules.LAYERS)
	add_child(_body)
	var y := 0.0
	for i in CakeRules.LAYERS:
		var tier := Node3D.new()
		tier.name = "Tier%d" % i
		tier.position.y = y
		_add_mesh(tier, CakeModels.tier_mesh(i))
		if i == 0:
			_add_mesh(tier, CakeModels.eyes_mesh())
		_body.add_child(tier)
		_tier_nodes.append(tier)
		y += CakeModels.TIER_HEIGHTS[i]
	for side in [1.0, -1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(CakeModels.ARM_PIVOT.x * side, CakeModels.ARM_PIVOT.y, 0.0)
		arm.scale.x = side
		_add_mesh(arm, CakeModels.arm_mesh())
		_body.add_child(arm)
		_arms.append(arm)
	_cherry.name = "Cherry"
	_cherry.mesh = CakeModels.cherry_mesh()
	_cherry.position.y = CakeModels.HEIGHTS[CakeRules.LAYERS]
	_body.add_child(_cherry)
	_stars.mesh = GolemModels.stars_mesh()
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


## Its collision box for `n` tiers (every screen: weapon taps find it at its height).
func _fit_box(n: int) -> void:
	var h: float = CakeModels.HEIGHTS[clampi(n, 1, CakeRules.LAYERS)]
	_box.size = Vector3(FOOT, h, FOOT)
	_shape.position.y = h * 0.5


func _ready() -> void:
	Music.play_boss(true)
	Audio.play(&"cake_roar", global_position)


func hit_center() -> Vector3:
	return global_position + Vector3(0, height() * 0.5, 0)


func hit_radius() -> float:
	return 1.5


func is_dazed() -> bool:
	return phase == P.DIZZY


func is_down() -> bool:
	return phase == P.DOWN


# --- Hits (host) -------------------------------------------------------------------------------------

## Not while it rises or drops a tier; double while dizzy; a hit never takes two tiers (CakeRules.after_hit).
## A tier that falls starts LAYER_DROP and every screen hears what comes next. At 0 HP: `defeated`, once.
func take_hit(damage: int, _from: Vector3, _knockback: Vector3) -> void:
	if _defeated or _sleeping or not multiplayer.is_server() or not CakeRules.hittable(phase):
		return
	hp = CakeRules.after_hit(hp, CakeRules.hit_taken(damage, is_dazed()), max_hp)
	if hp == 0:
		_defeated = true
		phase = P.DOWN
		defeated.emit(self)
		queue_free()
		return
	var now := CakeRules.layers_left(hp, max_hp)
	if now < _layers:
		_layers = now
		start_phase(P.LAYER_DROP)
		_rpc_layer.rpc(now)


## Host: a lost fight: it sinks into the frosting and is gone.
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
	if p == P.SPIN:
		_spin_dir = facing()
		_spun.clear()
		_spin_safe = block_at.is_valid() and _safe_ahead(_spin_dir, CakeRules.SPIN_SPEED)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or block_at.is_null():
		return
	if _sleeping:
		_sink(delta)
		return
	if _defeated:
		return
	_layers = mini(_layers, maxi(CakeRules.layers_left(hp, max_hp), 1))
	_phase_t += delta
	_ai_t -= delta
	if _ai_t <= 0.0:
		_ai_t += AI_INTERVAL
		_decide_cake()
	_land_rocks(delta)
	var from := global_position
	match phase:
		P.WALK:
			_walk_cake(delta)
		P.SPIN:
			_spin_step()
		_:
			_stand_cake(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if not (is_on_floor() and velocity.is_zero_approx()):
		move_and_slide()
	if phase == P.SPIN:
		_spin_hits(from, global_position)
		var moved := Vector2(global_position.x - from.x, global_position.z - from.z).length()
		if _phase_t > 0.1 and moved < CakeRules.SPIN_SPEED * delta * 0.3:
			start_phase(P.DIZZY)          # spun into a wall: it stops, dizzy (it never breaks blocks)
			return
	if _phase_t >= CakeRules.phase_time(phase):
		_next_cake()


func _next_cake() -> void:
	var old := phase
	if old == P.WAVE_WARN:
		_wave()
	elif old == P.CHERRY_WARN:
		_throw_cherries()
	start_phase(CakeRules.next_phase(old, _layers))


## Like the Golem's walk; with one tier left it is lighter and hurries.
func _walk_cake(delta: float) -> void:
	var speed := WALK_FAST if _layers == 1 else WALK_SPEED
	velocity.x = move_toward(velocity.x, _walk_dir.x * speed, ACCEL * delta)
	velocity.z = move_toward(velocity.z, _walk_dir.z * speed, ACCEL * delta)
	if is_on_floor() and _walk_dir != Vector3.ZERO and is_on_wall():
		velocity.y = sqrt(2.0 * GRAVITY * STEP_HOP)
	var t := _target_node()
	_turn_to(t.global_position - global_position if t else _walk_dir, delta)


## Winding up, dizzy, dropping a tier, rising: it stands; in a wind-up it keeps turning to its target.
func _stand_cake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ACCEL * 2.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, ACCEL * 2.0 * delta)
	var t := _target_node()
	if t and CakeRules.is_warning(phase):
		_turn_to(t.global_position - global_position, delta)


func _spin_step() -> void:
	if not _spin_safe:
		start_phase(P.DIZZY)
		velocity.x = 0.0
		velocity.z = 0.0
		return
	velocity.x = _spin_dir.x * CakeRules.SPIN_SPEED
	velocity.z = _spin_dir.z * CakeRules.SPIN_SPEED


## Ten times a second: the nearest child or bot friend near its spot, the walk, the ground ahead of a spin.
func _decide_cake() -> void:
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
	elif phase == P.SPIN:
		_spin_safe = _safe_ahead(_spin_dir, CakeRules.SPIN_SPEED)


# --- Attacks (host) -----------------------------------------------------------------------------------

func _wave() -> void:
	var nodes := _targets_now()
	for i in CakeRules.wave_hits(global_position, _info(nodes, true)):
		var away := Vector3(nodes[i].global_position.x - global_position.x, 0.0, nodes[i].global_position.z - global_position.z)
		_hurt(nodes[i], CakeRules.damage(CakeRules.WAVE), away.normalized() * WAVE_PUSH + Vector3.UP * 4.0)
	_rpc_wave.rpc(global_position)


func _throw_cherries() -> void:
	var t := _target_node()
	var at := t.global_position if t else global_position + facing() * 8.0
	var from := global_position + Vector3(0, height() + 0.4, 0)
	for spot in CakeRules.cherry_spots(from, at):
		_rocks.append([BossRules.rock_time(from, spot), spot])
		_rpc_cherry.rpc(from, spot)


## Cherries land: whoever is within reach of where one lands (the Golem's rock rule, the cherry's damage).
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
			_hurt(nodes[i], CakeRules.damage(CakeRules.CHERRIES), away.normalized() * CHERRY_PUSH + Vector3.UP * 3.0)


func _spin_hits(from: Vector3, to: Vector3) -> void:
	var nodes := _targets_now()
	for i in BossRules.charge_hits(from, to, _info(nodes)):
		var id := nodes[i].get_instance_id()
		if _spun.has(id):
			continue
		_spun[id] = true
		var side := Vector3(-_spin_dir.z, 0.0, _spin_dir.x)
		if side.dot(nodes[i].global_position - global_position) < 0.0:
			side = -side
		_hurt(nodes[i], CakeRules.damage(CakeRules.SPIN), (side + _spin_dir * 0.5).normalized() * SPIN_PUSH + Vector3.UP * 4.0)


# --- Everyone: the attacks' effects and the tiers ---------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func _rpc_wave(center: Vector3) -> void:
	var root := get_tree().root
	Fx.ripple(root, center + Vector3(0, 0.05, 0), CakeRules.WAVE_RADIUS / RING_REACH)
	Fx.burst(root, center + Vector3(0, 0.25, 0), CakeModels.PINK, 26, 8.0, 0.2, 0.8, 12.0, 80.0)
	Fx.burst(root, center + Vector3(0, 0.25, 0), CakeModels.CREAM, 16, 6.0, 0.22, 0.8, 12.0, 80.0)
	Audio.play(&"cake_slam", center)
	var me := _local_player()
	if me:
		Feel.slam(Vector2(me.global_position.x - center.x, me.global_position.z - center.z).length())


@rpc("authority", "call_local", "reliable")
func _rpc_cherry(from: Vector3, to: Vector3) -> void:
	if not (from.is_finite() and to.is_finite()):
		return
	var r := GolemRock.new()
	r.look = CakeModels.cherry_ball_mesh()
	r.dust = [CakeModels.CHERRY, CakeModels.PINK]
	r.sound = &"cherry_splat"
	r.setup(from, to)
	add_child(r)
	Audio.play(&"cake_throw", from)


## A tier fell off: every screen says what comes next (the fair signal) and hears the pop.
@rpc("authority", "call_local", "reliable")
func _rpc_layer(left: int) -> void:
	Audio.play(&"layer_pop", global_position + Vector3(0, height(), 0))
	var line: Variant = CakeRules.LAYER_LINES.get(left)
	if line is String:
		Session.magic_feedback.emit(line)


# --- Looks (every peer) -----------------------------------------------------------------------------

func _process(delta: float) -> void:
	if phase != _look_phase:
		_enter_cake_look()
	_look_t += delta
	var standing := layers()
	if standing < _shown_layers and standing > 0:
		for i in range(standing, _shown_layers):
			_falling[i] = 0.0
		_shown_layers = standing
		_fit_box(standing)
		_cherry.position.y = CakeModels.HEIGHTS[standing]
	_tumble(delta)
	if hp < _shown_hp:
		_took_hit_look()   # M5 Task 2: a squash and a lean back
	_shown_hp = hp
	_pose_cake(delta)


## A new phase on this screen: its sound, the cherry's glow, the stars.
func _enter_cake_look() -> void:
	_look_phase = phase
	_look_t = 0.0
	_stars.visible = phase == P.DIZZY
	_stars.position.y = height() + 0.5
	_cherry.mesh = CakeModels.cherry_mesh(phase == P.CHERRY_WARN)
	_cherry.visible = layers() >= 2 or phase == P.CHERRY_WARN
	match phase:
		P.WAVE_WARN:
			Audio.play(&"cake_roar", global_position, -6.0)
		P.CHERRY_WARN:
			Audio.play(&"sparkle", global_position + Vector3(0, height(), 0))
		P.SPIN_WARN:
			Audio.play(&"whirr", global_position)
		P.DOWN:
			_win_roar()   # M5 Task 2


## Fallen tiers slide off to one side, tip over and sink, then burst into crumbs and are gone.
func _tumble(delta: float) -> void:
	for i: int in _falling.keys():
		var tier := _tier_nodes[i]
		_falling[i] += delta
		var k := clampf(_falling[i] / FALL_TIME, 0.0, 1.0)
		var base := 0.0
		for j in i:
			base += CakeModels.TIER_HEIGHTS[j]
		tier.position = Vector3(1.8 * k, base * (1.0 - k * k), 0.0)
		tier.rotation = Vector3(0.0, 0.0, -1.2 * k)
		if k >= 1.0:
			tier.visible = false
			_falling.erase(i)
			var root := get_tree().root if is_inside_tree() else null
			if root:
				var at := tier.global_position + Vector3(0, 0.5, 0)
				for c: Color in CRUMBS:
					Fx.burst(root, at, c, 14, 5.0, 0.16, 0.8, 14.0)


## The body: it rises out of the frosting, wobbles as it walks, squishes down with its arms up before the
## wave, leans back and spins, wobbles while dizzy, and sinks when it goes back to sleep.
func _pose_cake(delta: float) -> void:
	var k := _look_t
	var lift := 0.0
	var squish := 1.0
	var lean := 0.0
	var wobble := 0.0
	var arms := 0.3
	var spin := 0.0
	match phase:
		P.RISE:
			var r := clampf(k / CakeRules.RISE_TIME, 0.0, 1.0)
			lift = -height() * (1.0 - r) * (1.0 - r)
		P.WALK:
			wobble = sin(k * 7.0) * 0.06
			lift = absf(sin(k * 7.0)) * 0.12
		P.WAVE_WARN:
			var w := clampf(k / CakeRules.WAVE_WINDUP, 0.0, 1.0)
			squish = 1.0 - 0.25 * w
			arms = -2.6 * w
		P.CHERRY_WARN:
			arms = -1.2
			_cherry.scale = Vector3.ONE * (1.0 + 0.4 * clampf(k / CakeRules.CHERRY_WINDUP, 0.0, 1.0))
		P.SPIN_WARN:
			lean = -0.3 * clampf(k / 0.4, 0.0, 1.0)
			spin = k * k * 6.0
		P.SPIN:
			spin = k * 18.0
			arms = -1.5
		P.DIZZY:
			wobble = sin(k * 5.0) * 0.1
			_stars.rotation.y = k * 4.0
		P.LAYER_DROP:
			wobble = sin(k * 20.0) * 0.05 * (1.0 - clampf(k / CakeRules.DROP_TIME, 0.0, 1.0))
		P.DOWN:
			lift = -height() * clampf((k - CreatureMoves.WIN_TIME) / SINK_TIME, 0.0, 1.0)
			if CreatureMoves.cheering(k):   # M5 Task 2: it won: arms up, hops and a little twirl
				var c := CreatureMoves.cheer(k)
				lift = c.x
				arms = -c.y
				spin = sin(k * 4.0) * 0.4 * c.y / CreatureMoves.CHEER_ARMS
				lean = c.z
	if phase != P.CHERRY_WARN and _cherry.scale != Vector3.ONE:
		_cherry.scale = Vector3.ONE
	var s := Vector3(1.0 / sqrt(squish), squish, 1.0 / sqrt(squish))
	if _squash > 0.0:
		_squash -= delta
		var q := clampf(_squash / 0.15, 0.0, 1.0)
		s *= Vector3(1.0 + 0.06 * q, 1.0 - 0.08 * q, 1.0 + 0.06 * q)
	if not _body.scale.is_equal_approx(s):
		_body.scale = s
	var p := Vector3(0.0, lift, 0.0)
	if not _body.position.is_equal_approx(p):
		_body.position = p
	var rot := Vector3(lean + _recoil_lean(delta), spin, wobble)
	if not _body.rotation.is_equal_approx(rot):
		_body.rotation = rot
	for arm in _arms:
		if arm.rotation.x != arms:
			arm.rotation.x = arms
