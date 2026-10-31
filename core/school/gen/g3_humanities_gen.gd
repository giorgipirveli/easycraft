class_name G3HumanitiesGen
extends RefCounted
## Owner #70 and #73 (research §6.3): grade 3 history, geography and citizenship generators: compass turns and the
## direction between places on a map, grid references (letters and numbers, then four figures), years on a timeline
## (BC and AD, decades and centuries, years between), and the game's gold (earning, saving, choosing what to buy, whole
## coins at grade 3, research §5.5 ruling 6). SchoolGen "g3h.<name>", `static func <name>(rng: RandomNumberGenerator,
## level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs,
## for tests/unit/test_g3_humanities_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
## Eight compass points, clockwise from north (an index is a number of eighths of a turn from north).
const POINTS: Array[String] = ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
const TURNS := {1: "an eighth of a turn", 2: "a quarter turn", 4: "a half turn", 6: "a three-quarter turn"}
const PEOPLE := {"Tilly": ["she", "her"], "Zara": ["she", "her"], "Bram": ["he", "his"], "Mimi": ["she", "her"]}
## Map places (short words, so every one fits a table cell of the exercise's picture).
const PLACES: Array[String] = ["farm", "well", "pond", "barn", "mill", "hut", "cave", "shop", "park", "camp", "tower"]
const MAP_COLS := 5
const MAP_ROWS := 4
const LETTERS: Array[String] = ["A", "B", "C", "D", "E"]
## [who, one thing, many, what they do] for earning gold (the game's helpers and their jobs, spec §14.17).
const JOBS: Array = [["Mimi", "cake", "cakes", "bakes"], ["Bram", "tree", "trees", "plants"],
	["Zara", "map", "maps", "draws"], ["Tilly", "basket", "baskets", "weaves"]]
const GOALS: Array[String] = ["a saddle", "a glider", "a lantern", "a bookshelf", "a telescope", "a boat"]
const THINGS: Array[String] = ["lantern", "kite", "book", "bell", "hat", "ball", "rope", "bucket"]


# --- Geography: compass directions (g3.geography.compass_directions) ---------------------------------------------------

## "Zara faces north and makes a quarter turn clockwise. Which way is she facing now?" Level 1: the four main points and
## a quarter turn; level 2: quarter, half and three-quarter turns; level 3: all eight points, eighth turns too.
static func compass_turn(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = PEOPLE.keys()[rng.randi_range(0, PEOPLE.size() - 1)]
	var start := rng.randi_range(0, 3) * 2 if level < 3 else rng.randi_range(0, 7)
	var sizes: Array = [2] if level == 1 else ([2, 4, 6] if level == 2 else [1, 2, 4, 6])
	var size: int = sizes[rng.randi_range(0, sizes.size() - 1)]
	var clockwise := rng.randf() < 0.6 or size == 4
	var eighths := size if clockwise else -size
	var end_at := posmod(start + eighths, 8)
	var way := "clockwise" if clockwise else "anticlockwise"
	var prompt := "%s faces %s and makes %s %s. Which way is %s facing now?" % [who, POINTS[start], TURNS[size], way,
		PEOPLE[who][0]]
	var step := 1 if level == 3 else 2
	var path: Array[String] = []
	for i in range(1, int(absi(eighths) / float(step)) + 1):
		path.append(POINTS[posmod(start + (i * step if clockwise else -i * step), 8)])
	var hint := "Clockwise goes the way a clock's hands go: north, east, south, west. A quarter turn is one of those steps."
	if level == 3:
		hint = "On an eight-point compass, an eighth of a turn is one point, a quarter turn two points, a half turn four."
	var explain := "%s from %s: %s. %s now faces %s." % [way.capitalize(), POINTS[start], ", ".join(path), who,
		POINTS[end_at]]
	var wrongs: Array = []
	var other := POINTS[posmod(start - eighths, 8)]
	if level == 3:
		for w: String in [other, POINTS[start], POINTS[posmod(end_at + 4, 8)], POINTS[posmod(end_at + 1, 8)],
				POINTS[posmod(end_at - 1, 8)]]:
			if w != POINTS[end_at] and not wrongs.has(w) and wrongs.size() < 3:
				wrongs.append(w)
	else:
		for i in 4:
			if i * 2 != end_at:
				wrongs.append(POINTS[i * 2])
	var ex := K.choice(rng, prompt, POINTS[end_at], wrongs, hint, explain)
	ex.data = {"start": start, "eighths": eighths}
	return ex


## A map (a table: north at the top) with places on it. Level 1: "Which direction is the well from the farm?" straight
## north, east, south or west; level 2: the eight points; level 3: "Start at the farm. Walk 2 squares east, then 1 square
## north. Where are you?"
static func compass_map(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := _pick(rng, PLACES, 3 if level == 1 else 4)
	var cells := _cells(rng)
	var from := cells[0]
	# level 1: straight; level 2: mostly a diagonal (the same number of squares each way), at times straight; level 3:
	# any square off the start's row and column. Every square has a straight and a diagonal neighbour, so none is empty.
	var diagonal_now := level == 2 and rng.randf() < 0.7
	var fit: Array[Vector2i] = []
	for c: Vector2i in cells.slice(1):
		var dx := c.x - from.x
		var dy := from.y - c.y
		var straight := dx == 0 or dy == 0
		var diagonal := not straight and absi(dx) == absi(dy)
		if (level == 1 or level == 2 and not diagonal_now) and straight or diagonal_now and diagonal \
				or level == 3 and not straight:
			fit.append(c)
	var to := fit[rng.randi_range(0, fit.size() - 1)]
	var spots: Array[Vector2i] = [from, to]
	for c in cells:
		if spots.size() >= names.size():
			break
		if not spots.has(c):
			spots.append(c)
	var places := {}
	for i in names.size():
		places[names[i]] = [spots[i].x, spots[i].y]
	var picture := _map_picture(places)
	var dx := to.x - from.x
	var dy := from.y - to.y
	var ex: Dictionary
	if level < 3:
		var right := _direction(dx, dy)
		var wrongs: Array = []
		for w: String in [_direction(-dx, -dy), _direction(dy, dx), _direction(-dy, -dx), _direction(dx, -dy),
				_direction(-dx, dy)]:
			if w != right and not wrongs.has(w) and wrongs.size() < 3:
				wrongs.append(w)
		for w: String in (POINTS if level == 2 else ["north", "east", "south", "west"]):
			if w != right and not wrongs.has(w) and wrongs.size() < 3:
				wrongs.append(w)
		ex = K.choice(rng, "North is at the top of this map. Which direction is the %s from the %s?" % [names[1], names[0]],
			right, wrongs, "Put your finger on the %s first, then see which way you move to reach the %s." % [names[0],
				names[1]],
			"From the %s, the %s is %s: %s. So it is %s of the %s." % [names[0], names[1], _steps(dx, dy),
				"straight along" if dx == 0 or dy == 0 else "the same number of squares each way", right, names[0]],
			picture)
	else:
		var walk := "Walk %s, then %s." % [_squares(absi(dx), "east" if dx > 0 else "west"),
			_squares(absi(dy), "north" if dy > 0 else "south")]
		var wrongs: Array = []
		for n in names:
			if n != names[1]:
				wrongs.append(n)
		ex = K.choice(rng, "North is at the top. Start at the %s. %s Where are you?" % [names[0], walk], names[1], wrongs,
			"East is to the right and north is up. Move one square at a time with your finger.",
			"From the %s: %s. You reach the %s." % [names[0], _steps(dx, dy), names[1]], picture)
		ex.data = {"places": places, "from": names[0], "dx": dx, "dy": dy}
		return ex
	ex.data = {"places": places, "from": names[0], "to": names[1]}
	return ex


# --- Geography: grid references (g3.geography.grid_references) -------------------------------------------------------

## A map with labelled columns and rows. Level 1: letters along and numbers up ("B3"); levels 2 and 3: four-figure grid
## references ("1436": the column's number, then the row's). Half ask "What is the grid reference of the well?", half
## "What is in square 1436?" (always the second at level 3).
static func grid_ref(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n_cols := 4 if level == 1 else 5
	var n_rows := 4 if level < 3 else 5
	var cols: Array[String] = []
	var rows: Array[String] = []   # top to bottom
	if level == 1:
		for i in n_cols:
			cols.append(LETTERS[i])
		for j in n_rows:
			rows.append(str(n_rows - j))
	else:
		var e0 := rng.randi_range(10, 25)
		var n0 := rng.randi_range(30, 60)
		for i in n_cols:
			cols.append(str(e0 + i))
		for j in n_rows:
			rows.append(str(n0 + n_rows - 1 - j))
	var names := _pick(rng, PLACES, 4)
	var spots: Array[Vector2i] = []
	while spots.size() < names.size():
		var c := Vector2i(rng.randi_range(0, n_cols - 1), rng.randi_range(0, n_rows - 1))
		if not spots.has(c):
			spots.append(c)
	var places := {}
	for i in names.size():
		places[names[i]] = [spots[i].x, spots[i].y]
	var header: Array = [""]
	header.append_array(cols)
	var table: Array = [header]
	for j in n_rows:
		var row: Array = [rows[j]]
		for i in n_cols:
			row.append("")
		table.append(row)
	for n: String in places:
		table[int(places[n][1]) + 1][int(places[n][0]) + 1] = n
	var picture := {"kind": "table", "rows": table}
	var place := names[0]
	var at := spots[0]
	var ref := cols[at.x] + rows[at.y]
	var ask := "ref" if level < 3 and rng.randf() < 0.5 else "place"
	var along := "letter" if level == 1 else "number"
	var hint := "Along the corridor, then up the stairs: the column's %s first, then the row's number." % along
	var explain := "The %s is in column %s and row %s, so its square is %s." % [place, cols[at.x], rows[at.y], ref]
	var ex: Dictionary
	if ask == "ref":
		var wrongs: Array = []
		var swapped := rows[at.y] + cols[at.x]
		for c: Vector2i in [at + Vector2i(1, 0), at + Vector2i(-1, 0), at + Vector2i(0, 1), at + Vector2i(0, -1)]:
			if c.x >= 0 and c.x < n_cols and c.y >= 0 and c.y < n_rows:
				wrongs.append(cols[c.x] + rows[c.y])
		GenKit.shuffle(rng, wrongs)
		wrongs = [swapped] + wrongs.slice(0, 2)   # the numbers the wrong way round, and a square next to it
		ex = K.choice(rng, "What is the grid reference of the %s?" % place, ref, wrongs, hint, explain, picture)
	else:
		var wrongs: Array = names.slice(1)
		ex = K.choice(rng, "What is in square %s?" % ref, place, wrongs, hint, explain, picture)
	ex.data = {"cols": cols, "rows": rows, "places": places, "place": place, "ask": ask}
	return ex


# --- History: timelines (g3.history.timelines) ----------------------------------------------------------------------------

## "Put these years in order on a timeline, earliest first." Level 1: three AD years; level 2: BC years (and one AD at
## times); level 3: four years, BC and AD (or BCE and CE).
static func year_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := 3 if level < 3 else 4
	var common_era := level == 3 and rng.randf() < 0.4
	var values: Array[int] = []
	while values.size() < n:
		var v: int
		if level == 1:
			v = rng.randi_range(100, 2020)
		elif level == 2:
			v = -rng.randi_range(1, 40) * 100 if values.size() < 2 or rng.randf() < 0.6 else rng.randi_range(1, 20) * 100
		else:
			v = -rng.randi_range(1, 50) * 100 if values.size() % 2 == 0 else rng.randi_range(1, 2020)
		if not values.has(v):
			values.append(v)
	var in_order := values.duplicate()
	in_order.sort()
	var words: Array = []
	for v: int in in_order:
		words.append(_year(v, level, common_era))
	var ex := K.order(rng, "Put these years in order on a timeline, earliest first.", words,
		"BC years count down to AD 1: the bigger the BC number, the longer ago. AD years count up." if level > 1
			else "The smaller the year, the longer ago it was.",
		"Earliest first: %s." % ", ".join(words))
	var shown: Array = []
	for item: Variant in ex.items:
		shown.append(in_order[words.find(item)])
	ex.data = {"values": shown}
	return ex


## Level 1: "Which decade is 1987 in?" (the 1980s); level 2: "Which hundred years is 1642 in?" (the 1600s); level 3:
## "Which century is 1642 in?" (the 17th century: the 1st century was the years 1 to 100).
static func decade_century(rng: RandomNumberGenerator, level: int) -> Dictionary:
	# Level 1 never names a decade "the 1900s" (that reads as a hundred years); level 3 never a year ending in 00.
	var y := rng.randi_range(180, 199) * 10 + rng.randi_range(0, 9)
	while level == 1 and _down(y, 10) % 100 == 0:
		y += 10
	if level == 2:
		y = rng.randi_range(1100, 1999)
	elif level == 3:
		y = rng.randi_range(2, 19) * 100 + rng.randi_range(1, 99)
	var ex: Dictionary
	if level == 1:
		var d := _down(y, 10)
		ex = K.choice(rng, "A decade is 10 years. Which decade is the year %d in?" % y, "the %ds" % d,
			["the %ds" % (d - 10), "the %ds" % (d + 10), "the %ds" % (d - 100)],
			"Keep the first three figures of the year and put a 0 at the end.",
			"%d starts with %d, so it is in the %ds (the years %d to %d)." % [y, int(d / 10.0), d, d, d + 9])
	elif level == 2:
		var h := _down(y, 100)
		ex = K.choice(rng, "Which hundred years is the year %d in?" % y, "the %ds" % h,
			["the %ds" % (h - 100), "the %ds" % (h + 100), "the %ds" % (h + 200 if h < 1800 else h - 200)],
			"Keep the first two figures of the year and put two 0s after them.",
			"%d starts with %d, so it is in the %ds (the years %d to %d)." % [y, int(h / 100.0), h, h, h + 99])
	else:
		var c := int(_down(y - 1, 100) / 100.0) + 1
		ex = K.choice(rng, "Which century is the year %d in?" % y, "the %s century" % _ordinal(c),
			["the %s century" % _ordinal(c - 1), "the %s century" % _ordinal(c + 1), "the %s century" % _ordinal(c - 2)],
			"The 1st century was the years 1 to 100, so a century's number is one more than its hundreds.",
			"%d is in the %ds. The 1st century was the years 1 to 100, so the %ds are the %s century." % [y, _down(y, 100),
				_down(y, 100), _ordinal(c)])
	ex.data = {"year": y}
	return ex


## "How many years from AD 1200 to AD 1500?" Level 1: whole hundreds; level 2: any AD years; level 3: BC years (both
## BC, so there is no year 0 to trip over: the calendar goes from 1 BC straight to AD 1).
static func years_between(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a: int
	var b: int
	if level == 1:
		a = rng.randi_range(5, 17) * 100
		b = a + rng.randi_range(1, 5) * 100
	elif level == 2:
		a = rng.randi_range(1000, 1900)
		b = a + rng.randi_range(12, 120)
	else:
		b = -rng.randi_range(5, 30) * 100
		a = b - rng.randi_range(1, 12) * 100
	var from := _year(a, 2, false)
	var to := _year(b, 2, false)
	var hint := "Count on from the earlier year to the later one, in easy jumps (hundreds, then tens)."
	var explain := "From %s to %s: %d − %d = %d years." % [from, to, b, a, b - a]
	if a < 0:
		hint = "Both years are BC, so they count down: take the smaller number from the bigger one."
		explain = "BC years count down: from %s to %s is %d − %d = %d years." % [from, to, -a, -b, b - a]
	var ex := K.number("How many years are there from %s to %s?" % [from, to], str(b - a), hint, explain)
	ex.data = {"from": a, "to": b}
	return ex


# --- Citizenship: money with the game's gold (g3.citizenship.earning_money, needs_wants, saving) ---------------------

## "Mimi earns 5 gold for each cake she bakes. She bakes 4 cakes. How much gold does she earn?" Level 1: 2, 5 or 10 gold
## each; level 2: 3, 4, 6, 7 or 8; level 3: then spends some of it on something she wants.
static func coins_earn(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var job: Array = JOBS[rng.randi_range(0, JOBS.size() - 1)]
	var who := str(job[0])
	var p: Array = PEOPLE[who]
	var rate: int = ([2, 5, 10] if level == 1 else [3, 4, 6, 7, 8])[rng.randi_range(0, 2 if level == 1 else 4)]
	var count := rng.randi_range(2, 6) if level == 1 else rng.randi_range(3, 9)
	var earned := rate * count
	var spent := 0
	var prompt := "%s earns %d gold for each %s %s %s. %s %s %d %s. How much gold does %s earn?" % [who, rate, job[1], p[0],
		job[3], str(p[0]).capitalize(), job[3], count, job[2], p[0]]
	var explain := "%d %s × %d gold each = %d gold." % [count, job[2], rate, earned]
	if level == 3:
		spent = rng.randi_range(1, earned - 1)
		var thing := THINGS[rng.randi_range(0, THINGS.size() - 1)]
		prompt = "%s earns %d gold for each %s %s %s, and %s %d %s. Then %s spends %d gold on a %s. How much gold is left?" \
			% [who, rate, job[1], p[0], job[3], job[3], count, job[2], p[0], spent, thing]
		explain = "%d × %d = %d gold earned. %d − %d = %d gold left." % [count, rate, earned, earned, spent, earned - spent]
	var ex := K.number(prompt, str(earned - spent),
		"Each %s earns the same, so it is a times question: how many, times the gold for each." % job[1], explain)
	if level == 3:
		ex.hint = "First work out the gold earned (how many × the gold for each), then take away what was spent."
	ex.data = {"rate": rate, "count": count, "spent": spent}
	return ex


## "Bram wants a saddle that costs 20 gold. He saves 5 gold each day. How many days until he has enough?" Level 1: from
## nothing; level 2: with some saved already; level 3: the last day takes the savings past the price.
static func coins_save(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = PEOPLE.keys()[rng.randi_range(0, PEOPLE.size() - 1)]
	var p: Array = PEOPLE[who]
	var goal_name := GOALS[rng.randi_range(0, GOALS.size() - 1)]
	var rate: int = ([2, 5, 10] if level == 1 else [3, 4, 5, 6])[rng.randi_range(0, 2 if level == 1 else 3)]
	var days := rng.randi_range(2, 6) if level == 1 else rng.randi_range(3, 8)
	var have := 0 if level == 1 else rng.randi_range(2, 12)
	var goal := have + rate * days
	if level == 3:
		goal -= rng.randi_range(1, rate - 1)   # not exact: the last day goes past the price
	var saved_line := "" if have == 0 else " %s has %d gold saved already." % [str(p[0]).capitalize(), have]
	var prompt := "%s wants %s that costs %d gold.%s %s saves %d gold each day. How many days until %s has enough?" % [who,
		goal_name, goal, saved_line, str(p[0]).capitalize(), rate, p[0]]
	var need := goal - have
	var hint := "Work out how much more is needed, then count in jumps of the gold saved each day."
	var explain := "%s needs %d − %d = %d more gold. %d ÷ %d = %d days." % [who, goal, have, need, need, rate, days]
	if have == 0:
		explain = "Count in %ds up to %d: that takes %d days, because %d × %d = %d." % [rate, goal, days, days, rate, goal]
	if level == 3:
		hint = "Count in jumps of the gold saved each day until you reach the price or go past it. The day that gets there counts."
		explain = "%s needs %d more gold. In %d days %s saves %d: not enough yet. In %d days %s saves %d: enough! So %d days." \
			% [who, need, days - 1, p[0], rate * (days - 1), days, p[0], rate * days, days]
	var ex := K.number(prompt, str(days), hint, explain)
	ex.data = {"goal": goal, "have": have, "rate": rate}
	return ex


## Choosing: "Mimi has 12 gold. She can buy a lantern for 7 gold and a kite for 6 gold." (level 1, true or false);
## "She buys the lantern. How much is left?" (level 2); "Which two things can she buy together?" (level 3: exactly one
## pair fits, so choosing it means giving up the third).
static func coins_spend(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who: String = PEOPLE.keys()[rng.randi_range(0, PEOPLE.size() - 1)]
	var p: Array = PEOPLE[who]
	var names := _pick(rng, THINGS, 3)
	var prices: Array[int] = []
	var have := 0
	var ex: Dictionary
	if level == 1:
		prices = [rng.randi_range(3, 9), rng.randi_range(3, 9), rng.randi_range(3, 9)]
		var both := prices[0] + prices[1]
		have = both + rng.randi_range(0, 4) if rng.randf() < 0.5 else both - rng.randi_range(1, mini(prices[0], prices[1]) - 1)
		have = maxi(have, maxi(prices[0], prices[1]))
		var fits := both <= have
		ex = K.truefalse("%s has %d gold. %s can buy both a %s for %d gold and a %s for %d gold." % [who, have,
			str(p[0]).capitalize(), names[0], prices[0], names[1], prices[1]], fits,
			"Add the two prices together, then compare the total with the gold %s has." % p[0],
			"%d + %d = %d gold. That is %s %d, so %s." % [prices[0], prices[1], both,
				"not more than" if fits else "more than", have,
				"there is enough for both" if fits else "%s must choose one and give up the other" % p[0]])
	elif level == 2:
		prices = [rng.randi_range(4, 19), rng.randi_range(3, 15), rng.randi_range(3, 15)]
		have = prices[0] + rng.randi_range(1, 20)
		ex = K.number("%s has %d gold and buys a %s for %d gold. How much gold is left?" % [who, have, names[0], prices[0]],
			str(have - prices[0]), "Spending takes gold away: start with what %s has and take away the price." % p[0],
			"%d − %d = %d gold left." % [have, prices[0], have - prices[0]])
	else:
		for _try in 200:
			prices = [rng.randi_range(3, 12), rng.randi_range(3, 12), rng.randi_range(3, 12)]
			var sums: Array[int] = [prices[0] + prices[1], prices[0] + prices[2], prices[1] + prices[2]]
			var low: int = sums.min()
			var others := sums.filter(func(s: int) -> bool: return s != low)
			if sums.count(low) == 1 and not others.is_empty():
				var next: int = others.min()
				if next - low >= 2:
					have = rng.randi_range(low, next - 1)
					break
		if have == 0:
			prices = [5, 6, 9]
			have = 12
		var pairs: Array = [[0, 1], [0, 2], [1, 2]]
		var right := ""
		var left_out := ""
		var wrongs: Array = []
		var sums_said: Array[String] = []
		for k in pairs.size():
			var pr: Array = pairs[k]
			var words := "the %s and the %s" % [names[pr[0]], names[pr[1]]]
			sums_said.append("%s and %s: %d" % [names[pr[0]].capitalize(), names[pr[1]], prices[pr[0]] + prices[pr[1]]])
			if prices[pr[0]] + prices[pr[1]] <= have:
				right = words
				left_out = names[2 - k]   # the pair (0, 1) leaves out 2, (0, 2) leaves 1, (1, 2) leaves 0
			else:
				wrongs.append(words)
		wrongs.append("all three")
		ex = K.choice(rng, "%s has %d gold. A %s costs %d, a %s costs %d and a %s costs %d. Which two can %s buy together?" % [
			who, have, names[0], prices[0], names[1], prices[1], names[2], prices[2], p[0]], right, wrongs,
			"Add up each pair of prices and compare each total with %d gold." % have,
			"%s. Only %s fit into %d gold, so %s gives up the %s." % [". ".join(sums_said), right, have, p[0], left_out])
	ex.data = {"have": have, "prices": prices, "names": names}
	return ex


# --- Helpers ------------------------------------------------------------------------------------------------------------

## n rounded down to a multiple of `step` (n ≥ 0).
static func _down(n: int, step: int) -> int:
	return n - n % step


## `count` different words from `list`, in a seeded order.
static func _pick(rng: RandomNumberGenerator, list: Array[String], count: int) -> Array[String]:
	var all: Array = list.duplicate()
	GenKit.shuffle(rng, all)
	var out: Array[String] = []
	for w: Variant in all.slice(0, count):
		out.append(str(w))
	return out


## Every map square in a seeded order.
static func _cells(rng: RandomNumberGenerator) -> Array[Vector2i]:
	var all: Array = []
	for y in MAP_ROWS:
		for x in MAP_COLS:
			all.append(Vector2i(x, y))
	GenKit.shuffle(rng, all)
	var out: Array[Vector2i] = []
	for c: Vector2i in all:
		out.append(c)
	return out


## A compass map: a header row with "north" over the middle, then MAP_ROWS rows of MAP_COLS squares.
static func _map_picture(places: Dictionary) -> Dictionary:
	var rows: Array = [["", "", "north", "", ""]]
	for y in MAP_ROWS:
		var row: Array = []
		for x in MAP_COLS:
			row.append("")
		rows.append(row)
	for n: String in places:
		rows[int(places[n][1]) + 1][int(places[n][0])] = n
	return {"kind": "table", "rows": rows}


## The compass point for a move of dx squares east and dy north (exact: straight or the same both ways).
static func _direction(dx: int, dy: int) -> String:
	var ns := "north" if dy > 0 else ("south" if dy < 0 else "")
	var ew := "east" if dx > 0 else ("west" if dx < 0 else "")
	if ns != "" and ew != "":
		return ns + "-" + ew
	return ns + ew


## "2 squares east and 1 square north"
static func _steps(dx: int, dy: int) -> String:
	var parts: Array[String] = []
	if dx != 0:
		parts.append(_squares(absi(dx), "east" if dx > 0 else "west"))
	if dy != 0:
		parts.append(_squares(absi(dy), "north" if dy > 0 else "south"))
	return " and ".join(parts)


static func _squares(n: int, way: String) -> String:
	return "%d square%s %s" % [n, "" if n == 1 else "s", way]


## A year as the lessons write it: level 1 "1066"; BC "500 BC" and AD "AD 43"; common_era "500 BCE" and "43 CE".
static func _year(v: int, level: int, common_era: bool) -> String:
	if v < 0:
		return "%d %s" % [-v, "BCE" if common_era else "BC"]
	if level == 1:
		return str(v)
	return "%d CE" % v if common_era else "AD %d" % v


static func _ordinal(n: int) -> String:
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
