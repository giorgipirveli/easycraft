extends GutTest
## Owner #70, #73 and #111, grade 8 history, geography and citizenship (G8HumGen, "g8h"): the modern world's dates in
## order and apart, coach and train journeys, towns growing, inventions, thinkers, the three powers, the triangular
## trade's goods, abolition, independence and votes for women around the world, who could vote, the world wars' sides,
## a wartime ration book, upstanders, the Universal Declaration's rights, chips doubling, the space race; carbon dioxide,
## climate causes, effects and responses, mitigation and adaptation, development's measures, population pyramids, trade
## balances, supply chains, energy sources and mixes, power's cost, water in food, farms, density, city fixes, tourists'
## spending and effects, the tourism cycle, the ocean's zones, litter in the sea, Mercator's stretch, projections, GIS
## overlays and features; seats and votes, a school vote, ages in law, rights and responsibilities, equality and equity,
## taxes, public spending, budgets, fixed and variable costs, loans, credit scores, the rule of 72, investing each month,
## real returns, consumer rights, best buys, the Global Goals, targets, reasons for and against, personal data and an
## AI's training data. Each generator's answer is worked out again here from the exercise's `data` and this file's own
## facts (typed apart from the generator's tables), for many seeds and every level, and every exercise must be valid
## (ExerciseCheck and the picture's own check).

const SEEDS := 60
const G := "g8h."
const NOW := 2025

const MODERN := {"Watt patents his steam engine": 1769, "Arkwright opens Cromford Mill": 1771,
	"America declares independence": 1776, "The storming of the Bastille": 1789, "Haiti wins independence": 1804,
	"Britain bans its slave trade": 1807, "The Battle of Waterloo": 1815, "The first public steam railway opens": 1825,
	"The Great Reform Act": 1832, "Britain ends slavery in most colonies": 1834, "The Great Exhibition": 1851,
	"Slavery ends in the USA": 1865, "Women vote in New Zealand": 1893, "The Wright brothers fly": 1903,
	"The First World War begins": 1914, "The Armistice": 1918, "Equal votes for women in the UK": 1928,
	"The Second World War begins": 1939, "D-Day": 1944, "The United Nations is founded": 1945,
	"India becomes independent": 1947, "The Universal Declaration of Human Rights": 1948, "Ghana becomes independent": 1957,
	"Yuri Gagarin flies into space": 1961, "The March on Washington": 1963, "The first Moon landing": 1969,
	"The first microprocessor": 1971, "The World Wide Web is invented": 1989, "South Africa's first free election": 1994,
	"People start living on the space station": 2000}
const TOWNS := {"Manchester": [70000, 300000], "Birmingham": [70000, 230000], "Liverpool": [80000, 380000],
	"Glasgow": [80000, 330000], "Leeds": [50000, 170000]}
const INVENTIONS := {"the flying shuttle": "textiles", "the spinning jenny": "textiles", "the water frame": "textiles",
	"the spinning mule": "textiles", "the power loom": "textiles", "Newcomen's steam engine": "power and iron",
	"Watt's steam engine": "power and iron", "smelting iron with coke": "power and iron", "the steam hammer": "power and iron",
	"the Bridgewater Canal": "transport", "the Rocket locomotive": "transport", "the steamship": "transport",
	"macadam roads": "transport"}
const THINKERS := {"John Locke": "natural rights", "Montesquieu": "separation of powers",
	"Rousseau": "the social contract", "Voltaire": "tolerance and free speech", "Mary Wollstonecraft": "the rights of women",
	"Thomas Paine": "the rights of man", "Adam Smith": "free trade and markets"}
const POWERS := {"votes on a new law": "legislature (makes laws)", "debates a bill": "legislature (makes laws)",
	"agrees the yearly budget": "legislature (makes laws)", "can change a law": "legislature (makes laws)",
	"runs the health service": "executive (runs things)", "collects taxes": "executive (runs things)",
	"signs treaties with other countries": "executive (runs things)", "puts new laws into action": "executive (runs things)",
	"decides if a law was broken": "judiciary (judges)", "hears appeals": "judiciary (judges)",
	"checks laws against the constitution": "judiciary (judges)", "sentences someone found guilty": "judiciary (judges)"}
const TRIANGLE := {"cloth": "Europe to West Africa", "metal pots and pans": "Europe to West Africa",
	"glass beads": "Europe to West Africa", "copper bars": "Europe to West Africa", "iron bars": "Europe to West Africa",
	"sugar": "the Americas to Europe", "cotton": "the Americas to Europe", "tobacco": "the Americas to Europe",
	"coffee": "the Americas to Europe", "indigo dye": "the Americas to Europe", "molasses": "the Americas to Europe"}
const ABOLITION := {"Haiti wins independence and freedom": 1804, "Britain bans its slave trade": 1807,
	"the USA bans bringing in enslaved people": 1808, "Chile ends slavery": 1823, "Mexico ends slavery": 1829,
	"Britain ends slavery in most colonies": 1834, "France ends slavery": 1848, "the USA ends slavery": 1865,
	"Brazil ends slavery": 1888}
const INDEPENDENCE := {"India": 1947, "Pakistan": 1947, "Sri Lanka": 1948, "Ghana": 1957, "Nigeria": 1960,
	"Senegal": 1960, "Jamaica": 1962, "Algeria": 1962, "Uganda": 1962, "Kenya": 1963, "Zambia": 1964, "Barbados": 1966,
	"Botswana": 1966}
const SUFFRAGE := {"New Zealand": 1893, "Finland": 1906, "Norway": 1913, "Denmark": 1915, "Germany": 1918,
	"the USA": 1920, "the UK": 1928, "Brazil": 1932, "France": 1944, "Japan": 1945, "India": 1950, "Switzerland": 1971}
const WW1 := {"Britain": "the Allies", "France": "the Allies", "Russia": "the Allies", "Serbia": "the Allies",
	"Belgium": "the Allies", "Italy (from 1915)": "the Allies", "Japan": "the Allies", "the USA (from 1917)": "the Allies",
	"Germany": "the Central Powers", "Austria-Hungary": "the Central Powers", "the Ottoman Empire": "the Central Powers",
	"Bulgaria": "the Central Powers"}
const WW2 := {"Britain": "the Allies", "France": "the Allies", "the Soviet Union (from 1941)": "the Allies",
	"the USA (from 1941)": "the Allies", "China": "the Allies", "Canada": "the Allies", "Australia": "the Allies",
	"Poland": "the Allies", "Germany": "the Axis", "Italy (until 1943)": "the Axis", "Japan": "the Axis"}
const RATIONS := {"butter": 50, "cheese": 50, "tea": 50, "bacon and ham": 100, "margarine": 100, "sugar": 225}
const STANDING := {"tells a trusted adult about bullying": "upstander", "sits with someone who is left out": "upstander",
	"reports a hateful post": "upstander", "says “that's not OK” when it is safe to": "upstander",
	"checks the person who was hurt is all right": "upstander", "asks friends to stop a cruel joke": "upstander",
	"watches and says nothing": "bystander", "scrolls past a hateful post": "bystander",
	"laughs along so as not to stand out": "bystander", "decides it is none of their business": "bystander",
	"walks away and tells no one": "bystander"}
const UDHR := {"freedom of speech": "freedoms", "freedom of belief": "freedoms", "the right to vote": "freedoms",
	"the right to meet peacefully": "freedoms", "freedom from slavery": "freedoms", "a fair trial": "freedoms",
	"the right to education": "a decent life", "the right to work": "a decent life", "rest and holidays": "a decent life",
	"food, clothing and housing": "a decent life", "health care": "a decent life", "fair pay": "a decent life"}
const SPACE := {"the first satellite (1957)": "the Soviet Union", "the first animal in orbit (1957)": "the Soviet Union",
	"the first person in space (1961)": "the Soviet Union", "the first woman in space (1963)": "the Soviet Union",
	"the first spacewalk (1965)": "the Soviet Union", "the first space station (1971)": "the Soviet Union",
	"the first close-up photos of Mars (1965)": "the USA", "the first people to orbit the Moon (1968)": "the USA",
	"the first people on the Moon (1969)": "the USA", "the first space shuttle flight (1981)": "the USA"}
const CO2 := {1960: 317, 1970: 326, 1980: 339, 1990: 354, 2000: 370, 2010: 390, 2020: 414}
const CLIMATE := {"burning coal for electricity": "cause", "cutting down rainforests": "cause",
	"cars burning petrol": "cause", "cattle giving off methane": "cause", "glaciers shrinking": "effect",
	"sea levels rising": "effect", "more intense heatwaves": "effect", "coral reefs bleaching": "effect",
	"building wind farms": "response", "planting new forests": "response", "insulating homes": "response",
	"building flood defences": "response"}
const MITIGATE := {"switching to solar power": "mitigation", "cycling instead of driving": "mitigation",
	"planting forests": "mitigation", "insulating homes": "mitigation", "using less energy": "mitigation",
	"raising flood walls": "adaptation", "growing crops that cope with drought": "adaptation",
	"building homes on stilts": "adaptation", "storing rainwater for dry spells": "adaptation",
	"warning people before heatwaves": "adaptation"}
## What each pyramid's shape says: its youngest band against its oldest.
const SAYS := {"many children, and few people grow old": "wide", "fewer children than before, more adults": "narrowing",
	"about as many people at every age": "column", "fewer children, and many older people": "narrow"}
const CHAINS := {
	"a T-shirt": ["cotton is grown", "it is spun into yarn", "yarn is woven into cloth", "the cloth is dyed",
		"the shirt is sewn", "it is shipped to shops"],
	"a chocolate bar": ["cacao pods are picked", "the beans are dried", "the beans are shipped", "they are roasted and ground",
		"chocolate is made", "the bars are sold"],
	"a phone": ["metals are mined", "chips are made", "the phone is put together", "it is shipped", "it is sold",
		"it is recycled"]}
const ENERGY := {"coal": "fossil fuel", "oil": "fossil fuel", "natural gas": "fossil fuel", "petrol": "fossil fuel",
	"wind": "renewable", "sunlight": "renewable", "flowing rivers (hydro)": "renewable", "geothermal heat": "renewable",
	"tides": "renewable", "waves": "renewable", "uranium": "nuclear", "splitting atoms": "nuclear"}
const FOOD_WATER := {"beef": 15400, "cheese": 5100, "chicken": 4300, "rice": 2500, "bread": 1600, "apples": 820,
	"potatoes": 290, "tomatoes": 210}
const FARMS := {"fields of wheat and barley": "arable", "a potato farm": "arable", "rice paddies": "arable",
	"fields of sugar beet": "arable", "a dairy farm with cows": "pastoral", "sheep on hillsides": "pastoral",
	"a cattle ranch": "pastoral", "goats kept for milk": "pastoral", "crops and cattle on one farm": "mixed",
	"grows barley to feed its own pigs": "mixed", "sheep graze stubble after harvest": "mixed"}
const FARM_SCALE := {"grows food for the family": "subsistence", "a small plot and a few goats": "subsistence",
	"keeps seeds from its own crops to plant": "subsistence", "sells wheat to a flour mill": "commercial",
	"a huge plantation of oil palms": "commercial", "exports bananas abroad": "commercial",
	"a chicken farm supplying shops": "commercial", "grows flowers to sell overseas": "commercial"}
const CITY_FIXES := {"traffic jams": "a metro or bus lanes", "hot summer streets": "trees and green roofs",
	"too few homes": "new flats near stations", "dirty air": "electric buses",
	"floods after storms": "rain gardens and wetlands", "long trips to the shops": "homes and shops mixed together"}
const TOURISM := {"new jobs in hotels and cafés": "good effect", "money to protect a rainforest": "good effect",
	"old crafts and dances kept alive": "good effect", "learning about other cultures": "good effect",
	"litter on beaches": "bad effect", "traffic jams in summer": "bad effect", "house prices too high for locals": "bad effect",
	"footpaths worn away": "bad effect", "coral damaged by boats": "bad effect", "jobs only in the summer": "bad effect"}
const STAGES: Array[String] = ["exploration", "involvement", "development", "consolidation", "stagnation"]
const LITTER := {"a plastic bag": 20, "a foam cup": 50, "a plastic straw": 200, "a drinks can": 200,
	"a plastic bottle": 450, "a nappy": 450, "fishing line": 600}
## Mercator's stretch is 1 ÷ cos(latitude): the latitudes as the exercises say them.
const LATITUDES := {"the equator": 0.0, "about 48° N": 48.0, "60° N": 60.0, "about 66.4° N": 66.4, "about 70.5° N": 70.53,
	"about 75.5° N": 75.52}
const PROJECTIONS := {"steering a ship by compass": "Mercator", "comparing countries' true sizes": "an equal-area map",
	"a good-looking world map": "a compromise map", "distances from the North Pole": "an azimuthal map"}
const GIS := {"a bus stop": "point", "a school": "point", "a postbox": "point", "a well": "point", "a river": "line",
	"a road": "line", "a railway": "line", "a footpath": "line", "a park": "area", "a lake": "area", "a forest": "area",
	"a flood zone": "area"}
const AGES := {"learn to drive a car": 17, "vote in a general election": 18, "buy a pet": 16, "do a light part-time job": 13,
	"leave school (then train to 18)": 16, "get a tattoo": 18, "serve on a jury": 18, "buy a lottery ticket": 18,
	"be held responsible for a crime": 10}
const RIGHTS := {"to be heard about decisions": "a right", "to be safe from harm": "a right", "to an education": "a right",
	"to privacy": "a right", "to play and rest": "a right", "to a fair trial": "a right",
	"to obey the law": "a responsibility", "to respect other people's rights": "a responsibility",
	"to tell the truth in court": "a responsibility", "to look after shared places": "a responsibility",
	"to treat others fairly": "a responsibility"}
const EQUITY := {"everyone gets the same book": "equality (the same)", "one vote each": "equality (the same)",
	"the same rules for every team": "equality (the same)", "the same test for every pupil": "equality (the same)",
	"a ramp beside the steps": "equity (what each needs)", "extra time for a pupil who needs it": "equity (what each needs)",
	"glasses for someone who cannot see the board": "equity (what each needs)",
	"a free lunch for those who cannot pay": "equity (what each needs)"}
const COSTS := {"rent": "fixed cost", "a phone contract": "fixed cost", "a monthly bus pass": "fixed cost",
	"home insurance": "fixed cost", "a gym membership": "fixed cost", "food shopping": "variable cost",
	"electricity": "variable cost", "clothes": "variable cost", "cinema trips": "variable cost", "petrol": "variable cost",
	"presents": "variable cost"}
const CREDIT := {"paying every bill on time": "helps your score", "using only a little of your limit": "helps your score",
	"being on the electoral register": "helps your score", "keeping one card for years": "helps your score",
	"missing a payment": "harms your score", "going over your credit limit": "harms your score",
	"applying for many loans at once": "harms your score", "paying a bill late": "harms your score"}
## UK law: faulty within 30 days, a full refund; faulty later (to 6 months), a repair or replacement first; bought
## online, 14 days to change your mind; otherwise no legal right (a shop may still offer one).
const REFUNDS := {"a faulty kettle, returned after 10 days": "full refund",
	"shoes not as described, after 2 weeks": "full refund", "a jumper bought online, changed mind on day 7": "full refund",
	"a broken toaster bought 3 weeks ago": "full refund", "headphones that break after 3 months": "repair or replacement",
	"a fridge that stops after 5 months": "repair or replacement",
	"a phone screen that fails after 4 months": "repair or replacement",
	"changing your mind about a jumper in a shop": "no legal right", "a phone you dropped and cracked": "no legal right",
	"a lamp you found cheaper elsewhere": "no legal right"}
const GOALS := {"a food bank collection": 2, "a beach litter pick": 14, "planting trees in the park": 15,
	"a reading club for young pupils": 4, "a healthy-eating fair": 3, "a water-saving campaign": 6,
	"a recycling drive": 12, "a coding club for girls": 5}
const SDG_NAMES := {2: "Zero hunger", 3: "Good health and well-being", 4: "Quality education", 5: "Gender equality",
	6: "Clean water and sanitation", 12: "Responsible consumption and production", 14: "Life below water",
	15: "Life on land"}
const PROPOSALS := {
	"cameras that recognise faces at the school gate": {"it could stop strangers coming in": "for",
		"no one needs a pass": "for", "it could find a lost child quickly": "for", "faces are private data": "against",
		"it can make mistakes with some faces": "against", "pupils may feel watched all the time": "against"},
	"an AI that marks homework": {"marks come back at once": "for", "teachers get more time to help": "for",
		"it never gets tired": "for", "it may not understand new ideas": "against", "it could copy unfair patterns": "against",
		"pupils might stop writing for people": "against"},
	"no phones in lessons": {"fewer distractions in class": "for", "less online unkindness in class": "for",
		"more talking face to face": "for", "phones help in an emergency": "against", "some apps help pupils learn": "against",
		"harder to check the bus times": "against"},
	"robots delivering parcels in town": {"no driver needed late at night": "for", "fewer vans on the roads": "for",
		"parcels arrive faster": "for", "delivery drivers could lose work": "against", "it could block the pavement": "against",
		"it might be stolen or damaged": "against"}}
const DATA := {"your full name": "personal data", "your home address": "personal data",
	"a photo of your face": "personal data", "your phone's location": "personal data", "your email address": "personal data",
	"your date of birth": "personal data", "today's weather": "not personal data", "a cake recipe": "not personal data",
	"the height of a mountain": "not personal data", "a city's population": "not personal data",
	"the rules of chess": "not personal data", "a bus timetable": "not personal data"}


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
		assert_true(str(ex.prompt).contains(item.trim_suffix(".")), "the item is asked about")
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


## A match's every item beside its own value.
func _matched(ex: Dictionary, table: Dictionary) -> void:
	assert_eq(str(ex.type), "match", str(ex.prompt))
	for i in (ex.items as Array).size():
		var item := ExerciseCheck.item_text(ex.items[i])
		assert_true(table.has(item), "known: %s" % item)
		assert_eq(ExerciseCheck.item_text(ex.matches[int(ex.answer[i])]), str(table.get(item, "")), item)


## An order exercise of "name (year)" items, right when the years rise.
func _in_year_order(ex: Dictionary, years: Dictionary) -> void:
	assert_eq(str(ex.type), "order", str(ex.prompt))
	var last := -1
	for i: Variant in ex.answer:
		var item := str(ex.items[int(i)])
		var name := item.substr(0, item.rfind(" ("))
		var key := ""
		for k: String in years:
			if k.to_lower() == name.to_lower():
				key = k
		assert_ne(key, "", "known: %s" % name)
		var y := int(years.get(key, 0))
		assert_true(item.contains(str(y)), "%s shows its year" % item)
		assert_gt(y, last, "earliest first: %s" % item)
		last = y


func _gen_ids() -> Array[String]:
	var out: Array[String] = []
	for gen in SchoolGen.ids():
		if gen.begins_with(G):
			out.append(gen)
	return out


func test_the_source_is_registered_and_every_generator_is_tested() -> void:
	assert_true(SchoolGen.SOURCES.has("g8h"), "the source is a SOURCES line")
	var tested := {}
	for m: Dictionary in (get_script() as Script).get_script_method_list():
		tested[str(m.name)] = true
	for gen in _gen_ids():
		assert_true(tested.has("test_" + gen.substr(G.length())), "%s has its own test here" % gen)
	assert_gte(_gen_ids().size(), 60, "grade 8 humanities' generators")


# --- History ------------------------------------------------------------------------------------------------------------

func test_modern_order() -> void:
	_each("modern_order", _check_modern_order)


func _check_modern_order(ex: Dictionary, level: int) -> void:
	assert_eq((ex.items as Array).size(), level + 2)
	_in_year_order(ex, MODERN)


func test_modern_years() -> void:
	_each("modern_years", _check_modern_years)


func _check_modern_years(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "anniversary":
		assert_true(ex.get("year", false), "an anniversary's answer is a year")
		_number_is(ex, int(MODERN[str(d.event)]) + int(d.years))
		assert_lte(int(MODERN[str(d.event)]) + int(d.years), NOW, "an anniversary that has been")
		return
	var a := int(MODERN[str(d.events[0])])
	var b := int(MODERN[str(d.events[1])])
	assert_lt(a, b)
	_number_is(ex, b - a)
	if level == 1:
		assert_lte(b - a, 60, "level 1: close together")


func test_rail_journey() -> void:
	_each("rail_journey", _check_rail_journey)


func _check_rail_journey(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var km := float(d.km)
	match str(d.ask):
		"coach":
			_number_is(ex, km / int(d.coach))
		"saved":
			_number_is(ex, km / int(d.coach) - km / int(d.train))
		"times":
			_number_is(ex, float(d.train) / int(d.coach))
	assert_gt(int(d.train), int(d.coach), "the train is faster")


func test_town_growth() -> void:
	_each("town_growth", _check_town_growth)


func _check_town_growth(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"more":
			_number_is(ex, int(TOWNS[d.town][1]) - int(TOWNS[d.town][0]))
		"each_census":
			_number_is(ex, (int(TOWNS[d.town][1]) - int(TOWNS[d.town][0])) / 5.0)
		"most":
			var best := ""
			for t: Variant in d.towns:
				if best == "" or int(TOWNS[t][1]) - int(TOWNS[t][0]) > int(TOWNS[best][1]) - int(TOWNS[best][0]):
					best = str(t)
			assert_eq(_right_choice(ex), best)


func test_invention_sort() -> void:
	_each("invention_sort", func(ex: Dictionary, _level: int) -> void: _grouped(ex, INVENTIONS))


func test_thinker_idea() -> void:
	_each("thinker_idea", _check_thinker_idea)


func _check_thinker_idea(ex: Dictionary, _level: int) -> void:
	if str(ex.type) == "choice":
		assert_eq(_right_choice(ex), str(ex.data.thinker))
		assert_true(str(ex.prompt).contains(str(THINKERS[ex.data.thinker])), "the idea is asked about")
		return
	_matched(ex, THINKERS)


func test_powers_sort() -> void:
	_each("powers_sort", func(ex: Dictionary, _level: int) -> void: _grouped(ex, POWERS))


func test_triangle_trade() -> void:
	_each("triangle_trade", func(ex: Dictionary, _level: int) -> void: _grouped(ex, TRIANGLE))


## Dated facts: which came first, years apart, four in order.
func _check_dates(ex: Dictionary, table: Dictionary) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"first":
			var a := int(table[d.names[0]])
			var b := int(table[d.names[1]])
			assert_lt(a, b)
			assert_eq(_right_choice(ex).to_lower(), str(d.names[0]).to_lower())
		"apart":
			_number_is(ex, int(table[d.names[1]]) - int(table[d.names[0]]))
		"order":
			_in_year_order(ex, table)


func test_abolition_dates() -> void:
	_each("abolition_dates", func(ex: Dictionary, _level: int) -> void: _check_dates(ex, ABOLITION))


func test_independence_years() -> void:
	_each("independence_years", _check_independence_years)


func _check_independence_years(ex: Dictionary, _level: int) -> void:
	var table := {}
	for c: String in INDEPENDENCE:
		table["%s becomes independent" % c] = INDEPENDENCE[c]
	if str(ex.data.ask) == "ago":
		_number_is(ex, NOW - int(INDEPENDENCE[str(ex.data.country)]))
		return
	_check_dates(ex, table)


func test_suffrage_years() -> void:
	var table := {}
	for c: String in SUFFRAGE:
		table["women vote in %s" % c] = SUFFRAGE[c]
	_each("suffrage_years", func(ex: Dictionary, _level: int) -> void: _check_dates(ex, table))


func test_electorate_share() -> void:
	_each("electorate_share", _check_electorate_share)


func _check_electorate_share(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"one_in":
			_number_is(ex, 100.0 / int(d.n))
		"share":
			_number_is(ex, float(d.voters) * 100.0 / int(d.adults))
		"rise":
			_number_is(ex, (float(d.after) - int(d.before)) * 100.0 / int(d.adults))
			assert_gt(int(d.after), int(d.before))


func test_ww1_sides() -> void:
	_each("ww1_sides", func(ex: Dictionary, _level: int) -> void: _grouped(ex, WW1))


func test_ww2_sides() -> void:
	_each("ww2_sides", func(ex: Dictionary, _level: int) -> void: _grouped(ex, WW2))


func test_ration_book() -> void:
	_each("ration_book", _check_ration_book)


func _check_ration_book(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	_number_is(ex, int(RATIONS[d.food]) * int(d.people) * int(d.weeks))


func test_upstander_sort() -> void:
	_each("upstander_sort", func(ex: Dictionary, _level: int) -> void: _grouped(ex, STANDING))


func test_udhr_rights() -> void:
	_each("udhr_rights", func(ex: Dictionary, _level: int) -> void: _grouped(ex, UDHR))


func test_moore_doubling() -> void:
	_each("moore_doubling", _check_moore_doubling)


func _check_moore_doubling(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "after":
		var v := int(d.start)
		for _y in int(d.years) / 2:
			v *= 2
		_number_is(ex, v)
		return
	var k := 0
	var v := int(d.start)
	while v < int(d.target):
		v *= 2
		k += 1
	assert_eq(v, int(d.target), "a whole number of doublings")
	_number_is(ex, 2 * k)


func test_space_firsts() -> void:
	_each("space_firsts", func(ex: Dictionary, _level: int) -> void: _grouped(ex, SPACE))


# --- Geography ---------------------------------------------------------------------------------------------------------

func test_co2_rise() -> void:
	_each("co2_rise", _check_co2_rise)


func _check_co2_rise(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"rise":
			_number_is(ex, int(CO2[int(d.years[1])]) - int(CO2[int(d.years[0])]))
		"above":
			_number_is(ex, int(CO2[int(d.year)]) - 280)
		"percent":
			_number_is(ex, (float(d.value) - 280.0) * 100.0 / 280.0)


func test_climate_sort() -> void:
	_each("climate_sort", func(ex: Dictionary, _level: int) -> void: _grouped(ex, CLIMATE))


func test_mitigate_adapt() -> void:
	_each("mitigate_adapt", func(ex: Dictionary, _level: int) -> void: _grouped(ex, MITIGATE))


func test_dev_indicator() -> void:
	_each("dev_indicator", _check_dev_indicator)


func _check_dev_indicator(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"longest":
			var best := 0
			for i in 3:
				if int(d.lives[i]) > int(d.lives[best]):
					best = i
			assert_eq(_right_choice(ex), ["Country A", "Country B", "Country C"][best])
			assert_eq(str(ex.picture.rows[best + 1][1]), str(d.lives[best]), "the table shows it")
		"gap":
			_number_is(ex, absi(int(d.lives[d.pair[0]]) - int(d.lives[d.pair[1]])))
		"per_person":
			_number_is(ex, float(d.total) / int(d.people))


func test_pyramid_read() -> void:
	_each("pyramid_read", _check_pyramid_read)


func _check_pyramid_read(ex: Dictionary, _level: int) -> void:
	var bands: Array = ex.picture.bands
	var total := 0
	for b: Array in bands:
		total += int(b[1]) + int(b[2])
	assert_eq(total, 100, "the bands add up to everyone")
	match str(ex.data.ask):
		"biggest":
			var best := 0
			for i in bands.size():
				if int(bands[i][1]) + int(bands[i][2]) > int(bands[best][1]) + int(bands[best][2]):
					best = i
			assert_eq(_right_choice(ex), str(bands[best][0]))
		"young":
			_number_is(ex, int(bands[0][1]) + int(bands[0][2]))
		"stage":
			var young := int(bands[0][1]) + int(bands[0][2])
			var old := int(bands[-1][1]) + int(bands[-1][2])
			match str(SAYS[_right_choice(ex)]):
				"wide":
					assert_gt(young, 4 * old, "a wide base: far more children than old people")
				"narrowing":
					assert_gt(young, 2 * old)
					assert_lte(young, 4 * old)
				"column":
					assert_between(float(young) / old, 0.7, 1.3, "a column: about as many children as old people")
				"narrow":
					assert_lt(float(young) / old, 0.7, "a narrow base")


func test_trade_balance() -> void:
	_each("trade_balance", _check_trade_balance)


func _check_trade_balance(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"balance":
			_number_is(ex, int(d.exports) - int(d.imports))
			assert_gt(int(d.exports), int(d.imports))
		"which":
			var gap := absi(int(d.exports) - int(d.imports))
			var word := "surplus" if int(d.exports) > int(d.imports) else "deficit"
			assert_eq(_right_choice(ex), "a %s of %s million gold" % [word, GenKit.fmt(gap)])
		"share":
			_number_is(ex, float(d.part) * 100.0 / int(d.exports))


func test_supply_chain() -> void:
	_each("supply_chain", _check_supply_chain)


func _check_supply_chain(ex: Dictionary, level: int) -> void:
	var chain: Array = CHAINS[str(ex.data.thing)]
	assert_eq((ex.items as Array).size(), level + 2)
	var last := -1
	for i: Variant in ex.answer:
		var at := chain.find(str(ex.items[int(i)]))
		assert_gt(at, last, "the journey's order")
		last = at


func test_energy_sort() -> void:
	_each("energy_sort", func(ex: Dictionary, _level: int) -> void: _grouped(ex, ENERGY))


func test_energy_mix() -> void:
	_each("energy_mix", _check_energy_mix)


func _check_energy_mix(ex: Dictionary, _level: int) -> void:
	var shares := {}
	var total := 0
	for b: Array in ex.picture.bars:
		shares[str(b[0])] = int(b[1])
		total += int(b[1])
	assert_eq(total, 100, "the mix is all the electricity")
	var green := int(shares.wind) + int(shares.solar) + int(shares.hydro)
	match str(ex.data.ask):
		"renewables":
			_number_is(ex, green)
		"twh":
			_number_is(ex, int(shares[str(ex.data.source)]) * int(ex.data.total) / 100.0)
		"low_carbon":
			_number_is(ex, green + int(shares.nuclear))


func test_power_cost() -> void:
	_each("power_cost", _check_power_cost)


func _check_power_cost(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"kwh":
			_number_is(ex, int(d.kw) * int(d.hours))
		"cost":
			_number_is(ex, int(d.kw) * int(d.hours) * int(d.price))
		"led":
			_number_is(ex, (60.0 - 10.0) * int(d.hours) / 1000.0 * int(d.price))


func test_virtual_water() -> void:
	_each("virtual_water", _check_virtual_water)


func _check_virtual_water(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"kg":
			_number_is(ex, int(FOOD_WATER[d.food]) * int(d.kg))
		"more":
			_number_is(ex, absi(int(FOOD_WATER[d.foods[0]]) - int(FOOD_WATER[d.foods[1]])))
		"list":
			_number_is(ex, int(FOOD_WATER[d.foods[0]]) * int(d.kgs[0]) + int(FOOD_WATER[d.foods[1]]) * int(d.kgs[1]))


func test_farm_type() -> void:
	_each("farm_type", func(ex: Dictionary, _level: int) -> void: _grouped(ex, FARMS))


func test_farm_scale() -> void:
	_each("farm_scale", func(ex: Dictionary, _level: int) -> void: _grouped(ex, FARM_SCALE))


func test_density() -> void:
	_each("density", _check_density)


func _check_density(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"density":
			_number_is(ex, float(d.people) / int(d.km2))
		"district":
			_number_is(ex, int(d.km2) * int(d.density))
		"denser":
			var a := float(d.people[0]) / int(d.km2[0])
			var b := float(d.people[1]) / int(d.km2[1])
			assert_ne(a, b)
			assert_eq(_right_choice(ex), "City A" if a > b else "City B")


func test_city_solutions() -> void:
	_each("city_solutions", _check_city_solutions)


func _check_city_solutions(ex: Dictionary, _level: int) -> void:
	if str(ex.type) == "choice":
		assert_eq(_right_choice(ex), str(CITY_FIXES[str(ex.data.problem)]))
		return
	_matched(ex, CITY_FIXES)


func test_tourist_spend() -> void:
	_each("tourist_spend", _check_tourist_spend)


func _check_tourist_spend(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"total":
			_number_is(ex, int(d.visitors) * int(d.spend))
		"stays":
			_number_is(ex, float(d.total) * (100 - int(d.leak)) / 100.0)
		"each":
			_number_is(ex, float(d.stays) / int(d.residents))


func test_tourism_effects() -> void:
	_each("tourism_effects", func(ex: Dictionary, _level: int) -> void: _grouped(ex, TOURISM))


func test_butler_stage() -> void:
	_each("butler_stage", _check_butler_stage)


func _check_butler_stage(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"picture":
			assert_eq(str(ex.picture.hide), str(d.stage))
			assert_eq(_right_choice(ex), str(d.stage))
		"describe":
			assert_eq(_right_choice(ex), str(d.stage))
		"after":
			assert_eq(_right_choice(ex), STAGES[STAGES.find(str(d.stage)) + 1])


func test_ocean_zone() -> void:
	_each("ocean_zone", _check_ocean_zone)


func _check_ocean_zone(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"zone":
			var depth := int(d.depth)
			var zone := "sunlight zone" if depth < 200 else "twilight zone" if depth < 1000 else "midnight zone" \
				if depth < 4000 else "abyss" if depth < 6000 else "trenches"
			assert_eq(_right_choice(ex), zone)
			assert_eq(SchoolPictureG8Hum.zone_at(depth), zone, "the picture's rule agrees")
		"pressure":
			_number_is(ex, 1 + int(d.depth) / 10.0)
		"minutes":
			_number_is(ex, float(d.depth) / int(d.speed))


func test_plastic_years() -> void:
	_each("plastic_years", _check_plastic_years)


func _check_plastic_years(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"until":
			assert_true(ex.get("year", false), "a year")
			_number_is(ex, NOW + int(LITTER[d.item]))
		"apart":
			_number_is(ex, absi(int(LITTER[d.items[0]]) - int(LITTER[d.items[1]])))
		"order":
			var last := -1
			for i: Variant in ex.answer:
				var y := int(LITTER[str(ex.items[int(i)])])
				assert_gt(y, last, "shortest-lasting first")
				last = y


func test_mercator_stretch() -> void:
	_each("mercator_stretch", _check_mercator_stretch)


func _check_mercator_stretch(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var k := 1.0 / cos(deg_to_rad(float(LATITUDES[str(d.at)])))
	match str(d.ask):
		"stretch":
			assert_almost_eq(NumberAnswer.value(str(ex.answer)), k, 0.02, str(ex.prompt))
		"area":
			assert_almost_eq(NumberAnswer.value(str(ex.answer)), k * k, 0.06, str(ex.prompt))
		"real":
			assert_almost_eq(NumberAnswer.value(str(ex.answer)) * k * k, float(d.shown), 0.2, str(ex.prompt))


func test_projection_choice() -> void:
	_each("projection_choice", _check_projection_choice)


func _check_projection_choice(ex: Dictionary, _level: int) -> void:
	if str(ex.type) == "choice":
		assert_eq(_right_choice(ex), str(PROJECTIONS[str(ex.data.use)]))
		return
	_matched(ex, PROJECTIONS)


func test_overlay_count() -> void:
	_each("overlay_count", _check_overlay_count)


func _check_overlay_count(ex: Dictionary, _level: int) -> void:
	var layers: Array = ex.picture.layers
	var flood: Array = layers[0].cells
	var houses: Array = layers[1].cells
	assert_eq(str(layers[0].what), "flood")
	assert_eq(str(layers[1].what), "houses")
	var n := 0
	var risk := 0
	for y in houses.size():
		for x in str(houses[y]).length():
			if str(houses[y])[x] == "#":
				n += 1
				if str(flood[y])[x] == "#":
					risk += 1
	assert_true(risk >= 1 and risk < n, "some houses at risk, not all")
	match str(ex.data.ask):
		"houses":
			_number_is(ex, n)
		"at_risk":
			_number_is(ex, risk)
		"percent":
			_number_is(ex, risk * 100.0 / n)


func test_gis_features() -> void:
	_each("gis_features", func(ex: Dictionary, _level: int) -> void: _grouped(ex, GIS))


# --- Citizenship ---------------------------------------------------------------------------------------------------------

func test_seat_maths() -> void:
	_each("seat_maths", _check_seat_maths)


func _check_seat_maths(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"winner":
			var shares: Array = d.shares
			var total := 0
			var best := 0
			for i in shares.size():
				total += int(shares[i])
				if int(shares[i]) > int(shares[best]):
					best = i
			assert_eq(total, 100)
			assert_eq(_right_choice(ex), ["Ana", "Ben", "Cal"][best])
		"pr_seats":
			_number_is(ex, int(d.share) * int(d.seats) / 100.0)
		"gap":
			_number_is(ex, int(d.won) - int(d.share) * int(d.seats) / 100.0)


func test_vote_tally() -> void:
	_each("vote_tally", _check_vote_tally)


func _check_vote_tally(ex: Dictionary, _level: int) -> void:
	var votes: Array = ex.data.votes
	var total := 0
	var best := 0
	for i in votes.size():
		total += int(votes[i])
		if int(votes[i]) > int(votes[best]):
			best = i
	match str(ex.data.ask):
		"winner":
			assert_eq(_right_choice(ex), str(ex.picture.bars[best][0]))
		"percent":
			_number_is(ex, int(votes[int(ex.data.idea)]) * 100.0 / total)
		"majority":
			var need := floori(total / 2.0) + 1
			_number_is(ex, need - int(votes[best]))
			assert_gt(need, int(votes[best]), "not a majority yet")


func test_law_ages() -> void:
	_each("law_ages", _check_law_ages)


func _check_law_ages(ex: Dictionary, _level: int) -> void:
	var table := {}
	for t: String in AGES:
		table[t] = "only from 18" if int(AGES[t]) >= 18 else "before 18"
	var d: Dictionary = ex.data
	match str(d.ask):
		"age":
			_number_is(ex, int(AGES[d.thing]))
		"between":
			_number_is(ex, absi(int(AGES[d.things[0]]) - int(AGES[d.things[1]])))
		"sort":
			_grouped(ex, table)


func test_rights_duties() -> void:
	_each("rights_duties", func(ex: Dictionary, _level: int) -> void: _grouped(ex, RIGHTS))


func test_equal_or_fair() -> void:
	_each("equal_or_fair", func(ex: Dictionary, _level: int) -> void: _grouped(ex, EQUITY))


func test_tax_maths() -> void:
	_each("tax_maths", _check_tax_maths)


func _check_tax_maths(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"vat":
			_number_is(ex, int(d.price) * 0.2)
		"income":
			_number_is(ex, (int(d.income) - 12000) * 0.2)
		"bands":
			_number_is(ex, (50000 - 12000) * 0.2 + (int(d.income) - 50000) * 0.4)
			assert_gt(int(d.income), 50000)


func test_spend_share() -> void:
	_each("spend_share", _check_spend_share)


func _check_spend_share(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"amount":
			_number_is(ex, int(d.total) * int(d.share) / 100.0)
		"percent":
			_number_is(ex, float(d.amount) * 100.0 / int(d.total))
		"trade_off":
			_number_is(ex, int(d.total) * int(d.more) / 100.0)


func test_monthly_budget() -> void:
	_each("monthly_budget", _check_monthly_budget)


func _check_monthly_budget(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"left":
			var costs := 0
			for c: Variant in d.costs:
				costs += int(c)
			_number_is(ex, int(d.income) - costs)
			assert_gt(int(d.income), costs)
		"rule":
			_number_is(ex, int(d.income) * {"needs": 0.5, "wants": 0.3, "saving": 0.2}[str(d.part)])
		"months":
			_number_is(ex, float(d.goal) / int(d.save))


func test_fixed_variable() -> void:
	_each("fixed_variable", func(ex: Dictionary, _level: int) -> void: _grouped(ex, COSTS))


func test_loan_cost() -> void:
	_each("loan_cost", _check_loan_cost)


func _check_loan_cost(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"interest":
			_number_is(ex, int(d.p) * int(d.r) * int(d.t) / 100.0)
		"monthly":
			var total := int(d.p) * (1.0 + int(d.r) * int(d.t) / 100.0)
			_number_is(ex, total / (12 * int(d.t)))
		"cheaper":
			var a := int(d.p) * int(d.a[0]) * int(d.a[1])
			var b := int(d.p) * int(d.b[0]) * int(d.b[1])
			assert_ne(a, b)
			assert_eq(_right_choice(ex), "Loan A" if a < b else "Loan B")


func test_credit_score_sort() -> void:
	_each("credit_score_sort", func(ex: Dictionary, _level: int) -> void: _grouped(ex, CREDIT))


func test_rule_of_72() -> void:
	_each("rule_of_72", _check_rule_of_72)


func _check_rule_of_72(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"double":
			_number_is(ex, 72.0 / int(d.rate))
		"grow":
			var doublings := int(d.years) / (72 / int(d.rate))
			_number_is(ex, int(d.start) * pow(2, doublings))
		"sooner":
			_number_is(ex, 72.0 / int(d.rates[0]) - 72.0 / int(d.rates[1]))
			assert_lt(int(d.rates[0]), int(d.rates[1]))


func test_regular_investing() -> void:
	_each("regular_investing", _check_regular_investing)


func _check_regular_investing(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var units := 0.0
	for p: Variant in d.prices:
		assert_eq(120 % int(p), 0, "whole units")
		units += 120.0 / int(p)
	match str(d.ask):
		"units", "total_units":
			_number_is(ex, units)
		"average":
			_number_is(ex, 360.0 / units)


func test_real_return() -> void:
	_each("real_return", _check_real_return)


func _check_real_return(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"real":
			_number_is(ex, int(d.rate) - int(d.inflation))
		"price":
			_number_is(ex, int(d.price) * (1.0 + int(d.inflation) / 100.0))
		"gold":
			_number_is(ex, int(d.savings) * (int(d.rate) - int(d.inflation)) / 100.0)


func test_refund_rights() -> void:
	_each("refund_rights", func(ex: Dictionary, _level: int) -> void: _grouped(ex, REFUNDS))


func test_best_buy() -> void:
	_each("best_buy", _check_best_buy)


func _check_best_buy(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"each":
			_number_is(ex, float(d.price) / int(d.n))
		"better":
			var per_kg_a := int(d.a[1]) * 1000.0 / int(d.a[0])
			var per_kg_b := int(d.b[1]) * 1000.0 / int(d.b[0])
			assert_ne(per_kg_a, per_kg_b)
			assert_eq(_right_choice(ex), "the 500 g bag" if per_kg_a < per_kg_b else "the 1 kg bag")
		"saving":
			var kg := int(d.kg)
			_number_is(ex, absf(int(d.a[1]) * 2.0 * kg - int(d.b[1]) * kg))


func test_goal_for_action() -> void:
	_each("goal_for_action", _check_goal_for_action)


func _check_goal_for_action(ex: Dictionary, _level: int) -> void:
	var short := {2: "Zero hunger", 3: "Good health", 4: "Quality education", 5: "Gender equality", 6: "Clean water",
		12: "Responsible consumption", 14: "Life below water", 15: "Life on land"}
	var table := {}
	for a: String in GOALS:
		table[a] = short[GOALS[a]]
	if str(ex.type) == "choice":
		var goal := int(GOALS[str(ex.data.action)])
		assert_eq(_right_choice(ex), "%d %s" % [goal, SDG_NAMES[goal]])
		return
	_matched(ex, table)


func test_target_progress() -> void:
	_each("target_progress", _check_target_progress)


func _check_target_progress(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	assert_gte(int(d.done), 0)
	match str(d.ask):
		"percent":
			_number_is(ex, float(d.done) * 100.0 / int(d.target))
		"more":
			_number_is(ex, int(d.target) - int(d.done))
		"per_week":
			_number_is(ex, float(int(d.target) - int(d.done)) / int(d.weeks))


func test_for_or_against() -> void:
	_each("for_or_against", _check_for_or_against)


func _check_for_or_against(ex: Dictionary, _level: int) -> void:
	var reasons: Dictionary = PROPOSALS[str(ex.data.proposal)]
	var table := {}
	for r: String in reasons:
		table[r] = "a reason for" if reasons[r] == "for" else "a reason against"
	if str(ex.type) == "choice":
		assert_eq(_right_choice(ex), str(table[str(ex.data.item)]))
		return
	_grouped(ex, table)


func test_personal_data() -> void:
	_each("personal_data", func(ex: Dictionary, _level: int) -> void: _grouped(ex, DATA))


func test_training_data() -> void:
	_each("training_data", _check_training_data)


func _check_training_data(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"share":
			_number_is(ex, float(d.part) * 100.0 / int(d.total))
		"balance":
			_number_is(ex, int(d.adults) - int(d.children))
		"right":
			_number_is(ex, 100.0 - float(d.mistakes) * 100.0 / int(d.total))