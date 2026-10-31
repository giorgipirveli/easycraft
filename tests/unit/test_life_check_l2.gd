extends GutTest
## Owner #112, #113, #117 (docs/design/life-skills.md §5 #4-#6, §10, §13; Life L2): the kinds of step Safe Streets, The
## Kitchen and Calm Corner add to LifeCheck, each from the same one sample a frame:
## - look: look both ways in the region's order (flat: a LOOK swipe or button, `looked`; VR: the head's turn, `look_yaw`);
## - cross: go across only when it is safe (the room's traffic says `safe`); stepping out on an unsafe moment is a kind
##   miss (the car stops gently); waiting while it is not safe is the right thing (it counts as progress, so the coach
##   never nags a child who waits);
## - rub: rub the hands for their seconds (soap, 20 s); - pour: pour (or spoon onto the scales) until the level is in its
##   band, then let go; - breathe: balloon breathing, in for a few seconds, out for a few; - feel: any picture is right
##   (nothing is marked, nothing is kept); - steady: hold a pedal to keep a needle in its band for some seconds.


func _feed(step: Dictionary, state: Dictionary, sample: Dictionary) -> Dictionary:
	if not sample.has("dt"):
		sample.dt = 0.1
	return LifeCheck.feed(step, state, sample)


func test_the_new_kinds_are_known_and_checked() -> void:
	for kind: String in ["look", "cross", "rub", "pour", "breathe", "feel", "steady"]:
		assert_has(LifeCheck.KINDS, kind)
	assert_ne(LifeCheck.problem({"kind": "look", "say": "Look.", "sides": []}), "", "a look needs its sides")
	assert_ne(LifeCheck.problem({"kind": "look", "say": "Look.", "sides": ["up"]}), "", "left or right only")
	assert_eq(LifeCheck.problem({"kind": "look", "say": "Look.", "sides": ["left", "right", "left"]}), "")
	assert_ne(LifeCheck.problem({"kind": "cross", "say": "Cross."}), "", "a cross needs where to go")
	assert_ne(LifeCheck.problem({"kind": "pour", "say": "Pour.", "target": "jug", "want": 2.0, "full": 1.0}), "",
		"the level wanted fits the jug")
	assert_eq(LifeCheck.problem({"kind": "pour", "say": "Pour.", "target": "jug", "want": 0.5, "full": 1.0, "tol": 0.07}), "")
	assert_ne(LifeCheck.problem({"kind": "breathe", "say": "Breathe.", "target": "balloon", "breaths": 0}), "")
	assert_ne(LifeCheck.problem({"kind": "feel", "say": "How?", "choices": [{"text": "Happy", "icon": "face_happy"}]}), "",
		"two pictures or more")
	assert_ne(LifeCheck.problem({"kind": "steady", "say": "Go.", "target": "pedal", "lo": 30, "hi": 20, "top": 60}), "")
	assert_eq(LifeCheck.problem({"kind": "steady", "say": "Go.", "target": "pedal", "lo": 20, "hi": 30, "top": 60,
		"seconds": 3}), "")


# --- look ------------------------------------------------------------------------------------------------------------

func test_look_both_ways_in_the_regions_order_by_swipes() -> void:
	var step := {"kind": "look", "sides": ["left", "right", "left"], "say": "Look left, right, left."}
	var s := LifeCheck.begin(step)
	var r := _feed(step, s, {"looked": "right"})
	assert_false(r.progress, "the wrong way first: not yet")
	assert_false(r.miss, "never a miss: just the kind words")
	assert_string_contains(r.said, "left")
	assert_true(_feed(step, s, {"looked": "left"}).progress)
	assert_true(_feed(step, s, {"looked": "right"}).progress)
	assert_almost_eq(LifeCheck.fraction(step, s), 2.0 / 3.0, 0.01)
	assert_true(_feed(step, s, {"looked": "left"}).done)


func test_look_in_vr_is_the_heads_turn_each_way() -> void:
	var step := {"kind": "look", "sides": ["right", "left", "right"], "say": "Look right, left, right."}
	var s := LifeCheck.begin(step)
	assert_false(_feed(step, s, {"look_yaw": deg_to_rad(10.0)}).progress, "a glance is not a look")
	assert_true(_feed(step, s, {"look_yaw": deg_to_rad(-50.0)}).progress, "the head turned right")
	assert_false(_feed(step, s, {"look_yaw": deg_to_rad(-55.0)}).progress, "still looking right: one look")
	assert_true(_feed(step, s, {"look_yaw": deg_to_rad(48.0)}).progress, "then left")
	assert_true(_feed(step, s, {"look_yaw": deg_to_rad(-45.0)}).done, "and right again")


func test_look_glows_the_way_to_look_next() -> void:
	var step := {"kind": "look", "sides": ["left", "right", "left"], "say": "Look."}
	var s := LifeCheck.begin(step)
	assert_eq(LifeCheck.next_targets(step, s), ["look_left"] as Array[String])
	_feed(step, s, {"looked": "left"})
	assert_eq(LifeCheck.next_targets(step, s), ["look_right"] as Array[String])
	assert_has(LifeCheck.targets_of(step), "look_left")
	assert_has(LifeCheck.targets_of(step), "look_right")


# --- cross -----------------------------------------------------------------------------------------------------------

func test_cross_only_when_it_is_safe_and_an_unsafe_step_is_a_kind_miss() -> void:
	var step := {"kind": "cross", "target": "far_kerb", "say": "Cross when it is safe.", "miss": "Wait! A car is coming."}
	var s := LifeCheck.begin(step)
	var wait := _feed(step, s, {"safe": false})
	assert_true(wait.progress, "waiting while a car comes is the right thing: no coach for it")
	var r := _feed(step, s, {"pressed": ["far_kerb"], "safe": false})
	assert_true(r.miss)
	assert_false(r.done)
	assert_eq(r.said, "Wait! A car is coming.")
	assert_false(_feed(step, s, {"safe": true}).progress, "safe now, and waiting: the coach may show the way")
	assert_true(_feed(step, s, {"pressed": ["far_kerb"], "safe": true}).done)


func test_cross_glows_only_when_it_is_safe_and_never_on_the_expert_try() -> void:
	var step := {"kind": "cross", "target": "far_kerb", "say": "Cross."}
	var s := LifeCheck.begin(step)
	_feed(step, s, {"safe": false})
	assert_eq(LifeCheck.next_targets(step, s), [] as Array[String], "nothing glows while a car comes")
	_feed(step, s, {"safe": true})
	assert_eq(LifeCheck.next_targets(step, s), ["far_kerb"] as Array[String])
	var expert := {"kind": "cross", "target": "far_kerb", "say": "Cross.", "glow": false}
	var e := LifeCheck.begin(expert)
	_feed(expert, e, {"safe": true})
	assert_eq(LifeCheck.next_targets(expert, e), [] as Array[String], "the Expert try judges the gap alone")


# --- rub, pour -------------------------------------------------------------------------------------------------------

func test_rub_counts_only_the_seconds_spent_rubbing() -> void:
	var step := {"kind": "rub", "target": "hands", "seconds": 2.0, "say": "Rub for 20 seconds."}
	var s := LifeCheck.begin(step)
	assert_true(_feed(step, s, {"rubbing": ["hands"], "dt": 1.0}).progress)
	assert_false(_feed(step, s, {"held": ["hands"], "dt": 1.0}).progress, "holding still is not rubbing")
	assert_almost_eq(LifeCheck.fraction(step, s), 0.5, 0.01)
	assert_true(_feed(step, s, {"rubbing": ["hands"], "dt": 1.0}).done)


func test_pour_until_the_level_is_in_its_band_then_let_go() -> void:
	var step := {"kind": "pour", "target": "jug", "want": 0.5, "full": 1.0, "tol": 0.07, "rate": 0.25,
		"say": "Pour half a cup."}
	var s := LifeCheck.begin(step)
	assert_true(_feed(step, s, {"held": ["jug"], "dt": 1.0}).progress)
	var early := _feed(step, s, {})
	assert_false(early.done, "a quarter: not yet")
	assert_eq(early.said, LifeCheck.POUR_MORE)
	_feed(step, s, {"held": ["jug"], "dt": 1.0})
	assert_almost_eq(float(s.level), 0.5, 0.001)
	assert_true(_feed(step, s, {}).done, "half a cup, then let go")


func test_pouring_too_much_comes_back_kindly() -> void:
	var step := {"kind": "pour", "target": "scales", "want": 200, "full": 500, "tol": 15, "rate": 100, "say": "200 g."}
	var s := LifeCheck.begin(step)
	_feed(step, s, {"held": ["scales"], "dt": 3.0})
	var r := _feed(step, s, {})
	assert_false(r.done)
	assert_false(r.miss, "too much is not a mistake to count")
	assert_eq(r.said, LifeCheck.POUR_TOO_MUCH)
	assert_lt(float(s.level), 200.0, "a little goes back")
	while float(s.level) < 200.0:
		_feed(step, s, {"held": ["scales"], "dt": 0.05})
	assert_true(_feed(step, s, {}).done)


# --- breathe ---------------------------------------------------------------------------------------------------------

func test_balloon_breathing_in_slowly_and_out_slowly() -> void:
	var step := {"kind": "breathe", "target": "balloon", "breaths": 2, "in": 2.0, "out": 2.0, "say": "Breathe in..."}
	var s := LifeCheck.begin(step)
	_feed(step, s, {"held": ["balloon"], "dt": 1.0})
	var quick := _feed(step, s, {})
	assert_eq(quick.said, LifeCheck.BREATHE_SLOWLY, "a quick breath: slowly, kindly")
	for i in 2:
		for k in 3:
			_feed(step, s, {"held": ["balloon"], "dt": 1.0})
		for k in 2:
			_feed(step, s, {"dt": 1.0})
	assert_eq(int(s.count), 2)
	assert_almost_eq(LifeCheck.fraction(step, s), 1.0, 0.01)


func test_breathing_finishes_after_its_breaths() -> void:
	var step := {"kind": "breathe", "target": "balloon", "breaths": 1, "in": 1.0, "out": 1.0, "say": "Breathe."}
	var s := LifeCheck.begin(step)
	_feed(step, s, {"held": ["balloon"], "dt": 1.2})
	_feed(step, s, {"dt": 0.5})
	assert_true(_feed(step, s, {"dt": 0.6}).done)


# --- feel, steady ----------------------------------------------------------------------------------------------------

func test_feel_takes_any_picture_and_answers_it_kindly() -> void:
	var step := {"kind": "feel", "say": "How do you feel now?", "choices": [
		{"text": "Happy", "icon": "face_happy", "reply": "Lovely!"},
		{"text": "Sad", "icon": "face_sad", "reply": "It is OK to feel sad."}]}
	var s := LifeCheck.begin(step)
	var r := _feed(step, s, {"answer": 1})
	assert_true(r.done, "any picture is right")
	assert_false(r.miss)
	assert_eq(r.said, "It is OK to feel sad.")
	assert_has(LifeRun.NO_HINTS, "feel", "the coach never picks a feeling for a child")


func test_steady_keeps_the_needle_in_its_band() -> void:
	var step := {"kind": "steady", "target": "pedal", "lo": 20, "hi": 30, "top": 60, "up": 10, "down": 10, "seconds": 2,
		"say": "Keep it under 30."}
	var s := LifeCheck.begin(step)
	for i in 19:
		_feed(step, s, {"held": ["pedal"], "dt": 0.1})
	assert_almost_eq(float(s.value), 19.0, 0.01)
	assert_almost_eq(float(s.t), 0.0, 0.001, "under the band: no seconds yet")
	var said: Array[String] = []
	for i in 15:
		said.append(str(_feed(step, s, {"held": ["pedal"], "dt": 0.1}).said))
	assert_has(said, LifeCheck.TOO_FAST, "over the limit: ease off")
	assert_lt(float(s.t), 2.0, "the seconds count only inside the band")
	var done := false
	var frames := 0
	while not done and frames < 200:
		frames += 1
		done = _feed(step, s, {"held": ["pedal"] if float(s.value) < 25.0 else [], "dt": 0.1}).done
	assert_true(done, "eased back into the band and kept it there")
	assert_almost_eq(LifeCheck.fraction(step, s), 1.0, 0.01)


# --- the automatic player ------------------------------------------------------------------------------------------

func test_the_automatic_player_does_every_new_kind() -> void:
	var steps: Array[Dictionary] = [
		{"id": "a", "kind": "look", "sides": ["left", "right", "left"], "say": "Look."},
		{"id": "b", "kind": "cross", "target": "far_kerb", "say": "Cross."},
		{"id": "c", "kind": "rub", "target": "hands", "seconds": 2.0, "say": "Rub."},
		{"id": "d", "kind": "pour", "target": "jug", "want": 0.75, "full": 1.0, "tol": 0.07, "rate": 0.3, "say": "Pour."},
		{"id": "e", "kind": "breathe", "target": "balloon", "breaths": 2, "in": 1.5, "out": 1.5, "say": "Breathe."},
		{"id": "f", "kind": "feel", "say": "How?", "choices": [{"text": "Happy", "icon": "face_happy"},
			{"text": "Calm", "icon": "face_calm"}]},
		{"id": "g", "kind": "steady", "target": "pedal", "lo": 20, "hi": 30, "top": 60, "seconds": 2, "say": "Go."},
		{"id": "h", "kind": "info", "say": "Well done."}]
	var run := LifeRun.new(steps)
	var frames := 0
	while not run.finished and frames < 2000:
		run.feed(LifeAuto.sample(run.current(), run.state, 0.1))
		frames += 1
	assert_true(run.finished, "stuck at " + str(run.current().get("id", "")))
	assert_eq(run.total_hints(), 0)
