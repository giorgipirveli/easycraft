class_name SwimStrokes
extends SkeletonModifier3D
## The realistic avatar's swim strokes (M2 Task 14). Kenney "Animated Characters 3" has only idle,
## run and jump clips, so the arms and legs are posed here, over the idle clip: a crawl (the arms
## windmill, the legs flutter) blended with treading water (the arms scull out to the sides, the legs
## pedal). RealisticAvatar tips the whole body; `influence` fades the strokes in and out.
##
## Each limb is turned from its rest pose (the T-pose) in the body's own frame (X right, Y up, -Z
## forward): the arm first hangs down, then swings about X (> 0 swings it forward and up).

const SWIM_SPREAD := 1.0       # rad: treading water, the arms scull out to the sides
const LIMBS := [
	["LeftArm", "LeftForeArm", -1.0],
	["RightArm", "RightForeArm", 1.0],
]
const LEGS := [
	["LeftUpLeg", "LeftLeg", -1.0],
	["RightUpLeg", "RightLeg", 1.0],
]

## Stroke phase (rad); RealisticAvatar advances it.
var phase := 0.0
## 0 = treading water, 1 = a full crawl.
var crawl := 0.0
## Skeleton space -> the body's frame (rotation only); set once the model is fitted.
var to_body := Basis.IDENTITY

var _bones := {}


## The arm's turn for a side (-1 left, 1 right): hang down (and out by `spread`), then swing about X.
static func arm_turn(side: float, swing: float, spread: float) -> Basis:
	return Basis(Vector3.RIGHT, swing) * Basis(Vector3.BACK, -side * (PI * 0.5 - spread))


func _process_modification_with_delta(_delta: float) -> void:
	var skel := get_skeleton()
	if skel == null:
		return
	var scull := sin(phase) * 0.45
	var spread := SWIM_SPREAD * (1.0 - crawl)
	for limb: Array in LIMBS:
		var side: float = limb[2]
		var crawl_swing := wrapf(-phase + (PI if side > 0.0 else 0.0), -PI, PI)
		var swing := lerp_angle(scull * -side, crawl_swing, crawl)
		var turn := arm_turn(side, swing, spread)
		_pose_limb(skel, limb[0], limb[1], turn, turn)
	var kick := sin(phase * 2.0) * 0.45 * crawl + sin(phase) * 0.5 * (1.0 - crawl)
	var knee := lerpf(0.5, 0.15, crawl)
	for leg: Array in LEGS:
		var k: float = kick * leg[2]
		_pose_limb(skel, leg[0], leg[1], Basis(Vector3.RIGHT, k), Basis(Vector3.RIGHT, k - knee * (0.5 + 0.5 * sin(phase + leg[2]))))


## Sets `upper` and `lower` so that, in the body's frame, each is turned by its basis from the rest pose.
func _pose_limb(skel: Skeleton3D, upper_name: String, lower_name: String, upper_turn: Basis, lower_turn: Basis) -> void:
	var upper := _bone(skel, upper_name)
	var lower := _bone(skel, lower_name)
	if upper < 0 or lower < 0:
		return
	var parent := skel.get_bone_parent(upper)
	var parent_basis := skel.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var inv := to_body.inverse()
	var upper_global := (inv * upper_turn * to_body) * skel.get_bone_global_rest(upper).basis
	var lower_global := (inv * lower_turn * to_body) * skel.get_bone_global_rest(lower).basis
	skel.set_bone_pose_rotation(upper, (parent_basis.inverse() * upper_global).get_rotation_quaternion())
	skel.set_bone_pose_rotation(lower, (upper_global.inverse() * lower_global).get_rotation_quaternion())


func _bone(skel: Skeleton3D, bone_name: String) -> int:
	if not _bones.has(bone_name):
		_bones[bone_name] = skel.find_bone(bone_name)
	return _bones[bone_name]
