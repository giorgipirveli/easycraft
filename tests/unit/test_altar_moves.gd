extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.4, §3.5's rules table, rulings 2-6, §4.6): the twin rules.
## Every move is a TWIN MOVE, the same done to both pans: take the same off both, put the same on both (the gem bag, the
## balloon pump), share both into equal shares and keep one. At the hands' level a lift (or a placement) waits for its
## twin on the other pan; more of the same on the same pan grows the batch; the twin commits it. Anything else while it
## waits is a rule break: the waiting things spring back and nothing changes. Putting back is free; carrying a thing
## across is refused; a share is fair only when every amount on both pans divides; a gem and a balloon on one pan cancel
## by themselves. The crystal is freed only alone, with nothing waiting.

const HALL: Array[String] = ["bowls", "gem_bag"]
const SKY: Array[String] = ["bowls", "gem_bag", "pump"]
const L := AltarState.LEFT
const R := AltarState.RIGHT
const GEM := AltarState.GEM
const BALLOON := AltarState.BALLOON
const CRYSTAL := AltarState.CRYSTAL


func _moves(lc: int, lk: int, rc: int, rk: int, x: int, tools: Array[String] = HALL) -> AltarMoves:
	return AltarMoves.start(AltarState.make(lc, lk, rc, rk, x), tools)


# --- The twin moves (the model's operations) ----------------------------------------------------------------------

func test_a_take_is_legal_only_when_both_pans_have_that_many() -> void:
	var s := AltarState.make(1, 3, 0, 7, 4)
	assert_true(AltarMoves.legal(s, AltarMoves.take(GEM, 3), HALL))
	assert_false(AltarMoves.legal(s, AltarMoves.take(GEM, 4), HALL), "the left pan has only three")
	assert_false(AltarMoves.legal(s, AltarMoves.take(CRYSTAL, 1), HALL), "the right pan has no crystal")
	assert_false(AltarMoves.legal(s, AltarMoves.take(BALLOON, 1), SKY), "no balloons at all")
	assert_false(AltarMoves.legal(s, AltarMoves.take(GEM, 0), HALL))
	assert_true(AltarMoves.apply(s, AltarMoves.take(GEM, 3)).same(AltarState.make(1, 0, 0, 4, 4)))


func test_an_add_needs_its_supply_and_a_balloon_cancels_a_gem() -> void:
	var s := AltarState.make(1, -3, 0, 5, 8)
	assert_true(AltarMoves.legal(s, AltarMoves.add(GEM, 3), HALL), "the gem bag")
	assert_false(AltarMoves.legal(s, AltarMoves.add(BALLOON, 1), HALL), "no pump in the hall")
	assert_true(AltarMoves.legal(s, AltarMoves.add(BALLOON, 1), SKY))
	assert_false(AltarMoves.legal(s, AltarMoves.add(GEM, AltarMoves.MAX_ADD + 1), HALL))
	var after := AltarMoves.apply(s, AltarMoves.add(GEM, 3))
	assert_true(after.same(AltarState.make(1, 0, 0, 8, 8)), "each gem caught a balloon and the pair floated off")
	assert_true(after.holds())
	assert_true(after.freed(), "the crystal stands alone: it weighs eight")
	assert_true(AltarMoves.apply(AltarState.make(1, 2, 0, 6, 4), AltarMoves.add(BALLOON, 2)).same(
		AltarState.make(1, 0, 0, 4, 4)), "balloons undo gems too")


func test_a_share_is_fair_only_when_every_amount_divides() -> void:
	var s := AltarState.make(3, 0, 0, 12, 4)
	assert_true(AltarMoves.legal(s, AltarMoves.share(3), HALL))
	assert_false(AltarMoves.legal(s, AltarMoves.share(2), HALL), "three crystals won't share into two")
	assert_false(AltarMoves.legal(s, AltarMoves.share(4), HALL), "nor into four")
	assert_false(AltarMoves.legal(AltarState.make(2, 1, 0, 7, 3), AltarMoves.share(2), HALL), "one gem won't split")
	assert_false(AltarMoves.legal(s, AltarMoves.share(3), ["gem_bag"] as Array[String]), "no bowls")
	assert_false(AltarMoves.legal(s, AltarMoves.share(1), HALL), "one bowl is no share")
	assert_false(AltarMoves.legal(AltarState.make(8, 0, 0, 16, 2), AltarMoves.share(8), HALL), "the rack has 2-6 bowls")
	assert_true(AltarMoves.apply(s, AltarMoves.share(3)).same(AltarState.make(1, 0, 0, 4, 4)))
	assert_true(AltarMoves.apply(AltarState.make(2, -2, 0, 6, 4), AltarMoves.share(2)).same(
		AltarState.make(1, -1, 0, 3, 4)), "balloons share too")


func test_every_legal_twin_move_listed() -> void:
	var ops := AltarMoves.legal_ops(AltarState.make(2, 2, 0, 8, 3), HALL, 3)
	var names := ops.map(func(op: Dictionary) -> String: return AltarMoves.name_of(op))
	assert_has(names, "take gem 1")
	assert_has(names, "take gem 2")
	assert_does_not_have(names, "take gem 3", "the left pan has two")
	assert_has(names, "add gem 3")
	assert_does_not_have(names, "add gem 4", "at most max_add")
	assert_does_not_have(names, "add balloon 1", "no pump")
	assert_has(names, "share 2")
	assert_does_not_have(names, "share 3")
	for op: Dictionary in ops:
		assert_true(AltarMoves.legal(AltarState.make(2, 2, 0, 8, 3), op, HALL), AltarMoves.name_of(op))


# --- The hands: a lift waits for its twin --------------------------------------------------------------------------

func test_a_lift_waits_and_its_twin_commits_the_move() -> void:
	var m := _moves(1, 3, 0, 7, 4)
	var r := m.lift(L, GEM)
	assert_true(r.ok)
	assert_true(r.waiting, "the gem rises, amber, waiting")
	assert_eq(r.moved, {})
	assert_eq(m.state.lk, 3, "nothing has changed yet")
	assert_eq(m.lifted(L), 1)
	r = m.lift(R, GEM)
	assert_eq(AltarMoves.name_of(r.moved), "take gem 1", "the twin: both float off")
	assert_false(r.waiting)
	assert_true(m.state.same(AltarState.make(1, 2, 0, 6, 4)))
	assert_eq(m.breaks, 0)


func test_more_of_the_same_on_the_same_pan_grows_the_batch() -> void:
	var m := _moves(1, 3, 0, 7, 4)
	m.lift(L, GEM)
	m.lift(L, GEM)
	m.lift(L, GEM)
	assert_eq(m.lifted(L), 3)
	assert_eq(m.lift(L, GEM).ok, false, "there is no fourth gem on that pan")
	m.lift(R, GEM)
	m.lift(R, GEM)
	assert_eq(m.state.lk, 3, "two of three twins: still waiting")
	var r := m.lift(R, GEM)
	assert_eq(AltarMoves.name_of(r.moved), "take gem 3")
	assert_true(m.freed(), "the crystal stands alone")
	assert_eq(m.state.shown_weight(), 4)
	assert_eq(m.ops, 1, "one move")


func test_pair_by_pair_is_one_move_too() -> void:
	var m := _moves(1, 3, 0, 7, 4)
	for i in 3:
		m.lift(L, GEM)
		m.lift(R, GEM)
	assert_true(m.freed())
	assert_eq(m.ops, 1, "consecutive takes of gems are one operation (ruling 5)")


func test_a_handful_and_its_twin_handful() -> void:
	var m := _moves(1, 3, 0, 7, 4)
	m.handful(L, GEM)
	assert_eq(m.lifted(L), 3, "every gem of that kind on the pan")
	var r := m.handful(R, GEM)
	assert_eq(AltarMoves.name_of(r.moved), "take gem 3", "the twin long press takes the same number")
	assert_true(m.freed())
	var short := _moves(0, 7, 1, 3, 4)
	short.handful(L, GEM)
	r = short.handful(R, GEM)
	assert_true(r.waiting, "the other pan has only three of the seven: the batch still waits")
	assert_eq(short.state.lk, 7, "nothing taken")


func test_anything_else_while_a_lift_waits_is_a_rule_break_and_changes_nothing() -> void:
	var cases := {
		"another kind": func(m: AltarMoves) -> Dictionary: return m.lift(L, CRYSTAL),
		"a share": func(m: AltarMoves) -> Dictionary: return m.share_by(2),
		"the crystal tapped": func(m: AltarMoves) -> Dictionary: return m.tap_crystal(),
		"a placement": func(m: AltarMoves) -> Dictionary: return m.place(R, GEM),
	}
	for what: String in cases:
		var m := _moves(1, 3, 0, 7, 4)
		m.lift(L, GEM)
		var r: Dictionary = (cases[what] as Callable).call(m)
		assert_eq(r.broke, AltarMoves.ONE_PAN, what)
		assert_false(r.waiting, "%s: the gem springs back" % what)
		assert_true(m.state.same(AltarState.make(1, 3, 0, 7, 4)), "%s: nothing changed" % what)
		assert_eq(m.breaks, 1, what)
		assert_eq(m.notes, [AltarMoves.ONE_PAN] as Array[String], what)


func test_putting_back_is_free() -> void:
	var m := _moves(1, 3, 0, 7, 4)
	m.lift(L, GEM)
	m.lift(L, GEM)
	var r := m.put_back()
	assert_true(r.ok)
	assert_eq(r.broke, "")
	assert_eq(m.lifted(L), 0)
	assert_eq(m.breaks, 0, "no rule broken")
	assert_eq(m.lift(L, CRYSTAL).broke, "", "nothing waits now: a crystal may be lifted (it waits for a twin)")


func test_carrying_a_thing_across_is_refused() -> void:
	var m := _moves(1, 3, 0, 7, 4)
	var r := m.carry_across(L, GEM)
	assert_eq(r.broke, AltarMoves.ACROSS, "lifting it changes one pan, dropping it changes the other")
	assert_true(m.state.same(AltarState.make(1, 3, 0, 7, 4)))
	assert_eq(m.notes, [AltarMoves.ACROSS] as Array[String])


func test_an_uneven_share_is_refused_and_a_fair_one_commits() -> void:
	var m := _moves(3, 0, 0, 12, 4)
	var r := m.share_by(2)
	assert_eq(r.broke, AltarMoves.UNFAIR)
	assert_true(m.state.same(AltarState.make(3, 0, 0, 12, 4)))
	r = m.share_by(3)
	assert_eq(AltarMoves.name_of(r.moved), "share 3")
	assert_true(m.freed())
	assert_eq(m.notes, [AltarMoves.UNFAIR] as Array[String])


func test_a_lift_the_other_pan_cannot_twin_is_noted_as_no_twin() -> void:
	var m := _moves(1, -3, 0, 5, 8, SKY)
	m.lift(L, BALLOON)
	assert_true(m.no_twin(), "the other pan has no balloon (the hall's habit, stuck)")
	assert_false(m.lift(R, BALLOON).ok, "there is no balloon to lift there")
	var r := m.tap_crystal()
	assert_eq(r.broke, AltarMoves.NO_TWIN)
	assert_eq(m.notes, [AltarMoves.NO_TWIN] as Array[String])


func test_the_gem_bag_puts_the_same_on_both_pans_and_a_gem_pops_a_balloon() -> void:
	var m := _moves(1, -3, 0, 5, 8, SKY)
	var r := m.place(L, GEM)
	assert_true(r.waiting, "it hangs under a balloon, waiting")
	assert_eq(m.state.lk, -3)
	r = m.place(R, GEM)
	assert_eq(AltarMoves.name_of(r.moved), "add gem 1")
	assert_true(m.state.same(AltarState.make(1, -2, 0, 6, 8)), "the gem and a balloon floated off together")
	m.place(L, GEM)
	m.place(L, GEM)
	m.place(R, GEM)
	m.place(R, GEM)
	assert_true(m.freed())
	assert_eq(m.state.shown_weight(), 8)
	assert_eq(m.ops, 1, "putting gems on, pair by pair: one move")
	var hall := _moves(1, 2, 0, 6, 4)
	assert_false(hall.place(L, BALLOON).ok, "no balloon pump in the hall")


func test_the_crystal_is_freed_only_alone_with_nothing_waiting() -> void:
	var m := _moves(1, 1, 0, 5, 4)
	m.lift(L, GEM)
	assert_false(m.freed(), "the gem is lifted but its twin has not come: nothing has moved")
	m.lift(R, GEM)
	assert_true(m.freed())
	assert_eq(m.freed_by, AltarMoves.CHILD)


func test_a_freed_altar_takes_no_more_moves() -> void:
	var m := _moves(1, 0, 0, 4, 4)
	assert_true(m.freed())
	assert_false(m.lift(R, GEM).ok)
	assert_eq(m.share_by(2).broke, "", "nothing to refuse: the altar is done")


func test_a_whole_twin_move_at_once_and_the_ghost_s() -> void:
	var m := _moves(2, 2, 0, 8, 3)
	var r := m.commit(AltarMoves.take(GEM, 2))
	assert_eq(AltarMoves.name_of(r.moved), "take gem 2", "a drag from a gem to its twin does both")
	assert_eq(m.ops, 1)
	r = m.commit(AltarMoves.share(2), AltarMoves.GHOST)
	assert_true(m.freed())
	assert_eq(m.freed_by, AltarMoves.GHOST)
	assert_true(m.helped, "the ghost's step is help")
	assert_eq(m.ops, 1, "the ghost's moves are not the child's")
	var refused := _moves(2, 1, 0, 7, 3)
	assert_eq(refused.commit(AltarMoves.share(2)).broke, AltarMoves.UNFAIR)


func test_moves_are_counted_as_operations_and_every_act_is_counted() -> void:
	var m := _moves(2, 2, 0, 8, 3)
	m.lift(L, GEM)
	m.lift(R, GEM)
	m.lift(L, GEM)
	m.lift(R, GEM)
	assert_eq(m.ops, 1)
	m.place(L, GEM)
	m.place(R, GEM)
	assert_eq(m.ops, 2, "a different verb is a new operation")
	m.lift(L, GEM)
	m.lift(R, GEM)
	assert_eq(m.ops, 3, "and taking again after it another")
	assert_eq(m.acts, 8)
	m.lift(R, CRYSTAL)
	assert_eq(m.acts, 9, "a tap on nothing to lift still counts as an act")
