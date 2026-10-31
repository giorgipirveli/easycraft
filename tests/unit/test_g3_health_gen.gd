extends GutTest
## Grade 3 health and PE, design and technology, and projects (G3HealthGen, "g3p"): pulse counts, hours of sleep, claps
## to count, food groups and where food comes from, cube nets, a park's area and fence, scaling a recipe, distances on a
## village map and a Stone Age camp's kit. Each generator's answer is worked out again here from the exercise's `data`
## with this file's own facts and arithmetic (its own cube folding, its own food tables), for many seeds and every
## level, and every exercise must be valid (ExerciseCheck, its picture's and its sound's own checks).

const SEEDS := 80
## This test's own food facts (the UK's healthy plate; potatoes are a starchy food, beans and nuts a protein).
const FOOD_GROUP := {
	"apples": "fruit and vegetables", "bananas": "fruit and vegetables", "carrots": "fruit and vegetables",
	"peas": "fruit and vegetables", "broccoli": "fruit and vegetables", "oranges": "fruit and vegetables",
	"tomatoes": "fruit and vegetables", "grapes": "fruit and vegetables", "spinach": "fruit and vegetables",
	"strawberries": "fruit and vegetables", "cucumber": "fruit and vegetables", "sweetcorn": "fruit and vegetables",
	"bread": "starchy foods", "rice": "starchy foods", "pasta": "starchy foods", "potatoes": "starchy foods",
	"oats": "starchy foods", "noodles": "starchy foods", "couscous": "starchy foods",
	"eggs": "protein", "fish": "protein", "beans": "protein", "lentils": "protein", "chicken": "protein",
	"nuts": "protein", "chickpeas": "protein",
	"milk": "dairy", "cheese": "dairy", "yoghurt": "dairy"}
## Grown (plants), reared (farm animals) or caught (from the wild), and what made foods are made from.
const SOURCE := {
	"apples": "grown", "carrots": "grown", "wheat": "grown", "rice": "grown", "potatoes": "grown", "strawberries": "grown",
	"peas": "grown", "oats": "grown", "oranges": "grown", "tomatoes": "grown", "bread": "grown", "pasta": "grown",
	"crisps": "grown", "jam": "grown",
	"eggs": "reared", "milk": "reared", "beef": "reared", "lamb": "reared", "chicken": "reared", "pork": "reared",
	"cheese": "reared", "butter": "reared", "yoghurt": "reared", "sausages": "reared",
	"cod": "caught", "mackerel": "caught", "sardines": "caught", "crab": "caught", "tuna": "caught", "haddock": "caught",
	"fish fingers": "caught"}
## Hunter-gatherers of the Stone Age had these; the rest came thousands of years later (metal, glass, bricks, paper…).
const STONE_AGE: Array[String] = ["a flint hand axe", "a flint scraper", "a wooden spear", "a bone needle",
	"a tent of animal skins", "a fire in a ring of stones", "clothes of fur and skins", "a cave painting",
	"a basket of berries", "a fishing spear"]
const LATER: Array[String] = ["a metal pot", "a glass window", "a brick wall", "a paper book", "a plastic bucket",
	"a metal saw", "a clock", "a woollen jumper", "coins", "a tin can"]
## The 11 nets of a cube (each once; the test turns and flips them).
const NETS: Array = [
	["#...", "####", "#..."], ["#...", "####", ".#.."], ["#...", "####", "..#."], ["#...", "####", "...#"],
	[".#..", "####", ".#.."], [".#..", "####", "..#."],
	["##..", ".###", ".#.."], ["##..", ".###", "..#."], ["##..", ".###", "...#"],
	["##..", ".##.", "..##"], ["###..", "..###"]]


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
			for c: Variant in ex.get("choices", []):
				if c is Dictionary and c.has("picture"):
					assert_eq(SchoolPicture.problem(c.picture), "", "%s: a choice's picture" % gen)
			if ex.has("sound"):
				assert_eq(SchoolSound.problem(ex.sound), "", "%s: its sound" % gen)
			check.call(ex, level)


func _answer(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


## Each sorted item's group name, as the exercise's answer gives it.
func _sorted(ex: Dictionary) -> Dictionary:
	var out := {}
	for i in (ex.items as Array).size():
		out[str(ex.items[i])] = str(ex.groups[int(ex.answer[i])])
	return out


# --- Health and PE ---------------------------------------------------------------------------------------------------

func test_a_pulse_count_makes_the_beats_in_a_minute() -> void:
	_each("g3p.pulse_minute", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var seconds := int(d.seconds)
		assert_eq(60 % seconds, 0, "a minute is whole lots of %d seconds" % seconds)
		if d.has("per_minute"):
			assert_eq(level, 3, "counting back from a minute is level 3")
			var m := int(d.per_minute)
			assert_eq(m % (60 / seconds), 0, "the minute's beats share equally")
			assert_eq(float(ex.answer), float(m * seconds / 60), str(ex.prompt))
			assert_between(m, 60, 200, "a real pulse")
		else:
			var beats := int(d.beats)
			assert_true(str(ex.prompt).contains(str(beats)), "the prompt gives the count")
			assert_eq(float(ex.answer), float(beats * 60 / seconds), str(ex.prompt))
			assert_between(beats * 60 / seconds, 60, 200, "a real pulse")
			assert_eq(seconds, [30, 15, 10][level - 1], "level %d counts for %d seconds" % [level, seconds]))


func test_hours_of_sleep_from_bedtime_to_waking() -> void:
	_each("g3p.sleep_hours", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var wake: Array = d.wake
		if d.has("need"):
			assert_eq(level, 3)
			var bed_h := int(wake[0]) + 12 - int(d.need)   # in the evening (pm)
			var want := ("%d pm" % bed_h) if int(wake[1]) == 0 else ("%d:%02d pm" % [bed_h, int(wake[1])])
			assert_eq(_answer(ex), want, str(ex.prompt))
			assert_between(int(d.need), 9, 12, "children need 9 to 12 hours")
		else:
			var bed: Array = d.bed
			var minutes := (12 * 60 - (int(bed[0]) * 60 + int(bed[1]))) + int(wake[0]) * 60 + int(wake[1])
			assert_eq(minutes % 60, 0, "whole hours")
			assert_eq(float(ex.answer), minutes / 60.0, str(ex.prompt))
			assert_between(minutes / 60, 9, 12, "a sensible night's sleep")
			if level == 1:
				assert_true(int(bed[1]) == 0 and int(wake[1]) == 0, "level 1: on the hour"))


func test_count_the_claps() -> void:
	_each("g3p.count_claps", func(ex: Dictionary, level: int) -> void:
		var p := str(ex.data.pattern)
		assert_eq(ex.sound, {"kind": "rhythm", "pattern": p, "tempo": ex.data.tempo}, "the sound is the pattern")
		assert_eq(int(ex.answer), p.count("x"), p)
		assert_true(p.begins_with("x"), "it starts with a clap")
		assert_between(p.count("x"), [3, 4, 6][level - 1], [5, 8, 10][level - 1], "level %d's claps" % level))


func test_foods_sort_into_their_groups() -> void:
	_each("g3p.food_sort", func(ex: Dictionary, level: int) -> void:
		assert_eq((ex.groups as Array).size(), 2 if level == 1 else 3)
		assert_eq((ex.items as Array).size(), [4, 5, 6][level - 1])
		var s := _sorted(ex)
		for food: String in s:
			assert_true(FOOD_GROUP.has(food), "%s is in this test's table" % food)
			assert_eq(s[food], FOOD_GROUP.get(food, ""), food))


# --- Design and technology ----------------------------------------------------------------------------------------

func test_foods_sort_by_where_they_come_from() -> void:
	_each("g3p.food_source", func(ex: Dictionary, level: int) -> void:
		assert_eq((ex.groups as Array).size(), 2 if level == 1 else 3)
		var s := _sorted(ex)
		for food: String in s:
			assert_true(SOURCE.has(food), "%s is in this test's table" % food)
			assert_eq(s[food], SOURCE.get(food, ""), food))


func test_which_nets_fold_into_a_cube() -> void:
	var nets := {}
	for rows: Array in NETS:
		for f in _forms(_cells(rows)):
			nets[_key(f)] = true
	assert_eq(nets.size(), 64, "the 11 nets make 64 shapes turned and flipped")
	_each("g3p.cube_net", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		if str(ex.type) == "truefalse":
			assert_true(level < 3)
			assert_eq(ex.picture.rows, d.rows)
			assert_eq(bool(ex.answer), nets.has(_key(_normal(_cells(d.rows)))), str(d.rows))
			assert_eq(_cells(d.rows).size(), 6, "six squares")
		elif d.has("letter"):   # which face is opposite the lettered one
			assert_eq(level, 3)
			assert_true(nets.has(_key(_normal(_cells(d.rows)))), "a net")
			var faces := _fold(d.rows)
			var at: Vector3i = faces[str(d.letter)]
			var opposite := ""
			for l: String in faces:
				if faces[l] == -at:
					opposite = l
			assert_eq(_answer(ex), opposite, str(d.rows))
		else:   # which of the pictures folds into a cube
			assert_eq(level, 3)
			var folding := 0
			for i in (ex.choices as Array).size():
				var rows: Array = ex.choices[i].picture.rows
				var folds := nets.has(_key(_normal(_cells(rows))))
				folding += 1 if folds else 0
				assert_eq(folds, i == int(ex.answer), str(rows))
			assert_eq(folding, 1, "one net folds"))


# --- Projects --------------------------------------------------------------------------------------------------------

func test_a_parks_area_and_fence() -> void:
	_each("g3p.park_fence", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var w := int(d.w)
		var h := int(d.h)
		match str(d.ask):
			"area":
				assert_eq(float(ex.answer), float(w * h))
			"perimeter":
				assert_eq(float(ex.answer), float(2 * w + 2 * h))
			"corners":   # fence blocks round the outside: the sides and the 4 corners
				assert_eq(float(ex.answer), float(2 * w + 2 * h + 4))
			"build":
				assert_eq(str(ex.type), "build")
				assert_eq(int(ex.goal.area), w * h)
				assert_eq(int(ex.goal.perimeter), 2 * w + 2 * h)
			_:
				fail_test("unknown ask %s" % d.ask)
		assert_eq(str(d.ask) in ["area", "perimeter"], level < 3, "level %d asks %s" % [level, d.ask]))


func test_a_recipe_scales_for_more_people() -> void:
	_each("g3p.recipe_scale", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var amount := int(d.amount)
		var from := int(d.from)
		var to := int(d.to)
		assert_eq((amount * to) % from, 0, "a whole amount")
		assert_eq(float(ex.answer), float(amount * to / from), str(ex.prompt))
		assert_true(str(ex.prompt).contains(str(amount)), "the prompt gives the amount")
		if level == 1:
			assert_eq(to, from * 2, "level 1 doubles"))


func test_distances_on_the_village_map() -> void:
	_each("g3p.map_distance", func(ex: Dictionary, level: int) -> void:
		var d: Dictionary = ex.data
		var from: Array = d.from
		var to: Array = d.to
		var squares := absi(int(to[0]) - int(from[0])) + absi(int(to[1]) - int(from[1]))
		assert_eq(float(ex.answer), float(squares * int(d.scale)), str(ex.prompt))
		var rows: Array = ex.picture.rows
		assert_eq(str(rows[int(from[1]) + 1][int(from[0]) + 1]), str(d.a), "the map shows the %s" % d.a)
		assert_eq(str(rows[int(to[1]) + 1][int(to[0]) + 1]), str(d.b), "the map shows the %s" % d.b)
		if level < 3:
			assert_true(int(to[0]) == int(from[0]) or int(to[1]) == int(from[1]), "levels 1 and 2: in a straight line"))


func test_a_stone_age_camps_kit() -> void:
	_each("g3p.camp_kit", func(ex: Dictionary, level: int) -> void:
		var s := _sorted(ex)
		for thing: String in s:
			assert_true(STONE_AGE.has(thing) or LATER.has(thing), "%s is in this test's lists" % thing)
			assert_eq(s[thing], "Stone Age camp" if STONE_AGE.has(thing) else "much later", thing))


# --- This test's own cube folding and shapes ------------------------------------------------------------------------

func _cells(rows: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in rows.size():
		for x in str(rows[y]).length():
			if str(rows[y])[x] != ".":
				out.append(Vector2i(x, y))
	return out


## Each lettered square -> the way its face points once the net is folded round the first square (a 3D direction). The
## cube is rolled with rotations of 3D vectors, not CubeNet's table.
func _fold(rows: Array) -> Dictionary:
	var letter := {}
	for y in rows.size():
		for x in str(rows[y]).length():
			if str(rows[y])[x] != ".":
				letter[Vector2i(x, y)] = str(rows[y])[x]
	var start: Vector2i = letter.keys()[0]
	var down := Vector3i(0, 0, -1)
	# per square: where each of the cube's first six directions points now
	var turn := {start: {Vector3i(1, 0, 0): Vector3i(1, 0, 0), Vector3i(-1, 0, 0): Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0): Vector3i(0, 1, 0), Vector3i(0, -1, 0): Vector3i(0, -1, 0), Vector3i(0, 0, 1): Vector3i(0, 0, 1),
		Vector3i(0, 0, -1): Vector3i(0, 0, -1)}}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + step
			if letter.has(n) and not turn.has(n):
				var now := {}
				for k: Vector3i in turn[c]:
					now[k] = _rolled(turn[c][k], step)
				turn[n] = now
				queue.append(n)
	var out := {}
	for c: Vector2i in turn:
		for k: Vector3i in turn[c]:
			if turn[c][k] == down:
				out[letter[c]] = k
	return out


## A direction after the cube rolls one square: over its edge in the direction of the step.
func _rolled(v: Vector3i, step: Vector2i) -> Vector3i:
	if step.x == 1:
		return Vector3i(v.z, v.y, -v.x)
	if step.x == -1:
		return Vector3i(-v.z, v.y, v.x)
	if step.y == 1:
		return Vector3i(v.x, v.z, -v.y)
	return Vector3i(v.x, -v.z, v.y)


func _normal(shape: Array) -> Array:
	var lo := Vector2i(1 << 20, 1 << 20)
	for c: Vector2i in shape:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
	var out: Array = []
	for c: Vector2i in shape:
		out.append(c - lo)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


func _key(shape: Array) -> String:
	return ";".join(shape.map(func(c: Vector2i) -> String: return "%d,%d" % [c.x, c.y]))


func _forms(shape: Array[Vector2i]) -> Array:
	var out: Array = []
	for flip in [false, true]:
		for t in 4:
			var r: Array = []
			for c in shape:
				var p := Vector2i(-c.x, c.y) if flip else c
				for _i in t:
					p = Vector2i(-p.y, p.x)
				r.append(p)
			out.append(_normal(r))
	return out
