class_name RefiningRules
extends RefCounted
## Mining and refining, as people really do it (spec §26.3, §26.4). What a deposit gives is worked in real steps, each
## with one real fact (said when it is made): gravel panned for gold; gold quartz, copper ore, malachite and banded iron
## smelted in the Clay Oven (it burns coal or wood, like a real furnace's fuel); rock salt dissolved, cleaned and dried;
## a salt crust scraped and dried in the sun; crude oil from an oil well's pump jack split at the Refinery into kerosene
## (the fuel jets and many rockets burn: ROCKET_FUEL, the hook the rocket's fuel can use later) and plastic. The recipes
## live in Recipes.LIST with the rest (Survivor's craft book: CraftRules checks and makes them); this file has their facts
## and what refined things sell for at Tilly's (ShopRules.SELL_PRICES reads SELL): a fair price, higher than the raw
## ore's (refining pays), and nothing here is ever sold by Tilly, so no loop can mint gold.
## Spec §26.5 (the Moon and Mars): in-situ resource use, living off the land. Ice melts into water at an Ice Melter; an
## Oxygen Maker splits water into hydrogen fuel and oxygen and pulls oxygen out of ilmenite; a Solar Oven (mirrors and
## sunlight) bakes planet dust into the colony's bricks and gets titanium, helium-3, rare earths, iron and Mars salt's
## oxygen out of the finds. What pays: hydrogen fuel (SPACE_FUEL: rocket fuel made far from Earth; its gold buys the
## next rocket's parts, which stay bought with gold: RocketParts), titanium, helium-3, rare earth powder and iron, each
## for less than Tilly's own water and ice would cost to make it (her colony stock sells water tanks and polar ice: no
## loop); what helps (never bought): water, air, bricks (HELPS).

## The rocket's fuel hook (spec §26.3, §25.3): a drum of kerosene is what a kerosene engine burns (RocketParts: the Rocket
## Engine). The missions may later ask for it to fill their Fuel Tanks; nothing asks for it yet.
const ROCKET_FUEL := BlockIds.KEROSENE
## Spec §26.5: the fuel split from the Moon's and Mars's ice (liquid hydrogen and oxygen, what a Space Engine burns): it
## sells at Tilly's, and its gold buys the next rocket's Fuel Tanks (the missions may later fill a tank with it).
const SPACE_FUEL := BlockIds.HYDROGEN_FUEL

## Gold per block at Tilly's (× 2^(u-1) in universe u, like every price: UniverseRules). The raw finds are not bought:
## refine them first.
const SELL := {BlockIds.TABLE_SALT: 1, BlockIds.CRUDE_OIL: 2, BlockIds.PLASTIC: 3, BlockIds.COPPER: 5,
	BlockIds.KEROSENE: 6, BlockIds.HYDROGEN_FUEL: 4, BlockIds.TITANIUM: 6, BlockIds.HELIUM_3: 8, BlockIds.RARE_EARTHS: 10}

## Recipe id -> the real fact its making tells.
const FACTS := {
	&"pan_gold": "Panning: swirl the gravel in a pan of water. Light sand washes out; heavy gold stays at the bottom.",
	&"smelt_gold": "Gold ore is mostly quartz. Crushed and heated, the heavy gold melts and runs out of it.",
	&"smelt_copper": "Smelting: heat takes copper out of its ore. Copper melts at about 1,085 °C.",
	&"smelt_malachite": "People first smelted copper from green malachite, more than 7,000 years ago.",
	&"smelt_iron": "In a furnace, carbon from the coal takes the oxygen out of iron ore, and iron is left.",
	&"table_salt": "Rock salt is dissolved in water, cleaned, and the water is boiled away: clean salt is left.",
	&"crust_salt": "In salt pans, the sun and the wind dry salty water, and people rake up the salt.",
	&"refinery": "A refinery's tall tower sorts crude oil by how hot each part must get to boil.",
	&"kerosene": "Heated crude oil turns to gas; kerosene turns back to liquid part way up the tower. Jets and many rockets burn it.",
	&"plastic": "Some of oil's small parts are joined into long chains: that is plastic.",
	# Spec §26.5: living off the land on the Moon and Mars (sources in docs/devlog/parts/prospecting-space.md).
	&"melt_moon_ice": "Warm the icy dust and its ice melts: clean water from the Moon itself, not carried up from Earth.",
	&"melt_mars_ice": "Mars's ground ice is almost pure water ice. Melted, it fills a tank with water to drink.",
	&"melt_polar_ice": "Melted, Mars's ice caps would cover the whole planet in water about 20 metres deep.",
	&"split_fuel": "Electricity splits water into hydrogen and oxygen. Cooled to liquids, they are rocket fuel made far from Earth.",
	&"split_oxygen": "Water is hydrogen and oxygen. Split by electricity, it gives oxygen to breathe, as on the space station.",
	&"rock_oxygen": "Moon rock is almost half oxygen! Melted and split by electricity, ilmenite gives up its oxygen.",
	&"solar_oven": "Curved mirrors bring sunlight to one spot. A big solar furnace on Earth gets hotter than 3,000 °C.",
	&"moon_bricks": "Sunlight focused by mirrors melts Moon dust together into hard bricks: a shield for the domes.",
	&"mars_bricks": "Mars soil baked hot becomes hard bricks. A thick shell of them keeps out the Sun's harmful rays.",
	&"titanium": "Ilmenite is iron, titanium and oxygen. Titanium is strong and light: planes and rockets are built with it.",
	&"helium3": "Heated, the dark dust lets out the helium-3 the Sun's wind left in it. It takes tonnes of dust for a little.",
	&"rare_earths": "Rare earths make the strongest magnets, for electric motors, wind turbines and headphones.",
	&"meteorite_iron": "An iron meteorite is almost pure metal: iron with a little nickel. Melt it and cast it.",
	&"sieve_blueberries": "The blueberries are small, hard balls: shake the dust through a sieve and they stay behind.",
	&"hematite_iron": "Hematite is iron and oxygen, the iron ore mined on Earth too. Heated with hydrogen, it gives iron.",
	&"sand_iron": "A magnet pulls the dark iron grains out of the sand. Melted, they make iron.",
	&"salt_oxygen": "Perchlorate salt is full of oxygen. Heated, it gives it off: oxygen candles on spacecraft use a salt like it.",
}
## Where each recipe is made (the tests hold Recipes.LIST to it).
const STEPS := {&"pan_gold": &"hand", &"smelt_gold": &"furnace", &"smelt_copper": &"furnace",
	&"smelt_malachite": &"furnace", &"smelt_iron": &"furnace", &"table_salt": &"furnace", &"crust_salt": &"hand",
	&"refinery": &"table", &"kerosene": &"refinery", &"plastic": &"refinery",
	&"melt_moon_ice": &"melter", &"melt_mars_ice": &"melter", &"melt_polar_ice": &"melter", &"split_fuel": &"oxygen_maker",
	&"split_oxygen": &"oxygen_maker", &"rock_oxygen": &"oxygen_maker", &"solar_oven": &"table",
	&"moon_bricks": &"solar_oven", &"mars_bricks": &"solar_oven", &"titanium": &"solar_oven", &"helium3": &"solar_oven",
	&"rare_earths": &"solar_oven", &"meteorite_iron": &"solar_oven", &"sieve_blueberries": &"hand",
	&"hematite_iron": &"solar_oven", &"sand_iron": &"solar_oven", &"salt_oxygen": &"solar_oven"}


## What each kind of deposit gives (its refining starts from these).
const KIND_BLOCKS := {DepositKinds.GOLD: [BlockIds.GOLD_GRAVEL, BlockIds.GOLD_QUARTZ],
	DepositKinds.COPPER: [BlockIds.COPPER_ORE, BlockIds.MALACHITE], DepositKinds.IRON: [BlockIds.BANDED_IRON],
	DepositKinds.COAL: [BlockIds.COAL], DepositKinds.OIL: [BlockIds.CRUDE_OIL],
	DepositKinds.SALT: [BlockIds.SALT_CRUST, BlockIds.ROCK_SALT],
	DepositKinds.MOON_ICE: [BlockIds.ICY_REGOLITH], DepositKinds.ILMENITE: [BlockIds.ILMENITE, BlockIds.MARE_DUST],   # §26.5
	DepositKinds.HELIUM_3: [BlockIds.MARE_DUST], DepositKinds.KREEP: [BlockIds.KREEP_ROCK],
	DepositKinds.MOON_METEORITE: [BlockIds.IRON_METEORITE], DepositKinds.MARS_ICE: [BlockIds.GROUND_ICE],
	DepositKinds.HEMATITE: [BlockIds.BLUEBERRY_SOIL, BlockIds.HEMATITE], DepositKinds.DARK_SAND: [BlockIds.DARK_SAND],
	DepositKinds.MARS_SALT: [BlockIds.MARS_SALT], DepositKinds.MARS_METEORITE: [BlockIds.IRON_METEORITE]}
const PLACE_WORDS := {&"hand": "by hand", &"furnace": "in the Clay Oven", &"table": "at a Workbench",
	&"refinery": "at a Refinery", &"melter": "at an Ice Melter", &"oxygen_maker": "at an Oxygen Maker",
	&"solar_oven": "in a Solar Oven"}
## Spec §26.5: what the finds' water goes on to make (a find's card follows it): the fuel and the air.
const CHAIN := {BlockIds.WATER_TANK: [&"split_fuel", &"split_oxygen"]}
## Spec §26.5: what a thing that sells is for, after its price on a find's card.
const FOR_WHAT := {BlockIds.HYDROGEN_FUEL: " (rocket fuel: gold for your next rocket's tanks)"}
## Spec §26.5: things counted one by one on a find's card ("2 Water Tanks"; the rest is stuff: "2 Icy Regolith").
const COUNTED: Array[int] = [BlockIds.WATER_TANK, BlockIds.OXYGEN_TANK]
## Spec §26.5: what the things that are never sold are for.
const HELPS := {BlockIds.WATER_TANK: "water to drink", BlockIds.OXYGEN_TANK: "air to breathe"}


## How a deposit's finds are refined, one line a step ("4 Gold Quartz → 1 Gold in the Clay Oven"), and what the result
## sells for at Tilly's.
static func lines_for(kind: StringName) -> Array[String]:
	var out: Array[String] = []
	var blocks: Array = KIND_BLOCKS.get(kind, [])
	if kind == DepositKinds.OIL:
		out.append("The pump jack fills drums of Crude Oil.")
	if kind == DepositKinds.COAL:
		out.append("Coal is the fuel the Clay Oven burns to smelt ores. It sells for %d gold." % ShopRules.sell_price(BlockIds.COAL))
	var made: Array[int] = []
	for r: Dictionary in Recipes.LIST:
		if not is_refining(r.id) or r.id == &"refinery" or r.id == &"solar_oven":
			continue
		var needs: Dictionary = r.needs
		for id: int in needs:
			if blocks.has(id):
				out.append(_line(r))
				made.append(int(r.makes))
	for id in made:   # spec §26.5: the ice's water goes on to fuel and air, the fuel into a rocket's tank
		for rid: StringName in CHAIN.get(id, []):
			var r := Recipes.find(rid)
			if not out.has(_line(r)):
				out.append(_line(r))
	return out


## "2 Icy Regolith → 1 Water Tank at an Ice Melter: water to drink." (what it sells for, or how it helps).
static func _line(r: Dictionary) -> String:
	var needs: Dictionary = r.needs
	var parts: Array[String] = []
	for id: int in needs:
		var n := int(needs[id])
		parts.append("%d %s%s" % [n, BlockIds.display_name(id), "s" if n > 1 and COUNTED.has(id) else ""])
	var makes := int(r.makes)
	var sells := ShopRules.sell_price(makes)
	var why := (": %d gold each at Tilly's%s" % [sells, FOR_WHAT.get(makes, "")]) if sells > 0 else (
		(": " + helps(makes)) if helps(makes) != "" else "")
	return "%s → %d %s %s%s." % [" + ".join(parts), int(r.count), BlockIds.display_name(makes), PLACE_WORDS.get(r.at, ""),
		why]


## Spec §26.5: what a thing that is never sold is for ("" for anything else): water, air, and the colony's own blocks
## (ColonyRules.STOCK: bricks to build your own dome).
static func helps(id: int) -> String:
	if HELPS.has(id):
		return str(HELPS[id])
	if ColonyRules.STOCK.has(id):
		return "the colony's blocks: build your own dome with them"
	return ""



## Metals, fuels and salt are stuff, counted, never "a": "You made 1 Kerosene!".
const STUFF: Array[int] = [BlockIds.GOLD, BlockIds.IRON, BlockIds.COPPER, BlockIds.TABLE_SALT, BlockIds.CRUDE_OIL,
	BlockIds.KEROSENE, BlockIds.PLASTIC, BlockIds.HYDROGEN_FUEL, BlockIds.TITANIUM, BlockIds.RARE_EARTHS,
	BlockIds.HELIUM_3]


static func is_stuff(id: int) -> bool:
	return STUFF.has(id)


## The fact a recipe's making tells ("" for any other recipe).
static func fact(recipe_id: StringName) -> String:
	return str(FACTS.get(recipe_id, ""))


static func is_refining(recipe_id: StringName) -> bool:
	return FACTS.has(recipe_id)


## Gold one block of `id` sells for in universe 1 (0: Tilly doesn't buy it).
static func sell_price(id: int) -> int:
	return int(SELL.get(id, 0))


## Gold a refining recipe's result sells for, less what its ingredients would (0 when they are not sold): refining
## always pays (tests).
static func value_added(recipe: Dictionary) -> int:
	var out := sell_price(int(recipe.makes)) * int(recipe.count)
	if out <= 0:
		return 0
	var needs: Dictionary = recipe.needs
	var cost := 0
	for id: int in needs:
		cost += maxi(sell_price(id), ShopRules.SELL_PRICES.get(id, 0)) * int(needs[id])
	return out - cost
