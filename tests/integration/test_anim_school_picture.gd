extends GutTest
## Owner #94 (docs/superpowers/plans/2026-09-30-animations-brief.md §4): the School's pictures that teach motion move.
## A SchoolPicture has a `time` (seconds) its moving kinds draw and a `playing` flag that advances it by itself
## (SchoolPictureMotion.moves says which kinds move, and when). Still kinds ignore both: they draw once, as before. At
## time 0 a moving kind is exactly its still picture. The School plays a lesson card's picture, keeps an exercise's still
## (motion could show the answer) unless its data says "animate": true, and keeps every picture still with Reduce
## motion. New kinds made for motion: the water cycle, the Moon's phases, orbits, a pendulum and a rocket's stages.

const MOVING: Array[Dictionary] = [
	{"kind": "gears", "gears": [10, 30], "turn": "cw", "marks": true},
	{"kind": "gears", "gears": [20, 10, 20, 40], "turn": "acw", "arrows": "all"},
	{"kind": "pulleys", "sizes": [2, 6], "turn": "cw"},
	{"kind": "cam", "shape": "snail", "turn": 200, "graph": true},
	{"kind": "food_web", "nodes": [["grass", 0, 3], ["rabbit", 0, 2], ["fox", 1, 1]], "links": [[0, 1], [1, 2]]},
	{"kind": "lever", "pivot": 5, "load": 1, "effort": 9},
	{"kind": "circuit", "parts": ["cell", "bulb", "switch", "motor"], "lit": true},
	{"kind": "wave", "waves": [{"count": 2, "amp": 2}, {"count": 4, "amp": 2}]},
	{"kind": "water_cycle"},
	{"kind": "water_cycle", "hide": "condensation", "sun": false},
	{"kind": "moon_phases"},
	{"kind": "moon_phases", "show": "row", "names": true, "hide": 2},
	{"kind": "moon_phases", "phase": 4, "names": true},
	{"kind": "orbit"},
	{"kind": "orbit", "planets": ["Mercury", "Venus", "Earth", "Mars"], "moon": true, "labels": true, "arrows": true},
	{"kind": "orbit", "centre": "earth", "arrows": true, "labels": true},
	{"kind": "pendulum"},
	{"kind": "pendulum", "lengths": [1, 3], "swing": 20, "labels": true},
	{"kind": "pendulum", "energy": true, "labels": true},
	{"kind": "rocket_stages"},
	{"kind": "rocket_stages", "stages": 2, "step": 1, "labels": true},
]
## Still: kinds that never move, and moving kinds whose data keeps them still.
const STILL: Array[Dictionary] = [
	{"kind": "table", "rows": [["km", "m"], ["1", "1,000"]]},
	{"kind": "clock", "h": 3, "m": 15},
	{"kind": "blocks", "thousands": 1, "hundreds": 3, "tens": 4, "ones": 7},
	{"kind": "gears", "gears": [10, 30], "turn": "cw", "animate": false},
	{"kind": "pulleys", "lift": 2},
	{"kind": "lever", "pivot": 2, "load": 5, "effort": 9},       # the load between: the arrow would push it the wrong way
	{"kind": "circuit", "parts": ["cell", "bulb", "switch"], "switch": "open"},
	{"kind": "circuit", "parts": ["cell", "bulb"]},              # not lit: nothing says it works
	{"kind": "wave", "waves": [{"count": 2, "amp": 3}], "labels": ["crest", "trough", "wavelength", "amplitude"]},
	{"kind": "pendulum", "animate": false},
]
const SIZES: Array[Vector2] = [Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]

var _reduce := false


class TimedPicture extends SchoolPicture:
	var draws := 0
	var usec := 0

	func _draw() -> void:
		var t0 := Time.get_ticks_usec()
		super()
		usec += Time.get_ticks_usec() - t0
		draws += 1


func before_each() -> void:
	_reduce = bool(Profile.data.settings.get("reduce_motion", false))
	Profile.data.settings.reduce_motion = false


func after_each() -> void:
	Profile.data.settings.reduce_motion = _reduce


func _picture(d: Dictionary, px: Vector2 = Vector2(560, 380)) -> TimedPicture:
	var p := TimedPicture.new(d, px)
	p.size = px
	add_child_autofree(p)
	return p


func test_the_samples_are_valid_and_move_or_stay_still() -> void:
	for d in MOVING:
		assert_eq(SchoolPicture.problem(d), "", str(d))
		assert_true(SchoolPicture.animates(d), "moves: %s" % d)
	for d in STILL:
		assert_eq(SchoolPicture.problem(d), "", str(d))
		assert_false(SchoolPicture.animates(d), "still: %s" % d)
	assert_false(SchoolPicture.animates({"kind": "gears"}), "broken data never moves")
	assert_ne(SchoolPicture.problem({"kind": "gears", "gears": [10, 30], "animate": "yes"}), "", "animate is a bool")


func test_every_new_kind_has_a_sample() -> void:
	var seen := {}
	for d in MOVING:
		seen[str(d.kind)] = true
	for k: String in SchoolPictureMotion.KINDS:
		assert_true(seen.has(k), "a sample of %s" % k)


func test_a_picture_has_a_time_and_a_playing_flag() -> void:
	var p := SchoolPicture.new(MOVING[0])
	assert_eq(p.time, 0.0)
	assert_false(p.playing, "still until someone plays it")
	p.time = 1.5
	assert_eq(p.time, 1.5)
	assert_eq(SchoolPicture.time_of(p), 1.5)
	var still := SchoolPicture.new(STILL[3])
	still.time = 1.5
	assert_eq(SchoolPicture.time_of(still), 0.0, "\"animate\": false draws its still picture whatever the time")
	assert_eq(SchoolPicture.time_of(Control.new()), 0.0, "anything else draws at time 0")
	p.free()
	still.free()


func test_a_still_kind_draws_once_whatever_the_time() -> void:
	var pics: Array[TimedPicture] = []
	for d in STILL:
		pics.append(_picture(d))
	await wait_process_frames(2)
	for p in pics:
		assert_eq(p.draws, 1, "drawn once: %s" % p.data)
		p.playing = true
		p.time = 3.7
		assert_false(p.is_processing(), "a still picture never ticks: %s" % p.data)
	await wait_process_frames(4)
	for p in pics:
		assert_eq(p.draws, 1, "the same drawing with or without time: %s" % p.data)


func test_every_still_kind_in_the_lessons_draws_once_with_time() -> void:
	var one_each := {}
	for d: Dictionary in _lesson_pictures():
		if not SchoolPicture.animates(d) and not one_each.has(str(d.kind)):
			one_each[str(d.kind)] = d
	assert_gt(one_each.size(), 100, "the lessons' still kinds")
	var pics: Array[TimedPicture] = []
	for k: String in one_each:
		var p := _picture(one_each[k], Vector2(480, 280))
		p.playing = true
		pics.append(p)
	await wait_process_frames(2)
	for p in pics:
		p.time = 2.0
	await wait_process_frames(3)
	for p in pics:
		assert_eq(p.draws, 1, "%s draws the same with or without time" % p.data.kind)


func test_a_moving_kind_moves_while_it_plays_and_stops_when_it_stops() -> void:
	var p := _picture(MOVING[0])
	await wait_process_frames(2)
	var first := p.draws
	p.playing = true
	assert_true(p.is_processing())
	var t0 := Time.get_ticks_msec()
	await wait_seconds(0.4)
	var seconds := (Time.get_ticks_msec() - t0) / 1000.0
	assert_gt(p.time, 0.2, "its clock runs")
	assert_gt(p.draws, first + 1, "it redraws as it moves")
	assert_lte(p.draws, first + ceili(seconds * SchoolPicture.FPS) + 2, "at most %d times a second" % SchoolPicture.FPS)
	p.playing = false
	var at := p.time
	var drawn := p.draws
	await wait_process_frames(4)
	assert_eq(p.time, at, "stopped")
	assert_eq(p.draws, drawn)
	p.time = 5.0
	await wait_process_frames(1)
	assert_eq(p.draws, drawn + 1, "a new time is drawn once (a Short can drive it)")


func test_a_hidden_picture_does_not_redraw() -> void:
	var p := _picture(MOVING[0])
	p.playing = true
	await wait_process_frames(2)
	p.visible = false
	var drawn := p.draws
	await wait_seconds(0.2)
	assert_eq(p.draws, drawn, "nobody sees it")


func test_the_school_plays_lessons_and_keeps_questions_still() -> void:
	var gears: Dictionary = MOVING[0]
	assert_true(SchoolPicture.should_play(gears, false), "a lesson card's picture moves")
	assert_false(SchoolPicture.should_play(gears, true), "an exercise's picture is the question: still")
	var asked := gears.duplicate()
	asked["animate"] = true
	assert_true(SchoolPicture.should_play(asked, true), "unless the exercise asks for motion")
	assert_false(SchoolPicture.should_play(STILL[0], false), "a still kind never plays")
	Profile.data.settings.reduce_motion = true
	assert_false(SchoolPicture.should_play(gears, false), "Reduce motion keeps every picture still")
	assert_false(SchoolPicture.should_play(asked, true))


func test_the_school_screens_follow_the_rule() -> void:
	var unit := "g4.maths.big_numbers"
	var gears: Dictionary = MOVING[0]
	Curriculum.clear_cache()
	Curriculum.put_content(unit, {"id": unit, "lesson": [{"text": "Gears turn.", "picture": gears}], "exercises": [
		{"type": "truefalse", "prompt": "Does B turn anticlockwise?", "answer": true, "hint": "Opposite.", "level": 1,
			"picture": gears}], "generators": []})
	var profile := ProfileData.new()
	profile.school.grade = 4
	var screen := SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: pass
	add_child_autofree(screen)
	await wait_process_frames(2)
	screen.show_lesson(unit)
	await wait_process_frames(2)
	var pics := screen.find_children("*", "SchoolPicture", true, false)
	assert_eq(pics.size(), 1, "the lesson card's picture")
	assert_true((pics[0] as SchoolPicture).playing, "a lesson card's gears turn")
	var panel := ExercisePanel.new(Curriculum.content(unit).exercises[0])
	add_child_autofree(panel)
	assert_not_null(panel.picture)
	assert_false(panel.picture.playing, "the question's gears hold still")
	Curriculum.clear_cache()


func test_at_time_zero_a_moving_kind_is_its_still_picture() -> void:
	assert_eq(SchoolPictureMotion.gear_spin([10, 30], 0, "cw", 0.0), 0.0)
	assert_eq(SchoolPictureMotion.gear_spin([10, 30], 1, "cw", 0.0), 0.0)
	assert_eq(SchoolPictureMotion.pulley_spin([2, 6], 1, "cw", false, 0.0), 0.0)
	assert_eq(SchoolPictureMotion.cam_turn({"kind": "cam", "shape": "pear", "turn": 90}, 0.0), 90.0)
	assert_eq(SchoolPictureMotion.lever_tilt({"kind": "lever", "pivot": 5, "load": 1, "effort": 9}, 0.0), 0.0)
	assert_eq(SchoolPictureMotion.wave_phase(3, 0.0), 0.0)
	assert_eq(SchoolPicture.wave_line(Rect2(0, 0, 200, 80), 30.0, 2, SchoolPictureMotion.wave_phase(2, 0.0)),
		SchoolPicture.wave_line(Rect2(0, 0, 200, 80), 30.0, 2), "the wave's still line")
	assert_eq(SchoolPictureMotion.moon_month({"kind": "moon_phases", "phase": 4}, 0.0), 0.5, "the still phase")
	assert_eq(SchoolPictureMotion.pendulum_angle(2, 30.0, 0.0), deg_to_rad(30.0), "at the end of its swing")
	var still := SchoolPictureMotion.rocket_state(3, 1, 0.0)
	assert_eq(int(still.dropped), 1, "the still picture's stages")
	assert_eq(float(still.since), 99.0, "nothing falling in the still picture")


## The rules the moving pictures follow, which the lessons teach.
func test_the_motion_follows_the_rules_it_teaches() -> void:
	var t := 1.3
	var a := SchoolPictureMotion.gear_spin([10, 30], 0, "cw", t)
	var b := SchoolPictureMotion.gear_spin([10, 30], 1, "cw", t)
	assert_gt(a, 0.0, "cw turns clockwise on the page")
	assert_lt(b, 0.0, "meshing gears turn opposite ways")
	assert_almost_eq(absf(a / b), 3.0, 0.0001, "the small gear turns 3 times for the big one's once")
	assert_almost_eq(SchoolPictureMotion.gear_spin([10, 30, 10], 2, "cw", t), a, 0.0001, "an idler: the same way")
	assert_lt(SchoolPictureMotion.pulley_spin([2, 6], 1, "cw", true, t), 0.0, "a crossed belt turns it back")
	assert_almost_eq(SchoolPictureMotion.pulley_spin([2, 6], 0, "cw", false, t)
		/ SchoolPictureMotion.pulley_spin([2, 6], 1, "cw", false, t), 3.0, 0.0001, "the small wheel turns faster")
	var lever := {"kind": "lever", "pivot": 5, "load": 1, "effort": 9}
	assert_gt(SchoolPictureMotion.lever_tilt(lever, SchoolPictureMotion.LEVER_CYCLE * 0.5), 0.0,
		"the effort (right) goes down, the load (left) up")
	lever = {"kind": "lever", "pivot": 5, "load": 9, "effort": 1}
	assert_lt(SchoolPictureMotion.lever_tilt(lever, SchoolPictureMotion.LEVER_CYCLE * 0.5), 0.0, "and the other way")
	assert_almost_eq(SchoolPictureMotion.pendulum_period(4) / SchoolPictureMotion.pendulum_period(1), 2.0, 0.0001,
		"four times as long swings half as fast")
	var p1 := SchoolPictureMotion.pendulum_period(1)
	assert_almost_eq(SchoolPictureMotion.pendulum_angle(1, 30.0, p1 * 0.5), -deg_to_rad(30.0), 0.0001,
		"half a swing later: the other end")
	for i in 3:
		assert_lt(SchoolPictureMotion.ORBIT_PERIODS[i], SchoolPictureMotion.ORBIT_PERIODS[i + 1],
			"a planet nearer the Sun goes round faster")
	assert_eq(SchoolPictureMotion.PHASES.size(), 8)
	assert_eq(SchoolPictureMotion.phase_index(0.0), 0)
	assert_eq(SchoolPictureMotion.phase_index(0.5), 4, "half a month: full moon")
	assert_eq(SchoolPictureMotion.phase_index(0.99), 0, "back to new")
	assert_eq(SchoolPictureMotion.PHASES[4], "full moon")
	var last_dropped := 0
	for i in 60:
		var s := SchoolPictureMotion.rocket_state(3, 0, i * 0.15)
		assert_true(int(s.dropped) >= last_dropped or int(s.dropped) == 0, "stages drop in order (then again)")
		assert_lte(int(s.dropped), 2, "the top stage (the capsule's) never drops")
		last_dropped = int(s.dropped)
	assert_eq(SchoolPictureMotion.circuit_way(["cell", "bulb"]), 1, "current leaves the cell's + end: clockwise")
	assert_eq(SchoolPictureMotion.circuit_way(["bulb", "motor", "switch", "cell"]), 1, "on the left edge too")
	assert_eq(SchoolPictureMotion.circuit_way(["bulb", "switch", "cell"]), -1,
		"a cell on the bottom edge points its + end the other way")


func test_every_moving_sample_draws_at_every_size_and_every_moment() -> void:
	for px in SIZES:
		for d in MOVING:
			var p := _picture(d, px)
			p.time = 7.3
	await wait_process_frames(2)
	for px in SIZES:
		for d in MOVING:
			var p := _picture(d, px)
			p.time = 0.4
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


func test_drawing_a_moving_picture_is_cheap() -> void:
	var worst := 0.0
	var worst_kind := ""
	for d in MOVING:
		var p := _picture(d)
		await wait_process_frames(1)
		p.usec = 0
		p.draws = 0
		for i in 12:
			p.time = 0.1 * i
			await wait_process_frames(1)
		var per := p.usec / float(maxi(p.draws, 1))
		if per > worst:
			worst = per
			worst_kind = str(d)
		gut.p("MEASURE picture %s %.0f us per draw" % [d.kind, per])
	gut.p("MEASURE the dearest moving picture: %.0f us per draw (%s)" % [worst, worst_kind])
	assert_lt(worst, 2500.0, "a moving picture's draw stays small at %d a second (phones: 3-5x)" % SchoolPicture.FPS)


func test_new_kinds_with_broken_data_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "water_cycle", "hide": "rain"}, {"kind": "water_cycle", "labels": "yes"},
			{"kind": "moon_phases", "show": "grid"}, {"kind": "moon_phases", "phase": 8},
			{"kind": "moon_phases", "phase": 1.5}, {"kind": "moon_phases", "hide": 2},
			{"kind": "moon_phases", "show": "row", "hide": 9},
			{"kind": "orbit", "centre": "moon"}, {"kind": "orbit", "planets": 5}, {"kind": "orbit", "planets": 0},
			{"kind": "orbit", "centre": "earth", "planets": ["Earth"]}, {"kind": "orbit", "arrows": 1},
			{"kind": "orbit", "planets": ["Pluto"]}, {"kind": "orbit", "planets": ["Earth", "Earth"]},
			{"kind": "orbit", "planets": ["Mars"], "moon": true},
			{"kind": "pendulum", "lengths": []}, {"kind": "pendulum", "lengths": [1, 2, 3, 4]},
			{"kind": "pendulum", "lengths": [5]}, {"kind": "pendulum", "swing": 60},
			{"kind": "pendulum", "lengths": [1, 2], "energy": true},
			{"kind": "rocket_stages", "stages": 4}, {"kind": "rocket_stages", "stages": 2, "step": 2},
			{"kind": "rocket_stages", "labels": "no"},
	]:
		assert_ne(SchoolPicture.problem(d), "", "a problem: %s" % d)


func _lesson_pictures() -> Array:
	var out: Array = []
	_scan("res://data/school", out)
	return out


func _scan(dir: String, out: Array) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(sub), out)
	for f: String in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			_collect(JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f))), out)


func _collect(v: Variant, out: Array) -> void:
	if v is Dictionary:
		var d: Dictionary = v
		if d.get("picture") is Dictionary and SchoolPicture.problem(d.picture) == "":
			out.append(d.picture)
		for k: Variant in d:
			_collect(d[k], out)
	elif v is Array:
		for x: Variant in v:
			_collect(x, out)
