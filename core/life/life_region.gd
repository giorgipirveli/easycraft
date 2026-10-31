class_name LifeRegion
extends RefCounted
## Owner #112 (docs/design/life-skills.md §6, "country-aware"): the region a grown-up sets on Life's page for grown-ups:
## the emergency number the Experiences dial and say (for an ambulance and the fire service), and which side cars drive
## on (Safe Streets' "look left, right, left"). A short list (the L1 ruling): the device's locale picks the default; an
## unknown country is Europe's 112, and the grown-up can change it. The facts and their sources:
## docs/devlog/parts/life-l1.md ("The region").

const DEFAULT := "eu"
## id -> {name (as a sentence says it), number, drive}. In the order the grown-ups' page lists them.
const REGIONS := {
	"ge": {"name": "Georgia", "number": "112", "drive": "right"},
	"eu": {"name": "Europe", "number": "112", "drive": "right"},
	"ie": {"name": "Ireland, Malta or Cyprus", "number": "112", "drive": "left"},
	"uk": {"name": "the UK", "number": "999", "drive": "left"},
	"us": {"name": "the US", "number": "911", "drive": "right"},
	"ca": {"name": "Canada", "number": "911", "drive": "right"},
	"au": {"name": "Australia", "number": "000", "drive": "left"},
	"nz": {"name": "New Zealand", "number": "111", "drive": "left"},
	"in": {"name": "India", "number": "112", "drive": "left"},
	"jp": {"name": "Japan", "number": "119", "drive": "left"},
}
## A locale's country (ISO 3166) -> its region; the European Union and its neighbours that dial 112 and drive on the
## right are "eu".
const COUNTRIES := {"GE": "ge", "GB": "uk", "UK": "uk", "IE": "ie", "MT": "ie", "CY": "ie", "US": "us", "CA": "ca",
	"AU": "au", "NZ": "nz", "IN": "in", "JP": "jp"}
const EUROPE_112: Array[String] = ["AT", "BE", "BG", "HR", "CZ", "DK", "EE", "FI", "FR", "DE", "GR", "HU", "IT", "LV",
	"LT", "LU", "NL", "PL", "PT", "RO", "SK", "SI", "ES", "SE", "NO", "IS", "CH", "LI", "AD", "MC", "SM", "AL", "BA",
	"ME", "MK", "RS", "MD", "UA", "TR", "AZ"]
const DIGITS: Array[String] = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine"]
## Life L3a (owner #118, the brief: "Georgia's mountains make the earthquake row matter: the region's own guidance where
## it exists"): why the earthquake drill matters here, in the region's own words (a sentence; unknown: the default's).
const QUAKE_WORDS := {
	"ge": "In Georgia the Caucasus mountains are still growing, so the ground can shake here.",
	"jp": "In Japan the ground shakes often, so everyone practises.",
	"nz": "In New Zealand the ground shakes often, so everyone practises.",
	"us": "In parts of the US, like California and Alaska, the ground can shake.",
	"ca": "In parts of Canada, like British Columbia, the ground can shake.",
	"in": "In India the Himalayas are still growing, so the ground can shake there.",
}
const QUAKE_DEFAULT := "In many places the ground can sometimes shake, so it's good to practise."
## Life L3b (owner #118, the brief: "wild animals in the hills (Georgia's mountains)"): the wild animals a child may meet
## out walking in the region, in a sentence (Safe with Animals' {wild_where}; unknown: the default's).
const WILD_WORDS := {
	"ge": "In Georgia's mountains live brown bears, wolves and wild boar, and big shepherd dogs guard the flocks of sheep.",
	"us": "In parts of the US live bears, mountain lions and rattlesnakes.",
	"ca": "In parts of Canada live bears, cougars and moose.",
	"au": "In Australia's bush live snakes, spiders and kangaroos.",
	"nz": "New Zealand has no wild snakes, but cows, sheep and wild pigs live in its hills.",
	"uk": "In the UK's hills live cows, horses, deer and adders, the only wild snake there with venom.",
	"ie": "In the hills live cows, horses, deer and wild goats.",
	"in": "In India live monkeys and snakes, and in the forests elephants and leopards.",
	"jp": "In Japan's mountains live bears, wild boar and monkeys.",
}
const WILD_DEFAULT := "In wild places live animals that need their own space."
## Life L3c (owner #112, the brief: "Georgia's own: Tbilisi's metro has two lines"): the region's own metro or underground,
## in a sentence (Find Your Way's {metro_where}; unknown: the default's). The game's own metro is its own, named plainly.
const METRO_WORDS := {
	"ge": "Tbilisi's metro has two lines too, and they meet at Station Square, where you change.",
	"uk": "London's Underground has many lines; its map shows where they meet, so you know where to change.",
	"us": "Big cities like New York have subways with many lines; the map shows where to change.",
	"ca": "Toronto and Montreal have metros with several lines; the map shows where to change.",
	"jp": "Tokyo has many metro lines; each has its own colour and letter on the map.",
	"in": "Delhi's metro has many lines, each with its own colour on the map.",
	"au": "Sydney's trains and its metro have lines of their own colours on the map.",
	"eu": "Many cities in Europe have metros with lines of different colours; the map shows where to change.",
}
const METRO_DEFAULT := "Many big cities have metros with lines of different colours; the map shows where to change."
## Life L3c (owner #112, the brief: "the region's bins as a ruling, with the sources"): where the region's own recycling
## bins differ, in a sentence (Home Helper's {bins_where}; unknown: the default's). The game's practice bins are its own.
const BINS_WORDS := {
	"ge": "In Georgia, more and more places have their own bins for plastic bottles or for paper: look for them near you.",
	"uk": "In the UK each council has its own bins and colours: your grown-up knows which is which.",
	"ie": "In Ireland the bins have their own colours: your grown-up knows which is which.",
	"us": "In the US each town has its own bins and colours: your grown-up knows which is which.",
	"eu": "Bins and their colours differ from town to town: your grown-up knows which is which.",
}
const BINS_DEFAULT := "Bins and their colours differ from place to place: your grown-up knows which is which."


static func ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in REGIONS:
		out.append(id)
	return out


static func valid(id: String) -> bool:
	return REGIONS.has(id)


## The region's entry (the default's for an unknown id).
static func of(id: String) -> Dictionary:
	return REGIONS.get(id, REGIONS[DEFAULT])


static func number(id: String) -> String:
	return str(of(id).number)


static func region_name(id: String) -> String:
	return str(of(id).name)


static func drive(id: String) -> String:
	return str(of(id).drive)


## Life L3a: the region's own sentence on earthquakes (Earth and Weather's {quake_where}).
static func quake_words(id: String) -> String:
	return str(QUAKE_WORDS.get(id, QUAKE_DEFAULT))


## Life L3b: the region's own sentence on the wild animals out walking (Safe with Animals' {wild_where}).
static func wild_words(id: String) -> String:
	return str(WILD_WORDS.get(id, WILD_DEFAULT))


## Life L3c: the region's own sentence on its metro (Find Your Way's {metro_where}).
static func metro_words(id: String) -> String:
	return str(METRO_WORDS.get(id, METRO_DEFAULT))


## Life L3c: the region's own sentence on its recycling bins (Home Helper's {bins_where}).
static func bins_words(id: String) -> String:
	return str(BINS_WORDS.get(id, BINS_DEFAULT))


## At the kerb, look first the way the nearest cars come from.
static func look_order(id: String) -> String:
	return "left, right, left" if drive(id) == "right" else "right, left, right"


## Owner #112, Safe Streets: the kerb drill's sides in order (the near lane's cars come from the first).
static func look_sides(id: String) -> Array[String]:
	if drive(id) == "right":
		return ["left", "right", "left"] as Array[String]
	return ["right", "left", "right"] as Array[String]


## The unit of the practice street's speed sign: the UK and the US sign miles an hour (their highway codes), the others
## kilometres an hour.
static func speed_unit(id: String) -> String:
	return "mph" if id in ["uk", "us"] else "km/h"


## The practice street's limit: a school street's 30 km/h, or 20 mph (a ruling: the game claims no national limit).
static func speed_limit(id: String) -> int:
	return 20 if speed_unit(id) == "mph" else 30


## The region for a device's locale ("ka_GE", "en-NZ"); DEFAULT when it names no country we know.
static func from_locale(locale: String) -> String:
	var parts := locale.replace("-", "_").split("_")
	if parts.size() < 2:
		return DEFAULT
	var country := parts[1].to_upper().left(2)
	if COUNTRIES.has(country):
		return COUNTRIES[country]
	return "eu" if EUROPE_112.has(country) else DEFAULT


## The region to use: the grown-up's choice, else the device's.
static func resolve(chosen: String, locale: String) -> String:
	return chosen if valid(chosen) else from_locale(locale)


## The region of this device and profile now (the grown-up's choice, else OS.get_locale()).
static func current(chosen: String) -> String:
	return resolve(chosen, OS.get_locale())


## "112" -> "one one two" (a number read digit by digit, as an operator wants it).
static func spoken(digits: String) -> String:
	var words: Array[String] = []
	for ch in digits:
		if ch.is_valid_int():
			words.append(DIGITS[int(ch)])
	return " ".join(words)


## The play phone's keys to press for a number, in order.
static func keys(digits: String) -> Array[String]:
	var out: Array[String] = []
	for ch in digits:
		if ch.is_valid_int():
			out.append("key_" + ch)
	return out
