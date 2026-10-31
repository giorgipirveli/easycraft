class_name LifeGhostFinger
extends Control
## Owner #113 (docs/design/life-skills.md §10: "show, don't tell"): the coach's see-through finger on a flat screen. It
## glides to the one next thing and does the step once: a tap, a press held, taps to a beat, a drag side to side; then it
## fades. Never in the way: it takes no touches.

const SIZE := 72.0
const GLIDE := 0.5
const SHOW := 2.4

var at := Vector2.ZERO
var motion := "tap"
var t := -1.0
var _from := Vector2.ZERO


func _init() -> void:
	name = "GhostFinger"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Shows the step at screen point `target` ("tap", "hold", "taps", "beat", "drag", "point").
func show_at(target: Vector2, how: String) -> void:
	_from = size * Vector2(0.5, 0.9) if size != Vector2.ZERO else target + Vector2(0, 160)
	at = target
	motion = how
	t = 0.0
	visible = true
	queue_redraw()


func showing() -> bool:
	return t >= 0.0 and t < GLIDE + SHOW


func _process(delta: float) -> void:
	if t < 0.0:
		return
	t += delta
	if t > GLIDE + SHOW:
		t = -1.0
	queue_redraw()


func _draw() -> void:
	if t < 0.0:
		return
	var k := clampf(t / GLIDE, 0.0, 1.0)
	var p := _from.lerp(at, k * k * (3.0 - 2.0 * k))
	var act := t - GLIDE
	var press := 0.0
	if act >= 0.0:
		match motion:
			"tap":
				press = 1.0 if fmod(act, 1.2) < 0.25 else 0.0
			"hold":
				press = 1.0 if act > 0.2 else 0.0
			"taps", "beat":
				press = 1.0 if fmod(act, LifeBeat.BEAT_SECONDS) < 0.18 else 0.0
			"drag":
				p.x += sin(act * TAU / 1.2) * 70.0
				press = 1.0
	var fade := clampf((GLIDE + SHOW - t) / 0.4, 0.0, 1.0) * 0.75
	if press > 0.0:
		draw_arc(at if motion != "drag" else p, SIZE * 0.55, 0, TAU, 32, Color(1, 0.92, 0.5, fade * 0.8), 6.0, true)
	_finger(p + Vector2(0, 8.0 * press), fade)


## A see-through hand with its finger pointing down at `tip`.
func _finger(tip: Vector2, alpha: float) -> void:
	var skin := Color(1, 1, 1, alpha)
	var edge := Color(0.12, 0.16, 0.29, alpha)
	var u := SIZE / 72.0
	draw_rect(Rect2(tip + Vector2(-9, 0) * u, Vector2(18, 42) * u), skin)
	draw_circle(tip + Vector2(0, 2) * u, 9 * u, skin)
	draw_rect(Rect2(tip + Vector2(-26, 36) * u, Vector2(52, 44) * u), skin)
	for i in 3:
		draw_circle(tip + Vector2(-17 + i * 16, 38) * u, 8 * u, skin)
	draw_rect(Rect2(tip + Vector2(-26, 36) * u, Vector2(52, 44) * u), edge, false, 3.0)
	draw_rect(Rect2(tip + Vector2(-9, 0) * u, Vector2(18, 38) * u), edge, false, 3.0)
