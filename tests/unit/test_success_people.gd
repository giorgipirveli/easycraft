extends GutTest
## Owner #115 (docs/design/success-skills.md §2.3, [S5]; the brief: "the worlds' people with names, jobs, wishes and
## needs (the baker needs flour, the farmer needs tools, the engineer needs a buyer); meet them, remember them in the
## book, help first, keep promises, introduce two people who can help each other; their warmth grows (never a public
## score); new chances open; mentors teach a skill when asked politely; people different from you"): the Connections
## Book's rules. The people are data (data/success/people.json); what a child did in a practice room is each step's
## "book" (meet, help, promise, intro, mentor), recorded after a finished try.

const DAY := 20_000

var d: SuccessData


func before_each() -> void:
	d = SuccessData.new()


func test_the_people_have_names_jobs_wishes_needs_and_offers() -> void:
	var list := SuccessPeople.list()
	assert_gte(list.size(), 12)
	var ids := {}
	for p in list:
		assert_true(SuccessData.valid_id(p.get("id")), str(p))
		assert_false(ids.has(p.id), "%s twice" % p.id)
		ids[p.id] = true
		for key: String in ["name", "job", "place", "wish", "needs", "offers", "colour", "look"]:
			assert_ne(str(p.get(key, "")), "", "%s: %s" % [p.id, key])
	for job: String in ["the baker", "the farmer", "the engineer"]:
		assert_true(list.any(func(p: Dictionary) -> bool: return str(p.job) == job), job)


func test_the_baker_needs_flour_the_farmer_tools_the_engineer_a_buyer() -> void:
	assert_string_contains(str(SuccessPeople.person("amara").needs), "flour")
	assert_string_contains(str(SuccessPeople.person("ana").needs), "spade")
	assert_string_contains(str(SuccessPeople.person("mei").needs), "buyer")


func test_every_need_has_someone_who_can_help() -> void:
	for p in SuccessPeople.list():
		var helper := str(p.get("helped_by", ""))
		assert_false(SuccessPeople.person(helper).is_empty(), "%s: who helps with %s" % [p.id, p.needs])
		assert_ne(helper, str(p.id))


func test_some_people_are_different_from_you() -> void:
	var different := SuccessPeople.list().filter(func(p: Dictionary) -> bool: return str(p.get("different", "")) != "")
	assert_gte(different.size(), 4, "older people, people from far away, people who use a wheelchair or sign")


func test_mentors_have_a_tip() -> void:
	var mentors := SuccessPeople.list().filter(func(p: Dictionary) -> bool: return str(p.get("tip", "")) != "")
	assert_gte(mentors.size(), 4)


func test_meeting_puts_a_person_in_the_book() -> void:
	assert_false(d.met("amara"))
	SuccessPeople.record(d, [{"meet": ["amara", "tomas"]}], DAY)
	assert_true(d.met("amara"))
	assert_eq(int(d.person("amara").m), DAY)
	assert_eq(int(d.person("amara").w), 1)
	assert_eq(SuccessPeople.met_count(d), 2)
	SuccessPeople.record(d, [{"meet": ["amara"]}], DAY + 3)
	assert_eq(int(d.person("amara").m), DAY, "the first meeting stays")
	SuccessPeople.record(d, [{"meet": ["nobody_here"]}], DAY)
	assert_false(d.people.has("nobody_here"), "only the book's people")


func test_helping_promises_introductions_and_mentors_warm_people() -> void:
	SuccessPeople.record(d, [{"meet": ["amara", "tomas", "omar"]}, {"help": "amara"}, {"promise": "amara"},
		{"intro": ["amara", "tomas"]}, {"mentor": "omar"}], DAY)
	var amara := d.person("amara")
	assert_eq(int(amara.h), 1)
	assert_eq(int(amara.p), 1)
	assert_eq(int(amara.i), 1)
	assert_eq(int(d.person("tomas").i), 1)
	assert_true(bool(d.person("omar").t), "Omar's tip is in the book")
	assert_gt(int(amara.w), int(d.person("tomas").w), "help and a kept promise warm more than a hello")


func test_warmth_grows_over_several_tries_never_all_at_once() -> void:
	var lots: Array[Dictionary] = [{"meet": ["amara"]}, {"help": "amara"}, {"promise": "amara"}, {"help": "amara"},
		{"intro": ["amara", "tomas"]}]
	SuccessPeople.record(d, lots, DAY)
	assert_lte(int(d.person("amara").w), 1 + SuccessPeople.WARMTH_PER_TRY)
	for i in 5:
		SuccessPeople.record(d, lots, DAY + i + 1)
	assert_eq(int(d.person("amara").w), SuccessData.MAX_WARMTH)


func test_warmth_shows_as_words_never_a_number() -> void:
	for w in SuccessData.MAX_WARMTH + 1:
		var words := SuccessPeople.warmth_words("amara", w)
		for digit in "0123456789":
			assert_false(words.contains(digit), words)
		if w > 0:
			assert_string_contains(words, "Amara")


func test_a_warm_connection_opens_a_new_chance() -> void:
	SuccessPeople.record(d, [{"meet": ["amara"]}], DAY)
	assert_eq(SuccessPeople.chances(d).size(), 0)
	for i in 3:
		SuccessPeople.record(d, [{"help": "amara"}, {"promise": "amara"}], DAY + i)
	var chances := SuccessPeople.chances(d)
	assert_eq(chances.size(), 1)
	assert_string_contains(chances[0], str(SuccessPeople.person("amara").chance))


func test_the_book_steps_of_a_try_are_read_from_its_log() -> void:
	var steps: Array[Dictionary] = [{"id": "hello", "kind": "info", "say": "Hi"},
		{"id": "meet", "kind": "touch", "target": "amara", "say": "Say hello", "book": {"meet": ["amara"]}},
		{"id": "flour", "kind": "touch", "target": "amara", "say": "Help", "book": {"help": "amara"}}]
	var log: Array = [{"id": "hello"}, {"id": "meet"}]
	var acts := SuccessPeople.actions_from(steps, log)
	assert_eq(acts, [{"meet": ["amara"]}] as Array[Dictionary], "only the steps the child did")


func test_the_grown_ups_line_counts_what_happened() -> void:
	assert_eq(SuccessPeople.grown_ups_line(d), "")
	SuccessPeople.record(d, [{"meet": ["amara", "tomas", "lina"]}, {"help": "amara"}, {"promise": "lina"},
		{"intro": ["amara", "tomas"]}], DAY)
	var line := SuccessPeople.grown_ups_line(d)
	assert_string_contains(line, "met 3 people")
	assert_string_contains(line, "helped 1 time")
	assert_string_contains(line, "kept 1 promise")
	assert_string_contains(line, "1 introduction")
