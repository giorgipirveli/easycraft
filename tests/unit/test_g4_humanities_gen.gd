extends GutTest
## Owner #70 and #73, grade 4 history, geography and citizenship (G4HumanitiesGen, "g4h"): years apart across BC and AD
## and dated events of the first civilisations in order, Egyptian and Babylonian numbers and time in sixties, map scales,
## capitals of the world, Europe and the Americas, fieldwork data (traffic and weather), and the game's gold with
## decimals (best value, change and card balances, adverts' deals, a town's budget) and votes. Each generator's answer
## is worked out again here from the exercise's `data` (and the capitals from this file's own facts), for many seeds
## and every level, and every exercise must be valid (ExerciseCheck, the picture's own check).

const SEEDS := 80
## This test's own facts (typed apart from the generator's tables): country -> [capital, continent].
const CAPITALS := {
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
## Capitals that are not their country's biggest city: country -> the biggest city.
const BIGGEST := {"Australia": "Sydney", "Canada": "Toronto", "Brazil": "Sao Paulo", "the United States": "New York",
	"Nigeria": "Lagos", "Pakistan": "Karachi", "New Zealand": "Auckland", "Morocco": "Casablanca", "Turkey": "Istanbul",
	"Vietnam": "Ho Chi Minh City"}
## The river through a European capital.
const RIVERS := {"London": "Thames", "Paris": "Seine", "Rome": "Tiber", "Vienna": "Danube", "Budapest": "Danube",
	"Berlin": "Spree", "Prague": "Vltava", "Lisbon": "Tagus", "Warsaw": "Vistula", "Dublin": "Liffey"}
const EGYPT_SIGNS := {"lotus flowers": 1000, "coils of rope": 100, "heel bones": 10, "strokes": 1}


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


## Gold in hundredths (cents) as the lessons write it: 250 -> "2.50", 300 -> "3".
func _gold(cents: int) -> String:
	return str(cents / 100) if cents % 100 == 0 else "%d.%02d" % [cents / 100, cents % 100]


## "3000 BC" -> -3000, "AD 43" -> 43 (the years' words the generators write).
func _signed_year(text: String) -> int:
	var re := RegEx.create_from_string("(AD )?([0-9,]+)( BC)?")
	var m := re.search(text)
	var n := int(m.get_string(2).replace(",", ""))
	return -n if m.get_string(3) != "" else n


# --- History: years and events ---------------------------------------------------------------------------------------

func test_years_apart_count_down_in_bc_and_skip_the_year_0() -> void:
	_each("g4h.years_apart", func(ex: Dictionary, level: int) -> void:
		var a := int(ex.data.from)
		var b := int(ex.data.to)
		assert_lt(a, b, "the earlier year first")
		var expected := b - a - (1 if a < 0 and b > 0 else 0)   # 1 BC is followed by AD 1: there is no year 0
		_number_is(ex, expected)
		if level == 1:
			assert_true(a < 0 and b < 0 and a % 100 == 0 and b % 100 == 0, "level 1: whole hundreds BC")
		elif level == 2:
			assert_true(a < 0 and b < 0, "level 2: two BC events")
		else:
			assert_true(a < 0 and b > 0, "level 3: from BC to AD")
			assert_true(str(ex.prompt).contains("no year 0"), "level 3 says there is no year 0")
		assert_true(str(ex.prompt).contains(_digits(absi(a))) and str(ex.prompt).contains(_digits(absi(b))),
			"the prompt gives both years"))


## A year's digits as the lessons write them: 3100, but 10,000.
func _digits(n: int) -> String:
	return str(n) if n < 10000 else GenKit.fmt(n)


func test_events_go_in_order_of_their_years() -> void:
	_each("g4h.event_order", func(ex: Dictionary, level: int) -> void:
		var years: Array[int] = []
		for item: Variant in ex.items:
			years.append(_signed_year(str(item)))
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
				assert_gte(ordered[k] - ordered[k - 1], 400, "level 1: far apart")
		if level == 2:
			assert_lt(ordered[-1], 0, "level 2: all BC")
		if level == 3:
			assert_true(ordered[0] < 0 and ordered[-1] > 0, "level 3: BC and AD"))


# --- History: how ancient people counted ----------------------------------------------------------------------------

func test_egyptian_numbers_add_up_their_signs() -> void:
	_each("g4h.egypt_number", func(ex: Dictionary, level: int) -> void:
		var v := int(ex.data.value)
		var digits := [v / 1000, v / 100 % 10, v / 10 % 10, v % 10]
		if level < 3:
			assert_eq(str(ex.picture.kind), "numerals")
			assert_eq(str(ex.picture.system), "egypt")
			assert_eq(int(ex.picture.value), v, "the picture shows the number")
			_number_is(ex, v)
			assert_between(v, 1000 if level == 2 else 11, 999 if level == 1 else 9999)
		else:
			assert_true(str(ex.prompt).contains(GenKit.fmt(v)), "the prompt gives the number")
			var ask := str(ex.data.ask)
			if ask == "signs":
				_number_is(ex, digits[0] + digits[1] + digits[2] + digits[3])
			else:
				assert_true(EGYPT_SIGNS.has(ask), ask)
				assert_true(str(ex.prompt).contains(ask), "the prompt names the sign")
				_number_is(ex, v / int(EGYPT_SIGNS[ask]) % 10))


func test_sixties_count_minutes_and_babylonian_places() -> void:
	_each("g4h.sixties", func(ex: Dictionary, level: int) -> void:
		var kind := str(ex.data.kind)
		if kind == "babylon":
			var s := int(ex.data.sixties)
			var o := int(ex.data.ones)
			assert_between(s, 1, 59)
			assert_between(o, 1, 59)
			assert_eq(str(ex.picture.system), "babylon")
			assert_eq(int(ex.picture.value), s * 60 + o, "the picture shows the number")
			_number_is(ex, s * 60 + o)
			assert_gte(level, 2)
		elif kind == "hours_minutes":
			var n := int(ex.data.minutes)
			assert_true(str(ex.prompt).contains("%d minutes is %d hour" % [n, n / 60]), str(ex.prompt))
			_number_is(ex, n % 60)
			assert_ne(n % 60, 0)
			assert_eq(level, 3)
		else:
			assert_eq(level, 1)
			assert_true(kind in ["minutes", "seconds"], kind)
			var n := int(ex.data.n)
			assert_true(str(ex.prompt).contains(str(n)))
			_number_is(ex, n * 60))


# --- Geography: scale, capitals and fieldwork ------------------------------------------------------------------------

func test_map_scales_turn_centimetres_into_real_distances() -> void:
	_each("g4h.map_scale", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var per := int(d.m_per_cm)
		var cm := 0.0
		for leg: Variant in d.legs:
			cm += float(leg)
		var real_m := cm * per
		var in_unit := real_m / (1000.0 if str(d.unit) == "km" else 1.0)
		if int(d.get("ratio", 0)) > 0:
			assert_eq(int(d.ratio), per * 100, "1 : n means 1 cm is n cm, which is n ÷ 100 m")
			assert_true(str(ex.prompt).contains(GenKit.fmt(int(d.ratio))), "the prompt gives the ratio")
		if str(d.ask) == "map":
			_number_is(ex, cm)
			assert_true(str(ex.prompt).contains("%s %s" % [_num(in_unit), d.unit]), "the prompt gives the real distance")
		else:
			_number_is(ex, in_unit)
			for leg: Variant in d.legs:
				assert_true(str(ex.prompt).contains("%s cm" % _num(float(leg))), "the prompt gives each leg")
		if level == 1:
			assert_true(per in [2000, 5000, 10000] and (d.legs as Array).size() == 1, "level 1: 1 cm is 2, 5 or 10 km"))


func _num(v: float) -> String:
	return GenKit.fmt(roundi(v)) if absf(v - roundf(v)) < 0.0001 else String.num(v, 2)


func _capital_check(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	var country := str(d.country)
	assert_true(CAPITALS.has(country), "a country this test knows: %s" % country)
	if not CAPITALS.has(country):
		return
	var capital := str(CAPITALS[country][0])
	match str(d.ask):
		"capital":
			assert_eq(_answer(ex), capital, str(ex.prompt))
			assert_true(str(ex.prompt).contains(country))
		"country":
			assert_true(str(ex.prompt).contains(capital))
			assert_eq(_answer(ex), country.substr(0, 1).to_upper() + country.substr(1), str(ex.prompt))
			for c: Variant in ex.choices:
				var plain := str(c)
				if plain.begins_with("The "):
					plain = "the " + plain.substr(4)
				assert_true(plain == country or str(CAPITALS[plain][0]) != capital, "one right country")
		"continent":
			assert_ne(str(CAPITALS[country][1]), "", "a country with one continent")
			assert_eq(_answer(ex), str(CAPITALS[country][1]), str(ex.prompt))
		"biggest":
			assert_eq(_answer(ex), capital, str(ex.prompt))
			assert_true(BIGGEST.has(country), country)
			assert_true((ex.choices as Array).has(BIGGEST.get(country, "")), "the biggest city is a wrong choice")
			assert_eq(level, 3)
		"river":
			assert_eq(_answer(ex), str(RIVERS[capital]), str(ex.prompt))
			assert_true(str(ex.prompt).contains(capital))
		"half":
			var north: bool = CAPITALS[country][1] == "North America"
			assert_eq(_answer(ex), "North America" if north else "South America", str(ex.prompt))
		_:
			fail_test("unknown ask %s" % d.ask)
	for c: Variant in ex.get("choices", []):
		if str(d.ask) == "capital" and c != capital:
			for k: String in CAPITALS:
				if CAPITALS[k][0] == c:
					assert_ne(k, country, "a wrong capital is another country's")


func test_world_capitals() -> void:
	_each("g4h.world_capital", _capital_check)


func test_europe_capitals_and_rivers() -> void:
	_each("g4h.europe_capital", func(ex: Dictionary, level: int) -> void:
		_capital_check(ex, level)
		assert_true(str(ex.data.ask) == "river" or CAPITALS[str(ex.data.country)][1] == "Europe", "a European country"))


func test_americas_capitals() -> void:
	_each("g4h.americas_capital", func(ex: Dictionary, level: int) -> void:
		_capital_check(ex, level)
		assert_true(str(CAPITALS[str(ex.data.country)][1]).ends_with("America"), "a country in the Americas"))


func test_a_traffic_survey_reads_from_its_bar_graph() -> void:
	_each("g4h.survey_count", _check_survey)


func _check_survey(ex: Dictionary, level: int) -> void:
	var counts: Dictionary = ex.data.counts
	var bars: Array = ex.picture.bars
	assert_eq(bars.size(), counts.size())
	for bar: Array in bars:
		assert_eq(int(bar[1]), int(counts[str(bar[0])]), "the graph shows %s" % bar[0])
	var most := ""
	for k: String in counts:
		if most == "" or int(counts[k]) > int(counts[most]):
			most = k
	var total := 0
	for k: String in counts:
		total += int(counts[k])
	match str(ex.data.ask):
		"how_many":
			_number_is(ex, int(counts[str(ex.data.a)]))
		"most":
			assert_eq(_answer(ex), most)
			for k: String in counts:
				assert_true(k == most or int(counts[k]) < int(counts[most]), "one kind is the most")
		"more":
			_number_is(ex, int(counts[str(ex.data.a)]) - int(counts[str(ex.data.b)]))
		"total":
			_number_is(ex, total)
		"hour":
			_number_is(ex, int(counts[str(ex.data.a)]) * 6)
			assert_eq(level, 3)
		_:
			fail_test("unknown ask")


func test_a_weather_record_reads_from_its_table() -> void:
	_each("g4h.weather_table", _check_weather)


func _check_weather(ex: Dictionary, level: int) -> void:
	var days: Array = ex.data.days
	var temps: Array = ex.data.temps
	var rain: Array = ex.data.rain
	var rows: Array = ex.picture.rows
	for i in days.size():
		assert_eq(str(rows[i + 1][0]), str(days[i]))
		assert_eq(str(rows[i + 1][1]), str(temps[i]).replace("-", "−"))
		assert_eq(str(rows[i + 1][2]), str(rain[i]))
	var hot := 0
	var cold := 0
	var wet := 0
	for i in temps.size():
		if int(temps[i]) > int(temps[hot]):
			hot = i
		if int(temps[i]) < int(temps[cold]):
			cold = i
		wet += int(rain[i])
	match str(ex.data.ask):
		"warmest":
			assert_eq(_answer(ex), str(days[hot]))
			assert_eq(temps.count(temps[hot]), 1, "one warmest day")
		"rain_on":
			_number_is(ex, int(rain[days.find(str(ex.data.a))]))
		"warmer":
			_number_is(ex, int(temps[days.find(str(ex.data.a))]) - int(temps[days.find(str(ex.data.b))]))
		"week_rain":
			_number_is(ex, wet)
		"range":
			_number_is(ex, int(temps[hot]) - int(temps[cold]))
			assert_lt(int(temps[cold]), 0, "level 3: a minus temperature")
		_:
			fail_test("unknown ask")


# --- Citizenship: gold with decimals, a town's budget, votes -----------------------------------------------------------

func test_best_value_compares_the_price_of_one() -> void:
	_each("g4h.best_value", _check_best_value)


func _check_best_value(ex: Dictionary, level: int) -> void:
	var a: Dictionary = ex.data.a
	var b: Dictionary = ex.data.b
	for p: Dictionary in [a, b]:
		assert_true(str(ex.prompt).contains(_gold(int(p.cents)) + " gold"), "the prompt gives %s" % _gold(int(p.cents)))
	match str(ex.data.ask):
		"save":
			_number_is(ex, absi(int(a.cents) - int(b.cents)) / 100.0)
			assert_eq(level, 1)
		"better":
			var ea := float(a.cents) / int(a.n)
			var eb := float(b.cents) / int(b.n)
			assert_ne(ea, eb, "one pack is better value")
			var best: Dictionary = a if ea < eb else b
			assert_true(_answer(ex).contains("pack of %d" % int(best.n)), "%s: %s" % [ex.prompt, _answer(ex)])
			assert_eq(int(a.cents) % int(a.n), 0, "the price for one is whole hundredths")
			assert_eq(int(b.cents) % int(b.n), 0, "the price for one is whole hundredths")
		"each":
			_number_is(ex, float(a.cents) / int(a.n) / 100.0)
		_:
			fail_test("unknown ask")


func test_change_and_card_balances() -> void:
	_each("g4h.change_due", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if d.has("paid"):
			assert_lt(int(d.price), int(d.paid))
			assert_true(str(ex.prompt).contains(_gold(int(d.price))) and str(ex.prompt).contains(_gold(int(d.paid))))
			_number_is(ex, (int(d.paid) - int(d.price)) / 100.0)
			if level == 1:
				assert_eq(int(d.price) % 100, 0, "level 1: whole gold")
		else:
			assert_eq(level, 3)
			var left := int(d.start)
			for p: Variant in d.payments:
				left -= int(p)
				assert_true(str(ex.prompt).contains(_gold(int(p))), "the prompt gives each payment")
			assert_gt(left, 0)
			_number_is(ex, left / 100.0))


func test_deals_in_adverts_are_worked_out() -> void:
	_each("g4h.deal_check", _check_deal)


func _check_deal(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"was_now":
			_number_is(ex, (int(d.was) - int(d.now)) / 100.0)
		"deal":
			# buy k, get 1 free: every (k + 1)th thing is free
			var k := int(d.buy)
			var need := int(d.need)
			var paid := need - need / (k + 1)
			_number_is(ex, paid * int(d.price) / 100.0)
		"compare":
			var k := int(d.buy)
			var need := int(d.need)
			var a := (need - need / (k + 1)) * int(d.price)
			var b := need * int(d.other)
			assert_ne(a, b, "one stall is cheaper")
			_number_is(ex, absi(a - b) / 100.0)
			assert_eq(level, 3)
		_:
			fail_test("unknown ask")


func test_a_town_budget_adds_shares_and_subtracts() -> void:
	_each("g4h.town_budget", _check_budget)


func _check_budget(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"sum":
			_number_is(ex, int(d.a) + int(d.b))
		"left":
			_number_is(ex, int(d.total) - int(d.a))
		"share":
			assert_eq(int(d.cost) % int(d.families), 0, "an equal whole share")
			_number_is(ex, int(d.cost) / int(d.families))
		"budget":
			_number_is(ex, int(d.total) - int(d.a) - int(d.b))
			assert_gt(int(d.total) - int(d.a) - int(d.b), 0)
		_:
			fail_test("unknown ask")


func test_votes_find_the_winner_and_a_majority() -> void:
	_each("g4h.vote_count", _check_votes)


func _check_votes(ex: Dictionary, level: int) -> void:
	var votes: Dictionary = ex.data.votes
	var total := 0
	var top := ""
	for k: String in votes:
		total += int(votes[k])
		if top == "" or int(votes[k]) > int(votes[top]):
			top = k
	for k: String in votes:
		assert_true(k == top or int(votes[k]) < int(votes[top]), "one winner")
	for bar: Array in ex.picture.bars:
		assert_eq(int(bar[1]), int(votes[str(bar[0])]), "the graph shows the votes for %s" % bar[0])
	match str(ex.data.ask):
		"winner":
			assert_eq(_answer(ex), top)
		"more":
			_number_is(ex, int(votes[top]) - int(votes[str(ex.data.a)]))
		"total":
			_number_is(ex, total)
		"majority":
			assert_eq(str(ex.type), "truefalse")
			assert_eq(ex.answer, int(votes[top]) * 2 > total, str(ex.prompt))
			assert_eq(level, 3)
		"need":
			_number_is(ex, total / 2 + 1)
			assert_eq(level, 3)
		_:
			fail_test("unknown ask")


## Level 3 majority questions are sometimes true and sometimes false (a child cannot guess "yes").
func test_majority_questions_go_both_ways() -> void:
	var seen := {}
	for s in SEEDS:
		var ex := SchoolGen.make("g4h.vote_count", s, 3)
		if str(ex.get("type", "")) == "truefalse":
			seen[ex.answer] = true
	assert_eq(seen.size(), 2, "true and false both come up")
