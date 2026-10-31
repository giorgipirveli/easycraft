class_name VrModelView
extends Node3D
## Owner #110, VR round 4 idea 6 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md, the research §5.3 "The Giant's Table",
## R6): MODEL VIEW, the Sandbox only, in VR only (MORE → MODEL VIEW). Behind a blink the child becomes a giant
## ModelViewRules.SCALE times their size standing in their own world: its loaded land a model at their feet (the ground
## at the real floor: no height to fear), every build and animal small and alive; they walk round it in the room. Their
## own body waits where it stood (the origin's anchor is a still spot at its feet; the controllers move nothing of it),
## seen small in the model.
## - **Pick up the little figure of themselves** (a VrGrabbable on a figure at the body: the grip near it) and **put it
##   down somewhere else**: a ring shows where it would land (green: they may go there, ModelViewRules.check; red: not);
##   let go on green: black, they are there at their own size (the body moved, the model gone), the fade back in. On
##   red it goes back to the body.
## - **Two hands twist the world** in 45° steps (empty grips: a claimer of VrGrabber's), never smoothly.
## - MORE → MODEL VIEW again (or a jump) ends it behind a blink: the size and the anchor as they were.

signal ended

const FIGURE_COLOR := Color(1.0, 0.85, 0.3)
const OK_COLOR := Color(0.4, 1.0, 0.5, 0.6)
const NO_COLOR := Color(1.0, 0.35, 0.3, 0.6)
const NOPE := [0.2, 0.08]

var player: Player
## The figure the hand takes (its grabbable: `pin`), and the ring where it would land.
var figure := Node3D.new()
var pin := VrGrabbable.new()
var ring := MeshInstance3D.new()
## Where a let-go figure would land and whether the child may go there (tests).
var landing := Vector3.INF
var landing_ok := false
## Jumps made (tests).
var jumps := 0

var _spot := Node3D.new()
var _scale_before := 1.0
var _real_height_before := false
var _twist := {}   # side -> true while that hand's empty grip is on the world
var _twist_from := NAN
var _twist_done := 0
var _open := false


func _init() -> void:
	name = "VrModelView"
	_spot.name = "ModelSpot"
	_spot.top_level = true
	add_child(_spot)
	figure.name = "Figure"
	figure.top_level = true
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.8
	cap.radial_segments = 12
	cap.rings = 2
	var m := StandardMaterial3D.new()
	m.albedo_color = FIGURE_COLOR
	m.emission_enabled = true
	m.emission = FIGURE_COLOR * 0.4
	cap.material = m
	body.mesh = cap
	body.position.y = 0.9
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	figure.add_child(body)
	pin.name = "VrGrabbable"
	pin.position.y = 0.9
	pin.radius = 0.9
	pin.far_pull = true   # the laser pulls it up off the floor: no bending down to the model
	pin.throwable = false
	figure.add_child(pin)
	add_child(figure)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 0.9
	torus.rings = 16
	torus.ring_segments = 6
	var rm := StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = OK_COLOR
	torus.material = rm
	ring.mesh = torus
	ring.name = "Landing"
	ring.top_level = true
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.visible = false
	add_child(ring)
	pin.released.connect(_on_released)


## Opens for `p` (this game's player in the world; the Sandbox only): false when it can't.
func open(p: Player) -> bool:
	if p == null or not p.is_spawned() or p.world == null or not ModelViewRules.allowed(Game.mode) or Vr.rig == null \
			or Vr.seated() or p.is_riding() or p.is_hiding():
		return false
	player = p
	_open = true
	_scale_before = Vr.world_scale()
	_real_height_before = Vr.rig.real_height
	_spot.global_position = p.global_position
	_put_figure_home()
	Vr.rig.real_height = true   # the giant stands on the ground: the head the tracked height up
	Vr.anchor(_spot, &"feet")
	Vr.set_world_scale(ModelViewRules.SCALE)   # behind a blink, the head over the spot
	Vr.set_head_blocked(0.0)
	Vr.show_self(true, &"model")
	if Vr.camera:
		Vr.camera.cull_mask |= VrPhotoCamera.SELF_LAYER   # the child sees their own body in the model
		_far_before = Vr.camera.far
	Vr.grabber.claimers.append(self)
	return true


var _far_before := VrRig.FAR


## The head's far plane cuts the model round (ModelViewRules.RANGE): the land beyond is never drawn.
func _cut_model() -> void:
	if Vr.camera != null and is_instance_valid(player):
		Vr.camera.far = ModelViewRules.far_plane(Vr.head_transform().origin.y - player.global_position.y)


func is_open() -> bool:
	return _open


## Ends it behind a blink: the size and the anchor as they were.
func close() -> void:
	if not _open:
		return
	_open = false
	pin.enabled = false   # no hand takes it any more (it goes with this node)
	figure.visible = false
	if Vr.grabber:
		Vr.grabber.claimers.erase(self)
	Vr.show_self(false, &"model")
	if Vr.camera:
		Vr.camera.far = _far_before
	if Vr.rig:
		Vr.rig.real_height = _real_height_before
	Vr.release(_spot)   # back to the player's feet, behind a blink
	Vr.set_world_scale(_scale_before)
	ring.visible = false
	ended.emit()
	queue_free()


func _put_figure_home() -> void:
	figure.global_transform = Transform3D(Basis(), player.global_position)


## One frame (Vr.step): the ring under a held figure, the world's twist.
func step(_delta: float) -> void:
	if not _open:
		return
	if not is_instance_valid(player) or not player.is_inside_tree():
		close()
		return
	_cut_model()
	if pin.held_by() != &"":
		landing = ModelViewRules.landing(figure.global_position + Vector3(0.0, 0.9, 0.0), player.world.get_block)
		landing_ok = ModelViewRules.check(player.global_position, landing, player.body_radius(),
			SizeMagic.clearance_blocks(player.size_mode), player.world.get_block, player.vr_teleport_refused) == ""
		ring.visible = landing.is_finite()
		if ring.visible:
			ring.global_transform = Transform3D(Basis(), landing + Vector3(0.0, 0.05, 0.0))
			((ring.mesh as TorusMesh).material as StandardMaterial3D).albedo_color = OK_COLOR if landing_ok else NO_COLOR
	else:
		ring.visible = false
	_step_twist()


func _on_released(side: StringName, _v: Vector3) -> void:
	ring.visible = false
	if not _open or not is_instance_valid(player):
		return   # the session ended with it in the hand
	if landing_ok and landing.is_finite():
		jump_to(landing)
	else:
		Vr.haptic(side, float(NOPE[0]), float(NOPE[1]))
		_put_figure_home()


## The child goes to `at` at their own size: black at once, the model gone, the body there, then the fade in.
func jump_to(at: Vector3) -> void:
	var p := player
	jumps += 1
	Vr.hold_fade(1.0)
	close()
	if is_instance_valid(p):
		p.global_position = at
		p.velocity = Vector3.ZERO
		p.rig.snap_to_target()
		Audio.play(&"air_jump", at)
	Vr.snap_origin()
	Vr.fade_in()

# --- Two hands turn the world (empty grips) ---

func grip_claim(side: StringName) -> bool:
	if not _open:
		return false
	_twist[side] = true
	if _twist.size() == 2:
		_twist_from = _hands_yaw()
		_twist_done = 0
	return true


func grip_release(side: StringName) -> void:
	_twist.erase(side)
	_twist_from = NAN


func _step_twist() -> void:
	if _twist.size() != 2 or is_nan(_twist_from):
		return
	var steps := ModelViewRules.twist_steps(angle_difference(_twist_from, _hands_yaw()))
	if steps == _twist_done:
		return
	# the hands turned the world one way: the child turns the other round their head (the world seems to turn)
	Vr.turn(-deg_to_rad(ModelViewRules.TWIST_STEP) * (steps - _twist_done))
	_twist_done = steps
	for s: StringName in _twist.keys():
		Vr.haptic(s, 0.3, 0.04)


## The hands' line's yaw in the play space (the origin's own turns never count).
func _hands_yaw() -> float:
	var inv := Vr.rig.global_transform.affine_inverse()
	var v := inv * Vr.hand_grip(VrRules.RIGHT).origin - inv * Vr.hand_grip(VrRules.LEFT).origin
	return atan2(-v.z, v.x)
