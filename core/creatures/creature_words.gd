class_name CreatureWords
extends RefCounted
## Robots and aliens on the planets (owner #86, spec §21f): every word they say, in one table, and their looks'
## colours. Pure data with lookups.
## - A helper robot at every space world's landing pad (ROBOTS): its name, its hello, the planet's first fact, what the
##   rover's sample is (a real fact about the ground), the question bank of its science quest (each question pays
##   EarnRules.FACT_QUIZ_GOLD once) and what it says when it points the way.
## - On the real bodies (the Moon, Mars, Europa, Io, Titan, Mercury, Venus, Saturn's rings, Pluto, Triton, Ganymede) a
##   travelling alien explorers'
##   camp (CAMPS): an
##   explorer who tells of its own far world, clearly make-believe, and always says HONEST with a real fact about how
##   scientists look for life; a trader with alien souvenirs for gold (SOUVENIRS).
## - On the playful planets (Planet Boing, Rainbow Planet) an alien village (VILLAGES): homes, a chief, villagers and
##   the drum game Echo.
## The facts and their sources are listed in docs/devlog/parts/space-creatures.md; keep that list when changing one.
## No mission, company or person's name (spec §21b.2): "a rover", "a probe", "spacecraft", "scientists".

## What every alien says (the brief's words): the science stays honest.
const HONEST := "No one has found life beyond Earth yet: scientists keep looking, and so do we!"

## The robots' colours (our own look, spec §3c: white shells, the brand's teal and orange trims).
const ROBOT_SHELL := Color("eef2f5")
const ROBOT_TEAL := Color("139e9b")
const ROBOT_ORANGE := Color("f28c28")
const ROBOT_SCREEN := Color("1d2733")
const ROBOT_EYES := Color("6ff3ff")
const ROBOT_DARK := Color("4a525c")

## World -> its helper robot. questions: [{id, q, choices (3), answer (index), hint}].
const ROBOTS := {
	16: {"name": "Lumo",
		"hello": "Hello, explorer! I'm Lumo, a helper robot. Real robots help people explore space, just like me!",
		"fact": "The Moon has no air, so no wind blows here: footprints on the Moon can last for millions of years!",
		"sample": "Your sample: moon dust! It is tiny sharp bits of rock, broken up by space rocks hitting the Moon for billions of years.",
		"questions": [
			{"id": "moon_footprints", "q": "Why can footprints on the Moon last for millions of years?",
				"choices": ["No wind or rain blows them away", "Moon dust is sticky like glue", "Robots guard every footprint"],
				"answer": 0, "hint": "Remember: the Moon has no air, so no wind blows there."},
			{"id": "moon_jump", "q": "On the real Moon, how much higher could you jump than at home?",
				"choices": ["2 times", "About 6 times", "100 times"],
				"answer": 1, "hint": "The real Moon's gravity is about one sixth of Earth's."},
			{"id": "moon_dust", "q": "What is moon dust made of?",
				"choices": ["Cheese crumbs", "Snowflakes", "Tiny sharp bits of broken rock"],
				"answer": 2, "hint": "Your rover's sample: space rocks broke the Moon's rock into dust."},
		]},
	17: {"name": "Sprocket",
		"hello": "Boing-hello! I'm Sprocket, a helper robot. Planet Boing is make-believe: real planets never bounce!",
		"fact": "Gravity pulls you back down after every jump, on every planet. Planet Boing's gravity is weaker than Earth's, so you float down slowly.",
		"sample": "Your sample: boing moss! It is make-believe. Real moss is a tiny plant that loves damp, shady places.",
		"questions": [
			{"id": "boing_gravity", "q": "What pulls you back down after you jump?",
				"choices": ["The wind", "Gravity", "Magnets in your shoes"],
				"answer": 1, "hint": "It pulls everything toward the ground, on every planet."},
			{"id": "boing_moss", "q": "What is real moss?",
				"choices": ["A tiny plant", "A kind of rock", "A bouncy jelly"],
				"answer": 0, "hint": "Your rover's sample: real moss loves damp, shady places."},
			{"id": "boing_real", "q": "Which of these is a real planet?",
				"choices": ["Planet Boing", "Mars", "Rainbow Planet"],
				"answer": 1, "hint": "Planet Boing and Rainbow Planet are make-believe."},
		]},
	18: {"name": "Prism",
		"hello": "Hello, explorer! I'm Prism, a helper robot. Rainbow Planet is make-believe, but real rainbows are real science!",
		"fact": "A real rainbow happens when sunlight shines through raindrops: each drop splits the white light into colours.",
		"sample": "Your sample: prism grass! It is make-believe. A real prism is clear glass that splits white light into rainbow colours.",
		"questions": [
			{"id": "rainbow_rain", "q": "What splits sunlight into a rainbow in the sky?",
				"choices": ["Raindrops", "Clouds of paint", "Birds' feathers"],
				"answer": 0, "hint": "Rainbows come out when the sun shines while it rains."},
			{"id": "rainbow_top", "q": "Which colour is at the top of a rainbow?",
				"choices": ["Violet", "Green", "Red"],
				"answer": 2, "hint": "From the top: red, orange, yellow, green, blue, violet."},
			{"id": "rainbow_white", "q": "What is white sunlight made of?",
				"choices": ["Only yellow light", "All the colours mixed together", "Tiny stars"],
				"answer": 1, "hint": "A prism splits white light into every colour."},
		]},
	19: {"name": "Dusty",
		"hello": "Hello, explorer! I'm Dusty, a helper robot. On the real Mars, robot rovers explore for scientists on Earth!",
		"fact": "Mars is called the Red Planet: its dust has rust in it. A day here lasts about 24 and a half hours.",
		"sample": "Your sample: red Mars dust! It is red because the iron in it has rusted.",
		"questions": [
			{"id": "mars_red", "q": "Why is Mars red?",
				"choices": ["It is very hot", "Its dust has rust in it", "Red sand blew there from Earth"],
				"answer": 1, "hint": "Your rover's sample: the iron in the dust has rusted."},
			{"id": "mars_volcano", "q": "Where is the tallest volcano in the solar system?",
				"choices": ["On Mars", "On the Moon", "On Earth"],
				"answer": 0, "hint": "Its name is Olympus Mons."},
			{"id": "mars_water", "q": "What did water leave on Mars long ago?",
				"choices": ["Dry river beds", "Chocolate lakes", "Nothing at all"],
				"answer": 0, "hint": "Long ago, water flowed on Mars."},
			{"id": "mars_caps", "q": "What are Mars's ice caps made of?",
				"choices": ["Salt and sugar", "Frozen water and frozen carbon dioxide", "White sand"],
				"answer": 1, "hint": "The south cap is topped with dry ice: frozen carbon dioxide."},
		]},
	20: {"name": "Glint",
		"hello": "Hello, explorer! I'm Glint, a helper robot. Scientists send robot spacecraft to study Europa up close!",
		"fact": "Europa is one of Jupiter's moons. Scientists think a salty ocean lies under its ice.",
		"sample": "Your sample: Europa ice! Its surface is never warmer than about −160 °C: much colder than any freezer.",
		"questions": [
			{"id": "europa_ocean", "q": "What do scientists think lies under Europa's ice?",
				"choices": ["A desert", "A salty ocean", "A forest"],
				"answer": 1, "hint": "Find the ocean at the bottom of the deep ice well."},
			{"id": "europa_jupiter", "q": "Which giant planet does Europa go around?",
				"choices": ["Jupiter", "Mars", "Earth"],
				"answer": 0, "hint": "Look up: the giant striped planet in the sky."},
			{"id": "europa_cold", "q": "How cold is Europa's icy surface?",
				"choices": ["Warm like a bath", "As cold as a fridge", "Never warmer than about −160 °C"],
				"answer": 2, "hint": "Your rover's sample: much colder than any freezer."},
		]},
	21: {"name": "Ember",
		"hello": "Hello, explorer! I'm Ember, a helper robot. Spacecraft have taken pictures of Io's volcanoes erupting!",
		"fact": "Io is one of Jupiter's moons, and the most volcanic place in the solar system: it has hundreds of volcanoes.",
		"sample": "Your sample: yellow sulphur! Io's volcanoes cover the ground with it.",
		"questions": [
			{"id": "io_volcanic", "q": "What is special about Io?",
				"choices": ["It is the most volcanic place in the solar system", "It is made of ice cream",
					"It is covered in water oceans"],
				"answer": 0, "hint": "It has hundreds of volcanoes."},
			{"id": "io_yellow", "q": "What makes Io's ground yellow?",
				"choices": ["Bananas", "Sulphur from its volcanoes", "Yellow grass"],
				"answer": 1, "hint": "Your rover's sample: Io's volcanoes cover the ground with it."},
			{"id": "io_jupiter", "q": "Which planet does Io go around?",
				"choices": ["Saturn", "Jupiter", "Mercury"],
				"answer": 1, "hint": "Look up: the giant striped planet in the sky."},
		]},
	22: {"name": "Haze",
		"hello": "Hello, explorer! I'm Haze, a helper robot. A probe from Earth once landed on Titan and sent back pictures!",
		"fact": "Titan is Saturn's biggest moon, and the only moon with thick air. Its lakes and seas hold liquid methane, not water.",
		"sample": "Your sample: Titan ice! It is so cold here, about −179 °C, that ice is as hard as rock.",
		"questions": [
			{"id": "titan_lakes", "q": "What fills Titan's lakes and seas?",
				"choices": ["Water", "Liquid methane", "Orange juice"],
				"answer": 1, "hint": "Not water: Titan is far too cold for that."},
			{"id": "titan_air", "q": "What makes Titan special among moons?",
				"choices": ["It has thick air", "It is square", "It is the hottest moon"],
				"answer": 0, "hint": "Its orange haze is its air."},
			{"id": "titan_saturn", "q": "Which planet does Titan go around?",
				"choices": ["Saturn", "Earth", "Mars"],
				"answer": 0, "hint": "Look up: the planet with the rings."},
		]},
	23: {"name": "Sunny",
		"hello": "Hello, explorer! I'm Sunny, a helper robot. Spacecraft have mapped the whole of Mercury from space!",
		"fact": "Mercury is the planet closest to the Sun, and the smallest planet. A year here lasts just 88 Earth days!",
		"sample": "Your sample: Mercury dust! Deep inside, Mercury has a huge iron core, much bigger for its size than Earth's.",
		"questions": [
			{"id": "mercury_close", "q": "Which planet is closest to the Sun?",
				"choices": ["Mercury", "Mars", "Earth"],
				"answer": 0, "hint": "You are standing on it!"},
			{"id": "mercury_year", "q": "How long is a year on Mercury?",
				"choices": ["One week", "88 Earth days", "100 years"],
				"answer": 1, "hint": "It goes round the Sun faster than any other planet."},
			{"id": "mercury_cliffs", "q": "Why does Mercury have long cliffs?",
				"choices": ["Giants built them", "It shrank as it cooled", "The wind blew them up"],
				"answer": 1, "hint": "Find a long cliff: Mercury's crust pushed it up."},
		]},
	24: {"name": "Nimbus",
		"hello": "Hello, explorer! I'm Nimbus, a helper robot. Our city floats about 50 km up in Venus's sky!",
		"fact": "Venus spins backwards, so the Sun rises in the west. A day here lasts longer than a whole Venus year!",
		"sample": "Your sample: a jar of Venus air! It is mostly carbon dioxide, much heavier than the air we breathe.",
		"questions": [
			{"id": "venus_west", "q": "Where does the Sun rise on Venus?",
				"choices": ["In the west", "In the east", "It never rises"],
				"answer": 0, "hint": "Venus spins backwards. Visit the west lookout!"},
			{"id": "venus_clouds", "q": "What are Venus's yellow clouds made of?",
				"choices": ["Cotton candy", "Tiny drops of sulfuric acid", "Snowflakes"],
				"answer": 1, "hint": "Look through the cloud scope by the landing pad."},
			{"id": "venus_float", "q": "Why could a city float high over Venus?",
				"choices": ["Venus has no gravity", "Giant magnets hold it up", "The air we breathe floats in Venus's heavy air"],
				"answer": 2, "hint": "Visit the airship dock and read its fact."},
		]},
	25: {"name": "Hoop",
		"hello": "Hello, explorer! I'm Hoop, a helper robot. We are standing on Saturn's rings!",
		"fact": "Saturn's rings are billions of chunks of ice, and they go all the way round Saturn!",
		"sample": "Your sample: a scoop of ring ice! It is almost all water ice, with a little dust and rock.",
		"questions": [
			{"id": "rings_made", "q": "What are Saturn's rings made of?",
				"choices": ["Gas and fire", "Chunks of ice and rock", "Solid gold"],
				"answer": 1, "hint": "Look at the ground under your feet: it is ice!"},
			{"id": "rings_gap", "q": "What is the Cassini Division?",
				"choices": ["A gap between the rings", "A moon", "A storm on Saturn"],
				"answer": 0, "hint": "Hop south to the edge of the bright B ring and look."},
			{"id": "rings_pan", "q": "What keeps the Encke Gap clear?",
				"choices": ["The wind", "A little moon called Pan", "Robots with brooms"],
				"answer": 1, "hint": "Find the walnut-shaped moon in the gap, far to the south."},
		]},
	26: {"name": "Nixie",
		"hello": "Hello, explorer! I'm Nixie, a helper robot. Welcome to Pluto, a dwarf planet far, far from the Sun!",
		"fact": "Pluto is a dwarf planet. Since 2006, a planet must clear its path round the Sun, and Pluto shares its path with many icy worlds.",
		"sample": "Your sample: nitrogen ice! On Earth nitrogen is a gas in the air we breathe. Here it is so cold that it freezes.",
		"questions": [
			{"id": "pluto_dwarf", "q": "Why is Pluto called a dwarf planet?",
				"choices": ["It is made of cheese", "It is very cold", "It shares its path round the Sun with many icy worlds"],
				"answer": 2, "hint": "Since 2006, a planet must clear its path round the Sun."},
			{"id": "pluto_heart", "q": "What is the plain in Pluto's heart made of?",
				"choices": ["Frozen nitrogen", "Red sand", "Liquid water"],
				"answer": 0, "hint": "Walk east onto the heart's plain and read its fact."},
			{"id": "pluto_charon", "q": "Why does Charon never move in Pluto's sky?",
				"choices": ["It is glued to the sky", "Pluto and Charon always face each other", "Charon is a painting"],
				"answer": 1, "hint": "Visit the Charon Lookout by the landing pad."},
		]},
	27: {"name": "Spout",
		"hello": "Hello, explorer! I'm Spout, a helper robot. Welcome to Triton, Neptune's biggest moon!",
		"fact": "Triton goes round Neptune backwards: it is the only big moon in the solar system that does.",
		"sample": "Your sample: pink nitrogen ice! Sunlight turned a little methane in it pink.",
		"questions": [
			{"id": "triton_backwards", "q": "Which way does Triton go round Neptune?",
				"choices": ["The same way Neptune spins", "Backwards", "It never moves"],
				"answer": 1, "hint": "Triton is the only big moon that goes round its planet the other way."},
			{"id": "triton_geysers", "q": "What do Triton's geysers blow high into the sky?",
				"choices": ["Nitrogen gas and dark dust", "Hot lava", "Soap bubbles"],
				"answer": 0, "hint": "Find a geyser on the pink ice to the south and read its fact."},
			{"id": "triton_neptune", "q": "Why does Neptune never move in Triton's sky?",
				"choices": ["Neptune is a painting", "Triton always shows Neptune the same face", "It is glued there"],
				"answer": 1, "hint": "Visit the Neptune Lookout by the landing pad."},
		]},
	28: {"name": "Compass",
		"hello": "Hello, explorer! I'm Compass, a helper robot. Welcome to Ganymede, the biggest moon of all!",
		"fact": "Ganymede is the only moon with its own magnetic field: its iron core makes it, as Earth's does.",
		"sample": "Your sample: Ganymede's water ice! Its crust of ice is about 150 km thick.",
		"questions": [
			{"id": "ganymede_magnet", "q": "What does Ganymede have that no other moon has?",
				"choices": ["Its own magnetic field", "A crust of cheese", "Square craters"],
				"answer": 0, "hint": "Find the Aurora Watch on the frost to the north."},
			{"id": "ganymede_size", "q": "Which is bigger: Ganymede or the planet Mercury?",
				"choices": ["Mercury", "Ganymede", "They are the same size"],
				"answer": 1, "hint": "Ganymede is the biggest moon of all."},
			{"id": "ganymede_ocean", "q": "Where is Ganymede's salty ocean?",
				"choices": ["On top of the ice", "Deep under its icy crust", "Inside Jupiter"],
				"answer": 1, "hint": "Visit the ocean drill to the south-west."},
		]},
}

## What a robot says when it points the way (%s: the place's name).
const POINT_WORDS := "Look where my arm points: %s! The red arrow points there too."
const POINT_CAMP := "Look where my arm points: the aliens' camp! They are explorers, like you."
const POINT_VILLAGE := "Look where my arm points: the alien village! They love music and games."
const ALL_EXPLORED := "You explored every place here! The Star Map has more worlds to visit."

## The science quest's words.
const QUEST_TITLE := "Science Quest"
const QUEST_GO := "LET'S GO!"
const QUEST_ANOTHER := "ANOTHER QUESTION"
const QUEST_ASK := "You're back! Here is my question:"
const ROBOT_TITLE := "%s the helper robot"
const QUEST_OFFER := "Will you help me with a science quest? Dig a sample, explore a place, then come back and answer my question!"
const QUEST_DIG := "Step 1: tap your rover buddy. It digs a sample for science!"
const QUEST_FIND := "Step 2: explore %s. Follow my arm!"
const QUEST_BACK := "Step 3: come back to me and answer my question!"
const QUEST_DONE := "Thank you, scientist! You finished my science quest."
const QUIZ_RIGHT := "Right the first time!"
const QUIZ_RIGHT_AGAIN := "Right! You worked it out."
const QUIZ_NOT_YET := "Not yet! Here is a hint: %s"
const QUIZ_ANSWER := "The answer is: %s. Let's try another one next time!"
const QUIZ_MORE := "Ask me another question any time!"
const QUIZ_ALL := "You answered all my questions! You are a real space scientist."

## The rover buddy and the scout drone.
const ROVER_NAME := "Rover"
const ROVER_DIGS := "Beep! Your rover digs a sample..."
const ROVER_AGAIN := "Your rover already dug a sample here. Scientists study every grain!"
const DRONE_NAME := "Drone"
const DRONE_SCOUTS := "Your drone flew ahead: %s is %d blocks %s!"
const DRONE_CAMP := "Your drone flew ahead: the aliens are %d blocks %s!"
const DRONE_NOTHING := "Your drone looked everywhere: you explored every place here!"
const DIRECTIONS: Array[String] = ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]

## A camp's colours. Each alien: [body, belly, suit, antenna tip].
const CAMPS := {
	16: {"explorer": &"blip", "trader": &"ploo"},
	19: {"explorer": &"zib", "trader": &"quix"},
	20: {"explorer": &"nuri", "trader": &"fizz"},
	21: {"explorer": &"tinka", "trader": &"wobbo"},
	22: {"explorer": &"oolo", "trader": &"mip"},
	23: {"explorer": &"pim", "trader": &"zeeka"},
	24: {"explorer": &"nubi", "trader": &"brezz"},
	25: {"explorer": &"frosi", "trader": &"clink"},
	26: {"explorer": &"wisp", "trader": &"tumble"},
	27: {"explorer": &"puffle", "trader": &"glim"},
	28: {"explorer": &"lumo", "trader": &"ridgy"},
}
const CAMP_NAME := "Explorers' Camp"
const CAMP_FOUND := "You found the aliens' camp! They are explorers from a make-believe world."

## The playful planets' villages: their name, the chief and the villagers.
const VILLAGES := {
	17: {"name": "Boingaloo", "chief": &"bopsy", "villagers": [&"hop", &"zoop", &"tiggle"],
		"home_colors": [Color("9be34a"), Color("ff9e3d"), Color("b388ff"), Color("4dd0c8")],
		"roof_colors": [Color("7a4fd6"), Color("ff5c8a"), Color("ffd23f"), Color("ff7043")]},
	18: {"name": "Prismtown", "chief": &"iri", "villagers": [&"hue", &"tint", &"shimmer"],
		"home_colors": [Color("ff6b6b"), Color("ffd23f"), Color("6bcb77"), Color("4d96ff")],
		"roof_colors": [Color("b388ff"), Color("ff9e3d"), Color("4dd0c8"), Color("ff8fc8")]},
}
const VILLAGE_FOUND := "You found %s, a make-believe alien village! Tap the chief to play."

## Every alien: its name, what it is, its colours, what it says. `role`: explorer, trader, chief, villager.
## pretend: its make-believe home world (always said as make-believe); science: a real fact about how scientists look
## for life; gift: the souvenir it gives a new friend; asks: what it would love (a sample from this planet).
const ALIENS := {
	&"blip": {"name": "Blip", "role": &"explorer", "colors": [Color("c7a8ff"), Color("efe4ff"), Color("5a67d8"), Color("ffd23f")],
		"pretend": "In my story, I come from Planet Wobble, where the hills wobble like jelly when you walk! The moon bunnies here are make-believe too, just like me.",
		"science": "Scientists look for water on other worlds, because every living thing we know needs water.",
		"asks": "Could your rover dig me a sample of moon dust? I'd love to keep one!", "gift": "gift_blip"},
	&"ploo": {"name": "Ploo", "role": &"trader", "colors": [Color("ffc59e"), Color("fff0e3"), Color("e05a8a"), Color("7be0ff")],
		"hello": "Hello! I'm Ploo, the camp's trader. My souvenirs are make-believe treasures from our story world!",
		"souvenirs": ["wobble_jar", "star_compass"]},
	&"zib": {"name": "Zib", "role": &"explorer", "colors": [Color("8ee6b8"), Color("e3fff0"), Color("f28c28"), Color("ff5c8a")],
		"pretend": "In my story, my home planet Glimmer has three suns, so it is never dark there!",
		"science": "Real rovers study Mars rocks, looking for signs of tiny life from long, long ago.",
		"asks": "Could your rover dig me a sample of red Mars dust? We have no red dust in my story!", "gift": "gift_zib"},
	&"quix": {"name": "Quix", "role": &"trader", "colors": [Color("8fd3ff"), Color("e6f6ff"), Color("ffd23f"), Color("ff7043")],
		"hello": "Hi there! I'm Quix, the camp's trader. Every souvenir comes with a story!",
		"souvenirs": ["sun_marble", "singing_pebble"]},
	&"nuri": {"name": "Nuri", "role": &"explorer", "colors": [Color("7fe0e0"), Color("e0ffff"), Color("7a4fd6"), Color("ffe066")],
		"pretend": "On my pretend world Bubbla, it snows soap bubbles every morning!",
		"science": "Scientists want to explore Europa's ocean: where there is water, there might be life.",
		"asks": "Could your rover dig me a sample of Europa ice? I want to see how it sparkles!", "gift": "gift_nuri"},
	&"fizz": {"name": "Fizz", "role": &"trader", "colors": [Color("ffa3cf"), Color("fff0f7"), Color("139e9b"), Color("9be34a")],
		"hello": "Hello, hello! I'm Fizz, the camp's trader. Look at my make-believe treasures!",
		"souvenirs": ["bubble_globe", "ice_flute"]},
	&"tinka": {"name": "Tinka", "role": &"explorer", "colors": [Color("ff9a8b"), Color("ffe9e4"), Color("2f7fe0"), Color("fff59d")],
		"pretend": "In my story, my world Emberpop has warm pink rain that smells like strawberries!",
		"science": "On Earth, tiny living things live in hot springs: scientists wonder where else life could hide.",
		"asks": "Could your rover dig me a sample of yellow sulphur? It is such a sunny colour!", "gift": "gift_tinka"},
	&"wobbo": {"name": "Wobbo", "role": &"trader", "colors": [Color("ffe066"), Color("fffbe0"), Color("8e44ad"), Color("7be0ff")],
		"hello": "Welcome! I'm Wobbo, the camp's trader. Want a souvenir from our story world?",
		"souvenirs": ["rain_umbrella", "glow_stone"]},
	&"oolo": {"name": "Oolo", "role": &"explorer", "colors": [Color("5fd4b8"), Color("e0fff6"), Color("f28c28"), Color("ff8fc8")],
		"pretend": "On my pretend world Mistyloo, everyone flies with wings made of fog!",
		"science": "Some scientists wonder if a very different kind of life could live in Titan's methane lakes.",
		"asks": "Could your rover dig me a sample of Titan ice? Ice as hard as rock sounds amazing!", "gift": "gift_oolo"},
	&"mip": {"name": "Mip", "role": &"trader", "colors": [Color("ffb366"), Color("fff1e0"), Color("2e7d6b"), Color("b388ff")],
		"hello": "Hi! I'm Mip, the camp's trader. My souvenirs are make-believe, and so am I!",
		"souvenirs": ["fog_kite", "haze_lantern"]},
	&"pim": {"name": "Pim", "role": &"explorer", "colors": [Color("ffd54f"), Color("fff8e1"), Color("d84315"), Color("7be0ff")],
		"pretend": "In my story, my planet Twirl spins so fast that a whole day lasts one hour!",
		"science": "Big telescopes have found more than 5,000 planets around other stars, and scientists study their air for signs of life.",
		"asks": "Could your rover dig me a sample of Mercury dust? I collect dust from every planet!", "gift": "gift_pim"},
	&"zeeka": {"name": "Zeeka", "role": &"trader", "colors": [Color("c6f06b"), Color("f7ffe0"), Color("5a67d8"), Color("ff5c8a")],
		"hello": "Hello, explorer! I'm Zeeka, the camp's trader. Every treasure here is from our make-believe world!",
		"souvenirs": ["spin_top", "sun_hat"]},
	&"nubi": {"name": "Nubi", "role": &"explorer", "colors": [Color("ffe08a"), Color("fff6d6"), Color("139e9b"), Color("ff8fc8")],
		"pretend": "In my story, my home world Fluffle floats in pink clouds, and everyone lives in balloon houses!",
		"science": "Some scientists wonder if tiny living things could float in Venus's clouds, high up where it is cooler.",
		"asks": "Could your rover catch me a jar of Venus cloud air? I collect skies from every planet!", "gift": "gift_nubi"},
	&"brezz": {"name": "Brezz", "role": &"trader", "colors": [Color("b3e5fc"), Color("eef9ff"), Color("f28c28"), Color("ffd23f")],
		"hello": "Hi, explorer! I'm Brezz, the camp's trader. My souvenirs are make-believe, just like me!",
		"souvenirs": ["balloon_charm", "cloud_jar"]},
	&"frosi": {"name": "Frosi", "role": &"explorer", "colors": [Color("9fe0ff"), Color("eefaff"), Color("7a4fd6"), Color("ffd23f")],
		"pretend": "In my story, my home world Glisten is one big ring of shiny ice, and everyone skates all day long!",
		"science": "Saturn's moon Enceladus sprays water from an ocean under its ice. Scientists want to look for life there.",
		"asks": "Could your rover chip me a piece of ring ice? It sparkles just like my home!", "gift": "gift_frosi"},
	&"clink": {"name": "Clink", "role": &"trader", "colors": [Color("ffb3d9"), Color("fff0f7"), Color("139e9b"), Color("9fe0ff")],
		"hello": "Hi, explorer! I'm Clink, the camp's trader. My souvenirs are make-believe, just like me!",
		"souvenirs": ["ring_skates", "walnut_marble"]},
	&"wisp": {"name": "Wisp", "role": &"explorer", "colors": [Color("ffc2e0"), Color("fff0f7"), Color("7a4fd6"), Color("9fe0ff")],
		"pretend": "In my story, my home world Snugheart is shaped like a heart, and everyone gives warm hugs to stay cosy!",
		"science": "Where there is water, scientists look for life. They think an ocean may hide deep under Pluto's icy heart.",
		"asks": "Could your rover scoop me some nitrogen ice? It sparkles just like my home!", "gift": "gift_wisp"},
	&"tumble": {"name": "Tumble", "role": &"trader", "colors": [Color("b8e0ff"), Color("eef8ff"), Color("e05a8a"), Color("ffd23f")],
		"hello": "Hi, explorer! I'm Tumble, the camp's trader. My souvenirs are make-believe, just like me!",
		"souvenirs": ["heart_globe", "twin_yoyo"]},
	&"puffle": {"name": "Puffle", "role": &"explorer", "colors": [Color("9fd8ff"), Color("f0f8ff"), Color("f28c28"), Color("ffc2e0")],
		"pretend": "In my story, my home world Puffaloo has geysers that blow bubbles, and everyone rides them to school!",
		"science": "Where there is water, scientists look for life. There may be an ocean deep under Triton's ice.",
		"asks": "Could your rover scoop me some pink ice? It glitters just like my home!", "gift": "gift_puffle"},
	&"glim": {"name": "Glim", "role": &"trader", "colors": [Color("ffd1e8"), Color("fff5fa"), Color("3f63e0"), Color("ffd23f")],
		"hello": "Hi, explorer! I'm Glim, the camp's trader. My souvenirs are make-believe, just like me!",
		"souvenirs": ["geyser_whistle", "melon_ball"]},
	&"lumo": {"name": "Lumo", "role": &"explorer", "colors": [Color("8affb8"), Color("f2fff6"), Color("ff9ccc"), Color("ffd23f")],
		"pretend": "In my story, my home world Lumoria has auroras so bright that we read bedtime stories by them!",
		"science": "Where there is water, scientists look for life. Ganymede's deep ocean may hold more water than Earth's seas.",
		"asks": "Could your rover scoop me some polar frost? It sparkles just like my home!", "gift": "gift_lumo"},
	&"ridgy": {"name": "Ridgy", "role": &"trader", "colors": [Color("dfe1e4"), Color("ffffff"), Color("6f6559"), Color("6df2a2")],
		"hello": "Hi, explorer! I'm Ridgy, the camp's trader. My souvenirs are make-believe, just like me!",
		"souvenirs": ["groove_comb", "magnet_moon"]},
	&"bopsy": {"name": "Bopsy", "role": &"chief", "colors": [Color("ffcf3f"), Color("fff6d6"), Color("7a4fd6"), Color("ff5c8a")],
		"pretend": "Welcome to Boingaloo! We are make-believe aliens, and we love music and bouncing!",
		"science": "Real scientists listen to space with giant radio telescopes, in case someone out there is calling.",
		"gift": "gift_bopsy"},
	&"hop": {"name": "Hop", "role": &"villager", "colors": [Color("ffb74d"), Color("fff3e0"), Color("4dd0c8"), Color("ffd23f")]},
	&"zoop": {"name": "Zoop", "role": &"villager", "colors": [Color("b388ff"), Color("f3ebff"), Color("ff7043"), Color("9be34a")]},
	&"tiggle": {"name": "Tiggle", "role": &"villager", "colors": [Color("4dd0c8"), Color("e0fffb"), Color("ff5c8a"), Color("ffe066")]},
	&"iri": {"name": "Iri", "role": &"chief", "colors": [Color("ff8fc8"), Color("fff0f7"), Color("4d96ff"), Color("ffd23f")],
		"pretend": "Welcome to Prismtown! We are make-believe aliens, and every song we sing has seven colours!",
		"science": "Scientists split starlight into rainbow colours to learn what far planets' air is made of.",
		"gift": "gift_iri"},
	&"hue": {"name": "Hue", "role": &"villager", "colors": [Color("ff6b6b"), Color("ffe9e9"), Color("ffd23f"), Color("4d96ff")]},
	&"tint": {"name": "Tint", "role": &"villager", "colors": [Color("6bcb77"), Color("e9ffec"), Color("b388ff"), Color("ff9e3d")]},
	&"shimmer": {"name": "Shimmer", "role": &"villager", "colors": [Color("4d96ff"), Color("e6f0ff"), Color("ff8fc8"), Color("9be34a")]},
}

## An explorer's and a chief's words around a friendship.
const MEET := "Hello! I'm %s, an explorer from a make-believe world."
const AGAIN := "Hello again, explorer!"
const GIVE := "GIVE A SAMPLE"
const COME := "COME ALONG"
const NOT_NOW := "NOT NOW"
const GOT := "You got the %s! %s"
const NEED_GOLD := "You need %d more gold. Lessons in the SCHOOL earn it!"
const YOUR_GOLD := "You have %d gold."
const YOUR_SOUVENIRS := "Your souvenirs: %s."
const PLAY_ECHO := "PLAY ECHO"
const THANKS := "Thank you, %s! You are my friend now. Here is a present for you: the %s!"
const COME_ASK := "May I come along with you, into every world?"
const COMES := "%s comes along with you now, into every world!"
const STAYS := "%s goes back to its camp. You are still friends!"
const FRIEND_HELLO := "Hello again, my friend!"
const BUDDY_HELLO := "I'm right here with you, my friend!"
const WANTS_SAMPLE := "Your rover can dig a sample: tap your rover!"
const ONE_BUDDY := "One alien friend comes along at a time: %s goes back to its camp, and stays your friend."

## Villagers' happy lines (a tap).
const VILLAGER_LINES: Array[String] = ["Boop! Hello!", "Want to play Echo? Ask our chief!", "We love music!",
	"Hop, hop, hooray!", "You're a great explorer!"]

## The drum game Echo.
const ECHO_TITLE := "Echo"
const ECHO_OFFER := "Let's play Echo! Listen to the drums, then hop on them in the same order."
const ECHO_LISTEN := "Listen..."
const ECHO_YOUR_TURN := "Your turn! Hop on the drums in the same order."
const ECHO_RIGHT := "Yes! One more note..."
const ECHO_NOT_YET := "Not yet! Listen again."
const ECHO_WON := "You did it! You played the whole song!"
const ECHO_AGAIN := "Play again any time!"

## Souvenirs: make-believe treasures (never real planets' things), each a line of its story. Bought ones at a camp's
## trader (and on the Gold Shop's DECORATIONS shelf); gifts only from a new friend.
const SOUVENIRS := {
	"wobble_jar": {"name": "Wobble Jelly Jar", "price": 60, "color": Color("c7a8ff"),
		"story": "In the story, the jelly wobbles whenever someone laughs."},
	"star_compass": {"name": "Star Compass", "price": 120, "color": Color("ffd23f"),
		"story": "In the story, its needle always points to the brightest star."},
	"sun_marble": {"name": "Three-Sun Marble", "price": 80, "color": Color("ff9e3d"),
		"story": "In the story, three tiny suns glow inside it."},
	"singing_pebble": {"name": "Singing Pebble", "price": 60, "color": Color("8ee6b8"),
		"story": "In the story, it hums a tune when you hold it."},
	"bubble_globe": {"name": "Bubble Snow Globe", "price": 90, "color": Color("7fe0e0"),
		"story": "Shake it, and in the story it snows soap bubbles."},
	"ice_flute": {"name": "Ice Flute", "price": 70, "color": Color("e0ffff"),
		"story": "In the story, it plays the sound of snowflakes."},
	"rain_umbrella": {"name": "Pink Rain Umbrella", "price": 70, "color": Color("ff8fc8"),
		"story": "In the story, it keeps off warm pink rain."},
	"glow_stone": {"name": "Warm Glow Stone", "price": 90, "color": Color("ffe066"),
		"story": "In the story, it glows warm like a little sun."},
	"fog_kite": {"name": "Fog Wings Kite", "price": 90, "color": Color("dfe9f0"),
		"story": "In the story, its wings are made of fog."},
	"haze_lantern": {"name": "Haze Lantern", "price": 60, "color": Color("ffb366"),
		"story": "In the story, it glows orange like Titan's sky."},
	"spin_top": {"name": "Twirl Spinning Top", "price": 60, "color": Color("c6f06b"),
		"story": "In the story, it spins all day, a whole hour long."},
	"sun_hat": {"name": "Sunbeam Hat", "price": 80, "color": Color("fff59d"),
		"story": "In the story, it keeps a sunbeam in its brim."},
	"gift_blip": {"name": "Wobble Star", "gift": true, "color": Color("c7a8ff"),
		"story": "Blip's present: a star that wobbles, in the story."},
	"gift_zib": {"name": "Glimmer Gem", "gift": true, "color": Color("8ee6b8"),
		"story": "Zib's present: a gem from the three suns' world, in the story."},
	"gift_nuri": {"name": "Bubble Wand", "gift": true, "color": Color("7fe0e0"),
		"story": "Nuri's present: it blows snow bubbles, in the story."},
	"gift_tinka": {"name": "Strawberry Rain Drop", "gift": true, "color": Color("ff9a8b"),
		"story": "Tinka's present: a drop of warm pink rain, in the story."},
	"gift_oolo": {"name": "Fog Feather", "gift": true, "color": Color("5fd4b8"),
		"story": "Oolo's present: a feather from fog wings, in the story."},
	"gift_pim": {"name": "Twirl Clock", "gift": true, "color": Color("ffd54f"),
		"story": "Pim's present: a clock with a one-hour day, in the story."},
	"balloon_charm": {"name": "Balloon House Charm", "price": 70, "color": Color("ff8fc8"),
		"story": "In the story, it floats up a little whenever you smile."},
	"cloud_jar": {"name": "Pink Cloud Jar", "price": 90, "color": Color("ffd1e8"),
		"story": "In the story, a tiny pink cloud lives inside it."},
	"gift_nubi": {"name": "Floating Feather Hat", "gift": true, "color": Color("ffe08a"),
		"story": "Nubi's present: a hat that floats up by itself, in the story."},
	"ring_skates": {"name": "Ring Skates", "price": 80, "color": Color("bfe8ff"),
		"story": "In the story, they glide all the way round a ring without ever stopping."},
	"walnut_marble": {"name": "Walnut Moon Marble", "price": 60, "color": Color("ebe3d2"),
		"story": "In the story, it rolls along a gap and sweeps it clean, like a little moon."},
	"gift_frosi": {"name": "Sparkle Snowflake", "gift": true, "color": Color("9fe0ff"),
		"story": "Frosi's present: a snowflake that never melts, in the story."},
	"heart_globe": {"name": "Heart Snow Globe", "price": 70, "color": Color("f3ece0"),
		"story": "In the story, shake it and nitrogen snow falls on a tiny icy heart."},
	"twin_yoyo": {"name": "Twin Moon Yo-Yo", "price": 60, "color": Color("a8a39d"),
		"story": "In the story, its two balls always spin face to face, like Pluto and Charon."},
	"gift_wisp": {"name": "Cosy Heart Mittens", "gift": true, "color": Color("ff8fc8"),
		"story": "Wisp's present: mittens that stay warm even on Pluto, in the story."},
	"geyser_whistle": {"name": "Geyser Whistle", "price": 60, "color": Color("f0c9c6"),
		"story": "In the story, blow it and a tiny geyser puffs up a cloud of frost."},
	"melon_ball": {"name": "Cantaloupe Ball", "price": 50, "color": Color("b3b79a"),
		"story": "In the story, it bounces on its dimples, like Triton's cantaloupe ground."},
	"gift_puffle": {"name": "Backwards Spinning Top", "gift": true, "color": Color("3f63e0"),
		"story": "Puffle's present: a top that spins backwards, like Triton going round Neptune, in the story."},
	"groove_comb": {"name": "Groove Comb", "price": 50, "color": Color("dfe1e4"),
		"story": "In the story, it combs sand into long ridges and grooves, like Ganymede's bright ground."},
	"magnet_moon": {"name": "Magnet Moon", "price": 60, "color": Color("6df2a2"),
		"story": "In the story, this little moon has its own magnetic field, just like Ganymede."},
	"gift_lumo": {"name": "Aurora Night-Light", "gift": true, "color": Color("8affb8"),
		"story": "Lumo's present: a night-light that glows red and green like Ganymede's auroras, in the story."},
	"gift_bopsy": {"name": "Boingaloo Drum", "gift": true, "color": Color("ffcf3f"),
		"story": "Bopsy's present: a little drum that plays Echo's song by itself, in the story."},
	"gift_iri": {"name": "Rainbow Bell", "gift": true, "color": Color("ff8fc8"),
		"story": "Iri's present: a bell that rings in seven colours, in the story."},
}


static func robot(u: int) -> Dictionary:
	return ROBOTS.get(u, {})


static func has_robot(u: int) -> bool:
	return ROBOTS.has(u)


static func alien(id: StringName) -> Dictionary:
	return ALIENS.get(id, {})


static func alien_name(id: StringName) -> String:
	return str(alien(id).get("name", ""))


static func camp(u: int) -> Dictionary:
	return CAMPS.get(u, {})


static func village(u: int) -> Dictionary:
	return VILLAGES.get(u, {})


static func souvenir(id: String) -> Dictionary:
	return SOUVENIRS.get(id, {})


## One question of world u's robot by id ({} for none).
static func question(u: int, id: String) -> Dictionary:
	for q: Dictionary in robot(u).get("questions", []):
		if q.id == id:
			return q
	return {}


## Every question id of every robot (CreatureData keeps the paid ones).
static func question_ids() -> Array[String]:
	var out: Array[String] = []
	for u: int in ROBOTS:
		for q: Dictionary in ROBOTS[u].questions:
			out.append(str(q.id))
	return out


## The eight-way direction from `from` to `to` in words (north is -z).
static func direction(from: Vector3, to: Vector3) -> String:
	var d := Vector2(to.x - from.x, to.z - from.z)
	if d.length() < 0.001:
		return DIRECTIONS[0]
	var a := fposmod(atan2(d.x, -d.y), TAU)   # 0 = north (-z), clockwise: east is +x
	return DIRECTIONS[int(roundi(a / (TAU / 8.0))) % 8]
