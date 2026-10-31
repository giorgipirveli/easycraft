class_name G5HumanitiesGen
extends RefCounted
## Owner #70 and #73 (research §6.5): grade 5 history, geography and citizenship generators: the Olympic Games counted
## in BC fours; the classical world's dated events (years apart across BC and AD, with no year 0, and in order on a
## timeline); Roman numerals on stones and Maya numbers of dots, bars and shells; places on the world's grid of latitude
## and longitude, and the hemispheres of real cities; time zones (January's hours ahead of or behind London, and 15° of
## longitude for each hour); temperatures up a mountain (about 6.5 °C colder for every 1,000 m); renewable and
## non-renewable resources, fuels, ores and things from living things; an atlas's index (pages, squares, latitudes);
## trade by sea (exports and imports, containers, voyages); and citizenship's numbers in the game's gold: an election's
## results and turnout, a budget (needs, then saving, then wants), simple interest, the cost of borrowing, and a class's
## rubbish before and after. SchoolGen "g5h.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) ->
## Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for
## tests/unit/test_g5_humanities_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE := {"Tilly": ["she", "her"], "Zara": ["she", "her"], "Bram": ["he", "his"], "Mimi": ["she", "her"]}
const ORDINALS := {2: "second", 3: "third", 4: "fourth", 5: "fifth"}

## The classical world's dated events, as the lessons give them: [what happened, the year (BC below 0), about?].
const EVENTS: Array = [
	["The first Olympic Games", -776, false],
	["Rome is founded, says the legend", -753, false],
	["Cyrus founds the Persian Empire", -550, true],
	["Rome becomes a republic", -509, false],
	["Democracy begins in Athens", -508, true],
	["The Battle of Marathon", -490, false],
	["Building of the Parthenon begins", -447, false],
	["Alexander the Great takes Persepolis", -330, false],
	["The Maurya Empire begins", -321, true],
	["Ashoka becomes emperor", -268, true],
	["The Han dynasty begins", -206, false],
	["Zhang Qian sets out to the west", -138, true],
	["Julius Caesar lands in Britain", -55, false],
	["Augustus becomes Rome's first emperor", -27, false],
	["The Romans invade Britain", 43, false],
	["Boudica's revolt", 60, true],
	["Vesuvius buries Pompeii", 79, false],
	["The Colosseum opens", 80, false],
	["Cai Lun shows paper to the emperor", 105, false],
	["Building of Hadrian's Wall begins", 122, false],
	["The Maya Classic Period begins", 250, true],
	["The Romans leave Britain", 410, true],
	["The Western Roman Empire ends", 476, false],
	["Aryabhata writes his maths book", 499, false],
	["Brahmagupta writes rules for zero", 628, false],
	["Many Maya cities are left empty", 900, true],
]
const ROMAN: Array = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"],
	[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
## Hours ahead of London (+) or behind it (−) in January (standard time; summer time moves some of them).
const ZONES := {"Paris": 1, "Rome": 1, "Lagos": 1, "Cairo": 2, "Athens": 2, "Nairobi": 3, "Dubai": 4, "Karachi": 5,
	"Dhaka": 6, "Bangkok": 7, "Beijing": 8, "Singapore": 8, "Tokyo": 9, "Brisbane": 10, "Honolulu": -10,
	"Los Angeles": -8, "Denver": -7, "Chicago": -6, "Mexico City": -6, "New York": -5, "Lima": -5, "Buenos Aires": -3,
	"Rio de Janeiro": -3}
## Real cities to the nearest degree: [latitude (N +), longitude (E +)].
const CITIES := {"Quito": [0, -78], "Singapore": [1, 104], "Cairo": [30, 31], "Sydney": [-34, 151],
	"Rio de Janeiro": [-23, -43], "Nairobi": [-1, 37], "Tokyo": [36, 140], "New York": [41, -74], "Reykjavik": [64, -22],
	"Cape Town": [-34, 18], "Buenos Aires": [-35, -58], "Mumbai": [19, 73], "Lima": [-12, -77], "Oslo": [60, 11],
	"Perth": [-32, 116], "Vancouver": [49, -123], "Mexico City": [19, -99], "Beijing": [40, 116], "Honolulu": [21, -158],
	"Madrid": [40, -4], "Anchorage": [61, -150], "Accra": [6, 0], "Auckland": [-37, 175]}
const RENEWABLE_EASY: Array[String] = ["sunlight", "wind", "rain", "waves"]
const RENEWABLE_MORE: Array[String] = ["tides", "flowing river water", "heat from deep underground",
	"wood from replanted forests", "crops such as wheat", "fish, if not overfished"]
const NON_RENEWABLE_EASY: Array[String] = ["coal", "oil", "natural gas"]
const NON_RENEWABLE_MORE: Array[String] = ["iron ore", "copper ore", "gold", "uranium", "diamonds"]
const FOSSIL: Array[String] = ["coal", "oil", "natural gas"]
const ORES: Array[String] = ["iron ore", "copper ore", "tin ore", "aluminium ore"]
const LIVING: Array[String] = ["wood", "cotton", "wool", "rubber", "fish", "leather"]
## Places an atlas's index lists (its own pages and squares are made up for each atlas).
const ATLAS_PLACES: Array[String] = ["Accra", "Beijing", "Cairo", "Dublin", "Lima", "Madrid", "Mumbai", "Nairobi",
	"Oslo", "Perth", "Quito", "Rome", "Tokyo", "Vancouver"]
const ISLANDS: Array[String] = ["Sunny Isle", "Pine Island", "Coral Key", "Misty Isle"]
const EXPORTS: Array[String] = ["fish", "wool", "fruit", "timber", "honey", "salt"]
const IMPORTS: Array[String] = ["tools", "cloth", "glass", "grain", "rope", "lamps"]
const CARGO: Array[String] = ["bananas", "books", "shoes", "lamps", "teapots", "toys"]


# --- History: the Greeks (g5.history.greek_daily_life) ----------------------------------------------------------------

## The first Olympic Games we know of were in 776 BC, then every 4 years. Level 1: the year of the 2nd-5th Games; level
## 2: of later Games; level 3: which Games were held in a year, or how many Games from 776 BC to a year, counting both.
static func olympiad(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var head := "The first Olympic Games we know of were held at Olympia in 776 BC, then every 4 years. "
	var ex: Dictionary
	if level < 3:
		var n := rng.randi_range(2, 5) if level == 1 else rng.randi_range(6, 30)
		var y := 776 - 4 * (n - 1)
		ex = K.number(head + "In what year BC were the %s Games?" % _ordinal(n), str(y),
			"BC years count down towards AD 1. Take away 4 years for each Games after the first.",
			"The %s Games were %d × 4 = %d years after the first. 776 − %d = %d, so %d BC." % [_ordinal(n), n - 1,
				4 * (n - 1), 4 * (n - 1), y, y])
		ex.data = {"ask": "year", "n": n}
		return ex
	var k := rng.randi_range(4, 29)
	var y := 776 - 4 * k
	if rng.randf() < 0.5:
		ex = K.number(head + "Which Games were held in %d BC? Type 1 for the first Games, 2 for the second, and so on." % y,
			str(k + 1), "Find how many years after 776 BC it was, then how many lots of 4 years. Do not forget the first Games.",
			"776 − %d = %d years after the first Games. %d ÷ 4 = %d more Games, so these were Games number %d + 1 = %d." % [y,
				4 * k, 4 * k, k, k, k + 1])
		ex.data = {"ask": "games", "year": y}
	else:
		ex = K.number(head + "How many Games were held from 776 BC to %d BC, counting both?" % y, str(k + 1),
			"Count the gaps of 4 years between the two years, then add 1 for the first Games.",
			"776 − %d = %d years. %d ÷ 4 = %d gaps of 4 years. %d gaps join %d + 1 = %d Games." % [y, 4 * k, 4 * k, k, k, k,
				k + 1])
		ex.data = {"ask": "count", "year": y}
	return ex


# --- History: timelines (g5.history.rome_republic_empire, classical_legacy) --------------------------------------------

## "How many years apart are they?" Level 1: two BC events (BC years count down); level 2: two AD events, or two BC
## events; level 3: a BC event and an AD event, exactly (1 BC is followed by AD 1: there is no year 0).
static func classical_years(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = EVENTS.filter(func(e: Array) -> bool: return int(e[1]) < 0)
	if level == 2 and rng.randf() < 0.6:
		pool = EVENTS.filter(func(e: Array) -> bool: return int(e[1]) > 0)
	var two: Array = []
	if level == 3:
		var exact: Array = EVENTS.filter(func(e: Array) -> bool: return not bool(e[2]))
		var bc: Array = exact.filter(func(e: Array) -> bool: return int(e[1]) < 0)
		var ad: Array = exact.filter(func(e: Array) -> bool: return int(e[1]) > 0)
		two = [bc[rng.randi_range(0, bc.size() - 1)], ad[rng.randi_range(0, ad.size() - 1)]]
	else:
		two = _pick_any(rng, pool, 2)
		two.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
	var a := int(two[0][1])
	var b := int(two[1][1])
	var prompt := "%s: %s. %s: %s. How many years apart are they?" % [two[0][0], _year_text(a, bool(two[0][2])),
		two[1][0], _year_text(b, bool(two[1][2]))]
	var ex: Dictionary
	if b < 0:
		ex = K.number(prompt, str(b - a), "BC years count down towards AD 1: take the smaller BC number from the bigger one.",
			"BC years count down: %d − %d = %d years." % [-a, -b, b - a])
	elif a > 0:
		ex = K.number(prompt, str(b - a), "AD years count up, like our years today: take the earlier year from the later one.",
			"AD years count up: %d − %d = %d years." % [b, a, b - a])
	else:
		ex = K.number(prompt + " Remember: there is no year 0.", str(b - a - 1),
			"Count the years up to AD 1, then the years after it. From 1 BC to AD 1 is just 1 year.",
			"From %d BC to AD 1 is %d years. From AD 1 to AD %d is %d more. %d + %d = %d years." % [-a, -a, b, b - 1, -a, b - 1,
				b - a - 1])
	ex.data = {"from": a, "to": b, "events": [str(two[0][0]), str(two[1][0])]}
	return ex


## "Put these events in order on a timeline, earliest first." Level 1: three events at least 150 years apart; level 2:
## four BC events; level 3: four events, BC and AD.
static func classical_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var picked: Array = []
	for _try in 300:
		var pool: Array = EVENTS if level != 2 else EVENTS.filter(func(e: Array) -> bool: return int(e[1]) < 0)
		picked = _pick_any(rng, pool, 3 if level == 1 else 4)
		picked.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
		var ok := true
		for k in range(1, picked.size()):
			var gap := int(picked[k][1]) - int(picked[k - 1][1])
			ok = ok and gap > 0 and (level != 1 or gap >= 150)
		if level == 3:
			ok = ok and int(picked[0][1]) < 0 and int(picked[-1][1]) > 0
		if ok:
			break
	var words: Array = []
	var years: Array[String] = []
	for e: Array in picked:
		words.append("%s (%s)" % [e[0], _year_text(int(e[1]), bool(e[2]))])
		years.append(_year_text(int(e[1]), false))
	var hint := "BC years count down to AD 1, so the biggest BC year is the earliest. Every AD year comes after every BC year."
	if int(picked[-1][1]) < 0:
		hint = "BC years count down to AD 1: the bigger the BC number, the longer ago it was."
	elif int(picked[0][1]) > 0:
		hint = "AD years count up, like ours: the smaller the AD number, the longer ago it was."
	var ex := K.order(rng, "Put these events in order on a timeline, earliest first.", words, hint,
		"Earliest first: %s." % ", ".join(years))
	ex.data = {"events": picked.map(func(e: Array) -> String: return str(e[0]))}
	return ex


# --- History: Roman numerals (g5.history.roman_life) ------------------------------------------------------------------

## Level 1: read a number to 39 on a milestone; level 2: 40-399, read or written (XL, XC, CD); level 3: a year from 1000
## to 2100 carved on a building, read or written.
static func roman_numeral(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(1, 39)
	if level == 2:
		n = rng.randi_range(40, 399)
	elif level == 3:
		n = rng.randi_range(1000, 2100)
	var r := _roman(n)
	var ex: Dictionary
	var parts := _roman_parts(n)
	var sum := "%s = %s = %d" % [r, " + ".join(parts.map(func(p: Array) -> String: return str(p[0]))),
		n] if parts.size() > 1 else "%s = %d" % [r, n]
	if level == 1 or rng.randf() < 0.5:
		var prompt := "A Roman milestone says the fort is %s miles away. What number is %s?" % [r, r]
		if level == 2:
			prompt = "A Roman fort's storeroom is marked %s. What number is it?" % r
		elif level == 3:
			prompt = "A building's stone shows the year it was built: %s. What year is it?" % r
		ex = K.number(prompt, str(n),
			"Split the numeral into parts, biggest first. A smaller letter before a bigger one is taken away: IV is 4, XL is 40, CM is 900.",
			"%s." % sum)
		if level == 3:
			ex.year = true   # "1850", not "1,850"
		ex.data = {"n": n, "ask": "read"}
		return ex
	var wrongs: Array = []
	var steps: Array[int] = [1, -1, 10, -10]
	if level == 3:
		steps = [1, -1, 10, 100, -100]
	for s in steps:
		if n + s >= 1:
			wrongs.append(_roman(n + s))
	var swapped := _swapped(r)
	if swapped != r:
		wrongs.push_front(swapped)
	ex = K.choice(rng, "Which is the usual way to write %d in Roman numerals?" % n if level == 2 else
		"A stonemason carves the year %d in Roman numerals. Which is right?" % n, r, wrongs.slice(0, 3),
		"Write the thousands, then the hundreds, the tens and the ones. 4s and 9s take away: IV, IX, XL, XC, CD, CM.",
		"%d is %s, so %s." % [n, " + ".join(parts.map(func(p: Array) -> String: return "%s (%d)" % [p[1], p[0]])), r])
	ex.data = {"n": n, "ask": "write"}
	return ex


# --- History: the Maya (g5.history.maya) ------------------------------------------------------------------------------

## Maya numbers in places of twenties (numerals picture). Level 1: one place, 1-19; level 2: two places (20s and ones,
## labelled), sometimes a shell for 0; level 3: three places (400s, 20s and ones), not labelled.
static func maya_number(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var v := rng.randi_range(1, 19)
	if level == 2:
		v = rng.randi_range(20, 399) if rng.randf() < 0.75 else 20 * rng.randi_range(1, 19)
	elif level == 3:
		v = rng.randi_range(400, 7999)
		if rng.randf() < 0.3:
			v = v / 400 * 400 + v % 20
	var places := SchoolPictureHistory.maya_places(v)
	var worths: Array[int] = [1]
	if places.size() == 2:
		worths = [20, 1]
	elif places.size() == 3:
		worths = [400, 20, 1]
	var names: Array[String] = ["It is"]
	if places.size() == 2:
		names = ["Top (20s)", "bottom (ones)"]
	elif places.size() == 3:
		names = ["Top (400s)", "middle (20s)", "bottom (ones)"]
	var said: Array[String] = []
	var sum: Array[String] = []
	for i in places.size():
		var digit := int(places[i])
		said.append("%s: %s = %d%s" % [names[i], _maya_words(digit), digit, "" if worths[i] == 1 else " × %s = %s" % [
			_digits(worths[i]), _digits(digit * worths[i])]])
		sum.append(_digits(digit * worths[i]))
	var hint := "A bar is 5 and a dot is 1. Count the bars and dots, then add."
	if level == 2:
		hint = "The top place counts twenties and the bottom place ones. Work out each place, times the top by 20, then add."
	elif level == 3:
		hint = "Three places: the top counts 400s (20 × 20), the middle 20s and the bottom ones. A shell is 0."
	var explain := "%s." % "; ".join(said)
	if places.size() > 1:
		explain += " %s = %s." % [" + ".join(sum), _digits(v)]
	elif v >= 5 and v % 5 > 0:
		explain = "%d bar%s (%d) and %d dot%s (%d): %d + %d = %d." % [v / 5, "" if v / 5 == 1 else "s", v / 5 * 5, v % 5,
			"" if v % 5 == 1 else "s", v % 5, v / 5 * 5, v % 5, v]
	else:
		explain = "%s: %d." % [_cap(_maya_words(v)), v]
	var ex := K.number("What number do these Maya dots, bars and shells show?" if level > 1 else
		"What number do these Maya dots and bars show?", str(v), hint, explain,
		{"kind": "numerals", "system": "maya", "value": v, "labels": level == 2})
	ex.data = {"value": v}
	return ex


# --- Geography: latitude and longitude (g5.geography.lat_long) --------------------------------------------------------

## Level 1: places A-D on a 30° grid: which place is at a latitude and longitude, or which is south of the Equator;
## level 2: a place's latitude or longitude (a 15° grid across); level 3: a real city's two hemispheres, or which city
## is nearest the Equator.
static func lat_long(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		if rng.randf() < 0.5:
			var cities: Array = CITIES.keys().filter(func(c: String) -> bool:
				return int(CITIES[c][0]) != 0 and int(CITIES[c][1]) != 0)
			var city := str(cities[rng.randi_range(0, cities.size() - 1)])
			var lat := int(CITIES[city][0])
			var lng := int(CITIES[city][1])
			var ns := "northern" if lat > 0 else "southern"
			var ew := "eastern" if lng > 0 else "western"
			var right := "%s and %s" % [ns, ew]
			var all: Array = ["northern and eastern", "northern and western", "southern and eastern", "southern and western"]
			ex = K.choice(rng, "%s is at about %s, %s. In which two hemispheres is it?" % [city, _lat_text(lat),
				_long_text(lng)], right, all.filter(func(x: String) -> bool: return x != right),
				"N or S tells you the side of the Equator; E or W tells you the side of the Prime Meridian.",
				"%s: %s. %s: %s. So %s is in the %s hemispheres." % [_lat_text(lat), "north of the Equator" if lat > 0 else
					"south of the Equator", _long_text(lng), "east of the Prime Meridian" if lng > 0 else "west of the Prime Meridian",
					city, right], {"kind": "latlong", "points": [{"lat": lat, "long": lng, "label": "?"}]})
			ex.data = {"ask": "hemispheres", "city": city}
			return ex
		var four: Array = []
		for _try in 100:
			four = _pick_any(rng, CITIES.keys(), 4)
			var seen := {}
			for c: String in four:
				seen[absi(int(CITIES[c][0]))] = true
			if seen.size() == 4:
				break
		var best := str(four[0])
		var said: Array[String] = []
		for c: String in four:
			said.append("%s %s" % [c, _lat_text(int(CITIES[c][0]))])
			if absi(int(CITIES[c][0])) < absi(int(CITIES[best][0])):
				best = c
		ex = K.choice(rng, "Which city is nearest the Equator? %s." % ", ".join(said), best,
			four.filter(func(c: String) -> bool: return c != best),
			"The Equator is 0°. N or S does not matter here: find the latitude with the smallest number of degrees.",
			"%s is only %s from the Equator, the smallest number of degrees." % [best, _lat_text(int(CITIES[best][0])).replace(
				"N", "").replace("S", "")])
		ex.data = {"ask": "nearest", "cities": four}
		return ex
	var lat_step := 30 if level == 1 else 15
	var labels: Array[String] = ["A", "B", "C", "D"]
	var named: Array = labels.duplicate()   # the letters in a seeded order, so the answer is not always A
	GenKit.shuffle(rng, named)
	var south := level == 1 and rng.randf() < 0.5
	var points: Array = []
	var used := {}
	for i in 4:
		for _try in 100:
			var lat := lat_step * rng.randi_range(-2 if level == 1 else -5, 2 if level == 1 else 5)
			if south:
				lat = -30 * rng.randi_range(1, 2) if i == 0 else 30 * rng.randi_range(0, 2)
			var lng := 30 * rng.randi_range(-5, 5)
			if not used.has(Vector2i(lat, lng)):
				used[Vector2i(lat, lng)] = true
				points.append({"lat": lat, "long": lng, "label": str(named[i])})
				break
	var picture := {"kind": "latlong", "lat_step": lat_step, "long_step": 30, "points": points}
	var target: Dictionary = points[0] if south else points[rng.randi_range(0, 3)]
	var tlat := int(target.lat)
	var tlng := int(target.long)
	if south:
		ex = K.choice(rng, "Which place on the map is south of the Equator?", str(target.label),
			labels.filter(func(l: String) -> bool: return l != str(target.label)),
			"The Equator is the line at 0°. Places south of it have a latitude with S.",
			"%s is at %s: south of the Equator. The others are at 0° or north of it." % [target.label, _lat_text(tlat)], picture)
		ex.data = {"ask": "south", "target": str(target.label)}
		return ex
	if level == 1:
		ex = K.choice(rng, "Which place is at %s, %s?" % [_lat_text(tlat), _long_text(tlng)], str(target.label),
			labels.filter(func(l: String) -> bool: return l != str(target.label)),
			"Latitude first: find the line across (N or S of the Equator). Then longitude: the line down (E or W).",
			"%s is on the %s line across and the %s line down." % [target.label, _lat_text(tlat), _long_text(tlng)], picture)
		ex.data = {"ask": "at", "target": str(target.label)}
		return ex
	if rng.randf() < 0.5:
		var right := _lat_text(tlat)
		var wrongs: Array = []
		for v: int in [-tlat, tlat + 15, tlat - 15, tlat + 30]:
			if absi(v) <= 90 and _lat_text(v) != right and not wrongs.has(_lat_text(v)):
				wrongs.append(_lat_text(v))
		ex = K.choice(rng, "What is the latitude of place %s?" % target.label, right, wrongs.slice(0, 3),
			"Latitude is the line across. Count the lines from the Equator (0°), 15° each, and say N or S.",
			"%s is on the %s line: %s." % [target.label, right, "the Equator" if tlat == 0 else "%d° %s of the Equator" % [
				absi(tlat), "north" if tlat > 0 else "south"]], picture)
		ex.data = {"ask": "lat", "target": str(target.label)}
		return ex
	var right := _long_text(tlng)
	var wrongs: Array = []
	for v: int in [-tlng, tlng + 30, tlng - 30, tlng + 60]:
		if absi(v) <= 180 and _long_text(v) != right and not wrongs.has(_long_text(v)):
			wrongs.append(_long_text(v))
	ex = K.choice(rng, "What is the longitude of place %s?" % target.label, right, wrongs.slice(0, 3),
		"Longitude is the line down. Count the lines from the Prime Meridian (0°), 30° each, and say E or W.",
		"%s is on the %s line: %s." % [target.label, right, "the Prime Meridian" if tlng == 0 else "%d° %s of the Prime Meridian" % [
			absi(tlng), "east" if tlng > 0 else "west"]], picture)
	ex.data = {"ask": "long", "target": str(target.label)}
	return ex


# --- Geography: time zones (g5.geography.time_zones) ------------------------------------------------------------------

## January's clocks. Level 1: from London to a city a few hours ahead, the same day; level 2: from London to any city,
## ahead or behind, maybe across midnight; level 3: between two cities (both given against London), or the hours of a
## longitude's Sun time (15° for each hour).
static func time_zone(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.4:
		var lng := 15 * rng.randi_range(1, 12) * (1 if rng.randf() < 0.5 else -1)
		var way := "ahead of" if lng > 0 else "behind"
		ex = K.number("The Sun seems to cross 15° of longitude every hour. A town is at %s. How many hours %s Greenwich is its Sun time?" % [
			_long_text(lng), way], str(absi(lng) / 15),
			"360° in 24 hours is 15° an hour. How many lots of 15° is the town from Greenwich? East is ahead, west behind.",
			"%d ÷ 15 = %d, so its Sun time is %d hour%s %s Greenwich." % [absi(lng), absi(lng) / 15, absi(lng) / 15,
				"" if absi(lng) == 15 else "s", way])
		ex.data = {"ask": "longitude", "long": lng}
		return ex
	var cities: Array = ZONES.keys()
	var from := "London"
	var to := ""
	var h := 0
	var prompt := ""
	if level == 1:
		var near: Array = cities.filter(func(c: String) -> bool: return int(ZONES[c]) > 0 and int(ZONES[c]) <= 4)
		to = str(near[rng.randi_range(0, near.size() - 1)])
		h = rng.randi_range(6, 23 - int(ZONES[to]))
		prompt = "In January, when it is %s in London, what time is it in %s? %s is %s ahead of London." % [_clock(h), to,
			to, _hours(int(ZONES[to]))]
	elif level == 2:
		to = str(cities[rng.randi_range(0, cities.size() - 1)])
		h = rng.randi_range(0, 23)
		prompt = "In January, when it is %s in London, what time is it in %s? %s is %s %s London." % [_clock(h), to, to,
			_hours(absi(int(ZONES[to]))), "ahead of" if int(ZONES[to]) > 0 else "behind"]
	else:
		for _try in 100:
			var two := _pick_any(rng, cities, 2)
			from = str(two[0])
			to = str(two[1])
			if int(ZONES[from]) != int(ZONES[to]):
				break
		h = rng.randi_range(0, 23)
		prompt = "In January, %s is %s %s London and %s is %s %s it. When it is %s in %s, what time is it in %s?" % [from,
			_hours(absi(int(ZONES[from]))), "ahead of" if int(ZONES[from]) > 0 else "behind", to, _hours(absi(int(ZONES[to]))),
			"ahead of" if int(ZONES[to]) > 0 else "behind", _clock(h), from, to]
	var diff := int(ZONES[to]) - (0 if from == "London" else int(ZONES[from]))
	var right := _when(h + diff)
	var wrongs: Array = [_when(h - diff), _when(h + diff + 1), _when(h + diff - 1)]
	if right.contains(" the"):
		wrongs.push_front(_clock(h + diff))
	var hint := "Ahead means a later time: add the hours. Behind means an earlier time: take them away."
	if level == 3:
		hint = "Change the time in %s to London time first, then to the time in %s." % [from, to]
	var explain := "%s %s %d hour%s is %s." % [_clock(h), "+" if diff > 0 else "−", absi(diff), "" if absi(diff) == 1 else "s", right]
	if level == 3:
		var london := h - int(ZONES[from])
		explain = "In London it is %s %s %d = %s. In %s it is %s %s %d = %s." % [_clock(h), "−" if int(ZONES[from]) > 0 else
			"+", absi(int(ZONES[from])), _when(london), to, _clock(london), "+" if int(ZONES[to]) > 0 else "−",
			absi(int(ZONES[to])), right]
	ex = K.choice(rng, prompt, right, wrongs, hint, explain, {"kind": "digital_clock", "h": h, "m": 0})
	ex.data = {"ask": "time", "from": from, "to": to, "h": h}
	return ex


# --- Geography: up a mountain (g5.geography.climate_zones, two_mountain_regions) ---------------------------------------

## About 6.5 °C colder for every 1,000 m up. Level 1: 2,000 or 4,000 m up (a whole answer); level 2: 1,000-4,000 m up,
## staying above 0 °C (halves); level 3: a peak below freezing, or how high it gets to 0 °C.
static func altitude_temp(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rule := "It gets about 6.5 °C colder for every 1,000 m you climb. "
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.35:
		var k := rng.randi_range(2, 4)
		var t0 := 6.5 * k
		ex = K.number("It is %s °C at the foot of a mountain. %sAbout how many metres up does it reach 0 °C?" % [_num(t0), rule],
			str(k * 1000), "How many lots of 6.5 °C make the temperature at the foot? Each lot is 1,000 m.",
			"%s ÷ 6.5 = %d, so it reaches 0 °C about %d × 1,000 = %s m up." % [_num(t0), k, k, _digits(k * 1000)])
		ex.data = {"ask": "zero", "t": t0}
		return ex
	var t0 := 0
	var climb := 0
	if level == 1:
		t0 = 2 * rng.randi_range(8, 15)
		climb = 4000 if t0 >= 26 and rng.randf() < 0.5 else 2000
	elif level == 2:
		for _try in 50:
			t0 = rng.randi_range(10, 30)
			climb = 1000 * rng.randi_range(1, 4)
			if t0 - 6.5 * climb / 1000.0 >= 0.0:
				break
		if t0 - 6.5 * climb / 1000.0 < 0.0:
			climb = 1000
	else:
		t0 = rng.randi_range(4, 18)
		climb = 1000 * rng.randi_range(3, 5)
		while t0 - 6.5 * climb / 1000.0 >= 0.0:
			climb += 1000
	var drop := 6.5 * climb / 1000.0
	var t1 := t0 - drop
	var place: String = ["in a valley", "in a mountain village", "at the foot of a mountain"][rng.randi_range(0, 2)]
	ex = K.number("%sIt is %d °C %s. About how warm is it %s m higher up, in °C?" % [rule, t0, place, _digits(climb)], _num(t1,
		true), "Work out how many lots of 1,000 m you climb, times them by 6.5 °C, then take that from the temperature below.",
		"%s m ÷ 1,000 m = %d. %d × 6.5 = %s °C colder. %d − %s = %s °C." % [_digits(climb), climb / 1000, climb / 1000,
			_num(drop), t0, _num(drop), _num(t1)])
	ex.data = {"ask": "top", "t": t0, "climb": climb}
	return ex


# --- Geography: resources (g5.geography.natural_resources) ------------------------------------------------------------

## Level 1: four resources, renewable or non-renewable; level 2: five, harder; level 3: fossil fuels, metal ores and
## things from living things.
static func resource_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var groups: Array[String] = ["renewable", "non-renewable"]
	var lists: Array = []
	if level == 1:
		lists = [_pick(rng, RENEWABLE_EASY, 2), _pick(rng, NON_RENEWABLE_EASY, 2)]
	elif level == 2:
		var n := rng.randi_range(2, 3)
		lists = [_pick(rng, RENEWABLE_EASY + RENEWABLE_MORE, n), _pick(rng, NON_RENEWABLE_EASY + NON_RENEWABLE_MORE, 5 - n)]
	else:
		groups = ["fossil fuel", "metal ore", "from living things"]
		var counts: Array = [[2, 2, 1], [1, 2, 2], [2, 1, 2]][rng.randi_range(0, 2)]
		lists = [_pick(rng, FOSSIL, int(counts[0])), _pick(rng, ORES, int(counts[1])), _pick(rng, LIVING, int(counts[2]))]
	var items: Array = []
	var of := {}
	for g in lists.size():
		for it: String in lists[g]:
			items.append(it)
			of[it] = g
	GenKit.shuffle(rng, items)
	var answer: Array = items.map(func(it: String) -> int: return int(of[it]))
	var said: Array[String] = []
	for g in groups.size():
		said.append("%s: %s" % [_cap(groups[g]), ", ".join(lists[g])])
	var hint := "Ask: can nature make more of it within a lifetime, or will it run out one day?"
	if level == 3:
		hint = "Fossil fuels were made from plants and animals buried for millions of years; ores are rocks with metal in; the rest grows."
	var ex := {"type": "sort", "prompt": "Sort these resources: %s." % (" or ".join(groups) if level < 3 else
		"fossil fuel, metal ore, or from living things"), "groups": groups, "items": items, "answer": answer, "hint": hint,
		"explain": "%s." % ". ".join(said)}
	ex.data = {"groups": groups}
	return ex


# --- Geography: an atlas (g5.geography.atlas_digital_maps) ------------------------------------------------------------

## An atlas's index in a table, in alphabetical order. Level 1: a place's page; level 2: a place's grid square, or the
## place in a page's square; level 3: the index's latitudes and longitudes: the place furthest north, or the one south of
## the Equator, or the one west of the Prime Meridian.
static func atlas_index(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var ask: String = ["north", "south", "west"][rng.randi_range(0, 2)]
		var names: Array = []
		for _try in 200:
			names = _pick_any(rng, CITIES.keys(), 4)
			var ok := true
			var count := 0
			var lats := {}
			for c: String in names:
				var lat := int(CITIES[c][0])
				var lng := int(CITIES[c][1])
				lats[lat] = true
				if (ask == "south" and lat < 0) or (ask == "west" and lng < 0):
					count += 1
				ok = ok and lat != 0 and lng != 0
			if ok and lats.size() == 4 and (ask == "north" or count == 1):
				break
		names.sort()
		var rows: Array = [["place", "latitude", "longitude"]]
		var best := ""
		for c: String in names:
			rows.append([c, _lat_text(int(CITIES[c][0])), _long_text(int(CITIES[c][1]))])
			var lat := int(CITIES[c][0])
			var lng := int(CITIES[c][1])
			if ask == "north" and (best == "" or lat > int(CITIES[best][0])):
				best = c
			elif (ask == "south" and lat < 0) or (ask == "west" and lng < 0):
				best = c
		var q := {"north": "Which place in this index is furthest north?",
			"south": "Which place in this index is south of the Equator?",
			"west": "Which place in this index is west of the Prime Meridian?"}
		var h := {"north": "Furthest north has the biggest latitude with N (a latitude with S is south of the Equator).",
			"south": "South of the Equator means a latitude with S.", "west": "West of the Prime Meridian means a longitude with W."}
		ex = K.choice(rng, str(q[ask]), best, names.filter(func(c: String) -> bool: return c != best), str(h[ask]),
			"%s is at %s, %s." % [best, _lat_text(int(CITIES[best][0])), _long_text(int(CITIES[best][1]))],
			{"kind": "table", "rows": rows})
		ex.data = {"ask": ask}
		return ex
	var names: Array = _pick_any(rng, ATLAS_PLACES, 5)
	names.sort()
	var rows: Array = [["place", "page", "square"]]
	var squares := {}
	for c: String in names:
		var sq := ""
		for _try in 50:
			sq = "%s%d" % ["ABCDEF"[rng.randi_range(0, 5)], rng.randi_range(1, 8)]
			if not squares.has(sq):
				break
		squares[sq] = true
		rows.append([c, str(rng.randi_range(8, 96)), sq])
	var row: Array = rows[rng.randi_range(1, rows.size() - 1)]
	var head := "Here is part of an atlas's index. "
	if level == 1:
		ex = K.number(head + "On which page is %s?" % row[0], str(row[1]),
			"An index is in alphabetical order. Find the name, then read across to the page.",
			"%s is on page %s, in square %s." % [row[0], row[1], row[2]], {"kind": "table", "rows": rows})
		ex.data = {"ask": "page", "place": str(row[0])}
		return ex
	if rng.randf() < 0.5:
		var others: Array = []
		for r in range(1, rows.size()):
			if rows[r] != row:
				others.append(str(rows[r][2]))
		ex = K.choice(rng, head + "In which grid square of its page is %s?" % row[0], str(row[2]), others.slice(0, 3),
			"Find the name in the index, then read across to its square: a letter and a number.",
			"%s: page %s, square %s. Turn to the page, then find column %s and row %s." % [row[0], row[1], row[2],
				str(row[2]).substr(0, 1), str(row[2]).substr(1)], {"kind": "table", "rows": rows})
		ex.data = {"ask": "square", "place": str(row[0])}
		return ex
	var wrongs: Array = []
	for r in range(1, rows.size()):
		if rows[r] != row:
			wrongs.append(str(rows[r][0]))
	ex = K.choice(rng, head + "Which place is on page %s in square %s?" % [row[1], row[2]], str(row[0]), wrongs.slice(0, 3),
		"Look down the page and square columns for the pair, then read back to the name.",
		"Page %s, square %s is %s." % [row[1], row[2], row[0]], {"kind": "table", "rows": rows})
	ex.data = {"ask": "which", "place": str(row[0])}
	return ex


# --- Geography: trade (g5.geography.trade_links) ----------------------------------------------------------------------

## Level 1: an island's exports and imports: the difference, or whether it sells more than it buys; level 2: how many
## containers a cargo needs (a part-full one still sails); level 3: a voyage's days at a ship's speed.
static func trade_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var island := ISLANDS[rng.randi_range(0, ISLANDS.size() - 1)]
	var ex: Dictionary
	if level == 1:
		var e := 10 * rng.randi_range(10, 90)
		var i := e
		while i == e:
			i = 10 * rng.randi_range(10, 90)
		var sell := EXPORTS[rng.randi_range(0, EXPORTS.size() - 1)]
		var buy := IMPORTS[rng.randi_range(0, IMPORTS.size() - 1)]
		var head := "Each month, %s exports (sells to other places) %d gold of %s and imports (buys) %d gold of %s. " % [
			island, e, sell, i, buy]
		if rng.randf() < 0.5:
			ex = K.number(head + "How much more does it %s than it %s, in gold?" % ["sell" if e > i else "buy",
				"buys" if e > i else "sells"], str(absi(e - i)), "Take the smaller amount from the bigger one.",
				"%d − %d = %d gold." % [maxi(e, i), mini(e, i), absi(e - i)])
			ex.data = {"ask": "difference", "exports": e, "imports": i}
		else:
			ex = K.truefalse(head + "It sells more than it buys.", e > i, "Compare the exports with the imports.",
				"%s: exports %d gold %s imports %d gold." % ["True" if e > i else "False", e, ">" if e > i else "<", i])
			ex.data = {"ask": "sells_more", "exports": e, "imports": i}
		return ex
	if level == 2:
		var per: int = [20, 25, 40, 50][rng.randi_range(0, 3)]
		var boxes := per
		while boxes % per == 0:
			boxes = rng.randi_range(per + 1, per * 12)
		var what := CARGO[rng.randi_range(0, CARGO.size() - 1)]
		var full := boxes / per
		ex = K.number("A container holds %d boxes of %s. How many containers are needed for %d boxes?" % [per, what, boxes],
			str(full + 1), "Divide the boxes by how many fit in one container. If some are left over, they need one more container.",
			"%d ÷ %d = %d full containers and %d boxes left over, which need one more: %d + 1 = %d containers." % [boxes, per,
				full, boxes - full * per, full, full + 1])
		ex.data = {"ask": "containers", "boxes": boxes, "per": per}
		return ex
	var per_day: int = [600, 700, 800, 900][rng.randi_range(0, 3)]
	var days := rng.randi_range(8, 35)
	ex = K.number("A container ship sails about %d km a day. How many days does a voyage of %s km take?" % [per_day,
		_digits(per_day * days)], str(days), "How many lots of the day's distance make the whole voyage? Divide.",
		"%s ÷ %d = %d days." % [_digits(per_day * days), per_day, days])
	ex.data = {"ask": "days", "km": per_day * days, "per_day": per_day}
	return ex


# --- Citizenship: democracy (g5.citizenship.democracy) ----------------------------------------------------------------

## The class council's election results in a table. Level 1: the winner; level 2: how many more votes than the runner-up,
## or how many votes in all; level 3: the turnout as a percentage, or whether the winner got a majority.
static func election(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array[String] = _pick(rng, _people(), 3 if level < 3 else rng.randi_range(3, 4))
	var ask := "winner"
	if level == 2:
		ask = "margin" if rng.randf() < 0.5 else "total"
	elif level == 3:
		ask = "turnout" if rng.randf() < 0.5 else "majority"
	var voters := 0
	var votes := {}
	var want_majority := rng.randf() < 0.5
	for _try in 300:
		var total := rng.randi_range(12, 40)
		if ask == "turnout":
			voters = [50, 100, 200, 250, 400, 500][rng.randi_range(0, 5)]
			var pct := 5 * rng.randi_range(8, 19)
			if voters * pct % 100 != 0:
				continue
			total = voters * pct / 100
		votes = _split(rng, total, names)
		if not _one_top(votes):
			continue
		if ask == "majority" and (int(votes[_top(votes)]) * 2 > total) != want_majority:
			continue
		break
	var rows: Array = [["candidate", "votes"]]
	var total := 0
	var said: Array[String] = []
	for k in names:
		rows.append([k, str(votes[k])])
		total += int(votes[k])
		said.append(str(votes[k]))
	var top := _top(votes)
	var picture := {"kind": "table", "rows": rows}
	var head := "The pupils elected a speaker for the school council. "
	var ex: Dictionary
	var d := {"votes": votes, "ask": ask}
	if ask == "winner":
		ex = K.choice(rng, head + "Who won the election?", top, names.filter(func(x: String) -> bool: return x != top),
			"In this election, the candidate with the most votes wins.", "%s got %d votes, more than anyone else." % [top,
				votes[top]], picture)
	elif ask == "margin":
		var second := ""
		for k in names:
			if k != top and (second == "" or int(votes[k]) > int(votes[second])):
				second = k
		ex = K.number(head + "How many more votes did the winner get than the candidate who came second?",
			str(int(votes[top]) - int(votes[second])), "Find the biggest and the second biggest numbers of votes, then subtract.",
			"%s won with %d; %s came second with %d. %d − %d = %d more votes." % [top, votes[top], second, votes[second],
				votes[top], votes[second], int(votes[top]) - int(votes[second])], picture)
		d.second = second
	elif ask == "total":
		ex = K.number(head + "How many votes were cast altogether?", str(total), "Each vote counts once: add them all up.",
			"%s = %d votes." % [" + ".join(said), total], picture)
	elif ask == "turnout":
		ex = K.number(head + "%d pupils could vote. What percentage of them voted?" % voters, str(total * 100 / voters),
			"Add up the votes, then find what part of the voters that is, out of 100.",
			"%s = %d votes. %d out of %d is %d out of 100, so %d%% voted." % [" + ".join(said), total, total, voters,
				total * 100 / voters, total * 100 / voters], picture)
		d.voters = voters
	else:
		var has := int(votes[top]) * 2 > total
		ex = K.truefalse(head + "The winner got a majority: more than half of all the votes.", has,
			"Add up all the votes and find half. A majority is more than half.",
			"%s = %d votes; half is %s. %s got %d, which is %s half." % [" + ".join(said), total, _half(total), top, votes[top],
				"more than" if has else "not more than"], picture)
	ex.data = d
	return ex


# --- Citizenship: money (g5.citizenship.make_a_budget, banks_interest, borrowing) --------------------------------------

## A week's budget in gold. Level 1: what is left after spending; level 2: needs first, then saving, then wants: what is
## left for wants; level 3: a budget table: what is left to save, or how many weeks to save for a goal.
static func budget_plan(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = PEOPLE.keys()[rng.randi_range(0, PEOPLE.size() - 1)]
	var p: Array = PEOPLE[who]
	var ex: Dictionary
	if level == 1:
		var income := rng.randi_range(15, 40)
		var cost := rng.randi_range(4, income - 3)
		ex = K.number("%s earns %d gold a week helping at the farm and spends %d gold of it. How much is left?" % [who, income,
			cost], str(income - cost), "Money in, take away money out.", "%d − %d = %d gold left." % [income, cost, income - cost])
		ex.data = {"ask": "left", "income": income, "costs": [cost]}
		return ex
	if level == 2:
		var income := rng.randi_range(20, 50)
		var needs := rng.randi_range(6, income / 2)
		var save := rng.randi_range(2, (income - needs) / 2)
		ex = K.number("Needs first, then saving, then wants. %s gets %d gold a week. %s needs cost %d gold and %s saves %d gold. How much is left for wants?" % [
			who, income, str(p[1]).capitalize(), needs, p[0], save], str(income - needs - save),
			"Take away the needs, then the saving. What is left can go on wants.",
			"%d − %d = %d, then %d − %d = %d gold for wants." % [income, needs, income - needs, income - needs, save,
				income - needs - save])
		ex.data = {"ask": "wants", "income": income, "costs": [needs, save]}
		return ex
	var income := rng.randi_range(25, 60)
	var costs: Array[int] = []
	for _try in 50:
		costs = [rng.randi_range(5, 15), rng.randi_range(3, 12), rng.randi_range(2, 8)]
		if costs[0] + costs[1] + costs[2] < income - 3:
			break
	if costs[0] + costs[1] + costs[2] >= income - 3:
		costs = [6, 5, 4]
		income = 30
	var left := income - costs[0] - costs[1] - costs[2]
	var rows: Array = [["budget", "gold a week"], ["in: jobs", str(income)], ["out: food", str(costs[0])],
		["out: tools", str(costs[1])], ["out: gifts", str(costs[2])]]
	var picture := {"kind": "table", "rows": rows}
	var spent := "%d + %d + %d = %d gold out" % [costs[0], costs[1], costs[2], costs[0] + costs[1] + costs[2]]
	if rng.randf() < 0.5:
		ex = K.number("%s's weekly budget is in the table. How much can %s save each week?" % [who, p[0]], str(left),
			"Add up all the money going out, then take it from the money coming in.",
			"%s. %d − %d = %d gold to save." % [spent, income, costs[0] + costs[1] + costs[2], left], picture)
		ex.data = {"ask": "left", "income": income, "costs": costs}
		return ex
	var goal := left * rng.randi_range(2, 8) + rng.randi_range(1, left - 1) if left > 1 else rng.randi_range(3, 12)
	var weeks := ceili(float(goal) / float(left))
	ex = K.number("%s's weekly budget is in the table. %s saves what is left each week for a saddle costing %d gold. How many weeks until %s can buy it?" % [
		who, str(p[0]).capitalize(), goal, p[0]], str(weeks),
		"Work out the saving each week first. Then how many weeks of saving reach the price? A part week still counts.",
		"%s. %d − %d = %d gold a week. %d ÷ %d is %s, so %d weeks." % [spent, income, costs[0] + costs[1] + costs[2], left,
			goal, left, ("%d" % (goal / left)) if goal % left == 0 else "more than %d" % (goal / left), weeks], picture)
	ex.data = {"ask": "weeks", "income": income, "costs": costs, "goal": goal}
	return ex


## Simple interest (the bank pays a percentage of the savings each year). Level 1: 10% or 5% of whole hundreds for a
## year; level 2: the account after a year at 2-5%; level 3: 2-4 years, the interest or the account.
static func simple_interest(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = PEOPLE.keys()[rng.randi_range(0, PEOPLE.size() - 1)]
	var p: Array = PEOPLE[who]
	var saved := 100 * rng.randi_range(1, 9)
	var rate: int = [10, 5][rng.randi_range(0, 1)]
	var years := 1
	var ask := "interest"
	if level == 2:
		saved = 100 * rng.randi_range(1, 10)
		rate = rng.randi_range(2, 5)
		ask = "total"
	elif level == 3:
		saved = 100 * rng.randi_range(2, 10)
		rate = rng.randi_range(2, 10)
		years = rng.randi_range(2, 4)
		ask = "interest" if rng.randf() < 0.5 else "total"
	var per_year := saved * rate / 100
	var interest := per_year * years
	var ex: Dictionary
	var how := "%d%% means %d gold for every 100 gold. %s gold is %d hundred%s, so %d × %d = %d gold a year" % [rate, rate,
		_digits(saved), saved / 100, "" if saved == 100 else "s", saved / 100, rate, per_year]
	if level < 3:
		var q := "How much interest does %s earn in one year?" % p[0] if ask == "interest" else \
			"How much is in %s account after one year?" % p[1]
		ex = K.number("%s saves %s gold in a bank that pays %d%% interest a year. %s" % [who, _digits(saved), rate, q],
			str(interest if ask == "interest" else saved + interest),
			"%d%% means %d gold for every 100 gold saved. How many hundreds are saved?" % [rate, rate],
			"%s.%s" % [how, "" if ask == "interest" else " %s + %d = %s gold." % [_digits(saved), interest, _digits(saved + interest)]])
	else:
		var q := "How much interest does %s earn in %d years?" % [p[0], years] if ask == "interest" else \
			"How much is in %s account after %d years?" % [p[1], years]
		ex = K.number("%s saves %s gold. The bank pays %d%% of it as interest every year (simple interest). %s" % [who, _digits(saved),
			rate, q], str(interest if ask == "interest" else saved + interest),
			"Work out one year's interest first, then times it by the number of years.",
			"%s. %d × %d years = %d gold.%s" % [how, per_year, years, interest, "" if ask == "interest" else
				" %s + %d = %s gold." % [_digits(saved), interest, _digits(saved + interest)]])
	ex.data = {"ask": ask, "saved": saved, "rate": rate, "years": years}
	return ex


## Level 1: what borrowing cost (paid back − borrowed); level 2: what to pay back after a year at 5-20%; level 3: each
## of equal repayments, or which of two loans costs less.
static func loan_cost(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = PEOPLE.keys()[rng.randi_range(0, PEOPLE.size() - 1)]
	var p: Array = PEOPLE[who]
	var ex: Dictionary
	if level == 1:
		var borrow := 10 * rng.randi_range(3, 20)
		var back: int = borrow + rng.randi_range(1, 10) * int([1, 2, 5][rng.randi_range(0, 2)])
		ex = K.number("%s borrows %d gold to buy a boat and must pay back %d gold. How much does borrowing cost %s?" % [who,
			borrow, back, "him" if p[0] == "he" else "her"], str(back - borrow),
			"The cost is the extra: what is paid back, take away what was borrowed.",
			"%d − %d = %d gold of interest." % [back, borrow, back - borrow])
		ex.data = {"ask": "interest", "borrow": borrow, "back": back}
		return ex
	if level == 2:
		var borrow := 100 * rng.randi_range(1, 10)
		var rate: int = [5, 10, 15, 20][rng.randi_range(0, 3)]
		var extra := borrow * rate / 100
		ex = K.number("%s borrows %s gold for a year at %d%% interest. How much must %s pay back?" % [who, _digits(borrow), rate, p[0]],
			str(borrow + extra), "Find the interest: %d gold for every 100 gold borrowed. Then add it to what was borrowed." % rate,
			"%d%% of %s is %d × %d = %d gold. %s + %d = %s gold." % [rate, _digits(borrow), borrow / 100, rate, extra,
				_digits(borrow), extra, _digits(borrow + extra)])
		ex.data = {"ask": "pay_back", "borrow": borrow, "rate": rate}
		return ex
	if rng.randf() < 0.5:
		var parts: int = [4, 5, 6, 10, 12][rng.randi_range(0, 4)]
		var each := rng.randi_range(5, 30)
		ex = K.number("%s must pay back %d gold in %d equal parts, one each month. How much is each part?" % [who,
			parts * each, parts], str(each), "Share the total equally: divide it by the number of parts.",
			"%d ÷ %d = %d gold each month." % [parts * each, parts, each])
		ex.data = {"ask": "each", "back": parts * each, "parts": parts}
		return ex
	var borrow := 10 * rng.randi_range(10, 30)
	var parts: int = [5, 10, 12][rng.randi_range(0, 2)]
	var each := 0
	var other := 0
	for _try in 50:
		each = borrow / parts + rng.randi_range(1, 6)
		other = borrow + 5 * rng.randi_range(2, 12)
		if each * parts != other:
			break
	ex = K.choice(rng, "Both loans lend %d gold. Loan A: pay back %d parts of %d gold. Loan B: pay back %d gold in one go. Which costs less?" % [
		borrow, parts, each, other], "Loan A" if each * parts < other else "Loan B",
		["Loan B" if each * parts < other else "Loan A", "They cost the same"],
		"Work out the total paid back for Loan A, then compare it with Loan B.",
		"Loan A: %d × %d = %d gold. Loan B: %d gold. %s costs less, by %d gold." % [parts, each, each * parts, other,
			"Loan A" if each * parts < other else "Loan B", absi(each * parts - other)])
	ex.data = {"ask": "cheaper", "parts": parts, "each": each, "other": other}
	return ex


# --- Citizenship: caring for the planet (g5.citizenship.planet_action) -------------------------------------------------

## The class weighs its rubbish each week (a table). Level 1: how many kg less in the last week than the first; level 2:
## the weeks' total; level 3: by what percentage it went down.
static func waste_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var weeks: Array[int] = []
	if level == 3:
		var first: int = [10, 20, 25, 40, 50][rng.randi_range(0, 4)]
		var pcts: Array = [10, 20, 30, 40, 50, 60].filter(func(x: int) -> bool: return first * x % 100 == 0)
		var pct: int = pcts[rng.randi_range(0, pcts.size() - 1)]
		var last := first - first * pct / 100
		weeks = [first, 0, 0, last]
		weeks[1] = rng.randi_range(last, first)
		weeks[2] = rng.randi_range(last, weeks[1])
	else:
		weeks = [rng.randi_range(18, 40), 0, 0, 0]
		for i in range(1, 4):
			weeks[i] = maxi(3, weeks[i - 1] - rng.randi_range(0, 6))
		if weeks[3] == weeks[0]:
			weeks[3] -= 1
	var rows: Array = [["week", "rubbish (kg)"]]
	for i in weeks.size():
		rows.append([str(i + 1), str(weeks[i])])
	var picture := {"kind": "table", "rows": rows}
	var head := "The class started a Waste Less plan and weighed its rubbish every week (the table). "
	var ex: Dictionary
	if level == 1:
		ex = K.number(head + "How many kg less rubbish was there in week 4 than in week 1?", str(weeks[0] - weeks[3]),
			"Read weeks 1 and 4, then take the smaller from the bigger.",
			"%d − %d = %d kg less." % [weeks[0], weeks[3], weeks[0] - weeks[3]], picture)
		ex.data = {"ask": "less", "kg": weeks}
	elif level == 2:
		var total := weeks[0] + weeks[1] + weeks[2] + weeks[3]
		ex = K.number(head + "How much rubbish was there in the 4 weeks altogether, in kg?", str(total),
			"Add the four weeks. Look for pairs that make a ten.",
			"%d + %d + %d + %d = %d kg." % [weeks[0], weeks[1], weeks[2], weeks[3], total], picture)
		ex.data = {"ask": "total", "kg": weeks}
	else:
		var drop := weeks[0] - weeks[3]
		var pct := drop * 100 / weeks[0]
		ex = K.number(head + "By what percentage did the rubbish go down from week 1 to week 4?", str(pct),
			"Find how many kg less, then how many that is for every 100 kg of week 1.",
			"%d − %d = %d kg less. %d out of %d is %d out of 100: %d%% less." % [weeks[0], weeks[3], drop, drop, weeks[0], pct,
				pct], picture)
		ex.data = {"ask": "percent", "kg": weeks}
	return ex


# --- Helpers ------------------------------------------------------------------------------------------------------------

## "second" for 2-5, then "6th", "11th", "22nd", "23rd".
static func _ordinal(n: int) -> String:
	if ORDINALS.has(n):
		return str(ORDINALS[n])
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = str({1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th"))
	return "%d%s" % [n, suffix]


## A year as the lessons write it: "776 BC", "about 550 BC", "AD 43".
static func _year_text(y: int, about: bool) -> String:
	var t := "%d BC" % -y if y < 0 else "AD %d" % y
	return ("about " + t) if about else t


static func _roman(n: int) -> String:
	var out := ""
	var left := n
	for pair: Array in ROMAN:
		while left >= int(pair[0]):
			out += str(pair[1])
			left -= int(pair[0])
	return out


## A number's Roman parts, one for each digit that is not 0, biggest first: [worth, letters] (1987 -> [1000, "M"],
## [900, "CM"], [80, "LXXX"], [7, "VII"]).
static func _roman_parts(n: int) -> Array:
	var out: Array = []
	for place: int in [1000, 100, 10, 1]:
		var worth := n / place % 10 * place
		if worth > 0:
			out.append([worth, _roman(worth)])
	return out


## A numeral with its first subtractive pair turned round ("XL" -> "LX"), a wrong choice that is another number.
static func _swapped(r: String) -> String:
	for pair: String in ["CM", "CD", "XC", "XL", "IX", "IV"]:
		var at := r.find(pair)
		if at >= 0:
			return r.substr(0, at) + pair[1] + pair[0] + r.substr(at + 2)
	return r


## A Maya digit in words: "a shell", "3 dots", "2 bars and 1 dot".
static func _maya_words(digit: int) -> String:
	if digit == 0:
		return "a shell"
	var parts: Array[String] = []
	if digit / 5 > 0:
		parts.append("%d bar%s" % [digit / 5, "" if digit / 5 == 1 else "s"])
	if digit % 5 > 0:
		parts.append("%d dot%s" % [digit % 5, "" if digit % 5 == 1 else "s"])
	return " and ".join(parts)


static func _lat_text(v: int) -> String:
	return SchoolPictureHistory.lat_text(v)


static func _long_text(v: int) -> String:
	return SchoolPictureHistory.long_text(v)


## "09:00" (the hour within the day).
static func _clock(h: int) -> String:
	return "%02d:00" % posmod(h, 24)


## A time with the day it falls on: "22:00 the day before", "03:00 the next day".
static func _when(h: int) -> String:
	return _clock(h) + ("" if h >= 0 and h < 24 else (" the next day" if h >= 24 else " the day before"))


static func _hours(n: int) -> String:
	return "%d hour%s" % [n, "" if n == 1 else "s"]


## 12 -> "12", 12.5 -> "12.5", −7.5 -> "−7.5" (or "-7.5" for an answer).
static func _num(v: float, answer: bool = false) -> String:
	var t := str(roundi(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
	return t if answer else t.replace("-", "−")


## A whole number as the lessons write it: 1000 -> "1,000" (years stay "1850").
static func _digits(n: int) -> String:
	return GenKit.fmt(n)


static func _half(n: int) -> String:
	return str(n / 2) if n % 2 == 0 else "%d½" % (n / 2)


## `total` votes shared between `names` at random (each at least 1; the last takes what is left).
static func _split(rng: RandomNumberGenerator, total: int, names: Array[String]) -> Dictionary:
	var out := {}
	var left := total
	for i in names.size():
		var still := names.size() - 1 - i   # names after this one, each needing at least 1
		var v := left if still == 0 else rng.randi_range(1, maxi(1, left - still))
		out[names[i]] = v
		left -= v
	return out


## The game's four friends' names, typed.
static func _people() -> Array[String]:
	var out: Array[String] = []
	for k: String in PEOPLE:
		out.append(k)
	return out


## "fossil fuel" -> "Fossil fuel".
static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


static func _one_top(counts: Dictionary) -> bool:
	var best := -1
	var seen := 0
	for k: String in counts:
		if int(counts[k]) > best:
			best = int(counts[k])
			seen = 1
		elif int(counts[k]) == best:
			seen += 1
	return seen == 1


static func _top(counts: Dictionary) -> String:
	var top := ""
	for k: String in counts:
		if top == "" or int(counts[k]) > int(counts[top]):
			top = k
	return top


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
