class_name IceRing
extends Node3D
## The icy ground a Frost Giant's stomp leaves (M3 Task 3), as every game sees it: a flat ring of frost on
## the ground (one shared mesh, the animals' material) for FrostGiantRules.ICY_TIME, shrinking away at the
## end. Only a picture: the slipperiness is IcyGround's, and no block changes. It frees itself.

const MELT := 0.6                 # it shrinks away over its last this many seconds

var _t := 0.0
var _mesh := MeshInstance3D.new()


func _ready() -> void:
	_mesh.mesh = GiantModels.ice_ring_mesh()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)


func _process(delta: float) -> void:
	_t += delta
	var left := FrostGiantRules.ICY_TIME - _t
	if left <= 0.0:
		queue_free()
	elif left < MELT:
		var k := maxf(left / MELT, 0.05)
		scale = Vector3(k, 1.0, k)
