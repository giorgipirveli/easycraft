class_name PortalSwirl
extends RefCounted
## The one swirl every portal shares (M3 Task 5, shaders/portal_swirl.gdshader): the inside of linked
## portal frames, the floor of the portal hub's stone circle, a universe portal's window. One material,
## one unit quad (scaled per opening), both made once and kept; compiled as the world appears (prewarm),
## so the first portal never costs a frame (DEVELOPMENT.md §8).

const SHADER := preload("res://shaders/portal_swirl.gdshader")

static var _material: ShaderMaterial
static var _quad: QuadMesh


static func material() -> ShaderMaterial:
	if _material == null:
		_material = _made(CrystalRules.swirl_colors(0), 1.0)   # owner #43: gold with rainbow arms
	return _material


static func _made(colors: Array, rainbow: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter(&"deep", colors[0])
	m.set_shader_parameter(&"bright", colors[1])
	m.set_shader_parameter(&"rim", colors[2])
	m.set_shader_parameter(&"rainbow", rainbow)
	return m


static var _universe_materials := {}


## Owner feedback #39: the swirl of a universe portal in its universe's colours (CrystalRules.swirl_colors): one
## shared material per universe, the same shader (no new compile: only its colours differ); 0 is the plain one.
static func material_for(u: int) -> ShaderMaterial:
	if not CrystalRules.CORES.has(u):
		return material()
	if not _universe_materials.has(u):
		_universe_materials[u] = _made(CrystalRules.swirl_colors(u), 0.0)   # its own colours, no rainbow arms
	return _universe_materials[u]


## A 1 x 1 quad facing +Z; scale its instance to the opening.
static func quad() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = Vector2.ONE
	return _quad


## A swirl surface of `size` (width, height) as a child of `parent` (not in the shadow pass).
static func surface(parent: Node3D, size: Vector2, u: int = 0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = quad()
	m.material_override = material_for(u)
	m.scale = Vector3(size.x, size.y, 1.0)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
	return m


## Draws the swirl once, tiny, in front of the camera as the world appears (a new shader's first draw
## was a 100+ ms frame on the emulator).
static func prewarm(camera: Camera3D) -> void:
	if camera == null or not camera.is_inside_tree():
		return
	var holder := Node3D.new()
	camera.add_child(holder)
	holder.position = Vector3(0, 0, -1.5)
	surface(holder, Vector2(0.01, 0.01))
	var t := holder.create_tween()
	t.tween_interval(0.25)
	t.tween_callback(holder.queue_free)
