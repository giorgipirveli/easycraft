class_name SporeMother
extends StoneGolem
## The Spore Mother, the Glow Caves' boss (universe 6, spec §5.1; rules in SporeMotherRules). To the BossDirector she
## is a StoneGolem (the same fight, bar, honest help, gold and portal, win and loss); her own rhythm, attacks and looks
## are here. The host simulates her: she rises out of the cave floor, sways after the nearest child, and attacks in
## her fixed rhythm, each attack signalled for a second or more on every screen:
## - SPORES: her cap glows and swells while glowing rings show on the ground (warning_spots: at each child's feet and a
##   few round her); the clouds land there: 1 HP to whoever is still in a ring, and every game slows its own player who
##   is (Player.slow_down); the clouds linger (lingering(): each game slows its own player who walks in, never hurts);
## - RING: she spins with her rim glowing, then a ring of spores rolls out along the ground: 2 HP to whoever stands on
##   the ground within it (a jump clears it);
## - PUFF: she squats, then hides in a big glittering puff (weapons go through it) and glides to a new spot.
## After every attack her gills glow open (GILLS_OPEN, is_dazed for the bar): double damage. Players are hurt through
## Session.hurt_player (shields block from the front), bot friends through hurt(). She never changes a block: she only
## reads the world through block_at.

const P := SporeMotherRules.Phase
const FOOT := 2.0                 # the collision box's width (a small footprint for her size)
const RING_PUSH := 5.0
const SWAY_SPEED := 1.6           # slower than a walking child
const GLIDE := SporeMotherRules.PUFF_MOVE / SporeMotherRules.HIDDEN_TIME * 1.6

## Every screen: the arena's middle (the Totem: BossDirector's "center"), where her clouds and her puff stay near.
var center := Vector3.ZERO
var _spots: Array[Vector3] = []   # every screen: the warning rings of the volley that is coming
var _clouds: Array = []           # every screen: lingering clouds [[spot, seconds left]]
var _puff_to := Vector3.INF       # host: where her puff carries her
var _cap := MeshInstance3D.new()
var _gills := MeshInstance3D.new()
var _puff := MeshInstance3D.new()
var _arms: Array[Node3D] = []
var _rings: Array[MeshInstance3D] = []
var _cloud_looks: Array[MeshInstance3D] = []
var _box := BoxShape3D.new()
var _shown_gills := false


func boss_kind() -> StringName:
	return BossRules.SPORE_MOTHER


func win_sound() -> StringName:
	return &"mother_hum"


## data = {id, pos, yaw, max_hp, tired, center}
func setup(data: Dictionary) -> void:
	center = data.get("center", data.get("pos", Vector3.ZERO))
	super(data)


func _ready() -> void:
	Music.play_boss(true)
	Audio.play(&"mother_hum", global_position)


func hit_center() -> Vector3:
	return global_position + Vector3(0, 2.2, 0)


func hit_radius() -> float:
	return 1.8


## Her gills are open: the bar shows her weak spot (the Golem's dazed look).
func is_dazed() -> bool:
	return phase == P.GILLS_OPEN


func is_down() -> bool:
	return phase == P.DOWN


## Every screen: the warning rings of the coming volley (empty when none).
func warning_spots() -> Array[Vector3]:
	return _spots


## Every screen: the clouds that linger now ([[spot, seconds left]]).
func lingering() -> Array:
	return _clouds


func _build() -> void:
	add_to_group(&"monsters")
	collision_layer = LAYER
	collision_mask = 1
	for unused: Node in [_arm_l, _arm_r, _held_rock]:   # the Golem's parts: not hers
		unused.free()
	var shape := CollisionShape3D.new()
	_box.size = Vector3(FOOT, SporeMotherModels.HEIGHT, FOOT)
	shape.shape = _box
	shape.position.y = SporeMotherModels.HEIGHT * 0.5
	add_child(shape)
	add_child(_body)
	_add_mesh(_body, SporeMotherModels.body_mesh())
	_cap.name = "Cap"
	_cap.mesh = SporeMotherModels.cap_mesh()
	_cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_cap)
	_gills.name = "Gills"
	_gills.mesh = SporeMotherModels.gills_mesh(false)
	_gills.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_gills)
	for side in [1.0, -1.0]:
		var arm := Node3D.new()
		arm.position = Vector3(SporeMotherModels.ARM_PIVOT.x * side, SporeMotherModels.ARM_PIVOT.y, 0.0)
		arm.scale.x = side
		_add_mesh(arm, SporeMotherModels.arm_mesh())
		_body.add_child(arm)
		_arms.append(arm)
	_puff.name = "Puff"
	_puff.mesh = SporeMotherModels.puff_mesh()
	_puff.visible = false
	_puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_puff)
	for i in SporeMotherRules.CLOUDS:
		var ring := MeshInstance3D.new()
		ring.mesh = SporeMotherModels.ring_mesh()
		ring.scale = Vector3.ONE * SporeMotherRules.CLOUD_R
		ring.top_level = true
		ring.visible = false
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_rings.append(ring)
		var cloud := MeshInstance3D.new()
		cloud.mesh = SporeMotherModels.cloud_mesh()
		cloud.top_level = true
		cloud.visible = false
		cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cloud)
		_cloud_looks.append(cloud)
	_stars.mesh = GolemModels.stars_mesh()
	_stars.visible = false
	add_child(_stars)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	for prop in [".:position", ".:rotation", ".:hp", ".:phase"]:
		cfg.add_property(NodePath(prop))
	for prop in [".:hp", ".:phase"]:
		cfg.property_set_replication_mode(NodePath(prop), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


# --- Hits (host) ---------------------------------------------------------------------------------------------

## Not while she rises, hides in her puff or is down; double on her open gills. At 0 HP: `defeated`, once.
func take_hit(damage: int, _from: Vector3, _knockback: Vector3) -> void:
	if _defeated or _sleeping or not multiplayer.is_server() or not SporeMotherRules.hittable(phase):
		return
	hp = maxi(hp - SporeMotherRules.hit_taken(damage, phase), 0)
	if hp == 0:
		_defeated = true
		phase = P.DOWN
		defeated.emit(self)
		queue_free()


func go_to_sleep() -> void:
	if _defeated or _sleeping:
		return
	_sleeping = true
	phase = P.DOWN
	collision_layer = 0
	_sink_t = 0.0


# --- Simulation (host) ---------------------------------------------------------------------------------------

func start_phase(p: int) -> void:
	phase = p
	_phase_t = 0.0
	_walk_dir = Vector3.ZERO
	if not multiplayer.is_server():
		return
	match p:
		P.SPORE_WARN:
			var feet: Array[Vector3] = []
			for n in _targets_now():
				if Vector2(n.global_position.x - center.x, n.global_position.z - center.z).length() <= BossRules.ARENA:
					feet.append(n.global_position)
			var spots := SporeMotherRules.cloud_spots(center, feet, _step)
			for i in spots.size():
				spots[i].y = BossRules.stand_y(spots[i].x, spots[i].z, spots[i].y, block_at) if block_at.is_valid() else spots[i].y
			if is_inside_tree():
				_rpc_warn.rpc(spots)
			else:
				_rpc_warn(spots)
		P.HIDDEN:
			_puff_to = SporeMotherRules.puff_spot(global_position, center, _step)


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or block_at.is_null():
		return
	if _sleeping:
		_sink(delta)
		return
	if _defeated:
		return
	if _dance_hold(delta):   # the Dance Orb: her rhythm waits
		return
	_phase_t += delta
	_ai_t -= delta
	if _ai_t <= 0.0:
		_ai_t += AI_INTERVAL
		_decide_mother()
	match phase:
		P.SWAY:
			_sway(delta)
		P.HIDDEN:
			_glide(delta)
		_:
			_stand_mother(delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if not (is_on_floor() and velocity.is_zero_approx()):
		move_and_slide()
	if _phase_t >= SporeMotherRules.phase_time(phase):
		_next_mother()


func _next_mother() -> void:
	var old := phase
	if old == P.SPORE_WARN:
		_land_clouds()
	elif old == P.RING_WARN:
		_ring()
	var next := SporeMotherRules.next_phase(old, _step)
	if old == P.SWAY:
		_step += 1
	start_phase(next)


## Ten times a second: the nearest child or bot friend near the arena, and the way to sway.
func _decide_mother() -> void:
	var best: Node3D = null
	var best_d := INF
	for n in _targets_now():
		if Vector2(n.global_position.x - center.x, n.global_position.z - center.z).length() > BossRules.ARENA:
			continue
		var d := n.global_position.distance_squared_to(global_position)
		if d < best_d:
			best_d = d
			best = n
	_target = best
	if phase == P.SWAY:
		_plan_walk()


## A slow shuffle towards her child (the Golem's walk, slower), never out of the arena.
func _sway(delta: float) -> void:
	if Vector2(global_position.x - center.x, global_position.z - center.z).length() > SporeMotherRules.ARENA_REACH \
			and _walk_dir.dot(center - global_position) < 0.0:
		_walk_dir = Vector3.ZERO
	velocity.x = move_toward(velocity.x, _walk_dir.x * SWAY_SPEED, ACCEL * delta)
	velocity.z = move_toward(velocity.z, _walk_dir.z * SWAY_SPEED, ACCEL * delta)
	if is_on_floor() and _walk_dir != Vector3.ZERO and is_on_wall():
		velocity.y = sqrt(2.0 * GRAVITY * STEP_HOP)
	var t := _target_node()
	_turn_to(t.global_position - global_position if t else _walk_dir, delta)


## Inside her puff she glides to its spot (a wall stops her: she never breaks blocks).
func _glide(delta: float) -> void:
	if not _puff_to.is_finite():
		_stand_mother(delta)
		return
	var to := Vector3(_puff_to.x - global_position.x, 0.0, _puff_to.z - global_position.z)
	var want := to.normalized() * minf(GLIDE, to.length() / maxf(delta, 0.001)) if to.length() > 0.05 else Vector3.ZERO
	velocity.x = want.x
	velocity.z = want.z


func _stand_mother(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ACCEL * 2.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, ACCEL * 2.0 * delta)
	var t := _target_node()
	if t and SporeMotherRules.is_warning(phase):
		_turn_to(t.global_position - global_position, delta)


# --- Attacks (host) ------------------------------------------------------------------------------------------

## The clouds land on the rings: 1 HP to whoever is still in one (players through the host's hearts, bot friends
## through hurt()); every screen shows them landing and slows its own player who is in one.
func _land_clouds() -> void:
	var spots := _spots.duplicate()
	var nodes := _targets_now()
	for n in nodes:
		for s: Vector3 in spots:
			if SporeMotherRules.cloud_hits(s, n.global_position):
				_hurt(n, SporeMotherRules.damage(SporeMotherRules.SPORES), Vector3.UP * 2.0)
				break
	if is_inside_tree():
		_rpc_land.rpc(spots)
	else:
		_rpc_land(spots)


func _ring() -> void:
	var nodes := _targets_now()
	for i in SporeMotherRules.ring_hits(global_position, _info(nodes, true)):
		var away := Vector3(nodes[i].global_position.x - global_position.x, 0.0, nodes[i].global_position.z - global_position.z)
		_hurt(nodes[i], SporeMotherRules.damage(SporeMotherRules.RING), away.normalized() * RING_PUSH + Vector3.UP * 4.0)
	if is_inside_tree():
		_rpc_ring.rpc(global_position)


# --- Everyone: the signals and the attacks' effects ----------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func _rpc_warn(spots: Array) -> void:
	_spots.clear()
	for s: Variant in spots:
		if s is Vector3 and (s as Vector3).is_finite():
			_spots.append(s)
	for i in _rings.size():
		var shown := i < _spots.size()
		_rings[i].visible = shown
		if shown and is_inside_tree():
			_rings[i].global_position = _spots[i] + Vector3(0, 0.02, 0)


@rpc("authority", "call_local", "reliable")
func _rpc_land(spots: Array) -> void:
	_spots.clear()
	for r in _rings:
		r.visible = false
	var me := _local_player()
	for s: Variant in spots:
		if not (s is Vector3 and (s as Vector3).is_finite()):
			continue
		_clouds.append([s, SporeMotherRules.CLOUD_LINGER])
		if me and SporeMotherRules.cloud_hits(s, me.global_position):
			me.slow_down(SporeMotherRules.SLOW_TIME)
		if is_inside_tree():
			Fx.burst(get_tree().root, s + Vector3(0, 0.6, 0), SporeMotherModels.CLOUD, 14, 2.5, 0.14, 0.9, -0.5)
	while _clouds.size() > _cloud_looks.size():
		_clouds.pop_front()
	if is_inside_tree():
		Audio.play(&"mother_spores", global_position)


@rpc("authority", "call_local", "reliable")
func _rpc_ring(at: Vector3) -> void:
	var root := get_tree().root
	Fx.ripple(root, at + Vector3(0, 0.05, 0), SporeMotherRules.RING_RADIUS / RING_REACH)
	Fx.burst(root, at + Vector3(0, 0.3, 0), SporeMotherModels.CLOUD, 26, 8.0, 0.18, 0.8, 12.0, 80.0)
	Audio.play(&"mother_ring", at)


# --- Looks (every screen) ------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_tick_clouds(delta)
	if phase != _look_phase:
		_enter_mother_look()
	_look_t += delta
	if hp < _shown_hp:
		_took_hit_look()
	_shown_hp = hp
	_pose_mother(delta)


## Lingering clouds fade (each game slows its own player who stands in one; they never hurt).
func _tick_clouds(delta: float) -> void:
	if _clouds.is_empty():
		for c in _cloud_looks:
			if c.visible:
				c.visible = false
		return
	var me := _local_player()
	for c: Array in _clouds:
		c[1] = float(c[1]) - delta
	_clouds = _clouds.filter(func(c: Array) -> bool: return float(c[1]) > 0.0)
	if me and SporeMotherRules.in_cloud(me.global_position, _clouds):
		me.slow_down(0.4)
	for i in _cloud_looks.size():
		var look := _cloud_looks[i]
		var shown := i < _clouds.size()
		if look.visible != shown:
			look.visible = shown
		if shown and look.is_inside_tree():
			var c: Array = _clouds[i]
			var k := clampf(float(c[1]) / SporeMotherRules.CLOUD_LINGER, 0.0, 1.0)
			look.global_position = c[0]
			look.scale = Vector3.ONE * SporeMotherRules.CLOUD_R * (0.4 + 0.6 * k)
			look.rotation.y += delta * 0.6


## A new phase on this screen: its sound, her gills, her puff.
func _enter_mother_look() -> void:
	_look_phase = phase
	_look_t = 0.0
	var open := phase == P.GILLS_OPEN
	if open != _shown_gills:
		_shown_gills = open
		_gills.mesh = SporeMotherModels.gills_mesh(open)
	_puff.visible = phase == P.HIDDEN
	_body.visible = phase != P.HIDDEN
	match phase:
		P.SPORE_WARN:
			Audio.play(&"spore_swell", global_position + Vector3(0, 3, 0))
		P.RING_WARN:
			Audio.play(&"whirr", global_position)
		P.PUFF_WARN:
			Audio.play(&"spore_puff", global_position)
		P.HIDDEN:
			Audio.play(&"mother_puff", global_position)
			if is_inside_tree():
				Fx.burst(get_tree().root, global_position + Vector3(0, 2, 0), SporeMotherModels.CLOUD, 30, 4.0, 0.3, 1.0, 1.0)
		P.GILLS_OPEN:
			Audio.play(&"sparkle", global_position + Vector3(0, 3, 0))
		P.DOWN:
			_win_roar()


## She rises out of the floor, sways and bobs, her cap swells before the spores, she spins before the ring, squats
## before the puff, wobbles with her gills open, and sinks when she goes back to sleep.
func _pose_mother(delta: float) -> void:
	var k := _look_t
	var lift := 0.0
	var squish := 1.0
	var lean := 0.0
	var wobble := 0.0
	var spin := 0.0
	var arms := 0.2
	var cap := 1.0
	match phase:
		P.RISE:
			var r := clampf(k / SporeMotherRules.RISE_TIME, 0.0, 1.0)
			lift = -SporeMotherModels.HEIGHT * (1.0 - r) * (1.0 - r)
		P.SWAY:
			wobble = sin(k * 3.0) * 0.07
			lift = absf(sin(k * 3.0)) * 0.1
			arms = 0.3 + sin(k * 3.0) * 0.2
		P.SPORE_WARN:
			var w := clampf(k / SporeMotherRules.SPORE_WINDUP, 0.0, 1.0)
			cap = 1.0 + 0.18 * w + 0.04 * sin(k * 18.0) * w
			arms = -1.6 * w
		P.RING_WARN:
			spin = k * k * 8.0
			lean = -0.12
		P.PUFF_WARN:
			squish = 1.0 - 0.22 * clampf(k / SporeMotherRules.PUFF_WINDUP, 0.0, 1.0)
		P.GILLS_OPEN:
			wobble = sin(k * 5.0) * 0.09
			lean = -0.15
			arms = 0.9
		P.DOWN:
			lift = -SporeMotherModels.HEIGHT * clampf((k - CreatureMoves.WIN_TIME) / SINK_TIME, 0.0, 1.0)
			if CreatureMoves.cheering(k):
				var c := CreatureMoves.cheer(k)
				lift = c.x
				arms = -c.y
				lean = c.z
	if _puff.visible:
		_puff.rotation.y += delta * 0.8
		var pk := 1.0 + 0.05 * sin(k * 6.0)
		_puff.scale = Vector3(pk, pk, pk)
	var s := Vector3(1.0 / sqrt(squish), squish, 1.0 / sqrt(squish))
	if _squash > 0.0:
		_squash -= delta
		var q := clampf(_squash / 0.15, 0.0, 1.0)
		s *= Vector3(1.0 + 0.06 * q, 1.0 - 0.08 * q, 1.0 + 0.06 * q)
	if not _body.scale.is_equal_approx(s):
		_body.scale = s
	var cs := Vector3(cap, 1.0 + (cap - 1.0) * 0.5, cap)
	if not _cap.scale.is_equal_approx(cs):
		_cap.scale = cs
	var p := Vector3(0.0, lift, 0.0)
	if not _body.position.is_equal_approx(p):
		_body.position = p
	var rot := Vector3(lean + _recoil_lean(delta), spin, wobble)
	if not _body.rotation.is_equal_approx(rot):
		_body.rotation = rot
	for arm in _arms:
		if arm.rotation.x != arms:
			arm.rotation.x = arms
