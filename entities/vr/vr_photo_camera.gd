class_name VrPhotoCamera
extends Node3D
## Owner #101 (VR on the Meta Quest, P3): PHOTO in a headset is a camera held in the pointing hand. Its own view (a
## SubViewport over the same world, a Camera3D at the hand's aim) shows on a little screen just above the hand, facing
## the child; the trigger takes the picture from it (PhotoMode). The main view never moves (no orbit round the player).
## The filter and the frame are drawn inside its viewport (PhotoMode moves them there), so the picture has them.

const SIZE := Vector2i(800, 600)
const SCREEN_SIZE := Vector2(0.24, 0.18)
const SCREEN_LIFT := 0.11    # m above the hand
const FOV := 60.0
## The child's own avatar is drawn on this render layer alone while PHOTO is open: the held camera sees it (a selfie),
## the head does not (it would be inside it). Free in the game's layers (the flight uses 1 << 18 and 1 << 19).
const SELF_LAYER := 1 << 17

var viewport := SubViewport.new()
var camera := Camera3D.new()
var screen := MeshInstance3D.new()


func _init() -> void:
	name = "VrPhotoCamera"
	viewport.name = "Lens"
	viewport.size = SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	add_child(viewport)
	camera.name = "Camera"
	camera.fov = FOV
	camera.near = 0.05
	camera.far = VrRig.FAR
	viewport.add_child(camera)
	var quad := QuadMesh.new()
	quad.size = SCREEN_SIZE
	screen.mesh = quad
	screen.name = "Screen"
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = viewport.get_texture()
	screen.material_override = mat
	add_child(screen)


## Over the same world as `world` (the game's).
func use_world(world: World3D) -> void:
	viewport.world_3d = world


## The lens at `lens` (the hand's aim: -Z looks ahead), the little screen just above it, turned to the eyes at `eye`.
func place(lens: Transform3D, eye: Vector3) -> void:
	camera.global_transform = lens
	var at := lens.origin + lens.basis.y.normalized() * SCREEN_LIFT
	var away := at - eye
	if away.length() < 0.01:
		away = -lens.basis.z
	var up := Vector3.UP if absf(away.normalized().y) < 0.99 else Vector3.BACK
	screen.global_transform = Transform3D(Basis.looking_at(away, up), at)
