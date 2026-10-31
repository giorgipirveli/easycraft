extends GutTest
## Owner #70, #73 and #111 ("we want to have full school programs and sylabusse content in the game"; research §6.8),
## the grade 8 life agent: every HEALTH AND PE, DESIGN AND TECHNOLOGY and PROJECTS unit of grade 8's outline (England's
## KS3 PE, RSHE and D&T, SHAPE America, NHES, CASEL, Jump$tart, Finland's crafts and home economics, the IB MYP, Cambridge
## Global Perspectives) is written, one step up from grade 7 and never repeating it: a lesson of 4 to 8 cards that opens
## with a memory question naming the earlier grade it builds on and ends with something to try in the world and what
## comes next (research §5.3 rules 1, 7 and 8), at least 12 hand-written exercises at levels 1, 2 and 3 of two kinds or
## more, each with a strategy hint and a worked answer, rounds that fill, vary and never show a hand-written exercise
## twice, and the School's quality bar (test_school_quality.gd's `bar`; its scope is grades 3-7, so grade 8's life
## subjects are held to it here). Health is taught kindly (no weight talk, nothing about puberty or reproduction:
## research §5.4 rule 4); alcohol, drugs, tobacco and vaping only in their own unit and gambling only in its own, both
## factually: the risks, the law, saying no and getting help, with no street drug named and nothing that shows use (rule
## 5). Owner #112, #115, #117, #118 (learn by doing; dangerous things learned safely): a unit whose topic is a Life or
## Success Experience ends by naming it in the LIFE tab, by its own title, and D&T's tools by the Tool Book's names. The
## rules the pictures teach (a gear train's ratio, a block and tackle's effort, a prize wheel's expected win, a plan's
## end) are worked out again here. (Every exercise's validity, answers, pictures, sounds and words are the shared content
## test's, test_school_content.gd; the generators' answers are test_g8_life_gen.gd's; the pictures' samples
## test_school_picture_g8life.gd's.)

const GRADE := 8
const UNITS := {"health_pe": 11, "design_tech": 9, "projects": 3}   # research §6.8
const MIN_EXERCISES := 12
const MIN_CARDS := 4
const MIN_DISTINCT := 12
## Grade 8 generators these units use: their own ("g8l", G8LifeGen).
const OWN_GEN := "g8l."
## Words a health lesson for 13-year-olds never uses (research §5.4 rule 4; no weight talk, no shaming about food). (A
## load has a "mass"; a nutrition lesson says "dietary needs".)
const NOT_IN_HEALTH: Array[String] = ["weight", "weights", "overweight", "underweight", "skinny", "fat people", "calorie",
	"calories", "junk", "naughty", "bad food", "bad foods", "diet", "diets", "dieting", "puberty", "reproduction", "sex",
	"sexy", "porn"]
## Alcohol, drugs, tobacco, vaping and solvents (research §5.4 rule 5): only in the unit that teaches them factually.
const SUBSTANCES: Array[String] = ["drug", "drugs", "alcohol", "alcoholic", "beer", "wine", "drunk", "cigarette",
	"cigarettes", "e-cigarette", "e-cigarettes", "tobacco", "smoking", "smoker", "vape", "vapes", "vaping", "nicotine",
	"solvent", "solvents"]
const SUBSTANCES_UNIT := "g8.health_pe.pressure_and_substances"
## Gambling (rule 5, from grade 5): only in its own unit, factually: chance, the house's edge, the law and help.
const GAMBLING: Array[String] = ["gambling", "gamble", "gambler", "gamblers", "bet", "bets", "betting", "bookmaker",
	"casino", "casinos", "lottery", "lotteries", "scratchcard", "scratchcards", "jackpot", "loot box", "loot boxes",
	"slot machine", "slot machines"]
const GAMBLING_UNIT := "g8.health_pe.gambling_harms"
## Never named anywhere (grade 7's ruling: the law's classes are taught by harm, without street names).
const STREET_DRUGS: Array[String] = ["cannabis", "cocaine", "heroin", "ecstasy", "mdma", "lsd", "ketamine", "crack",
	"weed", "skunk", "spice", "meth", "nitrous", "laughing gas"]
## Words that would show or invite use (rule 5: "nothing shows use"), or make gambling look like a way to win.
const SHOWS_USE: Array[String] = ["how to smoke", "take a puff", "have a sip", "try a sip", "try a vape", "try it once",
	"just once", "one won't hurt", "how to take", "how much to take", "safe dose", "get high", "how to win", "sure win",
	"a system to win", "lucky number"]
## Pictures with people in them, never in the substances and gambling units.
const FIGURES: Array[String] = ["pose", "lying", "track_field", "fast_signs", "pitch", "ref_signal", "photo_edit",
	"advert", "cpr_aed", "comic"]
const CURRENCIES: Array[String] = ["dollar", "dollars", "euro", "euros", "pound", "pounds", "pence", "penny", "pennies",
	"yen", "rupee", "rupees", "yuan", "lari"]
## Research §5.4 rule 7: people of the past only (no living people), no brands, apps or trade names (aramid, not the
## brand; low-melt plastic beads, not a trade name; a classroom board, not a product).
const BRANDS: Array[String] = ["instagram", "tiktok", "snapchat", "youtube", "whatsapp", "facebook", "google", "ipad", "macbook",
	"iphone", "samsung", "nintendo", "playstation", "xbox", "fifa", "kevlar", "velcro", "lycra", "gore-tex", "teflon",
	"micro:bit", "microbit", "arduino", "raspberry pi", "lego", "polymorph", "bluetooth", "wi-fi", "fairtrade",
	"nike", "adidas", "fitbit", "chatgpt", "tesla", "dyson", "rowling", "seligman", "berners-lee"]
const PERSONAL := "(what is|what's|tell us|type|enter|write) your (real |full |home |school )?(name|address|phone|number|password|school|birthday|age|email)"
## The facts each lesson must say (research §6.8 goals; the sources are in docs/devlog/parts/m8-grade8-life.md).
const MUST := {
	"g8.health_pe.game_strategy": ["scan", "formation", "4-4-2", "possession", "overload", "compact", "half-time",
		"gaps"],
	"g8.health_pe.fitness_testing": ["multistage", "sit-and-reach", "grip", "illinois", "valid", "reliable", "rating",
		"profile"],
	"g8.health_pe.active_for_life": ["150 minutes", "75 minutes", "twice a week", "vigorous", "moderate", "club",
		"taster", "active travel"],
	"g8.health_pe.mental_health_support": ["anxiety", "low mood", "fight, flight or freeze", "thinking trap",
		"avoid", "two weeks", "0800 1111", "a friend"],
	"g8.health_pe.bouncing_back": ["resilience", "setback", "forever", "everything", "all me", "even better if",
		"support", "wilma rudolph"],
	"g8.health_pe.respect_online": ["respect", "control", "consent", "under 18", "never your fault",
		"report remove", "ceop", "footprint", "upstander"],
	"g8.health_pe.gambling_harms": ["chance", "18", "the house", "expected", "no memory", "loot box", "chasing losses",
		"0808 8020 133"],
	"g8.health_pe.pressure_and_substances": ["peer pressure", "most young people", "25", "under 18", "nicotine",
		"single-use vapes", "code word", "frank", "999"],
	"g8.health_pe.cpr_defibrillator": ["cardiac arrest", "not breathing normally", "999", "centre of the chest",
		"5 to 6 cm", "100 to 120", "30", "defibrillator", "pads", "trained adult", "pantridge"],
	"g8.health_pe.health_campaign": ["campaign", "advocacy", "survey", "smart", "audience", "message",
		"percentage points", "before and after"],
	"g8.health_pe.digital_balance": ["balance", "notifications", "autoplay", "focus", "an hour", "outside the bedroom",
		"20-20-20", "screen-time"],
	"g8.design_tech.brief_to_product": ["design brief", "specification", "client", "constraints", "anthropometrics",
		"gantt", "tolerance", "cutting list", "quality control"],
	"g8.design_tech.smart_materials": ["smart material", "shape-memory", "nickel-titanium", "thermochromic",
		"photochromic", "piezoelectric", "composite", "matrix", "density", "graphene"],
	"g8.design_tech.programmable_product": ["sensor", "input", "process", "output", "threshold", "closed loop",
		"open loop", "flowchart", "battery", "mah"],
	"g8.design_tech.mechanical_advantage": ["mechanical advantage", "load", "effort", "velocity ratio", "efficiency",
		"gear ratio", "rpm", "compound", "idler", "pulley"],
	"g8.design_tech.big_structures": ["dead load", "live load", "factor of safety", "tuned mass damper",
		"base isolation", "cross-bracing", "suspension", "tension", "compression", "wind tunnel"],
	"g8.design_tech.nutrition_for_life": ["macronutrients", "micronutrients", "carbohydrate", "protein", "fat", "fibre",
		"vitamin d", "calcium", "iron", "gluten", "per 100 g", "6 g"],
	"g8.design_tech.food_production": ["arable", "livestock", "primary processing", "secondary processing",
		"pasteuris", "72 °c", "food miles", "air", "seasonal", "organic", "intensive"],
	"g8.design_tech.circular_design": ["linear", "circular economy", "maintain", "refurbish", "remanufacture",
		"recycle", "disassembly", "biological", "technical", "cost per year", "right to repair"],
	"g8.design_tech.future_tech": ["artificial intelligence", "robot", "internet of things", "levels",
		"social", "environmental", "economic", "ethical", "responsible", "standby"],
	"g8.projects.invention_expo": ["problem", "user", "sensor", "program", "test", "mean", "improve", "expo", "demo",
		"budget"],
	"g8.projects.history_documentary": ["turning point", "primary source", "secondary source", "storyboard", "shot",
		"frames", "narration", "credit", "accurate"],
	"g8.projects.global_goal_campaign": ["global goal", "data", "sample", "leading question", "chart", "scatter",
		"correlation", "per 100 m", "percent"],
}
## The pictures each unit needs, over its lesson, its exercises and its generators' ([kind, how many], …).
const DRAWS := {
	"g8.health_pe.game_strategy": [["pitch", 3], ["table", 1]],
	"g8.health_pe.fitness_testing": [["fitness_profile", 3], ["table", 1]],
	"g8.health_pe.active_for_life": [["talk_test", 1], ["table", 1]],
	"g8.health_pe.mental_health_support": [["feeling_curve", 2], ["breath_box", 1]],
	"g8.health_pe.bouncing_back": [["step_chain", 1], ["table", 1]],
	"g8.health_pe.respect_online": [["chat", 2], ["step_chain", 1]],
	"g8.health_pe.gambling_harms": [["chance_wheel", 3]],
	"g8.health_pe.pressure_and_substances": [["table", 1], ["step_chain", 1]],
	"g8.health_pe.cpr_defibrillator": [["cpr_aed", 3], ["step_chain", 1]],
	"g8.health_pe.health_campaign": [["bar_graph", 2], ["step_chain", 1]],
	"g8.health_pe.digital_balance": [["phone_feed", 1], ["pie_chart", 1]],
	"g8.design_tech.brief_to_product": [["making_plan", 2], ["access_fm", 1], ["table", 1]],
	"g8.design_tech.smart_materials": [["smart_material", 3], ["table", 1]],
	"g8.design_tech.programmable_product": [["sensor_system", 1], ["threshold_graph", 1], ["text_code", 2],
		["flowchart", 1]],
	"g8.design_tech.mechanical_advantage": [["gear_train", 3], ["block_tackle", 3], ["lever_class", 1]],
	"g8.design_tech.big_structures": [["tall_structure", 3]],
	"g8.design_tech.nutrition_for_life": [["plate", 1], ["table", 2]],
	"g8.design_tech.food_production": [["step_chain", 1], ["bar_graph", 1]],
	"g8.design_tech.circular_design": [["circular_loop", 3]],
	"g8.design_tech.future_tech": [["balance_scale", 1], ["table", 1]],
	"g8.projects.invention_expo": [["making_plan", 1], ["text_code", 1], ["table", 1]],
	"g8.projects.history_documentary": [["event_timeline", 1], ["comic", 1]],
	"g8.projects.global_goal_campaign": [["scatter_plot", 2], ["bar_graph", 1]],
}
## Units whose label exercises must exist (label the diagram), with how many.
const LABELS := {"g8.health_pe.cpr_defibrillator": 2, "g8.design_tech.smart_materials": 1,
	"g8.design_tech.big_structures": 2, "g8.design_tech.circular_design": 1}
## Owner #112, #115, #117 (learn by doing): the units whose topic is a Life or Success Experience end by naming it (in
## its title: data/life/experiences/, data/success/experiences/, data/tools/real_builder.json, or the Tool Book) in the
## LIFE tab.
const LIFE_LINKS := {
	"g8.health_pe.fitness_testing": ["Goal Board", "Tool Book"],
	"g8.health_pe.active_for_life": ["Goal Board"],
	"g8.health_pe.mental_health_support": ["Calm Corner"],
	"g8.health_pe.bouncing_back": ["Goal Board", "Success Stories"],
	"g8.health_pe.respect_online": ["Calm Corner", "Connections Book"],
	"g8.health_pe.gambling_harms": ["My Money Stall"],
	"g8.health_pe.pressure_and_substances": ["Calm Corner", "Poisons Cupboard"],
	"g8.health_pe.cpr_defibrillator": ["Little Lifesaver"],
	"g8.health_pe.health_campaign": ["Talk & Deal"],
	"g8.health_pe.digital_balance": ["Goal Board", "Calm Corner"],
	"g8.design_tech.brief_to_product": ["Real Builder"],
	"g8.design_tech.smart_materials": ["Real Builder"],
	"g8.design_tech.programmable_product": ["Poisons Cupboard", "Tool Book"],
	"g8.design_tech.mechanical_advantage": ["Tool Book"],
	"g8.design_tech.big_structures": ["Earth and Weather", "Real Builder"],
	"g8.design_tech.nutrition_for_life": ["The Kitchen"],
	"g8.design_tech.food_production": ["The Kitchen"],
	"g8.design_tech.circular_design": ["Tool Book"],
	"g8.design_tech.future_tech": ["Success Stories"],
	"g8.projects.invention_expo": ["Talk & Deal", "Tool Book"],
	"g8.projects.history_documentary": ["Success Stories"],
	"g8.projects.global_goal_campaign": ["Goal Board", "Talk & Deal"],
}
## The Tool Book's tools a unit's last card names (their ids in data/tools/tools.json, by their names there).
const TOOL_LINKS := {
	"g8.health_pe.fitness_testing": ["stopwatch", "tape"],
	"g8.design_tech.programmable_product": ["co_alarm"],
	"g8.design_tech.mechanical_advantage": ["spanner", "hammer"],
	"g8.design_tech.circular_design": ["sandpaper", "pliers"],
	"g8.projects.invention_expo": ["stopwatch"],
}
## A rhythm is heard where a beat is taught (CPR's 100 to 120 pushes a minute).
const HEARD := {"g8.health_pe.cpr_defibrillator": 2}


func _units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for subject: String in UNITS:
		out.append_array(Curriculum.units(GRADE, subject))
	return out


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
	for subject: String in UNITS:
		assert_eq(Curriculum.units(GRADE, subject).size(), int(UNITS[subject]), "grade 8 %s" % subject)


func test_grade_8_health_dt_projects_are_written_for_every_unit() -> void:
	var exercises := 0
	var cards := 0
	for u in _units():
		var id := str(u.id)
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
	gut.p("grade 8 health and PE, D&T and projects: %d cards, %d hand-written exercises" % [cards, exercises])


## The School's quality bar (owner #94; test_school_quality.gd, whose scope is grades 3-7): memory first, the world or
## what comes next last, 4-8 cards, pictures (two in D&T), three kinds of exercise, at most 70% choice and
## true-or-false, three a level or a generator, real hints and worked answers, no hint that gives the answer away.
func test_every_unit_meets_the_schools_quality_bar() -> void:
	var quality: Node = load("res://tests/unit/test_school_quality.gd").new()
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		assert_eq(quality.call("bar", id, id.split(".")[1]), [] as Array[String], "%s meets the bar" % id)
	quality.free()


## The outline keeps its standards and goals, and every unit names its own grade 8 file.
func test_the_files_are_their_own() -> void:
	for u in _units():
		var parts := str(u.id).split(".")
		assert_eq(str(u.get("file", "")), "g8/%s/%s.json" % [parts[1], parts[2]], "%s's file" % u.id)
		assert_gt((u.get("standards", []) as Array).size(), 0, "%s: its standards" % u.id)
		assert_gt((u.get("goals", []) as Array).size(), 0, "%s: its goals" % u.id)
		assert_null(u.get("hard"), "%s is not hard history" % u.id)


## Research §5.3: every exercise has a strategy hint (not the answer itself) and a worked answer.
func test_every_exercise_has_a_strategy_hint_and_a_worked_answer() -> void:
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			assert_ne(str(ex.get("hint", "")).strip_edges(), "", "%s: a hint" % ex.id)
			assert_ne(str(ex.get("explain", "")).strip_edges(), "", "%s: a worked answer" % ex.id)
			assert_ne(str(ex.hint), str(ex.get("explain", "")), "%s: the hint is a strategy, not the answer" % ex.id)


## Research §5.3 rules 1, 7 and 8: a memory question from an earlier grade (3 to 7) first; something to try in the
## world and what comes next last.
func test_every_lesson_starts_with_memory_of_an_earlier_grade_and_ends_in_the_world_with_what_comes_next() -> void:
	var earlier := RegEx.create_from_string("grade [34567]\\b")
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
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
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		var seen := {}
		for ex: Dictionary in Curriculum.content(id).exercises:
			var key := str(ex.prompt) + str(ex.get("picture", ""))
			assert_false(seen.has(key), "%s asks twice: %s" % [id, ex.prompt])
			seen[key] = true


## The units use grade 8's own health, D&T and projects generators ("g8l"), each of which exists, every unit practises
## with one, and every "g8l" generator is used by one of them.
func test_the_units_use_their_own_generators() -> void:
	var used := {}
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		var gens: Array = Curriculum.content(str(u.id)).generators
		assert_false(gens.is_empty(), "%s practises with a generator too" % u.id)
		for g: Dictionary in gens:
			var gen := str(g.gen)
			assert_true(gen.begins_with(OWN_GEN), "%s uses %s" % [u.id, gen])
			assert_true(SchoolGen.exists(gen), "%s: %s exists" % [u.id, gen])
			used[gen] = true
	var own := 0
	for gen in SchoolGen.ids():
		if gen.begins_with(OWN_GEN):
			own += 1
			assert_true(used.has(gen), "%s is used by a grade 8 health, D&T or project unit" % gen)
	assert_gt(own, 40, "grade 8's health, D&T and projects generators exist")


## The facts a child's safety and health depend on, and each unit's goals, are in the lessons.
func test_the_lessons_teach_their_facts() -> void:
	for id: String in MUST:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var lesson := _lesson(id)
		for fact: String in MUST[id]:
			assert_true(lesson.contains(fact.to_lower()), "%s's lesson says '%s'" % [id, fact])


## Research §5.4 rule 4 and the brief: never shaming about bodies or food, no weight talk, nothing about puberty or
## reproduction, in any card, exercise or generated exercise.
func test_health_is_taught_kindly() -> void:
	var found: Array[String] = []
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for t in _all_texts(str(u.id)):
			var w := _found(t, NOT_IN_HEALTH)
			if w != "":
				found.append("%s: '%s' in: %s" % [u.id, w, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


## Research §5.4 rule 5: alcohol, drugs, tobacco, vaping and solvents only in their own unit, and gambling only in its
## own (each factual: the risks, the law, saying no and getting help), no street drug named anywhere, nothing that
## shows or invites use, and no people drawn in those two units; and they teach the law and where to get help.
func test_substances_and_gambling_are_taught_only_factually_in_their_own_units() -> void:
	var found: Array[String] = []
	for u in _units():
		var id := str(u.id)
		if not Curriculum.has_content(id):
			continue
		for t in _all_texts(id):
			var w := _found(t, SUBSTANCES)
			if w != "" and id != SUBSTANCES_UNIT:
				found.append("%s: '%s' in: %s" % [id, w, t])
			var g := _found(t, GAMBLING)
			if g != "" and id != GAMBLING_UNIT:
				found.append("%s: '%s' in: %s" % [id, g, t])
			var street := _found(t, STREET_DRUGS)
			if street != "":
				found.append("%s: '%s' in: %s" % [id, street, t])
			var use := _found(t, SHOWS_USE)
			if use != "":
				found.append("%s: '%s' in: %s" % [id, use, t])
	assert_eq(found, [] as Array[String], "\n".join(found))
	var musts := {SUBSTANCES_UNIT: ["against the law", "say no", "trusted adult", "frank", "childline"],
		GAMBLING_UNIT: ["18", "trusted adult", "childline", "helpline"]}
	for id: String in musts:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var lesson := _lesson(id)
		for w: String in musts[id]:
			assert_true(lesson.contains(w), "%s's lesson says '%s'" % [id, w])
		for p in _pictures(id, 6):
			assert_false(str(p.get("kind", "")) in FIGURES, "%s: no people drawn" % id)


## Money is the game's gold (research §5.5 ruling 6), no lesson asks a child for personal details (rule 6), and no brand
## or living person is named (rule 7).
func test_money_is_gold_nothing_personal_is_asked_and_no_brands() -> void:
	var ask := RegEx.create_from_string(PERSONAL)
	for u in _units():
		var id := str(u.id)
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
	for u in _units():
		if not Curriculum.has_content(str(u.id)):
			continue
		for card: Dictionary in Curriculum.content(str(u.id)).lesson:
			if card.get("picture") is Dictionary:
				drawn[str(card.picture.get("kind", ""))] = true
	for kind: String in SchoolPictureG8Life.KINDS:
		assert_true(drawn.has(kind), "a lesson card draws %s" % kind)


## Label the diagram: every label's line ends on its own part of the picture (SchoolPictureG8Life.part_at, at the label
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
			assert_true(SchoolPictureG8Life.KINDS.has(str(ex.picture.kind)), "%s: a grade 8 life picture" % ex.id)
			for i in (ex.labels as Array).size():
				var spot: Array = ex.spots[int(ex.answer[i])]
				assert_eq(spot.size(), 4, "%s: a line from the pin to the part" % ex.id)
				if spot.size() != 4:
					continue
				var part := SchoolPictureG8Life.part_at(ex.picture, str(ex.labels[i]), ExerciseCheck.LABEL_BOX)
				assert_ne(part, Vector2(-1, -1), "%s: the picture has a %s" % [ex.id, ex.labels[i]])
				var tip := Vector2(float(spot[2]), float(spot[3])) * ExerciseCheck.LABEL_BOX
				assert_lt(tip.distance_to(part), 14.0, "%s: the line to %s ends on it" % [ex.id, ex.labels[i]])
				checked += 1
		assert_gte(n, int(LABELS[id]), "%s: label exercises" % id)
	assert_gte(checked, 20, "labels were checked")


## Owner #112, #115 and #117: the School and Life work together. A unit whose topic is a Life or Success Experience ends
## by naming it, in the LIFE tab; each name is in a real Experience's title (or the Tool Book), and each tool named is
## in the Tool Book.
func test_the_life_experiences_are_named_where_the_topic_is_one() -> void:
	var titles: Array[String] = ["Tool Book"]
	for id: String in LifeExperience.IDS:
		var d := LifeExperience.data(id)   # each Experience's own file (Life's, Real Builder's, Success's)
		assert_false(d.is_empty(), "%s's data" % id)
		titles.append(str(d.get("title", "")))
	var tools := {}
	for t: Variant in ToolBook.data().get("tools", []):
		tools[str(t.id)] = str(t.name)
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
		for tool: String in TOOL_LINKS.get(id, []):
			assert_true(tools.has(tool), "%s: %s is in the Tool Book" % [id, tool])
			assert_true(last.to_lower().contains(str(tools.get(tool, "?")).to_lower()), "%s names the %s" % [id,
				tools.get(tool, tool)])


## CPR's beat is heard (a card and an exercise to copy), and every project has a build on the block board.
func test_the_beat_is_heard_and_projects_are_built() -> void:
	for id: String in HEARD:
		if not Curriculum.has_content(id):
			fail_test("%s is not written" % id)
			continue
		var sounds := 0
		var c := Curriculum.content(id)
		for item: Dictionary in (c.lesson as Array) + (c.exercises as Array):
			if item.get("sound") is Dictionary:
				sounds += 1
		assert_gte(sounds, int(HEARD[id]), "%s: a beat to listen to" % id)
	for u in Curriculum.units(GRADE, "projects"):
		if not Curriculum.has_content(str(u.id)):
			fail_test("%s is not written" % u.id)
			continue
		var builds := 0
		for ex: Dictionary in Curriculum.content(str(u.id)).exercises:
			builds += 1 if str(ex.type) == "build" else 0
		assert_gte(builds, 1, "%s: a build on the block board" % u.id)


# --- The rules the pictures teach, worked out again (this test's own) ------------------------------------------------

## A gear train's ratio: each stage's driven teeth ÷ its driver's, multiplied.
func _ratio(stages: Array) -> float:
	var r := 1.0
	for s: Variant in stages:
		r *= float(s[1]) / float(s[0])
	return r


## The share of a prize wheel's slices that win each prize, times the prize: the gold a spin wins on average.
func _expected(slices: Array) -> float:
	var total := 0
	var won := 0.0
	for s: Variant in slices:
		total += int(s[1])
		won += int(s[1]) * (float(s[2]) if (s as Array).size() > 2 else 0.0)
	return won / total


## A plan's last column: the latest end of its tasks.
func _plan_end(tasks: Array) -> int:
	var out := 0
	for t: Variant in tasks:
		out = maxi(out, int(t[1]) + int(t[2]))
	return out


## Every number the units ask about a gear train's ratio, a block and tackle's effort, a prize wheel's expected win and a
## plan's end (hand-written and generated) has the answer this test works out, and the pictures' own rules agree.
func test_the_pictures_rules_are_right() -> void:
	var checked := 0
	for id: String in ["g8.design_tech.mechanical_advantage", "g8.health_pe.gambling_harms",
			"g8.design_tech.brief_to_product", "g8.projects.invention_expo"]:
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
			if kind == "gear_train" and prompt.contains("ratio"):
				assert_almost_eq(got, _ratio(pic.stages), 0.001, "%s: %s" % [ex.id, ex.prompt])
				assert_almost_eq(SchoolPictureG8Life.train_ratio(pic.stages), _ratio(pic.stages), 0.001,
					"%s: the picture's rule" % ex.id)
				checked += 1
			elif kind == "block_tackle" and prompt.contains("effort") and str(pic.get("effort", "")) == "?":
				assert_almost_eq(got, float(pic.load) / int(pic.ropes), 0.001, "%s: %s" % [ex.id, ex.prompt])
				assert_almost_eq(SchoolPictureG8Life.tackle_effort(float(pic.load), int(pic.ropes)), float(pic.load)
					/ int(pic.ropes), 0.001, "%s: the picture's rule" % ex.id)
				checked += 1
			elif kind == "chance_wheel" and prompt.contains("on average"):
				var per_spin := _expected(pic.slices)
				var spins := 1
				var m := RegEx.create_from_string("(\\d+) spins").search(prompt)
				if m != null:
					spins = int(m.get_string(1))
				var want := per_spin * spins
				if prompt.contains("lose"):
					want = float(pic.cost) * spins - per_spin * spins
				assert_almost_eq(got, want, 0.001, "%s: %s" % [ex.id, ex.prompt])
				assert_almost_eq(SchoolPictureG8Life.expected_win(pic.slices), per_spin, 0.001, "%s: the picture's rule"
					% ex.id)
				checked += 1
			elif kind == "making_plan" and prompt.contains("finish"):
				assert_eq(int(got), _plan_end(pic.tasks), "%s: %s" % [ex.id, ex.prompt])
				assert_eq(SchoolPictureG8Life.plan_end(pic.tasks), _plan_end(pic.tasks), "%s: the picture's rule" % ex.id)
				checked += 1
	assert_gte(checked, 20, "the pictures' rules were checked")
	assert_almost_eq(_ratio([[10, 40], [15, 30]]), 8.0, 0.001)
	assert_almost_eq(_expected([["5 gold", 1, 5], ["nothing", 9, 0]]), 0.5, 0.001)
	assert_eq(_plan_end([["cut", 0, 2], ["paint", 3, 2]]), 5)
