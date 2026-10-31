class_name LeafKit
extends RefCounted
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.11, §4.5; docs/devlog/parts/game-leaf-b.md §1): Inside a Leaf's
## building blocks, over LifeRoomKit. Every place is drawn as a few merged meshes (everything that doesn't move by
## itself: one mesh a material, whatever its pieces) and a MultiMesh per moving shape (cells, doors, workshops, puffs,
## sugars, drops), in vertex colours (soft shading baked in: a lighter top, a darker foot, a rim) on materials the
## warm-up already holds (ShaderWarmup's census, data/shader_warmup.json):
## - `lit()`: the Theater building's (lit, `vertex_color_use_as_albedo`, `vertex_color_is_srgb`); also instanced (the hub
##   circle's stones, the butterflies);
## - `glow()`: the launch site blinker's (unshaded, vertex colours); also instanced (the fireflies);
## - `glass()`: the rainbow arch's (unshaded, alpha, two-sided, vertex colours): never instanced (the census has none);
## - `glow_disc(...)`: a soft see-through disc fading to its edge, round the Sun and the moon (the glass material).
## A MultiMesh's per-instance colour multiplies the mesh's vertex colours (white-ish meshes take their instance's
## colour); no shadows anywhere. Triangles wind clockwise as seen from their front (Godot's front face; checked in a
## window, 2026-10-18).

static var _mats := {}


static func lit() -> StandardMaterial3D:
	if not _mats.has("lit"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = 0.82
		_mats["lit"] = m
	return _mats["lit"]


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


## A soft glow round something far (the Sun, the moon): a see-through disc facing `normal`, bright in its middle and
## fading to nothing at its edge (the glass material: one draw, no billboard needed that far away).
static func glow_disc(parent: Node3D, node_name: String, at: Vector3, normal: Vector3, radius: float, colour: Color) -> MeshInstance3D:
	var m := Mesher.new()
	var y := normal.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
	var basis := Basis(x, y, x.cross(y))
	var mid := m._add(at, y, colour)
	var rings := [[0.35, Color(colour, colour.a * 0.55)], [0.7, Color(colour, colour.a * 0.18)], [1.0, Color(colour, 0.0)]]
	var seg := 28
	var prev := -1
	for ring: Array in rings:
		var first := m.count()
		for k in seg + 1:
			var th := TAU * k / seg
			m._add(at + basis * Vector3(cos(th), 0, sin(th)) * radius * float(ring[0]), y, ring[1])
		for k in seg:
			if prev < 0:
				m.tri(mid, first + k, first + k + 1)
			else:
				m.tri(prev + k, first + k, first + k + 1)
				m.tri(prev + k, first + k + 1, prev + k + 1)
		prev = first
	return mesh(parent, node_name, m.commit(), glass())


## A merged mesh under `parent` (no shadows).
static func mesh(parent: Node3D, node_name: String, m: Mesh, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = m
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## A MultiMesh of `count` instances of `m` under `parent`, with per-instance colours; every instance starts hidden
## (scale 0). `bounds`: the box it may fill (a MultiMesh's own box is only worked out as it draws).
static func multimesh(parent: Node3D, node_name: String, m: Mesh, material: Material, count: int,
		bounds: AABB) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = m
	mm.instance_count = count
	var hidden := Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)
	for i in count:
		mm.set_instance_transform(i, hidden)
		mm.set_instance_color(i, Color.WHITE)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = bounds
	parent.add_child(mmi)
	return mmi


## Professor Hoot: the game's one owl (BlockyAnimal's body and turning head, the animals' warmed material) in his square
## teacher's cap (WeaponModels'), as W1's HootFlyer draws him; three draws, about 0.75 tall at `size` 1, facing +Z turned
## by `yaw` (the owl's model faces -Z). The lead fixed BlockyAnimal's winding (99f33b97): one owl model in the game.
static func hoot(parent: Node3D, at: Vector3, yaw: float = 0.0, size: float = 1.0) -> Node3D:
	var bird := Node3D.new()
	bird.name = "Hoot"
	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = BlockyAnimal.mesh_for(&"owl")
	bird.add_child(body)
	var head_mesh := BlockyAnimal.part_mesh_for(&"owl")
	if head_mesh != null:
		var head := MeshInstance3D.new()
		head.name = "Head"
		head.mesh = head_mesh
		head.position = BlockyAnimal.PART_PIVOT[&"owl"]
		bird.add_child(head)
	var cap := MeshInstance3D.new()
	cap.name = "Cap"
	cap.mesh = WeaponModels.build([[Vector3(0, 0.735, 0), Vector3(0.38, 0.04, 0.38), AcademyBuildings.CAP],
		[Vector3(0, 0.69, 0), Vector3(0.18, 0.08, 0.18), AcademyBuildings.CAP],
		[Vector3(0.16, 0.66, 0), Vector3(0.025, 0.15, 0.025), Color("ffcf3a")]])
	cap.material_override = WeaponModels.material()
	bird.add_child(cap)
	for m: Node in bird.get_children():
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bird.position = at
	bird.rotation.y = yaw + PI
	bird.scale = Vector3.ONE * size
	parent.add_child(bird)
	return bird


## A hidden instance (a MultiMesh slot not shown now).
static func hidden() -> Transform3D:
	return Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO)


## The place's Sun, warm, no shadows: the rooms' own LifeRoomSun (the rooms' look, 2026-10-17), the only light while
## the place shows (it puts the world's suns away and gives them back when the place goes). A Life room's is the room's
## own (LifeRoom.sun: the room makes no second one); any other place gets one of its own.
static func sun(parent: Node3D, pitch_deg: float, yaw_deg: float, colour: Color, energy: float) -> DirectionalLight3D:
	var l: LifeRoomSun
	if parent is LifeRoom:
		l = (parent as LifeRoom).sun(colour, energy, pitch_deg, yaw_deg)
	else:
		l = LifeRoomSun.new(colour, energy, pitch_deg, yaw_deg)
		parent.add_child(l)
	l.light_specular = 0.35
	return l


## The place's environment: a plain background (no sky shader), coloured ambient light, the worlds' filmic tone.
static func environment(background: Color, ambient: Color, ambient_energy: float) -> Environment:
	var env := LifeRoomKit.environment(background, background, ambient_energy)
	env.ambient_light_color = ambient
	env.set_meta(&"leaf_ambient", ambient)
	return env


## The leaf's own tone back on `env` after the rooms' look toned it for a daylight room (LifeRoomDecor.tone: its ACES
## exposure and blue-white ambient): the filmic tone, full exposure and the place's own ambient colour, as the leaf's
## pictures were made.
static func own_tone(env: Environment) -> void:
	if env == null:
		return
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.ambient_light_color = env.get_meta(&"leaf_ambient", env.ambient_light_color)


## Builds one merged surface from many primitives, each placed by a transform, in vertex colours.
class Mesher:
	extends RefCounted
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var i := PackedInt32Array()

	func count() -> int:
		return v.size()

	func _add(p: Vector3, normal: Vector3, colour: Color) -> int:
		v.append(p)
		n.append(normal)
		c.append(colour)
		return v.size() - 1

	func tri(a: int, b: int, d: int) -> void:
		i.append(a)
		i.append(b)
		i.append(d)

	## A grid of rows x cols vertices (already added in row order from `first`) joined into triangles.
	func _grid(first: int, rows: int, cols: int, flip: bool = false) -> void:
		for r in rows - 1:
			for k in cols - 1:
				var a := first + r * cols + k
				var b := a + 1
				var d := a + cols
				var e := d + 1
				if flip:
					tri(a, b, d)
					tri(b, e, d)
				else:
					tri(a, d, b)
					tri(b, d, e)

	## A ball (or an egg with `stretch`), lumpy by `lump` (0: round); its colour runs from `bottom` to `top`, with a
	## lighter rim on top (`sheen`).
	func ball(xf: Transform3D, radius: float, top: Color, bottom: Color, seg: int = 16, rings: int = 10,
			lump: float = 0.0, lump_seed: float = 0.0, sheen: float = 0.12) -> void:
		var first := v.size()
		for r in rings + 1:
			var phi := PI * r / rings
			for k in seg + 1:
				var theta := TAU * k / seg
				var dir := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
				var rr := radius * (1.0 + lump * _noise(dir, lump_seed))
				var p := dir * rr
				var col := bottom.lerp(top, (dir.y + 1.0) * 0.5)
				col = col.lerp(Color.WHITE, sheen * clampf(dir.y * 1.4 - 0.4, 0.0, 1.0))
				_add(xf * p, (xf.basis * dir).normalized(), col)
		_grid(first, rings + 1, seg + 1)
		if lump > 0.0:
			_smooth_normals(first, rings + 1, seg + 1, xf)

	## Recomputes a lumpy ball's normals from its own surface.
	func _smooth_normals(first: int, rows: int, cols: int, _xf: Transform3D) -> void:
		for r in rows:
			for k in cols:
				var at := first + r * cols + k
				var right := first + r * cols + (k + 1 if k + 1 < cols else 1)
				var left := first + r * cols + (k - 1 if k > 0 else cols - 2)
				var up := first + maxi(r - 1, 0) * cols + k
				var down := first + mini(r + 1, rows - 1) * cols + k
				var nn := (v[right] - v[left]).cross(v[down] - v[up])
				if nn.length() > 0.00001 and nn.dot(n[at]) > 0.0:
					n[at] = nn.normalized()

	static func _noise(dir: Vector3, s: float) -> float:
		return 0.5 * sin(dir.x * 3.1 + s) * sin(dir.y * 2.3 + s * 1.7) + 0.35 * sin(dir.z * 4.3 + s * 2.3) \
			* sin(dir.x * 2.1 - s) + 0.15 * sin(dir.y * 6.1 + dir.z * 5.3 + s * 3.1)

	## A capsule standing on y = 0 (height includes its round ends), colour from `bottom` to `top`.
	func capsule(xf: Transform3D, radius: float, height: float, top: Color, bottom: Color, seg: int = 14,
			cap_rings: int = 5) -> void:
		var first := v.size()
		var body := maxf(height - radius * 2.0, 0.0)
		var rows := 0
		for half in 2:
			for r in cap_rings + 1:
				var phi := PI * 0.5 * r / cap_rings if half == 0 else PI * 0.5 + PI * 0.5 * r / cap_rings
				var y_off := radius + body if half == 0 else radius
				for k in seg + 1:
					var theta := TAU * k / seg
					var dir := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
					var p := dir * radius + Vector3(0, y_off, 0)
					var col := bottom.lerp(top, clampf(p.y / maxf(height, 0.001), 0.0, 1.0))
					_add(xf * p, (xf.basis * dir).normalized(), col)
				rows += 1
		_grid(first, rows, seg + 1)

	## A tube from `a` to `b` (radius at each end), colours at each end; closed ends when `caps`.
	func tube(a: Vector3, b: Vector3, ra: float, rb: float, ca: Color, cb: Color, seg: int = 14, caps: bool = true) -> void:
		var axis := b - a
		if axis.length() < 0.0001:
			return
		var w := axis.normalized()
		var u := w.cross(Vector3.UP if absf(w.y) < 0.95 else Vector3.RIGHT).normalized()
		var t := w.cross(u)
		var first := v.size()
		for end in 2:
			var centre := a if end == 0 else b
			var r := ra if end == 0 else rb
			var col := ca if end == 0 else cb
			for k in seg + 1:
				var th := TAU * k / seg
				var dir := u * cos(th) + t * sin(th)
				_add(centre + dir * r, dir, col)
		for k in seg:
			var p0 := first + k
			var p1 := first + k + 1
			var q0 := first + seg + 1 + k
			var q1 := q0 + 1
			tri(p0, q0, p1)
			tri(p1, q0, q1)
		if caps:
			for end in 2:
				var centre := a if end == 0 else b
				var r := ra if end == 0 else rb
				var col := ca if end == 0 else cb
				var nn := -w if end == 0 else w
				var mid := _add(centre, nn, col)
				var ring := v.size()
				for k in seg + 1:
					var th := TAU * k / seg
					_add(centre + (u * cos(th) + t * sin(th)) * r, nn, col)
				for k in seg:
					if end == 0:
						tri(mid, ring + k, ring + k + 1)
					else:
						tri(mid, ring + k + 1, ring + k)

	## A box (each face one colour, the top lighter: `top`).
	func box(xf: Transform3D, size: Vector3, side: Color, top: Color) -> void:
		var h := size * 0.5
		var faces := [
			[Vector3.RIGHT, Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)],
			[Vector3.LEFT, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)],
			[Vector3.UP, Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)],
			[Vector3.DOWN, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)],
			[Vector3.BACK, Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)],
			[Vector3.FORWARD, Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)],
		]
		for f: Array in faces:
			var nn: Vector3 = xf.basis * (f[0] as Vector3)
			var col := top if (f[0] as Vector3) == Vector3.UP else side
			var base := v.size()
			for q in 4:
				var p: Vector3 = f[1 + q]
				_add(xf * p, nn.normalized(), col.lerp(side.darkened(0.15), 0.5 if p.y < 0.0 and col == side else 0.0))
			tri(base, base + 2, base + 1)
			tri(base, base + 3, base + 2)

	## A flat polygon (a disc of `seg` sides, or a hexagon with seg = 6) facing +Y, its middle `centre`, its edge `edge`.
	func disc(xf: Transform3D, radius: float, centre: Color, edge: Color, seg: int = 16, dome: float = 0.0) -> void:
		var nn := (xf.basis * Vector3.UP).normalized()
		var mid := _add(xf * Vector3(0, dome, 0), nn, centre)
		var ring := v.size()
		for k in seg + 1:
			var th := TAU * k / seg
			_add(xf * Vector3(cos(th) * radius, 0, sin(th) * radius), nn, edge)
		for k in seg:
			tri(mid, ring + k, ring + k + 1)

	## A hexagonal prism standing on y = 0: a lighter bevelled top, honey sides (a sugar, a paving cell).
	func hexagon(xf: Transform3D, radius: float, thick: float, top: Color, side: Color, bevel: float = 0.18) -> void:
		var inner := radius * (1.0 - bevel)
		var top_y := thick
		var bev_y := thick * 0.7
		var first := v.size()
		for k in 7:
			var th := TAU * k / 6.0 + PI / 6.0
			var dir := Vector3(cos(th), 0, sin(th))
			_add(xf * (dir * radius), (xf.basis * dir).normalized(), side.darkened(0.18))
			_add(xf * (dir * radius + Vector3(0, bev_y, 0)), (xf.basis * dir).normalized(), side)
		for k in 6:
			var a := first + k * 2
			var b := a + 2
			tri(a, b, a + 1)
			tri(b, b + 1, a + 1)
		var ring := v.size()
		for k in 7:
			var th := TAU * k / 6.0 + PI / 6.0
			var dir := Vector3(cos(th), 0, sin(th))
			var nn := (xf.basis * (dir + Vector3.UP).normalized()).normalized()
			_add(xf * (dir * radius + Vector3(0, bev_y, 0)), nn, side.lerp(top, 0.5))
			_add(xf * (dir * inner + Vector3(0, top_y, 0)), nn, top)
		for k in 6:
			var a := ring + k * 2
			var b := a + 2
			tri(a, b, a + 1)
			tri(b, b + 1, a + 1)
		var up := (xf.basis * Vector3.UP).normalized()
		var mid := _add(xf * Vector3(0, top_y, 0), up, top.lightened(0.25))
		var cap := v.size()
		for k in 7:
			var th := TAU * k / 6.0 + PI / 6.0
			_add(xf * (Vector3(cos(th), 0, sin(th)) * inner + Vector3(0, top_y, 0)), up, top)
		for k in 6:
			tri(mid, cap + k, cap + k + 1)

	## A bean (a guard cell): a sausage bent round +X, `length` long, `width` thick across, `height` tall above its
	## middle line (lifted by `lift`; below it down to `floor` x height), its belly on the -X side (where the pore is);
	## colour from `bottom` to `top`.
	func bean(xf: Transform3D, length: float, width: float, height: float, bend: float, top: Color, bottom: Color,
			seg: int = 14, rings: int = 18, lift: float = 0.0, floor_at: float = -0.25) -> void:
		var first := v.size()
		for r in rings + 1:
			var s := float(r) / rings
			var z := (s - 0.5) * length
			var fat := sin(PI * clampf(s, 0.0, 1.0))
			fat = pow(fat, 0.55)
			var cx := bend * (1.0 - pow((s - 0.5) * 2.0, 2.0))
			for k in seg + 1:
				var th := TAU * k / seg
				var dir := Vector3(cos(th), sin(th), 0)
				var p := Vector3(cx + dir.x * width * 0.5 * fat, lift + maxf(dir.y, floor_at) * height * fat, z)
				var nn := Vector3(dir.x / maxf(width, 0.01), dir.y / maxf(height, 0.01), 0).normalized()
				var col := bottom.lerp(top, clampf(((p.y - lift) / maxf(height, 0.001) + 0.6) / 1.6, 0.0, 1.0))
				_add(xf * p, (xf.basis * nn).normalized(), col)
		_grid(first, rings + 1, seg + 1)

	## A quad from `a` along `along` and `across` (a light's ray, a pane), colours at its two ends (alpha too).
	func quad(a: Vector3, along: Vector3, across: Vector3, ca: Color, cb: Color) -> void:
		var nn := along.cross(across).normalized()
		var p0 := _add(a - across * 0.5, nn, ca)
		var p1 := _add(a + across * 0.5, nn, ca)
		var p2 := _add(a + along + across * 0.5, nn, cb)
		var p3 := _add(a + along - across * 0.5, nn, cb)
		tri(p0, p1, p2)
		tri(p0, p2, p3)

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
