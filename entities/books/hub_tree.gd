class_name HubTree
extends Node3D
## The Hub Tree (M3 Task 21b; research R1) beside the portal hub's stone circle: its trunk, a leafy crown for every
## universe the world's owner explored, a glowing fruit for every boss beaten, a golden star for every Secret Book
## page done (HubTreeRules). Not blocks (it never changes the world): one mesh per tree state, cached, made of
## boxes — the trunk and crowns on BlockyAnimal's shared material, the fruits and stars on one shared unshaded
## material (they shine at night). No collision (like the circle's stones). Every game builds it where the rules
## say (from the seed) and shows the owner's state (BooksDirector).

static var _meshes := {}   # HubTreeRules.key -> ArrayMesh
static var _glow: StandardMaterial3D

var state: Dictionary = HubTreeRules.clean({})
var _mesh := MeshInstance3D.new()


func _ready() -> void:
	name = "HubTree"
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	_mesh.mesh = mesh_for(state)


## Shows state `s` (HubTreeRules.clean'd): a new mesh only when it changed.
func set_state(s: Dictionary) -> void:
	var clean := HubTreeRules.clean(s)
	if HubTreeRules.key(clean) == HubTreeRules.key(state) and _mesh.mesh != null:
		return
	state = clean
	if is_inside_tree():
		_mesh.mesh = mesh_for(state)


func shown_mesh() -> Mesh:
	return _mesh.mesh


## The tree of state `s` as one mesh (two surfaces), made once per state.
static func mesh_for(s: Dictionary) -> ArrayMesh:
	var key := HubTreeRules.key(s)
	if not _meshes.has(key):
		var b := HubTreeRules.boxes(s)
		var mesh := BlockyAnimal._build(b.lit)
		if not (b.glow as Array).is_empty():
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for box: Array in b.glow:
				BlockyAnimal._box(st, box[0], box[1], box[2])
			st.set_material(glow_material())
			st.commit(mesh)
		_meshes[key] = mesh
	return _meshes[key]


static func glow_material() -> StandardMaterial3D:
	if _glow == null:
		_glow = StandardMaterial3D.new()
		_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glow.vertex_color_use_as_albedo = true
		_glow.vertex_color_is_srgb = true
	return _glow
