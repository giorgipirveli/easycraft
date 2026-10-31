class_name VrBodyModifier
extends SkeletonModifier3D
## Owner #101 (VR on the Meta Quest, P4): the realistic person's skeleton for a remote VR player (VrBody), after its
## animation: the head bone turned by the headset's pose, and the arms folded away (their upper bones scaled to almost
## nothing: the floating hands show where the hands are). Off (`active` false), the skeleton is the animation's alone.

const HEAD_BONE := "Head"
const ARM_BONES: Array[String] = ["LeftUpperArm", "RightUpperArm"]
const FOLDED := Vector3(0.01, 0.01, 0.01)

## The head's turn from the animation's (the body's space).
var head := Basis()


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	var h := sk.find_bone(HEAD_BONE)
	if h >= 0:
		sk.set_bone_pose_rotation(h, Quaternion(head.orthonormalized()) * sk.get_bone_pose_rotation(h))
	for n in ARM_BONES:
		var b := sk.find_bone(n)
		if b >= 0:
			sk.set_bone_pose_scale(b, FOLDED)
