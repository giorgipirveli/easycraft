class_name Player
extends CharacterBody3D
## The player: camera-relative movement, double/triple jump, physics modes (Normal/Fly/Ghost),
## the Physics Lab (Moon, Zero-G, Slow motion) and pads (LabRules, PadRules), swimming (SwimRules),
## auto-step onto 1-block ledges, and safe spawning/unstucking.

signal jumped(index: int)
signal physics_mode_changed(mode: int)
signal size_mode_changed(mode: int)
signal spawned

const WALK_SPEED := 6.0
const FLY_SPEED := 11.0
const GROUND_ACCEL := 45.0
const AIR_ACCEL := 18.0
const FLY_ACCEL := 60.0
const GRAVITY := 24.0
const JUMP_VELOCITY := 9.0
const AIR_JUMP_VELOCITY := 8.0
const AUTO_STEP_VELOCITY := 7.6
const WATER_SPEED_FACTOR := 0.5    # wading through knee-deep water
const WORLD_COLLISION_MASK := 1
const SPAWN_TIMEOUT := 10.0
const STEP_DISTANCE := 1.8
const CAMERA_HIDE_DISTANCE := 0.8

var world: WorldService
var physics_mode: int = PhysicsMode.Mode.NORMAL
## Developer: the autopilot flies this player (its 2 km flight ghosts through hills in every world, Survivor too).
var autopilot_ghost := false
var size_mode: int = SizeMagic.Mode.NORMAL
var is_local := true
## Universe 6: seconds this player still walks slowed by the Spore Mother's spore clouds (SporeMotherRules.SLOW).
var _slow_t := 0.0
var peer_id := 1

var _jumps := JumpCounter.new()
var _spawned := false
var _spawn_target := Vector3.ZERO     # exact saved position, or (x, NAN, z) for "surface at x,z"
var _spawn_pending := false
var _spawn_wait := 0.0
var _step_travel := 0.0
var _applied_size := SizeMagic.Mode.NORMAL
var _last_good_remote := Vector3.ZERO   # a remote body's last finite synced position
## Hearts (M2 §12.3). The host decides changes (Session.hurt_player) and sends them to everyone.
var health := Health.new()
## Collision is streamed only this far around a player (its own body, and animals, which are
## simulated within AnimalRules.ACTIVE_DISTANCE of a player). Building it out to the view distance,
## on the main thread, made 108-145 ms frames while flying (M1b acceptance on the emulator).
const COLLISION_DISTANCE := int(AnimalRules.ACTIVE_DISTANCE) + 16
## Owner #92: how far a host streams the world round a friend: never further than round itself (a weak phone host on
## LOW sees 64), at most REMOTE_VIEW.
const REMOTE_VIEW := 128

@onready var avatar: AvatarModel = $Avatar
@onready var rig: CameraRig = $CameraRig
@onready var viewer: VoxelViewer = $VoxelViewer


func _enter_tree() -> void:
	# Players are named after their peer id; that peer simulates (owns) this body.
	if name.is_valid_int():
		peer_id = name.to_int()
	set_multiplayer_authority(peer_id)
	_sync_held_item_property()
	_sync_water_state_property()
	_sync_task6_properties()   # M2 Task 6
	_sync_lab_mode_property()
	_sync_look_property()
	_sync_task5_properties()   # M2 Task 5: crouching
	_sync_progress_tag_property()   # M3 Task 12: level and title on the name tag
	_sync_gadget_properties()   # M3 Task 14a: the glider, the hook, the zipline
	_sync_flight_properties()   # owner #78: the flying machine the child invented


func _ready() -> void:
	# Each player gets its own capsule so resizing one never resizes the others.
	$Collision.shape = ($Collision.shape as Shape3D).duplicate()
	add_to_group(&"players")
	is_local = peer_id == multiplayer.get_unique_id()
	rig.set_target(self)
	rig.camera.current = is_local and not Vr.active()   # owner #101: in VR the headset's camera is the view
	if is_local:
		Vr.anchor(self, &"feet")   # owner #101: the headset stands at this player's feet (off VR: only remembered)
	visible = false
	if is_local or multiplayer.is_server():   # the host simulates animals near its guests too
		var ground := VoxelViewer.new()
		ground.name = "CollisionViewer"
		ground.view_distance = COLLISION_DISTANCE
		ground.requires_visuals = false
		ground.requires_collisions = true
		add_child(ground)
	if is_local:
		viewer.requires_collisions = false   # the view streams what you see; collision is close by
	else:
		rig.process_mode = Node.PROCESS_MODE_DISABLED
		get_node("BlockInteractor").process_mode = Node.PROCESS_MODE_DISABLED
		if multiplayer.is_server():
			# The host streams terrain around remote players and sends it to them.
			viewer.set_network_peer_id(peer_id)
			viewer.view_distance = remote_view_distance(Profile.data.settings)   # owner #92: a weak host's memory
			viewer.requires_data_block_notifications = true
			viewer.requires_visuals = false
			viewer.requires_collisions = false
			viewer.view_distance_vertical_ratio = GraphicsPreset.viewer_ratio(viewer.view_distance)
		else:
			viewer.queue_free()
	_setup_look()
	_setup_name_tag()   # M3 Task 12
	_add_vr_pose_link()   # owner #101 (P4): a VR player's pose to the games that ask
	Progress.counted.connect(_on_progress_counted)   # owner #94: a happy jump for a secret, a quest step...


## Spawn on the surface at column (x, z) once the terrain there is ready.
func spawn_on_surface(x: int, z: int) -> void:
	_spawn_target = Vector3(x + 0.5, NAN, z + 0.5)
	_begin_spawn()


## Spawn exactly at a saved position once the terrain there is ready.
func spawn_at(pos: Vector3) -> void:
	_spawn_target = pos
	_begin_spawn()


## Parks the (hidden, not simulated) player at the target right away, so its VoxelViewer streams
## the terrain there instead of around the origin.
func _begin_spawn() -> void:
	_spawn_pending = true
	_spawned = false
	_spawn_wait = 0.0
	velocity = Vector3.ZERO
	if is_local and rig.vr_mode():
		Vr.fade_out(0.0)   # owner #101: black until the body stands (the snap's blink fades it back in)
	if world:
		var surface := world.surface_height(floori(_spawn_target.x), floori(_spawn_target.z))
		var y := float(surface) if is_nan(_spawn_target.y) else _spawn_target.y
		global_position = Vector3(_spawn_target.x, y, _spawn_target.z)


func is_spawned() -> bool:
	return _spawned


## Where `p` is, or INF when it is gone, out of the tree (a guest's own player when the host quits: the M3 review)
## or not spawned yet. The panels' "where is my player" callbacks use it. Untyped on purpose: a freed player fails a
## `Player` argument's check before the body runs (the live relay test, 2026-09-25).
static func position_or_none(p: Variant) -> Vector3:
	if not is_instance_valid(p) or not (p is Player):
		return Vector3.INF
	var player: Player = p
	if not player.is_inside_tree() or not player.is_spawned():
		return Vector3.INF
	return player.global_position


func camera() -> Camera3D:
	return rig.camera


## Owner #101: the one aim of every world tap (blocks, animals, traders, doors, weapons, gadgets...): [origin, direction]
## through `screen_pos` from the camera, as before; in VR the pointing hand's laser (the screen point means nothing).
func aim_ray(screen_pos: Vector2) -> Array:
	if is_local and rig.vr_mode():
		var hand := Vr.pointer_ray()
		if not hand.is_empty():
			return hand
	var cam := camera()
	return [cam.project_ray_origin(screen_pos), cam.project_ray_normal(screen_pos)]


func eye_position() -> Vector3:
	return global_position + Vector3(0, CameraRig.HEAD_HEIGHT * size_scale(), 0)


func size_scale() -> float:
	return SizeMagic.scale(size_mode)


func set_size_mode(mode: int) -> void:
	var grew := SizeMagic.scale(mode) > SizeMagic.scale(size_mode)
	size_mode = mode
	_apply_size()
	if grew and physics_mode == PhysicsMode.Mode.NORMAL:
		_unstuck()
	size_mode_changed.emit(mode)


func cycle_size_mode() -> void:
	set_size_mode(SizeMagic.next(size_mode))


func _apply_size() -> void:
	_applied_size = size_mode
	var s := size_scale()
	avatar.scale = Vector3.ONE * s
	var capsule := $Collision.shape as CapsuleShape3D
	capsule.radius = PlacementRules.PLAYER_RADIUS * s
	capsule.height = SizeMagic.PLAYER_HEIGHT * s
	($Collision as Node3D).position.y = SizeMagic.PLAYER_HEIGHT * s * 0.5
	rig.set_size_scale(s)


func look_delta(delta_px: Vector2, sensitivity: float = CameraRig.TOUCH_SENSITIVITY) -> void:
	rig.look(delta_px, sensitivity)


func toggle_camera() -> void:
	rig.toggle_first_person()


## Owner #90: a game controller's right stick looks round (GamepadRules.look_step: smooth, at SETTINGS → HELP's speed).
## Its actions are only a pad's, and a menu that has the pad takes them out of the input map, so it never turns behind one.
func _pad_look(delta: float) -> void:
	if photo_mode or not InputMap.has_action(&"look_left"):
		return
	var stick := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down", 0.0)
	if stick != Vector2.ZERO:
		rig.look(GamepadRules.look_step(stick, delta, str(Profile.data.settings.get("pad_look", "normal"))), 1.0)


## Set by PhotoMode (M3 Task 16) while it looks at this player: the body is always in the picture.
var photo_mode := false


## Hide your own avatar when the camera is inside it: first person, or the spring arm squeezed
## against leaves and walls (never in photo mode).
func _process(delta: float) -> void:
	_ride_place()   # M3 Task 20a: a rider sits on its buddy's saddle (every game)
	if is_local:
		avatar.visible = not is_hiding() and (photo_mode or Vr.self_seen() \
			or (not rig.first_person and rig.arm.get_hit_length() > CAMERA_HIDE_DISTANCE * size_scale()))
		_pad_look(delta)   # owner #90
	_vr_pose_frame()   # owner #101 (P4): the headset's pose out, a VR friend's body in
	_update_held_item()
	_update_potion_look()   # M2 Task 6
	_update_stealth_look()  # M2 Task 5
	_update_gadget_look()   # M3 Task 14a
	_update_flight_look()   # owner #78


func set_physics_mode(mode: int) -> void:
	if mode == PhysicsMode.Mode.GHOST and not Game.allows(ModeRules.GHOST) and not autopilot_ghost:
		mode = PhysicsMode.Mode.NORMAL   # Survivor has no Ghost mode (M2 §12.1)
	if mode == PhysicsMode.Mode.FLY and is_local and physics_mode == PhysicsMode.Mode.NORMAL \
			and Game.allows(ModeRules.FLYING) and _take_off_craft() == FlightCrafts.Craft.KITE:
		_kite_take_off()   # owner #78: a kite lifts you for a moment on a windy hill; it never flies you
		physics_mode_changed.emit(physics_mode)
		return
	if mode == PhysicsMode.Mode.FLY and not _may_take_off():
		mode = PhysicsMode.Mode.NORMAL   # Survivor flying costs gold (M2 Task 7) and needs an invention (owner #78)
	var was := physics_mode
	physics_mode = mode
	_follow_flight_craft(mode)   # owner #78: in the machine while flying, out of it otherwise
	collision_mask = WORLD_COLLISION_MASK if PhysicsMode.has_collision(mode) else 0
	velocity.y = 0.0
	_climb_to = NAN
	_lift_left = 0.0
	if mode == PhysicsMode.Mode.NORMAL and was != PhysicsMode.Mode.NORMAL:
		_unstuck()
		_jumps.reset()
	physics_mode_changed.emit(mode)
	_follow_physics_mode(mode)


## Streaming distance: horizontal view distance, and a vertical box that starts a little below
## the feet (GraphicsPreset.vertical_range), so the deep underground is only streamed when near.
## How far the host streams round a friend's player (owner #92).
static func remote_view_distance(settings: Dictionary) -> int:
	return mini(REMOTE_VIEW, GraphicsPreset.view_distance(settings))


func set_view_distance(view_distance: int) -> void:
	var view := GraphicsPreset.clamp_view_distance(view_distance)
	viewer.view_distance = view
	viewer.view_distance_vertical_ratio = GraphicsPreset.viewer_ratio(view)


## Keeps the streamed box around `at` (feet): from a little under the feet or the ground below,
## whichever is lower (GraphicsPreset.vertical_range).
func _place_viewer(at: Vector3) -> void:
	var ground := maxi(world.surface_height(floori(at.x), floori(at.z)), MeadowsShape.SEA_LEVEL)
	viewer.global_position = Vector3(at.x, GraphicsPreset.viewer_y(at.y, ground, viewer.view_distance), at.z)


## Host: hearts come back after a quiet moment (M2 §12.3); every change is sent to everyone.
func tick_health(delta: float) -> void:
	var before := health.hp
	health.tick(delta)
	if health.hp != before:
		Session.broadcast_health(peer_id, health.hp)
		Session.player_hurt.emit(peer_id, health.hp, Vector3.INF)


## 2 = double jump, 3 = triple jump (the player's setting).
func set_max_jumps(n: int) -> void:
	_jumps.max_jumps = clampi(n, JumpCounter.MIN_JUMPS, JumpCounter.MAX_JUMPS)


func cycle_physics_mode() -> void:
	set_physics_mode(PhysicsMode.next(physics_mode, Game.allows(ModeRules.GHOST)))


func _physics_process(delta: float) -> void:
	potions.tick(delta)   # M2 Task 6: on every game, for every player
	_slow_t = maxf(_slow_t - delta, 0.0)   # universe 6: a spore cloud's slow wears off
	if multiplayer.is_server():
		tick_health(delta)
	if not is_multiplayer_authority():
		_update_remote(delta)
		return
	if not _spawned:
		_try_spawn(delta)
		return
	if sleeping:
		_sleep_tick(delta)
		return
	if knocked_out:
		_knocked_out_tick(delta)
		return
	if is_riding():   # M3 Task 20a: the stick steers the buddy (the host moves it)
		_ride_tick(delta)
		return
	if _stealth_tick():   # M2 Task 5: inside a barrel or closet the body holds still; C crouches
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_simple_follow(input, delta)   # M3 Task 21a: Simple controls' camera follows behind
	var dir := Basis(Vector3.UP, _walk_yaw()) * Vector3(input.x, 0.0, input.y)
	water_state = SwimRules.water_state(global_position, size_scale(), world.get_block)
	var body_delta := LabRules.body_delta(lab_mode, delta)   # the body's own time (Physics Lab slow motion)
	_jump_taps_step(delta)   # owner #54: two quick taps on JUMP take off flying (the Sandbox)
	if _gadget_step(body_delta, dir):   # M3 Task 14a: gliding, pulled by the hook or riding a zipline
		pass
	elif lab_mode == LabRules.Mode.ZERO_G:
		_move_zero_g(body_delta, dir)
	elif physics_mode == PhysicsMode.Mode.NORMAL:
		_move_normal(body_delta, dir)
	else:
		_move_flying(body_delta, dir)
	_lab_move_and_slide(body_delta)
	_vr_room_scale()   # owner #101: a child who steps in the room walks the body after the head
	_place_viewer(global_position)
	_void_step(delta)   # owner 39: the Dragon Realm's void carries a faller back
	if SpawnRules.has_fallen(global_position.y):
		_rescue_to_surface()
	_update_avatar(body_delta, dir)
	_water_effects(body_delta)


func _move_normal(delta: float, dir: Vector3) -> void:
	_soft_fall_step()
	if not is_nan(_climb_to):
		_climb(delta, dir)
		return
	if water_state >= SwimRules.State.SWIMMING:
		_swim(delta, dir)
		return
	var wading := water_state == SwimRules.State.WADING
	var speed := WALK_SPEED * SizeMagic.walk_speed_factor(size_mode) * (WATER_SPEED_FACTOR if wading else 1.0) \
		* potions.speed_factor() * (StealthRules.CROUCH_SPEED if crouching else 1.0) \
		* (SporeMotherRules.SLOW if _slow_t > 0.0 else 1.0)   # universe 6: in a spore cloud
	var accel := GROUND_ACCEL * FrostRules.grip_at(global_position, world.get_block) if is_on_floor() else AIR_ACCEL   # M3 Task 3: ice slides
	velocity.x = move_toward(velocity.x, dir.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, dir.z * speed, accel * delta)
	if Input.is_action_just_pressed("jump"):
		_jumps.press_jump()
	if _jumps.tick(delta, is_on_floor()):
		var index := _jumps.jumps_used
		velocity.y = (JUMP_VELOCITY if index == 1 else AIR_JUMP_VELOCITY) * SizeMagic.jump_factor(size_mode) \
			* potions.jump_velocity_factor()
		jumped.emit(index)
		avatar.play_jump(index)
		Audio.play(&"jump" if index == 1 else &"air_jump", global_position)
		if index > 1:
			Fx.jump_puff(world, global_position)
	elif not is_on_floor():
		velocity.y -= GRAVITY * LabRules.gravity_factor(lab_mode) * delta
	_kite_step(delta)   # owner #78: the kite's pull, then its gentle way down
	_auto_step(dir)


func _move_flying(delta: float, dir: Vector3) -> void:
	var vertical := Input.get_axis("fly_down", "fly_up")
	if Input.is_action_pressed("jump") or _lift_left > 0.0:   # owner #54, #75: the taps' take-off and each tap lift
		vertical = 1.0
	_lift_left = maxf(_lift_left - delta, 0.0)
	if FlightCrafts.flies(flight_craft):   # owner #78: the balloon, the plane or the jet the child invented
		velocity = FlightCrafts.step(flight_craft, velocity, dir, vertical, wind, is_on_floor(), delta)
		return
	var fly_speed := FLY_SPEED * SizeMagic.walk_speed_factor(size_mode)
	var target := dir * fly_speed + Vector3.UP * vertical * fly_speed * 0.8
	velocity = velocity.move_toward(target, FLY_ACCEL * delta)


## Walking into a 1-block ledge with head room hops onto it (like auto-jump on mobile), at any size
## but Tiny: the probe and the head room grow with the body (StepRules).
func _auto_step(dir: Vector3) -> void:
	if not is_on_floor() or dir.length() < 0.3 or size_mode == SizeMagic.Mode.TINY:
		return
	if SimpleControls.auto_jump(simple_controls(), global_position, dir, body_radius(),   # M3 Task 21a: + gaps
			SizeMagic.clearance_blocks(size_mode), _is_solid):
		velocity.y = LabRules.step_velocity(AUTO_STEP_VELOCITY, LabRules.gravity_factor(lab_mode)) \
			* SizeMagic.jump_factor(size_mode)   # cosmos: a gentle hop in very low gravity (Europa)


## The footstep for the block under the feet (FootstepRules; wet feet wade).
func step_sound() -> StringName:
	var under := world.get_block(Vector3i((global_position + Vector3(0, -0.2, 0)).floor())) if world else BlockIds.GRASS
	return FootstepRules.sound(under, _water_fx.wet_feet())


func body_radius() -> float:
	return PlacementRules.PLAYER_RADIUS * size_scale()


func _is_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(world.get_block(cell))


func _update_avatar(delta: float, dir: Vector3) -> void:
	var flat := Vector2(velocity.x, velocity.z)
	if is_on_floor() and physics_mode == PhysicsMode.Mode.NORMAL and water_state < SwimRules.State.SWIMMING:
		_step_travel += flat.length() * delta
		if _step_travel >= STEP_DISTANCE:
			_step_travel = 0.0
			Audio.play(step_sound(), global_position, -6.0)   # the audio pass: by the block under the feet
	if rig.first_person or rig.vr_mode():   # owner #101: friends see a VR child's avatar face where its head looks
		avatar.rotation.y = rig.yaw
	elif dir.length() > 0.1:
		avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(-dir.x, -dir.z), clampf(12.0 * delta, 0.0, 1.0))
	if _show_swim_pose():
		avatar.swim(flat.length(), velocity.y, delta)
	else:
		avatar.animate(flat.length(), is_on_floor() or physics_mode != PhysicsMode.Mode.NORMAL, delta)
	_idle_tick(delta, flat.length(), is_on_floor() or physics_mode != PhysicsMode.Mode.NORMAL)   # owner #94


## Remote players are moved by the synchronizer; only animate them.
func _update_remote(delta: float) -> void:
	visible = true
	_spawned = true
	lab_mode = LabRules.valid(lab_mode)             # synced over LAN: a tampered value is Normal
	delta = LabRules.body_delta(lab_mode, delta)    # a slow-motion player moves slowly here too
	# Synced over LAN: a tampered NaN would spread into reach checks, pets and the host's save.
	if position.is_finite():
		_last_good_remote = position
	else:
		position = _last_good_remote
	if not velocity.is_finite():
		velocity = Vector3.ZERO
	if not avatar.rotation.is_finite():
		avatar.rotation = Vector3.ZERO
	water_state = clampi(water_state, SwimRules.State.DRY, SwimRules.State.DIVING)
	if multiplayer.is_server() and is_instance_valid(viewer) and world:
		_place_viewer(global_position)   # the host streams terrain to this client
	if _applied_size != size_mode:
		_apply_size()
	if _show_swim_pose():
		avatar.swim(Vector2(velocity.x, velocity.z).length(), velocity.y, delta)
	else:
		avatar.animate(Vector2(velocity.x, velocity.z).length(), absf(velocity.y) < 0.5, delta)
	_idle_tick(delta, Vector2(velocity.x, velocity.z).length(), absf(velocity.y) < 0.5)   # owner #94
	_water_effects(delta)


func _try_spawn(delta: float) -> void:
	if world == null or not _spawn_pending:
		return
	_spawn_wait += delta
	var probe := _spawn_target
	var surface := world.surface_height(floori(probe.x), floori(probe.z))
	probe.y = surface if is_nan(probe.y) else SpawnRules.readiness_probe_y(probe.y, surface)
	# Stream around the ground we wait for, which can lie far below a mid-air save.
	_place_viewer(probe)
	if not world.is_area_ready(probe) and _spawn_wait < SPAWN_TIMEOUT:
		return
	if is_nan(_spawn_target.y):
		var x := floori(_spawn_target.x)
		var z := floori(_spawn_target.z)
		global_position = Vector3(_spawn_target.x, SpawnRules.spawn_y(world.find_standing_y(x, z)), _spawn_target.z)
	else:
		global_position = _spawn_target
		if physics_mode == PhysicsMode.Mode.NORMAL:
			_unstuck()
	velocity = Vector3.ZERO
	_spawned = true
	_spawn_pending = false
	_spawn_wait = 0.0
	visible = true
	rig.snap_to_target()
	spawned.emit()


## If any part of the body is inside blocks, move up to the first spot with room for the whole
## footprint (a giant stands on up to 3 x 3 columns).
func _unstuck() -> void:
	var feet := floori(global_position.y + 0.01)
	var free := StepRules.first_free_y(global_position, body_radius(), SizeMagic.clearance_blocks(size_mode), WorldService.MAX_Y, _is_solid)
	if free != feet:
		global_position.y = SpawnRules.spawn_y(free)
		velocity = Vector3.ZERO


func _rescue_to_surface() -> void:
	if physics_mode == PhysicsMode.Mode.NORMAL:
		go_home()   # fell out of the world: back to bed, or to the world spawn
		return
	var x := floori(global_position.x)
	var z := floori(global_position.z)
	global_position.y = SpawnRules.spawn_y(world.find_standing_y(x, z))
	velocity = Vector3.ZERO
	rig.snap_to_target()


# --- Sleeping and home (M1b Task 10) ----------------------------------------------------------

const SLEEP_OFFSET := Vector3(0, 0, -0.45)   # lying avatar: centred on the mattress, head on the pillow (+Z)
const ZZZ_EVERY := 0.8
const WAKE_NEAR := 1.0   # a wake only steps off the bed if still on it (not after /tp)
const ZZZ_RISE_TIME := 1.6

## Set on every peer by SleepDirector when the host says so.
var sleeping := false
var sleep_bed := Vector3i.ZERO
## The bed this player last slept in; the host clears it when that bed breaks.
var has_home := false
var home_bed := Vector3i.ZERO

var _zzz: Tween


## Lies down in the bed at `bed` (on its top, the head on the pillow at +Z), or gets up. The avatar
## model owns the lying pose (AvatarModel.set_pose, both styles); here it only faces the pillow.
## "Z"s float up while asleep. The owner's body rests on the mattress and holds still.
func set_sleeping(asleep: bool, bed: Vector3i) -> void:
	if is_local and rig.vr_mode() and asleep != sleeping:
		_vr_sleep_fade(asleep)   # owner #101: a slow fade to night-black and back, never lying flat
	sleeping = asleep
	sleep_bed = bed
	avatar.rotation = Vector3.ZERO if asleep else Vector3(0.0, avatar.rotation.y, 0.0)
	avatar.position = SLEEP_OFFSET * size_scale() if asleep else Vector3.ZERO
	avatar.set_pose(AvatarModel.POSE_SLEEP if asleep else AvatarModel.POSE_STAND)
	if _zzz and _zzz.is_valid():
		_zzz.kill()
	if asleep:
		_zzz = create_tween().set_loops()
		_zzz.tween_callback(_puff_z)
		_zzz.tween_interval(ZZZ_EVERY)
	if is_local and asleep:
		velocity = Vector3.ZERO
		global_position = BedRules.lie_position(bed)
	elif is_local and world and global_position.distance_to(BedRules.lie_position(bed)) < WAKE_NEAR:
		global_position = BedRules.wake_position(bed, world.get_block)   # never head-first into a low ceiling


func set_home(on: bool, bed: Vector3i) -> void:
	has_home = on
	home_bed = bed


## Back home: to the bed this player last slept in, or the world spawn without one (falling out
## of the world, /home). A bed too far away to see yet is checked on arrival.
func go_home() -> void:
	if world == null:
		return
	var bed_id := BedRules.UNLOADED
	if has_home and world.is_editable(home_bed):
		bed_id = world.get_block(home_bed)
	if has_home and bed_id == BedRules.UNLOADED and not spawned.is_connected(_check_home_bed):
		spawned.connect(_check_home_bed, CONNECT_ONE_SHOT)
	spawn_at(BedRules.home_target(has_home, home_bed, bed_id, world.spawn_column(), world.get_block))


## On arrival at a bed that was too far away to see: it may be gone, or have no room above it now.
func _check_home_bed() -> void:
	if not has_home:
		return
	if world.get_block(home_bed) != BlockIds.BED:
		has_home = false
		go_home()
	else:
		global_position = BedRules.home_target(true, home_bed, BlockIds.BED, world.spawn_column(), world.get_block)


func _sleep_tick(delta: float) -> void:
	velocity = Vector3.ZERO
	avatar.animate(0.0, true, delta)


func _puff_z() -> void:
	var s := size_scale()
	var z := Label3D.new()
	z.text = "Z"
	z.font_size = 64
	z.pixel_size = 0.006 * s
	z.outline_size = 12
	z.modulate = Color(0.85, 0.92, 1.0)
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.position = Vector3(0.15, 0.75, 0.3) * s
	add_child(z)
	var rise := z.create_tween().set_parallel()
	rise.tween_property(z, "position", z.position + Vector3(0.35, 1.1, 0.0) * s, ZZZ_RISE_TIME)
	rise.tween_property(z, "modulate:a", 0.0, ZZZ_RISE_TIME).set_ease(Tween.EASE_IN)
	rise.chain().tween_callback(z.queue_free)

# --- Avatar style (M1b Task 13) -----------------------------------------------------------------

## This device's graphics style for this player's body: the blocky avatar, or a real-looking person
## in the REALISTIC style (blocky when that asset is missing, never an invisible player). The new
## model keeps the name "Avatar" (Sync replicates Avatar:rotation), visibility, facing and size.
func set_avatar_style(style: String) -> void:
	var realistic := style == "realistic" and RealisticAvatar.load_model() != null
	if (avatar is RealisticAvatar) == realistic:
		return
	var next: AvatarModel
	if realistic:
		var person := RealisticAvatar.new()
		person.skin_index = RealisticAvatar.skin_for(peer_id)
		next = person
	else:
		next = BlockyAvatar.new()
	if look_code != "":
		next.apply_look(AvatarLook.from_code(look_code))   # M3 Task 9: the same look in either style
	var old := avatar
	var index := old.get_index()
	next.transform = old.transform
	next.visible = old.visible
	if _held and _held.get_parent():   # the held weapon must not go down with the old body
		_held.get_parent().remove_child(_held)
	remove_child(old)
	old.queue_free()
	next.name = "Avatar"
	add_child(next)
	move_child(next, index)
	avatar = next
	if old.pose != AvatarModel.POSE_STAND:
		avatar.set_pose(old.pose)
	_update_held_item()

# --- Weapons (M1b Task 11) ---

## The weapon or tool in this player's hand (0 = none), synced to everyone so they see it.
var held_item := 0
var _held: HeldItem


## Adds held_item to the player's MultiplayerSynchronizer (once: the config is shared by all
## players, and every peer runs this before the synchronizer starts).
func _sync_held_item_property() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:held_item")
	if cfg and not cfg.has_property(path):
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


## Keeps the model in the avatar's hand in step with held_item (hidden while its boomerang flies).
func _update_held_item() -> void:
	var hand: Node3D = _held_item_hand()   # owner #101 (P4): in VR, the hand
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
	_held.thrown = (held_item == ItemIds.BOOMERANG and _boomerang_flying()) \
		or (WeaponRules.base_of(held_item) == ItemIds.SPEAR and spear_out())


func _boomerang_flying() -> bool:
	for b in get_tree().get_nodes_in_group(&"boomerangs"):
		if b is Boomerang and (b as Boomerang).shooter == peer_id and not b.is_queued_for_deletion():
			return true
	return false


## Plays an attack: the held item swings; an avatar with its own arm poses swings its arm too.
func play_attack(weapon_id: int, combo: int = 0) -> void:
	avatar.stop_emote(true)   # the swing takes over the body (M3 Task 9)
	var arm := avatar.has_method(&"play_attack")
	if arm:
		avatar.call(&"play_attack", weapon_id, combo)
	if _held:
		_held.play_attack(weapon_id, combo, arm)


## Bow drawn or relaxed.
func set_aiming(on: bool) -> void:
	var arm := avatar.has_method(&"set_aiming")
	if arm:
		avatar.call(&"set_aiming", on)
	if _held:
		_held.set_aiming(on, arm)


## A push from a hit (never damage). Only this player's own game moves its body.
func knockback(impulse: Vector3) -> void:
	if rig.vr_mode():
		return   # owner #101 (the plan's ruling 3): no knockback on a VR body (the hit is a buzz and a red tint)
	if is_multiplayer_authority() and _spawned:
		velocity += impulse

# --- Real water: swimming and water effects (M2 Task 14, owner feedback #17) --------------------

## The swim pose started or ended (the HUD shows UP and DOWN while swimming).
signal swimming_changed(on: bool)

## Where this body is in the water (SwimRules.State). Its own game decides it every physics frame; it
## is synced, so every game shows the same swim pose and effects.
var water_state: int = SwimRules.State.DRY

var _swimming := false
var _climb_to := NAN          # the bank's top being climbed onto (feet height), NAN when not climbing
var _climb_t := 0.0
var _climb_dir := Vector3.ZERO  # the flat way to the bank being climbed (owner feedback #30)
var _water_fx := SwimEffects.new()
var _bubble_count := 0
var _leap_coast := 0.0         # cosmos: a leap out of Titan's methane leaves it unbraked this long (TitanRules)
var _leap_cool := 0.0          # ... and the next one waits this long in it


## Adds water_state to the player's MultiplayerSynchronizer (once, like held_item).
func _sync_water_state_property() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:water_state")
	if cfg and not cfg.has_property(path):
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


## Swimming never walks on the bottom: glide at swim speed where the camera looks (look down and push
## forward to dive), JUMP swims up, DOWN (or crouch) dives, and otherwise the body floats with its
## head out (SwimRules). Pushing against a bank at most 1 block above the water climbs out.
func _swim(delta: float, dir: Vector3) -> void:
	_jumps.reset()
	var s := size_scale()
	var k := SizeMagic.walk_speed_factor(size_mode)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var target := SwimRules.swim_velocity(input, rig.yaw, rig.pitch, SwimRules.SWIM_SPEED * k)
	velocity.x = move_toward(velocity.x, target.x, SwimRules.SWIM_ACCEL * k * delta)
	velocity.z = move_toward(velocity.z, target.z, SwimRules.SWIM_ACCEL * k * delta)
	var surface := SwimRules.surface_y(global_position, world.get_block)
	var up := Input.is_action_pressed("jump")
	var down := Input.is_action_pressed("fly_down") or (InputMap.has_action(&"crouch") and Input.is_action_pressed(&"crouch"))
	# Owner feedback #30: a bank in reach (felt from BANK_DEPTH) is climbed near the surface; deeper, a
	# push into it never dives (with the view tilted down, the swimmer sank to a river's bottom against
	# the bank and stayed there): the body floats up to it instead.
	var look := Basis(Vector3.UP, rig.yaw) * Vector3.FORWARD
	var clearance := SizeMagic.clearance_blocks(size_mode)
	var bank := SwimRules.climb_out(global_position, dir, up, down, look, body_radius(), clearance, surface, s,
		_is_solid, SwimRules.BANK_DEPTH)
	var look_vy := target.y
	if not bank.is_empty():
		look_vy = maxf(look_vy, 0.0)
		if surface - global_position.y <= (SwimRules.FLOAT_DEPTH + SwimRules.AT_SURFACE) * s:
			_climb_to = float(bank.top)
			_climb_dir = bank.dir
			_climb_t = 0.0
	# Cosmos: Titan's methane is very floaty (TitanRules): JUMP at the surface leaps out like a dolphin.
	_leap_coast = maxf(_leap_coast - delta, 0.0)
	_leap_cool = maxf(_leap_cool - delta, 0.0)
	if bank.is_empty() and TitanRules.leaps(_floaty_liquid(), up, surface - global_position.y, s, _leap_cool):
		velocity.y = TitanRules.leap_speed(JUMP_VELOCITY) * SizeMagic.jump_factor(size_mode)
		_leap_coast = TitanRules.LEAP_COAST
		_leap_cool = TitanRules.LEAP_COOLDOWN
		Audio.play(&"splash_small", global_position, -4.0)
		return
	if _leap_coast > 0.0:
		return   # the methane lets the leap go
	var vy := SwimRules.vertical_target(surface - global_position.y, s, k, up, down, look_vy)
	velocity.y = SwimRules.vertical_velocity(velocity.y, vy, delta)


## Cosmos: this world's liquid is Titan's floaty methane (its descriptor's `liquid`, TitanRules).
func _floaty_liquid() -> bool:
	var d: Object = world.descriptor() if world else null
	return d != null and TitanRules.floaty(d.get("liquid"))


## Climbing out: up the bank's side towards it, a little above its top, then a step carries the body
## onto it. Owner feedback #30: a climb once started finishes (a quick tap of UP is enough); only
## pushing away from the bank (or a stuck climb) drops back into the water.
func _climb(delta: float, dir: Vector3) -> void:
	_climb_t += delta
	var k := SizeMagic.walk_speed_factor(size_mode)
	var away := dir.length() >= 0.3 and dir.normalized().dot(_climb_dir) < -0.3
	if away or _climb_t > SwimRules.CLIMB_TIMEOUT:
		_climb_to = NAN
		velocity.y = minf(velocity.y, 0.0)
		return
	if global_position.y >= _climb_to + SwimRules.CLIMB_OVER * size_scale():
		_climb_to = NAN
		var step := _climb_dir * SwimRules.CLIMB_STEP * k
		velocity = Vector3(step.x, 0.0, step.z)
		return
	var toward := dir.normalized() if dir.length() >= 0.3 else _climb_dir
	var push := toward * SwimRules.CLIMB_PUSH * k
	velocity = Vector3(push.x, SwimRules.CLIMB_SPEED * SizeMagic.jump_factor(size_mode), push.z)


## Puts the avatar in the swim pose, or back on its feet, as the (synced) water state changes, in
## every game. True while it swims.
func _show_swim_pose() -> bool:
	var on := SwimRules.swim_pose(physics_mode, water_state, sleeping)
	if not sleeping:
		var want := AvatarModel.POSE_SWIM if on else AvatarModel.POSE_STAND
		if avatar.pose != want:
			avatar.set_pose(want)
	if on != _swimming:
		_swimming = on
		swimming_changed.emit(on)
	return on


## Splashes, ripples, bubbles, drips and swim sounds, in every game (SwimEffects decides when). Each
## is one small burst with the shared particle material (Fx).
func _water_effects(delta: float) -> void:
	if world == null:
		return
	var s := size_scale()
	for e: StringName in _water_fx.update(delta, water_state, velocity):
		match e:
			&"splash":
				var strength := _water_fx.splash
				Fx.splash(world, _on_surface(), strength, s)
				Audio.play(&"splash" if strength >= 0.5 else &"splash_small", global_position, lerpf(-12.0, 0.0, strength))
			&"ripple":
				Fx.ripple(world, _on_surface(), s)
			&"bubbles":
				Fx.bubbles(world, eye_position(), s)
				_bubble_count += 1
				if _bubble_count % 3 == 1:
					Audio.play(&"bubbles", eye_position(), -10.0)
			&"drips":
				Fx.drips(self, SwimEffects.DRIP_TIME, s)
			&"stroke":
				Audio.play(&"swim", global_position, -8.0)
				if water_state == SwimRules.State.SWIMMING:   # a few drops fly from the stroke
					Fx.splash(world, _on_surface() - avatar.global_basis.z.normalized() * 0.6 * s, 0.1, s, false)


## The water's surface where this body is.
func _on_surface() -> Vector3:
	return Vector3(global_position.x, SwimRules.surface_y(global_position, world.get_block), global_position.z)

# --- Knock-outs (M2 Task 2) ---------------------------------------------------------------------

const POP_UP_VELOCITY := 6.0   # Sandbox: the little hop back onto your feet

## Set on every peer by KnockoutDirector when the host says so: the avatar lies down, and this
## player's own body holds still (it still falls to the ground) until the host revives it.
var knocked_out := false


func set_knocked_out(on: bool) -> void:
	knocked_out = on
	if is_local and rig.vr_mode():
		Vr.set_dim(VrRules.KNOCKOUT_DIM if on else 0.0)   # owner #101: the view dims; the head is never laid down
	if not sleeping:
		avatar.set_pose(AvatarModel.POSE_SLEEP if on else AvatarModel.POSE_STAND)
	if on and is_multiplayer_authority():
		velocity = Vector3(0.0, minf(velocity.y, 0.0), 0.0)


## Sandbox knock-out: back on your feet right where you were, with a little hop.
func pop_up() -> void:
	if physics_mode == PhysicsMode.Mode.NORMAL:
		_unstuck()
		velocity = Vector3(0.0, POP_UP_VELOCITY, 0.0)


func _knocked_out_tick(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if physics_mode == PhysicsMode.Mode.NORMAL and not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	avatar.animate(0.0, true, delta)

# --- M2 Task 7: flying costs gold in Survivor ------------------------------------------------------

const SOFT_FALL_SPEED := 4.0   # m/s: landing out of gold drifts down instead of dropping

var _soft_fall := false


## This player's own game refuses FLY without gold for the first 6 s (Sandbox flies free); the host
## charges the rest while flying (Session.fly_tick).
func _may_take_off() -> bool:
	if not Game.allows(ModeRules.FLYING):   # Monster Wave (spec §12.20): stay on the ground
		if is_local:
			Session.magic_feedback.emit(ArenaRules.NO_FLYING_WORDS)
		return false
	if not is_local:
		return true
	var free := Game.allows(ModeRules.FREE_FLY)
	var craft := _take_off_craft()
	var why := InventionRules.fly_refusal(free, Profile.data.inventions, craft, InventionRules.air(Game.universe))
	if why != "":   # owner #78: Survivor flies what the child invented; wings and balloons need air
		Session.magic_feedback.emit(why)
		return false
	if InventionRules.can_pay_take_off(free, craft, Profile.data.survivor_gold, Game.universe):
		return true
	Session.magic_feedback.emit(InventionRules.fuel_words(craft, Game.universe))   # M3 Task 5: the universe's price
	return false


## Out of gold in the air (the host says so): back to walking, drifting down gently.
func land_gently() -> void:
	if physics_mode == PhysicsMode.Mode.NORMAL:
		return
	set_physics_mode(PhysicsMode.Mode.NORMAL)
	_soft_fall = true


func soft_falling() -> bool:
	return _soft_fall


func _soft_fall_step() -> void:
	if not _soft_fall:
		return
	if is_on_floor() or water_state != SwimRules.State.DRY:
		_soft_fall = false
	else:
		velocity.y = maxf(velocity.y, -SOFT_FALL_SPEED)

# --- M2 Task 6: potions, shields, the spear in flight, the invisible look -------------------------

## Potions working on this player. Every game runs them (the host decided the drink,
## Session.request_drink): the owner's game moves faster or jumps higher, the host's monsters
## (stealth, Task 5) read is_invisible(), and everyone sees the see-through look.
var potions := PotionRules.Effects.new()
## The best shield this player carries in Sandbox (from its hotbar; synced). Survivor's shield comes
## from the inventory on the host (Session.best_shield_of).
var carried_shield := 0
## When this player's invisibility ends, in this game's Time.get_ticks_msec() / 1000.0 seconds; 0 when
## not invisible. (The potion itself counts down with the game, so a paused game keeps it.)
var invisible_until: float:
	get:
		if not potions.is_invisible():
			return 0.0
		return Time.get_ticks_msec() / 1000.0 + potions.time_left(ItemIds.POTION_INVIS)
var _ghost_avatar: Node

static var _ghost_material: StandardMaterial3D


func is_invisible() -> bool:
	return potions.is_invisible()


## Starts a potion on this player (on every game, once the host said so); false if it is not a
## potion or is still working.
func drink(potion_id: int) -> bool:
	if not potions.start(potion_id):
		return false
	_drink_fx(potion_id)
	return true


## A LAN guest's game: the host says this player's potion has `seconds` left (it just drank it, or
## this game joined while it was working). The host's word wins over this game's own timer.
func sync_potion(potion_id: int, seconds: float) -> bool:
	if not PotionRules.is_potion(potion_id):
		return false
	var was := potions.is_active(potion_id)
	potions.set_left(potion_id, seconds)
	if not was and potions.is_active(potion_id):
		_drink_fx(potion_id)
	return true


func _drink_fx(potion_id: int) -> void:
	var s := size_scale()
	Fx.burst(get_tree().root, global_position + Vector3(0, 1.3 * s, 0), PotionRules.color(potion_id), 16, 2.5, 0.1, 0.9, -3.0)
	Audio.play(&"ding", global_position, -6.0)


## Is this player's thrown spear still out there (so the hand is empty)?
func spear_out() -> bool:
	for n in get_tree().get_nodes_in_group(&"spears"):
		if n.get(&"shooter") == peer_id and not n.is_queued_for_deletion():
			return true
	return false


## The see-through look of an invisible player (Invisibility potion): one shared material for every
## part of every invisible player and their held item.
static func ghost_material() -> StandardMaterial3D:
	if _ghost_material == null:
		_ghost_material = StandardMaterial3D.new()
		_ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_ghost_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_ghost_material.albedo_color = Color(0.78, 0.9, 1.0, 0.28)
	return _ghost_material


## Puts the ghost look on (or takes it off) when invisibility starts or ends, or the avatar changed.
func _update_potion_look() -> void:
	var want: Node = avatar if potions.is_invisible() else null
	if want == _ghost_avatar:
		return
	if is_instance_valid(_ghost_avatar):
		_set_ghost(_ghost_avatar, false)
	if want:
		_set_ghost(want, true)
	_ghost_avatar = want
	if _held:
		_held.ghost = want != null


static func _set_ghost(node: Node, on: bool) -> void:
	for g in node.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).material_override = ghost_material() if on else null


## Adds carried_shield to the synchronizer, like held_item.
func _sync_task6_properties() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:carried_shield")
	if cfg and not cfg.has_property(path):
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)

# --- Physics Lab and pads (M3 Task 6, spec §14.3) -------------------------------------------------

## The lab mode changed (the HUD shows Moon, Zero-G and Slow motion on the WALK button and lights LAB).
signal lab_mode_changed(mode: int)

## The Physics Lab's mode (LabRules), on top of the physics switch: Moon gravity and Slow motion walk
## (physics_mode NORMAL), Zero-G floats (FLY). This player's own game sets it; it is synced (like
## physics_mode) so every game shows a slow-motion player slowly, and saved with the world.
var lab_mode: int = LabRules.Mode.NORMAL

var _setting_lab := false
var _pads := PadRules.new()
var _push_wait := 0.0


## Adds lab_mode to the player's MultiplayerSynchronizer (once, like held_item).
func _sync_lab_mode_property() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:lab_mode")
	if cfg and not cfg.has_property(path):
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


## Sets a lab mode and the physics switch under it. Modes the game mode does not allow are ignored
## (Survivor keeps Normal and Fly).
func set_lab_mode(mode: int) -> void:
	mode = LabRules.valid(mode)
	if not LabRules.allowed(mode, Game.mode):
		return
	_setting_lab = true
	lab_mode = mode
	set_physics_mode(LabRules.physics_mode(mode))
	_setting_lab = false
	if physics_mode != LabRules.physics_mode(mode):   # the switch said no (e.g. Fly without gold)
		mode = LabRules.from_physics(physics_mode)
		lab_mode = mode
	lab_mode_changed.emit(mode)


## The LAB button (Sandbox only): the next lab mode.
func cycle_lab_mode() -> void:
	if Game.allows(ModeRules.PHYSICS_LAB):
		set_lab_mode(LabRules.next(lab_mode, Game.mode))


## Hook at the end of set_physics_mode: the physics switch (WALK/FLY/GHOST, /walk /fly /ghost, a bed)
## picks the plain lab mode.
func _follow_physics_mode(mode: int) -> void:
	if _setting_lab:
		return
	var plain := LabRules.from_physics(mode)
	if plain != lab_mode:
		lab_mode = plain
		lab_mode_changed.emit(plain)


## Zero-G: no gravity; the drift fades slowly; the stick, JUMP and DOWN thrust gently; moving into a
## wall, floor or ceiling kicks off it (LabRules).
func _move_zero_g(delta: float, dir: Vector3) -> void:
	var vertical := Input.get_axis("fly_down", "fly_up")
	if Input.is_action_pressed("jump"):
		vertical = 1.0
	var k := SizeMagic.walk_speed_factor(size_mode)
	var wish := LabRules.wish(dir, vertical)
	_push_wait = maxf(_push_wait - delta, 0.0)
	if _push_wait <= 0.0:
		for i in get_slide_collision_count():
			var normal := get_slide_collision(i).get_normal()
			if LabRules.wants_push_off(normal, wish):
				velocity = LabRules.push_off_velocity(velocity, normal, k)
				_push_wait = LabRules.PUSH_COOLDOWN
				Audio.play(&"step", global_position, -4.0)
				break
	velocity = LabRules.zero_g_velocity(velocity, wish, delta, k)


## Moves the body: a pad under the feet fires first (a jump pad's throw, a speed pad's burst), then
## move_and_slide in the body's own time: slow motion moves it 0.4 as far each frame, while its
## velocity stays its own (synced, so other games animate it at the same slow pace).
func _lab_move_and_slide(body_delta: float) -> void:
	_pads.tick(body_delta)
	var fired := 0
	if physics_mode != PhysicsMode.Mode.GHOST and is_on_floor():
		var facing := Basis(Vector3.UP, rig.yaw) * Vector3.FORWARD
		fired = _pads.touch(PadRules.pad_under(global_position, body_radius(), world.get_block), velocity, facing)
	velocity = _pads.apply(velocity, fired)
	_vr_launched = maxf(_vr_launched - body_delta, 0.0)
	if fired != 0:
		_vr_launched = VR_LAUNCH_SECONDS   # owner #101: a pad's throw is motion the child did not make (the vignette)
		_pad_fx(fired)
		_rpc_pad_fx.rpc(fired)
		_gadget_pad_fired(fired)   # M3 Task 14a: a launch pad opens the glider at the top
	var k := LabRules.time_factor(lab_mode)
	var fall := velocity.y   # M3 Task 4: a landing on a gumdrop bounces
	velocity *= k
	move_and_slide()
	velocity /= k
	_gumdrop_bounce(fall)


func _pad_fx(pad: int) -> void:
	var parent: Node = world if world else get_tree().root
	PadFx.play(parent, global_position, pad, LabRules.time_factor(lab_mode))


## This player's own game fired a pad under it: the same boing and puff in every other game.
@rpc("authority", "call_remote", "unreliable")
func _rpc_pad_fx(pad: int) -> void:
	if PadRules.is_pad(pad):
		_pad_fx(pad)

# --- Avatar looks, emotes and celebrations (M3 Task 9) ------------------------------------------

## This player's look (AvatarLook.to_code), synced to every game (spawn + on change). Its own game
## sets it from the profile; every game wears it, parsed defensively (a bad code is the default look).
var look_code := "":
	set(value):
		look_code = value if value.length() <= AvatarLook.MAX_CODE_LENGTH else ""
		if is_node_ready():
			_wear_look()


## Adds look_code to the player's MultiplayerSynchronizer (once, like held_item).
func _sync_look_property() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:look_code")
	if cfg and not cfg.has_property(path):
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


func _setup_look() -> void:
	if is_local:
		Profile.avatar_changed.connect(_on_profile_look_changed)
		look_code = Profile.data.avatar.to_code()
	_wear_look()


func _on_profile_look_changed() -> void:
	look_code = Profile.data.avatar.to_code()


func _wear_look() -> void:
	if avatar and look_code != "":
		avatar.apply_look(AvatarLook.from_code(look_code))


## This game's own player does an emote (the HUD's emote wheel): it plays at once and the host sends it
## to everyone else (Session.request_emote). False when it can't now (asleep, swimming, not spawned).
func play_emote(emote_name: StringName) -> bool:
	if not is_local or not _spawned or sleeping or not avatar.play_emote(emote_name):
		return false
	Session.request_emote(emote_name)
	return true


## Shows another player's emote here (Session). Bots can call it on their bodies too.
func show_emote(emote_name: StringName) -> void:
	avatar.play_emote(emote_name)

# --- Owner #94: idle life and happy reactions (AnimIdle) -----------------------------------------------------------

var idle := AnimIdle.new()
var _idle_played: StringName = &""   # the fidget this body played last (a cheer may cut it short)
var _friend_near := false
var _friend_check := 0.0
var _arrival_wait := -1.0


## Every body in every game: a glance round, a stretch or a yawn now and then while it stands, a wave when a friend
## walks up (AnimIdle; played here, never sent). The local player also cheers after a rocket's landing.
func _idle_tick(delta: float, speed: float, on_floor: bool) -> void:
	var standing := speed < EmotePoses.STOP_SPEED and on_floor and _spawned and not sleeping and not knocked_out \
		and not _show_swim_pose() and not is_riding() and hidden_in == NO_SPOT and avatar.pose == AvatarModel.POSE_STAND
	_friend_check -= delta
	if _friend_check <= 0.0:
		_friend_check = AnimIdle.CHECK_EVERY
		_friend_near = _friend_close()
	var e := idle.step(delta, standing, avatar.emote() == &"", AnimIdle.is_night(), _friend_near)
	if e != &"" and avatar.play_emote(e):
		_idle_played = e
	if is_local:
		_arrival_step(delta)


## Another player or a bot within AnimIdle.FRIEND_NEAR (flat).
func _friend_close() -> bool:
	for group: StringName in [&"players", &"bots"]:
		for n in get_tree().get_nodes_in_group(group):
			var other := n as Node3D
			if other == null or other == self or not other.visible:
				continue
			var d := other.global_position - global_position
			if Vector2(d.x, d.z).length() < AnimIdle.FRIEND_NEAR and absf(d.y) < 3.0:
				return true
	return false


## A happy little jump and spin (EmotePoses "hooray"), for everyone like any emote: a secret found, a quest step or
## story done, a board goal, an animal tamed (AnimIdle.cheers_for), a Wonders stamp, a rocket's landing. Never over
## an emote or dance the child chose (a fidget the body played itself gives way).
func react_happy() -> void:
	if not is_local or not _spawned or sleeping or knocked_out:
		return
	var now := avatar.emote()
	if now != &"" and now != _idle_played:
		return
	play_emote(&"hooray")


func _on_progress_counted(kind: StringName, _amount: int) -> void:
	if is_local and AnimIdle.cheers_for(kind):
		react_happy()


## After a rocket lands (AnimIdle.cheer_on_arrival): once this player stands in the world and its loading card is
## gone, a short wait, then hooray.
func _arrival_step(delta: float) -> void:
	if AnimIdle.cheer_on_arrival and _arrival_wait < 0.0 and _spawned \
			and get_tree().get_nodes_in_group(LoadingCard.GROUP).is_empty():
		AnimIdle.cheer_on_arrival = false
		_arrival_wait = AnimIdle.ARRIVAL_DELAY
	if _arrival_wait >= 0.0:
		_arrival_wait -= delta
		if _arrival_wait < 0.0:
			react_happy()


## The victory celebration after a won wave or boss (spec §13.6): the victory dance and confetti over
## the head, in this game. M2 Tasks 9-10 call Session.celebrate_all() on the host, which does this for
## every player in every game. The first win in Survivor also earns the Victory dance for the wheel.
func celebrate() -> void:
	avatar.play_emote(&"victory")
	var s := size_scale()
	Celebration.confetti(world if world else get_parent(), eye_position() + Vector3.UP * 0.5 * s, s)
	Audio.play(&"ding", global_position)
	if is_local and Game.mode == ModeRules.SURVIVOR:
		var got := AvatarUnlocks.earn(Profile.data, AvatarCatalog.EARN_FIRST_VICTORY)
		if not got.is_empty():
			Session.magic_feedback.emit(tr("New dance: %s! Put it on your emote wheel.") % Lang.t(AvatarCatalog.display_name(got[0])))

# --- M2 Task 5: stealth — crouching and hiding ----------------------------------------------------

## Went into a barrel or closet (true) or came out (false), on every game.
signal hidden_changed(on: bool)

const NO_SPOT := Vector3i(0, -100000, 0)
const PEEK_HEIGHT := 0.6          # inside a hiding spot the camera looks out from this high in the block

## Crouching (the CROUCH button or C): half speed, a lower body and camera, quiet. This player's own
## game decides it; it is synced, so every game shows it and the host's monsters hear it.
var crouching := false
## The barrel or closet this player is inside (NO_SPOT: none). The host decides (the StealthDirector)
## and tells every game (set_hidden).
var hidden_in := NO_SPOT
## The light around this player (StealthRules.light_level) and whether it stands in a bush, a few times
## a second from the StealthDirector (the host for every player; a guest for its own, for the HUD).
var stealth_light := 1.0
var stealth_in_bush := false

var _hide_from := Vector3.ZERO    # where this body stood before it went in (it comes out on that side)
var _unhide_asked := false


func is_hiding() -> bool:
	return hidden_in != NO_SPOT


## Hidden from every monster: inside a barrel or closet, or crouching in a bush.
func is_hidden() -> bool:
	return StealthRules.is_hidden(is_hiding(), crouching, stealth_in_bush)


## How visible this player is now, 0..1 (StealthRules.visibility).
func stealth_visibility() -> float:
	if sheltered:
		return 0.0   # Build to Survive: safe in a shelter (spec §12.18)
	return StealthRules.visibility(stealth_light, crouching, is_hidden(), is_invisible())


## Build to Survive (spec §12.18): in a shelter (ShelterRules), so monsters can't see this player. Set by the
## SurvivorGameDirector: the host's answer for every player (monsters obey it), each game's own for its player.
var sheltered := false


## Where a monster looks at: the eyes, lower while crouching (a low wall hides a crouching player).
func stealth_eye() -> Vector3:
	var h := CameraRig.HEAD_HEIGHT * size_scale() * (StealthRules.CROUCH_EYE if crouching else 1.0)
	return global_position + Vector3(0, h, 0)


func set_crouching(on: bool) -> void:
	if on and not _may_crouch():
		on = false
	if on == crouching:
		return
	crouching = on
	_update_stealth_look()


func _may_crouch() -> bool:
	return physics_mode == PhysicsMode.Mode.NORMAL and water_state < SwimRules.State.SWIMMING \
		and not sleeping and not knocked_out and not is_hiding()


## This player's own game, every physics frame: true while hidden (the body holds still).
func _stealth_tick() -> bool:
	if is_hiding():
		_hiding_tick()
		return true
	_stealth_input(InputMap.has_action(&"crouch") and Input.is_action_just_pressed(&"crouch"))
	return false


## C (and the CROUCH button, which presses the same action) toggles crouching on the ground; taking
## off, swimming, sleeping and knock-outs stand up. Held while swimming, the action dives (Task 14).
func _stealth_input(toggle: bool) -> void:
	if crouching and not _may_crouch():
		set_crouching(false)
	elif toggle and water_state < SwimRules.State.SWIMMING:
		set_crouching(not crouching)


## Inside: still, and moving (or JUMP) asks the host to come out, once.
func _hiding_tick() -> void:
	velocity = Vector3.ZERO
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if not _unhide_asked and (input.length() > 0.3 or Input.is_action_just_pressed(&"jump")):
		_unhide_asked = true
		Session.stealth_request_unhide()


## Every game, when the host says so: into the barrel or closet at `cell` (the body goes into the
## block and stops colliding, the camera looks out from inside, nobody sees the avatar), or out again
## on the side it went in (StealthRules.search_spot).
func set_hidden(on: bool, cell: Vector3i) -> void:
	if on == is_hiding() and (not on or cell == hidden_in):
		return
	if on:
		set_crouching(false)
		if is_multiplayer_authority():
			if not is_hiding():
				_hide_from = global_position
			if physics_mode != PhysicsMode.Mode.NORMAL and world:
				set_physics_mode(PhysicsMode.Mode.NORMAL)
			velocity = Vector3.ZERO
			collision_mask = 0
			global_position = Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)
		hidden_in = cell
		_unhide_asked = false
		if is_local:
			rig.set_peek(Vector3(cell) + Vector3(0.5, PEEK_HEIGHT, 0.5))
	else:
		var was := hidden_in
		hidden_in = NO_SPOT
		_unhide_asked = false
		if is_multiplayer_authority():
			global_position = StealthRules.search_spot(was, _hide_from, _is_solid) if world else _hide_from
			collision_mask = WORLD_COLLISION_MASK if PhysicsMode.has_collision(physics_mode) else 0
			velocity = Vector3.ZERO
			if world:
				_unstuck()
		if is_local:
			rig.set_peek(Vector3.INF)
	_update_stealth_look()
	hidden_changed.emit(on)


## Every frame, only writing on a change: the crouched body (and the lower camera on this device), and
## no avatar for a player hiding inside (this device's own avatar is handled in _process).
func _update_stealth_look() -> void:
	var body := size_scale() * (StealthRules.CROUCH_BODY if crouching else 1.0)
	if avatar.scale.y != body:
		avatar.scale.y = body
	if is_local:
		var h := StealthRules.CROUCH_EYE if crouching else 1.0
		if rig.height_factor != h:
			rig.height_factor = h
	else:
		var shown := not is_hiding() and not vr_bubbled()   # owner #110 (R8): never in a VR child's face
		if avatar.visible != shown:
			avatar.visible = shown


## Adds crouching to the synchronizer, like held_item (sent with the spawn, then on a change).
func _sync_task5_properties() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:crouching")
	if cfg and not cfg.has_property(path):
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)

# --- M3 Task 12: the name tag's level and title -------------------------------------------------------

## "<level>:<style>" (Progress.tag()), synced (spawn + on change). This player's own game sets it (the
## world's ProgressDirector); the other games show it on the NameTag over this player, parsed defensively.
var progress_tag := "":
	set(value):
		progress_tag = value if value.length() <= 32 else ""


## Adds progress_tag to the player's MultiplayerSynchronizer (once, like held_item).
func _sync_progress_tag_property() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:progress_tag")
	if cfg and not cfg.has_property(path):
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


## Other players get a name tag with their name, level and title; this game's own player has none.
func _setup_name_tag() -> void:
	if not is_local:
		var tag := NameTag.new()
		tag.player = self
		add_child(tag)

# --- M3 Task 4: gumdrops bounce ------------------------------------------------------------------------------

## Landing on a gumdrop (the Candy Kingdom's hills) from a fall bounces this player back up (CandyRules); walking
## over one does not. A boing on this game and the others (the pads' puff RPC).
func _gumdrop_bounce(fall: float) -> void:
	if physics_mode != PhysicsMode.Mode.NORMAL or water_state >= SwimRules.State.SWIMMING or not is_on_floor():
		return
	var speed := CandyRules.gumdrop_bounce(-fall)
	if speed <= 0.0:
		return
	var under := Vector3i((global_position + Vector3(0, -0.05, 0)).floor())
	if not CandyRules.is_gumdrop(world.get_block(under)):
		return
	velocity.y = speed
	Audio.play(&"gummy", global_position, -8.0)

# --- M3 Task 14a: gadgets — the glider, the grappling hook's pull, riding a zipline ----------------------

## This player's gadget movement changed (the HUD's GLIDE button follows it).
signal gadget_move_changed(move: int)

const NO_ROOM_ON_LINE := "No room under the line here!"

## How this body moves with a gadget (GadgetRules.Move). Its own game decides it; it is synced (spawn + on
## change), so every game shows the open glider, the rope or the zipline handle.
var gadget_move: int = GadgetRules.Move.NONE
## The glider's look (GadgetRules.GLIDER_LOOKS index; a cosmetic slot for M3 Task 9's unlocks), synced.
var glider_look := 0
## Where this player's hook holds, in every game (its own game from the host's yes; the others from the
## host's GadgetDirector); INF while not hooked.
var hook_point := Vector3.INF

var _hook_t := 0.0
var _hook_best := INF
var _hook_stuck := 0.0
var _zip_from := Vector3.ZERO
var _zip_to := Vector3.ZERO
var _zip_s := 0.0
var _zip_speed := 0.0
var _zip_target := Vector3.INF
var _auto_glide := false
var _gadget_looks: GadgetLooks


## Adds gadget_move and glider_look to the player's MultiplayerSynchronizer (once, like held_item).
func _sync_gadget_properties() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	for prop: String in [".:gadget_move", ".:glider_look"]:
		var path := NodePath(prop)
		if cfg and not cfg.has_property(path):
			cfg.add_property(path)
			cfg.property_set_spawn(path, true)
			cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


## Sandbox always has a glider; Survivor needs one in the bag (the host's snapshot of this game's bag).
func has_glider() -> bool:
	return GadgetRules.has_glider(Game.allows(ModeRules.UNLIMITED_BLOCKS), Session.my_inventory.count(ItemIds.GLIDER)) \
		or Profile.data.inventions.has(InventionLine.GLIDER)   # owner #78: the glider invented is never lost


## Walking (not flying, a ghost or floating in zero-G): gadgets move a walking body.
func is_walking() -> bool:
	return physics_mode == PhysicsMode.Mode.NORMAL and lab_mode != LabRules.Mode.ZERO_G


## May the glider open now: in the air with room below, walking, not swimming, owned.
func can_glide() -> bool:
	if not is_local or not _spawned or sleeping or knocked_out or is_hiding() or gadget_move != GadgetRules.Move.NONE \
			or is_riding():   # owner #109: never from a seat (a flying car, a dragon)
		return false
	if world == null or not has_glider():
		return false
	return GadgetRules.can_open_glider(is_on_floor(), is_walking(), water_state,
		GadgetRules.air_below(global_position, _is_solid))


func open_glider() -> bool:
	if not can_glide():
		return false
	_jumps.reset()   # the press that opened it is no jump on landing
	_auto_glide = false
	_set_gadget_move(GadgetRules.Move.GLIDE)
	Audio.play(&"whoosh", global_position, -4.0)
	return true


## The GLIDE button: opens the glider, or folds it (the child drops).
func toggle_glider() -> bool:
	if gadget_move == GadgetRules.Move.GLIDE:
		_set_gadget_move(GadgetRules.Move.NONE)
		return true
	return open_glider()


## The host said yes to this player's hook: pulled to `point` (a walking body only).
func start_hook(point: Vector3) -> bool:
	if not is_multiplayer_authority() or not _spawned or not point.is_finite() or not is_walking():
		return false
	hook_point = point
	_hook_t = 0.0
	_hook_best = INF
	_hook_stuck = 0.0
	_set_gadget_move(GadgetRules.Move.HOOK)
	return true


## The host said yes to riding the line from `from` to `to` (its attach points): the body hangs under the
## line by the first post and rides. False (with a word why) when there is no room under the line there.
func start_zip(from: Vector3, to: Vector3) -> bool:
	if not is_multiplayer_authority() or not _spawned or not from.is_finite() or not to.is_finite() or world == null:
		return false
	var feet := GadgetRules.zip_feet(from, to, GadgetRules.ZIP_GAP)
	if not GadgetRules.body_fits(feet, _is_solid):
		if is_local:
			Session.magic_feedback.emit(NO_ROOM_ON_LINE)
		return false
	if not is_walking():
		set_physics_mode(PhysicsMode.Mode.NORMAL)
	_zip_from = from
	_zip_to = to
	_zip_s = GadgetRules.ZIP_GAP
	_zip_speed = GadgetRules.ZIP_START_SPEED
	_zip_target = feet
	global_position = feet
	velocity = Vector3.ZERO
	_set_gadget_move(GadgetRules.Move.ZIP)
	Audio.play(&"whoosh", global_position, -6.0)
	return true


func _set_gadget_move(m: int) -> void:
	m = GadgetRules.valid_move(m)
	if m == gadget_move:
		return
	gadget_move = m
	if m != GadgetRules.Move.HOOK:
		hook_point = Vector3.INF
	gadget_move_changed.emit(m)


## Hook in _physics_process before the movement: true while a gadget moves this body this frame (the
## velocity it set is moved by _lab_move_and_slide as usual).
func _gadget_step(delta: float, dir: Vector3) -> bool:
	if gadget_move == GadgetRules.Move.NONE:
		_gadget_idle()
	match gadget_move:
		GadgetRules.Move.GLIDE:
			return _glide_step(delta, dir)
		GadgetRules.Move.HOOK:
			return _hook_step(delta)
		GadgetRules.Move.ZIP:
			return _zip_step(delta)
	return false


## Not using a gadget: JUMP in the air with every air jump used opens the glider; after a launch pad the
## glider opens by itself at the top of the throw.
func _gadget_idle() -> void:
	if is_on_floor():
		_auto_glide = false
		return
	if _auto_glide and velocity.y <= 0.0:
		_auto_glide = false
		open_glider()
	elif Input.is_action_just_pressed("jump") and GadgetRules.glide_on_jump(_jumps.jumps_used, _jumps.max_jumps):
		open_glider()


func _glide_step(delta: float, dir: Vector3) -> bool:
	if GadgetRules.glide_ends(is_on_floor(), water_state, is_walking()):
		_set_gadget_move(GadgetRules.Move.NONE)   # landed softly (a slow fall): walking goes on this frame
		return false
	velocity = GadgetRules.glide_velocity(velocity, dir, delta, GRAVITY * LabRules.gravity_factor(lab_mode))
	return true


## Pulled straight at the hook point; there (or stuck on the way, or too long), it lets go with a hop.
func _hook_step(delta: float) -> bool:
	_hook_t += delta
	var chest := CombatDirector.chest(self)
	var d := chest.distance_to(hook_point) if hook_point.is_finite() else 0.0
	if d < _hook_best - 0.05:
		_hook_best = d
		_hook_stuck = 0.0
	else:
		_hook_stuck += delta
	if not hook_point.is_finite() or GadgetRules.hook_arrived(chest, hook_point) or _hook_t > GadgetRules.HOOK_MAX_TIME \
			or _hook_stuck > GadgetRules.HOOK_STUCK_TIME or not is_walking():
		if hook_point.is_finite():
			velocity = GadgetRules.hook_release(chest, hook_point)
		_set_gadget_move(GadgetRules.Move.NONE)
		return true
	velocity = GadgetRules.hook_velocity(chest, hook_point)
	return true


## Riding the line: gravity along it, the body kept under the line; JUMP lets go; a block in the way or the
## end of the line slides off with the speed of the ride.
func _zip_step(delta: float) -> bool:
	var along := (_zip_to - _zip_from).normalized()
	var left_behind := _zip_target.is_finite() and global_position.distance_to(_zip_target) > 0.6
	if Input.is_action_just_pressed("jump") or not is_walking() or left_behind:
		velocity = along * _zip_speed + Vector3.UP * (GadgetRules.ZIP_JUMP_OFF if not left_behind else 0.0)
		_set_gadget_move(GadgetRules.Move.NONE)
		return true
	_zip_speed = GadgetRules.zip_speed(_zip_speed, along, delta)
	var next := _zip_s + _zip_speed * delta
	var feet := GadgetRules.zip_feet(_zip_from, _zip_to, next)
	if next >= GadgetRules.zip_ride_end(_zip_from, _zip_to) or not GadgetRules.body_fits(feet, _is_solid):
		velocity = GadgetRules.zip_leave(_zip_from, _zip_to, _zip_speed)
		_set_gadget_move(GadgetRules.Move.NONE)
		return true
	_zip_s = next
	_zip_target = feet
	velocity = (feet - global_position) / maxf(delta, 0.0001)
	return true


## A pad fired under this body: a launch pad opens the glider by itself at the top (when there is one).
func _gadget_pad_fired(pad: int) -> void:
	if pad == BlockIds.LAUNCH_PAD and has_glider():
		_auto_glide = true


## Every frame, in every game: the synced state checked, a sleeping, knocked-out or hidden owner lets go,
## and the looks (the canopy, the rope, the handle) follow it.
func _update_gadget_look() -> void:
	gadget_move = GadgetRules.valid_move(gadget_move)   # synced over LAN: a tampered value is none
	glider_look = GadgetRules.glider_look(glider_look)
	if gadget_move != GadgetRules.Move.NONE and is_multiplayer_authority() and (sleeping or knocked_out or is_hiding()):
		_set_gadget_move(GadgetRules.Move.NONE)
	if gadget_move == GadgetRules.Move.NONE and _gadget_looks == null:
		return
	if _gadget_looks == null:
		_gadget_looks = GadgetLooks.new()
		_gadget_looks.name = "GadgetLooks"
		add_child(_gadget_looks)
	_gadget_looks.show_for(self)

# --- M3 Task 20a: riding a buddy ------------------------------------------------------------------------------

## This player got on or off a buddy (the RIDE button's look, UP/DOWN for a flyer).
signal ride_changed(on: bool)

## The buddy this player rides, set on every game by the buddy (Buddy.rider_peer, which the host decides).
## While riding, the body sits on the saddle (placed every frame), and its own game sends the stick to the host.
var riding: Buddy:
	set(b):
		if b == riding:
			return
		riding = b
		_on_ride(b != null)

var _ride_since := INF
var _ride_sent := Vector3.INF
## Owner #41: the horse or camel this player rides (set on every game by the animal, Animal.rider_peer).
var riding_animal: Animal:
	set(a):
		if a == riding_animal:
			return
		riding_animal = a
		_on_ride(a != null)


func is_riding() -> bool:
	return (is_instance_valid(riding) and riding.rider_peer == peer_id) \
		or (is_instance_valid(riding_animal) and riding_animal.rider_peer == peer_id) \
		or in_car()   # owner #109


## What this player rides: a buddy (M3 Task 20a) or a horse or camel (owner #41) or a car (owner #109); null for none.
func mount() -> Node3D:
	if is_instance_valid(riding) and riding.rider_peer == peer_id:
		return riding
	if is_instance_valid(riding_animal) and riding_animal.rider_peer == peer_id:
		return riding_animal
	if in_car():   # owner #109
		return riding_vehicle
	return null

# --- Owner #109: in a car (Vehicle, VehicleDirector) -------------------------------------------------------------

## The car this player sits in, set on every game by the car (Vehicle.seats, which the host decides). While in it the
## body sits on its seat (placed every frame, VR's origin with it) and the driver's own game sends the stick to the host.
var riding_vehicle: Vehicle:
	set(v):
		if v == riding_vehicle:
			return
		riding_vehicle = v
		_on_ride(v != null)

var _car_since := INF
var _car_sent := Vector3.INF


func in_car() -> bool:
	return is_instance_valid(riding_vehicle) and riding_vehicle.has_rider(peer_id)


## This player's own game in a car: sit still on the seat; the driver sends its stick (x: steer right, y: JUMP up /
## CROUCH down, z: forward) at most 20 times a second and every quarter second while held. Passengers just ride.
func _car_tick(delta: float) -> void:
	velocity = Vector3.ZERO
	water_state = SwimRules.State.DRY
	_ride_place()
	if is_instance_valid(viewer) and world:
		_place_viewer(global_position)   # the world streams around the car
	avatar.animate(0.0, true, delta)
	if riding_vehicle.driver() != peer_id:
		return
	var stick := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var vertical := 0.0
	if Input.is_action_pressed(&"jump"):
		vertical = 1.0
	elif Input.is_action_pressed(&"crouch") or Input.is_action_pressed(&"fly_down"):
		vertical = -1.0
	var wish := Vector3(stick.x, vertical, -stick.y)
	_car_since += delta
	if (wish != _car_sent and _car_since >= RideRules.INPUT_EVERY) or _car_since >= RideRules.INPUT_KEEPALIVE:
		_car_since = 0.0
		_car_sent = wish
		riding_vehicle.send_input(wish)


func _on_ride(on: bool) -> void:
	if on:
		avatar.play_emote(&"sit")
		if is_local:
			set_crouching(false)
			_soft_fall = false
			_climb_to = NAN
			if physics_mode != PhysicsMode.Mode.NORMAL:
				set_physics_mode(PhysicsMode.Mode.NORMAL)   # a paid flight stops: the buddy carries you
		_ride_since = INF
		_ride_sent = Vector3.INF
	else:
		avatar.stop_emote(true)
		if is_local and _spawned and is_inside_tree() and is_instance_valid(world) and world.is_inside_tree():
			_unstuck()          # never left inside blocks (the host's spot follows: get_off_at)
			_soft_fall = true   # off in the air: a gentle drift down, no fall
	ride_changed.emit(on)


## On the saddle, facing the way the buddy faces (every frame, after the buddy moved on this game).
func _ride_place() -> void:
	if not is_riding():
		return
	if in_car():   # owner #109: on its seat in the car
		global_position = riding_vehicle.seat_position(peer_id)
		avatar.rotation.y = riding_vehicle.rotation.y
	elif is_instance_valid(riding_animal) and riding_animal.rider_peer == peer_id:   # owner #41: a horse or camel
		global_position = riding_animal.seat_position()
		avatar.rotation.y = riding_animal.rotation.y
	else:
		global_position = riding.seat_position()
		avatar.rotation.y = riding.rotation.y
	if avatar.emote() == &"":
		avatar.play_emote(&"sit")   # an emote on the saddle ends sitting again


## This player's own game while riding: sit still on the saddle and send the stick to the host (at most 20 times
## a second, and every quarter second while held); JUMP gets off anything but a flyer (a flyer climbs).
func _ride_tick(delta: float) -> void:
	if in_car():
		_car_tick(delta)   # owner #109: a car (JUMP never hops off: it flies a flying car)
		return
	velocity = Vector3.ZERO
	water_state = SwimRules.State.DRY
	_ride_place()
	if is_instance_valid(viewer) and world:
		_place_viewer(global_position)   # the world streams around the rider
	avatar.animate(0.0, true, delta)
	var on_buddy := is_instance_valid(riding) and riding.rider_peer == peer_id
	var flyer := on_buddy and (riding.ride_mode == RideRules.Kind.FLY or riding.ride_kind == RideRules.Kind.FLY)
	if not flyer and Input.is_action_just_pressed(&"jump"):
		Session.request_ride_off()
		return
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Basis(Vector3.UP, _walk_yaw()) * Vector3(input.x, 0.0, input.y)
	var vertical := Input.get_axis(&"fly_down", &"fly_up")
	if Input.is_action_pressed(&"jump"):
		vertical = 1.0
	elif Input.is_action_pressed(&"crouch"):
		vertical = -1.0
	var wish := Vector3(dir.x, vertical, dir.z)
	_ride_since += delta
	if (wish != _ride_sent and _ride_since >= RideRules.INPUT_EVERY) or _ride_since >= RideRules.INPUT_KEEPALIVE:
		_ride_since = 0.0
		_ride_sent = wish
		Session.ride_input(String(riding.name if on_buddy else riding_animal.name), wish)


## The host says where to stand after getting off (RideRules.dismount_spot, never inside blocks).
func get_off_at(spot: Vector3) -> void:
	if not spot.is_finite():
		return
	riding = null
	riding_animal = null   # owner #41
	riding_vehicle = null   # owner #109
	global_position = spot
	velocity = Vector3.ZERO
	if physics_mode == PhysicsMode.Mode.NORMAL:
		_unstuck()
	_soft_fall = true
	rig.snap_to_target()

# --- Owner 39: the Dragon Realm's void ---------------------------------------------------------------------------

## The wind carried this player back from the void (its own game): the sandbox says so (DragonRules.CARRIED_BACK).
## `to`: where it lands (y NAN: on that column's ground; Vector3.INF: home).
signal carried_back(to: Vector3)

var _safe := DragonRules.SafeSpot.new()
var _void_world := -1   # -1: not looked at yet; 1: this world floats over a void (DragonRules.world_has_void)
var _void_line := DragonRules.RESCUE_Y   # cosmos: the world's own line (DragonRules.rescue_y: Venus's breeze)


func in_void_world() -> bool:
	if _void_world < 0 and world:
		_void_world = 1 if DragonRules.world_has_void(world.descriptor(), world.generator_shape() is ArenaShape) else 0
		_void_line = DragonRules.rescue_y(world.descriptor())
	return _void_world == 1


## This player's own game, every step after moving: remember where it last stood on solid ground; once its feet are
## below the line, the wind carries it back there (DragonRules.rescue_target: the spot, that column's ground, or home).
## No damage, no knock-out, nothing dropped, in every mode.
func _void_step(delta: float) -> void:
	if world == null or not in_void_world():
		return
	var under := Vector3i((global_position + Vector3(0, -0.05, 0)).floor())
	_safe.note(delta, is_on_floor(), world.get_block(under), global_position, _void_line)
	if DragonRules.fell_into_void(global_position.y, _void_line):
		carry_back()


## Back from the void: to the last safe spot, else onto that column's ground, else home (bed or spawn).
func carry_back() -> void:
	var spot := _safe.spot
	var still := BlockIds.is_solid(world.get_block(Vector3i((spot + Vector3(0, -0.05, 0)).floor())))
	var island := world.surface_height(floori(spot.x), floori(spot.z)) > maxf(MeadowsShape.SEA_LEVEL + 1, _void_line)
	var to := DragonRules.rescue_target(spot, _safe.has, still, island, Vector3.INF)
	velocity = Vector3.ZERO
	_soft_fall = false
	if to == Vector3.INF:
		go_home()
	else:
		spawn_at(to)
	Audio.play(&"whoosh")
	carried_back.emit(to)

# --- M3 Task 21a: Simple controls (SimpleControls; the setting simple_controls) ---

## True when this device's child chose Simple controls.
static func simple_controls() -> bool:
	return bool(Profile.data.settings.get("simple_controls", false))


## Simple: while the stick pushes sideways the third-person camera turns to follow behind the child.
func _simple_follow(input: Vector2, delta: float) -> void:
	if is_local and not rig.first_person and simple_controls() and not rig.vr_mode():   # owner #101: never in VR
		rig.yaw = SimpleControls.follow_yaw(rig.yaw, input, delta, rig.since_look())

# --- Owner #101: VR on the Meta Quest (docs/devlog/parts/vr-rig.md) -----------------------------------------------

## The yaw the stick walks along: the camera's (in VR the head's), or the walking hand's (VR COMFORT "hand").
func _walk_yaw() -> float:
	if not (is_local and rig.vr_mode()) or str(Vr.setting(VrRules.WALK_DIR)) != "hand":
		return rig.yaw
	var other := VrRules.LEFT if Vr.pointing_hand() == VrRules.RIGHT else VrRules.RIGHT
	var r := Vr.hand_ray(other)
	if r.is_empty():
		return rig.yaw
	var dir: Vector3 = r[1]
	return atan2(-dir.x, -dir.z) if Vector2(dir.x, dir.z).length() > 0.05 else rig.yaw


## P3: falling asleep the origin holds where the child stood while the view fades to black (the body goes onto the bed
## behind it), then waits there; waking, the body is off the bed already and the view fades back in. The head is never
## laid down with the avatar.
func _vr_sleep_fade(asleep: bool) -> void:
	if asleep:
		Vr.freeze(true)
		await Vr.fade_out(VrRules.SLEEP_FADE)
		if sleeping:
			Vr.freeze(false)   # at the bed, behind the black
		return
	Vr.freeze(false)
	await get_tree().process_frame   # the wake's step off the bed is done (set_sleeping goes on after this call)
	Vr.snap_origin()   # off the bed, still behind the black
	Vr.fade_in(VrRules.SLEEP_FADE)


## P3: motion the child did not make (the comfort vignette is stronger then): a ride (a buddy, the dragon and flyers, a
## horse), a gadget (the glider, the hook's pull, a zipline), zero-G, a pad's throw, a kite's lift, a soft fall.
func vr_passive_motion() -> bool:
	return is_riding() or gadget_move != GadgetRules.Move.NONE or lab_mode == LabRules.Mode.ZERO_G \
		or _vr_launched > 0.0 or _kite_floating or _soft_fall


## A pad threw this body (s left of its throw counting as passive motion).
var _vr_launched := 0.0
const VR_LAUNCH_SECONDS := 1.5
## (feet: Vector3) -> bool: a game says no teleport there; never by default. Round 3: every node in the group
## TELEPORT_RULES with refuses_teleport(player, at) -> bool is asked too (CourseDirector while racing, GamesDirector
## while a round is on): vr_teleport_refused() asks them all.
var vr_teleport_refuse: Callable = func(_at: Vector3) -> bool: return false
const TELEPORT_RULES := &"vr_teleport_rules"


## A teleport to `at` is refused: by this player's own rule, or by any game that has a say (a race, a round).
func vr_teleport_refused(at: Vector3) -> bool:
	if vr_teleport_refuse.is_valid() and bool(vr_teleport_refuse.call(at)):
		return true
	for n: Node in get_tree().get_nodes_in_group(TELEPORT_RULES) if is_inside_tree() else []:
		if n.has_method(&"refuses_teleport") and bool(n.call(&"refuses_teleport", self, at)):
			return true
	return false

# --- Owner #101, P4: vr_pose, the VR body, the hands ---------------------------------------------------------------

## A VR player's head and both hands (VrPoseRules, 21 bytes); empty off VR. Written by the player's own game while in
## VR and sent by its VrPoseLink (an RPC, 20 times a second, only to the games that asked: never the player's sync,
## which an older build could not read: see VrPoseLink); other games show it (VrBody).
var vr_pose := PackedByteArray()
## The developer arg for a game standing in for a build from before P4 (tools/net_test.sh --old=...): no VrPoseLink.
const OLD_PEER_ARG := "--vr-old-peer"
var _vr_body: VrBody
var _vr_link: VrPoseLink


## Every game's copy of a player gets the link (the same node path everywhere: its RPCs line up), owned as the player.
func _add_vr_pose_link() -> void:
	if OS.get_cmdline_user_args().has(OLD_PEER_ARG):
		return
	_vr_link = VrPoseLink.new(self)
	add_child(_vr_link)
	_vr_link.set_multiplayer_authority(peer_id)


## This game's player in VR writes its pose; any other player with a pose (or this one in the mirror) gets its body.
func _vr_pose_frame() -> void:
	if is_local:
		var mine := Vr.pose_bytes(self) if rig.vr_mode() and _spawned else PackedByteArray()
		if mine != vr_pose:
			vr_pose = mine
	var wants := not vr_pose.is_empty() and (not is_local or Vr.mirror_shown())
	if wants and _vr_body == null:
		_vr_body = VrBody.new(self)
		_vr_body.hands_shown = not is_local   # this game's own hands are the rig's
		add_child(_vr_body)
	elif not wants and _vr_body != null:
		_vr_body.queue_free()
		_vr_body = null


## Another player's VR body as this game shows it (null when none: not in VR, or this game's own).
func vr_body() -> VrBody:
	return _vr_body if _vr_body != null and is_instance_valid(_vr_body) else null


## Owner #110 (VR round 4, R8, the personal bubble): another player's head (its eyes) within VrGrabRules.BUBBLE of this
## game's child's head in a headset: its body is not drawn here (nobody pushes into a child's face). Off VR: never.
func vr_bubbled() -> bool:
	if is_local or not Vr.active() or Vr.camera == null:
		return false
	return eye_position().distance_to(Vr.head_transform().origin) / maxf(Vr.world_scale(), 0.001) < VrGrabRules.BUBBLE


## Where the held item hangs: this game's VR hand (a bow in the other hand), a remote VR player's right hand, or the
## avatar's hand as before.
func _held_item_hand() -> Node3D:
	if is_local and rig.vr_mode():
		var vr := Vr.item_anchor(held_item)
		if vr:
			return vr
	if _vr_body != null and is_instance_valid(_vr_body) and _vr_body.hands_shown:
		var remote := _vr_body.item_anchor()
		if remote:
			return remote
	return avatar.hand() if avatar and avatar.has_method(&"hand") else null


## P3: a teleport only from walking in the world: never riding, asleep, knocked out, hidden, gliding or hooked.
func vr_may_teleport() -> bool:
	return is_local and rig.vr_mode() and _spawned and world != null and not sleeping and not knocked_out \
		and not is_riding() and not is_hiding() and gadget_move == GadgetRules.Move.NONE


## P3: there, behind a black blink: out (VrRules.FADE_OUT), the body moved, in (the snap's blink).
func vr_teleport(at: Vector3) -> void:
	if not vr_may_teleport():
		return
	await Vr.fade_out(VrRules.FADE_OUT)
	if not is_inside_tree() or not vr_may_teleport():
		Vr.fade_in()
		return
	global_position = at
	velocity = Vector3.ZERO
	rig.snap_to_target()
	Audio.play(&"air_jump", at)


## Room scale: the child stepped in the room, so the head left the body: the body walks after it (collisions as any
## step) and the origin takes that step back, so the view never moves. A head the body can't follow (a wall), or one
## inside a solid block, fades the view to black (VrRules.head_fade): no x-ray through hills or into hiding spots.
func _vr_room_scale() -> void:
	if not (is_local and rig.vr_mode()) or Vr.rig == null or Vr.body_waits():   # owner #110: MODEL VIEW's body waits
		return
	var d := Vr.rig.head_offset()
	# move_and_slide steps by the physics tick inside one, by the frame's time outside (the tests' calls)
	var dt := get_physics_process_delta_time() if Engine.is_in_physics_frame() else get_process_delta_time()
	if d.length() > VrRules.FOLLOW_DEADZONE and dt > 0.0:
		var keep := velocity
		var before := global_position
		velocity = d / dt
		move_and_slide()
		velocity = keep
		Vr.rig.body_moved(global_position - before)
		d = Vr.rig.head_offset()
	var head := Vr.head_transform().origin
	var solid := world != null and BlockIds.is_solid(world.get_block(Vector3i(head.floor())))
	Vr.set_head_blocked(VrRules.head_fade(d.length(), solid))

# --- Owner #54: a double tap on JUMP takes off flying (JumpTaps, spec §3b) -----------------------------------

var _jump_taps := JumpTaps.new()
var _lift_left := 0.0   # s of UP left after the taps' take-off or a tap while flying
var _taps_frame := -2   # the physics frame _jump_taps_step last ran


## Every moving frame of this player's own game: counts the taps on JUMP (the touch button and Space alike). Quick taps
## take off like the FLY button (owner #54, #75): the second in the Sandbox, the third in Survivor (it costs gold);
## flying, each tap lifts the player higher. The first taps are still jumps (JumpCounter). A frame it did not run
## (asleep, riding, hidden, knocked out, not yet spawned) forgets the taps before it.
func _jump_taps_step(delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if frame != _taps_frame + 1:
		_jump_taps.reset()
	_taps_frame = frame
	_jump_taps.tick(delta)
	if not Input.is_action_just_pressed("jump"):
		return
	if physics_mode == PhysicsMode.Mode.FLY and gadget_move == GadgetRules.Move.NONE:
		_lift_left = minf(_lift_left + JumpTaps.TAP_LIFT, JumpTaps.MAX_LIFT)   # owner #75: flying, every tap goes higher
		return
	var counts := JumpTaps.counts(Game.allows(ModeRules.FLYING), is_walking() and is_nan(_climb_to), water_state,
		gadget_move)
	if _jump_taps.tap(counts, JumpTaps.needed(Game.allows(ModeRules.FREE_FLY))):
		take_off()


## Flying, as the FLY button does, with a clear lift and a whoosh (quick taps on JUMP). False where FLY is refused.
func take_off() -> bool:
	set_physics_mode(PhysicsMode.Mode.FLY)
	if physics_mode != PhysicsMode.Mode.FLY:
		return _kite_floating   # owner #78: the kite lifted the child (no flying)
	_lift_left = JumpTaps.TAKE_OFF_LIFT
	Audio.play(&"whoosh", global_position, -4.0)
	return true

# --- Owner #78 (spec §21e): flying machines the child invented ------------------------------------------------------
# Survivor flies what the child invented (InventionRules): the kite's short lift on a windy hill (walking, never FLY),
# the balloon (free), the plane and the jet (fuel: the host's fly_tick charges by flight_craft). The Sandbox keeps its
# classic free flying (NONE) and flies whatever the Inventions book picked (chosen_craft). FlightLook shows the machine.

## The flying machine this body is in (FlightCrafts.Craft): NONE the classic flying, KITE the kite up from the hand,
## BALLOON / PLANE / JET flying in it. Synced: every game shows it, the host charges its fuel.
var flight_craft: int = FlightCrafts.Craft.NONE
## The machine the Inventions book picked for the next take-off (NONE: Survivor's saved pick or its newest, the
## Sandbox's classic flying). This game's own.
var chosen_craft: int = FlightCrafts.Craft.NONE
## Where the wind blows and how fast (flat; the InventionsDirector sets it): the balloon drifts with it.
var wind := Vector3(FlightCrafts.WIND_SPEED, 0.0, 0.0)
## The kite is held up (its "try it"): it flies from the hand while walking.
var kite_held := false
var _kite_lift_left := 0.0
var _kite_floating := false
var _flight_look: FlightLook


func _sync_flight_properties() -> void:
	var cfg := ($Sync as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:flight_craft")
	if cfg and not cfg.has_property(path):
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


## The machine a take-off now flies with (InventionRules.take_off_craft).
func _take_off_craft() -> int:
	return InventionRules.take_off_craft(Game.allows(ModeRules.FREE_FLY), Profile.data.inventions, chosen_craft)


## Flying: in the machine picked (a flyer), else the classic flying; walking or a ghost: out of it (the kite held stays).
func _follow_flight_craft(mode: int) -> void:
	if not is_local:
		return
	if mode == PhysicsMode.Mode.FLY:
		var craft := _take_off_craft()
		flight_craft = craft if FlightCrafts.flies(craft) else FlightCrafts.Craft.NONE
		_kite_floating = false
	elif flight_craft != FlightCrafts.Craft.KITE or not (kite_held or _kite_floating):
		flight_craft = FlightCrafts.Craft.NONE


## FLY with the kite: on a windy hill it pulls the child up for a moment (true), else it says why. One lift until the
## feet touch the ground again (FLY pressed again in the air does nothing).
func _kite_take_off() -> bool:
	if _kite_floating:
		return false
	var no_air := InventionRules.air_refusal(InventionRules.air(Game.universe))
	if no_air != "":
		Session.magic_feedback.emit(no_air)
		return false
	if not FlightCrafts.windy_hill(global_position.y, MeadowsShape.SEA_LEVEL):
		Session.magic_feedback.emit(Lang.t(InventionRules.KITE_HILL_WORDS))
		return false
	_kite_lift_left = FlightCrafts.KITE_LIFT_TIME
	_kite_floating = true
	flight_craft = FlightCrafts.Craft.KITE
	Audio.play(&"whoosh", global_position, -4.0)
	return true


## The kite's "try it": up from the hand (or down).
func hold_kite(on: bool) -> void:
	kite_held = on
	if on:
		flight_craft = FlightCrafts.Craft.KITE
	elif not _kite_floating and flight_craft == FlightCrafts.Craft.KITE:
		flight_craft = FlightCrafts.Craft.NONE


## Walking with the kite's lift: its pull, then no faster down than KITE_FALL until the feet touch the ground.
func _kite_step(delta: float) -> void:
	if not _kite_floating:
		return
	if _kite_lift_left > 0.0:
		velocity.y = FlightCrafts.kite_velocity(velocity.y, _kite_lift_left)
		_kite_lift_left -= delta
	elif is_on_floor() or water_state != SwimRules.State.DRY:
		_kite_floating = false
		if not kite_held and flight_craft == FlightCrafts.Craft.KITE:
			flight_craft = FlightCrafts.Craft.NONE
	else:
		velocity.y = FlightCrafts.kite_velocity(velocity.y, 0.0)


func kite_floating() -> bool:
	return _kite_floating


## Every frame, in every game: the synced machine checked, and its model shown (made the first time one flies).
func _update_flight_look() -> void:
	flight_craft = FlightCrafts.valid(flight_craft)   # synced over LAN: a tampered value is none
	if flight_craft == FlightCrafts.Craft.NONE and _flight_look == null:
		return
	if _flight_look == null:
		_flight_look = FlightLook.new()
		_flight_look.name = "FlightLook"
		add_child(_flight_look)
	_flight_look.show_for(self)

# --- Universe 6: the Spore Mother's spore clouds slow a child ---------------------------------------------------------

## Slowed for `seconds` (the longer of this and what is left; 0 ends it now). Each game slows its own player (the
## SporeMother sees where its clouds land and linger on every screen).
func slow_down(seconds: float) -> void:
	_slow_t = 0.0 if seconds <= 0.0 else maxf(_slow_t, seconds)


func is_slowed() -> bool:
	return _slow_t > 0.0
