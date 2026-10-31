extends GutTest
## Owner #133, #134 (docs/design/games/balance-altar.md §3.4, §3.5's rules table, §4.3; the phase A model
## model/altar_rules.py): an altar is two pans that weigh the same for the crystal's hidden weight. A pan holds net
## amounts: crystals (each weighs x; negative: crystal balloons) and gems (+1; negative: balloons, so a gem and a balloon
## on one pan have already cancelled). The crystal is freed when it stands alone on its pan (one crystal, nothing else)
## and the other pan holds no crystal: that pan then shows its weight.


func test_an_altar_holds_when_both_pans_weigh_the_same_for_the_hidden_weight() -> void:
	var s := AltarState.make(1, 3, 0, 7, 4)   # a crystal and three gems | seven gems
	assert_true(s.holds(), "4 + 3 = 7")
	assert_false(AltarState.make(1, 3, 0, 8, 4).holds(), "4 + 3 is not 8")
	assert_true(AltarState.make(2, 0, 0, 6, 3).holds(), "two crystals weigh six")
	assert_true(AltarState.make(1, -3, 0, 5, 8).holds(), "a crystal and three balloons weigh five gems (x - 3 = 5)")
	assert_true(AltarState.make(0, 7, 1, 3, 4).holds(), "the crystal on the right")


func test_what_a_pan_holds_by_kind() -> void:
	var s := AltarState.make(2, -3, 0, 5, 4)
	assert_eq(s.amount(AltarState.LEFT, AltarState.CRYSTAL), 2)
	assert_eq(s.amount(AltarState.LEFT, AltarState.BALLOON), 3, "net -3 gems: three balloons")
	assert_eq(s.amount(AltarState.LEFT, AltarState.GEM), 0)
	assert_eq(s.amount(AltarState.RIGHT, AltarState.GEM), 5)
	assert_eq(s.amount(AltarState.RIGHT, AltarState.BALLOON), 0)
	assert_eq(s.amount(AltarState.RIGHT, AltarState.CRYSTAL), 0)
	var negative := AltarState.make(-2, 1, -1, 3, 2)
	assert_eq(negative.amount(AltarState.LEFT, AltarState.CRYSTAL_BALLOON), 2, "rung 7's crystal balloons (-x)")
	assert_eq(negative.amount(AltarState.LEFT, AltarState.CRYSTAL), 0)


func test_freed_only_when_the_crystal_stands_alone_and_the_other_pan_has_none() -> void:
	assert_true(AltarState.make(1, 0, 0, 4, 4).freed())
	assert_true(AltarState.make(0, 4, 1, 0, 4).freed(), "on the right too")
	assert_false(AltarState.make(1, 2, 0, 6, 4).freed(), "gems beside it")
	assert_false(AltarState.make(2, 0, 0, 8, 4).freed(), "two crystals")
	assert_false(AltarState.make(1, 0, 1, 0, 4).freed(), "a crystal on the other pan")
	assert_false(AltarState.make(1, -1, 0, 3, 4).freed(), "a balloon beside it")


func test_the_crystal_s_pan_is_the_only_pan_with_crystals_else_the_one_with_more() -> void:
	assert_eq(AltarState.make(1, 3, 0, 7, 4).crystal_pan(), AltarState.LEFT)
	assert_eq(AltarState.make(0, 7, 1, 3, 4).crystal_pan(), AltarState.RIGHT)
	assert_eq(AltarState.make(3, 1, 1, 9, 4).crystal_pan(), AltarState.LEFT, "more crystals")
	assert_eq(AltarState.make(1, 9, 3, 1, 4).crystal_pan(), AltarState.RIGHT)
	assert_eq(AltarState.make(2, 1, 2, 1, 4).crystal_pan(), AltarState.LEFT, "a tie: the left")


func test_clutter_is_how_far_the_crystal_is_from_alone() -> void:
	assert_eq(AltarState.make(1, 0, 0, 4, 4).clutter(), 0)
	assert_eq(AltarState.make(1, 3, 0, 7, 4).clutter(), 3)
	assert_eq(AltarState.make(3, 2, 0, 14, 4).clutter(), 4, "two extra crystals and two gems")
	assert_eq(AltarState.make(1, -2, 1, 1, 4).clutter(), 3, "two balloons and a crystal on the other pan")


func test_copies_keys_and_equality() -> void:
	var s := AltarState.make(2, 1, 0, 9, 4)
	var t := s.copy()
	assert_true(s.same(t))
	assert_eq(s.key(), t.key())
	t.lk = 5
	assert_false(s.same(t), "a copy is its own")
	assert_eq(s.lk, 1)
	assert_ne(s.key(), t.key())
	assert_eq(s.key(), Vector4i(2, 1, 0, 9))


func test_the_freed_crystal_s_weight_is_what_the_other_pan_shows() -> void:
	assert_eq(AltarState.make(1, 0, 0, 4, 4).shown_weight(), 4)
	assert_eq(AltarState.make(0, 6, 1, 0, 6).shown_weight(), 6)
	assert_eq(AltarState.make(1, 2, 0, 6, 4).shown_weight(), -1, "not freed: nothing shown")
