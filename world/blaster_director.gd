class_name BlasterDirector
extends Node
## Blaster shots in a world (M3 Task 14b, spec §13.4). The sandbox adds one on every peer, always named
## "Blasters", so its RPCs line up across the network (like CombatDirector).
## Host: a shot Session checked (blast_requested: the blaster, a sane aim, its rate and reload, Survivor ammo)
## starts at the host's own copy of the shooter's eyes and goes to everyone (_rpc_shot). Every game flies it
## in the same ShotPool (no node per shot); only the host checks what it meets on the way: monsters take the
## blaster's damage and push (a bubble traps a small one, paint slows and marks it), animals are only
## pushed, practice dummies show the hit, the bullseye scores; players, bot friends and buddies are never hit
## (the shot flies on). The Confetti Rocket's blast pushes everything within 4 blocks that it can see.
## Every game shows the bursts (a small pool of particle emitters, never one per hit) and the marks on
## monsters (a see-through bubble, a paint splat that shines through fog), from the host's word.
## The goblin archers' arrows fly in the same pool (monster_arrow): they hit players and bot friends only,
## never through a wall. Nothing here changes a block.

const END_HIT := 0
const MARK_BUBBLE := 0
const MARK_PAINT := 1
const MAX_MARKS := 8              # of each kind
const BURSTS := 10
const CONFETTI_BURSTS := 3
const TEAM_PLAYERS := 0
const TEAM_MONSTERS := 1
const BODY_RADIUS := 0.45         # an arrow hits a player or a friend this close to the chest
const SHOT_START := 0.6           # a shot leaves this far in front of the eyes
const HAND_SHOT_START := 0.05   # owner #124: from a VR player's muzzle, just past it
const PAINT_OVER_HEAD := 0.6

## block_at(pos: Vector3i) -> int: the world, read only (tests replace it).
var block_at: Callable = _world_block

var _pool := ShotPool.new()
var _next_id := 1
var _shots := {}                  # host: shot id -> {blaster, shooter, team, damage}
var _bursts: Array[CPUParticles3D] = []
var _confetti: Array[CPUParticles3D] = []
var _next_burst := 0
var _next_confetti := 0
var _bubble_meshes: Array[MeshInstance3D] = []
var _paint_meshes: Array[MeshInstance3D] = []
var _marks: Array[Dictionary] = []   # {node: WeakRef, kind, left, mesh}
var _things_frame := -1
var _things: Array[Dictionary] = []
var _prewarm_frames := 0


func _ready() -> void:
	_pool.name = "Shots"
	add_child(_pool)
	_pool.is_solid = _is_solid
	_pool.hit_check = _hit_check
	_pool.landed.connect(_on_landed)
	for i in BURSTS:
		_bursts.append(_make_burst(12, 0.12, 0.45, 12.0))
	for i in CONFETTI_BURSTS:
		var c := _make_burst(40, 0.09, 1.2, 5.0)
		c.color = Color.WHITE
		c.color_initial_ramp = Celebration.confetti_colors()
		c.initial_velocity_max = 7.0
		c.damping_min = 1.5
		c.damping_max = 3.0
		_confetti.append(c)
	for i in MAX_MARKS:
		_bubble_meshes.append(_make_mark(BlasterModels.bubble_mesh()))
		_paint_meshes.append(_make_mark(BlasterModels.paint_mark_mesh()))
	Session.blast_requested.connect(_on_blast)


func _world_block(pos: Vector3i) -> int:
	return Session.world.get_block(pos) if Session.world else BlockIds.AIR


func _is_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(block_at.call(cell))


func pool() -> ShotPool:
	return _pool


func active_shots() -> int:
	return _pool.active()


## Marks (bubbles and paint) this game shows now.
func marks_shown() -> int:
	return _marks.size()


func _physics_process(delta: float) -> void:
	_pool.step(delta)


# --- Host: shots ---------------------------------------------------------------------------------------

func _on_blast(peer_id: int, blaster: int, dir: Vector3) -> void:
	spawn_blast(peer_id, blaster, dir)


## Host: a checked shot of `blaster` from the player of `peer_id` along `dir`, for everyone. Returns its id
## (-1 when the player is not there).
func spawn_blast(peer_id: int, blaster: int, dir: Vector3) -> int:
	var p := Session._player_for_peer(peer_id)
	if p == null or not p.is_spawned() or not BlasterRules.is_blaster(blaster) or not BlasterRules.aim_ok(dir):
		return -1
	var d := dir.normalized()
	var id := _new_shot({"blaster": blaster, "shooter": peer_id, "team": TEAM_PLAYERS})
	var from := Session.shot_origin(p)   # owner #124: a VR player's gun in the hand, else the eye
	var start := from + d * (SHOT_START if from == p.eye_position() else HAND_SHOT_START)
	_rpc_shot.rpc(id, blaster, start, BlasterRules.velocity(blaster, d), peer_id)
	StealthDirector.add_noise(p.global_position, StealthRules.NOISE_ATTACK, true)   # monsters hear a shot
	return id


## Host: a goblin archer's arrow from `from` at `velocity`, hurting a player or bot friend it meets by
## `damage` (ArcherRules). Returns its id.
func monster_arrow(from: Vector3, velocity: Vector3, damage: int) -> int:
	if not from.is_finite() or not velocity.is_finite():
		return -1
	var id := _new_shot({"team": TEAM_MONSTERS, "damage": damage})
	_rpc_arrow.rpc(id, from, velocity)
	return id


func _new_shot(data: Dictionary) -> int:
	var id := _next_id
	_next_id += 1
	_shots[id] = data
	if _shots.size() > ShotPool.SIZE * 2:          # forget shots the pool no longer flies (recycled)
		for old: int in _shots.keys():
			if old != id and not _pool.has_shot(old):
				_shots.erase(old)
	return id


## Everyone: a blaster shot starts (the shooter's own game has already played its kick and sound).
@rpc("authority", "call_local", "reliable")
func _rpc_shot(id: int, blaster: int, origin: Vector3, velocity: Vector3, shooter: int) -> void:
	if not BlasterRules.is_blaster(blaster):
		return
	_pool.spawn(id, BlasterModels.shot_look(blaster), origin, velocity, BlasterRules.gravity(blaster),
		BlasterRules.life(blaster))
	if shooter != multiplayer.get_unique_id():
		var p := Session._player_for_peer(shooter)
		if p:
			p.play_attack(blaster, 0)
		Audio.play(BlasterRules.sound(blaster), origin, -2.0)


## Everyone: a goblin's arrow leaves its bow.
@rpc("authority", "call_local", "reliable")
func _rpc_arrow(id: int, from: Vector3, velocity: Vector3) -> void:
	_pool.spawn(id, BlasterModels.GOBLIN_ARROW, from, velocity, ArcherRules.ARROW_GRAVITY, ArcherRules.ARROW_LIFE)
	Audio.play(&"bow", from)


## Host -> guests: a shot hit something at `pos` (the host decided): it ends there.
@rpc("authority", "call_remote", "reliable")
func _rpc_end(id: int, pos: Vector3, _how: int) -> void:
	var look := _pool.shot_look(id)
	_pool.end(id)
	if pos.is_finite() and look != &"":
		_impact(look, pos)


## Host: the pool's check of one step of a shot (every shot, every physics step).
func _hit_check(id: int, p0: Vector3, p1: Vector3) -> bool:
	if not multiplayer.is_server() or not _shots.has(id):
		return false
	var s: Dictionary = _shots[id]
	if int(s.team) == TEAM_MONSTERS:
		return _arrow_hits(id, s, p0, p1)
	var seg := p1 - p0
	var length := maxf(seg.length(), 0.0001)
	var best := {}
	var best_t := INF
	var best_point := Vector3.ZERO
	for thing in _things_now():
		if thing.kind == WeaponRules.PLAYER or thing.kind == WeaponRules.BUDDY:
			continue                                   # never a player, a friend or a buddy: it flies on
		var reach := length + float(thing.radius) + 1.5   # a cheap look first: far things can't be met this step
		if p0.distance_squared_to(thing.pos) > reach * reach:
			continue
		var node: Node = thing.node
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		var t := -1.0
		var point := Vector3.ZERO
		if node is Bullseye:
			var b := node as Bullseye
			point = WeaponRules.segment_hits_disc(p0, p1, b.center(), b.face_normal(), WeaponRules.BULLSEYE_RADIUS)
			t = (point - p0).length() / length if point.is_finite() else -1.0
		else:
			t = WeaponRules.segment_hits_sphere(p0, p1, thing.pos, float(thing.radius) + BlasterRules.SHOT_RADIUS)
			point = p0 + seg * t
		if t >= 0.0 and t < best_t:
			best_t = t
			best = thing
			best_point = point
	if best.is_empty():
		return false
	_hit(id, s, best, best_point, seg / length)
	return true


## Everything a shot can meet, looked up once per physics frame (CombatDirector's list).
func _things_now() -> Array[Dictionary]:
	var frame := Engine.get_physics_frames()
	if frame != _things_frame:
		_things_frame = frame
		_things = CombatDirector.hittables(get_tree())
	return _things


## Host: what a blaster's shot does to what it hit, and the end of the shot everywhere.
func _hit(id: int, s: Dictionary, thing: Dictionary, point: Vector3, dir: Vector3) -> void:
	var blaster := int(s.blaster)
	var look := _pool.shot_look(id)
	_end_everywhere(id, point, look)
	var node: Node = thing.node
	var from := point - dir
	match thing.kind:
		WeaponRules.MONSTER:
			_hit_monster(node, blaster, from, BlasterRules.push(blaster, dir))
		WeaponRules.ANIMAL:
			if node.has_method(&"knockback"):
				node.call(&"knockback", BlasterRules.push(blaster, dir) + Vector3.UP)   # a toy: pushed, never hurt
		_:
			if node is Bullseye:
				(node as Bullseye).show_score.rpc(WeaponRules.bullseye_score(point.distance_to((node as Bullseye).center()),
					WeaponRules.BULLSEYE_RADIUS), point)
			elif node is PracticeTarget:
				(node as PracticeTarget).show_hit.rpc(BlasterRules.damage(blaster), from)
	if BlasterRules.effect(blaster) == BlasterRules.CONFETTI:
		_blast_area(point - dir * 0.1, blaster, node)


## Host: a monster takes a blaster's hit; a bubble traps a small one (a big one is slowed), paint slows and
## marks it. Everyone sees the marks.
func _hit_monster(node: Node, blaster: int, from: Vector3, push: Vector3) -> void:
	if not is_instance_valid(node) or not node.has_method(&"take_hit"):
		return
	var small := node as Monster
	if small != null and BlasterRules.effect(blaster) == BlasterRules.BUBBLE and BlasterRules.bubble_traps(small.level):
		# Owner #53's strong bubble would defeat every small monster before its bubble showed: it floats first and
		# takes the hit when the bubble pops (the same damage over a fight).
		small.blast_bubble(BlasterRules.BUBBLE_TIME, BlasterRules.damage(blaster), from)
		_rpc_mark.rpc(small.get_path(), MARK_BUBBLE, BlasterRules.BUBBLE_TIME)
		return
	node.call(&"take_hit", BlasterRules.damage(blaster), from, push)
	var m := node as Monster
	if m == null or not is_instance_valid(m) or m.is_queued_for_deletion():
		return                                         # defeated (or the boss, a piñata: damage only)
	match BlasterRules.effect(blaster):
		BlasterRules.BUBBLE:   # a big one (a small one floated above)
			m.blast_slow(BlasterRules.BUBBLE_SLOW, BlasterRules.BUBBLE_SLOW_TIME)
		BlasterRules.PAINT:
			m.blast_paint(BlasterRules.PAINT_TIME)
			_rpc_mark.rpc(m.get_path(), MARK_PAINT, BlasterRules.PAINT_TIME)


## Host: the Confetti Rocket's blast at `center`: everything within its radius that it can see (never
## through a wall) is pushed away; monsters take its damage. `skip`: what the rocket hit itself.
func _blast_area(center: Vector3, blaster: int, skip: Node) -> void:
	var radius := BlasterRules.area_radius(blaster)
	for thing in _things_now():
		var node: Node = thing.node
		if node == skip or thing.kind == WeaponRules.PLAYER or thing.kind == WeaponRules.BUDDY:
			continue
		if not is_instance_valid(node) or node.is_queued_for_deletion():
			continue
		if center.distance_to(thing.pos) > radius + float(thing.radius):
			continue
		if not MonsterRules.clear_line(center, thing.pos, _is_solid):
			continue
		var push := BlasterRules.area_push(center, thing.pos)
		match thing.kind:
			WeaponRules.MONSTER:
				_hit_monster(node, blaster, center, push)
			WeaponRules.ANIMAL:
				if node.has_method(&"knockback"):
					node.call(&"knockback", push)
			_:
				if node is PracticeTarget and not node is Bullseye:
					(node as PracticeTarget).show_hit.rpc(BlasterRules.damage(blaster), center)


## Host: a goblin's arrow meets the first player or bot friend on its way (it was already stopped by any
## block: the pool's flight): it hurts them (a shield in front blocks its share) and ends.
func _arrow_hits(id: int, s: Dictionary, p0: Vector3, p1: Vector3) -> bool:
	var best: Node3D = null
	var best_t := INF
	for p in Monster.players_now(get_tree()):
		if p.knocked_out or p.is_hiding():
			continue                                       # a hiding spot keeps its child safe
		var t := WeaponRules.segment_hits_sphere(p0, p1, CombatDirector.chest(p), BODY_RADIUS * p.size_scale())
		if t >= 0.0 and t < best_t:
			best_t = t
			best = p
	for b in Monster.bots_now(get_tree()):
		var chest: Vector3 = b.call(&"chest") if b.has_method(&"chest") else b.global_position + Vector3(0, 1.0, 0)
		var t := WeaponRules.segment_hits_sphere(p0, p1, chest, BODY_RADIUS)
		if t >= 0.0 and t < best_t:
			best_t = t
			best = b
	if best == null:
		return false
	var point := p0.lerp(p1, best_t)
	var dir := (p1 - p0).normalized() if p1 != p0 else Vector3.FORWARD
	_end_everywhere(id, point, BlasterModels.GOBLIN_ARROW)
	var from := point - dir * 2.0
	if best is Player:
		Session.hurt_player((best as Player).peer_id, int(s.damage), from)
	elif best.has_method(&"hurt"):
		best.call(&"hurt", int(s.damage), from)
	return true


func _end_everywhere(id: int, point: Vector3, look: StringName) -> void:
	_shots.erase(id)
	_pool.end(id)
	_impact(look, point)
	if not multiplayer.get_peers().is_empty():
		_rpc_end.rpc(id, point, END_HIT)


## Every game: a shot ended by itself (a block, or its whole flight). The host's rocket blasts there too.
func _on_landed(id: int, look: StringName, pos: Vector3, blocked: bool, vel: Vector3) -> void:
	if blocked or look == BlasterModels.ROCKET or look == BlasterModels.BUBBLE:
		_impact(look, pos)
	if multiplayer.is_server() and _shots.has(id):
		var s: Dictionary = _shots[id]
		_shots.erase(id)
		if int(s.get("team", TEAM_PLAYERS)) == TEAM_PLAYERS and BlasterRules.effect(int(s.blaster)) == BlasterRules.CONFETTI:
			# the blast starts a little back from the wall it met, never inside it (its rays never cross the wall)
			_blast_area(pos - vel.normalized() * 0.15 if vel.length() > 0.001 else pos, int(s.blaster), null)


# --- Every game: bursts and marks -----------------------------------------------------------------------

func _make_burst(amount: int, size: float, lifetime: float, gravity: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.set_meta(&"amount", amount)   # M5 Task 1: Fx.calm halves it with Reduce motion, and puts it back
	p.lifetime = lifetime
	p.explosiveness = 1.0
	p.mesh = Fx._mesh(size)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 4.0
	p.gravity = Vector3(0, -gravity, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	p.local_coords = false
	add_child(p)
	return p


func _make_mark(mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.top_level = true
	mi.visible = false
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## A burst from the pool (never a new node): `color` little cubes at `pos`.
func burst(pos: Vector3, color: Color) -> void:
	var p := _bursts[_next_burst]
	_next_burst = (_next_burst + 1) % _bursts.size()
	p.color = color
	p.global_position = pos
	Fx.calm(p, int(p.get_meta(&"amount", p.amount)))   # M5 Task 1: Reduce motion
	p.restart()


## The rocket's (and a piñata's) confetti from the pool.
func confetti(pos: Vector3) -> void:
	var p := _confetti[_next_confetti]
	_next_confetti = (_next_confetti + 1) % _confetti.size()
	p.global_position = pos
	Fx.calm(p, int(p.get_meta(&"amount", p.amount)))   # M5 Task 1: Reduce motion
	p.restart()


## What a shot looks like when it ends at `pos`, and how it sounds.
func _impact(look: StringName, pos: Vector3) -> void:
	if not is_inside_tree() or not pos.is_finite():
		return
	match look:
		BlasterModels.SNOWBALL:
			burst(pos, BlasterModels.SNOW)
			Audio.play(&"snow_splat", pos, -3.0)
		BlasterModels.PAINT_BLOB:
			burst(pos, BlasterModels.PAINT)
			Audio.play(&"splat", pos, -3.0)
		BlasterModels.BUBBLE:
			burst(pos, Color("dffbff"))
			Audio.play(&"bubble_pop", pos, -3.0)
		BlasterModels.ROCKET:
			confetti(pos)
			Audio.play(&"confetti_boom", pos)
		BlasterModels.GOBLIN_ARROW:
			burst(pos, Color("fff6b0"))
			Audio.play(&"thud", pos, -4.0)
		_:
			burst(pos, Color("ffd23f"))
			Audio.play(&"hit", pos, -8.0)


## Everyone: a monster wears a mark for `seconds` (MARK_BUBBLE or MARK_PAINT).
@rpc("authority", "call_local", "reliable")
func _rpc_mark(path: NodePath, kind: int, seconds: float) -> void:
	var node := get_node_or_null(path) as Node3D
	if node == null or not is_finite(seconds):
		return
	for m in _marks:
		if m.kind == kind and (m.node as WeakRef).get_ref() == node:
			m.left = seconds
			return
	var list := _bubble_meshes if kind == MARK_BUBBLE else _paint_meshes
	for mi in list:
		if not mi.visible:
			mi.visible = true
			_marks.append({"node": weakref(node), "kind": kind, "left": clampf(seconds, 0.0, 30.0), "mesh": mi})
			_place_mark(_marks[-1])
			return


func _process(delta: float) -> void:
	if _prewarm_frames > 0:
		_prewarm_frames -= 1
		if _prewarm_frames == 0:
			for mi in [_bubble_meshes[0], _paint_meshes[0]]:
				if not _marked(mi):
					mi.visible = false
	if _marks.is_empty():
		return
	for m in _marks.duplicate():
		m.left = float(m.left) - delta
		var node := (m.node as WeakRef).get_ref() as Node3D
		if node == null or not is_instance_valid(node) or node.is_queued_for_deletion() or float(m.left) <= 0.0:
			(m.mesh as MeshInstance3D).visible = false
			_marks.erase(m)
		else:
			_place_mark(m)


func _marked(mi: MeshInstance3D) -> bool:
	for m in _marks:
		if m.mesh == mi:
			return true
	return false


func _place_mark(m: Dictionary) -> void:
	var node := (m.node as WeakRef).get_ref() as Node3D
	var mi: MeshInstance3D = m.mesh
	if node == null:
		return
	var size := Vector3(0.8, 1.2, 0.8)
	if node.has_method(&"size"):
		size = node.call(&"size")
	if int(m.kind) == MARK_BUBBLE:
		var r := maxf(maxf(size.x, size.z), size.y) * 0.62 + 0.15
		mi.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * r), node.global_position + Vector3(0, size.y * 0.5, 0))
	else:
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		var b := cam.global_basis if cam else Basis.IDENTITY
		mi.global_transform = Transform3D(b, node.global_position + Vector3(0, size.y + PAINT_OVER_HEAD, 0))


## Compiles the see-through bubble's and the paint mark's shaders as the world appears (a first bubble in
## a fight must not cost a 100 ms frame): both are drawn for two frames in front of the camera.
func prewarm(camera: Camera3D) -> void:
	var at := camera.global_position - camera.global_basis.z * 2.0
	for mi in [_bubble_meshes[0], _paint_meshes[0]]:
		if not _marked(mi):
			mi.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.05), at)
			mi.visible = true
	_prewarm_frames = 2
