extends GutTest
## Grade 5 health and PE, design and technology, and projects: the picture kinds they add (SchoolPictureG5Life, drawn
## inside SchoolPicture): a net game's court from above (players, target spots, a shot), gears that mesh and pulleys on a
## belt or lifting a load, a cam turning under its follower (with the follower's rise over a turn), bridges seen from the
## side (with their squashing and stretching forces), a block model and its plan, front and side views, a compass rose
## with a bearing, a food web, and a person lying in the recovery position. Every kind draws from its data at the School's
## picture sizes; broken data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "net_court", "players": [[3, 3, "a"], [9, 1.5, "d"]]},
	{"kind": "net_court", "sport": "tennis", "players": [[1, 4.5, "a", "Z"], [10, 3, "d"]], "spots": [[7, 0.8, "A"],
		[7, 5.2, "B"], [11.2, 0.8, "C"], [11.2, 5.2, "D"]], "shot": [0, 1]},
	{"kind": "net_court", "sport": "volleyball", "players": [[2, 1.5, "a"], [2, 4.5, "a"], [4.5, 3, "a"], [8, 3, "d"]]},
	{"kind": "net_court", "sport": "badminton", "players": [[2.5, 3, "a"]], "spots": [[6.7, 3, "A"]]},
	{"kind": "gears", "gears": [10, 30], "turn": "cw"},
	{"kind": "gears", "gears": [20, 10, 20, 40], "turn": "acw", "arrows": "all", "labels": ["driver", "idler", "C",
		"D"]},
	{"kind": "gears", "gears": [16], "marks": true},
	{"kind": "gears", "gears": [8, 24, 12], "turn": "cw", "marks": true},
	{"kind": "pulleys", "sizes": [2, 6], "turn": "cw"},
	{"kind": "pulleys", "sizes": [5, 5], "turn": "acw", "crossed": true, "arrows": "all", "labels": ["A", "B"]},
	{"kind": "pulleys", "lift": 1, "labels": true},
	{"kind": "pulleys", "lift": 2},
	{"kind": "cam", "shape": "round"},
	{"kind": "cam", "shape": "pear", "turn": 90, "labels": true},
	{"kind": "cam", "shape": "snail", "turn": 200, "graph": true},
	{"kind": "cam", "shape": "oval", "turn": 45, "graph": true, "labels": true},
	{"kind": "bridge", "type": "beam"},
	{"kind": "bridge", "type": "beam", "spans": 3, "load": 0.3, "forces": true, "labels": true},
	{"kind": "bridge", "type": "arch", "forces": true, "labels": true},
	{"kind": "bridge", "type": "truss", "spans": 2, "load": 0.7, "mark": "truss"},
	{"kind": "bridge", "type": "suspension", "labels": true, "forces": true},
	{"kind": "bridge", "type": "cable_stayed", "mark": "cable"},
	{"kind": "views", "heights": ["2100", "1110", "3000"], "show": "model"},
	{"kind": "views", "heights": ["2100", "1110", "3000"], "show": "plan", "numbers": true, "label": true},
	{"kind": "views", "heights": ["2100", "1110", "3000"], "show": "front", "label": true},
	{"kind": "views", "heights": ["2100", "1110", "3000"], "show": "side"},
	{"kind": "views", "heights": ["5"], "show": "model"},
	{"kind": "compass"},
	{"kind": "compass", "points": 8, "bearing": 135, "degrees": true},
	{"kind": "compass", "points": 8, "hide": "SW", "needle": true},
	{"kind": "compass", "points": 4, "bearing": 270, "hide": "W"},
	{"kind": "food_web", "nodes": [["grass", 0, 3], ["rabbit", 0, 2], ["fox", 1, 1]], "links": [[0, 1], [1, 2]]},
	{"kind": "food_web", "nodes": [["cactus", 0, 3], ["seeds", 2, 3], ["grasshopper", 0, 2], ["kangaroo rat", 2, 2],
		["lizard", 1, 1], ["rattlesnake", 3, 1], ["hawk", 2, 0]], "links": [[0, 2], [1, 3], [2, 4], [3, 5], [4, 5],
		[4, 6], [5, 6]], "mark": 5, "hide": 6},
	{"kind": "lying", "pose": "back"},
	{"kind": "lying", "pose": "recovery", "labels": true},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_sport_shape_type_view_and_pose_has_a_sample() -> void:
	var seen := {}
	for d in SAMPLES:
		seen[str(d.kind)] = true
		for k: String in ["sport", "shape", "type", "show", "pose"]:
			if d.has(k):
				seen["%s:%s" % [k, d[k]]] = true
	for k: String in SchoolPictureG5Life.KINDS:
		assert_true(seen.has(k), "a sample of %s" % k)
	for s: String in SchoolPictureG5Life.SPORTS:
		assert_true(seen.has("sport:" + s), "a sample of the court %s" % s)
	for s: String in SchoolPictureG5Life.CAMS:
		assert_true(seen.has("shape:" + s), "a sample of the %s cam" % s)
	for t: String in SchoolPictureG5Life.BRIDGES:
		assert_true(seen.has("type:" + t), "a sample of the %s bridge" % t)
	for v: String in SchoolPictureG5Life.VIEWS:
		assert_true(seen.has("show:" + v), "a sample of the %s view" % v)
	for p: String in SchoolPictureG5Life.LYING:
		assert_true(seen.has("pose:" + p), "a sample of lying on the %s" % p)


func test_every_sample_draws_at_every_size() -> void:
	for px in SIZES:
		for d in SAMPLES:
			var p := SchoolPicture.new(d, px)
			p.size = px
			add_child_autofree(p)
	await wait_process_frames(2)
	assert_true(true, "drawn without script errors")


## The rules the pictures draw by, which the lessons teach: meshing gears turn opposite ways (an idler makes the last
## turn like the first), a crossed belt turns the other pulley the other way, the round cam lifts its follower once a
## turn and the oval twice, the snail rises slowly and drops at once, and a model's front view is its tallest block in
## each column, its side view in each row.
func test_the_pictures_follow_the_rules_they_teach() -> void:
	assert_eq(SchoolPictureG5Life.gear_turns("cw", 3), ["cw", "acw", "cw"])
	assert_eq(SchoolPictureG5Life.gear_turns("acw", 2), ["acw", "cw"])
	assert_eq(SchoolPictureG5Life.pulley_turns("cw", false), ["cw", "cw"])
	assert_eq(SchoolPictureG5Life.pulley_turns("cw", true), ["cw", "acw"])
	for shape: String in SchoolPictureG5Life.CAMS:
		var rises := 0
		var last := SchoolPictureG5Life.cam_height(shape, 0.0)
		var going_up := false
		for deg in range(2, 362, 2):
			var h := SchoolPictureG5Life.cam_height(shape, float(deg))
			if h > last + 0.0005 and not going_up:
				rises += 1
				going_up = true
			elif h < last - 0.0005:
				going_up = false
			last = h
		assert_eq(rises, 2 if shape == "oval" else 1, "the %s cam's rises in a turn" % shape)
	var snail_drop := SchoolPictureG5Life.cam_height("snail", 359.0) - SchoolPictureG5Life.cam_height("snail", 1.0)
	assert_gt(snail_drop, 0.4, "the snail cam drops at once at the end of its turn")
	assert_eq(SchoolPictureG5Life.front_view(["2100", "1110", "3000"]), [3, 1, 1, 0])
	assert_eq(SchoolPictureG5Life.side_view(["2100", "1110", "3000"]), [3, 1, 2])


func test_broken_pictures_are_problems() -> void:
	for d: Dictionary in [
			{"kind": "net_court"}, {"kind": "net_court", "players": []},
			{"kind": "net_court", "players": [[13, 3, "a"]]}, {"kind": "net_court", "players": [[3, 3, "b"]]},
			{"kind": "net_court", "players": [[3, 3, "a"]], "sport": "squash"},
			{"kind": "net_court", "players": [[3, 3, "a"]], "spots": [[7, 7, "A"]]},
			{"kind": "net_court", "players": [[3, 3, "a"]], "spots": [[7, 3, "ABC"]]},
			{"kind": "net_court", "players": [[3, 3, "a"]], "spots": [[7, 3, "A"]], "shot": [1, 0]},
			{"kind": "net_court", "players": [[3, 3, "a"]], "shot": [0, 0]},
			{"kind": "gears"}, {"kind": "gears", "gears": []}, {"kind": "gears", "gears": [4]},
			{"kind": "gears", "gears": [10, 10, 10, 10, 10]}, {"kind": "gears", "gears": [10, 20], "turn": "up"},
			{"kind": "gears", "gears": [10, 20], "arrows": "some"}, {"kind": "gears", "gears": [10, 20], "labels": ["a"]},
			{"kind": "gears", "gears": [10, 20], "labels": ["a", "a label too long"]},
			{"kind": "pulleys"}, {"kind": "pulleys", "sizes": [2]}, {"kind": "pulleys", "sizes": [2, 0]},
			{"kind": "pulleys", "sizes": [2, 3, 4]}, {"kind": "pulleys", "lift": 3},
			{"kind": "pulleys", "sizes": [2, 3], "lift": 1}, {"kind": "pulleys", "sizes": [2, 3], "crossed": "yes"},
			{"kind": "cam"}, {"kind": "cam", "shape": "square"}, {"kind": "cam", "shape": "round", "turn": 400},
			{"kind": "cam", "shape": "round", "graph": 1},
			{"kind": "bridge"}, {"kind": "bridge", "type": "rope"}, {"kind": "bridge", "type": "beam", "spans": 5},
			{"kind": "bridge", "type": "arch", "spans": 2}, {"kind": "bridge", "type": "beam", "load": 2},
			{"kind": "bridge", "type": "beam", "mark": "cable"},
			{"kind": "views"}, {"kind": "views", "heights": [], "show": "plan"},
			{"kind": "views", "heights": ["12", "1"], "show": "plan"}, {"kind": "views", "heights": ["19"], "show": "plan"},
			{"kind": "views", "heights": ["00"], "show": "plan"}, {"kind": "views", "heights": ["12"], "show": "top"},
			{"kind": "views", "heights": ["123456"], "show": "plan"},
			{"kind": "compass", "points": 16}, {"kind": "compass", "bearing": 360}, {"kind": "compass", "hide": "NNE"},
			{"kind": "compass", "points": 4, "hide": "NE"},
			{"kind": "food_web"}, {"kind": "food_web", "nodes": [["grass", 0, 3]], "links": []},
			{"kind": "food_web", "nodes": [["grass", 0, 3], ["rabbit", 0, 3]], "links": [[0, 1]]},
			{"kind": "food_web", "nodes": [["grass", 0, 3], ["rabbit", 0, 5]], "links": [[0, 1]]},
			{"kind": "food_web", "nodes": [["grass", 0, 3], ["a very long name", 0, 2]], "links": [[0, 1]]},
			{"kind": "food_web", "nodes": [["grass", 0, 3], ["rabbit", 0, 2]], "links": [[0, 2]]},
			{"kind": "food_web", "nodes": [["grass", 0, 3], ["rabbit", 0, 2]], "links": [[1, 1]]},
			{"kind": "food_web", "nodes": [["grass", 0, 3], ["rabbit", 0, 2]], "links": [[0, 1]], "hide": 4},
			{"kind": "lying"}, {"kind": "lying", "pose": "front"}, {"kind": "lying", "pose": "back", "labels": "yes"}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))
