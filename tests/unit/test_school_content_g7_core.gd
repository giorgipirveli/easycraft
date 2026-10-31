extends GutTest
## Owner #70, #73 and #111 ("full school programs and syllabus content"; research §6.7), the grade 7 core agent: grade
## 7's maths, science and English get their last units: primes, powers and estimates, speed, distance and time, and
## graphs that mislead (Singapore Secondary 1, England KS3); the periodic table, mixtures and separating, acids and
## alkalis, light and colour, and the air and the carbon cycle (England KS3, Singapore S1); strong evidence, fiction and
## history, speeches and media, and writing arguments with counterclaims, information like an expert and stories from a
## clear point of view (Common Core RL/RI/W/SL.7). After them every unit of grade 7's maths (18), science (17) and
## English (18) is written. Each unit teaches with a lesson of 4 to 8 cards that opens with a memory question naming
## what it builds on and ends with something to try in the world and what comes next (research §5.3 rules 1, 7 and 8),
## has at least 12 hand-written exercises at levels 1, 2 and 3 of two kinds or more, each with a strategy hint and a
## worked answer, rounds that fill, vary and never show a hand-written exercise twice, its own generators ("g7k") at
## every level, and meets the School's quality bar (test_school_quality.gd's `bar`). The facts each lesson must teach are
## listed below (their sources: docs/devlog/parts/m8-grade7-core.md); the answers the pictures show (a factor tree's
## missing prime, an HCF and an LCM from a Venn diagram of primes, a leg's speed on a distance-time graph, how much
## taller a bar looks on a cut axis, how much bigger a scaled picture looks, a chromatogram's dyes) are worked out again
## here with this file's own arithmetic. Where a unit's topic is a Life or Success Experience (owner #112, #115, #117:
## learn by doing), its last card names it in the LIFE tab.
## (Every exercise's validity, answers, pictures, sounds and words are the shared content test's, test_school_content.gd;
## the generators' answers are test_g7_core_gen.gd's; the pictures' rules test_school_picture_g7core.gd's.)

const GRADE := 7
const UNITS := {
	"maths": ["primes_estimation", "speed_rate", "misleading_graphs"],
	"science": ["periodic_table", "mixtures_separating", "acids_alkalis", "light_colour", "air_carbon_cycle"],
	"english": ["strong_evidence", "fiction_and_history", "speeches_media", "write_argument", "write_informative",
		"write_narrative"],
}
const MIN_EXERCISES := 12
const MIN_CARDS := 4
## Every unit's generators are this source's ("g7k": grade 7 core, G7CoreGen).
const SOURCE := "g7k."
const PICTURES := "res://ui/school/school_picture_g7core.gd"
## The facts each lesson must say (research §6.7 goals; lower case).
const MUST := {
	"g7.maths.primes_estimation": ["prime", "factor tree", "highest common factor", "hcf", "lowest common multiple",
		"lcm", "venn", "decimal place", "significant figure", "estimate"],
	"g7.maths.speed_rate": ["speed", "distance ÷ time", "km/h", "m/s", "3.6", "average speed", "distance-time graph",
		"steeper", "flat"],
	"g7.maths.misleading_graphs": ["bar chart", "line graph", "pie chart", "scatter graph", "axis", "starts at",
		"equal", "4 times", "nightingale"],
	"g7.science.periodic_table": ["atomic number", "period", "group", "mendeleev", "metal", "non-metal", "conduct",
		"alkali metals", "halogens", "noble gases"],
	"g7.science.mixtures_separating": ["mixture", "soluble", "solution", "filter", "residue", "filtrate", "evaporat",
		"distil", "condenser", "chromatography", "pure"],
	"g7.science.acids_alkalis": ["acid", "alkali", "ph", "neutral", "indicator", "litmus", "universal indicator",
		"neutralis", "a salt and water", "corrosive", "never taste"],
	"g7.science.light_colour": ["reflect", "diffuse", "refraction", "normal", "prism", "spectrum", "violet", "absorb",
		"filter", "white light", "never look"],
	"g7.science.air_carbon_cycle": ["78%", "21%", "nitrogen", "oxygen", "argon", "carbon dioxide", "photosynthesis",
		"respiration", "decomposers", "fossil fuels", "combustion", "greenhouse"],
	"g7.english.strong_evidence": ["evidence", "quote", "paraphrase", "relevant", "point", "explain"],
	"g7.english.fiction_and_history": ["historical fiction", "history text", "setting", "invented", "source",
		"compare", "caxton"],
	"g7.english.speeches_media": ["claim", "evidence", "ethos", "pathos", "logos", "pause", "film", "audio"],
	"g7.english.write_argument": ["counterclaim", "rebuttal", "concede", "logical", "source", "conclusion"],
	"g7.english.write_informative": ["compare", "contrast", "cause", "effect", "signal words", "precise",
		"point by point"],
	"g7.english.write_narrative": ["point of view", "first person", "third person", "omniscient", "pacing", "senses",
		"show"],
}
## The pictures each unit needs, over its lesson, its exercises and its generators ([kind, how many], …).
const DRAWS := {
	"g7.maths.primes_estimation": [["factor_tree", 3], ["prime_venn", 3], ["number_line", 1]],
	"g7.maths.speed_rate": [["speed_triangle", 2], ["distance_time", 4]],
	"g7.maths.misleading_graphs": [["cut_axis_bars", 3], ["odd_scale", 2], ["big_icons", 2], ["chart_kinds", 2]],
	"g7.science.periodic_table": [["periodic_grid", 5]],
	"g7.science.mixtures_separating": [["separation", 4], ["chromatogram", 3]],
	"g7.science.acids_alkalis": [["ph_scale", 4]],
	"g7.science.light_colour": [["light_rays", 4], ["seen_colour", 3], ["rgb_mix", 1]],
	"g7.science.air_carbon_cycle": [["air_mix", 2], ["carbon_cycle", 3], ["greenhouse", 1]],
	"g7.english.strong_evidence": [["marked_text", 2], ["argument_map", 1]],
	"g7.english.fiction_and_history": [["venn", 2], ["marked_text", 1]],
	"g7.english.speeches_media": [["table", 1], ["venn", 1]],
	"g7.english.write_argument": [["argument_map", 3], ["step_chain", 1]],
	"g7.english.write_informative": [["venn", 2], ["step_chain", 2]],
	"g7.english.write_narrative": [["pov_view", 3], ["marked_text", 1]],
}
## Units whose label exercises must exist (label the diagram), with how many.
const LABELS := {"g7.science.periodic_table": 1, "g7.science.mixtures_separating": 1, "g7.science.light_colour": 1,
	"g7.science.air_carbon_cycle": 1}
## Owner #112, #115 and #117 (learn by doing): the units whose topic is a Life or Success Experience end by naming it
## (its title, read through LifeExperience.data) in the LIFE tab.
const LIFE_LINKS := {
	"g7.maths.primes_estimation": ["My Money Stall"],
	"g7.maths.speed_rate": ["Safe Streets"],
	"g7.maths.misleading_graphs": ["Success Stories"],
	"g7.science.periodic_table": ["Electricity Safety"],
	"g7.science.acids_alkalis": ["The Poisons Cupboard"],
	"g7.science.light_colour": ["Safe Streets"],
	"g7.science.air_carbon_cycle": ["Fire Escape", "The Poisons Cupboard"],
	"g7.english.fiction_and_history": ["Success Stories"],
	"g7.english.speeches_media": ["Talk & Deal"],
	"g7.english.write_argument": ["Talk & Deal"],
}
## Research §5.4: nothing about puberty, human reproduction, drugs, alcohol, smoking or gambling in these units (health
## and PE's own units teach those); no personal questions; money is the game's gold (ruling 6); no living people or
## brands (rule 7).
const NOT_ANYWHERE: Array[String] = ["puberty", "sex", "pregnant", "pregnancy", "womb", "sperm", "drug", "drugs",
	"alcohol", "ethanol", "cigarette", "tobacco", "smoking", "vape", "vaping", "nicotine", "gambling", "dollar",
	"dollars", "euro", "euros", "pound", "pounds", "pence", "yen", "rupee", "rupees"]
const BRANDS: Array[String] = ["google", "youtube", "tiktok", "instagram", "facebook", "netflix", "iphone", "coca-cola",
	"cola", "pepsi", "nike", "lego", "disney", "marvel", "harry potter", "excel", "microsoft", "samsung", "spotify",
	"bbc", "sky news"]
const PERSONAL := "(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)"
## Lab safety (research §5.4): chemicals are never tasted, a home experiment is done with a grown-up, and the Sun is
## never looked at.
const SAFETY := {
	"g7.science.acids_alkalis": ["never taste", "with a grown-up", "never mix"],
	"g7.science.mixtures_separating": ["with a grown-up"],
	"g7.science.light_colour": ["never look straight at the sun"],
}


func _ids() -> Array[String]:
	var out: Array[String] = []
	for subject: String in UNITS:
		for name: String in UNITS[subject]:
			out.append("g%d.%s.%s" % [GRADE, subject, name])
	return out


func _lesson(id: String) -> String:
	var parts: Array[String] = []
	for card: Dictionary in Curriculum.content(id).lesson:
		parts.append(str(card.get("text", "")))
	return " ".join(parts)


func _ex_texts(ex: Dictionary) -> Array[String]:
	var out: Array[String] = [str(ex.get("prompt", "")), str(ex.get("hint", "")), str(ex.get("explain", ""))]
	for t: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []) \
			+ ex.get("labels", []):
		out.append(ExerciseCheck.item_text(t))
	return out


## A unit's hand-written exercises and its generators' at every level (12 seeds each).
func _exercises(id: String, seeds: int = 12) -> Array[Dictionary]:
	var c := Curriculum.content(id)
	var out: Array[Dictionary] = []
	for ex: Dictionary in c.exercises:
		out.append(ex)
	for g: Dictionary in c.generators:
		for s in seeds:
			out.append(SchoolGen.make(str(g.gen), s, int(g.level)))
	return out


## Every text a unit shows: its cards, its exercises' and its generators'.
func _all_texts(id: String) -> String:
	var parts: Array[String] = [_lesson(id)]
	for ex in _exercises(id):
		parts.append_array(_ex_texts(ex))
	return " ".join(parts)


func _pictures(id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card: Dictionary in Curriculum.content(id).lesson:
		if card.has("picture"):
			out.append(card.picture)
	for ex in _exercises(id):
		if ex.has("picture"):
			out.append(ex.picture)
		for c: Variant in ex.get("choices", []):
			if c is Dictionary and c.has("picture"):
				out.append(c.picture)
	return out


func test_the_outline_names_every_units_file() -> void:
	for subject: String in UNITS:
		var ids := {}
		for u: Dictionary in Curriculum.units(GRADE, subject):
			ids[str(u.id)] = u
		for name: String in UNITS[subject]:
			var id := "g%d.%s.%s" % [GRADE, subject, name]
			assert_true(ids.has(id), "%s is in the outline" % id)
			if ids.has(id):
				assert_eq(str(ids[id].get("file", "")), "g%d/%s/%s.json" % [GRADE, subject, name], "%s names its file" % id)


## Grade 7's maths, science and English: every unit of the outline is written now (15 + 3, 12 + 5, 12 + 6).
func test_grade_7_maths_science_and_english_are_complete() -> void:
	var counts := {"maths": 18, "science": 17, "english": 18}
	for subject: String in counts:
		var units := Curriculum.units(GRADE, subject)
		assert_eq(units.size(), int(counts[subject]), "grade 7 %s's units" % subject)
		for u: Dictionary in units:
			assert_true(Curriculum.has_content(str(u.id)), "%s is written" % u.id)


func test_every_unit_is_written_and_meets_the_bar() -> void:
	var exercises := 0
	var cards := 0
	for id in _ids():
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), MIN_CARDS, Curriculum.MAX_CARDS, "%s: a lesson of 4-8 cards" % id)
		cards += (c.lesson as Array).size()
		assert_gte((c.exercises as Array).size(), MIN_EXERCISES, "%s: at least %d hand-written exercises" % [id, MIN_EXERCISES])
		exercises += (c.exercises as Array).size()
		var levels := {}
		var types := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.level)] = true
			types[str(ex.type)] = true
		assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
		assert_gte(types.size(), 2, "%s: at least two kinds of hand-written exercise" % id)
		var distinct := {}
		for stars in [0, 1, 2]:
			for s in 20:
				var round := RoundPlan.plan(c, s * 7 + stars, stars)
				assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
				var ids := {}
				for ex in round:
					distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", ""))] = true
					if not str(ex.id).begins_with("gen:"):
						assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
						ids[ex.id] = true
		assert_gte(distinct.size(), 12, "%s: varied practice" % id)
	gut.p("%d lesson cards and %d hand-written exercises in grade 7's last maths, science and English units" % [cards,
		exercises])


## The School's quality bar (owner #94; test_school_quality.gd): memory first, the world or what comes next last, 4-8
## cards, pictures (two in maths and science), three kinds of exercise, at most 70% choice and true-or-false, three a
## level or a generator, real hints and worked answers, no hint that gives the answer away.
func test_every_unit_meets_the_schools_quality_bar() -> void:
	var quality: Node = load("res://tests/unit/test_school_quality.gd").new()
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		assert_eq(quality.call("bar", id, id.split(".")[1]), [] as Array[String], "%s meets the bar" % id)
	quality.free()


func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3: "Start with memory" (a quick question from what the unit builds on, named: an earlier grade or the
## unit before), "Spiral" (what comes next) and "Do it in the world" (a challenge to try).
func test_every_lesson_starts_with_memory_and_ends_in_the_world_with_what_comes_next() -> void:
	var named := RegEx.create_from_string("\\bgrades? [3-7]\\b|\\blast unit\\b")
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var lesson: Array = Curriculum.content(id).lesson
		var first := str(lesson[0].text)
		assert_true(first.begins_with("Quick memory:") and first.contains("?"), "%s: the first card asks a memory question" % id)
		assert_true(named.search(first) != null, "%s: the memory question names what it builds on" % id)
		var last := str(lesson[-1].text)
		assert_true(last.begins_with("Try it in the world:"), "%s: the last card is something to try in the world" % id)
		assert_true(last.contains("Next"), "%s: the last card says what comes next" % id)


func test_no_unit_asks_the_same_question_twice() -> void:
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var seen := {}
		for ex: Dictionary in Curriculum.content(id).exercises:
			var key := str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", ""))
			assert_false(seen.has(key), "%s asks twice: %s" % [id, ex.prompt])
			seen[key] = true


## Every unit uses "g7k" at every level, and every g7k generator is used by one of them: endless practice.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var gens: Array = Curriculum.content(id).generators
		assert_false(gens.is_empty(), "%s has generators" % id)
		var levels := {}
		for g: Dictionary in gens:
			assert_true(str(g.gen).begins_with(SOURCE), "%s uses %s" % [id, g.gen])
			assert_true(SchoolGen.exists(str(g.gen)), "%s: %s exists" % [id, g.gen])
			used[str(g.gen)] = true
			levels[int(g.level)] = true
		assert_eq(levels.keys().size(), 3, "%s: generators at every level" % id)
	var sources := 0
	for gen in SchoolGen.ids():
		if gen.begins_with(SOURCE):
			sources += 1
			assert_true(used.has(gen), "%s is used by a grade 7 maths, science or English unit" % gen)
	assert_gte(sources, 36, "g7k has its generators")


func test_every_lesson_teaches_its_facts() -> void:
	for id: String in MUST:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var text := _lesson(id).to_lower()
		for w: String in MUST[id]:
			assert_true(text.contains(w), "%s: the lesson says '%s'" % [id, w])


func test_every_unit_is_taught_with_its_pictures() -> void:
	for id: String in DRAWS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var counts := {}
		for p in _pictures(id):
			counts[str(p.kind)] = int(counts.get(str(p.kind), 0)) + 1
		for need: Array in DRAWS[id]:
			assert_gte(int(counts.get(str(need[0]), 0)), int(need[1]), "%s: %s pictures" % [id, need[0]])


## Every kind of the grade's new picture file teaches on a lesson card of these units.
func test_every_new_picture_kind_teaches_on_a_lesson_card() -> void:
	assert_true(ResourceLoader.exists(PICTURES), "the grade 7 core picture file")
	if not ResourceLoader.exists(PICTURES):
		return
	var drawn := {}
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		for card: Dictionary in Curriculum.content(id).lesson:
			if card.has("picture"):
				drawn[str(card.picture.kind)] = true
	for kind: String in (load(PICTURES) as Script).get_script_constant_map()["KINDS"]:
		assert_true(drawn.has(kind), "a lesson card draws %s" % kind)


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG7Core.part_at, at the label
## box's size), so the pins can be trusted; and the units that label have their label exercises.
func test_every_label_points_at_its_part() -> void:
	if not ResourceLoader.exists(PICTURES):
		fail_test("the grade 7 core picture file")
		return
	var pictures: Script = load(PICTURES)
	var kinds: Array = pictures.get_script_constant_map()["KINDS"]
	var checked := 0
	for id: String in LABELS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var n := 0
		for ex: Dictionary in Curriculum.content(id).exercises:
			if str(ex.type) != "label":
				continue
			n += 1
			assert_true(kinds.has(str(ex.picture.kind)), "%s: a grade 7 core picture" % ex.id)
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part: Vector2 = pictures.call("part_at", ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
		assert_gte(n, int(LABELS[id]), "%s: label exercises" % id)
	assert_gte(checked, 14, "labels were checked")


## Owner #112, #115 and #117: the School and Life work together. A unit whose topic is a Life or Success Experience ends
## by naming it, in the LIFE tab; each name is a real Experience's title.
func test_the_life_experiences_are_named_where_the_topic_is_one() -> void:
	var titles: Array[String] = []
	for id: String in LifeExperience.IDS:
		var d := LifeExperience.data(id)
		assert_false(d.is_empty(), "%s's data" % id)
		titles.append(str(d.get("title", "")))
	for id: String in LIFE_LINKS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var last := str((Curriculum.content(id).lesson as Array)[-1].text)
		assert_true(last.contains("LIFE"), "%s: the last card sends the child to the LIFE tab" % id)
		for name: String in LIFE_LINKS[id]:
			assert_true(titles.has(name), "%s: '%s' is a Life or Success Experience" % [id, name])
			assert_true(last.contains(name), "%s: the last card names %s" % [id, name])


## The maths the pictures show, worked out again with this test's own rules: a factor tree's hidden prime is what is
## left when the others divide the number; the HCF multiplies the primes two numbers share and the LCM all of them; a
## leg of a distance-time graph has the speed distance ÷ time; a bar on an axis that starts at `from` looks
## (b − from) ÷ (a − from) times as tall as another; a picture scaled k times each way looks k² times as big; a
## chromatogram's sample shows one spot for each dye.
func test_the_pictures_answers_are_worked_out_again() -> void:
	var checked := 0
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			if str(ex.type) != "number" or not ex.has("picture"):
				continue
			var p: Dictionary = ex.picture
			var prompt := str(ex.prompt).to_lower()
			var want := NAN
			match str(p.kind):
				"factor_tree":
					if p.has("hide"):
						var primes := _primes_of(int(p.n))
						want = primes[int(p.hide)]
				"prime_venn":
					if prompt.contains("hcf"):
						want = _gcd(int(p.a), int(p.b))
					elif prompt.contains("lcm"):
						want = int(p.a) * int(p.b) / _gcd(int(p.a), int(p.b))
				"distance_time":
					var pts: Array = p.points
					if p.has("mark"):
						var i := int(p.mark)
						var dt := float(pts[i + 1][0]) - float(pts[i][0])
						var dd := float(pts[i + 1][1]) - float(pts[i][1])
						var per_hour := 60.0 if str(p.get("t_unit", "min")) == "min" else 1.0
						want = dd / dt * per_hour if prompt.contains("km/h") else dd / dt
				"cut_axis_bars":
					var bars: Array = p.bars
					if prompt.contains("fair axis"):
						want = float(bars[1][1]) / float(bars[0][1])
					elif prompt.contains("times"):
						want = (float(bars[1][1]) - float(p.from)) / (float(bars[0][1]) - float(p.from))
					elif prompt.contains("percent") or prompt.contains("%"):
						want = (float(bars[1][1]) - float(bars[0][1])) * 100.0 / float(bars[0][1])
				"big_icons":
					var k := float(p.scale)
					want = k * k * k if prompt.contains("volume") or prompt.contains("3d") else k * k
				"chromatogram":
					if prompt.contains("how many"):
						for s: Array in p.samples:
							if prompt.contains(str(s[0]).to_lower()):
								want = (s[1] as Array).size()
			if is_nan(want):
				continue
			checked += 1
			assert_almost_eq(NumberAnswer.value(str(ex.answer)), want, 0.001, "%s: %s" % [ex.id, ex.prompt])
	assert_gte(checked, 10, "the pictures' answers were checked")


func _primes_of(n: int) -> Array[int]:
	var out: Array[int] = []
	var d := 2
	while n > 1:
		while n % d == 0:
			out.append(d)
			n /= d
		d += 1
	return out


func _gcd(a: int, b: int) -> int:
	while b != 0:
		var t := a % b
		a = b
		b = t
	return a


## Speeches are listened to (research §5.3 "listen and choose"): a speaker's pace and pauses, as claps.
func test_speeches_are_listened_to() -> void:
	var id := "g7.english.speeches_media"
	if not Curriculum.has_content(id):
		fail_test("%s is not written" % id)
		return
	var c := Curriculum.content(id)
	var cards := (c.lesson as Array).filter(func(card: Dictionary) -> bool: return card.has("sound"))
	var exercises := (c.exercises as Array).filter(func(ex: Dictionary) -> bool: return ex.has("sound"))
	assert_gte(cards.size(), 1, "a lesson card to listen to")
	assert_gte(exercises.size(), 3, "exercises to listen to")


## Research §5.4: nothing about puberty, reproduction, drugs, alcohol, smoking or gambling; no personal questions; the
## game's gold; no brands; and the lab's safety: never taste a chemical, home experiments with a grown-up, never look
## at the Sun.
func test_safety() -> void:
	for id in _ids():
		if not Curriculum.has_content(id):
			continue
		var all := _all_texts(id).to_lower()
		for w in NOT_ANYWHERE + BRANDS:
			assert_null(RegEx.create_from_string("\\b" + w + "\\b").search(all), "%s: nothing about '%s'" % [id, w])
		assert_null(RegEx.create_from_string(PERSONAL).search(all), "%s: no personal questions" % id)
	for id: String in SAFETY:
		if not Curriculum.has_content(id):
			continue
		var lesson := _lesson(id).to_lower()
		for w: String in SAFETY[id]:
			assert_true(lesson.contains(w), "%s: the lesson says '%s'" % [id, w])
