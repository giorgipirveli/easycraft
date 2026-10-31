class_name G8HumGen
extends RefCounted
## Owner #70, #73 and #111 (research §6.8): grade 8 history, geography and citizenship generators. History (the modern
## world, 1745 to today): its dates in order and apart, coach and train journeys, towns growing, inventions, thinkers
## and their ideas, the three powers of government, the triangular trade's goods, abolition's dates, independence and
## votes for women around the world, who could vote, the sides of the two world wars, a wartime ration book, upstanders
## and bystanders, the Universal Declaration's rights, chips doubling, the space race's firsts. Geography: carbon dioxide
## rising, climate causes, effects and responses, mitigation and adaptation, development's measures, population
## pyramids, trade balances, supply chains, energy sources, an electricity mix, power and its cost, water in food, kinds
## of farm, population density, city problems and fixes, tourists' spending, tourism's effects, the tourism cycle, the
## ocean's zones, how long litter lasts, Mercator's stretch, which projection for which job, GIS overlays and features.
## Citizenship (in the game's gold): seats and votes, a school vote, ages in law, rights and responsibilities, equality
## and equity, taxes, public spending, a monthly budget, fixed and variable costs, loans, credit scores, the rule of 72,
## investing each month, real returns, consumer rights, best buys, the Global Goals, targets, reasons for and against,
## personal data, an AI's training data. SchoolGen "g8h.<name>", `static func <name>(rng: RandomNumberGenerator, level:
## int) -> Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for
## tests/unit/test_g8_hum_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Omar", "Lena"]
## The year the lessons count from ("how many years ago").
const NOW := 2025

## The modern world's dated events, as the lessons give them: [what happened, the year].
const MODERN: Array = [
	["Watt patents his steam engine", 1769],
	["Arkwright opens Cromford Mill", 1771],
	["America declares independence", 1776],
	["The storming of the Bastille", 1789],
	["Haiti wins independence", 1804],
	["Britain bans its slave trade", 1807],
	["The Battle of Waterloo", 1815],
	["The first public steam railway opens", 1825],
	["The Great Reform Act", 1832],
	["Britain ends slavery in most colonies", 1834],
	["The Great Exhibition", 1851],
	["Slavery ends in the USA", 1865],
	["Women vote in New Zealand", 1893],
	["The Wright brothers fly", 1903],
	["The First World War begins", 1914],
	["The Armistice", 1918],
	["Equal votes for women in the UK", 1928],
	["The Second World War begins", 1939],
	["D-Day", 1944],
	["The United Nations is founded", 1945],
	["India becomes independent", 1947],
	["The Universal Declaration of Human Rights", 1948],
	["Ghana becomes independent", 1957],
	["Yuri Gagarin flies into space", 1961],
	["The March on Washington", 1963],
	["The first Moon landing", 1969],
	["The first microprocessor", 1971],
	["The World Wide Web is invented", 1989],
	["South Africa's first free election", 1994],
	["People start living on the space station", 2000],
]
const ANNIVERSARIES: Array[int] = [25, 50, 75, 100, 150, 200, 250]

## Towns' people in the censuses of 1801 and 1851 (rounded, as the lesson gives them).
const TOWNS := {"Manchester": [70000, 300000], "Birmingham": [70000, 230000], "Liverpool": [80000, 380000],
	"Glasgow": [80000, 330000], "Leeds": [50000, 170000]}
const COACH_SPEEDS: Array[int] = [10, 12]
const TRAIN_SPEEDS: Array[int] = [30, 36, 40, 48, 60]

const INVENTIONS := {"the flying shuttle": 0, "the spinning jenny": 0, "the water frame": 0, "the spinning mule": 0,
	"the power loom": 0, "Newcomen's steam engine": 1, "Watt's steam engine": 1, "smelting iron with coke": 1,
	"the steam hammer": 1, "the Bridgewater Canal": 2, "the Rocket locomotive": 2, "the steamship": 2,
	"macadam roads": 2}
const INVENTION_KINDS: Array[String] = ["textiles", "power and iron", "transport"]
const THINKERS := {"John Locke": "natural rights", "Montesquieu": "separation of powers",
	"Rousseau": "the social contract", "Voltaire": "tolerance and free speech",
	"Mary Wollstonecraft": "the rights of women", "Thomas Paine": "the rights of man",
	"Adam Smith": "free trade and markets"}
const POWERS := {"votes on a new law": 0, "debates a bill": 0, "agrees the yearly budget": 0, "can change a law": 0,
	"runs the health service": 1, "collects taxes": 1, "signs treaties with other countries": 1,
	"puts new laws into action": 1, "decides if a law was broken": 2, "hears appeals": 2,
	"checks laws against the constitution": 2, "sentences someone found guilty": 2}
const POWER_KINDS: Array[String] = ["legislature (makes laws)", "executive (runs things)", "judiciary (judges)"]
const TRIANGLE := {"cloth": 0, "metal pots and pans": 0, "glass beads": 0, "copper bars": 0, "iron bars": 0,
	"sugar": 1, "cotton": 1, "tobacco": 1, "coffee": 1, "indigo dye": 1, "molasses": 1}
const TRIANGLE_LEGS: Array[String] = ["Europe to West Africa", "the Americas to Europe"]
const ABOLITION := {"Haiti wins independence and freedom": 1804, "Britain bans its slave trade": 1807,
	"the USA bans bringing in enslaved people": 1808, "Chile ends slavery": 1823, "Mexico ends slavery": 1829,
	"Britain ends slavery in most colonies": 1834, "France ends slavery": 1848, "the USA ends slavery": 1865,
	"Brazil ends slavery": 1888}
const INDEPENDENCE := {"India": 1947, "Pakistan": 1947, "Sri Lanka": 1948, "Ghana": 1957, "Nigeria": 1960,
	"Senegal": 1960, "Jamaica": 1962, "Algeria": 1962, "Uganda": 1962, "Kenya": 1963, "Zambia": 1964, "Barbados": 1966,
	"Botswana": 1966}
## The year women won the vote in national elections (the UK: all women, 1928).
const SUFFRAGE := {"New Zealand": 1893, "Finland": 1906, "Norway": 1913, "Denmark": 1915, "Germany": 1918,
	"the USA": 1920, "the UK": 1928, "Brazil": 1932, "France": 1944, "Japan": 1945, "India": 1950, "Switzerland": 1971}
const ONE_IN: Array[int] = [2, 4, 5, 10, 20]
const WW1 := {"Britain": 0, "France": 0, "Russia": 0, "Serbia": 0, "Belgium": 0, "Italy (from 1915)": 0, "Japan": 0,
	"the USA (from 1917)": 0, "Germany": 1, "Austria-Hungary": 1, "the Ottoman Empire": 1, "Bulgaria": 1}
const WW1_SIDES: Array[String] = ["the Allies", "the Central Powers"]
const WW2 := {"Britain": 0, "France": 0, "the Soviet Union (from 1941)": 0, "the USA (from 1941)": 0, "China": 0,
	"Canada": 0, "Australia": 0, "Poland": 0, "Germany": 1, "Italy (until 1943)": 1, "Japan": 1}
const WW2_SIDES: Array[String] = ["the Allies", "the Axis"]
## An adult's weekly ration in Britain in the Second World War, in grams (about).
const RATIONS := {"butter": 50, "cheese": 50, "tea": 50, "bacon and ham": 100, "margarine": 100, "sugar": 225}
const STANDING := {"tells a trusted adult about bullying": 0, "sits with someone who is left out": 0,
	"reports a hateful post": 0, "says “that's not OK” when it is safe to": 0, "checks the person who was hurt is all right": 0,
	"asks friends to stop a cruel joke": 0, "watches and says nothing": 1, "scrolls past a hateful post": 1,
	"laughs along so as not to stand out": 1, "decides it is none of their business": 1, "walks away and tells no one": 1}
const STANDING_KINDS: Array[String] = ["upstander", "bystander"]
const UDHR := {"freedom of speech": 0, "freedom of belief": 0, "the right to vote": 0, "the right to meet peacefully": 0,
	"freedom from slavery": 0, "a fair trial": 0, "the right to education": 1, "the right to work": 1,
	"rest and holidays": 1, "food, clothing and housing": 1, "health care": 1, "fair pay": 1}
const UDHR_KINDS: Array[String] = ["freedoms", "a decent life"]
const CHIPS: Array[int] = [2300, 1000, 3000, 5000]
const SPACE := {"the first satellite (1957)": 0, "the first animal in orbit (1957)": 0,
	"the first person in space (1961)": 0, "the first woman in space (1963)": 0, "the first spacewalk (1965)": 0,
	"the first space station (1971)": 0, "the first close-up photos of Mars (1965)": 1,
	"the first people to orbit the Moon (1968)": 1, "the first people on the Moon (1969)": 1,
	"the first space shuttle flight (1981)": 1}
const SPACE_SIDES: Array[String] = ["the Soviet Union", "the USA"]

## Carbon dioxide in the air at Mauna Loa (parts per million, the year's mean, rounded); about 280 before industry.
const CO2 := {1960: 317, 1970: 326, 1980: 339, 1990: 354, 2000: 370, 2010: 390, 2020: 414}
const PRE_INDUSTRY := 280
const CLIMATE := {"burning coal for electricity": 0, "cutting down rainforests": 0, "cars burning petrol": 0,
	"cattle giving off methane": 0, "glaciers shrinking": 1, "sea levels rising": 1, "more intense heatwaves": 1,
	"coral reefs bleaching": 1, "building wind farms": 2, "planting new forests": 2, "insulating homes": 2,
	"building flood defences": 2}
const CLIMATE_KINDS: Array[String] = ["cause", "effect", "response"]
const MITIGATE := {"switching to solar power": 0, "cycling instead of driving": 0, "planting forests": 0,
	"insulating homes": 0, "using less energy": 0, "raising flood walls": 1, "growing crops that cope with drought": 1,
	"building homes on stilts": 1, "storing rainwater for dry spells": 1, "warning people before heatwaves": 1}
const MITIGATE_KINDS: Array[String] = ["mitigation", "adaptation"]
## Population pyramids (% of all people in each band; males, females): a wide base (stage 2) to a narrow base (stage 5).
const PYRAMIDS := {
	"wide base": [["0-14", 21, 20], ["15-29", 14, 14], ["30-44", 9, 9], ["45-59", 5, 5], ["60+", 2, 1]],
	"narrowing": [["0-14", 15, 14], ["15-29", 13, 13], ["30-44", 11, 11], ["45-59", 7, 8], ["60+", 4, 4]],
	"column": [["0-14", 9, 8], ["15-29", 10, 10], ["30-44", 11, 11], ["45-59", 10, 10], ["60+", 10, 11]],
	"narrow base": [["0-14", 6, 6], ["15-29", 8, 8], ["30-44", 10, 10], ["45-59", 12, 12], ["60+", 14, 14]],
}
const PYRAMID_SAYS := {"wide base": "many children, and few people grow old",
	"narrowing": "fewer children than before, more adults", "column": "about as many people at every age",
	"narrow base": "fewer children, and many older people"}
const CHAINS := {
	"a T-shirt": ["cotton is grown", "it is spun into yarn", "yarn is woven into cloth", "the cloth is dyed",
		"the shirt is sewn", "it is shipped to shops"],
	"a chocolate bar": ["cacao pods are picked", "the beans are dried", "the beans are shipped", "they are roasted and ground",
		"chocolate is made", "the bars are sold"],
	"a phone": ["metals are mined", "chips are made", "the phone is put together", "it is shipped",
		"it is sold", "it is recycled"],
}
const ENERGY := {"coal": 0, "oil": 0, "natural gas": 0, "petrol": 0, "wind": 1, "sunlight": 1,
	"flowing rivers (hydro)": 1, "geothermal heat": 1, "tides": 1, "waves": 1, "uranium": 2, "splitting atoms": 2}
const ENERGY_KINDS: Array[String] = ["fossil fuel", "renewable", "nuclear"]
const MIX_SOURCES: Array[String] = ["wind", "solar", "hydro", "gas", "coal", "nuclear"]
const RENEWABLES: Array[String] = ["wind", "solar", "hydro"]
## Water to grow or make 1 kg (litres, about: the Water Footprint Network's world averages).
const FOOD_WATER := {"beef": 15400, "cheese": 5100, "chicken": 4300, "rice": 2500, "bread": 1600, "apples": 820,
	"potatoes": 290, "tomatoes": 210}
const FARMS := {"fields of wheat and barley": 0, "a potato farm": 0, "rice paddies": 0, "fields of sugar beet": 0,
	"a dairy farm with cows": 1, "sheep on hillsides": 1, "a cattle ranch": 1, "goats kept for milk": 1,
	"crops and cattle on one farm": 2, "grows barley to feed its own pigs": 2, "sheep graze stubble after harvest": 2}
const FARM_KINDS: Array[String] = ["arable", "pastoral", "mixed"]
const FARM_SCALE := {"grows food for the family": 0, "a small plot and a few goats": 0,
	"keeps seeds from its own crops to plant": 0, "sells wheat to a flour mill": 1, "a huge plantation of oil palms": 1,
	"exports bananas abroad": 1, "a chicken farm supplying shops": 1, "grows flowers to sell overseas": 1}
const FARM_SCALES: Array[String] = ["subsistence", "commercial"]
const DENSITIES: Array[int] = [2000, 4000, 5000, 8000, 10000, 12000, 20000]
const AREAS: Array[int] = [50, 100, 200, 400, 500, 1000]
const CITY_FIXES := {"traffic jams": "a metro or bus lanes", "hot summer streets": "trees and green roofs",
	"too few homes": "new flats near stations", "dirty air": "electric buses",
	"floods after storms": "rain gardens and wetlands", "long trips to the shops": "homes and shops mixed together"}
const TOURISM := {"new jobs in hotels and cafés": 0, "money to protect a rainforest": 0,
	"old crafts and dances kept alive": 0, "learning about other cultures": 0, "litter on beaches": 1,
	"traffic jams in summer": 1, "house prices too high for locals": 1, "footpaths worn away": 1,
	"coral damaged by boats": 1, "jobs only in the summer": 1}
const TOURISM_KINDS: Array[String] = ["good effect", "bad effect"]
const BUTLER := {"exploration": "a few adventurous visitors and no hotels",
	"involvement": "local people open guest houses for visitors",
	"development": "big hotels are built and visitors pour in",
	"consolidation": "visitors still grow, but more slowly",
	"stagnation": "the resort is full and starts to look tired"}
const STAGES: Array[String] = ["exploration", "involvement", "development", "consolidation", "stagnation"]
const ZONE_NAMES: Array[String] = ["sunlight zone", "twilight zone", "midnight zone", "abyss", "trenches"]
const ZONE_TOPS: Array[int] = [0, 200, 1000, 4000, 6000]
const ZONE_FLOORS: Array[int] = [200, 1000, 4000, 6000, 11000]
## How long litter lasts in the sea (years, scientists' estimates).
const LITTER := {"a plastic bag": 20, "a foam cup": 50, "a plastic straw": 200, "a drinks can": 200,
	"a plastic bottle": 450, "a nappy": 450, "fishing line": 600}
## Mercator's stretch: [latitude as said, the stretch].
const STRETCH: Array = [["the equator", 1.0], ["about 48° N", 1.5], ["60° N", 2.0], ["about 66.4° N", 2.5],
	["about 70.5° N", 3.0], ["about 75.5° N", 4.0]]
const PROJECTION_USES := {"steering a ship by compass": "Mercator", "comparing countries' true sizes": "an equal-area map",
	"a good-looking world map": "a compromise map", "distances from the North Pole": "an azimuthal map"}
const GIS := {"a bus stop": 0, "a school": 0, "a postbox": 0, "a well": 0, "a river": 1, "a road": 1, "a railway": 1,
	"a footpath": 1, "a park": 2, "a lake": 2, "a forest": 2, "a flood zone": 2}
const GIS_KINDS: Array[String] = ["point", "line", "area"]

const CANDIDATES: Array[String] = ["Ana", "Ben", "Cal", "Dee"]
const COUNCIL_IDEAS: Array[String] = ["a garden", "new benches", "a quiet room", "more clubs"]
## Ages in law in England (some differ in Scotland, Wales and Northern Ireland, and in other countries).
const AGES := {"learn to drive a car": 17, "vote in a general election": 18, "buy a pet": 16,
	"do a light part-time job": 13, "leave school (then train to 18)": 16, "get a tattoo": 18, "serve on a jury": 18,
	"buy a lottery ticket": 18, "be held responsible for a crime": 10}
const AGE_KINDS: Array[String] = ["before 18", "only from 18"]
const RIGHTS := {"to be heard about decisions": 0, "to be safe from harm": 0, "to an education": 0, "to privacy": 0,
	"to play and rest": 0, "to a fair trial": 0, "to obey the law": 1, "to respect other people's rights": 1,
	"to tell the truth in court": 1, "to look after shared places": 1, "to treat others fairly": 1}
const RIGHT_KINDS: Array[String] = ["a right", "a responsibility"]
const EQUITY := {"everyone gets the same book": 0, "one vote each": 0, "the same rules for every team": 0,
	"the same test for every pupil": 0, "a ramp beside the steps": 1, "extra time for a pupil who needs it": 1,
	"glasses for someone who cannot see the board": 1, "a free lunch for those who cannot pay": 1}
const EQUITY_KINDS: Array[String] = ["equality (the same)", "equity (what each needs)"]
const ALLOWANCE := 12000
const HIGHER_FROM := 50000
const COSTS := {"rent": 0, "a phone contract": 0, "a monthly bus pass": 0, "home insurance": 0, "a gym membership": 0,
	"food shopping": 1, "electricity": 1, "clothes": 1, "cinema trips": 1, "petrol": 1, "presents": 1}
const COST_KINDS: Array[String] = ["fixed cost", "variable cost"]
const CREDIT := {"paying every bill on time": 0, "using only a little of your limit": 0,
	"being on the electoral register": 0, "keeping one card for years": 0, "missing a payment": 1,
	"going over your credit limit": 1, "applying for many loans at once": 1, "paying a bill late": 1}
const CREDIT_KINDS: Array[String] = ["helps your score", "harms your score"]
const DOUBLING_RATES: Array[int] = [2, 3, 4, 6, 8, 9, 12]
const UNIT_PRICES: Array[int] = [8, 10, 12, 15, 20, 24, 30, 40, 60]
const MONTHLY := 120
const REFUNDS := {"a faulty kettle, returned after 10 days": 0, "shoes not as described, after 2 weeks": 0,
	"a jumper bought online, changed mind on day 7": 0, "a broken toaster bought 3 weeks ago": 0,
	"headphones that break after 3 months": 1, "a fridge that stops after 5 months": 1,
	"a phone screen that fails after 4 months": 1, "changing your mind about a jumper in a shop": 2,
	"a phone you dropped and cracked": 2, "a lamp you found cheaper elsewhere": 2}
const REFUND_KINDS: Array[String] = ["full refund", "repair or replacement", "no legal right"]
## Actions and the Global Goal each serves most (with goals they also touch, never offered as wrong choices).
const ACTIONS := {"a food bank collection": [2, [1, 3]], "a beach litter pick": [14, [12, 15, 6]],
	"planting trees in the park": [15, [13, 11]], "a reading club for young pupils": [4, []],
	"a healthy-eating fair": [3, [2]], "a water-saving campaign": [6, [12, 13]],
	"a recycling drive": [12, [11, 13, 14]], "a coding club for girls": [5, [4, 9, 10]]}
const SDGS := {1: "No poverty", 2: "Zero hunger", 3: "Good health and well-being", 4: "Quality education",
	5: "Gender equality", 6: "Clean water and sanitation", 7: "Affordable and clean energy",
	8: "Decent work and economic growth", 9: "Industry, innovation and infrastructure", 10: "Reduced inequalities",
	11: "Sustainable cities and communities", 12: "Responsible consumption and production", 13: "Climate action",
	14: "Life below water", 15: "Life on land", 16: "Peace, justice and strong institutions",
	17: "Partnerships for the goals"}
## Short names (a match's side has 32 letters at most).
const SDG_SHORT := {2: "Zero hunger", 3: "Good health", 4: "Quality education", 5: "Gender equality",
	6: "Clean water", 12: "Responsible consumption", 14: "Life below water", 15: "Life on land"}
const PROPOSALS := {
	"cameras that recognise faces at the school gate": [["it could stop strangers coming in", "no one needs a pass",
		"it could find a lost child quickly"], ["faces are private data", "it can make mistakes with some faces",
		"pupils may feel watched all the time"]],
	"an AI that marks homework": [["marks come back at once", "teachers get more time to help", "it never gets tired"],
		["it may not understand new ideas", "it could copy unfair patterns", "pupils might stop writing for people"]],
	"no phones in lessons": [["fewer distractions in class", "less online unkindness in class", "more talking face to face"],
		["phones help in an emergency", "some apps help pupils learn", "harder to check the bus times"]],
	"robots delivering parcels in town": [["no driver needed late at night", "fewer vans on the roads",
		"parcels arrive faster"], ["delivery drivers could lose work", "it could block the pavement",
		"it might be stolen or damaged"]],
}
const SIDES: Array[String] = ["a reason for", "a reason against"]
const DATA := {"your full name": 0, "your home address": 0, "a photo of your face": 0, "your phone's location": 0,
	"your email address": 0, "your date of birth": 0, "today's weather": 1, "a cake recipe": 1,
	"the height of a mountain": 1, "a city's population": 1, "the rules of chess": 1, "a bus timetable": 1}
const DATA_KINDS: Array[String] = ["personal data", "not personal data"]


# --- History: the modern world's dates --------------------------------------------------------------------------------

## 3, 4 or 5 of MODERN in order, earliest first (level + 2).
static func modern_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var picks := _pick_any(rng, MODERN, level + 2)
	return _dated_order(rng, picks, "Put these in order, earliest first.")


## Level 1: two events 5-60 years apart; level 2: any two at least 30 apart; level 3: an anniversary (a year).
static func modern_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var e: Array = MODERN[rng.randi_range(0, MODERN.size() - 1)]
		var years: Array = ANNIVERSARIES.filter(func(n: int) -> bool: return int(e[1]) + n <= NOW)
		var n: int = years[rng.randi_range(0, years.size() - 1)]
		ex = K.number("%s: %d. In which year was its %s anniversary?" % [e[0], e[1], _ordinal(n)], str(int(e[1]) + n),
			"Add the anniversary's years to the year it happened.", "%d + %d = %d." % [e[1], n, int(e[1]) + n])
		ex.year = true
		ex.data = {"ask": "anniversary", "event": e[0], "years": n}
		return ex
	var a: Array = []
	var b: Array = []
	for _try in 200:
		var two := _pick_any(rng, MODERN, 2)
		two.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
		a = two[0]
		b = two[1]
		var g := int(b[1]) - int(a[1])
		if g >= 5 and (g <= 60 if level == 1 else g >= 30):
			break
	var gap := int(b[1]) - int(a[1])
	ex = K.number("%s: %d. %s: %d. How many years later was the second?" % [a[0], a[1], b[0], b[1]], str(gap),
		"Take the earlier year from the later one.", "%d − %d = %d years." % [b[1], a[1], gap])
	ex.data = {"ask": "apart", "events": [a[0], b[0]]}
	return ex


# --- History: the Industrial Revolution ---------------------------------------------------------------------------

## Level 1: hours by stagecoach; level 2: hours the train saves; level 3: how many times as fast.
static func rail_journey(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var coach: int = COACH_SPEEDS[rng.randi_range(0, COACH_SPEEDS.size() - 1)]
	var trains: Array = TRAIN_SPEEDS.filter(func(t: int) -> bool: return t % coach == 0)
	var train: int = trains[rng.randi_range(0, trains.size() - 1)]
	var lcm := coach * train / _gcd(coach, train)
	var km := lcm * rng.randi_range(1, maxi(1, 360 / lcm))
	if km < 60:
		km = lcm * maxi(1, ceili(60.0 / lcm))
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A stagecoach travels at about %d km an hour. How many hours does it take to go %d km?" % [coach, km],
				str(km / coach), "Time is the distance divided by the speed.", "%d ÷ %d = %d hours." % [km, coach, km / coach])
		2:
			var saved := km / coach - km / train
			ex = K.number("A trip of %d km takes a stagecoach at %d km an hour, or an early train at %d km an hour. How many hours does the train save?" % [
				km, coach, train], str(saved), "Find each journey's hours, then take one from the other.",
				"%d ÷ %d = %d hours; %d ÷ %d = %d hours; %d − %d = %d hours saved." % [km, coach, km / coach, km, train,
				km / train, km / coach, km / train, saved])
		_:
			ex = K.number("A stagecoach went about %d km an hour; an early train %d km an hour. How many times as fast was the train?" % [
				coach, train], str(train / coach), "Divide the train's speed by the coach's.",
				"%d ÷ %d = %d times as fast." % [train, coach, train / coach])
	ex.data = {"ask": ["coach", "saved", "times"][level - 1], "km": km, "coach": coach, "train": train}
	return ex


## Level 1: how many more people from 1801 to 1851; level 2: the growth each ten years; level 3: which grew most.
static func town_growth(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = TOWNS.keys()
	var ex: Dictionary
	if level < 3:
		var t: String = names[rng.randi_range(0, names.size() - 1)]
		var a := int(TOWNS[t][0])
		var b := int(TOWNS[t][1])
		if level == 1:
			ex = K.number("%s had about %s people in 1801 and about %s in 1851. How many more people was that?" % [t, K.fmt(a),
				K.fmt(b)], str(b - a), "Take the earlier number from the later one.", "%s − %s = %s more people." % [
				K.fmt(b), K.fmt(a), K.fmt(b - a)])
		else:
			ex = K.number("%s grew from about %s people in 1801 to %s in 1851: five ten-year gaps between censuses. On average, how many more people each ten years?" % [
				t, K.fmt(a), K.fmt(b)], str((b - a) / 5), "Find the whole growth, then share it between the five gaps.",
				"%s − %s = %s; %s ÷ 5 = %s people." % [K.fmt(b), K.fmt(a), K.fmt(b - a), K.fmt(b - a), K.fmt((b - a) / 5)])
		ex.data = {"ask": "more" if level == 1 else "each_census", "town": t}
		return ex
	var three := _pick_any(rng, names, 3)
	var best: String = three[0]
	var lines: Array[String] = []
	for t: Variant in three:
		if int(TOWNS[t][1]) - int(TOWNS[t][0]) > int(TOWNS[best][1]) - int(TOWNS[best][0]):
			best = str(t)
		lines.append("%s %s to %s" % [t, K.fmt(int(TOWNS[t][0])), K.fmt(int(TOWNS[t][1]))])
	var grew: Array[String] = []
	for t: Variant in three:
		grew.append("%s %s" % [t, K.fmt(int(TOWNS[t][1]) - int(TOWNS[t][0]))])
	ex = K.choice(rng, "From 1801 to 1851: %s. Which town gained the most people?" % "; ".join(lines), best,
		three.filter(func(t: Variant) -> bool: return str(t) != best), "Work out each town's growth, then compare them.",
		"Growth: %s. %s gained the most." % [", ".join(grew), best])
	ex.data = {"ask": "most", "towns": three}
	return ex


static func invention_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, INVENTIONS, INVENTION_KINDS, "Which part of the Industrial Revolution was %s?",
		"Sort these inventions: textiles, power and iron, or transport?",
		"Did it make cloth, make power or iron, or move people and goods?")


# --- History: ideas of liberty ------------------------------------------------------------------------------------------

## Level 1: which thinker wrote about an idea; levels 2-3: match three or four thinkers to their ideas.
static func thinker_idea(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = THINKERS.keys()
	if level == 1:
		var t: String = names[rng.randi_range(0, names.size() - 1)]
		var ex := K.choice(rng, "Which Enlightenment thinker is best known for writing about %s?" % THINKERS[t], t,
			_pick_any(rng, names.filter(func(n: Variant) -> bool: return str(n) != t), 3),
			"Think back to the lesson's card of thinkers and their big ideas.", "%s wrote about %s." % [t, THINKERS[t]])
		ex.data = {"ask": "one", "thinker": t}
		return ex
	return _match(rng, "Match each thinker to the idea they wrote about.", _pick_any(rng, names, level + 1), THINKERS,
		"Rights, powers, contracts, tolerance, women, markets: who wrote which?")


static func powers_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, POWERS, POWER_KINDS, "Which branch of government %s?",
		"Sort these jobs: lawmakers, the government that runs things, or the courts?",
		"Lawmakers make and change laws; the executive puts them into action; judges decide cases.")


# --- History: slavery and abolition -------------------------------------------------------------------------------------

static func triangle_trade(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, TRIANGLE, TRIANGLE_LEGS, "On the triangular trade, which way did ships carry %s?",
		"Sort these goods by the leg of the triangle that carried them.",
		"Ships took factory goods from Europe to Africa, and brought back crops grown on plantations in the Americas.")


## Level 1: which came first; level 2: years between two; level 3: four in order.
static func abolition_dates(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _dates(rng, level, ABOLITION, "When slavery ended", "%s (%d)")


static func independence_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = INDEPENDENCE.keys()
	if level == 1:
		var c: String = names[rng.randi_range(0, names.size() - 1)]
		var y := int(INDEPENDENCE[c])
		var ex := K.number("%s became independent in %d. How many years before %d was that?" % [c, y, NOW], str(NOW - y),
			"Take the earlier year from the later one.", "%d − %d = %d years." % [NOW, y, NOW - y])
		ex.data = {"ask": "ago", "country": c}
		return ex
	var table := {}
	for c: Variant in names:
		table["%s becomes independent" % c] = INDEPENDENCE[c]
	return _dates(rng, level, table, "Independence", "%s (%d)")


static func suffrage_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var table := {}
	for c: Variant in SUFFRAGE:
		table["women vote in %s" % c] = SUFFRAGE[c]
	return _dates(rng, level, table, "Votes for women", "%s (%d)")


## Level 1: "1 in N" as a percentage; level 2: voters out of adults as a percentage; level 3: the rise in points.
static func electorate_share(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var n: int = ONE_IN[rng.randi_range(0, ONE_IN.size() - 1)]
		ex = K.number("After a reform, about 1 in every %d adults could vote. What percentage is that?" % n, str(100 / n),
			"Find how many out of 100: divide 100 by %d." % n, "100 ÷ %d = %d, so %d%%." % [n, 100 / n, 100 / n])
		ex.data = {"ask": "one_in", "n": n}
		return ex
	var adults: int = [2000, 4000, 5000, 8000, 10000][rng.randi_range(0, 4)]
	var before := adults * rng.randi_range(1, 4) * 5 / 100
	if level == 2:
		ex = K.number("A town has %s adults, and %s of them can vote. What percentage can vote?" % [K.fmt(adults),
			K.fmt(before)], str(before * 100 / adults), "Divide the voters by the adults, then multiply by 100.",
			"%s ÷ %s × 100 = %d%%." % [K.fmt(before), K.fmt(adults), before * 100 / adults])
		ex.data = {"ask": "share", "adults": adults, "voters": before}
		return ex
	var after := before + adults * rng.randi_range(2, 8) * 5 / 100
	var p0 := before * 100 / adults
	var p1 := after * 100 / adults
	ex = K.number("A town has %s adults. Before a reform, %s could vote; after it, %s. By how many percentage points did the share rise?" % [
		K.fmt(adults), K.fmt(before), K.fmt(after)], str(p1 - p0), "Find each percentage first, then take one from the other.",
		"%d%% before, %d%% after: %d − %d = %d points." % [p0, p1, p1, p0, p1 - p0])
	ex.data = {"ask": "rise", "adults": adults, "before": before, "after": after}
	return ex


# --- History: the world wars and the Holocaust ------------------------------------------------------------------------

static func ww1_sides(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, WW1, WW1_SIDES, "In the First World War, which side was %s on?",
		"Sort these countries into the two sides of the First World War.",
		"Remember the two alliances of 1914, and who joined later.")


static func ww2_sides(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, WW2, WW2_SIDES, "In the Second World War, which side was %s on?",
		"Sort these countries into the two sides of the Second World War.",
		"The Axis was Germany and its partners; most other countries that fought joined the Allies.")


## Level 1: a family's ration for a week; level 2: one adult's over some weeks; level 3: a family's over some weeks.
static func ration_book(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var foods: Array = RATIONS.keys()
	var food: String = foods[rng.randi_range(0, foods.size() - 1)]
	var g := int(RATIONS[food])
	var people := 1 if level == 2 else rng.randi_range(2, 5)
	var weeks := 1 if level == 1 else rng.randi_range(2, 4)
	var total := g * people * weeks
	var ex: Dictionary
	if level == 1:
		ex = K.number("In the war, an adult's weekly ration of %s was about %d g. How many grams did a family of %d adults get in a week?" % [
			food, g, people], str(total), "Multiply one person's ration by the people.", "%d × %d = %s g." % [g, people,
			K.fmt(total)])
	elif level == 2:
		ex = K.number("An adult's weekly ration of %s was about %d g. How many grams did one adult get in %d weeks?" % [food, g,
			weeks], str(total), "Multiply the weekly ration by the weeks.", "%d × %d = %s g." % [g, weeks, K.fmt(total)])
	else:
		ex = K.number("An adult's weekly ration of %s was about %d g. How many grams did %d adults get in %d weeks?" % [food, g,
			people, weeks], str(total), "Find one week for everyone, then multiply by the weeks.",
			"%d × %d = %s g a week; × %d = %s g." % [g, people, K.fmt(g * people), weeks, K.fmt(total)])
	ex.data = {"ask": "ration", "food": food, "people": people, "weeks": weeks}
	return ex


static func upstander_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, STANDING, STANDING_KINDS, "Someone %s. Upstander or bystander?",
		"Sort these: is each person an upstander or a bystander?",
		"An upstander does something to help, safely; a bystander sees it and does nothing.")


# --- History: building peace and the digital age ----------------------------------------------------------------------

static func udhr_rights(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, UDHR, UDHR_KINDS, "Which kind of right in the Universal Declaration is %s?",
		"Sort these rights: freedoms, or what everyone needs for a decent life?",
		"Freedoms protect what you may say, believe and do; a decent life is about school, work, food, homes and health.")


## Chips' transistors double about every 2 years. Level 1: after 2 or 4 years; level 2: after 6-10; level 3: the
## years to reach a number.
static func moore_doubling(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var start: int = CHIPS[rng.randi_range(0, CHIPS.size() - 1)]
	var said := "The first microprocessor, in 1971, had about %s transistors." % K.fmt(start) if start == 2300 \
		else "A chip has %s transistors." % K.fmt(start)
	var ex: Dictionary
	if level < 3:
		var years: int = [2, 4][rng.randi_range(0, 1)] if level == 1 else [6, 8, 10][rng.randi_range(0, 2)]
		var n := start * int(pow(2, years / 2))
		var steps: Array[String] = []
		var v := start
		for _k in years / 2:
			v *= 2
			steps.append(K.fmt(v))
		ex = K.number("%s If the number doubles every 2 years, how many would a chip have %d years later?" % [said, years], str(n),
			"Count the doublings (one every 2 years), then double that many times.",
			"%d doublings: %s." % [years / 2, ", ".join(steps)])
		ex.data = {"ask": "after", "start": start, "years": years}
		return ex
	var k := rng.randi_range(3, 6)
	var target := start * int(pow(2, k))
	ex = K.number("%s If the number doubles every 2 years, after how many years would a chip have %s?" % [said, K.fmt(target)],
		str(k * 2), "Count how many doublings it takes, then 2 years for each.",
		"%s ÷ %s = %d = 2 to the power %d: %d doublings × 2 = %d years." % [K.fmt(target), K.fmt(start), int(pow(2, k)), k, k,
		k * 2])
	ex.data = {"ask": "years_to", "start": start, "target": target}
	return ex


static func space_firsts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, SPACE, SPACE_SIDES, "In the space race, who achieved %s?",
		"Sort these firsts of the space race: the Soviet Union or the USA?",
		"The Soviet Union won most of the early firsts; the USA won the race to the Moon.")


# --- Geography: climate change -------------------------------------------------------------------------------------------

## Level 1: the rise between two years; level 2: how far above 280 ppm; level 3: the percentage rise from 280.
static func co2_rise(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var years: Array = CO2.keys()
	var ex: Dictionary
	if level == 1:
		var two := _pick_any(rng, years, 2)
		two.sort()
		var a := int(CO2[two[0]])
		var b := int(CO2[two[1]])
		ex = K.number("Carbon dioxide in the air was %d parts per million (ppm) in %d and %d ppm in %d. By how much did it rise?" % [
			a, two[0], b, two[1]], str(b - a), "Take the earlier level from the later one.", "%d − %d = %d ppm." % [b, a, b - a])
		ex.data = {"ask": "rise", "years": two}
		return ex
	if level == 2:
		var y: int = years[rng.randi_range(0, years.size() - 1)]
		var v := int(CO2[y])
		ex = K.number("Before industry, the air had about %d ppm of carbon dioxide. In %d it had %d ppm. How many ppm higher was that?" % [
			PRE_INDUSTRY, y, v], str(v - PRE_INDUSTRY), "Take the old level from the new one.", "%d − %d = %d ppm." % [v,
			PRE_INDUSTRY, v - PRE_INDUSTRY])
		ex.data = {"ask": "above", "year": y}
		return ex
	var pct := rng.randi_range(2, 10) * 5
	var v := PRE_INDUSTRY * (100 + pct) / 100
	ex = K.number("Carbon dioxide rose from about %d ppm before industry to %d ppm. By what percentage did it rise?" % [
		PRE_INDUSTRY, v], str(pct), "Find the rise, then divide it by the old level and multiply by 100.",
		"%d − %d = %d; %d ÷ %d × 100 = %d%%." % [v, PRE_INDUSTRY, v - PRE_INDUSTRY, v - PRE_INDUSTRY, PRE_INDUSTRY, pct])
	ex.data = {"ask": "percent", "value": v}
	return ex


static func climate_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, CLIMATE, CLIMATE_KINDS, "Is %s a cause of climate change, an effect, or a response?",
		"Sort these: a cause of climate change, an effect of it, or a response to it?",
		"Causes add greenhouse gases; effects are what warming does; responses are what people do about it.")


static func mitigate_adapt(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, MITIGATE, MITIGATE_KINDS, "Is %s mitigation or adaptation?",
		"Sort these: mitigation (cutting the cause) or adaptation (living with the changes)?",
		"Mitigation cuts greenhouse gases; adaptation protects people from the changes that come.")


# --- Geography: development -----------------------------------------------------------------------------------------------

## Three countries' measures in a table. Level 1: the longest lives; level 2: the gap in years; level 3: income for
## each person.
static func dev_indicator(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array[String] = ["Country A", "Country B", "Country C"]
	var lives: Array = _distinct(rng, 3, 52, 84)
	var school: Array = _distinct(rng, 3, 4, 14)
	var income: Array = _distinct(rng, 3, 2, 60)
	var rows: Array = [["", "life (years)", "school (years)", "income (thousand gold)"]]
	for i in 3:
		rows.append([names[i], str(lives[i]), str(school[i]), str(income[i])])
	var pic := {"kind": "table", "rows": rows}
	var ex: Dictionary
	if level == 1:
		var best := 0
		for i in 3:
			if int(lives[i]) > int(lives[best]):
				best = i
		ex = K.choice(rng, "Which country's people live longest on average?", names[best],
			names.filter(func(n: String) -> bool: return n != names[best]), "Look down the life expectancy column for the biggest number.",
			"%s: %d years, the longest." % [names[best], lives[best]], pic)
		ex.data = {"ask": "longest", "lives": lives}
		return ex
	if level == 2:
		var two := _pick_any(rng, [0, 1, 2], 2)
		var i: int = two[0]
		var j: int = two[1]
		var gap := absi(int(lives[i]) - int(lives[j]))
		ex = K.number("How many years longer do people live, on average, in the longer-lived of %s and %s?" % [names[i], names[j]],
			str(gap), "Find both life expectancies, then take the smaller from the bigger.", "%d − %d = %d years." % [
			maxi(int(lives[i]), int(lives[j])), mini(int(lives[i]), int(lives[j])), gap], pic)
		ex.data = {"ask": "gap", "lives": lives, "pair": [i, j]}
		return ex
	var people := rng.randi_range(2, 60)
	var each := rng.randi_range(2, 50)
	var total := people * each
	ex = K.number("A country's people earn %s million gold in a year, and %d million people live there. What is the income for each person, in gold?" % [
		K.fmt(total), people], str(each), "Divide the country's income by its people.", "%s million ÷ %d million = %d gold each." % [
		K.fmt(total), people, each])
	ex.data = {"ask": "per_person", "total": total, "people": people}
	return ex


## A population pyramid. Level 1: the biggest age band; level 2: the share aged 0-14; level 3: what its shape says.
static func pyramid_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var shapes: Array = PYRAMIDS.keys()
	var shape: String = shapes[rng.randi_range(0, shapes.size() - 1)]
	var bands: Array = (PYRAMIDS[shape] as Array).duplicate(true)
	# Nudge the youngest band and the next one (the totals stay 100), so pyramids of one shape differ.
	var nudge := rng.randi_range(-1, 1)
	if shape != "wide base":
		bands[0][1] = int(bands[0][1]) + nudge
		bands[1][1] = int(bands[1][1]) - nudge
	var most := 0
	for b: Array in bands:
		most = maxi(most, maxi(int(b[1]), int(b[2])))
	var pic := {"kind": "pop_pyramid", "bands": bands, "top": maxi(10, ceili((most + 1) / 5.0) * 5), "step": 5}
	var ex: Dictionary
	if level == 1:
		var best := 0
		var sums: Array[int] = []
		for i in bands.size():
			sums.append(int(bands[i][1]) + int(bands[i][2]))
			if sums[i] > sums[best]:
				best = i
		var labels: Array = bands.map(func(b: Array) -> String: return str(b[0]))
		var others: Array = labels.filter(func(l: Variant) -> bool: return str(l) != str(labels[best]))
		ex = K.choice(rng, "Which age band holds the most people?", labels[best], others.slice(0, 3),
			"Add each band's two bars and find the widest.",
			"%s: %d%% + %d%% = %d%%, the most." % [labels[best], bands[best][1], bands[best][2], sums[best]], pic)
		ex.data = {"ask": "biggest", "bands": bands}
		return ex
	if level == 2:
		var young := int(bands[0][1]) + int(bands[0][2])
		ex = K.number("What percentage of the people are aged 0-14?", str(young), "Add the two bars of the youngest band.",
			"%d%% + %d%% = %d%%." % [bands[0][1], bands[0][2], young], pic)
		ex.data = {"ask": "young", "bands": bands}
		return ex
	var says := str(PYRAMID_SAYS[shape])
	ex = K.choice(rng, "What does this pyramid's shape tell you about the country?", says,
		PYRAMID_SAYS.values().filter(func(s: Variant) -> bool: return str(s) != says),
		"Compare the bottom of the pyramid (children) with the top (older people).",
		"Its shape (%s) shows %s." % [shape, says], pic)
	ex.data = {"ask": "stage", "shape": shape}
	return ex


# --- Geography: a connected world ---------------------------------------------------------------------------------------

## Level 1: the trade balance; level 2: surplus or deficit; level 3: one partner's share of exports.
static func trade_balance(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var exports := rng.randi_range(20, 90) * 10
	var imports := exports + rng.randi_range(-30, 30) * 10
	if imports == exports:
		imports += 50
	var ex: Dictionary
	if level == 1:
		var hi := maxi(exports, imports)
		var lo := mini(exports, imports)
		exports = hi
		imports = lo
		ex = K.number("A country sells %s million gold of goods abroad and buys %s million gold. By how much do its exports beat its imports, in million gold?" % [
			K.fmt(exports), K.fmt(imports)], str(exports - imports), "Take the imports from the exports.",
			"%s − %s = %s million gold: a surplus." % [K.fmt(exports), K.fmt(imports), K.fmt(exports - imports)])
		ex.data = {"ask": "balance", "exports": exports, "imports": imports}
		return ex
	if level == 2:
		var right := "a surplus of %s million gold" % K.fmt(absi(exports - imports)) if exports > imports \
			else "a deficit of %s million gold" % K.fmt(absi(exports - imports))
		var wrong := "a deficit of %s million gold" % K.fmt(absi(exports - imports)) if exports > imports \
			else "a surplus of %s million gold" % K.fmt(absi(exports - imports))
		ex = K.choice(rng, "Exports: %s million gold. Imports: %s million gold. What is the trade balance?" % [K.fmt(exports),
			K.fmt(imports)], right, [wrong, "balanced: no gap"], "More exports than imports is a surplus; more imports is a deficit.",
			"%s − %s: %s." % [K.fmt(exports), K.fmt(imports), right])
		ex.data = {"ask": "which", "exports": exports, "imports": imports}
		return ex
	var pct := rng.randi_range(1, 9) * 10
	var part := exports * pct / 100
	exports = part * 100 / pct
	ex = K.number("A country exports %s million gold of goods. %s million gold of it goes to one partner. What percentage is that?" % [
		K.fmt(exports), K.fmt(part)], str(pct), "Divide the partner's part by all the exports, then multiply by 100.",
		"%s ÷ %s × 100 = %d%%." % [K.fmt(part), K.fmt(exports), pct])
	ex.data = {"ask": "share", "exports": exports, "part": part}
	return ex


## 3, 4 or 5 steps of a product's journey in order (level + 2).
static func supply_chain(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = CHAINS.keys()
	var thing: String = names[rng.randi_range(0, names.size() - 1)]
	var steps: Array = CHAINS[thing]
	var at := _pick_any(rng, range(steps.size()), level + 2)
	at.sort()
	var in_order: Array = at.map(func(i: int) -> String: return str(steps[i]))
	var ex := K.order(rng, "Put the journey of %s in order, first step first." % thing, in_order,
		"Start where the raw material comes from and end with the shop or what happens after.",
		"In order: %s." % ", ".join(in_order))
	ex.data = {"ask": "chain", "thing": thing}
	return ex


# --- Geography: energy ----------------------------------------------------------------------------------------------------

static func energy_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, ENERGY, ENERGY_KINDS, "What kind of energy source is %s?",
		"Sort these energy sources: fossil fuel, renewable or nuclear?",
		"Fossil fuels are the remains of ancient life; renewables never run out; nuclear energy comes from atoms.")


## A country's electricity by source (%, a bar graph). Level 1: the renewables' share; level 2: one source's TWh;
## level 3: the low-carbon share (renewables and nuclear).
static func energy_mix(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var parts := _split(rng, 20, MIX_SOURCES.size())   # 20 fives: every share a multiple of 5, at least 5
	var mix := {}
	var bars: Array = []
	for i in MIX_SOURCES.size():
		mix[MIX_SOURCES[i]] = parts[i] * 5
		bars.append([MIX_SOURCES[i], parts[i] * 5])
	var most := 0
	for b: Array in bars:
		most = maxi(most, int(b[1]))
	var pic := {"kind": "bar_graph", "bars": bars, "step": 10, "top": ceili(most / 10.0) * 10, "name": "Electricity (%)"}
	var green := 0
	for s: String in RENEWABLES:
		green += int(mix[s])
	var ex: Dictionary
	if level == 1:
		ex = K.number("What percentage of this country's electricity comes from renewables (wind, solar and hydro)?", str(green),
			"Add the three renewable bars.", "%d + %d + %d = %d%%." % [mix.wind, mix.solar, mix.hydro, green], pic)
		ex.data = {"ask": "renewables", "mix": mix}
		return ex
	if level == 2:
		var s: String = MIX_SOURCES[rng.randi_range(0, MIX_SOURCES.size() - 1)]
		var total: int = [200, 300, 400, 500][rng.randi_range(0, 3)]
		var twh := total * int(mix[s]) / 100
		ex = K.number("The country makes %d TWh of electricity a year. How many TWh come from %s?" % [total, s], str(twh),
			"Find the share of %s on the graph, then take that percentage of the total." % s,
			"%d%% of %d = %d TWh." % [mix[s], total, twh], pic)
		ex.data = {"ask": "twh", "mix": mix, "source": s, "total": total}
		return ex
	var low := green + int(mix.nuclear)
	ex = K.number("Low-carbon electricity comes from renewables and nuclear. What percentage is low-carbon here?", str(low),
		"Add the wind, solar, hydro and nuclear bars.", "%d + %d + %d + %d = %d%%." % [mix.wind, mix.solar, mix.hydro,
		mix.nuclear, low], pic)
	ex.data = {"ask": "low_carbon", "mix": mix}
	return ex


## Level 1: kilowatt-hours; level 2: their cost in gold; level 3: what an LED saves.
static func power_cost(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var price := rng.randi_range(2, 5)
	var ex: Dictionary
	if level < 3:
		var kw := rng.randi_range(1, 3)
		var hours := rng.randi_range(2, 8)
		var kwh := kw * hours
		if level == 1:
			ex = K.number("A %d kW heater runs for %d hours. How many kilowatt-hours (kWh) does it use?" % [kw, hours], str(kwh),
				"Energy in kWh is the power in kW times the hours.", "%d × %d = %d kWh." % [kw, hours, kwh])
		else:
			ex = K.number("A %d kW heater runs for %d hours, and each kWh costs %d gold. How much does it cost?" % [kw, hours, price],
				str(kwh * price), "Find the kWh first, then multiply by the price.", "%d × %d = %d kWh; %d × %d = %d gold." % [kw,
				hours, kwh, kwh, price, kwh * price])
		ex.data = {"ask": "kwh" if level == 1 else "cost", "kw": kw, "hours": hours, "price": price}
		return ex
	var hours: int = [100, 200, 300, 400][rng.randi_range(0, 3)]
	var saved_kwh := (60 - 10) * hours / 1000
	ex = K.number("A 60 W bulb is swapped for a 10 W LED that gives as much light. Over %d hours, at %d gold a kWh, how much gold is saved?" % [
		hours, price], str(saved_kwh * price), "Find the watts saved, turn watt-hours into kWh (÷ 1,000), then multiply by the price.",
		"60 − 10 = 50 W; 50 × %d = %s Wh = %d kWh; %d × %d = %d gold." % [hours, K.fmt(50 * hours), saved_kwh, saved_kwh, price,
		saved_kwh * price])
	ex.data = {"ask": "led", "hours": hours, "price": price}
	return ex


# --- Geography: feeding the world -------------------------------------------------------------------------------------

## Level 1: water for some kg of one food; level 2: the difference for 1 kg of two; level 3: a shopping list.
static func virtual_water(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var foods: Array = FOOD_WATER.keys()
	var ex: Dictionary
	if level == 1:
		var f: String = foods[rng.randi_range(0, foods.size() - 1)]
		var kg := rng.randi_range(2, 4)
		ex = K.number("Growing or making 1 kg of %s takes about %s litres of water. How many litres for %d kg?" % [f,
			K.fmt(int(FOOD_WATER[f])), kg], str(int(FOOD_WATER[f]) * kg), "Multiply the litres for 1 kg by the kilograms.",
			"%s × %d = %s litres." % [K.fmt(int(FOOD_WATER[f])), kg, K.fmt(int(FOOD_WATER[f]) * kg)])
		ex.data = {"ask": "kg", "food": f, "kg": kg}
		return ex
	if level == 2:
		var two := _pick_any(rng, foods, 2)
		var a := int(FOOD_WATER[two[0]])
		var b := int(FOOD_WATER[two[1]])
		ex = K.number("1 kg of %s takes about %s litres of water; 1 kg of %s about %s. How many litres more does the thirstier food take?" % [
			two[0], K.fmt(a), two[1], K.fmt(b)], str(absi(a - b)), "Take the smaller number from the bigger.",
			"%s − %s = %s litres." % [K.fmt(maxi(a, b)), K.fmt(mini(a, b)), K.fmt(absi(a - b))])
		ex.data = {"ask": "more", "foods": two}
		return ex
	var list := _pick_any(rng, foods, 2)
	var kgs: Array[int] = [rng.randi_range(1, 3), rng.randi_range(1, 3)]
	var total := 0
	var parts: Array[String] = []
	var said: Array[String] = []
	for i in 2:
		var w := int(FOOD_WATER[list[i]])
		total += w * kgs[i]
		parts.append("%s × %d = %s" % [K.fmt(w), kgs[i], K.fmt(w * kgs[i])])
		said.append("%d kg of %s (%s litres a kg)" % [kgs[i], list[i], K.fmt(w)])
	ex = K.number("How many litres of water went into %s and %s?" % [said[0], said[1]], str(total),
		"Work out each food's water, then add them.", "%s; %s; together %s litres." % [parts[0], parts[1], K.fmt(total)])
	ex.data = {"ask": "list", "foods": list, "kgs": kgs}
	return ex


static func farm_type(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, FARMS, FARM_KINDS, "What kind of farming is %s?",
		"Sort these farms: arable (crops), pastoral (animals) or mixed?",
		"Arable farms grow crops, pastoral farms keep animals, mixed farms do both.")


static func farm_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, FARM_SCALE, FARM_SCALES, "Is this subsistence or commercial farming: %s?",
		"Sort these: subsistence farming (food for the family) or commercial farming (to sell)?",
		"Ask who eats what the farm grows: the family, or customers who buy it.")


# --- Geography: cities ------------------------------------------------------------------------------------------------------

## Level 1: people for each km²; level 2: the denser of two cities; level 3: people in a new district.
static func density(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level != 2:
		var d: int = DENSITIES[rng.randi_range(0, DENSITIES.size() - 1)]
		var a: int = AREAS[rng.randi_range(0, AREAS.size() - 1)]
		if level == 1:
			ex = K.number("A city has %s people on %d km². How many people is that for each km²?" % [K.fmt(d * a), a], str(d),
				"Population density is the people divided by the area.", "%s ÷ %d = %s people a km²." % [K.fmt(d * a), a,
				K.fmt(d)])
			ex.data = {"ask": "density", "people": d * a, "km2": a}
		else:
			var k := rng.randi_range(2, 12)
			ex = K.number("A new district of %d km² is planned at %s people a km². How many people could live there?" % [k,
				K.fmt(d)], str(k * d), "Multiply the area by the people for each km².", "%d × %s = %s people." % [k, K.fmt(d),
				K.fmt(k * d)])
			ex.data = {"ask": "district", "km2": k, "density": d}
		return ex
	var ds := _pick_any(rng, DENSITIES, 2)
	var areas := _pick_any(rng, AREAS, 2)
	var names: Array[String] = ["City A", "City B"]
	var dense := 0 if int(ds[0]) > int(ds[1]) else 1
	ex = K.choice(rng, "City A: %s people on %d km². City B: %s people on %d km². Which is more crowded?" % [
		K.fmt(int(ds[0]) * int(areas[0])), areas[0], K.fmt(int(ds[1]) * int(areas[1])), areas[1]], names[dense],
		[names[1 - dense], "they are the same"], "Work out the people for each km² in both cities, then compare.",
		"City A: %s a km²; City B: %s a km². %s is more crowded." % [K.fmt(int(ds[0])), K.fmt(int(ds[1])), names[dense]])
	ex.data = {"ask": "denser", "people": [int(ds[0]) * int(areas[0]), int(ds[1]) * int(areas[1])], "km2": areas}
	return ex


## Level 1: an idea for one problem; levels 2-3: match three or four problems to their fixes.
static func city_solutions(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var problems: Array = CITY_FIXES.keys()
	if level == 1:
		var p: String = problems[rng.randi_range(0, problems.size() - 1)]
		var others: Array = _pick_any(rng, problems.filter(func(q: Variant) -> bool: return str(q) != p), 3)
		var ex := K.choice(rng, "Which idea helps most with %s in a big city?" % p, str(CITY_FIXES[p]),
			others.map(func(q: Variant) -> String: return str(CITY_FIXES[q])),
			"Think what causes the problem, then what takes the cause away.",
			"%s: %s." % [_cap(p), CITY_FIXES[p]])
		ex.data = {"ask": "one", "problem": p}
		return ex
	return _match(rng, "Match each city problem to an idea that helps.", _pick_any(rng, problems, level + 1), CITY_FIXES,
		"Ask what causes each problem: too many cars, too little shade, too few homes, too much hard ground.")


# --- Geography: tourism ----------------------------------------------------------------------------------------------------

## Level 1: what visitors spend; level 2: what stays after leakage; level 3: what stays for each person who lives there.
static func tourist_spend(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var visitors := rng.randi_range(2, 20) * 1000
	var spend := rng.randi_range(2, 10) * 10
	var total := visitors * spend
	var ex: Dictionary
	if level == 1:
		ex = K.number("%s visitors each spend about %d gold on an island. How much gold do they spend in all?" % [K.fmt(visitors),
			spend], str(total), "Multiply the visitors by what each spends.", "%s × %d = %s gold." % [K.fmt(visitors), spend,
			K.fmt(total)])
		ex.data = {"ask": "total", "visitors": visitors, "spend": spend}
		return ex
	var leak := rng.randi_range(2, 8) * 10
	var stays := total * (100 - leak) / 100
	if level == 2:
		ex = K.number("Tourists spend %s gold on an island, but %d%% leaks away to companies abroad. How much gold stays on the island?" % [
			K.fmt(total), leak], str(stays), "Find the share that stays (100%% − %d%%), then take that share." % leak,
			"100 − %d = %d%%; %d%% of %s = %s gold." % [leak, 100 - leak, 100 - leak, K.fmt(total), K.fmt(stays)])
		ex.data = {"ask": "stays", "total": total, "leak": leak}
		return ex
	var residents := 100
	for r: int in [2000, 1000, 500, 400, 200, 100]:
		if stays % r == 0:
			residents = r
			break
	ex = K.number("%s gold from tourism stays on an island where %s people live. Shared out, how much gold is that for each person?" % [
		K.fmt(stays), K.fmt(residents)], str(stays / residents), "Divide the gold by the people.", "%s ÷ %s = %s gold each." % [
		K.fmt(stays), K.fmt(residents), K.fmt(stays / residents)])
	ex.data = {"ask": "each", "stays": stays, "residents": residents}
	return ex


static func tourism_effects(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, TOURISM, TOURISM_KINDS, "Is %s a good effect of tourism or a bad one?",
		"Sort these effects of tourism: good or bad for the place and its people?",
		"Does it help local people and nature, or harm them?")


## Butler's tourism cycle. Level 1: the hidden stage on the curve; level 2: a stage from its description; level 3: what
## comes next.
static func butler_stage(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var stage: String = STAGES[rng.randi_range(0, STAGES.size() - 1 if level < 3 else STAGES.size() - 2)]
	var others: Array = STAGES.filter(func(s: String) -> bool: return s != stage)
	var ex: Dictionary
	if level == 1:
		ex = K.choice(rng, "Which stage of the tourism cycle is hidden by the question mark?", stage, _pick_any(rng, others, 3),
			"Follow the curve: few visitors, growth, fast growth, slower growth, then a flat top.",
			"It is %s: %s." % [stage, BUTLER[stage]], {"kind": "tourism_cycle", "labels": true, "hide": stage})
		ex.data = {"ask": "picture", "stage": stage}
		return ex
	if level == 2:
		ex = K.choice(rng, "A resort where %s. Which stage of the tourism cycle is it in?" % BUTLER[stage], stage,
			_pick_any(rng, others, 3), "Think how many visitors there are, and whether their numbers are still growing.",
			"%s: %s." % [_cap(stage), BUTLER[stage]])
		ex.data = {"ask": "describe", "stage": stage}
		return ex
	var next := STAGES[STAGES.find(stage) + 1]
	ex = K.choice(rng, "In the tourism cycle, which stage comes after %s?" % stage, next,
		_pick_any(rng, STAGES.filter(func(s: String) -> bool: return s != next and s != stage), 3),
		"Exploration, involvement, development, consolidation, stagnation: say them in order.",
		"After %s comes %s." % [stage, next])
	ex.data = {"ask": "after", "stage": stage}
	return ex


# --- Geography: oceans ------------------------------------------------------------------------------------------------------

## Level 1: the zone at a depth; level 2: the pressure (about 1 atmosphere more every 10 m); level 3: a dive's minutes.
static func ocean_zone(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var z := rng.randi_range(0, ZONE_NAMES.size() - 1)
		var lo := ZONE_TOPS[z] + (ZONE_FLOORS[z] - ZONE_TOPS[z]) / 5
		var hi := ZONE_FLOORS[z] - (ZONE_FLOORS[z] - ZONE_TOPS[z]) / 5
		var depth := rng.randi_range(lo / 10, hi / 10) * 10
		ex = K.choice(rng, "A creature lives %s m down. Which zone of the ocean is that?" % K.fmt(depth), ZONE_NAMES[z],
			_pick_any(rng, ZONE_NAMES.filter(func(n: String) -> bool: return n != ZONE_NAMES[z]), 3),
			"Sunlight to 200 m, twilight to 1,000 m, midnight to 4,000 m, the abyss to 6,000 m, then the trenches.",
			"%s m is in the %s (%s to %s m)." % [K.fmt(depth), ZONE_NAMES[z], K.fmt(ZONE_TOPS[z]), K.fmt(ZONE_FLOORS[z])],
			{"kind": "ocean_zones", "depths": true, "labels": false})
		ex.data = {"ask": "zone", "depth": depth}
		return ex
	if level == 2:
		var depth := rng.randi_range(2, 300) * 10
		var atm := 1 + depth / 10
		ex = K.number("At the surface the air presses with 1 atmosphere. Every 10 m of sea adds about 1 more. About how many atmospheres press at %s m?" % K.fmt(depth),
			str(atm), "Find how many 10 m steps there are, then add the 1 from the air.", "%s ÷ 10 = %d; %d + 1 = %d atmospheres." % [
			K.fmt(depth), depth / 10, depth / 10, atm])
		ex.data = {"ask": "pressure", "depth": depth}
		return ex
	var speed: int = [20, 25, 30, 40, 50][rng.randi_range(0, 4)]
	var minutes := rng.randi_range(10, 200)
	ex = K.number("A submersible sinks %d m every minute. How many minutes does it take to reach %s m?" % [speed,
		K.fmt(speed * minutes)], str(minutes), "Divide the depth by the metres it sinks each minute.",
		"%s ÷ %d = %d minutes." % [K.fmt(speed * minutes), speed, minutes])
	ex.data = {"ask": "minutes", "speed": speed, "depth": speed * minutes}
	return ex


## Level 1: until about which year a piece of litter lasts (a year); level 2: years between two; level 3: in order.
static func plastic_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var items: Array = LITTER.keys()
	var ex: Dictionary
	if level == 1:
		var it: String = items[rng.randi_range(0, items.size() - 1)]
		var n := int(LITTER[it])
		ex = K.number("Scientists estimate %s lasts about %d years in the sea. If it is dropped in %d, until about which year could it last?" % [
			it, n, NOW], str(NOW + n), "Add the years it lasts to the year it was dropped.", "%d + %d = %d." % [NOW, n, NOW + n])
		ex.year = true
		ex.data = {"ask": "until", "item": it}
		return ex
	if level == 2:
		var two: Array = []
		for _try in 100:
			two = _pick_any(rng, items, 2)
			if int(LITTER[two[0]]) != int(LITTER[two[1]]):
				break
		var a := int(LITTER[two[0]])
		var b := int(LITTER[two[1]])
		ex = K.number("%s lasts about %d years in the sea, and %s about %d. How many years longer does the longer-lasting one last?" % [
			_cap(two[0]), a, two[1], b], str(absi(a - b)), "Take the smaller number of years from the bigger.",
			"%d − %d = %d years." % [maxi(a, b), mini(a, b), absi(a - b)])
		ex.data = {"ask": "apart", "items": two}
		return ex
	var picks: Array = []
	for _try in 200:
		picks = _pick_any(rng, items, 4)
		var years := {}
		for p: Variant in picks:
			years[int(LITTER[p])] = true
		if years.size() == 4:
			break
	picks.sort_custom(func(a: Variant, b: Variant) -> bool: return int(LITTER[a]) < int(LITTER[b]))
	var in_order: Array = picks.map(func(p: Variant) -> String: return str(p))
	ex = K.order(rng, "Put this litter in order: the shortest-lasting in the sea first.", in_order,
		"Remember roughly how long each lasts: tens of years, or hundreds?",
		"%s." % ", ".join(picks.map(func(p: Variant) -> String: return "%s (%d years)" % [p, LITTER[p]])))
	ex.data = {"ask": "order", "items": in_order}
	return ex


# --- Geography: maps and GIS --------------------------------------------------------------------------------------------------

## Mercator's stretch. Level 1: how many times longer lengths are drawn; level 2: how many times bigger an area looks;
## level 3: a country's true area from how big it looks.
static func mercator_stretch(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var choices: Array = STRETCH.slice(0 if level == 1 else 1)
	if level == 3:
		choices = STRETCH.filter(func(e: Array) -> bool: return float(e[1]) >= 2.0 and is_equal_approx(float(e[1]), roundf(float(e[1]))))
	var pick: Array = choices[rng.randi_range(0, choices.size() - 1)]
	var at := str(pick[0])
	var k := float(pick[1])
	var ex: Dictionary
	if level == 1:
		ex = K.number("On a Mercator map, how many times too long is a short east-west line drawn at %s?" % at, _ans(k),
			"Mercator stretches by 1 at the equator, 1.5 at 48°, 2 at 60°, 2.5 at about 66°, 3 at about 70.5°, 4 at about 75.5°.",
			"At %s the stretch is %s: lengths look %s times as long." % [at, _num(k), _num(k)])
		ex.data = {"ask": "stretch", "at": at}
		return ex
	if level == 2:
		ex = K.number("Mercator stretches lengths %s times at %s, both east-west and north-south. How many times too big does an area there look?" % [
			_num(k), at], _ans(k * k), "An area stretches both ways: multiply the stretch by itself.", "%s × %s = %s times." % [
			_num(k), _num(k), _num(k * k)])
		ex.data = {"ask": "area", "at": at}
		return ex
	var kk := roundi(k * k)
	var real: int = [1, 2, 3, 5, 6][rng.randi_range(0, 4)]
	ex = K.number("A country at %s looks %d million km² on a Mercator map, which stretches areas there %d times. What is its true area, in million km²?" % [
		at, real * kk, kk], str(real), "Divide how big it looks by the stretch of areas.", "%d ÷ %d = %d million km²." % [
		real * kk, kk, real])
	ex.data = {"ask": "real", "at": at, "shown": real * kk}
	return ex


## Level 1: a projection for a job; levels 2-3: match three or four jobs to their projections.
static func projection_choice(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var uses: Array = PROJECTION_USES.keys()
	if level == 1:
		var u: String = uses[rng.randi_range(0, uses.size() - 1)]
		var right := str(PROJECTION_USES[u])
		var others: Array = PROJECTION_USES.values().filter(func(v: Variant) -> bool: return str(v) != right)
		var ex := K.choice(rng, "Which kind of map is best for %s?" % u, right, others,
			"Ask what the map must keep true: directions, areas, a good look, or distances from one point?",
			"For %s: %s." % [u, right])
		ex.data = {"ask": "one", "use": u}
		return ex
	return _match(rng, "Match each job to the best kind of map.", _pick_any(rng, uses, level + 1), PROJECTION_USES,
		"Mercator keeps directions, equal-area keeps sizes, azimuthal keeps distances from its centre.")


## A layered map: houses and a flood zone. Level 1: count the houses; level 2: the houses in the flood zone; level 3:
## their percentage.
static func overlay_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := 8
	var h := 5
	var n: int = [4, 5, 10][rng.randi_range(0, 2)] if level == 3 else rng.randi_range(4, 9)
	# The flood zone: the river side of the map, a few columns wide, wider in some rows.
	var flood := {}
	var edge := rng.randi_range(2, 3)
	for y in h:
		for x in edge + (1 if (y + rng.randi_range(0, 1)) % 2 == 0 else 0):
			flood[Vector2i(x, y)] = true
	var cells: Array[Vector2i] = []
	for y in h:
		for x in w:
			cells.append(Vector2i(x, y))
	var at_risk := 0
	var houses: Array[Vector2i] = []
	for _try in 300:
		K.shuffle(rng, cells)
		houses = cells.slice(0, n)
		at_risk = houses.filter(func(c: Vector2i) -> bool: return flood.has(c)).size()
		if at_risk >= 1 and at_risk < n:
			break
	var rows_f: Array[String] = []
	var rows_h: Array[String] = []
	for y in h:
		var rf := ""
		var rh := ""
		for x in w:
			rf += "#" if flood.has(Vector2i(x, y)) else "."
			rh += "#" if houses.has(Vector2i(x, y)) else "."
		rows_f.append(rf)
		rows_h.append(rh)
	var pic := {"kind": "layer_map", "w": w, "h": h, "layers": [{"name": "flood zone", "what": "flood", "cells": rows_f},
		{"name": "houses", "what": "houses", "cells": rows_h}]}
	var ex: Dictionary
	if level == 1:
		ex = K.number("The map has two layers: a flood zone and houses. How many houses are there?", str(n),
			"Count the houses one by one, square by square.", "There are %d houses." % n, pic)
	elif level == 2:
		ex = K.number("Put the layers together: how many houses are inside the flood zone?", str(at_risk),
			"Look for squares that have a house AND the flood colour.", "%d of the %d houses are in the flood zone." % [at_risk, n], pic)
	else:
		ex = K.number("What percentage of the houses are inside the flood zone?", str(at_risk * 100 / n),
			"Count the houses in the flood zone, divide by all the houses, then multiply by 100.",
			"%d ÷ %d × 100 = %d%%." % [at_risk, n, at_risk * 100 / n], pic)
	ex.data = {"ask": ["houses", "at_risk", "percent"][level - 1]}
	return ex


static func gis_features(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, GIS, GIS_KINDS, "On a GIS map, is %s a point, a line or an area?",
		"Sort these map features: points, lines or areas?",
		"A point is one place, a line is something long and thin, an area covers ground.")


# --- Citizenship: democracy and voice ---------------------------------------------------------------------------------------

## Level 1: who wins a seat by first past the post; level 2: seats by proportional representation; level 3: the gap
## between the two systems.
static func seat_maths(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var shares: Array = []
		for _try in 100:
			shares = _split(rng, 20, 3).map(func(p: int) -> int: return p * 5)
			var top := 0
			for s: Variant in shares:
				top = maxi(top, int(s))
			if shares.count(top) == 1:
				break
		var best := 0
		for i in 3:
			if int(shares[i]) > int(shares[best]):
				best = i
		var said: Array[String] = []
		for i in 3:
			said.append("%s %d%%" % [CANDIDATES[i], shares[i]])
		ex = K.choice(rng, "First past the post: the candidate with the most votes wins the seat. Votes: %s. Who wins?" % ", ".join(said),
			CANDIDATES[best], [CANDIDATES[(best + 1) % 3], CANDIDATES[(best + 2) % 3], "no one: nobody has over half"],
			"The most votes wins, even without more than half.", "%s has the most votes (%d%%), so wins the seat." % [
			CANDIDATES[best], shares[best]])
		ex.data = {"ask": "winner", "shares": shares}
		return ex
	var seats: int = [50, 100, 200][rng.randi_range(0, 2)]
	var share := rng.randi_range(4, 23) * 2
	var pr := share * seats / 100
	if level == 2:
		ex = K.number("Proportional representation: a group wins %d%% of the votes for a parliament of %d seats. How many seats does it get?" % [
			share, seats], str(pr), "Seats follow votes: take the same percentage of the seats.", "%d%% of %d = %d seats." % [share,
			seats, pr])
		ex.data = {"ask": "pr_seats", "share": share, "seats": seats}
		return ex
	var won := mini(pr + rng.randi_range(2, seats / 5), seats - 1)
	ex = K.number("A group wins %d%% of the votes but %d of the %d seats by first past the post. How many more seats is that than proportional representation would give?" % [
		share, won, seats], str(won - pr), "Find its fair share of seats first, then compare.", "%d%% of %d = %d; %d − %d = %d more seats." % [
		share, seats, pr, won, pr, won - pr])
	ex.data = {"ask": "gap", "share": share, "seats": seats, "won": won}
	return ex


## A school council vote. Level 1: the winner; level 2: one idea's percentage; level 3: votes more for a majority.
static func vote_tally(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var totals: Array = [20, 25, 50, 100] if level == 2 else [20, 25, 50, 100, 200]   # level 2: every percentage whole
	var total: int = totals[rng.randi_range(0, totals.size() - 1)]
	var votes: Array = []
	for _try in 200:
		votes = _split(rng, total, 4)
		var top := 0
		for v: Variant in votes:
			top = maxi(top, int(v))
		if votes.count(top) == 1 and (level != 3 or top <= total / 2):
			break
	var best := 0
	for i in 4:
		if int(votes[i]) > int(votes[best]):
			best = i
	var bars: Array = []
	for i in 4:
		bars.append([COUNCIL_IDEAS[i], votes[i]])
	var step := maxi(1, ceili(float(votes[best]) / 5.0))
	var pic := {"kind": "bar_graph", "bars": bars, "step": step, "top": step * ceili(float(votes[best]) / step),
		"name": "Votes from %d pupils" % total}
	var ex: Dictionary
	if level == 1:
		ex = K.choice(rng, "The school council asked pupils what to spend its money on. Which idea won?", COUNCIL_IDEAS[best],
			COUNCIL_IDEAS.filter(func(c: String) -> bool: return c != COUNCIL_IDEAS[best]), "Find the tallest bar.",
			"%s: %d votes, the most." % [_cap(COUNCIL_IDEAS[best]), votes[best]], pic)
		ex.data = {"ask": "winner", "votes": votes}
		return ex
	if level == 2:
		var i := rng.randi_range(0, 3)
		ex = K.number("What percentage of the %d pupils voted for %s?" % [total, COUNCIL_IDEAS[i]], str(int(votes[i]) * 100 / total),
			"Divide its votes by all the votes, then multiply by 100.", "%d ÷ %d × 100 = %d%%." % [votes[i], total,
			int(votes[i]) * 100 / total], pic)
		ex.data = {"ask": "percent", "votes": votes, "idea": i}
		return ex
	var need := total / 2 + 1
	ex = K.number("A majority is more than half of the %d votes. How many more votes would %s need for a majority?" % [total,
		COUNCIL_IDEAS[best]], str(need - int(votes[best])), "Find more than half of the votes, then take away what it has.",
		"Half of %d is %s, so a majority is %d; %d − %d = %d more votes." % [total, _num(total / 2.0), need, need, votes[best],
		need - int(votes[best])], pic)
	ex.data = {"ask": "majority", "votes": votes}
	return ex


## Ages in law in England. Level 1: an age; level 2: the years between two; level 3: before 18 or only from 18.
static func law_ages(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var things: Array = AGES.keys()
	var ex: Dictionary
	if level == 1:
		var t: String = things[rng.randi_range(0, things.size() - 1)]
		ex = K.number("In England, from what age can you %s?" % t, str(AGES[t]), "Remember the lesson's line of ages from 10 to 18.",
			"In England you can %s from %d." % [t, AGES[t]])
		ex.data = {"ask": "age", "thing": t}
		return ex
	if level == 2:
		var two: Array = []
		for _try in 100:
			two = _pick_any(rng, things, 2)
			if int(AGES[two[0]]) != int(AGES[two[1]]):
				break
		var a := int(AGES[two[0]])
		var b := int(AGES[two[1]])
		ex = K.number("In England you can %s at %d and %s at %d. How many years apart are those ages?" % [two[0], a, two[1], b],
			str(absi(a - b)), "Take the younger age from the older one.", "%d − %d = %d years." % [maxi(a, b), mini(a, b),
			absi(a - b)])
		ex.data = {"ask": "between", "things": two}
		return ex
	var table := {}
	for t: Variant in things:
		table[t] = 1 if int(AGES[t]) >= 18 else 0
	return _sorter(rng, 3, table, AGE_KINDS, "", "Sort these, in England: allowed before 18, or only from 18?",
		"Think of the ages on the lesson's line: 10, 13, 16, 17 and 18.")


static func rights_duties(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, RIGHTS, RIGHT_KINDS, "Is this a right or a responsibility: %s?",
		"Sort these: rights we all have, or responsibilities we all share?",
		"A right is something you are owed; a responsibility is something you owe to others.")


static func equal_or_fair(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, EQUITY, EQUITY_KINDS, "Is this equality or equity: %s?",
		"Sort these: equality (the same for everyone) or equity (what each person needs)?",
		"Equality gives everyone the same; equity gives each person what they need to have a fair chance.")


# --- Citizenship: public money -------------------------------------------------------------------------------------------------

## Level 1: a sales tax (VAT) of 20%; level 2: income tax of 20% above the tax-free allowance; level 3: two bands.
static func tax_maths(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var price := rng.randi_range(2, 60) * 5
		ex = K.number("In this example, a sales tax of 20%% is added to a bike's price of %d gold. How much tax is that?" % price,
			str(price / 5), "20% is a fifth: divide by 5, or find 10% and double it.", "10%% of %d is %s; 20%% is %s gold." % [price,
			_num(price / 10.0), _num(price / 5.0)])
		ex.data = {"ask": "vat", "price": price}
		return ex
	if level == 2:
		var income := rng.randi_range(13, 45) * 1000
		var tax := (income - ALLOWANCE) / 5
		ex = K.number("In this example, the first %s gold a year is tax-free and the rest is taxed at 20%%. How much tax is paid on %s gold?" % [
			K.fmt(ALLOWANCE), K.fmt(income)], str(tax), "Take away the tax-free part first, then find 20% of the rest.",
			"%s − %s = %s; 20%% of that is %s gold." % [K.fmt(income), K.fmt(ALLOWANCE), K.fmt(income - ALLOWANCE), K.fmt(tax)])
		ex.data = {"ask": "income", "income": income}
		return ex
	var income := rng.randi_range(11, 18) * 5000
	var basic := (HIGHER_FROM - ALLOWANCE) / 5
	var higher := (income - HIGHER_FROM) * 2 / 5
	ex = K.number("In this example: 0%% up to %s gold, 20%% from %s to %s, 40%% above %s. How much tax is paid on %s gold?" % [
		K.fmt(ALLOWANCE), K.fmt(ALLOWANCE), K.fmt(HIGHER_FROM), K.fmt(HIGHER_FROM), K.fmt(income)], str(basic + higher),
		"Work out each band's tax separately, then add them.", "20%% of %s = %s; 40%% of %s = %s; %s + %s = %s gold." % [
		K.fmt(HIGHER_FROM - ALLOWANCE), K.fmt(basic), K.fmt(income - HIGHER_FROM), K.fmt(higher), K.fmt(basic), K.fmt(higher),
		K.fmt(basic + higher)])
	ex.data = {"ask": "bands", "income": income}
	return ex


## A government's yearly budget in billion gold. Level 1: a service's money; level 2: its percentage; level 3: what a
## bigger share adds.
static func spend_share(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var total: int = [400, 500, 800, 1000, 1200][rng.randi_range(0, 4)]
	var service: String = ["health", "education", "pensions", "transport", "defence"][rng.randi_range(0, 4)]
	var share := rng.randi_range(1, 6) * 5
	var amount := total * share / 100
	var ex: Dictionary
	if level == 1:
		ex = K.number("A government spends %s billion gold a year, %d%% of it on %s. How many billion gold is that?" % [K.fmt(total),
			share, service], str(amount), "Find 1% (divide by 100), then multiply by the percentage.", "%d%% of %s = %s billion gold." % [
			share, K.fmt(total), K.fmt(amount)])
		ex.data = {"ask": "amount", "total": total, "share": share}
		return ex
	if level == 2:
		ex = K.number("A budget of %s billion gold gives %s billion to %s. What percentage is that?" % [K.fmt(total), K.fmt(amount),
			service], str(share), "Divide the part by the whole, then multiply by 100.", "%s ÷ %s × 100 = %d%%." % [K.fmt(amount),
			K.fmt(total), share])
		ex.data = {"ask": "percent", "total": total, "amount": amount}
		return ex
	var more := rng.randi_range(1, 3) * 5
	ex = K.number("A %s billion gold budget gives %s %d%%. If its share rises to %d%% (the total stays the same), how many billion gold more does it get?" % [
		K.fmt(total), service, share, share + more], str(total * more / 100), "Find the extra percentage, then that share of the total.",
		"%d − %d = %d%%; %d%% of %s = %s billion gold." % [share + more, share, more, more, K.fmt(total), K.fmt(total * more / 100)])
	ex.data = {"ask": "trade_off", "total": total, "more": more}
	return ex


# --- Citizenship: money ---------------------------------------------------------------------------------------------------------

## Level 1: what is left after bills; level 2: 50/30/20; level 3: months to save for a goal.
static func monthly_budget(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var income := rng.randi_range(15, 40) * 100
	var ex: Dictionary
	if level == 1:
		var rent := income * rng.randi_range(25, 35) / 100 / 10 * 10
		var food := rng.randi_range(20, 40) * 10
		var bills := rng.randi_range(8, 20) * 10
		var left := income - rent - food - bills
		ex = K.number("Monthly pay: %s gold. Rent %s, food %d, bills %d. How much is left for saving and fun?" % [K.fmt(income),
			K.fmt(rent), food, bills], str(left), "Add up the costs, then take them from the pay.", "%s + %d + %d = %s; %s − %s = %s gold." % [
			K.fmt(rent), food, bills, K.fmt(rent + food + bills), K.fmt(income), K.fmt(rent + food + bills), K.fmt(left)])
		ex.data = {"ask": "left", "income": income, "costs": [rent, food, bills]}
		return ex
	if level == 2:
		var part: Array = [["needs", 50], ["wants", 30], ["saving", 20]][rng.randi_range(0, 2)]
		ex = K.number("The 50/30/20 plan: 50%% of pay for needs, 30%% for wants, 20%% for saving. Pay is %s gold a month. How much goes to %s?" % [
			K.fmt(income), part[0]], str(income * int(part[1]) / 100), "Find 10% of the pay, then multiply.", "10%% of %s is %s; %d%% is %s gold." % [
			K.fmt(income), K.fmt(income / 10), part[1], K.fmt(income * int(part[1]) / 100)])
		ex.data = {"ask": "rule", "income": income, "part": part[0]}
		return ex
	var save := rng.randi_range(4, 30) * 10
	var months := rng.randi_range(3, 18)
	ex = K.number("%s saves %d gold a month for a bike that costs %s gold. How many months will it take?" % [PEOPLE[rng.randi_range(0, 5)],
		save, K.fmt(save * months)], str(months), "Divide the price by the saving each month.", "%s ÷ %d = %d months." % [
		K.fmt(save * months), save, months])
	ex.data = {"ask": "months", "save": save, "goal": save * months}
	return ex


static func fixed_variable(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, COSTS, COST_KINDS, "Is %s a fixed cost or a variable cost?",
		"Sort these monthly costs: fixed (the same each month) or variable (they change)?",
		"Would the cost be the same next month whatever you do? Then it is fixed.")


## Simple interest. Level 1: the interest; level 2: the monthly payment; level 3: the cheaper of two loans.
static func loan_cost(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var p := 0
		var r := 0
		var t := 0
		var interest := 0
		for _try in 200:
			p = [1200, 2400, 3600, 6000][rng.randi_range(0, 3)]
			r = [5, 6, 8, 10, 12][rng.randi_range(0, 4)]
			t = rng.randi_range(1, 3)
			interest = p * r * t / 100
			if p * r * t % 100 == 0 and (p + interest) % (12 * t) == 0:
				break
		if p * r * t % 100 != 0 or (p + interest) % (12 * t) != 0:
			p = 1200
			r = 5
			t = 1
			interest = 60
		if level == 1:
			ex = K.number("A loan of %s gold charges %d%% a year (simple interest). How much interest is that over %d year%s?" % [
				K.fmt(p), r, t, "" if t == 1 else "s"], str(interest), "Find one year's interest, then multiply by the years.",
				"%d%% of %s = %s a year; × %d = %s gold." % [r, K.fmt(p), K.fmt(p * r / 100), t, K.fmt(interest)])
			ex.data = {"ask": "interest", "p": p, "r": r, "t": t}
			return ex
		var months := 12 * t
		ex = K.number("%s gold is borrowed at %d%% a year, simple interest, paid back in equal monthly amounts over %d months. How much is each payment?" % [
			K.fmt(p), r, months], str((p + interest) / months), "Add the interest to the loan, then share it over the months.",
			"Interest %s; %s + %s = %s; ÷ %d = %s gold a month." % [K.fmt(interest), K.fmt(p), K.fmt(interest), K.fmt(p + interest),
			months, K.fmt((p + interest) / months)])
		ex.data = {"ask": "monthly", "p": p, "r": r, "t": t}
		return ex
	var p: int = [1000, 2000, 5000][rng.randi_range(0, 2)]
	var ra := 0
	var rb := 0
	var ta := 0
	var tb := 0
	for _try in 200:
		ra = [4, 5, 6, 8, 10][rng.randi_range(0, 4)]
		rb = [4, 5, 6, 8, 10][rng.randi_range(0, 4)]
		ta = rng.randi_range(1, 4)
		tb = rng.randi_range(1, 4)
		if ra * ta != rb * tb and ra != rb:
			break
	var ia := p * ra * ta / 100
	var ib := p * rb * tb / 100
	var cheaper := "Loan A" if ia < ib else "Loan B"
	ex = K.choice(rng, "To borrow %s gold: Loan A charges %d%% a year for %d years; Loan B %d%% a year for %d years (simple interest). Which costs less in all?" % [
		K.fmt(p), ra, ta, rb, tb], cheaper, ["Loan A" if cheaper == "Loan B" else "Loan B", "they cost the same"],
		"Work out each loan's total interest: rate × years, not the rate alone.",
		"A: %d%% × %d = %d%% = %s gold. B: %d%% × %d = %d%% = %s gold. %s is cheaper." % [ra, ta, ra * ta, K.fmt(ia), rb, tb,
		rb * tb, K.fmt(ib), cheaper])
	ex.data = {"ask": "cheaper", "p": p, "a": [ra, ta], "b": [rb, tb]}
	return ex


static func credit_score_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, CREDIT, CREDIT_KINDS, "Does %s help or harm a credit score?",
		"Sort these: do they help or harm a credit score?",
		"Lenders like people who pay on time and borrow carefully.")


## The rule of 72: money doubles in about 72 ÷ rate years. Level 1: the years; level 2: the money after some doublings;
## level 3: how many years sooner a higher rate doubles it.
static func rule_of_72(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var r: int = DOUBLING_RATES[rng.randi_range(0, DOUBLING_RATES.size() - 1)]
	var ex: Dictionary
	if level == 1:
		ex = K.number("The rule of 72: money growing at a steady rate doubles in about 72 ÷ the rate years. About how many years to double at %d%% a year?" % r,
			str(72 / r), "Divide 72 by the rate.", "72 ÷ %d = %d years." % [r, 72 / r])
		ex.data = {"ask": "double", "rate": r}
		return ex
	if level == 2:
		var start: int = [500, 1000, 2000][rng.randi_range(0, 2)]
		var k := rng.randi_range(2, 3)
		var years := k * 72 / r
		var end := start * int(pow(2, k))
		ex = K.number("%s gold grows at %d%% a year. Using the rule of 72, about how much is it worth after %d years?" % [K.fmt(start), r,
			years], str(end), "Find how long one doubling takes, then count the doublings.", "72 ÷ %d = %d years a doubling; %d years is %d doublings: %s gold." % [
			r, 72 / r, years, k, K.fmt(end)])
		ex.data = {"ask": "grow", "rate": r, "start": start, "years": years}
		return ex
	var two := _pick_any(rng, DOUBLING_RATES, 2)
	two.sort()
	var lo := int(two[0])
	var hi := int(two[1])
	ex = K.number("Savings grow at %d%% a year; shares might grow at %d%%. By the rule of 72, about how many years sooner would the money double at %d%%?" % [
		lo, hi, hi], str(72 / lo - 72 / hi), "Find both doubling times, then take one from the other.", "72 ÷ %d = %d; 72 ÷ %d = %d; %d − %d = %d years." % [
		lo, 72 / lo, hi, 72 / hi, 72 / lo, 72 / hi, 72 / lo - 72 / hi])
	ex.data = {"ask": "sooner", "rates": [lo, hi]}
	return ex


## Investing the same 120 gold every month. Level 1: units bought at a price; level 2: units over three months; level
## 3: the average cost of a unit.
static func regular_investing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var p: int = UNIT_PRICES[rng.randi_range(0, UNIT_PRICES.size() - 1)]
		ex = K.number("You invest %d gold this month in a fund whose units cost %d gold each. How many units do you buy?" % [MONTHLY, p],
			str(MONTHLY / p), "Divide the gold by the price of one unit.", "%d ÷ %d = %d units." % [MONTHLY, p, MONTHLY / p])
		ex.data = {"ask": "units", "prices": [p]}
		return ex
	var prices: Array = []
	var units := 0
	for _try in 300:
		prices = [UNIT_PRICES[rng.randi_range(0, 8)], UNIT_PRICES[rng.randi_range(0, 8)], UNIT_PRICES[rng.randi_range(0, 8)]]
		units = 0
		for p: Variant in prices:
			units += MONTHLY / int(p)
		if (level == 2 or (MONTHLY * 3) % units == 0) and not (prices[0] == prices[1] and prices[1] == prices[2]):
			break
	if level == 3 and (MONTHLY * 3) % units != 0:
		prices = [10, 12, 15]
		units = 30
	var bought: Array[String] = []
	for p: Variant in prices:
		bought.append("%d ÷ %d = %d" % [MONTHLY, p, MONTHLY / int(p)])
	if level == 2:
		ex = K.number("You invest %d gold every month. The unit price is %d, then %d, then %d gold. How many units do you have after three months?" % [
			MONTHLY, prices[0], prices[1], prices[2]], str(units), "Work out each month's units, then add them.", "%s; together %d units." % [
			"; ".join(bought), units])
		ex.data = {"ask": "total_units", "prices": prices}
		return ex
	ex = K.number("You invest %d gold each month for three months, at unit prices of %d, %d and %d gold. What did each unit cost you on average?" % [
		MONTHLY, prices[0], prices[1], prices[2]], str(MONTHLY * 3 / units), "Divide all the gold you invested by all the units you bought.",
		"%s: %d units for %d gold; %d ÷ %d = %d gold a unit." % ["; ".join(bought), units, MONTHLY * 3, MONTHLY * 3, units,
		MONTHLY * 3 / units])
	ex.data = {"ask": "average", "prices": prices}
	return ex


## Level 1: the real return (interest − inflation); level 2: a price after inflation; level 3: buying power gained or
## lost in gold.
static func real_return(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rate := rng.randi_range(1, 6)
	var inflation := rng.randi_range(1, 6)
	var ex: Dictionary
	if level == 1:
		var real := rate - inflation
		ex = K.number("A savings account pays %d%% a year, and prices rise %d%% a year. What is the real return, in percent? (It can be below 0.)" % [
			rate, inflation], str(real), "Take the inflation rate from the interest rate.", "%d − %d = %s%%." % [rate, inflation,
			_signed(real)])
		ex.data = {"ask": "real", "rate": rate, "inflation": inflation}
		return ex
	if level == 2:
		var price := rng.randi_range(1, 20) * 100
		ex = K.number("Prices rise %d%% this year. A bike costs %s gold now. What will it cost next year?" % [inflation, K.fmt(price)],
			str(price * (100 + inflation) / 100), "Find the rise (the percentage of the price), then add it.", "%d%% of %s = %s; %s + %s = %s gold." % [
			inflation, K.fmt(price), K.fmt(price * inflation / 100), K.fmt(price), K.fmt(price * inflation / 100),
			K.fmt(price * (100 + inflation) / 100)])
		ex.data = {"ask": "price", "inflation": inflation, "price": price}
		return ex
	if rate == inflation:
		rate += 1
	var savings := rng.randi_range(1, 20) * 100
	var gain := savings * (rate - inflation) / 100
	ex = K.number("%s gold is saved at %d%% a year while prices rise %d%%. About how much buying power, in gold, is gained in a year? (Write a loss below 0.)" % [
		K.fmt(savings), rate, inflation], str(gain), "Find the real return (interest − inflation), then that percentage of the savings.",
		"%d − %d = %s%%; %s%% of %s is about %s gold." % [rate, inflation, _signed(rate - inflation), _signed(rate - inflation), K.fmt(savings),
		_signed(gain)])
	ex.data = {"ask": "gold", "rate": rate, "inflation": inflation, "savings": savings}
	return ex


static func refund_rights(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, REFUNDS, REFUND_KINDS, "In the UK, what are you owed for %s?",
		"Sort these by what UK law gives you: a full refund, a repair or replacement, or no legal right?",
		"Faulty within 30 days: refund. Faulty later: repair or replace first. Online: 14 days to change your mind.")


## Level 1: the price of one in a pack; level 2: the better value of two packs; level 3: the saving on a big buy.
static func best_buy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var each := rng.randi_range(2, 12)
		var n: int = [4, 6, 8, 10, 12][rng.randi_range(0, 4)]
		ex = K.number("A pack of %d juice cartons costs %d gold. How much is each carton?" % [n, each * n], str(each),
			"Divide the pack's price by the number in it.", "%d ÷ %d = %d gold each." % [each * n, n, each])
		ex.data = {"ask": "each", "n": n, "price": each * n}
		return ex
	var g_a := 500
	var g_b := 1000
	var pa := 0
	var pb := 0
	for _try in 100:
		pa = rng.randi_range(3, 9)
		pb = rng.randi_range(5, 17)
		if pb != pa * 2:
			break
	if pb == pa * 2:
		pb += 1
	if level == 2:
		var better := "the 1 kg bag" if pb < pa * 2 else "the 500 g bag"
		ex = K.choice(rng, "Rice: a 500 g bag costs %d gold; a 1 kg bag costs %d gold. Which is better value?" % [pa, pb], better,
			["the 500 g bag" if better == "the 1 kg bag" else "the 1 kg bag", "they are the same value"],
			"Compare the same amount: what would 1 kg cost in 500 g bags?", "Two 500 g bags cost %d gold; one 1 kg bag costs %d. %s is better value." % [
			pa * 2, pb, _cap(better)])
		ex.data = {"ask": "better", "a": [g_a, pa], "b": [g_b, pb]}
		return ex
	var kg := rng.randi_range(2, 5)
	var a_cost := pa * 2 * kg
	var b_cost := pb * kg
	ex = K.number("Rice: a 500 g bag costs %d gold; a 1 kg bag %d gold. How much gold do you save buying %d kg the cheaper way?" % [pa, pb, kg],
		str(absi(a_cost - b_cost)), "Price %d kg both ways, then take the smaller cost from the bigger." % kg,
		"500 g bags: %d × %d = %d gold; 1 kg bags: %d × %d = %d gold; saving %d gold." % [pa, kg * 2, a_cost, pb, kg, b_cost,
		absi(a_cost - b_cost)])
	ex.data = {"ask": "saving", "a": [g_a, pa], "b": [g_b, pb], "kg": kg}
	return ex


# --- Citizenship: Global Goals and big questions -----------------------------------------------------------------------------

## Level 1-2: the Global Goal an action serves most (3 or 4 choices, never one it also serves); level 3: match three.
static func goal_for_action(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var actions: Array = ACTIONS.keys()
	if level < 3:
		var a: String = actions[rng.randi_range(0, actions.size() - 1)]
		var goal := int(ACTIONS[a][0])
		var also: Array = ACTIONS[a][1]
		var pool: Array = SDGS.keys().filter(func(g: int) -> bool: return g != goal and not also.has(g))
		var wrongs: Array = _pick_any(rng, pool, level + 1).map(func(g: Variant) -> String: return "%d %s" % [g, SDGS[g]])
		var ex := K.choice(rng, "Which Global Goal does %s help most?" % a, "%d %s" % [goal, SDGS[goal]], wrongs,
			"Ask who or what the action helps most: people, the sea, the land, learning, health...",
			"%s helps Goal %d, %s." % [_cap(a), goal, SDGS[goal]])
		ex.data = {"ask": "one", "action": a}
		return ex
	var picks: Array = []
	for _try in 200:
		picks = _pick_any(rng, actions, 3)
		var clash := false
		for x: Variant in picks:
			for y: Variant in picks:
				if x != y and (ACTIONS[x][1] as Array).has(int(ACTIONS[y][0])):
					clash = true
		if not clash:
			break
	var table := {}
	for x: Variant in picks:
		table[x] = SDG_SHORT[int(ACTIONS[x][0])]
	var ex := _match(rng, "Match each action to the Global Goal it helps most.", picks, table,
		"Food is Goal 2, health 3, learning 4, fairness for girls 5, water 6, using less 12, the sea 14, the land 15.")
	ex.data = {"ask": "match", "actions": picks}
	return ex


## A Global Goals project's target. Level 1: the percentage done; level 2: how many more; level 3: how many a week.
static func target_progress(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var what: Array = [["trees planted", "trees"], ["bags of litter collected", "bags"], ["tins collected for the food bank", "tins"]][
		rng.randi_range(0, 2)]
	var target: int = [20, 40, 50, 100, 200][rng.randi_range(0, 4)]
	var ex: Dictionary
	if level == 1:
		var pct := rng.randi_range(1, 9) * 10
		var done := target * pct / 100
		ex = K.number("The class's target is %d %s. So far %d. What percentage of the target is done?" % [target, what[0], done],
			str(done * 100 / target), "Divide what is done by the target, then multiply by 100.", "%d ÷ %d × 100 = %d%%." % [done,
			target, done * 100 / target])
		ex.data = {"ask": "percent", "target": target, "done": done}
		return ex
	var weeks := rng.randi_range(2, 5)
	var per := rng.randi_range(1, 10)
	var left := weeks * per
	var done := target - left
	if done < 0:
		target = left + 10
		done = 10
	if level == 2:
		ex = K.number("The target is %d %s, and %d are done. How many more %s are needed?" % [target, what[0], done, what[1]],
			str(target - done), "Take what is done from the target.", "%d − %d = %d %s." % [target, done, target - done, what[1]])
		ex.data = {"ask": "more", "target": target, "done": done}
		return ex
	ex = K.number("The target is %d %s; %d are done and %d weeks are left. How many %s a week are needed?" % [target, what[0], done,
		weeks, what[1]], str(per), "Find how many are still needed, then share them over the weeks.", "%d − %d = %d; %d ÷ %d = %d a week." % [
		target, done, target - done, target - done, weeks, per])
	ex.data = {"ask": "per_week", "target": target, "done": done, "weeks": weeks}
	return ex


## Reasons for and against a proposal. Level 1: one reason; level 2: four sorted; level 3: all six.
static func for_or_against(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = PROPOSALS.keys()
	var p: String = names[rng.randi_range(0, names.size() - 1)]
	var table := {}
	for side in 2:
		for reason: Variant in PROPOSALS[p][side]:
			table[reason] = side
	var hint := "Does the reason make the idea better, or warn of a cost or a risk?"
	if level == 1:
		var r: String = table.keys()[rng.randi_range(0, table.size() - 1)]
		var ex := K.choice(rng, "The idea: %s. Is “%s” a reason for it or against it?" % [p, r], SIDES[int(table[r])],
			[SIDES[1 - int(table[r])]], hint, "“%s” is %s %s." % [_cap(r), SIDES[int(table[r])], p])
		ex.data = {"ask": "one", "proposal": p, "item": r}
		return ex
	var ex := _sorter(rng, level, table, SIDES, "", "The idea: %s. Sort the reasons: for it or against it?" % p, hint)
	ex.data = {"ask": "sort", "proposal": p, "items": ex.items}
	return ex


static func personal_data(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _sorter(rng, level, DATA, DATA_KINDS, "Is %s personal data?",
		"Sort these: personal data (it can identify you) or not?",
		"Personal data is anything that could show who you are or where you are.")


## An AI's training examples. Level 1: one kind's percentage; level 2: how many more to balance; level 3: the
## percentage it gets right.
static func training_data(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var total: int = [100, 200, 500, 1000][rng.randi_range(0, 3)]
	var ex: Dictionary
	if level == 1:
		var pct := rng.randi_range(1, 9) * 10
		var part := total * pct / 100
		ex = K.number("An AI learned from %s photos of animals: %s were cats. What percentage were cats?" % [K.fmt(total), K.fmt(part)],
			str(pct), "Divide the cats by all the photos, then multiply by 100.", "%s ÷ %s × 100 = %d%%." % [K.fmt(part), K.fmt(total), pct])
		ex.data = {"ask": "share", "total": total, "part": part}
		return ex
	if level == 2:
		var adults := total * rng.randi_range(6, 9) / 10
		var children := total - adults
		ex = K.number("An AI learned to read faces from %s photos of adults and %s of children. How many more photos of children would make the two equal?" % [
			K.fmt(adults), K.fmt(children)], str(adults - children), "Take the smaller number from the bigger.", "%s − %s = %s photos." % [
			K.fmt(adults), K.fmt(children), K.fmt(adults - children)])
		ex.data = {"ask": "balance", "adults": adults, "children": children}
		return ex
	var wrong_pct := rng.randi_range(1, 20)
	var mistakes := total * wrong_pct / 100
	ex = K.number("An AI was tested on %s photos and made %s mistakes. What percentage did it get right?" % [K.fmt(total), K.fmt(mistakes)],
		str(100 - wrong_pct), "Find the percentage it got wrong, then take it from 100.", "%s ÷ %s × 100 = %d%% wrong; 100 − %d = %d%% right." % [
		K.fmt(mistakes), K.fmt(total), wrong_pct, wrong_pct, 100 - wrong_pct])
	ex.data = {"ask": "right", "total": total, "mistakes": mistakes}
	return ex


# --- Helpers --------------------------------------------------------------------------------------------------------

## A table's item and its group (the group's index in `groups`). Level 1: one item's group (a choice; skipped when
## `one` is ""); level 2: four items sorted; level 3: six (or all), from at least two groups (three when there are three).
static func _sorter(rng: RandomNumberGenerator, level: int, table: Dictionary, groups: Array, one: String, many: String,
		hint: String) -> Dictionary:
	var pool: Array = table.keys()
	if level == 1 and one != "":
		var item: String = pool[rng.randi_range(0, pool.size() - 1)]
		var right := str(groups[int(table[item])])
		var ex := K.choice(rng, one % _said(item), right, groups.filter(func(g: Variant) -> bool: return str(g) != right), hint,
			"%s: %s." % [_cap(_said(item)), right])
		ex.data = {"ask": "one", "item": item}
		return ex
	var want := mini(groups.size(), 2 if level <= 2 else 3)
	var items: Array = []
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


## A match exercise: each of `keys` to its value in `table`, the values shown shuffled (never side by side).
static func _match(rng: RandomNumberGenerator, prompt: String, keys: Array, table: Dictionary, hint: String) -> Dictionary:
	var matches: Array = keys.map(func(k: Variant) -> String: return str(table[k]))
	var order: Array = range(keys.size())
	for _i in 12:
		K.shuffle(rng, order)
		if order != range(keys.size()):
			break
	if order == range(keys.size()):
		order.reverse()
	var shown: Array = order.map(func(i: int) -> String: return str(matches[i]))
	var answer: Array = []
	for i in keys.size():
		answer.append(shown.find(matches[i]))
	var pairs: Array[String] = []
	for i in keys.size():
		pairs.append("%s: %s" % [keys[i], matches[i]])
	var ex := {"type": "match", "prompt": prompt, "items": keys.duplicate(), "matches": shown, "answer": answer, "hint": hint,
		"explain": ". ".join(pairs) + "."}
	ex.data = {"ask": "match", "items": keys.duplicate()}
	return ex


## Level 1: which of two came first (a choice); level 2: years between two (a number); level 3: four in order.
static func _dates(rng: RandomNumberGenerator, level: int, table: Dictionary, title: String, shown: String) -> Dictionary:
	var names: Array = table.keys()
	var picks: Array = []
	for _try in 200:
		picks = _pick_any(rng, names, 2 if level < 3 else 4)
		var years := {}
		for p: Variant in picks:
			years[int(table[p])] = true
		if years.size() == picks.size():
			break
	picks.sort_custom(func(a: Variant, b: Variant) -> bool: return int(table[a]) < int(table[b]))
	var ex: Dictionary
	if level == 1:
		ex = K.choice(rng, "%s: which came first, %s or %s?" % [title, picks[1], picks[0]], _cap(str(picks[0])),
			[_cap(str(picks[1]))], "Remember the years: the smaller year came first.", "%s: %d, before %s: %d." % [
			_cap(str(picks[0])), table[picks[0]], picks[1], table[picks[1]]])
		ex.data = {"ask": "first", "names": picks}
		return ex
	if level == 2:
		var a := int(table[picks[0]])
		var b := int(table[picks[1]])
		ex = K.number("%s: %s in %d, and %s in %d. How many years apart?" % [title, picks[0], a, picks[1], b], str(b - a),
			"Take the earlier year from the later one.", "%d − %d = %d years." % [b, a, b - a])
		ex.data = {"ask": "apart", "names": picks}
		return ex
	var dated: Array = picks.map(func(p: Variant) -> Array: return [_cap(str(p)), int(table[p])])
	var out := _dated_order(rng, dated, "%s: put these in order, earliest first." % title)
	out.data = {"ask": "order", "names": picks}
	return out


static func _dated_order(rng: RandomNumberGenerator, picks: Array, prompt: String) -> Dictionary:
	var sorted := picks.duplicate()
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) < int(b[1]))
	var items: Array = sorted.map(func(e: Array) -> String: return "%s (%d)" % [e[0], e[1]])
	var years: Array[String] = []
	for e: Array in sorted:
		years.append(str(e[1]))
	var ex := K.order(rng, prompt, items, "Look at the years: the smaller the year, the earlier.",
		"Earliest first: %s." % ", ".join(years))
	ex.data = {"events": sorted.map(func(e: Array) -> String: return str(e[0]))}
	return ex


## `parts` whole numbers, each at least 1, that add up to `total`.
static func _split(rng: RandomNumberGenerator, total: int, parts: int) -> Array:
	var out: Array = []
	for _i in parts:
		out.append(1)
	for _i in total - parts:
		out[rng.randi_range(0, parts - 1)] += 1
	return out


## `n` different whole numbers from lo to hi.
static func _distinct(rng: RandomNumberGenerator, n: int, lo: int, hi: int) -> Array:
	var out: Array = []
	while out.size() < n:
		var v := rng.randi_range(lo, hi)
		if not out.has(v):
			out.append(v)
	return out


static func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := b
		b = a % b
		a = t
	return a


## An item as a lesson writes it: a sentence in quotation marks, a phrase as it is.
static func _said(item: String) -> String:
	return "“%s”" % item.trim_suffix(".") if item.ends_with(".") else item


## A number as the lessons write it: 2.5, 40, 6.25.
static func _num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return K.fmt(roundi(v))
	if is_equal_approx(v * 10.0, roundf(v * 10.0)):
		return "%.1f" % v
	return "%.2f" % v


## A number as an answer is typed: 2.5, 40000 (no commas).
static func _ans(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(roundi(v))
	if is_equal_approx(v * 10.0, roundf(v * 10.0)):
		return "%.1f" % v
	return "%.2f" % v


## A whole number with the lessons' minus sign.
static func _signed(v: int) -> String:
	return ("−" if v < 0 else "") + K.fmt(absi(v))


static func _ordinal(n: int) -> String:
	if n % 100 >= 11 and n % 100 <= 13:
		return "%dth" % n
	return "%d%s" % [n, {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")]


static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


static func _pick_any(rng: RandomNumberGenerator, list: Array, count: int) -> Array:
	var pool := list.duplicate()
	K.shuffle(rng, pool)
	return pool.slice(0, count)
