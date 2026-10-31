extends GutTest
## Owner #96 (spec §5.12b, the Reel Studio): a 3D stage and a video are checked like every Short's data: the models the
## game can build, moves it knows, cameras that ease, effects that follow a model that is there, a video's file name.


func _stage() -> Dictionary:
	return {"sky": "space", "light": "space", "models": [
		{"id": "earth", "model": "planet", "body": "earth", "at": [0, 0, 0], "size": 6, "moves": [
			{"do": "spin", "at": 0, "rate": 0.05}]},
		{"id": "rocket", "model": "rocket", "rocket": "moon", "at": [0, 0, -20], "moves": [
			{"do": "move", "at": 1, "dur": 4, "to": [0, 30, -20], "ease": "in"}, {"do": "stage", "at": 3, "stage": 0}]}],
		"effects": [{"kind": "flame", "on": "rocket", "from": 1, "to": 5}],
		"camera": [{"at": 0, "pos": [0, 5, 30], "look": [0, 0, 0], "fov": 45},
			{"at": 4, "pos": [20, 8, 20], "look": [0, 0, 0], "path": "orbit"}]}


func test_a_good_stage_has_no_problem() -> void:
	assert_eq(Scene3DKind.stage_problem(_stage()), "")


func test_the_stage_s_parts_are_checked() -> void:
	var cases := {
		"sky": func(s: Dictionary) -> void: s.sky = "purple haze",
		"light": func(s: Dictionary) -> void: s.light = "disco",
		"model kind": func(s: Dictionary) -> void: s.models[0].model = "castle",
		"body": func(s: Dictionary) -> void: s.models[0].body = "vulcan",
		"rocket": func(s: Dictionary) -> void: s.models[1].rocket = "banana",
		"same id": func(s: Dictionary) -> void: s.models[1].id = "earth",
		"move": func(s: Dictionary) -> void: s.models[1].moves[0].do = "teleport",
		"move to": func(s: Dictionary) -> void: s.models[1].moves[0].erase("to"),
		"stage on a planet": func(s: Dictionary) -> void: s.models[0].moves.append({"do": "stage", "at": 1, "stage": 0}),
		"effect kind": func(s: Dictionary) -> void: s.effects[0].kind = "lasers",
		"effect on": func(s: Dictionary) -> void: s.effects[0].on = "ufo",
		"effect time": func(s: Dictionary) -> void: s.effects[0].to = 0.5,
		"camera": func(s: Dictionary) -> void: s.camera = [],
		"camera pos": func(s: Dictionary) -> void: s.camera[0].erase("pos"),
		"camera fov": func(s: Dictionary) -> void: s.camera[0].fov = 170,
		"camera path": func(s: Dictionary) -> void: s.camera[1].path = "spiral",
		"camera follow": func(s: Dictionary) -> void: s.camera[1].follow = "ufo",
		"far away": func(s: Dictionary) -> void: s.models[0].at = [0, 99999, 0],
	}
	for what: String in cases:
		var s := _stage().duplicate(true)
		(cases[what] as Callable).call(s)
		assert_ne(Scene3DKind.stage_problem(s), "", "%s is checked" % what)


func test_the_style_guide_holds_in_3d() -> void:
	var s := _stage().duplicate(true)
	s.camera[1].ease = "linear"
	s.camera[1].path = "line"
	assert_string_contains(Scene3DKind.stage_problem(s), "ease", "no camera glides at a constant speed (but an orbit)")
	s = _stage().duplicate(true)
	s.camera[1].at = 0.2
	assert_string_contains(Scene3DKind.stage_problem(s), "0.4", "a camera move lasts 12 frames at least")
	s = _stage().duplicate(true)
	s.camera[1].cut = true
	s.camera[1].at = 0.2
	assert_eq(Scene3DKind.stage_problem(s), "", "a cut is a new shot, any time")


func test_a_scene3d_actor_holds_a_stage_in_its_box() -> void:
	var a := {"kind": "scene3d", "at": [180, 220], "w": 320, "h": 380, "stage": _stage()}
	assert_eq(Scene3DKind.problem(a), "")
	var no_stage := a.duplicate(true)
	no_stage.erase("stage")
	assert_ne(Scene3DKind.problem(no_stage), "")
	var big := a.duplicate(true)
	big.w = 900
	assert_ne(Scene3DKind.problem(big), "")


func test_a_video_actor_names_its_file_and_where_it_starts() -> void:
	assert_eq(VideoKind.problem({"kind": "video", "at": [180, 200], "file": "rocket_launch", "w": 300, "h": 170}), "")
	assert_ne(VideoKind.problem({"kind": "video", "at": [180, 200]}), "", "a file")
	assert_ne(VideoKind.problem({"kind": "video", "at": [180, 200], "file": "../secret"}), "", "a plain name")
	assert_ne(VideoKind.problem({"kind": "video", "at": [180, 200], "file": "a_b", "start": -1}), "", "start >= 0")


func test_both_kinds_are_registered_and_the_checker_uses_them() -> void:
	assert_true(ShortKinds.has("scene3d"))
	assert_true(ShortKinds.has("video"))
	var short := {"id": "stage_test", "title": "A stage", "topic": "space", "link": {"star_map": true}, "scenes": []}
	for i in 3:
		short.scenes.append({"seconds": 8, "background": "space", "caption": "Look.", "say": "Look at it.", "actors": [
			{"kind": "scene3d", "at": [180, 220], "w": 320, "h": 380, "stage": _stage()}]})
	short.scenes[2].caption = "What do you see?"
	assert_eq(ShortCheck.problems(short), [] as Array[String])
	short.scenes[1].actors[0].stage.sky = "nope"
	assert_string_contains("\n".join(ShortCheck.problems(short)), "sky")


func test_a_short_s_own_stage_and_video_are_checked() -> void:
	var short := {"id": "stage_test", "title": "A stage", "topic": "space", "link": {"star_map": true},
		"stage": _stage(), "video": "stage_test", "scenes": []}
	for i in 3:
		short.scenes.append({"seconds": 8, "background": "space", "caption": "Look.", "say": "Look at it."})
	short.scenes[2].caption = "What do you see?"
	assert_eq(ShortCheck.problems(short), [] as Array[String])
	short.video = "no way"
	assert_string_contains("\n".join(ShortCheck.problems(short)), "video")
	short.video = "stage_test"
	short.stage.models[0].model = "castle"
	assert_string_contains("\n".join(ShortCheck.problems(short)), "castle")
	short.stage = _stage()
	short.stage.effects[0].to = 40
	assert_string_contains("\n".join(ShortCheck.problems(short)), "after", "the stage's times fit the Short")
