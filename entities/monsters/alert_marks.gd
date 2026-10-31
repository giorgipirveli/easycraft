class_name AlertMarks
extends RefCounted
## The "?" and "!" that float over a monster's head (M2 Task 5, spec §12.5): a question mark while it
## is suspicious or searching, an exclamation mark while it sees you. Pixel letters built from little
## boxes, each with a dark back for contrast, into one mesh per mark, made once and shared by every
## monster. They use BlockyAnimal's vertex-colour material, so no new shader ever compiles (DEVELOPMENT.md
## §8: per-event materials made 100+ ms frames).

const PIXEL := 0.09               # metres per letter pixel
const DEPTH := 0.05
const QUESTION := Color("ffd23f")  # "?" warm yellow
const BANG := Color("ff5a36")      # "!" red-orange; the shapes differ too (never colour alone)
const BACK := Color("1c1c20")

## 5 x 7 pixel letters, top row first.
const GLYPHS := {
	StealthRules.MARK_QUESTION: [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	StealthRules.MARK_BANG: ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
}

static var _meshes := {}


## The shared mesh of a mark (StealthRules.MARK_QUESTION or MARK_BANG), centred, facing +Z; null for
## MARK_NONE.
static func mesh(mark: int) -> ArrayMesh:
	if not GLYPHS.has(mark):
		return null
	if not _meshes.has(mark):
		_meshes[mark] = BlockyAnimal._build(boxes(mark))
	return _meshes[mark]


## The letter's boxes: [center, size, colour] (a dark back box behind every pixel).
static func boxes(mark: int) -> Array:
	var rows: Array = GLYPHS[mark]
	var color := QUESTION if mark == StealthRules.MARK_QUESTION else BANG
	var out: Array = []
	for r in rows.size():
		var row: String = rows[r]
		for c in row.length():
			if row[c] != "#":
				continue
			var at := Vector3((c - 2) * PIXEL, (rows.size() * 0.5 - r - 0.5) * PIXEL, 0.0)
			out.append([at - Vector3(0, 0, DEPTH * 0.5), Vector3(PIXEL * 1.6, PIXEL * 1.6, DEPTH * 0.5), BACK])
			out.append([at, Vector3(PIXEL, PIXEL, DEPTH), color])
	return out
