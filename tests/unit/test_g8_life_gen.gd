extends GutTest
## Owner #70, #73 and #111, grade 8 health and PE, D&T and projects generators (G8LifeGen, SchoolGen source "g8l"):
## every generator makes a valid exercise at every level for 120 seeds, with a strategy hint, a worked answer and its
## `data`, and every answer is worked out again here from `data` with this test's own rules and facts: formations,
## pass completion and possession, fitness tests and their best, mean and improvement, a profile's weakest part, a week's
## moderate minutes, a wheel's chance and expected win, a mystery box's odds, CPR's counts, survey percentages, screen
## time, a making plan's end, cutting lists and tolerances, mass and density, thresholds and conditions, battery life,
## levers' moments, gear trains, a block and tackle's effort and efficiency, velocity ratio, factors of safety, label
## portions, food footprints, cost per year, standby energy, a parts budget, animation frames, the years between turning
## points, litter rates and samples, and a scatter graph's correlation; and the facts behind every choice, sort, match
## and order.

const SEEDS := 120
const SOURCE := "g8l."

## This test's own facts.
const TACTIC_BEST := {"Your team is losing 1-0 with ten minutes left.": "add an attacker and push higher up",
	"Your team is winning 2-1 and the game is nearly over.": "keep a compact shape and keep the ball",
	"The other team's best player keeps finding space in midfield.": "mark them closely and close the space",
	"The other team has three in midfield against your two, and you keep losing the ball there.":
		"add a midfielder, such as 4-5-1",
	"Their defenders are tall and win every high cross.": "pass along the ground and cross low",
	"Their defence pushes up high, leaving space behind it.": "make runs and pass into the space behind",
	"In netball, the other team keeps intercepting your long passes.": "use short passes and move into space",
	"In badminton, your opponent is strong at the back but slow to the net.": "mix deep clears with drop shots",
	"In rounders, the batters hit most balls to the left side.": "move more fielders to the left",
	"You lead 1-0, then the other team switches to three strikers.": "drop a midfielder back to defend"}
const TEST_PART := {"multistage fitness test": "stamina", "Cooper 12-minute run": "stamina",
	"sit-and-reach test": "flexibility", "hand-grip test": "strength", "30 m sprint": "speed",
	"Illinois agility run": "agility", "stork stand": "balance", "vertical jump": "power",
	"one-minute press-up test": "muscular endurance", "ruler drop test": "reaction time"}
const TIMED: Array[String] = ["30 m sprint", "Illinois agility run"]
const VIGOROUS: Array[String] = ["runs", "games of football", "fast swims"]
const STRENGTH: Array[String] = ["press-ups", "squats", "resistance-band exercises", "pull-ups", "lunges", "sit-ups"]
const SPORT_KIND := {"football": "team", "netball": "team", "hockey": "team", "basketball": "team", "swimming": "solo",
	"running": "solo", "gymnastics": "solo", "yoga": "solo", "climbing": "outdoor adventure",
	"kayaking": "outdoor adventure", "orienteering": "outdoor adventure", "hill walking": "outdoor adventure"}
const TRAP_OF := {"If I get one answer wrong, the whole test is ruined.": "all-or-nothing",
	"I'm either brilliant at football or useless.": "all-or-nothing",
	"They didn't reply, so they must be angry with me.": "mind reading",
	"Everyone thinks my idea was silly.": "mind reading", "I'll definitely mess up my solo tomorrow.": "fortune telling",
	"I just know I won't get into the team.": "fortune telling",
	"My friend is late, something terrible must have happened.": "catastrophising",
	"If I miss the bus, my whole day will be a disaster.": "catastrophising"}
const BALANCED_OF := {"If I get one answer wrong, the whole test is ruined.": "One wrong answer is one mark, not all.",
	"I'm either brilliant at football or useless.": "I'm good at some skills, still learning others.",
	"They didn't reply, so they must be angry with me.": "They might be busy; I can ask them.",
	"Everyone thinks my idea was silly.": "I don't know what they think unless I ask.",
	"I'll definitely mess up my solo tomorrow.": "I've practised; it may well go fine.",
	"I just know I won't get into the team.": "I can't know yet; I'll do my best at the trial.",
	"My friend is late, something terrible must have happened.": "They're probably just held up.",
	"If I miss the bus, my whole day will be a disaster.": "If I miss it, I'll catch the next one."}
const TRAP_SHORT := {"one wrong answer ruins it all": "all-or-nothing", "brilliant or useless": "all-or-nothing",
	"no reply: they must be angry": "mind reading", "everyone thinks my idea is silly": "mind reading",
	"I'll definitely mess up my solo": "fortune telling", "I know I won't get in the team": "fortune telling",
	"they're late: disaster!": "catastrophising", "miss the bus: my day is ruined": "catastrophising"}
const HELPFUL: Array[String] = ["talking to a trusted adult", "going for a walk outside", "box breathing for a minute",
	"writing worries down", "a regular bedtime", "breaking a job into small steps", "doing something kind for someone"]
const HELP_BEST := {"Bram has felt low and lost interest in everything for over two weeks.":
	"talk to a trusted adult or a GP soon",
	"A friend says they feel very low, and asks you to keep it secret.": "listen, then help them tell a trusted adult",
	"Before a test, Zara's heart races and her hands shake.": "slow breaths, then start with an easy question",
	"Mimi is worried about a party where she knows few people.": "go with a friend and plan what to say",
	"Someone tells you they want to hurt themselves.": "tell a trusted adult straight away"}
const P_TRAP_OF := {"I'll never be good at this.": "forever", "I always lose.": "forever",
	"I'm bad at everything.": "everything", "This ruins my whole week.": "everything",
	"We lost and it's all my fault.": "all me", "The test went badly because I'm hopeless.": "all me"}
const REFRAME_OF := {"I'll never be good at this.": "This is hard now; practice will help.",
	"I always lose.": "I lost today; next time can be different.", "I'm bad at everything.":
	"Maths was hard today; art went well.", "This ruins my whole week.": "One bad match is one part of my week.",
	"We lost and it's all my fault.": "We all made mistakes; they played well.",
	"The test went badly because I'm hopeless.": "The test was hard; I can prepare better."}
const P_SHORT := {"I'll never be good at this": "forever", "I always lose": "forever", "I'm bad at everything": "everything",
	"This ruins my whole week": "everything", "We lost and it's all my fault": "all me",
	"it went badly: I'm hopeless": "all me"}
const BOUNCE: Array[String] = ["notice the feeling", "calm your body", "look at what happened", "plan one next step",
	"try again"]
const WENT_WELL: Array[String] = ["my passes were accurate", "I kept trying to the end", "I warmed up properly",
	"I asked for help early"]
const SETBACK_BEST := {"Tilly didn't get a part in the school play.": "ask for feedback and help backstage",
	"Bram's model bridge broke in testing.": "find where it broke and strengthen it",
	"Zara's test score was lower than she hoped.": "find the questions she missed and practise them",
	"Mo lost a tennis match 6-1.": "keep what worked, practise one weak shot"}
const HEALTHY: Array[String] = ["respects it when you say no", "is happy for you to see other friends",
	"asks before sharing your photo", "gives you time to reply", "is kind in public and in private"]
const ONLINE_BEST := {"Someone you met online asks you to keep your chats secret and send a photo.":
	"don't send it; tell a trusted adult",
	"A private picture of a classmate is shared in a group chat.": "don't forward it; tell a trusted adult",
	"Your friend posts a photo of you that you don't like.": "ask them kindly to take it down",
	"Someone threatens to share a picture of you unless you send more.": "send nothing; tell an adult; report to CEOP",
	"Before posting a group photo with your friends, you should…": "ask everyone in it",
	"Your friend says no when you ask to post their photo.": "accept the no and don't post it",
	"A group chat starts making fun of a classmate.": "don't join in; support them; tell an adult",
	"You see a hateful comment about someone's religion.": "report it and check the person is okay"}
const REPORT: Array[String] = ["don't reply", "keep the evidence", "block the person", "report it", "tell a trusted adult"]
const CHANCE_IS := {"A fair wheel has no memory of the last spin.": true,
	"Over time, the people running it expect to win.": true, "A near miss is still a loss.": true,
	"Chasing losses usually means losing more.": true, "In the UK, most gambling is for adults only.": true,
	"A mystery box sells a chance, not a prize.": true, "After five reds in a row, black is due.": false,
	"A lucky charm makes winning more likely.": false, "Keep playing and you're bound to win it back.": false,
	"A near miss means you're about to win.": false, "Each loss makes the next win more likely.": false}
const PRESSURE_OF := {"A friend says, 'Go on, everyone else is.'": "direct",
	"Someone dares you in front of the group.": "direct", "An older teen offers you a drink of alcohol.": "direct",
	"Your friends all start vaping at the park.": "indirect",
	"The party photos show everyone drinking.": "indirect",
	"A video makes vaping look grown-up and cool.": "indirect", "You want to look older than you are.": "from inside",
	"You worry you'll be left out if you say no.": "from inside",
	"You think saying yes will make you popular.": "from inside"}
const LAW_IS := {"In the UK it is against the law to sell alcohol to anyone under 18.": true,
	"Shops must not sell vapes or tobacco to anyone under 18.": true, "Nicotine is addictive.": true,
	"Alcohol affects judgement, balance and memory.": true, "Vapes are made for young people to try.": false,
	"Most young people your age drink alcohol every week.": false,
	"The police can take alcohol away from under-18s in public.": true,
	"The brain keeps developing until about the age of 25.": true,
	"Single-use vapes are banned from sale in the UK.": true,
	"Alcohol warms you up and keeps you safe in the cold.": false, "Coffee or a cold shower sobers someone up.": false,
	"In the UK, anyone over 16 can buy alcohol in a shop.": false}
const LAW_ANSWER := {"From what age can someone buy alcohol in the UK?": "18",
	"Which substance in most vapes is addictive?": "nicotine",
	"Until about what age does the brain keep developing?": "about 25",
	"What do the UK's top doctors advise for children?": "an alcohol-free childhood",
	"Someone has drunk too much and is very unwell. What helps?": "call 999 and stay with them"}
const REFUSAL_OF := {"'No thanks.' 'No thanks.' 'No thanks.'": "broken record",
	"'No, I've got training early.'": "give a reason", "'No. Let's get chips instead.'": "suggest something else",
	"'No way, I'm allergic to bad ideas!'": "use humour", "Saying no, then leaving the group.": "walk away",
	"Texting home a word that means 'pick me up'.": "a code word"}
const REFUSAL_SHORT := {"'No thanks' again and again": "broken record", "'No, I've got training early.'": "give a reason",
	"'No. Let's get chips instead.'": "suggest something else", "'I'm allergic to bad ideas!'": "use humour",
	"saying no, then leaving": "walk away", "a text home: 'pick me up'": "a code word"}
const REFUSE_BEST := {"At a party, friends keep asking even after you say no.": "leave, and text your code word home",
	"A friend offers you a vape on the way home.": "say 'No thanks' and suggest something else",
	"Someone says everyone your age drinks.": "say most don't, and say no"}
const CPR: Array[String] = ["check for danger", "check for a response", "shout for help", "open the airway",
	"check breathing for 10 seconds", "call 999 and get a defibrillator", "start CPR"]
const CPR_BEST := {"Someone collapses. They don't respond and aren't breathing normally.": "call 999 and start CPR",
	"Someone doesn't respond but is breathing normally.": "the recovery position, and call 999",
	"The defibrillator says 'Shock advised'.": "make sure nobody is touching them",
	"You're tiring during CPR and someone else can help.": "swap over with hardly a pause",
	"A defibrillator arrives while you're doing CPR.": "switch it on and follow its voice"}
const SMART_AIMS: Array[String] = ["60% of Year 9 drink water at lunch by July",
	"Double the pupils who cycle to school by June", "80% of Year 8 eat breakfast by half term"]
const CAMPAIGN: Array[String] = ["survey to find the problem", "set a SMART aim", "choose your audience and message",
	"run the campaign", "survey again and compare"]
const MESSAGE_BEST := {"more sleep": "Screens off at 9, sleep by 10: wake up sharper",
	"water": "Refill at the fountain: water helps you focus",
	"walking to school": "Walk together on Wednesdays: 20 minutes, done"}
const HELPS_FOCUS: Array[String] = ["phone in another room while studying", "notifications off at night",
	"one task at a time", "a 5-minute break after 25 minutes", "screens off an hour before bed",
	"charging the phone outside the bedroom"]
const TRICK_DOES := {"autoplay": "starts the next video by itself", "endless scroll": "the feed never ends",
	"notifications": "pull you back to the app", "likes": "keep you checking for approval",
	"daily rewards": "pay you to open it every day"}
const HEADING_OF := {"It must hold 10 pens.": "Function", "It must cost under 5 gold to make.": "Cost",
	"It must fit on a 30 cm shelf.": "Size", "It must use 50% recycled material.": "Environment",
	"It must have rounded corners and no sharp edges.": "Safety", "It must match the logo's red and yellow.": "Aesthetics",
	"It must be made of a wood that can be sanded.": "Materials", "It must suit pupils aged 11 to 14.": "Customer"}
const SMART_FOR := {"glasses frames that spring back after bending": "shape-memory alloy",
	"a baby's spoon that shows when food is too hot": "thermochromic pigment",
	"lenses that darken in sunlight": "photochromic lenses", "a gas lighter that sparks when pressed": "piezoelectric crystal",
	"crystals that store water in a plant pot": "hydrogel", "a light, strong bike frame": "carbon fibre composite",
	"a boat hull that is strong and does not rot": "glass fibre (GRP)",
	"a mug whose picture appears with a hot drink": "thermochromic pigment"}
const TRIGGER_OF := {"shape-memory alloy": "warming it", "photochromic lenses": "ultraviolet light",
	"piezoelectric crystal": "squeezing it", "hydrogel": "water"}
const SMART_ANSWER := {"Photochromic glasses go back indoors. What happens?": "the lenses slowly clear",
	"A bent shape-memory wire goes into warm water. What happens?": "it returns to its set shape",
	"A thermochromic strip on a kettle cools down. What happens?": "its colour changes back",
	"A piezoelectric crystal is squeezed. What does it make?": "a small voltage, or a spark",
	"Why are most composites hard to recycle?": "their materials are bonded together"}
const DENSITY := {"steel": 7.8, "aluminium": 2.7, "titanium": 4.5, "carbon fibre": 1.6}
const MATRIX_OF := {"glass fibre (GRP)": "resin", "carbon fibre": "resin", "reinforced concrete": "concrete",
	"cob walls": "clay and earth", "MDF": "glue"}
const REINFORCEMENTS: Array[String] = ["glass fibres", "carbon fibres", "steel bars", "straw", "wood fibres"]
const COMPOSITE_IS := {"A composite is usually stronger than either material alone.": true,
	"Most composites are hard to recycle because their materials are bonded.": true,
	"In reinforced concrete, steel bars take the stretching (tension).": true,
	"A composite is one pure material.": false, "In a fibre composite, the matrix gives most of the strength.": false,
	"Carbon fibre is heavier than steel for the same strength.": false}
const CLOSED := {"a heater with a thermostat": "the room's temperature, measured again",
	"a fridge that keeps itself at 4 °C": "the temperature inside it", "an oven held at 180 °C": "the oven's own temperature",
	"a greenhouse fan with a temperature sensor": "the air's temperature in the greenhouse",
	"a car's cruise control": "the car's speed"}
const FEATURE_JOB := {"tuned mass damper": "swings against the sway", "base isolation": "lets the ground move underneath",
	"cross-bracing": "triangles stop the frame leaning", "deep piles": "reach down to firm ground",
	"a rounded shape": "lets the wind slip past", "expansion joints": "give room to grow in heat",
	"a wide base": "keeps it from tipping"}
const LOAD_KIND := {"the bridge's own deck": "dead", "the steel frame": "dead", "the concrete floors": "dead",
	"lorries crossing": "live", "people in the stadium": "live", "furniture and people": "live",
	"a strong wind": "environmental", "snow on the roof": "environmental", "an earthquake": "environmental"}
const NUTRIENT_FOR := {"the body's main energy source": "carbohydrate", "growth and repair": "protein",
	"an energy store and warmth": "fat", "keeps digestion healthy": "fibre", "healing and healthy skin": "vitamin C",
	"helps take in calcium": "vitamin D", "strong bones and teeth": "calcium", "red blood cells carry oxygen": "iron",
	"seeing in dim light": "vitamin A"}
const LACK := {"vitamin D": "soft, weak bones (rickets)", "iron": "tiredness (anaemia)",
	"vitamin C": "bleeding gums (scurvy)", "vitamin A": "poor sight in dim light"}
const HAS_GLUTEN: Array[String] = ["bread made from wheat", "pasta", "barley soup", "rye crackers", "couscous"]
const VEGAN: Array[String] = ["lentil curry", "tofu stir-fry", "falafel", "an apple", "peanut butter"]
const PRIMARY: Array[String] = ["milling wheat into flour", "pasteurising milk", "washing and sorting potatoes",
	"pressing oil from seeds", "cutting meat into joints"]
const CHAINS: Array = [["wheat grows", "harvest it", "mill it into flour", "bake bread", "deliver to shops"],
	["cows are milked", "chill the milk", "pasteurise it", "make cheese", "sell it"],
	["potatoes grow", "dig them up", "wash and sort them", "make crisps", "pack them"]]
const FOOTPRINT := {"beef": 100, "cheese": 24, "chicken": 10, "eggs": 5, "tofu": 3, "peas": 1}
const LOOP_OF := {"oiling a bike chain so it lasts": "maintain", "mending a torn backpack": "maintain",
	"passing a coat on to a cousin": "reuse", "selling a phone second-hand": "reuse",
	"fixing up old laptops to sell again": "refurbish", "rebuilding old engines as good as new": "refurbish",
	"melting cans into new metal": "recycle", "turning bottles into fleece": "recycle",
	"putting peel in the compost bin": "compost", "rotting garden leaves into soil": "compost"}
const RANK: Array[String] = ["maintain", "reuse", "refurbish", "recycle", "landfill"]
const CIRCULAR_BEST := {"The school's laptops are slow but still work.": "refurbish them with new parts",
	"A chair's leg has worked loose.": "tighten or glue the joint",
	"Old cotton T-shirts are too worn to wear.": "reuse them as cleaning cloths"}
const EASY_REPAIR: Array[String] = ["held together with screws", "made from standard parts", "a battery you can swap",
	"a free repair guide", "parts that unclip", "spare parts for 10 years"]
const REPAIR_BEST := {"Designing a toy so its parts can be recycled.": "parts that unclip, one material each",
	"Designing a torch so it lasts for years.": "a battery and bulb you can swap",
	"Designing a chair to be mended.": "standard bolts and a repair guide"}
const IMPACT_OF := {"people can talk to family far away": "social", "robots do dangerous jobs instead of people": "social",
	"some people spend less time with friends": "social", "data centres use a lot of electricity": "environmental",
	"old devices become e-waste": "environmental", "better batteries store solar power": "environmental",
	"new jobs designing robots": "economic", "some jobs disappear": "economic", "products get cheaper to make": "economic",
	"who is to blame if a robot makes a mistake?": "ethical", "should cameras see faces without asking?": "ethical"}
const AUTOMATION: Array[String] = ["gives no help: the driver does everything", "helps with speed or with steering",
	"steers and controls speed while the driver watches", "drives itself in some places; you take over when asked",
	"drives itself in set areas, with no takeover needed", "drives itself anywhere, in any conditions"]
const AUTO_ANSWER := {"At level 2, who must watch the road?": "the driver, all the time",
	"At level 3, what must the driver be ready to do?": "take over when the car asks",
	"Which level needs no driver anywhere?": "level 5",
	"A car keeps its lane but you steer round corners. Level?": "level 1"}
const PART_COST := {"a moisture sensor": 3.0, "a small pump": 6.0, "a battery box": 2.0, "tubing": 1.5, "a case": 4.0,
	"a board": 8.0, "wires": 0.5, "an LED": 0.25, "a buzzer": 1.25}
const PRIMARY_SOURCE: Array[String] = ["a letter written in 1830 about the railway",
	"a photo taken the day the Berlin Wall fell", "a newspaper printed in July 1969",
	"an interview with someone who was there", "a ticket from the first inter-city railway",
	"a poster from 1918 about votes for women"]
const SOURCE_ANSWER := {"A 1918 poster asking for votes for women is…": "useful, but made to persuade",
	"Two sources disagree about an event. What should you do?": "compare them, and look for a third",
	"Why credit your sources in a documentary?": "so viewers can check the facts"}
const YEAR_OF := {"the first inter-city railway opens": 1830, "the first powered flight": 1903,
	"some UK women win the vote": 1918, "UK women vote on equal terms": 1928, "the NHS is founded": 1948,
	"the first Moon landing": 1969, "the Berlin Wall falls": 1989, "the first website goes live": 1991}
const FAIR_QS: Array[String] = ["How do you usually travel to school?",
	"How many glasses of water do you drink a day?", "How often do you visit the beach?",
	"How many minutes do you spend outside each day?"]
const SAMPLE_ANSWER := {"To find how Year 9 travels to school, who should you ask?": "a random 30 from all Year 9 classes",
	"Why is a bigger sample usually better?": "the results are less likely to be a fluke",
	"Litter is counted on one sunny Sunday only. What is the problem?": "one day may not be typical",
	"Towns with more cycle lanes have fewer car trips to school. This shows…": "they go together, which doesn't prove cause",
	"Ice cream sales and sunburn both rise in summer. Why?": "a third thing, sunny weather, drives both",
	"The points slope down from left to right. The correlation is…": "negative"}


func _gens() -> Array[String]:
	var out: Array[String] = []
	for g in SchoolGen.ids():
		if g.begins_with(SOURCE):
			out.append(g)
	return out


## The right answer as the child sees it: a choice's text, a true or false, a number's value, a sort's or match's
## pairs, an order's items in order.
func _right(ex: Dictionary) -> Variant:
	match str(ex.type):
		"choice":
			return ExerciseCheck.item_text(ex.choices[int(ex.answer)])
		"truefalse":
			return bool(ex.answer)
		"number":
			return NumberAnswer.value(str(ex.answer))
		"sort":
			var out := {}
			for i in (ex.items as Array).size():
				out[str(ex.items[i])] = str(ex.groups[int(ex.answer[i])])
			return out
		"match":
			var out := {}
			for i in (ex.items as Array).size():
				out[str(ex.items[i])] = str(ex.matches[int(ex.answer[i])])
			return out
		"order":
			var out: Array[String] = []
			for i: Variant in ex.answer:
				out.append(str(ex.items[int(i)]))
			return out
	return null


func _lines(f: String) -> Array[int]:
	var out: Array[int] = []
	for part in f.split("-"):
		out.append(int(part))
	return out


## Every pair of a sort or match agrees with `facts` (a Dictionary of item → group), or with `rule`.
func _pairs_ok(right: Dictionary, facts: Dictionary) -> String:
	for item: String in right:
		if str(facts.get(item, "?")) != str(right[item]):
			return "%s is %s" % [item, facts.get(item, "?")]
	return ""


## A sort of [item, group] pairs where `yes` items (a list) belong to `yes_group`.
func _two_ok(right: Dictionary, yes: Array, yes_group: String, no_group: String) -> String:
	for item: String in right:
		var want := yes_group if yes.has(item) else no_group
		if str(right[item]) != want:
			return "%s is %s" % [item, want]
	return ""


func _near(a: Variant, b: float) -> bool:
	return absf(float(a) - b) < 0.006


func test_the_source_is_registered_last_and_has_its_generators() -> void:
	var keys: Array = SchoolGen.SOURCES.keys()
	assert_true(keys.has("g8l"), "g8l is a SOURCES line")
	assert_gt(keys.find("g8l"), maxi(keys.find("g8h"), keys.find("g7w")), "g8l comes after the earlier grade 8 sources")
	assert_gt(_gens().size(), 50, "the grade 8 life generators exist")


func test_every_generator_is_valid_at_every_level_with_a_hint_a_worked_answer_and_data() -> void:
	for g in _gens():
		for level in [1, 2, 3]:
			var prompts := {}
			for s in SEEDS:
				var ex := SchoolGen.make(g, s, level)
				assert_eq(ExerciseCheck.problem(ex), "", "%s level %d seed %d: %s" % [g, level, s, ex])
				assert_true(ex.has("data"), "%s: data" % g)
				assert_gt(str(ex.get("explain", "")).length(), 8, "%s: a worked answer" % g)
				assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy" % g)
				if ex.get("picture") is Dictionary:
					assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture %s" % [g, ex.picture])
				prompts[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("items", "")) + str(ex.get("choices", ""))] = true
			assert_gt(prompts.size(), 1, "%s level %d varies" % [g, level])


func test_every_answer_is_worked_out_again() -> void:
	var checked := 0
	for g in _gens():
		var name := g.substr(SOURCE.length())
		for level in [1, 2, 3]:
			for s in SEEDS:
				var ex := SchoolGen.make(g, s, level)
				var why := _check(name, level, ex)
				assert_eq(why, "", "%s level %d seed %d: %s | %s" % [g, level, s, why, ex.prompt])
				checked += 1
	assert_gt(checked, 20000, "answers checked")


## "" when `ex`'s answer is right by this test's own working; otherwise why not.
func _check(name: String, level: int, ex: Dictionary) -> String:
	var d: Dictionary = ex.data
	var right: Variant = _right(ex)
	var p := str(ex.prompt)
	match name:
		"formation":
			if level == 1:
				var lines := _lines(str(d.formation))
				var shown := 0
				for pl: Array in ex.picture.players:
					shown += 1
				if shown != 11:
					return "the pitch shows %d players" % shown
				return "" if is_equal_approx(right, lines[int(d.line)]) else "the line"
			if level == 2:
				var k := int(d.line)
				var best := ""
				for f: String in d.formations:
					if best == "" or _lines(f)[k] > _lines(best)[k]:
						best = f
				return "" if right == best else "most is %s" % best
			return "" if is_equal_approx(right, _lines(str(d.formation))[1] - _lines(str(d.other))[1]) else "midfield"
		"match_stats":
			if level == 1:
				return "" if _near(right, 100.0 * int(d.done) / int(d.tried)) else "completion"
			if level == 2:
				return "" if _near(right, 100.0 * int(d.had) / int(d.total)) else "possession"
			var a := 100.0 * int(d.d1) / int(d.t1)
			var b := 100.0 * int(d.d2) / int(d.t2)
			return "" if _near(right, b - a) and b > a else "points"
		"tactic_change":
			return "" if right == TACTIC_BEST.get(str(d.situation), "?") else "best change"
		"fitness_test":
			if level == 1:
				return "" if right == TEST_PART.get(str(d.test), "?") else "part"
			if level == 2:
				return _pairs_ok(right, TEST_PART)
			return "" if TEST_PART.get(str(right), "?") == str(d.component) else "valid test"
		"test_result":
			var lower := TIMED.has(str(d.test))
			if level == 1:
				var best: float = (d.values as Array).min() if lower else (d.values as Array).max()
				return "" if _near(right, best) else "best"
			if level == 2:
				var sum := 0.0
				for v: float in d.values:
					sum += v
				return "" if _near(right, sum / 3.0) else "mean"
			var change := (float(d.old) - float(d.new)) if lower else (float(d.new) - float(d.old))
			return "" if _near(right, change / float(d.old) * 100.0) and change > 0.0 else "improvement"
		"profile_read":
			var parts: Array = d.parts
			if level == 1:
				for pt: Array in parts:
					if str(pt[0]) == str(d.part):
						return "" if is_equal_approx(right, int(pt[1])) else "score"
				return "no such part"
			if level == 2:
				var low := 99
				var name_low := ""
				var ties := 0
				for pt: Array in parts:
					if int(pt[1]) < low:
						low = int(pt[1])
						name_low = str(pt[0])
						ties = 1
					elif int(pt[1]) == low:
						ties += 1
				return "" if right == name_low and ties == 1 else "weakest"
			var best := -1
			var name_best := ""
			for i in parts.size():
				var g := int(d.after[i]) - int(parts[i][1])
				if g > best:
					best = g
					name_best = str(parts[i][0])
			return "" if right == name_best else "most improved"
		"week_activity":
			if level == 1:
				return "" if is_equal_approx(right, int(d.minutes) / int(d.days)) else "per day"
			var total := 0
			for s: Array in d.sessions:
				total += int(s[0]) * int(s[1]) * (2 if VIGOROUS.has(str(s[2])) else 1)
			if level == 2:
				return "" if is_equal_approx(right, total) else "moderate minutes"
			return "" if is_equal_approx(right, 150 - total) and total < 150 else "still needed"
		"activity_kind":
			if level == 1:
				return "" if STRENGTH.has(str(right)) else "strengthening"
			if level == 2:
				return _two_ok(right, STRENGTH, "muscle-strengthening", "aerobic")
			return _pairs_ok(right, SPORT_KIND)
		"thinking_trap":
			if level == 1:
				return "" if right == TRAP_OF.get(str(d.thought), "?") else "trap"
			if level == 2:
				return _pairs_ok(right, TRAP_SHORT)
			return "" if right == BALANCED_OF.get(str(d.thought), "?") else "balanced"
		"coping_choice":
			if level == 1:
				return "" if right == HELPFUL.has(str(d.way)) else "helpful"
			if level == 2:
				return _two_ok(right, HELPFUL, "helpful", "unhelpful")
			return "" if right == HELP_BEST.get(str(d.situation), "?") else "help"
		"three_ps":
			if level == 1:
				return "" if right == P_TRAP_OF.get(str(d.thought), "?") else "trap"
			if level == 2:
				return _pairs_ok(right, P_SHORT)
			return "" if right == REFRAME_OF.get(str(d.thought), "?") else "reframe"
		"review_step":
			if level == 1:
				return "" if str(right) == str(BOUNCE) else "order"
			if level == 2:
				return _two_ok(right, WENT_WELL, "what went well", "even better if")
			return "" if right == SETBACK_BEST.get(str(d.setback), "?") else "next step"
		"online_sign":
			if level == 1:
				return "" if right == HEALTHY.has(str(d.sign)) else "healthy"
			if level == 2:
				return _two_ok(right, HEALTHY, "healthy", "warning sign")
			return "" if right == ONLINE_BEST.get(str(d.situation), "?") else "what to do"
		"online_action":
			if level == 2:
				return "" if str(right) == str(REPORT) else "order"
			return "" if right == ONLINE_BEST.get(str(d.situation), "?") else "respect"
		"wheel_odds":
			var total := 0
			var wins := 0
			var won := 0.0
			for s: Array in d.slices:
				total += int(s[1])
				wins += int(s[1]) if float(s[2]) > 0.0 else 0
				won += int(s[1]) * float(s[2])
			if not ex.has("picture") or ex.picture.slices != d.slices:
				return "the wheel"
			if level == 1:
				return "" if _near(right, 100.0 * wins / total) else "share"
			if level == 2:
				return "" if _near(right, won / total) and won / total < 1.0 else "expected"
			var spins := int(RegEx.create_from_string("(\\d+) spins").search(p).get_string(1))
			return "" if _near(right, (1.0 - won / total) * spins) else "expected loss"
		"loot_odds":
			if level == 1:
				return "" if _near(right, 100.0 / int(d.n)) else "percent"
			if level == 2:
				return "" if is_equal_approx(right, int(d.n)) else "boxes"
			return "" if is_equal_approx(right, int(d.n) * int(d.cost)) else "gold"
		"chance_myth":
			if level == 1:
				return "" if right == CHANCE_IS.get(str(d.statement), null) else "truth"
			for c: Variant in ex.choices:
				var t := ExerciseCheck.item_text(c)
				if not CHANCE_IS.has(t):
					return "unknown statement %s" % t
				if (t == right) != (CHANCE_IS[t] == (level == 2)):
					return "%s" % t
			return ""
		"pressure_kind":
			if level == 1:
				return "" if right == PRESSURE_OF.get(str(d.example), "?") else "kind"
			return _pairs_ok(right, PRESSURE_OF)
		"substance_law":
			if level == 2:
				return "" if right == LAW_ANSWER.get(str(d.question), "?") else "answer"
			return "" if right == LAW_IS.get(str(d.statement), null) else "truth"
		"refusal":
			if level == 1:
				return "" if right == REFUSAL_OF.get(str(d.example), "?") else "way"
			if level == 2:
				var flipped := {}
				for item: String in right:
					flipped[str(right[item])] = item
				for ex_text: String in flipped:
					if REFUSAL_SHORT.get(ex_text, "?") != flipped[ex_text]:
						return "%s is %s" % [ex_text, REFUSAL_SHORT.get(ex_text, "?")]
				return ""
			return "" if right == REFUSE_BEST.get(str(d.situation), "?") else "best"
		"cpr_count":
			if level == 1:
				return "" if is_equal_approx(right, int(d.rate) * int(d.secs) / 60.0) else "pushes"
			if level == 2:
				return "" if is_equal_approx(right, 30 * int(d.cycles)) else "cycles"
			if d.has("pushes"):
				return "" if is_equal_approx(right, 30.0 * 60.0 / int(d.rate)) else "seconds"
			return "" if is_equal_approx(right, int(d.rate) * int(d.minutes) / 30.0) else "sets"
		"cpr_step":
			if level == 1:
				var i := CPR.find(str(d.step))
				return "" if i >= 0 and right == CPR[i + 1] else "next"
			if level == 2:
				return "" if str(right) == str(CPR.slice(int(d.start), int(d.start) + 5)) else "order"
			return "" if right == CPR_BEST.get(str(d.situation), "?") else "what to do"
		"survey_share":
			if level == 1:
				return "" if _near(right, 100.0 * int(d.part) / int(d.n)) else "share"
			if level == 2:
				return "" if _near(right, 100.0 * (int(d.after) - int(d.before)) / int(d.n)) and int(d.after) > int(d.before) \
					else "points"
			return "" if _near(right, int(d.n) * (int(d.p2) - int(d.p1)) / 100.0) else "pupils"
		"campaign_plan":
			if level == 1:
				return "" if SMART_AIMS.has(str(right)) else "smart"
			if level == 2:
				return "" if str(right) == str(CAMPAIGN) else "order"
			return "" if right == MESSAGE_BEST.get(str(d.topic), "?") else "message"
		"screen_time":
			if level == 1:
				return "" if _near(right, float(d.hours) * 7.0) else "week"
			if level == 2:
				var sum := 0
				for v: int in d.days:
					sum += v
				return "" if _near(right, sum / 7.0) else "mean"
			if d.has("awake"):
				return "" if _near(right, 100.0 * int(d.screens) / int(d.awake)) else "share"
			return "" if is_equal_approx(right, int(d.hours) * 365) else "year"
		"focus_habit":
			if level == 1:
				return "" if right == HELPS_FOCUS.has(str(d.habit)) else "focus"
			if level == 2:
				return _two_ok(right, HELPS_FOCUS, "helps", "harms")
			return _pairs_ok(right, TRICK_DOES)
		"spec_point":
			if level == 1:
				return "" if HEADING_OF.has(str(right)) else "measurable"
			if level == 2:
				return _two_ok(right, HEADING_OF.keys(), "measurable", "vague")
			return "" if right == HEADING_OF.get(str(d.point), "?") else "heading"
		"plan_time":
			var end := 0
			for t: Array in d.tasks:
				end = maxi(end, int(t[1]) + int(t[2]))
			if ex.picture.tasks != d.tasks:
				return "the plan"
			if level == 1:
				for t: Array in d.tasks:
					if str(t[0]) == str(d.task):
						return "" if is_equal_approx(right, int(t[2])) else "length"
				return "no such task"
			if level == 2:
				return "" if is_equal_approx(right, end) else "finish"
			var t0 := 0
			for t: Array in d.tasks:
				if int(t[1]) != t0:
					return "not one after another"
				t0 = int(t[1]) + int(t[2])
			return "" if is_equal_approx(right, end + int(d.extra)) else "delay"
		"cutting_list":
			if level == 1:
				return "" if is_equal_approx(right, int(d.n) * int(d.length)) else "total"
			if level == 2:
				return "" if is_equal_approx(right, floori(float(d.stock) / int(d.piece))) else "pieces"
			return "" if _near(right, int(d.size) + (-1.0 if bool(d.small) else 1.0) * float(d.tol)) else "tolerance"
		"smart_use":
			if level == 1:
				return "" if right == SMART_FOR.get(str(d.use), "?") else "material"
			if level == 2:
				return _pairs_ok(right, TRIGGER_OF)
			return "" if right == SMART_ANSWER.get(str(d.question), "?") else "what happens"
		"material_mass":
			var dens := float(DENSITY[str(d.material)])
			if level == 1:
				return "" if _near(right, dens * int(d.volume)) else "mass"
			if level == 2:
				return "" if _near(right, (dens - 1.6) * int(d.volume)) else "saved"
			return "" if _near(right, float(d.mass) / dens) else "volume"
		"composite_part":
			if level == 1:
				return "" if right == MATRIX_OF.get(str(d.composite), "?") else "matrix"
			if level == 2:
				return _two_ok(right, REINFORCEMENTS, "reinforcement", "matrix")
			return "" if right == COMPOSITE_IS.get(str(d.statement), null) else "truth"
		"threshold_output":
			if level == 1:
				return "" if right == (int(d.r) < int(d.t)) else "lamp"
			if level == 2:
				var n := 0
				for v: int in d.readings:
					if v == int(d.t):
						return "a reading on the threshold"
					n += 1 if (v < int(d.t) if bool(d.below) else v > int(d.t)) else 0
				return "" if is_equal_approx(right, n) else "count"
			var hot := int(d.temp) > int(d.limit)
			var damp := int(d.hum) > int(d.damp)
			return "" if right == ((hot and damp) if str(d.op) == "and" else (hot or damp)) else "fan"
		"battery_life":
			if level == 1:
				return "" if is_equal_approx(right, float(d.cap) / int(d.ma)) else "hours"
			if level == 2:
				return "" if is_equal_approx(right, float(d.cap) / int(d.ma) / int(d.per_day)) else "days"
			return "" if is_equal_approx(right, int(d.ma) * int(d.hours)) else "capacity"
		"control_loop":
			if level == 1:
				return "" if CLOSED.has(str(right)) else "closed"
			if level == 2:
				return _two_ok(right, CLOSED.keys(), "closed loop", "open loop")
			return "" if right == CLOSED.get(str(d.system), "?") else "feedback"
		"lever_ma":
			var pic: Dictionary = ex.picture
			if int(pic.load) != int(d.dl) or int(pic.pivot) != 0:
				return "the lever"
			if level == 1:
				return "" if is_equal_approx(right, float(d.de) / int(d.dl)) else "MA"
			if level == 2:
				return "" if is_equal_approx(right, float(d.load) * int(d.dl) / int(d.de)) else "effort"
			var effort := float(d.load) * int(d.dl) / int(d.de)
			return "" if is_equal_approx(right, float(d.load) * int(d.dl) / effort) else "distance"
		"gear_ratio":
			var r := 1.0
			for s: Array in d.stages:
				r *= float(s[1]) / float(s[0])
			if ex.picture.stages != d.stages:
				return "the train"
			if p.contains("ratio"):
				return "" if is_equal_approx(right, r) else "ratio"
			return "" if is_equal_approx(right, int(d.rpm) / r) else "speed"
		"tackle_effort":
			if int(ex.picture.ropes) != int(d.ropes):
				return "the ropes"
			if level == 1:
				return "" if is_equal_approx(right, float(d.load) / int(d.ropes)) else "effort"
			if level == 2:
				return "" if is_equal_approx(right, int(d.lift) * int(d.ropes)) else "rope"
			return "" if _near(right, float(d.load) / int(d.ropes) / int(d.real) * 100.0) else "efficiency"
		"ma_efficiency":
			if level == 1:
				return "" if is_equal_approx(right, float(d.load) / int(d.effort)) else "MA"
			if level == 2:
				return "" if is_equal_approx(right, float(d.effort_d) / int(d.load_d)) else "VR"
			var ma := float(d.load) / int(d.effort)
			var vr := float(d.effort_d) / int(d.load_d)
			return "" if _near(right, ma / vr * 100.0) else "efficiency"
		"safety_factor":
			var fos := int(d.fos)
			var work := int(d.work)
			if level == 1:
				return "" if is_equal_approx(right, fos) and p.contains(str(work * fos)) else "factor"
			return "" if is_equal_approx(right, work if level == 2 else work * fos) else "load"
		"structure_feature":
			if level == 1:
				return "" if right == FEATURE_JOB.get(str(d.feature), "?") else "job"
			if level == 2:
				return _pairs_ok(right, FEATURE_JOB)
			return _pairs_ok(right, LOAD_KIND)
		"nutrient_job":
			if level == 1:
				return "" if right == NUTRIENT_FOR.get(str(d.job), "?") else "nutrient"
			if level == 2:
				var flipped := {}
				for n: String in right:
					flipped[str(right[n])] = n
				return _pairs_ok(flipped, NUTRIENT_FOR)
			return "" if right == LACK.get(str(d.nutrient), "?") else "lack"
		"per_portion":
			if level == 1:
				return "" if _near(right, int(d.per) * int(d.portion) / 100.0) else "fibre"
			if level == 2:
				return "" if _near(right, float(d.salt) * int(d.portion) / 100.0 / 6.0 * 100.0) else "salt"
			return "" if _near(right, 25.0 - int(d.a) * int(d.pa) / 100.0 - int(d.b) * int(d.pb) / 100.0) else "fibre left"
		"dietary_need":
			if level == 1:
				return "" if not HAS_GLUTEN.has(str(right)) else "gluten-free"
			if level == 2:
				return _two_ok(right, HAS_GLUTEN, "has gluten", "gluten-free")
			return _two_ok(right, VEGAN, "vegan", "not vegan")
		"processing":
			if level == 1:
				return "" if PRIMARY.has(str(right)) else "primary"
			if level == 2:
				return _two_ok(right, PRIMARY, "primary", "secondary")
			return "" if CHAINS.any(func(c: Array) -> bool: return str(c) == str(right)) else "chain"
		"food_footprint":
			if level == 1:
				return "" if _near(right, int(FOOTPRINT[str(d.food)]) * float(d.kg)) else "footprint"
			if level == 2:
				return "" if _near(right, float(FOOTPRINT[str(d.a)]) / int(FOOTPRINT[str(d.b)])) else "times"
			return "" if _near(right, (100 - int(FOOTPRINT[str(d.swap)])) * float(d.kg)) else "saved"
		"loop_order":
			if level == 1:
				return "" if right == LOOP_OF.get(str(d.action), "?") else "loop"
			if level == 2:
				return "" if str(right) == str(RANK) else "rank"
			return "" if right == CIRCULAR_BEST.get(str(d.case), "?") else "best"
		"cost_per_year":
			if level == 1:
				return "" if is_equal_approx(right, float(d.price) / int(d.years)) else "per year"
			if level == 2:
				var a := float(d.pa) / int(d.ya)
				var b := float(d.pb) / int(d.yb)
				return "" if is_equal_approx(right, a - b) and b < a and int(d.yb) > int(d.ya) else "less a year"
			var cheap := int(d.pc) * int(d.span) / int(d.yc)
			return "" if is_equal_approx(right, cheap - int(d.pg)) and cheap > int(d.pg) else "more in all"
		"repair_feature":
			if level == 1:
				return "" if right == EASY_REPAIR.has(str(d.feature)) else "easy"
			if level == 2:
				return _two_ok(right, EASY_REPAIR, "easy to repair", "hard to repair")
			return "" if right == REPAIR_BEST.get(str(d.case), "?") else "best"
		"impact_kind":
			if level == 1:
				return "" if right == IMPACT_OF.get(str(d.impact), "?") else "kind"
			return _pairs_ok(right, IMPACT_OF)
		"standby_energy":
			var w := int(d.w) * int(d.get("n", 1))
			if level == 1:
				return "" if is_equal_approx(right, w * 24) else "Wh"
			return "" if _near(right, w * 24 * 365 / 1000.0) else "kWh"
		"automation_level":
			if level == 3:
				return "" if right == AUTO_ANSWER.get(str(d.question), "?") else "answer"
			var lv := int(d.level)
			if not p.contains(AUTOMATION[lv]):
				return "the description"
			return "" if (right == "level %d" % lv if level == 1 else is_equal_approx(right, lv)) else "level"
		"reliability":
			if level == 1:
				return "" if _near(right, 100.0 * int(d.worked) / int(d.n)) else "percent"
			if level == 2:
				var sum := 0
				for v: int in d.values:
					sum += v
				return "" if _near(right, sum / 5.0) else "mean"
			return "" if _near(right, 100.0 * (int(d.w2) - int(d.w1)) / int(d.n)) and int(d.w2) > int(d.w1) else "points"
		"parts_budget":
			var total := 0.0
			for part: String in d.parts:
				total += float(PART_COST[part])
			if level == 1:
				return "" if _near(right, total) else "total"
			if level == 2:
				return "" if _near(right, int(d.budget) - total) and int(d.budget) > total else "left"
			return "" if is_equal_approx(right, floori(int(d.budget) / total)) else "kits"
		"frame_count":
			if level == 1:
				return "" if is_equal_approx(right, int(d.fps) * int(d.secs)) else "frames"
			if level == 2:
				return "" if is_equal_approx(right, float(d.frames) / int(d.fps)) else "seconds"
			var secs := 0
			for s: int in d.shots:
				secs += s
			return "" if is_equal_approx(right, secs * int(d.fps)) else "all frames"
		"source_type":
			if level == 1:
				return "" if right == PRIMARY_SOURCE.has(str(d.source)) else "primary"
			if level == 2:
				return _two_ok(right, PRIMARY_SOURCE, "primary", "secondary")
			return "" if right == SOURCE_ANSWER.get(str(d.question), "?") else "answer"
		"years_between":
			if level == 1:
				return "" if is_equal_approx(right, int(YEAR_OF[str(d.b)]) - int(YEAR_OF[str(d.a)])) else "years"
			if level == 2:
				return "" if is_equal_approx(right, int(YEAR_OF[str(d.b)])) and ex.get("year", false) == true else "year"
			for i in range(1, (right as Array).size()):
				if int(YEAR_OF[str(right[i])]) <= int(YEAR_OF[str(right[i - 1])]):
					return "not in time order"
			return ""
		"goal_rate":
			if level == 1:
				return "" if is_equal_approx(right, int(d.count) * 100.0 / int(d.length)) else "per 100 m"
			if level == 2:
				return "" if _near(right, 100.0 * (int(d.before) - int(d.after)) / int(d.before)) else "fall"
			var sum := 0
			for c: int in d.counts:
				sum += c
			return "" if is_equal_approx(right, sum / 4.0 * int(d.length) / 100.0) else "estimate"
		"correlation":
			if level == 3:
				return "" if right == SAMPLE_ANSWER.get(str(d.question), "?") else "answer"
			var pts: Array[Vector2] = []
			for pt: Array in d.points:
				pts.append(Vector2(float(pt[0]), float(pt[1])))
			var r := _pearson(pts)
			if level == 1:
				var want := "positive" if r > 0.6 else ("negative" if r < -0.6 else ("no correlation" if absf(r) < 0.3
					else "unclear"))
				return "" if right == want else "it is %s (r = %s)" % [want, r]
			var letter := p.substr(p.find("Point ") + 6, 1)
			for pt: Array in d.points:
				if str(pt[2]) == letter:
					return "" if is_equal_approx(right, float(pt[1])) else "point"
			return "no such point"
		"survey_question":
			if level == 1:
				return "" if FAIR_QS.has(str(right)) else "fair"
			if level == 2:
				return _two_ok(right, FAIR_QS, "fair", "leading")
			return "" if right == SAMPLE_ANSWER.get(str(d.question), "?") else "sample"
	return "no check for %s" % name


## The sample correlation (this test's own).
func _pearson(pts: Array[Vector2]) -> float:
	var n := float(pts.size())
	var mx := 0.0
	var my := 0.0
	for q in pts:
		mx += q.x
		my += q.y
	mx /= n
	my /= n
	var sxy := 0.0
	var sxx := 0.0
	var syy := 0.0
	for q in pts:
		sxy += (q.x - mx) * (q.y - my)
		sxx += (q.x - mx) * (q.x - mx)
		syy += (q.y - my) * (q.y - my)
	return 0.0 if sxx == 0.0 or syy == 0.0 else sxy / sqrt(sxx * syy)


## Every generator's choices are different from its right answer and never give it away in the hint.
func test_hints_never_say_the_right_choice() -> void:
	for g in _gens():
		for level in [1, 2, 3]:
			for s in 30:
				var ex := SchoolGen.make(g, s, level)
				if str(ex.type) != "choice":
					continue
				var right := ExerciseCheck.item_text(ex.choices[int(ex.answer)]).to_lower().trim_suffix(".")
				if right.length() < 4 or str(ex.prompt).to_lower().contains(right):
					continue
				assert_false(str(ex.hint).to_lower().contains(right), "%s: the hint says '%s'" % [g, right])
