class_name VrTeleport
extends Node3D
## Owner #101 (VR on the Meta Quest, P3): the turning stick pushed up aims a teleport. A falling arc of dots leaves the
## pointing hand (TeleportRules.arc) and a ring shows where it lands: green where the child may go (TeleportRules: on
## ground with room, at most a block up, at most 6 m, in sight, never a hiding spot, never where a game says no), grey
## where not. Let go of the stick and the child is there, behind a black blink (Player.vr_teleport: out 0.15 s, in
## 0.25 s). Only while the child walks in the world (Player.vr_may_teleport) and the VR COMFORT setting allows it.

const DOTS := 24
const DOT_RADIUS := 0.035
const RING_RADIUS := 0.35
const OK_COLOR := Color(0.35, 1.0, 0.55, 0.9)
const NO_COLOR := Color(0.7, 0.7, 0.75, 0.6)

## The last aim ({ok, at, points, why}; {} when not aiming) and teleports done (tests).
var aim := {}
var aiming := false
var jumps := 0

## The arc's dots: one MultiMesh (one draw; a headset's budget is about 100).
var _dots := MultiMeshInstance3D.new()
var _ring := MeshInstance3D.new()
var _ok_mat := _material(OK_COLOR)
var _no_mat := _material(NO_COLOR)


func _init() -> void:
	name = "VrTeleport"
	var ball := SphereMesh.new()
	ball.radius = DOT_RADIUS
	ball.height = DOT_RADIUS * 2.0
	ball.radial_segments = 6
	ball.rings = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ball
	mm.instance_count = DOTS
	mm.visible_instance_count = 0
	_dots.multimesh = mm
	_dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_dots.top_level = true
	add_child(_dots)
	var torus := TorusMesh.new()
	torus.inner_radius = RING_RADIUS - 0.05
	torus.outer_radius = RING_RADIUS
	torus.rings = 24
	torus.ring_segments = 6
	_ring.mesh = torus
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ring.visible = false
	add_child(_ring)


static func _material(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	return m


## One frame: the turning stick's push away (`stick_y`) for `player` (null: nothing to aim).
func step(player: Player, stick_y: float) -> void:
	var allowed := player != null and bool(Vr.setting(VrRules.TELEPORT)) and player.vr_may_teleport()
	var s := VrRules.teleport_step(stick_y if allowed else 0.0, aiming)
	aiming = bool(s.aim) and allowed
	if bool(s.go) and allowed and bool(aim.get("ok", false)):
		jumps += 1
		player.vr_teleport(aim.at)
	if aiming:
		var ray := Vr.pointer_ray()
		if not ray.is_empty():
			aim = TeleportRules.target(ray[0], ray[1], player.global_position, player.eye_position(),
				player.body_radius(), SizeMagic.clearance_blocks(player.size_mode), player.world.get_block,
				player.vr_teleport_refused)
	else:
		aim = {}
	_show()


func _show() -> void:
	var pts: PackedVector3Array = aim.get("points", PackedVector3Array())
	var ok := bool(aim.get("ok", false))
	var mat := _ok_mat if ok else _no_mat
	var every := maxi(1, ceili(float(pts.size()) / DOTS))
	var mm := _dots.multimesh
	var shown := 0
	if aiming:
		for i in DOTS:
			var k := i * every
			if k >= pts.size():
				break
			mm.set_instance_transform(i, Transform3D(Basis(), pts[k]))
			shown += 1
	mm.visible_instance_count = shown
	_dots.material_override = mat
	var at: Vector3 = aim.get("at", Vector3.INF)
	_ring.visible = aiming and at.is_finite()
	if _ring.visible:
		_ring.global_position = at + Vector3(0.0, 0.03, 0.0)
		_ring.material_override = mat
