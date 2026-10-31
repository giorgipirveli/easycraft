extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.10, rulings 4, 5, 14, 15; the lead's rulings 2 and 6;
## future-lessons.md §3.5, invisible assessment): each judged altar becomes one SkillShown event for the room's unit. Freed
## by the child with no rule break, no help and within its move budget: SOLVED in the hall, NEW_SETTING for the Great
## Altar and in the Sky Room (transfer, kept apart). Otherwise HELPED (a rule break, over budget, the ghost's step, SHOW
## ME, H16's hint) with a note saying why, or SHOWN when the ghost freed it. Taught altars are not judged.

const HALL: Array[String] = ["bowls", "gem_bag"]
const SKY: Array[String] = ["bowls", "gem_bag", "pump"]
const L := AltarState.LEFT
const R := AltarState.RIGHT


func _altar(room: String, n: int) -> Dictionary:
	for a: Dictionary in AltarHalls.altars(room):
		if int(a.n) == n:
			return a
	return {}


func _moves(lc: int, lk: int, rc: int, rk: int, x: int, tools: Array[String] = HALL) -> AltarMoves:
	return AltarMoves.start(AltarState.make(lc, lk, rc, rk, x), tools)


func test_freed_first_time_within_budget_is_solved_in_the_hall() -> void:
	var b := AltarBeats.for_room("entrance")
	var m := _moves(1, 3, 0, 7, 4)
	m.handful(L, AltarState.GEM)
	m.handful(R, AltarState.GEM)
	var r := b.judge(_altar("entrance", 3), m)
	assert_true(r.judged)
	assert_eq(r.outcome, SkillShown.SOLVED)
	assert_eq(r.kind, SkillShown.SOLVED)
	assert_true(r.counts)


func test_the_great_altar_and_the_sky_room_are_new_setting() -> void:
	var b := AltarBeats.for_room("entrance")
	var m := _moves(2, 1, 0, 7, 3)
	m.commit(AltarMoves.take(AltarState.GEM, 1))
	m.share_by(2)
	var r := b.judge(_altar("entrance", 11), m)
	assert_eq(r.kind, SkillShown.NEW_SETTING, "the lead's ruling 6")
	assert_eq(r.note, "the Great Altar")
	var sky := AltarBeats.for_room("sky")
	var s := _moves(1, -3, 0, 5, 8, SKY)
	s.commit(AltarMoves.add(AltarState.GEM, 3))
	r = sky.judge(_altar("sky", 1), s)
	assert_eq(r.kind, SkillShown.NEW_SETTING)
	assert_eq(r.note, "the Sky Room", "a transfer notes where it happened")


func test_a_rule_break_makes_it_helped_with_the_misconception_noted() -> void:
	var b := AltarBeats.for_room("entrance")
	var m := _moves(1, 3, 0, 7, 4)
	m.lift(L, AltarState.GEM)
	m.tap_crystal()
	m.handful(L, AltarState.GEM)
	m.handful(R, AltarState.GEM)
	var r := b.judge(_altar("entrance", 3), m)
	assert_eq(r.kind, SkillShown.HELPED, "right, but not the first time (ruling 15)")
	assert_eq(r.note, AltarMoves.ONE_PAN)
	assert_false(r.counts)


func test_over_the_budget_is_helped() -> void:
	var b := AltarBeats.for_room("entrance")
	var m := _moves(1, 3, 0, 7, 4)
	m.commit(AltarMoves.take(AltarState.GEM, 1))
	m.commit(AltarMoves.add(AltarState.GEM, 1))
	m.commit(AltarMoves.take(AltarState.GEM, 3))
	assert_true(m.freed())
	var r := b.judge(_altar("entrance", 3), m)
	assert_eq(r.kind, SkillShown.HELPED, "a one-move altar must be freed in one move (ruling 5)")
	assert_eq(r.note, "over budget")
	var two := _moves(2, 1, 0, 7, 3)
	two.commit(AltarMoves.take(AltarState.GEM, 1))
	two.commit(AltarMoves.add(AltarState.GEM, 1))
	two.commit(AltarMoves.take(AltarState.GEM, 1))
	two.share_by(2)
	assert_eq(b.judge(_altar("entrance", 11), two).kind, SkillShown.HELPED, "4 moves where 2 + 1 are allowed")
	var detour := _moves(2, 1, 0, 7, 3)
	detour.commit(AltarMoves.add(AltarState.GEM, 1))
	detour.share_by(2)
	detour.commit(AltarMoves.take(AltarState.GEM, 1))
	assert_eq(b.judge(_altar("entrance", 11), detour).kind, SkillShown.NEW_SETTING, "3 moves: within the budget")


func test_help_is_noted_and_the_ghost_freeing_it_is_shown() -> void:
	var b := AltarBeats.for_room("entrance")
	var eye := _moves(2, 1, 0, 7, 3)
	eye.note_help(AltarMoves.EYE)
	eye.commit(AltarMoves.take(AltarState.GEM, 1), AltarMoves.GHOST)
	eye.share_by(2)
	var r := b.judge(_altar("entrance", 11), eye)
	assert_eq(r.kind, SkillShown.HELPED)
	assert_eq(r.note, "eye")
	var shown := _moves(1, 3, 0, 7, 4)
	shown.note_help(AltarMoves.GHOST_STEP)
	shown.commit(AltarMoves.take(AltarState.GEM, 3), AltarMoves.GHOST)
	r = b.judge(_altar("entrance", 3), shown)
	assert_eq(r.kind, SkillShown.SHOWN)
	assert_eq(r.note, "ghost step")
	var hint := _moves(1, -3, 0, 5, 8, SKY)
	hint.note_help(AltarMoves.HINT)
	hint.commit(AltarMoves.add(AltarState.GEM, 3))
	assert_eq(AltarBeats.for_room("sky").judge(_altar("sky", 1), hint).kind, SkillShown.HELPED, "H16's hint is help")


func test_taught_altars_are_not_judged() -> void:
	var b := AltarBeats.for_room("entrance")
	var m := _moves(1, 2, 0, 5, 3)
	m.commit(AltarMoves.take(AltarState.GEM, 2))
	var r := b.judge(_altar("entrance", 1), m)
	assert_false(r.judged)
	assert_eq(b.total(), 0)


func test_the_events_go_to_the_record() -> void:
	var b := AltarBeats.for_room("entrance")
	var good := _moves(1, 3, 0, 7, 4)
	good.commit(AltarMoves.take(AltarState.GEM, 3))
	b.judge(_altar("entrance", 3), good)
	var broke := _moves(0, 9, 1, 2, 7)
	broke.carry_across(R, AltarState.GEM)
	broke.commit(AltarMoves.take(AltarState.GEM, 2))
	b.judge(_altar("entrance", 4), broke)
	var shown := SkillShown.begin()
	assert_eq(b.record(shown), 2)
	assert_eq(shown.total("g6.maths.equations"), 2)
	assert_eq(shown.right_first("g6.maths.equations"), 1)
	var events: Array = shown.events["g6.maths.equations"]
	assert_eq(str(events[1].note), AltarMoves.ACROSS)
	assert_eq(b.right_first(), 1)
	assert_false(b.masters(), "1 of 2")
