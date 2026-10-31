class_name DangerArrows
extends Control
## The danger arrow (M2 Task 5; research A3): when a monster starts to see this player ("!") while it
## is behind the camera or off the screen, a small arrow glows at the screen's edge, pointing at it,
## then fades. It never nags: once per "!", not again for the same monster within
## StealthRules.ARROW_COOLDOWN, at most MAX_ARROWS at a time, and no arrow for a monster already on
## the screen. With Reduce motion it does not pulse. It looks at the monsters ten times a second
## (their synced alert, so it works on every peer) and draws only while an arrow shows.

const POLL := 0.1
const MARGIN := 64.0
const SIZE := 30.0
const MAX_ARROWS := 3
const COLOR := Color("ff5a36")      # the "!" colour
const GLOW := Color(1.0, 0.45, 0.25, 0.35)
const EDGE := Color(1, 1, 1, 0.95)

var player: Player

var _clock := 0.0
var _poll := 0.0
var _seen := {}                   # monster instance id -> its mark for this player at the last poll
var _last := {}                   # monster instance id -> when it last brought an arrow
var _arrows: Array[Dictionary] = []   # {monster, age}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	tick(delta)
	_poll -= delta
	if _poll <= 0.0:
		_poll = POLL
		poll()


func count() -> int:
	return _arrows.size()


## Ages the arrows (and the clock) by `delta`; faded ones go.
func tick(delta: float) -> void:
	_clock += delta
	if _arrows.is_empty():
		return
	for a in _arrows:
		a.age += delta
	_arrows = _arrows.filter(func(a: Dictionary) -> bool: return a.age < StealthRules.ARROW_TIME and is_instance_valid(a.monster))
	queue_redraw()


## Looks for monsters that just started to see this player.
func poll() -> void:
	if not is_instance_valid(player):
		return
	var cam := VrUi.world_camera(self)   # owner #101: the world's camera (in VR the HUD is in the canvas)
	var seen := {}
	for m in Monster.all_monsters():
		if not is_instance_valid(m) or m.is_queued_for_deletion():
			continue
		var id := m.get_instance_id()
		var mark := m.alert if m.alert_peer == player.peer_id else StealthRules.MARK_NONE
		seen[id] = mark
		if mark != StealthRules.MARK_BANG or _seen.get(id, StealthRules.MARK_NONE) == StealthRules.MARK_BANG:
			continue
		if cam == null or _arrows.size() >= MAX_ARROWS or not StealthRules.arrow_again(float(_last.get(id, -INF)), _clock):
			continue
		var at := m.hit_center()
		if StealthRules.arrow_wanted(cam.is_position_behind(at), _on_screen(cam, at)):
			_arrows.append({"monster": m, "age": 0.0})
			_last[id] = _clock
			queue_redraw()
	_seen = seen


## Where arrow `i` sits on the screen now.
func arrow_point(i: int) -> Vector2:
	var cam := VrUi.world_camera(self)   # owner #101: the world's camera (in VR the HUD is in the canvas)
	var m: Monster = _arrows[i].monster
	return StealthRules.arrow_edge(size, _direction(cam, m.hit_center()), MARGIN)


func _on_screen(cam: Camera3D, at: Vector3) -> bool:
	if cam.is_position_behind(at):
		return false
	var p := cam.unproject_position(at)
	return get_viewport().get_visible_rect().has_point(p)


## From the middle of the screen towards `at` (camera space: right is +x, up is +y).
func _direction(cam: Camera3D, at: Vector3) -> Vector2:
	if cam == null:
		return Vector2.DOWN
	var local := cam.global_transform.affine_inverse() * at
	var d := Vector2(local.x, -local.y)
	if d.length() < 0.001:
		return Vector2.DOWN   # straight behind: the bottom edge
	return d.normalized()


func _draw() -> void:
	if _arrows.is_empty():
		return
	var cam := VrUi.world_camera(self)   # owner #101: the world's camera (in VR the HUD is in the canvas)
	var reduce := not Feel.motion_allowed()
	for a in _arrows:
		var m: Monster = a.monster
		if not is_instance_valid(m):
			continue
		var dir := _direction(cam, m.hit_center())
		var at := StealthRules.arrow_edge(size, dir, MARGIN)
		var alpha := StealthRules.arrow_alpha(a.age, reduce)
		var s := SIZE * StealthRules.arrow_scale(a.age, reduce)
		draw_circle(at, s * 1.1, Color(GLOW, GLOW.a * alpha))
		var side := Vector2(-dir.y, dir.x)
		var tip := at + dir * s
		var back := at - dir * s * 0.6
		var points := PackedVector2Array([tip, back + side * s * 0.75, at - dir * s * 0.2, back - side * s * 0.75])
		draw_colored_polygon(points, Color(COLOR, alpha))
		points.append(tip)
		draw_polyline(points, Color(EDGE, alpha), 3.0, true)
