extends GutTest
## Owner #112, #113 (docs/design/life-skills.md §3, §5, §6, §11): the three L1 Experiences as data
## (data/life/experiences/*.json): each on the Little, Middle and Big track, with its steps (every one valid), its
## Expert try, its before-and-after picture check, its "name it" card in the authorities' words with the source, its Try
## it for real card, its "your child can now..." words and its sources. The region's number is dialled and said; the
## money varies with the seed; the first aid tracks say they are practice. An automatic player finishes every track.

const PRACTICE_NOTE := "This is practice. A real first aid course teaches more."
const UNKIND: Array[String] = ["miss you", "don't go", "lonely", "last chance", "hurry", "only today", "you failed",
	"failure", "loser", "for babies", "noob", "streak", "wrong!", "stupid", "dumb", "idiot", "lazy", "you lose", "blood",
	"bleeding to death", "die", "dies", "dead", "death", "scream", "kill", "burn to"]
const US_SPELLINGS: Array[String] = ["color", "colors", "center", "centers", "meter", "meters", "favorite", "gray",
	"neighbor", "neighbors", "math", "behavior", "honor", "organize", "realize", "practicing", "practiced"]
const ALLOWED := "×÷−°²³½¼¾•’“”—…"


func _texts_of(v: Variant, out: Array[String]) -> void:
	if v is String:
		out.append(v)
	elif v is Array:
		for x: Variant in v:
			_texts_of(x, out)
	elif v is Dictionary:
		for k: Variant in v:
			if str(k) not in ["id", "kind", "target", "targets", "icon", "action", "url", "view", "react", "room", "vary",
					"mode", "area", "experience"]:
				_texts_of(v[k], out)


func _all_words() -> Array[String]:
	var out: Array[String] = []
	for id in LifeExperience.IDS:
		_texts_of(LifeExperience.data(id), out)
	return out


func test_the_twenty_experiences_load() -> void:
	assert_eq(LifeExperience.IDS, ["little_lifesaver", "fire_escape", "money_stall", "safe_streets", "kitchen",
		"calm_corner", "real_builder", "water_safety", "poisons_cupboard", "earth_weather", "electricity", "animals",
		"medical", "online_city", "find_way", "home_helper", "goal_board", "talk_deal", "connections",
		"success_stories", "my_shop", "market_square"] as Array[String],
		"L1's three, L2's three, Real Builder, L3a's, L3b's and L3c's three, Success S2's four and S3's two (owner #112, #116, #118, #115)")
	for id in LifeExperience.IDS:
		assert_false(LifeExperience.data(id).is_empty(), id)
		assert_ne(str(LifeExperience.data(id).get("title", "")), "", id)


func test_every_experience_has_no_problems() -> void:
	for id in LifeExperience.IDS:
		assert_eq(LifeExperience.problems(id), [] as Array[String], id)


func test_every_track_has_its_steps_check_cards_and_sources() -> void:
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			var t := LifeExperience.track_data(id, track)
			var where := "%s.%s" % [id, track]
			assert_ne(str(t.get("skill", "")), "", where)
			assert_gte(LifeExperience.steps(id, track, false, 1, "ge").size(), 5, where)
			var check := LifeExperience.check(id, track, "ge")
			assert_between(check.size(), 3, 5, where + ": 3-5 picture questions")
			var card: Dictionary = t.get("name_it", {})
			assert_between((card.get("lines", []) as Array).size(), 3, 5, where + ": the name-it card's steps")
			assert_ne(str(card.get("source", "")), "", where + ": the card names its authority")
			assert_ne(str(t.get("try_real", "")), "", where)
			assert_ne(str(t.get("can_now", "")), "", where)
			var sources: Array = t.get("sources", [])
			assert_gte(sources.size(), 2, where)
			for s: Dictionary in sources:
				assert_true(str(s.get("url", "")).begins_with("https://"), "%s: %s" % [where, s])
				assert_ne(str(s.get("fact", "")), "", where)


func test_every_check_question_has_pictures() -> void:
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			for q: Dictionary in LifeExperience.check(id, track, "ge"):
				assert_eq(LifeCheck.problem(q), "", "%s.%s: %s" % [id, track, q.get("say")])
				for c: Dictionary in q.choices:
					assert_true(LifeIcons.has(str(c.get("icon", ""))), "%s.%s: %s's icon %s" % [id, track, c.text,
						c.get("icon")])


func test_every_choice_in_the_steps_has_a_known_picture() -> void:
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for step: Dictionary in LifeExperience.steps(id, track, expert, 2, "us"):
					for c: Variant in step.get("choices", []):
						assert_true(LifeIcons.has(str((c as Dictionary).get("icon", ""))), "%s.%s %s: %s" % [id, track,
							step.id, c])


## Owner #117 (docs/design/life-skills.md §13): every step that uses a real motion names it (one of the ten), so the
## shared tool recogniser can take over later without a rule changing; the motions the owner's alignment names.
func _step(id: String, track: String, step_id: String, expert: bool = false) -> Dictionary:
	for s: Dictionary in LifeExperience.steps(id, track, expert, 1, "ge"):
		if str(s.id) == step_id:
			return s
	return {}


func test_every_hands_on_step_names_its_motion() -> void:
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for s: Dictionary in LifeExperience.steps(id, track, expert, 1, "ge"):
					if str(s.kind) in ["rhythm", "taps", "sequence", "coins", "basket", "sweep", "point", "hands", "rub", "pour",
							"steady"]:
						assert_has(LifeCheck.MOTIONS, str(s.get("motion", "")), "%s.%s %s" % [id, track, s.id])


func test_the_motions_the_owner_named() -> void:
	assert_eq(str(_step("little_lifesaver", "big", "cpr").motion), "press", "CPR: press")
	assert_eq(str(_step("little_lifesaver", "middle", "press").motion), "press", "the cloth on a cut: press")
	assert_eq(str(_step("little_lifesaver", "middle", "press").tool), "cloth")
	assert_eq(str(_step("fire_escape", "big", "squeeze").motion), "squeeze", "the extinguisher: squeeze...")
	assert_eq(str(_step("fire_escape", "big", "aim").motion), "aim", "...and aim")
	assert_eq(str(_step("fire_escape", "big", "sweep").motion), "aim")
	assert_eq(str(_step("money_stall", "middle", "change").motion), "press", "giving change: a press for now")
	assert_eq(str(_step("little_lifesaver", "middle", "tap").motion), "twist", "a tap twists")
	assert_eq(str(_step("little_lifesaver", "big", "blows").motion), "strike", "back blows")


## Life L2 (owner #117): the kitchen's tools, the street's belts, buckles and pedals, each with its real motion.
func test_the_motions_of_l2s_tools() -> void:
	assert_eq(str(_step("kitchen", "little", "cut").motion), "cut", "a child-safe knife cuts")
	assert_eq(str(_step("kitchen", "little", "cut").tool), "knife", "the Tool Book's knife (its child-safe grip; owner #117)")
	assert_eq(str(_step("kitchen", "little", "tap").motion), "twist", "a tap twists")
	assert_eq(str(_step("kitchen", "little", "rub").motion), "stroke", "hands rub back and forth")
	assert_eq(str(_step("kitchen", "little", "pour").motion), "pour", "a jug pours")
	assert_eq(str(_step("kitchen", "middle", "weigh").motion), "measure", "the scales measure")
	assert_eq(str(_step("kitchen", "middle", "whisk").motion), "stroke", "a whisk strokes")
	assert_eq(str(_step("kitchen", "middle", "knob").motion), "twist", "the hob's knob twists")
	assert_eq(str(_step("kitchen", "big", "tray").motion), "squeeze", "oven gloves squeeze the tray")
	assert_eq(str(_step("safe_streets", "little", "belt").motion), "stroke", "a belt is pulled across")
	assert_eq(str(_step("safe_streets", "middle", "buckle").motion), "squeeze", "a buckle clicks shut")
	assert_eq(str(_step("safe_streets", "middle", "fingers").motion), "measure", "two fingers measure the helmet")
	assert_eq(str(_step("safe_streets", "big", "brake").motion), "press", "the brake")
	assert_eq(str(_step("safe_streets", "middle", "button").device), "crossing")
	assert_eq(str(_step("kitchen", "big", "switch").device), "kettle")
	assert_eq(str(_step("kitchen", "middle", "handle").device), "hob")
	assert_eq(str(_step("calm_corner", "big", "block").device), "tablet")


## The device model (controls, what it shows, the right order, its safety steps): the play phone, the extinguisher, the
## shop's till.
func test_the_devices_are_described_and_named_by_their_steps() -> void:
	assert_eq(str(_step("little_lifesaver", "little", "dial").device), "phone")
	assert_eq(str(_step("fire_escape", "middle", "dial").device), "phone")
	for step_id: String in ["pin", "aim", "squeeze", "sweep"]:
		assert_eq(str(_step("fire_escape", "big", step_id).device), "extinguisher", step_id)
	assert_eq(str(_step("money_stall", "middle", "shop").device), "till")
	for id in LifeExperience.IDS:
		var devices := LifeExperience.devices(id, "ge")
		assert_false(devices.is_empty(), id)
		for d: String in devices:
			for key: String in ["controls", "shows", "order", "safety"]:
				assert_gt((devices[d].get(key, []) as Array).size(), 0, "%s's %s: its %s" % [id, d, key])
	assert_string_contains(" ".join(PackedStringArray(LifeExperience.devices("little_lifesaver", "uk").phone.order)), "999",
		"a device's steps are filled for the region")


func test_the_first_aid_tracks_say_they_are_practice() -> void:
	for track in LifeData.TRACKS:
		var said := false
		for step: Dictionary in LifeExperience.steps("little_lifesaver", track, false, 1, "ge"):
			said = said or str(step.say).contains(PRACTICE_NOTE)
		assert_true(said, track)


func test_the_regions_number_is_dialled_and_said() -> void:
	for region: String in ["ge", "uk", "us", "au"]:
		var steps := LifeExperience.steps("little_lifesaver", "little", false, 1, region)
		var dialled := false
		for step: Dictionary in steps:
			if str(step.kind) == "sequence":
				assert_eq(step.targets, LifeRegion.keys(LifeRegion.number(region)), region)
				dialled = true
			assert_false(str(step.say).contains("{"), "%s: every word filled in: %s" % [region, step.say])
		assert_true(dialled, region)
		var all := " ".join(PackedStringArray(steps.map(func(s: Dictionary) -> String: return str(s.say))))
		assert_true(all.contains(LifeRegion.number(region)), region)


func test_every_track_has_an_expert_try() -> void:
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			var normal := LifeExperience.steps(id, track, false, 1, "ge")
			var expert := LifeExperience.steps(id, track, true, 1, "ge")
			assert_ne(str(LifeExperience.track_data(id, track).get("twist", "")), "", "%s.%s: the twist's words" % [id,
				track])
			assert_ne(JSON.stringify(normal), JSON.stringify(expert), "%s.%s: the Expert try is different" % [id, track])


func test_the_money_varies_with_the_seed() -> void:
	var seen := {}
	for seed in 20:
		seen[JSON.stringify(LifeExperience.steps("money_stall", "middle", false, seed, "ge"))] = true
	assert_gt(seen.size(), 2)


func test_an_automatic_player_finishes_every_track_by_itself() -> void:
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for seed in 4:
					var run := LifeRun.new(LifeExperience.steps(id, track, expert, seed, "ge"), expert)
					var frames := 0
					while not run.finished and frames < 5000:
						run.feed(LifeAuto.sample(run.current(), run.state, 0.1))
						frames += 1
					var where := "%s.%s expert=%s seed=%d" % [id, track, expert, seed]
					assert_true(run.finished, where + " stuck at " + str(run.current().get("id", "")))
					assert_eq(int(run.outcome().hints), 0, where)


func test_the_words_are_kind_calm_english_and_british() -> void:
	var found: Array[String] = []
	for t in _all_words():
		var lower := t.to_lower()
		for w in UNKIND + US_SPELLINGS:
			if RegEx.create_from_string("\\b" + w + "\\b").search(lower):
				found.append("'%s' in: %s" % [w, t])
		for ch in t:
			if ch.unicode_at(0) > 127 and not ALLOWED.contains(ch):
				found.append("'%s' in: %s" % [ch, t])
				break
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_nothing_asks_for_an_address_or_a_name_to_be_typed() -> void:
	for t in _all_words():
		var lower := t.to_lower()
		assert_false(lower.contains("type your"), t)
		assert_false(lower.contains("enter your"), t)


## The lead (owner #116, round 4b's hooks): Real Builder is a Life Experience: its data from the tools' file, its room the
## building site, its units on Life's map launch it (no longer "coming soon").
func test_real_builder_is_wired_into_life() -> void:
	assert_false(LifeExperience.data(RealBuilder.ID).is_empty(), "its data from data/tools")
	assert_true(LifeRooms.make("building_site", "little") is RealBuilderSite, "its room: the building site")
	var launches := 0
	for u: Dictionary in LifeCatalog.all_units():
		if str(u.get("experience", "")) == RealBuilder.ID:
			launches += 1
			assert_false(u.has("soon"), "%s: not 'coming soon'" % u.id)
	assert_eq(launches, 3, "one unit per track launches it")
