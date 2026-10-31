extends GutTest
## Owner #70 and #73, grade 4 health and PE, design and technology, and projects: every "g4w" generator (G4HealthGen)
## makes answers that are right, worked out again here from each exercise's `data` with this test's own facts and rules:
## distances on the pitch, jumps and relay times, circuit training, the parts of fitness, the UK's food-label traffic
## lights, sugar cubes, compass directions and distances on a map, circuits (a battery, a complete loop, metals conduct),
## wheels, fabric, triangle frames (Euler's rule for the struts), a bread recipe and its times, the food groups, a
## survey, materials, invention dates, the first civilisations' objects, fields, and a tune's notes by their pitch.

const SEEDS := 150
## This test's own facts, written apart from the generator's tables.
const FITNESS := {"a long, steady jog": "stamina", "swimming lengths": "stamina", "a long bike ride": "stamina",
	"skipping for 5 minutes": "stamina", "press-ups": "strength", "squats": "strength", "a plank": "strength",
	"climbing a rope": "strength", "a tug of war": "strength", "a 30 m sprint": "speed", "a sprint relay": "speed",
	"sprint starts": "speed", "a race to a cone": "speed", "touching your toes": "flexibility",
	"a butterfly stretch": "flexibility", "a calf stretch": "flexibility", "yoga stretches": "flexibility"}
## The UK's front-of-pack colours for food, per 100 g: green if at most the first, red if more than the second (grams).
const TRAFFIC := {"fat": [3.0, 17.5], "saturates": [1.5, 5.0], "sugars": [5.0, 22.5], "salt": [0.3, 1.5]}
const METAL: Array[String] = ["foil", "a paper clip", "a steel spoon", "a coin", "a key", "a nail"]
const NOT_METAL: Array[String] = ["a rubber band", "plastic ruler", "paper", "a lolly stick", "wooden spoon", "string",
	"plastic straw", "an eraser"]
const COMPASS := {"north": Vector2i(0, -1), "south": Vector2i(0, 1), "east": Vector2i(1, 0), "west": Vector2i(-1, 0),
	"north-east": Vector2i(1, -1), "north-west": Vector2i(-1, -1), "south-east": Vector2i(1, 1),
	"south-west": Vector2i(-1, 1)}
const ONE_LOAF := {"flour": 500, "water": 300, "yeast": 7, "salt": 10}
const FOOD_GROUP := {"carrots": "fruit and vegetables", "broccoli": "fruit and vegetables",
	"an apple": "fruit and vegetables", "a banana": "fruit and vegetables", "a salad": "fruit and vegetables",
	"cucumber": "fruit and vegetables", "spinach": "fruit and vegetables", "tomatoes": "fruit and vegetables",
	"peas": "fruit and vegetables", "sweetcorn": "fruit and vegetables", "rice": "starchy foods",
	"pasta": "starchy foods", "bread": "starchy foods", "noodles": "starchy foods", "a wrap": "starchy foods",
	"porridge oats": "starchy foods", "a baked potato": "starchy foods", "fish": "protein", "eggs": "protein",
	"chicken": "protein", "tofu": "protein", "nuts": "protein", "a glass of milk": "dairy", "cheese": "dairy",
	"a yoghurt": "dairy"}
## job -> [the material for it, the property it needs]
const MATERIALS := {"a window": ["glass", "transparent"], "a towel": ["cotton", "absorbent"],
	"the wires inside a cable": ["copper", "a conductor of electricity"], "a raincoat": ["waterproof nylon", "waterproof"],
	"a saucepan": ["steel", "a good conductor of heat"], "a saucepan's handle": ["wood", "a poor conductor of heat"],
	"the covering on a wire": ["plastic", "an electrical insulator"], "a bouncy ball": ["rubber", "elastic"],
	"a bridge's beams": ["steel", "strong and stiff"], "a warm hat": ["wool", "warm, because it traps air"],
	"a fridge door that magnets stick to": ["steel", "magnetic"]}
const YEARS := {"Al-Jazari's book of machines": 1206, "Gutenberg's printing press": 1440,
	"James Watt's steam engine": 1769, "Volta's electric battery": 1800, "the Stephensons' Rocket train": 1829,
	"Ada Lovelace's computer program": 1843, "Margaret Knight's bag machine": 1871, "Bell's telephone": 1876,
	"Karl Benz's motor car": 1886, "the Wright brothers' aeroplane": 1903, "Garrett Morgan's traffic signal": 1923,
	"John Logie Baird's television": 1926}
const MUSEUM := {"a mummy case": "Ancient Egypt", "a papyrus scroll": "Ancient Egypt", "a scarab charm": "Ancient Egypt",
	"a canopic jar": "Ancient Egypt", "a model pyramid": "Ancient Egypt", "a shaduf for lifting water": "Ancient Egypt",
	"a seal with a unicorn": "Indus Valley", "stone cubes for weighing": "Indus Valley", "a carnelian bead": "Indus Valley",
	"a clay toy cart": "Indus Valley", "a model of the Great Bath": "Indus Valley", "an oracle bone": "Shang China",
	"a bronze ding pot": "Shang China", "a turtle shell with writing": "Shang China", "a jade dragon": "Shang China",
	"a scrap of silk": "Shang China"}


func _each(gen: String, level: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in SEEDS:
		var ex := SchoolGen.make("g4w." + gen, s, level)
		assert_eq(ExerciseCheck.problem(ex), "", "%s L%d seed %d" % [gen, level, s])
		out.append(ex)
	return out


func _num(ex: Dictionary) -> float:
	return float(str(ex.answer))


func _chosen(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


func test_every_generator_is_valid_and_varied_at_every_level() -> void:
	var names: Array[String] = []
	for id in SchoolGen.ids():
		if id.begins_with("g4w."):
			names.append(id.substr(4))
	assert_eq(names.size(), 21, "the 21 generators: %s" % [names])
	for n in names:
		for level in [1, 2, 3]:
			var prompts := {}
			for ex in _each(n, level):
				prompts[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", "")) + str(ex.get("items", ""))
					+ str(ex.get("choices", "")) + str(ex.get("answer", ""))] = true
				assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)), "%s: its own answer" % ex.id)
				assert_true(ex.has("data") and ex.has("explain"), "%s: its data and worked answer" % ex.id)
			assert_gte(prompts.size(), 3 if level == 1 else 6, "g4w.%s L%d varies" % [n, level])


func test_find_space_picks_the_free_or_the_marked_teammate() -> void:
	for level in [1, 2, 3]:
		for ex in _each("find_space", level):
			var mates := {}
			var others: Array[Vector2] = []
			for p: Array in ex.data.players:
				var at := Vector2(float(p[0]), float(p[1]))
				assert_true(at.x > 0 and at.y > 0 and at.x < 12 and at.y < 7, "%s: on the pitch" % ex.id)
				if str(p[2]) == "d":
					others.append(at)
				elif p.size() == 4:
					mates[str(p[3])] = at
			var gap := {}
			for tag: String in mates:
				var best := INF
				for o in others:
					best = minf(best, (mates[tag] as Vector2).distance_to(o))
				gap[tag] = best
			var right := _chosen(ex)
			for tag: String in gap:
				if str(ex.data.ask) == "space":
					if tag == right:
						assert_gte(float(gap[tag]), 3.0, "%s: %s is free" % [ex.id, tag])
					else:
						assert_lte(float(gap[tag]), 1.5, "%s: %s is marked" % [ex.id, tag])
				else:
					if tag == right:
						assert_lte(float(gap[tag]), 1.5, "%s: %s is marked closely" % [ex.id, tag])
					else:
						assert_gte(float(gap[tag]), 3.0, "%s: %s is not" % [ex.id, tag])


func test_jumps_and_relays_add_up() -> void:
	for level in [1, 2, 3]:
		for ex in _each("jump_measure", level):
			var j: Array = ex.data.jumps
			for cm: int in j:
				assert_true(str(ex.prompt).contains("%d m %d cm" % [floori(cm / 100.0), cm % 100]), "%s: says %d cm" % [ex.id,
					cm])
			match str(ex.data.ask):
				"cm":
					assert_eq(_num(ex), float(j[0]))
				"further":
					assert_gt(int(j[1]), int(j[0]), "%s: better today" % ex.id)
					assert_eq(_num(ex), float(int(j[1]) - int(j[0])))
				_:
					assert_eq(_num(ex), float(int(j[0]) + int(j[1]) + int(j[2])))
		for ex in _each("relay_time", level):
			var total := 0
			for t: int in ex.data.legs:
				total += t
			if ex.data.has("last"):
				assert_eq(_num(ex), float(int(ex.data.last) - total), ex.id)
			else:
				assert_eq(_num(ex), float(total), ex.id)


func test_circuit_training_and_the_parts_of_fitness() -> void:
	for level in [1, 2, 3]:
		for ex in _each("circuit_training", level):
			var d: Dictionary = ex.data
			var secs := int(d.stations) * int(d.work) * int(d.rounds) + (int(d.stations) - 1) * int(d.rest)
			if str(d.ask) == "minutes":
				assert_eq(secs % 60, 0, "%s: whole minutes" % ex.id)
				assert_eq(_num(ex), secs / 60.0, ex.id)
			else:
				assert_eq(_num(ex), float(secs), ex.id)
		for ex in _each("fitness_sort", level):
			for i in (ex.items as Array).size():
				assert_eq(str(ex.groups[int(ex.answer[i])]), str(FITNESS[str(ex.items[i])]), "%s: %s" % [ex.id, ex.items[i]])


func _colour(nutrient: String, grams: float) -> String:
	var t: Array = TRAFFIC[nutrient.to_lower()]
	return "low" if grams <= float(t[0]) else ("high" if grams > float(t[1]) else "medium")


func test_food_labels_follow_the_traffic_lights() -> void:
	for level in [1, 2, 3]:
		for ex in _each("label_light", level):
			match str(ex.data.ask):
				"read":
					var highs: Array[String] = []
					var greens := 0
					for row: Array in ex.data.rows:
						var grams := float(str(row[1]).trim_suffix(" g"))
						assert_eq(str(row[2]), _colour(str(row[0]), grams), "%s: %s %s" % [ex.id, row[0], row[1]])
						if str(row[2]) == "high":
							highs.append(str(row[0]).to_lower())
						greens += 1 if str(row[2]) == "low" else 0
					if str(ex.type) == "choice":
						assert_eq(highs.size(), 1, "%s: one red box" % ex.id)
						assert_eq(_chosen(ex), highs[0], ex.id)
					else:
						assert_eq(_num(ex), float(greens), ex.id)
				"less":
					var a := int(ex.data.a)
					var b := int(ex.data.b)
					assert_ne(a, b)
					assert_eq(_chosen(ex), "cereal A" if a < b else "cereal B", ex.id)
				_:
					var grams := int(ex.data.tenths) / 10.0
					assert_true(_chosen(ex).to_lower().begins_with(_colour("sugars", grams)), "%s: %s g" % [ex.id, grams])
		for ex in _each("sugar_cubes", level):
			var d: Dictionary = ex.data
			if d.has("grams"):
				assert_eq(_num(ex), int(d.grams) / 4.0, ex.id)
			else:
				var grams := int(d.per) * int(d.bottle) / 100.0
				assert_eq(_num(ex), grams if str(d.ask) == "grams" else grams / 4.0, ex.id)
				assert_eq(fmod(_num(ex), 1.0), 0.0, "%s: whole" % ex.id)


func _find(rows: Array, ch: String) -> Vector2i:
	for y in rows.size():
		var x := str(rows[y]).find(ch)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


func test_the_orienteering_map_is_read_right() -> void:
	for level in [1, 2, 3]:
		for ex in _each("orienteer", level):
			var rows: Array = ex.data.rows
			var start := _find(rows, "S")
			for ch in ["1", "2", "3"]:
				assert_ne(_find(rows, ch), Vector2i(-1, -1), "%s: control %s is on the map" % [ex.id, ch])
			match str(ex.data.ask):
				"reach":
					var at: Vector2i = start + COMPASS[str(ex.data.way)] * int(ex.data.steps)
					assert_eq(_chosen(ex), "control %s" % str(rows[at.y])[at.x], ex.id)
				"way":
					var d := _find(rows, "2") - _find(rows, "1")
					assert_true(d.x == 0 or d.y == 0 or absi(d.x) == absi(d.y), "%s: on a compass line" % ex.id)
					var unit := Vector2i(signi(d.x), signi(d.y))
					assert_eq(COMPASS[_chosen(ex)], unit, ex.id)
				_:
					var c := _find(rows, str(ex.data.control))
					assert_eq(_num(ex), float((absi(c.x - start.x) + absi(c.y - start.y)) * int(ex.data.scale)), ex.id)


func test_circuits_work_only_when_complete() -> void:
	for level in [1, 2, 3]:
		for ex in _each("circuit_lights", level):
			if str(ex.data.ask) == "which":
				assert_true(METAL.has(_chosen(ex)), "%s: a metal bridges the gap" % ex.id)
				for i in (ex.choices as Array).size():
					if i != int(ex.answer):
						assert_true(NOT_METAL.has(ExerciseCheck.item_text(ex.choices[i])), "%s: an insulator" % ex.id)
				continue
			var parts: Array = ex.data.parts
			var works: bool = parts.has("cell") and str(ex.data.switch) != "open" \
				and (not parts.has("gap") or METAL.has(str(ex.data.gap)))
			assert_eq(ex.answer, works, "%s: %s" % [ex.id, ex.picture])
			assert_eq(ex.picture.parts, parts)


func test_wheels_fabric_and_frames() -> void:
	for level in [1, 2, 3]:
		for ex in _each("wheel_roll", level):
			var d: Dictionary = ex.data
			match str(d.ask):
				"distance":
					assert_eq(_num(ex), float(int(d.round[0]) * int(d.turns)), ex.id)
				"turns":
					assert_eq(_num(ex) * int(d.round[0]), float(d.distance), ex.id)
				_:
					assert_eq(_num(ex), float(int(d.turns) * int(d.round[1]) - int(d.turns) * int(d.round[0])), ex.id)
		for ex in _each("fabric_cut", level):
			var d: Dictionary = ex.data
			var one := int(d.size) + int(d.add[0]) + int(d.add[1])
			assert_eq(_num(ex), float(one * 2 if str(d.ask) == "ribbon" else one), ex.id)
		for ex in _each("frame_struts", level):
			# a strip of n triangles has n + 2 corners and n + 1 faces (the outside too): Euler's V − E + F = 2
			var n := int(ex.data.get("triangles", _num(ex)))
			var edges := (n + 2) + (n + 1) - 2
			if str(ex.data.ask) == "struts":
				assert_eq(_num(ex), float(edges), ex.id)
			else:
				assert_eq(int(ex.data.struts), edges, ex.id)


func test_bread_scales_and_bakes_on_time() -> void:
	for level in [1, 2, 3]:
		for ex in _each("bread_recipe", level):
			var d: Dictionary = ex.data
			if str(d.ask) == "rolls":
				assert_eq(_num(ex), 500.0 / 10.0 * int(d.rolls), ex.id)
			else:
				assert_eq(_num(ex), float(ONE_LOAF[str(d.ingredient)]) * float(d.times), ex.id)
		for ex in _each("bake_time", level):
			var end := int(ex.data.start)
			for m: int in ex.data.minutes:
				end += m
			var h := end / 60
			assert_eq(_chosen(ex), "%d:%02d %s" % [h - 12 if h > 12 else h, end % 60, "am" if h < 12 else "pm"], ex.id)
			assert_true(str(ex.prompt).contains("%d:%02d am" % [int(ex.data.start) / 60, int(ex.data.start) % 60]), ex.id)


func test_meals_surveys_and_materials() -> void:
	for level in [1, 2, 3]:
		for ex in _each("meal_missing", level):
			var have := {}
			for f: String in ex.data.foods:
				have[FOOD_GROUP[f]] = true
			var missing: Array[String] = []
			for g in ["fruit and vegetables", "starchy foods", "protein", "dairy"]:
				if not have.has(g):
					missing.append(g)
			assert_eq(missing.size(), 1, "%s: one group missing" % ex.id)
			assert_eq(_chosen(ex), missing[0], ex.id)
		for ex in _each("user_survey", level):
			var counts: Array = []
			var rows: Array = ex.picture.rows
			for i in range(1, rows.size()):
				counts.append(int(str(rows[i][1])))
			match str(ex.data.ask):
				"most":
					var best := counts.find(counts.max())
					assert_eq(counts.count(counts.max()), 1, "%s: one favourite" % ex.id)
					assert_eq(_chosen(ex), str(rows[best + 1][0]), ex.id)
				"total":
					var total := 0
					for c: int in counts:
						total += c
					assert_eq(_num(ex), float(total), ex.id)
				_:
					var a: int = counts[int(ex.data.pair[0])]
					var b: int = counts[int(ex.data.pair[1])]
					assert_true(str(ex.prompt).contains("chose %s than %s" % [rows[int(ex.data.pair[0]) + 1][0],
						rows[int(ex.data.pair[1]) + 1][0]]), ex.id)
					assert_eq(_num(ex), float(a - b), ex.id)
		for ex in _each("material_job", level):
			var m: Array = MATERIALS[str(ex.data.job)]
			assert_eq(_chosen(ex), str(m[0]) if str(ex.data.ask) == "material" else str(m[1]), ex.id)


func test_inventions_objects_fields_and_tunes() -> void:
	for level in [1, 2, 3]:
		for ex in _each("invention_order", level):
			var years: Array[int] = []
			for i: int in ex.answer:
				years.append(int(YEARS[str(ex.items[i])]))
			for i in range(1, years.size()):
				assert_gt(years[i], years[i - 1], "%s: oldest first" % ex.id)
		for ex in _each("museum_sort", level):
			for i in (ex.items as Array).size():
				assert_eq(str(ex.groups[int(ex.answer[i])]), str(MUSEUM[str(ex.items[i])]), "%s: %s" % [ex.id, ex.items[i]])
		for ex in _each("river_fields", level):
			var d: Dictionary = ex.data
			match str(d.ask):
				"area":
					assert_eq(_num(ex), float(int(d.w) * int(d.h)), ex.id)
				"perimeter":
					assert_eq(_num(ex), float(2 * (int(d.w) + int(d.h))), ex.id)
				"l_area":
					assert_eq(_num(ex), float(int(d.w) * int(d.h) + int(d.w2) * int(d.h2)), ex.id)
				_:
					assert_eq(int(ex.goal.area), int(d.w) * int(d.h), ex.id)
					assert_eq(int(ex.goal.perimeter), 2 * (int(d.w) + int(d.h)), ex.id)
					var cells: Array = []
					for y in int(d.h):
						for x in int(d.w):
							cells.append(Vector2i(x, y))
					assert_true(BuildCheck.check(ex.goal, ex.board, cells), "%s: the field fits the board" % ex.id)
		for ex in _each("tune_shape", level):
			var hz: Array[float] = []
			for n: String in ex.sound.notes:
				hz.append(SchoolSound.frequency(n))
			match str(ex.data.ask):
				"updown":
					var up := true
					var down := true
					for i in range(1, hz.size()):
						up = up and hz[i] > hz[i - 1]
						down = down and hz[i] < hz[i - 1]
					assert_true(up != down, "%s: all up or all down" % ex.id)
					assert_eq(_chosen(ex), "up" if up else "down", ex.id)
				"count":
					assert_eq(_num(ex), float(hz.size()), ex.id)
				_:
					var top := hz.find(hz.max())
					assert_eq(hz.count(hz.max()), 1, "%s: one highest" % ex.id)
					assert_eq(_chosen(ex), "the %s note" % ["first", "second", "third", "fourth"][top], ex.id)
