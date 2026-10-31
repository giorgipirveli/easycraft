class_name LoadingHints
extends RefCounted
## The hints a child sees while a world loads (M5 Task 2, spec §15.2): one short line and one picture at a time
## (LoadingCard shows them over the universe's scene, 5 s each, read aloud with "Read to me"). Each hint may be for
## some modes only (`modes`) or one universe only (`universe`); pick() never shows the same one twice in a row.
## Every line says something the game really does (checked against the systems named beside it).

const HINTS: Array[Dictionary] = [
	{"text": "Tap a build with the Magic Wand to wake it!", "picture": ItemIds.WAND},          # Buddy
	{"text": "Stamps build a whole house in one tap.", "picture": ItemIds.STAMP_HOUSE},          # stamps
	{"text": "Lanterns keep monsters away at night.", "picture": BlockIds.LANTERN,               # MonsterRules.LIGHT_CLEAR
		"modes": [ModeRules.SURVIVOR]},
	{"text": "Hide in a bush or a barrel. Monsters walk past!", "picture": BlockIds.BUSH,         # StealthDirector
		"modes": [ModeRules.SURVIVOR]},
	{"text": "Sleep in your bed and the night goes by.", "picture": BlockIds.BED,                # SleepDirector
		"modes": [ModeRules.SURVIVOR]},
	{"text": "Monsters drop gold. Tilly sells great things for it!", "picture": &"coin",         # MonsterDirector, Tilly
		"modes": [ModeRules.SURVIVOR]},
	{"text": "Build walls round you before night comes.", "picture": BlockIds.PLANKS,            # night spawns
		"modes": [ModeRules.SURVIVOR]},
	{"text": "Give a dog a biscuit to make a friend.", "picture": ItemIds.TREAT_BISCUIT,   # PetRules
		"modes": [ModeRules.SANDBOX, ModeRules.SURVIVOR]},
	{"text": "Every block is yours here. Build anything!", "picture": BlockIds.BRICK,            # Sandbox's palette
		"modes": [ModeRules.SANDBOX]},
	{"text": "The longer you stay up, the more gold you get.", "picture": &"coin",               # ArenaRules
		"modes": [ModeRules.WAVE]},
	{"text": "Beat wave ten's boss to open a new universe!", "picture": BlockIds.TROPHY,      # ArenaRules
		"modes": [ModeRules.WAVE]},
	{"text": "In a sandstorm, monsters see you less. Sneak past!", "picture": BlockIds.SAND,       # SandstormRules
		"universe": 2},
	{"text": "Ice is slippery. Walk slowly on it!", "picture": BlockIds.ICE,                     # FrostRules.grip
		"universe": 3},
	{"text": "Candy sneakers hide in the dark. Bring a candy lamp!", "picture": BlockIds.CANDY_LAMP,   # sneakers
		"universe": 4},
	{"text": "Fell off an island? The wind carries you back.", "picture": BlockIds.CLOUD,          # DragonRules
		"universe": 5},
	{"text": "Crawlers are blind: tiptoe past them. Puffs see light!", "picture": BlockIds.SPORE_LAMP,   # GLOW_KINDS
		"universe": 6},
	{"text": "Lost? Climb a sunbeam's ramp up to the sky.", "picture": BlockIds.GLOW_MOSS,   # GlowShape's shafts
		"universe": 6},
	{"text": "Dig down to find caves, ores and treasure.", "picture": BlockIds.GOLD,             # caves, secrets
		"modes": [ModeRules.SANDBOX, ModeRules.SURVIVOR]},
	# owner #55: space
	{"text": "On the Moon you jump high and float down!", "picture": BlockIds.MOON_DUST,          # UniverseRegistry.gravity
		"universe": 16},
	{"text": "Find the Moon Base near the landing pad!", "picture": BlockIds.PORTHOLE,            # SpaceSecretRules
		"universe": 16},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 16},
	{"text": "Jump on the moss and jelly. Boing!", "picture": BlockIds.JELLY,                    # CandyRules.is_gumdrop
		"universe": 17},
	{"text": "Bounce up the Boing Tower to its chest!", "picture": BlockIds.SPRING_CAP,          # SpaceSecretRules
		"universe": 17},
	{"text": "Climb the steps up the Rainbow Arch!", "picture": BlockIds.RAINBOW_RED,             # SpaceSecretRules
		"universe": 18},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 18},
	# cosmos: Mars (spec §21b.2)
	{"text": "On Mars you jump more than twice as high!", "picture": BlockIds.MARS_DUST,       # its gravity, 0.38
		"universe": 19},
	{"text": "Find the rover near the landing pad!", "picture": BlockIds.ROVER_WHEEL,          # SpaceSecretRules
		"universe": 19},
	{"text": "The giant volcano and ice caps are on your map.", "picture": BlockIds.POLAR_ICE,   # SpaceSights
		"universe": 19},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 19},
	# cosmos: Europa (spec §21b.2)
	{"text": "On Europa you jump over 7 times as high!", "picture": BlockIds.EUROPA_ICE,        # its gravity, 0.13
		"universe": 20},
	{"text": "Find the Ice Lander near the landing pad!", "picture": BlockIds.PROBE_PANEL,      # SpaceSecretRules
		"universe": 20},
	{"text": "Step into a water plume and fly up high!", "picture": BlockIds.GEYSER_VENT,        # PadRules, SpaceGeysers
		"universe": 20},
	{"text": "Jupiter never moves in Europa's sky!", "picture": BlockIds.BAND_ICE,              # tidally locked (NASA)
		"universe": 20},
	{"text": "A salty ocean hides under the ice. Find the well!", "picture": BlockIds.SALT,    # SpaceSights: the ocean
		"universe": 20},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 20},
	# cosmos: Io (spec §21b.2)
	{"text": "On Io you jump over 5 times as high!", "picture": BlockIds.SULPHUR,               # its gravity, 0.18
		"universe": 21},
	{"text": "Find the Volcano Lander near the landing pad!", "picture": BlockIds.HEAT_TILE,    # SpaceSecretRules
		"universe": 21},
	{"text": "Step on a volcano's vent and fly up high!", "picture": BlockIds.VOLCANO_VENT,     # PadRules, SpaceGeysers
		"universe": 21},
	{"text": "Hot lava bounces you out. The dark crust is safe!", "picture": BlockIds.HOT_LAVA,   # PadRules.LAVA_SPEED
		"universe": 21},
	{"text": "Io has about 400 volcanoes: more than anywhere else!", "picture": BlockIds.LAVA_CRUST,   # NASA/JPL
		"universe": 21},
	{"text": "Jupiter never moves in Io's sky!", "picture": BlockIds.SULPHUR_FROST,          # tidally locked
		"universe": 21},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 21},
	# cosmos: Titan (spec §21b.2)
	{"text": "On Titan you jump about 7 times as high!", "picture": BlockIds.TITAN_SOIL,       # its gravity, 0.14
		"universe": 22},
	{"text": "Find the Landing Probe near the landing pad!", "picture": BlockIds.PROBE_SHELL,  # SpaceSecretRules
		"universe": 22},
	{"text": "In methane lakes, JUMP to leap out like a dolphin!", "picture": BlockIds.WET_SHORE,   # TitanRules
		"universe": 22},
	{"text": "Titan's thick air is mostly nitrogen, like Earth's!", "picture": BlockIds.ICE_PEBBLES,   # NASA
		"universe": 22},
	{"text": "Titan's air presses about 1.5 times as hard as Earth's.", "picture": BlockIds.DUNE_SAND,   # 1.45 bar
		"universe": 22},
	{"text": "Titan has rain, rivers and seas, but of methane!", "picture": BlockIds.SHORE_CRYSTAL,   # NASA
		"universe": 22},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 22},
	# cosmos: Mercury (spec §21b.2)
	{"text": "On Mercury you jump more than twice as high!", "picture": BlockIds.MERCURY_DUST,   # its gravity, 0.38
		"universe": 23},
	{"text": "Find the Sunshade Lander near the landing pad!", "picture": BlockIds.SUNSHADE,   # SpaceSecretRules
		"universe": 23},
	{"text": "From Mercury the Sun looks three times as big!", "picture": BlockIds.RAY_DUST,   # NASA; sun_size
		"universe": 23},
	{"text": "Mercury has no moons at all.", "picture": BlockIds.MERCURY_ROCK,   # NASA
		"universe": 23},
	{"text": "Look for ice in the craters far to the north!", "picture": BlockIds.SHADOW_ICE,   # MercuryTerrain
		"universe": 23},
	{"text": "Earth and our Moon look like two tiny stars here.", "picture": BlockIds.DARK_DUST,   # a spacecraft's photo
		"universe": 23},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 23},
	# cosmos: Venus's cloud city (spec §21b.2)
	{"text": "On Venus you weigh almost what you weigh at home.", "picture": BlockIds.CLOUD_DECK,   # its gravity, 0.9
		"universe": 24},
	{"text": "On Venus the Sun rises in the west!", "picture": BlockIds.TELESCOPE,   # NASA; SkyCycle.sun_west
		"universe": 24},
	{"text": "Find the Research Blimp at the airship dock!", "picture": BlockIds.BLIMP_SKIN,   # SpaceSecretRules
		"universe": 24},
	{"text": "A day on Venus lasts longer than its year!", "picture": BlockIds.SKY_TURF,   # NASA: 243 against 225 days
		"universe": 24},
	{"text": "Step off a bridge? A warm breeze lifts you back!", "picture": BlockIds.SKY_BRIDGE,   # the void line
		"universe": 24},
	{"text": "Venus has no moon at all.", "picture": BlockIds.VENUS_CLOUD,   # NASA
		"universe": 24},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 24},
	# cosmos: Saturn's rings (spec §21b.2)
	{"text": "In Saturn's rings you float a long way!", "picture": BlockIds.RING_FROST,   # its gravity, 0.05
		"universe": 25},
	{"text": "On a real ring chunk, one hop floats you away!", "picture": BlockIds.RING_ROCK,   # a chunk's tiny pull
		"universe": 25},
	{"text": "Saturn's rings are mostly water ice.", "picture": BlockIds.RING_ICE,   # NASA
		"universe": 25},
	{"text": "Find the Ring Explorer on its own ice chunk!", "picture": BlockIds.RADIO_DISH,   # SpaceSecretRules
		"universe": 25},
	{"text": "Fall between chunks? Your suit's jets bring you back!", "picture": BlockIds.RING_BEACON,   # the void line
		"universe": 25},
	{"text": "Look north: Saturn is huge from its rings!", "picture": BlockIds.SATURN_BAND,   # the sky planet
		"universe": 25},
	{"text": "The Cassini Division is a wide gap in the rings.", "picture": BlockIds.DUSTY_ICE,   # NASA
		"universe": 25},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 25},
	# cosmos: Pluto (spec §21b.2)
	{"text": "Pluto is a dwarf planet, and full of wonders!", "picture": BlockIds.NITROGEN_ICE,   # the IAU, 2006
		"universe": 26},
	{"text": "Since 2006 Pluto has been called a dwarf planet.", "picture": BlockIds.CHARON_GLOBE,   # the IAU
		"universe": 26},
	{"text": "Pluto shares its path round the Sun with icy worlds.", "picture": BlockIds.PLUTO_FROST,   # why: NASA
		"universe": 26},
	{"text": "On Pluto you jump about 16 times as high!", "picture": BlockIds.METHANE_SNOW,   # its gravity, 0.063
		"universe": 26},
	{"text": "Charon never moves in Pluto's sky: they face each other.", "picture": BlockIds.CHARON_GLOBE,   # the sky
		"universe": 26},
	{"text": "Pluto's thin haze glows blue, like Earth's sky!", "picture": BlockIds.FROST_CRYSTAL,   # New Horizons
		"universe": 26},
	{"text": "Real noon on Pluto is as dim as dusk here.", "picture": BlockIds.THOLIN_DUST,   # 1/900 of Earth's light
		"universe": 26},
	{"text": "Pluto spins backwards: its Sun rises in the west!", "picture": BlockIds.WATER_ICE,   # NASA: retrograde
		"universe": 26},
	{"text": "Find the Balloon Lander near the landing pad!", "picture": BlockIds.DRAG_BALLOON,   # SpaceSecretRules
		"universe": 26},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 26},
	# cosmos: Triton (spec §21b.2)
	{"text": "Triton goes round Neptune backwards!", "picture": BlockIds.NEPTUNE_GLOBE,   # NASA: retrograde
		"universe": 27},
	{"text": "Neptune probably caught Triton from the Kuiper Belt.", "picture": BlockIds.NITROGEN_ICE,   # NASA
		"universe": 27},
	{"text": "Triton and Pluto are icy cousins!", "picture": BlockIds.CANTALOUPE_ICE,   # NASA: many similarities
		"universe": 27},
	{"text": "Triton's geysers blow nitrogen gas 8 km high.", "picture": BlockIds.GEYSER_DUST,   # Voyager 2, 1989
		"universe": 27},
	{"text": "Step on a geyser: a gentle puff lifts you up!", "picture": BlockIds.NITROGEN_GEYSER,   # PadRules
		"universe": 27},
	{"text": "On Triton you jump about 12 times as high!", "picture": BlockIds.PINK_ICE,   # its gravity, 0.079
		"universe": 27},
	{"text": "Neptune never moves in Triton's sky.", "picture": BlockIds.NEPTUNE_GLOBE,   # tidally locked
		"universe": 27},
	{"text": "Sunlight takes about 4 hours to reach Triton.", "picture": BlockIds.TRITON_FROST,   # NASA: to Neptune
		"universe": 27},
	{"text": "Far in the future, Triton may turn into rings!", "picture": BlockIds.ICE_LAVA,   # NASA: tides
		"universe": 27},
	{"text": "Find the Hopper Lander near the landing pad!", "picture": BlockIds.NITROGEN_TANK,   # SpaceSecretRules
		"universe": 27},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 27},
	# cosmos: Ganymede (spec §21b.2)
	{"text": "Ganymede is the biggest moon in the solar system!", "picture": BlockIds.GROOVED_ICE,   # NASA
		"universe": 28},
	{"text": "Ganymede is even bigger than the planet Mercury.", "picture": BlockIds.DARK_ICE,   # NASA
		"universe": 28},
	{"text": "Ganymede is the only moon with its own magnetic field.", "picture": BlockIds.MAGNETOMETER,   # NASA
		"universe": 28},
	{"text": "Look north at night for Ganymede's glowing auroras!", "picture": BlockIds.AURORA_LAMP,   # GanymedeSky
		"universe": 28},
	{"text": "A salty ocean hides deep under Ganymede's ice.", "picture": BlockIds.WATER_ICE,   # NASA, 2015
		"universe": 28},
	{"text": "Ice and ocean may lie in layers, like a sandwich!", "picture": BlockIds.TROUGH_ICE,   # NASA/JPL, 2014
		"universe": 28},
	{"text": "On Ganymede you jump about 7 times as high!", "picture": BlockIds.POLAR_FROST,   # its gravity, 0.146
		"universe": 28},
	{"text": "Jupiter never moves in Ganymede's sky.", "picture": BlockIds.JUPITER_GLOBE,   # tidally locked
		"universe": 28},
	{"text": "Watch Io and Europa swing past Jupiter!", "picture": BlockIds.AURORA_CRYSTAL,   # GanymedeSky
		"universe": 28},
	{"text": "Sunlight takes about 43 minutes to reach Ganymede.", "picture": BlockIds.RAY_ICE,   # NASA: to Jupiter
		"universe": 28},
	{"text": "Find the Solar Wing Lander near the landing pad!", "picture": BlockIds.SOLAR_PANEL,   # SpaceSecretRules
		"universe": 28},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.LANDING_PAD,   # SpaceDirector
		"universe": 28},
	# owner #78: Wonders of the World (spec §24)
	{"text": "Follow the red arrow to the Seven Wonders!", "picture": BlockIds.PAVING,        # WondersDirector's compass
		"universe": 41},
	{"text": "Each wonder you reach stamps your Wonders Passport.", "picture": BlockIds.LIMESTONE,   # WonderData.stamp
		"universe": 41},
	{"text": "Tap a wonder's plaque for its story and its quiz.", "picture": BlockIds.WONDER_PLAQUE,   # WonderCard
		"universe": 41},
	{"text": "Of the ancient seven, only the Great Pyramid still stands!", "picture": BlockIds.CASING_STONE,   # WonderFacts
		"universe": 41},
	{"text": "Take the Wonders Road west to the New Seven Wonders!", "picture": BlockIds.SPEED_PAD,   # WonderTour.road
		"universe": 41},
	{"text": "Walk along the top of the Great Wall.", "picture": BlockIds.WALL_BRICK,   # WonderBuildsNew
		"universe": 41},
	{"text": "Walk through Petra's narrow gorge to the Treasury.", "picture": BlockIds.ROSE_ROCK,   # WonderBuildsNew
		"universe": 41},
	{"text": "Machu Picchu's stones fit together without any mortar.", "picture": BlockIds.INCA_STONE,   # WonderFacts
		"universe": 41},
	{"text": "Take the Nature Trail south to the Seven Natural Wonders!", "picture": BlockIds.SPEED_PAD,   # WonderTour.trail
		"universe": 41},
	{"text": "The canyon's bottom rocks are about 2 billion years old.", "picture": BlockIds.VISHNU_SCHIST,   # WonderFacts
		"universe": 41},
	{"text": "Tiny coral animals built the Great Barrier Reef.", "picture": BlockIds.BRAIN_CORAL, "universe": 41},
	{"text": "On dark nights, look up for the northern lights!", "picture": BlockIds.ICE,   # NatureSky
		"universe": 41},
	{"text": "Parícutin, a volcano, was born in a cornfield in 1943.", "picture": BlockIds.CINDER,   # WonderFacts
		"universe": 41},
	{"text": "Walk into the pyramid to find the King's Chamber.", "picture": BlockIds.GRANITE,   # WonderBuilds
		"universe": 41},
	{"text": "To go home, fly up high or take the portal.", "picture": BlockIds.PORTAL_FRAME,   # SpaceDirector
		"universe": 41},
]


## The indexes of the hints that fit a world of `mode` in universe `u`.
static func fitting(mode: StringName, u: int) -> Array[int]:
	var out: Array[int] = []
	for i in HINTS.size():
		var h: Dictionary = HINTS[i]
		if h.has("modes") and not (h.modes as Array).has(mode):
			continue
		if h.has("universe") and int(h.universe) != u:
			continue
		out.append(i)
	return out


## The next hint for a world of `mode` in `u`: a fitting one, never `last` again (while another fits).
static func pick(mode: StringName, u: int, last: int, rng: RandomNumberGenerator) -> int:
	var fit := fitting(mode, u)
	if fit.is_empty():
		return -1
	var others := fit.filter(func(i: int) -> bool: return i != last)
	if others.is_empty():
		return fit[0]
	return others[rng.randi_range(0, others.size() - 1)]


## A hint's picture: its block's or item's icon (the gold coin for &"coin").
static func picture(h: Dictionary) -> Texture2D:
	var p: Variant = h.get("picture")
	if p is StringName and p == &"coin":
		return CoinIcon.texture()
	if p is int:
		return BlockIcons.icon(p)
	return null
