class_name Arrow
extends Node3D
## An arrow (M1b Task 11). The host spawns it through CombatDirector's spawner with its start
## (origin and velocity), and every peer flies it the same way (WeaponRules.arrow_step), so nothing
## else is sent while it flies. It arcs under gravity and sticks into the first solid block. Only
## the host checks what else it hits (hit_check); it then tells everyone where the arrow stopped.

const STUCK_TIME := 10.0        # seconds an arrow stays stuck before the host removes it
const MAX_FLIGHT := 5.0

var shooter := 1
var power := 1.0
var weapon := ItemIds.BOW          # the bow that shot it (M2 Task 6: a tier's damage)
var velocity := Vector3.ZERO
var stuck := false
var in_block := false
var stuck_cell := Vector3i.ZERO
## is_solid(cell: Vector3i) -> bool, set by whoever spawns it.
var is_solid: Callable
## Host only: hit_check(arrow, from, to) -> bool; true when the arrow hit something on the way.
var hit_check: Callable
var _age := 0.0


## data = {id, origin: Vector3, velocity: Vector3, shooter: int, power: float, weapon: int (a bow tier)}
func setup(data: Dictionary) -> void:
	name = str(data.id)
	position = data.origin
	velocity = data.velocity
	shooter = int(data.shooter)
	power = float(data.power)
	weapon = int(data.get("weapon", ItemIds.BOW))
	if WeaponRules.base_of(weapon) != ItemIds.BOW:
		weapon = ItemIds.BOW
	var mi := MeshInstance3D.new()
	mi.mesh = WeaponModels.arrow()
	add_child(mi)
	_face(velocity)


func _physics_process(delta: float) -> void:
	_age += delta
	if stuck:
		var block_gone: bool = in_block and is_solid.is_valid() and not is_solid.call(stuck_cell)
		if multiplayer.is_server() and (_age > STUCK_TIME or block_gone):
			queue_free()
		return
	var solid := is_solid if is_solid.is_valid() else func(_c: Vector3i) -> bool: return false
	var s := WeaponRules.arrow_step(global_position, velocity, delta, solid)
	if hit_check.is_valid() and hit_check.call(self, global_position, s.pos):
		return
	global_position = s.pos
	velocity = s.vel
	_face(velocity)
	if s.stuck:
		stick(s.pos, velocity, s.cell, true)
		Audio.play(&"thud", global_position, -4.0)
	elif multiplayer.is_server() and (_age > MAX_FLIGHT or global_position.y < WorldService.MIN_Y):
		queue_free()


## Stops the arrow at pos, pointing along dir. in_block: it stuck in the block `cell` (it falls out
## when that block is broken); otherwise it stuck in a target.
func stick(pos: Vector3, dir: Vector3, cell: Vector3i = Vector3i.ZERO, block: bool = false) -> void:
	stuck = true
	in_block = block
	_age = 0.0
	global_position = pos
	stuck_cell = cell
	_face(dir)


## Host -> clients: where the arrow really stopped (in a target, or where the host saw the block).
@rpc("authority", "call_remote", "reliable")
func stick_at(pos: Vector3, dir: Vector3) -> void:
	stick(pos, dir)


func _face(dir: Vector3) -> void:
	if dir.length() > 0.001:
		basis = Basis.looking_at(dir.normalized(), Vector3.UP if absf(dir.normalized().y) < 0.99 else Vector3.RIGHT)
