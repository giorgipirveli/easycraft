class_name FlightMoments
extends Node3D
## The flight's movie-style moments (owner #86: "on the space ship we should have visuals from different movies"), in
## our own look (spec §3c, §25.3), round the rocket in the flight's space set; never a film's ships, logos, sounds or
## music:
##   the jump to light speed: the stars stretch into lines and a flash (the lines then rush past);
##   a warp tunnel: gold and rainbow streaks and rings racing by (tunnel.gdshader);
##   a wormhole: our golden portal swirl opening ahead (PortalSwirl, the game's own), then a twisting teal-violet tunnel;
##   the asteroid belt: lumpy rocks tumbling past, never in the rocket's way (one MultiMesh);
##   a nebula: big soft clouds of pink, teal, gold and violet drifting by.
## Each is driven by FlightShots.pose (stretch, flash, tunnel, swirl, rocks, nebula) and costs a draw call or a few.

const STREAKS := 360
const ROCKS := 40
const ROCK_CLEAR := 12.0          # no rock nearer the rocket's way than this: never a crash
const NEBULA_COLORS: Array[Color] = [Color(1.0, 0.45, 0.75, 0.55), Color(0.3, 0.95, 0.9, 0.5), Color(1.0, 0.8, 0.35, 0.5),
	Color(0.62, 0.45, 1.0, 0.55)]

var layer := 1
var streaks: MeshInstance3D
var tunnel: MeshInstance3D
var swirl: MeshInstance3D
var rocks: MultiMeshInstance3D
var puffs: Array[MeshInstance3D] = []

var _rock_base: Array = []        # [x, y, z0, scale, spin axis, spin speed]
var _puff_base: Array[Vector3] = []
var _t := 0.0


func setup(visual_layer: int) -> void:
	for part in parts(visual_layer):
		part.call()


## setup() in pieces, each light enough for a frame of its own (RocketFlight builds them over the boarding).
func parts(visual_layer: int) -> Array[Callable]:
	layer = visual_layer
	name = "Moments"
	streaks = MeshInstance3D.new()
	tunnel = MeshInstance3D.new()
	rocks = MultiMeshInstance3D.new()
	return [_build_streaks, _build_tunnels, _build_rocks, _build_nebula, hide_all]


func _build_tunnels() -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 30.0
	cyl.bottom_radius = 30.0
	cyl.height = 1600.0
	cyl.radial_segments = 32
	cyl.rings = 4
	cyl.cap_top = false
	cyl.cap_bottom = false
	tunnel.name = "Tunnel"
	tunnel.mesh = cyl
	tunnel.rotation_degrees = Vector3(90, 0, 0)   # along the flight (-Z)
	tunnel.position = Vector3(0, 0, -500)
	tunnel.material_override = FlightLooks.tunnel_material(&"warp")
	_own(tunnel)
	var holder := Node3D.new()
	holder.name = "Swirl"
	add_child(holder)
	swirl = PortalSwirl.surface(holder, Vector2.ONE)
	swirl.layers = layer
	holder.visible = false


func hide_all() -> void:
	if swirl == null:
		return
	streaks.visible = false
	tunnel.visible = false
	swirl.get_parent().visible = false
	rocks.visible = false
	for p in puffs:
		p.visible = false


## Applies a moment of the flight (FlightShots.pose); `delta` moves what flies past.
func apply(pose: Dictionary, delta: float) -> void:
	if rocks == null or rocks.multimesh == null or puffs.is_empty():   # not built (the boarding builds it; a landing has none)
		return
	_t += delta
	var moment: StringName = pose.moment
	hide_all()
	match moment:
		FlightPlan.JUMP:
			streaks.visible = true
			var rushing := float(pose.flash) < 0.5 and float(pose.stretch) > 70.0 and _t > 0.0
			streaks.scale = Vector3(1, 1, float(pose.stretch))
			streaks.position.z = fposmod(_t * 2600.0, 1400.0) - 400.0 if rushing else 0.0
		FlightPlan.WARP, FlightPlan.WORMHOLE:
			var kind := &"warp" if moment == FlightPlan.WARP else &"wormhole"
			var m := FlightLooks.tunnel_material(kind)
			tunnel.material_override = m
			m.set_shader_parameter(&"strength", float(pose.tunnel))
			tunnel.visible = float(pose.tunnel) > 0.01
			var s := float(pose.swirl)
			swirl.get_parent().visible = s > 0.01
			if s > 0.01:
				var holder := swirl.get_parent() as Node3D
				holder.position = Vector3(0, 0, lerpf(-1400.0, -120.0, s))
				holder.scale = Vector3.ONE * lerpf(40.0, 700.0, s)
		FlightPlan.ASTEROIDS:
			rocks.visible = float(pose.rocks) > 0.01
			rocks.multimesh.visible_instance_count = int(ROCKS * clampf(float(pose.rocks), 0.0, 1.0))
			_move_rocks()
		FlightPlan.NEBULA:
			for i in puffs.size():
				var p := puffs[i]
				p.visible = true
				p.position = _puff_base[i] + Vector3(0, 0, _t * 140.0)
				var m := p.material_override as StandardMaterial3D
				m.albedo_color.a = NEBULA_COLORS[i % NEBULA_COLORS.size()].a * float(pose.nebula)


## Thin lines round the way ahead, their long side along it: at a stretch of 1 they are the stars' dots; stretched they
## are light speed's lines.
func _build_streaks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for i in STREAKS:
		var a := rng.randf() * TAU
		var r := rng.randf_range(40.0, 700.0)
		var z := rng.randf_range(-40.0, 4.0)
		var radial := Vector3(cos(a), sin(a), 0.0)
		var side := Vector3(-sin(a), cos(a), 0.0) * rng.randf_range(0.6, 1.8) * (r / 250.0)
		var c := radial * r + Vector3(0, 0, z)
		var col := Color(0.85, 0.92, 1.0) if rng.randf() < 0.6 else Color(1.0, 0.9, 0.7)
		var len := Vector3(0, 0, 1.0)
		verts.append_array([c - side, c + side, c + side + len, c - side, c + side + len, c - side + len])
		for k in 6:
			colors.append(col)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, FlightLooks.night_material())
	streaks.name = "Streaks"
	streaks.mesh = mesh
	streaks.extra_cull_margin = 4000.0
	_own(streaks)


## The asteroids: one lumpy rock (a sphere pushed in and out, grey-brown) drawn 40 times.
func _build_rocks() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var noise := FastNoiseLite.new()
	noise.seed = 31
	noise.frequency = 1.4
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 10
	sphere.rings = 6
	var arrays := sphere.get_mesh_arrays()
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	for i in v.size():
		v[i] = v[i] * (1.0 + 0.35 * noise.get_noise_3dv(v[i]))
	for t in range(0, idx.size(), 3):
		var a := v[idx[t]]
		var b := v[idx[t + 1]]
		var c := v[idx[t + 2]]
		var n := (c - a).cross(b - a).normalized()   # flat faces, facing out (clockwise seen from outside)
		var shade := Color(0.8, 0.74, 0.66).darkened(0.3 * absf(noise.get_noise_3dv(a * 3.0)))
		for p: Vector3 in [a, b, c]:
			st.set_color(shade)
			st.set_normal(n)
			st.add_vertex(p)
	st.set_material(Fx.material())
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = st.commit()
	mm.instance_count = ROCKS
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	for i in ROCKS:
		var a := rng.randf() * TAU
		var r := rng.randf_range(ROCK_CLEAR, 110.0)
		var size := rng.randf_range(3.0, 16.0) if r > ROCK_CLEAR + 12.0 else rng.randf_range(1.5, 4.0)
		_rock_base.append([cos(a) * r, sin(a) * r, rng.randf_range(-1200.0, 150.0), size,
			Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized(),
			rng.randf_range(0.2, 1.2)])
	rocks.name = "Asteroids"
	rocks.multimesh = mm
	rocks.custom_aabb = AABB(Vector3(-200, -200, -1400), Vector3(400, 400, 1700))
	_own(rocks)
	_move_rocks()


func _move_rocks() -> void:
	var mm := rocks.multimesh
	for i in ROCKS:
		var b: Array = _rock_base[i]
		var z := fposmod(float(b[2]) + _t * 150.0 + 1200.0, 1350.0) - 1200.0
		var basis := Basis(b[4] as Vector3, _t * float(b[5])).scaled(Vector3.ONE * float(b[3]))
		mm.set_instance_transform(i, Transform3D(basis, Vector3(float(b[0]), float(b[1]), z)))


func _build_nebula() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 7:
		var q := QuadMesh.new()
		q.size = Vector2.ONE * rng.randf_range(500.0, 900.0)
		var p := MeshInstance3D.new()
		p.name = "Puff%d" % i
		p.mesh = q
		p.material_override = FlightLooks.puff_material(NEBULA_COLORS[i % NEBULA_COLORS.size()])
		var a := rng.randf() * TAU
		var r := rng.randf_range(90.0, 420.0)
		_puff_base.append(Vector3(cos(a) * r, sin(a) * r, rng.randf_range(-1600.0, -300.0)))
		_own(p)
		puffs.append(p)


func _own(m: GeometryInstance3D) -> void:
	m.layers = layer
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
