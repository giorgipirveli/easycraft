class_name TempleArrival
extends AltarRoom
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5 step 1, §3.7's minute 1, §3.11; picture 01): the arrival.
## The Sky Temple floats on a bank of clouds at sunset: a round hall of white stone under a dome with a gold oculus, a
## portico of six columns and a pediment carrying the temple's emblem (a gold ring and the equals sign's two bars), the
## great front door (it opens by itself for a new Keeper), and a stair of clouds down to where the child arrives.
## Gold gems drift in the warm air. B1's first version: the glide up the stair and the door's swing are B2's and B3's.
##
## Drawn as: the sky dome, the sun's glow, the temple (one lit mesh), its glow (the light inside the door, the
## lantern), the door, the clouds (one MultiMesh), the drifting gems (one MultiMesh), Hoot.

const DRUM := 8.4
const DRUM_H := 8.4
const PORTICO_Z := 11.2
const DOOR_W := 2.6
const DOOR_H := 4.4

var _door: MeshInstance3D
var _inside: MeshInstance3D
var _door_open := false


func build() -> void:
	env = AltarKit.environment(Color("3a3470"), Color(1.0, 0.84, 0.8), 0.46)
	exposure = 1.0
	AltarKit.sun_for(self, -24.0, -32.0, Color(1.0, 0.8, 0.6), 0.95)
	AltarKit.mesh(self, "SkyDome", AltarKit.sky_dome(90.0, [[90, Color("232c66")], [62, Color("373e8c")], [40, Color("6a58ab")],
		[22, Color("c46f9e")], [11, Color("ff8f7c")], [4, Color("ffbf86")], [0, Color("ffe0a2")], [-2, Color("fbd0b8")],
		[-14, Color("d4b4d4")], [-90, Color("8a82c0")]]), AltarKit.glow())
	var glass := AltarKit.Mesher.new()
	var sun_at := Vector3(-46.0, 5.0, -70.0)
	AltarKit.halo(glass, sun_at, Vector3(0, 0.0, 1).normalized(), 26.0, Color(1.0, 0.82, 0.55, 0.55))
	AltarKit.halo(glass, sun_at, Vector3(0, 0.0, 1), 7.0, Color(1.0, 0.95, 0.8, 1.0))
	AltarKit.mesh(self, "Sun", glass.commit(), AltarKit.glass())
	var lit := AltarKit.Mesher.new()
	var glow := AltarKit.Mesher.new()
	_temple(lit, glow)
	_wisps(glow)
	AltarKit.mesh(self, "Temple", lit.commit(), AltarKit.lit())
	AltarKit.mesh(self, "TempleGlow", glow.commit(), AltarKit.glow())
	_door = AltarKit.mesh(self, "Door", ArrayMesh.new(), AltarKit.lit())
	var inside := AltarKit.Mesher.new()
	_inside_light(inside)
	_inside = AltarKit.mesh(self, "Inside", inside.commit(), AltarKit.glow())
	set_door_open(false)
	_clouds()
	_gems()
	_hoot = AltarKit.hoot(self, Vector3(-2.3, 1.0, DRUM + 1.6), 0.25, 1.0)
	add_view("foot", Vector3(0.0, 3.4, 28.0), Vector3(0.0, 7.4, 0.0))
	add_view("door", Vector3(0.6, 2.2, 17.0), Vector3(0.0, 3.0, DRUM))
	start_view = "foot"


func set_door_open(open: bool) -> void:
	_door_open = open
	var m := AltarKit.Mesher.new()
	var wood := Color("8f5b34")
	var gold := BalanceAltar.GOLD
	for sx: float in [-1.0, 1.0]:
		var hinge := Transform3D(Basis(Vector3.UP, sx * -1.25 if open else 0.0), Vector3(sx * DOOR_W * 0.5, 1.0, DRUM + 0.12))
		var w := DOOR_W * 0.5
		m.box(hinge * Transform3D(Basis(), Vector3(-sx * w * 0.5, DOOR_H * 0.5, 0.06)), Vector3(w - 0.02, DOOR_H, 0.12), wood,
			wood.lightened(0.12), 0.25)
		for y: float in [0.5, DOOR_H * 0.5, DOOR_H - 0.5]:
			m.box(hinge * Transform3D(Basis(), Vector3(-sx * w * 0.5, y, 0.13)), Vector3(w - 0.08, 0.08, 0.02), gold,
				BalanceAltar.GOLD_TOP, 0.05)
		m.torus(hinge * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-sx * (w - 0.18), DOOR_H * 0.45, 0.15)), 0.1, 0.016,
			BalanceAltar.GOLD_TOP, gold, 20, 5)
	_door.mesh = m.commit()
	_inside.visible = open


func door_open() -> bool:
	return _door_open


## The round hall seen from outside: steps, the drum, its pilasters and windows, the dome with gold ribs and the oculus's
## lantern, the portico's six columns, the entablature with its gold frieze, the pediment and its emblem, the door's frame.
func _temple(m: AltarKit.Mesher, glow: AltarKit.Mesher) -> void:
	var stone := Color("f4ede1")
	var gold := BalanceAltar.GOLD
	var gold_top := BalanceAltar.GOLD_TOP
	# The base: a round podium under the drum and the portico's steps down to the clouds.
	m.lathe(Transform3D(), [Vector2(0.0, -1.4), Vector2(DRUM + 1.2, -1.4), Vector2(DRUM + 1.2, 0.6), Vector2(DRUM + 1.0, 0.8),
		Vector2(DRUM + 1.0, 1.0), Vector2(0.0, 1.0)] as Array[Vector2],
		[stone.darkened(0.3), stone.darkened(0.25), stone.darkened(0.05), gold, gold_top, stone] as Array[Color], 64)
	for s in 5:
		var y := 1.0 - s * 0.48
		var z := PORTICO_Z + 1.6 + s * 0.62
		m.box(Transform3D(Basis(), Vector3(0, y - 0.24, (PORTICO_Z - 2.0 + z) * 0.5)), Vector3(13.6 + s * 0.6, 0.48, z - PORTICO_Z + 2.0),
			stone.darkened(0.06), stone.lightened(0.04), 0.18)
	m.box(Transform3D(Basis(), Vector3(0, 0.5, (DRUM + PORTICO_Z + 1.6) * 0.5)), Vector3(13.6, 1.0, PORTICO_Z + 1.6 - DRUM + 1.0),
		stone.darkened(0.04), stone.lightened(0.05), 0.15)
	# The drum: white stone, darker at its foot, a gold band and cornice at its top, pilasters and windows.
	m.lathe(Transform3D(), [Vector2(DRUM, 1.0), Vector2(DRUM, 2.2), Vector2(DRUM, DRUM_H - 0.6), Vector2(DRUM, DRUM_H)] as Array[Vector2],
		[stone.darkened(0.16), stone.darkened(0.04), stone, stone.lightened(0.04)] as Array[Color], 64)
	m.lathe(Transform3D(), [Vector2(DRUM - 0.02, DRUM_H), Vector2(DRUM + 0.3, DRUM_H + 0.12), Vector2(DRUM + 0.3, DRUM_H + 0.4),
		Vector2(DRUM + 0.45, DRUM_H + 0.5), Vector2(DRUM + 0.45, DRUM_H + 0.62), Vector2(DRUM - 0.3, DRUM_H + 0.62)] as Array[Vector2],
		[stone.darkened(0.1), gold, gold_top, stone, stone.lightened(0.05), stone] as Array[Color], 64)
	for i in 16:
		var th := TAU * (i + 0.5) / 16.0
		var out := Vector3(sin(th), 0, cos(th))
		m.box(Transform3D(Basis(Vector3.UP, th), out * (DRUM + 0.12) + Vector3(0, (1.0 + DRUM_H) * 0.5, 0)),
			Vector3(0.5, DRUM_H - 1.0, 0.26), stone.lightened(0.02), stone.lightened(0.06), 0.12)
		if absf(wrapf(th, -PI, PI)) < 0.5:
			continue
		var wth := TAU * i / 16.0
		var wout := Vector3(sin(wth), 0, cos(wth))
		var across := Vector3(wout.z, 0, -wout.x)
		var c := wout * (DRUM + 0.02) + Vector3(0, 3.6, 0)
		glow.panel(c - across * 0.5 + Vector3(0, -1.2, 0), c + across * 0.5 + Vector3(0, -1.2, 0), c + across * 0.5 + Vector3(0, 1.2, 0),
			c - across * 0.5 + Vector3(0, 1.2, 0), wout, Color("ffcf8a"), Color("ffcf8a"), Color("ffe8b8"), Color("ffe8b8"))
		m.box(Transform3D(Basis(Vector3.UP, wth), c + Vector3(0, 1.32, 0) + wout * 0.06), Vector3(1.2, 0.14, 0.14), gold, gold_top, 0.05)
		m.box(Transform3D(Basis(Vector3.UP, wth), c + Vector3(0, -1.3, 0) + wout * 0.06), Vector3(1.2, 0.1, 0.18), gold, gold_top, 0.05)
		# A round window in the attic above (the hall's dome begins behind it).
		var o := wout * (DRUM + 0.03) + Vector3(0, 7.1, 0)
		glow.lathe(Transform3D(AltarKit.facing(wout), o), [Vector2(0.42, 0.0), Vector2(0.0, 0.0)] as Array[Vector2],
			[Color("ffcf8a"), Color("fff0cc")] as Array[Color], 18)
		m.torus(Transform3D(AltarKit.facing(wout), o + wout * 0.02), 0.45, 0.05, gold_top, gold, 20, 5)
	# A gold band where the hall's cornice is inside.
	m.lathe(Transform3D(), [Vector2(DRUM + 0.02, 6.1), Vector2(DRUM + 0.12, 6.16), Vector2(DRUM + 0.12, 6.34),
		Vector2(DRUM + 0.02, 6.4)] as Array[Vector2], [gold.darkened(0.1), gold, gold_top, gold] as Array[Color], 64)
	# The dome: white with gold ribs, the oculus's gold lantern on top.
	var profile: Array[Vector2] = []
	var cols: Array[Color] = []
	for r in 13:
		var phi := deg_to_rad(80.0) * r / 12.0
		profile.append(Vector2((DRUM - 0.3) * cos(phi), DRUM_H + 0.62 + 7.6 * sin(phi)))
		cols.append(Color("f7f2ea").lerp(Color("ffffff"), float(r) / 12.0).darkened(0.04 if r % 2 == 1 else 0.0))
	m.lathe(Transform3D(), profile, cols, 64)
	for i in 16:
		var th := TAU * i / 16.0
		var prev := Vector3.ZERO
		for r in 13:
			var p := Vector3(sin(th) * (profile[r].x + 0.05), profile[r].y + 0.02, cos(th) * (profile[r].x + 0.05))
			if r > 0:
				m.tube(prev, p, 0.07, gold, gold_top, 6)
			prev = p
	var top := profile[12]
	m.lathe(Transform3D(Basis(), Vector3(0, top.y, 0)), [Vector2(top.x + 0.1, -0.05), Vector2(top.x + 0.1, 0.35),
		Vector2(top.x - 0.1, 0.45), Vector2(0.9, 0.45), Vector2(0.9, 1.3), Vector2(0.5, 1.6), Vector2(0.15, 1.9),
		Vector2(0.0, 2.3)] as Array[Vector2], [gold, gold_top, gold, gold, gold_top, gold, gold_top, gold_top] as Array[Color], 24)
	glow.lathe(Transform3D(Basis(), Vector3(0, top.y + 0.45, 0)), [Vector2(0.92, 0.0), Vector2(0.92, 0.85)] as Array[Vector2],
		[Color("ffd890"), Color("fff0c8")] as Array[Color], 24, false, false, 0.0, 0.0, 8)
	# The portico: six columns, the entablature with a gold frieze, the pediment and the emblem.
	for c in 6:
		var x := -5.0 + c * 2.0
		AltarKit.column(m, Vector3(x, 1.0, PORTICO_Z), 5.6, 0.28, stone)
	for c in 2:
		var x := -5.0 + c * 10.0
		AltarKit.column(m, Vector3(x, 1.0, PORTICO_Z - 2.2), 5.6, 0.28, stone)
	var ent_y := 1.0 + 5.6
	m.box(Transform3D(Basis(), Vector3(0, ent_y + 0.25, PORTICO_Z - 1.4)), Vector3(12.0, 0.5, 4.0), stone, stone.lightened(0.05),
		0.1, Color("e6d8c0"))
	# The portico's coffered ceiling: gold-edged beams across it.
	for b in 7:
		var bx := -4.5 + b * 1.5
		m.box(Transform3D(Basis(), Vector3(bx, ent_y - 0.06, PORTICO_Z - 1.4)), Vector3(0.16, 0.12, 3.9), Color("efe3cc"),
			stone, 0.0, gold)
	for z: float in [PORTICO_Z - 2.6, PORTICO_Z - 1.4, PORTICO_Z - 0.2]:
		m.box(Transform3D(Basis(), Vector3(0, ent_y - 0.05, z)), Vector3(11.8, 0.1, 0.14), Color("efe3cc"), stone, 0.0, gold)
	m.box(Transform3D(Basis(), Vector3(0, ent_y + 0.72, PORTICO_Z - 1.4)), Vector3(12.0, 0.44, 4.0), gold, gold_top, 0.1)
	m.box(Transform3D(Basis(), Vector3(0, ent_y + 1.06, PORTICO_Z - 1.4)), Vector3(12.5, 0.24, 4.3), stone, stone.lightened(0.06))
	var py := ent_y + 1.18
	var pz := PORTICO_Z + 0.75
	var peak := Vector3(0, py + 2.1, pz)
	var left := Vector3(-6.25, py, pz)
	var right := Vector3(6.25, py, pz)
	var tri_col := stone.lightened(0.03)
	var a := m.add(left, Vector3.BACK, tri_col)
	var b := m.add(right, Vector3.BACK, tri_col)
	var d := m.add(peak, Vector3.BACK, stone.lightened(0.07))
	m.tri(a, b, d)
	for sx: float in [-1.0, 1.0]:
		var p0 := Vector3(sx * 6.45, py, pz + 0.1)
		var p1 := Vector3(0, py + 2.25, pz + 0.1)
		m.tube(p0, p1, 0.16, stone.lightened(0.04), stone.lightened(0.08), 8)
		var roof := Vector3(sx * 6.45, py, PORTICO_Z - 3.4)
		m.panel(p0, Vector3(0, py + 2.25, pz + 0.1), Vector3(0, py + 2.25, PORTICO_Z - 3.4), roof,
			(Vector3(sx * 2.25, 6.45, 0)).normalized(), Color("e9d9c0"), Color("efe2cc"), Color("efe2cc"), Color("e9d9c0"))
	m.tube(Vector3(-6.45, py, pz + 0.1), Vector3(6.45, py, pz + 0.1), 0.12, gold, gold_top, 8)
	var face := Basis(Vector3.RIGHT, PI * 0.5)
	var centre := Vector3(0, py + 0.85, pz + 0.08)
	m.torus(Transform3D(face, centre), 0.72, 0.07, gold_top, gold, 36, 6)
	for y: float in [0.17, -0.17]:
		m.box(Transform3D(Basis(), centre + Vector3(0, y, 0.04)), Vector3(0.86, 0.16, 0.08), gold, gold_top, 0.05)
	# The door's frame in the drum.
	for sx: float in [-1.0, 1.0]:
		m.box(Transform3D(Basis(), Vector3(sx * (DOOR_W * 0.5 + 0.2), 1.0 + DOOR_H * 0.5 + 0.2, DRUM + 0.18)), Vector3(0.4, DOOR_H + 0.4, 0.4),
			stone, stone.lightened(0.05))
	m.box(Transform3D(Basis(), Vector3(0, 1.0 + DOOR_H + 0.45, DRUM + 0.2)), Vector3(DOOR_W + 1.0, 0.5, 0.45), gold, gold_top, 0.1)


## Long thin sunset clouds across the sky (glowing strips on the dome).
func _wisps(m: AltarKit.Mesher) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for s in 9:
		var az := rng.randf_range(-2.6, 0.9)
		var el := deg_to_rad(rng.randf_range(6.0, 26.0))
		var length := rng.randf_range(0.18, 0.42)
		var thick := deg_to_rad(rng.randf_range(0.5, 1.4))
		var r := 84.0
		var col := Color("ffb08e").lerp(Color("ffe2c0"), rng.randf()) if el < deg_to_rad(15.0) else Color("e48aa8").lerp(Color("ffc4a8"), rng.randf())
		var steps := 8
		for k in steps:
			var a0 := az + length * k / steps
			var a1 := az + length * (k + 1) / steps
			var f0 := sin(PI * k / steps)
			var f1 := sin(PI * (k + 1) / steps)
			var p00 := _dir(a0, el - thick * f0) * r
			var p01 := _dir(a0, el + thick * f0) * r
			var p10 := _dir(a1, el - thick * f1) * r
			var p11 := _dir(a1, el + thick * f1) * r
			var inward := -_dir((a0 + a1) * 0.5, el)
			m.panel(p00, p10, p11, p01, inward, col, col, col.lightened(0.1), col.lightened(0.1))


static func _dir(az: float, el: float) -> Vector3:
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))


## The warm light inside the open door (the hall's glow, the ring's crystals far in).
func _inside_light(m: AltarKit.Mesher) -> void:
	var z := DRUM + 0.04
	var cols := 10
	for k in cols:
		var u0 := -DOOR_W * 0.5 + DOOR_W * k / cols
		var u1 := -DOOR_W * 0.5 + DOOR_W * (k + 1) / cols
		var mid := 1.0 - absf((u0 + u1) * 0.5) / (DOOR_W * 0.5)
		var col := Color("ffcf8a").lerp(Color("fff3d6"), mid)
		m.panel(Vector3(u0, 1.0, z), Vector3(u1, 1.0, z), Vector3(u1, 1.0 + DOOR_H, z), Vector3(u0, 1.0 + DOOR_H, z), Vector3.BACK,
			col.darkened(0.1), col.darkened(0.1), col, col)


## The cloud bank under the temple, the stair of clouds down to the child, soft clouds below in the evening sea.
func _clouds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	var puffs: Array[Array] = []
	for i in 80:
		var a := rng.randf() * TAU
		var r := rng.randf_range(4.0, 14.0)
		puffs.append([Vector3(sin(a) * r, rng.randf_range(-3.2, -0.8), cos(a) * r * 0.85 + 1.0),
			Vector3.ONE * rng.randf_range(2.0, 3.6) * Vector3(1.3, 0.62, 1.3)])
	for s in 11:
		var z := PORTICO_Z + 5.4 + s * 1.65
		var y := -1.15 - s * 0.62
		for p in 3:
			puffs.append([Vector3(rng.randf_range(-1.6, 1.6), y, z + rng.randf_range(-0.4, 0.4)),
				Vector3.ONE * rng.randf_range(0.9, 1.25) * Vector3(1.5, 0.45, 1.1)])
	for i in 70:
		var a := rng.randf() * TAU
		var r := rng.randf_range(20.0, 75.0)
		puffs.append([Vector3(sin(a) * r, rng.randf_range(-16.0, -8.0), cos(a) * r), Vector3.ONE * rng.randf_range(5.0, 10.0) * Vector3(1.5, 0.4, 1.5)])
	var box := AABB(Vector3(-90, -30, -90), Vector3(180, 60, 180))
	var mmi := AltarKit.multimesh(self, "Clouds", AltarKit.cloud_puff(), AltarKit.glow(), puffs.size(), box)
	for i in puffs.size():
		var p: Array = puffs[i]
		var at: Vector3 = p[0]
		mmi.multimesh.set_instance_transform(i, Transform3D(Basis().scaled(p[1]), at))
		var low := clampf((-at.y - 1.0) / 14.0, 0.0, 1.0)
		var tint := Color(1.0, 0.9, 0.84).lerp(Color(0.86, 0.76, 0.9), low)
		if at.x < -2.0:
			tint = tint.lerp(Color(1.0, 0.82, 0.66), 0.35)
		mmi.multimesh.set_instance_color(i, tint)


## Gold gems drifting in the warm air round the temple.
func _gems() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	var n := 14
	var box := AABB(Vector3(-20, -5, -5), Vector3(40, 25, 40))
	var mmi := AltarKit.multimesh(self, "Gems", BalanceAltar.gem_mesh(), AltarKit.glow(), n, box)
	for i in n:
		var at := Vector3(rng.randf_range(-12.0, 12.0), rng.randf_range(2.0, 10.0), rng.randf_range(8.0, 22.0))
		if absf(at.x) < 3.0:
			at.x += 6.0 * signf(at.x + 0.01)
		var basis := Basis.from_euler(Vector3(rng.randf_range(-0.6, 0.6), rng.randf() * TAU, rng.randf_range(-0.6, 0.6)))
		mmi.multimesh.set_instance_transform(i, Transform3D(basis.scaled(Vector3.ONE * rng.randf_range(3.0, 5.0)), at))
