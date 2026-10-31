class_name G7HumGen
extends RefCounted
## Owner #70 and #73 (research §6.7): grade 7 history, geography and citizenship generators. History (the early modern
## world): its dates in order and apart, a hand press's sheets and days, mirrored type, the Pole Star's latitude, dead
## reckoning, the Columbian exchange, the Ottoman Empire's three continents, Mughal and Tudor-Stuart reigns, Kepler's
## third law, the scientific method, the spice trade's profit and a company's shares. Geography: plate boundaries,
## earthquake magnitudes, plates drifting, rocks and weathering, glaciers retreating and their landforms, coastal
## landforms, defences and their cost, biomes' climates, energy up a food chain, water used and water for each person,
## places in the Middle East, Russia's time zones, fieldwork averages, predict-protect-prepare. Citizenship (in the
## game's gold): a law's stages and votes, free speech's limits, petitions, a charity's spending, facts and opinions,
## charts with a cut axis, the Global Goals, careers, profit and loss, card interest, spreading savings, kinds of moral
## reasons. SchoolGen "g7h.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded,
## level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for tests/unit/test_g7_hum_gen.gd).
## Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi"]

## The early modern world's dated events, as the lessons give them: [what happened, the year, about?].
const EVENTS: Array = [
	["Jikji is printed in Korea", 1377, false],
	["Zheng He's first voyage", 1405, false],
	["The Forbidden City is finished", 1420, false],
	["Brunelleschi's dome is finished", 1436, false],
	["The Ottomans take Constantinople", 1453, false],
	["The Gutenberg Bible is printed", 1455, true],
	["Caxton prints in England", 1476, false],
	["Columbus crosses the Atlantic", 1492, false],
	["Vasco da Gama reaches India", 1498, false],
	["Michelangelo finishes David", 1504, false],
	["Henry VIII becomes king", 1509, false],
	["Suleiman becomes sultan", 1520, false],
	["Magellan's ship returns", 1522, false],
	["Babur founds the Mughal Empire", 1526, false],
	["Copernicus's book is printed", 1543, false],
	["The Süleymaniye Mosque is finished", 1557, false],
	["Elizabeth I becomes queen", 1558, false],
	["Akbar builds Fatehpur Sikri", 1571, false],
	["The Spanish Armada sails", 1588, false],
	["The English East India Company begins", 1600, false],
	["The Dutch East India Company begins", 1602, false],
	["Tokugawa Ieyasu becomes shogun", 1603, false],
	["Galileo sees Jupiter's moons", 1610, false],
	["Work on the Taj Mahal begins", 1632, false],
	["The English Civil War begins", 1642, false],
	["The Ming dynasty ends", 1644, false],
	["The Royal Society is founded", 1660, false],
	["Newton's Principia is printed", 1687, false],
	["The Bill of Rights", 1689, false],
	["England and Scotland unite", 1707, false],
]
const ANNIVERSARIES: Array[int] = [100, 200, 300, 400, 500, 600]

## Rulers and their reigns [from, to] (the lessons' years).
const TUDORS := {"Henry VII": [1485, 1509], "Henry VIII": [1509, 1547], "Edward VI": [1547, 1553], "Mary I": [1553, 1558],
	"Elizabeth I": [1558, 1603], "James I": [1603, 1625], "Charles I": [1625, 1649], "Charles II": [1660, 1685],
	"James II": [1685, 1688], "Anne": [1702, 1714]}
const MUGHALS := {"Babur": [1526, 1530], "Akbar": [1556, 1605], "Jahangir": [1605, 1627], "Shah Jahan": [1628, 1658],
	"Aurangzeb": [1658, 1707]}

const EXCHANGE := {"potatoes": 0, "tomatoes": 0, "maize": 0, "cacao beans": 0, "chilli peppers": 0, "peanuts": 0,
	"pumpkins": 0, "turkeys": 0, "pineapples": 0, "vanilla": 0, "wheat": 1, "rice": 1, "sugar cane": 1, "coffee": 1,
	"bananas": 1, "oranges": 1, "horses": 1, "cattle": 1, "pigs": 1, "sheep": 1, "chickens": 1}
const EXCHANGE_WAYS: Array[String] = ["from the Americas", "to the Americas"]
const OTTOMAN := {"Edirne": 0, "Sofia": 0, "Belgrade": 0, "Budapest": 0, "Athens": 0, "Sarajevo": 0, "Bursa": 1,
	"Ankara": 1, "Baghdad": 1, "Damascus": 1, "Mecca": 1, "Aleppo": 1, "Cairo": 2, "Alexandria": 2, "Algiers": 2, "Tunis": 2}
const CONTINENTS: Array[String] = ["Europe", "Asia", "Africa"]

const TYPE_LETTERS: Array[String] = ["b", "d", "p", "q"]
const TYPE_WORDS: Array[String] = ["book", "page", "ink", "press", "type", "print", "paper", "news", "bread", "drop",
	"pond", "bed", "map", "word"]
const SET_WORDS: Array[String] = ["BOOK", "NEWS", "INK", "PRESS", "MAP", "PAGE", "TYPE", "WORD", "PRINT", "LORD", "SHIP"]

const PLANETS: Array[String] = ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn"]
const STEPS: Array[String] = ["question", "hypothesis", "experiment", "results", "conclusion"]
## Three investigations, each a statement for every step of the method (in STEPS' order).
const STUDIES: Array = [
	["Do heavy balls fall faster than light ones?", "I think heavy and light balls fall as fast.",
		"Roll a heavy and a light ball down a ramp.", "Both balls reached the bottom together.",
		"Weight does not change how fast they roll."],
	["What are the stars next to Jupiter?", "I predict they are moons going round Jupiter.",
		"Draw Jupiter and the stars every clear night.", "The stars moved from side to side each night.",
		"They are moons orbiting Jupiter."],
	["Does a pendulum's weight change its swing?", "I think only the string's length matters.",
		"Time swings with weights of 1, 2 and 3 blocks.", "Every weight took 2 seconds a swing.",
		"The weight does not change the swing."],
]

const BOUNDARIES := {"the Mid-Atlantic Ridge": 0, "Iceland's rift valley": 0, "the East African Rift": 0,
	"new ocean floor forms": 0, "the Andes": 1, "the Himalayas": 1, "Japan's volcanoes": 1, "a deep ocean trench forms": 1,
	"fold mountains rise": 1, "the San Andreas Fault": 2, "a road is split and moved sideways": 2,
	"the Alpine Fault in New Zealand": 2}
const MOVES: Array[String] = ["moving apart", "moving together", "sliding past"]
const PLATE_RATES: Array[float] = [2.0, 2.5, 4.0, 5.0, 8.0, 10.0]
const ROCK_NAMES := {"granite": 0, "basalt": 0, "pumice": 0, "obsidian": 0, "sandstone": 1, "limestone": 1, "chalk": 1,
	"shale": 1, "conglomerate": 1, "marble": 2, "slate": 2, "schist": 2, "gneiss": 2, "quartzite": 2}
const ROCK_CLUES := {"formed when lava cooled quickly": 0, "big crystals from magma cooling slowly": 0,
	"layers of sand pressed together": 1, "holds fossils of sea shells": 1, "limestone changed by great heat": 2,
	"mudstone squeezed into thin sheets": 2}
const ROCK_KINDS: Array[String] = ["igneous", "sedimentary", "metamorphic"]
const WEATHERING := {"water freezes and splits a rock": 0, "a hot desert rock peels in layers": 0,
	"salt crystals grow in cracks": 0, "rain slowly dissolves limestone": 1, "acid rain wears a statue's face away": 1,
	"iron in a rock turns to rust": 1, "tree roots widen a crack": 2, "rabbits burrow into a slope": 2,
	"lichen slowly breaks down rock": 2}
const WEATHER_KINDS: Array[String] = ["physical", "chemical", "biological"]
const GLACIAL := {"corrie": 0, "arete": 0, "pyramidal peak": 0, "U-shaped valley": 0, "hanging valley": 0,
	"truncated spur": 0, "ribbon lake": 0, "terminal moraine": 1, "lateral moraine": 1, "drumlin": 1, "erratic boulder": 1}
const WORK: Array[String] = ["erosion", "deposition"]
const COAST := {"cave": 0, "arch": 0, "stack": 0, "stump": 0, "cliff": 0, "wave-cut platform": 0, "beach": 1, "spit": 1,
	"bar": 1, "tombolo": 1, "sand dunes": 1}
const DEFENCES := {"sea wall": 0, "groynes": 0, "rock armour": 0, "gabions": 0, "beach nourishment": 1,
	"dune planting": 1, "managed retreat": 1, "salt marsh creation": 1}
const ENGINEERING: Array[String] = ["hard engineering", "soft engineering"]

## Each biome's typical year: [°C a month, mm a month, t_from, t_top, t_step, r_top, r_step, a description].
const BIOMES := {
	"tropical rainforest": [[27, 27, 27, 27, 27, 26, 26, 26, 27, 27, 27, 27], [260, 250, 300, 280, 220, 160, 140, 150,
		180, 220, 240, 270], 0, 40, 10, 400, 100, "Hot all year, about 27 °C, and wet in every month: about 2,700 mm of rain a year."],
	"hot desert": [[14, 17, 21, 26, 30, 33, 34, 33, 30, 25, 19, 15], [8, 6, 4, 2, 0, 0, 0, 0, 0, 1, 4, 7], 0, 40, 10, 40,
		10, "Under 50 mm of rain in a whole year, and summer months over 30 °C."],
	"savanna": [[26, 28, 30, 31, 30, 28, 26, 26, 27, 28, 28, 26], [0, 2, 10, 30, 90, 150, 220, 240, 160, 40, 4, 0], 0, 40,
		10, 300, 75, "Hot all year, with months of almost no rain and then a wet season of heavy storms."],
	"Mediterranean": [[10, 11, 13, 15, 19, 23, 26, 26, 23, 18, 14, 11], [90, 70, 55, 40, 25, 8, 2, 5, 25, 60, 85, 100], 0,
		40, 10, 120, 30, "Hot, dry summers and mild, wet winters, never much below 10 °C."],
	"temperate forest": [[4, 5, 7, 9, 13, 16, 18, 18, 15, 11, 7, 5], [60, 45, 45, 45, 50, 50, 50, 55, 55, 70, 65, 60], 0,
		20, 5, 80, 20, "Mild: about 4 °C in winter and 18 °C in summer, with rain in every month."],
	"taiga": [[-20, -17, -9, 1, 9, 15, 17, 14, 8, 0, -10, -18], [20, 15, 18, 25, 40, 60, 75, 70, 50, 35, 28, 22], -30, 20,
		10, 100, 20, "Long winters down to −20 °C, short summers up to 17 °C, and about 450 mm of rain a year."],
	"tundra": [[-28, -28, -25, -16, -5, 4, 8, 6, 0, -10, -20, -25], [8, 7, 8, 9, 12, 20, 35, 38, 25, 15, 10, 9], -30, 20,
		10, 50, 10, "Below freezing for most of the year, a short summer under 10 °C, and very little rain."],
}
## Pairs too alike to be told apart at level 1.
const BIOME_KIN := {"tropical rainforest": ["savanna"], "savanna": ["tropical rainforest", "hot desert"],
	"hot desert": ["savanna"], "Mediterranean": ["temperate forest"], "temperate forest": ["Mediterranean"],
	"taiga": ["tundra"], "tundra": ["taiga"]}

const MIDEAST := {"Cairo": [30, 31], "Ankara": [40, 33], "Istanbul": [41, 29], "Baghdad": [33, 44], "Tehran": [36, 51],
	"Riyadh": [25, 47], "Muscat": [24, 58], "Mecca": [21, 40], "Amman": [32, 36], "Kuwait City": [29, 48],
	"Doha": [25, 51], "Dubai": [25, 55]}
const MIDEAST_MAP := {"kind": "voyage_map", "window": {"lat": [10, 45], "long": [25, 65]}, "lat_step": 10, "long_step": 15}
## Russia's cities and their clocks (hours ahead of UTC; Russia keeps the same time all year).
const RUSSIA_UTC := {"Kaliningrad": 2, "Moscow": 3, "St Petersburg": 3, "Samara": 4, "Yekaterinburg": 5, "Omsk": 6,
	"Novosibirsk": 7, "Krasnoyarsk": 7, "Irkutsk": 8, "Yakutsk": 9, "Vladivostok": 10, "Magadan": 11, "Kamchatka": 12}

const HAZARD := {"measure a volcano swelling": 0, "check a volcano's gases": 0,
	"record small earthquakes with seismometers": 0, "track a hurricane by satellite": 0,
	"build houses with cross-bracing": 1, "put rubber pads under a building": 1, "build a wall against tsunamis": 1,
	"dig channels to steer lava away": 1, "practise earthquake drills": 2, "pack a kit with water and a torch": 2,
	"plan an escape route and a meeting point": 2, "learn Drop, Cover and Hold On": 2}
const THREE_PS: Array[String] = ["predict", "protect", "prepare"]
## Fieldwork: what was counted or measured at five or seven sites, and its unit.
const SURVEYS: Array = [["Pedestrians counted in 10 minutes", ""], ["River widths", " m"], ["Pieces of litter counted", ""],
	["Cars passing in 5 minutes", ""]]

const STAGES: Array[String] = ["first reading", "second reading", "committee stage", "report stage", "third reading",
	"the other House", "royal assent"]
const SPEECH := {"saying a new law is unfair": 0, "writing that a film was boring": 0,
	"arguing the council made a mistake": 0, "holding a peaceful protest": 0, "sharing an unpopular opinion politely": 0,
	"criticising the government": 0, "threatening to hurt someone": 1, "spreading lies that ruin someone's name": 1,
	"stirring up hatred against a group": 1, "posting someone's private photos": 1, "urging people to attack a shop": 1}
const SPEECH_KINDS: Array[String] = ["free speech", "not protected"]
const FACTS := {"The bridge opened on 3 May.": 0, "The council voted 7 to 2 for the plan.": 0, "The park is 2 km long.": 0,
	"Tickets cost 5 gold.": 0, "The river rose 30 cm overnight.": 0, "The new bridge is ugly.": 1,
	"The plan is a terrible idea.": 1, "It is the best park in the town.": 1, "Tickets are far too expensive.": 1,
	"The shocking plan was passed on Monday.": 2, "A mob gathered outside the hall.": 2,
	"The heroic mayor opened the bridge.": 2}
const CLAIMS: Array[String] = ["fact", "opinion", "loaded words"]
const BAR_NAMES: Array = [["Oak", "River"], ["2025", "2026"], ["Monday", "Tuesday"], ["Team A", "Team B"],
	["North", "South"]]
const SDGS := {1: "No poverty", 2: "Zero hunger", 3: "Good health and well-being", 4: "Quality education",
	5: "Gender equality", 6: "Clean water and sanitation", 7: "Affordable and clean energy",
	8: "Decent work and economic growth", 9: "Industry, innovation and infrastructure", 10: "Reduced inequalities",
	11: "Sustainable cities and communities", 12: "Responsible consumption and production", 13: "Climate action",
	14: "Life below water", 15: "Life on land", 16: "Peace, justice and strong institutions",
	17: "Partnerships for the goals"}
const CAREERS := {"nurse": 0, "teacher": 0, "care worker": 0, "police officer": 0, "social worker": 0, "electrician": 1,
	"mechanic": 1, "carpenter": 1, "plumber": 1, "farmer": 1, "scientist": 2, "programmer": 2, "accountant": 2,
	"researcher": 2, "data analyst": 2}
const WORKS_WITH: Array[String] = ["people", "things and tools", "ideas and data"]
const LIKES: Array[String] = ["helping and talking with people", "fixing and building things with their hands",
	"solving puzzles with numbers and facts"]
const CARDS := {"spends money already in your account": 0, "money leaves your account at once": 0,
	"you can only spend what you have": 0, "borrows money to pay back later": 1,
	"has a spending limit set by the lender": 1, "charges interest if not paid in full": 1}
const CARD_KINDS: Array[String] = ["debit card", "credit card"]
const REASONS := {"Everyone should get the same chance.": 0, "The rule must be the same for everyone.": 0,
	"She did the work, so she gets the credit.": 0, "If we tell now, the problem stops sooner.": 1,
	"More people will be helped this way.": 1, "A lie now could cause bigger trouble later.": 1,
	"He feels left out, so let's include him.": 2, "Think how you would feel in her place.": 2,
	"A friend who is upset needs us to listen.": 2}
const REASON_KINDS: Array[String] = ["fairness", "consequences", "kindness"]


# --- History: the early modern world's dates --------------------------------------------------------------------------

## 3, 4 or 5 of EVENTS in order, earliest first (level + 2).
static func early_modern_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var picks := _pick_any(rng, EVENTS, level + 2)
	picks.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) < int(b[1]))
	var items: Array = []
	var years: Array[String] = []
	for e: Array in picks:
		items.append(_event_text(e))
		years.append(str(e[1]))
	var ex := K.order(rng, "Put these in order, earliest first.", items,
		"Look at the years: the smaller the year, the earlier.", "Earliest first: %s." % ", ".join(years))
	ex.data = {"events": picks.map(func(e: Array) -> String: return str(e[0]))}
	return ex


## Level 1: two events up to 120 years apart; level 2: any two; level 3: an anniversary (a year).
static func early_modern_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var exact: Array = EVENTS.filter(func(e: Array) -> bool: return not bool(e[2]))
	var ex: Dictionary
	if level == 3:
		var e: Array = exact[rng.randi_range(0, exact.size() - 1)]
		var years: Array = ANNIVERSARIES.filter(func(n: int) -> bool: return int(e[1]) + n <= 2025)
		var n: int = years[rng.randi_range(0, years.size() - 1)]
		ex = K.number("%s: %d. In which year was its %s anniversary?" % [e[0], e[1], _ordinal(n)], str(int(e[1]) + n),
			"Add the anniversary's years to the year it happened.", "%d + %d = %d." % [e[1], n, int(e[1]) + n])
		ex.year = true
		ex.data = {"ask": "anniversary", "event": e[0], "years": n}
		return ex
	var a: Array = []
	var b: Array = []
	for _try in 200:
		var two := _pick_any(rng, exact, 2)
		two.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
		a = two[0]
		b = two[1]
		var g := int(b[1]) - int(a[1])
		if g >= 5 and (g <= 120 if level == 1 else g >= 30):
			break
	var gap := int(b[1]) - int(a[1])
	ex = K.number("%s: %d. %s: %d. How many years later was the second?" % [a[0], a[1], b[0], b[1]], str(gap),
		"Take the earlier year from the later one.", "%d − %d = %d years." % [b[1], a[1], gap])
	ex.data = {"ask": "apart", "events": [a[0], b[0]]}
	return ex


## A hand press's work. Level 1: sheets in a day; level 2: days for a book's copies; level 3: the press against a scribe.
static func print_run(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var rate: int = [150, 200, 250, 300][rng.randi_range(0, 3)]
		var hours := rng.randi_range(8, 14)
		ex = K.number("A hand press prints %d sheets an hour. How many sheets does it print in a %d-hour working day?" % [
			rate, hours], str(rate * hours), "Sheets an hour times the hours.",
			"%d × %d = %s sheets." % [rate, hours, K.fmt(rate * hours)])
		ex.data = {"ask": "day", "rate": rate, "hours": hours}
		return ex
	if level == 2:
		var sheets := 0
		var copies := 0
		var per_day := 0
		for _try in 200:
			sheets = [20, 25, 30, 40, 50][rng.randi_range(0, 4)]
			copies = [100, 150, 200, 300][rng.randi_range(0, 3)]
			per_day = [1000, 1500, 2000, 2500, 3000][rng.randi_range(0, 4)]
			if sheets * copies % per_day == 0:
				break
		if sheets * copies % per_day != 0:
			sheets = 30
			copies = 200
			per_day = 2000
		var days := sheets * copies / per_day
		ex = K.number("A book needs %d sheets for each copy. The printer makes %d copies, and the press prints %s sheets a day. How many days does the job take?" % [
			sheets, copies, K.fmt(per_day)], str(days), "First find all the sheets needed, then share them into days.",
			"%d × %d = %s sheets; %s ÷ %s = %d days." % [sheets, copies, K.fmt(sheets * copies), K.fmt(sheets * copies),
			K.fmt(per_day), days])
		ex.data = {"ask": "days", "sheets": sheets, "copies": copies, "per_day": per_day}
		return ex
	var scribe := 0
	var press := 0
	for _try in 200:
		scribe = rng.randi_range(2, 6)
		press = [1200, 1800, 2400, 3000, 3600][rng.randi_range(0, 4)]
		if press % scribe == 0:
			break
	ex = K.number("A scribe copies %d pages a day by hand. A hand press prints %s pages a day. How many times as many pages does the press make?" % [
		scribe, K.fmt(press)], str(press / scribe), "Divide the press's pages by the scribe's.",
		"%s ÷ %d = %s times as many." % [K.fmt(press), scribe, K.fmt(press / scribe)])
	ex.data = {"ask": "faster", "scribe": scribe, "press": press}
	return ex


## Type is a mirror of the page. Level 1: which small letter a piece prints; level 2: which word a line prints; level 3:
## the order of a word's letters in the forme.
static func mirror_type(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var word := TYPE_LETTERS[rng.randi_range(0, 3)] if level == 1 else TYPE_WORDS[rng.randi_range(0, TYPE_WORDS.size() - 1)]
		var wrongs: Array = []
		if level == 1:
			wrongs = TYPE_LETTERS.filter(func(x: String) -> bool: return x != word)
		else:
			for w: String in [word.reverse(), _flip_letters(word), _flip_letters(word).reverse(), word.substr(1) + word[0]]:
				if w != word and not wrongs.has(w):
					wrongs.append(w)
			wrongs = wrongs.slice(0, 3)
		ex = K.choice(rng, "Which %s will this %s print?" % ["letter" if level == 1 else "word",
			"piece of type" if level == 1 else "line of type"], word, wrongs,
			"Type is a mirror of the page: imagine the letters flipped left to right, and read the line from the other end.",
			"Flipped and read the other way, the type prints “%s”." % word,
			{"kind": "hand_press", "view": "type", "word": word, "print": false})
		ex.data = {"ask": "letter" if level == 1 else "word", "word": word}
		return ex
	var up := SET_WORDS[rng.randi_range(0, SET_WORDS.size() - 1)]
	var in_forme := _letters(up.reverse())
	var wrongs: Array = []
	for w: String in [up, up.substr(1) + up[0], up.reverse().substr(1) + up.reverse()[0]]:
		var t := _letters(w)
		if t != in_forme and not wrongs.has(t):
			wrongs.append(t)
	ex = K.choice(rng, "A printer sets the word %s in type. Looking down at the type, which order are its letters in, from left to right?" % up,
		in_forme, wrongs, "The type is a mirror of the page, so the word runs the other way.",
		"%s is set backwards, each letter flipped: %s." % [up, in_forme])
	ex.data = {"ask": "set", "word": up}
	return ex


# --- History: voyages -------------------------------------------------------------------------------------------------

## In the northern hemisphere the Pole Star's height above the horizon is the latitude. Level 1: read it; level 2:
## degrees sailed north; level 3: about how many km (111 km a degree).
static func pole_star_latitude(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var angle := rng.randi_range(15, 70)
		if angle == 45:
			angle = 46
		ex = K.choice(rng, "A sailor measures how high the Pole Star stands above the horizon. What is the ship's latitude?",
			"%d° N" % angle, ["%d° N" % (90 - angle), "%d° S" % angle, "%d° N" % (angle + 10)],
			"The Pole Star's height above the horizon is the same as your latitude north.",
			"The star is %d° above the horizon, so the ship is at %d° N." % [angle, angle],
			{"kind": "pole_star", "angle": angle, "labels": true})
		ex.data = {"ask": "read", "angle": angle}
		return ex
	var from := rng.randi_range(20, 45)
	var to := from + rng.randi_range(4, 15)
	var diff := to - from
	if level == 2:
		ex = K.number("Leaving port, a sailor measured the Pole Star %d° above the horizon. Weeks later it stood %d° high. How many degrees of latitude north has the ship sailed?" % [
			from, to], str(diff), "Each angle is a latitude: take one from the other.", "%d − %d = %d degrees north." % [
			to, from, diff])
		ex.data = {"ask": "sailed", "from": from, "to": to}
		return ex
	ex = K.number("A ship's Pole Star rose from %d° to %d° above the horizon. Each degree of latitude is about 111 km. About how many km north did it sail?" % [
		from, to], str(diff * 111), "Find the degrees sailed, then multiply by 111.",
		"%d − %d = %d degrees; %d × 111 = %s km." % [to, from, diff, diff, K.fmt(diff * 111)])
	ex.data = {"ask": "km", "from": from, "to": to}
	return ex


## Dead reckoning: speed × time. Level 1: the distance; level 2: the hours; level 3: days sailing day and night.
static func dead_reckoning(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var speed := rng.randi_range(4, 12)
	var ex: Dictionary
	if level == 1:
		var hours := rng.randi_range(3, 12)
		ex = K.number("A caravel sails at %d km an hour for %d hours on the same course. How far does it go, in km?" % [speed,
			hours], str(speed * hours), "Distance is speed times time.", "%d × %d = %d km." % [speed, hours, speed * hours])
		ex.data = {"ask": "distance", "speed": speed, "hours": hours}
		return ex
	if level == 2:
		var hours := rng.randi_range(6, 30)
		ex = K.number("At %d km an hour, how many hours does a ship take to sail %d km?" % [speed, speed * hours], str(hours),
			"Time is the distance divided by the speed.", "%d ÷ %d = %d hours." % [speed * hours, speed, hours])
		ex.data = {"ask": "hours", "speed": speed, "km": speed * hours}
		return ex
	var days := rng.randi_range(5, 40)
	var km := speed * 24 * days
	ex = K.number("A ship sails day and night at %d km an hour. How many days does it take to cross %s km of ocean?" % [speed,
		K.fmt(km)], str(days), "Find how far it sails in a day of 24 hours first.",
		"%d × 24 = %d km a day; %s ÷ %d = %d days." % [speed, speed * 24, K.fmt(km), speed * 24, days])
	ex.data = {"ask": "days", "speed": speed, "km": km}
	return ex


static func exchange_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, EXCHANGE, EXCHANGE_WAYS, "After 1492, which way did %s cross the Atlantic?",
		"Sort these: which way did they cross the Atlantic after 1492?",
		"Think where each first grew or lived: in the Americas, or in Europe, Africa and Asia.")


static func ottoman_continents(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, OTTOMAN, CONTINENTS, "The Ottoman Empire at its greatest held %s. Which continent is it in?",
		"Sort these cities of the Ottoman Empire by continent.",
		"Istanbul sits where Europe meets Asia: Europe lies to its north-west, Asia to its east, and Africa across the sea to the south.")


# --- History: rulers --------------------------------------------------------------------------------------------------

static func mughal_reigns(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _reigns(rng, level, MUGHALS, "Mughal emperors")


static func tudor_reigns(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _reigns(rng, level, TUDORS, "Tudor and Stuart monarchs")


## Level 1: a reign's length; level 2: the longest of three; level 3: who ruled in a year.
static func _reigns(rng: RandomNumberGenerator, level: int, table: Dictionary, who: String) -> Dictionary:
	var names: Array = table.keys()
	var ex: Dictionary
	if level == 1:
		var n: String = names[rng.randi_range(0, names.size() - 1)]
		var r: Array = table[n]
		ex = K.number("%s ruled from %d to %d. For how many years?" % [n, r[0], r[1]], str(int(r[1]) - int(r[0])),
			"Take the first year from the last.", "%d − %d = %d years." % [r[1], r[0], int(r[1]) - int(r[0])])
		ex.data = {"ask": "length", "ruler": n}
		return ex
	if level == 2:
		var three: Array = []
		for _try in 200:
			three = _pick_any(rng, names, 3)
			var lengths := {}
			for n: Variant in three:
				lengths[int(table[n][1]) - int(table[n][0])] = true
			if lengths.size() == 3:
				break
		var best: String = three[0]
		var words: Array[String] = []
		for n: Variant in three:
			var r: Array = table[n]
			words.append("%s %d − %d = %d" % [n, r[1], r[0], int(r[1]) - int(r[0])])
			if int(r[1]) - int(r[0]) > int(table[best][1]) - int(table[best][0]):
				best = str(n)
		var lines: Array[String] = []
		for n: Variant in three:
			lines.append("%s %d-%d" % [n, table[n][0], table[n][1]])
		ex = K.choice(rng, "Which of these %s ruled for the longest? %s." % [who, "; ".join(lines)], best,
			three.filter(func(n: Variant) -> bool: return str(n) != best), "Work out each reign's length: last year − first year.",
			"%s. The longest: %s." % ["; ".join(words), best])
		ex.data = {"ask": "longest", "rulers": three}
		return ex
	var four := _pick_any(rng, names, mini(4, names.size()))
	var ruler: String = four[rng.randi_range(0, four.size() - 1)]
	var r: Array = table[ruler]
	var year := rng.randi_range(int(r[0]) + 1, int(r[1]) - 1) if int(r[1]) - int(r[0]) > 1 else int(r[0])
	var lines: Array[String] = []
	for n: Variant in four:
		lines.append("%s %d-%d" % [n, table[n][0], table[n][1]])
	ex = K.choice(rng, "Who was ruling in %d? %s." % [year, "; ".join(lines)], ruler,
		four.filter(func(n: Variant) -> bool: return str(n) != ruler), "Find the reign whose first and last years are either side of it.",
		"%s ruled from %d to %d, and %d comes between them." % [ruler, r[0], r[1], year])
	ex.data = {"ask": "when", "rulers": four, "year": year}
	return ex


# --- History: the Scientific Revolution -------------------------------------------------------------------------------

## Kepler's third law in Earth's years and distances (years × years = distance × distance × distance). Level 1: the
## further, the longer; level 2: a planet's year from its distance; level 3: its distance from its year.
static func kepler_orbit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var law := "Kepler's law: years² = distance³ (in Earth years and Earth distances)."
	if level == 1:
		var three := _pick_any(rng, PLANETS, 3)
		var far := -1
		for p: Variant in three:
			far = maxi(far, PLANETS.find(str(p)))
		ex = K.choice(rng, "Kepler showed that planets further from the Sun take longer to go round it. Which of these takes the longest?",
			PLANETS[far], three.filter(func(p: Variant) -> bool: return str(p) != PLANETS[far]),
			"Which of them is furthest from the Sun?", "From the Sun: %s. The furthest, %s, takes the longest." % [
			", ".join(PLANETS), PLANETS[far]])
		ex.data = {"ask": "longest", "planets": three}
		return ex
	if level == 2:
		var a: int = [4, 9, 16, 25, 36][rng.randi_range(0, 4)]
		var t := int(round(sqrt(pow(a, 3))))
		ex = K.number("%s A planet is %d times as far from the Sun as Earth. How many years does it take to go round?" % [law, a],
			str(t), "Work out the distance cubed (× itself three times), then find the number that times itself makes it.",
			"%d × %d × %d = %d, and %d × %d = %d, so %d years." % [a, a, a, a * a * a, t, t, t * t, t])
		ex.data = {"ask": "years", "a": a}
		return ex
	var y: int = [8, 27, 64, 125, 216][rng.randi_range(0, 4)]
	var d := int(round(pow(y, 2.0 / 3.0)))
	ex = K.number("%s A planet takes %d years to go round the Sun. How many times Earth's distance is it from the Sun?" % [law, y],
		str(d), "Work out the years squared (× itself), then find the number that cubed makes it.",
		"%d × %d = %s, and %d × %d × %d = %s, so %d times as far." % [y, y, K.fmt(y * y), d, d, d, K.fmt(d * d * d), d])
	ex.data = {"ask": "distance", "t": y}
	return ex


## Level 1: a statement's step, of three; level 2: of all five; level 3: an investigation in the method's order.
static func method_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var study: Array = STUDIES[rng.randi_range(0, STUDIES.size() - 1)]
	var ex: Dictionary
	if level == 3:
		ex = K.order(rng, "Put this investigation in the scientific method's order.", study,
			"First a question, then a guess to test, then the test, what happened, and what it shows.",
			"Question, hypothesis, experiment, results, conclusion: %s" % " ".join(study))
		if str(ex.explain).length() > 260:
			ex.explain = "Question, hypothesis, experiment, results, conclusion: from “%s” to “%s”" % [study[0], study[4]]
		ex.data = {"ask": "order"}
		return ex
	var k := rng.randi_range(0, 4)
	var statement: String = study[k]
	var wrongs: Array = STEPS.filter(func(s: String) -> bool: return s != STEPS[k])
	K.shuffle(rng, wrongs)
	if level == 1:
		wrongs = wrongs.slice(0, 2)
	ex = K.choice(rng, "Which step of the scientific method is this? “%s”" % statement, STEPS[k], wrongs,
		"A question asks; a hypothesis guesses what will happen; an experiment tests; results are what happened; a conclusion says what it shows.",
		"“%s” belongs to the %s step." % [statement.trim_suffix(".").trim_suffix("?") + ("?" if statement.ends_with("?") else ""),
		STEPS[k]])
	ex.data = {"ask": "step", "statement": statement}
	return ex


# --- History: trade -----------------------------------------------------------------------------------------------------

## Level 1: profit on a sack; level 2: a voyage's profit; level 3: the profit as a percentage of all spent.
static func spice_profit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var buy := rng.randi_range(2, 9)
	var sell := rng.randi_range(4, 12) * 5
	if level == 1:
		ex = K.number("A merchant buys pepper in Calicut for %d gold a sack and sells it in Lisbon for %d gold a sack. What is the profit on each sack, before the voyage's costs?" % [
			buy, sell], str(sell - buy), "Take the buying price from the selling price.", "%d − %d = %d gold a sack." % [sell,
			buy, sell - buy])
		ex.data = {"ask": "sack", "buy": buy, "sell": sell}
		return ex
	var sacks := 0
	var costs := 0
	for _try in 400:
		buy = rng.randi_range(2, 9)
		sell = rng.randi_range(4, 12) * 5
		sacks = [50, 100, 150, 200][rng.randi_range(0, 3)]
		costs = rng.randi_range(2, 12) * 250
		var profit := sacks * (sell - buy) - costs
		if profit > 0 and (level == 2 or profit * 100 % (sacks * buy + costs) == 0):
			break
	if level == 3 and (sacks * (sell - buy) - costs) * 100 % (sacks * buy + costs) != 0:
		buy = 5
		sell = 30
		sacks = 100
		costs = 500
	var profit := sacks * (sell - buy) - costs
	if level == 2:
		ex = K.number("A merchant buys %d sacks of pepper at %d gold and sells them at %d gold each. The voyage costs %s gold. What is her profit?" % [
			sacks, buy, sell, K.fmt(costs)], str(profit), "Find the profit on the sacks, then take away the voyage's costs.",
			"%d × (%d − %d) = %s; %s − %s = %s gold." % [sacks, sell, buy, K.fmt(sacks * (sell - buy)),
			K.fmt(sacks * (sell - buy)), K.fmt(costs), K.fmt(profit)])
		ex.data = {"ask": "profit", "sacks": sacks, "buy": buy, "sell": sell, "costs": costs}
		return ex
	var spent := sacks * buy + costs
	ex = K.number("A merchant buys %d sacks of pepper at %d gold, sells them at %d gold each, and the voyage costs %s gold. What is her profit as a percentage of all she spent?" % [
		sacks, buy, sell, K.fmt(costs)], str(profit * 100 / spent), "Profit ÷ all she spent × 100.",
		"Spent %s + %s = %s; profit %s; %s ÷ %s × 100 = %d%%." % [K.fmt(sacks * buy), K.fmt(costs), K.fmt(spent),
		K.fmt(profit), K.fmt(profit), K.fmt(spent), profit * 100 / spent])
	ex.data = {"ask": "percent", "sacks": sacks, "buy": buy, "sell": sell, "costs": costs}
	return ex


## A joint-stock company shares its profit by shares. Level 1: per share; level 2: for someone's shares; level 3: how
## many shares.
static func joint_stock(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var shares: int = [100, 200, 250, 400, 500, 1000][rng.randi_range(0, 5)]
	var per := rng.randi_range(2, 60)
	var who := PEOPLE[rng.randi_range(0, 3)]
	var ex: Dictionary
	if level == 1:
		ex = K.number("A trading company has %s shares. It shares out %s gold of profit equally. How much does each share get?" % [
			K.fmt(shares), K.fmt(shares * per)], str(per), "Share the profit equally: divide by the number of shares.",
			"%s ÷ %s = %d gold a share." % [K.fmt(shares * per), K.fmt(shares), per])
		ex.data = {"ask": "per_share", "shares": shares, "profit": shares * per}
		return ex
	if level == 2:
		var owned := rng.randi_range(2, 30)
		ex = K.number("A company with %s shares shares out %s gold of profit. %s owns %d shares. How much does %s get?" % [
			K.fmt(shares), K.fmt(shares * per), who, owned, who], str(per * owned),
			"Find what one share gets, then multiply by the shares owned.",
			"%s ÷ %s = %d a share; %d × %d = %s gold." % [K.fmt(shares * per), K.fmt(shares), per, per, owned, K.fmt(per * owned)])
		ex.data = {"ask": "owned", "shares": shares, "profit": shares * per, "owned": owned}
		return ex
	ex = K.number("A company paid out %s gold of profit: %d gold for every share. How many shares are there?" % [
		K.fmt(shares * per), per], str(shares), "How many lots of the gold a share fit into all the gold?",
		"%s ÷ %d = %s shares." % [K.fmt(shares * per), per, K.fmt(shares)])
	ex.data = {"ask": "shares", "paid": shares * per, "per": per}
	return ex


# --- Geography: plates and hazards ------------------------------------------------------------------------------------

static func boundary_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, BOUNDARIES, MOVES, "Which way are the plates moving here: %s?",
		"Sort these by how the plates move.",
		"Apart: new crust fills the gap. Together: one plate sinks or the land crumples. Sliding past: the ground is torn sideways.")


## Each whole step of magnitude: 10 times the shaking, about 32 times the energy. Level 1: one step's shaking; level 2:
## two or three steps' shaking; level 3: one or two steps' energy.
static func quake_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var m1 := rng.randi_range(40, 66) / 10.0
	var steps := 1 if level == 1 else rng.randi_range(2, 3) if level == 2 else rng.randi_range(1, 2)
	var m2 := m1 + steps
	var ex: Dictionary
	var hint := "Each whole step up the magnitude scale is 10 times the shaking and about 32 times the energy."
	if level == 1:
		ex = K.choice(rng, "How many times more ground shaking does a magnitude %.1f earthquake cause than a magnitude %.1f one?" % [
			m2, m1], "10 times", ["2 times", "100 times", "32 times"], hint, "%.1f is one whole step above %.1f: 10 times the shaking." % [
			m2, m1])
		ex.data = {"ask": "shaking", "m1": m1, "m2": m2}
		return ex
	if level == 2:
		var times := int(pow(10, steps))
		ex = K.number("How many times more ground shaking does a magnitude %.1f earthquake cause than a magnitude %.1f one?" % [
			m2, m1], str(times), hint, "%d whole steps: %s = %s times the shaking." % [steps,
			"10 × 10" if steps == 2 else "10 × 10 × 10", K.fmt(times)])
		ex.data = {"ask": "shaking", "m1": m1, "m2": m2}
		return ex
	var right := "about 32 times" if steps == 1 else "about 1,000 times"
	ex = K.choice(rng, "About how many times more energy does a magnitude %.1f earthquake release than a magnitude %.1f one?" % [
		m2, m1], right, ["about 10 times", "about 100 times", "about 2 times", "about 32 times", "about 1,000 times"].filter(
		func(w: String) -> bool: return w != right).slice(0, 3), hint,
		"One step" + (": about 32 times the energy." if steps == 1 else "s: 32 × 32 = 1,024, about 1,000 times the energy."))
	ex.data = {"ask": "energy", "m1": m1, "m2": m2}
	return ex


## Plates move a few cm a year. Level 1: metres in some years; level 2: km in millions of years; level 3: years for km.
static func plate_drift(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var cm := PLATE_RATES[rng.randi_range(0, PLATE_RATES.size() - 1)]
	var ex: Dictionary
	var hint := "100 cm make 1 m, and 100,000 cm make 1 km."
	if level == 1:
		var years: int = [100, 200, 400, 1000][rng.randi_range(0, 3)]
		var metres := cm * years / 100.0
		ex = K.number("A plate moves %s cm a year. How many metres does it move in %s years?" % [_num(cm), K.fmt(years)],
			_ans(metres), hint, "%s × %s = %s cm = %s m." % [_num(cm), K.fmt(years), _num(cm * years), _num(metres)])
		ex.data = {"ask": "metres", "cm": cm, "years": years}
		return ex
	if level == 2:
		var millions: int = [1, 2, 3, 5, 10][rng.randi_range(0, 4)]
		var km := cm * 10.0 * millions
		ex = K.number("A plate moves %s cm a year. How many km does it move in %s million years?" % [_num(cm), millions],
			_ans(km), hint, "In a million years: %s × 1,000,000 cm = %s km; × %d = %s km." % [_num(cm), _num(cm * 10.0),
			millions, _num(km)])
		ex.data = {"ask": "km", "cm": cm, "millions": millions}
		return ex
	var km: int = [1, 2, 5, 10][rng.randi_range(0, 3)]
	var years := km * 100000.0 / cm
	ex = K.number("The ocean between two plates widens %s cm a year. How many years does it take to widen %d km?" % [_num(cm), km],
		_ans(years), hint, "%d km = %s cm; %s ÷ %s = %s years." % [km, K.fmt(km * 100000), K.fmt(km * 100000), _num(cm),
		_num(years)])
	ex.data = {"ask": "years", "cm": cm, "km": km}
	return ex


static func hazard_plan(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, HAZARD, THREE_PS, "Is this a way to predict, protect or prepare: %s?",
		"Sort these: predict, protect or prepare?",
		"Predict: watch for warning signs. Protect: build to resist it. Prepare: plan what people will do.")


# --- Geography: rocks, glaciers, coasts -------------------------------------------------------------------------------

## Level 1: a rock's kind; level 2: four rocks sorted; level 3: rocks and clues about how they formed.
static func rock_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hint := "Igneous rocks cooled from melted rock; sedimentary rocks are layers pressed together; metamorphic rocks were changed by heat and pressure."
	if level < 3:
		return _sorter(rng, level, ROCK_NAMES, ROCK_KINDS, "What kind of rock is %s?", "Sort these rocks.", hint)
	var table := ROCK_NAMES.duplicate()
	table.merge(ROCK_CLUES)
	var items: Array = []
	for _try in 100:
		items = _pick_any(rng, ROCK_CLUES.keys(), 2) + _pick_any(rng, ROCK_NAMES.keys(), 3)
		var used := {}
		for it: Variant in items:
			used[int(table[it])] = true
		if used.size() == 3:
			break
	return _sort_ex(rng, "Sort these rocks and clues by the kind of rock.", table, ROCK_KINDS, items, hint)


static func weathering_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, WEATHERING, WEATHER_KINDS, "Which kind of weathering is this: %s?",
		"Sort these kinds of weathering.",
		"Physical: forces break the rock. Chemical: the rock itself changes or dissolves. Biological: living things do it.")


## A glacier's end (its snout) seen from a hut. Level 1: metres retreated; level 2: metres a year; level 3: years to a
## further point.
static func glacier_retreat(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var span: int = [20, 25, 30, 40, 50][rng.randi_range(0, 4)]
	var y0 := rng.randi_range(1950, 2025 - span) / 5 * 5   # both years have been
	var rate := rng.randi_range(1, 8) * 5
	var d0 := rng.randi_range(2, 12) * 50
	var d1 := d0 + rate * span
	var ex: Dictionary
	if level < 3:
		var ask := "In %d a glacier's end (its snout) was %s m from a hut. In %d it was %s m from the hut." % [y0, K.fmt(d0),
			y0 + span, K.fmt(d1)]
		if level == 1:
			ex = K.number(ask + " How many metres did the glacier retreat?", str(d1 - d0),
				"Take the first distance from the second.", "%s − %s = %s m." % [K.fmt(d1), K.fmt(d0), K.fmt(d1 - d0)])
			ex.data = {"ask": "metres", "y0": y0, "y1": y0 + span, "d0": d0, "d1": d1}
		else:
			ex = K.number(ask + " On average, how many metres did it retreat each year?", str(rate),
				"Divide the metres it retreated by the years between.", "%s − %s = %s m in %d − %d = %d years; %s ÷ %d = %d m a year." % [
				K.fmt(d1), K.fmt(d0), K.fmt(d1 - d0), y0 + span, y0, span, K.fmt(d1 - d0), span, rate])
			ex.data = {"ask": "rate", "y0": y0, "y1": y0 + span, "d0": d0, "d1": d1}
		return ex
	var more := rng.randi_range(2, 20)
	var target := d1 + rate * more
	ex = K.number("A glacier's end is %s m from a hut and retreats %d m a year. At that rate, how many years until it is %s m from the hut?" % [
		K.fmt(d1), rate, K.fmt(target)], str(more), "Find how much further it must retreat, then divide by the metres a year.",
		"%s − %s = %s m; %s ÷ %d = %d years." % [K.fmt(target), K.fmt(d1), K.fmt(target - d1), K.fmt(target - d1), rate, more])
	ex.data = {"ask": "years", "d0": d0, "d1": d1, "rate": rate, "target": target}
	return ex


static func glacial_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, GLACIAL, WORK, "Was the %s made by a glacier's erosion or its deposition?",
		"Sort these glacial landforms: made by erosion or by deposition?",
		"Erosion carves hollows, ridges and valleys; deposition drops the rock the ice carried.")


## Level 1: a coastal landform's work; level 2: four landforms sorted; level 3: defences, hard or soft.
static func coast_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		ex = _sorter(rng, level, COAST, WORK, "Is a %s made by the sea's erosion or its deposition?",
			"Sort these coastal landforms: erosion or deposition?",
			"Erosion wears the land away into shapes; deposition builds new land from sand and pebbles.")
		ex.data.ask = "landforms"
		return ex
	var items: Array = []
	for _try in 100:
		items = _pick_any(rng, DEFENCES.keys(), 5)
		var used := {}
		for it: Variant in items:
			used[int(DEFENCES[it])] = true
		if used.size() == 2:
			break
	ex = _sort_ex(rng, "Sort these ways to protect a coast: hard or soft engineering?", DEFENCES, ENGINEERING, items,
		"Hard engineering builds strong structures against the sea; soft engineering works with nature.")
	ex.data.ask = "defences"
	return ex


## Level 1: a defence's cost; level 2: the saving from a cheaper defence; level 3: gold protected for each gold spent.
static func defence_cost(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var metres: int = [50, 100, 150, 200, 300, 400][rng.randi_range(0, 5)]
	if level == 1:
		var per_m: int = [2000, 2500, 3000, 4000, 5000, 6000][rng.randi_range(0, 5)]
		ex = K.number("A new sea wall costs %s gold a metre. How much does %d m of wall cost?" % [K.fmt(per_m), metres],
			str(per_m * metres), "Multiply the cost of a metre by the metres.", "%s × %d = %s gold." % [K.fmt(per_m), metres,
			K.fmt(per_m * metres)])
		ex.data = {"ask": "cost", "per_m": per_m, "metres": metres}
		return ex
	if level == 2:
		var armour: int = [1000, 1500, 2000, 2500][rng.randi_range(0, 3)]
		var wall: int = armour + [1000, 2000, 3000, 4000][rng.randi_range(0, 3)]
		ex = K.number("Rock armour costs %s gold a metre; a sea wall costs %s gold a metre. How much is saved by using rock armour along %d m?" % [
			K.fmt(armour), K.fmt(wall), metres], str((wall - armour) * metres), "Find the saving on each metre first.",
			"%s − %s = %s a metre; × %d = %s gold." % [K.fmt(wall), K.fmt(armour), K.fmt(wall - armour), metres,
			K.fmt((wall - armour) * metres)])
		ex.data = {"ask": "saved", "armour": armour, "wall": wall, "metres": metres}
		return ex
	var cost := rng.randi_range(1, 9) * 100000
	var k := rng.randi_range(2, 12)
	ex = K.number("A scheme costs %s gold and protects homes and land worth %s gold. For every gold spent, how many gold of homes and land are protected?" % [
		K.fmt(cost), K.fmt(cost * k)], str(k), "Divide what is protected by what it costs.", "%s ÷ %s = %d." % [K.fmt(cost * k),
		K.fmt(cost), k])
	ex.data = {"ask": "ratio", "cost": cost, "value": cost * k}
	return ex


# --- Geography: ecosystems and water ----------------------------------------------------------------------------------

## Level 1: a climate graph and three biomes that are easy to tell apart; level 2: four; level 3: a description.
static func biome_climate(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = BIOMES.keys()
	var biome: String = names[rng.randi_range(0, names.size() - 1)]
	var b: Array = BIOMES[biome]
	var others: Array = names.filter(func(n: Variant) -> bool: return str(n) != biome and (level > 1 or
		not (BIOME_KIN[biome] as Array).has(n)))
	K.shuffle(rng, others)
	var hint := "Look at how hot it is and how much rain falls, and whether they change through the year."
	var ex: Dictionary
	if level < 3:
		var pic := {"kind": "climograph", "temp": b[0], "rain": b[1], "t_top": b[3], "t_step": b[4], "r_top": b[5],
			"r_step": b[6]}
		if int(b[2]) != 0:
			pic.t_from = b[2]
		ex = K.choice(rng, "Which ecosystem most likely has this climate?", biome, others.slice(0, 2 if level == 1 else 3), hint,
			"%s: %s" % [_cap(biome), _uncap(str(b[7]))], pic)
	else:
		ex = K.choice(rng, "Which ecosystem has this climate? %s" % b[7], biome, others.slice(0, 3), hint,
			"%s: %s" % [_cap(biome), _uncap(str(b[7]))])
	ex.data = {"ask": "biome", "biome": biome}
	return ex


## About a tenth of the energy passes up each step of a food chain. Level 1: one step; level 2: two; level 3: back down
## from an owl.
static func energy_pyramid(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var hint := "About a tenth passes up each step: divide by 10 for every step up, multiply by 10 for every step down."
	if level < 3:
		var energy := rng.randi_range(2, 90) * (1000 if level == 1 else 100) * (10 if level == 2 else 1)
		var steps := level
		var got := energy / int(pow(10, steps))
		ex = K.number("Grass stores %s units of energy. About a tenth passes up each step of a food chain. About how many units reach the %s?" % [
			K.fmt(energy), "rabbits that eat it" if level == 1 else "foxes that eat the rabbits"], str(got), hint,
			"%s ÷ %s = %s units." % [K.fmt(energy), "10" if steps == 1 else "10 ÷ 10", K.fmt(got)])
		ex.data = {"ask": "up", "energy": energy, "steps": steps}
		return ex
	var owl := rng.randi_range(5, 60)
	ex = K.number("An owl gets %d units of energy from the mice it eats, and the mice ate plants. About how many units were in the plants?" % owl,
		str(owl * 100), hint, "Two steps down: %d × 10 × 10 = %s units." % [owl, K.fmt(owl * 100)])
	ex.data = {"ask": "back", "energy": owl, "steps": 2}
	return ex


## Level 1: a shower's litres; level 2: litres saved by showers; level 3: a family's litres.
static func water_use(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var per_minute := rng.randi_range(6, 12)
		var minutes := rng.randi_range(3, 10)
		ex = K.number("A shower uses %d litres a minute. How many litres does a %d-minute shower use?" % [per_minute, minutes],
			str(per_minute * minutes), "Litres a minute times the minutes.", "%d × %d = %d litres." % [per_minute, minutes,
			per_minute * minutes])
		ex.data = {"ask": "shower", "per_minute": per_minute, "minutes": minutes}
		return ex
	if level == 2:
		var bath := rng.randi_range(7, 10) * 10
		var shower := rng.randi_range(3, 6) * 10
		var times := rng.randi_range(2, 7)
		var who := PEOPLE[rng.randi_range(0, 3)]
		ex = K.number("A bath uses %d litres; a short shower uses %d litres. %s swaps %d baths a week for showers. How many litres does that save each week?" % [
			bath, shower, who, times], str(times * (bath - shower)), "Find the saving each time first.",
			"%d − %d = %d litres a time; × %d = %d litres." % [bath, shower, bath - shower, times, times * (bath - shower)])
		ex.data = {"ask": "saved", "bath": bath, "shower": shower, "times": times}
		return ex
	var people := rng.randi_range(2, 6)
	var each: int = [120, 130, 140, 150][rng.randi_range(0, 3)]
	var days: int = [7, 30][rng.randi_range(0, 1)]
	ex = K.number("%d people each use about %d litres of water a day. How many litres do they use in %d days?" % [people, each,
		days], str(people * each * days), "Find the litres for one day first.", "%d × %d = %s a day; × %d = %s litres." % [
		people, each, K.fmt(people * each), days, K.fmt(people * each * days)])
	ex.data = {"ask": "family", "people": people, "each": each, "days": days}
	return ex


## Level 1: m³ a person from million m³; level 2: from km³; level 3: stress or scarcity.
static func water_per_person(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var per := rng.randi_range(2, 20) * 250
	var millions := rng.randi_range(2, 40)
	if level == 1:
		ex = K.number("A country has %s million m³ of fresh water a year for %d million people. How many m³ is that for each person?" % [
			K.fmt(per * millions), millions], str(per), "Share the water equally: divide by the people.",
			"%s million ÷ %d million = %s m³ each." % [K.fmt(per * millions), millions, K.fmt(per)])
		ex.data = {"ask": "million_m3", "million_m3": per * millions, "millions": millions}
		return ex
	if level == 2:
		var km3 := 0
		for _try in 200:
			millions = rng.randi_range(2, 40)
			per = rng.randi_range(2, 20) * 250
			if per * millions % 1000 == 0:
				break
		if per * millions % 1000 != 0:
			per = 2000
			millions = 20
		km3 = per * millions / 1000
		ex = K.number("A country has %d km³ of fresh water a year for %d million people. 1 km³ is 1,000 million m³. How many m³ is that for each person?" % [
			km3, millions], str(per), "Turn km³ into million m³, then divide by the millions of people.",
			"%d km³ = %s million m³; ÷ %d million = %s m³ each." % [km3, K.fmt(km3 * 1000), millions, K.fmt(per)])
		ex.data = {"ask": "km3", "km3": km3, "millions": millions}
		return ex
	var levels: Array = [[150, 450, "absolute scarcity"], [550, 950, "water scarcity"], [1050, 1650, "water stress"],
		[1750, 5000, "no water stress"]]
	var band: Array = levels[rng.randi_range(0, 3)]
	per = rng.randi_range(int(band[0]) / 50, int(band[1]) / 50) * 50
	ex = K.choice(rng, "A country has %s m³ of fresh water a year for each person. Under 1,700 m³ is water stress, under 1,000 scarcity, under 500 absolute scarcity. Which is it?" % K.fmt(per),
		str(band[2]), ["absolute scarcity", "water scarcity", "water stress", "no water stress"].filter(func(w: String) -> bool:
			return w != str(band[2])), "Start from the lowest line: is it under 500? Under 1,000? Under 1,700?",
		"%s m³: %s." % [K.fmt(per), band[2]])
	ex.data = {"ask": "stress", "per": per}
	return ex


## Places on a map of the Middle East. Level 1: the furthest north of three; level 2: furthest north, south, east or
## west of four; level 3: degrees of latitude apart.
static func mideast_places(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = MIDEAST.keys()
	var ex: Dictionary
	if level < 3:
		var picks: Array = []
		var way := "north"
		for _try in 400:
			picks = _pick_any(rng, names, 3 if level == 1 else 4)
			way = "north" if level == 1 else ["north", "south", "east", "west"][rng.randi_range(0, 3)]
			if _spaced(picks) and _furthest(picks, way) != "":
				break
		var best := _furthest(picks, way)
		var words: Array[String] = []
		for p: Variant in picks:
			var at: Array = MIDEAST[p]
			words.append("%s %d° %s" % [p, at[1] if way in ["east", "west"] else at[0], "E" if way in ["east", "west"] else "N"])
		ex = K.choice(rng, "On this map, which of these places is furthest %s?" % way, best,
			picks.filter(func(p: Variant) -> bool: return str(p) != best),
			"North and south: the latitude, up the side. East and west: the longitude, along the bottom.",
			"%s. Furthest %s: %s." % [", ".join(words), way, best], _mideast_map(picks))
		ex.data = {"ask": way, "places": picks}
		return ex
	var two: Array = []
	for _try in 200:
		two = _pick_any(rng, names, 2)
		if int(MIDEAST[two[0]][0]) != int(MIDEAST[two[1]][0]):
			break
	var la := int(MIDEAST[two[0]][0])
	var lb := int(MIDEAST[two[1]][0])
	ex = K.number("%s is at %d° N and %s at %d° N. How many degrees of latitude apart are they?" % [two[0], la, two[1], lb],
		str(absi(la - lb)), "Both are north of the Equator: take the smaller latitude from the bigger.",
		"%d − %d = %d°." % [maxi(la, lb), mini(la, lb), absi(la - lb)], _mideast_map(two))
	ex.data = {"ask": "apart", "places": two}
	return ex


## Russia's time zones. Level 1: hours ahead; level 2: the time in a city further east; level 3: past midnight.
static func russia_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = RUSSIA_UTC.keys()
	var a := ""
	var b := ""
	var hour := 0
	for _try in 400:
		var two := _pick_any(rng, names, 2)
		a = str(two[0])
		b = str(two[1])
		if int(RUSSIA_UTC[a]) > int(RUSSIA_UTC[b]):
			var t := a
			a = b
			b = t
		var diff := int(RUSSIA_UTC[b]) - int(RUSSIA_UTC[a])
		hour = rng.randi_range(0, 23)
		if diff > 0 and (level == 1 or (level == 2 and hour + diff < 24 and hour >= diff) or (level == 3 and hour + diff >= 24
				and diff >= 3)):
			break
	var diff := int(RUSSIA_UTC[b]) - int(RUSSIA_UTC[a])
	var hint := "Further east, clocks are ahead: add the difference between the two UTC numbers."
	var ex: Dictionary
	if level == 1:
		ex = K.number("%s keeps UTC+%d and %s keeps UTC+%d. How many hours ahead of %s is %s?" % [a, RUSSIA_UTC[a], b,
			RUSSIA_UTC[b], a, b], str(diff), "Take the smaller UTC number from the bigger.", "%d − %d = %d hours ahead." % [
			RUSSIA_UTC[b], RUSSIA_UTC[a], diff])
		ex.data = {"ask": "ahead", "a": a, "b": b}
		return ex
	var h := hour + diff
	if level == 2:
		ex = K.choice(rng, "%s is UTC+%d and %s is UTC+%d. When it is %02d:00 in %s, what time is it in %s?" % [a, RUSSIA_UTC[a],
			b, RUSSIA_UTC[b], hour, a, b], "%02d:00" % h, ["%02d:00" % (hour - diff), "%02d:00" % ((h + 1) % 24),
			"%02d:00" % hour], hint, "%s is %d hours ahead: %d + %d = %d, so %02d:00." % [b, diff, hour, diff, h, h])
		ex.data = {"ask": "time", "a": a, "b": b, "hour": hour}
		return ex
	ex = K.choice(rng, "%s is UTC+%d and %s is UTC+%d. When it is %02d:00 in %s, what time is it in %s?" % [a, RUSSIA_UTC[a], b,
		RUSSIA_UTC[b], hour, a, b], "%02d:00 the next day" % (h - 24), ["%02d:00 the same day" % (h - 24),
		"%02d:00 the same day" % (hour - diff), "%02d:00 the next day" % ((h - 23) % 24)], hint + " Past 24:00 is the next day.",
		"%d + %d = %d; %d − 24 = %d, so %02d:00 the next day." % [hour, diff, h, h, h - 24, h - 24])
	ex.data = {"ask": "next_day", "a": a, "b": b, "hour": hour}
	return ex


## Fieldwork data. Level 1: the range; level 2: the median of an odd count; level 3: the mean.
static func field_stats(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var survey: Array = SURVEYS[rng.randi_range(0, SURVEYS.size() - 1)]
	var count: int = 5 if level != 2 else [5, 7][rng.randi_range(0, 1)]
	var values: Array = []
	for _i in count:
		values.append(rng.randi_range(2, 40))
	if level == 3:
		var total := 0
		for v: Variant in values:
			total += int(v)
		var fix: int = (count - total % count) % count
		values[count - 1] = int(values[count - 1]) + fix
	var sorted := values.duplicate()
	sorted.sort()
	var shown := ", ".join(values.map(func(v: Variant) -> String: return str(int(v)) + str(survey[1])))
	var ex: Dictionary
	if level == 1:
		var r := int(sorted.back()) - int(sorted[0])
		ex = K.number("%s at %d sites: %s. What is the range?" % [survey[0], count, shown], str(r),
			"The range is the biggest value take away the smallest.", "%d − %d = %d." % [sorted.back(), sorted[0], r])
		ex.data = {"ask": "range", "values": values}
	elif level == 2:
		var mid := int(sorted[count / 2])
		ex = K.number("%s at %d sites: %s. What is the median?" % [survey[0], count, shown], str(mid),
			"Put the values in order and find the middle one.", "In order: %s. The middle one is %d." % [", ".join(
			sorted.map(func(v: Variant) -> String: return str(int(v)))), mid])
		ex.data = {"ask": "median", "values": values}
	else:
		var total := 0
		for v: Variant in values:
			total += int(v)
		ex = K.number("%s at %d sites: %s. What is the mean?" % [survey[0], count, shown], str(total / count),
			"Add all the values, then divide by how many there are.", "%s = %d; %d ÷ %d = %d." % [" + ".join(
			values.map(func(v: Variant) -> String: return str(int(v)))), total, total, count, total / count])
		ex.data = {"ask": "mean", "values": values}
	return ex


# --- Citizenship --------------------------------------------------------------------------------------------------------

## Level 1: the next stage of a bill; level 2: four stages in order; level 3: a majority or two-thirds of a house.
static func bill_stages(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var hint := "A bill is read, debated, checked line by line, reported, read again, sent to the other House, and signed."
	if level == 1:
		var i := rng.randi_range(0, STAGES.size() - 2)
		var wrongs: Array = STAGES.filter(func(s: String) -> bool: return s != STAGES[i + 1] and s != STAGES[i])
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "In the UK Parliament, which stage comes straight after the %s?" % STAGES[i] if i != 5 else
			"In the UK Parliament, which stage comes after a bill has passed the other House?", STAGES[i + 1],
			wrongs.slice(0, 3), hint, "The stages: %s." % ", ".join(STAGES))
		ex.data = {"ask": "next", "stage": STAGES[i]}
		return ex
	if level == 2:
		var start := rng.randi_range(0, STAGES.size() - 4)
		var four := STAGES.slice(start, start + 4)
		ex = K.order(rng, "Put these stages of a bill in order.", four, hint, "In order: %s." % ", ".join(four))
		ex.data = {"ask": "order"}
		return ex
	if rng.randf() < 0.5:
		var members: int = [99, 150, 300, 435, 450, 600][rng.randi_range(0, 5)]
		ex = K.number("To overturn a president's veto, a house of %d members needs two-thirds of them to vote for it. If they all vote, how many votes is that?" % members,
			str(members * 2 / 3), "Find a third, then double it.", "%d ÷ 3 = %d; × 2 = %d votes." % [members, members / 3,
			members * 2 / 3])
		ex.data = {"ask": "two_thirds", "members": members}
		return ex
	var members: int = [100, 150, 200, 301, 435, 650][rng.randi_range(0, 5)]
	ex = K.number("A parliament has %d members, and they all vote. What is the fewest votes for a majority, more than half?" % members,
		str(members / 2 + 1), "Find half, then the next whole number above it.", "Half of %d is %s; more than half is %d." % [
		members, _num(members / 2.0), members / 2 + 1])
	ex.data = {"ask": "majority", "members": members}
	return ex


static func speech_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, SPEECH, SPEECH_KINDS, "Is this protected as free speech, or not: %s?",
		"Sort these: protected as free speech, or not protected?",
		"Free speech protects saying what you think, even when others disagree; it does not protect threats, harmful lies or hatred.")


## UK Parliament petitions: 10,000 signatures for a reply, 100,000 to be considered for a debate. Level 1: to 10,000;
## level 2: to 100,000; level 3: days to 100,000.
static func petition_goal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var have := rng.randi_range(20, 198) * 50
		ex = K.number("A petition to Parliament has %s signatures. How many more does it need to reach 10,000, when the government must reply?" % K.fmt(have),
			str(10000 - have), "Take what it has from 10,000.", "10,000 − %s = %s." % [K.fmt(have), K.fmt(10000 - have)])
		ex.data = {"ask": "response", "have": have}
		return ex
	if level == 2:
		var have := rng.randi_range(40, 198) * 500
		ex = K.number("A petition has %s signatures. How many more does it need to reach 100,000, when Parliament considers it for a debate?" % K.fmt(have),
			str(100000 - have), "Take what it has from 100,000.", "100,000 − %s = %s." % [K.fmt(have), K.fmt(100000 - have)])
		ex.data = {"ask": "debate", "have": have}
		return ex
	var have := 0
	var per_day := 0
	for _try in 200:
		have = rng.randi_range(2, 18) * 5000
		per_day = [500, 1000, 1500, 2000, 2500, 4000, 5000][rng.randi_range(0, 6)]
		if (100000 - have) % per_day == 0:
			break
	if (100000 - have) % per_day != 0:
		have = 40000
		per_day = 2000
	var days := (100000 - have) / per_day
	ex = K.number("A petition has %s signatures and gains %s a day. How many days until it reaches 100,000?" % [K.fmt(have),
		K.fmt(per_day)], str(days), "Find how many more it needs, then divide by the signatures a day.",
		"100,000 − %s = %s; %s ÷ %s = %d days." % [K.fmt(have), K.fmt(100000 - have), K.fmt(100000 - have), K.fmt(per_day), days])
	ex.data = {"ask": "days", "have": have, "per_day": per_day}
	return ex


## Level 1-2: the gold a charity spent on its work; level 3: a gift with Gift Aid (1 gold more for every 4 given).
static func charity_share(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var raised := rng.randi_range(2, 60) * (1000 if level == 1 else 100)
		var percent: int = ([70, 80, 90] if level == 1 else [65, 75, 85, 95])[rng.randi_range(0, 2 if level == 1 else 3)]
		ex = K.number("A charity raised %s gold and spent %d%% of it directly on its work. How much went to its work?" % [
			K.fmt(raised), percent], str(raised * percent / 100), "Find 1% first (divide by 100), then multiply.",
			"1%% of %s is %s; × %d = %s gold." % [K.fmt(raised), _num(raised / 100.0), percent, K.fmt(raised * percent / 100)])
		ex.data = {"ask": "work", "raised": raised, "percent": percent}
		return ex
	var given := rng.randi_range(5, 100) * 4
	var who := PEOPLE[rng.randi_range(0, 3)]
	ex = K.number("With Gift Aid, a charity can claim 1 gold more from the tax for every 4 gold a taxpayer gives. %s gives %d gold. How much does the charity get in all?" % [
		who, given], str(given + given / 4), "Find a quarter of the gift, then add it on.", "%d ÷ 4 = %d; %d + %d = %d gold." % [
		given, given / 4, given, given / 4, given + given / 4])
	ex.data = {"ask": "gift_aid", "given": given}
	return ex


## Level 1: fact or opinion; level 2: four sorted; level 3: facts, opinions and loaded words.
static func fact_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hint := "A fact can be checked. An opinion is what someone thinks. Loaded words slip an opinion into a fact."
	var plain: Array = FACTS.keys().filter(func(k: Variant) -> bool: return int(FACTS[k]) < 2)
	if level < 3:
		return _sorter(rng, level, FACTS, CLAIMS.slice(0, 2), "Fact or opinion? %s", "Sort these: fact or opinion?", hint, plain)
	var items: Array = []
	for _try in 100:
		items = _pick_any(rng, FACTS.keys(), 5)
		var used := {}
		for it: Variant in items:
			used[int(FACTS[it])] = true
		if used.size() == 3:
			break
	return _sort_ex(rng, "Sort these sentences: a fact, an opinion, or a fact with loaded words?", FACTS, CLAIMS, items, hint)


## A two-bar chart. Level 1: does the axis start at 0; level 2: how many times as tall one bar looks; level 3: the real
## difference as a percentage.
static func cut_axis(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := 50
	var b := 55
	var from := 45
	for _try in 400:
		var a1: int = [20, 25, 40, 50, 60, 80, 100, 120, 150, 200, 250, 400, 500][rng.randi_range(0, 12)]
		var pct: int = [2, 4, 5, 8, 10, 20, 25, 50][rng.randi_range(0, 7)]
		var k := rng.randi_range(2, 5)
		if a1 * pct % 100 != 0:
			continue
		var b1 := a1 + a1 * pct / 100
		if (k * a1 - b1) % (k - 1) == 0 and (k * a1 - b1) / (k - 1) >= 0 and (k * a1 - b1) / (k - 1) < a1:
			a = a1
			b = b1
			from = (k * a1 - b1) / (k - 1)
			break
	var cut := level > 1 or rng.randf() < 0.6
	if not cut:
		from = 0
	var pair: Array = BAR_NAMES[rng.randi_range(0, BAR_NAMES.size() - 1)]
	var pic := _cut_chart(pair, a, b, from)
	var ex: Dictionary
	if level == 1:
		ex = K.truefalse("This chart's axis starts at 0.", from == 0, "Read the lowest number on the axis.",
			("True: the axis starts at 0, so the bars' heights are fair." if from == 0 else
			"False: the axis starts at %s, so the bars' heights mislead." % K.fmt(from)), pic)
		ex.data = {"ask": "zero", "a": a, "b": b, "from": from}
		return ex
	if level == 2:
		var looks := (b - from) / (a - from)
		ex = K.number("The axis starts at %s. How many times as tall as %s's bar does %s's bar look?" % [K.fmt(from), pair[0],
			pair[1]], str(looks), "Each bar is drawn from the axis's start: measure each from there.",
			"%s's bar: %s − %s = %s; %s's: %s − %s = %s; %s ÷ %s = %d times as tall." % [pair[1], K.fmt(b), K.fmt(from),
			K.fmt(b - from), pair[0], K.fmt(a), K.fmt(from), K.fmt(a - from), K.fmt(b - from), K.fmt(a - from), looks], pic)
		ex.data = {"ask": "looks", "a": a, "b": b, "from": from}
		return ex
	var really := (b - a) * 100 / a
	ex = K.number("By what percentage is %s's number really bigger than %s's?" % [pair[1], pair[0]], str(really),
		"Find the difference, then what percentage it is of the smaller number.", "%s − %s = %s; %s ÷ %s × 100 = %d%%." % [
		K.fmt(b), K.fmt(a), K.fmt(b - a), K.fmt(b - a), K.fmt(a), really], pic)
	ex.data = {"ask": "really", "a": a, "b": b, "from": from}
	return ex


## Level 1: a goal's name; level 2: its number; level 3: four goals matched.
static func sdg_goal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var goals: Array = SDGS.keys()
	var ex: Dictionary
	var hint := "The goals start with people's basic needs (1-6), then work and fair societies, then the planet (13-15), then peace and partnership."
	if level == 1:
		var four := _pick_any(rng, goals, 4)
		var n := int(four[0])
		ex = K.choice(rng, "Which Sustainable Development Goal is number %d?" % n, str(SDGS[n]), four.slice(1).map(
			func(g: Variant) -> String: return str(SDGS[g])), hint, "Goal %d: %s." % [n, SDGS[n]])
		ex.data = {"ask": "name", "goal": n}
		return ex
	if level == 2:
		var n: int = goals[rng.randi_range(0, goals.size() - 1)]
		ex = K.number("What is the number of the Sustainable Development Goal “%s”?" % SDGS[n], str(n), hint,
			"“%s” is Goal %d." % [SDGS[n], n])
		ex.data = {"ask": "number", "goal": n}
		return ex
	var short: Array = goals.filter(func(g: Variant) -> bool: return str(SDGS[g]).length() <= 32)
	var four := _pick_any(rng, short, 4)
	var items: Array = four.map(func(g: Variant) -> String: return "Goal %d" % int(g))
	var names: Array = four.map(func(g: Variant) -> String: return str(SDGS[g]))
	var order: Array = range(4)
	for _try in 10:
		K.shuffle(rng, order)
		if order != range(4):
			break
	if order == range(4):
		order = [1, 2, 3, 0]
	var matches: Array = []
	for i: int in order:
		matches.append(names[i])
	var answer: Array = []
	for i in 4:
		answer.append(order.find(i))
	ex = {"type": "match", "prompt": "Match each Global Goal's number to its name.", "items": items, "matches": matches,
		"answer": answer, "hint": hint, "explain": ". ".join(Array(range(4)).map(func(i: int) -> String:
			return "%s: %s" % [items[i], names[i]])) + "."}
	ex.data = {"ask": "match", "goals": four}
	return ex


## Level 1: a job for what someone enjoys; levels 2-3: jobs sorted by what they work with.
static func career_match(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hint := "Think about what each job spends most of the day working with."
	if level > 1:
		return _sorter(rng, level, CAREERS, WORKS_WITH, "", "Sort these jobs: mostly working with people, things and tools, or ideas and data?", hint)
	var g := rng.randi_range(0, 2)
	var who := PEOPLE[rng.randi_range(0, 3)]
	var jobs: Array = []
	for k in 3:
		var of_k: Array = CAREERS.keys().filter(func(j: Variant) -> bool: return int(CAREERS[j]) == k)
		jobs.append(of_k[rng.randi_range(0, of_k.size() - 1)])
	var ex := K.choice(rng, "%s enjoys %s. Which job might suit %s best?" % [who, LIKES[g], who], str(jobs[g]),
		jobs.filter(func(j: Variant) -> bool: return str(j) != str(jobs[g])), hint,
		"The job of %s is mostly working with %s, which %s enjoys. Any job is open to anyone who learns its skills." % [
		jobs[g], WORKS_WITH[g], who])
	ex.data = {"ask": "likes", "group": WORKS_WITH[g]}
	return ex


## A small business. Level 1: a profit; level 2: profit or loss with fixed and item costs; level 3: the break-even point
## on a chart.
static func profit_loss(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := PEOPLE[rng.randi_range(0, 3)]
	var ex: Dictionary
	if level == 1:
		var sold := rng.randi_range(20, 80)
		var price := rng.randi_range(2, 5)
		var costs := rng.randi_range(5, sold * price / 5) * 5 - 5
		costs = maxi(costs, 10)
		ex = K.number("%s sells %d cookies at %d gold each. The ingredients and the stall cost %d gold. What is the profit?" % [
			who, sold, price, costs], str(sold * price - costs), "Takings are items sold times the price; profit is takings minus costs.",
			"%d × %d = %d; %d − %d = %d gold." % [sold, price, sold * price, sold * price, costs, sold * price - costs])
		ex.data = {"ask": "profit", "sold": sold, "price": price, "costs": costs}
		return ex
	var fixed := 0
	var cost := 0.5
	var price := 2.0
	var sold := 0
	if level == 2:
		var result := 0.0
		for _try in 200:
			fixed = rng.randi_range(2, 12) * 5
			cost = [0.5, 1.0][rng.randi_range(0, 1)]
			price = [1.5, 2.0, 2.5, 3.0][rng.randi_range(0, 3)]
			sold = rng.randi_range(10, 60)
			result = sold * price - (fixed + cost * sold)
			if price > cost and not is_zero_approx(result):
				break
		var money := _num(absf(result))
		var right := ("a profit of %s gold" if result > 0 else "a loss of %s gold") % money
		var other := ("a loss of %s gold" if result > 0 else "a profit of %s gold") % money
		var alt := _num(absf(sold * price - fixed))
		var wrongs: Array = [other, ("a profit of %s gold" % alt) if alt != money else "a profit of %s gold" % _num(absf(result) + 5)]
		ex = K.choice(rng, "A stall costs %d gold to hire. Each drink costs %s gold to make and sells for %s gold. %s sells %d drinks. Is it a profit or a loss, and how much?" % [
			fixed, _num(cost), _num(price), who, sold], right, wrongs,
			"Takings = drinks × price. Costs = the stall + drinks × cost to make. Compare them.",
			"Takings %d × %s = %s. Costs %d + %d × %s = %s. So %s." % [sold, _num(price), _num(sold * price), fixed, sold,
			_num(cost), _num(fixed + cost * sold), right])
		ex.data = {"ask": "either", "fixed": fixed, "cost": cost, "price": price, "sold": sold}
		return ex
	var items := 0
	for _try in 200:
		cost = [0.5, 1.0, 1.5, 2.0][rng.randi_range(0, 3)]
		price = cost + [1.0, 1.5, 2.0, 2.5, 3.0][rng.randi_range(0, 4)]
		items = rng.randi_range(4, 30)
		fixed = int(roundf(items * (price - cost)))
		if is_equal_approx(fixed, items * (price - cost)) and fixed >= 10:
			break
	if not is_equal_approx(fixed, items * (price - cost)) or fixed < 10:
		cost = 1.0
		price = 3.0
		items = 20
		fixed = 40
	var most := items * 2 if items >= 10 else 25
	ex = K.number("A stall costs %d gold to hire. Each item costs %s gold to make and sells for %s gold. How many must be sold to break even?" % [
		fixed, _num(cost), _num(price)], str(items), "Each item sold pays price − cost towards the stall: how many cover it?",
		"%s − %s = %s gold an item; %d ÷ %s = %d items." % [_num(price), _num(cost), _num(price - cost), fixed,
		_num(price - cost), items], {"kind": "break_even", "fixed": fixed, "cost": cost, "price": price, "max": most,
		"point": true, "hide": true})
	ex.data = {"ask": "break_even", "fixed": fixed, "cost": cost, "price": price}
	return ex


## Level 1: a month's interest; level 2: a year's interest; level 3: debit or credit.
static func card_interest(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := PEOPLE[rng.randi_range(0, 3)]
	var ex: Dictionary
	if level == 3:
		ex = _sorter(rng, 2 + rng.randi_range(0, 1), CARDS, CARD_KINDS, "", "Sort these: debit card or credit card?",
			"A debit card spends your own money; a credit card borrows money you pay back later.")
		ex.data.ask = "sort"
		return ex
	var owed := rng.randi_range(1, 9) * 100 if level == 1 else rng.randi_range(5, 30) * 100
	var rate: int = ([2, 3] if level == 1 else [18, 20, 22, 24, 25, 30])[rng.randi_range(0, 1 if level == 1 else 5)]
	var when := "a month" if level == 1 else "a year"
	ex = K.number("%s owes %s gold on a credit card that charges %d%% interest %s on money not paid back. How much interest is that for %s?" % [
		who, K.fmt(owed), rate, when, "one month" if level == 1 else "a whole year (without interest on interest)"],
		_ans(owed * rate / 100.0), "Find 1% of what is owed, then multiply by the rate.", "1%% of %s is %s; × %d = %s gold." % [
		K.fmt(owed), _num(owed / 100.0), rate, _num(owed * rate / 100.0)])
	ex.data = {"ask": "month" if level == 1 else "year", "owed": owed, "rate": rate}
	return ex


## Eggs in baskets. Level 1: each part; level 2: one part fails; level 3: one fails and the rest grow.
static func portfolio(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := PEOPLE[rng.randi_range(0, 3)]
	var parts := rng.randi_range(3, 10)
	var each := rng.randi_range(1, 20) * 100
	var total := each * parts
	var ex: Dictionary
	var start := "%s splits %s gold equally between %d different investments." % [who, K.fmt(total), parts]
	if level == 1:
		ex = K.number(start + " How much goes into each?", str(each), "Divide the gold by the number of investments.",
			"%s ÷ %d = %s gold each." % [K.fmt(total), parts, K.fmt(each)])
		ex.data = {"ask": "each", "total": total, "parts": parts}
		return ex
	if level == 2:
		ex = K.number(start + " One fails and is worth nothing; the others keep their value. How much is left?", str(each * (parts - 1)),
			"Find what was in each, then count the ones that are left.", "%s ÷ %d = %s each; %d left × %s = %s gold." % [
			K.fmt(total), parts, K.fmt(each), parts - 1, K.fmt(each), K.fmt(each * (parts - 1))])
		ex.data = {"ask": "one_fails", "total": total, "parts": parts}
		return ex
	var grow: int = [5, 10, 20, 25, 50][rng.randi_range(0, 4)]
	var left := each * (parts - 1)
	var now := left + left * grow / 100
	ex = K.number(start + " One fails and is worth nothing, but the others grow by %d%%. How much does %s have now?" % [grow, who],
		str(now), "Find what is left in the others, then add the growth.", "%s ÷ %d = %s each; %d × %s = %s; + %d%% = %s gold." % [
		K.fmt(total), parts, K.fmt(each), parts - 1, K.fmt(each), K.fmt(left), grow, K.fmt(now)])
	ex.data = {"ask": "rest_grow", "total": total, "parts": parts, "grow": grow}
	return ex


static func reason_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, REASONS, REASON_KINDS, "What kind of reason is this? %s",
		"Sort these reasons: fairness, consequences or kindness?",
		"Fairness: treating people the same way. Consequences: what will happen. Kindness: caring how someone feels.")


# --- Helpers --------------------------------------------------------------------------------------------------------

## A table's item and its group (the group's index in `groups`). Level 1: one item's group (a choice; skipped when
## `one` is ""); level 2: four items sorted; level 3: six (or all), from at least two groups (three when there are three).
static func _sorter(rng: RandomNumberGenerator, level: int, table: Dictionary, groups: Array, one: String, many: String,
		hint: String, keys: Array = []) -> Dictionary:
	var pool: Array = keys if not keys.is_empty() else table.keys()
	if level == 1 and one != "":
		var item: String = pool[rng.randi_range(0, pool.size() - 1)]
		var right := str(groups[int(table[item])])
		var ex := K.choice(rng, one % _said(item), right, groups.filter(func(g: Variant) -> bool: return str(g) != right), hint,
			"%s: %s." % [_cap(_said(item)), right])
		ex.data = {"ask": "one", "item": item}
		return ex
	var want := mini(groups.size(), 2 if level <= 2 else 3)
	var items: Array = []
	# Level 2 sorts 4, level 3 six; fewer when the worked answer would not fit its panel.
	for n in range(mini(4 if level <= 2 else 6, pool.size()), 2, -1):
		for _try in 60:
			items = _pick_any(rng, pool, n)
			var used := {}
			for it: Variant in items:
				used[int(table[it])] = true
			if used.size() >= want and _sort_explain(table, groups, items).length() <= 250:
				return _sort_ex(rng, many, table, groups, items, hint)
	return _sort_ex(rng, many, table, groups, items, hint)


static func _sort_ex(rng: RandomNumberGenerator, prompt: String, table: Dictionary, groups: Array, items: Array,
		hint: String) -> Dictionary:
	var shown := items.duplicate()
	K.shuffle(rng, shown)
	var answer: Array = shown.map(func(it: Variant) -> int: return int(table[it]))
	var ex := {"type": "sort", "prompt": prompt, "groups": groups.duplicate(), "items": shown, "answer": answer, "hint": hint,
		"explain": _sort_explain(table, groups, shown)}
	ex.data = {"ask": "sort", "items": shown}
	return ex


static func _sort_explain(table: Dictionary, groups: Array, items: Array) -> String:
	var parts: Array[String] = []
	for g in groups.size():
		var of_g: Array = items.filter(func(it: Variant) -> bool: return int(table[it]) == g)
		if not of_g.is_empty():
			parts.append("%s: %s" % [_cap(str(groups[g])), ", ".join(of_g.map(func(it: Variant) -> String: return _said(str(it))))])
	return ". ".join(parts) + "."


## An item as a lesson writes it: a sentence in quotation marks, a phrase as it is.
static func _said(item: String) -> String:
	return "“%s”" % item.trim_suffix(".") if item.ends_with(".") else item


static func _event_text(e: Array) -> String:
	return "%s (%s%d)" % [e[0], "about " if bool(e[2]) else "", e[1]]


## "BOOK" -> "B, O, O, K".
static func _letters(word: String) -> String:
	var out: Array[String] = []
	for ch in word:
		out.append(ch)
	return ", ".join(out)


static func _flip_letters(word: String) -> String:
	var flip := {"b": "d", "d": "b", "p": "q", "q": "p"}
	var out := ""
	for ch in word:
		out += str(flip.get(ch, ch))
	return out


static func _mideast_map(names: Array) -> Dictionary:
	var pic := MIDEAST_MAP.duplicate(true)
	pic.places = names.map(func(n: Variant) -> Dictionary: return {"lat": int(MIDEAST[n][0]), "long": int(MIDEAST[n][1]),
		"label": str(n)})
	return pic


## Whether places sit far enough apart on the Middle East map for their dots and names.
static func _spaced(names: Array) -> bool:
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: Array = MIDEAST[names[i]]
			var b: Array = MIDEAST[names[j]]
			if absi(int(a[0]) - int(b[0])) < 3 and absi(int(a[1]) - int(b[1])) < 6:
				return false
	return true


## The place furthest `way`, or "" when two share the furthest line.
static func _furthest(names: Array, way: String) -> String:
	var key := 1 if way in ["east", "west"] else 0
	var dir := 1 if way in ["north", "east"] else -1
	var best := ""
	var tie := false
	for p: Variant in names:
		var v := int(MIDEAST[p][key]) * dir
		if best == "" or v > int(MIDEAST[best][key]) * dir:
			best = str(p)
			tie = false
		elif v == int(MIDEAST[best][key]) * dir:
			tie = true
	return "" if tie else best


static func _cut_chart(pair: Array, a: int, b: int, from: int) -> Dictionary:
	for step: int in [1, 2, 5, 10, 20, 25, 50, 100]:
		var steps := ceili(float(b - from) / step)
		if steps >= 2 and steps <= 10:
			return {"kind": "cut_axis_bars", "bars": [[pair[0], a], [pair[1], b]], "from": from, "to": from + steps * step,
				"step": step}
	return {"kind": "cut_axis_bars", "bars": [[pair[0], a], [pair[1], b]], "from": from, "to": from + 10 * 100, "step": 100}


## A number as an answer is typed: 2.5, 40000 (no commas).
static func _ans(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(roundi(v))
	if is_equal_approx(v * 10.0, roundf(v * 10.0)):
		return "%.1f" % v
	return "%.2f" % v


## A number as the lessons write it: 2.5, 40.
static func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return K.fmt(roundi(v))
	if is_equal_approx(v * 10.0, roundf(v * 10.0)):
		return "%.1f" % v
	return "%.2f" % v


static func _ordinal(n: int) -> String:
	if n % 100 >= 11 and n % 100 <= 13:
		return "%dth" % n
	return "%d%s" % [n, {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")]


static func _uncap(s: String) -> String:
	return s.substr(0, 1).to_lower() + s.substr(1)


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


static func _pick_any(rng: RandomNumberGenerator, list: Array, count: int) -> Array:
	var pool := list.duplicate()
	K.shuffle(rng, pool)
	return pool.slice(0, count)
