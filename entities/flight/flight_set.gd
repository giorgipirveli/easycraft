class_name FlightSet
extends Node3D
## The flight's own piece of space (owner #79: "the Earth and the Moon as real spheres, stars, the Sun's light"; spec
## §25.3), far above the world (RocketFlight.SET_OFFSET) with the rocket at its middle: the stars (one mesh, always round
## the camera), the Sun (its own light for the flight's things only, and its glowing disc: three times as big over
## Mercury), the Earth and the destination as whole spheres (FlightLooks' planet shader: the Earth's clouds turning, the
## Moon's real seas and craters), and the landing ground (the dust in the blocks' look, tinted per world, the landing pad
## in the brand's teal with a golden star, rocks). Its sky is its own environment (the camera's while in space): the
## day's blue turning black, or the destination's own sky under its air, fog hiding the ground's far edge.
## A body far away is drawn nearer and smaller (its size in the sky stays right); the target is never smaller than a
## dot a child can aim at (MIN_TARGET degrees).

const STAR_COUNT := 700
const STAR_SEED := 20260929
const STAR_RADIUS := 85000.0
const FAR_DRAW := 70000.0         # bodies farther than this are drawn here, smaller
const MIN_TARGET := 1.1           # degrees: a target's smallest radius in the sky
const EARTH_MIN := 2.0            # degrees: the Earth behind us stays a marble a child can see
const SUN_DISTANCE := 80000.0
const GROUND_RADIUS := 1600.0
const DAY_SKY := Color(0.42, 0.62, 0.92)

var destination := SpaceRules.MOON
var layer := 1
var env := Environment.new()
var sun: DirectionalLight3D
var stars: MeshInstance3D
var sun_disc: MeshInstance3D
var earth: MeshInstance3D
var dest: MeshInstance3D
var ground: Node3D
var pad: MeshInstance3D
var dust: CPUParticles3D
var pad_offset := Vector3.ZERO

var _look := {}
var _earth_face := Vector3.UP
var _dest_face := Vector3.UP


func setup(destination_world: int, visual_layer: int) -> void:
	for part in parts(destination_world, visual_layer):
		part.call()


## setup() in pieces, each light enough for a frame of its own (RocketFlight builds a flight's set over the boarding).
func parts(destination_world: int, visual_layer: int) -> Array[Callable]:
	destination = destination_world
	layer = visual_layer
	sun = DirectionalLight3D.new()
	stars = MeshInstance3D.new()
	sun_disc = MeshInstance3D.new()
	earth = MeshInstance3D.new()
	dest = MeshInstance3D.new()
	_look = FlightLooks.look(destination)
	_environment()
	return [_add_sun, _build_stars, _add_bodies, _build_ground]


func _add_sun() -> void:
	sun.name = "Sun"
	sun.light_cull_mask = layer | RocketFlight.ROCKET_LAYER
	sun.shadow_enabled = false
	sun.light_energy = 1.6
	sun.basis = Basis.looking_at(-FlightLooks.SUN_DIR, Vector3.UP)
	add_child(sun)
	sun_disc.name = "SunDisc"
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = FlightLooks.sun_material()
	sun_disc.mesh = quad
	_own(sun_disc)


func _add_bodies() -> void:
	for pair: Array in [[earth, "Earth", FlightLooks.earth_material()], [dest, "Destination",
			FlightLooks.planet_material(destination)]]:
		var m: MeshInstance3D = pair[0]
		m.name = pair[1]
		m.mesh = FlightLooks.sphere()
		m.material_override = pair[2]
		_own(m)
	_earth_face = _face_point(20.0, 10.0)   # Africa and Europe face the rocket
	match destination:
		SpaceRules.MARS:
			_dest_face = _face_point(-5.0, -70.0)   # the canyon and the volcanoes
		SpaceRules.MERCURY:
			_dest_face = _face_point(25.0, 150.0)   # the Caloris basin
		_:
			_dest_face = _face_point(0.0, 0.0)   # the Moon's near side, the one Earth sees


## Applies a moment of the flight (FlightShots.pose) round the camera at `cam` (global).
func apply(pose: Dictionary, cam: Vector3, time: float) -> void:
	var sky := Color.BLACK
	if float(pose.air_sky) > 0.0 and (_look.sky as Color).a > 0.0:
		sky = Color.BLACK.lerp(_look.sky, float(pose.air_sky))
	else:
		sky = DAY_SKY.lerp(Color.BLACK, float(pose.sky))
	env.background_color = sky
	var fog := bool(pose.ground)   # always on (one way of drawing all flight long), far away when there is no ground
	env.fog_depth_begin = 500.0 if fog else 1e8
	env.fog_depth_end = GROUND_RADIUS * 0.95 if fog else 1e8 + 1.0
	env.fog_light_color = sky if (_look.sky as Color).a > 0.0 and pose.air else Color(0.02, 0.02, 0.03)
	var local_cam := to_local(cam)
	if sun_disc.get_parent() == null:   # the Sun is built a frame later in a landing
		return
	stars.position = local_cam
	stars.visible = float(pose.air_sky) < 0.7 and float(pose.sky) > 0.2
	var sun_size := float(_look.get("sun_size", 1.0))
	sun_disc.position = local_cam + FlightLooks.SUN_DIR.normalized() * SUN_DISTANCE
	sun_disc.scale = Vector3.ONE * SUN_DISTANCE * tan(deg_to_rad(1.6 * sun_size)) * 2.0
	sun_disc.visible = float(pose.air_sky) < 0.8
	var e: Dictionary = pose.earth
	var ground_shown := bool(pose.ground)
	earth.visible = (bool(e.show) or (ground_shown and destination == SpaceRules.MOON)) \
		and FlightLooks.has_map(earth.material_override)
	if earth.visible:
		if ground_shown:   # the Earth hanging in the Moon's black sky over the landing
			_place(earth, 384400.0 * FlightShots.VISUAL_R / FlightShots.EARTH_KM, Vector3(0.35, 0.5, -0.8).normalized(), 1.9,
				_earth_face)
		else:
			_place(earth, float(e.alt), e.dir, EARTH_MIN, _earth_face)
		var em := earth.material_override as ShaderMaterial
		em.set_shader_parameter(&"spin", time * 0.0035)
		em.set_shader_parameter(&"cloud_spin", time * 0.0055)
	var d: Dictionary = pose.dest
	dest.visible = bool(d.show) and not ground_shown and FlightLooks.has_map(dest.material_override)
	if dest.visible:
		_place(dest, float(d.alt), d.dir, MIN_TARGET, _dest_face)
		(dest.material_override as ShaderMaterial).set_shader_parameter(&"spin", time * 0.002)
	if ground == null:   # built a few frames into a landing
		return
	ground.visible = ground_shown
	if ground_shown:
		ground.position = Vector3(0, -float(pose.ground_h), 0) - pad_offset


## Body `m` (a unit sphere) with its surface `alt` set units away in direction `dir` from the rocket (the set's middle),
## its `face` (a point of its map, on the unit sphere) turned toward the rocket; `min_deg`: never smaller in the sky.
func _place(m: MeshInstance3D, alt: float, dir: Vector3, min_deg: float, face: Vector3) -> void:
	var r := FlightShots.VISUAL_R
	var dist := r + maxf(alt, 1.0)
	if dist > FAR_DRAW:
		r = r * FAR_DRAW / dist
		dist = FAR_DRAW
	if min_deg > 0.0:
		r = maxf(r, dist * tan(deg_to_rad(min_deg)))
	var d := dir.normalized()
	m.position = d * dist
	var toward := -d
	var up := Vector3.UP if absf(toward.dot(Vector3.UP)) < 0.95 else Vector3.BACK
	m.basis = _face_basis(face, toward, up).scaled(Vector3.ONE * r)


## A point (latitude, longitude) of an equirectangular map on the unit sphere as the sphere mesh lays it (u = 0 at +Z,
## a quarter turn at +X; the map's longitude 0 is its middle, u = 0.5).
static func _face_point(lat: float, lon: float) -> Vector3:
	var u := (lon + 180.0) / 360.0
	var la := deg_to_rad(lat)
	return Vector3(cos(la) * sin(u * TAU), sin(la), cos(la) * cos(u * TAU))


## The rotation turning the sphere's point `face` toward `toward`, its north as near to `up` as it can be.
static func _face_basis(face: Vector3, toward: Vector3, up: Vector3) -> Basis:
	var src_z := face.normalized()
	var src_x := Vector3.UP.cross(src_z)
	if src_x.length() < 0.01:
		src_x = Vector3.RIGHT
	src_x = src_x.normalized()
	var src := Basis(src_x, src_z.cross(src_x), src_z)
	var dst_z := toward.normalized()
	var dst_x := up.cross(dst_z)
	if dst_x.length() < 0.01:
		dst_x = Vector3.RIGHT
	dst_x = dst_x.normalized()
	var dst := Basis(dst_x, dst_z.cross(dst_x), dst_z)
	return dst * src.inverse()


func _environment() -> void:
	env.background_mode = Environment.BG_COLOR
	env.background_color = DAY_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.32, 0.34, 0.42)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_depth_begin = 1e8
	env.fog_depth_end = 1e8 + 1.0
	env.fog_density = 1.0


func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for i in STAR_COUNT:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if d.length() < 0.05:
			d = Vector3.UP
		d = d.normalized()
		var side := d.cross(Vector3.UP if absf(d.y) < 0.99 else Vector3.RIGHT).normalized()
		var up := side.cross(d)
		var s := rng.randf_range(90.0, 260.0) * (2.0 if rng.randf() < 0.05 else 1.0)
		var c := d * STAR_RADIUS
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
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, FlightLooks.night_material())
	stars.name = "Stars"
	stars.mesh = mesh
	stars.extra_cull_margin = STAR_RADIUS
	_own(stars)


## The landing ground: a wide disc of dust (the tile repeating every 6 m, tinted per world), the pad in its middle and a
## scatter of boulders; the engine's dust blows off it near the end.
func _build_ground() -> void:
	ground = Node3D.new()
	pad = MeshInstance3D.new()
	ground.name = "Ground"
	ground.visible = false
	add_child(ground)
	var tint: Color = _look.ground
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 48
	var tile := 6.0
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var p0 := Vector3(cos(a0), 0, sin(a0)) * GROUND_RADIUS
		var p1 := Vector3(cos(a1), 0, sin(a1)) * GROUND_RADIUS
		for p: Vector3 in [Vector3.ZERO, p0, p1]:   # clockwise seen from above
			st.set_color(tint)
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(p.x, p.z) / tile)
			st.add_vertex(p)
	st.set_material(FlightLooks.ground_material())
	var disc := MeshInstance3D.new()
	disc.name = "Dust"
	disc.mesh = st.commit()
	_own(disc, ground)
	pad.name = "Pad"
	pad.mesh = _pad_mesh()
	pad.position = Vector3(0, 0.05, 0)
	_own(pad, ground)
	var rocks := MeshInstance3D.new()
	rocks.name = "Rocks"
	rocks.mesh = _rocks_mesh(tint)
	_own(rocks, ground)
	dust = CPUParticles3D.new()
	dust.name = "EngineDust"
	dust.layers = layer
	dust.amount = Fx.scaled(40)
	dust.lifetime = 1.4
	dust.emitting = false
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	dust.emission_ring_axis = Vector3.UP
	dust.emission_ring_radius = 3.0
	dust.emission_ring_inner_radius = 1.0
	dust.emission_ring_height = 0.1
	dust.direction = Vector3(1, 0.25, 0)
	dust.spread = 180.0
	dust.flatness = 0.8
	dust.initial_velocity_min = 5.0
	dust.initial_velocity_max = 11.0
	dust.damping_min = 2.0
	dust.damping_max = 4.0
	dust.gravity = Vector3(0, -1.0, 0)
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.45
	box.material = Fx.material()
	dust.mesh = box
	dust.color = tint.lightened(0.15)
	ground.add_child(dust)


## The pad: a round glowing disc, the brand's teal ring round a light middle with a golden star (our own look, §3c).
func _pad_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 32
	var rings := [[0.0, 3.2, Color(0.85, 0.88, 0.9)], [3.2, 5.5, FlightLooks.TEAL]]
	for ring: Array in rings:
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var in0 := Vector3(cos(a0), 0, sin(a0)) * float(ring[0])
			var in1 := Vector3(cos(a1), 0, sin(a1)) * float(ring[0])
			var out0 := Vector3(cos(a0), 0, sin(a0)) * float(ring[1])
			var out1 := Vector3(cos(a1), 0, sin(a1)) * float(ring[1])
			for p: Vector3 in [in0, out0, out1, in0, out1, in1]:
				st.set_color(ring[2])
				st.set_normal(Vector3.UP)
				st.add_vertex(p)
	for i in 5:   # the star, a little above the disc
		var a := -PI * 0.5 + TAU * i / 5.0
		var tip := Vector3(cos(a), 0.02, sin(a)) * 2.6
		var l := Vector3(cos(a - 0.63), 0.02, sin(a - 0.63)) * 1.05
		var r := Vector3(cos(a + 0.63), 0.02, sin(a + 0.63)) * 1.05
		for p: Vector3 in [Vector3(0, 0.02, 0), tip, r, Vector3(0, 0.02, 0), l, tip]:
			st.set_color(FlightLooks.GOLD)
			st.set_normal(Vector3.UP)
			st.add_vertex(p)
	st.set_material(GolemModels.glow_material())
	return st.commit()


## Boulders: lumpy grey boxes scattered round the pad (never on it), one mesh.
static func _rocks_mesh(tint: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 877
	for i in 40:
		var a := rng.randf() * TAU
		var d := rng.randf_range(22.0, 700.0)
		var size := Vector3(rng.randf_range(0.8, 3.5), rng.randf_range(0.5, 2.2), rng.randf_range(0.8, 3.5)) * (1.0 + d / 400.0)
		var at := Vector3(cos(a) * d, size.y * 0.35, sin(a) * d)
		box(st, at, size, tint.darkened(rng.randf_range(0.15, 0.4)))
	st.set_material(Fx.material())
	return st.commit()


## A box of `size` round `centre` in one colour, its faces wound clockwise seen from outside (Godot's front faces).
static func box(st: SurfaceTool, centre: Vector3, size: Vector3, color: Color) -> void:
	var h := size * 0.5
	for f: Array in [[Vector3.RIGHT, Vector3.UP], [Vector3.LEFT, Vector3.UP], [Vector3.BACK, Vector3.UP],
			[Vector3.FORWARD, Vector3.UP], [Vector3.UP, Vector3.FORWARD], [Vector3.DOWN, Vector3.BACK]]:
		var n: Vector3 = f[0]
		var up: Vector3 = f[1]
		var right := (-n).cross(up)
		var c := centre + n * (h * n.abs()).length()
		var r := right * (h * right.abs()).length()
		var u := up * (h * up.abs()).length()
		for p: Vector3 in [c - r + u, c + r + u, c + r - u, c - r + u, c + r - u, c - r - u]:
			st.set_color(color)
			st.set_normal(n)
			st.add_vertex(p)


func _own(m: GeometryInstance3D, parent: Node = self) -> void:
	m.layers = layer
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(m)
