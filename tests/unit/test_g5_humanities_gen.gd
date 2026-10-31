extends GutTest
## Owner #70 and #73, grade 5 history, geography and citizenship (G5HumanitiesGen, "g5h"): the Olympic Games' years
## counted in BC, the classical world's dated events (years apart across BC and AD, and in order), Roman numerals and Maya
## numbers; latitude and longitude on the world's grid, time zones, temperatures up a mountain, renewable and other
## resources, an atlas's index, trade by sea; an election's results, a budget, simple interest, the cost of borrowing and
## a class's rubbish before and after. Each generator's answer is worked out again here from the exercise's `data` (and
## the facts from this file's own tables), for many seeds and every level, and every exercise must be valid
## (ExerciseCheck, the picture's own check).

const SEEDS := 80
## This test's own facts (typed apart from the generator's tables).
## The classical world's events: what happened -> its year (BC below 0).
const EVENTS := {
	"The first Olympic Games": -776, "Rome is founded, says the legend": -753,
	"Cyrus founds the Persian Empire": -550, "Rome becomes a republic": -509, "Democracy begins in Athens": -508,
	"The Battle of Marathon": -490, "Building of the Parthenon begins": -447, "Alexander the Great takes Persepolis": -330,
	"The Maurya Empire begins": -321, "Ashoka becomes emperor": -268, "The Han dynasty begins": -206,
	"Zhang Qian sets out to the west": -138, "Julius Caesar lands in Britain": -55,
	"Augustus becomes Rome's first emperor": -27, "The Romans invade Britain": 43, "Boudica's revolt": 60,
	"Vesuvius buries Pompeii": 79, "The Colosseum opens": 80, "Cai Lun shows paper to the emperor": 105,
	"Building of Hadrian's Wall begins": 122, "The Maya Classic Period begins": 250, "The Romans leave Britain": 410,
	"The Western Roman Empire ends": 476, "Aryabhata writes his maths book": 499,
	"Brahmagupta writes rules for zero": 628, "Many Maya cities are left empty": 900,
}
## Hours ahead of London (+) or behind it (−) in January.
const ZONES := {"London": 0, "Lisbon": 0, "Reykjavik": 0, "Accra": 0, "Paris": 1, "Rome": 1, "Lagos": 1, "Cairo": 2,
	"Athens": 2, "Nairobi": 3, "Dubai": 4, "Karachi": 5, "Dhaka": 6, "Bangkok": 7, "Beijing": 8, "Singapore": 8,
	"Tokyo": 9, "Brisbane": 10, "Honolulu": -10, "Los Angeles": -8, "Denver": -7, "Chicago": -6, "Mexico City": -6,
	"New York": -5, "Lima": -5, "Buenos Aires": -3, "Rio de Janeiro": -3}
## Cities to the nearest degree: [lat (N +), long (E +)].
const CITIES := {"London": [51, 0], "Quito": [0, -78], "Singapore": [1, 104], "Cairo": [30, 31], "Sydney": [-34, 151],
	"Rio de Janeiro": [-23, -43], "Nairobi": [-1, 37], "Tokyo": [36, 140], "New York": [41, -74], "Reykjavik": [64, -22],
	"Cape Town": [-34, 18], "Buenos Aires": [-35, -58], "Mumbai": [19, 73], "Lima": [-12, -77], "Oslo": [60, 11],
	"Perth": [-32, 116], "Vancouver": [49, -123], "Mexico City": [19, -99], "Beijing": [40, 116], "Honolulu": [21, -158],
	"Madrid": [40, -4], "Anchorage": [61, -150], "Accra": [6, 0], "Auckland": [-37, 175]}
const RENEWABLE: Array[String] = ["sunlight", "wind", "rain", "waves", "tides", "flowing river water",
	"heat from deep underground", "wood from replanted forests", "crops such as wheat", "fish, if not overfished"]
const NON_RENEWABLE: Array[String] = ["coal", "oil", "natural gas", "iron ore", "copper ore", "gold", "uranium",
	"diamonds"]
const FOSSIL: Array[String] = ["coal", "oil", "natural gas"]
const ORES: Array[String] = ["iron ore", "copper ore", "tin ore", "aluminium ore"]
const LIVING: Array[String] = ["wood", "cotton", "wool", "rubber", "fish", "leather"]
const ORDINALS := {1: "first", 2: "second", 3: "third", 4: "fourth", 5: "fifth"}


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


## The right answer in words (a choice's text, a number, True or False, an order's items).
func _answer(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


## A number exercise's answer is `expected` (compared by value, so "1.50" and "1.5" agree).
func _number_is(ex: Dictionary, expected: float) -> void:
	assert_eq(str(ex.type), "number", str(ex.prompt))
	assert_almost_eq(NumberAnswer.value(str(ex.answer)), expected, 0.0001, str(ex.prompt))


## "776 BC" -> -776, "AD 43" -> 43.
func _signed_year(text: String) -> int:
	var m := RegEx.create_from_string("(AD )?([0-9,]+)( BC)?").search(text)
	var n := int(m.get_string(2).replace(",", ""))
	return -n if m.get_string(3) != "" else n


func _year_text(y: int) -> String:
	return "%d BC" % -y if y < 0 else "AD %d" % y


func _roman(n: int) -> String:
	var out := ""
	var left := n
	for pair: Array in [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"],
			[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while left >= int(pair[0]):
			out += str(pair[1])
			left -= int(pair[0])
	return out


func _lat(v: int) -> String:
	return "0°" if v == 0 else "%d°%s" % [absi(v), "N" if v > 0 else "S"]


func _long(v: int) -> String:
	return "0°" if v == 0 or absi(v) == 180 else "%d°%s" % [absi(v), "E" if v > 0 else "W"]


func _clock(h: int) -> String:
	return "%02d:00" % posmod(h, 24)


# --- History ----------------------------------------------------------------------------------------------------------

## The first Games we know of were in 776 BC, then every 4 years: the nth Games were in 776 − 4 × (n − 1) BC.
func test_the_olympic_games_count_down_in_fours() -> void:
	_each("g5h.olympiad", _check_the_olympic_games_count_down_in_fours)


func _check_the_olympic_games_count_down_in_fours(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	assert_true(str(ex.prompt).contains("776 BC"), "the prompt starts from 776 BC")
	match str(d.ask):
		"year":
			var n := int(d.n)
			_number_is(ex, 776 - 4 * (n - 1))
			if level == 1:
				assert_between(n, 2, 5, "level 1: the first few Games")
				assert_true(str(ex.prompt).contains(str(ORDINALS[n])), "the prompt names the %s Games" % ORDINALS[n])
			else:
				assert_between(n, 6, 30, "level 2: later Games")
			assert_true(str(ex.prompt).contains("%s Games" % _ordinal(n)), str(ex.prompt))
		"games":
			assert_eq(level, 3)
			var y := int(d.year)
			assert_eq((776 - y) % 4, 0, "a Games year")
			_number_is(ex, (776 - y) / 4 + 1)
			assert_true(str(ex.prompt).contains("%d BC" % y))
		"count":
			assert_eq(level, 3)
			var y := int(d.year)
			assert_eq((776 - y) % 4, 0, "a Games year")
			_number_is(ex, (776 - y) / 4 + 1)
			assert_true(str(ex.prompt).contains("%d BC" % y) and str(ex.prompt).contains("both"))
		_:
			assert_true(false, "an ask: %s" % d.ask)


func _ordinal(n: int) -> String:
	if ORDINALS.has(n):
		return str(ORDINALS[n])
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		suffix = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
	return "%d%s" % [n, suffix]


## Years apart: BC years count down, AD years up, and 1 BC is followed by AD 1 (no year 0).
func test_classical_years_apart_skip_the_year_0() -> void:
	_each("g5h.classical_years", _check_classical_years_apart_skip_the_year_0)


func _check_classical_years_apart_skip_the_year_0(ex: Dictionary, level: int) -> void:
	var a := int(ex.data.from)
	var b := int(ex.data.to)
	assert_lt(a, b, "the earlier year first")
	_number_is(ex, b - a - (1 if a < 0 and b > 0 else 0))
	for e: String in ex.data.events:
		assert_true(EVENTS.has(e), "an event of the lessons: %s" % e)
	assert_eq(int(EVENTS[ex.data.events[0]]), a, "the first event's year")
	assert_eq(int(EVENTS[ex.data.events[1]]), b, "the second event's year")
	if level == 1:
		assert_true(a < 0 and b < 0, "level 1: two BC events")
	elif level == 2:
		assert_true(a > 0 and b > 0 or a < 0 and b < 0, "level 2: both BC or both AD")
	else:
		assert_true(a < 0 and b > 0, "level 3: from BC to AD")
		assert_true(str(ex.prompt).contains("no year 0"), "level 3 says there is no year 0")
	assert_true(str(ex.prompt).contains(str(absi(a))) and str(ex.prompt).contains(str(absi(b))), "both years")


func test_classical_events_go_in_order_of_their_years() -> void:
	_each("g5h.classical_order", _check_classical_events_go_in_order_of_their_years)


func _check_classical_events_go_in_order_of_their_years(ex: Dictionary, level: int) -> void:
	var years: Array[int] = []
	for item: Variant in ex.items:
		var text := str(item)
		var name := text.substr(0, text.rfind(" ("))
		assert_true(EVENTS.has(name), "an event of the lessons: %s" % name)
		var y := _signed_year(text.substr(text.rfind(" (")))
		assert_eq(y, int(EVENTS.get(name, y)), "%s's year" % name)
		years.append(y)
	var ordered: Array[int] = []
	for i: Variant in ex.answer:
		ordered.append(years[int(i)])
	var sorted := ordered.duplicate()
	sorted.sort()
	assert_eq(ordered, sorted, "earliest first: %s" % str(ex.items))
	assert_eq(years.size(), 3 if level == 1 else 4)
	for k in range(1, ordered.size()):
		assert_ne(ordered[k], ordered[k - 1], "no two events in the same year")
	if level == 1:
		for k in range(1, ordered.size()):
			assert_gte(ordered[k] - ordered[k - 1], 150, "level 1: far apart")
	if level == 2:
		assert_lt(ordered[-1], 0, "level 2: all BC")
	if level == 3:
		assert_true(ordered[0] < 0 and ordered[-1] > 0, "level 3: BC and AD")


func test_roman_numerals_are_read_and_written() -> void:
	_each("g5h.roman_numeral", _check_roman_numerals_are_read_and_written)


func _check_roman_numerals_are_read_and_written(ex: Dictionary, level: int) -> void:
	var n := int(ex.data.n)
	var ranges := {1: [1, 39], 2: [40, 399], 3: [1000, 2100]}
	assert_between(n, int(ranges[level][0]), int(ranges[level][1]), "level %d's numbers" % level)
	if str(ex.data.ask) == "read":
		assert_true(str(ex.prompt).contains(_roman(n)), "the prompt shows %s" % _roman(n))
		_number_is(ex, n)
		assert_eq(ExerciseCheck.grouped(ex), level < 3, "a year reads 1850, not 1,850")
	else:
		assert_eq(str(ex.type), "choice")
		assert_eq(_answer(ex), _roman(n), "%d in Roman numerals" % n)
		var rights := 0
		for c: Variant in ex.choices:
			if str(c) == _roman(n):
				rights += 1
		assert_eq(rights, 1, "one right way to write it")


func test_maya_numbers_add_up_their_places() -> void:
	_each("g5h.maya_number", _check_maya_numbers_add_up_their_places)


func _check_maya_numbers_add_up_their_places(ex: Dictionary, level: int) -> void:
	var v := int(ex.data.value)
	assert_eq(str(ex.picture.system), "maya")
	assert_eq(int(ex.picture.value), v, "the picture shows the number")
	_number_is(ex, v)
	var ranges := {1: [1, 19], 2: [20, 399], 3: [400, 7999]}
	assert_between(v, int(ranges[level][0]), int(ranges[level][1]), "level %d: %d places" % [level, level])
	var places: Array[int] = []
	var left := v
	while left > 0:
		places.push_front(left % 20)
		left /= 20
	var sum := 0
	for p in places:
		sum = sum * 20 + p
	assert_eq(sum, v)


# --- Geography --------------------------------------------------------------------------------------------------------

func test_places_are_found_by_latitude_and_longitude() -> void:
	_each("g5h.lat_long", _check_places_are_found_by_latitude_and_longitude)


func _check_places_are_found_by_latitude_and_longitude(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"at", "south", "lat", "long":
			var pts: Array = ex.picture.points
			assert_eq(str(ex.picture.kind), "latlong")
			var target := {}
			for p: Dictionary in pts:
				if str(p.label) == str(d.target):
					target = p
			assert_false(target.is_empty(), "the place is on the map")
			var lat := int(target.lat)
			var lng := int(target.long)
			match str(d.ask):
				"at":
					assert_true(str(ex.prompt).contains(_lat(lat)) and str(ex.prompt).contains(_long(lng)))
					assert_eq(_answer(ex), str(target.label))
					for p: Dictionary in pts:
						if p != target:
							assert_false(int(p.lat) == lat and int(p.long) == lng, "one place there")
				"south":
					assert_lt(lat, 0, "the answer is south of the Equator")
					assert_eq(_answer(ex), str(target.label))
					for p: Dictionary in pts:
						if p != target:
							assert_gte(int(p.lat), 0, "only one place south of the Equator")
				"lat":
					assert_eq(_answer(ex), _lat(lat))
					assert_true(str(ex.prompt).contains(str(target.label)))
				"long":
					assert_eq(_answer(ex), _long(lng))
		"hemispheres":
			assert_eq(level, 3)
			var city := str(d.city)
			assert_true(CITIES.has(city), city)
			var lat := int(CITIES[city][0])
			var lng := int(CITIES[city][1])
			assert_true(str(ex.prompt).contains(_lat(lat)) and str(ex.prompt).contains(_long(lng)), "%s's place" % city)
			assert_eq(_answer(ex), "%s and %s" % ["northern" if lat > 0 else "southern", "eastern" if lng > 0 else "western"])
		"nearest":
			assert_eq(level, 3)
			var best := ""
			for city: String in d.cities:
				assert_true(CITIES.has(city), city)
				if best == "" or absi(int(CITIES[city][0])) < absi(int(CITIES[best][0])):
					best = city
			assert_eq(_answer(ex), best, "the city nearest the Equator")
		_:
			assert_true(false, "an ask: %s" % d.ask)


func test_time_zones_add_the_hours_ahead_and_take_the_hours_behind() -> void:
	_each("g5h.time_zone", _check_time_zones_add_the_hours_ahead_and_take_the_hours_behind)


func _check_time_zones_add_the_hours_ahead_and_take_the_hours_behind(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	if str(d.ask) == "longitude":
		assert_eq(level, 3)
		var lng := int(d.long)
		assert_eq(lng % 15, 0)
		assert_true(str(ex.prompt).contains(_long(lng)), "the prompt gives the longitude")
		_number_is(ex, absi(lng) / 15)
		assert_true(str(ex.prompt).contains("ahead" if lng > 0 else "behind"))
		return
	var from := str(d.from)
	var to := str(d.to)
	assert_true(ZONES.has(from) and ZONES.has(to), "%s and %s" % [from, to])
	var h := int(d.h)
	var at := h + int(ZONES[to]) - int(ZONES[from])
	var day := "" if at >= 0 and at < 24 else (" the next day" if at >= 24 else " the day before")
	assert_eq(_answer(ex), _clock(at) + day, str(ex.prompt))
	assert_true(str(ex.prompt).contains(_clock(h)), "the prompt gives the time in %s" % from)
	if level == 1:
		assert_eq(from, "London")
		assert_true(int(ZONES[to]) > 0 and day == "", "level 1: ahead of London, the same day")


func test_it_gets_colder_up_a_mountain() -> void:
	_each("g5h.altitude_temp", _check_it_gets_colder_up_a_mountain)


func _check_it_gets_colder_up_a_mountain(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	assert_true(str(ex.prompt).contains("6.5 °C") and str(ex.prompt).contains("1,000 m"), "the rule is given")
	var t0 := float(d.t)
	if str(d.ask) == "zero":
		assert_eq(level, 3)
		_number_is(ex, t0 / 6.5 * 1000.0)
		return
	var climb := float(d.climb)
	var expected := t0 - 6.5 * climb / 1000.0
	_number_is(ex, expected)
	if level == 1:
		assert_eq(fmod(expected, 1.0), 0.0, "level 1: a whole number")
		assert_gte(expected, 0.0)
	if level == 3:
		assert_lt(expected, 0.0, "level 3: below freezing")


func test_resources_are_sorted_by_our_own_facts() -> void:
	_each("g5h.resource_sort", _check_resources_are_sorted_by_our_own_facts)


func _check_resources_are_sorted_by_our_own_facts(ex: Dictionary, level: int) -> void:
	var groups: Array = ex.groups
	for i in (ex.items as Array).size():
		var item := str(ex.items[i])
		var group := str(groups[int(ex.answer[i])])
		match group:
			"renewable":
				assert_true(RENEWABLE.has(item), "%s is renewable" % item)
			"non-renewable":
				assert_true(NON_RENEWABLE.has(item), "%s is non-renewable" % item)
			"fossil fuel":
				assert_true(FOSSIL.has(item), "%s is a fossil fuel" % item)
			"metal ore":
				assert_true(ORES.has(item), "%s is a metal ore" % item)
			"from living things":
				assert_true(LIVING.has(item), "%s comes from living things" % item)
			_:
				assert_true(false, "a group: %s" % group)
	assert_eq(groups.size(), 3 if level == 3 else 2)


func test_an_atlas_index_is_read_back() -> void:
	_each("g5h.atlas_index", _check_an_atlas_index_is_read_back)


func _check_an_atlas_index_is_read_back(ex: Dictionary, level: int) -> void:
	var rows: Array = ex.picture.rows
	var d: Dictionary = ex.data
	var names: Array[String] = []
	for r in range(1, rows.size()):
		names.append(str(rows[r][0]))
	var sorted := names.duplicate()
	sorted.sort()
	assert_eq(names, sorted, "an index is in alphabetical order")
	var row: Array = []
	for r in range(1, rows.size()):
		if str(rows[r][0]) == str(d.get("place", "")):
			row = rows[r]
	match str(d.ask):
		"page":
			_number_is(ex, int(row[1]))
		"square":
			assert_eq(_answer(ex), str(row[2]))
		"which":
			assert_true(str(ex.prompt).contains("page %s" % row[1]) and str(ex.prompt).contains(str(row[2])))
			assert_eq(_answer(ex), str(row[0]))
			for r in range(1, rows.size()):
				if rows[r] != row:
					assert_false(str(rows[r][1]) == str(row[1]) and str(rows[r][2]) == str(row[2]), "one place there")
		"north", "south", "west":
			assert_eq(level, 3)
			for r in range(1, rows.size()):
				var city := str(rows[r][0])
				assert_true(CITIES.has(city), city)
				assert_eq(str(rows[r][1]), _lat(int(CITIES[city][0])), "%s's latitude" % city)
				assert_eq(str(rows[r][2]), _long(int(CITIES[city][1])), "%s's longitude" % city)
			var best := ""
			var count := 0
			for n in names:
				var lat := int(CITIES[n][0])
				var lng := int(CITIES[n][1])
				if str(d.ask) == "north":
					if best == "" or lat > int(CITIES[best][0]):
						best = n
				elif (str(d.ask) == "south" and lat < 0) or (str(d.ask) == "west" and lng < 0):
					best = n
					count += 1
			if str(d.ask) != "north":
				assert_eq(count, 1, "exactly one place is %s" % d.ask)
			assert_eq(_answer(ex), best)
		_:
			assert_true(false, "an ask: %s" % d.ask)


func test_trade_by_sea_is_worked_out() -> void:
	_each("g5h.trade_count", _check_trade_by_sea_is_worked_out)


func _check_trade_by_sea_is_worked_out(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"difference":
			_number_is(ex, absi(int(d.exports) - int(d.imports)))
		"sells_more":
			assert_eq(ex.answer, int(d.exports) > int(d.imports))
			assert_ne(int(d.exports), int(d.imports))
		"containers":
			_number_is(ex, ceili(float(d.boxes) / float(d.per)))
			assert_ne(int(d.boxes) % int(d.per), 0, "a part-full container still sails")
		"days":
			assert_eq(int(d.km) % int(d.per_day), 0)
			_number_is(ex, int(d.km) / int(d.per_day))
		_:
			assert_true(false, "an ask: %s" % d.ask)
	if level == 1:
		assert_true(str(d.ask) in ["difference", "sells_more"])
	elif level == 2:
		assert_eq(str(d.ask), "containers")
	else:
		assert_eq(str(d.ask), "days")


# --- Citizenship ------------------------------------------------------------------------------------------------------

func test_an_election_is_counted() -> void:
	_each("g5h.election", _check_an_election_is_counted)


func _check_an_election_is_counted(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var votes: Dictionary = d.votes
	var total := 0
	var top := ""
	for k: String in votes:
		total += int(votes[k])
		if top == "" or int(votes[k]) > int(votes[top]):
			top = k
	for k: String in votes:
		if k != top:
			assert_lt(int(votes[k]), int(votes[top]), "one winner")
	match str(d.ask):
		"winner":
			assert_eq(_answer(ex), top)
		"margin":
			_number_is(ex, int(votes[top]) - int(votes[d.second]))
		"total":
			_number_is(ex, total)
		"turnout":
			assert_eq(total * 100 % int(d.voters), 0, "a whole percentage")
			_number_is(ex, total * 100 / int(d.voters))
		"majority":
			assert_eq(ex.answer, int(votes[top]) * 2 > total)
		_:
			assert_true(false, "an ask: %s" % d.ask)
	if level == 3:
		assert_true(str(d.ask) in ["turnout", "majority"])


func test_a_budget_is_balanced() -> void:
	_each("g5h.budget_plan", _check_a_budget_is_balanced)


func _check_a_budget_is_balanced(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var spent := 0
	for c: int in d.costs:
		spent += c
	match str(d.ask):
		"left", "wants":
			_number_is(ex, int(d.income) - spent)
			assert_gte(int(d.income) - spent, 0, "never more spent than earned")
		"weeks":
			var save := int(d.income) - spent
			assert_gt(save, 0)
			_number_is(ex, ceili(float(d.goal) / float(save)))
		_:
			assert_true(false, "an ask: %s" % d.ask)


func test_simple_interest_is_paid_on_the_savings() -> void:
	_each("g5h.simple_interest", _check_simple_interest_is_paid_on_the_savings)


func _check_simple_interest_is_paid_on_the_savings(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var p := int(d.saved)
	var rate := int(d.rate)
	var years := int(d.years)
	assert_eq(p * rate % 100, 0, "whole gold")
	var interest := p * rate / 100 * years
	_number_is(ex, interest if str(d.ask) == "interest" else p + interest)
	assert_true(str(ex.prompt).contains("%d%%" % rate), "the rate is given")
	if level < 3:
		assert_eq(years, 1)
	else:
		assert_between(years, 2, 4)


func test_borrowing_costs_interest() -> void:
	_each("g5h.loan_cost", _check_borrowing_costs_interest)


func _check_borrowing_costs_interest(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"interest":
			_number_is(ex, int(d.back) - int(d.borrow))
			assert_gt(int(d.back), int(d.borrow))
		"pay_back":
			assert_eq(int(d.borrow) * int(d.rate) % 100, 0)
			_number_is(ex, int(d.borrow) + int(d.borrow) * int(d.rate) / 100)
		"each":
			assert_eq(int(d.back) % int(d.parts), 0)
			_number_is(ex, int(d.back) / int(d.parts))
		"cheaper":
			var a := int(d.parts) * int(d.each)
			var b := int(d.other)
			assert_ne(a, b)
			assert_eq(_answer(ex), "Loan A" if a < b else "Loan B")
		_:
			assert_true(false, "an ask: %s" % d.ask)


func test_a_class_measures_what_changed() -> void:
	_each("g5h.waste_change", _check_a_class_measures_what_changed)


func _check_a_class_measures_what_changed(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var weeks: Array = d.kg
	match str(d.ask):
		"less":
			_number_is(ex, int(weeks[0]) - int(weeks[-1]))
		"total":
			var t := 0
			for w: int in weeks:
				t += w
			_number_is(ex, t)
		"percent":
			var before := int(weeks[0])
			var after := int(weeks[-1])
			assert_eq((before - after) * 100 % before, 0, "a whole percentage")
			_number_is(ex, (before - after) * 100 / before)
		_:
			assert_true(false, "an ask: %s" % d.ask)
	assert_eq(int(ex.picture.rows.size()), weeks.size() + 1, "the table shows every week")
