class_name SkyDragonModels
extends RefCounted
## Box-built models for the Sky Dragon and its sun lanterns (owner feedback #39; our own design), each built once
## and shared (no per-event meshes or materials). Scaly parts draw with BlockyAnimal's vertex-colour material (the
## animals' and monsters' shader, already compiled); glowing parts (eyes, the chest gem, the wind-up's glow, the
## crystals, the heal beams and the dive line) share GolemModels.glow_material (compiled with the portals as the
## world appears). Nothing new to compile. The dragon faces -Z and stands on y = 0; its neck, wings and tail hang from
## pivots (NECK, WING, TAIL) so they can move. The Dragon Realm's colours: teal scales, violet wings and spikes, a pale
## belly, ivory horns, golden eyes.

const SCALES := Color("2bb3a8")
const SCALES_DARK := Color("1d7f7a")
const SCALES_LIGHT := Color("5fd8c9")
const VIOLET := Color("8a5cf0")
const VIOLET_DARK := Color("5e3bb5")
const VIOLET_LIGHT := Color("b596ff")
const BELLY := Color("f3e9c8")
const HORN := Color("fff4d6")
const EYES := Color("ffd84a")
const EYES_LIT := Color("fff3a8")
const SLIT := Color("2a1a40")
const GEM := Color("ff7ad9")
const NOSTRIL := Color("123f3c")
const TOOTH := Color("fbfbfb")
## The healing towers (owner #43, spec §3c): golden sun lanterns on cloud-white pillars with golden beams, never
## crystals on dark pillars (the names CRYSTAL / ROCK stay for the code).
const CRYSTAL := Color("ffc94d")
const CRYSTAL_CORE := Color("fff0a8")
const CRYSTAL_TIP := Color("fffbe8")
const ROCK := Color("f4eee6")
const ROCK_DARK := Color("d8ccbf")
const BEAM := Color("ffe08a")
## The dive line: warm stripes with pale edges (a danger path every child reads).
const LINE_A := Color("ff5a3c")
const LINE_B := Color("ffd23f")
const LINE_EDGE := Color("fff7e8")

## Pivots (local to the body): the neck at the front of its chest, the wings at its shoulders (x = ±WING_X), the
## tail at its hips.
const NECK := Vector3(0, 1.9, -1.25)
const WING_X := 0.62
const WING := Vector3(WING_X, 2.1, -0.45)
const TAIL := Vector3(0, 1.5, 1.45)
## Its head (for the stars while it rests), local to the neck pivot.
const HEAD := Vector3(0, 1.45, -1.0)
const HEIGHT := 3.2
## A tower's height (its crystal's tip) and where its beam leaves.
const TOWER_HEIGHT := 3.9
const TOWER_TOP := Vector3(0, 3.5, 0)

static var _meshes := {}


static func _cached(key: StringName, boxes: Array, glow: bool) -> ArrayMesh:
	if not _meshes.has(key):
		_meshes[key] = GolemModels._build_glow(boxes) if glow else BlockyAnimal._build(boxes)
	return _meshes[key]


## Its body: chest and belly, hips, four stubby legs with ivory claws, a row of violet spikes along its back.
static func body_mesh() -> ArrayMesh:
	var boxes: Array = [
		[Vector3(0, 1.55, -0.15), Vector3(1.5, 1.3, 2.5), SCALES],            # chest and back
		[Vector3(0, 1.45, 1.05), Vector3(1.3, 1.05, 0.9), SCALES],            # hips
		[Vector3(0, 0.95, -0.1), Vector3(1.2, 0.26, 2.6), BELLY],             # belly
		[Vector3(0, 1.5, -1.38), Vector3(1.1, 0.95, 0.12), BELLY],            # chest plate
		[Vector3(0, 2.22, -0.15), Vector3(1.2, 0.08, 2.2), SCALES_LIGHT],     # a lighter back
	]
	for sx in [-1.0, 1.0]:
		boxes.append([Vector3(0.52 * sx, 0.5, -0.85), Vector3(0.42, 1.0, 0.5), SCALES_DARK])   # front legs
		boxes.append([Vector3(0.56 * sx, 0.55, 1.0), Vector3(0.5, 1.1, 0.62), SCALES_DARK])   # back legs
		boxes.append([Vector3(0.52 * sx, 0.07, -1.12), Vector3(0.46, 0.14, 0.2), HORN])       # claws
		boxes.append([Vector3(0.56 * sx, 0.07, 0.66), Vector3(0.5, 0.14, 0.2), HORN])
		boxes.append([Vector3(0.78 * sx, 1.25, -0.2), Vector3(0.06, 0.5, 1.9), SCALES_DARK])  # flank stripes
	for i in 5:
		var h := 0.42 - absf(i - 2) * 0.08
		boxes.append([Vector3(0, 2.3 + h * 0.5, -1.05 + i * 0.55), Vector3(0.18, h, 0.3), VIOLET])
	return _cached(&"body", boxes, false)


## Its neck and head (round the NECK pivot): a two-step neck, a broad head with a snout, a pale jaw, nostrils,
## two small white teeth, ivory horns, violet cheek frills and a crest.
static func neck_mesh() -> ArrayMesh:
	var boxes: Array = [
		[Vector3(0, 0.3, -0.2), Vector3(0.78, 0.85, 0.75), SCALES],
		[Vector3(0, 0.85, -0.5), Vector3(0.66, 0.75, 0.66), SCALES],
		[Vector3(0, 0.62, -0.62), Vector3(0.5, 0.9, 0.08), BELLY],            # the neck's pale front
		[Vector3(0, 1.4, -0.95), Vector3(0.95, 0.75, 1.0), SCALES],           # head
		[Vector3(0, 1.28, -1.62), Vector3(0.72, 0.5, 0.62), SCALES],          # snout
		[Vector3(0, 1.02, -1.4), Vector3(0.68, 0.18, 0.9), BELLY],            # jaw
		[Vector3(0, 1.8, -0.7), Vector3(0.14, 0.26, 0.5), VIOLET],            # crest
		[Vector3(0, 1.72, -0.28), Vector3(0.12, 0.2, 0.3), VIOLET],
	]
	for sx in [-1.0, 1.0]:
		boxes.append([Vector3(0.18 * sx, 1.42, -1.94), Vector3(0.1, 0.08, 0.03), NOSTRIL])
		boxes.append([Vector3(0.2 * sx, 1.1, -1.9), Vector3(0.08, 0.12, 0.05), TOOTH])
		boxes.append([Vector3(0.3 * sx, 1.9, -0.6), Vector3(0.16, 0.45, 0.18), HORN])       # horns, swept back
		boxes.append([Vector3(0.33 * sx, 2.18, -0.44), Vector3(0.11, 0.26, 0.2), HORN])
		boxes.append([Vector3(0.52 * sx, 1.35, -0.72), Vector3(0.1, 0.42, 0.42), VIOLET])   # cheek frills
	return _cached(&"neck", boxes, false)


## Its golden eyes with dark slits, and a pink gem on its chest (on the neck pivot and the body). `lit`: bigger and
## brighter, with a glow in its mouth (the dive's wind-up: every screen sees it glow).
static func eyes_mesh(lit: bool = false) -> ArrayMesh:
	var e := EYES_LIT if lit else EYES
	var w := 0.26 if lit else 0.2
	var boxes: Array = []
	for sx in [-1.0, 1.0]:
		boxes.append([Vector3(0.3 * sx, 1.5, -1.46), Vector3(w, w * 0.8, 0.04), e])
		boxes.append([Vector3(0.3 * sx, 1.5, -1.485), Vector3(0.05, w * 0.7, 0.02), SLIT])
	if lit:
		boxes.append([Vector3(0, 1.12, -1.92), Vector3(0.46, 0.08, 0.06), Color("ff9a3c")])
	return _cached(&"eyes_lit" if lit else &"eyes", boxes, true)


## The pink gem on its chest, glowing (on the body).
static func gem_mesh() -> ArrayMesh:
	return _cached(&"gem", [
		[Vector3(0, 1.62, -1.46), Vector3(0.3, 0.3, 0.04), GEM],
		[Vector3(0, 1.62, -1.48), Vector3(0.12, 0.12, 0.03), Color.WHITE],
	], true)


## The wind-up's glow: bright violet stripes along its belly and flanks (on the body; shown while its line shows).
static func aura_mesh() -> ArrayMesh:
	var boxes: Array = [[Vector3(0, 0.8, -0.1), Vector3(1.0, 0.06, 2.3), VIOLET_LIGHT]]
	for sx in [-1.0, 1.0]:
		boxes.append([Vector3(0.8 * sx, 1.5, -0.2), Vector3(0.04, 0.2, 1.8), VIOLET_LIGHT])
	return _cached(&"aura", boxes, true)


## One wing, reaching out along +X from its shoulder pivot (the left wing is the same mesh mirrored): an arm bone
## and a forearm, a claw at the tip, and a violet membrane stepping down behind them.
static func wing_mesh() -> ArrayMesh:
	return _cached(&"wing", [
		[Vector3(0.85, 0.1, 0), Vector3(1.7, 0.18, 0.2), VIOLET_DARK],
		[Vector3(2.45, 0.22, 0.05), Vector3(1.55, 0.15, 0.17), VIOLET_DARK],
		[Vector3(3.3, 0.28, 0.08), Vector3(0.22, 0.22, 0.22), HORN],
		[Vector3(0.95, 0.02, 0.6), Vector3(1.9, 0.06, 1.0), VIOLET],
		[Vector3(2.35, 0.08, 0.55), Vector3(1.2, 0.06, 0.95), VIOLET],
		[Vector3(3.0, 0.14, 0.4), Vector3(0.7, 0.06, 0.62), VIOLET_LIGHT],
		[Vector3(1.6, 0.0, 1.12), Vector3(0.12, 0.07, 0.3), VIOLET_DARK],    # a rib in the membrane
	], false)


## Its tail from the hip pivot back (+Z): four tapering segments sloping down, spikes, and a violet spade.
static func tail_mesh() -> ArrayMesh:
	return _cached(&"tail", [
		[Vector3(0, 0, 0.45), Vector3(0.8, 0.7, 0.9), SCALES],
		[Vector3(0, -0.12, 1.25), Vector3(0.62, 0.56, 0.9), SCALES],
		[Vector3(0, -0.24, 2.05), Vector3(0.44, 0.42, 0.9), SCALES_DARK],
		[Vector3(0, -0.32, 2.8), Vector3(0.3, 0.3, 0.8), SCALES_DARK],
		[Vector3(0, -0.32, 3.35), Vector3(0.72, 0.1, 0.5), VIOLET],
		[Vector3(0, -0.32, 3.62), Vector3(0.36, 0.1, 0.2), VIOLET],
		[Vector3(0, 0.44, 0.5), Vector3(0.16, 0.22, 0.3), VIOLET],
		[Vector3(0, 0.25, 1.3), Vector3(0.14, 0.18, 0.26), VIOLET],
	], false)


# --- Crystal towers -------------------------------------------------------------------------------------------

## A tower's base: a cloud-white pillar foot (owner #43).
static func tower_base_mesh() -> ArrayMesh:
	return _cached(&"tower_base", [
		[Vector3(0, 0.3, 0), Vector3(1.5, 0.6, 1.5), ROCK],
		[Vector3(0, 0.3, 0), Vector3(1.1, 0.64, 1.8), ROCK_DARK],
		[Vector3(0.55, 0.15, 0.55), Vector3(0.5, 0.3, 0.5), ROCK_DARK],
		[Vector3(-0.6, 0.12, -0.4), Vector3(0.4, 0.24, 0.4), ROCK],
	], false)


## A tower's sun lantern (it glows): a tall golden lantern with warm light panes, two little lanterns beside it and a
## bright sun on top (owner #43).
static func tower_crystal_mesh() -> ArrayMesh:
	return _cached(&"tower_crystal", [
		[Vector3(0, 1.9, 0), Vector3(0.72, 2.6, 0.72), CRYSTAL],
		[Vector3(0, 1.9, -0.37), Vector3(0.26, 2.2, 0.04), CRYSTAL_CORE],
		[Vector3(0, 1.9, 0.37), Vector3(0.26, 2.2, 0.04), CRYSTAL_CORE],
		[Vector3(0, 3.45, 0), Vector3(0.42, 0.5, 0.42), CRYSTAL_TIP],
		[Vector3(0, 3.8, 0), Vector3(0.18, 0.2, 0.18), CRYSTAL_TIP],
		[Vector3(0.52, 1.2, 0.1), Vector3(0.34, 1.2, 0.34), CRYSTAL],
		[Vector3(-0.46, 1.0, -0.2), Vector3(0.3, 0.9, 0.3), CRYSTAL_CORE],
	], true)


## The heal beam: a unit bar along -Z from its origin (scaled to reach the dragon).
static func beam_mesh() -> ArrayMesh:
	return _cached(&"beam", [[Vector3(0, 0, -0.5), Vector3(1, 1, 1), BEAM]], true)


## A spark that runs along the beam to the dragon (the heal on its way).
static func spark_mesh() -> ArrayMesh:
	return _cached(&"spark", [
		[Vector3.ZERO, Vector3(0.3, 0.3, 0.3), CRYSTAL_TIP],
		[Vector3.ZERO, Vector3(0.46, 0.12, 0.12), CRYSTAL_CORE],
		[Vector3.ZERO, Vector3(0.12, 0.46, 0.12), CRYSTAL_CORE],
	], true)


# --- The dive line --------------------------------------------------------------------------------------------

## The dive line: a flat strip 1 × 1 (x across, z along; scaled to the dive's length and width) of warm stripes with
## pale edges, lying just over y = 0.
static func line_mesh() -> ArrayMesh:
	var boxes: Array = []
	var n := 8
	for i in n:
		var z := -0.5 + (i + 0.5) / n
		boxes.append([Vector3(0, 0.02, z), Vector3(0.84, 0.04, 1.0 / n), LINE_A if i % 2 == 0 else LINE_B])
	for sx in [-1.0, 1.0]:
		boxes.append([Vector3(0.46 * sx, 0.02, 0), Vector3(0.08, 0.04, 1.0), LINE_EDGE])
	return _cached(&"line", boxes, true)
