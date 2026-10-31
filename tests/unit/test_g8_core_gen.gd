extends GutTest
## Owner #70, #73 and #111, grade 8 maths, science and English generators for the research's last 14 units (G8CoreGen,
## SchoolGen source "g8k"): every generator makes a valid exercise at every level for 120 seeds, with a strategy hint, a
## worked answer and its `data`, and every answer is worked out again here from `data` (or the exercise's own picture
## and prompt) with this test's own rules and facts: expansions and factorisations, a parabola's values and crossings,
## the sides and ratios of right-angled triangles (with the true sine, cosine and tangent), pressure, depth and density,
## joules, kilowatt-hours and bills, temperature changes and bond energies, Ohm's law in series and parallel, the oxygen a
## breath keeps, selective breeding's parents and means; and the facts behind every choice, sort, match and order.

const SEEDS := 120
const SOURCE := "g8k."

## This test's own facts.
const EXO: Array[String] = ["a candle burning", "a campfire", "respiration in your cells", "an acid neutralising an alkali",
	"iron powder rusting in a hand warmer", "calcium oxide reacting with water", "a gel warmer's liquid crystallising",
	"a firework exploding"]
const ENDO: Array[String] = ["photosynthesis in a leaf", "heating limestone to make lime", "citric acid with baking soda",
	"ammonium nitrate dissolving in a cold pack", "baking soda breaking down in a hot oven", "ice melting",
	"urea dissolving in water"]
const WARMS := {"a cold pack for a sprained ankle": false, "a hand warmer for a winter walk": true,
	"a self-heating can of soup": true, "a cooling pad for a sore knee": false, "a heat pad for cold feet": true,
	"an ice-free cold pack for a picnic": false}
const WARM_USES: Array[String] = ["iron powder rusting fast", "calcium oxide reacting with water",
	"a gel pack's liquid crystallising"]
const COOL_USES: Array[String] = ["ammonium nitrate dissolving in water", "urea dissolving in water",
	"citric acid with baking soda"]
const DENSITY := {"cork": 0.24, "pine wood": 0.5, "oak wood": 0.75, "candle wax": 0.9, "ice": 0.92,
	"polypropylene plastic": 0.9, "PVC plastic": 1.4, "glass": 2.5, "granite": 2.7, "aluminium": 2.7, "iron": 7.9,
	"copper": 9.0, "lead": 11.3, "gold": 19.3}
const ROUTES := {
	"water through a plant": ["water in the soil", "a root hair cell", "the xylem in the root", "the xylem in the stem",
		"a leaf", "a stoma", "the air, as water vapour"],
	"blood through the heart": ["the vena cava", "the right atrium", "the right ventricle", "the pulmonary artery",
		"the lungs", "the pulmonary vein", "the left atrium", "the left ventricle", "the aorta"],
	"oxygen from the air into the blood": ["the nose or mouth", "the windpipe", "a bronchus", "a bronchiole",
		"an air sac (alveolus)", "a capillary", "a red blood cell"],
	"sugar from a leaf to a root": ["a leaf cell making sugar", "the phloem in the leaf", "the phloem in the stem",
		"the phloem in the root", "a root cell storing it"],
}
const JOB := {"xylem": "carries water and minerals up", "phloem": "carries sugars both ways",
	"root hair cells": "take in water from the soil", "stomata": "let water vapour out",
	"arteries": "carry blood away from the heart", "veins": "bring blood back to the heart",
	"capillaries": "pass substances to cells", "red blood cells": "carry oxygen", "plasma": "carries dissolved food",
	"white blood cells": "fight germs", "platelets": "help blood to clot", "valves": "stop blood flowing backwards",
	"alveoli": "let gases into and out of blood"}
const STEPS: Array[String] = ["decide which trait you want", "choose parents that show it most", "breed them together",
	"choose the young that show it most", "breed those, generation after generation"]
const BRED: Array[String] = ["dog breeds from wolves", "broccoli from wild cabbage", "cows that give more milk",
	"wheat with short, strong stems", "sheep with finer wool", "hens that lay more eggs", "roses with bigger flowers"]
const ENGINEERED: Array[String] = ["bacteria making human insulin", "Golden Rice making beta-carotene",
	"cotton that makes its own pest killer", "maize that resists insect pests", "papaya that resists a virus",
	"microbes making cheese-making enzymes"]
const BENEFITS: Array[String] = ["more food from the same land", "less pesticide sprayed", "medicines such as insulin",
	"crops that survive drought", "vitamins in everyday foods"]
const BEST_QUOTE := {"Kofi is careful.": "“checked the knot three times”", "Mei is nervous.": "“Mei's hands shook”",
	"The bakery is popular.": "“its queue reached the corner”", "Zara works carefully.": "“read the instructions twice”",
	"The flood was powerful.": "“swept the old bridge away”",
	"Bram is helpful.": "“stayed after the match to fold every chair”",
	"Ana cares about the race.": "“polished her trainers until they shone”",
	"The watch matters to Grandad.": "“touched it in his pocket every morning”",
	"The new boy feels shut out.": "“ate his lunch by the bins”"}
const SAID: Array[String] = ["Tilly set out six plates.", "Tilly checked the oven.", "The cat stared at the tank.",
	"Its tail was twitching.", "Rafi's phone buzzed.", "Rafi kept reading.", "Snow lay over the path.",
	"There were no footprints."]
const INFERRED: Array[String] = ["Tilly is expecting guests.", "Tilly has been baking.", "The cat wants the fish.",
	"The cat is alert.", "Rafi wants to finish reading.", "The messages can wait.", "Nobody has walked there since it snowed.",
	"It snowed not long ago."]
const OLD_OF := {"Jo keeps": "The Boy Who Cried Wolf", "A fast, boastful robot": "The Tortoise and the Hare",
	"A boy wishes": "King Midas", "Ignoring her teacher's warning": "Icarus", "Lina's stepfamily": "Cinderella",
	"A curious boy opens": "Pandora's box", "Two rival bakers'": "Romeo and Juliet", "After ten years": "the Odyssey",
	"A scientist builds": "Frankenstein"}
const TYPE_OF := {"Anansi the spider": "trickster", "Br'er Rabbit": "trickster", "Merlin": "mentor", "Athena": "mentor",
	"Theseus": "hero", "Hua Mulan": "hero", "the Minotaur": "monster", "Medusa": "monster", "Grandma Ifeoma": "mentor",
	"Pip, a market boy": "trickster", "the giant robot": "monster", "Sami, who leaves home": "hero",
	"old Mr Okafor": "mentor", "Nell, who swaps": "trickster"}
const PART_OF := {"Some say a garden takes too much time.": 1, "However, a rota needs only an hour a week.": 2,
	"80% of pupils said they would help.": 3, "Some argue it would make home time later.": 1,
	"Yet registration could be shorter instead.": 2, "Active pupils focus better after lunch.": 3,
	"Admittedly, staff would need extra pay.": 1, "Even so, volunteers could run it.": 2,
	"300 people signed a petition for it.": 3, "Some say cycle lanes slow down traffic.": 1,
	"However, fewer cars can mean less traffic.": 2, "More children cycle where lanes are safe.": 3,
	"It is true that trees take up space.": 1, "But trees round the edge leave room to play.": 2,
	"Trees cool a playground on hot days.": 3, "Our school should start a garden.": 0, "Lunch break should be longer.": 0,
	"The library should open on Saturdays.": 0, "Our town needs safe cycle lanes.": 0,
	"The school field needs more trees.": 0}
const PART_NAMES: Array[String] = ["the claim", "a counterclaim", "a rebuttal", "evidence"]
const BEST_SOURCE := {"how much sleep teenagers need": "a national health service's guidance",
	"whether a new medicine works": "a published study of many patients",
	"how fast the sea level is rising": "a national science agency's report",
	"the number of people living in a city": "the national statistics office",
	"whether a snack is healthy": "a health body's advice and the label"}
const CHECKS: Array[String] = ["Who wrote it, and what do they know?", "Can I find the same fact in another good source?",
	"Could the writer gain from what they say?"]
const FORMAL_OF := {"Loads of kids think the canteen food is rubbish.": "Many pupils are unhappy with the canteen food.",
	"You'd be mad not to recycle.": "Recycling is a sensible choice for everyone.",
	"Phones in class are a total nightmare.": "Phones in class can distract pupils.",
	"The new park is awesome and everyone loves it.": "The new park is popular with many residents.",
	"Homework is a massive waste of time, if you ask me.": "Too much homework may not help pupils learn.",
	"Kids these days never go outside.": "Many young people now spend less time outdoors."}
const GRAPHIC_OF := {"the steps of the water cycle": "a cycle diagram", "the water cycle's steps": "a cycle diagram",
	"the parts of a volcano": "a labelled diagram", "a volcano's parts": "a labelled diagram",
	"rainfall in each month of a year": "a bar chart", "rainfall each month": "a bar chart",
	"how a town's population grew since 1900": "a line graph", "a town's population since 1900": "a line graph",
	"three planets' sizes, moons and days": "a table", "three planets compared": "a table",
	"where the world's rainforests are": "a map", "where rainforests are": "a map",
	"a voyage's events, in order of date": "a timeline", "a voyage's events by date": "a timeline",
	"the share of each gas in the air": "a pie chart", "each gas's share of the air": "a pie chart",
	"how to make paper, step by step": "a flowchart", "making paper, step by step": "a flowchart"}
const WORD_OF := {"When water is heated, it ___ into the air.": "evaporates", "The heart ___ blood around the body.": "pumps",
	"A magnet ___ iron nails.": "attracts", "In autumn, many trees ___ their leaves.": "shed",
	"Water vapour ___ into droplets on a cold window.": "condenses", "The Moon ___ the Earth about once a month.": "orbits",
	"Green plants make sugar by ___.": "photosynthesis", "Wind and waves slowly ___ the cliff.": "erode",
	"The volcano ___ ash high into the sky.": "ejected", "A bridge's cables carry the deck's ___ to the towers.": "load"}
const DEFINITION_OF := {"erosion": "Erosion (rock being worn away) shapes coasts.",
	"a predator": "A predator (an animal that hunts) needs speed.",
	"condensation": "Condensation (gas turning to liquid) wets glass.",
	"a circuit": "A circuit (a complete loop) lets current flow."}
const TIME_ORDER: Array = [["Mo starts training for the race", "Mo falls and hurts his knee", "Mo's knee slowly heals",
	"Mo trains again, harder", "Mo crosses the finish line", "Mo holds up the medal"], ["Ana finds an old map in the attic",
	"Ana and Kofi set off", "a storm traps them in a cave", "they find the hidden cove", "the coastguard finds them",
	"Ana tells the story at school"], ["Great-grandad plants an acorn", "the oak grows taller than the house",
	"a storm breaks a branch", "the family mends the tree", "Kai sits in its shade"], ["Zara breaks Mei's model by accident",
	"Zara hides what she did", "Mei gets the blame", "Zara tells the truth", "the girls fix the model together"]]
const SHOWS := {"nervous": "Tilly's hands shook as she held the card.",
	"proud": "Bram hung his certificate right by the door.", "tired": "Mei's eyes closed before the bus left the stop.",
	"cold": "Kofi stamped his feet and blew on his fingers.", "excited": "Rafi ran to the door at every sound.",
	"kind": "Zara gave her umbrella to the man in the rain."}
const REFLECTIVE: Array[String] = ["Losing taught me more than winning ever did.",
	"Only later did I see how that day changed me.", "Now I see that asking for help was brave."]
const SIGNAL_OF := {"a jump back in time (a flashback)": "Three summers earlier,",
	"two things happening at the same time": "Meanwhile,", "a jump forward in time": "Years later,",
	"a return to the present after a flashback": "Now, back on the cliff,", "a move to a new place": "Across town,"}
const FLASHBACKS: Array[String] = ["She had never seen the sea before that day.", "He had trained for months before the race.",
	"They had lived by the river once."]
const MEDIA_OF := {"how a volcano erupts": "a short video clip", "a volcano erupting": "a short video clip",
	"how pupils travel to school": "a bar chart", "where the new park will be": "a map",
	"what the old harbour looked like": "an old photograph", "the old harbour, long ago": "an old photograph",
	"how a blackbird's song sounds": "a sound recording", "a blackbird's song": "a sound recording",
	"how the temperature changed over a year": "a line graph", "a year's temperatures": "a line graph",
	"the steps to make compost": "a flowchart", "making compost, step by step": "a flowchart"}
const DISTRACTING: Array[String] = ["loud music under your voice", "a spinning animated title", "a slide full of small text",
	"a joke picture with no link"]
const HELPS: Array[String] = ["a short title", "big, clear text", "one chart that makes the point", "key words only",
	"credit for a photo", "one idea a slide"]


func _gens() -> Array[String]:
	var out: Array[String] = []
	for g in SchoolGen.ids():
		if g.begins_with(SOURCE):
			out.append(g)
	return out


## The right answer as the child sees it: a choice's text, a number's value, a sort's or match's pairs, an order's items.
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


func _near(a: Variant, b: float, tolerance: float = 0.006) -> bool:
	return absf(float(a) - b) < tolerance


## This test's own polynomial writing: "2x² − 3x + 1".
func _poly(c2: int, c1: int, c0: int) -> String:
	var out := ""
	for pair: Array in [[c2, "x²"], [c1, "x"], [c0, ""]]:
		var c: int = pair[0]
		if c == 0:
			continue
		var mag := "" if absi(c) == 1 and pair[1] != "" else str(absi(c))
		if out == "":
			out = ("−" if c < 0 else "") + mag + str(pair[1])
		else:
			out += (" + " if c > 0 else " − ") + mag + str(pair[1])
	return out


## (x + a)(x + b) read back: [a, b], or [] when the text is not two such brackets.
func _brackets(t: String) -> Array:
	var m := RegEx.create_from_string("^\\(x ([+−]) (\\d+)\\)\\(x ([+−]) (\\d+)\\)$").search(t)
	if m == null:
		return []
	return [int(m.get_string(2)) * (1 if m.get_string(1) == "+" else -1), int(m.get_string(4)) * (1 if
		m.get_string(3) == "+" else -1)]


func _trig(f: String, deg: float) -> float:
	match f:
		"sin":
			return sin(deg_to_rad(deg))
		"cos":
			return cos(deg_to_rad(deg))
	return tan(deg_to_rad(deg))


func _inverse(f: String, v: float) -> float:
	match f:
		"sin":
			return rad_to_deg(asin(v))
		"cos":
			return rad_to_deg(acos(v))
	return rad_to_deg(atan(v))


func _side_value(t: String) -> float:
	return float(t.split(" ")[0])


func _pairs_ok(right: Dictionary, facts: Dictionary) -> String:
	for item: String in right:
		if str(facts.get(item, "?")) != str(right[item]):
			return "%s is %s" % [item, facts.get(item, "?")]
	return ""


func test_the_source_is_registered_last_and_has_its_generators() -> void:
	var keys: Array = SchoolGen.SOURCES.keys()
	assert_true(keys.has("g8k"), "g8k is a SOURCES line")
	assert_gt(keys.find("g8k"), maxi(keys.find("g8l"), keys.find("g8h")), "g8k comes after the earlier grade 8 sources")
	assert_gt(_gens().size(), 30, "the grade 8 core generators exist")


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
	assert_gt(checked, 13000, "answers checked")


## "" when `ex`'s answer is right by this test's own working; otherwise why not.
func _check(name: String, level: int, ex: Dictionary) -> String:
	var d: Dictionary = ex.data
	var right: Variant = _right(ex)
	var p := str(ex.prompt)
	match name:
		"expand_brackets":
			if level == 1:
				return "" if _near(right, int(d.k) * int(d.p) if d.ask == "x" else int(d.k) * int(d.q)) else "a(bx + c)"
			if level == 2:
				return "" if _near(right, int(d.p) + int(d.q) if d.ask == "x" else int(d.p) * int(d.q)) else "two brackets"
			var a := int(d.a)
			var b := int(d.b)
			var want := {"square_plus": _poly(1, 2 * a, a * a), "square_minus": _poly(1, -2 * a, a * a),
				"difference": _poly(1, 0, -a * a), "coefficient": _poly(2, 2 * b + a, a * b)}
			return "" if right == want[d.kind] else "expanded is %s" % want[d.kind]
		"factorise_quadratic":
			if level == 1:
				var k := int(d.k)
				var pp := int(d.p)
				var q := int(d.q)
				var g := 1
				for c in range(2, 10):
					if (k * pp) % c == 0 and (k * q) % c == 0:
						g = c
				var inner := ("x" if pp == 1 else "%dx" % pp) + " + %d" % q
				return "" if right == "%d(%s)" % [g, inner] and g == k else "the highest common factor"
			if level == 2:
				var m := RegEx.create_from_string("x² \\+ (\\d+)x \\+ (\\d+) = \\(x \\+ (\\d+)\\)").search(p)
				var b := int(m.get_string(1))
				var c := int(m.get_string(2))
				var pp := int(m.get_string(3))
				return "" if _near(float(right) * pp, c) and _near(float(right) + pp, b) else "the gap"
			var roots := _brackets(str(right))
			if roots.is_empty():
				return "not two brackets: %s" % right
			var want_b := int(d.p) + int(d.q) if d.kind == "trinomial" else 0
			var want_c := int(d.p) * int(d.q) if d.kind == "trinomial" else -int(d.n) * int(d.n)
			if int(roots[0]) + int(roots[1]) != want_b or int(roots[0]) * int(roots[1]) != want_c:
				return "%s does not expand back" % right
			for c: Variant in ex.choices:
				var other := _brackets(str(c))
				if str(c) != str(right) and other.size() == 2 and int(other[0]) + int(other[1]) == want_b and \
						int(other[0]) * int(other[1]) == want_c:
					return "two right choices"
			return ""
		"parabola_point":
			if level == 1:
				return "" if _near(right, int(d.x) * int(d.x) + int(d.c)) and int(ex.picture.c) == int(d.c) else "y"
			if level == 2:
				return "" if _near(right, d.n) and int(d.n) * int(d.n) == -int(ex.picture.c) else "the crossing"
			var pp := int(d.p)
			var q := int(d.q)
			if int(ex.picture.b) != -(pp + q) or int(ex.picture.c) != pp * q:
				return "the curve"
			return "" if _near(right, maxi(pp, q) if d.ask == "larger" else mini(pp, q)) else "the crossing"
		"trig_sides":
			if level == 1:
				return "" if right == str(d.sides[d.role]) else "the side"
			if level == 2:
				var both := [str(d.known), str(d.want)]
				var f := "sin" if both.has("opp") and both.has("hyp") else ("cos" if both.has("adj") and both.has("hyp")
					else "tan")
				var formula := {"sin": "sin x = opposite ÷ hypotenuse", "cos": "cos x = adjacent ÷ hypotenuse",
					"tan": "tan x = opposite ÷ adjacent"}
				return "" if right == formula[f] else "the ratio"
			var o := int(d.opp)
			var a := int(d.adj)
			var h := int(d.hyp)
			if o * o + a * a != h * h:
				return "not a right-angled triangle"
			var want := float(o) / h if d.ratio == "sin" else (float(a) / h if d.ratio == "cos" else float(o) / a)
			return "" if _near(right, want, 0.0001) else "the ratio's fraction"
		"trig_side":
			var angle := float(d.angle)
			var v := snappedf(_trig(str(d.ratio), angle), 0.01)
			if not _near(v, float(d.value), 0.0001) or not p.contains("= %.2f" % v):
				return "the ratio's value"
			var side := float(d.side)
			var want := snappedf(side * v, 0.01) if level < 3 else snappedf(side / v, 0.1)
			if not _near(right, want, 0.011):
				return "the side is %s" % want
			var unit := {"hyp": 1.0, "opp": sin(deg_to_rad(angle)), "adj": cos(deg_to_rad(angle))}
			var exact := side / float(unit[d.known]) * float(unit[d.want])
			return "" if absf(float(right) - exact) <= maxf(0.06, exact * 0.03) else "far from the true %s" % exact
		"trig_angle":
			var f := str(d.ratio)
			var angle := float(d.angle)
			if not _near(right, angle):
				return "the angle"
			if level == 1:
				var m := RegEx.create_from_string("= (\\d\\.\\d\\d)").search(p)
				return "" if absf(_inverse(f, float(m.get_string(1))) - angle) <= 1.0 else "the table"
			var top := 0.0
			var bottom := 1.0
			if level == 2:
				var nums := RegEx.create_from_string("(\\d+) cm").search_all(p)
				top = float(nums[0].get_string(1))
				bottom = float(nums[1].get_string(1))
			else:
				var sides: Dictionary = ex.picture.sides
				top = _side_value(str(sides.get("opp" if f != "cos" else "adj")))
				bottom = _side_value(str(sides.get("hyp" if f != "tan" else "adj")))
			return "" if absf(_inverse(f, top / bottom) - angle) <= 1.0 else "the sides make %s°" % _inverse(f, top / bottom)
		"pressure_calc":
			if level == 1 or (level == 2 and d.has("force")):
				return "" if _near(right, float(d.force) / float(d.area)) else "force ÷ area"
			if level == 2:
				return "" if _near(right, float(d.pressure) * float(d.area)) else "pressure × area"
			var sides: Array = d.sides
			var faces := [int(sides[0]) * int(sides[1]), int(sides[0]) * int(sides[2]), int(sides[1]) * int(sides[2])]
			return "" if _near(right, float(d.force) / float(faces.min())) else "the smallest face"
		"depth_pressure":
			if level == 1:
				if d.has("depths"):
					return "" if right == "%d m down" % int((d.depths as Array).max()) else "the deepest"
				return "" if right == "the bottom hole" else "the deepest hole"
			if level == 2:
				return "" if _near(right, 10 * int(d.depth)) else "10 kPa a metre"
			return "" if _near(right, 100 + 10 * int(d.depth) if d.find == "total" else int(d.depth)) else "the total"
		"float_sink":
			if level == 1:
				var floats := float(DENSITY[d.material]) < 1.0
				return "" if right == ("it floats" if floats else "it sinks") else "float or sink"
			if level == 2:
				return "" if _near(right, float(d.mass) / int(d.volume)) else "mass ÷ volume"
			if d.has("material"):
				return "" if _near(right, DENSITY[d.material]) else "the part under water"
			return "" if _near(right, d.mass) else "the water pushed aside"
		"energy_joules":
			if level == 1:
				return "" if _near(right, int(d.watts) * int(d.seconds)) else "W × s"
			if level == 2:
				return "" if _near(right, int(d.watts) * int(d.minutes) * 60 / 1000.0) else "kJ"
			return "" if _near(right, float(d.joules) / int(d.seconds)) else "J ÷ s"
		"energy_kwh":
			if level == 1:
				return "" if _near(right, int(d.kw) * int(d.hours)) else "kW × h"
			if level == 2:
				return "" if _near(right, int(d.watts) / 1000.0 * int(d.minutes) / 60.0, 0.0011) else "kWh"
			var total := 0.0
			for row: Array in (d.rows as Array).slice(1):
				total += float(str(row[1]).replace(" W", "").replace(",", "")) / 1000.0 * float(row[2])
			return "" if _near(right, total, 0.0011) else "the day's kWh"
		"energy_cost":
			if level == 1:
				return "" if _near(right, int(d.used)) and SchoolPictureG8Core.meter_used(ex.picture) == int(d.used) else "units"
			if level == 2:
				return "" if _near(right, int(d.used) * float(d.price)) else "units × price"
			return "" if _near(right, int(d.used) * float(d.price) + 7 * float(d.charge)) else "the bill"
		"temp_change":
			if level == 1:
				var warmer := int(d.after) > int(d.before)
				return "" if str(right).begins_with("exothermic" if warmer else "endothermic") else "exo or endo"
			if level == 2:
				return "" if _near(right, absi(int(d.after) - int(d.before))) else "the change"
			var rows: Array = ex.picture.rows
			var best := ""
			var top := -100
			var falls: Array[String] = []
			for row: Array in rows.slice(1):
				var change := int(row[2]) - int(row[1])
				if change > top:
					top = change
					best = str(row[0])
				if change < 0:
					falls.append(str(row[0]))
			if d.ask == "most heat":
				return "" if right == "mixture " + best else "the biggest rise is %s" % best
			return "" if falls.size() == 1 and right == "mixture " + falls[0] else "the fall"
		"reaction_type":
			if level == 1:
				return "" if str(right).begins_with("exothermic" if EXO.has(d.item) else "endothermic") and \
					(EXO.has(d.item) or ENDO.has(d.item)) else "exo or endo"
			if level == 2:
				for item: String in right:
					var want := "gives out heat" if EXO.has(item) else ("takes in heat" if ENDO.has(item) else "?")
					if right[item] != want:
						return "%s %s" % [item, want]
				return ""
			var warm: bool = WARMS[d.device]
			return "" if (WARM_USES if warm else COOL_USES).has(right) else "the device's change"
		"bond_energy":
			if level == 1:
				var r := int(d.reactants)
				var pr := int(d.products)
				var said_out := p.contains("given out")
				return "" if _near(right, absi(r - pr)) and said_out == (pr < r) else "the change"
			var exo := int(d.made) > int(d.broken)
			if level == 2:
				return "" if right == ("exothermic" if exo else "endothermic") else "the bonds"
			return "" if _near(right, absi(int(d.made) - int(d.broken))) and p.contains("given out") == exo else "overall"
		"ohms_law":
			if level == 1:
				return "" if _near(right, float(d.amps) * int(d.ohms)) else "V = IR"
			if level == 2:
				return "" if _near(right, float(d.volts) / int(d.ohms)) else "I = V ÷ R"
			return "" if _near(right, float(d.volts) / float(d.amps)) else "R = V ÷ I"
		"series_volts":
			var total := 0
			for o: Variant in d.ohms:
				total += int(o)
			var amps := float(d.volts) / total
			if level == 1:
				return "" if _near(right, float(d.volts) - amps * int(d.ohms[0])) else "the shared voltage"
			if level == 2:
				return "" if _near(right, amps) else "the current"
			var k := int(str(ex.picture.meters[0][1]))
			return "" if _near(right, amps * int(d.ohms[k])) else "the part's voltage"
		"parallel_amps":
			var v := float(d.volts)
			var total := 0.0
			for o: Variant in d.ohms:
				total += v / int(o)
			if level == 2:
				return "" if _near(right, v / int(d.ohms[1]), 0.011) else "the other branch"
			return "" if _near(right, total, 0.011) else "the branches' sum"
		"transport_route":
			var route: Array = ROUTES[d.route]
			var want := route.slice(int(d.start), int(d.start) + int(d.n))
			return "" if right == want else "the route"
		"transport_job":
			if level == 1:
				return "" if right == JOB[d.part] else "the job"
			if level == 2:
				return _pairs_ok(right, JOB)
			return "" if right == d.part and p.contains(JOB[d.part]) else "the part"
		"air_in_out":
			var vol := int(d.volume)
			if level == 1:
				return "" if _near(right, vol * 0.21) else "21%"
			if level == 2:
				return "" if _near(right, vol * 0.05) else "21% − 16%"
			return "" if _near(right, vol * 0.05 * int(d.rate)) else "a minute"
		"breed_pick":
			if level == 1:
				var scores: Array = d.scores
				var names: Array = d.names
				var order: Array = range(4)
				order.sort_custom(func(a: int, b: int) -> bool: return int(scores[a]) > int(scores[b]))
				var two := [names[order[0]], names[order[1]]]
				two.sort()
				return "" if right == "%s and %s" % [two[0], two[1]] else "the parents"
			if level == 2:
				return "" if right == STEPS else "the steps"
			return "" if _near(right, int(d.start) + int(d.add) * int(d.generations)) else "the mean"
		"gm_or_bred":
			if level == 1:
				var bred := BRED.has(d.item)
				return "" if right == ("by selective breeding" if bred else "by genetic engineering") and (bred or
					ENGINEERED.has(d.item)) else "bred or engineered"
			for item: String in right:
				var want := ""
				if level == 2:
					want = "selective breeding" if BRED.has(item) else "genetic engineering"
				else:
					want = "a benefit" if BENEFITS.has(item) else "a worry or question"
				if right[item] != want:
					return "%s %s" % [item, want]
			return ""
		"evidence_pick":
			return "" if right == BEST_QUOTE.get(d.claim, "?") and p.contains(str(right).trim_prefix("“").trim_suffix("”")) \
				else "the strongest words"
		"evidence_kind":
			if level == 1:
				return "" if (SAID.has(d.statement) == str(right).begins_with("said")) and (SAID.has(d.statement) or
					INFERRED.has(d.statement)) else "said or inferred"
			if level == 2:
				for item: String in right:
					if right[item] != ("said (explicit)" if SAID.has(item) else "inferred") or not (SAID.has(item) or
							INFERRED.has(item)):
						return "%s" % item
				return ""
			return "" if INFERRED.has(right) else "the inference"
		"story_pattern":
			for start: String in OLD_OF:
				if str(d.story).begins_with(start):
					return "" if right == OLD_OF[start] else "the older story"
			return "unknown story"
		"archetype_match":
			if level == 2:
				return _pairs_ok(right, TYPE_OF)
			for start: String in TYPE_OF:
				if str(d.character).begins_with(start):
					return "" if right == TYPE_OF[start] else "the type"
			return "unknown character"
		"argument_part":
			if level == 1:
				var sentence := RegEx.create_from_string("this sentence: “(.+)”\\?$").search(p).get_string(1)
				return "" if right == PART_NAMES[int(PART_OF[sentence])] else "the part"
			if level == 2:
				for item: String in right:
					if not PART_OF.has(item) or right[item] != ["claim", "counterclaim", "rebuttal", "evidence"][int(PART_OF[item])]:
						return item
				return ""
			var parts: Array = right.map(func(t: String) -> int: return int(PART_OF.get(t, -1)))
			return "" if parts == [0, 3, 1, 2, -1] else "the order"
		"credible_source":
			if level == 1:
				return "" if right == BEST_SOURCE[d.topic] else "the best source"
			if level == 2:
				return "" if right != BEST_SOURCE[d.topic] and (ex.choices as Array).has(BEST_SOURCE[d.topic]) else "the worst"
			return "" if CHECKS.has(right) else "the check"
		"formal_style":
			return "" if right == FORMAL_OF[d.informal] else "the formal version"
		"graphic_pick":
			if level == 2:
				return _pairs_ok(right, GRAPHIC_OF)
			return "" if right == GRAPHIC_OF[d.info] else "the graphic"
		"precise_word":
			if d.has("term"):
				return "" if right == DEFINITION_OF[d.term] else "the definition"
			return "" if right == WORD_OF[d.sentence] else "the word"
		"time_order":
			for story: Array in TIME_ORDER:
				if story.has(right[0]):
					var idx: Array = right.map(func(t: String) -> int: return story.find(t))
					var sorted := idx.duplicate()
					sorted.sort()
					return "" if idx == sorted and not idx.has(-1) and idx[-1] == story.size() - 1 else "time order"
			return "unknown story"
		"telling_detail":
			if level == 1:
				return "" if right == SHOWS[d.feeling] else "the detail"
			if level == 2:
				for item: String in right:
					if right[item] != ("shows" if SHOWS.values().has(item) else "tells"):
						return item
				return ""
			return "" if REFLECTIVE.has(right) else "the reflection"
		"shift_signal":
			if level == 3:
				return "" if FLASHBACKS.has(right) else "the flashback"
			return "" if right == SIGNAL_OF[d.shift] else "the signal"
		"media_pick":
			if level == 1:
				return "" if right == MEDIA_OF[d.point] else "the media"
			if level == 2:
				return _pairs_ok(right, MEDIA_OF)
			return "" if DISTRACTING.has(right) else "the distraction"
		"slide_rule":
			if level == 1:
				return "" if HELPS.has(right) else "a good habit"
			if level == 2:
				for item: String in right:
					if right[item] != ("helps the audience" if HELPS.has(item) else "distracts them"):
						return item
				return ""
			return "" if right == "cut it to a few key words, in big text" and bool(ex.picture.busy) else "the fix"
	return "no check for %s" % name


## Every generator's choices never give the right one away in the hint.
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
