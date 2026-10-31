extends GutTest
## Owner #70, #73 and #111, grade 8 health and PE, D&T and projects (research §6.8): the School draws their pictures
## from data (SchoolPictureG8Life, inside SchoolPicture): a fitness profile as a spider chart (and its retest), how
## pressure and anxiety change (the best zone; staying until anxiety falls), a prize wheel and its key, CPR's straight
## arms and stacked hands, a defibrillator's pads and the machine itself, a making plan as a Gantt chart, smart materials
## before and after their trigger (and a composite's layers), a compound gear train, a block and tackle, big structures
## (a tuned mass damper, base isolation, suspension and cable-stayed bridges) and the circular economy's loops. Every
## sample draws at the School's picture sizes; broken data is a problem the content test finds; the rules the pictures
## draw by (a train's ratio and turns, a tackle's effort, a wheel's chances and expected win, a plan's end, the weakest
## part, the pressure zones) are checked here, and every labelled part has its place.

const SAMPLES: Array[Dictionary] = [
	{"kind": "fitness_profile", "parts": [["stamina", 3], ["strength", 4], ["speed", 2], ["flexibility", 5],
		["agility", 3], ["balance", 4]], "top": 5, "title": "Mo's profile"},
	{"kind": "fitness_profile", "parts": [["stamina", 6], ["strength", 4], ["speed", 7], ["power", 5]], "top": 10,
		"after": [8, 5, 7, 6], "mark": 0},
	{"kind": "fitness_profile", "parts": [["a", 1], ["b", 3], ["c", 0]], "top": 3},
	{"kind": "feeling_curve", "view": "pressure"},
	{"kind": "feeling_curve", "view": "pressure", "point": 0.85, "mark": "too much"},
	{"kind": "feeling_curve", "view": "pressure", "labels": true, "hide": "best zone"},
	{"kind": "feeling_curve", "view": "stay"},
	{"kind": "feeling_curve", "view": "stay", "labels": true, "mark": "the peak"},
	{"kind": "feeling_curve", "view": "stay", "words": false},
	{"kind": "chance_wheel", "slices": [["5 gold", 1, 5], ["nothing", 9, 0]], "cost": 1},
	{"kind": "chance_wheel", "slices": [["rare", 1, 50], ["common", 15, 0], ["2 gold", 4, 2]], "cost": 2, "pointer": 0,
		"mark": 2},
	{"kind": "chance_wheel", "slices": [["a", 4], ["b", 4], ["c", 4], ["d", 4], ["e", 4], ["f", 4]], "hide": 3},
	{"kind": "cpr_aed", "view": "hands"},
	{"kind": "cpr_aed", "view": "hands", "labels": true, "mark": "straight arms"},
	{"kind": "cpr_aed", "view": "hands", "pins": true},
	{"kind": "cpr_aed", "view": "pads", "labels": true},
	{"kind": "cpr_aed", "view": "pads", "pins": true, "mark": "side pad"},
	{"kind": "cpr_aed", "view": "machine", "labels": true, "hide": "shock button"},
	{"kind": "cpr_aed", "view": "machine"},
	{"kind": "making_plan", "tasks": [["research", 0, 2], ["sketch ideas", 1, 2], ["make a model", 3, 2],
		["cut the parts", 5, 3], ["put together", 8, 2], ["test, evaluate", 10, 2]], "columns": 12, "today": 4},
	{"kind": "making_plan", "tasks": [["a", 0, 1], ["b", 1, 3]], "columns": 4, "unit": "week", "mark": 1},
	{"kind": "making_plan", "tasks": [["mark out", 0, 1], ["cut", 1, 2], ["sand", 3, 1], ["paint", 4, 2],
		["dry", 6, 1], ["varnish", 7, 1], ["check", 8, 1]], "columns": 16, "hide": 3},
	{"kind": "smart_material", "material": "shape_memory"},
	{"kind": "smart_material", "material": "thermochromic", "mark": "hot colour"},
	{"kind": "smart_material", "material": "photochromic", "labels": true},
	{"kind": "smart_material", "material": "piezoelectric", "hide": "spark"},
	{"kind": "smart_material", "material": "hydrogel"},
	{"kind": "smart_material", "material": "composite", "labels": true},
	{"kind": "smart_material", "material": "composite", "pins": true},
	{"kind": "gear_train", "stages": [[10, 40]], "rpm": 200, "out": "?", "turn": "cw", "arrows": true},
	{"kind": "gear_train", "stages": [[10, 40], [15, 30]], "rpm": 400, "out": "50 rpm", "labels": true},
	{"kind": "gear_train", "stages": [[8, 60], [12, 48], [20, 20]], "arrows": true, "hide": 3, "turn": "acw"},
	{"kind": "gear_train", "stages": [[40, 10]], "values": false},
	{"kind": "block_tackle", "ropes": 1, "load": 200, "effort": 200, "labels": true},
	{"kind": "block_tackle", "ropes": 2, "load": 400, "effort": "?", "count": true},
	{"kind": "block_tackle", "ropes": 4, "load": 800, "labels": true, "count": true},
	{"kind": "block_tackle", "ropes": 6},
	{"kind": "tall_structure", "type": "damper"},
	{"kind": "tall_structure", "type": "damper", "labels": true, "mark": "tuned mass damper"},
	{"kind": "tall_structure", "type": "isolation", "labels": true},
	{"kind": "tall_structure", "type": "isolation", "pins": true},
	{"kind": "tall_structure", "type": "suspension", "labels": true, "hide": "hangers"},
	{"kind": "tall_structure", "type": "suspension"},
	{"kind": "tall_structure", "type": "cable_stayed", "labels": true},
	{"kind": "circular_loop"},
	{"kind": "circular_loop", "mark": "maintain", "hide": "recycle"},
	{"kind": "circular_loop", "side": "technical", "labels": true},
	{"kind": "circular_loop", "side": "biological"},
	{"kind": "circular_loop", "pins": true, "words": false},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126),
	Vector2(520, 250)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_view_material_and_type_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG8Life.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	for pair: Array in [["feeling_curve", "view", SchoolPictureG8Life.FEEL_VIEWS], ["cpr_aed", "view",
			SchoolPictureG8Life.CPR_VIEWS], ["smart_material", "material", SchoolPictureG8Life.SMART], ["tall_structure",
			"type", SchoolPictureG8Life.STRUCTURES]]:
		for v: String in pair[2]:
			assert_true(SAMPLES.any(func(d: Dictionary) -> bool: return d.kind == pair[0] and str(d.get(pair[1])) == v),
				"a %s %s" % [v, pair[0]])


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "fitness_profile", "parts": [["a", 1], ["b", 2]], "top": 5},
			{"kind": "fitness_profile", "parts": [["a", 1], ["b", 2], ["c", 6]], "top": 5},
			{"kind": "fitness_profile", "parts": [["a", 1], ["b", 2], ["c", 3]], "top": 12},
			{"kind": "fitness_profile", "parts": [["a", 1], ["b", 2], ["c", 3]], "top": 5, "after": [1, 2]},
			{"kind": "fitness_profile", "parts": [["a name too long", 1], ["b", 2], ["c", 3]], "top": 5},
			{"kind": "fitness_profile", "parts": [["a", 1], ["b", 2], ["c", 3]], "top": 5, "mark": 3},
			{"kind": "feeling_curve", "view": "fear"}, {"kind": "feeling_curve", "view": "stay", "point": 0.5},
			{"kind": "feeling_curve", "view": "pressure", "point": 2}, {"kind": "feeling_curve", "view": "pressure",
				"mark": "the peak"}, {"kind": "feeling_curve", "view": "stay", "words": "yes"},
			{"kind": "chance_wheel", "slices": [["a", 1]]}, {"kind": "chance_wheel", "slices": [["a", 0], ["b", 1]]},
			{"kind": "chance_wheel", "slices": [["a", 20], ["b", 20]]},
			{"kind": "chance_wheel", "slices": [["a", 1, -2], ["b", 1]]},
			{"kind": "chance_wheel", "slices": [["a", 1], ["b", 1]], "pointer": 2},
			{"kind": "chance_wheel", "slices": [["a very long name", 1], ["b", 1]]},
			{"kind": "cpr_aed", "view": "back"}, {"kind": "cpr_aed", "view": "hands", "mark": "pads"},
			{"kind": "cpr_aed", "view": "pads", "pins": 1},
			{"kind": "making_plan", "tasks": [["a", 0, 2]], "columns": 4},
			{"kind": "making_plan", "tasks": [["a", 0, 2], ["b", 3, 2]], "columns": 4},
			{"kind": "making_plan", "tasks": [["a", 0, 2], ["b", 1, 0]], "columns": 4},
			{"kind": "making_plan", "tasks": [["a", 0, 2], ["b", 1, 1]], "columns": 20},
			{"kind": "making_plan", "tasks": [["a", 0, 2], ["b", 1, 1]], "columns": 4, "today": 5},
			{"kind": "smart_material", "material": "glass"},
			{"kind": "smart_material", "material": "composite", "hide": "spark"},
			{"kind": "gear_train", "stages": []}, {"kind": "gear_train", "stages": [[4, 40]]},
			{"kind": "gear_train", "stages": [[10, 40], [10, 40], [10, 40], [10, 40]]},
			{"kind": "gear_train", "stages": [[10, 40]], "turn": "left"},
			{"kind": "gear_train", "stages": [[10, 40]], "hide": 2},
			{"kind": "block_tackle", "ropes": 0}, {"kind": "block_tackle", "ropes": 7},
			{"kind": "block_tackle", "ropes": 2, "load": 0}, {"kind": "block_tackle", "ropes": 2, "effort": "lots"},
			{"kind": "tall_structure", "type": "pyramid"}, {"kind": "tall_structure", "type": "damper", "mark": "deck"},
			{"kind": "circular_loop", "side": "middle"},
			{"kind": "circular_loop", "side": "technical", "mark": "compost"},
			{"kind": "unknown_g8life"}]:
		assert_ne(SchoolPicture.problem(d), "", "a problem: %s" % d)


func test_the_rules_the_pictures_draw_by() -> void:
	assert_almost_eq(SchoolPictureG8Life.train_ratio([[10, 40]]), 4.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Life.train_ratio([[10, 40], [15, 30]]), 8.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Life.train_ratio([[40, 10]]), 0.25, 0.0001)
	assert_eq(SchoolPictureG8Life.train_turns([[10, 40], [15, 30]], "cw"), ["cw", "acw", "acw", "cw"] as Array[String])
	assert_eq(SchoolPictureG8Life.train_turns([[10, 40]], "acw"), ["acw", "cw"] as Array[String])
	assert_almost_eq(SchoolPictureG8Life.tackle_effort(800.0, 4), 200.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Life.chance([["5 gold", 1, 5], ["nothing", 9, 0]], 0), 0.1, 0.0001)
	assert_almost_eq(SchoolPictureG8Life.expected_win([["5 gold", 1, 5], ["nothing", 9, 0]]), 0.5, 0.0001)
	assert_almost_eq(SchoolPictureG8Life.expected_win([["rare", 1, 50], ["common", 15, 0], ["2 gold", 4, 2]]), 2.9,
		0.0001)
	assert_eq(SchoolPictureG8Life.plan_end([["a", 0, 2], ["b", 1, 3], ["c", 4, 1]]), 5)
	assert_eq(SchoolPictureG8Life.weakest([["stamina", 3], ["speed", 2], ["power", 2]]), "speed")
	assert_eq(SchoolPictureG8Life.pressure_zone(0.1), "too little")
	assert_eq(SchoolPictureG8Life.pressure_zone(0.5), "best zone")
	assert_eq(SchoolPictureG8Life.pressure_zone(0.9), "too much")


## A wheel's slices: each group's count, spread round the wheel.
func test_a_wheel_has_each_groups_slices() -> void:
	var slices := [["rare", 1, 50], ["common", 15, 0], ["2 gold", 4, 2]]
	var groups := SchoolPictureG8Life._slice_groups(slices)
	assert_eq(groups.size(), 20)
	assert_eq(groups.count(0), 1)
	assert_eq(groups.count(1), 15)
	assert_eq(groups.count(2), 4)


## Every part a labelled diagram names has a place inside its picture, at the label box's size and with pins.
func test_every_labelled_part_has_its_place() -> void:
	var box := ExerciseCheck.LABEL_BOX
	var checked := 0
	var pictures: Array[Dictionary] = []
	for v: String in SchoolPictureG8Life.CPR_VIEWS:
		pictures.append({"kind": "cpr_aed", "view": v, "pins": true})
	for m: String in SchoolPictureG8Life.SMART:
		pictures.append({"kind": "smart_material", "material": m, "pins": true})
	for t: String in SchoolPictureG8Life.STRUCTURES:
		pictures.append({"kind": "tall_structure", "type": t, "pins": true})
	pictures.append({"kind": "circular_loop", "pins": true, "words": false})
	for p in pictures:
		var parts: Array = []
		match str(p.kind):
			"cpr_aed":
				parts = SchoolPictureG8Life.CPR_PARTS[p.view]
			"smart_material":
				parts = SchoolPictureG8Life.SMART_PARTS[p.material]
			"tall_structure":
				parts = SchoolPictureG8Life.STRUCTURE_PARTS[p.type]
			"circular_loop":
				parts = SchoolPictureG8Life.LOOP_PARTS
		for part: String in parts:
			var at := SchoolPictureG8Life.part_at(p, part, box)
			assert_true(Rect2(Vector2.ZERO, box).has_point(at), "%s: %s at %s" % [p, part, at])
			checked += 1
		assert_eq(SchoolPictureG8Life.part_at(p, "no such part", box), Vector2(-1, -1))
	assert_gt(checked, 40)
