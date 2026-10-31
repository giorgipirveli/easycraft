extends GutTest
## Owner #112 (docs/design/life-skills.md §3, §10): how each kind of Experience step is checked. The host (flat or VR)
## turns fingers, hands and the head into one sample a frame (pressed, held, aimed, pushes, low, an action, an answer,
## OK, a sweep); a step reads "the hand is here and squeezing", never a particular button, so VR round 4's shared grab
## can feed the same samples later.


func _feed(step: Dictionary, state: Dictionary, sample: Dictionary) -> Dictionary:
	if not sample.has("dt"):
		sample.dt = 0.1
	return LifeCheck.feed(step, state, sample)


func test_every_kind_is_known_and_a_bad_step_is_named() -> void:
	for kind: String in LifeCheck.KINDS:
		assert_ne(kind, "")
	assert_ne(LifeCheck.problem({"kind": "dance", "say": "x"}), "")
	assert_ne(LifeCheck.problem({"kind": "touch", "say": "x"}), "", "a touch needs its target")
	assert_ne(LifeCheck.problem({"kind": "touch", "target": "phone"}), "", "every step says something")
	assert_eq(LifeCheck.problem({"kind": "touch", "target": "phone", "say": "Pick up the phone."}), "")
	assert_ne(LifeCheck.problem({"kind": "choose", "say": "?", "choices": [{"text": "a"}], "answer": 0}), "",
		"a choice needs two choices or more")
	assert_ne(LifeCheck.problem({"kind": "choose", "say": "?", "choices": [{"text": "a"}, {"text": "b"}], "answer": 2}), "")
	assert_ne(LifeCheck.problem({"kind": "rhythm", "say": "Push", "target": "chest", "pushes": 30, "good": 40}), "",
		"never more good pushes than pushes")


## Owner #117 (docs/design/life-skills.md §13): a step names its real motion, one of the ten the shared recogniser
## will know (strike, stroke, twist, squeeze, press, spread, measure, pour, aim, cut); the rules never read it yet.
func test_a_steps_motion_is_one_of_the_ten() -> void:
	assert_eq(LifeCheck.MOTIONS.size(), 10)
	for m: String in ["strike", "stroke", "twist", "squeeze", "press", "spread", "measure", "pour", "aim", "cut"]:
		assert_has(LifeCheck.MOTIONS, m)
	assert_eq(LifeCheck.problem({"kind": "rhythm", "target": "chest", "motion": "press", "say": "Push."}), "")
	assert_ne(LifeCheck.problem({"kind": "rhythm", "target": "chest", "motion": "wiggle", "say": "Push."}), "")
	assert_ne(LifeCheck.problem({"kind": "touch", "target": "phone", "device": 7, "say": "Pick it up."}), "",
		"a device is named by its id")


func test_info_waits_for_ok() -> void:
	var step := {"kind": "info", "say": "This is practice."}
	var s := LifeCheck.begin(step)
	assert_false(_feed(step, s, {}).done)
	assert_true(_feed(step, s, {"ok": true}).done)


func test_touch_is_done_by_a_press_on_its_target_only() -> void:
	var step := {"kind": "touch", "target": "phone", "say": "Pick up the phone."}
	var s := LifeCheck.begin(step)
	assert_false(_feed(step, s, {"pressed": ["cloth"]}).done)
	assert_true(_feed(step, s, {"pressed": ["phone"]}).done)


func test_hold_needs_the_hand_there_and_squeezing_for_its_seconds() -> void:
	var step := {"kind": "hold", "target": "cut", "seconds": 1.0, "say": "Press and hold."}
	var s := LifeCheck.begin(step)
	var r := _feed(step, s, {"held": ["cut"], "dt": 0.5})
	assert_true(r.progress)
	assert_false(r.done)
	assert_false(_feed(step, s, {"held": ["arm"], "dt": 0.5}).done, "held somewhere else does not count")
	assert_true(_feed(step, s, {"held": ["cut"], "dt": 0.6}).done)
	assert_almost_eq(LifeCheck.fraction(step, s), 1.0, 0.01)


func test_taps_counts_presses() -> void:
	var step := {"kind": "taps", "target": "back", "count": 5, "say": "Five back blows."}
	var s := LifeCheck.begin(step)
	for i in 4:
		assert_false(_feed(step, s, {"pressed": ["back"]}).done)
	assert_almost_eq(LifeCheck.fraction(step, s), 0.8, 0.01)
	assert_true(_feed(step, s, {"pressed": ["back"]}).done)


func test_sequence_in_order_and_a_wrong_key_is_a_kind_miss() -> void:
	var step := {"kind": "sequence", "targets": ["key_1", "key_1", "key_2"], "say": "Dial 112."}
	var s := LifeCheck.begin(step)
	assert_eq(LifeCheck.next_targets(step, s), ["key_1"] as Array[String])
	assert_true(_feed(step, s, {"pressed": ["key_1"]}).progress)
	var miss := _feed(step, s, {"pressed": ["key_9"]})
	assert_true(miss.miss)
	assert_false(miss.done)
	assert_true(_feed(step, s, {"pressed": ["key_1"]}).progress)
	assert_eq(LifeCheck.next_targets(step, s), ["key_2"] as Array[String])
	assert_true(_feed(step, s, {"pressed": ["key_2"]}).done)


func test_find_in_any_order_says_each_things_line() -> void:
	var step := {"kind": "find", "targets": ["pan", "candle", "plug"], "say": "Find the dangers.",
		"lines": {"pan": "Turn the handle in.", "candle": "Keep candles away from curtains."}}
	var s := LifeCheck.begin(step)
	var r := _feed(step, s, {"pressed": ["candle"]})
	assert_true(r.progress)
	assert_eq(r.said, "Keep candles away from curtains.")
	assert_false(_feed(step, s, {"pressed": ["candle"]}).progress, "found already")
	_feed(step, s, {"pressed": ["pan"]})
	assert_eq(LifeCheck.next_targets(step, s), ["plug"] as Array[String])
	assert_true(_feed(step, s, {"pressed": ["plug"]}).done)


func test_find_may_need_fewer_than_all() -> void:
	var step := {"kind": "find", "targets": ["a", "b", "c"], "need": 2, "say": "Find two."}
	var s := LifeCheck.begin(step)
	_feed(step, s, {"pressed": ["a"]})
	assert_true(_feed(step, s, {"pressed": ["c"]}).done)


func test_choose_right_is_done_and_wrong_is_a_miss_with_its_words() -> void:
	var step := {"kind": "choose", "say": "Is it safe?", "answer": 0, "miss": "Look again: nothing here can hurt you.",
		"choices": [{"text": "Safe", "icon": "tick"}, {"text": "Not safe", "icon": "cross"}]}
	var s := LifeCheck.begin(step)
	var r := _feed(step, s, {"answer": 1})
	assert_true(r.miss)
	assert_eq(r.said, "Look again: nothing here can hurt you.")
	assert_true(_feed(step, s, {"answer": 0}).done)


func test_action_low_must_be_held_a_moment() -> void:
	var step := {"kind": "action", "action": "low", "seconds": 0.5, "say": "Get low."}
	var s := LifeCheck.begin(step)
	assert_false(_feed(step, s, {"low": true, "dt": 0.3}).done)
	assert_true(_feed(step, s, {"low": true, "dt": 0.3}).done)


func test_action_by_its_big_button_is_done_at_once() -> void:
	var step := {"kind": "action", "action": "roll", "seconds": 1.5, "say": "Roll."}
	var s := LifeCheck.begin(step)
	assert_false(_feed(step, s, {"action": "cover"}).done)
	assert_true(_feed(step, s, {"action": "roll", "action_tap": true}).done)


func test_a_low_step_waits_while_the_child_stands_and_says_so_kindly() -> void:
	var step := {"kind": "touch", "target": "door", "low": true, "say": "Open the door."}
	var s := LifeCheck.begin(step)
	var r := _feed(step, s, {"pressed": ["door"], "low": false})
	assert_false(r.done)
	assert_eq(r.said, LifeCheck.STAY_LOW)
	assert_true(_feed(step, s, {"pressed": ["door"], "low": true}).done)


func test_go_is_a_press_on_its_spot() -> void:
	var step := {"kind": "go", "target": "meeting_point", "say": "Go to the meeting point."}
	var s := LifeCheck.begin(step)
	assert_true(_feed(step, s, {"pressed": ["meeting_point"]}).done)


func test_rhythm_counts_pushes_and_wants_the_beat() -> void:
	var step := {"kind": "rhythm", "target": "chest", "pushes": 10, "good": 6, "say": "Push to the beat."}
	var s := LifeCheck.begin(step)
	var t := 0.0
	var last := {}
	for i in 10:
		t += 0.55   # 109 a minute
		last = _feed(step, s, {"pushes": 1, "time": t})
		assert_true(last.progress)
	assert_true(last.done)
	assert_eq(int(s.count), 10)
	assert_gte(int(s.good), 6)


func test_rhythm_too_slow_says_faster_and_keeps_going() -> void:
	var step := {"kind": "rhythm", "target": "chest", "pushes": 6, "good": 4, "say": "Push to the beat."}
	var s := LifeCheck.begin(step)
	var t := 0.0
	var said: Array[String] = []
	var done := false
	for i in 8:
		t += 1.0   # 60 a minute
		var r := _feed(step, s, {"pushes": 1, "time": t})
		said.append(str(r.said))
		done = done or bool(r.done)
	assert_false(done, "6 pushes at 60 a minute are not yet the beat")
	assert_has(said, LifeCheck.FASTER)


func test_coins_add_up_to_the_change_and_too_much_comes_back() -> void:
	var step := {"kind": "coins", "target": "hand", "sum": 3, "coins": [1, 2, 5], "say": "Give 3 coins change."}
	var s := LifeCheck.begin(step)
	assert_true(_feed(step, s, {"pressed": ["coin_2"]}).progress)
	assert_eq(int(s.sum), 2)
	var over := _feed(step, s, {"pressed": ["coin_5"]})
	assert_eq(over.said, LifeCheck.TOO_MUCH)
	assert_eq(int(s.sum), 2, "the 5 came back")
	assert_true(_feed(step, s, {"pressed": ["coin_1"]}).done)
	assert_eq(s.given, [2, 1])


func test_coins_back_takes_the_last_coin_back() -> void:
	var step := {"kind": "coins", "target": "jar", "sum": 4, "coins": [1, 2], "say": "Save 4."}
	var s := LifeCheck.begin(step)
	_feed(step, s, {"pressed": ["coin_2"]})
	_feed(step, s, {"pressed": ["coins_back"]})
	assert_eq(int(s.sum), 0)


func test_basket_needs_everything_on_the_list_within_the_budget() -> void:
	var step := {"kind": "basket", "budget": 10, "say": "Shop with 10 coins.",
		"items": [{"target": "bread", "price": 2, "need": true}, {"target": "milk", "price": 3, "need": true},
			{"target": "toy", "price": 6, "need": false}, {"target": "apples", "price": 2, "need": false}]}
	var s := LifeCheck.begin(step)
	_feed(step, s, {"pressed": ["bread"]})
	_feed(step, s, {"pressed": ["toy"]})
	var r := _feed(step, s, {"pressed": ["till"]})
	assert_true(r.miss, "the milk is missing")
	assert_eq(r.said, LifeCheck.LIST_MISSING)
	_feed(step, s, {"pressed": ["milk"]})
	r = _feed(step, s, {"pressed": ["till"]})
	assert_eq(r.said, LifeCheck.OVER_BUDGET, "2 + 6 + 3 = 11")
	_feed(step, s, {"pressed": ["toy"]})   # put back
	assert_eq(LifeCheck.basket_total(step, s), 5)
	assert_true(_feed(step, s, {"pressed": ["till"]}).done)


func test_sweep_counts_side_to_side_while_squeezing() -> void:
	var step := {"kind": "sweep", "target": "fire_base", "sweeps": 3, "say": "Sweep side to side."}
	var s := LifeCheck.begin(step)
	var done := false
	for u: float in [-0.8, 0.0, 0.7, 0.1, -0.6, 0.5]:
		done = bool(_feed(step, s, {"sweep_u": u}).done)
	assert_true(done)
	assert_eq(int(s.crossings), 3)


func test_point_aims_for_its_seconds_or_a_tap() -> void:
	var step := {"kind": "point", "target": "fire_base", "seconds": 0.5, "say": "Aim at the bottom of the fire."}
	var s := LifeCheck.begin(step)
	assert_false(_feed(step, s, {"aimed": ["fire_base"], "dt": 0.3}).done)
	assert_true(_feed(step, s, {"aimed": ["fire_base"], "dt": 0.3}).done)
	var t := LifeCheck.begin(step)
	assert_true(_feed(step, t, {"pressed": ["fire_base"]}).done, "a flat tap aims at once")


func test_timelapse_plays_by_itself() -> void:
	var step := {"kind": "timelapse", "seconds": 2.0, "say": "Cool it for 20 minutes.", "label": "20 minutes"}
	var s := LifeCheck.begin(step)
	assert_false(_feed(step, s, {"dt": 1.5}).done)
	assert_true(_feed(step, s, {"dt": 0.6}).done)


func test_the_one_next_thing() -> void:
	assert_eq(LifeCheck.next_targets({"kind": "touch", "target": "phone", "say": "x"}, {}), ["phone"] as Array[String])
	var hunt := {"kind": "find", "targets": ["a", "b"], "say": "x"}
	assert_eq(LifeCheck.next_targets(hunt, LifeCheck.begin(hunt)), ["a"] as Array[String], "one at a time")
	var coins := {"kind": "coins", "target": "hand", "sum": 3, "coins": [1, 2], "say": "x"}
	assert_eq(LifeCheck.next_targets(coins, LifeCheck.begin(coins)), ["coin_2"] as Array[String],
		"the coach shows the biggest coin that still fits")
