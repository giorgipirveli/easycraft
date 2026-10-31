class_name BuildTableRules
extends RefCounted
## Owner #110, VR round 4 idea 5 (VR-HANDS; docs/devlog/parts/vr-r4-hands.md, the research §5.3 "Build with your hands:
## the Build Table", ruling R5): the Build Table's grid as pure rules. A table at hand height with CELL-sized blocks,
## FREE_SIZE a side (My Stamps' 16-a-side cap, MyStampBook.MAX_SIDE). The table's space is the world's for a child
## facing -Z: x to the child's right, y up from the top, z towards the child (the far row z = 0), in the child's metres;
## a cell is Vector3i(x, y, z). A block goes only where it stands on the table or touches another (a School board's cell
## anywhere on its board). The build turns in quarter turns (counter-clockwise seen from above for a positive one),
## mirrors across the middle column, and becomes a stamp (x to the child's right, z away, the nearest row at z = 0,
## centred: PowerTools' stamp space). The School's "build the answer" boards (BuildCheck) sit on it: a "wall" with its
## columns across and rows up, a "farm" seen from above with its row 0 nearest the child.

const CELL := 0.1
const SIDE := 16
const FREE_SIZE := Vector3i(SIDE, SIDE, SIDE)
const NO_CELL := Vector3i(-1, -1, -1)
## The table opens this far ahead of the eyes (to its near edge) and this far under them (hand height); the child's hand
## on its rim moves it, its top kept between HEIGHT_MIN and HEIGHT_MAX under the eyes (no bending over a model).
const AHEAD := 0.25
const BELOW := 0.45
const HEIGHT_MIN := 0.2
const HEIGHT_MAX := 0.8
## A hand within this of the table's rim holds the table (the child's metres); its fingers this far past the volume
## still build.
const RIM := 0.07
const MARGIN := 0.04

const _SIDES: Array[Vector3i] = [Vector3i.LEFT, Vector3i.RIGHT, Vector3i.DOWN, Vector3i.UP, Vector3i.FORWARD,
	Vector3i.BACK]


## The cell holding the point `local` (the table's space, the child's metres) on a table of `size`, or NO_CELL.
static func cell_at(local: Vector3, size: Vector3i) -> Vector3i:
	var c := Vector3i((local / CELL).floor())
	return c if inside(c, size) else NO_CELL


static func inside(c: Vector3i, size: Vector3i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.z >= 0 and c.x < size.x and c.y < size.y and c.z < size.z


## Where a block goes for a hand at `local`: its empty cell, standing on the table (y = 0) or touching a block of
## `cells` (`supported` false: anywhere, a School board); NO_CELL when there is none or a block is there.
static func ghost_cell(local: Vector3, cells: Dictionary, size: Vector3i, supported: bool = true) -> Vector3i:
	var c := cell_at(local, size)
	if c == NO_CELL or cells.has(c):
		return NO_CELL
	if not supported or c.y == 0:
		return c
	for s in _SIDES:
		if cells.has(c + s):
			return c
	return NO_CELL


## The block a hand at `local` touches (its cell holds one), or NO_CELL.
static func touched(local: Vector3, cells: Dictionary, size: Vector3i) -> Vector3i:
	var c := cell_at(local, size)
	return c if c != NO_CELL and cells.has(c) else NO_CELL


## The cell across the table's middle column (the Mirror's twin).
static func mirrored(c: Vector3i, size: Vector3i) -> Vector3i:
	return Vector3i(size.x - 1 - c.x, c.y, c.z)


## `cells` turned `quarters` times round the table's middle (a positive quarter: counter-clockwise seen from above).
static func turned(cells: Dictionary, quarters: int, size: Vector3i) -> Dictionary:
	var out := cells
	for i in posmod(quarters, 4):
		var next := {}
		for c: Vector3i in out:
			next[Vector3i(c.z, c.y, size.x - 1 - c.x)] = out[c]
		out = next
	return out


## Quarter turns for two hands whose line turned `angle` (radians, positive counter-clockwise from above): one each 90°
## past the first 45°.
static func twist_quarters(angle: float) -> int:
	return int(roundi(rad_to_deg(angle) / 90.0)) if absf(rad_to_deg(angle)) >= 45.0 else 0


## The build in stamp space (x to the child's right, z away, standing on y = 0, the nearest row at z = 0, centred).
static func as_stamp(cells: Dictionary) -> Dictionary:
	return PowerTools.to_stamp(stamp_blocks(cells), Vector3i(0, 0, -1))


## The build as MyStampBook.add wants it with facing (0, 0, -1): the table's cells are already a child-facing-−Z world's.
static func stamp_blocks(cells: Dictionary) -> Dictionary:
	return cells.duplicate()

# --- The School's boards (BuildCheck's {cols, rows, block, view}) ---

static func board_size(board: Dictionary) -> Vector3i:
	var cols := clampi(int(board.get("cols", 1)), 1, SIDE)
	var rows := clampi(int(board.get("rows", 1)), 1, SIDE)
	return Vector3i(cols, 1, rows) if str(board.get("view", "wall")) == "farm" else Vector3i(cols, rows, 1)


## A table cell as the board's Vector2i (a wall: x, y; a farm: x, its row from the nearest).
static func board_cell(c: Vector3i, board: Dictionary) -> Vector2i:
	if str(board.get("view", "wall")) == "farm":
		return Vector2i(c.x, board_size(board).z - 1 - c.z)
	return Vector2i(c.x, c.y)


static func table_cell(b: Vector2i, board: Dictionary) -> Vector3i:
	if str(board.get("view", "wall")) == "farm":
		return Vector3i(b.x, 0, board_size(board).z - 1 - b.y)
	return Vector3i(b.x, b.y, 0)
