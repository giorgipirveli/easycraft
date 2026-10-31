extends GutTest
## Grade 3 health and PE, design and technology, and projects: the picture kinds they add (SchoolPictureLife, drawn inside
## SchoolPicture): a net of squares (cube nets, faces lettered), the balanced plate of food groups, a lever with its
## pivot, load and effort, frames (a square that squashes, one braced with triangles), a weave of over and under, a
## running stitch, backstitch and overstitch, and stick figures showing how to run, jump, throw, catch and balance. Every
## kind draws from its data at the School's picture sizes; broken data is a problem the content test finds.

const SAMPLES: Array[Dictionary] = [
	{"kind": "net", "rows": [".#..", "####", ".#.."]},
	{"kind": "net", "rows": ["A#..", ".BC#", "..#."]},
	{"kind": "net", "rows": ["######"]},
	{"kind": "net", "rows": ["#", "#", "#", "#", "#", "#"]},
	{"kind": "plate"},
	{"kind": "plate", "hide": "protein", "water": false},
	{"kind": "lever", "pivot": 5, "load": 1, "effort": 9},
	{"kind": "lever", "pivot": 0, "load": 3, "effort": 10, "tags": {"pivot": "A", "load": "B", "effort": "C"}},
	{"kind": "frame", "frames": ["square", "braced"]},
	{"kind": "frame", "frames": ["pushed", "triangle", "braced"], "labels": ["A", "B", "C"]},
	{"kind": "weave", "rows": ["ouou", "uouo", "ouou", "uouo"]},
	{"kind": "weave", "rows": ["ouououou", "uouououo", "ouououou"], "weft": ["red", "blue"], "numbers": true},
	{"kind": "stitch", "what": "running"},
	{"kind": "stitch", "what": "back"},
	{"kind": "stitch", "what": "over"},
	{"kind": "pose", "poses": ["run"]},
	{"kind": "pose", "poses": ["crouch", "jump", "land"], "labels": ["1", "2", "3"]},
	{"kind": "pose", "poses": ["throw", "catch"]},
	{"kind": "pose", "poses": ["star", "stork", "tuck", "stretch"]},
	{"kind": "pose", "poses": ["stand", "clap"], "labels": ["ready", "clap!"]},
]
const SIZES: Array[Vector2] = [Vector2(580, 250), Vector2(560, 380), Vector2(480, 280), Vector2(248, 126)]


func test_every_sample_is_valid() -> void:
	for d in SAMPLES:
		assert_eq(SchoolPicture.problem(d), "", str(d))


func test_every_kind_and_pose_has_a_sample() -> void:
	var kinds := {}
	var poses := {}
	for d in SAMPLES:
		kinds[d.kind] = true
		for p: String in d.get("poses", []):
			poses[p] = true
	for k: String in SchoolPictureLife.KINDS:
		assert_true(kinds.has(k), "a sample of %s" % k)
	for p: String in SchoolPictureLife.POSES:
		assert_true(poses.has(p), "a sample of the pose %s" % p)
	assert_eq(kinds.size(), SchoolPictureLife.KINDS.size())


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
			{"kind": "net"}, {"kind": "net", "rows": []}, {"kind": "net", "rows": ["...."]},
			{"kind": "net", "rows": ["##", "#"]}, {"kind": "net", "rows": ["#x#"]}, {"kind": "net", "rows": ["#######"]},
			{"kind": "net", "rows": ["#", "#", "#", "#", "#", "#", "#"]},
			{"kind": "plate", "hide": "sweets"},
			{"kind": "lever", "pivot": 5, "load": 5, "effort": 9}, {"kind": "lever", "pivot": 11, "load": 1, "effort": 9},
			{"kind": "lever", "load": 1, "effort": 9}, {"kind": "lever", "pivot": 5, "load": 1, "effort": 9,
				"tags": {"pivot": "a very long tag here"}},
			{"kind": "frame"}, {"kind": "frame", "frames": []}, {"kind": "frame", "frames": ["circle"]},
			{"kind": "frame", "frames": ["square", "square", "square", "square"]},
			{"kind": "frame", "frames": ["square"], "labels": ["A", "B"]},
			{"kind": "weave", "rows": ["ouou", "uou"]}, {"kind": "weave", "rows": ["oxou"]}, {"kind": "weave", "rows": ["o"]},
			{"kind": "weave", "rows": ["ou", "uo", "ou", "uo", "ou", "uo", "ou"]},
			{"kind": "weave", "rows": ["ouou"], "weft": ["gold"]},
			{"kind": "stitch", "what": "zigzag"}, {"kind": "stitch"},
			{"kind": "pose"}, {"kind": "pose", "poses": []}, {"kind": "pose", "poses": ["fly"]},
			{"kind": "pose", "poses": ["run", "run", "run", "run", "run"]},
			{"kind": "pose", "poses": ["run"], "labels": ["a label that is far too long"]},
			{"kind": "pose", "poses": ["run", "jump"], "labels": ["1"]}]:
		assert_ne(SchoolPicture.problem(d), "", str(d))


## A pose is a stick figure: every joint is there, the feet of a figure on the ground touch it, and a jump is off it.
func test_the_poses_are_whole_figures() -> void:
	for name: String in SchoolPictureLife.POSES:
		var pose: Dictionary = SchoolPictureLife.POSES[name]
		for j: String in SchoolPictureLife.JOINTS:
			assert_true(pose.has(j), "%s has its %s" % [name, j])
		var lowest := minf(pose.lf.y, pose.rf.y)
		if name == "jump":
			assert_gt(lowest, 0.05, "a jump is in the air")
		elif name != "tuck":
			assert_almost_eq(lowest, 0.0, 0.07, "%s stands on the ground" % name)
