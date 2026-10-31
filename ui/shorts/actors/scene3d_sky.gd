class_name Scene3DSky
extends Node3D
## The Reel Studio (owner #96, spec §5.12b): a 3D stage's sky round its camera: a dome painted top to horizon to below
## (StudioRules.sky_at: a preset, colours, or keys fading from day to space) and the stars behind it, seen through it as
## it darkens (the dome's colours carry how opaque the sky is). The night sky's own settings (FlightLooks.night_material:
## unshaded vertex colours, see-through, never fogged): no new shader. The dome is drawn before everything else
## see-through (sorting offsets), the stars before the dome.

const SEGMENTS := 24
const RINGS := 12

var dome := MeshInstance3D.new()
var stars := MeshInstance3D.new()
var _mesh := ArrayMesh.new()
var _arrays := []
var _ring_of := PackedInt32Array()   # each vertex's ring line (0 below .. RINGS overhead)
var _last := {}


func _init() -> void:
	name = "Sky"
	_build_dome()
	dome.name = "Dome"
	dome.mesh = _mesh
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dome.sorting_offset = -1.0e6
	dome.extra_cull_margin = StudioRules.SKY_RADIUS
	add_child(dome)
	stars.name = "Stars"
	stars.mesh = star_mesh()
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stars.sorting_offset = -2.0e6
	stars.extra_cull_margin = StudioRules.STAR_RADIUS
	add_child(stars)


## The sky at a moment (colours {top, horizon, bottom, opacity}), round the camera at `at`.
func show_sky(c: Dictionary, at: Vector3) -> void:
	position = at
	stars.visible = float(c.opacity) < 0.995
	if not _last.is_empty() and _same(c, _last):
		return
	_last = c.duplicate()
	var lines: Array[Color] = []   # the colours depend on the height only: one per ring line
	for ring in RINGS + 1:
		lines.append(colour_at(c, sin(PI * (float(ring) / RINGS - 0.5))))
	var colours := PackedColorArray()
	colours.resize(_ring_of.size())
	for i in _ring_of.size():
		colours[i] = lines[_ring_of[i]]
	_arrays[Mesh.ARRAY_COLOR] = colours
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _arrays)
	_mesh.surface_set_material(0, FlightLooks.night_material())


## True when two skies differ by less than a colour step (the dome is not rebuilt for nothing).
static func _same(a: Dictionary, b: Dictionary) -> bool:
	for key: String in ["top", "horizon", "bottom"]:
		var x: Color = a[key]
		var y: Color = b[key]
		if absf(x.r - y.r) + absf(x.g - y.g) + absf(x.b - y.b) > 0.004:
			return false
	return absf(float(a.opacity) - float(b.opacity)) < 0.004


## The dome's colour at height `y` (-1 below .. 1 overhead): the horizon's glow a band round 0, the top above, the
## bottom below; its alpha the sky's opacity.
static func colour_at(c: Dictionary, y: float) -> Color:
	var col: Color
	if y >= 0.0:
		col = (c.horizon as Color).lerp(c.top, pow(clampf(y / 0.55, 0.0, 1.0), 0.7))
	else:
		col = (c.horizon as Color).lerp(c.bottom, clampf(-y / 0.25, 0.0, 1.0))
	col.a = float(c.opacity)
	return col


func _build_dome() -> void:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var r := StudioRules.SKY_RADIUS
	for ring in RINGS:
		var a0 := PI * (float(ring) / RINGS - 0.5)
		var a1 := PI * (float(ring + 1) / RINGS - 0.5)
		for s in SEGMENTS:
			var b0 := TAU * s / SEGMENTS
			var b1 := TAU * (s + 1) / SEGMENTS
			var p00 := Vector3(cos(a0) * cos(b0), sin(a0), cos(a0) * sin(b0))
			var p01 := Vector3(cos(a0) * cos(b1), sin(a0), cos(a0) * sin(b1))
			var p10 := Vector3(cos(a1) * cos(b0), sin(a1), cos(a1) * sin(b0))
			var p11 := Vector3(cos(a1) * cos(b1), sin(a1), cos(a1) * sin(b1))
			var lines := [ring, ring + 1, ring + 1, ring, ring + 1, ring]
			var corners := [p00, p10, p11, p00, p11, p01]
			for k in 6:
				verts.append((corners[k] as Vector3) * r)
				normals.append(-(corners[k] as Vector3))
				_ring_of.append(lines[k])
	_arrays.resize(Mesh.ARRAY_MAX)
	_arrays[Mesh.ARRAY_VERTEX] = verts
	_arrays[Mesh.ARRAY_NORMAL] = normals


static var _stars: ArrayMesh


## The stars: small quads all round (the flight's own recipe, fewer and farther), bluish and warm, a few bigger.
static func star_mesh() -> ArrayMesh:
	if _stars != null:
		return _stars
	var rng := RandomNumberGenerator.new()
	rng.seed = StudioRules.STAR_SEED
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for i in StudioRules.STAR_COUNT:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if d.length() < 0.05:
			d = Vector3.UP
		d = d.normalized()
		var side := d.cross(Vector3.UP if absf(d.y) < 0.99 else Vector3.RIGHT).normalized()
		var up := side.cross(d)
		var s := rng.randf_range(22.0, 60.0) * (2.2 if rng.randf() < 0.06 else 1.0)
		var c := d * StudioRules.STAR_RADIUS
		var tint := Color(0.78, 0.86, 1.0) if rng.randf() < 0.5 else Color(1.0, 0.94, 0.8)
		var color := Color.WHITE.lerp(tint, rng.randf()) * rng.randf_range(0.55, 1.0)
		color.a = 1.0
		verts.append_array([c - side * s - up * s, c + side * s - up * s, c + side * s + up * s,
			c - side * s - up * s, c + side * s + up * s, c - side * s + up * s])
		for k in 6:
			colors.append(color)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	_stars = ArrayMesh.new()
	_stars.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_stars.surface_set_material(0, FlightLooks.night_material())
	return _stars
