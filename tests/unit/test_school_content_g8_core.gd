extends GutTest
## Owner #70, #73 and #111 ("we want to have full school programs and sylabusse content in the game"; research §6.8),
## the grade 8 core agent: the 14 MATHS, SCIENCE and ENGLISH units of grade 8's outline that were still "Coming soon"
## (Singapore Secondary 2's expanding, factorising and trigonometry; England's KS3 pressure, energy bills, energetics,
## current and voltage, and gas exchange; NGSS MS-PS1-6 and MS-LS4-5; Common Core RL/RI.8.1, RL.8.9, W.8.1-3, SL.8.4-5)
## are written, one step up from grade 7 and building on grade 8's older units: a lesson of 4 to 8 cards that opens with
## a memory question naming the earlier grade it builds on and ends with something to try in the world and what comes
## next (research §5.3 rules 1, 7 and 8), at least 12 hand-written exercises at levels 1, 2 and 3 of two kinds or more,
## each with a strategy hint and a worked answer, rounds that fill, vary and never show a hand-written exercise twice,
## and the School's quality bar (test_school_quality.gd's `bar`; its scope is grades 3-7, so these units are held to it
## here). Owner #112, #115, #117, #118: a unit whose topic is a Life or Success Experience ends by naming it in the LIFE
## tab, by its own title. The rules the pictures teach (sine, cosine and tangent; a series or parallel circuit's meters;
## a meter's units; a parabola's crossings; an energy level diagram's change) are worked out again here. (Every
## exercise's validity, answers, pictures, sounds and words are the shared content test's, test_school_content.gd; the
## generators' answers are test_g8_core_gen.gd's; the pictures' samples test_school_picture_g8core.gd's.)

const GRADE := 8
## The units this agent wrote (the outline's other grade 8 maths, science and English units were written before).
const UNITS: Array[String] = ["g8.maths.expand_factorise", "g8.maths.trig_ratios", "g8.science.pressure",
	"g8.science.energy_bills", "g8.science.hot_cold_reactions", "g8.science.circuits_voltage",
	"g8.science.transport_systems", "g8.science.breeding_genes", "g8.english.strongest_evidence",
	"g8.english.old_stories_new", "g8.english.write_argument", "g8.english.write_informative",
	"g8.english.write_narrative", "g8.english.present_multimedia"]
const OUTLINE := {"maths": 18, "science": 17, "english": 18}   # research §6.8
const MIN_EXERCISES := 12
const MIN_CARDS := 4
const MIN_DISTINCT := 12
## The units' own generators ("g8k", G8CoreGen).
const OWN_GEN := "g8k."
const CURRENCIES: Array[String] = ["dollar", "dollars", "euro", "euros", "pound", "pounds", "pence", "penny", "pennies",
	"yen", "rupee", "rupees", "yuan", "lari"]
## Research §5.4 rule 7: people of the past only, no brands, apps, products or other games.
const BRANDS: Array[String] = ["instagram", "tiktok", "snapchat", "youtube", "whatsapp", "facebook", "google", "ipad",
	"iphone", "samsung", "nintendo", "playstation", "xbox", "powerpoint", "keynote", "excel", "disney", "pixar",
	"marvel", "netflix", "hollywood", "chatgpt", "tesla", "humulin", "genentech", "monsanto", "bayer", "duracell",
	"lego", "wikipedia"]
const PERSONAL := "(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)"
## Research §5.4 rule 4: nothing about puberty or human reproduction (plants' and animals' breeding stays in science).
const NOT_TAUGHT: Array[String] = ["puberty", "sex", "sexual", "pregnant", "pregnancy", "human reproduction"]
## The facts each lesson must say (research §6.8 goals; the sources are in docs/devlog/parts/m8-grade8-core.md).
const MUST := {
	"g8.maths.expand_factorise": ["expand", "factorise", "x² + 5x + 6", "a² + 2ab + b²", "a² − b²", "common factor",
		"parabola", "vertex", "symmetr"],
	"g8.maths.trig_ratios": ["hypotenuse", "opposite", "adjacent", "sin x = opposite ÷ hypotenuse",
		"cos x = adjacent ÷ hypotenuse", "tan x = opposite ÷ adjacent", "soh cah toa", "inverse"],
	"g8.science.pressure": ["force ÷ area", "pascal", "depth", "all directions", "upthrust", "less dense",
		"air pressure", "kpa"],
	"g8.science.energy_bills": ["watt", "joule", "kilowatt-hour", "power × time", "electricity counter", "units", "standby", "led"],
	"g8.science.hot_cold_reactions": ["exothermic", "endothermic", "temperature", "energy level diagram",
		"breaking bonds", "making", "activation energy", "hand warmer", "cold pack", "never mix"],
	"g8.science.circuits_voltage": ["current", "amps", "ammeter", "voltage", "volts", "voltmeter", "series",
		"parallel", "resistance", "ohms", "voltage ÷ current"],
	"g8.science.transport_systems": ["xylem", "phloem", "root hair", "transpiration", "stomata", "atri",
		"ventricle", "valves", "arteries", "veins", "capillaries", "alveoli", "diffus"],
	"g8.science.breeding_genes": ["selective breeding", "generations", "traits", "genetic engineering", "gene",
		"insulin", "bacteria", "golden rice", "vitamin a", "close relatives"],
	"g8.english.strongest_evidence": ["claim", "evidence", "strongest", "specific", "explicit", "infer", "explain"],
	"g8.english.old_stories_new": ["myth", "folk tale", "pattern", "archetype", "trickster", "romeo and juliet",
		"prometheus", "keeps", "changes"],
	"g8.english.write_argument": ["claim", "counterclaim", "rebuttal", "however", "credible", "formal", "conclusion",
		"call to action"],
	"g8.english.write_informative": ["introduction", "heading", "graphic", "caption", "precise", "define",
		"transition", "conclusion"],
	"g8.english.write_narrative": ["flashback", "had", "time order", "telling detail", "senses", "pacing",
		"reflection", "transition"],
	"g8.english.present_multimedia": ["salient", "evidence", "media", "slide", "eye contact", "volume",
		"pronunciation", "pause", "credit"],
}
## The pictures each unit needs, over its lesson, its exercises and its generators ([kind, how many], …).
const DRAWS := {
	"g8.maths.expand_factorise": [["area_model", 2], ["parabola", 3]],
	"g8.maths.trig_ratios": [["trig_triangle", 6], ["table", 1]],
	"g8.science.pressure": [["fluid_pressure", 4], ["line_graph", 1]],
	"g8.science.energy_bills": [["energy_meter", 3], ["table", 1]],
	"g8.science.hot_cold_reactions": [["energy_profile", 3], ["thermometer", 3]],
	"g8.science.circuits_voltage": [["meter_circuit", 6], ["line_graph", 1]],
	"g8.science.transport_systems": [["plant_transport", 2], ["heart_chambers", 2], ["air_sac", 1]],
	"g8.science.breeding_genes": [["gene_transfer", 2], ["step_chain", 1], ["balance_scale", 1]],
	"g8.english.strongest_evidence": [["balance_scale", 1], ["step_chain", 1]],
	"g8.english.old_stories_new": [["table", 1], ["step_chain", 1]],
	"g8.english.write_argument": [["argument_map", 2]],
	"g8.english.write_informative": [["info_page", 1], ["table", 1]],
	"g8.english.write_narrative": [["story_order", 3]],
	"g8.english.present_multimedia": [["slide_design", 3]],
}
## Units whose label exercises must exist (label the diagram), with how many.
const LABELS := {"g8.maths.trig_ratios": 2, "g8.science.pressure": 1, "g8.science.hot_cold_reactions": 1,
	"g8.science.transport_systems": 2, "g8.science.breeding_genes": 1}
## Owner #112, #115, #117: the units whose topic is a Life or Success Experience end by naming it (in its title:
## data/life/experiences/, data/success/experiences/, data/tools/real_builder.json) in the LIFE tab.
const LIFE_LINKS := {
	"g8.maths.trig_ratios": ["Real Builder"],
	"g8.science.pressure": ["Water Safety"],
	"g8.science.energy_bills": ["Electricity Safety"],
	"g8.science.hot_cold_reactions": ["Poisons Cupboard"],
	"g8.science.circuits_voltage": ["Electricity Safety"],
	"g8.science.transport_systems": ["Little Lifesaver", "Medical Emergencies"],
	"g8.english.write_argument": ["Talk & Deal"],
	"g8.english.write_narrative": ["Success Stories"],
	"g8.english.present_multimedia": ["Talk & Deal"],
}
## Listening is taught where a talk's pace, volume and pauses are (a card and exercises to hear).
const HEARD := {"g8.english.present_multimedia": 4}


func _texts(c: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for card: Dictionary in c.lesson:
		out.append(str(card.get("text", "")))
	for ex: Dictionary in c.exercises:
		out.append_array(_ex_texts(ex))
	return out


func _ex_texts(ex: Dictionary) -> Array[String]:
	var out: Array[String] = [str(ex.get("prompt", "")), str(ex.get("hint", "")), str(ex.get("explain", ""))]
	for t: Variant in ex.get("choices", []) + ex.get("items", []) + ex.get("matches", []) + ex.get("groups", []) \
			+ ex.get("labels", []):
		out.append(ExerciseCheck.item_text(t))
	return out


## A unit's texts with its generators' at every level.
func _all_texts(id: String, seeds: int = 12) -> Array[String]:
	var c := Curriculum.content(id)
	var texts := _texts(c)
	for g: Dictionary in c.generators:
		for s in seeds:
			texts.append_array(_ex_texts(SchoolGen.make(str(g.gen), s, int(g.level))))
	return texts


func _lesson(id: String) -> String:
	var out := ""
	for card: Dictionary in Curriculum.content(id).lesson:
		out += str(card.text) + " "
	return out.to_lower()


## A unit's exercises: hand-written, and its generators' for `seeds` seeds.
func _exercises(id: String, seeds: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var c := Curriculum.content(id)
	for ex: Dictionary in c.exercises:
		out.append(ex)
	for g: Dictionary in c.generators:
		for s in seeds:
			out.append(SchoolGen.make(str(g.gen), s, int(g.level)))
	return out


## Every picture of a unit (on its cards, its exercises and their choices), with its generators' for `seeds` seeds.
func _pictures(id: String, seeds: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for card: Dictionary in Curriculum.content(id).lesson:
		if card.get("picture") is Dictionary:
			out.append(card.picture)
	for ex in _exercises(id, seeds):
		if ex.get("picture") is Dictionary:
			out.append(ex.picture)
		for ch: Variant in ex.get("choices", []):
			if ch is Dictionary and ch.get("picture") is Dictionary:
				out.append(ch.picture)
	return out


func _found(t: String, words: Array[String]) -> String:
	for w in words:
		if RegEx.create_from_string("\\b" + w + "\\b").search(t.to_lower()):
			return w
	return ""


func test_the_outline_has_every_unit_of_the_research() -> void:
	for subject: String in OUTLINE:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(OUTLINE[subject]), "grade 8 %s" % subject)
	var ids := {}
	for subject: String in OUTLINE:
		for u: Dictionary in Curriculum.units(GRADE, subject):
			ids[str(u.id)] = true
	for id in UNITS:
		assert_true(ids.has(id), "%s is in the outline" % id)


func test_every_unit_is_written_and_meets_the_bar() -> void:
	var exercises := 0
	var cards := 0
	for id in UNITS:
		assert_true(Curriculum.has_content(id), "%s is written" % id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(Curriculum.content_problems(id), [] as Array[String], id)
		var c := Curriculum.content(id)
		assert_between((c.lesson as Array).size(), MIN_CARDS, Curriculum.MAX_CARDS, "%s: a lesson of 4 to 8 cards" % id)
		assert_gte((c.exercises as Array).size(), MIN_EXERCISES, "%s: at least %d hand-written exercises" % [id,
			MIN_EXERCISES])
		exercises += (c.exercises as Array).size()
		cards += (c.lesson as Array).size()
		var levels := {}
		var types := {}
		for ex: Dictionary in c.exercises:
			levels[int(ex.level)] = true
			types[str(ex.type)] = true
		assert_eq(levels.keys().size(), 3, "%s: hand-written exercises at levels 1, 2 and 3" % id)
		assert_gte(types.size(), 2, "%s: at least two kinds of exercise" % id)
		var distinct := {}
		for stars in [0, 1, 2]:
			for s in 20:
				var round := RoundPlan.plan(c, s * 7 + stars, stars)
				assert_eq(round.size(), MasteryRules.ROUND_SIZE, "%s fills a round" % id)
				var ids := {}
				for ex in round:
					distinct[str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", "")) + str(ex.get("board", ""))] = true
					if not str(ex.id).begins_with("gen:"):
						assert_false(ids.has(ex.id), "%s: %s twice in a round" % [id, ex.id])
						ids[ex.id] = true
		assert_gte(distinct.size(), MIN_DISTINCT, "%s: varied practice" % id)
	gut.p("grade 8 maths, science and English (the 14 new units): %d cards, %d hand-written exercises" % [cards,
		exercises])


## The School's quality bar (owner #94; test_school_quality.gd, whose scope is grades 3-7): memory first, the world or
## what comes next last, 4-8 cards, pictures (two in maths and science), three kinds of exercise, at most 70% choice
## and true-or-false, three a level or a generator, real hints and worked answers, no hint that gives the answer away.
func test_every_unit_meets_the_schools_quality_bar() -> void:
	var quality: Node = load("res://tests/unit/test_school_quality.gd").new()
	for id in UNITS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		assert_eq(quality.call("bar", id, id.split(".")[1]), [] as Array[String], "%s meets the bar" % id)
	quality.free()


## The outline keeps its standards and goals, and every unit names its own grade 8 file.
func test_the_files_are_their_own() -> void:
	for subject: String in OUTLINE:
		for u: Dictionary in Curriculum.units(GRADE, subject):
			if not UNITS.has(str(u.id)):
				continue
			var parts := str(u.id).split(".")
			assert_eq(str(u.get("file", "")), "g8/%s/%s.json" % [parts[1], parts[2]], "%s's file" % u.id)
			assert_gt((u.get("standards", []) as Array).size(), 0, "%s: its standards" % u.id)
			assert_gt((u.get("goals", []) as Array).size(), 0, "%s: its goals" % u.id)
			assert_null(u.get("hard"), "%s is not hard history" % u.id)


## Research §5.3: every exercise has a strategy hint (not the answer itself) and a worked answer.
func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for id in UNITS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		for ex: Dictionary in Curriculum.content(id).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)
			if str(ex.type) == "number":
				var a := str(ex.answer)
				var said := RegEx.create_from_string("(?<![\\d.,/])" + a.replace(".", "\\.") + "(?![\\d/]|\\.\\d)")
				assert_true(said.search(str(ex.hint)) == null or str(ex.prompt).contains(a),
					"%s: the hint says the answer %s" % [ex.id, a])


## Research §5.3 rules 1, 7 and 8: a memory question from an earlier grade (3 to 7) first; something to try in the
## world and what comes next last.
func test_every_lesson_starts_with_memory_of_an_earlier_grade_and_ends_in_the_world_with_what_comes_next() -> void:
	var earlier := RegEx.create_from_string("grade [34567]\\b")
	for id in UNITS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var cards: Array = Curriculum.content(id).lesson
		var first := str(cards[0].text)
		assert_true(first.begins_with("Quick memory:") and first.contains("?"), "%s: the first card asks a memory question" % id)
		assert_true(earlier.search(first) != null, "%s: the first card names the grade it builds on" % id)
		var last := str(cards[-1].text)
		assert_true(last.begins_with("Try it in the world:"), "%s: the last card is something to try in the world" % id)
		assert_true(last.contains("Next"), "%s: the last card says what comes next" % id)


## A hand-written exercise's prompt appears once in a unit (a round never shows the same question twice by another id).
func test_no_unit_asks_the_same_question_twice() -> void:
	for id in UNITS:
		if not Curriculum.has_content(id):
			continue
		var seen := {}
		for ex: Dictionary in Curriculum.content(id).exercises:
			var key := str(ex.prompt) + str(ex.get("picture", "")) + str(ex.get("sound", ""))
			assert_false(seen.has(key), "%s asks twice: %s" % [id, ex.prompt])
			seen[key] = true


## The units use their own generators ("g8k"), each of which exists, every unit practises with one, and every "g8k"
## generator is used by one of them.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for id in UNITS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var gens: Array = Curriculum.content(id).generators
		assert_false(gens.is_empty(), "%s practises with a generator too" % id)
		for g: Dictionary in gens:
			var gen := str(g.gen)
			assert_true(gen.begins_with(OWN_GEN), "%s uses %s" % [id, gen])
			assert_true(SchoolGen.exists(gen), "%s: %s exists" % [id, gen])
			used[gen] = true
	var own := 0
	for gen in SchoolGen.ids():
		if gen.begins_with(OWN_GEN):
			own += 1
			assert_true(used.has(gen), "%s is used by one of the 14 units" % gen)
	assert_gt(own, 25, "the grade 8 core generators exist")


## Each unit's goals are in its lesson.
func test_the_lessons_teach_their_facts() -> void:
	for id: String in MUST:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var lesson := _lesson(id)
		for fact: String in MUST[id]:
			assert_true(lesson.contains(fact.to_lower()), "%s's lesson says '%s'" % [id, fact])


## Research §5.4 rule 4: breeding and transport stay with plants, animals and bodies' systems: nothing about puberty or
## human reproduction anywhere in these units.
func test_nothing_about_puberty_or_human_reproduction() -> void:
	var found: Array[String] = []
	for id in UNITS:
		if not Curriculum.has_content(id):
			continue
		for t in _all_texts(id):
			var w := _found(t, NOT_TAUGHT)
			if w != "":
				found.append("%s: '%s' in: %s" % [id, w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


## Money is the game's gold (research §5.5 ruling 6), no lesson asks a child for personal details (rule 6), and no brand
## or living person is named (rule 7).
func test_money_is_gold_nothing_personal_is_asked_and_no_brands() -> void:
	var ask := RegEx.create_from_string(PERSONAL)
	for id in UNITS:
		if not Curriculum.has_content(id):
			continue
		for t in _all_texts(id, 6):
			assert_false(t.contains("$") or t.contains("£") or t.contains("€"), "%s: %s" % [id, t])
			var w := _found(t, CURRENCIES)
			assert_eq(w, "", "%s: '%s' in %s" % [id, w, t])
			assert_null(ask.search(t.to_lower()), "%s asks: %s" % [id, t])
			var b := _found(t, BRANDS)
			assert_eq(b, "", "%s: '%s' in %s" % [id, b, t])


## The units that need a picture to be taught have theirs.
func test_the_units_are_drawn() -> void:
	for id: String in DRAWS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var counts := {}
		for p in _pictures(id, 6):
			counts[str(p.get("kind", ""))] = int(counts.get(str(p.get("kind", "")), 0)) + 1
		for need: Array in DRAWS[id]:
			assert_gte(int(counts.get(str(need[0]), 0)), int(need[1]), "%s: %s pictures" % [id, need[0]])


## Every new kind of the grade's picture file is drawn by a lesson card.
func test_every_new_picture_kind_teaches_on_a_card() -> void:
	var drawn := {}
	for id in UNITS:
		if not Curriculum.has_content(id):
			continue
		for card: Dictionary in Curriculum.content(id).lesson:
			if card.get("picture") is Dictionary:
				drawn[str(card.picture.get("kind", ""))] = true
	for kind: String in SchoolPictureG8Core.KINDS:
		assert_true(drawn.has(kind), "a lesson card draws %s" % kind)


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG8Core.part_at, at the label
## box's size), so the pins can be trusted; and the units that label have their label exercises.
func test_every_label_points_at_its_part() -> void:
	var checked := 0
	for id: String in LABELS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var n := 0
		for ex in _exercises(id):
			if str(ex.type) != "label":
				continue
			n += 1
			assert_true(SchoolPictureG8Core.KINDS.has(str(ex.picture.kind)), "%s: a grade 8 core picture" % ex.id)
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part := SchoolPictureG8Core.part_at(ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
		assert_gte(n, int(LABELS[id]), "%s: label exercises" % id)
	assert_gte(checked, 20, "labels were checked")


## Owner #112, #115 and #117: the School and Life work together. A unit whose topic is a Life or Success Experience ends
## by naming it, in the LIFE tab; each name is in a real Experience's title.
func test_the_life_experiences_are_named_where_the_topic_is_one() -> void:
	var titles: Array[String] = []
	for id: String in LifeExperience.IDS:
		var d := LifeExperience.data(id)   # each Experience's own file (Life's, Real Builder's, Success's)
		assert_false(d.is_empty(), "%s's data" % id)
		titles.append(str(d.get("title", "")))
	for id: String in LIFE_LINKS:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var last := str((Curriculum.content(id).lesson as Array)[-1].text)
		assert_true(last.contains("LIFE"), "%s: the last card sends the child to the LIFE tab" % id)
		for name: String in LIFE_LINKS[id]:
			assert_true(titles.any(func(t: String) -> bool: return t.contains(name)), "%s: '%s' is a Life Experience" % [
				id, name])
			assert_true(last.contains(name), "%s: the last card names %s" % [id, name])


## A talk's pace, volume, pauses and a mix's balance are heard (a card and exercises to listen to).
func test_listening_is_heard() -> void:
	for id: String in HEARD:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var sounds := 0
		var c := Curriculum.content(id)
		var on_card := false
		for card: Dictionary in c.lesson:
			if card.get("sound") is Dictionary:
				on_card = true
				sounds += 1
		for ex: Dictionary in c.exercises:
			if ex.get("sound") is Dictionary:
				sounds += 1
		assert_true(on_card, "%s: a card to listen to" % id)
		assert_gte(sounds, int(HEARD[id]), "%s: sounds to listen to" % id)


# --- The rules the pictures teach, worked out again (this test's own) ------------------------------------------------

## A circuit's meter readings, from its cell's voltage and its parts' resistances: [current or voltage for each meter].
func _readings(p: Dictionary) -> Array[float]:
	var out: Array[float] = []
	var volts := float(p.volts)
	var ohms: Array[float] = []
	for part: Variant in p.parts:
		ohms.append(float(part[1]) if (part as Array).size() > 1 else -1.0)
	for m: Variant in p.get("meters", []):
		var where := str(m[1])
		if ohms.has(-1.0):
			out.append(NAN)
			continue
		if str(p.layout) == "series":
			var total := 0.0
			for o in ohms:
				total += o
			var amps := volts / total
			if str(m[0]) == "A":
				out.append(amps)
			else:
				out.append(volts if where == "cell" else amps * ohms[int(where)])
		else:
			var amps := 0.0
			for o in ohms:
				amps += volts / o
			if str(m[0]) == "A":
				out.append(amps if where == "main" else volts / ohms[int(where)])
			else:
				out.append(volts)
	return out


## Every number the units ask about a right-angled triangle, a circuit's meters, a meter's units, a parabola's crossing
## and an energy level diagram's change (hand-written and generated) has the answer this test works out.
func test_the_pictures_rules_are_right() -> void:
	var checked := 0
	for id: String in ["g8.maths.trig_ratios", "g8.science.circuits_voltage", "g8.science.energy_bills",
			"g8.maths.expand_factorise", "g8.science.hot_cold_reactions"]:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		for ex in _exercises(id, 20):
			var pic: Variant = ex.get("picture")
			if not pic is Dictionary or str(ex.type) != "number":
				continue
			var kind := str(pic.get("kind", ""))
			var prompt := str(ex.prompt).to_lower()
			var got := NumberAnswer.value(str(ex.answer))
			match kind:
				"trig_triangle":
					var sides: Dictionary = pic.get("sides", {})
					var angle := float(pic.angle)
					var unknown := ""
					for k: String in sides:
						if str(sides[k]) == "?":
							unknown = k
					if unknown == "" or str(pic.get("angle_label", "x")) == "?":
						continue
					var known := ""
					for k: String in sides:
						if k != unknown and str(sides[k]).is_valid_float():
							known = k
					if known == "":
						continue
					# The sides are named from the marked angle wherever it sits, so the ratios are the same.
					var rad := deg_to_rad(angle)
					var unit := {"hyp": 1.0, "opp": sin(rad), "adj": cos(rad)}
					var want := float(sides[known]) / float(unit[known]) * float(unit[unknown])
					assert_almost_eq(got, want, maxf(0.06, want * 0.03), "%s: %s" % [ex.id, ex.prompt])
					checked += 1
				"meter_circuit":
					var meters: Array = pic.get("meters", [])
					for i in meters.size():
						if (meters[i] as Array).size() > 2 and str(meters[i][2]) == "?":
							var want: float = _readings(pic)[i]
							if is_nan(want):
								continue
							assert_almost_eq(got, want, 0.001, "%s: %s" % [ex.id, ex.prompt])
							assert_almost_eq(SchoolPictureG8Core.reading(pic, i), want, 0.001, "%s: the picture's rule"
								% ex.id)
							checked += 1
				"energy_meter":
					if prompt.contains("kwh") and (pic.readings as Array).size() == 2:
						var used := float(str(pic.readings[1][1]).to_int() - str(pic.readings[0][1]).to_int())
						if prompt.contains("cost") or prompt.contains("gold"):
							continue
						assert_almost_eq(got, used, 0.001, "%s: %s" % [ex.id, ex.prompt])
						assert_almost_eq(SchoolPictureG8Core.meter_used(pic), used, 0.001, "%s: the picture's rule" % ex.id)
						checked += 1
				"parabola":
					if prompt.contains("cross"):
						var a := float(pic.get("a", 1))
						var b := float(pic.get("b", 0))
						var c := float(pic.get("c", 0))
						assert_almost_eq(a * got * got + b * got + c, 0.0, 0.001, "%s: %s" % [ex.id, ex.prompt])
						assert_almost_eq(SchoolPictureG8Core.parabola_y(pic, got), 0.0, 0.001, "%s: the picture's rule" %
							ex.id)
						checked += 1
				"energy_profile":
					var values: Array = pic.get("values", [])
					if values.size() == 2 and (prompt.contains("given out") or prompt.contains("taken in")):
						assert_almost_eq(got, absf(float(values[0]) - float(values[1])), 0.001, "%s: %s" % [ex.id,
							ex.prompt])
						checked += 1
	assert_gte(checked, 40, "the pictures' rules were checked")
	assert_eq(_readings({"layout": "series", "volts": 6, "parts": [["lamp", 2], ["lamp", 4]], "meters": [["A",
		"main"], ["V", "1"]]}), [1.0, 4.0] as Array[float])
	assert_eq(_readings({"layout": "parallel", "volts": 6, "parts": [["lamp", 2], ["lamp", 3]], "meters": [["A",
		"main"], ["A", "1"], ["V", "0"]]}), [5.0, 2.0, 6.0] as Array[float])
