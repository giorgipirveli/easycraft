class_name G8LifeGen
extends RefCounted
## Owner #70, #73 and #111 (research §6.8): grade 8 health and PE, design and technology, and projects generators:
## formations and match statistics, changing tactics, fitness tests and their results, fitness profiles, a week's
## activity, kinds of activity, thinking traps and coping, the three traps after a setback and bouncing back, healthy and
## controlling online friendships and what to do, a prize wheel's chances and expected win, mystery-box odds, myths about
## chance, kinds of peer pressure, the UK's law on alcohol, tobacco and vapes, ways to say no, CPR's counts and steps, a
## campaign's survey and plan, screen time and focus; specifications, a making plan, cutting lists and tolerances, smart
## materials and their uses, mass from density, composites' parts, sensors' thresholds, battery life, open and closed
## loops, levers, gear trains, a block and tackle, mechanical advantage, velocity ratio and efficiency, factors of
## safety, structures' features and loads, nutrients, a label's portions, dietary needs, food processing, food's
## footprints, the circular economy's loops, cost per year, design for repair, technology's effects, standby energy,
## levels of driving automation; a prototype's reliability, a parts budget, animation frames, sources, the years between
## turning points, litter rates and samples, scatter graphs' correlation and fair survey questions. SchoolGen
## "g8l.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a
## hint (a strategy), a worked answer and `data` (its inputs, for tests/unit/test_g8_life_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const W := preload("res://core/school/gen/g7_life_gen.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi", "Mo", "Ana"]

# --- Banks (checked by the test with its own copies) ----------------------------------------------------------------

## Formations, counted from the back (the goalkeeper is not counted): defenders, midfielders, strikers.
const FORMATIONS: Array[String] = ["4-4-2", "4-3-3", "4-5-1", "3-5-2", "5-3-2", "3-4-3", "5-4-1"]
const LINES: Array[String] = ["defenders", "midfielders", "strikers"]
## Changing tactics in a game: [level, situation, the best change, other choices].
const TACTIC_CASES: Array = [
	[1, "Your team is losing 1-0 with ten minutes left.", "add an attacker and push higher up",
		["bring on an extra defender", "slow the game down", "keep everything the same"]],
	[1, "Your team is winning 2-1 and the game is nearly over.", "keep a compact shape and keep the ball",
		["send everyone forward", "take risky long shots", "stop running"]],
	[1, "The other team's best player keeps finding space in midfield.", "mark them closely and close the space",
		["ignore them", "move your keeper forward", "let them have the ball"]],
	[2, "The other team has three in midfield against your two, and you keep losing the ball there.",
		"add a midfielder, such as 4-5-1", ["take a defender off", "stand still in midfield", "only pass backwards"]],
	[2, "Their defenders are tall and win every high cross.", "pass along the ground and cross low",
		["cross even higher", "only shoot from far away", "kick it out of play"]],
	[2, "Their defence pushes up high, leaving space behind it.", "make runs and pass into the space behind",
		["pass sideways at the back", "stand offside", "slow every attack down"]],
	[3, "In netball, the other team keeps intercepting your long passes.", "use short passes and move into space",
		["throw the ball higher and longer", "hold the ball for longer", "stand still to receive"]],
	[3, "In badminton, your opponent is strong at the back but slow to the net.", "mix deep clears with drop shots",
		["only play clears", "hit every shot straight at them", "serve long every time"]],
	[3, "In rounders, the batters hit most balls to the left side.", "move more fielders to the left",
		["put every fielder behind the bowler", "move all fielders to the right", "take fielders off the pitch"]],
	[3, "You lead 1-0, then the other team switches to three strikers.", "drop a midfielder back to defend",
		["push your defenders forward", "take off a defender", "play exactly as before"]],
]
## Fitness tests and the part of fitness each measures.
const TESTS: Array = [["multistage fitness test", "stamina"], ["Cooper 12-minute run", "stamina"],
	["sit-and-reach test", "flexibility"], ["hand-grip test", "strength"], ["30 m sprint", "speed"],
	["Illinois agility run", "agility"], ["stork stand", "balance"], ["vertical jump", "power"],
	["one-minute press-up test", "muscular endurance"], ["ruler drop test", "reaction time"]]
## Tests with a measured result: [test, unit, lower is better].
const RESULT_TESTS: Array = [["30 m sprint", "s", true], ["Illinois agility run", "s", true],
	["sit-and-reach test", "cm", false], ["vertical jump", "cm", false], ["hand-grip test", "kg", false],
	["standing long jump", "cm", false]]
const PROFILE_PARTS: Array[String] = ["stamina", "strength", "speed", "flexibility", "agility", "balance", "power"]
## Moderate and vigorous sessions: [what, vigorous].
const SESSIONS: Array = [["brisk walks", false], ["bike rides to school", false], ["easy swims", false],
	["runs", true], ["games of football", true], ["fast swims", true]]
const AEROBIC: Array[String] = ["brisk walking", "cycling", "swimming lengths", "running", "dancing", "rowing"]
const STRENGTHENING: Array[String] = ["press-ups", "squats", "resistance-band exercises", "pull-ups", "lunges",
	"sit-ups"]
const KIND_OF_SPORT: Array = [["football", "team"], ["netball", "team"], ["hockey", "team"], ["basketball", "team"],
	["swimming", "solo"], ["running", "solo"], ["gymnastics", "solo"], ["yoga", "solo"], ["climbing", "outdoor adventure"],
	["kayaking", "outdoor adventure"], ["orienteering", "outdoor adventure"], ["hill walking", "outdoor adventure"]]
## Thinking traps: [thought, trap, a balanced thought].
const TRAPS: Array[String] = ["catastrophising", "mind reading", "all-or-nothing", "fortune telling"]
const TRAP_THOUGHTS: Array = [
	["If I get one answer wrong, the whole test is ruined.", "all-or-nothing", "One wrong answer is one mark, not all.",
		"one wrong answer ruins it all"],
	["I'm either brilliant at football or useless.", "all-or-nothing", "I'm good at some skills, still learning others.",
		"brilliant or useless"],
	["They didn't reply, so they must be angry with me.", "mind reading", "They might be busy; I can ask them.",
		"no reply: they must be angry"],
	["Everyone thinks my idea was silly.", "mind reading", "I don't know what they think unless I ask.",
		"everyone thinks my idea is silly"],
	["I'll definitely mess up my solo tomorrow.", "fortune telling", "I've practised; it may well go fine.",
		"I'll definitely mess up my solo"],
	["I just know I won't get into the team.", "fortune telling", "I can't know yet; I'll do my best at the trial.",
		"I know I won't get in the team"],
	["My friend is late, something terrible must have happened.", "catastrophising", "They're probably just held up.",
		"they're late: disaster!"],
	["If I miss the bus, my whole day will be a disaster.", "catastrophising", "If I miss it, I'll catch the next one.",
		"miss the bus: my day is ruined"],
]
const HELPFUL: Array[String] = ["talking to a trusted adult", "going for a walk outside", "box breathing for a minute",
	"writing worries down", "a regular bedtime", "breaking a job into small steps", "doing something kind for someone"]
const UNHELPFUL: Array[String] = ["staying up late online to forget", "keeping every worry to yourself",
	"avoiding everything that feels hard", "skipping meals when stressed", "blaming yourself for everything",
	"staying in your room all weekend"]
## Getting help: [situation, the best thing to do, other choices].
const HELP_CASES: Array = [
	["Bram has felt low and lost interest in everything for over two weeks.", "talk to a trusted adult or a GP soon",
		["wait for it to go by itself", "keep it secret from everyone", "stay in bed more"]],
	["A friend says they feel very low, and asks you to keep it secret.", "listen, then help them tell a trusted adult",
		["promise never to tell anyone", "change the subject", "post about it online"]],
	["Before a test, Zara's heart races and her hands shake.", "slow breaths, then start with an easy question",
		["leave the room for good", "skip the test next time", "tell herself it will go badly"]],
	["Mimi is worried about a party where she knows few people.", "go with a friend and plan what to say",
		["never go to parties again", "stay home every time", "worry about it alone"]],
	["Someone tells you they want to hurt themselves.", "tell a trusted adult straight away",
		["keep it a secret", "wait and see", "tell them to cheer up"]],
]
## The three traps after a setback: [thought, trap, a resilient reframe].
const P_TRAPS: Array[String] = ["forever", "everything", "all me"]
const P_THOUGHTS: Array = [
	["I'll never be good at this.", "forever", "This is hard now; practice will help.", "I'll never be good at this"],
	["I always lose.", "forever", "I lost today; next time can be different.", "I always lose"],
	["I'm bad at everything.", "everything", "Maths was hard today; art went well.", "I'm bad at everything"],
	["This ruins my whole week.", "everything", "One bad match is one part of my week.", "This ruins my whole week"],
	["We lost and it's all my fault.", "all me", "We all made mistakes; they played well.", "We lost and it's all my fault"],
	["The test went badly because I'm hopeless.", "all me", "The test was hard; I can prepare better.",
		"it went badly: I'm hopeless"],
]
const BOUNCE_STEPS: Array[String] = ["notice the feeling", "calm your body", "look at what happened",
	"plan one next step", "try again"]
const WENT_WELL: Array[String] = ["my passes were accurate", "I kept trying to the end", "I warmed up properly",
	"I asked for help early"]
const EVEN_BETTER: Array[String] = ["I start revising sooner", "I talk to my team more", "I check my answers",
	"I practise my serve more"]
const SETBACKS: Array = [
	["Tilly didn't get a part in the school play.", "ask for feedback and help backstage",
		["give up on drama", "say the teacher is unfair", "pretend she never wanted it"]],
	["Bram's model bridge broke in testing.", "find where it broke and strengthen it",
		["throw the whole idea away", "blame the testing machine", "never build again"]],
	["Zara's test score was lower than she hoped.", "find the questions she missed and practise them",
		["decide she's no good at it", "hide the test", "stop revising"]],
	["Mo lost a tennis match 6-1.", "keep what worked, practise one weak shot",
		["quit the club", "blame the racket", "play the same way next time"]],
]
## Online friendships: healthy signs and warning signs.
const HEALTHY_SIGNS: Array[String] = ["respects it when you say no", "is happy for you to see other friends",
	"asks before sharing your photo", "gives you time to reply", "is kind in public and in private"]
const WARNING_SIGNS: Array[String] = ["checks where you are all the time", "gets angry if you don't reply at once",
	"asks for your passwords", "pressures you to send private pictures", "tells you who you can talk to",
	"shares your messages to embarrass you"]
## What to do online: [situation, the best thing to do, other choices].
const ONLINE_CASES: Array = [
	["Someone you met online asks you to keep your chats secret and send a photo.", "don't send it; tell a trusted adult",
		["send it if they seem nice", "keep it secret as asked", "send a photo of a friend"]],
	["A private picture of a classmate is shared in a group chat.", "don't forward it; tell a trusted adult",
		["forward it to one friend", "add a funny comment", "save a copy"]],
	["Your friend posts a photo of you that you don't like.", "ask them kindly to take it down",
		["post a worse one of them", "say nothing and feel bad", "tell everyone they're mean"]],
	["Someone threatens to share a picture of you unless you send more.", "send nothing; tell an adult; report to CEOP",
		["send more so they stop", "pay them to stop", "deal with it alone"]],
]
const RESPECT_CASES: Array = [
	["Before posting a group photo with your friends, you should…", "ask everyone in it",
		["post it quickly", "only ask your best friend", "tag strangers in it"]],
	["Your friend says no when you ask to post their photo.", "accept the no and don't post it",
		["post it anyway", "keep asking until they agree", "post it later"]],
	["A group chat starts making fun of a classmate.", "don't join in; support them; tell an adult",
		["add a laughing face", "screenshot it to share", "join in so you fit in"]],
	["You see a hateful comment about someone's religion.", "report it and check the person is okay",
		["like it so you fit in", "reply with a hateful comment", "share it with friends"]],
]
const REPORT_STEPS: Array[String] = ["don't reply", "keep the evidence", "block the person", "report it",
	"tell a trusted adult"]
## Chance: facts and myths.
const CHANCE_TRUE: Array[String] = ["A fair wheel has no memory of the last spin.",
	"Over time, the people running it expect to win.", "A near miss is still a loss.",
	"Chasing losses usually means losing more.", "In the UK, most gambling is for adults only.",
	"A mystery box sells a chance, not a prize."]
const CHANCE_FALSE: Array[String] = ["After five reds in a row, black is due.",
	"A lucky charm makes winning more likely.", "Keep playing and you're bound to win it back.",
	"A near miss means you're about to win.", "Each loss makes the next win more likely."]
## Peer pressure: [example, kind].
const PRESSURES: Array = [
	["A friend says, 'Go on, everyone else is.'", "direct"], ["Someone dares you in front of the group.", "direct"],
	["An older teen offers you a drink of alcohol.", "direct"],
	["Your friends all start vaping at the park.", "indirect"],
	["The party photos show everyone drinking.", "indirect"],
	["A video makes vaping look grown-up and cool.", "indirect"],
	["You want to look older than you are.", "from inside"], ["You worry you'll be left out if you say no.", "from inside"],
	["You think saying yes will make you popular.", "from inside"]]
const PRESSURE_KINDS: Array[String] = ["direct", "indirect", "from inside"]
## The UK's law and the facts: [statement, true].
const LAW_EASY: Array = [
	["In the UK it is against the law to sell alcohol to anyone under 18.", true],
	["Shops must not sell vapes or tobacco to anyone under 18.", true], ["Nicotine is addictive.", true],
	["Alcohol affects judgement, balance and memory.", true],
	["Vapes are made for young people to try.", false],
	["Most young people your age drink alcohol every week.", false]]
const LAW_HARD: Array = [
	["The police can take alcohol away from under-18s in public.", true],
	["The brain keeps developing until about the age of 25.", true],
	["Single-use vapes are banned from sale in the UK.", true],
	["Alcohol warms you up and keeps you safe in the cold.", false],
	["Coffee or a cold shower sobers someone up.", false],
	["In the UK, anyone over 16 can buy alcohol in a shop.", false]]
const LAW_QS: Array = [
	["From what age can someone buy alcohol in the UK?", "18", ["14", "16", "21"]],
	["Which substance in most vapes is addictive?", "nicotine", ["water", "sugar", "vitamin C"]],
	["Until about what age does the brain keep developing?", "about 25", ["about 10", "about 13", "about 16"]],
	["What do the UK's top doctors advise for children?", "an alcohol-free childhood",
		["one drink a week", "drinks only at parties", "drinks from 14"]],
	["Someone has drunk too much and is very unwell. What helps?", "call 999 and stay with them",
		["a cold shower", "strong coffee", "leave them to sleep alone"]],
]
## Ways to say no: [way, an example].
const REFUSALS: Array = [["broken record", "'No thanks.' 'No thanks.' 'No thanks.'"],
	["give a reason", "'No, I've got training early.'"], ["suggest something else", "'No. Let's get chips instead.'"],
	["use humour", "'No way, I'm allergic to bad ideas!'"], ["walk away", "Saying no, then leaving the group."],
	["a code word", "Texting home a word that means 'pick me up'."]]
const REFUSE_CASES: Array = [
	["At a party, friends keep asking even after you say no.", "leave, and text your code word home",
		["give in so they stop", "argue until they agree", "hide all night"]],
	["A friend offers you a vape on the way home.", "say 'No thanks' and suggest something else",
		["take it to be polite", "take it and bin it later", "say maybe tomorrow"]],
	["Someone says everyone your age drinks.", "say most don't, and say no",
		["agree and join in", "pretend you already do", "stay quiet and feel bad"]],
]
## CPR: the steps in order, and what to do.
const CPR_STEPS: Array[String] = ["check for danger", "check for a response", "shout for help", "open the airway",
	"check breathing for 10 seconds", "call 999 and get a defibrillator", "start CPR"]
const CPR_CASES: Array = [
	["Someone collapses. They don't respond and aren't breathing normally.", "call 999 and start CPR",
		["the recovery position", "give them water", "wait for them to wake"]],
	["Someone doesn't respond but is breathing normally.", "the recovery position, and call 999",
		["start CPR", "sit them up", "leave them alone"]],
	["The defibrillator says 'Shock advised'.", "make sure nobody is touching them",
		["hold their hand", "keep pushing during the shock", "switch it off"]],
	["You're tiring during CPR and someone else can help.", "swap over with hardly a pause",
		["stop and rest", "slow down to 50 a minute", "push more gently"]],
	["A defibrillator arrives while you're doing CPR.", "switch it on and follow its voice",
		["do 10 minutes of CPR first", "read its manual", "wait for the ambulance"]],
]
## A health campaign: habits to survey, SMART aims, the steps and messages.
const HABITS: Array[String] = ["drank water at lunch", "walked or cycled to school", "had breakfast",
	"ate fruit at break", "turned screens off an hour before bed"]
const AIMS: Array = [
	["60% of Year 9 drink water at lunch by July", ["Make everyone healthier", "Drink more water",
		"Try to help a bit"]],
	["Double the pupils who cycle to school by June", ["Get people cycling", "Bikes are good", "Do some cycling"]],
	["80% of Year 8 eat breakfast by half term", ["Eat breakfast", "Be healthier in the morning", "Food is fuel"]],
]
const CAMPAIGN_STEPS: Array[String] = ["survey to find the problem", "set a SMART aim", "choose your audience and message",
	"run the campaign", "survey again and compare"]
const MESSAGES: Array = [
	["more sleep", "Screens off at 9, sleep by 10: wake up sharper", ["Sleep or else!", "Sleep is important, probably",
		"Sleep is for winners only"]],
	["water", "Refill at the fountain: water helps you focus", ["Fizzy drinks will ruin your life",
		"Water exists", "Only silly people forget to drink"]],
	["walking to school", "Walk together on Wednesdays: 20 minutes, done", ["Cars are evil",
		"Walking is a thing you can do", "Drivers should be ashamed"]],
]
## Focus and screens.
const HELPS_FOCUS: Array[String] = ["phone in another room while studying", "notifications off at night",
	"one task at a time", "a 5-minute break after 25 minutes", "screens off an hour before bed",
	"charging the phone outside the bedroom"]
const HARMS_FOCUS: Array[String] = ["checking messages every few minutes", "autoplay on all evening",
	"scrolling in bed", "homework with three apps open", "an alert for every like", "gaming until midnight"]
const DESIGN_TRICKS: Array = [["autoplay", "starts the next video by itself"], ["endless scroll", "the feed never ends"],
	["notifications", "pull you back to the app"], ["likes", "keep you checking for approval"],
	["daily rewards", "pay you to open it every day"]]
## Specifications: [point, measurable, its ACCESS FM heading (or "")].
const SPEC_POINTS: Array = [["It must hold 10 pens.", true, "Function"],
	["It must cost under 5 gold to make.", true, "Cost"], ["It must fit on a 30 cm shelf.", true, "Size"],
	["It must use 50% recycled material.", true, "Environment"],
	["It must have rounded corners and no sharp edges.", true, "Safety"],
	["It must match the logo's red and yellow.", true, "Aesthetics"],
	["It must be made of a wood that can be sanded.", true, "Materials"],
	["It must suit pupils aged 11 to 14.", true, "Customer"],
	["It must look nice.", false, ""], ["It must be cheap.", false, ""], ["It must be good quality.", false, ""],
	["It must be the right size.", false, ""], ["It must be eco-friendly.", false, ""], ["It must be safe.", false, ""]]
const HEADINGS: Array[String] = ["Aesthetics", "Cost", "Customer", "Environment", "Safety", "Size", "Function",
	"Materials"]
const PLAN_TASKS: Array[String] = ["research", "sketch ideas", "make a model", "mark out", "cut the parts",
	"join the parts", "paint, varnish", "test it", "evaluate"]
const PIECES: Array[String] = ["legs", "rails", "shelves", "sides", "slats"]
## Smart materials: [use, material]; [material, trigger]; [question, right, other choices].
const SMART_USES: Array = [["glasses frames that spring back after bending", "shape-memory alloy"],
	["a baby's spoon that shows when food is too hot", "thermochromic pigment"],
	["lenses that darken in sunlight", "photochromic lenses"],
	["a gas lighter that sparks when pressed", "piezoelectric crystal"],
	["crystals that store water in a plant pot", "hydrogel"], ["a light, strong bike frame", "carbon fibre composite"],
	["a boat hull that is strong and does not rot", "glass fibre (GRP)"],
	["a mug whose picture appears with a hot drink", "thermochromic pigment"]]
const SMART_TRIGGERS: Array = [["shape-memory alloy", "warming it"], ["photochromic lenses", "ultraviolet light"],
	["piezoelectric crystal", "squeezing it"], ["hydrogel", "water"]]
const SMART_WHAT: Array = [
	["Photochromic glasses go back indoors. What happens?", "the lenses slowly clear",
		["they stay dark for good", "they turn pink", "they get hot"]],
	["A bent shape-memory wire goes into warm water. What happens?", "it returns to its set shape",
		["it melts", "it stays bent", "it turns blue"]],
	["A thermochromic strip on a kettle cools down. What happens?", "its colour changes back",
		["it keeps the hot colour", "it shrinks", "it glows"]],
	["A piezoelectric crystal is squeezed. What does it make?", "a small voltage, or a spark",
		["light", "water", "only heat"]],
	["Why are most composites hard to recycle?", "their materials are bonded together",
		["they are too light", "they are magnetic", "they melt too easily"]],
]
## Densities in g/cm³ (the lesson's table).
const DENSITY := {"steel": 7.8, "aluminium": 2.7, "titanium": 4.5, "carbon fibre": 1.6}
## Composites: [composite, reinforcement, matrix].
const COMPOSITES: Array = [["glass fibre (GRP)", "glass fibres", "resin"], ["carbon fibre", "carbon fibres", "resin"],
	["reinforced concrete", "steel bars", "concrete"], ["cob walls", "straw", "clay and earth"],
	["MDF", "wood fibres", "glue"]]
const COMPOSITE_FACTS: Array = [["A composite is usually stronger than either material alone.", true],
	["Most composites are hard to recycle because their materials are bonded.", true],
	["In reinforced concrete, steel bars take the stretching (tension).", true],
	["A composite is one pure material.", false],
	["In a fibre composite, the matrix gives most of the strength.", false],
	["Carbon fibre is heavier than steel for the same strength.", false]]
## Open and closed loops: [system, closed, what is fed back].
const LOOPS: Array = [["a toaster on a timer", false, ""], ["a microwave set for 2 minutes", false, ""],
	["a hand-held fan with a switch", false, ""], ["a hand dryer that runs for 30 seconds", false, ""],
	["a heater with a thermostat", true, "the room's temperature, measured again"],
	["a fridge that keeps itself at 4 °C", true, "the temperature inside it"],
	["an oven held at 180 °C", true, "the oven's own temperature"],
	["a greenhouse fan with a temperature sensor", true, "the air's temperature in the greenhouse"],
	["a car's cruise control", true, "the car's speed"]]
## Structures: [feature, its job]; [load, kind].
const FEATURES: Array = [["tuned mass damper", "swings against the sway"],
	["base isolation", "lets the ground move underneath"], ["cross-bracing", "triangles stop the frame leaning"],
	["deep piles", "reach down to firm ground"], ["a rounded shape", "lets the wind slip past"],
	["expansion joints", "give room to grow in heat"], ["a wide base", "keeps it from tipping"]]
const LOADS: Array = [["the bridge's own deck", "dead"], ["the steel frame", "dead"], ["the concrete floors", "dead"],
	["lorries crossing", "live"], ["people in the stadium", "live"], ["furniture and people", "live"],
	["a strong wind", "environmental"], ["snow on the roof", "environmental"], ["an earthquake", "environmental"]]
## Nutrients: [nutrient, its job, foods]; deficiencies: [nutrient, what a long lack can lead to].
const NUTRIENTS: Array = [["carbohydrate", "the body's main energy source", "bread, rice, pasta"],
	["protein", "growth and repair", "beans, eggs, fish"], ["fat", "an energy store and warmth", "oils, nuts, cheese"],
	["fibre", "keeps digestion healthy", "wholegrains, fruit"], ["vitamin C", "healing and healthy skin",
	"oranges, peppers"], ["vitamin D", "helps take in calcium", "sunlight, oily fish"],
	["calcium", "strong bones and teeth", "milk, yoghurt"], ["iron", "red blood cells carry oxygen",
	"beans, red meat, spinach"], ["vitamin A", "seeing in dim light", "carrots, eggs"]]
const DEFICIENCIES: Array = [["vitamin D", "soft, weak bones (rickets)"], ["iron", "tiredness (anaemia)"],
	["vitamin C", "bleeding gums (scurvy)"], ["vitamin A", "poor sight in dim light"]]
const GLUTEN: Array = [["bread made from wheat", true], ["pasta", true], ["barley soup", true], ["rye crackers", true],
	["couscous", true], ["rice", false], ["potatoes", false], ["corn tortillas", false], ["eggs", false],
	["fresh fruit", false], ["lentils", false]]
const VEGAN: Array = [["lentil curry", true], ["tofu stir-fry", true], ["falafel", true], ["an apple", true],
	["peanut butter", true], ["cheese", false], ["honey", false], ["eggs", false], ["milk chocolate", false],
	["fish fingers", false], ["yoghurt", false]]
## Food processing: [step, primary].
const PROCESSING: Array = [["milling wheat into flour", true], ["pasteurising milk", true],
	["washing and sorting potatoes", true], ["pressing oil from seeds", true], ["cutting meat into joints", true],
	["baking bread from flour", false], ["making cheese from milk", false], ["making crisps from potatoes", false],
	["making pasta from flour", false], ["making jam from fruit", false], ["making yoghurt from milk", false]]
const FOOD_CHAINS: Array = [["wheat grows", "harvest it", "mill it into flour", "bake bread", "deliver to shops"],
	["cows are milked", "chill the milk", "pasteurise it", "make cheese", "sell it"],
	["potatoes grow", "dig them up", "wash and sort them", "make crisps", "pack them"]]
## Greenhouse gases for each kilogram of food (kg, about; Poore and Nemecek, 2018).
const FOOTPRINT := {"beef": 100, "cheese": 24, "chicken": 10, "eggs": 5, "tofu": 3, "peas": 1}
## The circular economy's loops, best first; actions and their loop; cases.
const LOOP_RANK: Array[String] = ["maintain", "reuse", "refurbish", "recycle", "landfill"]
const LOOP_ACTIONS: Array = [["oiling a bike chain so it lasts", "maintain"], ["mending a torn backpack", "maintain"],
	["passing a coat on to a cousin", "reuse"], ["selling a phone second-hand", "reuse"],
	["fixing up old laptops to sell again", "refurbish"], ["rebuilding old engines as good as new", "refurbish"],
	["melting cans into new metal", "recycle"], ["turning bottles into fleece", "recycle"],
	["putting peel in the compost bin", "compost"], ["rotting garden leaves into soil", "compost"]]
const CIRCULAR_CASES: Array = [
	["The school's laptops are slow but still work.", "refurbish them with new parts",
		["send them to landfill", "melt them for metal", "buy new ones at once"]],
	["A chair's leg has worked loose.", "tighten or glue the joint", ["recycle the chair", "throw it away",
		"buy a new chair"]],
	["Old cotton T-shirts are too worn to wear.", "reuse them as cleaning cloths", ["put them in landfill",
		"burn them", "keep them in a drawer for ever"]],
]
const EASY_REPAIR: Array[String] = ["held together with screws", "made from standard parts", "a battery you can swap",
	"a free repair guide", "parts that unclip", "spare parts for 10 years"]
const HARD_REPAIR: Array[String] = ["glued shut", "special screws only the maker has", "a sealed-in battery",
	"no spare parts sold", "parts welded together", "no repair information"]
const REPAIR_CASES: Array = [
	["Designing a toy so its parts can be recycled.", "parts that unclip, one material each",
		["glue three plastics together", "weld it shut", "paint it in mixed layers"]],
	["Designing a torch so it lasts for years.", "a battery and bulb you can swap",
		["a sealed-in battery", "a body glued shut", "special screws only"]],
	["Designing a chair to be mended.", "standard bolts and a repair guide", ["glued joints only",
		"one-off parts with no spares", "a body welded together"]],
]
const PRODUCTS: Array[String] = ["kettle", "toaster", "school bag", "lamp", "bike light", "torch"]
## Technology's effects: [effect, kind].
const IMPACTS: Array = [["people can talk to family far away", "social"],
	["robots do dangerous jobs instead of people", "social"], ["some people spend less time with friends", "social"],
	["data centres use a lot of electricity", "environmental"], ["old devices become e-waste", "environmental"],
	["better batteries store solar power", "environmental"], ["new jobs designing robots", "economic"],
	["some jobs disappear", "economic"], ["products get cheaper to make", "economic"],
	["who is to blame if a robot makes a mistake?", "ethical"], ["should cameras see faces without asking?", "ethical"]]
const IMPACT_KINDS: Array[String] = ["social", "environmental", "economic", "ethical"]
## Driving automation, levels 0-5.
const AUTOMATION: Array[String] = ["gives no help: the driver does everything", "helps with speed or with steering",
	"steers and controls speed while the driver watches", "drives itself in some places; you take over when asked",
	"drives itself in set areas, with no takeover needed", "drives itself anywhere, in any conditions"]
const AUTOMATION_QS: Array = [
	["At level 2, who must watch the road?", "the driver, all the time", ["nobody", "the car only",
		"a passenger"]],
	["At level 3, what must the driver be ready to do?", "take over when the car asks",
		["sleep", "leave the car", "nothing at all"]],
	["Which level needs no driver anywhere?", "level 5", ["level 1", "level 2", "level 3"]],
	["A car keeps its lane but you steer round corners. Level?", "level 1", ["level 0", "level 4", "level 5"]],
]
## A project's parts: [part, gold].
const PARTS: Array = [["a moisture sensor", 3], ["a small pump", 6], ["a battery box", 2], ["tubing", 1.5],
	["a case", 4], ["a board", 8], ["wires", 0.5], ["an LED", 0.25], ["a buzzer", 1.25]]
## Sources: [source, primary].
const SOURCES: Array = [["a letter written in 1830 about the railway", true],
	["a photo taken the day the Berlin Wall fell", true], ["a newspaper printed in July 1969", true],
	["an interview with someone who was there", true], ["a ticket from the first inter-city railway", true],
	["a poster from 1918 about votes for women", true], ["a textbook chapter written in 2015", false],
	["a documentary made in 2010", false], ["a website summarising the Moon landing", false],
	["a historian's book about votes for women", false], ["an encyclopedia entry", false]]
const SOURCE_QS: Array = [
	["A 1918 poster asking for votes for women is…", "useful, but made to persuade",
		["neutral and complete", "a secondary source", "useless because it is old"]],
	["Two sources disagree about an event. What should you do?", "compare them, and look for a third",
		["use the first one you found", "make up the answer", "pick the shorter one"]],
	["Why credit your sources in a documentary?", "so viewers can check the facts",
		["to make it longer", "because it sounds clever", "so nobody asks questions"]],
]
## Turning points: [event, year].
const TURNING: Array = [["the first inter-city railway opens", 1830], ["the first powered flight", 1903],
	["some UK women win the vote", 1918], ["UK women vote on equal terms", 1928], ["the NHS is founded", 1948],
	["the first Moon landing", 1969], ["the Berlin Wall falls", 1989], ["the first website goes live", 1991]]
## Survey questions: [question, fair]; samples.
const SURVEY_QS: Array = [["How do you usually travel to school?", true],
	["How many glasses of water do you drink a day?", true], ["How often do you visit the beach?", true],
	["How many minutes do you spend outside each day?", true],
	["Don't you agree that litter is disgusting?", false], ["Wouldn't you love more cycle lanes?", false],
	["Most people care about the planet. Do you?", false], ["Surely driving short trips is wrong?", false]]
const SAMPLE_QS: Array = [
	["To find how Year 9 travels to school, who should you ask?", "a random 30 from all Year 9 classes",
		["only your friends", "only the cycling club", "only pupils who live nearby"]],
	["Why is a bigger sample usually better?", "the results are less likely to be a fluke",
		["it takes longer", "small samples are illegal", "it always gives 100%"]],
	["Litter is counted on one sunny Sunday only. What is the problem?", "one day may not be typical",
		["Sunday is not a day", "the sun hides litter", "nothing: one day is enough"]],
]
const CORRELATION_QS: Array = [
	["Towns with more cycle lanes have fewer car trips to school. This shows…",
		"they go together, which doesn't prove cause", ["cycle lanes must cause it", "there is no link at all",
		"the data must be wrong"]],
	["Ice cream sales and sunburn both rise in summer. Why?", "a third thing, sunny weather, drives both",
		["ice cream causes sunburn", "sunburn makes people buy ice cream", "it is pure luck every year"]],
	["The points slope down from left to right. The correlation is…", "negative",
		["positive", "none", "perfect"]],
]


# --- Health and PE: game strategy ---------------------------------------------------------------------------------------

static func _lines(f: String) -> Array[int]:
	var out: Array[int] = []
	for part in f.split("-"):
		out.append(int(part))
	return out


## A formation's players on a pitch, attacking to the right: the keeper, then each line.
static func _formation_pitch(f: String) -> Dictionary:
	var players: Array = [[0.6, 3.5, "a", "GK"]]
	var xs: Array[float] = [3.0, 6.5, 10.0]
	var lines := _lines(f)
	for k in 3:
		var n := lines[k]
		for i in n:
			players.append([xs[k], 7.0 * (i + 1) / (n + 1), "a"])
	return {"kind": "pitch", "cols": 12, "rows": 7, "players": players}


## Formations: level 1, a line's number on the pitch; level 2, the formation with the most in a line; level 3, how many
## more midfielders one formation has than another.
static func formation(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var f := FORMATIONS[rng.randi_range(0, FORMATIONS.size() - 1)]
			var k := rng.randi_range(0, 2)
			var lines := _lines(f)
			ex = K.number("Your team plays %s (the goalkeeper is not counted). How many %s are there?" % [f, LINES[k]],
				lines[k], "A formation counts from the back: defenders, then midfielders, then strikers.",
				"%s: %d defenders, %d midfielders and %d strikers, so %d %s." % [f, lines[0], lines[1], lines[2],
				lines[k], LINES[k]], _formation_pitch(f))
			ex.data = {"formation": f, "line": k}
		2:
			var k := rng.randi_range(0, 2)
			var picks: Array = []
			for _t in 40:
				var pool := FORMATIONS.duplicate()
				K.shuffle(rng, pool)
				picks = pool.slice(0, 3)
				var counts: Array = picks.map(func(f: String) -> int: return _lines(f)[k])
				var top: int = counts.max()
				if counts.count(top) == 1:
					break
			var best: String = picks[0]
			for f: String in picks:
				if _lines(f)[k] > _lines(best)[k]:
					best = f
			var others: Array = picks.filter(func(f: String) -> bool: return f != best)
			var said: Array = picks.map(func(f: String) -> String: return "%s has %d" % [f, _lines(f)[k]])
			ex = K.choice(rng, "Which formation has the most %s?" % LINES[k], best, others,
				"Find the right number in each: the first is defenders, the middle midfielders, the last strikers.",
				"%s: so %s." % [W._and(said), best])
			ex.data = {"formations": picks, "line": k}
		_:
			var mine := ""
			var theirs := ""
			while mine == theirs or _lines(mine)[1] <= _lines(theirs)[1]:
				mine = FORMATIONS[rng.randi_range(0, FORMATIONS.size() - 1)]
				theirs = FORMATIONS[rng.randi_range(0, FORMATIONS.size() - 1)]
			var a := _lines(mine)[1]
			var b := _lines(theirs)[1]
			ex = K.number("Your team plays %s and the other team plays %s. How many more players does your team have in midfield?" % [
				mine, theirs], a - b, "Compare the middle numbers of the two formations.",
				"%s has %d in midfield and %s has %d: %d − %d = %d, an overload that helps you keep the ball." % [mine, a,
				theirs, b, a, b, a - b])
			ex.data = {"formation": mine, "other": theirs}
	return ex


## Match statistics: level 1, pass completion; level 2, possession; level 3, a rise in completion in percentage points.
static func match_stats(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var tried := [100, 200, 250, 300, 400, 500][rng.randi_range(0, 5)] as int
			var pct := _whole_pct(rng, tried, 60, 95)
			var done := tried * pct / 100
			ex = K.number("A team tried %d passes and completed %d. What percentage of its passes were completed?" % [
				tried, done], pct, "Divide the completed passes by the passes tried, then multiply by 100.",
				"%d ÷ %d × 100 = %d%%." % [done, tried, pct])
			ex.data = {"done": done, "tried": tried}
		2:
			var total := [50, 60][rng.randi_range(0, 1)] as int
			var pct := _whole_pct(rng, total, 50, 80)
			var had := total * pct / 100
			var team := ["Red", "Blue", "Green"][rng.randi_range(0, 2)] as String
			ex = K.number("The ball was in play for %d minutes. %s had it for %d of them. What was %s's possession, in percent?" % [
				total, team, had, team], pct, "Possession is the share of the time with the ball: divide, then times 100.",
				"%d ÷ %d × 100 = %d%%." % [had, total, pct])
			ex.data = {"had": had, "total": total}
		_:
			var t1 := [80, 100, 120, 160, 200][rng.randi_range(0, 4)] as int
			var t2 := [80, 100, 120, 160, 200][rng.randi_range(0, 4)] as int
			var p1 := _whole_pct(rng, t1, 55, 80)
			var p2 := p1
			for _t in 30:
				p2 = _whole_pct(rng, t2, 60, 95)
				if p2 > p1:
					break
			if p2 <= p1:
				t2 = 100
				p2 = p1 + 10
			var d1 := t1 * p1 / 100
			var d2 := t2 * p2 / 100
			ex = K.number("First half: %d of %d passes completed. Second half: %d of %d. By how many percentage points did the completion rate rise?" % [
				d1, t1, d2, t2], p2 - p1, "Work out each half's percentage first, then subtract.",
				"%d ÷ %d = %d%% and %d ÷ %d = %d%%: %d − %d = %d percentage points." % [d1, t1, p1, d2, t2, p2, p2, p1,
				p2 - p1])
			ex.data = {"d1": d1, "t1": t1, "d2": d2, "t2": t2}
	return ex


## A whole percentage from lo to hi that is a whole number of `n` (n × pct ÷ 100 whole).
static func _whole_pct(rng: RandomNumberGenerator, n: int, lo: int, hi: int) -> int:
	var ok: Array = []
	for p in range(lo, hi + 1):
		if (n * p) % 100 == 0:
			ok.append(p)
	return int(ok[rng.randi_range(0, ok.size() - 1)]) if not ok.is_empty() else 50


## Changing tactics: a game's situation and the best change (harder situations at higher levels).
static func tactic_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = TACTIC_CASES.filter(func(c: Array) -> bool: return int(c[0]) == level)
	var c: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var ex := K.choice(rng, "%s What is the best change?" % c[1], str(c[2]), c[3],
		"Read the game: where is the space, and what is the other team doing well?",
		"Best: %s. A good change answers what the game shows." % c[2])
	ex.data = {"situation": c[1]}
	return ex


# --- Fitness testing ------------------------------------------------------------------------------------------------------

static func _component(test: String) -> String:
	for t: Array in TESTS:
		if str(t[0]) == test:
			return str(t[1])
	return ""


## Fitness tests: level 1, what a test measures; level 2, tests matched to parts; level 3, a valid test for a part.
static func fitness_test(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := TESTS.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var t: Array = pool[0]
			var wrongs := _other_values(pool, 1, str(t[1]), 3)
			ex = K.choice(rng, "Which part of fitness does the %s measure?" % t[0], str(t[1]), wrongs,
				"Picture the test: running, reaching, gripping, jumping or reacting?",
				"The %s measures %s." % [t[0], t[1]])
			ex.data = {"test": t[0]}
		2:
			var picked := _distinct_by(pool, 1, 4)
			ex = W._match(rng, "Match each test to the part of fitness it measures.", picked.map(func(t: Array) -> String:
				return str(t[0])), picked.map(func(t: Array) -> String: return str(t[1])),
				"What does each test make you do, and for how long?", W._and(picked.map(func(t: Array) -> String:
				return "%s: %s" % [t[0], t[1]])) + ".")
			ex.data = {"tests": picked.map(func(t: Array) -> String: return str(t[0]))}
		_:
			var t: Array = pool[0]
			var who := _who(rng)
			var wrongs: Array = []
			for o: Array in pool:
				if str(o[1]) != str(t[1]) and wrongs.size() < 3:
					wrongs.append(str(o[0]))
			ex = K.choice(rng, "%s wants a valid test of %s: one that measures it and nothing else. Which test?" % [who,
				t[1]], str(t[0]), wrongs, "Valid means it tests the part you want. Which test only needs that part?",
				"The %s measures %s, so it is a valid test of it." % [t[0], t[1]])
			ex.data = {"component": t[1], "test": t[0]}
	return ex


## A test's results: level 1, the best of three tries; level 2, the mean of three; level 3, the improvement in percent.
static func test_result(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t: Array = RESULT_TESTS[rng.randi_range(0, RESULT_TESTS.size() - 1)]
	var unit := str(t[1])
	var lower := bool(t[2])
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1, 2:
			var mid := _result_mid(rng, str(t[0]))
			var step := 0.1 if lower else 1.0
			var spread := rng.randi_range(1, 4)
			var vals: Array[float] = [mid - spread * step, mid, mid + spread * step]
			if level == 1:
				vals[2] = mid + rng.randi_range(1, 3) * step
			var shown := vals.duplicate()
			K.shuffle(rng, shown)
			var texts: Array = shown.map(func(v: float) -> String: return "%s %s" % [W._num_text(v), unit])
			if level == 1:
				var best: float = shown.min() if lower else shown.max()
				ex = K.number("%s's three tries at the %s: %s. What is the best result, in %s?" % [who, t[0], W._and(texts),
					unit], W._num_text(best), "In a timed test the lowest time is best; for distance or force, the biggest." if lower else
					"For a distance or a force, the biggest number is best; for a time, the lowest.",
					"%s: the best is %s %s." % ["Lower is better" if lower else "Higher is better", W._num_text(best), unit])
			else:
				var sum := 0.0
				for v in shown:
					sum += v
				var mean := snappedf(sum / 3.0, 0.01)
				ex = K.number("%s's three tries at the %s: %s. What is the mean, in %s?" % [who, t[0], W._and(texts), unit],
					W._num_text(mean), "Add the three results, then divide by 3.",
					"%s = %s; %s ÷ 3 = %s %s." % [" + ".join(PackedStringArray(shown.map(func(v: float) -> String:
					return W._num_text(v)))), W._num_text(snappedf(sum, 0.01)), W._num_text(snappedf(sum, 0.01)),
					W._num_text(mean), unit])
			ex.data = {"test": t[0], "values": shown}
		_:
			var pair := _improvement(rng, lower)
			var old := float(pair[0])
			var now := float(pair[1])
			var pct := int(pair[2])
			ex = K.number("%s's %s went from %s %s to %s %s. By what percentage did it improve?" % [who, t[0],
				W._num_text(old), unit, W._num_text(now), unit], pct,
				"Find the change, divide it by the first result, then times 100." + (" Here a lower time is better." if lower
				else ""), "%s − %s = %s; %s ÷ %s × 100 = %d%%." % [W._num_text(maxf(old, now)), W._num_text(minf(old, now)),
				W._num_text(absf(old - now)), W._num_text(absf(old - now)), W._num_text(old), pct])
			ex.data = {"test": t[0], "old": old, "new": now}
	return ex


## A typical middle result for a test (seconds to one decimal place, or whole cm and kg).
static func _result_mid(rng: RandomNumberGenerator, test: String) -> float:
	match test:
		"30 m sprint":
			return rng.randi_range(45, 60) / 10.0
		"Illinois agility run":
			return rng.randi_range(160, 210) / 10.0
		"sit-and-reach test":
			return float(rng.randi_range(15, 35))
		"vertical jump":
			return float(rng.randi_range(30, 50))
		"hand-grip test":
			return float(rng.randi_range(20, 35))
	return float(rng.randi_range(150, 210))


## [old, new, percent] with a whole percent improvement and a result of at most one decimal place.
static func _improvement(rng: RandomNumberGenerator, lower: bool) -> Array:
	var pairs: Array = []
	if lower:
		for old: float in [5.0, 6.0, 8.0, 10.0, 12.0, 15.0, 16.0, 20.0]:
			for p: int in [5, 10, 20, 25]:
				var now := old * (100 - p) / 100.0
				if is_equal_approx(now * 10.0, roundf(now * 10.0)):
					pairs.append([old, snappedf(now, 0.1), p])
	else:
		for old: float in [10.0, 20.0, 25.0, 30.0, 40.0, 50.0]:
			for p: int in [10, 20, 25, 50]:
				var now := old * (100 + p) / 100.0
				if is_equal_approx(now, roundf(now)):
					pairs.append([old, now, p])
	return pairs[rng.randi_range(0, pairs.size() - 1)]


## A fitness profile: level 1, one part's score; level 2, the weakest part; level 3, the part a retest improved most.
static func profile_read(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := PROFILE_PARTS.duplicate()
	K.shuffle(rng, names)
	var n := rng.randi_range(4, 6)
	var top := 5 if level < 3 else 10
	var parts: Array = []
	for _t in 60:
		parts.clear()
		for i in n:
			parts.append([names[i], rng.randi_range(1, top - 1)])
		var scores: Array = parts.map(func(p: Array) -> int: return int(p[1]))
		if scores.count(scores.min()) == 1:
			break
	var who := _who(rng)
	var pic := {"kind": "fitness_profile", "parts": parts, "top": top}
	var ex: Dictionary
	match level:
		1:
			var k := rng.randi_range(0, n - 1)
			ex = K.number("%s's fitness profile: what is the score for %s?" % [who, parts[k][0]], int(parts[k][1]),
				"Follow that part's spoke out from the middle; each ring is one more point.",
				"The blue shape crosses the %s spoke at ring %d, so the score is %d." % [parts[k][0], parts[k][1],
				parts[k][1]], pic)
			ex.data = {"part": parts[k][0]}
		2:
			var weak := SchoolPictureG8Life.weakest(parts)
			var others: Array = parts.map(func(p: Array) -> String: return str(p[0])).filter(func(s: String) -> bool:
				return s != weak)
			K.shuffle(rng, others)
			ex = K.choice(rng, "Which part of fitness is weakest in %s's profile?" % who, weak, others.slice(0, 3),
				"Find the spoke where the blue shape comes closest to the middle.",
				"%s has the lowest score, so it is the part to train first." % W._cap(weak), pic)
			ex.data = {}
		_:
			var after: Array = []
			var gains: Array = []
			for _t in 60:
				after.clear()
				gains.clear()
				for p: Array in parts:
					var g := rng.randi_range(0, 3)
					after.append(mini(int(p[1]) + g, top))
					gains.append(int(after[-1]) - int(p[1]))
				if gains.count(gains.max()) == 1:
					break
			pic.after = after
			var best := str(parts[gains.find(gains.max())][0])
			var others: Array = parts.map(func(p: Array) -> String: return str(p[0])).filter(func(s: String) -> bool:
				return s != best)
			K.shuffle(rng, others)
			ex = K.choice(rng, "The orange line is %s's retest. Which part improved the most?" % who, best,
				others.slice(0, 3), "On each spoke, count the rings from the blue point out to the orange one.",
				"%s went up by %d rings, more than any other part." % [W._cap(best), gains.max()], pic)
			ex.data = {"after": after}
	ex.data.parts = parts
	return ex


# --- Active for life ------------------------------------------------------------------------------------------------------

## A week of activity: level 1, a weekly target shared over days; level 2, moderate minutes with vigorous ones counted
## twice; level 3, the minutes still needed to reach 150.
static func week_activity(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	if level == 1:
		var opts := [[150, 3, "moderate"], [150, 5, "moderate"], [150, 6, "moderate"], [75, 3, "vigorous"],
			[75, 5, "vigorous"]]
		var o: Array = opts[rng.randi_range(0, opts.size() - 1)]
		ex = K.number("Adults are advised at least %d minutes of %s activity a week. %s spreads it over %d days. How many minutes a day?" % [
			o[0], o[2], who, o[1]], int(o[0]) / int(o[1]), "Share the week's minutes equally: divide by the days.",
			"%d ÷ %d = %d minutes a day." % [o[0], o[1], int(o[0]) / int(o[1])])
		ex.data = {"minutes": o[0], "days": o[1]}
		return ex
	var sessions: Array = []
	var total := 0
	for _t in 60:
		sessions.clear()
		total = 0
		var pool := SESSIONS.duplicate()
		K.shuffle(rng, pool)
		for i in 2:
			var n := rng.randi_range(2, 3)
			var m := [15, 20, 25, 30][rng.randi_range(0, 3)] as int
			sessions.append([n, m, pool[i][0], pool[i][1]])
			total += n * m * (2 if bool(pool[i][1]) else 1)
		if level == 2 or total < 150:
			break
	if level == 3 and total >= 150:
		sessions = [[2, 20, "brisk walks", false], [2, 15, "runs", true]]
		total = 100
	var said: Array = sessions.map(func(s: Array) -> String: return "%d %s of %d minutes" % [s[0], s[2], s[1]])
	var working: Array = sessions.map(func(s: Array) -> String: return "%d × %d%s = %d" % [s[0], s[1], " × 2" if
		bool(s[3]) else "", int(s[0]) * int(s[1]) * (2 if bool(s[3]) else 1)])
	if level == 2:
		ex = K.number("Vigorous minutes count double. %s did %s this week. How many moderate minutes is that?" % [
			who, W._and(said)], total, "Runs, games and fast swims are vigorous: double those minutes, then add.",
			"%s; in all %d moderate minutes." % ["; ".join(PackedStringArray(working)), total])
	else:
		ex = K.number("Vigorous minutes count double. %s did %s. How many more moderate minutes reach 150 this week?" % [
			who, W._and(said)], 150 - total, "Work out the week's moderate minutes first, then take them from 150.",
			"%s; %d so far, and 150 − %d = %d more." % ["; ".join(PackedStringArray(working)), total, total, 150 - total])
	ex.data = {"sessions": sessions}
	return ex


## Kinds of activity: level 1, a muscle-strengthening one; level 2, aerobic or strengthening; level 3, team, solo or an
## outdoor adventure.
static func activity_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var a := AEROBIC.duplicate()
			K.shuffle(rng, a)
			var s := STRENGTHENING[rng.randi_range(0, STRENGTHENING.size() - 1)]
			ex = K.choice(rng, "Which of these is a muscle-strengthening activity?", s, a.slice(0, 3),
				"Which one makes your muscles work against a load, not keep your heart going for a long time?",
				"%s make muscles work hard against a load; the others are aerobic." % W._cap(s))
			ex.data = {"right": s}
		2:
			var items: Array = []
			var a := AEROBIC.duplicate()
			var s := STRENGTHENING.duplicate()
			K.shuffle(rng, a)
			K.shuffle(rng, s)
			var na := rng.randi_range(2, 3)
			for i in na:
				items.append([a[i], "aerobic"])
			for i in 5 - na:
				items.append([s[i], "muscle-strengthening"])
			ex = W._sort(rng, "Aerobic, or muscle-strengthening?", ["aerobic", "muscle-strengthening"], items,
				"Aerobic keeps you moving and puffing for a while; strengthening works muscles against a load.",
				W._sorted_words(["aerobic", "muscle-strengthening"], items))
			ex.data = {"items": items}
		_:
			var items: Array = []
			for kind: String in ["team", "solo", "outdoor adventure"]:
				var pool: Array = KIND_OF_SPORT.filter(func(k: Array) -> bool: return str(k[1]) == kind)
				K.shuffle(rng, pool)
				items.append_array(pool.slice(0, 2))
			ex = W._sort(rng, "A team game, a solo activity, or an outdoor adventure?", ["team", "solo", "outdoor adventure"],
				items, "Do you play with teammates, do it on your own, or go out into wild places?",
				W._sorted_words(["team", "solo", "outdoor adventure"], items))
			ex.data = {"items": items}
	return ex


# --- Looking after mental health ------------------------------------------------------------------------------------------

## Thinking traps: level 1, name the trap; level 2, match thoughts to traps; level 3, a balanced thought.
static func thinking_trap(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := TRAP_THOUGHTS.duplicate()
	K.shuffle(rng, pool)
	var t: Array = pool[0]
	var ex: Dictionary
	match level:
		1:
			var wrongs: Array = TRAPS.filter(func(x: String) -> bool: return x != str(t[1]))
			ex = K.choice(rng, "Which thinking trap is this? '%s'" % t[0], str(t[1]), wrongs,
				"Is it expecting the worst, guessing others' minds, seeing only extremes, or predicting the future?",
				"'%s' is %s. A balanced thought: '%s'" % [t[0], t[1], t[2]])
			ex.data = {"thought": t[0]}
		2:
			var picked := _distinct_by(pool, 1, 3)
			ex = W._match(rng, "Match each thought to its thinking trap.", picked.map(func(p: Array) -> String:
				return str(p[3])), picked.map(func(p: Array) -> String: return str(p[1])),
				"Ask of each: is it expecting the worst, guessing minds, all-or-nothing, or telling the future?",
				W._and(picked.map(func(p: Array) -> String: return "'%s': %s" % [p[3], p[1]])) + ".")
			ex.data = {"thoughts": picked.map(func(p: Array) -> String: return str(p[0]))}
		_:
			var wrongs: Array = []
			for o: Array in pool.slice(1):
				if str(o[1]) != str(t[1]) and wrongs.size() < 3:
					wrongs.append(o[2])
			ex = K.choice(rng, "Which is a balanced thought instead of: '%s'" % t[0], str(t[2]), wrongs,
				"A balanced thought is fair and true, and fits this exact worry.",
				"'%s' answers the trap (%s) with something fair and true." % [t[2], t[1]])
			ex.data = {"thought": t[0]}
	return ex


## Coping: level 1, helpful or not; level 2, sort helpful and unhelpful ways; level 3, what to do in a situation.
static func coping_choice(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var helpful := rng.randf() < 0.5
			var pool: Array = HELPFUL if helpful else UNHELPFUL
			var w := str(pool[rng.randi_range(0, pool.size() - 1)])
			ex = K.truefalse("%s is a helpful way to cope with stress." % W._cap(w), helpful,
				"Does it help in the long run, or only feel better for a moment?",
				("True: %s helps." if helpful else "False: %s may feel easier now, but it makes things worse later.") % w)
			ex.data = {"way": w}
		2:
			var h := HELPFUL.duplicate()
			var u := UNHELPFUL.duplicate()
			K.shuffle(rng, h)
			K.shuffle(rng, u)
			var nh := rng.randi_range(2, 3)
			var items: Array = []
			for i in nh:
				items.append([h[i], "helpful"])
			for i in 5 - nh:
				items.append([u[i], "unhelpful"])
			ex = W._sort(rng, "Helpful or unhelpful ways to cope?", ["helpful", "unhelpful"], items,
				"Helpful ways still help next week; unhelpful ones only hide the worry.",
				W._sorted_words(["helpful", "unhelpful"], items))
			ex.data = {"items": items}
		_:
			var c: Array = HELP_CASES[rng.randi_range(0, HELP_CASES.size() - 1)]
			ex = K.choice(rng, "%s What is the best thing to do?" % c[0], str(c[1]), c[2],
				"Which choice gets the right support, from the right person, soon?",
				"Best: %s. Talking to a trusted adult gets real help." % c[1])
			ex.data = {"situation": c[0]}
	return ex


# --- Bouncing back --------------------------------------------------------------------------------------------------------

## The three traps after a setback: level 1, name it; level 2, match thoughts to traps; level 3, a resilient reframe.
static func three_ps(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := P_THOUGHTS.duplicate()
	K.shuffle(rng, pool)
	var t: Array = pool[0]
	var ex: Dictionary
	match level:
		1:
			ex = K.choice(rng, "Which trap is this thought after a setback? '%s'" % t[0], str(t[1]),
				P_TRAPS.filter(func(x: String) -> bool: return x != str(t[1])),
				"Does it say it will last for ever, spread to all of life, or be only your fault?",
				"'%s' is the '%s' trap. Instead: '%s'" % [t[0], t[1], t[2]])
			ex.data = {"thought": t[0]}
		2:
			var picked := _distinct_by(pool, 1, 3)
			ex = W._match(rng, "Match each thought to its trap.", picked.map(func(p: Array) -> String:
				return str(p[3])), picked.map(func(p: Array) -> String: return str(p[1])),
				"Look for 'never' and 'always', 'everything', and 'my fault'.",
				W._and(picked.map(func(p: Array) -> String: return "'%s': %s" % [p[3], p[1]])) + ".")
			ex.data = {"thoughts": picked.map(func(p: Array) -> String: return str(p[0]))}
		_:
			var wrongs: Array = [t[0]]
			for o: Array in pool.slice(1):
				if str(o[1]) != str(t[1]) and wrongs.size() < 3:
					wrongs.append(o[2])
			ex = K.choice(rng, "Which is a resilient way to think instead of: '%s'" % t[0], str(t[2]), wrongs,
				"Choose the thought that is just as true, but says it is for now, about one thing, and shared.",
				"'%s' turns the '%s' trap into something fair and hopeful." % [t[2], t[1]])
			ex.data = {"thought": t[0]}
	return ex


## Bouncing back: level 1, the steps in order; level 2, what went well or even better if; level 3, a next step.
static func review_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			ex = K.order(rng, "Put the bounce-back steps in order.", BOUNCE_STEPS,
				"Feelings first, then thinking, then doing.",
				"Notice the feeling, calm your body, look at what happened, plan one next step, then try again.")
			ex.data = {}
		2:
			var a := WENT_WELL.duplicate()
			var b := EVEN_BETTER.duplicate()
			K.shuffle(rng, a)
			K.shuffle(rng, b)
			var na := rng.randi_range(2, 3)
			var items: Array = []
			for i in na:
				items.append([a[i], "what went well"])
			for i in 5 - na:
				items.append([b[i], "even better if"])
			ex = W._sort(rng, "Sort the review: what went well, or even better if…?", ["what went well", "even better if"],
				items, "What went well is something done; even better if is a change for next time.",
				W._sorted_words(["what went well", "even better if"], items))
			ex.data = {"items": items}
		_:
			var c: Array = SETBACKS[rng.randi_range(0, SETBACKS.size() - 1)]
			ex = K.choice(rng, "%s What is the best next step?" % c[0], str(c[1]), c[2],
				"Which step learns from what happened and leads to trying again?",
				"Best: %s. A setback is information for the next try." % c[1])
			ex.data = {"setback": c[0]}
	return ex


# --- Respect online -------------------------------------------------------------------------------------------------------

## Online friendships: level 1, healthy or not; level 2, sort healthy and warning signs; level 3, what to do.
static func online_sign(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var healthy := rng.randf() < 0.5
			var pool: Array = HEALTHY_SIGNS if healthy else WARNING_SIGNS
			var s := str(pool[rng.randi_range(0, pool.size() - 1)])
			ex = K.truefalse("In a healthy online friendship, the other person %s." % s, healthy,
				"Does it respect your choices, or try to control you?",
				("True: someone who %s respects you." if healthy else
				"False: someone who %s is trying to control you. Talk to a trusted adult.") % s)
			ex.data = {"sign": s}
		2:
			var h := HEALTHY_SIGNS.duplicate()
			var w := WARNING_SIGNS.duplicate()
			K.shuffle(rng, h)
			K.shuffle(rng, w)
			var nh := rng.randi_range(2, 3)
			var items: Array = []
			for i in nh:
				items.append([h[i], "healthy"])
			for i in 5 - nh:
				items.append([w[i], "warning sign"])
			ex = W._sort(rng, "Healthy, or a warning sign?", ["healthy", "warning sign"], items,
				"Healthy friends respect you; controlling ones check up, pressure or embarrass you.",
				W._sorted_words(["healthy", "warning sign"], items))
			ex.data = {"items": items}
		_:
			var c: Array = ONLINE_CASES[rng.randi_range(0, ONLINE_CASES.size() - 1)]
			ex = K.choice(rng, "%s What should you do?" % c[0], str(c[1]), c[2],
				"Which choice keeps everyone safe and gets a trusted adult's help?",
				"Best: %s. It is never your fault, and help is there." % c[1])
			ex.data = {"situation": c[0]}
	return ex


## Respect online: level 1 and 3, what to do; level 2, the steps when someone is unkind, in order.
static func online_action(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 2:
		ex = K.order(rng, "Someone keeps sending you unkind messages. Put the steps in order.", REPORT_STEPS,
			"First stop it growing, then save the proof, then stop and report them, then get help.",
			"Don't reply, keep the evidence, block the person, report it, and tell a trusted adult.")
		ex.data = {}
		return ex
	var pool: Array = RESPECT_CASES.slice(0, 2) if level == 1 else RESPECT_CASES.slice(2)
	var c: Array = pool[rng.randi_range(0, pool.size() - 1)]
	ex = K.choice(rng, str(c[0]), str(c[1]), c[2], "What would you want someone to do if it were about you?",
		"Best: %s. Respect online is the same as face to face." % c[1])
	ex.data = {"situation": c[0]}
	return ex


# --- Chance, gambling and spending ----------------------------------------------------------------------------------------

## A prize wheel: [[label, count, gold], …] with 10 or 20 slices, one big prize, a few small ones and the rest nothing.
static func _wheel(rng: RandomNumberGenerator) -> Array:
	for _t in 60:
		var total := [10, 20][rng.randi_range(0, 1)] as int
		var big := [5, 8, 10][rng.randi_range(0, 2)] as int
		var small_n := rng.randi_range(1, 3)
		var small := rng.randi_range(1, 2)
		if big + small_n * small < total:
			return [["%d gold" % big, 1, big], ["%d gold" % small, small_n, small], ["nothing", total - 1 - small_n, 0]]
	return [["5 gold", 1, 5], ["1 gold", 2, 1], ["nothing", 7, 0]]


## A prize wheel: level 1, the percentage of slices that win; level 2, the gold a spin wins on average; level 3, the gold
## lost over many spins on average.
static func wheel_odds(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var slices := _wheel(rng)
	var total := 0
	var winning := 0
	for s: Array in slices:
		total += int(s[1])
		winning += int(s[1]) if int(s[2]) > 0 else 0
	var cost := 1
	var pic := {"kind": "chance_wheel", "slices": slices, "cost": cost}
	var per := SchoolPictureG8Life.expected_win(slices)
	var said: Array = slices.filter(func(s: Array) -> bool: return int(s[2]) > 0).map(func(s: Array) -> String:
		return "%d × %d" % [s[1], s[2]])
	var won := 0
	for s: Array in slices:
		won += int(s[1]) * int(s[2])
	var ex: Dictionary
	match level:
		1:
			ex = K.number("What percentage of this wheel's slices win any prize?", W._num_text(winning * 100.0 / total),
				"Count the slices that win something, divide by all the slices, then times 100.",
				"%d of %d slices win: %d ÷ %d × 100 = %s%%." % [winning, total, winning, total,
				W._num_text(winning * 100.0 / total)], pic)
		2:
			ex = K.number("How much gold does one spin win, on average?", W._num_text(per),
				"Imagine spinning once for every slice: add up all the prizes, then share by the number of slices.",
				"%s = %d gold over %d slices: %d ÷ %d = %s gold a spin, less than the 1 gold it costs." % [
				" + ".join(PackedStringArray(said)), won, total, won, total, W._num_text(per)], pic)
		_:
			var spins := [10, 20, 50, 100][rng.randi_range(0, 3)] as int
			var lost := (cost - per) * spins
			ex = K.number("Each spin costs %d gold. Over %d spins, how much gold would you expect to lose, on average?" % [cost,
				spins], W._num_text(snappedf(lost, 0.01)),
				"Find what one spin wins on average, take it from the cost, then multiply by the spins.",
				"A spin wins %s gold on average, so each spin costs %d − %s = %s gold more than it pays back; × %d = %s gold." % [W._num_text(per),
				cost, W._num_text(per), W._num_text(snappedf(cost - per, 0.01)), spins, W._num_text(snappedf(lost, 0.01))],
				pic)
	ex.data = {"slices": slices}
	return ex


## Mystery boxes: level 1, a 1-in-N chance as a percentage; level 2, the boxes it takes on average; level 3, the gold.
static func loot_odds(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := [4, 5, 10, 20, 25, 50, 100, 200][rng.randi_range(0, 7)] as int
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A rare item comes from a mystery box with a chance of 1 in %d. What is that as a percentage?" % n,
				W._num_text(100.0 / n), "1 in %d means 1 ÷ %d; times 100 makes it a percentage." % [n, n],
				"1 ÷ %d × 100 = %s%%." % [n, W._num_text(100.0 / n)])
		2:
			ex = K.number("Each loot box has a 1 in %d chance of the rare item. On average, how many boxes does it take to get one?" % n,
				n, "If something happens 1 time in every N, how many tries does it take on average?",
				"1 in %d means once every %d boxes on average, and it could take many more." % [n, n])
		_:
			var cost := [1, 2, 3, 5][rng.randi_range(0, 3)] as int
			ex = K.number("Each loot box costs %d gold, and the rare item's chance is 1 in %d. On average, how much gold is spent to get it?" % [
				cost, n], cost * n, "Find how many boxes it takes on average, then multiply by the cost of one.",
				"About %d boxes × %d gold = %d gold, and with bad luck much more." % [n, cost, cost * n])
			ex.data = {"n": n, "cost": cost}
			return ex
	ex.data = {"n": n}
	return ex


## Chance: level 1, true or false; level 2, the true statement; level 3, the myth.
static func chance_myth(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var t := CHANCE_TRUE.duplicate()
	var f := CHANCE_FALSE.duplicate()
	K.shuffle(rng, t)
	K.shuffle(rng, f)
	var ex: Dictionary
	match level:
		1:
			var truth := rng.randf() < 0.5
			var s: String = t[0] if truth else f[0]
			ex = K.truefalse(s, truth, "Does chance remember what happened before? Who is the game designed to win?",
				("True: " + s) if truth else "False: chance has no memory, and the game is designed to win over time.")
			ex.data = {"statement": s}
		2:
			ex = K.choice(rng, "Which of these is true?", str(t[0]), f.slice(0, 3),
				"Chance has no memory, and the game is designed to win over time.",
				"True: %s The others are myths." % t[0])
			ex.data = {"statement": t[0], "truth": true}
		_:
			ex = K.choice(rng, "Which of these is a myth?", str(f[0]), t.slice(0, 3),
				"Spot the one that pretends chance can remember or be beaten.",
				"Myth: %s Each turn starts fresh, and the house keeps its share." % f[0])
			ex.data = {"statement": f[0], "truth": false}
	return ex


# --- Alcohol, drugs and peer pressure -------------------------------------------------------------------------------------

## Peer pressure: level 1, name the kind; level 2, sort direct and indirect; level 3, sort all three kinds.
static func pressure_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := PRESSURES.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var p: Array = pool[0]
			ex = K.choice(rng, "What kind of pressure is this? %s" % p[0], str(p[1]),
				PRESSURE_KINDS.filter(func(k: String) -> bool: return k != str(p[1])),
				"Is someone asking you, is it what others seem to do, or is it a feeling inside you?",
				"%s That is %s pressure." % [p[0], p[1]])
			ex.data = {"example": p[0]}
		2:
			var items: Array = []
			for kind: String in ["direct", "indirect"]:
				var some: Array = pool.filter(func(p: Array) -> bool: return str(p[1]) == kind)
				items.append_array(some.slice(0, 2))
			ex = W._sort(rng, "Direct or indirect pressure?", ["direct", "indirect"], items,
				"Direct: someone asks or dares you. Indirect: you see what others do and feel you should.",
				W._sorted_words(["direct", "indirect"], items))
			ex.data = {"items": items}
		_:
			var items: Array = []
			for kind: String in PRESSURE_KINDS:
				var some: Array = pool.filter(func(p: Array) -> bool: return str(p[1]) == kind)
				items.append_array(some.slice(0, 2))
			ex = W._sort(rng, "Direct, indirect, or from inside?", PRESSURE_KINDS, items,
				"Who is doing the pushing: a person, the crowd, or your own wishes and worries?",
				"Direct: someone asks or dares you. Indirect: what others seem to do. From inside: your own wish to fit in or look older.")
			ex.data = {"items": items}
	return ex


## The law and the facts (UK): level 1, true or false; level 2, a question's answer; level 3, harder true or false.
static func substance_law(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 2:
		var q: Array = LAW_QS[rng.randi_range(0, LAW_QS.size() - 1)]
		ex = K.choice(rng, str(q[0]), str(q[1]), q[2], "Think of what the lesson said about the law, the brain and help.",
			"%s %s." % [q[0], W._cap(str(q[1]))])
		ex.data = {"question": q[0]}
		return ex
	var pool: Array = LAW_EASY if level == 1 else LAW_HARD
	var f: Array = pool[rng.randi_range(0, pool.size() - 1)]
	ex = K.truefalse(str(f[0]), bool(f[1]), "Think of the UK law, and what alcohol and nicotine do to the body.",
		("True. %s" if bool(f[1]) else "False. %s") % _law_why(str(f[0])))
	ex.data = {"statement": f[0]}
	return ex


static func _law_why(s: String) -> String:
	if s.begins_with("Vapes"):
		return "Vapes are only meant to help adults stop smoking."
	if s.begins_with("Most young"):
		return "Most young people your age do not drink alcohol."
	if s.begins_with("Alcohol warms"):
		return "Alcohol makes the body lose heat faster."
	if s.begins_with("Coffee"):
		return "Only time sobers someone up; if they are very unwell, call 999."
	if s.contains("over 16"):
		return "It is 18 to buy alcohol in the UK."
	return "The lesson's facts and the UK's law say so."


## Saying no: level 1, name the way; level 2, match ways and examples; level 3, the best way in a situation.
static func refusal(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := REFUSALS.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var r: Array = pool[0]
			ex = K.choice(rng, "Which way of saying no is this? %s" % r[1], str(r[0]), pool.slice(1, 4).map(
				func(x: Array) -> String: return str(x[0])), "Listen to what the words do: repeat, explain, swap, joke, leave?",
				"%s is '%s'." % [r[1], r[0]])
			ex.data = {"example": r[1]}
		2:
			var picked: Array = pool.slice(0, 4)
			ex = W._match(rng, "Match each way of saying no to its example.", picked.map(func(x: Array) -> String:
				return str(x[0])), picked.map(func(x: Array) -> String: return _short_example(str(x[1]))),
				"Read each example and ask what it does: repeat, give a reason, offer an idea, or leave?",
				W._and(picked.map(func(x: Array) -> String: return "%s: %s" % [x[0], x[1]])) + ".")
			ex.data = {"ways": picked.map(func(x: Array) -> String: return str(x[0]))}
		_:
			var c: Array = REFUSE_CASES[rng.randi_range(0, REFUSE_CASES.size() - 1)]
			ex = K.choice(rng, "%s What is the best thing to do?" % c[0], str(c[1]), c[2],
				"Which choice keeps you safe and true to yourself, even if it feels awkward?",
				"Best: %s. Real friends accept a no." % c[1])
			ex.data = {"situation": c[0]}
	return ex


## An example short enough for a match's side (32 letters).
static func _short_example(s: String) -> String:
	var short := {"'No thanks.' 'No thanks.' 'No thanks.'": "'No thanks' again and again",
		"Texting home a word that means 'pick me up'.": "a text home: 'pick me up'",
		"Saying no, then leaving the group.": "saying no, then leaving",
		"'No, I've got training early.'": "'No, I've got training early.'",
		"'No. Let's get chips instead.'": "'No. Let's get chips instead.'",
		"'No way, I'm allergic to bad ideas!'": "'I'm allergic to bad ideas!'"}
	return str(short.get(s, s.substr(0, 32)))


# --- CPR and defibrillators -----------------------------------------------------------------------------------------------

## CPR's counts: level 1, pushes in a time; level 2, pushes in cycles of 30 and 2; level 3, seconds for 30 pushes, or
## cycles in some minutes.
static func cpr_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var rate := [100, 110, 120][rng.randi_range(0, 2)] as int
			var secs := [30, 60, 90, 120][rng.randi_range(0, 3)] as int
			ex = K.number("At %d pushes a minute, how many pushes are given in %d seconds?" % [rate, secs], rate * secs / 60,
				"How many minutes is it? Then multiply by the pushes a minute.",
				"%d seconds is %s of a minute: %d × %d ÷ 60 = %d pushes." % [secs, W._num_text(secs / 60.0), rate, secs,
				rate * secs / 60])
			ex.data = {"rate": rate, "secs": secs}
		2:
			var cycles := rng.randi_range(3, 8)
			ex = K.number("A trained rescuer gives 30 pushes, then 2 rescue breaths, in each cycle. How many pushes are in %d cycles?" % cycles,
				30 * cycles, "Each cycle has the same 30 pushes: multiply.", "30 × %d = %d pushes." % [cycles, 30 * cycles])
			ex.data = {"cycles": cycles}
		_:
			if rng.randf() < 0.5:
				var rate := [100, 120][rng.randi_range(0, 1)] as int
				ex = K.number("At %d pushes a minute, how many seconds do 30 pushes take?" % rate, 30 * 60 / rate,
					"Find the seconds for one push (60 ÷ the rate), then multiply by 30.",
					"60 ÷ %d = %s seconds a push; × 30 = %d seconds." % [rate, W._num_text(60.0 / rate), 30 * 60 / rate])
				ex.data = {"rate": rate, "pushes": 30}
			else:
				var opts := [[120, 2], [100, 3], [120, 1], [100, 6], [110, 3], [120, 5]]
				var o: Array = opts[rng.randi_range(0, opts.size() - 1)]
				ex = K.number("Pushing at %d a minute for %d minutes, how many sets of 30 pushes is that?" % [o[0], o[1]],
					int(o[0]) * int(o[1]) / 30, "Find all the pushes first, then share them into thirties.",
					"%d × %d = %d pushes; %d ÷ 30 = %d sets." % [o[0], o[1], int(o[0]) * int(o[1]), int(o[0]) * int(o[1]),
					int(o[0]) * int(o[1]) / 30])
				ex.data = {"rate": o[0], "minutes": o[1]}
	return ex


## CPR's steps: level 1, the next step; level 2, five steps in order; level 3, what to do.
static func cpr_step(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var i := rng.randi_range(0, CPR_STEPS.size() - 2)
			var wrongs: Array = []
			for j in CPR_STEPS.size():
				if j != i and j != i + 1:
					wrongs.append(CPR_STEPS[j])
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "In an emergency, what comes straight after '%s'?" % CPR_STEPS[i], CPR_STEPS[i + 1],
				wrongs.slice(0, 3), "Safety first, then the person, then help, then breathing, then action.",
				"After '%s' comes '%s'." % [CPR_STEPS[i], CPR_STEPS[i + 1]])
			ex.data = {"step": CPR_STEPS[i]}
		2:
			var start := rng.randi_range(0, CPR_STEPS.size() - 5)
			var steps := CPR_STEPS.slice(start, start + 5)
			ex = K.order(rng, "Put these steps in order.", steps, "Safety first, then the person, then help, then breathing, then action.",
				W._cap(", then ".join(PackedStringArray(steps))) + ".")
			ex.data = {"start": start}
		_:
			var c: Array = CPR_CASES[rng.randi_range(0, CPR_CASES.size() - 1)]
			ex = K.choice(rng, "%s What do you do?" % c[0], str(c[1]), c[2],
				"Is the person breathing normally? What keeps blood flowing and everyone safe?",
				"Best: %s." % W._cap(str(c[1])))
			ex.data = {"situation": c[0]}
	return ex


# --- Speak up for health --------------------------------------------------------------------------------------------------

## A campaign's survey: level 1, a share as a percentage; level 2, the rise in percentage points; level 3, how many more.
static func survey_share(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := [20, 25, 50, 100, 150, 200, 300][rng.randi_range(0, 6)] as int
	var habit := HABITS[rng.randi_range(0, HABITS.size() - 1)]
	var ex: Dictionary
	match level:
		1:
			var p := _whole_pct(rng, n, 10, 90)
			ex = K.number("%d of %d pupils %s. What percentage is that?" % [n * p / 100, n, habit], p,
				"Divide the part by the whole, then times 100.", "%d ÷ %d × 100 = %d%%." % [n * p / 100, n, p])
			ex.data = {"part": n * p / 100, "n": n}
		2:
			var p1 := _whole_pct(rng, n, 10, 60)
			var p2 := p1
			for _t in 30:
				p2 = _whole_pct(rng, n, 20, 90)
				if p2 > p1:
					break
			if p2 <= p1:
				n = 100
				p2 = p1 + 10
			ex = K.number("Before the campaign, %d of %d pupils %s. After it, %d of %d did. By how many percentage points did it rise?" % [
				n * p1 / 100, n, habit, n * p2 / 100, n], p2 - p1, "Turn both into percentages, then subtract.",
				"%d%% before and %d%% after: %d − %d = %d percentage points." % [p1, p2, p2, p1, p2 - p1])
			ex.data = {"before": n * p1 / 100, "after": n * p2 / 100, "n": n}
		_:
			var p1 := _whole_pct(rng, n, 10, 50)
			var p2 := p1
			for _t in 30:
				p2 = _whole_pct(rng, n, 30, 90)
				if p2 > p1:
					break
			if p2 <= p1:
				n = 100
				p2 = p1 + 20
			ex = K.number("Before the campaign, %d%% of %d pupils %s; after it, %d%%. How many more pupils is that?" % [p1, n,
				habit, p2], n * (p2 - p1) / 100, "Find the rise in percentage points, then take that percentage of the pupils.",
				"%d − %d = %d points; %d%% of %d = %d pupils." % [p2, p1, p2 - p1, p2 - p1, n, n * (p2 - p1) / 100])
			ex.data = {"p1": p1, "p2": p2, "n": n}
	return ex


## A campaign's plan: level 1, a SMART aim; level 2, the steps in order; level 3, the best message.
static func campaign_plan(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var a: Array = AIMS[rng.randi_range(0, AIMS.size() - 1)]
			ex = K.choice(rng, "Which aim for a health campaign is SMART?", str(a[0]), a[1],
				"SMART is specific, measurable, achievable, relevant and has a date: look for numbers and a deadline.",
				"'%s' says who, how much and by when, so you can check it." % a[0])
			ex.data = {"aim": a[0]}
		2:
			ex = K.order(rng, "Put a health campaign's steps in order.", CAMPAIGN_STEPS,
				"You need evidence before an aim, and an aim before a message.",
				"Survey, set a SMART aim, choose the audience and message, run it, then survey again and compare.")
			ex.data = {}
		_:
			var m: Array = MESSAGES[rng.randi_range(0, MESSAGES.size() - 1)]
			ex = K.choice(rng, "Which is the best message for a campaign about %s?" % m[0], str(m[1]), m[2],
				"A good message is short, positive, true and says exactly what to do.",
				"'%s' is positive, true and gives a clear action, without shaming anyone." % m[1])
			ex.data = {"topic": m[0]}
	return ex


# --- Digital balance ------------------------------------------------------------------------------------------------------

## Screen time: level 1, a week's hours; level 2, a week's mean; level 3, a share of waking hours, or a year's hours.
static func screen_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1:
			var h := [1.5, 2.0, 2.5, 3.0, 4.0, 5.0][rng.randi_range(0, 5)] as float
			ex = K.number("%s uses screens for %s hours a day. How many hours is that in a week?" % [who, W._num_text(h)],
				W._num_text(h * 7.0), "A week has 7 days: multiply.", "%s × 7 = %s hours a week." % [W._num_text(h),
				W._num_text(h * 7.0)])
			ex.data = {"hours": h}
		2:
			var mean := rng.randi_range(3, 5)
			var days: Array = []
			var offs: Array = [-2, -1, 0, 0, 1, 1, 1]
			var shift := [-1, 0, 1][rng.randi_range(0, 2)] as int
			offs[6] = -offs.slice(0, 6).reduce(func(a: int, b: int) -> int: return a + b, 0)
			for o: int in offs:
				days.append(maxi(mean + o + shift, 0))
			K.shuffle(rng, days)
			var sum := 0
			for d: int in days:
				sum += d
			var names := ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
			var said: Array = []
			for i in 7:
				said.append("%s %d" % [names[i], days[i]])
			ex = K.number("%s's screen time this week, in hours: %s. What is the mean a day?" % [who, ", ".join(
				PackedStringArray(said))], W._num_text(sum / 7.0), "Add all seven days, then divide by 7.",
				"%d hours in all; %d ÷ 7 = %s hours a day." % [sum, sum, W._num_text(snappedf(sum / 7.0, 0.01))])
			ex.data = {"days": days}
		_:
			if rng.randf() < 0.5:
				var pairs := [[16, 4], [16, 8], [15, 3], [15, 6], [16, 2], [15, 9], [16, 12]]
				var p: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
				var pct := float(p[1]) / float(p[0]) * 100.0
				ex = K.number("%s is awake for %d hours and spends %d of them on screens. What percentage of waking time is that?" % [
					who, p[0], p[1]], W._num_text(pct), "Divide the screen hours by the waking hours, then times 100.",
					"%d ÷ %d × 100 = %s%%." % [p[1], p[0], W._num_text(pct)])
				ex.data = {"awake": p[0], "screens": p[1]}
			else:
				var h := rng.randi_range(2, 5)
				ex = K.number("%d hours of screens a day, every day for a year (365 days): how many hours is that?" % h,
					h * 365, "Multiply the hours a day by the days in a year.",
					"%d × 365 = %s hours: about %d whole days." % [h, GenKit.fmt(h * 365), h * 365 / 24])
				ex.data = {"hours": h}
	return ex


## Focus: level 1, helps or harms; level 2, sort; level 3, match design tricks to what they do.
static func focus_habit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var helps := rng.randf() < 0.5
			var pool: Array = HELPS_FOCUS if helps else HARMS_FOCUS
			var h := str(pool[rng.randi_range(0, pool.size() - 1)])
			ex = K.truefalse("'%s' helps focus and sleep." % W._cap(h), helps,
				"Does it cut interruptions and late light, or add them?",
				("True: %s cuts interruptions." if helps else "False: %s breaks focus or delays sleep.") % W._cap(h))
			ex.data = {"habit": h}
		2:
			var a := HELPS_FOCUS.duplicate()
			var b := HARMS_FOCUS.duplicate()
			K.shuffle(rng, a)
			K.shuffle(rng, b)
			var na := rng.randi_range(2, 3)
			var items: Array = []
			for i in na:
				items.append([a[i], "helps"])
			for i in 5 - na:
				items.append([b[i], "harms"])
			ex = W._sort(rng, "Does it help or harm focus and sleep?", ["helps", "harms"], items,
				"Interruptions and late screens harm; one task, breaks and a dark bedroom help.",
				W._sorted_words(["helps", "harms"], items))
			ex.data = {"items": items}
		_:
			var pool := DESIGN_TRICKS.duplicate()
			K.shuffle(rng, pool)
			var picked: Array = pool.slice(0, 4)
			ex = W._match(rng, "Match each design trick to what it does.", picked.map(func(x: Array) -> String:
				return str(x[0])), picked.map(func(x: Array) -> String: return str(x[1])),
				"Each trick is built to keep you on the app longer. How?",
				W._and(picked.map(func(x: Array) -> String: return "%s %s" % [x[0], x[1]])) + ".")
			ex.data = {"tricks": picked.map(func(x: Array) -> String: return str(x[0]))}
	return ex


# --- From brief to product ------------------------------------------------------------------------------------------------

## Specifications: level 1, a point you can check; level 2, sort measurable and vague; level 3, its ACCESS FM heading.
static func spec_point(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var good: Array = SPEC_POINTS.filter(func(s: Array) -> bool: return bool(s[1]))
	var vague: Array = SPEC_POINTS.filter(func(s: Array) -> bool: return not bool(s[1]))
	K.shuffle(rng, good)
	K.shuffle(rng, vague)
	var ex: Dictionary
	match level:
		1:
			ex = K.choice(rng, "Which specification point can be checked by measuring or testing?", str(good[0][0]),
				vague.slice(0, 3).map(func(s: Array) -> String: return str(s[0])),
				"Look for a number or something you could test with a yes or no.",
				"'%s' can be checked; the others need a number to mean anything." % good[0][0])
			ex.data = {"point": good[0][0]}
		2:
			var ng := rng.randi_range(2, 3)
			var items: Array = []
			for i in ng:
				items.append([good[i][0], "measurable"])
			for i in 5 - ng:
				items.append([vague[i][0], "vague"])
			ex = W._sort(rng, "A measurable specification point, or a vague one?", ["measurable", "vague"], items,
				"Could two people check it and agree? Then it is measurable.", W._sorted_words(["measurable", "vague"], items))
			ex.data = {"items": items}
		_:
			var s: Array = good[0]
			var wrongs := HEADINGS.filter(func(h: String) -> bool: return h != str(s[2]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which ACCESS FM heading does this go under? '%s'" % s[0], str(s[2]), wrongs.slice(0, 3),
				"Is it about looks, price, the user, the planet, harm, how big it is, its job, or what it is made of?",
				"'%s' is about %s." % [s[0], str(s[2]).to_lower()])
			ex.data = {"point": s[0]}
	return ex


## A making plan: level 1, a task's length; level 2, the lesson the plan finishes; level 3, the end after a delay.
static func plan_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names := PLAN_TASKS.duplicate()
	var n := rng.randi_range(4, 6)
	var start_at := rng.randi_range(0, names.size() - n)
	var tasks: Array = []
	var t := 0
	for i in n:
		var length := rng.randi_range(1, 3 if n <= 4 else 2)
		var s := t
		if level == 2 and i > 0 and rng.randf() < 0.4:
			s = maxi(int(tasks[-1][1]), t - 1)   # overlaps the task before it
		tasks.append([names[start_at + i], s, length])
		t = s + length
	var cols := clampi(SchoolPictureG8Life.plan_end(tasks) + rng.randi_range(0, 2), 4, 16)
	var pic := {"kind": "making_plan", "tasks": tasks, "columns": cols}
	var end := SchoolPictureG8Life.plan_end(tasks)
	var ex: Dictionary
	match level:
		1:
			var k := rng.randi_range(0, n - 1)
			ex = K.number("How many lessons does '%s' take in this plan?" % tasks[k][0], int(tasks[k][2]),
				"Count the squares its bar covers.", "Its bar covers %d lesson%s." % [tasks[k][2], "" if int(tasks[k][2]) == 1
				else "s"], pic)
			ex.data = {"task": tasks[k][0]}
		2:
			ex = K.number("In which lesson does this plan finish?", end, "Find the bar that reaches furthest to the right.",
				"The last bar ends in lesson %d, so the plan finishes then." % end, pic)
		_:
			var k := rng.randi_range(0, n - 2)
			var extra := rng.randi_range(1, 2)
			ex = K.number("'%s' takes %d more lesson%s than planned, and every later task moves back. In which lesson does the plan end now?" % [
				tasks[k][0], extra, "" if extra == 1 else "s"], end + extra,
				"In a plan where each task waits for the one before, a delay moves the end too.",
				"It ended in lesson %d; %d + %d = lesson %d." % [end, end, extra, end + extra], pic)
			ex.data = {"extra": extra}
	ex.data = ex.get("data", {})
	ex.data.tasks = tasks
	return ex


## Cutting lists and tolerances: level 1, the total length; level 2, pieces from a length; level 3, the smallest or
## largest size allowed.
static func cutting_list(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var n := rng.randi_range(2, 6)
			var length := rng.randi_range(6, 45) * 10
			var what := PIECES[rng.randi_range(0, PIECES.size() - 1)]
			ex = K.number("A cutting list says %d %s of %d mm each. What length of wood is needed in all, in mm?" % [n, what,
				length], n * length, "Multiply the number of pieces by each piece's length.",
				"%d × %d = %s mm." % [n, length, GenKit.fmt(n * length)])
			ex.data = {"n": n, "length": length}
		2:
			var piece := [250, 300, 350, 400, 450][rng.randi_range(0, 4)] as int
			var stock := [1200, 1800, 2000, 2400][rng.randi_range(0, 3)] as int
			ex = K.number("How many %d mm pieces can be cut from a %s mm length? (Ignore the saw cuts.)" % [piece,
				GenKit.fmt(stock)], stock / piece, "Divide, and count only whole pieces: a part piece is waste.",
				"%s ÷ %d = %s, so %d whole pieces and %d mm left over." % [GenKit.fmt(stock), piece,
				W._num_text(snappedf(float(stock) / piece, 0.01)), stock / piece, stock - stock / piece * piece])
			ex.data = {"piece": piece, "stock": stock}
		_:
			var size := [40, 85, 120, 250][rng.randi_range(0, 3)] as int
			var tol := [0.2, 0.5, 1.0][rng.randi_range(0, 2)] as float
			var small := rng.randf() < 0.5
			var ans := size - tol if small else size + tol
			ex = K.number("A part must be %d mm, plus or minus %s mm. What is the %s size allowed, in mm?" % [size, W._num_text(tol),
				"smallest" if small else "largest"], W._num_text(ans),
				"Plus or minus means the size may be that much smaller or that much larger.",
				"%d %s %s = %s mm." % [size, "−" if small else "+", W._num_text(tol), W._num_text(ans)])
			ex.data = {"size": size, "tol": tol, "small": small}
	return ex


# --- Smart and modern materials -------------------------------------------------------------------------------------------

## Smart materials: level 1, the material for a use; level 2, match materials to triggers; level 3, what happens.
static func smart_use(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var u: Array = SMART_USES[rng.randi_range(0, SMART_USES.size() - 1)]
			var wrongs: Array = []
			var mats: Array = SMART_USES.map(func(x: Array) -> String: return str(x[1]))
			K.shuffle(rng, mats)
			for m: String in mats:
				if m != str(u[1]) and not wrongs.has(m) and wrongs.size() < 3:
					wrongs.append(m)
			ex = K.choice(rng, "Which material suits %s?" % u[0], str(u[1]), wrongs,
				"What must it react to, or what property must it have?", "%s: %s." % [W._cap(str(u[0])), u[1]])
			ex.data = {"use": u[0]}
		2:
			var pool := SMART_TRIGGERS.duplicate()
			K.shuffle(rng, pool)
			var picked: Array = pool.slice(0, 3 + rng.randi_range(0, 1))
			ex = W._match(rng, "Match each smart material to what makes it change.", picked.map(func(x: Array) -> String:
				return str(x[0])), picked.map(func(x: Array) -> String: return str(x[1])),
				"Heat, light, force or water: which one does each react to?",
				W._and(picked.map(func(x: Array) -> String: return "%s: %s" % [x[0], x[1]])) + ".")
			ex.data = {"materials": picked.map(func(x: Array) -> String: return str(x[0]))}
		_:
			var q: Array = SMART_WHAT[rng.randi_range(0, SMART_WHAT.size() - 1)]
			ex = K.choice(rng, str(q[0]), str(q[1]), q[2], "Smart materials change when the trigger comes, and change back when it goes.",
				"%s %s." % [q[0], W._cap(str(q[1]))])
			ex.data = {"question": q[0]}
	return ex


## Mass from density: level 1, a part's mass; level 2, the grams saved in carbon fibre; level 3, a volume from a mass.
static func material_mass(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var names: Array = DENSITY.keys()
	var ex: Dictionary
	match level:
		1:
			var m := str(names[rng.randi_range(0, names.size() - 1)])
			var v := [10, 20, 50, 100, 200, 250, 500][rng.randi_range(0, 6)] as int
			var d := float(DENSITY[m])
			ex = K.number("%s's density is %s g/cm³. What is the mass of a %d cm³ %s part, in grams?" % [W._cap(m),
				W._num_text(d), v, m], W._num_text(d * v), "Mass = density × volume.",
				"%s × %d = %s g." % [W._num_text(d), v, W._num_text(snappedf(d * v, 0.01))])
			ex.data = {"material": m, "volume": v}
		2:
			var m := ["steel", "aluminium", "titanium"][rng.randi_range(0, 2)] as String
			var v := [100, 200, 250, 500][rng.randi_range(0, 3)] as int
			var d := float(DENSITY[m])
			var saved := snappedf((d - 1.6) * v, 0.01)
			ex = K.number("A %d cm³ part in %s (%s g/cm³) or carbon fibre (1.6 g/cm³): how many grams lighter is the carbon fibre one?" % [
				v, m, W._num_text(d)], W._num_text(saved), "Work out both masses (density × volume), then subtract.",
				"%s × %d = %s g; 1.6 × %d = %s g; the difference is %s g." % [W._num_text(d), v,
				W._num_text(snappedf(d * v, 0.01)), v, W._num_text(1.6 * v), W._num_text(saved)])
			ex.data = {"material": m, "volume": v}
		_:
			var m := str(names[rng.randi_range(0, names.size() - 1)])
			var v := [10, 20, 50, 100, 200, 250][rng.randi_range(0, 5)] as int
			var d := float(DENSITY[m])
			var mass := snappedf(d * v, 0.01)
			ex = K.number("A %s part has a mass of %s g. %s's density is %s g/cm³. What is its volume, in cm³?" % [m,
				W._num_text(mass), W._cap(m), W._num_text(d)], v, "Volume = mass ÷ density.",
				"%s ÷ %s = %d cm³." % [W._num_text(mass), W._num_text(d), v])
			ex.data = {"material": m, "mass": mass}
	return ex


## Composites: level 1, the matrix; level 2, sort reinforcements and matrices; level 3, true or false.
static func composite_part(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := COMPOSITES.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var c: Array = pool[0]
			var wrongs: Array = [c[1]]
			for o: Array in pool.slice(1):
				for x: Variant in [o[1], o[2]]:
					if str(x) != str(c[2]) and not wrongs.has(x) and wrongs.size() < 3:
						wrongs.append(x)
			ex = K.choice(rng, "In %s, which part is the matrix that holds everything together?" % c[0], str(c[2]), wrongs,
				"The reinforcement gives strength; the matrix surrounds and binds it.",
				"In %s, %s is the matrix and %s the reinforcement." % [c[0], c[2], c[1]])
			ex.data = {"composite": c[0]}
		2:
			var items: Array = []
			var seen := {}
			for c: Array in pool:
				for k in [1, 2]:
					var t := str(c[k])
					if not seen.has(t) and items.size() < 5:
						seen[t] = true
						items.append([t, "reinforcement" if k == 1 else "matrix"])
			ex = W._sort(rng, "Reinforcement or matrix?", ["reinforcement", "matrix"], items,
				"Fibres and bars carry the load; the stuff around them holds them in place.",
				W._sorted_words(["reinforcement", "matrix"], items))
			ex.data = {"items": items}
		_:
			var f: Array = COMPOSITE_FACTS[rng.randi_range(0, COMPOSITE_FACTS.size() - 1)]
			ex = K.truefalse(str(f[0]), bool(f[1]), "Remember: fibres for strength, a matrix to bind them, bonded for good.",
				("True. %s" if bool(f[1]) else "False. %s") % _composite_why(str(f[0])))
			ex.data = {"statement": f[0]}
	return ex


static func _composite_why(s: String) -> String:
	if s.begins_with("A composite is one"):
		return "A composite joins two or more materials."
	if s.contains("matrix gives"):
		return "The fibres give most of the strength; the matrix binds them."
	if s.begins_with("Carbon fibre is heavier"):
		return "Carbon fibre is much lighter than steel for the same strength."
	return "Fibres or bars carry the load, and the bonded materials are hard to separate."


# --- A programmable product ------------------------------------------------------------------------------------------------

## Thresholds: level 1, is the output on; level 2, readings that switch it on; level 3, two conditions.
static func threshold_output(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var t := rng.randi_range(3, 8) * 10
			var r := t + [-15, -5, 0, 5, 15][rng.randi_range(0, 4)] as int
			var on := r < t
			ex = K.truefalse("A night light's program: if light < %d: lamp on, else: lamp off. The light reading is %d. Is the lamp on?" % [
				t, r], on, "'<' means strictly less than: is the reading below the threshold?",
				("%d < %d, so the lamp is on." if on else "%d is not less than %d, so the lamp is off.") % [r, t])
			ex.data = {"t": t, "r": r}
		2:
			var t := rng.randi_range(3, 7) * 10
			var below := rng.randf() < 0.5
			var readings: Array = []
			var labels: Array = []
			var n := rng.randi_range(5, 8)
			for i in n:
				var v := t
				while v == t:
					v = rng.randi_range(1, 9) * 10 + rng.randi_range(-4, 4)
				readings.append(v)
				labels.append("%d:00" % (17 + i))
			var count := 0
			for v: int in readings:
				count += 1 if (v < t if below else v > t) else 0
			var name := "light level" if below else "temperature"
			ex = K.number("The output comes on when the %s is %s %d (the dashed line). How many of these readings switch it on?" % [
				name, "below" if below else "above", t], count, "Count the points %s the dashed line." % ("under" if below
				else "over"), "%d of the %d readings are %s %d." % [count, n, "below" if below else "above", t],
				{"kind": "threshold_graph", "readings": readings, "labels": labels, "threshold": t, "below": below,
				"name": name})
			ex.data = {"readings": readings, "t": t, "below": below}
		_:
			var limit := rng.randi_range(24, 30)
			var damp := [60, 70, 80][rng.randi_range(0, 2)] as int
			var temp := limit + [-2, -1, 1, 3][rng.randi_range(0, 3)] as int
			var hum := damp + [-10, -5, 5, 10][rng.randi_range(0, 3)] as int
			var both := rng.randf() < 0.5
			var on := (temp > limit and hum > damp) if both else (temp > limit or hum > damp)
			var op := "and" if both else "or"
			ex = K.truefalse("Greenhouse fan: if temperature > %d %s humidity > %d: fan on. It is %d °C with %d%% humidity. Is the fan on?" % [
				limit, op, damp, temp, hum], on, "With 'and' both must be true; with 'or' one is enough.",
				"Temperature > %d is %s; humidity > %d is %s; with '%s' the fan is %s." % [limit, "true" if temp > limit else
				"false", damp, "true" if hum > damp else "false", op, "on" if on else "off"])
			ex.data = {"limit": limit, "damp": damp, "temp": temp, "hum": hum, "op": op}
	return ex


## Battery life: level 1, hours; level 2, days at some hours a day; level 3, the capacity needed.
static func battery_life(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1, 2:
			var pairs: Array = []
			for cap: int in [500, 1000, 1200, 2000, 2400, 3000]:
				for ma: int in [10, 20, 25, 40, 50, 100, 200]:
					if cap % ma == 0:
						pairs.append([cap, ma])
			var p: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
			var hours := int(p[0]) / int(p[1])
			if level == 1:
				ex = K.number("A %s mAh battery powers a product that draws %d mA. About how many hours will it run?" % [
					GenKit.fmt(int(p[0])), p[1]], hours, "Hours = capacity in mAh ÷ current in mA.",
					"%s ÷ %d = %d hours." % [GenKit.fmt(int(p[0])), p[1], hours])
				ex.data = {"cap": p[0], "ma": p[1]}
			else:
				var per_day: Array = []
				for d: int in [1, 2, 4, 5, 8, 10]:
					if hours % d == 0 and hours / d >= 2:
						per_day.append(d)
				if per_day.is_empty():
					per_day = [1]
				var d := int(per_day[rng.randi_range(0, per_day.size() - 1)])
				ex = K.number("A %s mAh battery, a %d mA product, used %d hour%s a day: how many days will it last?" % [
					GenKit.fmt(int(p[0])), p[1], d, "" if d == 1 else "s"], hours / d,
					"Find the hours it lasts first, then share them by the hours used each day.",
					"%s ÷ %d = %d hours; %d ÷ %d = %d days." % [GenKit.fmt(int(p[0])), p[1], hours, hours, d, hours / d])
				ex.data = {"cap": p[0], "ma": p[1], "per_day": d}
		_:
			var h := [10, 20, 24, 40, 50][rng.randi_range(0, 4)] as int
			var ma := [20, 25, 40, 50, 60][rng.randi_range(0, 4)] as int
			ex = K.number("A bike light draws %d mA and must run for %d hours. What battery capacity is needed, in mAh?" % [ma,
				h], h * ma, "Capacity = current × hours.", "%d × %d = %s mAh." % [ma, h, GenKit.fmt(h * ma)])
			ex.data = {"ma": ma, "hours": h}
	return ex


## Open and closed loops: level 1, the closed one; level 2, sort; level 3, what is fed back.
static func control_loop(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var open: Array = LOOPS.filter(func(l: Array) -> bool: return not bool(l[1]))
	var closed: Array = LOOPS.filter(func(l: Array) -> bool: return bool(l[1]))
	K.shuffle(rng, open)
	K.shuffle(rng, closed)
	var ex: Dictionary
	match level:
		1:
			ex = K.choice(rng, "Which of these is a closed loop system?", str(closed[0][0]), open.slice(0, 3).map(
				func(l: Array) -> String: return str(l[0])), "A closed loop measures its own result and corrects itself.",
				"%s measures %s and adjusts: a closed loop. The others just run." % [W._cap(str(closed[0][0])), closed[0][2]])
			ex.data = {"right": closed[0][0]}
		2:
			var nc := rng.randi_range(2, 3)
			var items: Array = []
			for i in nc:
				items.append([closed[i][0], "closed loop"])
			for i in 5 - nc:
				items.append([open[i][0], "open loop"])
			ex = W._sort(rng, "Open loop or closed loop?", ["open loop", "closed loop"], items,
				"Does it check its result and adjust, or just run for a set time?",
				W._sorted_words(["open loop", "closed loop"], items))
			ex.data = {"items": items}
		_:
			var c: Array = closed[0]
			ex = K.choice(rng, "%s is a closed loop. What is fed back to its controller?" % W._cap(str(c[0])), str(c[2]),
				closed.slice(1, 4).map(func(l: Array) -> String: return str(l[2])),
				"What does this system measure about its own job?", "It measures %s, again and again, and adjusts." % c[2])
			ex.data = {"system": c[0]}
	return ex


# --- Mechanical advantage -------------------------------------------------------------------------------------------------

## Levers (the pivot at one end, the load between): level 1, the mechanical advantage; level 2, the effort; level 3,
## where the effort must be.
static func lever_ma(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var dl := rng.randi_range(1, 3)
	var ma := rng.randi_range(2, 10 / dl)
	var de := dl * ma
	var load := ma * rng.randi_range(2, 12) * 10
	var effort := load / ma
	var pic := {"kind": "lever_class", "pivot": 0, "load": dl, "effort": de, "scale": true,
		"values": {"load": "%d N" % load, "effort": "?"}}
	var ex: Dictionary
	match level:
		1:
			pic.values = {}
			ex = K.number("The effort is %d marks from the pivot and the load %d marks. What is the mechanical advantage?" % [
				de, dl], ma, "Mechanical advantage = the effort's distance ÷ the load's distance from the pivot.",
				"%d ÷ %d = %d: the lever multiplies the effort %d times." % [de, dl, ma, ma], pic)
		2:
			ex = K.number("A %d N load sits %d marks from the pivot and the effort %d marks. What effort lifts it, in newtons?" % [
				load, dl, de], effort, "Find the mechanical advantage first, then divide the load by it.",
				"MA = %d ÷ %d = %d; %d ÷ %d = %d N." % [de, dl, ma, load, ma, effort], pic)
		_:
			pic.values = {"load": "%d N" % load, "effort": "%d N" % effort}
			pic.effort = de
			ex = K.number("A %d N load is %d marks from the pivot. The effort is %d N. How many marks from the pivot must it be?" % [
				load, dl, effort], de, "Moments balance: effort × its distance = load × its distance.",
				"%d × %d = %d; %d ÷ %d = %d marks." % [load, dl, load * dl, load * dl, effort, de], pic)
	ex.data = {"dl": dl, "de": de, "load": load}
	return ex


## Gear trains: level 1, a ratio; level 2, the output's speed; level 3, a compound train's ratio or speed.
static func gear_ratio(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var stages := _stages(rng, 1 if level < 3 else 2)
	var ratio := SchoolPictureG8Life.train_ratio(stages)
	var rpm: int = int(ratio) * int([10, 20, 30, 40, 50, 60][rng.randi_range(0, 5)])
	var pic := {"kind": "gear_train", "stages": stages, "turn": "cw"}
	var said: Array = stages.map(func(s: Array) -> String: return "%d ÷ %d = %d" % [s[1], s[0], int(s[1]) / int(s[0])])
	var ex: Dictionary
	if level == 1 or (level == 3 and rng.randf() < 0.5):
		ex = K.number("What is the %sgear ratio of this train (driven ÷ driver)?" % ("overall " if level == 3 else ""),
			int(ratio), "Each stage: the driven gear's teeth ÷ the driver's. With two stages, multiply them.",
			"%s%s." % ["; ".join(PackedStringArray(said)), ("; %s = %d" % [" × ".join(PackedStringArray(stages.map(
			func(s: Array) -> String: return str(int(s[1]) / int(s[0]))))), int(ratio)]) if stages.size() > 1 else ""], pic)
	else:
		pic.rpm = rpm
		pic.out = "?"
		ex = K.number("The first gear turns at %d rpm. How fast does the last gear turn, in rpm?" % rpm, rpm / int(ratio),
			"A big driven gear turns slower: divide the speed by the teeth's ratio, stage by stage.",
			"%s; %d ÷ %d = %d rpm." % ["; ".join(PackedStringArray(said)), rpm, int(ratio), rpm / int(ratio)], pic)
	ex.data = {"stages": stages, "rpm": rpm}
	return ex


## Gear stages with whole ratios (2-5), teeth 8-60.
static func _stages(rng: RandomNumberGenerator, n: int) -> Array:
	var out: Array = []
	for _i in n:
		for _t in 40:
			var driver := [8, 10, 12, 15, 20][rng.randi_range(0, 4)] as int
			var r := rng.randi_range(2, 5)
			if driver * r <= 60:
				out.append([driver, driver * r])
				break
	return out


## A block and tackle: level 1, the effort; level 2, the rope pulled; level 3, its efficiency.
static func tackle_effort(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var n := rng.randi_range(2, 6)
	var ex: Dictionary
	match level:
		1:
			var effort := rng.randi_range(2, 12) * 25
			var load := effort * n
			ex = K.number("Count the ropes holding the load. Ignoring friction, what effort lifts it, in newtons?", effort,
				"The load is shared by the ropes that hold it: divide by how many there are.",
				"%d ropes hold it: %d ÷ %d = %d N." % [n, load, n, effort], {"kind": "block_tackle", "ropes": n,
				"load": load, "effort": "?", "count": true})
			ex.data = {"ropes": n, "load": load}
		2:
			var lift := rng.randi_range(1, 5)
			ex = K.number("To lift the crate %d m, how many metres of rope must be pulled?" % lift, lift * n,
				"Every holding rope must get shorter by the lift: multiply.",
				"%d ropes × %d m = %d m: less force, more rope." % [n, lift, lift * n], {"kind": "block_tackle", "ropes": n,
				"count": true})
			ex.data = {"ropes": n, "lift": lift}
		_:
			var opts: Array = []
			for eff: int in [50, 75, 80]:
				for ideal: int in range(40, 401, 20):
					if (ideal * 100) % eff == 0:
						opts.append([ideal, eff])
			var o: Array = opts[rng.randi_range(0, opts.size() - 1)]
			var ideal := int(o[0])
			var real := ideal * 100 / int(o[1])
			var load := ideal * n
			ex = K.number("Friction means the real effort is %d N. What is the efficiency, in percent?" % real, o[1],
				"Work out the effort with no friction (load ÷ ropes), then divide it by the real effort, times 100.",
				"%d ÷ %d = %d N with no friction; %d ÷ %d × 100 = %d%%." % [load, n, ideal, ideal, real, o[1]],
				{"kind": "block_tackle", "ropes": n, "load": load, "effort": real, "count": true})
			ex.data = {"ropes": n, "load": load, "real": real}
	return ex


## Machines: level 1, mechanical advantage; level 2, velocity ratio; level 3, efficiency.
static func ma_efficiency(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var effort := rng.randi_range(2, 20) * 10
			var ma := rng.randi_range(2, 6)
			ex = K.number("A machine lifts a %d N load with a %d N effort. What is its mechanical advantage?" % [effort * ma,
				effort], ma, "Mechanical advantage = load ÷ effort.", "%d ÷ %d = %d." % [effort * ma, effort, ma])
			ex.data = {"load": effort * ma, "effort": effort}
		2:
			var load_d := rng.randi_range(2, 10) * 5
			var vr := rng.randi_range(2, 8)
			ex = K.number("The effort moves %d cm while the load rises %d cm. What is the velocity ratio?" % [load_d * vr,
				load_d], vr, "Velocity ratio = the distance the effort moves ÷ the distance the load moves.",
				"%d ÷ %d = %d." % [load_d * vr, load_d, vr])
			ex.data = {"effort_d": load_d * vr, "load_d": load_d}
		_:
			var opts: Array = []
			for vr: int in [2, 3, 4, 5, 6]:
				for eff: int in [50, 60, 75, 80, 90]:
					if (vr * eff) % 100 == 0 or (vr * eff) % 50 == 0:
						opts.append([vr, eff])
			var o: Array = opts[rng.randi_range(0, opts.size() - 1)]
			var vr := int(o[0])
			var eff := int(o[1])
			var effort := 100
			var load := vr * eff   # MA = vr × eff ÷ 100, with an effort of 100 N
			var load_d := [10, 20, 25][rng.randi_range(0, 2)] as int
			ex = K.number("A %d N load is lifted %d cm by a %d N effort that moves %d cm. What is the efficiency, in percent?" % [
				load, load_d, effort, load_d * vr], eff,
				"Find the mechanical advantage (load ÷ effort) and the velocity ratio (distances), then MA ÷ VR × 100.",
				"MA = %d ÷ %d = %s; VR = %d ÷ %d = %d; %s ÷ %d × 100 = %d%%." % [load, effort, W._num_text(load / 100.0),
				load_d * vr, load_d, vr, W._num_text(load / 100.0), vr, eff])
			ex.data = {"load": load, "effort": effort, "load_d": load_d, "effort_d": load_d * vr}
	return ex


# --- Engineering big structures ---------------------------------------------------------------------------------------------

## Factors of safety: level 1, the factor; level 2, the most load; level 3, the breaking load needed.
static func safety_factor(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var fos := rng.randi_range(2, 6)
	var work := rng.randi_range(2, 30) * 10
	var what := ["cable", "beam", "bolt", "column"][rng.randi_range(0, 3)] as String
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A %s breaks at %d kN and carries %d kN. What is its factor of safety?" % [what, work * fos, work],
				fos, "Factor of safety = the breaking load ÷ the working load.", "%d ÷ %d = %d." % [work * fos, work, fos])
		2:
			ex = K.number("A %s breaks at %d kN and needs a factor of safety of %d. What is the most it should carry, in kN?" % [
				what, work * fos, fos], work, "Working load = breaking load ÷ the factor of safety.",
				"%d ÷ %d = %d kN." % [work * fos, fos, work])
		_:
			ex = K.number("A bridge's %s will carry %d kN and needs a factor of safety of %d. What must its breaking load be, at least, in kN?" % [
				what, work, fos], work * fos, "Breaking load = working load × the factor of safety.",
				"%d × %d = %d kN." % [work, fos, work * fos])
	ex.data = {"fos": fos, "work": work}
	return ex


## Structures: level 1, what a feature does; level 2, match features to jobs; level 3, sort loads.
static func structure_feature(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := FEATURES.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var f: Array = pool[0]
			ex = K.choice(rng, "What does %s do for a big structure?" % f[0], str(f[1]), pool.slice(1, 4).map(
				func(x: Array) -> String: return str(x[1])), "Think about which force or danger this feature fights.",
				"%s %s." % [W._cap(str(f[0])), f[1]])
			ex.data = {"feature": f[0]}
		2:
			var picked: Array = pool.slice(0, 4)
			ex = W._match(rng, "Match each feature to its job.", picked.map(func(x: Array) -> String: return str(x[0])),
				picked.map(func(x: Array) -> String: return str(x[1])), "Wind, earthquakes, heat, soft ground or tipping?",
				W._and(picked.map(func(x: Array) -> String: return "%s %s" % [x[0], x[1]])) + ".")
			ex.data = {"features": picked.map(func(x: Array) -> String: return str(x[0]))}
		_:
			var items: Array = []
			for kind: String in ["dead", "live", "environmental"]:
				var some: Array = LOADS.filter(func(l: Array) -> bool: return str(l[1]) == kind)
				K.shuffle(rng, some)
				items.append_array(some.slice(0, 2))
			ex = W._sort(rng, "A dead load, a live load, or an environmental load?", ["dead", "live", "environmental"],
				items, "Dead loads are the structure itself; live loads come and go; environmental ones come from nature.",
				W._sorted_words(["dead", "live", "environmental"], items))
			ex.data = {"items": items}
	return ex


# --- Nutrition for life ---------------------------------------------------------------------------------------------------

## Nutrients: level 1, the nutrient for a job; level 2, match nutrients to jobs; level 3, what a long lack can cause.
static func nutrient_job(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := NUTRIENTS.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var n: Array = pool[0]
			ex = K.choice(rng, "Which nutrient does this job: %s?" % n[1], str(n[0]), pool.slice(1, 4).map(
				func(x: Array) -> String: return str(x[0])), "Think of the foods it comes in and what the body uses it for.",
				"%s: %s (in %s)." % [W._cap(str(n[0])), n[1], n[2]])
			ex.data = {"job": n[1]}
		2:
			var picked: Array = pool.slice(0, 4)
			ex = W._match(rng, "Match each nutrient to its job.", picked.map(func(x: Array) -> String: return str(x[0])),
				picked.map(func(x: Array) -> String: return str(x[1])), "Energy, growth, bones, blood or digestion?",
				W._and(picked.map(func(x: Array) -> String: return "%s: %s" % [x[0], x[1]])) + ".")
			ex.data = {"nutrients": picked.map(func(x: Array) -> String: return str(x[0]))}
		_:
			var d: Array = DEFICIENCIES[rng.randi_range(0, DEFICIENCIES.size() - 1)]
			ex = K.choice(rng, "A long lack of %s can lead to…" % d[0], str(d[1]), DEFICIENCIES.filter(func(x: Array) -> bool:
				return str(x[0]) != str(d[0])).map(func(x: Array) -> String: return str(x[1])),
				"What is that nutrient's job? Then think what happens without it.",
				"Without enough %s: %s." % [d[0], d[1]])
			ex.data = {"nutrient": d[0]}
	return ex


## A label's numbers: level 1, fibre in a portion; level 2, a portion's share of 6 g of salt; level 3, fibre still needed.
static func per_portion(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var per := [4, 6, 8, 10, 12, 15][rng.randi_range(0, 5)] as int
			var portion := [30, 40, 50][rng.randi_range(0, 2)] as int
			var got := per * portion / 100.0
			ex = K.number("A cereal has %d g of fibre per 100 g. How much fibre is in a %d g bowl, in grams?" % [per, portion],
				W._num_text(got), "Divide by 100 for 1 g, then multiply by the portion.",
				"%d × %d ÷ 100 = %s g." % [per, portion, W._num_text(got)])
			ex.data = {"per": per, "portion": portion}
		2:
			var opts: Array = []
			for salt: float in [0.5, 0.6, 0.8, 1.0, 1.2]:
				for portion: int in [150, 200, 250, 300]:
					var pct := salt * portion / 100.0 / 6.0 * 100.0
					if is_equal_approx(pct, roundf(pct)):
						opts.append([salt, portion, roundi(pct)])
			var o: Array = opts[rng.randi_range(0, opts.size() - 1)]
			var grams := float(o[0]) * int(o[1]) / 100.0
			ex = K.number("A soup has %s g of salt per 100 g. What percentage of the 6 g daily limit is in a %d g bowl?" % [
				W._num_text(float(o[0])), o[1]], o[2], "Find the salt in the bowl, then divide by 6 and times 100.",
				"%s × %d ÷ 100 = %s g; %s ÷ 6 × 100 = %d%%." % [W._num_text(float(o[0])), o[1], W._num_text(grams),
				W._num_text(grams), o[2]])
			ex.data = {"salt": o[0], "portion": o[1]}
		_:
			var a := [6, 8, 10][rng.randi_range(0, 2)] as int
			var pa := 50
			var b := [4, 5, 6][rng.randi_range(0, 2)] as int
			var pb := [100, 200][rng.randi_range(0, 1)] as int
			var got := a * pa / 100.0 + b * pb / 100.0
			ex = K.number("Porridge: %d g of fibre per 100 g, and you eat %d g. Beans: %d g per 100 g, and you eat %d g. How many more grams reach 25 g?" % [
				a, pa, b, pb], W._num_text(25.0 - got), "Work out the fibre in each portion, add them, then take from 25.",
				"%s g + %s g = %s g; 25 − %s = %s g more." % [W._num_text(a * pa / 100.0), W._num_text(b * pb / 100.0),
				W._num_text(got), W._num_text(got), W._num_text(25.0 - got)])
			ex.data = {"a": a, "pa": pa, "b": b, "pb": pb}
	return ex


## Dietary needs: level 1, a food safe without gluten; level 2, sort gluten and gluten-free; level 3, sort vegan foods.
static func dietary_need(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var g := GLUTEN.duplicate()
	K.shuffle(rng, g)
	var ex: Dictionary
	match level:
		1:
			var free: Array = g.filter(func(x: Array) -> bool: return not bool(x[1]))
			var has: Array = g.filter(func(x: Array) -> bool: return bool(x[1]))
			ex = K.choice(rng, "Which food is safe for someone with coeliac disease (no gluten)?", str(free[0][0]),
				has.slice(0, 3).map(func(x: Array) -> String: return str(x[0])),
				"Gluten is in wheat, barley and rye. Which food is made from none of them?",
				"%s has no gluten; the others are made with wheat, barley or rye." % W._cap(str(free[0][0])))
			ex.data = {"right": free[0][0]}
		2:
			var items := _two_groups(g, "has gluten", "gluten-free", rng)
			ex = W._sort(rng, "Does it have gluten, or is it gluten-free?", ["has gluten", "gluten-free"], items,
				"Look for wheat, barley or rye in it.", W._sorted_words(["has gluten", "gluten-free"], items))
			ex.data = {"items": items}
		_:
			var v := VEGAN.duplicate()
			K.shuffle(rng, v)
			var items := _two_groups(v, "vegan", "not vegan", rng)
			ex = W._sort(rng, "Vegan, or not vegan?", ["vegan", "not vegan"], items,
				"Vegans eat nothing from animals: no meat, fish, milk, eggs or honey.",
				W._sorted_words(["vegan", "not vegan"], items))
			ex.data = {"items": items}
	return ex


## 5 [text, group] items from [text, bool] pairs: 2 or 3 true (`yes`), the rest false (`no`).
static func _two_groups(pairs: Array, yes: String, no: String, rng: RandomNumberGenerator) -> Array:
	var a: Array = pairs.filter(func(x: Array) -> bool: return bool(x[1]))
	var b: Array = pairs.filter(func(x: Array) -> bool: return not bool(x[1]))
	var na := rng.randi_range(2, 3)
	var items: Array = []
	for i in na:
		items.append([a[i][0], yes])
	for i in 5 - na:
		items.append([b[i][0], no])
	return items


# --- How food is produced -------------------------------------------------------------------------------------------------

## Processing: level 1, a primary step; level 2, sort primary and secondary; level 3, farm to fork in order.
static func processing(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p := PROCESSING.duplicate()
	K.shuffle(rng, p)
	var ex: Dictionary
	match level:
		1:
			var prim: Array = p.filter(func(x: Array) -> bool: return bool(x[1]))
			var sec: Array = p.filter(func(x: Array) -> bool: return not bool(x[1]))
			ex = K.choice(rng, "Which of these is primary processing?", str(prim[0][0]), sec.slice(0, 3).map(
				func(x: Array) -> String: return str(x[0])), "Primary processing makes a raw food ready to use or to cook with.",
				"%s gets a raw food ready; the others make new products from it (secondary)." % W._cap(str(prim[0][0])))
			ex.data = {"right": prim[0][0]}
		2:
			var items := _two_groups(p, "primary", "secondary", rng)
			ex = W._sort(rng, "Primary or secondary processing?", ["primary", "secondary"], items,
				"Primary: the raw food made usable. Secondary: a new product made from it.",
				W._sorted_words(["primary", "secondary"], items))
			ex.data = {"items": items}
		_:
			var chain: Array = FOOD_CHAINS[rng.randi_range(0, FOOD_CHAINS.size() - 1)]
			ex = K.order(rng, "Put this food's journey from farm to fork in order.", chain,
				"Grow it, gather it, process it (primary, then secondary), then get it to people.",
				", then ".join(PackedStringArray(chain)) + ".")
			ex.data = {"chain": chain}
	return ex


## Food's footprints (kg of greenhouse gases a kg, about): level 1, a footprint; level 2, how many times bigger; level 3,
## a swap's saving.
static func food_footprint(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var food := ["chicken", "cheese", "eggs", "tofu", "beef"][rng.randi_range(0, 4)] as String
			var kg := [0.5, 2.0, 3.0, 0.25][rng.randi_range(0, 3)] as float
			var per := int(FOOTPRINT[food])
			ex = K.number("Making 1 kg of %s gives off about %d kg of greenhouse gases. About how much for %s kg?" % [food, per,
				W._num_text(kg)], W._num_text(per * kg), "Multiply the footprint for 1 kg by the kilograms.",
				"%d × %s = %s kg." % [per, W._num_text(kg), W._num_text(per * kg)])
			ex.data = {"food": food, "kg": kg}
		2:
			var pairs := [["beef", "peas"], ["beef", "chicken"], ["beef", "eggs"], ["chicken", "peas"], ["eggs", "peas"],
				["tofu", "peas"], ["cheese", "peas"]]
			var p: Array = pairs[rng.randi_range(0, pairs.size() - 1)]
			var a := int(FOOTPRINT[p[0]])
			var b := int(FOOTPRINT[p[1]])
			ex = K.number("Per kg, %s gives off about %d kg of greenhouse gases and %s about %d kg. How many times bigger is %s's footprint?" % [
				p[0], a, p[1], b, p[0]], a / b, "Divide the bigger footprint by the smaller one.",
				"%d ÷ %d = %d times." % [a, b, a / b])
			ex.data = {"a": p[0], "b": p[1]}
		_:
			var swap := ["peas", "tofu", "chicken"][rng.randi_range(0, 2)] as String
			var kg := [0.25, 0.5, 0.2, 1.0][rng.randi_range(0, 3)] as float
			var saved := (100 - int(FOOTPRINT[swap])) * kg
			ex = K.number("Beef: about 100 kg of greenhouse gases per kg; %s: about %d kg. Swapping %s kg of beef for %s saves how many kg?" % [
				swap, FOOTPRINT[swap], W._num_text(kg), swap], W._num_text(saved),
				"Find the difference for 1 kg, then multiply by the kilograms swapped.",
				"100 − %d = %d per kg; × %s = %s kg saved." % [FOOTPRINT[swap], 100 - int(FOOTPRINT[swap]), W._num_text(kg),
				W._num_text(saved)])
			ex.data = {"swap": swap, "kg": kg}
	return ex


# --- Circular design ------------------------------------------------------------------------------------------------------

## The loops: level 1, an action's loop; level 2, the loops from best to last; level 3, the best choice for a case.
static func loop_order(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var a: Array = LOOP_ACTIONS[rng.randi_range(0, LOOP_ACTIONS.size() - 1)]
			var loops := ["maintain", "reuse", "refurbish", "recycle", "compost"].filter(func(l: String) -> bool:
				return l != str(a[1]))
			K.shuffle(rng, loops)
			ex = K.choice(rng, "Which loop of the circular economy is this: %s?" % a[0], str(a[1]), loops.slice(0, 3),
				"Is it kept going, passed on, rebuilt, made into new material, or returned to the soil?",
				"%s: %s." % [W._cap(str(a[0])), a[1]])
			ex.data = {"action": a[0]}
		2:
			ex = K.order(rng, "Put the choices in order, from the one that saves most to the last resort.", LOOP_RANK,
				"The smaller the loop, the more of the product's value and energy is kept.",
				"Maintain, reuse, refurbish, recycle, and landfill only as a last resort.")
			ex.data = {}
		_:
			var c: Array = CIRCULAR_CASES[rng.randi_range(0, CIRCULAR_CASES.size() - 1)]
			ex = K.choice(rng, "%s What is the best choice?" % c[0], str(c[1]), c[2],
				"Choose the smallest loop that still works: keep it, mend it or reuse it before recycling.",
				"Best: %s. It keeps the most value." % c[1])
			ex.data = {"case": c[0]}
	return ex


## Cost per year: level 1, one product's; level 2, how much less the longer-lasting one costs a year; level 3, the
## extra spent over years on cheap ones.
static func cost_per_year(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var what := PRODUCTS[rng.randi_range(0, PRODUCTS.size() - 1)]
	var ex: Dictionary
	match level:
		1:
			var years := rng.randi_range(2, 10)
			var per := rng.randi_range(2, 12)
			ex = K.number("A %d-gold %s lasts %d years. What does it cost per year?" % [years * per, what, years], per,
				"Share the price by the years it lasts.", "%d ÷ %d = %d gold a year." % [years * per, years, per])
			ex.data = {"price": years * per, "years": years}
		2:
			var ya := rng.randi_range(1, 3)
			var pa := ya * rng.randi_range(6, 15)
			var yb := ya * rng.randi_range(3, 5)
			var per_b := rng.randi_range(2, pa / ya - 1)
			var pb := yb * per_b
			ex = K.number("%s A costs %d gold and lasts %d year%s; %s B costs %d gold and lasts %d years. How much less per year does B cost?" % [
				W._cap(what), pa, ya, "" if ya == 1 else "s", what, pb, yb], pa / ya - per_b,
				"Work out each one's cost per year, then subtract.", "A: %d ÷ %d = %d a year. B: %d ÷ %d = %d a year. %d − %d = %d gold." % [
				pa, ya, pa / ya, pb, yb, per_b, pa / ya, per_b, pa / ya - per_b])
			ex.data = {"pa": pa, "ya": ya, "pb": pb, "yb": yb}
		_:
			var yc := rng.randi_range(2, 4)
			var span := yc * rng.randi_range(2, 4)
			var pc := rng.randi_range(2, 6) * 5
			var cheap := pc * span / yc
			var pg := rng.randi_range(pc + 5, cheap - 5)
			ex = K.number("Over %d years: a %d-gold %s lasts %d years, or a %d-gold one lasts all %d. How much more do the cheap ones cost in all?" % [
				span, pc, what, yc, pg, span], cheap - pg, "How many cheap ones are needed? Add up their cost, then compare.",
				"%d ÷ %d = %d cheap ones × %d = %d gold; %d − %d = %d gold more." % [span, yc, span / yc, pc, cheap, cheap,
				pg, cheap - pg])
			ex.data = {"span": span, "yc": yc, "pc": pc, "pg": pg}
	return ex


## Design for repair: level 1, easy to repair or not; level 2, sort; level 3, a designer's best choice.
static func repair_feature(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var easy := rng.randf() < 0.5
			var pool: Array = EASY_REPAIR if easy else HARD_REPAIR
			var f := str(pool[rng.randi_range(0, pool.size() - 1)])
			ex = K.truefalse("A product with %s is easy to repair." % f, easy,
				"Could you open it, get the part and put it back with ordinary tools?",
				("True: %s makes repair easy." if easy else "False: %s makes repair hard.") % f)
			ex.data = {"feature": f}
		2:
			var a := EASY_REPAIR.duplicate()
			var b := HARD_REPAIR.duplicate()
			K.shuffle(rng, a)
			K.shuffle(rng, b)
			var na := rng.randi_range(2, 3)
			var items: Array = []
			for i in na:
				items.append([a[i], "easy to repair"])
			for i in 5 - na:
				items.append([b[i], "hard to repair"])
			ex = W._sort(rng, "Easy to repair, or hard?", ["easy to repair", "hard to repair"], items,
				"Can it be opened, and can you get the parts and the know-how?",
				W._sorted_words(["easy to repair", "hard to repair"], items))
			ex.data = {"items": items}
		_:
			var c: Array = REPAIR_CASES[rng.randi_range(0, REPAIR_CASES.size() - 1)]
			ex = K.choice(rng, "%s Which choice is best?" % c[0], str(c[1]), c[2],
				"Which choice lets someone open it, mend it and separate its materials later?",
				"Best: %s." % W._cap(str(c[1])))
			ex.data = {"case": c[0]}
	return ex


# --- Future technology ----------------------------------------------------------------------------------------------------

## Technology's effects: level 1, the kind; level 2, sort social and environmental; level 3, sort three kinds.
static func impact_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := IMPACTS.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var i: Array = pool[0]
			ex = K.choice(rng, "What kind of effect is this: %s" % _end_mark(str(i[0])), str(i[1]),
				IMPACT_KINDS.filter(func(k: String) -> bool: return k != str(i[1])),
				"People's lives, the planet, money and jobs, or right and wrong?",
				"'%s' is %s." % [_end_mark(str(i[0])), i[1]])
			ex.data = {"impact": i[0]}
		_:
			var kinds: Array = ["social", "environmental"] if level == 2 else ["social", "environmental", "economic"]
			var items: Array = []
			for k: String in kinds:
				var some: Array = pool.filter(func(x: Array) -> bool: return str(x[1]) == k)
				items.append_array(some.slice(0, 3 if level == 2 and k == "social" else 2))
			if items.size() > 6:
				items = items.slice(0, 6)
			ex = W._sort(rng, "What kind of effect is each?", kinds, items,
				"Social: people's lives. Environmental: the planet. Economic: money and jobs.",
				W._sorted_words(kinds, items))
			ex.data = {"items": items}
	return ex


static func _end_mark(s: String) -> String:
	return s if s.ends_with("?") else s + "."


## Standby energy: level 1, watt-hours a day; level 2, kWh a year; level 3, many devices' kWh a year.
static func standby_energy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var w := [1, 2, 3, 4, 5, 10][rng.randi_range(0, 5)] as int
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A device uses %d W on standby. How many watt-hours does it use in 24 hours?" % w, w * 24,
				"Watt-hours = watts × hours.", "%d × 24 = %d Wh." % [w, w * 24])
			ex.data = {"w": w}
		2:
			var kwh := w * 24 * 365 / 1000.0
			ex = K.number("A device uses %d W on standby all day, every day. How many kWh is that in a year?" % w,
				W._num_text(kwh), "Watts × 24 × 365 gives watt-hours; divide by 1,000 for kWh.",
				"%d × 24 × 365 = %s Wh = %s kWh." % [w, GenKit.fmt(w * 24 * 365), W._num_text(kwh)])
			ex.data = {"w": w}
		_:
			var n := rng.randi_range(2, 10)
			var kwh := n * w * 24 * 365 / 1000.0
			ex = K.number("A smart home has %d devices, each using %d W on standby all day. How many kWh a year is that?" % [n,
				w], W._num_text(kwh), "Find the watts in all, then × 24 × 365 ÷ 1,000.",
				"%d × %d = %d W; × 24 × 365 = %s Wh = %s kWh." % [n, w, n * w, GenKit.fmt(n * w * 24 * 365),
				W._num_text(kwh)])
			ex.data = {"w": w, "n": n}
	return ex


## Driving automation: level 1, a level from what the car does; level 2, its number; level 3, a question about levels.
static func automation_level(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lv := rng.randi_range(0, 5)
	var ex: Dictionary
	match level:
		1:
			var wrongs: Array = []
			for k in 6:
				if k != lv:
					wrongs.append("level %d" % k)
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Which level of driving automation is this? The car %s." % AUTOMATION[lv], "level %d" % lv,
				wrongs.slice(0, 3), "Count up from no help at all to driving anywhere: who steers, who controls the speed, who watches?",
				"A car that %s is level %d." % [AUTOMATION[lv], lv])
		2:
			ex = K.number("On the scale of driving automation from 0 to 5, which level is a car that %s?" % AUTOMATION[lv], lv,
				"Count up: no help, one help, both with a watcher, some places, set areas, anywhere.",
				"A car that %s is level %d." % [AUTOMATION[lv], lv])
		_:
			var q: Array = AUTOMATION_QS[rng.randi_range(0, AUTOMATION_QS.size() - 1)]
			ex = K.choice(rng, str(q[0]), str(q[1]), q[2], "Who is responsible for driving at that level?",
				"%s %s." % [q[0], W._cap(str(q[1]))])
			ex.data = {"question": q[0]}
			return ex
	ex.data = {"level": lv}
	return ex


# --- Projects -------------------------------------------------------------------------------------------------------------

## A prototype's tests: level 1, how often it worked; level 2, the mean of five tests; level 3, the improvement.
static func reliability(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var n := [10, 20, 25, 40, 50][rng.randi_range(0, 4)] as int
			var p := _whole_pct(rng, n, 50, 95)
			ex = K.number("The prototype worked %d times in %d tests. What percentage is that?" % [n * p / 100, n], p,
				"Divide the times it worked by the tests, then times 100.", "%d ÷ %d × 100 = %d%%." % [n * p / 100, n, p])
			ex.data = {"worked": n * p / 100, "n": n}
		2:
			var mean := rng.randi_range(8, 20)
			var offs: Array = [-3, -1, 0, 1, 3]
			K.shuffle(rng, offs)
			var vals: Array = offs.map(func(o: int) -> int: return mean + o)
			ex = K.number("Five tests of how long the pump ran, in seconds: %s. What is the mean?" % W._and(vals.map(
				func(v: int) -> String: return str(v))), mean, "Add the five results, then divide by 5.",
				"%d ÷ 5 = %d seconds." % [mean * 5, mean])
			ex.data = {"values": vals}
		_:
			var n := [10, 20, 25, 50][rng.randi_range(0, 3)] as int
			var p1 := _whole_pct(rng, n, 40, 70)
			var p2 := p1
			for _t in 30:
				p2 = _whole_pct(rng, n, 50, 100)
				if p2 > p1:
					break
			if p2 <= p1:
				n = 10
				p1 = 50
				p2 = 80
			ex = K.number("Version 1 worked %d of %d times; version 2 worked %d of %d times. By how many percentage points did it improve?" % [
				n * p1 / 100, n, n * p2 / 100, n], p2 - p1, "Turn both into percentages, then subtract.",
				"%d%% and %d%%: %d − %d = %d percentage points." % [p1, p2, p2, p1, p2 - p1])
			ex.data = {"w1": n * p1 / 100, "w2": n * p2 / 100, "n": n}
	return ex


## A parts budget: level 1, the total; level 2, what is left; level 3, how many complete kits.
static func parts_budget(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := PARTS.duplicate()
	K.shuffle(rng, pool)
	var picked: Array = pool.slice(0, rng.randi_range(3, 4))
	var total := 0.0
	for p: Array in picked:
		total += float(p[1])
	var listed := W._and(picked.map(func(p: Array) -> String: return "%s (%s gold)" % [p[0], W._num_text(float(p[1]))]))
	var sum_text := " + ".join(PackedStringArray(picked.map(func(p: Array) -> String: return W._num_text(float(p[1])))))
	var ex: Dictionary
	var budget := 0
	match level:
		1:
			ex = K.number("The parts: %s. What is the total cost, in gold?" % listed, W._num_text(total),
				"Add the prices; line up the decimal points.", "%s = %s gold." % [sum_text, W._num_text(total)])
		2:
			budget = ceili(total / 5.0) * 5 + 5
			ex = K.number("The budget is %d gold. The parts: %s. How much gold is left?" % [budget, listed],
				W._num_text(budget - total), "Add the parts, then take the total from the budget.",
				"%s = %s; %d − %s = %s gold." % [sum_text, W._num_text(total), budget, W._num_text(total),
				W._num_text(budget - total)])
		_:
			budget = [50, 60, 80, 100][rng.randi_range(0, 3)] as int
			var kits := floori(budget / total)
			ex = K.number("Each kit needs %s. With %d gold, how many complete kits can you buy?" % [listed, budget], kits,
				"Find one kit's cost, divide the budget by it, and count whole kits only.",
				"One kit: %s gold; %d ÷ %s = %s, so %d whole kits." % [W._num_text(total), budget, W._num_text(total),
				W._num_text(snappedf(budget / total, 0.01)), kits])
	ex.data = {"parts": picked.map(func(p: Array) -> String: return str(p[0])), "budget": budget}
	return ex


## Animation frames: level 1, frames for some seconds; level 2, seconds from frames; level 3, a film's shots.
static func frame_count(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var fps := [8, 10, 12, 24][rng.randi_range(0, 3)] as int
	var ex: Dictionary
	match level:
		1:
			var secs := [5, 10, 15, 20, 30][rng.randi_range(0, 4)] as int
			ex = K.number("A stop-motion film runs at %d frames a second. How many frames make %d seconds?" % [fps, secs],
				fps * secs, "Frames = frames a second × seconds.", "%d × %d = %d frames: %d photos." % [fps, secs, fps * secs,
				fps * secs])
			ex.data = {"fps": fps, "secs": secs}
		2:
			var secs := rng.randi_range(4, 40)
			ex = K.number("A film has %d frames at %d frames a second. How many seconds long is it?" % [fps * secs, fps], secs,
				"Seconds = frames ÷ frames a second.", "%d ÷ %d = %d seconds." % [fps * secs, fps, secs])
			ex.data = {"fps": fps, "frames": fps * secs}
		_:
			var shots: Array = []
			for _i in rng.randi_range(3, 4):
				shots.append(rng.randi_range(2, 8))
			var total := 0
			for s: int in shots:
				total += s
			ex = K.number("A storyboard has shots of %s seconds, at %d frames a second. How many frames are needed in all?" % [
				W._and(shots.map(func(s: int) -> String: return str(s))), fps], total * fps,
				"Add the seconds first, then multiply by the frames a second.",
				"%s = %d seconds; × %d = %d frames." % [" + ".join(PackedStringArray(shots.map(func(s: int) -> String:
				return str(s)))), total, fps, total * fps])
			ex.data = {"fps": fps, "shots": shots}
	return ex


## Sources: level 1, primary or not; level 2, sort; level 3, using sources well.
static func source_type(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := SOURCES.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var s: Array = pool[0]
			ex = K.truefalse("%s is a primary source." % W._cap(str(s[0])), bool(s[1]),
				"Was it made at the time, by someone who was there?",
				("True: %s was made at the time." if bool(s[1]) else "False: %s was made later, so it is secondary.") % s[0])
			ex.data = {"source": s[0]}
		2:
			var items := _two_groups(pool, "primary", "secondary", rng)
			ex = W._sort(rng, "A primary or a secondary source?", ["primary", "secondary"], items,
				"Primary: from the time. Secondary: made later, about it.", W._sorted_words(["primary", "secondary"], items))
			ex.data = {"items": items}
		_:
			var q: Array = SOURCE_QS[rng.randi_range(0, SOURCE_QS.size() - 1)]
			ex = K.choice(rng, str(q[0]), str(q[1]), q[2], "Ask who made it, when and why, and check it against others.",
				"%s %s." % [q[0], W._cap(str(q[1]))])
			ex.data = {"question": q[0]}
	return ex


## Turning points: level 1, the years between two; level 2, a year from a gap; level 3, four in order.
static func years_between(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := TURNING.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1, 2:
			var a: Array = pool[0]
			var b: Array = pool[1]
			if int(a[1]) > int(b[1]):
				var t := a
				a = b
				b = t
			if level == 1:
				ex = K.number("How many years passed between %s (%d) and %s (%d)?" % [a[0], a[1], b[0], b[1]], int(b[1]) - int(a[1]),
					"Take the earlier year from the later one.", "%d − %d = %d years." % [b[1], a[1], int(b[1]) - int(a[1])])
			else:
				ex = K.number("'%s' came %d years after '%s' (%d). In which year was it?" % [W._cap(str(b[0])),
					int(b[1]) - int(a[1]), a[0], a[1]], int(b[1]), "Add the gap to the earlier year.",
					"%d + %d = %d." % [a[1], int(b[1]) - int(a[1]), b[1]])
				ex.year = true
			ex.data = {"a": a[0], "b": b[0]}
		_:
			var picked: Array = pool.slice(0, 4)
			picked.sort_custom(func(x: Array, y: Array) -> bool: return int(x[1]) < int(y[1]))
			ex = K.order(rng, "Put these turning points in time order, the earliest first.", picked.map(func(x: Array) -> String:
				return str(x[0])), "Think of trains, then planes, then votes and health, then space, then the web.",
				W._and(picked.map(func(x: Array) -> String: return "%s (%d)" % [x[0], x[1]])) + ".")
			ex.data = {"events": picked.map(func(x: Array) -> String: return str(x[0]))}
	return ex


## Litter data: level 1, a rate per 100 m; level 2, a fall in percent; level 3, a beach's total from a sample.
static func goal_rate(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var length := [50, 200, 250, 400, 500][rng.randi_range(0, 4)] as int
			var per := rng.randi_range(1, 15) * 2
			var count := per * length / 100
			ex = K.number("%d pieces of litter were found on a %d m stretch of beach. How many is that per 100 m?" % [count,
				length], per, "Find the count for 1 m, then times 100; or scale the stretch to 100 m.",
				"%d ÷ %d × 100 = %d per 100 m." % [count, length, per])
			ex.data = {"count": count, "length": length}
		2:
			var before := [20, 40, 50, 60, 80, 100][rng.randi_range(0, 5)] as int
			var pct := _whole_pct(rng, before, 10, 80)
			var after := before - before * pct / 100
			ex = K.number("Before the clean-up campaign: %d pieces. After: %d. By what percentage did the litter fall?" % [before,
				after], pct, "Find the fall, divide it by the starting count, then times 100.",
				"%d − %d = %d; %d ÷ %d × 100 = %d%%." % [before, after, before - after, before - after, before, pct])
			ex.data = {"before": before, "after": after}
		_:
			var mean := rng.randi_range(4, 15)
			var offs: Array = [-2, -1, 1, 2]
			K.shuffle(rng, offs)
			var counts: Array = offs.map(func(o: int) -> int: return mean + o)
			var length := [800, 1000, 1200, 1500, 2000][rng.randi_range(0, 4)] as int
			ex = K.number("A sample: litter on four 100 m stretches was %s. The beach is %s m long. Estimate its total litter." % [
				W._and(counts.map(func(c: int) -> String: return str(c))), GenKit.fmt(length)], mean * length / 100,
				"Find the mean per 100 m, then multiply by how many 100 m stretches the beach has.",
				"Mean: %d ÷ 4 = %d per 100 m; %s m is %d stretches; %d × %d = %d pieces." % [mean * 4, mean, GenKit.fmt(length),
				length / 100, mean, length / 100, mean * length / 100])
			ex.data = {"counts": counts, "length": length}
	return ex


## Scatter graphs: level 1, the kind of correlation; level 2, a point's value; level 3, what a correlation means.
static func correlation(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level == 3:
		var q: Array = CORRELATION_QS[rng.randi_range(0, CORRELATION_QS.size() - 1)]
		ex = K.choice(rng, str(q[0]), str(q[1]), q[2], "Going together is not the same as one thing causing the other.",
			"%s %s." % [q[0], W._cap(str(q[1]))])
		ex.data = {"question": q[0]}
		return ex
	var kind := ["positive", "negative", "none"][rng.randi_range(0, 2)] as String
	var pts := _scatter(rng, kind)
	var letters := "ABCDEFGH"
	var points: Array = []
	for i in pts.size():
		points.append([pts[i].x, pts[i].y, letters[i]] if level == 2 else [pts[i].x, pts[i].y])
	var pic := {"kind": "scatter_plot", "points": points, "x_name": "km from school", "y_name": "car trips a week",
		"x_to": 10, "x_step": 2, "y_to": 10, "y_step": 2}
	if level == 1:
		var name := {"positive": "positive", "negative": "negative", "none": "no correlation"}[kind] as String
		ex = K.choice(rng, "What kind of correlation does this scatter graph show?", name, ["positive", "negative",
			"no correlation"].filter(func(s: String) -> bool: return s != name),
			"Do the points rise to the right, fall to the right, or scatter with no pattern?",
			{"positive": "The points rise to the right: as one grows, so does the other.", "negative":
			"The points fall to the right: as one grows, the other shrinks.", "none":
			"The points are scattered with no clear slope."}[kind], pic)
	else:
		var k := rng.randi_range(0, pts.size() - 1)
		ex = K.number("Point %s: how many car trips a week?" % letters[k], int(pts[k].y),
			"Find the point's letter, then read across to the side scale.",
			"Point %s is at %d km and %d trips." % [letters[k], int(pts[k].x), int(pts[k].y)], pic)
	ex.data = {"kind": kind, "points": points}
	return ex


## 6-8 whole points in 0-10 with a clear positive, clear negative, or no correlation (by the sample correlation).
static func _scatter(rng: RandomNumberGenerator, kind: String) -> Array[Vector2]:
	var best: Array[Vector2] = []
	for _t in 200:
		var pts: Array[Vector2] = []
		var n := rng.randi_range(6, 8)
		var xs := range(1, 11)
		K.shuffle(rng, xs)
		for i in n:
			var x := float(xs[i])
			var y := float(rng.randi_range(1, 9))
			if kind == "positive":
				y = clampf(roundf(x * 0.8 + rng.randi_range(-1, 1) + 0.5), 0, 10)
			elif kind == "negative":
				y = clampf(roundf(9.5 - x * 0.8 + rng.randi_range(-1, 1)), 0, 10)
			pts.append(Vector2(x, y))
		var r := _pearson(pts)
		if (kind == "positive" and r > 0.7) or (kind == "negative" and r < -0.7) or (kind == "none" and absf(r) < 0.25):
			return pts
		best = pts
	return best


## The sample correlation of points (−1 to 1; 0 when either spread is 0).
static func _pearson(pts: Array[Vector2]) -> float:
	var n := pts.size()
	var mx := 0.0
	var my := 0.0
	for p in pts:
		mx += p.x / n
		my += p.y / n
	var sxy := 0.0
	var sxx := 0.0
	var syy := 0.0
	for p in pts:
		sxy += (p.x - mx) * (p.y - my)
		sxx += (p.x - mx) * (p.x - mx)
		syy += (p.y - my) * (p.y - my)
	return 0.0 if sxx == 0.0 or syy == 0.0 else sxy / sqrt(sxx * syy)


## Surveys: level 1, a fair question; level 2, sort fair and leading; level 3, samples.
static func survey_question(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool := SURVEY_QS.duplicate()
	K.shuffle(rng, pool)
	var ex: Dictionary
	match level:
		1:
			var fair: Array = pool.filter(func(q: Array) -> bool: return bool(q[1]))
			var leading: Array = pool.filter(func(q: Array) -> bool: return not bool(q[1]))
			ex = K.choice(rng, "Which survey question is fair (not leading)?", str(fair[0][0]), leading.slice(0, 3).map(
				func(q: Array) -> String: return str(q[0])), "A leading question pushes people towards one answer.",
				"'%s' lets people answer freely; the others push them." % fair[0][0])
			ex.data = {"right": fair[0][0]}
		2:
			var items := _two_groups(pool, "fair", "leading", rng)
			ex = W._sort(rng, "A fair question, or a leading one?", ["fair", "leading"], items,
				"Does the question hint at the answer it wants?", W._sorted_words(["fair", "leading"], items))
			ex.data = {"items": items}
		_:
			var q: Array = SAMPLE_QS[rng.randi_range(0, SAMPLE_QS.size() - 1)]
			ex = K.choice(rng, str(q[0]), str(q[1]), q[2], "A good sample is big enough, chosen fairly, and typical.",
				"%s %s." % [q[0], W._cap(str(q[1]))])
			ex.data = {"question": q[0]}
	return ex


# --- Helpers --------------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return PEOPLE[rng.randi_range(0, PEOPLE.size() - 1)]


## Up to `n` values of column `col` other than `not_this`, each once.
static func _other_values(rows: Array, col: int, not_this: String, n: int) -> Array:
	var out: Array = []
	for r: Array in rows:
		var v := str(r[col])
		if v != not_this and not out.has(v) and out.size() < n:
			out.append(v)
	return out


## Up to `n` rows whose column `col` values are all different (first come, first kept).
static func _distinct_by(rows: Array, col: int, n: int) -> Array:
	var out: Array = []
	var seen := {}
	for r: Array in rows:
		if not seen.has(str(r[col])) and out.size() < n:
			seen[str(r[col])] = true
			out.append(r)
	return out
