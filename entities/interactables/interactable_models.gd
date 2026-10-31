class_name InteractableModels
extends RefCounted
## Shared models of the secrets' things (M2 Task 16): box-built, vertex-coloured meshes made once and used
## by every chest, note and Wanderer, a glow quad per rarity (§13.2) and the falling star. Nothing here is
## made per event (the Fx lesson: a material per burst recompiled its shader, a 100+ ms frame).

const WOOD := Color("9c6b34")
const WOOD_LIGHT := Color("b8834a")
const WOOD_DARK := Color("6e4522")
const GOLD := Color("f2c230")
const GOLD_LIGHT := Color("ffe27a")
const GOLD_DARK := Color("b8860b")
## The lid turns around its back edge (local +Z, models face -Z).
const LID_PIVOT := Vector3(0, 0.46, 0.25)

static var _meshes := {}
static var _material: StandardMaterial3D
static var _glow_materials := {}
static var _glow_mesh: QuadMesh
static var _shine: StandardMaterial3D


## The chest's box (its front faces -Z). A sky island's chest is golden.
static func chest_base(golden: bool) -> ArrayMesh:
	var key := "base_gold" if golden else "base"
	if not _meshes.has(key):
		var body := GOLD if golden else WOOD
		var band := GOLD_LIGHT if golden else GOLD
		_meshes[key] = _build([
			[Vector3(0, 0.23, 0), Vector3(0.8, 0.46, 0.5), body],
			[Vector3(0, 0.23, -0.255), Vector3(0.82, 0.08, 0.02), band],       # a band round the front
			[Vector3(-0.3, 0.23, -0.255), Vector3(0.06, 0.46, 0.02), band],
			[Vector3(0.3, 0.23, -0.255), Vector3(0.06, 0.46, 0.02), band],
			[Vector3(0, 0.36, -0.265), Vector3(0.12, 0.14, 0.03), GOLD_LIGHT],   # the lock
			[Vector3(0, 0.33, -0.28), Vector3(0.04, 0.05, 0.01), Color("2a2230")],
		])
	return _meshes[key]


## The lid, around LID_PIVOT (so it swings open by turning about x).
static func chest_lid(golden: bool) -> ArrayMesh:
	var key := "lid_gold" if golden else "lid"
	if not _meshes.has(key):
		var top := GOLD_LIGHT if golden else WOOD_LIGHT
		var band := GOLD_DARK if golden else GOLD
		_meshes[key] = _build([
			[Vector3(0, 0.1, -0.25), Vector3(0.82, 0.2, 0.52), top],
			[Vector3(-0.3, 0.1, -0.25), Vector3(0.07, 0.21, 0.53), band],
			[Vector3(0.3, 0.1, -0.25), Vector3(0.07, 0.21, 0.53), band],
		])
	return _meshes[key]


## A riddle note: a paper on a little wooden stand.
static func note() -> ArrayMesh:
	if not _meshes.has("note"):
		_meshes["note"] = _build([
			[Vector3(0, 0.3, 0.02), Vector3(0.08, 0.6, 0.08), WOOD_DARK],
			[Vector3(0, 0.62, 0), Vector3(0.5, 0.36, 0.06), WOOD],
			[Vector3(0, 0.63, -0.035), Vector3(0.42, 0.3, 0.01), Color("fbf6e4")],
			[Vector3(0, 0.7, -0.042), Vector3(0.3, 0.02, 0.005), Color("8a8a96")],
			[Vector3(0, 0.64, -0.042), Vector3(0.3, 0.02, 0.005), Color("8a8a96")],
			[Vector3(-0.04, 0.58, -0.042), Vector3(0.22, 0.02, 0.005), Color("8a8a96")],
			[Vector3(0, 0.02, 0.02), Vector3(0.3, 0.04, 0.25), WOOD_DARK],
		])
	return _meshes["note"]


## The Wanderer: a hooded purple robe, a dark face, a staff with a star (faces -Z; eyes: wanderer_eyes).
static func wanderer() -> ArrayMesh:
	if not _meshes.has("wanderer"):
		var robe := Color("5b3f8c")
		var dark := Color("3f2a66")
		_meshes["wanderer"] = _build([
			[Vector3(0, 0.45, 0), Vector3(0.7, 0.9, 0.55), robe],
			[Vector3(0, 1.1, 0), Vector3(0.56, 0.5, 0.45), robe],
			[Vector3(0, 1.55, 0.02), Vector3(0.52, 0.5, 0.5), dark],           # hood
			[Vector3(0, 1.82, 0.1), Vector3(0.3, 0.14, 0.3), dark],
			[Vector3(0, 1.5, -0.2), Vector3(0.36, 0.34, 0.12), Color("140f1e")],  # the face in shadow
			[Vector3(0, 0.95, -0.01), Vector3(0.6, 0.08, 0.5), Color("c9a24a")],  # belt
			[Vector3(-0.42, 0.9, -0.05), Vector3(0.14, 0.5, 0.14), robe],        # arm holding the staff
			[Vector3(-0.52, 0.95, -0.12), Vector3(0.07, 1.9, 0.07), WOOD],       # staff
			[Vector3(0.3, 0.9, -0.05), Vector3(0.14, 0.46, 0.14), robe],
		])
	return _meshes["wanderer"]


## The Wanderer's glowing eyes and the star on his staff (drawn unshaded, so they shine at dusk).
static func wanderer_eyes() -> ArrayMesh:
	if not _meshes.has("eyes"):
		_meshes["eyes"] = _build([
			[Vector3(-0.08, 1.53, -0.27), Vector3(0.07, 0.05, 0.02), Color("9ff3ff")],
			[Vector3(0.08, 1.53, -0.27), Vector3(0.07, 0.05, 0.02), Color("9ff3ff")],
			[Vector3(-0.52, 1.95, -0.12), Vector3(0.22, 0.22, 0.08), Color("ffd23f")],
			[Vector3(-0.52, 1.95, -0.12), Vector3(0.08, 0.32, 0.09), Color("fff3a8")],
		], shine())
	return _meshes["eyes"]


## A falling star: a small bright block (unshaded).
static func star() -> ArrayMesh:
	if not _meshes.has("star"):
		_meshes["star"] = _build([
			[Vector3.ZERO, Vector3(0.6, 0.6, 0.6), Color("fff3a8")],
			[Vector3.ZERO, Vector3(0.9, 0.25, 0.25), Color("ffd23f")],
			[Vector3.ZERO, Vector3(0.25, 0.9, 0.25), Color("ffd23f")],
			[Vector3.ZERO, Vector3(0.25, 0.25, 0.9), Color("ffd23f")],
		], shine())
	return _meshes["star"]


## A flat picture tile lying on the ground (a temple plate's picture); material: Pictures.material(id).
static func picture_quad() -> PlaneMesh:
	if not _meshes.has("picture"):
		var p := PlaneMesh.new()
		p.size = Vector2(0.8, 0.8)
		_meshes["picture"] = p
	return _meshes["picture"]


## The soft halo behind an unopened chest, in its rarity's colour (one material per rarity).
static func glow_quad() -> QuadMesh:
	if _glow_mesh == null:
		_glow_mesh = QuadMesh.new()
		_glow_mesh.size = Vector2(1.5, 1.5)
	return _glow_mesh


static func glow_material(rarity: int) -> StandardMaterial3D:
	if not _glow_materials.has(rarity):
		var tex := GradientTexture2D.new()
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.9))
		g.set_color(1, Color(1, 1, 1, 0.0))
		tex.gradient = g
		var m := StandardMaterial3D.new()
		m.albedo_texture = tex
		m.albedo_color = LootRules.rarity_color(rarity)
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_glow_materials[rarity] = m
	return _glow_materials[rarity]


## The unshaded vertex-colour material of things that shine.
static func shine() -> StandardMaterial3D:
	if _shine == null:
		_shine = StandardMaterial3D.new()
		_shine.vertex_color_use_as_albedo = true
		_shine.vertex_color_is_srgb = true
		_shine.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return _shine


static func _build(boxes: Array, material: StandardMaterial3D = null) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b: Array in boxes:
		_box(st, b[0], b[1], b[2])
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.8
	st.set_material(material if material != null else _material)
	return st.commit()


static func _box(st: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3.RIGHT, Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)],
		[Vector3.LEFT, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3.UP, Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3.DOWN, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)],
		[Vector3.BACK, Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)],
		[Vector3.FORWARD, Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)],
	]
	for f: Array in faces:
		st.set_color(color)
		st.set_normal(f[0])
		for i in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(center + (f[1 + i] as Vector3))
