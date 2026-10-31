class_name AltarKit
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.11, §4.5; docs/devlog/parts/game-altar-b.md §1): Balance
## Altar's building blocks, over LifeRoomKit's way (made in code, no assets loaded, no shadows). Every place is drawn as a
## few merged meshes (everything that does not move by itself: one mesh a material, whatever its pieces) and a MultiMesh
## per moving or repeated shape (gems, balloons, strings, the ring's altars and crystals, the chandelier's sockets,
## clouds), in vertex colours with soft shading baked in (a lighter top, a darker foot), on materials the warm-up already
## holds (ShaderWarmup's census, data/shader_warmup.json; only a material's bool and int settings make its shader):
## - `lit()`, `shiny()`: the Theater building's (lit, `vertex_color_use_as_albedo`, `vertex_color_is_srgb`); also
##   instanced (the hub circle's stones, the butterflies). `shiny` is the same shader, smoother (gold, gems);
## - `glow()`: the launch site blinker's (unshaded, vertex colours); also instanced (the fireflies): what gives light
##   (the crystals' chains, the Glimmers, the sky, the windows, the chandelier's sockets, clouds);
## - `glass()`: the rainbow arch's (unshaded, alpha, two-sided, vertex colours), never instanced: the crystals, the
##   light from the oculus, halos.
## Every triangle faces along its first corner's normal (Godot's front face: clockwise seen from that side;
## test_mesh_winding.gd), so nothing is lit from inside. A MultiMesh's instance colour multiplies its mesh's colours.

## Where the baked shading's light comes from (above, a little left and in front: the oculus and the sunset).
const LIGHT := Vector3(-0.35, 0.85, 0.4)

static var _mats := {}
static var _meshes := {}


static func lit() -> StandardMaterial3D:
	if not _mats.has("lit"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = 0.82
		_mats["lit"] = m
	return _mats["lit"]


static func shiny() -> StandardMaterial3D:
	if not _mats.has("shiny"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = 0.38
		m.metallic_specular = 0.75
		_mats["shiny"] = m
	return _mats["shiny"]


static func glow() -> StandardMaterial3D:
	if not _mats.has("glow"):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		_mats["glow"] = m
	return _mats["glow"]


static func glass() -> StandardMaterial3D:
	if not _mats.has("glass"):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		_mats["glass"] = m
	return _mats["glass"]


## A merged mesh under `parent` (no shadows).
static func mesh(parent: Node3D, node_name: String, m: Mesh, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = m
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## A MultiMesh of `count` instances of `m` under `parent`, with per-instance colours; every instance starts hidden.
## `bounds`: the box it may fill (a MultiMesh's own box is only worked out as it draws).
static func multimesh(parent: Node3D, node_name: String, m: Mesh, material: Material, count: int,
		bounds: AABB) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = m
	mm.instance_count = count
	for i in count:
		mm.set_instance_transform(i, hidden())
		mm.set_instance_color(i, Color.WHITE)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = bounds
	parent.add_child(mmi)
	return mmi


## A hidden instance (a MultiMesh slot not shown now).
static func hidden() -> Transform3D:
	return Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)


## A colour lit by the baked light for a face turned to `normal` (for the unshaded materials).
static func shade(colour: Color, normal: Vector3, low: float = 0.72, high: float = 1.12) -> Color:
	var k := clampf(normal.normalized().dot(LIGHT.normalized()), 0.0, 1.0)
	var f := lerpf(low, high, k)
	return Color(colour.r * f, colour.g * f, colour.b * f, colour.a)


## The place's sun: the room's own LifeRoomSun (the rooms' look), warm, no shadows, the only light while the place
## shows (it puts the world's suns away and gives them back).
static func sun_for(room: LifeRoom, pitch_deg: float, yaw_deg: float, colour: Color, energy: float) -> LifeRoomSun:
	var l := room.sun(colour, energy, pitch_deg, yaw_deg)
	l.light_specular = 0.4
	return l


## A basis whose +Y is `normal` (a disc or a lathe facing that way), safe for any direction.
static func facing(normal: Vector3) -> Basis:
	var y := normal.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	return Basis(x, y, x.cross(y))


## A soft disc of light facing `normal` (for the glass material): `colour` in its middle, fading to nothing at its edge.
static func halo(m: Mesher, at: Vector3, normal: Vector3, radius: float, colour: Color) -> void:
	var y := normal.normalized()
	var x := y.cross(Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	m.lathe(Transform3D(Basis(x, y, z), at), [Vector2(radius, 0), Vector2(radius * 0.4, 0), Vector2(0, 0)] as Array[Vector2],
		[Color(colour, 0.0), Color(colour, colour.a * 0.4), colour] as Array[Color], 24)


## The place's environment: a plain background (no sky shader: each place draws its own sky dome), a coloured ambient
## light, the worlds' tone.
static func environment(background: Color, ambient: Color, ambient_energy: float) -> Environment:
	var env := LifeRoomKit.environment(background, background, ambient_energy)
	env.ambient_light_color = ambient
	env.set_meta(&"altar_ambient", ambient)
	env.set_meta(&"altar_ambient_energy", ambient_energy)
	return env


## The place's own tone back on `env` after the rooms' look toned it for a daylight room (LifeRoomDecor.tone: a
## blue-white ambient): the worlds' ACES tone kept, the place's own warm ambient and exposure.
static func own_tone(env: Environment, exposure: float = 1.0) -> void:
	if env == null:
		return
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = exposure
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = env.get_meta(&"altar_ambient", env.ambient_light_color)
	env.ambient_light_energy = float(env.get_meta(&"altar_ambient_energy", env.ambient_light_energy))


## A sky round a place (an unlit dome facing in): `bands` from the zenith down to the nadir, each [elevation in degrees
## (90 the zenith, -90 the nadir), colour].
static func sky_dome(radius: float, bands: Array) -> ArrayMesh:
	var m := Mesher.new()
	var profile: Array[Vector2] = []
	var colours: Array[Color] = []
	for b: Array in bands:
		var e := deg_to_rad(float(b[0]))
		profile.append(Vector2(cos(e) * radius, sin(e) * radius))
		colours.append(b[1])
	m.lathe(Transform3D(), profile, colours, 40)
	return m.commit()


## One puff of a cloud: a soft ball, white on top, a little shadowed under (glow, instanced: the fireflies' draw).
static func cloud_puff() -> ArrayMesh:
	if not _meshes.has("puff"):
		var m := Mesher.new()
		m.sphere(Transform3D(), 1.0, Color(1, 1, 1), Color(0.8, 0.82, 0.9), 14, 8)
		_meshes["puff"] = m.commit()
	return _meshes["puff"]


## A fluted stone column with a gold base ring and a gold capital, `height` tall, standing at `at`.
static func column(m: Mesher, at: Vector3, height: float, radius: float, stone: Color = Color("f6f0e6")) -> void:
	var gold := Color("e9b83f")
	var gold_top := Color("ffe39a")
	var xf := Transform3D(Basis(), at)
	var r := radius
	m.lathe(xf, [Vector2(r * 1.45, 0.0), Vector2(r * 1.45, r * 0.45), Vector2(r * 1.3, r * 0.6), Vector2(r * 1.3, r * 0.9),
		Vector2(r * 1.1, r * 1.15)] as Array[Vector2], [stone.darkened(0.25), stone.darkened(0.12), gold, gold, stone] as Array[Color], 24)
	m.lathe(xf, [Vector2(r * 1.07, r * 1.1), Vector2(r * 0.92, height - r * 2.4)] as Array[Vector2],
		[stone.darkened(0.1), stone.lightened(0.04)] as Array[Color], 48, false, false, 0.0, 0.06, 16)
	m.lathe(xf, [Vector2(r * 0.92, height - r * 2.45), Vector2(r * 1.07, height - r * 2.15), Vector2(r * 1.45, height - r * 1.75),
		Vector2(r * 1.45, height - r * 1.5), Vector2(0.0, height - r * 1.5)] as Array[Vector2],
		[gold.darkened(0.1), gold, gold_top, gold, gold] as Array[Color], 24)
	m.box(Transform3D(Basis(), at + Vector3(0, height - r * 0.75, 0)), Vector3(r * 3.1, r * 1.5, r * 3.1), stone, stone.lightened(0.06))


## Professor Hoot (DISCOVER's owl): the game's own owl (BlockyAnimal's, head and all) in a teacher's square cap with a
## gold tassel; about 0.75 tall, facing +Z. One draw.
static func hoot_mesh() -> ArrayMesh:
	if _meshes.has("hoot"):
		return _meshes["hoot"]
	var m := Mesher.new()
	m.append_mesh(BlockyAnimal.mesh_for(&"owl"), Transform3D())
	var head := BlockyAnimal.part_mesh_for(&"owl")
	var pivot: Vector3 = BlockyAnimal.PART_PIVOT.get(&"owl", Vector3.ZERO)
	if head != null:
		m.append_mesh(head, Transform3D(Basis(), pivot))
	var top := m.top_y()
	var navy := Color("22283b")
	m.box(Transform3D(Basis(), Vector3(0, top + 0.03, 0)), Vector3(0.18, 0.06, 0.16), navy, navy.lightened(0.12))
	m.box(Transform3D(Basis(Vector3.UP, 0.62), Vector3(0, top + 0.075, 0)), Vector3(0.3, 0.025, 0.3), Color("2d3550"),
		Color("38426a"))
	var gold := Color("e7b53c")
	m.box(Transform3D(Basis(), Vector3(0, top + 0.095, 0)), Vector3(0.03, 0.02, 0.03), gold, gold.lightened(0.2))
	m.tube(Vector3(0, top + 0.095, 0), Vector3(0.14, top + 0.09, 0.07), 0.008, gold, gold, 5)
	m.tube(Vector3(0.14, top + 0.09, 0.07), Vector3(0.14, top - 0.01, 0.07), 0.008, gold, gold, 5)
	m.sphere(Transform3D(Basis(), Vector3(0.14, top - 0.02, 0.07)), 0.022, Color("f2c95a"), Color("d9a332"), 6, 4)
	var mesh := m.commit()
	_meshes["hoot"] = mesh
	return mesh


## Professor Hoot under `parent` at `at` (one draw), facing +Z turned by `yaw`.
static func hoot(parent: Node3D, at: Vector3, yaw: float = 0.0, size: float = 1.0) -> MeshInstance3D:
	var mi := mesh(parent, "Hoot", hoot_mesh(), lit())
	mi.position = at
	mi.rotation.y = yaw
	mi.scale = Vector3.ONE * size
	return mi


## Builds one merged surface from many primitives, each placed by a transform, in vertex colours. Every triangle is
## turned to face along its first corner's normal (Godot's front: clockwise seen from that side).
class Mesher:
	extends RefCounted
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var i := PackedInt32Array()

	func count() -> int:
		return v.size()

	func add(p: Vector3, normal: Vector3, colour: Color) -> int:
		v.append(p)
		n.append(normal)
		c.append(colour)
		return v.size() - 1

	## A triangle facing along its first corner's normal.
	func tri(a: int, b: int, d: int) -> void:
		var face := (v[b] - v[a]).cross(v[d] - v[a])
		i.append(a)
		if face.dot(n[a]) > 0.0:
			i.append(d)
			i.append(b)
		else:
			i.append(b)
			i.append(d)

	func quad(a: int, b: int, d: int, e: int) -> void:
		tri(a, b, d)
		tri(a, d, e)

	## The highest point so far (to stack something on top).
	func top_y() -> float:
		var y := -INF
		for p in v:
			y = maxf(y, p.y)
		return y if y > -INF else 0.0

	## Another mesh's first surface, placed by `xf` (its triangles keep facing along their normals).
	func append_mesh(mesh: Mesh, xf: Transform3D, tint: Color = Color.WHITE) -> void:
		if mesh == null or mesh.get_surface_count() == 0:
			return
		var arrays := mesh.surface_get_arrays(0)
		var pv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var pn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var pc: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if arrays[Mesh.ARRAY_COLOR] != null else PackedColorArray()
		var pi: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var nb := xf.basis.inverse().transposed()
		var first := v.size()
		for k in pv.size():
			var col := pc[k] if k < pc.size() else Color.WHITE
			add(xf * pv[k], (nb * pn[k]).normalized(), col * tint)
		if pi.is_empty():
			for k in range(0, pv.size(), 3):
				tri(first + k, first + k + 1, first + k + 2)
		else:
			for k in range(0, pi.size(), 3):
				tri(first + pi[k], first + pi[k + 1], first + pi[k + 2])

	## A box: each face one colour (the top `top`), the sides darkening to their foot (`foot`: 0 none).
	func box(xf: Transform3D, size: Vector3, side: Color, top: Color, foot: float = 0.14, bottom: Color = Color(0, 0, 0, 0)) -> void:
		var h := size * 0.5
		var nb := xf.basis.inverse().transposed()
		var under := bottom if bottom.a > 0.0 else side.darkened(0.3)
		var faces := [
			[Vector3.RIGHT, Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)],
			[Vector3.LEFT, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)],
			[Vector3.UP, Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)],
			[Vector3.DOWN, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)],
			[Vector3.BACK, Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)],
			[Vector3.FORWARD, Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)],
		]
		for f: Array in faces:
			var fn: Vector3 = f[0]
			var nn := (nb * fn).normalized()
			var col := top if fn == Vector3.UP else (under if fn == Vector3.DOWN else side)
			var base := v.size()
			for q in 4:
				var p: Vector3 = f[1 + q]
				var k := col
				if fn != Vector3.UP and fn != Vector3.DOWN and p.y < 0.0:
					k = col.darkened(foot)
				add(xf * p, nn, k)
			quad(base, base + 1, base + 2, base + 3)

	## A surface of revolution about the transform's Y: `profile` points (radius, height) from one end to the other
	## (bottom to top faces outwards; top to bottom faces inwards), a colour a point, `seg` sides. `flat`: faceted (each
	## face its own normal, its colour shaded by the baked light when `baked`). `twist`: the first side's angle.
	func lathe(xf: Transform3D, profile: Array[Vector2], colours: Array[Color], seg: int, flat: bool = false,
			baked: bool = false, twist: float = 0.0, ripple: float = 0.0, ripples: int = 0) -> void:
		var rows := profile.size()
		if rows < 2:
			return
		var nb := xf.basis.inverse().transposed()
		var normals2: Array[Vector2] = []
		for r in rows:
			var d := profile[mini(r + 1, rows - 1)] - profile[maxi(r - 1, 0)]
			normals2.append(Vector2(d.y, -d.x).normalized())
		if not flat:
			var first := v.size()
			for r in rows:
				for k in seg + 1:
					var th := twist + TAU * k / seg
					var rr := profile[r].x * (1.0 + ripple * cos(th * ripples)) if ripples > 0 else profile[r].x
					var p := Vector3(cos(th) * rr, profile[r].y, sin(th) * rr)
					var nl := Vector3(cos(th) * normals2[r].x, normals2[r].y, sin(th) * normals2[r].x)
					var col := colours[mini(r, colours.size() - 1)]
					if ripples > 0:
						col = col.darkened(0.12 * (1.0 - cos(th * ripples)) * 0.5)
					add(xf * p, (nb * nl).normalized(), col)
			for r in rows - 1:
				for k in seg:
					var a := first + r * (seg + 1) + k
					quad(a, a + 1, a + seg + 2, a + seg + 1)
			return
		for r in rows - 1:
			for k in seg:
				var t0 := twist + TAU * k / seg
				var t1 := twist + TAU * (k + 1) / seg
				var p00 := Vector3(cos(t0) * profile[r].x, profile[r].y, sin(t0) * profile[r].x)
				var p01 := Vector3(cos(t1) * profile[r].x, profile[r].y, sin(t1) * profile[r].x)
				var p10 := Vector3(cos(t0) * profile[r + 1].x, profile[r + 1].y, sin(t0) * profile[r + 1].x)
				var p11 := Vector3(cos(t1) * profile[r + 1].x, profile[r + 1].y, sin(t1) * profile[r + 1].x)
				var mid := (t0 + t1) * 0.5
				var n2 := (normals2[r] + normals2[r + 1]).normalized()
				var outward := Vector3(cos(mid) * n2.x, n2.y, sin(mid) * n2.x)
				var face := (p10 - p01).cross(p11 - p00)
				if face.length() < 0.0000001:
					face = (p11 - p00).cross(p10 - p00) if (p11 - p00).length() > 0.0 else outward
				if face.dot(outward) < 0.0:
					face = -face
				var fn := (nb * face.normalized()).normalized()
				var c0 := colours[mini(r, colours.size() - 1)]
				var c1 := colours[mini(r + 1, colours.size() - 1)]
				if baked:
					c0 = AltarKit.shade(c0, fn)
					c1 = AltarKit.shade(c1, fn)
				var a := add(xf * p00, fn, c0)
				var b := add(xf * p01, fn, c0)
				var e := add(xf * p11, fn, c1)
				var f := add(xf * p10, fn, c1)
				quad(a, b, e, f)

	## A ball (`top` to `bottom` colours).
	func sphere(xf: Transform3D, radius: float, top: Color, bottom: Color, seg: int = 12, rings: int = 7) -> void:
		var profile: Array[Vector2] = []
		var colours: Array[Color] = []
		for r in rings + 1:
			var phi := -PI * 0.5 + PI * r / rings
			profile.append(Vector2(cos(phi) * radius, sin(phi) * radius))
			colours.append(bottom.lerp(top, float(r) / rings))
		lathe(xf, profile, colours, seg)

	## A tube from `a` to `b` (radius `r`), colours at each end; closed ends when `caps`.
	func tube(a: Vector3, b: Vector3, r: float, ca: Color, cb: Color, seg: int = 10, caps: bool = false, rb: float = -1.0) -> void:
		var axis := b - a
		var length := axis.length()
		if length < 0.00001:
			return
		var y := axis / length
		var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
		var z := x.cross(y)
		var xf := Transform3D(Basis(x, y, z), a)
		var top := rb if rb >= 0.0 else r
		if caps:
			lathe(xf, [Vector2(0, 0), Vector2(r, 0), Vector2(top, length), Vector2(0, length)] as Array[Vector2],
				[ca, ca, cb, cb] as Array[Color], seg)
		else:
			lathe(xf, [Vector2(r, 0), Vector2(top, length)] as Array[Vector2], [ca, cb] as Array[Color], seg)

	## A ring (a torus about the transform's Y): radius `big`, tube radius `small`.
	func torus(xf: Transform3D, big: float, small: float, colour: Color, inner: Color, seg: int = 16, tube_seg: int = 6) -> void:
		var profile: Array[Vector2] = []
		var colours: Array[Color] = []
		for k in tube_seg + 1:
			var t := -PI * 0.5 + TAU * k / tube_seg
			profile.append(Vector2(big + cos(t) * small, sin(t) * small))
			colours.append(inner.lerp(colour, (sin(t) + 1.0) * 0.5))
		lathe(xf, profile, colours, seg)

	## A flat disc facing the transform's +Y (`centre` to `edge`).
	func disc(xf: Transform3D, radius: float, centre: Color, edge: Color, seg: int = 24, inner: float = 0.0) -> void:
		lathe(xf, [Vector2(radius, 0), Vector2(inner, 0)] as Array[Vector2], [edge, centre] as Array[Color], seg)

	## A flat quad facing `normal` from its four corners (a, b, d, e around), colours a corner.
	func panel(a: Vector3, b: Vector3, d: Vector3, e: Vector3, normal: Vector3, ca: Color, cb: Color, cd: Color, ce: Color) -> void:
		var nn := normal.normalized()
		quad(add(a, nn, ca), add(b, nn, cb), add(d, nn, cd), add(e, nn, ce))

	## The whole surface as one mesh (the material is the node's).
	func commit() -> ArrayMesh:
		var am := ArrayMesh.new()
		if v.is_empty():
			return am
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = v
		arrays[Mesh.ARRAY_NORMAL] = n
		arrays[Mesh.ARRAY_COLOR] = c
		arrays[Mesh.ARRAY_INDEX] = i
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return am
