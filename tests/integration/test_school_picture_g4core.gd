extends GutTest
## Owner #70 and #73, grade 4 maths, science and English (research §6.4): the School draws the new units' pictures from
## data (SchoolPictureG4Core, inside SchoolPicture): line graphs and pie charts (Singapore P4 statistics), electric
## circuits (a cell, wires, bulbs, buzzers or motors, a switch, a gap and what bridges it), thermometers in °C, the three
## states of matter in jars, teeth and the digestive system. Every sample draws at the School's picture sizes; broken
## data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "line_graph", "points": [["8:00", 12], ["10:00", 16], ["12:00", 20], ["14:00", 22], ["16:00", 18]], "step": 4,
		"top": 24, "name": "Temperature (°C)"},
	{"kind": "line_graph", "points": [["Wk 1", 10], ["Wk 2", 25], ["Wk 3", 40], ["Wk 4", 60], ["Wk 5", 70], ["Wk 6", 75],
		["Wk 7", 78], ["Wk 8", 80]], "step": 10, "top": 80, "mark": 2},
	{"kind": "line_graph", "points": [["Mon", -4], ["Tue", -1], ["Wed", 3]], "step": 2, "from": -6, "top": 4},
	{"kind": "pie_chart", "slices": [["Apples", 2], ["Pears", 1], ["Plums", 1]], "lines": true},
	{"kind": "pie_chart", "slices": [["Berries", 4], ["Carrots", 1], ["Seeds", 3]], "whole": 8},
	{"kind": "pie_chart", "slices": [["Red", 1], ["Blue", 1], ["Green", 1], ["Gold", 1], ["Pink", 1], ["Grey", 7]],
		"lines": true, "key": false},
	{"kind": "lab_circuit", "parts": ["bulb"]},
	{"kind": "lab_circuit", "parts": ["bulb", "bulb"], "switch": "closed"},
	{"kind": "lab_circuit", "parts": ["bulb"], "switch": "open"},
	{"kind": "lab_circuit", "parts": ["buzzer", "motor", "bulb"], "gap": true},
	{"kind": "lab_circuit", "parts": ["bulb"], "gap": true, "bridge": "steel spoon", "conducts": true},
	{"kind": "lab_circuit", "parts": ["bulb"], "gap": true, "bridge": "rubber", "glow": "?"},
	{"kind": "lab_circuit", "parts": ["motor"], "cell": false},
	{"kind": "thermometer", "from": 0, "to": 50, "step": 10, "value": 26, "minor": 4},
	{"kind": "thermometer", "from": -20, "to": 20, "step": 10, "value": -5, "minor": 1},
	{"kind": "thermometer", "from": 0, "to": 100, "step": 10, "values": [85, 40, 20], "names": ["soup", "bath", "room"]},
	{"kind": "thermometer", "from": -20, "to": 110, "step": 10, "value": 100},
	{"kind": "states", "show": ["solid", "liquid", "gas"], "names": true},
	{"kind": "states", "show": ["liquid"], "mark": "liquid"},
	{"kind": "states", "show": ["gas", "solid"]},
	{"kind": "teeth", "labels": true},
	{"kind": "teeth", "set": "milk", "mark": "canines"},
	{"kind": "teeth", "mark": "molars"},
	{"kind": "digestion", "labels": true},
	{"kind": "digestion", "mark": "stomach"},
	{"kind": "digestion", "mark": "small intestine", "labels": true},
	{"kind": "digestion"},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG4Core.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)


func test_no_kind_is_another_grades() -> void:
	for k: String in SchoolPictureG4Core.KINDS:
		assert_false(SchoolPicture.KINDS.has(k) or SchoolPicture.SCIENCE_KINDS.has(k) or SchoolPictureG5.KINDS.has(k)
			or SchoolPictureG3.KINDS.has(k) or SchoolPictureArts.KINDS.has(k) or SchoolPictureLife.KINDS.has(k)
			or SchoolPictureHistory.KINDS.has(k), k)


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
			{"kind": "line_graph", "points": [["Mon", 3]], "step": 1, "top": 5},   # one point is not a line
			{"kind": "line_graph", "points": [["Mon", 3], ["Tue", 9]], "step": 1, "top": 5},   # above the top
			{"kind": "line_graph", "points": [["Mon", 3], ["Tue", 4]], "step": 1, "top": 12},   # 12 steps
			{"kind": "line_graph", "points": [["Mon", 3], ["Tue", 4]], "step": 2, "top": 5},   # top not a step
			{"kind": "line_graph", "points": [["Mon", "3"], ["Tue", 4]], "step": 1, "top": 5},
			{"kind": "pie_chart", "slices": [["All", 4]]},
			{"kind": "pie_chart", "slices": [["A", 2], ["B", 1]], "whole": 4},   # the slices must make the whole
			{"kind": "pie_chart", "slices": [["A", 12], ["B", 1]]},   # 13 parts
			{"kind": "pie_chart", "slices": [["A", 0], ["B", 1]]},
			{"kind": "lab_circuit", "parts": []}, {"kind": "lab_circuit", "parts": ["lamp"]},
			{"kind": "lab_circuit", "parts": ["bulb"], "switch": "half"},
			{"kind": "lab_circuit", "parts": ["bulb"], "bridge": "coin"},   # a bridge needs a gap
			{"kind": "lab_circuit", "parts": ["bulb"], "glow": "bright"},
			{"kind": "thermometer", "from": 0, "to": 50, "step": 10, "value": 60},
			{"kind": "thermometer", "from": 0, "to": 50, "step": 7, "value": 20},
			{"kind": "thermometer", "from": 0, "to": 50, "step": 10},
			{"kind": "thermometer", "from": 0, "to": 50, "step": 10, "values": [10, 20], "names": ["a"]},
			{"kind": "thermometer", "from": 0, "to": 50, "step": 10, "values": [10, 20, 30, 40]},
			{"kind": "states", "show": []}, {"kind": "states", "show": ["plasma"]},
			{"kind": "states", "show": ["gas", "gas"]}, {"kind": "states", "show": ["gas"], "mark": "solid"},
			{"kind": "teeth", "set": "shark"}, {"kind": "teeth", "mark": "fangs"},
			{"kind": "teeth", "set": "milk", "mark": "premolars"},   # milk teeth have no premolars
			{"kind": "digestion", "mark": "heart"}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## A circuit works only as a complete loop: a cell, no open switch, and no gap unless a conductor bridges it.
func test_a_circuit_works_only_as_a_complete_loop() -> void:
	assert_true(SchoolPictureG4Core.works({"kind": "lab_circuit", "parts": ["bulb"]}))
	assert_true(SchoolPictureG4Core.works({"kind": "lab_circuit", "parts": ["bulb"], "switch": "closed"}))
	assert_false(SchoolPictureG4Core.works({"kind": "lab_circuit", "parts": ["bulb"], "switch": "open"}))
	assert_false(SchoolPictureG4Core.works({"kind": "lab_circuit", "parts": ["bulb"], "gap": true}))
	assert_false(SchoolPictureG4Core.works({"kind": "lab_circuit", "parts": ["bulb"], "cell": false}))
	assert_true(SchoolPictureG4Core.works({"kind": "lab_circuit", "parts": ["bulb"], "gap": true, "bridge": "coin",
		"conducts": true}))
	assert_false(SchoolPictureG4Core.works({"kind": "lab_circuit", "parts": ["bulb"], "gap": true, "bridge": "rubber"}))


## The teeth drawn are an adult's jaw (4 incisors, 2 canines, 4 premolars, 6 molars: 16, 32 in both jaws) or a
## child's milk teeth (4 incisors, 2 canines, 4 molars: 10, 20 in both jaws).
func test_the_teeth_of_one_jaw() -> void:
	assert_eq(SchoolPictureG4Core.jaw("adult"), {"incisors": 4, "canines": 2, "premolars": 4, "molars": 6})
	assert_eq(SchoolPictureG4Core.jaw("milk"), {"incisors": 4, "canines": 2, "premolars": 0, "molars": 4})


## A pie chart's slices in turn from the top, clockwise: each slice's share of the whole circle.
func test_the_pie_charts_slices() -> void:
	assert_eq(SchoolPictureG4Core.pie_parts({"kind": "pie_chart", "slices": [["A", 2], ["B", 1], ["C", 1]]}), [2, 1, 1])
	assert_eq(SchoolPictureG4Core.pie_whole({"kind": "pie_chart", "slices": [["A", 2], ["B", 1], ["C", 1]]}), 4)
	assert_eq(SchoolPictureG4Core.pie_whole({"kind": "pie_chart", "slices": [["A", 5], ["B", 3]], "whole": 8}), 8)
