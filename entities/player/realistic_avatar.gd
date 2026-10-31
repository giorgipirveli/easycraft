class_name RealisticAvatar
extends AvatarModel
## The player's body in the REALISTIC style (M1b Task 13): a real-looking, kid-friendly person.
## Kenney "Animated Characters 3" (CC0): one skinned mesh of 1.6k triangles, one material, a 256² skin
## texture, with idle, run and jump clips. Walking plays the run clip slower; falling holds the
## airborne jump pose. Faces -Z, feet at y = 0 and 1.8 blocks tall, like BlockyAvatar.

const MODEL_PATH := "res://assets/characters/kenney_human/characterMedium.fbx"
## Our animation name -> [clip file, clip]. Each clip file is imported as an AnimationLibrary with
## its clip looping (see the .import files).
const CLIPS := {
	&"idle": ["res://assets/characters/kenney_human/idle.fbx", &"Root|Idle"],
	&"walk": ["res://assets/characters/kenney_human/run.fbx", &"Root|Run"],
	&"run": ["res://assets/characters/kenney_human/run.fbx", &"Root|Run"],
	&"jump": ["res://assets/characters/kenney_human/jump.fbx", &"Root|Jump"],
	&"fall": ["res://assets/characters/kenney_human/jump.fbx", &"Root|Jump"],
}
const SKINS: Array[String] = [
	"res://assets/characters/kenney_human/humanMaleA.png",
	"res://assets/characters/kenney_human/humanFemaleA.png",
]
const HAND_BONE := "RightHand"
const FINGER_BONE := "RightHandIndex1"
const PIVOT_Y := 0.9          # body centre; flips rotate around it
const WALK_FROM := 0.4        # m/s; slower is idle
const RUN_FROM := 3.5         # m/s; a half-tilted joystick walks, a full one runs
const STRIDE_SPEED := 4.0     # m/s at which the run clip plays at its own speed (1.8 m tall)
const MIN_PLAYBACK := 0.55
const MAX_PLAYBACK := 2.0
const FALL_DELAY := 0.15      # s in the air before the fall pose: stepping down keeps running
const LAND_DELAY := 0.06      # s on the ground before landing: a remote jump's apex stays airborne
const BLEND := 0.15
const FLIP_TIME := 0.38
const SLEEP_PIVOT_Y := 0.18   # lying on the back: the back touches the ground (or bed)

## Tests point this at a missing file to check the blocky fallback.
static var model_path := MODEL_PATH
static var _library: AnimationLibrary
static var _materials := {}

## Which of SKINS to wear; set before adding to the tree (Player uses skin_for(peer_id)).
var skin_index := 0

var _pivot: Node3D
var _model: Node3D
var _skeleton: Skeleton3D
var _mesh: MeshInstance3D
var _player: AnimationPlayer
var _hand: Node3D
var _current := &""
var _air := 0.0
var _airborne := false
var _flip: Tween


## The animation for a horizontal speed (m/s) and floor state.
static func animation_for(speed: float, on_floor: bool) -> StringName:
	if not on_floor:
		return &"fall"
	if speed < WALK_FROM:
		return &"idle"
	return &"walk" if speed < RUN_FROM else &"run"


## Playback speed of `anim`: strides follow the ground speed; bigger bodies take longer strides.
static func playback_speed(anim: StringName, speed: float, size: float) -> float:
	if anim != &"walk" and anim != &"run":
		return 1.0
	return clampf(speed / (STRIDE_SPEED * maxf(size, 0.01)), MIN_PLAYBACK, MAX_PLAYBACK)


## The host (and solo) wears the first skin; guests get theirs from their peer id.
static func skin_for(peer_id: int) -> int:
	return posmod(peer_id - 1, SKINS.size())


## The character scene, or null when the asset is missing or broken (Player then stays blocky).
static func load_model() -> PackedScene:
	if not ResourceLoader.exists(model_path):
		return null
	return load(model_path) as PackedScene


func _ready() -> void:
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	_pivot.position.y = PIVOT_Y
	add_child(_pivot)
	var scene := load_model()
	if scene == null:
		return
	_model = scene.instantiate() as Node3D
	_pivot.add_child(_model)
	var skeletons := _model.find_children("*", "Skeleton3D", true, false)
	var meshes := _model.find_children("*", "MeshInstance3D", true, false)
	if skeletons.is_empty() or meshes.is_empty():
		push_warning("RealisticAvatar: %s has no skinned mesh" % model_path)
		return
	_skeleton = skeletons[0] as Skeleton3D
	_mesh = meshes[0] as MeshInstance3D
	_mesh.set_surface_override_material(0, _skin_material(skin_index))
	_fit_model()
	_player = AnimationPlayer.new()
	_player.name = "AnimationPlayer"
	_model.add_child(_player)   # root_node ".." is the model: clip tracks are "Root/Skeleton3D:<bone>"
	_player.add_animation_library(&"", _animations())
	_play(&"idle")
	_make_hand()
	_make_strokes()
	_make_look_nodes()


func animate(horizontal_speed: float, on_floor: bool, delta: float) -> void:
	_animate_clip(horizontal_speed, on_floor, delta)
	if _player == null:
		return
	_dress_tick(horizontal_speed, on_floor, delta)
	var emote_pose := _emote_step(horizontal_speed, delta, on_floor)
	if not emote_pose.is_empty():
		_show_emote(emote_pose, _emote_w)


func _animate_clip(horizontal_speed: float, on_floor: bool, delta: float) -> void:
	if _player == null:
		return
	if on_floor:
		_air = move_toward(_air, 0.0, delta / LAND_DELAY)
	else:
		_air = move_toward(_air, 1.0, delta / FALL_DELAY)
	if _air >= 1.0:
		_airborne = true
	elif _air <= 0.0:
		_airborne = false
	var anim := animation_for(horizontal_speed, not _airborne)
	if pose == POSE_SLEEP:
		anim = &"idle"
	elif anim == &"fall" and _current == &"jump":
		anim = &"jump"   # a jump flows into the air
	_play(anim)
	_player.speed_scale = playback_speed(anim, horizontal_speed, scale.x)


## Every jump restarts the jump pose; air jumps (2nd and 3rd) also do a forward flip.
func play_jump(index: int) -> void:
	stop_emote(true)
	if _player == null:
		return
	_air = 1.0
	_airborne = true
	_play(&"jump", true)
	if index < 2:
		return
	if _flip and _flip.is_valid():
		_flip.kill()
	_pivot.rotation.x = 0.0
	_flip = create_tween()
	_flip.tween_property(_pivot, "rotation:x", -TAU, FLIP_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flip.tween_callback(func() -> void: _pivot.rotation.x = 0.0)


## A BoneAttachment3D on the right-hand bone carries this node (see AvatarModel.hand).
func hand() -> Node3D:
	return _hand if _hand else self


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
	if (sleeping or new_pose == POSE_SWIM) and _player:
		_play(&"idle")
	if _strokes:
		_strokes.influence = 0.0
		_strokes.active = new_pose == POSE_SWIM


func skeleton() -> Skeleton3D:
	return _skeleton


func body_mesh() -> MeshInstance3D:
	return _mesh


func animation_player() -> AnimationPlayer:
	return _player


func _play(anim: StringName, restart: bool = false) -> void:
	if (anim == _current and not restart) or not _player.has_animation(anim):
		return
	# walk/run and jump/fall share a clip: switching between them keeps the stride's phase.
	var same_clip := _current != &"" and _player.is_playing() \
		and _player.get_animation(anim) == _player.get_animation(_current)
	var at := _player.current_animation_position if same_clip else 0.0
	_player.play(anim, 0.0 if same_clip else BLEND)
	if restart:
		_player.seek(0.0, true)
	elif same_clip:
		_player.seek(at, true)
	_current = anim


## The model faces +Z and is about 3.8 units tall: turn it to face -Z, scale it to the blocky
## avatar's height and stand its feet on y = 0.
func _fit_model() -> void:
	_model.rotation.y = PI
	var box := _relative(_mesh, _model) * _mesh.get_aabb()
	var s := SizeMagic.PLAYER_HEIGHT / box.size.y
	_model.scale = Vector3.ONE * s
	_model.position.y = -PIVOT_Y - box.position.y * s


## The hand frame sits in the palm; in the rest pose (a T-pose) its -Y runs along the arm to the
## fingers and its -Z points forward, with the body's scale (the rig's 100x unit scale cancelled).
func _make_hand() -> void:
	var bone := _skeleton.find_bone(HAND_BONE)
	if bone < 0:
		return
	var attachment := BoneAttachment3D.new()
	attachment.name = "RightHand"
	attachment.bone_name = HAND_BONE
	_skeleton.add_child(attachment)
	_hand = Node3D.new()
	_hand.name = "Hand"
	attachment.add_child(_hand)
	var to_avatar := _relative(_skeleton, self)
	var wrist := to_avatar * _skeleton.get_bone_global_rest(bone)
	var finger := _skeleton.find_bone(FINGER_BONE)
	var tip := (to_avatar * _skeleton.get_bone_global_rest(finger)).origin if finger >= 0 \
		else wrist.origin + Vector3.RIGHT * 0.1
	var y := (wrist.origin - tip).normalized()
	var z := (Vector3.BACK - y * Vector3.BACK.dot(y)).normalized()
	var frame := Transform3D(Basis(y.cross(z), y, z), (wrist.origin + tip) * 0.5)
	_hand.transform = wrist.affine_inverse() * frame


## `node`'s transform in the space of its ancestor `top`.
static func _relative(node: Node3D, top: Node) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != top and n is Node3D:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t


## One shared library for every realistic avatar, built once from the imported clip files.
static func _animations() -> AnimationLibrary:
	if _library == null:
		_library = AnimationLibrary.new()
		for anim_name: StringName in CLIPS:
			var source: Array = CLIPS[anim_name]
			var clips := load(source[0]) as AnimationLibrary
			if clips and clips.has_animation(source[1]):
				_library.add_animation(anim_name, clips.get_animation(source[1]))
	return _library


## One shared material per skin.
static func _skin_material(index: int) -> StandardMaterial3D:
	var i := posmod(index, SKINS.size())
	if not _materials.has(i):
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = load(SKINS[i])
		# Like the block atlas: the OpenGL (Compatibility) renderer needs the sRGB decode forced.
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mat.roughness = 0.85
		_materials[i] = mat
	return _materials[i]

# --- Swimming (M2 Task 14, owner feedback #17) ---

const STROKE_BLEND := 0.25    # s to fade the strokes in

var _strokes: SwimStrokes


## The clips have no swim (ruling in docs/devlog/parts/m2-task-14.md): the body tips like the blocky
## one, the idle clip keeps breathing, and SwimStrokes poses the arms and legs over it.
func swim(horizontal_speed: float, vertical_speed: float, delta: float) -> void:
	if _player == null:
		return
	_tip(_pivot, PIVOT_Y, horizontal_speed, vertical_speed, delta)
	_play(&"idle")
	_player.speed_scale = 1.0
	_strokes.active = true
	_strokes.crawl = clampf(Vector2(horizontal_speed, vertical_speed).length() / SWIM_CRAWL_FROM, 0.0, 1.0)
	_strokes.phase += delta * lerpf(3.0, 5.5, _strokes.crawl)
	_strokes.influence = move_toward(_strokes.influence, 1.0, delta / STROKE_BLEND)


func swim_strokes() -> SwimStrokes:
	return _strokes


func _make_strokes() -> void:
	_strokes = SwimStrokes.new()
	_strokes.name = "SwimStrokes"
	_strokes.to_body = _relative(_skeleton, _pivot).basis.orthonormalized()
	_strokes.influence = 0.0
	_strokes.active = false
	_skeleton.add_child(_strokes)

# --- Looks and emotes (M3 Task 9) ---

## Where the box parts sit, in the avatar's space at rest (the blocky body's parts, scaled down).
const HEAD_CENTER := Vector3(0, 1.53, -0.01)
const FACE_CENTER := Vector3(0, 1.455, -0.02)   # the eyes sit lower under the Kenney hair than on the blocky head
const BACK_POINT := Vector3(0, 1.22, 0.12)
const HIP_POINT := Vector3(0, 0.66, 0.1)
const COVER_SCALE := Vector3(1.12, 1.1, 1.3)
const COVER_OFFSET := Vector3(0, -0.02, 0.05)
## Owner 48: the chest (hoodie pockets, overall bibs, the jacket's tee) and the waist (skirts), where the
## "_real" clothes recipes are built in metres (measured on the Kenney mesh at rest: the waist at 0.78 m,
## the hips ±0.17 m wide, the chest's front 0.12 m ahead of the spine).
const CHEST_POINT := Vector3(0, 0.95, -0.02)
const WAIST_POINT := Vector3(0, 0.78, -0.025)

var _head_frame: Node3D
var _face_frame: Node3D
var _back_frame: Node3D
var _hip_frame: Node3D
var _chest_frame: Node3D
var _waist_frame: Node3D
var _poser: EmotePoser


func head_anchor() -> Node3D:
	return _head_frame


func face_anchor() -> Node3D:
	return _face_frame


func back_anchor() -> Node3D:
	return _back_frame


func hip_anchor() -> Node3D:
	return _hip_frame


## Owner 48: the chest, for the clothes' front pieces (blocky-only torso boxes still skip this body).
func body_anchor() -> Node3D:
	return _chest_frame


func waist_anchor() -> Node3D:
	return _waist_frame


func emote_poser() -> EmotePoser:
	return _poser


## The recolour shader material of the look (one per look, shared: AvatarSkin).
func _color_body(r: Dictionary) -> void:
	if _mesh:
		_mesh.set_surface_override_material(0, AvatarSkin.material(AvatarSkin.variant_for(r.hair, r.get("lashes", false)), r))


## The Kenney head is deeper than a blocky head, and its hair reaches further back: helmets fit a
## little bigger and further back.
func _fit_cover(part: Node3D) -> void:
	part.scale = COVER_SCALE
	part.position = COVER_OFFSET


func _show_emote(p: Dictionary, w: float) -> void:
	if _poser == null:
		return
	_poser.pose = p
	_poser.influence = w
	_poser.active = w > 0.0
	_pose_pivot(_pivot, PIVOT_Y, p, w)


## Frames for the box parts on the head, chest and hip bones (like the hand: the rig's scale
## cancelled, the parts at the realistic head and back scale), the emote poser, and the look (when
## one was given before the model was ready).
func _make_look_nodes() -> void:
	_head_frame = _bone_frame("Head", HEAD_CENTER, REALISTIC_HEAD_SCALE, "HeadAnchor")
	_face_frame = _bone_frame("Head", FACE_CENTER, REALISTIC_HEAD_SCALE, "FaceAnchor")
	_back_frame = _bone_frame("UpperChest", BACK_POINT, REALISTIC_BACK_SCALE, "BackAnchor")
	_hip_frame = _bone_frame("Hips", HIP_POINT, REALISTIC_BACK_SCALE, "HipAnchor")
	_chest_frame = _bone_frame("Chest", CHEST_POINT, 1.0, "ChestAnchor")    # Owner 48
	_waist_frame = _bone_frame("Hips", WAIST_POINT, 1.0, "WaistAnchor")
	_poser = EmotePoser.new()
	_poser.name = "EmotePoser"
	_poser.to_body = _relative(_skeleton, _pivot).basis.orthonormalized()
	_poser.influence = 0.0
	_poser.active = false
	_skeleton.add_child(_poser)
	if _look_applied:
		_dress(_resolved())


## A node on `bone` that stands at `at` (avatar space, at rest) with the avatar's axes and scale `s`.
func _bone_frame(bone_name: String, at: Vector3, s: float, frame_name: String) -> Node3D:
	var bone := _skeleton.find_bone(bone_name)
	if bone < 0:
		return null
	var attachment := BoneAttachment3D.new()
	attachment.name = bone_name + "Attachment"
	attachment.bone_name = bone_name
	_skeleton.add_child(attachment)
	var frame := Node3D.new()
	frame.name = frame_name
	attachment.add_child(frame)
	var rest := _relative(_skeleton, self) * _skeleton.get_bone_global_rest(bone)
	frame.transform = rest.affine_inverse() * Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s), at)
	return frame
