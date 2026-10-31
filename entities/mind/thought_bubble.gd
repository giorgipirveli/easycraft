class_name ThoughtBubble
extends MeshInstance3D
## A small thought bubble over a creature's head (M2 Task 18, spec §12.17): a picture (Thought) for
## SHOW_TIME seconds, turned to this device's camera, floating gently (still with Reduce motion).
## One per creature, made the first time it thinks aloud and reused; every bubble shares the quad and
## the picture materials (ThoughtPictures). Shown only near this device's camera, and never more
## than MAX_SHOWN at once on one screen. The host decides the thoughts (Mind.take_thought: at most one
## per creature every 8 s) and syncs them to guests; each device shows them for itself.

const SHOW_TIME := 2.5
const SEE_DISTANCE := 16.0
const MAX_SHOWN := 3
const BOB := 0.06
const POP_TIME := 0.15
const NODE_NAME := &"Thought"

## Bubbles showing on this device.
static var shown := 0

var picture := Thought.NONE
var _left := 0.0
var _age := 0.0
var _base_y := 0.0
var _counted := false


func _init() -> void:
	name = NODE_NAME
	mesh = ThoughtPictures.quad()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false
	set_process(false)


## Shows picture `id` over `creature` at `height` (its own bubble, made once). Null when this device's
## camera is too far away or enough bubbles are showing already.
static func show_on(creature: Node3D, id: int, height: float) -> ThoughtBubble:
	if not Thought.valid(id) or not creature.is_inside_tree():
		return null
	var bubble := creature.get_node_or_null(NodePath(NODE_NAME)) as ThoughtBubble
	var camera := creature.get_viewport().get_camera_3d()
	if camera and camera.global_position.distance_to(creature.global_position) > SEE_DISTANCE:
		return null
	if (bubble == null or not bubble.visible) and shown >= MAX_SHOWN:
		return null
	if bubble == null:
		bubble = ThoughtBubble.new()
		creature.add_child(bubble)
	bubble._show(id, height)
	return bubble


## Hides the bubble over `creature`, if it has one.
static func hide_on(creature: Node3D) -> void:
	var bubble := creature.get_node_or_null(NodePath(NODE_NAME)) as ThoughtBubble
	if bubble:
		bubble.hide_picture()


## Shows a bubble once, tiny, in front of `camera`, so its shader is compiled as the world appears
## instead of at the first thought (see Fx.prewarm).
static func prewarm(camera: Camera3D) -> void:
	var at := camera.global_position - camera.global_basis.z * 1.5
	var mi := MeshInstance3D.new()
	mi.mesh = ThoughtPictures.quad()
	mi.material_override = ThoughtPictures.material(Thought.HEART)
	mi.scale = Vector3.ONE * 0.01
	camera.get_parent().add_child(mi)
	mi.global_position = at
	camera.get_tree().create_timer(0.1).timeout.connect(mi.queue_free)


func hide_picture() -> void:
	visible = false
	picture = Thought.NONE
	set_process(false)
	_uncount()


func _show(id: int, height: float) -> void:
	picture = id
	material_override = ThoughtPictures.material(id)
	_base_y = height
	position = Vector3(0, height, 0)
	_left = SHOW_TIME
	_age = 0.0
	scale = Vector3.ONE if not _moves() else Vector3.ONE * 0.6
	visible = true
	if not _counted:
		_counted = true
		shown += 1
	set_process(true)
	_face_camera()


func _process(delta: float) -> void:
	_left -= delta
	_age += delta
	if _left <= 0.0:
		hide_picture()
		return
	if _moves():
		position.y = _base_y + sin(_age * 3.0) * BOB
		scale = Vector3.ONE * lerpf(0.6, 1.0, clampf(_age / POP_TIME, 0.0, 1.0))
	_face_camera()


## Turns the picture side (+Z of the quad) to this device's camera.
func _face_camera() -> void:
	var camera := get_viewport().get_camera_3d() if is_inside_tree() else null
	if camera == null:
		return
	var away := global_position - camera.global_position
	if Vector2(away.x, away.z).length() < 0.01:
		return
	var s := scale
	global_basis = Basis.looking_at(away, Vector3.UP)
	scale = s


func _moves() -> bool:
	return Feel.motion_allowed()


func _uncount() -> void:
	if _counted:
		_counted = false
		shown = maxi(shown - 1, 0)


func _exit_tree() -> void:
	hide_picture()
