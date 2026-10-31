class_name GolemModels
extends RefCounted
## Box-built models for the Stone Golem and its portal (M2 Task 10), each built once and shared (the
## monsters' lesson: no per-event meshes or materials). Lit parts use BlockyAnimal's vertex-colour
## material (the animals' and monsters' shader, already compiled); glowing parts (eyes, the chest rune,
## the thrown rock, the dazed stars) share ONE unshaded vertex-colour material, glow_material(), which
## DesertPortal.prewarm compiles as the world appears. The same models serve both graphics styles.
## Models face -Z and stand on y = 0. The arms hang from their shoulders (arm_pivot), pointing down.

const STONE := Color("8d9199")
const STONE_DARK := Color("62666e")
const STONE_LIGHT := Color("a9adb4")
const MOSS := Color("5d8f3a")
const EYES := Color("ffb23a")
const RUNE := Color("6fe3ff")
const ROCK := Color("ff7a2a")
const ROCK_CORE := Color("ffd65c")
const STAR := Color("ffe45c")
const SAND := Color("dcb877")

## Shoulders (the arms turn around these): x = ±SHOULDER_X.
const SHOULDER_X := 1.22
const SHOULDER_Y := 2.35
const HEIGHT := 3.3

static var _body: ArrayMesh
static var _arm: ArrayMesh
static var _eyes: ArrayMesh
static var _rock: ArrayMesh
static var _stars: ArrayMesh
static var _frame: ArrayMesh
static var _glow: StandardMaterial3D


static func arm_pivot(right: bool) -> Vector3:
	return Vector3(-SHOULDER_X if right else SHOULDER_X, SHOULDER_Y, 0.0)


## Legs, hips, a broad chest with moss on the shoulders, a head with a heavy brow.
static func body_mesh() -> ArrayMesh:
	if _body == null:
		_body = BlockyAnimal._build([
			[Vector3(-0.45, 0.5, 0), Vector3(0.62, 1.0, 0.72), STONE_DARK],       # legs
			[Vector3(0.45, 0.5, 0), Vector3(0.62, 1.0, 0.72), STONE_DARK],
			[Vector3(-0.45, 0.08, -0.08), Vector3(0.7, 0.16, 0.86), STONE],       # feet
			[Vector3(0.45, 0.08, -0.08), Vector3(0.7, 0.16, 0.86), STONE],
			[Vector3(0, 1.25, 0), Vector3(1.5, 0.5, 1.0), STONE_DARK],             # hips
			[Vector3(0, 2.0, 0), Vector3(2.1, 1.1, 1.2), STONE],                   # chest
			[Vector3(0, 2.3, -0.02), Vector3(1.7, 0.35, 1.26), STONE_LIGHT],       # chest plate
			[Vector3(-0.8, 2.58, 0), Vector3(0.6, 0.1, 0.9), MOSS],                # moss on the shoulders
			[Vector3(0.75, 2.58, 0.1), Vector3(0.5, 0.1, 0.7), MOSS],
			[Vector3(0.3, 1.62, -0.61), Vector3(0.4, 0.2, 0.04), MOSS],
			[Vector3(0, 2.95, -0.08), Vector3(0.95, 0.8, 0.88), STONE],            # head
			[Vector3(0, 3.22, -0.46), Vector3(1.05, 0.2, 0.22), STONE_DARK],       # brow
			[Vector3(0, 2.68, -0.53), Vector3(0.42, 0.07, 0.05), STONE_DARK],      # mouth crack
			[Vector3(0, 3.36, -0.05), Vector3(0.5, 0.08, 0.5), MOSS],              # moss on the head
		])
	return _body


## One arm and fist around its shoulder, hanging down (shared by both arms).
static func arm_mesh() -> ArrayMesh:
	if _arm == null:
		_arm = BlockyAnimal._build([
			[Vector3(0, -0.5, 0), Vector3(0.56, 1.05, 0.62), STONE],
			[Vector3(0, -1.3, 0), Vector3(0.8, 0.62, 0.8), STONE_DARK],             # fist
			[Vector3(0, -1.3, -0.41), Vector3(0.5, 0.3, 0.04), STONE_LIGHT],        # knuckles
			[Vector3(0, 0.05, 0), Vector3(0.66, 0.2, 0.7), MOSS],
		])
	return _arm


## The glowing eyes and the rune on its chest (they shine at night too).
static func eyes_mesh() -> ArrayMesh:
	if _eyes == null:
		_eyes = _build_glow([
			[Vector3(-0.22, 3.0, -0.53), Vector3(0.22, 0.13, 0.04), EYES],
			[Vector3(0.22, 3.0, -0.53), Vector3(0.22, 0.13, 0.04), EYES],
			[Vector3(0, 2.02, -0.62), Vector3(0.3, 0.3, 0.03), RUNE],
			[Vector3(0, 2.02, -0.635), Vector3(0.12, 0.12, 0.03), Color.WHITE],
		])
	return _eyes


## The thrown rock: a glowing lump (about 0.8 blocks) centred on its origin.
static func rock_mesh() -> ArrayMesh:
	if _rock == null:
		_rock = _build_glow([
			[Vector3.ZERO, Vector3(0.7, 0.62, 0.66), ROCK],
			[Vector3(0.12, 0.1, -0.1), Vector3(0.5, 0.5, 0.52), ROCK_CORE],
			[Vector3(-0.2, -0.12, 0.14), Vector3(0.38, 0.4, 0.4), ROCK.darkened(0.2)],
		])
	return _rock


## Three little stars circling over a dazed Golem's head (centred on the origin).
static func stars_mesh() -> ArrayMesh:
	if _stars == null:
		var boxes: Array = []
		for i in 3:
			var a := TAU * i / 3.0
			var c := Vector3(cos(a) * 0.62, 0.0, sin(a) * 0.62)
			boxes.append([c, Vector3(0.2, 0.2, 0.2), STAR])
			boxes.append([c, Vector3(0.34, 0.08, 0.08), STAR])
			boxes.append([c, Vector3(0.08, 0.34, 0.08), STAR])
		_stars = _build_glow(boxes)
	return _stars


## The portal's stone frame: two pillars and a lintel around a 2 x 3 window (centred on x = 0,
## standing on y = 0, the window facing ±Z), with moss and a sandy keystone.
static func portal_frame_mesh() -> ArrayMesh:
	if _frame == null:
		_frame = BlockyAnimal._build([
			[Vector3(-1.4, 1.75, 0), Vector3(0.8, 3.5, 0.9), STONE],               # pillars
			[Vector3(1.4, 1.75, 0), Vector3(0.8, 3.5, 0.9), STONE],
			[Vector3(0, 3.85, 0), Vector3(3.6, 0.7, 1.0), STONE_DARK],             # lintel
			[Vector3(0, 3.85, 0), Vector3(0.7, 0.8, 1.06), SAND],                  # keystone
			[Vector3(0, 0.12, 0), Vector3(3.8, 0.24, 1.2), STONE_DARK],            # step
			[Vector3(-1.4, 0.5, 0), Vector3(0.96, 0.3, 1.02), STONE_LIGHT],        # pillar feet
			[Vector3(1.4, 0.5, 0), Vector3(0.96, 0.3, 1.02), STONE_LIGHT],
			[Vector3(-1.5, 2.6, 0.02), Vector3(0.84, 0.12, 0.96), MOSS],
			[Vector3(1.3, 3.5, -0.02), Vector3(0.6, 0.1, 1.04), MOSS],
			[Vector3(1.4, 1.2, 0), Vector3(0.84, 0.1, 0.94), SAND],
		])
	return _frame


## The one unshaded vertex-colour material every glowing part shares.
static func glow_material() -> StandardMaterial3D:
	if _glow == null:
		_glow = StandardMaterial3D.new()
		_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glow.vertex_color_use_as_albedo = true
		_glow.vertex_color_is_srgb = true
	return _glow


static func _build_glow(boxes: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b: Array in boxes:
		BlockyAnimal._box(st, b[0], b[1], b[2])
	st.set_material(glow_material())
	return st.commit()
