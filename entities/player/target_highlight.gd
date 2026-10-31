class_name TargetHighlight
extends MeshInstance3D
## Dark outline around the block the player is aiming at: 12 thin edge bars, thick enough to see
## on a phone screen.

const THICKNESS := 0.035
const GROW := 0.01


func _ready() -> void:
	top_level = true
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.06, 0.06, 0.1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lo := -GROW
	var hi := 1.0 + GROW
	var len := hi - lo
	var t := THICKNESS
	for a in [lo, hi]:
		for b in [lo, hi]:
			_bar(st, Vector3(lo, a - t * 0.5, b - t * 0.5), Vector3(len, t, t))   # along X
			_bar(st, Vector3(a - t * 0.5, lo, b - t * 0.5), Vector3(t, len, t))   # along Y
			_bar(st, Vector3(a - t * 0.5, b - t * 0.5, lo), Vector3(t, t, len))   # along Z
	st.set_material(mat)
	mesh = st.commit()


## Pass a block position to show it, or null to hide.
func show_block(block_pos: Variant) -> void:
	if block_pos == null:
		visible = false
		return
	global_position = Vector3(block_pos as Vector3i)
	visible = true


func _bar(st: SurfaceTool, origin: Vector3, size: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	var arrays := box.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in indices:
		st.add_vertex(verts[i] + origin + size * 0.5)
