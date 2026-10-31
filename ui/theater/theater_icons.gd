class_name TheaterIcons
extends RefCounted
## The pictures on the Theater's channel tabs and video cards (owner #89: "channels as big picture tabs"): a TV,
## a planet, a flask, a paw, a gear, a music note, a palette, a pyramid, a star (TheaterChannels.ICONS). White
## shapes drawn once into small textures, like the panel's arrows: no image files, nothing to license.

const SIZE := 48

static var _cache: Dictionary = {}


static func icon(name: StringName, size: int = SIZE) -> Texture2D:
	var key := "%s@%d" % [name, size]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var draw := _shape(name if TheaterChannels.ICONS.has(name) else TheaterChannels.DEFAULT_ICON)
	for y in size:
		for x in size:
			# Four samples a pixel: soft edges.
			var cover := 0.0
			for s: Vector2 in [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)]:
				if draw.call((Vector2(x, y) + s) / size):
					cover += 0.25
			if cover > 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, cover))
	var tex := ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


static func _shape(name: StringName) -> Callable:
	match name:
		&"planet":
			return _planet
		&"flask":
			return _flask
		&"paw":
			return _paw
		&"gear":
			return _gear
		&"note":
			return _note
		&"palette":
			return _palette
		&"pyramid":
			return _pyramid
		&"star":
			return _star
	return _tv


static func _tv(p: Vector2) -> bool:
	var body := _round_rect(p, Rect2(0.1, 0.3, 0.8, 0.52), 0.08)
	var screen := _round_rect(p, Rect2(0.18, 0.38, 0.52, 0.36), 0.05)
	var knob := p.distance_to(Vector2(0.8, 0.46)) < 0.045 or p.distance_to(Vector2(0.8, 0.62)) < 0.045
	var antennas := _segment(p, Vector2(0.5, 0.3), Vector2(0.3, 0.08), 0.035) or _segment(p, Vector2(0.5, 0.3), Vector2(0.7, 0.08), 0.035)
	var feet := _round_rect(p, Rect2(0.2, 0.82, 0.12, 0.08), 0.02) or _round_rect(p, Rect2(0.68, 0.82, 0.12, 0.08), 0.02)
	return (body and not screen and not knob) or antennas or feet


static func _planet(p: Vector2) -> bool:
	var c := Vector2(0.5, 0.5)
	var ball := p.distance_to(c) < 0.25
	var q := (p - c).rotated(deg_to_rad(20.0))
	var e := pow(q.x / 0.46, 2.0) + pow(q.y / 0.13, 2.0)
	var ring := e > 0.78 and e < 1.0 and not (q.y < 0.0 and ball)
	var gap := e >= 1.0 and e < 1.45 and ball
	return (ball and not gap) or ring


static func _flask(p: Vector2) -> bool:
	var neck := Rect2(0.41, 0.1, 0.18, 0.3).has_point(p)
	var lip := Rect2(0.36, 0.08, 0.28, 0.06).has_point(p)
	var body := _in_polygon(p, [Vector2(0.41, 0.38), Vector2(0.59, 0.38), Vector2(0.86, 0.84), Vector2(0.8, 0.9),
		Vector2(0.2, 0.9), Vector2(0.14, 0.84)])
	var bubble := p.distance_to(Vector2(0.44, 0.7)) < 0.05 or p.distance_to(Vector2(0.58, 0.6)) < 0.035
	return neck or lip or (body and not bubble)


static func _paw(p: Vector2) -> bool:
	var pad := pow((p.x - 0.5) / 0.22, 2.0) + pow((p.y - 0.68) / 0.18, 2.0) < 1.0
	for toe: Vector2 in [Vector2(0.24, 0.44), Vector2(0.4, 0.27), Vector2(0.6, 0.27), Vector2(0.76, 0.44)]:
		if p.distance_to(toe) < 0.09:
			return true
	return pad


static func _gear(p: Vector2) -> bool:
	var q := p - Vector2(0.5, 0.5)
	var r := q.length()
	var a := fposmod(atan2(q.y, q.x), TAU / 8.0) / (TAU / 8.0)
	var tooth := a > 0.25 and a < 0.75
	return (r > 0.14 and r < 0.33) or (tooth and r >= 0.33 and r < 0.44)


static func _note(p: Vector2) -> bool:
	var head_a := pow((p.x - 0.34) / 0.13, 2.0) + pow((p.y - 0.74) / 0.1, 2.0) < 1.0
	var head_b := pow((p.x - 0.72) / 0.13, 2.0) + pow((p.y - 0.64) / 0.1, 2.0) < 1.0
	var stem_a := Rect2(0.41, 0.22, 0.06, 0.52).has_point(p)
	var stem_b := Rect2(0.79, 0.12, 0.06, 0.52).has_point(p)
	var beam := _segment(p, Vector2(0.44, 0.25), Vector2(0.82, 0.15), 0.05)
	return head_a or head_b or stem_a or stem_b or beam


static func _palette(p: Vector2) -> bool:
	var blob := pow((p.x - 0.5) / 0.42, 2.0) + pow((p.y - 0.52) / 0.36, 2.0) < 1.0
	for hole: Vector2 in [Vector2(0.3, 0.4), Vector2(0.46, 0.3), Vector2(0.64, 0.32), Vector2(0.28, 0.6)]:
		if p.distance_to(hole) < 0.065:
			return false
	var thumb := p.distance_to(Vector2(0.64, 0.66)) < 0.09
	return blob and not thumb


static func _pyramid(p: Vector2) -> bool:
	if not _in_polygon(p, [Vector2(0.5, 0.12), Vector2(0.92, 0.86), Vector2(0.08, 0.86)]):
		return false
	for y: float in [0.36, 0.52, 0.68]:
		if absf(p.y - y) < 0.022:
			return false
	return true


static func _star(p: Vector2) -> bool:
	var points: Array = []
	for i in 10:
		var r := 0.42 if i % 2 == 0 else 0.18
		var a := -PI / 2.0 + i * PI / 5.0
		points.append(Vector2(0.5, 0.54) + Vector2(cos(a), sin(a)) * r)
	return _in_polygon(p, points)


static func _round_rect(p: Vector2, r: Rect2, radius: float) -> bool:
	var inner := r.grow(-radius)
	var nearest := p.clamp(inner.position, inner.end)
	return p.distance_to(nearest) <= radius


static func _segment(p: Vector2, a: Vector2, b: Vector2, half_width: float) -> bool:
	return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) <= half_width


static func _in_polygon(p: Vector2, points: Array) -> bool:
	return Geometry2D.is_point_in_polygon(p, PackedVector2Array(points))
