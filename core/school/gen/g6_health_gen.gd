class_name G6HealthGen
extends RefCounted
## Owner #70 and #73 (research §6.6): grade 6 health and PE, design and technology, and projects generators: pulses,
## FITT and the training principles, formations and tactics, relay legs, jumps and speeds, success rates, 5 A DAY,
## nutrients, the five ways to wellbeing, box breathing, the circle of control, facts about smoking, vaping and alcohol,
## emergencies, walking times by Naismith's rule and a walker's kit, specifications and ACCESS FM, interview questions,
## designs from nature, trusses and the forces in structures, lever classes and moments, gear ratios and linkages,
## sensors and thresholds, food zones, bacteria that double, date labels, prices per 100 g and per portion, material
## families and density, design movements, a market's prices, a week's weather and a decision matrix. SchoolGen
## "g6w.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each
## with a hint (a strategy), a worked answer and `data` (its inputs, for tests/unit/test_g6_health_gen.gd). Helpers
## start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi"]

# --- Banks (checked by the test with its own copies) ----------------------------------------------------------------

const FITT_CHANGES: Array = [
	["frequency", "swims twice a week", "swims three times a week"],
	["frequency", "cycles on 2 days a week", "cycles on 4 days a week"],
	["frequency", "plays tennis once a week", "plays tennis twice a week"],
	["intensity", "jogs at an easy pace", "runs at a faster pace"],
	["intensity", "walks on flat paths", "walks up steep hills"],
	["intensity", "skips slowly", "skips as fast as possible"],
	["time", "runs for 15 minutes", "runs for 25 minutes"],
	["time", "swims for 20 minutes", "swims for 30 minutes"],
	["time", "plays for half an hour", "plays for an hour"],
	["type", "runs", "swims instead"],
	["type", "cycles", "plays basketball instead"],
	["type", "jogs", "goes to a dance class instead"],
]
const FITT_WORDS := {"frequency": "how often", "intensity": "how hard", "time": "how long", "type": "which activity"}
const PRINCIPLE_CASES: Array = [
	["overload", "Muscles only get stronger when they work harder than they are used to."],
	["overload", "To get fitter, Mimi makes her heart and lungs work harder than usual."],
	["progression", "Tilly adds one more minute to her run each week."],
	["progression", "Zara adds 2 more press-ups every week, step by step."],
	["specificity", "Swimmers train mostly in the pool: training should match your own sport."],
	["specificity", "Bram practises diving saves because he plays in goal."],
	["reversibility", "Mimi stopped running for two months, and her stamina went down."],
	["reversibility", "After a long break from football, Bram got out of breath more quickly."],
	["rest and recovery", "Zara takes a day off between hard training days, so her muscles can repair."],
	["rest and recovery", "Tilly sleeps well after training, so her body can recover."],
]
const PRINCIPLES: Array[String] = ["overload", "progression", "specificity", "reversibility", "rest and recovery"]
## Formations by outfield players (a goalkeeper as well): defenders, midfielders, forwards.
const FORMATIONS := {10: [[4, 4, 2], [4, 3, 3], [3, 5, 2], [5, 3, 2], [4, 5, 1], [3, 4, 3]],
	6: [[2, 3, 1], [3, 2, 1], [2, 2, 2], [3, 1, 2]], 4: [[2, 1, 1], [1, 2, 1], [1, 1, 2]]}
const TEAM_SIZE := {10: 11, 6: 7, 4: 5}
const LINE_NAMES: Array[String] = ["defenders", "midfielders", "forwards"]
const TACTIC_CASES: Array = [
	["width", "Two players stay out near the sidelines, so the other team has to spread out."],
	["width", "The players spread out wide to make space in the middle."],
	["support", "A teammate stays close behind the player with the ball, ready for a pass back."],
	["support", "Teammates move to where the ball carrier can pass to them easily."],
	["penetration", "A player dribbles forward past the defenders towards goal."],
	["penetration", "A pass goes forward through the gap between two defenders."],
	["movement", "A player keeps moving to get away from a marker."],
	["movement", "After a pass, run into a new space to get the ball back."],
	["pressure", "The nearest defender quickly closes down the player with the ball."],
	["cover", "A second defender stands behind the first, ready if the attacker gets past."],
	["compactness", "All the defenders move close together to shut the space in front of goal."],
	["delay", "A defender slows the attacker down, so teammates have time to get back."],
	["marking", "Each defender stays close to one attacker, between them and the goal."],
]
const ATTACKING: Array[String] = ["width", "support", "penetration", "movement"]
const DEFENDING: Array[String] = ["pressure", "cover", "compactness", "delay", "marking"]
const FRUIT_VEG: Array[String] = ["an apple", "a banana", "a salad", "grapes", "carrot sticks", "a pear", "peas",
	"broccoli", "a tomato", "sweetcorn", "a satsuma", "strawberries"]
const JUICES: Array[String] = ["orange juice", "a smoothie", "apple juice"]
const BEANS: Array[String] = ["baked beans", "lentils", "kidney beans", "chickpeas"]
const OTHER_FOODS: Array[String] = ["toast", "milk", "an egg", "rice", "cheese", "a yoghurt", "pasta"]
const POTATOES: Array[String] = ["potatoes", "a jacket potato", "chips"]
const NUTRIENT_JOBS: Array = [   # [level, nutrient, what it does or where it is]
	[1, "carbohydrates", "gives you most of your energy"], [1, "protein", "helps you grow and repair your body"],
	[1, "fibre", "keeps your digestion working well"], [1, "water", "keeps you hydrated and cool"],
	[1, "fats", "helps keep you warm and carries some vitamins"], [2, "calcium", "builds strong bones and teeth"],
	[2, "iron", "helps your blood carry oxygen"], [2, "vitamin C", "helps you heal and fight infections"],
	[2, "vitamin D", "helps your body use calcium"],
	[3, "carbohydrates", "bread, rice and pasta"], [3, "protein", "fish, eggs, beans and lentils"],
	[3, "calcium", "milk, cheese and yoghurt"], [3, "vitamin C", "oranges, strawberries and peppers"],
	[3, "fibre", "wholegrain cereal, fruit and vegetables"], [3, "iron", "red meat, beans and dark green leaves"],
	[3, "vitamin D", "oily fish and eggs"],
]
const NUTRIENT_WHY := {
	"carbohydrates": "Carbohydrates, in bread, rice, pasta and potatoes, give you most of your energy.",
	"protein": "Protein, in fish, eggs, meat, beans and lentils, helps you grow and repair your body.",
	"fibre": "Fibre, in wholegrain foods, fruit and vegetables, keeps your digestion working well.",
	"water": "Water keeps you hydrated, carries nutrients round the body and cools you.",
	"fats": "Fats, a little each day, help keep you warm and carry vitamins A, D, E and K.",
	"calcium": "Calcium, in milk, cheese and yoghurt, builds strong bones and teeth.",
	"iron": "Iron, in red meat, beans and dark green leaves, helps your blood carry oxygen.",
	"vitamin C": "Vitamin C, in oranges, strawberries and peppers, helps you heal and fight infections.",
	"vitamin D": "Vitamin D, from sunlight on skin, oily fish and eggs, helps your body use calcium.",
}
const NUTRIENTS: Array[String] = ["carbohydrates", "protein", "fibre", "water", "fats", "calcium", "iron", "vitamin C",
	"vitamin D"]
const WAYS: Array[String] = ["connect", "be active", "keep learning", "give", "take notice"]
const WAY_ACTS := {
	"connect": ["phone your grandad for a chat", "eat dinner together and talk", "play a board game with friends",
		"join a club and meet new people"],
	"be active": ["walk the dog after school", "dance to music in your room", "ride your bike to the park",
		"play tag at break"],
	"keep learning": ["learn a new song", "try a new recipe", "learn to juggle", "read about volcanoes"],
	"give": ["help a neighbour carry shopping", "make a card for a friend who is ill", "say thank you to the dinner staff",
		"help a younger child with reading"],
	"take notice": ["listen to the birds for a minute", "notice five things you can see", "watch the clouds drift by",
		"taste your food slowly"],
}
const CAN_CONTROL: Array[String] = ["how hard I try", "asking for help", "my bedtime", "how I speak to others",
	"getting my bag ready", "practising for the test", "what I say to myself", "taking slow breaths"]
const CANNOT_CONTROL: Array[String] = ["the weather", "what others think", "the past", "the test's questions",
	"other people's choices", "the bus being late", "who is in my class", "a match's result"]
## Statements about smoking, vaping and alcohol: [level, true or false, the statement] (NHS, Cancer Research UK, UK law).
const SUBSTANCE_FACTS: Array = [
	[1, true, "Tobacco smoke contains tar, a sticky substance that coats the lungs."],
	[1, true, "Smoking makes the heart work harder."],
	[1, true, "Breathing in other people's smoke can harm your health."],
	[1, true, "Nicotine is addictive, so smoking or vaping is very hard to stop."],
	[1, false, "Nicotine is not addictive."],
	[1, false, "Smoking helps you get fitter."],
	[1, false, "Vaping is completely harmless."],
	[2, true, "Carbon monoxide in smoke takes the place of oxygen in the blood."],
	[2, true, "Most lung cancers are caused by smoking."],
	[2, true, "Alcohol slows down the messages between the brain and the body."],
	[2, true, "Alcohol affects balance, speech and judgement."],
	[2, true, "Vapes usually contain nicotine."],
	[2, false, "Alcohol makes your reactions faster."],
	[2, false, "Cigarette smoke only harms the person smoking."],
	[3, true, "In the UK, it is against the law to sell alcohol, cigarettes or nicotine vapes to anyone under 18."],
	[3, true, "In the UK, it is against the law for an adult to buy cigarettes or alcohol for someone under 18."],
	[3, true, "In England and Wales, it is against the law to smoke in a car with anyone under 18 in it."],
	[3, true, "Most young people do not smoke, vape or drink alcohol."],
	[3, true, "Vapes are not for children and young people."],
	[3, false, "It is legal for a shop to sell nicotine vapes to a 14-year-old."],
	[3, false, "Most young people your age vape."],
]
const GOOD_NO: Array[String] = ["No thanks, I want to stay healthy.", "No thanks. Let's go and play football instead.",
	"No. I don't want to, and I'm going home now.", "No thanks, it's not for me."]
const WEAK_NO: Array[String] = ["Maybe later.", "I'll think about it.", "Only if nobody sees.", "Fine, if you all are."]
const OFFERS: Array[String] = ["a vape", "a cigarette", "a can of beer"]
const PRESSURE: Array[String] = ["Everyone does it.", "Go on, don't be boring.", "Nobody will find out.",
	"Older kids all do it."]
const EMERGENCIES: Array = [
	["ambulance", "Someone has collapsed and is not breathing normally."],
	["ambulance", "A cyclist has fallen and is bleeding badly."],
	["ambulance", "A man's face droops and his speech is slurred."],
	["fire", "Thick smoke is pouring out of a kitchen window."],
	["fire", "A big bin is on fire next to a school."],
	["fire", "A car has caught fire in a car park."],
	["police", "Someone is breaking into a neighbour's house."],
	["police", "A walker is lost and hurt high on a mountain."],
	["coastguard", "A swimmer is being swept out to sea."],
	["coastguard", "Two people are cut off by the tide below a cliff."],
]
const SERVICES: Array[String] = ["ambulance", "fire", "police", "coastguard"]
const FAST_SIGNS: Array = [
	["Face", "Their smile is lopsided: one side of the face has dropped."],
	["Face", "One side of the mouth droops when they try to smile."],
	["Arms", "They cannot lift both arms and keep them up."],
	["Arms", "One of their arms drifts down when they hold both arms out."],
	["Speech", "Their words are slurred or muddled."],
	["Speech", "Their words come out jumbled, or they cannot find the words."],
]
const KIT_PACK: Array[String] = ["a waterproof jacket", "a map and compass", "a whistle", "water", "a warm layer",
	"a first aid kit", "snacks", "a torch", "sun cream", "a hat"]
const KIT_LEAVE: Array[String] = ["a games console", "a heavy book", "flip-flops", "a glass jar", "a pillow",
	"a big box of toys"]
const SPEC_MEASURABLE: Array[String] = ["It must hold at least 500 g of books.", "It must cost less than 8 gold to make.",
	"It must fit in a box 30 cm by 20 cm.", "It must stay upright on a 20° slope.",
	"It must keep a drink warm for 2 hours.", "Children aged 6 to 8 must be able to open it."]
const SPEC_VAGUE: Array[String] = ["It must look nice.", "It must be good.", "It should be quite cheap.",
	"It must be really strong.", "It should be fun.", "It must not be too big."]
const ACCESS_POINTS: Array = [
	["Aesthetics", "It should be bright blue with rounded corners."],
	["Cost", "It must cost less than 8 gold to make."],
	["Customer", "It is for children aged 6 to 8 who love dinosaurs."],
	["Environment", "At least half of it must be recycled."],
	["Safety", "It must have no sharp edges or small loose parts."],
	["Size", "It must be no bigger than 20 cm by 15 cm."],
	["Function", "It must hold 6 pencils upright."],
	["Materials", "It must be made from wood with a water-based paint."],
]
const ACCESS_WORDS: Array[String] = ["Aesthetics", "Cost", "Customer", "Environment", "Safety", "Size", "Function",
	"Materials"]
const SPEC_BETTER: Array = [   # [vague, measurable, three vague rewrites]
	["It must be light.", "It must have a mass under 300 g.", ["It must be very light.", "It must be lighter than most.",
		"It must not be heavy."]],
	["It must be cheap.", "It must cost less than 5 gold to make.", ["It must be very cheap.", "It must be cheaper.",
		"It must not cost a lot."]],
	["It must be small.", "It must fit in a 20 cm box.", ["It must be quite small.", "It must be smaller than most.",
		"It must not be big."]],
	["It must be strong.", "It must hold 2 kg without bending.", ["It must be very strong.", "It must be tough.",
		"It must not break easily."]],
	["It must be quick.", "It must be ready in under 5 minutes.", ["It must be very quick.", "It must be fast.",
		"It must not take long."]],
	["It must be easy to use.", "A 6-year-old can use it with no help.", ["It must be very easy to use.",
		"It must be simple.", "It must not be hard to use."]],
]
const OPEN_QUESTIONS: Array[String] = ["What do you find hard about packing your bag?", "How do you use your lunch box?",
	"What would make your mornings easier?", "Tell me about the last time it broke.", "Why do you like that one?",
	"How do you feel when it rains on your walk?"]
const CLOSED_QUESTIONS: Array[String] = ["Do you like red?", "Is it too heavy?", "Do you have a lunch box?",
	"Would you use it every day?", "Is 10 gold too much?", "Do you walk to school?"]
## Designs copied from nature: [the picture's pair (or ""), nature, design].
const NATURE_DESIGNS: Array = [
	["burr", "a burdock burr's hooks", "hook-and-loop fasteners"],
	["kingfisher", "a kingfisher's beak", "a bullet train's long nose"],
	["honeycomb", "honeycomb's six-sided cells", "light, strong honeycomb panels"],
	["lotus", "a lotus leaf's waxy bumps", "self-cleaning paint"],
	["whale_fin", "a humpback whale's flipper", "quieter wind turbine blades"],
	["termite", "a termite mound's air tunnels", "a building cooled by chimneys"],
	["", "a gecko's feet", "grippers that need no glue"],
	["", "an owl's soft feathers", "quieter fans and train parts"],
	["", "a bird's wings", "aeroplane wings"],
]
const FORCE_THINGS: Array = [
	["tension", "a rope holding up a swing"], ["tension", "a crane's cable lifting a crate"],
	["tension", "a guitar string"], ["tension", "a tow rope pulling a car"],
	["compression", "the legs of a table"], ["compression", "a pillar holding up a roof"],
	["compression", "the bricks at the bottom of a wall"],
	["bending", "a diving board with someone on its end"], ["bending", "a shelf holding books"],
	["bending", "a ruler pushed down in the middle"],
	["torsion", "wringing out a wet towel"], ["torsion", "turning a screwdriver"], ["torsion", "twisting open a jar lid"],
	["shear", "scissors cutting paper"], ["shear", "a hole punch"], ["shear", "a paper guillotine"],
]
const FORCES: Array[String] = ["compression", "tension", "bending", "torsion", "shear"]
const LEVER_TOOLS: Array = [["a seesaw", 1], ["scissors", 1], ["pliers", 1], ["a crowbar lifting a stone", 1],
	["a wheelbarrow", 2], ["a nutcracker", 2], ["a bottle opener", 2], ["tweezers", 3], ["a fishing rod", 3],
	["your forearm lifting a cup", 3], ["a broom sweeping", 3]]
## Products and their input (a sensor or switch), with the output the picture shows.
const SENSOR_PRODUCTS: Array = [
	["light", "lamp", "a night light that comes on when it gets dark"],
	["light", "lamp", "a street lamp that turns on at dusk"],
	["heat", "buzzer", "a frost alarm that beeps when it is freezing"],
	["heat", "fan", "a fan that turns on when a room gets hot"],
	["moisture", "pump", "a plant pot that waters itself when the soil is dry"],
	["motion", "buzzer", "a burglar alarm that notices someone moving"],
	["sound", "led", "a baby monitor that lights up when the baby cries"],
	["push", "lamp", "a fridge light that comes on when the door opens"],
	["tilt", "buzzer", "a toy that beeps when it is tipped over"],
	["magnet", "buzzer", "a door alarm with a magnet on the door"],
]
const SENSOR_NAMES := {"light": "light sensor", "heat": "temperature sensor", "moisture": "moisture sensor",
	"sound": "sound sensor", "motion": "motion sensor", "push": "push switch", "tilt": "tilt switch",
	"magnet": "reed switch"}
const ZONE_WORDS := {"freezer": "freezer", "fridge": "fridge", "danger": "danger zone", "hot": "hot"}
const ZONE_CASES: Array = [
	["freezer", "Frozen peas are kept at %s °C.", [-24, -18]],
	["fridge", "Milk is kept in the fridge at %s °C.", [1, 4]],
	["danger", "Cooked rice has cooled to %s °C on the worktop.", [15, 40]],
	["danger", "A lunch box sits in a warm car at %s °C.", [25, 45]],
	["hot", "Soup is kept hot at %s °C.", [65, 90]],
]
const USE_BY: Array[String] = ["ham", "chicken", "fresh milk", "a yoghurt", "fresh fish"]
const BEST_BEFORE: Array[String] = ["biscuits", "cereal", "rice", "pasta", "a tin of tomatoes", "bread"]
const PACK_FOODS: Array[String] = ["rice", "pasta", "oats", "lentils", "flour"]
const MATERIAL_FAMILY := {"oak": "wood", "beech": "wood", "ash": "wood", "mahogany": "wood", "balsa": "wood",
	"pine": "wood", "spruce": "wood", "cedar": "wood", "larch": "wood", "plywood": "wood", "MDF": "wood",
	"chipboard": "wood", "steel": "metal", "cast iron": "metal", "stainless steel": "metal", "aluminium": "metal",
	"copper": "metal", "brass": "metal", "tin": "metal", "zinc": "metal", "acrylic": "plastic", "polythene": "plastic",
	"PVC": "plastic", "polystyrene": "plastic", "melamine": "plastic", "epoxy resin": "plastic",
	"urea formaldehyde": "plastic", "carbon fibre": "composite", "concrete": "composite",
	"glass-reinforced plastic": "composite", "reinforced concrete": "composite"}
const MATERIAL_SUB := {"oak": "hardwood", "beech": "hardwood", "ash": "hardwood", "mahogany": "hardwood",
	"balsa": "hardwood", "pine": "softwood", "spruce": "softwood", "cedar": "softwood", "larch": "softwood",
	"plywood": "manufactured board", "MDF": "manufactured board", "chipboard": "manufactured board",
	"steel": "ferrous", "cast iron": "ferrous", "stainless steel": "ferrous", "aluminium": "non-ferrous",
	"copper": "non-ferrous", "brass": "non-ferrous", "tin": "non-ferrous", "zinc": "non-ferrous",
	"acrylic": "thermoplastic", "polythene": "thermoplastic", "PVC": "thermoplastic", "polystyrene": "thermoplastic",
	"melamine": "thermoset", "epoxy resin": "thermoset", "urea formaldehyde": "thermoset"}
const SUB_OF := {"wood": ["hardwood", "softwood", "manufactured board"], "metal": ["ferrous", "non-ferrous"],
	"plastic": ["thermoplastic", "thermoset"]}
const SUB_PAIRS: Array = [["hardwood", "softwood"], ["ferrous", "non-ferrous"], ["thermoplastic", "thermoset"]]
## The swatch picture's name of a material, when it has one.
const SWATCH := {"oak": "oak", "pine": "pine", "plywood": "plywood", "MDF": "mdf", "steel": "steel",
	"aluminium": "aluminium", "copper": "copper", "brass": "brass", "acrylic": "acrylic", "polythene": "polythene",
	"melamine": "melamine", "carbon fibre": "carbon_fibre", "concrete": "concrete"}
## Densities in g/cm³ (about), for float or sink.
const DENSITY := {"pine": 0.5, "oak": 0.75, "balsa": 0.16, "polythene": 0.92, "acrylic": 1.2, "aluminium": 2.7,
	"steel": 7.9, "concrete": 2.4}
const STYLE_FEATURES := {
	"Arts and Crafts": ["made by hand by skilled makers", "patterns of leaves, flowers and birds",
		"natural materials like oak and wool", "decoration on the surface", "each piece a little different",
		"inspired by medieval crafts"],
	"Bauhaus": ["made by machines in factories", "simple geometric shapes", "new materials like tubular steel",
		"little or no decoration", "form follows function", "primary colours: red, yellow, blue"],
}
const DESIGN_YEARS: Array = [["the Bauhaus opened in Weimar", 1919], ["the Bauhaus moved to Dessau", 1925],
	["the Bauhaus closed", 1933], ["William Morris was born", 1834], ["William Morris died", 1896],
	["Morris and his friends started their firm", 1861], ["the first Arts and Crafts exhibition", 1888],
	["Louis Sullivan wrote 'form ever follows function'", 1896]]
const MARKET_GOODS: Array[String] = ["loaves", "candles", "pies", "horseshoes", "cheeses"]
const IDEAS: Array[String] = ["idea A", "idea B", "idea C"]
const CRITERIA: Array[String] = ["cost", "safety", "use"]


# --- Health and PE: training principles (g6.health_pe.training_principles) --------------------------------------

## Your pulse from a count: beats in 15 s × 4 (level 1), in 10, 20 or 30 s (level 2); level 3: how much higher after a
## run than at rest.
static func pulse_rate(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var seconds: int = 15 if level != 2 else [10, 20, 30][rng.randi_range(0, 2)]
	var per := 60 / seconds
	var ex: Dictionary
	if level < 3:
		var after_run := level == 2 and rng.randf() < 0.5
		var bpm := rng.randi_range(120, 170) if after_run else rng.randi_range(68, 96)
		bpm -= bpm % per
		var count := bpm / per
		ex = K.number("%s counts %d beats in %d seconds, %s. What is that in beats a minute?" % [who, count, seconds,
			"just after a run" if after_run else "sitting still"], bpm,
			"A minute is 60 seconds. How many lots of %d seconds make a minute?" % seconds,
			"60 ÷ %d = %d, so %d × %d = %d beats a minute." % [seconds, per, count, per, bpm])
		ex.data = {"count": count, "seconds": seconds, "rest": 0}
	else:
		var rest := rng.randi_range(17, 24) * 4
		var count := rng.randi_range(30, 42)
		var after := count * 4
		ex = K.number("At rest, %s's pulse is %d beats a minute. Just after a run, %s counts %d beats in 15 seconds. How many beats a minute higher is that?" % [
			who, rest, who, count], after - rest,
			"First find the pulse after the run: beats in 15 seconds × 4. Then take away the resting pulse.",
			"%d × 4 = %d beats a minute after the run, and %d − %d = %d more than at rest." % [count, after, after, rest,
				after - rest])
		ex.data = {"count": count, "seconds": 15, "rest": rest}
	return ex


## A week of activity: level 1 days × minutes; level 2: how many more minutes to reach 60 a day on average (420 a
## week); level 3: progression, a few minutes more each week.
static func fitt_plan(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1:
			var days := rng.randi_range(2, 6)
			var minutes := [20, 30, 40, 45, 50, 60][rng.randi_range(0, 5)] as int
			ex = K.number("%s is active for %d minutes on %d days a week. How many minutes is that in a week?" % [who,
				minutes, days], days * minutes, "Frequency times time: multiply the days by the minutes.",
				"%d × %d = %d minutes a week." % [days, minutes, days * minutes])
			ex.data = {"days": days, "minutes": minutes}
		2:
			var acts: Array = [["PE", [50, 60]], ["football", [60, 90]], ["swimming", [30, 45]], ["dance", [45, 60]],
				["walking to school", [50, 75]], ["tag at break", [40, 75]]]
			K.shuffle(rng, acts)
			var sessions: Array = []
			var total := 0
			for i in 3:
				var opts: Array = acts[i][1]
				var m := int(opts[rng.randi_range(0, opts.size() - 1)])
				sessions.append([str(acts[i][0]), m])
				total += m
			var parts: Array = sessions.map(func(s: Array) -> String: return "%s %d" % [s[0], s[1]])
			ex = K.number("Being active 60 minutes a day on average makes 420 minutes a week. %s does %s minutes. How many more minutes are needed?" % [
				who, _and(parts)], 420 - total, "Add up the minutes so far, then take them away from 420.",
				"%s = %d minutes so far, and 420 − %d = %d more. Walking, cycling and play all count." % [
					" + ".join(sessions.map(func(s: Array) -> String: return str(s[1]))), total, total, 420 - total])
			ex.data = {"sessions": sessions}
		_:
			var start := rng.randi_range(8, 20)
			var add := rng.randi_range(1, 3)
			var week := rng.randi_range(4, 8)
			var t := start + add * (week - 1)
			ex = K.number("%s runs for %d minutes in week 1 and adds %d minute%s each week. How long is the run in week %d, in minutes?" % [
				who, start, add, "" if add == 1 else "s", week], t,
				"Week %d is %d weeks after week 1. How much is added in that many weeks?" % [week, week - 1],
				"Week %d is %d weeks on: %d + %d × %d = %d minutes. Progression: a little more each week." % [week, week - 1,
					start, week - 1, add, t])
			ex.data = {"start": start, "add": add, "week": week}
	return ex


## FITT and the principles: level 1, which part of FITT changed; level 2, which training principle a story shows;
## level 3, which change is a change of one part.
static func fitt_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1:
			var c: Array = FITT_CHANGES[rng.randi_range(0, FITT_CHANGES.size() - 1)]
			ex = K.choice(rng, "Before: %s %s. Now: %s %s. Which part of FITT has changed?" % [who, c[1], who, c[2]],
				str(c[0]), ["frequency", "intensity", "time", "type"].filter(func(p: String) -> bool: return p != str(c[0])),
				"Frequency is how often, intensity how hard, time how long, and type which activity.",
				"%s: the change is %s." % [_cap(str(c[0])), FITT_WORDS[str(c[0])]])
			ex.data = {"before": c[1], "after": c[2]}
		2:
			var c: Array = PRINCIPLE_CASES[rng.randi_range(0, PRINCIPLE_CASES.size() - 1)]
			ex = K.choice(rng, "%s Which training principle is this?" % c[1], str(c[0]),
				PRINCIPLES.filter(func(p: String) -> bool: return p != str(c[0])),
				"Overload: harder than usual. Progression: step by step. Specificity: your own sport. Reversibility: losing it when you stop.",
				"%s." % _principle_why(str(c[0])))
			ex.data = {"principle": c[0]}
		_:
			var parts: Array = ["frequency", "intensity", "time", "type"]
			var part := str(parts[rng.randi_range(0, 3)])
			var right := ""
			var wrongs: Array = []
			for p: String in parts:
				var of: Array = FITT_CHANGES.filter(func(c: Array) -> bool: return str(c[0]) == p)
				var after := str(of[rng.randi_range(0, of.size() - 1)][2])
				if p == part:
					right = after
				else:
					wrongs.append(after)
			ex = K.choice(rng, "Which of these changes the %s of training?" % part, right, wrongs,
				"%s is %s. Which change is about that?" % [_cap(part), FITT_WORDS[part]],
				"'%s' changes %s: the %s." % [right, FITT_WORDS[part], part])
			ex.data = {"part": part}
	return ex


static func _principle_why(p: String) -> String:
	match p:
		"overload":
			return "Overload: the body works harder than it is used to, so it adapts and gets fitter"
		"progression":
			return "Progression: adding a little more, step by step"
		"specificity":
			return "Specificity: training for your own sport or skill"
		"reversibility":
			return "Reversibility: fitness is lost when you stop training (use it or lose it)"
	return "Rest and recovery: the body repairs and gets stronger between sessions"


# --- Health and PE: team tactics (g6.health_pe.team_tactics) ---------------------------------------------------

## Formations: level 1, the missing line of an 11-a-side formation; level 2, name the blue team's formation on the
## pitch; level 3, the missing line in 7- and 5-a-side.
static func formation(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var outfield: int = 10 if level < 3 else [6, 4][rng.randi_range(0, 1)]
	if level == 2 and rng.randf() < 0.3:
		outfield = 6
	var forms: Array = FORMATIONS[outfield]
	var lines: Array = (forms[rng.randi_range(0, forms.size() - 1)] as Array).duplicate()
	var name := "-".join(lines.map(func(n: int) -> String: return str(n)))
	var ex: Dictionary
	if level == 2:
		var players: Array = [[1, 4, "a"]]
		var xs: Array = [3.5, 6.0, 8.5] if lines.size() == 3 else [4.5, 8.0]
		for i in lines.size():
			var n := int(lines[i])
			for k in n:
				players.append([xs[i], snappedf((k + 0.5) * 8.0 / n, 0.1), "a"])
		var wrongs: Array = []
		for f: Array in forms:
			var s := "-".join(f.map(func(n: int) -> String: return str(n)))
			if s != name:
				wrongs.append(s)
		K.shuffle(rng, wrongs)
		ex = K.choice(rng, "The blue team attacks to the right. Which formation are they playing?", name, wrongs.slice(0, 3),
			"Count the players in each line from the back, but leave out the goalkeeper.",
			"%s: %s from the back, with the goalkeeper behind them." % [name, _and(_line_words(lines))],
			{"kind": "pitch", "cols": 12, "rows": 8, "players": players})
		ex.data = {"outfield": outfield, "lines": lines}
		return ex
	var ask := 1 if lines.size() == 3 and (level == 1 or rng.randf() < 0.5) else rng.randi_range(0, lines.size() - 1)
	var shown: Array = lines.map(func(n: int) -> String: return str(n))
	shown[ask] = "?"
	var line := str(LINE_NAMES[ask] if lines.size() == 3 else ["defenders", "forwards"][ask])
	var others := 0
	for i in lines.size():
		if i != ask:
			others += int(lines[i])
	ex = K.number("%s %d-a-side team has a goalkeeper and %d outfield players. It plays %s. How many %s are there?" % [
		"An" if outfield == 10 else "A", int(TEAM_SIZE[outfield]), outfield, "-".join(shown), line], int(lines[ask]),
		"The numbers in a formation add up to the outfield players. What is missing?",
		"%d − %d = %d %s, so the formation is %s." % [outfield, others, int(lines[ask]),
			line.trim_suffix("s") if int(lines[ask]) == 1 else line, name])
	ex.data = {"outfield": outfield, "lines": lines, "ask": ask}
	return ex


static func _line_words(lines: Array) -> Array:
	var out: Array = []
	var names: Array = LINE_NAMES if lines.size() == 3 else ["defenders", "forwards"]
	for i in lines.size():
		out.append("%d %s" % [int(lines[i]), str(names[i]).trim_suffix("s") if int(lines[i]) == 1 else str(names[i])])
	return out


## Tactics: level 1, attacking or defending; level 2, which idea (of its side); level 3, which idea of all.
static func tactic_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c: Array = TACTIC_CASES[rng.randi_range(0, TACTIC_CASES.size() - 1)]
	var idea := str(c[0])
	var attacking := ATTACKING.has(idea)
	var ex: Dictionary
	if level == 1:
		ex = K.choice(rng, "%s Is this an idea for attacking or for defending?" % c[1],
			"attacking" if attacking else "defending", ["defending" if attacking else "attacking"],
			"Which team has the ball: yours, or the other team?",
			"%s: it is about %s. The idea is %s." % ["Attacking" if attacking else "Defending",
				"keeping the ball and making chances" if attacking else "stopping the other team scoring", idea])
	else:
		var pool: Array = (ATTACKING if attacking else DEFENDING).duplicate() if level == 2 \
			else (ATTACKING + DEFENDING).duplicate()
		pool.erase(idea)
		K.shuffle(rng, pool)
		ex = K.choice(rng, "%s %s Which idea is this?" % ["Your team has the ball." if attacking
			else "The other team has the ball.", c[1]], idea, pool.slice(0, 3 if level == 2 else 4),
			"Width: spread out. Support: help the ball carrier. Pressure, cover, delay and marking stop attackers.",
			"%s: %s" % [_cap(idea), _tactic_why(idea)])
	ex.data = {"idea": idea}
	return ex


static func _tactic_why(idea: String) -> String:
	match idea:
		"width":
			return "spreading out makes the other team spread out too, and opens space."
		"support":
			return "teammates near the ball give the ball carrier someone to pass to."
		"penetration":
			return "getting the ball forward past defenders makes chances to score."
		"movement":
			return "moving into space gets you free to receive the ball."
		"pressure":
			return "closing down the ball carrier quickly gives them less time."
		"cover":
			return "a second defender backs up the first."
		"compactness":
			return "defenders close together leave no space to pass through."
		"delay":
			return "slowing the attacker gives teammates time to get back."
	return "staying goal-side of an attacker stops them getting the ball easily."


# --- Health and PE: athletics (g6.health_pe.athletics_technique) ----------------------------------------------

## A 4 × 100 m relay: level 1, the team's time from four legs; level 2, the missing leg from the total; level 3, the
## time with three smooth baton changes.
static func relay_split(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var legs: Array = []
	var sum := 0
	for i in 4:
		var t := rng.randi_range(130, 175)
		legs.append(t)
		sum += t
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A 4 × 100 m relay team's legs took %s. What was the team's time, in seconds?" % _and(
				legs.map(func(t: int) -> String: return _tenths(t) + " s")), _tenths(sum),
				"Add the four legs. Add the whole seconds, then the tenths.",
				"%s = %s seconds." % [" + ".join(legs.map(func(t: int) -> String: return _tenths(t))), _tenths(sum)])
			ex.data = {"legs": legs}
		2:
			var missing := rng.randi_range(0, 3)
			var known: Array = []
			var known_sum := 0
			for i in 4:
				if i != missing:
					known.append(_tenths(int(legs[i])) + " s")
					known_sum += int(legs[i])
			var nth := ["first", "second", "third", "last"][missing] as String
			ex = K.number("%s's relay team ran %s s. The other three legs took %s. How long did the %s leg take, in seconds?" % [
				who, _tenths(sum), _and(known), nth], _tenths(int(legs[missing])),
				"The four legs add up to the team's time. Take the three you know away from it.",
				"The three legs add up to %s s, and %s − %s = %s s." % [_tenths(known_sum), _tenths(sum), _tenths(known_sum),
					_tenths(int(legs[missing]))])
			ex.data = {"legs": legs, "missing": missing}
		_:
			var save := rng.randi_range(2, 6)
			ex = K.number("A relay team ran %s s, but each of its 3 baton changes lost %s s. With 3 smooth changes, what time could it run, in seconds?" % [
				_tenths(sum), _tenths(save)], _tenths(sum - 3 * save),
				"How much time do 3 changes lose? Take that away from the team's time.",
				"3 × %s = %s s lost, and %s − %s = %s s. Practise the handover in the zone!" % [_tenths(save), _tenths(3 * save),
					_tenths(sum), _tenths(3 * save), _tenths(sum - 3 * save)])
			ex.data = {"legs": legs, "save": save}
	return ex


## Jumps: level 1, a long jump measured to the nearest mark; level 2, a triple jump's hop, step and jump added; level 3,
## the best of three jumps when one is a no-jump.
static func jump_measure(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1:
			var feet := rng.randi_range(25, 45)
			var back := feet - rng.randi_range(2, 6)
			var hand := rng.randf() < 0.6
			var marks: Array = [feet / 10.0, back / 10.0]
			var what := "a hand touches the sand" if hand else "the other heel lands"
			ex = K.number("%s's heels land %s m from the take-off line, but %s at %s m. How long is the jump, in metres?" % [
				who, _tenths(feet), what, _tenths(back)], _tenths(back),
				"A jump is measured from the take-off line to the nearest mark in the sand.",
				"The nearest mark is at %s m, so the jump is %s m, not %s m. Fall forwards, not back!" % [_tenths(back),
					_tenths(back), _tenths(feet)],
				{"kind": "track_field", "view": "long_jump", "marks": marks})
			ex.data = {"marks": marks}
		2:
			var p: Array = [rng.randi_range(25, 45), rng.randi_range(20, 35), rng.randi_range(22, 40)]
			var total := int(p[0]) + int(p[1]) + int(p[2])
			var phases: Array = p.map(func(t: int) -> float: return t / 10.0)
			ex = K.number("%s's triple jump: a hop of %s m, a step of %s m and a jump of %s m. How far is it in all, in metres?" % [
				who, _tenths(int(p[0])), _tenths(int(p[1])), _tenths(int(p[2]))], _tenths(total),
				"The hop, the step and the jump add up to the whole triple jump.",
				"%s + %s + %s = %s m." % [_tenths(int(p[0])), _tenths(int(p[1])), _tenths(int(p[2])), _tenths(total)],
				{"kind": "track_field", "view": "triple_jump", "phases": phases, "labels": true})
			ex.data = {"phases": phases}
		_:
			var jumps: Array = []
			var shown: Array = []
			var foul := rng.randi_range(0, 2)
			var best := 0
			for i in 3:
				if i == foul:
					jumps.append(-1)
					shown.append("a no-jump (a foot over the line)")
				else:
					var j := rng.randi_range(280, 390)
					while j == best:
						j += 3
					best = maxi(best, j)
					jumps.append(j / 100.0)
					shown.append(_hundredths(j) + " m")
			ex = K.number("%s's three long jumps: %s. What is the best jump that counts, in metres?" % [who, _and(shown)],
				_hundredths(best), "A no-jump never counts, however long it was. Compare the others.",
				"The no-jump does not count, so the best is %s m." % _hundredths(best))
			ex.data = {"jumps": jumps}
	return ex


## Speed = distance ÷ time: level 1, a speed; level 2, who is faster; level 3, the time for a distance.
static func sprint_speed(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var v := rng.randi_range(4, 8)
			var t := rng.randi_range(8, 25)
			var d := v * t
			var who := _who(rng)
			ex = K.number("%s runs %d m in %d seconds. What is the average speed, in metres a second?" % [who, d, t], v,
				"Speed is distance ÷ time.", "%d ÷ %d = %d m a second." % [d, t, v])
			ex.data = {"distance": d, "time": t}
		2:
			var pair := PEOPLE.duplicate()
			K.shuffle(rng, pair)
			var runners: Array = []
			for _try in 50:
				runners.clear()
				for i in 2:
					var v := rng.randi_range(4, 8)
					var t := rng.randi_range(8, 20)
					runners.append([pair[i], v * t, t])
				if int(runners[0][1]) * int(runners[1][2]) != int(runners[1][1]) * int(runners[0][2]) \
						and int(runners[0][1]) != int(runners[1][1]):
					break
			var v0 := float(runners[0][1]) / float(runners[0][2])
			var v1 := float(runners[1][1]) / float(runners[1][2])
			var fast := 0 if v0 > v1 else 1
			ex = K.choice(rng, "%s runs %d m in %d s. %s runs %d m in %d s. Whose average speed is faster?" % [
				runners[0][0], runners[0][1], runners[0][2], runners[1][0], runners[1][1], runners[1][2]],
				str(runners[fast][0]), [str(runners[1 - fast][0])],
				"Work out each speed: distance ÷ time. The longer distance is not always the faster run.",
				"%s: %d m a second; %s: %d m a second. %s is faster." % [runners[0][0], int(v0), runners[1][0], int(v1),
					runners[fast][0]])
			ex.data = {"runners": runners}
		_:
			var v := rng.randi_range(4, 8)
			var t := rng.randi_range(10, 40)
			var d := v * t
			ex = K.number("A runner keeps a steady %d m a second. How many seconds does %d m take?" % [v, d], t,
				"Time is distance ÷ speed.", "%d ÷ %d = %d seconds." % [d, v, t])
			ex.data = {"distance": d, "speed": v}
	return ex


# --- Health and PE: analyse and improve (g6.health_pe.analyse_improve) -----------------------------------------

## Success rates: level 1, out of 10 as a percentage; level 2, out of 20, 25 or 50; level 3, the skill to practise
## most from a table.
static func success_rate(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	if level < 3:
		var tries: int = 10 if level == 1 else [20, 25, 50][rng.randi_range(0, 2)]
		var made := rng.randi_range(maxi(1, tries * 3 / 10), tries - 1)
		var what := ["shots on target", "passes that reached a teammate", "serves in", "catches"][rng.randi_range(0, 3)] as String
		var pct := made * 100 / tries
		ex = K.number("%s counted %d %s out of %d tries. What percentage is that?" % [who, made, what, tries], pct,
			"Per cent means out of 100. How many times does %d go into 100?" % tries,
			"100 ÷ %d = %d, so %d × %d = %d%%." % [tries, 100 / tries, made, 100 / tries, pct])
		ex.data = {"made": made, "tries": tries}
		return ex
	var skills: Array = ["passing", "shooting", "dribbling", "catching", "serving", "free throws"]
	K.shuffle(rng, skills)
	var rows: Array = []
	var pcts: Array = []
	for _try in 50:
		rows.clear()
		pcts.clear()
		for i in 3:
			var tries := [10, 20][rng.randi_range(0, 1)] as int
			var made := rng.randi_range(tries * 3 / 10, tries * 9 / 10)
			rows.append([skills[i], made, tries])
			pcts.append(made * 100 / tries)
		var s: Array = pcts.duplicate()
		s.sort()
		if int(s[1]) - int(s[0]) >= 10 and int(s[2]) - int(s[1]) >= 5:
			break
	var worst := pcts.find(pcts.min())
	var table: Array = [["skill", "successes", "tries"]]
	for r: Array in rows:
		table.append([str(r[0]), str(r[1]), str(r[2])])
	ex = K.choice(rng, "%s's practice results are in the table. Which skill should come first in the next practice?" % who,
		str(rows[worst][0]), rows.filter(func(r: Array) -> bool: return str(r[0]) != str(rows[worst][0])).map(
			func(r: Array) -> String: return str(r[0])),
		"Turn each into a percentage, so different numbers of tries can be compared.",
		"%s. The lowest is %s: practise it first." % [_cap(", ".join(PackedStringArray(rows.map(func(r: Array) -> String:
			return "%s %d%%" % [r[0], int(r[1]) * 100 / int(r[2])])))), rows[worst][0]],
		{"kind": "table", "rows": table})
	ex.data = {"rows": rows}
	return ex


# --- Health and PE: food as fuel (g6.health_pe.food_as_fuel) ---------------------------------------------------

## 5 A DAY by the NHS's rules: level 1, fruit and vegetables among other foods; level 2, juice or beans more than once
## (they count once); level 3, potatoes as well (they are starchy food).
static func five_a_day(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var fruit := FRUIT_VEG.duplicate()
	K.shuffle(rng, fruit)
	var foods: Array = fruit.slice(0, rng.randi_range(2, 3))
	var other := OTHER_FOODS.duplicate()
	K.shuffle(rng, other)
	foods.append(other[0])
	var notes: Array = []
	var count := foods.size() - 1
	if level >= 2:
		if rng.randf() < 0.5 or level == 3:
			var j := JUICES.duplicate()
			K.shuffle(rng, j)
			foods.append_array([j[0], j[1]] if level == 2 else [j[0]])
			count += 1
			notes.append("juice and smoothies count once, however much")
		if level == 2 and notes.is_empty() or level == 3:
			var b := BEANS.duplicate()
			K.shuffle(rng, b)
			foods.append_array([b[0], b[1]] if level == 2 else [b[0]])
			count += 1
			notes.append("beans and pulses count once")
	if level == 3:
		foods.append(POTATOES[rng.randi_range(0, POTATOES.size() - 1)])
		notes.append("potatoes are a starchy food, so they do not count")
	K.shuffle(rng, foods)
	var ex := K.number("In one day, %s has %s. How many portions of 5 A DAY is that?" % [who, _and(foods)], count,
		"Count the fruit and vegetables. Juice counts once at most, beans once at most, and potatoes not at all.",
		"%d portion%s: each fruit or vegetable counts 1%s." % [count, "" if count == 1 else "s",
			("; " + "; ".join(PackedStringArray(notes))) if not notes.is_empty() else ""])
	ex.data = {"foods": foods}
	return ex


## Nutrients: level 1, the big ones' jobs; level 2, minerals' and vitamins' jobs; level 3, which nutrient foods are rich
## in.
static func nutrient_job(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var cases: Array = NUTRIENT_JOBS.filter(func(c: Array) -> bool: return int(c[0]) == level)
	var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
	var right := str(c[1])
	var pool: Array = (NUTRIENTS.slice(0, 5) if level == 1 else NUTRIENTS).filter(func(n: String) -> bool: return n != right)
	K.shuffle(rng, pool)
	var prompt := ("Which nutrient %s?" % c[2]) if level < 3 else ("Which nutrient are %s rich in?" % c[2])
	var ex := K.choice(rng, prompt, right, pool.slice(0, 3),
		"Think of what each nutrient does: energy, growing, digestion, bones, blood.", str(NUTRIENT_WHY[right]))
	ex.data = {"nutrient": right}
	return ex


# --- Health and PE: mental health (g6.health_pe.mental_health) --------------------------------------------------

## The five ways to wellbeing: level 1, of three; level 2, of all five; level 3, sort activities into two ways.
static func wellbeing_way(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ways := WAYS.duplicate()
	K.shuffle(rng, ways)
	var ex: Dictionary
	if level < 3:
		var way := str(ways[0])
		var acts: Array = WAY_ACTS[way]
		var act := str(acts[rng.randi_range(0, acts.size() - 1)])
		ex = K.choice(rng, "Which of the five ways to wellbeing is this: %s?" % act, way, ways.slice(1, 3 if level == 1 else 5),
			"Connect, be active, keep learning, give, take notice: which is it mostly about?",
			"%s: %s." % [_cap(way), _way_why(way)])
		ex.data = {"activity": act}
		return ex
	var a := str(ways[0])
	var b := str(ways[1])
	var items: Array = []
	for w: String in [a, b]:
		var acts: Array = (WAY_ACTS[w] as Array).duplicate()
		K.shuffle(rng, acts)
		for act: Variant in acts.slice(0, 3):
			items.append([str(act), w])
	ex = _sort(rng, "Sort them: %s or %s?" % [a, b], [a, b], items,
		"Is it about other people, moving, learning, helping or noticing?",
		"%s: %s. %s: %s." % [_cap(a), _way_why(a), _cap(b), _way_why(b)])
	ex.data = {"ways": [a, b]}
	return ex


static func _way_why(way: String) -> String:
	match way:
		"connect":
			return "time with other people"
		"be active":
			return "moving your body"
		"keep learning":
			return "trying something new"
		"give":
			return "doing something kind for someone"
	return "noticing the world around you, right now"


# --- Health and PE: stress and coping (g6.health_pe.stress_coping) ----------------------------------------------

## Box breathing: level 1, the counts in one box; level 2, the seconds for several boxes; level 3, slow breaths with a
## longer breath out, and how many in a few minutes.
static func box_breath(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var n := rng.randi_range(3, 6)
			ex = K.number("Box breathing: breathe in for %d, hold for %d, breathe out for %d, hold for %d. How many counts is one box?" % [
				n, n, n, n], 4 * n, "A box has 4 sides, and each side is the same count.",
				"4 × %d = %d counts." % [n, 4 * n], {"kind": "breath_box", "count": n})
			ex.data = {"count": n}
		2:
			var n := rng.randi_range(3, 5)
			var boxes := rng.randi_range(2, 5)
			ex = K.number("%s breathes round the box %d times, counting %d on each side, one count a second. How many seconds is that?" % [
				_who(rng), boxes, n], 4 * n * boxes, "Find the seconds for one box first, then multiply by the boxes.",
				"One box: 4 × %d = %d seconds. %d boxes: %d × %d = %d seconds." % [n, 4 * n, boxes, boxes, 4 * n,
					4 * n * boxes], {"kind": "breath_box", "count": n})
			ex.data = {"count": n, "boxes": boxes}
		_:
			var br := 0
			var out := 0
			var minutes := 0
			for _try in 100:
				br = rng.randi_range(3, 5)
				out = br + rng.randi_range(1, 4)
				minutes = rng.randi_range(1, 3)
				if 60 * minutes % (br + out) == 0:
					break
			var per := br + out
			ex = K.number("A slow, calming breath: in for %d counts and out for %d, one count a second. How many breaths is that in %d minute%s?" % [
				br, out, minutes, "" if minutes == 1 else "s"], 60 * minutes / per,
				"One breath takes in + out seconds. How many seconds are in the minutes?",
				"One breath: %d + %d = %d seconds. %d seconds ÷ %d = %d breaths." % [br, out, per, 60 * minutes, per,
					60 * minutes / per])
			ex.data = {"in": br, "out": out, "minutes": minutes}
	return ex


## The circle of control: sort what I can control from what I cannot (4, 5 or 6 things).
static func control_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var can := CAN_CONTROL.duplicate()
	var cannot := CANNOT_CONTROL.duplicate()
	K.shuffle(rng, can)
	K.shuffle(rng, cannot)
	var n := level + 3
	var k := rng.randi_range(1, n - 1)
	var items: Array = []
	for i in k:
		items.append([can[i], "I can control"])
	for i in n - k:
		items.append([cannot[i], "I cannot control"])
	var ex := _sort(rng, "The circle of control: sort them.", ["I can control", "I cannot control"], items,
		"Can you choose it or change it yourself, today?",
		"I can control my own choices and actions: %s. Not: %s. Put your energy where you can make a difference." % [
			_and(can.slice(0, k)), _and(cannot.slice(0, n - k))])
	ex.data = {}
	return ex


# --- Health and PE: smoking, vaping and alcohol (g6.health_pe.smoking_vaping_alcohol) --------------------------

## Facts about the body and the law as true or false (levels 1-3); at level 3, half of the time, the clearest way to
## say no.
static func substance_facts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3 and rng.randf() < 0.5:
		var offer := str(OFFERS[rng.randi_range(0, OFFERS.size() - 1)])
		var said := str(PRESSURE[rng.randi_range(0, PRESSURE.size() - 1)])
		var weak := WEAK_NO.duplicate()
		K.shuffle(rng, weak)
		var good := str(GOOD_NO[rng.randi_range(0, GOOD_NO.size() - 1)])
		ex = K.choice(rng, "Someone offers you %s and says, '%s' Which answer says no most clearly?" % [offer, said],
			good, weak.slice(0, 3), "A clear no is short and firm, and can give a reason or suggest something else.",
			"'%s' It is clear and firm. Then walk away, and tell a trusted adult if it happens again." % good)
		ex.data = {"offer": offer}
		return ex
	var facts: Array = SUBSTANCE_FACTS.filter(func(f: Array) -> bool: return int(f[0]) == level)
	var f: Array = facts[rng.randi_range(0, facts.size() - 1)]
	ex = K.truefalse(str(f[2]), bool(f[1]), "Think about what these things do to the body, and what the law says.",
		("True. " if bool(f[1]) else "False. ") + _substance_why(str(f[2])))
	ex.data = {"fact": f[2]}
	return ex


static func _substance_why(fact: String) -> String:
	if fact.contains("harmless"):
		return "Vapes usually contain nicotine, which is addictive, and they are not for young people."
	if fact.contains("fitter"):
		return "Smoking harms the lungs and heart, so it makes you less fit."
	if fact.contains("not addictive"):
		return "Nicotine is addictive: the body craves more."
	if fact.contains("faster"):
		return "Alcohol slows the brain, so reactions get slower."
	if fact.contains("only harms"):
		return "Second-hand smoke harms the people nearby too."
	if fact.contains("14-year-old"):
		return "In the UK, it is against the law to sell nicotine vapes to anyone under 18."
	if fact.contains("your age vape"):
		return "Most young people do not vape, smoke or drink alcohol."
	return "It is a fact from doctors or from the law."


# --- Health and PE: serious emergencies (g6.health_pe.serious_emergencies) --------------------------------------

## Emergencies: level 1, which service to ask for; level 2, the FAST signs of a stroke; level 3, cooling a burn for
## 20 minutes, or the pushes of CPR at 100-120 a minute.
static func emergency_call(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = EMERGENCIES[rng.randi_range(0, EMERGENCIES.size() - 1)]
			ex = K.choice(rng, "You call 999 in the UK. Which service do you ask for? %s" % c[1], str(c[0]),
				SERVICES.filter(func(s: String) -> bool: return s != str(c[0])),
				"Who can help most: someone to treat an injury, put out a fire, stop a crime, or rescue at sea?",
				"Ask for the %s. %s" % [{"ambulance": "ambulance", "fire": "fire service", "police": "police",
					"coastguard": "coastguard"}[str(c[0])], "In the mountains, the police send mountain rescue." if str(c[1]).contains("mountain")
					else "Say where you are and what has happened, and stay on the line."])
			ex.data = {"scenario": c[1]}
		2:
			var c: Array = FAST_SIGNS[rng.randi_range(0, FAST_SIGNS.size() - 1)]
			ex = K.choice(rng, "Which sign of a stroke in FAST is this? %s" % c[1], str(c[0]), ["Face", "Arms", "Speech",
				"Time"].filter(func(s: String) -> bool: return s != str(c[0])),
				"F is the face, A the arms, S the speech, and T is time to call 999.",
				"%s. Any FAST sign means Time: call 999 straight away." % c[0], {"kind": "fast_signs", "words": false})
			ex.data = {"sign": c[1]}
		_:
			if rng.randf() < 0.5:
				var start := rng.randi_range(6, 33) * 10   # 1:00 pm to 6:30 pm, minutes after noon
				start = mini(start, 330)
				var end := start + 20
				var wrongs: Array = [_pm(start + 5), _pm(start + 10), _pm(start + 60)]
				ex = K.choice(rng, "A burn is put under cool running water at %s. When should the cooling stop?" % _pm(start),
					_pm(end), wrongs, "Cool a burn under cool or lukewarm running water for 20 minutes.",
					"20 minutes after %s is %s. Then cover it loosely with cling film and get help." % [_pm(start), _pm(end)])
				ex.data = {"kind": "burn", "start": start}
			else:
				var per := [100, 110, 120][rng.randi_range(0, 2)] as int
				var secs := [30, 60, 90][rng.randi_range(0, 2)] as int
				ex = K.number("On a 999 call, the call handler counts CPR pushes at %d a minute. How many pushes is that in %d seconds?" % [
					per, secs], per * secs / 60, "How many minutes, or what part of a minute, is that many seconds?",
					"%d seconds is %s of a minute: %d × %d ÷ 60 = %d pushes." % [secs, {30: "half", 60: "all", 90: "one and a half"}[secs],
						per, secs, per * secs / 60])
				ex.data = {"kind": "cpr", "per_minute": per, "seconds": secs}
	return ex


static func _pm(minutes_after_noon: int) -> String:
	return "%d:%02d pm" % [minutes_after_noon / 60, minutes_after_noon % 60]


# --- Health and PE: outdoor challenge (g6.health_pe.outdoor_challenge) ------------------------------------------

## Walking times: level 1, at a steady speed; level 2, Naismith's rule (12 minutes a km, 1 minute for every 10 m
## climbed); level 3, a route card's three legs.
static func naismith(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var speed := rng.randi_range(3, 5)
			var km := rng.randi_range(2, 9)
			var minutes := km * 60 / speed
			if km * 60 % speed != 0:
				km = speed * rng.randi_range(1, 2)
				minutes = km * 60 / speed
			ex = K.number("A group walks at %d km an hour. How many minutes will %d km take?" % [speed, km], minutes,
				"An hour is 60 minutes. How many minutes does 1 km take at that speed?",
				"1 km takes 60 ÷ %d = %d minutes, so %d km take %d × %d = %d minutes." % [speed, 60 / speed, km, km,
					60 / speed, minutes])
			ex.data = {"km": km, "speed": speed}
		2:
			var km := rng.randi_range(3, 12)
			var climb := rng.randi_range(2, 12) * 50
			var t := km * 12 + climb / 10
			ex = K.number("Naismith's rule: 12 minutes for each km, and 1 more minute for every 10 m climbed. How many minutes for %d km with %d m of climbing?" % [
				km, climb], t, "Work out the walking time and the climbing time, then add them.",
				"%d × 12 = %d minutes of walking, %d ÷ 10 = %d minutes of climbing: %d minutes." % [km, km * 12, climb,
					climb / 10, t])
			ex.data = {"km": km, "climb": climb}
		_:
			var legs: Array = []
			var rows: Array = [["leg", "km", "climb (m)"]]
			var total := 0
			for i in 3:
				var half_km := rng.randi_range(2, 10)
				var climb := rng.randi_range(0, 6) * 50
				legs.append([half_km / 2.0, climb])
				rows.append([str(i + 1), _halves(half_km), str(climb)])
				total += half_km * 6 + climb / 10
			ex = K.number("A route card's legs are in the table. By Naismith's rule (12 minutes a km, 1 minute for each 10 m climbed), how many minutes is the whole route?",
				total, "Work out each leg's time, then add the three legs.",
				"%s = %d minutes. Add time for rests, and tell someone your route." % [" + ".join(PackedStringArray(legs.map(
					func(l: Array) -> String: return str(int(float(l[0]) * 12 + float(l[1]) / 10))))), total],
				{"kind": "table", "rows": rows})
			ex.data = {"legs": legs}
	return ex


## A day walk's kit: sort what to pack from what to leave at home (4, 5 or 6 things).
static func kit_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pack := KIT_PACK.duplicate()
	var leave := KIT_LEAVE.duplicate()
	K.shuffle(rng, pack)
	K.shuffle(rng, leave)
	var n := level + 3
	var k := rng.randi_range(maxi(2, n - 3), n - 1)
	var items: Array = []
	for i in k:
		items.append([pack[i], "pack it"])
	for i in n - k:
		items.append([leave[i], "leave it at home"])
	var ex := _sort(rng, "A day's walk in the hills: pack it, or leave it at home?", ["pack it", "leave it at home"],
		items, "Pack what keeps you safe, warm, dry, fed and found. Leave what is heavy, breakable or not needed.",
		"Pack %s. Leave %s." % [_and(pack.slice(0, k)), _and(leave.slice(0, n - k))])
	ex.data = {}
	return ex


# --- Design and technology: user-centred design (g6.design_tech.user_centred_design) ------------------------------

## Specifications: level 1, the point that can be measured; level 2, its ACCESS FM heading; level 3, a vague point
## made measurable.
static func spec_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var good := str(SPEC_MEASURABLE[rng.randi_range(0, SPEC_MEASURABLE.size() - 1)])
			var vague := SPEC_VAGUE.duplicate()
			K.shuffle(rng, vague)
			ex = K.choice(rng, "Which specification point can be measured and tested?", good, vague.slice(0, 3),
				"Look for a number you could check with a ruler, scales, a clock or a user test.",
				"'%s' has a number to test. The others are opinions: how nice is nice?" % good)
			ex.data = {}
		2:
			var c: Array = ACCESS_POINTS[rng.randi_range(0, ACCESS_POINTS.size() - 1)]
			var others: Array = ACCESS_WORDS.filter(func(w: String) -> bool: return w != str(c[0]))
			K.shuffle(rng, others)
			ex = K.choice(rng, "Which ACCESS FM heading is this specification point under? '%s'" % c[1], str(c[0]),
				others.slice(0, 3), "Aesthetics, Cost, Customer, Environment, Safety, Size, Function, Materials: what is it about?",
				"%s: %s." % [c[0], _access_why(str(c[0]))], {"kind": "access_fm"})
			ex.data = {"point": c[1]}
		_:
			var c: Array = SPEC_BETTER[rng.randi_range(0, SPEC_BETTER.size() - 1)]
			ex = K.choice(rng, "Make this specification point measurable: '%s'" % c[0], str(c[1]), c[2],
				"A measurable point has a number and a unit, so a test can show whether it passes.",
				"'%s' can be tested. 'Very' and 'not' are still opinions." % c[1])
			ex.data = {"vague": c[0]}
	return ex


static func _access_why(word: String) -> String:
	match word:
		"Aesthetics":
			return "how it looks and feels"
		"Cost":
			return "how much it costs to make or buy"
		"Customer":
			return "who it is for and what they like"
		"Environment":
			return "its effect on the planet"
		"Safety":
			return "keeping users safe"
		"Size":
			return "how big it is"
		"Function":
			return "what it must do"
	return "what it is made from"


## Interview questions: level 1, open or closed; level 2, the open one; level 3, sort them.
static func interview_q(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var open := OPEN_QUESTIONS.duplicate()
	var closed := CLOSED_QUESTIONS.duplicate()
	K.shuffle(rng, open)
	K.shuffle(rng, closed)
	var ex: Dictionary
	match level:
		1:
			var is_open := rng.randf() < 0.5
			var q := str(open[0] if is_open else closed[0])
			ex = K.choice(rng, "An interview question for a user: '%s' Is it open or closed?" % q,
				"open" if is_open else "closed", ["closed" if is_open else "open"],
				"A closed question can be answered with yes, no or one word. An open one needs a longer answer.",
				"%s: %s" % ["Open" if is_open else "Closed", "it invites the user to explain." if is_open
					else "it can be answered with just yes or no, or one word."])
			ex.data = {"question": q}
		2:
			ex = K.choice(rng, "Which question will tell a designer the most about a user's needs?", str(open[0]),
				closed.slice(0, 3), "Which one cannot be answered with just yes or no?",
				"'%s' is open: the user has to explain, so you learn about their needs." % open[0])
			ex.data = {}
		_:
			var k := rng.randi_range(2, 3)
			var items: Array = []
			for i in k:
				items.append([open[i], "open"])
			for i in 5 - k:
				items.append([closed[i], "closed"])
			ex = _sort(rng, "Sort the questions: open or closed?", ["open", "closed"], items,
				"Could it be answered with yes, no or one word? Then it is closed.",
				"Open: %s Closed: %s" % [" ".join(PackedStringArray(open.slice(0, k))),
					" ".join(PackedStringArray(closed.slice(0, 5 - k)))])
			ex.data = {}
	return ex


# --- Design and technology: ideas from nature (g6.design_tech.ideas_from_nature) --------------------------------

## Biomimicry: level 1, the design copied from something in nature; level 2, what in nature inspired a design; level
## 3, match four.
static func nature_idea(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pairs := NATURE_DESIGNS.duplicate()
	K.shuffle(rng, pairs)
	var c: Array = pairs[0]
	var ex: Dictionary
	match level:
		1:
			var pic := {"kind": "biomimicry", "pair": str(c[0]), "show": "nature", "names": false} if str(c[0]) != "" else {}
			ex = K.choice(rng, "Engineers copied %s. Which design did it inspire?" % c[1], str(c[2]), pairs.slice(1, 4).map(
				func(p: Array) -> String: return str(p[2])), "Think about what the natural thing is good at.",
				"%s: %s" % [_cap(str(c[2])), _nature_why(str(c[1]))], pic)
			ex.data = {"nature": c[1]}
		2:
			ex = K.choice(rng, "Which part of nature inspired %s?" % c[2], str(c[1]), pairs.slice(1, 4).map(
				func(p: Array) -> String: return str(p[1])), "What would the design need to be good at? What in nature does that?",
				"%s. %s" % [_cap(str(c[1])), _nature_why(str(c[1]))])
			ex.data = {"design": c[2]}
		_:
			var four: Array = pairs.slice(0, 4)
			ex = _match(rng, "Match each part of nature to the design it inspired.", four.map(func(p: Array) -> String:
				return str(p[1])), four.map(func(p: Array) -> String: return str(p[2])),
				"Think about what each natural thing does best: hooks grip, beaks slice, cells are strong, leaves stay clean.",
				"; ".join(PackedStringArray(four.map(func(p: Array) -> String: return "%s: %s" % [p[1], p[2]]))) + ".")
			ex.data = {}
	return ex


static func _nature_why(nature: String) -> String:
	if nature.contains("burr"):
		return "the burr's tiny hooks catch on loops, like fur."
	if nature.contains("kingfisher"):
		return "the beak's long, pointed shape dives into water with hardly a splash."
	if nature.contains("honeycomb"):
		return "six-sided cells make a strong, light structure from little material."
	if nature.contains("lotus"):
		return "water beads up on the leaf and rolls off, taking the dirt with it."
	if nature.contains("whale"):
		return "the bumps on the flipper's front edge help the water flow smoothly."
	if nature.contains("termite"):
		return "warm air rises out of the mound's chimneys and pulls cool air in low down."
	if nature.contains("gecko"):
		return "millions of tiny hairs on the toes cling to surfaces."
	if nature.contains("owl"):
		return "soft, fringed edges make the owl's flight almost silent."
	return "curved wings give lift as air flows over them."


# --- Design and technology: structures and forces (g6.design_tech.structures_forces) ----------------------------

## A Warren truss: level 1, count the triangles of 2-3 panels; level 2, of 4-6 panels; level 3, the bars.
static func truss_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var panels := rng.randi_range(2, 4) if level == 1 else rng.randi_range(4, 6) if level == 2 else rng.randi_range(2, 6)
	var t := 2 * panels - 1
	var thing := ["a bridge", "a crane's arm", "a roof", "a stage's lighting rig"][rng.randi_range(0, 3)] as String
	var ex: Dictionary
	var pic := {"kind": "truss", "panels": panels}
	if level < 3:
		ex = K.number("This truss is part of %s. How many triangles does it have?" % thing, t,
			"Count the triangles pointing up, then the ones pointing down between them.",
			"%d pointing up and %d pointing down: %d triangles." % [panels, panels - 1, t], pic)
		ex.data = {"panels": panels, "ask": "triangles"}
	else:
		ex = K.number("This truss, part of %s, has %d triangles. How many bars is it made of? (Count, or use: 2 × triangles + 1.)" % [
			thing, t],
			2 * t + 1, "The first triangle needs 3 bars; each new triangle adds 2 more.",
			"2 × %d + 1 = %d bars: 3 for the first triangle and 2 for each of the other %d." % [t, 2 * t + 1, t - 1], pic)
		ex.data = {"panels": panels, "ask": "bars"}
	return ex


## The forces in structures: level 1, tension or compression; level 2, all five; level 3, the picture that shows the
## force.
static func struct_force(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var cases: Array = FORCE_THINGS.filter(func(c: Array) -> bool: return level > 1 or str(c[0]) in ["tension",
		"compression"])
	var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
	var force := str(c[0])
	var ex: Dictionary
	var why := _force_why(force)
	if level < 3:
		var others: Array = (["tension", "compression"] if level == 1 else FORCES.duplicate()).filter(
			func(f: String) -> bool: return f != force)
		ex = K.choice(rng, "Which force acts on %s?" % c[1], force, others,
			"Is it being stretched, squashed, bent, twisted or cut?", "%s: %s" % [_cap(force), why])
	else:
		var others: Array = FORCES.filter(func(f: String) -> bool: return f != force)
		K.shuffle(rng, others)
		var pic := func(f: String) -> Dictionary: return {"picture": {"kind": "struct_force", "forces": [f], "names": false}}
		ex = K.choice(rng, "Which picture shows the force on %s?" % c[1], pic.call(force), others.slice(0, 3).map(
			func(f: String) -> Dictionary: return pic.call(f)),
			"Arrows pointing in squash; arrows pointing out stretch; curved arrows twist.",
			"%s: %s" % [_cap(force), why])
	ex.data = {"thing": c[1]}
	return ex


static func _force_why(force: String) -> String:
	match force:
		"tension":
			return "it is being pulled and stretched."
		"compression":
			return "it is being pushed and squashed."
		"bending":
			return "a load pushes on it between supports, so it bends: squashed on top, stretched underneath."
		"torsion":
			return "it is being twisted."
	return "two forces push past each other, like the blades of scissors."


# --- Design and technology: mechanisms (g6.design_tech.mechanisms) ---------------------------------------------

## A lever's class: level 1, clear layouts; level 2, any layout; level 3, everyday levers.
static func lever_class(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var c: Array = LEVER_TOOLS[rng.randi_range(0, LEVER_TOOLS.size() - 1)]
		var k := int(c[1])
		ex = K.choice(rng, "What class of lever is %s?" % c[0], "class %d" % k, ["class 1", "class 2", "class 3"].filter(
			func(s: String) -> bool: return s != "class %d" % k), "Find the pivot, the load and the effort. Which one is in the middle?",
			"Class %d: %s." % [k, ["the pivot is in the middle", "the load is in the middle", "the effort is in the middle"][k - 1]])
		ex.data = {"tool": c[0]}
		return ex
	var p := 0
	var l := 0
	var e := 0
	for _try in 200:
		if level == 1:
			match rng.randi_range(1, 3):
				1:
					p = 5
					l = rng.randi_range(0, 2)
					e = rng.randi_range(8, 10)
				2:
					p = 0
					l = rng.randi_range(3, 6)
					e = rng.randi_range(9, 10)
				3:
					p = 0
					e = rng.randi_range(3, 5)
					l = rng.randi_range(9, 10)
			if rng.randf() < 0.5:
				p = 10 - p
				l = 10 - l
				e = 10 - e
		else:
			p = rng.randi_range(0, 10)
			l = rng.randi_range(0, 10)
			e = rng.randi_range(0, 10)
		if absi(p - l) >= 2 and absi(p - e) >= 2 and absi(l - e) >= 2:
			break
	var k := SchoolPictureG6Health.lever_kind(p, l, e)
	ex = K.choice(rng, "What class of lever is this?", "class %d" % k, ["class 1", "class 2", "class 3"].filter(
		func(s: String) -> bool: return s != "class %d" % k), "Which is in the middle: the pivot, the load or the effort?",
		"Class %d: %s." % [k, ["the pivot is between the load and the effort", "the load is between the pivot and the effort",
			"the effort is between the pivot and the load"][k - 1]],
		{"kind": "lever_class", "pivot": p, "load": l, "effort": e})
	ex.data = {"pivot": p, "load": l, "effort": e}
	return ex


## Moments: effort × its distance = load × its distance. Level 1, the effort twice or three times as far; level 2, any
## effort; level 3, where the effort must push.
static func lever_balance(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var load := 0
	var dl := 0
	var de := 0
	var effort := 0
	for _try in 300:
		dl = rng.randi_range(1, 3)
		de = dl * rng.randi_range(2, 3) if level == 1 else rng.randi_range(dl + 1, 8)
		load = rng.randi_range(2, 12) * 10
		if load * dl % de == 0 and de <= 8 and dl + de <= 10:
			effort = load * dl / de
			break
	var class2 := level > 1 and rng.randf() < 0.4 and de <= 10
	var pivot := 0 if class2 else rng.randi_range(dl, 10 - de)
	var lp := pivot + dl if class2 else pivot - dl
	var ep := pivot + de
	var ask := "distance" if level == 3 else "effort"
	var pic := {"kind": "lever_class", "pivot": pivot, "load": lp, "effort": ep, "scale": true,
		"values": {"load": "%d N" % load, "effort": "?" if ask == "effort" else "%d N" % effort}}
	var ex: Dictionary
	if ask == "effort":
		ex = K.number("The load is %d N, %d mark%s from the pivot. The effort pushes %d marks from the pivot. What effort balances it, in N?" % [
			load, dl, "" if dl == 1 else "s", de], effort,
			"Moments balance: effort × its distance = load × its distance.",
			"%d × %d = %d, and %d ÷ %d = %d N." % [load, dl, load * dl, load * dl, de, effort], pic)
	else:
		ex = K.number("The load is %d N, %d mark%s from the pivot. An effort of %d N balances it. How many marks from the pivot does the effort push?" % [
			load, dl, "" if dl == 1 else "s", effort], de,
			"Moments balance: effort × its distance = load × its distance. Find the load's moment first.",
			"%d × %d = %d, and %d ÷ %d = %d marks." % [load, dl, load * dl, load * dl, effort, de], pic)
	ex.data = {"load": load, "dl": dl, "de": de, "effort": effort, "ask": ask}
	return ex


## Gear ratios (driven teeth ÷ driver teeth): level 1, the ratio; level 2, the driven gear's turns a minute; level 3, a
## compound train of two pairs.
static func gear_ratio(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var driver := [8, 10, 12, 15, 20][rng.randi_range(0, 4)] as int
			var k := rng.randi_range(2, 40 / driver)
			var driven := driver * k
			ex = K.number("A driver gear with %d teeth turns a driven gear with %d teeth. What is the gear ratio? (3 : 1 is written 3.)" % [
				driver, driven], k, "Gear ratio = driven teeth ÷ driver teeth.",
				"%d ÷ %d = %d: a ratio of %d : 1. The driver turns %d times for each turn of the driven gear." % [driven,
					driver, k, k, k], {"kind": "gears", "gears": [driver, driven], "turn": "cw", "labels": ["driver", "driven"]})
			ex.data = {"driver": driver, "driven": driven}
		2:
			var pairs: Array = [[10, 20], [10, 30], [20, 10], [12, 24], [15, 30], [30, 15], [8, 24], [24, 8], [10, 40],
				[40, 10], [12, 36], [36, 12]]
			var pr: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
			var driver := int(pr[0])
			var driven := int(pr[1])
			var rpm := 0
			for _try in 50:
				rpm = rng.randi_range(2, 12) * 10
				if rpm * driver % driven == 0:
					break
			var out := rpm * driver / driven
			ex = K.number("The driver gear (%d teeth) turns %d times a minute. How many times a minute does the driven gear (%d teeth) turn?" % [
				driver, rpm, driven], out, "Teeth passing a minute are the same for both gears: turns × teeth.",
				"%d × %d = %d teeth a minute, and %d ÷ %d = %d turns a minute." % [rpm, driver, rpm * driver, rpm * driver,
					driven, out], {"kind": "gears", "gears": [driver, driven], "turn": "cw", "labels": ["driver", "driven"]})
			ex.data = {"driver": driver, "driven": driven, "rpm": rpm}
		_:
			var a := [8, 10, 12][rng.randi_range(0, 2)] as int
			var c := [8, 10, 12][rng.randi_range(0, 2)] as int
			var k1 := rng.randi_range(2, 3)
			var k2 := rng.randi_range(2, 3)
			var b := a * k1
			var d := c * k2
			ex = K.number("Gear A (%d teeth) drives gear B (%d teeth). Gear C (%d teeth), on B's axle, drives gear D (%d teeth). How many turns of A make one turn of D?" % [
				a, b, c, d], k1 * k2, "Find each pair's ratio, then multiply them together.",
				"A to B: %d ÷ %d = %d. C to D: %d ÷ %d = %d. %d × %d = %d turns of A." % [b, a, k1, d, c, k2, k1, k2, k1 * k2])
			ex.data = {"a": a, "b": b, "c": c, "d": d}
	return ex


## Linkages: level 1, a reverse motion linkage; level 2, reverse or parallel; level 3, a bell crank.
static func linkage_move(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var type: String = "reverse" if level == 1 else (["reverse", "parallel"][rng.randi_range(0, 1)] if level == 2 else "bell_crank")
	var move := ["left", "right"][rng.randi_range(0, 1)] as String
	var out := SchoolPictureG6Health.linkage_output(type, move)
	var choices: Array = ["left", "right"] if level < 3 else ["up", "down", "left", "right"]
	var names := {"reverse": "a reverse motion linkage", "parallel": "a parallel motion linkage", "bell_crank": "a bell crank"}
	var ex := K.choice(rng, "This is %s. The input rod is pushed to the %s. Which way does the output move?" % [names[type],
		move], out, choices.filter(func(c: String) -> bool: return c != out),
		"Follow the movement bar by bar. A bar turning on a fixed pivot moves its ends opposite ways.",
		"%s: %s" % [_cap(out), {"reverse": "a reverse linkage turns the movement round.",
			"parallel": "two reverse linkages make the output move the same way as the input.",
			"bell_crank": "a bell crank turns the movement through a right angle."}[type]],
		{"kind": "linkage", "type": type, "move": move, "output": false, "labels": true})
	ex.data = {"type": type, "move": move}
	return ex


# --- Design and technology: sensors and switches (g6.design_tech.sensors_switches) --------------------------------

## Which input a product needs: level 1, of three; level 2, of four; level 3, from its systems diagram.
static func sensor_pick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c: Array = SENSOR_PRODUCTS[rng.randi_range(0, SENSOR_PRODUCTS.size() - 1)]
	var right := str(SENSOR_NAMES[str(c[0])])
	var others: Array = SENSOR_NAMES.values().filter(func(n: String) -> bool: return n != right)
	K.shuffle(rng, others)
	var ex: Dictionary
	if level < 3:
		ex = K.choice(rng, "Which input would you use for %s?" % c[2], right, others.slice(0, 2 if level == 1 else 3),
			"What does the product need to notice: light, heat, water, sound, movement, a push, a tilt or a magnet?",
			"A %s: %s" % [right, _sensor_why(str(c[0]))])
	else:
		ex = K.choice(rng, "This is the system for %s. Which input goes in the first box?" % c[2], right, others.slice(0, 3),
			"The input notices a change; the process decides; the output acts.",
			"A %s: %s" % [right, _sensor_why(str(c[0]))],
			{"kind": "sensor_system", "input": str(c[0]), "output": str(c[1]), "hide": "input"})
	ex.data = {"product": c[2]}
	return ex


static func _sensor_why(input: String) -> String:
	match input:
		"light":
			return "it notices how bright or dark it is."
		"heat":
			return "it measures how hot or cold it is."
		"moisture":
			return "it notices how wet the soil is."
		"sound":
			return "it notices loud sounds."
		"motion":
			return "it notices warm bodies moving."
		"push":
			return "the closed door presses the switch; opening the door lets it go."
		"tilt":
			return "a ball inside rolls and joins or breaks the circuit."
	return "a magnet nearby closes the switch; moving it away opens it."


## Sensor readings and a threshold: level 1, when the output first comes on; level 2, how many readings switch it on;
## level 3, which threshold makes it come on at a given time.
static func threshold_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 2:
		var labels: Array = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
		var readings: Array = []
		var t := 0
		var on := 0
		for _try in 100:
			readings.clear()
			for i in 7:
				readings.append(rng.randi_range(8, 30))
			t = rng.randi_range(12, 26)
			on = readings.filter(func(v: int) -> bool: return v > t).size()
			if on >= 1 and on <= 6 and not readings.has(t):
				break
		ex = K.number("A fan's program: IF temperature > %d THEN fan on. On how many days is the fan on?" % t, on,
			"Look along the dashed line: which readings are above it?",
			"%d of the days are above %d °C: %s." % [on, t, _and(labels.filter(func(l: String) -> bool:
				return int(readings[labels.find(l)]) > t))],
			{"kind": "threshold_graph", "readings": readings, "labels": labels, "threshold": t, "below": false, "top": 40,
				"name": "temperature (°C)"})
		ex.data = {"readings": readings, "labels": labels, "threshold": t, "below": false}
		return ex
	var labels: Array = ["4 pm", "5 pm", "6 pm", "7 pm", "8 pm", "9 pm"]
	var readings: Array = []
	var v := rng.randi_range(80, 95)
	for i in 6:
		readings.append(v)
		v -= rng.randi_range(8, 15)
	var at := rng.randi_range(2, 4)
	if level == 1:
		var t := rng.randi_range(int(readings[at]) + 1, int(readings[at - 1]) - 1)
		ex = K.choice(rng, "A street lamp's program: IF light < %d THEN lamp on. At what time does the lamp first come on?" % t,
			str(labels[at]), labels.filter(func(l: String) -> bool: return l != str(labels[at])).slice(0, 3),
			"Find the first reading below the dashed line.",
			"At %s the light is %d, below %d for the first time, so the lamp comes on." % [labels[at], readings[at], t],
			{"kind": "threshold_graph", "readings": readings, "labels": labels, "threshold": t, "name": "light level"})
		ex.data = {"readings": readings, "labels": labels, "threshold": t, "below": true}
		return ex
	var right := rng.randi_range(int(readings[at]) + 1, int(readings[at - 1]))
	var wrongs: Array = [int(readings[at]) - rng.randi_range(1, 5), int(readings[at - 1]) + rng.randi_range(2, 8),
		int(readings[at + 1]) - 1 if at + 1 < 6 else int(readings[at]) - 6]
	wrongs = wrongs.filter(func(w: int) -> bool: return w > 0 and w != right)
	ex = K.choice(rng, "The lamp should come on at %s, not before. Which number works in IF light < ? THEN lamp on?" % labels[at],
		str(right), wrongs.map(func(w: int) -> String: return str(w)),
		"At %s the reading must be below the number; the reading before it must not be." % labels[at],
		"%d: at %s the light is %d, below %d; at %s it is %d, not below." % [right, labels[at], readings[at], right,
			labels[at - 1], readings[at - 1]],
		{"kind": "line_graph", "points": labels.map(func(l: String) -> Array: return [l, readings[labels.find(l)]]),
			"step": 20, "top": 100, "name": "light level"})
	ex.data = {"readings": readings, "labels": labels, "threshold": right, "below": true, "at": at}
	return ex


# --- Design and technology: food science (g6.design_tech.food_science) ------------------------------------------

## The food thermometer: level 1, read the zone; level 2, a kitchen's temperature's zone; level 3, cooked to 75 °C?
static func food_zone(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var zones: Array = ["freezer", "fridge", "danger zone", "hot"]
	if level == 3:
		var t := [60, 68, 72, 75, 78, 82, 90][rng.randi_range(0, 6)] as int
		var food := ["chicken", "a burger", "a sausage", "a chicken pie"][rng.randi_range(0, 3)] as String
		var ok := t >= 75
		ex = K.truefalse("A probe in the middle of %s reads %d °C. It is cooked safely." % [food, t], ok,
			"The middle (the core) must reach 75 °C.",
			"%s: %d °C is %s 75 °C." % ["True" if ok else "False", t, "at least" if ok else "below"])
		ex.data = {"t": t}
		return ex
	var c: Array = ZONE_CASES[rng.randi_range(0, ZONE_CASES.size() - 1)]
	var span: Array = c[2]
	var t := rng.randi_range(int(span[0]), int(span[1]))
	var zone := str(ZONE_WORDS[str(c[0])])
	if level == 1:
		ex = K.choice(rng, "The thermometer reads %s °C. Which zone is that?" % _temp(t), zone, zones.filter(
			func(z: String) -> bool: return z != zone), "Find the pointer, then the coloured zone above it.",
			"%s °C is in the %s." % [_temp(t), zone] if zone != "hot" else "%s °C is hot: 63 °C and above." % _temp(t),
			{"kind": "food_thermo", "value": t})
	else:
		ex = K.choice(rng, "%s Which zone is it in?" % (str(c[1]) % _temp(t)), zone, zones.filter(
			func(z: String) -> bool: return z != zone),
			"Freezer: −18 °C or colder. Fridge: 0 to 5 °C. Danger zone: above 5 °C and below 63 °C. Hot: 63 °C and above.",
			"%s °C: the %s.%s" % [_temp(t), zone, " Bacteria grow fast here: chill it or heat it." if zone == "danger zone" else ""])
	ex.data = {"t": t}
	return ex


## Bacteria that split every 20 minutes: level 1, count the rows; level 2, from a few; level 3, how long to reach a
## number.
static func microbe_double(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var steps := rng.randi_range(1, 3) if level == 1 else rng.randi_range(3, 5)
		var start := 1 if level == 1 else rng.randi_range(1, 3)
		var minutes := steps * 20
		var n := start * int(pow(2, steps))
		ex = K.number("%s in warm food split%s in two every 20 minutes. How many are there after %d minutes?" % [
			"One bacterium" if start == 1 else "%d bacteria" % start, "s" if start == 1 else "", minutes], n,
			"How many lots of 20 minutes are there? Double that many times.",
			"%d minutes is %d lot%s of 20 minutes: %d doubled %s is %d." % [minutes, steps, "" if steps == 1 else "s", start,
				"once" if steps == 1 else "%d times" % steps, n],
			{"kind": "microbe_split", "steps": steps} if level == 1 else {})
		ex.data = {"start": start, "minutes": minutes, "ask": "count"}
	else:
		var start := rng.randi_range(1, 2)
		var steps := rng.randi_range(4, 6)
		var target := start * int(pow(2, steps))
		ex = K.number("%s split%s in two every 20 minutes. How many minutes until there are %d?" % [
			"One bacterium" if start == 1 else "%d bacteria" % start, "s" if start == 1 else "", target], steps * 20,
			"Keep doubling and count the doublings.",
			"%d doubles %d times to make %d: %d × 20 = %d minutes. That is why food goes in the fridge quickly." % [start,
				steps, target, steps, steps * 20])
		ex.data = {"start": start, "target": target, "ask": "time"}
	return ex


## Date labels: level 1, "use by" (safety); level 2, "best before" (quality); level 3, which food goes in the bin.
static func date_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var today := rng.randi_range(8, 24)
	var ex: Dictionary
	if level < 3:
		var label := "use by" if level == 1 else "best before"
		var foods: Array = USE_BY if level == 1 else BEST_BEFORE
		var food := str(foods[rng.randi_range(0, foods.size() - 1)])
		var date := today + (rng.randi_range(1, 5) * (1 if rng.randf() < 0.5 else -1))
		var claim := "safe" if rng.randf() < 0.5 else "bin"
		var safe := label == "best before" or today <= date
		var text := "It is safe to eat." if claim == "safe" else "It must go in the bin."
		ex = K.truefalse("Today is %d March. The label on %s says '%s %d March', and it has been kept as the label says. %s" % [
			today, food, label, date, text], safe if claim == "safe" else not safe,
			"'Use by' is about safety: never after the date. 'Best before' is about quality: still safe, maybe not as nice.",
			"%s: '%s %d March' %s" % ["True" if (safe if claim == "safe" else not safe) else "False", label, date,
				("is past, so it is not safe to eat." if today > date else "is still to come, so it is safe.")
				if label == "use by" else "is about quality, so it is still safe to eat, just maybe not at its best."])
		ex.data = {"today": today, "date": date, "label": label, "claim": claim}
		return ex
	var uses := USE_BY.duplicate()
	var bests := BEST_BEFORE.duplicate()
	K.shuffle(rng, uses)
	K.shuffle(rng, bests)
	var items: Array = [[uses[0], "use by", today - rng.randi_range(1, 4)], [uses[1], "use by", today + rng.randi_range(1, 4)],
		[bests[0], "best before", today - rng.randi_range(1, 6)], [bests[1], "best before", today + rng.randi_range(1, 6)]]
	K.shuffle(rng, items)
	var answer := items.find(items.filter(func(it: Array) -> bool: return str(it[1]) == "use by" and int(it[2]) < today)[0])
	ex = {"type": "choice", "prompt": "Today is %d March. Which one must go in the bin?" % today,
		"choices": items.map(func(it: Array) -> String: return "%s: %s %d March" % it), "answer": answer,
		"hint": "Only 'use by' is about safety. Is its date already past?",
		"explain": "%s: its 'use by' date, %d March, is past. The 'best before' foods are still safe." % [_cap(str(items[answer][0])),
			items[answer][2]]}
	ex.data = {"today": today, "items": items}
	return ex


# --- Design and technology: cook on a budget (g6.design_tech.cook_on_a_budget) -----------------------------------

## Prices per 100 g: level 1, one pack's; levels 2-3, the best value of two or three packs.
static func unit_price(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var food := str(PACK_FOODS[rng.randi_range(0, PACK_FOODS.size() - 1)])
	var ex: Dictionary
	if level == 1:
		var grams := [200, 400, 500, 1000][rng.randi_range(0, 3)] as int
		var per := rng.randi_range(5, 40) * 2   # hundredths of a gold per 100 g
		var price := per * grams / 100
		ex = K.number("A %s bag of %s costs %s gold. What is the price for each 100 g, in gold?" % [_kg(grams), food,
			_gold(price)], _gold(per), "How many lots of 100 g are in the bag? Share the price between them.",
			"%d g is %d lots of 100 g, and %s ÷ %d = %s gold for each 100 g." % [grams, grams / 100, _gold(price),
				grams / 100, _gold(per)])
		ex.data = {"grams": grams, "price": price}
		return ex
	var sizes: Array = [250, 500, 1000, 2000]
	K.shuffle(rng, sizes)
	var packs: Array = []
	var pers: Array = []
	for _try in 100:
		packs.clear()
		pers.clear()
		for i in level:
			var g := int(sizes[i])
			var per := rng.randi_range(10, 40) * 4
			packs.append(["the %s bag" % (_kg(g)), g, per * g / 100])
			pers.append(per)
		var s: Array = pers.duplicate()
		s.sort()
		var distinct := true
		for i in s.size() - 1:
			distinct = distinct and int(s[i + 1]) - int(s[i]) >= 4
		if distinct:
			break
	var best := pers.find(pers.min())
	ex = K.choice(rng, "Bags of %s: %s. Which bag is the best value?" % [food, _and(packs.map(
		func(p: Array) -> String: return "%s costs %s gold" % [p[0], _gold(int(p[2]))]))],
		str(packs[best][0]), packs.filter(func(p: Array) -> bool: return str(p[0]) != str(packs[best][0])).map(
			func(p: Array) -> String: return str(p[0])),
		"Work out the price for each 100 g of every bag, then compare.",
		"%s. The lowest price for each 100 g is the best value." % _cap("; ".join(PackedStringArray(packs.map(
			func(p: Array) -> String: return "%s: %s gold for each 100 g" % [p[0], _gold(int(p[2]) * 100 / int(p[1]))])))))
	ex.data = {"packs": packs}
	return ex


## A meal's cost: level 1, a portion's share of a dish; level 2, of three ingredients; level 3, a budget's change.
static func portion_cost(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var who := _who(rng)
	match level:
		1:
			var portions := rng.randi_range(2, 6)
			var per := rng.randi_range(4, 30) * 10
			var dish := ["a pot of soup", "a vegetable curry", "a pasta bake", "a lentil stew"][rng.randi_range(0, 3)] as String
			ex = K.number("%s for %d people costs %s gold. What is the cost per portion, in gold?" % [_cap(dish),
				portions, _gold(per * portions)], _gold(per), "Share the total cost equally between the portions.",
				"%s ÷ %d = %s gold per portion." % [_gold(per * portions), portions, _gold(per)])
			ex.data = {"total": per * portions, "portions": portions}
		2:
			var portions := rng.randi_range(2, 5)
			var sum := rng.randi_range(12, 50) * 10 * portions
			var c1 := rng.randi_range(3, sum / 30) * 10
			var c2 := rng.randi_range(3, maxi(3, (sum - c1) / 20)) * 10
			if c1 + c2 >= sum - 30:
				c1 = sum / 3 / 10 * 10
				c2 = sum / 3 / 10 * 10
			var costs: Array = [c1, c2, sum - c1 - c2]
			var names: Array = ["pasta", "tomatoes", "cheese", "onions", "beans"]
			K.shuffle(rng, names)
			ex = K.number("A pasta bake for %d: %s. What is the cost per portion, in gold?" % [portions, _and(range(3).map(
				func(i: int) -> String: return "%s %s gold" % [names[i], _gold(int(costs[i]))]))], _gold(sum / portions),
				"Add the costs to find the whole dish, then share it between the portions.",
				"%s = %s gold, and %s ÷ %d = %s gold per portion." % [" + ".join(PackedStringArray(costs.map(
					func(c: int) -> String: return _gold(c)))), _gold(sum), _gold(sum), portions, _gold(sum / portions)])
			ex.data = {"costs": costs, "portions": portions}
		_:
			var people := rng.randi_range(3, 6)
			var per := rng.randi_range(10, 40) * 10
			var budget := (per * people / 100 + rng.randi_range(1, 6)) * 100
			ex = K.number("%s has %s gold to cook for %d people. The meal costs %s gold a portion. How much gold is left?" % [
				who, _gold(budget), people, _gold(per)], _gold(budget - per * people),
				"Work out the cost for everyone first, then take it away from the budget.",
				"%d × %s = %s gold, and %s − %s = %s gold left." % [people, _gold(per), _gold(per * people), _gold(budget),
					_gold(per * people), _gold(budget - per * people)])
			ex.data = {"budget": budget, "per": per, "people": people}
	return ex


# --- Design and technology: material families (g6.design_tech.material_families) --------------------------------

## Material families: level 1, wood, metal, plastic or composite; level 2, hardwood, softwood or board, ferrous or
## non-ferrous, thermoplastic or thermoset; level 3, sort two of those.
static func material_family(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var pair: Array = SUB_PAIRS[rng.randi_range(0, SUB_PAIRS.size() - 1)]
		var k := rng.randi_range(2, 3)
		var items: Array = []
		for g in 2:
			var of: Array = MATERIAL_SUB.keys().filter(func(m: String) -> bool: return str(MATERIAL_SUB[m]) == str(pair[g]))
			K.shuffle(rng, of)
			for m: Variant in of.slice(0, k if g == 0 else 5 - k):
				items.append([str(m), str(pair[g])])
		ex = _sort(rng, "Sort the materials: %s or %s?" % pair, pair, items, _sub_hint(str(pair[0])),
			"%s: %s. %s: %s." % [_cap(str(pair[0])), _and(_in_group(items, str(pair[0]))),
				_cap(str(pair[1])), _and(_in_group(items, str(pair[1])))])
		ex.data = {"pair": pair}
		return ex
	var pool: Array = MATERIAL_FAMILY.keys() if level == 1 else MATERIAL_SUB.keys()
	var m := str(pool[rng.randi_range(0, pool.size() - 1)])
	var pic := {"kind": "material_swatch", "samples": [SWATCH[m]]} if SWATCH.has(m) else {}
	if level == 1:
		var fam := str(MATERIAL_FAMILY[m])
		ex = K.choice(rng, "Which family of materials is %s in?" % m, fam, ["wood", "metal", "plastic", "composite"].filter(
			func(f: String) -> bool: return f != fam), "Woods come from trees, metals from ores, plastics mostly from oil, and composites join materials.",
			"%s is in the %s family%s." % [_cap(m), fam, _family_note(m)], pic)
	else:
		var sub := str(MATERIAL_SUB[m])
		var fam := str(MATERIAL_FAMILY[m])
		var choices: Array = (SUB_OF[fam] as Array).filter(func(s: String) -> bool: return s != sub)
		if choices.size() < 2:
			choices.append("composite")
		ex = K.choice(rng, "%s is in the %s family. Which kind of %s is it?" % [_cap(m), fam, fam], sub, choices,
			_sub_hint(sub), "%s is %s %s: %s" % [_cap(m),
				"an" if sub.begins_with("a") or sub.begins_with("e") else "a", sub, _sub_why(sub)], pic)
	ex.data = {"material": m}
	return ex


static func _family_note(m: String) -> String:
	match m:
		"plywood", "MDF", "chipboard":
			return ": a manufactured board, made from wood"
		"melamine", "epoxy resin", "urea formaldehyde":
			return ": a thermoset plastic"
		"carbon fibre", "concrete", "glass-reinforced plastic", "reinforced concrete":
			return ": two or more materials joined to work better together"
	return ""


static func _sub_hint(sub: String) -> String:
	if sub in ["hardwood", "softwood", "manufactured board"]:
		return "Hardwoods come from broad-leaved trees, softwoods from conifers; boards are made from wood fibres, chips or layers."
	if sub in ["ferrous", "non-ferrous"]:
		return "Ferrous metals contain iron, so most are magnetic and can rust."
	return "Thermoplastics soften when heated and can be reshaped; thermosets set hard for good."


static func _sub_why(sub: String) -> String:
	match sub:
		"hardwood":
			return "it comes from a broad-leaved tree."
		"softwood":
			return "it comes from a conifer, with needles and cones."
		"manufactured board":
			return "it is made from wood fibres, chips or thin layers glued together."
		"ferrous":
			return "it contains iron."
		"non-ferrous":
			return "it contains no iron, so it does not rust."
		"thermoplastic":
			return "it softens when heated and can be shaped again."
	return "once set, heat will not soften it again."


## Density = mass ÷ volume: level 1, a block's volume; level 2, a density; level 3, float or sink (water: 1 g/cm³).
static func density_float(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var l := rng.randi_range(2, 12)
			var w := rng.randi_range(2, 10)
			var h := rng.randi_range(1, 5)
			ex = K.number("A block is %d cm long, %d cm wide and %d cm high. What is its volume, in cm³?" % [l, w, h], l * w * h,
				"Volume = length × width × height.", "%d × %d × %d = %d cm³." % [l, w, h, l * w * h])
			ex.data = {"l": l, "w": w, "h": h}
		2:
			var volume := [20, 25, 40, 50, 100, 200][rng.randi_range(0, 5)] as int
			var d := 0   # hundredths of a g/cm³
			var mass := 0
			for _try in 200:
				d = rng.randi_range(15, 300)
				if d * volume % 100 == 0:
					break
			if d * volume % 100 != 0:
				d = 100
			mass = d * volume / 100
			ex = K.number("A block has a volume of %d cm³ and a mass of %d g. What is its density, in g/cm³?" % [volume, mass],
				_num_text(float(mass) / volume), "Density = mass ÷ volume.",
				"%d ÷ %d = %s g/cm³." % [mass, volume, _num_text(float(mass) / volume)])
			ex.data = {"mass": mass, "volume": volume}
		_:
			var names: Array = DENSITY.keys()
			var m := str(names[rng.randi_range(0, names.size() - 1)])
			var volume := [100, 200, 300, 500][rng.randi_range(0, 3)] as int
			var mass := int(round(float(DENSITY[m]) * volume))
			var floats := mass < volume
			ex = K.choice(rng, "A block of %s has a volume of %d cm³ and a mass of %d g. Does it float or sink in water?" % [m,
				volume, mass], "it floats" if floats else "it sinks", ["it sinks" if floats else "it floats"],
				"Work out the density. Water's density is 1 g/cm³: less floats, more sinks.",
				"%d ÷ %d = %s g/cm³, %s than water's 1 g/cm³, so it %s." % [mass, volume, _num_text(float(mass) / volume),
					"less" if floats else "more", "floats" if floats else "sinks"])
			ex.data = {"mass": mass, "volume": volume, "material": m}
	return ex


# --- Design and technology: design movements (g6.design_tech.design_movements) ----------------------------------

## Arts and Crafts or Bauhaus: levels 1-2, sort 4 or 6 features; level 3, years between two events.
static func style_sort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var n := 2 if level == 1 else 3
		var items: Array = []
		for style: String in ["Arts and Crafts", "Bauhaus"]:
			var f: Array = (STYLE_FEATURES[style] as Array).duplicate()
			K.shuffle(rng, f)
			for x: Variant in f.slice(0, n):
				items.append([str(x), style])
		ex = _sort(rng, "Arts and Crafts or Bauhaus? Sort the features.", ["Arts and Crafts", "Bauhaus"], items,
			"Arts and Crafts: handmade, natural and decorated. Bauhaus: machine-made, simple and geometric.",
			"Arts and Crafts: %s. Bauhaus: %s." % [_and(_in_group(items, "Arts and Crafts")), _and(_in_group(items,
				"Bauhaus"))])
		ex.data = {}
		return ex
	var a: Array = []
	var b: Array = []
	for _try in 100:
		a = DESIGN_YEARS[rng.randi_range(0, DESIGN_YEARS.size() - 1)]
		b = DESIGN_YEARS[rng.randi_range(0, DESIGN_YEARS.size() - 1)]
		if int(b[1]) > int(a[1]):
			break
	var gap := int(b[1]) - int(a[1])
	ex = K.number("%s in %d, and %s in %d. How many years apart were they?" % [_cap(str(a[0])).substr(0, 1) +
		str(a[0]).substr(1), int(a[1]), b[0], int(b[1])], gap, "Take the earlier year away from the later year.",
		"%d − %d = %d years." % [int(b[1]), int(a[1]), gap])
	ex.data = {"first": a[0], "then": b[0]}
	return ex


# --- Projects -----------------------------------------------------------------------------------------------------

## A medieval market's prices: level 1, at the same rate; level 2, a toll as a percentage; level 3, sharing in a ratio.
static func market_price(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var goods := str(MARKET_GOODS[rng.randi_range(0, MARKET_GOODS.size() - 1)])
	match level:
		1:
			var unit := rng.randi_range(2, 9)
			var n := rng.randi_range(2, 6)
			var m := rng.randi_range(2, 12)
			while m == n:
				m += 1
			ex = K.number("At the market, %d %s cost %d gold. What do %d %s cost at the same rate?" % [n, goods, n * unit,
				m, goods], m * unit, "Find the price of one first, then multiply.",
				"One costs %d ÷ %d = %d gold, so %d cost %d × %d = %d gold." % [n * unit, n, unit, m, m, unit, m * unit])
			ex.data = {"n": n, "cost": n * unit, "m": m}
		2:
			var percent := [5, 10, 20, 25][rng.randi_range(0, 3)] as int
			var price := rng.randi_range(4, 40) * (4 if percent == 25 else 2 if percent == 5 else 1)
			var toll := price * percent / 100.0
			ex = K.number("The town charges a toll of %d%% on every sale at the market. A trader sells %s for %d gold. What is the toll, in gold?" % [
				percent, goods, price], _num_text(toll), "Per cent means out of 100. Find 1% or 10% first.",
				"%d%% of %d = %d × %d ÷ 100 = %s gold." % [percent, price, price, percent, _num_text(toll)])
			ex.data = {"price": price, "percent": percent}
		_:
			var a := rng.randi_range(1, 4)
			var b := rng.randi_range(1, 5)
			while b == a:
				b += 1
			var total := (a + b) * rng.randi_range(3, 12)
			ex = K.number("Two guild members share %d gold of profit in the ratio %d : %d. How much does the second get?" % [
				total, a, b], total * b / (a + b), "Add the parts of the ratio, and find what one part is worth.",
				"%d + %d = %d parts, one part is %d ÷ %d = %d gold, so the second gets %d × %d = %d gold." % [a, b, a + b,
					total, a + b, total / (a + b), b, total / (a + b), total * b / (a + b)])
			ex.data = {"total": total, "a": a, "b": b}
	return ex


## A weather station's log: level 1, a week's rain; level 2, a spreadsheet's mean temperature; level 3, a winter
## week's range.
static func weather_week(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var rain: Array = []
			var sum := 0
			for i in 7:
				var r := rng.randi_range(0, 9) if rng.randf() < 0.7 else 0
				rain.append(r)
				sum += r
			ex = K.number("A rain gauge's readings, Monday to Sunday, in mm: %s. How much rain fell in the week?" % ", ".join(
				PackedStringArray(rain.map(func(r: int) -> String: return str(r)))), sum, "Add the seven days' rain.",
				"%s = %d mm." % [" + ".join(PackedStringArray(rain.map(func(r: int) -> String: return str(r)))), sum])
			ex.data = {"rain": rain}
		2:
			var temps: Array = []
			var sum := 0
			for _try in 200:
				temps.clear()
				sum = 0
				for i in 5:
					var t := rng.randi_range(6, 22)
					temps.append(t)
					sum += t
				if sum % 5 == 0:
					break
			var days: Array = ["Mon", "Tue", "Wed", "Thu", "Fri"]
			var cells: Array = [["Day", "Temp (°C)"]]
			for i in 5:
				cells.append([days[i], str(temps[i])])
			cells.append(["Mean", "=AVERAGE(B2:B6)"])
			ex = K.number("A weather station's spreadsheet. What will cell B7 show?", sum / 5,
				"=AVERAGE adds the cells and divides by how many there are.",
				"%s = %d, and %d ÷ 5 = %d °C." % [" + ".join(PackedStringArray(temps.map(func(t: int) -> String:
					return str(t)))), sum, sum, sum / 5],
				{"kind": "sheet", "cells": cells, "mark": "B7", "show": "formulas"})
			ex.data = {"temps": temps}
		_:
			var high := rng.randi_range(2, 14)
			var low := rng.randi_range(-7, 1)
			ex = K.number("One winter week, the highest temperature was %s °C and the lowest was %s °C. What was the range, in °C?" % [
				_temp(high), _temp(low)], high - low, "Range = highest − lowest. Count up from the lowest to 0, then on.",
				"From %s °C up to 0 is %d, and from 0 up to %d is %d more: %d °C." % [_temp(low), -low if low < 0 else 0,
					high, high, high - low] if low < 0 else "%d − %d = %d °C." % [high, low, high - low])
			ex.data = {"high": high, "low": low}
	return ex


## A decision matrix: level 1, the best total; level 2, one idea's total; level 3, with function counting double.
static func decision_matrix(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var rows: Array = []
	var weights: Array = [1, 1, 2] if level == 3 else []
	var totals: Array = []
	for _try in 200:
		rows.clear()
		totals.clear()
		for i in 3:
			var row: Array = [IDEAS[i]]
			var t := 0
			for k in 3:
				var s := rng.randi_range(1, 5)
				row.append(s)
				t += s * (int(weights[k]) if not weights.is_empty() else 1)
			rows.append(row)
			totals.append(t)
		var s: Array = totals.duplicate()
		s.sort()
		if int(s[0]) != int(s[1]) and int(s[1]) != int(s[2]):
			break
	var table: Array = [["idea"] + CRITERIA]
	for r: Array in rows:
		table.append(r.map(func(v: Variant) -> String: return str(v)))
	var best := totals.find(totals.max())
	var ex: Dictionary
	if level == 2:
		var ask := rng.randi_range(0, 2)
		var row: Array = rows[ask]
		ex = K.number("The decision matrix scores each idea from 1 to 5. What is %s's total score?" % IDEAS[ask],
			int(row[1]) + int(row[2]) + int(row[3]), "Add the idea's scores along its row.",
			"%d + %d + %d = %d." % [int(row[1]), int(row[2]), int(row[3]), int(row[1]) + int(row[2]) + int(row[3])],
			{"kind": "table", "rows": table})
		ex.data = {"rows": rows, "ask": ask}
		return ex
	var why := "; ".join(PackedStringArray(range(3).map(func(i: int) -> String: return "%s %d" % [IDEAS[i], totals[i]])))
	ex = K.choice(rng, "Which idea wins the decision matrix%s?" % (", if 'use' counts double" if level == 3 else ""),
		str(IDEAS[best]), IDEAS.filter(func(i: String) -> bool: return i != str(IDEAS[best])),
		"Add each idea's scores%s. The highest total wins." % (", counting 'use' twice" if level == 3 else ""),
		"%s: %s wins." % [_cap(why), IDEAS[best]], {"kind": "table", "rows": table})
	ex.data = {"rows": rows, "weights": weights} if level == 3 else {"rows": rows}
	return ex


# --- Helpers ------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return PEOPLE[rng.randi_range(0, PEOPLE.size() - 1)]


## `s` with its first letter a capital (capitalize() would capitalise every word).
static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


## "a, b and c".
static func _and(items: Array) -> String:
	var words: Array = items.map(func(x: Variant) -> String: return str(x))
	if words.size() <= 1:
		return "".join(PackedStringArray(words))
	return ", ".join(PackedStringArray(words.slice(0, words.size() - 1))) + " and " + str(words[-1])


## Tenths as a decimal: 152 -> "15.2".
static func _tenths(t: int) -> String:
	return "%d.%d" % [t / 10, t % 10]


## Hundredths as a decimal: 312 -> "3.12".
static func _hundredths(t: int) -> String:
	return "%d.%02d" % [t / 100, t % 100]


## Halves of a km as the table writes them: 5 -> "2.5", 4 -> "2".
static func _halves(h: int) -> String:
	return str(h / 2) if h % 2 == 0 else "%d.5" % (h / 2)


## Hundredths of a gold as the lessons write gold: 250 -> "2.50", 300 -> "3".
static func _gold(h: int) -> String:
	return str(h / 100) if h % 100 == 0 else "%d.%02d" % [h / 100, h % 100]


## A mass for a bag's name: 250 -> "250 g", 1000 -> "1 kg".
static func _kg(g: int) -> String:
	return "%d kg" % (g / 1000) if g % 1000 == 0 else "%d g" % g


## A temperature as the School writes it: −5 (the minus sign), 12.
static func _temp(t: int) -> String:
	return ("−%d" % -t) if t < 0 else str(t)


## A number without trailing zeros: 0.5, 1.25, 3.
static func _num_text(v: float) -> String:
	var s := "%.2f" % v
	s = s.rstrip("0").rstrip(".")
	return s


## The texts of the [text, group] items in `group`.
static func _in_group(items: Array, group: String) -> Array:
	var out: Array = []
	for it: Array in items:
		if str(it[1]) == group:
			out.append(str(it[0]))
	return out


## A sort exercise: `items` are [text, group]; shown shuffled.
static func _sort(rng: RandomNumberGenerator, prompt: String, groups: Array, items: Array, hint: String,
		explain: String) -> Dictionary:
	var shown := items.duplicate()
	K.shuffle(rng, shown)
	return {"type": "sort", "prompt": prompt, "groups": groups, "items": shown.map(func(it: Array) -> String:
		return str(it[0])), "answer": shown.map(func(it: Array) -> int: return groups.find(it[1])), "hint": hint,
		"explain": explain}


## A match exercise: items[i] matches matches[i]; the matches are shown in another order (never side by side).
static func _match(rng: RandomNumberGenerator, prompt: String, items: Array, matches: Array, hint: String,
		explain: String) -> Dictionary:
	var order: Array = range(matches.size())
	for _i in 10:
		K.shuffle(rng, order)
		if order != range(matches.size()):
			break
	if order == range(matches.size()):
		order.reverse()
	var shown: Array = order.map(func(i: int) -> String: return str(matches[i]))
	return {"type": "match", "prompt": prompt, "items": items, "matches": shown,
		"answer": range(items.size()).map(func(i: int) -> int: return order.find(i)), "hint": hint, "explain": explain}
