class_name ColonyRules
extends RefCounted
## Colonies under domes (owner #77: "on the planets like moon, create domes for living creatures, something like [a
## famous rocket builder] is dreaming, find it. same on the mars"; spec §21c) as pure rules: which worlds have one, its
## parts and the real fact each part says (the descriptors' sights, SpaceSights: the Great Dome is the big sight on MY
## MAP and the explorer's checklist, the other parts are small ones found by walking in), each planet's own blocks in it,
## the Great Dome's animals (the game's own, living only under the glass: ColonyAnimals), Tilly's stock there and the
## Gold Shop's dome decorations. Where the colony stands and what it is built of: ColonyLayout.
## The real idea (checked against the agencies' own pages; sources in docs/devlog/parts/colony-domes.md): a base near the
## Moon's south pole, a city on Mars; homes under glass domes and shields of planet dust or ice, greenhouses under lamps,
## water from ice, oxygen from water or from Mars's air, solar power, and a big rocket that lands on its legs and flies
## again. No real person's, company's or mission's name in the game (spec §21b.2): "a rover", "rocket builders".

const PLANETS: Array[StringName] = [SpaceShape.MOON, SpaceShape.MARS]

## The parts (sight ids). The Great Dome is DOME, the colony's big sight ("sight:colony" in the world's secrets).
const DOME := &"colony"
const GARDEN := &"colony_garden"
const AIRLOCK := &"colony_airlock"
const HOMES := &"colony_homes"
const LAB := &"colony_lab"
const WATER := &"colony_water"
const OXYGEN := &"colony_oxygen"
const CONTROL := &"colony_control"
const SOLAR := &"colony_solar"
const ROCKET := &"colony_rocket"
const GARAGE := &"colony_garage"
const MINE := &"colony_mine"
const PARTS: Array[StringName] = [DOME, GARDEN, AIRLOCK, HOMES, LAB, WATER, OXYGEN, CONTROL, SOLAR, ROCKET, GARAGE, MINE]

## planet -> {part: {"name", "words"}}: a find, then a real fact (each checked; the notes list the sources).
const WORDS := {
	SpaceShape.MARS: {
		DOME: {"name": "Mars Colony", "words":
			"You found the Mars Colony's Great Dome! Mars's air is too thin to breathe, so the dome keeps air in for life."},
		GARDEN: {"name": "Greenhouse", "words":
			"You found the greenhouse! Astronauts have grown lettuce, cabbage, kale and even flowers in space."},
		AIRLOCK: {"name": "Airlock", "words":
			"You found the airlock! A real one has two doors, and one always stays shut, so the air never gets out."},
		HOMES: {"name": "Homes", "words":
			"You found the homes! A thick shell of Mars soil or ice over a home keeps out the Sun's harmful rays."},
		LAB: {"name": "Lab", "words":
			"You found the lab! A rover on Mars seals rock samples in tubes, so scientists can study them one day."},
		WATER: {"name": "Water Plant", "words":
			"You found the water plant! Ice hides just under the dust in many places on Mars: melted, it is water to drink."},
		OXYGEN: {"name": "Oxygen Maker", "words":
			"You found the oxygen maker! A rover's machine made oxygen from Mars's air: what a small dog breathes in 10 hours."},
		CONTROL: {"name": "Control Room", "words":
			"You found the control room! A radio message from Mars takes 3 to 22 minutes to reach Earth."},
		SOLAR: {"name": "Solar Panels", "words":
			"You found the solar panels! Mars gets less than half of Earth's sunshine, and dust must be cleaned off them."},
		ROCKET: {"name": "Big Rocket", "words":
			"You found the big rocket! Rockets that land on their legs can fly again. Earth to Mars takes about 7 months."},
		GARAGE: {"name": "Rover Garage", "words":
			"You found the rover garage! A rover on Mars drove more than a marathon: over 45 kilometres."},
		MINE: {"name": "Ice Mine", "words":
			"You found the ice mine! Ice can be split into hydrogen and oxygen: rocket fuel for the trip home."},
	},
	SpaceShape.MOON: {
		DOME: {"name": "Moon Colony", "words":
			"You found the Moon Colony's Great Dome! The Moon has no air to breathe, so the dome keeps air in for life."},
		GARDEN: {"name": "Greenhouse", "words":
			"You found the greenhouse! Plants in space grow under pink lamps: they use red and blue light the most."},
		AIRLOCK: {"name": "Airlock", "words":
			"You found the airlock! A real one has two doors, and one always stays shut, so the air never gets out."},
		HOMES: {"name": "Homes", "words":
			"You found the homes! Robots could print a shell of Moon dust over them: a shield from the Sun's rays."},
		LAB: {"name": "Lab", "words":
			"You found the lab! Astronauts brought 382 kilograms of Moon rock home, and scientists still study it."},
		WATER: {"name": "Water Plant", "words":
			"You found the water plant! Craters near the Moon's south pole stay in shadow and hold ice: water to drink."},
		OXYGEN: {"name": "Oxygen Maker", "words":
			"You found the oxygen maker! On the space station, electricity splits water into oxygen to breathe."},
		CONTROL: {"name": "Control Room", "words":
			"You found the control room! A radio message from the Moon reaches Earth in about 1.3 seconds."},
		SOLAR: {"name": "Solar Panels", "words":
			"You found the solar panels! Near the Moon's south pole, some high places get sunshine almost all the time."},
		ROCKET: {"name": "Big Rocket", "words":
			"You found the big rocket! Some new Moon landers land on their legs and stand as tall as a 15-storey building."},
		GARAGE: {"name": "Rover Garage", "words":
			"You found the rover garage! Astronauts drove an electric car on the Moon in 1971 and 1972."},
		MINE: {"name": "Ice Crater", "words":
			"You found the ice crater! Space agencies plan a base near the Moon's south pole, where dark craters hold ice."},
	},
}

## Each planet's own blocks in its colony: the ice in the mine and the water plant, the mine's rim, the lab's samples
## (a rock and a crystal).
const PALETTE := {
	SpaceShape.MOON: {"ice": BlockIds.SHADOW_ICE, "rim": BlockIds.MOON_ROCK, "rock": BlockIds.MOON_ROCK,
		"crystal": BlockIds.MOON_CRYSTAL, "glint": BlockIds.ICE_CRYSTAL},
	SpaceShape.MARS: {"ice": BlockIds.POLAR_ICE, "rim": BlockIds.MARS_REGOLITH, "rock": BlockIds.BASALT,
		"crystal": BlockIds.GYPSUM, "glint": BlockIds.GYPSUM},
}

## The Great Dome's animals: the game's own, living only under the glass (ColonyAnimals). Fish swim in its pond.
const HERD: Array[Dictionary] = [{"species": &"rabbit", "count": 2}, {"species": &"chicken", "count": 3},
	{"species": &"duck", "count": 2}, {"species": &"fish", "count": 3}]

## Tilly's colony blocks on the Moon and Mars (gold for one; never scaled in space).
const STOCK := {
	BlockIds.DOME_GLASS: 2, BlockIds.COLONY_PANEL: 2, BlockIds.COLONY_FLOOR: 1, BlockIds.GREENHOUSE_SOIL: 2,
	BlockIds.GROW_LAMP: 4, BlockIds.COLONY_LIGHT: 4, BlockIds.FRUIT_LEAVES: 2, BlockIds.WATER_TANK: 4,
	BlockIds.ICE_MELTER: 5, BlockIds.OXYGEN_MAKER: 6, BlockIds.CONTROL_SCREEN: 5, BlockIds.COLONY_MAP: 6,
	BlockIds.AIRLOCK_FRAME: 3, BlockIds.ROCKET_HULL: 3, BlockIds.PRINTED_REGOLITH: 2, BlockIds.COLONY_TABLE: 3,
}

## The Gold Shop's DECORATIONS shelf (SpendRules.DECOR): dome decorations, bought again and again, into the backpack
## (they come into the next Survivor world): {"id", "name", "price", "blocks": [[id, count], …]}.
const DECOR: Array[Dictionary] = [
	{"id": "decor:dome_glass", "name": "Dome Glass x20", "price": 60, "blocks": [[BlockIds.DOME_GLASS, 20]]},
	{"id": "decor:grow_lamps", "name": "Grow Lamps x4", "price": 60, "blocks": [[BlockIds.GROW_LAMP, 4]]},
	{"id": "decor:greenhouse", "name": "Greenhouse Soil x10", "price": 40, "blocks": [[BlockIds.GREENHOUSE_SOIL, 10]]},
	{"id": "decor:fruit_tree", "name": "Fruit Tree", "price": 80,
		"blocks": [[BlockIds.LOG, 4], [BlockIds.FRUIT_LEAVES, 12]]},
	{"id": "decor:lights", "name": "Colony Lights x4", "price": 50, "blocks": [[BlockIds.COLONY_LIGHT, 4]]},
	{"id": "decor:tables", "name": "Colony Tables x2", "price": 40, "blocks": [[BlockIds.COLONY_TABLE, 2]]},
	{"id": "decor:water_tanks", "name": "Water Tanks x2", "price": 60, "blocks": [[BlockIds.WATER_TANK, 2]]},
	{"id": "decor:oxygen", "name": "Oxygen Maker", "price": 80, "blocks": [[BlockIds.OXYGEN_MAKER, 1]]},
	{"id": "decor:screens", "name": "Control Screens x2", "price": 80, "blocks": [[BlockIds.CONTROL_SCREEN, 2]]},
	{"id": "decor:map", "name": "Colony Map", "price": 80, "blocks": [[BlockIds.COLONY_MAP, 1]]},
]


static func has_colony(planet: StringName) -> bool:
	return PLANETS.has(planet)


## A colony part's sight id.
static func is_part(id: StringName) -> bool:
	return PARTS.has(id)


## A part other than the Great Dome: found by walking in, never on MY MAP or the checklist by itself.
static func is_small_part(id: StringName) -> bool:
	return is_part(id) and id != DOME


## The colony's sights on `planet` ({part: {"name", "words"}}; {} where there is no colony).
static func sights(planet: StringName) -> Dictionary:
	return (WORDS.get(planet, {}) as Dictionary).duplicate(true)


## A descriptor's own sights with the colony's added (the descriptors' `sights`).
static func with_sights(planet: StringName, own: Dictionary) -> Dictionary:
	var out := own.duplicate(true)
	out.merge(sights(planet))
	return out


## A descriptor's own Tilly stock with the colony's blocks added (the descriptors' `trader_stock`).
static func with_stock(own: Dictionary) -> Dictionary:
	var out := own.duplicate()
	out.merge(STOCK)
	return out


## The planet's own block for `what` in its colony (PALETTE: "ice", "rim", "rock", "crystal", "glint").
static func block(planet: StringName, what: String) -> int:
	return int((PALETTE.get(planet, PALETTE[SpaceShape.MOON]) as Dictionary)[what])


## Hangs the dome decorations on the Gold Shop's DECORATIONS shelf (the shop calls it; a second call adds nothing).
static func register_shelf() -> void:
	for d: Dictionary in DECOR:
		var blocks: Array = d.blocks
		SpendRules.register(SpendRules.DECOR, {"id": d.id, "name": d.name, "price": d.price, "repeat": true,
			"block": int(blocks[0][0])}, func(profile: ProfileData, _id: String) -> void: pack(profile, blocks))


## Puts [[id, count], …] into the profile's backpack (it comes into the next Survivor world).
static func pack(profile: ProfileData, blocks: Array) -> void:
	for b: Array in blocks:
		var id := int(b[0])
		profile.backpack[id] = mini(int(profile.backpack.get(id, 0)) + int(b[1]), Inventory.MAX_COUNT)
