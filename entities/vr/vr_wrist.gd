class_name VrWrist
extends Node3D
## VR on the Meta Quest (owner #101, P2; docs/devlog/parts/vr-research.md "HUD in VR"): glances that need no look down
## at the tray. While the child plays (the tray's time) the hotbar, the hearts and the gold also ride on the wrist of
## the hand that does not point: parts of the VR canvas (where the HUD drew them: Hud.vr_rects) on small strips just
## over the hand, facing the eyes, drawn to one scale (METRES_PER_PX). A toast, else the boss bar, else the wave line
## floats on a strip just above the gaze while one shows, lazily following the head's yaw as the tray does. Nothing is
## pinned to the face. Drawn over the world like the panel (no depth test), on the flight's layer too.

const METRES_PER_PX := 0.0004
## The wrist strips float this far over the hand, the hearts and the gold this far over the hotbar.
const ABOVE_HAND := 0.07
const GAP := 0.012
## The toast strip: this far ahead and this many degrees above the eyes.
const TOAST_DISTANCE := 1.3
const TOAST_UP_DEGREES := 18.0
const TOAST_METRES_PER_PX := 0.0011
const PRIORITY := 125
const PARTS: Array[StringName] = [&"hotbar", &"hearts", &"gold"]
## What the toast strip shows, the first one showing.
const TOASTS: Array[StringName] = [&"toast", &"boss", &"wave"]

## () -> Transform3D: the hand the strips ride on (default: the hand that does not point, Vr.hand_ray).
var hand_source := Callable()
## () -> Transform3D: the head (VrUi gives the panel's).
var head_source := Callable()
## The canvas's picture.
var texture: Texture2D:
	set(t):
		texture = t
		for m: MeshInstance3D in _all():
			((m.mesh as QuadMesh).material as StandardMaterial3D).albedo_texture = t
var toast := MeshInstance3D.new()

var _parts := {}   # name -> MeshInstance3D
var _toast_yaw := 0.0
var _following := false
var _toast_was := false


func _init() -> void:
	name = "VrWrist"
	top_level = true
	for p: StringName in PARTS:
		var m := _strip(String(p))
		_parts[p] = m
		add_child(m)
	toast = _strip("Toast")
	add_child(toast)


static func _strip(strip_name: String) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = "Wrist_" + strip_name
	var quad := QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_PREMULT_ALPHA
	mat.no_depth_test = true
	mat.render_priority = PRIORITY
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.disable_receive_shadows = true
	quad.material = mat
	m.mesh = quad
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.layers = VrPanelRules.LAYERS
	m.top_level = true
	m.visible = false
	return m


## The strip for a HUD part (&"hotbar", &"hearts", &"gold").
func part(part_name: StringName) -> MeshInstance3D:
	return _parts[part_name]


## One frame: `rects` the HUD's parts on the canvas (Hud.vr_rects; an empty rect: not showing); `playing`: the tray's
## time (no menu in front, no flight).
func step(delta: float, rects: Dictionary, playing: bool) -> void:
	if not playing or rects.is_empty() or not is_inside_tree():
		for m: MeshInstance3D in _all():
			m.visible = false
		_toast_was = false
		return
	var head := _head()
	_place_wrist(rects, head)
	_place_toast(rects, head, delta)


func _place_wrist(rects: Dictionary, head: Transform3D) -> void:
	var h: Variant = hand_source.call() if hand_source.is_valid() else _off_hand()
	if h == null:
		for p: StringName in PARTS:
			(_parts[p] as MeshInstance3D).visible = false
		return
	var k := Vr.world_scale()   # owner #110: a giant's wrist is a giant's (Size Magic, MODEL VIEW)
	var center: Vector3 = (h as Transform3D).origin + Vector3.UP * ABOVE_HAND * k
	var b := facing(center, head.origin)
	var bar: Rect2 = rects.get(&"hotbar", Rect2())
	var bar_size := bar.size * METRES_PER_PX * k
	for p: StringName in PARTS:
		var m := _parts[p] as MeshInstance3D
		var r: Rect2 = rects.get(p, Rect2())
		m.visible = r.has_area()
		if not m.visible:
			continue
		var s := r.size * METRES_PER_PX * k
		_show(m, r, s)
		var local := Vector2.ZERO
		if p == &"hearts":
			local = Vector2(-bar_size.x * 0.5 + s.x * 0.5, bar_size.y * 0.5 + GAP * k + s.y * 0.5)
		elif p == &"gold":
			local = Vector2(bar_size.x * 0.5 - s.x * 0.5, bar_size.y * 0.5 + GAP * k + s.y * 0.5)
		m.global_transform = Transform3D(b, center + b.x * local.x + b.y * local.y)


func _place_toast(rects: Dictionary, head: Transform3D, delta: float) -> void:
	var r := Rect2()
	for t: StringName in TOASTS:
		var candidate: Rect2 = rects.get(t, Rect2())
		if candidate.has_area():
			r = candidate
			break
	toast.visible = r.has_area()
	if not toast.visible:
		_toast_was = false
		return
	var yaw := VrPanelRules.head_yaw(head)
	if not _toast_was:
		_toast_yaw = yaw
		_following = false
	else:
		var step := VrPanelRules.tray_yaw(_toast_yaw, yaw, _following, delta)
		_toast_yaw = step[0]
		_following = step[1]
	_toast_was = true
	var up := deg_to_rad(TOAST_UP_DEGREES)
	var k := Vr.world_scale()
	var at := head.origin + Basis(Vector3.UP, _toast_yaw) * (Vector3(0.0, sin(up), -cos(up)) * TOAST_DISTANCE * k)
	_show(toast, r, r.size * TOAST_METRES_PER_PX * k)
	toast.global_transform = Transform3D(facing(at, head.origin), at)


## A strip's part of the canvas and its size in metres.
func _show(m: MeshInstance3D, r: Rect2, size_m: Vector2) -> void:
	var quad := m.mesh as QuadMesh
	quad.size = size_m
	var mat := quad.material as StandardMaterial3D
	var c := Vector2(VrPanelRules.CANVAS)
	mat.uv1_offset = Vector3(r.position.x / c.x, r.position.y / c.y, 0.0)
	mat.uv1_scale = Vector3(r.size.x / c.x, r.size.y / c.y, 1.0)


## A basis whose +Z looks from `at` to `eye`, kept upright.
static func facing(at: Vector3, eye: Vector3) -> Basis:
	var z := eye - at
	if z.length_squared() < 0.000001:
		return Basis()
	z = z.normalized()
	var x := Vector3.UP.cross(z)
	if x.length_squared() < 0.000001:
		x = Vector3.RIGHT
	x = x.normalized()
	return Basis(x, z.cross(x), z)


func _head() -> Transform3D:
	return head_source.call() if head_source.is_valid() else Transform3D(Basis(), Vector3(0, CameraRig.HEAD_HEIGHT, 0))


## The hand that does not point (null without a hand).
func _off_hand() -> Variant:
	var left := Profile.data != null and bool(Profile.data.settings.get("left_handed", false))
	var off := VrRules.RIGHT if VrRules.pointing_hand(left) == VrRules.LEFT else VrRules.LEFT
	var ray := Vr.hand_ray(off)
	return Transform3D(Basis(), ray[0]) if ray.size() == 2 else null


func _all() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = [toast]
	for p: StringName in PARTS:
		if _parts.has(p):
			out.append(_parts[p])
	return out
