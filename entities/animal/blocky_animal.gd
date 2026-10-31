class_name BlockyAnimal
extends RefCounted
## Box-built animal models: vertex-coloured meshes per species, built once and shared by every
## animal of that species. Animals face -Z; land animals stand on y = 0, fish are centred on y = 0.
## They hop-walk as a whole (no separate legs), Crossy Road style. One part may move on its own for
## the idle animation (spec §3b): dogs and cats wag their tail, the farm animals bob their head.
## That part is a second mesh around PART_PIVOT (two draw calls; fish and rabbits have one).

static var _meshes := {}
static var _material: StandardMaterial3D

const BLACK := Color("1c1c20")
const WHITE := Color("fbfbfb")
const PART := true                # 4th box element: this box belongs to the moving part
const WAG := &"wag"
const BOB := &"bob"
## Where the moving part turns (tail root or neck), and how it moves.
const PART_PIVOT := {
	&"dog": Vector3(0, 0.6, 0.4), &"cat": Vector3(0, 0.42, 0.36), &"pig": Vector3(0, 0.52, -0.38),
	&"cow": Vector3(0, 0.95, -0.52), &"sheep": Vector3(0, 0.76, -0.43), &"chicken": Vector3(0, 0.45, -0.08),
	&"fox": Vector3(0, 0.42, 0.35), &"parrot": Vector3(0, 0.26, 0.16), &"pip": Vector3(0, 0.75, 0),   # M3 Task 11
	&"dragon": Vector3(0, 0.48, 0.02),   # owner 39: its wings flap from the shoulders
	# owner #41: heads that bob (grazers, penguins), tails that wag, an owl's head that turns
	&"horse": Vector3(0, 1.5, -0.72), &"donkey": Vector3(0, 0.98, -0.52), &"goat": Vector3(0, 0.62, -0.28),
	&"deer": Vector3(0, 0.88, -0.32), &"duck": Vector3(0, 0.26, -0.12), &"turtle": Vector3(0, 0.15, -0.28),
	&"squirrel": Vector3(0, 0.2, 0.14), &"owl": Vector3(0, 0.46, 0), &"camel": Vector3(0, 1.55, -0.78),
	&"lizard": Vector3(0, 0.07, 0.15), &"fennec": Vector3(0, 0.32, 0.26), &"penguin": Vector3(0, 0.58, 0),
	&"polar_bear": Vector3(0, 0.95, -0.7), &"arctic_fox": Vector3(0, 0.42, 0.35), &"seal": Vector3(0, 0.3, -0.3),
	&"candy_bird": Vector3(0, 0.2, 0.14),
}
const PART_KIND := {&"dog": WAG, &"cat": WAG, &"pig": BOB, &"cow": BOB, &"sheep": BOB, &"chicken": BOB,
	&"fox": WAG, &"parrot": WAG, &"pip": BOB,   # M3 Task 11: bushy tail, tail feathers, Pip's antenna
	&"dragon": BOB,   # owner 39: the wings go up and down
	&"horse": BOB, &"donkey": BOB, &"goat": BOB, &"deer": BOB, &"duck": BOB, &"turtle": BOB, &"squirrel": WAG,
	&"owl": WAG, &"camel": BOB, &"lizard": WAG, &"fennec": WAG, &"penguin": BOB, &"polar_bear": BOB,
	&"arctic_fox": WAG, &"seal": BOB, &"candy_bird": WAG}   # owner #41
## A pet's collar: a band round the back of the head [center, size] (tameable species only).
const COLLAR := {
	&"dog": [Vector3(0, 0.63, -0.27), Vector3(0.41, 0.36, 0.06)],
	&"cat": [Vector3(0, 0.5, -0.23), Vector3(0.34, 0.3, 0.05)],
	&"fox": [Vector3(0, 0.5, -0.22), Vector3(0.32, 0.28, 0.05)],   # M3 Task 11
	&"parrot": [Vector3(0, 0.43, -0.05), Vector3(0.24, 0.05, 0.22)],   # a ring round the neck
	&"pip": [Vector3(0, 0.49, -0.07), Vector3(0.2, 0.07, 0.03)],        # a bow tie
	&"dragon": [Vector3(0, 0.55, -0.28), Vector3(0.26, 0.06, 0.2)],     # owner 39: a ring round the neck
	# owner #41's pets: a band round the neck (the head that bobs is apart from it)
	&"horse": [Vector3(0, 1.22, -0.62), Vector3(0.32, 0.08, 0.34)],
	&"donkey": [Vector3(0, 0.92, -0.46), Vector3(0.24, 0.06, 0.24)],
	&"camel": [Vector3(0, 1.3, -0.72), Vector3(0.24, 0.08, 0.26)],
	&"fennec": [Vector3(0, 0.4, -0.14), Vector3(0.24, 0.21, 0.04)],
	&"arctic_fox": [Vector3(0, 0.5, -0.22), Vector3(0.32, 0.28, 0.05)],
	# M3 Task 20b: a band round the middle (each kind's own fit: MagicPetModels.collar_for, set by Animal)
	&"monster_friend": [Vector3(0, 0.4, 0), Vector3(0.5, 0.05, 0.5)],
	&"mini_boss": [Vector3(0, 0.4, 0), Vector3(0.5, 0.05, 0.5)],
}
## Owner #41: what a pet wears on its back once it has it (a horse's or a camel's saddle, a donkey's packs),
## part of its cached "dressed" mesh (dressed_mesh_for), never an extra draw call.
const LEATHER := Color("6b3f1f")
const STEEL := Color("9aa3ad")

static var _dressed := {}

static var _parts := {}


static func mesh_for(species: StringName) -> ArrayMesh:
	if not _meshes.has(species):
		_meshes[species] = _build(_boxes(species).filter(func(b: Array) -> bool: return b.size() < 4))
	return _meshes[species]


## Owner #41: the body with what it wears on its back (a saddle, a donkey's packs), cached per species; the
## plain body when it wears nothing.
static func dressed_mesh_for(species: StringName) -> ArrayMesh:
	var extra := dress_boxes(species)
	if extra.is_empty():
		return mesh_for(species)
	if not _dressed.has(species):
		_dressed[species] = _build(_boxes(species).filter(func(b: Array) -> bool: return b.size() < 4) + extra)
	return _dressed[species]


## A saddle with stirrups on a horse's back or a camel's hump; two packs with a lid on a donkey.
static func dress_boxes(species: StringName) -> Array:
	match species:
		&"horse":
			return [[Vector3(0, 1.28, 0.0), Vector3(0.58, 0.08, 0.48), LEATHER],
				[Vector3(0, 1.36, -0.2), Vector3(0.14, 0.1, 0.07), LEATHER.darkened(0.2)],
				[Vector3(-0.3, 1.05, 0.0), Vector3(0.03, 0.3, 0.03), STEEL],
				[Vector3(0.3, 1.05, 0.0), Vector3(0.03, 0.3, 0.03), STEEL],
				[Vector3(-0.3, 0.89, 0.0), Vector3(0.07, 0.03, 0.1), STEEL],
				[Vector3(0.3, 0.89, 0.0), Vector3(0.07, 0.03, 0.1), STEEL]]
		&"camel":
			return [[Vector3(0, 1.365, 0.1), Vector3(0.58, 0.04, 0.72), Color("c0392b")],
				[Vector3(0, 1.6, 0.1), Vector3(0.44, 0.06, 0.46), LEATHER],
				[Vector3(-0.3, 1.2, 0.1), Vector3(0.03, 0.34, 0.03), STEEL],
				[Vector3(0.3, 1.2, 0.1), Vector3(0.03, 0.34, 0.03), STEEL]]
		&"donkey":
			return [[Vector3(-0.3, 0.84, 0.08), Vector3(0.14, 0.3, 0.46), Color("8a5a2b")],
				[Vector3(0.3, 0.84, 0.08), Vector3(0.14, 0.3, 0.46), Color("8a5a2b")],
				[Vector3(0, 1.03, 0.08), Vector3(0.62, 0.04, 0.4), LEATHER],
				[Vector3(-0.375, 0.86, 0.08), Vector3(0.02, 0.08, 0.1), Color("f2c230")],
				[Vector3(0.375, 0.86, 0.08), Vector3(0.02, 0.08, 0.1), Color("f2c230")]]
	return []


## The moving part (tail or head) around PART_PIVOT[species], or null when the species has none.
static func part_mesh_for(species: StringName) -> ArrayMesh:
	if not PART_PIVOT.has(species):
		return null
	if not _parts.has(species):
		var pivot: Vector3 = PART_PIVOT[species]
		var boxes: Array = []
		for b: Array in _boxes(species):
			if b.size() >= 4:
				boxes.append([b[0] - pivot, b[1], b[2]])
		_parts[species] = _build(boxes)
	return _parts[species]


## [center, size, colour(, PART)] boxes per species. c = body colour, d = detail colour.
static func _boxes(species: StringName) -> Array:
	var c: Color = AnimalRules.SPECIES[species].colors[0]
	var d: Color = AnimalRules.SPECIES[species].colors[1]
	var dark := c.darkened(0.3)
	match species:
		&"dog":
			return [
				[Vector3(0, 0.45, 0.05), Vector3(0.45, 0.34, 0.7), c],        # body
				[Vector3(0, 0.64, -0.42), Vector3(0.38, 0.34, 0.34), c],      # head
				[Vector3(0, 0.56, -0.64), Vector3(0.2, 0.15, 0.14), d],       # snout
				[Vector3(0, 0.61, -0.72), Vector3(0.08, 0.06, 0.03), BLACK],  # nose
				[Vector3(-0.16, 0.8, -0.4), Vector3(0.1, 0.18, 0.1), dark],   # ears
				[Vector3(0.16, 0.8, -0.4), Vector3(0.1, 0.18, 0.1), dark],
				[Vector3(-0.1, 0.7, -0.595), Vector3(0.07, 0.07, 0.02), BLACK],
				[Vector3(0.1, 0.7, -0.595), Vector3(0.07, 0.07, 0.02), BLACK],
				[Vector3(0, 0.72, 0.44), Vector3(0.08, 0.26, 0.08), c, PART],       # tail
			] + _legs(0.14, -0.18, 0.3, 0.12, 0.28, c)
		&"cat":
			return [
				[Vector3(0, 0.36, 0.05), Vector3(0.32, 0.26, 0.6), c],
				[Vector3(0, 0.5, -0.35), Vector3(0.32, 0.28, 0.28), c],
				[Vector3(0, 0.44, -0.495), Vector3(0.16, 0.1, 0.02), d],      # muzzle
				[Vector3(-0.1, 0.68, -0.36), Vector3(0.08, 0.1, 0.06), c],    # ears
				[Vector3(0.1, 0.68, -0.36), Vector3(0.08, 0.1, 0.06), c],
				[Vector3(-0.08, 0.54, -0.495), Vector3(0.06, 0.05, 0.02), Color("3fae4b")],
				[Vector3(0.08, 0.54, -0.495), Vector3(0.06, 0.05, 0.02), Color("3fae4b")],
				[Vector3(0, 0.62, 0.36), Vector3(0.07, 0.42, 0.07), c, PART],       # tail up
			] + _legs(0.1, -0.15, 0.25, 0.09, 0.24, c)
		&"pig":
			return [
				[Vector3(0, 0.46, 0.05), Vector3(0.7, 0.5, 0.95), c],
				[Vector3(0, 0.56, -0.55), Vector3(0.5, 0.44, 0.35), c, PART],
				[Vector3(0, 0.5, -0.76), Vector3(0.26, 0.18, 0.08), d, PART],       # snout
				[Vector3(-0.06, 0.5, -0.805), Vector3(0.05, 0.06, 0.02), BLACK, PART],
				[Vector3(0.06, 0.5, -0.805), Vector3(0.05, 0.06, 0.02), BLACK, PART],
				[Vector3(-0.17, 0.82, -0.55), Vector3(0.12, 0.1, 0.06), d, PART],   # ears
				[Vector3(0.17, 0.82, -0.55), Vector3(0.12, 0.1, 0.06), d, PART],
				[Vector3(-0.13, 0.66, -0.73), Vector3(0.07, 0.07, 0.02), BLACK, PART],
				[Vector3(0.13, 0.66, -0.73), Vector3(0.07, 0.07, 0.02), BLACK, PART],
			] + _legs(0.22, -0.3, 0.35, 0.16, 0.24, c)
		&"cow":
			return [
				[Vector3(0, 0.82, 0.1), Vector3(0.9, 0.7, 1.3), c],
				[Vector3(0.455, 0.9, 0.2), Vector3(0.02, 0.32, 0.42), d],     # spots
				[Vector3(-0.455, 0.76, -0.2), Vector3(0.02, 0.26, 0.32), d],
				[Vector3(0.1, 1.175, 0.35), Vector3(0.42, 0.02, 0.36), d],
				[Vector3(0, 1.02, -0.75), Vector3(0.5, 0.5, 0.45), c, PART],        # head
				[Vector3(0, 0.86, -1.0), Vector3(0.4, 0.2, 0.08), Color("f2a7b3"), PART],  # muzzle
				[Vector3(-0.2, 1.32, -0.72), Vector3(0.06, 0.12, 0.06), Color("efe3c6"), PART],  # horns
				[Vector3(0.2, 1.32, -0.72), Vector3(0.06, 0.12, 0.06), Color("efe3c6"), PART],
				[Vector3(-0.13, 1.1, -0.98), Vector3(0.07, 0.08, 0.02), BLACK, PART],
				[Vector3(0.13, 1.1, -0.98), Vector3(0.07, 0.08, 0.02), BLACK, PART],
			] + _legs(0.3, -0.4, 0.55, 0.2, 0.46, c)
		&"sheep":
			return [
				[Vector3(0, 0.64, 0.05), Vector3(0.8, 0.6, 1.0), c],          # wool
				[Vector3(0, 0.78, -0.58), Vector3(0.36, 0.36, 0.3), d, PART],       # face
				[Vector3(0, 0.98, -0.55), Vector3(0.4, 0.1, 0.32), c, PART],        # wool cap
				[Vector3(-0.09, 0.82, -0.735), Vector3(0.07, 0.06, 0.02), WHITE, PART],
				[Vector3(0.09, 0.82, -0.735), Vector3(0.07, 0.06, 0.02), WHITE, PART],
			] + _legs(0.22, -0.3, 0.35, 0.14, 0.34, d)
		&"chicken":
			return [
				[Vector3(0, 0.33, 0.03), Vector3(0.36, 0.3, 0.42), c],
				[Vector3(0, 0.56, -0.12), Vector3(0.22, 0.24, 0.2), c, PART],
				[Vector3(0, 0.54, -0.26), Vector3(0.1, 0.06, 0.08), d, PART],       # beak
				[Vector3(0, 0.71, -0.12), Vector3(0.06, 0.08, 0.14), Color("e23b3b"), PART],  # comb
				[Vector3(0, 0.46, -0.23), Vector3(0.05, 0.06, 0.03), Color("e23b3b"), PART],
				[Vector3(-0.19, 0.34, 0.05), Vector3(0.03, 0.18, 0.28), c.darkened(0.08)],  # wings
				[Vector3(0.19, 0.34, 0.05), Vector3(0.03, 0.18, 0.28), c.darkened(0.08)],
				[Vector3(-0.07, 0.6, -0.225), Vector3(0.05, 0.05, 0.02), BLACK, PART],
				[Vector3(0.07, 0.6, -0.225), Vector3(0.05, 0.05, 0.02), BLACK, PART],
				[Vector3(-0.08, 0.09, 0.03), Vector3(0.04, 0.18, 0.04), d],   # legs
				[Vector3(0.08, 0.09, 0.03), Vector3(0.04, 0.18, 0.04), d],
			]
		&"rabbit":
			return [
				[Vector3(0, 0.2, 0.05), Vector3(0.32, 0.28, 0.4), c],
				[Vector3(0, 0.34, -0.2), Vector3(0.24, 0.22, 0.2), c],
				[Vector3(-0.06, 0.56, -0.2), Vector3(0.06, 0.26, 0.04), c],   # ears
				[Vector3(0.06, 0.56, -0.2), Vector3(0.06, 0.26, 0.04), c],
				[Vector3(0, 0.28, 0.27), Vector3(0.12, 0.12, 0.06), d],       # tail
				[Vector3(-0.07, 0.38, -0.305), Vector3(0.05, 0.05, 0.02), BLACK],
				[Vector3(0.07, 0.38, -0.305), Vector3(0.05, 0.05, 0.02), BLACK],
				[Vector3(0, 0.3, -0.305), Vector3(0.05, 0.04, 0.02), Color("f2a7b3")],
			] + _legs(0.1, -0.12, 0.18, 0.08, 0.1, c)
		&"fox", &"arctic_fox":   # M3 Task 11: orange with a white chest, snout and tail tip, dark socks (#41: the arctic fox, white)
			var socks := Color("3a2a22") if species == &"fox" else Color("9aa7b4")
			return [
				[Vector3(0, 0.36, 0.05), Vector3(0.34, 0.26, 0.6), c],        # body
				[Vector3(0, 0.33, -0.2), Vector3(0.26, 0.2, 0.12), d],        # chest
				[Vector3(0, 0.5, -0.36), Vector3(0.3, 0.26, 0.26), c],        # head
				[Vector3(0, 0.44, -0.54), Vector3(0.14, 0.1, 0.14), d],       # snout
				[Vector3(0, 0.47, -0.615), Vector3(0.05, 0.04, 0.02), BLACK], # nose
				[Vector3(-0.09, 0.69, -0.36), Vector3(0.08, 0.12, 0.05), c],  # ears
				[Vector3(0.09, 0.69, -0.36), Vector3(0.08, 0.12, 0.05), c],
				[Vector3(-0.08, 0.54, -0.495), Vector3(0.05, 0.04, 0.02), BLACK],
				[Vector3(0.08, 0.54, -0.495), Vector3(0.05, 0.04, 0.02), BLACK],
				[Vector3(0, 0.44, 0.52), Vector3(0.16, 0.16, 0.34), c, PART],       # bushy tail
				[Vector3(0, 0.44, 0.73), Vector3(0.14, 0.14, 0.08), d, PART],       # its white tip
			] + _legs(0.1, -0.15, 0.25, 0.08, 0.24, socks)
		&"parrot":   # M3 Task 11: red with green wings, a yellow beak and blue tail feathers
			return [
				[Vector3(0, 0.32, 0.02), Vector3(0.26, 0.3, 0.3), c],         # body
				[Vector3(-0.145, 0.32, 0.04), Vector3(0.03, 0.24, 0.26), d],  # wings
				[Vector3(0.145, 0.32, 0.04), Vector3(0.03, 0.24, 0.26), d],
				[Vector3(0, 0.53, -0.06), Vector3(0.22, 0.2, 0.2), c],        # head
				[Vector3(0, 0.5, -0.19), Vector3(0.08, 0.1, 0.08), Color("f2c230")],   # beak
				[Vector3(0, 0.45, -0.21), Vector3(0.05, 0.05, 0.04), Color("5a4a44")],
				[Vector3(-0.08, 0.56, -0.165), Vector3(0.06, 0.06, 0.02), WHITE],      # eyes
				[Vector3(0.08, 0.56, -0.165), Vector3(0.06, 0.06, 0.02), WHITE],
				[Vector3(-0.08, 0.56, -0.177), Vector3(0.03, 0.03, 0.01), BLACK],
				[Vector3(0.08, 0.56, -0.177), Vector3(0.03, 0.03, 0.01), BLACK],
				[Vector3(0, 0.2, 0.3), Vector3(0.12, 0.05, 0.3), Color("2f7fe0"), PART],   # tail feathers
				[Vector3(-0.06, 0.08, 0.02), Vector3(0.04, 0.16, 0.04), Color("8a8a8a")],  # legs
				[Vector3(0.06, 0.08, 0.02), Vector3(0.04, 0.16, 0.04), Color("8a8a8a")],
			]
		&"pip":   # M3 Task 11: a small friendly robot with a screen face and an antenna
			var dark_grey := Color("4a5260")
			return [
				[Vector3(-0.12, 0.06, 0), Vector3(0.12, 0.12, 0.3), dark_grey],   # wheels
				[Vector3(0.12, 0.06, 0), Vector3(0.12, 0.12, 0.3), dark_grey],
				[Vector3(0, 0.3, 0), Vector3(0.4, 0.34, 0.34), c],             # body
				[Vector3(0, 0.32, -0.175), Vector3(0.12, 0.08, 0.02), d],     # chest light
				[Vector3(-0.24, 0.3, 0), Vector3(0.07, 0.22, 0.08), dark],    # arms
				[Vector3(0.24, 0.3, 0), Vector3(0.07, 0.22, 0.08), dark],
				[Vector3(0, 0.49, 0), Vector3(0.1, 0.05, 0.1), dark_grey],    # neck
				[Vector3(0, 0.62, 0), Vector3(0.44, 0.26, 0.34), c],          # head
				[Vector3(0, 0.62, -0.175), Vector3(0.34, 0.18, 0.02), Color("1c2a44")],   # screen
				[Vector3(-0.08, 0.645, -0.19), Vector3(0.06, 0.07, 0.02), d],  # eyes
				[Vector3(0.08, 0.645, -0.19), Vector3(0.06, 0.07, 0.02), d],
				[Vector3(0, 0.575, -0.19), Vector3(0.12, 0.025, 0.02), d],     # smile
				[Vector3(0, 0.8, 0), Vector3(0.03, 0.1, 0.03), dark_grey, PART],   # antenna
				[Vector3(0, 0.87, 0), Vector3(0.07, 0.07, 0.07), Color("ffd23f"), PART],
			]
		&"dragon":   # owner 39: a baby dragon: teal scales, a violet belly and wing skin, little horns, a tail
			var belly := Color("f3d9a4")
			return [
				[Vector3(0, 0.32, 0.05), Vector3(0.34, 0.3, 0.5), c],          # body
				[Vector3(0, 0.26, 0.02), Vector3(0.26, 0.16, 0.44), belly],    # belly
				[Vector3(0, 0.5, -0.24), Vector3(0.16, 0.2, 0.16), c],         # neck
				[Vector3(0, 0.62, -0.36), Vector3(0.28, 0.24, 0.28), c],       # head
				[Vector3(0, 0.56, -0.53), Vector3(0.18, 0.12, 0.1), c],        # snout
				[Vector3(-0.06, 0.59, -0.585), Vector3(0.03, 0.03, 0.02), BLACK],   # nostrils
				[Vector3(0.06, 0.59, -0.585), Vector3(0.03, 0.03, 0.02), BLACK],
				[Vector3(-0.08, 0.67, -0.505), Vector3(0.07, 0.08, 0.02), WHITE],   # eyes
				[Vector3(0.08, 0.67, -0.505), Vector3(0.07, 0.08, 0.02), WHITE],
				[Vector3(-0.08, 0.665, -0.515), Vector3(0.04, 0.05, 0.01), BLACK],
				[Vector3(0.08, 0.665, -0.515), Vector3(0.04, 0.05, 0.01), BLACK],
				[Vector3(-0.08, 0.79, -0.32), Vector3(0.05, 0.1, 0.05), belly],   # little horns
				[Vector3(0.08, 0.79, -0.32), Vector3(0.05, 0.1, 0.05), belly],
				[Vector3(0, 0.49, 0.1), Vector3(0.06, 0.06, 0.4), d],          # spines down the back
				[Vector3(0, 0.26, 0.42), Vector3(0.12, 0.1, 0.3), c],          # tail
				[Vector3(0, 0.22, 0.6), Vector3(0.14, 0.04, 0.1), d],          # its tip
				[Vector3(-0.3, 0.5, 0.04), Vector3(0.3, 0.04, 0.3), d, PART],   # wings
				[Vector3(0.3, 0.5, 0.04), Vector3(0.3, 0.04, 0.3), d, PART],
				[Vector3(-0.44, 0.52, -0.04), Vector3(0.06, 0.05, 0.12), c, PART],   # wing tips
				[Vector3(0.44, 0.52, -0.04), Vector3(0.06, 0.05, 0.12), c, PART],
			] + _legs(0.1, -0.1, 0.18, 0.08, 0.17, c.darkened(0.2))
		&"horse", &"donkey", &"goat", &"deer", &"duck", &"frog", &"turtle", &"squirrel", &"owl", &"hedgehog", \
				&"camel", &"lizard", &"fennec", &"penguin", &"polar_bear", &"seal", &"gummy_bunny", &"candy_bird", &"moon_bunny":
			return AnimalBoxes.boxes(species, c, d)   # owner #41: the new kinds' boxes
		&"fish":
			return [
				[Vector3(0, 0, 0), Vector3(0.18, 0.26, 0.45), c],
				[Vector3(0, 0, 0.3), Vector3(0.04, 0.26, 0.14), d],           # tail fin
				[Vector3(0, 0.16, 0.02), Vector3(0.03, 0.08, 0.18), d],       # back fin
				[Vector3(-0.095, 0.04, -0.14), Vector3(0.02, 0.06, 0.06), BLACK],
				[Vector3(0.095, 0.04, -0.14), Vector3(0.02, 0.06, 0.06), BLACK],
			]
	return [[Vector3(0, 0.5, 0), Vector3.ONE * 0.5, c]]


## Four legs at x = ±x, z = front and back.
static func _legs(x: float, front: float, back: float, w: float, h: float, color: Color) -> Array:
	var out: Array = []
	for lx in [-x, x]:
		for lz in [front, back]:
			out.append([Vector3(lx, h * 0.5, lz), Vector3(w, h, w), color])
	return out


static func _build(boxes: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b: Array in boxes:
		_box(st, b[0], b[1], b[2])
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.85
	st.set_material(_material)
	return st.commit()


static func _box(st: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var h := size * 0.5
	# normal, then the four corners (counter-clockwise seen from outside; the triangles below take them clockwise)
	var faces := [
		[Vector3.RIGHT, Vector3(h.x, -h.y, h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(h.x, h.y, h.z)],
		[Vector3.LEFT, Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, -h.y, h.z), Vector3(-h.x, h.y, h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3.UP, Vector3(-h.x, h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z)],
		[Vector3.DOWN, Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, -h.y, h.z), Vector3(-h.x, -h.y, h.z)],
		[Vector3.BACK, Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)],
		[Vector3.FORWARD, Vector3(h.x, -h.y, -h.z), Vector3(-h.x, -h.y, -h.z), Vector3(-h.x, h.y, -h.z), Vector3(h.x, h.y, -h.z)],
	]
	for f: Array in faces:
		st.set_color(color)
		st.set_normal(f[0])
		for i in [0, 2, 1, 0, 3, 2]:   # Godot's front faces turn clockwise seen from outside (test_mesh_winding.gd)
			st.add_vertex(center + (f[1 + i] as Vector3))
