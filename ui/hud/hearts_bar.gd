class_name HeartsBar
extends Control
## The hearts row (M2 Task 2, spec §12.3): 10 hearts of 2 HP each, drawn full, half or empty. A hurt
## flashes the full hearts and shakes the row; while hearts come back (Health.REGEN_DELAY without a
## hit) the heart being refilled pulses gently. A few polygons, redrawn only while something moves.

const HEARTS := 10                # 2 HP each: Health.MAX_HP
const HEART_SIZE := 28.0
const GAP := 3.0
const FLASH_TIME := 0.45
const SHAKE_PX := 5.0
const PULSE_SPEED := 5.0          # radians per second
const PULSE_SCALE := 0.16
const RED := Color("e8403a")
const FLASH := Color("fff4f0")
const EMPTY := Color(0.12, 0.06, 0.08, 0.55)
const OUTLINE := Color(0.08, 0.03, 0.05, 0.9)
const SHINE := Color(1, 1, 1, 0.45)
## M5 Task 1 (never colour alone): an empty heart is hollow, a light outline round a dark middle; a full one is solid
## red with a shine, a half one half filled.
const EMPTY_RIM := Color(1, 1, 1, 0.8)
const SOLID := &"solid"
const HALF := &"half"
const HOLLOW := &"hollow"
const _SEGMENTS := 20             # per half heart

static var _left: PackedVector2Array     # unit heart (1 wide) around (0, 0)
static var _right: PackedVector2Array
static var _outline: PackedVector2Array

## P5 (VR draws): one heart's shapes in a HEART_SIZE heart's pixels round (0, 0), built once ([left, right, outline,
## shine], in drawing order): `points` and each part's vertex count; `outline_colors` the outline's soft edge (an alpha
## per vertex); `indices` the whole row's triangles (the same every redraw).
static var _vr := {}
## P5: redraws through the headset's one-draw path; tests count them.
var vr_draws := 0

var hp := Health.MAX_HP
var _flash := 0.0                 # 1 right after a hurt, down to 0
var _quiet := 0.0                 # seconds since the last hurt
var _t := 0.0


## How full heart `index` (0 = leftmost) is at hp: 1, 0.5 or 0.
static func fill(points: int, index: int) -> float:
	return clampf((points - index * 2) / 2.0, 0.0, 1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _outline.is_empty():
		_right = _curve(0.0, PI)
		_left = _curve(PI, TAU)
		_outline = _curve(0.0, TAU)


func bar_size() -> Vector2:
	return Vector2(HEARTS * HEART_SIZE + (HEARTS - 1) * GAP, HEART_SIZE)


## New hearts from the host; fewer than before is a hurt (flash, shake, and the regen wait restarts).
func set_hp(points: int) -> void:
	points = clampi(points, 0, Health.MAX_HP)
	if points < hp:
		_flash = 1.0
		_quiet = 0.0
	hp = points
	queue_redraw()


func is_flashing() -> bool:
	return _flash > 0.0


## Hearts are coming back: hurt, not knocked out, and no hit for Health.REGEN_DELAY.
func is_regenerating() -> bool:
	return hp > 0 and hp < Health.MAX_HP and _quiet >= Health.REGEN_DELAY


## The heart that fills next.
func pulse_index() -> int:
	return floori(hp / 2.0)


func shake_offset() -> Vector2:
	if _flash <= 0.0:
		return Vector2.ZERO
	var a := _t * 60.0
	return Vector2(sin(a), cos(a)) * SHAKE_PX * _flash


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_t += delta
	_quiet += delta
	if _flash > 0.0:
		_flash = maxf(_flash - delta / FLASH_TIME, 0.0)
		queue_redraw()
	elif is_regenerating():
		queue_redraw()


func _draw() -> void:
	if GraphicsPreset.vr_session:   # P5: a headset's HUD canvas is drawn every frame: the row as one draw, not 60
		vr_draws += 1
		var m := vr_mesh()
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), m.indices, m.points, m.colors)
		return
	var off := shake_offset()
	var full := RED.lerp(FLASH, _flash * 0.75)
	var pulsing := pulse_index() if is_regenerating() else -1
	for i in HEARTS:
		var s := HEART_SIZE
		if i == pulsing:
			s *= 1.0 + PULSE_SCALE * (0.5 + 0.5 * sin(_t * PULSE_SPEED))
		var f := fill(hp, i)
		draw_set_transform(off + Vector2(i * (HEART_SIZE + GAP) + HEART_SIZE * 0.5, HEART_SIZE * 0.5), 0.0, Vector2(s, s))
		draw_colored_polygon(_left, full if f > 0.0 else EMPTY)
		draw_colored_polygon(_right, full if f >= 1.0 else EMPTY)
		draw_polyline(_outline, EMPTY_RIM if f <= 0.0 else OUTLINE, 2.0 / s, true)   # M5 Task 1: hollow when empty
		if f > 0.0:
			draw_circle(Vector2(-0.22, -0.16), 0.08, SHINE)
	draw_set_transform(Vector2.ZERO)


## P5 (VR draws): the row as one triangle list ({points, colors, indices}): the same hearts as _draw (full, half or
## hollow, the flash, the pulse, the shake, the shine), each heart's shapes from the cached mesh (_vr) moved and scaled
## by native calls only, so a redraw while the hearts pulse costs little.
func vr_mesh() -> Dictionary:
	if _vr.is_empty():
		_build_vr()
	var off := shake_offset()
	var full := RED.lerp(FLASH, _flash * 0.75)
	var pulsing := pulse_index() if is_regenerating() else -1
	var counts: Array = _vr.counts
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in HEARTS:
		var k := 1.0
		if i == pulsing:
			k += PULSE_SCALE * (0.5 + 0.5 * sin(_t * PULSE_SPEED))
		var f := fill(hp, i)
		var at := off + Vector2(i * (HEART_SIZE + GAP) + HEART_SIZE * 0.5, HEART_SIZE * 0.5)
		pts.append_array(Transform2D(0.0, Vector2(k, k), 0.0, at) * (_vr.points as PackedVector2Array))
		cols.append_array(_filled(int(counts[0]), full if f > 0.0 else EMPTY))
		cols.append_array(_filled(int(counts[1]), full if f >= 1.0 else EMPTY))
		cols.append_array(_vr.rim if f <= 0.0 else _vr.outline)
		cols.append_array(_filled(int(counts[3]), SHINE if f > 0.0 else Color(SHINE, 0.0)))
	return {"points": pts, "colors": cols, "indices": _vr.indices}


static func _filled(n: int, c: Color) -> PackedColorArray:
	var out := PackedColorArray()
	out.resize(n)
	out.fill(c)
	return out


## One heart's parts drawn once into a CanvasBatch at HEART_SIZE (the outline 2 px with Godot's 1 px soft edge), its
## colours kept for the two outline colours, and the row's triangles.
static func _build_vr() -> void:
	if _outline.is_empty():
		_right = _curve(0.0, PI)
		_left = _curve(PI, TAU)
		_outline = _curve(0.0, TAU)
	var parts: Array[CanvasBatch] = []
	for k in 4:
		var b := CanvasBatch.new()
		b.draw_set_transform(Vector2.ZERO, 0.0, Vector2(HEART_SIZE, HEART_SIZE))
		parts.append(b)
	parts[0].draw_colored_polygon(_left, Color.WHITE)
	parts[1].draw_colored_polygon(_right, Color.WHITE)
	parts[2].draw_polyline(_outline, Color.WHITE, 2.0 / HEART_SIZE, true)
	parts[3].draw_circle(Vector2(-0.22, -0.16), 0.08, Color.WHITE)
	var points := PackedVector2Array()
	var heart_indices := PackedInt32Array()
	var counts: Array[int] = []
	for b: CanvasBatch in parts:
		for i: int in b.indices:
			heart_indices.append(points.size() + i)
		points.append_array(b.points)
		counts.append(b.points.size())
	var outline := PackedColorArray()
	var rim := PackedColorArray()
	for c: Color in parts[2].colors:   # the soft edge: the line's own colour to clear
		outline.append(Color(OUTLINE, OUTLINE.a * c.a))
		rim.append(Color(EMPTY_RIM, EMPTY_RIM.a * c.a))
	var indices := PackedInt32Array()
	for h in HEARTS:
		for i: int in heart_indices:
			indices.append(h * points.size() + i)
	_vr = {"points": points, "counts": counts, "outline": outline, "rim": rim, "indices": indices}


## Part of the classic heart curve, scaled to 1 wide and centred on (0, 0) (screen y down).
static func _curve(t0: float, t1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := _SEGMENTS * (2 if t1 - t0 > PI + 0.1 else 1)
	for k in n + 1:
		var t := lerpf(t0, t1, float(k) / n)
		var s := sin(t)
		var x := 16.0 * s * s * s
		var y := -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
		pts.append(Vector2(x, y - 2.6) / 32.0)
	return pts


## M5 Task 1: heart `index`'s shape at `points` (solid, half or hollow: its look never rests on colour alone).
static func shape_of(points: int, index: int) -> StringName:
	var f := fill(points, index)
	return SOLID if f >= 1.0 else (HALF if f > 0.0 else HOLLOW)
