class_name PlacePop
extends MeshInstance3D
## A block the player just placed pops in: a soft glow over it grows from 0.8 to 1.0 and fades
## (M2 Task 3, the lead's child-friendly feedback; the voxel block itself can't be scaled). The sound
## is the placing sound already played. One per player's BlockInteractor, reused for every block;
## one mesh and one material for the whole game, with the break ring's shader setup.

const START_SCALE := 0.8
const GROW_TIME := 0.14
const FADE_TIME := 0.22
const COLOR := Color(1.0, 1.0, 0.92, 0.55)

static var _box: BoxMesh   # its material is the pop's own (its alpha fades); one pop plays at a time

var _tween: Tween


func _ready() -> void:
	top_level = true
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if _box == null:
		_box = BoxMesh.new()
		_box.size = Vector3.ONE * 1.001   # just over the block, so its faces never flicker
		_box.material = BreakRing.feedback_material(COLOR)
	mesh = _box


func pop(block_pos: Vector3i) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	global_position = Vector3(block_pos) + Vector3(0.5, 0.5, 0.5)
	scale = Vector3.ONE * START_SCALE
	_set_glow(1.0)
	visible = true
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector3.ONE, GROW_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.parallel().tween_method(_set_glow, 1.0, 0.0, FADE_TIME).set_ease(Tween.EASE_IN)
	_tween.tween_callback(hide)


## Draws the glow once, tiny, in front of the camera (see BreakRing.prewarm).
func prewarm(camera: Camera3D) -> void:
	global_position = camera.global_position - camera.global_basis.z * 1.5
	scale = Vector3.ONE * 0.01
	_set_glow(1.0)
	visible = true
	get_tree().create_timer(BreakRing.PREWARM_SECONDS).timeout.connect(_end_prewarm)


func _end_prewarm() -> void:
	if scale.x < 0.5:   # still the tiny prewarm glow, not a real pop
		visible = false


func _set_glow(amount: float) -> void:
	(_box.material as StandardMaterial3D).albedo_color.a = COLOR.a * amount
