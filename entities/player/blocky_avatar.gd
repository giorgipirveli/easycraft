class_name BlockyAvatar
extends AvatarModel
## EasyCraft's blocky character, built from boxes and animated in code (no art assets). Owner 43 (spec §3c): its
## own proportions (a rounder head, its edges cut round, a little bigger) and the buddy badge on its chest
## (AvatarModel); the first colours are the default look's (peach skin, an orange tee, teal trousers).

const SKIN := Color("eab48f")    # AvatarCatalog.SKIN_TONES.peach
const TORSO := Color("fb8c00")   # AvatarCatalog.CLOTH.orange
const LEGS := Color("00a3a3")    # AvatarCatalog.CLOTH.teal
## Owner 43: the head is this much bigger, its centre lowered so its top stays at 1.8.
const HEAD_SCALE := 1.08
const HEAD_Y := 1.8 - 0.25 * HEAD_SCALE
## Owner 43: the head's three crossing boxes are this thick across (0.5 long): its edges are cut round.
const HEAD_ROUND := 0.42
const FACE := Color("1b1b1b")
const PIVOT_Y := 0.9          # body centre; flips rotate around it
const FLIP_TIME := 0.38
const AIR_ARM_ANGLE := 2.6   # positive = arms swing up in FRONT (the avatar faces -Z)

var _pivot: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _phase := 0.0
var _air_blend := 0.0
var _flip: Tween


func _ready() -> void:
	_pivot = Node3D.new()
	_pivot.position.y = PIVOT_Y
	add_child(_pivot)
	# M3 Task 9: named boxes on shared per-colour materials (AvatarParts), anchors for the look's
	# parts; the face is a part too (AvatarParts "face_*"), dressed from the look below.
	_head = _anchor("HeadAnchor", Vector3(0, HEAD_Y - PIVOT_Y, 0))
	_head.scale = Vector3.ONE * HEAD_SCALE   # owner 43: hair, hats and faces grow with it
	_box(_head, Vector3(0.5, HEAD_ROUND, HEAD_ROUND), Vector3.ZERO, SKIN, "Head")   # owner 43: three crossing boxes,
	_box(_head, Vector3(HEAD_ROUND, 0.5, HEAD_ROUND), Vector3.ZERO, SKIN, "HeadTall")   # not one cube: a rounder head
	_box(_head, Vector3(HEAD_ROUND, HEAD_ROUND, 0.5), Vector3.ZERO, SKIN, "HeadDeep")
	_box(_pivot, Vector3(0.62, 0.72, 0.32), Vector3(0, 1.0 - PIVOT_Y, 0), TORSO, "Torso")
	_body = _anchor("BodyAnchor", Vector3(0, 1.0 - PIVOT_Y, 0))
	_back = _anchor("BackAnchor", Vector3(0, 1.36 - PIVOT_Y, 0.16))
	_hip = _anchor("HipAnchor", Vector3(0, 0.66 - PIVOT_Y, 0.16))
	_left_arm = _limb(Vector3(-0.42, 1.32 - PIVOT_Y, 0), Vector3(0.22, 0.66, 0.26), SKIN, "LeftArm")
	_right_arm = _limb(Vector3(0.42, 1.32 - PIVOT_Y, 0), Vector3(0.22, 0.66, 0.26), SKIN, "RightArm")
	_left_leg = _limb(Vector3(-0.15, 0.64 - PIVOT_Y, 0), Vector3(0.28, 0.64, 0.3), LEGS, "LeftLeg")
	_right_leg = _limb(Vector3(0.15, 0.64 - PIVOT_Y, 0), Vector3(0.28, 0.64, 0.3), LEGS, "RightLeg")
	_box(_left_arm, Vector3(0.24, 0.2, 0.28), Vector3(0, -0.06, 0), TORSO, "LeftSleeve")
	_box(_right_arm, Vector3(0.24, 0.2, 0.28), Vector3(0, -0.06, 0), TORSO, "RightSleeve")
	_box(_left_leg, Vector3(0.3, 0.12, 0.33), Vector3(0, -0.54, -0.01), LEGS, "LeftShoe").visible = false
	_box(_right_leg, Vector3(0.3, 0.12, 0.33), Vector3(0, -0.54, -0.01), LEGS, "RightShoe").visible = false
	_hand.name = "Hand"                       # the right fist: held items hang here (M1b Task 11)
	_hand.position = HAND_OFFSET
	_right_arm.add_child(_hand)
	_dress(_resolved())


## Called every physics frame with the horizontal speed in m/s.
func animate(horizontal_speed: float, on_floor: bool, delta: float) -> void:
	var stride := clampf(horizontal_speed / 6.0, 0.0, 1.0)
	_phase += delta * (4.0 + 6.0 * stride)
	var swing := sin(_phase) * 0.9 * stride
	_air_blend = move_toward(_air_blend, 0.0 if on_floor else 1.0, delta * 6.0)
	_left_leg.rotation.x = lerpf(swing, 0.35, _air_blend)
	_right_leg.rotation.x = lerpf(-swing, -0.35, _air_blend)
	_left_arm.rotation.x = lerpf(-swing, AIR_ARM_ANGLE, _air_blend)
	_right_arm.rotation.x = lerpf(swing, AIR_ARM_ANGLE, _air_blend)
	_apply_attack_pose(delta)
	_dress_tick(horizontal_speed, on_floor, delta)
	var emote_pose := _emote_step(horizontal_speed, delta, on_floor)
	if not emote_pose.is_empty():
		_show_emote(emote_pose, _emote_w)


## Air jumps (2nd and 3rd) do a forward flip.
func play_jump(index: int) -> void:
	stop_emote(true)
	if index < 2:
		return
	if _flip and _flip.is_valid():
		_flip.kill()
	_pivot.rotation.x = 0.0
	_flip = create_tween()
	_flip.tween_property(_pivot, "rotation:x", -TAU, FLIP_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flip.tween_callback(func() -> void: _pivot.rotation.x = 0.0)


func _limb(joint: Vector3, size: Vector3, color: Color, mesh_name: String) -> Node3D:
	var j := Node3D.new()
	j.name = mesh_name + "Joint"
	j.position = joint
	_pivot.add_child(j)
	_box(j, size, Vector3(0, -size.y * 0.5 + 0.04, 0), color, mesh_name)
	return j


## A box of the body: one shared mesh per size and one shared material per colour (AvatarParts).
func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, mesh_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = AvatarParts.box_mesh(size)
	mi.material_override = AvatarParts.material(color)
	mi.position = pos
	parent.add_child(mi)
	_meshes[mesh_name] = mi
	return mi


func _anchor(anchor_name: String, pos: Vector3) -> Node3D:
	var a := Node3D.new()
	a.name = anchor_name
	a.position = pos
	_pivot.add_child(a)
	return a

# --- Looks and emotes (M3 Task 9) ---

var _head: Node3D
var _body: Node3D
var _back: Node3D
var _hip: Node3D
var _meshes := {}   # box name -> MeshInstance3D

# Owner 48: sleeves and shoes change size with the clothes (the boxes' own sizes are in _ready)
const SLEEVE_HEIGHT := 0.2
const SLEEVE_TOP := 0.04         # the short sleeve's top, at the shoulder joint
const LONG_SLEEVE := 2.6         # a long sleeve is this many short ones: down to the wrist, the hand bare
const PUFF := Vector3(1.3, 1.15, 1.3)
const SHOE_HEIGHT := 0.12
const SHOE_Y := -0.54
const BOOT_SCALE := 2.0


func head_anchor() -> Node3D:
	return _head


## Owner #101 (P4): the two arms (a remote VR player's floating hands fold them away: VrBody).
func arms() -> Array[Node3D]:
	return [_left_arm, _right_arm]


func back_anchor() -> Node3D:
	return _back


func hip_anchor() -> Node3D:
	return _hip


func body_anchor() -> Node3D:
	return _body


func _builds_everything() -> bool:
	return true


func _color_body(r: Dictionary) -> void:
	var skin := AvatarParts.material(r.skin)
	var shirt := AvatarParts.material(r.shirt)
	for n: String in ["Head", "HeadTall", "HeadDeep", "LeftArm", "RightArm"]:
		(_meshes[n] as MeshInstance3D).material_override = skin
	for n: String in ["Torso", "LeftSleeve", "RightSleeve"]:
		(_meshes[n] as MeshInstance3D).material_override = shirt
	for n: String in ["LeftLeg", "RightLeg"]:
		(_meshes[n] as MeshInstance3D).material_override = AvatarParts.material(r.pants)
	var shoes: Color = r.shoes
	var boots := bool(r.get("boots", false))
	for n: String in ["LeftShoe", "RightShoe"]:
		var shoe := _meshes[n] as MeshInstance3D
		shoe.visible = shoes.a > 0.0
		if shoe.visible:
			shoe.material_override = AvatarParts.material(Color(shoes, 1.0))
		# Owner 48: boots are taller shoes (their sole stays on the ground)
		shoe.scale = Vector3(1.0, BOOT_SCALE if boots else 1.0, 1.0)
		shoe.position.y = SHOE_Y + (SHOE_HEIGHT * (BOOT_SCALE - 1.0) * 0.5 if boots else 0.0)
	# Owner 48: long sleeves (a hoodie, a jacket) reach the wrist; a dress puffs its short sleeves
	var sleeves: Color = r.get("sleeves", Color(0, 0, 0, 0))
	var puff := bool(r.get("puff", false))
	for n: String in ["LeftSleeve", "RightSleeve"]:
		var sleeve := _meshes[n] as MeshInstance3D
		if sleeves.a > 0.0:
			sleeve.material_override = AvatarParts.material(Color(sleeves, 1.0))
			sleeve.scale = Vector3(1.0, LONG_SLEEVE, 1.0)
			sleeve.position.y = SLEEVE_TOP - SLEEVE_HEIGHT * LONG_SLEEVE * 0.5
		else:
			sleeve.scale = PUFF if puff else Vector3.ONE
			sleeve.position.y = SLEEVE_TOP - SLEEVE_HEIGHT * sleeve.scale.y * 0.5


## Blends the limbs and the body towards an emote pose (EmotePoses) by w.
func _show_emote(p: Dictionary, w: float) -> void:
	if _pivot == null:
		return
	for limb: Array in [[_left_arm, "l_arm", -1.0], [_right_arm, "r_arm", 1.0]]:
		var joint: Node3D = limb[0]
		var a: Vector2 = p.get(limb[1], Vector2.ZERO)
		joint.rotation.x = lerp_angle(joint.rotation.x, a.x, w)
		joint.rotation.z = lerpf(joint.rotation.z, float(limb[2]) * a.y, w)
	_left_leg.rotation.x = lerpf(_left_leg.rotation.x, float(p.get("l_leg", 0.0)), w)
	_right_leg.rotation.x = lerpf(_right_leg.rotation.x, float(p.get("r_leg", 0.0)), w)
	_head.rotation = (p.get("head", Vector3.ZERO) as Vector3) * w   # owner #94: nods, turns and tilts (0: ahead)
	_pose_pivot(_pivot, PIVOT_Y, p, w)


# --- AvatarModel (M1b Task 13) ------------------------------------------------------------------

const SLEEP_PIVOT_Y := 0.18    # lying on the back: the torso's back touches the ground (or bed)

func body_pivot() -> Node3D:
	return _pivot if _pivot else self


func set_pose(new_pose: StringName) -> void:
	super(new_pose)
	if _pivot == null:
		return
	var sleeping := new_pose == POSE_SLEEP
	if _flip and _flip.is_valid():
		_flip.kill()
	_pivot.rotation.x = PI * 0.5 if sleeping else 0.0
	_pivot.position.y = SLEEP_PIVOT_Y if sleeping else PIVOT_Y

# --- Held items and attack poses (M1b Task 11) ---

const HAND_OFFSET := Vector3(0, -0.56, -0.06)   # the fist, at the end of the right arm
const AIM_ANGLE := 1.55                          # bow drawn: both arms straight forward
## Right arm keyframes per attack (see HeldItem.SWINGS): [pitch, roll, seconds]; pitch > 0 is
## forward and up, roll > 0 swings the hand outwards.
const ARM_SWINGS := {
	&"slash": [[2.6, 0.2, 0.08], [0.5, -0.1, 0.1]],
	&"sweep": [[1.3, 0.9, 0.07], [1.3, -0.6, 0.12]],
	&"spin": [[1.4, 0.9, 0.05], [1.4, 0.9, 0.25]],
	&"smash": [[3.0, 0.0, 0.32], [0.4, 0.0, 0.09], [0.4, 0.0, 0.12]],
	&"chop": [[2.5, 0.3, 0.12], [0.5, -0.2, 0.1]],
	&"pick": [[2.8, 0.0, 0.08], [0.3, 0.0, 0.08]],
	&"throw": [[-0.9, 0.0, 0.1], [2.0, 0.0, 0.08]],
	&"shoot": [[AIM_ANGLE + 0.25, 0.0, 0.04], [AIM_ANGLE, 0.0, 0.1]],
	&"punch": [[AIM_ANGLE - 0.5, 0.2, 0.05], [AIM_ANGLE + 0.1, -0.1, 0.07]],   # owner feedback #29: fists
}
const RELEASE_TIME := 0.16

var _hand := Node3D.new()
var _attack: Tween
var _attack_w := 0.0
var _attack_rx := 0.0
var _attack_rz := 0.0
var _aim_w := 0.0
var _aiming := false


## Where a held item goes: its grip at the origin, pointing along -Z (forward while the arm
## hangs down); -Y runs along the arm, away from the shoulder.
func hand() -> Node3D:
	return _hand


## Swings the right arm for an attack (the held item adds a wrist motion); the sword's third
## swing spins the whole body.
func play_attack(weapon_id: int, combo: int = 0) -> void:
	var swing := HeldItem.swing_name(weapon_id, combo)
	var keys: Array = ARM_SWINGS.get(swing, [])
	if keys.is_empty():
		return
	if _attack and _attack.is_valid():
		_attack.kill()
	_attack_rx = _right_arm.rotation.x
	_attack_rz = 0.0
	_attack_w = 1.0
	_attack = create_tween()
	for k: Array in keys:
		_attack.tween_property(self, "_attack_rx", float(k[0]), k[2]).set_trans(Tween.TRANS_SINE)
		_attack.parallel().tween_property(self, "_attack_rz", float(k[1]), k[2]).set_trans(Tween.TRANS_SINE)
	_attack.tween_property(self, "_attack_w", 0.0, RELEASE_TIME)
	if swing == &"spin":
		_pivot.rotation.y = 0.0
		var spin := create_tween()
		spin.tween_property(_pivot, "rotation:y", -TAU, 0.3).set_trans(Tween.TRANS_SINE)
		spin.tween_callback(func() -> void: _pivot.rotation.y = 0.0)


## Bow drawn: both arms forward.
func set_aiming(on: bool) -> void:
	_aiming = on


func _apply_attack_pose(delta: float) -> void:
	_aim_w = move_toward(_aim_w, 1.0 if _aiming else 0.0, delta * 8.0)
	if _aim_w > 0.0:
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, AIM_ANGLE, _aim_w)
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x, AIM_ANGLE, _aim_w)
	_left_arm.rotation.z = 0.35 * _aim_w       # the left hand reaches for the string
	if _attack_w > 0.0:
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, _attack_rx, _attack_w)
	_right_arm.rotation.z = _attack_rz * _attack_w

# --- Swimming (M2 Task 14, owner feedback #17) ---

const TREAD_SPREAD := 0.9      # rad: treading water, the arms scull out to the sides


## Crawl: the arms windmill (reach ahead, pull under the body, recover over the back) and the legs
## flutter; treading water: the arms scull out to the sides and the legs pedal.
func swim(horizontal_speed: float, vertical_speed: float, delta: float) -> void:
	if _pivot == null:
		return
	_tip(_pivot, PIVOT_Y, horizontal_speed, vertical_speed, delta)
	var crawl := clampf(Vector2(horizontal_speed, vertical_speed).length() / SWIM_CRAWL_FROM, 0.0, 1.0)
	_phase += delta * lerpf(3.0, 5.5, crawl)
	var scull := sin(_phase) * 0.45
	_left_arm.rotation.x = lerp_angle(scull, wrapf(-_phase, -PI, PI), crawl)
	_right_arm.rotation.x = lerp_angle(-scull, wrapf(-_phase + PI, -PI, PI), crawl)
	var kick := sin(_phase * 2.0) * 0.45 * crawl + sin(_phase) * 0.5 * (1.0 - crawl)
	_left_leg.rotation.x = kick
	_right_leg.rotation.x = -kick
	_air_blend = 0.0
	_apply_attack_pose(delta)
	_left_arm.rotation.z -= TREAD_SPREAD * (1.0 - crawl)
	_right_arm.rotation.z += TREAD_SPREAD * (1.0 - crawl)
