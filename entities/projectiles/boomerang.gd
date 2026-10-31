class_name Boomerang
extends Node3D
## A thrown boomerang (M1b Task 11): it spins out along the throw, turns back at its range or at
## a wall, and flies home to the thrower (WeaponRules.boomerang_step). Every peer flies it from
## the same start; only the host checks hits (each thing once per throw) and removes it when caught.

const SPIN := 22.0              # radians per second
const HAND_HEIGHT := 1.2

var shooter := 1
var state := {}
var hit := {}                   # instance ids already hit on this throw (host)
## is_solid(cell: Vector3i) -> bool, set by whoever spawns it.
var is_solid: Callable
## Host only: hit_check(boomerang, from, to).
var hit_check: Callable
var _mesh := MeshInstance3D.new()
var _was_returning := false


## data = {id, origin: Vector3, dir: Vector3, shooter: int}
func setup(data: Dictionary) -> void:
	name = str(data.id)
	shooter = int(data.shooter)
	position = data.origin
	state = WeaponRules.boomerang_start(data.origin, data.dir)
	_mesh.mesh = WeaponModels.mesh_for(ItemIds.BOOMERANG)
	_mesh.scale = Vector3.ONE * 1.4
	add_child(_mesh)
	add_to_group(&"boomerangs")


## Where it flies home to: the thrower's hand, or where it was thrown from if they left.
func home() -> Vector3:
	for p: Node in get_tree().get_nodes_in_group(&"players"):
		if p is Player and (p as Player).peer_id == shooter:
			return (p as Player).global_position + Vector3(0, HAND_HEIGHT * (p as Player).size_scale(), 0)
	return state.get("pos", global_position)


func _physics_process(delta: float) -> void:
	if state.is_empty() or state.caught:
		return
	var from: Vector3 = state.pos
	var solid := is_solid if is_solid.is_valid() else func(_c: Vector3i) -> bool: return false
	state = WeaponRules.boomerang_step(state, home(), delta, solid)
	global_position = state.pos
	_mesh.rotation.y += SPIN * delta
	if state.returning and not _was_returning:
		_was_returning = true
		Audio.play(&"whirr", global_position, -3.0)
	if hit_check.is_valid():
		hit_check.call(self, from, global_position)
	if state.caught:
		visible = false
		if multiplayer.is_server():
			queue_free()
