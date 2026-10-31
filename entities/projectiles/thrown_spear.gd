class_name ThrownSpear
extends Node3D
## A thrown spear (M2 Task 6, spec §13.1). The host spawns it through CombatDirector's projectile
## spawner and every peer flies it from the same start, like an arrow (WeaponRules.arrow_step with
## SPEAR_GRAVITY). Only the host checks what it hits (hit_check): the first thing hit takes the
## throw's damage and the spear drops from there. It sticks where it lands and waits: its thrower
## walks up to take it back (the host checks), or after SPEAR_RETURN_TIME it flies back by itself.
## A spear is never lost: while it is out, its thrower's hand is empty (Player.spear_out).

## Host only: it went back to its thrower (picked up, returned by itself, or lost in the void).
signal returned(pos: Vector3, picked_up: bool)

const TIP := 1.34               # the model's tip is this far ahead of its grip

var shooter := 1
var weapon := ItemIds.SPEAR
var velocity := Vector3.ZERO
var stuck := false
var dropped := false            # it hit something and falls from there
var in_block := false
var stuck_cell := Vector3i.ZERO
## is_solid(cell: Vector3i) -> bool, set by whoever spawns it.
var is_solid: Callable
## Host only: hit_check(spear, from, to) -> bool; true when it hit something on the way.
var hit_check: Callable
var _age := 0.0
var _mesh := MeshInstance3D.new()


## data = {id, origin: Vector3, velocity: Vector3, shooter: int, weapon: int (a spear tier)}
func setup(data: Dictionary) -> void:
	name = str(data.id)
	position = data.origin
	velocity = data.velocity
	shooter = int(data.shooter)
	weapon = int(data.get("weapon", ItemIds.SPEAR))
	if WeaponRules.base_of(weapon) != ItemIds.SPEAR:
		weapon = ItemIds.SPEAR
	_mesh.mesh = WeaponModels.mesh_for(weapon)
	var tier := WeaponRules.tier_of(weapon)
	_mesh.material_override = WeaponModels.tier_material(tier) if tier > WeaponRules.TIER_WOOD else null
	_mesh.position = Vector3(0, 0, TIP)     # the tip at this node's origin, the shaft trailing (+Z)
	add_child(_mesh)
	add_to_group(&"spears")
	_face(velocity)


func _physics_process(delta: float) -> void:
	_age += delta
	if stuck:
		if in_block and is_solid.is_valid() and not is_solid.call(stuck_cell):
			stuck = false                    # its block was broken: it falls again
			dropped = true
			velocity = Vector3.ZERO
			_age = 0.0
		elif multiplayer.is_server():
			_host_waiting()
		return
	var solid := is_solid if is_solid.is_valid() else func(_c: Vector3i) -> bool: return false
	var s := WeaponRules.arrow_step(global_position, velocity, delta, solid, WeaponRules.SPEAR_GRAVITY)
	if not dropped and hit_check.is_valid() and hit_check.call(self, global_position, s.pos):
		return
	global_position = s.pos
	velocity = s.vel
	if not dropped:
		_face(velocity)
	if s.stuck:
		stick(s.pos, s.cell)
		Audio.play(&"thud", global_position, -4.0)
	elif multiplayer.is_server() and (_age > WeaponRules.SPEAR_MAX_FLIGHT or global_position.y < WorldService.MIN_Y):
		_go_home(false)


## Stops it at pos, stuck in the block `cell` (it falls again when that block is broken).
func stick(pos: Vector3, cell: Vector3i) -> void:
	stuck = true
	in_block = true
	stuck_cell = cell
	_age = 0.0
	global_position = pos


## Host -> everyone (the host calls it directly too): it hit something at pos and drops from there.
@rpc("authority", "call_remote", "reliable")
func drop_at(pos: Vector3) -> void:
	dropped = true
	stuck = false            # this game's copy may have stuck in a wall just before the host's word
	in_block = false
	global_position = pos
	velocity = Vector3(0, -1.0, 0)


## Host: while it waits on the ground, its thrower takes it back by walking up; after a while it
## comes back by itself (also when its thrower has left the game).
func _host_waiting() -> void:
	var feet := _thrower_feet()
	if feet.is_finite() and WeaponRules.can_pick_up(global_position, feet):
		_go_home(true)
	elif _age > WeaponRules.SPEAR_RETURN_TIME:
		_go_home(false)


func _go_home(picked_up: bool) -> void:
	if is_queued_for_deletion():
		return
	returned.emit(global_position, picked_up)
	queue_free()


func _thrower_feet() -> Vector3:
	for n in get_tree().get_nodes_in_group(&"players"):
		var p := n as Player
		if p and p.peer_id == shooter and not p.is_queued_for_deletion():
			return p.global_position
	return Vector3.INF


func _face(dir: Vector3) -> void:
	if dir.length() > 0.001:
		basis = Basis.looking_at(dir.normalized(), Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.RIGHT)
