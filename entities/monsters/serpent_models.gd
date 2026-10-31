class_name SerpentModels
extends RefCounted
## Box-built models for the Sand Serpent (M3 Task 2), each built once and shared (no per-event meshes or
## materials). The body draws with BlockyAnimal's vertex-colour material (the animals' and monsters'
## shader); its eyes and the glowing mouth of a sand-ball wind-up use GolemModels.glow_material (one
## unshaded material, compiled with the Golem's portal). Models face -Z; a segment is centred on its origin.

const SCALES := Color("d9a441")
const SCALES_DARK := Color("a8742a")
const BELLY := Color("f1d98f")
const EYES := Color("7cffb0")
const FANG := Color("fbf6e6")
const MOUTH := Color("5a2415")
const MOUTH_LIT := Color("ffcf4a")
const SAND := Color("dcb877")
const SAND_DARK := Color("b99655")
const SEGMENTS := 7
const SEGMENT := 0.62             # a segment's height along the neck

static var _head: ArrayMesh
static var _head_lit: ArrayMesh
static var _eyes: ArrayMesh
static var _segment: ArrayMesh
static var _tail: ArrayMesh
static var _mound: ArrayMesh
static var _ball: ArrayMesh


## A big snake head: scales, a paler jaw, fangs, a crest (the eyes are eyes_mesh). lit: a sand ball
## glowing in its open mouth (the spit's wind-up).
static func head_mesh(lit: bool = false) -> ArrayMesh:
	if lit and _head_lit != null:
		return _head_lit
	if not lit and _head != null:
		return _head
	var mesh := BlockyAnimal._build([
		[Vector3(0, 0.1, 0), Vector3(1.0, 0.62, 1.1), SCALES],                       # skull
		[Vector3(0, -0.28, -0.12), Vector3(0.86, 0.22, 0.95), BELLY],                # jaw
		[Vector3(0, 0.0, -0.6), Vector3(0.7, 0.3, 0.2), MOUTH_LIT if lit else MOUTH],   # the open mouth
		[Vector3(-0.25, -0.1, -0.66), Vector3(0.1, 0.22, 0.08), FANG],               # fangs
		[Vector3(0.25, -0.1, -0.66), Vector3(0.1, 0.22, 0.08), FANG],
		[Vector3(0, 0.46, 0.1), Vector3(0.2, 0.18, 0.9), SCALES_DARK],               # crest
		[Vector3(-0.52, 0.12, 0.05), Vector3(0.06, 0.4, 0.7), SCALES_DARK],          # cheeks
		[Vector3(0.52, 0.12, 0.05), Vector3(0.06, 0.4, 0.7), SCALES_DARK],
	])
	if lit:
		_head_lit = mesh
	else:
		_head = mesh
	return mesh


static func eyes_mesh() -> ArrayMesh:
	if _eyes == null:
		_eyes = GolemModels._build_glow([
			[Vector3(-0.3, 0.25, -0.5), Vector3(0.18, 0.14, 0.06), EYES],
			[Vector3(0.3, 0.25, -0.5), Vector3(0.18, 0.14, 0.06), EYES],
		])
	return _eyes


## One segment of its long body: scales with a pale belly towards -Z and dark bands.
static func segment_mesh() -> ArrayMesh:
	if _segment == null:
		_segment = BlockyAnimal._build([
			[Vector3.ZERO, Vector3(0.9, SEGMENT, 0.9), SCALES],
			[Vector3(0, 0, -0.44), Vector3(0.62, SEGMENT * 0.9, 0.04), BELLY],
			[Vector3(0, SEGMENT * 0.42, 0), Vector3(0.94, 0.08, 0.94), SCALES_DARK],
		])
	return _segment


## Its tail, lying along the sand behind it (the rattle shakes before a sweep).
static func tail_mesh() -> ArrayMesh:
	if _tail == null:
		_tail = BlockyAnimal._build([
			[Vector3(0, 0.25, 0.6), Vector3(0.7, 0.5, 1.2), SCALES],
			[Vector3(0, 0.2, 1.6), Vector3(0.5, 0.4, 1.0), SCALES_DARK],
			[Vector3(0, 0.3, 2.3), Vector3(0.36, 0.5, 0.5), BELLY],                   # the rattle
		])
	return _tail


## The mound of sand that moves over it while it swims under the sand.
static func mound_mesh() -> ArrayMesh:
	if _mound == null:
		_mound = BlockyAnimal._build([
			[Vector3(0, 0.12, 0), Vector3(1.8, 0.24, 1.8), SAND],
			[Vector3(0, 0.3, 0), Vector3(1.1, 0.2, 1.1), SAND_DARK],
			[Vector3(0, 0.45, 0.1), Vector3(0.5, 0.14, 0.6), SAND],
		])
	return _mound


## The spat ball of sand (centred on its origin).
static func ball_mesh() -> ArrayMesh:
	if _ball == null:
		_ball = BlockyAnimal._build([
			[Vector3.ZERO, Vector3(0.66, 0.6, 0.62), SAND],
			[Vector3(0.1, 0.12, -0.1), Vector3(0.44, 0.44, 0.46), SAND_DARK],
		])
	return _ball
