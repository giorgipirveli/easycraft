class_name VrPanel
extends MeshInstance3D
## VR on the Meta Quest (owner #101), the panel side: the one quad that shows the VR canvas (Vr.ui_viewport()) in the
## world, in VrPanelRules' two places: EYE (a menu, a board, the pause menu, a world loading: 1.6 × 0.9 m, 1.4 m ahead,
## world-fixed, re-centred past 50°) and TRAY (playing: the HUD, 1 m wide, low, lazily following the head's yaw).
##
## It keeps its place relative to the XR origin (the parent of Vr.camera), so a world-fixed panel moves with the
## child's body, never with the head. It is drawn over the world (no depth test: a wall nearer than 1.4 m never hides a
## menu) and is unshaded; the canvas's colours are premultiplied, as a transparent 2D viewport stores them.

## The top (RENDER_PRIORITY_MAX): over the world, the loading room (VrLoadingRoom.SKY_PRIORITY) and VR-RIG's comfort
## sphere (its black fade and vignette, VrComfort's 100), so a menu or the loading card always shows in a fade.
const RENDER_PRIORITY := 127

## () -> Transform3D: the head (default: Vr.camera, else the viewport's camera: a desktop preview).
var head_source := Callable()
## () -> Node3D: what the panel's place is kept relative to (default: the XR origin, Vr.camera's parent; none: the world).
var origin_source := Callable()
## Owner #127: () -> Transform3D: the hand that does not point, whose raised forearm is the SHIELD (default: its grip).
var hand_source := Callable()

var place: StringName = VrPanelRules.HIDDEN
var size := Vector2.ZERO

var _eye_mesh := QuadMesh.new()
var _tray_mesh := QuadMesh.new()
var _shield_mesh := QuadMesh.new()   # owner #127
var _material := StandardMaterial3D.new()
var _local := Transform3D()   # the place, relative to the origin (or the world)
var _origin: Node3D
var _tray_yaw := 0.0
var _following := false
var _eye_yaw := 0.0


func _init() -> void:
	name = "VrPanel"
	_eye_mesh.size = VrPanelRules.EYE_SIZE
	_tray_mesh.size = VrPanelRules.TRAY_SIZE
	_shield_mesh.size = VrPanelRules.SHIELD_SIZE
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
	_material.no_depth_test = true
	_material.render_priority = RENDER_PRIORITY
	_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	_material.disable_receive_shadows = true
	_eye_mesh.material = _material
	_tray_mesh.material = _material
	_shield_mesh.material = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layers = VrPanelRules.LAYERS   # seen in a flight's space too
	visible = false
	top_level = true


## The canvas the panel shows.
func show_canvas(texture: Texture2D) -> void:
	_material.albedo_texture = texture


## Moves the panel to `p` (VrPanelRules.EYE, TRAY or HIDDEN), placed for the head now.
func set_place(p: StringName) -> void:
	if p == place:
		return
	place = p
	visible = p != VrPanelRules.HIDDEN
	var head := head()
	if p == VrPanelRules.EYE:
		mesh = _eye_mesh
		size = VrPanelRules.EYE_SIZE
		_eye_yaw = VrPanelRules.head_yaw(head)
		_set_world(VrPanelRules.eye_transform(head))
	elif p == VrPanelRules.TRAY:
		mesh = _tray_mesh
		size = VrPanelRules.TRAY_SIZE
		_tray_yaw = VrPanelRules.head_yaw(head)
		_following = false
		_set_world(VrPanelRules.tray_transform(head.origin, _tray_yaw))
	elif p == VrPanelRules.SHIELD:
		mesh = _shield_mesh
		size = VrPanelRules.SHIELD_SIZE
		_set_world(VrPanelRules.shield_transform(head.origin, hand()))


## One frame: the eye panel comes round past 50°; the tray follows the head's yaw lazily and stays under the eyes.
func step(delta: float) -> void:
	if place == VrPanelRules.HIDDEN:
		return
	var head := head()
	if place == VrPanelRules.SHIELD:   # owner #127: it rides on the raised forearm
		_set_world(VrPanelRules.shield_transform(head.origin, hand()))
		return
	var yaw := VrPanelRules.head_yaw(head)
	if place == VrPanelRules.EYE:
		if VrPanelRules.needs_recentre(_eye_yaw, yaw):
			_eye_yaw = yaw
			_set_world(VrPanelRules.eye_transform(head))
		else:
			_follow_origin()
		return
	var r := VrPanelRules.tray_yaw(_tray_yaw, yaw, _following, delta)
	_tray_yaw = r[0]
	_following = r[1]
	_set_world(VrPanelRules.tray_transform(head.origin, _tray_yaw))


## Where a ray lands on the panel: Vector3(u, v, distance) or VrPanelRules.MISS (hidden, missed, from behind).
func hit(from: Vector3, dir: Vector3) -> Vector3:
	if place == VrPanelRules.HIDDEN or not is_inside_tree():
		return VrPanelRules.MISS
	return VrPanelRules.hit(global_transform, size, from, dir)


## The head's transform now.
func head() -> Transform3D:
	if head_source.is_valid():
		return head_source.call()
	if Vr.camera != null and is_instance_valid(Vr.camera) and Vr.camera.is_inside_tree():
		return Vr.camera.global_transform
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam.global_transform if cam != null else Transform3D(Basis(), Vector3(0, CameraRig.HEAD_HEIGHT, 0))


## Owner #127: the hand that does not point, in the world (its grip; the head when no hand is tracked).
func hand() -> Transform3D:
	if hand_source.is_valid():
		return hand_source.call()
	var left := Profile.data != null and bool(Profile.data.settings.get("left_handed", false))
	var off := VrRules.RIGHT if VrRules.pointing_hand(left) == VrRules.LEFT else VrRules.LEFT
	return Vr.hand_grip(off) if Vr.rig != null else head()


func _origin_node() -> Node3D:
	if origin_source.is_valid():
		return origin_source.call()
	if Vr.camera != null and is_instance_valid(Vr.camera):
		return Vr.camera.get_parent() as Node3D
	return null


func _set_world(t: Transform3D) -> void:
	t = scaled_round_head(t, head().origin, Vr.world_scale())
	_origin = _origin_node()
	_local = _origin.global_transform.affine_inverse() * t if _origin != null and _origin.is_inside_tree() else t
	global_transform = t


## Owner #110: under Size Magic's or MODEL VIEW's world scale `s` the panel is placed and sized as for a child of the
## world's own size (a giant's panel is as far and as big to their eyes as ever, never inside their face).
static func scaled_round_head(t: Transform3D, head: Vector3, s: float) -> Transform3D:
	if is_equal_approx(s, 1.0):
		return t
	return Transform3D(t.basis * s, head + (t.origin - head) * s)


## A world-fixed eye panel stays where it was relative to the child's body (the origin follows the feet).
func _follow_origin() -> void:
	if _origin != null and is_instance_valid(_origin) and _origin.is_inside_tree():
		global_transform = _origin.global_transform * _local
