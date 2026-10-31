extends GutTest
## Owner #70 and #73, grade 6 health and PE, design and technology, and projects: every "g6w" generator (G6HealthGen)
## makes answers that are right, worked out again here from each exercise's `data` with this test's own facts and rules
## (written apart from the generator's tables): pulses, FITT and the training principles, formations and tactics, relay
## times, jumps and speeds, success rates, 5 A DAY, nutrients, the five ways to wellbeing, box breathing, the circle of
## control, facts about smoking, vaping and alcohol, emergencies, walking times and kit, specifications, interview
## questions, designs from nature, trusses and forces, levers, moments, gears and linkages, sensors and thresholds, food
## zones, bacteria, date labels, prices, materials and density, design movements, market prices, a week's weather and a
## decision matrix.

const SEEDS := 120
const NAMES: Array[String] = ["pulse_rate", "fitt_plan", "fitt_change", "formation", "tactic_pick", "relay_split",
	"jump_measure", "sprint_speed", "success_rate", "five_a_day", "nutrient_job", "wellbeing_way", "box_breath",
	"control_sort", "substance_facts", "emergency_call", "naismith", "kit_check", "spec_check", "interview_q",
	"nature_idea", "truss_count", "struct_force", "lever_class", "lever_balance", "gear_ratio", "linkage_move",
	"sensor_pick", "threshold_check", "food_zone", "microbe_double", "date_check", "unit_price", "portion_cost",
	"material_family", "density_float", "style_sort", "market_price", "weather_week", "decision_matrix"]

# --- This test's own facts ------------------------------------------------------------------------------------------

## FITT: what each "now" changes.
const FITT := {"swims three times a week": "frequency", "cycles on 4 days a week": "frequency",
	"plays tennis twice a week": "frequency", "runs at a faster pace": "intensity", "walks up steep hills": "intensity",
	"skips as fast as possible": "intensity", "runs for 25 minutes": "time", "swims for 30 minutes": "time",
	"plays for an hour": "time", "swims instead": "type", "plays basketball instead": "type",
	"goes to a dance class instead": "type"}
## The training principles, by a word each scenario must have.
const PRINCIPLES := {"harder than": "overload", "each week": "progression", "every week": "progression",
	"own sport": "specificity", "because he plays in goal": "specificity", "stopped": "reversibility",
	"long break": "reversibility", "day off": "rest and recovery", "sleeps well": "rest and recovery"}
## Tactics: a scenario's key words and its idea.
const TACTICS := {"sidelines": "width", "spread out wide": "width", "close behind": "support",
	"can pass to them easily": "support", "past the defenders": "penetration", "between two defenders": "penetration",
	"away from a marker": "movement", "run into a new space": "movement", "quickly closes down": "pressure",
	"closes down the player": "pressure", "stands behind the first": "cover", "ready if the attacker": "cover",
	"close together": "compactness", "shut the space": "compactness", "slows the attacker": "delay",
	"time to get back": "delay", "between them and the goal": "marking", "stays close to one attacker": "marking"}
const ATTACK: Array[String] = ["width", "support", "penetration", "movement"]
## 5 A DAY (the NHS): fruit and vegetables count 1 each; juices and smoothies 1 at most in all; beans and pulses 1 at
## most in all; potatoes are starchy food and count 0; the rest are not fruit or vegetables.
const FRUIT_VEG: Array[String] = ["an apple", "a banana", "a salad", "grapes", "carrot sticks", "a pear", "peas",
	"broccoli", "a tomato", "sweetcorn", "a satsuma", "strawberries"]
const JUICE: Array[String] = ["orange juice", "a smoothie", "apple juice"]
const BEANS: Array[String] = ["baked beans", "lentils", "kidney beans", "chickpeas"]
const NOT_FRUIT: Array[String] = ["toast", "milk", "an egg", "rice", "cheese", "a yoghurt", "pasta", "potatoes",
	"a jacket potato", "chips"]
const NUTRIENTS := {"energy": "carbohydrates", "grow and repair": "protein", "digestion": "fibre", "hydrated": "water",
	"keep you warm": "fats", "bones and teeth": "calcium", "carry oxygen": "iron", "heal": "vitamin C",
	"use calcium": "vitamin D", "bread, rice and pasta": "carbohydrates", "fish, eggs, beans and lentils": "protein",
	"milk, cheese and yoghurt": "calcium", "oranges, strawberries and peppers": "vitamin C",
	"wholegrain cereal": "fibre", "red meat": "iron", "oily fish": "vitamin D"}
const WAYS := {"phone": "connect", "dinner together": "connect", "board game": "connect", "join a club": "connect",
	"walk the dog": "be active", "dance": "be active", "ride your bike": "be active", "play tag": "be active",
	"new song": "keep learning", "new recipe": "keep learning", "juggle": "keep learning", "read about": "keep learning",
	"help a neighbour": "give", "make a card": "give", "say thank you": "give", "help a younger child": "give",
	"listen to the birds": "take notice", "five things you can see": "take notice", "watch the clouds": "take notice",
	"taste your food slowly": "take notice"}
const CAN_CONTROL: Array[String] = ["how hard I try", "asking for help", "my bedtime", "how I speak to others",
	"getting my bag ready", "practising for the test", "what I say to myself", "taking slow breaths"]
const CANNOT_CONTROL: Array[String] = ["the weather", "what others think", "the past", "the test's questions",
	"other people's choices", "the bus being late", "who is in my class", "a match's result"]
## Smoking, vaping and alcohol: true and false statements by a key phrase (NHS, CRUK, UK law).
const TRUE_FACTS: Array[String] = ["tar", "carbon monoxide", "nicotine is addictive", "heart work harder",
	"most lung cancers", "other people's smoke", "slows down the messages", "balance, speech", "usually contain nicotine",
	"not for children", "sell alcohol, cigarettes or nicotine vapes", "buy cigarettes or alcohol for someone",
	"smoke in a car", "most young people"]
const FALSE_FACTS: Array[String] = ["completely harmless", "helps you get fitter", "reactions faster",
	"not addictive", "only harms the person", "legal for a shop", "most young people your age vape"]
const GOOD_NO: Array[String] = ["No thanks, I want to stay healthy.", "No thanks. Let's go and play football instead.",
	"No. I don't want to, and I'm going home now.", "No thanks, it's not for me."]
const SERVICE := {"not breathing": "ambulance", "bleeding badly": "ambulance", "speech is slurred": "ambulance",
	"smoke is pouring": "fire", "bin is on fire": "fire", "car has caught fire": "fire",
	"breaking into": "police", "high on a mountain": "police", "swept out to sea": "coastguard",
	"cut off by the tide": "coastguard"}
const FAST := {"smile": "Face", "arms": "Arms", "words": "Speech"}
const PACK: Array[String] = ["a waterproof jacket", "a map and compass", "a whistle", "water", "a warm layer",
	"a first aid kit", "snacks", "a torch", "sun cream", "a hat"]
const LEAVE: Array[String] = ["a games console", "a heavy book", "flip-flops", "a glass jar", "a pillow",
	"a big box of toys"]
const MEASURABLE: Array[String] = ["at least 500 g", "less than 8 gold", "30 cm by 20 cm", "20° slope", "for 2 hours",
	"aged 6 to 8 must be able"]
const ACCESS := {"bright blue": "Aesthetics", "cost less than": "Cost", "who love dinosaurs": "Customer",
	"recycled": "Environment", "no sharp edges": "Safety", "no bigger than": "Size", "hold 6 pencils": "Function",
	"made from wood": "Materials"}
const BETTER := {"It must be light.": "It must have a mass under 300 g.", "It must be cheap.":
	"It must cost less than 5 gold to make.", "It must be small.": "It must fit in a 20 cm box.",
	"It must be strong.": "It must hold 2 kg without bending.", "It must be quick.":
	"It must be ready in under 5 minutes.", "It must be easy to use.": "A 6-year-old can use it with no help."}
const OPEN_Q: Array[String] = ["What do you find hard about packing your bag?", "How do you use your lunch box?",
	"What would make your mornings easier?", "Tell me about the last time it broke.", "Why do you like that one?",
	"How do you feel when it rains on your walk?"]
const CLOSED_Q: Array[String] = ["Do you like red?", "Is it too heavy?", "Do you have a lunch box?",
	"Would you use it every day?", "Is 10 gold too much?", "Do you walk to school?"]
const NATURE := {"a burdock burr's hooks": "hook-and-loop fasteners", "a kingfisher's beak": "a bullet train's long nose",
	"honeycomb's six-sided cells": "light, strong honeycomb panels", "a lotus leaf's waxy bumps": "self-cleaning paint",
	"a humpback whale's flipper": "quieter wind turbine blades", "a termite mound's air tunnels":
	"a building cooled by chimneys", "a gecko's feet": "grippers that need no glue", "an owl's soft feathers":
	"quieter fans and train parts", "a bird's wings": "aeroplane wings"}
const FORCE := {"a rope holding up a swing": "tension", "a crane's cable lifting a crate": "tension",
	"a guitar string": "tension", "a tow rope pulling a car": "tension", "the legs of a table": "compression",
	"a pillar holding up a roof": "compression", "the bricks at the bottom of a wall": "compression",
	"a diving board with someone on its end": "bending", "a shelf holding books": "bending",
	"a ruler pushed down in the middle": "bending", "wringing out a wet towel": "torsion", "turning a screwdriver":
	"torsion", "twisting open a jar lid": "torsion", "scissors cutting paper": "shear", "a hole punch": "shear",
	"a paper guillotine": "shear"}
const LEVER_TOOLS := {"a seesaw": 1, "scissors": 1, "pliers": 1, "a crowbar lifting a stone": 1, "a wheelbarrow": 2,
	"a nutcracker": 2, "a bottle opener": 2, "tweezers": 3, "a fishing rod": 3, "your forearm lifting a cup": 3,
	"a broom sweeping": 3}
const SENSOR := {"comes on when it gets dark": "light sensor", "turns on at dusk": "light sensor",
	"freezing": "temperature sensor", "room gets hot": "temperature sensor", "soil is dry": "moisture sensor",
	"someone moving": "motion sensor", "baby cries": "sound sensor", "door opens": "push switch",
	"tipped over": "tilt switch", "magnet": "reed switch"}
## Material families (this test's own).
const FAMILY := {"oak": "wood", "beech": "wood", "ash": "wood", "mahogany": "wood", "balsa": "wood", "pine": "wood",
	"spruce": "wood", "cedar": "wood", "larch": "wood", "plywood": "wood", "MDF": "wood", "chipboard": "wood",
	"steel": "metal", "cast iron": "metal", "stainless steel": "metal", "aluminium": "metal", "copper": "metal",
	"brass": "metal", "tin": "metal", "zinc": "metal", "acrylic": "plastic", "polythene": "plastic", "PVC": "plastic",
	"polystyrene": "plastic", "melamine": "plastic", "epoxy resin": "plastic", "urea formaldehyde": "plastic",
	"carbon fibre": "composite", "concrete": "composite", "glass-reinforced plastic": "composite",
	"reinforced concrete": "composite"}
const SUBFAMILY := {"oak": "hardwood", "beech": "hardwood", "ash": "hardwood", "mahogany": "hardwood",
	"balsa": "hardwood", "pine": "softwood", "spruce": "softwood", "cedar": "softwood", "larch": "softwood",
	"plywood": "manufactured board", "MDF": "manufactured board", "chipboard": "manufactured board",
	"steel": "ferrous", "cast iron": "ferrous", "stainless steel": "ferrous", "aluminium": "non-ferrous",
	"copper": "non-ferrous", "brass": "non-ferrous", "tin": "non-ferrous", "zinc": "non-ferrous",
	"acrylic": "thermoplastic", "polythene": "thermoplastic", "PVC": "thermoplastic", "polystyrene": "thermoplastic",
	"melamine": "thermoset", "epoxy resin": "thermoset", "urea formaldehyde": "thermoset"}
const STYLE := {"made by hand": "Arts and Crafts", "leaves, flowers and birds": "Arts and Crafts",
	"natural materials": "Arts and Crafts", "decoration on the surface": "Arts and Crafts",
	"each piece a little different": "Arts and Crafts", "medieval crafts": "Arts and Crafts",
	"made by machines": "Bauhaus", "geometric shapes": "Bauhaus", "tubular steel": "Bauhaus",
	"little or no decoration": "Bauhaus", "form follows function": "Bauhaus", "primary colours": "Bauhaus"}
const YEARS := {"the Bauhaus opened in Weimar": 1919, "the Bauhaus moved to Dessau": 1925, "the Bauhaus closed": 1933,
	"William Morris was born": 1834, "William Morris died": 1896, "Morris and his friends started their firm": 1861,
	"the first Arts and Crafts exhibition": 1888, "Louis Sullivan wrote 'form ever follows function'": 1896}


func _each(gen: String, level: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in SEEDS:
		var ex := SchoolGen.make("g6w." + gen, s, level)
		assert_eq(ExerciseCheck.problem(ex), "", "%s L%d seed %d" % [gen, level, s])
		out.append(ex)
	return out


func _num(ex: Dictionary) -> float:
	return NumberAnswer.value(str(ex.answer))


func _chosen(ex: Dictionary) -> String:
	return ExerciseCheck.item_text(ex.choices[int(ex.answer)])


## The value in `table` whose key `text` contains ("" when none does).
func _by_key(table: Dictionary, text: String) -> String:
	for k: String in table:
		if text.to_lower().contains(k.to_lower()):
			return str(table[k])
	return ""


func _near(a: float, b: float) -> bool:
	return absf(a - b) < 0.0001


func test_every_generator_is_valid_and_varied_at_every_level() -> void:
	var names: Array[String] = []
	for id in SchoolGen.ids():
		if id.begins_with("g6w."):
			names.append(id.substr(4))
	names.sort()
	var want := NAMES.duplicate()
	want.sort()
	assert_eq(names, want, "the %d generators" % NAMES.size())
	for n in names:
		for level in [1, 2, 3]:
			var prompts := {}
			for ex in _each(n, level):
				prompts[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("items", "")) + str(ex.get("choices", ""))
					+ str(ex.get("answer", ""))] = true
				assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)), "%s: its own answer" % ex.id)
				assert_true(ex.has("data") and ex.has("explain"), "%s: its data and worked answer" % ex.id)
				assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: a hint, not the answer" % ex.id)
			assert_gte(prompts.size(), 3 if level == 1 else 6, "g6w.%s L%d varies" % [n, level])


# --- Health and PE ---------------------------------------------------------------------------------------------------

func test_pulses_and_fitt_plans() -> void:
	for level in [1, 2, 3]:
		for ex in _each("pulse_rate", level):
			var d: Dictionary = ex.data
			var bpm := int(d.count) * 60 / int(d.seconds)
			assert_eq(60 % int(d.seconds), 0, "%s: a count that makes a minute" % ex.id)
			assert_eq(_num(ex), float(bpm - int(d.get("rest", 0))), ex.id)
			assert_between(bpm, 55, 190, "%s: a real pulse" % ex.id)
		for ex in _each("fitt_plan", level):
			var d: Dictionary = ex.data
			match level:
				1:
					assert_eq(_num(ex), float(int(d.days) * int(d.minutes)), ex.id)
				2:
					var total := 0
					for s: Array in d.sessions:
						total += int(s[1])
					assert_lt(total, 420, ex.id)
					assert_eq(_num(ex), float(7 * 60 - total), "%s: 60 minutes a day on average" % ex.id)
				3:
					assert_eq(_num(ex), float(int(d.start) + int(d.add) * (int(d.week) - 1)), ex.id)


func test_fitt_changes_and_principles() -> void:
	for ex in _each("fitt_change", 1):
		assert_eq(_chosen(ex), _by_key(FITT, str(ex.data.after)), ex.id)
	for ex in _each("fitt_change", 2):
		assert_eq(_chosen(ex), _by_key(PRINCIPLES, str(ex.prompt)), ex.id)
	for ex in _each("fitt_change", 3):
		assert_eq(str(FITT.get(_chosen(ex), "")), str(ex.data.part), ex.id)
		var parts := {}
		for c: Variant in ex.choices:
			parts[str(FITT.get(ExerciseCheck.item_text(c), "?"))] = true
		assert_eq(parts.size(), (ex.choices as Array).size(), "%s: one change of each part" % ex.id)


func test_formations_add_up_to_the_outfield_players() -> void:
	for level in [1, 2, 3]:
		for ex in _each("formation", level):
			var lines: Array = ex.data.lines
			var sum := 0
			for n: Variant in lines:
				sum += int(n)
			assert_eq(sum, int(ex.data.outfield), "%s: every outfield player in a line" % ex.id)
			assert_true(int(ex.data.outfield) in [10, 6, 4], "%s: 11-, 7- or 5-a-side" % ex.id)
			if str(ex.type) == "number":
				assert_eq(_num(ex), float(lines[int(ex.data.ask)]), ex.id)
			else:
				assert_eq(_chosen(ex), "-".join(lines.map(func(n: Variant) -> String: return str(int(n)))), ex.id)
				var per_x := {}   # the picture's players, counted line by line (a goalkeeper at the back)
				for p: Array in ex.picture.players:
					per_x[float(p[0])] = int(per_x.get(float(p[0]), 0)) + 1
				var xs := per_x.keys()
				xs.sort()
				var counts: Array = []
				for x: Variant in xs:
					counts.append(per_x[x])
				assert_eq(counts, [1] + lines, "%s: the picture shows the formation" % ex.id)


func test_tactics_are_their_ideas() -> void:
	for level in [1, 2, 3]:
		for ex in _each("tactic_pick", level):
			var idea := _by_key(TACTICS, str(ex.prompt))
			assert_ne(idea, "", "%s: a scenario this test knows" % ex.id)
			if level == 1:
				assert_eq(_chosen(ex), "attacking" if ATTACK.has(idea) else "defending", ex.id)
			else:
				assert_eq(_chosen(ex), idea, ex.id)


func test_relays_jumps_and_speeds() -> void:
	for level in [1, 2, 3]:
		for ex in _each("relay_split", level):
			var d: Dictionary = ex.data
			var legs: Array = d.legs
			var sum := 0
			for t: Variant in legs:
				sum += int(t)
			match level:
				1:
					assert_true(_near(_num(ex), sum / 10.0), ex.id)
				2:
					assert_true(_near(_num(ex), int(legs[int(d.missing)]) / 10.0), ex.id)
					assert_true(str(ex.prompt).contains(_tenths(sum)), "%s: the total is given" % ex.id)
				3:
					assert_true(_near(_num(ex), (sum - 3 * int(d.save)) / 10.0), ex.id)
			for t: Variant in legs:
				assert_between(int(t), 120, 200, "%s: a 100 m leg of 12-20 s" % ex.id)
		for ex in _each("jump_measure", level):
			var d: Dictionary = ex.data
			match level:
				1:
					var m: Array = d.marks
					assert_true(_near(_num(ex), minf(float(m[0]), float(m[1]))), "%s: the nearest mark" % ex.id)
					assert_eq(str(ex.picture.kind), "track_field", ex.id)
				2:
					var p: Array = d.phases
					assert_true(_near(_num(ex), float(p[0]) + float(p[1]) + float(p[2])), ex.id)
				3:
					var best := 0.0
					for j: Variant in d.jumps:
						best = maxf(best, float(j))   # a no-jump is -1
					assert_true((d.jumps as Array).has(-1), "%s: one no-jump" % ex.id)
					assert_true(_near(_num(ex), best), ex.id)
		for ex in _each("sprint_speed", level):
			var d: Dictionary = ex.data
			match level:
				1:
					assert_true(_near(_num(ex), float(d.distance) / float(d.time)), ex.id)
				2:
					var best := ""
					var top := 0.0
					for r: Array in d.runners:
						var v := float(r[1]) / float(r[2])
						assert_ne(v, top, "%s: no tie" % ex.id)
						if v > top:
							top = v
							best = str(r[0])
					assert_eq(_chosen(ex), best, ex.id)
				3:
					assert_true(_near(_num(ex), float(d.distance) / float(d.speed)), ex.id)


func _tenths(t: int) -> String:
	return "%d.%d" % [t / 10, t % 10]


func test_success_rates() -> void:
	for level in [1, 2, 3]:
		for ex in _each("success_rate", level):
			var d: Dictionary = ex.data
			if level < 3:
				assert_true(_near(_num(ex), 100.0 * int(d.made) / int(d.tries)), ex.id)
			else:
				var worst := ""
				var low := 101.0
				for r: Array in d.rows:
					var p := 100.0 * int(r[1]) / int(r[2])
					if p < low:
						low = p
						worst = str(r[0])
				assert_eq(_chosen(ex), worst, ex.id)
				assert_eq(str(ex.picture.kind), "table", ex.id)


func test_five_a_day_counts_by_the_nhs_rules() -> void:
	for level in [1, 2, 3]:
		for ex in _each("five_a_day", level):
			var n := 0
			var juice := false
			var beans := false
			for f: String in ex.data.foods:
				if FRUIT_VEG.has(f):
					n += 1
				elif JUICE.has(f):
					juice = true
				elif BEANS.has(f):
					beans = true
				else:
					assert_true(NOT_FRUIT.has(f), "%s: %s is a food this test knows" % [ex.id, f])
			n += (1 if juice else 0) + (1 if beans else 0)
			assert_eq(_num(ex), float(n), ex.id)


func test_nutrients_and_the_ways_to_wellbeing() -> void:
	for level in [1, 2, 3]:
		for ex in _each("nutrient_job", level):
			assert_eq(_chosen(ex), _by_key(NUTRIENTS, str(ex.prompt)), ex.id)
		for ex in _each("wellbeing_way", level):
			if str(ex.type) == "sort":
				for i in (ex.items as Array).size():
					assert_eq(str(ex.groups[int(ex.answer[i])]), _by_key(WAYS, str(ex.items[i])), ex.id)
			else:
				assert_eq(_chosen(ex), _by_key(WAYS, str(ex.prompt)), ex.id)


func test_box_breathing_and_the_circle_of_control() -> void:
	for level in [1, 2, 3]:
		for ex in _each("box_breath", level):
			var d: Dictionary = ex.data
			match level:
				1:
					assert_eq(_num(ex), float(4 * int(d.count)), ex.id)
				2:
					assert_eq(_num(ex), float(4 * int(d.count) * int(d.boxes)), ex.id)
				3:
					var per := int(d["in"]) + int(d.out)
					assert_eq(60 * int(d.minutes) % per, 0, "%s: whole breaths" % ex.id)
					assert_eq(_num(ex), float(60 * int(d.minutes) / per), ex.id)
					assert_gt(int(d.out), int(d["in"]), "%s: a longer breath out calms" % ex.id)
		for ex in _each("control_sort", level):
			for i in (ex.items as Array).size():
				var item := str(ex.items[i])
				assert_true(CAN_CONTROL.has(item) or CANNOT_CONTROL.has(item), "%s: %s" % [ex.id, item])
				assert_eq(int(ex.answer[i]), 0 if CAN_CONTROL.has(item) else 1, "%s: %s" % [ex.id, item])


func test_substance_facts_are_true_and_saying_no_is_clear() -> void:
	for level in [1, 2, 3]:
		for ex in _each("substance_facts", level):
			if str(ex.type) == "truefalse":
				var t := str(ex.prompt)
				var is_true := false
				var known := false
				for k in TRUE_FACTS:
					if t.to_lower().contains(k):
						is_true = true
						known = true
				for k in FALSE_FACTS:
					if t.to_lower().contains(k):
						is_true = false
						known = true
				assert_true(known, "%s: a fact this test knows: %s" % [ex.id, t])
				assert_eq(ex.answer, is_true, "%s: %s" % [ex.id, t])
			else:
				assert_true(GOOD_NO.has(_chosen(ex)), "%s: a clear no" % ex.id)
				for c: Variant in ex.choices:
					if ExerciseCheck.item_text(c) != _chosen(ex):
						assert_false(GOOD_NO.has(ExerciseCheck.item_text(c)), "%s: one clear no" % ex.id)


func test_emergencies() -> void:
	for ex in _each("emergency_call", 1):
		assert_eq(_chosen(ex), _by_key(SERVICE, str(ex.prompt)), ex.id)
	for ex in _each("emergency_call", 2):
		assert_eq(_chosen(ex), _by_key(FAST, str(ex.data.sign)), ex.id)
	for ex in _each("emergency_call", 3):
		var d: Dictionary = ex.data
		if str(d.kind) == "burn":
			var end := int(d.start) + 20   # cool a burn for 20 minutes (NHS)
			assert_eq(_chosen(ex), "%d:%02d pm" % [end / 60, end % 60], ex.id)
		else:
			assert_between(int(d.per_minute), 100, 120, "%s: CPR at 100-120 a minute" % ex.id)
			assert_eq(_num(ex), float(int(d.per_minute) * int(d.seconds) / 60), ex.id)


func test_walking_times_and_kit() -> void:
	for level in [1, 2, 3]:
		for ex in _each("naismith", level):
			var d: Dictionary = ex.data
			match level:
				1:
					assert_true(_near(_num(ex), float(d.km) / float(d.speed) * 60.0), ex.id)
				2:
					assert_true(_near(_num(ex), float(d.km) * 12.0 + float(d.climb) / 10.0), "%s: Naismith" % ex.id)
				3:
					var total := 0.0
					for leg: Array in d.legs:
						total += float(leg[0]) * 12.0 + float(leg[1]) / 10.0
					assert_true(_near(_num(ex), total), ex.id)
		for ex in _each("kit_check", level):
			for i in (ex.items as Array).size():
				var item := str(ex.items[i])
				assert_true(PACK.has(item) or LEAVE.has(item), "%s: %s" % [ex.id, item])
				assert_eq(int(ex.answer[i]), 0 if PACK.has(item) else 1, "%s: %s" % [ex.id, item])


# --- Design and technology ---------------------------------------------------------------------------------------

func test_specifications_and_interviews() -> void:
	for ex in _each("spec_check", 1):
		for c: Variant in ex.choices:
			var t := ExerciseCheck.item_text(c)
			assert_eq(t == _chosen(ex), _measurable(t), "%s: only the measurable one is right: %s" % [ex.id, t])
	for ex in _each("spec_check", 2):
		assert_eq(_chosen(ex), _by_key(ACCESS, str(ex.prompt)), ex.id)
	for ex in _each("spec_check", 3):
		assert_eq(_chosen(ex), str(BETTER.get(str(ex.data.vague), "")), ex.id)
	for level in [1, 2, 3]:
		for ex in _each("interview_q", level):
			if str(ex.type) == "sort":
				for i in (ex.items as Array).size():
					assert_eq(int(ex.answer[i]), 0 if OPEN_Q.has(str(ex.items[i])) else 1, ex.id)
					assert_true(OPEN_Q.has(str(ex.items[i])) or CLOSED_Q.has(str(ex.items[i])), ex.id)
			elif level == 1:
				assert_eq(_chosen(ex), "open" if OPEN_Q.has(str(ex.data.question)) else "closed", ex.id)
			else:
				assert_true(OPEN_Q.has(_chosen(ex)), "%s: the open question" % ex.id)
				for c: Variant in ex.choices:
					if ExerciseCheck.item_text(c) != _chosen(ex):
						assert_true(CLOSED_Q.has(ExerciseCheck.item_text(c)), ex.id)


func _measurable(t: String) -> bool:
	for k in MEASURABLE:
		if t.contains(k):
			return true
	return false


func test_designs_from_nature() -> void:
	for ex in _each("nature_idea", 1):
		assert_eq(_chosen(ex), str(NATURE[str(ex.data.nature)]), ex.id)
	for ex in _each("nature_idea", 2):
		assert_eq(str(NATURE.get(_chosen(ex), "")), str(ex.data.design), ex.id)
	for ex in _each("nature_idea", 3):
		for i in (ex.items as Array).size():
			assert_eq(str(ex.matches[int(ex.answer[i])]), str(NATURE[str(ex.items[i])]), ex.id)


func test_trusses_and_forces() -> void:
	for level in [1, 2, 3]:
		for ex in _each("truss_count", level):
			var d: Dictionary = ex.data
			var t := 2 * int(d.panels) - 1
			if str(d.ask) == "triangles":
				assert_eq(_num(ex), float(t), ex.id)
			else:
				assert_eq(_num(ex), float(2 * t + 1), "%s: bars = 2 × triangles + 1" % ex.id)
			if ex.has("picture"):
				assert_eq(int(ex.picture.panels), int(d.panels), ex.id)
		for ex in _each("struct_force", level):
			var want := str(FORCE[str(ex.data.thing)])
			if level < 3:
				assert_eq(_chosen(ex), want, ex.id)
			else:
				var pic: Dictionary = ex.choices[int(ex.answer)].picture
				assert_eq(str(pic.forces[0]), want, ex.id)


func _lever_class(pivot: int, load: int, effort: int) -> int:
	if (pivot - load) * (pivot - effort) < 0:
		return 1
	return 2 if absi(load - pivot) < absi(effort - pivot) else 3


func test_levers_moments_gears_and_linkages() -> void:
	for level in [1, 2, 3]:
		for ex in _each("lever_class", level):
			var d: Dictionary = ex.data
			var want := int(LEVER_TOOLS[str(d.tool)]) if level == 3 else _lever_class(int(d.pivot), int(d.load), int(d.effort))
			assert_eq(_chosen(ex), "class %d" % want, ex.id)
		for ex in _each("lever_balance", level):
			var d: Dictionary = ex.data
			var ans := _num(ex)
			if str(d.ask) == "effort":
				assert_true(_near(ans * int(d.de), float(int(d.load) * int(d.dl))), "%s: moments balance" % ex.id)
			else:
				assert_true(_near(float(d.effort) * ans, float(int(d.load) * int(d.dl))), "%s: moments balance" % ex.id)
			var pic: Dictionary = ex.picture
			assert_eq(absi(int(pic.load) - int(pic.pivot)), int(d.dl), "%s: the load's distance" % ex.id)
		for ex in _each("gear_ratio", level):
			var d: Dictionary = ex.data
			match level:
				1:
					assert_true(_near(_num(ex), float(d.driven) / float(d.driver)), ex.id)
				2:
					assert_true(_near(_num(ex), float(d.rpm) * float(d.driver) / float(d.driven)), ex.id)
				3:
					assert_true(_near(_num(ex), float(d.b) / float(d.a) * float(d.d) / float(d.c)), ex.id)
		for ex in _each("linkage_move", level):
			var d: Dictionary = ex.data
			var want := ""
			match str(d.type):
				"reverse":
					want = "left" if str(d.move) == "right" else "right"
				"parallel":
					want = str(d.move)
				"bell_crank":
					want = "down" if str(d.move) == "right" else "up"
			assert_eq(_chosen(ex), want, ex.id)
			assert_false(ex.picture.get("output", true), "%s: the output's arrow is hidden" % ex.id)


func test_sensors_and_thresholds() -> void:
	for level in [1, 2, 3]:
		for ex in _each("sensor_pick", level):
			assert_eq(_chosen(ex), _by_key(SENSOR, str(ex.data.product)), ex.id)
		for ex in _each("threshold_check", level):
			var d: Dictionary = ex.data
			var r: Array = d.readings
			var on: Array = []
			for v: Variant in r:
				on.append(float(v) < float(d.threshold) if bool(d.below) else float(v) > float(d.threshold))
			match level:
				1:
					assert_eq(_chosen(ex), str(d.labels[on.find(true)]), ex.id)
				2:
					assert_eq(_num(ex), float(on.count(true)), ex.id)
				3:
					var t := float(ExerciseCheck.item_text(ex.choices[int(ex.answer)]))
					var i := int(d.at)
					assert_true(float(r[i]) < t and float(r[i - 1]) >= t, "%s: on from %s" % [ex.id, d.labels[i]])
					for c: Variant in ex.choices:
						var o := float(ExerciseCheck.item_text(c))
						if o != t:
							assert_false(float(r[i]) < o and float(r[i - 1]) >= o, "%s: %s also works" % [ex.id, o])


# --- Food ----------------------------------------------------------------------------------------------------------

func _zone(t: int) -> String:
	if t <= -18:
		return "freezer"
	if t >= 0 and t <= 5:
		return "fridge"
	if t > 5 and t < 63:
		return "danger zone"
	return "hot" if t >= 63 else ""


func test_food_zones_bacteria_and_dates() -> void:
	for level in [1, 2, 3]:
		for ex in _each("food_zone", level):
			var t := int(ex.data.t)
			if str(ex.type) == "truefalse":
				assert_eq(ex.answer, t >= 75, "%s: cooked to 75 °C in the middle" % ex.id)
			else:
				assert_eq(_chosen(ex), _zone(t), ex.id)
				assert_ne(_zone(t), "", "%s: a temperature in a zone" % ex.id)
		for ex in _each("microbe_double", level):
			var d: Dictionary = ex.data
			if str(d.ask) == "count":
				assert_eq(_num(ex), float(int(d.start) * int(pow(2, int(d.minutes) / 20))), ex.id)
				assert_eq(int(d.minutes) % 20, 0, ex.id)
			else:
				assert_eq(int(d.target), int(d.start) * int(pow(2, int(_num(ex)) / 20)), "%s: the time to reach it" % ex.id)
		for ex in _each("date_check", level):
			var d: Dictionary = ex.data
			if str(ex.type) == "truefalse":
				var safe := str(d.label) == "best before" or int(d.today) <= int(d.date)
				assert_eq(ex.answer, safe if str(d.claim) == "safe" else not safe, "%s: %s" % [ex.id, ex.prompt])
			else:
				var item: Array = d.items[int(ex.answer)]
				assert_eq(str(item[1]), "use by", "%s: throw away a use-by food" % ex.id)
				assert_lt(int(item[2]), int(d.today), "%s: past its use-by date" % ex.id)


func test_prices_and_portions() -> void:
	for level in [1, 2, 3]:
		for ex in _each("unit_price", level):
			var d: Dictionary = ex.data
			if level == 1:
				assert_true(_near(_num(ex), float(d.price) / 100.0 * 100.0 / float(d.grams)), ex.id)
			else:
				var best := ""
				var low := INF
				for p: Array in d.packs:
					var per := float(p[2]) / float(p[1])
					assert_ne(per, low, "%s: no tie" % ex.id)
					if per < low:
						low = per
						best = str(p[0])
				assert_eq(_chosen(ex), best, ex.id)
		for ex in _each("portion_cost", level):
			var d: Dictionary = ex.data
			match level:
				1:
					assert_true(_near(_num(ex), float(d.total) / 100.0 / int(d.portions)), ex.id)
				2:
					var sum := 0
					for c: Variant in d.costs:
						sum += int(c)
					assert_true(_near(_num(ex), sum / 100.0 / int(d.portions)), ex.id)
				3:
					assert_true(_near(_num(ex), (int(d.budget) - int(d.per) * int(d.people)) / 100.0), ex.id)


func test_materials_and_density() -> void:
	for ex in _each("material_family", 1):
		assert_eq(_chosen(ex), str(FAMILY[str(ex.data.material)]), ex.id)
	for ex in _each("material_family", 2):
		assert_eq(_chosen(ex), str(SUBFAMILY[str(ex.data.material)]), ex.id)
	for ex in _each("material_family", 3):
		for i in (ex.items as Array).size():
			assert_eq(str(ex.groups[int(ex.answer[i])]), str(SUBFAMILY[str(ex.items[i])]), ex.id)
	for ex in _each("density_float", 1):
		assert_eq(_num(ex), float(int(ex.data.l) * int(ex.data.w) * int(ex.data.h)), ex.id)
	for ex in _each("density_float", 2):
		assert_true(_near(_num(ex), float(ex.data.mass) / float(ex.data.volume)), ex.id)
	for ex in _each("density_float", 3):
		var floats := float(ex.data.mass) < float(ex.data.volume)   # water: 1 g for each cm³
		assert_eq(_chosen(ex), "it floats" if floats else "it sinks", ex.id)


func test_design_movements() -> void:
	for level in [1, 2]:
		for ex in _each("style_sort", level):
			for i in (ex.items as Array).size():
				assert_eq(str(ex.groups[int(ex.answer[i])]), _by_key(STYLE, str(ex.items[i])), ex.id)
	for ex in _each("style_sort", 3):
		var a := int(YEARS[str(ex.data.first)])
		var b := int(YEARS[str(ex.data.then)])
		assert_gt(b, a, ex.id)
		assert_eq(_num(ex), float(b - a), ex.id)


# --- Projects ------------------------------------------------------------------------------------------------------

func test_market_weather_and_decisions() -> void:
	for level in [1, 2, 3]:
		for ex in _each("market_price", level):
			var d: Dictionary = ex.data
			match level:
				1:
					assert_true(_near(_num(ex), float(d.cost) / int(d.n) * int(d.m)), ex.id)
				2:
					assert_true(_near(_num(ex), float(d.price) * int(d.percent) / 100.0), ex.id)
				3:
					assert_true(_near(_num(ex), float(d.total) * int(d.b) / (int(d.a) + int(d.b))), ex.id)
		for ex in _each("weather_week", level):
			var d: Dictionary = ex.data
			match level:
				1:
					var sum := 0
					for v: Variant in d.rain:
						sum += int(v)
					assert_eq(_num(ex), float(sum), ex.id)
				2:
					var sum := 0
					for v: Variant in d.temps:
						sum += int(v)
					assert_true(_near(_num(ex), sum / float((d.temps as Array).size())), ex.id)
					assert_eq(str(ex.picture.kind), "sheet", ex.id)
				3:
					assert_eq(_num(ex), float(int(d.high) - int(d.low)), ex.id)
		for ex in _each("decision_matrix", level):
			var d: Dictionary = ex.data
			var weights: Array = d.get("weights", [])
			var best := ""
			var top := -1
			for row: Array in d.rows:
				var total := 0
				for i in range(1, row.size()):
					total += int(row[i]) * (int(weights[i - 1]) if not weights.is_empty() else 1)
				assert_ne(total, top, "%s: no tie" % ex.id)
				if total > top:
					top = total
					best = str(row[0])
			if str(ex.type) == "number":
				var row: Array = d.rows[int(d.ask)]
				var total := 0
				for i in range(1, row.size()):
					total += int(row[i])
				assert_eq(_num(ex), float(total), ex.id)
			else:
				assert_eq(_chosen(ex), best, ex.id)
