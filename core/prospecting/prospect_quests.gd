class_name ProspectQuests
extends RefCounted
## Prospecting quests (spec §26.2, owner #80: "to find such places you need find them with quests which include solving
## problems, quizes, maps, advantures, findings and other exciting things"). Gemma the geologist tells one per resource
## at her camp by the spawn. Each is 7 steps of these kinds, from this world (the deposit DepositRules put there and the
## camp): pure, the same for the same deposit, camp and roll.
## - MAP: read the quest's map (the camp, the X, the grid, north up, the scale): which way, how far, or which square.
## - CLUE: a clue from real geology (a choice).       - PROBLEM: a survey's maths (a number typed on the pad).
## - QUIZ: two or three School exercises of what the quest taught (ExerciseCheck; the School's answer gold).
## - REACH: walk to the step's place (the HUD's compass points there): the adventure.
## - SIGN: find the telltale sign itself by walking up to it; it says a real fact.
## - MARK: mark the deposit on MY MAP: the quest is done (EarnRules' gold, ProspectRewards).
## Fair fun (spec §6): no timers, nothing expires or is lost (a quest waits where it was), a miss gets a hint and another
## try (ExercisePanel), and nothing is dangerous or scary. Spec §26.5: the Moon's and Mars's quests are SpaceQuests'
## (their cards and their steps between the map and MARK IT), built with the same steps.

const MAP := &"map"
const CLUE := &"clue"
const PROBLEM := &"problem"
const QUIZ := &"quiz"
const REACH := &"reach"
const SIGN := &"sign"
const MARK := &"mark"
const TYPES: Array[StringName] = [MAP, CLUE, PROBLEM, QUIZ, REACH, SIGN, MARK]
## A step's place is reached this near (sideways) and this far up or down.
const REACH_NEAR := 16.0
const SIGN_NEAR := 3.5
const NEAR_HIGH := 12.0
## The salt problem's pans, in litres (the roll picks one).
const SALT_PANS: Array[int] = [2, 4, 10]
## The echo survey's rock (SurveyRules.ECHO_SPEED), written as a child reads it.
const SPEED_WORDS := "2,000"

## kind -> {title, story (Gemma's words on the card), map_ask: what the map asks ("direction", "distance", "square")}.
const QUESTS := {
	DepositKinds.GOLD: {"title": "Gold in the hills", "map_ask": "direction",
		"story": "Long ago, rivers here carried gold! Gold is heavy, so its flakes sink into the gravel. Let's find where they came from."},
	DepositKinds.COPPER: {"title": "The green rocks", "map_ask": "square",
		"story": "Copper hides in dry mountains, and where it meets the air it turns the rock green! My map shows green rocks on a mesa."},
	DepositKinds.IRON: {"title": "The needle that points wrong", "map_ask": "distance",
		"story": "Some hills here are rusty red, and my compass goes funny near them! Let's find out why."},
	DepositKinds.COAL: {"title": "The black stripe", "map_ask": "direction",
		"story": "Long, long ago this land was a steamy swamp forest with giant ferns. Its plants turned into coal! Let's find a seam."},
	DepositKinds.OIL: {"title": "The echo under the sand", "map_ask": "direction",
		"story": "This desert was a sea long ago. Tiny sea creatures sank into the mud and slowly became oil. Let's find where it's trapped!"},
	DepositKinds.SALT: {"title": "The dried-up lake", "map_ask": "square",
		"story": "Once a lake filled this valley. The hot sun dried it up and left its salt behind. Let's find the salt flat!"},
}


static func quest(kind: StringName) -> Dictionary:
	return QUESTS.get(kind, SpaceQuests.quest(kind))


## The quest's steps for `deposit` found from a camp at `camp` (roll: the seed's pick of the numbers, the choices' order).
static func steps(kind: StringName, deposit: Dictionary, camp: Vector3, roll: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if deposit.is_empty() or quest(kind).is_empty():
		return out
	out.append(_map_step(kind, deposit, camp, roll))
	var name := DepositKinds.display_name(kind).to_lower()
	out.append_array(SpaceQuests.middle(kind, deposit, roll))   # spec §26.5 (nothing for Earth's kinds)
	match kind:
		DepositKinds.GOLD:
			out.append(_reach(0, "Walk to the river by the X"))
			out.append(_sign(0, "Find gold flakes in the river's gravel",
				"Gold is about 19 times heavier than water, so its flakes sink into the gravel where the water slows down."))
			out.append(_problem(_number("You pan the gravel three times, going up the stream: 2 flakes, then 4, then 8. If it doubles again, how many flakes are in the next pan?",
				"16", "Each pan has twice as many flakes as the one before. What is 8 + 8?",
				"8 × 2 = 16. More gold up the stream means the gold washed down from the hill!")))
			out.append(_sign(1, "Follow the gold uphill: find the quartz stripe",
				"Gold grows in white quartz veins deep in old rock. Rain and rivers wear the veins away and wash the gold down."))
			out.append(_quiz([
				_truefalse("Gold rusts when it gets wet.", false, "Gold rings stay shiny for thousands of years.",
					"Gold never rusts. That is why gold coins from long ago still shine."),
				_choice("Why does gold stay in the pan while the sand washes out?",
					["It is very heavy", "It is sticky", "It floats", "It is magnetic"], 0, roll,
					"Think of the flakes sinking in the river.",
					"Gold is very heavy, so it sinks to the bottom of the pan and the light sand washes away."),
			]))
		DepositKinds.COPPER:
			out.append(_reach(0, "Walk to the mesa at the X"))
			out.append(_sign(0, "Find the green stains on the mesa",
				"The green is malachite. Copper turns green in the air, like the copper skin of the Statue of Liberty."))
			out.append(_clue(_choice("Why are these rocks green?",
				["Copper turned green in the air", "Moss grows on them", "Someone painted them", "Rain made them wet"], 0, roll,
				"The Statue of Liberty is made of copper, and she is green too.",
				"Copper meets air and water and grows a green crust: malachite on rocks, a patina on statues and roofs.")))
			out.append(_problem(_number("This ore is 1% copper: 1 kg of copper in every 100 kg of rock. How many kg of copper are in 500 kg of ore?",
				"5", "How many hundreds are in 500? Each hundred gives 1 kg.",
				"500 ÷ 100 = 5, so 5 kg. Real copper ore is often less than 1% copper, so a mine digs a lot of rock!")))
			out.append(_quiz([
				_choice("What is most copper used for?", ["Electric wires", "Bread", "Glass windows", "Paper"], 0, roll + 1,
					"Copper carries electricity very well.",
					"Most copper goes into wires, motors and electronics. Only silver carries electricity better."),
				_truefalse("Copper was one of the first metals people learned to use.", true,
					"People made copper tools long before iron ones.",
					"People smelted copper more than 7,000 years ago, long before iron."),
			]))
		DepositKinds.IRON:
			out.append(_reach(0, "Walk to the red hill at the X"))
			out.append(_sign(0, "Find the rusty red rock on the hilltop",
				"Iron ore rusts where air and rain reach it, so the top of an iron deposit turns red-brown."))
			var clue := _choice("On the rusty rock, your compass needle points at the rock, not north! Why?",
				["The rock holds magnetic iron ore", "The compass is broken", "The rock is hot", "It is night"], 0, roll,
				"Magnets pull a compass needle.",
				"Magnetite is the most magnetic mineral on Earth. The iron ore pulls the compass needle towards it.")
			clue.picture = {"kind": "compass", "needle": true, "bearing": 110}
			out.append(_clue(clue))
			out.append(_problem(_number("My metal detector beeps once a second 40 m from the iron, twice at 20 m and 4 times at 10 m. How many beeps a second at 5 m?",
				"8", "Each time the distance halves, the beeps double.",
				"Half of 10 m is 5 m, so the beeps double again: 4 × 2 = 8. The faster it beeps, the closer the iron!")))
			out.append(_quiz([
				_truefalse("Steel is made mostly of iron.", true, "Steel is iron with a little carbon.",
					"Steel is iron with a little carbon mixed in. Almost all the iron ore dug up is made into steel."),
				_number("In the Clay Oven, each Banded Iron makes 2 Iron. How many Iron do 6 Banded Iron make?", "12",
					"6 lots of 2.", "6 × 2 = 12 Iron. Rich iron ore can be more than half iron!"),
				_choice("How did iron from the old seas end up in stripes of rock?",
					["Oxygen from tiny living things rusted it", "Volcanoes painted it", "Fish carried it", "Snow pressed it flat"],
					0, roll + 2, "The first living things that made oxygen lived in the sea.",
					"Tiny sea life began making oxygen billions of years ago. It rusted the iron in the sea, and the rust sank in layers."),
			]))
		DepositKinds.COAL:
			out.append(_reach(0, "Walk to the hillside at the X"))
			out.append(_sign(0, "Find the black stripe in the hillside",
				"The grey rock over the coal is shale. Its fern prints are fossils of the old swamp's plants."))
			var layers := _choice("The rock above the coal has fern prints. What was here when the coal formed?",
				["A swamp forest", "A desert", "An ice sheet", "A deep ocean"], 0, roll,
				"Ferns grow in warm, wet places.",
				"This was a swamp forest about 300 million years ago. Its plants were buried and slowly squeezed into coal.")
			layers.picture = {"kind": "layers", "blocks": [BlockIds.STONE, BlockIds.COAL, BlockIds.FERN_SHALE, BlockIds.DIRT,
				BlockIds.GRASS], "fossils": {"2": "leaf"}}
			out.append(_clue(layers))
			out.append(_problem(_number("About 10 m of squashed plants make 1 m of coal. This seam is 3 m thick. How many metres of plants made it?",
				"30", "Each metre of coal took 10 m of plants.", "3 × 10 = 30 m of plants! That is taller than a 9-storey house.")))
			out.append(_quiz([
				{"type": "order", "prompt": "Put the steps in order: how a swamp forest becomes coal.",
					"items": ["The plants are buried in mud", "Heat and weight squeeze them into coal", "Plants grow in a swamp",
						"The mud turns to rock"], "answer": [2, 0, 3, 1], "hint": "What must happen first?",
					"explain": "Plants grow, fall over and are buried in mud; the mud turns to rock; deep down, heat and weight squeeze them into coal."},
				_truefalse("Burning coal puts carbon dioxide into the air, which warms the planet.", true,
					"Coal is mostly carbon.",
					"Burning coal makes carbon dioxide, which traps heat. That is why many countries now make electricity from wind and sunlight."),
			]))
		DepositKinds.OIL:
			var depth := int(deposit.get("depth_m", 1000))
			var t := SurveyRules.echo_seconds(depth)
			var t_words := _seconds_words(t)
			out.append(_reach(0, "Walk to the dunes at the X"))
			out.append(_sign(0, "Find the dark, sticky sand",
				"An oil seep is where a little oil comes up to the top. People used oil from seeps thousands of years ago."))
			out.append(_problem(_number("Thump! Sound goes %s m every second in this rock. The echo from the dome came back after %s seconds. It went down and back up. How deep is the dome?" % [SPEED_WORDS, t_words],
				str(depth), "In %s seconds the sound goes %s × %s m. Half of that is the way down." % [t_words, SPEED_WORDS, t_words],
				"%s × %s = %s m, down and back up, so the dome is %s m down." % [SPEED_WORDS, t_words,
					_thousands(depth * 2), _thousands(depth)])))
			out.append(_reach(1, "Walk to the top of the dome to drill"))
			out.append(_quiz([
				_choice("Why does the oil stay under the dome?",
					["Tight cap rock won't let it through", "The sand is sticky", "Oil is heavier than rock", "It is frozen"], 0, roll,
					"Oil rises through rock with tiny holes until it meets rock with none.",
					"Oil is light and rises through rock with tiny holes. A dome of tight rock above stops it, like a lid."),
				_choice("Which fuel made from oil do many rockets burn?", ["Kerosene", "Milk", "Salt water", "Sand"], 0, roll + 1,
					"Jet planes burn it too.", "Refineries make kerosene from oil. Jet planes and many rockets burn it."),
				_truefalse("Burning oil puts carbon dioxide in the air, and that warms the planet.", true,
					"Oil, like coal, is mostly carbon.",
					"That is why cars and rockets are learning cleaner fuels, like electricity and hydrogen made with sunlight."),
			]))
		DepositKinds.SALT:
			var litres := SALT_PANS[absi(roll) % SALT_PANS.size()]
			out.append(_reach(0, "Walk to the flat ground at the X"))
			out.append(_sign(0, "Find the flat, white, crusty ground",
				"A salt flat is the dried bed of a lake. Nothing grows on it: the salt is too strong for plants."))
			out.append(_problem(_number("Sea water has about 35 g of salt in every litre. A salt pan holds %d litres. How many grams of salt are left when it dries?" % litres,
				str(35 * litres), "Each litre leaves 35 g of salt. How much do %d litres leave?" % litres,
				"35 × %d = %d g of salt. People have dried sea water in shallow pans for thousands of years." % [litres, 35 * litres])))
			out.append(_clue(_choice("How did the salt get here?",
				["A lake dried up and left it", "It snowed", "Salt grows like a plant", "The wind made it"], 0, roll,
				"When water dries up, what is left behind?",
				"When salty water dries in the sun, the water goes up into the air and the salt stays. A whole lake did that here.")))
			out.append(_quiz([
				_choice("What shape are rock salt's crystals?", ["Little cubes", "Balls", "Stars", "Rings"], 0, roll + 1,
					"Look closely at a grain of salt.", "Salt's crystals are little cubes: that is how its atoms stack up."),
				_truefalse("Salt helps keep roads free of ice in winter.", true, "Salty water freezes at a lower temperature.",
					"Salt makes ice melt at a lower temperature, so roads stay safer in winter."),
			]))
	out.append({"type": MARK, "words": "Mark the %s on your map" % DepositKinds.mark_words(kind), "picture": &"map"})
	return out


## The exercises a step asks (MAP, CLUE, PROBLEM: one; QUIZ: two or three; walking and marking: none).
static func exercises(step: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if step.has("exercise"):
		out.append(step.exercise)
	for ex: Dictionary in step.get("exercises", []):
		out.append(ex)
	return out


## Where the HUD's compass points for a step (INF: nowhere). REACH: the step's place; SIGN: its sign's first cell.
static func target(step: Dictionary, deposit: Dictionary) -> Vector3:
	var i := int(step.get("spot", -1))
	var spots: Array = deposit.get("spots", [])
	if i < 0 or i >= spots.size():
		return Vector3.INF
	if step.type == SIGN:
		var signs: Array = (deposit.get("signs", []) as Array)[i] if i < (deposit.get("signs", []) as Array).size() else []
		if not signs.is_empty():
			return Vector3(signs[0] as Vector3i) + Vector3(0.5, 0.5, 0.5)
	return Vector3(spots[i] as Vector3i) + Vector3(0.5, 0.5, 0.5)


## True when feet at `feet` have done a walking step: near the place (REACH), up close to the sign (SIGN).
static func arrived(step: Dictionary, deposit: Dictionary, feet: Vector3) -> bool:
	if not feet.is_finite():
		return false
	match step.get("type"):
		REACH:
			var at := target(step, deposit)
			return at.is_finite() and Vector2(at.x - feet.x, at.z - feet.z).length() <= REACH_NEAR \
				and absf(at.y - feet.y) <= NEAR_HIGH
		SIGN:
			var i := int(step.get("spot", -1))
			var all: Array = deposit.get("signs", [])
			if i < 0 or i >= all.size():
				return false
			for c: Vector3i in all[i]:
				var at := Vector3(c) + Vector3(0.5, 0.5, 0.5)
				if Vector2(at.x - feet.x, at.z - feet.z).length() <= SIGN_NEAR and absf(at.y - feet.y) <= NEAR_HIGH * 0.5:
					return true
	return false


# --- Building the steps --------------------------------------------------------------------------------------------

## The map step: the quest's map round the camp and the first place (the X), and its question.
static func _map_step(kind: StringName, deposit: Dictionary, camp: Vector3, roll: int) -> Dictionary:
	var spot: Vector3i = deposit.spots[0]
	var target := Vector3(spot) + Vector3(0.5, 0, 0.5)
	var frame := SurveyRules.map_frame(camp, target)
	var sq := int(frame.square)
	var ask := str(quest(kind).get("map_ask", "direction"))
	var what := DepositKinds.what(kind)
	var ex := {}
	match ask:
		"distance":
			var dist := SurveyRules.map_distance(camp, target, sq)
			var c := SurveyRules.number_choices(dist, sq, roll)
			ex = {"type": "choice", "prompt": "Each square on the map is %d m. About how far is the X from the camp?" % sq,
				"choices": c.choices, "answer": c.answer,
				"hint": "Count the squares from the camp to the X, then times by %d." % sq,
				"explain": "The X is about %d squares away: about %d m." % [dist / sq, dist]}
		"square":
			var right := SurveyRules.square(target, frame.corner, sq)
			var c := SurveyRules.square_choices(right, roll)
			ex = {"type": "choice", "prompt": "Which square of the map is the X in? Letters go across the top, numbers go down the side.",
				"choices": c.choices, "answer": c.answer,
				"hint": "Go down from the letter above the X, and across from the number beside it.",
				"explain": "The X is in square %s: column %s, row %s." % [right, right[0], right.substr(1)]}
		_:
			var p := SurveyRules.point(camp, target)
			var c := SurveyRules.point_choices(p, roll)
			ex = {"type": "choice", "prompt": "The X on the map is where I saw signs of %s. Which way is it from our camp?" % what,
				"choices": c.choices, "answer": c.answer,
				"hint": "North is at the top of the map. Find the camp, then look at the X.",
				"explain": "The X is %s of the camp. North is up, east is to the right." % SurveyRules.point_words(p)}
	return {"type": MAP, "words": "Read my map", "picture": &"map", "exercise": ex, "ask": ask,
		"map": {"camp": camp, "target": target, "frame": frame, "kind": kind}}


static func _reach(spot: int, words: String) -> Dictionary:
	return {"type": REACH, "words": words, "spot": spot, "picture": &"compass"}


static func _sign(spot: int, words: String, fact: String) -> Dictionary:
	return {"type": SIGN, "words": words, "spot": spot, "fact": fact, "picture": &"sign"}


static func _clue(ex: Dictionary) -> Dictionary:
	return {"type": CLUE, "words": "Think like a geologist", "picture": &"clue", "exercise": ex}


static func _problem(ex: Dictionary) -> Dictionary:
	return {"type": PROBLEM, "words": "Solve the survey's sum", "picture": &"problem", "exercise": ex}


static func _quiz(list: Array) -> Dictionary:
	var exs: Array[Dictionary] = []
	for e: Dictionary in list:
		exs.append(e)
	return {"type": QUIZ, "words": "Answer Gemma's quiz", "picture": &"quiz", "exercises": exs}


static func _number(prompt: String, answer: String, hint: String, explain: String) -> Dictionary:
	return {"type": "number", "prompt": prompt, "answer": answer, "hint": hint, "explain": explain}


static func _truefalse(prompt: String, answer: bool, hint: String, explain: String) -> Dictionary:
	return {"type": "truefalse", "prompt": prompt, "answer": answer, "hint": hint, "explain": explain}


## A choice with its right answer (index `right` of `list`) moved to the place the roll picks.
static func _choice(prompt: String, list: Array, right: int, roll: int, hint: String, explain: String) -> Dictionary:
	var choices: Array = list.duplicate()
	var answer_text: String = choices[right]
	choices.remove_at(right)
	var at := absi(roll) % (choices.size() + 1)
	choices.insert(at, answer_text)
	return {"type": "choice", "prompt": prompt, "choices": choices, "answer": at, "hint": hint, "explain": explain}


## "1.5", "2" (a time in seconds as a child writes it).
static func _seconds_words(t: float) -> String:
	return str(int(t)) if is_equal_approx(t, roundf(t)) else "%.1f" % t


## 2000 -> "2,000".
static func _thousands(n: int) -> String:
	var s := str(n)
	return s if n < 1000 else "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]
