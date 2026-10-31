extends GutTest
## Owner #70, grade 3 science (G3ScienceGen, "g3s"): every generator's answer is worked out again here from the
## exercise's `data` with the test's own facts and rules, for many seeds and every level, and every exercise must be
## valid (ExerciseCheck, the picture's own check).

const SEEDS := 60
const LIVING := "living"
const ONCE := "once living"
const NEVER := "never living"


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make(gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % gen)
			check.call(ex, level)


func _right(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


## The items of an order exercise in its right order.
func _ordered(ex: Dictionary) -> Array:
	var out: Array = []
	for i: Variant in ex.answer:
		out.append(ex.items[int(i)])
	return out


# --- Living things and keys ---------------------------------------------------------------------------------------

func test_living_once_living_and_never_living() -> void:
	var once_words: Array[String] = ["wooden", "paper", "cotton", "leather", "woolly", "bone", "feather", "shell",
		"dry leaf"]
	var never_words: Array[String] = ["rock", "metal", "glass", "plastic", "puddle", "cloud", "fire", "robot", "Sun",
		"snowman"]
	_each("g3s.living_or_not", func(ex: Dictionary, _l: int) -> void:
		var thing := str(ex.data.thing)
		var expect := LIVING
		for w in once_words:
			if thing.contains(w):
				expect = ONCE
		for w in never_words:
			if thing.contains(w):
				expect = NEVER
		assert_eq(_right(ex), expect, thing)
		assert_true(str(ex.prompt).to_lower().contains(thing.to_lower()), "the prompt names %s" % thing))


func test_a_key_is_followed_question_by_question() -> void:
	_each("g3s.key_walk", func(ex: Dictionary, level: int) -> void:
		var key: Dictionary = G3ScienceGen.KEYS[int(ex.data.key)]
		var expect := str(key.last)
		for step: Array in key.steps:
			if (ex.data.features as Array).has(step[1]):
				expect = str(step[2])
				break
		assert_eq(_right(ex), expect, str(ex.prompt))
		assert_eq((ex.picture.rows as Array).size(), (key.steps as Array).size() + 1, "the key's table")
		if level == 3:
			assert_eq(expect, str(key.last), "level 3 answers no to every question"))


# --- Life cycles and plants ---------------------------------------------------------------------------------------

const CYCLES := {
	"frog": ["egg", "tadpole", "froglet", "adult frog"],
	"butterfly": ["egg", "caterpillar", "chrysalis", "butterfly"],
	"chicken": ["egg", "chick", "young hen", "adult hen"],
	"bean plant": ["seed", "seedling", "plant with flowers", "pod with seeds"],
	"ladybird": ["egg", "larva", "pupa", "adult ladybird"],
}


func test_a_life_cycle_in_order() -> void:
	_each("g3s.life_cycle_order", func(ex: Dictionary, level: int) -> void:
		var cycle: Array = CYCLES[str(ex.data.animal)]
		assert_eq(_ordered(ex), cycle.slice(0, 3 if level == 1 else 4), str(ex.prompt))
		assert_true(str(ex.prompt).contains(str(ex.data.animal))))


func test_what_comes_next_or_before_in_a_life_cycle() -> void:
	_each("g3s.life_cycle_next", func(ex: Dictionary, level: int) -> void:
		var cycle: Array = CYCLES[str(ex.data.animal)]
		var i := cycle.find(str(ex.data.stage))
		assert_eq(bool(ex.data.before), level == 3)
		assert_eq(_right(ex), str(cycle[i - 1] if ex.data.before else cycle[i + 1]), str(ex.prompt)))


func test_each_plant_part_and_its_job() -> void:
	var jobs := {"water from the soil": "the roots", "in the ground": "the roots", "food from sunlight": "the leaves",
		"makes the seeds": "the flower", "bright petals": "the flower", "leaves up": "the stem",
		"from the roots to the leaves": "the stem", "new plant": "the seed", "seeds safe": "the fruit"}
	_each("g3s.plant_part", func(ex: Dictionary, _l: int) -> void:
		var expect := ""
		for k: String in jobs:
			if str(ex.data.job).contains(k):
				expect = jobs[k]
		assert_eq(_right(ex), expect, str(ex.prompt)))


# --- Traits ---------------------------------------------------------------------------------------------------------

func test_where_a_trait_comes_from() -> void:
	var inherited := "inherited from the parents"
	var around := "changed by the surroundings"
	var learned := "learned"
	var expect := {"a cat's eye colour": inherited, "a dog's fur colour": inherited, "reading a book": learned,
		"riding a bike": learned, "a plant drooping with no water": around, "a sunburnt nose": around,
		"a zebra's stripes": inherited, "a parrot saying hello": learned, "a dog sitting when asked": learned,
		"a flamingo's pink feathers": around, "a pale plant grown in the dark": around, "a scar on a knee": around,
		"a bird's beak shape": inherited, "a spider's eight legs": inherited, "a sheepdog rounding up sheep": learned,
		"speaking English": learned, "blue hydrangeas in some soils": around,
		"a tree bent over by strong winds": around}
	_each("g3s.trait_kind", func(ex: Dictionary, _l: int) -> void:
		assert_true(expect.has(str(ex.data.trait)), "the test knows %s" % ex.data.trait)
		assert_eq(_right(ex), str(expect.get(str(ex.data.trait), "")), str(ex.prompt)))


func test_variation_is_read_from_the_table() -> void:
	_each("g3s.variation_table", func(ex: Dictionary, _l: int) -> void:
		var values: Array = ex.data.values
		var names := ["A", "B", "C", "D"]
		for i in 4:
			assert_eq(str(ex.picture.rows[i + 1][1]), str(values[i]), "the table shows every value")
		var most: int = values.max()
		var least: int = values.min()
		if str(ex.data.ask) == "most":
			assert_eq(_right(ex), names[values.find(most)])
		elif str(ex.data.ask) == "least":
			assert_eq(_right(ex), names[values.find(least)])
		elif str(ex.data.ask) == "over":
			var n := 0
			for v: int in values:
				if v > int(ex.data.line):
					n += 1
			assert_eq(int(str(ex.answer)), n, str(ex.prompt))
		else:
			assert_eq(int(str(ex.answer)), most - least, str(ex.prompt)))


# --- Fossils and habitats -------------------------------------------------------------------------------------------

func test_fossils_tell_of_the_place_and_its_age() -> void:
	var sea := ["fish", "shell"]
	_each("g3s.fossil_clue", func(ex: Dictionary, _l: int) -> void:
		var fossils: Dictionary = ex.data.fossils
		assert_eq(ex.picture.fossils, fossils, "the picture shows the fossils")
		var layers: Array = fossils.keys().map(func(k: String) -> int: return int(k))
		layers.sort()
		var lower := str(fossils[str(layers[0])])
		if str(ex.data.ask) == "place":
			assert_eq(_right(ex), "under the sea" if sea.has(lower) else "land with plants")
		elif str(ex.data.ask) == "older":
			assert_eq(_right(ex), "the " + lower)
		else:
			var upper := str(fossils[str(layers[1])])
			assert_ne(sea.has(lower), sea.has(upper), "one layer sea, one land")
			assert_eq(_right(ex), "The sea became land" if sea.has(lower) else "The land became sea"))


func test_what_survives_well_in_each_habitat() -> void:
	for place: String in G3ScienceGen.HABITATS:
		for t: String in G3ScienceGen.HABITATS[place].well:
			assert_false((G3ScienceGen.HABITATS[place].not as Array).has(t), "%s: %s both" % [place, t])
	var never := {"the sea": ["a camel", "a cactus"], "a hot desert": ["a shark", "a jellyfish"],
		"a pond": ["an octopus", "a shark"]}
	_each("g3s.habitat_fit", func(ex: Dictionary, _l: int) -> void:
		var place := str(ex.data.place)
		var fits: bool = (G3ScienceGen.HABITATS[place].well as Array).has(ex.data.thing)
		assert_eq(bool(ex.data.fits), fits, str(ex.prompt))
		if never.has(place):
			assert_false(fits and (never[place] as Array).has(ex.data.thing), "%s in %s" % [ex.data.thing, place])
		if str(ex.type) == "truefalse":
			assert_eq(ex.answer, fits)
		else:
			assert_eq(_right(ex), str(ex.data.thing))
			for c: Variant in ex.choices:
				if str(c) != str(ex.data.thing):
					assert_true((G3ScienceGen.HABITATS[place].not as Array).has(c), "%s cannot live in %s" % [c,
						place]))


# --- Food and materials ---------------------------------------------------------------------------------------------

func test_every_food_in_its_group() -> void:
	var group := {"bread": "starchy", "pasta": "starchy", "rice": "starchy", "potatoes": "starchy",
		"porridge oats": "starchy", "eggs": "protein", "fish": "protein", "beans": "protein", "lentils": "protein",
		"chicken": "protein", "apples": "fruit", "carrots": "fruit", "bananas": "fruit", "broccoli": "fruit",
		"oranges": "fruit", "milk": "dairy", "cheese": "dairy", "yoghurt": "dairy"}
	_each("g3s.food_group", func(ex: Dictionary, _l: int) -> void:
		assert_true(group.has(str(ex.data.food)), "the test knows %s" % ex.data.food)
		assert_true(_right(ex).begins_with(str(group.get(str(ex.data.food), "?"))), str(ex.prompt)))


func test_the_right_material_for_each_job() -> void:
	var best := {"a window": "glass", "a raincoat": "waterproof plastic", "a towel": "cotton", "a car tyre": "rubber",
		"a saucepan": "metal", "a pair of wellies": "rubber", "a spoon to stir a hot pan": "wood",
		"a bridge over a river": "steel", "curtains that keep out light": "thick fabric", "a fish tank": "glass"}
	_each("g3s.material_job", func(ex: Dictionary, _l: int) -> void:
		var job := str(ex.data.job)
		assert_true(best.has(job), "the test knows %s" % job)
		if str(ex.data.ask) == "material":
			assert_eq(_right(ex), str(best[job]), str(ex.prompt))
		else:
			assert_true(str(ex.prompt).contains(str(best[job])), str(ex.prompt))
			assert_eq(_right(ex), str(ex.data.answer)))


# --- Forces, motion, magnets and light ------------------------------------------------------------------------------

func test_the_stronger_team_wins_the_tug_of_war() -> void:
	var still := 0
	_each("g3s.tug_of_war", func(ex: Dictionary, _l: int) -> void:
		var l := int(ex.data.left)
		var r := int(ex.data.right)
		assert_eq(_right(ex), "The rope stays still" if l == r else ("The rope moves left" if l > r else
			"The rope moves right"), str(ex.prompt)))
	for s in 60:
		var ex := SchoolGen.make("g3s.tug_of_war", s, 2)
		if int(ex.data.left) == int(ex.data.right):
			still += 1
	assert_between(still, 6, 40, "balanced and unbalanced both come up")


func test_the_shortest_roll_has_the_most_friction() -> void:
	var order: Array[String] = ["ice", "wood", "carpet", "grass", "sand"]   # the least friction first
	_each("g3s.surface_test", func(ex: Dictionary, _l: int) -> void:
		var names: Array = ex.data.surfaces
		var cm: Array = ex.data.cm
		for i in names.size() - 1:
			assert_lt(order.find(names[i]), order.find(names[i + 1]), "the surfaces by friction")
			assert_gt(int(cm[i]), int(cm[i + 1]), "more friction, a shorter roll")
		if str(ex.data.ask) == "most":
			assert_eq(_right(ex), str(names[names.size() - 1]))
		elif str(ex.data.ask) == "least":
			assert_eq(_right(ex), str(names[0]))
		else:
			assert_eq(int(str(ex.answer)), int(cm[int(ex.data.a)]) - int(cm[int(ex.data.b)])))


func test_a_repeating_motion_is_predicted() -> void:
	_each("g3s.motion_next", func(ex: Dictionary, _l: int) -> void:
		var period := int(ex.data.period)
		if str(ex.data.ask) == "swings":
			assert_eq(int(str(ex.answer)) * period, int(ex.data.total), str(ex.prompt))
		else:
			assert_eq(int(str(ex.answer)), int(ex.data.start) + 3 * period, str(ex.prompt)))


func test_unlike_poles_attract_and_like_poles_repel() -> void:
	_each("g3s.magnet_poles", func(ex: Dictionary, level: int) -> void:
		var b := str(ex.data.b)
		if ex.data.turned:
			b = "S" if b == "N" else "N"
		assert_eq(bool(ex.data.turned), level == 3)
		assert_eq(_right(ex), "They pull together" if str(ex.data.a) != b else "They push apart", str(ex.prompt)))


func test_magnets_pull_iron_and_steel_only() -> void:
	var magnetic := func(thing: String) -> bool: return thing.contains("iron") or thing.contains("steel")
	_each("g3s.magnetic_or_not", func(ex: Dictionary, _l: int) -> void:
		if str(ex.type) == "truefalse":
			assert_eq(ex.answer, magnetic.call(str(ex.data.things[0])), str(ex.prompt))
			return
		assert_true(magnetic.call(_right(ex)), _right(ex))
		for c: Variant in ex.choices:
			if str(c) != _right(ex):
				assert_false(magnetic.call(str(c)), "%s is not magnetic" % c))


func test_closer_to_the_torch_the_bigger_the_shadow() -> void:
	_each("g3s.shadow_size", func(ex: Dictionary, _l: int) -> void:
		var ds: Array = ex.data.distances
		if str(ex.data.ask) == "change":
			assert_eq(_right(ex), "It gets bigger" if int(ds[1]) < int(ds[0]) else "It gets smaller")
		elif str(ex.data.ask) == "biggest":
			assert_eq(_right(ex), "%d cm from the torch" % int(ds.min()))
			for row: Array in (ex.picture.rows as Array).slice(1):
				var d := int(str(row[0]).split(" ")[0])
				assert_eq(int(str(row[1]).split(" ")[0]), roundi(1000.0 / d), "a 10 cm toy, a wall 100 cm away")
		else:
			var sorted := ds.duplicate()
			sorted.sort()
			assert_eq(_ordered(ex), sorted.map(func(d: int) -> String: return "%d cm from the torch" % d)))


# --- Weather, climate and hazards -----------------------------------------------------------------------------------

func test_the_weather_table_is_read_right() -> void:
	var names := {"Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday", "Thu": "Thursday", "Fri": "Friday"}
	_each("g3s.weather_table", func(ex: Dictionary, _l: int) -> void:
		var temps: Array = ex.data.temps
		var rain: Array = ex.data.rain
		var days: Array = ex.data.days
		for i in days.size():
			assert_eq(ex.picture.rows[i + 1], [days[i], "%d °C" % temps[i], "%d mm" % rain[i]], "the table")
		if str(ex.data.ask) == "warmest":
			assert_eq(_right(ex), names[days[temps.find(temps.max())]])
		elif str(ex.data.ask) == "coldest":
			assert_eq(_right(ex), names[days[temps.find(temps.min())]])
		elif str(ex.data.ask) == "rain":
			var total := 0
			for r: int in rain:
				total += r
			assert_eq(int(str(ex.answer)), total)
		elif str(ex.data.ask) == "dry":
			assert_eq(int(str(ex.answer)), rain.count(0))
		else:
			assert_eq(int(str(ex.answer)), int(temps.max()) - int(temps.min())))


func test_a_climate_from_its_usual_weather() -> void:
	_each("g3s.climate_clue", func(ex: Dictionary, level: int) -> void:
		assert_eq(_right(ex), str(ex.data.climate))
		if level == 1:
			return
		var rain := int(ex.data.rain)
		var expect := "a mild climate"
		if rain >= 1500:
			expect = "a tropical rainforest"
		elif int(ex.data.winter) <= -10:
			expect = "a polar climate"
		elif int(ex.data.summer) >= 30 and rain < 250:
			expect = "a hot desert"
		assert_eq(_right(ex), expect, "%s °C, %s °C, %d mm" % [ex.data.summer, ex.data.winter, rain]))


func test_a_design_that_helps_with_each_hazard() -> void:
	var sure := {"a thunderstorm": "a lightning rod", "a drought": "a reservoir", "a blizzard": "a snow plough"}
	_each("g3s.hazard_design", func(ex: Dictionary, _l: int) -> void:
		var hazard := str(ex.data.hazard)
		var help: Array = G3ScienceGen.HAZARDS[hazard].help
		assert_true(help.has(_right(ex)), str(ex.prompt))
		assert_false(help.has("a sun hat") and hazard != "a heatwave", "a sun hat helps in a heatwave only")
		for c: Variant in ex.choices:
			if str(c) != _right(ex):
				assert_false(help.has(c), "%s does not help with %s" % [c, hazard])
				assert_ne(str(c), str(sure.get(hazard, "")), "the sure design is never a wrong choice"))


# --- Working like a scientist and engineer --------------------------------------------------------------------------

func test_the_right_tool_and_unit() -> void:
	_each("g3s.tool_unit", func(ex: Dictionary, _l: int) -> void:
		var what := str(ex.data.what)
		var kind := "length"
		if what.contains("takes") or what.contains("burns"):
			kind = "time"
		elif what.contains("heavy"):
			kind = "mass"
		elif what.contains("hot") or what.contains("cold") or what.contains("warm"):
			kind = "temperature"
		elif what.contains("how much"):
			kind = "liquid"
		var tools := {"length": "a ruler", "time": "a stopwatch", "mass": "scales", "temperature": "a thermometer",
			"liquid": "a measuring jug"}
		var units := {"length": "centimetres (cm)", "time": "seconds", "mass": "grams (g)",
			"temperature": "degrees Celsius (°C)", "liquid": "millilitres (mL)"}
		assert_eq(_right(ex), str((tools if str(ex.data.ask) == "tool" else units)[kind]), str(ex.prompt)))


func test_the_bridge_that_meets_the_rules() -> void:
	_each("g3s.design_pick", func(ex: Dictionary, _l: int) -> void:
		var designs: Array = ex.data.designs
		var names := ["A", "B", "C"]
		var need := int(ex.data.need)
		var limit := int(ex.data.limit)
		if str(ex.data.ask) == "most":
			var best := 0
			for i in 3:
				if int(designs[i][0]) > int(designs[best][0]):
					best = i
			assert_eq(_right(ex), names[best])
		elif str(ex.data.ask) == "cheapest_enough":
			var pick := -1
			for i in 3:
				if int(designs[i][0]) >= need and (pick < 0 or int(designs[i][1]) < int(designs[pick][1])):
					pick = i
			assert_eq(_right(ex), names[pick])
		else:
			var ok: Array = []
			for i in 3:
				if int(designs[i][0]) >= need and int(designs[i][1]) <= limit:
					ok.append(names[i])
			assert_eq(ok, [_right(ex)], "exactly one bridge meets both rules"))
