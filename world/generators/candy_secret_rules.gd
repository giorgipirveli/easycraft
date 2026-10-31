class_name CandySecretRules
extends SecretRules
## Where the Candy Kingdom hides its secrets (M3 Task 4, spec §14.1 and §12.16 adapted): the five kinds of
## Green Meadows' SecretRules, built the candy way, with the same ids, finds, chests and plates (so the
## SecretDirector plays them unchanged):
## - buried treasure: an X of sprinkles on the frosting, the chest 2-4 blocks under it;
## - a hidden room (ROOM) inside a cake mountain's bottom tier: a cream room with candy lamps, reached by a
##   tunnel from a door of fake chocolate in the cake's side (a dark door-shaped patch in the sponge: a fair
##   clue);
## - a gingerbread house (TEMPLE): gingerbread walls with sugar-glass windows, a stepped roof of icing with
##   gumdrops and a golden candy on top; inside, the three pressure plates and the note, and the treasure
##   room behind the golden door the plates open (the temple's puzzle);
## - a floating cake (ISLAND): a round layer cake in the sky with golden candy in its side and a golden
##   chest on top;
## - a rock-candy geode deep underground (Green Meadows' crystal geode).
## Every secret stays inside its 128 x 128 area; chosen from the seed and the area alone.

const CANDY_ATTEMPTS := [[TREASURE, 0.8], [TREASURE, 0.5], [ROOM, 0.7], [TEMPLE, 0.45], [ISLAND, 0.25], [GEODE, 0.5]]
const CHAMBER := 3                # a hidden room: 7 x 7 inside its walls
const ROOM_REACH := 28            # the tunnel from the room to the cake's side is at most this long
const ROOM_PROBES: Array[Vector2i] = [Vector2i(0, 0), Vector2i(20, 0), Vector2i(-20, 0), Vector2i(0, 20),
	Vector2i(0, -20), Vector2i(20, 20), Vector2i(-20, -20), Vector2i(20, -20), Vector2i(-20, 20)]
const HOUSE_HALF := 5             # the gingerbread house: 11 x 11
const HOUSE_FLAT := 4             # its footprint's ground may rise and fall this much
## A floating cake's layers from its top down.
const ISLAND_LAYERS: Array[int] = [BlockIds.SPRINKLES, BlockIds.CREAM, BlockIds.CAKE, BlockIds.JAM, BlockIds.CAKE,
	BlockIds.CAKE, BlockIds.CHOCOLATE, BlockIds.CHOCOLATE]

var candy: CandyShape


func _init(world_seed: int, terrain: MeadowsShape = null) -> void:
	candy = terrain as CandyShape if terrain is CandyShape else CandyShape.new(world_seed)
	super(world_seed, candy)


func _attempts() -> Array:
	return CANDY_ATTEMPTS


## Buried treasure: an X of sprinkles on open frosting, and room for a chest 2 to 4 blocks under it.
func _treasure(x: int, z: int, v: int) -> Dictionary:
	if candy.terrain_at(x, z) != CandyShape.PLAINS or candy.tree_at(x, z):
		return {}
	var boxes: Array = []
	for c in X_CELLS:
		var col := candy.column(x + c.x, z + c.y)
		if col.y != CandyShape.PLAINS:
			return {}
		var cell := Vector3i(x + c.x, col.x - 1, z + c.y)
		_box(boxes, cell, cell, BlockIds.SPRINKLES)
	var chest := Vector3i(x, candy.height_at(x, z) - 3 - v % 3, z)
	_box(boxes, chest, chest, BlockIds.AIR)
	return {"anchor": chest, "chest": chest, "chest_kind": &"buried", "yaw": _yaw(DIRS[(v >> 2) % 4]), "boxes": boxes}


## A hidden room inside a cake mountain: the drawn spot, or one of a few around it, must be under a cake.
func _room(x: int, z: int, v: int) -> Dictionary:
	for off in ROOM_PROBES:
		var s := _cake_room(x + off.x, z + off.y, v)
		if not s.is_empty():
			return s
	return {}


## A cream room with candy lamps and a chest in a cake's bottom tier, level with the frosting outside; a
## tunnel leads out to a fake chocolate door (two blocks, a door's size) in the cake's side.
func _cake_room(x: int, z: int, v: int) -> Dictionary:
	var col := candy.column(x, z)
	if col.y != CandyShape.CAKE_MOUNTAIN:
		return {}
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var out := -1
	for k in range(CHAMBER + 1, ROOM_REACH + 1):
		if candy.terrain_at(x + dir.x * k, z + dir.z * k) != CandyShape.CAKE_MOUNTAIN:
			out = k
			break
	if out < 0:
		return {}
	var outside := candy.column(x + dir.x * out, z + dir.z * out)
	if outside.y != CandyShape.PLAINS:
		return {}                # the door opens onto frosting (never over a river)
	var f := outside.x - 1
	for c: Vector2i in [Vector2i(-3, -3), Vector2i(3, -3), Vector2i(-3, 3), Vector2i(3, 3), Vector2i.ZERO]:
		var cc := candy.column(x + c.x, z + c.y)
		if cc.y != CandyShape.CAKE_MOUNTAIN or cc.x < f + 7:
			return {}            # the room would poke out of the cake
	for k in range(CHAMBER + 1, out):
		var cc := candy.column(x + dir.x * k, z + dir.z * k)
		if cc.x < f + 5:
			return {}            # the tunnel would poke out
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, c + Vector3i(-3, 0, -3), c + Vector3i(3, 5, 3), BlockIds.CREAM)
	_box(boxes, c + Vector3i(-2, 0, -2), c + Vector3i(2, 0, 2), BlockIds.CHOCOLATE)
	_box(boxes, c + Vector3i(-2, 1, -2), c + Vector3i(2, 3, 2), BlockIds.AIR)
	for lamp: Vector3i in [Vector3i(-2, 4, -2), Vector3i(2, 4, -2), Vector3i(-2, 4, 2), Vector3i(2, 4, 2)]:
		_box(boxes, c + lamp, c + lamp, BlockIds.CANDY_LAMP)
	_box(boxes, _at(c, dir, side, CHAMBER, -1, 0), _at(c, dir, side, out - 1, 1, 3), BlockIds.CREAM)
	_box(boxes, _at(c, dir, side, CHAMBER, 0, 1), _at(c, dir, side, out - 2, 0, 2), BlockIds.AIR)
	var fake: Array[Vector3i] = [_at(c, dir, side, out - 1, 0, 1), _at(c, dir, side, out - 1, 0, 2)]
	_box(boxes, fake[0], fake[1], BlockIds.FAKE_CHOCOLATE)
	var s := {"anchor": c + Vector3i(0, 1, 0), "chest": c + Vector3i(0, 1, 0) - dir * 2, "chest_kind": &"room",
		"yaw": _yaw(dir), "boxes": boxes, "fake_wall": fake, "stairs_top": fake[0] + dir, "dir": dir,
		"inside": [c + Vector3i(-2, 1, -2), c + Vector3i(3, 4, 3)]}
	if (v >> 2) % 2 == 0:
		var note := Riddles.room_note(v >> 3)
		s.note = {"cell": c + Vector3i(0, 1, 0) - dir * 2 + side * 2, "text": note.text, "pictures": note.pictures,
			"yaw": _yaw(dir)}
	return s


## A gingerbread house on flat frosting (the kingdom's puzzle temple): walls of gingerbread with sugar-glass
## windows, a chocolate floor, a stepped roof of icing with gumdrops at its corners and a golden candy on top;
## the three plates and the note inside, and the vault behind the golden door.
func _temple(x: int, z: int, v: int) -> Dictionary:
	var n := HOUSE_HALF
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	for dz in [-n, 0, n]:
		for dx in [-n, 0, n]:
			var col := candy.column(x + dx, z + dz)
			if col.y != CandyShape.PLAINS:
				return {}
			lo = mini(lo, col.x)
			hi = maxi(hi, col.x)
	if hi - lo > HOUSE_FLAT:
		return {}                # too steep
	var dir := DIRS[v % 4]
	var side := Vector3i(-dir.z, 0, dir.x)
	var f := candy.height_at(x, z) - 1
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_box(boxes, Vector3i(x - n, lo - 3, z - n), Vector3i(x + n, f + 5, z + n), BlockIds.GINGERBREAD)   # foundation, walls
	_box(boxes, Vector3i(x - n, f + 6, z - n), Vector3i(x + n, f + 10, z + n), BlockIds.AIR)          # nothing on the roof
	_box(boxes, Vector3i(x - n, f + 5, z - n), Vector3i(x + n, f + 5, z + n), BlockIds.CREAM)         # icing over the walls
	_box(boxes, Vector3i(x - n + 1, f + 6, z - n + 1), Vector3i(x + n - 1, f + 6, z + n - 1), BlockIds.CREAM)   # a stepped roof ...
	_box(boxes, Vector3i(x - n + 3, f + 7, z - n + 3), Vector3i(x + n - 3, f + 7, z + n - 3), BlockIds.SPRINKLES)
	_box(boxes, Vector3i(x, f + 8, z), Vector3i(x, f + 8, z), BlockIds.GOLDEN_CANDY)                 # ... with a golden candy
	for k in 4:                                                                                       # gumdrops at the corners
		var corner := Vector3i(x + (n - 1) * (1 if k % 2 == 0 else -1), f + 7, z + (n - 1) * (1 if k < 2 else -1))
		_box(boxes, corner, corner, BlockIds.RED_GUMDROP if k % 3 == 0 else BlockIds.GUMDROP)
	_box(boxes, Vector3i(x - n + 1, f, z - n + 1), Vector3i(x + n - 1, f, z + n - 1), BlockIds.CHOCOLATE)   # the floor
	_box(boxes, Vector3i(x - n + 1, f + 1, z - n + 1), Vector3i(x + n - 1, f + 4, z + n - 1), BlockIds.AIR)
	for s: int in [-1, 1]:                                                                            # sugar-glass windows
		_box(boxes, _at(c, dir, side, 1, s * n, 2), _at(c, dir, side, 2, s * n, 3), BlockIds.SUGAR_GLASS)
	_box(boxes, _at(c, dir, side, -2, -(n - 1), 1), _at(c, dir, side, -2, n - 1, 4), BlockIds.GINGERBREAD)   # the vault's wall
	var vault: Array[Vector3i] = [_at(c, dir, side, -2, 0, 1), _at(c, dir, side, -2, 0, 2)]
	_box(boxes, vault[0], vault[1], BlockIds.YELLOW)   # a bright "golden" door (the Meadows temple's)
	_box(boxes, _at(c, dir, side, n, -1, 1), _at(c, dir, side, n + 2, 1, 4), BlockIds.AIR)            # door and way in
	for lamp: Vector3i in [_at(c, dir, side, n - 1, -(n - 1), 4), _at(c, dir, side, n - 1, n - 1, 4),
			_at(c, dir, side, -1, -(n - 1), 4), _at(c, dir, side, -1, n - 1, 4), _at(c, dir, side, -n + 2, 0, 4),
			_at(c, dir, side, n, -2, 3), _at(c, dir, side, n, 2, 3)]:
		_box(boxes, lamp, lamp, BlockIds.CANDY_LAMP)
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


## A floating cake: a round layer cake (sprinkles on top, cream, sponge and jam) with golden candy in its
## side and a golden chest on top.
func _island(x: int, z: int, v: int) -> Dictionary:
	var r := 4 + v % 3
	var ground := candy.height_at(x, z)
	for c: Vector2i in [Vector2i(r, 0), Vector2i(-r, 0), Vector2i(0, r), Vector2i(0, -r)]:
		ground = maxi(ground, candy.height_at(x + c.x, z + c.y))
	var top := maxi(ground + 24, ISLAND_MIN_TOP) + (v >> 2) % 8
	if top > ISLAND_MAX_TOP:
		return {}
	var boxes: Array = []
	for k in r + 2:
		_disc(boxes, Vector3i(x, top - k, z), r if k <= 3 else r - (k - 3), ISLAND_LAYERS[mini(k, ISLAND_LAYERS.size() - 1)])
	var gz := z + (v >> 5) % 3 - 1
	_box(boxes, Vector3i(x - r, top - 2, gz), Vector3i(x - r, top - 2, gz), BlockIds.GOLDEN_CANDY)
	_box(boxes, Vector3i(x + r, top - 2, gz), Vector3i(x + r, top - 2, gz), BlockIds.GOLDEN_CANDY)
	var chest := Vector3i(x, top + 1, z)
	return {"anchor": chest, "chest": chest, "chest_kind": &"sky", "yaw": _yaw(DIRS[(v >> 8) % 4]), "boxes": boxes,
		"inside": [Vector3i(x - r, top + 1, z - r), Vector3i(x + r + 1, top + 5, z + r + 1)]}
