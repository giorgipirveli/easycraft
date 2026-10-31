extends GutTest
## Owner #70, #73 and #111, grade 8 computing, art and music (research §6.8): the School draws their pictures from data
## (SchoolPictureG8Arts, inside SchoolPicture): a program planned in modules, how algorithms' steps grow, a model's
## states, a town's map and its abstract model, the fetch-decode-execute cycle and inside a processor, a sound sampled,
## logic circuits, database tables, training examples, cyber threats, an app's screen; Monet's series of light, three
## kinds of brushwork, modern movements, the camera obscura, raster and vector, a portrait of symbols, a mural's grid, a
## lamp, a chair and two phones, animation frames, a mobile, a gallery's plan and a label; a jazz band, instruments'
## ranges and an opera house. Every sample draws at the School's picture sizes; broken data is a problem the content
## test finds; the rules the pictures draw by (steps, stops, gates, nearest points, the ball, turning, ranges, the parts'
## places) are checked here.

const SAMPLES: Array[Dictionary] = [
	{"kind": "structure_chart", "top": "Quiz game", "parts": [["Ask", ["Pick a question", "Show it"]], ["Check", ["Read the answer"]],
		["Score", []]]},
	{"kind": "structure_chart", "top": "Shop", "parts": [["Menu", []], ["Basket", ["Add", "Remove", "Total"]], ["Pay", ["Card"]],
		["Receipt", []]], "mark": "Total", "hide": "Pay"},
	{"kind": "step_growth", "lines": ["linear", "binary"], "upto": 64},
	{"kind": "step_growth", "lines": ["linear", "binary", "bubble"], "upto": 16, "at": 10},
	{"kind": "step_growth", "lines": ["bubble"], "upto": 4},
	{"kind": "state_machine", "states": ["red", "red and amber", "green", "amber"], "arrows": [[0, 1, "wait"], [1, 2, "wait"],
		[2, 3, "wait"], [3, 0, "wait"]], "current": 2},
	{"kind": "state_machine", "states": ["menu", "playing"], "arrows": [[0, 1, "tap PLAY"], [1, 0, "tap STOP"]], "mark": 1},
	{"kind": "state_machine", "states": ["idle", "walking", "jumping", "falling", "landed"], "arrows": [[0, 1, "move"],
		[1, 2, "jump"], [2, 3, "top"], [3, 4, "ground"], [4, 0, "stop"], [1, 0, "stop"], [0, 2, "jump"], [4, 1, "move"]]},
	{"kind": "abstract_map", "view": "real"},
	{"kind": "abstract_map", "view": "model", "route": ["Hill", "Park", "Market", "Castle"], "mark": "Castle"},
	{"kind": "abstract_map", "view": "real", "route": ["School", "Market", "Station"]},
	{"kind": "cpu_cycle", "view": "cycle"},
	{"kind": "cpu_cycle", "view": "cycle", "step": "decode"},
	{"kind": "cpu_cycle", "view": "machine", "memory": [[0, "LOAD 7"], [1, "ADD 5"], [2, "OUT"], [3, "HALT"]], "pc": 1, "acc": 7},
	{"kind": "cpu_cycle", "view": "machine", "memory": [[10, "12"], [11, "30"]], "labels": true, "mark": "ALU", "hide": "bus"},
	{"kind": "cpu_cycle", "view": "machine", "memory": [], "acc": "?"},
	{"kind": "sampled_wave", "samples": [4, 6, 7, 7, 6, 4, 2, 1, 0, 1, 2, 4], "bits": 3},
	{"kind": "sampled_wave", "samples": [1, 3, 3, 1, 0, 0], "bits": 2, "view": "steps", "wave": false},
	{"kind": "sampled_wave", "samples": [8, 12, 15, 14, 10, 5, 1, 0, 3, 8, 13, 15, 12, 7, 2, 0, 2, 7, 12, 15, 13, 9, 4, 1],
		"bits": 4, "view": "bars"},
	{"kind": "sampled_wave", "samples": [1, 0, 1, 0], "bits": 1},
	{"kind": "gate_circuit", "expr": ["AND", "A", "B"], "inputs": {"A": 1, "B": 0}},
	{"kind": "gate_circuit", "expr": ["NOT", "A"], "inputs": {"A": 0}, "lit": true},
	{"kind": "gate_circuit", "expr": ["OR", ["AND", "A", "B"], "C"], "inputs": {"A": 1, "B": 1, "C": 0}, "out": false},
	{"kind": "gate_circuit", "expr": ["AND", ["OR", "A", "B"], ["NOT", "C"]], "inputs": {"A": 0, "B": 1, "C": 0}, "lit": true},
	{"kind": "gate_circuit", "expr": ["NOT", ["OR", "A", ["NOT", "B"]]], "inputs": {"A": 0, "B": 1}},
	{"kind": "db_table", "name": "pets", "fields": ["id", "name", "animal", "age"], "rows": [[1, "Pip", "dog", 3],
		[2, "Mo", "cat", 7], [3, "Bobo", "rabbit", 2]], "key": 0},
	{"kind": "db_table", "name": "books", "fields": ["title", "pages"], "rows": [["Seas", "120"], ["Stars", "88"]],
		"pick": [1], "field": 1, "query": "SELECT title FROM books WHERE pages < 100"},
	{"kind": "scatter_learn", "axes": ["ear length", "weight (kg)"], "groups": ["cat", "rabbit"], "points": [[2, 4, 0],
		[3, 5, 0], [2.5, 3, 0], [7, 2, 1], [8, 3, 1], [7.5, 1.5, 1]], "new": [6, 3], "near": 3},
	{"kind": "scatter_learn", "axes": ["length", "width"], "groups": ["leaf A", "leaf B"], "points": [[1, 1, 0], [9, 9, 1]],
		"line": [0, 10, 10, 0]},
	{"kind": "threat_card", "threat": "virus", "name": true},
	{"kind": "threat_card", "threat": "worm"},
	{"kind": "threat_card", "threat": "trojan", "name": true},
	{"kind": "threat_card", "threat": "ransomware"},
	{"kind": "threat_card", "threat": "spyware", "name": true},
	{"kind": "threat_card", "threat": "phishing"},
	{"kind": "threat_card", "threat": "shoulder_surfing", "name": true},
	{"kind": "app_screen", "design": "clear"},
	{"kind": "app_screen", "design": "clear", "labels": true, "mark": "add button", "hide": "title"},
	{"kind": "app_screen", "design": "tiny"},
	{"kind": "app_screen", "design": "low_contrast"},
	{"kind": "app_screen", "design": "cluttered"},
	{"kind": "app_screen", "design": "colour_only"},
	{"kind": "app_screen", "design": "no_words"},
	{"kind": "light_series", "times": ["morning", "noon", "evening", "winter"], "names": true},
	{"kind": "light_series", "times": ["evening"]},
	{"kind": "light_series", "times": ["noon", "winter"]},
	{"kind": "brushwork", "style": "smooth"},
	{"kind": "brushwork", "style": "broken"},
	{"kind": "brushwork", "style": "dots"},
	{"kind": "movement_piece", "style": "realist"},
	{"kind": "movement_piece", "style": "cubist"},
	{"kind": "movement_piece", "style": "surreal"},
	{"kind": "movement_piece", "style": "pop"},
	{"kind": "movement_piece", "style": "fauve"},
	{"kind": "camera_obscura"},
	{"kind": "camera_obscura", "labels": true, "mark": "pinhole", "hide": "upside-down image"},
	{"kind": "raster_vector", "view": "raster", "zoom": true},
	{"kind": "raster_vector", "view": "vector", "zoom": true},
	{"kind": "raster_vector", "view": "raster"},
	{"kind": "symbol_portrait", "symbols": ["book", "ball", "music", "brush", "plant", "cat"], "names": true},
	{"kind": "symbol_portrait", "symbols": ["rocket", "home"], "mark": "home"},
	{"kind": "symbol_portrait"},
	{"kind": "grid_enlarge", "rows": ["YYB", "YRB", "GGG"], "key": {"Y": "yellow", "B": "blue", "R": "red", "G": "green"},
		"done": 4, "sizes": ["5 cm", "1 m"]},
	{"kind": "grid_enlarge", "rows": ["ab", "ba"], "key": {"a": "orange", "b": "light blue"}},
	{"kind": "object_design", "what": "lamp", "labels": true},
	{"kind": "object_design", "what": "chair", "labels": true, "mark": "frame"},
	{"kind": "object_design", "what": "dial_phone", "labels": true, "hide": "dial"},
	{"kind": "object_design", "what": "smartphone", "labels": true},
	{"kind": "object_design", "what": "lamp", "mark": "springs"},
	{"kind": "flip_frames", "count": 9, "ease": true, "squash": true},
	{"kind": "flip_frames", "count": 9},
	{"kind": "flip_frames", "count": 12, "view": "strip", "ease": true, "mark": 6},
	{"kind": "flip_frames", "count": 4, "view": "strip", "squash": true},
	{"kind": "mobile_balance", "left": [[3, 2]], "right": [[2, 3]]},
	{"kind": "mobile_balance", "left": [[4, 1], [2, 4]], "right": [[6, 2]], "hide": ["right", 0]},
	{"kind": "mobile_balance", "left": [[10, 5]], "right": [[1, 1]], "numbers": false},
	{"kind": "mobile_balance", "left": [[2, 5]], "right": [[3, 3]], "still": true},
	{"kind": "gallery_plan", "works": [["Sky", 0.2, 0.2], ["Sea", 0.8, 0.2], ["Stone", 0.5, 0.55]], "door": "bottom",
		"path": [2, 0, 1], "size": ["9 m", "6 m"]},
	{"kind": "gallery_plan", "works": [["one", 0.1, 0.1], ["two", 0.9, 0.9], ["three", 0.5, 0.5], ["four", 0.9, 0.1],
		["five", 0.1, 0.9], ["six", 0.5, 0.1]], "door": "left", "mark": 3},
	{"kind": "wall_label", "title": "Impression, Sunrise", "artist": "Claude Monet (1840-1926)", "date": "1872",
		"medium": "Oil on canvas", "size": "48 × 63 cm", "lines": ["Painted at the port of Le Havre,", "it gave a movement its name."]},
	{"kind": "wall_label", "title": "Tide", "artist": "Mimi", "date": "2026", "medium": "Blocks and paint"},
	{"kind": "jazz_band"},
	{"kind": "jazz_band", "labels": true, "mark": "saxophone", "hide": "double bass"},
	{"kind": "instrument_ranges", "instruments": ["flute", "violin", "cello", "double bass"], "note": "C2"},
	{"kind": "instrument_ranges", "instruments": ["soprano", "alto", "tenor", "bass"], "names": true, "mark": "tenor"},
	{"kind": "instrument_ranges", "instruments": ["clarinet", "trumpet", "trombone", "tuba", "viola", "violin"]},
	{"kind": "opera_house"},
	{"kind": "opera_house", "labels": true, "mark": "conductor", "hide": "surtitles"},
	{"kind": "swing_beats", "rows": ["straight", "swing"], "beats": 4},
	{"kind": "swing_beats", "rows": ["swing"], "beats": 2, "mark": 0},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126),
	ExerciseCheck.LABEL_BOX]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_and_variant_has_a_sample() -> void:
	var kinds := {}
	for d in SAMPLES:
		kinds[d.kind] = true
	for k: String in SchoolPictureG8Arts.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	var has := func(kind: String, key: String, value: String) -> bool:
		return SAMPLES.any(func(d: Dictionary) -> bool: return d.kind == kind and str(d.get(key, "")) == value)
	for t: String in SchoolPictureG8Arts.THREATS:
		assert_true(has.call("threat_card", "threat", t), "a %s" % t)
	for s: String in SchoolPictureG8Arts.SCREENS:
		assert_true(has.call("app_screen", "design", s), "a %s screen" % s)
	for s: String in SchoolPictureG8Arts.STYLES:
		assert_true(has.call("brushwork", "style", s), "%s brushwork" % s)
	for m: String in SchoolPictureG8Arts.MOVEMENTS:
		assert_true(has.call("movement_piece", "style", m), "a %s piece" % m)
	for o: String in SchoolPictureG8Arts.OBJECTS:
		assert_true(has.call("object_design", "what", o), "a %s" % o)
	for v: String in ["real", "model"]:
		assert_true(has.call("abstract_map", "view", v), "the %s map" % v)
	for v: String in ["cycle", "machine"]:
		assert_true(has.call("cpu_cycle", "view", v), "the %s view" % v)
	for v: String in ["raster", "vector"]:
		assert_true(has.call("raster_vector", "view", v), "a %s picture" % v)


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
			{"kind": "structure_chart", "top": "x", "parts": [["a", []]]},
			{"kind": "structure_chart", "top": "", "parts": [["a", []], ["b", []]]},
			{"kind": "structure_chart", "top": "x", "parts": [["a", ["1", "2", "3", "4"]], ["b", []]]},
			{"kind": "structure_chart", "top": "x", "parts": [["a", []], ["b", []]], "mark": "c"},
			{"kind": "step_growth", "lines": ["quick"], "upto": 10}, {"kind": "step_growth", "lines": ["linear"], "upto": 100},
			{"kind": "step_growth", "lines": ["linear", "linear"], "upto": 10},
			{"kind": "step_growth", "lines": ["linear"], "upto": 10, "at": 11},
			{"kind": "state_machine", "states": ["a"], "arrows": [[0, 0, "x"]]},
			{"kind": "state_machine", "states": ["a", "b"], "arrows": [[0, 0, "x"]]},
			{"kind": "state_machine", "states": ["a", "b"], "arrows": [[0, 2, "x"]]},
			{"kind": "state_machine", "states": ["a", "b"], "arrows": [[0, 1, "x"]], "current": 2},
			{"kind": "abstract_map", "view": "satellite"}, {"kind": "abstract_map", "view": "model", "mark": "Zoo"},
			{"kind": "abstract_map", "view": "model", "route": ["Hill", "Market"]},
			{"kind": "cpu_cycle", "view": "inside"}, {"kind": "cpu_cycle", "view": "cycle", "step": "store"},
			{"kind": "cpu_cycle", "view": "machine", "memory": [[0, "LOAD 7"]], "pc": 3},
			{"kind": "cpu_cycle", "view": "machine", "memory": [[100, "LOAD 7"]]},
			{"kind": "cpu_cycle", "view": "machine", "mark": "cache"},
			{"kind": "sampled_wave", "samples": [1, 2, 3], "bits": 2},
			{"kind": "sampled_wave", "samples": [1, 2, 3, 4], "bits": 2},
			{"kind": "sampled_wave", "samples": [1, 2, 3, 1], "bits": 5},
			{"kind": "sampled_wave", "samples": [1, 2, 3, 1], "bits": 2, "view": "lines"},
			{"kind": "gate_circuit", "expr": ["XOR", "A", "B"], "inputs": {"A": 1, "B": 0}},
			{"kind": "gate_circuit", "expr": ["AND", "A"], "inputs": {"A": 1}},
			{"kind": "gate_circuit", "expr": ["AND", "A", "B"], "inputs": {"A": 1}},
			{"kind": "gate_circuit", "expr": ["AND", "A", "B"], "inputs": {"A": 1, "B": 2}},
			{"kind": "gate_circuit", "expr": ["AND", ["OR", "A", "B"], ["AND", "C", ["NOT", "D"]]],
				"inputs": {"A": 1, "B": 0, "C": 1, "D": 0}},
			{"kind": "gate_circuit", "expr": "A", "inputs": {"A": 1}},
			{"kind": "db_table", "name": "t", "fields": ["a"], "rows": [["1"]]},
			{"kind": "db_table", "name": "t", "fields": ["a", "b"], "rows": [["1"]]},
			{"kind": "db_table", "name": "t", "fields": ["a", "b"], "rows": [["1", "2"]], "key": 2},
			{"kind": "db_table", "name": "t", "fields": ["a", "b"], "rows": [["1", "a value too long"]]},
			{"kind": "db_table", "name": "t", "fields": ["a", "b"], "rows": [["1", "2"]], "pick": [1]},
			{"kind": "scatter_learn", "axes": ["x"], "groups": ["a", "b"], "points": [[1, 1, 0], [2, 2, 1]]},
			{"kind": "scatter_learn", "axes": ["x", "y"], "groups": ["a", "b"], "points": [[1, 11, 0], [2, 2, 1]]},
			{"kind": "scatter_learn", "axes": ["x", "y"], "groups": ["a", "b"], "points": [[1, 1, 2], [2, 2, 1]]},
			{"kind": "scatter_learn", "axes": ["x", "y"], "groups": ["a", "b"], "points": [[1, 1, 0], [2, 2, 1]], "near": 1},
			{"kind": "threat_card", "threat": "spam"},
			{"kind": "app_screen", "design": "pretty"}, {"kind": "app_screen", "design": "tiny", "labels": true},
			{"kind": "app_screen", "design": "clear", "mark": "logo"},
			{"kind": "light_series", "times": []}, {"kind": "light_series", "times": ["night"]},
			{"kind": "brushwork", "style": "splash"}, {"kind": "movement_piece", "style": "baroque"},
			{"kind": "camera_obscura", "mark": "lens"}, {"kind": "raster_vector", "view": "both"},
			{"kind": "symbol_portrait", "symbols": ["crown"]}, {"kind": "symbol_portrait", "symbols": ["cat", "cat"]},
			{"kind": "symbol_portrait", "symbols": ["cat"], "mark": "dog"},
			{"kind": "grid_enlarge", "rows": ["ab"], "key": {"a": "red", "b": "blue"}},
			{"kind": "grid_enlarge", "rows": ["ab", "a"], "key": {"a": "red", "b": "blue"}},
			{"kind": "grid_enlarge", "rows": ["ab", "ac"], "key": {"a": "red", "b": "blue"}},
			{"kind": "grid_enlarge", "rows": ["ab", "ba"], "key": {"a": "red", "b": "gold"}},
			{"kind": "grid_enlarge", "rows": ["ab", "ba"], "key": {"a": "red", "b": "blue"}, "done": 5},
			{"kind": "object_design", "what": "kettle"}, {"kind": "object_design", "what": "lamp", "mark": "screen"},
			{"kind": "flip_frames", "count": 3}, {"kind": "flip_frames", "count": 13},
			{"kind": "flip_frames", "count": 6, "mark": 6}, {"kind": "flip_frames", "count": 6, "view": "film"},
			{"kind": "mobile_balance", "left": [], "right": [[1, 1]]},
			{"kind": "mobile_balance", "left": [[11, 1]], "right": [[1, 1]]},
			{"kind": "mobile_balance", "left": [[1, 6]], "right": [[1, 1]]},
			{"kind": "mobile_balance", "left": [[1, 2], [3, 2]], "right": [[1, 1]]},
			{"kind": "mobile_balance", "left": [[1, 2]], "right": [[1, 1]], "hide": ["right", 1]},
			{"kind": "gallery_plan", "works": [], "door": "bottom"},
			{"kind": "gallery_plan", "works": [["a", 0.0, 0.5]], "door": "bottom"},
			{"kind": "gallery_plan", "works": [["a", 0.5, 0.5]], "door": "roof"},
			{"kind": "gallery_plan", "works": [["a", 0.5, 0.5]], "door": "left", "path": [1]},
			{"kind": "wall_label", "title": "", "artist": "a", "date": "1", "medium": "m"},
			{"kind": "wall_label", "title": "t", "artist": "a", "date": "1", "medium": "m", "lines": ["1", "2", "3", "4"]},
			{"kind": "jazz_band", "mark": "violin"}, {"kind": "jazz_band", "labels": "yes"},
			{"kind": "instrument_ranges", "instruments": ["kazoo"]}, {"kind": "instrument_ranges", "instruments": []},
			{"kind": "instrument_ranges", "instruments": ["flute"], "note": "C9"},
			{"kind": "instrument_ranges", "instruments": ["flute"], "mark": "cello"},
			{"kind": "opera_house", "hide": "balcony"}, {"kind": "swing_beats", "rows": ["shuffle"], "beats": 4},
			{"kind": "swing_beats", "rows": ["swing"], "beats": 5}, {"kind": "swing_beats", "rows": ["swing", "swing"], "beats": 4},
			{"kind": "swing_beats", "rows": ["swing"], "beats": 4, "mark": 1}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## Worst-case steps: linear n, binary ⌊log₂ n⌋ + 1, bubble sort n(n − 1) ÷ 2 comparisons.
func test_the_steps() -> void:
	assert_eq(SchoolPictureG8Arts.steps_for("linear", 16), 16)
	assert_eq(SchoolPictureG8Arts.steps_for("binary", 16), 5)
	assert_eq(SchoolPictureG8Arts.steps_for("binary", 15), 4)
	assert_eq(SchoolPictureG8Arts.steps_for("binary", 1000), 10)
	assert_eq(SchoolPictureG8Arts.steps_for("binary", 1), 1)
	assert_eq(SchoolPictureG8Arts.steps_for("bubble", 10), 45)
	assert_eq(SchoolPictureG8Arts.steps_for("bubble", 4), 6)


## The model railway: Hill to Harbour along the red line, the blue line crossing at Market.
func test_the_stops() -> void:
	assert_eq(SchoolPictureG8Arts.stops_between("Hill", "Harbour"), 4)
	assert_eq(SchoolPictureG8Arts.stops_between("Hill", "Castle"), 3)
	assert_eq(SchoolPictureG8Arts.stops_between("School", "Castle"), 2)
	assert_eq(SchoolPictureG8Arts.stops_between("Park", "Park"), 0)
	assert_eq(SchoolPictureG8Arts.stops_between("Park", "Zoo"), -1)
	for s: String in SchoolPictureG8Arts.STOPS:
		assert_true(SchoolPictureG8Arts.REAL_AT.has(s) and SchoolPictureG8Arts.MODEL_AT.has(s), s)


func test_the_gates() -> void:
	var out := func(e: Variant, a: int, b: int, c: int = 0) -> int:
		return SchoolPictureG8Arts.circuit_out(e, {"A": a, "B": b, "C": c})
	assert_eq(out.call(["AND", "A", "B"], 1, 1), 1)
	assert_eq(out.call(["AND", "A", "B"], 1, 0), 0)
	assert_eq(out.call(["OR", "A", "B"], 0, 1), 1)
	assert_eq(out.call(["OR", "A", "B"], 0, 0), 0)
	assert_eq(out.call(["NOT", "A"], 0, 0), 1)
	assert_eq(out.call(["OR", ["AND", "A", "B"], "C"], 1, 0, 1), 1)
	assert_eq(out.call(["AND", ["OR", "A", "B"], ["NOT", "C"]], 0, 1, 1), 0)
	assert_eq(out.call(["NOT", ["OR", "A", ["NOT", "B"]]], 0, 1), 1)
	assert_eq(SchoolPictureG8Arts.circuit_out(["AND", "A", "B"], {"A": 1}), -1)
	assert_eq(SchoolPictureG8Arts.circuit_letters(["OR", ["AND", "A", "B"], ["NOT", "A"]]), ["A", "B"] as Array[String])


func test_the_nearest_points() -> void:
	var pts := [[2, 4, 0], [3, 5, 0], [2.5, 3, 0], [7, 2, 1], [8, 3, 1], [7.5, 1.5, 1]]
	assert_eq(SchoolPictureG8Arts.nearest(pts, 6, 3, 1), [3] as Array[int])
	assert_eq(SchoolPictureG8Arts.nearest(pts, 6, 3, 3), [3, 4, 5] as Array[int])
	assert_eq(SchoolPictureG8Arts.nearest([[1, 1, 0], [3, 1, 1]], 2, 1, 1), [0] as Array[int], "a tie: the earlier point")


## The ball falls to the ground in the middle frame; with easing it moves less near the top than at the bottom.
func test_the_bouncing_ball() -> void:
	assert_almost_eq(SchoolPictureG8Arts.ball_at(4, 9, true).y, 0.86, 0.001)
	assert_almost_eq(SchoolPictureG8Arts.ball_at(0, 9, true).y, 0.16, 0.001)
	var top_step := SchoolPictureG8Arts.ball_at(1, 9, true).y - SchoolPictureG8Arts.ball_at(0, 9, true).y
	var low_step := SchoolPictureG8Arts.ball_at(4, 9, true).y - SchoolPictureG8Arts.ball_at(3, 9, true).y
	assert_lt(top_step, low_step, "slow in at the top, fast at the bottom")
	var even_top := SchoolPictureG8Arts.ball_at(1, 9, false).y - SchoolPictureG8Arts.ball_at(0, 9, false).y
	var even_low := SchoolPictureG8Arts.ball_at(4, 9, false).y - SchoolPictureG8Arts.ball_at(3, 9, false).y
	assert_almost_eq(even_top, even_low, 0.0001, "one speed all the way")


func test_the_mobile_turns() -> void:
	assert_eq(SchoolPictureG8Arts.turning({"left": [[3, 2]], "right": [[2, 3]]}), 0)
	assert_eq(SchoolPictureG8Arts.turning({"left": [[4, 1], [2, 4]], "right": [[6, 2]]}), 0)
	assert_eq(SchoolPictureG8Arts.turning({"left": [[10, 5]], "right": [[1, 1]]}), 49)


func test_the_ranges() -> void:
	assert_eq(SchoolPictureG8Arts.pitch_of("C4"), 48)
	assert_eq(SchoolPictureG8Arts.pitch_of("Bb3"), 46)
	assert_eq(SchoolPictureG8Arts.pitch_of("F#2"), 30)
	assert_eq(SchoolPictureG8Arts.pitch_of("H2"), -1)
	assert_eq(SchoolPictureG8Arts.range_of("cello"), [24, 69] as Array[int])
	assert_eq(SchoolPictureG8Arts.range_of("kazoo"), [] as Array[int])
	for name: String in SchoolPictureG8Arts.RANGE_NAMES:
		var rg := SchoolPictureG8Arts.range_of(name)
		assert_lt(rg[0], rg[1], name)


## Every labelled part lies inside the label box's drawing area, and parts of one picture are apart.
func test_the_parts_are_in_the_picture() -> void:
	var inner := Rect2(Vector2.ONE * SchoolPicture.MARGIN, ExerciseCheck.LABEL_BOX - Vector2(2, 2) * SchoolPicture.MARGIN)
	var pictures: Array[Dictionary] = [{"kind": "cpu_cycle", "view": "machine"}, {"kind": "camera_obscura"},
		{"kind": "jazz_band"}, {"kind": "opera_house"}, {"kind": "app_screen", "design": "clear"}]
	for o: String in SchoolPictureG8Arts.OBJECTS:
		pictures.append({"kind": "object_design", "what": o})
	for p in pictures:
		var parts: Dictionary = SchoolPictureG8Arts._anchor_table(p)
		assert_false(parts.is_empty(), str(p))
		var seen: Array[Vector2] = []
		for part: String in parts:
			var at := SchoolPictureG8Arts.part_at(p, part, ExerciseCheck.LABEL_BOX)
			assert_true(inner.has_point(at), "%s: %s inside" % [p, part])
			for other in seen:
				assert_gt(at.distance_to(other), 12.0, "%s: %s apart from the others" % [p, part])
			seen.append(at)
	assert_eq(SchoolPictureG8Arts.part_at({"kind": "cpu_cycle", "view": "cycle"}, "ALU", ExerciseCheck.LABEL_BOX),
		Vector2(-1, -1), "the cycle view has no parts")
	assert_eq(SchoolPictureG8Arts.part_at({"kind": "app_screen", "design": "tiny"}, "title", ExerciseCheck.LABEL_BOX),
		Vector2(-1, -1), "only the clear screen names its parts")
