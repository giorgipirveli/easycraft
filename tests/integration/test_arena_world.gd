extends GutTest
## Monster Wave's arena world (spec §12.20): WorldService builds a flat arena of the universe when asked (the host
## and a guest alike), its own save slot per universe (Game.slot), and WorldMeta keeps each player's best there.

var _mode: StringName
var _universe := 1


func before_each() -> void:
	_mode = Game.mode
	_universe = Game.universe


func after_each() -> void:
	Game.mode = _mode
	Game.universe = _universe


func test_the_world_service_builds_a_flat_arena_of_the_universe() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 99, false, 2, true)
	add_child_autofree(w)
	assert_true(w.generator_shape() is ArenaShape)
	assert_eq((w.generator_shape() as ArenaShape).universe, 2)
	assert_eq(w.surface_height(300, -40), ArenaShape.FLOOR)
	assert_eq(w.spawn_column(), Vector2i(0, ArenaShape.START_Z))
	var gen := w.terrain().generator as ArenaGenerator
	assert_not_null(gen, "the arena's generator")
	assert_eq(gen.universe, 2)
	assert_eq(gen.world_seed, 99)


func test_a_guest_builds_the_same_arena() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 99, true, 3, true)
	add_child_autofree(w)
	assert_true(w.generator_shape() is ArenaShape)
	var edited := w.terrain().generator as EditedGenerator
	assert_not_null(edited)
	assert_true(edited.base is ArenaGenerator, "the host's edits over the same arena")


func test_other_worlds_are_as_before() -> void:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 99, false, 1)
	add_child_autofree(w)
	assert_false(w.generator_shape() is ArenaShape)


func test_each_universe_has_its_own_arena_slot() -> void:
	Game.mode = ModeRules.WAVE
	Game.universe = 1
	assert_eq(Game.slot(), "wave_1")
	Game.universe = 2
	assert_eq(Game.slot(), "wave_2")


func test_the_arena_keeps_each_players_best() -> void:
	var m := WorldMeta.new_random()
	m.mode = ModeRules.WAVE
	m.arena = {"Kid": {"best_time": 204.5, "best_wave": 5}}
	var q := WorldMeta.from_json(m.to_json())
	assert_eq(q.mode, ModeRules.WAVE)
	assert_eq(q.arena, {"Kid": {"best_time": 204.5, "best_wave": 5}})
	assert_eq(WorldMeta.from_json('{"seed": 3}').arena, {}, "worlds saved before have none")
	assert_eq(WorldMeta.from_json('{"seed": 3, "arena": [1]}').arena, {})
