extends GutTest
## Owner #118 (docs/design/life-skills.md §14; Life L3a): the dangerous-skills wave's first three Experiences as data:
## Water Safety (the catalogue's row 2), The Poisons Cupboard (row 5) and Earth and Weather (row 9). Each on the Little,
## Middle and Big track; prevention first, then what to do; the authorities' own steps with their sources; the safe
## mistakes the brief names (swimming straight back against a rip, standing up on thin ice, jumping in after someone, two
## cleaners poured together, running outside during the shaking) on the Middle and Big tracks only (on Little the coach
## guides first); danger moments where time slows on the first tries; "not for a child to do" said plainly; the region's
## number and, for earthquakes, the region's own words (Georgia's mountains).

const L3A: Array[String] = ["water_safety", "poisons_cupboard", "earth_weather"]


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
		var m: Variant = s.get("safe_mistake")
		if m is Dictionary:
			out.append(str((m as Dictionary).get("why", "")))
			out.append(str((m as Dictionary).get("right", "")))
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


func test_the_three_experiences_are_known_and_emergencies() -> void:
	for id in L3A:
		assert_has(LifeExperience.IDS, id)
		assert_eq(LifeExperience.problems(id), [] as Array[String], id)
		assert_true(LifeExperience.emergency(id), id + ": the debrief after it")
		assert_eq(str(LifeExperience.data(id).area), "safe", id + ": Staying safe")
	assert_true(LifeExperience.emergency("little_lifesaver"))
	assert_true(LifeExperience.emergency("fire_escape"))
	assert_false(LifeExperience.emergency("money_stall"))
	assert_false(LifeExperience.emergency("kitchen"))


func test_little_never_shows_a_mistake_the_coach_guides_first() -> void:
	for id in LifeExperience.IDS:
		for expert: bool in [false, true]:
			for s in LifeExperience.steps(id, "little", expert, 1, "ge"):
				assert_false(s.has("safe_mistake"), "%s little %s" % [id, s.id])
	var guided := false
	for s in _steps("water_safety", "little"):
		if str(s.kind) == "point":
			break
		guided = guided or str(s.say).to_lower().contains("never jump in")
	assert_true(guided, "Little hears 'never jump in' before the float is thrown")
	var told := false
	for s in _steps("earth_weather", "little"):
		if str(s.id) == "drop":
			break
		told = told or str(s.say).to_lower().contains("never run outside")
	assert_true(told, "Little hears 'never run outside while it shakes' before the shaking")


func test_the_brief_s_safe_mistakes_are_there_on_middle_and_big() -> void:
	var water_m := _mistakes("water_safety", "middle")
	assert_true(water_m.has("rip_tired"), "swimming straight back against a rip current")
	assert_true(water_m.has("two_in_water"), "jumping in after someone")
	var water_b := _mistakes("water_safety", "big")
	assert_true(water_b.has("ice_cracks"), "standing up on the ice")
	assert_eq(str(water_b.ice_cracks.safe_mistake.try), "action:stand")
	assert_true(water_b.has("ice_cracks_helper"), "walking onto the ice to help")
	for track: String in ["middle", "big"]:
		assert_true(_mistakes("poisons_cupboard", track).has("fumes"), track + ": two cleaners poured together")
		assert_true(_mistakes("earth_weather", track).has("falling_tiles"), track + ": running outside during the shaking")
	for id in L3A:
		for track: String in ["middle", "big"]:
			for event: String in _mistakes(id, track):
				assert_true(LifeCheck.tries_mistake(_mistakes(id, track)[event]), "%s.%s %s: the child can try it" % [id,
					track, event])
				var m: Dictionary = _mistakes(id, track)[event].safe_mistake
				assert_true(LifeIcons.has(str(m.get("icon", ""))), "%s.%s %s: the why card's picture %s" % [id, track, event,
					m.get("icon")])


func test_the_right_ways_in_the_authorities_words() -> void:
	var rip := _step("water_safety", "middle", "rip")
	assert_eq(str(rip.target), "swim_along", "swim along the beach, out of the rip")
	assert_string_contains(str(rip.safe_mistake.right).to_lower(), "along the beach")
	var water_big := _words("water_safety", "big").to_lower()
	for w: String in ["arms out", "kick", "roll", "crawl", "stay off"]:
		assert_string_contains(water_big, w, "thin ice: " + w)
	assert_string_contains(_words("water_safety", "middle").to_lower(), "quiet", "drowning is quiet, not waving")
	assert_string_contains(_words("water_safety", "middle").to_lower(), "red and yellow flags")
	var poisons := _words("poisons_cupboard", "big").to_lower()
	for w: String in ["can't see, smell or taste", "fresh air", "from outside", "button battery"]:
		assert_string_contains(poisons, w, "poisons (Big): " + w)
	var poisons_mid := _words("poisons_cupboard", "middle").to_lower()
	for w: String in ["never mix", "child lock", "mushrooms", "corrosive", "toxic", "flammable"]:
		assert_string_contains(poisons_mid, w, "poisons (Middle): " + w)
	assert_string_contains(_words("poisons_cupboard", "little").to_lower(), "medicine only from your", "medicines")
	var earth := _words("earth_weather", "middle").to_lower()
	for w: String in ["drop", "cover", "hold on", "open ground", "turn around", "inside", "shade"]:
		assert_string_contains(earth, w, "earth (Middle): " + w)
	var earth_big := _words("earth_weather", "big").to_lower()
	for w: String in ["stay put", "whistle", "layers", "shoes", "emergency bag"]:
		assert_string_contains(earth_big, w, "earth (Big): " + w)
	assert_string_contains(_words("earth_weather", "little").to_lower(), "hug a tree")


## "Not for a child to do" is said plainly (design §14): going in after someone, mixing chemicals, going back into
## danger. The words say "never".
func test_not_for_a_child_is_said_plainly() -> void:
	assert_string_contains(_words("water_safety", "middle").to_lower(), "never go in after")
	assert_string_contains(_words("poisons_cupboard", "middle").to_lower(), "never mix")
	assert_string_contains(_words("water_safety", "big").to_lower(), "never walk on the ice")


func test_danger_moments_slow_down_and_the_drop_is_wanted_in_time() -> void:
	for id in L3A:
		for track in LifeData.TRACKS:
			var danger := 0
			for s in _steps(id, track):
				if bool(s.get("danger", false)):
					danger += 1
			if id != "poisons_cupboard":
				assert_gt(danger, 0, "%s.%s has a danger moment (time slows on the first tries)" % [id, track])
	var drop := _step("earth_weather", "middle", "drop")
	assert_true(bool(drop.danger))
	assert_gt(float(drop.get("within", 0.0)), 0.0, "drop at once: within its seconds of the room's time")


func test_the_regions_number_and_georgias_mountains() -> void:
	for id in L3A:
		var said := false
		for track in LifeData.TRACKS:
			said = said or _words(id, track, false, "uk").contains("999")
		assert_true(said, id + " says the region's number")
	assert_string_contains(_words("earth_weather", "little", false, "ge"), "Georgia", "Georgia's mountains shake")
	assert_false(_words("earth_weather", "little", false, "uk").contains("Georgia"), "another region, its own words")
	var sources := JSON.stringify(LifeExperience.track_data("earth_weather", "middle").sources)
	assert_string_contains(sources, ".ge", "Georgia's own guidance where it exists")


func test_each_has_its_devices_and_its_tools_are_in_the_tool_book() -> void:
	assert_true(LifeExperience.devices("poisons_cupboard", "ge").has("co_alarm"))
	assert_true(LifeExperience.devices("poisons_cupboard", "ge").has("child_lock"))
	for tool_id: String in ["life_jacket", "ring_buoy", "reach_pole", "whistle", "child_lock", "co_alarm"]:
		assert_true(ToolBook.has(tool_id), tool_id + " in the Tool Book")
	assert_eq(str(_step("water_safety", "little", "throw").tool), "ring_buoy")
	assert_eq(str(_step("water_safety", "little", "throw").motion), "aim", "a float is aimed and thrown")
	assert_eq(str(_step("poisons_cupboard", "big", "test").device), "co_alarm")
	assert_eq(str(_step("poisons_cupboard", "middle", "lock").device), "child_lock")


func test_the_intensity_reaches_the_rooms_words() -> void:
	assert_eq(str(LifeExperience.vars("water_safety", "big", 1, "ge").intensity), LifeData.GENTLE)
	assert_eq(str(LifeExperience.vars("water_safety", "big", 1, "ge", LifeData.REAL).intensity), LifeData.REAL)
