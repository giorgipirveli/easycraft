class_name VrHandModel
extends Node3D
## Owner #101 (VR on the Meta Quest, P4): a hand in the avatar's own colours, the child's own (on the controller) or a
## remote VR player's (VrBody). A mitten: the palm, the three fingers together, the index finger and the thumb, and a
## cuff in the sleeve's colour; blocky (boxes, the blocky body's) or realistic (rounded, the realistic person's). The
## grip curls the fingers and the thumb into a fist; the trigger curls the index finger: a squeeze of the grip alone
## points. Its origin is the palm's middle, the fingers point along -Z, the back of the hand is +Y. Held items hang
## from item_anchor() (HeldItem's way: the grip at its origin, the item along its -Z).

const BLOCKY := &"blocky"
const REALISTIC := &"realistic"
const PALM := Vector3(0.08, 0.03, 0.085)
const FINGERS := Vector3(0.058, 0.024, 0.07)
const INDEX := Vector3(0.02, 0.022, 0.075)
const THUMB := Vector3(0.022, 0.022, 0.05)
const CUFF := Vector3(0.09, 0.055, 0.045)
const FINGER_CURL := 1.45
const INDEX_CURL := 1.35
const THUMB_CURL := 0.9

## RIGHT or LEFT (VrRules): which side the thumb is on.
var side: StringName = VrRules.RIGHT
var style: StringName = BLOCKY
var grip := 0.0
var trigger := 0.0

var _fingers := Node3D.new()
var _index := Node3D.new()
var _thumb := Node3D.new()
var _anchor := Node3D.new()
var _skin: Array[MeshInstance3D] = []
var _cuff: MeshInstance3D


func _init(hand_side: StringName = VrRules.RIGHT, hand_style: StringName = BLOCKY) -> void:
	side = hand_side
	style = hand_style
	name = "VrHandModel"
	var inward := -1.0 if side == VrRules.RIGHT else 1.0   # the thumb's side: towards the body's middle
	_skin.append(_part(self, PALM, Vector3.ZERO, "Palm"))
	_fingers.name = "Fingers"
	_fingers.position = Vector3(-inward * 0.011, 0.0, -PALM.z * 0.5)
	add_child(_fingers)
	_skin.append(_part(_fingers, FINGERS, Vector3(0, 0, -FINGERS.z * 0.5), "Mitten"))
	_index.name = "Index"
	_index.position = Vector3(inward * (PALM.x * 0.5 - INDEX.x * 0.5), 0.002, -PALM.z * 0.5)
	add_child(_index)
	_skin.append(_part(_index, INDEX, Vector3(0, 0, -INDEX.z * 0.5), "IndexFinger"))
	_thumb.name = "Thumb"
	_thumb.position = Vector3(inward * PALM.x * 0.5, -0.004, -0.012)
	_thumb.rotation = Vector3(0.0, inward * 0.6, 0.0)
	add_child(_thumb)
	_skin.append(_part(_thumb, THUMB, Vector3(0, 0, -THUMB.z * 0.5), "ThumbFinger"))
	_cuff = _part(self, CUFF, Vector3(0, 0.002, PALM.z * 0.5 + CUFF.z * 0.4), "Cuff")
	_anchor.name = "ItemAnchor"
	_anchor.position = Vector3(0.0, -0.01, -0.01)
	_anchor.child_entered_tree.connect(_on_held)   # owner #126: what the hand holds shows in space too
	add_child(_anchor)
	set_colors(BlockyAvatar.SKIN, BlockyAvatar.TORSO)


func _part(parent: Node3D, size: Vector3, at: Vector3, part_name: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = part_name
	if style == REALISTIC:
		var c := CapsuleMesh.new()   # the realistic person's: rounded
		c.radius = minf(size.x, size.y) * 0.5
		c.height = maxf(size.z, c.radius * 2.0)
		c.radial_segments = 8
		c.rings = 2
		m.mesh = c
		m.rotation = Vector3(PI * 0.5, 0.0, 0.0)   # the capsule's length along z
		m.scale = Vector3(size.x / (c.radius * 2.0), 1.0, size.y / (c.radius * 2.0))
	else:
		m.mesh = AvatarParts.box_mesh(size)
	m.position = at
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.layers = 1 | VrRules.HANDS_LAYER   # owner #126: seen in the rocket in space too
	parent.add_child(m)
	return m


## The skin's and the sleeve's (or shirt's) colours.
func set_colors(skin: Color, sleeve: Color) -> void:
	var s := AvatarParts.material(Color(skin, 1.0))
	for m in _skin:
		m.material_override = s
	_cuff.material_override = AvatarParts.material(Color(sleeve, 1.0))


## A resolved AvatarLook (AvatarLook.resolve): its skin, and its sleeves or else its shirt.
func set_look(r: Dictionary) -> void:
	var sleeves: Color = r.get("sleeves", Color(0, 0, 0, 0))
	set_colors(r.get("skin", BlockyAvatar.SKIN), sleeves if sleeves.a > 0.0 else r.get("shirt", BlockyAvatar.TORSO))


## The grip (0 open .. 1 a fist) and the trigger (0 .. 1 the index curled): grip without trigger points.
func set_pose(grip_amount: float, trigger_amount: float) -> void:
	grip = clampf(grip_amount, 0.0, 1.0)
	trigger = clampf(trigger_amount, 0.0, 1.0)
	_fingers.rotation.x = -grip * FINGER_CURL
	_index.rotation.x = -trigger * INDEX_CURL
	var inward := -1.0 if side == VrRules.RIGHT else 1.0
	_thumb.rotation = Vector3(-grip * THUMB_CURL * 0.5, inward * (0.6 - grip * THUMB_CURL), 0.0)


## Is the index finger out (pointing)?
func pointing() -> bool:
	return grip > 0.5 and trigger < 0.5


func item_anchor() -> Node3D:
	return _anchor


## Owner #126: a thing hung on the hand (HeldItem) draws on the hands' layer too (once it has made its meshes: they come
## in its _ready, after it entered the hand).
func _on_held(n: Node) -> void:
	if n.is_node_ready():
		_layer_held(n)
	else:
		n.ready.connect(_layer_held.bind(n), CONNECT_ONE_SHOT)


func _layer_held(n: Node) -> void:
	if not is_instance_valid(n):
		return
	var meshes := n.find_children("*", "MeshInstance3D", true, false)
	if n is MeshInstance3D:
		meshes.append(n)
	for m: Node in meshes:
		(m as MeshInstance3D).layers |= VrRules.HANDS_LAYER


## Draws on these render layers only (the selfie and the mirror: VrPhotoCamera.SELF_LAYER).
func set_layers(mask: int) -> void:
	for m: Node in find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).layers = mask

# --- Owner #110 (VR round 4, VR-HANDS; ruling R2): the picture stops at a block's face ---

const GHOST_COLOR := Color(1.0, 1.0, 1.0, 0.22)

var _ghost: MeshInstance3D
var _free := Vector3.INF


## The child's own hand on the controller's `grip` (world), its picture stopped at a block's face: `solid(cell) -> bool`
## (the world's blocks; invalid: never stopped), `scale` the world's (Size Magic), `head` where to come from when the
## hand has been in a block since before. A faint outline shows where the real hand is when they part.
func follow(grip: Transform3D, solid: Callable, scale_now: float, head: Vector3) -> void:
	var at := grip.origin
	var picture := at
	if solid.is_valid():
		if not bool(solid.call(Vector3i(at.floor()))):
			_free = at
		else:
			var from := _free if _free.is_finite() and not bool(solid.call(Vector3i(_free.floor()))) else head
			picture = stop_at_face(from, at, VrGrabRules.HAND_RADIUS * scale_now, solid)
	global_transform = Transform3D(grip.basis, picture)
	scale = Vector3.ONE * scale_now
	_show_ghost(at, picture.distance_to(at) > VrGrabRules.GHOST_GAP * scale_now, scale_now)


## Where a hand moving from `from` (in the air) to `to` (in a block) stops: `radius` short of the first solid face on
## the way (the voxels' own ray, no physics).
static func stop_at_face(from: Vector3, to: Vector3, radius: float, solid: Callable) -> Vector3:
	var d := to - from
	if d.length() < 0.0001:
		return from
	var dir := d.normalized()
	var hit := GridRay.cast(from, dir, d.length(), solid)
	if hit == null:
		return to
	return from + dir * maxf(hit.distance - radius, 0.0)


## Where the index finger's tip is (world): it pokes the wrist hotbar's slots (owner #110).
func fingertip() -> Vector3:
	return _index.global_transform * Vector3(0.0, 0.0, -INDEX.z)


## The real hand's faint outline is showing (the picture stopped short of it).
func ghost_shown() -> bool:
	return _ghost != null and _ghost.visible


func _show_ghost(at: Vector3, on: bool, scale_now: float) -> void:
	if not on and _ghost == null:
		return
	if _ghost == null:
		_ghost = MeshInstance3D.new()
		_ghost.name = "RealHand"
		var s := SphereMesh.new()
		s.radius = VrGrabRules.HAND_RADIUS
		s.height = VrGrabRules.HAND_RADIUS * 2.0
		s.radial_segments = 12
		s.rings = 6
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.no_depth_test = true   # seen inside the wall it went into
		m.albedo_color = GHOST_COLOR
		s.material = m
		_ghost.mesh = s
		_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost.top_level = true
		_ghost.layers = 1 | VrRules.HANDS_LAYER   # owner #126
		add_child(_ghost)
	_ghost.visible = on
	if on:
		_ghost.global_transform = Transform3D(Basis.from_scale(Vector3.ONE * scale_now), at)
