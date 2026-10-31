class_name G4HumanitiesGen
extends RefCounted
## Owner #70 and #73 (research §6.4): grade 4 history, geography and citizenship generators: years apart across BC and
## AD and the first civilisations' dated events in order; Egyptian hieroglyph numbers and the Babylonians' sixties (and
## our minutes); map scales (words, scale bars, ratios, routes); capitals of the world, Europe and the Americas (widely
## recognised capitals only, research §5.4 rule 2); fieldwork data (a traffic count's bar graph, a weather table with
## minus temperatures); and the game's gold with decimals from grade 4 (research §5.5 ruling 6): best value and the
## price for one, change and a card account's balance, adverts' deals, a town's shared costs and budget, and votes and
## majorities. SchoolGen "g4h.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`,
## seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for
## tests/unit/test_g4_humanities_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE := {"Tilly": ["she", "her"], "Zara": ["she", "her"], "Bram": ["he", "his"], "Mimi": ["she", "her"]}

## The first civilisations' dated events and their finding again: [what happened, the year (BC below 0), about?]. The
## lessons give the same dates (grade 4 history's units).
const EVENTS: Array = [
	["Farming begins", -10000, true],
	["Uruk grows into a city", -3500, true],
	["Writing begins in Sumer", -3200, true],
	["Egypt is united under one king", -3100, true],
	["Stonehenge's first circle is dug", -3000, true],
	["The Great Pyramid is finished", -2560, true],
	["Mohenjo-daro is built", -2500, true],
	["Hammurabi's laws are carved", -1754, true],
	["The Shang dynasty begins", -1600, true],
	["Tutankhamun becomes pharaoh", -1332, true],
	["The Shang dynasty ends", -1046, true],
	["The first coins are made in Lydia", -600, true],
	["The Rosetta Stone is carved", -196, false],
	["The last hieroglyphs are carved", 394, false],
	["Champollion reads hieroglyphs", 1822, false],
	["Oracle bones are found to be writing", 1899, false],
	["Tutankhamun's tomb is found", 1922, false],
	["Fu Hao's tomb is found", 1976, false],
]
## Egyptian number signs, biggest first: [worth, one, many].
const EGYPT_SIGNS: Array = [[1000, "lotus flower", "lotus flowers"], [100, "coil of rope", "coils of rope"],
	[10, "heel bone", "heel bones"], [1, "stroke", "strokes"]]

## Capitals (widely recognised ones only; no country whose capital or borders are disputed): country -> [capital,
## continent ("" where the seven-continent answer is unclear)].
const COUNTRIES := {
	"France": ["Paris", "Europe"], "Italy": ["Rome", "Europe"], "Spain": ["Madrid", "Europe"],
	"the United Kingdom": ["London", "Europe"], "Germany": ["Berlin", "Europe"], "Ireland": ["Dublin", "Europe"],
	"Greece": ["Athens", "Europe"], "Portugal": ["Lisbon", "Europe"], "the Netherlands": ["Amsterdam", "Europe"],
	"Belgium": ["Brussels", "Europe"], "Poland": ["Warsaw", "Europe"], "Sweden": ["Stockholm", "Europe"],
	"Norway": ["Oslo", "Europe"], "Denmark": ["Copenhagen", "Europe"], "Finland": ["Helsinki", "Europe"],
	"Austria": ["Vienna", "Europe"], "Hungary": ["Budapest", "Europe"], "Iceland": ["Reykjavik", "Europe"],
	"Romania": ["Bucharest", "Europe"], "the Czech Republic": ["Prague", "Europe"],
	"Japan": ["Tokyo", "Asia"], "China": ["Beijing", "Asia"], "India": ["New Delhi", "Asia"],
	"South Korea": ["Seoul", "Asia"], "Thailand": ["Bangkok", "Asia"], "Vietnam": ["Hanoi", "Asia"],
	"Pakistan": ["Islamabad", "Asia"], "Nepal": ["Kathmandu", "Asia"], "the Philippines": ["Manila", "Asia"],
	"Egypt": ["Cairo", "Africa"], "Kenya": ["Nairobi", "Africa"], "Nigeria": ["Abuja", "Africa"],
	"Ghana": ["Accra", "Africa"], "Ethiopia": ["Addis Ababa", "Africa"], "Senegal": ["Dakar", "Africa"],
	"Morocco": ["Rabat", "Africa"], "Turkey": ["Ankara", ""], "Australia": ["Canberra", "Australia"],
	"New Zealand": ["Wellington", ""], "Canada": ["Ottawa", "North America"],
	"the United States": ["Washington, D.C.", "North America"], "Mexico": ["Mexico City", "North America"],
	"Cuba": ["Havana", "North America"], "Jamaica": ["Kingston", "North America"],
	"Panama": ["Panama City", "North America"], "Costa Rica": ["San Jose", "North America"],
	"Guatemala": ["Guatemala City", "North America"], "Brazil": ["Brasilia", "South America"],
	"Argentina": ["Buenos Aires", "South America"], "Peru": ["Lima", "South America"],
	"Chile": ["Santiago", "South America"], "Colombia": ["Bogota", "South America"],
	"Venezuela": ["Caracas", "South America"], "Ecuador": ["Quito", "South America"],
	"Uruguay": ["Montevideo", "South America"], "Paraguay": ["Asuncion", "South America"],
}
const WORLD_EASY: Array[String] = ["France", "Italy", "Spain", "the United Kingdom", "Germany", "Japan", "China", "Egypt",
	"Kenya", "Mexico", "Argentina", "Peru"]
const WORLD_MORE: Array[String] = ["India", "South Korea", "Thailand", "Nepal", "the Philippines", "Ghana", "Ethiopia",
	"Senegal", "Greece", "Norway", "Chile", "Colombia", "Cuba", "Jamaica"]
## Capitals that are not their country's biggest city: country -> the biggest city.
const BIGGEST := {"Australia": "Sydney", "Canada": "Toronto", "Brazil": "Sao Paulo", "the United States": "New York",
	"Nigeria": "Lagos", "Pakistan": "Karachi", "New Zealand": "Auckland", "Morocco": "Casablanca", "Turkey": "Istanbul",
	"Vietnam": "Ho Chi Minh City"}
const CONTINENTS: Array[String] = ["Africa", "Asia", "Europe", "North America", "South America", "Australia",
	"Antarctica"]
const EUROPE_EASY: Array[String] = ["the United Kingdom", "France", "Germany", "Italy", "Spain", "Ireland", "Greece",
	"Portugal"]
const EUROPE_MORE: Array[String] = ["the Netherlands", "Belgium", "Poland", "Sweden", "Norway", "Denmark", "Finland",
	"Austria", "Hungary", "Iceland", "Romania", "the Czech Republic"]
## The river a European capital stands on: capital -> river.
const CAPITAL_RIVERS := {"London": "Thames", "Paris": "Seine", "Rome": "Tiber", "Vienna": "Danube",
	"Budapest": "Danube", "Berlin": "Spree", "Prague": "Vltava", "Lisbon": "Tagus", "Warsaw": "Vistula",
	"Dublin": "Liffey"}
const AMERICAS_EASY: Array[String] = ["Canada", "the United States", "Mexico", "Brazil", "Argentina", "Peru"]
const AMERICAS_MORE: Array[String] = ["Chile", "Colombia", "Venezuela", "Cuba", "Jamaica", "Ecuador", "Uruguay",
	"Panama", "Costa Rica", "Guatemala", "Paraguay"]

const VEHICLES: Array[String] = ["cars", "vans", "bikes", "buses", "lorries"]
const DAYS: Array[String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
## [one, many] of things sold in the game's stalls.
const GOODS: Array = [["kite", "kites"], ["lantern", "lanterns"], ["rope", "ropes"], ["bucket", "buckets"],
	["hat", "hats"], ["ball", "balls"], ["book", "books"], ["bell", "bells"]]
const FOODS: Array[String] = ["apples", "eggs", "carrots", "bread rolls", "pears", "plums"]
## Builds a class can vote for (short words: the bar graph's labels).
const BUILDS: Array[String] = ["treehouse", "pond", "maze", "garden", "tower", "bridge"]


# --- History: timelines (g4.history.first_cities, compare_civilisations) ----------------------------------------------

## "How many years are there from 3000 BC to 2200 BC?" Level 1: whole hundreds BC; level 2: two of the first
## civilisations' events, both BC; level 3: from a BC year to an AD year, exactly (there is no year 0: 1 BC is followed
## by AD 1).
static func years_apart(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a: int
	var b: int
	var prompt: String
	if level == 1:
		a = -rng.randi_range(20, 50) * 100
		b = a + rng.randi_range(3, 15) * 100
		prompt = "How many years are there from %s to %s?" % [_year_text(a, false), _year_text(b, false)]
	elif level == 2:
		var bc := EVENTS.filter(func(e: Array) -> bool: return int(e[1]) < 0)
		var two := _pick_any(rng, bc, 2)
		two.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
		a = int(two[0][1])
		b = int(two[1][1])
		prompt = "%s: %s. %s: %s. How many years apart are they?" % [two[0][0], _year_text(a, bool(two[0][2])), two[1][0],
			_year_text(b, bool(two[1][2]))]
	else:
		a = -rng.randi_range(1, 20) * 50
		b = rng.randi_range(1, 30) * 50
		prompt = "How many years are there from %s to %s? Remember: there is no year 0." % [_year_text(a, false),
			_year_text(b, false)]
	var ex: Dictionary
	if b < 0:
		ex = K.number(prompt, str(b - a), "BC years count down towards AD 1, so take the smaller number from the bigger one.",
			"BC years count down: %s − %s = %s years." % [_digits(-a), _digits(-b), GenKit.fmt(b - a)])
	else:
		ex = K.number(prompt, str(b - a - 1),
			"Count the years up to AD 1, then add the years after it. From 1 BC to AD 1 is just 1 year.",
			"From %s to AD 1 is %d years. From AD 1 to %s is %d more. %d + %d = %s years." % [_year_text(a, false), -a,
				_year_text(b, false), b - 1, -a, b - 1, GenKit.fmt(b - a - 1)])
	ex.data = {"from": a, "to": b}
	return ex


## "Put these events in order on a timeline, earliest first." Level 1: three events far apart; level 2: four BC events;
## level 3: four events, BC and AD.
static func event_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var picked: Array = []
	for _try in 200:
		var pool: Array = EVENTS if level != 2 else EVENTS.filter(func(e: Array) -> bool: return int(e[1]) < 0)
		picked = _pick_any(rng, pool, 3 if level == 1 else 4)
		picked.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
		var ok := true
		for k in range(1, picked.size()):
			var gap := int(picked[k][1]) - int(picked[k - 1][1])
			ok = ok and gap > 0 and (level != 1 or gap >= 400)
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
	if level == 1 and int(picked[-1][1]) < 0:
		hint = "BC years count down to AD 1: the bigger the BC number, the longer ago it was."
	var ex := K.order(rng, "Put these events in order on a timeline, earliest first.", words, hint,
		"Earliest first: %s." % ", ".join(years))
	ex.data = {"events": picked.map(func(e: Array) -> String: return str(e[0]))}
	return ex


# --- History: how ancient people counted (g4.history.ancient_numbers) -------------------------------------------------

## Egyptian hieroglyph numbers. Level 1: read one to 999 from the picture; level 2: to 9,999; level 3: how many signs a
## scribe draws for a number (all of them, or of one kind: a 0 needs none).
static func egypt_number(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var v := rng.randi_range(11, 999) if level == 1 else rng.randi_range(1000, 9999)
	var parts: Array[String] = []
	var worths: Array[String] = []
	for s: Array in EGYPT_SIGNS:
		var count := v / int(s[0]) % 10
		if count > 0:
			parts.append("%d %s (%s)" % [count, s[1] if count == 1 else s[2], GenKit.fmt(count * int(s[0]))])
			worths.append(GenKit.fmt(count * int(s[0])))
	var ex: Dictionary
	if level < 3:
		var hint := "A coil of rope is 100, a heel bone 10 and a stroke 1. Count each kind of sign, then add."
		if level == 2:
			hint = "A lotus flower is 1,000, a coil of rope 100, a heel bone 10 and a stroke 1. Count each kind, then add."
		var sum: String = "%s = %s" % [" + ".join(worths), GenKit.fmt(v)] if worths.size() > 1 else GenKit.fmt(v)
		ex = K.number("What number do these Egyptian hieroglyphs show?", str(v), hint, "%s: %s." % [", ".join(parts), sum],
			{"kind": "numerals", "system": "egypt", "value": v})
		ex.data = {"value": v, "ask": "read"}
		return ex
	var digits: Array[int] = [v / 1000, v / 100 % 10, v / 10 % 10, v % 10]
	var ask := "signs"
	if rng.randf() < 0.6:
		var s: Array = EGYPT_SIGNS[rng.randi_range(0, 3)]
		ask = str(s[2])
		var count := v / int(s[0]) % 10
		ex = K.number("An Egyptian scribe writes the number %s. How many %s does the scribe draw?" % [GenKit.fmt(v), ask],
			str(count), "Each digit tells you how many of one sign: thousands are lotus flowers, hundreds coils of rope, tens heel bones, ones strokes.",
			"%s is %s. So %d %s%s." % [GenKit.fmt(v), ", ".join(parts), count, ask,
				" (a 0 needs no sign at all)" if count == 0 else ""])
	else:
		var total := digits[0] + digits[1] + digits[2] + digits[3]
		ex = K.number("How many signs in all does an Egyptian scribe draw to write %s?" % GenKit.fmt(v), str(total),
			"Each digit tells you how many signs of one kind are needed. Add the digits together.",
			"%s is %s. %d + %d + %d + %d = %d signs." % [GenKit.fmt(v), ", ".join(parts), digits[0], digits[1], digits[2],
				digits[3], total])
	ex.data = {"value": v, "ask": ask}
	return ex


## Sixties. Level 1: minutes in hours, or seconds in minutes; level 2: a Babylonian number in two places (sixties and
## ones, the places labelled); level 3: a bigger Babylonian number, unlabelled, or minutes as hours and minutes.
static func sixties(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var n := rng.randi_range(2, 10)
		var kind := "minutes" if rng.randf() < 0.5 else "seconds"
		var big := "hours" if kind == "minutes" else "minutes"
		ex = K.number("How many %s are there in %d %s?" % [kind, n, big], str(n * 60),
			"There are 60 %s in every %s (from the Babylonians' sixties), so multiply by 60." % [kind, big.trim_suffix("s")],
			"%d × 60 = %d %s." % [n, n * 60, kind])
		ex.data = {"kind": kind, "n": n}
		return ex
	if level == 3 and rng.randf() < 0.5:
		var h := rng.randi_range(1, 5)
		var m := rng.randi_range(1, 11) * 5
		var total := h * 60 + m
		ex = K.number("%d minutes is %d hour%s and how many minutes?" % [total, h, "" if h == 1 else "s"], str(m),
			"Take away 60 minutes for each whole hour. What is left over is the minutes.",
			"%d hour%s = %d × 60 = %d minutes. %d − %d = %d minutes left over." % [h, "" if h == 1 else "s", h, h * 60,
				total, h * 60, m])
		ex.data = {"kind": "hours_minutes", "minutes": total}
		return ex
	var s := rng.randi_range(1, 9) if level == 2 else rng.randi_range(10, 59)
	var o := rng.randi_range(1, 59)
	var v := s * 60 + o
	ex = K.number("The Babylonians counted in sixties. What number does this clay tablet show?%s" % [
		" The left group counts sixties." if level == 2 else ""], str(v),
		"In each group a corner wedge is 10 and an upright wedge is 1. The left group counts sixties: times it by 60, then add the right group.",
		"Left: %s = %d sixt%s = %d × 60 = %s. Right: %s = %d. %s + %d = %s." % [_wedges(s), s, "y" if s == 1 else "ies", s,
			GenKit.fmt(s * 60),
			_wedges(o), o, GenKit.fmt(s * 60), o, GenKit.fmt(v)],
		{"kind": "numerals", "system": "babylon", "value": v, "labels": level == 2})
	ex.data = {"kind": "babylon", "sixties": s, "ones": o}
	return ex


# --- Geography: scale and distance (g4.geography.scale_distance) -------------------------------------------------------

## Level 1: "1 cm stands for 5 km; the path is 4 cm on the map: how long really?" (a scale bar under it); level 2: from
## a real distance back to the map, or a town map in metres; level 3: a route of 2-3 legs, or a ratio scale (1 : 50,000).
static func map_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var per: int
	var legs: Array[int] = []
	var unit := "km"
	var ask := "real"
	var ratio := 0
	var ex: Dictionary
	if level == 1 or level == 2 and rng.randf() < 0.5:
		per = [2000, 5000, 10000][rng.randi_range(0, 2)] if level == 1 else [2000, 5000, 10000, 25000][rng.randi_range(0, 3)]
		legs = [rng.randi_range(2, 9)]
		var km := per / 1000
		var bar := {"kind": "number_line", "from": "0", "to": str(km * 5), "step": str(km), "labels": "all"}
		if level == 1:
			var place: String = ["the mill", "the lake", "the castle", "the farm", "the harbour"][rng.randi_range(0, 4)]
			ex = K.number("On this map, 1 cm stands for %d km (the scale bar shows km). The path to %s is %d cm long on the map. How long is it really, in km?" % [
				km, place, legs[0]], str(legs[0] * km),
				"Every centimetre on the map is %d km for real, so multiply the centimetres by %d." % [km, km],
				"%d cm × %d km = %d km." % [legs[0], km, legs[0] * km], bar)
		else:
			ask = "map"
			ex = K.number("On a map, 1 cm stands for %d km. Two towns are %d km apart. How far apart are they on the map, in cm?" % [
				km, legs[0] * km], str(legs[0]),
				"Each centimetre stands for %d km. How many lots of %d km make the real distance?" % [km, km],
				"%d km ÷ %d km = %d, so the towns are %d cm apart on the map." % [legs[0] * km, km, legs[0], legs[0]])
	elif level == 2:
		per = [100, 200, 250, 500][rng.randi_range(0, 3)]
		legs = [rng.randi_range(2, 9)]
		unit = "m"
		ex = K.number("On a map of a town, 1 cm stands for %d m. The walk to the park is %d cm long on the map. How far is it really, in metres?" % [
			per, legs[0]], str(per * legs[0]), "Each centimetre is %d m for real: multiply the centimetres by %d." % [per, per],
			"%d cm × %d m = %s m." % [legs[0], per, GenKit.fmt(per * legs[0])])
	elif rng.randf() < 0.5:
		per = [2000, 3000, 4000, 5000, 10000, 25000][rng.randi_range(0, 5)]
		var km := per / 1000
		var stops: Array[String] = ["the mill", "the bridge", "the town"]
		for i in rng.randi_range(2, 3):
			legs.append(rng.randi_range(1, 6))
		var said: Array[String] = []
		var total := 0
		for i in legs.size():
			said.append("%d cm to %s" % [legs[i], stops[i + 3 - legs.size()]])
			total += legs[i]
		ex = K.number("On a map, 1 cm stands for %d km. The road goes %s. How far is that really, in km?" % [km,
			", then ".join(said)], str(total * km),
			"Add up the centimetres of the whole route first, then change them into km with the scale.",
			"%s = %d cm. %d × %d km = %d km." % [" + ".join(legs.map(func(l: int) -> String: return str(l))), total, total,
				km, total * km])
	else:
		ratio = [25000, 50000, 100000, 200000][rng.randi_range(0, 3)]
		per = ratio / 100
		legs = [rng.randi_range(2, 9)]
		unit = "km" if ratio >= 100000 else "m"
		var real_m := per * legs[0]
		var answer := str(real_m / 1000) if unit == "km" else str(real_m)
		ex = K.number("A map's scale is 1 : %s. A lake is %d cm across on the map. How far across is it really, in %s?" % [
			GenKit.fmt(ratio), legs[0], "km" if unit == "km" else "metres"], answer,
			"1 : %s means 1 cm on the map is %s cm for real. 100 cm make 1 m, and 1,000 m make 1 km." % [GenKit.fmt(ratio),
				GenKit.fmt(ratio)],
			"1 cm is %s cm = %s m. %d × %s m = %s m%s." % [GenKit.fmt(ratio), GenKit.fmt(per), legs[0], GenKit.fmt(per),
				GenKit.fmt(real_m), " = %s km" % (real_m / 1000) if unit == "km" else ""])
	ex.data = {"m_per_cm": per, "legs": legs, "unit": unit, "ask": ask, "ratio": ratio}
	return ex


# --- Geography: countries and capitals (g4.geography.countries_capitals, europe, americas) -----------------------------

## The world's capitals. Level 1: famous capitals; level 2: a capital's country, or a country's continent; level 3:
## capitals that are not the biggest city (the biggest city is always a wrong choice).
static func world_capital(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 1:
		return _ask_capital(rng, WORLD_EASY)
	if level == 2:
		if rng.randf() < 0.5:
			return _ask_country(rng, WORLD_MORE, WORLD_MORE + WORLD_EASY)
		var with_one: Array[String] = []
		for c: String in WORLD_EASY + WORLD_MORE:
			if str(COUNTRIES[c][1]) != "":
				with_one.append(c)
		var country := with_one[rng.randi_range(0, with_one.size() - 1)]
		var continent := str(COUNTRIES[country][1])
		var wrongs: Array = CONTINENTS.filter(func(x: String) -> bool: return x != continent)
		GenKit.shuffle(rng, wrongs)
		var ex := K.choice(rng, "Which continent is %s in?" % country, continent, wrongs.slice(0, 3),
			"Picture the world map: which big piece of land is %s on? Its capital, %s, can help you remember." % [country,
				COUNTRIES[country][0]],
			"%s is in %s. Its capital is %s." % [_cap(country), continent,
				COUNTRIES[country][0]])
		ex.data = {"country": country, "ask": "continent"}
		return ex
	var countries: Array = BIGGEST.keys()
	var country := str(countries[rng.randi_range(0, countries.size() - 1)])
	var capital := str(COUNTRIES[country][0])
	var others: Array = countries.filter(func(x: String) -> bool: return x != country)
	GenKit.shuffle(rng, others)
	var wrongs: Array = [BIGGEST[country], COUNTRIES[others[0]][0], COUNTRIES[others[1]][0]]
	var ex := K.choice(rng, "What is the capital of %s?" % country, capital, wrongs,
		"The capital is where the government meets. It is not always the biggest or the most famous city.",
		"%s is the capital of %s. %s is its biggest city, but the government meets in %s." % [capital, country,
			BIGGEST[country], capital])
	ex.data = {"country": country, "ask": "biggest"}
	return ex


## Europe. Level 1: the capitals of Europe's biggest countries; level 2: more capitals; level 3: a capital's river, or a
## capital's country.
static func europe_capital(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 1:
		return _ask_capital(rng, EUROPE_EASY)
	if level == 2:
		return _ask_capital(rng, EUROPE_MORE)
	if rng.randf() < 0.5:
		return _ask_country(rng, EUROPE_MORE, EUROPE_MORE + EUROPE_EASY)
	var capitals: Array = CAPITAL_RIVERS.keys()
	var capital := str(capitals[rng.randi_range(0, capitals.size() - 1)])
	var river := str(CAPITAL_RIVERS[capital])
	var wrongs: Array = []
	for c: String in CAPITAL_RIVERS:
		var r := str(CAPITAL_RIVERS[c])
		if r != river and not wrongs.has(r):
			wrongs.append(r)
	GenKit.shuffle(rng, wrongs)
	var country := ""
	for c: String in COUNTRIES:
		if str(COUNTRIES[c][0]) == capital:
			country = c
	var ex := K.choice(rng, "Which river flows through %s, the capital of %s?" % [capital, country], river,
		wrongs.slice(0, 3), "Many capitals grew beside a river for water and boats. Picture a map of %s." % country,
		"The %s flows through %s." % [river, capital])
	ex.data = {"country": country, "ask": "river"}
	return ex


## North and South America. Level 1: the biggest countries' capitals; level 2: more capitals; level 3: a capital's
## country, or which of the two continents a country is in (Central America and the Caribbean are North America).
static func americas_capital(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level == 1:
		return _ask_capital(rng, AMERICAS_EASY)
	if level == 2:
		return _ask_capital(rng, AMERICAS_MORE)
	if rng.randf() < 0.5:
		return _ask_country(rng, AMERICAS_MORE, AMERICAS_MORE + AMERICAS_EASY)
	var all: Array[String] = AMERICAS_MORE + AMERICAS_EASY
	var country := all[rng.randi_range(0, all.size() - 1)]
	var half := str(COUNTRIES[country][1])
	var ex := K.choice(rng, "Is %s in North America or South America?" % country, half,
		["South America" if half == "North America" else "North America"],
		"The two continents meet at Panama. Countries north of Colombia, and the Caribbean islands, are in North America.",
		"%s is in %s. Its capital is %s." % [_cap(country), half, COUNTRIES[country][0]])
	ex.data = {"country": country, "ask": "half"}
	return ex


# --- Geography: fieldwork (g4.geography.fieldwork_survey) --------------------------------------------------------------

## A 10-minute traffic count on a bar graph. Level 1: how many of one kind, or which kind passed most; level 2: how many
## more, or how many altogether; level 3: how many in an hour at the same rate, or altogether.
static func survey_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var counts := {}
	for _try in 50:
		counts = {"cars": rng.randi_range(8, 20), "vans": rng.randi_range(2, 10), "bikes": rng.randi_range(1, 12),
			"buses": rng.randi_range(1, 6), "lorries": rng.randi_range(1, 8)}
		if _one_top(counts):
			break
	var bars: Array = []
	for k: String in VEHICLES:
		bars.append([k, counts[k]])
	var picture := {"kind": "bar_graph", "bars": bars, "step": 2, "top": 20, "name": "Vehicles in 10 minutes"}
	var who: String = PEOPLE.keys()[rng.randi_range(0, PEOPLE.size() - 1)]
	var head := "%s's 10-minute traffic count is on the bar graph. " % who
	var total := 0
	var sums: Array[String] = []
	for k: String in VEHICLES:
		total += int(counts[k])
		sums.append(str(counts[k]))
	var roll := rng.randf()
	var ex: Dictionary
	var d := {"counts": counts}
	if level == 1 and roll < 0.5:
		var a := VEHICLES[rng.randi_range(0, 4)]
		ex = K.number(head + "How many %s passed?" % a, str(counts[a]),
			"Find the %s bar, then read across from its top to the scale. A bar can end halfway between two lines." % a,
			"The %s bar reaches %d, so %d %s passed." % [a, counts[a], counts[a], a], picture)
		d.merge({"ask": "how_many", "a": a})
	elif level == 1:
		var most := _top(counts)
		ex = K.choice(rng, head + "Which kind of vehicle passed most often?", most,
			VEHICLES.filter(func(v: String) -> bool: return v != most),
			"Look for the tallest bar.", "The %s bar is the tallest (%d), so %s passed most often." % [most, counts[most],
				most], picture)
		d.merge({"ask": "most"})
	elif level == 2 and roll < 0.5:
		var pair: Array[String] = []
		for _try in 50:
			pair = [VEHICLES[rng.randi_range(0, 4)], VEHICLES[rng.randi_range(0, 4)]]
			if int(counts[pair[0]]) > int(counts[pair[1]]):
				break
		if int(counts[pair[0]]) <= int(counts[pair[1]]):
			pair = [_top(counts), "buses" if _top(counts) != "buses" else "vans"]
		var diff := int(counts[pair[0]]) - int(counts[pair[1]])
		ex = K.number(head + "How many more %s than %s passed?" % [pair[0], pair[1]], str(diff),
			"Read both bars, then take the smaller number from the bigger one.",
			"%d %s − %d %s = %d more %s." % [counts[pair[0]], pair[0], counts[pair[1]], pair[1], diff, pair[0]], picture)
		d.merge({"ask": "more", "a": pair[0], "b": pair[1]})
	elif level == 3 and roll < 0.5:
		var a := VEHICLES[rng.randi_range(0, 4)]
		ex = K.number(head + "If the traffic stayed the same, how many %s would pass in a whole hour?" % a,
			str(int(counts[a]) * 6), "An hour is 60 minutes: how many lots of 10 minutes is that?",
			"60 minutes is 6 lots of 10 minutes. %d × 6 = %d %s in an hour." % [counts[a], int(counts[a]) * 6, a], picture)
		d.merge({"ask": "hour", "a": a})
	else:
		ex = K.number(head + "How many vehicles passed altogether?", str(total),
			"Read every bar and add them all. Add the biggest first, or make tens.",
			"%s = %d vehicles." % [" + ".join(sums), total], picture)
		d.merge({"ask": "total"})
	ex.data = d
	return ex


## A week's weather record in a table (°C and mm of rain). Level 1: the warmest day, or one day's rain; level 2: how
## much warmer one day was, or the week's rain; level 3: a winter week: the difference between the warmest and the
## coldest temperature, across 0 °C.
static func weather_table(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var temps: Array[int] = []
	var rain: Array[int] = []
	for _try in 100:
		temps.clear()
		rain.clear()
		for i in DAYS.size():
			temps.append(rng.randi_range(-6, 7) if level == 3 else rng.randi_range(6, 24))
			rain.append(rng.randi_range(0, 12))
		if temps.count(temps.max()) == 1 and temps.count(temps.min()) == 1 and (level < 3 or temps.min() < 0 and temps.max() > 0):
			break
	var rows: Array = [["day", "°C", "rain (mm)"]]
	for i in DAYS.size():
		rows.append([DAYS[i], str(temps[i]).replace("-", "−"), str(rain[i])])
	var picture := {"kind": "table", "rows": rows}
	var head := "Bram's weather record for a week is in the table. "
	var hot := temps.find(temps.max())
	var cold := temps.find(temps.min())
	var ex: Dictionary
	var d := {"days": DAYS.duplicate(), "temps": temps, "rain": rain}
	var roll := rng.randf()
	if level == 1 and roll < 0.5:
		ex = K.choice(rng, head + "Which day was the warmest?", DAYS[hot], DAYS.filter(func(x: String) -> bool:
			return x != DAYS[hot]), "Look down the °C column for the highest number.",
			"The highest temperature is %d °C, on %s." % [temps[hot], DAYS[hot]], picture)
		d.merge({"ask": "warmest"})
	elif level == 1:
		var i := rng.randi_range(0, DAYS.size() - 1)
		ex = K.number(head + "How much rain fell on %s, in mm?" % DAYS[i], str(rain[i]),
			"Find the row for %s, then read across to the rain column." % DAYS[i],
			"On %s the rain gauge showed %d mm." % [DAYS[i], rain[i]], picture)
		d.merge({"ask": "rain_on", "a": DAYS[i]})
	elif level == 2 and roll < 0.5:
		var i := hot
		var j := rng.randi_range(0, DAYS.size() - 1)
		while j == i:
			j = rng.randi_range(0, DAYS.size() - 1)
		if rng.randf() < 0.5:   # not always the warmest day: any day warmer than another
			for _try in 20:
				var x := rng.randi_range(0, DAYS.size() - 1)
				var y := rng.randi_range(0, DAYS.size() - 1)
				if temps[x] > temps[y]:
					i = x
					j = y
					break
		ex = K.number(head + "How much warmer was %s than %s, in °C?" % [DAYS[i], DAYS[j]], str(temps[i] - temps[j]),
			"Find both temperatures, then take the lower one from the higher one.",
			"%d °C − %d °C = %d °C warmer." % [temps[i], temps[j], temps[i] - temps[j]], picture)
		d.merge({"ask": "warmer", "a": DAYS[i], "b": DAYS[j]})
	elif level == 2:
		var total := 0
		var said: Array[String] = []
		for r in rain:
			total += r
			said.append(str(r))
		ex = K.number(head + "How much rain fell in the whole week, in mm?", str(total),
			"Add the rain column. Look for numbers that make 10 to add them quickly.",
			"%s = %d mm." % [" + ".join(said), total], picture)
		d.merge({"ask": "week_rain"})
	else:
		var diff := temps[hot] - temps[cold]
		ex = K.number(head + "What is the difference between the warmest and the coldest temperature, in °C?", str(diff),
			"Count from the coldest temperature up to 0, then on from 0 to the warmest.",
			"From %s °C up to 0 is %d; from 0 to %d °C is %d more. %d + %d = %d °C." % [str(temps[cold]).replace("-", "−"),
				-temps[cold], temps[hot], temps[hot], -temps[cold], temps[hot], diff], picture)
		d.merge({"ask": "range"})
	ex.data = d
	return ex


# --- Citizenship: smart spending, adverts, ways to pay (gold with decimals from grade 4) --------------------------------

## Level 1: the same thing at two stalls: how much is saved at the cheaper one; level 2: which pack is better value
## (whole prices for one); level 3: better value with decimal prices, or the price for one.
static func best_value(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1:
		var good: Array = GOODS[rng.randi_range(0, GOODS.size() - 1)]
		var pa := rng.randi_range(4, 15)
		var pb := pa
		while pb == pa:
			pb = rng.randi_range(3, 15)
		ex = K.number("A %s costs %s gold at Tilly's stall and %s gold at Bram's stall. It is the same %s. How much do you save at the cheaper stall?" % [
			good[0], pa, pb, good[0]], str(absi(pa - pb)),
			"Find the difference between the two prices: take the smaller price from the bigger one.",
			"%d − %d = %d gold saved at %s stall." % [maxi(pa, pb), mini(pa, pb), absi(pa - pb),
				"Tilly's" if pa < pb else "Bram's"])
		ex.data = {"ask": "save", "a": {"n": 1, "cents": pa * 100}, "b": {"n": 1, "cents": pb * 100}}
		return ex
	var food := FOODS[rng.randi_range(0, FOODS.size() - 1)]
	var na: int = [2, 3, 4, 5][rng.randi_range(0, 3)]
	var nb: int = [6, 8, 10][rng.randi_range(0, 2)]
	var each: Array[int] = [20, 25, 30, 40, 45, 50, 60, 75, 80, 90]
	if level == 2:
		each = [100, 200, 300, 400, 500, 600]
	var ia := rng.randi_range(0, each.size() - 1)   # close prices for one, so working them out matters
	var ib: int = ia + [-2, -1, 1, 2][rng.randi_range(0, 3)]
	if ib < 0 or ib >= each.size():
		ib = ia + 1 if ia + 1 < each.size() else ia - 1
	var ua := each[ia]
	var ub := each[ib]
	var a := {"n": na, "cents": na * ua}
	var b := {"n": nb, "cents": nb * ub}
	if level == 3 and rng.randf() < 0.4:
		ex = K.number("A pack of %d %s costs %s gold. How much is that for one?" % [nb, food, _gold(nb * ub)], _gold(ub),
			"Share the price equally: divide it by how many are in the pack. Change gold into hundredths if it helps.",
			"%s ÷ %d = %s gold for one." % [_gold(nb * ub), nb, _gold(ub)])
		ex.data = {"ask": "each", "a": b, "b": b}
		return ex
	var better := na if ua < ub else nb
	ex = K.choice(rng, "A pack of %d %s costs %s gold. A pack of %d costs %s gold. Which pack is better value?" % [na, food,
		_gold(na * ua), nb, _gold(nb * ub)], "the pack of %d" % better,
		["the pack of %d" % (nb if better == na else na), "both are the same value"],
		"Work out the price for one in each pack: divide the price by how many are in it.",
		"For one: %s ÷ %d = %s gold, and %s ÷ %d = %s gold. The pack of %d costs less for each one (if you will use them all)." % [
			_gold(na * ua), na, _gold(ua), _gold(nb * ub), nb, _gold(ub), better])
	ex.data = {"ask": "better", "a": a, "b": b}
	return ex


## Level 1: change from whole gold; level 2: change with decimals (count on to the next whole gold, then on); level 3: a
## bank account's balance after paying by card and by phone (the money is real, though no coins move).
static func change_due(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = PEOPLE.keys()[rng.randi_range(0, PEOPLE.size() - 1)]
	var p: Array = PEOPLE[who]
	var good: Array = GOODS[rng.randi_range(0, GOODS.size() - 1)]
	var ex: Dictionary
	if level == 3:
		var start := rng.randi_range(20, 60) * 100
		var pay: Array[int] = []
		for _try in 50:
			pay = [rng.randi_range(30, 300) * 5, rng.randi_range(30, 300) * 5]
			if pay[0] + pay[1] < start:
				break
		if pay[0] + pay[1] >= start:
			pay = [640, 1275]
			start = 3000
		var after := start - pay[0]
		ex = K.number("%s has %s gold in %s bank account. %s pays %s gold by card, then %s gold with %s phone. How much is left in the account?" % [
			who, _gold(start), p[1], str(p[0]).capitalize(), _gold(pay[0]), _gold(pay[1]), p[1]], _gold(after - pay[1]),
			"Take away one payment at a time. Card and phone payments take real money out of the account.",
			"%s − %s = %s, then %s − %s = %s gold left, though no coins moved." % [_gold(start), _gold(pay[0]), _gold(after),
				_gold(after), _gold(pay[1]), _gold(after - pay[1])])
		ex.data = {"start": start, "payments": pay}
		return ex
	var price := rng.randi_range(1, 19) * 100
	if level == 2:
		price = rng.randi_range(1, 18) * 100 + [10, 25, 40, 50, 60, 75, 90][rng.randi_range(0, 6)]
	var notes: Array[int] = [500, 1000, 2000]
	var paid := 2000
	for n in notes:
		if n > price:
			paid = n
			break
	if rng.randf() < 0.3 and paid < 2000:
		paid = 2000
	var change := paid - price
	var explain := "%s − %s = %s gold change." % [_gold(paid), _gold(price), _gold(change)]
	var hint := "Take the price away from the gold paid, or count on from the price up to the gold paid."
	if price % 100 != 0:
		var up := 100 - price % 100
		var next_whole := price + up
		explain = "Count on: from %s to %s is %s, and from %s to %s is %s. %s + %s = %s gold change." % [_gold(price),
			_gold(next_whole), _gold(up), _gold(next_whole), _gold(paid), _gold(paid - next_whole), _gold(up),
			_gold(paid - next_whole), _gold(change)]
		hint = "Count on from the price: first up to the next whole gold, then on to the gold paid."
	ex = K.number("%s buys a %s for %s gold and pays with %s gold. How much change does %s get?" % [who, good[0], _gold(price),
		_gold(paid), p[0]], _gold(change), hint, explain)
	ex.data = {"price": price, "paid": paid}
	return ex


## Adverts' deals. Level 1: "Was 12 gold, now 9 gold!": how much cheaper; level 2: "Buy 2, get 1 free": what you pay;
## level 3: a deal against another stall's price, for the number you need (a deal only helps if you need that many).
static func deal_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var good: Array = GOODS[rng.randi_range(0, GOODS.size() - 1)]
	var ex: Dictionary
	if level == 1:
		var was := rng.randi_range(6, 20)
		var now := was - rng.randi_range(1, was - 2)
		ex = K.number("An advert says: 'Was %d gold, now %d gold!' How much cheaper is it now?" % [was, now], str(was - now),
			"Find the difference between the old price and the new price.",
			"%d − %d = %d gold cheaper. Check: do you need it at all?" % [was, now, was - now])
		ex.data = {"ask": "was_now", "was": was * 100, "now": now * 100}
		return ex
	var buy := rng.randi_range(2, 3)
	var price := rng.randi_range(2, 9) * 100
	if level == 2:
		var need := buy + 1 if rng.randf() < 0.7 else 2 * (buy + 1)
		var paid := need - need / (buy + 1)
		ex = K.number("%s cost %s gold each. The advert says 'Buy %d, get 1 free!' How much do %d %s cost with the deal?" % [
			str(good[1]).capitalize(), _gold(price), buy, need, good[1]], _gold(paid * price),
			"In every group of %d, one is free: you pay for %d of each %d." % [buy + 1, buy, buy + 1],
			"%d %s is %d group%s of %d, so you pay for %d: %d × %s = %s gold." % [need, good[1], need / (buy + 1),
				"" if need == buy + 1 else "s", buy + 1, paid, paid, _gold(price), _gold(paid * price)])
		ex.data = {"ask": "deal", "buy": buy, "need": need, "price": price}
		return ex
	var need := buy + 1 if rng.randf() < 0.7 else 1
	var other := price
	var a := 0
	var b := 0
	for _try in 50:
		other = price - rng.randi_range(1, 6) * 25
		a = (need - need / (buy + 1)) * price
		b = need * other
		if other > 0 and a != b:
			break
	if other <= 0 or a == b:
		price = 600
		other = 450
		need = buy + 1
		a = (need - need / (buy + 1)) * price
		b = need * other
	var cheaper := "Stall A" if a < b else "Stall B"
	var paid_a := need - need / (buy + 1)
	ex = K.number("Stall A sells %s at %s gold each: buy %d, get 1 free. Stall B sells them at %s gold each, no deal. You need %d. How much do you save at the cheaper stall?" % [
		good[1], _gold(price), buy, _gold(other), need], _gold(absi(a - b)),
		"Work out what you would really pay at each stall for the number you need, then find the difference.",
		"Stall A: pay for %d, %d × %s = %s gold. Stall B: %d × %s = %s gold. %s is cheaper by %s gold." % [paid_a, paid_a,
			_gold(price), _gold(a), need, _gold(other), _gold(b), cheaper, _gold(absi(a - b))])
	ex.data = {"ask": "compare", "buy": buy, "need": need, "price": price, "other": other}
	return ex


# --- Citizenship: who runs a town? deciding together (g4.citizenship.local_government, deciding_together) --------------

## A town's money. Level 1: two costs added, or what is left after one; level 2: a cost shared equally between
## families; level 3: a budget: what is left after two services.
static func town_budget(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 1 and rng.randf() < 0.5:
		var a := rng.randi_range(10, 60) * 10
		var b := rng.randi_range(10, 60) * 10
		ex = K.number("The town spends %d gold on the library and %d gold on the park. How much is that altogether?" % [a, b],
			str(a + b), "Add the hundreds, then the tens.", "%d + %d = %d gold." % [a, b, a + b])
		ex.data = {"ask": "sum", "a": a, "b": b}
	elif level == 1:
		var total := rng.randi_range(5, 10) * 100
		var a := rng.randi_range(11, total / 10 - 5) * 10
		ex = K.number("The council has %d gold. It spends %d gold mending roads. How much is left?" % [total, a],
			str(total - a), "Take away the money spent from the money the council had.",
			"%d − %d = %d gold left." % [total, a, total - a])
		ex.data = {"ask": "left", "total": total, "a": a}
	elif level == 2:
		var families: int = [10, 20, 25, 40, 50, 100][rng.randi_range(0, 5)]
		var each := rng.randi_range(2, 30)
		var what: String = ["playground", "bus shelter", "footbridge", "skate park", "library roof"][rng.randi_range(0, 4)]
		ex = K.number("A new %s costs %s gold. %d families share the cost equally. How much does each family pay?" % [what,
			GenKit.fmt(families * each), families], str(each),
			"Sharing equally is dividing: the cost ÷ the number of families.",
			"%s ÷ %d = %d gold for each family. Together they pay for something none could buy alone." % [
				GenKit.fmt(families * each), families, each])
		ex.data = {"ask": "share", "cost": families * each, "families": families}
	else:
		var total: int = [1000, 1500, 2000, 2500, 3000][rng.randi_range(0, 4)]
		var a := rng.randi_range(8, total / 50) * 25
		var b := rng.randi_range(4, (total - a) / 25 - 4) * 25
		ex = K.number("The council has %s gold of taxes. It spends %s gold on roads and %s gold on bins and recycling. How much is left for parks and libraries?" % [
			GenKit.fmt(total), GenKit.fmt(a), GenKit.fmt(b)], str(total - a - b),
			"Take away one cost at a time, or add the two costs first and take the total away.",
			"%s + %s = %s spent. %s − %s = %s gold left." % [GenKit.fmt(a), GenKit.fmt(b), GenKit.fmt(a + b),
				GenKit.fmt(total), GenKit.fmt(a + b), GenKit.fmt(total - a - b)])
		ex.data = {"ask": "budget", "total": total, "a": a, "b": b}
	return ex


## A class votes for its next build (a bar graph). Level 1: the winner; level 2: how many more votes, or how many
## voted; level 3: did the winner get a majority (more than half)? or how many votes a majority needs.
static func vote_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 3 if level < 3 else rng.randi_range(3, 4)
	var names := _pick(rng, BUILDS, n)
	var want_majority := rng.randf() < 0.5
	var votes := {}
	var ask := "winner"
	var roll := rng.randf()
	if level == 2:
		ask = "more" if roll < 0.5 else "total"
	elif level == 3:
		ask = "majority" if roll < 0.5 else "need"
	for _try in 200:
		votes = {}
		for k in names:
			votes[k] = rng.randi_range(1, 14)
		if not _one_top(votes):
			continue
		var total := 0
		for k: String in votes:
			total += int(votes[k])
		if ask != "majority" or (int(votes[_top(votes)]) * 2 > total) == want_majority:
			break
	var bars: Array = []
	var total := 0
	var said: Array[String] = []
	for k in names:
		bars.append([k, votes[k]])
		total += int(votes[k])
		said.append(str(votes[k]))
	var picture := {"kind": "bar_graph", "bars": bars, "step": 2, "top": 16, "name": "Votes"}
	var top := _top(votes)
	var head := "The class voted for its next build, one vote each. "
	var ex: Dictionary
	var d := {"votes": votes, "ask": ask}
	match ask:
		"winner":
			ex = K.choice(rng, head + "Which build won the vote?", top, names.filter(func(x: String) -> bool: return x != top),
				"The winner is the choice with the most votes: the tallest bar.",
				"The %s got %d votes, more than any other, so it won." % [top, votes[top]], picture)
		"more":
			var others := names.filter(func(x: String) -> bool: return x != top)
			var a := str(others[rng.randi_range(0, others.size() - 1)])
			ex = K.number(head + "How many more votes did the %s get than the %s?" % [top, a], str(int(votes[top]) - int(votes[a])),
				"Read both bars, then take the smaller number from the bigger one.",
				"%d − %d = %d more votes." % [votes[top], votes[a], int(votes[top]) - int(votes[a])], picture)
			d.a = a
		"total":
			ex = K.number(head + "How many children voted altogether?", str(total),
				"Each child voted once, so add up all the votes.", "%s = %d children." % [" + ".join(said), total], picture)
		"majority":
			var has := int(votes[top]) * 2 > total
			ex = K.truefalse(head + "The %s won a majority: more than half of all the votes." % top, has,
				"Add up all the votes and find half. A majority is more than half.",
				"%s = %d votes; half of %d is %s. The %s got %d, which is %s half, so %s." % [" + ".join(said), total, total,
					_half(total), top, votes[top], "more than" if has else "not more than",
					"it is a majority" if has else "it won with the most votes but no majority"], picture)
		_:
			ex = K.number(head + "How many votes would one build need for a majority (more than half)?", str(total / 2 + 1),
				"Add up the votes to find how many children voted. A majority is the smallest number bigger than half.",
				"%s = %d voters. Half of %d is %s, so a majority is %d votes." % [" + ".join(said), total, total, _half(total),
					total / 2 + 1], picture)
	ex.data = d
	return ex


# --- Helpers ------------------------------------------------------------------------------------------------------------

static func _ask_capital(rng: RandomNumberGenerator, pool: Array[String]) -> Dictionary:
	var country := pool[rng.randi_range(0, pool.size() - 1)]
	var capital := str(COUNTRIES[country][0])
	var wrongs: Array = []
	for c in pool:
		if c != country:
			wrongs.append(str(COUNTRIES[c][0]))
	GenKit.shuffle(rng, wrongs)
	var continent := str(COUNTRIES[country][1])
	var ex := K.choice(rng, "What is the capital of %s?" % country, capital, wrongs.slice(0, 3),
		"A capital is the city where a country's government meets. Which of these cities is in %s?" % country,
		"%s is the capital of %s%s." % [capital, country, "" if continent == "" else ", in " + continent])
	ex.data = {"country": country, "ask": "capital"}
	return ex


static func _ask_country(rng: RandomNumberGenerator, pool: Array[String], choices_from: Array[String]) -> Dictionary:
	var country := pool[rng.randi_range(0, pool.size() - 1)]
	var capital := str(COUNTRIES[country][0])
	var wrongs: Array = choices_from.filter(func(c: String) -> bool: return c != country)
	GenKit.shuffle(rng, wrongs)
	var ex := K.choice(rng, "%s is the capital of which country?" % capital, _cap(country), wrongs.slice(0, 3).map(
		func(c: String) -> String: return _cap(c)),
		"Think where %s is on the map, or which language its people speak." % capital,
		"%s is the capital of %s." % [capital, country])
	ex.data = {"country": country, "ask": "country"}
	return ex


## "the United Kingdom" -> "The United Kingdom" (a choice or a sentence's start).
static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


## A year as the lessons write it: "about 3100 BC", "196 BC", "AD 394", "10,000 BC".
static func _year_text(y: int, about: bool) -> String:
	var t := "%s BC" % _digits(absi(y)) if y < 0 else "AD %s" % _digits(y)
	return ("about " + t) if about else t


## A year's digits: 3100, but 10,000.
static func _digits(n: int) -> String:
	return str(n) if n < 10000 else GenKit.fmt(n)


## Gold in hundredths as the lessons write it: 250 -> "2.50", 300 -> "3".
static func _gold(cents: int) -> String:
	return str(cents / 100) if cents % 100 == 0 else "%d.%02d" % [cents / 100, cents % 100]


static func _half(n: int) -> String:
	return str(n / 2) if n % 2 == 0 else "%d½" % (n / 2)


## "2 corner wedges and 3 upright wedges"
static func _wedges(n: int) -> String:
	var parts: Array[String] = []
	if n / 10 > 0:
		parts.append("%d corner wedge%s" % [n / 10, "" if n / 10 == 1 else "s"])
	if n % 10 > 0:
		parts.append("%d upright wedge%s" % [n % 10, "" if n % 10 == 1 else "s"])
	return " and ".join(parts)


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
