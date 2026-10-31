class_name Buddy
extends CharacterBody3D
## A living build: meshed from the blocks it was made of, with googly eyes and a name tag.
## Follows its owner with bouncy hops (or hovers, if mostly glass), glows if it has light blocks,
## and cheers when tapped. The host simulates it; other peers see a synced copy.

const LAYER := 4                     # physics layer 3: buddies (players and the world ignore it)
const GRAVITY := 20.0
const FOLLOW_DISTANCE := 3.5
const TELEPORT_DISTANCE := 40.0
const ACCEL := 20.0
## Collision footprint cap (blocks). Physics cost grows with the box's footprint on the voxel
## terrain: ten house-sized buddies with full-size boxes dropped phones to 3 FPS (owner feedback #9).
## Big buddies stand on a compact base; they keep their full height so walls still stop them.
const MAX_FOOTPRINT := 1.8
## The wake-up ceremony (M2 Task 17) of a buddy the wand just woke: sparkles swirl, its eyes blink
## open, its name pops in with a chime, its owner's camera leans in a little. Over by WAKE_TIME.
const WAKE_TIME := 1.6
const LEAN_FOV := 8.0                # degrees the owner's camera narrows at the peak (never with Reduce motion)

var blocks: Dictionary = {}          # Vector3i offset (min corner at 0) -> block id
var traits: Dictionary = {}
var buddy_name := ""
var owner_peer := 1
var size_blocks := Vector3i.ONE
var fresh := false                  # woken just now (the ceremony plays), not loaded from a save

var _body := Node3D.new()            # visual root: squash, spin
var _pupils: Array[Node3D] = []
var _t := 0.0
var _last_y := 0.0
var _last_vy := 0.0
var _anim: Tween
var _tag: Label3D
var _whites: Array[MeshInstance3D] = []


## Spawn data <-> buddy. data = {flat, name, owner, pos, yaw, id}
func setup(data: Dictionary) -> void:
	blocks = unpack(data.flat)
	buddy_name = str(data.name)
	owner_peer = int(data.owner)
	fresh = bool(data.get("fresh", false))
	name = str(data.id)
	position = data.pos
	rotation.y = float(data.yaw)
	traits = BuddyTraits.from_blocks(blocks)
	_t20b_setup()   # M3 Task 20b: a secret shape's own traits (before _build: its light, its float)
	var mx := Vector3i.ZERO
	for p: Vector3i in blocks:
		mx = Vector3i(maxi(mx.x, p.x), maxi(mx.y, p.y), maxi(mx.z, p.z))
	size_blocks = mx + Vector3i.ONE
	_ride_setup()   # M3 Task 20a: a saddle makes it rideable (before _build: a flyer's wings are meshes of their own)
	_build()
	_wake_kind_setup()   # M3 Task 21c: a cactus, a pumpkin or a snowman has a personality of its own
	_t20b_look()   # M3 Task 20b: a special buddy's name tag in its colour


func to_save() -> Dictionary:
	var list: Array = []
	for p: Vector3i in blocks:
		list.append([p.x, p.y, p.z, blocks[p]])
	var d := {"blocks": list, "pos": [global_position.x, global_position.y, global_position.z], "yaw": rotation.y, "name": buddy_name}
	_t20b_save(d)   # M3 Task 20b: its tricks
	return d


static func pack(b: Dictionary) -> PackedInt32Array:
	var flat := PackedInt32Array()
	for p: Vector3i in b:
		flat.append_array([p.x, p.y, p.z, b[p]])
	return flat


static func unpack(flat: PackedInt32Array) -> Dictionary:
	var b := {}
	for i in range(0, flat.size() - 3, 4):
		b[Vector3i(flat[i], flat[i + 1], flat[i + 2])] = flat[i + 3]
	return b


## Plays the happy animation (and a jump on the host).
func cheer() -> void:
	Audio.play(&"air_jump", global_position)
	_wake_kind_cheer()   # M3 Task 21c
	BabbleVoices.say(self, &"buddy", voice_size(), "Yay! Hooray!", true, buddy_name)   # M3 Task 21a
	# Particles go to the scene root (they free themselves), never into the buddy container.
	Fx.burst(get_tree().root, global_position + Vector3(0, size_blocks.y + 0.3, 0), Color("ff5c8a"), 12, 3.0, 0.14, 0.8, 4.0)
	if _anim and _anim.is_valid():
		_anim.kill()
	_anim = create_tween()
	_anim.tween_property(_body, "rotation:y", _body.rotation.y + TAU, 0.5).set_trans(Tween.TRANS_BACK)
	if multiplayer.is_server() and (is_on_floor() or traits.floaty):
		velocity.y = sqrt(2.0 * GRAVITY * (traits.hop + 1.2))


func _build() -> void:
	collision_layer = LAYER
	collision_mask = 1
	add_to_group(&"buddies")   # weapons make buddies cheer (M1b Task 11)
	add_child(_body)
	var s := Vector3(size_blocks)
	var buf := VoxelBuffer.new()
	buf.create(size_blocks.x + 2, size_blocks.y + 2, size_blocks.z + 2)
	for p: Vector3i in blocks:
		if not _wing_cells.has(p):   # M3 Task 20a: a flyer's wings are meshed on their own (they flap)
			buf.set_voxel(blocks[p], p.x + 1, p.y + 1, p.z + 1, VoxelBuffer.CHANNEL_TYPE)
	var mesher := VoxelMesherBlocky.new()
	mesher.library = WorldService.library()
	var mi := MeshInstance3D.new()
	mi.mesh = mesher.build_mesh(buf, [], {})
	mi.position = Vector3(-s.x * 0.5, 0.0, -s.z * 0.5)   # mesh coords == block offsets
	_body.add_child(mi)
	_build_wings(mesher)   # M3 Task 20a

	var box := BoxShape3D.new()
	box.size = Vector3(minf(s.x * 0.9, MAX_FOOTPRINT), s.y * 0.95, minf(s.z * 0.9, MAX_FOOTPRINT))
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = s.y * 0.5
	add_child(shape)

	var eye_r := clampf(minf(s.x, s.y) * 0.17, 0.14, 0.45)
	var eye_y := maxf(s.y - eye_r * 1.6, eye_r + 0.1)
	var spread := clampf(s.x * 0.22, eye_r * 1.15, 1.2)
	for side in [-1.0, 1.0]:
		_eye(Vector3(side * spread, eye_y, -s.z * 0.5 - 0.02), eye_r)

	var tag := Label3D.new()
	_tag = tag
	tag.text = buddy_name
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.font_size = 44
	tag.outline_size = 12
	tag.pixel_size = 0.011
	tag.position.y = s.y + 0.55
	add_child(tag)

	if traits.glow:
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.9, 0.6)
		light.light_energy = traits.glow_energy
		light.omni_range = 6.0 + s.y
		light.position.y = s.y * 0.5
		add_child(light)

	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	cfg.add_property(NodePath(".:position"))
	cfg.add_property(NodePath(".:rotation"))
	_sync_ride(cfg)   # M3 Task 20a: who rides it and what it does now
	sync.replication_config = cfg
	add_child(sync)
	_last_y = position.y


func _eye(pos: Vector3, r: float) -> void:
	var white := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = r
	ball.height = r * 2.0
	var wm := StandardMaterial3D.new()
	wm.albedo_color = Color(1, 1, 1)
	wm.roughness = 0.3
	ball.material = wm
	white.mesh = ball
	white.position = pos
	_body.add_child(white)
	_whites.append(white)
	var pupil := MeshInstance3D.new()
	var dot := SphereMesh.new()
	dot.radius = r * 0.5
	dot.height = r
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.05, 0.05, 0.07)
	dot.material = pm
	pupil.mesh = dot
	pupil.position = Vector3(0, 0, -r * 0.62)
	white.add_child(pupil)
	_pupils.append(pupil)


func _ready() -> void:
	if fresh:
		_wake_up()


## Whether this game's camera leans in towards a new buddy: its owner's own game, and not with
## Reduce motion.
static func camera_leans(is_fresh: bool, owner_id: int, local_id: int, reduce_motion: bool) -> bool:
	return is_fresh and owner_id == local_id and not reduce_motion


func _wake_up() -> void:
	for w in _whites:
		w.scale.y = 0.05                   # eyes closed
	_tag.scale = Vector3.ZERO
	var sparkles := create_tween()
	for i in 4:                            # a swirl of sparkles up around the body (the shared Fx material)
		sparkles.tween_callback(_sparkle.bind(i))
		sparkles.tween_interval(0.18)
	var eyes := create_tween()
	eyes.tween_interval(0.8)
	eyes.tween_method(_open_eyes, 0.05, 1.0, 0.12)
	eyes.tween_method(_open_eyes, 1.0, 0.05, 0.08)   # a sleepy blink ...
	eyes.tween_method(_open_eyes, 0.05, 1.0, 0.12)   # ... and awake
	var tag := create_tween()
	tag.tween_interval(1.1)
	tag.tween_property(_tag, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tag.parallel().tween_callback(func() -> void:
		Audio.play(&"chime", global_position)
		BabbleVoices.say(self, &"buddy", voice_size(), "Hello! I'm awake!", true, buddy_name))   # M3 Task 21a
	if camera_leans(fresh, owner_peer, multiplayer.get_unique_id(), bool(Profile.data.settings.get("reduce_motion", false))):
		var cam := get_viewport().get_camera_3d()
		if cam:
			var fov := cam.fov
			var lean := create_tween()
			lean.tween_property(cam, "fov", fov - LEAN_FOV, WAKE_TIME * 0.5).set_trans(Tween.TRANS_SINE)
			lean.tween_property(cam, "fov", fov, WAKE_TIME * 0.5).set_trans(Tween.TRANS_SINE)


func _open_eyes(y: float) -> void:
	for w in _whites:
		w.scale.y = y


func _sparkle(i: int) -> void:
	if not is_inside_tree():
		return
	var s := Vector3(size_blocks)
	var angle := TAU * i / 4.0
	var at := global_position + Vector3(cos(angle) * (s.x * 0.5 + 0.3), s.y * (0.2 + 0.25 * i), sin(angle) * (s.z * 0.5 + 0.3))
	Fx.wake(get_tree().root, at)   # M5 Task 2: the wake's gold stars (one style everywhere)


## Owner #110 (VR round 4, idea 3): a child in a headset near: the pupils look at its eyes (VrGestures sets it each
## frame; INF: the googly jiggle as always).
var look_target := Vector3.INF


func _process(delta: float) -> void:
	_t += delta
	for i in _pupils.size():   # googly jiggle
		var r := (_pupils[i].get_parent() as MeshInstance3D).mesh.get("radius") as float
		if look_target.is_finite():
			var white := _pupils[i].get_parent() as Node3D
			_pupils[i].position = VrGestureRules.pupil_position(white.to_local(look_target), r) \
				+ Vector3(sin(_t * 7.0 + i * 1.7) * r * 0.04, cos(_t * 5.0 + i) * r * 0.03, 0.0)
			continue
		_pupils[i].position.x = sin(_t * 7.0 + i * 1.7) * r * 0.18
		_pupils[i].position.y = cos(_t * 5.0 + i) * r * 0.14
		_pupils[i].position.z = -r * 0.62
	var vy := (global_position.y - _last_y) / maxf(delta, 0.001)
	if _last_vy < -2.0 and absf(vy) < 0.5:   # just landed: squash and stretch
		_squash()
		wake_kind_landed()   # M3 Task 21c: a pumpkin rolls, a snowman puffs snow
	_last_vy = vy
	_last_y = global_position.y
	_ride_process(delta)   # M3 Task 20a: wings flap, the rider found on this game
	_t20b_process(delta)   # M3 Task 20b: a special buddy's own thing now and then


func _squash() -> void:
	if _anim and _anim.is_valid():
		return
	_anim = create_tween()
	_anim.tween_property(_body, "scale", Vector3(1.18, 0.8, 1.18) * grown, 0.07)
	_anim.tween_property(_body, "scale", Vector3.ONE * grown, 0.18).set_trans(Tween.TRANS_BACK)   # M3 Task 20b: grown


func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if rider_peer != 0:   # M3 Task 20a: ridden, the rider's stick moves it
		_ride_step(delta)
		return
	if visiting:   # M4 I: waiting in a friend's showcase
		_visit_step(delta)
		return
	var owner := _find_owner()
	if owner == null or not owner.is_spawned():
		return
	var to := _goal(owner.global_position) - global_position   # M4 I: a playdate's spot, else the owner
	to.y = 0.0
	var dist := to.length()
	if dist > TELEPORT_DISTANCE or global_position.y < SpawnRules.FALL_LIMIT_Y:
		global_position = owner.global_position + Vector3(2.0, 1.0, 2.0)
		velocity = Vector3.ZERO
		return
	var dir := to / dist if dist > _follow_distance() else Vector3.ZERO
	var speed: float = traits.speed
	velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta)
	if traits.floaty:
		var hover := owner.global_position.y + 1.4 + sin(_t * 2.0) * 0.4
		velocity.y = (hover - global_position.y) * 3.0
	elif is_on_floor():
		if dir != Vector3.ZERO:
			var height: float = traits.hop + (1.2 if is_on_wall() else 0.0)
			velocity.y = sqrt(2.0 * GRAVITY * height)
	else:
		velocity.y -= GRAVITY * delta
	if dir != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(8.0 * delta, 0.0, 1.0))
	move_and_slide()


## Its owner's body, or null when the owner left (M3 Task 19: it waits where it is, like a pet, instead of following
## whichever child it looked at last; a saved buddy is the host's again when the world loads).
func _find_owner() -> Player:
	for p: Player in get_tree().get_nodes_in_group(&"players"):
		if p.peer_id == owner_peer:
			return p
	return null

# --- M4 Wave 3, agent I: playdates and waiting in a showcase ---

## Host: where a playdate (PlaydateDirector) takes this buddy; INF: it follows its owner, as always.
var playdate_target := Vector3.INF
## In a friend's showcase visit: it stands where it is and waves for visitors now and then.
var visiting := false
const PLAYDATE_GAP := 0.8          # how close it walks to a playdate's spot
const VISIT_WAVE_EVERY := 4.0

var _wave_wait := 0.0


## Where it walks: a playdate's spot, else its owner's feet (M3 Task 20b: or where a puppy buddy fetches).
func _goal(owner_pos: Vector3) -> Vector3:
	if playdate_target.is_finite():
		return playdate_target
	return fetch_target if fetch_target.is_finite() else owner_pos


func _follow_distance() -> float:
	return PLAYDATE_GAP if playdate_target.is_finite() else FOLLOW_DISTANCE


## Turns to look at `point` (its face is its -Z side).
func face(point: Vector3) -> void:
	var d := point - global_position if is_inside_tree() else point - position
	if Vector2(d.x, d.z).length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)


## A friendly wave: a wiggle side to side and a little hop (every game plays it: PlaydateDirector's RPC).
func wave() -> void:
	if _anim and _anim.is_valid():
		_anim.kill()
	_anim = create_tween()
	for i in 3:
		_anim.tween_property(_body, "rotation:z", 0.22, 0.12).set_trans(Tween.TRANS_SINE)
		_anim.tween_property(_body, "rotation:z", -0.22, 0.12).set_trans(Tween.TRANS_SINE)
	_anim.tween_property(_body, "rotation:z", 0.0, 0.1)
	_anim.parallel().tween_property(_body, "position:y", 0.35, 0.15).set_trans(Tween.TRANS_QUAD)
	_anim.tween_property(_body, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE)


## A little dance together: two turns with hops, then a bow.
func dance() -> void:
	if _anim and _anim.is_valid():
		_anim.kill()
	_anim = create_tween()
	for i in 2:
		_anim.tween_property(_body, "rotation:y", _body.rotation.y + TAU * (i + 1), 0.6).set_trans(Tween.TRANS_SINE)
		_anim.parallel().tween_property(_body, "position:y", 0.5, 0.3).set_trans(Tween.TRANS_QUAD)
		_anim.tween_property(_body, "position:y", 0.0, 0.3).set_trans(Tween.TRANS_BOUNCE)
	_anim.tween_property(_body, "rotation:x", 0.35, 0.2)
	_anim.tween_property(_body, "rotation:x", 0.0, 0.25)
	_anim.tween_callback(func() -> void:
		if is_inside_tree():
			Fx.burst(get_tree().root, global_position + Vector3(0, size_blocks.y + 0.3, 0), Color("ffd23f"), 10, 3.0, 0.12, 0.7, 4.0))


## A visiting buddy: gravity only, and a wave every few seconds.
func _visit_step(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity = Vector3.ZERO
	move_and_slide()
	_wave_wait -= delta
	if _wave_wait <= 0.0:
		_wave_wait = VISIT_WAVE_EVERY
		wave()

# --- M3 Task 20a: rideable buddies ---
# A buddy built with a SADDLE can be ridden, and what it does comes from its shape (RideRules): wings fly, wheels
# drive, water sails, anything else walks. The host decides everything: RideDirector puts a rider on
# (rider_peer, synced), the rider's stick comes in (set_ride_input, like a player's input), the host moves the
# buddy here with its one compact collision box (owner feedback #9) and decides 10 times a second (water,
# steps, landings). Every game puts the rider on the saddle (Player.riding) and flaps a flyer's wings.

const FLAP_RATE := 7.0            # radians a second: a wing beat about every 0.9 s
const FLAP_ANGLE := 0.55          # how far the wings beat up and down (radians)
const BUMP_EVERY := 0.4           # a car's thud at most this often

## What it does when ridden (RideRules.Kind; NONE without a saddle), from its blocks, on every game.
var ride_kind: int = RideRules.Kind.NONE
## The player riding it (0: nobody). The host decides; synced, so each game puts that player on the saddle.
var rider_peer := 0:
	set(v):
		rider_peer = v
		_link_rider()
## What it does right now (FLY, DRIVE, SAIL or WALK; NONE while nobody rides). Host; synced (wings flap, UP/DOWN).
var ride_mode: int = RideRules.Kind.NONE
## Host: the rider's stick (RideRules.clean_wish: x/z the way to go, y up or down).
var ride_input := Vector3.ZERO

var _seat := Vector3.ZERO                   # the rider's feet in the buddy's own space
var _wing_cells := {}                       # a flyer's wing blocks (meshed apart from the body)
var _wings: Array[Node3D] = []              # left and right wing hinges
var _rider: Player                          # this game's copy of the rider
var _input_age := INF
var _ride_clock := 0.0
var _relink_clock := 0.0
var _hop := false
var _surface := NAN
var _air_time := 0.0
var _was_airborne := false
var _bump_wait := 0.0
var _flap := 0.0


func _ride_setup() -> void:
	ride_kind = RideRules.kind_of(blocks)
	_seat = RideRules.seat_offset(blocks, size_blocks)
	_wing_cells = {}
	if ride_kind == RideRules.Kind.FLY:
		var w := RideRules.wings(blocks)
		for p: Vector3i in w.get("left", []) + w.get("right", []):
			_wing_cells[p] = true


## A flyer's two wings: meshes of their own on hinges at the body's sides, so they can beat.
func _build_wings(mesher: VoxelMesherBlocky) -> void:
	if _wing_cells.is_empty():
		return
	var s := Vector3(size_blocks)
	var w := RideRules.wings(blocks)
	var lo := 1 << 30
	var hi := -(1 << 30)
	for p: Vector3i in blocks:
		if p.y < size_blocks.y / 2:
			lo = mini(lo, p.x)
			hi = maxi(hi, p.x)
	for side: String in ["left", "right"]:
		var cells: Array = w[side]
		var bottom := 1 << 30
		var buf := VoxelBuffer.new()
		buf.create(size_blocks.x + 2, size_blocks.y + 2, size_blocks.z + 2)
		for p: Vector3i in cells:
			buf.set_voxel(blocks[p], p.x + 1, p.y + 1, p.z + 1, VoxelBuffer.CHANNEL_TYPE)
			bottom = mini(bottom, p.y)
		var hinge := Node3D.new()
		hinge.name = "Wing_" + side
		hinge.position = Vector3((lo if side == "left" else hi + 1) - s.x * 0.5, bottom + 0.5, 0.0)
		var mi := MeshInstance3D.new()
		mi.mesh = mesher.build_mesh(buf, [], {})
		mi.position = Vector3(-s.x * 0.5, 0.0, -s.z * 0.5) - hinge.position
		hinge.add_child(mi)
		_body.add_child(hinge)
		_wings.append(hinge)


func _sync_ride(cfg: SceneReplicationConfig) -> void:
	for prop: String in ["rider_peer", "ride_mode"]:
		var path := NodePath(".:" + prop)
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


## Where the rider's feet go now, in the world: on top of the saddle.
func seat_position() -> Vector3:
	return global_transform * _seat if is_inside_tree() else transform * _seat


## The player riding it on this game (null for none).
func rider() -> Player:
	return _rider if is_instance_valid(_rider) and _rider.peer_id == rider_peer else null


## Host: `peer` gets on (RideDirector checked it may).
func start_ride(peer: int) -> void:
	rider_peer = peer
	ride_input = Vector3.ZERO
	_input_age = INF
	_hop = false
	_air_time = 0.0
	_was_airborne = false
	_ride_decide()


## Host: the rider is off; it follows its owner again (a flyer drops to the ground).
func end_ride() -> void:
	rider_peer = 0
	ride_mode = RideRules.Kind.NONE
	ride_input = Vector3.ZERO
	velocity = Vector3(0.0, minf(velocity.y, 0.0), 0.0)


## Host: the rider's stick, as it came from the rider's game (cleaned by RideRules.clean_wish).
func set_ride_input(wish: Vector3) -> void:
	ride_input = RideRules.clean_wish(wish)
	_input_age = 0.0


## Host: standing on the ground, or on the water's top (a boat, a flyer that came down on a lake).
func resting() -> bool:
	return is_on_floor() or (is_finite(_surface) and global_position.y <= _surface - RideRules.DRAFT + 0.2)


## Host: has a flyer been in the air since the ride started (Survivor: landing ends the ride)?
func was_airborne() -> bool:
	return _was_airborne


## Every game: puts this game's rider on (or off) the saddle when rider_peer changes.
func _link_rider() -> void:
	if not is_inside_tree():
		return
	var next: Player = null
	if rider_peer != 0:
		for p: Player in get_tree().get_nodes_in_group(&"players"):
			if p.peer_id == rider_peer and not p.is_queued_for_deletion():
				next = p
				break
	if is_instance_valid(_rider) and _rider != next and _rider.riding == self:
		_rider.riding = null
	_rider = next
	if next:
		next.riding = self


func _exit_tree() -> void:
	if is_instance_valid(_rider) and _rider.riding == self:
		_rider.riding = null
	_rider = null


## Every frame on every game: a ridden flyer beats its wings; a rider not found yet (still joining) is looked for.
func _ride_process(delta: float) -> void:
	if rider_peer != 0 and rider() == null:
		_relink_clock -= delta
		if _relink_clock <= 0.0:
			_relink_clock = RideRules.DECIDE_EVERY
			_link_rider()
	if _wings.is_empty():
		return
	var beating := ride_mode == RideRules.Kind.FLY and rider_peer != 0
	var angle := 0.0
	if beating:
		var before := _flap
		_flap = fmod(_flap + FLAP_RATE * delta, TAU)
		angle = sin(_flap) * FLAP_ANGLE
		if _flap < before and is_inside_tree():   # one beat a turn: a soft whoosh
			Audio.play(&"whoosh", global_position, -14.0)
	else:
		_flap = 0.0
		angle = lerpf(_wings[0].rotation.z, 0.0, clampf(6.0 * delta, 0.0, 1.0))
	_wings[0].rotation.z = -angle
	if _wings.size() > 1:
		_wings[1].rotation.z = angle


## Host, every physics step while ridden: the stick moves it (RideRules.step); gravity for walkers, cars and
## boats (a boat floats at the water's top); hops onto 1-block steps; a car bumps off walls.
func _ride_step(delta: float) -> void:
	_ride_clock -= delta
	if _ride_clock <= 0.0:
		_ride_clock = RideRules.DECIDE_EVERY
		_ride_decide()
	_input_age += delta
	_bump_wait = maxf(_bump_wait - delta, 0.0)
	var wish := ride_input if _input_age < RideRules.INPUT_STALE else Vector3.ZERO
	var r := RideRules.step(ride_mode, velocity, rotation.y, wish, wish.y, delta)
	velocity = r.velocity
	rotation.y = r.yaw
	var floating := is_finite(_surface) and global_position.y <= _surface - RideRules.DRAFT + 0.15
	var lift := clampf((_surface - RideRules.DRAFT - global_position.y) * 4.0, -4.0, 4.0) if floating else 0.0
	if ride_mode == RideRules.Kind.SAIL and floating:
		velocity.y = lift   # floats
	elif ride_mode == RideRules.Kind.FLY and floating:
		velocity.y = maxf(velocity.y, lift)   # a flyer comes down on the water's top, never under it
	elif ride_mode != RideRules.Kind.FLY and not is_on_floor():
		velocity.y -= GRAVITY * delta
	if _hop:
		_hop = false
		velocity.y = RideRules.hop_velocity(ride_mode, GRAVITY)
	var going := Vector3(velocity.x, 0.0, velocity.z)
	move_and_slide()
	if ride_mode == RideRules.Kind.DRIVE and is_on_wall() and _bump_wait <= 0.0 and going.length() > 2.0:
		var wall := get_wall_normal()
		if -going.normalized().dot(Vector3(wall.x, 0.0, wall.z).normalized()) > 0.5:   # head-on, not a scrape
			_bump_wait = BUMP_EVERY
			if RideRules.wants_hop(ride_mode, _step_ahead(going)):
				_hop = true   # a 1-block step: up it goes
			else:
				velocity = RideRules.bump(going, wall) + Vector3(0.0, velocity.y, 0.0)
				_ride_fx.rpc(&"thud")
				_play_ride_fx(&"thud")


## Host, 10 times a second: what it does now (on water: sails), where the water's top is, a step to hop onto,
## and whether a flyer has taken off.
func _ride_decide() -> void:
	var world := Session.world
	var on_water := world != null and RideRules.on_water(global_position, world.get_block)
	var now := RideRules.mode(ride_kind, on_water)
	if now != ride_mode:
		ride_mode = now
	_surface = NAN
	if world != null and ride_mode == RideRules.Kind.SAIL:
		_surface = RideRules.water_surface(global_position, world.get_block)
	elif world != null and ride_mode == RideRules.Kind.FLY:   # water just under a flyer (it lands on its top)
		_surface = RideRules.water_surface(global_position + Vector3.DOWN, world.get_block)
	if ride_mode == RideRules.Kind.FLY:
		_air_time = 0.0 if resting() else _air_time + RideRules.DECIDE_EVERY
		if _air_time >= RideRules.AIRBORNE_AFTER:
			_was_airborne = true
		return
	var flat := Vector3(ride_input.x, 0.0, ride_input.z)
	if world == null or _input_age >= RideRules.INPUT_STALE or flat.length() < 0.3 or not is_on_wall():
		return
	var dir := flat if ride_mode == RideRules.Kind.WALK else Basis(Vector3.UP, rotation.y) * Vector3.FORWARD
	if RideRules.wants_hop(ride_mode, _step_ahead(dir)) and (is_on_floor() or ride_mode == RideRules.Kind.SAIL):
		_hop = true


## Host: how high the ground rises just ahead of its box going `dir` (a boat measures from the water's top).
func _step_ahead(dir: Vector3) -> int:
	var world := Session.world
	if world == null:
		return 0
	var feet := global_position
	if ride_mode == RideRules.Kind.SAIL and is_finite(_surface):
		feet.y = _surface
	var half := minf(maxf(size_blocks.x, size_blocks.z) * 0.45, MAX_FOOTPRINT * 0.5)
	return RideRules.climb_height(feet, dir, half + 0.4, func(c: Vector3i) -> bool: return BlockIds.is_solid(world.get_block(c)))


## The host's ride sounds on every other game (a car's thud).
@rpc("authority", "call_remote", "unreliable")
func _ride_fx(kind: StringName) -> void:
	_play_ride_fx(kind)


func _play_ride_fx(kind: StringName) -> void:
	if kind == &"thud" and is_inside_tree():
		Audio.play(&"thud", global_position, -6.0)

# --- M3 Task 21c: waking more things (WakeKinds) ---
# A build of its own blocks wakes with a personality of its own, on every game (the kind comes from the synced
# blocks): a cactus's pink flower pops out when it cheers, a jack-o-lantern glows orange, a pumpkin rocks and rolls
# as it lands and giggles when cheered, a snowman puffs snowflakes as it lands. Looks are shared (one flower mesh;
# the shared Fx bursts).

const SNOW_PUFF_EVERY := 1.0       # seconds between a snowman's puffs of snow
const FLOWER_TIME := 1.4           # seconds a cactus's flower shows
const _FLOWER_PINK := Color("ff6fb5")
const _FLOWER_CENTRE := Color("ffd23f")

static var _flower_mesh: Mesh

## What it woke as (WakeKinds.CACTUS, PUMPKIN, SNOWMAN; NONE for an ordinary buddy).
var wake_kind: StringName = WakeKinds.NONE
## Puffs of snow so far (tests).
var snow_puffs := 0

var _flower: MeshInstance3D
var _flower_tween: Tween
var _roll: Tween
var _last_puff_ms := -100000


func _wake_kind_setup() -> void:
	if recipe != &"":   # M3 Task 20b's secret shapes come first: a secret snowman is Frosty, not a wake-kind snowman
		return
	wake_kind = WakeKinds.kind_of(blocks)
	if WakeKinds.glows(blocks):
		var light := OmniLight3D.new()
		light.light_color = WakeKinds.GLOW_COLOR
		light.light_energy = 1.2
		light.omni_range = 5.0 + size_blocks.y
		light.position.y = size_blocks.y * 0.6
		add_child(light)
	if wake_kind == WakeKinds.CACTUS:
		_flower = MeshInstance3D.new()
		_flower.name = "Flower"
		_flower.mesh = _shared_flower()
		_flower.position = Vector3(0, size_blocks.y + 0.02, 0)
		_flower.visible = false
		_body.add_child(_flower)


## A cactus's flower (null for other kinds).
func flower() -> MeshInstance3D:
	return _flower


func _wake_kind_cheer() -> void:
	match wake_kind:
		WakeKinds.CACTUS:
			if _flower == null:
				return
			if _flower_tween and _flower_tween.is_valid():
				_flower_tween.kill()
			_flower.visible = true
			_flower.scale = Vector3.ONE * 0.1
			if is_inside_tree():
				_flower_tween = create_tween()
				_flower_tween.tween_property(_flower, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				_flower_tween.tween_interval(FLOWER_TIME)
				_flower_tween.tween_property(_flower, "scale", Vector3.ONE * 0.1, 0.2)
				_flower_tween.tween_callback(func() -> void: _flower.visible = false)
		WakeKinds.PUMPKIN:
			Audio.play(&"giggle", global_position if is_inside_tree() else position, -6.0, 1.3)


## Just landed a hop: a pumpkin rocks and rolls; a snowman puffs snow (at most once a second).
func wake_kind_landed() -> void:
	match wake_kind:
		WakeKinds.PUMPKIN:
			if _roll and _roll.is_valid():
				return
			if not is_inside_tree():
				return
			_roll = create_tween()
			_roll.tween_property(_body, "rotation:x", -0.35, 0.12).set_trans(Tween.TRANS_SINE)
			_roll.tween_property(_body, "rotation:x", 0.2, 0.14).set_trans(Tween.TRANS_SINE)
			_roll.tween_property(_body, "rotation:x", 0.0, 0.16).set_trans(Tween.TRANS_BOUNCE)
		WakeKinds.SNOWMAN:
			var now := Time.get_ticks_msec()
			if now - _last_puff_ms < int(SNOW_PUFF_EVERY * 1000.0):
				return
			_last_puff_ms = now
			snow_puffs += 1
			if is_inside_tree():
				Fx.burst(get_tree().root, global_position + Vector3(0, 0.2, 0), Color("f4f8fc"), 10, 2.0, 0.08, 0.7, 2.0)


func is_rolling() -> bool:
	return _roll != null and _roll.is_valid()


## A pink flower with a yellow middle: one mesh for every cactus (WeaponModels' shared material).
static func _shared_flower() -> Mesh:
	if _flower_mesh == null:
		_flower_mesh = WeaponModels.build([
			[Vector3(0.18, 0.08, 0), Vector3(0.2, 0.1, 0.16), _FLOWER_PINK],
			[Vector3(-0.18, 0.08, 0), Vector3(0.2, 0.1, 0.16), _FLOWER_PINK],
			[Vector3(0, 0.08, 0.18), Vector3(0.16, 0.1, 0.2), _FLOWER_PINK],
			[Vector3(0, 0.08, -0.18), Vector3(0.16, 0.1, 0.2), _FLOWER_PINK],
			[Vector3(0, 0.1, 0), Vector3(0.18, 0.14, 0.18), _FLOWER_CENTRE],
		])
	return _flower_mesh

# --- M3 Task 21a: its babble voice ---

## How big the buddy sounds (BabbleRules.pitch): its tallest or widest side in blocks.
func voice_size() -> float:
	return float(maxi(size_blocks.x, maxi(size_blocks.y, size_blocks.z)))


# --- M3 Task 20b: buddy magic (secret shapes, tricks) ---
# A buddy whose blocks match a secret shape (BuddyRecipes) is special on every game, worked out from its blocks
# (so a save and a guest need nothing more): its recipe's traits (set before _build: a fairy floats, a lighthouse's
# bright light), its name tag in the recipe's colour, and now and then its own thing on every game by itself (the
# shared Fx material and Audio; nothing is sent): snowflakes, a beep, growing, a tune, a light sweeping, a bark and
# a fetch (the host moves it), a rainbow wiggle, twinkles. Tricks (TrickRules): the host counts its child's emotes
# near it (BuddyMagicDirector) and every game plays the move (do_trick); learned tricks are saved with it.

## How big a growing buddy may get (its look only: the collision box never grows, owner feedback #9).
const GROW_MAX := 2.0
const GROW_STEP := 0.1
const FETCH_AHEAD := 6.0          # a puppy buddy runs this far ahead of its child ...
const FETCH_TIME := 2.5           # ... for this long, then comes back
const ACT_SEEN := 48.0            # its sparkles only when this game's camera is this close
const SING_NOTES: Array[float] = [1.0, 1.26, 1.5, 2.0]

## The secret shape this buddy is (a BuddyRecipes id; &"" for a plain buddy).
var recipe: StringName = &""
## How many times it did its own thing on this game.
var acts := 0
## A growing buddy's size (its look).
var grown := 1.0
## Host: where a puppy buddy runs to fetch (INF: nowhere).
var fetch_target := Vector3.INF
## Host: its tricks (TrickRules state).
var trick_state := {}

var _act_t := 0.0
var _fetch_t := 0.0
var _light: OmniLight3D


func _t20b_setup() -> void:
	recipe = BuddyRecipes.match_blocks(blocks)
	var r := BuddyRecipes.recipe(recipe)
	if r.is_empty():
		return
	for k: String in r.traits:
		traits[k] = r.traits[k]
	_act_t = float(r.every) * (0.5 + 0.5 * float(absi(hash(name)) % 100) / 100.0)   # buddies don't all act at once


func _t20b_look() -> void:
	for c in get_children():
		if c is OmniLight3D:
			_light = c
	if recipe == &"":
		return
	_tag.modulate = BuddyRecipes.recipe(recipe).color
	_tag.outline_modulate = Color(0.12, 0.08, 0.22)


func _t20b_save(d: Dictionary) -> void:
	var learned := TrickRules.learned(trick_state)
	if not learned.is_empty():
		d.tricks = learned


## Host: its tricks from its save entry (WorldMeta.buddies).
func load_tricks(saved: Dictionary) -> void:
	trick_state = TrickRules.state_from(saved.get("tricks"))


## Host: one emote its child did near it (TrickRules.lesson).
func learn(emote: StringName) -> StringName:
	return TrickRules.lesson(trick_state, emote)


func _t20b_process(delta: float) -> void:
	if fetch_target.is_finite():
		_fetch_t -= delta
		if _fetch_t <= 0.0:
			fetch_target = Vector3.INF
	if recipe == &"":
		return
	_act_t -= delta
	if _act_t > 0.0:
		return
	var r := BuddyRecipes.recipe(recipe)
	_act_t = float(r.every)
	_act(r)


## Its own thing (every game by itself; the host also starts a puppy's fetch).
func _act(r: Dictionary) -> void:
	acts += 1
	var top := (global_position if is_inside_tree() else position) + Vector3(0, size_blocks.y * grown + 0.3, 0)
	Audio.play(r.sound, top, -10.0)
	var seen := _seen()
	var root: Node = get_tree().root if is_inside_tree() else null
	match r.act:
		BuddyRecipes.SNOW:
			if seen:
				Fx.burst(root, top + Vector3(0, 1.2, 0), Color("f4fbff"), 16, 1.4, 0.07, 2.4, 1.2, 80.0)
		BuddyRecipes.BEEP:
			wave()
		BuddyRecipes.GROW:
			grown = minf(grown + GROW_STEP, GROW_MAX)
			if not (_anim and _anim.is_valid()):
				_body.scale = Vector3.ONE * grown
			_tag.position.y = size_blocks.y * grown + 0.55
			if seen:
				Fx.burst(root, top, Color("ff9ec8"), 10, 2.0, 0.09, 1.0, 3.0)
		BuddyRecipes.SING:
			var tune := create_tween()
			for i in SING_NOTES.size():
				tune.tween_callback(_note.bind(SING_NOTES[i], i, seen))
				tune.tween_interval(0.28)
		BuddyRecipes.BEAM:
			if _light:
				var beam := create_tween()
				beam.tween_property(_light, "light_energy", float(traits.glow_energy) * 2.2, 0.4)
				beam.tween_property(_light, "light_energy", float(traits.glow_energy), 0.9)
			if seen:
				Fx.burst(root, top, r.color, 12, 3.0, 0.08, 0.8, 0.0)
		BuddyRecipes.BARK:
			cheer()
			if multiplayer.is_server():
				_fetch()
		BuddyRecipes.WIGGLE:
			wave()
			if seen:
				var colours: Array[Color] = [Color("e23b3b"), Color("ffd23f"), Color("3fae4b"), Color("3a7bff"), Color("9b4dff")]
				for i in colours.size():
					Fx.burst(root, top + Vector3(0, i * 0.15, 0), colours[i], 5, 2.0, 0.07, 0.7, 2.0)
		BuddyRecipes.SPARKLE:
			if seen:
				Fx.burst(root, top - Vector3(0, size_blocks.y * 0.5, 0), r.color, 12, 1.0, 0.06, 1.2, -0.5)


## Host: a puppy buddy runs past its child a little way (on from where it stands), then comes back (Buddy._goal).
func _fetch() -> void:
	var owner := _find_owner() if is_inside_tree() else null
	if owner == null or not owner.is_spawned():
		return
	var on := owner.global_position - global_position
	on.y = 0.0
	var ahead := on.normalized() if on.length() > 0.1 else Basis(Vector3.UP, rotation.y) * Vector3.FORWARD
	fetch_target = owner.global_position + ahead * FETCH_AHEAD
	_fetch_t = FETCH_TIME


## One note of a singing castle's tune.
func _note(pitch: float, i: int, seen: bool) -> void:
	if not is_inside_tree():
		return
	var top := global_position + Vector3(0, size_blocks.y * grown + 0.4, 0)
	Audio.play(&"chime", top, -12.0, pitch)
	if seen:
		Fx.burst(get_tree().root, top + Vector3(0.3 * (i - 1.5), 0.2 * i, 0), Color("ffd23f"), 4, 1.5, 0.08, 0.8, -1.0)


## Is it near this game's camera (so its sparkles are worth making)?
func _seen() -> bool:
	if not is_inside_tree():
		return false
	var cam := get_viewport().get_camera_3d()
	return cam != null and cam.global_position.distance_to(global_position) <= ACT_SEEN


## Every game: a trick (TrickRules move) its child just did with it.
func do_trick(move: StringName) -> void:
	if move == TrickRules.DANCE:
		dance()
		return
	if move == TrickRules.WAVE:
		wave()
		return
	if _anim and _anim.is_valid():
		_anim.kill()
	_anim = create_tween()
	match move:
		TrickRules.SPIN:
			_anim.tween_property(_body, "rotation:y", _body.rotation.y + TAU, 0.55).set_trans(Tween.TRANS_BACK)
			_anim.parallel().tween_property(_body, "position:y", 0.45, 0.25).set_trans(Tween.TRANS_QUAD)
			_anim.tween_property(_body, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_BOUNCE)
		TrickRules.HOP:
			for i in 2:
				_anim.tween_property(_body, "position:y", 0.4, 0.15).set_trans(Tween.TRANS_QUAD)
				_anim.tween_property(_body, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE)
		TrickRules.SIT:
			_anim.tween_property(_body, "position:y", -0.12, 0.2)
			_anim.parallel().tween_property(_body, "rotation:x", -0.15, 0.2)
			_anim.tween_interval(1.2)
			_anim.tween_property(_body, "position:y", 0.0, 0.25)
			_anim.parallel().tween_property(_body, "rotation:x", 0.0, 0.25)
		_:   # BOW
			_anim.tween_property(_body, "rotation:x", 0.4, 0.25)
			_anim.tween_interval(0.3)
			_anim.tween_property(_body, "rotation:x", 0.0, 0.3)
