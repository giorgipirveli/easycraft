class_name VrBody
extends Node3D
## Owner #101 (VR on the Meta Quest, P4): another player who plays in a headset, as this game shows it. Its
## Player.vr_pose (VrPoseRules: the head and both hands, 20 times a second by VrPoseLink) turns the avatar's head (a
## nod, a look round) and floats two hands in the avatar's colours where the controllers are (waving, pointing, a fist),
## the arms folded away (the hands show where they are); what it holds is in its right hand. Eased between poses.
## Made by the Player on the games that show it (never its own game: its own hands are the rig's), and away again when
## the pose stops (the headset taken off).

const EASE := 14.0   # 1/s: eased towards each new pose

var player: Player
## False for this game's own player in the mirror (its hands are the rig's): only the head turns and the arms fold.
var hands_shown := true
var hands := {}        # VrRules.LEFT / RIGHT -> VrHandModel
var head_euler := Vector3.ZERO
var pose := {}         # the last decoded pose (tests)

var _style: StringName = &""
var _modifier: VrBodyModifier
var _arms_hidden: Array[Node3D] = []


func _init(p: Player = null) -> void:
	name = "VrBody"
	player = p
	top_level = true


func _process(delta: float) -> void:
	step(delta)


## One frame: the newest pose, eased; the head turned, the hands placed and posed.
func step(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var s := player.size_scale()
	var eye := CameraRig.HEAD_HEIGHT * s
	var p := VrPoseRules.decode(player.vr_pose, eye, s)
	if p.is_empty():
		pose = {}
		_show(false)
		return
	pose = p
	_style_hands()
	_show(true)
	var k := clampf(EASE * delta, 0.0, 1.0) if delta > 0.0 else 1.0
	var body := Transform3D(Basis(Vector3.UP, player.avatar.rotation.y), player.global_position)
	head_euler = head_euler.lerp((p.head as Transform3D).basis.get_euler(), k)
	_turn_head(head_euler)
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var h := hands[side] as VrHandModel
		var want := body * (p[side] as Transform3D)
		h.global_transform = want if not h.visible or k >= 1.0 else h.global_transform.interpolate_with(want, k)
		var bubble := _bubble(h.global_position)   # owner #110 (R8): never into this child's face
		h.scale = Vector3.ONE * s * maxf(bubble, 0.001)
		h.visible = hands_shown and bubble > 0.0
		h.set_pose(float(p[str(side) + "_grip"]), float(p[str(side) + "_trigger"]))


## Owner #110 (R8, the personal bubble): how big another player's hand shows at `at` from this game's child's head in a
## headset (VrGestureRules.bubble_scale); whole off VR.
static func _bubble(at: Vector3) -> float:
	if not Vr.active() or Vr.camera == null:
		return 1.0
	return VrGestureRules.bubble_scale(at.distance_to(Vr.head_transform().origin) / maxf(Vr.world_scale(), 0.001))


## Where the right hand holds an item (Player._update_held_item; null while no pose shows).
func item_anchor() -> Node3D:
	var h := hands.get(VrRules.RIGHT) as VrHandModel
	return h.item_anchor() if h and h.visible else null


## The pose is showing.
func showing() -> bool:
	return not pose.is_empty()


func _style_hands() -> void:
	var style := VrHandModel.REALISTIC if player.avatar is RealisticAvatar else VrHandModel.BLOCKY
	if style == _style and hands.size() == 2:
		return
	_style = style
	for h: Node in hands.values():
		h.queue_free()
	hands.clear()
	for side: StringName in [VrRules.LEFT, VrRules.RIGHT]:
		var h := VrHandModel.new(side, style)
		h.top_level = true
		h.visible = false
		add_child(h)
		hands[side] = h
	_arms_hidden.clear()
	_modifier = null
	var r := player.avatar.look().resolve()
	for h: VrHandModel in hands.values():
		h.set_look(r)


func _show(on: bool) -> void:
	for h: VrHandModel in hands.values():
		h.visible = on and hands_shown
	var blocky := player.avatar as BlockyAvatar
	if blocky:
		for arm in blocky.arms():
			arm.visible = not on   # the hands show where they are: the arms fold away
		if not on:
			blocky.head_anchor().rotation = Vector3.ZERO
	var realistic := player.avatar as RealisticAvatar
	if realistic and realistic.skeleton():
		if _modifier == null or not is_instance_valid(_modifier) or _modifier.get_parent() != realistic.skeleton():
			_modifier = VrBodyModifier.new()
			realistic.skeleton().add_child(_modifier)
		_modifier.active = on


func _turn_head(e: Vector3) -> void:
	var blocky := player.avatar as BlockyAvatar
	if blocky:
		blocky.head_anchor().rotation = e
	elif _modifier:
		_modifier.head = Basis.from_euler(e)


func _exit_tree() -> void:
	if is_instance_valid(player) and player.avatar:
		_show(false)
	if is_instance_valid(_modifier):
		_modifier.queue_free()
