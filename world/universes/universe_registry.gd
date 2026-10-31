class_name UniverseRegistry
extends RefCounted
## The universe ladder (M3 Task 5, spec §14.1): which universes exist and what each one brings.
## Universe 1 is Green Meadows (world/universes/meadows.gd, today's world). Universes 2–5 are
## descriptors in their own files, world/universes/<name>.gd, written by the tasks that build them; a
## universe whose file doesn't exist yet is "coming soon" (the hub shows it, nobody can travel there).
##
## A descriptor is a script (extends RefCounted), instanced once, read through this interface:
## - `var name: StringName` (the ladder's name, e.g. &"desert"), `var display_name: String`, `var index: int`
## - `func generator_shape(world_seed: int) -> MeadowsShape`: the terrain's pure rules, a MeadowsShape or
##   a subclass (every system types it MeadowsShape: height_at, is_river, tree_at, spawn_column, …)
## - `func generator(world_seed: int) -> VoxelGenerator` (optional; Green Meadows' generator without it)
## - optional (owner #45b): `func terrain_shape(world_seed, terrain) -> MeadowsShape` and `func terrain_generator(
##   world_seed, terrain) -> VoxelGenerator` for a world's newer terrain version (WorldMeta.terrain > 1)
## - `var monster_kinds: Array[StringName]`, `var boss_kind: StringName`
## - `var music: Dictionary` {&"day"/"day", "night", "boss": "res://….ogg"} (missing tracks: Meadows')
## - `var sky: Dictionary` {"sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog": Color}
##   (the daytime colours; the night stays the night's)
## - `var trader_stock: Dictionary` {block or item id: price in Green Meadows gold} (Tilly's local things;
##   prices scale with the universe)
## - optional (the audio pass): `var ambience: Dictionary` {"day"/"night": an AmbienceSoundRules loop} and
##   `var classical: Array` (MusicPieces ids the universe plays first)
## Missing or broken fields read as safe defaults, so a half-written descriptor never breaks a world.

const DIR := "res://world/universes/"
## The ladder, in order. The colours paint each universe's hub card before (and after) its file exists.
const LADDER: Array[Dictionary] = [
	{"name": &"meadows", "display_name": "Green Meadows",
		"top": Color("5aa9f0"), "bottom": Color("bfe3ff"), "ground": Color("5cb85c")},
	{"name": &"desert", "display_name": "Sandstorm Desert",
		"top": Color("f59e5b"), "bottom": Color("ffe0a3"), "ground": Color("e8c170")},
	{"name": &"frost", "display_name": "Frostpeak",
		"top": Color("7fb4e6"), "bottom": Color("e8f4ff"), "ground": Color("f4f8fb")},
	{"name": &"candy", "display_name": "Candy Kingdom",
		"top": Color("ff8fc8"), "bottom": Color("ffe1f0"), "ground": Color("a0522d")},
	{"name": &"dragon", "display_name": "Dragon Realm",   # owner 39; #43 and M5 Task 2: islands at sunrise over clouds
		"top": Color("75a8f2"), "bottom": Color("ffd69e"), "ground": Color("f7e8e2")},
	{"name": &"glow", "display_name": "Glow Caves",   # universe 6: caverns lit by their own glow
		"top": Color("2f2a6b"), "bottom": Color("6a5fc4"), "ground": Color("3fd9b8")},
]
## Owner #55 (spec §21): the space worlds, off the ladder (numbers SpaceRules.WORLDS), reached by flying up. Their
## descriptors follow the same interface, plus the optional `gravity` (×, the Moon 0.35), `peaceful` (no monsters come
## by themselves), `space_sky` (0..1: how much the day sky is space's), `sky_planet` ({color, land, ring, size}: a
## planet hanging in the sky; `lumpy`, `own_moons` and `moons` [{color, land, size, dir, lumpy}] for a world's own small
## moons, cosmos; `bands` and `spot` draw a gas giant's cloud bands and its great storm: Jupiter over Europa and Io)
## and `landing_words` (said on landing); cosmos (spec §21b.2): `lifeless` (no animals: Mars, Europa, Io, Titan, Mercury) and
## `sights` ({id: {name, words}}: the places a child learns a real fact at, SpaceSights); Titan's `liquid` (&"methane",
## TitanRules); Mercury's `sun_size` (how big the Sun looks, × home's: SkyCycle.sun_size); Venus's `sun_rises_west`
## (it spins backwards: SkyCycle.sun_west) and its void (`has_void`, `void_y`, `void_words`: DragonRules); Saturn's
## rings: a sky planet's `dir` (where it hangs), `ring_edge` (rings seen edge-on) and `pixels` (its picture's size);
## Pluto: a sky planet's `cap` (a coloured polar cap: Charon's red one); Triton: a sky planet's `spot_color` (Neptune's
## dark spot, where Jupiter's is red); Ganymede: its sky planet's `moons` swing past it (GanymedeSky: Io and Europa).
const SPACE := {
	16: {"name": &"moon", "display_name": "The Moon",
		"top": Color("0b0d24"), "bottom": Color("26306a"), "ground": Color("c9ccd6")},
	17: {"name": &"boing", "display_name": "Planet Boing",
		"top": Color("7a4fd6"), "bottom": Color("e5b8ff"), "ground": Color("9be34a")},
	18: {"name": &"rainbow", "display_name": "Rainbow Planet",
		"top": Color("b9a4f5"), "bottom": Color("ffe1f4"), "ground": Color("f7a6c8")},
	19: {"name": &"mars", "display_name": "Mars",   # cosmos (spec §21b.2): the first real planet
		"top": Color("cc8f6b"), "bottom": Color("edc29a"), "ground": Color("c1440e")},
	20: {"name": &"europa", "display_name": "Europa",   # cosmos (spec §21b.2): Jupiter's icy moon
		"top": Color("0b0d24"), "bottom": Color("1f2c5a"), "ground": Color("eae3d2")},
	21: {"name": &"io", "display_name": "Io",   # cosmos (spec §21b.2): Jupiter's volcanic moon
		"top": Color("120a14"), "bottom": Color("4a2a16"), "ground": Color("e8d04a")},
	22: {"name": &"titan", "display_name": "Titan",   # cosmos (spec §21b.2): Saturn's hazy moon
		"top": Color("d98c42"), "bottom": Color("f6c98a"), "ground": Color("c07a3c")},
	23: {"name": &"mercury", "display_name": "Mercury",   # cosmos (spec §21b.2): the planet closest to the Sun
		"top": Color("06060a"), "bottom": Color("2b2b33"), "ground": Color("a7a39d")},
	24: {"name": &"venus", "display_name": "Venus",   # cosmos (spec §21b.2): its cloud city over the yellow clouds
		"top": Color("ebc773"), "bottom": Color("ffebb3"), "ground": Color("f4efe3")},
	25: {"name": &"rings", "display_name": "Saturn's Rings",   # cosmos (spec §21b.2): chunks of ice round Saturn
		"top": Color("05060d"), "bottom": Color("2a2438"), "ground": Color("e6eff8")},
	26: {"name": &"pluto", "display_name": "Pluto",   # cosmos (spec §21b.2): the dwarf planet with a heart of ice
		"top": Color("05070f"), "bottom": Color("26365e"), "ground": Color("f3ece0")},
	27: {"name": &"triton", "display_name": "Triton",   # cosmos (spec §21b.2): Neptune's big moon, pink ice and geysers
		"top": Color("04060f"), "bottom": Color("1d2a5a"), "ground": Color("f0c9c6")},
	28: {"name": &"ganymede", "display_name": "Ganymede",   # cosmos (spec §21b.2): the biggest moon, with auroras
		"top": Color("060a16"), "bottom": Color("1f2c5a"), "ground": Color("cfd2d8")},
}
## Owner #78 (spec §24): Earth's own worlds (numbers EarthRules 41-60), off the ladder like space's and reached from the
## Star Map's Earth card: 41, Wonders of the World (world/universes/wonders.gd). Their descriptors follow the same
## interface; Earth's gravity, sky and animals are the defaults.
const EARTH := {
	41: {"name": &"wonders", "display_name": "Wonders of the World",
		"top": Color("5aa9f0"), "bottom": Color("cfe8ff"), "ground": Color("e2c98f")},
}
const MIN_GRAVITY := 0.05             # cosmos: Saturn's rings' (spec §21b.2)
const MAX_GRAVITY := 2.0
const MIN_SUN := 0.025                 # cosmos: a world's `sun_size` (the Sun far away: Pluto's ... close by)
const MAX_SUN := 4.0

static var _cache := {}       # universe -> descriptor (or null: no file)
static var _overrides := {}   # tests: universe -> descriptor (or null: pretend the file is missing)
static var _warming := {}     # M7: universe -> asked for in the background (warm_space), not taken yet


static func size() -> int:
	return LADDER.size()


static func ladder_name(u: int) -> StringName:
	return LADDER[u - 1].name if u >= 1 and u <= size() else &""


## Where universe u's descriptor lives: world/universes/<name>.gd (a space world's too, owner #55).
static func path_for(u: int) -> String:
	var n := ladder_name(u)
	if n == &"":
		n = space_name(u)
	if n == &"" and EARTH.has(u):
		n = EARTH[u].name   # owner #78: Earth's own worlds
	return DIR + String(n) + ".gd" if n != &"" else ""


## Universe u's descriptor, or null when its file doesn't exist (yet).
static func descriptor(u: int) -> Object:
	if _overrides.has(u):
		return _overrides[u]
	if not _cache.has(u):
		_cache[u] = _load(u)
	return _cache[u]


static func _load(u: int) -> Object:
	var path := path_for(u)
	if path == "" or not ResourceLoader.exists(path):
		return null
	var script: GDScript = null
	if _warming.has(u):   # M7: asked for in the background (warm_space); waits here only if it is not done yet
		script = ResourceLoader.load_threaded_get(path) as GDScript
		_warming.erase(u)
	if script == null:
		script = load(path) as GDScript
	if script == null or not script.can_instantiate():
		return null
	return script.new()


static func exists(u: int) -> bool:
	return descriptor(u) != null


## The universes whose descriptor files exist, in ladder order (Green Meadows always).
static func available() -> Array[int]:
	var out: Array[int] = []
	for u in range(1, size() + 1):
		if exists(u):
			out.append(u)
	return out


## The universe after `u` among those that exist, round the ladder (the developer menu's WORLD).
static func next_available(u: int) -> int:
	var avail := available()
	var i := avail.find(u)
	return avail[0] if i < 0 else avail[(i + 1) % avail.size()]


## The worlds the developer menu's autopilot can go to (WORLD): the ladder's universes, then the space worlds, then
## Earth's own (owner #78).
static func autopilot_worlds() -> Array[int]:
	var out: Array[int] = available().duplicate()
	out.append_array(space_available())
	out.append_array(earth_available())
	return out


static func next_autopilot(u: int) -> int:
	var all := autopilot_worlds()
	var i := all.find(u)
	return all[0] if i < 0 else all[(i + 1) % all.size()]


static func display_name(u: int) -> String:
	var v: Variant = _field(u, "display_name")
	if v is String and v != "":
		return v
	if is_space(u):
		return SPACE[u].display_name
	if is_earth(u):
		return EARTH[u].display_name
	return LADDER[u - 1].display_name if u >= 1 and u <= size() else Lang.t("Universe %d") % u


static func monster_kinds(u: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var v: Variant = _field(u, "monster_kinds")
	if v is Array:
		for k: Variant in v:
			if k is StringName or k is String:
				out.append(StringName(k))
	return out


static func boss_kind(u: int) -> StringName:
	var v: Variant = _field(u, "boss_kind")
	return StringName(v) if v is StringName or v is String else &""


## {track: path}; tracks MusicRules.DAY / NIGHT / BOSS. {} = Green Meadows' music.
static func music(u: int) -> Dictionary:
	var out := {}
	var v: Variant = _field(u, "music")
	if v is Dictionary:
		for track: Variant in v:
			if (track is String or track is StringName) and v[track] is String:
				out[String(track)] = v[track]
	return out


## The universe's daytime sky colours {"sky_top", "sky_horizon", "ground_bottom", "ground_horizon", "fog"}.
static func sky(u: int) -> Dictionary:
	var out := {}
	var v: Variant = _field(u, "sky")
	if v is Dictionary:
		for key: Variant in v:
			if v[key] is Color:
				out[String(key)] = v[key]
	return out


## The audio pass: the universe's own ambience loops {"day": id, "night": id} (AmbienceSoundRules.LOOPS
## ids; optional descriptor field `ambience`). {} = birds by day, crickets at night.
static func ambience(u: int) -> Dictionary:
	var out := {}
	var v: Variant = _field(u, "ambience")
	if v is Dictionary:
		for key: Variant in v:
			if String(key) in ["day", "night"] and AmbienceSoundRules.LOOPS.has(StringName(str(v[key]))):
				out[String(key)] = StringName(str(v[key]))
	return out


## The audio pass: the universe's own classical pieces (MusicPieces ids; optional descriptor field
## `classical`), played first among equals (MusicPlan.favourites). The Candy Kingdom's: the Nutcracker.
static func classical(u: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var v: Variant = _field(u, "classical")
	if v is Array:
		for id: Variant in v:
			if (id is String or id is StringName) and MusicPieces.has(StringName(id)):
				out.append(StringName(id))
	return out


## Owner #41: the animals universe u grows (optional descriptor field `animals`, AnimalRules species; unknown
## names dropped). A universe that names none keeps Green Meadows' (AnimalRules.MEADOWS_KINDS); a lifeless one has
## none (cosmos: Mars).
static func animals(u: int) -> Array[StringName]:
	var out: Array[StringName] = []
	if lifeless(u):
		return out
	var v: Variant = _field(u, "animals")
	if v is Array:
		for sp: Variant in v:
			if (sp is StringName or sp is String) and AnimalRules.SPECIES.has(StringName(sp)):
				out.append(StringName(sp))
	if out.is_empty():
		out.assign(AnimalRules.MEADOWS_KINDS)
	return out


## Tilly's local things {id: price in Green Meadows gold}.
static func trader_stock(u: int) -> Dictionary:
	var out := {}
	var v: Variant = _field(u, "trader_stock")
	if v is Dictionary:
		for id: Variant in v:
			if typeof(id) == TYPE_INT and typeof(v[id]) in [TYPE_INT, TYPE_FLOAT] and int(v[id]) > 0:
				out[id] = int(v[id])
	return out


## The terrain rules of universe u for a world seed (Green Meadows' when u has no descriptor or no shape).
## terrain (owner #45b): the world's terrain version (WorldMeta.terrain); a descriptor with `terrain_shape(seed,
## terrain)` makes the newer ones (Green Meadows' wild meadows), the others ignore it.
static func shape_for(u: int, world_seed: int, terrain: int = 1) -> MeadowsShape:
	var d := descriptor(u)
	if terrain > 1 and d != null and d.has_method(&"terrain_shape"):
		var t: Variant = d.call(&"terrain_shape", world_seed, terrain)
		if t is MeadowsShape:
			return t
	if d != null and d.has_method(&"generator_shape"):
		var s: Variant = d.call(&"generator_shape", world_seed)
		if s is MeadowsShape:
			return s
	return MeadowsShape.new(world_seed)


## The voxel generator of universe u (Green Meadows' when u has none); terrain as for shape_for (a descriptor's
## `terrain_generator(seed, terrain)`).
static func generator_for(u: int, world_seed: int, terrain: int = 1) -> VoxelGenerator:
	var d := descriptor(u)
	if terrain > 1 and d != null and d.has_method(&"terrain_generator"):
		var t: Variant = d.call(&"terrain_generator", world_seed, terrain)
		if t is VoxelGenerator:
			return t
	if d != null and d.has_method(&"generator"):
		var g: Variant = d.call(&"generator", world_seed)
		if g is VoxelGenerator:
			return g
	var meadows := MeadowsGenerator.new()
	meadows.world_seed = world_seed
	return meadows


## The portal hub's list for a profile that unlocked `unlocked` universes (UniverseRules.hub_entries).
static func hub_entries(unlocked: int) -> Array[Dictionary]:
	return UniverseRules.hub_entries(unlocked, size(), available())


## The colours of universe u's hub card: {top, bottom (sky), ground}. A descriptor's sky wins.
static func card_colors(u: int) -> Dictionary:
	var base: Dictionary = SPACE[u] if is_space(u) else (EARTH[u] if is_earth(u) else LADDER[clampi(u, 1, size()) - 1])
	var s := sky(u)
	return {"top": s.get("sky_top", base.top), "bottom": s.get("sky_horizon", base.bottom), "ground": base.ground}


# --- Owner #55: the space worlds (spec §21) ---

## A space world of the SPACE table (16-18).
static func is_space(u: int) -> bool:
	return SPACE.has(u)


static func space_name(u: int) -> StringName:
	return SPACE[u].name if SPACE.has(u) else &""


## M7 (the browser's freezes): the picker's cards read the space worlds' descriptors, and loading their files (scripts
## with their generators and shapes, ~90 ms here, several times that on a phone) froze the game the first time it
## opened. The climb asks for them in the background (ResourceLoader's threads) instead; descriptor() takes them from
## there. Only the files not here or asked for yet; returns the worlds asked for.
static func warm_space() -> Array[int]:
	var out: Array[int] = []
	for u: int in SpaceRules.WORLDS + EarthRules.WORLDS:   # owner #78: the Star Map's Earth card lands too
		if _overrides.has(u) or _cache.has(u) or _warming.has(u):
			continue
		var path := path_for(u)
		if path != "" and ResourceLoader.exists(path) and ResourceLoader.load_threaded_request(path) == OK:
			_warming[u] = true
			out.append(u)
	return out


## The space worlds whose descriptor files exist, in order.
static func space_available() -> Array[int]:
	var out: Array[int] = []
	for u: int in SpaceRules.WORLDS:
		if is_space(u) and exists(u):
			out.append(u)
	return out


# --- Owner #78: Earth's own worlds (spec §24) ---

## One of the EARTH table's worlds (41: Wonders of the World).
static func is_earth(u: int) -> bool:
	return EARTH.has(u)


## Earth's worlds whose descriptor files exist, in order.
static func earth_available() -> Array[int]:
	var out: Array[int] = []
	for u: int in EarthRules.WORLDS:
		if is_earth(u) and exists(u):
			out.append(u)
	return out


## Every world a trip lands on from the Star Map whose file exists: the space worlds, then Earth's (owner #78).
static func trip_available() -> Array[int]:
	var out := space_available()
	out.append_array(earth_available())
	return out


## Gravity × this in world u (the descriptor's `gravity`; 1 without one), never below MIN_GRAVITY or above MAX_GRAVITY.
static func gravity(u: int) -> float:
	var v: Variant = _field(u, "gravity")
	if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)):
		return 1.0
	return clampf(float(v), MIN_GRAVITY, MAX_GRAVITY)


## No monsters come by themselves in world u (the descriptor's `peaceful`).
static func peaceful(u: int) -> bool:
	return _field(u, "peaceful") == true


## How much world u's daytime sky is space's (0..1; the descriptor's `space_sky`).
## Cosmos (spec §21b.2): whether the realistic style shows the photo sky (Earth's blue and clouds) in world u; a
## descriptor with `photo_sky = false` (Mars) keeps its own painted sky.
static func photo_sky(u: int) -> bool:
	var v: Variant = _field(u, "photo_sky")
	return v if v is bool else true


static func space_sky(u: int) -> float:
	var v: Variant = _field(u, "space_sky")
	return clampf(float(v), 0.0, 1.0) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) else 0.0


## The planet hanging in world u's sky ({color, land, ring, size}; {} for none).
static func sky_planet(u: int) -> Dictionary:
	var v: Variant = _field(u, "sky_planet")
	return v if v is Dictionary and (v as Dictionary).get("color") is Color else {}


## Cosmos (spec §21b.2): how big the Sun looks in world u's sky, × home's (the descriptor's `sun_size`: Mercury's 3;
## 1 without one), between MIN_SUN and MAX_SUN.
static func sun_size(u: int) -> float:
	var v: Variant = _field(u, "sun_size")
	if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)):
		return 1.0
	return clampf(float(v), MIN_SUN, MAX_SUN)


## The visuals brief (docs/devlog/parts/visuals.md): how bright world u's noon sunlight is, × home's (the descriptor's
## `sun_light`, 0.3-1.5; 1 without one): Mars's under half of Earth's sunlight, Venus's glaring cloud deck. The day's
## light only (SkyCycle.sun_light), never the moon's.
static func sun_light(u: int) -> float:
	var v: Variant = _field(u, "sun_light")
	if typeof(v) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)):
		return 1.0
	return clampf(float(v), 0.3, 1.5)


## Cosmos (spec §21b.2): the Sun rises in the west in world u (the descriptor's `sun_rises_west`: Venus spins backwards).
static func sun_rises_west(u: int) -> bool:
	return _field(u, "sun_rises_west") == true


## Cosmos (spec §21b.2): no animals live in world u (the descriptor's `lifeless`: Mars has no life we know of).
static func lifeless(u: int) -> bool:
	return _field(u, "lifeless") == true


## Cosmos: world u's sights {id: {"name", "words"}} (the descriptor's `sights`; entries without both dropped; {} for
## none). Where each sight is, is its shape's (SpaceShape.sight_at, sights).
static func sights(u: int) -> Dictionary:
	var out := {}
	var v: Variant = _field(u, "sights")
	if v is Dictionary:
		for id: Variant in v:
			var e: Variant = v[id]
			if (id is StringName or id is String) and e is Dictionary and (e as Dictionary).get("name") is String \
					and (e as Dictionary).get("words") is String:
				out[StringName(id)] = {"name": e.name, "words": e.words}
	return out


## What world u says on landing ("" for none).
static func landing_words(u: int) -> String:
	var v: Variant = _field(u, "landing_words")
	return v if v is String else ""


## Universe 6 (the Glow Caves): the mood under a ceiling of world u (GlowRules.mood's `cave`: the descriptor's `cave_mood`,
## a Dictionary with every key of GlowRules.CAVE_MOOD); {} for the meadows' caves (AmbienceRules alone).
## Universe 6 (brief, owner #72): a locked universe's free peek: a few short lines of what is inside (its descriptor's
## `peek`; [] for a universe without one, or not built).
static func peek(u: int) -> Array[String]:
	var out: Array[String] = []
	var v: Variant = _field(u, "peek")
	if v is Array:
		for l: Variant in v:
			if l is String and l != "" and out.size() < 3:
				out.append(l)
	return out


static func cave_mood(u: int) -> Dictionary:
	var v: Variant = _field(u, "cave_mood")
	if not v is Dictionary:
		return {}
	for key: String in GlowRules.CAVE_MOOD:
		if not (v as Dictionary).has(key):
			return {}
	return v



## Tests: pretend universe u's descriptor is `d` (null: its file is missing).
static func use(u: int, d: Object) -> void:
	_overrides[u] = d


## Tests: back to the files on disk.
static func reset() -> void:
	for u: int in _warming:
		ResourceLoader.load_threaded_get(path_for(u))   # nothing is left loading
	_warming.clear()
	_overrides.clear()
	_cache.clear()


static func _field(u: int, key: String) -> Variant:
	var d := descriptor(u)
	return d.get(key) if d != null else null
