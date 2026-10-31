class_name LifeRoomKit
extends RefCounted
## Owner #112 (docs/design/life-skills.md §4, §6): the practice rooms' building blocks, made in code in the game's own
## blocky look (boxes, cylinders, spheres, signs, soft lights): no assets loaded, materials shared by colour, no shadows
## from the rooms' own lights (the Quest's frame budget). Every shader is one the game already warms up (ShaderWarmup):
## lit things are the blocky avatar's material (AvatarParts.material), see-through and glowing things the mirror
## wall's settings (unshaded, alpha, two-sided), signs the animals' billboard tags, and the background a plain colour.

static var _materials := {}


## A shared material: lit and opaque (AvatarParts.material), or glowing (`unshaded`) or see-through (alpha < 1): those
## two draw with the mirror wall's settings.
static func material(colour: Color, unshaded: bool = false) -> StandardMaterial3D:
	if not unshaded and colour.a >= 0.999:
		return AvatarParts.material(colour)
	var key := "%s|glow" % colour.to_html(true)
	if not _materials.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(colour, minf(colour.a, 0.98))
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materials[key] = m
	return _materials[key]


static func box(parent: Node3D, name: String, size: Vector3, at: Vector3, colour: Color, yaw: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _place(parent, name, mesh, at, colour, yaw)


static func cylinder(parent: Node3D, name: String, radius: float, height: float, at: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	return _place(parent, name, mesh, at, colour, 0.0)


static func sphere(parent: Node3D, name: String, radius: float, at: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	return _place(parent, name, mesh, at, colour, 0.0)


## Words in the room (a sign, a price tag): billboards that always face the child (readable from anywhere, in VR too;
## the animals' tags' settings).
static func sign(parent: Node3D, name: String, text: String, at: Vector3, pixel: float = 0.004, colour: Color = Color.WHITE,
		yaw: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.name = name
	l.text = text
	l.pixel_size = pixel
	l.font_size = 64
	l.outline_size = 12
	l.modulate = colour
	l.outline_modulate = Color(0.08, 0.1, 0.18, 0.9)
	l.position = at
	l.rotation.y = yaw
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	return l


static func light(parent: Node3D, at: Vector3, energy: float = 1.2, reach: float = 7.0, colour: Color = Color(1, 0.96, 0.88)) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.position = at
	o.light_energy = energy
	o.omni_range = reach
	o.light_color = colour
	o.shadow_enabled = false
	parent.add_child(o)
	return o


## A calm sky-coloured environment the room's camera (and the VR head) draws with: a plain soft blue (no sky shader to
## compile), gentle ambient light, no fog (the menu's world, far below, has its own). `horizon` is kept for a later
## gradient.
static func environment(top: Color, _horizon: Color, ambient: float = 0.55) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = top
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 0.98, 0.94)
	env.ambient_light_energy = ambient
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	return env


static func _place(parent: Node3D, name: String, mesh: Mesh, at: Vector3, colour: Color, yaw: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = name
	m.mesh = mesh
	m.material_override = material(colour)
	m.position = at
	m.rotation.y = yaw
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m
