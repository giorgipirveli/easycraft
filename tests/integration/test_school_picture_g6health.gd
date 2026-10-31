extends GutTest
## Grade 6 health and PE, design and technology, and projects: the picture kinds they add (SchoolPictureG6Health, drawn
## inside SchoolPicture): the three classes of lever with their forces and distances, linkages that reverse, keep or
## turn a movement, a truss of triangles with its squashed and stretched bars, the five forces on a structure, designs
## copied from nature, samples of materials, Arts and Crafts and Bauhaus designs, a sensor's input, process and output,
## sensor readings against a threshold, box breathing, the circle of control, the food thermometer's zones, bacteria
## doubling, a weather station's instruments, ACCESS FM, the talk test, FAST (the signs of a stroke), and a sprint start,
## a relay's takeover zone, the long jump's measure and the triple jump's phases. Every kind draws from its data at the
## School's picture sizes; broken data is a problem the content test finds; the rules they draw by are checked here.

const SAMPLES: Array[Dictionary] = [
	{"kind": "lever_class", "pivot": 5, "load": 1, "effort": 9},
	{"kind": "lever_class", "pivot": 0, "load": 4, "effort": 10, "tags": {"load": "wheel"}, "values": {"load": "60 N",
		"effort": "?"}, "scale": true},
	{"kind": "lever_class", "pivot": 0, "load": 10, "effort": 3, "scale": true},
	{"kind": "lever_class", "pivot": 0, "load": 10, "effort": 4, "names": false},
	{"kind": "linkage", "type": "reverse"},
	{"kind": "linkage", "type": "reverse", "move": "left", "labels": true, "output": false},
	{"kind": "linkage", "type": "parallel", "labels": true},
	{"kind": "linkage", "type": "bell_crank", "move": "left"},
	{"kind": "linkage", "type": "crank_slider", "labels": true},
	{"kind": "truss", "panels": 3},
	{"kind": "truss", "panels": 5, "forces": true, "load": true},
	{"kind": "truss", "panels": 2, "numbers": true, "mark": "diagonal"},
	{"kind": "truss", "panels": 6, "numbers": true, "mark": "top"},
	{"kind": "struct_force", "forces": ["compression", "tension", "bending", "torsion", "shear"]},
	{"kind": "struct_force", "forces": ["tension"], "names": false},
	{"kind": "struct_force", "forces": ["bending", "shear"], "hide": 1, "mark": 0},
	{"kind": "biomimicry", "pair": "burr"},
	{"kind": "biomimicry", "pair": "kingfisher", "show": "nature"},
	{"kind": "biomimicry", "pair": "kingfisher", "show": "design", "names": false},
	{"kind": "biomimicry", "pair": "honeycomb"},
	{"kind": "biomimicry", "pair": "lotus"},
	{"kind": "biomimicry", "pair": "whale_fin"},
	{"kind": "biomimicry", "pair": "termite"},
	{"kind": "material_swatch", "samples": ["oak", "pine", "plywood", "mdf"]},
	{"kind": "material_swatch", "samples": ["steel", "aluminium", "copper", "brass"], "mark": 2},
	{"kind": "material_swatch", "samples": ["acrylic", "polythene", "melamine"], "hide": 0},
	{"kind": "material_swatch", "samples": ["carbon_fibre", "concrete"], "names": false},
	{"kind": "design_style", "style": "arts_crafts", "object": "pattern", "label": true},
	{"kind": "design_style", "style": "bauhaus", "object": "pattern"},
	{"kind": "design_style", "style": "arts_crafts", "object": "chair"},
	{"kind": "design_style", "style": "bauhaus", "object": "chair", "label": true},
	{"kind": "design_style", "style": "arts_crafts", "object": "lamp"},
	{"kind": "design_style", "style": "bauhaus", "object": "lamp"},
	{"kind": "sensor_system", "input": "light", "process": "IF dark", "output": "lamp"},
	{"kind": "sensor_system", "input": "heat", "output": "fan", "hide": "input"},
	{"kind": "sensor_system", "input": "moisture", "output": "pump", "headings": false},
	{"kind": "sensor_system", "input": "sound", "output": "led"},
	{"kind": "sensor_system", "input": "motion", "output": "buzzer", "hide": "output"},
	{"kind": "sensor_system", "input": "push", "output": "motor", "process": "microcontroller"},
	{"kind": "sensor_system", "input": "tilt", "output": "buzzer", "hide": "process"},
	{"kind": "sensor_system", "input": "magnet", "output": "lamp"},
	{"kind": "threshold_graph", "readings": [80, 60, 35, 20, 10], "labels": ["4 pm", "5 pm", "6 pm", "7 pm", "8 pm"],
		"threshold": 30},
	{"kind": "threshold_graph", "readings": [4, 12, 22, 27, 18, 8, 3], "labels": ["Mon", "Tue", "Wed", "Thu", "Fri",
		"Sat", "Sun"], "threshold": 20, "below": false, "name": "temperature (°C)", "top": 40, "show_on": true},
	{"kind": "breath_box"},
	{"kind": "breath_box", "count": 5, "mark": 2},
	{"kind": "breath_box", "count": 4, "words": false, "mark": 0},
	{"kind": "control_rings", "inside": ["my effort", "asking for help", "my bedtime"], "outside": ["the weather",
		"what others think", "the past"]},
	{"kind": "control_rings", "inside": ["how I respond"], "outside": ["a test's questions"], "titles": false},
	{"kind": "food_thermo"},
	{"kind": "food_thermo", "value": 37, "mark": "danger"},
	{"kind": "food_thermo", "value": -18, "hide": "freezer"},
	{"kind": "food_thermo", "value": 4, "labels": false},
	{"kind": "food_thermo", "value": 75, "mark": "hot"},
	{"kind": "microbe_split", "steps": 0},
	{"kind": "microbe_split", "steps": 3},
	{"kind": "microbe_split", "steps": 5, "minutes": 20, "times": false},
	{"kind": "weather_kit", "tools": ["thermometer", "rain_gauge", "wind_vane", "anemometer"]},
	{"kind": "weather_kit", "tools": ["barometer"], "names": false},
	{"kind": "weather_kit", "tools": ["rain_gauge", "anemometer", "barometer"], "hide": 1, "mark": 0},
	{"kind": "access_fm"},
	{"kind": "access_fm", "mark": 4, "hide": 6},
	{"kind": "access_fm", "words": false},
	{"kind": "talk_test"},
	{"kind": "talk_test", "mark": "moderate"},
	{"kind": "talk_test", "mark": "vigorous", "words": false},
	{"kind": "fast_signs"},
	{"kind": "fast_signs", "mark": 1, "hide": 2},
	{"kind": "fast_signs", "words": false},
	{"kind": "track_field", "view": "marks"},
	{"kind": "track_field", "view": "set", "labels": true},
	{"kind": "track_field", "view": "relay", "labels": true},
	{"kind": "track_field", "view": "long_jump", "marks": [3.6, 3.2], "measure": true, "labels": true},
	{"kind": "track_field", "view": "long_jump"},
	{"kind": "track_field", "view": "triple_jump", "phases": [3.5, 2.5, 3.0], "labels": true},
	{"kind": "track_field", "view": "triple_jump", "phases": [2, 2, 2]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126),
	Vector2(520, 250)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_and_its_options_have_a_sample() -> void:
	var seen := {}
	for d in SAMPLES:
		seen[str(d.kind)] = true
		for k: String in ["type", "pair", "style", "object", "input", "output", "view"]:
			if d.has(k):
				seen["%s:%s" % [k, d[k]]] = true
		for k: String in ["forces", "samples", "tools"]:
			if d.get(k) is Array:
				for v: Variant in d[k]:
					seen["%s:%s" % [k, v]] = true
	for k: String in SchoolPictureG6Health.KINDS:
		assert_true(seen.has(k), "a sample of %s" % k)
	var lists := {"type": SchoolPictureG6Health.LINKAGES, "pair": SchoolPictureG6Health.PAIRS,
		"style": SchoolPictureG6Health.STYLES, "object": SchoolPictureG6Health.OBJECTS,
		"input": SchoolPictureG6Health.SENSORS, "output": SchoolPictureG6Health.OUTPUTS,
		"view": SchoolPictureG6Health.VIEWS, "forces": SchoolPictureG6Health.STRUCT_FORCES,
		"samples": SchoolPictureG6Health.MATERIALS, "tools": SchoolPictureG6Health.TOOLS}
	for k: String in lists:
		for v: Variant in lists[k]:
			assert_true(seen.has("%s:%s" % [k, v]), "a sample of %s %s" % [k, v])


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


## The rules the pictures draw by, which the lessons teach: a lever's class is what sits in the middle; the effort
## pushes down across the pivot from the load and lifts up on the same side; a reverse linkage turns a push round, a
## parallel one keeps it and a bell crank turns it through a right angle; a Warren truss of p panels has 2p − 1
## triangles, 4p − 1 bars and 2p + 1 joints; food is in the danger zone above 5 °C and below 63 °C; bacteria double
## every step; the long jump is measured to the nearest mark; a sensor's output is on when its reading passes the
## threshold.
func test_the_pictures_follow_the_rules_they_teach() -> void:
	assert_eq(SchoolPictureG6Health.lever_kind(5, 1, 9), 1)
	assert_eq(SchoolPictureG6Health.lever_kind(0, 4, 10), 2)
	assert_eq(SchoolPictureG6Health.lever_kind(0, 10, 3), 3)
	assert_eq(SchoolPictureG6Health.lever_kind(10, 2, 6), 3)
	assert_false(SchoolPictureG6Health.effort_up(5, 1, 9), "a seesaw: push down")
	assert_true(SchoolPictureG6Health.effort_up(0, 4, 10), "a wheelbarrow: lift up")
	assert_true(SchoolPictureG6Health.effort_up(0, 10, 3), "tweezers and a forearm: up")
	assert_eq(SchoolPictureG6Health.linkage_output("reverse", "right"), "left")
	assert_eq(SchoolPictureG6Health.linkage_output("reverse", "left"), "right")
	assert_eq(SchoolPictureG6Health.linkage_output("parallel", "left"), "left")
	assert_eq(SchoolPictureG6Health.linkage_output("bell_crank", "right"), "down")
	assert_eq(SchoolPictureG6Health.linkage_output("bell_crank", "left"), "up")
	assert_eq(SchoolPictureG6Health.linkage_output("crank_slider", "right"), "back and forth")
	for p in range(2, 7):
		var n := SchoolPictureG6Health.truss_counts(p)
		assert_eq(int(n.triangles), 2 * p - 1)
		assert_eq(int(n.bars), 4 * p - 1)
		assert_eq(int(n.joints), 2 * p + 1)
		assert_eq(int(n.bars), 2 * int(n.joints) - 3, "a truss just stiff enough: bars = 2 × joints − 3")
	assert_eq(SchoolPictureG6Health.zone_of(-20), "freezer")
	assert_eq(SchoolPictureG6Health.zone_of(-18), "freezer")
	assert_eq(SchoolPictureG6Health.zone_of(3), "fridge")
	assert_eq(SchoolPictureG6Health.zone_of(5), "fridge")
	assert_eq(SchoolPictureG6Health.zone_of(6), "danger")
	assert_eq(SchoolPictureG6Health.zone_of(37), "danger")
	assert_eq(SchoolPictureG6Health.zone_of(63), "hot")
	assert_eq(SchoolPictureG6Health.zone_of(75), "hot")
	assert_eq(SchoolPictureG6Health.zone_of(-10), "", "between the freezer and the fridge: no zone")
	assert_eq(SchoolPictureG6Health.jump_length([3.6, 3.2]), 3.2)
	assert_eq(SchoolPictureG6Health.on_at([80, 60, 35, 20, 10], 30, true), [false, false, false, true, true])
	assert_eq(SchoolPictureG6Health.on_at([4, 12, 22, 27, 18], 20, false), [false, false, true, true, false])


## The label exercises' parts are where the pictures draw them (part_at), and a part the picture has not is (-1, -1).
func test_parts_are_found() -> void:
	var box := Vector2(520, 250)
	var lever := {"kind": "lever_class", "pivot": 0, "load": 4, "effort": 10}
	var pivot := SchoolPictureG6Health.part_at(lever, "pivot", box)
	var load := SchoolPictureG6Health.part_at(lever, "load", box)
	var effort := SchoolPictureG6Health.part_at(lever, "effort", box)
	assert_lt(pivot.x, load.x, "the pivot is at the left end")
	assert_lt(load.x, effort.x, "the effort at the right end")
	assert_eq(SchoolPictureG6Health.part_at(lever, "fulcrum?", box), Vector2(-1, -1))
	var s := {"kind": "sensor_system", "input": "light", "output": "lamp"}
	var a := SchoolPictureG6Health.part_at(s, "input", box)
	var b := SchoolPictureG6Health.part_at(s, "process", box)
	var c := SchoolPictureG6Health.part_at(s, "output", box)
	assert_true(a.x < b.x and b.x < c.x, "input, process, output from left to right")
	var kit := {"kind": "weather_kit", "tools": ["rain_gauge", "wind_vane", "anemometer"]}
	assert_lt(SchoolPictureG6Health.part_at(kit, "rain gauge", box).x, SchoolPictureG6Health.part_at(kit, "anemometer",
		box).x)
	assert_eq(SchoolPictureG6Health.part_at(kit, "barometer", box), Vector2(-1, -1))
	var truss := {"kind": "truss", "panels": 4}
	assert_lt(SchoolPictureG6Health.part_at(truss, "top chord", box).y, SchoolPictureG6Health.part_at(truss,
		"bottom chord", box).y)
	for p: Vector2 in [pivot, load, effort, a, b, c]:
		assert_true(Rect2(Vector2.ZERO, box).has_point(p), "inside the picture: %s" % p)


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "lever_class"}, {"kind": "lever_class", "pivot": 5, "load": 5, "effort": 9},
			{"kind": "lever_class", "pivot": 5, "load": 1, "effort": 11},
			{"kind": "lever_class", "pivot": 5, "load": 1, "effort": 9, "tags": {"load": "a very long tag here"}},
			{"kind": "lever_class", "pivot": 5, "load": 1, "effort": 9, "values": {"spin": "3"}},
			{"kind": "lever_class", "pivot": 5, "load": 1, "effort": 9, "scale": 1},
			{"kind": "lever_class", "pivot": 5, "load": 1, "effort": 9, "names": "no"},
			{"kind": "linkage"}, {"kind": "linkage", "type": "chain"}, {"kind": "linkage", "type": "reverse", "move": "up"},
			{"kind": "linkage", "type": "reverse", "output": "no"},
			{"kind": "truss"}, {"kind": "truss", "panels": 1}, {"kind": "truss", "panels": 7},
			{"kind": "truss", "panels": 3, "mark": "roof"},
			{"kind": "struct_force"}, {"kind": "struct_force", "forces": []},
			{"kind": "struct_force", "forces": ["twist"]}, {"kind": "struct_force", "forces": ["tension", "tension"]},
			{"kind": "struct_force", "forces": ["tension"], "hide": 1},
			{"kind": "biomimicry"}, {"kind": "biomimicry", "pair": "spider"},
			{"kind": "biomimicry", "pair": "burr", "show": "both sides"},
			{"kind": "material_swatch"}, {"kind": "material_swatch", "samples": ["gold"]},
			{"kind": "material_swatch", "samples": ["oak", "pine", "mdf", "steel", "copper"]},
			{"kind": "material_swatch", "samples": ["oak"], "mark": 1},
			{"kind": "design_style"}, {"kind": "design_style", "style": "baroque", "object": "chair"},
			{"kind": "design_style", "style": "bauhaus", "object": "sofa"},
			{"kind": "sensor_system"}, {"kind": "sensor_system", "input": "smell", "output": "lamp"},
			{"kind": "sensor_system", "input": "light", "output": "radio"},
			{"kind": "sensor_system", "input": "light", "output": "lamp", "process": "a process far too long"},
			{"kind": "sensor_system", "input": "light", "output": "lamp", "hide": "all"},
			{"kind": "threshold_graph"}, {"kind": "threshold_graph", "readings": [1, 2], "labels": ["a", "b"],
				"threshold": 5},
			{"kind": "threshold_graph", "readings": [1, 2, 3], "labels": ["a", "b"], "threshold": 5},
			{"kind": "threshold_graph", "readings": [1, 2, 300], "labels": ["a", "b", "c"], "threshold": 5},
			{"kind": "threshold_graph", "readings": [1, 2, 3], "labels": ["a", "b", "c"], "threshold": 0},
			{"kind": "breath_box", "count": 9}, {"kind": "breath_box", "mark": 4},
			{"kind": "control_rings"}, {"kind": "control_rings", "inside": [], "outside": ["x"]},
			{"kind": "control_rings", "inside": ["a", "b", "c", "d", "e"], "outside": ["x"]},
			{"kind": "food_thermo", "value": 120}, {"kind": "food_thermo", "mark": "oven"},
			{"kind": "microbe_split"}, {"kind": "microbe_split", "steps": 6},
			{"kind": "microbe_split", "steps": 2, "minutes": 5},
			{"kind": "weather_kit"}, {"kind": "weather_kit", "tools": ["radar"]},
			{"kind": "weather_kit", "tools": ["barometer", "barometer"]},
			{"kind": "access_fm", "mark": 8}, {"kind": "access_fm", "words": "yes"},
			{"kind": "talk_test", "mark": "sprint"},
			{"kind": "fast_signs", "hide": 4},
			{"kind": "track_field"}, {"kind": "track_field", "view": "hurdles"},
			{"kind": "track_field", "view": "long_jump", "marks": [3.6]},
			{"kind": "track_field", "view": "long_jump", "marks": [3.6, 12]},
			{"kind": "track_field", "view": "triple_jump", "phases": [3, 3]},
			{"kind": "track_field", "view": "triple_jump", "phases": [3, 3, 9]}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))
