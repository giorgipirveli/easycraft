class_name ProspectModels
extends RefCounted
## Prospecting's models (spec §26: Gemma's camp, the oil well) as vertex-coloured boxes in one mesh per moving part, with
## the Theater's shared material exactly (vertex colours, roughness 0.9: its shaders are warmed already, like
## LaunchBuildings'): a camp or a well is a handful of draw calls. A box is [size, centre, colour, rotation (euler,
## optional)], its sides a little darker than its top, like the blocks.

static var _material: StandardMaterial3D


static func shared_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.9   # the Theater's material: its shaders are warmed already
	return _material


## The boxes as one mesh.
static func mesh(boxes: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b: Array in boxes:
		_box(st, b[0], b[1], b[2], b[3] if b.size() > 3 else Vector3.ZERO)
	st.set_material(shared_material())
	return st.commit()


## A MeshInstance3D of the boxes under `parent` (no shadow: small props).
static func add(parent: Node3D, boxes: Array, name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = name
	mi.mesh = mesh(boxes)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## A billboard label over a model.
static func label(parent: Node3D, text: String, pos: Vector3, font_size: int = 40) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.outline_size = 10
	l.pixel_size = 0.005
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l


static func _box(st: SurfaceTool, size: Vector3, centre: Vector3, c: Color, rot: Vector3) -> void:
	var basis := Basis.from_euler(rot)
	var h := size * 0.5
	var faces := [
		[Vector3.UP, [Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)], 1.0],
		[Vector3.DOWN, [Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z)], 0.6],
		[Vector3.FORWARD, [Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)], 0.85],
		[Vector3.BACK, [Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)], 0.85],
		[Vector3.LEFT, [Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)], 0.75],
		[Vector3.RIGHT, [Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)], 0.75],
	]
	for f: Array in faces:
		var n: Vector3 = f[0]
		var q: Array = f[1]
		var shade: Color = c * float(f[2])
		shade.a = 1.0
		var order: Array[int] = [0, 1, 2, 0, 2, 3]
		if (q[1] - q[0]).cross(q[2] - q[0]).dot(n) > 0.0:
			order = [0, 2, 1, 0, 3, 2]
		for i: int in order:
			st.set_color(shade)
			st.set_normal(basis * n)
			st.add_vertex(centre + basis * (q[i] as Vector3))
