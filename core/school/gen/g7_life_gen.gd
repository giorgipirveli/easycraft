class_name G7LifeGen
extends RefCounted
## Owner #70, #73 and #111 (research §6.7): grade 7 health and PE, design and technology, and projects generators:
## advanced tactics and overloads, badminton's serving court and the end of a game, tennis scores, shots for a
## situation, maximum heart rates and their zones, a week's minutes, dance counts and styles, a referee's calls, a
## tournament's matches, hours of sleep and sleep habits, adverts' tricks and what influences a choice, edited photos
## and kind thoughts, facts about drugs and the law and getting help, I-statements and calming a conflict, where to get
## help; a product's parts and materials, scales of production and a mould's cost, 3D printing layers and laser cuts,
## additive or subtractive making, resistors' colour codes and LED resistors, circuits that work, a microcontroller's
## LEDs, pauses and decisions, fabrics and fibres, scaling a recipe, dishes and staple foods, food waste and where food
## is stored, a product's life and the 6 Rs, tests' means and fair tests; distances and supplies at sea, energy, carbon
## and water in a district, a price's markup and a business's profit or loss. SchoolGen "g7w.<name>",
## `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with a hint (a
## strategy), a worked answer and `data` (its inputs, for tests/unit/test_g7_life_gen.gd). Helpers start with "_".

const K := preload("res://core/school/gen/gen_kit.gd")
const PEOPLE: Array[String] = ["Tilly", "Zara", "Bram", "Mimi"]

# --- Banks (checked by the test with its own copies) ----------------------------------------------------------------

## Advanced tactics: [name, "attacking" | "defending", what it looks like].
const TACTICS: Array = [
	["overlap", "attacking", "A teammate runs round the outside of the player with the ball, ready for a wide pass."],
	["third-man run", "attacking", "A passes to B, and C is already running into space for B's next pass."],
	["switch of play", "attacking", "The ball moves quickly from one side of the pitch to the other, where there is space."],
	["decoy run", "attacking", "A player sprints away to drag a defender with them, opening space for a teammate."],
	["give-and-go", "attacking", "A player passes, sprints past their defender and gets the ball straight back."],
	["screen", "attacking", "In basketball, a player stands still and legally blocks a defender, so a teammate gets free."],
	["pressing", "defending", "Players close down the ball together, high up the pitch, to win it back quickly."],
	["zonal marking", "defending", "Each defender guards an area and marks whoever comes into it."],
	["man-to-man marking", "defending", "Each defender follows one attacker wherever they go."],
	["recovery run", "defending", "After losing the ball, a player sprints back to get goal-side of an attacker."],
	["double team", "defending", "Two defenders close down the player with the ball at the same time."],
	["compact block", "defending", "Defenders and midfielders squeeze into two close lines, leaving no gaps between them."],
]
## Game situations: [situation, best choice, other choices].
const SITUATIONS: Array = [
	["Your team has 3 attackers against 2 defenders near goal. What should the player with the ball do first?",
		"run at a defender to draw them, then pass", ["pass back to the goalkeeper", "stop and wait for help",
		"shoot from far away"]],
	["Your team has just lost the ball near the other team's goal. What can the nearest players do?",
		"press at once to win it back", ["walk back slowly", "stand still and watch", "argue with the referee"]],
	["The other team has crowded one side of the pitch. What can your team do?", "switch play to the empty side",
		["keep passing into the crowd", "kick the ball out", "all run to that side"]],
	["An attacker is clean through on goal and you are behind them. What do you do?",
		"sprint back to get goal-side", ["give up and walk", "pull their shirt", "shout at your goalkeeper"]],
	["Your team wins the ball and the other team is out of position. What is the quickest way to attack?",
		"counter-attack fast, into the space", ["pass sideways slowly", "wait for everyone to get back",
		"kick it high and long out of play"]],
	["A defender is marking your striker very closely. How can a teammate help the striker get free?",
		"make a decoy run to pull defenders away", ["stand next to the striker", "stop moving", "ask the defender to move"]],
	["In netball, a defender is close behind your teammate. How can you help them get the ball?",
		"move into space and call, then pass and move", ["throw it at the defender", "hold the ball for 10 seconds",
		"stand still in the circle"]],
]
## Badminton: a game is rally scoring to 21, won by 2 clear, and 30 wins at 29-all.
const BADMINTON_TO := 21
const BADMINTON_CAP := 30
## Tennis's calls for 0-3 points.
const TENNIS_CALLS: Array[String] = ["love", "15", "30", "40"]
## Shots for a situation: [situation, the shot, why].
const SHOT_CASES: Array = [
	["Your opponent is close to the net.", "clear", "it flies high and deep, over them"],
	["Your opponent is at the back of the court.", "drop shot", "it falls just over the net, far from them"],
	["The shuttle comes high and short, near the middle of your court.", "smash",
		"a high, short shuttle can be hit down hard"],
	["The shuttle is at about net height and you want a fast, flat return.", "drive",
		"it is fast and flat, just over the net"],
	["The shuttle drops just over the net on your side.", "net shot", "it tips the shuttle just back over the net"],
	["You are pushed back and need time to get back to your base.", "clear",
		"a high clear gives you time to recover"],
]
const SHOT_LETTERS := "ABCD"
## Ages and who they are, for a maximum heart rate of about 220 − age.
const AGES: Array = [[10, "Mimi's cousin"], [12, "Tilly"], [13, "Bram"], [15, "Zara's sister"], [20, "a young coach"],
	[30, "a PE teacher"], [35, "Bram's aunt"], [40, "a swimming coach"], [45, "Mimi's dad"], [60, "Tilly's grandad"]]
## Ages whose zones' edges (60% and 80%) are whole beats: 220 − age is a multiple of 5.
const WHOLE_AGES: Array = [[10, "Mimi's cousin"], [15, "Zara's sister"], [20, "a young coach"], [30, "a PE teacher"],
	[35, "Bram's aunt"], [40, "a swimming coach"], [45, "Mimi's dad"], [60, "Tilly's grandad"]]
const ACTIVITIES: Array[String] = ["cycling", "swimming", "football", "dance", "running", "netball", "tennis", "walking"]
## Dance moves and their style: [move, style].
const DANCE_MOVES: Array = [
	["a freeze, balancing on your hands", "street"], ["toprock: steps danced standing up", "street"],
	["popping: tensing muscles on the beat", "street"], ["locking: quick moves that stop and hold", "street"],
	["a battle in a circle called a cypher", "street"],
	["quick, neat steps with the arms still", "folk"], ["dancing in lines with bells and sticks", "folk"],
	["a circle dance, holding hands", "folk"], ["a reel with a partner at a ceilidh", "folk"],
	["a harvest dance from Punjab: Bhangra", "folk"],
	["floorwork: rolling and sliding on the floor", "contemporary"], ["contraction and release", "contemporary"],
	["fall and recovery", "contemporary"], ["moving freely to show a feeling", "contemporary"],
]
const DANCE_STYLES: Array[String] = ["street", "folk", "contemporary"]
const DANCE_FACTS: Array = [
	["Breaking began in…", "New York in the 1970s", ["Paris in the 1800s", "Rome in 100 BC", "Tokyo in 1600"]],
	["Bhangra comes from…", "Punjab, at harvest time", ["Ireland, at weddings", "Brazil, at carnival",
		"Japan, at New Year"]],
	["Martha Graham was a pioneer of…", "contemporary dance", ["breaking", "Morris dancing", "ballroom dancing"]],
	["Morris dancers often wear…", "bells on their legs", ["roller skates", "helmets", "flippers"]],
	["In Irish step dance, the arms are usually…", "held still at the sides", ["waved above the head",
		"crossed behind the back", "flapped like wings"]],
	["A cypher is…", "a circle where street dancers take turns", ["a kind of folk costume", "a slow ballet step",
		"a dance with a partner"]],
]
## Football's signals (the Laws of the Game) and what they mean.
const SIGNAL_MEANING := {"advantage": "play on: the fouled team still has a good chance",
	"direct": "a direct free kick, the way the arm points", "indirect": "an indirect free kick: someone else must touch it before a goal",
	"penalty": "a penalty kick", "card": "a caution (yellow) or a sending off (red)"}
## Referee's decisions: [what happened, the decision, other decisions].
const REF_CASES: Array = [
	["A player is fouled, but their team keeps the ball with a good chance to score.", "play advantage",
		["stop play for a free kick", "give a penalty", "give a throw-in"]],
	["A defender trips an attacker inside their own penalty area.", "a penalty kick",
		["a corner kick", "a drop ball", "a goal kick"]],
	["An attacker is offside when the ball is passed to them.", "an indirect free kick",
		["a penalty kick", "a corner kick", "play on"]],
	["A player pushes an opponent in the middle of the pitch.", "a direct free kick",
		["a throw-in", "a goal kick", "play on"]],
	["The ball goes over the touchline off a red player.", "a throw-in to the other team",
		["a penalty kick", "a corner kick", "a free kick to red"]],
	["A player keeps fouling again and again on purpose.", "a free kick and a yellow card",
		["nothing at all", "a goal for the other team", "a drop ball"]],
]
## Being a fair official: [situation, the fair choice, other choices].
const FAIR_CASES: Array = [
	["You are refereeing a friendly match. Your best friend fouls someone.", "give the free kick, as for anyone",
		["let it go because they are your friend", "give a penalty to your friend", "stop refereeing"]],
	["A player shouts at you about a decision.", "stay calm, explain briefly and play on",
		["shout back", "change the decision to please them", "end the match"]],
	["You did not see who touched the ball last before it went out.", "ask your assistant, then decide",
		["guess and pick your favourite team", "let both teams argue", "stop the game for good"]],
	["As captain, a teammate makes a mistake that costs a goal.", "encourage them and focus on the next play",
		["tell them off in front of everyone", "ask the coach to take them off", "ignore them"]],
	["As coach, a player keeps missing passes in practice.", "give one clear tip and praise what improves",
		["list everything they do wrong", "tell them to give up", "only coach the best players"]],
]
## Helps or harms a teenager's sleep.
const SLEEP_HELPS: Array[String] = ["the same bedtime every day", "a dark, quiet, cool bedroom",
	"daylight in the morning", "screens off an hour before bed", "exercise earlier in the day", "reading a paper book"]
const SLEEP_HARMS: Array[String] = ["an energy drink in the evening", "a phone in bed", "a late lie-in every weekend",
	"a bright screen at midnight", "games just before bed", "a busy, noisy room"]
const SLEEP_FACTS: Array = [
	[true, "Teenagers need about 8 to 10 hours of sleep a night."],
	[true, "In the teenage years the body clock moves later, so you feel sleepy later."],
	[true, "Melatonin, the hormone that makes you sleepy, is released when it gets dark."],
	[true, "Sleep helps your memory: the brain sorts what you learned that day."],
	[true, "Caffeine can keep you awake for hours after a drink."],
	[false, "Teenagers need less sleep than younger children because they are bigger."],
	[false, "Screens just before bed help you fall asleep."],
	[false, "Sleeping late every weekend fixes a whole week of short nights."],
	[false, "The light from a phone has no effect on your body clock."],
]
## An advert's lines and the trick each uses.
const ADVERT_LINES: Array = [
	["'Nine out of ten kids love it!'", "bandwagon"], ["'Everyone at school has one!'", "bandwagon"],
	["'As worn by a champion runner.'", "famous person"], ["A football star smiles with the drink.", "famous person"],
	["'Now with added vitamins!'", "health claim"], ["'Packed with goodness!'", "health claim"],
	["'Buy one and get a free toy!'", "free gift"], ["'Collect 5 tokens for a free poster!'", "free gift"],
	["Tiny words at the bottom of the screen.", "small print"], ["'*Terms apply' in very small letters.", "small print"],
	["A video says '#ad' at the start.", "paid post"], ["An influencer is paid to show a snack.", "paid post"],
]
const ADVERT_TRICKS: Array[String] = ["bandwagon", "famous person", "health claim", "free gift", "small print", "paid post"]
const ADVERT_TRICK_IDS := {"bandwagon": "bandwagon", "famous person": "star", "health claim": "health_claim",
	"free gift": "free_gift", "small print": "small_print", "#ad label": "ad_label"}
## What to ask about an advert's claim: [claim, the question to ask, other choices].
const ADVERT_CHECKS: Array = [
	["A fizzy drink says 'Full of vitamins!'", "How much sugar does it have?", ["Is the can a nice colour?",
		"Is the advert funny?", "Does a star drink it?"]],
	["A video star says a snack is 'the best ever'.", "Were they paid to say it?", ["How many followers do they have?",
		"Is the video long?", "Is the music good?"]],
	["'Free gift inside!'", "What do I have to buy to get it?", ["What colour is the gift?",
		"Is the box big?", "Who drew the logo?"]],
	["'Everyone has one!'", "Do I need it, or just want it?", ["Will my friends see it?", "Is it shiny?",
		"Is the advert loud?"]],
]
## What influences a choice: [the story, the influence].
const INFLUENCES: Array = [
	["Tilly eats the same breakfast as her parents.", "family"], ["Bram wants the trainers his friends wear.", "friends"],
	["Zara watches a video star try a new drink.", "media"], ["A poster at the bus stop shows a new snack.", "adverts"],
	["Mimi's family cooks special food for a festival.", "culture"], ["The school canteen serves fruit every day.", "school"],
	["Bram tries hockey because his older cousin plays.", "family"], ["Mimi joins a running club with her best friend.", "friends"],
	["A TV programme makes Zara want to try climbing.", "media"], ["A cereal box promises a free toy.", "adverts"],
]
const INFLUENCE_KINDS: Array[String] = ["family", "friends", "media", "adverts", "culture", "school"]
const HEALTHY_PULL: Array[String] = ["a friend asks you to join a club", "a family walk at the weekend",
	"a video about cooking vegetables", "a poster about drinking water"]
const UNHEALTHY_PULL: Array[String] = ["a dare to skip lunch", "an advert for a sugary drink",
	"friends staying up all night gaming", "a video star's risky stunt"]
## Unkind thoughts and a kinder way to say them.
const THOUGHTS: Array = [
	["I'm rubbish at this.", "I'm still learning this."], ["Everyone is better than me.",
		"I'm only seeing their best moments."],
	["I'll never get it right.", "I can try a new way next time."], ["I look awful in this photo.",
		"It's one photo, and I'm more than a photo."],
	["I made a mistake, so I'm useless.", "Everyone makes mistakes: what can I learn?"],
	["I can't do anything well.", "I'm good at some things and getting better."],
]
const UNKIND_EXTRA: Array[String] = ["I should give up.", "Nobody likes me.", "I'm not good enough."]
const EDIT_FACTS: Array = [
	[true, "Most photos in adverts are edited before you see them."],
	[true, "Filters and apps can change skin, eyes, teeth and the background."],
	[true, "A computer program can make a picture of a person who does not exist."],
	[true, "People often post the best of many photos, not their everyday life."],
	[false, "A photo online always shows exactly what was really there."],
	[false, "If someone looks perfect online, they look like that every day."],
	[false, "An edited photo always says that it was edited."],
]
## Facts about drugs: [level, true or false, the statement] (the NHS, FRANK, UK law).
const DRUG_FACTS: Array = [
	[1, true, "A drug is a substance that changes the way the body or mind works."],
	[1, true, "Medicines are drugs that can help when they are used the way the label says."],
	[1, false, "It is safe to take a medicine that was prescribed for a friend."],
	[1, true, "Caffeine, in coffee and energy drinks, is a drug."],
	[1, true, "Breathing in gas, glue or aerosol sprays can stop the heart, even the first time."],
	[1, true, "Most young people never take illegal drugs."],
	[1, false, "Illegal drugs are always made safely."],
	[2, true, "You cannot know what is in an illegal drug or how strong it is."],
	[2, true, "Mixing drugs, or drugs and alcohol, makes them more dangerous."],
	[2, true, "Drugs can harm mental health as well as the body."],
	[2, true, "Drugs can make it harder to learn, sleep and do well at sport."],
	[2, false, "A drug that is legal for adults is always safe."],
	[2, false, "Saying no to drugs means you will lose your friends."],
	[3, true, "In the UK, the Misuse of Drugs Act puts illegal drugs into classes A, B and C."],
	[3, true, "In the UK, class A drugs carry the most serious punishments."],
	[3, true, "Giving an illegal drug to a friend, even for free, counts as supplying it."],
	[3, true, "A criminal record can make it harder to get some jobs or visit some countries."],
	[3, true, "FRANK gives free, confidential advice about drugs on 0300 123 6600."],
	[3, false, "It is legal to carry an illegal drug if it is only for yourself."],
	[3, false, "Only adults can call FRANK for advice."],
]
## Who to turn to: [worry, the best help, other choices].
const DRUG_HELP: Array = [
	["You are worried about a friend who is taking drugs.", "tell a trusted adult or call FRANK",
		["keep it secret forever", "post about it online", "take some too, to stay friends"]],
	["Someone offers you a pill at a party.", "say no and move away", ["take it to be polite",
		"keep it for later", "sell it to someone else"]],
	["A friend has taken something and will not wake up.", "call 999 at once", ["let them sleep it off",
		"wait until morning", "give them a cold drink"]],
	["You found a packet of tablets on the pavement.", "do not touch it: tell an adult", ["try one", "take it home",
		"give it to a younger child"]],
	["You have questions about drugs but feel shy asking.", "call FRANK or Childline, free and confidential",
		["guess the answers", "ask a stranger online", "never ask anyone"]],
]
const EMERGENCY_STEPS: Array[String] = ["check it is safe to go near", "call 999 and say what has happened",
	"recovery position, if breathing", "stay with them until help comes", "tell the paramedics what they took"]
const SAY_NO: Array[String] = ["No thanks, it's not for me.", "No. I'm going home now.",
	"No thanks. Let's go and play football instead."]
const WEAK_NO: Array[String] = ["Um, maybe later?", "I don't know… perhaps.", "OK, just this once.", "Ask me tomorrow."]
const OFFERS: Array[String] = ["a pill", "something to sniff", "a strange drink at a party", "a tablet in a packet"]
## I-statements: [situation, the I-statement, blaming ones].
const I_CASES: Array = [
	["Zara keeps taking Mimi's pens without asking.", "I feel cross when my pens go: I need them.",
		["You always steal my stuff!", "You're so annoying.", "Give them back or else."]],
	["Bram's team leaves Tilly out of the game.", "I feel upset when I'm left out: I want to play.",
		["You're all mean.", "I hate this team.", "You never let anyone play."]],
	["A friend is late again.", "I feel worried when you're late: I wait alone.",
		["You're always late!", "You don't care about me.", "That's it, we're not friends."]],
	["Someone talks over Mimi in a group project.", "I feel ignored when talked over: I have ideas.",
		["Stop being rude!", "You think you know everything.", "You never listen."]],
]
## Win-win solutions: [the quarrel, a win-win, choices that are not].
const WIN_CASES: Array = [
	["Two friends both want the one computer for their projects.", "take turns: half an hour each",
		["the louder one gets it", "nobody uses it", "one tells the teacher a lie"]],
	["Tilly wants to play football and Zara wants to play tag.", "play football first, then tag",
		["Tilly goes home", "they never play again", "Zara gets her way always"]],
	["Bram and Mimi both want the last slice of cake.", "cut it in half and share",
		["grab it first", "throw it away in a sulk", "argue until it is stale"]],
	["Two players both want to be captain.", "captain for one match each",
		["the taller one is captain", "nobody plays", "pick by shouting the loudest"]],
]
const CALM_MOVES: Array[String] = ["take slow breaths", "speak in a calm voice", "listen without interrupting",
	"take a break and talk later", "say what you feel with 'I'"]
const HEAT_MOVES: Array[String] = ["shout over them", "call them names", "bring more people in", "blame them for everything",
	"bring up old quarrels"]
const CONFLICT_STEPS: Array[String] = ["stop and calm down", "say what happened and how you feel", "listen to each other",
	"think of solutions together", "agree on one and check later"]
## Where to get help: [need, the help, other choices].
const HELP_CASES: Array = [
	["A house is on fire.", "999 or 112", ["111", "0800 1111", "101"]],
	["Someone has collapsed and is not breathing.", "999 or 112", ["111", "0800 1111", "a text to a friend"]],
	["You have a bad earache in the evening, but it is not an emergency.", "111", ["999", "0800 1111", "101"]],
	["You feel worried all the time and want to talk to someone.", "a trusted adult or Childline, 0800 1111",
		["nobody", "999", "a stranger online"]],
	["Someone online asks you to send photos and keep it secret.", "a trusted adult and the CEOP button",
		["send them", "keep the secret", "reply with your address"]],
	["Your bike was stolen yesterday.", "101, the police's non-emergency number",
		["999", "0800 1111", "111"]],
]
const HELP_FACTS: Array = [
	[true, "Childline is free, and the call does not show on a phone bill."],
	[true, "112 works for emergencies in the UK and in many other countries."],
	[true, "Many European countries use 116 111 for a children's helpline."],
	[true, "A trusted adult may need to tell someone else if you are in danger."],
	[true, "If the first adult you tell does not help, keep telling until someone does."],
	[false, "You should only ask for help if the problem is huge."],
	[false, "999 is the right number for a lost homework book."],
	[false, "Telling a trusted adult about something unsafe is telling tales."],
]

# --- Design and technology banks ---------------------------------------------------------------------------------------

## A torch's parts: [part, material, why].
const TORCH_MATERIALS: Array = [
	["case", "ABS plastic", "tough, light and easy to mould"], ["lens", "acrylic", "clear and harder to shatter than glass"],
	["spring", "steel", "springy and conducts electricity"], ["contacts", "brass", "conducts and does not rust"],
	["reflector", "shiny metal-coated plastic", "reflects light forward"], ["switch button", "rubber", "soft, grippy and waterproof"],
]
## How parts are made: [part, process].
const PROCESSES: Array = [
	["a plastic torch case, by the thousand", "injection moulding"], ["a plastic chair in one piece", "injection moulding"],
	["a thin plastic tray for chocolates", "vacuum forming"], ["a yoghurt pot lid shape from a plastic sheet", "vacuum forming"],
	["a metal battery contact from a sheet", "pressing (stamping)"], ["a steel car door panel", "pressing (stamping)"],
	["an aluminium engine part from molten metal", "casting"], ["a bronze statue", "casting"],
]
const PROCESS_NAMES: Array[String] = ["injection moulding", "vacuum forming", "pressing (stamping)", "casting"]
const SCALE_CASES: Array = [
	["a wedding cake made for one couple", "one-off"], ["a bridge across one river", "one-off"],
	["a made-to-measure suit", "one-off"], ["100 loaves at a bakery each morning", "batch"],
	["500 school jumpers in one colour", "batch"], ["a run of 200 concert posters", "batch"],
	["millions of identical drink cans", "mass production"], ["cars on a production line", "mass production"],
	["a phone model sold all over the world", "mass production"],
]
const SCALES: Array[String] = ["one-off", "batch", "mass production"]
const LAYER_HEIGHTS: Array = [[0.1, "0.1"], [0.2, "0.2"], [0.25, "0.25"], [0.3, "0.3"]]
const MAKE_CASES: Array = [
	["A 3D printer builds a model layer by layer.", "additive"], ["A laser cutter burns a shape out of a sheet.", "subtractive"],
	["A CNC router cuts a shape out of a block of wood.", "subtractive"], ["A drill makes a hole.", "subtractive"],
	["A potter builds a pot from coils of clay.", "additive"], ["A file smooths away a rough edge.", "subtractive"],
]
const MACHINE_CASES: Array = [
	["a flat name sign cut from 3 mm plywood", "a laser cutter"], ["a key ring cut from acrylic sheet", "a laser cutter"],
	["a hollow phone stand with a curved inside", "a 3D printer"], ["a small model of a building's shape", "a 3D printer"],
	["a chess piece shaped from a thick block of wood", "a CNC router"], ["a carved wooden sign, 2 cm deep", "a CNC router"],
]
const MACHINE_NAMES: Array[String] = ["a laser cutter", "a 3D printer", "a CNC router"]
## Resistor values (two digits and a number of zeros) the units ask about.
const DIGIT_COLOURS: Array[String] = ["black", "brown", "red", "orange", "yellow", "green", "blue", "violet", "grey",
	"white"]
const E12: Array[int] = [10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82]
## LED resistor sums: [supply volts, LED volts, current in mA].
const LED_CASES: Array = [[9, 2, 20], [5, 2, 20], [6, 2, 20], [12, 2, 20], [9, 2, 10], [5, 3, 20], [3, 2, 10],
	[12, 3, 20], [6, 3, 10], [9, 3, 20]]
## Switches for an alarm: [what the alarm notices, the input].
const ALARM_INPUTS: Array = [
	["a door being opened", "a reed switch and a magnet"], ["someone stepping on a mat", "a pressure pad"],
	["a bag being tipped or lifted", "a tilt switch"], ["the room getting dark", "an LDR (light sensor)"],
	["a visitor pressing a button", "a push switch"],
]
const ALARM_WHY: Array = [
	["Why does an LED need a resistor in series?", "it limits the current so the LED won't burn out",
		["it makes the LED change colour", "it stores electricity", "it is only there to look neat"]],
	["An LED stays dark. What should you check first?", "that its long leg goes to the positive side",
		["that it is a nice colour", "that the wires are long", "that the battery is new and shiny"]],
	["Why build an alarm on a breadboard first?", "parts can be moved and tested without soldering",
		["breadboards are the strongest", "it makes the alarm louder", "it is the only way to use LEDs"]],
	["Why is a soldering iron used only with a grown-up nearby?", "its tip is hot enough to burn, about 350 °C",
		["it is very heavy", "it is loud", "it uses a lot of paper"]],
]
## Fabric needs: [use, the fabric or property, other choices].
const FABRIC_CASES: Array = [
	["a walking jacket for rainy hills", "a waterproof, breathable fabric", ["thin cotton", "wool felt", "paper"]],
	["a cyclist's vest for dark evenings", "reflective strips", ["a dark fabric", "velvet", "a lace pattern"]],
	["a cyclist's top for dull days", "fluorescent colours", ["black cotton", "a dark denim", "a see-through net"]],
	["a firefighter's suit", "fire-resistant aramid fibres", ["nylon", "silk", "cotton jersey"]],
	["a top that tracks your heart rate", "a smart fabric with sensors", ["a woollen jumper", "a plain T-shirt",
		"a paper suit"]],
	["a swimsuit that stretches and springs back", "elastane", ["linen", "felt", "canvas"]],
	["a winter hat that keeps heat in", "fleece that traps air", ["a thin net", "a plastic bag", "silk ribbon"]],
]
const NATURAL_FIBRES: Array[String] = ["cotton", "wool", "silk", "linen"]
const SYNTHETIC_FIBRES: Array[String] = ["polyester", "nylon", "elastane", "acrylic"]
const SMART_OR_TECH: Array = [
	["a T-shirt that changes colour when it gets warm", "smart"], ["a jacket with LEDs that flash", "smart"],
	["a shirt with sensors that measure your heart", "smart"], ["a waterproof, breathable coat", "technical"],
	["fire-resistant gloves", "technical"], ["a cut-resistant glove for chefs", "technical"],
]
## Dishes and where they come from.
const DISHES: Array = [
	["paella", "Spain"], ["dal with rice", "India"], ["jollof rice", "West Africa"], ["tacos", "Mexico"],
	["sushi", "Japan"], ["khachapuri", "Georgia"], ["couscous", "North Africa"], ["pierogi", "Poland"],
	["pho", "Vietnam"], ["goulash", "Hungary"],
]
const STAPLES: Array = [
	["rice", "warm, wet places, like South and East Asia"], ["wheat", "cooler, drier places, like Europe"],
	["maize", "the Americas, where it was first grown"], ["cassava", "hot, tropical places, like much of Africa"],
	["potatoes", "the Andes mountains of South America first"],
]
## Food waste: where food keeps best: [food, "fridge" | "freezer" | "cupboard"].
const STORE_CASES: Array = [
	["milk", "fridge"], ["yoghurt", "fridge"], ["raw chicken, on the bottom shelf", "fridge"], ["cheese", "fridge"],
	["frozen peas", "freezer"], ["ice cream", "freezer"], ["fish fingers", "freezer"],
	["dry pasta", "cupboard"], ["rice", "cupboard"], ["tinned beans", "cupboard"], ["bread to eat this week", "cupboard"],
]
const PLACES: Array[String] = ["fridge", "freezer", "cupboard"]
const FOODS_WITH_DATES: Array[String] = ["yoghurts", "cartons of milk", "packs of cheese", "boxes of eggs"]
## A product's life: [what happens, the stage].
const STAGE_CASES: Array = [
	["Bauxite is dug out of the ground to make aluminium.", "raw materials"],
	["Cotton is grown and picked.", "raw materials"], ["Oil is pumped up to make plastic.", "raw materials"],
	["The phone's case is moulded in a factory.", "manufacture"], ["Parts are put together on a production line.", "manufacture"],
	["The bikes are shipped across the sea.", "transport"], ["Lorries carry the boxes to the shops.", "transport"],
	["The kettle is boiled three times a day.", "use"], ["The washing machine washes clothes for ten years.", "use"],
	["The old phone is taken apart for recycling.", "end of life"], ["The broken chair goes to landfill.", "end of life"],
]
const STAGES: Array[String] = ["raw materials", "manufacture", "transport", "use", "end of life"]
const SIX_RS: Array = [
	["rethink", "ask if there is a better way to do it"], ["refuse", "say no to things you do not need"],
	["reduce", "use less material and energy"], ["reuse", "use it again, for the same or a new job"],
	["repair", "mend it instead of throwing it away"], ["recycle", "turn its materials into something new"],
]
const SIX_R_CASES: Array = [
	["Bram mends the puncture in his bike tyre.", "repair"], ["Tilly says no to a free plastic bag.", "refuse"],
	["Zara turns a jam jar into a pencil pot.", "reuse"], ["Mimi's old cans go in the metal bin.", "recycle"],
	["A designer uses thinner card for the same strong box.", "reduce"],
	["A team asks if a product could be shared instead of each buying one.", "rethink"],
]
const PLASTIC_CODES: Array = [[1, "PET", "drink bottles"], [2, "HDPE", "milk bottles"], [4, "LDPE", "carrier bags"],
	[5, "PP", "yoghurt pots and food tubs"], [6, "PS", "polystyrene cups"]]
## Fair tests: [what is tested, a fair test, unfair ones].
const FAIR_CASES_DT: Array = [
	["Which paper bridge holds most coins?", "same gap and coins; only the shape changes",
		["a bigger gap for one bridge", "different coins for each", "one bridge tested for longer"]],
	["Which glue is strongest?", "same card and amount; only the glue changes",
		["more glue on one", "different card for each", "one tested a day later"]],
	["Which wheel size makes the buggy roll furthest?", "same ramp and buggy; only the wheels change",
		["a steeper ramp for one", "a push for one buggy", "a heavier load on one"]],
	["Which bag handle is most comfortable?", "same bag and load; only the handle changes",
		["a heavier load in one bag", "a different tester for each", "one tested for longer"]],
]
const PROTOTYPE_CASES: Array = [
	["You want to try five quick ideas for a phone stand's shape.", "card models", ["a finished metal stand",
		"a 3D print of each, finished and painted", "a full advert"]],
	["You need exact sizes before making a mould.", "a CAD model", ["a paper sketch only", "a clay blob", "a poster"]],
	["You want to check a toy's gears really turn.", "a working prototype", ["a drawing", "a name for it",
		"a box for it"]],
	["You want users to try how a game's menu feels.", "a clickable screen prototype", ["a wooden model",
		"a printed poster", "a sculpture"]],
]
const NEXT_STEPS: Array = [
	["The bag's handle cut into the tester's hand.", "make the handle wider, then test again",
		["give up on bags", "change everything at once", "tell the tester to use the other hand"]],
	["The bridge held 40 coins, but the target is 50.", "add a triangle frame, then retest",
		["say 40 is close enough", "use a smaller target", "paint it"]],
	["The lunch box leaks when tipped.", "add a seal round the lid, then test it again",
		["only carry it flat", "make it a new colour", "test a different box"]],
]

# --- Projects banks ----------------------------------------------------------------------------------------------------

## Ports by latitude (whole degrees north or south: negative is south) for straight north-south sailings.
const PORTS: Array = [["Lisbon", 39], ["the Canary Islands", 28], ["Cape Verde", 15], ["the Equator", 0], ["Recife", -8],
	["Plymouth", 50], ["Bordeaux", 45], ["Dakar", 15]]
const SHIPS: Array = [["a caravel", 5], ["a galleon", 4], ["a clipper", 12], ["a sailing yacht", 6], ["a treasure ship", 4]]


# --- Health and PE: invasion games, advanced (g7.health_pe.invasion_advanced) -------------------------------------

## Level 1: name a tactic from what it looks like; level 2: sort tactics into attacking and defending; level 3: the
## best choice in a game situation.
static func tactic_case(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var t: Array = TACTICS[rng.randi_range(0, TACTICS.size() - 1)]
			var same: Array = TACTICS.filter(func(x: Array) -> bool: return str(x[1]) == str(t[1]) and x[0] != t[0])
			K.shuffle(rng, same)
			ex = K.choice(rng, "%s Which tactic is this?" % t[2], str(t[0]), same.slice(0, 3).map(func(x: Array) -> String:
				return str(x[0])), "Picture it on a pitch: who moves, and where does the ball go?",
				"%s: %s" % [_cap(str(t[0])), _lower_first(str(t[2]))])
			ex.data = {"tactic": t[0]}
		2:
			var att: Array = TACTICS.filter(func(x: Array) -> bool: return str(x[1]) == "attacking")
			var def: Array = TACTICS.filter(func(x: Array) -> bool: return str(x[1]) == "defending")
			K.shuffle(rng, att)
			K.shuffle(rng, def)
			var k := rng.randi_range(2, 3)
			var items: Array = []
			for i in k:
				items.append([str(att[i][0]), "attacking"])
			for i in 5 - k:
				items.append([str(def[i][0]), "defending"])
			ex = _sort(rng, "Sort the tactics: attacking (with the ball) or defending (without it)?", ["attacking",
				"defending"], items, "Ask: does the team doing it have the ball, or want it back?",
				"Attacking: %s. Defending: %s." % [_and(_in_group(items, "attacking")), _and(_in_group(items, "defending"))])
			ex.data = {"items": items}
		_:
			var s: Array = SITUATIONS[rng.randi_range(0, SITUATIONS.size() - 1)]
			ex = K.choice(rng, str(s[0]), str(s[1]), s[2], "Think: where is the space, and who is free?",
				"Best: %s." % s[1])
			ex.data = {"situation": s[0]}
	return ex


## An overload on the pitch: level 1, how many more blue attackers than red defenders; level 2, whose overload it is;
## level 3, how many red players must recover to make it even.
static func overload(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a := rng.randi_range(2, 5)
	var d := rng.randi_range(1, a - 1) if level != 2 or rng.randf() < 0.5 else rng.randi_range(a, a + 1)
	if level == 2 and rng.randf() < 0.3:
		d = a
	var players: Array = []
	var spots: Array = [[3, 2], [4, 4], [3, 6], [5, 1], [5, 7], [6, 3], [6, 5], [7, 4], [8, 2], [8, 6], [2, 4], [4, 1]]
	K.shuffle(rng, spots)
	for i in a:
		players.append([int(spots[i][0]), int(spots[i][1]), "a", str(i + 1)])
	for j in d:
		var s: Array = spots[a + j]
		players.append([int(s[0]) + 2, int(s[1]), "d"])
	var pic := {"kind": "pitch", "cols": 12, "rows": 8, "players": players, "ball": 0}
	var ex: Dictionary
	match level:
		1:
			ex = K.number("Blue attack with %d players against %d red defenders. How many more attackers than defenders are there?" % [
				a, d], a - d, "Count each team, then find the difference.",
				"%d − %d = %d spare attacker%s: an overload for blue." % [a, d, a - d, "" if a - d == 1 else "s"], pic)
		2:
			var right := "even numbers" if a == d else ("an overload for blue" if a > d else "an overload for red")
			ex = K.choice(rng, "Blue have %d players here and red have %d. What is it?" % [a, d], right, ["an overload for blue",
				"an overload for red", "even numbers"].filter(func(x: String) -> bool: return x != right),
				"An overload means one team has more players in that part of the pitch.",
				"%d against %d: %s." % [a, d, right], pic)
		_:
			ex = K.number("Blue break forward with %d attackers against %d red defenders. How many red players must make a recovery run to make it even?" % [
				a, d], a - d, "Even means the same number on each side.",
				"%d − %d = %d red player%s must sprint back to get goal-side." % [a, d, a - d, "" if a - d == 1 else "s"])
	ex.data = {"attackers": a, "defenders": d}
	return ex


# --- Health and PE: racket sports (g7.health_pe.racket_sports) -----------------------------------------------------

## Badminton singles: level 1, the serving court for a score (even: right, odd: left); level 2, who serves and from
## where after a rally; level 3, whether a game is over (21, two clear, 30 at most).
static func serve_court(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var a_name := _who(rng)
	var b_name := _other(rng, a_name)
	var ex: Dictionary
	match level:
		1:
			var score := rng.randi_range(0, 20)
			var right := "the right service court" if score % 2 == 0 else "the left service court"
			ex = K.choice(rng, "In badminton singles, %s serves with a score of %d. Where does %s serve from?" % [a_name,
				score, a_name], right, ["the right service court", "the left service court", "the back of the court"].filter(
				func(x: String) -> bool: return x != right), "Is the server's score even or odd?",
				"%d is %s, so %s: even on the right, odd on the left." % [score, "even" if score % 2 == 0 else "odd", right])
			ex.data = {"score": score}
		2:
			var a := rng.randi_range(2, 19)
			var b := rng.randi_range(2, 19)
			var winner := a_name if rng.randf() < 0.5 else b_name
			var new_a := a + (1 if winner == a_name else 0)
			var new_b := b + (1 if winner == b_name else 0)
			var their := new_a if winner == a_name else new_b
			var side := "right" if their % 2 == 0 else "left"
			var right := "%s, from the %s" % [winner, side]
			var loser := b_name if winner == a_name else a_name
			var other_side := "left" if side == "right" else "right"
			ex = K.choice(rng, "The score is %s %d, %s %d. %s wins the next rally. Who serves next, and from which court?" % [
				a_name, a, b_name, b, winner], right, ["%s, from the %s" % [winner, other_side], "%s, from the %s" % [loser,
				side], "%s, from the %s" % [loser, other_side]],
				"The winner of a rally serves next. Then look at the server's new score: even or odd?",
				"%s wins, so %s serves with %d points: %s, so the %s court." % [winner, winner, their, "even" if their % 2
					== 0 else "odd", side])
			ex.data = {"a": a, "b": b, "winner_is_a": winner == a_name}
		_:
			var cases: Array = [[21, 19], [21, 20], [20, 19], [22, 20], [23, 22], [30, 29], [29, 28], [24, 22], [21, 15],
				[25, 24], [29, 29], [20, 20]]
			var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
			var flip := rng.randf() < 0.5
			var a: int = c[1] if flip else c[0]
			var b: int = c[0] if flip else c[1]
			var over := _badminton_over(a, b)
			var right := ("%s has won the game" % a_name) if over == 1 else (("%s has won the game" % b_name) if over == 2
				else "the game goes on")
			ex = K.choice(rng, "Badminton: %s %d, %s %d. Has the game ended?" % [a_name, a, b_name, b], right,
				["%s has won the game" % a_name, "%s has won the game" % b_name, "the game goes on"].filter(
				func(x: String) -> bool: return x != right),
				"A game is won at 21 with 2 points clear; at 29-all, the next point wins.",
				"%d-%d: %s. Win at 21 by two clear, or the first to 30." % [maxi(a, b), mini(a, b), right])
			ex.data = {"a": a, "b": b}
	return ex


## 1: the first name has won, 2: the second, 0: the game goes on.
static func _badminton_over(a: int, b: int) -> int:
	if a >= BADMINTON_CAP or (a >= BADMINTON_TO and a - b >= 2):
		return 1
	if b >= BADMINTON_CAP or (b >= BADMINTON_TO and b - a >= 2):
		return 2
	return 0


## Tennis points: level 1, the score call before deuce; level 2, deuce or advantage; level 3, whether a game is won.
static func tennis_score(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var s_name := _who(rng)
	var r_name := _other(rng, s_name)
	var a: int
	var b: int
	match level:
		1:
			a = rng.randi_range(0, 3)
			b = rng.randi_range(0, 3)
			if a == 3 and b == 3:
				b = rng.randi_range(0, 2)
		2:
			a = rng.randi_range(3, 6)
			b = clampi(a + rng.randi_range(-1, 1), 3, 7)
		_:
			a = rng.randi_range(2, 6)
			b = rng.randi_range(2, 6)
			if absi(a - b) > 2:
				b = a + (2 if b > a else -2)
			b = maxi(b, 0)
	var right := _tennis_call(a, b, s_name, r_name)
	var wrongs: Array = []
	for w: String in [_tennis_call(b, a, s_name, r_name), _tennis_call(a, maxi(b - 1, 0), s_name, r_name),
			_tennis_call(a + 1, b, s_name, r_name), "deuce", "advantage %s" % s_name, "game to %s" % r_name]:
		if w != right and not wrongs.has(w):
			wrongs.append(w)
	K.shuffle(rng, wrongs)
	var ex := K.choice(rng, "Tennis: %s has won %d point%s and %s has won %d in this game. What is the score called?" % [
		s_name, a, "" if a == 1 else "s", r_name, b], right, wrongs.slice(0, 3),
		"Points go love, 15, 30, 40. From 40-all, it is deuce, then advantage, then game.",
		"%d points to %d: %s." % [a, b, right])
	ex.data = {"server": a, "receiver": b}
	return ex


## The score's call: "30-15" (the server first), "15-all", "deuce", "advantage Bram", "game to Bram".
static func _tennis_call(a: int, b: int, s_name: String, r_name: String) -> String:
	if a >= 4 and a - b >= 2:
		return "game to %s" % s_name
	if b >= 4 and b - a >= 2:
		return "game to %s" % r_name
	if a >= 3 and b >= 3:
		if a == b:
			return "deuce"
		return "advantage %s" % (s_name if a > b else r_name)
	if a == b:
		return "%s-all" % TENNIS_CALLS[a]
	return "%s-%s" % [TENNIS_CALLS[a], TENNIS_CALLS[b]]


## Shots: level 1, find a shot's path on a picture; level 2, the shot for a situation; level 3, why that shot.
static func shot_choice(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var shots: Array = ["clear", "drop", "smash", "drive", "net"]
			K.shuffle(rng, shots)
			shots = shots.slice(0, 4)
			var k := rng.randi_range(0, 3)
			var name := str({"clear": "clear", "drop": "drop shot", "smash": "smash", "drive": "drive",
				"net": "net shot"}[shots[k]])
			ex = K.choice(rng, "Which path, A, B, C or D, is the %s?" % name, "path %s" % SHOT_LETTERS[k],
				["path A", "path B", "path C", "path D"].filter(func(x: String) -> bool: return x != "path %s" % SHOT_LETTERS[k]),
				"Clears fly high and deep, drops land just over the net, smashes go steeply down, drives stay flat.",
				"Path %s: %s." % [SHOT_LETTERS[k], _shot_why(str(shots[k]))],
				{"kind": "shot_paths", "sport": "badminton", "shots": shots, "tags": true})
			ex.data = {"shots": shots, "asked": k}
		2:
			var c: Array = SHOT_CASES[rng.randi_range(0, SHOT_CASES.size() - 1)]
			ex = K.choice(rng, "Badminton: %s Which shot is best?" % c[0], str(c[1]),
				["clear", "drop shot", "smash", "drive", "net shot"].filter(func(x: String) -> bool: return x != str(c[1])).slice(0, 3),
				"Where is your opponent, and where is the space?", "%s: %s." % [_cap(str(c[1])), c[2]])
			ex.data = {"case": c[0]}
		_:
			var c: Array = SHOT_CASES[rng.randi_range(0, SHOT_CASES.size() - 1)]
			var others: Array = SHOT_CASES.filter(func(x: Array) -> bool: return str(x[1]) != str(c[1])).map(
				func(x: Array) -> String: return str(x[2]))
			K.shuffle(rng, others)
			var uniq: Array = []
			for o: String in others:
				if not uniq.has(o):
					uniq.append(o)
			ex = K.choice(rng, "%s You play a %s. Why is it a good choice?" % [c[0], c[1]], str(c[2]), uniq.slice(0, 3),
				"Think about where the shot lands and how fast it flies.", "Because %s." % c[2])
			ex.data = {"case": c[0]}
	return ex


static func _shot_why(shot: String) -> String:
	match shot:
		"clear":
			return "it flies high and lands deep at the back"
		"drop":
			return "it falls just over the net"
		"smash":
			return "it goes steeply down, fast"
		"drive":
			return "it flies flat and fast, just over the net"
	return "it is tipped from near the net, just over it"


# --- Health and PE: your fitness plan (g7.health_pe.fitness_plan) ---------------------------------------------------

## The maximum heart rate (about 220 − age): level 1, the estimate; level 2, an edge of the aerobic zone (60% or 80%);
## level 3, how many beats wide the aerobic zone is.
static func max_hr(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var pool: Array = AGES if level == 1 else WHOLE_AGES
	var p: Array = pool[rng.randi_range(0, pool.size() - 1)]
	var age := int(p[0])
	var top := 220 - age
	var ex: Dictionary
	match level:
		1:
			ex = K.number("Estimate the maximum heart rate of %s, aged %d, in beats a minute." % [p[1], age], top,
				"Use the rough rule: 220 take away the age.", "220 − %d = %d beats a minute (an estimate)." % [age, top])
		2:
			var low := rng.randf() < 0.5
			var share := 0.6 if low else 0.8
			var v := roundi(top * share)
			ex = K.number("%s is %d, so their maximum heart rate is about %d. What is the %s end of their aerobic zone (%d%% of the maximum)?" % [
				_cap(str(p[1])), age, top, "low" if low else "high", int(share * 100)], v,
				"Find %d%%: divide by 10, then multiply by %d." % [int(share * 100), int(share * 10)],
				"%d ÷ 10 × %d = %d beats a minute." % [top, int(share * 10), v])
		_:
			var lo := roundi(top * 0.6)
			var hi := roundi(top * 0.8)
			ex = K.number("%s is %d. Their aerobic zone runs from 60%% to 80%% of %d. How many beats a minute wide is it?" % [
				_cap(str(p[1])), age, top], hi - lo, "Work out both ends, then subtract. Or find 20% of the maximum.",
				"60%% of %d is %d and 80%% is %d: %d − %d = %d (20%% of %d)." % [top, lo, hi, hi, lo, hi - lo, top])
	ex.data = {"age": age}
	return ex


## A pulse's zone: level 1 and 2, on a picture of the zones (level 2 with a session's trace); level 3, from an age and
## a pulse in words.
static func hr_zone(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var p: Array = WHOLE_AGES[rng.randi_range(0, 4)] if level < 3 else AGES[rng.randi_range(0, AGES.size() - 1)]
	var age := int(p[0])
	var top := 220 - age
	var zones: Array = ["rest", "warm-up", "aerobic", "anaerobic", "maximum"]
	var target := str(zones[rng.randi_range(1, 4)]) if level > 1 else str(zones[rng.randi_range(1, 3)])
	var lo := {"rest": 0.42, "warm-up": 0.51, "aerobic": 0.61, "anaerobic": 0.81, "maximum": 0.91}[target] as float
	var hi := {"rest": 0.49, "warm-up": 0.59, "aerobic": 0.79, "anaerobic": 0.89, "maximum": 0.98}[target] as float
	var bpm := rng.randi_range(ceili(top * lo), floori(top * hi))
	var right := _zone_choice(target)
	var wrongs: Array = []
	for z: String in zones.slice(1):
		if z != target:
			wrongs.append(_zone_choice(z))
	var ex: Dictionary
	match level:
		1:
			ex = K.choice(rng, "%s's maximum heart rate is about %d. A pulse of %d is in which zone?" % [_cap(str(p[1])), top,
				bpm],
				right, wrongs, "Find the pulse on the scale, and read the band it falls in.",
				"%d is %d%% of %d: %s." % [bpm, roundi(100.0 * bpm / top), top, right], {"kind": "hr_zones", "max": top})
		2:
			var labels: Array = ["rest", "warm", "game", "sprint", "cool"]
			var shares: Array = [0.4, 0.55, 0.7, 0.85, 0.5]
			var trace: Array = []
			for i in labels.size():
				trace.append([labels[i], roundi(top * float(shares[i]))])
			var point := rng.randi_range(1, 3)
			trace[point] = [labels[point], bpm]
			ex = K.choice(rng, "The graph shows a PE lesson. Which zone is the big orange point in?", right, wrongs,
				"Follow the orange point across to the zones' bands.",
				"%d beats a minute is %d%% of %d: %s." % [bpm, roundi(100.0 * bpm / top), top, right],
				{"kind": "hr_zones", "max": top, "trace": trace, "point": point})
			ex.data = {"age": age, "bpm": bpm, "point": point}
			return ex
		_:
			ex = K.choice(rng, "%s is %d. Their pulse is %d beats a minute. Which zone are they in?" % [_cap(str(p[1])), age,
				bpm], right, wrongs, "First find the maximum (220 − age), then the pulse's share of it.",
				"Maximum: 220 − %d = %d. %d is %d%% of %d: %s." % [age, top, bpm, roundi(100.0 * bpm / top), top, right])
	ex.data = {"age": age, "bpm": bpm}
	return ex


static func _zone_choice(z: String) -> String:
	return {"warm-up": "warm-up zone (50-60%)", "aerobic": "aerobic zone (60-80%)", "anaerobic": "anaerobic zone (80-90%)",
		"maximum": "maximum zone (90-100%)"}.get(z, z)


## A week of activity: level 1, the week's minutes; level 2, the average a day; level 3, a 10% increase.
static func week_minutes(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1:
			var acts := ACTIVITIES.duplicate()
			K.shuffle(rng, acts)
			var sessions: Array = []
			var total := 0
			for i in 4:
				var m := rng.randi_range(3, 12) * 5
				sessions.append([acts[i], m])
				total += m
			ex = K.number("%s's week: %s minutes. How many minutes in all?" % [who, _and(sessions.map(func(s: Array) -> String:
				return "%s %d" % [s[0], s[1]]))], total, "Add the minutes; tens first, then the fives.",
				"%s = %d minutes." % [" + ".join(sessions.map(func(s: Array) -> String: return str(s[1]))), total])
			ex.data = {"minutes": sessions.map(func(s: Array) -> int: return int(s[1]))}
		2:
			var avg := rng.randi_range(5, 13) * 5
			var total := avg * 7
			ex = K.number("%s was active for %d minutes this week. What is that on average a day?" % [who, total], avg,
				"A week has 7 days: share the total by 7.",
				"%d ÷ 7 = %d minutes a day, %s." % [total, avg, "60 or more: well done" if avg >= 60 else "under 60, so a little more each day helps"])
			ex.data = {"total": total}
		_:
			var start := rng.randi_range(2, 9) * 10
			var next := start + start / 10
			ex = K.number("%s runs for %d minutes a week now. Progression: add 10%% next week. How many minutes next week?" % [
				who, start], next, "10% is a tenth: divide by 10, then add it on.",
				"10%% of %d is %d, so %d + %d = %d minutes." % [start, start / 10, start, start / 10, next])
			ex.data = {"start": start}
	return ex


# --- Health and PE: dance styles (g7.health_pe.dance_styles) --------------------------------------------------------

## Counts: level 1, counts in some 8-count phrases; level 2, a phrase's seconds at a tempo; level 3, a canon's starts.
static func dance_counts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var n := rng.randi_range(2, 8)
			ex = K.number("A routine has %d phrases of 8 counts. How many counts is that?" % n, n * 8,
				"Each phrase is 8 counts: multiply.", "%d × 8 = %d counts." % [n, n * 8])
			ex.data = {"phrases": n}
		2:
			var tempos: Array = [[60, 8], [80, 6], [96, 5], [120, 4], [160, 3], [240, 2]]
			var t: Array = tempos[rng.randi_range(0, tempos.size() - 1)]
			var phrases := rng.randi_range(1, 3)
			var secs := int(t[1]) * phrases
			ex = K.number("The music has %d beats a minute, one count a beat. How many seconds do %d phrase%s of 8 counts take?" % [
				t[0], phrases, "" if phrases == 1 else "s"], secs,
				"A minute is 60 seconds: how long do 8 beats take at this speed?",
				"8 × 60 ÷ %d = %d s a phrase; × %d = %d s." % [t[0], int(t[1]), phrases, secs])
			ex.data = {"tempo": t[0], "phrases": phrases}
		_:
			var gap := rng.randi_range(1, 4)
			var dancers := rng.randi_range(3, 5)
			var start := 1 + gap * (dancers - 1)
			ex = K.number("In a canon, %d dancers do the same moves, each starting %d count%s after the one before. The first starts on count 1. On which count does the last start?" % [
				dancers, gap, "" if gap == 1 else "s"], start, "Count the gaps between the first and the last dancer.",
				"%d dancers have %d gaps: 1 + %d × %d = count %d." % [dancers, dancers - 1, dancers - 1, gap, start])
			ex.data = {"gap": gap, "dancers": dancers}
	return ex


## Styles: level 1, a move's style; level 2, sort moves into styles; level 3, where a dance comes from.
static func dance_style(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var m: Array = DANCE_MOVES[rng.randi_range(0, DANCE_MOVES.size() - 1)]
			ex = K.choice(rng, "Which style of dance is this: %s?" % m[0], str(m[1]), DANCE_STYLES.filter(func(s: String) -> bool:
				return s != str(m[1])), "Street dance grew in cities, folk dance is passed down by a people, contemporary is free and expressive.",
				"%s: %s." % [_cap(str(m[1])), m[0]])
			ex.data = {"move": m[0]}
		2:
			var items: Array = []
			for s: String in DANCE_STYLES:
				var of: Array = DANCE_MOVES.filter(func(x: Array) -> bool: return str(x[1]) == s)
				K.shuffle(rng, of)
				items.append([str(of[0][0]), s])
				if items.size() < 5 and rng.randf() < 0.6:
					items.append([str(of[1][0]), s])
			ex = _sort(rng, "Sort the moves into their dance styles.", DANCE_STYLES, items,
				"Ask where each move comes from: a city's streets, a people's tradition, or the theatre.",
				_sorted_words(DANCE_STYLES, items))
			ex.data = {"items": items}
		_:
			var f: Array = DANCE_FACTS[rng.randi_range(0, DANCE_FACTS.size() - 1)]
			ex = K.choice(rng, str(f[0]), str(f[1]), f[2], "Think of the style's story: where and when did it start?",
				"%s %s." % [str(f[0]).trim_suffix("…"), f[1]])
			ex.data = {"fact": f[0]}
	return ex


# --- Health and PE: leading and officiating (g7.health_pe.lead_and_officiate) ---------------------------------------

## Level 1, a signal in a picture; level 2, the decision for what happened; level 3, a fair official, captain or coach.
static func ref_call(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var signals: Array = ["advantage", "direct", "indirect", "penalty"]
			var s := str(signals[rng.randi_range(0, signals.size() - 1)])
			var names := {"advantage": "advantage: play on", "direct": "a direct free kick",
				"indirect": "an indirect free kick", "penalty": "a penalty kick"}
			ex = K.choice(rng, "What is the referee signalling?", str(names[s]), signals.filter(func(x: String) -> bool:
				return x != s).map(func(x: String) -> String: return str(names[x])),
				"Both arms forward, one arm pointing, an arm straight up, or pointing at the spot?",
				"It means %s." % SIGNAL_MEANING[s], {"kind": "ref_signal", "signal": s})
			ex.data = {"signal": s}
		2:
			var c: Array = REF_CASES[rng.randi_range(0, REF_CASES.size() - 1)]
			ex = K.choice(rng, "%s What should the referee give?" % c[0], str(c[1]), c[2],
				"Think about where it happened and whether stopping play helps the fouled team.", "%s." % _cap(str(c[1])))
			ex.data = {"case": c[0]}
		_:
			var c: Array = FAIR_CASES[rng.randi_range(0, FAIR_CASES.size() - 1)]
			ex = K.choice(rng, "%s What is the fair thing to do?" % c[0], str(c[1]), c[2],
				"A good leader is fair to everyone, calm and encouraging.", "%s: fair, calm and kind." % _cap(str(c[1])))
			ex.data = {"case": c[0]}
	return ex


## A tournament: level 1, a knockout's matches (n − 1); level 2, a round robin's (n(n − 1) ÷ 2); level 3, how long a
## round robin takes on some courts.
static func tournament(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var n := [4, 8, 16, 32][rng.randi_range(0, 3)] as int
			ex = K.number("A knockout has %d teams. Each match knocks one team out. How many matches until there is a winner?" % n,
				n - 1, "Every team but the winner must lose once.", "%d teams, %d must be knocked out: %d − 1 = %d matches." % [
					n, n - 1, n, n - 1])
			ex.data = {"teams": n}
		2:
			var n := rng.randi_range(3, 8)
			ex = K.number("In a round robin, every team plays every other team once. How many matches are there with %d teams?" % n,
				n * (n - 1) / 2, "Each team plays all the others; then halve, because each match has two teams.",
				"%d × %d ÷ 2 = %d matches." % [n, n - 1, n * (n - 1) / 2])
			ex.data = {"teams": n}
		_:
			var cases: Array = [[4, 10, 2], [5, 8, 2], [6, 10, 3], [6, 8, 2], [5, 12, 2], [7, 10, 3], [8, 5, 4], [8, 6, 2],
				[6, 12, 3], [4, 15, 2]]
			var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
			var n := int(c[0])
			var matches := n * (n - 1) / 2
			var rounds := ceili(float(matches) / int(c[2]))
			var mins := rounds * int(c[1])
			ex = K.number("A round robin has %d teams. Each match takes %d minutes and %d courts are free. How many minutes does it take at least?" % [
				n, c[1], c[2]], mins, "Find the matches, then how many rounds the courts need, then the time.",
				"%d × %d ÷ 2 = %d matches; %d courts need %d rounds; %d × %d = %d minutes." % [n, n - 1, matches, c[2], rounds,
					rounds, c[1], mins])
			ex.data = {"teams": n, "minutes": c[1], "courts": c[2]}
	return ex


# --- Health and PE: sleep for teenagers (g7.health_pe.teen_sleep) --------------------------------------------------

## Level 1, the hours on a sleep dial; level 2, the latest time to be asleep for 9 hours; level 3, a week's sleep debt.
static func sleep_hours(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1:
			var sleep := rng.randi_range(42, 47) * 30   # 21:00 to 23:30
			var wake := rng.randi_range(12, 16) * 30    # 06:00 to 08:00
			var h := float(wake + 1440 - sleep) / 60.0
			ex = K.number("%s falls asleep at %s and wakes at %s. How many hours of sleep is that?" % [who, _clock(sleep),
				_clock(wake)], _num_text(h), "Count to midnight, then add the hours after it.",
				"%s to midnight is %s h, and midnight to %s is %s h: %s hours." % [_clock(sleep), _num_text((1440.0 - sleep) / 60.0),
					_clock(wake), _num_text(wake / 60.0), _num_text(h)],
				{"kind": "sleep_dial", "sleep": _clock(sleep), "wake": _clock(wake), "hide": true})
			ex.data = {"sleep": sleep, "wake": wake}
		2:
			var wake := rng.randi_range(12, 16) * 30
			var need := [9, 9, 10, 8][rng.randi_range(0, 3)] as int
			var asleep := (wake - need * 60 + 1440) % 1440
			var wrongs: Array = [_clock((asleep + 60) % 1440), _clock((asleep + 30) % 1440), _clock((asleep + 1380) % 1440)]
			ex = K.choice(rng, "%s wakes at %s for school and needs %d hours of sleep. By when should %s be asleep?" % [who,
				_clock(wake), need, who], _clock(asleep), wrongs, "Count back the hours from the time you wake.",
				"%s back %d hours is %s." % [_clock(wake), need, _clock(asleep)])
			ex.data = {"wake": wake, "need": need}
		_:
			var short := rng.randi_range(1, 4) * 30
			var nights := 5
			var got := 9 * 60 - short
			var debt := short * nights
			ex = K.number("%s needs 9 hours a night but sleeps %s hours on each of %d school nights. How much sleep is missed in the week, in hours?" % [
				who, _num_text(got / 60.0), nights], _num_text(debt / 60.0),
				"Find the sleep missed each night, then multiply by the nights.",
				"9 − %s = %s h a night; × %d = %s hours missed. A sleep debt: earlier nights pay it back." % [
					_num_text(got / 60.0), _num_text(short / 60.0), nights, _num_text(debt / 60.0)])
			ex.data = {"short": short, "nights": nights}
	return ex


## Level 1, true or false about sleep; level 2, sort what helps or harms sleep; level 3, the best change for a story.
static func sleep_habit(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var f: Array = SLEEP_FACTS[rng.randi_range(0, SLEEP_FACTS.size() - 1)]
			ex = K.truefalse(str(f[1]), bool(f[0]), "Think about the body clock, melatonin and how much teenagers need.",
				("True. " if bool(f[0]) else "False. ") + _sleep_why(str(f[1])))
			ex.data = {"fact": f[1]}
		2:
			var helps := SLEEP_HELPS.duplicate()
			var harms := SLEEP_HARMS.duplicate()
			K.shuffle(rng, helps)
			K.shuffle(rng, harms)
			var k := rng.randi_range(2, 3)
			var items: Array = []
			for i in k:
				items.append([helps[i], "helps sleep"])
			for i in 5 - k:
				items.append([harms[i], "harms sleep"])
			ex = _sort(rng, "Sort them: does each help or harm a teenager's sleep?", ["helps sleep", "harms sleep"], items,
				"Ask: does it calm the body and brain for the night, or wake them up?",
				"Helps: %s. Harms: %s." % [_and(_in_group(items, "helps sleep")), _and(_in_group(items, "harms sleep"))])
			ex.data = {"items": items}
		_:
			var harm := str(SLEEP_HARMS[rng.randi_range(0, SLEEP_HARMS.size() - 1)])
			var fix := {"an energy drink in the evening": "water instead, and no caffeine after lunch",
				"a phone in bed": "charge the phone outside the bedroom",
				"a late lie-in every weekend": "get up within an hour of your school-day time",
				"a bright screen at midnight": "screens off an hour before bed",
				"games just before bed": "games earlier, then a calm hour before bed",
				"a busy, noisy room": "a dark, quiet, cool room"}[harm] as String
			var wrongs: Array = ["stay up later to get tired", "drink cola to relax", "sleep with the TV on"]
			ex = K.choice(rng, "Tilly's sleep is short because of %s. What is the best change?" % harm, fix, wrongs,
				"Choose the change that helps the body clock and the brain wind down.", "Best: %s." % fix)
			ex.data = {"harm": harm}
	return ex


static func _sleep_why(fact: String) -> String:
	if fact.contains("less sleep"):
		return "Teenagers need 8 to 10 hours: growing and learning take lots of sleep."
	if fact.contains("help you fall asleep"):
		return "Screens' bright light holds back melatonin, so sleep comes later."
	if fact.contains("fixes"):
		return "Long lie-ins shift the body clock later; steady times work better."
	if fact.contains("no effect"):
		return "Bright light, blue above all, tells the body clock it is still day."
	return "It is what sleep doctors and the NHS say."


# --- Health and PE: what influences your choices (g7.health_pe.health_influences) ------------------------------------

## Level 1, the trick circled on an advert; level 2, the trick in an advert's line; level 3, the question to ask.
static func advert_trick(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var ids: Array = ["star", "bandwagon", "free_gift", "health_claim", "small_print", "ad_label"]
			K.shuffle(rng, ids)
			var tricks: Array = ids.slice(0, 4)
			var t := str(tricks[rng.randi_range(0, 3)])
			var names := {"star": "a famous person", "bandwagon": "bandwagon", "free_gift": "a free gift",
				"health_claim": "a health claim", "small_print": "small print", "ad_label": "a '#ad' label"}
			var product := ["drink", "trainers", "cereal"][rng.randi_range(0, 2)] as String
			ex = K.choice(rng, "Which trick is circled in orange?", str(names[t]), tricks.filter(func(x: String) -> bool:
				return x != t).map(func(x: String) -> String: return str(names[x])),
				"Read the words in the circle: who or what is trying to persuade you?",
				"It is %s: %s." % [names[t], _trick_why(t)], {"kind": "advert", "product": product, "tricks": tricks, "mark": t})
			ex.data = {"trick": t}
		2:
			var l: Array = ADVERT_LINES[rng.randi_range(0, ADVERT_LINES.size() - 1)]
			ex = K.choice(rng, "%s Which trick is this?" % l[0], str(l[1]), ADVERT_TRICKS.filter(func(x: String) -> bool:
				return x != str(l[1])).slice(0, 3), "Ask what the advert wants you to think or feel.",
				"%s: %s." % [_cap(str(l[1])), _trick_why(str(ADVERT_TRICK_IDS.get(str(l[1]), "ad_label")))])
			ex.data = {"line": l[0]}
		_:
			var c: Array = ADVERT_CHECKS[rng.randi_range(0, ADVERT_CHECKS.size() - 1)]
			ex = K.choice(rng, "%s Which question helps you most?" % c[0], str(c[1]), c[2],
				"Look past the trick: what is the advert not telling you?", "Ask: %s" % c[1])
			ex.data = {"claim": c[0]}
	return ex


static func _trick_why(t: String) -> String:
	match t:
		"star":
			return "a star makes you think you will be like them"
		"bandwagon":
			return "it says everyone has it, so you feel left out without it"
		"free_gift":
			return "the gift gets you to buy the product"
		"health_claim":
			return "one healthy word hides what else is in it"
		"small_print":
			return "the rules are hidden in tiny letters"
	return "someone was paid to show it, and '#ad' must say so"


## Level 1, the influence in a story; level 2, sort healthy and unhealthy pulls; level 3, the steps of a good decision.
static func influence_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = INFLUENCES[rng.randi_range(0, INFLUENCES.size() - 1)]
			var others: Array = INFLUENCE_KINDS.filter(func(x: String) -> bool: return x != str(c[1]))
			K.shuffle(rng, others)
			ex = K.choice(rng, "%s What is influencing the choice?" % c[0], str(c[1]), others.slice(0, 3),
				"Who or what in the story is pulling on the choice?", "%s: %s" % [_cap(str(c[1])), _lower_first(str(c[0]))])
			ex.data = {"story": c[0]}
		2:
			var good := HEALTHY_PULL.duplicate()
			var bad := UNHEALTHY_PULL.duplicate()
			K.shuffle(rng, good)
			K.shuffle(rng, bad)
			var k := rng.randi_range(2, 3)
			var items: Array = []
			for i in k:
				items.append([good[i], "healthy"])
			for i in 5 - k:
				items.append([bad[i], "unhealthy"])
			ex = _sort(rng, "Influences can pull either way. Sort them.", ["healthy", "unhealthy"], items,
				"Would it help your body and mind, or put them at risk?",
				"Healthy: %s. Unhealthy: %s." % [_and(_in_group(items, "healthy")), _and(_in_group(items, "unhealthy"))])
			ex.data = {"items": items}
		_:
			ex = K.order(rng, "Put the steps of a good decision in order.", ["stop and notice the choice",
				"think of the options", "think of what each could lead to", "choose, and say why", "look back: did it work?"],
				"Notice first, think before you choose, and learn after.",
				"Stop, think of options and where each leads, choose, then look back.")
			ex.data = {}
	return ex


# --- Health and PE: self-image and media (g7.health_pe.self_image) -------------------------------------------------

## Level 1, how many edits are tagged on a photo; level 2, which edit a tag shows; level 3, true or false about edited
## images.
static func edit_signs(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var edits: Array = ["light", "filter", "smooth", "eyes", "teeth", "background"]
	K.shuffle(rng, edits)
	var ex: Dictionary
	match level:
		1:
			var n := rng.randi_range(2, 5)
			var used := edits.slice(0, n)
			ex = K.number("Each numbered circle shows one change made to the photo. How many changes were made?", n,
				"Compare the two photos, and count the circles.", "%d changes: %s." % [n, _and(used.map(func(e: String) -> String:
					return str(SchoolPictureG7Life.EDIT_NAMES[e])))],
				{"kind": "photo_edit", "edits": used, "tags": true})
			ex.data = {"edits": used}
		2:
			var n := rng.randi_range(3, 4)
			var used := edits.slice(0, n)
			var k := rng.randi_range(0, n - 1)
			var right := str(SchoolPictureG7Life.EDIT_NAMES[used[k]])
			var wrongs: Array = edits.filter(func(e: String) -> bool: return e != str(used[k])).map(func(e: String) -> String:
				return str(SchoolPictureG7Life.EDIT_NAMES[e]))
			K.shuffle(rng, wrongs)
			ex = K.choice(rng, "Compare the photos. What changed at circle %d?" % (k + 1), right, wrongs.slice(0, 3),
				"Look at the same place on both photos.", "Circle %d: %s." % [k + 1, right],
				{"kind": "photo_edit", "edits": used, "tags": true})
			ex.data = {"edits": used, "asked": k}
		_:
			var f: Array = EDIT_FACTS[rng.randi_range(0, EDIT_FACTS.size() - 1)]
			ex = K.truefalse(str(f[1]), bool(f[0]), "Think about filters, editing apps and what people choose to post.",
				("True. " if bool(f[0]) else "False. ") + ("Photos are often edited, and you rarely see the whole story."
					if bool(f[0]) else "Many photos are edited or chosen from many, and most do not say so."))
			ex.data = {"fact": f[1]}
	return ex


## Level 1, the kinder way to say an unkind thought; level 2, sort kind and unkind self-talk; level 3, what helps
## when a feed makes you feel bad.
static func kind_thought(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var t: Array = THOUGHTS[rng.randi_range(0, THOUGHTS.size() - 1)]
			var wrongs: Array = UNKIND_EXTRA.duplicate()
			ex = K.choice(rng, "Zara thinks, '%s' What would a kind friend say instead?" % t[0], str(t[1]), wrongs,
				"Talk to yourself the way you would talk to a good friend.", "'%s' It is true and kind." % t[1])
			ex.data = {"thought": t[0]}
		2:
			var ts := THOUGHTS.duplicate()
			K.shuffle(rng, ts)
			var items: Array = []
			var k := rng.randi_range(2, 3)
			for i in k:
				items.append([str(ts[i][1]), "kind"])
			for i in range(k, 5):
				items.append([str(ts[i][0]), "unkind"])
			ex = _sort(rng, "Sort the self-talk: kind or unkind?", ["kind", "unkind"], items,
				"Would you say it to a friend you care about?",
				"Kind: %s Unkind: %s" % [" ".join(_in_group(items, "kind")), " ".join(_in_group(items, "unkind"))])
			ex.data = {"items": items}
		_:
			var right := ["take a break and unfollow upsetting accounts",
				"talk to a trusted adult about how you feel"][rng.randi_range(0, 1)] as String
			ex = K.choice(rng, "Scrolling through edited photos makes Mimi feel bad about herself. What could help?", right,
				["scroll for longer to find better photos", "edit her own photos more", "keep the feeling a secret"],
				"Choose what protects how she feels, not what feeds the comparison.", "Best: %s." % right)
			ex.data = {}
	return ex


# --- Health and PE: drugs, risks and the law (g7.health_pe.drugs_and_the_law) ---------------------------------------

## Facts about drugs, their risks (levels 1 and 2) and the UK's law (level 3), as true or false.
static func drug_facts(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var facts: Array = DRUG_FACTS.filter(func(f: Array) -> bool: return int(f[0]) == level)
	var f: Array = facts[rng.randi_range(0, facts.size() - 1)]
	var ex := K.truefalse(str(f[2]), bool(f[1]), "Think about what drugs do to the body and mind, and what the law says.",
		("True. " if bool(f[1]) else "False. ") + _drug_why(str(f[2])))
	ex.data = {"fact": f[2]}
	return ex


static func _drug_why(fact: String) -> String:
	if fact.contains("prescribed for a friend"):
		return "A prescription is for one person only: it could harm someone else."
	if fact.contains("made safely"):
		return "Nobody checks them: their strength and what is in them are unknown."
	if fact.contains("legal for adults"):
		return "Alcohol and tobacco are legal for adults, and they still harm health."
	if fact.contains("lose your friends"):
		return "Real friends respect a no, and most young people say no too."
	if fact.contains("only for yourself"):
		return "Having an illegal drug, even for yourself, is possession: a crime."
	if fact.contains("Only adults"):
		return "Anyone can call FRANK, free and in confidence."
	return "It is what the NHS, FRANK or the law say."


## Level 1, who to turn to; level 2, the steps when someone is very unwell; level 3, the clearest way to say no.
static func drug_help(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = DRUG_HELP[rng.randi_range(0, DRUG_HELP.size() - 1)]
			ex = K.choice(rng, "%s What is the best thing to do?" % c[0], str(c[1]), c[2],
				"Choose what keeps everyone safe and gets the right help.", "Best: %s." % c[1])
			ex.data = {"worry": c[0]}
		2:
			ex = K.order(rng, "Someone is very unwell after taking something. Put the steps in order.", EMERGENCY_STEPS,
				"Safety first, then help on the way, then care until it comes.",
				"Check it is safe, call 999, the recovery position if they are breathing, stay with them, tell the paramedics.")
			ex.data = {}
		_:
			var offer := str(OFFERS[rng.randi_range(0, OFFERS.size() - 1)])
			var good := str(SAY_NO[rng.randi_range(0, SAY_NO.size() - 1)])
			var weak := WEAK_NO.duplicate()
			K.shuffle(rng, weak)
			ex = K.choice(rng, "Someone offers you %s and says it's fun. Which answer says no most clearly?" % offer, good,
				weak.slice(0, 3), "A clear no is short and firm; a reason or another idea helps.",
				"'%s' Then move away, and tell a trusted adult." % good)
			ex.data = {"offer": offer}
	return ex


# --- Health and PE: resolving conflicts (g7.health_pe.resolve_conflict) -------------------------------------------

## Level 1, the I-statement; level 2, the win-win; level 3, which moves calm a conflict and which make it worse.
static func i_statement(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = I_CASES[rng.randi_range(0, I_CASES.size() - 1)]
			ex = K.choice(rng, "%s Which is an I-statement?" % c[0], str(c[1]), c[2],
				"An I-statement says how I feel, when, and why: no blame.", "'%s' It shares the feeling without blaming." % c[1])
			ex.data = {"case": c[0]}
		2:
			var c: Array = WIN_CASES[rng.randi_range(0, WIN_CASES.size() - 1)]
			ex = K.choice(rng, "%s Which is a win-win?" % c[0], str(c[1]), c[2],
				"A win-win gives both people something they want.", "%s: both get something they want." % _cap(str(c[1])))
			ex.data = {"case": c[0]}
		_:
			var calm := CALM_MOVES.duplicate()
			var heat := HEAT_MOVES.duplicate()
			K.shuffle(rng, calm)
			K.shuffle(rng, heat)
			var k := rng.randi_range(2, 3)
			var items: Array = []
			for i in k:
				items.append([calm[i], "calms it down"])
			for i in 5 - k:
				items.append([heat[i], "makes it worse"])
			ex = _sort(rng, "Sort the moves in a quarrel.", ["calms it down", "makes it worse"], items,
				"Does it lower the heat, or add to it?",
				"Calms it: %s. Worse: %s." % [_and(_in_group(items, "calms it down")), _and(_in_group(items, "makes it worse"))])
			ex.data = {"items": items}
	return ex


## Level 1, the first step; level 2, the steps in order; level 3, when to get a trusted adult.
static func conflict_move(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			ex = K.choice(rng, "Two friends are shouting at each other. What should come first?", "stop and calm down",
				["decide who is right", "tell everyone else", "think of a punishment"],
				"Nobody can listen or think well when they are angry.", "Stop and calm down first: breathe, or take a break.")
			ex.data = {}
		2:
			var steps := CONFLICT_STEPS.duplicate()
			var start := rng.randi_range(0, 1)
			ex = K.order(rng, "Put the steps for sorting out a conflict in order.", steps.slice(start, start + 4),
				"Calm, talk, listen, solve: in that order.", "%s." % _cap(", then ".join(PackedStringArray(steps.slice(start,
					start + 4)))))
			ex.data = {"start": start}
		_:
			var cases: Array = [["Someone keeps picking on a classmate every day.", true],
				["Someone threatens to hurt you after school.", true], ["A quarrel online turns into lots of people being cruel.", true],
				["Two friends disagree about which film to watch.", false], ["You and a friend both want to go first in a game.", false]]
			var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
			ex = K.truefalse("%s This needs a trusted adult's help." % c[0], bool(c[1]),
				"Is anyone being bullied or in danger, or is it an everyday disagreement?",
				"True: bullying or danger always needs an adult." if bool(c[1]) else "False: you can sort this out together, calmly.")
			ex.data = {"case": c[0]}
	return ex


# --- Health and PE: where to get help (g7.health_pe.where_to_get_help) ----------------------------------------------

## Level 1 and 2, the right help for a need (level 2 with harder ones); level 3, true or false about getting help.
static func help_service(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	if level < 3:
		var pool: Array = HELP_CASES.slice(0, 3) if level == 1 else HELP_CASES.slice(2)
		var c: Array = pool[rng.randi_range(0, pool.size() - 1)]
		ex = K.choice(rng, "%s Who should you contact?" % c[0], str(c[1]), c[2],
			"Is someone in danger now? Is it urgent but not an emergency? Is it a worry to talk through?",
			"%s: %s." % [_cap(str(c[1])), _service_why(str(c[1]))])
		ex.data = {"need": c[0]}
	else:
		var f: Array = HELP_FACTS[rng.randi_range(0, HELP_FACTS.size() - 1)]
		ex = K.truefalse(str(f[1]), bool(f[0]), "Think about what helplines and trusted adults are for.",
			("True. " if bool(f[0]) else "False. ") + ("Help is there for big and small worries." if bool(f[0])
				else "Any worry is worth sharing, and emergencies need 999."))
		ex.data = {"fact": f[1]}
	return ex


# --- Design and technology: product analysis (g7.design_tech.product_analysis) ------------------------------------

## A torch's parts: level 1, why a part's material; level 2, match parts to materials; level 3, how a part was made.
static func part_material(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var p: Array = TORCH_MATERIALS[rng.randi_range(0, TORCH_MATERIALS.size() - 1)]
			var others: Array = TORCH_MATERIALS.filter(func(x: Array) -> bool: return x[0] != p[0]).map(func(x: Array) -> String:
				return str(x[2]))
			K.shuffle(rng, others)
			ex = K.choice(rng, "A torch's %s is made of %s. Why?" % [p[0], p[1]], str(p[2]), others.slice(0, 3),
				"Think about what that part has to do.", "%s: %s." % [_cap(str(p[1])), p[2]])
			ex.data = {"part": p[0]}
		2:
			var ps := TORCH_MATERIALS.duplicate()
			K.shuffle(rng, ps)
			ps = ps.slice(0, 4)
			ex = _match(rng, "Match each torch part to its material.", ps.map(func(x: Array) -> String: return str(x[0])),
				ps.map(func(x: Array) -> String: return str(x[1])), "What does each part do: hold, shine, spring or conduct?",
				"; ".join(PackedStringArray(ps.map(func(x: Array) -> String: return "%s: %s" % [x[0], x[1]]))) + ".")
			ex.data = {"parts": ps.map(func(x: Array) -> String: return str(x[0]))}
		_:
			var p: Array = PROCESSES[rng.randi_range(0, PROCESSES.size() - 1)]
			ex = K.choice(rng, "How is %s usually made?" % p[0], str(p[1]), PROCESS_NAMES.filter(func(x: String) -> bool:
				return x != str(p[1])), "Is it plastic or metal, a sheet or a solid shape?",
				"%s: %s." % [_cap(str(p[1])), _process_why(str(p[1]))])
			ex.data = {"part": p[0]}
	return ex


## Level 1, the scale of production; level 2, sort products by scale; level 3, a part's cost with its mould.
static func production_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = SCALE_CASES[rng.randi_range(0, SCALE_CASES.size() - 1)]
			ex = K.choice(rng, "Which scale of production is %s?" % c[0], str(c[1]), SCALES.filter(func(x: String) -> bool:
				return x != str(c[1])), "One made once, a set number together, or huge numbers non-stop?",
				"%s: %s." % [_cap(str(c[1])), c[0]])
			ex.data = {"case": c[0]}
		2:
			var items: Array = []
			var used := {}
			for s: String in SCALES:
				var of: Array = SCALE_CASES.filter(func(x: Array) -> bool: return str(x[1]) == s)
				var pick: Array = of[rng.randi_range(0, of.size() - 1)]
				items.append([str(pick[0]), s])
				used[str(pick[0])] = true
			var rest: Array = SCALE_CASES.filter(func(x: Array) -> bool: return not used.has(str(x[0])))
			var extra: Array = rest[rng.randi_range(0, rest.size() - 1)]
			items.append([str(extra[0]), str(extra[1])])
			ex = _sort(rng, "Sort them by scale of production.", SCALES, items,
				"How many are made: one, a set number, or millions?",
				_sorted_words(SCALES, items))
			ex.data = {"items": items}
		_:
			var mould := [2000, 5000, 10000, 20000][rng.randi_range(0, 3)] as int
			var each := rng.randi_range(1, 3)
			var n := [1000, 2000, 5000, 10000][rng.randi_range(0, 3)] as int
			var total := mould + each * n
			var cost := float(total) / n
			ex = K.number("A mould costs %s gold, then each case costs %d gold to make. What does each case cost when %s are made?" % [
				K.fmt(mould), each, K.fmt(n)], _num_text(cost), "Add the mould to the making cost of them all, then share by how many.",
				"%s + %d × %s = %s gold; ÷ %s = %s gold each. More made, cheaper each." % [K.fmt(mould), each, K.fmt(n),
					K.fmt(total), K.fmt(n), _num_text(cost)])
			ex.data = {"mould": mould, "each": each, "count": n}
	return ex


# --- Design and technology: from screen to object (g7.design_tech.cad_cam) ------------------------------------------

## Level 1, a 3D print's layers; level 2, its printing time; level 3, a laser cut's length and time.
static func print_layers(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var lh: Array = LAYER_HEIGHTS[rng.randi_range(0, LAYER_HEIGHTS.size() - 1)]
	var layer := float(lh[0])
	var ex: Dictionary
	match level:
		1:
			var layers := rng.randi_range(4, 30) * 10
			var height := layers * layer
			ex = K.number("A 3D printer prints layers %s mm thick. How many layers make a model %s mm tall?" % [lh[1],
				_num_text(height)], layers, "Divide the height by one layer's thickness.",
				"%s ÷ %s = %d layers." % [_num_text(height), lh[1], layers],
				{"kind": "cam_process", "machine": "printer", "layers": 6})
			ex.data = {"layer": layer, "height": height}
		2:
			var layers := rng.randi_range(5, 30) * 10
			var secs := [6, 12, 15, 30, 60][rng.randi_range(0, 4)] as int
			var total := layers * secs
			ex = K.number("A print has %d layers, and each takes %d seconds. How many minutes does it take?" % [layers, secs],
				_num_text(total / 60.0), "Find the seconds for all the layers, then divide by 60.",
				"%d × %d = %s s; ÷ 60 = %s minutes." % [layers, secs, K.fmt(total), _num_text(total / 60.0)])
			ex.data = {"layers": layers, "seconds": secs}
		_:
			var w := rng.randi_range(3, 12) * 10
			var h := rng.randi_range(2, 8) * 10
			var speed := [5, 10, 20][rng.randi_range(0, 2)] as int
			var length := 2 * (w + h)
			ex = K.number("A laser cuts round a rectangle %d mm by %d mm at %d mm a second. How many seconds does the cut take?" % [
				w, h, speed], _num_text(float(length) / speed), "The cut goes all the way round: find the perimeter first.",
				"2 × (%d + %d) = %d mm; ÷ %d = %s seconds." % [w, h, length, speed, _num_text(float(length) / speed)])
			ex.data = {"w": w, "h": h, "speed": speed}
	return ex


## Level 1, additive or subtractive; level 2, the machine for a job; level 3, the width a laser's cuts burn away.
static func make_method(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = MAKE_CASES[rng.randi_range(0, MAKE_CASES.size() - 1)]
			ex = K.choice(rng, "%s Is that additive or subtractive making?" % c[0], str(c[1]), ["additive", "subtractive"].filter(
				func(x: String) -> bool: return x != str(c[1])), "Does it add material bit by bit, or take material away?",
				"%s: it %s material." % [_cap(str(c[1])), "adds" if str(c[1]) == "additive" else "takes away"])
			ex.data = {"case": c[0]}
		2:
			var c: Array = MACHINE_CASES[rng.randi_range(0, MACHINE_CASES.size() - 1)]
			ex = K.choice(rng, "Which machine suits %s?" % c[0], str(c[1]), MACHINE_NAMES.filter(func(x: String) -> bool:
				return x != str(c[1])), "Flat sheet, a hollow 3D shape, or carved from a thick block?",
				"%s: %s." % [_cap(str(c[1])), _machine_why(str(c[1]))])
			ex.data = {"case": c[0]}
		_:
			var pieces := rng.randi_range(3, 9)
			var kerf := [1, 2, 3][rng.randi_range(0, 2)] as int   # tenths of a mm
			var cuts := pieces - 1
			ex = K.number("The laser burns away a line 0.%d mm wide (the kerf). A strip is cut into %d pieces with straight cuts across. How many mm are burned away?" % [
				kerf, pieces], _num_text(cuts * kerf / 10.0), "How many cuts make that many pieces? One fewer than the pieces.",
				"%d pieces need %d cuts; %d × 0.%d = %s mm." % [pieces, cuts, cuts, kerf, _num_text(cuts * kerf / 10.0)])
			ex.data = {"pieces": pieces, "kerf": kerf}
	return ex


static func _service_why(help: String) -> String:
	if help.begins_with("999"):
		return "someone is in danger right now"
	if help == "111":
		return "urgent health help that is not an emergency"
	if help.contains("Childline"):
		return "free and private, for any worry"
	if help.contains("CEOP"):
		return "for worries about someone online"
	return "for a crime that is not happening now"


static func _process_why(process: String) -> String:
	match process:
		"injection moulding":
			return "melted plastic is forced into a mould"
		"vacuum forming":
			return "a warm plastic sheet is sucked over a shape"
		"pressing (stamping)":
			return "a press cuts and bends sheet metal"
	return "molten metal is poured into a mould"


static func _machine_why(m: String) -> String:
	match m:
		"a laser cutter":
			return "it cuts and engraves flat sheets"
		"a 3D printer":
			return "it builds 3D shapes layer by layer, even hollow ones"
	return "its spinning cutter carves shapes out of thick blocks"


# --- Design and technology: electronic circuits (g7.design_tech.electronic_circuits) ------------------------------

## A resistor's bands: levels 1 and 2, its value from the picture (named, then by colour); level 3, the bands for a
## value.
static func resistor_code(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var first := rng.randi_range(1, 9)
	var second := rng.randi_range(0, 9)
	var zeros := rng.randi_range(0, 3)
	var bands: Array = [DIGIT_COLOURS[first], DIGIT_COLOURS[second], DIGIT_COLOURS[zeros], "gold"]
	var value := (first * 10 + second) * int(pow(10, zeros))
	var ex: Dictionary
	if level < 3:
		ex = K.number("What is this resistor's value in ohms? (The gold band is its tolerance.)", value,
			"Bands 1 and 2 are digits; band 3 says how many zeros to add.",
			"%s = %d, %s = %d, %s = %d zero%s: %s ohms." % [bands[0], first, bands[1], second, bands[2], zeros, "" if zeros == 1
				else "s", K.fmt(value)], {"kind": "resistor", "bands": bands, "names": level == 1})
	else:
		var right := "%s, %s, %s" % [bands[0], bands[1], bands[2]]
		var wrongs: Array = []
		for w: String in ["%s, %s, %s" % [bands[1], bands[0], bands[2]], "%s, %s, %s" % [bands[0], bands[1],
				DIGIT_COLOURS[(zeros + 1) % 4]], "%s, %s, %s" % [DIGIT_COLOURS[(first % 9) + 1], bands[1], bands[2]]]:
			if w != right and not wrongs.has(w):
				wrongs.append(w)
		ex = K.choice(rng, "Which first three bands make %s ohms?" % K.fmt(value), right, wrongs,
			"Write the value as two digits and a number of zeros.",
			"%s = %d%d and %d zero%s: %s." % [K.fmt(value), first, second, zeros, "" if zeros == 1 else "s", right])
	ex.data = {"bands": bands}
	return ex


## An LED's resistor: level 1, the volts across it; level 2, its ohms, (supply − LED) ÷ current; level 3, the
## standard value to use (the next one up in the E12 series).
static func led_resistor(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var c: Array = LED_CASES[rng.randi_range(0, LED_CASES.size() - 1)]
	var vs := int(c[0])
	var vf := int(c[1])
	var ma := int(c[2])
	var r := (vs - vf) * 1000 / ma
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A %d V battery lights an LED that needs %d V. How many volts are left across its resistor?" % [vs, vf],
				vs - vf, "The battery's volts are shared round the loop.", "%d − %d = %d V across the resistor." % [vs, vf,
					vs - vf], {"kind": "schematic", "parts": ["closed", "resistor", "led", "battery"], "lit": true,
					"values": ["", "?", "%d V" % vf, "%d V" % vs]})
		2:
			ex = K.number("A %d V supply, an LED that needs %d V and %d mA. What resistor does it need, in ohms?" % [vs, vf, ma],
				r, "Volts left ÷ current in amps: %d mA is %s A." % [ma, _num_text(ma / 1000.0)],
				"(%d − %d) ÷ %s = %d ÷ %s = %s ohms." % [vs, vf, _num_text(ma / 1000.0), vs - vf, _num_text(ma / 1000.0), K.fmt(r)])
		_:
			var std := _e12_up(r)
			var below := _e12_below(r)
			var wrongs: Array = []
			for w: int in [below, _e12_up(std + 1), std * 10]:
				if w != std and not wrongs.has(w) and w > 0:
					wrongs.append(w)
			ex = K.choice(rng, "The sum says %s ohms. Resistors come in standard values. Which should you use?" % K.fmt(r),
				"%s ohms" % K.fmt(std), wrongs.map(func(w: int) -> String: return "%s ohms" % K.fmt(w)),
				"Choose the nearest standard value that is not smaller: a smaller one lets more current through.",
				"%s ohms: the next standard value up from %s keeps the current safe." % [K.fmt(std), K.fmt(r)])
	ex.data = {"supply": vs, "led": vf, "ma": ma}
	return ex


## The smallest E12 value (10, 12, 15 … 82 × a power of ten) that is at least `r`.
static func _e12_up(r: int) -> int:
	var scale := 1
	for _k in 8:
		for v: int in E12:
			if v * scale >= r:
				return v * scale
		scale *= 10
	return r


## The largest E12 value below `r`.
static func _e12_below(r: int) -> int:
	var best := 0
	var scale := 1
	while 10 * scale < r * 10:
		for v: int in E12:
			if v * scale < r:
				best = v * scale
		scale *= 10
	return best


## Level 1, whether a circuit's LED or buzzer works; level 2, the input for an alarm; level 3, why a circuit is built
## the way it is.
static func alarm_logic(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var cases: Array = [[["closed", "resistor", "led", "battery"], false], [["switch", "resistor", "led", "battery"],
				false], [["closed", "led_back", "resistor", "battery"], false], [["pad", "buzzer", "cell"], true],
				[["pad", "buzzer", "cell"], false], [["push", "resistor", "led", "battery"], true],
				[["tilt", "buzzer", "battery"], true], [["reed", "buzzer", "battery"], false]]
			var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
			var parts: Array = c[0]
			var active := bool(c[1])
			var works := SchoolPictureG7Life.conducts(parts, active)
			var out := "buzzer" if parts.has("buzzer") else "LED"
			var says := {true: "is pressed", false: "is not pressed"}
			var how := ""
			for s: Variant in parts:
				if SchoolPictureG7Life.SENSING.has(str(s)):
					how = " The %s %s." % [SchoolPictureG7Life.SYM_NAMES[str(s)], {"push": says[active], "pad": says[active],
						"reed": "has its magnet near" if active else "has no magnet near", "tilt": "is tipped" if active
						else "is level"}[str(s)]]
			ex = K.truefalse("Look at the circuit.%s The %s works." % [how, out], works,
				"Follow the loop from the battery: is there a gap, or an LED the wrong way round?",
				("True: the loop is complete." if works else "False: %s." % _why_not(parts, active)),
				{"kind": "schematic", "parts": parts, "active": active, "names": true})
			ex.data = {"parts": parts, "active": active}
		2:
			var c: Array = ALARM_INPUTS[rng.randi_range(0, ALARM_INPUTS.size() - 1)]
			var others: Array = ALARM_INPUTS.filter(func(x: Array) -> bool: return x[0] != c[0]).map(func(x: Array) -> String:
				return str(x[1]))
			K.shuffle(rng, others)
			ex = K.choice(rng, "An alarm must notice %s. Which input should it use?" % c[0], str(c[1]), others.slice(0, 3),
				"What changes: a magnet moves, a foot presses, it tips, or the light fades?", "%s." % _cap(str(c[1])))
			ex.data = {"job": c[0]}
		_:
			var c: Array = ALARM_WHY[rng.randi_range(0, ALARM_WHY.size() - 1)]
			ex = K.choice(rng, str(c[0]), str(c[1]), c[2], "Think about current, heat and testing safely.", "%s." % _cap(str(c[1])))
			ex.data = {"question": c[0]}
	return ex


static func _why_not(parts: Array, active: bool) -> String:
	if parts.has("switch"):
		return "the switch is open, so there is a gap"
	if parts.has("led_back"):
		return "the LED is the wrong way round, so it blocks the current"
	for s: Variant in parts:
		if SchoolPictureG7Life.SENSING.has(str(s)) and not active:
			return "the %s is still open" % SchoolPictureG7Life.SYM_NAMES[str(s)]
	return "the loop is broken"


# --- Design and technology: microcontrollers (g7.design_tech.microcontrollers) ------------------------------------

## The board's LEDs: level 1, which LED is lit (x, y); level 2, the board a plot() shows; level 3, how many LEDs a loop
## lights.
static func led_xy(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var x := rng.randi_range(0, 4)
	var y := rng.randi_range(0, 4)
	var ex: Dictionary
	match level:
		1:
			var right := "x = %d, y = %d" % [x, y]
			var wrongs: Array = []
			for w: String in ["x = %d, y = %d" % [y, x], "x = %d, y = %d" % [(x + 1) % 5, y], "x = %d, y = %d" % [x, (y + 2) % 5]]:
				if w != right and not wrongs.has(w):
					wrongs.append(w)
			ex = K.choice(rng, "Which LED is lit? x counts across from 0, y counts down from 0.", right, wrongs,
				"Count the columns from the left for x, then the rows from the top for y.", "%s." % _cap(right),
				{"kind": "micro_board", "leds": _leds([[x, y]]), "grid": true})
		2:
			var pts: Array = [[x, y], [y, x], [(x + 2) % 5, y], [x, (y + 3) % 5]]
			var uniq: Array = []
			for p: Array in pts:
				if not uniq.has(p):
					uniq.append(p)
			var choices: Array = uniq.map(func(p: Array) -> Dictionary: return {"picture": {"kind": "micro_board",
				"leds": _leds([p]), "grid": true}})
			ex = K.choice(rng, "Which board shows plot(%d, %d)?" % [x, y], choices[0], choices.slice(1),
				"plot(x, y): x across from the left, y down from the top, both from 0.",
				"Column %d from the left, row %d from the top." % [x, y])
		_:
			var n := rng.randi_range(2, 5)
			var row := rng.randi_range(0, 4)
			var lines: Array = ["for x in range(%d):" % n, "    plot(x, %d)" % row]
			var both := rng.randf() < 0.5
			if both:
				lines.append("plot(%d, %d)" % [rng.randi_range(0, 4), (row + 2) % 5])
			var lit := n + (1 if both else 0)
			ex = K.number("How many LEDs does this program light?", lit, "range(n) counts 0, 1, … up to n − 1: n times.",
				"The loop plots %d LEDs in row %d%s: %d in all." % [n, row, ", then one more" if both else "", lit],
				{"kind": "text_code", "lines": lines})
	ex.data = {"x": x, "y": y}
	return ex


static func _leds(points: Array) -> Array:
	var rows: Array = []
	for yy in 5:
		var s := ""
		for xx in 5:
			s += "1" if points.has([xx, yy]) else "0"
		rows.append(s)
	return rows


## Pauses and counts: level 1, a pause in ms as seconds; level 2, how long a loop takes; level 3, a counter after
## button presses.
static func pause_time(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var ms := rng.randi_range(1, 12) * 500
			ex = K.number("A program says pause(%s). How many seconds is that?" % K.fmt(ms), _num_text(ms / 1000.0),
				"There are 1,000 milliseconds in a second.", "%s ÷ 1,000 = %s seconds." % [K.fmt(ms), _num_text(ms / 1000.0)],
				{"kind": "text_code", "lines": ["show(HEART)", "pause(%d)" % ms, "clear()"]})
			ex.data = {"ms": ms}
		2:
			var times := rng.randi_range(2, 6)
			var on := rng.randi_range(1, 4) * 250
			var off := rng.randi_range(1, 4) * 250
			var total := times * (on + off)
			ex = K.number("How many seconds does this program take to run?", _num_text(total / 1000.0),
				"Add the pauses inside the loop, then multiply by the times it repeats.",
				"%d + %d = %s ms a time; × %d = %s ms = %s s." % [on, off, K.fmt(on + off), times, K.fmt(total), _num_text(total
					/ 1000.0)], {"kind": "text_code", "lines": ["for i in range(%d):" % times, "    show(HEART)",
					"    pause(%d)" % on, "    clear()", "    pause(%d)" % off]})
			ex.data = {"times": times, "on": on, "off": off}
		_:
			var presses: Array = []
			for i in rng.randi_range(4, 7):
				presses.append("A" if rng.randf() < 0.7 else "B")
			var count := 0
			for p: String in presses:
				count = count + 1 if p == "A" else 0
			ex = K.number("Button A adds 1 to count; button B sets count back to 0. Bram presses %s. What is count now?" % _and(
				presses), count, "Follow the presses one by one, writing count down each time.",
				"Count after each press: %s. It ends at %d." % [", ".join(PackedStringArray(_counts(presses))), count])
			ex.data = {"presses": presses}
	return ex


static func _counts(presses: Array) -> Array:
	var out: Array = []
	var c := 0
	for p: String in presses:
		c = c + 1 if p == "A" else 0
		out.append(str(c))
	return out


## Decisions on a sensor: level 1, light below a threshold; level 2, temperature above one; level 3, two at once.
static func micro_if(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var threshold := rng.randi_range(4, 12) * 10
			var reading := clampi(threshold + rng.randi_range(-4, 4) * 10, 0, 255)
			if reading == threshold:
				reading += 10
			var on := reading < threshold
			ex = K.truefalse("The light level reads %d. The night light comes on." % reading, on,
				"The LED turns on only when the light level is below the number.",
				"%s: %d is %s %d." % ["True" if on else "False", reading, "below" if on else "not below", threshold],
				{"kind": "text_code", "lines": ["while True:", "    if light_level() < %d:" % threshold, "        led_on()",
					"    else:", "        led_off()"]})
			ex.data = {"threshold": threshold, "reading": reading}
		2:
			var t := rng.randi_range(22, 30)
			var reading := t + rng.randi_range(-3, 3)
			if reading == t:
				reading += 1
			var on := reading > t
			ex = K.truefalse("The temperature reads %d °C. The fan comes on." % reading, on,
				"The fan turns on only when the temperature is above the number.",
				"%s: %d is %s %d." % ["True" if on else "False", reading, "above" if on else "not above", t],
				{"kind": "text_code", "lines": ["while True:", "    if temperature() > %d:" % t, "        fan_on()",
					"    else:", "        fan_off()"]})
			ex.data = {"limit": t, "reading": reading}
		_:
			var dark := rng.randf() < 0.5
			var moving := rng.randf() < 0.5
			var use_and := rng.randf() < 0.5
			var on := (dark and moving) if use_and else (dark or moving)
			var op := "and" if use_and else "or"
			ex = K.truefalse("It is %s, and someone %s. The porch light comes on." % ["dark" if dark else "light",
				"is moving nearby" if moving else "is not moving"], on,
				"'and' needs both to be true; 'or' needs at least one.",
				"%s: dark is %s and moving is %s, so '%s' is %s." % ["True" if on else "False", str(dark).to_lower(),
					str(moving).to_lower(), op, str(on).to_lower()],
				{"kind": "text_code", "lines": ["if is_dark() %s moving():" % op, "    light_on()"]})
			ex.data = {"dark": dark, "moving": moving, "and": use_and}
	return ex


# --- Design and technology: technical textiles (g7.design_tech.smart_textiles) ------------------------------------

## Level 1, the fabric for a use; level 2, match uses to fabrics; level 3, how a breathable membrane works.
static func fabric_for(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = FABRIC_CASES[rng.randi_range(0, FABRIC_CASES.size() - 1)]
			ex = K.choice(rng, "Which fabric suits %s?" % c[0], str(c[1]), c[2], "What must the fabric do for the person?",
				"%s: it does the job the person needs." % _cap(str(c[1])))
			ex.data = {"use": c[0]}
		2:
			var cs := FABRIC_CASES.duplicate()
			K.shuffle(rng, cs)
			cs = cs.slice(0, 4)
			var short := {"a waterproof, breathable fabric": "waterproof breathable", "reflective strips": "reflective strips",
				"fluorescent colours": "fluorescent colours", "fire-resistant aramid fibres": "fire-resistant fibres",
				"a smart fabric with sensors": "smart fabric", "elastane": "elastane", "fleece that traps air": "fleece"}
			var uses := {"a walking jacket for rainy hills": "a rain jacket", "a cyclist's vest for dark evenings": "a night vest",
				"a cyclist's top for dull days": "a day cycling top", "a firefighter's suit": "a firefighter's suit",
				"a top that tracks your heart rate": "a heart-rate top", "a swimsuit that stretches and springs back": "a swimsuit",
				"a winter hat that keeps heat in": "a winter hat"}
			ex = _match(rng, "Match each item to the fabric it needs.", cs.map(func(x: Array) -> String: return str(uses[x[0]])),
				cs.map(func(x: Array) -> String: return str(short[x[1]])), "What must each item do: stay dry, be seen, stretch, protect?",
				"; ".join(PackedStringArray(cs.map(func(x: Array) -> String: return "%s: %s" % [uses[x[0]], short[x[1]]]))) + ".")
			ex.data = {"uses": cs.map(func(x: Array) -> String: return str(x[0]))}
		_:
			var qs: Array = [
				["Why does rain stay out of a breathable membrane?", "its holes are smaller than a raindrop",
					["it is sticky", "rain bounces off all fabric", "it is thick like a carpet"]],
				["Why can sweat still get out through it?", "water vapour is far smaller than the holes",
					["sweat is a solid", "the jacket has a fan", "the holes open when wet"]],
				["Why are a jacket's seams taped?", "rain could get in through the stitch holes",
					["to make it heavier", "for decoration", "so it stretches"]],
				["How does a reflective strip shine in headlights?", "glass beads send the light back to the driver",
					["it makes its own light", "it is painted white", "it gets hot"]],
			]
			var q: Array = qs[rng.randi_range(0, qs.size() - 1)]
			ex = K.choice(rng, str(q[0]), str(q[1]), q[2], "Think about sizes: a raindrop, water vapour and the tiny holes.",
				"Because %s." % q[1], {"kind": "fabric_section", "type": "breathable" if not str(q[0]).contains("reflective")
					else "reflective"})
			ex.data = {"question": q[0]}
	return ex


## Level 1, sort natural and synthetic fibres; level 2, smart or technical; level 3, fluorescent by day or reflective
## at night.
static func fibre_kind(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var nat := NATURAL_FIBRES.duplicate()
			var syn := SYNTHETIC_FIBRES.duplicate()
			K.shuffle(rng, nat)
			K.shuffle(rng, syn)
			var k := rng.randi_range(2, 3)
			var items: Array = []
			for i in k:
				items.append([nat[i], "natural"])
			for i in 5 - k:
				items.append([syn[i], "synthetic"])
			ex = _sort(rng, "Sort the fibres: natural or synthetic (made from oil)?", ["natural", "synthetic"], items,
				"Does it come from a plant or an animal, or from a factory?",
				"Natural: %s. Synthetic: %s." % [_and(_in_group(items, "natural")), _and(_in_group(items, "synthetic"))])
			ex.data = {"items": items}
		2:
			var c: Array = SMART_OR_TECH[rng.randi_range(0, SMART_OR_TECH.size() - 1)]
			ex = K.choice(rng, "Is %s a smart textile or a technical textile?" % c[0], str(c[1]), ["smart", "technical"].filter(
				func(x: String) -> bool: return x != str(c[1])), "Smart textiles sense or change; technical ones are built to perform.",
				"%s: %s." % [_cap(str(c[1])), "it senses or reacts to something" if str(c[1]) == "smart"
					else "it is made to do a hard job well"])
			ex.data = {"case": c[0]}
		_:
			var night := rng.randf() < 0.5
			var right := "reflective strips" if night else "fluorescent colours"
			ex = K.choice(rng, "Zara cycles home %s. What helps drivers see her most?" % ("after dark" if night
				else "on a grey afternoon"), right, ["reflective strips", "fluorescent colours", "a dark coat"].filter(
				func(x: String) -> bool: return x != right), "Fluorescent colours glow in daylight; reflective strips need a light shone on them.",
				"%s: %s." % [_cap(right), "they send headlights' light back" if night else "they glow brightly in daylight"])
			ex.data = {"night": night}
	return ex


# --- Design and technology: food of the world (g7.design_tech.world_cooking) --------------------------------------

## Scaling a recipe: level 1, for 2 or 3 times as many; level 2, from 4 people to 6 or 10; level 3, for any number.
static func recipe_scale(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var foods: Array = [["rice", 75], ["lentils", 50], ["flour", 100], ["pasta", 80], ["couscous", 60]]
	var f: Array = foods[rng.randi_range(0, foods.size() - 1)]
	var per := int(f[1])
	var ex: Dictionary
	match level:
		1:
			var k := rng.randi_range(2, 3)
			ex = K.number("A recipe for 4 uses %d g of %s. How many grams for %d people?" % [per * 4, f[0], 4 * k], per * 4 * k,
				"How many times as many people? Multiply by that.", "%d people is %d times 4, so %d × %d = %d g." % [4 * k, k,
					per * 4, k, per * 4 * k])
			ex.data = {"per_four": per * 4, "people": 4 * k}
		2:
			var people := [6, 10, 2][rng.randi_range(0, 2)] as int
			ex = K.number("A recipe for 4 uses %d g of %s. How many grams for %d people?" % [per * 4, f[0], people], per * people,
				"Find the amount for 1 person first, then multiply.", "%d ÷ 4 = %d g a person; × %d = %d g." % [per * 4, per,
					people, per * people])
			ex.data = {"per_four": per * 4, "people": people}
		_:
			var base := [4, 5][rng.randi_range(0, 1)] as int
			var people := rng.randi_range(3, 9)
			if people == base:
				people += 1
			ex = K.number("A recipe for %d uses %d g of %s. How many grams for %d people?" % [base, per * base, f[0], people],
				per * people, "Share by the recipe's people to find one portion, then multiply.",
				"%d ÷ %d = %d g a person; × %d = %d g." % [per * base, base, per, people, per * people])
			ex.data = {"base": base, "amount": per * base, "people": people}
	return ex


## Level 1, where a dish comes from; level 2, match dishes and places; level 3, where a staple food grows best.
static func dish_place(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var d: Array = DISHES[rng.randi_range(0, DISHES.size() - 1)]
			var others: Array = DISHES.filter(func(x: Array) -> bool: return x[0] != d[0]).map(func(x: Array) -> String:
				return str(x[1]))
			K.shuffle(rng, others)
			ex = K.choice(rng, "Where does %s come from?" % d[0], str(d[1]), others.slice(0, 3),
				"Think of the dish's staple food and its spices.", "%s comes from %s." % [_cap(str(d[0])), d[1]])
			ex.data = {"dish": d[0]}
		2:
			var ds := DISHES.duplicate()
			K.shuffle(rng, ds)
			ds = ds.slice(0, 4)
			ex = _match(rng, "Match each dish to where it comes from.", ds.map(func(x: Array) -> String: return str(x[0])),
				ds.map(func(x: Array) -> String: return str(x[1])), "Which staples grow where: rice, wheat or maize?",
				"; ".join(PackedStringArray(ds.map(func(x: Array) -> String: return "%s: %s" % [x[0], x[1]]))) + ".")
			ex.data = {"dishes": ds.map(func(x: Array) -> String: return str(x[0]))}
		_:
			var s: Array = STAPLES[rng.randi_range(0, STAPLES.size() - 1)]
			var others: Array = STAPLES.filter(func(x: Array) -> bool: return x[0] != s[0]).map(func(x: Array) -> String:
				return str(x[1]))
			K.shuffle(rng, others)
			ex = K.choice(rng, "%s is a staple food. Which place suits it, or did it come from?" % _cap(str(s[0])), str(s[1]),
				others.slice(0, 3),
				"Each staple needs its own climate: warm and wet, cool and dry, or tropical.", "%s: %s." % [_cap(str(s[0])),
					s[1]])
			ex.data = {"staple": s[0]}
	return ex


# --- Design and technology: cooking with less waste (g7.design_tech.less_food_waste) -------------------------------

## Food wasted: level 1, a share as a percentage; level 2, gold wasted in a year; level 3, a percentage from kilograms.
static func waste_share(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var who := _who(rng)
	var ex: Dictionary
	match level:
		1:
			var whole := [10, 20, 25][rng.randi_range(0, 2)] as int
			var thrown := rng.randi_range(1, whole / 4)
			var pct := thrown * 100 / whole
			ex = K.number("%s's family throws away %d slices from a %d-slice loaf. What percentage is wasted?" % [who, thrown,
				whole], pct, "Make it a fraction of the loaf, then out of 100.",
				"%d/%d = %d/100 = %d%%." % [thrown, whole, pct, pct])
			ex.data = {"thrown": thrown, "whole": whole}
		2:
			var week := rng.randi_range(3, 12)
			ex = K.number("A family wastes food worth %d gold a week. How much is that in a year of 52 weeks?" % week, week * 52,
				"Multiply by 52: by 50, then add 2 lots.", "%d × 52 = %d × 50 + %d × 2 = %d gold." % [week, week, week, week * 52])
			ex.data = {"week": week}
		_:
			var bought := [20, 25, 40, 50][rng.randi_range(0, 3)] as int
			var wasted := rng.randi_range(1, bought / 5)
			while wasted * 100 % bought != 0:
				wasted += 1
			var pct := wasted * 100 / bought
			ex = K.number("Over a month, a family buys %d kg of food and throws away %d kg. What percentage is wasted?" % [bought,
				wasted], pct, "Wasted ÷ bought, then × 100.", "%d ÷ %d × 100 = %d%%." % [wasted, bought, pct])
			ex.data = {"bought": bought, "wasted": wasted}
	return ex


## Where food keeps: level 1, one food's place; level 2, sort foods by place; level 3, first in, first out by dates.
static func store_place(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = STORE_CASES[rng.randi_range(0, STORE_CASES.size() - 1)]
			ex = K.choice(rng, "Where should %s be kept?" % c[0], "the %s" % c[1], PLACES.filter(func(x: String) -> bool:
				return x != str(c[1])).map(func(x: String) -> String: return "the %s" % x),
				"Is it chilled, frozen or dry when you buy it?", "In the %s." % c[1])
			ex.data = {"food": c[0]}
		2:
			var items: Array = []
			for p: String in PLACES:
				var of: Array = STORE_CASES.filter(func(x: Array) -> bool: return str(x[1]) == p)
				K.shuffle(rng, of)
				items.append([str(of[0][0]), p])
				if rng.randf() < 0.5:
					items.append([str(of[1][0]), p])
			ex = _sort(rng, "Sort the shopping: fridge, freezer or cupboard?", PLACES, items,
				"Was it chilled, frozen or on a shelf in the shop?",
				_sorted_words(PLACES, items))
			ex.data = {"items": items}
		_:
			var food := str(FOODS_WITH_DATES[rng.randi_range(0, FOODS_WITH_DATES.size() - 1)])
			var days: Array = []
			while days.size() < 4:
				var d := rng.randi_range(3, 28)
				if not days.has(d):
					days.append(d)
			var sorted := days.duplicate()
			sorted.sort()
			ex = K.order(rng, "First in, first out: put the %s in the order to use them, first first." % food,
				sorted.map(func(d: int) -> String: return "use by %d June" % d), "The nearest date is used first.",
				"Earliest date first: %s." % _and(sorted.map(func(d: int) -> String: return "%d June" % d)))
			ex.data = {"days": days}
	return ex


# --- Design and technology: a product's life (g7.design_tech.product_life_cycle) ----------------------------------

## Level 1, the stage of a product's life; level 2, the stages in order; level 3, where most of a product's footprint
## comes from.
static func life_stage(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var c: Array = STAGE_CASES[rng.randi_range(0, STAGE_CASES.size() - 1)]
			var others: Array = STAGES.filter(func(x: String) -> bool: return x != str(c[1]))
			K.shuffle(rng, others)
			ex = K.choice(rng, "%s Which stage of the product's life is this?" % c[0], str(c[1]), others.slice(0, 3),
				"Is it getting materials, making, moving, using or getting rid of it?", "%s: the product is %s." % [
					_cap(str(c[1])), {"raw materials": "getting what it is made from", "manufacture": "being made",
					"transport": "being moved", "use": "being used", "end of life": "being got rid of"}[str(c[1])]])
			ex.data = {"case": c[0]}
		2:
			var start := rng.randi_range(0, 1)
			ex = K.order(rng, "Put a product's life in order.", STAGES.slice(start, start + 4),
				"From the ground to the factory, the shop, the home and beyond.",
				"%s." % _cap(", then ".join(PackedStringArray(STAGES.slice(start, start + 4)))))
			ex.data = {"start": start}
		_:
			var cases: Array = [["a smartphone", "manufacture", "making its chips and screen takes most of the energy"],
				["a washing machine", "use", "years of electricity and water add up to most of it"],
				["a petrol car", "use", "burning fuel for years makes most of its carbon"],
				["an aluminium can", "raw materials", "making new aluminium from ore takes the most energy"]]
			var c: Array = cases[rng.randi_range(0, cases.size() - 1)]
			ex = K.choice(rng, "For %s, which stage usually has the biggest carbon footprint?" % c[0], str(c[1]), STAGES.filter(
				func(x: String) -> bool: return x != str(c[1])).slice(0, 3),
				"Does it use energy every day for years, or take a lot to make?", "%s: %s." % [_cap(str(c[1])), c[2]])
			ex.data = {"product": c[0]}
	return ex


## The 6 Rs: level 1, which R a story shows; level 2, match the Rs to what they mean; level 3, plastics' codes.
static func six_rs(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var rs: Array = SIX_RS.map(func(x: Array) -> String: return str(x[0]))
	match level:
		1:
			var c: Array = SIX_R_CASES[rng.randi_range(0, SIX_R_CASES.size() - 1)]
			var others: Array = rs.filter(func(x: String) -> bool: return x != str(c[1]))
			K.shuffle(rng, others)
			ex = K.choice(rng, "%s Which of the 6 Rs is this?" % c[0], str(c[1]), others.slice(0, 3),
				"Rethink, refuse, reduce, reuse, repair, recycle: which fits?", "%s: %s." % [_cap(str(c[1])), _r_means(str(c[1]))])
			ex.data = {"case": c[0]}
		2:
			var ps := SIX_RS.duplicate()
			K.shuffle(rng, ps)
			ps = ps.slice(0, 4)
			ex = _match(rng, "Match each R to what it means.", ps.map(func(x: Array) -> String: return str(x[0])),
				ps.map(func(x: Array) -> String: return _short_r(str(x[0]))), "Say each word slowly: what does it ask you to do?",
				"; ".join(PackedStringArray(ps.map(func(x: Array) -> String: return "%s: %s" % [x[0], x[1]]))) + ".")
			ex.data = {"rs": ps.map(func(x: Array) -> String: return str(x[0]))}
		_:
			var p: Array = PLASTIC_CODES[rng.randi_range(0, PLASTIC_CODES.size() - 1)]
			var others: Array = PLASTIC_CODES.filter(func(x: Array) -> bool: return x[0] != p[0]).map(func(x: Array) -> String:
				return str(x[1]))
			ex = K.choice(rng, "Recycling code %d is on %s. Which plastic is it?" % [p[0], p[2]], str(p[1]), others.slice(0, 3),
				"Remember the common ones: 1 for drink bottles, 2 for milk bottles, 5 for tubs.",
				"Code %d is %s, used for %s." % [p[0], p[1], p[2]])
			ex.data = {"code": p[0]}
	return ex


static func _r_means(r: String) -> String:
	for x: Array in SIX_RS:
		if str(x[0]) == r:
			return str(x[1])
	return ""


static func _short_r(r: String) -> String:
	return {"rethink": "find a better way", "refuse": "say no if not needed", "reduce": "use less",
		"reuse": "use it again", "repair": "mend it", "recycle": "make it into new things"}[r]


# --- Design and technology: prototype and improve (g7.design_tech.prototype_improve) -------------------------------

## Tests' results: level 1, the mean of three; level 2, a percentage improvement; level 3, the mean once a slip is
## tested again.
static func test_mean(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var m := rng.randi_range(10, 60)
			var a := m + rng.randi_range(-4, 4)
			var b := m + rng.randi_range(-4, 4)
			var c := 3 * m - a - b
			ex = K.number("A bridge held %d, %d and %d coins in three tests. What is the mean?" % [a, b, c], m,
				"Add the three results, then share by 3.", "%d + %d + %d = %d; ÷ 3 = %d coins." % [a, b, c, 3 * m, m])
			ex.data = {"results": [a, b, c]}
		2:
			var before := [20, 25, 40, 50][rng.randi_range(0, 3)] as int
			var pct := [10, 20, 40, 50, 60][rng.randi_range(0, 4)] as int
			var after := before + before * pct / 100
			while before * pct % 100 != 0:
				pct += 10
				after = before + before * pct / 100
			ex = K.number("Prototype 1 held %d coins; prototype 2 holds %d. By what percentage did it improve?" % [before,
				after], pct, "Find the change, then compare it with the first result.",
				"%d − %d = %d; %d ÷ %d × 100 = %d%%." % [after, before, after - before, after - before, before, pct])
			ex.data = {"before": before, "after": after}
		_:
			var m := rng.randi_range(20, 50)
			var r: Array = [m + rng.randi_range(-3, 3), m + rng.randi_range(-3, 3), m + rng.randi_range(-3, 3)]
			var retest := 4 * m - int(r[0]) - int(r[1]) - int(r[2])
			var slip := rng.randi_range(3, 9)
			ex = K.number("Tests: %d, %d, %d and %d; the %d was a slip, so it was tested again and got %d. What is the mean of %d, %d, %d and %d?" % [
				r[0], r[1], slip, r[2], slip, retest, r[0], r[1], r[2], retest], m,
				"Leave out the slip and use the new result: add the four, then share by 4.",
				"%d + %d + %d + %d = %d; ÷ 4 = %d." % [r[0], r[1], r[2], retest, 4 * m, m])
			ex.data = {"results": [r[0], r[1], r[2], retest]}
	return ex


## Level 1, the fair test; level 2, the prototype for a job; level 3, what to do after a test.
static func fair_change(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var bank: Array = FAIR_CASES_DT if level == 1 else (PROTOTYPE_CASES if level == 2 else NEXT_STEPS)
	var c: Array = bank[rng.randi_range(0, bank.size() - 1)]
	var prompts := {1: "%s Which test is fair?", 2: "%s Which prototype fits best?", 3: "%s What is the best next step?"}
	var hints := {1: "A fair test changes only one thing and keeps everything else the same.",
		2: "Quick and cheap to try ideas; exact for sizes; working to test how it works.",
		3: "Change one thing that fixes the problem, then test again."}
	ex = K.choice(rng, str(prompts[level]) % c[0], str(c[1]), c[2], str(hints[level]), "%s." % _cap(str(c[1])))
	ex.data = {"case": c[0]}
	return ex


# --- Projects: a voyage of exploration (g7.projects.voyage) ---------------------------------------------------------

## Level 1, distance from speed and time; level 2, days at sea; level 3, nautical miles between two latitudes.
static func sea_distance(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var s: Array = SHIPS[rng.randi_range(0, SHIPS.size() - 1)]
	var knots := int(s[1])
	var ex: Dictionary
	match level:
		1:
			var hours := rng.randi_range(2, 24)
			ex = K.number("%s sails at %d knots (nautical miles an hour) for %d hours. How many nautical miles does it sail?" % [
				_cap(str(s[0])), knots, hours], knots * hours, "Distance = speed × time.",
				"%d × %d = %d nautical miles." % [knots, hours, knots * hours])
			ex.data = {"knots": knots, "hours": hours}
		2:
			var days := rng.randi_range(2, 15)
			var dist := knots * 24 * days
			ex = K.number("%s sails at %d knots, day and night. How many days does it take to sail %s nautical miles?" % [
				_cap(str(s[0])), knots, K.fmt(dist)], days, "Find the distance in one day first: 24 hours × the speed.",
				"%d × 24 = %d nautical miles a day; %s ÷ %d = %d days." % [knots, knots * 24, K.fmt(dist), knots * 24, days])
			ex.data = {"knots": knots, "distance": dist}
		_:
			var a: Array = PORTS[rng.randi_range(0, PORTS.size() - 1)]
			var b: Array = PORTS[rng.randi_range(0, PORTS.size() - 1)]
			while int(a[1]) == int(b[1]):
				b = PORTS[rng.randi_range(0, PORTS.size() - 1)]
			var diff := absi(int(a[1]) - int(b[1]))
			ex = K.number("%s is at latitude %s and %s at %s. Each degree of latitude is 60 nautical miles. How many nautical miles apart are they, north to south?" % [
				_cap(_port_lat(a)), _lat(int(a[1])), _port_lat(b), _lat(int(b[1]))], diff * 60,
				"Find how many degrees apart they are (across the Equator, add), then × 60.",
				"%d degrees apart; %d × 60 = %s nautical miles." % [diff, diff, K.fmt(diff * 60)])
			ex.data = {"from": a[1], "to": b[1]}
	return ex


static func _port_lat(p: Array) -> String:
	return str(p[0])


static func _lat(v: int) -> String:
	if v == 0:
		return "0°"
	return "%d°%s" % [absi(v), "N" if v > 0 else "S"]


## Supplies: level 1, water for the crew; level 2, with a spare fifth for storms; level 3, barrels needed.
static func voyage_supplies(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var crew := rng.randi_range(2, 6) * 5
	var days := rng.randi_range(2, 8) * 5
	var litres := 3
	var need := crew * days * litres
	var ex: Dictionary
	match level:
		1:
			ex = K.number("A crew of %d sails for %d days. Each sailor needs %d litres of water a day. How many litres?" % [crew,
				days, litres], need, "Multiply the sailors, the days and the litres.", "%d × %d × %d = %s litres." % [crew,
					days, litres, K.fmt(need)])
		2:
			var spare := need / 5
			ex = K.number("The crew needs %s litres of water. The plan adds a fifth more, for storms and delays. How many litres in all?" % K.fmt(need),
				need + spare, "Find a fifth (divide by 5), then add it.",
				"%s ÷ 5 = %s; %s + %s = %s litres." % [K.fmt(need), K.fmt(spare), K.fmt(need), K.fmt(spare), K.fmt(need + spare)])
		_:
			var barrel := [100, 150, 200, 250][rng.randi_range(0, 3)] as int
			var barrels := ceili(float(need) / barrel)
			ex = K.number("The voyage needs %s litres of water, in barrels of %d litres. How many barrels must go on board?" % [
				K.fmt(need), barrel], barrels, "Divide, and if anything is left over, it needs one more barrel.",
				"%s ÷ %d = %s, so %d barrels." % [K.fmt(need), barrel, _num_text(float(need) / barrel), barrels])
			ex.data = {"need": need, "barrel": barrel}
			return ex
	ex.data = {"crew": crew, "days": days}
	return ex


# --- Projects: an eco-district (g7.projects.eco_district) ------------------------------------------------------------

## Energy: level 1, watts saved by an LED; level 2, kWh from kW × hours; level 3, carbon from kWh (about 0.2 kg each).
static func energy_use(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var bulbs := rng.randi_range(2, 10)
			ex = K.number("An old 60 W bulb and an 8 W LED give the same light. How many watts are saved by changing %d bulbs?" % bulbs,
				52 * bulbs, "Find the saving for one bulb, then multiply.", "60 − 8 = 52 W a bulb; × %d = %d W." % [bulbs,
					52 * bulbs])
			ex.data = {"bulbs": bulbs}
		2:
			var kw := rng.randi_range(1, 4)
			var hours := rng.randi_range(2, 8)
			ex = K.number("A %d kW heater runs for %d hours. How many kWh of energy does it use?" % [kw, hours], kw * hours,
				"Energy in kWh = power in kW × time in hours.", "%d × %d = %d kWh." % [kw, hours, kw * hours])
			ex.data = {"kw": kw, "hours": hours}
		_:
			var kwh := rng.randi_range(2, 40) * 25
			ex = K.number("Making 1 kWh of electricity gives about 0.2 kg of carbon dioxide. How many kg does %s kWh give?" % K.fmt(kwh),
				_num_text(kwh * 0.2), "0.2 is a fifth: divide by 5.", "%s × 0.2 = %s ÷ 5 = %s kg." % [K.fmt(kwh), K.fmt(kwh),
					_num_text(kwh * 0.2)])
			ex.data = {"kwh": kwh}
	return ex


## Water: level 1, a shower's litres; level 2, litres saved by a shorter shower; level 3, rain collected from a roof
## (1 mm on 1 m² is 1 litre).
static func water_saving(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var rate := [8, 10, 12, 15][rng.randi_range(0, 3)] as int
			var mins := rng.randi_range(3, 12)
			ex = K.number("A shower uses %d litres a minute. How many litres does a %d-minute shower use?" % [rate, mins],
				rate * mins, "Litres a minute × minutes.", "%d × %d = %d litres." % [rate, mins, rate * mins])
			ex.data = {"rate": rate, "minutes": mins}
		2:
			var rate := [8, 10, 12][rng.randi_range(0, 2)] as int
			var before := rng.randi_range(8, 15)
			var after := rng.randi_range(3, 6)
			var people := rng.randi_range(2, 5)
			var saved := (before - after) * rate * people
			ex = K.number("%d people each cut their shower from %d to %d minutes. The shower uses %d litres a minute. How many litres are saved a day?" % [
				people, before, after, rate], saved, "Find the minutes saved, then × litres a minute, then × people.",
				"(%d − %d) × %d × %d = %d litres a day." % [before, after, rate, people, saved])
			ex.data = {"rate": rate, "before": before, "after": after, "people": people}
		_:
			var area := rng.randi_range(2, 12) * 5
			var mm := rng.randi_range(2, 25)
			ex = K.number("1 mm of rain on 1 m² of roof makes 1 litre. A roof of %d m² gets %d mm of rain. How many litres can the rain butts collect?" % [
				area, mm], area * mm, "Multiply the roof's area by the rain's depth in mm.",
				"%d × %d = %d litres." % [area, mm, area * mm])
			ex.data = {"area": area, "mm": mm}
	return ex


# --- Projects: a mini business (g7.projects.mini_business) -----------------------------------------------------------

## Prices: level 1, cost plus a markup; level 2, a discount; level 3, the profit on a batch.
static func markup_price(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	match level:
		1:
			var cost := rng.randi_range(1, 10) * 2
			var pct := [25, 50, 100][rng.randi_range(0, 2)] as int
			while cost * pct % 100 != 0:
				cost += 2
			var price := cost + cost * pct / 100
			ex = K.number("A bookmark costs %d gold to make. With a %d%% markup, what is its price?" % [cost, pct], price,
				"Find %d%% of the cost, then add it on." % pct, "%d%% of %d = %d; %d + %d = %d gold." % [pct, cost, cost * pct
					/ 100, cost, cost * pct / 100, price])
			ex.data = {"cost": cost, "pct": pct}
		2:
			var price := rng.randi_range(2, 12) * 5
			var off := [10, 20, 25, 50][rng.randi_range(0, 3)] as int
			while price * off % 100 != 0:
				price += 5
			var cut := price * off / 100
			ex = K.number("A key ring sells for %d gold. At the end of the day it is %d%% off. What is the new price?" % [price,
				off], price - cut, "Find the discount, then take it away from the original price.",
				"%d%% of %d = %d; %d − %d = %d gold." % [off, price, cut, price, cut, price - cut])
			ex.data = {"price": price, "off": off}
		_:
			var cost := rng.randi_range(1, 6)
			var price := cost + rng.randi_range(1, 6)
			var sold := rng.randi_range(2, 10) * 5
			ex = K.number("Each phone stand costs %d gold to make and sells for %d gold. How much profit do %d sales make?" % [cost,
				price, sold], (price - cost) * sold, "Find the profit on one, then multiply by the sales.",
				"%d − %d = %d gold each; × %d = %d gold." % [price, cost, price - cost, sold, (price - cost) * sold])
			ex.data = {"cost": cost, "price": price, "sold": sold}
	return ex


## A stall's results: level 1, takings; level 2, profit or loss with fixed costs; level 3, the break-even point.
static func profit_loss(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var ex: Dictionary
	var price := rng.randi_range(3, 9)
	var cost := rng.randi_range(1, price - 1)
	var fixed := rng.randi_range(2, 10) * 10
	match level:
		1:
			var sold := rng.randi_range(5, 40)
			ex = K.number("The stall sells %d bracelets at %d gold each. What are the takings?" % [sold, price], sold * price,
				"Takings = price × number sold.", "%d × %d = %d gold." % [price, sold, sold * price])
			ex.data = {"price": price, "sold": sold}
		2:
			var sold := rng.randi_range(5, 40)
			if sold * (price - cost) == fixed:
				sold += 1
			var result := sold * (price - cost) - fixed
			var right := ("a profit of %d gold" % result) if result > 0 else ("a loss of %d gold" % -result)
			var wrongs: Array = []
			for w: String in ["a profit of %d gold" % absi(result), "a loss of %d gold" % absi(result),
					"a profit of %d gold" % (sold * price), "no profit and no loss"]:
				if w != right and not wrongs.has(w):
					wrongs.append(w)
			ex = K.choice(rng, "The stall costs %d gold. Each bracelet costs %d to make and sells for %d. %d are sold. What is the result?" % [
				fixed, cost, price, sold], right, wrongs.slice(0, 3),
				"Takings minus all the costs: the stall and the bracelets.",
				"Takings %d × %d = %d; costs %d + %d × %d = %d; %d − %d: %s." % [sold, price, sold * price, fixed, sold, cost,
					fixed + sold * cost, sold * price, fixed + sold * cost, right])
			ex.data = {"price": price, "cost": cost, "fixed": fixed, "sold": sold}
		_:
			while fixed % (price - cost) != 0:
				fixed += 10
			var be := fixed / (price - cost)
			ex = K.number("The stall costs %d gold. Each bracelet costs %d to make and sells for %d. How many must be sold to break even?" % [
				fixed, cost, price], be, "Each sale pays off price − cost of the stall: divide the stall's cost by that.",
				"%d − %d = %d gold towards the stall each; %d ÷ %d = %d bracelets." % [price, cost, price - cost, fixed,
					price - cost, be], {"kind": "break_even", "fixed": fixed, "cost": cost, "price": price, "max": be * 2 + 2})
			ex.data = {"price": price, "cost": cost, "fixed": fixed}
	return ex


# --- Helpers ------------------------------------------------------------------------------------------------------

static func _who(rng: RandomNumberGenerator) -> String:
	return PEOPLE[rng.randi_range(0, PEOPLE.size() - 1)]


## Someone other than `who`.
static func _other(rng: RandomNumberGenerator, who: String) -> String:
	var others: Array = PEOPLE.filter(func(p: String) -> bool: return p != who)
	return str(others[rng.randi_range(0, others.size() - 1)])


## `s` with its first letter a capital.
static func _cap(s: String) -> String:
	return s.substr(0, 1).to_upper() + s.substr(1)


## `s` with its first letter small, unless it starts with a name.
static func _lower_first(s: String) -> String:
	var first := s.split(" ")[0].trim_suffix("'s")
	if PEOPLE.has(first) or first == "I":
		return s
	return s.substr(0, 1).to_lower() + s.substr(1)


## "a, b and c".
static func _and(items: Array) -> String:
	var words: Array = items.map(func(x: Variant) -> String: return str(x))
	if words.size() <= 1:
		return "".join(PackedStringArray(words))
	return ", ".join(PackedStringArray(words.slice(0, words.size() - 1))) + " and " + str(words[-1])


## Minutes after midnight as "HH:MM".
static func _clock(m: int) -> String:
	return "%02d:%02d" % [(m / 60) % 24, m % 60]


## A number without trailing zeros: 0.5, 1.25, 3.
static func _num_text(v: float) -> String:
	var s := "%.2f" % v
	if s.contains("."):
		s = s.rstrip("0").rstrip(".")
	return s


## "Street: a and b. Folk: c." for the [text, group] items, group by group (empty groups left out).
static func _sorted_words(groups: Array, items: Array) -> String:
	var parts: Array = []
	for g: Variant in groups:
		var words := _in_group(items, str(g))
		if not words.is_empty():
			parts.append("%s: %s." % [_cap(str(g)), _and(words)])
	return " ".join(PackedStringArray(parts))


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
