extends GutTest
## Owner #115 (docs/design/success-skills.md §2.7; the brief: "twenty short read-aloud stories of real people who built
## things (inventors, nurses, teachers, farmers, engineers, founders; many countries; started small, failed, tried
## again, helped others), every fact checked with its source; no living-people politics, no brands' marketing; 'Which
## skill did they use?' questions"): data/success/stories.json and its rules.

const UNKIND: Array[String] = ["die", "died", "dies", "dead", "death", "kill", "killed", "blood", "bleeding", "scream",
	"stupid", "dumb", "idiot", "lazy", "loser", "failure", "you failed", "streak", "hurry", "last chance"]
const US_SPELLINGS: Array[String] = ["color", "colors", "center", "centers", "meter", "meters", "favorite", "gray",
	"neighbor", "neighbors", "math", "behavior", "honor", "organize", "organized", "realize", "practicing", "practiced",
	"airplane", "airplanes", "program", "traveled", "theater", "labor", "mold"]
const BRANDS: Array[String] = ["shell", "ibm", "coca", "pepsi", "google", "apple inc", "microsoft", "nike", "toyota",
	"sony", "panasonic", "tata", "amazon", "facebook", "red cross emblem"]


func test_twenty_stories() -> void:
	assert_eq(SuccessStories.list().size(), 20)
	assert_eq(SuccessStories.problems(), [] as Array[String])


func test_each_story_is_short_read_aloud_and_kind() -> void:
	for s in SuccessStories.list():
		var lines: Array = s.lines
		assert_between(lines.size(), 5, 7, str(s.id))
		for line: Variant in lines:
			assert_lte(str(line).length(), SuccessStories.MAX_LINE, "%s: %s" % [s.id, line])
		for t in SuccessStories.texts(s):
			var lower := t.to_lower()
			for w in UNKIND + US_SPELLINGS:
				assert_null(RegEx.create_from_string("\\b" + w + "\\b").search(lower), "'%s' in %s: %s" % [w, s.id, t])
			for b in BRANDS:
				assert_false(lower.contains(b), "%s in %s" % [b, s.id])
			for ch in t:
				assert_lte(ch.unicode_at(0), 127, "%s: plain letters for the voice: %s" % [s.id, t])


func test_every_fact_has_its_source() -> void:
	for s in SuccessStories.list():
		var sources: Array = s.get("sources", [])
		assert_gte(sources.size(), 2, str(s.id))
		for src: Variant in sources:
			assert_true(str((src as Dictionary).get("url", "")).begins_with("https://"), "%s: %s" % [s.id, src])
			assert_ne(str((src as Dictionary).get("fact", "")), "", str(s.id))


func test_real_people_of_the_past_from_many_countries_and_jobs() -> void:
	var countries := {}
	var jobs := ""
	var women := 0
	for s in SuccessStories.list():
		countries[str(s.country)] = true
		jobs += " " + str(s.job).to_lower()
		women += 1 if str(s.get("she", "")) == "yes" else 0
		assert_true(RegEx.create_from_string("\\d{4}$").search(str(s.life)) != null,
			"%s: a person of the past (no living people's politics): %s" % [s.id, s.life])
	assert_gte(countries.size(), 14, "many countries")
	assert_gte(women, 7, "women and men")
	for job: String in ["nurse", "teacher", "farm", "engineer", "inventor", "founder", "doctor", "scientist"]:
		assert_string_contains(jobs, job)


func test_which_skill_did_they_use() -> void:
	for s in SuccessStories.list():
		var q := SuccessStories.question(s)
		assert_eq(LifeCheck.problem(q), "", str(s.id))
		assert_eq((q.choices as Array).size(), 3, str(s.id))
		assert_string_contains(str(q.say).to_lower(), "which skill", str(s.id))
		for c: Dictionary in q.choices:
			assert_true(LifeIcons.has(str(c.get("icon", ""))), "%s: %s" % [s.id, c])
		for i in (q.choices as Array).size():
			if i != int(q.answer):
				assert_ne(str(q.choices[i].get("why", "")), "", "%s: kind words for every other answer" % s.id)
		assert_has(SuccessStories.SKILLS, str(s.skill), str(s.id))


func test_reading_and_answering_is_kept() -> void:
	var d := SuccessData.new()
	SuccessStories.read(d, "braille", 20_000, false)
	assert_true(d.story_read("braille"))
	SuccessStories.read(d, "braille", 20_002, true)
	assert_eq(int(d.story("braille").r), 20_000)
	assert_true(bool(d.story("braille").a))
	SuccessStories.read(d, "not_a_story", 20_000, true)
	assert_false(d.stories.has("not_a_story"))
	assert_eq(SuccessStories.read_count(d), 1)
	assert_string_contains(SuccessStories.grown_ups_line(d), "1 of 20")
