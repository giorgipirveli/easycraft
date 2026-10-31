class_name SporeMotherModels
extends RefCounted
## Box-built models for the Spore Mother, the Glow Caves' boss (universe 6; our own design), each built once and
## shared (no per-event meshes or materials). Her stem-body, arms and face draw with BlockyAnimal's vertex-colour
## material (the animals' and monsters' shader); her glowing cap, its spots, her gills, the warning rings, the spore
## clouds and her glittering puff use GolemModels.glow_material (one unshaded material, compiled with the portals as
## the world appears). Nothing new to compile. She faces -Z and stands on y = 0: a giant friendly mushroom, a pale
## lilac stem-body with a sleepy smiling face, two stubby arms, a big domed rose-and-teal cap with glowing spots, and
## gills under its rim that glow bright when they are open (her weak spot).

const STEM := Color("efe6f7")
const STEM_SHADE := Color("d6c8e8")
const CAP := Color("f285b9")              # her rose cap (it glows: unshaded)
const CAP_DARK := Color("c95b92")
const CAP_LIGHT := Color("ffc2df")
const SPOT := Color("8ff7e8")             # glowing teal spots
const GILLS := Color("b88fd9")            # her gills, closed ...
const GILLS_OPEN := Color("fff1a8")       # ... and open: bright and golden (hit them!)
const EYE := Color("2a1f3d")
const CHEEK := Color("ff9fc2")
const RING := Color("8ff7e8")             # a spore cloud's warning ring
const CLOUD := Color("c9fff3")
const CLOUD_DEEP := Color("8fe8d8")
const GLITTER: Array[Color] = [Color("fff1a8"), Color("c9fff3"), Color("ffd6ec"), Color("e8dcff")]
const HEIGHT := 4.6                       # her height to the cap's top
const CAP_Y := 3.0                        # the cap's underside
const ARM_PIVOT := Vector3(1.0, 2.0, 0.0) # her right arm's shoulder (the left is mirrored)

static var _meshes := {}


static func _cached(key: StringName, boxes: Array, glow: bool) -> ArrayMesh:
	if not _meshes.has(key):
		_meshes[key] = GolemModels._build_glow(boxes) if glow else BlockyAnimal._build(boxes)
	return _meshes[key]


## Her stem-body: a stepped round stem wider at the foot, a frill under the cap, her sleepy smiling face in front.
static func body_mesh() -> ArrayMesh:
	var boxes: Array = [
		[Vector3(0, 0.25, 0), Vector3(2.2, 0.5, 2.2), STEM_SHADE],               # her round foot
		[Vector3(0, 0.9, 0), Vector3(1.9, 0.8, 1.9), STEM],
		[Vector3(0, 1.8, 0), Vector3(1.7, 1.0, 1.7), STEM],
		[Vector3(0, 2.6, 0), Vector3(1.5, 0.8, 1.5), STEM],
		[Vector3(0, 2.92, 0), Vector3(2.1, 0.16, 2.1), STEM_SHADE],             # a frill (her ring)
		[Vector3(-0.38, 2.05, -0.86), Vector3(0.34, 0.08, 0.04), EYE],          # sleepy closed eyes (happy arcs)
		[Vector3(0.38, 2.05, -0.86), Vector3(0.34, 0.08, 0.04), EYE],
		[Vector3(-0.52, 2.12, -0.86), Vector3(0.08, 0.08, 0.04), EYE],
		[Vector3(-0.24, 2.12, -0.86), Vector3(0.08, 0.08, 0.04), EYE],
		[Vector3(0.24, 2.12, -0.86), Vector3(0.08, 0.08, 0.04), EYE],
		[Vector3(0.52, 2.12, -0.86), Vector3(0.08, 0.08, 0.04), EYE],
		[Vector3(0, 1.62, -0.86), Vector3(0.4, 0.08, 0.04), EYE],               # a soft smile
		[Vector3(-0.2, 1.68, -0.86), Vector3(0.08, 0.08, 0.04), EYE],
		[Vector3(0.2, 1.68, -0.86), Vector3(0.08, 0.08, 0.04), EYE],
		[Vector3(-0.62, 1.8, -0.86), Vector3(0.2, 0.12, 0.04), CHEEK],          # pink cheeks
		[Vector3(0.62, 1.8, -0.86), Vector3(0.2, 0.12, 0.04), CHEEK],
	]
	return _cached(&"body", boxes, false)


## One stubby arm (the right one, hanging from its shoulder at the origin; the left is mirrored).
static func arm_mesh() -> ArrayMesh:
	return _cached(&"arm", [
		[Vector3(0.2, -0.35, 0), Vector3(0.4, 0.8, 0.45), STEM],
		[Vector3(0.24, -0.82, 0), Vector3(0.46, 0.3, 0.5), STEM_SHADE],
	], false)


## Her big domed cap, glowing (unshaded): a wide rim, layers narrowing to a round top, glowing teal spots.
static func cap_mesh() -> ArrayMesh:
	var boxes: Array = [
		[Vector3(0, CAP_Y + 0.15, 0), Vector3(4.2, 0.3, 4.2), CAP_DARK],
		[Vector3(0, CAP_Y + 0.45, 0), Vector3(3.8, 0.4, 3.8), CAP],
		[Vector3(0, CAP_Y + 0.85, 0), Vector3(3.0, 0.4, 3.0), CAP],
		[Vector3(0, CAP_Y + 1.2, 0), Vector3(2.0, 0.3, 2.0), CAP_LIGHT],
		[Vector3(0, CAP_Y + 1.45, 0), Vector3(1.0, 0.2, 1.0), CAP_LIGHT],
	]
	for s: Vector3 in [Vector3(-1.2, 0.68, -1.0), Vector3(1.1, 0.7, -1.2), Vector3(0.0, 1.07, -1.05), Vector3(-1.4, 0.66, 0.9),
			Vector3(1.3, 0.66, 1.0), Vector3(0.6, 1.36, 0.5), Vector3(-0.6, 1.36, -0.3), Vector3(0.2, 0.66, 1.75),
			Vector3(-1.75, 0.5, 0.0), Vector3(1.75, 0.5, -0.2)]:
		boxes.append([Vector3(s.x, CAP_Y + s.y, s.z), Vector3(0.45, 0.12, 0.45), SPOT])
	return _cached(&"cap", boxes, true)


## The gills under her cap's rim (unshaded): lilac when closed, bright golden when open (her weak spot).
static func gills_mesh(open: bool) -> ArrayMesh:
	var boxes: Array = []
	var c := GILLS_OPEN if open else GILLS
	for i in 16:
		var a := TAU * i / 16.0
		boxes.append([Vector3(cos(a) * 1.55, CAP_Y - 0.04, sin(a) * 1.55), Vector3(0.18, 0.08, 0.6), c])
	boxes.append([Vector3(0, CAP_Y - 0.06, 0), Vector3(3.6, 0.04, 3.6), c.darkened(0.25) if not open else c.darkened(0.05)])
	return _cached(&"gills_open" if open else &"gills", boxes, true)


## A warning ring on the ground where a spore cloud will land (radius 1 unscaled: scaled to its ring), glowing teal.
static func ring_mesh() -> ArrayMesh:
	var boxes: Array = []
	for i in 20:
		var a := TAU * i / 20.0
		boxes.append([Vector3(cos(a), 0.04, sin(a)), Vector3(0.24, 0.06, 0.24), RING])
	boxes.append([Vector3(0, 0.03, 0), Vector3(0.24, 0.04, 0.24), RING])
	return _cached(&"ring", boxes, true)


## A spore cloud (radius about 1 unscaled): soft round puffs, glowing pale teal.
static func cloud_mesh() -> ArrayMesh:
	var boxes: Array = []
	for p: Vector3 in [Vector3(0, 0.5, 0), Vector3(0.6, 0.4, 0.2), Vector3(-0.5, 0.45, -0.3), Vector3(0.1, 0.9, -0.4),
			Vector3(-0.2, 0.85, 0.5), Vector3(0.5, 0.75, -0.5), Vector3(-0.6, 0.3, 0.5), Vector3(0.0, 1.2, 0.0)]:
		var s := 0.55 - absf(p.y - 0.6) * 0.3
		boxes.append([p, Vector3.ONE * s, CLOUD if int(p.x * 10) % 2 == 0 else CLOUD_DEEP])
	return _cached(&"cloud", boxes, true)


## Her glittering puff (while she hides): a big round cloud with glitter, about as tall as she is.
static func puff_mesh() -> ArrayMesh:
	var boxes: Array = []
	for i in 26:
		var a := TAU * i / 26.0
		var y := 0.4 + float((i * 7) % 11) / 11.0 * 3.6
		var r := 1.6 + 0.6 * sin(i * 1.7)
		boxes.append([Vector3(cos(a) * r, y, sin(a) * r), Vector3.ONE * (0.9 - 0.12 * (i % 3)), CLOUD if i % 2 == 0 else CLOUD_DEEP])
	for i in 18:
		var a := TAU * i / 18.0 + 0.3
		boxes.append([Vector3(cos(a) * 2.3, 0.6 + (i % 6) * 0.65, sin(a) * 2.3), Vector3.ONE * 0.16, GLITTER[i % GLITTER.size()]])
	return _cached(&"puff", boxes, true)
