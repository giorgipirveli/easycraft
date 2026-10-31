class_name VrLens
extends Node3D
## Owner #110 (VR round 4, VR-WONDER, idea 2 "lens tools"; docs/devlog/parts/vr-r4-wonder.md, the research
## docs/devlog/parts/vr-ideas-research.md §5.3, ruling R7): the telescope and the magnifier in a headset. The one chosen
## in the hotbar (ItemIds.TELESCOPE, MAGNIFIER) is in the pointing hand: VR-HANDS' grabber is given it (a VrGrabbable of
## kind &"tool": its trigger is the lens's, the hand's laser is off) and steps it (keep_in_hand). Another item puts it
## away; letting go of the grip keeps it (it is the hotbar's item, as a sword stays in the hand).
##
## - **R7: the zoom happens only inside the lens.** A round disc world-locked to the hand shows what the lens's own camera
##   sees (a SubViewport over the same world, VrPhotoCamera's way): the part of the world the disc covers from the eyes,
##   narrowed by the zoom (LensRules.fov_degrees). The head's view never changes.
## - **The telescope:** a brass tube; its eyepiece disc faces the child, its camera looks out of the front along the
##   tube. The trigger zooms 2x to 8x; the view is steadied (LensRules.steady: a zoomed tremor is magnified too).
## - **The magnifier:** a round glass on a handle; it shows what is behind it from the eyes, 2x to 4x. Over a block with a
##   close-up (LensRules.CLOSEUPS: sand, leaves, a trunk, snow, ores...) within 60 cm the glass shows its close-up (our own
##   picture, VrLensCloseups) and its name and fact float over it (read aloud the first time, when "Read to me" is on);
##   its camera then rests (no second render).
## Drawn only while held. Off VR none of it exists.

const TELESCOPE_RADIUS := 0.04
const MAGNIFIER_RADIUS := 0.05
## The telescope along -Z from the grip: the eyepiece (the disc the child looks at) behind the hand, the front ahead.
const EYEPIECE_Z := 0.07
const FRONT_Z := -0.23
## The magnifier's glass ahead of the grip, on its handle.
const GLASS_Z := -0.13
const BRASS := Color("c9963a")
const BRASS_DARK := Color("7a5520")
const SILVER := Color("b8bfc8")
const WOOD := Color("8a5a2b")
## The lens's own meshes are drawn on this render layer alone (the head sees it; the lens's camera never: a camera that
## saw its own disc would read the picture it is drawing). Free in the game's layers (VrPhotoCamera.SELF_LAYER 1 << 17,
## the flight 1 << 18 and 1 << 19).
const LENS_LAYER := 1 << 16
## The lens camera's near plane (m), and the magnifier's far (it looks at near things).
const NEAR := 0.02
const MAGNIFIER_FAR := 12.0

var kind: StringName
var item := 0
var grabbable := VrGrabbable.new()
var viewport := SubViewport.new()
var camera := Camera3D.new()
var disc := MeshInstance3D.new()
var fact_label := Label3D.new()
## The zoom now (times) and the trigger's squeeze (0..1).
var zoom := 2.0
var squeeze := 0.0

var _view := StandardMaterial3D.new()
var _close := StandardMaterial3D.new()
var _closeup: StringName = &""
var _steady := Basis()
var _steadied := false

## The close-ups whose fact was read aloud in this run of the game.
static var _spoken := {}


func _init(lens_kind: StringName = LensRules.TELESCOPE) -> void:
	kind = lens_kind
	item = ItemIds.TELESCOPE if kind == LensRules.TELESCOPE else ItemIds.MAGNIFIER
	name = "VrLens"
	process_mode = Node.PROCESS_MODE_ALWAYS
	grabbable.name = "Grabbable"
	grabbable.kind = &"tool"
	grabbable.throwable = false
	grabbable.far_pull = false
	grabbable.radius = 0.06
	add_child(grabbable)
	grabbable.used.connect(func(_side: StringName, amount: float) -> void: squeeze = amount)
	viewport.name = "Lens"
	viewport.size = Vector2i(LensRules.PIXELS, LensRules.PIXELS)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.handle_input_locally = false
	viewport.positional_shadow_atlas_size = 0   # the lens never draws lamps' shadows
	add_child(viewport)
	camera.name = "Camera"
	camera.near = NEAR
	camera.far = VrRig.FAR if kind == LensRules.TELESCOPE else MAGNIFIER_FAR
	camera.cull_mask = ((1 << 20) - 1) & ~VrPhotoCamera.SELF_LAYER & ~LENS_LAYER
	viewport.add_child(camera)
	for m: StandardMaterial3D in [_view, _close]:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.disable_receive_shadows = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED   # VrPhotoCamera's screen's settings, both sides
	_view.albedo_texture = viewport.get_texture()
	disc.name = "Disc"
	disc.mesh = _disc_mesh(radius())
	disc.material_override = _view
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	fact_label.name = "Fact"
	fact_label.font_size = 34
	fact_label.pixel_size = 0.0005
	fact_label.outline_size = 8
	fact_label.width = 560.0
	fact_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fact_label.modulate = Color("fff3b0")
	fact_label.outline_modulate = Color(0.05, 0.05, 0.12)
	fact_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fact_label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fact_label.visible = false
	add_child(fact_label)
	if kind == LensRules.TELESCOPE:
		_build_telescope()
	else:
		_build_magnifier()
	for n: Node in find_children("*", "VisualInstance3D", true, false):
		(n as VisualInstance3D).layers = LENS_LAYER
	visible = false


func _ready() -> void:
	viewport.world_3d = get_viewport().find_world_3d()   # the same world as the head's


## The disc's radius (m).
func radius() -> float:
	return TELESCOPE_RADIUS if kind == LensRules.TELESCOPE else MAGNIFIER_RADIUS


## The close-up the glass shows now (&"" for the magnified world).
func closeup_shown() -> StringName:
	return _closeup

# --- The hotbar's lens in the hand (VR-HANDS' grabber steps it every frame) ---

## Every frame of a session (VrGrabber.step): the item chosen in the local player's hotbar is a lens: it is in the
## pointing hand (made, then given to the hand when that hand is free); anything else: no lens. Not while the child sits
## in the rocket or stands as a giant (MODEL VIEW).
static func keep_in_hand(grabber: VrGrabber, delta: float) -> void:
	var lens := grabber.get_node_or_null(^"VrLens") as VrLens
	var want := LensRules.kind_of(_selected_item())
	if Vr.seated() or Vr.body_waits():
		want = &""
	if lens != null and lens.kind != want:
		grabber.take_back(lens.grabbable)   # the hand is free at once (its laser again)
		lens.grabbable.enabled = false
		lens.name = "VrLensGone"   # a new one may take the name this frame
		lens.queue_free()
		lens = null
	if want == &"":
		return
	if lens == null:
		lens = VrLens.new(want)
		grabber.add_child(lens)
	if lens.grabbable.held_by() == &"" and grabber.state(Vr.pointing_hand()) == VrGrabber.IDLE:
		lens.global_transform = Vr.hand_grip(Vr.pointing_hand()) * lens.grabbable.hold_offset
		lens.visible = true
		grabber.give(Vr.pointing_hand(), lens.grabbable)
	lens.step(delta)


static func _selected_item() -> int:
	var p := Vr.local_player()
	if p == null or not p.is_spawned():
		return 0
	var interactor := p.get_node_or_null(^"BlockInteractor") as BlockInteractor
	return interactor.selected_block() if interactor != null else 0

# --- Every frame ---

## The lens camera at the lens, its zoom from the trigger, steadied; the magnifier's close-up.
func step(delta: float) -> void:
	var held := grabbable.held_by() == VrRules.LEFT or grabbable.held_by() == VrRules.RIGHT
	visible = held
	if not held:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	zoom = LensRules.zoom(kind, squeeze)
	var eye := Vr.head_transform().origin
	var at := disc.global_position
	camera.fov = LensRules.fov_degrees(radius() * _scale(), eye.distance_to(at), zoom)
	var origin: Vector3
	var target: Basis
	if kind == LensRules.TELESCOPE:
		origin = global_transform * Vector3(0.0, 0.0, FRONT_Z)
		target = global_basis.orthonormalized()
	else:
		origin = at
		var through := at - eye
		through = through.normalized() if through.length() > 0.001 else -global_basis.z.normalized()
		var up := global_basis.y.normalized()
		if absf(up.dot(through)) > 0.98:
			up = -global_basis.z.normalized()
		target = Basis.looking_at(through, up)
	_steady = target if not _steadied else LensRules.steady(_steady, target, delta, zoom)
	_steadied = true
	camera.global_transform = Transform3D(_steady, origin)
	if kind == LensRules.MAGNIFIER:
		_look_close(at, -_steady.z)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED if _closeup != &"" else SubViewport.UPDATE_ALWAYS


## The world's scale on the lens (it is the child's own size in the world: a giant's lens is a giant's).
func _scale() -> float:
	return global_basis.get_scale().x


## The magnifier: the block behind the glass within LensRules.CLOSE_RANGE, its close-up if it has one.
func _look_close(at: Vector3, dir: Vector3) -> void:
	var c := {}
	var p := Vr.local_player()
	if p != null and p.world != null:
		var hit := p.world.raycast(at, dir, LensRules.CLOSE_RANGE * Vr.world_scale())
		if hit != null and LensRules.shows_closeup(hit.distance / Vr.world_scale()):
			c = LensRules.closeup(p.world.get_block(hit.position))
	var pic: StringName = c.get("picture", &"")
	if pic == _closeup:
		return
	_closeup = pic
	if pic == &"":
		disc.material_override = _view
		fact_label.visible = false
		return
	_close.albedo_texture = VrLensCloseups.texture(pic)
	disc.material_override = _close
	fact_label.text = "%s\n%s" % [str(c.name).to_upper(), str(c.fact)]
	fact_label.visible = true
	if not _spoken.has(c.fact):
		_spoken[c.fact] = true
		ReadAloud.auto(str(c.fact))

# --- Building ---

## The telescope: three brass tubes along -Z, wider to the front; the eyepiece disc at the back faces the child.
func _build_telescope() -> void:
	_tube(0.022, 0.024, Vector3(0.0, 0.0, 0.035), 0.07, BRASS_DARK)   # the eyepiece
	_tube(0.03, 0.033, Vector3(0.0, 0.0, -0.06), 0.13, BRASS)
	_tube(0.042, 0.045, Vector3(0.0, 0.0, -0.18), 0.1, BRASS)
	disc.position = Vector3(0.0, 0.0, EYEPIECE_Z)
	disc.mesh = _disc_mesh(TELESCOPE_RADIUS)


## The magnifier: a wooden handle from the grip forward, a silver rim round the glass.
func _build_magnifier() -> void:
	_tube(0.012, 0.014, Vector3(0.0, 0.0, -0.035), 0.07, WOOD)
	var rim := MeshInstance3D.new()
	rim.name = "Rim"
	var t := TorusMesh.new()
	t.inner_radius = MAGNIFIER_RADIUS - 0.002
	t.outer_radius = MAGNIFIER_RADIUS + 0.008
	t.rings = 24
	t.ring_segments = 6
	rim.mesh = t
	rim.rotation = Vector3(PI * 0.5, 0.0, 0.0)   # its hole along z
	rim.position = Vector3(0.0, 0.0, GLASS_Z)
	rim.material_override = AvatarParts.material(SILVER)
	rim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(rim)
	disc.position = Vector3(0.0, 0.0, GLASS_Z)
	fact_label.position = Vector3(0.0, MAGNIFIER_RADIUS + 0.05, GLASS_Z)


func _tube(r_back: float, r_front: float, at: Vector3, length: float, colour: Color) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r_front
	c.bottom_radius = r_back
	c.height = length
	c.radial_segments = 12
	c.rings = 1
	m.mesh = c
	m.rotation = Vector3(-PI * 0.5, 0.0, 0.0)   # its top towards -z (the front)
	m.position = at
	m.material_override = AvatarParts.material(colour)   # the blocky avatar's (warmed): no new shader in a headset
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)


## A round disc facing +Z (towards the child) whose UVs take the square picture's inscribed circle.
static func _disc_mesh(r: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var n := 40
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		for v: Vector2 in [Vector2.ZERO, Vector2(cos(a0), sin(a0)), Vector2(cos(a1), sin(a1))]:
			verts.append(Vector3(v.x * r, v.y * r, 0.0))
			uvs.append(Vector2(0.5 + 0.5 * v.x, 0.5 - 0.5 * v.y))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
