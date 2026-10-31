class_name Vehicle
extends CharacterBody3D
## Owner #109 (spec §3b "Cars"): a ready-made car in the world (CarKinds: a go-kart, an off-roader, a race car, a pickup
## truck, a bus, a monster truck, a hover car or a sky taxi). Its look is CarModels' cached meshes; it keeps ONE compact
## collision box (owner feedback #9), solid like the world (children bump into a parked car and can climb onto it).
## The host decides everything (VehicleDirector puts riders in its seats: `seats`, synced, the driver first; the driver's
## stick comes in through set_input, from the driver's own game by an RPC on this node, heard only from the driver) and
## moves it here (VehicleRules): driving, hopping up the steps it climbs, bumping off walls, stopping for bodies in its
## way and pushing them gently aside, floating in water, flying, landing. A parked car sleeps (no physics at all) until
## someone gets in or the ground under it goes; one that falls out of the world is carried back to safe ground. Every
## game puts its riders on their seats (Player.riding_vehicle), spins the wheels and the rotors, bobs a hover car,
## bounces a monster truck, shows the pickup's load and plays the engine, the horn and the bumps.

## Solid like the world (Player.WORLD_COLLISION_MASK): players bump into cars and stand on them; the world's rays and
## the camera's spring arm see them (VehicleDirector keeps a rider's own car out of its camera's arm).
const LAYER := 1
## What stops a car: the world (and other cars), players, buddies, animals and monsters, bot friends.
const MASK := 1 | 2 | 4 | 8 | 64
const BUMP_EVERY := 0.4
const BOUNCE := 0.38            # a monster truck lands and bounces back up with this share of its fall
const BOUNCE_FROM := 6.0        # m/s of falling before a landing bounces
const SAFE_EVERY := 0.5
const RELINK_EVERY := 0.1
const HOVER_BOB := 0.05
const ENGINE_DB := -16.0

signal fx_played(what: StringName)

## The kind (CarKinds), from the spawn data, on every game.
var kind: StringName = CarKinds.GO_KART
## Its owner's name (the child whose car it is: one of each kind per child).
var owner_name := ""
## Host: when it came out (the oldest parked one goes back to the garage first).
var born := 0
## Its colour (CarKinds.colour_index). Synced; a new colour is a new look at once.
var colour := 0:
	set(v):
		colour = CarKinds.colour_index(v)
		_repaint()
## Who sits where (a player's id, 0 for a free seat; the driver's seat first). The host decides; synced.
var seats := PackedInt32Array():
	set(v):
		seats = VehicleRules.clean_seats(v, CarKinds.seats(kind))
		_link_riders()
## A flying car in the air (the host's; synced: UP and DOWN on the driver's HUD, the rotors).
var flying := false
## The pickup's load (VehicleRules' pairs of a block and a count). Synced; shown in its bed.
var cargo := PackedInt32Array():
	set(v):
		cargo = VehicleRules.clean_cargo(v)
		_show_cargo()
## Host: the driver's stick (steer, up/down, throttle), as VehicleRules.clean_input left it.
var input := Vector3.ZERO
## Its speed as this game sees it (m/s, along its front: negative backing up), for the wheels and the engine.
var shown_speed := 0.0

var _input_age := INF
var _decide := 0.0
var _hop := 0
var _hop_way := 0.0              # a hop on: 1 forward, -1 backing up, 0 none
var _surface := NAN
var _landing := false
var _awake := true
var _bump_wait := 0.0
var _safe := Vector3.INF
var _safe_clock := 0.0
var _ceiling := VehicleRules.FLY_CEILING
var _pushed := {}               # host: body instance id -> seconds until it may be pushed again
var _excepted: Array[Node] = []   # host: rider bodies the box ignores
var _riders: Array[Player] = []  # this game's copies of its riders
var _relink := 0.0
var _body := Node3D.new()        # the look's root (a hover car's bob, a monster truck's bounce)
var _look := MeshInstance3D.new()
var _seat_nodes: Array[Marker3D] = []
var _wheels: Array[Node3D] = []
var _rotors: Array[Node3D] = []
var _cargo_view: MeshInstance3D
var _engine: AudioStreamPlayer3D
var _last_pos := Vector3.INF
var _spin := 0.0
var _t := 0.0
var _bounce := 0.0
var _bounce_v := 0.0


## Spawn data -> car: {kind, colour, owner, pos, yaw, id, seats?, cargo?}.
func setup(data: Dictionary) -> void:
	kind = StringName(str(data.get("kind", CarKinds.GO_KART)))
	if not CarKinds.exists(kind):
		kind = CarKinds.GO_KART
	owner_name = str(data.get("owner", ""))
	name = str(data.get("id", "Car"))
	position = data.get("pos", Vector3.ZERO)
	rotation.y = float(data.get("yaw", 0.0))
	born = int(data.get("born", 0))
	_build()
	colour = int(data.get("colour", 0))
	seats = PackedInt32Array(data.get("seats", PackedInt32Array()))
	cargo = VehicleRules.clean_cargo(data.get("cargo", []))
	_safe = position


## The spawn data that makes this car again (a guest's spawner, the save).
func to_spawn() -> Dictionary:
	return {"kind": String(kind), "colour": colour, "owner": owner_name, "pos": global_position if is_inside_tree()
		else position, "yaw": rotation.y, "id": String(name), "born": born, "cargo": cargo}


## What the save keeps (VehicleRules.clean_save reads it back).
func to_save() -> Dictionary:
	var p := global_position if is_inside_tree() else position
	return {"kind": String(kind), "colour": colour, "owner": owner_name, "pos": [p.x, p.y, p.z], "yaw": rotation.y,
		"cargo": Array(cargo)}


func _build() -> void:
	collision_layer = LAYER
	collision_mask = MASK
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.3
	add_to_group(&"vehicles")
	_body.name = "Body"
	add_child(_body)
	_look.name = "Look"
	_body.add_child(_look)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = CarKinds.box(kind)
	shape.shape = box
	shape.position.y = box.size.y * 0.5
	add_child(shape)
	var wheel := CarModels.wheel(kind)
	for p: Vector3 in CarKinds.wheels(kind):
		var hinge := Node3D.new()
		hinge.name = "Wheel%d" % _wheels.size()
		hinge.position = p
		hinge.rotation.y = -PI * 0.5 if p.x > 0.0 else PI * 0.5   # its face looks out of the car's side
		var mi := MeshInstance3D.new()
		mi.mesh = wheel
		hinge.add_child(mi)
		_body.add_child(hinge)
		_wheels.append(hinge)
	for p: Vector3 in CarModels.rotor_spots(kind):
		var r := MeshInstance3D.new()
		r.name = "Rotor%d" % _rotors.size()
		r.mesh = CarModels.rotor()
		r.position = p
		_body.add_child(r)
		_rotors.append(r)
	var i := 0
	for s: Vector3 in CarKinds.seat_offsets(kind):
		var m := Marker3D.new()
		m.name = "Seat%d" % i
		m.position = s
		add_child(m)
		_seat_nodes.append(m)
		i += 1
	if CarKinds.carries_load(kind):
		_cargo_view = MeshInstance3D.new()
		_cargo_view.name = "Cargo"
		_cargo_view.scale = Vector3.ONE * 0.42
		_cargo_view.position = CarModels.BED + Vector3(-0.42, 0.0, -0.42)
		_body.add_child(_cargo_view)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var cfg := SceneReplicationConfig.new()
	cfg.add_property(NodePath(".:position"))
	cfg.add_property(NodePath(".:rotation"))
	for prop: String in ["seats", "flying", "colour", "cargo"]:
		var path := NodePath(".:" + prop)
		cfg.add_property(path)
		cfg.property_set_spawn(path, true)
		cfg.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	sync.replication_config = cfg
	add_child(sync)


func _repaint() -> void:
	if _look:
		_look.mesh = CarModels.body(kind, colour)


func _ready() -> void:
	_link_riders()
	_last_pos = global_position


func _exit_tree() -> void:
	for p in _riders:
		if is_instance_valid(p) and p.riding_vehicle == self:
			p.riding_vehicle = null
	_riders.clear()


# --- Seats -------------------------------------------------------------------------------------------------------

## The look (tests: its mesh is the kind's in its colour).
func look() -> MeshInstance3D:
	return _look


func seat_nodes() -> Array[Marker3D]:
	return _seat_nodes


func wheel_nodes() -> Array[Node3D]:
	return _wheels


func rotor_nodes() -> Array[Node3D]:
	return _rotors


## Seat `i`'s place in the world: where its rider's feet go.
func seat_spot(i: int) -> Vector3:
	var offsets := CarKinds.seat_offsets(kind)
	if i < 0 or i >= offsets.size():
		return Vector3.INF
	return (global_transform if is_inside_tree() else transform) * (offsets[i] as Vector3)


## Where player `peer` sits now (INF when it has no seat here).
func seat_position(peer: int) -> Vector3:
	return seat_spot(VehicleRules.seat_of(seats, peer))


func driver() -> int:
	return seats[0] if not seats.is_empty() else 0


func has_rider(peer: int) -> bool:
	return peer != 0 and seats.has(peer)


func has_riders() -> bool:
	return not VehicleRules.riders(seats).is_empty()


## The RIDE button's word next to it ("DRIVE", "GET IN"; "" when full).
func board_word() -> String:
	return VehicleRules.board_word(seats)


## Host: `peer` gets in (VehicleDirector checked it may): the seat it took, or -1 when full.
func host_board(peer: int) -> int:
	var i := VehicleRules.free_seat(seats)
	if i < 0 or has_rider(peer):
		return VehicleRules.seat_of(seats, peer) if has_rider(peer) else -1
	var next := seats.duplicate()
	next[i] = peer
	seats = next
	if i == 0:
		input = Vector3.ZERO
		_input_age = INF
		_landing = false
	_awake = true
	return i


## Host: `peer` gets out. A flying car whose driver left comes down gently.
func host_leave(peer: int) -> bool:
	var i := VehicleRules.seat_of(seats, peer)
	if i < 0:
		return false
	var next := seats.duplicate()
	next[i] = 0
	seats = next
	if i == 0:
		input = Vector3.ZERO
		_input_age = INF
		_landing = flying
	_awake = true
	return true


## Host: the driver's stick, as it came (cleaned).
func set_input(wish: Vector3) -> void:
	input = VehicleRules.clean_input(wish)
	_input_age = 0.0


## The driver's own game: its stick to the host (the host's own driver straight in).
func send_input(wish: Vector3) -> void:
	if multiplayer.is_server():
		if driver() == multiplayer.get_unique_id():
			set_input(wish)
	else:
		_rpc_input.rpc_id(1, wish)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_input(wish: Vector3) -> void:
	if multiplayer.is_server():
		_heard_input(multiplayer.get_remote_sender_id(), wish)


## Host: a stick heard from player `from`: only the driver's moves the car.
func _heard_input(from: int, wish: Vector3) -> void:
	if from != 0 and from == driver():
		set_input(wish)


## Host: FLY (on) lifts a flying car off; LAND (off) brings it down to drive.
func host_fly(on: bool) -> void:
	if not CarKinds.flies(kind):
		return
	if on and not flying:
		flying = true
		_landing = false
		velocity.y = maxf(velocity.y, VehicleRules.TAKE_OFF)
		_awake = true
		host_fx(&"lift")
	elif not on and flying:
		_landing = true


## Host: it goes to `pos` facing `yaw` (called to a child, carried back), stopped and on the ground.
func host_place(pos: Vector3, yaw: float) -> void:
	global_position = pos
	rotation = Vector3(0.0, yaw, 0.0)
	velocity = Vector3.ZERO
	flying = false
	_landing = false
	_safe = pos
	_awake = true
	_last_pos = pos
	reset_physics_interpolation()


## Parked and asleep: no physics at all until someone gets in or the ground under it goes.
func asleep() -> bool:
	return not _awake


## Every game: this car's riders sit on its seats (Player.riding_vehicle); the host's box ignores them.
func _link_riders() -> void:
	if not is_inside_tree():
		return
	var now: Array[Player] = []
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and not p.is_queued_for_deletion() and has_rider(p.peer_id):
			now.append(p)
	for p in _riders:
		if is_instance_valid(p) and not now.has(p) and p.riding_vehicle == self:
			p.riding_vehicle = null
	for p in now:
		if p.riding_vehicle != self:
			p.riding_vehicle = self
	_riders = now
	for b in _excepted:
		if is_instance_valid(b) and not now.has(b):
			remove_collision_exception_with(b)
	_excepted.clear()
	for p in now:
		add_collision_exception_with(p)
		_excepted.append(p)


# --- The host moves it -------------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	host_step(delta)


func host_step(delta: float) -> void:
	_decide -= delta
	if _decide <= 0.0:
		_decide = VehicleRules.DECIDE_EVERY
		_host_decide()
	if not _awake:
		return
	_input_age += delta
	_bump_wait = maxf(_bump_wait - delta, 0.0)
	for id: int in _pushed.keys():
		_pushed[id] = float(_pushed[id]) - delta
		if float(_pushed[id]) <= 0.0:
			_pushed.erase(id)
	var wish := input if driver() != 0 and _input_age < VehicleRules.INPUT_STALE else Vector3.ZERO
	var floating := _floating()
	if CarKinds.flies(kind) and not flying and driver() != 0 and wish.y > 0.5:
		host_fly(true)   # JUMP on the ground takes off
	if flying:
		var vertical := -1.0 if _landing else wish.y
		var r := VehicleRules.fly_step(kind, velocity, rotation.y, wish.x, wish.z if not _landing else 0.0, vertical, delta)
		velocity = r.velocity
		rotation.y = r.yaw
		if _landing:
			velocity.y = maxf(velocity.y, -VehicleRules.LAND_SPEED)
		velocity = VehicleRules.held_under(velocity, global_position.y, _ceiling)
		if is_finite(_surface):
			velocity.y = maxf(velocity.y, _lift(_surface))   # comes down on the water's top, never under it
	else:
		var top := VehicleRules.FLOAT_SPEED if floating and not CarKinds.hovers(kind) else -1.0
		var r := VehicleRules.drive_step(kind, velocity, rotation.y, wish.x, wish.z, is_on_floor() or floating, delta, top,
			driver() == 0)
		velocity = r.velocity
		rotation.y = r.yaw
		if floating:
			velocity.y = _lift(_surface - (0.0 if CarKinds.hovers(kind) else RideRules.DRAFT))
		elif not is_on_floor():
			velocity.y -= VehicleRules.GRAVITY * delta
		if _hop > 0:
			velocity.y = VehicleRules.hop_velocity(_hop, VehicleRules.GRAVITY)
			_hop = 0
			_hop_way = -1.0 if wish.z < 0.0 else 1.0
		if _hop_way != 0.0:
			if is_on_floor() and velocity.y <= 0.0:
				_hop_way = 0.0   # landed: up the step
			else:   # a hop goes on up and over the step, never straight up against its face
				var fwd := Basis(Vector3.UP, rotation.y) * Vector3.FORWARD * _hop_way
				var along := Vector3(velocity.x, 0.0, velocity.z).dot(fwd)
				if along < VehicleRules.HOP_FORWARD:
					var h := fwd * VehicleRules.HOP_FORWARD
					velocity = Vector3(h.x, velocity.y, h.z)
	var going := Vector3(velocity.x, 0.0, velocity.z)
	var falling := velocity.y
	var was_floor := is_on_floor()
	move_and_slide()
	_after_move(going, falling, was_floor, wish)


func _lift(target_y: float) -> float:
	return clampf((target_y - global_position.y) * 4.0, -4.0, 4.0)


func _floating() -> bool:
	if not is_finite(_surface):
		return false
	var draft := 0.0 if CarKinds.hovers(kind) else RideRules.DRAFT
	return global_position.y <= _surface - draft + 0.2


func _after_move(going: Vector3, falling: float, was_floor: bool, wish: Vector3) -> void:
	var speed := going.length()
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var body := hit.get_collider() as Node3D
		if body == null or body is StaticBody3D or body is Vehicle or not body is CharacterBody3D or _excepted.has(body):
			continue   # (another car is a wall: the bump below)
		_push(body, going)
		velocity = Vector3(0.0, velocity.y, 0.0)   # it stops for anyone in its way
	if flying:
		var on_water := is_finite(_surface) and global_position.y <= _surface + 0.15
		if (is_on_floor() or on_water) and velocity.y <= 0.05 and (_landing or wish.y < -0.3):
			flying = false
			_landing = false
			host_fx(&"land")
	elif is_on_wall() and _bump_wait <= 0.0 and speed > 2.0:
		var wall := get_wall_normal()
		var flat := Vector3(wall.x, 0.0, wall.z)
		if flat.length() > 0.1 and -going.normalized().dot(flat.normalized()) > 0.5:   # head-on, not a scrape
			_bump_wait = BUMP_EVERY
			var h := _step_ahead(going)
			if VehicleRules.wants_hop(kind, h):
				_hop = h
			else:
				velocity = RideRules.bump(going, wall) + Vector3(0.0, velocity.y, 0.0)
				host_fx(&"thud")
	if CarKinds.bounces(kind) and not was_floor and is_on_floor() and falling < -BOUNCE_FROM:
		velocity.y = -falling * BOUNCE
		host_fx(&"bounce")
	if not has_riders() and is_on_floor() and velocity.length() < VehicleRules.STOP and not flying:
		velocity = Vector3.ZERO
		_awake = false


## Pushes a body in the way gently aside (never in VR: Player.knockback says no there); at most every PUSH_EVERY.
func _push(body: Node3D, going: Vector3) -> void:
	var id := body.get_instance_id()
	if _pushed.has(id) or going.length() < 0.5:
		return
	_pushed[id] = VehicleRules.PUSH_EVERY
	var push := VehicleRules.push_aside(going, global_position, body.global_position)
	if body is Player:
		var peer := (body as Player).peer_id
		if peer == multiplayer.get_unique_id() or multiplayer.get_peers().has(peer):
			Session.send_knockback(peer, push)
	elif body is CharacterBody3D:
		(body as CharacterBody3D).velocity += push
	host_fx(&"beep")


## Host, 10 times a second: the water under it, its ceiling, a step to hop onto, its last safe spot, a fall out of
## the world (carried back), the ground gone from under a parked car.
func _host_decide() -> void:
	var world := Session.world
	if world == null:
		return
	var at := global_position
	_surface = RideRules.water_surface(at + Vector3(0, 0.1, 0), world.get_block) if RideRules.on_water(at, world.get_block) \
		else NAN
	if CarKinds.flies(kind):
		_ceiling = VehicleRules.ceiling_y(kind, world.surface_height(floori(at.x), floori(at.z)) + 1.0)
	if _awake and not flying and driver() != 0 and is_on_wall() and absf(input.z) > 0.3 and _input_age < VehicleRules.INPUT_STALE:
		var dir := Basis(Vector3.UP, rotation.y) * Vector3.FORWARD * signf(input.z)
		var h := _step_ahead(dir)
		if VehicleRules.wants_hop(kind, h) and is_on_floor():
			_hop = h
	_safe_clock -= VehicleRules.DECIDE_EVERY
	if _safe_clock <= 0.0:
		_safe_clock = SAFE_EVERY
		if is_on_floor() and not _floating():
			_safe = at
	if at.y < _fall_line(world) and _safe.is_finite():
		host_place(_safe + Vector3(0, 0.2, 0), rotation.y)
		host_fx(&"puff")
		return
	if not _awake and _loaded(world) and not _supported(world):
		_awake = true


## Its ground is loaded (a chunk nobody is near reads as air and has no collider: a parked car waits there). A world
## of its own (tests) may say so with is_loaded(cell).
func _loaded(world: WorldService) -> bool:
	var cell := Vector3i(global_position.floor()) + Vector3i.DOWN
	if world.has_method(&"is_loaded"):
		return bool(world.call(&"is_loaded", cell))
	return world.get("_tool") == null or world.is_editable(cell)


func _fall_line(world: WorldService) -> float:
	var d := world.descriptor()
	if DragonRules.world_has_void(d, false):
		return DragonRules.rescue_y(d)
	return SpawnRules.FALL_LIMIT_Y


## Solid ground under its middle or a wheel's corner (a parked car digs nothing: it just waits there).
func _supported(world: WorldService) -> bool:
	var b := CarKinds.box(kind)
	var turn := Basis(Vector3.UP, rotation.y)
	for off: Vector3 in [Vector3.ZERO, Vector3(-b.x, 0, -b.z) * 0.4, Vector3(b.x, 0, -b.z) * 0.4,
			Vector3(-b.x, 0, b.z) * 0.4, Vector3(b.x, 0, b.z) * 0.4]:
		var p := global_position + turn * off + Vector3(0, -0.3, 0)
		if BlockIds.is_solid(world.get_block(Vector3i(p.floor()))):
			return true
	return false


## How high the ground rises just ahead of its box going `dir`.
func _step_ahead(dir: Vector3) -> int:
	var world := Session.world
	if world == null:
		return 0
	var half := CarKinds.box(kind).z * 0.5
	return RideRules.climb_height(global_position, dir, half + 0.4,
		func(c: Vector3i) -> bool: return BlockIds.is_solid(world.get_block(c)))


# --- Every game: how it looks and sounds ----------------------------------------------------------------------------

## Host: a sound and a look on every game (the horn, a bump, a bounce, a take-off, a landing, a puff).
func host_fx(what: StringName) -> void:
	_play_fx(what)
	if multiplayer.has_multiplayer_peer() and not multiplayer.get_peers().is_empty():
		_rpc_fx.rpc(what)


@rpc("authority", "call_remote", "unreliable")
func _rpc_fx(what: StringName) -> void:
	_play_fx(what)


func _play_fx(what: StringName) -> void:
	fx_played.emit(what)
	if not is_inside_tree():
		return
	var at := global_position + Vector3(0, CarKinds.box(kind).y * 0.5, 0)
	match what:
		&"horn":
			Audio.play(VehicleSounds.horn(kind), at, -2.0)
		&"thud":
			Audio.play(&"thud", at, -6.0)
		&"beep":
			Audio.play(VehicleSounds.horn(kind), at, -8.0, 1.2)
		&"bounce":
			Audio.play(&"boing", at, -6.0, 0.8)
			_bounce_v = -2.5
		&"lift":
			Audio.play(&"whoosh", at, -6.0)
		&"land":
			Audio.play(&"thud", at, -10.0, 1.3)
		&"puff":
			Audio.play(&"poof", at, -4.0)
			Fx.burst(get_tree().root, at, Color.WHITE, 16, 3.0, 0.14, 0.7, 3.0)
		&"start":
			Audio.play(VehicleSounds.START, at, -6.0, 0.9 if CarKinds.box(kind).y > 2.0 else 1.1)


func _process(delta: float) -> void:
	_t += delta
	if has_riders() and _riders.size() < VehicleRules.riders(seats).size():
		_relink -= delta
		if _relink <= 0.0:
			_relink = RELINK_EVERY
			_link_riders()   # a rider still joining on this game
	var p := global_position
	if _last_pos.is_finite() and delta > 0.0:
		var moved := p - _last_pos
		var fwd := Basis(Vector3.UP, rotation.y) * Vector3.FORWARD
		var now := Vector3(moved.x, 0.0, moved.z).dot(fwd) / delta
		shown_speed = lerpf(shown_speed, clampf(now, -30.0, 30.0), clampf(delta * 10.0, 0.0, 1.0))
	_last_pos = p
	var r := CarKinds.wheel_radius(kind)
	if r > 0.0 and absf(shown_speed) > 0.05:
		_spin = fmod(_spin + shown_speed / r * delta, TAU)
		for w in _wheels:
			var mi := w.get_child(0) as Node3D
			mi.rotation.z = _spin if w.position.x > 0.0 else -_spin
	if not _rotors.is_empty():
		var rate := 24.0 if flying else (8.0 if driver() != 0 else 0.0)
		for i in _rotors.size():
			_rotors[i].rotation.y = fmod(_rotors[i].rotation.y + rate * delta * (1.0 if i % 2 == 0 else -1.0), TAU)
	var y := 0.0
	if CarKinds.hovers(kind):
		y = sin(_t * 2.4) * HOVER_BOB
	if CarKinds.bounces(kind) or _bounce != 0.0 or _bounce_v != 0.0:
		_bounce_v += (-_bounce * 60.0 - _bounce_v * 6.0) * delta   # a soft spring
		_bounce += _bounce_v * delta
		if absf(_bounce) < 0.001 and absf(_bounce_v) < 0.01:
			_bounce = 0.0
			_bounce_v = 0.0
		y += _bounce
	_body.position.y = y
	_engine_sound()


## The engine's hum while someone drives (its pitch with the speed); nothing while parked.
func _engine_sound() -> void:
	var on := driver() != 0 and is_inside_tree()
	if not on:
		if _engine:
			_engine.queue_free()
			_engine = null
		return
	if _engine == null:
		_engine = AudioStreamPlayer3D.new()
		_engine.name = "Engine"
		_engine.stream = VehicleSounds.engine(kind)
		_engine.bus = Audio.BUS
		_engine.unit_size = 5.0
		_engine.max_distance = Audio.HEARING
		_engine.volume_db = ENGINE_DB
		add_child(_engine)
		if _engine.stream:
			_engine.play()
	var top := maxf(CarKinds.speed(kind), CarKinds.fly_speed(kind))
	_engine.pitch_scale = clampf(0.7 + absf(shown_speed) / maxf(top, 1.0) * 0.8 + (0.2 if flying else 0.0), 0.5, 2.0)


## The pickup's load: a few cubes in its bed, meshed from the blocks themselves (the world's own block look).
func _show_cargo() -> void:
	if _cargo_view == null:
		return
	var shown := VehicleRules.cargo_shown(cargo)
	if shown.is_empty():
		_cargo_view.mesh = null
		return
	var buf := VoxelBuffer.new()
	buf.create(4, 4, 4)
	for i in shown.size():
		buf.set_voxel(shown[i], 1 + i % 2, 1 + i / 4, 1 + (i / 2) % 2, VoxelBuffer.CHANNEL_TYPE)
	var mesher := VoxelMesherBlocky.new()
	mesher.library = WorldService.library()
	_cargo_view.mesh = mesher.build_mesh(buf, [], {})
