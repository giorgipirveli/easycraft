class_name WavingFlag
extends Node3D
## Owner #94 (the animations brief §2): a flag waving on its pole at a landmark (Mission Control's roof at the Launch
## Site). The cloth is STRIPS narrow strips hinged one to the next, each turning a little later than the one before, so
## a wave runs along it. Vertex-coloured boxes on the Launch Site's own material (no new shader). It sleeps (no turns)
## farther than LifeRules.AWAKE_RANGE from the camera, looked at twice a second. Nothing is sent.

const STRIPS := 5
const CLOTH := Vector2(1.5, 0.9)
const POLE := 2.6
const THICK := 0.04
const WAVE_SPEED := 5.0
const WAVE_LAG := 0.7
const SWING := 0.28
const LOOK_EVERY := 0.5
const TEAL := Color("139e9b")
const GOLD := Color("ffd23f")
const POLE_COLOR := Color("c9ced6")

var hinges: Array[Node3D] = []
var _t := 0.0
var _look := 0.0
var _awake := true


func _init(material: Material = null) -> void:
	name = "WavingFlag"
	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	pole.mesh = _box_mesh(Vector3(0.08, POLE, 0.08), POLE_COLOR, material)
	pole.position = Vector3(0, POLE * 0.5, 0)
	add_child(pole)
	var parent: Node3D = self
	var w := CLOTH.x / STRIPS
	for i in STRIPS:
		var hinge := Node3D.new()
		hinge.name = "Hinge%d" % i
		hinge.position = Vector3(0.04 if i == 0 else w, POLE - CLOTH.y * 0.5 if i == 0 else 0.0, 0)
		parent.add_child(hinge)
		var strip := MeshInstance3D.new()
		strip.mesh = _box_mesh(Vector3(w, CLOTH.y, THICK), GOLD if i == STRIPS / 2 else TEAL, material)
		strip.position = Vector3(w * 0.5, 0, 0)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hinge.add_child(strip)
		hinges.append(hinge)
		parent = hinge


static func _box_mesh(size: Vector3, color: Color, material: Material) -> ArrayMesh:
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
	if material:
		st.set_material(material)
	return st.commit()


func _process(delta: float) -> void:
	_look -= delta
	if _look <= 0.0:
		_look = LOOK_EVERY
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		_awake = cam == null or cam.global_position.distance_to(global_position) < LifeRules.AWAKE_RANGE
	if _awake:
		wave(delta)


## The cloth `delta` seconds on: each strip turns on its hinge a little after the one before.
func wave(delta: float) -> void:
	_t += delta
	for i in hinges.size():
		hinges[i].rotation.y = turn_of(i, _t)


## Strip `i`'s turn on its hinge `t` seconds in (radians).
static func turn_of(i: int, t: float) -> float:
	return SWING * (0.6 + 0.4 * i / STRIPS) * sin(t * WAVE_SPEED - i * WAVE_LAG) * (0.5 if i == 0 else 1.0)


## True while it waves (near the camera).
func awake() -> bool:
	return _awake
