extends GutTest
## Owner #117 (docs/design/life-skills.md §13, "The Tool Book"; the catalogue by area): every tool and device a child
## can learn, as data (data/tools/tools.json): its name, what it is for, how to hold it, its motion, its safety rule, its
## area. "The right tool for the job" is noticed kindly.


func test_the_catalogue_has_no_problems() -> void:
	assert_eq(ToolBook.problems(), [] as Array[String])


func test_every_area_of_the_design_has_tools() -> void:
	assert_eq(ToolBook.AREAS, ["building", "fixing", "kitchen", "home", "garden", "health", "money", "tech", "science",
		"around", "art"] as Array[String])
	for area in ToolBook.AREAS:
		assert_gt(ToolBook.of_area(area).size(), 0, area)
		assert_ne(ToolBook.area_title(area), "", area)


func test_every_entry_says_what_it_is_for_how_to_hold_it_and_its_safety_rule() -> void:
	for id in ToolBook.ids():
		var e := ToolBook.entry(id)
		for key: String in ["name", "for", "hold", "safety", "area", "kind"]:
			assert_ne(str(e.get(key, "")).strip_edges(), "", "%s: %s" % [id, key])
		assert_has(ToolBook.KINDS, str(e.kind), id)


func test_every_tool_has_motions_from_the_ten() -> void:
	for id in ToolBook.ids():
		if str(ToolBook.entry(id).kind) == "safety":
			assert_eq(ToolBook.motions(id), [] as Array[String], id + ": safety gear is put on, not used")
			continue
		assert_gt(ToolBook.motions(id).size(), 0, id)
		for m in ToolBook.motions(id):
			assert_has(ToolMotion.ALL, m, id)


func test_every_motion_has_a_tool_that_teaches_it() -> void:
	var seen := {}
	for id in ToolBook.ids():
		for m in ToolBook.motions(id):
			seen[m] = true
	for m in ToolMotion.ALL:
		assert_true(seen.has(m), m)


func test_devices_run_as_devices() -> void:
	var n := 0
	for id in ToolBook.ids():
		if str(ToolBook.entry(id).kind) == "device":
			n += 1
			assert_eq(ToolDevice.problems(ToolBook.device(id)), [] as Array[String], id)
	assert_gte(n, 5)


func test_real_builders_tools_are_in_the_book() -> void:
	for id: String in ["trowel", "spirit_level", "plumb_line", "tape", "hammer", "saw", "gloves", "goggles", "hard_hat",
			"mixer", "shovel", "bucket"]:
		assert_true(ToolBook.has(id), id)
	assert_eq(ToolBook.entry("trowel").area, "building")
	assert_eq(ToolBook.motions("trowel"), ["spread", "strike"] as Array[String], "spread mortar, tap a brick down")


func test_life_l1s_tools_and_devices_are_in_the_book() -> void:
	for exp_id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			for step in LifeExperience.steps(exp_id, track, false, 1, "ge") + LifeExperience.steps(exp_id, track, true, 1, "ge"):
				for key: String in ["tool", "device"]:
					if step.has(key):
						assert_true(ToolBook.has(str(step[key])), "%s.%s %s: %s" % [exp_id, track, step.id, step[key]])


func test_a_tools_own_numbers_for_a_motion() -> void:
	var c := ToolBook.checks("trowel", "strike")
	assert_lt(float(c.get("min_speed", 99.0)), float(ToolMotion.CHECKS.strike.min_speed), "a trowel's handle taps gently")
	assert_eq(ToolBook.checks("trowel", "cut"), {}, "nothing for a motion it is not used with")


func test_the_right_tool_for_the_job_is_noticed_kindly() -> void:
	assert_eq(ToolBook.right_tool("hammer", "hammer"), "")
	var words := ToolBook.right_tool("hammer", "screwdriver")
	assert_string_contains(words, "hammer")
	assert_string_contains(words, "screwdriver")
	assert_string_starts_with(words, "That works better with")
	assert_eq(ToolBook.right_tool("hammer", ""), ToolBook.PICK_UP % ToolBook.name_of("hammer"), "nothing in the hand: pick it up")


func test_the_words_are_kind_short_and_british() -> void:
	var us := ["color", "center", "meter", "favorite", "gray", "aluminum", "organize"]
	for id in ToolBook.ids():
		var e := ToolBook.entry(id)
		for key: String in ["name", "for", "hold", "safety"]:
			var t := str(e[key])
			assert_lte(t.length(), 120, "%s %s" % [id, key])
			for w: String in us:
				assert_false(RegEx.create_from_string("\\b" + w + "\\b").search(t.to_lower()) != null, "%s: %s" % [id, w])


func test_grown_ups_jobs_say_so() -> void:
	for id: String in ["mixer", "extinguisher"]:
		assert_true(bool(ToolBook.entry(id).get("grown_up", false)), id + " is a grown-up's job in real life")
