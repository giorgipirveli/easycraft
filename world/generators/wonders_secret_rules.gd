class_name WondersSecretRules
extends SecretRules
## Where world 41 (Wonders of the World, owner #78, spec §24) hides its secrets: one at each wonder, each find ending
## with a real fact (its `words`, WonderFacts' "secret": the SecretDirector says the find on its banner and the fact
## after it). The Secret Book counts them like every world's:
##   the Great Pyramid: a hidden room above the Grand Gallery (the "big void" scientists found in 2017), up a secret
##     stair behind a fake limestone block in the gallery's wall (ROOM, a chest inside);
##   the Hanging Gardens: a cool room under the terraces, behind a fake brick at the back of the vaulted gallery (ROOM);
##   the Temple of Artemis: its treasury (TEMPLE: three plates in the hall, the riddle's note, a golden door, the chest);
##   the Statue of Zeus: Phidias's workshop west of the temple, its door a fake marble one (ROOM);
##   the Mausoleum: the hidden tomb room under the podium, down a stair behind a fake marble door at its back (ROOM);
##   the Colossus: buried treasure under an X of sand in the grass by the harbour (TREASURE);
##   the Lighthouse: a golden chest in the lantern by the fire (TREASURE, found when it is opened).
## The New Seven's (the second tour):
##   the Great Wall: a watchtower's store room in its base, behind a fake wall brick on its south face (ROOM);
##   Petra: treasure on the ledge by the Treasury's urn, up the stair cut in the rock (TREASURE, found when opened);
##   the Colosseum: the tunnels under the arena, down steps behind a fake travertine block in the arena's wall (ROOM);
##   Chichen Itza: the pyramid inside the pyramid, in at a fake stone in the north stair's balustrade, a tunnel under the
##     stair and a stair up to the inner temple with the red jaguar throne (ROOM);
##   Machu Picchu: the cave under the Temple of the Sun, behind a fake Inca stone in its rock's wall (ROOM);
##   the Taj Mahal: treasure at the top of the hollow minaret, up its spiral stair (TREASURE, found when opened);
##   Christ the Redeemer: the room inside the pedestal, behind a fake white stone at its back (ROOM).
## The Seven Natural Wonders' (the third tour):
##   the Grand Canyon: a chest in the granary in the cliff beside the trail down (TREASURE, found when opened);
##   the Great Barrier Reef: a chest by the ship's cannon on the reef flat, dived to (TREASURE, found when opened);
##   the Harbour of Rio de Janeiro: a chest on a climbers' ledge under the Sugarloaf's lookout (TREASURE);
##   Mount Everest: a chest on the summit, by its fossil rock (TREASURE);
##   the Northern Lights: the ice cave in the snow mound, behind a fake snow block on its east face (ROOM);
##   Parícutin: a room in the church tower, behind a fake wall brick over the lava (ROOM);
##   Victoria Falls: a chest on Livingstone Island, on the lip of the falls, swum to (TREASURE).
## Only these round the tours (no other secret, treasure-pack place or mouse village in their areas: they would land on
## a wonder or a path); out past them Green Meadows' own secrets as everywhere.

## The areas round the first tour (x and z from TOUR_AREAS.x to TOUR_AREAS.y): only the wonders' secrets there.
const TOUR_AREAS := Vector2i(-3, 2)
## The areas of the second tour's region (the New Seven Wonders round WonderTour.NEW_SQUARE, and its blend).
const NEW_TOUR_AREAS := Rect2i(-5, -2, 5, 4)
## The areas of the third tour's region (the Seven Natural Wonders round WonderTour.NATURE_SQUARE, and its blend).
const NATURE_TOUR_AREAS := Rect2i(-2, 0, 6, 6)
const FIRST_ATTEMPT := 100         # the wonders' secrets' numbers in their ids (never a random attempt's)

var _wonder_secrets := {}          # area -> Array of secrets


func _init(world_seed: int, terrain: MeadowsShape = null) -> void:
	super(world_seed, terrain if terrain != null else WondersShape.new(world_seed))
	var list := _make_wonder_secrets()
	for i in list.size():
		var s: Dictionary = list[i]
		var at: Vector3i = s.anchor
		var area := area_of(at.x, at.z)
		_finish(s, s.kind, area, FIRST_ATTEMPT + i)
		if not _wonder_secrets.has(area):
			_wonder_secrets[area] = []
		(_wonder_secrets[area] as Array).append(s)


static func in_tour(area: Vector2i) -> bool:
	if NEW_TOUR_AREAS.has_point(area) or NATURE_TOUR_AREAS.has_point(area):
		return true
	return area.x >= TOUR_AREAS.x and area.x <= TOUR_AREAS.y and area.y >= TOUR_AREAS.x and area.y <= TOUR_AREAS.y


func _place(area: Vector2i) -> Array:
	if in_tour(area):
		return _wonder_secrets.get(area, [])
	return super(area)


func tiny_in_area(area: Vector2i) -> Array:
	return [] if in_tour(area) else super(area)


## Every wonder's secret (tests, the smoke run).
func wonder_secrets() -> Array:
	var out: Array = []
	for area: Vector2i in _wonder_secrets:
		out.append_array(_wonder_secrets[area])
	return out


## The secret of wonder `id` ({} for none).
func secret_of(id: StringName) -> Dictionary:
	for s: Dictionary in wonder_secrets():
		if s.get("wonder") == id:
			return s
	return {}


func _make_wonder_secrets() -> Array:
	var out: Array = []
	for id: StringName in WonderTour.ids():
		var s := _wonder_secret(id)
		if not s.is_empty():
			s.wonder = id
			s.words = str(WonderFacts.of(id).get("secret", ""))
			out.append(s)
	return out


func _wonder_secret(id: StringName) -> Dictionary:
	match id:
		&"pyramid":
			return _pyramid_room()
		&"gardens":
			return _gardens_room()
		&"artemis":
			return _artemis_treasury()
		&"zeus":
			return _workshop()
		&"mausoleum":
			return _tomb_room()
		&"colossus":
			return _colossus_treasure()
		&"lighthouse":
			return _lighthouse_chest()
		&"great_wall":
			return _wall_store_room()
		&"petra":
			return _sky_chest(&"petra", Vector3i(1, WonderBuildsNew.PETRA_LEDGE, WonderBuildsNew.PETRA_FACE - 1))
		&"colosseum":
			return _hypogeum()
		&"chichen_itza":
			return _inner_pyramid()
		&"machu_picchu":
			return _royal_tomb()
		&"taj_mahal":
			var m := WonderBuildsNew.TAJ_HOLLOW
			return _sky_chest(&"taj_mahal", Vector3i(m.x, WonderBuildsNew.MINARET_FLOOR + 1, m.y))
		&"christ_redeemer":
			return _pedestal_room()
		&"grand_canyon":
			var g := WonderBuildsNature.GRANARY
			return _sky_chest(&"grand_canyon", Vector3i(g.position.x + 2, WonderBuildsNature.trail_feet(
				WonderBuildsNature.GRANARY_DOOR_Z), WonderBuildsNature.GRANARY_DOOR_Z))
		&"barrier_reef":
			var c := WonderBuildsNature.CANNON
			return _sky_chest(&"barrier_reef", Vector3i(c.x - 1, WonderBuildsNature.ROOM_FLOOR - WonderTour.BASE_Y, c.z + 2))
		&"rio_harbour":
			return _climbers_ledge()
		&"everest":
			return _sky_chest(&"everest", Vector3i(0, NatureGround.EVEREST_TOP, 1))
		&"northern_lights":
			return _ice_cave()
		&"paricutin":
			return _tower_room()
		&"victoria_falls":
			var i := NatureGround.ISLAND
			return _sky_chest(&"victoria_falls", Vector3i((i.x + i.z) / 2, 1, i.y + 2))
	return {}


## A cell of wonder `id`'s own frame (y up from the tour's ground) in the world.
static func _w(id: StringName, p: Vector3i) -> Vector3i:
	var q := WonderTour.to_world(id, Vector2i(p.x, p.z))
	return Vector3i(q.x, p.y + WonderTour.BASE_Y, q.y)


## A direction of wonder `id`'s own frame in the world.
static func _wdir(id: StringName, d: Vector3i) -> Vector3i:
	var q := WonderTour.turn(Vector2i(d.x, d.z), WonderTour.WONDERS[id].face)
	return Vector3i(q.x, 0, q.y)


## [lo, hi exclusive] of a frame box in the world.
static func _wbox(id: StringName, a: Vector3i, b: Vector3i) -> Array:
	var f := WonderBuilds.Frame.new(id)
	f.box(a, b, BlockIds.AIR)
	return [f.out[0][0], f.out[0][1]]


## The Great Pyramid's hidden room: the "big void" over the Grand Gallery, up a spiral stair behind a fake block.
func _pyramid_room() -> Dictionary:
	var id := &"pyramid"
	var f := WonderBuilds.Frame.new(id)
	f.box(Vector3i(5, 11, -6), Vector3i(7, 19, -4), BlockIds.AIR)          # the stair's shaft (inside the stone)
	f.box(Vector3i(6, 10, -5), Vector3i(6, 19, -5), BlockIds.LIMESTONE)    # its pillar
	var turn := [Vector2i(5, -5), Vector2i(5, -6), Vector2i(6, -6), Vector2i(7, -6), Vector2i(7, -5), Vector2i(7, -4),
		Vector2i(6, -4), Vector2i(5, -4)]
	for k in turn.size():
		f.box(Vector3i(turn[k].x, 10, turn[k].y), Vector3i(turn[k].x, 10 + k, turn[k].y), BlockIds.LIMESTONE)
	f.box(Vector3i(4, 18, -4), Vector3i(4, 20, -4), BlockIds.AIR)          # into the room
	f.box(Vector3i(0, 18, -6), Vector3i(3, 20, -3), BlockIds.AIR)          # the room
	f.cell(Vector3i(0, 21, -6), BlockIds.DESERT_LAMP)
	f.cell(Vector3i(3, 21, -3), BlockIds.DESERT_LAMP)
	f.box(Vector3i(4, 10, -5), Vector3i(4, 11, -5), BlockIds.FAKE_LIMESTONE)   # the fake block in the gallery's wall
	var dir := _wdir(id, Vector3i(-1, 0, 0))
	var inside := _wbox(id, Vector3i(0, 18, -6), Vector3i(3, 20, -3))
	return {"kind": ROOM, "anchor": _w(id, Vector3i(1, 18, -5)), "chest": _w(id, Vector3i(2, 18, -6)),
		"chest_kind": &"room", "yaw": _yaw(dir), "boxes": f.out, "dir": dir,
		"fake_wall": [_w(id, Vector3i(4, 10, -5)), _w(id, Vector3i(4, 11, -5))] as Array[Vector3i], "inside": inside}


## The Hanging Gardens' cool room under the terraces, behind a fake brick at the back of the vaulted gallery.
func _gardens_room() -> Dictionary:
	var id := &"gardens"
	var f := WonderBuilds.Frame.new(id)
	f.box(Vector3i(5, 0, -11), Vector3i(9, 2, -7), BlockIds.AIR)
	f.cell(Vector3i(5, 2, -7), BlockIds.DESERT_LAMP)
	f.cell(Vector3i(9, 2, -7), BlockIds.DESERT_LAMP)
	f.box(Vector3i(6, 0, -8), Vector3i(8, 0, -8), BlockIds.WATER)   # a cool pool
	f.box(Vector3i(7, 0, -12), Vector3i(7, 1, -12), BlockIds.FAKE_BABYLON_BRICK)
	var dir := _wdir(id, Vector3i(0, 0, -1))
	return {"kind": ROOM, "anchor": _w(id, Vector3i(7, 0, -9)), "chest": _w(id, Vector3i(8, 0, -11)),
		"chest_kind": &"room", "yaw": _yaw(dir), "boxes": f.out, "dir": dir,
		"fake_wall": [_w(id, Vector3i(7, 0, -12)), _w(id, Vector3i(7, 1, -12))] as Array[Vector3i],
		"inside": _wbox(id, Vector3i(5, 0, -11), Vector3i(9, 2, -7))}


## The Temple of Artemis's treasury: three plates in the hall, the note, a golden door, the chest behind it.
func _artemis_treasury() -> Dictionary:
	var id := &"artemis"
	var f := WonderBuilds.Frame.new(id)
	var v := 0x2d61
	var plates: Array[Vector3i] = []
	for x: int in [-2, 0, 2]:
		var p := _w(id, Vector3i(x, 3, -4))
		plates.append(p)
		f.cell(Vector3i(x, 3, -4), BlockIds.PRESSURE_PLATE)
	f.box(Vector3i(-3, 3, 11), Vector3i(3, 7, 11), BlockIds.MARBLE)   # the treasury's wall
	f.box(Vector3i(0, 3, 11), Vector3i(0, 4, 11), BlockIds.YELLOW)     # its golden door
	f.cell(Vector3i(-3, 6, 14), BlockIds.GOLD_LAMP)
	f.cell(Vector3i(3, 6, 14), BlockIds.GOLD_LAMP)
	var symbols := _permutation(Riddles.TEMPLE_SYMBOLS, v >> 2)
	var order := _permutation([0, 1, 2], v >> 5)
	var pictures: Array[int] = [symbols[order[0]], symbols[order[1]], symbols[order[2]]]
	var dir := _wdir(id, Vector3i(0, 0, -1))
	return {"kind": TEMPLE, "anchor": _w(id, Vector3i(0, 4, 0)), "chest": _w(id, Vector3i(0, 3, 14)),
		"chest_kind": &"temple", "locked": true, "yaw": _yaw(dir), "boxes": f.out, "plates": plates,
		"symbols": symbols, "order": order,
		"vault": [_w(id, Vector3i(0, 3, 11)), _w(id, Vector3i(0, 4, 11))] as Array[Vector3i], "dir": dir,
		"note": {"cell": _w(id, Vector3i(-2, 3, 8)), "text": Riddles.TEMPLE_TEXT, "pictures": pictures, "yaw": _yaw(dir)},
		"inside": _wbox(id, Vector3i(-3, 3, -11), Vector3i(3, 8, 10))}


## Phidias's workshop west of the Temple of Zeus: walls and a tiled roof, his bench, clay moulds, bits of ivory and
## gold, a lantern; its door a fake marble one.
func _workshop() -> Dictionary:
	var r := WonderTour.WORKSHOP
	var y := WonderTour.BASE_Y
	var lo := Vector3i(r.position.x, y, r.position.y)
	var hi := Vector3i(r.end.x - 1, y, r.end.y - 1)
	var boxes: Array = []
	_box(boxes, lo + Vector3i(0, -1, 0), hi + Vector3i(0, -1, 0), BlockIds.PAVING)
	_box(boxes, lo, hi + Vector3i(0, 4, 0), BlockIds.WHITE_BRICK)
	_box(boxes, lo + Vector3i(1, 0, 1), hi + Vector3i(-1, 3, -1), BlockIds.AIR)
	_box(boxes, lo + Vector3i(0, 5, 0), hi + Vector3i(0, 5, 0), BlockIds.ROOF_TILES)
	_box(boxes, lo + Vector3i(1, 6, 2), hi + Vector3i(-1, 6, -2), BlockIds.ROOF_TILES)
	_box(boxes, lo + Vector3i(2, 0, 2), lo + Vector3i(2, 0, 2), BlockIds.CRAFTING_TABLE)
	_box(boxes, lo + Vector3i(2, 0, 6), lo + Vector3i(3, 0, 6), BlockIds.BRICK)       # clay moulds for the robe
	_box(boxes, lo + Vector3i(6, 0, 1), lo + Vector3i(6, 0, 1), BlockIds.IVORY)
	_box(boxes, lo + Vector3i(7, 0, 1), lo + Vector3i(7, 0, 1), BlockIds.GOLD_LEAF)
	_box(boxes, lo + Vector3i(5, 3, 4), lo + Vector3i(5, 3, 4), BlockIds.LANTERN)
	var door: Array[Vector3i] = []
	for dz: int in [3, 4]:
		for dy: int in [0, 1]:
			var c := Vector3i(hi.x, y + dy, lo.z + dz)
			door.append(c)
			_box(boxes, c, c, BlockIds.FAKE_MARBLE)
	var dir := Vector3i(1, 0, 0)
	return {"kind": ROOM, "anchor": lo + Vector3i(5, 0, 4), "chest": lo + Vector3i(8, 0, 6), "chest_kind": &"room",
		"yaw": _yaw(dir), "boxes": boxes, "dir": dir, "fake_wall": door,
		"inside": [lo + Vector3i(1, 0, 1), hi + Vector3i(0, 4, 0)]}


## The Mausoleum's hidden tomb room under its podium, down a stair behind a fake marble door at its back.
func _tomb_room() -> Dictionary:
	var id := &"mausoleum"
	var f := WonderBuilds.Frame.new(id)
	f.box(Vector3i(-4, -6, -3), Vector3i(4, -1, 5), BlockIds.MARBLE)
	f.box(Vector3i(-3, -5, -2), Vector3i(3, -2, 4), BlockIds.AIR)
	for j in 6:
		f.box(Vector3i(1, -j, 10 - j), Vector3i(2, 2 - j, 10 - j), BlockIds.AIR)
	f.box(Vector3i(-2, -5, 0), Vector3i(0, -4, 1), BlockIds.MARBLE)   # the stone coffin
	f.cell(Vector3i(-3, -2, -2), BlockIds.DESERT_LAMP)
	f.cell(Vector3i(3, -2, 4), BlockIds.DESERT_LAMP)
	var fake: Array[Vector3i] = []
	for x: int in [1, 2]:
		for y: int in [0, 1]:
			fake.append(_w(id, Vector3i(x, y, 11)))
			f.cell(Vector3i(x, y, 11), BlockIds.FAKE_MARBLE)
	var dir := _wdir(id, Vector3i(0, 0, 1))
	return {"kind": ROOM, "anchor": _w(id, Vector3i(0, -5, 1)), "chest": _w(id, Vector3i(2, -5, 0)),
		"chest_kind": &"room", "yaw": _yaw(dir), "boxes": f.out, "dir": dir, "fake_wall": fake,
		"inside": _wbox(id, Vector3i(-3, -5, -2), Vector3i(3, -2, 4))}


## Buried treasure by the Colossus: an X of sand in the grass toward the harbour, the chest three blocks under it.
func _colossus_treasure() -> Dictionary:
	var c := Vector2i(52, -80)
	var h := WonderTour.BASE_Y
	var boxes: Array = []
	for x: Vector2i in X_CELLS:
		var cell := Vector3i(c.x + x.x, h - 1, c.y + x.y)
		_box(boxes, cell, cell, BlockIds.SAND)
	var chest := Vector3i(c.x, h - 3, c.y)
	_box(boxes, chest, chest, BlockIds.AIR)
	return {"kind": TREASURE, "anchor": chest, "chest": chest, "chest_kind": &"buried", "yaw": _yaw(DIRS[1]),
		"boxes": boxes}


# --- The second tour's secrets: the New Seven Wonders ---

## A hidden room of wonder `id`: `room` its air [lo, hi] (frame, inclusive), the fake cells, the way out of them (frame
## dir), the chest's cell, lamps; `extra`: more frame boxes [a, b, block] (tunnels, steps, a throne), written first.
func _frame_room(id: StringName, room: Array, fakes: Array, fake_block: int, out_dir: Vector3i, chest: Vector3i,
		lamps: Array, extra: Array = []) -> Dictionary:
	var f := WonderBuilds.Frame.new(id)
	for e: Array in extra:
		f.box(e[0], e[1], e[2])
	f.box(room[0], room[1], BlockIds.AIR)
	for p: Vector3i in lamps:
		f.cell(p, BlockIds.DESERT_LAMP)
	var fake_world: Array[Vector3i] = []
	for p: Vector3i in fakes:
		f.cell(p, fake_block)
		fake_world.append(_w(id, p))
	var dir := _wdir(id, out_dir)
	var lo: Vector3i = room[0]
	var hi: Vector3i = room[1]
	return {"kind": ROOM, "anchor": _w(id, (lo + hi) / 2 * Vector3i(1, 0, 1) + Vector3i(0, lo.y, 0)),
		"chest": _w(id, chest), "chest_kind": &"room", "yaw": _yaw(dir), "boxes": f.out, "dir": dir,
		"fake_wall": fake_world, "inside": _wbox(id, lo, hi)}


## A chest standing at a wonder's frame cell (on its floor): found when it is opened.
func _sky_chest(id: StringName, at: Vector3i) -> Dictionary:
	var chest := _w(id, at)
	var boxes: Array = []
	_box(boxes, chest, chest, BlockIds.AIR)
	return {"kind": TREASURE, "anchor": chest, "chest": chest, "chest_kind": &"sky",
		"yaw": _yaw(_wdir(id, Vector3i(0, 0, -1))), "boxes": boxes}


## The Great Wall: a store room in the base of the watchtower east of the middle one, its door a fake wall brick on the
## tower's south face at the ridge's ground.
func _wall_store_room() -> Dictionary:
	var id := &"great_wall"
	var t: int = NewSevenGround.WALL_TOWERS[3]
	var foot := WonderTour.to_world(id, Vector2i(t, -5))
	var g := NewSevenGround.height(foot.x, foot.y) - WonderTour.BASE_Y   # the ground's feet by the tower
	g = mini(g, NewSevenGround.wall_walk(t) - 4)
	return _frame_room(id, [Vector3i(t - 2, g, -3), Vector3i(t + 2, g + 2, -1)], [Vector3i(t, g, -4), Vector3i(t, g + 1, -4)],
		BlockIds.FAKE_WALL_BRICK, Vector3i(0, 0, -1), Vector3i(t + 2, g, -1), [Vector3i(t - 2, g + 2, -1)])


## The Colosseum: steps down behind a fake travertine block in the arena's wall (its west end) to a room under the tiers,
## where the lifts' machinery was (a wooden lift's floor, its posts).
func _hypogeum() -> Dictionary:
	var id := &"colosseum"
	var x := 4
	var zh := 0   # the arena's last cell along z in row x (its wall starts after it)
	for row: Array in WonderBuildsNew._oval_rows(WonderBuildsNew.ARENA.x, WonderBuildsNew.ARENA.y):
		if row[0] == x:
			zh = row[1]
	var door := zh + 1
	var steps: Array = []
	for k in range(1, 6):   # down a block a step, three high
		steps.append([Vector3i(x, -k, door + k), Vector3i(x, 2 - k, door + k), BlockIds.AIR])
	var z0 := door + 6
	steps.append([Vector3i(6, -5, z0 + 3), Vector3i(7, -5, z0 + 4), BlockIds.PLANKS])   # the lift's floor ...
	steps.append([Vector3i(5, -5, z0 + 5), Vector3i(5, -3, z0 + 5), BlockIds.LOG])     # ... and a post of its frame
	var room := [Vector3i(1, -5, z0), Vector3i(7, -3, z0 + 5)]
	var r := _frame_room(id, room, [Vector3i(x, 0, door), Vector3i(x, 1, door)], BlockIds.FAKE_TRAVERTINE,
		Vector3i(0, 0, -1), Vector3i(2, -5, z0 + 4), [Vector3i(1, -3, z0), Vector3i(7, -3, z0)])
	var f := WonderBuilds.Frame.new(id)   # the steps go in after the room's air (they are air too), the lift on its floor
	for e: Array in steps:
		f.box(e[0], e[1], e[2])
	(r.boxes as Array).append_array(f.out)
	return r


## Chichen Itza: the pyramid inside the pyramid: a fake stone low in the north stair's west balustrade, a tunnel under
## the stair, a stair up inside to the inner temple with the red jaguar throne.
func _inner_pyramid() -> Dictionary:
	var id := &"chichen_itza"
	var extra: Array = [[Vector3i(-2, 0, -22), Vector3i(-2, 1, -12), BlockIds.AIR],   # the tunnel under the stair
		[Vector3i(-2, 2, -12), Vector3i(-2, 2, -12), BlockIds.AIR]]
	for k in 8:   # the stair up inside, a block a step, three high
		var z := -11 + k
		extra.append([Vector3i(-2, 0, z), Vector3i(-2, k, z), BlockIds.MAYA_STONE])
		extra.append([Vector3i(-2, k + 1, z), Vector3i(-2, k + 3, z), BlockIds.AIR])
	var room := [Vector3i(-7, 8, -3), Vector3i(-2, 10, 3)]
	var r := _frame_room(id, room, [Vector3i(-3, 0, -22), Vector3i(-3, 1, -22)], BlockIds.FAKE_MAYA_STONE,
		Vector3i(-1, 0, 0), Vector3i(-3, 8, 2), [Vector3i(-7, 10, -3), Vector3i(-7, 10, 3)], extra)
	var f := WonderBuilds.Frame.new(id)
	f.box(Vector3i(-7, 8, -1), Vector3i(-7, 8, 1), BlockIds.JAGUAR_THRONE)   # the red jaguar throne
	(r.boxes as Array).append_array(f.out)
	return r


## Machu Picchu: the cave under the Temple of the Sun, in the rock under its tower, behind a fake Inca stone in the
## rock's walled east face; a stepped altar inside.
func _royal_tomb() -> Dictionary:
	var id := &"machu_picchu"
	var y := WonderBuildsNew.MACHU_TOP
	var r := _frame_room(id, [Vector3i(-15, y, -7), Vector3i(-11, y + 2, -3)], [Vector3i(-10, y, -5), Vector3i(-10, y + 1, -5)],
		BlockIds.FAKE_INCA_STONE, Vector3i(1, 0, 0), Vector3i(-13, y, -3), [Vector3i(-15, y + 2, -7)])
	var f := WonderBuilds.Frame.new(id)
	f.box(Vector3i(-15, y, -6), Vector3i(-15, y, -4), BlockIds.INCA_STONE)   # the stepped altar
	f.cell(Vector3i(-15, y + 1, -5), BlockIds.INCA_STONE)
	(r.boxes as Array).append_array(f.out)
	return r


## Christ the Redeemer: the room inside the pedestal, behind a fake white stone at its back (workers go in there).
func _pedestal_room() -> Dictionary:
	var top := NewSevenGround.CORCOVADO_TOP
	return _frame_room(&"christ_redeemer", [Vector3i(-1, top, -1), Vector3i(1, top + 2, 1)],
		[Vector3i(0, top, 2), Vector3i(0, top + 1, 2)], BlockIds.FAKE_WHITE_BRICK, Vector3i(0, 0, 1), Vector3i(0, top, -1),
		[Vector3i(-1, top + 2, 1)])


## The Harbour of Rio de Janeiro: a climbers' ledge under the Sugarloaf's lookout on its south side: a gap in the
## lookout's wall, a step down, a small stone ledge jutting out with a chest (found when it is opened).
func _climbers_ledge() -> Dictionary:
	var id := &"rio_harbour"
	var sl := NatureGround.SUGARLOAF
	var c := Vector2i(int(sl.x), int(sl.y))
	var feet := NatureGround.SEA + NatureGround.SUGARLOAF_TOP - WonderTour.BASE_Y   # the lookout's feet (frame y)
	var f := WonderBuilds.Frame.new(id)
	f.box(Vector3i(c.x, feet, c.y + 4), Vector3i(c.x, feet + 2, c.y + 4), BlockIds.AIR)   # the gap in the wall
	f.cell(Vector3i(c.x, feet - 1, c.y + 4), BlockIds.STONE)
	f.cell(Vector3i(c.x, feet - 2, c.y + 5), BlockIds.STONE)   # a step down
	f.box(Vector3i(c.x, feet - 1, c.y + 5), Vector3i(c.x, feet + 1, c.y + 5), BlockIds.AIR)
	f.box(Vector3i(c.x - 1, feet - 3, c.y + 6), Vector3i(c.x + 1, feet - 3, c.y + 7), BlockIds.STONE)   # the ledge
	f.box(Vector3i(c.x - 1, feet - 2, c.y + 6), Vector3i(c.x + 1, feet, c.y + 7), BlockIds.AIR)
	var chest := _w(id, Vector3i(c.x, feet - 2, c.y + 7))
	f.cell(Vector3i(c.x, feet - 2, c.y + 7), BlockIds.AIR)
	return {"kind": TREASURE, "anchor": chest, "chest": chest, "chest_kind": &"sky",
		"yaw": _yaw(_wdir(id, Vector3i(0, 0, -1))), "boxes": f.out}


## The Northern Lights: the ice cave in the snow mound, lined with blue ice, behind a fake snow block on its east face
## (toward the deck), lit by ice lanterns.
func _ice_cave() -> Dictionary:
	var id := &"northern_lights"
	var m := NatureGround.MOUND
	var cx := int(m.x)
	var cz := int(m.y)
	var lining := [[Vector3i(cx - 3, -1, cz - 7), Vector3i(cx + 3, 3, cz - 1), BlockIds.BLUE_ICE]]
	var r := _frame_room(id, [Vector3i(cx - 2, 0, cz - 6), Vector3i(cx + 2, 2, cz - 2)],
		[Vector3i(cx, 0, cz - 7), Vector3i(cx, 1, cz - 7)], BlockIds.FAKE_SNOW, Vector3i(0, 0, -1),
		Vector3i(cx + 1, 0, cz - 2), [], lining)
	var f := WonderBuilds.Frame.new(id)   # ice lanterns in its back corners
	f.cell(Vector3i(cx - 2, 2, cz - 2), BlockIds.ICE_LANTERN)
	f.cell(Vector3i(cx + 2, 2, cz - 2), BlockIds.ICE_LANTERN)
	(r.boxes as Array).append_array(f.out)
	return r


## Parícutin: a room in the church tower of San Juan, behind a fake wall brick on its south face over the lava.
func _tower_room() -> Dictionary:
	var t := WonderBuildsNature.TOWER
	return _frame_room(&"paricutin", [Vector3i(t.x + 1, 3, t.y + 1), Vector3i(t.x + 2, 5, t.y + 2)],
		[Vector3i(t.x + 1, 3, t.y), Vector3i(t.x + 1, 4, t.y)], BlockIds.FAKE_WALL_BRICK, Vector3i(0, 0, -1),
		Vector3i(t.x + 2, 3, t.y + 2), [Vector3i(t.x + 1, 5, t.y + 2)])


## A golden chest in the Lighthouse's lantern, by the fire: found when it is opened.
func _lighthouse_chest() -> Dictionary:
	var id := &"lighthouse"
	var chest := _w(id, Vector3i(-1, WonderBuilds.LIGHTHOUSE_TOP, 0))
	var boxes: Array = []
	_box(boxes, chest, chest, BlockIds.AIR)
	return {"kind": TREASURE, "anchor": chest, "chest": chest, "chest_kind": &"sky",
		"yaw": _yaw(_wdir(id, Vector3i(0, 0, -1))), "boxes": boxes}
