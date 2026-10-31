class_name CreatureLook
extends RefCounted
## How the planets' robots and aliens are drawn (owner #86, spec §21f), cheap for phones (§7.5): each model is ONE
## merged vertex-coloured mesh built from boxes once and cached (WeaponModels.build), drawn with the animals' own
## vertex-colour material (BlockyAnimal's flags: nothing new to compile). Both graphics styles: the blocky style draws
## them as the animals are drawn; the realistic style gives the robots Pip's shiny metal (Animal.pip_material: the same
## shader, only its metal numbers differ) and the aliens a softer sheen. Far away they are not drawn at all
## (visibility ranges), and nothing here runs every frame.

const ROBOT_RANGE := 110.0        # a robot is drawn this far from the camera
const CAMP_RANGE := 220.0         # a camp or a village (seen from the pad: RADII up to 50)

static var _material: StandardMaterial3D
static var _soft: StandardMaterial3D
static var _meshes := {}


## The animals' vertex-colour material (the same flags as BlockyAnimal's: its shader is already compiled).
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.85
	return _material


## The realistic style's aliens: the same shader with a softer sheen.
static func soft() -> StandardMaterial3D:
	if _soft == null:
		_soft = material().duplicate() as StandardMaterial3D
		_soft.roughness = 0.45
	return _soft


## The material a model wears in `style` ("blocky", "realistic"): robots shine in the realistic style.
static func material_for(style: String, robot: bool) -> StandardMaterial3D:
	if style != "realistic":
		return material()
	return Animal.pip_material() if robot else soft()


## A cached mesh of `parts` (WeaponModels' boxes [center, size, color, basis?] and discs) under `key`.
static func mesh(key: String, parts: Array) -> ArrayMesh:
	if not _meshes.has(key):
		var m := WeaponModels.build(parts)
		m.surface_set_material(0, material())
		_meshes[key] = m
	return _meshes[key]


static func has_mesh(key: String) -> bool:
	return _meshes.has(key)


## A MeshInstance3D of `m` under `parent`, drawn up to `range_end` (0: always).
static func add(parent: Node3D, m: Mesh, range_end: float = ROBOT_RANGE, node_name: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	if node_name != "":
		mi.name = node_name
	if range_end > 0.0:
		mi.visibility_range_end = range_end
		mi.visibility_range_end_margin = 8.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


## Every mesh under `root` wears `style`'s material.
static func dress(root: Node, style: String, robot: bool) -> void:
	var m: Material = null if style != "realistic" else material_for(style, robot)
	for n in root.find_children("*", "MeshInstance3D", true, false):
		(n as MeshInstance3D).material_override = m


## A round-ish block (a cross of two boxes and a diamond between them) of radius `r` and height `h` at `center`: the
## blocky way to draw something round.
static func round_box(center: Vector3, r: float, h: float, color: Color) -> Array:
	return [
		[center, Vector3(r * 2.0, h, r * 1.2), color],
		[center, Vector3(r * 1.2, h, r * 2.0), color],
		[center, Vector3(r * 1.42, h, r * 1.42), color, Basis(Vector3.UP, PI / 4.0)],
	]


## `parts` made `k` times as big round their own origin (boxes only).
static func scaled(parts: Array, k: float) -> Array:
	var out: Array = []
	for p: Variant in parts:
		var b: Array = (p as Array).duplicate()
		b[0] = (b[0] as Vector3) * k
		b[1] = (b[1] as Vector3) * k
		out.append(b)
	return out


## `parts` moved by `offset` and turned by `yaw` round their own origin (boxes only).
static func placed(parts: Array, offset: Vector3, yaw: float) -> Array:
	var turn := Basis(Vector3.UP, yaw)
	var out: Array = []
	for p: Variant in parts:
		var b: Array = p
		var basis: Basis = b[3] if b.size() > 3 else Basis.IDENTITY
		out.append([offset + turn * (b[0] as Vector3), b[1], b[2], turn * basis])
	return out
