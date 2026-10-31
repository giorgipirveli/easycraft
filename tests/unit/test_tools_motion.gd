extends GutTest
## Owner #116, #117 (docs/design/life-skills.md §13): the ten real motions, one recogniser for a hand in VR and a finger
## on a phone. Every motion is checked done well (it finishes), done badly (it never counts) and almost (a kind word, no
## count), from samples in the work's own frame (metres: x along the work, y up out of the surface, z across).

const DT := 1.0 / 72.0


func _m(motion: String, checks: Dictionary = {}) -> ToolMotion:
	return ToolMotion.new(motion, checks)


## Feeds samples; returns every event (the last one is `last`).
func _feed(m: ToolMotion, samples: Array) -> Dictionary:
	var out := {"said": [], "verdicts": [], "done": false, "buzz": 0, "progress": 0}
	for s: Dictionary in samples:
		var e := m.feed(s)
		if str(e.said) != "":
			out.said.append(str(e.said))
		if str(e.verdict) != "":
			out.verdicts.append(str(e.verdict))
		if bool(e.done):
			out.done = true
		if float(e.buzz) > 0.0:
			out.buzz += 1
		if bool(e.progress):
			out.progress += 1
	return out


func _vr(at: Vector3, extra: Dictionary = {}) -> Dictionary:
	var s := {"dt": DT, "at": at, "touch": at.y <= 0.02, "flat": false}
	s.merge(extra, true)
	return s


func _finger(at: Vector3, down: bool, extra: Dictionary = {}) -> Dictionary:
	var s := {"dt": DT, "at": Vector3(at.x, 0.0, at.z), "touch": down, "trigger": 1.0 if down else 0.0, "flat": true,
		"reach": 0.02}
	s.merge(extra, true)
	return s


func _idle(n: int, at: Vector3 = Vector3(0, 0.3, 0)) -> Array:
	var out := []
	for i in n:
		out.append(_vr(at))
	return out


# --- The list is the one source -------------------------------------------------------------------------------------

func test_the_ten_motions_are_the_designs_words_in_its_order() -> void:
	assert_eq(ToolMotion.ALL, ["strike", "stroke", "twist", "squeeze", "press", "spread", "measure", "pour", "aim", "cut"]
		as Array[String])
	assert_eq(ToolMotion.ALL, LifeCheck.MOTIONS, "Life's step data names the same ten (LifeCheck can point here)")
	for m in ToolMotion.ALL:
		assert_true(ToolMotion.CHECKS.has(m), m + " has its checks")


func test_an_unknown_motion_is_a_problem_and_never_finishes() -> void:
	assert_ne(ToolMotion.problem("juggle", {}), "")
	assert_eq(ToolMotion.problem("strike", {}), "")
	assert_ne(ToolMotion.problem("strike", {"hits": 0}), "", "a motion needs something to do")
	var m := _m("juggle")
	assert_false(bool(m.feed(_vr(Vector3.ZERO)).done))


func test_a_tools_and_a_steps_checks_change_the_numbers() -> void:
	var m := ToolMotion.new("strike", {"hits": 5}, {"hits": 2, "min_speed": 0.5})
	assert_eq(int(m.checks.hits), 2, "the step's own numbers win over the tool's")
	assert_eq(float(m.checks.min_speed), 0.5)
	assert_eq(float(m.checks.max_speed), float(ToolMotion.CHECKS.strike.max_speed), "the rest stay the motion's")


# --- Strike: a swing that lands on the target, its speed checked ---------------------------------------------------

## A swing down onto (x, z) at `speed` m/s, from 12 cm up; then back up.
func _swing(speed: float, x: float = 0.0, z: float = 0.0, slant: float = 0.0) -> Array:
	var out := []
	var y := 0.12
	var p := Vector3(x - slant * y, y, z)
	while y > -0.01:
		out.append(_vr(p))
		y -= speed * DT
		p = Vector3(x - slant * maxf(y, 0.0), y, z)
	out.append(_vr(p))
	out.append_array(_idle(6, Vector3(x, 0.15, z)))
	return out


func test_strike_well_three_good_hits_drive_it_in() -> void:
	var m := _m("strike")
	var r := _feed(m, _swing(2.0) + _swing(2.2) + _swing(1.8))
	assert_true(r.done, "three steady hits")
	assert_eq(m.count, 3)
	assert_eq(r.buzz, 3, "a soft buzz on each good hit")
	assert_eq(r.verdicts, ["good", "good", "good"])


func test_strike_badly_a_swing_that_misses_never_counts() -> void:
	var m := _m("strike")
	var r := _feed(m, _swing(2.0, 0.3, 0.0) + _swing(2.0, 0.0, 0.25))
	assert_false(r.done)
	assert_eq(m.count, 0)
	assert_eq(r.said, [], "a swing nowhere near is not about this nail: no words")


func test_strike_almost_too_soft_off_centre_or_too_hard_says_kindly() -> void:
	var m := _m("strike")
	var soft := _feed(m, _swing(0.6))
	assert_eq(soft.said, [ToolMotion.HARDER])
	m = _m("strike")
	var off := _feed(m, _swing(2.0, 0.06))
	assert_eq(off.said, [ToolMotion.CENTRE])
	m = _m("strike")
	var hard := _feed(m, _swing(8.0))
	assert_eq(hard.said, [ToolMotion.SOFTER])
	assert_eq(m.count, 0, "almost is never a count")
	assert_eq(soft.verdicts + off.verdicts + hard.verdicts, ["almost", "almost", "almost"])


func test_strike_a_glancing_blow_is_almost() -> void:
	var m := _m("strike")
	var r := _feed(m, _swing(2.0, 0.0, 0.0, 1.5))
	assert_eq(r.said, [ToolMotion.STRAIGHT])
	assert_eq(m.count, 0)


func test_strike_resting_the_tool_on_it_is_not_a_hit() -> void:
	var m := _m("strike")
	var r := _feed(m, _swing(0.2))
	assert_eq(m.count, 0)
	assert_eq(r.said, [])


func test_strike_flat_a_tap_on_the_target() -> void:
	var m := _m("strike", {"hits": 2})
	var r := _feed(m, [_finger(Vector3(0.01, 0, 0), true), _finger(Vector3.ZERO, false), _finger(Vector3(0, 0, 0.01), true),
		_finger(Vector3.ZERO, false)])
	assert_true(r.done, "two taps on the nail")
	m = _m("strike")
	r = _feed(m, [_finger(Vector3(0.07, 0, 0), true), _finger(Vector3.ZERO, false)])
	assert_eq(r.said, [ToolMotion.CENTRE], "a tap just beside it: almost")
	m = _m("strike")
	r = _feed(m, [_finger(Vector3(0.4, 0, 0), true), _finger(Vector3.ZERO, false)])
	assert_eq(m.count, 0)
	assert_eq(r.said, [])


# --- Stroke: back and forth along a line ----------------------------------------------------------------------------

## Back and forth along x between -half and +half, `n` strokes, at `speed` m/s, `z` off the line.
func _strokes(n: int, half: float, speed: float, z: float = 0.0, flat: bool = false) -> Array:
	var out := []
	var x := -half
	var dir := 1.0
	var done := 0
	while done < n:
		x += dir * speed * DT
		if (dir > 0 and x >= half) or (dir < 0 and x <= -half):
			x = half * dir
			dir = -dir
			done += 1
		out.append(_finger(Vector3(x, 0, z), true) if flat else _vr(Vector3(x, 0.0, z)))
	out.append(_finger(Vector3(x, 0, z), true) if flat else _vr(Vector3(x - dir * 0.05, 0.0, z)))
	out.append(_finger(Vector3(x, 0, z), true) if flat else _vr(Vector3(x - dir * 0.08, 0.0, z)))
	return out


func test_stroke_well_long_steady_strokes_on_the_line() -> void:
	var m := _m("stroke")
	var r := _feed(m, _strokes(8, 0.1, 0.3))
	assert_true(r.done)
	assert_gte(m.count, 6)


func test_stroke_badly_far_off_the_line_never_counts() -> void:
	var m := _m("stroke")
	var r := _feed(m, _strokes(8, 0.1, 0.3, 0.09))
	assert_eq(m.count, 0)
	assert_has(r.said, ToolMotion.LINE)
	assert_has(r.verdicts, "bad")


func test_stroke_almost_short_or_fast_or_drifting() -> void:
	var m := _m("stroke")
	var r := _feed(m, _strokes(4, 0.02, 0.2))
	assert_has(r.said, ToolMotion.LONGER)
	assert_eq(m.count, 0)
	m = _m("stroke")
	r = _feed(m, _strokes(4, 0.1, 2.4))
	assert_has(r.said, ToolMotion.SLOWER)
	assert_eq(m.count, 0)
	m = _m("stroke")
	r = _feed(m, _strokes(4, 0.1, 0.3, 0.035))
	assert_has(r.said, ToolMotion.LINE)
	assert_has(r.verdicts, "almost")


func test_stroke_lifted_off_the_surface_does_nothing() -> void:
	var m := _m("stroke")
	var samples := []
	for s: Dictionary in _strokes(8, 0.1, 0.3):
		samples.append(_vr(s.at + Vector3(0, 0.1, 0)))
	_feed(m, samples)
	assert_eq(m.count, 0)


func test_stroke_flat_drag_back_and_forth() -> void:
	var m := _m("stroke", {"strokes": 4})
	var r := _feed(m, _strokes(6, 0.1, 0.3, 0.0, true))
	assert_true(r.done)


# --- Twist: the wrist turns while the tool touches -----------------------------------------------------------------

## The tool on the screw (pointing down into it), its side turning by `total` radians (positive: clockwise from above).
func _turning(total: float, steps: int = 72, align: Vector3 = Vector3.DOWN, at: Vector3 = Vector3(0, 0.0, 0)) -> Array:
	var out := []
	for i in steps + 1:
		var a := total * float(i) / steps
		out.append(_vr(at, {"axis": align, "side": Vector3(cos(a), 0, sin(a))}))
	return out


func test_twist_well_two_turns_the_right_way() -> void:
	var m := _m("twist")
	var r := _feed(m, _turning(TAU * 2.1, 200))
	assert_true(r.done)
	assert_gt(r.buzz, 3, "a little buzz every quarter turn")


func test_twist_badly_the_wrong_way_never_counts_and_says_so() -> void:
	var m := _m("twist")
	var r := _feed(m, _turning(-TAU * 2.0, 200))
	assert_false(r.done)
	assert_almost_eq(m.fraction(), 0.0, 0.001)
	assert_has(r.said, ToolMotion.OTHER_WAY)


func test_twist_almost_held_at_a_slant() -> void:
	var m := _m("twist")
	var r := _feed(m, _turning(TAU * 2.1, 200, Vector3(0.7, -0.7, 0).normalized()))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.STRAIGHT)


func test_twist_off_the_screw_does_nothing() -> void:
	var m := _m("twist")
	_feed(m, _turning(TAU * 2.1, 200, Vector3.DOWN, Vector3(0.2, 0, 0)))
	assert_almost_eq(m.fraction(), 0.0, 0.001)


func test_twist_loosen_is_the_other_way() -> void:
	var m := _m("twist", {"dir": -1, "turns": 1.0})
	assert_true(_feed(m, _turning(-TAU * 1.1, 120)).done, "a tap opens anticlockwise")


func test_twist_flat_a_circle_drawn_round_it() -> void:
	var m := _m("twist", {"turns": 1.0})
	var samples := []
	for i in 61:
		var a := TAU * 1.05 * i / 60.0
		samples.append(_finger(Vector3(cos(a) * 0.04, 0, sin(a) * 0.04), true))
	assert_true(_feed(m, samples).done)
	m = _m("twist", {"turns": 1.0})
	samples.clear()
	for i in 61:
		var a := -TAU * 1.05 * i / 60.0
		samples.append(_finger(Vector3(cos(a) * 0.04, 0, sin(a) * 0.04), true))
	var r := _feed(m, samples)
	assert_false(r.done)
	assert_has(r.said, ToolMotion.OTHER_WAY)


# --- Squeeze: the trigger held, the pressure in its pull -----------------------------------------------------------

func _squeeze(value: float, seconds: float) -> Array:
	var out := []
	for i in ceili(seconds / DT):
		out.append(_vr(Vector3.ZERO, {"trigger": value}))
	return out


func test_squeeze_well_held_firmly_long_enough() -> void:
	var m := _m("squeeze")
	assert_true(_feed(m, _squeeze(0.8, 1.6)).done)


func test_squeeze_badly_let_go_too_soon_starts_again() -> void:
	var m := _m("squeeze")
	var r := _feed(m, _squeeze(0.8, 1.0) + _squeeze(0.0, 0.2) + _squeeze(0.8, 1.0))
	assert_false(r.done, "a steady squeeze: letting go starts again")
	assert_has(r.said, ToolMotion.KEEP)


func test_squeeze_almost_too_light_or_too_hard() -> void:
	var m := _m("squeeze")
	var r := _feed(m, _squeeze(0.35, 2.0))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.HARDER_SQUEEZE)
	m = _m("squeeze", {"hi": 0.75})
	r = _feed(m, _squeeze(1.0, 2.0))
	assert_false(r.done, "a glue gun, gently")
	assert_has(r.said, ToolMotion.GENTLER)


func test_squeeze_flat_press_and_hold() -> void:
	var m := _m("squeeze", {"seconds": 1.0, "hi": 0.75})
	var samples := []
	for i in 80:
		samples.append(_finger(Vector3.ZERO, true))
	assert_true(_feed(m, samples).done, "a finger has no pressure: holding is squeezing")


# --- Press: pushed into the target, depth and rate -----------------------------------------------------------------

func _push(depth: float, x: float = 0.0, hold_frames: int = 4) -> Array:
	var out := []
	for i in 6:
		out.append(_vr(Vector3(x, 0.06 - 0.01 * i, 0)))
	for i in hold_frames:
		out.append(_vr(Vector3(x, -depth, 0)))
	for i in 6:
		out.append(_vr(Vector3(x, 0.01 * i, 0)))
	return out


func test_press_well_pushed_in_far_enough() -> void:
	var m := _m("press", {"presses": 2})
	assert_true(_feed(m, _push(0.015) + _push(0.02)).done)


func test_press_badly_beside_the_mark_never_counts() -> void:
	var m := _m("press")
	var r := _feed(m, _push(0.02, 0.3))
	assert_eq(m.count, 0)
	assert_eq(r.said, [])


func test_press_almost_not_far_enough_or_just_beside() -> void:
	var m := _m("press")
	var r := _feed(m, _push(0.005))
	assert_eq(m.count, 0)
	assert_has(r.said, ToolMotion.FURTHER)
	m = _m("press")
	r = _feed(m, _push(0.02, 0.08))
	assert_eq(m.count, 0)
	assert_has(r.said, ToolMotion.ON_MARK)


func test_press_and_hold_needs_its_seconds() -> void:
	var m := _m("press", {"seconds": 1.0})
	var r := _feed(m, _push(0.02, 0.0, 40))
	assert_false(r.done, "half a second is not enough")
	assert_has(r.said, ToolMotion.KEEP_PRESSING)
	assert_true(_feed(m, _push(0.02, 0.0, 80)).done)


func test_press_to_a_beat_counts_only_in_time() -> void:
	var m := _m("press", {"presses": 4, "rate_lo": 100.0, "rate_hi": 120.0})
	var slow := []
	for i in 6:
		slow.append_array(_push(0.02, 0.0, 4))
		slow.append_array(_idle(60, Vector3(0, 0.05, 0)))
	var r := _feed(m, slow)
	assert_false(r.done, "far too slow")
	assert_has(r.said, ToolMotion.FASTER)
	m = _m("press", {"presses": 4, "rate_lo": 100.0, "rate_hi": 120.0})
	var steady := []
	for i in 7:
		steady.append_array(_push(0.02, 0.0, 4))
		steady.append_array(_idle(23, Vector3(0, 0.05, 0)))   # 39 frames a push at 72 Hz: about 110 a minute
	assert_true(_feed(m, steady).done)


func test_press_flat_a_finger_on_it() -> void:
	var m := _m("press")
	assert_true(_feed(m, [_finger(Vector3.ZERO, true), _finger(Vector3.ZERO, false)]).done)


# --- Spread: a sweeping pass over a surface ------------------------------------------------------------------------

func _sweep(from_x: float, to_x: float, speed: float, y: float = 0.005, z: float = 0.0, flat: bool = false) -> Array:
	var out := []
	var x := from_x
	var dir := signf(to_x - from_x)
	while (to_x - x) * dir > 0.0:
		out.append(_finger(Vector3(x, 0, z), true) if flat else _vr(Vector3(x, y, z)))
		x += dir * speed * DT
	return out


func test_spread_well_an_even_layer_over_the_bed() -> void:
	var m := _m("spread", {"length": 0.9})
	var r := _feed(m, _sweep(0.0, 0.92, 0.5))
	assert_true(r.done)
	assert_almost_eq(m.fraction(), 1.0, 0.001)


func test_spread_badly_off_the_bricks_covers_nothing() -> void:
	var m := _m("spread", {"length": 0.9})
	var r := _feed(m, _sweep(0.0, 0.9, 0.5, 0.005, 0.3))
	assert_almost_eq(m.fraction(), 0.0, 0.001)
	assert_has(r.said, ToolMotion.ON_SURFACE)


func test_spread_almost_too_fast_or_too_high() -> void:
	var m := _m("spread", {"length": 0.9})
	var r := _feed(m, _sweep(0.0, 0.9, 3.0))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.SMOOTHER)
	m = _m("spread", {"length": 0.9})
	r = _feed(m, _sweep(0.0, 0.9, 0.5, 0.05))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.LOWER)


func test_spread_half_the_bed_is_half_done() -> void:
	var m := _m("spread", {"length": 0.9})
	_feed(m, _sweep(0.0, 0.45, 0.5))
	assert_between(m.fraction(), 0.4, 0.75)


func test_spread_flat_a_drag_over_the_surface() -> void:
	var m := _m("spread", {"length": 0.6})
	assert_true(_feed(m, _sweep(0.0, 0.62, 0.5, 0.0, 0.0, true)).done)


# --- Measure: from the start to the end, held there ----------------------------------------------------------------

func _tape(to_x: float, hook_at: Vector3 = Vector3.ZERO, hold: float = 1.0, flat: bool = false) -> Array:
	var out := []
	for i in 5:
		out.append(_finger(hook_at, true) if flat else _vr(hook_at))
	var x := hook_at.x
	while x < to_x:
		x = minf(x + 0.6 * DT, to_x)
		out.append(_finger(Vector3(x, 0, 0), true) if flat else _vr(Vector3(x, 0.0, 0)))
	for i in ceili(hold / DT):
		out.append(_finger(Vector3(to_x, 0, 0), true) if flat else _vr(Vector3(to_x, 0.0, 0)))
	return out


func test_measure_well_hooked_on_the_start_held_at_the_end() -> void:
	var m := _m("measure", {"length": 1.8})
	var r := _feed(m, _tape(1.8))
	assert_true(r.done)
	assert_almost_eq(m.reading, 1.8, 0.01, "the tape reads 1.80 m")


func test_measure_badly_never_hooked_on_the_start() -> void:
	var m := _m("measure", {"length": 1.8})
	var r := _feed(m, _tape(1.8, Vector3(0.5, 0, 0)))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.HOOK)


func test_measure_almost_short_of_the_end_or_past_it() -> void:
	var m := _m("measure", {"length": 1.8})
	var r := _feed(m, _tape(1.6, Vector3.ZERO, 1.5))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.FURTHER_TAPE)
	m = _m("measure", {"length": 1.8})
	r = _feed(m, _tape(2.0, Vector3.ZERO, 1.5))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.BACK)


func test_measure_flat_a_drag_from_start_to_end() -> void:
	var m := _m("measure", {"length": 1.0})
	assert_true(_feed(m, _tape(1.0, Vector3.ZERO, 1.0, true)).done)


# --- Pour: tilted over the target, the amount by the tilt and the time ---------------------------------------------

func _pour(tilt: float, seconds: float, at: Vector3 = Vector3(0, 0.15, 0)) -> Array:
	var out := []
	for i in ceili(seconds / DT):
		out.append(_vr(at, {"tilt": tilt}))
	for i in 3:
		out.append(_vr(at, {"tilt": 0.0}))
	return out


func test_pour_well_tilted_over_it_and_stopped_at_the_line() -> void:
	var m := _m("pour", {"want": 0.5, "tol": 0.08, "rate": 0.35})
	var r := _feed(m, _pour(1.3, 1.45))
	assert_true(r.done)
	assert_almost_eq(m.reading, 0.5, 0.08)


func test_pour_badly_beside_the_bucket_fills_nothing() -> void:
	var m := _m("pour")
	var r := _feed(m, _pour(1.3, 1.5, Vector3(0.4, 0.15, 0)))
	assert_false(r.done)
	assert_almost_eq(m.reading, 0.0, 0.001)
	assert_has(r.said, ToolMotion.OVER)


func test_pour_almost_too_little_or_too_much() -> void:
	var m := _m("pour", {"want": 0.5})
	var r := _feed(m, _pour(1.3, 0.5))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.MORE)
	m = _m("pour", {"want": 0.5})
	r = _feed(m, _pour(1.3, 2.5))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.TOO_MUCH)
	assert_lt(m.reading, 0.5, "a little goes back: try again")


func test_pour_a_small_tilt_pours_nothing() -> void:
	var m := _m("pour")
	_feed(m, _pour(0.3, 2.0))
	assert_almost_eq(m.reading, 0.0, 0.001)


func test_pour_flat_hold_and_let_go() -> void:
	var m := _m("pour", {"want": 0.4, "tol": 0.1, "rate": 0.4})
	var samples := []
	for i in ceili(1.7 / DT):
		samples.append(_finger(Vector3.ZERO, true))
	samples.append(_finger(Vector3.ZERO, false))
	assert_true(_feed(m, samples).done)


# --- Aim: held still and pointed -----------------------------------------------------------------------------------

func _hold(axis: Vector3, seconds: float, at: Vector3 = Vector3(0, 0.01, 0), wobble: float = 0.0) -> Array:
	var out := []
	for i in ceili(seconds / DT):
		var w := Vector3(0, 0, wobble * sin(i * 0.9))
		out.append(_vr(at + w, {"axis": axis}))
	return out


func test_aim_well_held_still_and_true() -> void:
	var m := _m("aim", {"dir": [1, 0, 0]})
	assert_true(_feed(m, _hold(Vector3(1, 0.02, 0).normalized(), 1.2)).done)


func test_aim_badly_pointed_the_wrong_way_never_counts() -> void:
	var m := _m("aim", {"dir": [1, 0, 0]})
	var r := _feed(m, _hold(Vector3(0, 0, 1), 2.0))
	assert_false(r.done)
	assert_eq(r.said, [], "far off is not trying yet")


func test_aim_almost_a_little_off_or_shaking() -> void:
	var m := _m("aim", {"dir": [1, 0, 0]})
	var r := _feed(m, _hold(Vector3(1, 0.12, 0).normalized(), 2.0))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.NEARLY)
	m = _m("aim", {"dir": [1, 0, 0]})
	r = _feed(m, _hold(Vector3(1, 0, 0), 2.0, Vector3(0, 0.01, 0), 0.03))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.STILL)


func test_aim_either_way_round_for_a_spirit_level() -> void:
	var m := _m("aim", {"dir": [1, 0, 0], "either": true})
	assert_true(_feed(m, _hold(Vector3(-1, 0, 0), 1.2)).done)


func test_aim_on_a_surface_only_when_it_touches() -> void:
	var m := _m("aim", {"dir": [1, 0, 0], "touch": true})
	assert_false(_feed(m, _hold(Vector3(1, 0, 0), 1.5, Vector3(0, 0.2, 0))).done, "held in the air: not on the bricks")
	assert_true(_feed(m, _hold(Vector3(1, 0, 0), 1.5)).done)


func test_aim_flat_point_and_hold() -> void:
	var m := _m("aim", {"hold": 0.5})
	var samples := []
	for i in 40:
		samples.append(_finger(Vector3.ZERO, true))
	assert_true(_feed(m, samples).done)


# --- Cut: along a line, slowly, fingers back ------------------------------------------------------------------------

func _cut(to_x: float, speed: float, z: float = 0.0, other: Vector3 = Vector3.INF, flat: bool = false) -> Array:
	var out := []
	var x := 0.0
	while x < to_x:
		var extra := {} if not other.is_finite() else {"other": other}
		out.append(_finger(Vector3(x, 0, z), true, extra) if flat else _vr(Vector3(x, 0.0, z), extra))
		x += speed * DT
	out.append(_vr(Vector3(to_x, 0.0, z)) if not flat else _finger(Vector3(to_x, 0, z), true))
	return out


func test_cut_well_slowly_along_the_line() -> void:
	var m := _m("cut", {"length": 0.2})
	assert_true(_feed(m, _cut(0.21, 0.15)).done)


func test_cut_badly_fingers_in_front_of_the_blade() -> void:
	var m := _m("cut", {"length": 0.2})
	var r := _feed(m, _cut(0.21, 0.15, 0.0, Vector3(0.15, 0.01, 0.0)))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.CLAW)
	assert_has(r.verdicts, "bad")


func test_cut_almost_too_fast_or_off_the_line() -> void:
	var m := _m("cut", {"length": 0.2})
	var r := _feed(m, _cut(0.21, 1.5))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.SLOWLY)
	m = _m("cut", {"length": 0.2})
	r = _feed(m, _cut(0.21, 0.15, 0.03))
	assert_false(r.done)
	assert_has(r.said, ToolMotion.FOLLOW)


func test_cut_flat_a_drag_along_the_line() -> void:
	var m := _m("cut", {"length": 0.2})
	assert_true(_feed(m, _cut(0.21, 0.15, 0.0, Vector3.INF, true)).done)


# --- Words: kind, about the action, never too often ----------------------------------------------------------------

func test_the_same_word_is_said_at_most_every_few_seconds() -> void:
	var m := _m("strike")
	var r := _feed(m, _swing(0.6) + _swing(0.6) + _swing(0.6))
	assert_eq(r.said.size(), 1, "once, not three times in a second")


func test_every_word_is_kind_and_short() -> void:
	for w: String in ToolMotion.WORDS:
		assert_lte(w.length(), 70, w)
		for bad: String in ["wrong", "bad", "no!", "fail", "stupid"]:
			assert_false(w.to_lower().contains(bad), w)
