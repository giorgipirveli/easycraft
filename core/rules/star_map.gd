class_name StarMap
extends RefCounted
## The Star Map (owner #72, #74, spec §21b.1): what the sky shows when a flyer crosses the space line. Our solar system
## in its real order out from the Sun, each planet with its moons; far away the game's own planets and every universe
## as its own planet (and the next ones, coming). Every body has three real facts for its card (read aloud) and, from
## where the child is, one state: LAND on a built space world, HOME, HERE, a universe's PORTAL, LOCKED, COMING_SOON,
## NO_GROUND (a star or a gas giant), LOOK (the moons still to build) or MISSION (spec §21d.5: a real planet built but
## not reached yet: a mission from the Launch Site first). Owner #78 (spec §24): Earth lands at Earth's own world 41,
## Wonders of the World (its card's button says so: action_words_for). Sizes are the map's radii in
## pixels: bigger means bigger, not to scale (Jupiter would not fit next to Mercury). Pure data; SpacePanel draws it.

const LAND := &"land"
const HOME := &"home"
const HERE := &"here"
const PORTAL := &"portal"
const LOCKED := &"locked"
const COMING_SOON := &"coming_soon"
const NO_GROUND := &"no_ground"
const LOOK := &"look"
const MISSION := &"mission"   # spec §21d.5

const MAX_FACT := 110           # letters: a fact is one line or two on the card

const _WORDS := {
	LAND: "LAND",
	HOME: "HOME",
	HERE: "You are here!",
	PORTAL: "Open! Travel there through a universe portal.",
	LOCKED: "Beat the boss of the universe before it to open it.",
	COMING_SOON: "Coming soon: explorers are building it!",
	NO_GROUND: "No ground to land on here.",
	LOOK: "Look and learn: you can't land here yet.",
	MISSION: "Mission needed: build a rocket at the Launch Site",
}

## The solar system, then the far worlds. kind: star, planet, dwarf, moon, game (our own planets) or universe;
## world: the world a LAND or PORTAL goes to (0: none); parent: a moon's planet; color, color2: its look (color2 a band
## or a patch); ring: Saturn's (and Uranus's faint) rings.
const SOLAR: Array[Dictionary] = [
	{"id": &"sun", "name": "The Sun", "kind": "star", "world": 0, "size": 70.0, "color": Color("ffd23a"),
		"color2": Color("ff8a1c"), "facts": [
		"The Sun is a star: a giant ball of glowing hot gas.",
		"About 1.3 million Earths would fit inside the Sun.",
		"Its light takes about 8 minutes to reach Earth.",
	]},
	{"id": &"mercury", "name": "Mercury", "kind": "planet", "world": 23, "size": 9.0, "color": Color("9a948c"),
		"color2": Color("6f6a64"), "facts": [
		"Mercury is the smallest planet and the closest to the Sun.",
		"From sunrise to sunrise takes 176 Earth days there.",
		"Days reach 430 °C and nights fall to −180 °C.",
	]},
	{"id": &"venus", "name": "Venus", "kind": "planet", "world": 24, "size": 15.0, "color": Color("e9c46a"),
		"color2": Color("f4e0a8"), "facts": [
		"Venus is the hottest planet: about 465 °C, hot enough to melt lead.",
		"Thick yellow clouds of acid hide its ground.",
		"It spins backwards: there the Sun rises in the west.",
	]},
	{"id": &"earth", "name": "Earth", "kind": "planet", "world": EarthRules.WONDERS, "size": 16.0, "color": Color("3f8fe0"),
		"color2": Color("5cb85c"), "land": "Wonders of the World", "facts": [   # owner #78: LAND at the wonders
		"Earth is our home: the only planet we know with life.",
		"Oceans cover more than two thirds of it.",
		"It goes round the Sun once every 365 days: a year.",
	]},
	{"id": &"moon", "name": "The Moon", "kind": "moon", "parent": &"earth", "world": 16, "size": 7.0,
		"color": Color("c9ccd6"), "color2": Color("8e929e"), "facts": [
		"The Moon goes round Earth about once every 27 days.",
		"On the real Moon you would jump 6 times higher than at home.",
		"Twelve astronauts walked on the Moon between 1969 and 1972.",
	]},
	{"id": &"mars", "name": "Mars", "kind": "planet", "world": 19, "size": 11.0, "color": Color("c1440e"),
		"color2": Color("e27b58"), "facts": [
		"Mars is red because its dust has rust in it.",
		"Its volcano Olympus Mons is about 22 km high: 2.5 times Mount Everest.",
		"A day on Mars lasts about 24 hours and 40 minutes.",
	]},
	{"id": &"jupiter", "name": "Jupiter", "kind": "planet", "world": 0, "size": 40.0, "color": Color("d8a86a"),
		"color2": Color("b5653d"), "facts": [
		"Jupiter is the biggest planet: over 1,300 Earths would fit inside.",
		"Its Great Red Spot is a storm bigger than Earth.",
		"It is made of gas and has no ground: land on its moons!",
	]},
	{"id": &"io", "name": "Io", "kind": "moon", "parent": &"jupiter", "world": 21, "size": 7.0,
		"color": Color("e8d04a"), "color2": Color("d9772b"), "facts": [
		"Io has about 400 volcanoes that erupt: the most of any place we know.",
		"Its yellow and orange colours come from sulphur.",
		"Jupiter's pull squeezes Io and keeps its inside hot.",
	]},
	{"id": &"europa", "name": "Europa", "kind": "moon", "parent": &"jupiter", "world": 20, "size": 6.5,
		"color": Color("eae3d2"), "color2": Color("a8674a"), "facts": [
		"Europa is covered in a shell of ice with long reddish cracks.",
		"Under the ice is an ocean with more water than all of Earth's seas.",
		"Scientists want to find out if anything lives in that ocean.",
	]},
	{"id": &"ganymede", "name": "Ganymede", "kind": "moon", "parent": &"jupiter", "world": 28, "size": 9.0,
		"color": Color("a39a8c"), "color2": Color("6f6457"), "facts": [
		"Ganymede is the biggest moon of all: bigger than Mercury.",
		"It is the only moon we know with its own magnetic field.",
		"It is made of rock and ice, with a salty ocean deep inside.",
	]},
	{"id": &"callisto", "name": "Callisto", "kind": "moon", "parent": &"jupiter", "world": 0, "size": 8.5,
		"color": Color("6e6254"), "color2": Color("b9ad98"), "facts": [
		"Callisto is covered in craters from edge to edge.",
		"Its ground has hardly changed for about 4 billion years.",
		"It goes round Jupiter once every 17 days.",
	]},
	{"id": &"saturn", "name": "Saturn", "kind": "planet", "world": 25, "size": 34.0, "ring": true,
		"land": "Saturn's rings",   # cosmos (spec §21b.2): no ground on Saturn: LAND in its rings
		"color": Color("e3c98f"), "color2": Color("c9a55c"), "facts": [
		"Saturn's rings are made of ice and rock, from dust to chunks as big as houses.",
		"Saturn is so light it would float in a giant bath of water.",
		"A year on Saturn lasts about 29 Earth years.",
	]},
	{"id": &"titan", "name": "Titan", "kind": "moon", "parent": &"saturn", "world": 22, "size": 8.5,
		"color": Color("e0a44a"), "color2": Color("b8772a"), "facts": [
		"Titan has lakes and rivers, but of liquid methane, not water.",
		"It is the only moon with thick air: thicker than Earth's.",
		"Its air is so thick and its pull so weak that people could fly with wings.",
	]},
	{"id": &"uranus", "name": "Uranus", "kind": "planet", "world": 0, "size": 22.0, "ring": true,
		"color": Color("9fe3e6"), "color2": Color("7fcfd6"), "facts": [
		"Uranus spins on its side, like a ball rolling round the Sun.",
		"It is an ice giant, blue-green from methane gas.",
		"A year on Uranus lasts 84 Earth years.",
	]},
	{"id": &"neptune", "name": "Neptune", "kind": "planet", "world": 0, "size": 21.0, "color": Color("3f63e0"),
		"color2": Color("2a44a8"), "facts": [
		"Neptune has the fastest winds: over 2,000 km an hour.",
		"A year on Neptune lasts 165 Earth years.",
		"It was found with maths before anyone saw it in a telescope.",
	]},
	{"id": &"triton", "name": "Triton", "kind": "moon", "parent": &"neptune", "world": 27, "size": 6.0,
		"color": Color("e7c7c1"), "color2": Color("8a7773"), "facts": [
		"Triton goes round Neptune backwards: the only big moon that does.",
		"Its geysers blow nitrogen gas about 8 km high.",
		"It is one of the coldest places we know: about −235 °C.",
	]},
	{"id": &"pluto", "name": "Pluto", "kind": "dwarf", "world": 26, "size": 6.0, "color": Color("d9c3a5"),
		"color2": Color("f3ead9"), "facts": [
		"Pluto is a dwarf planet, smaller than our Moon.",
		"It has a giant heart-shaped plain of frozen nitrogen.",
		"A year on Pluto lasts 248 Earth years.",
	]},
]

## Far away: the game's own planets (space worlds) and the universes (the ladder, then the ones still to come, §5.1).
const FAR: Array[Dictionary] = [
	{"id": &"boing", "name": "Planet Boing", "kind": "game", "world": 17, "size": 16.0, "color": Color("9be34a"),
		"color2": Color("7a4fd6"), "facts": [
		"Our own planet: boing moss and spring caps bounce you high.",
		"Its pull is a bit more than half of home's: big springy jumps.",
		"Climb the Boing Tower to find its chest.",
	]},
	{"id": &"rainbow", "name": "Rainbow Planet", "kind": "game", "world": 18, "size": 16.0, "color": Color("f7a6c8"),
		"color2": Color("8fd3ff"), "facts": [
		"Our own planet: its hills are striped in every colour.",
		"Two small moons shine in its lilac sky.",
		"A giant Rainbow Arch hides a chest on its top.",
	]},
	{"id": &"green_meadows", "name": "", "kind": "universe", "world": 1, "size": 18.0, "color": Color("5cb85c"),
		"color2": Color("3f8fe0"), "facts": [
		"Where every adventure starts: meadows, forests, rivers and caves.",
		"Farms, mouse villages, bees and butterflies.",
		"Beat the Stone Golem to open the portal to the next universe.",
	]},
	{"id": &"sandstorm_desert", "name": "", "kind": "universe", "world": 2, "size": 18.0, "color": Color("e9c46a"),
		"color2": Color("d98b3a"), "facts": [
		"Golden dunes, cactus and sandstorms.",
		"Watch out for the traps in its old temples.",
		"Camels, lizards and fennec foxes live in the heat.",
	]},
	{"id": &"frostpeak", "name": "", "kind": "universe", "world": 3, "size": 18.0, "color": Color("e8f4ff"),
		"color2": Color("8fc4e8"), "facts": [
		"Snowy peaks, frozen lakes and slippery ice.",
		"Penguins, a gentle polar bear, arctic foxes and seals.",
		"Snowstorms blow over the mountains.",
	]},
	{"id": &"candy_kingdom", "name": "", "kind": "universe", "world": 4, "size": 18.0, "color": Color("ff9ed2"),
		"color2": Color("8fe3c8"), "facts": [
		"Hills of candy, chocolate rivers and gumdrops that bounce.",
		"Sprinkles fall from the sky at night.",
		"A giant cake is its boss: sweet but tough.",
	]},
	{"id": &"dragon_realm", "name": "", "kind": "universe", "world": 5, "size": 18.0, "color": Color("7a3a8a"),
		"color2": Color("e05a3a"), "facts": [
		"Floating islands over a sea of clouds.",
		"Find a dragon egg and raise your own baby dragon.",
		"The Sky Dragon, the mightiest boss of all, waits here.",
	]},
	{"id": &"universe_6", "name": "Glow Caves", "kind": "universe", "world": 6, "size": 18.0, "color": Color("2a2f6a"),
		"color2": Color("7df9ff"), "facts": [
		"Caves glowing blue: real glow-worms make cold light like this.",
		"Rainwater carved them: a weak acid dissolves limestone.",
		"Blind cave fish, crystal halls and the Spore Mother wait here.",
	]},
	{"id": &"universe_7", "name": "Neon City", "kind": "universe", "world": 7, "size": 18.0, "color": Color("1f1f3a"),
		"color2": Color("ff3df0"), "facts": [
		"A city of bright lights and friendly robots.",
		"Towers, rails and signs of every colour.",
		"Explorers are building it now.",
	]},
	{"id": &"universe_8", "name": "Lava Core", "kind": "universe", "world": 8, "size": 18.0, "color": Color("5a1a0a"),
		"color2": Color("ff7a1a"), "facts": [
		"The hot heart of a world: rivers of lava.",
		"Fire imps dance on black rock.",
		"Explorers are building it now.",
	]},
]


## Every body: the solar system in its order, then the far worlds (a universe's name from its descriptor).
static func bodies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in SOLAR:
		out.append(b)
	for b in FAR:
		if str(b.kind) == "universe" and int(b.world) <= UniverseRegistry.size():
			var named: Dictionary = b.duplicate()
			named.name = UniverseRegistry.display_name(int(b.world))
			out.append(named)
		else:
			out.append(b)
	return out


## The body a space world is (&"" for none).
static func body_for_world(u: int) -> StringName:
	for b in SOLAR + FAR:
		if int(b.world) == u and str(b.kind) != "universe":
			return b.id
	return &""


## Owner #91 ("animation, movements, cyrcle as it is in reality"): each planet's real year in days (sidereal) and its
## mean longitude on 1 January 2000 at noon (J2000, degrees): where it is on any day, on a circle (good to a few degrees).
## Source: NASA's planetary fact sheets and the JPL approximate positions of the planets.
const ORBITS := {&"mercury": [87.969, 252.25084], &"venus": [224.701, 181.97973], &"earth": [365.256, 100.46435],
	&"mars": [686.980, 355.45332], &"jupiter": [4332.589, 34.40438], &"saturn": [10759.22, 49.94432],
	&"uranus": [30685.4, 313.23218], &"neptune": [60189.0, 304.88003], &"pluto": [90560.0, 238.92881]}
const J2000_UNIX := 946728000.0   # 2000-01-01 12:00 UTC


## A planet's year in days (0.0 for anything that does not go round the Sun itself: a moon, a star, a universe).
static func year_days(id: StringName) -> float:
	return float(ORBITS[id][0]) if ORBITS.has(id) else 0.0


## Where a planet is `days` after 1 January 2000 (radians, counter-clockwise seen from above the Sun's north).
static func longitude(id: StringName, days: float) -> float:
	if not ORBITS.has(id):
		return 0.0
	var o: Array = ORBITS[id]
	return fposmod(deg_to_rad(float(o[1])) + TAU * days / float(o[0]), TAU)


## Days since 1 January 2000 at noon, for a unix time (the device's clock).
static func days_since_2000(unix: float) -> float:
	return (unix - J2000_UNIX) / 86400.0


static func body(id: StringName) -> Dictionary:
	for b in bodies():
		if b.id == id:
			return b
	return {}


## Each body's state from world `here` (the trip started from `home`), with `available` space worlds built and
## universes up to `unlocked` opened. `route` (spec §21d.5, MissionRules.route): the worlds this child has reached; a
## built world with a mission not on it says MISSION. null: no missions (every built world lands, as before them).
static func states(here: int, home: int, available: Array[int], unlocked: int, route: Variant = null) -> Dictionary:
	var out := {}
	var home_world := SpaceRules.home_for(here, home) if SpaceRules.is_away(here) else here
	for b in bodies():
		var u := int(b.world)
		var kind := str(b.kind)
		var state := LOOK
		if u > 0 and u == here:
			state = HERE
		elif kind == "universe":
			if u > UniverseRegistry.size():
				state = COMING_SOON
			elif u == home_world:
				state = HOME
			elif u <= unlocked:
				state = PORTAL
			else:
				state = LOCKED
		elif u > 0:
			state = LAND if available.has(u) else COMING_SOON
			if state == LAND and route is Array and MissionRules.needs_mission(u, _worlds(route)):
				state = MISSION
		elif kind == "star" or b.id in [&"jupiter", &"uranus", &"neptune"]:
			state = NO_GROUND
		out[b.id] = state
	return out


static func action_words(state: StringName) -> String:
	return _WORDS.get(state, "")


## The card's button for body `id` in `state`: a body with a place of its own to land at says it first (owner #78: the
## Earth card's "Wonders of the World: LAND"); else action_words.
static func action_words_for(id: StringName, state: StringName) -> String:
	var place := str(body(id).get("land", ""))
	if state == LAND and place != "":
		return "%s: %s" % [place, _WORDS[LAND]]
	return action_words(state)


static func _worlds(v: Array) -> Array[int]:
	var out: Array[int] = []
	for u: Variant in v:
		if typeof(u) == TYPE_INT:
			out.append(u)
	return out
