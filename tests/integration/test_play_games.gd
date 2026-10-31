extends GutTest
## Owner #122 (G0 → G1-G5, the contract the signature games build on): a signature game is registered in
## data/play/mechanics.json's "signature" ({id: {name, script}}: a PlayStation subclass with `static func
## expresses(ex) -> bool`). A unit whose play block names it is P1, and plays each exercise the game expresses in the
## game's own station; any other exercise keeps G0's mechanic. The audit and the grown-ups' page read the same registry.

const TF := {"type": "truefalse", "prompt": "In 347, the 4 is worth 40.", "answer": true, "hint": "Tens place."}
const SORT := {"type": "sort", "prompt": "Living or not?", "hint": "Does it grow?", "groups": ["living", "not living"],
	"items": ["a tree", "a rock"], "answer": [0, 1]}

var _saved := {}


func before_each() -> void:
	_saved = PlayMechanics.data().duplicate(true)
	PlayMechanics.data().signature = {"tiny_game": {"name": "Tiny Game", "script": "res://tests/integration/play_tiny_game.gd"}}


func after_each() -> void:
	PlayMechanics._data = _saved


func test_a_unit_naming_a_registered_game_is_p1() -> void:
	assert_eq(PlayMechanics.level({"play": {"game": "tiny_game"}}), PlayMechanics.P1)
	assert_eq(PlayMechanics.level({"play": {"game": "not_built"}}), PlayMechanics.P0)
	assert_eq(PlayMechanics.game_name("tiny_game"), "Tiny Game")


func test_the_game_plays_what_it_expresses_and_g0_the_rest() -> void:
	var arena := PlayArena.new()
	add_child_autofree(arena)
	var st := arena.show_challenge(TF.duplicate(true), 1, {}, "tiny_game")
	assert_eq(st.get_script().resource_path, "res://tests/integration/play_tiny_game.gd", "the game's own station")
	assert_true(arena.has_target("lever_true"))
	var sort := arena.show_challenge(SORT.duplicate(true), 1, {}, "tiny_game")
	assert_true(sort is SortStation, "an exercise the game can't express keeps G0's mechanic")
	var plain := arena.show_challenge(TF.duplicate(true), 1, {}, "")
	assert_true(plain is TestStation, "no game: G0's")


func test_the_host_plays_a_unit_in_its_game_and_the_referee_is_the_same() -> void:
	var parent := Node.new()
	add_child_autofree(parent)
	var host := PlayHost.new()
	host.setup("g4.maths.big_numbers", {"id": "g4.maths.big_numbers", "lesson": [], "exercises": [TF], "play":
		{"game": "tiny_game"}}, 3, 0, {})
	host.open(parent)
	await wait_process_frames(2)
	host.end_hook()
	var st := host.station()
	assert_eq(st.get_script().resource_path, "res://tests/integration/play_tiny_game.gd")
	st.tap(st.ghost()[0])
	assert_true(host.loop.answered)
	assert_eq(host.loop.right_first, 1, "ExerciseCheck judged it; the record counts it")
	host.close()
