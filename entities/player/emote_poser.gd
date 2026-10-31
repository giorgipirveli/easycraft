class_name EmotePoser
extends SkeletonModifier3D
## The realistic avatar's emotes and dances (M3 Task 9). The Kenney clips have none, so the arms and
## legs are posed here from EmotePoses (the same poses the blocky body shows), over the idle clip;
## RealisticAvatar moves the whole body (hop, spin, lean, sit) and fades `influence` in and out.
## Limbs turn from their rest pose (the T-pose) in the body's frame, like SwimStrokes: the arm first
## hangs down, spreads out by `spread`, then swings forward and up about X by `pitch`.

const ARMS := [["LeftArm", "LeftForeArm", -1.0, "l_arm"], ["RightArm", "RightForeArm", 1.0, "r_arm"]]
const LEGS := [["LeftUpLeg", "LeftLeg", "l_leg"], ["RightUpLeg", "RightLeg", "r_leg"]]

## The pose to show (EmotePoses.sample).
var pose := EmotePoses.rest()
## Skeleton space -> the body's frame (rotation only); set once the model is fitted.
var to_body := Basis.IDENTITY

var _bones := {}


func _process_modification_with_delta(_delta: float) -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	for arm: Array in ARMS:
		var p: Vector2 = pose.get(arm[3], Vector2.ZERO)
		var turn := SwimStrokes.arm_turn(arm[2], p.x, p.y)
		_pose_limb(skel, arm[0], arm[1], turn)
	for leg: Array in LEGS:
		_pose_limb(skel, leg[0], leg[1], Basis(Vector3.RIGHT, float(pose.get(leg[2], 0.0))))
	var head: Vector3 = pose.get("head", Vector3.ZERO)
	if head != Vector3.ZERO:   # owner #94: a nod, a turn, a tilt (else the clip's own head)
		_pose_bone(skel, "Head", Basis.from_euler(head))


## Turns one bone by `turn` from its rest pose, in the body's frame.
func _pose_bone(skel: Skeleton3D, bone_name: String, turn: Basis) -> void:
	var bone := _bone(skel, bone_name)
	if bone < 0:
		return
	var parent := skel.get_bone_parent(bone)
	var parent_basis := skel.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var goal := to_body.inverse() * turn * to_body * skel.get_bone_global_rest(bone).basis
	skel.set_bone_pose_rotation(bone, (parent_basis.inverse() * goal).get_rotation_quaternion())


## Turns `upper` (and `lower` with it, straight) by `turn` from the rest pose, in the body's frame.
func _pose_limb(skel: Skeleton3D, upper_name: String, lower_name: String, turn: Basis) -> void:
	var upper := _bone(skel, upper_name)
	var lower := _bone(skel, lower_name)
	if upper < 0 or lower < 0:
		return
	var parent := skel.get_bone_parent(upper)
	var parent_basis := skel.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var t := to_body.inverse() * turn * to_body
	var upper_global := t * skel.get_bone_global_rest(upper).basis
	var lower_global := t * skel.get_bone_global_rest(lower).basis
	skel.set_bone_pose_rotation(upper, (parent_basis.inverse() * upper_global).get_rotation_quaternion())
	skel.set_bone_pose_rotation(lower, (upper_global.inverse() * lower_global).get_rotation_quaternion())


func _bone(skel: Skeleton3D, bone_name: String) -> int:
	if not _bones.has(bone_name):
		_bones[bone_name] = skel.find_bone(bone_name)
	return _bones[bone_name]
