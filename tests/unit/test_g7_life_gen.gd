extends GutTest
## Owner #70, #73 and #111, grade 7 health and PE, D&T and projects generators (G7LifeGen, SchoolGen source "g7w"):
## every generator makes a valid exercise at every level for 120 seeds, with a strategy hint, a worked answer and its
## `data`, and every answer is worked out again here from `data` with this test's own rules and facts: badminton's
## serving court and the end of a game, tennis's calls, heart-rate zones (220 − age), sleep across midnight, tournaments,
## resistors' colour codes, an LED's resistor and the E12 series, circuits that conduct, a board's LEDs, programs' pauses
## and counters, recipes, percentages, a mould's cost, 3D-printing layers, laser cuts, the kerf, sea miles by latitude,
## water, energy, carbon, markups, discounts, profit and break-even; and the facts behind every choice.

const SEEDS := 120
const SOURCE := "g7w."

## Own facts: what each choice's right answer must be, by what the exercise asked.
const TACTIC_GROUP := {"overlap": "attacking", "third-man run": "attacking", "switch of play": "attacking",
	"decoy run": "attacking", "give-and-go": "attacking", "screen": "attacking", "pressing": "defending",
	"zonal marking": "defending", "man-to-man marking": "defending", "recovery run": "defending",
	"double team": "defending", "compact block": "defending"}
const SHOT_FOR := {"Your opponent is close to the net.": "clear", "Your opponent is at the back of the court.": "drop shot",
	"The shuttle comes high and short, near the middle of your court.": "smash",
	"The shuttle is at about net height and you want a fast, flat return.": "drive",
	"The shuttle drops just over the net on your side.": "net shot",
	"You are pushed back and need time to get back to your base.": "clear"}
const SHOT_NAMES := {"clear": "clear", "drop": "drop shot", "smash": "smash", "drive": "drive", "net": "net shot"}
const STYLE_OF := {"a freeze, balancing on your hands": "street", "toprock: steps danced standing up": "street",
	"popping: tensing muscles on the beat": "street", "locking: quick moves that stop and hold": "street",
	"a battle in a circle called a cypher": "street", "quick, neat steps with the arms still": "folk",
	"dancing in lines with bells and sticks": "folk", "a circle dance, holding hands": "folk",
	"a reel with a partner at a ceilidh": "folk", "a harvest dance from Punjab: Bhangra": "folk",
	"floorwork: rolling and sliding on the floor": "contemporary", "contraction and release": "contemporary",
	"fall and recovery": "contemporary", "moving freely to show a feeling": "contemporary"}
const SIGNAL_WORDS := {"advantage": "advantage: play on", "direct": "a direct free kick",
	"indirect": "an indirect free kick", "penalty": "a penalty kick"}
const HELPS_SLEEP: Array[String] = ["the same bedtime every day", "a dark, quiet, cool bedroom", "daylight in the morning",
	"screens off an hour before bed", "exercise earlier in the day", "reading a paper book"]
const TRICK_WORDS := {"star": "a famous person", "bandwagon": "bandwagon", "free_gift": "a free gift",
	"health_claim": "a health claim", "small_print": "small print", "ad_label": "a '#ad' label"}
const INFLUENCE_OF := {"Tilly eats the same breakfast as her parents.": "family",
	"Bram wants the trainers his friends wear.": "friends", "Zara watches a video star try a new drink.": "media",
	"A poster at the bus stop shows a new snack.": "adverts", "Mimi's family cooks special food for a festival.": "culture",
	"The school canteen serves fruit every day.": "school", "Bram tries hockey because his older cousin plays.": "family",
	"Mimi joins a running club with her best friend.": "friends", "A TV programme makes Zara want to try climbing.": "media",
	"A cereal box promises a free toy.": "adverts"}
const EDIT_NAMES := {"light": "brighter light", "filter": "warm filter", "smooth": "smoothed skin", "eyes": "bigger eyes",
	"teeth": "whiter teeth", "background": "new background"}
const STORE := {"milk": "fridge", "yoghurt": "fridge", "raw chicken, on the bottom shelf": "fridge", "cheese": "fridge",
	"frozen peas": "freezer", "ice cream": "freezer", "fish fingers": "freezer", "dry pasta": "cupboard", "rice": "cupboard",
	"tinned beans": "cupboard", "bread to eat this week": "cupboard"}
const DISH_FROM := {"paella": "Spain", "dal with rice": "India", "jollof rice": "West Africa", "tacos": "Mexico",
	"sushi": "Japan", "khachapuri": "Georgia", "couscous": "North Africa", "pierogi": "Poland", "pho": "Vietnam",
	"goulash": "Hungary"}
const MATERIAL_OF := {"case": "ABS plastic", "lens": "acrylic", "spring": "steel", "contacts": "brass",
	"reflector": "shiny metal-coated plastic", "switch button": "rubber"}
const R_OF := {"Bram mends the puncture in his bike tyre.": "repair", "Tilly says no to a free plastic bag.": "refuse",
	"Zara turns a jam jar into a pencil pot.": "reuse", "Mimi's old cans go in the metal bin.": "recycle",
	"A designer uses thinner card for the same strong box.": "reduce",
	"A team asks if a product could be shared instead of each buying one.": "rethink"}
const PLASTIC := {1: "PET", 2: "HDPE", 4: "LDPE", 5: "PP", 6: "PS"}
const STAGE_ORDER: Array[String] = ["raw materials", "manufacture", "transport", "use", "end of life"]
const COLOURS: Array[String] = ["black", "brown", "red", "orange", "yellow", "green", "blue", "violet", "grey", "white"]
const E12: Array[int] = [10, 12, 15, 18, 22, 27, 33, 39, 47, 56, 68, 82]
const NATURAL: Array[String] = ["cotton", "wool", "silk", "linen"]


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


func test_the_source_is_registered_last_and_has_its_generators() -> void:
	# Added at the end of SOURCES (the brief's rule); later grades' sources ("g8h"…) go after it, so it stays after
	# every grade 7 source.
	var keys: Array = SchoolGen.SOURCES.keys()
	assert_true(keys.has("g7w"), "g7w is a SOURCES line")
	assert_gt(keys.find("g7w"), maxi(keys.find("g7h"), keys.find("g7c")), "g7w comes after grade 7's other sources")
	assert_gt(_gens().size(), 40, "the grade 7 life generators exist")


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
	assert_gt(checked, 15000, "answers checked")


## "" when `ex`'s answer is right by this test's own working; otherwise why not.
func _check(name: String, level: int, ex: Dictionary) -> String:
	var d: Dictionary = ex.data
	var right: Variant = _right(ex)
	var p := str(ex.prompt)
	match name:
		"tactic_case":
			if level == 1:
				return "" if right == str(d.tactic) and TACTIC_GROUP.has(right) else "not the tactic"
			if level == 2:
				for item: String in right:
					if TACTIC_GROUP.get(item, "") != right[item]:
						return "%s is %s" % [item, TACTIC_GROUP.get(item, "?")]
				return ""
			return "" if _situation_best(str(d.situation)) == right else "not the best choice"
		"overload":
			var a := 0
			var dd := 0
			for pl: Array in ex.get("picture", {"players": []}).players:
				a += 1 if str(pl[2]) == "a" else 0
				dd += 1 if str(pl[2]) == "d" else 0
			if ex.has("picture") and (a != int(d.attackers) or dd != int(d.defenders)):
				return "the pitch shows %d v %d" % [a, dd]
			if level == 2:
				var want := "even numbers" if int(d.attackers) == int(d.defenders) else ("an overload for blue"
					if int(d.attackers) > int(d.defenders) else "an overload for red")
				return "" if right == want else "it is %s" % want
			return "" if is_equal_approx(right, int(d.attackers) - int(d.defenders)) else "difference"
		"serve_court":
			if level == 1:
				return "" if right == ("the right service court" if int(d.score) % 2 == 0 else "the left service court") else "court"
			if level == 2:
				var names := _names_in(p)
				var winner := names[0] if bool(d.winner_is_a) else names[1]
				var score := int(d.a) + 1 if bool(d.winner_is_a) else int(d.b) + 1
				return "" if right == "%s, from the %s" % [winner, "right" if score % 2 == 0 else "left"] else "server"
			var a := int(d.a)
			var b := int(d.b)
			var names := _names_in(p)
			var won_a := a >= 30 or (a >= 21 and a - b >= 2)
			var won_b := b >= 30 or (b >= 21 and b - a >= 2)
			var want := ("%s has won the game" % names[0]) if won_a else (("%s has won the game" % names[1]) if won_b
				else "the game goes on")
			return "" if right == want else "it is: %s" % want
		"tennis_score":
			var names := _names_in(p)
			return "" if right == _tennis(int(d.server), int(d.receiver), names[0], names[1]) else "the call"
		"shot_choice":
			if level == 1:
				var asked := int(d.asked)
				if not p.contains(str(SHOT_NAMES[str(d.shots[asked])])):
					return "asks another shot"
				return "" if right == "path %s" % "ABCD"[asked] else "wrong path"
			if level == 2:
				return "" if right == SHOT_FOR.get(str(d.case), "?") else "shot"
			return "" if p.contains(str(SHOT_FOR.get(str(d.case), "?"))) else "the shot's reason"
		"max_hr":
			var top := 220 - int(d.age)
			if level == 1:
				return "" if is_equal_approx(right, top) else "220 − age"
			if level == 2:
				var share := 0.6 if p.contains("low end") else 0.8
				return "" if is_equal_approx(right, roundf(top * share)) else "%d%% of %d" % [int(share * 100), top]
			return "" if is_equal_approx(right, roundf(top * 0.8) - roundf(top * 0.6)) else "width"
		"hr_zone":
			var top := 220 - int(d.age)
			var share := float(d.bpm) / top
			var zone := "rest" if share < 0.5 else ("warm-up" if share < 0.6 else ("aerobic" if share < 0.8 else
				("anaerobic" if share < 0.9 else "maximum")))
			if level == 2 and int(ex.picture.trace[int(ex.picture.point)][1]) != int(d.bpm):
				return "the point is not the pulse"
			return "" if str(right).begins_with(zone) else "it is %s" % zone
		"week_minutes":
			if level == 1:
				var total := 0
				for m: Variant in d.minutes:
					total += int(m)
				return "" if is_equal_approx(right, total) else "total"
			if level == 2:
				return "" if is_equal_approx(right, float(d.total) / 7.0) else "average"
			return "" if is_equal_approx(right, int(d.start) * 1.1) else "10% more"
		"dance_counts":
			if level == 1:
				return "" if is_equal_approx(right, int(d.phrases) * 8) else "counts"
			if level == 2:
				return "" if is_equal_approx(right, 8.0 * 60.0 / int(d.tempo) * int(d.phrases)) else "seconds"
			return "" if is_equal_approx(right, 1 + int(d.gap) * (int(d.dancers) - 1)) else "canon"
		"dance_style":
			if level == 1:
				return "" if right == STYLE_OF.get(str(d.move), "?") else "style"
			if level == 2:
				for item: String in right:
					if STYLE_OF.get(item, "?") != right[item]:
						return item
				return ""
			return "" if _dance_fact(str(d.fact)) == right else "fact"
		"ref_call":
			if level == 1:
				return "" if right == SIGNAL_WORDS[str(d.signal)] and str(ex.picture.signal) == str(d.signal) else "signal"
			return "" if _ref_best(str(d.case)) == right else "decision"
		"tournament":
			var n := int(d.teams)
			if level == 1:
				return "" if is_equal_approx(right, n - 1) else "knockout"
			if level == 2:
				return "" if is_equal_approx(right, n * (n - 1) / 2) else "round robin"
			var rounds := ceili(float(n * (n - 1) / 2) / int(d.courts))
			if int(d.courts) * 2 > n:
				return "more courts than pairs of teams"
			return "" if is_equal_approx(right, rounds * int(d.minutes)) else "time"
		"sleep_hours":
			if level == 1:
				var h := float((int(d.wake) - int(d.sleep) + 1440) % 1440) / 60.0
				var pic_h := SchoolPictureG7Life.sleep_hours(str(ex.picture.sleep), str(ex.picture.wake))
				return "" if is_equal_approx(right, h) and is_equal_approx(pic_h, h) else "hours"
			if level == 2:
				var m := (int(d.wake) - int(d.need) * 60 + 1440) % 1440
				return "" if right == "%02d:%02d" % [m / 60, m % 60] else "bedtime"
			return "" if is_equal_approx(right, int(d.short) * int(d.nights) / 60.0) else "debt"
		"sleep_habit":
			if level == 1:
				var f := str(d.fact)
				var truth := not (f.contains("less sleep") or f.contains("help you fall") or f.contains("fixes")
					or f.contains("no effect"))
				return "" if right == truth else "fact"
			if level == 2:
				for item: String in right:
					if (right[item] == "helps sleep") != HELPS_SLEEP.has(item):
						return item
				return ""
			return "" if not str(right).contains("later") and not str(right).contains("cola") and not str(right).contains("TV") \
				else "a change that harms sleep"
		"advert_trick":
			if level == 1:
				return "" if right == TRICK_WORDS[str(d.trick)] and str(ex.picture.mark) == str(d.trick) else "trick"
			if level == 2:
				return "" if right == _trick_of(str(d.line)) else "trick of the line"
			return "" if str(right).ends_with("?") and _advert_question(str(d.claim)) == right else "question"
		"influence_kind":
			if level == 1:
				return "" if right == INFLUENCE_OF.get(str(d.story), "?") else "influence"
			if level == 2:
				for item: String in right:
					var healthy := item in ["a friend asks you to join a club", "a family walk at the weekend",
						"a video about cooking vegetables", "a poster about drinking water"]
					if (right[item] == "healthy") != healthy:
						return item
				return ""
			return "" if right == (["stop and notice the choice", "think of the options", "think of what each could lead to",
				"choose, and say why", "look back: did it work?"] as Array[String]) else "steps"
		"edit_signs":
			if level == 1:
				return "" if is_equal_approx(right, (ex.picture.edits as Array).size()) else "count"
			if level == 2:
				return "" if right == EDIT_NAMES[str(ex.picture.edits[int(d.asked)])] else "edit"
			var f := str(d.fact)
			var truth := not (f.contains("always shows") or f.contains("every day") or f.contains("always says"))
			return "" if right == truth else "fact"
		"kind_thought":
			if level == 1:
				return "" if _kinder(str(d.thought)) == right else "kind words"
			if level == 2:
				for item: String in right:
					var kind := item in ["I'm still learning this.", "I'm only seeing their best moments.",
						"I can try a new way next time.", "It's one photo, and I'm more than a photo.",
						"Everyone makes mistakes: what can I learn?", "I'm good at some things and getting better."]
					if (right[item] == "kind") != kind:
						return item
				return ""
			return "" if str(right).contains("break") or str(right).contains("trusted adult") else "help"
		"drug_facts":
			return "" if right == _drug_truth(str(d.fact)) else "fact"
		"drug_help":
			if level == 1:
				return "" if _drug_best(str(d.worry)) == right else "help"
			if level == 2:
				return "" if right == (["check it is safe to go near", "call 999 and say what has happened",
					"recovery position, if breathing", "stay with them until help comes",
					"tell the paramedics what they took"] as Array[String]) else "steps"
			return "" if str(right).begins_with("No") else "a clear no"
		"i_statement":
			if level == 1:
				return "" if str(right).begins_with("I feel") and str(right).contains("when") else "I-statement"
			if level == 2:
				return "" if _win_win(str(d.case)) == right else "win-win"
			for item: String in right:
				var calm := item in ["take slow breaths", "speak in a calm voice", "listen without interrupting",
					"take a break and talk later", "say what you feel with 'I'"]
				if (right[item] == "calms it down") != calm:
					return item
			return ""
		"conflict_move":
			if level == 1:
				return "" if right == "stop and calm down" else "first step"
			if level == 2:
				var steps: Array[String] = ["stop and calm down", "say what happened and how you feel",
					"listen to each other", "think of solutions together", "agree on one and check later"]
				return "" if right == steps.slice(int(d.start), int(d.start) + 4) else "steps"
			var c := str(d.case)
			var adult := c.contains("picking on") or c.contains("threatens") or c.contains("cruel")
			return "" if right == adult else "adult help"
		"help_service":
			if level < 3:
				return "" if _service(str(d.need)) == right else "service"
			var f := str(d.fact)
			var truth := not (f.contains("only ask") or f.contains("homework") or f.contains("telling tales"))
			return "" if right == truth else "fact"
		"part_material":
			if level == 1:
				return "" if p.contains(str(MATERIAL_OF.get(str(d.part), "?"))) and _material_why(str(d.part)) == right \
					else "why"
			if level == 2:
				for item: String in right:
					if MATERIAL_OF.get(item, "?") != right[item]:
						return item
				return ""
			return "" if _process_of(str(d.part)) == right else "process"
		"production_scale":
			if level == 1:
				return "" if _scale(str(d.case)) == right else "scale"
			if level == 2:
				for item: String in right:
					if _scale(item) != right[item]:
						return item
				return ""
			return "" if is_equal_approx(right, (float(d.mould) + int(d.each) * int(d.count)) / int(d.count)) else "cost"
		"print_layers":
			if level == 1:
				return "" if is_equal_approx(right, roundf(float(d.height) / float(d.layer))) else "layers"
			if level == 2:
				return "" if is_equal_approx(right, int(d.layers) * int(d.seconds) / 60.0) else "minutes"
			return "" if is_equal_approx(right, 2.0 * (int(d.w) + int(d.h)) / int(d.speed)) else "cut time"
		"make_method":
			if level == 1:
				var c := str(d.case)
				var additive := c.contains("3D printer") or c.contains("potter")
				return "" if right == ("additive" if additive else "subtractive") else "method"
			if level == 2:
				var c := str(d.case)
				var want := "a laser cutter" if c.contains("plywood") or c.contains("acrylic") else ("a 3D printer"
					if c.contains("hollow") or c.contains("model of") else "a CNC router")
				return "" if right == want else "machine"
			return "" if is_equal_approx(right, (int(d.pieces) - 1) * int(d.kerf) / 10.0) else "kerf"
		"resistor_code":
			var bands: Array = d.bands
			var value := (COLOURS.find(str(bands[0])) * 10 + COLOURS.find(str(bands[1]))) * int(pow(10, COLOURS.find(str(bands[2]))))
			if level < 3:
				return "" if is_equal_approx(right, value) and ex.picture.bands == bands else "value"
			return "" if right == "%s, %s, %s" % [bands[0], bands[1], bands[2]] and p.contains(GenKit.fmt(value)) else "bands"
		"led_resistor":
			var r := (int(d.supply) - int(d.led)) * 1000 / int(d.ma)
			if level == 1:
				return "" if is_equal_approx(right, int(d.supply) - int(d.led)) else "volts"
			if level == 2:
				return "" if is_equal_approx(right, r) else "ohms"
			var std := 0
			var scale := 1
			while std == 0:
				for v: int in E12:
					if std == 0 and v * scale >= r:
						std = v * scale
				scale *= 10
			return "" if right == "%s ohms" % GenKit.fmt(std) else "standard value %d" % std
		"alarm_logic":
			if level == 1:
				var parts: Array = d.parts
				var works := true
				for s: Variant in parts:
					if str(s) in ["switch", "led_back"] or (str(s) in ["push", "pad", "reed", "tilt"] and not bool(d.active)):
						works = false
				return "" if right == works else "conducts"
			if level == 2:
				return "" if _alarm_input(str(d.job)) == right else "input"
			return "" if _alarm_why(str(d.question)) == right else "why"
		"led_xy":
			if level == 1:
				var leds: Array = ex.picture.leds
				return "" if right == "x = %d, y = %d" % [int(d.x), int(d.y)] and str(leds[int(d.y)])[int(d.x)] == "1" \
					else "lit LED"
			if level == 2:
				var pic: Dictionary = ex.choices[int(ex.answer)].picture
				return "" if SchoolPictureG7Life.led_at(pic.leds, int(d.x), int(d.y)) and p.contains("plot(%d, %d)" % [d.x,
					d.y]) else "board"
			var lines: Array = ex.picture.lines
			var n := int(str(lines[0]).get_slice("range(", 1).get_slice(")", 0))
			return "" if is_equal_approx(right, n + (lines.size() - 2)) else "LEDs"
		"pause_time":
			if level == 1:
				return "" if is_equal_approx(right, int(d.ms) / 1000.0) else "seconds"
			if level == 2:
				return "" if is_equal_approx(right, int(d.times) * (int(d.on) + int(d.off)) / 1000.0) else "loop time"
			var c := 0
			for press: Variant in d.presses:
				c = c + 1 if str(press) == "A" else 0
			return "" if is_equal_approx(right, c) else "count"
		"micro_if":
			if level == 1:
				return "" if right == (int(d.reading) < int(d.threshold)) else "light"
			if level == 2:
				return "" if right == (int(d.reading) > int(d.limit)) else "temperature"
			var want: bool = (bool(d.dark) and bool(d.moving)) if bool(d.and) else (bool(d.dark) or bool(d.moving))
			return "" if right == want else "and/or"
		"fabric_for":
			if level == 1:
				return "" if _fabric(str(d.use)) == right else "fabric"
			if level == 2:
				return "" if (right as Dictionary).size() == 4 else "pairs"
			return "" if _fabric_why(str(d.question)) == right else "why"
		"fibre_kind":
			if level == 1:
				for item: String in right:
					if (right[item] == "natural") != NATURAL.has(item):
						return item
				return ""
			if level == 2:
				var c := str(d.case)
				var smart := c.contains("changes colour") or c.contains("LEDs") or c.contains("sensors")
				return "" if right == ("smart" if smart else "technical") else "smart or technical"
			return "" if right == ("reflective strips" if bool(d.night) else "fluorescent colours") else "day or night"
		"recipe_scale":
			if level == 3:
				return "" if is_equal_approx(right, float(d.amount) / int(d.base) * int(d.people)) else "scale"
			return "" if is_equal_approx(right, float(d.per_four) / 4.0 * int(d.people)) else "scale"
		"dish_place":
			if level == 1:
				return "" if right == DISH_FROM.get(str(d.dish), "?") else "place"
			if level == 2:
				for item: String in right:
					if DISH_FROM.get(item, "?") != right[item]:
						return item
				return ""
			return "" if _staple(str(d.staple)) == right else "staple"
		"waste_share":
			if level == 1:
				return "" if is_equal_approx(right, 100.0 * int(d.thrown) / int(d.whole)) else "percent"
			if level == 2:
				return "" if is_equal_approx(right, int(d.week) * 52) else "a year"
			return "" if is_equal_approx(right, 100.0 * int(d.wasted) / int(d.bought)) else "percent"
		"store_place":
			if level == 1:
				return "" if right == "the %s" % STORE.get(str(d.food), "?") else "place"
			if level == 2:
				for item: String in right:
					if STORE.get(item, "?") != right[item]:
						return item
				return ""
			var days: Array = (d.days as Array).duplicate()
			days.sort()
			var want: Array[String] = []
			for dd: Variant in days:
				want.append("use by %d June" % int(dd))
			return "" if right == want else "first in, first out"
		"life_stage":
			if level == 1:
				return "" if _stage(str(d.case)) == right else "stage"
			if level == 2:
				return "" if right == STAGE_ORDER.slice(int(d.start), int(d.start) + 4) else "order"
			var want := {"a smartphone": "manufacture", "a washing machine": "use", "a petrol car": "use",
				"an aluminium can": "raw materials"}
			return "" if right == want.get(str(d.product), "?") else "footprint"
		"six_rs":
			if level == 1:
				return "" if right == R_OF.get(str(d.case), "?") else "R"
			if level == 2:
				return "" if (right as Dictionary).size() == 4 and (right as Dictionary).keys().all(func(k: String) -> bool:
					return k in ["rethink", "refuse", "reduce", "reuse", "repair", "recycle"]) else "pairs"
			return "" if right == PLASTIC.get(int(d.code), "?") else "code"
		"test_mean":
			var res: Array = d.get("results", [])
			if level == 2:
				return "" if is_equal_approx(right, 100.0 * (int(d.after) - int(d.before)) / int(d.before)) else "percent"
			var total := 0
			for v: Variant in res:
				total += int(v)
			return "" if is_equal_approx(right, float(total) / res.size()) else "mean"
		"fair_change":
			return "" if _fair_best(str(d.case)) == right else "best"
		"sea_distance":
			if level == 1:
				return "" if is_equal_approx(right, int(d.knots) * int(d.hours)) else "distance"
			if level == 2:
				return "" if is_equal_approx(right, float(d.distance) / (int(d.knots) * 24)) else "days"
			return "" if is_equal_approx(right, absi(int(d.from) - int(d.to)) * 60) else "latitude miles"
		"voyage_supplies":
			if level == 1:
				return "" if is_equal_approx(right, int(d.crew) * int(d.days) * 3) else "litres"
			if level == 2:
				var need := int(d.crew) * int(d.days) * 3
				return "" if is_equal_approx(right, need * 1.2) else "a fifth more"
			return "" if is_equal_approx(right, ceilf(float(d.need) / int(d.barrel))) else "barrels"
		"energy_use":
			if level == 1:
				return "" if is_equal_approx(right, (60 - 8) * int(d.bulbs)) else "watts"
			if level == 2:
				return "" if is_equal_approx(right, int(d.kw) * int(d.hours)) else "kWh"
			return "" if is_equal_approx(right, int(d.kwh) * 0.2) else "carbon"
		"water_saving":
			if level == 1:
				return "" if is_equal_approx(right, int(d.rate) * int(d.minutes)) else "litres"
			if level == 2:
				return "" if is_equal_approx(right, (int(d.before) - int(d.after)) * int(d.rate) * int(d.people)) else "saved"
			return "" if is_equal_approx(right, int(d.area) * int(d.mm)) else "rain"
		"markup_price":
			if level == 1:
				return "" if is_equal_approx(right, int(d.cost) * (1.0 + int(d.pct) / 100.0)) else "markup"
			if level == 2:
				return "" if is_equal_approx(right, int(d.price) * (1.0 - int(d.off) / 100.0)) else "discount"
			return "" if is_equal_approx(right, (int(d.price) - int(d.cost)) * int(d.sold)) else "profit"
		"profit_loss":
			if level == 1:
				return "" if is_equal_approx(right, int(d.price) * int(d.sold)) else "takings"
			if level == 2:
				var result := int(d.sold) * (int(d.price) - int(d.cost)) - int(d.fixed)
				var want := ("a profit of %d gold" % result) if result > 0 else ("a loss of %d gold" % -result)
				return "" if right == want else "it is %s" % want
			var be := float(d.fixed) / (int(d.price) - int(d.cost))
			return "" if is_equal_approx(right, be) and is_equal_approx(SchoolPictureG7Hum.break_even_items(float(d.fixed),
				float(d.cost), float(d.price)), be) else "break-even"
	return "no check for %s" % name


# --- Own facts --------------------------------------------------------------------------------------------------------

## The two people a prompt names, in order.
func _names_in(p: String) -> Array[String]:
	var found: Array = []
	for who: String in ["Tilly", "Zara", "Bram", "Mimi"]:
		var at := p.find(who)
		if at >= 0:
			found.append([at, who])
	found.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var out: Array[String] = []
	for f: Array in found:
		out.append(str(f[1]))
	return out


func _tennis(a: int, b: int, s: String, r: String) -> String:
	var calls := ["love", "15", "30", "40"]
	if a >= 4 and a - b >= 2:
		return "game to %s" % s
	if b >= 4 and b - a >= 2:
		return "game to %s" % r
	if a >= 3 and b >= 3:
		return "deuce" if a == b else "advantage %s" % (s if a > b else r)
	return ("%s-all" % calls[a]) if a == b else "%s-%s" % [calls[a], calls[b]]


func _situation_best(s: String) -> String:
	if s.contains("3 attackers"):
		return "run at a defender to draw them, then pass"
	if s.contains("just lost the ball"):
		return "press at once to win it back"
	if s.contains("crowded one side"):
		return "switch play to the empty side"
	if s.contains("clean through"):
		return "sprint back to get goal-side"
	if s.contains("wins the ball"):
		return "counter-attack fast, into the space"
	if s.contains("marking your striker"):
		return "make a decoy run to pull defenders away"
	return "move into space and call, then pass and move"


func _dance_fact(f: String) -> String:
	return {"Breaking began in…": "New York in the 1970s", "Bhangra comes from…": "Punjab, at harvest time",
		"Martha Graham was a pioneer of…": "contemporary dance", "Morris dancers often wear…": "bells on their legs",
		"In Irish step dance, the arms are usually…": "held still at the sides",
		"A cypher is…": "a circle where street dancers take turns"}.get(f, "?")


func _ref_best(c: String) -> String:
	if c.contains("keeps the ball"):
		return "play advantage"
	if c.contains("penalty area"):
		return "a penalty kick"
	if c.contains("offside"):
		return "an indirect free kick"
	if c.contains("pushes"):
		return "a direct free kick"
	if c.contains("touchline"):
		return "a throw-in to the other team"
	if c.contains("again and again"):
		return "a free kick and a yellow card"
	if c.contains("best friend"):
		return "give the free kick, as for anyone"
	if c.contains("shouts"):
		return "stay calm, explain briefly and play on"
	if c.contains("did not see"):
		return "ask your assistant, then decide"
	if c.contains("captain"):
		return "encourage them and focus on the next play"
	return "give one clear tip and praise what improves"


func _trick_of(line: String) -> String:
	if line.contains("ten kids") or line.contains("Everyone"):
		return "bandwagon"
	if line.contains("champion") or line.contains("football star"):
		return "famous person"
	if line.contains("vitamins") or line.contains("goodness"):
		return "health claim"
	if line.contains("free"):
		return "free gift"
	if line.contains("Tiny") or line.contains("small letters"):
		return "small print"
	return "paid post"


func _advert_question(c: String) -> String:
	if c.contains("vitamins"):
		return "How much sugar does it have?"
	if c.contains("video star"):
		return "Were they paid to say it?"
	if c.contains("Free gift"):
		return "What do I have to buy to get it?"
	return "Do I need it, or just want it?"


func _kinder(t: String) -> String:
	return {"I'm rubbish at this.": "I'm still learning this.", "Everyone is better than me.":
		"I'm only seeing their best moments.", "I'll never get it right.": "I can try a new way next time.",
		"I look awful in this photo.": "It's one photo, and I'm more than a photo.",
		"I made a mistake, so I'm useless.": "Everyone makes mistakes: what can I learn?",
		"I can't do anything well.": "I'm good at some things and getting better."}.get(t, "?")


func _drug_truth(f: String) -> bool:
	for false_one: String in ["prescribed for a friend", "always made safely", "always safe", "lose your friends",
			"only for yourself", "Only adults"]:
		if f.contains(false_one):
			return false
	return true


func _drug_best(w: String) -> String:
	if w.contains("worried about a friend"):
		return "tell a trusted adult or call FRANK"
	if w.contains("offers you a pill"):
		return "say no and move away"
	if w.contains("will not wake"):
		return "call 999 at once"
	if w.contains("found a packet"):
		return "do not touch it: tell an adult"
	return "call FRANK or Childline, free and confidential"


func _win_win(c: String) -> String:
	if c.contains("computer"):
		return "take turns: half an hour each"
	if c.contains("football"):
		return "play football first, then tag"
	if c.contains("cake"):
		return "cut it in half and share"
	return "captain for one match each"


func _service(n: String) -> String:
	if n.contains("fire") or n.contains("not breathing"):
		return "999 or 112"
	if n.contains("earache"):
		return "111"
	if n.contains("worried"):
		return "a trusted adult or Childline, 0800 1111"
	if n.contains("online"):
		return "a trusted adult and the CEOP button"
	return "101, the police's non-emergency number"


func _material_why(part: String) -> String:
	return {"case": "tough, light and easy to mould", "lens": "clear and harder to shatter than glass",
		"spring": "springy and conducts electricity", "contacts": "conducts and does not rust",
		"reflector": "reflects light forward", "switch button": "soft, grippy and waterproof"}.get(part, "?")


func _process_of(part: String) -> String:
	if part.contains("plastic torch") or part.contains("plastic chair"):
		return "injection moulding"
	if part.contains("tray") or part.contains("lid"):
		return "vacuum forming"
	if part.contains("contact") or part.contains("door"):
		return "pressing (stamping)"
	return "casting"


func _scale(c: String) -> String:
	if c.contains("wedding") or c.contains("bridge") or c.contains("made-to-measure"):
		return "one-off"
	if c.contains("loaves") or c.contains("jumpers") or c.contains("posters"):
		return "batch"
	return "mass production"


func _alarm_input(job: String) -> String:
	return {"a door being opened": "a reed switch and a magnet", "someone stepping on a mat": "a pressure pad",
		"a bag being tipped or lifted": "a tilt switch", "the room getting dark": "an LDR (light sensor)",
		"a visitor pressing a button": "a push switch"}.get(job, "?")


func _alarm_why(q: String) -> String:
	if q.contains("resistor"):
		return "it limits the current so the LED won't burn out"
	if q.contains("stays dark"):
		return "that its long leg goes to the positive side"
	if q.contains("breadboard"):
		return "parts can be moved and tested without soldering"
	return "its tip is hot enough to burn, about 350 °C"


func _fabric(use: String) -> String:
	return {"a walking jacket for rainy hills": "a waterproof, breathable fabric",
		"a cyclist's vest for dark evenings": "reflective strips", "a cyclist's top for dull days": "fluorescent colours",
		"a firefighter's suit": "fire-resistant aramid fibres", "a top that tracks your heart rate":
		"a smart fabric with sensors", "a swimsuit that stretches and springs back": "elastane",
		"a winter hat that keeps heat in": "fleece that traps air"}.get(use, "?")


func _fabric_why(q: String) -> String:
	if q.contains("rain stay out"):
		return "its holes are smaller than a raindrop"
	if q.contains("sweat"):
		return "water vapour is far smaller than the holes"
	if q.contains("seams"):
		return "rain could get in through the stitch holes"
	return "glass beads send the light back to the driver"


func _staple(s: String) -> String:
	return {"rice": "warm, wet places, like South and East Asia", "wheat": "cooler, drier places, like Europe",
		"maize": "the Americas, where it was first grown", "cassava": "hot, tropical places, like much of Africa",
		"potatoes": "the Andes mountains of South America first"}.get(s, "?")


func _stage(c: String) -> String:
	if c.contains("dug") or c.contains("grown") or c.contains("pumped"):
		return "raw materials"
	if c.contains("moulded") or c.contains("production line"):
		return "manufacture"
	if c.contains("shipped") or c.contains("Lorries"):
		return "transport"
	if c.contains("boiled") or c.contains("washes"):
		return "use"
	return "end of life"


func _fair_best(c: String) -> String:
	return {"Which paper bridge holds most coins?": "same gap and coins; only the shape changes",
		"Which glue is strongest?": "same card and amount; only the glue changes",
		"Which wheel size makes the buggy roll furthest?": "same ramp and buggy; only the wheels change",
		"Which bag handle is most comfortable?": "same bag and load; only the handle changes",
		"You want to try five quick ideas for a phone stand's shape.": "card models",
		"You need exact sizes before making a mould.": "a CAD model",
		"You want to check a toy's gears really turn.": "a working prototype",
		"You want users to try how a game's menu feels.": "a clickable screen prototype",
		"The bag's handle cut into the tester's hand.": "make the handle wider, then test again",
		"The bridge held 40 coins, but the target is 50.": "add a triangle frame, then retest",
		"The lunch box leaks when tipped.": "add a seal round the lid, then test it again"}.get(c, "?")
