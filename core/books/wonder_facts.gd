class_name WonderFacts
extends RefCounted
## The world's wonders' real stories (owner #78, spec §24), as pure data, a tour at a time: the first tour, the Seven
## Wonders of the Ancient World, the second, the New Seven Wonders (chosen in 2007), and the third, the Seven Natural
## Wonders of the World (a list from 1997). Each wonder: its name, where it is (or was), when it was built (nature's:
## how it was formed, "formed"), whether it still stands (STANDING, GONE or UNKNOWN: the Hanging Gardens may never have
## existed; nature's are NATURAL), what a child hears on reaching it (sight), four to six real facts (its card: the
## plaque by it and the Wonders Passport's page), its fact quiz (each question pays EarnRules.FACT_QUIZ_GOLD once,
## answered right the first time) and what its secret's find says. Religion is told as culture and what people believe
## (spec §22.4); only people of history are named; hard history (forced labour, conquest) is named with respect, never
## shown. Every fact is checked against encyclopaedias, museums, national parks and UNESCO: the lists with their sources
## are docs/devlog/parts/wonders-ancient.md, wonders-new-seven.md and wonders-nature.md (keep them when changing a fact).

const STANDING := &"standing"
const GONE := &"gone"
const UNKNOWN := &"unknown"
const NATURAL := &"natural"        # the third tour: made by nature, not built

## The first tour (its constants keep their first names: the landing square's plaque and the ancient seven's card).
const TOUR := "the Seven Wonders of the Ancient World"
const TOUR_TITLE := "The Seven Wonders"
## The world's landing card (PlanetGuideCard): both tours, which are gone, where the second one is, what to do.
const WORLD_TITLE := "the Wonders of the World"
const TOUR_INTRO := "The Seven Wonders of the Ancient World stand round this square: only the Great Pyramid still " \
	+ "stands, the rest are built as people believe they looked. The New Seven Wonders wait along the Wonders Road to the " \
	+ "west, the Seven Natural Wonders along the Nature Trail to the south. Each one stamps your Wonders Passport. " \
	+ "Follow the red arrow!"
## The first tour's own plaque (by the landing spot) and the passport's first page.
const TOUR_FACTS: Array[String] = [
	"Greek travellers wrote lists of amazing things to see: the Seven Wonders of the Ancient World.",
	"Only the Great Pyramid still stands. Earthquakes, fires and people took the other six.",
	"The pyramid was already about 2,000 years old when the other wonders were built.",
	"No one knows for sure the Hanging Gardens of Babylon ever existed.",
	"The New Seven Wonders, chosen in 2007, stand along the Wonders Road to the west.",
	"The Seven Natural Wonders, made by nature, wait along the Nature Trail to the south.",
]

## The second tour: the New Seven Wonders, round their own square at the end of the Wonders Road.
const NEW_TOUR := "the New Seven Wonders"
const NEW_TOUR_TITLE := "The New Seven Wonders"
const NEW_TOUR_FACTS: Array[String] = [
	"In 2007 people all over the world voted on the internet and by phone for the New Seven Wonders.",
	"All seven still stand today, on four continents: Asia, Europe, North and South America.",
	"The Great Pyramid, the last ancient wonder still standing, was given a place of honour.",
	"It was a popular vote: many other amazing places were not on the list.",
	"The Seven Ancient Wonders stand along the Wonders Road to the east.",
]

## The third tour: the Seven Natural Wonders of the World (a list made in 1997), round their own square at the end of
## the Nature Trail, south of the landing square.
const NATURE_TOUR := "the Seven Natural Wonders of the World"
const NATURE_TOUR_TITLE := "The Seven Natural Wonders"
const NATURE_TOUR_FACTS: Array[String] = [
	"In 1997 a list was made of the Seven Natural Wonders of the World: amazing places made by nature, not by people.",
	"Rivers, ice, the sea, tiny corals, the Sun and the moving ground made them, some over millions of years.",
	"They are on five continents, and the northern lights shine round the North Pole.",
	"Each one shows how our Earth works. Walk to each one and stamp your Wonders Passport!",
	"The Seven Ancient Wonders stand along the Nature Trail to the north.",
]

## The tours: their wonders (in their lists' order), titles, what their square's plaque says (its id: WonderTour), the
## way there from the landing square (`road`, `way`: "" for the tour round it).
const ANCIENT: Array[StringName] = [&"pyramid", &"gardens", &"artemis", &"zeus", &"mausoleum", &"colossus", &"lighthouse"]
const NEW: Array[StringName] = [&"great_wall", &"petra", &"colosseum", &"chichen_itza", &"machu_picchu", &"taj_mahal",
	&"christ_redeemer"]
const NATURE: Array[StringName] = [&"grand_canyon", &"barrier_reef", &"rio_harbour", &"everest", &"northern_lights",
	&"paricutin", &"victoria_falls"]
const TOURS := {
	&"ancient": {"name": TOUR, "title": TOUR_TITLE, "heading": "The Seven Ancient Wonders", "plaque": &"tour",
		"where": "Of the Ancient World: 1 still standing, 6 gone", "facts": TOUR_FACTS, "road": "", "way": ""},
	&"new": {"name": NEW_TOUR, "title": NEW_TOUR_TITLE, "heading": "The New Seven Wonders", "plaque": &"tour_new",
		"where": "Chosen in 2007: all 7 still standing", "facts": NEW_TOUR_FACTS, "road": "Wonders Road",
		"way": "follow the Wonders Road west to the New Seven Wonders"},
	&"nature": {"name": NATURE_TOUR, "title": NATURE_TOUR_TITLE, "heading": "The Seven Natural Wonders",
		"plaque": &"tour_nature", "where": "Made by nature: a list from 1997", "facts": NATURE_TOUR_FACTS,
		"road": "Nature Trail", "way": "follow the Nature Trail south to the Seven Natural Wonders"},
}
const TOUR_IDS: Array[StringName] = [&"ancient", &"new", &"nature"]

## Every wonder of every tour, the first tour first (the passport's stamps, the sights, the saved marks).
const ORDER: Array[StringName] = [&"pyramid", &"gardens", &"artemis", &"zeus", &"mausoleum", &"colossus", &"lighthouse",
	&"great_wall", &"petra", &"colosseum", &"chichen_itza", &"machu_picchu", &"taj_mahal", &"christ_redeemer",
	&"grand_canyon", &"barrier_reef", &"rio_harbour", &"everest", &"northern_lights", &"paricutin", &"victoria_falls"]

const WONDERS := {
	&"pyramid": {"name": "Great Pyramid of Giza", "short": "Great Pyramid", "place": "Giza, Egypt",
		"built": "about 4,500 years ago", "status": STANDING,
		"sight": "You reached the Great Pyramid of Giza! It is the only one of the Seven Ancient Wonders still standing.",
		"facts": [
			"It was built about 4,500 years ago as the tomb of Khufu, a king of Egypt (a pharaoh).",
			"It was about 146 m tall: for about 3,800 years nothing people built was taller.",
			"It is made of about 2.3 million stone blocks, and its sides face north, south, east and west.",
			"It was once covered in smooth white stone that shone in the sun. Most of it was taken away long ago.",
			"Archaeologists found the town where its workers lived and baked their bread.",
			"Visitors may not climb the real pyramid today: it is protected. Here you may!",
		],
		"quiz": [
			{"id": "pyramid_1", "q": "Who was the Great Pyramid built for?",
				"choices": ["Khufu, a king of Egypt", "Alexander the Great", "A Roman emperor"], "right": 0},
			{"id": "pyramid_2", "q": "Which of the Seven Wonders still stands today?",
				"choices": ["The Colossus of Rhodes", "The Great Pyramid", "The Lighthouse of Alexandria"], "right": 1},
			{"id": "pyramid_3", "q": "What covered the pyramid's sides long ago?",
				"choices": ["Green grass", "Gold paint", "Smooth white stone"], "right": 2},
		],
		"secret": "You found a hidden room! In 2017 scientists found a big hidden space inside the Great Pyramid, using " \
			+ "tiny particles that fall from space. No one knows yet what it was for.",
	},
	&"gardens": {"name": "Hanging Gardens of Babylon", "short": "Hanging Gardens", "place": "Babylon, in today's Iraq",
		"built": "about 2,600 years ago, if they were real", "status": UNKNOWN,
		"sight": "You reached the Hanging Gardens of Babylon! Old writers described them, but no one knows for sure " \
			+ "they were real.",
		"facts": [
			"Greek and Roman writers told of gardens on high terraces in Babylon, with trees growing up high.",
			"A story says King Nebuchadnezzar II built them for his wife, who missed the green hills of her home.",
			"No writing from Babylon itself mentions them, and archaeologists have never found them.",
			"Some scholars think they were really in Nineveh, another city, made by an Assyrian king.",
			"Here they are built as people imagine them: no one knows what they looked like.",
		],
		"quiz": [
			{"id": "gardens_1", "q": "Have archaeologists found the Hanging Gardens?",
				"choices": ["No, not yet", "Yes, in Egypt", "Yes, under the sea"], "right": 0},
			{"id": "gardens_2", "q": "Which river flows through Babylon?",
				"choices": ["The Nile", "The Euphrates", "The Amazon"], "right": 1},
		],
		"secret": "You found a cool room under the gardens! An old writer said water was lifted up to the gardens by " \
			+ "screws turned by people.",
	},
	&"artemis": {"name": "Temple of Artemis at Ephesus", "short": "Temple of Artemis", "place": "Ephesus, in today's Turkey",
		"built": "about 2,550 years ago", "status": GONE,
		"sight": "You reached the Temple of Artemis! The ancient Greeks believed Artemis was the goddess of hunting " \
			+ "and the Moon.",
		"facts": [
			"It was one of the biggest Greek temples, with more than 100 marble columns, each about 18 m tall.",
			"King Croesus helped to pay for it, about 2,550 years ago.",
			"In 356 BC a man burned it down to become famous. The people of Ephesus built it again, even grander.",
			"Raiders wrecked it in AD 262, and later its stones were taken for other buildings.",
			"It is gone: today one column stands there, put back together from old pieces.",
		],
		"quiz": [
			{"id": "artemis_1", "q": "What were the temple's columns made of?",
				"choices": ["Marble", "Wood", "Ice"], "right": 0},
			{"id": "artemis_2", "q": "What stands at the temple's place today?",
				"choices": ["The whole temple", "Only its roof", "One column"], "right": 2},
		],
		"secret": "You found the temple's treasury! People kept their gold safe in the Temple of Artemis: it worked " \
			+ "like a bank.",
	},
	&"zeus": {"name": "Statue of Zeus at Olympia", "short": "Statue of Zeus", "place": "Olympia, Greece",
		"built": "about 2,450 years ago", "status": GONE,
		"sight": "You reached the Statue of Zeus! The ancient Greeks believed Zeus was the king of their gods.",
		"facts": [
			"The sculptor Phidias made it about 2,450 years ago, for the temple at Olympia.",
			"Zeus sat on a throne, about 12 m tall: if he stood up, his head would go through the roof.",
			"Its skin was ivory and its robe was gold, over a frame of wood.",
			"Olympia is where the ancient Olympic Games were held. Winners got a crown of olive leaves.",
			"It is gone: it was lost about 1,500 years ago, probably in a fire.",
		],
		"quiz": [
			{"id": "zeus_1", "q": "What were Zeus's skin and robe made of?",
				"choices": ["Chocolate and silver", "Ivory and gold", "Clay and glass"], "right": 1},
			{"id": "zeus_2", "q": "Which games began at Olympia?",
				"choices": ["The Olympic Games", "Chess", "Football"], "right": 0},
		],
		"secret": "You found Phidias's workshop! In the 1950s archaeologists found his real workshop at Olympia, with " \
			+ "his tools and the clay moulds for Zeus's robe.",
	},
	&"mausoleum": {"name": "Mausoleum at Halicarnassus", "short": "Mausoleum", "place": "Bodrum, in today's Turkey",
		"built": "about 2,370 years ago", "status": GONE,
		"sight": "You reached the Mausoleum! It was a giant tomb for Mausolus, a ruler of Caria, finished by his wife " \
			+ "Artemisia.",
		"facts": [
			"It was about 45 m tall, with 36 columns and a roof shaped like a stepped pyramid.",
			"On its top, four stone horses pulled a chariot.",
			"Our word mausoleum, for a big grand tomb, comes from Mausolus's name.",
			"It is gone: earthquakes broke it, and knights used its stones to build a castle over 500 years ago.",
			"Some of its statues are in a museum in London today.",
		],
		"quiz": [
			{"id": "mausoleum_1", "q": "Which word comes from Mausolus's name?",
				"choices": ["Museum", "Mausoleum", "Mountain"], "right": 1},
			{"id": "mausoleum_2", "q": "What stood on top of the Mausoleum?",
				"choices": ["Four horses pulling a chariot", "A fire", "A garden"], "right": 0},
		],
		"secret": "You found the hidden tomb room! The real one lay under the Mausoleum: knights found it in 1522, when " \
			+ "they took its stones.",
	},
	&"colossus": {"name": "Colossus of Rhodes", "short": "Colossus", "place": "Rhodes, an island of Greece",
		"built": "about 2,300 years ago", "status": GONE,
		"sight": "You reached the Colossus of Rhodes! It was a giant bronze statue of Helios, whom the people of " \
			+ "Rhodes believed was the god of the Sun.",
		"facts": [
			"It was about 33 m tall, as tall as a ten-storey building. Chares of Lindos took 12 years to make it.",
			"It stood only about 54 years: an earthquake knocked it down in 226 BC.",
			"Its pieces lay on the ground for hundreds of years; few people could wrap their arms round its thumb.",
			"Old pictures show it standing over the harbour, but it could not have: it stood with its legs together.",
			"No one knows exactly what it looked like: here it holds up a torch, as many people imagine it.",
		],
		"quiz": [
			{"id": "colossus_1", "q": "What was the Colossus made of?",
				"choices": ["Wood", "Sand", "Bronze"], "right": 2},
			{"id": "colossus_2", "q": "What knocked the Colossus down?",
				"choices": ["An earthquake", "A storm at sea", "An elephant"], "right": 0},
		],
		"secret": "You found buried treasure! The people of Rhodes paid for the Colossus by selling the weapons an " \
			+ "army left behind.",
	},
	&"lighthouse": {"name": "Lighthouse of Alexandria", "short": "Lighthouse", "place": "Alexandria, Egypt",
		"built": "about 2,300 years ago", "status": GONE,
		"sight": "You reached the Lighthouse of Alexandria! It stood on the island of Pharos, joined to the city by a " \
			+ "long causeway.",
		"facts": [
			"It was built about 2,300 years ago and was over 100 m tall: one of the tallest buildings of its time.",
			"It had three parts: a square bottom, an eight-sided middle and a round top.",
			"A fire burned at the top at night so ships could find the harbour.",
			"Its island's name, Pharos, became the word for lighthouse in French, Italian and Spanish.",
			"It is gone: earthquakes broke it. In 1994 divers found its huge stones on the sea floor.",
		],
		"quiz": [
			{"id": "lighthouse_1", "q": "What shone at the top of the lighthouse at night?",
				"choices": ["An electric bulb", "A fire", "A glowing crystal"], "right": 1},
			{"id": "lighthouse_2", "q": "In French, Italian and Spanish, the word for lighthouse comes from...",
				"choices": ["The island of Pharos", "The Moon", "A king's dog"], "right": 0},
		],
		"secret": "You found treasure at the top! The lighthouse's fire could be seen by sailors far out at sea.",
	},
	# --- The second tour: the New Seven Wonders (chosen in 2007), all still standing ---
	&"great_wall": {"name": "Great Wall of China", "short": "Great Wall", "place": "Northern China",
		"built": "over about 2,000 years", "status": STANDING, "tour": &"new",
		"sight": "You reached the Great Wall of China! It runs for thousands of kilometres over mountains and deserts.",
		"facts": [
			"Chinese kingdoms began building walls about 2,700 years ago to guard their northern lands.",
			"Most of the wall people visit today was built of brick and stone by the Ming dynasty (1368 to 1644).",
			"The Ming wall is about 8,850 km long; all of its walls together measure about 21,000 km.",
			"Builders mixed sticky rice into the lime mortar to make it stronger.",
			"You cannot see it from the Moon with your eyes: it is very long, but narrow.",
			"Soldiers, farmers and prisoners were made to build it. The work was hard, and many died.",
		],
		"quiz": [
			{"id": "great_wall_1", "q": "Which dynasty built most of the wall people visit today?",
				"choices": ["The Ming", "The Romans", "The Inca"], "right": 0},
			{"id": "great_wall_2", "q": "Can you see the Great Wall from the Moon with just your eyes?",
				"choices": ["Yes, easily", "Only at night", "No, it is too narrow"], "right": 2},
			{"id": "great_wall_3", "q": "What did builders mix into the mortar to make it stronger?",
				"choices": ["Chocolate", "Sticky rice", "Moon dust"], "right": 1},
		],
		"secret": "You found the watchtower's store room! Guards on the Great Wall sent messages with smoke by day and " \
			+ "fire by night.",
	},
	&"petra": {"name": "Petra", "short": "Petra", "place": "Jordan", "built": "about 2,000 years ago", "status": STANDING,
		"tour": &"new",
		"sight": "You reached Petra! The Nabataeans carved this city's buildings right into the rose-red rock.",
		"facts": [
			"The Nabataeans, Arab traders, made Petra their capital more than 2,000 years ago.",
			"You walk in through the Siq, a narrow gorge about 1.2 km long, only 3 m wide in places.",
			"Its most famous building, the Treasury, is about 39 m tall and was carved out of the cliff.",
			"The Nabataeans built dams, pipes and tanks to catch the rare desert rain.",
			"Its rock is rose-red, so people call Petra the Rose City.",
			"For centuries only people living nearby knew it; a Swiss traveller told Europe about it in 1812.",
		],
		"quiz": [
			{"id": "petra_1", "q": "What were Petra's buildings carved into?",
				"choices": ["Ice", "Rock cliffs", "Tree trunks"], "right": 1},
			{"id": "petra_2", "q": "How do you walk into Petra?",
				"choices": ["Through a narrow gorge", "Over a glass bridge", "Up a long ladder"], "right": 0},
			{"id": "petra_3", "q": "Why is Petra called the Rose City?",
				"choices": ["Roses grow on its walls", "A queen named Rose built it", "Its rock is rose-red"], "right": 2},
		],
		"secret": "You found treasure by the urn! People once thought treasure was hidden in the Treasury's stone urn, " \
			+ "but it is solid rock.",
	},
	&"colosseum": {"name": "Colosseum", "short": "Colosseum", "place": "Rome, Italy", "built": "from AD 70 to 80",
		"status": STANDING, "tour": &"new",
		"sight": "You reached the Colosseum! About 50,000 Romans sat here to watch shows, almost 2,000 years ago.",
		"facts": [
			"Emperor Vespasian began it, and his son Titus opened it in AD 80 with 100 days of games.",
			"It is an oval 189 m long and 48 m tall, built of travertine stone held by iron clamps.",
			"A huge cloth roof could be pulled over the seats to shade the crowd from the sun.",
			"Crowds watched gladiators fight there. Many of them, and many of its builders, were enslaved people.",
			"Earthquakes broke its south side, and people took its stones for other buildings.",
		],
		"quiz": [
			{"id": "colosseum_1", "q": "About how many people could watch shows in the Colosseum?",
				"choices": ["About 500", "About 50,000", "About 5 million"], "right": 1},
			{"id": "colosseum_2", "q": "What shaded the crowd from the sun?",
				"choices": ["A huge cloth roof", "A glass dome", "Tall trees"], "right": 0},
			{"id": "colosseum_3", "q": "What was under the arena's floor?",
				"choices": ["A swimming pool", "Nothing at all", "Tunnels and lifts"], "right": 2},
		],
		"secret": "You found the tunnels under the arena! Lifts once raised scenery and animals up through trapdoors " \
			+ "into the arena.",
	},
	&"chichen_itza": {"name": "Chichen Itza", "short": "Chichen Itza", "place": "Yucatan, Mexico",
		"built": "about 1,000 years ago", "status": STANDING, "tour": &"new",
		"sight": "You reached Chichen Itza! The Maya built this pyramid for Kukulcan, the feathered serpent they " \
			+ "believed was a god.",
		"facts": [
			"The Maya built Chichen Itza, one of their great cities, about 1,000 to 1,400 years ago.",
			"Its pyramid, El Castillo, has 4 stairs of 91 steps: with the top, 365, the days in a year.",
			"In spring and autumn, the evening sun makes a shadow like a snake sliding down its stairs.",
			"If you clap your hands at the foot of its stairs, the echo chirps like a bird.",
			"Its great ball court is 168 m long: players hit a rubber ball with their hips.",
			"Maya people still live in Mexico and Central America today and speak Maya languages.",
		],
		"quiz": [
			{"id": "chichen_itza_1", "q": "Who built Chichen Itza?",
				"choices": ["The Vikings", "The Maya", "The Romans"], "right": 1},
			{"id": "chichen_itza_2", "q": "How many steps are on each of El Castillo's four stairs?",
				"choices": ["91", "7", "1,000"], "right": 0},
			{"id": "chichen_itza_3", "q": "What does the shadow on its stairs look like in spring?",
				"choices": ["A dragon", "A bird", "A snake"], "right": 2},
		],
		"secret": "You found the pyramid inside the pyramid! In the 1930s explorers found an older temple inside, with " \
			+ "a red jaguar throne.",
	},
	&"machu_picchu": {"name": "Machu Picchu", "short": "Machu Picchu", "place": "the Andes, Peru",
		"built": "around 1450", "status": STANDING, "tour": &"new",
		"sight": "You reached Machu Picchu! The Inca built this town high in the Andes mountains, 2,430 m above the sea.",
		"facts": [
			"The Inca built it around 1450, probably for their emperor Pachacuti.",
			"Its stones fit so tightly, without any mortar, that a knife blade cannot slide between them.",
			"Terraces on the steep slopes gave land for farming and kept the mountain from sliding away.",
			"The Inca left it about 100 years later. Spanish conquerors took their empire but never found it.",
			"Local farmers knew it well; after 1911 the whole world heard about it.",
			"Machu Picchu means old peak in Quechua, the Inca's language.",
		],
		"quiz": [
			{"id": "machu_picchu_1", "q": "Who built Machu Picchu?",
				"choices": ["The Inca", "The Egyptians", "The Vikings"], "right": 0},
			{"id": "machu_picchu_2", "q": "What holds its stone walls together?",
				"choices": ["Glue", "Nails", "Nothing: the stones just fit"], "right": 2},
			{"id": "machu_picchu_3", "q": "Why did the Inca build terraces on the mountain?",
				"choices": ["For racing llamas", "For farming on the slopes", "To hide gold"], "right": 1},
		],
		"secret": "You found the cave under the Temple of the Sun! People call it the Royal Tomb, but no one knows for " \
			+ "sure what it was for.",
	},
	&"taj_mahal": {"name": "Taj Mahal", "short": "Taj Mahal", "place": "Agra, India", "built": "from 1632 to 1653",
		"status": STANDING, "tour": &"new",
		"sight": "You reached the Taj Mahal! Emperor Shah Jahan built it of white marble in memory of his wife, " \
			+ "Mumtaz Mahal.",
		"facts": [
			"Mumtaz Mahal died in 1631. Shah Jahan built the Taj Mahal for her from 1632 to 1653.",
			"More than 20,000 workers built it, with white marble brought from Makrana.",
			"Flowers of 28 kinds of coloured stones are set into its marble.",
			"From the ground to the tip of its golden top, it is about 73 m tall.",
			"Its marble seems pink in the morning, white at noon and golden in the moonlight.",
			"Verses from the Quran, the holy book of Islam, are written round its arches.",
		],
		"quiz": [
			{"id": "taj_mahal_1", "q": "Who built the Taj Mahal in memory of his wife?",
				"choices": ["Shah Jahan", "Julius Caesar", "King Arthur"], "right": 0},
			{"id": "taj_mahal_2", "q": "What is the Taj Mahal mostly made of?",
				"choices": ["Red bricks", "White marble", "Wood"], "right": 1},
			{"id": "taj_mahal_3", "q": "What are the flowers on its walls made of?",
				"choices": ["Paint", "Paper", "Coloured stones"], "right": 2},
		],
		"secret": "You found treasure at the top of a minaret! The four minarets lean a little outward, so an " \
			+ "earthquake would topple them away from the tomb.",
	},
	&"christ_redeemer": {"name": "Christ the Redeemer", "short": "Christ the Redeemer",
		"place": "Rio de Janeiro, Brazil", "built": "from 1922 to 1931", "status": STANDING, "tour": &"new",
		"sight": "You reached Christ the Redeemer! It is a statue of Jesus, whom Christians believe is the Son of God.",
		"facts": [
			"It was built from 1922 to 1931 on Corcovado, a mountain 710 m high over Rio de Janeiro.",
			"The statue is 30 m tall and stands on an 8 m base; its arms spread 28 m wide.",
			"It is made of concrete covered with thousands of small tiles of soapstone.",
			"Engineer Heitor da Silva Costa designed it; sculptor Paul Landowski shaped it.",
			"Lightning often strikes it: in 2014 a bolt chipped one of its fingers.",
			"A little train has carried visitors up the mountain since 1884, long before the statue.",
		],
		"quiz": [
			{"id": "christ_redeemer_1", "q": "On which mountain does the statue stand?",
				"choices": ["Mount Everest", "Corcovado", "Mount Fuji"], "right": 1},
			{"id": "christ_redeemer_2", "q": "What covers the statue's concrete?",
				"choices": ["Small soapstone tiles", "Gold", "Moss"], "right": 0},
			{"id": "christ_redeemer_3", "q": "About how wide are its open arms?",
				"choices": ["2 m", "280 m", "28 m"], "right": 2},
		],
		"secret": "You found the door inside the base! Workers climb stairs inside the statue and come out of small " \
			+ "hatches on its arms and head to fix it.",
	},
	# --- The third tour: the Seven Natural Wonders of the World (a list from 1997), made by nature ---
	&"grand_canyon": {"name": "Grand Canyon", "short": "Grand Canyon", "place": "Arizona, USA",
		"formed": "carved over about 5 to 6 million years", "status": NATURAL, "tour": &"nature",
		"sight": "You reached the Grand Canyon! The Colorado River carved it, a little at a time, over millions of years.",
		"facts": [
			"The Colorado River began carving the Grand Canyon about 5 to 6 million years ago, and it is carving it still.",
			"It is 446 km long, up to 29 km wide and more than 1.8 km deep.",
			"Its walls are layers of rock, one on another: the rocks at the bottom are about 2 billion years old.",
			"The rock at its rim formed on the floor of a warm, shallow sea: it holds fossils of sea animals.",
			"Ancestral Puebloans lived here long ago; the Hualapai, the Havasupai and other Native American peoples "
				+ "live here now.",
			"Rare California condors, with wings about 3 m wide, fly over the canyon again.",
		],
		"quiz": [
			{"id": "grand_canyon_1", "q": "What carved the Grand Canyon?",
				"choices": ["A river", "A giant", "An earthquake"], "right": 0},
			{"id": "grand_canyon_2", "q": "How old are the rocks at the bottom of the canyon?",
				"choices": ["About 20 years", "About 2,000 years", "About 2 billion years"], "right": 2},
			{"id": "grand_canyon_3", "q": "What do the sea fossils in the rim's rock tell us?",
				"choices": ["It fell from space", "It was once the floor of a sea", "It is made of ice"], "right": 1},
		],
		"secret": "You found a hidden granary! About 900 years ago, Ancestral Puebloan people stored corn and seeds in " \
			+ "little stone rooms high in the canyon's cliffs.",
	},
	&"barrier_reef": {"name": "Great Barrier Reef", "short": "Great Barrier Reef", "place": "off Queensland, Australia",
		"formed": "built by corals over thousands of years", "status": NATURAL, "tour": &"nature",
		"sight": "You reached the Great Barrier Reef! It is the biggest thing on Earth built by living things: tiny corals.",
		"facts": [
			"It has more than 2,900 reefs and 900 islands along 2,300 km of Australia's coast. It can be seen from space.",
			"Corals are tiny animals related to jellyfish. They build stony skeletons, and their skeletons make the reef.",
			"Tiny algae inside the corals feed them and give them colour. If the sea gets too warm, corals lose them and "
				+ "turn white.",
			"More than 1,500 kinds of fish live here, and six of the world's seven kinds of sea turtles.",
			"Aboriginal and Torres Strait Islander peoples have known and used the reef for thousands of years.",
			"A marine park protects it, and it is a World Heritage Site.",
		],
		"quiz": [
			{"id": "barrier_reef_1", "q": "What builds the Great Barrier Reef?",
				"choices": ["Sharks", "Tiny animals called corals", "Sea turtles"], "right": 1},
			{"id": "barrier_reef_2", "q": "What gives corals their colours?",
				"choices": ["Paint", "The Moon", "Tiny algae living inside them"], "right": 2},
			{"id": "barrier_reef_3", "q": "Along which country's coast is the reef?",
				"choices": ["Australia", "Canada", "Egypt"], "right": 0},
		],
		"secret": "You found a ship's cannon! In 1770 James Cook's ship Endeavour ran onto the reef. Its crew threw six " \
			+ "cannons into the sea to float free, and divers found them in 1969.",
	},
	&"rio_harbour": {"name": "Harbour of Rio de Janeiro", "short": "Harbour of Rio", "place": "Rio de Janeiro, Brazil",
		"formed": "shaped over millions of years", "status": NATURAL, "tour": &"nature",
		"sight": "You reached the Harbour of Rio de Janeiro! Granite mountains like the Sugarloaf stand round its huge bay.",
		"facts": [
			"Its bay, Guanabara Bay, is about 31 km long and 28 km wide, with more than 130 islands.",
			"Portuguese sailors came into the bay on 1 January 1502 and named it Rio de Janeiro: River of January.",
			"Its other name, Guanabara, comes from Tupi, the language of the people who lived on its shores.",
			"The Sugarloaf, 396 m high, stands at the bay's mouth, named after the cone-shaped sugar loaves ships once "
				+ "carried.",
			"Since 1912 a cable car has carried visitors to the top of the Sugarloaf.",
			"Christ the Redeemer looks over the harbour from Corcovado: find it among the New Seven Wonders!",
		],
		"quiz": [
			{"id": "rio_harbour_1", "q": "What does Rio de Janeiro mean?",
				"choices": ["River of January", "City of Sugar", "Green Island"], "right": 0},
			{"id": "rio_harbour_2", "q": "What is the Sugarloaf named after?",
				"choices": ["A birthday cake", "Loaves of sugar", "A sailor"], "right": 1},
			{"id": "rio_harbour_3", "q": "Since 1912, how have visitors gone up the Sugarloaf?",
				"choices": ["By a lift inside it", "By balloon", "By a cable car"], "right": 2},
		],
		"secret": "You found the climbers' ledge! More than 270 climbing routes go up the Sugarloaf and the hills next to it.",
	},
	&"everest": {"name": "Mount Everest", "short": "Mount Everest", "place": "Nepal and China",
		"formed": "pushed up over millions of years", "status": NATURAL, "tour": &"nature",
		"sight": "You reached Mount Everest! At 8,849 m it is the highest mountain on Earth.",
		"facts": [
			"Its top is 8,849 m above the sea: higher than any other mountain on Earth.",
			"It stands between Nepal and China. In Nepali it is called Sagarmatha; in Tibetan, Chomolungma.",
			"It rose when India, moving north, crashed into Asia and crumpled the land into the Himalayas. India is still "
				+ "pushing.",
			"Tenzing Norgay and Edmund Hillary were the first people known to reach its top, on 29 May 1953.",
			"Sherpa people live in the valleys below it, and many of them are expert mountain guides.",
			"Climbers hang prayer flags in five colours: Buddhists believe the wind carries their prayers.",
		],
		"quiz": [
			{"id": "everest_1", "q": "Which is the highest mountain on Earth?",
				"choices": ["Mount Everest", "Corcovado", "Mount Fuji"], "right": 0},
			{"id": "everest_2", "q": "What pushed up the Himalayas?",
				"choices": ["A volcano", "India crashing into Asia", "Giant moles"], "right": 1},
			{"id": "everest_3", "q": "Who were the first people known to reach Everest's top, in 1953?",
				"choices": ["Christopher Columbus", "Two astronauts", "Tenzing Norgay and Edmund Hillary"], "right": 2},
		],
		"secret": "You found a sea fossil on top of the world! The rock at Everest's top formed on the floor of an " \
			+ "ancient sea: it holds fossils of sea animals called trilobites.",
	},
	&"northern_lights": {"name": "Northern Lights", "short": "Northern Lights", "place": "the far north, round the North Pole",
		"formed": "glowing on dark nights", "status": NATURAL, "tour": &"nature",
		"sight": "You reached the land of the Northern Lights! Look up on a dark night: the sky glows green, pink and purple.",
		"facts": [
			"The Sun blows out tiny charged bits, the solar wind. When they crash into the gases high in our air, the gases "
				+ "glow.",
			"Earth's magnetic field steers them toward the North and South Poles, so the lights shine in a ring round each "
				+ "pole.",
			"Oxygen glows green and red, nitrogen blue and purple. Most of the glow is about 100 km up, far higher than "
				+ "planes fly.",
			"You can only see them when the sky is dark: best on long winter nights in Norway, Iceland, Finland, Canada and "
				+ "Alaska.",
			"Galileo called them aurora borealis in 1619, after Aurora, the Roman goddess of dawn, and Boreas, the north "
				+ "wind.",
		],
		"quiz": [
			{"id": "northern_lights_1", "q": "What makes the northern lights glow?",
				"choices": ["Fireflies", "Bits from the Sun hitting our air", "City lights"], "right": 1},
			{"id": "northern_lights_2", "q": "When can you see the northern lights?",
				"choices": ["On dark nights", "At noon", "Only on rainy days"], "right": 0},
			{"id": "northern_lights_3", "q": "Which gas glows green in the northern lights?",
				"choices": ["Helium", "Smoke", "Oxygen"], "right": 2},
		],
		"secret": "You found the ice cave! The same lights shine round the South Pole, where they are called the southern " \
			+ "lights, and Jupiter and Saturn have them too.",
	},
	&"paricutin": {"name": "Parícutin", "short": "Parícutin", "place": "Michoacán, Mexico", "formed": "born in 1943",
		"status": NATURAL, "status_words": "Quiet since 1952: here its crater glows as it did while it grew",
		"tour": &"nature",
		"sight": "You reached Parícutin! This volcano was born in a farmer's cornfield in 1943.",
		"facts": [
			"On 20 February 1943, the ground in Dionisio Pulido's cornfield cracked open and began to puff out smoke and ash.",
			"In one day it grew a cone about 50 m tall. It erupted for nine years, until 1952, and grew 424 m tall.",
			"It was the first time scientists could watch a volcano's whole life, from its birth to its end.",
			"Its lava buried two villages; their people built a new town. San Juan's church tower still stands above the "
				+ "lava.",
			"It is a cinder cone: a hill of bits of lava that cooled in the air and fell round its vent.",
			"It is one of about 1,400 volcanoes and vents in its part of Mexico.",
		],
		"quiz": [
			{"id": "paricutin_1", "q": "Where was Parícutin born?",
				"choices": ["In a cornfield", "Under the sea", "In a city square"], "right": 0},
			{"id": "paricutin_2", "q": "How long did Parícutin erupt?",
				"choices": ["Nine minutes", "Nine years", "Nine hundred years"], "right": 1},
			{"id": "paricutin_3", "q": "What still stands above its lava?",
				"choices": ["A castle", "A lighthouse", "A church tower"], "right": 2},
		],
		"secret": "You found the room in the church tower! The lava flowed into the church of San Juan but left its main " \
			+ "altar standing. People still bring it candles and flowers.",
	},
	&"victoria_falls": {"name": "Victoria Falls", "short": "Victoria Falls", "place": "between Zambia and Zimbabwe",
		"formed": "carved by the Zambezi River", "status": NATURAL, "tour": &"nature",
		"sight": "You reached Victoria Falls! Its Lozi name is Mosi-oa-Tunya: the smoke that thunders.",
		"facts": [
			"The Zambezi River falls 108 m into a deep, narrow chasm, along a line 1,708 m wide.",
			"It is the largest sheet of falling water in the world, counting its width and height together.",
			"Its spray rises over 400 m and can be seen 50 km away. Rainbows shine in it, and at full moon even a moonbow.",
			"The spray falls like rain every day on the rainforest that faces the falls.",
			"The falls cut back into the basalt rock over time: the zigzag gorges below them show where they used to be.",
			"They lie on the border of Zambia and Zimbabwe, and are a World Heritage Site.",
		],
		"quiz": [
			{"id": "victoria_falls_1", "q": "What does Mosi-oa-Tunya mean?",
				"choices": ["The smoke that thunders", "The big river", "The rainbow bridge"], "right": 0},
			{"id": "victoria_falls_2", "q": "Which river falls at Victoria Falls?",
				"choices": ["The Nile", "The Zambezi", "The Amazon"], "right": 1},
			{"id": "victoria_falls_3", "q": "What grows on the cliff facing the falls, watered by the spray?",
				"choices": ["A desert", "An ice field", "A rainforest"], "right": 2},
		],
		"secret": "You found treasure on Livingstone Island! From here in 1855 David Livingstone saw the falls and named " \
			+ "them after Queen Victoria; local people had long known them.",
	},
}


static func has(id: StringName) -> bool:
	return WONDERS.has(id)


## Wonder `id`'s data ({} for none).
static func of(id: StringName) -> Dictionary:
	return WONDERS.get(id, {})


static func display_name(id: StringName) -> String:
	return str(of(id).get("name", ""))


## The wonders whose names take no "the" in a sentence ("Next: Petra", "walk to Machu Picchu", "Mount Everest").
const NO_THE: Array[StringName] = [&"petra", &"chichen_itza", &"machu_picchu", &"christ_redeemer", &"everest",
	&"paricutin", &"victoria_falls"]


## Wonder `id`'s name as a sentence says it: "the Great Wall of China", "Petra".
static func called(id: StringName) -> String:
	return display_name(id) if NO_THE.has(id) else "the " + display_name(id)


static func status(id: StringName) -> StringName:
	return StringName(of(id).get("status", &""))


## What a child reads about whether it still stands (a wonder's own words when it has them: Parícutin's).
static func status_words(id: StringName) -> String:
	if of(id).has("status_words"):
		return str(of(id).status_words)
	match status(id):
		STANDING:
			return "Still standing"
		GONE:
			return "Gone: built here as people believe it looked"
		UNKNOWN:
			return "No one knows for sure it existed"
		NATURAL:
			return "A wonder of nature"
	return ""


## When it was built ("built about 4,500 years ago"), or for nature's wonders how it was formed ("born in 1943").
static func when_words(id: StringName) -> String:
	var f := of(id)
	if f.has("formed"):
		return str(f.formed)
	return "built " + str(f.get("built", ""))


## Every quiz question of the tour, in order ({id, wonder, q, choices, right}).
static func questions() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in ORDER:
		for q: Dictionary in of(id).get("quiz", []):
			var e := q.duplicate()
			e.wonder = id
			out.append(e)
	return out


## The question with this id ({} for none).
static func question(qid: String) -> Dictionary:
	for q in questions():
		if q.id == qid:
			return q
	return {}


# --- The tours ---

## The tour wonder `id` belongs to (&"ancient", &"new" or &"nature"; &"" for none).
static func tour_of(id: StringName) -> StringName:
	if not has(id):
		return &""
	return StringName(of(id).get("tour", &"ancient"))


## The wonders of tour `tour`, in its list's order.
static func tour_ids(tour: StringName) -> Array[StringName]:
	match tour:
		&"ancient":
			return ANCIENT.duplicate()
		&"new":
			return NEW.duplicate()
		&"nature":
			return NATURE.duplicate()
	return [] as Array[StringName]


## Tour `tour`'s data ({name, title, heading, plaque, where, facts}; {} for none).
static func tour_info(tour: StringName) -> Dictionary:
	return TOURS.get(tour, {})


## The tour whose square's plaque has the id `plaque` (&"tour", &"tour_new"), or &"".
static func tour_of_plaque(plaque: StringName) -> StringName:
	for t: StringName in TOUR_IDS:
		if TOURS[t].plaque == plaque:
			return t
	return &""
