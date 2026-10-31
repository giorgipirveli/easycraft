extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5, §3.5b, §3.8, §3.10, rulings 4, 14; §4.3): one room
## played, altar after altar: the run B2's host steps and the cheat bots play. Numbers are new every visit (seeded); the
## ghost shows the taught altars' moves; every second rule break brings the ghost's step; after 40 acts the ghost frees
## the crystal; each freed altar is judged; Hoot's lines come as cues (first times once), and the rune line is read at
## every altar's start.

const L := AltarState.LEFT
const R := AltarState.RIGHT


## Frees the current altar the way a child who knows the rule does: a shortest solution, each take as a handful and its
## twin, each add pair by pair, each share by the bowls.
func _solve(run: AltarRun) -> void:
	for op: Dictionary in AltarSolver.shortest(run.moves.state, run.tools):
		var side := run.moves.state.crystal_pan()
		match str(op.verb):
			AltarMoves.TAKE:
				run.handful(side, str(op.kind))
				run.handful(1 - side, str(op.kind))
			AltarMoves.ADD:
				for i in int(op.n):
					run.place(side, str(op.kind))
				for i in int(op.n):
					run.place(1 - side, str(op.kind))
			AltarMoves.SHARE:
				run.share_by(int(op.n))


func _said(cues: Array[Dictionary]) -> Array:
	return cues.filter(func(c: Dictionary) -> bool: return c.has("say")).map(func(c: Dictionary) -> String:
		return str(c.say))


func test_the_same_seed_gives_the_same_room_and_another_seed_new_numbers() -> void:
	var a := AltarRun.make("entrance", 4)
	var b := AltarRun.make("entrance", 4)
	var c := AltarRun.make("entrance", 5)
	assert_eq(a.count(), 11)
	var differs := false
	for i in a.count():
		assert_true(a.start_state(i).same(b.start_state(i)), "altar %d" % (i + 1))
		differs = differs or not a.start_state(i).same(c.start_state(i))
	assert_true(differs, "another visit, new numbers")
	assert_true(a.start_state(0).same(AltarState.make(1, 2, 0, 5, 3)), "the taught altars are fixed")


func test_the_first_altar_is_shown_by_the_ghost_then_it_is_the_child_s_turn() -> void:
	var run := AltarRun.make("entrance", 1)
	run.start()
	var cues := run.take_cues()
	var said := _said(cues)
	assert_has(said, "Watch: the same off both pans.", "H3")
	assert_has(said, "Your turn!", "H4")
	var ghost := cues.filter(func(c: Dictionary) -> bool: return c.has("ghost"))
	assert_eq(ghost.size(), 1)
	assert_true(bool(ghost[0].demo), "a demonstration, not help")
	assert_true(run.moves.state.same(AltarState.make(1, 1, 0, 4, 3)), "the ghost lifted a gem off each pan")
	assert_false(run.moves.helped)
	assert_has(cues.map(func(c: Dictionary) -> String: return str(c.get("read", ""))),
		"A crystal and two gems weigh five gems.", "the rune line read at the start (stage 1)")


func test_the_hall_played_by_the_rule_gives_eight_counting_events() -> void:
	var run := AltarRun.make("entrance", 2)
	run.start()
	while not run.is_done():
		_solve(run)
		assert_true(run.freed(), "altar %d freed" % run.altar().n)
		run.next_altar()
	var results := run.beats.judged()
	assert_eq(results.size(), 8)
	for r: Dictionary in results:
		assert_true(bool(r.counts), "altar %d: %s %s" % [r.n, r.kind, r.note])
	assert_eq(str(results[7].kind), SkillShown.NEW_SETTING, "the Great Altar")
	assert_true(run.beats.masters())
	var shown := SkillShown.begin()
	run.record(shown)
	assert_eq(shown.total("g6.maths.equations"), 8)
	assert_eq(shown.transfer("g6.maths.equations"), 1)
	assert_has(run.take_cues().map(func(c: Dictionary) -> bool: return bool(c.get("room_done", false))), true)


func test_the_bowls_altar_is_freed_by_the_ghost_and_then_its_see_why() -> void:
	var run := AltarRun.make("entrance", 3)
	run.start()
	for i in 4:
		_solve(run)
		run.next_altar()
	var cues := run.take_cues()
	assert_eq(int(run.altar().n), 5)
	assert_true(run.freed(), "the ghost set two bowls and pressed the seal")
	var said := _said(cues)
	assert_has(said, "Watch: share both pans fairly. Keep one share.", "H12")
	assert_has(said, "Two crystals weighed six. So one weighs three!", "H13")


func test_every_second_rule_break_brings_the_ghost_s_step() -> void:
	var run := AltarRun.make("entrance", 1)
	run.start()
	run.next_altar()   # altar 2, the trap: 1 crystal and 3 gems | 7 gems
	run.take_cues()
	run.lift(L, AltarState.GEM)
	var r := run.tap_crystal()
	assert_eq(str(r.broke), AltarMoves.ONE_PAN)
	var said := _said(run.take_cues())
	assert_has(said, "Whoa! The altar wants fair moves.", "H9, the first break")
	assert_has(said, "The same on both pans!", "H10, see why")
	assert_true(run.moves.state.same(AltarState.make(1, 3, 0, 7, 4)), "nothing changed")
	run.carry_across(L, AltarState.GEM)
	var cues := run.take_cues()
	assert_has(_said(cues), "Moving it across changes both pans. Same on both!", "H11")
	assert_has(_said(cues), "Watch me do one.", "H15")
	assert_true(run.freed(), "the ghost took the three gems: a one-move altar")
	assert_true(run.moves.helped)


func test_after_forty_acts_the_ghost_frees_the_crystal() -> void:
	var run := AltarRun.make("entrance", 9)
	run.start()
	_solve(run)
	run.next_altar()
	_solve(run)
	run.next_altar()   # altar 3, judged
	for i in AltarRun.CAP:
		if run.freed():
			break
		run.put_back()
	assert_true(run.freed())
	assert_eq(run.moves.freed_by, AltarMoves.GHOST)
	var judged := run.beats.judged()
	assert_eq(str(judged[0].kind), SkillShown.SHOWN)


func test_show_me_does_one_step_and_counts_as_help() -> void:
	var run := AltarRun.make("entrance", 2)
	run.start()
	for i in 10:
		_solve(run)
		run.next_altar()
	assert_true(bool(run.altar().get("great", false)), "the Great Altar")
	run.take_cues()
	run.show_me()
	assert_eq(run.take_cues().filter(func(c: Dictionary) -> bool: return c.has("ghost")).size(), 1)
	assert_false(run.freed(), "one step of two")
	_solve(run)
	assert_true(run.freed())
	var last: Dictionary = run.beats.judged()[-1]
	assert_eq(str(last.kind), SkillShown.HELPED)
	assert_eq(str(last.note), "eye")


func test_a_freed_crystal_says_its_weight_and_its_gems_count_themselves() -> void:
	var run := AltarRun.make("entrance", 6)
	run.start()
	_solve(run)
	var cues := run.take_cues()
	assert_has(_said(cues), "Free! It weighs three gems!", "H6")
	assert_has(_said(cues), "Fair and square! The altar stays level.", "H5, the first twin move")
	assert_has(_said(cues), "It's flying up to the chandelier!", "H8, the first Glimmer")
	var counts := cues.filter(func(c: Dictionary) -> bool: return c.has("count"))
	assert_eq(counts.size(), 1)
	assert_eq(counts[0].count, ["one", "two", "three"], "one number word a gem (H7)")
	var freed := cues.filter(func(c: Dictionary) -> bool: return c.has("freed"))
	assert_eq(int(freed[0].weight), 3)
	assert_eq(str(freed[0].glimmer), "fox")
	run.next_altar()
	_solve(run)
	assert_does_not_have(_said(run.take_cues()), "Fair and square! The altar stays level.", "H5 is said once")


func test_the_sky_room_s_first_pop_and_its_frame() -> void:
	var run := AltarRun.make("sky", 1)
	run.start()
	var said := _said(run.take_cues())
	assert_has(said, "The Sky Room! Up here, balloons pull pans up.", "S1")
	assert_has(said, "Balloons pull pans up. Gems pull them down.", "S2: the frame (teaching)")
	assert_eq(run.moves.state.amount(run.moves.state.crystal_pan(), AltarState.BALLOON) > 0, true, "a balloon altar")
	_solve(run)
	assert_has(_said(run.take_cues()), "A gem and a balloon cancel out. Pop!", "S4, the first zero pair")
	assert_eq(str(run.beats.judged()[0].kind), SkillShown.NEW_SETTING)


func test_a_lift_with_no_twin_can_be_hinted_and_the_hint_is_help() -> void:
	var run := AltarRun.make("sky", 2)
	run.start()
	run.take_cues()
	var side := run.moves.state.crystal_pan()
	run.lift(side, AltarState.BALLOON)
	assert_true(run.moves.no_twin())
	run.hint_no_twin()
	assert_has(_said(run.take_cues()), "The other pan has none. Put it back.", "H16")
	run.put_back()
	_solve(run)
	assert_eq(str(run.beats.judged()[0].kind), SkillShown.HELPED)
	assert_eq(str(run.beats.judged()[0].note), "hint")
