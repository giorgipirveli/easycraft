class_name AcademyPlaza
extends RefCounted
## Owner #132 (W1), stage 3: the Discovery Academy's plaza by a home world's spawn: a tall tower in the middle (Professor
## Hoot on its top) and twelve doors round it on a ring, one per subject family and Life's, facing out, Maths' towards
## the spawn. It is found by Life Town's own search (LifeTown.pick with this LAYOUT: the same rings round the spawn, dry
## near-level ground, trees cleared once by the host, never on the Theater or the Launch Site nor hidden behind them),
## after Life Town and the Market Square and off both their plazas and beside them (`avoid`), so they keep every meadow
## they had. A world with no room gets it as a small island floating ISLAND_UP over the spawn (`island`). Nothing stamped:
## models (AcademyBuildings). Local cells: +Z towards the spawn, turned by `facing` (LaunchSite's frame).
##
## Each door: its subject (a School subject id, or "life"), its name (spoken as the child walks up; never shown: owner
## #133), its picture (AcademyIcons), its colour (the School's), its walk-up spot (`door`), its footprint and its angle
## on the ring. What a door opens (`opens`): Maths its real play (a crystal at the door, #134), Life Life, every other a
## calm "coming soon" until its games come (the lead's switch).

const PLAZA_MIN := Vector2i(-10, -10)
const PLAZA_MAX := Vector2i(10, 10)
## The ring: the gates' middles this far from the tower's middle, their walk-up spots a little further out.
const RING := 7.4
const DOOR_RING := 8.6
const TOWER_HALF := 3
## A world without room: the Academy floats this many blocks over the spawn's ground.
const ISLAND_UP := 16
## The search starts round the rings from another angle than Life Town's (the same rings, its own start).
const SEED_SHIFT := 7919

const PLAY := &"play"
const LIFE := &"life"
const SOON := &"soon"

## The doors in ring order from the front (Maths, towards the spawn), with their angle on the ring (degrees: 90 is +Z).
const _RING := [
	["maths", 90.0, "The Maths Workshop", "gear"], ["science", 120.0, "The Science Lab", "flask"],
	["english", 60.0, "The Word Tower", "book"], ["life", 150.0, "Life", "heart"],
	["computing", 30.0, "The Code Lab", "code"], ["history", 180.0, "The History Museum", "columns"],
	["geography", 0.0, "The Map Room", "pin"], ["health_pe", 210.0, "The Health Gym", "dumbbell"],
	["music", 330.0, "The Music Hall", "note"], ["citizenship", 240.0, "The Citizens' Hall", "people"],
	["art", 300.0, "The Art Studio", "palette"], ["design_tech", 270.0, "The Makers' Shed", "hammer"],
]

static var DOORS: Array[String] = _door_ids()
static var SPOTS: Dictionary = _spots(true)
## The search's layout (the doors and the tower's footprint) and the walk-up's (the doors only).
static var LAYOUT: Dictionary = {"min": PLAZA_MIN, "max": PLAZA_MAX, "spots": SPOTS}
static var DOOR_LAYOUT: Dictionary = {"min": PLAZA_MIN, "max": PLAZA_MAX, "spots": _spots(false)}


static func _door_ids() -> Array[String]:
	var out: Array[String] = []
	for e: Array in _RING:
		out.append(str(e[0]))
	return out


static func _spots(with_tower: bool) -> Dictionary:
	var out := {}
	for e: Array in _RING:
		var a := deg_to_rad(float(e[1]))
		var dir := Vector2(cos(a), sin(a))
		var mid := dir * RING
		var c := Vector2i(mid.round())
		out[str(e[0])] = {"subject": str(e[0]), "name": str(e[2]), "picture": str(e[3]), "angle": float(e[1]),
			"door": dir * DOOR_RING, "min": c - Vector2i(1, 1), "max": c + Vector2i(1, 1), "experience": ""}
	if with_tower:
		out["tower"] = {"subject": "", "name": "", "picture": "", "angle": 0.0, "door": Vector2.ZERO, "experience": "",
			"min": Vector2i(-TOWER_HALF, -TOWER_HALF), "max": Vector2i(TOWER_HALF, TOWER_HALF)}
	return out


## Owner #132 (W1) → deep games: THE LEAD'S SWITCH for what a door opens: PLAY (a whole round in Play G0's place of the
## subject's unit that plays without reading: DiscoveryPlays.subject_unit; a deep game registered with G0 plays there
## too; none yet: a calm "coming soon", a picture and a spoken line), LIFE (Life), SOON (always "coming soon"). A deep
## game with a scene of its own (the Science Lab's Leaf Voyage) gets its door here.
static func opens(door: String) -> StringName:
	if door == "life":
		return LIFE
	return PLAY if SPOTS.has(door) else SOON


## The Academy's site round `spawn` (`world_seed`), after the town's and the Market Square's ({} when none), on the
## Theater's and the Launch Site's terms; else the island over the spawn.
static func pick(spawn: Vector2i, world_seed: int, height_at: Callable, is_dry: Callable, has_tree: Callable,
		theater: Dictionary = {}, launch: Dictionary = {}, town: Dictionary = {}, market: Dictionary = {},
		rejected: Array = []) -> Dictionary:
	var site := LifeTown.pick(spawn, world_seed + SEED_SHIFT, height_at, is_dry, has_tree, theater, launch, rejected,
		LAYOUT, {}, _avoid(town, market))
	if not site.is_empty():
		return site
	return island(spawn, int(height_at.call(spawn.x, spawn.y)))


## pick() with a home world's terrain (its first spawn).
static func pick_for(shape: MeadowsShape, theater: Dictionary = {}, launch: Dictionary = {}, town: Dictionary = {},
		market: Dictionary = {}, rejected: Array = []) -> Dictionary:
	var site := LifeTown.pick_for(shape, theater, launch, rejected, LAYOUT, {}, _avoid(town, market),
		shape.seed + SEED_SHIFT)
	if not site.is_empty():
		return site
	var sp := shape.spawn_column()
	return island(sp, shape.height_at(sp.x, sp.y))


## The small island over the spawn (a world with no room on the ground).
static func island(spawn: Vector2i, ground_y: int) -> Dictionary:
	return {"pos": Vector3i(spawn.x, ground_y + ISLAND_UP, spawn.y), "facing": 0, "island": true}


static func _avoid(town: Dictionary, market: Dictionary) -> Array:
	var out: Array = []
	if not town.is_empty():
		out.append([{"pos": town.pos, "facing": town.facing}, {}])
	if not market.is_empty():
		out.append([market, MarketPlaza.LAYOUT])
	return out


static func door_position(site: Dictionary, door: String, ground: Callable = Callable()) -> Vector3:
	return LifeTown.door_position(site, door, ground, DOOR_LAYOUT)


## The door whose spot feet at `feet` stand at ("" for none; the tower's middle is no door).
static func near(site: Dictionary, feet: Vector3, ground: Callable = Callable()) -> String:
	if site.is_empty() or bool(site.get("island", false)):
		return ""
	return LifeTown.near(site, feet, ground, DOOR_LAYOUT)


static func natural_box(site: Dictionary) -> Array:
	return LifeTown.natural_box(site, LAYOUT)


static func natural(site: Dictionary, read: Callable) -> bool:
	return LifeTown.natural(site, read, LAYOUT)


static func clear_changes(site: Dictionary, read: Callable) -> Array:
	return LifeTown.clear_changes(site, read, LAYOUT)


static func to_world(site: Dictionary, local: Vector2i) -> Vector2i:
	return LifeTown.to_world(site, local)


## [x, y, z, facing] (and a 1 for the island), or [] for none: WorldMeta.academy.
static func to_save(site: Dictionary) -> Array:
	if site.is_empty():
		return []
	var p: Vector3i = site.pos
	var out := [p.x, p.y, p.z, int(site.facing)]
	if bool(site.get("island", false)):
		out.append(1)
	return out


static func from_save(v: Variant) -> Dictionary:
	if v is Array and (v as Array).size() == 5 and typeof(v[4]) in [TYPE_INT, TYPE_FLOAT] and int(v[4]) == 1:
		var s := TheaterSite.from_save((v as Array).slice(0, 4))
		if not s.is_empty():
			s.island = true
		return s
	return TheaterSite.from_save(v)
