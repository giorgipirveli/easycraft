class_name RocketParts
extends RefCounted
## The rocket parts (spec §21d.2, §25.3; owner #78, #79) in one table: blocks on page 32 (RocketPage) a child buys with
## gold at the Launch Site and builds on its pad. Real-ish numbers rounded for children (sources in
## docs/devlog/parts/missions.md): mass in tonnes full and empty (a tank is mostly fuel), an engine's push in
## tonnes-force (how many tonnes it could hold up) and its efficiency, the specific impulse in seconds (how long one
## kilogram of fuel keeps pushing with one kilogram-force: more is better), what a part gives the crew. RocketCheck
## does the sums. Prices in gold, one table (PRICES): the Gold Shop's rocket shelf reads it (the lead wires it, spec
## §25.5). Owner #98: a service module keeps one astronaut for the whole trip (it reuses air and water like the space
## station and grows a little food), and the parts' names in a child's words, with plurals (amount_words, list_words).
## Pure: no nodes, no profile.

const G0 := 9.80665   # m/s²: Earth's gravity at the surface (the rocket equation's g₀)

## id -> {full, empty (tonnes), push (tonnes-force), isp (s), fuel?, space_only?, seats?, keeps? (astronauts it keeps
## going for the whole trip)}
const PARTS := {
	BlockIds.ROCKET_ENGINE: {"full": 4.0, "empty": 4.0, "push": 250.0, "isp": 300.0},
	BlockIds.SPACE_ENGINE: {"full": 3.0, "empty": 3.0, "push": 150.0, "isp": 450.0, "space_only": true},
	BlockIds.FUEL_TANK: {"full": 100.0, "empty": 6.0},
	BlockIds.NOSE_CONE: {"full": 1.0, "empty": 1.0},
	BlockIds.CREW_CAPSULE: {"full": 5.0, "empty": 5.0, "seats": 1},
	BlockIds.SERVICE_MODULE: {"full": 4.0, "empty": 4.0, "keeps": 1},   # owner #98: one astronaut, however long the trip
	BlockIds.HEAT_SHIELD: {"full": 2.0, "empty": 2.0},
	BlockIds.LANDING_LEGS: {"full": 1.0, "empty": 1.0},
	BlockIds.ROCKET_FINS: {"full": 0.5, "empty": 0.5},
	BlockIds.STAGE_SEPARATOR: {"full": 1.0, "empty": 1.0},
	BlockIds.SOLAR_ARRAY: {"full": 0.5, "empty": 0.5},
	BlockIds.PARACHUTE_PACK: {"full": 1.0, "empty": 1.0},
}

## Gold for one part, in every mode (the rest of the Sandbox stays free). Owner #98: halved (multiples of 5, at least 5)
## and tuned with Mission Control's plans (RocketPlan): the Moon's about a good day of learning (EarnRules: 150 gold for
## answers and 100 a unit mastered), Mars's under 900, the far worlds' mostly under 2,000, Mercury's the dearest (its
## speed). The plans' table is in docs/devlog/parts/rocket-easier.md ("As built").
const PRICES := {
	BlockIds.ROCKET_ENGINE: 25, BlockIds.SPACE_ENGINE: 30, BlockIds.FUEL_TANK: 5, BlockIds.NOSE_CONE: 5,
	BlockIds.CREW_CAPSULE: 40, BlockIds.SERVICE_MODULE: 20, BlockIds.HEAT_SHIELD: 20, BlockIds.LANDING_LEGS: 5,
	BlockIds.ROCKET_FINS: 5, BlockIds.STAGE_SEPARATOR: 5, BlockIds.SOLAR_ARRAY: 10, BlockIds.PARACHUTE_PACK: 15,
}

## The shop's order: what pushes and what burns, then what the crew needs.
const ORDER: Array[int] = [BlockIds.ROCKET_ENGINE, BlockIds.SPACE_ENGINE, BlockIds.FUEL_TANK, BlockIds.NOSE_CONE,
	BlockIds.CREW_CAPSULE, BlockIds.SERVICE_MODULE, BlockIds.HEAT_SHIELD, BlockIds.LANDING_LEGS, BlockIds.ROCKET_FINS,
	BlockIds.STAGE_SEPARATOR, BlockIds.SOLAR_ARRAY, BlockIds.PARACHUTE_PACK]

## Owner #98: each part's name in a child's words, one and many ("8 rocket engines, 10 fuel tanks").
const NAMES := {
	BlockIds.ROCKET_ENGINE: ["rocket engine", "rocket engines"], BlockIds.SPACE_ENGINE: ["space engine", "space engines"],
	BlockIds.FUEL_TANK: ["fuel tank", "fuel tanks"], BlockIds.NOSE_CONE: ["nose cone", "nose cones"],
	BlockIds.CREW_CAPSULE: ["crew capsule", "crew capsules"],
	BlockIds.SERVICE_MODULE: ["service module", "service modules"], BlockIds.HEAT_SHIELD: ["heat shield", "heat shields"],
	BlockIds.LANDING_LEGS: ["landing leg", "landing legs"], BlockIds.ROCKET_FINS: ["fin", "fins"],
	BlockIds.STAGE_SEPARATOR: ["stage separator", "stage separators"], BlockIds.SOLAR_ARRAY: ["solar array", "solar arrays"],
	BlockIds.PARACHUTE_PACK: ["parachute pack", "parachute packs"],
}

## What each part does, in a child's words (the shop's cards, the rocket science panel).
const WORDS := {
	BlockIds.ROCKET_ENGINE: "Burns kerosene with oxygen. Hot gas rushes down out of its bell, so the rocket goes up.",
	BlockIds.SPACE_ENGINE: "Burns hydrogen: the best rocket fuel. Its huge bell is made for space: stage 2 and up.",
	BlockIds.FUEL_TANK: "94 tonnes of fuel and liquid oxygen. A rocket brings its own oxygen: space has no air.",
	BlockIds.NOSE_CONE: "A pointed top: air slides round it instead of pushing hard on a flat top.",
	BlockIds.CREW_CAPSULE: "A seat and a window for one astronaut. It rides on top of the rocket.",
	BlockIds.SERVICE_MODULE: "Air, water and food for one astronaut for the whole trip: it reuses air and water like the "
		+ "space station.",
	BlockIds.HEAT_SHIELD: "Rushing down through a planet's air makes things glow hot. The shield keeps you cool.",
	BlockIds.LANDING_LEGS: "Three legs stand steady on bumpy ground, like a stool.",
	BlockIds.ROCKET_FINS: "Keep a rocket flying straight through the air, like the feathers on an arrow.",
	BlockIds.STAGE_SEPARATOR: "Goes between stages. An empty stage drops away, so the rest is lighter.",
	BlockIds.SOLAR_ARRAY: "Turns sunlight into electricity: lights, radio and air pumps for the crew.",
	BlockIds.PARACHUTE_PACK: "Opens in a planet's air and slows the lander down before its engines land it.",
}


## What real ones are made of (the shop's cards; Survivor makes the simple ones from real materials: craft_words).
const MADE_OF := {
	BlockIds.ROCKET_ENGINE: "Real ones: steel and copper that stand huge heat; the cold fuel cools the bell.",
	BlockIds.SPACE_ENGINE: "Real ones: steel, copper and nickel; the bell is thin to be light.",
	BlockIds.FUEL_TANK: "Real ones: thin aluminium walls, as light as they can be.",
	BlockIds.NOSE_CONE: "Real ones: aluminium or carbon fibre.",
	BlockIds.CREW_CAPSULE: "Real ones: aluminium walls and a window of thick layered glass.",
	BlockIds.SERVICE_MODULE: "Real ones: tanks, pumps, batteries and radiators in an aluminium shell.",
	BlockIds.HEAT_SHIELD: "Real ones: ceramic tiles (baked like pottery) or a resin that slowly chars away.",
	BlockIds.LANDING_LEGS: "Real ones: aluminium struts with shock absorbers that squash on landing.",
	BlockIds.ROCKET_FINS: "Real ones: aluminium or titanium.",
	BlockIds.STAGE_SEPARATOR: "Real ones: a metal ring with springs that push the stages apart.",
	BlockIds.SOLAR_ARRAY: "Real ones: silicon cells (silicon is made from sand) behind glass.",
	BlockIds.PARACHUTE_PACK: "Real ones: strong nylon cloth and cords, folded tight in a canister.",
}


static func is_part(id: int) -> bool:
	return PARTS.has(id)


static func mass_full(id: int) -> float:
	return float(PARTS.get(id, {}).get("full", 0.0))


static func mass_empty(id: int) -> float:
	return float(PARTS.get(id, {}).get("empty", 0.0))


## Tonnes of fuel (and oxygen) a full part holds.
static func fuel(id: int) -> float:
	return mass_full(id) - mass_empty(id)


static func push(id: int) -> float:
	return float(PARTS.get(id, {}).get("push", 0.0))


static func isp(id: int) -> float:
	return float(PARTS.get(id, {}).get("isp", 0.0))


static func is_engine(id: int) -> bool:
	return push(id) > 0.0


## An engine made for space: in the first stage it does not lift off.
static func space_only(id: int) -> bool:
	return bool(PARTS.get(id, {}).get("space_only", false))


static func seats(id: int) -> int:
	return int(PARTS.get(id, {}).get("seats", 0))


## Astronauts this part keeps going for the whole trip (owner #98: a service module cleans and reuses its astronaut's
## air and water, like the space station, and grows a little food; the trip's real length stays on the mission's card).
static func keeps(id: int) -> int:
	return int(PARTS.get(id, {}).get("keeps", 0))


static func made_of(id: int) -> String:
	return str(MADE_OF.get(id, ""))


## Survivor: how to make this part ("Make 2 at a Workbench: 1 Iron"), "" for a part only bought.
static func craft_words(id: int) -> String:
	var r := Recipes.for_result(id)
	if r.is_empty():
		return ""
	var needs: Array[String] = []
	for k: int in r.needs:
		needs.append("%d %s" % [int(r.needs[k]), ItemIds.display_name(k)])
	var at := "a Workbench" if r.at == Recipes.TABLE else ("a Clay Oven" if r.at == Recipes.FURNACE else "hand")
	var made := "Make it" if int(r.count) == 1 else "Make %d" % int(r.count)
	return "%s at %s: %s." % [made, at, ", ".join(needs)]


## "1 rocket engine", "8 rocket engines" (owner #98: plurals a young reader and the speaker follow).
static func amount_words(id: int, n: int) -> String:
	var names: Array = NAMES.get(id, [BlockIds.display_name(id), BlockIds.display_name(id)])
	return "%d %s" % [n, names[0] if n == 1 else names[1]]


## "8 rocket engines, 10 fuel tanks and 3 fins": the parts ({id: count}) in the shop's order ("" for none).
static func list_words(parts: Dictionary) -> String:
	var out: Array[String] = []
	for id in ORDER:
		if int(parts.get(id, 0)) > 0:
			out.append(amount_words(id, int(parts[id])))
	if out.size() <= 1:
		return "" if out.is_empty() else out[0]
	return "%s and %s" % [", ".join(out.slice(0, out.size() - 1)), out[out.size() - 1]]


## How many parts there are in {id: count}.
static func total(parts: Dictionary) -> int:
	var n := 0
	for id: int in parts:
		if is_part(id):
			n += maxi(int(parts[id]), 0)
	return n


static func price(id: int) -> int:
	return int(PRICES.get(id, 0))


static func words(id: int) -> String:
	return str(WORDS.get(id, ""))


## Gold for these parts ({id: count}); what is not a part costs nothing here.
static func cost(parts: Dictionary) -> int:
	var total_gold := 0
	for id: int in parts:
		total_gold += price(id) * maxi(int(parts[id]), 0)
	return total_gold


## The parts `needed` ({id: count}) has more of than `owned`: {id: how many more}.
static func missing(needed: Dictionary, owned: Dictionary) -> Dictionary:
	var out := {}
	for id: int in needed:
		var short := int(needed[id]) - int(owned.get(id, 0))
		if short > 0 and is_part(id):
			out[id] = short
	return out


## {id: count} of the parts in cells ({Vector3i: id}).
static func count(cells: Dictionary) -> Dictionary:
	var out := {}
	for p: Vector3i in cells:
		var id: int = cells[p]
		if is_part(id):
			out[id] = int(out.get(id, 0)) + 1
	return out


## The core loop (owner #79, #83): the Gold Shop's ROCKET PARTS shelf sells every part at its price, again and again.
## Called by the Gold Shop and at the start (register ignores a second call). Owner #98 (bug 1): the part goes where
## grant() puts it, so one bought in the menu is never lost to a Survivor world.
static func register_shelf() -> void:
	for part: int in ORDER:
		SpendRules.register(SpendRules.ROCKET, {"id": "part:%d" % part, "name": BlockIds.display_name(part),
			"price": price(part), "repeat": true, "block": part},
			func(profile: ProfileData, _id: String) -> void: grant(profile, part, 1))


## A part given outside a world (the Gold Shop, a friend's present): for every Sandbox rocket (MissionData) and, in the
## backpack, for the next Survivor world's bag (owner #98, bugs 1 and 2: one purchase, both pots; a ruling in
## docs/devlog/parts/rocket-easier.md). The caller saves.
static func grant(profile: ProfileData, part: int, n: int) -> void:
	if not is_part(part) or n <= 0:
		return
	profile.missions.add_part(part, n)
	profile.backpack[part] = mini(int(profile.backpack.get(part, 0)) + n, Inventory.MAX_COUNT)


## Where grant() puts a part, in words (the Gold Shop's and the present's "It's yours!").
const GRANT_WORDS := "For your Sandbox rockets, and in your backpack for your next Survivor world."
