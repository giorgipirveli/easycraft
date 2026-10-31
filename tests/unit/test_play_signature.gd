extends GutTest
## Owner #133, #134 (the leaf's B2 brief; docs/devlog/parts/game-leaf-b.md B2.1): the registry for a deep game with its
## own host, built once for every deep game. data/play/mechanics.json's "signature" table names a game's host script
## ({"host": path}: a PlayHost subclass) beside G0's station games ({"script": path}). PlaySignature says which host a
## unit opens and makes it: the deep game's own when the unit's play block names one, else G0's PlayHost as today; an
## unknown game, or a host that is missing or no PlayHost, falls back to PlayHost with a warning, never a crash.

const HOST := "res://tests/integration/play_signature_host.gd"

var _saved := {}


func before_each() -> void:
	_saved = PlayMechanics.data().duplicate(true)
	PlayMechanics.data().signature = {
		"stand_in": {"name": "Stand-in Game", "host": HOST},
		"tiny_game": {"name": "Tiny Game", "script": "res://tests/integration/play_tiny_game.gd"},
		"lost_host": {"name": "Lost Game", "host": "res://tests/integration/no_such_host.gd"},
		"not_a_host": {"name": "Not a Host", "host": "res://core/play/play_block.gd"},
	}


func after_each() -> void:
	PlayMechanics._data = _saved


func _unit(game: String) -> Dictionary:
	return {"id": "g5.science.x", "exercises": [], "play": {"game": game, "params": {"voyage": "5.T1"}}}


func test_a_unit_naming_a_deep_game_with_a_host_opens_that_host() -> void:
	var c := _unit("stand_in")
	assert_eq(PlaySignature.game_of(c), "stand_in")
	assert_eq(PlaySignature.host_for(c), HOST)
	assert_eq(PlaySignature.why_not(c), "", "nothing to warn about")
	var h := PlaySignature.make_host(c)
	assert_true(h is PlayHost, "a host is a PlayHost: every caller treats it as a round")
	assert_eq(h.get_script().resource_path, HOST)
	h.free()


func test_a_unit_naming_no_deep_game_plays_g0s_way_as_today() -> void:
	for c: Dictionary in [{"id": "g4.maths.x"}, _unit("generic"), _unit("tiny_game")]:
		assert_eq(PlaySignature.host_for(c), "", str(c))
		assert_eq(PlaySignature.why_not(c), "", "as designed, no warning: %s" % c)
		var h := PlaySignature.make_host(c)
		assert_eq(h.get_script(), PlayHost, "G0's play place: %s" % c)
		h.free()


func test_an_unknown_or_broken_game_falls_back_to_playhost_with_a_warning() -> void:
	for game: String in ["no_such_game", "lost_host", "not_a_host"]:
		var c := _unit(game)
		assert_eq(PlaySignature.host_for(c), "", game)
		assert_string_contains(PlaySignature.why_not(c), game, "the warning names the game")
		var h := PlaySignature.make_host(c)
		assert_eq(h.get_script(), PlayHost, "%s: G0's place, never a crash" % game)
		h.free()


func test_a_deep_game_is_known_by_name_and_its_unit_is_p1() -> void:
	assert_true(PlaySignature.hosts().has("stand_in"))
	assert_false(PlaySignature.hosts().has("tiny_game"), "a station game has no host of its own")
	assert_eq(PlayMechanics.level(_unit("stand_in")), PlayMechanics.P1, "G0's registry: a deep game's unit is P1")


func test_the_params_to_open_next_come_from_the_outcome() -> void:
	assert_eq(PlaySignature.then_of({"then": {"voyage": "5.T1"}}), {"voyage": "5.T1"})
	assert_eq(PlaySignature.then_of({"right_first": 5}), {}, "a round's outcome opens nothing next")
	var c := _unit("stand_in")
	var next := PlaySignature.with_params(c, {"voyage": "5.1"})
	assert_eq(PlayBlock.params(next).voyage, "5.1")
	assert_eq(PlayBlock.params(c).voyage, "5.T1", "the unit itself is untouched")


func test_any_open_sees_a_deep_games_host_while_it_shows() -> void:
	var parent := Node.new()
	add_child_autofree(parent)
	assert_false(PlaySignature.any_open(get_tree()))
	var h := PlaySignature.make_host(_unit("stand_in"))
	h.setup("g5.science.x", _unit("stand_in"), 1, 0, {})
	h.open(parent)
	assert_true(PlaySignature.any_open(get_tree()))
	assert_true(PlayHost.any_open(get_tree()), "G0's own check sees it too (Back belongs to the game)")
	h.close()
	await wait_process_frames(1)
	assert_false(PlaySignature.any_open(get_tree()))
