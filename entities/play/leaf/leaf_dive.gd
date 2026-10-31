class_name LeafDive
extends Node3D
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5 step 2, §3.11; picture 02-the-dive): Size Magic by tens, the
## dive's first version. Three sets, each a world at its own size: the leaf's top like a green field with its veins and a
## ladybird like a bus (x10), the leaf's hairs like glass trees over the skin's soft domes (x100), the skin's cells like
## paving with its doors like lips, a little mist at the open ones (x1,000). The last step (x85,000, a door as big as a
## gate) is the leaf's own place seen from under it (LeafPlace.UNDER). `pose(p)` (0 to 1) shows the set for the moment
## and gives its camera (`camera_transform`); B2 flies between them with a chime at each step (flat: the camera rushes
## down; VR: the world grows around the child's feet), B3 times it to the sparkle.

const STAGES := ["leaf", "hairs", "skin"]
const SCALES := [10, 100, 1000]
const LEAF_GREEN := Color("3f9a38")
const VEIN := Color("b0de86")
const LADYBIRD := Color("e23a2c")
const SPOT := Color("1c1a1a")
const SKIN := Color("cbe8ae")
const SKIN_GROOVE := Color("5c9b52")
const GUARD := Color("3fcf5c")
const HAIR := Color(0.92, 1.0, 0.86, 0.34)

var env: Environment
var sun: DirectionalLight3D
var stage := 0
## B2: built in steps over several frames (`build_step`), and whole yet.
var staged := false
var built := false
var _steps: Array[Callable] = []
var _sets: Array[Node3D] = []
var _views: Array = [[Vector3(-1.1, 0.75, 2.4), Vector3(0.5, 0.55, -1.2)],
	[Vector3(0.6, 1.2, 6.8), Vector3(-0.2, 3.4, -2.6)], [Vector3(-0.6, 2.4, 3.6), Vector3(-1.4, 0.0, -0.8)]]
var _mist: CPUParticles3D


func _init() -> void:
	name = "LeafDive"


func _ready() -> void:
	env = LeafKit.environment(Color("9fd6f2"), Color("e2f0da"), 0.62)
	sun = LeafKit.sun(self, -36.0, 74.0, Color("fff3d8"), 1.25)
	_steps = [_build_sky, func() -> void: _sets.append(_build_leaf()), func() -> void: _sets.append(_build_hairs()),
		func() -> void: _sets.append(_build_skin()), _finish_dive]
	if not staged:
		while not build_step():
			pass


func _finish_dive() -> void:
	built = true
	pose(0.0)


## B2: one more piece of the dive; true once it is whole (a `staged` dive, set before it enters the tree, builds only
## this way: the host spreads it over the garden's frames).
func build_step() -> bool:
	if _steps.is_empty():
		return true
	var step: Callable = _steps.pop_front()
	step.call()
	return _steps.is_empty()


## The dive at `p` (0: x10, 1: x1,000): the set for the moment.
func pose(p: float) -> void:
	if not built:
		return
	stage = clampi(roundi(clampf(p, 0.0, 1.0) * (STAGES.size() - 1)), 0, STAGES.size() - 1)
	for i in _sets.size():
		_sets[i].visible = i == stage
	if _mist:
		if _mist.emitting != (stage == 2):
			_mist.emitting = stage == 2


## The camera for the moment (this node's space, made global).
func camera_transform() -> Transform3D:
	var v: Array = _views[stage]
	var from := to_global(v[0])
	return Transform3D(Basis.looking_at(to_global(v[1]) - from, Vector3.UP), from)


func _build_sky() -> void:
	var m := LeafKit.Mesher.new()
	var first := m.count()
	for r in 11:
		var phi := PI * 0.6 * r / 10.0
		for k in 29:
			var th := TAU * k / 28.0
			var dir := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			m._add(dir * 36.0, -dir, Color("e8f6ff").lerp(Color("5cb2ee"), sqrt(maxf(dir.y, 0.0))))
	m._grid(first, 11, 29, true)
	LeafKit.mesh(self, "Sky", m.commit(), LeafKit.glow())


## x10: the leaf's top like a field: its veins raised in its own surface (a midrib and side veins branching forward),
## its little cells' sheen, and a ladybird like a bus.
func _build_leaf() -> Node3D:
	var set_node := Node3D.new()
	set_node.name = "Leaf"
	add_child(set_node)
	var m := LeafKit.Mesher.new()
	var first := m.count()
	var n := 56
	var step := 0.7
	for r in n + 1:
		for k in n + 1:
			var x := (k - n * 0.5) * step
			var z := (r - n * 0.5) * step
			var vein := _vein_at(x, z)
			var y := 0.12 * sin(x * 0.33) * cos(z * 0.27) - 0.0012 * (x * x + z * z) + 0.16 * vein
			var cells := 0.5 + 0.5 * sin(x * 3.1) * sin(z * 3.4)
			var col := LEAF_GREEN.lerp(LEAF_GREEN.lightened(0.1), cells * 0.35).lerp(VEIN, vein * 0.85)
			m._add(Vector3(x, y, z), Vector3.UP, col)
	m._grid(first, n + 1, n + 1, true)
	_normals_from_heights(m, first, n + 1)
	LeafKit.mesh(set_node, "Surface", m.commit(), LeafKit.lit())
	var bug := LeafKit.Mesher.new()
	var at := Vector3.ZERO
	bug.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.7, 1.15)), at + Vector3(0, 0.45, 0)), 1.0, LADYBIRD.lightened(0.18),
		LADYBIRD.darkened(0.3), 26, 14, 0.0, 0.0, 0.35)
	for sp: Array in [[0.46, 0.3], [-0.46, 0.3], [0.68, -0.38], [-0.68, -0.38], [0.0, 0.62], [0.5, 0.85], [-0.5, 0.85]]:
		var dir := Vector3(float(sp[0]), 0.0, float(sp[1]))
		dir.y = sqrt(maxf(1.0 - dir.x * dir.x - dir.z * dir.z / 1.3, 0.05))
		var p := at + Vector3(0, 0.45, 0) + Vector3(dir.x, dir.y * 0.7, dir.z * 1.15)
		var normal := (p - (at + Vector3(0, 0.45, 0))).normalized()
		bug.disc(Transform3D(LeafPlace._facing(normal), p + normal * 0.015), 0.19, SPOT, SPOT.lightened(0.1), 16, 0.03)
	bug.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.68, 0.8)), at + Vector3(0, 0.47, -1.12)), 0.5, SPOT.lightened(0.18),
		SPOT, 18, 10, 0.0, 0.0, 0.3)
	for side: float in [-1.0, 1.0]:
		bug.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.8, 0.6)), at + Vector3(side * 0.24, 0.6, -1.44)), 0.13, Color.WHITE,
			Color("dddddd"), 10, 6)
		bug.tube(at + Vector3(side * 0.14, 0.72, -1.48), at + Vector3(side * 0.44, 1.05, -1.95), 0.025, 0.015, SPOT, SPOT, 5)
		for k in 3:
			var hip := at + Vector3(side * 0.62, 0.24, -0.55 + k * 0.52)
			var knee := hip + Vector3(side * 0.36, 0.08, 0.0)
			bug.tube(hip, knee, 0.055, 0.045, SPOT, SPOT, 6)
			bug.tube(knee, knee + Vector3(side * 0.14, -0.34, 0.05), 0.045, 0.028, SPOT, SPOT, 6)
	var ladybird := LeafKit.mesh(set_node, "Ladybird", bug.commit(), LeafKit.lit())
	ladybird.position = Vector3(0.6, 0.04, -1.1)
	ladybird.rotation.y = 2.4   # turned three-quarters towards the eye
	return set_node


## How much of a vein is at (x, z) on the x10 leaf (0 none, 1 on its middle line): a midrib along z, side veins
## branching forward from it every 3 m.
static func _vein_at(x: float, z: float) -> float:
	var mid := clampf(1.0 - absf(x + 1.6 - z * 0.25) / 0.6, 0.0, 1.0)
	var side := 0.0
	var along := absf(x + 1.6 - z * 0.25)
	for k in range(-8, 9):
		var z0 := k * 3.0
		var zz := z - (z0 - along * 0.66)
		side = maxf(side, clampf(1.0 - absf(zz) / maxf(0.32 - along * 0.012, 0.08), 0.0, 1.0) * clampf(1.0 - along / 14.0, 0.0, 1.0))
	return maxf(mid, side * 0.8)


## Normals of a height grid from its own slopes (rows x rows vertices from `first`).
static func _normals_from_heights(m: LeafKit.Mesher, first: int, rows: int) -> void:
	for r in rows:
		for k in rows:
			var at := first + r * rows + k
			var right := first + r * rows + mini(k + 1, rows - 1)
			var left := first + r * rows + maxi(k - 1, 0)
			var down := first + mini(r + 1, rows - 1) * rows + k
			var up := first + maxi(r - 1, 0) * rows + k
			var nn := (m.v[down] - m.v[up]).cross(m.v[right] - m.v[left])
			if nn.length() > 0.00001:
				m.n[at] = nn.normalized() if nn.y > 0.0 else -nn.normalized()


## x100: leaf hairs like glass trees over the skin's soft domes: each hair three glassy cells, bulging a little, their
## joints brighter, on a pale foot.
func _build_hairs() -> Node3D:
	var set_node := Node3D.new()
	set_node.name = "Hairs"
	add_child(set_node)
	var ground := LeafKit.Mesher.new()
	ground.disc(Transform3D(Basis(), Vector3(0, -0.05, 0)), 24.0, SKIN_GROOVE, SKIN_GROOVE.darkened(0.2), 40)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	# The skin's cells: one ball, many times (a MultiMesh: built in a blink, still one draw), each its own green.
	var cell := LeafKit.Mesher.new()
	cell.ball(Transform3D(), 1.0, Color.WHITE, Color(0.84, 0.84, 0.84), 10, 5)
	var at: Array[Transform3D] = []
	var tint: Array[Color] = []
	for row in range(-14, 15):
		for col in range(-13, 14):
			var x := col * 1.3 + (0.65 if row % 2 != 0 else 0.0) + rng.randf_range(-0.15, 0.15)
			var z := row * 1.13 + rng.randf_range(-0.15, 0.15)
			if Vector2(x, z).length() > 22.0:
				continue
			var r := rng.randf_range(0.6, 0.72)
			at.append(Transform3D(Basis().scaled(Vector3(r, r * 0.36, r)), Vector3(x, 0.0, z)))
			tint.append(LEAF_GREEN.lightened(rng.randf_range(0.14, 0.3)))
	var cells := LeafKit.multimesh(set_node, "Cells", cell.commit(), LeafKit.lit(), at.size(),
		AABB(Vector3(-24, -1, -24), Vector3(48, 3, 48)))
	for i in at.size():
		cells.multimesh.set_instance_transform(i, at[i])
		cells.multimesh.set_instance_color(i, tint[i])
	var hairs := LeafKit.Mesher.new()
	for h: Array in [[-1.4, -1.2, 5.6], [2.2, -3.0, 6.4], [-3.8, -4.6, 5.0], [4.2, 0.2, 4.4], [0.4, -6.8, 6.0],
			[-5.8, 0.4, 4.2], [6.2, -5.4, 5.4], [-0.4, 2.2, 3.4], [-7.6, -6.0, 4.8], [8.0, -1.8, 4.0]]:
		var base := Vector3(h[0], 0.12, h[1])
		var tall := float(h[2])
		ground.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.55, 1.0)), base), 0.72, Color("e2f7c4"), Color("aedb92"), 12, 6)
		var lean := Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35))
		var a := base
		for seg in 3:
			var f := float(seg + 1) / 3.0
			var b := base + Vector3(0, tall * f, 0) + lean * f * f * tall * 0.45
			var ra := 0.4 * (1.0 - float(seg) / 3.2) + 0.05
			var rb := 0.4 * (1.0 - f) + 0.02
			var mid := a.lerp(b, 0.5)
			hairs.tube(a, mid, ra, (ra + rb) * 0.56, HAIR, Color(HAIR, 0.3), 16, false)
			hairs.tube(mid, b, (ra + rb) * 0.56, rb, Color(HAIR, 0.3), HAIR, 16, false)
			if seg < 2:
				hairs.tube(b - (b - a).normalized() * 0.04, b + (b - a).normalized() * 0.04, rb + 0.03, rb + 0.03,
					Color(1, 1, 1, 0.62), Color(1, 1, 1, 0.62), 16, true)
			a = b
	LeafKit.mesh(set_node, "Skin", ground.commit(), LeafKit.lit())
	LeafKit.mesh(set_node, "Hairs", hairs.commit(), LeafKit.glass())
	return set_node


## A jigsaw cell of the leaf's skin (its wavy edge locks into its neighbours'), domed.
static func _jigsaw(m: LeafKit.Mesher, at: Vector3, radius: float, rng: RandomNumberGenerator, top: Color) -> void:
	var ring := PackedVector3Array()
	var lobes := rng.randi_range(5, 7)
	var phase := rng.randf_range(0.0, TAU)
	for k in 28:
		var th := TAU * k / 28.0
		var r := radius * (0.9 + 0.12 * sin(th * lobes + phase))
		ring.append(Vector3(cos(th) * r, 0, sin(th) * r))
	LeafPlace._polygon(m, at, ring, 0.93, top.lightened(0.1), top.darkened(0.06), rng.randf_range(0.1, 0.18), true)


## x1,000: the skin's cells like paving, its doors like lips (two green guard cells round a dark slit).
func _build_skin() -> Node3D:
	var set_node := Node3D.new()
	set_node.name = "SkinCells"
	add_child(set_node)
	var m := LeafKit.Mesher.new()
	m.disc(Transform3D(Basis(), Vector3(0, -0.04, 0)), 20.0, SKIN_GROOVE, SKIN_GROOVE.darkened(0.2), 40)
	var doors := [Vector3(-2.4, 0, -0.6), Vector3(2.2, 0, -2.4), Vector3(0.4, 0, 2.2), Vector3(-4.6, 0, -4.0),
		Vector3(4.8, 0, 1.6)]
	var rng := RandomNumberGenerator.new()
	rng.seed = 63
	for row in range(-8, 9):
		for col in range(-7, 8):
			var x := col * 2.2 + (1.1 if row % 2 != 0 else 0.0) + rng.randf_range(-0.35, 0.35)
			var z := row * 1.8 + rng.randf_range(-0.3, 0.3)
			if Vector2(x, z).length() > 18.0:
				continue
			var near := false
			for d: Vector3 in doors:
				if Vector2(x - d.x, z - d.z).length() < 1.25:
					near = true
			if near:
				continue
			var shade := rng.randf_range(-0.05, 0.06)
			var top := SKIN.lightened(maxf(shade, 0.0)).darkened(maxf(-shade, 0.0))
			_jigsaw(m, Vector3(x, 0, z), 1.12, rng, top)
	var slits := LeafKit.Mesher.new()
	var mist_points := PackedVector3Array()
	for d: Vector3 in doors:   # each door's ring of little cells
		for k in 8:
			var th := TAU * k / 8.0
			_jigsaw(m, d + Vector3(cos(th) * 1.25, 0, sin(th) * 0.95), 0.42, rng, SKIN.lightened(0.08))
	for k in doors.size():
		var at: Vector3 = doors[k]
		var yaw := rng.randf_range(-0.6, 0.6)
		var open := k % 2 == 0
		var basis := Basis(Vector3.UP, yaw)
		var side := basis * Vector3.RIGHT
		var gap := 0.3 if open else 0.22
		m.bean(Transform3D(basis.scaled(Vector3(0.62, 0.62, 0.62)), at + side * gap), 2.3, 0.8, 0.62, 0.16,
			GUARD.lightened(0.12), GUARD.darkened(0.15))
		m.bean(Transform3D((basis * Basis(Vector3.UP, PI)).scaled(Vector3(0.62, 0.62, 0.62)), at - side * gap), 2.3, 0.8,
			0.62, 0.16, GUARD.lightened(0.12), GUARD.darkened(0.15))
		slits.ball(Transform3D(basis * Basis.from_scale(Vector3(0.22 if open else 0.03, 0.12, 0.55)), at + Vector3(0, 0.02, 0)),
			1.0, Color("16473b"), Color("0a2a24"), 14, 6)
		if open:
			mist_points.append(at + Vector3(0, 0.15, 0))
	LeafKit.mesh(set_node, "Paving", m.commit(), LeafKit.lit())
	LeafKit.mesh(set_node, "Slits", slits.commit(), LeafKit.glow())
	var mm := LeafKit.Mesher.new()
	mm.ball(Transform3D(), 0.12, Color.WHITE, Color(0.88, 0.95, 1.0), 8, 4)
	var mesh := mm.commit()
	mesh.surface_set_material(0, LeafKit.glow())
	_mist = CPUParticles3D.new()
	_mist.name = "Mist"
	_mist.mesh = mesh
	_mist.amount = 24
	_mist.lifetime = 2.2
	_mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS
	_mist.emission_points = mist_points
	_mist.direction = Vector3(0, 1, 0)
	_mist.spread = 25.0
	_mist.initial_velocity_min = 0.2
	_mist.initial_velocity_max = 0.5
	_mist.gravity = Vector3(0, 0.05, 0)
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.3))
	curve.add_point(Vector2(0.4, 1.0))
	curve.add_point(Vector2(1, 0))
	_mist.scale_amount_curve = curve
	_mist.color = Color("e2f5ff")
	_mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_node.add_child(_mist)
	return set_node
