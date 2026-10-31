extends GutTest
## Owner #118 (docs/design/life-skills.md §14; Life L3b): the dangers wave's second part as data: Electricity Safety (the
## catalogue's row 7), Safe with Animals (row 8) and Medical Emergencies (row 10), and what L1 left of fire and heat
## (row 3) and of choking (row 6) in The Kitchen and Fire Escape. Each on the Little, Middle and Big track (Electricity's
## Little: the hazard hunt only; Medical's Little: tell a grown-up and call); prevention first; the authorities' own
## steps with their sources; the brief's safe mistakes on Middle and Big only; "not for a child to do" said plainly;
## never a bite or an injury shown; the region's number and Georgia's mountains; the Tool Book's new entries.

const L3B: Array[String] = ["electricity", "animals", "medical"]


func _steps(id: String, track: String, expert: bool = false, region: String = "ge") -> Array[Dictionary]:
	return LifeExperience.steps(id, track, expert, 1, region)


func _step(id: String, track: String, step_id: String, expert: bool = false) -> Dictionary:
	for s in _steps(id, track, expert):
		if str(s.id) == step_id:
			return s
	return {}


func _words(id: String, track: String, expert: bool = false, region: String = "ge") -> String:
	var out: Array[String] = []
	for s in _steps(id, track, expert, region):
		out.append(str(s.get("say", "")))
		out.append(str(s.get("done", "")))
		for c: Variant in s.get("choices", []):
			out.append(str((c as Dictionary).get("text", "")))
			out.append(str((c as Dictionary).get("why", "")))
		var m: Variant = s.get("safe_mistake")
		if m is Dictionary:
			out.append(str((m as Dictionary).get("why", "")))
			out.append(str((m as Dictionary).get("right", "")))
		var lines: Variant = s.get("lines")
		if lines is Dictionary:
			for k: Variant in lines:
				out.append(str(lines[k]))
		var nots: Variant = s.get("not")
		if nots is Dictionary:
			for k: Variant in nots:
				out.append(str(nots[k]))
	var card := LifeExperience.card(id, track, region)
	out.append_array(card.get("lines", []))
	return " ".join(out)


func _mistakes(id: String, track: String) -> Dictionary:
	var out := {}
	for expert: bool in [false, true]:
		for s in _steps(id, track, expert):
			if s.get("safe_mistake") is Dictionary:
				out[str(s.safe_mistake.event)] = s
	return out


func test_the_three_are_known_emergencies_with_no_problems() -> void:
	for id in L3B:
		assert_has(LifeExperience.IDS, id)
		assert_eq(LifeExperience.problems(id), [] as Array[String], id)
		assert_true(LifeExperience.emergency(id), id + ": the calm debrief after it")
	assert_eq(str(LifeExperience.data("electricity").area), "safe")
	assert_eq(str(LifeExperience.data("medical").area), "safe")
	assert_eq(str(LifeExperience.data("animals").area), "world", "Our world: care for animals (a ruling)")


func test_the_brief_s_safe_mistakes_are_there_on_middle_and_big_only() -> void:
	assert_true(_mistakes("electricity", "big").has("current_through"), "grabbing someone stuck to a current")
	assert_eq(str(_mistakes("electricity", "big").current_through.safe_mistake.try), "gus_stuck")
	assert_true(_mistakes("electricity", "big").has("ground_live"), "going closer to a fallen line")
	assert_true(_mistakes("electricity", "middle").has("wet_spark"), "wet hands on the hair dryer")
	assert_true(_mistakes("animals", "middle").has("dog_chase"), "running from the dog")
	assert_true(_mistakes("animals", "middle").has("dog_uneasy"), "hugging a dog you don't know")
	assert_true(_mistakes("animals", "big").has("dog_chase"), "running from the guard dog")
	assert_true(_mistakes("medical", "middle").has("throat"), "tipping the head back for a nosebleed")
	assert_true(_mistakes("medical", "big").has("spoon_mouth"), "something in the mouth during a seizure")
	assert_true(_mistakes("kitchen", "middle").has("flare"), "water on a pan fire")
	assert_true(_mistakes("safe_streets", "middle").has("step_out_van"), "the unsafe crossing (L3a's hook)")
	assert_eq(str(_mistakes("safe_streets", "middle").step_out_van.safe_mistake.try), LifeCheck.UNSAFE)
	for id: String in L3B + ["kitchen", "safe_streets", "fire_escape"]:
		for expert: bool in [false, true]:
			for s in _steps(id, "little", expert):
				assert_false(s.has("safe_mistake"), "%s little %s: the coach guides first" % [id, s.id])
		for track: String in ["middle", "big"]:
			for event: String in _mistakes(id, track):
				var s: Dictionary = _mistakes(id, track)[event]
				assert_true(LifeCheck.tries_mistake(s), "%s.%s %s: the child can try it" % [id, track, event])
				assert_true(LifeIcons.has(str(s.safe_mistake.get("icon", ""))), "%s.%s %s: the why card's picture %s" % [id,
					track, event, s.safe_mistake.get("icon")])


func test_real_builders_saw_is_a_true_safe_mistake() -> void:
	for track: String in ["middle", "big"]:
		for s in RealBuilder.steps(track, false, 1, "ge"):
			if str(s.get("tool", "")) == "saw":
				assert_true(LifeCheck.tries_mistake(s), track + ": the saw without goggles can be tried")
				assert_eq(str(s.safe_mistake.try), LifeCheck.UNSAFE, "the saw itself, before the goggles")
				assert_true(LifeIcons.has(str(s.safe_mistake.icon)), track)
	assert_eq(RealBuilder.problems(), [] as Array[String])


func test_little_guides_first() -> void:
	var said := false
	for s in _steps("animals", "little"):
		if str(s.kind) == "action":
			break
		said = said or str(s.say).to_lower().contains("be a tree") and str(s.say).to_lower().contains("never run")
	assert_true(said, "Little hears 'be a tree... never run' before the dog comes")
	for s in _steps("electricity", "little"):
		assert_ne(str(s.kind), "action", "Electricity's Little track is the hazard hunt only")
	assert_eq(str(_step("electricity", "little", "hunt").kind), "find", "the hazard hunt")
	var dialled := false
	for s in _steps("medical", "little"):
		dialled = dialled or str(s.kind) == "sequence"
	assert_true(dialled, "Medical's Little: tell a grown-up and call for help on the play phone")


func test_the_right_ways_in_the_authorities_words() -> void:
	var e_mid := _words("electricity", "middle").to_lower()
	for w: String in ["dry", "plug", "adaptor", "power lines", "substation", "kite"]:
		assert_string_contains(e_mid, w, "electricity (Middle): " + w)
	var e_big := _words("electricity", "big").to_lower()
	for w: String in ["fuse box", "rcd", "never touch", "10 metres", "keep others away"]:
		assert_string_contains(e_big, w, "electricity (Big): " + w)
	var a_mid := _words("animals", "middle").to_lower()
	for w: String in ["stiff", "stare", "lips", "tail", "ask the owner", "back of your hand", "be a tree", "behind a horse",
			"calves", "swat", "snake"]:
		assert_string_contains(a_mid, w, "animals (Middle): " + w)
	var a_big := _words("animals", "big").to_lower()
	for w: String in ["stay with", "noise", "never feed", "flock", "sting"]:
		assert_string_contains(a_big, w, "animals (Big): " + w)
	var m_mid := _words("medical", "middle").to_lower()
	for w: String in ["lean forward", "pinch the soft part", "10 minutes", "spacer", "shake", "press", "shade", "water"]:
		assert_string_contains(m_mid, w, "medical (Middle): " + w)
	var m_big := _words("medical", "big").to_lower()
	for w: String in ["blue to the sky", "orange to the thigh", "trainer", "time it", "hard things", "soft under",
			"never hold", "nothing in the mouth", "recovery position", "5 minutes"]:
		assert_string_contains(m_big, w, "medical (Big): " + w)


func test_not_for_a_child_and_the_own_pen_are_said_plainly() -> void:
	assert_string_contains(_words("electricity", "big").to_lower(), "not for a child to do")
	var pen := str(_step("medical", "big", "pen_info").say).to_lower()
	assert_string_contains(pen, "only ever the person's own")
	assert_string_contains(pen, "no needle")
	for id in L3B:
		for track in LifeData.TRACKS:
			var w := _words(id, track).to_lower()
			for never: String in ["bite you", "bit him", "bit her", "blood", "dose of", "mg"]:
				assert_false(RegEx.create_from_string("\\b" + never + "\\b").search(w) != null, "%s.%s: '%s'" % [id, track, never])


func test_danger_moments_slow_down() -> void:
	for pair: Array in [["animals", "little"], ["animals", "middle"], ["animals", "big"], ["electricity", "big"],
			["kitchen", "middle"]]:
		var danger := 0
		for s in _steps(str(pair[0]), str(pair[1])):
			if bool(s.get("danger", false)):
				danger += 1
		assert_gt(danger, 0, "%s.%s has a danger moment" % pair)


func test_the_regions_number_and_georgias_mountains() -> void:
	for id in L3B:
		var said := false
		for track in LifeData.TRACKS:
			said = said or _words(id, track, false, "uk").contains("999")
		assert_true(said, id + " says the region's number")
	assert_string_contains(str(_step("animals", "big", "hello").say), "Georgia")
	assert_false(str(_steps("animals", "big", false, "uk")[0].say).contains("Georgia"), "another region, its own words")


func test_fire_and_heat_in_the_kitchen_and_fire_escape() -> void:
	var lid := _step("kitchen", "middle", "lid")
	assert_eq(str(lid.safe_mistake.try), "water_jug", "the safe mistake: water on the pan")
	assert_true(bool(lid.danger), "frozen before the flare")
	assert_string_contains(str(lid.safe_mistake.why).to_lower(), "lid")
	var k_mid := _words("kitchen", "middle").to_lower()
	for w: String in ["heat off", "lid", "leave it covered", "get out"]:
		assert_string_contains(k_mid, w, "pan fire: " + w)
	var k_big := _words("kitchen", "big").to_lower()
	for w: String in ["cool running water", "20 minutes", "cling film"]:
		assert_string_contains(k_big, w, "scalds: " + w)
	var k_little := _words("kitchen", "little").to_lower()
	for w: String in ["small things", "baby", "hot tap"]:
		assert_string_contains(k_little, w, "choking and hot water (Little): " + w)
	var f_little := _words("fire_escape", "little").to_lower()
	assert_string_contains(f_little, "matches", "candles and matches: a grown-up's job")
	assert_string_contains(f_little, "grown-up's job")
	var f_mid := _words("fire_escape", "middle").to_lower()
	for w: String in ["ring", "small", "drown", "stir", "back of your hand"]:
		assert_string_contains(f_mid, w, "the campfire: " + w)


func test_the_devices_and_the_tool_book() -> void:
	assert_true(LifeExperience.devices("electricity", "ge").has("fuse_box"))
	assert_true(LifeExperience.devices("electricity", "ge").has("rcd"))
	assert_true(LifeExperience.devices("medical", "ge").has("auto_injector"))
	assert_true(LifeExperience.devices("medical", "ge").has("inhaler"))
	for tool_id: String in ["fuse_box", "rcd", "plug", "auto_injector", "inhaler", "pan_lid", "calendar", "jar"]:
		assert_true(ToolBook.has(tool_id), tool_id + " in the Tool Book")
	assert_true(bool(ToolBook.entry("fuse_box").get("grown_up", false)), "the fuse box is a grown-up's job")
	assert_eq(str(_step("electricity", "big", "rcd").device), "rcd")
	assert_eq(str(_step("electricity", "middle", "unplug").tool), "plug")
	assert_eq(str(_step("medical", "big", "thigh").tool), "auto_injector")
	assert_eq(str(_step("medical", "middle", "press").tool), "inhaler")
	assert_eq(str(_step("kitchen", "middle", "lid").tool), "pan_lid")


func test_every_new_unit_is_on_the_map() -> void:
	for id in L3B:
		for track in LifeData.TRACKS:
			assert_ne(LifeCatalog.experience_unit(id, track), "", "%s.%s has its unit" % [id, track])
