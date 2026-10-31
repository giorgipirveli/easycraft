class_name DragonSecretRules
extends SecretRules
## Where the Dragon Realm hides its secrets (owner feedback #39, spec §14.2a and §12.16 adapted): the five kinds of
## Green Meadows' SecretRules, built the realm's way, with the same ids, finds, chests and plates (so the
## SecretDirector plays them unchanged), and never over the void where they would hang wrongly:
## - buried treasure: an X of ember scales on the sky grass, the chest 2-4 blocks under it, in the island's rock;
## - a hidden room (ROOM) inside an island: a floatstone-brick room with moon lamps ROOM_DEPTH under the moss, stairs
##   up to the top that end at a door of fake floatstone;
## - a sky shrine (TEMPLE, the puzzle temple): floatstone-brick walls with starglass windows, a stepped roof of dragon
##   and ember scales with dragon gold on top; inside, the three pressure plates, the note and the vault behind the
##   golden door;
## - a dragon nest (ISLAND): a small floating island of its own just off a bigger one's edge, level with it (a short
##   bridge away), dragon gold in its side, a nest of twigs and scales on top with a DRAGON EGG's cell in it (the
##   extra field "egg": the air cell on the nest where the egg lies, standing on a nest block, inside `inside`) and
##   the golden chest beside it;
## - an amethyst geode inside a thick island: a hollow ball of crystal spire with diamonds and dragon gold in its shell.
## The treasure pack's places (owner 42) come in the realm's blocks (TreasurePlaces' DRAGON style). Every secret but
## the nest stands on an island: every column under it is island rock reaching below its lowest block (grounded()).
## Every secret stays inside its 128 x 128 area; chosen from the seed and the area alone.

const DRAGON_ATTEMPTS := [[TREASURE, 0.8], [TREASURE, 0.6], [ROOM, 0.6], [TEMPLE, 0.45], [ISLAND, 0.55], [GEODE, 0.5]]
## Spots tried round the drawn one until one fits (islands cover a third of the sky).
const PROBES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(14, 0), Vector2i(-14, 0), Vector2i(0, 14), Vector2i(0, -14),
	Vector2i(12, 12), Vector2i(-12, -12), Vector2i(12, -12), Vector2i(-12, 12)]
const GROUND_STEP := 2            # grounded() looks at every other column (and the edges)
const SHRINE_HALF := 5            # the sky shrine: 11 x 11
const SHRINE_FLAT := 3            # its footprint's ground may rise and fall this much
const NEST_REACH := 8             # a nest island floats at most this far from a bigger island's edge
const NEST_RISE := 3              # ... its top level with that island's or up to NEST_RISE - 1 higher
const GEODE_COVER := 3            # rock over a geode's shell at least
## A nest island's layers from its top down.
const NEST_LAYERS: Array[int] = [BlockIds.SKY_GRASS, BlockIds.FLOATSTONE, BlockIds.FLOATSTONE, BlockIds.DEEP_FLOATSTONE,
	BlockIds.DEEP_FLOATSTONE, BlockIds.DEEP_FLOATSTONE]

var dragon: DragonShape


func _init(world_seed: int, terrain: MeadowsShape = null) -> void:
	dragon = terrain as DragonShape if terrain is DragonShape else DragonShape.new(world_seed)
	super(world_seed, dragon)


func _attempts() -> Array:
	return DRAGON_ATTEMPTS


## The drawn spot, or one of a few round it, where the kind fits and (but a nest) stands on an island.
func _build(kind: StringName, x: int, z: int, v: int) -> Dictionary:
	if not PLACED.has(kind):
		var pack := super(kind, x, z, v)   # the treasure pack's places: in the realm's blocks, grounded
		return pack if not pack.is_empty() and grounded(pack.boxes) else {}
	for off in PROBES:
		var s := super(kind, x + off.x, z + off.y, v)
		if s.is_empty():
			continue
		if kind == ISLAND or grounded(s.boxes):
			return s
	return {}


## Every column under the boxes (every GROUND_STEP-th, and the far edges) is island rock whose underside lies below
## the lowest box: nothing hangs over the void or pokes out of an island's bottom.
func grounded(boxes: Array) -> bool:
	var lo := Vector3i(0x7fffffff, 0x7fffffff, 0x7fffffff)
	var hi := -lo
	for b: Array in boxes:
		lo = lo.min(b[0])
		hi = hi.max(b[1])
	var xs := _steps(lo.x, hi.x - 1)
	for z in _steps(lo.z, hi.z - 1):
		for x in xs:
			var c := dragon.column(x, z)
			if c.x <= c.y or c.y >= lo.y:
				return false
	return true


static func _steps(a: int, b: int) -> Array[int]:
	var out: Array[int] = []
	for v in range(a, b, GROUND_STEP):
		out.append(v)
	out.append(b)
	return out


func _on_island(x: int, z: int) -> bool:
	return dragon.is_island(x, z)


## Buried treasure: an X of ember scales on open sky grass, and room for a chest 2 to 4 blocks under it.
func _treasure(x: int, z: int, v: int) -> Dictionary:
	if not _on_island(x, z) or dragon.tree_at(x, z):
		return {}
	var boxes: Array = []
	for c in X_CELLS:
		var col := dragon.column(x + c.x, z + c.y)
		if col.x <= col.y or dragon.tree_at(x + c.x, z + c.y):
			return {}
		var cell := Vector3i(x + c.x, col.x - 1, z + c.y)
		_box(boxes, cell, cell, BlockIds.EMBER_SCALE)
	var chest := Vector3i(x, dragon.height_at(x, z) - 3 - v % 3, z)
	_box(boxes, chest, chest, BlockIds.AIR)
	return {"anchor": chest, "chest": chest, "chest_kind": &"buried", "yaw": _yaw(DIRS[(v >> 2) % 4]), "boxes": boxes}


## A hidden room: a floatstone-brick room with a moon lamp in every corner and a chest, ROOM_DEPTH under the moss,
## walled in the island's rock. Floatstone stairs lead down to it from the top and end at a fake floatstone door
## (two blocks, a door's size); every stair column is island (the stairs never open into the void).
func _room(x: int, z: int, v: int) -> Dictionary:
	if not _on_island(x, z):
		return {}
	var h := dragon.height_at(x, z)
	var f := h - ROOM_DEPTH
	for c: Vector2i in [Vector2i(-3, -3), Vector2i(3, -3), Vector2i(-3, 3), Vector2i(3, 3)]:
		if not _on_island(x + c.x, z + c.y) or dragon.height_at(x + c.x, z + c.y) < f + 7:
			return {}            # the room would poke out of the island
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, c + Vector3i(-3, 0, -3), c + Vector3i(3, 4, 3), BlockIds.FLOATSTONE)
	_box(boxes, c + Vector3i(-2, 0, -2), c + Vector3i(2, 0, 2), BlockIds.FLOATSTONE_BRICK)
	_box(boxes, c + Vector3i(-2, 1, -2), c + Vector3i(2, 3, 2), BlockIds.AIR)
	for lamp: Vector3i in [Vector3i(-2, 4, -2), Vector3i(2, 4, -2), Vector3i(-2, 4, 2), Vector3i(2, 4, 2)]:
		_box(boxes, c + lamp, c + lamp, BlockIds.MOON_LAMP)
	var fake: Array[Vector3i] = [c + dir * 3 + Vector3i(0, 1, 0), c + dir * 3 + Vector3i(0, 2, 0)]
	_box(boxes, fake[0], fake[1], BlockIds.FAKE_FLOATSTONE)
	var top := Vector3i.ZERO
	var k := 1
	while true:
		var col := c + dir * (3 + k)
		var fy := f if k <= 2 else f + k - 2
		if not _on_island(col.x, col.z) or not _on_island(col.x + side.x, col.z + side.z) \
				or not _on_island(col.x - side.x, col.z - side.z):
			return {}            # the stairs would run out over the void
		var hc := dragon.height_at(col.x, col.z)
		if fy >= hc:
			break                # out in the open: the stairs are done
		if k > ROOM_STEPS:
			return {}
		_box(boxes, Vector3i(col.x, fy, col.z) - side, Vector3i(col.x, mini(fy + 4, hc - 1), col.z) + side, BlockIds.FLOATSTONE)
		_box(boxes, Vector3i(col.x, fy + 1, col.z), Vector3i(col.x, fy + 3, col.z), BlockIds.AIR)
		top = Vector3i(col.x, fy, col.z)
		k += 1
	var s := {"anchor": c + Vector3i(0, 1, 0), "chest": c + Vector3i(0, 1, 0) - dir * 2, "chest_kind": &"room",
		"yaw": _yaw(dir), "boxes": boxes, "fake_wall": fake, "stairs_top": top, "dir": dir,
		"inside": [c + Vector3i(-2, 1, -2), c + Vector3i(3, 4, 3)]}
	if (v >> 2) % 2 == 0:
		var note := Riddles.room_note(v >> 3)
		s.note = {"cell": c + Vector3i(0, 1, 0) - dir * 2 + side * 2, "text": note.text, "pictures": note.pictures,
			"yaw": _yaw(dir)}
	return s


## A sky shrine on flat sky grass (the realm's puzzle temple): floatstone-brick walls with starglass windows on a
## foundation, a stepped roof of dragon and ember scales with dragon gold on top; the three plates and the note
## inside, and the vault behind the golden door.
func _temple(x: int, z: int, v: int) -> Dictionary:
	var n := SHRINE_HALF
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	for dz in [-n, 0, n]:
		for dx in [-n, 0, n]:
			var col := dragon.column(x + dx, z + dz)
			if col.x <= col.y:
				return {}
			lo = mini(lo, col.x)
			hi = maxi(hi, col.x)
	if hi - lo > SHRINE_FLAT:
		return {}                # too steep
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var f := dragon.height_at(x, z) - 1
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, Vector3i(x - n, lo - 3, z - n), Vector3i(x + n, f + 5, z + n), BlockIds.FLOATSTONE_BRICK)   # foundation, walls
	_box(boxes, Vector3i(x - n, f + 6, z - n), Vector3i(x + n, f + 10, z + n), BlockIds.AIR)                # nothing on the roof
	_box(boxes, Vector3i(x - n, f + 5, z - n), Vector3i(x + n, f + 5, z + n), BlockIds.DRAGON_SCALE)      # a stepped roof ...
	_box(boxes, Vector3i(x - n + 1, f + 6, z - n + 1), Vector3i(x + n - 1, f + 6, z + n - 1), BlockIds.EMBER_SCALE)
	_box(boxes, Vector3i(x - n + 3, f + 7, z - n + 3), Vector3i(x + n - 3, f + 7, z + n - 3), BlockIds.DRAGON_SCALE)
	_box(boxes, Vector3i(x, f + 8, z), Vector3i(x, f + 8, z), BlockIds.DRAGON_GOLD)                      # ... with dragon gold
	for k in 4:                                                                                         # moon lamps at its corners
		var corner := Vector3i(x + (n - 1) * (1 if k % 2 == 0 else -1), f + 7, z + (n - 1) * (1 if k < 2 else -1))
		_box(boxes, corner, corner, BlockIds.MOON_LAMP)
	_box(boxes, Vector3i(x - n + 1, f, z - n + 1), Vector3i(x + n - 1, f, z + n - 1), BlockIds.FLOATSTONE_BRICK)   # the floor
	_box(boxes, Vector3i(x - n + 1, f + 1, z - n + 1), Vector3i(x + n - 1, f + 4, z + n - 1), BlockIds.AIR)
	for s: int in [-1, 1]:                                                                              # starglass windows
		_box(boxes, _at(c, dir, side, 1, s * n, 2), _at(c, dir, side, 2, s * n, 3), BlockIds.STARGLASS)
	_box(boxes, _at(c, dir, side, -2, -(n - 1), 1), _at(c, dir, side, -2, n - 1, 4), BlockIds.FLOATSTONE_BRICK)   # the vault's wall
	var vault: Array[Vector3i] = [_at(c, dir, side, -2, 0, 1), _at(c, dir, side, -2, 0, 2)]
	_box(boxes, vault[0], vault[1], BlockIds.YELLOW)   # a bright "golden" door (the Meadows temple's)
	_box(boxes, _at(c, dir, side, n, -1, 1), _at(c, dir, side, n + 2, 1, 4), BlockIds.AIR)            # door and way in
	for lamp: Vector3i in [_at(c, dir, side, n - 1, -(n - 1), 4), _at(c, dir, side, n - 1, n - 1, 4),
			_at(c, dir, side, -1, -(n - 1), 4), _at(c, dir, side, -1, n - 1, 4), _at(c, dir, side, -n + 2, 0, 4),
			_at(c, dir, side, n, -2, 3), _at(c, dir, side, n, 2, 3)]:
		_box(boxes, lamp, lamp, BlockIds.MOON_LAMP)
	var plates: Array[Vector3i] = []
	for s: int in [-2, 0, 2]:
		var p := _at(c, dir, side, 1, s, 1)
		_box(boxes, p, p, BlockIds.PRESSURE_PLATE)
		plates.append(p)
	var symbols := _permutation(Riddles.TEMPLE_SYMBOLS, v >> 2)
	var order := _permutation([0, 1, 2], v >> 5)
	var pictures: Array[int] = [symbols[order[0]], symbols[order[1]], symbols[order[2]]]
	return {"anchor": c + Vector3i(0, 1, 0), "chest": _at(c, dir, side, -3, 0, 1), "chest_kind": &"temple",
		"locked": true, "yaw": _yaw(dir), "boxes": boxes, "plates": plates, "symbols": symbols, "order": order,
		"vault": vault, "dir": dir, "tip": Vector3i(x, f + 8, z),
		"note": {"cell": _at(c, dir, side, 3, -3, 1), "text": Riddles.TEMPLE_TEXT, "pictures": pictures, "yaw": _yaw(dir)},
		"inside": [Vector3i(x - n + 1, f + 1, z - n + 1), Vector3i(x + n, f + 5, z + n)]}


## A dragon nest: a small round island floating in the void just off a bigger island (at most NEST_REACH from its
## edge, its top level with it or a little higher: a short bridge away), sky grass over floatstone tapering to deep floatstone,
## dragon gold in its side. On top a nest of woven twigs (a 3 x 3 floor, a ring one higher) with two scales in its
## rim; the egg's cell is the nest's hollow (air, on the middle nest block); the golden chest stands beside it.
func _island(x: int, z: int, v: int) -> Dictionary:
	var r := 3 + v % 2
	for dz in range(-r - 1, r + 2):
		for dx in range(-r - 1, r + 2):
			if _on_island(x + dx, z + dz):
				return {}        # a nest island floats on its own, clear of the others
	var neighbour := -1
	for ring in range(r + 2, r + 2 + NEST_REACH + 1, 2):
		for i in 12:
			var a := TAU * i / 12.0
			var q := Vector2i(x + roundi(cos(a) * ring), z + roundi(sin(a) * ring))
			var col := dragon.column(q.x, q.y)
			if col.x > col.y:
				neighbour = maxi(neighbour, col.x)
		if neighbour >= 0:
			break
	if neighbour < 0:
		return {}                # nothing near: out of a child's reach
	var top := neighbour + (v >> 2) % NEST_RISE
	var boxes: Array = []
	for k in NEST_LAYERS.size():
		_disc(boxes, Vector3i(x, top - k, z), r if k <= 1 else maxi(r - (k - 1), 1), NEST_LAYERS[k])
	var gz := z + (v >> 5) % 3 - 1
	_box(boxes, Vector3i(x - r, top - 1, gz), Vector3i(x - r, top - 1, gz), BlockIds.DRAGON_GOLD)
	_box(boxes, Vector3i(x - 1, top + 1, z - 1), Vector3i(x + 1, top + 1, z + 1), BlockIds.NEST)       # the nest's floor
	_box(boxes, Vector3i(x - 1, top + 2, z - 1), Vector3i(x + 1, top + 2, z + 1), BlockIds.NEST)       # its rim
	var scale_a := Vector3i(x + DIRS[(v >> 7) % 4].x, top + 2, z + DIRS[(v >> 7) % 4].z)
	var scale_b := Vector3i(x - 1, top + 2, z + 1)
	_box(boxes, scale_a, scale_a, BlockIds.DRAGON_SCALE)
	_box(boxes, scale_b, scale_b, BlockIds.EMBER_SCALE)
	var egg := Vector3i(x, top + 2, z)
	_box(boxes, egg, egg + Vector3i(0, 2, 0), BlockIds.AIR)                                             # the egg's hollow
	var chest := Vector3i(x + 2, top + 1, z)
	_box(boxes, chest, chest + Vector3i(0, 1, 0), BlockIds.AIR)
	return {"anchor": chest, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(Vector3i(-1, 0, 0)), "boxes": boxes,
		"egg": egg, "inside": [Vector3i(x - r, top + 1, z - r), Vector3i(x + r + 1, top + 5, z + r + 1)]}


## An amethyst geode inside a thick island: a hollow ball of crystal spire with diamonds and dragon gold in its shell,
## GEODE_COVER or more under the moss and above the island's underside.
func _geode(x: int, z: int, v: int) -> Dictionary:
	var r := 4 + v % 2
	if not _on_island(x, z):
		return {}
	var h := dragon.height_at(x, z)
	for q: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
		if not _on_island(x + q.x, z + q.y):
			return {}
		h = mini(h, dragon.height_at(x + q.x, z + q.y))
	var c := Vector3i(x, h - 1 - GEODE_COVER - r - (v >> 1) % 3, z)
	var boxes: Array = []
	_ball(boxes, c, r, BlockIds.CRYSTAL_SPIRE)
	_ball(boxes, c, r - 1, BlockIds.AIR)
	var axes: Array[Vector3i] = [Vector3i(r, 0, 0), Vector3i(-r, 0, 0), Vector3i(0, 0, r), Vector3i(0, 0, -r),
		Vector3i(0, -r, 0), Vector3i(0, r, 0)]
	for i in 3:
		var stud := c + axes[(v >> (4 + i * 3)) % axes.size()]
		_box(boxes, stud, stud, BlockIds.DRAGON_GOLD if i == 0 else BlockIds.DIAMOND)
	return {"anchor": c, "radius": r, "boxes": boxes,
		"inside": [c - Vector3i(r - 2, r - 2, r - 2), c + Vector3i(r - 1, r - 1, r - 1)]}
