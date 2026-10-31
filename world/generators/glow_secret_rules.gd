class_name GlowSecretRules
extends SecretRules
## Where universe 6, the Glow Caves, hides its secrets (spec §5.7 and §12.16 adapted; brief: hidden chests behind fake
## walls, a riddle note, a hidden grotto). The five kinds of Green Meadows' SecretRules, built the caves' way with the
## same ids, finds, chests and plates (so the SecretDirector plays them unchanged):
## - buried treasure: an X of glowing cave pearls on the cavern floor, the chest 2-4 blocks under it;
## - a hidden room under the floor: cave stone walls, a fungus-plank floor, spore lamps, stairs down from the floor that
##   end at a door of fake cave stone (a riddle note in some);
## - the puzzle temple: a flowstone hall under a high ceiling with its three plates, the note, the golden door and the
##   vault, a cave gold tip on its roof, spore lamps;
## - a hidden grotto (the ISLAND kind's place in the caves): a rock mound on the floor with a door of fake cave stone in
##   its face; stairs inside it go down to a round grotto under the floor with a glow-worm ceiling, a little pool of
##   glowing cave pearls and the golden chest;
## - a selenite geode under the floor with cave gold and diamonds in its shell.
## The treasure pack's places come in the caves' blocks (TreasurePlaces' GLOW style). Each is tried at the drawn spot
## and a few round it and kept only where it fits its cave (fits()): every column under it is open floor (no wall, no
## daylight shaft, no lake) and nothing reaches up into a ceiling.

const GLOW_ATTEMPTS := [[TREASURE, 0.8], [TREASURE, 0.6], [ROOM, 0.6], [TEMPLE, 0.5], [ISLAND, 0.6], [GEODE, 0.55]]
const PROBES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(12, 0), Vector2i(-12, 0), Vector2i(0, 12), Vector2i(0, -12),
	Vector2i(10, 10), Vector2i(-10, -10), Vector2i(10, -10), Vector2i(-10, 10)]
## The meadows kinds' blocks the caves' way.
const RESTYLE := {BlockIds.STONE: BlockIds.CAVE_STONE, BlockIds.PLANKS: BlockIds.FUNGUS_PLANKS,
	BlockIds.LIGHT: BlockIds.SPORE_LAMP, BlockIds.FAKE_WALL: BlockIds.FAKE_CAVE_STONE, BlockIds.BRICK: BlockIds.FLOWSTONE,
	BlockIds.GOLD: BlockIds.CAVE_GOLD, BlockIds.SAND: BlockIds.CAVE_PEARL}
const FIT_STEP := 2               # fits() looks at every other column (and the far edges)
const MOUND := 5                  # a grotto's mound: this long along its way ...
const GROTTO_STEPS := 8           # ... its stairs go down this many steps ...
const GROTTO_R := 4               # ... to a round grotto this wide
const GEODE_COVER := 3

var glow: GlowShape
## The Cave Wonders (one per area): every secret keeps GAP blocks off its area's wonder.
var wonders: GlowWonders


func _init(world_seed: int, terrain: MeadowsShape = null) -> void:
	glow = terrain as GlowShape if terrain is GlowShape else GlowShape.new(world_seed)
	wonders = GlowWonders.new(world_seed, glow)
	super(world_seed, glow, true, false)


## SecretRules' rule, and off the area's Cave Wonder.
func _fits(s: Dictionary, area: Vector2i, others: Array) -> bool:
	if not super(s, area, others):
		return false
	var w := wonders.footprint(area)
	if w.size == Vector2i.ZERO:
		return true
	var lo: Vector3i = s.lo
	var hi: Vector3i = s.hi
	return not (lo.x - GAP < w.end.x and w.position.x < hi.x + GAP and lo.z - GAP < w.end.y and w.position.y < hi.z + GAP)


func _attempts() -> Array:
	return GLOW_ATTEMPTS


## The drawn spot, or one of a few round it, where the kind fits its cave.
func _build(kind: StringName, x: int, z: int, v: int) -> Dictionary:
	if not PLACED.has(kind):
		var pack := super(kind, x, z, v)   # the treasure pack's places: in the caves' blocks, fitting their caves
		return pack if not pack.is_empty() and fits(pack.boxes) else {}
	for off in PROBES:
		var s := _make(kind, x + off.x, z + off.y, v)
		if not s.is_empty() and fits(s.boxes):
			return s
	return {}


func _make(kind: StringName, x: int, z: int, v: int) -> Dictionary:
	match kind:
		TREASURE:
			return _restyle(_treasure(x, z, v))
		ROOM:
			return _restyle(_room(x, z, v))
		TEMPLE:
			return _restyle(_temple(x, z, v))
		ISLAND:
			return _grotto(x, z, v)
		GEODE:
			return _cave_geode(x, z, v)
	return {}


## The meadows kinds' blocks swapped for the caves' (RESTYLE).
static func _restyle(s: Dictionary) -> Dictionary:
	if s.is_empty():
		return s
	var boxes: Array = []
	for b: Array in s.boxes:
		boxes.append([b[0], b[1], RESTYLE.get(b[2], b[2])])
	s.boxes = boxes
	return s


## Every column under the boxes (every FIT_STEP-th, and the far edges) is open, dry cavern floor outside the shafts,
## and the boxes' top stays under its ceiling.
func fits(boxes: Array) -> bool:
	var lo := Vector3i(0x7fffffff, 0x7fffffff, 0x7fffffff)
	var hi := -lo
	for b: Array in boxes:
		lo = lo.min(b[0])
		hi = hi.max(b[1])
	var xs := _steps(lo.x, hi.x - 1)
	for z in _steps(lo.z, hi.z - 1):
		for x in xs:
			var c := glow.column(x, z)
			if c.x == c.y or c.y >= c.z or c.x <= GlowShape.LAKE_LEVEL + 1 or hi.y > c.y:
				return false
	return true


static func _steps(a: int, b: int) -> Array[int]:
	var out: Array[int] = []
	for v in range(a, b, FIT_STEP):
		out.append(v)
	out.append(b)
	return out


## A hidden grotto: a rock mound on the cavern floor (MOUND along `dir`, three wide, three high) with a two-block door
## of fake cave stone in its face; a passage inside it and GROTTO_STEPS steps down under the floor (the mound roofs the
## first ones) to a round grotto: four high, GROTTO_R across, a glow-worm ceiling, glow moss on its floor, a little pool
## with glowing cave pearls on its bottom, two small glowshrooms and the golden chest. Every column of it must have the
## cavern floor at least as high as the grotto needs (three blocks of rock over its ceiling).
func _grotto(x: int, z: int, v: int) -> Dictionary:
	var h := glow.height_at(x, z)
	if not _dry(x, z, h):
		return {}
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var c := Vector3i(x, h, z)
	var f := h - GROTTO_STEPS - 1               # the grotto's floor block
	var mid := c + dir * (MOUND + GROTTO_STEPS + GROTTO_R - 3)
	for along in range(0, MOUND + GROTTO_STEPS + 2 * GROTTO_R):
		for across in [-GROTTO_R, 0, GROTTO_R]:
			var col: Vector3i = c + dir * along + side * across
			var hc := glow.height_at(col.x, col.z)
			if hc < h - 1 or hc > h + 2:
				return {}                      # the floor dips over the grotto, or a slope is in the way
	var boxes: Array = []
	_box(boxes, _at(c, dir, side, 0, -1, 0), _at(c, dir, side, MOUND - 1, 1, 2), BlockIds.CAVE_STONE)   # the mound
	var door: Array[Vector3i] = [c, c + Vector3i.UP]
	_box(boxes, door[0], door[1], BlockIds.FAKE_CAVE_STONE)
	_box(boxes, _at(c, dir, side, 1, 0, 0), _at(c, dir, side, 1, 0, 1), BlockIds.AIR)                    # the landing
	for k in range(1, GROTTO_STEPS + 1):
		var sy := h - k
		var step := _at(c, dir, side, 1 + k, 0, 0)
		_box(boxes, Vector3i(step.x, sy - 1, step.z) - side, Vector3i(step.x, sy - 1, step.z) + side, BlockIds.CAVE_STONE)
		_box(boxes, Vector3i(step.x, sy, step.z), Vector3i(step.x, sy + 2, step.z), BlockIds.AIR)
	var r := GROTTO_R
	_cylinder(boxes, mid, r + 1, f - 1, f + 5, BlockIds.CAVE_STONE)      # its rock
	_cylinder(boxes, mid, r, f, f, BlockIds.GLOW_MOSS)                   # a glowing floor
	_cylinder(boxes, mid, r, f + 1, f + 4, BlockIds.AIR)
	_cylinder(boxes, mid, r, f + 5, f + 5, BlockIds.GLOW_WORMS)          # a starry ceiling of glow-worms
	var pool := mid + side * 2 + dir
	_cylinder(boxes, pool, 1, f - 1, f - 1, BlockIds.CAVE_PEARL)
	_cylinder(boxes, pool, 1, f, f, BlockIds.WATER)
	for s: int in [-1, 1]:
		var shroom := mid - dir * 2 + side * (3 * s)
		_box(boxes, shroom + Vector3i(0, f + 1 - mid.y, 0), shroom + Vector3i(0, f + 1 - mid.y, 0), BlockIds.SHROOM_STEM)
		_box(boxes, shroom + Vector3i(0, f + 2 - mid.y, 0), shroom + Vector3i(0, f + 2 - mid.y, 0),
			BlockIds.BLUE_SHROOM if s < 0 else BlockIds.ROSE_SHROOM)
	var chest := Vector3i(mid.x, f + 1, mid.z) - side * 2
	return {"anchor": chest, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(-dir), "boxes": boxes,
		"fake_wall": door, "dir": dir,
		"inside": [Vector3i(mid.x - r + 1, f + 1, mid.z - r + 1), Vector3i(mid.x + r, f + 5, mid.z + r)]}


## Rows of boxes filling a round disc of radius r round `mid` from height y0 to y1.
static func _cylinder(boxes: Array, mid: Vector3i, r: int, y0: int, y1: int, id: int) -> void:
	for dz in range(-r, r + 1):
		var hw := int(sqrt((r + 0.5) * (r + 0.5) - dz * dz))
		boxes.append([Vector3i(mid.x - hw, y0, mid.z + dz), Vector3i(mid.x + hw + 1, y1 + 1, mid.z + dz + 1), id])


## A selenite geode under the floor (GEODE_COVER or more of rock over its shell), cave gold and diamonds in its shell.
func _cave_geode(x: int, z: int, v: int) -> Dictionary:
	var r := 4 + v % 2
	var h := glow.height_at(x, z)
	if not _dry(x, z, h):
		return {}
	for q: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
		var hq := glow.height_at(x + q.x, z + q.y)
		if hq <= MeadowsShape.SEA_LEVEL + 1:
			return {}
		h = mini(h, hq)
	var c := Vector3i(x, h - 1 - GEODE_COVER - r - (v >> 1) % 3, z)
	var boxes: Array = []
	_ball(boxes, c, r, BlockIds.SELENITE)
	_ball(boxes, c, r - 1, BlockIds.AIR)
	var axes: Array[Vector3i] = [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r),
		Vector3i(0, -r, 0), Vector3i(0, r, 0)]
	for i in 3:
		var stud := c + axes[(v >> (4 + i * 3)) % axes.size()]
		_box(boxes, stud, stud, BlockIds.CAVE_GOLD if i == 0 else BlockIds.DIAMOND)
	return {"anchor": c, "radius": r, "boxes": boxes,
		"inside": [c - Vector3i(r - 2, r - 2, r - 2), c + Vector3i(r - 1, r - 1, r - 1)]}
