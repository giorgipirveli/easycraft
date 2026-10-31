class_name InventionLine
extends RefCounted
## Owner #78 (spec §21e): "if you want to fly you have to invent acordingly". The line of flight in the order people
## invented it, one table: the kite (China, over 2,000 years ago), the hot-air balloon (1783), the glider (the 1890s),
## the plane with an engine (1903), the jet (1939) and the rocket (1957 the first satellite, 1961 the first person in
## space, 1969 people on the Moon). Each entry: its real story (people of history only, never living people: `people`
## is [name, born, died]), its science in one card, what it opens in the game, its "try it" moment, what it is made of
## at a Workbench (`needs`: [material, how many, why]), a little gold, and the School unit on its science (mastered, it
## makes the invention free: InventionRules). The facts and their sources: docs/devlog/parts/invent-flight.md. Pure.

const KITE := &"kite"
const BALLOON := &"balloon"
const GLIDER := &"glider"
const PLANE := &"plane"
const JET := &"jet"
const ROCKET := &"rocket"
const ORDER: Array[StringName] = [KITE, BALLOON, GLIDER, PLANE, JET, ROCKET]

## What a need is made of: any of these things in the bag, taken in this order (a sheep's wool is the colour blocks,
## AnimalRules.WOOL; the wild meadows' windmills and ships have sail cloth). Kerosene comes from the Refinery (spec §26)
## or, owner #98, from Tilly in the first universe (no other universe is needed for the rocket).
const MATERIALS := {
	&"sticks": {"name": "Sticks", "ids": [ItemIds.STICK]},
	&"planks": {"name": "Planks", "ids": [BlockIds.PLANKS]},
	&"cloth": {"name": "Cloth", "ids": [BlockIds.SAIL, BlockIds.RED, BlockIds.YELLOW, BlockIds.GREEN, BlockIds.BLUE,
		BlockIds.PURPLE], "hint": "sail cloth, or a sheep's wool"},
	&"iron": {"name": "Iron", "ids": [BlockIds.IRON]},
	&"coal": {"name": "Coal", "ids": [BlockIds.COAL]},
	&"glass": {"name": "Glass", "ids": [BlockIds.GLASS]},
	&"kerosene": {"name": "Kerosene", "ids": [BlockIds.KEROSENE],
		"hint": "bought from Tilly, or refined from crude oil at a Refinery"},   # owner #98: no other universe needed
}

const LINE: Array[Dictionary] = [
	{"id": KITE, "name": "The Kite", "year": -450, "when": "More than 2,000 years ago", "where": "China",
		"people": [["Mozi", -470, -391], ["Lu Ban", -507, -444]],
		"story": "People in China flew the first kites more than 2,000 years ago, made of silk and bamboo. Old stories "
			+ "say the thinker Mozi built a wooden bird that flew, and the builder Lu Ban made kites of light bamboo. "
			+ "Kites sent signals, and made people wonder: could we fly too?",
		"science": "Wind and a string. The wind pushes on the kite's tilted face, and the string pulls it back. Tilted, "
			+ "the push turns upwards: the kite climbs. No wind, no push: the kite comes down.",
		"opens": "On a windy hill, your kite pulls you up for a moment: FLY with the kite on high ground.",
		"try": "Stand with your back to the wind (the arrow shows where it blows) and keep your kite flying for 5 seconds.",
		"try_done": "Your kite flies! The wind pushes it, the string holds it, and the push lifts it up.",
		"safety": "Fly real kites with a grown-up, far away from power lines and roads.",
		"made_of": "Sticks for the frame (bamboo, in old China) and cloth for the sail; wool spun into the string.",
		"needs": [[&"sticks", 4, "the frame (the first kites had bamboo frames)"],
			[&"cloth", 3, "the sail that catches the wind, and wool spun into the string"]],
		"gold": 10, "unit": "g3.science.forces_friction", "picture": &"kite"},
	{"id": BALLOON, "name": "The Hot-Air Balloon", "year": 1783, "when": "1783", "where": "France",
		"people": [["Joseph Montgolfier", 1740, 1810], ["Étienne Montgolfier", 1745, 1799],
			["Pilâtre de Rozier", 1754, 1785]],
		"story": "In 1783 the brothers Joseph and Étienne Montgolfier filled a huge cloth bag with hot air from a fire. "
			+ "First a sheep, a duck and a rooster flew in its basket for 8 minutes. Two months later Pilâtre de Rozier "
			+ "and the Marquis d'Arlandes were the first people ever to fly: 25 minutes over Paris.",
		"science": "Hot air is lighter than cold air. Heat makes air spread out, so a balloon full of hot air weighs less "
			+ "than the cold air around it, and it floats up. Let the air cool, and the balloon sinks.",
		"opens": "Slow flying: hold UP to heat the air and rise, let go to sink slowly. The wind carries you. The burner's "
			+ "gas costs nothing.",
		"try": "Heat the air: hold UP and rise 15 blocks.",
		"try_done": "Up you go! Hot air is lighter than the cold air around it, so the balloon floats.",
		"made_of": "Cloth for the big bag, a basket of sticks, an iron burner and coal to heat the air.",
		"needs": [[&"cloth", 8, "the big bag (the Montgolfiers' was cloth lined with paper)"],
			[&"sticks", 4, "the basket you ride in"], [&"iron", 1, "the burner"],
			[&"coal", 2, "fuel to heat the air (the Montgolfiers burned wool and hay)"]],
		"gold": 25, "unit": "g5.science.particles", "picture": &"balloon"},
	{"id": GLIDER, "name": "The Glider", "year": 1891, "when": "The 1890s", "where": "Germany",
		"people": [["Otto Lilienthal", 1848, 1896]],
		"story": "Otto Lilienthal watched storks fly, then built gliders of willow wood and cotton cloth. From 1891 he "
			+ "made about 2,000 flights, jumping from a hill he built himself. He even sold copies of his glider: the "
			+ "first aircraft ever made to sell.",
		"science": "Wings lift. A wing is curved and tilted: moving through the air, it pushes air down, and the air "
			+ "pushes the wing up. The higher you start, the farther you glide.",
		"opens": "The glide, in every Survivor world and never lost: in the air, jump again or press GLIDE.",
		"try": "Glide 25 blocks in one glide. Start high: from 10 blocks up you glide about 25 blocks forward.",
		"try_done": "What a glide! Your wings pushed the air down, and the air held you up.",
		"made_of": "Sticks for the frame (willow wood) and cloth for the wings (cotton).",
		"needs": [[&"sticks", 6, "the frame (Lilienthal used willow wood)"], [&"cloth", 4, "the wings (cotton cloth)"]],
		"gold": 40, "unit": "g5.science.forces_machines", "picture": &"glider"},
	{"id": PLANE, "name": "The Plane", "year": 1903, "when": "1903", "where": "the USA",
		"people": [["Wilbur Wright", 1867, 1912], ["Orville Wright", 1871, 1948]],
		"story": "On 17 December 1903 the brothers Wilbur and Orville Wright flew the first plane with an engine, near "
			+ "Kitty Hawk. Orville flew first: 12 seconds and 37 metres. Their little engine turned two propellers, and "
			+ "the wings were wood and cloth.",
		"science": "The engine turns the propellers, which push air backwards, so the plane goes forwards. Moving fast, "
			+ "the wings lift it. Too slow, and the wings stop lifting: a plane must keep moving to stay up.",
		"opens": "Fast flying: push forward to speed up, UP and DOWN to climb and dive. The engine burns fuel: 10 gold "
			+ "a minute.",
		"try": "Fly your plane for 12 seconds without landing, like the first flight in 1903.",
		"try_done": "12 seconds: as long as the very first plane flight! Today planes fly for many hours.",
		"made_of": "Planks for the frame (spruce wood), cloth for the wings and iron for the engine.",
		"needs": [[&"planks", 8, "the frame (the Wrights used spruce wood)"], [&"cloth", 6, "the wings (cotton cloth)"],
			[&"iron", 4, "the engine and the propellers' chains"]],
		"gold": 60, "unit": "g4.science.energy_speed", "picture": &"plane"},
	{"id": JET, "name": "The Jet", "year": 1939, "when": "1939", "where": "Germany and Britain",
		"people": [["Frank Whittle", 1907, 1996], ["Hans von Ohain", 1911, 1998]],
		"story": "Frank Whittle in Britain and Hans von Ohain in Germany each invented a jet engine. In 1939 a plane "
			+ "with von Ohain's engine was the first to fly by jet, for 6 minutes. Today jets carry people all round "
			+ "the world.",
		"science": "Pushing air out fast pushes you forward. A jet engine sucks air in at the front, squeezes it, burns "
			+ "fuel in it and blows it out of the back very fast: every push has an equal push back. Jets burn kerosene.",
		"opens": "The fastest flying. A jet burns lots of fuel: 20 gold a minute.",
		"try": "Fly your jet 300 blocks in one flight.",
		"try_done": "Whoosh! Air rushed out of the back, and you rushed forward. Real jets fly at 900 km an hour.",
		"made_of": "Iron for the engine and the body, glass for the canopy, kerosene for the fuel.",
		"needs": [[&"iron", 10, "the engine and the body"], [&"glass", 2, "the canopy you look out of"],
			[&"kerosene", 2, "jet fuel is kerosene"]],
		"gold": 100, "unit": "g8.science.forces_motion", "picture": &"jet"},
	{"id": ROCKET, "name": "The Rocket", "year": 1957, "when": "1957 to 1969", "where": "the USSR and the USA",
		"people": [["Konstantin Tsiolkovsky", 1857, 1935], ["Robert Goddard", 1882, 1945], ["Yuri Gagarin", 1934, 1968],
			["Neil Armstrong", 1930, 2012]],
		"story": "Konstantin Tsiolkovsky worked out how rockets could reach space, and Robert Goddard flew the first "
			+ "rocket with liquid fuel in 1926. In 1957 the first satellite went round the Earth. In 1961 Yuri Gagarin "
			+ "was the first person in space, and in 1969 Neil Armstrong was the first person to step onto the Moon.",
		"science": "A rocket burns its fuel into hot gas and pushes it out of the bottom very fast, and the gas pushes the "
			+ "rocket up. It carries its own oxygen, so it works in space, where there is no air.",
		"opens": "The Launch Site's missions: build a rocket on the pad and fly it to the Moon and the planets.",
		"try": "Launch a bottle rocket: pump air in, then LAUNCH. Make it fly 30 metres high.",
		"try_done": "The air pushed the water down, and the water pushed the bottle up: every rocket flies like that.",
		"made_of": "Iron for the tanks and the engine's bell, kerosene for the fuel (the Moon rocket's first stage burned "
			+ "kerosene).",
		"needs": [[&"iron", 8, "the tanks and the engine's bell"],
			[&"kerosene", 2, "fuel (the Moon rocket's first stage burned kerosene)"]],
		"gold": 150, "unit": "g4.science.rockets_explorer", "picture": &"rocket"},
]


static func entry(id: StringName) -> Dictionary:
	for e in LINE:
		if e.id == id:
			return e
	return {}


static func has(id: StringName) -> bool:
	return ORDER.has(id)


static func index(id: StringName) -> int:
	return ORDER.find(id)


## The invention before `id` in the line (&"" for the first or an unknown one).
static func previous(id: StringName) -> StringName:
	var i := index(id)
	return ORDER[i - 1] if i > 0 else &""


## {material: how many} for one invention.
static func needs_of(id: StringName) -> Dictionary:
	var out := {}
	for n: Array in entry(id).get("needs", []):
		out[n[0]] = int(n[1])
	return out


static func material_name(m: StringName) -> String:
	return str((MATERIALS.get(m, {}) as Dictionary).get("name", ""))


## "4 Sticks, 3 Cloth".
static func needs_words(id: StringName) -> String:
	var parts: Array[String] = []
	for n: Array in entry(id).get("needs", []):
		parts.append("%d %s" % [int(n[1]), material_name(n[0])])
	return ", ".join(parts)
