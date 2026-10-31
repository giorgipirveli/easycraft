class_name TempleHall
extends AltarRoom
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5, §3.11, §4.3, §4.5): the Sky Temple's Entrance Hall. A
## round hall of white stone 16 m across under a coffered dome with an oculus (the evening sky in it, a soft shaft of
## light to a warm glow on the floor), twelve fluted columns, tall arched windows painted with the sunset, the great door
## at the far side (closed until the hall is lit), ten altars in a ring round a gold seal in the floor where the Great
## Altar rises, and a chandelier of eleven crystal sockets that light one by one as the Glimmers fly up. The child stands
## on the walkway outside the ring; the ring turns to bring each altar in front of them.
##
## Drawn as: the shell (floor, walls, columns, dome, cornices, the chandelier's frame: one lit mesh), its glow (windows,
## the oculus's sky, the door's view, the chandelier's drops), its glass (the light from the oculus), the door, the
## ring's two MultiMeshes, the sockets' MultiMesh, their halos, the active altar, the Great Altar once risen, Hoot.

const RADIUS := 8.0
const WALL := 6.4
const RING_R := 5.0
const SOCKETS := 11
const CHANDELIER_Y := 7.0
const CHANDELIER_R := 1.9
const DOOR_W := 2.6
const DOOR_H := 4.4
const DUSK := Color("2f2a55")
const WOOD := Color("8f5b34")

var _great: BalanceAltar
var _great_t := 0.0
var _sockets: MultiMeshInstance3D
var _halos: MeshInstance3D
var _lit := 0
var _door: MeshInstance3D
var _door_open := false


func build() -> void:
	env = AltarKit.environment(DUSK, Color(1.0, 0.86, 0.78), 0.4)
	exposure = 1.0
	AltarKit.sun_for(self, -58.0, -22.0, Color(1.0, 0.88, 0.72), 0.74)
	var lit := AltarKit.Mesher.new()
	var glow := AltarKit.Mesher.new()
	var glass := AltarKit.Mesher.new()
	_floor(lit)
	_wall(lit, glow)
	_dome(lit, glow)
	_light(glass)
	_chandelier(lit, glow)
	AltarKit.mesh(self, "Shell", lit.commit(), AltarKit.lit())
	AltarKit.mesh(self, "ShellGlow", glow.commit(), AltarKit.glow())
	AltarKit.mesh(self, "Light", glass.commit(), AltarKit.glass())
	_door = AltarKit.mesh(self, "Door", ArrayMesh.new(), AltarKit.lit())
	set_door_open(false)
	var sockets := AABB(Vector3(-2.5, 5.0, -2.5), Vector3(5, 3.5, 5))
	_sockets = AltarKit.multimesh(self, "Sockets", BalanceAltar.ring_crystal_mesh(), AltarKit.glow(), SOCKETS, sockets)
	_halos = AltarKit.mesh(self, "Halos", ArrayMesh.new(), AltarKit.glass())
	set_lit(0)
	room_tools = AltarHalls.tools("entrance")
	build_ring(10, RING_R, "fox")
	_great = BalanceAltar.new(true, room_tools, "dragon")
	_great.visible = false
	add_child(_great)
	raise_great(0.0)
	add_view(ALTAR_VIEW, Vector3(0, 1.12, RING_R + 0.98), Vector3(0, 0.6, RING_R - 0.02), Vector3(0, 0, RING_R + 0.5), 0.0)
	add_view("great", Vector3(0, 1.5, 1.55), Vector3(0, 0.85, 0.0), Vector3(0, 0, 0.5), 0.0)
	add_view("wide", Vector3(1.2, 1.55, 7.35), Vector3(-0.4, 3.9, -3.0))
	add_view("up", Vector3(0, 1.4, 4.2), Vector3(0, 8.0, 0.0))
	start_view = ALTAR_VIEW


# --- What changes -------------------------------------------------------------------------------------------------------

## The Great Altar rises from the seal (`t` 0: under the floor, 1: risen); once risen it is the altar played.
func raise_great(t: float) -> void:
	_great_t = clampf(t, 0.0, 1.0)
	_great.visible = _great_t > 0.0
	_great.position = Vector3(0, lerpf(-1.8, 0.0, _great_t), 0)
	if _great_t >= 1.0:
		_ring_altar.visible = false
		_refresh_ring()
		focus("great", _great)
	elif altar == _great:
		_ring_altar.visible = true
		_refresh_ring()
		focus(ALTAR_VIEW, _ring_altar)


func great_visible() -> bool:
	return _great.visible


## `n` of the chandelier's eleven sockets lit (the ring's ten in order, then the Great Altar's in the middle): a lit
## crystal glows warm gold and sparkles (crossed soft discs of light).
func set_lit(n: int) -> void:
	_lit = clampi(n, 0, SOCKETS)
	var mm := _sockets.multimesh
	var halos := AltarKit.Mesher.new()
	for i in SOCKETS:
		var xf := _socket_transform(i)
		mm.set_instance_transform(i, xf)
		var on := i < _lit
		mm.set_instance_color(i, Color(1.0, 0.95, 0.74) if on else Color(0.46, 0.47, 0.64))
		if on:
			var mid := xf * Vector3(0, 0.12, 0)
			var size := 0.62 if i < 10 else 1.15
			for a in 3:
				var th := PI * a / 3.0
				AltarKit.halo(halos, mid, Vector3(sin(th), 0, cos(th)), size, Color(1.0, 0.86, 0.5, 0.42))
			AltarKit.halo(halos, mid, Vector3.UP, size * 0.8, Color(1.0, 0.86, 0.5, 0.3))
	_halos.mesh = halos.commit()


func lit_count() -> int:
	return _lit


func socket_count() -> int:
	return SOCKETS


func _socket_transform(i: int) -> Transform3D:
	if i >= 10:
		return Transform3D(Basis(Vector3.RIGHT, PI).scaled(Vector3.ONE * 2.6), Vector3(0, CHANDELIER_Y - 0.28, 0))
	var th := TAU * i / 10.0
	return Transform3D(Basis().scaled(Vector3.ONE * 1.8), Vector3(sin(th) * CHANDELIER_R, CHANDELIER_Y + 0.06, cos(th) * CHANDELIER_R))


## The great door at the far side, closed or swung open onto the sky.
func set_door_open(open: bool) -> void:
	_door_open = open
	var m := AltarKit.Mesher.new()
	var z := -RADIUS + 0.2
	for sx: float in [-1.0, 1.0]:
		var hinge := Vector3(sx * DOOR_W * 0.5, 0, z + (0.004 if sx > 0.0 else 0.0))
		var turn := sx * 1.3 if open else 0.0
		_leaf(m, Transform3D(Basis(Vector3.UP, turn), hinge), sx)
	_door.mesh = m.commit()


func door_open() -> bool:
	return _door_open


## One leaf of the arched door (its top follows the arch), planks of warm wood, gold bands and studs, a ring handle.
## The leaf's own x runs from its hinge towards the door's middle (a hair past it, so the leaves meet).
func _leaf(m: AltarKit.Mesher, hinge: Transform3D, sx: float) -> void:
	var w := DOOR_W * 0.5 + 0.012
	var arch := DOOR_W * 0.5
	var thick := 0.12
	var basis := hinge.basis
	var along := basis * Vector3(-sx, 0, 0)
	var out := basis * Vector3(0, 0, 1)
	var o := hinge.origin
	var strips := 12
	for k in strips:
		var x0 := w * k / strips
		var x1 := w * (k + 1) / strips
		var t0 := _arch_top(x0, arch)
		var t1 := _arch_top(x1, arch)
		var plank := WOOD.darkened(0.12 if k % 3 == 2 else 0.0)
		var top := plank.lightened(0.1)
		m.panel(o + along * x0 + out * thick, o + along * x1 + out * thick, o + along * x1 + Vector3(0, t1, 0) + out * thick,
			o + along * x0 + Vector3(0, t0, 0) + out * thick, out, plank.darkened(0.15), plank.darkened(0.15), top, top)
		m.panel(o + along * x0, o + along * x0 + Vector3(0, t0, 0), o + along * x1 + Vector3(0, t1, 0), o + along * x1, -out,
			plank, plank, plank, plank)
		var edge_n := (Vector3(0, 1, 0) - along * (t1 - t0) / maxf(x1 - x0, 0.001)).normalized()
		m.panel(o + along * x0 + Vector3(0, t0, 0), o + along * x0 + Vector3(0, t0, 0) + out * thick,
			o + along * x1 + Vector3(0, t1, 0) + out * thick, o + along * x1 + Vector3(0, t1, 0), edge_n, top, top, top, top)
	for side: float in [0.0, w]:
		var t := _arch_top(side, arch)
		var n := -along if side == 0.0 else along
		m.panel(o + along * side, o + along * side + out * thick, o + along * side + Vector3(0, t, 0) + out * thick,
			o + along * side + Vector3(0, t, 0), n, WOOD.darkened(0.3), WOOD.darkened(0.3), WOOD.darkened(0.2), WOOD.darkened(0.2))
	var gold := BalanceAltar.GOLD
	for y: float in [0.5, DOOR_H * 0.5, DOOR_H - 0.4]:
		var c := o + along * (w * 0.5) + Vector3(0, y, 0) + out * (thick + 0.012)
		m.box(Transform3D(basis, c), Vector3(w - 0.08, 0.08, 0.024), gold, BalanceAltar.GOLD_TOP, 0.05)
		for s in 5:
			m.sphere(Transform3D(basis, o + along * (0.1 + s * (w - 0.2) / 4.0) + Vector3(0, y, 0) + out * (thick + 0.03)), 0.02,
				BalanceAltar.GOLD_TOP, gold, 8, 4)
	var handle := o + along * (w - 0.2) + Vector3(0, DOOR_H * 0.45, 0) + out * (thick + 0.03)
	m.torus(Transform3D(basis * Basis(Vector3.RIGHT, PI * 0.5), handle), 0.1, 0.016, BalanceAltar.GOLD_TOP, gold, 20, 5)


## The arch's height over a point `x` along a leaf from its hinge (the arch's middle at the leaf's far edge).
static func _arch_top(x: float, arch: float) -> float:
	var d := clampf(arch - x, -arch, arch)
	return DOOR_H + sqrt(maxf(arch * arch - d * d, 0.0))


# --- The shell ----------------------------------------------------------------------------------------------------------

## The floor: warm sandstone in rings, gold inlays, rays from the seal to each altar, the seal's medallion and its star.
func _floor(m: AltarKit.Mesher) -> void:
	var walk := Color("e8d4ae")
	var band := Color("dcc29a")
	var inner := Color("ebd9b6")
	var gold := Color("d6a541")
	var ivory := Color("f4ead6")
	var rings: Array[Vector2] = [Vector2(RADIUS, 0), Vector2(7.6, 0), Vector2(6.3, 0), Vector2(6.16, 0), Vector2(6.08, 0),
		Vector2(5.94, 0), Vector2(4.06, 0), Vector2(3.94, 0), Vector2(3.86, 0), Vector2(2.3, 0), Vector2(1.86, 0),
		Vector2(1.78, 0), Vector2(1.7, 0), Vector2(0.0, 0)]
	var cols: Array[Color] = [walk.darkened(0.24), walk.darkened(0.08), walk, gold, gold.darkened(0.1), band, band.darkened(0.03),
		gold, inner, inner, inner.lightened(0.03), gold, ivory, ivory.lightened(0.02)]
	m.lathe(Transform3D(), rings, cols, 72)
	for i in 10:
		var th := TAU * i / 10.0
		var dir := Vector3(sin(th), 0, cos(th))
		var side := Vector3(dir.z, 0, -dir.x)
		var a := dir * 1.86 + Vector3(0, 0.003, 0)
		var b := dir * 3.88 + Vector3(0, 0.003, 0)
		m.panel(a - side * 0.045, a + side * 0.045, b + side * 0.012, b - side * 0.012, Vector3.UP, gold, gold, gold.lightened(0.08),
			gold.lightened(0.08))
		var tip := dir * 1.62 + Vector3(0, 0.004, 0)
		var root := dir * 0.58 + Vector3(0, 0.004, 0)
		for half: float in [-1.0, 1.0]:
			var a2 := m.add(root, Vector3.UP, gold)
			var b2 := m.add(root + side * half * 0.16, Vector3.UP, Color("efd9a6") if half < 0.0 else gold.darkened(0.1))
			var c2 := m.add(tip, Vector3.UP, gold.lightened(0.12))
			m.tri(a2, b2, c2)
	m.torus(Transform3D(Basis(), Vector3(0, 0.006, 0)), 0.5, 0.025, BalanceAltar.GOLD_TOP, gold, 36, 4)
	for z: float in [-0.13, 0.13]:
		m.box(Transform3D(Basis(), Vector3(0, 0.012, z)), Vector3(0.62, 0.02, 0.13), gold, BalanceAltar.GOLD_TOP, 0.0)


## The round wall: a skirting, the wall (darker at its foot), twelve fluted columns, tall arched windows painted with the
## sunset, the cornice; the door's frame and the sky behind it.
func _wall(m: AltarKit.Mesher, glow: AltarKit.Mesher) -> void:
	var stone := Color("efe5d4")
	m.lathe(Transform3D(), [Vector2(RADIUS, WALL), Vector2(RADIUS, WALL - 1.2), Vector2(RADIUS, 1.6), Vector2(RADIUS, 0.4),
		Vector2(RADIUS, 0.0)] as Array[Vector2],
		[Color("f6efe3"), stone, stone.darkened(0.04), stone.darkened(0.13), stone.darkened(0.24)] as Array[Color], 72)
	m.lathe(Transform3D(), [Vector2(RADIUS - 0.02, 0.42), Vector2(RADIUS - 0.1, 0.38), Vector2(RADIUS - 0.1, 0.03),
		Vector2(RADIUS - 0.02, 0.0)] as Array[Vector2],
		[BalanceAltar.GOLD, Color("dfcfb2"), Color("d3c09d"), Color("c7b28c")] as Array[Color], 72)
	m.lathe(Transform3D(), [Vector2(RADIUS, WALL), Vector2(RADIUS - 0.42, WALL), Vector2(RADIUS - 0.42, WALL - 0.12),
		Vector2(RADIUS - 0.34, WALL - 0.18), Vector2(RADIUS - 0.34, WALL - 0.3), Vector2(RADIUS - 0.02, WALL - 0.42)] as Array[Vector2],
		[stone, stone.lightened(0.05), stone, BalanceAltar.GOLD_TOP, BalanceAltar.GOLD, stone.darkened(0.1)] as Array[Color], 72)
	for i in 12:
		var th := TAU * (i + 0.5) / 12.0
		AltarKit.column(m, Vector3(sin(th), 0, cos(th)) * (RADIUS - 0.42), WALL - 0.4, 0.25)
	for i in 12:
		if i == 0:
			continue
		var th := TAU * i / 12.0
		if i == 6:
			_door_frame(m, glow, th)
		else:
			_window(m, glow, th, i)


## An arched window in the wall at angle `th`: its glass painted with the sunset (deep blue above, violet, coral, gold
## at the sill) with soft wisps of cloud, a gold frame with a keystone.
func _window(m: AltarKit.Mesher, glow: AltarKit.Mesher, th: float, index: int) -> void:
	var out := Vector3(sin(th), 0, cos(th))
	var across := Vector3(out.z, 0, -out.x)
	var r := RADIUS - 0.03
	var w := 1.36
	var bottom := 1.7
	var top := 4.6
	var arch := w * 0.5
	var sky := [[0.0, Color("ffd38c")], [0.2, Color("ffb088")], [0.45, Color("d98fb8")], [0.72, Color("7d70c0")],
		[1.0, Color("3f4896")]]
	var cols := 14
	var height := top + arch - bottom
	for k in cols:
		var u0 := -w * 0.5 + w * k / cols
		var u1 := -w * 0.5 + w * (k + 1) / cols
		var t0 := top + sqrt(maxf(arch * arch - u0 * u0, 0.0))
		var t1 := top + sqrt(maxf(arch * arch - u1 * u1, 0.0))
		var rows := 8
		for j in rows:
			var f0 := float(j) / rows
			var f1 := float(j + 1) / rows
			var y00 := bottom + (t0 - bottom) * f0
			var y01 := bottom + (t0 - bottom) * f1
			var y10 := bottom + (t1 - bottom) * f0
			var y11 := bottom + (t1 - bottom) * f1
			glow.panel(out * r + across * u0 + Vector3(0, y00, 0), out * r + across * u1 + Vector3(0, y10, 0),
				out * r + across * u1 + Vector3(0, y11, 0), out * r + across * u0 + Vector3(0, y01, 0), -out,
				_sky_at(sky, (y00 - bottom) / height), _sky_at(sky, (y10 - bottom) / height), _sky_at(sky, (y11 - bottom) / height),
				_sky_at(sky, (y01 - bottom) / height))
	var rng := RandomNumberGenerator.new()
	rng.seed = index * 31
	for s in 3:
		var y := bottom + rng.randf_range(0.6, 2.2)
		var half := rng.randf_range(0.22, 0.5)
		var c := rng.randf_range(-0.3, 0.3)
		var col := Color("ffd9bf") if y < bottom + 1.4 else Color("f0b6cf")
		var a0 := out * (r - 0.006) + across * (c - half) + Vector3(0, y, 0)
		var a1 := out * (r - 0.006) + across * (c + half) + Vector3(0, y, 0)
		glow.panel(a0, a1, a1 + Vector3(0, 0.045, 0) - across * half * 0.4, a0 + Vector3(0, 0.045, 0) + across * half * 0.3, -out,
			col, col, col.lightened(0.15), col.lightened(0.15))
	var gold := BalanceAltar.GOLD
	var rr := r - 0.04
	for side: float in [-1.0, 1.0]:
		m.tube(out * rr + across * side * w * 0.5 + Vector3(0, bottom, 0), out * rr + across * side * w * 0.5 + Vector3(0, top, 0),
			0.05, gold, gold, 8)
	m.box(Transform3D(Basis.looking_at(-out, Vector3.UP), out * (rr - 0.04) + Vector3(0, bottom - 0.04, 0)), Vector3(w + 0.3, 0.1, 0.16),
		gold.darkened(0.1), BalanceAltar.GOLD_TOP)
	var prev := Vector3.ZERO
	for k in 13:
		var a := PI * k / 12.0
		var p := out * rr + across * cos(a) * arch + Vector3(0, top + sin(a) * arch, 0)
		if k > 0:
			m.tube(prev, p, 0.05, gold, gold, 8)
		prev = p
	m.box(Transform3D(Basis.looking_at(-out, Vector3.UP), out * (rr - 0.03) + Vector3(0, top + arch + 0.03, 0)), Vector3(0.16, 0.24, 0.1),
		gold, BalanceAltar.GOLD_TOP)


func _sky_at(bands: Array, f: float) -> Color:
	for b in bands.size() - 1:
		var lo: float = bands[b][0]
		var hi: float = bands[b + 1][0]
		if f <= hi:
			return (bands[b][1] as Color).lerp(bands[b + 1][1], clampf((f - lo) / maxf(hi - lo, 0.0001), 0.0, 1.0))
	return bands[-1][1]


## The great door's frame: a deep stone arch edged in gold, the temple's emblem over it, and the sky beyond (seen when
## the door opens): bright blue, the cloud bridge to the Sky Room and its balloons.
func _door_frame(m: AltarKit.Mesher, glow: AltarKit.Mesher, th: float) -> void:
	var out := Vector3(sin(th), 0, cos(th))
	var across := Vector3(out.z, 0, -out.x)
	var r := RADIUS - 0.02
	var w := DOOR_W
	var arch := w * 0.5
	var sky := [[0.0, Color("f6fbff")], [0.3, Color("cfe8ff")], [0.7, Color("8cc4f6")], [1.0, Color("5b9ae6")]]
	var cols := 16
	var height := DOOR_H + arch
	for k in cols:
		var u0 := -w * 0.5 + w * k / cols
		var u1 := -w * 0.5 + w * (k + 1) / cols
		var t0 := DOOR_H + sqrt(maxf(arch * arch - u0 * u0, 0.0))
		var t1 := DOOR_H + sqrt(maxf(arch * arch - u1 * u1, 0.0))
		for j in 6:
			var f0 := float(j) / 6.0
			var f1 := float(j + 1) / 6.0
			glow.panel(out * r + across * u0 + Vector3(0, t0 * f0, 0), out * r + across * u1 + Vector3(0, t1 * f0, 0),
				out * r + across * u1 + Vector3(0, t1 * f1, 0), out * r + across * u0 + Vector3(0, t0 * f1, 0), -out,
				_sky_at(sky, t0 * f0 / height), _sky_at(sky, t1 * f0 / height), _sky_at(sky, t1 * f1 / height),
				_sky_at(sky, t0 * f1 / height))
	var near := out * (r - 0.01)
	for b in 5:
		var y := 0.05 + b * 0.16
		var half := 1.2 - b * 0.2
		glow.panel(near + across * -half + Vector3(0, y, 0), near + across * half + Vector3(0, y, 0),
			near + across * (half * 0.8) + Vector3(0, y + 0.16, 0), near + across * (-half * 0.8) + Vector3(0, y + 0.16, 0), -out,
			Color(1, 1, 1), Color(1, 1, 1), Color(0.93, 0.96, 1.0), Color(0.93, 0.96, 1.0))
	for b in 5:
		var at := near + across * ((b - 2) * 0.18) + Vector3(0, 2.0 + 0.12 * sin(b * 1.9), 0)
		glow.lathe(Transform3D(Basis.looking_at(out, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5), at - out * 0.003),
			[Vector2(0.075, 0.0), Vector2(0.0, 0.0)] as Array[Vector2], [Color("ff7a66"), Color("ffb0a0")] as Array[Color], 12)
	var gold := BalanceAltar.GOLD
	var rr := r - 0.12
	for side: float in [-1.0, 1.0]:
		m.box(Transform3D(Basis.looking_at(-out, Vector3.UP), out * rr + across * side * (w * 0.5 + 0.18) + Vector3(0, DOOR_H * 0.5, 0)),
			Vector3(0.36, DOOR_H, 0.3), Color("efe5d4"), Color("f7f0e4"))
	var prev := Vector3.ZERO
	for k in 17:
		var a := PI * k / 16.0
		var p := out * rr + across * cos(a) * (arch + 0.12) + Vector3(0, DOOR_H + sin(a) * (arch + 0.12), 0)
		if k > 0:
			m.tube(prev, p, 0.13, Color("ebe0cd"), Color("ebe0cd"), 10)
			m.tube(prev - out * 0.1, p - out * 0.1, 0.05, gold, gold, 8)
		prev = p
	m.box(Transform3D(Basis.looking_at(-out, Vector3.UP), out * (r - 0.25) + Vector3(0, 0.05, 0)), Vector3(w + 0.8, 0.1, 0.5),
		gold.darkened(0.1), gold)
	var face := Basis.looking_at(out, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5)
	var centre := out * (rr - 0.18) + Vector3(0, DOOR_H + arch + 0.75, 0)
	m.torus(Transform3D(face, centre), 0.42, 0.04, BalanceAltar.GOLD_TOP, gold, 32, 6)
	for y: float in [0.1, -0.1]:
		m.box(Transform3D(Basis.looking_at(-out, Vector3.UP), centre + Vector3(0, y, 0) - out * 0.02), Vector3(0.5, 0.1, 0.05),
			gold, BalanceAltar.GOLD_TOP, 0.05)


## The dome: rows of recessed coffers (each with a gold rosette), smaller towards the top, the oculus's gold rim and the
## evening sky in it. Warmer and lighter near the oculus, where the light comes in.
func _dome(m: AltarKit.Mesher, glow: AltarKit.Mesher) -> void:
	var a := RADIUS - 0.42
	var b := 5.5
	var top_phi := acos(1.45 / a)
	var rows := 7
	var segs := 24
	var at := func(phi: float, th: float) -> Vector3:
		return Vector3(sin(th) * a * cos(phi), WALL + b * sin(phi), cos(th) * a * cos(phi))
	var inward := func(phi: float, th: float) -> Vector3:
		return -Vector3(sin(th) * cos(phi) / a, sin(phi) / b, cos(th) * cos(phi) / a).normalized()
	for r in rows:
		var p0 := top_phi * r / rows
		var p1 := top_phi * (r + 1) / rows
		var f := float(r) / (rows - 1)
		var panel := Color("e9dcc6").lerp(Color("fbeccc"), f)
		var rim := Color("d8c8ad").lerp(Color("efdcba"), f)
		for k in segs:
			var t0 := TAU * k / segs
			var t1 := TAU * (k + 1) / segs
			var c00: Vector3 = at.call(p0, t0)
			var c01: Vector3 = at.call(p0, t1)
			var c11: Vector3 = at.call(p1, t1)
			var c10: Vector3 = at.call(p1, t0)
			var mid := (c00 + c01 + c11 + c10) * 0.25
			var n: Vector3 = inward.call((p0 + p1) * 0.5, (t0 + t1) * 0.5)
			var depth := -n * (0.16 - 0.08 * f)
			var inset := 0.2
			var i00 := c00.lerp(mid, inset) + depth
			var i01 := c01.lerp(mid, inset) + depth
			var i11 := c11.lerp(mid, inset) + depth
			var i10 := c10.lerp(mid, inset) + depth
			m.panel(i00, i01, i11, i10, n, panel.darkened(0.06), panel.darkened(0.06), panel, panel)
			m.panel(c00, c01, i01, i00, n, rim.lightened(0.08), rim.lightened(0.08), rim.darkened(0.1), rim.darkened(0.1))
			m.panel(c10, i10, i11, c11, n, rim.darkened(0.12), rim.darkened(0.22), rim.darkened(0.22), rim.darkened(0.12))
			m.panel(c00, i00, i10, c10, n, rim, rim.darkened(0.15), rim.darkened(0.15), rim)
			m.panel(c01, c11, i11, i01, n, rim, rim, rim.darkened(0.15), rim.darkened(0.15))
			var rose := mid + depth * 0.94
			m.lathe(Transform3D(AltarKit.facing(n), rose),
				[Vector2(0.09 + 0.06 * (1.0 - f), 0.0), Vector2(0.0, 0.02)] as Array[Vector2],
				[BalanceAltar.GOLD, BalanceAltar.GOLD_TOP] as Array[Color], 10)
	var top_y := WALL + b * sin(top_phi)
	m.torus(Transform3D(Basis(), Vector3(0, top_y - 0.05, 0)), 1.5, 0.12, BalanceAltar.GOLD_TOP, BalanceAltar.GOLD, 40, 6)
	m.lathe(Transform3D(), [Vector2(a + 0.02, WALL + 0.02), Vector2(a - 0.12, WALL + 0.12), Vector2(a - 0.12, WALL + 0.2),
		Vector2(a + 0.02, WALL + 0.2)] as Array[Vector2], [BalanceAltar.GOLD, BalanceAltar.GOLD_TOP, BalanceAltar.GOLD,
		BalanceAltar.GOLD] as Array[Color], 72)
	glow.lathe(Transform3D(Basis(), Vector3(0, top_y + 0.35, 0)), [Vector2(0.0, 0.08), Vector2(0.9, 0.06), Vector2(1.7, 0.0)]
		as Array[Vector2], [Color("4d5aa8"), Color("8d7cc9"), Color("ffbe94")] as Array[Color], 32)


## The light from the oculus: a soft warm shaft down to a gentle glow on the floor round the seal.
func _light(m: AltarKit.Mesher) -> void:
	var top := WALL + 5.3
	m.lathe(Transform3D(), [Vector2(1.35, top), Vector2(1.55, top - 4.0), Vector2(1.9, 0.4)] as Array[Vector2],
		[Color(1.0, 0.86, 0.6, 0.0), Color(1.0, 0.86, 0.58, 0.07), Color(1.0, 0.88, 0.66, 0.0)] as Array[Color], 40)
	m.disc(Transform3D(Basis(), Vector3(0, 0.016, 0)), 2.1, Color(1.0, 0.9, 0.66, 0.16), Color(1.0, 0.9, 0.66, 0.0), 48)


## The chandelier's gold frame: an outer ring of ten cups (one over each altar), an inner ring hung with small crystal
## drops, a boss with the eleventh socket below it, four chains up to the oculus.
func _chandelier(m: AltarKit.Mesher, glow: AltarKit.Mesher) -> void:
	var gold := BalanceAltar.GOLD
	var y := CHANDELIER_Y
	var r := CHANDELIER_R
	m.torus(Transform3D(Basis(), Vector3(0, y, 0)), r, 0.05, BalanceAltar.GOLD_TOP, gold.darkened(0.15), 56, 6)
	m.torus(Transform3D(Basis(), Vector3(0, y - 0.04, 0)), r + 0.12, 0.025, BalanceAltar.GOLD_TOP, gold.darkened(0.15), 56, 5)
	m.torus(Transform3D(Basis(), Vector3(0, y - 0.26, 0)), 1.05, 0.035, BalanceAltar.GOLD_TOP, gold.darkened(0.15), 40, 6)
	m.sphere(Transform3D(Basis(), Vector3(0, y, 0)), 0.2, BalanceAltar.GOLD_TOP, gold.darkened(0.2), 16, 8)
	for i in 10:
		var th := TAU * i / 10.0
		var at := Vector3(sin(th) * r, y, cos(th) * r)
		m.lathe(Transform3D(Basis(), at), [Vector2(0.0, -0.08), Vector2(0.06, -0.07), Vector2(0.1, 0.03), Vector2(0.09, 0.06)]
			as Array[Vector2], [gold.darkened(0.3), gold, BalanceAltar.GOLD_TOP, gold] as Array[Color], 14)
		m.tube(Vector3(0, y, 0), at, 0.022, gold, gold, 6)
		m.tube(Vector3(sin(th) * 1.05, y - 0.26, cos(th) * 1.05), at, 0.016, gold, gold, 6)
		var drop := Vector3(sin(th + 0.31) * 1.05, y - 0.3, cos(th + 0.31) * 1.05)
		BalanceAltar.crystal_geometry(glow, Transform3D(Basis(Vector3.RIGHT, PI).scaled(Vector3.ONE * 0.6), drop),
			Color(0.85, 0.94, 1.0), Color(1.0, 1.0, 1.0))
	m.tube(Vector3(0, y - 0.15, 0), Vector3(0, y - 0.32, 0), 0.04, gold, gold, 8)
	for i in 4:
		var th := TAU * (i + 0.5) / 4.0
		m.tube(Vector3(sin(th) * r, y, cos(th) * r), Vector3(sin(th) * 1.4, WALL + 5.25, cos(th) * 1.4), 0.025, gold.darkened(0.1),
			gold, 6)
