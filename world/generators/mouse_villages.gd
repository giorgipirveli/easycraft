class_name MouseVillages
extends RefCounted
## The Tiny world (M3 Task 21c; spec §3a Size Magic "tiny-only secrets", §16 "a Tiny-only mouse village"), as pure
## rules. A mouse hole — a door one block high at the foot of a hill (HILL), or between the roots of a big old tree
## on a grassy knoll (KNOLL) — leads through a short tunnel into a mouse village: a little room under the ground with
## the mice's houses, a glowing lamp, a mouse family (MouseFamily, spawned near players) and a tiny treasure chest.
## Only a tiny child fits through the door (a normal-size child is two blocks tall); a pumpkin (the desert: a cactus,
## Frostpeak: a small snowman, the Candy Kingdom: a jack-o-lantern) stands by every door.
##
## Placed like secrets: from the seed, the 128 x 128 area and the terrain alone, every box inside its area (chunks
## meet without seams), at most one per area. SecretRules asks for them apart from its own (SecretRules.tiny_in_area;
## secrets_in_area never lists them), so no secret, no treasure-pack place (owner #42) and no wild-meadows place
## (owner #45b, which keeps GAP from the secrets it knows) moves for a mouse village: villages keep GAP from all of
## them instead, and CLEAR_OF_SPAWN from the world spawn, and stay off rivers and water. A village is a secret
## Dictionary (id "mice_<ax>_<az>_<n>", kind, area, anchor, boxes, lo/hi, chest + chest_kind + yaw) plus: room ([lo,
## hi) of the room's air), door (the door's open cell), visit (outside the door, where /secret sends you), dir (from
## the door into the hill), variant (HILL or KNOLL), markers (the marker's cells), tiny (true). No "inside": a
## normal-size child who digs in is shown out and never finds it (TinyDirector).
## Read-only apart from a cache behind a mutex, shared by every MouseVillages of the same world (the generator's
## threads work an area out once; the host's SecretDirector, whose SecretRules are its own, then finds it there
## instead of placing it again on the main thread).

const KIND := &"mice"
const NAME := "Mouse Village"
const CHEST_KIND := &"mouse"
const CHEST_SCALE := 0.45         # the mice's tiny chest
const HILL := &"hill"
const KNOLL := &"knoll"
const FIRST_ATTEMPT := 64         # ids "mice_<ax>_<az>_<64+>": never a secret's of the same area
## [chance] per attempt, in a fixed order (each draws its random numbers up front); the first that fits wins.
const ATTEMPTS: Array[float] = [0.55, 0.45, 0.4, 0.35]
const MARGIN := 24                # spots are drawn this far inside their area
const CLEAR_OF_SPAWN := 60.0      # like the treasure pack: the spawn's landmarks and the ways between them stay clear
const GAP := 4                    # blocks between a village and a secret or a place
const COVER := 0.5                # a hill covers this much of the room's shell: HILL (no mound, no tree)
const STEP := 2                   # the doorstep's ground may be this much off the door's level (filled or cut)

# The village in its own frame: along = from the door into the hill (0 = the door), across = to the side.
const SHELL_ALONG := Vector2i(0, 8)
const SHELL_ACROSS := 3
const ROOM_ALONG := Vector2i(3, 7)
const ROOM_ACROSS := 2
const ROOM_HIGH := 3              # the room's air: f .. f + 2
const ROOF := 3                   # the shell's roof over the floor level f
const MOUND_TOP := 5              # the knoll's grass over the floor level f
const MOUND_REACH := 6            # its slope: a block down a block round the shell's sides and back, to f - 1
const TRUNK := 5                  # the knoll's old tree
const DOORSTEP := 3               # the level ground in front of the door, blocks out
const MIDDLE := 5                 # the room's middle (the mice's home)

const MEADOWS := &"meadows"
const DESERT := &"desert"
const FROST := &"frost"
const CANDY := &"candy"
## Each universe's blocks. houses: the mice's houses, each a stack of blocks from the floor up.
const PALETTE := {
	MEADOWS: {"wall": BlockIds.PLANKS, "floor": BlockIds.PLANKS, "frame": BlockIds.LOG, "top": BlockIds.GRASS,
		"fill": BlockIds.DIRT, "lamp": BlockIds.GLOW_MUSHROOM, "log": BlockIds.LOG, "leaves": BlockIds.LEAVES,
		"marker": [BlockIds.PUMPKIN], "houses": [[BlockIds.PLANKS, BlockIds.RED], [BlockIds.PUMPKIN], [BlockIds.BARREL]]},
	DESERT: {"wall": BlockIds.CUT_SANDSTONE, "floor": BlockIds.PLANKS, "frame": BlockIds.PALM_LOG, "top": BlockIds.SAND,
		"fill": BlockIds.SANDSTONE, "lamp": BlockIds.DESERT_LAMP, "log": BlockIds.PALM_LOG, "leaves": BlockIds.PALM_LEAVES,
		"marker": [BlockIds.CACTUS, BlockIds.CACTUS], "houses": [[BlockIds.SANDSTONE, BlockIds.RED], [BlockIds.CACTUS],
		[BlockIds.BARREL]]},
	FROST: {"wall": BlockIds.SNOW_BRICK, "floor": BlockIds.PLANKS, "frame": BlockIds.PINE_LOG, "top": BlockIds.SNOWY_GRASS,
		"fill": BlockIds.DIRT, "lamp": BlockIds.ICE_LANTERN, "log": BlockIds.PINE_LOG, "leaves": BlockIds.PINE_NEEDLES,
		"marker": [BlockIds.PACKED_SNOW, BlockIds.SNOWMAN_HEAD], "houses": [[BlockIds.SNOW_BRICK, BlockIds.BLUE],
		[BlockIds.SNOWMAN_HEAD], [BlockIds.BARREL]]},
	CANDY: {"wall": BlockIds.GINGERBREAD, "floor": BlockIds.CAKE, "frame": BlockIds.CANDY_CANE, "top": BlockIds.FROSTING,
		"fill": BlockIds.CAKE, "lamp": BlockIds.CANDY_LAMP, "log": BlockIds.CANDY_CANE, "leaves": BlockIds.LOLLIPOP,
		"marker": [BlockIds.JACK_O_LANTERN], "houses": [[BlockIds.GINGERBREAD, BlockIds.RED], [BlockIds.JACK_O_LANTERN],
		[BlockIds.BARREL]]},
}
const DIRS: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 0, 1), Vector3i(-1, 0, 0), Vector3i(0, 0, -1)]
const CACHE_LIMIT := 1024
const SEA := MeadowsShape.SEA_LEVEL

# --- What children see and hear ---
const FOUND_TEXT := {KIND: "You found a mouse village!"}
const HINT_NAME := "mouse village"
## The Secret Book's picture riddle until one is found.
const BOOK_RIDDLE := "A tiny door by a hill. Get small!"
const TOO_BIG := "Too big for the mouse village! The mice showed you the way out."
const NOTICE := "Squeak! A tiny door! Only tiny friends fit in there."
## The tiny chest's gold in Survivor (x 2^(u-1)) and its little extras (one, fixed by the chest).
const GOLD := 10
const LITTLE_THINGS: Array = [[BlockIds.PUMPKIN, 2], [BlockIds.YELLOW, 4], [BlockIds.LANTERN, 1],
	[BlockIds.JACK_O_LANTERN, 1], [BlockIds.GLASS, 4], [ItemIds.POTION_JUMP, 1]]

var shape: MeadowsShape
var spawn: Vector2i
var seed: int
var style: StringName
var palette: Dictionary

var _rules: WeakRef                 # the SecretRules that own this (weak: it holds this strongly)
var _shared_places: WeakRef         # the world generator's own MeadowsPlaces (the same answers), when it has one
var _own_places: MeadowsPlaces
var _world_key := ""                # the world these villages are of: seed, terrain, secrets (the cache's key)
var _places_mutex := Mutex.new()

## "<world key>|<area>" -> the area's villages, for every world played in this session (the same world's
## MouseVillages share it: the answers are the same).
static var _cache := {}
static var _mutex := Mutex.new()


func _init(rules: SecretRules) -> void:
	_rules = weakref(rules)
	shape = rules.shape
	spawn = rules.spawn
	seed = rules.seed
	style = CANDY if shape is CandyShape else (FROST if shape is FrostShape else (DESERT if shape is DesertShape else MEADOWS))
	palette = PALETTE[style]
	_world_key = "%d|%s|%s|%s" % [seed, (shape.get_script() as Script).resource_path,
		(rules.get_script() as Script).resource_path, rules.more != null]


## Whether a world of this terrain has mouse villages: not over the Dragon Realm's void, not in an arena.
static func fits_terrain(terrain: MeadowsShape) -> bool:
	return not (terrain is DragonShape or terrain is ArenaShape)


## The wild meadows' generator lends its places (so they are worked out once); otherwise this works them out itself.
func share_places(places: MeadowsPlaces) -> void:
	_shared_places = weakref(places) if places != null else null


static func is_id(id: String) -> bool:
	var parts := id.split("_")
	return parts.size() == 4 and parts[0] == String(KIND) and parts[1].is_valid_int() and parts[2].is_valid_int() \
		and parts[3].is_valid_int()


## The mouse villages of one area (shared: never change the returned dictionaries).
func villages_in_area(area: Vector2i) -> Array:
	var key := "%s|%d|%d" % [_world_key, area.x, area.y]
	_mutex.lock()
	var cached: Variant = _cache.get(key)
	_mutex.unlock()
	if cached != null:
		return cached
	var list := _place(area)
	_mutex.lock()
	if _cache.size() >= CACHE_LIMIT:
		_cache.clear()
	_cache[key] = list
	_mutex.unlock()
	return list


## The block the villages put at p, or -1.
func block_at(p: Vector3i) -> int:
	for s: Dictionary in villages_in_area(SecretRules.area_of(p.x, p.z)):
		if not SecretRules._contains(s.lo, s.hi, p):
			continue
		var boxes: Array = s.boxes
		for i in range(boxes.size() - 1, -1, -1):
			if SecretRules._contains(boxes[i][0], boxes[i][1], p):
				return boxes[i][2]
	return -1


## The mice's tiny chest: their cheese (treasure only) and a little something, the same for the same chest, and in
## Survivor a little gold, always the same (GOLD x 2^(u-1); spec 6: nothing random for money).
static func loot(key: int, universe: int, survivor: bool) -> Dictionary:
	var extra: Array = LITTLE_THINGS[posmod(key, LITTLE_THINGS.size())]
	var items: Array = [[BlockIds.CHEESE, 1], [int(extra[0]), int(extra[1])]]
	return {"gold": GOLD * LootRules._scale(universe) if survivor else 0, "items": items,
		"rarity": LootRules.best_rarity(items), "title": Lang.t("The mice's treasure! ")}


# --- Placement --------------------------------------------------------------------------------------------------

func _place(area: Vector2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = _mix(area.x, area.y)
	var base := area * SecretRules.AREA
	var tries: Array = []
	for i in ATTEMPTS.size():
		tries.append([rng.randf(), base.x + rng.randi_range(MARGIN, SecretRules.AREA - MARGIN - 1),
			base.y + rng.randi_range(MARGIN, SecretRules.AREA - MARGIN - 1), int(rng.randi() & 0x7fffffff)])
	for i in tries.size():
		var t: Array = tries[i]
		if float(t[0]) >= ATTEMPTS[i]:
			continue
		var s := build(int(t[1]), int(t[2]), int(t[3]))
		if s.is_empty():
			continue
		_finish(s, area, FIRST_ATTEMPT + i)
		if _fits(s, area):
			return [s]
	return []


func _finish(s: Dictionary, area: Vector2i, n: int) -> void:
	s.id = "%s_%d_%d_%d" % [KIND, area.x, area.y, n]
	s.kind = KIND
	s.area = area
	s.tiny = true
	var lo := Vector3i(0x7fffffff, 0x7fffffff, 0x7fffffff)
	var hi := -lo
	for b: Array in s.boxes:
		lo = lo.min(b[0])
		hi = hi.max(b[1])
	s.lo = lo
	s.hi = hi


## Inside its area, clear of the spawn, GAP from the area's secrets and from the places of the wild meadows.
func _fits(s: Dictionary, area: Vector2i) -> bool:
	var lo: Vector3i = s.lo
	var hi: Vector3i = s.hi
	var a0 := area * SecretRules.AREA
	if lo.x < a0.x or lo.z < a0.y or hi.x > a0.x + SecretRules.AREA or hi.z > a0.y + SecretRules.AREA:
		return false
	var dx := maxi(maxi(lo.x - spawn.x, spawn.x - (hi.x - 1)), 0)
	var dz := maxi(maxi(lo.z - spawn.y, spawn.y - (hi.z - 1)), 0)
	if Vector2(dx, dz).length() < CLEAR_OF_SPAWN:
		return false
	var rules := _rules.get_ref() as SecretRules
	if rules != null:
		for o: Dictionary in rules.secrets_in_area(area):
			if _near(s, o):
				return false
	var places := _places()
	if places != null:
		var r0 := MeadowsPlaces.region_of(lo.x - GAP, lo.z - GAP)
		var r1 := MeadowsPlaces.region_of(hi.x + GAP, hi.z + GAP)
		for rz in range(r0.y, r1.y + 1):
			for rx in range(r0.x, r1.x + 1):
				for p: Dictionary in places.places_in_region(Vector2i(rx, rz)):
					if _near(s, p):
						return false
	return true


static func _near(s: Dictionary, o: Dictionary) -> bool:
	var lo: Vector3i = s.lo
	var hi: Vector3i = s.hi
	var olo: Vector3i = o.lo
	var ohi: Vector3i = o.hi
	return lo.x - GAP < ohi.x and olo.x < hi.x + GAP and lo.z - GAP < ohi.z and olo.z < hi.z + GAP


## The wild meadows' places (null in other terrains): the generator's own, or worked out here once.
func _places() -> MeadowsPlaces:
	if not shape is MeadowsBiomeShape:
		return null
	var shared := _shared_places.get_ref() as MeadowsPlaces if _shared_places != null else null
	if shared != null:
		return shared
	_places_mutex.lock()
	if _own_places == null:
		var rules := _rules.get_ref() as SecretRules
		if rules != null:
			_own_places = MeadowsPlaces.new(seed, shape as MeadowsBiomeShape, SecretsView.new(rules))
	var got := _own_places
	_places_mutex.unlock()
	return got


## The places' view of the secrets: the owner's own (held weakly, so nothing holds itself).
class SecretsView:
	extends SecretRules
	var _owner: WeakRef

	func _init(owner: SecretRules) -> void:
		super(owner.seed, owner.shape, false, false)
		_owner = weakref(owner)

	func secrets_in_area(area: Vector2i) -> Array:
		var o := _owner.get_ref() as SecretRules
		return o.secrets_in_area(area) if o != null else []


# --- The village ------------------------------------------------------------------------------------------------

## The mouse village whose door is at (x, z), or {} when none fits there: tries the four ways the door can face and
## takes the one most dug into a hill.
func build(x: int, z: int, v: int) -> Dictionary:
	var memo := {}
	var best := -1.0
	var pick := Vector3i.ZERO
	var floor_y := 0
	for k in 4:
		var dir := DIRS[(v + k) % 4]
		var f := _doorstep(memo, x, z, dir)
		if f == -0x7fffffff:
			continue
		var cover := _cover(memo, x, z, dir, f)
		if cover > best:
			best = cover
			pick = dir
			floor_y = f
	if best < 0.0 or not _ground_around(memo, x, z, pick, floor_y):
		return {}
	return _village(memo, Vector3i(x, floor_y, z), pick, HILL if best >= COVER else KNOLL, v)


## The door's floor level for a door at (x, z) facing out along -dir: the doorstep's middle ground; -0x7fffffff when
## the doorstep is uneven, wet, a river or has a tree.
func _doorstep(memo: Dictionary, x: int, z: int, dir: Vector3i) -> int:
	var side := Vector3i(-dir.z, 0, dir.x)
	var c := Vector3i(x, 0, z)
	var f := _h(memo, (c - dir).x, (c - dir).z)
	for along in range(1, DOORSTEP + 1):
		for across: int in [-1, 0, 1, 3]:     # 3: the marker's column
			var p := c - dir * along + side * across
			var h := _h(memo, p.x, p.z)
			if absi(h - f) > STEP or not _dry(memo, p.x, p.z) or shape.tree_at(p.x, p.z):
				return -0x7fffffff
	var mark := c - dir * 2 + side * 3
	for n: Vector3i in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
		if shape.tree_at(mark.x + n.x, mark.z + n.z):   # a trunk by the marker would wake with it
			return -0x7fffffff
	return f


## How much of the room's shell the natural ground already buries (0..1): a block of it at least over the roof.
func _cover(memo: Dictionary, x: int, z: int, dir: Vector3i, f: int) -> float:
	var side := Vector3i(-dir.z, 0, dir.x)
	var n := 0
	var covered := 0
	for along in range(SHELL_ALONG.x, SHELL_ALONG.y + 1, 2):
		for across in range(-SHELL_ACROSS, SHELL_ACROSS + 1, 2):
			var p := Vector3i(x, 0, z) + dir * along + side * across
			n += 1
			covered += int(_h(memo, p.x, p.z) >= f + MOUND_TOP)
	return float(covered) / n


## Dry land (no water, no river) under the shell and the knoll's slopes, and round them ground no lower than the
## slope's foot (f - 1), so a child walks onto the knoll a block at a time (its front is the door's wall).
func _ground_around(memo: Dictionary, x: int, z: int, dir: Vector3i, f: int) -> bool:
	var side := Vector3i(-dir.z, 0, dir.x)
	for along in range(0, SHELL_ALONG.y + MOUND_REACH + 2):
		for across in range(-SHELL_ACROSS - MOUND_REACH - 1, SHELL_ACROSS + MOUND_REACH + 2):
			var d := _mound_distance(along, across)
			if d > MOUND_REACH + 1:
				continue
			var p := Vector3i(x, 0, z) + dir * along + side * across
			if d <= MOUND_REACH:
				if not _dry(memo, p.x, p.z):
					return false
			elif along >= 1 and _h(memo, p.x, p.z) < f - 1:
				return false
	return true


## How far (blocks) a column of the village's frame is from the room's shell, sideways and behind.
static func _mound_distance(along: int, across: int) -> float:
	var dx := maxi(absi(across) - SHELL_ACROSS, 0)
	var db := maxi(along - SHELL_ALONG.y, 0)
	return sqrt(float(dx * dx + db * db))


func _village(memo: Dictionary, c: Vector3i, dir: Vector3i, variant: StringName, v: int) -> Dictionary:
	var side := Vector3i(-dir.z, 0, dir.x)
	var f := c.y
	var pal := palette
	var boxes: Array = []
	var at := func(along: int, across: int, up: int) -> Vector3i: return c + dir * along + side * across + Vector3i(0, up, 0)
	# The doorstep: level ground, open to the sky.
	SecretRules._box(boxes, at.call(-1, -1, -3), at.call(-DOORSTEP, 1, -2), pal.fill)
	SecretRules._box(boxes, at.call(-1, -1, -1), at.call(-DOORSTEP, 1, -1), pal.top)
	SecretRules._box(boxes, at.call(-1, -1, 0), at.call(-DOORSTEP, 1, ROOF), BlockIds.AIR)
	# The knoll (only where the land is lower): grass over the shell, sloping down a block a block at its sides and
	# back; its front is the door's wall.
	for along in range(0, SHELL_ALONG.y + MOUND_REACH + 1):
		for across in range(-SHELL_ACROSS - MOUND_REACH, SHELL_ACROSS + MOUND_REACH + 1):
			var top := f + MOUND_TOP - ceili(_mound_distance(along, across))
			var p: Vector3i = at.call(along, across, 0)
			var h := _h(memo, p.x, p.z)
			if top < h or top < f - 1 or h >= f + MOUND_TOP:   # the natural ground covers it already
				continue
			if top > h:
				SecretRules._box(boxes, Vector3i(p.x, h, p.z), Vector3i(p.x, top - 1, p.z), pal.fill)
			SecretRules._box(boxes, Vector3i(p.x, top, p.z), Vector3i(p.x, top, p.z), pal.top)
	# The shell, the room, the tunnel and the door.
	SecretRules._box(boxes, at.call(SHELL_ALONG.x, -SHELL_ACROSS, -1), at.call(SHELL_ALONG.y, SHELL_ACROSS, ROOF), pal.wall)
	SecretRules._box(boxes, at.call(ROOM_ALONG.x, -ROOM_ACROSS, -1), at.call(ROOM_ALONG.y, ROOM_ACROSS, -1), pal.floor)
	SecretRules._box(boxes, at.call(ROOM_ALONG.x, -ROOM_ACROSS, 0), at.call(ROOM_ALONG.y, ROOM_ACROSS, ROOM_HIGH - 1), BlockIds.AIR)
	SecretRules._box(boxes, at.call(0, 0, 0), at.call(ROOM_ALONG.x - 1, 0, 0), BlockIds.AIR)
	# The door's frame: tree roots round a knoll's door, beams in a hill's.
	SecretRules._box(boxes, at.call(0, -1, 0), at.call(0, -1, 1), pal.frame)
	SecretRules._box(boxes, at.call(0, 1, 0), at.call(0, 1, 1), pal.frame)
	SecretRules._box(boxes, at.call(0, 0, 1), at.call(0, 0, 1), pal.frame)
	# The mice's houses, a lamp in the back wall and one on a post.
	var houses: Array = pal.houses
	var spots: Array[Vector3i] = [at.call(ROOM_ALONG.y, -ROOM_ACROSS, 0), at.call(ROOM_ALONG.y, ROOM_ACROSS, 0),
		at.call(ROOM_ALONG.x + 1, ROOM_ACROSS, 0)]
	for i in spots.size():
		var stack: Array = houses[(i + v) % houses.size()]
		for k in stack.size():
			var cell: Vector3i = spots[i] + Vector3i(0, k, 0)
			SecretRules._box(boxes, cell, cell, int(stack[k]))
	var lamp: Vector3i = at.call(ROOM_ALONG.y + 1, 0, ROOM_HIGH - 1)
	SecretRules._box(boxes, lamp, lamp, pal.lamp)
	var post: Vector3i = at.call(ROOM_ALONG.x + 1, -ROOM_ACROSS, 0)
	SecretRules._box(boxes, post, post + Vector3i.UP, pal.lamp)
	# A knoll's big old tree.
	if variant == KNOLL:
		var trunk: Vector3i = at.call((SHELL_ALONG.x + SHELL_ALONG.y) / 2, 0, MOUND_TOP + 1)
		SecretRules._box(boxes, trunk + Vector3i(-2, TRUNK - 2, -2), trunk + Vector3i(2, TRUNK - 1, 2), pal.leaves)
		SecretRules._box(boxes, trunk + Vector3i(-1, TRUNK, -1), trunk + Vector3i(1, TRUNK, 1), pal.leaves)
		SecretRules._box(boxes, trunk, trunk + Vector3i(0, TRUNK - 1, 0), pal.log)
	# The marker by the door (never on the way in).
	var markers: Array[Vector3i] = []
	var mark: Vector3i = at.call(-2, 3, 0)
	SecretRules._box(boxes, mark + Vector3i(0, -3, 0), mark + Vector3i(0, -2, 0), pal.fill)
	SecretRules._box(boxes, mark + Vector3i.DOWN, mark + Vector3i.DOWN, pal.top)
	var stack: Array = pal.marker
	for k in stack.size():
		SecretRules._box(boxes, mark + Vector3i(0, k, 0), mark + Vector3i(0, k, 0), int(stack[k]))
		markers.append(mark + Vector3i(0, k, 0))
	var room_lo: Vector3i = at.call(ROOM_ALONG.x, -ROOM_ACROSS, 0)
	var room_hi: Vector3i = at.call(ROOM_ALONG.y, ROOM_ACROSS, ROOM_HIGH - 1)
	return {"anchor": at.call(MIDDLE, 0, 0), "chest": at.call(ROOM_ALONG.y, 0, 0), "chest_kind": CHEST_KIND,
		"yaw": SecretRules._yaw(-dir), "boxes": boxes, "room": [room_lo.min(room_hi), room_lo.max(room_hi) + Vector3i.ONE],
		"door": c, "visit": at.call(-2, 0, 0), "dir": dir, "variant": variant, "markers": markers}


# --- Ground -----------------------------------------------------------------------------------------------------

func _h(memo: Dictionary, x: int, z: int) -> int:
	var k := Vector2i(x, z)
	var got: Variant = memo.get(k)
	if got != null:
		return got[0]
	var h := shape.height_at(x, z)
	var river := shape.is_river(x, z)
	memo[k] = [h, river]
	return h


func _dry(memo: Dictionary, x: int, z: int) -> bool:
	var h := _h(memo, x, z)
	return h > SEA + 1 and not bool(memo[Vector2i(x, z)][1])


func _mix(x: int, z: int) -> int:
	var h := x * 374761393 ^ z * 668265263 ^ seed * 2246822519 ^ 0x6d696365
	h = (h ^ (h >> 15)) * 2654435761
	return (h ^ (h >> 13)) & 0x7fffffffffffffff
