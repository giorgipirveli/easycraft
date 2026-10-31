extends GutTest
## Owner #122 (docs/design/learning-is-play.md §5.1; spec §22.0): every exercise type is played in the play arena by its
## mechanic's station: things to tap, carry and put (flat: a finger; VR: the hands, the laser). Driven here through the
## station's own taps: the coach's ghost steps always lead to a right answer (ExerciseCheck), the worked answer shown is
## right, a miss sends the things home where the School's own answers cleared, everything to tap is on the screen from
## the station's view and within a child's reach in VR, and every material is one the game already warms.

const SAMPLES := {
	"number tower": {"type": "number", "prompt": "How many cubes?", "answer": "12", "hint": "Count."},
	"number base ten": {"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Parts."},
	"number decimal": {"type": "number", "prompt": "3 + 0.75 = ?", "answer": "3.75", "hint": "Tenths."},
	"number coins": {"type": "number", "prompt": "Tilly pays 65 gold from 100 gold. How much change?", "answer": "35",
		"hint": "Count up."},
	"number jug": {"type": "number", "prompt": "How many ml are left?", "answer": "750", "hint": "Take away."},
	"number scale": {"type": "number", "prompt": "How many g does it weigh?", "answer": "450", "hint": "Add."},
	"number fraction": {"type": "number", "prompt": "1/2 + 1/4 = ?", "answer": "3/4", "hint": "Quarters."},
	"number frog": {"type": "number", "prompt": "5 - 17 = ?", "answer": "-12", "hint": "Below zero."},
	"number dial": {"type": "number", "prompt": "Write 2 out of 97 as a fraction.", "answer": "2/97", "hint": "Out of 97."},
	"sort": {"type": "sort", "prompt": "Living or not?", "hint": "Does it grow?", "groups": ["living", "not living"],
		"items": ["a tree", "a rock", "a frog", "a cloud"], "answer": [0, 1, 0, 1]},
	"order": {"type": "order", "prompt": "Smallest first.", "hint": "Hundreds.", "items": ["4,210", "4,021", "4,201"],
		"answer": [1, 2, 0]},
	"match": {"type": "match", "prompt": "Animal and young.", "hint": "A baby cat?", "items": ["cat", "dog", "cow"],
		"matches": ["puppy", "calf", "kitten"], "answer": [2, 0, 1]},
	"label": {"type": "label", "prompt": "Label the blocks.", "hint": "Top first.", "picture": {"kind": "blocks", "tens": 1,
		"ones": 3}, "spots": [[0.2, 0.2], [0.8, 0.8]], "labels": ["a ten", "ones"], "answer": [1, 0]},
	"build": {"type": "build", "prompt": "Build 2 rows of 3.", "board": {"cols": 6, "rows": 3, "block": 9, "given": []},
		"goal": {"kind": "array", "rows": 2, "cols": 3}, "hint": "A row of 3 first."},
	"robot": {"type": "robot", "prompt": "Take the robot to the flag.", "hint": "Which way does it face?",
		"board": {"cols": 4, "rows": 3, "start": [0, 1], "facing": "N", "goal": [3, 1]}},
	"rhythm": {"type": "rhythm", "prompt": "Copy the rhythm.", "hint": "Listen again.",
		"sound": {"kind": "rhythm", "pattern": "x-x-xx--", "tempo": 90}},
	"mix": {"type": "mix", "prompt": "Mix orange.", "hint": "Two primary colours.", "target": "orange"},
	"point": {"type": "point", "prompt": "Find the point (2, 5).", "grid": {"x_max": 6, "y_max": 6}, "answer": [2, 5],
		"hint": "2 along, then 5 up."},
	"choice give": {"type": "choice", "prompt": "Which is 3,000 + 20 + 5?", "choices": ["3,025", "3,205", "325"], "answer": 0,
		"hint": "No hundreds."},
	"choice path": {"type": "choice", "prompt": "Which is a mammal?", "choices": ["a shark", "a whale", "a trout", "an eel"],
		"answer": 1, "hint": "It breathes air."},
	"choice pictures": {"type": "choice", "prompt": "Which shows 13?", "choices": [{"picture": {"kind": "blocks", "tens": 1,
		"ones": 3}}, {"picture": {"kind": "blocks", "tens": 3, "ones": 1}}], "answer": 0, "hint": "One ten."},
	"truefalse": {"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens place."},
}
const COSTUMES := {"choice give": "give", "choice path": "path", "choice pictures": "give"}

var arena: PlayArena


func before_all() -> void:
	Profile.data.settings.reduce_motion = true   # every move at once (the game eases them)


func after_all() -> void:
	Profile.data.settings.reduce_motion = false
	Audio.stop_all()


func _open(key: String, seed: int = 3) -> PlayStation:
	var ex: Dictionary = JSON.parse_string(JSON.stringify(SAMPLES[key]))   # as the School's files give it: numbers as floats
	assert_eq(ExerciseCheck.problem(ex), "", "%s is a good exercise" % key)
	arena = PlayArena.new()
	add_child_autofree(arena)
	var params := {"costume": COSTUMES[key]} if COSTUMES.has(key) else {}
	return arena.show_challenge(ex, seed, params)


## Plays the coach's ghost steps until there are none: each is the taps a child would make.
func _solve(st: PlayStation) -> void:
	for i in 200:
		var steps := st.ghost()
		if steps.is_empty():
			return
		for t in steps:
			st.tap(t)


func test_every_type_gets_its_mechanic_s_station() -> void:
	for key: String in SAMPLES:
		var st := _open(key)
		assert_eq(st.mechanic, PlayMechanics.of(str(SAMPLES[key].type)), key)
		assert_gt(arena.target_names().size(), 1, "%s has things to act with" % key)
		for t in arena.target_names():
			assert_true(arena.has_target(t), "%s: %s" % [key, t])
		arena.free()


func test_the_maker_follows_the_answer() -> void:
	var want := {"number tower": "tower", "number base ten": "base_ten", "number decimal": "base_ten", "number coins": "coins",
		"number jug": "jug", "number scale": "scale", "number fraction": "fraction", "number frog": "frog",
		"number dial": "dial"}
	for key: String in want:
		var st := _open(key) as MakeStation
		assert_eq(st.maker, want[key], key)
		arena.free()


func test_the_coach_s_steps_always_lead_to_a_right_answer() -> void:
	for key: String in SAMPLES:
		var st := _open(key)
		var acted := []
		st.acted.connect(func() -> void: acted.append(true))
		_solve(st)
		if st.answers_by_acting():
			assert_eq(acted.size(), 1, "%s: the act answered" % key)
		else:
			assert_true(st.is_ready(), "%s is ready" % key)
		assert_true(ExerciseCheck.is_right(st.ex, st.response()), "%s: %s" % [key, st.response()])
		arena.free()


func test_a_wrong_answer_is_not_right() -> void:
	var st := _open("number base ten")
	_solve(st)
	st.tap("src_0")   # one thousand too many
	assert_false(ExerciseCheck.is_right(st.ex, st.response()))
	assert_eq(PlayMake.compare((st as MakeStation).placed, st.ex), 1, "the world says: too much")
	arena.free()
	var sort := _open("sort")
	for i in 4:
		sort.tap("thing_%d" % i)
		sort.tap("bin_0")
	assert_true(sort.is_ready())
	assert_false(ExerciseCheck.is_right(sort.ex, sort.response()))
	arena.free()


func test_the_worked_answer_shown_is_right() -> void:
	for key: String in SAMPLES:
		var st := _open(key)
		st.show_answer()
		assert_true(ExerciseCheck.is_right(st.ex, st.response()), "%s shows a right answer: %s" % [key, st.response()])
		arena.free()


func test_a_miss_sends_things_home_where_the_school_s_answers_cleared() -> void:
	for key: String in ["sort", "order", "match", "label"]:
		var st := _open(key)
		st.tap("thing_0")
		st.tap(st.spot_names()[0])
		st.react(PlayLoop.NOT_YET)
		assert_eq(st.placing.placed_count(), 0, "%s: everything back home" % key)
		arena.free()
	var make := _open("number base ten") as MakeStation
	make.tap("src_1")
	make.react(PlayLoop.NOT_YET)
	assert_eq(make.placed.size(), 1, "a build stays, so the child can change it")
	arena.free()


func test_a_placed_thing_can_be_moved_and_taken_back() -> void:
	var st := _open("order")
	st.tap("thing_1")
	st.tap("slot_0")
	assert_eq(st.placing.at[1], 0)
	st.tap("thing_1")
	assert_eq(st.placing.at[1], -1, "lifted again")
	st.tap("thing_1")
	assert_eq(st.carried, "", "a second tap puts it down at home")
	arena.free()
	var make := _open("number base ten") as MakeStation
	make.tap("src_1")
	make.tap("src_1")
	assert_eq(make.placed.size(), 2)
	make.tap("piece_0")
	assert_eq(make.placed.size(), 1, "a piece on the build comes off when tapped")
	arena.free()


func test_the_buddy_or_the_gate_answers_by_the_act() -> void:
	var st := _open("choice give")
	var acted := []
	st.acted.connect(func() -> void: acted.append(st.response()))
	st.tap("thing_2")
	st.tap("buddy")
	assert_eq(acted, [2], "the crate given to the buddy is the answer")
	arena.free()
	var gate := _open("truefalse")
	var said := []
	gate.acted.connect(func() -> void: said.append(gate.response()))
	gate.tap("gate_1")
	assert_eq(said, [false], "the FALSE gate")
	arena.free()


func test_every_thing_to_tap_is_on_screen_from_the_station_s_view() -> void:
	var view := SubViewport.new()   # the game's narrowest canvas (16:9; phones are wider): the headless window is square
	view.size = Vector2i(PlayHud.CANVAS)
	add_child_autofree(view)
	var cam := Camera3D.new()
	cam.fov = PlayHost.FOV
	view.add_child(cam)
	for key: String in SAMPLES:
		var st := _open(key)
		_solve(st)   # everything placed too: the far places stay on screen with things on them
		st.show_answer()
		cam.global_transform = arena.camera_transform(PlayArena.VIEW)
		for t in arena.target_names():
			if not arena.target_node(t).is_visible_in_tree():
				continue
			var p := arena.target_position(t)
			assert_false(cam.is_position_behind(p), "%s: %s is behind the camera" % [key, t])
			var s := cam.unproject_position(p)
			assert_true(PlayHud.FREE.has_point(s), "%s: %s is off the free screen at %s" % [key, t, s])
		if arena.board != null:
			for corner in arena.board.corners():
				var s := cam.unproject_position(corner)
				assert_true(Rect2(Vector2.ZERO, PlayHud.CANVAS).has_point(s), "%s: the board's corner %s" % [key, s])
		arena.free()


func test_in_vr_the_hands_reach_what_they_carry_and_where_it_goes() -> void:
	for key: String in SAMPLES:
		var st := _open(key)
		var eye := arena.vr_stand(PlayArena.VIEW).origin
		for t in arena.target_names():
			var d := eye.distance_to(arena.target_position(t))
			if st.carryable(t) or st.spot_names().has(t):
				assert_lte(d, 1.1, "%s: %s is %.2f m away (the hands must reach it)" % [key, t, d])
			else:
				assert_lte(d, PlayHost.LASER, "%s: %s is %.2f m away (the laser must reach it)" % [key, t, d])
		arena.free()


func test_the_place_casts_no_shadows_and_uses_only_warmed_shaders() -> void:
	var census := {}
	var labels := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			census[ShaderWarmup.key(d.material)] = true
		if d.has("label"):
			labels[JSON.stringify(d.label, "", true)] = true
	for key: String in SAMPLES:
		var st := _open(key)
		_solve(st)
		arena.glow(arena.target_names())
		for m: Node in arena.find_children("*", "GeometryInstance3D", true, false):
			if m.get_viewport() != arena.get_viewport():
				continue   # a picture's own 2D canvas (PlayBoard's SubViewport) draws no 3D
			assert_eq((m as GeometryInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, str(m.name))
			if m is MeshInstance3D:
				var mat := (m as MeshInstance3D).material_override
				assert_true(census.has(ShaderWarmup.key(ShaderWarmup.describe(mat))), "%s %s: %s" % [key, m.name,
					ShaderWarmup.describe(mat)])
			elif m is Label3D:
				for d: Dictionary in ShaderWarmup.draws_of(m):
					assert_true(labels.has(JSON.stringify(d.label, "", true)), "%s %s: %s" % [key, m.name, d.label])
		for l: Node in arena.find_children("*", "Light3D", true, false):
			assert_false((l as Light3D).shadow_enabled)
		arena.free()


func test_a_picture_shows_on_the_board_in_the_place() -> void:
	var ex: Dictionary = SAMPLES["number base ten"].duplicate(true)
	ex.picture = {"kind": "blocks", "hundreds": 3, "tens": 4, "ones": 7}
	arena = PlayArena.new()
	add_child_autofree(arena)
	arena.show_challenge(ex, 1, {})
	assert_not_null(arena.board, "the board")
	assert_eq(arena.board.picture.data.kind, "blocks")
	arena.show_challenge(SAMPLES["sort"].duplicate(true), 1, {})
	assert_null(arena.board, "no picture, no board")
	arena.free()


func test_a_new_challenge_replaces_the_station_and_its_things() -> void:
	arena = PlayArena.new()
	add_child_autofree(arena)
	arena.show_challenge(SAMPLES["sort"].duplicate(true), 1, {})
	assert_true(arena.has_target("bin_0"))
	arena.show_challenge(SAMPLES["truefalse"].duplicate(true), 1, {})
	assert_false(arena.has_target("bin_0"), "the sort's bins are gone")
	assert_true(arena.has_target("gate_0"))
	arena.free()
