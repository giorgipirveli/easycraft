extends GutTest
## Owner #70 and #73, grade 7 history, geography and citizenship (G7HumGen, "g7h"): the early modern world's dates in
## order and apart, a press's sheets and days, mirrored type, the Pole Star's latitude, dead reckoning, the Columbian
## exchange, the Ottoman Empire's three continents, Mughal and Tudor-Stuart reigns, Kepler's third law, the scientific
## method, the spice trade's profit, shares in a company; plate boundaries, earthquake magnitudes, plates drifting,
## rocks and weathering, glaciers retreating and their landforms, coastal landforms and defences and their cost,
## biomes' climates, energy up a food chain, water used and water per person, places in the Middle East, Russia's time
## zones, fieldwork averages, predict-protect-prepare; a law's stages and votes, free speech's limits, petitions,
## charities' spending, facts and opinions, charts with cut axes, the Global Goals, careers, profit and loss, card
## interest, spreading savings, and kinds of moral reasons. Each generator's answer is worked out again here from the
## exercise's `data` and this file's own facts (typed apart from the generator's tables), for many seeds and every
## level, and every exercise must be valid (ExerciseCheck and the picture's own check).

const SEEDS := 80
const G := "g7h."

## The early modern world's dated events, as the lessons give them.
const EVENTS := {
	"Jikji is printed in Korea": 1377, "Zheng He's first voyage": 1405, "The Forbidden City is finished": 1420,
	"Brunelleschi's dome is finished": 1436, "The Ottomans take Constantinople": 1453,
	"The Gutenberg Bible is printed": 1455, "Caxton prints in England": 1476, "Columbus crosses the Atlantic": 1492,
	"Vasco da Gama reaches India": 1498, "Michelangelo finishes David": 1504, "Henry VIII becomes king": 1509,
	"Suleiman becomes sultan": 1520, "Magellan's ship returns": 1522, "Babur founds the Mughal Empire": 1526,
	"Copernicus's book is printed": 1543, "The Süleymaniye Mosque is finished": 1557,
	"Elizabeth I becomes queen": 1558, "Akbar builds Fatehpur Sikri": 1571, "The Spanish Armada sails": 1588,
	"The English East India Company begins": 1600, "The Dutch East India Company begins": 1602,
	"Tokugawa Ieyasu becomes shogun": 1603, "Galileo sees Jupiter's moons": 1610, "Work on the Taj Mahal begins": 1632,
	"The English Civil War begins": 1642, "The Ming dynasty ends": 1644, "The Royal Society is founded": 1660,
	"Newton's Principia is printed": 1687, "The Bill of Rights": 1689, "England and Scotland unite": 1707,
}
## Dated only roughly ("about"): never an anniversary.
const ABOUT: Array[String] = ["The Gutenberg Bible is printed"]
const TUDORS := {"Henry VII": [1485, 1509], "Henry VIII": [1509, 1547], "Edward VI": [1547, 1553], "Mary I": [1553, 1558],
	"Elizabeth I": [1558, 1603], "James I": [1603, 1625], "Charles I": [1625, 1649], "Charles II": [1660, 1685],
	"James II": [1685, 1688], "Anne": [1702, 1714]}
const MUGHALS := {"Babur": [1526, 1530], "Akbar": [1556, 1605], "Jahangir": [1605, 1627], "Shah Jahan": [1628, 1658],
	"Aurangzeb": [1658, 1707]}
const EXCHANGE := {"potatoes": "from the Americas", "tomatoes": "from the Americas", "maize": "from the Americas",
	"cacao beans": "from the Americas", "chilli peppers": "from the Americas", "peanuts": "from the Americas",
	"pumpkins": "from the Americas", "turkeys": "from the Americas", "pineapples": "from the Americas",
	"vanilla": "from the Americas", "wheat": "to the Americas", "rice": "to the Americas", "sugar cane": "to the Americas",
	"coffee": "to the Americas", "bananas": "to the Americas", "oranges": "to the Americas", "horses": "to the Americas",
	"cattle": "to the Americas", "pigs": "to the Americas", "sheep": "to the Americas", "chickens": "to the Americas"}
const OTTOMAN := {"Edirne": "Europe", "Sofia": "Europe", "Belgrade": "Europe", "Budapest": "Europe", "Athens": "Europe",
	"Sarajevo": "Europe", "Bursa": "Asia", "Ankara": "Asia", "Baghdad": "Asia", "Damascus": "Asia", "Mecca": "Asia",
	"Aleppo": "Asia", "Cairo": "Africa", "Alexandria": "Africa", "Algiers": "Africa", "Tunis": "Africa"}
## The planets in order from the Sun.
const PLANETS: Array[String] = ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn"]
const STEPS: Array[String] = ["question", "hypothesis", "experiment", "results", "conclusion"]
const METHOD := {
	"Do heavy balls fall faster than light ones?": "question",
	"I think heavy and light balls fall as fast.": "hypothesis",
	"Roll a heavy and a light ball down a ramp.": "experiment",
	"Both balls reached the bottom together.": "results",
	"Weight does not change how fast they roll.": "conclusion",
	"What are the stars next to Jupiter?": "question",
	"I predict they are moons going round Jupiter.": "hypothesis",
	"Draw Jupiter and the stars every clear night.": "experiment",
	"The stars moved from side to side each night.": "results",
	"They are moons orbiting Jupiter.": "conclusion",
	"Does a pendulum's weight change its swing?": "question",
	"I think only the string's length matters.": "hypothesis",
	"Time swings with weights of 1, 2 and 3 blocks.": "experiment",
	"Every weight took 2 seconds a swing.": "results",
	"The weight does not change the swing.": "conclusion",
}
const BOUNDARIES := {"the Mid-Atlantic Ridge": "moving apart", "Iceland's rift valley": "moving apart",
	"the East African Rift": "moving apart", "new ocean floor forms": "moving apart", "the Andes": "moving together",
	"the Himalayas": "moving together", "Japan's volcanoes": "moving together",
	"a deep ocean trench forms": "moving together", "fold mountains rise": "moving together",
	"the San Andreas Fault": "sliding past", "a road is split and moved sideways": "sliding past",
	"the Alpine Fault in New Zealand": "sliding past"}
const ROCKS := {"granite": "igneous", "basalt": "igneous", "pumice": "igneous", "obsidian": "igneous",
	"sandstone": "sedimentary", "limestone": "sedimentary", "chalk": "sedimentary", "shale": "sedimentary",
	"conglomerate": "sedimentary", "marble": "metamorphic", "slate": "metamorphic", "schist": "metamorphic",
	"gneiss": "metamorphic", "quartzite": "metamorphic", "formed when lava cooled quickly": "igneous",
	"big crystals from magma cooling slowly": "igneous", "layers of sand pressed together": "sedimentary",
	"holds fossils of sea shells": "sedimentary", "limestone changed by great heat": "metamorphic",
	"mudstone squeezed into thin sheets": "metamorphic"}
const WEATHERING := {"water freezes and splits a rock": "physical", "a hot desert rock peels in layers": "physical",
	"salt crystals grow in cracks": "physical", "rain slowly dissolves limestone": "chemical",
	"acid rain wears a statue's face away": "chemical", "iron in a rock turns to rust": "chemical",
	"tree roots widen a crack": "biological", "rabbits burrow into a slope": "biological",
	"lichen slowly breaks down rock": "biological"}
const GLACIAL := {"corrie": "erosion", "arete": "erosion", "pyramidal peak": "erosion", "U-shaped valley": "erosion",
	"hanging valley": "erosion", "truncated spur": "erosion", "ribbon lake": "erosion", "terminal moraine": "deposition",
	"lateral moraine": "deposition", "drumlin": "deposition", "erratic boulder": "deposition"}
const COAST := {"cave": "erosion", "arch": "erosion", "stack": "erosion", "stump": "erosion", "cliff": "erosion",
	"wave-cut platform": "erosion", "beach": "deposition", "spit": "deposition", "bar": "deposition",
	"tombolo": "deposition", "sand dunes": "deposition"}
const DEFENCES := {"sea wall": "hard engineering", "groynes": "hard engineering", "rock armour": "hard engineering",
	"gabions": "hard engineering", "beach nourishment": "soft engineering", "dune planting": "soft engineering",
	"managed retreat": "soft engineering", "salt marsh creation": "soft engineering"}
## Each biome's typical year (as the generator draws it): the months' °C and mm.
const BIOMES := {
	"tropical rainforest": [[27, 27, 27, 27, 27, 26, 26, 26, 27, 27, 27, 27], [260, 250, 300, 280, 220, 160, 140, 150,
		180, 220, 240, 270]],
	"hot desert": [[14, 17, 21, 26, 30, 33, 34, 33, 30, 25, 19, 15], [8, 6, 4, 2, 0, 0, 0, 0, 0, 1, 4, 7]],
	"savanna": [[26, 28, 30, 31, 30, 28, 26, 26, 27, 28, 28, 26], [0, 2, 10, 30, 90, 150, 220, 240, 160, 40, 4, 0]],
	"Mediterranean": [[10, 11, 13, 15, 19, 23, 26, 26, 23, 18, 14, 11], [90, 70, 55, 40, 25, 8, 2, 5, 25, 60, 85, 100]],
	"temperate forest": [[4, 5, 7, 9, 13, 16, 18, 18, 15, 11, 7, 5], [60, 45, 45, 45, 50, 50, 50, 55, 55, 70, 65, 60]],
	"taiga": [[-20, -17, -9, 1, 9, 15, 17, 14, 8, 0, -10, -18], [20, 15, 18, 25, 40, 60, 75, 70, 50, 35, 28, 22]],
	"tundra": [[-28, -28, -25, -16, -5, 4, 8, 6, 0, -10, -20, -25], [8, 7, 8, 9, 12, 20, 35, 38, 25, 15, 10, 9]],
}
const MIDEAST := {"Cairo": [30, 31], "Ankara": [40, 33], "Istanbul": [41, 29], "Baghdad": [33, 44], "Tehran": [36, 51],
	"Riyadh": [25, 47], "Muscat": [24, 58], "Mecca": [21, 40], "Amman": [32, 36], "Kuwait City": [29, 48],
	"Doha": [25, 51], "Dubai": [25, 55]}
const RUSSIA_UTC := {"Kaliningrad": 2, "Moscow": 3, "St Petersburg": 3, "Samara": 4, "Yekaterinburg": 5, "Omsk": 6,
	"Novosibirsk": 7, "Krasnoyarsk": 7, "Irkutsk": 8, "Yakutsk": 9, "Vladivostok": 10, "Magadan": 11, "Kamchatka": 12}
const HAZARD := {"measure a volcano swelling": "predict", "check a volcano's gases": "predict",
	"record small earthquakes with seismometers": "predict", "track a hurricane by satellite": "predict",
	"build houses with cross-bracing": "protect", "put rubber pads under a building": "protect",
	"build a wall against tsunamis": "protect", "dig channels to steer lava away": "protect",
	"practise earthquake drills": "prepare", "pack a kit with water and a torch": "prepare",
	"plan an escape route and a meeting point": "prepare", "learn Drop, Cover and Hold On": "prepare"}
const STAGES: Array[String] = ["first reading", "second reading", "committee stage", "report stage", "third reading",
	"the other House", "royal assent"]
const SPEECH := {"saying a new law is unfair": "free speech", "writing that a film was boring": "free speech",
	"arguing the council made a mistake": "free speech", "holding a peaceful protest": "free speech",
	"sharing an unpopular opinion politely": "free speech", "criticising the government": "free speech",
	"threatening to hurt someone": "not protected", "spreading lies that ruin someone's name": "not protected",
	"stirring up hatred against a group": "not protected", "posting someone's private photos": "not protected",
	"urging people to attack a shop": "not protected"}
const FACTS := {"The bridge opened on 3 May.": "fact", "The council voted 7 to 2 for the plan.": "fact",
	"The park is 2 km long.": "fact", "Tickets cost 5 gold.": "fact", "The river rose 30 cm overnight.": "fact",
	"The new bridge is ugly.": "opinion", "The plan is a terrible idea.": "opinion",
	"It is the best park in the town.": "opinion", "Tickets are far too expensive.": "opinion",
	"The shocking plan was passed on Monday.": "loaded words", "A mob gathered outside the hall.": "loaded words",
	"The heroic mayor opened the bridge.": "loaded words"}
const SDGS := {1: "No poverty", 2: "Zero hunger", 3: "Good health and well-being", 4: "Quality education",
	5: "Gender equality", 6: "Clean water and sanitation", 7: "Affordable and clean energy",
	8: "Decent work and economic growth", 9: "Industry, innovation and infrastructure", 10: "Reduced inequalities",
	11: "Sustainable cities and communities", 12: "Responsible consumption and production", 13: "Climate action",
	14: "Life below water", 15: "Life on land", 16: "Peace, justice and strong institutions",
	17: "Partnerships for the goals"}
const CAREERS := {"nurse": "people", "teacher": "people", "care worker": "people", "police officer": "people",
	"social worker": "people", "electrician": "things and tools", "mechanic": "things and tools",
	"carpenter": "things and tools", "plumber": "things and tools", "farmer": "things and tools",
	"scientist": "ideas and data", "programmer": "ideas and data", "accountant": "ideas and data",
	"researcher": "ideas and data", "data analyst": "ideas and data"}
const CARDS := {"spends money already in your account": "debit card", "money leaves your account at once": "debit card",
	"you can only spend what you have": "debit card", "borrows money to pay back later": "credit card",
	"has a spending limit set by the lender": "credit card", "charges interest if not paid in full": "credit card"}
const REASONS := {"Everyone should get the same chance.": "fairness",
	"The rule must be the same for everyone.": "fairness", "She did the work, so she gets the credit.": "fairness",
	"If we tell now, the problem stops sooner.": "consequences", "More people will be helped this way.": "consequences",
	"A lie now could cause bigger trouble later.": "consequences",
	"He feels left out, so let's include him.": "kindness", "Think how you would feel in her place.": "kindness",
	"A friend who is upset needs us to listen.": "kindness"}


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(G + gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			assert_ne(str(ex.get("explain", "")), "", "%s: a worked answer" % gen)
			assert_ne(str(ex.get("hint", "")), str(ex.get("explain", "")), "%s: the hint is a strategy" % gen)
			assert_true(ex.get("data") is Dictionary, "%s: its data" % gen)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % gen)
			if ExerciseCheck.problem(ex) == "" and ex.get("data") is Dictionary:
				check.call(ex, level)


func _right_choice(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func _number_is(ex: Dictionary, expected: float) -> void:
	assert_eq(str(ex.type), "number", str(ex.prompt))
	assert_almost_eq(NumberAnswer.value(str(ex.answer)), expected, 0.0001, str(ex.prompt))


## A sort's every item in its group, or a choice's one item in its group, by this file's own table.
func _grouped(ex: Dictionary, table: Dictionary) -> void:
	if str(ex.type) == "choice":
		var item := str(ex.data.item)
		assert_true(table.has(item), "known: %s" % item)
		assert_true(str(ex.prompt).contains(item.trim_suffix(".")), "the item is asked about")   # a sentence is quoted
		assert_eq(_right_choice(ex), str(table.get(item, "")), item)
		return
	assert_eq(str(ex.type), "sort", str(ex.prompt))
	var used := {}
	for i in (ex.items as Array).size():
		var item := str(ex.items[i])
		assert_true(table.has(item), "known: %s" % item)
		assert_eq(str(ex.groups[int(ex.answer[i])]), str(table.get(item, "")), item)
		used[int(ex.answer[i])] = true
	assert_gte(used.size(), 2, "at least two groups used")


func _gen_ids() -> Array[String]:
	var out: Array[String] = []
	for gen in SchoolGen.ids():
		if gen.begins_with(G):
			out.append(gen)
	return out


func test_the_source_is_registered_and_every_generator_is_tested() -> void:
	assert_true(SchoolGen.SOURCES.has("g7h"), "the source is a SOURCES line")
	var tested := {}
	for m: Dictionary in (get_script() as Script).get_script_method_list():
		tested[str(m.name)] = true
	for gen in _gen_ids():
		assert_true(tested.has("test_" + gen.substr(G.length())), "%s has its own test here" % gen)
	assert_gte(_gen_ids().size(), 40, "grade 7 humanities' generators")


# --- History ------------------------------------------------------------------------------------------------------------

func test_early_modern_order() -> void:
	_each("early_modern_order", _check_early_modern_order)


func _check_early_modern_order(ex: Dictionary, level: int) -> void:
	assert_eq((ex.items as Array).size(), level + 2)
	var years: Array[int] = []
	for i: Variant in ex.answer:
		var item := str(ex.items[int(i)])
		var name := item.substr(0, item.rfind(" ("))
		assert_true(EVENTS.has(name), "known: %s" % name)
		years.append(int(EVENTS.get(name, 0)))
		assert_true(item.contains(str(EVENTS.get(name, 0))), "%s shows its year" % item)
	for k in range(1, years.size()):
		assert_lt(years[k - 1], years[k], "earliest first: %s" % [years])


func test_early_modern_years() -> void:
	_each("early_modern_years", _check_early_modern_years)


func _check_early_modern_years(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "anniversary":
		assert_true(ex.get("year", false), "an anniversary's answer is a year")
		assert_false(ABOUT.has(str(d.event)), "an exact year")
		_number_is(ex, int(EVENTS[str(d.event)]) + int(d.years))
		assert_lte(int(EVENTS[str(d.event)]) + int(d.years), 2025, "an anniversary that has been")
		return
	var a := int(EVENTS[str(d.events[0])])
	var b := int(EVENTS[str(d.events[1])])
	assert_lt(a, b)
	assert_true(str(ex.prompt).contains(str(d.events[0])) and str(ex.prompt).contains(str(d.events[1])), "both asked")
	_number_is(ex, b - a)


func test_print_run() -> void:
	_each("print_run", _check_print_run)


func _check_print_run(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"day":
			_number_is(ex, int(d.rate) * int(d.hours))
		"days":
			assert_eq(int(d.sheets) * int(d.copies) % int(d.per_day), 0, "whole days")
			_number_is(ex, float(int(d.sheets) * int(d.copies)) / int(d.per_day))
		"faster":
			assert_eq(int(d.press) % int(d.scribe), 0)
			_number_is(ex, float(d.press) / int(d.scribe))


## Type is a mirror of the page: the picture shows the word's type, and the page shows the word.
func test_mirror_type() -> void:
	_each("mirror_type", _check_mirror_type)


func _check_mirror_type(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var word := str(d.word)
	match str(d.ask):
		"letter", "word":
			assert_eq(str(ex.picture.word), word, "the type shown")
			assert_eq(_right_choice(ex), word)
		"set":
			var letters: Array[String] = []
			for i in range(word.length() - 1, -1, -1):
				letters.append(word[i].to_upper())
			assert_eq(_right_choice(ex), ", ".join(letters))
			assert_true(str(ex.prompt).contains(word.to_upper()), "the word asked")


## In the northern hemisphere the Pole Star's height above the horizon is the latitude; a degree of latitude is about
## 111 km.
func test_pole_star_latitude() -> void:
	_each("pole_star_latitude", _check_pole_star_latitude)


func _check_pole_star_latitude(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"read":
			assert_eq(int(ex.picture.angle), int(d.angle))
			assert_eq(_right_choice(ex), "%d° N" % int(d.angle))
		"sailed":
			_number_is(ex, int(d.to) - int(d.from))
		"km":
			_number_is(ex, (int(d.to) - int(d.from)) * 111)


func test_dead_reckoning() -> void:
	_each("dead_reckoning", _check_dead_reckoning)


func _check_dead_reckoning(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"distance":
			_number_is(ex, int(d.speed) * int(d.hours))
		"hours":
			_number_is(ex, float(d.km) / int(d.speed))
		"days":
			_number_is(ex, float(d.km) / (int(d.speed) * 24))


func test_exchange_sort() -> void:
	_each("exchange_sort", _check_exchange_sort)


func _check_exchange_sort(ex: Dictionary, _level: int) -> void:
	_grouped(ex, EXCHANGE)


func test_ottoman_continents() -> void:
	_each("ottoman_continents", _check_ottoman_continents)


func _check_ottoman_continents(ex: Dictionary, _level: int) -> void:
	_grouped(ex, OTTOMAN)


func _check_reigns(ex: Dictionary, table: Dictionary) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"length":
			var r: Array = table[str(d.ruler)]
			_number_is(ex, int(r[1]) - int(r[0]))
		"longest":
			var best := ""
			for n: Variant in d.rulers:
				var r: Array = table[str(n)]
				assert_true(best == "" or int(r[1]) - int(r[0]) != int(table[best][1]) - int(table[best][0]), "one longest")
				if best == "" or int(r[1]) - int(r[0]) > int(table[best][1]) - int(table[best][0]):
					best = str(n)
			assert_eq(_right_choice(ex), best)
		"when":
			var y := int(d.year)
			var who: Array[String] = []
			for n: Variant in d.rulers:
				var r: Array = table[str(n)]
				if y > int(r[0]) and y < int(r[1]):
					who.append(str(n))
			assert_eq(who.size(), 1, "one ruler in %d" % y)
			assert_eq(_right_choice(ex), who[0] if not who.is_empty() else "")


func test_mughal_reigns() -> void:
	_each("mughal_reigns", _check_mughal_reigns)


func _check_mughal_reigns(ex: Dictionary, _level: int) -> void:
	_check_reigns(ex, MUGHALS)


func test_tudor_reigns() -> void:
	_each("tudor_reigns", _check_tudor_reigns)


func _check_tudor_reigns(ex: Dictionary, _level: int) -> void:
	_check_reigns(ex, TUDORS)


## Kepler's third law in Earth's years and distances: years × years = distance × distance × distance.
func test_kepler_orbit() -> void:
	_each("kepler_orbit", _check_kepler_orbit)


func _check_kepler_orbit(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"longest":
			var far := -1
			for p: Variant in d.planets:
				far = maxi(far, PLANETS.find(str(p)))
			assert_eq(_right_choice(ex), PLANETS[far])
		"years":
			var t := NumberAnswer.value(str(ex.answer))
			assert_almost_eq(t * t, pow(float(d.a), 3.0), 0.001, str(ex.prompt))
		"distance":
			var a := NumberAnswer.value(str(ex.answer))
			assert_almost_eq(pow(a, 3.0), float(d.t) * float(d.t), 0.001, str(ex.prompt))


func test_method_step() -> void:
	_each("method_step", _check_method_step)


func _check_method_step(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "order":
		var steps: Array[String] = []
		for i: Variant in ex.answer:
			steps.append(str(METHOD[str(ex.items[int(i)])]))
		assert_eq(steps, STEPS, "the investigation in the method's order")
		return
	assert_eq(_right_choice(ex), str(METHOD[str(d.statement)]))
	assert_true(str(ex.prompt).contains(str(d.statement)), "the statement is asked about")


func test_spice_profit() -> void:
	_each("spice_profit", _check_spice_profit)


func _check_spice_profit(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var each := int(d.sell) - int(d.buy)
	match str(d.ask):
		"sack":
			_number_is(ex, each)
		"profit":
			_number_is(ex, int(d.sacks) * each - int(d.costs))
		"percent":
			var spent := int(d.sacks) * int(d.buy) + int(d.costs)
			_number_is(ex, 100.0 * (int(d.sacks) * each - int(d.costs)) / spent)


func test_joint_stock() -> void:
	_each("joint_stock", _check_joint_stock)


func _check_joint_stock(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"per_share":
			_number_is(ex, float(d.profit) / int(d.shares))
		"owned":
			_number_is(ex, int(d.profit) / int(d.shares) * int(d.owned))
		"shares":
			_number_is(ex, float(d.paid) / int(d.per))


# --- Geography ----------------------------------------------------------------------------------------------------------

func test_boundary_sort() -> void:
	_each("boundary_sort", _check_boundary_sort)


func _check_boundary_sort(ex: Dictionary, _level: int) -> void:
	_grouped(ex, BOUNDARIES)


## Each whole step of magnitude: 10 times the shaking, about 32 times the energy.
func test_quake_scale() -> void:
	_each("quake_scale", _check_quake_scale)


func _check_quake_scale(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var steps := roundi(float(d.m2) - float(d.m1))
	assert_almost_eq(float(d.m2) - float(d.m1), float(steps), 0.001, "whole steps apart")
	match str(d.ask):
		"shaking":
			if str(ex.type) == "number":
				_number_is(ex, pow(10.0, steps))
			else:
				assert_eq(_right_choice(ex), "%s times" % GenKit.fmt(int(pow(10.0, steps))))
		"energy":
			assert_eq(_right_choice(ex), "about 32 times" if steps == 1 else "about 1,000 times")


func test_plate_drift() -> void:
	_each("plate_drift", _check_plate_drift)


func _check_plate_drift(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var cm := float(d.cm)
	match str(d.ask):
		"metres":
			_number_is(ex, cm * int(d.years) / 100.0)
		"km":
			_number_is(ex, cm * int(d.millions) * 1000000.0 / 100000.0)
		"years":
			_number_is(ex, int(d.km) * 100000.0 / cm)


func test_rock_sort() -> void:
	_each("rock_sort", _check_rock_sort)


func _check_rock_sort(ex: Dictionary, _level: int) -> void:
	_grouped(ex, ROCKS)


func test_weathering_sort() -> void:
	_each("weathering_sort", _check_weathering_sort)


func _check_weathering_sort(ex: Dictionary, _level: int) -> void:
	_grouped(ex, WEATHERING)


func test_glacier_retreat() -> void:
	_each("glacier_retreat", _check_glacier_retreat)


func _check_glacier_retreat(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var moved := int(d.d1) - int(d.d0)
	match str(d.ask):
		"metres":
			_number_is(ex, moved)
		"rate":
			_number_is(ex, float(moved) / (int(d.y1) - int(d.y0)))
		"years":
			_number_is(ex, float(int(d.target) - int(d.d1)) / int(d.rate))


func test_glacial_sort() -> void:
	_each("glacial_sort", _check_glacial_sort)


func _check_glacial_sort(ex: Dictionary, _level: int) -> void:
	_grouped(ex, GLACIAL)


func test_coast_sort() -> void:
	_each("coast_sort", _check_coast_sort)


func _check_coast_sort(ex: Dictionary, _level: int) -> void:
	_grouped(ex, DEFENCES if str(ex.data.ask) == "defences" else COAST)


func test_defence_cost() -> void:
	_each("defence_cost", _check_defence_cost)


func _check_defence_cost(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"cost":
			_number_is(ex, int(d.per_m) * int(d.metres))
		"saved":
			_number_is(ex, (int(d.wall) - int(d.armour)) * int(d.metres))
		"ratio":
			_number_is(ex, float(d.value) / int(d.cost))


## The climate graph shows the biome's own year, and the answer is that biome.
func test_biome_climate() -> void:
	_each("biome_climate", _check_biome_climate)


func _check_biome_climate(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	assert_true(BIOMES.has(str(d.biome)), "known: %s" % d.biome)
	assert_eq(_right_choice(ex), str(d.biome))
	if ex.has("picture"):
		assert_eq(ex.picture.temp, BIOMES[str(d.biome)][0], "its temperatures")
		assert_eq(ex.picture.rain, BIOMES[str(d.biome)][1], "its rain")


## About a tenth of the energy passes up each step of a food chain.
func test_energy_pyramid() -> void:
	_each("energy_pyramid", _check_energy_pyramid)


func _check_energy_pyramid(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "back":
		_number_is(ex, int(d.energy) * pow(10.0, int(d.steps)))
	else:
		_number_is(ex, int(d.energy) / pow(10.0, int(d.steps)))


func test_water_use() -> void:
	_each("water_use", _check_water_use)


func _check_water_use(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"shower":
			_number_is(ex, int(d.per_minute) * int(d.minutes))
		"saved":
			_number_is(ex, int(d.times) * (int(d.bath) - int(d.shower)))
		"family":
			_number_is(ex, int(d.people) * int(d.each) * int(d.days))


## 1 km³ is 1,000 million m³; under 1,700 m³ a person a year is water stress, under 1,000 scarcity, under 500 absolute
## scarcity.
func test_water_per_person() -> void:
	_each("water_per_person", _check_water_per_person)


func _check_water_per_person(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"million_m3":
			_number_is(ex, float(d.million_m3) / float(d.millions))
		"km3":
			_number_is(ex, float(d.km3) * 1000.0 / float(d.millions))
		"stress":
			var per := int(d.per)
			var right := "absolute scarcity" if per < 500 else "water scarcity" if per < 1000 else \
				"water stress" if per < 1700 else "no water stress"
			assert_eq(_right_choice(ex), right, str(per))


func test_mideast_places() -> void:
	_each("mideast_places", _check_mideast_places)


func _check_mideast_places(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var names: Array = d.places
	for p: Variant in names:
		assert_true(MIDEAST.has(str(p)), "known: %s" % p)
	if ex.has("picture"):
		assert_eq((ex.picture.places as Array).size(), names.size(), "every place on the map")
		for pl: Dictionary in ex.picture.places:
			assert_eq([int(pl.lat), int(pl.long)], MIDEAST[str(pl.label)], "%s where it is" % pl.label)
	match str(d.ask):
		"north", "east", "south", "west":
			var key := 1 if str(d.ask) in ["east", "west"] else 0
			var sign := 1 if str(d.ask) in ["north", "east"] else -1
			var best := ""
			for p: Variant in names:
				if best == "" or int(MIDEAST[str(p)][key]) * sign > int(MIDEAST[best][key]) * sign:
					best = str(p)
			for p: Variant in names:
				if str(p) != best:
					assert_ne(int(MIDEAST[str(p)][key]), int(MIDEAST[best][key]), "one furthest")
			assert_eq(_right_choice(ex), best)
		"apart":
			_number_is(ex, absi(int(MIDEAST[str(names[0])][0]) - int(MIDEAST[str(names[1])][0])))


func test_russia_time() -> void:
	_each("russia_time", _check_russia_time)


func _check_russia_time(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var diff := int(RUSSIA_UTC[str(d.b)]) - int(RUSSIA_UTC[str(d.a)])
	assert_gt(diff, 0, "the second city is further east")
	match str(d.ask):
		"ahead":
			_number_is(ex, diff)
		"time":
			var h := int(d.hour) + diff
			assert_lt(h, 24, "the same day")
			assert_eq(_right_choice(ex), "%02d:00" % h)
		"next_day":
			var h := int(d.hour) + diff
			assert_gte(h, 24, "past midnight")
			assert_eq(_right_choice(ex), "%02d:00 the next day" % (h - 24))


func test_field_stats() -> void:
	_each("field_stats", _check_field_stats)


func _check_field_stats(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var v: Array = (d.values as Array).duplicate()
	v.sort()
	var total := 0
	for x: Variant in v:
		total += int(x)
	for x: Variant in d.values:
		assert_true(str(ex.prompt).contains(str(int(x))), "every value shown")
	match str(d.ask):
		"range":
			_number_is(ex, int(v.back()) - int(v[0]))
		"median":
			assert_eq(v.size() % 2, 1, "an odd count")
			_number_is(ex, int(v[v.size() / 2]))
		"mean":
			_number_is(ex, float(total) / v.size())


func test_hazard_plan() -> void:
	_each("hazard_plan", _check_hazard_plan)


func _check_hazard_plan(ex: Dictionary, _level: int) -> void:
	_grouped(ex, HAZARD)


# --- Citizenship --------------------------------------------------------------------------------------------------------

func test_bill_stages() -> void:
	_each("bill_stages", _check_bill_stages)


func _check_bill_stages(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"next":
			var i := STAGES.find(str(d.stage))
			assert_between(i, 0, STAGES.size() - 2)
			assert_eq(_right_choice(ex), STAGES[i + 1])
		"order":
			var at: Array[int] = []
			for i: Variant in ex.answer:
				at.append(STAGES.find(str(ex.items[int(i)])))
			for k in range(1, at.size()):
				assert_eq(at[k], at[k - 1] + 1, "the stages in turn")
		"two_thirds":
			assert_eq(int(d.members) % 3, 0)
			_number_is(ex, int(d.members) * 2 / 3)
		"majority":
			_number_is(ex, int(d.members) / 2 + 1)


func test_speech_sort() -> void:
	_each("speech_sort", _check_speech_sort)


func _check_speech_sort(ex: Dictionary, _level: int) -> void:
	_grouped(ex, SPEECH)


## UK Parliament petitions: 10,000 signatures for a government response, 100,000 to be considered for a debate.
func test_petition_goal() -> void:
	_each("petition_goal", _check_petition_goal)


func _check_petition_goal(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"response":
			_number_is(ex, 10000 - int(d.have))
		"debate":
			_number_is(ex, 100000 - int(d.have))
		"days":
			_number_is(ex, float(100000 - int(d.have)) / int(d.per_day))


func test_charity_share() -> void:
	_each("charity_share", _check_charity_share)


func _check_charity_share(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "gift_aid":
		assert_eq(int(d.given) % 4, 0)
		_number_is(ex, int(d.given) + int(d.given) / 4)
	else:
		_number_is(ex, int(d.raised) * int(d.percent) / 100.0)


func test_fact_check() -> void:
	_each("fact_check", _check_fact_check)


func _check_fact_check(ex: Dictionary, _level: int) -> void:
	_grouped(ex, FACTS)


## A cut axis: bars as tall as their values above the axis's start.
func test_cut_axis() -> void:
	_each("cut_axis", _check_cut_axis)


func _check_cut_axis(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var bars: Array = ex.picture.bars
	assert_eq([float(bars[0][1]), float(bars[1][1])], [float(d.a), float(d.b)], "the bars drawn")
	assert_eq(float(ex.picture.from), float(d.from))
	match str(d.ask):
		"zero":
			assert_eq(ex.answer, is_zero_approx(float(d.from)))
		"looks":
			_number_is(ex, (float(d.b) - float(d.from)) / (float(d.a) - float(d.from)))
		"really":
			_number_is(ex, (float(d.b) - float(d.a)) * 100.0 / float(d.a))


func test_sdg_goal() -> void:
	_each("sdg_goal", _check_sdg_goal)


func _check_sdg_goal(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"name":
			assert_eq(_right_choice(ex), str(SDGS[int(d.goal)]))
		"number":
			_number_is(ex, int(d.goal))
		"match":
			for i in (ex.items as Array).size():
				var n := int(str(ex.items[i]).trim_prefix("Goal "))
				assert_eq(str(ex.matches[int(ex.answer[i])]), str(SDGS[n]), str(ex.items[i]))


func test_career_match() -> void:
	_each("career_match", _check_career_match)


func _check_career_match(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "likes":
		assert_eq(str(CAREERS[_right_choice(ex)]), str(d.group), "a job of the family the person likes")
		for c: Variant in ex.choices:
			if str(c) != _right_choice(ex):
				assert_ne(str(CAREERS[str(c)]), str(d.group), "%s is another family's" % c)
		return
	_grouped(ex, CAREERS)


func test_profit_loss() -> void:
	_each("profit_loss", _check_profit_loss)


func _check_profit_loss(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"profit":
			_number_is(ex, int(d.sold) * float(d.price) - int(d.costs))
		"either":
			var result := int(d.sold) * float(d.price) - (float(d.fixed) + float(d.cost) * int(d.sold))
			assert_ne(result, 0.0)
			var money := SchoolPictureG7Hum._gold(absf(result))
			assert_eq(_right_choice(ex), ("a profit of %s gold" if result > 0 else "a loss of %s gold") % money)
		"break_even":
			_number_is(ex, float(d.fixed) / (float(d.price) - float(d.cost)))
			assert_true(ex.picture.get("hide", false), "the point is hidden")


func test_card_interest() -> void:
	_each("card_interest", _check_card_interest)


func _check_card_interest(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"month", "year":
			_number_is(ex, int(d.owed) * int(d.rate) / 100.0)
		"sort":
			_grouped(ex, CARDS)


func test_portfolio() -> void:
	_each("portfolio", _check_portfolio)


func _check_portfolio(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var each := float(d.total) / int(d.parts)
	match str(d.ask):
		"each":
			_number_is(ex, each)
		"one_fails":
			_number_is(ex, each * (int(d.parts) - 1))
		"rest_grow":
			_number_is(ex, each * (int(d.parts) - 1) * (1.0 + int(d.grow) / 100.0))


func test_reason_kind() -> void:
	_each("reason_kind", _check_reason_kind)


func _check_reason_kind(ex: Dictionary, _level: int) -> void:
	_grouped(ex, REASONS)
