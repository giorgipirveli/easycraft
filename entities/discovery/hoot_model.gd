class_name HootModel
extends RefCounted
## The learning places' look (2026-10-18, docs/devlog/parts/academy-look.md): Professor Hoot, one blocky owl for every
## place he is (perched on the Discovery Academy's top, flying to the child): a round brown body with a cream belly and
## its feathers' chevrons, a big head with a pale face disc, round yellow eyes with dark pupils and a gleam, an orange
## beak and feet, little ear tufts, a tail, and the School's square teacher's cap with its golden tassel; two wings of their
## own that beat in flight and fold at his sides. Boxes in the owl's own metres (about 0.8 m tall at scale 1), standing on
## y 0, facing -Z (BlockyAnimal's owls face -Z too). Every face turned outwards (LifeRoomDecor's boxes), drawn with the
## rooms' warmed lit material: the body one mesh, each wing one.

const BODY := &"body"
const WING_LEFT := &"wing_left"
const WING_RIGHT := &"wing_right"

const BROWN := Color("8d6e4f")
const CREAM := Color("eadcbc")
const BEAK := Color("e7a33a")
const EYE := Color("ffd23f")
const PUPIL := Color("1c1c20")
const CAP := Color("23263a")
const BOARD := Color("2d3550")
const GOLD := Color("f2c95a")

## Each wing's shoulder (its pivot) in the owl's frame; the wing hangs down from it.
const SHOULDER := Vector3(0.175, 0.47, 0.01)

static var _meshes := {}


## The boxes of `part` ([centre, size, colour] or with a basis): the body in the owl's frame, a wing about its shoulder.
static func parts(part: StringName) -> Array:
	match part:
		WING_LEFT, WING_RIGHT:
			var s := -1.0 if part == WING_LEFT else 1.0
			return [[Vector3(s * 0.02, -0.15, 0.02), Vector3(0.045, 0.3, 0.25), BROWN.darkened(0.14)],
				[Vector3(s * 0.025, -0.06, -0.06), Vector3(0.05, 0.12, 0.1), CREAM.darkened(0.12)],
				[Vector3(s * 0.02, -0.31, 0.07), Vector3(0.04, 0.06, 0.15), BROWN.darkened(0.26)]]
	var out := [
		# the body, its belly and the chevrons of its feathers
		[Vector3(0, 0.26, 0), Vector3(0.32, 0.36, 0.28), BROWN],
		[Vector3(0, 0.25, -0.141), Vector3(0.22, 0.28, 0.01), CREAM],
		[Vector3(0, 0.12, 0.165), Vector3(0.18, 0.1, 0.07), BROWN.darkened(0.18)],   # the tail
		# the head, its face disc, eyes, beak and ear tufts
		[Vector3(0, 0.56, 0), Vector3(0.34, 0.24, 0.3), BROWN],
		[Vector3(0, 0.555, -0.151), Vector3(0.28, 0.19, 0.01), CREAM],
		[Vector3(0, 0.515, -0.166), Vector3(0.045, 0.06, 0.04), BEAK],
		[Vector3(-0.15, 0.69, 0.0), Vector3(0.05, 0.06, 0.06), BROWN.darkened(0.12)],
		[Vector3(0.15, 0.69, 0.0), Vector3(0.05, 0.06, 0.06), BROWN.darkened(0.12)],
		# the feet
		[Vector3(-0.07, 0.03, -0.05), Vector3(0.07, 0.06, 0.09), BEAK],
		[Vector3(0.07, 0.03, -0.05), Vector3(0.07, 0.06, 0.09), BEAK],
		# the square cap: its crown, the board (turned a little), its button and the tassel hanging at the side
		[Vector3(0, 0.705, 0.01), Vector3(0.2, 0.07, 0.18), CAP],
		[Vector3(0, 0.75, 0.01), Vector3(0.34, 0.025, 0.34), BOARD, Basis(Vector3.UP, 0.62)],
		[Vector3(0, 0.767, 0.01), Vector3(0.035, 0.015, 0.035), GOLD],
		[Vector3(0.155, 0.7, -0.09), Vector3(0.016, 0.1, 0.016), GOLD],
		[Vector3(0.155, 0.64, -0.09), Vector3(0.036, 0.04, 0.036), GOLD],
	]
	for y: float in [0.33, 0.24, 0.15]:   # chevrons on the belly
		for x: float in [-0.05, 0.05]:
			out.append([Vector3(x, y, -0.148), Vector3(0.045, 0.02, 0.006), CREAM.darkened(0.16)])
	for x: float in [-0.07, 0.07]:   # the eyes: yellow, a dark pupil, a white gleam
		out.append([Vector3(x, 0.57, -0.158), Vector3(0.088, 0.088, 0.01), EYE])
		out.append([Vector3(x, 0.565, -0.164), Vector3(0.046, 0.046, 0.01), PUPIL])
		out.append([Vector3(x + 0.012, 0.58, -0.17), Vector3(0.015, 0.015, 0.004), Color.WHITE])
	return out


## The mesh of `part` (made once), drawn with LifeRoomDecor.lit_material().
static func mesh(part: StringName) -> ArrayMesh:
	if not _meshes.has(part):
		_meshes[part] = LifeRoomDecor.boxes_mesh(parts(part))
	return _meshes[part]


## Where a wing's pivot is in the owl's frame.
static func shoulder(part: StringName) -> Vector3:
	return Vector3(-SHOULDER.x if part == WING_LEFT else SHOULDER.x, SHOULDER.y, SHOULDER.z)


## The whole owl, wings folded, into `d` as lit pieces named `piece` + its part: standing at `xf` (the owl's frame: its
## feet at the origin, facing -Z), `size` times the model.
static func add_to(d: LifeRoomDecor, piece: String, xf: Transform3D, size: float) -> void:
	for part: StringName in [BODY, WING_LEFT, WING_RIGHT]:
		var at := Vector3.ZERO if part == BODY else shoulder(part)
		for b: Array in parts(part):
			var basis: Basis = b[3] if b.size() > 3 else Basis.IDENTITY
			d.box_basis(piece, (b[1] as Vector3) * size,
				Transform3D(xf.basis * basis, xf * ((at + (b[0] as Vector3)) * size)), b[2])
