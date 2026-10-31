class_name DesertSecretRules
extends SecretRules
## Where the Sandstorm Desert hides its secrets (M3 Task 2, spec §14.1 and §12.16 adapted): the five kinds
## of Green Meadows' SecretRules, built the desert way, with the same ids, finds, chests and plates (so the
## SecretDirector plays them unchanged):
## - buried treasure: a red-sand X on the open sand, the chest 2-4 blocks under it;
## - a hidden room (ROOM) inside a mesa, reached by a tunnel from a fake sandstone wall in its side;
## - a pyramid (TEMPLE): a stepped sandstone pyramid with a golden tip; the way in has two arrow slits
##   (DesertTraps shoots darts, signalled first) and a sand pit under a lid of trap sand; the chamber has
##   the three pressure plates and the note, and the treasure room waits behind a golden door the plates
##   open (the temple's puzzle);
## - a floating mesa (ISLAND) with a golden chest on top;
## - a crystal geode deep underground (Green Meadows' own).
## Every secret stays inside its 128 x 128 area; chosen from the seed and the area alone.

const DESERT_ATTEMPTS := [[TREASURE, 0.8], [TREASURE, 0.5], [ROOM, 0.7], [TEMPLE, 0.5], [ISLAND, 0.2], [GEODE, 0.5]]
const PYRAMID_HALF := 10          # 21 x 21 blocks at the bottom, 11 steps up to the golden tip
const PYRAMID_FLAT := 7           # its footprint's ground may rise and fall this much
const CHAMBER := 3                # the chamber: 7 x 7, 4 high
const ROOM_RISE := 10             # a mesa this much above its floor can hold a room
const ROOM_REACH := 28            # the tunnel from the room to the mesa's side is at most this long
const ROOM_PROBES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(24, 0), Vector2i(-24, 0), Vector2i(0, 24),
	Vector2i(0, -24), Vector2i(24, 24), Vector2i(-24, -24), Vector2i(24, -24), Vector2i(-24, 24)]

var desert: DesertShape


func _init(world_seed: int, terrain: MeadowsShape = null) -> void:
	desert = terrain as DesertShape if terrain is DesertShape else DesertShape.new(world_seed)
	super(world_seed, desert)


func _attempts() -> Array:
	return DESERT_ATTEMPTS


## Buried treasure: a red-sand X on the open sand, and room for a chest 2 to 4 blocks under it.
func _treasure(x: int, z: int, v: int) -> Dictionary:
	if desert.terrain_at(x, z) != DesertShape.DESERT or desert.tree_at(x, z):
		return {}
	var boxes: Array = []
	for c in X_CELLS:
		var col := desert.column(x + c.x, z + c.y)
		if col.y != DesertShape.DESERT:
			return {}
		var cell := Vector3i(x + c.x, col.x - 1, z + c.y)
		_box(boxes, cell, cell, BlockIds.RED_SAND)
	var chest := Vector3i(x, desert.height_at(x, z) - 3 - v % 3, z)
	_box(boxes, chest, chest, BlockIds.AIR)
	return {"anchor": chest, "chest": chest, "chest_kind": &"buried", "yaw": _yaw(DIRS[(v >> 2) % 4]), "boxes": boxes}


## A hidden room inside a mesa: the drawn spot, or one of a few around it, must be a tall mesa.
func _room(x: int, z: int, v: int) -> Dictionary:
	for off in ROOM_PROBES:
		var s := _mesa_room(x + off.x, z + off.y, v)
		if not s.is_empty():
			return s
	return {}


## A sandstone room with lamps and a chest in a mesa's body, level with the desert outside; a tunnel leads
## out to a fake sandstone wall (two blocks, a door's size) in the mesa's side.
func _mesa_room(x: int, z: int, v: int) -> Dictionary:
	var col := desert.column(x, z)
	if col.y != DesertShape.MESA or col.x - col.z < ROOM_RISE:
		return {}
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var out := -1
	for k in range(CHAMBER + 1, ROOM_REACH + 1):
		if desert.terrain_at(x + dir.x * k, z + dir.z * k) != DesertShape.MESA:
			out = k
			break
	if out < 0:
		return {}
	var f := desert.height_at(x + dir.x * out, z + dir.z * out) - 1
	for c: Vector2i in [Vector2i(-3, -3), Vector2i(3, -3), Vector2i(-3, 3), Vector2i(3, 3), Vector2i.ZERO]:
		var cc := desert.column(x + c.x, z + c.y)
		if cc.y != DesertShape.MESA or cc.x < f + 7:
			return {}            # the room would poke out of the mesa
	for k in range(CHAMBER + 1, out):
		var cc := desert.column(x + dir.x * k, z + dir.z * k)
		if cc.x < f + 5:
			return {}            # the tunnel would poke out
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, c + Vector3i(-3, 0, -3), c + Vector3i(3, 5, 3), BlockIds.SANDSTONE)
	_box(boxes, c + Vector3i(-2, 0, -2), c + Vector3i(2, 0, 2), BlockIds.CUT_SANDSTONE)
	_box(boxes, c + Vector3i(-2, 1, -2), c + Vector3i(2, 3, 2), BlockIds.AIR)
	for lamp: Vector3i in [Vector3i(-2, 4, -2), Vector3i(2, 4, -2), Vector3i(-2, 4, 2), Vector3i(2, 4, 2)]:
		_box(boxes, c + lamp, c + lamp, BlockIds.DESERT_LAMP)
	_box(boxes, _at(c, dir, side, CHAMBER, -1, 0), _at(c, dir, side, out - 1, 1, 3), BlockIds.SANDSTONE)
	_box(boxes, _at(c, dir, side, CHAMBER, 0, 1), _at(c, dir, side, out - 2, 0, 2), BlockIds.AIR)
	var fake: Array[Vector3i] = [_at(c, dir, side, out - 1, 0, 1), _at(c, dir, side, out - 1, 0, 2)]
	_box(boxes, fake[0], fake[1], BlockIds.FAKE_SANDSTONE)
	var s := {"anchor": c + Vector3i(0, 1, 0), "chest": c + Vector3i(0, 1, 0) - dir * 2, "chest_kind": &"room",
		"yaw": _yaw(dir), "boxes": boxes, "fake_wall": fake, "stairs_top": fake[0] + dir, "dir": dir,
		"inside": [c + Vector3i(-2, 1, -2), c + Vector3i(3, 4, 3)]}
	if (v >> 2) % 2 == 0:
		var note := Riddles.room_note(v >> 3)
		s.note = {"cell": c + Vector3i(0, 1, 0) - dir * 2 + side * 2, "text": note.text, "pictures": note.pictures,
			"yaw": _yaw(dir)}
	return s


## A pyramid on open, fairly flat sand (see the class comment). c is the chamber's floor; `dir` points out
## of the entrance.
func _temple(x: int, z: int, v: int) -> Dictionary:
	var half := PYRAMID_HALF
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	for dz in [-half, 0, half]:
		for dx in [-half, 0, half]:
			var col := desert.column(x + dx, z + dz)
			if col.y != DesertShape.DESERT:
				return {}
			lo = mini(lo, col.x)
			hi = maxi(hi, col.x)
	if hi - lo > PYRAMID_FLAT:
		return {}
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var door := Vector2i(x + dir.x * (half + 2), z + dir.z * (half + 2))
	if desert.terrain_at(door.x, door.y) != DesertShape.DESERT:
		return {}
	var f := clampi(desert.height_at(door.x, door.y) - 1, lo - 1, hi - 1)
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, Vector3i(x - half, lo - 3, z - half), Vector3i(x + half, f, z + half), BlockIds.SANDSTONE)   # foundation
	for k in half + 1:                                                                                     # the steps
		var r := half - k
		var id := BlockIds.PYRAMID_GOLD if r == 0 else (BlockIds.CUT_SANDSTONE if k % 2 == 0 else BlockIds.SANDSTONE)
		_box(boxes, Vector3i(x - r, f + 1 + k, z - r), Vector3i(x + r, f + 1 + k, z + r), id)
	var n := CHAMBER
	_box(boxes, _at(c, dir, side, -n, -n, 0), _at(c, dir, side, n, n, 0), BlockIds.CHISELED_SANDSTONE)       # chamber floor
	_box(boxes, _at(c, dir, side, -n, -n, 1), _at(c, dir, side, n, n, 4), BlockIds.AIR)                    # the chamber
	_box(boxes, _at(c, dir, side, n + 1, -1, 1), _at(c, dir, side, half, 1, 3), BlockIds.AIR)              # the way in
	_box(boxes, _at(c, dir, side, half + 1, -1, 0), _at(c, dir, side, half + 3, 1, 0), BlockIds.SANDSTONE)  # a doorstep
	_box(boxes, _at(c, dir, side, half + 1, -1, 1), _at(c, dir, side, half + 3, 1, 4), BlockIds.AIR)       # dug out
	for s: int in [-2, 2]:                                                                                 # the doorway's frame
		_box(boxes, _at(c, dir, side, half, s, 1), _at(c, dir, side, half, s, 4), BlockIds.CHISELED_SANDSTONE)
	_box(boxes, _at(c, dir, side, half, -1, 4), _at(c, dir, side, half, 1, 4), BlockIds.CHISELED_SANDSTONE)
	_box(boxes, _at(c, dir, side, -n - 3, -1, 1), _at(c, dir, side, -n - 2, 1, 3), BlockIds.AIR)           # treasure room
	var vault: Array[Vector3i] = [_at(c, dir, side, -n - 1, 0, 1), _at(c, dir, side, -n - 1, 0, 2)]
	_box(boxes, vault[0], vault[1], BlockIds.YELLOW)                                                      # the golden door
	for lamp: Vector3i in [_at(c, dir, side, n + 1, -3, 3), _at(c, dir, side, n + 1, 3, 3), _at(c, dir, side, -n - 1, -3, 3),
			_at(c, dir, side, -n - 1, 3, 3), _at(c, dir, side, 0, -n - 1, 3), _at(c, dir, side, 0, n + 1, 3),
			_at(c, dir, side, 6, 0, 4), _at(c, dir, side, 9, 0, 4), _at(c, dir, side, -n - 2, 0, 4)]:
		_box(boxes, lamp, lamp, BlockIds.DESERT_LAMP)
	# Traps on the way in: two arrow slits at head height facing across it, a sand pit between them.
	var traps: Array = [{"cell": _at(c, dir, side, 5, -2, 2), "dir": side}, {"cell": _at(c, dir, side, 8, 2, 2), "dir": -side}]
	for t: Dictionary in traps:
		_box(boxes, t.cell, t.cell, BlockIds.ARROW_SLIT)
	_box(boxes, _at(c, dir, side, 6, -1, -1), _at(c, dir, side, 7, 1, -1), BlockIds.AIR)
	_box(boxes, _at(c, dir, side, 6, -1, 0), _at(c, dir, side, 7, 1, 0), BlockIds.TRAP_SAND)
	var pits: Array[Vector3i] = []
	for along in [6, 7]:
		for across in [-1, 0, 1]:
			pits.append(_at(c, dir, side, along, across, 0))
	var plates: Array[Vector3i] = []
	for s: int in [-2, 0, 2]:
		var p := _at(c, dir, side, 1, s, 1)
		_box(boxes, p, p, BlockIds.PRESSURE_PLATE)
		plates.append(p)
	var symbols := _permutation(Riddles.TEMPLE_SYMBOLS, v >> 2)
	var order := _permutation([0, 1, 2], v >> 5)
	var pictures: Array[int] = [symbols[order[0]], symbols[order[1]], symbols[order[2]]]
	var in_a := _at(c, dir, side, -n, -n, 1)
	var in_b := _at(c, dir, side, n, n, 4)
	return {"anchor": c + Vector3i(0, 1, 0), "chest": _at(c, dir, side, -n - 3, 0, 1), "chest_kind": &"temple",
		"locked": true, "yaw": _yaw(dir), "boxes": boxes, "plates": plates, "symbols": symbols, "order": order,
		"vault": vault, "dir": dir, "tip": Vector3i(x, f + 1 + half, z), "entrance": _at(c, dir, side, half, 0, 1),
		"traps": traps, "pits": pits,
		"note": {"cell": _at(c, dir, side, n, -n, 1), "text": Riddles.TEMPLE_TEXT, "pictures": pictures, "yaw": _yaw(dir)},
		"inside": [in_a.min(in_b), in_a.max(in_b) + Vector3i.ONE]}


## A floating mesa: a round island of red sand and red sandstone with a golden chest on top.
func _island(x: int, z: int, v: int) -> Dictionary:
	var r := 4 + v % 3
	var ground := desert.height_at(x, z)
	for c: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
		ground = maxi(ground, desert.height_at(x + c.x, z + c.y))
	var top := maxi(ground + 24, ISLAND_MIN_TOP) + (v >> 2) % 8
	if top > ISLAND_MAX_TOP:
		return {}
	var boxes: Array = []
	for k in r + 2:
		var id := BlockIds.RED_SAND if k == 0 else (BlockIds.RED_SANDSTONE if k <= 2 else BlockIds.SANDSTONE)
		_disc(boxes, Vector3i(x, top - k, z), r if k <= 1 else r - (k - 1), id)
	var gz := z + (v >> 5) % 3 - 1
	_box(boxes, Vector3i(x - 1, top - 3, gz), Vector3i(x - 1, top - 3, gz), BlockIds.GOLD)
	_box(boxes, Vector3i(x + 1, top - 4, gz), Vector3i(x + 1, top - 4, gz), BlockIds.GOLD)
	var chest := Vector3i(x, top + 1, z)
	return {"anchor": chest, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(DIRS[(v >> 8) % 4]), "boxes": boxes,
		"inside": [Vector3i(x - r, top + 1, z - r), Vector3i(x + r + 1, top + 5, z + r + 1)]}
