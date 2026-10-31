extends GutTest
## Owner #112, #115 (docs/design/life-skills.md §2, §7; docs/design/success-skills.md): the Life tab's map
## (data/life/life.json): the ten areas in Life's two strands (Living well; Success: money and business, thinking and the
## future), each with units on the Little, Middle and Big tracks. A unit is Life's own (data/life/units/, the School's
## lesson format, its "Try it" starts its Experience), or one of the School's real lessons where it fits (Health,
## Citizenship, Computing, D&T: one unit, one reward), or "coming soon" only when it needs an Experience not built yet.

const UNKIND: Array[String] = ["miss you", "don't go", "lonely", "last chance", "hurry", "only today", "you failed",
	"failure", "loser", "for babies", "noob", "streak", "wrong!", "stupid", "dumb", "idiot", "lazy", "you lose", "blood",
	"die", "dead", "death", "scream", "kill"]
const US_SPELLINGS: Array[String] = ["color", "colors", "center", "meter", "meters", "favorite", "gray", "neighbor",
	"math", "behavior", "honor", "organize", "realize", "practicing", "practiced"]


func test_the_catalog_has_no_problems() -> void:
	assert_eq(LifeCatalog.problems(), [] as Array[String])


func test_the_ten_areas_in_two_strands() -> void:
	var areas := LifeCatalog.areas()
	assert_eq(areas.size(), 14, "the ten, and Success S2's four (owner #115: goals, talk, connections, stories)")
	for a in areas:
		assert_true(LifeIcons.has(str(a.icon)), str(a.id))
		assert_has(LifeCatalog.STRANDS, str(a.strand))
	assert_eq(str(LifeCatalog.area("money").strand), "success")
	assert_eq(str(LifeCatalog.area("thinking").strand), "success")
	assert_eq(str(LifeCatalog.area("safe").strand), "living")


func test_every_area_has_units_on_every_track() -> void:
	for a in LifeCatalog.areas():
		for track in LifeData.TRACKS:
			assert_gt(LifeCatalog.units(str(a.id), track).size(), 0, "%s %s" % [a.id, track])


func test_every_experience_track_has_its_own_unit() -> void:
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			var found := 0
			for u in LifeCatalog.all_units():
				if str(u.get("experience", "")) == id and str(u.track) == track:
					found += 1
					assert_true(LifeData.valid_unit_id(str(u.id)), str(u.id))
					assert_false(LifeCatalog.content(str(u.id)).is_empty(), str(u.id) + " is written")
			assert_eq(found, 1, "%s %s" % [id, track])


func test_the_schools_lessons_are_real_and_written() -> void:
	var school := 0
	for u in LifeCatalog.all_units():
		if LifeCatalog.is_school(str(u.id)):
			school += 1
			assert_false(Curriculum.unit(str(u.id)).is_empty(), str(u.id))
			assert_true(Curriculum.has_content(str(u.id)), str(u.id))
			assert_ne(LifeCatalog.title(str(u.id)), "")
	assert_gt(school, 20, "prefer the School's real lessons where they fit")


func test_coming_soon_only_for_experiences_not_built_yet() -> void:
	var waiting_for_built := 0
	for u in LifeCatalog.all_units():
		if u.has("soon"):
			assert_false(u.has("file"))
			if LifeExperience.IDS.has(str(u.soon)):
				waiting_for_built += 1
	assert_eq(waiting_for_built, 0, "an Experience that is built has its real units (Life L2 built all three)")


func test_lifes_own_units_meet_the_schools_bar() -> void:
	for u in LifeCatalog.all_units():
		var id := str(u.id)
		if not LifeData.valid_unit_id(id) or u.has("soon"):
			continue
		var c := LifeCatalog.content(id)
		var cards: Array = c.lesson
		assert_between(cards.size(), 4, 8, id)
		assert_true(str(cards[0].text).begins_with("Quick memory:"), id + ": a memory question first")
		assert_true(str(cards.back().text).begins_with("Try it"), id + ": what to try last")
		for card: Dictionary in cards:
			assert_lte(str(card.text).length(), 260, id)
		assert_gte(c.exercises.size(), 9, id)
		var levels := {}
		for ex: Dictionary in c.exercises:
			assert_eq(ExerciseCheck.problem(ex), "", "%s: %s" % [id, ex.get("prompt")])
			assert_true(ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)), "%s: %s" % [id, ex.get("prompt")])
			assert_ne(str(ex.get("hint", "")), "", id)
			levels[int(ex.level)] = true
		assert_eq(levels.size(), 3, id + ": levels 1-3")
		assert_eq(RoundPlan.plan(c, 3, 0).size(), MasteryRules.ROUND_SIZE, id + ": a round of 6")


func test_unit_titles_fit_their_cards() -> void:
	for u in LifeCatalog.all_units():
		assert_lte(LifeCatalog.title(str(u.id)).length(), 40, str(u.id))


func test_the_words_are_kind_and_british() -> void:
	var found: Array[String] = []
	for u in LifeCatalog.all_units():
		if not LifeData.valid_unit_id(str(u.id)) or u.has("soon"):
			continue
		var c := LifeCatalog.content(str(u.id))
		var texts: Array[String] = []
		for card: Dictionary in c.lesson:
			texts.append(str(card.text))
		for ex: Dictionary in c.exercises:
			texts.append_array([str(ex.get("prompt", "")), str(ex.get("hint", "")), str(ex.get("explain", ""))])
			for ch: Variant in ex.get("choices", []) + ex.get("items", []):
				texts.append(ExerciseCheck.item_text(ch))
		for t in texts:
			var lower := t.to_lower()
			for w in UNKIND + US_SPELLINGS:
				if RegEx.create_from_string("\\b" + w + "\\b").search(lower):
					found.append("'%s' in %s: %s" % [w, u.id, t])
	assert_eq(found, [] as Array[String], "\n".join(found))


func test_a_units_track_words() -> void:
	assert_eq(LifeCatalog.track_words("little"), "LITTLE")
	assert_eq(LifeCatalog.track_ages("big"), "12 and up")
