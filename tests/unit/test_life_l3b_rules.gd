extends GutTest
## Owner #118 (docs/design/life-skills.md §14; Life L3b): the framework's two small new rules. A safe mistake's
## `try: "unsafe"` is the right target at the wrong moment (Safe Streets' crossing pressed while a car comes, Real
## Builder's saw used before the goggles are on): pressed while the sample says it is not safe, it is the mistake (never
## a miss); pressed while safe, the step is done. The body action "tree" (a dog runs at you: be a tree: still, arms in,
## look at your feet). The region's own words on wild animals ({wild_where}: Georgia's mountains).


func _cross() -> Dictionary:
	return {"id": "cross_van", "kind": "cross", "target": "far_kerb_van", "say": "Wait for a big gap, then cross.",
		"miss": "Wait! A car is coming.",
		"safe_mistake": {"wrong": "stepping out while a car comes", "try": "unsafe", "event": "step_out_gap",
			"icon": "car_close", "why": "A driver needs time to stop.", "right": "Wait for a big gap."}}


func test_an_unsafe_press_is_the_safe_mistake_never_a_miss() -> void:
	var step := _cross()
	assert_eq(LifeCheck.problem(step), "", "a cross step may name the wrong moment")
	assert_true(LifeCheck.tries_mistake(step))
	var state := LifeCheck.begin(step)
	var r := LifeCheck.feed(step, state, {"dt": 0.1, "pressed": ["far_kerb_van"], "safe": false})
	assert_true(r.mistake, "pressed while a car comes: the safe mistake")
	assert_false(r.miss, "never a miss")
	assert_false(r.done)
	r = LifeCheck.feed(step, state, {"dt": 0.1, "safe": false})
	assert_false(r.mistake, "waiting is never a mistake")
	assert_true(r.progress, "waiting at the kerb while a car comes is the right thing")
	r = LifeCheck.feed(step, state, {"dt": 0.1, "pressed": ["far_kerb_van"], "safe": true})
	assert_true(r.done, "pressed in a big gap: across")
	assert_false(r.mistake)


func test_the_wrong_moment_is_never_a_thing_in_the_room() -> void:
	assert_false(LifeCheck.targets_of(_cross()).has("unsafe"), "only the far kerb, at the wrong moment")
	assert_has(LifeCheck.targets_of(_cross()), "far_kerb_van")


func test_the_wrong_moment_needs_a_moment_that_can_be_wrong() -> void:
	var touch := {"id": "t", "kind": "touch", "target": "lid", "say": "Put the lid on.",
		"safe_mistake": {"wrong": "w", "try": "unsafe", "event": "e", "why": "why", "right": "right"}}
	assert_ne(LifeCheck.problem(touch), "", "a plain touch has no unsafe moment")
	touch["safety"] = "goggles"
	assert_eq(LifeCheck.problem(touch), "", "a tool used before its safety gear is on: the unsafe moment")
	var state := LifeCheck.begin(touch)
	assert_false(LifeCheck.feed(touch, state, {"dt": 0.1, "pressed": ["lid"]}).mistake,
		"a sample that says nothing about safety is safe")
	assert_true(LifeCheck.feed(touch, state, {"dt": 0.1, "pressed": ["lid"], "safe": false}).mistake)


func test_little_still_has_no_safe_mistake_and_a_little_crossing_still_misses_kindly() -> void:
	var step := _cross()
	step.erase("safe_mistake")
	var state := LifeCheck.begin(step)
	var r := LifeCheck.feed(step, state, {"dt": 0.1, "pressed": ["far_kerb_van"], "safe": false})
	assert_true(r.miss, "without a safe mistake: L2's kind miss (the car stops gently)")
	assert_false(r.mistake)


func test_be_a_tree_is_a_body_action() -> void:
	assert_has(LifeCheck.ACTIONS, "tree")
	var step := {"id": "tree", "kind": "action", "action": "tree", "seconds": 1.0, "button": "BE A TREE",
		"say": "Be a tree: stand still, arms in, look at your feet."}
	assert_eq(LifeCheck.problem(step), "")
	var state := LifeCheck.begin(step)
	assert_false(LifeCheck.feed(step, state, {"dt": 0.5, "action": "still"}).done, "only still is not a tree yet")
	var r := LifeCheck.feed(step, state, {"dt": 0.6, "action": "tree"})
	assert_true(r.progress)
	r = LifeCheck.feed(step, state, {"dt": 0.6, "action": "tree"})
	assert_true(r.done, "still, arms in, eyes down, for its seconds")
	state = LifeCheck.begin(step)
	assert_true(LifeCheck.feed(step, state, {"dt": 0.1, "action": "tree", "action_tap": true}).done,
		"flat: the BE A TREE button")
	var auto := LifeRun.new([step, {"id": "end", "kind": "info", "say": "Well done."}] as Array[Dictionary])
	var frames := 0
	while not auto.finished and frames < 100:
		auto.feed(LifeAuto.sample(auto.current(), auto.state, 0.1))
		frames += 1
	assert_true(auto.finished, "the automatic player is a tree too")


func test_running_from_the_dog_is_a_place_to_run_to_never_a_body_action() -> void:
	var step := {"id": "tree", "kind": "action", "action": "tree", "say": "Be a tree.",
		"safe_mistake": {"wrong": "running from a dog", "try": "run_away", "event": "dog_chase", "icon": "run",
			"why": "Running makes a dog want to chase.", "right": "Be a tree."}}
	assert_eq(LifeCheck.problem(step), "")
	assert_has(LifeCheck.targets_of(step), "run_away", "the path behind: a place in the room")
	var state := LifeCheck.begin(step)
	assert_true(LifeCheck.feed(step, state, {"dt": 0.1, "pressed": ["run_away"]}).mistake)


func test_the_regions_wild_animals() -> void:
	assert_string_contains(LifeRegion.wild_words("ge"), "Georgia")
	assert_string_contains(LifeRegion.wild_words("ge").to_lower(), "bears")
	assert_string_contains(LifeRegion.wild_words("ge").to_lower(), "shepherd dogs", "the flocks' guard dogs")
	assert_false(LifeRegion.wild_words("uk").contains("Georgia"))
	assert_ne(LifeRegion.wild_words("zz"), "", "an unknown region: the default sentence")
	assert_eq(str(LifeExperience.vars("water_safety", "big", 1, "ge").wild_where), LifeRegion.wild_words("ge"),
		"a token for every Experience's words")
