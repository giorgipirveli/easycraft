extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5's rules table, ruling 5, §4.3, §4.6): the shortest way to
## free a crystal (breadth-first over the twin moves, as the model's `shortest`): the ghost's next step and the move
## budget. A one-move altar must be freed in one move; a longer one may take one move more than its shortest solution.

const HALL: Array[String] = ["bowls", "gem_bag"]
const SKY: Array[String] = ["bowls", "gem_bag", "pump"]


func _names(path: Array[Dictionary]) -> Array:
	return path.map(func(op: Dictionary) -> String: return AltarMoves.name_of(op))


func test_the_shortest_solution_of_every_hall_form() -> void:
	assert_eq(_names(AltarSolver.shortest(AltarState.make(1, 3, 0, 7, 4), HALL)), ["take gem 3"], "x + 3 = 7")
	assert_eq(_names(AltarSolver.shortest(AltarState.make(0, 9, 1, 2, 7), HALL)), ["take gem 2"], "9 = x + 2")
	assert_eq(_names(AltarSolver.shortest(AltarState.make(3, 0, 0, 12, 4), HALL)), ["share 3"], "3x = 12")
	assert_eq(_names(AltarSolver.shortest(AltarState.make(0, 8, 2, 0, 4), HALL)), ["share 2"], "8 = 2x")
	assert_eq(_names(AltarSolver.shortest(AltarState.make(2, 1, 0, 7, 3), HALL)), ["take gem 1", "share 2"],
		"the Great Altar: take, then share (one gem won't split)")


func test_the_shortest_solution_of_every_sky_form() -> void:
	assert_eq(_names(AltarSolver.shortest(AltarState.make(1, -3, 0, 5, 8), SKY)), ["add gem 3"], "x - 3 = 5")
	assert_eq(_names(AltarSolver.shortest(AltarState.make(0, 4, 1, -2, 6), SKY)), ["add gem 2"], "4 = x - 2")
	assert_eq(_names(AltarSolver.shortest(AltarState.make(2, -2, 0, 6, 4), SKY)).size(), 2, "2x - 2 = 6: two moves")
	assert_eq(_names(AltarSolver.shortest(AltarState.make(2, -2, 0, 6, 4), SKY))[1], "share 2")


func test_a_freed_altar_needs_nothing_and_a_hopeless_one_has_no_solution() -> void:
	assert_eq(AltarSolver.shortest(AltarState.make(1, 0, 0, 4, 4), HALL), [] as Array[Dictionary])
	assert_eq(AltarSolver.min_ops(AltarState.make(1, 0, 0, 4, 4), HALL), 0)
	assert_true(AltarSolver.solvable(AltarState.make(1, 0, 0, 4, 4), HALL))
	var no_bowls: Array[String] = ["gem_bag"]
	assert_false(AltarSolver.solvable(AltarState.make(3, 0, 0, 12, 4), no_bowls), "three crystals and no bowls")
	assert_eq(AltarSolver.min_ops(AltarState.make(3, 0, 0, 12, 4), no_bowls), AltarSolver.NONE)
	assert_eq(AltarSolver.next_step(AltarState.make(3, 0, 0, 12, 4), no_bowls), {})


func test_the_ghost_s_next_step_is_the_first_of_a_shortest_solution() -> void:
	assert_eq(AltarMoves.name_of(AltarSolver.next_step(AltarState.make(2, 1, 0, 7, 3), HALL)), "take gem 1")
	assert_eq(AltarMoves.name_of(AltarSolver.next_step(AltarState.make(1, 2, 0, 6, 4), HALL)), "take gem 2")


func test_the_move_budget() -> void:
	assert_eq(AltarSolver.budget(1), 1, "a one-move altar in one move (ruling 5)")
	assert_eq(AltarSolver.budget(2), 3, "a longer one: one move more than its shortest")
	assert_eq(AltarSolver.budget(3), 4)
	assert_eq(AltarSolver.budget(0), 0)


func test_solutions_are_cached_and_stay_the_same() -> void:
	var s := AltarState.make(2, 3, 0, 11, 4)
	var first := _names(AltarSolver.shortest(s, HALL))
	var again := _names(AltarSolver.shortest(s.copy(), HALL))
	assert_eq(first, again)
	assert_eq(first, ["take gem 3", "share 2"])
