class_name SkyRoom
extends AltarRoom
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5b, §3.11, §4.3): the Sky Room, the transfer room through the
## great door. A round white platform floating high above a sea of clouds in a bright blue sky, six altars on cloud
## plinths round its middle (each with the gem bag, the bowls and the balloon pump), coral balloons bobbing on gold
## posts round its rim, and far off on its own cloud the Mirror Halls glinting (next year's wing). B1's first dressing;
## the clouds parting and the Glimmers' flight are B3's.
##
## Drawn as: the sky dome, the platform (one lit mesh), its glow (the far halls, the inlays' shine), the clouds (one
## MultiMesh of puffs), the rim's balloons and strings (two MultiMeshes), the ring's two MultiMeshes, the active altar,
## Hoot.

const RADIUS := 6.0
const RING_R := 4.0
const POSTS := 8
const SKY := Color("8cc4f6")

var _clouds: MultiMeshInstance3D
var _balloons: MultiMeshInstance3D
var _strings: MultiMeshInstance3D


func build() -> void:
	env = AltarKit.environment(SKY, Color(0.86, 0.92, 1.0), 0.4)
	exposure = 1.0
	AltarKit.sun_for(self, -52.0, -20.0, Color(1.0, 0.96, 0.88), 0.72)
	AltarKit.mesh(self, "SkyDome", AltarKit.sky_dome(60.0, [[90, Color("2c5fc2")], [55, Color("4884da")],
		[28, Color("74aceb")], [10, Color("acd3f5")], [1, Color("dcedfb")], [-2, Color("f2f7ff")], [-12, Color("d9e4f6")],
		[-90, Color("b3c6e6")]]), AltarKit.glow())
	var lit := AltarKit.Mesher.new()
	var glow := AltarKit.Mesher.new()
	_platform(lit)
	_far_halls(glow)
	AltarKit.mesh(self, "Platform", lit.commit(), AltarKit.lit())
	AltarKit.mesh(self, "Far", glow.commit(), AltarKit.glow())
	_cloud_sea()
	_rim_balloons()
	room_tools = AltarHalls.tools("sky")
	build_ring(6, RING_R, "bird")
	add_view(ALTAR_VIEW, Vector3(0, 1.12, RING_R + 0.98), Vector3(0, 0.6, RING_R - 0.02), Vector3(0, 0, RING_R + 0.5), 0.0)
	add_view("wide", Vector3(3.2, 2.1, 9.6), Vector3(0.0, 0.9, 0.0))
	start_view = ALTAR_VIEW


## The platform: white stone, a gold rim, sky-blue inlays and a gold compass star, a gentle underside into the clouds.
func _platform(m: AltarKit.Mesher) -> void:
	var stone := Color("eceef2")
	var blue := Color("a9d2f0")
	var gold := BalanceAltar.GOLD
	m.disc(Transform3D(), RADIUS, stone, stone, 48)
	var pale := Color("e4edf5")
	var rings: Array[Vector2] = []
	var cols: Array[Color] = []
	# Sharp bands (each edge two points): the gold rim, white stone, a sky-blue band, the altars' gold ring, pale stone,
	# a gold ring round the compass star.
	for band: Array in [[RADIUS - 0.02, RADIUS - 0.18, gold], [RADIUS - 0.2, RADIUS - 0.6, stone], [RADIUS - 0.62, RING_R + 0.9, blue],
			[RING_R + 0.88, RING_R + 0.8, gold], [RING_R + 0.78, 2.42, pale], [2.4, 2.3, gold], [2.28, 0.0, pale.lightened(0.04)]]:
		rings.append(Vector2(float(band[0]), 0.004))
		rings.append(Vector2(float(band[1]), 0.004))
		cols.append(band[2])
		cols.append(band[2])
	m.lathe(Transform3D(), rings, cols, 64)
	m.lathe(Transform3D(), [Vector2(0.0, -1.9), Vector2(2.6, -1.5), Vector2(5.3, -0.62), Vector2(RADIUS, -0.34),
		Vector2(RADIUS, -0.04), Vector2(RADIUS - 0.01, 0.0)] as Array[Vector2],
		[Color("dfe3ec"), Color("e8eaf0"), Color("f0eee8"), gold.darkened(0.15), BalanceAltar.GOLD_TOP, stone] as Array[Color], 64)
	for i in 16:
		var th := TAU * i / 16.0
		var dir := Vector3(sin(th), 0, cos(th))
		var side := Vector3(dir.z, 0, -dir.x)
		var length := 1.9 if i % 2 == 0 else 1.2
		var a := m.add(Vector3(0, 0.008, 0) + side * 0.18, Vector3.UP, gold.lightened(0.1))
		var b := m.add(Vector3(0, 0.008, 0) - side * 0.18, Vector3.UP, gold.darkened(0.08))
		var c := m.add(dir * length + Vector3(0, 0.008, 0), Vector3.UP, BalanceAltar.GOLD_TOP)
		m.tri(a, b, c)
	for i in POSTS:
		var th := TAU * (i + 0.5) / POSTS
		var at := Vector3(sin(th), 0, cos(th)) * (RADIUS - 0.4)
		m.lathe(Transform3D(Basis(), at), [Vector2(0.12, 0.0), Vector2(0.1, 0.06), Vector2(0.045, 0.1), Vector2(0.04, 0.95),
			Vector2(0.07, 1.0), Vector2(0.0, 1.04)] as Array[Vector2],
			[gold.darkened(0.2), gold, stone, stone, gold, BalanceAltar.GOLD_TOP] as Array[Color], 14)


## Far off on a cloud of its own: the Mirror Halls, a small bright temple whose mirrors glint (next year's wing).
func _far_halls(m: AltarKit.Mesher) -> void:
	var at := Vector3(-30.0, 3.0, -44.0)
	var face := (Vector3(0, 1.2, RING_R + 1.2) - at)
	face.y = 0.0
	var yaw := atan2(face.x, face.z)
	var xf := Transform3D(Basis(Vector3.UP, yaw), at)
	var haze := Color("c4d3f2")
	var lit := Color("dfe8fb")
	m.box(xf * Transform3D(Basis(), Vector3(0, 0.6, 0)), Vector3(6.0, 1.2, 3.0), haze, lit, 0.05, haze)
	for c in 5:
		m.box(xf * Transform3D(Basis(), Vector3(-2.4 + c * 1.2, 2.2, 1.2)), Vector3(0.42, 2.2, 0.42), lit, lit, 0.05, haze)
	m.box(xf * Transform3D(Basis(), Vector3(0, 3.5, 0)), Vector3(6.4, 0.5, 3.2), haze, lit, 0.05, haze)
	m.lathe(xf * Transform3D(Basis(), Vector3(0, 3.75, -0.3)), [Vector2(1.7, 0.0), Vector2(1.5, 0.9), Vector2(0.9, 1.6), Vector2(0.0, 1.9)]
		as Array[Vector2], [haze, lit, Color("eef3ff"), Color("ffffff")] as Array[Color], 20)
	# The mirrors' glint: a bright silver diamond on the hall's face.
	m.box(xf * Transform3D(Basis(Vector3.BACK, PI * 0.25), Vector3(0, 2.2, 1.5)), Vector3(0.55, 0.55, 0.05), Color("ffffff"),
		Color("ffffff"), 0.0, Color("ffffff"))


## A sea of clouds below, a bank round the platform's foot, a cloud plinth under each altar of the ring, and soft
## clouds in the far sky: puffs of one MultiMesh, tinted by height.
func _cloud_sea() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	var puffs: Array[Array] = []   # [centre, size (x, y, z)]
	for i in 70:
		var a := rng.randf() * TAU
		var r := rng.randf_range(4.5, 9.0)
		puffs.append([Vector3(sin(a) * r, rng.randf_range(-2.6, -1.2), cos(a) * r), Vector3.ONE * rng.randf_range(1.4, 2.6) * Vector3(1.3, 0.6, 1.3)])
	for i in 60:
		var a := rng.randf() * TAU
		var r := rng.randf_range(14.0, 48.0)
		puffs.append([Vector3(sin(a) * r, rng.randf_range(-9.0, -5.0), cos(a) * r), Vector3.ONE * rng.randf_range(4.0, 8.0) * Vector3(1.4, 0.45, 1.4)])
	for i in 18:
		var a := rng.randf() * TAU
		var r := rng.randf_range(26.0, 50.0)
		var y := rng.randf_range(4.0, 14.0)
		for p in 4:
			puffs.append([Vector3(sin(a) * r, y, cos(a) * r) + Vector3(rng.randf_range(-3, 3), rng.randf_range(-0.6, 0.6),
				rng.randf_range(-3, 3)), Vector3.ONE * rng.randf_range(1.6, 3.0) * Vector3(1.4, 0.7, 1.4)])
	for p in 9:
		puffs.append([Vector3(-30.0, 2.4, -44.0) + Vector3(rng.randf_range(-4.5, 4.5), rng.randf_range(-0.8, 0.2),
			rng.randf_range(-2.5, 2.5)), Vector3.ONE * rng.randf_range(1.6, 2.6) * Vector3(1.4, 0.55, 1.2)])
	for s in 6:
		var th := TAU * s / 6.0
		var base := Vector3(sin(th), 0, cos(th)) * RING_R
		for p in 5:
			var off := Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(-0.35, -0.15), rng.randf_range(-0.55, 0.55))
			puffs.append([base + off, Vector3.ONE * rng.randf_range(0.42, 0.62) * Vector3(1.3, 0.55, 1.2)])
	var box := AABB(Vector3(-60, -15, -60), Vector3(120, 35, 120))
	_clouds = AltarKit.multimesh(self, "Clouds", AltarKit.cloud_puff(), AltarKit.glow(), puffs.size(), box)
	for i in puffs.size():
		var p: Array = puffs[i]
		var at: Vector3 = p[0]
		_clouds.multimesh.set_instance_transform(i, Transform3D(Basis().scaled(p[1]), at))
		var warm := clampf((at.y + 9.0) / 22.0, 0.0, 1.0)
		_clouds.multimesh.set_instance_color(i, Color(0.93, 0.95, 1.0).lerp(Color(1.0, 1.0, 1.0), warm))


## Coral balloons bobbing on strings tied to the gold posts round the rim.
func _rim_balloons() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var per := 4
	var box := AABB(Vector3(-8, -1, -8), Vector3(16, 6, 16))
	_balloons = AltarKit.multimesh(self, "RimBalloons", BalanceAltar.balloon_mesh(), AltarKit.shiny(), POSTS * per, box)
	_strings = AltarKit.multimesh(self, "RimStrings", BalanceAltar.string_mesh(), AltarKit.lit(), POSTS * per, box)
	for i in POSTS:
		var th := TAU * (i + 0.5) / POSTS
		var post := Vector3(sin(th), 0, cos(th)) * (RADIUS - 0.4) + Vector3(0, 1.02, 0)
		for b in per:
			var k := i * per + b
			var at := post + Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(0.9, 1.5), rng.randf_range(-0.35, 0.35))
			_balloons.multimesh.set_instance_transform(k, Transform3D(Basis().scaled(Vector3.ONE * 3.2), at))
			_balloons.multimesh.set_instance_color(k, Color.WHITE if b % 3 != 2 else Color(1.0, 0.86, 0.6))
			var d := (at - Vector3(0, 0.2, 0)) - post
			var y := d.normalized()
			var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
			_strings.multimesh.set_instance_transform(k, Transform3D(Basis(x, y * d.length(), x.cross(y)), post))
