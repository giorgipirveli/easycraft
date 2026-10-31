class_name VrLoadingRoom
extends Node3D
## VR on the Meta Quest (owner #101), the panel side: while a world loads (a LoadingCard is up), the headset never shows
## a black void or half a world popping in: a calm dark room round the child, a floor grid at the feet and a horizon
## (docs/devlog/parts/vr-research.md: "never black for more than about 3 s"), with the loading card on the eye panel.
## The room is world-fixed: placed under the head when it opens and moved only if the head ends up far from it (a
## spawn), so leaning and turning feel like standing in a room. Drawn over the world (no depth test), over VR-RIG's
## black fade (its comfort sphere draws at 100: a spawn held behind black shows the room, not a void) and under the panel
## (VrPanel.RENDER_PRIORITY, 127). Unshaded; the grid is a small picture made once.

## The sky's render priority; the floor and the horizon draw one over it.
const SKY_PRIORITY := 110
const RADIUS := 8.0
const FLOOR_SIZE := 16.0
## The floor's grid: one line a metre.
const GRID_CELLS := 16
## Further than this from the room's middle (a spawn moved the child), it comes round the head again.
const REPLACE_METRES := 3.0
const SKY := Color(0.05, 0.07, 0.13)
const LINE := Color(0.35, 0.65, 0.95, 0.55)
const HORIZON := Color(0.25, 0.45, 0.75, 0.6)

## () -> Transform3D: the head (VrPanel.head by default, set by VrUi).
var head_source := Callable()

var _sky := MeshInstance3D.new()
var _floor := MeshInstance3D.new()
var _horizon := MeshInstance3D.new()


func _init() -> void:
	name = "VrLoadingRoom"
	top_level = true
	visible = false
	var sphere := SphereMesh.new()
	sphere.radius = RADIUS
	sphere.height = RADIUS * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12
	sphere.flip_faces = true   # seen from inside
	sphere.material = _material(SKY, SKY_PRIORITY)
	_sky.mesh = sphere
	_sky.name = "Sky"
	add_child(_sky)
	var plane := PlaneMesh.new()
	plane.size = Vector2(FLOOR_SIZE, FLOOR_SIZE)
	var grid := _material(Color.WHITE, SKY_PRIORITY + 1)
	grid.albedo_texture = grid_texture()
	grid.uv1_scale = Vector3(GRID_CELLS, GRID_CELLS, 1)
	grid.texture_repeat = true
	plane.material = grid
	_floor.mesh = plane
	_floor.name = "Floor"
	add_child(_floor)
	var ring := TorusMesh.new()   # the horizon: a thin glowing ring at eye level, far away
	ring.inner_radius = RADIUS * 0.94
	ring.outer_radius = RADIUS * 0.95
	ring.rings = 48
	ring.ring_segments = 4
	ring.material = _material(HORIZON, SKY_PRIORITY + 1)
	_horizon.mesh = ring
	_horizon.name = "Horizon"
	add_child(_horizon)
	for m: MeshInstance3D in [_sky, _floor, _horizon]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.layers = VrPanelRules.LAYERS


static func _material(color: Color, priority: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA   # drawn in the see-through pass: after the world, in order
	m.no_depth_test = true
	m.render_priority = priority
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.disable_receive_shadows = true
	return m


## One grid cell's picture: a line along two edges.
static func grid_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 32:
		for w in 2:
			img.set_pixel(i, w, LINE)
			img.set_pixel(w, i, LINE)
	return ImageTexture.create_from_image(img)


## Shows the room (round the head, the floor at the feet) or hides it.
func set_open(open: bool) -> void:
	if open and not visible:
		_place()
	visible = open


## One frame: a room left far behind (a spawn) comes round the head again.
func step() -> void:
	if not visible:
		return
	var head := _head()
	if Vector2(head.origin.x - global_position.x, head.origin.z - global_position.z).length() > REPLACE_METRES:
		_place()


## The floor's height under the head (the avatar's eye height below it: "game height", VrRules).
func floor_y() -> float:
	return global_position.y


func _place() -> void:
	var head := _head()
	global_position = head.origin - Vector3(0, CameraRig.HEAD_HEIGHT, 0)
	_sky.position = Vector3(0, CameraRig.HEAD_HEIGHT, 0)
	_horizon.position = Vector3(0, CameraRig.HEAD_HEIGHT, 0)
	_floor.position = Vector3.ZERO


func _head() -> Transform3D:
	if head_source.is_valid():
		return head_source.call()
	return Transform3D(Basis(), Vector3(0, CameraRig.HEAD_HEIGHT, 0))
