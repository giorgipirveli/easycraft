class_name VrMirror
extends Node3D
## Owner #101 (VR on the Meta Quest, P4): a mirror to see your own avatar (optional: Vr.set_mirror). A framed glass
## stands where the child looks, 1.6 m ahead, world-fixed; behind it a camera on the child's eye reflected through the
## glass renders the room into it (an off-axis frustum on the glass, the picture flipped), so the child sees their own
## avatar dance, wave and nod (VrBody turns its head, the rig's hands are seen too). Only while it is open does the
## avatar show (on VrPhotoCamera.SELF_LAYER: never from inside the head); its viewport renders only then.

const SIZE := Vector2(1.1, 1.8)
const PIXELS := Vector2i(440, 720)
const AHEAD := 1.6
const FRAME := 0.05
const FAR := 60.0

var viewport := SubViewport.new()
var camera := Camera3D.new()
var glass := MeshInstance3D.new()


func _init() -> void:
	name = "VrMirror"
	viewport.name = "Glass"
	viewport.size = PIXELS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	camera.name = "Reflection"
	camera.projection = Camera3D.PROJECTION_FRUSTUM
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	viewport.add_child(camera)
	var quad := QuadMesh.new()
	quad.size = SIZE
	glass.mesh = quad
	glass.name = "GlassQuad"
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = viewport.get_texture()
	mat.uv1_scale = Vector3(-1.0, 1.0, 1.0)   # a mirror: left and right swapped
	mat.uv1_offset = Vector3(1.0, 0.0, 0.0)
	glass.material_override = mat
	add_child(glass)
	var frame := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(SIZE.x + FRAME * 2.0, SIZE.y + FRAME * 2.0, 0.03)
	frame.mesh = box
	frame.name = "Frame"
	frame.position = Vector3(0.0, 0.0, -0.02)
	frame.material_override = AvatarParts.material(Color("8d5a2b"))
	frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(frame)


## Over the same world as `world` (the game's).
func use_world(world: World3D) -> void:
	viewport.world_3d = world


## Stands the glass AHEAD m from the eye, facing it, level, its middle a little under the eye.
func stand_before(eye: Transform3D) -> void:
	var fwd := -eye.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	var at := eye.origin + fwd * AHEAD + Vector3(0.0, -0.35, 0.0)
	global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), at)   # -Z away from the child: +Z faces them


## The reflection for an eye at `eye_at`: the camera at the eye mirrored through the glass, looking through it into
## the room, its frustum exactly the glass.
func reflect(eye_at: Vector3) -> void:
	var g := glass.global_transform
	var n := g.basis.z.normalized()        # the glass faces the child along +Z
	var d := (eye_at - g.origin).dot(n)
	if d <= 0.05:
		return   # behind or at the glass: nothing to see
	var mirrored := eye_at - n * (2.0 * d)
	camera.global_transform = Transform3D(Basis.looking_at(n, Vector3.UP), mirrored)   # looks back through the glass
	var local := camera.global_transform.affine_inverse() * g.origin
	camera.set_frustum(SIZE.y, Vector2(local.x, local.y), d, FAR)
	camera.cull_mask = (1 << 20) - 1
