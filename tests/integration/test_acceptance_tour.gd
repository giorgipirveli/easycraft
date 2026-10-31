extends GutTest
## The acceptance tour's runner (tools/tour.gd) with fake checks, no sandbox: one line per check,
## then the summary; a check that never ends is timed out and the tour goes on; the waits of an
## abandoned check end at once and its late result is ignored; a shot is announced and held.

signal never_emitted

var tour: AcceptanceTour
var done: Array = []


func before_each() -> void:
	done = []
	tour = AcceptanceTour.new()
	tour.warmup = 0.0
	tour.shot_hold = 0.1
	tour.on_done = func(passed: int, failed: int) -> void: done.append([passed, failed])


func _start(checks: Array[Dictionary]) -> void:
	tour.checks = checks
	add_child_autofree(tour)
	await wait_until(func() -> bool: return not done.is_empty(), 5.0, "the tour ends")


func _check(check_name: StringName, limit: float, run: Callable) -> Dictionary:
	return {"name": check_name, "limit": limit, "run": run}


func test_each_check_prints_one_line_then_the_summary() -> void:
	await _start([
		_check(&"one", 5.0, func(_g: int) -> Array: return [true, "fine"]),
		_check(&"two", 5.0, func(_g: int) -> Array: return [false, "broken"]),
	])
	assert_eq(tour.lines, ["TOUR one PASS fine", "TOUR two FAIL broken", "TOUR done passed=1 failed=1"])
	assert_eq(done, [[1, 1]])


func test_a_skipped_check_is_not_counted() -> void:
	await _start([_check(&"later", 5.0, func(_g: int) -> Array: return [null, "measured separately"])])
	assert_eq(tour.lines, ["TOUR later SKIP measured separately", "TOUR done passed=0 failed=0"])


func test_a_check_that_never_ends_times_out_and_the_tour_goes_on() -> void:
	await _start([
		_check(&"stuck", 0.3, func(_g: int) -> Array:
			await never_emitted
			return [true, "unreachable"]),
		_check(&"after", 5.0, func(_g: int) -> Array: return [true, "ran"]),
	])
	assert_eq(tour.lines.size(), 3)
	assert_string_starts_with(tour.lines[0], "TOUR stuck FAIL timeout after 0.3 s")
	assert_eq(tour.lines[1], "TOUR after PASS ran")
	assert_eq(tour.lines[2], "TOUR done passed=1 failed=1")


func test_a_timeout_names_the_step_the_check_was_at() -> void:
	await _start([_check(&"stuck", 0.2, func(_g: int) -> Array:
		tour.note("digging at y=-12")
		await never_emitted
		return [true, ""])])
	assert_eq(tour.lines[0], "TOUR stuck FAIL timeout after 0.2 s at: digging at y=-12")


func test_the_waits_of_an_abandoned_check_end_at_once_and_its_result_is_ignored() -> void:
	var finished: Array = []
	await _start([_check(&"slow", 0.2, func(g: int) -> Array:
		var ok: bool = await tour.wait_seconds(10.0, g)
		finished.append(ok)
		return [true, "late"])])
	await wait_until(func() -> bool: return not finished.is_empty(), 1.0, "the abandoned wait returns")
	assert_eq(finished, [false])
	assert_false(tour.lines.has("TOUR slow PASS late"))
	assert_eq(tour.lines.back(), "TOUR done passed=0 failed=1")


func test_wait_until_true_reports_the_condition() -> void:
	var seen: Array = []
	await _start([_check(&"cond", 5.0, func(g: int) -> Array:
		var t0 := Time.get_ticks_msec()
		seen.append(await tour.wait_until_true(func() -> bool: return Time.get_ticks_msec() - t0 > 100, 2.0, g))
		seen.append(await tour.wait_until_true(func() -> bool: return false, 0.1, g))
		return [true, ""])])
	assert_eq(seen, [true, false])


## On a crowded emulator one frame can take longer than a wait's whole budget (a shader compile,
## chunk meshing): the M1b tour failed its underwater, animals and avatar checks at load 30 after
## seeing a single frame. A wait gives up only after its time AND MIN_WAIT_FRAMES frames.
func test_a_wait_never_gives_up_before_its_minimum_frames() -> void:
	var seen: Array = []
	var calls := [0]
	await _start([_check(&"slow", 5.0, func(g: int) -> Array:
		seen.append(await tour.wait_until_true(func() -> bool:
			calls[0] += 1
			return calls[0] > AcceptanceTour.MIN_WAIT_FRAMES - 2, 0.0, g))
		return [true, ""])])
	assert_eq(seen, [true], "a condition true within the minimum frames is seen, whatever the clock says")
	assert_gt(AcceptanceTour.MIN_WAIT_FRAMES, 5)


func test_a_shot_is_announced_and_held() -> void:
	await _start([_check(&"pic", 5.0, func(g: int) -> Array:
		var t0 := Time.get_ticks_msec()
		await tour.shot("pic", g)
		return [true, str(Time.get_ticks_msec() - t0)])])
	assert_eq(tour.lines[0], "TOUR_SHOT pic")
	assert_string_starts_with(tour.lines[1], "TOUR pic PASS ")
	assert_gte(int(tour.lines[1].get_slice(" ", 3)), 90, "held for shot_hold")


## M2 Task 12: the Survivor tour (tools/tour_survivor.gd) runs a method for every M2 check it lists, and
## a Survivor world starts it instead of the Sandbox tour.
func test_the_survivor_tour_has_a_method_for_every_m2_check() -> void:
	var t := SurvivorTour.new()
	for c: Array in SurvivorTour.M2_CHECKS:
		assert_true(t.has_method("_check_" + String(c[0])), String(c[0]))
		assert_gt(float(c[1]), 0.0, "a time limit")
	assert_true(t is AcceptanceTour, "the same runner")
	t.free()


func test_a_survivor_world_gets_the_survivor_tour() -> void:
	assert_eq(AcceptanceTour.script_for(ModeRules.SURVIVOR), "res://tools/tour_survivor.gd")
	assert_eq(AcceptanceTour.script_for(ModeRules.SANDBOX), "res://tools/tour.gd")
