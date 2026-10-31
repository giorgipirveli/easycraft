class_name StealthMeter
extends Control
## The stealth HUD (M2 Task 5, spec §12.5), top-left under the hearts: a small eye — open (they can
## see you), half closed (hard to see: night, a cave, crouching) or closed (hidden) — and three noise
## bars (quiet, walking, running). Icons, not numbers. It looks ten times a second and redraws only
## when something changed.

const EYE_BOX := Vector2(46, 32)
const BAR_W := 9.0
const BAR_GAP := 4.0
const BAR_HEIGHTS: Array[float] = [10.0, 18.0, 26.0]
const LOOK_EVERY := 0.1
const BACK := Color(0.08, 0.1, 0.16, 0.55)
const WHITE := Color(1, 1, 1, 0.95)
const DIM := Color(1, 1, 1, 0.22)
const EYE_WHITE := Color("f7f4ea")
const IRIS := Color("3a7be8")
const LOUD := Color("ffd23f")
const OUTLINE := Color(0.05, 0.05, 0.08, 0.9)

var player: Player
var director: StealthDirector
var eye_state := StealthRules.EYE_OPEN
var bars := 0

var _t := 0.0
var _box := StyleBoxFlat.new()
## P5 (VR draws): redraws through the headset's one-draw path; tests count them.
var vr_draws := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.bg_color = BACK
	_box.set_corner_radius_all(10)


func meter_size() -> Vector2:
	return Vector2(EYE_BOX.x + 12.0 + 3.0 * BAR_W + 2.0 * BAR_GAP + 10.0, EYE_BOX.y + 4.0)


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = LOOK_EVERY
	refresh()


## Reads the player's visibility and noise; redraws on a change.
func refresh() -> void:
	if not is_instance_valid(player):
		return
	var e := StealthRules.eye(player.stealth_visibility())
	var noise := director.local_noise() if is_instance_valid(director) else 0.0
	var b := StealthRules.noise_bars(noise)
	if e != eye_state or b != bars:
		eye_state = e
		bars = b
		queue_redraw()


func _draw() -> void:
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	if GraphicsPreset.vr_session:   # P5: a headset's HUD canvas: the eye's shapes as one draw (CanvasBatch)
		vr_draws += 1
		var batch := CanvasBatch.new()
		draw_eye(batch, Vector2(8.0 + EYE_BOX.x * 0.5, size.y * 0.5), EYE_BOX.x, eye_state)
		batch.flush(self)
	else:
		draw_eye(self, Vector2(8.0 + EYE_BOX.x * 0.5, size.y * 0.5), EYE_BOX.x, eye_state)
	var x := 8.0 + EYE_BOX.x + 10.0
	var bottom := size.y * 0.5 + 13.0
	for i in 3:
		var h: float = BAR_HEIGHTS[i]
		var on := i < bars
		var c := (LOUD if bars == 3 else WHITE) if on else DIM
		draw_rect(Rect2(x, bottom - h, BAR_W, h), c)
		x += BAR_W + BAR_GAP


## An eye `width` wide at `center`: open (white, a blue iris, a pupil), half (the lid half down) or
## closed (a curve with lashes). Also drawn by the hiding view (HideOverlay). `canvas`: a CanvasItem, or a CanvasBatch
## (P5: a headset's HUD).
static func draw_eye(canvas: Object, center: Vector2, width: float, state: int) -> void:
	var w := width * 0.5
	var h := width * 0.32
	if state == StealthRules.EYE_CLOSED:
		var lid := PackedVector2Array()
		for k in 13:
			var t := k / 12.0
			lid.append(center + Vector2(lerpf(-w, w, t), sin(t * PI) * h * 0.55))
		canvas.draw_polyline(lid, OUTLINE, 6.0, true)
		canvas.draw_polyline(lid, WHITE, 3.0, true)
		for t: float in [0.25, 0.5, 0.75]:
			var p := center + Vector2(lerpf(-w, w, t), sin(t * PI) * h * 0.55)
			canvas.draw_line(p, p + Vector2((t - 0.5) * 10.0, 7.0), WHITE, 2.5, true)
		return
	var shape := PackedVector2Array()
	for k in 24:
		var t := k / 23.0
		shape.append(center + Vector2(lerpf(-w, w, t), -sin(t * PI) * h))
	for k in range(22, 0, -1):
		var t := k / 23.0
		shape.append(center + Vector2(lerpf(-w, w, t), sin(t * PI) * h))
	canvas.draw_colored_polygon(shape, EYE_WHITE)
	canvas.draw_circle(center, h * 0.78, IRIS)
	canvas.draw_circle(center, h * 0.38, OUTLINE)
	canvas.draw_circle(center + Vector2(-h * 0.25, -h * 0.3), h * 0.16, WHITE)
	if state == StealthRules.EYE_HALF:            # the lid comes half way down
		var lid := PackedVector2Array()
		for k in 24:
			var t := k / 23.0
			lid.append(center + Vector2(lerpf(-w, w, t), -sin(t * PI) * h - 1.0))
		for k in range(23, -1, -1):
			var t := k / 23.0
			lid.append(center + Vector2(lerpf(-w, w, t), sin(t * PI) * h * 0.05))
		canvas.draw_colored_polygon(lid, Color("8a6a52"))
	shape.append(shape[0])
	canvas.draw_polyline(shape, OUTLINE, 3.0, true)
