class_name TreasurePlaces
extends RefCounted
## The treasure pack's places (owner feedback #42, spec §12.16b), as pure rules: shipwrecks, sunken chests,
## mineshafts with a loot cart, dungeon vaults behind three levers, waterfall caves, hollow trees, wishing
## wells, pirate coves, ruins, friendly haunted houses and campsites. SecretRules asks for them after its own
## M2 kinds (their attempts come last, so the M2 secrets and their saved ids never move) and keeps them in
## their 128 x 128 area and apart from the others, exactly like its own. Each universe builds the kinds that
## fit its land, in its own blocks (the palette): Green Meadows all of them, the Sandstorm Desert and
## Frostpeak six each.
##
## A place is a SecretRules secret Dictionary (anchor, boxes, chest + chest_kind + yaw, inside, ...) plus:
## door (the entrance's open cell at the feet), visit (where /secret sends you), and per kind: beach + dir
## (a shipwreck), levers + symbols + order + vault + steps + note (a vault), curtain (a waterfall), well (a
## well's opening), ghosts + riddle (a haunted house). No place stands within CLEAR_OF_SPAWN of the world
## spawn (the landmarks near it and the ways between them stay clear) or on a river, and every entrance is
## open. Read-only after construction: the generator's threads share it (its height lookups are memoised
## per call, never shared).

const SHIPWRECK := &"shipwreck"
const SUNKEN := &"sunken"
const MINESHAFT := &"mineshaft"
const VAULT := &"vault"
const WATERFALL := &"waterfall"
const HOLLOW := &"hollowtree"
const RAINBOW := &"rainbow"       # not a place: it comes while playing (TreasureRules)
const WELL := &"well"
const COVE := &"cove"
const RUINS := &"ruins"
const HAUNTED := &"haunted"
const CAMP := &"camp"
## Every kind of the pack, in the Secret Book's order (its "Treasure Hunt" page). No name has an "_": a
## secret's id is "<kind>_<area x>_<area z>_<attempt>".
const KINDS: Array[StringName] = [SHIPWRECK, SUNKEN, MINESHAFT, VAULT, WATERFALL, HOLLOW, RAINBOW, WELL, COVE,
	RUINS, HAUNTED, CAMP]
## The kinds the terrain generator builds.
const PLACED: Array[StringName] = [SHIPWRECK, SUNKEN, MINESHAFT, VAULT, WATERFALL, HOLLOW, WELL, COVE, RUINS,
	HAUNTED, CAMP]

const MEADOWS := &"meadows"
const DESERT := &"desert"
const FROST := &"frost"
const CANDY := &"candy"   # M3 Task 4's kingdom (merged after the pack): its own six, in candy
const DRAGON := &"dragon"   # owner 39: the Dragon Realm's five, in its blocks (DragonSecretRules keeps them on islands)
const GLOW := &"glow"   # universe 6: the Glow Caves' four, in its blocks (GlowSecretRules keeps them under the ceilings)
## [kind, chance] per attempt, after the M2 kinds', per universe style.
const ATTEMPTS := {
	MEADOWS: [[SHIPWRECK, 0.6], [SUNKEN, 0.6], [MINESHAFT, 0.3], [VAULT, 0.25], [WATERFALL, 0.3], [HOLLOW, 0.35],
		[WELL, 0.25], [COVE, 0.5], [RUINS, 0.3], [HAUNTED, 0.2], [CAMP, 0.4]],
	DESERT: [[SHIPWRECK, 0.3], [MINESHAFT, 0.35], [VAULT, 0.25], [WELL, 0.3], [RUINS, 0.4], [CAMP, 0.45]],
	FROST: [[MINESHAFT, 0.35], [VAULT, 0.25], [HOLLOW, 0.35], [RUINS, 0.35], [HAUNTED, 0.25], [CAMP, 0.45]],
	CANDY: [[MINESHAFT, 0.35], [VAULT, 0.25], [WELL, 0.3], [RUINS, 0.35], [HAUNTED, 0.25], [CAMP, 0.45]],
	DRAGON: [[MINESHAFT, 0.4], [VAULT, 0.3], [RUINS, 0.45], [HAUNTED, 0.3], [CAMP, 0.5]],
	GLOW: [[MINESHAFT, 0.45], [VAULT, 0.3], [RUINS, 0.45], [CAMP, 0.5]],
}
const KINDS_BY_STYLE := {
	MEADOWS: [SHIPWRECK, SUNKEN, MINESHAFT, VAULT, WATERFALL, HOLLOW, WELL, COVE, RUINS, HAUNTED, CAMP],
	DESERT: [SHIPWRECK, MINESHAFT, VAULT, WELL, RUINS, CAMP],
	FROST: [MINESHAFT, VAULT, HOLLOW, RUINS, HAUNTED, CAMP],
	CANDY: [MINESHAFT, VAULT, WELL, RUINS, HAUNTED, CAMP],
	DRAGON: [MINESHAFT, VAULT, RUINS, HAUNTED, CAMP],
	GLOW: [MINESHAFT, VAULT, RUINS, CAMP],
}
## Each universe's blocks for the same roles.
const PALETTE := {
	MEADOWS: {"wood": BlockIds.PLANKS, "log": BlockIds.LOG, "stone": BlockIds.STONE, "brick": BlockIds.BRICK,
		"pillar": BlockIds.BRICK, "lamp": BlockIds.LANTERN, "light": BlockIds.LIGHT, "leaves": BlockIds.LEAVES,
		"top": BlockIds.GRASS, "fill": BlockIds.DIRT, "plaza": BlockIds.STONE, "cloth": BlockIds.RED,
		"cloth2": BlockIds.YELLOW, "roof": BlockIds.LOG},
	DESERT: {"wood": BlockIds.PLANKS, "log": BlockIds.PALM_LOG, "stone": BlockIds.SANDSTONE,
		"brick": BlockIds.CUT_SANDSTONE, "pillar": BlockIds.CHISELED_SANDSTONE, "lamp": BlockIds.DESERT_LAMP,
		"light": BlockIds.DESERT_LAMP, "leaves": BlockIds.PALM_LEAVES, "top": BlockIds.SAND,
		"fill": BlockIds.SANDSTONE, "plaza": BlockIds.CUT_SANDSTONE, "cloth": BlockIds.RED, "cloth2": BlockIds.YELLOW,
		"roof": BlockIds.PALM_LOG},
	FROST: {"wood": BlockIds.PLANKS, "log": BlockIds.PINE_LOG, "stone": BlockIds.STONE,
		"brick": BlockIds.SNOW_BRICK, "pillar": BlockIds.SNOW_BRICK, "lamp": BlockIds.ICE_LANTERN,
		"light": BlockIds.ICE_LANTERN, "leaves": BlockIds.PINE_NEEDLES, "top": BlockIds.SNOWY_GRASS,
		"fill": BlockIds.DIRT, "plaza": BlockIds.PACKED_SNOW, "cloth": BlockIds.BLUE, "cloth2": BlockIds.YELLOW,
		"roof": BlockIds.PINE_LOG},
	CANDY: {"wood": BlockIds.GINGERBREAD, "log": BlockIds.CANDY_CANE, "stone": BlockIds.CAKE, "brick": BlockIds.JAM,
		"pillar": BlockIds.CANDY_CANE, "lamp": BlockIds.CANDY_LAMP, "light": BlockIds.CANDY_LAMP,
		"leaves": BlockIds.LOLLIPOP, "top": BlockIds.FROSTING, "fill": BlockIds.CAKE, "plaza": BlockIds.CREAM,
		"cloth": BlockIds.RED, "cloth2": BlockIds.YELLOW, "roof": BlockIds.GINGERBREAD},
	DRAGON: {"wood": BlockIds.MUSHROOM_STEM, "log": BlockIds.MUSHROOM_STEM, "stone": BlockIds.FLOATSTONE,
		"brick": BlockIds.FLOATSTONE_BRICK, "pillar": BlockIds.CRYSTAL_SPIRE, "lamp": BlockIds.MOON_LAMP,
		"light": BlockIds.MOON_LAMP, "leaves": BlockIds.GLOW_CAP, "top": BlockIds.SKY_GRASS, "fill": BlockIds.FLOATSTONE,
		"plaza": BlockIds.FLOATSTONE_BRICK, "cloth": BlockIds.PURPLE, "cloth2": BlockIds.YELLOW,
		"roof": BlockIds.DRAGON_SCALE},
	GLOW: {"wood": BlockIds.FUNGUS_PLANKS, "log": BlockIds.SHROOM_STEM, "stone": BlockIds.CAVE_STONE,
		"brick": BlockIds.FLOWSTONE, "pillar": BlockIds.SELENITE, "lamp": BlockIds.SPORE_LAMP,
		"light": BlockIds.SPORE_LAMP, "leaves": BlockIds.BLUE_SHROOM, "top": BlockIds.CAVE_STONE,
		"fill": BlockIds.CAVE_STONE, "plaza": BlockIds.FLOWSTONE, "cloth": BlockIds.BLUE, "cloth2": BlockIds.YELLOW,
		"roof": BlockIds.FUNGUS_PLANKS},
}

## No place within this many blocks (edge to spawn, sideways) of the world spawn: Tilly (12), the Totem
## (20), the hub circle (<= 11) and the Theater (28-48, 9 wide) and the ways between them stay clear.
const CLEAR_OF_SPAWN := 60.0
const SEA := MeadowsShape.SEA_LEVEL
const SHORE_RINGS: Array[int] = [0, 10, 20, 30]   # where a coast is looked for around the drawn spot
const SHORE_ANGLES := 8
const SHORE_REACH: Array[int] = [4, 8, 12, 16]   # how far on from the beach the water may be
const COAST_HINT := 6                   # ground this low somewhere around: a coast may be near
const SUNKEN_DEPTH := Vector2i(4, 12)   # blocks of water over a sunken chest
const MINE_STAIRS := 6                  # steps down to a mineshaft's tunnel
const MINE_TUNNEL := 14                 # the tunnel's length
const VAULT_DEPTH := 20                 # a vault's floor lies this far under the ground
## The spiral stairs' eight cells around the pillar, in walking order (each one next to the last).
const RING: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0),
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)]

var shape: MeadowsShape
var spawn: Vector2i
var style: StringName
var palette: Dictionary


func _init(terrain: MeadowsShape, spawn_column: Vector2i) -> void:
	shape = terrain
	spawn = spawn_column
	style = CANDY if terrain is CandyShape else (FROST if terrain is FrostShape else (DESERT if terrain is DesertShape else MEADOWS))
	if terrain is DragonShape:
		style = DRAGON   # owner 39
	elif terrain is GlowShape:
		style = GLOW   # universe 6
	palette = PALETTE[style]


static func is_kind(kind: StringName) -> bool:
	return KINDS.has(kind)


## [kind, chance] per attempt for this universe.
func attempts() -> Array:
	return ATTEMPTS[style]


## The place of `kind` drawn at (x, z) with the random bits v, or {} when it doesn't fit there.
func build(kind: StringName, x: int, z: int, v: int) -> Dictionary:
	var memo := {}
	var s: Dictionary
	match kind:
		SHIPWRECK:
			s = _shipwreck(memo, x, z, v)
		SUNKEN:
			s = _sunken(memo, x, z, v)
		MINESHAFT:
			s = _mineshaft(memo, x, z, v)
		VAULT:
			s = _vault(memo, x, z, v)
		WATERFALL:
			s = _waterfall(memo, x, z, v)
		HOLLOW:
			s = _hollow_tree(memo, x, z, v)
		WELL:
			s = _well(memo, x, z, v)
		COVE:
			s = _cove(memo, x, z, v)
		RUINS:
			s = _ruins(memo, x, z, v)
		HAUNTED:
			s = _haunted(memo, x, z, v)
		CAMP:
			s = _camp(memo, x, z, v)
	if s.is_empty() or not _clear_of_spawn(s.boxes):
		return {}
	return s


# --- Ground ------------------------------------------------------------------------------------

## (ground height, 1 when it is open land a building may stand on, 1 on a river) of column (x, z), looked up
## once per call of build(): Green Meadows' dry land off the rivers, the desert's open sand, Frostpeak's
## valleys.
func _col(memo: Dictionary, x: int, z: int) -> Vector3i:
	var k := Vector2i(x, z)
	var got: Variant = memo.get(k)
	if got != null:
		return got
	var out: Vector3i
	match style:
		DESERT:
			var c := (shape as DesertShape).column(x, z)
			out = Vector3i(c.x, 1 if c.y == DesertShape.DESERT else 0, 0)
		FROST:
			var c := (shape as FrostShape).column(x, z)
			out = Vector3i(c.x, 1 if c.y == FrostShape.VALLEY else 0, 0)
		_:
			if (shape as Object).get_script() == MeadowsShape or shape is MeadowsBiomeShape:   # owner #45b: one column call
				var c := shape._column(x, z)
				out = Vector3i(c.x, 1 if c.x > SEA + 1 and c.y == 0 else 0, c.y)
			else:                # another universe's terrain: its own rules, one call each
				var hh := shape.height_at(x, z)
				var river := 1 if shape.is_river(x, z) else 0
				out = Vector3i(hh, 1 if hh > SEA + 1 and river == 0 else 0, river)
	memo[k] = out
	return out


func _river(memo: Dictionary, x: int, z: int) -> bool:
	return _col(memo, x, z).z == 1


## Is there any coast within reach of (x, z)? The drawn spot and four spots SHORE_RINGS' last ring away are
## all high land: no (a cheap way out for most areas, which are inland).
func _coast_near(memo: Dictionary, x: int, z: int) -> bool:
	var r: int = SHORE_RINGS[SHORE_RINGS.size() - 1]
	for p: Vector2i in [Vector2i(x, z), Vector2i(x + r, z), Vector2i(x - r, z), Vector2i(x, z + r), Vector2i(x, z - r)]:
		if _h(memo, p.x, p.y) <= SEA + COAST_HINT:
			return true
	return false


func _h(memo: Dictionary, x: int, z: int) -> int:
	return _col(memo, x, z).x


## The cell right above the ground in `p`'s column.
func _ground_at(memo: Dictionary, p: Vector3i) -> Vector3i:
	return Vector3i(p.x, _h(memo, p.x, p.z), p.z)


## The lowest and highest ground of the rectangle between corners a and b (sideways, inclusive), sampled
## every `step` blocks and on its far edges; Vector2i(1, 0) (lo > hi) when a sample is not open land.
func _span(memo: Dictionary, a: Vector3i, b: Vector3i, step: int = 3) -> Vector2i:
	var lo := 0x7fffffff
	var hi := -0x7fffffff
	var x0 := mini(a.x, b.x)
	var x1 := maxi(a.x, b.x)
	var z0 := mini(a.z, b.z)
	var z1 := maxi(a.z, b.z)
	var xs: Array[int] = []
	for x in range(x0, x1, step):
		xs.append(x)
	xs.append(x1)
	var zs: Array[int] = []
	for z in range(z0, z1, step):
		zs.append(z)
	zs.append(z1)
	for z in zs:
		for x in xs:
			var c := _col(memo, x, z)
			if c.y == 0:
				return Vector2i(1, 0)
			lo = mini(lo, c.x)
			hi = maxi(hi, c.x)
	return Vector2i(lo, hi)


## Open land over the rectangle whose ground rises and falls at most `rise`: its (lo, hi), or (1, 0).
func _flat(memo: Dictionary, a: Vector3i, b: Vector3i, rise: int) -> Vector2i:
	var span := _span(memo, a, b)
	return span if span.x <= span.y and span.y - span.x <= rise else Vector2i(1, 0)


## Frostpeak: no igloo on the rectangle (it keeps its igloos whole; the other universes have none). Trees
## are simply cleared (pads, like the M2 temple), so nothing else is looked for.
func _no_igloo(a: Vector3i, b: Vector3i) -> bool:
	if style != FROST:
		return true
	var frost := shape as FrostShape
	var x1 := maxi(a.x, b.x)
	var z1 := maxi(a.z, b.z)
	for z in range(mini(a.z, b.z), z1 + 5, 5):
		for x in range(mini(a.x, b.x), x1 + 5, 5):
			if not frost.igloo_near(mini(x, x1), mini(z, z1)).is_empty():
				return false
	return true


## A beach column (dry, at most `land_max` high) near (x, z) with water in one of the four directions within
## SHORE_REACH: {"at": Vector2i, "h": its ground height, "dir": Vector3i towards the water, "water": blocks},
## or {}. Green Meadows' coasts are gentle, so the water may be a few blocks on.
func _shore(memo: Dictionary, x: int, z: int, v: int, land_max: int) -> Dictionary:
	if not _coast_near(memo, x, z):
		return {}
	var turn := (v >> 3) % SHORE_ANGLES
	for r in SHORE_RINGS:
		for i in (1 if r == 0 else SHORE_ANGLES):
			var a := TAU * float((i + turn) % SHORE_ANGLES) / SHORE_ANGLES
			var at := Vector2i(x + roundi(cos(a) * r), z + roundi(sin(a) * r))
			var h := _h(memo, at.x, at.y)
			if h < SEA or h > land_max or _river(memo, at.x, at.y):
				continue
			for k in 4:
				var d := SecretRules.DIRS[(k + v) % 4]
				for reach in SHORE_REACH:
					var w := at + Vector2i(d.x, d.z) * reach
					if _h(memo, w.x, w.y) <= SEA - 2 and not _river(memo, w.x, w.y):
						return {"at": at, "h": h, "dir": d, "water": reach}
	return {}


## A flat pad at level g over the rectangle between corners a and b (sideways): the ground under it filled
## up from lo - 1, its top the universe's ground, and everything above it cleared up to g + clear (trees
## too). Slopes are cut into and dips filled, so a place stands level on gentle hills.
func _pad(boxes: Array, a: Vector3i, b: Vector3i, lo: int, g: int, clear: int = 9) -> void:
	var a0 := Vector3i(a.x, 0, a.z)
	var b0 := Vector3i(b.x, 0, b.z)
	if lo < g - 1:
		_box(boxes, a0 + Vector3i(0, lo - 1, 0), b0 + Vector3i(0, g - 2, 0), _p("fill"))
	_box(boxes, a0 + Vector3i(0, g - 1, 0), b0 + Vector3i(0, g - 1, 0), _p("top"))
	_box(boxes, a0 + Vector3i(0, g, 0), b0 + Vector3i(0, g + clear, 0), BlockIds.AIR)


func _clear_of_spawn(boxes: Array) -> bool:
	var lo := Vector3i(0x7fffffff, 0, 0x7fffffff)
	var hi := Vector3i(-0x7fffffff, 0, -0x7fffffff)
	for b: Array in boxes:
		lo = lo.min(b[0])
		hi = hi.max(b[1])
	var dx := maxi(maxi(lo.x - spawn.x, spawn.x - (hi.x - 1)), 0)
	var dz := maxi(maxi(lo.z - spawn.y, spawn.y - (hi.z - 1)), 0)
	return Vector2(dx, dz).length() >= CLEAR_OF_SPAWN


func _p(role: String) -> int:
	return int(palette[role])


static func _box(boxes: Array, a: Vector3i, b: Vector3i, id: int) -> void:
	SecretRules._box(boxes, a, b, id)


static func _at(c: Vector3i, dir: Vector3i, side: Vector3i, along: int, across: int, up: int) -> Vector3i:
	return SecretRules._at(c, dir, side, along, across, up)


static func _side(dir: Vector3i) -> Vector3i:
	return Vector3i(-dir.z, 0, dir.x)


## [lo, hi) of the box between two cells (any order), for "inside".
static func _inside(a: Vector3i, b: Vector3i) -> Array:
	return [a.min(b), a.max(b) + Vector3i.ONE]


## A chest spot's facing: towards `dir`.
static func _yaw(dir: Vector3i) -> float:
	return SecretRules._yaw(dir)


# --- The places ----------------------------------------------------------------------------------

## A shipwreck: a broken plank ship washed up on a beach, its bow towards the water, on a mound of sand (the
## desert: lost in the dunes), with a mast and a torn sail, a hole in its side, barrels and a chest by the
## stern.
func _shipwreck(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var dir: Vector3i
	var beach: Vector2i
	var h: int
	var water := 0
	if style == DESERT:
		dir = SecretRules.DIRS[v % 4]
		beach = Vector2i(x, z)
		var e := Vector3i(x, 0, z)
		var span := _flat(memo, _at(e, dir, _side(dir), -3, -3, 0), _at(e, dir, _side(dir), 7, 3, 0), 4)
		if span.x > span.y:
			return {}
		h = _h(memo, x, z)
	else:
		var shore := _shore(memo, x, z, v, SEA + 2)
		if shore.is_empty():
			return {}
		dir = shore.dir
		beach = shore.at
		h = shore.h
		water = shore.water
	var side := _side(dir)
	var fy := h - 1
	var m := Vector3i(beach.x, fy, beach.y) + dir * 2      # the ship's middle, at its bottom
	var boxes: Array = []
	_box(boxes, _at(m, dir, side, -4, -2, -2), _at(m, dir, side, 4, 2, -1), BlockIds.SAND)   # a mound of sand
	_box(boxes, _at(m, dir, side, -4, -2, 1), _at(m, dir, side, 4, 2, 5), BlockIds.AIR)
	_box(boxes, _at(m, dir, side, -4, -2, 0), _at(m, dir, side, 3, 2, 0), _p("wood"))        # the bottom
	_box(boxes, _at(m, dir, side, 4, 0, 0), _at(m, dir, side, 4, 0, 1), _p("wood"))          # the bow's point
	for s: int in [-2, 2]:
		_box(boxes, _at(m, dir, side, -4, s, 1), _at(m, dir, side, 3, s, 2), _p("wood"))     # the sides
	_box(boxes, _at(m, dir, side, -4, -2, 1), _at(m, dir, side, -4, 2, 3), _p("wood"))       # the stern
	_box(boxes, _at(m, dir, side, 1, 2, 2), _at(m, dir, side, 2, 2, 2), BlockIds.AIR)        # broken planks
	_box(boxes, _at(m, dir, side, -1, -2, 1), _at(m, dir, side, 0, -2, 2), BlockIds.AIR)     # a hole to walk in
	_box(boxes, _at(m, dir, side, 0, 0, 1), _at(m, dir, side, 0, 0, 5), _p("log"))           # the mast
	_box(boxes, _at(m, dir, side, 0, -2, 5), _at(m, dir, side, 0, 2, 5), _p("log"))          # its yard
	_box(boxes, _at(m, dir, side, 0, -1, 3), _at(m, dir, side, 0, 1, 4), _p("cloth"))        # a torn sail
	_box(boxes, _at(m, dir, side, 0, 1, 3), _at(m, dir, side, 0, 1, 3), BlockIds.AIR)
	_box(boxes, _at(m, dir, side, -3, 1, 1), _at(m, dir, side, -3, 1, 1), BlockIds.BARREL)
	_box(boxes, _at(m, dir, side, 2, -1, 1), _at(m, dir, side, 2, -1, 1), BlockIds.BARREL)
	var chest := _at(m, dir, side, -3, -1, 1)
	var outside := _at(m, dir, side, -1, -3, 0)
	return {"anchor": _at(m, dir, side, -1, 0, 1), "chest": chest, "chest_kind": &"shipwreck", "yaw": _yaw(dir),
		"boxes": boxes, "beach": beach, "dir": dir, "water": water, "door": _at(m, dir, side, -1, -2, 1),
		"visit": Vector3i(outside.x, _h(memo, outside.x, outside.z), outside.z),
		"inside": _inside(_at(m, dir, side, -3, -1, 1), _at(m, dir, side, 3, 1, 3))}


## A sunken chest on the seabed, SUNKEN_DEPTH under the water, with broken planks and a barrel around it.
func _sunken(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	if not _coast_near(memo, x, z):
		return {}
	var turn := (v >> 3) % SHORE_ANGLES
	for r in SHORE_RINGS:
		for i in (1 if r == 0 else SHORE_ANGLES):
			var a := TAU * float((i + turn) % SHORE_ANGLES) / SHORE_ANGLES
			var at := Vector2i(x + roundi(cos(a) * r), z + roundi(sin(a) * r))
			var h := _h(memo, at.x, at.y)
			if SEA - h < SUNKEN_DEPTH.x or SEA - h > SUNKEN_DEPTH.y or _river(memo, at.x, at.y):
				continue
			var ok := true
			for d: Vector3i in SecretRules.DIRS:
				var n := at + Vector2i(d.x, d.z) * 2
				if absi(_h(memo, n.x, n.y) - h) > 1 or _river(memo, n.x, n.y):
					ok = false
					break
			if ok:
				return _sunken_at(memo, Vector3i(at.x, h, at.y), v)
	return {}


func _sunken_at(memo: Dictionary, c: Vector3i, v: int) -> Dictionary:
	var dir := SecretRules.DIRS[v % 4]
	var side := _side(dir)
	var boxes: Array = []
	_box(boxes, c, c, BlockIds.WATER)
	for e: Array in [[2, 0, _p("wood")], [-2, 1, _p("wood")], [1, -2, _p("wood")], [-1, 2, BlockIds.BARREL]]:
		var cell := _at(c, dir, side, int(e[0]), int(e[1]), 0)
		cell.y = _h(memo, cell.x, cell.z)
		_box(boxes, cell, cell, int(e[2]))
	return {"anchor": c, "chest": c, "chest_kind": &"sunken", "yaw": _yaw(dir), "boxes": boxes, "door": c,
		"visit": c + Vector3i(0, 2, 0), "inside": _inside(c - Vector3i(1, 1, 1), c + Vector3i(1, 2, 1))}


## A mineshaft: a timber frame over MINE_STAIRS plank steps down to a tunnel MINE_TUNNEL long with plank
## rails on log sleepers, log posts and beams with lanterns, and a loot cart (a chest on wheels) at the end.
## The tunnel goes the first way (of four) where ground covers it all the way.
func _mineshaft(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var e := Vector3i(x, 0, z)
	var span := _flat(memo, e - Vector3i(2, 0, 2), e + Vector3i(2, 0, 2), 4)
	if span.x > span.y or not _no_igloo(e - Vector3i(3, 0, 3), e + Vector3i(3, 0, 3)):
		return {}
	var h := _h(memo, x, z)
	var fy := h - 1 - MINE_STAIRS
	var end := MINE_STAIRS + MINE_TUNNEL - 1
	for turn in 4:
		var dir := SecretRules.DIRS[(v + turn) % 4]
		var side := _side(dir)
		var covered := true
		for k in range(MINE_STAIRS, end + 2, 3):
			for across: int in [-2, 0, 2]:
				var col := _at(e, dir, side, k, across, 0)
				var c := _col(memo, col.x, col.z)
				if c.y == 0 or c.x < fy + 7:
					covered = false  # the tunnel would come out of the ground, or run under water
					break
			if not covered:
				break
		if covered:
			return _mineshaft_at(memo, e, h, span.x, dir)
	return {}


func _mineshaft_at(memo: Dictionary, e: Vector3i, h: int, lo: int, dir: Vector3i) -> Dictionary:
	var side := _side(dir)
	var fy := h - 1 - MINE_STAIRS
	var end := MINE_STAIRS + MINE_TUNNEL - 1
	var c0 := Vector3i(e.x, h, e.z)
	var boxes: Array = []
	_pad(boxes, _at(e, dir, side, -3, -2, 0), _at(e, dir, side, 0, 2, 0), lo, h, 5)                 # the way in
	for k in MINE_STAIRS:                                                                          # the stairs
		var step_y := h - 1 - k
		var col := _at(e, dir, side, k, 0, 0)
		var top := mini(h - 1, _h(memo, col.x, col.z) - 1)
		if k >= 2 and top >= step_y:
			_box(boxes, Vector3i(col.x, step_y, col.z) - side * 2, Vector3i(col.x, top, col.z) + side * 2, _p("stone"))
		_box(boxes, Vector3i(col.x, step_y, col.z) - side, Vector3i(col.x, step_y, col.z) + side, _p("wood"))
		_box(boxes, Vector3i(col.x, step_y + 1, col.z) - side, Vector3i(col.x, step_y + 4, col.z) + side, BlockIds.AIR)
	var t := Vector3i(e.x, fy, e.z)
	_box(boxes, _at(t, dir, side, MINE_STAIRS, -2, 0), _at(t, dir, side, end + 1, 2, 4), _p("stone"))   # the shell
	_box(boxes, _at(t, dir, side, MINE_STAIRS, -1, 1), _at(t, dir, side, end, 1, 3), BlockIds.AIR)
	_box(boxes, _at(t, dir, side, MINE_STAIRS, 0, 0), _at(t, dir, side, end, 0, 0), _p("wood"))            # the rails
	for k in range(MINE_STAIRS + 1, end + 1, 3):
		_box(boxes, _at(t, dir, side, k, -1, 0), _at(t, dir, side, k, 1, 0), _p("log"))                 # sleepers
	for k in range(MINE_STAIRS + 2, end - 1, 4):
		for s: int in [-1, 1]:
			_box(boxes, _at(t, dir, side, k, s, 1), _at(t, dir, side, k, s, 2), _p("log"))            # posts
		_box(boxes, _at(t, dir, side, k, -1, 3), _at(t, dir, side, k, 1, 3), _p("wood"))               # a beam
		_box(boxes, _at(t, dir, side, k, 0, 3), _at(t, dir, side, k, 0, 3), _p("lamp"))                # its lantern
	_box(boxes, _at(t, dir, side, MINE_STAIRS, -2, 2), _at(t, dir, side, MINE_STAIRS, -2, 2), _p("lamp"))
	for s: int in [-2, 2]:                                                                         # the frame
		_box(boxes, _at(c0, dir, side, 0, s, 0), _at(c0, dir, side, 0, s, 2), _p("log"))
	_box(boxes, _at(c0, dir, side, 0, -2, 3), _at(c0, dir, side, 0, 2, 3), _p("wood"))
	_box(boxes, _at(t, dir, side, end - 1, 1, 1), _at(t, dir, side, end - 1, 1, 1), BlockIds.BARREL)
	var chest := _at(t, dir, side, end - 1, 0, 1)
	return {"anchor": _at(t, dir, side, MINE_STAIRS + MINE_TUNNEL / 2, 0, 1), "chest": chest, "chest_kind": &"cart",
		"yaw": _yaw(-dir), "boxes": boxes, "dir": dir, "door": c0, "visit": _at(c0, dir, side, -2, 0, 0),
		"inside": _inside(_at(t, dir, side, MINE_STAIRS, -1, 1), _at(t, dir, side, end, 1, 3))}


## A dungeon vault: a lantern on a pillar marks a spiral stair that goes VAULT_DEPTH down to a hall with three
## levers in its wall (a key, a crown and a gem painted over them) and a note with their order; the right
## order opens the golden door to the vault and its legendary chest (SecretDirector / TreasureDirector).
func _vault(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var e := Vector3i(x, 0, z)
	var span := _flat(memo, e - Vector3i(3, 0, 3), e + Vector3i(3, 0, 3), 4)
	if span.x > span.y or not _no_igloo(e - Vector3i(3, 0, 3), e + Vector3i(3, 0, 3)):
		return {}
	var h := _h(memo, x, z)
	var f := h - VAULT_DEPTH
	for turn in 4:
		var dir := SecretRules.DIRS[(v + turn) % 4]
		var side := _side(dir)
		var covered := true
		for along in [4, 8, 12, 16]:
			for across in [-4, 4]:
				var col := _at(e, dir, side, along, across, 0)
				var c := _col(memo, col.x, col.z)
				if c.x < f + 8 or (style == MEADOWS and c.x <= SEA + 1):
					covered = false  # the hall would poke out, or lie under the sea
			if not covered:
				break
		if covered:
			return _vault_at(memo, e, h, span.x, dir, v)
	return {}


func _vault_at(memo: Dictionary, e: Vector3i, h: int, lo: int, dir: Vector3i, v: int) -> Dictionary:
	var x := e.x
	var z := e.z
	var side := _side(dir)
	var f := h - VAULT_DEPTH
	var c := Vector3i(x, f, z)
	var boxes: Array = []
	_pad(boxes, e - Vector3i(3, 0, 3), e + Vector3i(3, 0, 3), lo, h, 6)
	_box(boxes, Vector3i(x - 2, f, z - 2), Vector3i(x + 2, h - 1, z + 2), _p("brick"))                   # the shaft
	_box(boxes, _at(c, dir, side, 2, -4, 0), _at(c, dir, side, 10, 4, 4), _p("brick"))                   # the hall
	_box(boxes, _at(c, dir, side, 10, -3, 0), _at(c, dir, side, 16, 3, 4), _p("brick"))                  # the vault
	_box(boxes, Vector3i(x - 1, f + 1, z - 1), Vector3i(x + 1, h + 2, z + 1), BlockIds.AIR)
	_box(boxes, Vector3i(x, f, z), Vector3i(x, h - 1, z), _p("brick"))                                  # the pillar
	_box(boxes, Vector3i(x, h, z), Vector3i(x, h, z), _p("lamp"))
	for s: int in [-2, 2]:
		for t: int in [-2, 2]:
			_box(boxes, Vector3i(x + s, h, z + t), Vector3i(x + s, h + 1, z + t), _p("brick"))       # corner posts
	_box(boxes, _at(c, dir, side, 3, -3, 1), _at(c, dir, side, 9, 3, 3), BlockIds.AIR)
	_box(boxes, _at(c, dir, side, 11, -2, 1), _at(c, dir, side, 15, 2, 3), BlockIds.AIR)
	_box(boxes, _at(c, dir, side, 2, 0, 1), _at(c, dir, side, 2, 0, 2), BlockIds.AIR)                    # out of the shaft
	var steps: Array[Vector3i] = []
	var n := h - 1 - f
	var exit := RING.find(Vector2i(dir.x, dir.z))
	var start := posmod(exit - 1 - (n - 1), RING.size())
	for k in n:
		var r := RING[(start + k) % RING.size()]
		var step := Vector3i(x + r.x, h - 1 - k, z + r.y)
		_box(boxes, step, step, _p("brick"))
		steps.append(step)
	var levers: Array[Vector3i] = []
	for along: int in [4, 6, 8]:
		var cell := _at(c, dir, side, along, -4, 2)
		_box(boxes, cell, cell, BlockIds.LEVER)
		levers.append(cell)
	for along: int in [4, 8, 12, 14]:
		var lamp := _at(c, dir, side, along, 0, 4)
		_box(boxes, lamp, lamp, _p("light"))
	var vault: Array[Vector3i] = [_at(c, dir, side, 10, 0, 1), _at(c, dir, side, 10, 0, 2)]
	_box(boxes, vault[0], vault[1], BlockIds.YELLOW)                                                   # the golden door
	var symbols := SecretRules._permutation(TreasureRules.VAULT_SYMBOLS, v >> 2)
	var order := SecretRules._permutation([0, 1, 2], v >> 5)
	var pictures: Array[int] = [symbols[order[0]], symbols[order[1]], symbols[order[2]]]
	var outside := e + dir * 4
	return {"anchor": Vector3i(x, h, z), "chest": _at(c, dir, side, 14, 0, 1), "chest_kind": &"vault", "locked": true,
		"yaw": _yaw(-dir), "boxes": boxes, "dir": dir, "side": side, "levers": levers, "symbols": symbols,
		"order": order, "vault": vault, "steps": steps, "door": steps[0] + Vector3i.UP,
		"hall": _inside(_at(c, dir, side, 3, -3, 1), _at(c, dir, side, 9, 3, 3)),
		"note": {"cell": _at(c, dir, side, 5, 3, 1), "text": TreasureRules.VAULT_TEXT, "pictures": pictures,
			"yaw": _yaw(-side)},
		"visit": Vector3i(outside.x, h, outside.z),
		"inside": _inside(_at(c, dir, side, 11, -2, 1), _at(c, dir, side, 15, 2, 3))}


## A waterfall cave: a mossy rock with a stream on top pouring over the front, down past the mouth of a cave
## lit by crystals, into a shallow pool; a chest waits at the back of the cave.
func _waterfall(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var dir := SecretRules.DIRS[v % 4]
	var side := _side(dir)
	var e := Vector3i(x, 0, z)
	var span := _flat(memo, _at(e, dir, side, -6, -6, 0), _at(e, dir, side, 8, 6, 0), 5)
	if span.x > span.y:
		return {}
	var g := clampi(_h(memo, x, z), span.x, span.y)
	var c := Vector3i(x, g, z)
	var boxes: Array = []
	_pad(boxes, _at(c, dir, side, -6, -6, 0), _at(c, dir, side, 8, 6, 0), span.x, g, 10)
	_box(boxes, _at(c, dir, side, -5, -5, -1), _at(c, dir, side, 3, 5, 6), BlockIds.STONE)        # the rock
	_box(boxes, _at(c, dir, side, -4, -4, 7), _at(c, dir, side, 2, 4, 7), _p("top"))              # its mossy top
	for s: int in [-5, 5]:
		_box(boxes, _at(c, dir, side, -5, s, 6), _at(c, dir, side, 3, s, 6), BlockIds.AIR)        # rounded edges
	_box(boxes, _at(c, dir, side, -5, -5, 6), _at(c, dir, side, -5, 5, 6), BlockIds.AIR)
	for bush: Vector3i in [Vector3i(-2, 8, -3), Vector3i(-3, 8, 2), Vector3i(0, 8, 3)]:
		var cell := _at(c, dir, side, bush.x, bush.z, bush.y)
		_box(boxes, cell, cell, _p("leaves"))
	_box(boxes, _at(c, dir, side, 4, -3, -1), _at(c, dir, side, 7, 2, -1), BlockIds.WATER)       # the pool
	_box(boxes, _at(c, dir, side, 4, -3, -2), _at(c, dir, side, 7, 2, -2), BlockIds.SAND)
	_box(boxes, _at(c, dir, side, -3, -1, 0), _at(c, dir, side, 3, 1, 2), BlockIds.AIR)          # the cave
	_box(boxes, _at(c, dir, side, 0, -1, 7), _at(c, dir, side, 3, 0, 7), BlockIds.WATER)          # the stream on top
	var curtain: Array[Vector3i] = []
	for across: int in [-1, 0]:
		for up in range(1, 8):
			curtain.append(_at(c, dir, side, 4, across, up))
	_box(boxes, _at(c, dir, side, 4, -1, 1), _at(c, dir, side, 4, 0, 7), BlockIds.WATER)          # the waterfall
	for crystal: Vector3i in [Vector3i(-1, 1, -2), Vector3i(1, 1, 2), Vector3i(-4, 2, 0), Vector3i(0, 3, 0)]:
		var cell := _at(c, dir, side, crystal.x, crystal.z, crystal.y)
		_box(boxes, cell, cell, BlockIds.CRYSTAL)
	return {"anchor": _at(c, dir, side, -1, 0, 0), "chest": _at(c, dir, side, -3, 0, 0), "chest_kind": &"waterfall",
		"yaw": _yaw(dir), "boxes": boxes, "dir": dir, "curtain": curtain, "door": _at(c, dir, side, 3, 1, 0),
		"visit": _at(c, dir, side, 8, 0, 0),
		"inside": _inside(_at(c, dir, side, -3, -1, 0), _at(c, dir, side, 2, 1, 2))}


## A hollow tree: a giant trunk with a doorway into a hollow room and a chest in it, under a big crown (a
## pine's cone of needles in Frostpeak).
func _hollow_tree(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var dir := SecretRules.DIRS[v % 4]
	var side := _side(dir)
	var e := Vector3i(x, 0, z)
	var span := _flat(memo, _at(e, dir, side, -4, -4, 0), _at(e, dir, side, 5, 4, 0), 3)
	if span.x > span.y or not _no_igloo(e - Vector3i(5, 0, 5), e + Vector3i(5, 0, 5)):
		return {}
	var g := clampi(_h(memo, x, z), span.x, span.y)
	var c := Vector3i(x, g, z)
	var boxes: Array = []
	_pad(boxes, _at(c, dir, side, -4, -4, 0), _at(c, dir, side, 5, 4, 0), span.x, g, 9)
	_box(boxes, Vector3i(x - 2, g - 1, z - 2), Vector3i(x + 2, g + 10, z + 2), _p("log"))          # the trunk
	for s: int in [-2, 2]:
		for t: int in [-2, 2]:
			_box(boxes, Vector3i(x + s, g, z + t), Vector3i(x + s, g + 10, z + t), BlockIds.AIR)   # round it
	for root: Vector2i in [Vector2i(-3, 0), Vector2i(0, 3), Vector2i(0, -3)]:
		var cell := _at(c, dir, side, root.x, root.y, 0)
		_box(boxes, cell, cell, _p("log"))
	if style == FROST:
		for k in 4:
			SecretRules._disc(boxes, Vector3i(x, g + 8 + k * 2, z), 4 - k, _p("leaves"))
			SecretRules._disc(boxes, Vector3i(x, g + 9 + k * 2, z), maxi(3 - k, 0), _p("leaves"))
	else:
		SecretRules._ball(boxes, Vector3i(x, g + 12, z), 4, _p("leaves"))
		_box(boxes, Vector3i(x - 1, g + 10, z - 1), Vector3i(x + 1, g + 12, z + 1), _p("log"))
	_box(boxes, Vector3i(x - 1, g, z - 1), Vector3i(x + 1, g + 2, z + 1), BlockIds.AIR)            # the hollow
	_box(boxes, _at(c, dir, side, 2, 0, 0), _at(c, dir, side, 2, 0, 1), BlockIds.AIR)             # its doorway
	return {"anchor": c, "chest": _at(c, dir, side, -1, 0, 0), "chest_kind": &"hollowtree", "yaw": _yaw(dir),
		"boxes": boxes, "dir": dir, "door": _at(c, dir, side, 2, 0, 0), "visit": _at(c, dir, side, 4, 0, 0),
		"inside": _inside(Vector3i(x - 1, g, z - 1), Vector3i(x + 1, g + 2, z + 1))}


## A wishing well in a village-like clearing: a round cobbled plaza, a well with a rim, posts and a little
## roof, two lamp posts and two benches. Tapping the well tosses a coin (TreasureDirector).
func _well(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var e := Vector3i(x, 0, z)
	var span := _flat(memo, e - Vector3i(5, 0, 5), e + Vector3i(5, 0, 5), 3)
	if span.x > span.y or not _no_igloo(e - Vector3i(6, 0, 6), e + Vector3i(6, 0, 6)):
		return {}
	var g := clampi(_h(memo, x, z), span.x, span.y)
	var c := Vector3i(x, g, z)
	var boxes: Array = []
	for dz in range(-5, 6):                                                                        # the plaza
		var hw := int(sqrt(5.5 * 5.5 - dz * dz))
		if span.x < g - 1:
			_box(boxes, Vector3i(x - hw, span.x - 1, z + dz), Vector3i(x + hw, g - 2, z + dz), _p("fill"))
		_box(boxes, Vector3i(x - hw, g, z + dz), Vector3i(x + hw, g + 7, z + dz), BlockIds.AIR)
		_box(boxes, Vector3i(x - hw, g - 1, z + dz), Vector3i(x + hw, g - 1, z + dz), _p("plaza"))
	_box(boxes, Vector3i(x - 1, g - 5, z - 1), Vector3i(x + 1, g, z + 1), _p("brick"))              # the well
	_box(boxes, Vector3i(x, g - 4, z), Vector3i(x, g - 1, z), BlockIds.WATER)
	_box(boxes, c, c, BlockIds.AIR)
	for p: Vector2i in [Vector2i(-1, -1), Vector2i(1, 1)]:
		_box(boxes, Vector3i(x + p.x, g + 1, z + p.y), Vector3i(x + p.x, g + 2, z + p.y), _p("log"))
	_box(boxes, Vector3i(x - 1, g + 3, z - 1), Vector3i(x + 1, g + 3, z + 1), _p("wood"))           # its roof
	var dir := SecretRules.DIRS[v % 4]
	var side := _side(dir)
	for s: int in [-4, 4]:                                                                         # lamp posts
		var post := _at(c, dir, side, 0, s, 0)
		_box(boxes, post, post + Vector3i(0, 1, 0), _p("log"))
		_box(boxes, post + Vector3i(0, 2, 0), post + Vector3i(0, 2, 0), _p("lamp"))
	for b: Vector2i in [Vector2i(3, -3), Vector2i(-3, 3)]:                                         # benches
		var bench := _at(c, dir, side, b.x, b.y, 0)
		_box(boxes, bench, bench + side, _p("wood"))
	return {"anchor": c, "well": c, "boxes": boxes, "dir": dir, "door": _at(c, dir, side, 3, 0, 0),
		"visit": _at(c, dir, side, 3, 0, 0), "inside": _inside(c - Vector3i(4, 0, 4), c + Vector3i(4, 3, 4))}


## A pirate cove: a rock dome on the shore with a sandy floor, a lagoon by its mouth (which faces the water),
## barrels, lanterns, a flag on top and a chest at the back.
func _cove(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var shore := _shore(memo, x, z, v >> 4, SEA + 1)
	if shore.is_empty():
		return {}
	var dir: Vector3i = shore.dir
	var side := _side(dir)
	var at: Vector2i = shore.at
	var f := SEA - 1
	var c := Vector3i(at.x, f, at.y) - dir * 3
	for across: int in [-4, 0, 4]:
		for along: int in [-4, 0, 4]:
			var col := _at(c, dir, side, along, across, 0)
			if _river(memo, col.x, col.z):
				return {}
	for across: int in [-2, 0, 2]:
		var front := _at(c, dir, side, 6, across, 0)
		if _h(memo, front.x, front.z) > SEA + 1:
			return {}            # the mouth must open onto the beach and the water
	var boxes: Array = []
	_box(boxes, _at(c, dir, side, -4, -4, -1), _at(c, dir, side, 4, 4, 5), _p("stone"))             # the dome
	for s: int in [-4, 4]:
		_box(boxes, _at(c, dir, side, -4, s, 5), _at(c, dir, side, 4, s, 5), BlockIds.AIR)
		_box(boxes, _at(c, dir, side, s, -4, 5), _at(c, dir, side, s, 4, 5), BlockIds.AIR)
	_box(boxes, _at(c, dir, side, -3, -3, 0), _at(c, dir, side, 3, 3, 0), BlockIds.SAND)             # its floor
	_box(boxes, _at(c, dir, side, -3, -3, 1), _at(c, dir, side, 3, 3, 3), BlockIds.AIR)
	_box(boxes, _at(c, dir, side, 4, -2, 1), _at(c, dir, side, 4, 2, 2), BlockIds.AIR)               # the mouth
	_box(boxes, _at(c, dir, side, 5, -2, 1), _at(c, dir, side, 6, 2, 3), BlockIds.AIR)               # the way in
	_box(boxes, _at(c, dir, side, 1, -1, 0), _at(c, dir, side, 3, 0, 0), BlockIds.WATER)             # the lagoon
	_box(boxes, _at(c, dir, side, -2, 0, 6), _at(c, dir, side, -2, 0, 9), _p("log"))                 # the flag
	_box(boxes, _at(c, dir, side, -2, 1, 8), _at(c, dir, side, -2, 2, 9), BlockIds.RED)
	_box(boxes, _at(c, dir, side, -2, 2, 9), _at(c, dir, side, -2, 2, 9), BlockIds.YELLOW)
	for b: Vector2i in [Vector2i(-2, -2), Vector2i(-2, 2), Vector2i(-3, -1)]:
		var cell := _at(c, dir, side, b.x, b.y, 1)
		_box(boxes, cell, cell, BlockIds.BARREL)
	for s: int in [-4, 4]:
		var lamp := _at(c, dir, side, 0, s, 2)
		_box(boxes, lamp, lamp, _p("lamp"))
	return {"anchor": _at(c, dir, side, 0, 0, 1), "chest": _at(c, dir, side, -3, 0, 1), "chest_kind": &"cove",
		"yaw": _yaw(dir), "boxes": boxes, "dir": dir, "door": _at(c, dir, side, 4, 2, 1),
		"visit": _ground_at(memo, _at(c, dir, side, 6, 2, 0)),
		"inside": _inside(_at(c, dir, side, -3, -3, 1), _at(c, dir, side, 3, 3, 3))}


## Ancient ruins: a broken floor, standing and fallen pillars, wall stubs, an old note with a riddle about
## another secret and a chest behind the back wall's stub.
func _ruins(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var dir := SecretRules.DIRS[v % 4]
	var side := _side(dir)
	var e := Vector3i(x, 0, z)
	var span := _flat(memo, _at(e, dir, side, -5, -5, 0), _at(e, dir, side, 5, 5, 0), 4)
	if span.x > span.y or not _no_igloo(_at(e, dir, side, -5, -5, 0), _at(e, dir, side, 5, 5, 0)):
		return {}
	var g := clampi(_h(memo, x, z), span.x, span.y)
	var c := Vector3i(x, g, z)
	var boxes: Array = []
	_pad(boxes, _at(c, dir, side, -5, -5, 0), _at(c, dir, side, 5, 5, 0), span.x, g, 8)
	_box(boxes, _at(c, dir, side, -4, -4, -2), _at(c, dir, side, 4, 4, -1), _p("brick"))            # the floor
	for k in 6:                                                                                    # grass in its cracks
		var cell := _at(c, dir, side, ((v >> (k * 3)) % 7) - 3, ((v >> (k * 3 + 1)) % 7) - 3, -1)
		_box(boxes, cell, cell, _p("top"))
	var heights := [5, 2, 4, 1]
	var corners: Array[Vector2i] = [Vector2i(-4, -4), Vector2i(-4, 4), Vector2i(4, 4), Vector2i(4, -4)]
	for i in 4:
		var hgt: int = heights[(i + (v >> 20)) % 4]
		var p := _at(c, dir, side, corners[i].x, corners[i].y, 0)
		_box(boxes, p, p + Vector3i(0, hgt - 1, 0), _p("pillar"))
	_box(boxes, _at(c, dir, side, -4, -3, 0), _at(c, dir, side, -4, -1, 1), _p("brick"))            # wall stubs
	_box(boxes, _at(c, dir, side, -4, 1, 0), _at(c, dir, side, -4, 3, 0), _p("brick"))
	_box(boxes, _at(c, dir, side, -1, 4, 0), _at(c, dir, side, 2, 4, 0), _p("brick"))
	_box(boxes, _at(c, dir, side, 2, -3, 0), _at(c, dir, side, 2, 0, 0), _p("pillar"))              # a fallen pillar
	var note := Riddles.room_note(v >> 9)
	return {"anchor": c, "chest": _at(c, dir, side, -3, 0, 0), "chest_kind": &"ruins", "yaw": _yaw(dir),
		"boxes": boxes, "dir": dir, "door": _at(c, dir, side, 4, 0, 0), "visit": _at(c, dir, side, 5, 0, 0),
		"note": {"cell": _at(c, dir, side, 0, -2, 0), "text": note.text, "pictures": note.pictures, "yaw": _yaw(dir)},
		"inside": _inside(_at(c, dir, side, -3, -3, 0), _at(c, dir, side, 3, 3, 3))}


## A friendly haunted house: an old wooden house on a stone foundation, dark log corners and roof, broken
## windows, a closet and a barrel inside; two gentle ghosts float in it and ask a picture riddle; the right
## answer opens the chest (TreasureDirector).
func _haunted(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var dir := SecretRules.DIRS[v % 4]
	var side := _side(dir)
	var e := Vector3i(x, 0, z)
	var span := _flat(memo, _at(e, dir, side, -4, -4, 0), _at(e, dir, side, 6, 4, 0), 4)
	if span.x > span.y or not _no_igloo(_at(e, dir, side, -5, -5, 0), _at(e, dir, side, 6, 5, 0)):
		return {}
	var g := clampi(_h(memo, x, z), span.x, span.y)
	var c := Vector3i(x, g, z)
	var boxes: Array = []
	_pad(boxes, _at(c, dir, side, -4, -4, 0), _at(c, dir, side, 6, 4, 0), span.x, g, 10)
	_box(boxes, _at(c, dir, side, -3, -3, span.x - g - 1), _at(c, dir, side, 4, 3, -1), _p("stone"))  # foundation
	_box(boxes, _at(c, dir, side, -3, -3, 0), _at(c, dir, side, 3, 3, 4), _p("wood"))                # the walls
	_box(boxes, _at(c, dir, side, -2, -2, -1), _at(c, dir, side, 2, 2, -1), _p("wood"))              # the floor
	_box(boxes, _at(c, dir, side, -2, -2, 0), _at(c, dir, side, 2, 2, 3), BlockIds.AIR)
	for s: int in [-3, 3]:
		for t: int in [-3, 3]:
			_box(boxes, _at(c, dir, side, s, t, 0), _at(c, dir, side, s, t, 4), _p("roof"))          # corners
	for k in 4:                                                                                    # the roof
		_box(boxes, _at(c, dir, side, -4, -3 + k, 5 + k), _at(c, dir, side, 4, 3 - k, 5 + k), _p("roof"))
	_box(boxes, _at(c, dir, side, 3, 0, 0), _at(c, dir, side, 3, 0, 1), BlockIds.AIR)               # the door
	_box(boxes, _at(c, dir, side, 4, -1, -1), _at(c, dir, side, 4, 1, -1), _p("wood"))              # its step
	for w: Vector2i in [Vector2i(3, -2), Vector2i(3, 2), Vector2i(-3, 0), Vector2i(0, 3)]:
		var cell := _at(c, dir, side, w.x, w.y, 2)
		_box(boxes, cell, cell, BlockIds.GLASS)
	var broken := _at(c, dir, side, 0, -3, 2)
	_box(boxes, broken, broken, BlockIds.AIR)                                                     # a broken window
	_box(boxes, _at(c, dir, side, -2, -2, 0), _at(c, dir, side, -2, -2, 0), BlockIds.CLOSET)
	_box(boxes, _at(c, dir, side, -2, 2, 0), _at(c, dir, side, -2, 2, 0), BlockIds.BARREL)
	var lamp := _at(c, dir, side, 0, 0, 4)
	_box(boxes, lamp, lamp, _p("lamp"))
	var ghosts: Array[Vector3] = []
	for gpos: Vector3i in [_at(c, dir, side, 0, -1, 1), _at(c, dir, side, -1, 1, 1)]:
		ghosts.append(Vector3(gpos) + Vector3(0.5, 0.2, 0.5))
	return {"anchor": _at(c, dir, side, 0, 0, 0), "chest": _at(c, dir, side, -2, 0, 0), "chest_kind": &"haunted",
		"locked": true, "yaw": _yaw(dir), "boxes": boxes, "dir": dir, "ghosts": ghosts,
		"riddle": (v >> 9) % TreasureRules.GHOST_RIDDLES.size(), "door": _at(c, dir, side, 3, 0, 0),
		"visit": _at(c, dir, side, 6, 0, 0),
		"inside": _inside(_at(c, dir, side, -2, -2, 0), _at(c, dir, side, 2, 2, 3))}


## A campsite: a striped tent open to the front with a supply chest inside, a campfire ringed with stones
## and two log seats, and a woodpile.
func _camp(memo: Dictionary, x: int, z: int, v: int) -> Dictionary:
	var dir := SecretRules.DIRS[v % 4]
	var side := _side(dir)
	var e := Vector3i(x, 0, z)
	var span := _flat(memo, _at(e, dir, side, -4, -4, 0), _at(e, dir, side, 5, 4, 0), 3)
	if span.x > span.y or not _no_igloo(_at(e, dir, side, -4, -4, 0), _at(e, dir, side, 5, 4, 0)):
		return {}
	var g := clampi(_h(memo, x, z), span.x, span.y)
	var c := Vector3i(x, g, z)
	var boxes: Array = []
	_pad(boxes, _at(c, dir, side, -4, -4, 0), _at(c, dir, side, 5, 4, 0), span.x, g, 6)
	for k in 4:                                                                                    # the tent
		var along := -3 + k
		var cloth := _p("cloth") if k % 2 == 0 else _p("cloth2")
		for s: int in [-2, 2]:
			_box(boxes, _at(c, dir, side, along, s, 0), _at(c, dir, side, along, s, 0), cloth)
		for s: int in [-1, 1]:
			_box(boxes, _at(c, dir, side, along, s, 1), _at(c, dir, side, along, s, 1), cloth)
		_box(boxes, _at(c, dir, side, along, 0, 2), _at(c, dir, side, along, 0, 2), cloth)
	_box(boxes, _at(c, dir, side, -3, -1, 0), _at(c, dir, side, -3, 1, 0), _p("cloth"))              # its back
	_box(boxes, _at(c, dir, side, -3, 0, 1), _at(c, dir, side, -3, 0, 1), _p("cloth"))
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:          # the fire
		var stone := _at(c, dir, side, 3 + d.x, d.y, 0)
		_box(boxes, stone, stone, _p("stone"))
	var fire := _at(c, dir, side, 3, 0, 0)
	_box(boxes, fire - Vector3i(0, 1, 0), fire - Vector3i(0, 1, 0), _p("log"))
	_box(boxes, fire, fire, _p("lamp"))
	for s: int in [-3, 3]:
		var seat := _at(c, dir, side, 3, s, 0)
		_box(boxes, seat, seat, _p("log"))
	_box(boxes, _at(c, dir, side, -2, 3, 0), _at(c, dir, side, -1, 3, 0), _p("log"))                # a woodpile
	return {"anchor": fire, "chest": _at(c, dir, side, -2, 0, 0), "chest_kind": &"camp", "yaw": _yaw(dir),
		"boxes": boxes, "dir": dir, "door": _at(c, dir, side, 0, 0, 0), "visit": _at(c, dir, side, 5, 0, 0),
		"inside": _inside(_at(c, dir, side, -3, -3, 0), _at(c, dir, side, 4, 3, 2))}
