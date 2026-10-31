extends GutTest
## Owner #70 and #73, grade 6 history, geography and citizenship (G6HumanitiesGen, "g6h"): centuries, a medieval
## village's three fields, years apart and anniversaries, events in order, al-Khwarizmi's word puzzles, salt caravans,
## quipu cords, the harvest after the Black Death; population density and change, cities, job sectors, grid references,
## contours, map scales, climate graphs, rivers, places in Africa and Asia, a map in layers; the three jobs of government,
## seats and majorities, disagreeing well, take-home pay, compound interest, insurance, scams and a week's footprint.
## Each generator's answer is worked out again here from the exercise's `data` (and this file's own facts, typed apart
## from the generator's tables), for many seeds and every level, and every exercise must be valid (ExerciseCheck, the
## picture's own check).

const SEEDS := 80
## The medieval events and their years (as the lessons give them).
const EVENTS := {
	"Constantinople becomes Rome's new capital": 330, "The Roman Empire splits for good": 395,
	"The Roman army leaves Britain": 410, "The Western Roman Empire ends": 476, "Hagia Sophia is finished": 537,
	"The Tang dynasty begins": 618, "Baghdad is founded": 762, "Vikings raid Lindisfarne": 793,
	"Al-Khwarizmi's algebra book": 820, "The oldest dated printed book": 868, "Alfred becomes king of Wessex": 871,
	"Alfred wins at Edington": 878, "The Song dynasty begins": 960, "Vikings reach North America": 1000,
	"The Battle of Hastings": 1066, "The Domesday Book is made": 1086, "Shen Kuo describes the compass": 1088,
	"Minamoto Yoritomo becomes shogun": 1192, "Magna Carta is sealed": 1215, "Sundiata founds the Mali Empire": 1235,
	"Simon de Montfort's parliament": 1265, "Mansa Musa travels to Mecca": 1324, "Tenochtitlan is founded": 1325,
	"The Black Death reaches England": 1348, "The Peasants' Revolt": 1381, "Pachacuti begins the Inca Empire": 1438,
	"Constantinople falls to the Ottomans": 1453,
	"The first Olympic Games": -776, "Rome is founded, says the legend": -753, "Rome becomes a republic": -509,
	"Julius Caesar lands in Britain": -55, "Augustus becomes Rome's first emperor": -27,
}
## The three fields' turn.
const TURN: Array[String] = ["wheat", "beans", "nothing: it rests"]
const SECTOR_OF := {"farmer": "primary", "fisher": "primary", "miner": "primary", "forester": "primary",
	"quarry worker": "primary", "shepherd": "primary", "car factory worker": "secondary", "builder": "secondary",
	"steelworker": "secondary", "shipbuilder": "secondary", "furniture maker": "secondary", "brickmaker": "secondary",
	"teacher": "tertiary", "nurse": "tertiary", "shop assistant": "tertiary", "bus driver": "tertiary",
	"hairdresser": "tertiary", "firefighter": "tertiary", "research scientist": "quaternary",
	"medical researcher": "quaternary", "data scientist": "quaternary", "robot designer": "quaternary"}
const SYMBOL_OF := {"worship": "a place of worship", "school": "a school", "farm": "a farm", "car_park": "a car park",
	"campsite": "a campsite", "viewpoint": "a viewpoint", "castle": "a castle"}
const RIVER_GROUP := {"waterfall": "upper course", "gorge": "upper course", "V-shaped valley": "upper course",
	"interlocking spurs": "upper course", "rapids": "upper course", "delta": "lower course", "estuary": "lower course",
	"levee": "lower course", "wide floodplain": "lower course",
	"the outside of a bend wears away": "erosion", "a plunge pool gets deeper": "erosion",
	"a waterfall moves back upstream": "erosion", "a gorge gets longer": "erosion", "a valley gets deeper": "erosion",
	"sand piles up inside a bend": "deposition", "a delta grows out into the sea": "deposition",
	"a levee builds up in a flood": "deposition", "mud settles on a floodplain": "deposition"}
const PROCESS_OF := {"The force of the water pushes into cracks and breaks the rock.": "hydraulic action",
	"Stones carried by the river scrape the bed and banks.": "abrasion",
	"Stones knock into each other and become smaller and rounder.": "attrition",
	"Some rocks, such as limestone, dissolve in the water.": "solution",
	"Big boulders roll along the river bed.": "traction", "Small stones bounce along the river bed.": "saltation",
	"Fine mud is carried along in the water.": "suspension"}
## Places to the nearest degree: [lat (N +), long (E +)].
const PLACES := {"Cairo": [30, 31], "Lagos": [7, 3], "Nairobi": [-1, 37], "Kinshasa": [-4, 15], "Cape Town": [-34, 18],
	"Timbuktu": [17, -3], "Dakar": [15, -17], "Accra": [6, 0], "Marrakesh": [32, -8], "Mombasa": [-4, 40],
	"Harare": [-18, 31], "Beijing": [40, 116], "Shanghai": [31, 121], "Delhi": [29, 77], "Mumbai": [19, 73],
	"Tokyo": [36, 140], "Dhaka": [24, 90], "Jakarta": [-6, 107], "Singapore": [1, 104], "Everest": [28, 87],
	"Bangkok": [14, 101], "Manila": [15, 121], "Seoul": [38, 127]}
const BRANCH_OF := {"votes on a new law": "makes laws", "debates a plan for a law": "makes laws",
	"changes an old law": "makes laws", "agrees the taxes for next year": "makes laws",
	"runs the schools and hospitals": "carries out laws", "collects the taxes": "carries out laws",
	"plans new railways": "carries out laws", "sends out passports": "carries out laws",
	"decides if someone broke a law": "judges laws", "settles an argument about a contract": "judges laws",
	"says what a law means": "judges laws", "holds a fair trial": "judges laws"}
const CASE_OF := {"A judge decides a new rule goes against the country's constitution.": "the courts",
	"Members vote to change the age for a driving test.": "parliament",
	"Ministers decide how to spend the money for roads.": "the government",
	"A jury listens to both sides and gives its verdict.": "the courts",
	"A plan for a law is read three times and debated.": "parliament",
	"Civil servants open a new school the law allowed.": "the government"}
const POOR := {"You would say that. You're always wrong.": "attacking the person",
	"Only silly people think that.": "attacking the person",
	"Everyone thinks so, so it must be true.": "following the crowd",
	"All my friends agree, so I must be right.": "following the crowd",
	"So you want to ban all fun forever?": "twisting what was said",
	"You said less homework, so you want no school!": "twisting what was said",
	"I'm not listening. My idea is best.": "not listening"}
const SCAM_SIGNS: Array[String] = ["asks for your password", "says you must act right now",
	"offers a prize you never entered for", "has a link with an odd spelling", "asks you to keep it a secret",
	"wants gold sent to a stranger", "says your account will close today"]
const POINTS := {"car trip": 4, "bus trip": 2, "beef burger": 6, "bean burger": 1, "new T-shirt": 5, "used T-shirt": 1,
	"hot bath": 3, "short shower": 1}


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
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


func _answer(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


func _right_choice(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func _number_is(ex: Dictionary, expected: float) -> void:
	assert_eq(str(ex.type), "number", str(ex.prompt))
	assert_almost_eq(NumberAnswer.value(str(ex.answer)), expected, 0.0001, str(ex.prompt))


func _ordinal(n: int) -> String:
	if n % 100 >= 11 and n % 100 <= 13:
		return "%dth" % n
	return "%d%s" % [n, {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")]


func _century(y: int) -> int:
	return (absi(y) - 1) / 100 + 1


## Each sort item's group, by this file's own table.
func _sorted_by(ex: Dictionary, table: Dictionary) -> void:
	assert_eq(str(ex.type), "sort")
	for i in (ex.items as Array).size():
		var item := str(ex.items[i])
		assert_true(table.has(item), "known: %s" % item)
		assert_eq(str(ex.groups[int(ex.answer[i])]), str(table.get(item, "")), item)


# --- History ------------------------------------------------------------------------------------------------------------

## A century is one more than the hundreds of its years (not counting years ending in 00): 1066 is in the 11th.
func test_centuries() -> void:
	_each("g6h.century", _check_centuries)


func _check_centuries(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"choice":
			assert_ne(int(d.year) % 100, 0)
			assert_eq(_right_choice(ex), "the %s century" % _ordinal(_century(int(d.year))), str(ex.prompt))
		"number", "bc":
			assert_true(str(ex.prompt).contains(str(absi(int(d.year)))), "the year is asked about")
			_number_is(ex, _century(int(d.year)))
		"years":
			var right := int(_right_choice(ex))
			assert_eq(_century(right), int(d.century), "%d is in the %s century" % [right, _ordinal(int(d.century))])
			for c: Variant in ex.choices:
				if int(str(c)) != right:
					assert_ne(_century(int(str(c))), int(d.century), "%s is another century's" % str(c))


## The fields take turns: wheat, then beans, then a year of rest.
func test_three_fields() -> void:
	_each("g6h.three_fields", _check_three_fields)


func _check_three_fields(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"crop":
			var first := TURN.find(str(d.start[d.field]))
			assert_gte(first, 0)
			assert_eq(_right_choice(ex), TURN[(first + int(d.year) - 1) % 3], str(ex.prompt))
		"strips":
			_number_is(ex, 2 * int(d.strips))
		"rests":
			var first := TURN.find(str(d.start[d.field]))
			var n := 0
			for y in range(1, int(d.years) + 1):
				if (first + y - 1) % 3 == 2:
					n += 1
			_number_is(ex, n)


## Years apart (no year 0 between BC and AD) and anniversaries (a year: "year": true).
func test_medieval_years() -> void:
	_each("g6h.medieval_years", _check_medieval_years)


func _check_medieval_years(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "anniversary":
		assert_true(ex.get("year", false), "an anniversary's answer is a year")
		_number_is(ex, int(EVENTS[str(d.event)]) + int(d.years))
		assert_lte(int(EVENTS[str(d.event)]) + int(d.years), 2020, "an anniversary that has been")
		return
	var a := int(EVENTS[str(d.events[0])])
	var b := int(EVENTS[str(d.events[1])])
	assert_eq([a, b], [int(d.from), int(d.to)], "the events' own years")
	assert_lt(a, b)
	_number_is(ex, b - a - 1 if a < 0 and b > 0 else b - a)


func test_medieval_order() -> void:
	_each("g6h.medieval_order", _check_medieval_order)


func _check_medieval_order(ex: Dictionary, level: int) -> void:
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


## k things and a equal m things and b: one thing.
func test_al_jabr() -> void:
	_each("g6h.al_jabr", _check_al_jabr)


func _check_al_jabr(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var t := int(ex.answer)
	assert_eq(int(d.k) * t + int(d.a), int(d.m) * t + int(d.b), "it balances")
	assert_true(str(ex.prompt).contains(str(int(d.a))) and str(ex.prompt).contains(str(int(d.b))), "the numbers asked")
	assert_eq(t, int(d.thing))


func test_caravans() -> void:
	_each("g6h.caravan", _check_caravans)


func _check_caravans(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"slabs":
			_number_is(ex, int(d.camels) * int(d.slabs))
		"days":
			_number_is(ex, float(d.km) / int(d.per_day))
		"share":
			assert_eq(int(d.camels) * int(d.slabs) % int(d.towns), 0, "shared equally")
			_number_is(ex, float(int(d.camels) * int(d.slabs)) / int(d.towns))


## The picture's cords are the numbers asked about.
func test_quipu_numbers() -> void:
	_each("g6h.quipu_number", _check_quipu_numbers)


func _check_quipu_numbers(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	assert_eq(ex.picture.cords, d.cords, "the picture's cords")
	var c: Array = d.cords
	match str(d.ask):
		"read":
			_number_is(ex, int(c[0]))
		"total":
			_number_is(ex, int(c[0]) + int(c[1]) + int(c[2]))
		"more":
			assert_gt(int(c[int(d.more)]), int(c[int(d.fewer)]))
			for v: Variant in c:
				assert_between(int(v), int(c[int(d.fewer)]), int(c[int(d.more)]), "the most and the fewest")
			_number_is(ex, int(c[int(d.more)]) - int(c[int(d.fewer)]))


func test_harvest_after_the_black_death() -> void:
	_each("g6h.harvest_workers", _check_harvest)


func _check_harvest(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"days":
			assert_lt(int(d.left), int(d.workers), "fewer workers")
			_number_is(ex, float(int(d.workers) * int(d.days)) / int(d.left))
		"fraction":
			_number_is(ex, float(int(d.people)) * int(d.num) / int(d.den))
		"wage":
			_number_is(ex, (int(d.wage) + int(d.wage) * int(d.rise) / 100.0) * int(d.days))


# --- Geography ----------------------------------------------------------------------------------------------------------

func test_population_density() -> void:
	_each("g6h.density", _check_density)


func _check_density(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"density":
			_number_is(ex, float(int(d.people)) / int(d.km2))
			if ex.has("picture"):
				assert_eq(int(ex.picture.areas[0].people), int(d.people), "a dot for each person")
		"busier":
			var p: Array = d.people
			var k: Array = d.km2
			var busier := 0 if float(p[0]) / int(k[0]) > float(p[1]) / int(k[1]) else 1
			assert_eq(_right_choice(ex), str(d.places[busier]))
		"people":
			_number_is(ex, int(d.density) * int(d.km2))


func test_population_change() -> void:
	_each("g6h.population_change", _check_population_change)


func _check_population_change(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"moving":
			_number_is(ex, int(d["in"]) - int(d.out))
		"change":
			assert_gt(int(d.births) - int(d.deaths) + int(d["in"]) - int(d.out), 0, "it grows")
			_number_is(ex, int(d.births) - int(d.deaths) + int(d["in"]) - int(d.out))
		"end":
			_number_is(ex, int(d.start) + int(d.births) - int(d.deaths) + int(d["in"]) - int(d.out))


func test_city_growth() -> void:
	_each("g6h.city_growth", _check_city_growth)


func _check_city_growth(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"more":
			_number_is(ex, int(d.after) - int(d.before))
		"times":
			_number_is(ex, float(int(d.after)) / int(d.before))
		"percent":
			_number_is(ex, 100.0 * int(d.urban) / int(d.people))


func test_job_sectors() -> void:
	_each("g6h.sector_sort", _check_sectors)


func _check_sectors(ex: Dictionary, _level: int) -> void:
	if str(ex.data.ask) == "choice":
		assert_eq(_right_choice(ex), str(SECTOR_OF[str(ex.data.job)]))
	else:
		_sorted_by(ex, SECTOR_OF)


## Along the corridor, then up the stairs: a symbol's square and a point's six figures, from the map's own data.
func test_grid_references() -> void:
	_each("g6h.grid_ref", _check_grid_refs)


func _check_grid_refs(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var e := int(d.e)
	var n := int(d.n)
	var on_map := false
	for q: Dictionary in ex.picture.get("symbols", []) + ex.picture.get("points", []):
		on_map = on_map or (int(q.e) == e and int(q.n) == n)
	assert_true(on_map, "the place is on the map")
	match str(d.ask):
		"four":
			assert_eq(_right_choice(ex), "%d%d" % [e / 10, n / 10])
		"six":
			assert_eq(_right_choice(ex), "%d%d" % [e, n])
		"what":
			assert_true(str(ex.prompt).contains("%d%d" % [e, n]))
			assert_eq(_right_choice(ex), str(SYMBOL_OF[str(d.what)]))
		"point":
			assert_true(str(ex.prompt).contains("%d%d" % [e, n]))
			assert_eq(_right_choice(ex), "point %s" % str(d.label))


func test_contours() -> void:
	_each("g6h.contours", _check_contours)


func _check_contours(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"steep":
			assert_eq(str(ex.picture.hills[0].steep), str(d.side), "the picture's steep side")
			assert_eq(_right_choice(ex), "the %s side" % {"n": "north", "e": "east", "s": "south", "w": "west"}[str(d.side)])
		"line":
			_number_is(ex, int(d.low) + (int(d.k) - 1) * int(d.interval))
		"climb":
			_number_is(ex, int(d.top) - int(d["from"]))
		"path":
			_number_is(ex, int(d["from"]) + int(d.crossed) * int(d.interval))


## 1:25,000: 4 cm is 1 km (25,000 cm is 250 m); 1:50,000: 2 cm is 1 km; 4 km an hour is 15 minutes a km.
func test_map_scales() -> void:
	_each("g6h.map_scale", _check_map_scales)


func _check_map_scales(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"km":
			_number_is(ex, float(d.cm) * int(d.scale) / 100000.0)
		"cm":
			_number_is(ex, float(d.km) * 100000.0 / int(d.scale))
		"minutes":
			_number_is(ex, float(d.cm) * 25000 / 100000.0 / 4.0 * 60.0)


## The graph's own numbers: the wettest or warmest month, the range, the rain, the hemisphere by its warm months.
func test_climate_graphs() -> void:
	_each("g6h.climate_read", _check_climate)


func _check_climate(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var p: Dictionary = ex.picture
	var temp: Array = p.temp
	var rain: Array = p.rain
	var months := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October",
		"November", "December"]
	match str(d.ask):
		"wettest", "warmest":
			var values: Array = rain if str(d.ask) == "wettest" else temp
			var top := values.max() as float
			assert_eq(values.count(top), 1, "one month on top")
			assert_eq(_right_choice(ex), months[values.find(top)])
		"range":
			var hi := float(temp.max())
			var lo := float(temp.min())
			assert_eq(fposmod(hi - float(p.get("t_from", 0)), float(p.t_step)), 0.0, "the warmest month on a grid line")
			assert_eq(fposmod(lo - float(p.get("t_from", 0)), float(p.t_step)), 0.0, "the coldest month on a grid line")
			_number_is(ex, hi - lo)
		"rain":
			var wet := float(rain.max())
			assert_eq(fposmod(wet, float(p.r_step)), 0.0, "the wettest month on a grid line")
			_number_is(ex, wet)
		"hemisphere":
			var summer := float(temp[5]) + float(temp[6]) + float(temp[7])
			var winter := float(temp[11]) + float(temp[0]) + float(temp[1])
			assert_eq(_right_choice(ex), "northern" if summer > winter else "southern")
		"climate":
			assert_eq(_right_choice(ex), str(d.kind))


func test_rivers() -> void:
	_each("g6h.river_sort", _check_rivers)


func _check_rivers(ex: Dictionary, _level: int) -> void:
	if str(ex.data.ask) == "process":
		var what := str(ex.prompt).replace(" Which process is this?", "")
		assert_eq(_right_choice(ex), str(PROCESS_OF.get(what, "")), what)
	else:
		_sorted_by(ex, RIVER_GROUP)


## Places by their own latitudes and longitudes.
func test_places_in_africa_and_asia() -> void:
	_each("g6h.africa_places", _check_places)
	_each("g6h.asia_places", _check_places)


func _check_places(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"hemisphere":
			var lat := int(PLACES[str(d.place)][0])
			assert_eq(_right_choice(ex), "north of the Equator" if lat > 0 else "south of the Equator")
		"north", "south", "east":
			var best := ""
			for p: Variant in d.places:
				var v: Array = PLACES[str(p)]
				if best == "":
					best = str(p)
					continue
				var b: Array = PLACES[best]
				match str(d.ask):
					"north":
						best = str(p) if int(v[0]) > int(b[0]) else best
					"south":
						best = str(p) if int(v[0]) < int(b[0]) else best
					_:
						best = str(p) if int(v[1]) > int(b[1]) else best
			assert_eq(_right_choice(ex), best)
			var points: Array = ex.picture.points
			for q: Dictionary in points:
				assert_eq([int(q.lat), int(q.long)], [int(PLACES[str(q.label)][0]), int(PLACES[str(q.label)][1])], "on the grid")
			assert_true(_names_clear(points), "the places' names keep clear of each other: %s" % [points])
			var key := 1 if str(d.ask) == "east" else 0
			var extreme := 0
			for p: Variant in d.places:
				if int(PLACES[str(p)][key]) == int(PLACES[best][key]):
					extreme += 1
			assert_eq(extreme, 1, "one place is furthest %s" % d.ask)
		"apart":
			_number_is(ex, absi(int(PLACES[str(d.places[0])][0]) - int(PLACES[str(d.places[1])][0])))


## The places' names on a 580 × 250 exercise's world grid (the map about 392 × 196 pixels, a name about 7.5 pixels a
## letter, written leftwards when it would run off the right edge) overlap no other name or dot.
func _names_clear(points: Array) -> bool:
	var names: Array[Rect2] = []
	var dots: Array[Rect2] = []
	for q: Dictionary in points:
		var x := (float(q.long) + 180.0) * 392.0 / 360.0
		var y := (90.0 - float(q.lat)) * 196.0 / 180.0
		var w := str(q.label).length() * 7.5
		names.append(Rect2(x + 9.0 if x + 9.0 + w < 392.0 else x - 9.0 - w, y - 10.0, w, 14.0))
		dots.append(Rect2(x - 6.0, y - 6.0, 12.0, 12.0))
	for i in names.size():
		for j in names.size():
			if i != j and (names[i].intersects(names[j]) or names[i].intersects(dots[j])):
				return false
	return true


## Counted again from the picture's own layers.
func test_a_map_in_layers() -> void:
	_each("g6h.layer_query", _check_layers)


func _check_layers(ex: Dictionary, _level: int) -> void:
	var cells := {}
	for l: Dictionary in ex.picture.layers:
		var on := {}
		for y in (l.cells as Array).size():
			for x in str(l.cells[y]).length():
				if str(l.cells[y])[x] == "#":
					on[Vector2i(x, y)] = true
		cells[str(l.what)] = on
	var houses: Dictionary = cells.houses
	var flood: Dictionary = cells.flood
	match str(ex.data.ask):
		"houses":
			_number_is(ex, houses.size())
		"flooded":
			_number_is(ex, houses.keys().filter(func(c: Vector2i) -> bool: return flood.has(c)).size())
		"dry":
			var n := 0
			for key: String in ["houses", "schools"]:
				n += (cells[key] as Dictionary).keys().filter(func(c: Vector2i) -> bool: return not flood.has(c)).size()
			_number_is(ex, n)
		"layers":
			assert_eq(_right_choice(ex), "schools and flood zone")
	for c: Vector2i in cells.water:
		assert_true(flood.has(c), "the river is in its flood zone")


# --- Citizenship --------------------------------------------------------------------------------------------------------

func test_the_three_jobs_of_government() -> void:
	_each("g6h.branch_sort", _check_branches)


func _check_branches(ex: Dictionary, _level: int) -> void:
	if str(ex.data.ask) == "case":
		assert_eq(_right_choice(ex), str(CASE_OF[str(ex.data.case)]))
	else:
		_sorted_by(ex, BRANCH_OF)


## The most votes in an area wins its seat; a majority is more than half the seats.
func test_seats_and_majorities() -> void:
	_each("g6h.seat_count", _check_seats)


func _check_seats(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var parties := ["Oak", "River", "Sun"]
	match str(d.ask):
		"winner":
			var v: Array = d.votes
			var best := 0
			for i in 3:
				if int(v[i]) > int(v[best]):
					best = i
			assert_eq(_right_choice(ex), "the %s Party" % parties[best])
		"seats":
			var won := 0
			for v: Array in d.votes:
				var best := 0
				for i in 3:
					if int(v[i]) > int(v[best]):
						best = i
				won += 1 if best == int(d.party) else 0
			_number_is(ex, won)
		"majority":
			var need := int(d.seats) / 2 + 1
			assert_gt(need * 2, int(d.seats), "more than half")
			assert_lte((need - 1) * 2, int(d.seats), "the fewest")
			_number_is(ex, need)


func test_disagreeing_well() -> void:
	_each("g6h.argue_well", _check_argue)


func _check_argue(ex: Dictionary, _level: int) -> void:
	if str(ex.data.ask) == "mistake":
		assert_eq(_right_choice(ex), str(POOR[str(ex.data.said)]))
		return
	for i in (ex.items as Array).size():
		var item := str(ex.items[i])
		assert_eq(int(ex.answer[i]), 1 if POOR.has(item) else 0, item)


func test_take_home_pay() -> void:
	_each("g6h.take_home_pay", _check_pay)


func _check_pay(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if d.has("tax"):
		_number_is(ex, int(d.gross) - int(d.tax))
	elif d.has("band"):
		var tax := (int(d.band) - int(d.free)) * 0.2 + (int(d.gross) - int(d.band)) * 0.4
		_number_is(ex, int(d.gross) - tax)
	else:
		_number_is(ex, int(d.gross) - (int(d.gross) - int(d.free)) * int(d.rate) / 100.0)


func test_compound_interest() -> void:
	_each("g6h.compound_growth", _check_compound)


func _check_compound(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var start := float(d.start)
	var rate := float(d.rate) / 100.0
	match str(d.ask):
		"first":
			_number_is(ex, start * rate)
		"after":
			_number_is(ex, start * pow(1.0 + rate, int(d.years)))
		"more":
			_number_is(ex, start * pow(1.0 + rate, 2) - (start + 2 * start * rate))


func test_insurance() -> void:
	_each("g6h.insurance_pool", _check_insurance)


func _check_insurance(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"year":
			_number_is(ex, 12 * int(d.monthly))
		"pot":
			assert_gt(int(d.members) * int(d.pay), int(d.claims) * int(d.cost), "the pot pays every claim")
			_number_is(ex, int(d.members) * int(d.pay) - int(d.claims) * int(d.cost))
		"total":
			_number_is(ex, int(d.years) * int(d.yearly) + int(d.excess))


func test_scams() -> void:
	_each("g6h.scam_signs", _check_scams)


func _check_scams(ex: Dictionary, _level: int) -> void:
	if str(ex.data.ask) == "case":
		assert_eq(_right_choice(ex), "don't reply or click; tell a grown-up")
		return
	for i in (ex.items as Array).size():
		var item := str(ex.items[i])
		assert_eq(int(ex.answer[i]), 0 if SCAM_SIGNS.has(item) else 1, item)


## The table's rows: times × points each.
func test_footprints() -> void:
	_each("g6h.footprint", _check_footprint)


func _check_footprint(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	var rows: Array = ex.picture.rows
	var total := 0
	for r in range(1, rows.size()):
		assert_eq(int(str(rows[r][2])), int(POINTS[str(rows[r][0])]), "%s's points" % rows[r][0])
		total += int(str(rows[r][1])) * int(str(rows[r][2]))
	var saved := 0
	if d.has("swap"):
		saved = int(str(rows[1][1])) * (int(POINTS[str(d.swap[0])]) - int(d.swap[2]))
		assert_eq(str(rows[1][0]), str(d.swap[0]), "the swapped activity is in the table")
	match str(d.ask):
		"total":
			_number_is(ex, total)
		"saved":
			_number_is(ex, saved)
		"percent":
			_number_is(ex, 100.0 * saved / total)
