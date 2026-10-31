class_name LifeBuddy
extends Node3D
## Owner #112 (docs/design/life-skills.md §6: "the person who needs help is a friendly buddy or a dummy"; §7): a calm,
## friendly blocky buddy about a metre tall (Bobo, Lulu, the market's customers). It is never hurt to look at: a cut is a
## soft glowing "ouch" spot, never a wound. Poses (stand, sit, sit_floor, lie, side) and the recovery position's moves
## (arm_out, hand_cheek, knee_up, roll_side, head_tilt) ease in; marks are named points on its parts that follow every
## pose (the rooms make targets of them): shoulder, near_hand, far_hand, near_arm, far_knee, chin, back, tummy, cut, cut2.
## "Near" is the buddy's -X side (towards the child when it lies on the mat), "far" its +X side.

const SKIN := Color("f2c79b")
const EYES := Color("1f2a4a")
const OUCH := Color(1.0, 0.72, 0.55, 0.85)
const EASE := 0.5

var colour := Color("1fa6a0")
var hips := Node3D.new()
var head := Node3D.new()
var arm_near := Node3D.new()
var arm_far := Node3D.new()
var leg_near := Node3D.new()
var leg_far := Node3D.new()
var marks := {}
var current_pose := "stand"
var ouch: Array[MeshInstance3D] = []
## Life L2, Calm Corner: the face shown (FEELINGS; "" the plain smile of L1).
var feeling := ""
const FEELINGS: Array[String] = ["happy", "sad", "cross", "worried", "calm"]
var _face_parts := {}
var _calm := false


func _init(body_colour: Color = Color("1fa6a0"), buddy_name: String = "Buddy") -> void:
	colour = body_colour
	name = buddy_name
	_calm = UiMotion.calm()
	hips.name = "Hips"
	hips.position = Vector3(0, 0.42, 0)
	add_child(hips)
	LifeRoomKit.box(hips, "Torso", Vector3(0.36, 0.42, 0.22), Vector3(0, 0.21, 0), colour)
	head.name = "Head"
	head.position = Vector3(0, 0.42, 0)
	hips.add_child(head)
	LifeRoomKit.box(head, "Face", Vector3(0.32, 0.3, 0.3), Vector3(0, 0.16, 0), colour.lightened(0.12))
	for x: float in [-0.07, 0.07]:
		LifeRoomKit.box(head, "Eye", Vector3(0.05, 0.06, 0.02), Vector3(x, 0.19, 0.155), EYES)
	LifeRoomKit.box(head, "Smile", Vector3(0.1, 0.025, 0.02), Vector3(0, 0.1, 0.155), EYES.lightened(0.2))
	for side: int in [-1, 1]:
		var arm := arm_near if side < 0 else arm_far
		arm.name = "ArmNear" if side < 0 else "ArmFar"
		arm.position = Vector3(0.23 * side, 0.38, 0)
		hips.add_child(arm)
		LifeRoomKit.box(arm, "Arm", Vector3(0.1, 0.34, 0.1), Vector3(0, -0.15, 0), colour.darkened(0.08))
		LifeRoomKit.box(arm, "Paw", Vector3(0.11, 0.08, 0.11), Vector3(0, -0.34, 0), SKIN)
		var leg := leg_near if side < 0 else leg_far
		leg.name = "LegNear" if side < 0 else "LegFar"
		leg.position = Vector3(0.1 * side, 0, 0)
		hips.add_child(leg)
		LifeRoomKit.box(leg, "Leg", Vector3(0.13, 0.42, 0.13), Vector3(0, -0.21, 0), colour.darkened(0.25))
	_mark("shoulder", hips, Vector3(-0.17, 0.4, 0.06))
	_mark("near_hand", arm_near, Vector3(0, -0.34, 0))
	_mark("far_hand", arm_far, Vector3(0, -0.34, 0))
	_mark("near_arm", arm_near, Vector3(0, -0.16, 0))
	_mark("far_knee", leg_far, Vector3(0, -0.22, 0.04))
	_mark("chin", head, Vector3(0, 0.03, 0.15))
	_mark("back", hips, Vector3(0, 0.3, -0.13))
	_mark("tummy", hips, Vector3(0, 0.14, 0.13))
	_mark("cut", arm_near, Vector3(0, -0.2, 0.06))
	_mark("cut2", arm_far, Vector3(0, -0.2, 0.06))


func _mark(mark_name: String, parent: Node3D, at: Vector3) -> void:
	var n := Node3D.new()
	n.name = "Mark_" + mark_name
	n.position = at
	parent.add_child(n)
	marks[mark_name] = n


func mark(mark_name: String) -> Node3D:
	return marks.get(mark_name)


## A soft "ouch" spot (a little warm glow, never a wound) on a mark; null to clear them all.
func show_ouch(mark_name: String) -> void:
	if mark_name == "":
		for o in ouch:
			o.queue_free()
		ouch.clear()
		return
	var m := mark(mark_name)
	if m != null:
		ouch.append(LifeRoomKit.sphere(m, "Ouch", 0.035, Vector3.ZERO, OUCH))


func pose(pose_name: String) -> void:
	current_pose = pose_name
	match pose_name:
		"sit_floor":
			_to(hips, Vector3(0, 0.13, 0), Vector3.ZERO)
			_to(leg_near, leg_near.position, Vector3(-PI / 2, 0, 0))
			_to(leg_far, leg_far.position, Vector3(-PI / 2, 0, 0))
			_to(arm_near, arm_near.position, Vector3(-0.3, 0, -0.2))
			_to(arm_far, arm_far.position, Vector3(-0.3, 0, 0.2))
		"sit":
			_to(hips, Vector3(0, 0.46, 0), Vector3.ZERO)
			_to(leg_near, leg_near.position, Vector3(-PI / 2, 0, 0))
			_to(leg_far, leg_far.position, Vector3(-PI / 2, 0, 0))
			_to(arm_near, arm_near.position, Vector3(-0.5, 0, 0))
			_to(arm_far, arm_far.position, Vector3(-0.5, 0, 0))
		"lie":   # on the back, face up, the head along -X of the parent
			_basis(Basis(Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)))
			_to(hips, Vector3(0, 0.42, 0), Vector3.ZERO)
			for limb: Node3D in [arm_near, arm_far, leg_near, leg_far]:
				_to(limb, limb.position, Vector3.ZERO)
			_to(head, head.position, Vector3.ZERO)
		"side":   # the recovery position: rolled towards the near side, the face to the child
			_basis(Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1)))
		_:
			_basis(Basis())
			_to(hips, Vector3(0, 0.42, 0), Vector3.ZERO)
			for limb: Node3D in [arm_near, arm_far, leg_near, leg_far, head]:
				_to(limb, limb.position, Vector3.ZERO)


## The recovery position's moves, one by one (each eases in).
func arm_out() -> void:
	_to(arm_near, arm_near.position, Vector3(0, 0, -PI / 2))


func hand_cheek() -> void:
	_to(arm_far, arm_far.position, Vector3(-0.4, 0, 2.6))


func knee_up() -> void:
	_to(leg_far, leg_far.position, Vector3(-1.1, 0, 0))


func roll_side() -> void:
	pose("side")


func head_tilt() -> void:
	_to(head, head.position, Vector3(-0.35, 0, 0))


## Owner #112, Calm Corner (design §5 #6: "name the feeling: the buddies' faces"): a friendly face for a feeling, made of
## the mouth's three pieces, two brows and the eyes' shape. Never scary: cross is frowning brows and a flat mouth.
func face(which: String) -> void:
	if not FEELINGS.has(which):
		return
	feeling = which
	if _face_parts.is_empty():
		_make_face_parts()
	(head.get_node("Smile") as Node3D).visible = false
	var mouth_y := 0.1
	var corner := 0.0   # + up (a smile), - down
	var brow_tilt := 0.0   # + inner ends up (sad, worried), - inner ends down (cross)
	var brow_y := 0.255
	var eye_squash := 1.0
	var mouth_w := 0.1
	match which:
		"happy":
			corner = 0.025
			mouth_w = 0.12
		"sad":
			corner = -0.025
			brow_tilt = 0.35
		"cross":
			brow_tilt = -0.45
			brow_y = 0.245
		"worried":
			brow_tilt = 0.3
			brow_y = 0.27
			mouth_w = 0.05
		"calm":
			corner = 0.012
			eye_squash = 0.35
	(_face_parts.mid as Node3D).position = Vector3(0, mouth_y, 0.158)
	(_face_parts.mid as Node3D).scale = Vector3(mouth_w / 0.1, 1, 1)
	for side: int in [-1, 1]:
		var c := _face_parts["corner_%d" % side] as Node3D
		c.position = Vector3(side * (mouth_w * 0.5 + 0.012), mouth_y + corner, 0.158)
		c.visible = absf(corner) > 0.001
		var b := _face_parts["brow_%d" % side] as Node3D
		b.position = Vector3(side * 0.07, brow_y, 0.158)
		b.rotation.z = -side * brow_tilt
	for e: Node in head.find_children("Eye*", "MeshInstance3D", false, false):
		(e as Node3D).scale = Vector3(1, eye_squash, 1)


func _make_face_parts() -> void:
	_face_parts.mid = LifeRoomKit.box(head, "Mouth", Vector3(0.1, 0.025, 0.02), Vector3(0, 0.1, 0.158), EYES.lightened(0.2))
	for side: int in [-1, 1]:
		_face_parts["corner_%d" % side] = LifeRoomKit.box(head, "MouthCorner", Vector3(0.025, 0.025, 0.02), Vector3.ZERO,
			EYES.lightened(0.2))
		_face_parts["brow_%d" % side] = LifeRoomKit.box(head, "Brow", Vector3(0.07, 0.018, 0.02), Vector3.ZERO, EYES)


## A little wave or nod (a buddy saying it is fine, a customer saying thank you).
func nod() -> void:
	if not is_inside_tree():
		return
	var tw := create_tween()
	tw.tween_property(head, "rotation:x", 0.25, 0.2)
	tw.tween_property(head, "rotation:x", 0.0, 0.25)


func _to(n: Node3D, at: Vector3, rot: Vector3) -> void:
	if _calm or not is_inside_tree():
		n.position = at
		n.rotation = rot
		return
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
	tw.tween_property(n, "position", at, EASE)
	tw.tween_property(n, "rotation", rot, EASE)


func _basis(b: Basis) -> void:
	if _calm or not is_inside_tree():
		basis = b
		return
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "quaternion", b.get_rotation_quaternion(), EASE)
