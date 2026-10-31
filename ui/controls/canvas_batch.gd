class_name CanvasBatch
extends RefCounted
## P5 (VR draws, docs/devlog/parts/vr-perf.md): the HUD's pictures drawn in code (the hearts, HudIcons' symbols on the
## buttons, the coin, the stealth eye) are many small polygons, circles and lines, and Godot 4's canvas renderer draws
## each of those as a draw call of its own (only rects and text batch). In a headset the HUD's canvas is drawn every
## frame into the tray's texture: those pictures were 100 of the Sandbox's 165 draws. A CanvasBatch takes the same calls
## as a CanvasItem (draw_colored_polygon, draw_circle, draw_line, draw_polyline, draw_arc, draw_rect,
## draw_set_transform), builds one triangle list with a colour per vertex, and `flush` draws it as ONE call
## (RenderingServer.canvas_item_add_triangle_array). Antialiased lines get a FEATHER-wide soft edge, as Godot's own.
## Only the headset's HUD uses it (GraphicsPreset.vr_session): a phone draws exactly as before.

## Antialiased lines' soft edge (px), drawn from the line's colour to clear.
const FEATHER := 1.0
## Segments of a circle: about one per FAN_PX of its rim, at least MIN_FAN.
const FAN_PX := 2.5
const MIN_FAN := 12
const MAX_FAN := 64

var points := PackedVector2Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()

var _xf := Transform2D.IDENTITY
var _scale := 1.0


func is_empty() -> bool:
	return indices.is_empty()


## Like CanvasItem.draw_set_transform: what is drawn next is moved, turned and scaled.
func draw_set_transform(position: Vector2, rotation: float = 0.0, scale: Vector2 = Vector2.ONE) -> void:
	_xf = Transform2D(rotation, scale, 0.0, position)
	_scale = (absf(scale.x) + absf(scale.y)) * 0.5


func draw_colored_polygon(polygon: PackedVector2Array, color: Color) -> void:
	if polygon.size() < 3:
		return
	var p := _xf * polygon
	var tri := Geometry2D.triangulate_polygon(p)
	if tri.is_empty():   # not a simple polygon: a fan, as a convex one would be
		for k in range(1, p.size() - 1):
			tri.append_array([0, k, k + 1])
	_add(p, color, tri)


func draw_rect(rect: Rect2, color: Color, filled: bool = true, width: float = -1.0) -> void:
	var a := rect.position
	var b := rect.end
	if filled:
		_add(_xf * PackedVector2Array([a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]), color, PackedInt32Array([0, 1, 2, 0, 2, 3]))
		return
	var corners := [a, Vector2(b.x, a.y), b, Vector2(a.x, b.y)]
	for k in 4:
		draw_line(corners[k], corners[(k + 1) % 4], color, width)


func draw_circle(center: Vector2, radius: float, color: Color, filled: bool = true, width: float = -1.0,
		antialiased: bool = false) -> void:
	if not filled:
		draw_arc(center, radius, 0.0, TAU, _fan(radius) + 1, color, width, antialiased)
		return
	var n := _fan(radius)
	var p := PackedVector2Array([center])
	for k in n:
		p.append(center + Vector2.from_angle(TAU * k / n) * radius)
	var tri := PackedInt32Array()
	for k in n:
		tri.append_array([0, 1 + k, 1 + (k + 1) % n])
	_add(_xf * p, color, tri)


func draw_line(from: Vector2, to: Vector2, color: Color, width: float = -1.0, antialiased: bool = false) -> void:
	draw_polyline(PackedVector2Array([from, to]), color, width, antialiased)


func draw_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, point_count: int, color: Color,
		width: float = -1.0, antialiased: bool = false) -> void:
	var p := PackedVector2Array()
	var n := maxi(point_count, 2)
	for k in n:
		p.append(center + Vector2.from_angle(lerpf(start_angle, end_angle, float(k) / (n - 1))) * radius)
	draw_polyline(p, color, width, antialiased)


## A strip `width` wide (a thin one, `width` <= 0, is a pixel) along `polyline`, each point pushed out along the
## average of its two segments' normals (Godot's own joint), plus a FEATHER of soft edge when `antialiased`.
func draw_polyline(polyline: PackedVector2Array, color: Color, width: float = -1.0, antialiased: bool = false) -> void:
	var n := polyline.size()
	if n < 2:
		return
	var p := _xf * polyline
	var closed := p[0].distance_to(p[n - 1]) < 0.001 and n > 2
	var h := (width * _scale if width > 0.0 else 1.0) * 0.5
	var clear := Color(color, 0.0)
	var base := points.size()
	var rows := 4 if antialiased else 2   # the vertices across the strip at each point
	for i in n:
		var prev := p[i - 1] if i > 0 else (p[n - 2] if closed else p[i])
		var next := p[i + 1] if i < n - 1 else (p[1] if closed else p[i])
		var t := (next - prev).normalized()
		if t == Vector2.ZERO:
			t = Vector2.RIGHT
		var normal := t.orthogonal()
		if antialiased:
			points.append_array([p[i] + normal * (h + FEATHER), p[i] + normal * h, p[i] - normal * h,
				p[i] - normal * (h + FEATHER)])
			colors.append_array([clear, color, color, clear])
		else:
			points.append_array([p[i] + normal * h, p[i] - normal * h])
			colors.append_array([color, color])
	for i in n - 1:
		var a := base + i * rows
		var b := a + rows
		for r in rows - 1:
			indices.append_array([a + r, b + r, b + r + 1, a + r, b + r + 1, a + r + 1])


## A StyleBoxFlat's look: `rect` filled with `fill`, its corners rounded by `radius`, and a `border` `border_width` wide
## inside its edge (antialiased).
func draw_rounded_box(rect: Rect2, radius: float, fill: Color, border: Color, border_width: float) -> void:
	var outline := _rounded(rect, radius)
	_add(_xf * outline, fill, _fan_of(outline.size()))
	if border_width > 0.0 and border.a > 0.0:
		var inner := _rounded(rect.grow(-border_width * 0.5), maxf(radius - border_width * 0.5, 0.0))
		inner.append(inner[0])
		draw_polyline(inner, border, border_width, true)


## The outline of `rect` with corners of `radius` (ROUND_STEPS segments each), clockwise from the top left.
const ROUND_STEPS := 4


static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var out := PackedVector2Array()
	var corners := [[rect.position + Vector2(r, r), PI], [Vector2(rect.end.x - r, rect.position.y + r), PI * 1.5],
		[rect.end - Vector2(r, r), 0.0], [Vector2(rect.position.x + r, rect.end.y - r), PI * 0.5]]
	for c: Array in corners:
		for k in ROUND_STEPS + 1:
			out.append((c[0] as Vector2) + Vector2.from_angle(float(c[1]) + PI * 0.5 * k / ROUND_STEPS) * r)
	return out


static func _fan_of(n: int) -> PackedInt32Array:
	var tri := PackedInt32Array()
	for k in range(1, n - 1):
		tri.append_array([0, k, k + 1])
	return tri


## Draws everything gathered on `ci` as one call (inside its _draw) and starts empty again.
func flush(ci: CanvasItem) -> void:
	if not is_empty():
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), indices, points, colors)
	points = PackedVector2Array()
	colors = PackedColorArray()
	indices = PackedInt32Array()


func _fan(radius: float) -> int:
	return clampi(ceili(TAU * radius * _scale / FAN_PX), MIN_FAN, MAX_FAN)


func _add(p: PackedVector2Array, color: Color, tri: PackedInt32Array) -> void:
	var base := points.size()
	points.append_array(p)
	var c := PackedColorArray()
	c.resize(p.size())
	c.fill(color)
	colors.append_array(c)
	for i: int in tri:
		indices.append(base + i)
