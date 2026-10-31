extends GutTest
## Owner #116, #117 (docs/superpowers/plans/2026-10-16-vr-round4.md "Round 4b"): Real Builder as a Life Experience
## (data/tools/real_builder.json, Life L1's format and rules): three tracks (Little: a little wall of big blocks; Middle:
## a garden shed; Big: a small house), each with an Expert try, its check, its card, its sources, Try it for real; safety
## first; every tool step uses its tool the real way (the Tool Book's motions); the numbers in its words are the
## brickwork's own (BrickBond); its Life units meet the School's bar; its catalogue entries wait for the lead's hook.

const UNKIND: Array[String] = ["miss you", "don't go", "lonely", "last chance", "hurry", "only today", "you failed",
	"failure", "loser", "for babies", "noob", "streak", "wrong!", "stupid", "dumb", "idiot", "lazy", "you lose", "blood",
	"die", "dead", "death", "scream", "kill"]
const US_SPELLINGS: Array[String] = ["color", "colors", "center", "centers", "meter", "meters", "favorite", "gray",
	"neighbor", "math", "behavior", "honor", "organize", "realize", "practicing", "practiced"]
const ALLOWED := "×÷−°²³½¼¾•’“”—…"


func before_each() -> void:
	RealBuilder.clear_cache()


func _texts(v: Variant, out: Array[String]) -> void:
	if v is String:
		out.append(v)
	elif v is Array:
		for x: Variant in v:
			_texts(x, out)
	elif v is Dictionary:
		for k: Variant in v:
			if str(k) not in ["id", "kind", "target", "targets", "icon", "url", "view", "react", "after", "goes", "room",
					"mode", "area", "motion", "tool", "device", "gear", "safety", "do"]:
				_texts(v[k], out)


func test_it_has_no_problems() -> void:
	assert_eq(RealBuilder.problems(), [] as Array[String])


func test_three_tracks_each_with_an_expert_try() -> void:
	for track in LifeData.TRACKS:
		var normal := RealBuilder.steps(track, false, 1, "ge")
		var expert := RealBuilder.steps(track, true, 1, "ge")
		assert_gte(normal.size(), 10, track)
		assert_ne(JSON.stringify(normal), JSON.stringify(expert), track + ": the Expert try is different")
		assert_ne(RealBuilder.words(track, "twist"), "", track)


func test_an_automatic_player_finishes_every_track_by_itself() -> void:
	for track in LifeData.TRACKS:
		for expert: bool in [false, true]:
			for seed in 3:
				var run := LifeRun.new(RealBuilder.steps(track, expert, seed, "ge"), expert)
				var frames := 0
				while not run.finished and frames < 6000:
					run.feed(LifeAuto.sample(run.current(), run.state, 0.1))
					frames += 1
				assert_true(run.finished, "%s expert=%s stuck at %s" % [track, expert, run.current().get("id", "")])
				assert_eq(int(run.outcome().hints), 0, track)


func test_safety_first_on_every_track() -> void:
	for track in LifeData.TRACKS:
		var steps := RealBuilder.steps(track, false, 1, "ge")
		assert_eq(str(steps[1].kind), "find", track + ": the gear goes on before anything else")
		for g: String in ["hard_hat", "gloves"]:
			assert_has(steps[1].gear as Array, g, track)
		var worn: Array = []
		for s in steps:
			worn.append_array(s.get("gear", []))
			if s.has("safety"):
				assert_has(worn, str(s.safety), "%s %s: the gear is on before the tool" % [track, s.id])
			if str(s.get("tool", "")) == "saw":
				assert_eq(str(s.get("safety", "")), "goggles", track + ": goggles for the saw")


## Owner #118 (docs/design/life-skills.md §14): the natural safe mistakes of a building site are shaped for Life's coming
## "safe mistake" kind (the wrong way tried, time frozen, the coach's calm why, the right way): a saw without goggles,
## straight joints under the push test, no lintel. Only on Middle and Big: on Little the coach guides first.
func test_the_safe_mistakes_are_shaped_for_lifes_next_wave() -> void:
	var found := {}
	for track in LifeData.TRACKS:
		for expert: bool in [false, true]:
			for s in RealBuilder.steps(track, expert, 1, "ge"):
				if not s.has("safe_mistake"):
					continue
				assert_ne(track, "little", str(s.id))
				var m: Dictionary = s.safe_mistake
				for key: String in RealBuilder.SAFE_MISTAKE_KEYS:
					assert_ne(str(m.get(key, "")), "", "%s %s: %s" % [track, s.id, key])
				found["%s.%s" % [track, m.event]] = true
	for key: String in ["middle.sawdust", "big.sawdust", "middle.split", "middle.sag", "big.sag"]:
		assert_true(found.has(key), key)


func test_goggles_come_off_after_the_mixer_so_the_saw_asks_again() -> void:
	for track: String in ["middle", "big"]:
		var off := false
		for s in RealBuilder.steps(track, false, 1, "ge"):
			if str(s.get("after", "")) == "goggles_off":
				off = true
			if str(s.get("tool", "")) == "saw":
				assert_true(off, track + ": the goggles were taken off after the dusty mixing job")
				assert_eq(str(s.safety), "goggles")


func test_the_real_tools_are_used_the_real_way() -> void:
	var used := {}
	for track in LifeData.TRACKS:
		for s in RealBuilder.steps(track, false, 1, "ge"):
			if s.has("tool"):
				used["%s:%s" % [s.tool, s.motion]] = true
	for pair: String in ["trowel:spread", "trowel:strike", "spirit_level:aim", "plumb_line:aim", "tape:measure",
			"saw:stroke", "hammer:strike"]:
		assert_true(used.has(pair), pair)


func test_the_tracks_grow_little_wall_middle_shed_big_house() -> void:
	var little := JSON.stringify(RealBuilder.steps("little", false, 1, "ge"))
	var middle := JSON.stringify(RealBuilder.steps("middle", false, 1, "ge"))
	var big := JSON.stringify(RealBuilder.steps("big", false, 1, "ge"))
	assert_false(little.contains("lintel"), "a little wall has no openings")
	assert_true(middle.contains("lintel_door"), "the shed's door has its lintel")
	assert_true(middle.contains("tiles"), "and its roof")
	for t: String in ["lintel_door", "lintel_window", "square_diag", "tiles", "inside"]:
		assert_true(big.contains(t), "the house: " + t)


func test_the_numbers_are_the_brickworks_own() -> void:
	var wall := BrickBond.plan({"kind": "block", "shape": "wall", "length": 3, "courses": 3})
	var shed := BrickBond.plan({"kind": "brick", "shape": "box", "length": 8, "depth": 6, "courses": 1})
	var house := BrickBond.plan({"kind": "brick", "shape": "box", "length": 14, "depth": 10, "courses": 1})
	var lengths := {"little.mortar_1": wall.length, "middle.measure": shed.length, "big.measure": house.length,
		"middle.mortar_1": shed.length, "big.mortar_1": 2 * BrickBond.unit("brick").pitch - BrickBond.JOINT,
		"big.square": 1.0}
	for key: String in lengths:
		var parts := key.split(".")
		var found := false
		for s in RealBuilder.steps(parts[0], false, 1, "ge"):
			if str(s.id) == parts[1]:
				found = true
				assert_almost_eq(float((s.checks as Dictionary).length), float(lengths[key]), 0.001, key)
		assert_true(found, key)
	assert_almost_eq(BrickBond.unit("brick").pitch, 0.225, 0.0001, "the 22.5 cm the words say")


func test_the_mixer_is_the_tool_books_mixer() -> void:
	assert_eq(RealBuilder.devices().mixer, ToolBook.device("mixer"))


func test_the_words_are_kind_calm_and_british() -> void:
	var texts: Array[String] = []
	_texts(RealBuilder.data(), texts)
	for f: String in RealBuilder.UNIT_FILES.values():
		var json := JSON.new()
		json.parse(FileAccess.get_file_as_string(f))
		_texts(json.data, texts)
	var found: Array[String] = []
	for t in texts:
		var lower := t.to_lower()
		for w in UNKIND + US_SPELLINGS:
			if RegEx.create_from_string("\\b" + w + "\\b").search(lower):
				found.append("'%s' in: %s" % [w, t])
		for ch in t:
			if ch.unicode_at(0) > 127 and not ALLOWED.contains(ch):
				found.append("'%s' in: %s" % [ch, t])
				break
		if lower.contains("type your") or lower.contains("enter your"):
			found.append(t)
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_try_it_for_real_never_sends_a_child_onto_a_site() -> void:
	assert_string_contains(RealBuilder.words("little", "try_real"), "never go onto a building site")
	for track in LifeData.TRACKS:
		assert_string_contains(RealBuilder.words(track, "try_real"), "grown-up")


# --- The Life units (the School's format and bar) and the catalogue ------------------------------------------------

func test_the_life_units_meet_the_schools_bar() -> void:
	for track: String in RealBuilder.UNIT_FILES:
		var id: String = RealBuilder.UNIT_IDS[track]
		var c := Curriculum.parse_content(id, FileAccess.get_file_as_string(RealBuilder.UNIT_FILES[track]))
		assert_false(c.is_empty(), id)
		var cards: Array = c.lesson
		assert_between(cards.size(), 4, 8, id)
		assert_true(str(cards[0].text).begins_with("Quick memory:"), id)
		assert_true(str(cards.back().text).begins_with("Try it"), id)
		for card: Dictionary in cards:
			assert_lte(str(card.text).length(), 260, id)
		assert_gte(c.exercises.size(), 9, id)
		var levels := {}
		for ex: Dictionary in c.exercises:
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [id, ex.get("prompt")])
			assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)), "%s: %s" % [id, ex.get("prompt")])
			assert_ne(str(ex.get("hint", "")), "", id)
			levels[int(ex.level)] = true
		assert_eq(levels.size(), 3, id)
		assert_eq(RoundPlan.plan(c, 3, 0).size(), MasteryRules.ROUND_SIZE, id)


func test_the_units_files_are_reachable_from_lifes_folder() -> void:
	for track: String in RealBuilder.UNIT_FILES:
		var from_life := "res://data/life".path_join("../tools/units/real_builder_%s.json" % track)
		assert_true(FileAccess.file_exists(from_life), from_life + ": the lead's hook can name it from data/life")


func test_the_catalogue_has_one_entry_per_track_waiting_for_the_hook() -> void:
	for track: String in RealBuilder.UNIT_IDS:
		var u := LifeCatalog.unit(RealBuilder.UNIT_IDS[track])
		assert_false(u.is_empty(), track)
		assert_eq(str(u.track), track)
		assert_eq(str(u.area), "home")
		assert_true(LifeData.valid_unit_id(str(u.id)))
		if LifeExperience.IDS.has(RealBuilder.ID):
			assert_eq(str(u.get("experience", "")), RealBuilder.ID, "hooked: its TRY IT opens Real Builder")
		else:
			assert_eq(str(u.get("soon", "")), RealBuilder.ID, "until Life knows the id, it says coming soon")
	assert_eq(LifeCatalog.problems(), [] as Array[String])
