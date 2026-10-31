class_name Blinker
extends Node3D
## Owner #94 (the animations brief §2): a light that blinks, like the Launch Site tower's red warning light: a glowing
## box (the golem's glow: unshaded vertex colours, no new shader) on for ON_SHARE of every PERIOD. Each frame only
## counts; the light is shown or hidden twice a period. Nothing is sent.

const PERIOD := 1.2
const ON_SHARE := 0.4

var light := MeshInstance3D.new()
var _t := 0.0


## A blinking light of `size` and `color` (its own tiny vertex-coloured box, made once).
func _init(size: Vector3 = Vector3.ONE * 0.55, color: Color = Color("ff3b2f")) -> void:
	name = "Blinker"
	light.name = "Light"
	light.mesh = glow_box(size, color)
	light.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(light)


## A box whose vertices carry `color`, with the golem's glow.
static func glow_box(size: Vector3, color: Color) -> ArrayMesh:
	var box := BoxMesh.new()
	box.size = size
	var arrays := box.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in index:
		st.set_color(color)
		st.set_normal(normals[i])
		st.add_vertex(verts[i])
	st.set_material(GolemModels.glow_material())
	return st.commit()


func _process(delta: float) -> void:
	_t += delta
	var on := lit_at(_t)
	if light.visible != on:   # a visibility change only twice a period
		light.visible = on


## True while the light is on, `t` seconds in.
static func lit_at(t: float) -> bool:
	return fposmod(t, PERIOD) < PERIOD * ON_SHARE
