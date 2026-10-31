class_name DepositKinds
extends RefCounted
## Prospecting (spec §26.1, owner #80): the kinds of rich deposits, each where real geology puts it and with the
## telltale sign a child learns to read. Earth: Green Meadows (universe 1) has gold, iron and coal; the Sandstorm Desert
## (universe 2) copper, oil and salt. Space (spec §26.5): the Moon (world 16) its ice in dark craters, ilmenite in its
## dark seas, helium-3 in their old dust, KREEP's rare earths and iron meteorites; Mars (world 19) its ground ice,
## hematite "blueberries", dark iron-rich sand, salt from old lakes and iron meteorites. DepositRules places them from the
## seed (SpaceDepositSites the planets'); ProspectQuests teaches how to find them; RefiningRules turns what they give into
## metal, fuel, salt, water, air and bricks. A kind is one row here.

const GOLD := &"gold"
const COPPER := &"copper"
const IRON := &"iron"
const COAL := &"coal"
const OIL := &"oil"
const SALT := &"salt"
# The Moon (spec §26.5)
const MOON_ICE := &"moon_ice"
const ILMENITE := &"ilmenite"
const HELIUM_3 := &"helium3"
const KREEP := &"kreep"
const MOON_METEORITE := &"moon_meteorite"
# Mars (spec §26.5)
const MARS_ICE := &"mars_ice"
const HEMATITE := &"hematite"
const DARK_SAND := &"dark_sand"
const MARS_SALT := &"mars_salt"
const MARS_METEORITE := &"mars_meteorite"
## Every kind, in the prospecting board's order (Earth's, the Moon's, Mars's).
const ALL: Array[StringName] = [GOLD, COPPER, IRON, COAL, OIL, SALT, MOON_ICE, ILMENITE, HELIUM_3, KREEP, MOON_METEORITE,
	MARS_ICE, HEMATITE, DARK_SAND, MARS_SALT, MARS_METEORITE]
## The worlds whose quests one board tells together (Earth's two; each planet its own).
const PLACES: Array = [[1, 2], [16], [19]]

## kind -> its data:
## - name: what a child calls it; universe: the world it is found in;
## - setting: where real geology puts it (one short line); sign: what shows it at the top; sign_block: that block;
## - ore: the block its rich body is made of (oil: none, it is pumped); work: how people get it out, and with what;
## - map: the MY MAP mark's name; what, mark (spec §26.5, optional): what the map's question calls it ("signs of ice")
##   and the name a quest's words use ("Mark the KREEP crater"), else the name and the map's in small letters.
const DATA := {
	GOLD: {"name": "Gold", "universe": 1, "picture": &"gold",
		"setting": "Gold grows in white quartz veins in old hills. Rivers wash flakes of it down into their gravel.",
		"sign": "shiny gold flakes in the river's gravel, and a white quartz stripe in the hill above",
		"sign_block": BlockIds.GOLD_GRAVEL, "ore": BlockIds.GOLD_QUARTZ,
		"work": "Pan the river gravel for flakes, and dig a mine into the hill for the quartz vein.",
		"map": "Gold vein"},
	COPPER: {"name": "Copper", "universe": 2, "picture": &"copper",
		"setting": "Big copper deposits lie in dry mountains. Where copper meets the air, it turns the rock green.",
		"sign": "green stains of malachite on the rocks", "sign_block": BlockIds.MALACHITE, "ore": BlockIds.COPPER_ORE,
		"work": "Dig an open pit, a quarry, for the grey copper ore, then smelt it.",
		"map": "Copper mine"},
	IRON: {"name": "Iron", "universe": 1, "picture": &"iron",
		"setting": "Iron ore lies in striped rock laid down in the seas long ago. At the top it rusts red.",
		"sign": "rusty red rock on a hill, and a compass needle that swings towards it",
		"sign_block": BlockIds.RUSTY_ROCK, "ore": BlockIds.BANDED_IRON,
		"work": "Dig the banded iron out of the hill, then smelt it with coal.",
		"map": "Iron hill"},
	COAL: {"name": "Coal", "universe": 1, "picture": &"coal",
		"setting": "Coal was a swamp forest long ago. Its plants were buried and squeezed into black rock.",
		"sign": "a black stripe in a hillside, with fern prints in the grey rock above it",
		"sign_block": BlockIds.FERN_SHALE, "ore": BlockIds.COAL,
		"work": "Dig along the black stripe, the seam, into the hill.",
		"map": "Coal seam"},
	OIL: {"name": "Oil", "universe": 2, "picture": &"oil",
		"setting": "Oil comes from tiny sea creatures buried long ago. It rises until a dome of tight rock traps it.",
		"sign": "dark, sticky sand where a little oil seeps up", "sign_block": BlockIds.OIL_SEEP, "ore": BlockIds.AIR,
		"work": "Drill a well at the top of the dome, then a pump jack lifts the oil up.",
		"map": "Oil well"},
	SALT: {"name": "Salt", "universe": 2, "picture": &"salt",
		"setting": "A salt flat is a lake or a sea that dried up in the sun and left its salt behind.",
		"sign": "flat, white, crusty ground where nothing grows", "sign_block": BlockIds.SALT_CRUST,
		"ore": BlockIds.ROCK_SALT,
		"work": "Scrape the crust and quarry the rock salt under it, then clean it.",
		"map": "Salt flat"},
	MOON_ICE: {"name": "Moon Ice", "universe": 16, "picture": &"moon_ice",
		"setting": "Near the Moon's poles, the floors of deep craters never see the Sun. They are so cold that ice stays there.",
		"sign": "frosty grey dust on the floor of a deep, dark crater", "sign_block": BlockIds.ICY_REGOLITH,
		"ore": BlockIds.ICY_REGOLITH,
		"work": "Dig the icy dust and melt it into water. Split the water: oxygen to breathe and hydrogen fuel for rockets.",
		"map": "Ice crater", "what": "ice", "mark": "ice crater"},
	ILMENITE: {"name": "Ilmenite", "universe": 16, "picture": &"ilmenite",
		"setting": "The Moon's dark seas are plains of old lava. Their rock holds ilmenite: iron, titanium and oxygen.",
		"sign": "dark grey dust with black crystals, on a low, flat plain", "sign_block": BlockIds.MARE_DUST,
		"ore": BlockIds.ILMENITE,
		"work": "Dig the black ilmenite under the dark dust. Heat it for titanium, or pull oxygen out of it to breathe.",
		"map": "Ilmenite sea", "what": "ilmenite", "mark": "ilmenite sea"},
	HELIUM_3: {"name": "Helium-3", "universe": 16, "picture": &"helium3",
		"setting": "The Sun's wind has blown on the Moon for billions of years and left a rare gas, helium-3, in its dust.",
		"sign": "a wide, flat plain of old, dark dust with no young craters", "sign_block": BlockIds.MARE_DUST,
		"ore": BlockIds.MARE_DUST,
		"work": "Scoop up lots of the dark dust and heat it in a Solar Oven: a tiny bit of helium-3 comes out.",
		"map": "Helium-3 sea", "what": "helium-3", "mark": "helium-3 sea"},
	KREEP: {"name": "Rare Earths", "universe": 16, "picture": &"kreep",
		"setting": "Giant impacts dug up KREEP rock, rich in rare earths, and threw it round their craters.",
		"sign": "pale, speckled rock on a crater's rim", "sign_block": BlockIds.KREEP_ROCK, "ore": BlockIds.KREEP_ROCK,
		"work": "Dig the KREEP rock and bake it in a Solar Oven: rare earths for strong magnets.",
		"map": "KREEP crater", "what": "KREEP rock", "mark": "KREEP crater"},
	MOON_METEORITE: {"name": "Moon Meteorite", "universe": 16, "picture": &"meteorite",
		"setting": "Space rocks hit the Moon all the time: it has no air to slow them. A few of them are iron.",
		"sign": "a lump of dark, shiny iron in a small crater", "sign_block": BlockIds.IRON_METEORITE,
		"ore": BlockIds.IRON_METEORITE,
		"work": "Dig out the meteorite and melt it in a Solar Oven: iron to build with.",
		"map": "Moon meteorite", "what": "a meteorite", "mark": "meteorite"},
	MARS_ICE: {"name": "Mars Ice", "universe": 19, "picture": &"mars_ice",
		"setting": "Mars hides water ice just under its dust, away from its warmer middle. A fresh crater shows it.",
		"sign": "bright white ice in the floor of a small, fresh crater", "sign_block": BlockIds.GROUND_ICE,
		"ore": BlockIds.GROUND_ICE,
		"work": "Dig the ice and melt it into water. Split the water: oxygen to breathe and hydrogen fuel for rockets.",
		"map": "Ice crater", "what": "ice", "mark": "ice crater"},
	HEMATITE: {"name": "Hematite", "universe": 19, "picture": &"hematite",
		"setting": "Long ago, water soaked through Mars's rock and grew little balls of hematite, an iron ore.",
		"sign": "little grey balls, the blueberries, all over the red dust", "sign_block": BlockIds.BLUEBERRY_SOIL,
		"ore": BlockIds.HEMATITE,
		"work": "Sieve the blueberries out of the dust, dig the hematite rock under it, and heat it: iron.",
		"map": "Blueberry field", "what": "blueberries", "mark": "blueberry field"},
	DARK_SAND: {"name": "Iron Sand", "universe": 19, "picture": &"dark_sand",
		"setting": "Mars is red because its dust is rusty. Its dark sand is full of iron grains a magnet picks up.",
		"sign": "dark sand on a crater's floor", "sign_block": BlockIds.DARK_SAND, "ore": BlockIds.DARK_SAND,
		"work": "Scoop the dark sand and melt its iron grains in a Solar Oven: iron to build with.",
		"map": "Dark dunes", "what": "iron sand", "mark": "dark dunes"},
	MARS_SALT: {"name": "Mars Salt", "universe": 19, "picture": &"mars_salt",
		"setting": "Where old lakes on Mars dried up, they left salt. One kind, perchlorate, holds lots of oxygen.",
		"sign": "a pale, cracked crust on low, flat ground", "sign_block": BlockIds.MARS_SALT, "ore": BlockIds.MARS_SALT,
		"work": "Scrape up the salt and heat it in a Solar Oven: it gives off oxygen to breathe.",
		"map": "Salt basin", "what": "salt", "mark": "salt basin"},
	MARS_METEORITE: {"name": "Mars Meteorite", "universe": 19, "picture": &"meteorite",
		"setting": "Iron meteorites lie on Mars's plains. Mars is so dry and cold that they rust very slowly.",
		"sign": "a dark, shiny iron rock sitting on the red plain", "sign_block": BlockIds.IRON_METEORITE,
		"ore": BlockIds.IRON_METEORITE,
		"work": "Pick up the meteorite and melt it in a Solar Oven: iron to build with.",
		"map": "Mars meteorite", "what": "a meteorite", "mark": "meteorite"},
}


static func is_kind(kind: StringName) -> bool:
	return DATA.has(kind)


static func data(kind: StringName) -> Dictionary:
	return DATA.get(kind, {})


static func display_name(kind: StringName) -> String:
	return str(data(kind).get("name", ""))


## What a quest's map calls the kind ("signs of gold", "signs of ice").
static func what(kind: StringName) -> String:
	return str(data(kind).get("what", display_name(kind).to_lower()))


## The find's name in a sentence ("the gold vein", "the KREEP crater").
static func mark_words(kind: StringName) -> String:
	return str(data(kind).get("mark", str(data(kind).get("map", "find")).to_lower()))


static func universe_of(kind: StringName) -> int:
	return int(data(kind).get("universe", 0))


## The kinds found in universe u (in ALL's order).
static func in_universe(u: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for k in ALL:
		if universe_of(k) == u:
			out.append(k)
	return out


## The worlds whose quests the board in world u tells (Earth's two together; a planet its own; [] elsewhere).
static func place_of(u: int) -> Array:
	for p: Array in PLACES:
		if p.has(u):
			return p
	return []


## The kinds a board in world u shows: its place's (Earth's six in Green Meadows and the desert).
static func told_in(u: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var place := place_of(u)
	for k in ALL:
		if place.has(universe_of(k)):
			out.append(k)
	return out


## Space's kinds (the Moon's and Mars's): their quests live off the land (spec §26.5).
static func in_space(kind: StringName) -> bool:
	return SpaceRules.is_space(universe_of(kind))


## The kind a found block belongs to (a sign or an ore of a deposit), or &"".
static func kind_of_block(id: int) -> StringName:
	for k in ALL:
		if id != BlockIds.AIR and (int(DATA[k].sign_block) == id or int(DATA[k].ore) == id):
			return k
	if id == BlockIds.GOLD_QUARTZ:
		return GOLD
	return &""
