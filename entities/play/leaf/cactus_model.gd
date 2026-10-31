class_name CactusModel
extends Node3D
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5b steps 1 and 8, §3.11; ruling 4: no face, no mouth): the
## desert's cactus in its pot of sand, waist-high to a child, facing +Z (the child). A ribbed green stem with two arms (a
## cactus builds its sugar in its stem: its spines are its leaves, here soft pale dots, never needles: never scary), a pale
## closed bud on top that opens into a big white flower at night (`set_pose(bloom)`). Two draws: the plant and the flower.
## `stem_point()`: where the child touches its green stem to dive ("Let's look inside its green stem. Size Magic!").

const HEIGHT := 0.62
const RADIUS := 0.1
const GREEN := Color("4f9a48")
const GREEN_LIGHT := Color("7cc062")
const AREOLE := Color("eef3dc")
const PETAL := Color("fbfbf4")
const HEART := Color("f6d65a")

var bloom := 0.0
var _flower: MeshInstance3D
var _bud: MeshInstance3D


func _init() -> void:
	name = "Cactus"


func _ready() -> void:
	var m := LeafKit.Mesher.new()
	# The ribbed stem: eight ribs as slim capsules round a core, a domed top.
	m.capsule(Transform3D(), RADIUS, HEIGHT, GREEN_LIGHT, GREEN, 16, 8)
	for k in 8:
		var a := TAU * k / 8.0
		var at := Vector3(cos(a), 0, sin(a)) * RADIUS * 0.72
		m.capsule(Transform3D(Basis(), at), RADIUS * 0.38, HEIGHT * 0.92, GREEN_LIGHT.lightened(0.05), GREEN.darkened(0.08),
			10, 6)
	# Two arms, rising like a cupped hand on each side.
	for side: float in [-1.0, 1.0]:
		var root := Vector3(side * RADIUS * 0.8, HEIGHT * (0.42 if side < 0 else 0.3), 0)
		var elbow := root + Vector3(side * 0.13, 0.0, 0)
		m.tube(root, elbow, RADIUS * 0.55, RADIUS * 0.55, GREEN, GREEN_LIGHT, 12, false)
		m.ball(Transform3D(Basis(), elbow), RADIUS * 0.55, GREEN_LIGHT, GREEN, 12, 8)
		m.capsule(Transform3D(Basis(), elbow - Vector3(0, RADIUS * 0.55, 0)), RADIUS * 0.55, 0.26, GREEN_LIGHT, GREEN, 12, 6)
	# Soft pale dots where the spines would be (never needles).
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 26:
		var a := TAU * (k % 8) / 8.0 + 0.2
		var y := 0.06 + (k / 8) * 0.15 + rng.randf_range(-0.02, 0.02)
		var at := Vector3(cos(a), 0, sin(a)) * RADIUS * 1.08 + Vector3(0, y, 0)
		m.ball(Transform3D(Basis(), at), 0.011, AREOLE, AREOLE.darkened(0.1), 5, 3)
	LeafKit.mesh(self, "Plant", m.commit(), LeafKit.lit())
	var b := LeafKit.Mesher.new()   # the closed bud: pale, smooth, pointed
	b.ball(Transform3D(Basis().scaled(Vector3(1.0, 1.25, 1.0)), Vector3(0, HEIGHT + 0.08, 0)), 0.045, Color("eef5d8"),
		Color("b9d29a"), 12, 8)
	_bud = LeafKit.mesh(self, "Bud", b.commit(), LeafKit.lit())
	var f := LeafKit.Mesher.new()   # the night flower: two rings of white petals round a golden heart
	for ring in 2:
		var n := 12
		for k in n:
			var a := TAU * (k + ring * 0.5) / n
			var dir := Vector3(cos(a), 0, sin(a))
			var tilt := 0.35 + ring * 0.35
			var basis := Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, tilt)
			f.ball(Transform3D(basis * Basis.from_scale(Vector3(0.38, 0.1, 1.0)), dir * (0.07 - ring * 0.012) + Vector3(0, 0.01 * ring, 0)),
				0.075 - ring * 0.01, PETAL, PETAL.darkened(0.08), 8, 5)
	f.ball(Transform3D(Basis(), Vector3(0, 0.02, 0)), 0.03, HEART, HEART.darkened(0.15), 10, 6)
	_flower = LeafKit.mesh(self, "Flower", f.commit(), LeafKit.lit())
	_flower.position = Vector3(0, HEIGHT + 0.06, 0)
	set_pose(bloom)


## 0: the pale closed bud; 1: the big white flower open.
func set_pose(new_bloom: float) -> void:
	bloom = clampf(new_bloom, 0.0, 1.0)
	if _flower == null:
		return
	var open := smoothstep(0.0, 1.0, bloom)
	_flower.visible = open > 0.02
	_flower.scale = Vector3.ONE * lerpf(0.2, 1.0, open)
	_bud.visible = open < 0.6


## The point on the green stem the child touches (this node's space), on the child's side.
func stem_point() -> Vector3:
	return Vector3(0.0, HEIGHT * 0.55, RADIUS * 1.1)
