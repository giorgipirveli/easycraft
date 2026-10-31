class_name CakeModels
extends RefCounted
## Box-built models for the Cake Monster (M3 Task 4), each built once and shared (no per-event meshes or
## materials). The cake draws with BlockyAnimal's vertex-colour material (the animals' and monsters' shader);
## its eyes and a glowing cherry use GolemModels.glow_material (one unshaded material, compiled with the
## Golem's portal). Models face -Z and stand on y = 0. Each tier is its own mesh, so a tier can fall off.

const SPONGE := Color("f2c46d")
const SPONGE_DARK := Color("d6a24a")
const PINK := Color("ff9ec8")
const PINK_DARK := Color("ec78ad")
const CREAM := Color("fff7ea")
const JAM := Color("d61f3c")
const CHOCO := Color("6b3a1f")
const CHOCO_DARK := Color("47230f")
const CHERRY := Color("e0102e")
const CHERRY_LIT := Color("ff5a7a")
const STEM := Color("3c7a2a")
const EYE_WHITE := Color("fbfbfb")
const PUPIL := Color("1c1c20")
const MOUTH := Color("47230f")
const TOOTH := Color("fbfbfb")
const SPRINKLES: Array[Color] = [Color("ff3b5c"), Color("ffd23f"), Color("3fb5ff"), Color("5ee05e"), Color("b57bff")]
## Each tier's height, and the height of the cake with 1, 2 or 3 tiers standing.
const TIER_HEIGHTS: Array[float] = [1.1, 1.0, 0.9]
const HEIGHTS: Array[float] = [0.0, 1.1, 2.1, 3.0]
const ARM_PIVOT := Vector3(1.35, 0.7, 0.0)   # its right arm's shoulder (the left is mirrored)

static var _tiers := {}
static var _arm: ArrayMesh
static var _eyes: ArrayMesh
static var _cherry: ArrayMesh
static var _cherry_lit: ArrayMesh
static var _ball: ArrayMesh


## Tier `i` (0 = the bottom, with the face; 1 = cream with pink dots; 2 = chocolate with sprinkles), from its
## own floor up (the monster stacks them).
static func tier_mesh(i: int) -> ArrayMesh:
	if not _tiers.has(i):
		_tiers[i] = BlockyAnimal._build(tier_boxes(i))
	return _tiers[i]


static func tier_boxes(i: int) -> Array:
	var h: float = TIER_HEIGHTS[i]
	var out: Array = []
	match i:
		0:   # sponge with a jam stripe and pink frosting dripping over its top; the face in front
			out.append_array(_round(2.8, h, SPONGE, 0.0))
			out.append_array(_round(2.84, 0.1, JAM, 0.45))
			out.append_array(_round(2.86, 0.18, PINK, h - 0.09))
			for k in 6:
				var x := -1.1 + k * 0.44
				out.append([Vector3(x, h - 0.28, -1.42), Vector3(0.18, 0.24, 0.04), PINK_DARK if k % 2 == 0 else PINK])
			out.append([Vector3(-0.5, 0.75, -1.42), Vector3(0.44, 0.34, 0.04), EYE_WHITE])   # eyes (the glow is eyes_mesh)
			out.append([Vector3(0.5, 0.75, -1.42), Vector3(0.44, 0.34, 0.04), EYE_WHITE])
			out.append([Vector3(0, 0.26, -1.42), Vector3(1.1, 0.24, 0.04), MOUTH])           # a wide grin
			for k in 4:
				out.append([Vector3(-0.36 + k * 0.24, 0.34, -1.445), Vector3(0.12, 0.09, 0.02), TOOTH])
		1:   # cream icing with pink dots
			out.append_array(_round(2.0, h, CREAM, 0.0))
			for k in 8:
				var a := TAU * k / 8.0
				out.append([Vector3(cos(a) * 1.01, 0.5, sin(a) * 1.01), Vector3(0.16, 0.16, 0.16), PINK])
			out.append_array(_round(2.04, 0.12, PINK, h - 0.06))
		_:   # chocolate with rainbow sprinkles on its top
			out.append_array(_round(1.3, h, CHOCO, 0.0))
			out.append_array(_round(1.34, 0.12, CHOCO_DARK, h - 0.06))
			for k in 10:
				var a := TAU * k / 10.0
				var r := 0.25 + (k % 3) * 0.12
				out.append([Vector3(cos(a) * r, h + 0.02, sin(a) * r), Vector3(0.14, 0.04, 0.05), SPRINKLES[k % SPRINKLES.size()]])
	return out


## A round-looking tier: two crossed boxes (an octagon from above), `w` across, from `y0` up `h`.
static func _round(w: float, h: float, c: Color, y0: float) -> Array:
	return [[Vector3(0, y0 + h * 0.5, 0), Vector3(w, h, w * 0.72), c], [Vector3(0, y0 + h * 0.5, 0), Vector3(w * 0.72, h, w), c]]


## Glowing pupils in its white eyes (the glow material).
static func eyes_mesh() -> ArrayMesh:
	if _eyes == null:
		_eyes = GolemModels._build_glow([
			[Vector3(-0.5, 0.72, -1.45), Vector3(0.18, 0.2, 0.03), Color("ff4fa3")],
			[Vector3(0.5, 0.72, -1.45), Vector3(0.18, 0.2, 0.03), Color("ff4fa3")],
		])
	return _eyes


## A stubby cream arm hanging from its shoulder (the pivot at the origin), a pink cuff at its end.
static func arm_mesh() -> ArrayMesh:
	if _arm == null:
		_arm = BlockyAnimal._build([
			[Vector3(0.18, -0.3, 0), Vector3(0.34, 0.7, 0.34), CREAM],
			[Vector3(0.18, -0.68, 0), Vector3(0.4, 0.14, 0.4), PINK],
		])
	return _arm


## The cherry on top (lit: it glows before the cherries fly: the signal).
static func cherry_mesh(lit: bool = false) -> ArrayMesh:
	if lit:
		if _cherry_lit == null:
			_cherry_lit = GolemModels._build_glow(_cherry_boxes(CHERRY_LIT))
		return _cherry_lit
	if _cherry == null:
		_cherry = BlockyAnimal._build(_cherry_boxes(CHERRY))
	return _cherry


static func _cherry_boxes(c: Color) -> Array:
	return [[Vector3(0, 0.22, 0), Vector3(0.44, 0.4, 0.44), c], [Vector3(0, 0.22, 0), Vector3(0.34, 0.46, 0.34), c],
		[Vector3(0.06, 0.52, 0), Vector3(0.06, 0.24, 0.06), STEM]]


## A thrown cherry (GolemRock's look): a red ball with a stem.
static func cherry_ball_mesh() -> ArrayMesh:
	if _ball == null:
		_ball = BlockyAnimal._build(_cherry_boxes(CHERRY))
	return _ball
