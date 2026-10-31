extends GutTest
## Owner #68, the grade 4 agent: grade 4 life and Earth science's generators (G4LifeGen "g4l": plant and animal parts,
## senses and the brain; G4EarthGen "g4t": weathering and erosion, maps of Earth's features, energy resources, natural
## hazards), checked against what they show: maps read here, arithmetic done here, lists kept here.

const SEEDS := 60
const SENSES: Array[String] = ["sight", "hearing", "smell", "taste", "touch"]
const RENEWABLE: Array[String] = ["sunlight", "wind", "flowing river water", "ocean waves", "heat from deep underground",
	"wood from trees that are replanted"]
const NOT_RENEWABLE: Array[String] = ["coal", "oil", "natural gas", "petrol", "uranium"]


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if not ex.is_empty():
				check.call(ex, level)


func _shown_order(ex: Dictionary) -> Array:
	var out: Array = []
	for i: Variant in ex.answer:
		out.append(str(ex.items[int(i)]))
	return out


## Map cells next to (or on) the other kind: land next to sea.
func _coastal(rows: Array, x: int, y: int) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + d.x
		var ny := y + d.y
		if ny >= 0 and ny < rows.size() and nx >= 0 and nx < str(rows[ny]).length() and "~=x".contains(str(rows[ny])[nx]):
			return true
	return false


# --- Plant and animal parts; senses (g4l) -------------------------------------------------------------------------

func test_every_part_has_one_job_and_its_wrong_jobs_are_others() -> void:
	for row: Dictionary in G4LifeGen.PARTS:
		assert_false((row.wrongs as Array).has(row.right), str(row.q))
		assert_eq((row.wrongs as Array).size(), 3, str(row.q))
	_each("g4l.part_job", func(ex: Dictionary, _l: int) -> void:
		var row: Dictionary = G4LifeGen.PARTS.filter(func(r: Dictionary) -> bool: return r.q == ex.prompt)[0]
		assert_eq(ExerciseCheck.answer_text(ex), str(row.right)))


func test_inside_and_outside_parts() -> void:
	_each("g4l.inside_outside", func(ex: Dictionary, _l: int) -> void:
		if str(ex.type) == "truefalse":
			var part := str(ex.data.part)
			var inside := G4LifeGen.INSIDE.has(part)
			assert_true(inside or G4LifeGen.OUTSIDE.has(part))
			assert_eq(ex.answer, inside == str(ex.prompt).contains("inside"), str(ex.prompt))
		else:
			var want_inside := str(ex.prompt).contains("inside")
			for i in (ex.choices as Array).size():
				var c := str(ex.choices[i])
				assert_eq(i == int(ex.answer), G4LifeGen.INSIDE.has(c) == want_inside, "%s: %s" % [ex.prompt, c]))
	for part in G4LifeGen.INSIDE:
		assert_false(G4LifeGen.OUTSIDE.has(part), part)


func test_each_situation_uses_one_of_the_five_senses() -> void:
	_each("g4l.which_sense", func(ex: Dictionary, _l: int) -> void:
		assert_eq(ex.choices.size(), 5)
		for c: Variant in ex.choices:
			assert_true(SENSES.has(str(c)))
		assert_eq(ExerciseCheck.answer_text(ex), str(ex.data.sense), str(ex.prompt)))


func test_information_goes_from_the_sense_to_the_brain_to_the_action() -> void:
	_each("g4l.sense_steps", func(ex: Dictionary, level: int) -> void:
		var steps := _shown_order(ex)
		assert_true(steps[0].contains(" pick up ") or steps[0].contains(" picks up "), "the sense first: %s" % steps[0])
		assert_true(steps[1].contains("brain"), "then the brain")
		assert_eq(steps.size(), 3 if level == 1 else 4)
		if level > 1:
			assert_true(steps[2].contains("decides"), "the brain decides before the body acts")
		assert_false(steps.back().contains("brain"), "the action last"))


# --- Weathering and erosion; maps; resources; hazards (g4t) -------------------------------------------------------

func test_weathering_breaks_erosion_carries_deposition_drops() -> void:
	_each("g4t.weather_or_erode", func(ex: Dictionary, level: int) -> void:
		assert_eq(ex.choices.size(), 3 if level == 3 else 2)
		assert_eq(ExerciseCheck.answer_text(ex), str(ex.data.kind), str(ex.prompt)))
	for row: Array in G4EarthGen.CHANGES:
		assert_true(["weathering", "erosion", "deposition"].has(str(row[1])), str(row[0]))


func test_the_cause_of_each_change_is_named_in_it() -> void:
	var words := {"water": ["river", "rain", "wave", "stream", "flood"], "ice": ["ice", "glacier", "frost"],
		"wind": ["wind", "blow", "dune", "dust"], "plants": ["root", "moss", "plant", "tree"]}
	_each("g4t.erosion_cause", func(ex: Dictionary, _l: int) -> void:
		var cause := ExerciseCheck.answer_text(ex)
		var said := str(ex.data.change).to_lower()
		assert_true((words[cause] as Array).any(func(w: String) -> bool: return said.contains(w)), "%s: %s" % [cause, said])
		for other: String in words:
			if other != cause and not (other == "water" and cause == "ice"):
				assert_false((words[other] as Array).any(func(w: String) -> bool: return said.contains(w)),
					"%s names only its cause (%s)" % [said, other]))


func test_erosion_rates_multiply_and_divide() -> void:
	_each("g4t.erosion_rate", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.has("total"):
			assert_eq(int(str(ex.answer)) * int(d.rate), int(d.total), str(ex.prompt))
		else:
			assert_eq(int(str(ex.answer)), int(d.rate) * int(d.years), str(ex.prompt)))


func test_the_map_is_counted() -> void:
	_each("g4t.map_count", func(ex: Dictionary, _l: int) -> void:
		var what := str(ex.data.what)
		var symbols := {"volcanoes": "v", "earthquakes": "*x", "mountains": "^"}[what] as String
		var n := 0
		for row: String in ex.picture.rows:
			for ch in row:
				n += int(symbols.contains(ch))
		assert_eq(int(str(ex.answer)), n, str(ex.picture.rows)))


func test_volcanoes_earthquakes_and_mountains_lie_along_the_coast() -> void:
	_each("g4t.map_pattern", func(ex: Dictionary, _l: int) -> void:
		var rows: Array = ex.picture.rows
		for y in rows.size():
			for x in str(rows[y]).length():
				var ch := str(rows[y])[x]
				if "v*^".contains(ch):
					assert_true(_coastal(rows, x, y), "%s at %d,%d is by the coast: %s" % [ch, x, y, rows])
				if ch == "=":
					assert_true(_coastal_to_land(rows, x, y), "the trench lies next to the coast: %s" % [rows])
		var right := ExerciseCheck.answer_text(ex)
		assert_true(right.contains("coast") or right == "a deep trench", right))


func _coastal_to_land(rows: Array, x: int, y: int) -> bool:
	for dx in [-2, -1, 1, 2]:
		var nx: int = x + dx
		if nx >= 0 and nx < str(rows[y]).length() and ".^v*".contains(str(rows[y])[nx]):
			return true
	return false


func test_heights_and_depths_are_compared_by_subtracting() -> void:
	_each("g4t.height_depth", func(ex: Dictionary, _l: int) -> void:
		var a: Array = ex.data.a
		var b: Array = ex.data.b
		match str(ex.type):
			"number":
				assert_eq(int(str(ex.answer)), absi(int(a[1]) - int(b[1])), str(ex.prompt))
			"choice":
				assert_eq(ExerciseCheck.answer_text(ex), str(a[0]) if int(a[1]) > int(b[1]) else str(b[0]))
		assert_true(str(ex.prompt).contains(GenKit.fmt(int(a[1]))) and str(ex.prompt).contains(GenKit.fmt(int(b[1])))))
	for row: Array in G4EarthGen.HEIGHTS + G4EarthGen.DEPTHS:
		assert_eq(int(row[1]) % 100, 0, "%s: rounded to the nearest hundred metres" % row[0])


func test_renewable_resources() -> void:
	_each("g4t.renewable", func(ex: Dictionary, _l: int) -> void:
		if str(ex.type) == "truefalse":
			var thing := str(ex.data.thing)
			assert_eq(ex.answer, RENEWABLE.has(thing), thing)
			assert_true(RENEWABLE.has(thing) or NOT_RENEWABLE.has(thing), thing)
		else:
			var want_not := str(ex.prompt).contains("NOT")
			for i in (ex.choices as Array).size():
				var c := str(ex.choices[i])
				assert_true(RENEWABLE.has(c) or NOT_RENEWABLE.has(c), c)
				assert_eq(i == int(ex.answer), NOT_RENEWABLE.has(c) if want_not else RENEWABLE.has(c), "%s: %s" % [ex.prompt, c]))


func test_turbines_and_homes() -> void:
	_each("g4t.power_homes", func(ex: Dictionary, _l: int) -> void:
		var d: Dictionary = ex.data
		if d.has("homes"):
			assert_eq(int(str(ex.answer)) * int(d.each), int(d.homes), str(ex.prompt))
		else:
			assert_eq(int(str(ex.answer)), int(d.each) * int(d.count), str(ex.prompt)))


func test_each_idea_protects_from_its_own_hazard() -> void:
	_each("g4t.hazard_idea", func(ex: Dictionary, level: int) -> void:
		assert_eq(ex.choices.size(), [2, 3, 4][level - 1])
		assert_eq(ExerciseCheck.answer_text(ex), str(ex.data.hazard), str(ex.prompt)))
