class_name SunflowerModel
extends Node3D
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5, §3.11; ruling 4: no face, no mouth: the plant shows how it is
## by posture, colour and sound only): the sunflower in its pot, about a child's height, facing +Z (the child). Five
## draws: the stem's segments, the leaves, the bracts and the petals (MultiMeshes) and the head (its seeds and green back).
## `set_pose(droop, bloom)`: droop 1 arches the stem over and hangs the head face-down, the leaves limp and pale; 0 stands
## it tall, its face to the child, leaves spread wide and green; bloom 0 is a closed bud (green bracts wrapped over it,
## the petals tucked inside), 1 the flower open, its petals out like a sun. `leaf_tip()`: where the biggest leaf is (the
## dive starts there: "Touch the leaf. Size Magic!").

const SEGMENTS := 6
const SEGMENT := 0.22
## Each joint's bend when fully drooping (radians, forward towards the child), from the pot up.
const BENDS := [0.03, 0.06, 0.14, 0.38, 0.62, 0.78]
## [segment, turn round the stem (0 faces the child), size]: the biggest (index 2) faces the child's right.
const LEAVES := [[1, -1.45, 1.35], [2, 1.55, 1.5], [3, 1.05, 1.75], [3, -1.75, 1.45], [4, 2.0, 1.15], [5, -1.25, 0.9]]
const PETALS := 26
const BRACTS := 14
const STEM := Color("5fa83c")
const LEAF := Color("5cc44c")
const LEAF_LIMP := Color("a9b45c")
const PETAL := Color("ffd21f")
const SEEDS := Color("4a2a12")
const BRACT := Color("5aa43c")

var droop := 1.0
var bloom := 0.0
var _stem: MultiMeshInstance3D
var _leaves: MultiMeshInstance3D
var _head: MeshInstance3D
var _petals: MultiMeshInstance3D
var _bracts: MultiMeshInstance3D
var _bud: MeshInstance3D
var _joints: Array[Transform3D] = []


func _init() -> void:
	name = "Sunflower"


func _ready() -> void:
	var s := LeafKit.Mesher.new()
	s.tube(Vector3.ZERO, Vector3(0, SEGMENT + 0.012, 0), 0.04, 0.034, STEM.darkened(0.08), STEM, 10, false)
	var bounds := AABB(Vector3(-1.4, -0.3, -1.4), Vector3(2.8, 2.6, 2.8))
	_stem = LeafKit.multimesh(self, "Stem", s.commit(), LeafKit.lit(), SEGMENTS, bounds)
	_leaves = LeafKit.multimesh(self, "Leaves", _leaf_mesh(), LeafKit.lit(), LEAVES.size(), bounds)
	_head = LeafKit.mesh(self, "Head", _head_mesh(), LeafKit.lit())
	var p := LeafKit.Mesher.new()
	p.ball(Transform3D(Basis().scaled(Vector3(0.3, 0.07, 1.0)), Vector3(0, 0, 0.14)), 0.14, Color(1, 1, 0.92),
		Color(0.94, 0.86, 0.66), 10, 6, 0.0, 0.0, 0.25)
	_petals = LeafKit.multimesh(self, "Petals", p.commit(), LeafKit.lit(), PETALS, bounds)
	for i in PETALS:
		_petals.multimesh.set_instance_color(i, PETAL.lerp(Color("ffbb10"), float(i % 3) * 0.18))
	var b := LeafKit.Mesher.new()
	b.ball(Transform3D(Basis().scaled(Vector3(0.42, 0.12, 1.0)), Vector3(0, 0, 0.075)), 0.085, Color(0.95, 1.0, 0.9),
		Color(0.72, 0.82, 0.68), 8, 5)
	_bracts = LeafKit.multimesh(self, "Bracts", b.commit(), LeafKit.lit(), BRACTS, bounds)
	var bud := LeafKit.Mesher.new()   # the closed bud's green bulb, pointed, its bracts' lines down its sides
	bud.ball(Transform3D(Basis().scaled(Vector3(1.0, 1.05, 1.0)), Vector3(0, 0.06, 0)), 0.15, Color("8fcf5c"), Color("4f8f34"),
		18, 12, 0.04, 2.2, 0.15)
	bud.tube(Vector3(0, 0.18, 0), Vector3(0, 0.27, 0), 0.06, 0.004, Color("7cc052"), Color("a6dc74"), 12, false)
	_bud = LeafKit.mesh(self, "Bud", bud.commit(), LeafKit.lit())
	for i in BRACTS:
		_bracts.multimesh.set_instance_color(i, BRACT.lerp(Color("78b84c"), float(i % 2) * 0.4))
	set_pose(droop, bloom)


func set_pose(new_droop: float, new_bloom: float) -> void:
	droop = clampf(new_droop, 0.0, 1.0)
	bloom = clampf(new_bloom, 0.0, 1.0)
	if _stem == null:
		return
	_joints.clear()
	var xf := Transform3D()
	for i in SEGMENTS:
		xf = xf * Transform3D(Basis(Vector3.RIGHT, BENDS[i] * droop + 0.015 * sin(i * 1.7)), Vector3.ZERO)
		_joints.append(xf)
		_stem.multimesh.set_instance_transform(i, xf)
		_stem.multimesh.set_instance_color(i, STEM.lerp(LEAF_LIMP, droop * 0.3))
		xf = xf * Transform3D(Basis(), Vector3(0, SEGMENT, 0))
	var top := xf
	for k in LEAVES.size():
		_leaves.multimesh.set_instance_transform(k, _leaf_xf(k))
		_leaves.multimesh.set_instance_color(k, LEAF.lerp(LEAF_LIMP, droop * 0.85))
	# The head: its face to the child (a little up) when standing; hanging face-down when drooping.
	var face := top * Transform3D(Basis(Vector3.RIGHT, lerpf(1.15, 0.5, droop)), Vector3(0, 0.03, 0))
	var head_size := lerpf(0.72, 1.0, bloom)
	var opened := smoothstep(0.15, 0.45, bloom)   # the head shows as the bud opens
	_head.transform = face * Transform3D(Basis().scaled(Vector3.ONE * head_size * maxf(opened, 0.001)), Vector3.ZERO)
	_head.visible = opened > 0.01
	var closed := 1.0 - smoothstep(0.1, 0.4, bloom)
	_bud.transform = face * Transform3D(Basis().scaled(Vector3.ONE * maxf(closed, 0.001)), Vector3.ZERO)
	_bud.visible = closed > 0.01
	var open := smoothstep(0.0, 1.0, bloom)
	for i in BRACTS:
		var around := TAU * i / BRACTS
		# Closed: wrapped forward over the face (the bud); open: laid back behind the petals.
		var tilt := lerpf(-1.15, 0.95, open) + (0.08 if i % 2 == 0 else -0.05)
		var basis := Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, tilt)
		var at := face * Transform3D(Basis().scaled(Vector3.ONE * head_size), Vector3.ZERO) \
			* Transform3D(basis, Basis(Vector3.UP, around) * Vector3(0, -0.02, 0.15))
		_bracts.multimesh.set_instance_transform(i, at * Transform3D(Basis().scaled(Vector3.ONE * lerpf(1.25, 1.0, open)),
			Vector3.ZERO))
	for i in PETALS:
		var around := TAU * i / PETALS + (0.06 if i % 2 == 0 else -0.04)
		var ring := 0.15 + 0.02 * (i % 2)
		var lag := 0.04 * (i % 5)
		var spread := smoothstep(0.0, 1.0, clampf((bloom - lag) / (1.0 - lag), 0.0, 1.0))
		var lean := lerpf(-1.35, 0.1 + 0.07 * (i % 2), spread)
		var basis := Basis(Vector3.UP, around) * Basis(Vector3.RIGHT, lean)
		var at := face * Transform3D(Basis().scaled(Vector3.ONE * head_size), Vector3.ZERO) \
			* Transform3D(basis, Basis(Vector3.UP, around) * Vector3(0, 0.04, ring))
		var size := lerpf(0.05, 1.0, spread)
		_petals.multimesh.set_instance_transform(i, at * Transform3D(Basis().scaled(Vector3.ONE * size), Vector3.ZERO))


func _leaf_xf(k: int) -> Transform3D:
	var spec: Array = LEAVES[k]
	var at: Transform3D = _joints[int(spec[0])] * Transform3D(Basis(), Vector3(0, SEGMENT * 0.55, 0))
	var lift := lerpf(-0.42, 1.0, droop)   # standing: spread up and out; drooping: hanging down
	var basis := Basis(Vector3.UP, float(spec[1])) * Basis(Vector3.RIGHT, lift) * Basis().scaled(Vector3.ONE * float(spec[2]))
	return at * Transform3D(basis, Vector3.ZERO)


## The head's middle, in this node's space (the bee visits it).
func head_position() -> Vector3:
	return _head.position if _head else Vector3(0, SEGMENT * SEGMENTS, 0)


## The biggest leaf's middle, in this node's space (the dive's start).
func leaf_tip() -> Vector3:
	if _joints.is_empty():
		set_pose(droop, bloom)
	return _leaf_xf(2) * Vector3(0, 0.0, 0.24)


## A leaf: a heart-shaped blade with a midrib, cupped a little, from its stalk (z = 0) to its tip (z = 0.42).
static func _leaf_mesh() -> ArrayMesh:
	var m := LeafKit.Mesher.new()
	m.tube(Vector3.ZERO, Vector3(0, 0.0, 0.07), 0.012, 0.01, Color(0.85, 0.95, 0.8), Color(0.9, 1, 0.85), 6, false)
	var rows := 10
	var cols := 9
	for face in 2:
		var first := m.count()
		for r in rows:
			var s := float(r) / (rows - 1)
			var z := 0.06 + s * 0.36
			var half := 0.17 * pow(sin(PI * clampf(s * 0.9 + 0.06, 0.0, 1.0)), 0.75) * (1.0 - 0.3 * s)
			for k in cols:
				var u := float(k) / (cols - 1) * 2.0 - 1.0
				var y := 0.04 * u * u - 0.025 * s - (0.004 if face == 1 else 0.0)
				var col := Color(1, 1, 1).lerp(Color(0.84, 0.93, 0.8), absf(u))
				if absf(u) < 0.14:
					col = Color(1.0, 1.0, 0.84)   # the midrib
				elif int(r) % 3 == 1 and absf(u) < 0.7:
					col = col.lightened(0.06)   # the side veins
				if face == 1:
					col = Color(0.76, 0.86, 0.72)
				m._add(Vector3(u * half, y, z), Vector3.UP if face == 0 else Vector3.DOWN, col)
		m._grid(first, rows, cols, face == 0)
	return m.commit()


## The head: the seed disc (seeds in a golden-angle spiral, two browns) and its green back.
static func _head_mesh() -> ArrayMesh:
	var m := LeafKit.Mesher.new()
	m.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.42, 1.0)), Vector3(0, -0.02, 0)), 0.19, Color("6aa83e"), Color("3f7a2a"),
		18, 10, 0.0, 0.0, 0.1)
	m.disc(Transform3D(Basis(), Vector3(0, 0.055, 0)), 0.165, SEEDS.lightened(0.12), SEEDS.darkened(0.25), 28, 0.025)
	var golden := PI * (3.0 - sqrt(5.0))
	for k in 80:
		var r := 0.15 * sqrt(float(k) / 80.0)
		var th := k * golden
		var col := SEEDS.lightened(0.22) if k % 2 == 0 else SEEDS.darkened(0.12)
		m.ball(Transform3D(Basis(), Vector3(cos(th) * r, 0.072 + 0.012 * (1.0 - r / 0.15), sin(th) * r)), 0.012, col, col, 4, 2)
	return m.commit()
