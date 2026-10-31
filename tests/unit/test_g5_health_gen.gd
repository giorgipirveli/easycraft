extends GutTest
## Owner #70 and #73, grade 5 health and PE, design and technology, and projects: every "g5w" generator (G5HealthGen)
## makes answers that are right, worked out again here from each exercise's `data` with this test's own facts and rules:
## where to place a shot, tennis scores, a clear pass, dance counts and claps, personal bests and goals, facts about
## medicines, tobacco, vaping and alcohol, allergens, high temperatures, bedtimes, map scales, paces and bearings,
## gears, cams, bridges, a build's views, scale drawings, a program's output, recipes, seasons, cooking times, reuse,
## how long things take to break down, fibres, weaves, fair tests, criteria, a Roman grid, food webs, biomes' weather
## and a fair's money.

const SEEDS := 150
const NAMES: Array[String] = ["court_target", "tennis_score", "pass_lane", "dance_counts", "motif_claps", "pb_best",
	"goal_plan", "health_facts", "allergen_find", "fever_check", "bedtime", "map_scale", "pace_count", "bearing",
	"gear_turns", "gear_direction", "cam_rises", "bridge_piers", "bridge_test", "block_views", "scale_drawing",
	"control_trace", "recipe_servings", "season_pick", "cook_timing", "reuse_count", "breakdown_order", "fibre_sort",
	"weave_next", "test_average", "criteria_score", "roman_grid", "expedition_web", "biome_weather", "fair_money"]
## This test's own facts, written apart from the generator's tables.
const TRUE_FACTS: Array[String] = ["only take a medicine that a trusted adult gives you", "label tells you how much",
	"can look like sweets", "out of reach of young children", "pharmacist", "nicotine", "harms the heart and the lungs",
	"most adults in the uk do not smoke", "thousands of chemicals", "yellow", "against the law for a shop to sell alcohol",
	"against the law to sell cigarettes or nicotine vapes", "slows down", "brains are still growing", "alcohol-free childhood",
	"balance, speech", "you can say no"]
const FALSE_FACTS: Array[String] = ["a friend's medicine", "two doses", "is harmless", "made for children to try",
	"do not know what is in it"]
const CONTAINS := {"milk": ["cheese", "butter", "yoghurt", "cream", "custard"],
	"eggs": ["mayonnaise", "meringue", "an omelette", "egg fried rice"],
	"peanuts": ["peanut butter", "satay sauce", "peanut brittle"],
	"wheat": ["bread", "pasta", "couscous", "a flour tortilla"],
	"sesame": ["tahini", "hummus made with tahini", "a bun with sesame seeds"],
	"fish": ["tuna", "salmon", "fish fingers", "anchovies"], "soya": ["tofu", "soy sauce", "edamame beans"]}
const FREE: Array[String] = ["rice", "an apple", "carrots", "a banana", "potatoes", "peas", "grapes", "cucumber",
	"an orange", "plain chicken"]
const POINT_DEG := {"N": 0, "NE": 45, "E": 90, "SE": 135, "S": 180, "SW": 225, "W": 270, "NW": 315}
const RISES := {"round": 1, "pear": 1, "snail": 1, "oval": 2}
const SEASON := {"asparagus": "spring", "rhubarb": "spring", "wild garlic": "spring", "strawberries": "summer",
	"raspberries": "summer", "peas": "summer", "broad beans": "summer", "courgettes": "summer", "cherries": "summer",
	"apples": "autumn", "pears": "autumn", "pumpkins": "autumn", "butternut squash": "autumn", "leeks": "winter",
	"parsnips": "winter", "Brussels sprouts": "winter", "kale": "winter", "swede": "winter"}
## About how long each takes to break down (scientists' estimates, in years).
const YEARS := {"a paper towel": 0.06, "an apple core": 0.17, "a wool glove": 1.0, "a plastic bag": 20.0,
	"a tin can": 50.0, "an aluminium can": 200.0, "a plastic bottle": 450.0}
const FIBRE := {"cotton": "plant", "linen": "plant", "hemp": "plant", "jute": "plant", "wool": "animal",
	"silk": "animal", "cashmere": "animal", "alpaca wool": "animal", "polyester": "oil", "nylon": "oil",
	"acrylic": "oil", "elastane": "oil"}
## Who eats whom in the expedition's three food webs (food, eater).
const EATS: Array = [["grass", "grasshopper"], ["mesquite", "kangaroo rat"], ["grasshopper", "lizard"],
	["lizard", "hawk"], ["kangaroo rat", "rattlesnake"], ["rattlesnake", "hawk"], ["lizard", "rattlesnake"],
	["lichen", "caribou"], ["grass", "lemming"], ["grass", "arctic hare"], ["lemming", "snowy owl"],
	["lemming", "arctic fox"], ["arctic hare", "arctic fox"], ["arctic hare", "wolf"], ["caribou", "wolf"],
	["oak tree", "caterpillar"], ["oak tree", "mouse"], ["grass", "rabbit"], ["caterpillar", "blue tit"],
	["blue tit", "sparrowhawk"], ["mouse", "fox"], ["rabbit", "fox"]]
const PLANTS: Array[String] = ["grass", "mesquite", "lichen", "oak tree"]


func _each(gen: String, level: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in SEEDS:
		var ex := SchoolGen.make("g5w." + gen, s, level)
		assert_eq(ExerciseCheck.problem(ex), "", "%s L%d seed %d" % [gen, level, s])
		out.append(ex)
	return out


func _num(ex: Dictionary) -> float:
	return float(str(ex.answer))


func _chosen(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func _clock(minutes: int) -> String:
	var m := posmod(minutes, 24 * 60)
	var h := m / 60
	return "%d:%02d %s" % [12 if h % 12 == 0 else h % 12, m % 60, "am" if h < 12 else "pm"]


func test_every_generator_is_valid_and_varied_at_every_level() -> void:
	var names: Array[String] = []
	for id in SchoolGen.ids():
		if id.begins_with("g5w."):
			names.append(id.substr(4))
	names.sort()
	var want := NAMES.duplicate()
	want.sort()
	assert_eq(names, want, "the %d generators" % NAMES.size())
	for n in names:
		for level in [1, 2, 3]:
			var prompts := {}
			for ex in _each(n, level):
				prompts[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", "")) + str(ex.get("items", ""))
					+ str(ex.get("choices", "")) + str(ex.get("answer", ""))] = true
				assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)), "%s: its own answer" % ex.id)
				assert_true(ex.has("data") and ex.has("explain"), "%s: its data and worked answer" % ex.id)
				assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: a hint, not the answer" % ex.id)
			assert_gte(prompts.size(), 3 if level == 1 else 6, "g5w.%s L%d varies" % [n, level])


# --- Health and PE ---------------------------------------------------------------------------------------------------

func test_court_target_is_the_spot_farthest_from_the_other_side() -> void:
	for level in [1, 2, 3]:
		for ex in _each("court_target", level):
			var reach := {}
			for s: Array in ex.data.spots:
				var best := INF
				for p: Array in ex.data.players:
					if str(p[2]) == "d":
						best = minf(best, Vector2(float(s[0]), float(s[1])).distance_to(Vector2(float(p[0]), float(p[1]))))
				reach[str(s[2])] = best
				assert_gt(float(s[0]), 6.0, "%s: the spots are over the net" % ex.id)
			var right := _chosen(ex)
			for tag: String in reach:
				if tag != right:
					assert_gte(float(reach[right]) - float(reach[tag]), 1.0, "%s: %s is clearly farther than %s" % [ex.id,
						right, tag])


## Tennis: love, 15, 30, 40, game (two clear points); 40-40 is deuce, then advantage; the server's score first.
func _call(points: Array, server: String, receiver: String) -> String:
	var s := points.count("s")
	var r := points.count("r")
	var word := ["love", "15", "30", "40"]
	if s >= 4 and s - r >= 2:
		return "game to " + server
	if r >= 4 and r - s >= 2:
		return "game to " + receiver
	if s >= 3 and r >= 3:
		return "deuce" if s == r else "advantage " + (server if s > r else receiver)
	if s == r:
		return "%s-all" % word[s]
	return "%s-%s" % [word[s], word[r]]


func test_tennis_scores_follow_the_rules() -> void:
	for level in [1, 2, 3]:
		for ex in _each("tennis_score", level):
			var pts: Array = ex.data.points
			assert_eq(_chosen(ex), _call(pts, str(ex.data.server), str(ex.data.receiver)), ex.id)
			if level < 3:
				assert_false(_chosen(ex).begins_with("game") or _chosen(ex) in ["deuce"], "%s: no deuce yet" % ex.id)


## The distance from `p` to the pass from `a` to `b`, and how far along it the nearest point is (0-1).
func _lane(a: Vector2, b: Vector2, p: Vector2) -> Vector2:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return Vector2(p.distance_to(a + ab * t), t)


func test_pass_lane_finds_the_one_clear_or_blocked_pass() -> void:
	for level in [1, 2, 3]:
		for ex in _each("pass_lane", level):
			var players: Array = ex.data.players
			var carrier := Vector2(float(players[0][0]), float(players[0][1]))
			var right := _chosen(ex)
			for pl: Array in players:
				if pl.size() < 4:
					continue
				var mate := Vector2(float(pl[0]), float(pl[1]))
				var nearest := INF
				for d: Array in players:
					if str(d[2]) == "d":
						nearest = minf(nearest, _lane(carrier, mate, Vector2(float(d[0]), float(d[1]))).x)
				var clear := nearest >= 1.2
				var blocked := nearest <= 0.6
				assert_true(clear or blocked, "%s: %s's pass is clearly open or closed" % [ex.id, pl[3]])
				var is_answer := str(pl[3]) == right
				if str(ex.data.ask) == "safe":
					assert_eq(clear, is_answer, "%s: %s" % [ex.id, pl[3]])
				else:
					assert_eq(blocked, is_answer, "%s: %s" % [ex.id, pl[3]])


func test_dance_counts_and_claps() -> void:
	for level in [1, 2, 3]:
		for ex in _each("dance_counts", level):
			var d: Dictionary = ex.data
			match str(d.kind):
				"phrase":
					assert_eq(_num(ex), float(8 * int(d.eights)), ex.id)
				"canon":
					assert_eq(_num(ex), float(1 + (int(d.dancer) - 1) * int(d.gap)), ex.id)
				"structure":
					var total := 0
					for part: String in str(d.form):
						total += int(d.lengths[part])
					assert_eq(_num(ex), float(total), ex.id)
		for ex in _each("motif_claps", level):
			var p := str(ex.data.pattern)
			assert_eq(p, str(ex.sound.pattern), ex.id)
			assert_eq(p.length(), [4, 6, 8][level - 1], "%s: its length" % ex.id)
			assert_true(p.begins_with("x") and p.count("x") >= 2 and p.count("-") >= 1, "%s: claps and a rest" % ex.id)


func test_personal_bests_and_goals() -> void:
	for level in [1, 2, 3]:
		for ex in _each("pb_best", level):
			var v: Array = ex.data.values
			match str(ex.data.kind):
				"longest":
					assert_eq(_num(ex), float(v.max()), ex.id)
				"improve":
					assert_eq(_num(ex), float(v[-1]) - float(v[0]), ex.id)
					for bar: Array in ex.picture.bars:
						assert_eq(int(float(bar[1])) % int(ex.picture.step), 0, "%s: bars on the lines" % ex.id)
				"fastest":
					assert_eq(_chosen(ex), "%.1f s" % float(v.min()), ex.id)
				"mean":
					var sum := 0.0
					for x: Variant in v:
						sum += float(x)
					assert_eq(_num(ex), sum / v.size(), ex.id)
		for ex in _each("goal_plan", level):
			var d: Dictionary = ex.data
			match str(d.kind):
				"more":
					assert_eq(_num(ex), float(int(d.goal) - int(d.now)), ex.id)
				"weeks":
					assert_eq(_num(ex) * float(d.step), float(int(d.goal) - int(d.now)), ex.id)
				"after":
					assert_eq(_num(ex), float(int(d.now) + int(d.step) * int(d.weeks)), ex.id)


func test_health_facts_are_true_or_false_as_this_test_knows_them() -> void:
	for level in [1, 2, 3]:
		for ex in _each("health_facts", level):
			var s := str(ex.data.statement).to_lower()
			var truth := -1
			for f in TRUE_FACTS:
				if s.contains(f):
					truth = 1
			for f in FALSE_FACTS:
				if s.contains(f):
					truth = 0
			assert_ne(truth, -1, "%s: this test knows '%s'" % [ex.id, s])
			assert_eq(ex.answer, truth == 1, "%s: %s" % [ex.id, s])


func test_allergens_are_found_by_this_tests_own_table() -> void:
	for level in [1, 2, 3]:
		for ex in _each("allergen_find", level):
			var has: Array = CONTAINS[str(ex.data.allergen)]
			match str(ex.type):
				"choice":
					for i in (ex.choices as Array).size():
						var food := ExerciseCheck.item_text(ex.choices[i])
						assert_true(has.has(food) or FREE.has(food), "%s: %s is known" % [ex.id, food])
						var right := i == int(ex.answer)
						if str(ex.data.kind) == "contains":
							assert_eq(has.has(food), right, "%s: %s" % [ex.id, food])
						else:
							assert_eq(FREE.has(food), right, "%s: %s" % [ex.id, food])
				"sort":
					for i in (ex.items as Array).size():
						var food := str(ex.items[i])
						assert_eq(int(ex.answer[i]), 0 if has.has(food) else 1, "%s: %s" % [ex.id, food])
						assert_true(has.has(food) or FREE.has(food), "%s: %s is known" % [ex.id, food])


func test_a_high_temperature_is_38_or_more() -> void:
	for level in [1, 2, 3]:
		for ex in _each("fever_check", level):
			var t: Array = ex.data.temps
			match str(ex.data.kind):
				"one":
					assert_eq(ex.answer, float(t[0]) >= 38.0, ex.id)
				"which":
					assert_eq(_chosen(ex), "%.1f °C" % float(t[0]), ex.id)
					assert_gte(float(t[0]), 38.0, ex.id)
					for x: Variant in t.slice(1):
						assert_lt(float(x), 38.0, ex.id)
				"fall":
					assert_almost_eq(_num(ex), float(t[0]) - float(t[1]), 0.0001, ex.id)


func test_bedtimes_add_up() -> void:
	for level in [1, 2, 3]:
		for ex in _each("bedtime", level):
			var d: Dictionary = ex.data
			match str(d.kind):
				"hours":
					assert_eq(_num(ex) * 60.0, float(posmod(int(d.wake) - int(d.sleep), 24 * 60)), ex.id)
				"asleep":
					assert_eq(_chosen(ex), _clock(int(d.wake) - int(d.need)), ex.id)
				"screens":
					assert_eq(_chosen(ex), _clock(int(d.wake) - int(d.need) - 60), ex.id)
			if ex.has("picture"):
				assert_eq(int(ex.picture.h) * 60 + int(ex.picture.m), int(d.wake), "%s: the clock shows the wake time" % ex.id)
			assert_between(int(d.get("need", 600)), 540, 720, "%s: 9 to 12 hours" % ex.id)


func test_maps_paces_and_bearings() -> void:
	for level in [1, 2, 3]:
		for ex in _each("map_scale", level):
			var d: Dictionary = ex.data
			assert_almost_eq(float(d.cm) * float(d.m_per_cm), float(d.metres), 0.0001, ex.id)
			assert_almost_eq(_num(ex), float(d.cm) if str(d.kind) == "to_map" else float(d.metres), 0.0001, ex.id)
		for ex in _each("pace_count", level):
			var d: Dictionary = ex.data
			assert_almost_eq(float(d.paces), float(d.per100) * float(d.metres) / 100.0, 0.0001, ex.id)
			assert_eq(_num(ex), float(d.metres) if str(d.kind) == "metres" else float(d.paces), ex.id)
			assert_eq(int(d.per100) % 2, 0, "%s: whole paces" % ex.id)
		for ex in _each("bearing", level):
			var d: Dictionary = ex.data
			match str(d.kind):
				"name":
					assert_eq(_chosen(ex), str(d.point), ex.id)
					assert_eq(int(POINT_DEG[str(d.point)]), int(ex.picture.bearing), ex.id)
				"degrees":
					assert_eq(_num(ex), float(POINT_DEG[str(d.point)]), ex.id)
				"point":
					assert_eq(_chosen(ex), str(d.point), ex.id)
					assert_eq(int(POINT_DEG[str(d.point)]), int(d.bearing), ex.id)
				"turn":
					assert_eq(_num(ex), float(posmod(int(d.bearing) + int(d.turn), 360)), ex.id)


# --- Design and technology -------------------------------------------------------------------------------------------

func test_gears_turn_by_their_teeth_and_opposite_ways() -> void:
	for level in [1, 2, 3]:
		for ex in _each("gear_turns", level):
			var d: Dictionary = ex.data
			assert_eq(int(d.driver_turns) * int(d.driver), int(d.driven_turns) * int(d.driven), "%s: teeth passed" % ex.id)
			assert_eq(_num(ex), float(d.driver_turns if str(d.ask) == "driver" else d.driven_turns), ex.id)
			assert_eq(ex.picture.gears, [d.driver, d.driven], ex.id)
		for ex in _each("gear_direction", level):
			var d: Dictionary = ex.data
			var same: bool
			if str(d.kind) == "gears":
				same = int(d.n) % 2 == 1
				assert_eq((ex.picture.gears as Array).size(), int(d.n), ex.id)
			else:
				same = not bool(d.crossed)
			var first := str(d.first)
			var last := first if same else ("anticlockwise" if first == "clockwise" else "clockwise")
			assert_eq(_chosen(ex), last, ex.id)


func test_cams_rise_by_their_shape() -> void:
	for level in [1, 2, 3]:
		for ex in _each("cam_rises", level):
			var d: Dictionary = ex.data
			if str(d.kind) == "rises":
				assert_eq(_num(ex), float(int(RISES[str(d.shape)]) * int(d.turns)), ex.id)
				assert_eq(str(ex.picture.shape), str(d.shape), ex.id)
			else:
				assert_almost_eq(_num(ex), float(d.far) - float(d.near), 0.0001, ex.id)


func test_bridges_spans_piers_and_tests() -> void:
	for level in [1, 2, 3]:
		for ex in _each("bridge_piers", level):
			var d: Dictionary = ex.data
			var spans := int(d.length) / int(d.span)
			assert_eq(int(d.length) % int(d.span), 0, ex.id)
			assert_eq(_num(ex), float(spans if str(d.kind) == "spans" else spans - 1), ex.id)
		for ex in _each("bridge_test", level):
			var d: Dictionary = ex.data
			var rows: Array = d.get("rows", [])
			match str(d.kind):
				"most":
					var best: Array = rows[0]
					for r: Array in rows:
						if int(r[1]) > int(best[1]):
							best = r
					assert_eq(_chosen(ex), str(best[0]), ex.id)
				"grams":
					assert_eq(_num(ex), float(int(d.washers) * int(d.each)), ex.id)
				"ratio":
					var best: Array = rows[0]
					for r: Array in rows:
						if float(r[2]) / float(r[1]) > float(best[2]) / float(best[1]):
							best = r
					assert_eq(_chosen(ex), str(best[0]), ex.id)
					for r: Array in rows:
						if r != best:
							assert_gte(float(best[2]) / float(best[1]) - float(r[2]) / float(r[1]), 3.0, "%s: clear" % ex.id)


func _front(rows: Array) -> String:
	var out := ""
	for c in str(rows[0]).length():
		var top := 0
		for r: Variant in rows:
			top = maxi(top, int(str(r)[c]))
		out += str(top)
	return out


func _side(rows: Array) -> String:
	var out := ""
	for i in range(rows.size() - 1, -1, -1):   # from the right: the front row on the left
		var top := 0
		for ch in str(rows[i]):
			top = maxi(top, int(ch))
		out += str(top)
	return out


func test_block_views_and_scale_drawings() -> void:
	for level in [1, 2, 3]:
		for ex in _each("block_views", level):
			var rows: Array = ex.data.heights
			match str(ex.data.kind):
				"count":
					var sum := 0
					for r: Variant in rows:
						for ch in str(r):
							sum += int(ch)
					assert_eq(_num(ex), float(sum), ex.id)
				"front", "side":
					var want := _front(rows) if str(ex.data.kind) == "front" else _side(rows)
					var seen := {}
					for i in (ex.choices as Array).size():
						var pic: Dictionary = ex.choices[i].picture
						var shown := _front(pic.heights)
						assert_false(seen.has(shown), "%s: every choice looks different" % ex.id)
						seen[shown] = true
						assert_eq(shown == want, i == int(ex.answer), "%s: choice %d" % [ex.id, i])
		for ex in _each("scale_drawing", level):
			var d: Dictionary = ex.data
			assert_almost_eq(float(d.draw_cm) * float(d.scale), float(d.real_cm), 0.0001, ex.id)
			var want: float = float(d.draw_cm) if str(d.kind) == "to_drawing" else float(d.real_cm) / float(d.get("unit", 1))
			assert_almost_eq(_num(ex), want, 0.0001, ex.id)


func test_the_programs_run() -> void:
	for level in [1, 2, 3]:
		for ex in _each("control_trace", level):
			var d: Dictionary = ex.data
			if str(d.kind) == "loop":
				assert_eq(_num(ex), float(int(d.repeats) * (int(d.on) + int(d.off))), ex.id)
				continue
			var on: bool = int(d.reading) < int(d.threshold) if str(d.op) == "<" else int(d.reading) > int(d.threshold)
			assert_ne(int(d.reading), int(d.threshold), "%s: never on the line" % ex.id)
			var lines: Array = ex.picture.lines
			assert_true(str(lines[1]).strip_edges() == "IF %s %s %d" % [d.sensor, d.op, int(d.threshold)], ex.id)
			if str(ex.type) == "truefalse":
				assert_eq(ex.answer, on, ex.id)
			else:
				assert_eq(_chosen(ex), "on" if on else "off", ex.id)


func test_recipes_seasons_and_timings() -> void:
	for level in [1, 2, 3]:
		for ex in _each("recipe_servings", level):
			var d: Dictionary = ex.data
			assert_almost_eq(_num(ex), float(d.amount) * float(d.target) / float(d.base), 0.0001, ex.id)
			assert_eq(_num(ex), floorf(_num(ex)), "%s: a whole amount" % ex.id)
		for ex in _each("season_pick", level):
			var d: Dictionary = ex.data
			match str(ex.type):
				"choice":
					if str(d.kind) == "food":
						for i in (ex.choices as Array).size():
							var food := ExerciseCheck.item_text(ex.choices[i])
							assert_eq(str(SEASON[food]) == str(d.season), i == int(ex.answer), "%s: %s" % [ex.id, food])
					else:
						assert_eq(_chosen(ex), str(SEASON[str(d.food)]), ex.id)
				"sort":
					for i in (ex.items as Array).size():
						assert_eq(str(ex.groups[int(ex.answer[i])]), str(SEASON[str(ex.items[i])]), ex.id)
		for ex in _each("cook_timing", level):
			var d: Dictionary = ex.data
			match str(d.kind):
				"total":
					assert_eq(_num(ex), float(int(d.prep) + int(d.cook)), ex.id)
				"ready":
					assert_eq(_chosen(ex), _clock(int(d.start) + int(d.prep) + int(d.cook)), ex.id)
				"start":
					assert_eq(_chosen(ex), _clock(int(d.ready) - int(d.prep) - int(d.cook)), ex.id)


func test_reuse_breakdown_fibres_and_weaves() -> void:
	for level in [1, 2, 3]:
		for ex in _each("reuse_count", level):
			var d: Dictionary = ex.data
			assert_eq(_num(ex), float(int(d.have) / int(d.per)), ex.id)
		for ex in _each("breakdown_order", level):
			var shown: Array = ex.items
			var years: Array = []
			for i: Variant in ex.answer:
				years.append(float(YEARS[str(shown[int(i)])]))
			for k in years.size() - 1:
				assert_gte(float(years[k + 1]) / float(years[k]), 2.0, "%s: shortest first, clearly apart" % ex.id)
		for ex in _each("fibre_sort", level):
			for i in (ex.items as Array).size():
				var kind := str(FIBRE[str(ex.items[i])])
				var group := str(ex.groups[int(ex.answer[i])])
				if (ex.groups as Array).size() == 2:
					assert_eq(group == "made fibre", kind == "oil", "%s: %s" % [ex.id, ex.items[i]])
				else:
					assert_true(group.contains({"plant": "plants", "animal": "animals", "oil": "oil"}[kind]),
						"%s: %s" % [ex.id, ex.items[i]])
		for ex in _each("weave_next", level):
			var rows: Array = ex.data.rows
			var last := str(rows[-1])
			var want := ""
			if str(ex.data.kind) == "plain":
				for ch in last:
					want += "u" if ch == "o" else "o"
			else:   # a twill steps one thread along each row (8 threads: two whole repeats)
				assert_eq(last.length(), 8, "%s: a whole twill" % ex.id)
				want = last.substr(last.length() - 1) + last.substr(0, last.length() - 1)
			assert_eq(str(ex.choices[int(ex.answer)].picture.rows[0]), want, ex.id)


func test_fair_tests_and_criteria() -> void:
	for level in [1, 2, 3]:
		for ex in _each("test_average", level):
			var v: Array = ex.data.values
			var kept: Array = []
			for i in v.size():
				if i != int(ex.data.get("odd", -1)):
					kept.append(float(v[i]))
			var sum := 0.0
			for x: float in kept:
				sum += x
			assert_eq(_num(ex), sum / kept.size(), ex.id)
		for ex in _each("criteria_score", level):
			var d: Dictionary = ex.data
			var ta := 0
			var tb := 0
			for x: Variant in d.a:
				ta += int(x)
			for x: Variant in d.b:
				tb += int(x)
			assert_ne(ta, tb, "%s: no tie" % ex.id)
			match str(d.kind):
				"winner":
					assert_eq(_chosen(ex), "design A" if ta > tb else "design B", ex.id)
				"total":
					assert_eq(_num(ex), float(ta if str(d.design) == "A" else tb), ex.id)
				"by":
					assert_eq(_num(ex), float(absi(ta - tb)), ex.id)


# --- Projects --------------------------------------------------------------------------------------------------------

func test_the_roman_grid() -> void:
	for level in [1, 2, 3]:
		for ex in _each("roman_grid", level):
			var d: Dictionary = ex.data
			var at := {}
			for p: Dictionary in d.points:
				at[str(p.label)] = Vector2i(int(p.x), int(p.y))
			var t: Vector2i = at[str(d.target)]
			match str(d.kind):
				"tap":
					assert_eq(ExerciseCheck.answer_of(ex), t, ex.id)
				"name":
					assert_eq(_chosen(ex), "(%d, %d)" % [t.x, t.y], ex.id)
				"walk":
					var f: Vector2i = at[str(d.from)]
					assert_eq(_num(ex), float((absi(t.x - f.x) + absi(t.y - f.y)) * 10), ex.id)


func test_the_expedition_webs_are_true_and_read_right() -> void:
	var real := {}
	for pair: Array in EATS:
		real["%s>%s" % pair] = true
	for level in [1, 2, 3]:
		for ex in _each("expedition_web", level):
			var nodes: Array = ex.picture.nodes
			var eats := {}
			for l: Array in ex.picture.links:
				var key := "%s>%s" % [nodes[int(l[0])][0], nodes[int(l[1])][0]]
				assert_true(real.has(key), "%s: %s is true" % [ex.id, key])
				eats[key] = true
			var who := str(ex.data.subject)
			match str(ex.data.kind):
				"producer":
					assert_true(PLANTS.has(_chosen(ex)), ex.id)
					for i in (ex.choices as Array).size():
						if i != int(ex.answer):
							assert_false(PLANTS.has(ExerciseCheck.item_text(ex.choices[i])), ex.id)
				"eats":
					for i in (ex.choices as Array).size():
						var food := ExerciseCheck.item_text(ex.choices[i])
						assert_eq(eats.has("%s>%s" % [food, who]), i == int(ex.answer), "%s: %s" % [ex.id, food])
				"loses":
					for i in (ex.choices as Array).size():
						var eater := ExerciseCheck.item_text(ex.choices[i])
						assert_eq(eats.has("%s>%s" % [who, eater]), i == int(ex.answer), "%s: %s" % [ex.id, eater])


func test_biomes_and_the_fairs_money() -> void:
	for level in [1, 2, 3]:
		for ex in _each("biome_weather", level):
			var d: Dictionary = ex.data
			var rows: Array = d.rows   # [name, °C, mm of rain]
			match str(d.kind):
				"wettest", "driest", "warmest", "coldest":
					var col := 2 if str(d.kind) in ["wettest", "driest"] else 1
					var most := str(d.kind) in ["wettest", "warmest"]
					var best: Array = rows[0]
					for r: Array in rows:
						if (float(r[col]) > float(best[col])) == most and float(r[col]) != float(best[col]):
							best = r
					assert_eq(_chosen(ex), str(best[0]), ex.id)
				"rain_gap":
					assert_eq(_num(ex), float(d.a) - float(d.b), ex.id)
				"warmer":
					assert_eq(_num(ex), float(d.a) - float(d.b), ex.id)
					assert_true(str(ex.prompt).contains("−") or float(d.b) >= 0, "%s: minus signs" % ex.id)
		for ex in _each("fair_money", level):
			var d: Dictionary = ex.data
			match str(d.kind):
				"left":
					var spent := 0.0
					for c: Variant in d.costs:
						spent += float(c)
					assert_almost_eq(_num(ex), float(d.budget) - spent, 0.0001, ex.id)
					assert_gt(_num(ex), 0.0, ex.id)
				"discount":
					assert_almost_eq(_num(ex), float(d.price) * (100.0 - float(d.percent)) / 100.0, 0.0001, ex.id)
				"profit":
					assert_almost_eq(_num(ex), float(d.tickets) * float(d.each) - float(d.costs), 0.0001, ex.id)
					assert_gt(_num(ex), 0.0, ex.id)
