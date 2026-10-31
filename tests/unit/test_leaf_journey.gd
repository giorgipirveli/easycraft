extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5 steps 1-3 and 9-11, §3.5b steps 1-2 and 8; the B2 brief): a
## voyage from the garden and back, as the host plays it (pure: LeafJourney; inside the plant it is B1's LeafRun). The
## garden's hook (5.1: water the soil, then touch the leaf; 5.T1: no can, touch the cactus's green stem), the ghost after
## 6 s of nothing, the dive, under the leaf, inside, the return when the bud is full, the world's answer line by line and
## the end. Hoot's lines come as cues, each said once.

func _cues_said(j: LeafJourney) -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in j.take_cues():
		if c.has("say"):
			out.append(str(c.say))
	return out


func _run(j: LeafJourney, seconds: float, dt: float = 0.1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var t := 0.0
	while t < seconds - 0.0001:
		j.step(dt)
		out.append_array(j.take_cues())
		t += dt
	return out


func _said(cues: Array[Dictionary]) -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in cues:
		if c.has("say"):
			out.append(str(c.say))
	return out


func test_the_sunflower_s_hook_waters_the_soil_then_dives_into_the_leaf() -> void:
	var j := LeafJourney.make("5.1", 1)
	j.start()
	assert_eq(j.stage, LeafJourney.HOOK)
	var first := j.take_cues()
	assert_true(_said(first).has("L1"), "Oh no! Our sunflower is drooping in the heat.")
	assert_true(first.any(func(c: Dictionary) -> bool: return c.get("glow", []) == ["can"]), "the can glows")
	assert_false(j.touch_leaf(), "the leaf waits until the soil is watered")
	assert_true(j.water())
	assert_true(j.watered)
	var after := j.take_cues()
	assert_true(_said(after).has("L2"), "Good! But it still droops. Let's look inside!")
	assert_true(after.any(func(c: Dictionary) -> bool: return c.get("glow", []) == ["leaf"]), "the leaf glows")
	assert_true(_said(_run(j, 4.0)).has("L3"), "Touch the leaf. Size Magic!")
	assert_true(j.touch_leaf())
	assert_eq(j.stage, LeafJourney.DIVE)
	assert_true(_said(j.take_cues()).has("L4"), "Smaller... smaller...")


func test_a_child_who_does_nothing_sees_the_ghost_show_the_can_then_the_leaf() -> void:
	var j := LeafJourney.make("5.1", 1)
	j.start()
	j.take_cues()
	var cues := _run(j, LeafJourney.GHOST_AFTER + 0.2)
	assert_true(cues.any(func(c: Dictionary) -> bool: return c.get("ghost", "") == "can"), "after 6 s: the can")
	j.water()
	cues = _run(j, LeafJourney.GHOST_AFTER + 0.2)
	assert_true(cues.any(func(c: Dictionary) -> bool: return c.get("ghost", "") == "leaf"), "then the leaf")


func test_the_desert_has_no_can_the_cactus_stem_is_touched_at_once() -> void:
	var j := LeafJourney.make("5.T1", 1)
	j.start()
	var first := j.take_cues()
	assert_true(_said(first).has("D1"), "A cactus from the desert! It's hot and thirsty.")
	assert_true(first.any(func(c: Dictionary) -> bool: return c.get("glow", []) == ["leaf"]), "its stem glows")
	assert_false(j.has_can())
	assert_false(j.water(), "no watering can: the sand is dry")
	assert_true(j.touch_leaf())
	assert_true(_said(j.take_cues()).has("D2"), "Let's look inside its green stem. Size Magic!")


func test_the_dive_goes_under_the_leaf_then_inside_where_the_run_starts() -> void:
	var j := LeafJourney.make("5.1", 1)
	j.start()
	j.water()
	j.touch_leaf()
	var cues := _run(j, LeafJourney.DIVE_TIME + 0.05)
	assert_eq(j.stage, LeafJourney.UNDER)
	assert_true(_said(cues).has("L5"), "Up through a door! Let's go in.")
	assert_almost_eq(j.progress(), 0.0, 0.05)
	cues = _run(j, LeafJourney.UNDER_TIME + 0.05)
	assert_eq(j.stage, LeafJourney.INSIDE)
	assert_eq(j.run.phase, LeafRun.ACT1, "the run has started")
	assert_true(_said(cues).has("L6"), "inside: Look! The water is escaping through the doors.")


func test_when_the_bud_is_full_the_journey_returns_and_the_world_answers_line_by_line() -> void:
	var j := LeafJourney.make("5.1", 1)
	j.start()
	j.water()
	j.touch_leaf()
	_run(j, LeafJourney.DIVE_TIME + LeafJourney.UNDER_TIME + 0.2)
	j.run.phase = LeafRun.DONE   # the bud filled (LeafRun's own tests play there)
	j.step(0.1)
	assert_eq(j.stage, LeafJourney.RETURN)
	var cues := _run(j, LeafJourney.RETURN_TIME + LeafJourney.ANSWER_GAP * 5.0)
	var said := _said(cues)
	for id: String in ["L22", "L23", "L24", "L25", "L26"]:
		assert_true(said.has(id), id)
	assert_lt(said.find("L22"), said.find("L24"), "the bloom before the idea")
	assert_eq(j.stage, LeafJourney.END)


func test_the_desert_answers_with_its_night_flower_and_the_rule_in_words() -> void:
	var j := LeafJourney.make("5.T1", 1)
	j.start()
	j.touch_leaf()
	_run(j, LeafJourney.DIVE_TIME + LeafJourney.UNDER_TIME + 0.2)
	j.run.phase = LeafRun.DONE
	j.step(0.1)
	var said := _said(_run(j, LeafJourney.RETURN_TIME + LeafJourney.ANSWER_GAP * 4.0))
	for id: String in ["D8", "D9", "D10"]:
		assert_true(said.has(id), id)
	assert_eq(j.stage, LeafJourney.END)
