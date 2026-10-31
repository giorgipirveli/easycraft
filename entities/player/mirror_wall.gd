class_name MirrorWall
extends MeshInstance3D
## Translucent glowing wall that shows where Mirror mode's mirror plane is.

const SIZE := Vector2(40, 36)


func _ready() -> void:
	top_level = true
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var quad := QuadMesh.new()
	quad.size = SIZE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.4, 0.9, 1.0, 0.16)
	quad.material = mat
	mesh = quad


## The wall runs through the middle of block column `plane` along the given axis.
func show_at(axis: int, plane: int, near: Vector3) -> void:
	if axis == MirrorRules.Axis.X:
		global_position = Vector3(plane + 0.5, near.y + 6.0, near.z)
		rotation = Vector3(0, PI / 2.0, 0)
	else:
		global_position = Vector3(near.x, near.y + 6.0, plane + 0.5)
		rotation = Vector3.ZERO
	visible = true
