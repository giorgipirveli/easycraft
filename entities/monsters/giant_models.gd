class_name GiantModels
extends RefCounted
## Box-built models for the Frost Giant (M3 Task 3), each built once and shared (no per-event meshes or
## materials). The body draws with BlockyAnimal's vertex-colour material (the animals' and monsters' shader);
## its eyes and its glowing mouth use GolemModels.glow_material (one unshaded material, compiled with the
## portal). Models face -Z and stand on y = 0. The arms hang from their shoulders, the right leg from its hip
## (it lifts for the stomp). The icy ring is a flat disc laid on the ground after a stomp.

const SKIN := Color("9ec6e8")
const SKIN_DARK := Color("6f9cc8")
const FUR := Color("f2f6fa")
const FUR_SHADE := Color("c9d6e3")
const BELT := Color("4c5d7a")
const ICE := Color("bfeaff")
const EYES := Color("e8fcff")
const MOUTH := Color("2a3d5c")
const MOUTH_LIT := Color("c8f8ff")
const FROST := Color("dff6ff")
const SNOW := Color("fbfdff")
const HEIGHT := 4.2
const SHOULDER_X := 1.3
const SHOULDER_Y := 2.9
const HIP := Vector3(-0.45, 1.3, 0.0)   # the right leg turns here (lifted for the stomp)
const MOUTH_AT := Vector3(0.0, 3.35, -0.62)   # where the breath leaves (unturned)

static var _body: ArrayMesh
static var _arm: ArrayMesh
static var _leg: ArrayMesh
static var _eyes: ArrayMesh
static var _eyes_lit: ArrayMesh
static var _snowball: ArrayMesh
static var _ring: ArrayMesh


static func arm_pivot(right: bool) -> Vector3:
	return Vector3(-SHOULDER_X if right else SHOULDER_X, SHOULDER_Y, 0.0)


## Its left leg, a fur loincloth, a broad icy-blue chest with a fur mantle, a big head with a white beard of
## icicles and a crown of ice.
static func body_mesh() -> ArrayMesh:
	if _body == null:
		_body = BlockyAnimal._build([
			[Vector3(0.45, 0.65, 0), Vector3(0.66, 1.3, 0.74), SKIN_DARK],       # the left leg (the right one lifts)
			[Vector3(0.45, 0.08, -0.1), Vector3(0.76, 0.16, 0.92), FUR_SHADE],   # its boot
			[Vector3(0, 1.45, 0), Vector3(1.6, 0.55, 1.0), FUR],                 # a fur loincloth
			[Vector3(0, 1.72, 0), Vector3(1.66, 0.12, 1.04), BELT],              # the belt
			[Vector3(0, 2.4, 0), Vector3(2.2, 1.25, 1.25), SKIN],                # chest
			[Vector3(0, 3.0, 0), Vector3(2.4, 0.35, 1.35), FUR],                 # the fur mantle
			[Vector3(0, 3.55, -0.05), Vector3(1.05, 0.9, 0.95), SKIN],           # head
			[Vector3(0, 3.75, -0.53), Vector3(1.1, 0.16, 0.14), SKIN_DARK],      # brow
			[Vector3(0, 3.12, -0.5), Vector3(0.9, 0.42, 0.14), FUR],             # beard
			[Vector3(-0.3, 2.84, -0.54), Vector3(0.12, 0.26, 0.1), ICE],         # icicles in the beard
			[Vector3(0.05, 2.8, -0.54), Vector3(0.12, 0.34, 0.1), ICE],
			[Vector3(0.32, 2.86, -0.54), Vector3(0.12, 0.22, 0.1), ICE],
			[Vector3(0, 4.05, -0.05), Vector3(1.0, 0.14, 0.9), ICE],             # a crown of ice
			[Vector3(-0.35, 4.22, -0.05), Vector3(0.14, 0.24, 0.14), ICE],
			[Vector3(0, 4.28, -0.05), Vector3(0.16, 0.34, 0.16), ICE],
			[Vector3(0.35, 4.22, -0.05), Vector3(0.14, 0.24, 0.14), ICE],
		])
	return _body


## One arm and fist around its shoulder, hanging down (shared by both arms).
static func arm_mesh() -> ArrayMesh:
	if _arm == null:
		_arm = BlockyAnimal._build([
			[Vector3(0, -0.1, 0), Vector3(0.74, 0.5, 0.76), FUR],                # fur on the shoulder
			[Vector3(0, -0.7, 0), Vector3(0.56, 1.1, 0.6), SKIN],
			[Vector3(0, -1.45, 0), Vector3(0.74, 0.6, 0.74), SKIN_DARK],         # fist
			[Vector3(0, -1.2, 0), Vector3(0.64, 0.12, 0.64), FUR_SHADE],         # a fur cuff
		])
	return _arm


## The right leg around its hip, hanging down.
static func leg_mesh() -> ArrayMesh:
	if _leg == null:
		_leg = BlockyAnimal._build([
			[Vector3(0, -0.6, 0), Vector3(0.66, 1.3, 0.74), SKIN_DARK],
			[Vector3(0, -1.22, -0.1), Vector3(0.76, 0.16, 0.92), FUR_SHADE],
		])
	return _leg


## Its eyes and mouth (they glow at night too). lit: the mouth glowing icy (the breath's wind-up).
static func eyes_mesh(lit: bool = false) -> ArrayMesh:
	if lit and _eyes_lit != null:
		return _eyes_lit
	if not lit and _eyes != null:
		return _eyes
	var mesh := GolemModels._build_glow([
		[Vector3(-0.24, 3.6, -0.53), Vector3(0.2, 0.14, 0.04), EYES],
		[Vector3(0.24, 3.6, -0.53), Vector3(0.2, 0.14, 0.04), EYES],
		[Vector3(0, 3.35, -0.58), Vector3(0.38, 0.14, 0.04), MOUTH_LIT if lit else MOUTH],
	])
	if lit:
		_eyes_lit = mesh
	else:
		_eyes = mesh
	return mesh


## A giant snowball (about 1.1 blocks), centred on its origin.
static func snowball_mesh() -> ArrayMesh:
	if _snowball == null:
		_snowball = BlockyAnimal._build([
			[Vector3.ZERO, Vector3(1.1, 1.0, 1.05), SNOW],
			[Vector3(0.18, 0.14, -0.2), Vector3(0.6, 0.6, 0.62), FUR_SHADE.lightened(0.3)],
			[Vector3(-0.3, -0.2, 0.2), Vector3(0.5, 0.5, 0.5), FUR],
		])
	return _snowball


## The icy ring a stomp leaves: a flat, pale-blue disc of FrostGiantRules.ICY_RADIUS (rows of thin boxes),
## laid on the ground for FrostGiantRules.ICY_TIME.
static func ice_ring_mesh() -> ArrayMesh:
	if _ring == null:
		var boxes: Array = []
		var r := FrostGiantRules.ICY_RADIUS
		for dz in range(-int(r), int(r) + 1):
			var hw := sqrt(maxf(r * r - dz * dz, 0.0))
			boxes.append([Vector3(0, 0, dz), Vector3(hw * 2.0, 0.04, 1.0), FROST if dz % 2 == 0 else ICE])
		_ring = BlockyAnimal._build(boxes)
	return _ring
