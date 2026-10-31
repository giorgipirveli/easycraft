class_name BreakRing
extends Node3D
## A ring on the face of the block a held finger is breaking; it fills until the block breaks
## (TouchClassifier.hold_progress), so holding visibly does something (M2 Task 3, the lead's
## child-friendly feedback). One per player's BlockInteractor, reused. Its meshes (a track and one
## arc per fill step) and materials are made once and shared for the whole game: a material made per
## use freed its shader with it, and the next use compiled it again (see Fx).

const STEPS := 24          # the fill grows in 1/24 steps
const RADIUS := 0.32
const WIDTH := 0.1
const LIFT := 0.02         # off the face
const TRACK_COLOR := Color(0.05, 0.06, 0.1, 0.45)
const FILL_COLOR := Color(1.0, 0.85, 0.25, 0.95)   # the selected hotbar slot's gold
const PREWARM_SECONDS := 0.1

static var _track_mesh: ArrayMesh
static var _fill_meshes: Array[ArrayMesh] = []   # [k]: the first k steps of the ring ([0] is empty)
static var _materials := {}                       # colour -> material, all with one shader setup

var _track := MeshInstance3D.new()
var _fill := MeshInstance3D.new()
var _step := -1
var _prewarming := false


func _ready() -> void:
	top_level = true
	visible = false
	_build_meshes()
	for m: MeshInstance3D in [_track, _fill]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
	_track.mesh = _track_mesh
	_track.material_override = feedback_material(TRACK_COLOR)
	_fill.material_override = feedback_material(FILL_COLOR)
	_fill.sorting_offset = 0.01   # drawn over the track


## Shows the ring on the face of `hit` the finger is on, `progress` (0..1) filled; null hides it.
func show_on(hit: BlockHit, progress: float) -> void:
	if hit == null:
		if not _prewarming:   # "no hold" comes every frame; the prewarm must still be drawn
			visible = false
		return
	_prewarming = false
	var normal := Vector3(hit.previous_position - hit.position)
	if normal.length_squared() != 1.0:
		normal = Vector3.UP
	global_basis = face_basis(normal)
	global_position = Vector3(hit.position) + Vector3(0.5, 0.5, 0.5) + normal * (0.5 + LIFT)
	_set_step(clampi(int(progress * STEPS), 0, STEPS))
	visible = true


func fill_step() -> int:
	return _step


func fill_mesh() -> Mesh:
	return _fill.mesh


## Draws the ring once, tiny, in front of the camera, so its shader is compiled as the world appears
## instead of at the first hold (a 100+ ms frame on the emulator's GL renderer; see Fx.prewarm).
func prewarm(camera: Camera3D) -> void:
	_set_step(STEPS)
	global_basis = camera.global_basis.scaled(Vector3.ONE * 0.01)
	global_position = camera.global_position - camera.global_basis.z * 1.5
	visible = true
	_prewarming = true
	get_tree().create_timer(PREWARM_SECONDS).timeout.connect(_end_prewarm)


func _end_prewarm() -> void:
	if _prewarming:   # not taken over by a real hold
		_prewarming = false
		visible = false


## A rotation whose Z axis points out of the face (the ring is drawn in its XY plane).
static func face_basis(normal: Vector3) -> Basis:
	var up := Vector3.FORWARD if absf(normal.y) > 0.5 else Vector3.UP
	return Basis.looking_at(-normal, up)


## Unshaded, see-through, two-sided and drawn over the terrain. The ring and PlacePop use this one setup, so
## there is one shader to compile.
static func feedback_material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED   # seen from either side, whatever the winding
		m.albedo_color = color
		_materials[color] = m
	return _materials[color]


func _set_step(step: int) -> void:
	if step == _step:
		return
	_step = step
	_fill.mesh = _fill_meshes[step]


static func _build_meshes() -> void:
	if _track_mesh != null:
		return
	_track_mesh = _arc(STEPS)
	_fill_meshes.append(null)
	for k in range(1, STEPS + 1):
		_fill_meshes.append(_arc(k))


## The first `steps` of the ring, clockwise from the top as seen from +Z (front faces are clockwise).
static func _arc(steps: int) -> ArrayMesh:
	var inner := RADIUS - WIDTH * 0.5
	var outer := RADIUS + WIDTH * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in steps:
		var d0 := Vector3(sin(TAU * i / STEPS), cos(TAU * i / STEPS), 0.0)
		var d1 := Vector3(sin(TAU * (i + 1) / STEPS), cos(TAU * (i + 1) / STEPS), 0.0)
		for v: Vector3 in [d0 * outer, d1 * outer, d1 * inner, d0 * outer, d1 * inner, d0 * inner]:
			st.add_vertex(v)
	return st.commit()
