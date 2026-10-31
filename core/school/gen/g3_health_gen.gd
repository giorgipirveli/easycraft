class_name G3HealthGen
extends RefCounted
## Owner #70 and #73 (research §6.3): grade 3 health and PE, design and technology, and projects generators: a pulse
## counted for part of a minute, hours of sleep, claps to count by ear, foods sorted into their groups and by where they
## come from, nets of a cube, a park's area and fence, a recipe scaled for more people, distances on a village map, and a
## Stone Age camp's kit. SchoolGen "g3p.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) ->
## Dictionary`, seeded, level 1-3, each with a hint (a strategy), a worked answer and `data` (its inputs, for
## tests/unit/test_g3_health_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi"]

# --- Health and PE: your heart (g3.health_pe.heart_exercise) -----------------------------------------------------------

## [what they did, resting?]
const MOMENTS: Array = [["while sitting quietly", true], ["after reading a book", true], ["before the game", true],
	["after skipping", false], ["after a race", false], ["after dancing", false], ["after star jumps", false]]


## "Zara counts 22 beats in 15 seconds after skipping. How many beats is that in a whole minute?" Level 1: 30 seconds
## (double it); level 2: 15 seconds (times 4); level 3: 10 seconds (times 6), or back from a minute to 15 seconds.
static func pulse_minute(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	if level == 3 and rng.randf() < 0.4:
		var quarter := rng.randi_range(18, 36)
		var m := quarter * 4
		var ex := K.number("%s's heart beats %d times a minute. How many beats would %s count in 15 seconds?" % [who, m,
			who], str(quarter), "15 seconds is a quarter of a minute, so share the minute's beats by 4.",
			"A minute is 4 lots of 15 seconds: %d ÷ 4 = %d beats in 15 seconds." % [m, quarter])
		ex.data = {"per_minute": m, "seconds": 15}
		return ex
	var seconds: int = [30, 15, 10][level - 1]
	var lots := int(60.0 / seconds)
	var moment: Array = MOMENTS[rng.randi_range(0, MOMENTS.size() - 1)]
	var lo := 70 if moment[1] else 110
	var hi := 100 if moment[1] else 160
	var beats := rng.randi_range(ceili(float(lo) / lots), floori(float(hi) / lots))
	var hint := "A minute is 60 seconds: 2 lots of 30 seconds, so double the count."
	if lots == 4:
		hint = "A minute is 4 lots of 15 seconds, so times the count by 4."
	elif lots == 6:
		hint = "A minute is 6 lots of 10 seconds, so times the count by 6."
	var explain := "60 seconds is %d lots of %d seconds: %d × %d = %d beats a minute." % [lots, seconds, beats, lots,
		beats * lots]
	if not moment[1]:
		explain += " Exercise made the heart beat faster."
	var ex := K.number("%s counts %d beats in %d seconds %s. How many beats is that in a whole minute?" % [who, beats,
		seconds, moment[0]], str(beats * lots), hint, explain)
	ex.data = {"beats": beats, "seconds": seconds}
	return ex


# --- Health and PE: sleep (g3.health_pe.sleep_rest) ----------------------------------------------------------------

## "Tilly goes to bed at 8 pm and wakes up at 7 am. How many hours of sleep is that?" (9 to 12 hours, the sleep a child of
## 8 or 9 needs). Level 1: on the hour; level 2: half past too; level 3: "needs 10 hours and wakes at 7 am: bedtime?"
static func sleep_hours(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	if level == 3:
		var need := rng.randi_range(9, 11)
		var wake_h := rng.randi_range(6, 8)
		var bed_h := wake_h + 12 - need
		var wrongs: Array = []
		for h in [bed_h - 1, bed_h + 1, bed_h - 2, bed_h + 2]:
			if h >= 6 and h <= 11 and wrongs.size() < 3:
				wrongs.append("%d pm" % h)
		var ex := K.choice(rng, "%s must wake up at %d am and needs %d hours of sleep. What time should %s be asleep?" % [
			who, wake_h, need, who], "%d pm" % bed_h, wrongs,
			"Count back from the wake-up time: first the hours back to midnight, then the rest.",
			"Count back from %d am: %d hours to midnight, then %d more hours to %d pm. %d + %d = %d hours of sleep." % [
				wake_h, wake_h, need - wake_h, bed_h, wake_h, need - wake_h, need])
		ex.data = {"need": need, "wake": [wake_h, 0]}
		return ex
	var m := 30 if level == 2 and rng.randf() < 0.6 else 0
	var nights: Array[Vector2i] = []   # (bedtime, waking) with 9 to 12 hours between
	for bh in range(7, 10):
		for wh in range(6, 9):
			if 12 - bh + wh >= 9 and 12 - bh + wh <= 12:
				nights.append(Vector2i(bh, wh))
	var night := nights[rng.randi_range(0, nights.size() - 1)]
	var bed_h := night.x
	var wake_h := night.y
	var before := 12 - bed_h
	var bed := _time(bed_h, m, "pm")
	var wake := _time(wake_h, m, "am")
	var midnight := "midnight" if m == 0 else _time(12, m, "am")
	var ex := K.number("%s goes to bed at %s and wakes up at %s. How many hours of sleep is that?" % [who, bed, wake],
		str(before + wake_h), "Count the hours up to midnight, then the hours after midnight, and add them.",
		"From %s to %s is %d hours, and from %s to %s is %d hours: %d + %d = %d hours." % [bed, midnight, before,
			midnight, wake, wake_h, before, wake_h, before + wake_h])
	ex.data = {"bed": [bed_h, m], "wake": [wake_h, m]}
	return ex


# --- Health and PE: dance (g3.health_pe.dance_moves) --------------------------------------------------------------

## A rhythm of claps and rests to LISTEN to: "How many claps do you hear?" Level 1: 3-5 even claps; level 2: 4-8 with
## double claps; level 3: 6-10 in a longer pattern.
static func count_claps(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var claps := rng.randi_range([3, 4, 6][level - 1], [5, 8, 10][level - 1])
	var most: int = [10, 14, 16][level - 1]
	var pattern := "x"
	if level == 1:
		pattern = "x-".repeat(claps)
	else:
		for i in range(1, claps):
			var left := claps - 1 - i   # claps still to come after this one
			var room := most - pattern.length() - 1 - left
			var gap := rng.randi_range(0, mini(2, room))
			pattern += "-".repeat(gap) + "x"
		if pattern.length() < most:
			pattern += "-"
	var tempo: int = [90, 100, 110][level - 1]
	var ex := K.number("Tap LISTEN. How many claps do you hear?", str(claps),
		"Listen again and put up one finger for each clap. Two quick claps still count as two.",
		"The rhythm is %s: each x is a clap and each dash a rest. That makes %d claps." % [pattern, claps])
	ex.sound = {"kind": "rhythm", "pattern": pattern, "tempo": tempo}
	ex.data = {"pattern": pattern, "tempo": tempo}
	return ex


# --- Health and PE: eating well (g3.health_pe.healthy_eating) ----------------------------------------------------------

## Food group -> [[food, level from which it is used]] (level 3 adds the ones children often sort wrongly: potatoes are
## starchy, peas and sweetcorn are vegetables, lentils and nuts are protein).
const FOODS := {
	"fruit and vegetables": [["apples", 1], ["bananas", 1], ["carrots", 1], ["oranges", 1], ["grapes", 1],
		["strawberries", 1], ["broccoli", 2], ["tomatoes", 2], ["cucumber", 2], ["spinach", 2], ["peas", 3],
		["sweetcorn", 3]],
	"starchy foods": [["bread", 1], ["rice", 1], ["pasta", 1], ["noodles", 2], ["couscous", 2], ["potatoes", 3],
		["oats", 3]],
	"protein": [["eggs", 1], ["fish", 1], ["chicken", 1], ["beans", 2], ["lentils", 3], ["nuts", 3], ["chickpeas", 3]],
	"dairy": [["milk", 1], ["cheese", 1], ["yoghurt", 1]],
}


## "Sort the foods into their food groups." Level 1: 2 groups, 4 foods; level 2: 3 groups, 5 foods; level 3: 3 groups,
## 6 foods, with the tricky ones.
static func food_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var groups := _pick(rng, FOODS.keys(), 2 if level == 1 else 3)
	var ex := _sort_foods(rng, level, FOODS, groups, [4, 5, 6][level - 1],
		"Sort the foods into their food groups.",
		"Is it a fruit or vegetable, a starchy food like bread or rice, made from milk, or meat, fish, eggs, beans or nuts?",
		{"potatoes": "Potatoes are a starchy food.", "peas": "Peas are a vegetable.", "nuts": "Nuts are a protein.",
			"lentils": "Lentils are a protein, like beans."})
	return ex


# --- D&T: where food comes from (g3.design_tech.food_origins) --------------------------------------------------------

const SOURCES := {
	"grown": [["apples", 1], ["carrots", 1], ["wheat", 1], ["potatoes", 1], ["strawberries", 2], ["rice", 2], ["peas", 2],
		["oats", 2], ["oranges", 2], ["tomatoes", 2], ["bread", 3], ["pasta", 3], ["crisps", 3], ["jam", 3]],
	"reared": [["eggs", 1], ["milk", 1], ["beef", 2], ["lamb", 2], ["chicken", 2], ["pork", 2], ["cheese", 3],
		["butter", 3], ["yoghurt", 3], ["sausages", 3]],
	"caught": [["cod", 1], ["mackerel", 1], ["sardines", 2], ["crab", 2], ["haddock", 2], ["tuna", 2],
		["fish fingers", 3]],
}
const MADE_FROM := {"bread": "Bread is made from wheat.", "pasta": "Pasta is made from wheat.",
	"crisps": "Crisps are made from potatoes.", "jam": "Jam is made from fruit.", "cheese": "Cheese is made from milk.",
	"butter": "Butter is made from milk.", "yoghurt": "Yoghurt is made from milk.",
	"sausages": "Sausages are made from farm animals' meat.", "fish fingers": "Fish fingers are made from fish like cod."}


## "Is it grown, reared or caught?" Level 1: two of them, 4 foods; level 2: all three, 5 foods; level 3: 6 foods, some
## made from others (bread from wheat, cheese from milk).
static func food_source(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var groups := _pick(rng, SOURCES.keys(), 2 if level == 1 else 3)
	return _sort_foods(rng, level, SOURCES, groups, [4, 5, 6][level - 1],
		"Sort the foods: are they grown, reared or caught?",
		"Grown foods come from plants, reared foods from farm animals, and caught foods are fished from the wild.",
		MADE_FROM)


# --- D&T: boxes and nets (g3.design_tech.boxes_nets) -----------------------------------------------------------------

## The 11 nets of a cube, and hexominoes that are not nets (the obvious ones first).
const NETS: Array = [
	["#...", "####", "#..."], ["#...", "####", ".#.."], ["#...", "####", "..#."], ["#...", "####", "...#"],
	[".#..", "####", ".#.."], [".#..", "####", "..#."],
	["##..", ".###", ".#.."], ["##..", ".###", "..#."], ["##..", ".###", "...#"],
	["##..", ".##.", "..##"], ["###..", "..###"]]
const NOT_NETS_EASY: Array = [["######"], ["###", "###"], ["####", "##.."], ["####", "#..#"]]
const NOT_NETS: Array = [["######"], ["#####", "#...."], ["#####", ".#..."], [".####", "##..."], ["####", "#...", "#..."],
	["#####", "..#.."], ["####", "##.."], [".###", "##..", "#..."], ["####", ".#..", ".#.."], [".###", "##..", ".#.."],
	[".###", ".#..", "##.."], ["####", "#.#."], ["####", ".##."], [".###", "###."], ["#..", "##.", "###"],
	["#.##", "###."], ["#..", "###", "##."], ["#..", "###", "#.#"], ["#..", "###", ".##"], ["#..", "#.#", "###"],
	["####", "#..#"], ["###", "###"], ["##.", "###", ".#."], ["##.", ".##", "##."]]
const LETTERS := "ABCDEF"


## "Will this net fold into a cube?" (true or false, level 1 against shapes that plainly do not, level 2 against every
## hexomino that does not); level 3: "Which net folds into a cube?" (three pictures) or "Which face is opposite A?"
static func cube_net(rng: RandomNumberGenerator, level: int) -> Dictionary:
	if level < 3:
		var folds := rng.randf() < 0.5
		var pool: Array = NETS if folds else (NOT_NETS_EASY if level == 1 else NOT_NETS)
		var rows := _turned(rng, pool[rng.randi_range(0, pool.size() - 1)])
		var why := "Yes: its 6 squares fold up with one square on each face of the cube."
		if not folds:
			why = "No: fold it up and two squares land on the same face, leaving another face open."
			if _has_block(rows):
				why = "No: four squares meet round one corner, which cannot happen on a cube, so two squares overlap."
		var ex := K.truefalse("Will this net fold into a cube?", folds,
			"Imagine folding it round one square: a cube needs one square on each of its 6 faces, none on top of another.",
			why, {"kind": "net", "rows": rows})
		ex.data = {"rows": rows}
		return ex
	if rng.randf() < 0.5:
		var right := _turned(rng, NETS[rng.randi_range(0, NETS.size() - 1)])
		var wrong_a := _turned(rng, NOT_NETS[rng.randi_range(0, NOT_NETS.size() - 1)])
		var wrong_b := wrong_a
		while wrong_b == wrong_a:
			wrong_b = _turned(rng, NOT_NETS[rng.randi_range(0, NOT_NETS.size() - 1)])
		var ex := K.choice(rng, "Which net folds into a cube?", {"picture": {"kind": "net", "rows": right}},
			[{"picture": {"kind": "net", "rows": wrong_a}}, {"picture": {"kind": "net", "rows": wrong_b}}],
			"Fold each one in your head: a net of a cube never has four squares round a corner, or two squares landing on one face.",
			"Only this one folds with one square on each of the cube's 6 faces; the others overlap and leave a face open.")
		ex.data = {"nets": [right, wrong_a, wrong_b]}
		return ex
	var rows := _lettered(_turned(rng, NETS[rng.randi_range(0, NETS.size() - 1)]))
	var cells := _cells(rows)
	var letter := LETTERS[rng.randi_range(0, 5)]
	var at := _find(rows, letter)
	var opposite := ""
	for c in cells:
		if CubeNet.opposite(cells, at, c):
			opposite = _letter_at(rows, c)
	var wrongs: Array = []
	for l in LETTERS:
		if l != letter and l != opposite:
			wrongs.append(l)
	var ex := K.choice(rng, "Fold this net into a cube. Which face is opposite %s?" % letter, opposite, wrongs,
		"Opposite faces never touch. In a straight line of squares, the ones two apart end up opposite each other.",
		"Folded up, %s and %s are on opposite sides of the cube: they share no edge, and every other face touches %s." % [
			letter, opposite, letter], {"kind": "net", "rows": rows})
	ex.data = {"rows": rows, "letter": letter}
	return ex


# --- Projects: a habitat park (g3.projects.habitat_park) -------------------------------------------------------------

## A park w × h blocks (each block 1 m): level 1 its area, level 2 its fence (the perimeter); level 3 build a park of an
## area and a fence on the block board, or count the fence blocks round the outside (the sides and the 4 corners).
static func park_fence(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := rng.randi_range(3, 7)
	var h := rng.randi_range(2, 5)
	var pic := {"kind": "rect", "w": w, "h": h, "unit": "m"}
	var sides := "%d + %d + %d + %d = %d" % [w, h, w, h, 2 * (w + h)]
	var ex: Dictionary
	var ask := "area"
	if level == 1:
		ex = K.number("The park is %d m long and %d m wide. Each square is 1 m by 1 m. What is its area in squares?" % [
			w, h], str(w * h), "Count the squares in one row, then multiply by the number of rows.",
			"%d rows of %d squares: %d × %d = %d squares." % [h, w, h, w, w * h], pic)
	elif level == 2:
		ask = "perimeter"
		ex = K.number("The park is %d m long and %d m wide. How many metres of fence go all the way round it?" % [w, h],
			str(2 * (w + h)), "Add up all four sides: two long sides and two short sides.",
			"All four sides: %s m of fence." % sides, pic)
	elif rng.randf() < 0.5:
		ask = "build"
		while w * h > 30 or w == h:   # fits the board, and a long side and a short side
			w = rng.randi_range(3, 7)
			h = rng.randi_range(2, 5)
		ex = K.build("Build a park with an area of %d squares and a fence of %d m all the way round." % [w * h,
			2 * (w + h)], {"cols": 10, "rows": 7, "block": 1, "given": [], "view": "farm"},
			{"kind": "rectangle", "area": w * h, "perimeter": 2 * (w + h)},
			"Think of rectangles with an area of %d, then add up each one's four sides." % [w * h],
			"%d by %d: %d × %d = %d squares, and %d + %d + %d + %d = %d m of fence." % [w, h, w, h, w * h, w, h, w, h,
				2 * (w + h)])
	else:
		ask = "corners"
		ex = K.number("In the world, fence blocks go round the outside of a park %d blocks by %d, so each corner needs a block too. How many fence blocks?" % [
			w, h], str(2 * (w + h) + 4), "Add the four sides, then one more block for each of the 4 corners.",
			"The sides need %s blocks, and the 4 corners 4 more: %d + 4 = %d blocks." % [sides, 2 * (w + h),
				2 * (w + h) + 4], pic)
	ex.data = {"w": w, "h": h, "ask": ask}
	return ex


# --- D&T: a healthy snack (g3.design_tech.healthy_snack) ---------------------------------------------------------------

## [recipe, the ingredient as written after its amount, the question's words, amount for 2 people (even, so it halves)]
const RECIPES: Array = [["fruit kebabs", "strawberries", "strawberries", 6], ["fruit kebabs", "grapes", "grapes", 12],
	["a fruit salad", "apples", "apples", 2], ["a fruit salad", "grapes", "grapes", 10],
	["yoghurt pots", "spoonfuls of oats", "spoonfuls of oats", 4], ["a smoothie", "mL of milk", "millilitres of milk", 300],
	["a smoothie", "strawberries", "strawberries", 8], ["sandwiches", "slices of bread", "slices of bread", 4],
	["vegetable sticks", "carrots", "carrots", 2]]


## "The recipe for fruit kebabs for 2 people uses 6 strawberries. How many strawberries for 4 people?" Level 1: double;
## level 2: 3 or 4 times as many; level 3: halve, or go through 1 or 2 people (2 → 5, 4 → 6).
static func recipe_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var r: Array = RECIPES[rng.randi_range(0, RECIPES.size() - 1)]
	var per_two: int = r[3]
	var from := 2
	var to := 4
	var amount := per_two
	var hint := "Twice as many people need twice as much: double it."
	var explain := ""
	var answer := 0
	match level:
		1:
			answer = amount * 2
			explain = "4 people is 2 times 2 people: %d × 2 = %s %s." % [amount, K.fmt(answer), r[1]]
		2:
			var times := rng.randi_range(3, 4)
			to = 2 * times
			answer = amount * times
			hint = "%d people is %d times as many as 2 people, so multiply by %d." % [to, times, times]
			explain = "%d people is %d times 2 people: %d × %d = %s %s." % [to, times, amount, times, K.fmt(answer), r[1]]
		_:
			var way := rng.randi_range(0, 2)
			if way == 0:   # halve: from 4 people to 2
				from = 4
				to = 2
				amount = per_two * 2
				answer = per_two
				hint = "2 people is half of 4 people, so halve the amount."
				explain = "Half of 4 people is 2 people: %d ÷ 2 = %d %s." % [amount, answer, r[1]]
			elif way == 1:   # through 1 person: from 2 to 5
				to = 5
				var one := int(per_two / 2.0)
				answer = one * 5
				hint = "First work out the amount for 1 person, then multiply by 5."
				explain = "For 1 person: %d ÷ 2 = %d. For 5 people: %d × 5 = %d %s." % [amount, one, one, answer, r[1]]
			else:   # through 2 people: from 4 to 6
				from = 4
				to = 6
				amount = per_two * 2
				answer = per_two * 3
				hint = "First work out the amount for 2 people, then multiply by 3 for 6 people."
				explain = "For 2 people: %d ÷ 2 = %d. For 6 people: %d × 3 = %d %s." % [amount, per_two, per_two, answer,
					r[1]]
	var ex := K.number("The recipe for %s for %d people uses %d %s. How many %s for %d people?" % [r[0], from, amount,
		r[1], r[2], to], str(answer), hint, explain)
	ex.data = {"amount": amount, "from": from, "to": to, "thing": r[1]}
	return ex


# --- Projects: map my village (g3.projects.map_my_village) -----------------------------------------------------------

const PLACES: Array[String] = ["well", "barn", "mill", "hut", "pond", "farm", "shop", "camp", "tower", "gate"]
const MAP_COLS := 5
const MAP_ROWS := 4


## A village map (a table: letters along the bottom, numbers up the side) where each square is some blocks across: "How
## many blocks is it from the well to the barn?" Levels 1-2: in a straight line (level 1: 10 blocks a square); level 3:
## along and then up or down.
static func map_distance(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := _pick(rng, PLACES, 4)
	var scale: int = 10 if level == 1 else [5, 10, 20][rng.randi_range(0, 2)]
	var a := Vector2i(rng.randi_range(0, MAP_COLS - 1), rng.randi_range(0, MAP_ROWS - 1))
	var fits: Array[Vector2i] = []   # every map square has some: the map is 5 by 4
	for y in MAP_ROWS:
		for x in MAP_COLS:
			var dx := absi(x - a.x)
			var dy := absi(y - a.y)
			if (level < 3 and ((dx >= 2 and dy == 0) or (dy >= 2 and dx == 0))) or (level == 3 and dx >= 1 and dy >= 1):
				fits.append(Vector2i(x, y))
	var b := fits[rng.randi_range(0, fits.size() - 1)]
	var spots: Array[Vector2i] = [a, b]
	while spots.size() < names.size():
		var c := Vector2i(rng.randi_range(0, MAP_COLS - 1), rng.randi_range(0, MAP_ROWS - 1))
		if not spots.has(c):
			spots.append(c)
	var rows: Array = [["", "A", "B", "C", "D", "E"]]
	for y in MAP_ROWS:
		var row: Array = [str(MAP_ROWS - y)]
		for x in MAP_COLS:
			var at := spots.find(Vector2i(x, y))
			row.append(names[at] if at >= 0 else "")
		rows.append(row)
	var dx := absi(b.x - a.x)
	var dy := absi(b.y - a.y)
	var squares := dx + dy
	var prompt := "On this map, each square is %d blocks across. How many blocks is it from the %s to the %s?" % [scale,
		names[0], names[1]]
	var explain := "The %s is %d squares from the %s: %d × %d = %d blocks." % [names[1], squares, names[0], squares,
		scale, squares * scale]
	if level == 3:
		prompt = "Each square is %d blocks across. Walking along the rows and columns, how many blocks from the %s to the %s?" % [
			scale, names[0], names[1]]
		explain = "%d squares along and %d up or down: %d + %d = %d squares. %d × %d = %d blocks." % [dx, dy, dx, dy,
			squares, squares, scale, squares * scale]
	var ex := K.number(prompt, str(squares * scale), "Count the squares between them, then multiply by %d." % scale,
		explain, {"kind": "table", "rows": rows})
	ex.data = {"from": [a.x, a.y], "to": [b.x, b.y], "scale": scale, "a": names[0], "b": names[1]}
	return ex


# --- Projects: a Stone Age camp (g3.projects.stone_age_camp) ---------------------------------------------------------

const STONE_AGE: Array[String] = ["a flint hand axe", "a flint scraper", "a wooden spear", "a bone needle",
	"a tent of animal skins", "a fire in a ring of stones", "clothes of fur and skins", "a cave painting",
	"a basket of berries", "a fishing spear"]
const LATER: Array[String] = ["a metal pot", "a glass window", "a brick wall", "a paper book", "a plastic bucket",
	"a metal saw", "a clock", "a woollen jumper", "coins", "a tin can"]


## "Which things belong in a Stone Age camp, and which came much later?" 4, 5 or 6 things by level.
static func camp_kit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n: int = [4, 5, 6][level - 1]
	var old_n := rng.randi_range(1, n - 1)
	var things: Array = _pick(rng, STONE_AGE, old_n) + _pick(rng, LATER, n - old_n)
	K.shuffle(rng, things)
	var answer: Array = []
	var old: Array[String] = []
	var later: Array[String] = []
	for t: String in things:
		answer.append(0 if STONE_AGE.has(t) else 1)
		if STONE_AGE.has(t):
			old.append(t)
		else:
			later.append(t)
	var ex := {"type": "sort", "prompt": "Which things belong in a Stone Age camp, and which came much later?",
		"groups": ["Stone Age camp", "much later"], "items": things, "answer": answer,
		"hint": "Hunter-gatherers made things from stone, bone, wood, skins and plants: no metal, glass, bricks or paper.",
		"explain": "Stone Age camp: %s. Much later: %s." % [", ".join(old), ", ".join(later)]}
	ex.data = {"things": things}
	return ex


# --- Helpers ---------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return PEOPLE[rng.randi_range(0, PEOPLE.size() - 1)]


## `n` different things from `from`, in a seeded order.
static func _pick(rng: RandomNumberGenerator, from: Array, n: int) -> Array:
	var all := from.duplicate()
	K.shuffle(rng, all)
	return all.slice(0, n)


## "8 pm", "7:30 am", "12:30 am".
static func _time(h: int, m: int, half: String) -> String:
	return ("%d %s" % [h, half]) if m == 0 else ("%d:%02d %s" % [h, m, half])


## A sort of `count` foods into `groups` (each used at least once) from `bank` (group -> [[food, level]]), with the
## foods' notes (bank-specific facts) in the worked answer.
static func _sort_foods(rng: RandomNumberGenerator, level: int, bank: Dictionary, groups: Array, count: int,
		prompt: String, hint: String, notes: Dictionary) -> Dictionary:
	var per := {}
	for g: String in groups:
		per[g] = []
	# each group once, then the rest at random from groups with foods left; at level 3, a tricky food first where the
	# groups have one
	var room := {}
	for g: String in groups:
		room[g] = (bank[g] as Array).filter(func(f: Array) -> bool: return int(f[1]) <= level).size() - 1
	var order: Array = groups.duplicate()
	while order.size() < count:
		var open: Array = groups.filter(func(g: String) -> bool: return int(room[g]) > 0)
		var g: String = open[rng.randi_range(0, open.size() - 1)]
		room[g] = int(room[g]) - 1
		order.append(g)
	var used := {}
	var items: Array = []
	var answer: Array = []
	var tricky_done := level < 3
	for g: String in order:
		var pool: Array = (bank[g] as Array).filter(func(f: Array) -> bool:
			return int(f[1]) <= level and not used.has(f[0]))
		if not tricky_done:
			var hard: Array = pool.filter(func(f: Array) -> bool: return int(f[1]) == 3)
			if not hard.is_empty():
				pool = hard
				tricky_done = true
		var food: String = pool[rng.randi_range(0, pool.size() - 1)][0]
		used[food] = true
		items.append(food)
		answer.append(groups.find(g))
	var idx: Array = range(items.size())
	K.shuffle(rng, idx)
	var shown: Array = []
	var shown_answer: Array = []
	for i: int in idx:
		shown.append(items[i])
		shown_answer.append(answer[i])
	var parts: Array[String] = []
	for gi in groups.size():
		var in_group: Array[String] = []
		for i in shown.size():
			if int(shown_answer[i]) == gi:
				in_group.append(str(shown[i]))
		if not in_group.is_empty():
			parts.append("%s: %s." % [_cap(str(groups[gi])), ", ".join(in_group)])
	for f: String in shown:
		if notes.has(f):
			parts.append(str(notes[f]))
	var ex := {"type": "sort", "prompt": prompt, "groups": groups, "items": shown, "answer": shown_answer, "hint": hint,
		"explain": " ".join(parts)}
	ex.data = {"foods": shown, "groups": groups}
	return ex


static func _cap(s: String) -> String:
	return s.left(1).to_upper() + s.substr(1)


# --- Helpers: nets ---------------------------------------------------------------------------------------------------

static func _cells(rows: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in rows.size():
		for x in str(rows[y]).length():
			if str(rows[y])[x] != ".":
				out.append(Vector2i(x, y))
	return out


## The shape turned a random number of quarter turns and perhaps flipped, as rows again.
static func _turned(rng: RandomNumberGenerator, rows: Array) -> Array:
	var flip := rng.randf() < 0.5
	var turns := rng.randi_range(0, 3)
	var pts: Array[Vector2i] = []
	for c in _cells(rows):
		var p := Vector2i(-c.x, c.y) if flip else c
		for _i in turns:
			p = Vector2i(-p.y, p.x)
		pts.append(p)
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-(1 << 20), -(1 << 20))
	for p in pts:
		lo = Vector2i(mini(lo.x, p.x), mini(lo.y, p.y))
		hi = Vector2i(maxi(hi.x, p.x), maxi(hi.y, p.y))
	var out: Array = []
	for y in range(lo.y, hi.y + 1):
		var line := ""
		for x in range(lo.x, hi.x + 1):
			line += "#" if pts.has(Vector2i(x, y)) else "."
		out.append(line)
	return out


## The net's squares lettered A-F, row by row.
static func _lettered(rows: Array) -> Array:
	var out: Array = []
	var i := 0
	for r: String in rows:
		var line := ""
		for ch in r:
			if ch == ".":
				line += "."
			else:
				line += LETTERS[i]
				i += 1
		out.append(line)
	return out


static func _find(rows: Array, letter: String) -> Vector2i:
	for y in rows.size():
		var x := str(rows[y]).find(letter)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


static func _letter_at(rows: Array, c: Vector2i) -> String:
	return str(rows[c.y])[c.x]


static func _has_block(rows: Array) -> bool:
	var cells := _cells(rows)
	for c in cells:
		if cells.has(c + Vector2i.RIGHT) and cells.has(c + Vector2i.DOWN) and cells.has(c + Vector2i.ONE):
			return true
	return false
