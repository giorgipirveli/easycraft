class_name CarPicture
extends Control
## Owner #109: a car's picture for the garage, drawn from its own model (CarModels.parts: the same boxes): seen from its
## right side, its front to the right, the far wheels first, then the body's boxes from the far side to the near one,
## then the near wheels. No textures, no 3D view: a few rectangles and discs, redrawn only when it changes.

const OUTLINE := Color(0, 0, 0, 0.35)

var kind: StringName = CarKinds.GO_KART:
	set(v):
		kind = v
		queue_redraw()
var colour := 0:
	set(v):
		colour = CarKinds.colour_index(v)
		queue_redraw()


func _init(k: StringName = CarKinds.GO_KART, c: int = 0, side := Vector2(160, 90)) -> void:
	kind = k
	colour = c
	custom_minimum_size = side
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## The picture's boxes as [rect (in the car's z / y metres, front at -z), colour, depth (x)], far ones first.
static func shapes(k: StringName, c: int) -> Array:
	var out: Array = []
	for p: Variant in CarModels.parts(k, c):
		if p is Array:
			var centre: Vector3 = p[0]
			var size: Vector3 = p[1]
			var basis: Basis = p[3] if (p as Array).size() > 3 else Basis.IDENTITY
			var lo := Vector2(INF, INF)
			var hi := Vector2(-INF, -INF)
			for sx: float in [-0.5, 0.5]:
				for sy: float in [-0.5, 0.5]:
					for sz: float in [-0.5, 0.5]:
						var corner := centre + basis * Vector3(size.x * sx, size.y * sy, size.z * sz)
						lo = Vector2(minf(lo.x, corner.z), minf(lo.y, corner.y))
						hi = Vector2(maxf(hi.x, corner.z), maxf(hi.y, corner.y))
			out.append([Rect2(lo, hi - lo), p[2], centre.x])
		elif p is Dictionary:
			var d: Dictionary = p
			var r := 0.0
			for ring: Array in d.rings:
				r = maxf(r, float(ring[1]))
			var c3: Vector3 = d.center
			out.append([Rect2(Vector2(c3.z - r, c3.y - r), Vector2(r, r) * 2.0), d.back, c3.x])
	out.sort_custom(func(a: Array, b: Array) -> bool: return float(a[2]) < float(b[2]))
	return out


func _draw() -> void:
	if not CarKinds.exists(kind):
		return
	var s := CarKinds.size(kind)
	var span := Vector2(s.z + 0.6, s.y + 0.4)
	var scale_px := minf(size.x / span.x, size.y / span.y)
	var origin := Vector2(size.x * 0.5, size.y * 0.5 + (s.y * 0.5) * scale_px)   # the car's feet, its middle
	var to_px := func(z: float, y: float) -> Vector2: return origin + Vector2(-z, -y) * scale_px
	var r := CarKinds.wheel_radius(kind)
	for w: Vector3 in CarKinds.wheels(kind):
		if w.x < 0.0:
			_wheel(to_px.call(w.z, w.y), r * scale_px, true)
	for sh: Array in shapes(kind, colour):
		var rect: Rect2 = sh[0]
		var a: Vector2 = to_px.call(rect.end.x, rect.end.y)
		var b: Vector2 = to_px.call(rect.position.x, rect.position.y)
		var px := Rect2(a, b - a).abs()
		draw_rect(px, sh[1])
		draw_rect(px, OUTLINE, false, 1.0)
	for w: Vector3 in CarKinds.wheels(kind):
		if w.x >= 0.0:
			_wheel(to_px.call(w.z, w.y), r * scale_px, false)
	for spot: Vector3 in CarModels.rotor_spots(kind):
		if spot.x > 0.0:
			var at: Vector2 = to_px.call(spot.z, spot.y + 0.1)
			draw_line(at - Vector2(0.55 * scale_px, 0), at + Vector2(0.55 * scale_px, 0), CarModels.TRIM, maxf(2.0, scale_px * 0.06))
	if CarKinds.hovers(kind):   # the air cushion under a hover car
		for x: float in [-1.0, 1.0]:
			var at: Vector2 = to_px.call(x * s.z * 0.3, 0.12)
			draw_line(at - Vector2(0.4 * scale_px, 0), at + Vector2(0.4 * scale_px, 0), CarModels.GLOW, maxf(2.0, scale_px * 0.05))


func _wheel(at: Vector2, radius: float, far: bool) -> void:
	draw_circle(at, radius, CarModels.TYRE.darkened(0.3) if far else CarModels.TYRE)
	draw_circle(at, radius * 0.6, CarModels.RIM.darkened(0.3) if far else CarModels.RIM)
	draw_circle(at, radius * 0.22, CarModels.TRIM)
