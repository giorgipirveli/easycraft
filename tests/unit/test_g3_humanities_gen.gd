extends GutTest
## Owner #70 and #73, grade 3 history, geography and citizenship (G3HumanitiesGen, "g3h"): compass turns and directions
## on a map, grid references, years on a timeline (BC and AD, decades and centuries, years between), and the game's gold
## (earning, saving, choosing what to buy). Each generator's answer is worked out again here from the exercise's `data`,
## for many seeds and every level, and every exercise must be valid (ExerciseCheck, the picture's own check).

const SEEDS := 80
const POINTS: Array[String] = ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			assert_ne(str(ex.get("explain", "")), "", "%s: a worked answer" % gen)
			assert_true(ex.get("data") is Dictionary, "%s: its data" % gen)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % gen)
			check.call(ex, level)


## The right answer in words (a choice's text, a number, True or False, an order's items).
func _answer(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


## The table picture's cell for map square (col, row), below its header row (and right of its label column).
func _cell(ex: Dictionary, col: int, row: int, labels: bool) -> String:
	var rows: Array = ex.picture.rows
	var r: Array = rows[row + 1]
	return str(r[col + (1 if labels else 0)])


# --- Geography: compass directions ------------------------------------------------------------------------------------

func test_a_compass_turn_ends_where_the_steps_say() -> void:
	_each("g3h.compass_turn", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var start := int(d.start)
		var eighths := int(d.eighths)
		assert_true(str(ex.prompt).contains(POINTS[start]), "the prompt says where it starts")
		assert_eq(_answer(ex), POINTS[posmod(start + eighths, 8)], str(ex.prompt))
		assert_ne(eighths % 8, 0, "a turn that changes the way it faces")
		if level < 3:
			assert_eq(start % 2, 0, "levels 1 and 2 start on the four main points")
			assert_eq(eighths % 2, 0, "levels 1 and 2 turn in quarters")
		if level == 1:
			assert_eq(absi(eighths), 2, "level 1 is a quarter turn")
		var clockwise := str(ex.prompt).contains(" clockwise")
		var anti := str(ex.prompt).contains("anticlockwise")
		assert_true(clockwise or anti, "the prompt says which way")
		assert_eq(anti, eighths < 0, "anticlockwise turns count back"))


func test_the_direction_between_two_places_on_the_map() -> void:
	_each("g3h.compass_map", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var places: Dictionary = d.places
		for name: String in places:
			assert_eq(_cell(ex, int(places[name][0]), int(places[name][1]), false), name, "the map shows the %s" % name)
		assert_eq(str((ex.picture.rows as Array)[0][2]), "north", "north is at the top")
		var from: Array = places[str(d.from)]
		if level < 3:
			var to: Array = places[str(d.to)]
			var dx := int(to[0]) - int(from[0])
			var dy := int(from[1]) - int(to[1])   # rows go down the map: north is up
			assert_true(dx == 0 or dy == 0 or absi(dx) == absi(dy), "an exact compass direction")
			var words := ("north" if dy > 0 else ("south" if dy < 0 else ""))
			words += ("-" if dx != 0 and dy != 0 else "") + ("east" if dx > 0 else ("west" if dx < 0 else ""))
			assert_eq(_answer(ex), words, str(ex.prompt))
			if level == 1:
				assert_true(dx == 0 or dy == 0, "level 1: straight north, east, south or west")
		else:
			var at := Vector2i(int(from[0]) + int(d.dx), int(from[1]) - int(d.dy))
			var found := ""
			for name: String in places:
				if Vector2i(int(places[name][0]), int(places[name][1])) == at:
					found = name
			assert_ne(found, "", "the walk ends on a place")
			assert_eq(_answer(ex), found, str(ex.prompt)))


# --- Geography: grid references ---------------------------------------------------------------------------------------

func test_a_grid_reference_is_along_the_corridor_then_up_the_stairs() -> void:
	_each("g3h.grid_ref", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var cols: Array = d.cols
		var rows: Array = d.rows
		var header: Array = (ex.picture.rows as Array)[0]
		for i in cols.size():
			assert_eq(str(header[i + 1]), str(cols[i]), "the columns' labels")
		for j in rows.size():
			assert_eq(str((ex.picture.rows as Array)[j + 1][0]), str(rows[j]), "the rows' labels")
		var places: Dictionary = d.places
		for name: String in places:
			assert_eq(_cell(ex, int(places[name][0]), int(places[name][1]), true), name, "the map shows the %s" % name)
		if level == 1:
			assert_true(str(cols[0]) == "A", "level 1: letters along, numbers up")
		else:
			assert_eq(str(cols[0]).length(), 2, "two figures along")
			assert_eq(str(rows[0]).length(), 2, "two figures up")
			assert_gt(int(rows[0]), int(rows[-1]), "the numbers go up the map")
		var p: Array = places[str(d.place)]
		var ref := str(cols[int(p[0])]) + str(rows[int(p[1])])
		if str(d.ask) == "ref":
			assert_eq(_answer(ex), ref, str(ex.prompt))
		else:
			assert_true(str(ex.prompt).contains(ref), "the prompt names the square")
			assert_eq(_answer(ex), str(d.place), str(ex.prompt)))


# --- History: timelines -----------------------------------------------------------------------------------------------

## "500 BC" or "500 BCE" -> -500; "AD 43", "43 CE" or "1066" -> the year.
func _year_value(text: String) -> int:
	var t := text.strip_edges()
	if t.ends_with(" BC") or t.ends_with(" BCE"):
		return -int(t.get_slice(" ", 0))
	if t.begins_with("AD "):
		return int(t.get_slice(" ", 1))
	return int(t.get_slice(" ", 0))


func test_years_go_in_order_earliest_first() -> void:
	_each("g3h.year_order", func(ex: Dictionary, level: int) -> void:
		var values: Array = ex.data.values
		var items: Array = ex.items
		assert_eq(values.size(), items.size())
		for i in items.size():
			assert_eq(_year_value(str(items[i])), int(values[i]), "item %s is the year %s" % [items[i], values[i]])
		for i in range(1, (ex.answer as Array).size()):
			assert_lt(int(values[int(ex.answer[i - 1])]), int(values[int(ex.answer[i])]), str(ex.items))
		var bc := false
		for v: Variant in values:
			bc = bc or int(v) < 0
		if level == 1:
			assert_false(bc, "level 1: AD years only")
		if level == 2:
			assert_true(bc, "level 2 counts BC years"))


func _ordinal(n: int) -> String:
	if n % 100 in [11, 12, 13]:
		return "%dth" % n
	match n % 10:
		1:
			return "%dst" % n
		2:
			return "%dnd" % n
		3:
			return "%drd" % n
	return "%dth" % n


func test_decades_and_centuries() -> void:
	_each("g3h.decade_century", func(ex: Dictionary, level: int) -> void:
		var y := int(ex.data.year)
		assert_true(str(ex.prompt).contains(str(y)), "the prompt names the year")
		if level == 1:
			assert_eq(_answer(ex), "the %ds" % (y / 10 * 10), str(ex.prompt))
		elif level == 2:
			assert_eq(_answer(ex), "the %ds" % (y / 100 * 100), str(ex.prompt))
		else:
			assert_ne(y % 100, 0, "never a year that ends a century (1900 is the last of the 19th)")
			assert_eq(_answer(ex), "the %s century" % _ordinal((y - 1) / 100 + 1), str(ex.prompt)))


func test_years_between_two_dates() -> void:
	_each("g3h.years_between", func(ex: Dictionary, level: int) -> void:
		var a := int(ex.data.from)
		var b := int(ex.data.to)
		assert_lt(a, b, "from the earlier year to the later one")
		assert_true((a < 0) == (b < 0), "both BC or both AD (no year 0 to trip over)")
		assert_eq(str(ex.answer), str(b - a), str(ex.prompt))
		if level == 3:
			assert_lt(b, 0, "level 3 counts BC years"))


# --- Citizenship: the game's gold -------------------------------------------------------------------------------------

func test_saving_for_a_goal_takes_enough_days() -> void:
	_each("g3h.coins_save", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var need := int(d.goal) - int(d.have)
		var days := ceili(float(need) / int(d.rate))
		assert_gt(need, 0, "something left to save")
		assert_eq(str(ex.answer), str(days), str(ex.prompt))
		assert_true(int(d.have) + days * int(d.rate) >= int(d.goal), "enough after that many days")
		assert_true(int(d.have) + (days - 1) * int(d.rate) < int(d.goal), "not enough a day sooner")
		if level < 3:
			assert_eq(need % int(d.rate), 0, "levels 1 and 2 come out exactly"))


func test_choosing_what_to_buy_with_the_gold_there_is() -> void:
	_each("g3h.coins_spend", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var have := int(d.have)
		var prices: Array = d.prices
		var names: Array = d.names
		if level == 1:
			assert_eq(ex.answer, int(prices[0]) + int(prices[1]) <= have, str(ex.prompt))
		elif level == 2:
			assert_eq(str(ex.answer), str(have - int(prices[0])), str(ex.prompt))
			assert_lte(int(prices[0]), have, "it can be bought")
		else:
			var fits: Array[String] = []
			var given_up := ""
			for i in 3:
				for j in range(i + 1, 3):
					if int(prices[i]) + int(prices[j]) <= have:
						fits.append("the %s and the %s" % [names[i], names[j]])
						given_up = str(names[3 - i - j])
			assert_eq(fits.size(), 1, "exactly one pair fits: %s" % [fits])
			if fits.size() == 1:
				assert_eq(_answer(ex), fits[0], str(ex.prompt))
				assert_true(str(ex.explain).ends_with("gives up the %s." % given_up), "it says what is given up: %s" % ex.explain))
	var trues := 0
	for s in 40:
		if SchoolGen.make("g3h.coins_spend", s, 1).answer == true:
			trues += 1
	assert_between(trues, 8, 32, "yes and no both come up")


func test_earning_gold_for_work() -> void:
	_each("g3h.coins_earn", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var earned := int(d.rate) * int(d.count)
		assert_eq(str(ex.answer), str(earned - int(d.spent)), str(ex.prompt))
		if level < 3:
			assert_eq(int(d.spent), 0, "levels 1 and 2 only earn")
		else:
			assert_between(int(d.spent), 1, earned - 1, "level 3 spends some and keeps some"))
