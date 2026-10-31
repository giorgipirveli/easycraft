class_name G6HumanitiesGen
extends RefCounted
## Owner #70 and #73 (research §6.6): grade 6 history, geography and citizenship generators. History: centuries (AD and
## BC), a medieval village's three fields in turn, years apart and anniversaries, events in order on a timeline,
## al-Khwarizmi's word puzzles ("a thing and 5 make 12"), salt caravans across the Sahara, Inca quipu cords, and the
## harvest after the Black Death. Geography: population density, a population's change, cities growing, jobs in four
## sectors, grid references and contours on a detailed map, map scales, climate graphs, rivers' features and processes,
## places in Africa and Asia on the world's grid, and a map in layers. Citizenship (in the game's gold): the three jobs of
## government, seats and majorities, disagreeing well, take-home pay, compound interest, insurance, a scam's warning
## signs, and a week's footprint. SchoolGen "g6h.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) ->
## Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for
## tests/unit/test_g6_humanities_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi"]
const MONTHS: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September",
	"October", "November", "December"]
const ORDINAL_WORDS := {1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth", 6: "sixth"}

## The medieval world's dated events, as the lessons give them: [what happened, the year (AD), about?].
const EVENTS: Array = [
	["Constantinople becomes Rome's new capital", 330, false],
	["The Roman Empire splits for good", 395, false],
	["The Roman army leaves Britain", 410, true],
	["The Western Roman Empire ends", 476, false],
	["Hagia Sophia is finished", 537, false],
	["The Tang dynasty begins", 618, false],
	["Baghdad is founded", 762, false],
	["Vikings raid Lindisfarne", 793, false],
	["Al-Khwarizmi's algebra book", 820, true],
	["The oldest dated printed book", 868, false],
	["Alfred becomes king of Wessex", 871, false],
	["Alfred wins at Edington", 878, false],
	["The Song dynasty begins", 960, false],
	["Vikings reach North America", 1000, true],
	["The Battle of Hastings", 1066, false],
	["The Domesday Book is made", 1086, false],
	["Shen Kuo describes the compass", 1088, false],
	["Minamoto Yoritomo becomes shogun", 1192, false],
	["Magna Carta is sealed", 1215, false],
	["Sundiata founds the Mali Empire", 1235, true],
	["Simon de Montfort's parliament", 1265, false],
	["Mansa Musa travels to Mecca", 1324, false],
	["Tenochtitlan is founded", 1325, true],
	["The Black Death reaches England", 1348, false],
	["The Peasants' Revolt", 1381, false],
	["Pachacuti begins the Inca Empire", 1438, false],
	["Constantinople falls to the Ottomans", 1453, false],
]
## Grade 5's dated events before AD 1 (the spiral), for years across BC and AD.
const BC_EVENTS: Array = [["The first Olympic Games", -776], ["Rome is founded, says the legend", -753],
	["Rome becomes a republic", -509], ["Julius Caesar lands in Britain", -55],
	["Augustus becomes Rome's first emperor", -27]]
const ANNIVERSARIES: Array[int] = [100, 200, 300, 500, 600, 700, 800, 900, 1000]

## A village's three big fields and what each grows, year after year: wheat, then beans, then a year of rest (fallow).
const FIELDS: Array[String] = ["North", "East", "West"]
const CROPS: Array[String] = ["wheat", "beans", "nothing: it rests"]
const QUIPU_THINGS: Array[String] = ["maize", "potatoes", "llamas", "houses", "workers", "sacks", "blankets"]
const TOWNS: Array[String] = ["Pebbleton", "Mossfield", "Brightwater", "Fernby", "Cloudmere", "Sunhaven", "Riverton",
	"Hollowby"]

## Jobs and their sector: 0 primary (taking from nature), 1 secondary (making things), 2 tertiary (services), 3
## quaternary (knowledge and research).
const SECTORS: Array[String] = ["primary", "secondary", "tertiary", "quaternary"]
const JOBS := {"farmer": 0, "fisher": 0, "miner": 0, "forester": 0, "quarry worker": 0, "shepherd": 0,
	"car factory worker": 1, "builder": 1, "steelworker": 1, "shipbuilder": 1, "furniture maker": 1, "brickmaker": 1,
	"teacher": 2, "nurse": 2, "shop assistant": 2, "bus driver": 2, "hairdresser": 2, "firefighter": 2,
	"research scientist": 3, "medical researcher": 3, "data scientist": 3, "robot designer": 3}

## A detailed map's symbols, in words.
const SYMBOL_WORDS := {"worship": "a place of worship", "school": "a school", "farm": "a farm", "car_park": "a car park",
	"campsite": "a campsite", "viewpoint": "a viewpoint", "castle": "a castle"}
const SIDE_WORDS := {"n": "north", "e": "east", "s": "south", "w": "west"}

## Climate graphs' patterns: a month's °C and mm (northern hemisphere; a southern place's year is 6 months on).
const CLIMATES := {
	"temperate": {"temp": [4, 5, 7, 9, 13, 16, 18, 18, 15, 11, 7, 5], "rain": [60, 45, 45, 45, 50, 50, 50, 55, 55, 70, 65,
		60]},
	"tropical rainforest": {"temp": [26, 26, 27, 27, 27, 27, 26, 26, 27, 27, 27, 26], "rain": [250, 260, 300, 280, 200,
		120, 100, 110, 140, 200, 230, 240]},
	"monsoon": {"temp": [24, 25, 27, 29, 30, 29, 27, 27, 27, 28, 27, 25], "rain": [0, 0, 0, 0, 20, 500, 650, 450, 300, 60,
		10, 0]},
	"hot desert": {"temp": [14, 16, 20, 24, 28, 30, 31, 31, 29, 25, 20, 16], "rain": [5, 4, 3, 1, 0, 0, 0, 0, 0, 1, 3, 5]},
	"cold continental": {"temp": [-10, -8, -2, 6, 13, 17, 19, 17, 11, 5, -2, -7], "rain": [40, 35, 35, 40, 55, 80, 90, 80,
		65, 60, 50, 45]},
}
const RAIN_STEPS: Array[int] = [10, 20, 25, 50, 100, 200]

## Rivers: features by course; what erosion and deposition do; erosion's and transport's processes.
const UPPER: Array[String] = ["waterfall", "gorge", "V-shaped valley", "interlocking spurs", "rapids"]
const LOWER: Array[String] = ["delta", "estuary", "levee", "wide floodplain"]
const EROSION: Array[String] = ["the outside of a bend wears away", "a plunge pool gets deeper",
	"a waterfall moves back upstream", "a gorge gets longer", "a valley gets deeper"]
const DEPOSITION: Array[String] = ["sand piles up inside a bend", "a delta grows out into the sea",
	"a levee builds up in a flood", "mud settles on a floodplain"]
const PROCESSES := {
	"hydraulic action": "The force of the water pushes into cracks and breaks the rock.",
	"abrasion": "Stones carried by the river scrape the bed and banks.",
	"attrition": "Stones knock into each other and become smaller and rounder.",
	"solution": "Some rocks, such as limestone, dissolve in the water.",
	"traction": "Big boulders roll along the river bed.",
	"saltation": "Small stones bounce along the river bed.",
	"suspension": "Fine mud is carried along in the water.",
}
const EROSION_PROCESSES: Array[String] = ["hydraulic action", "abrasion", "attrition", "solution"]
const TRANSPORT_PROCESSES: Array[String] = ["traction", "saltation", "suspension", "solution"]

## Places to the nearest degree: [latitude (N +), longitude (E +)].
const AFRICA := {"Cairo": [30, 31], "Lagos": [7, 3], "Nairobi": [-1, 37], "Kinshasa": [-4, 15], "Cape Town": [-34, 18],
	"Timbuktu": [17, -3], "Dakar": [15, -17], "Accra": [6, 0], "Marrakesh": [32, -8], "Mombasa": [-4, 40],
	"Harare": [-18, 31]}
## (Places far to the east, such as Tokyo, are left out: their names would be written leftwards over their neighbours.)
const ASIA := {"Beijing": [40, 116], "Shanghai": [31, 121], "Delhi": [29, 77], "Mumbai": [19, 73],
	"Dhaka": [24, 90], "Jakarta": [-6, 107], "Singapore": [1, 104], "Everest": [28, 87], "Bangkok": [14, 101],
	"Manila": [15, 121]}

## The three jobs of government: 0 makes laws (parliament), 1 carries them out (the government), 2 judges (the courts).
const BRANCHES: Array[String] = ["makes laws", "carries out laws", "judges laws"]
const BRANCH_NAMES: Array[String] = ["parliament", "the government", "the courts"]
const BRANCH_JOBS := {"votes on a new law": 0, "debates a plan for a law": 0, "changes an old law": 0,
	"agrees the taxes for next year": 0, "runs the schools and hospitals": 1, "collects the taxes": 1,
	"plans new railways": 1, "sends out passports": 1, "decides if someone broke a law": 2,
	"settles an argument about a contract": 2, "says what a law means": 2, "holds a fair trial": 2}
const BRANCH_CASES := {
	"A judge decides a new rule goes against the country's constitution.": 2,
	"Members vote to change the age for a driving test.": 0,
	"Ministers decide how to spend the money for roads.": 1,
	"A jury listens to both sides and gives its verdict.": 2,
	"A plan for a law is read three times and debated.": 0,
	"Civil servants open a new school the law allowed.": 1,
}
const PARTIES: Array[String] = ["Oak", "River", "Sun"]
const AREAS: Array[String] = ["North", "South", "East", "West", "Centre"]

## Disagreeing well: what helps a discussion, and what gets in its way (with the mistake's name).
const HELPS: Array[String] = ["I disagree, because the survey says otherwise.", "Where does that number come from?",
	"Your evidence is better. I've changed my mind.", "I think so, because more of us can come then.",
	"So you mean the park is too far? Is that right?", "That's a fair point, but think about the cost."]
const MISTAKES := {"You would say that. You're always wrong.": "attacking the person",
	"Only silly people think that.": "attacking the person",
	"Everyone thinks so, so it must be true.": "following the crowd",
	"All my friends agree, so I must be right.": "following the crowd",
	"So you want to ban all fun forever?": "twisting what was said",
	"You said less homework, so you want no school!": "twisting what was said",
	"I'm not listening. My idea is best.": "not listening"}
const MISTAKE_NAMES: Array[String] = ["attacking the person", "following the crowd", "twisting what was said",
	"not listening"]

## Scams: warning signs, and safe things to do.
const SIGNS: Array[String] = ["asks for your password", "says you must act right now",
	"offers a prize you never entered for", "has a link with an odd spelling", "asks you to keep it a secret",
	"wants gold sent to a stranger", "says your account will close today"]
const SAFE: Array[String] = ["stop and tell a trusted grown-up", "type the website's address yourself",
	"block and report the sender", "use a different password for each account", "leave links in surprise messages alone"]
const SCAM_CASES: Array[String] = [
	"A message says your game account closes today unless you log in at its link.",
	"A stranger online says you have won 5,000 gold and asks for your password to send it.",
	"A text from a new number says: it's your friend, please send gold now and tell no one.",
	"A pop-up offers a free gold maker if you type your username and password.",
	"An email says a parcel is waiting and asks for card details to pay a small fee."]
const SCAM_RIGHT := "don't reply or click; tell a grown-up"
const SCAM_WRONGS: Array[String] = ["click the link quickly to check", "reply with your details",
	"send it on to your friends", "do what it says, it seems urgent"]

## A week's footprint points (the game's own measure: more points, more harm to the planet).
const ACTS := {"car trip": 4, "bus trip": 2, "beef burger": 6, "bean burger": 1, "new T-shirt": 5, "used T-shirt": 1,
	"hot bath": 3, "short shower": 1}
const SWAPS: Array = [["car trip", "walk", 0], ["beef burger", "bean burger", 1], ["new T-shirt", "used T-shirt", 1],
	["hot bath", "short shower", 1], ["car trip", "bus trip", 2]]


# --- History: centuries (g6.history.after_rome) -----------------------------------------------------------------------

## Level 1: the century of a year from 1001 to 1599, chosen from four; level 2: the century's number for 401-1999;
## level 3: a BC year's century, or which year belongs in a century (the "1200s are the 13th century" trap). Years
## ending in 00 are left out (1300 is the last year of the 13th century, a puzzle for later).
static func century(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var hint := "A century's number is one more than the hundreds in its years: the 1200s are the 13th century."
	if level < 3:
		var y := _not_hundred(rng, 1001 if level == 1 else 401, 1599 if level == 1 else 1999)
		var c := (y - 1) / 100 + 1
		var explain := "%d is in the %d00s, and the century is one more than %d: %d + 1 = %d, the %s century." % [y,
			y / 100, y / 100, y / 100, c, _ordinal(c)]
		if level == 1:
			var wrongs: Array = []
			for v: int in [c - 1, c + 1, c - 2]:
				wrongs.append("the %s century" % _ordinal(v))
			ex = K.choice(rng, "In which century is the year %d?" % y, "the %s century" % _ordinal(c), wrongs, hint,
				explain)
			ex.data = {"ask": "choice", "year": y}
		else:
			ex = K.number("Which century is the year %d in? Type its number: 13 for the 13th century." % y, str(c), hint,
				explain)
			ex.data = {"ask": "number", "year": y}
		return ex
	if rng.randf() < 0.5:
		var y := _not_hundred(rng, 101, 999)
		var c := (y - 1) / 100 + 1
		ex = K.number("BC centuries count back from AD 1: 1 BC to 100 BC is the 1st century BC. Which century BC is %d BC in? Type its number." % y,
			str(c), "Count back from AD 1 the way you count forward: the century is one more than the hundreds.",
			"%d BC is in the %d00s BC, one more than %d: the %s century BC." % [y, y / 100, y / 100, _ordinal(c)])
		ex.data = {"ask": "bc", "year": -y}
		return ex
	var c := rng.randi_range(6, 15)
	var right := (c - 1) * 100 + rng.randi_range(1, 99)
	var wrongs: Array = [c * 100 + rng.randi_range(1, 99), (c - 2) * 100 + rng.randi_range(1, 99),
		(c + 1) * 100 + rng.randi_range(1, 99)]
	ex = K.choice(rng, "An old coin was made in the %s century. Which of these years could it be?" % _ordinal(c),
		str(right), wrongs.map(func(v: int) -> String: return str(v)), hint,
		"The %s century is the %d00s: the years %d to %d. So %d." % [_ordinal(c), c - 1, (c - 1) * 100 + 1, c * 100, right])
	ex.data = {"ask": "years", "century": c, "year": right}
	return ex


# --- History: a medieval village (g6.history.castles_feudal) ----------------------------------------------------------

## A village's three fields take turns: wheat, then beans, then a year of rest. Level 1: what a field grows next year;
## level 2: in a later year (the turn repeats every 3 years); level 3: strips growing food, or years a field rests.
static func three_fields(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var off := rng.randi_range(0, 2)
	var start := {}
	for i in 3:
		start[FIELDS[i]] = CROPS[(off + i) % 3]
	var head := "Year 1: North field %s, East field %s, West field %s. Each year a field moves on: wheat, beans, rest. " % [
		_crop_words(str(start.North)), _crop_words(str(start.East)), _crop_words(str(start.West))]
	var ex: Dictionary
	if level < 3:
		var field := FIELDS[rng.randi_range(0, 2)]
		var year := 2 if level == 1 else rng.randi_range(3, 8)
		var first := CROPS.find(str(start[field]))
		var crop := CROPS[(first + year - 1) % 3]
		var steps := "%s" % _crop_words(str(start[field]))
		for y in range(2, year + 1):
			steps += ", then %s" % _crop_words(CROPS[(first + y - 1) % 3])
		ex = K.choice(rng, head + "What does the %s field grow in year %d?" % [field, year], crop,
			CROPS.filter(func(c: String) -> bool: return c != crop),
			"Follow the field one year at a time: wheat, beans, rest, and round again every 3 years.",
			"The %s field: %s. In year %d it grows %s." % [field, steps, year, _crop_words(crop)])
		ex.data = {"ask": "crop", "start": start, "field": field, "year": year}
		return ex
	if rng.randf() < 0.5:
		var strips := rng.randi_range(12, 60)
		ex = K.number("A village's three big fields have %d strips of land each. Each year one field rests. How many strips grow food each year?" % strips,
			str(2 * strips), "Two of the three fields grow crops each year.",
			"Two fields grow food: %d + %d = %d strips." % [strips, strips, 2 * strips])
		ex.data = {"ask": "strips", "strips": strips}
		return ex
	var years := rng.randi_range(6, 12)
	var field := FIELDS[rng.randi_range(0, 2)]
	var first := CROPS.find(str(start[field]))
	var rests: Array[String] = []
	for y in range(1, years + 1):
		if CROPS[(first + y - 1) % 3] == CROPS[2]:
			rests.append(str(y))
	ex = K.number(head + "In years 1 to %d, how many years does the %s field rest?" % [years, field], str(rests.size()),
		"Find the first year it rests, then count on in threes.",
		"The %s field rests in year%s %s: %d year%s." % [field, "" if rests.size() == 1 else "s", ", ".join(rests),
			rests.size(), "" if rests.size() == 1 else "s"])
	ex.data = {"ask": "rests", "start": start, "field": field, "years": years}
	return ex


# --- History: years (g6.history.magna_carta) --------------------------------------------------------------------------

## "How many years apart?" Level 1: two events at most 300 years apart; level 2: any two events at least 20 years apart;
## level 3: a grade 5 event BC and a medieval one (no year 0), or an event's anniversary (a year).
static func medieval_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var exact: Array = EVENTS.filter(func(e: Array) -> bool: return not bool(e[2]))
		var e: Array = exact[rng.randi_range(0, exact.size() - 1)]
		if rng.randf() < 0.5:
			var bc: Array = BC_EVENTS[rng.randi_range(0, BC_EVENTS.size() - 1)]
			var a := int(bc[1])
			var b := int(e[1])
			ex = K.number("%s: %d BC. %s: AD %d. How many years apart are they? Remember: there is no year 0." % [bc[0], -a,
				e[0], b], str(b - a - 1), "Count the years up to AD 1, then the years after it. From 1 BC to AD 1 is 1 year.",
				"From %d BC to AD 1 is %d years. From AD 1 to AD %d is %d more. %d + %d = %d years." % [-a, -a, b, b - 1,
					-a, b - 1, b - a - 1])
			ex.data = {"ask": "apart", "from": a, "to": b, "events": [str(bc[0]), str(e[0])]}
			return ex
		var fits: Array = ANNIVERSARIES.filter(func(n: int) -> bool: return int(e[1]) + n <= 2020)
		var n: int = fits[rng.randi_range(0, fits.size() - 1)]
		var y := int(e[1]) + n
		ex = K.number("%s: %d. Which year was its %s anniversary, %d years later?" % [e[0], int(e[1]), _ordinal(n), n],
			str(y), "An anniversary comes a whole number of years after the event: add the years to it.",
			"%d + %d = %d." % [int(e[1]), n, y])
		ex.year = true   # 1966, not 1,966
		ex.data = {"ask": "anniversary", "event": str(e[0]), "years": n}
		return ex
	var two: Array = []
	for _try in 300:
		two = _pick_any(rng, EVENTS, 2)
		two.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
		var gap := int(two[1][1]) - int(two[0][1])
		if gap >= 20 and (level != 1 or gap <= 300):
			break
	var a := int(two[0][1])
	var b := int(two[1][1])
	ex = K.number("%s: %s. %s: %s. How many years apart are they?" % [two[0][0], _year_text(a, bool(two[0][2])), two[1][0],
		_year_text(b, bool(two[1][2]))], str(b - a), "Take the earlier year from the later one.",
		"%d − %d = %d years." % [b, a, b - a])
	ex.data = {"ask": "apart", "from": a, "to": b, "events": [str(two[0][0]), str(two[1][0])]}
	return ex


## "Put these events in order, earliest first." Level 1: three events at least 100 years apart; level 2: four, at least
## 30 apart; level 3: five, at least 5 apart.
static func medieval_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var count := level + 2
	var least: int = [100, 30, 5][level - 1]
	var picked: Array = []
	for _try in 300:
		picked = _pick_any(rng, EVENTS, count)
		picked.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
		var ok := true
		for k in range(1, picked.size()):
			ok = ok and int(picked[k][1]) - int(picked[k - 1][1]) >= least
		if ok:
			break
	var words: Array = []
	var years: Array[String] = []
	for e: Array in picked:
		words.append("%s (%s)" % [e[0], _year_text(int(e[1]), bool(e[2]))])
		years.append(str(int(e[1])))
	var ex := K.order(rng, "Put these events in order on a timeline, earliest first.", words,
		"Look at the years: the smaller the year, the longer ago it was.", "Earliest first: %s." % ", ".join(years))
	ex.data = {"events": picked.map(func(e: Array) -> String: return str(e[0]))}
	return ex


# --- History: al-Khwarizmi's puzzles (g6.history.baghdad_wisdom) ------------------------------------------------------

## Al-Khwarizmi wrote his algebra in words: "a thing" is the unknown. Level 1: a thing and a make b; level 2: k things
## and a make b; level 3: k things and a equal m things and b (take m things from both sides, then a).
static func al_jabr(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var thing := rng.randi_range(2, 40 if level == 1 else 20)
	var k := 1 if level == 1 else rng.randi_range(2, 5 if level == 2 else 7)
	var m := 0 if level < 3 else rng.randi_range(1, k - 1)
	var a := rng.randi_range(1, 30)
	var b := (k - m) * thing + a   # k things and a = m things and b
	var hint := "Balance it, as al-Khwarizmi did: do the same to both sides until one thing is left on its own."
	var ex: Dictionary
	if level == 1:
		ex = K.number("Al-Khwarizmi wrote puzzles in words. A thing and %d make %d. What is the thing?" % [a, b], str(thing),
			hint, "Take %d from both sides: the thing = %d − %d = %d." % [a, b, a, thing])
	elif level == 2:
		ex = K.number("In al-Khwarizmi's words: %d things and %d make %d. What is one thing?" % [k, a, b], str(thing), hint,
			"Take %d from both sides: %d things = %d − %d = %d. Share by %d: %d ÷ %d = %d." % [a, k, b, a, b - a, k, b - a, k,
				thing])
	else:
		ex = K.number("In al-Khwarizmi's words: %d things and %d equal %d thing%s and %d. What is one thing?" % [k, a, m,
			"" if m == 1 else "s", b], str(thing), hint,
			"Take %d thing%s from both sides: %d things and %d = %d. Take %d: %d things = %d. Share by %d: one thing = %d." % [
				m, "" if m == 1 else "s", k - m, a, b, a, k - m, b - a, k - m, thing])
	ex.data = {"k": k, "a": a, "m": m, "b": b, "thing": thing}
	return ex


# --- History: the Sahara's salt caravans (g6.history.african_kingdoms) ------------------------------------------------

## Level 1: camels × slabs of salt; level 2: days to cross the desert (km ÷ km a day); level 3: salt shared among towns.
static func caravan(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var camels := rng.randi_range(12, 60)
		var slabs := rng.randi_range(2, 6)
		ex = K.number("A salt caravan has %d camels. Each camel carries %d slabs of salt. How many slabs is that?" % [camels,
			slabs], str(camels * slabs), "Each camel carries the same: multiply.",
			"%d × %d = %d slabs." % [camels, slabs, camels * slabs])
		ex.data = {"ask": "slabs", "camels": camels, "slabs": slabs}
	elif level == 2:
		var per_day: int = [20, 25, 30, 35, 40][rng.randi_range(0, 4)]
		var days := rng.randi_range(15, 60)
		ex = K.number("A caravan must cross %s km of desert to reach Timbuktu. It travels %d km a day. How many days will it take?" % [
			K.fmt(per_day * days), per_day], str(days), "How many lots of the day's distance make the whole journey? Divide.",
			"%s ÷ %d = %d days." % [K.fmt(per_day * days), per_day, days])
		ex.data = {"ask": "days", "km": per_day * days, "per_day": per_day}
	else:
		var towns := rng.randi_range(2, 6)
		var camels := towns * rng.randi_range(3, 12)
		var slabs := rng.randi_range(2, 6)
		var each := camels * slabs / towns
		ex = K.number("A caravan of %d camels carries %d slabs of salt each. The salt is shared equally among %d market towns. How many slabs does each town get?" % [
			camels, slabs, towns], str(each), "First find all the slabs, then share them equally.",
			"%d × %d = %d slabs. %d ÷ %d = %d slabs each." % [camels, slabs, camels * slabs, camels * slabs, towns, each])
		ex.data = {"ask": "share", "camels": camels, "slabs": slabs, "towns": towns}
	return ex


# --- History: the Incas' quipu (g6.history.aztec_inca) ----------------------------------------------------------------

## A quipu cord's knots (quipu picture). Level 1: one cord, 1-99; level 2: one cord, 100-999 (sometimes an empty place);
## level 3: three named cords, their total or the difference between two.
static func quipu_number(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hint := "Read each place from the top: count the single knots for the hundreds and tens; in the ones place a long knot's turns count, and a figure-of-eight is 1."
	var ex: Dictionary
	if level < 3:
		var n := rng.randi_range(1, 99) if level == 1 else rng.randi_range(100, 999)
		if level == 2 and rng.randf() < 0.3:
			n = n / 100 * 100 + n % 10   # an empty tens place: no knots there
		var digits := SchoolPictureG6Hum.quipu_digits(n)
		ex = K.number("An Inca record keeper tied this cord. What number does it show?", str(n), hint,
			"%s: %d." % [_quipu_words(digits), n], {"kind": "quipu", "cords": [n], "places": true})
		ex.data = {"ask": "read", "cords": [n]}
		return ex
	var names := _pick(rng, QUIPU_THINGS, 3)
	var cords: Array = []
	for i in 3:
		cords.append(rng.randi_range(10, 400))
	var picture := {"kind": "quipu", "cords": cords, "names": names, "places": true}
	if rng.randf() < 0.5:
		var total := int(cords[0]) + int(cords[1]) + int(cords[2])
		ex = K.number("This quipu counts a town's %s, %s and %s. What is the total of the three cords?" % names, str(total),
			"Read each cord's number first, then add them.",
			"%d + %d + %d = %d." % [int(cords[0]), int(cords[1]), int(cords[2]), total], picture)
		ex.data = {"ask": "total", "cords": cords}
		return ex
	var order: Array = [0, 1, 2]
	order.sort_custom(func(x: int, y: int) -> bool: return int(cords[x]) > int(cords[y]))
	var hi: int = order[0]
	var lo: int = order[2]
	if int(cords[hi]) == int(cords[lo]):
		cords[hi] = int(cords[hi]) + 7
	ex = K.number("This quipu counts %s, %s and %s. How many more %s than %s are there?" % [names[0], names[1], names[2],
		names[hi], names[lo]], str(int(cords[hi]) - int(cords[lo])), "Read the two cords, then take the smaller from the bigger.",
		"%s: %d. %s: %d. %d − %d = %d." % [_cap(names[hi]), int(cords[hi]), names[lo], int(cords[lo]), int(cords[hi]),
			int(cords[lo]), int(cords[hi]) - int(cords[lo])], picture)
	ex.data = {"ask": "more", "cords": cords, "more": hi, "fewer": lo}
	return ex


# --- History: after the Black Death (g6.history.black_death_change) ---------------------------------------------------

## Fewer people were left to do the same work. Level 1: the same harvest with fewer workers takes longer; level 2: a
## village with a fraction of its people; level 3: a reaper's week of pay after a rise.
static func harvest_workers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var workers := 0
		var days := 0
		var left := 0
		for _try in 200:
			workers = rng.randi_range(6, 20)
			days = rng.randi_range(2, 8)
			left = rng.randi_range(2, workers - 1)
			if workers * days % left == 0 and workers * days / left <= 40:
				break
		if workers * days % left != 0:
			workers = 12
			days = 4
			left = 8
		var need := workers * days
		ex = K.number("Before the Black Death, %d workers brought in a lord's harvest in %d days. Afterwards only %d workers were left. How many days would the same harvest take them?" % [
			workers, days, left], str(need / left),
			"Find how many days of work the harvest needs in all, then share them among the workers left.",
			"%d workers × %d days = %d days of work. %d ÷ %d = %d days." % [workers, days, need, need, left, need / left])
		ex.data = {"ask": "days", "workers": workers, "days": days, "left": left}
	elif level == 2:
		var parts: Array = [[1, 2, "half"], [2, 3, "two thirds"], [3, 4, "three quarters"], [3, 5, "three fifths"]]
		var p: Array = parts[rng.randi_range(0, parts.size() - 1)]
		var people := int(p[1]) * rng.randi_range(12, 120)
		var now := people / int(p[1]) * int(p[0])
		ex = K.number("Before the Black Death, a village had %d people. When the plague had passed, it had only %s as many. How many people was that?" % [
			people, p[2]], str(now), "Find one part first (divide by the bottom number), then take as many parts as the top number.",
			"%d ÷ %d = %d. %d × %d = %d people." % [people, int(p[1]), people / int(p[1]), people / int(p[1]), int(p[0]), now])
		ex.data = {"ask": "fraction", "people": people, "num": int(p[0]), "den": int(p[1])}
	else:
		var rise: int = [25, 50, 100][rng.randi_range(0, 2)]
		var wage := 4 * rng.randi_range(1, 5)
		var days := rng.randi_range(5, 6)
		var new_wage := wage + wage * rise / 100
		ex = K.number("Workers were now scarce, so they could ask for more. A reaper earned %d gold a day before the plague; afterwards lords paid %d%% more. How much did a reaper earn in a %d-day week?" % [
			wage, rise, days], str(new_wage * days), "Find the new pay for one day first, then multiply by the days.",
			"%d%% of %d is %d, so a day's pay was %d + %d = %d gold. %d × %d = %d gold." % [rise, wage, wage * rise / 100,
				wage, wage * rise / 100, new_wage, new_wage, days, new_wage * days])
		ex.data = {"ask": "wage", "wage": wage, "rise": rise, "days": days}
	return ex


# --- Geography: population (g6.geography.population) ------------------------------------------------------------------

## People per km². Level 1: count the dots on a small area (dot_density picture); level 2: a big island's density;
## level 3: which of two places is more crowded, or the people from a density and an area.
static func density(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var hint := "Population density is the number of people ÷ the area in km²."
	if level == 1:
		var km2 := rng.randi_range(1, 6)
		var each := rng.randi_range(2, 8)
		var town := TOWNS[rng.randi_range(0, TOWNS.size() - 1)]
		ex = K.number("Each dot is one person living in %s. How many people are there for each km²?" % town, str(each), hint,
			"%d people ÷ %d km² = %d people per km²." % [km2 * each, km2, each],
			{"kind": "dot_density", "areas": [{"name": town, "people": km2 * each, "km2": km2}]})
		ex.data = {"ask": "density", "people": km2 * each, "km2": km2}
		return ex
	if level == 2:
		var area := rng.randi_range(2, 60) * 5
		var each := rng.randi_range(1, 90) * 10
		ex = K.number("An island of %s km² has %s people. What is its population density, in people per km²?" % [K.fmt(area),
			K.fmt(area * each)], str(each), hint, "%s ÷ %s = %s people per km²." % [K.fmt(area * each), K.fmt(area),
				K.fmt(each)])
		ex.data = {"ask": "density", "people": area * each, "km2": area}
		return ex
	if rng.randf() < 0.5:
		var two := _pick(rng, TOWNS, 2)
		var areas: Array[int] = [rng.randi_range(2, 40) * 5, rng.randi_range(2, 40) * 5]
		var eaches: Array[int] = [rng.randi_range(2, 60) * 10, 0]
		eaches[1] = eaches[0] + rng.randi_range(1, 30) * 10 * (1 if rng.randf() < 0.5 else -1)
		if eaches[1] <= 0:
			eaches[1] = eaches[0] + 50
		var busier := 0 if eaches[0] > eaches[1] else 1
		ex = K.choice(rng, "%s has %s people on %d km². %s has %s people on %d km². Which is more crowded?" % [two[0],
			K.fmt(areas[0] * eaches[0]), areas[0], two[1], K.fmt(areas[1] * eaches[1]), areas[1]], two[busier],
			[two[1 - busier]], "Crowded means more people on each km²: work out both densities, then compare.",
			"%s: %s ÷ %d = %d a km². %s: %s ÷ %d = %d a km². %s is more crowded." % [two[0], K.fmt(areas[0] * eaches[0]),
				areas[0], eaches[0], two[1], K.fmt(areas[1] * eaches[1]), areas[1], eaches[1], two[busier]])
		ex.data = {"ask": "busier", "places": two, "people": [areas[0] * eaches[0], areas[1] * eaches[1]], "km2": areas}
		return ex
	var area := rng.randi_range(3, 50)
	var each := rng.randi_range(2, 50) * 10
	ex = K.number("A valley has a population density of %d people per km². Its area is %d km². How many people live there?" % [
		each, area], str(area * each), "Density is people ÷ area, so the people are density × area.",
		"%d × %d = %s people." % [each, area, K.fmt(area * each)])
	ex.data = {"ask": "people", "density": each, "km2": area}
	return ex


# --- Geography: a population's change (g6.geography.migration) --------------------------------------------------------

## Level 1: people moving in and out; level 2: births and deaths too (it grows); level 3: the population after a year
## (it may fall).
static func population_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var town := TOWNS[rng.randi_range(0, TOWNS.size() - 1)]
	var ex: Dictionary
	if level == 1:
		var out := rng.randi_range(20, 400)
		var moved_in := out + rng.randi_range(10, 400)
		ex = K.number("In one year, %d people moved to %s and %d moved away. By how many did moving change the population?" % [
			moved_in, town, out], str(moved_in - out), "Take the people who left from the people who came.",
			"%d − %d = %d more people." % [moved_in, out, moved_in - out])
		ex.data = {"ask": "moving", "in": moved_in, "out": out}
		return ex
	var births := rng.randi_range(100, 900)
	var deaths := rng.randi_range(50, births - 20)
	var out := rng.randi_range(50, 600)
	var moved_in := rng.randi_range(50, 600)
	if level == 2:
		while births - deaths + moved_in - out <= 0:
			moved_in += 50
		var change := births - deaths + moved_in - out
		ex = K.number("In one year %s had %d births and %d deaths. %d people moved in and %d moved out. By how many people did it grow?" % [
			town, births, deaths, moved_in, out], str(change),
			"Add what joins the town (births, people moving in) and take away what leaves it (deaths, people moving out).",
			"%d + %d = %d joined. %d + %d = %d left. %d − %d = %d." % [births, moved_in, births + moved_in, deaths, out,
				deaths + out, births + moved_in, deaths + out, change])
		ex.data = {"ask": "change", "births": births, "deaths": deaths, "in": moved_in, "out": out}
		return ex
	var start := rng.randi_range(20, 90) * 100
	if rng.randf() < 0.4:   # more people leave than join
		out = births - deaths + moved_in + rng.randi_range(10, 300)
	var now := start + births - deaths + moved_in - out
	ex = K.number("%s had %s people at the start of a year. That year: %d births, %d deaths, %s moved in, %s moved out. How many lived there at the end?" % [
		town, K.fmt(start), births, deaths, K.fmt(moved_in), K.fmt(out)], str(now),
		"Work out the change first (births − deaths + moving in − moving out); it may be less than 0.",
		"%d − %d + %d − %d = %d. %s + %d = %s." % [births, deaths, moved_in, out, now - start, K.fmt(start), now - start,
			K.fmt(now)] if now >= start else "%d − %d + %d − %d = −%d. %s − %d = %s." % [births, deaths, moved_in, out,
			start - now, K.fmt(start), start - now, K.fmt(now)])
	ex.data = {"ask": "end", "start": start, "births": births, "deaths": deaths, "in": moved_in, "out": out}
	return ex


# --- Geography: cities (g6.geography.cities) ---------------------------------------------------------------------------

## Level 1: how many more people a town has; level 2: how many times bigger it grew; level 3: the percentage of a
## country's people living in towns and cities.
static func city_growth(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var town := TOWNS[rng.randi_range(0, TOWNS.size() - 1)]
	var ex: Dictionary
	if level == 1:
		var before := rng.randi_range(2, 90) * 100
		var after := before + rng.randi_range(1, 200) * 100
		ex = K.number("In 1900 %s had %s people. By 2000 it had %s. How many more people was that?" % [town, K.fmt(before),
			K.fmt(after)], str(after - before), "Take the smaller number from the bigger one.",
			"%s − %s = %s." % [K.fmt(after), K.fmt(before), K.fmt(after - before)])
		ex.data = {"ask": "more", "before": before, "after": after}
	elif level == 2:
		var before := rng.randi_range(2, 60) * 500
		var times := rng.randi_range(2, 12)
		ex = K.number("In 1850 %s had %s people. Today it has %s. How many times bigger has it grown?" % [town, K.fmt(before),
			K.fmt(before * times)], str(times), "Divide the new number by the old one.",
			"%s ÷ %s = %d times." % [K.fmt(before * times), K.fmt(before), times])
		ex.data = {"ask": "times", "before": before, "after": before * times}
	else:
		var percent := rng.randi_range(12, 95)
		var people := rng.randi_range(1, 50) * 100000
		var urban := people / 100 * percent
		ex = K.number("A country has %s people, and %s of them live in towns and cities. What percentage is that?" % [
			K.fmt(people), K.fmt(urban)], str(percent), "Find how many people make 1% (÷ 100), then how many of those are in the towns.",
			"1%% is %s ÷ 100 = %s. %s ÷ %s = %d, so %d%%." % [K.fmt(people), K.fmt(people / 100), K.fmt(urban),
				K.fmt(people / 100), percent, percent])
		ex.data = {"ask": "percent", "people": people, "urban": urban}
	return ex


# --- Geography: jobs (g6.geography.jobs_industry) ----------------------------------------------------------------------

## Level 1: sort jobs into primary, secondary and tertiary; level 2: three sectors, one of them quaternary; level 3:
## which sector a job is in, from all four.
static func sector_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hint := "Primary jobs take from nature; secondary jobs make things; tertiary jobs serve people; quaternary jobs find out and invent."
	if level == 3:
		var job: String = JOBS.keys()[rng.randi_range(0, JOBS.size() - 1)]
		var s := int(JOBS[job])
		var ex := K.choice(rng, "Which sector of the economy is a %s's job in?" % job, SECTORS[s],
			SECTORS.filter(func(x: String) -> bool: return x != SECTORS[s]), hint,
			"A %s %s, so the job is in the %s sector." % [job, _sector_why(s), SECTORS[s]])
		ex.data = {"ask": "choice", "job": job}
		return ex
	var groups: Array[int] = [0, 1, 2]
	if level == 2:
		groups.assign([[0, 2, 3], [1, 2, 3], [0, 1, 3]][rng.randi_range(0, 2)])
	var count := 4 if level == 1 else 6
	var items: Array = []
	var answer: Array = []
	var per: Array[int] = [2, 1, 1]
	if level != 1:
		per = [2, 2, 2]
	GenKit.shuffle(rng, per)
	var said: Array[String] = []
	for g in 3:
		var pool: Array[String] = []
		for j: String in JOBS:
			if int(JOBS[j]) == groups[g]:
				pool.append(j)
		var some := _pick(rng, pool, per[g])
		items.append_array(some)
		said.append("%s: %s" % [_cap(SECTORS[groups[g]]), ", ".join(some)])
	GenKit.shuffle(rng, items)
	for it: String in items:
		answer.append(groups.find(int(JOBS[it])))
	var names: Array[String] = []
	for g: int in groups:
		names.append(SECTORS[g])
	var ex := {"type": "sort", "prompt": "Sort these jobs into their sectors.", "groups": names, "items": items,
		"answer": answer, "hint": hint, "explain": "%s." % ". ".join(said)}
	ex.data = {"ask": "sort", "count": count}
	return ex


# --- Geography: a detailed map (g6.geography.detailed_maps) -----------------------------------------------------------

## A map with symbols and points (os_map). Level 1: a symbol's four-figure square; level 2: a point's six-figure
## reference; level 3: what is at a six-figure reference, or which point is there.
static func grid_ref(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var e0 := rng.randi_range(10, 80)
	var n0 := rng.randi_range(10, 80)
	var spots := _map_spots(rng, e0, n0, 6)   # on 4 × 2 squares: big enough to read tenths on an exercise's card
	var kinds := _pick_symbols(rng, 3)
	var symbols: Array = []
	for i in 3:
		symbols.append({"what": kinds[i], "e": int(spots[i].x), "n": int(spots[i].y)})
	var points: Array = []
	for i in 3:
		points.append({"e": int(spots[3 + i].x), "n": int(spots[3 + i].y), "label": ["A", "B", "C"][i]})
	var picture := {"kind": "os_map", "e0": e0, "n0": n0, "cols": 4, "rows": 2, "symbols": symbols, "points": points}
	var ex: Dictionary
	if level == 1:
		var s: Dictionary = symbols[rng.randi_range(0, 2)]
		var e := int(s.e)
		var n := int(s.n)
		var right := SchoolPictureG6Hum.four_figure(e, n)
		var wrongs: Array = ["%02d%02d" % [n / 10, e / 10], "%02d%02d" % [e / 10 + 1, n / 10], "%02d%02d" % [e / 10,
			n / 10 + 1], "%02d%02d" % [e / 10 - 1, n / 10]]
		ex = K.choice(rng, "Which square is %s in? Choose its four-figure grid reference." % SYMBOL_WORDS[str(s.what)],
			right, wrongs.filter(func(w: String) -> bool: return w != right).slice(0, 3),
			"Along the corridor, then up the stairs: the number along the bottom first, then the one up the side, for the square's bottom-left corner.",
			"The square's bottom-left corner is at %02d along and %02d up: %s." % [e / 10, n / 10, right], picture)
		ex.data = {"ask": "four", "e": e, "n": n}
		return ex
	var hint := "Along, then up: the square's number along the bottom and the tenths across it, then the number up the side and the tenths up it."
	if level == 2:
		var i := rng.randi_range(0, 2)
		var e := int(points[i].e)
		var n := int(points[i].n)
		var right := SchoolPictureG6Hum.six_figure(e, n)
		var wrongs: Array = ["%03d%03d" % [n, e], "%03d%03d" % [e / 10 * 10, n / 10 * 10], "%03d%03d" % [e + 2, n],
			"%03d%03d" % [e, n - 2]]
		ex = K.choice(rng, "What is the six-figure grid reference of point %s?" % str(points[i].label), right,
			wrongs.filter(func(w: String) -> bool: return w != right).slice(0, 3), hint,
			"Point %s is %d tenths along from line %02d and %d tenths up from line %02d: %s." % [str(points[i].label), e % 10,
				e / 10, n % 10, n / 10, right], picture)
		ex.data = {"ask": "six", "e": e, "n": n}
		return ex
	if rng.randf() < 0.5:
		var s: Dictionary = symbols[rng.randi_range(0, 2)]
		var ref := SchoolPictureG6Hum.six_figure(int(s.e), int(s.n))
		var right := str(SYMBOL_WORDS[str(s.what)])
		var wrongs: Array = []
		for o: Dictionary in symbols:
			if o != s:
				wrongs.append(str(SYMBOL_WORDS[str(o.what)]))
		ex = K.choice(rng, "What is at grid reference %s?" % ref, right, wrongs, hint,
			"%s is %s tenths along from line %s and %s tenths up from line %s: %s." % [ref, ref[2], ref.substr(0, 2), ref[5],
				ref.substr(3, 2), right], picture)
		ex.data = {"ask": "what", "e": int(s.e), "n": int(s.n), "what": str(s.what)}
		return ex
	var i := rng.randi_range(0, 2)
	var ref := SchoolPictureG6Hum.six_figure(int(points[i].e), int(points[i].n))
	ex = K.choice(rng, "Which point is at grid reference %s?" % ref, "point %s" % str(points[i].label),
		points.filter(func(q: Dictionary) -> bool: return q != points[i]).map(func(q: Dictionary) -> String: return "point %s" % str(q.label)),
		hint,
		"%s: %s tenths along from line %s, %s tenths up from line %s. That is point %s." % [ref, ref[2], ref.substr(0, 2),
			ref[5], ref.substr(3, 2), str(points[i].label)], picture)
	ex.data = {"ask": "point", "e": int(points[i].e), "n": int(points[i].n), "label": str(points[i].label)}
	return ex


## Contour lines. Level 1: which side of a hill is steepest (os_map); level 2: a contour's height from the lowest one and
## the interval; level 3: a climb from a contour to the top, or up across contour lines.
static func contours(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var side := ["n", "e", "s", "w"][rng.randi_range(0, 3)] as String
		var interval: int = [10, 20, 25, 50][rng.randi_range(0, 3)]
		var low := interval * rng.randi_range(1, 4)
		var heights: Array = []
		for k in 4:
			heights.append(low + k * interval)
		var e0 := rng.randi_range(10, 80)
		var n0 := rng.randi_range(10, 80)
		var picture := {"kind": "os_map", "e0": e0, "n0": n0, "cols": 4, "rows": 3, "hills": [{"e": e0 * 10 + 20,
			"n": n0 * 10 + 15, "heights": heights, "size": 13, "steep": side}]}
		ex = K.choice(rng, "Look at the contour lines round this hill. On which side is it steepest?",
			"the %s side" % SIDE_WORDS[side], ["n", "e", "s", "w"].filter(func(x: String) -> bool: return x != side).map(
				func(x: String) -> String: return "the %s side" % SIDE_WORDS[x]),
			"Contour lines close together mean steep ground; far apart means gentle.",
			"The lines bunch up on the %s side, so the ground climbs fastest there." % SIDE_WORDS[side], picture)
		ex.data = {"ask": "steep", "side": side}
		return ex
	var interval: int = [5, 10, 20, 25, 50][rng.randi_range(0, 4)]
	if level == 2:
		var low := interval * rng.randi_range(1, 10)
		var k := rng.randi_range(3, 6)
		var h := low + (k - 1) * interval
		ex = K.number("On a hill, the contour lines are %d m apart and the lowest is at %d m. How high is the %s line up from the bottom?" % [
			interval, low, ORDINAL_WORDS[k]], str(h), "Count the steps up from the lowest line: each step is one interval.",
			"The %s line is %d steps above the lowest: %d + %d × %d = %d m." % [ORDINAL_WORDS[k], k - 1, low, k - 1, interval,
				h])
		ex.data = {"ask": "line", "low": low, "interval": interval, "k": k}
		return ex
	if rng.randf() < 0.5:
		var start := interval * rng.randi_range(1, 8)
		var top := start + interval * rng.randi_range(2, 8) + rng.randi_range(1, interval - 1)
		ex = K.number("Point A is on the %d m contour. The hill's top has a spot height of %d m. How many metres do you climb from A to the top?" % [
			start, top], str(top - start), "Take the lower height from the higher one.", "%d − %d = %d m." % [top, start,
				top - start])
		ex.data = {"ask": "climb", "from": start, "top": top}
		return ex
	var start := interval * rng.randi_range(1, 8)
	var crossed := rng.randi_range(3, 8)
	ex = K.number("A path starts on the %d m contour and goes uphill, crossing %d more contour lines %d m apart. How high does it end, on the last line?" % [
		start, crossed, interval], str(start + crossed * interval), "Each line crossed going uphill is one interval higher.",
		"%d + %d × %d = %d m." % [start, crossed, interval, start + crossed * interval])
	ex.data = {"ask": "path", "from": start, "crossed": crossed, "interval": interval}
	return ex


## Scales. Level 1: 1:25,000 (4 cm is 1 km), cm to km; level 2: 1:50,000 (2 cm is 1 km), cm to km, halves; level 3: km to
## cm at 1:25,000, or a walk's minutes at 4 km an hour.
static func map_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var km := rng.randi_range(1, 6)
		ex = K.number("On a 1:25,000 map, 4 cm stands for 1 km. How many km is %d cm on the map?" % (4 * km), str(km),
			"How many lots of 4 cm are there? Each is 1 km.", "%d ÷ 4 = %d km." % [4 * km, km])
		ex.data = {"ask": "km", "scale": 25000, "cm": 4 * km}
	elif level == 2:
		var cm := rng.randi_range(1, 19)
		ex = K.number("On a 1:50,000 map, 2 cm stands for 1 km. How many km is %d cm on the map?" % cm, _half(cm),
			"Each 2 cm is 1 km, so halve the centimetres.", "%d ÷ 2 = %s km." % [cm, _half(cm)])
		ex.data = {"ask": "km", "scale": 50000, "cm": cm}
	elif rng.randf() < 0.5:
		var halves := rng.randi_range(1, 10)
		ex = K.number("On a 1:25,000 map, 4 cm stands for 1 km. How many cm on the map is a real walk of %s km?" % _half(halves),
			str(halves * 2), "Every 1 km is 4 cm on this map: multiply the km by 4.",
			"%s × 4 = %d cm." % [_half(halves), halves * 2])
		ex.data = {"ask": "cm", "scale": 25000, "km": halves / 2.0}
	else:
		var km := rng.randi_range(1, 6)
		ex = K.number("A path is %d cm long on a 1:25,000 map (4 cm is 1 km). Walking at 4 km an hour takes 15 minutes a km. How many minutes will the walk take?" % (
			4 * km), str(15 * km), "Find the real distance in km first, then the minutes for each km.",
			"%d ÷ 4 = %d km. %d × 15 = %d minutes." % [4 * km, km, km, 15 * km])
		ex.data = {"ask": "minutes", "cm": 4 * km}
	return ex


# --- Geography: climate graphs (g6.geography.climate_graphs, asia) -----------------------------------------------------

## A made-up place's climate graph (climograph). Level 1: the wettest or warmest month; level 2: the temperature range
## (its warmest and coldest months on grid lines) or the wettest month's rain (on a grid line); level 3: which climate it
## shows, or its hemisphere.
static func climate_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var kind: String = CLIMATES.keys()[rng.randi_range(0, CLIMATES.size() - 1)]
	var south := (kind == "temperate" or kind == "cold continental") and rng.randf() < 0.4
	var temp: Array[int] = []
	var rain: Array[int] = []
	for m in 12:
		var src := (m + 6) % 12 if south else m
		temp.append(int(CLIMATES[kind].temp[src]) + rng.randi_range(-1, 1))
		var r := int(CLIMATES[kind].rain[src])
		rain.append(maxi(0, r + rng.randi_range(-r / 10, r / 10)))
	_unique_top(temp)
	_unique_top(rain)
	var ask := ""
	match level:
		1:
			ask = ["wettest", "warmest"][rng.randi_range(0, 1)]
		2:   # a range is asked only where it is big enough to read (not the tropics' 1 or 2 °C)
			ask = ["range", "rain"][rng.randi_range(0, 1)] if kind != "tropical rainforest" and kind != "monsoon" else "rain"
		_:
			ask = "hemisphere" if (kind == "temperate" or kind == "cold continental") and rng.randf() < 0.5 else "climate"
	var scale := _climate_scale(temp, rain)
	for _settle in 6:   # the values asked about on grid lines, so they can be read (the scale may grow, so again)
		var moved := false
		if ask == "range":
			var hot := temp.find(temp.max())
			var cold := temp.find(temp.min())
			var step := int(scale.t_step)
			var up := int(ceil(temp[hot] / float(step))) * step
			var down := int(floor(temp[cold] / float(step))) * step
			moved = up != temp[hot] or down != temp[cold]
			temp[hot] = up
			temp[cold] = down
		elif ask == "rain":
			var wet := rain.find(rain.max())
			var step := int(scale.r_step)
			var up := maxi(step, int(ceil(rain[wet] / float(step))) * step)
			moved = up != rain[wet]
			rain[wet] = up
		if not moved:
			break
		scale = _climate_scale(temp, rain)
	var picture := {"kind": "climograph", "temp": temp, "rain": rain, "t_from": scale.t_from, "t_top": scale.t_top,
		"t_step": scale.t_step, "r_top": scale.r_top, "r_step": scale.r_step}
	var ex: Dictionary
	match ask:
		"wettest", "warmest":
			var values: Array[int] = temp
			if ask == "wettest":
				values = rain
			var m := values.find(values.max())
			var others: Array = []
			for k in 12:
				if k != m:
					others.append(MONTHS[k])
			ex = K.choice(rng, "This climate graph is of a made-up place. Which month is the %s?" % ask, MONTHS[m],
				_pick_any(rng, others, 3), "Rain is the blue bars (mm); temperature is the red line (°C). Find the tallest bar or the highest point.",
				"The %s is highest in %s." % ["blue bar" if ask == "wettest" else "red line", MONTHS[m]], picture)
		"range":
			var hi := temp.max() as int
			var lo := temp.min() as int
			ex = K.number("Read the red line. What is this place's temperature range, the warmest month take away the coldest, in °C?",
				str(hi - lo), "Find the highest and lowest points of the red line on the °C scale, then take one from the other.",
				"The warmest month is %s °C and the coldest %s °C: %s − %s = %d °C." % [_signed(hi), _signed(lo), _signed(hi),
					_signed(lo), hi - lo], picture)
		"rain":
			var wet := rain.find(rain.max())
			ex = K.number("Read the blue bars on the mm scale. How much rain falls in the wettest month?", str(rain[wet]),
				"Find the tallest bar and read across to the scale on the right.",
				"The tallest bar is %s: %d mm." % [MONTHS[wet], rain[wet]], picture)
		"hemisphere":
			var right := "southern" if south else "northern"
			ex = K.choice(rng, "Is this place in the northern or the southern hemisphere?", right, ["northern", "southern"].filter(
				func(x: String) -> bool: return x != right), "Summer is the warm part of the year. North of the Equator it comes in June to August; south of it, in December to February.",
				"Its warmest months are %s, so it is in the %s hemisphere." % ["December to February" if south else "June to August",
					right], picture)
		_:
			var names: Array = CLIMATES.keys().filter(func(x: String) -> bool: return x != kind)
			ex = K.choice(rng, "Which kind of climate does this graph show?", kind, _pick_any(rng, names, 3),
				"Look at both: is it hot all year or with a cold winter, and is it wet all year, dry all year, or very wet for a few months?",
				"%s." % _climate_why(kind), picture)
	ex.data = {"ask": ask, "kind": kind, "south": south}
	return ex


# --- Geography: rivers (g6.geography.river_processes) ------------------------------------------------------------------

## Level 1: sort features into the upper or lower course; level 2: sort changes into erosion or deposition; level 3:
## name an erosion or transport process from what it does.
static func river_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		var family: Array[String] = EROSION_PROCESSES
		if rng.randf() < 0.5:
			family = TRANSPORT_PROCESSES
		var right := family[rng.randi_range(0, family.size() - 1)]
		var ex := K.choice(rng, "%s Which process is this?" % PROCESSES[right], right, family.filter(
			func(x: String) -> bool: return x != right), "Think of what the water, or what it carries, is doing: breaking, scraping, knocking, dissolving, rolling, bouncing or floating.",
			"That is %s." % right)
		ex.data = {"ask": "process", "process": right}
		return ex
	var groups: Array[String] = ["upper course", "lower course"]
	var first: Array[String] = UPPER
	var second: Array[String] = LOWER
	if level == 2:
		groups = ["erosion", "deposition"]
		first = EROSION
		second = DEPOSITION
	var n := 4 if level == 1 else 5
	var a := rng.randi_range(1, n - 1)
	var one := _pick(rng, first, a)
	var two := _pick(rng, second, n - a)
	var items: Array = one + two
	GenKit.shuffle(rng, items)
	var answer: Array = items.map(func(it: String) -> int: return 0 if one.has(it) else 1)
	var hint := "The upper course is steep, in the hills; the lower course is wide and flat, near the sea." if level == 1 else \
		"Erosion wears land away; deposition drops what the river carried when it slows down."
	var ex := {"type": "sort", "prompt": "Sort these: %s or %s?" % groups, "groups": groups, "items": items,
		"answer": answer, "hint": hint, "explain": "%s: %s. %s: %s." % [_cap(groups[0]), ", ".join(one), _cap(groups[1]),
			", ".join(two)]}
	ex.data = {"ask": "sort", "groups": groups}
	return ex


# --- Geography: Africa and Asia on the world's grid (g6.geography.africa, asia) ---------------------------------------

static func africa_places(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _places(rng, level, AFRICA, "Africa")


static func asia_places(rng: RandomNumberGenerator, level: int) -> Dictionary:
	return _places(rng, level, ASIA, "Asia")


## Level 1: a place north or south of the Equator; level 2: of four places on the grid (latlong), the one furthest north,
## south or east; level 3: degrees of latitude between two places.
static func _places(rng: RandomNumberGenerator, level: int, table: Dictionary, continent: String) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var name: String = table.keys()[rng.randi_range(0, table.size() - 1)]
		var lat := int(table[name][0])
		var right := "north of the Equator" if lat > 0 else "south of the Equator"
		ex = K.choice(rng, "%s, in %s, is at %s, %s. Is it north or south of the Equator?" % [name, continent,
			SchoolPictureHistory.lat_text(lat), SchoolPictureHistory.long_text(int(table[name][1]))], right,
			["north of the Equator", "south of the Equator"].filter(func(x: String) -> bool: return x != right),
			"Look at the letter after the latitude: N or S.", "%s means %s." % [SchoolPictureHistory.lat_text(lat), right],
			{"kind": "latlong", "lat_step": 15, "long_step": 30, "points": [{"lat": lat, "long": int(table[name][1]),
				"label": name}]})
		ex.data = {"ask": "hemisphere", "place": name}
		return ex
	if level == 2:
		var four: Array = []
		var way := "north"
		for count: int in [4, 3]:   # four places if their names fit without overlapping, else three; one clear answer
			for _try in 300:
				four = _pick_any(rng, table.keys(), count)
				way = ["north", "south", "east"][rng.randi_range(0, 2)]
				if _labels_clear(four, table) and _furthest(four, table, way) != "":
					break
			if _labels_clear(four, table) and _furthest(four, table, way) != "":
				break
		var best := _furthest(four, table, way)
		var points: Array = []
		for p: Variant in four:
			points.append({"lat": int(table[p][0]), "long": int(table[p][1]), "label": str(p)})
		var words: Array[String] = []
		for p: Variant in four:
			words.append("%s %s" % [str(p), SchoolPictureHistory.lat_text(int(table[p][0])) if way != "east" else
				SchoolPictureHistory.long_text(int(table[p][1]))])
		ex = K.choice(rng, "Which of these places in %s is furthest %s?" % [continent, way], best,
			four.filter(func(p: Variant) -> bool: return str(p) != best).map(func(p: Variant) -> String: return str(p)),
			"North and south are the latitude (up the side); east is the longitude (along the bottom)." if way != "east" else
			"East is the longitude: the bigger the °E, the further east.", "%s. Furthest %s: %s." % [", ".join(words), way, best],
			{"kind": "latlong", "lat_step": 15, "long_step": 30, "points": points})
		ex.data = {"ask": way, "places": four}
		return ex
	var two: Array = []
	for _try in 300:
		two = _pick_any(rng, table.keys(), 2)
		if int(table[two[0]][0]) != int(table[two[1]][0]):
			break
	var la := int(table[two[0]][0])
	var lb := int(table[two[1]][0])
	var across := (la > 0) != (lb > 0) and la != 0 and lb != 0
	ex = K.number("%s is at %s and %s is at %s. How many degrees of latitude apart are they?" % [two[0],
		SchoolPictureHistory.lat_text(la), two[1], SchoolPictureHistory.lat_text(lb)], str(absi(la - lb)),
		"Both on the same side of the Equator: take one from the other. On opposite sides: add them." ,
		("%d° to the Equator and %d° beyond it: %d + %d = %d°." % [absi(la), absi(lb), absi(la), absi(lb), absi(la - lb)]) if across
		else ("%d − %d = %d°." % [maxi(absi(la), absi(lb)), mini(absi(la), absi(lb)), absi(la - lb)]))
	ex.data = {"ask": "apart", "places": two}
	return ex


## The place furthest `way` ("north", "south", "east"), or "" when two share the furthest line.
static func _furthest(names: Array, table: Dictionary, way: String) -> String:
	var key := 1 if way == "east" else 0
	var dir := -1 if way == "south" else 1
	var best := ""
	var tie := false
	for p: Variant in names:
		var v := int(table[p][key]) * dir
		if best == "" or v > int(table[best][key]) * dir:
			best = str(p)
			tie = false
		elif v == int(table[best][key]) * dir:
			tie = true
	return "" if tie else best


## Whether the places' dots and names on an exercise's world grid (about 392 × 196 pixels, names about 7.5 pixels a
## letter, written leftwards near the right edge as SchoolPictureHistory does) keep clear of each other.
static func _labels_clear(names: Array, table: Dictionary) -> bool:
	var labels: Array[Rect2] = []
	var dots: Array[Rect2] = []
	for p: Variant in names:
		var x := (float(table[p][1]) + 180.0) / 360.0 * 392.0
		var y := (90.0 - float(table[p][0])) / 180.0 * 196.0
		var tw := str(p).length() * 7.5
		var lx := x + 9.0 if x + 9.0 + tw < 392.0 else x - 9.0 - tw
		labels.append(Rect2(lx, y - 10.0, tw, 14.0))
		dots.append(Rect2(x - 6.0, y - 6.0, 12.0, 12.0))
	for i in labels.size():
		for j in labels.size():
			if i != j and (labels[i].grow(2.0).intersects(labels[j]) or labels[i].grow(1.0).intersects(dots[j])):
				return false
	return true


# --- Geography: a map in layers (g6.geography.maps_with_layers) -------------------------------------------------------

## A town's layers (layer_map): a river, its flood zone, houses and schools. Level 1: how many houses; level 2: how many
## houses are in the flood zone; level 3: how many schools and houses are outside it, or which layers answer a question.
static func layer_query(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := 8
	var h := 5
	var river: Array[Vector2i] = []
	var x := rng.randi_range(1, w - 3)
	for y in h:
		river.append(Vector2i(x, y))
		if rng.randf() < 0.5:
			river.append(Vector2i(x + 1, y))
		x = clampi(x + rng.randi_range(-1, 1), 0, w - 2)
	var flood: Array[Vector2i] = []
	for c: Vector2i in river:
		for dx: int in [-1, 0, 1]:
			var f := Vector2i(clampi(c.x + dx, 0, w - 1), c.y)
			if not flood.has(f):
				flood.append(f)
	var free: Array[Vector2i] = []
	for y in h:
		for xx in w:
			if not river.has(Vector2i(xx, y)):
				free.append(Vector2i(xx, y))
	GenKit.shuffle(rng, free)
	var houses: Array[Vector2i] = []
	for c: Vector2i in free.slice(0, rng.randi_range(6, 10)):
		houses.append(c)
	var schools: Array[Vector2i] = []
	for c: Vector2i in free.slice(10, 10 + rng.randi_range(1, 3)):
		schools.append(c)
	var layers: Array = [{"name": "river", "what": "water", "cells": _cells(river, w, h)},
		{"name": "flood zone", "what": "flood", "cells": _cells(flood, w, h)},
		{"name": "houses", "what": "houses", "cells": _cells(houses, w, h)}]
	if level == 3:
		layers.append({"name": "schools", "what": "schools", "cells": _cells(schools, w, h)})
	var picture := {"kind": "layer_map", "w": w, "h": h, "layers": layers}
	var wet := houses.filter(func(c: Vector2i) -> bool: return flood.has(c)).size()
	var ex: Dictionary
	if level == 1:
		ex = K.number("This map has three layers switched on. How many houses does it show?", str(houses.size()),
			"Find the houses' symbol in the key, then count every one on the map.",
			"There are %d house symbols." % houses.size(), picture)
		ex.data = {"ask": "houses"}
	elif level == 2:
		ex = K.number("The flood zone layer shows where the river may flood. How many houses are inside the flood zone?",
			str(wet), "Look only at the shaded flood zone and count the houses on it.",
			"%d house%s %s on the flood zone; the other %d %s outside it." % [wet, "" if wet == 1 else "s",
				"is" if wet == 1 else "are", houses.size() - wet, "is" if houses.size() - wet == 1 else "are"], picture)
		ex.data = {"ask": "flooded"}
	elif rng.randf() < 0.6:
		var dry := houses.size() - wet + schools.filter(func(c: Vector2i) -> bool: return not flood.has(c)).size()
		ex = K.number("How many buildings (houses and schools together) are outside the flood zone?", str(dry),
			"Count the houses and the schools that are not on the shaded flood zone.",
			"Houses outside: %d. Schools outside: %d. %d + %d = %d." % [houses.size() - wet, dry - (houses.size() - wet),
				houses.size() - wet, dry - (houses.size() - wet), dry], picture)
		ex.data = {"ask": "dry"}
	else:
		ex = K.choice(rng, "A town wants to know which schools could flood. Which two layers must it switch on together?",
			"schools and flood zone", ["houses and river", "roads and parks", "schools and houses"],
			"Which layer shows the schools, and which shows where floods can reach?",
			"The schools layer over the flood zone layer shows which schools are on land that can flood.", picture)
		ex.data = {"ask": "layers"}
	return ex


# --- Citizenship: government (g6.citizenship.how_a_country_is_run) ----------------------------------------------------

## Level 1: sort four jobs into making, carrying out and judging laws; level 2: six; level 3: which part of government
## acts in a case.
static func branch_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hint := "Parliament makes the laws, the government carries them out, and the courts judge what they mean and who broke them."
	if level == 3:
		var case: String = BRANCH_CASES.keys()[rng.randi_range(0, BRANCH_CASES.size() - 1)]
		var b := int(BRANCH_CASES[case])
		var ex := K.choice(rng, "%s Which part of government is at work?" % case, BRANCH_NAMES[b],
			BRANCH_NAMES.filter(func(x: String) -> bool: return x != BRANCH_NAMES[b]), hint,
			"That is %s: it %s." % [BRANCH_NAMES[b], BRANCHES[b]])
		ex.data = {"ask": "case", "case": case}
		return ex
	var per: Array[int] = [2, 1, 1]
	if level != 1:
		per = [2, 2, 2]
	GenKit.shuffle(rng, per)
	var items: Array = []
	var said: Array[String] = []
	for b in 3:
		var pool: Array[String] = []
		for j: String in BRANCH_JOBS:
			if int(BRANCH_JOBS[j]) == b:
				pool.append(j)
		var some := _pick(rng, pool, per[b])
		items.append_array(some)
		said.append("%s: %s" % [_cap(BRANCHES[b]), ", ".join(some)])
	GenKit.shuffle(rng, items)
	var ex := {"type": "sort", "prompt": "Sort these jobs: which part of government does each?", "groups": BRANCHES,
		"items": items, "answer": items.map(func(it: String) -> int: return int(BRANCH_JOBS[it])), "hint": hint,
		"explain": "%s." % ". ".join(said)}
	ex.data = {"ask": "sort"}
	return ex


## Elections by the most votes in each area (made-up parties: Oak, River and Sun). Level 1: an area's winner from its
## votes; level 2: how many of five areas a party won; level 3: the seats a majority needs.
static func seat_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var votes := _votes(rng)
		var win := _winner(votes)
		var rows: Array = [["Party", "Votes"]]
		for i in 3:
			rows.append([PARTIES[i], K.fmt(votes[i])])
		ex = K.choice(rng, "Here are the votes in one area. Whoever gets the most votes wins the area's seat. Who wins?",
			"the %s Party" % PARTIES[win], PARTIES.filter(func(p: String) -> bool: return p != PARTIES[win]).map(
				func(p: String) -> String: return "the %s Party" % p), "Compare the votes: the biggest number wins, even if it is less than half.",
			"The %s Party has the most votes, %s, so it wins the seat." % [PARTIES[win], K.fmt(votes[win])],
			{"kind": "table", "rows": rows})
		ex.data = {"ask": "winner", "votes": votes}
		return ex
	if level == 2:
		var rows: Array = [["Area", "Oak", "River", "Sun"]]
		var all: Array = []
		for a in 5:
			var votes := _votes(rng)
			all.append(votes)
			rows.append([AREAS[a], K.fmt(votes[0]), K.fmt(votes[1]), K.fmt(votes[2])])
		var party := rng.randi_range(0, 2)
		var won: Array[String] = []
		for a in 5:
			if _winner(all[a]) == party:
				won.append(AREAS[a])
		ex = K.number("Five areas each elect one member. Whoever gets the most votes in an area wins its seat. How many seats does the %s Party win?" % PARTIES[party],
			str(won.size()), "Go area by area: find the biggest number in each row, then count the rows the party won.",
			("The %s Party wins %s: %d seat%s." % [PARTIES[party], ", ".join(won), won.size(), "" if won.size() == 1 else "s"])
			if won.size() > 0 else "The %s Party does not have the most votes in any area: 0 seats." % PARTIES[party],
			{"kind": "table", "rows": rows})
		ex.data = {"ask": "seats", "votes": all, "party": party}
		return ex
	var seats := rng.randi_range(40, 700)
	ex = K.number("A parliament has %d seats. A majority is more than half of them. What is the fewest seats one party needs for a majority?" % seats,
		str(seats / 2 + 1), "Find half of the seats; a majority needs more than that.",
		("Half of %d is %d; one more is %d." % [seats, seats / 2, seats / 2 + 1]) if seats % 2 == 0 else
		("Half of %d is %d½; the next whole number is %d." % [seats, seats / 2, seats / 2 + 1]))
	ex.data = {"ask": "majority", "seats": seats}
	return ex


## Level 1: sort four things said into "helps us think" and "gets in the way"; level 2: six; level 3: name the mistake.
static func argue_well(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var hint := "A good argument is about the idea and its evidence; a poor one attacks the person, follows the crowd, twists words or stops listening."
	if level == 3:
		var said: String = MISTAKES.keys()[rng.randi_range(0, MISTAKES.size() - 1)]
		var right := str(MISTAKES[said])
		var ex := K.choice(rng, "Someone in a class debate says: \"%s\" What goes wrong here?" % said, right,
			MISTAKE_NAMES.filter(func(x: String) -> bool: return x != right), hint, "It is %s." % right)
		ex.data = {"ask": "mistake", "said": said}
		return ex
	var n := 4 if level == 1 else 6
	var good := rng.randi_range(1, 3) if level == 1 else rng.randi_range(2, 4)
	var ones := _pick(rng, HELPS, good)
	var bad_pool: Array[String] = []
	for k: String in MISTAKES:
		bad_pool.append(k)
	var twos := _pick(rng, bad_pool, n - good)
	var items: Array = ones + twos
	GenKit.shuffle(rng, items)
	var groups: Array[String] = ["helps us think", "gets in the way"]
	var ex := {"type": "sort", "prompt": "In a class debate, which of these help everyone think, and which get in the way?",
		"groups": groups, "items": items, "answer": items.map(func(it: String) -> int: return 0 if ones.has(it) else 1),
		"hint": hint, "explain": "Gets in the way: %s The rest help." % " ".join(twos)}
	ex.data = {"ask": "sort"}
	return ex


# --- Citizenship: money (income_tax, compound_interest, risk_protection) -----------------------------------------------

## Level 1: pay take away the tax on a payslip; level 2: no tax on the first part of pay, then a rate; level 3: two
## rates above the tax-free part.
static func take_home_pay(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := PEOPLE[rng.randi_range(0, 3)]
	var ex: Dictionary
	if level == 1:
		var gross := rng.randi_range(20, 90) * 10
		var tax := rng.randi_range(2, gross / 40) * 10
		ex = K.number("%s earns %d gold a month before tax (gross pay). The payslip shows %d gold taken off for tax. What is the take-home pay?" % [
			who, gross, tax], str(gross - tax), "Take-home (net) pay is gross pay take away what is taken off.",
			"%d − %d = %d gold." % [gross, tax, gross - tax])
		ex.data = {"ask": "net", "gross": gross, "tax": tax}
		return ex
	var free: int = [100, 200, 300][rng.randi_range(0, 2)]
	if level == 2:
		var rate: int = [10, 20][rng.randi_range(0, 1)]
		var above := rng.randi_range(1, 40) * 10
		var tax := above * rate / 100
		ex = K.number("No tax is paid on the first %d gold of a month's pay; above that, the tax is %d%%. %s earns %d gold. What is %s take-home pay?" % [
			free, rate, who, free + above, "her" if who != "Bram" else "his"], str(free + above - tax),
			"Find the pay above the tax-free part, work out the tax on that part only, then take it off.",
			"%d − %d = %d gold is taxed. %d%% of %d = %d. %d − %d = %d gold." % [free + above, free, above, rate, above, tax,
				free + above, tax, free + above - tax])
		ex.data = {"ask": "net", "free": free, "rate": rate, "gross": free + above}
		return ex
	var band := free + rng.randi_range(2, 6) * 100
	var over := rng.randi_range(1, 20) * 10
	var gross := band + over
	var tax := (band - free) * 20 / 100 + over * 40 / 100
	ex = K.number("Pay up to %d gold a month is tax-free. Pay from %d to %d gold is taxed at 20%%, and pay above %d gold at 40%%. %s earns %d gold. What is the take-home pay?" % [
		free, free, band, band, who, gross], str(gross - tax),
		"Split the pay into its parts; work out each part's tax, add them, then take the tax from the pay.",
		"20%% of %d = %d. 40%% of %d = %d. Tax: %d. %d − %d = %d gold." % [band - free, (band - free) / 5, over, over * 2 / 5,
			tax, gross, tax, gross - tax])
	ex.data = {"ask": "bands", "free": free, "band": band, "gross": gross}
	return ex


## Level 1: a year's interest; level 2: savings after 2 years of compound interest (savings_growth picture); level 3:
## after 3 years at 10%, or how much more than simple interest after 2 years.
static func compound_growth(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := PEOPLE[rng.randi_range(0, 3)]
	var hint := "Compound interest: each year, find the interest on everything in the account, then add it before the next year."
	var ex: Dictionary
	if level == 1:
		var start := rng.randi_range(1, 20) * 100
		var rate := rng.randi_range(2, 10)
		ex = K.number("%s saves %s gold at %d%% interest a year. How much interest is added after the first year?" % [who,
			K.fmt(start), rate], str(start * rate / 100), "Per cent means for every hundred: find the gold for each 100.",
			"%s gold is %d hundreds. %d × %d = %d gold." % [K.fmt(start), start / 100, start / 100, rate, start * rate / 100])
		ex.data = {"ask": "first", "start": start, "rate": rate}
		return ex
	if level == 2:
		var plans: Array = [[10, 100], [5, 400], [20, 25]]
		var plan: Array = plans[rng.randi_range(0, 2)]
		var rate := int(plan[0])
		var start := int(plan[1]) * rng.randi_range(1, 20)
		var one := start + start * rate / 100
		var two := one + one * rate / 100
		ex = K.number("%s saves %s gold at %d%% compound interest a year. How much is in the account after 2 years?" % [who,
			K.fmt(start), rate], str(two), hint,
			"Year 1: %d%% of %s = %s, so %s. Year 2: %d%% of %s = %s, so %s gold." % [rate, K.fmt(start), K.fmt(one - start),
				K.fmt(one), rate, K.fmt(one), K.fmt(two - one), K.fmt(two)],
			{"kind": "savings_growth", "start": start, "rate": rate, "years": 2})
		ex.data = {"ask": "after", "start": start, "rate": rate, "years": 2}
		return ex
	if rng.randf() < 0.5:
		var start := rng.randi_range(1, 9) * 1000
		var one := start + start / 10
		var two := one + one / 10
		var three := two + two / 10
		ex = K.number("%s saves %s gold at 10%% compound interest a year. How much is in the account after 3 years?" % [who,
			K.fmt(start)], str(three), hint, "%s, then %s, then %s, then %s gold." % [K.fmt(start), K.fmt(one), K.fmt(two),
				K.fmt(three)], {"kind": "savings_growth", "start": start, "rate": 10, "years": 3})
		ex.data = {"ask": "after", "start": start, "rate": 10, "years": 3}
		return ex
	var start := rng.randi_range(1, 30) * 100
	var rate: int = [10, 20][rng.randi_range(0, 1)]
	var simple := start + 2 * start * rate / 100
	var one := start + start * rate / 100
	var two := one + one * rate / 100
	ex = K.number("%s gold is saved for 2 years at %d%% a year. How much more does compound interest give than simple interest?" % [
		K.fmt(start), rate], str(two - simple), "Work out both: simple pays on the first savings only; compound pays on the interest too.",
		"Simple: %s + 2 × %s = %s. Compound: %s, then %s. %s − %s = %s gold." % [K.fmt(start), K.fmt(start * rate / 100),
			K.fmt(simple), K.fmt(one), K.fmt(two), K.fmt(two), K.fmt(simple), K.fmt(two - simple)],
		{"kind": "savings_growth", "start": start, "rate": rate, "years": 2, "simple": true})
	ex.data = {"ask": "more", "start": start, "rate": rate}
	return ex


## Level 1: a year of insurance from its monthly cost; level 2: a shared pot after claims; level 3: all you pay over some
## years, with one claim's excess.
static func insurance_pool(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := PEOPLE[rng.randi_range(0, 3)]
	var ex: Dictionary
	if level == 1:
		var monthly := rng.randi_range(2, 15)
		ex = K.number("%s's bike insurance costs %d gold a month. How much is that for a year?" % [who, monthly],
			str(12 * monthly), "There are 12 months in a year.", "12 × %d = %d gold." % [monthly, 12 * monthly])
		ex.data = {"ask": "year", "monthly": monthly}
		return ex
	if level == 2:
		var members := rng.randi_range(20, 100)
		var pay := rng.randi_range(5, 20)
		var cost := rng.randi_range(4, 30) * 10
		if cost * 2 > members * pay:
			cost = members * pay / 20 * 10   # at most half the pot
		var claims := rng.randi_range(1, maxi(1, members * pay / cost - 1))
		ex = K.number("In a bike club, %d members each pay %d gold a year into a shared pot. This year %d bike%s stolen, and the pot paid %d gold for each. How much is left in the pot?" % [
			members, pay, claims, " was" if claims == 1 else "s were", cost], str(members * pay - claims * cost),
			"Find what went into the pot, then take away what it paid out.",
			"%d × %d = %d in. %d × %d = %d out. %d − %d = %d gold." % [members, pay, members * pay, claims, cost, claims * cost,
				members * pay, claims * cost, members * pay - claims * cost])
		ex.data = {"ask": "pot", "members": members, "pay": pay, "claims": claims, "cost": cost}
		return ex
	var yearly := rng.randi_range(3, 20) * 5
	var excess := rng.randi_range(1, 10) * 10
	var years := rng.randi_range(2, 5)
	ex = K.number("Home insurance costs %d gold a year. When you claim, you pay the first %d gold yourself (the excess). Over %d years you claim once. How much do you pay in all?" % [
		yearly, excess, years], str(years * yearly + excess), "Add every year's cost, then the excess for the one claim.",
		"%d × %d = %d. %d + %d = %d gold." % [years, yearly, years * yearly, years * yearly, excess, years * yearly + excess])
	ex.data = {"ask": "total", "yearly": yearly, "excess": excess, "years": years}
	return ex


## Level 1: sort four into warning signs and safe things to do; level 2: six; level 3: what to do about a message.
static func scam_signs(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 3:
		var case := SCAM_CASES[rng.randi_range(0, SCAM_CASES.size() - 1)]
		var ex := K.choice(rng, "%s What should you do?" % case, SCAM_RIGHT, _pick(rng, SCAM_WRONGS, 3),
			"Stop and think: does it rush you, offer something too good, or ask for secret details?",
			"It is a scam's trick. Don't reply or click, tell a grown-up you trust, and report it.")
		ex.data = {"ask": "case"}
		return ex
	var n := 4 if level == 1 else 6
	var a := rng.randi_range(1, n - 1)
	var ones := _pick(rng, SIGNS, a)
	var twos := _pick(rng, SAFE, n - a)
	var items: Array = ones + twos
	GenKit.shuffle(rng, items)
	var groups: Array[String] = ["warning sign", "safe thing to do"]
	var ex := {"type": "sort", "prompt": "Sort these: a scam's warning sign, or a safe thing to do?", "groups": groups,
		"items": items, "answer": items.map(func(it: String) -> int: return 0 if ones.has(it) else 1),
		"hint": "Scams rush you, offer too much, and ask for secrets; safe habits slow down and get help.",
		"explain": "Warning signs: %s. Safe: %s." % [", ".join(ones), ", ".join(twos)]}
	ex.data = {"ask": "sort"}
	return ex


## A week's footprint points in a table. Level 1: the total; level 2: the points saved by a swap; level 3: the swap's
## saving as a percentage of the total.
static func footprint(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := PEOPLE[rng.randi_range(0, 3)]
	var ex: Dictionary
	for _try in 400:
		var swap: Array = SWAPS[rng.randi_range(0, SWAPS.size() - 1)]
		var others: Array = []   # the rest of the week, with no second school trip beside a trip being swapped
		for a: String in ACTS:
			if a != str(swap[0]) and a != str(swap[1]) and not (str(swap[0]).contains("trip") and a.contains("trip")):
				others.append(a)
		var acts: Array = [str(swap[0])] + _pick_any(rng, others, 2)
		var counts: Array[int] = []
		var total := 0
		for a: String in acts:
			var c := rng.randi_range(1, 5)
			counts.append(c)
			total += c * int(ACTS[a])
		var rows: Array = [["This week", "Times", "Points each"]]
		for i in 3:
			rows.append([acts[i], str(counts[i]), str(ACTS[acts[i]])])
		var picture := {"kind": "table", "rows": rows}
		var each := int(ACTS[str(swap[0])]) - int(swap[2])
		var saved := counts[0] * each
		if level == 1:
			var parts: Array[String] = []
			for i in 3:
				parts.append("%d × %d" % [counts[i], int(ACTS[acts[i]])])
			ex = K.number("%s's week of footprint points is in the table. What is the total?" % who, str(total),
				"Multiply each row's times by its points, then add the rows.", "%s = %d points." % [" + ".join(parts), total],
				picture)
			ex.data = {"ask": "total", "acts": acts, "counts": counts}
			return ex
		if level == 2:
			ex = K.number("Next week %s swaps every %s for a %s (%d point%s each). How many points does that save?" % [who,
				swap[0], swap[1], int(swap[2]), "" if int(swap[2]) == 1 else "s"], str(saved),
				"Each swap saves the difference in points; multiply by the times.",
				"Each swap saves %d − %d = %d. %d × %d = %d points." % [int(ACTS[str(swap[0])]), int(swap[2]), each, counts[0],
					each, saved], picture)
			ex.data = {"ask": "saved", "acts": acts, "counts": counts, "swap": swap}
			return ex
		if saved * 100 % total == 0 and saved < total:
			ex = K.number("%s swaps every %s for a %s (%d point%s each). By what percentage does the week's total fall?" % [who,
				swap[0], swap[1], int(swap[2]), "" if int(swap[2]) == 1 else "s"], str(saved * 100 / total),
				"Find the total and the points saved, then how many hundredths of the total the saving is.",
				"Total: %d. Saved: %d × %d = %d. %d ÷ %d = %d%%." % [total, counts[0], each, saved, saved, total,
					saved * 100 / total], picture)
			ex.data = {"ask": "percent", "acts": acts, "counts": counts, "swap": swap}
			return ex
	# no whole percentage after many tries: the points saved instead (level 2's question)
	return footprint(rng, 2)


# --- Helpers ------------------------------------------------------------------------------------------------------------

## "1st", "2nd", "3rd", "11th", "13th", "21st".
static func _ordinal(n: int) -> String:
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = str({1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th"))
	return "%d%s" % [n, suffix]


## A year as the lessons write it: "1066", "about 820".
static func _year_text(y: int, about: bool) -> String:
	return ("about %d" % y) if about else str(y)


## A whole number from lo to hi that does not end in 00.
static func _not_hundred(rng: RandomNumberGenerator, lo: int, hi: int) -> int:
	var y := rng.randi_range(lo, hi)
	while y % 100 == 0:
		y = rng.randi_range(lo, hi)
	return y


static func _crop_words(crop: String) -> String:
	return "resting" if crop == CROPS[2] else crop


## A quipu cord's places in words: "3 single knots for 300, no knots for the tens, a long knot of 4 turns for 4".
static func _quipu_words(digits: Array[int]) -> String:
	var parts: Array[String] = []
	var worth: Array[int] = [1000, 100, 10, 1]
	var started := false
	for i in 4:
		var d := digits[i]
		started = started or d > 0
		if not started:
			continue
		var knot := SchoolPictureG6Hum.knot_kind(d, i == 3)
		match knot:
			"none":
				parts.append("no knots for the %s" % ["thousands", "hundreds", "tens", "ones"][i])
			"single":
				parts.append("%d single knot%s for %s" % [d, "" if d == 1 else "s", K.fmt(d * worth[i])])
			"eight":
				parts.append("a figure-of-eight knot for 1")
			_:
				parts.append("a long knot of %d turns for %d" % [d, d])
	return _cap(", ".join(parts))


## Places on a 4 × 2 map, in tenths, apart from each other and off the grid lines.
static func _map_spots(rng: RandomNumberGenerator, e0: int, n0: int, count: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for _try in 500:
		if out.size() == count:
			break
		var p := Vector2i(e0 * 10 + rng.randi_range(3, 37), n0 * 10 + rng.randi_range(3, 17))
		if p.x % 10 == 0 or p.y % 10 == 0:
			continue
		var ok := true
		for q in out:
			ok = ok and (absi(p.x - q.x) >= 6 or absi(p.y - q.y) >= 6)
		if ok:
			out.append(p)
	while out.size() < count:   # a fallback grid (never needed with 500 tries)
		out.append(Vector2i(e0 * 10 + 4 + out.size() % 4 * 10, n0 * 10 + 4 + out.size() / 4 * 10))
	return out


static func _pick_symbols(rng: RandomNumberGenerator, count: int) -> Array[String]:
	var all: Array[String] = []
	for k: String in SYMBOL_WORDS:
		all.append(k)
	return _pick(rng, all, count)


## `cells` as a layer's rows of "#" and ".".
static func _cells(cells: Array[Vector2i], w: int, h: int) -> Array:
	var rows: Array = []
	for y in h:
		var row := ""
		for x in w:
			row += "#" if cells.has(Vector2i(x, y)) else "."
		rows.append(row)
	return rows


## Three parties' votes in an area, with one clear winner.
static func _votes(rng: RandomNumberGenerator) -> Array[int]:
	var v: Array[int] = []
	for _try in 50:
		v = [rng.randi_range(100, 999), rng.randi_range(100, 999), rng.randi_range(100, 999)]
		if v[0] != v[1] and v[1] != v[2] and v[0] != v[2]:
			break
	if v[0] == v[1] or v[1] == v[2] or v[0] == v[2]:
		v = [410, 380, 290]
	return v


static func _winner(votes: Array) -> int:
	var best := 0
	for i in 3:
		if int(votes[i]) > int(votes[best]):
			best = i
	return best


## One month on top: a tie for the biggest value is broken by one more for the first of them.
static func _unique_top(values: Array[int]) -> void:
	var top := values.max() as int
	if values.count(top) > 1:
		values[values.find(top)] = top + 1


## The climate graph's scales: temperature from a multiple of 5 (or 10) below the coldest to one above the warmest, and
## rain with as many steps.
static func _climate_scale(temp: Array[int], rain: Array[int]) -> Dictionary:
	var t_step := 5 if temp.max() - temp.min() <= 30 else 10
	var t_from := int(floor(mini(0, temp.min()) / float(t_step))) * t_step
	var t_top := int(ceil(temp.max() / float(t_step))) * t_step
	if t_top == temp.max():
		t_top += t_step
	while (t_top - t_from) / t_step < 3:
		t_top += t_step
	for _grow in 12:
		var steps := (t_top - t_from) / t_step
		for r in RAIN_STEPS:
			if steps * r >= rain.max():
				return {"t_from": t_from, "t_top": t_top, "t_step": t_step, "r_top": steps * r, "r_step": r}
		t_top += t_step
	return {"t_from": t_from, "t_top": t_top, "t_step": t_step, "r_top": 2000, "r_step": 200}


## "−6" for a temperature below 0.
static func _signed(v: int) -> String:
	return ("−%d" % -v) if v < 0 else str(v)


static func _climate_why(kind: String) -> String:
	match kind:
		"temperate":
			return "Temperate: mild, with rain all year and no very hot or very cold months"
		"tropical rainforest":
			return "Tropical rainforest: hot all year (about 26-27 °C) and wet every month"
		"monsoon":
			return "Monsoon: hot all year, very dry for months, then very wet in the rainy season"
		"hot desert":
			return "Hot desert: hot summers and almost no rain all year"
	return "Cold continental: a winter below 0 °C, a warm summer, and more rain in summer"


static func _sector_why(s: int) -> String:
	return ["takes from nature", "makes things", "serves people", "finds out new things and invents"][s]


static func _half(n: int) -> String:
	return str(n / 2) if n % 2 == 0 else "%d.5" % (n / 2)


## "maize" -> "Maize".
static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


## `count` different words from `list`, in a seeded order.
static func _pick(rng: RandomNumberGenerator, list: Array[String], count: int) -> Array[String]:
	var all: Array = list.duplicate()
	GenKit.shuffle(rng, all)
	var out: Array[String] = []
	for w: Variant in all.slice(0, count):
		out.append(str(w))
	return out


## `count` different entries of `list`, in a seeded order.
static func _pick_any(rng: RandomNumberGenerator, list: Array, count: int) -> Array:
	var all: Array = list.duplicate()
	GenKit.shuffle(rng, all)
	return all.slice(0, count)
