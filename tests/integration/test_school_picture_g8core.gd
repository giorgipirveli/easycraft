extends GutTest
## Owner #70, #73 and #111, grade 8 maths, science and English (research §6.8): the School draws their pictures from data
## (SchoolPictureG8Core, inside SchoolPicture): the U of y = x² and its crossings, a right-angled triangle with its sides
## named from the marked angle (and a ladder or a ramp), pressure in solids, liquids and gases (a brick on two faces, a
## tank's spouts, a dam, floating and sinking), an electricity meter, an energy level diagram, series and parallel
## circuits with ammeters and voltmeters, a plant's xylem and phloem, the heart's four chambers, an air sac, genetic
## engineering in four panels, a presentation slide (clear and crammed), and a story's told order over its time order.
## Every sample draws at the School's picture sizes; broken data is a problem the content test finds; the rules the
## pictures draw by (a parabola's crossings, lowest point and equation; a circuit's meters; a meter's units; a
## flashback) are checked here, and every labelled part has its place.

const SAMPLES: Array[Dictionary] = [
	{"kind": "parabola"},
	{"kind": "parabola", "c": -4, "roots": true, "vertex": true, "axis": true},
	{"kind": "parabola", "b": -4, "c": 3, "from": -1, "to": 5, "points": [0, 4], "roots": true},
	{"kind": "parabola", "a": -1, "c": 9, "roots": true, "vertex": true},
	{"kind": "parabola", "a": 2, "b": 0, "c": 1, "from": -3, "to": 3, "equation": false},
	{"kind": "trig_triangle", "angle": 37, "sides": {"hyp": "5", "opp": "3", "adj": "4"}},
	{"kind": "trig_triangle", "angle": 30, "names": true, "mark": "opp"},
	{"kind": "trig_triangle", "angle": 60, "at": "top", "names": true, "sides": {"hyp": "10 cm", "adj": "?"}},
	{"kind": "trig_triangle", "angle": 75, "scene": "ladder", "sides": {"hyp": "6 m", "opp": "?"}, "angle_label": "75°"},
	{"kind": "trig_triangle", "angle": 10, "scene": "ramp", "sides": {"opp": "1.5 m", "hyp": "?"}, "angle_label": "10°"},
	{"kind": "trig_triangle", "angle": 40, "labels": true, "hide": "adjacent"},
	{"kind": "trig_triangle", "angle": 55, "at": "top", "pins": true},
	{"kind": "fluid_pressure", "view": "faces"},
	{"kind": "fluid_pressure", "view": "faces", "labels": true, "mark": "small area"},
	{"kind": "fluid_pressure", "view": "spouts"},
	{"kind": "fluid_pressure", "view": "spouts", "labels": true, "hide": "bottom hole"},
	{"kind": "fluid_pressure", "view": "dam"},
	{"kind": "fluid_pressure", "view": "dam", "pins": true},
	{"kind": "fluid_pressure", "view": "float"},
	{"kind": "fluid_pressure", "view": "float", "floats": false},
	{"kind": "fluid_pressure", "view": "float", "pins": true},
	{"kind": "fluid_pressure", "view": "float", "floats": false, "labels": true, "words": false},
	{"kind": "energy_meter", "readings": [["Monday", "12790"], ["next Monday", "12846"]]},
	{"kind": "energy_meter", "readings": [["now", "04512"]], "unit": "kWh"},
	{"kind": "energy_meter", "readings": [["1 March", "305618"], ["1 April", "305990"]], "mark": 1},
	{"kind": "energy_profile", "type": "exo"},
	{"kind": "energy_profile", "type": "endo", "reactants": "limestone", "products": "lime + gas"},
	{"kind": "energy_profile", "type": "exo", "values": [700, 400], "hide": "change"},
	{"kind": "energy_profile", "type": "endo", "values": [200, 350], "hump": false},
	{"kind": "energy_profile", "type": "exo", "pins": true},
	{"kind": "energy_profile", "type": "endo", "labels": true, "mark": "activation energy"},
	{"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["lamp", 6], ["lamp", 6]],
		"meters": [["A", "main", 0.5], ["V", "0", 3], ["V", "1", "?"]]},
	{"kind": "meter_circuit", "layout": "series", "volts": 9, "parts": [["resistor", 10], ["lamp", 20], ["motor", 15]],
		"meters": [["A", "main", "?"], ["V", "cell", 9]], "names": true},
	{"kind": "meter_circuit", "layout": "series", "volts": 1.5, "parts": [["lamp"]], "meters": [["A", "main"]]},
	{"kind": "meter_circuit", "layout": "parallel", "volts": 6, "parts": [["lamp", 12], ["lamp", 20]],
		"meters": [["A", "main", 0.8], ["A", "0", 0.5], ["A", "1", "?"]]},
	{"kind": "meter_circuit", "layout": "parallel", "volts": 12, "parts": [["lamp", 24], ["resistor", 12], ["motor", 6]],
		"meters": [["A", "main", "?"], ["V", "1", 12]], "names": true},
	{"kind": "meter_circuit", "layout": "parallel", "volts": 3, "parts": [["lamp"], ["lamp"]],
		"meters": [["V", "cell", 3], ["V", "0", "?"]]},
	{"kind": "plant_transport"},
	{"kind": "plant_transport", "labels": true},
	{"kind": "plant_transport", "show": "xylem", "mark": "root hairs"},
	{"kind": "plant_transport", "show": "phloem", "flows": false},
	{"kind": "plant_transport", "pins": true},
	{"kind": "heart_chambers"},
	{"kind": "heart_chambers", "labels": true, "hide": "left ventricle"},
	{"kind": "heart_chambers", "pins": true, "flow": false},
	{"kind": "heart_chambers", "sides": false, "mark": "aorta"},
	{"kind": "heart_chambers", "labels": true, "parts": ["right atrium", "left atrium", "right ventricle",
		"left ventricle", "aorta"], "mark": "left ventricle"},
	{"kind": "air_sac"},
	{"kind": "air_sac", "labels": true},
	{"kind": "air_sac", "pins": true, "arrows": false},
	{"kind": "gene_transfer"},
	{"kind": "gene_transfer", "step": 2},
	{"kind": "gene_transfer", "labels": true, "hide": "plasmid"},
	{"kind": "gene_transfer", "pins": true, "words": false},
	{"kind": "slide_design", "title": "Plastic on our beach", "bullets": ["Most litter is plastic",
		"It harms sea birds"], "chart": [["plastic", 60], ["paper", 15], ["glass", 10], ["metal", 15]]},
	{"kind": "slide_design", "title": "Plastic on our beach", "bullets": ["Most litter is plastic", "It harms sea birds",
		"Some of it is very small", "Nets and ropes last for years", "Bottle tops are common"], "busy": true},
	{"kind": "slide_design", "title": "Six in ten pieces", "number": "60%", "notes": "Pause, then say what it means.",
		"mark": "number"},
	{"kind": "slide_design", "title": "Where we counted", "image": "map", "bullets": ["Three beaches"]},
	{"kind": "slide_design", "title": "How plants grow", "image": "plant", "mark": "title"},
	{"kind": "slide_design", "title": "Solar power", "image": "sun", "bullets": ["Clean", "Free once built"],
		"mark": "bullets"},
	{"kind": "slide_design", "title": "Our results", "image": "chart_icon"},
	{"kind": "story_order", "events": ["Ana learns to swim", "a storm hits the bay", "Ana saves her brother"],
		"told": [2, 0, 1], "flash": 0},
	{"kind": "story_order", "events": ["a", "b", "c", "d", "e"], "told": [0, 1, 2, 3, 4]},
	{"kind": "story_order", "events": ["the old map is found", "the trip begins", "the cave", "home again"],
		"told": [1, 2, 0, 3], "names": false, "flash": 0},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126),
	Vector2(520, 250)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_and_view_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG8Core.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	for pair: Array in [["fluid_pressure", "view", SchoolPictureG8Core.FLUID_VIEWS], ["energy_profile", "type",
			SchoolPictureG8Core.PROFILE_TYPES], ["meter_circuit", "layout", SchoolPictureG8Core.LAYOUTS],
			["trig_triangle", "scene", SchoolPictureG8Core.SCENES], ["slide_design", "image", ["map", "plant", "sun",
			"chart_icon"]]]:
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
			{"kind": "parabola", "a": 0}, {"kind": "parabola", "a": 4}, {"kind": "parabola", "b": 1.5},
			{"kind": "parabola", "c": 40}, {"kind": "parabola", "from": 0, "to": 1}, {"kind": "parabola", "to": 9},
			{"kind": "parabola", "points": [7]}, {"kind": "parabola", "roots": "yes"},
			{"kind": "trig_triangle", "angle": 5}, {"kind": "trig_triangle", "angle": 30.5},
			{"kind": "trig_triangle", "angle": 30, "at": "right"}, {"kind": "trig_triangle", "angle": 30, "scene": "tree"},
			{"kind": "trig_triangle", "angle": 30, "sides": {"long": "5"}},
			{"kind": "trig_triangle", "angle": 30, "sides": {"hyp": "a long side"}},
			{"kind": "trig_triangle", "angle": 30, "angle_label": "the angle"},
			{"kind": "trig_triangle", "angle": 30, "hide": "hyp"},
			{"kind": "fluid_pressure", "view": "air"}, {"kind": "fluid_pressure", "view": "dam", "floats": true},
			{"kind": "fluid_pressure", "view": "float", "mark": "dam wall"},
			{"kind": "energy_meter", "readings": []}, {"kind": "energy_meter", "readings": [["a", "12"]]},
			{"kind": "energy_meter", "readings": [["a", "12a45"]]}, {"kind": "energy_meter", "readings": [["a", 1234]]},
			{"kind": "energy_meter", "readings": [["a", "1234"], ["b", "1200"]]},
			{"kind": "energy_meter", "readings": [["a", "1234"], ["b", "12345"]]},
			{"kind": "energy_meter", "readings": [["a", "1234"]], "mark": 1},
			{"kind": "energy_profile", "type": "warm"}, {"kind": "energy_profile", "type": "exo", "values": [100, 300]},
			{"kind": "energy_profile", "type": "endo", "values": [300, 100]},
			{"kind": "energy_profile", "type": "exo", "values": [300]},
			{"kind": "energy_profile", "type": "exo", "reactants": "a very long name here"},
			{"kind": "energy_profile", "type": "exo", "mark": "change"},
			{"kind": "meter_circuit", "layout": "ring", "volts": 6, "parts": [["lamp"]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 0, "parts": [["lamp"]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 30, "parts": [["lamp"]]},
			{"kind": "meter_circuit", "layout": "parallel", "volts": 6, "parts": [["lamp"]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["bulb"]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["lamp", 0]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["lamp", 6]], "meters": [["A", "0"]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["lamp", 6]], "meters": [["W", "main"]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["lamp", 6]], "meters": [["A", "main", 2]]},
			{"kind": "meter_circuit", "layout": "parallel", "volts": 6, "parts": [["lamp", 6], ["lamp", 3]],
				"meters": [["A", "main", 2]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["lamp", 6]], "meters": [["V", "0", "x"]]},
			{"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["lamp"]], "meters": [["V", "0"],
				["V", "0"]]},
			{"kind": "plant_transport", "show": "roots"}, {"kind": "plant_transport", "show": "xylem", "mark": "phloem"},
			{"kind": "heart_chambers", "mark": "lungs"}, {"kind": "heart_chambers", "flow": 1},
			{"kind": "heart_chambers", "parts": ["lungs"]},
			{"kind": "heart_chambers", "parts": ["aorta"], "hide": "vena cava"},
			{"kind": "air_sac", "hide": "nose"}, {"kind": "gene_transfer", "step": 5},
			{"kind": "gene_transfer", "mark": "virus"},
			{"kind": "slide_design"}, {"kind": "slide_design", "title": "a title much too long for any slide here"},
			{"kind": "slide_design", "title": "t", "bullets": ["a", "b", "c", "d", "e", "f"]},
			{"kind": "slide_design", "title": "t", "chart": [["a", 1]]},
			{"kind": "slide_design", "title": "t", "chart": [["a", -1], ["b", 2]]},
			{"kind": "slide_design", "title": "t", "image": "cat"}, {"kind": "slide_design", "title": "t", "mark": "x"},
			{"kind": "story_order", "events": ["a", "b"], "told": [1, 0]},
			{"kind": "story_order", "events": ["a", "b", "c"], "told": [0, 1]},
			{"kind": "story_order", "events": ["a", "b", "c"], "told": [0, 1, 1]},
			{"kind": "story_order", "events": ["a", "b", "c"], "told": [0, 1, 2], "flash": 3},
			{"kind": "story_order", "events": ["a", "b", "an event far too long to fit"], "told": [0, 1, 2]},
			{"kind": "unknown_g8core"}]:
		assert_ne(SchoolPicture.problem(d), "", "a problem: %s" % d)


## The rules the pictures draw by.
func test_the_rules() -> void:
	assert_eq(SchoolPictureG8Core.equation({"kind": "parabola"}), "y = x²")
	assert_eq(SchoolPictureG8Core.equation({"kind": "parabola", "c": -4}), "y = x² − 4")
	assert_eq(SchoolPictureG8Core.equation({"kind": "parabola", "b": -4, "c": 3}), "y = x² − 4x + 3")
	assert_eq(SchoolPictureG8Core.equation({"kind": "parabola", "a": -1, "b": 1, "c": 6}), "y = −x² + x + 6")
	assert_eq(SchoolPictureG8Core.equation({"kind": "parabola", "a": 2, "b": 5}), "y = 2x² + 5x")
	assert_eq(SchoolPictureG8Core.roots({"kind": "parabola", "c": -4}), [-2.0, 2.0] as Array[float])
	assert_eq(SchoolPictureG8Core.roots({"kind": "parabola", "b": -4, "c": 3}), [1.0, 3.0] as Array[float])
	assert_eq(SchoolPictureG8Core.roots({"kind": "parabola", "b": -6, "c": 9}), [3.0] as Array[float])
	assert_eq(SchoolPictureG8Core.roots({"kind": "parabola", "c": 1}), [] as Array[float])
	assert_eq(SchoolPictureG8Core.vertex({"kind": "parabola", "b": -4, "c": 3}), Vector2(2, -1))
	assert_almost_eq(SchoolPictureG8Core.parabola_y({"kind": "parabola", "a": -1, "c": 9}, 3.0), 0.0, 0.0001)
	assert_eq(SchoolPictureG8Core.meter_used({"kind": "energy_meter", "readings": [["a", "12790"], ["b", "12846"]]}), 56)
	var series := {"kind": "meter_circuit", "layout": "series", "volts": 6, "parts": [["lamp", 2], ["resistor", 4]],
		"meters": [["A", "main"], ["V", "0"], ["V", "1"], ["V", "cell"]]}
	assert_almost_eq(SchoolPictureG8Core.reading(series, 0), 1.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Core.reading(series, 1), 2.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Core.reading(series, 2), 4.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Core.reading(series, 3), 6.0, 0.0001)
	var parallel := {"kind": "meter_circuit", "layout": "parallel", "volts": 6, "parts": [["lamp", 2], ["lamp", 3]],
		"meters": [["A", "main"], ["A", "0"], ["A", "1"], ["V", "1"]]}
	assert_almost_eq(SchoolPictureG8Core.reading(parallel, 0), 5.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Core.reading(parallel, 1), 3.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Core.reading(parallel, 2), 2.0, 0.0001)
	assert_almost_eq(SchoolPictureG8Core.reading(parallel, 3), 6.0, 0.0001)
	assert_true(is_nan(SchoolPictureG8Core.reading({"kind": "meter_circuit", "layout": "series", "volts": 6, "parts":
		[["lamp"]], "meters": [["A", "main"]]}, 0)), "no resistance: no reading")
	assert_true(SchoolPictureG8Core.flashback({"told": [2, 0, 1]}))
	assert_false(SchoolPictureG8Core.flashback({"told": [0, 1, 2]}))


## Every part a labelled diagram names has a place inside its picture, at the label box's size and with pins; the sides
## of a triangle are named from its marked angle.
func test_every_labelled_part_has_its_place() -> void:
	var box := ExerciseCheck.LABEL_BOX
	var checked := 0
	var pictures: Array = []
	for at: String in SchoolPictureG8Core.AT:
		pictures.append([{"kind": "trig_triangle", "angle": 35, "at": at, "pins": true}, SchoolPictureG8Core.TRIG_PARTS])
	for v: String in SchoolPictureG8Core.FLUID_VIEWS:
		pictures.append([{"kind": "fluid_pressure", "view": v, "pins": true}, SchoolPictureG8Core.FLUID_PARTS[v]])
	pictures.append([{"kind": "fluid_pressure", "view": "float", "floats": false, "pins": true},
		SchoolPictureG8Core.FLUID_PARTS["float"]])
	for t: String in SchoolPictureG8Core.PROFILE_TYPES:
		pictures.append([{"kind": "energy_profile", "type": t, "pins": true}, SchoolPictureG8Core.PROFILE_PARTS])
	pictures.append([{"kind": "plant_transport", "pins": true}, SchoolPictureG8Core.PLANT_PARTS])
	pictures.append([{"kind": "heart_chambers", "pins": true}, SchoolPictureG8Core.HEART_PARTS])
	pictures.append([{"kind": "air_sac", "pins": true}, SchoolPictureG8Core.SAC_PARTS])
	pictures.append([{"kind": "gene_transfer", "pins": true}, SchoolPictureG8Core.GENE_PARTS])
	for pair: Array in pictures:
		var p: Dictionary = pair[0]
		for part: String in pair[1]:
			var at := SchoolPictureG8Core.part_at(p, part, box)
			assert_true(Rect2(Vector2.ZERO, box).has_point(at), "%s: %s at %s" % [p, part, at])
			checked += 1
		assert_eq(SchoolPictureG8Core.part_at(p, "no such part", box), Vector2(-1, -1))
	assert_gt(checked, 40)
	# With the angle at the bottom left, the opposite side is the upright one; with it at the top, the base.
	var low := {"kind": "trig_triangle", "angle": 35, "pins": true}
	var high := {"kind": "trig_triangle", "angle": 35, "at": "top", "pins": true}
	var lo_opp := SchoolPictureG8Core.part_at(low, "opposite", box)
	var lo_adj := SchoolPictureG8Core.part_at(low, "adjacent", box)
	assert_lt(lo_opp.y, lo_adj.y, "the upright side is opposite an angle at the bottom left")
	var hi_opp := SchoolPictureG8Core.part_at(high, "opposite", box)
	var hi_adj := SchoolPictureG8Core.part_at(high, "adjacent", box)
	assert_gt(hi_opp.y, hi_adj.y, "the base is opposite an angle at the top")
	assert_eq(SchoolPictureG8Core.part_at({"kind": "slide_design", "title": "t"}, "title", box), Vector2(-1, -1))
