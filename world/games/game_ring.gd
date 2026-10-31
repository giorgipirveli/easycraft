class_name GameRing
extends MeshInstance3D
## The co-op games' glowing circle (M4 Wave 3, agent H): Storm Run's shrinking safe circle and
## hide-and-seek's play area, on every game. One open cylinder mesh and one material (shaders/
## game_ring.gdshader) shared by every ring, made once and kept; a round only moves and scales it, and
## only when the circle changed. Compiled as the world appears (prewarm), never in the middle of a round.

const SHADER := preload("res://shaders/game_ring.gdshader")
const HEIGHT := 36.0              # blocks, from BELOW under the ground up
const BELOW := 10.0
const STORM_TINT := Color(0.45, 0.62, 1.0)
const AREA_TINT := Color(0.55, 1.0, 0.6)

static var _mesh: CylinderMesh
static var _material: ShaderMaterial

var _shown := Vector4.INF         # centre x, ground y, centre z, radius


static func material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material


static func mesh_shape() -> CylinderMesh:
	if _mesh == null:
		_mesh = CylinderMesh.new()
		_mesh.top_radius = 1.0
		_mesh.bottom_radius = 1.0
		_mesh.height = 1.0
		_mesh.radial_segments = 64
		_mesh.rings = 1
		_mesh.cap_top = false
		_mesh.cap_bottom = false
	return _mesh


func _ready() -> void:
	mesh = mesh_shape()
	material_override = material()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top_level = true
	visible = false


## Shows the circle of `radius` around `centre` (flat), standing on ground at `ground_y`, in `tint`.
func show_circle(centre: Vector2, ground_y: float, radius: float, tint: Color) -> void:
	var want := Vector4(centre.x, ground_y, centre.y, radius)
	if not visible:
		material().set_shader_parameter(&"tint", tint)
		visible = true
	if want.is_equal_approx(_shown):
		return
	_shown = want
	transform = Transform3D(Basis().scaled(Vector3(radius, HEIGHT, radius)),
		Vector3(centre.x, ground_y - BELOW + HEIGHT * 0.5, centre.y))


func hide_circle() -> void:
	visible = false
	_shown = Vector4.INF


## Draws the ring once, tiny, in front of the camera as the world appears (a new shader's first draw was
## a 100+ ms frame on the emulator, DEVELOPMENT.md §8).
static func prewarm(camera: Camera3D) -> void:
	if camera == null or not camera.is_inside_tree():
		return
	var holder := Node3D.new()
	camera.add_child(holder)
	holder.position = Vector3(0, 0, -1.5)
	var m := MeshInstance3D.new()
	m.mesh = mesh_shape()
	m.material_override = material()
	m.scale = Vector3.ONE * 0.01
	holder.add_child(m)
	var s := MeshInstance3D.new()
	s.mesh = StarPool.star_mesh()
	s.material_override = StarPool.material()
	s.scale = Vector3.ONE * 0.01
	holder.add_child(s)
	var t := holder.create_tween()
	t.tween_interval(0.25)
	t.tween_callback(holder.queue_free)
