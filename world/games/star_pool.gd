class_name StarPool
extends Node3D
## Storm Run's stars on every game (M4 Wave 3, agent H): StormRun.MAX_STARS star meshes made once and
## reused (never a node per star), one five-pointed star mesh and one material (shaders/game_star.gdshader:
## the stars turn and bob on the GPU) shared by all. The host's GamesDirector says where a star is and
## when it goes (taken: a burst of gold and a coin sound; left outside the circle: a small puff).

const SHADER := preload("res://shaders/game_star.gdshader")
const OUTER := 0.45
const INNER := 0.2
const DEPTH := 0.14
const TAKEN_COLOR := Color("ffd23f")
const GONE_COLOR := Color(0.75, 0.8, 1.0)

static var _mesh: ArrayMesh
static var _material: ShaderMaterial

var _free: Array[MeshInstance3D] = []
var _shown := {}                  # star id -> MeshInstance3D


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material


## A flat five-pointed star facing +Z, DEPTH thick, centred on the origin.
static func star_mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim: Array[Vector2] = []
	for i in 10:
		var r := OUTER if i % 2 == 0 else INNER
		var a := PI * 0.5 + float(i) * TAU / 10.0
		rim.append(Vector2(cos(a), sin(a)) * r)
	for side in [1.0, -1.0]:
		var z: float = DEPTH * 0.5 * side
		for i in 10:
			var a := rim[i]
			var b := rim[(i + 1) % 10]
			st.set_normal(Vector3(0, 0, side))
			st.add_vertex(Vector3(0, 0, z))
			st.add_vertex(Vector3(a.x, a.y, z) if side > 0.0 else Vector3(b.x, b.y, z))
			st.add_vertex(Vector3(b.x, b.y, z) if side > 0.0 else Vector3(a.x, a.y, z))
	for i in 10:
		var a := rim[i]
		var b := rim[(i + 1) % 10]
		var n := Vector3(b.y - a.y, a.x - b.x, 0).normalized()
		var f := DEPTH * 0.5
		st.set_normal(n)
		for v: Vector3 in [Vector3(a.x, a.y, f), Vector3(a.x, a.y, -f), Vector3(b.x, b.y, f),
				Vector3(b.x, b.y, f), Vector3(a.x, a.y, -f), Vector3(b.x, b.y, -f)]:
			st.add_vertex(v)
	_mesh = st.commit()
	return _mesh


func _ready() -> void:
	top_level = true
	for i in StormRun.MAX_STARS:
		var m := MeshInstance3D.new()
		m.name = "Star%d" % i
		m.mesh = star_mesh()
		m.material_override = material()
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.top_level = true
		m.visible = false
		add_child(m)
		_free.append(m)


func count() -> int:
	return _shown.size()


func has_star(id: int) -> bool:
	return _shown.has(id)


## Shows star `id` at `pos` (its centre); false when the pool is used up (never more than MAX_STARS).
func show_star(id: int, pos: Vector3) -> bool:
	if _shown.has(id):
		(_shown[id] as MeshInstance3D).global_position = pos
		return true
	if _free.is_empty() or not pos.is_finite():
		return false
	var m: MeshInstance3D = _free.pop_back()
	m.position = pos
	m.visible = true
	_shown[id] = m
	return true


## Star `id` goes: taken (gold burst, a coin sound) or left outside the circle (a puff).
func hide_star(id: int, taken: bool) -> void:
	var m := _shown.get(id) as MeshInstance3D
	if m == null:
		return
	_shown.erase(id)
	m.visible = false
	_free.append(m)
	if not is_inside_tree():
		return
	if taken:
		Fx.burst(get_tree().root, m.position, TAKEN_COLOR, 14, 4.0, 0.1, 0.6, 5.0)
		Audio.play(&"coin", m.position)
	else:
		Fx.burst(get_tree().root, m.position, GONE_COLOR, 6, 2.0, 0.08, 0.5, 2.0)


func clear() -> void:
	for id: int in _shown.keys():
		var m: MeshInstance3D = _shown[id]
		m.visible = false
		_free.append(m)
	_shown.clear()
