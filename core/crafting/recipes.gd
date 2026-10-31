class_name Recipes
extends RefCounted
## Every crafting recipe (owner feedback #34, spec §12.19), in one table: the picture recipe book shows
## them in this order. Each is {id, at (HAND anywhere, TABLE next to a Crafting Table, FURNACE next to a
## Furnace, burning one of FUELS, REFINERY next to a Refinery: spec §26; spec §26.5: MELTER next to an Ice Melter,
## OXYGEN_MAKER next to an Oxygen Maker, SOLAR_OVEN next to a Solar Oven), needs {id: count}, makes: id, count}. Ores are used directly (no ingots,
## ruling in docs/devlog/parts/survivor-games-crafting.md). problems() and has_loop() validate a table;
## the tests hold LIST to them. Never gold, never random.

const HAND := &"hand"
const TABLE := &"table"
const FURNACE := &"furnace"
const REFINERY := &"refinery"   # spec §26: crude oil is split into kerosene and plastic next to a Refinery
## Spec §26.5 (living off the land on the Moon and Mars): the colony's Ice Melter melts ice into water, its Oxygen Maker
## splits water (and rock) with electricity, a Solar Oven's mirrors bake and melt with sunlight. None burns a fuel.
const MELTER := &"melter"
const OXYGEN_MAKER := &"oxygen_maker"
const SOLAR_OVEN := &"solar_oven"
const STATIONS: Array[StringName] = [HAND, TABLE, FURNACE, REFINERY, MELTER, OXYGEN_MAKER, SOLAR_OVEN]
## The machines found in reach like the stations (Session.craft_stations_near looks for their blocks).
const MACHINES: Array[StringName] = [MELTER, OXYGEN_MAKER, SOLAR_OVEN]
## What a furnace burns, in the order it picks them (never the recipe's own result).
const FUELS: Array[int] = [BlockIds.COAL, BlockIds.LOG]

const LIST := [
	# By hand, anywhere.
	{"id": &"planks", "at": HAND, "needs": {BlockIds.LOG: 1}, "makes": BlockIds.PLANKS, "count": 4},
	{"id": &"sticks", "at": HAND, "needs": {BlockIds.PLANKS: 2}, "makes": ItemIds.STICK, "count": 4},
	{"id": &"crafting_table", "at": HAND, "needs": {BlockIds.PLANKS: 4}, "makes": BlockIds.CRAFTING_TABLE, "count": 1},
	# At the crafting table: a home.
	{"id": &"furnace", "at": TABLE, "needs": {BlockIds.STONE: 8}, "makes": BlockIds.FURNACE, "count": 1},
	{"id": &"doors", "at": TABLE, "needs": {BlockIds.PLANKS: 6}, "makes": BlockIds.DOOR, "count": 2},
	{"id": &"bed", "at": TABLE, "needs": {BlockIds.PLANKS: 5}, "makes": BlockIds.BED, "count": 1},
	{"id": &"lights", "at": TABLE, "needs": {BlockIds.COAL: 1, ItemIds.STICK: 1}, "makes": BlockIds.LIGHT, "count": 4},
	{"id": &"lantern", "at": TABLE, "needs": {BlockIds.COAL: 1, ItemIds.STICK: 1, BlockIds.GLASS: 1}, "makes": BlockIds.LANTERN, "count": 1},
	{"id": &"barrel", "at": TABLE, "needs": {BlockIds.PLANKS: 6, ItemIds.STICK: 2}, "makes": BlockIds.BARREL, "count": 1},
	{"id": &"closet", "at": TABLE, "needs": {BlockIds.PLANKS: 8}, "makes": BlockIds.CLOSET, "count": 1},
	{"id": &"spike_trap", "at": TABLE, "needs": {BlockIds.IRON: 1, BlockIds.STONE: 2, ItemIds.STICK: 2}, "makes": BlockIds.SPIKE_TRAP, "count": 1},
	{"id": &"shield_wood", "at": TABLE, "needs": {BlockIds.PLANKS: 6}, "makes": ItemIds.SHIELD_WOOD, "count": 1},
	# Spec §23: the Science Lab's bench (a white bench, a glass flask, an iron burner).
	{"id": &"lab_bench", "at": TABLE, "needs": {BlockIds.PLANKS: 3, BlockIds.GLASS: 1, BlockIds.IRON: 1}, "makes": BlockIds.LAB_BENCH, "count": 1},
	# Owner #110 (VR round 4): the music blocks: wooden bars on a frame (sticks for its mallets), a hollowed log's drums.
	{"id": &"xylophone", "at": TABLE, "needs": {BlockIds.PLANKS: 4, ItemIds.STICK: 2}, "makes": BlockIds.XYLOPHONE, "count": 1},
	{"id": &"bongo_drums", "at": TABLE, "needs": {BlockIds.LOG: 1, BlockIds.PLANKS: 2}, "makes": BlockIds.DRUM, "count": 1},
	# Spec §21d (missions): the simple rocket parts from real materials (metal; the heat shield's ceramic is baked from
	# sand). Engines, tanks, the capsule, the service module, the solar array and the parachute are bought with gold.
	{"id": &"nose_cone", "at": TABLE, "needs": {BlockIds.IRON: 2}, "makes": BlockIds.NOSE_CONE, "count": 1},
	{"id": &"rocket_fins", "at": TABLE, "needs": {BlockIds.IRON: 1}, "makes": BlockIds.ROCKET_FINS, "count": 2},
	{"id": &"landing_legs", "at": TABLE, "needs": {BlockIds.IRON: 3}, "makes": BlockIds.LANDING_LEGS, "count": 1},
	{"id": &"stage_separator", "at": TABLE, "needs": {BlockIds.IRON: 2}, "makes": BlockIds.STAGE_SEPARATOR, "count": 1},
	# At the crafting table: the tiers of §12.6 (wood, stone, iron, crystal from diamond, cosmic from gold and crystal).
	{"id": &"sword", "at": TABLE, "needs": {BlockIds.PLANKS: 2, ItemIds.STICK: 1}, "makes": ItemIds.SWORD, "count": 1},
	{"id": &"pickaxe", "at": TABLE, "needs": {BlockIds.PLANKS: 3, ItemIds.STICK: 2}, "makes": ItemIds.PICKAXE, "count": 1},
	{"id": &"axe", "at": TABLE, "needs": {BlockIds.PLANKS: 3, ItemIds.STICK: 2}, "makes": ItemIds.AXE, "count": 1},
	{"id": &"sword_stone", "at": TABLE, "needs": {BlockIds.STONE: 2, ItemIds.STICK: 1}, "makes": ItemIds.SWORD_STONE, "count": 1},
	{"id": &"pickaxe_stone", "at": TABLE, "needs": {BlockIds.STONE: 3, ItemIds.STICK: 2}, "makes": ItemIds.PICKAXE_STONE, "count": 1},
	{"id": &"axe_stone", "at": TABLE, "needs": {BlockIds.STONE: 3, ItemIds.STICK: 2}, "makes": ItemIds.AXE_STONE, "count": 1},
	{"id": &"sword_iron", "at": TABLE, "needs": {BlockIds.IRON: 2, ItemIds.STICK: 1}, "makes": ItemIds.SWORD_IRON, "count": 1},
	{"id": &"pickaxe_iron", "at": TABLE, "needs": {BlockIds.IRON: 3, ItemIds.STICK: 2}, "makes": ItemIds.PICKAXE_IRON, "count": 1},
	{"id": &"axe_iron", "at": TABLE, "needs": {BlockIds.IRON: 3, ItemIds.STICK: 2}, "makes": ItemIds.AXE_IRON, "count": 1},
	{"id": &"sword_crystal", "at": TABLE, "needs": {BlockIds.DIAMOND: 2, ItemIds.STICK: 1}, "makes": ItemIds.SWORD_CRYSTAL, "count": 1},
	{"id": &"pickaxe_crystal", "at": TABLE, "needs": {BlockIds.DIAMOND: 3, ItemIds.STICK: 2}, "makes": ItemIds.PICKAXE_CRYSTAL, "count": 1},
	{"id": &"sword_cosmic", "at": TABLE, "needs": {BlockIds.GOLD: 2, BlockIds.CRYSTAL: 2, ItemIds.STICK: 1}, "makes": ItemIds.SWORD_COSMIC, "count": 1},
	{"id": &"pickaxe_cosmic", "at": TABLE, "needs": {BlockIds.GOLD: 3, BlockIds.CRYSTAL: 3, ItemIds.STICK: 2}, "makes": ItemIds.PICKAXE_COSMIC, "count": 1},
	# At the furnace (each also burns one fuel).
	{"id": &"glass", "at": FURNACE, "needs": {BlockIds.SAND: 4}, "makes": BlockIds.GLASS, "count": 4},
	{"id": &"bricks", "at": FURNACE, "needs": {BlockIds.STONE: 4}, "makes": BlockIds.BRICK, "count": 4},
	{"id": &"charcoal", "at": FURNACE, "needs": {BlockIds.LOG: 3}, "makes": BlockIds.COAL, "count": 1},
	{"id": &"heat_shield", "at": FURNACE, "needs": {BlockIds.SAND: 3, BlockIds.STONE: 1}, "makes": BlockIds.HEAT_SHIELD, "count": 1},   # §21d
	# Spec §26 (prospecting): refining what the deposits give, each step with a real fact (RefiningRules.FACTS).
	{"id": &"pan_gold", "at": HAND, "needs": {BlockIds.GOLD_GRAVEL: 4}, "makes": BlockIds.GOLD, "count": 1},
	{"id": &"crust_salt", "at": HAND, "needs": {BlockIds.SALT_CRUST: 3}, "makes": BlockIds.TABLE_SALT, "count": 1},
	{"id": &"smelt_gold", "at": FURNACE, "needs": {BlockIds.GOLD_QUARTZ: 4}, "makes": BlockIds.GOLD, "count": 1},
	{"id": &"smelt_copper", "at": FURNACE, "needs": {BlockIds.COPPER_ORE: 2}, "makes": BlockIds.COPPER, "count": 1},
	{"id": &"smelt_malachite", "at": FURNACE, "needs": {BlockIds.MALACHITE: 2}, "makes": BlockIds.COPPER, "count": 1},
	{"id": &"smelt_iron", "at": FURNACE, "needs": {BlockIds.BANDED_IRON: 1}, "makes": BlockIds.IRON, "count": 2},
	{"id": &"table_salt", "at": FURNACE, "needs": {BlockIds.ROCK_SALT: 2}, "makes": BlockIds.TABLE_SALT, "count": 1},
	{"id": &"refinery", "at": TABLE, "needs": {BlockIds.IRON: 4, BlockIds.GLASS: 2, BlockIds.BRICK: 2}, "makes": BlockIds.REFINERY, "count": 1},
	{"id": &"kerosene", "at": REFINERY, "needs": {BlockIds.CRUDE_OIL: 1}, "makes": BlockIds.KEROSENE, "count": 1},
	{"id": &"plastic", "at": REFINERY, "needs": {BlockIds.CRUDE_OIL: 2}, "makes": BlockIds.PLASTIC, "count": 3},
	# Spec §26.5 (the Moon and Mars): living off the land, each step with a real fact (RefiningRules.FACTS). Ice melts
	# into water; water splits into hydrogen fuel (it sells: gold for the next rocket's parts) and oxygen; a Solar Oven
	# bakes dust into bricks and gets metals, helium-3 and oxygen out of the finds.
	{"id": &"melt_moon_ice", "at": MELTER, "needs": {BlockIds.ICY_REGOLITH: 2}, "makes": BlockIds.WATER_TANK, "count": 1},
	{"id": &"melt_mars_ice", "at": MELTER, "needs": {BlockIds.GROUND_ICE: 2}, "makes": BlockIds.WATER_TANK, "count": 1},
	{"id": &"melt_polar_ice", "at": MELTER, "needs": {BlockIds.POLAR_ICE: 2}, "makes": BlockIds.WATER_TANK, "count": 1},
	{"id": &"split_fuel", "at": OXYGEN_MAKER, "needs": {BlockIds.WATER_TANK: 2}, "makes": BlockIds.HYDROGEN_FUEL, "count": 1},
	{"id": &"split_oxygen", "at": OXYGEN_MAKER, "needs": {BlockIds.WATER_TANK: 1}, "makes": BlockIds.OXYGEN_TANK, "count": 1},
	{"id": &"rock_oxygen", "at": OXYGEN_MAKER, "needs": {BlockIds.ILMENITE: 2}, "makes": BlockIds.OXYGEN_TANK, "count": 1},
	{"id": &"solar_oven", "at": TABLE, "needs": {BlockIds.IRON: 2, BlockIds.DOME_GLASS: 2}, "makes": BlockIds.SOLAR_OVEN, "count": 1},
	{"id": &"moon_bricks", "at": SOLAR_OVEN, "needs": {BlockIds.MOON_DUST: 4}, "makes": BlockIds.PRINTED_REGOLITH, "count": 2},
	{"id": &"mars_bricks", "at": SOLAR_OVEN, "needs": {BlockIds.MARS_REGOLITH: 4}, "makes": BlockIds.PRINTED_REGOLITH, "count": 2},
	{"id": &"titanium", "at": SOLAR_OVEN, "needs": {BlockIds.ILMENITE: 2}, "makes": BlockIds.TITANIUM, "count": 1},
	{"id": &"helium3", "at": SOLAR_OVEN, "needs": {BlockIds.MARE_DUST: 16}, "makes": BlockIds.HELIUM_3, "count": 1},
	{"id": &"rare_earths", "at": SOLAR_OVEN, "needs": {BlockIds.KREEP_ROCK: 4}, "makes": BlockIds.RARE_EARTHS, "count": 1},
	{"id": &"meteorite_iron", "at": SOLAR_OVEN, "needs": {BlockIds.IRON_METEORITE: 1}, "makes": BlockIds.IRON, "count": 3},
	{"id": &"sieve_blueberries", "at": HAND, "needs": {BlockIds.BLUEBERRY_SOIL: 3}, "makes": BlockIds.HEMATITE, "count": 1},
	{"id": &"hematite_iron", "at": SOLAR_OVEN, "needs": {BlockIds.HEMATITE: 2}, "makes": BlockIds.IRON, "count": 1},
	{"id": &"sand_iron", "at": SOLAR_OVEN, "needs": {BlockIds.DARK_SAND: 4}, "makes": BlockIds.IRON, "count": 1},
	{"id": &"salt_oxygen", "at": SOLAR_OVEN, "needs": {BlockIds.MARS_SALT: 2}, "makes": BlockIds.OXYGEN_TANK, "count": 1},
]


## The recipe with this id, or {}.
static func find(id: StringName) -> Dictionary:
	for r: Dictionary in LIST:
		if r.id == id:
			return r
	return {}


## The (first) recipe that makes `id`, or {}.
static func for_result(id: int) -> Dictionary:
	for r: Dictionary in LIST:
		if r.makes == id:
			return r
	return {}


## The block a station is ("next to a Crafting Table"); AIR for HAND.
static func station_block(at: StringName) -> int:
	match at:
		TABLE:
			return BlockIds.CRAFTING_TABLE
		FURNACE:
			return BlockIds.FURNACE
		REFINERY:
			return BlockIds.REFINERY   # spec §26
		MELTER:   # spec §26.5: the colony's machines and the Solar Oven
			return BlockIds.ICE_MELTER
		OXYGEN_MAKER:
			return BlockIds.OXYGEN_MAKER
		SOLAR_OVEN:
			return BlockIds.SOLAR_OVEN
	return BlockIds.AIR


## What is wrong with a table of recipes (one line per problem; [] = nothing).
static func problems(list: Array) -> Array[String]:
	var out: Array[String] = []
	var ids := {}
	for r: Variant in list:
		if not r is Dictionary or not (r as Dictionary).has_all(["id", "at", "needs", "makes", "count"]):
			out.append("a recipe without its fields: %s" % str(r))
			continue
		var d: Dictionary = r
		var rid := str(d.id)
		if ids.has(d.id):
			out.append("%s: listed twice" % rid)
		ids[d.id] = true
		if not STATIONS.has(d.at):
			out.append("%s: made at an unknown place (%s)" % [rid, d.at])
		if not d.makes is int or not Inventory.ownable(d.makes):
			out.append("%s: makes something no bag holds (%s)" % [rid, d.makes])
		if not d.count is int or int(d.count) <= 0 or int(d.count) > Inventory.MAX_COUNT:
			out.append("%s: makes %s" % [rid, d.count])
		if not d.needs is Dictionary or (d.needs as Dictionary).is_empty():
			out.append("%s: made from nothing" % rid)
			continue
		for id: Variant in d.needs:
			var n: Variant = (d.needs as Dictionary)[id]
			if not id is int or not Inventory.ownable(id):
				out.append("%s: needs something no bag holds (%s)" % [rid, id])
			elif not n is int or int(n) <= 0:
				out.append("%s: needs %s of %s" % [rid, n, ItemIds.display_name(id)])
	if has_loop(list):
		out.append("the recipes go round in a loop")
	return out


## Can following recipes lead from a thing back to itself? (The graph from each ingredient to its result.)
static func has_loop(list: Array) -> bool:
	var edges := {}   # ingredient -> [results]
	for r: Variant in list:
		if not r is Dictionary or not (r as Dictionary).get("needs") is Dictionary:
			continue
		for id: Variant in r.needs:
			if not edges.has(id):
				edges[id] = []
			(edges[id] as Array).append(r.get("makes"))
	var state := {}   # 1 = on the path, 2 = done
	for start: Variant in edges:
		if _loops_from(start, edges, state):
			return true
	return false


static func _loops_from(id: Variant, edges: Dictionary, state: Dictionary) -> bool:
	if state.get(id, 0) == 1:
		return true
	if state.get(id, 0) == 2:
		return false
	state[id] = 1
	for next: Variant in edges.get(id, []):
		if _loops_from(next, edges, state):
			return true
	state[id] = 2
	return false
