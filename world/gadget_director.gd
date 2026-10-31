class_name GadgetDirector
extends Node
## The action kit's gadgets in a world (M3 Task 14a, spec §13.3). The sandbox adds one on every peer, always
## named "Gadgets", so its RPCs line up across the network.
## Host: Session checks every use (section "M3 Task 14a"); here a checked orb flies (GadgetRules.orb_path:
## the first block its arc meets, followed once per throw) and bursts: the Boing Orb pushes monsters away
## and bounces players up (never damage), the Dance Orb makes monsters in its bubble dance 5 s (bosses 2 s,
## at most once in 20 s). A hook's rope and a quick build's puff are sent to every game.
## Every peer: thrown orbs fly the same arc (a small pool of shared-mesh orbs, never a node or material per
## throw), bursts and music notes over dancers (Fx's shared material), the rope of other players' hooks.

## Host: an orb burst (tests): what it caught.
signal burst_done(item: int, point: Vector3, caught: Array)

const POOL_SIZE := 8
const NOTE_EVERY := 0.5
const BOING_COLOR := Color("56c8ff")
const DANCE_COLORS: Array[Color] = [Color("ff7ad9"), Color("ffd23f"), Color("8cf07a")]
const BUILD_PUFF := Color("f3e6c8")

## Host: block_at(cell: Vector3i) -> int (tests use stubs).
var block_at: Callable = _world_block
## Host: the clock (seconds) for the bosses' dance gap (tests set their own).
var now_s: Callable = func() -> float: return Time.get_ticks_msec() / 1000.0

var _pending: Array = []        # host: [seconds until it bursts, item, point, thrower]
var _flying: Array = []         # every peer: [MeshInstance3D, from, velocity, t, seconds]
var _pool: Array[MeshInstance3D] = []
var _dancers := {}              # every peer: instance id -> [node, seconds left, seconds to the next note]
var _boss_danced := {}          # host: boss instance id -> now_s of its last dance
var _holder := Node3D.new()


func _ready() -> void:
	_holder.name = "Orbs"
	_holder.top_level = true
	add_child(_holder)
	Session.gadget_orb_thrown.connect(_on_orb_thrown)
	Session.gadget_hooked.connect(_on_hooked)
	Session.gadget_built.connect(_on_built)


func _world_block(cell: Vector3i) -> int:
	return Session.world.get_block(cell) if Session.world else BlockIds.AIR


func _is_solid(cell: Vector3i) -> bool:
	return BlockIds.is_solid(block_at.call(cell))

# --- Host -------------------------------------------------------------------------------------------------

## Host: a checked throw: every game flies it; it bursts where its arc meets a block.
func _on_orb_thrown(peer_id: int, item: int, from: Vector3, velocity: Vector3) -> void:
	var path := GadgetRules.orb_path(from, velocity, _is_solid)
	_pending.append([float(path.time), item, path.point, peer_id])
	_rpc_orb.rpc(item, from, velocity, float(path.time))


func _physics_process(delta: float) -> void:
	if _pending.is_empty() or not multiplayer.is_server():
		return
	for i in range(_pending.size() - 1, -1, -1):
		var p: Array = _pending[i]
		p[0] = float(p[0]) - delta
		if p[0] <= 0.0:
			_pending.remove_at(i)
			burst(int(p[1]), p[2], int(p[3]))


## Host: an orb bursts at `point`. Returns the monsters (and, for the Boing Orb, players) it caught.
func burst(item: int, point: Vector3, _thrower: int = 0) -> Array:
	var caught: Array = []
	var dancers: Array = []
	var seconds := 0.0
	for n in get_tree().get_nodes_in_group(&"monsters"):
		var m := n as Node3D
		if m == null or m.is_queued_for_deletion():
			continue
		var at: Vector3 = m.call(&"hit_center") if m.has_method(&"hit_center") else m.global_position
		if not GadgetRules.in_bubble(point, at):
			continue
		if item == ItemIds.IMPULSE_ORB:
			if m.has_method(&"take_hit"):
				m.call(&"take_hit", GadgetRules.ORB_DAMAGE, point, GadgetRules.impulse_push(point, m.global_position))
				caught.append(m)
		elif m.has_method(&"dance"):
			var boss := m is StoneGolem
			var id := m.get_instance_id()
			var secs := GadgetRules.dance_seconds(boss, float(_boss_danced.get(id, -1.0)), float(now_s.call()))
			if secs <= 0.0:
				continue
			if boss:
				_boss_danced[id] = float(now_s.call())
			m.call(&"dance", secs)
			caught.append(m)
			dancers.append(m.get_path())
			seconds = maxf(seconds, secs)
	if item == ItemIds.IMPULSE_ORB:
		for p in Monster.players_now(get_tree()):
			if is_instance_valid(p) and GadgetRules.in_bubble(point, p.global_position):
				Session.send_knockback(p.peer_id, GadgetRules.impulse_bounce(point, p.global_position))
				caught.append(p)
	_rpc_burst.rpc(item, point, dancers, seconds)
	burst_done.emit(item, point, caught)
	return caught


func _on_hooked(peer_id: int, point: Vector3) -> void:
	_rpc_hook.rpc(peer_id, point)


func _on_built(_peer_id: int, _item: int, center: Vector3) -> void:
	_rpc_built.rpc(center)


## Host: the orbs on their way (tests).
func pending() -> int:
	return _pending.size()

# --- Every peer ---------------------------------------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func _rpc_orb(item: int, from: Vector3, velocity: Vector3, seconds: float) -> void:
	if not GadgetRules.is_orb(item) or not from.is_finite() or not velocity.is_finite() or not is_finite(seconds):
		return
	var orb := _take_orb()
	orb.mesh = GadgetModels.orb(item)
	orb.position = from
	orb.visible = true
	_flying.append([orb, from, velocity, 0.0, clampf(seconds, 0.0, GadgetRules.ORB_MAX_TIME)])
	Audio.play(&"swing", from, -4.0)


@rpc("authority", "call_local", "reliable")
func _rpc_burst(item: int, point: Vector3, dancers: Array, seconds: float) -> void:
	if not point.is_finite():
		return
	var root := get_tree().root
	if item == ItemIds.IMPULSE_ORB:
		Fx.burst(root, point, BOING_COLOR, 26, 9.0, 0.16, 0.6, 4.0)
		Audio.play(&"boing", point, 3.0)
	else:
		for i in DANCE_COLORS.size():
			Fx.burst(root, point + Vector3.UP * 0.3, DANCE_COLORS[i], 10, 5.0, 0.14, 0.8, 1.0)
		Audio.play(&"ding", point)
	for path: Variant in dancers:
		if not path is NodePath:
			continue
		var node := get_node_or_null(path) as Node3D
		if node:
			_dancers[node.get_instance_id()] = [node, clampf(seconds, 0.0, GadgetRules.DANCE_TIME), 0.0]


## Another player's hook holds at `point`: its rope shows in this game (its own game already knows).
@rpc("authority", "call_local", "reliable")
func _rpc_hook(peer_id: int, point: Vector3) -> void:
	if not point.is_finite():
		return
	var p := Session._player_for_peer(peer_id)
	if p and not p.is_multiplayer_authority():
		p.hook_point = point
	Audio.play(&"hit", point, -6.0)


@rpc("authority", "call_local", "reliable")
func _rpc_built(center: Vector3) -> void:
	if center.is_finite():
		Fx.burst(get_tree().root, center, BUILD_PUFF, 22, 5.0, 0.16, 0.6, 3.0)
		Audio.play(&"place", center)


func _process(delta: float) -> void:
	for i in range(_flying.size() - 1, -1, -1):
		var f: Array = _flying[i]
		var orb: MeshInstance3D = f[0]
		f[3] = float(f[3]) + delta
		if float(f[3]) >= float(f[4]) or not is_instance_valid(orb):
			if is_instance_valid(orb):
				orb.visible = false
			_flying.remove_at(i)
			continue
		orb.position = GadgetRules.orb_position(f[1], f[2], f[3])
		orb.rotation.y += delta * 8.0
	for id: int in _dancers.keys():
		var d: Array = _dancers[id]
		var node: Node3D = d[0]
		d[1] = float(d[1]) - delta
		d[2] = float(d[2]) - delta
		if not is_instance_valid(node) or float(d[1]) <= 0.0:
			_dancers.erase(id)
			continue
		if float(d[2]) <= 0.0:
			d[2] = NOTE_EVERY
			var top: Vector3 = node.global_position + Vector3.UP * 1.6
			Fx.burst(get_tree().root, top, DANCE_COLORS[randi() % DANCE_COLORS.size()], 4, 1.5, 0.12, 0.7, -1.5, 30.0)


func _take_orb() -> MeshInstance3D:
	for orb in _pool:
		if not orb.visible:
			return orb
	if _pool.size() >= POOL_SIZE:   # all out: the oldest one comes back to be thrown again
		var oldest: MeshInstance3D = _flying[0][0]
		_flying.remove_at(0)
		return oldest
	var orb := MeshInstance3D.new()
	orb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_holder.add_child(orb)
	_pool.append(orb)
	return orb


## Every peer: the orb nodes made so far (tests: never more than POOL_SIZE) and those in the air.
func orb_nodes() -> int:
	return _pool.size()


func orbs_flying() -> int:
	return _flying.size()


func dancers() -> int:
	return _dancers.size()
