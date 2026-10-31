extends GutTest
## Owner #70, #73 and #111, grade 7's last maths, science and English units (G7CoreGen, "g7k"; research §6.7): primes,
## factor trees, HCF and LCM, rounding, estimates, speed, distance-time graphs, cut axes, charts and scaled pictures; the
## periodic table, separating mixtures, chromatograms, pH and indicators, salts, colour, refraction, the spectrum, the
## air and the carbon cycle, combustion; evidence, quotes, history and fiction, ethos, pathos and logos, tricks,
## rebuttals, faulty reasoning, signal words, precise words, points of view and the senses. Each answer is worked out
## again here from the exercise's picture and `data` with this file's own arithmetic, facts and rules (typed apart from
## the generator's tables), for many seeds and every level, and every exercise must be valid.

const SEEDS := 60
const GENS: Array[String] = ["prime_pick", "factorise", "hcf_lcm", "round_dp", "round_sf", "estimate_calc", "speed_calc",
	"speed_convert", "dt_read", "average_speed", "cut_axis_look", "best_chart", "picture_scale", "element_place",
	"metal_sort", "element_symbol", "separate_method", "chroma_read", "mixture_words", "ph_kind", "indicator_colour",
	"salt_name", "colour_seen", "refraction_bend", "spectrum_order", "air_share", "carbon_process", "burn_products",
	"evidence_pick", "quote_or_paraphrase", "fact_or_fiction", "out_of_time", "appeal_kind", "speech_trick",
	"rebuttal_pick", "reasoning_flaw", "signal_word", "precise_term", "pov_name", "sense_detail"]

## The first 20 elements: [symbol, name, school group (0: noble gases), period, metal?].
const FIRST20: Array = [["H", "hydrogen", 1, 1, false], ["He", "helium", 0, 1, false], ["Li", "lithium", 1, 2, true],
	["Be", "beryllium", 2, 2, true], ["B", "boron", 3, 2, false], ["C", "carbon", 4, 2, false],
	["N", "nitrogen", 5, 2, false], ["O", "oxygen", 6, 2, false], ["F", "fluorine", 7, 2, false],
	["Ne", "neon", 0, 2, false], ["Na", "sodium", 1, 3, true], ["Mg", "magnesium", 2, 3, true],
	["Al", "aluminium", 3, 3, true], ["Si", "silicon", 4, 3, false], ["P", "phosphorus", 5, 3, false],
	["S", "sulfur", 6, 3, false], ["Cl", "chlorine", 7, 3, false], ["Ar", "argon", 0, 3, false],
	["K", "potassium", 1, 4, true], ["Ca", "calcium", 2, 4, true]]
const MORE_SYMBOLS := {"iron": "Fe", "copper": "Cu", "zinc": "Zn", "silver": "Ag", "tin": "Sn", "gold": "Au",
	"mercury": "Hg", "lead": "Pb", "iodine": "I", "bromine": "Br"}
const METALS: Array[String] = ["iron", "copper", "gold", "silver", "sodium", "magnesium", "aluminium", "zinc", "calcium",
	"potassium", "lead", "tin", "mercury", "lithium"]
const CHARTS := {"temperature every hour": "line graph", "sunflower's height": "line graph",
	"population every ten years": "line graph", "like each kind of fruit": "bar chart", "each team scored": "bar chart",
	"cars of each colour": "bar chart", "24 hours are spent": "pie chart", "used for each crop": "pie chart",
	"gets to school": "pie chart", "arm span": "scatter graph", "ice creams sold": "scatter graph"}
const METHOD_OF := {"sand from": "filtering", "chalk from": "filtering", "mud from": "filtering",
	"tea leaves": "filtering", "salt from": "evaporating", "sugar from": "evaporating", "blue crystals": "evaporating",
	"from sea water": "distilling", "from inky water": "distilling", "felt-tip": "chromatography",
	"food colouring": "chromatography", "iron filings": "a magnet", "pebbles": "a sieve"}
const WORD_MEANS := {"solute": "dissolves", "solvent": "liquid it dissolves in", "solution": "solute dissolved",
	"soluble": "able to dissolve", "insoluble": "not able", "residue": "filter keeps back",
	"filtrate": "passes a filter", "distillate": "distilling"}
const PH_OF := {"stomach acid": 1.0, "lemon juice": 2.0, "vinegar": 3.0, "tomato juice": 4.0, "black coffee": 5.0,
	"pure water": 7.0, "salty water": 7.0, "sugar water": 7.0, "baking soda": 8.0, "soap": 10.0,
	"household ammonia": 11.0, "bleach": 12.0, "oven cleaner": 13.0, "drain cleaner": 14.0}
const REFLECTS := {"white": ["red", "green", "blue"], "black": [], "red": ["red"], "green": ["green"], "blue": ["blue"],
	"yellow": ["red", "green"]}
const RAINBOW: Array[String] = ["red", "orange", "yellow", "green", "blue", "indigo", "violet"]
const ADDS := {"photosynthesis": false, "respiration": true, "burning coal": true, "a forest growing": false,
	"decomposers breaking down dead leaves": true, "burning petrol in a car": true, "burning wood": true,
	"a volcano erupting": true, "seaweed growing in the sea": false, "plankton making food from sunlight": false}
const AIR := {"nitrogen": 78.0, "oxygen": 21.0, "argon": 1.0}
const STRONGEST := {"Sam is nervous.": "hands shook", "The village is poor.": "patched", "Leo is generous.": "last coin",
	"The house is empty.": "Weeds", "Mira is brave.": "Knees shaking", "Tom feels left out.": "wishing",
	"The king is greedy.": "kept the harvest", "Ana loves the sea.": "happiest", "Jun changes during the story.": "at first",
	"The storm frightens the crew.": "gripped", "The town trusts the doctor.": "sent for", "Kit is clever.": "hairpin"}
const HISTORY_BY := ["1476", "Canterbury Tales", "By 1500", "In 1610", "1632", "prologues"]
const LATER := {"a bicycle": 1817, "an electric light": 1879, "a train ticket": 1825, "a telephone": 1876,
	"an aeroplane": 1903, "a light bulb": 1879, "a camera": 1839, "a radio": 1895, "a steam train": 1872, "a car": 1886,
	"electric street lights": 1878, "a motor car": 1886, "an electric fan": 1882, "a plastic bottle": 1947,
	"potatoes for dinner": 1580, "a cup of tea": 1650, "a telescope": 1608, "a tomato salad": 1590,
	"a printed newspaper": 1605, "chocolate to drink": 1520, "a pocket telescope": 1608, "a potato field": 1570}
const APPEAL_BY := {"doctor": "ethos", "library": "ethos", "librar": "ethos", "scientists": "ethos", "puppy": "pathos",
	"proud": "pathos", "lost pet": "pathos", "20 minutes": "logos", "300 gold": "logos", "surveys": "logos"}
const TRICK_BY := {"disastrous": "loaded words", "Everyone in the": "exaggeration", "Sam": "attacking the person",
	"cousin": "one story as proof", "shameful": "loaded words", "Nobody": "exaggeration", "Mo": "attacking the person",
	"gran": "one story as proof"}
const REBUT_BY := {"garden": "club", "bridge": "long road", "later start": "sleep enough", "library": "no books",
	"leaves": "compost"}
const FLAW_BY := {"trainers": "following the crowd", "Everyone buys": "following the crowd",
	"tourists": "too few examples", "Two were rude": "too few examples", "ban phones": "a false choice",
	"Ban them": "a false choice", "twelve": "attacking the person", "Lots of people": "following the crowd",
	"Lots believe": "following the crowd", "One apple": "too few examples", "One bad apple": "too few examples",
	"bridge today": "a false choice", "spell": "attacking the person"}
const SIGNAL_OF := {"Frogs have smooth": "whereas", "Both frogs": "Similarly", "The desert is dry": "however",
	"a bat": "Unlike", "Heavy rain": "as a result", "The ice melted": "because", "The forest was cut": "so",
	"Plants need light": "Therefore"}
const COMPARE: Array[String] = ["whereas", "similarly", "however", "unlike", "likewise", "in contrast"]
const PRECISE_OF := {"a lot of rain": "50 mm", "animals that live in water and on land": "amphibians",
	"got bigger": "expanded", "a long time ago": "1476", "a big wave": "3-metre", "really cold": "−20 °C",
	"went down": "fell by 20%", "the thing that pumps blood": "the heart", "lots of people": "4,000"}
const POV_BY := {"I pushed": "first person", "We ran": "first person", "I knew": "first person",
	"Zara stared": "third person limited", "Zara was sure": "third person limited",
	"Bram climbed": "third person limited", "Tilly smiled": "third person limited",
	"Zara thought": "third person omniscient", "Zara feared": "third person omniscient",
	"Every villager": "third person omniscient", "All hoped": "third person omniscient",
	"Leo felt": "third person omniscient"}
const SENSE_BY := {"sky": "sight", "floorboards": "sound", "smoke": "smell", "salty": "taste", "bark": "touch",
	"bell": "sound", "bread": "smell", "lemon": "taste", "icy": "touch", "kite": "sight"}


func _each(gen: String, check: Callable) -> void:
	for level in [1, 2, 3]:
		for s in SEEDS:
			var ex := SchoolGen.make("g7k." + gen, s, level)
			assert_false(ex.is_empty(), "%s makes an exercise" % gen)
			if ex.is_empty():
				return
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [gen, ex.get("prompt", "")])
			assert_ne(str(ex.get("explain", "")), "", "%s: a worked answer" % gen)
			assert_ne(str(ex.get("hint", "")), str(ex.get("explain", "")), "%s: the hint is a strategy" % gen)
			assert_true(ex.get("data") is Dictionary, "%s: its data" % gen)
			if ex.has("picture"):
				assert_eq(SchoolPicture.problem(ex.picture), "", "%s: its picture" % gen)
			if ExerciseCheck.problem(ex) == "" and ex.get("data") is Dictionary:
				check.call(ex, level)


func _num(ex: Dictionary) -> float:
	return NumberAnswer.value(str(ex.answer))


func _answer(ex: Dictionary) -> String:
	return ExerciseCheck.answer_text(ex)


## Each sorted item's group name.
func _sorted(ex: Dictionary) -> Dictionary:
	var out := {}
	for i in (ex.items as Array).size():
		out[str(ex.items[i])] = str(ex.groups[int(ex.answer[i])])
	return out


## Each matched item's partner.
func _matched(ex: Dictionary) -> Dictionary:
	var out := {}
	for i in (ex.items as Array).size():
		out[str(ex.items[i])] = str(ex.matches[int(ex.answer[i])])
	return out


func _prime(n: int) -> bool:
	if n < 2:
		return false
	var d := 2
	while d * d <= n:
		if n % d == 0:
			return false
		d += 1
	return true


func _factors(n: int) -> Array[int]:
	var out: Array[int] = []
	var d := 2
	while n > 1:
		while n % d == 0:
			out.append(d)
			n /= d
		d += 1
	return out


func _gcd(a: int, b: int) -> int:
	return a if b == 0 else _gcd(b, a % b)


## A whole number above 0 rounded half up to 1 significant figure.
func _one_sf(x: float) -> float:
	var p := pow(10.0, floorf(log(x) / log(10.0) + 0.0000001))
	return floorf(x / p + 0.5) * p


func _by_phrase(table: Dictionary, text: String) -> String:
	for k: String in table:
		if text.contains(k):
			return str(table[k])
	return "?"


func test_every_generator_is_tested_here() -> void:
	var mine: Array[String] = []
	for id in SchoolGen.ids():
		if id.begins_with("g7k."):
			mine.append(id.trim_prefix("g7k."))
	mine.sort()
	var listed := GENS.duplicate()
	listed.sort()
	assert_eq(mine, listed, "every g7k generator has its test")


func test_primes() -> void:
	_each("prime_pick", _c_prime_pick)


func test_factorise() -> void:
	_each("factorise", _c_factorise)


func test_hcf_and_lcm() -> void:
	_each("hcf_lcm", _c_hcf_lcm)


func test_rounding() -> void:
	_each("round_dp", _c_round_dp)
	_each("round_sf", _c_round_sf)


func test_estimates() -> void:
	_each("estimate_calc", _c_estimate_calc)


func test_speed() -> void:
	_each("speed_calc", _c_speed_calc)
	_each("speed_convert", _c_speed_convert)
	_each("average_speed", _c_average_speed)


func test_distance_time_graphs() -> void:
	_each("dt_read", _c_dt_read)


func test_misleading_graphs() -> void:
	_each("cut_axis_look", _c_cut_axis_look)
	_each("best_chart", _c_best_chart)
	_each("picture_scale", _c_picture_scale)


var by_symbol := {}
var by_name := {}


func before_all() -> void:
	for e: Array in FIRST20:
		by_symbol[str(e[0])] = e
		by_name[str(e[1])] = e


func test_the_periodic_table() -> void:
	_each("element_place", _c_element_place)
	_each("metal_sort", _c_metal_sort)
	_each("element_symbol", _c_element_symbol)


func test_separating_mixtures() -> void:
	_each("separate_method", _c_separate_method)
	_each("chroma_read", _c_chroma_read)
	_each("mixture_words", _c_mixture_words)


func test_acids_and_alkalis() -> void:
	_each("ph_kind", _c_ph_kind)
	_each("indicator_colour", _c_indicator_colour)
	_each("salt_name", _c_salt_name)


func test_light_and_colour() -> void:
	_each("colour_seen", _c_colour_seen)
	_each("refraction_bend", _c_refraction_bend)
	_each("spectrum_order", _c_spectrum_order)


func test_the_air_and_the_carbon_cycle() -> void:
	_each("air_share", _c_air_share)
	_each("carbon_process", _c_carbon_process)
	_each("burn_products", _c_burn_products)


func test_evidence_and_quotes() -> void:
	_each("evidence_pick", _c_evidence_pick)
	_each("quote_or_paraphrase", _c_quote_or_paraphrase)


func test_fiction_and_history() -> void:
	_each("fact_or_fiction", _c_fact_or_fiction)
	_each("out_of_time", _c_out_of_time)


func test_speeches() -> void:
	_each("appeal_kind", _c_appeal_kind)
	_each("speech_trick", _c_speech_trick)


func test_arguments() -> void:
	_each("rebuttal_pick", _c_rebuttal_pick)
	_each("reasoning_flaw", _c_reasoning_flaw)


func test_informative_writing() -> void:
	_each("signal_word", _c_signal_word)
	_each("precise_term", _c_precise_term)


func test_narrative_writing() -> void:
	_each("pov_name", _c_pov_name)
	_each("sense_detail", _c_sense_detail)


func _c_prime_pick(ex: Dictionary, level: int) -> void:
	if level == 3:
		for it: String in _sorted(ex):
			assert_eq(_sorted(ex)[it], "prime" if _prime(int(it)) else "not prime", it)
	else:
		assert_true(_prime(int(_answer(ex))), "%s is prime" % _answer(ex))
		for c: Variant in ex.choices:
			if str(c) != _answer(ex):
				assert_false(_prime(int(str(c))), "%s is not prime" % c)


func _c_factorise(ex: Dictionary, level: int) -> void:
	var n := int(ex.data.n)
	match level:
		1:
			assert_eq(int(_num(ex)), _factors(n)[int(ex.data.hide)], str(n))
			var product := 1
			for p in _factors(n):
				product *= p
			assert_eq(product, n)
		2:
			var said := _answer(ex)
			var product := 1
			for part in said.split(" × "):
				var base := int(part.substr(0, 1) if part.length() > 1 and not part[1].is_valid_int() else part)
				var power := 1
				var sup := {"²": 2, "³": 3, "⁴": 4, "⁵": 5, "⁶": 6, "⁷": 7}
				for k: String in sup:
					if part.ends_with(k):
						base = int(part.trim_suffix(k))
						power = int(sup[k])
				assert_true(_prime(base), "%s: %d is prime" % [said, base])
				product *= int(pow(base, power))
			assert_eq(product, n, said)
		3:
			assert_eq(int(_num(ex)), n)


func _c_hcf_lcm(ex: Dictionary, _level: int) -> void:
	var a := int(ex.data.a)
	var b := int(ex.data.b)
	var want := _gcd(a, b) if str(ex.data.ask) == "hcf" else a * b / _gcd(a, b)
	assert_eq(int(_num(ex)), want, str(ex.prompt))
	assert_true(str(ex.prompt).to_lower().contains(str(ex.data.ask)) or ex.prompt.contains("together")
		or ex.prompt.contains("meet") or ex.prompt.contains("most") or ex.prompt.contains("biggest")
		or ex.prompt.contains("as long as possible"), str(ex.prompt))


func _c_round_dp(ex: Dictionary, level: int) -> void:
	var m := int(ex.data.m)
	var digits := int(ex.data.digits)
	assert_eq(int(ex.data.places), level)
	var x := float(m) / pow(10.0, digits)
	var want := floorf(x * pow(10.0, level) + 0.5 + 0.000001) / pow(10.0, level)
	assert_almost_eq(_num(ex), want, 0.0000001, str(ex.prompt))


func _c_round_sf(ex: Dictionary, _level: int) -> void:
	var m := int(ex.data.m)
	var e := int(ex.data.e)
	var sf := int(ex.data.sf)
	var d := str(m).length()
	var q := floorf(m / pow(10.0, d - sf) + 0.5 + 0.0000001)
	var want := q * pow(10.0, e + d - sf)
	assert_almost_eq(_num(ex), want, absf(want) * 0.000001, str(ex.prompt))


func _c_estimate_calc(ex: Dictionary, level: int) -> void:
	var a := float(ex.data.a) / 10.0
	var b := float(ex.data.b) / 10.0
	var est := _one_sf(a) * _one_sf(b) if level != 2 else _one_sf(a) / _one_sf(b)
	assert_almost_eq(float(ex.data.estimate), est, 0.0001, str(ex.prompt))
	match level:
		1:
			assert_almost_eq(float(_answer(ex).replace(",", "")), est, 0.0001)
		2:
			assert_almost_eq(_num(ex), est, 0.0001)
		3:
			var shown := float(ex.data.shown)
			var close := absf(shown - a * b) < a * b * 0.02
			assert_eq(_answer(ex).begins_with("Yes"), close, "%s: %s" % [ex.prompt, _answer(ex)])
			assert_true(_answer(ex).contains(GenKit.fmt(int(est))), _answer(ex))


func _c_speed_calc(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	match str(d.ask):
		"speed":
			assert_almost_eq(_num(ex), float(d.d) / (float(d.t_min) / 60.0), 0.0001, str(ex.prompt))
		"distance":
			assert_almost_eq(_num(ex), float(d.s) * float(d.t_min) / 60.0, 0.0001, str(ex.prompt))
		"time":
			assert_almost_eq(_num(ex), float(d.d) / float(d.s) * 60.0, 0.0001, str(ex.prompt))


func _c_speed_convert(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_almost_eq(_num(ex), float(ex.data.mps) * 3600.0 / 1000.0, 0.0001)
		2:
			assert_almost_eq(_num(ex), float(ex.data.kmh) * 1000.0 / 3600.0, 0.0001)
		3:
			var mps_in_kmh := float(ex.data.mps) * 3.6
			assert_eq(_answer(ex), "%d m/s" % ex.data.mps if mps_in_kmh > float(ex.data.kmh) else "%d km/h" % ex.data.kmh)


func _c_average_speed(ex: Dictionary, level: int) -> void:
	var d: Dictionary = ex.data
	if d.has("t_half_hours"):
		assert_almost_eq(_num(ex), float(d.d) / (float(d.t_half_hours) / 2.0), 0.0001, str(ex.prompt))
	else:
		var t := float(d.d) / float(d.s1) + float(d.d) / float(d.s2)
		assert_almost_eq(_num(ex), 2.0 * float(d.d) / t, 0.0001, str(ex.prompt))
		assert_ne(_num(ex), (float(d.s1) + float(d.s2)) / 2.0, "not halfway between the speeds")


func _c_dt_read(ex: Dictionary, _level: int) -> void:
	var pts: Array = ex.data.points
	assert_eq(float(pts[1][1]), float(pts[2][1]), "leg B is a stop")
	match str(ex.data.ask):
		"stop":
			assert_almost_eq(_num(ex), float(pts[2][0]) - float(pts[1][0]), 0.0001)
		"distance":
			assert_almost_eq(_num(ex), float(pts[1][1]), 0.0001)
		"leg":
			var i := int(ex.data.leg)
			var km := float(pts[i + 1][1]) - float(pts[i][1])
			var minutes := float(pts[i + 1][0]) - float(pts[i][0])
			assert_almost_eq(_num(ex), km / minutes * 60.0, 0.0001)
			assert_eq(int(ex.picture.mark), i, "the leg is marked")
		"average":
			assert_almost_eq(_num(ex), float(pts[3][1]) / float(pts[3][0]) * 60.0, 0.0001)
		"faster":
			var sa := (float(pts[1][1]) - float(pts[0][1])) / (float(pts[1][0]) - float(pts[0][0]))
			var sc := (float(pts[3][1]) - float(pts[2][1])) / (float(pts[3][0]) - float(pts[2][0]))
			assert_eq(_answer(ex), "leg A" if sa > sc else ("leg C" if sc > sa else "both the same"))


func _c_cut_axis_look(ex: Dictionary, _level: int) -> void:
	var a := float(ex.data.a)
	var b := float(ex.data.b)
	var f := float(ex.data.from)
	assert_eq(float(ex.picture.from), f)
	match str(ex.data.ask):
		"looks":
			assert_almost_eq(_num(ex), (b - f) / (a - f), 0.0001)
		"percent":
			assert_almost_eq(_num(ex), (b - a) / a * 100.0, 0.0001)
		"fair":
			assert_almost_eq(_num(ex), b / a, 0.0001)


func _c_best_chart(ex: Dictionary, level: int) -> void:
	if level == 3:
		var sorted := _sorted(ex)
		for it: String in sorted:
			assert_eq(sorted[it], _by_phrase(CHARTS, it), it)
	else:
		assert_eq(_answer(ex), _by_phrase(CHARTS, str(ex.prompt)), str(ex.prompt))


func _c_picture_scale(ex: Dictionary, level: int) -> void:
	var k := float(ex.data.k)
	assert_almost_eq(_num(ex), k * k * (k if level == 3 else 1.0), 0.0001, str(ex.prompt))
	assert_eq(float(ex.picture.scale), k)


func _c_element_place(ex: Dictionary, _level: int) -> void:
	var e: Array = by_symbol[str(ex.data.symbol)]
	match str(ex.data.ask):
		"group":
			assert_eq(int(_num(ex)), int(e[2]), str(e[1]))
			assert_eq(ex.picture.mark, [e[0]])
		"period":
			assert_eq(int(_num(ex)), int(e[3]), str(e[1]))
		"which":
			assert_eq(_answer(ex), str(e[1]))
			assert_true(str(ex.prompt).contains("group %d and period %d" % [e[2], e[3]]), str(ex.prompt))
			for c: Variant in ex.choices:
				var o: Array = by_name.get(str(c), [])
				if str(c) != str(e[1]):
					assert_false(int(o[2]) == int(e[2]) and int(o[3]) == int(e[3]), "%s is elsewhere" % c)


func _c_metal_sort(ex: Dictionary, level: int) -> void:
	if level == 1:
		assert_eq(_answer(ex), "a metal" if METALS.has(str(ex.data.name)) else "a non-metal")
	else:
		var sorted := _sorted(ex)
		for it: String in sorted:
			assert_eq(sorted[it], "metal" if METALS.has(it) else "non-metal", it)


func _c_element_symbol(ex: Dictionary, level: int) -> void:
	var symbol_of := {}
	for e: Array in FIRST20:
		symbol_of[str(e[1])] = str(e[0])
	symbol_of.merge(MORE_SYMBOLS)
	if level == 1:
		assert_eq(_answer(ex), str(symbol_of[str(ex.prompt).trim_prefix("What is the symbol for ").trim_suffix("?")]))
	else:
		var m := _matched(ex)
		for name: String in m:
			assert_eq(m[name], str(symbol_of[name]), name)


func _c_separate_method(ex: Dictionary, level: int) -> void:
	if level == 3:
		var sorted := _sorted(ex)
		for it: String in sorted:
			assert_eq(sorted[it], _by_phrase(METHOD_OF, it), it)
	else:
		assert_eq(_answer(ex), _by_phrase(METHOD_OF, str(ex.prompt)), str(ex.prompt))


func _c_chroma_read(ex: Dictionary, _level: int) -> void:
	var samples: Array = ex.picture.samples
	match str(ex.data.ask):
		"count":
			for s: Array in samples:
				if str(s[0]) == "ink X":
					assert_eq(int(_num(ex)), (s[1] as Array).size())
		"pure":
			for s: Array in samples:
				assert_eq(_answer(ex) == "ink %s" % s[0], (s[1] as Array).size() == 1, str(s))
		"which":
			var mix: Array = samples[0][1]
			var inside: Array[String] = []
			for s: Array in samples.slice(1):
				for spot: Array in mix:
					if absf(float(spot[0]) - float(s[1][0][0])) < 0.01:
						inside.append(str(s[0]))
			assert_eq(_answer(ex), " and ".join(inside))


func _c_mixture_words(ex: Dictionary, level: int) -> void:
	if level == 1:
		assert_true(str(ex.prompt).contains(str(WORD_MEANS[_answer(ex)])), "%s: %s" % [_answer(ex), ex.prompt])
	else:
		var m := _matched(ex)
		for w: String in m:
			assert_true(str(m[w]).contains(str(WORD_MEANS[w])), "%s: %s" % [w, m[w]])


func _c_ph_kind(ex: Dictionary, level: int) -> void:
	if level == 3:
		var order: Array = []
		for i: Variant in ex.answer:
			order.append(float(PH_OF[str(ex.items[int(i)])]))
		for i in range(1, order.size()):
			assert_lt(float(order[i - 1]), float(order[i]), "most acidic first")
		return
	var ph := float(PH_OF[str(ex.data.substance)])
	assert_eq(float(ex.data.ph), ph)
	if level == 1:
		assert_eq(_answer(ex), "acidic" if ph < 7.0 else ("neutral" if ph == 7.0 else "alkaline"))
	else:
		var want := "neutral"
		if ph <= 3.0:
			want = "strongly acidic"
		elif ph < 7.0:
			want = "weakly acidic"
		elif ph >= 11.0:
			want = "strongly alkaline"
		elif ph > 7.0:
			want = "weakly alkaline"
		assert_eq(_answer(ex), want, str(ph))


func _c_indicator_colour(ex: Dictionary, level: int) -> void:
	match level:
		1:
			var ph := float(ex.data.ph)
			var want := "red" if ph <= 3.0 else ("green" if ph == 7.0 else ("blue" if ph <= 10.0 else "purple"))
			assert_eq(_answer(ex), want, str(ph))
		2:
			var acid := float(PH_OF[str(ex.data.substance)]) < 7.0
			var ends := "red" if acid else "blue"
			var paper := str(ex.data.paper)
			assert_eq(_answer(ex), "it stays %s" % paper if paper == ends else "it turns %s" % ends)
		3:
			assert_eq(_answer(ex), "green")


func _c_salt_name(ex: Dictionary, level: int) -> void:
	var metal := str(ex.data.alkali).split(" ")[0]
	var tail: String = {"hydrochloric acid": "chloride", "sulfuric acid": "sulfate", "nitric acid": "nitrate"}[
		str(ex.data.acid)]
	match level:
		1:
			assert_eq(_answer(ex), "water")
		2:
			assert_eq(_answer(ex), "%s %s" % [metal, tail])
		3:
			assert_eq(_answer(ex), "%s + %s" % [ex.data.acid, ex.data.alkali])
			assert_true(str(ex.prompt).contains("%s %s" % [metal, tail]), str(ex.prompt))


func _c_colour_seen(ex: Dictionary, _level: int) -> void:
	var light: Array = REFLECTS["white" if str(ex.data.light) == "white" else str(ex.data.light)]
	var left: Array = []
	for c: Variant in light:
		if (REFLECTS[str(ex.data.object)] as Array).has(c) and (str(ex.data.filter) == "" or str(c) == str(ex.data.filter)):
			left.append(c)
	var want := "black"
	if left.size() == 3:
		want = "white"
	elif left.size() == 2:
		want = "yellow"
	elif left.size() == 1:
		want = str(left[0])
	assert_eq(_answer(ex), want, str(ex.prompt))
	assert_true(bool(ex.picture.hide), "the picture never shows the answer")


func _c_refraction_bend(ex: Dictionary, level: int) -> void:
	if level <= 2:
		var into_denser := str(ex.data.to) != "air"
		assert_eq(_answer(ex), "towards the normal" if into_denser else "away from the normal")
	elif str(ex.data.ask) == "normal":
		assert_eq(_answer(ex), "it does not bend")
	else:
		assert_eq(_answer(ex), "the ray into glass")


func _c_spectrum_order(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex), RAINBOW[RAINBOW.find(str(ex.data.after)) + 1])
		2:
			var last := -1
			for i: Variant in ex.answer:
				var at := RAINBOW.find(str(ex.items[int(i)]))
				assert_gt(at, last, "in the spectrum's order")
				last = at
		3:
			var cols: Array = ex.data.colours
			var idx: Array = cols.map(func(c: Variant) -> int: return RAINBOW.find(str(c)))
			var want := RAINBOW[int(idx.max())] if bool(ex.data.most) else RAINBOW[int(idx.min())]
			assert_eq(_answer(ex), want, "violet bends most, red least")


func _c_air_share(ex: Dictionary, _level: int) -> void:
	var d: Dictionary = ex.data
	if d.has("ppm"):
		assert_almost_eq(_num(ex), float(d.ppm) / 10000.0, 0.0000001)
	elif d.has("litres"):
		assert_almost_eq(_num(ex), float(d.litres) * float(AIR[str(d.gas)]) / 100.0, 0.0001)
	else:
		assert_almost_eq(_num(ex), float(AIR[str(d.gas)]), 0.0001)


func _c_carbon_process(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex).contains("adds"), bool(ADDS[str(ex.data.process)]), str(ex.prompt))
		2:
			var sorted := _sorted(ex)
			for it: String in sorted:
				assert_eq(sorted[it].begins_with("adds"), bool(ADDS[it]), it)
		3:
			assert_eq(_answer(ex), str(ex.picture.hide))


func _c_burn_products(ex: Dictionary, level: int) -> void:
	var answer := _answer(ex)
	match level:
		1:
			assert_eq(answer, "carbon dioxide")
		2:
			var fuel := str(ex.data.fuel)
			assert_eq(answer, "carbon dioxide" if fuel.contains("coal") else "carbon dioxide and water", fuel)
		3:
			assert_true(answer == "carbon monoxide" or answer == "hydrogen", answer)


func _c_evidence_pick(ex: Dictionary, _level: int) -> void:
	assert_true(_answer(ex).contains(str(STRONGEST[str(ex.data.claim)])), "%s: %s" % [ex.data.claim, _answer(ex)])


func _c_quote_or_paraphrase(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex), "a quote" if str(ex.data.sentence).contains("\"") else "a paraphrase")
		2:
			var sorted := _sorted(ex)
			for it: String in sorted:
				assert_eq(sorted[it], "quote" if it.contains("\"") else "paraphrase", it)
		3:
			assert_false(_answer(ex).contains("\""), "a paraphrase has no quotation marks")


func _c_fact_or_fiction(ex: Dictionary, level: int) -> void:
	var is_history := func(t: String) -> bool:
		for k: String in HISTORY_BY:
			if t.contains(k):
				return true
		return false
	if level == 1:
		assert_eq(_answer(ex), "a history text" if is_history.call(str(ex.data.sentence)) else "historical fiction")
	else:
		var sorted := _sorted(ex)
		for it: String in sorted:
			assert_eq(sorted[it], "history text" if is_history.call(it) else "historical fiction", it)


func _c_out_of_time(ex: Dictionary, _level: int) -> void:
	var year := int(RegEx.create_from_string("(\\d{4})").search(str(ex.data.setting)).get_string(1))
	assert_true(LATER.has(_answer(ex)), "%s is from a later time" % _answer(ex))
	assert_gt(int(LATER.get(_answer(ex), 0)), year, "%s came after %d" % [_answer(ex), year])
	for c: Variant in ex.choices:
		if str(c) != _answer(ex):
			assert_lte(int(LATER.get(str(c), 0)), year, "%s belongs in %s" % [c, ex.data.setting])


func _c_appeal_kind(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_eq(_answer(ex), _by_phrase(APPEAL_BY, str(ex.data.line)))
		2:
			var m := _matched(ex)
			for k: String in m:
				assert_eq(_by_phrase(APPEAL_BY, str(m[k])), k, str(m[k]))
		3:
			var sorted := _sorted(ex)
			for it: String in sorted:
				assert_eq(sorted[it], _by_phrase(APPEAL_BY, it), it)


func _c_speech_trick(ex: Dictionary, level: int) -> void:
	match level:
		1:
			assert_ne(_by_phrase(TRICK_BY, _answer(ex)), "?", "the answer is a trick: %s" % _answer(ex))
		2:
			assert_eq(_answer(ex), _by_phrase(TRICK_BY, str(ex.data.line)))
		3:
			var m := _matched(ex)
			for k: String in m:
				assert_eq(_by_phrase(TRICK_BY, str(m[k])), k, str(m[k]))


func _c_rebuttal_pick(ex: Dictionary, _level: int) -> void:
	assert_true(_answer(ex).contains(_by_phrase(REBUT_BY, str(ex.data.counter))), _answer(ex))


func _c_reasoning_flaw(ex: Dictionary, level: int) -> void:
	match level:
		1:
			var flawed := _by_phrase(FLAW_BY, str(ex.data.line)) != "?"
			assert_eq(_answer(ex).begins_with("no"), flawed, str(ex.data.line))
		2:
			assert_eq(_answer(ex), _by_phrase(FLAW_BY, str(ex.data.line)))
		3:
			var m := _matched(ex)
			for k: String in m:
				assert_eq(_by_phrase(FLAW_BY, str(m[k])), k, str(m[k]))


func _c_signal_word(ex: Dictionary, level: int) -> void:
	if level == 3:
		var sorted := _sorted(ex)
		for it: String in sorted:
			assert_eq(sorted[it], "compare and contrast" if COMPARE.has(it) else "cause and effect", it)
	else:
		assert_eq(_answer(ex), _by_phrase(SIGNAL_OF, str(ex.data.sentence)))


func _c_precise_term(ex: Dictionary, level: int) -> void:
	if level == 3:
		var sorted := _sorted(ex)
		for it: String in sorted:
			assert_eq(sorted[it] == "vague", PRECISE_OF.has(it), it)
	else:
		assert_true(_answer(ex).contains(str(PRECISE_OF[str(ex.data.vague)])), _answer(ex))


func _c_pov_name(ex: Dictionary, level: int) -> void:
	if level == 3:
		var sorted := _sorted(ex)
		for it: String in sorted:
			var want := _by_phrase(POV_BY, it).replace("third person ", "third ")
			assert_eq(sorted[it], want, it)
	else:
		assert_eq(_answer(ex), _by_phrase(POV_BY, str(ex.data.line)))
		if level == 2:
			assert_true(bool(ex.picture.hide), "the picture hides the answer")


func _c_sense_detail(ex: Dictionary, level: int) -> void:
	if level == 1:
		assert_eq(_answer(ex), _by_phrase(SENSE_BY, str(ex.data.detail)))
	else:
		var m := _matched(ex)
		for k: String in m:
			assert_eq(_by_phrase(SENSE_BY, str(m[k])), k, str(m[k]))
