class_name FrostSecretRules
extends SecretRules
## Where Frostpeak hides its secrets (M3 Task 3, spec §14.1 and §12.16 adapted): the five kinds of Green
## Meadows' SecretRules, built the Frostpeak way, with the same ids, finds, chests and plates (so the
## SecretDirector plays them unchanged):
## - buried treasure: a blue-ice X in the snow, the chest 2-4 blocks under it;
## - a hidden room (ROOM) under an igloo (FrostShape builds the igloos: "a secret inside sometimes"): a fake
##   packed-snow floor opens onto stairs that go down to a snow-brick room with ice lanterns and a chest;
## - an ice temple (TEMPLE): a snow-brick hall with a stepped roof of packed snow and blue ice under a golden
##   tip; the three pressure plates, the note, and the treasure behind the golden door they open;
## - a floating iceberg (ISLAND) with a golden chest on top;
## - a crystal geode deep underground (Green Meadows' own).
## Every secret stays inside its 128 x 128 area; chosen from the seed and the area alone.

const FROST_ATTEMPTS := [[TREASURE, 0.8], [TREASURE, 0.5], [ROOM, 0.9], [TEMPLE, 0.4], [ISLAND, 0.25], [GEODE, 0.5]]
const ROOM_SEARCH := 48           # a room goes under the nearest igloo within this of the drawn spot
const STAIRS := 5                 # steps down from the hole in the igloo's floor to the room's doorway
const ROOM_LEN := 5               # the room: 5 x 5 blocks, 3 high
const TEMPLE_FLAT := 5

var frost: FrostShape


func _init(world_seed: int, terrain: MeadowsShape = null) -> void:
	frost = terrain as FrostShape if terrain is FrostShape else FrostShape.new(world_seed)
	super(world_seed, frost)


func _attempts() -> Array:
	return FROST_ATTEMPTS


func _snowy(x: int, z: int) -> bool:
	var col := frost.column(x, z)
	return col.y != FrostShape.LAKE and col.x > MeadowsShape.SEA_LEVEL + 1


## Buried treasure: a blue-ice X in the snow, and room for a chest 2 to 4 blocks under it.
func _treasure(x: int, z: int, v: int) -> Dictionary:
	if not _snowy(x, z) or frost.tree_at(x, z):
		return {}
	var boxes: Array = []
	for c in X_CELLS:
		if not _snowy(x + c.x, z + c.y):
			return {}
		var cell := Vector3i(x + c.x, frost.height_at(x + c.x, z + c.y) - 1, z + c.y)
		_box(boxes, cell, cell, BlockIds.BLUE_ICE)
	var chest := Vector3i(x, frost.height_at(x, z) - 3 - v % 3, z)
	_box(boxes, chest, chest, BlockIds.AIR)
	return {"anchor": chest, "chest": chest, "chest_kind": &"buried", "yaw": _yaw(DIRS[(v >> 2) % 4]), "boxes": boxes}


## A hidden room under the igloo nearest the drawn spot (the first that has room for it).
func _room(x: int, z: int, v: int) -> Dictionary:
	var c0 := Vector2i(floori((x - ROOM_SEARCH) / float(FrostShape.IGLOO_CELL)), floori((z - ROOM_SEARCH) / float(FrostShape.IGLOO_CELL)))
	var c1 := Vector2i(floori((x + ROOM_SEARCH) / float(FrostShape.IGLOO_CELL)), floori((z + ROOM_SEARCH) / float(FrostShape.IGLOO_CELL)))
	var igloos: Array = []
	for cz in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var ig := frost.igloo_in_cell(Vector2i(cx, cz))
			if not ig.is_empty():
				igloos.append(ig)
	igloos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return Vector2(a.center.x - x, a.center.z - z).length_squared() < Vector2(b.center.x - x, b.center.z - z).length_squared())
	for ig: Dictionary in igloos:
		var s := _igloo_room(ig, v)
		if not s.is_empty():
			return s
	return {}


## Under igloo `ig`: two fake packed-snow blocks in its floor (away from the doorway), a landing two blocks
## under them (a double jump gets back up), STAIRS steps down away from the doorway (the natural ground is
## their walls and roof), then a snow-brick room with ice lanterns and a chest. Only where the ground outside
## covers every step and the room. `path`: where feet stand, from the landing to inside the room.
func _igloo_room(ig: Dictionary, v: int) -> Dictionary:
	var c: Vector3i = ig.center
	var g := c.y
	var back: Vector3i = -(ig.dir as Vector3i)            # the stairs go this way, away from the doorway
	var side := Vector3i(-back.z, 0, back.x)
	var path: Array[Vector3i] = [c + back + Vector3i(0, -2, 0)]   # the landing under the hole, then each step
	for k in STAIRS:
		path.append(c + back * (2 + k) + Vector3i(0, -2 - k, 0))
	var f := g - 2 - STAIRS                               # the room's floor level (feet)
	var door := c + back * (2 + STAIRS)
	var fr := Vector3i(door.x, f, door.z) + back * 3      # the room's middle (along the stairs' line)
	path.append(Vector3i(door.x, f, door.z))
	path.append(fr - back * 2)                            # the first step into the room
	for p: Vector3i in path:
		if Vector2(p.x - c.x, p.z - c.z).length() <= FrostShape.IGLOO_R + 0.5:
			continue                   # under the igloo: its floor and foundation cover the stairs
		var col := frost.column(p.x, p.z)
		if col.y == FrostShape.LAKE or col.x < p.y + 4:
			return {}                  # the ground outside is too low: the stairs would open to the sky
	for off: Vector2i in [Vector2i(-3, -3), Vector2i(3, -3), Vector2i(-3, 3), Vector2i(3, 3), Vector2i.ZERO]:
		var col := frost.column(fr.x + off.x, fr.z + off.y)
		if col.y == FrostShape.LAKE or col.x < f + 5:
			return {}                  # the room would poke out of the ground (or into a lake)
	var boxes: Array = []
	_box(boxes, fr + Vector3i(-3, -1, -3), fr + Vector3i(3, 3, 3), BlockIds.SNOW_BRICK)          # the shell
	_box(boxes, fr + Vector3i(-2, -1, -2), fr + Vector3i(2, -1, 2), BlockIds.PACKED_SNOW)        # its floor
	_box(boxes, fr + Vector3i(-2, 0, -2), fr + Vector3i(2, 2, 2), BlockIds.AIR)                  # the room
	for lamp: Vector3i in [Vector3i(-2, 3, -2), Vector3i(2, 3, -2), Vector3i(-2, 3, 2), Vector3i(2, 3, 2)]:
		_box(boxes, fr + lamp, fr + lamp, BlockIds.ICE_LANTERN)
	for p: Vector3i in path:                               # the stairs: a floor under each step, room above
		_box(boxes, p + Vector3i.DOWN, p + Vector3i.DOWN, BlockIds.PACKED_SNOW)
		_box(boxes, p, p + Vector3i(0, 2, 0), BlockIds.AIR)
	var fake: Array[Vector3i] = [c + back + Vector3i.DOWN, c + back * 2 + Vector3i.DOWN]
	_box(boxes, fake[0], fake[1], BlockIds.FAKE_SNOW)
	var chest := fr + back * 2
	var s := {"anchor": fr, "chest": chest, "chest_kind": &"room", "yaw": _yaw(-back), "boxes": boxes,
		"fake_wall": fake, "stairs_top": c, "dir": Vector3i.UP, "path": path,
		"inside": [fr + Vector3i(-2, 0, -2), fr + Vector3i(3, 3, 3)]}
	if (v >> 2) % 2 == 0:
		var note := Riddles.room_note(v >> 3)
		s.note = {"cell": chest + side * 2, "text": note.text, "pictures": note.pictures, "yaw": _yaw(-back)}
	return s


## An ice temple: an 11 x 11 snow-brick hall on a foundation, a packed-snow floor, a stepped roof of packed
## snow and blue ice with a golden tip, three pressure plates painted with a sun, a moon and a star, a note
## showing the order to step on them, and a vault behind a golden door.
func _temple(x: int, z: int, v: int) -> Dictionary:
	var h := frost.height_at(x, z)
	var lo := h
	var hi := h
	for dz in [-5, 0, 5]:
		for dx in [-5, 0, 5]:
			if not _snowy(x + dx, z + dz) or frost.tree_at(x + dx, z + dz):
				return {}
			var hc := frost.height_at(x + dx, z + dz)
			lo = mini(lo, hc)
			hi = maxi(hi, hc)
	if hi - lo > TEMPLE_FLAT:
		return {}                # too steep
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var f := h - 1
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, Vector3i(x - 5, lo - 3, z - 5), Vector3i(x + 5, f + 5, z + 5), BlockIds.SNOW_BRICK)  # foundation, walls
	_box(boxes, Vector3i(x - 5, f + 6, z - 5), Vector3i(x + 5, f + 9, z + 5), BlockIds.AIR)          # nothing on the roof
	_box(boxes, Vector3i(x - 5, f + 5, z - 5), Vector3i(x + 5, f + 5, z + 5), BlockIds.PACKED_SNOW)  # a stepped roof ...
	_box(boxes, Vector3i(x - 4, f + 6, z - 4), Vector3i(x + 4, f + 6, z + 4), BlockIds.BLUE_ICE)
	_box(boxes, Vector3i(x - 2, f + 7, z - 2), Vector3i(x + 2, f + 7, z + 2), BlockIds.PACKED_SNOW)
	_box(boxes, Vector3i(x, f + 8, z), Vector3i(x, f + 8, z), BlockIds.GOLD)                         # ... with a golden tip
	_box(boxes, Vector3i(x - 4, f, z - 4), Vector3i(x + 4, f, z + 4), BlockIds.PACKED_SNOW)
	_box(boxes, Vector3i(x - 4, f + 1, z - 4), Vector3i(x + 4, f + 4, z + 4), BlockIds.AIR)
	_box(boxes, _at(c, dir, side, -2, -4, 1), _at(c, dir, side, -2, 4, 4), BlockIds.SNOW_BRICK)     # the vault's wall
	var vault: Array[Vector3i] = [_at(c, dir, side, -2, 0, 1), _at(c, dir, side, -2, 0, 2)]
	_box(boxes, vault[0], vault[1], BlockIds.YELLOW)   # a bright "golden" door (gold ore would be worth mining)
	_box(boxes, _at(c, dir, side, 5, -1, 1), _at(c, dir, side, 7, 1, 4), BlockIds.AIR)          # door and way in
	for s: int in [-3, 3]:                                                                     # frosted windows
		_box(boxes, _at(c, dir, side, 1, s * 5 / 3, 3), _at(c, dir, side, 1, s * 5 / 3, 3), BlockIds.FROSTED_GLASS)
	for lamp: Vector3i in [_at(c, dir, side, 4, -4, 5), _at(c, dir, side, 4, 4, 5), _at(c, dir, side, -1, -4, 5),
			_at(c, dir, side, -1, 4, 5), _at(c, dir, side, -3, 0, 5), _at(c, dir, side, 5, -2, 3), _at(c, dir, side, 5, 2, 3)]:
		_box(boxes, lamp, lamp, BlockIds.ICE_LANTERN)
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
		"vault": vault, "dir": dir,
		"note": {"cell": _at(c, dir, side, 3, -3, 1), "text": Riddles.TEMPLE_TEXT, "pictures": pictures, "yaw": _yaw(dir)},
		"inside": [Vector3i(x - 4, f + 1, z - 4), Vector3i(x + 5, f + 5, z + 5)]}


## A floating iceberg: snow on top, packed snow, ice, and a cone of blue ice with gold in it; a golden
## chest on top.
func _island(x: int, z: int, v: int) -> Dictionary:
	var r := 4 + v % 3
	var ground := frost.height_at(x, z)
	for c: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
		ground = maxi(ground, frost.height_at(x + c.x, z + c.y))
	var top := maxi(ground + 24, ISLAND_MIN_TOP) + (v >> 2) % 8
	if top > ISLAND_MAX_TOP:
		return {}
	var boxes: Array = []
	for k in r + 2:
		var id := BlockIds.SNOW if k == 0 else (BlockIds.PACKED_SNOW if k == 1 else (BlockIds.ICE if k == 2 else BlockIds.BLUE_ICE))
		_disc(boxes, Vector3i(x, top - k, z), r if k <= 1 else r - (k - 1), id)
	var gz := z + (v >> 5) % 3 - 1
	_box(boxes, Vector3i(x - 1, top - 3, gz), Vector3i(x - 1, top - 3, gz), BlockIds.GOLD)
	_box(boxes, Vector3i(x + 1, top - 4, gz), Vector3i(x + 1, top - 4, gz), BlockIds.GOLD)
	var chest := Vector3i(x, top + 1, z)
	return {"anchor": chest, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(DIRS[(v >> 8) % 4]), "boxes": boxes,
		"inside": [Vector3i(x - r, top + 1, z - r), Vector3i(x + r + 1, top + 5, z + r + 1)]}
