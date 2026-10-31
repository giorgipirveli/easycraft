extends GutTest
## What bot friends learn about their child (M2 Task 18, spec §12.17): favourite blocks and shapes,
## which designs the child keeps, what the child follows (ores, animals, secrets), how much space the
## child likes, and which side the monsters come from.


func _mind() -> Mind:
	return Mind.create(BotSpecies.table(), "Pip")


# --- Favourite blocks and shapes ---

func test_the_childs_favourite_blocks_come_first() -> void:
	var s := BotStyle.new()
	for i in 5:
		s.saw_block(BlockIds.BLUE, Vector3i(i, 10, 0), BotStyle.NO_CELL)
	for i in 2:
		s.saw_block(BlockIds.GLASS, Vector3i(i, 11, 5), BotStyle.NO_CELL)
	s.saw_block(BlockIds.WATER, Vector3i(0, 10, 9), BotStyle.NO_CELL)
	s.saw_block(BlockIds.BED, Vector3i(0, 10, 9), BotStyle.NO_CELL)
	assert_eq(s.favourite_blocks(), [BlockIds.BLUE, BlockIds.GLASS] as Array[int], "water and beds are not build blocks")


func test_at_most_eight_favourites_and_old_ones_fade() -> void:
	var s := BotStyle.new()
	for id in [BlockIds.RED, BlockIds.YELLOW, BlockIds.GREEN, BlockIds.BLUE, BlockIds.PURPLE, BlockIds.BRICK,
			BlockIds.GLASS, BlockIds.PLANKS, BlockIds.STONE, BlockIds.SAND]:
		s.saw_block(id, Vector3i.ZERO, BotStyle.NO_CELL)
	assert_lte(s.favourites.size(), BotStyle.MAX_FAVOURITES)
	for i in 30:
		s.saw_block(BlockIds.DIRT, Vector3i.ZERO, BotStyle.NO_CELL)
	assert_eq(s.favourite_blocks()[0], BlockIds.DIRT, "what the child builds with now counts most")


func test_a_design_is_built_in_the_childs_blocks() -> void:
	var s := BotStyle.new()
	for i in 4:
		s.saw_block(BlockIds.BRICK, Vector3i(i, 10, 0), BotStyle.NO_CELL)
	for i in 3:
		s.saw_block(BlockIds.GLASS, Vector3i(i, 11, 0), BotStyle.NO_CELL)
	var rainbow: Array = BotRules.SANDBOX_DESIGNS[2]
	var styled := s.style_design(rainbow)
	assert_eq(styled.size(), rainbow.size())
	for cell: Array in styled:
		assert_true(cell[1] in [BlockIds.BRICK, BlockIds.GLASS], "only the child's blocks: %s" % [cell])
	var lamp := s.style_design(BotRules.SANDBOX_DESIGNS[0])
	assert_eq(lamp[2][1], BlockIds.LIGHT, "a lamp keeps its light")
	var planter := s.style_design(BotRules.SANDBOX_DESIGNS[1])
	assert_eq(planter[2][1], BlockIds.LEAVES, "a planter keeps its plants")
	assert_eq(BotStyle.new().style_design(rainbow), rainbow, "nothing learned yet: the design as it is")


func test_it_notices_whether_the_child_builds_tall_or_wide() -> void:
	var tall := BotStyle.new()
	var prev := BotStyle.NO_CELL
	for y in 8:
		var cell := Vector3i(0, 10 + y, 0)
		tall.saw_block(BlockIds.BRICK, cell, prev)
		prev = cell
	var wide := BotStyle.new()
	prev = BotStyle.NO_CELL
	for x in 8:
		var cell := Vector3i(x, 10, 0)
		wide.saw_block(BlockIds.BRICK, cell, prev)
		prev = cell
	assert_gt(tall.shape().x, 0.5, "towers")
	assert_lt(tall.shape().y, 0.1)
	assert_gt(wide.shape().y, 0.5, "walls and floors")


func test_tall_builders_get_tall_designs() -> void:
	var m := _mind()
	var s := BotStyle.new()
	var prev := BotStyle.NO_CELL
	for y in 10:
		var cell := Vector3i(0, 10 + y, 0)
		s.saw_block(BlockIds.BRICK, cell, prev)
		prev = cell
	var counts := {}
	for i in 60:
		var d := BotSpecies.pick_design(m, s, 5)
		counts[d] = int(counts.get(d, 0)) + 1
	var tall := int(counts.get(0, 0)) + int(counts.get(2, 0)) + int(counts.get(3, 0))
	assert_gt(tall, 40, "pillars and lamp posts for a tower builder: %s" % [counts])


func test_a_design_the_child_breaks_is_built_less_and_one_it_keeps_more() -> void:
	var m := _mind()
	var s := BotStyle.new()
	var before := _design_share(m, s, 4)
	for i in 4:
		BotSpecies.pick_design(m, s, 5)
		m.action = 4
		m.feel(&"broken")
	assert_lt(_design_share(m, s, 4), before, "the little flower keeps being broken")
	var kept_before := _design_share(m, s, 1)
	for i in 4:
		BotSpecies.pick_design(m, s, 5)
		m.action = 1
		m.feel(&"kept")
	assert_gt(_design_share(m, s, 1), kept_before, "the planter stays: more planters")


func _design_share(m: Mind, s: BotStyle, design: int) -> float:
	var probs := BotSpecies.design_odds(m, s, 5)
	return probs[design]


# --- What the child follows ---

func test_an_explorer_learns_what_the_child_follows() -> void:
	var m := _mind()
	var both := BotSpecies.find_mask([BotSpecies.FIND_ORE, BotSpecies.FIND_ANIMAL])
	var start := BotSpecies.find_odds(m, both)
	for i in 4:
		BotSpecies.pick_find(m, both)          # it thinks about what to show, then shows an ore
		m.action = BotSpecies.index(BotSpecies.FIND_ORE)
		m.feel(&"ignored")                     # the child walks on
		BotSpecies.pick_find(m, both)
		m.action = BotSpecies.index(BotSpecies.FIND_ANIMAL)
		m.feel(&"used")                        # the child tames the dog it showed
	var after := BotSpecies.find_odds(m, both)
	assert_gt(after[BotSpecies.index(BotSpecies.FIND_ANIMAL)], start[BotSpecies.index(BotSpecies.FIND_ANIMAL)])
	assert_gt(after[BotSpecies.index(BotSpecies.FIND_ANIMAL)], 0.8, "animals first now")
	var picks := {}
	for i in 40:
		var k := BotSpecies.pick_find(m, both)
		picks[k] = int(picks.get(k, 0)) + 1
	assert_gt(int(picks.get(BotSpecies.FIND_ANIMAL, 0)), 30, "%s" % [picks])


# --- Space and guarding ---

func test_the_child_walking_away_gives_more_space_and_coming_close_less() -> void:
	var s := BotStyle.new()
	assert_eq(s.space, 0.0)
	for i in 3:
		s.walked_away()
	assert_eq(s.space, 3.0)
	for i in 20:
		s.walked_away()
	assert_eq(s.space, BotStyle.MAX_SPACE, "never too far")
	s.came_close()
	assert_eq(s.space, BotStyle.MAX_SPACE - 0.5)


func test_a_fighter_remembers_the_side_monsters_come_from() -> void:
	var s := BotStyle.new()
	assert_true(is_nan(s.guard_angle()), "no side yet")
	for i in 4:
		s.note_danger(0.1)          # east (+X)
	s.note_danger(PI)
	var a := s.guard_angle()
	assert_false(is_nan(a))
	assert_almost_eq(cos(a), 1.0, 0.1, "guards the east")


func test_the_style_saves_small_and_round_trips() -> void:
	var s := BotStyle.new()
	for i in 6:
		s.saw_block(BlockIds.BLUE, Vector3i(0, i, 0), Vector3i(0, i - 1, 0))
	s.walked_away()
	s.note_danger(1.0)
	s.note_danger(1.0)
	var text := JSON.stringify(s.to_save())
	assert_lte(text.length(), 600)
	var back := BotStyle.from_save(JSON.parse_string(text))
	assert_eq(back.favourite_blocks(), s.favourite_blocks())
	assert_eq(back.space, s.space)
	assert_almost_eq(back.shape(), s.shape(), Vector2.ONE * 0.01)
	assert_almost_eq(back.guard_angle(), s.guard_angle(), 0.01)
	for bad: Variant in [null, 1, {"f": {"x": 1}, "sp": NAN, "si": [1, 2]}, {"f": {"999": 3, "11": 2}}]:
		var b := BotStyle.from_save(bad)
		assert_eq(b.favourite_blocks(), [] as Array[int], "no bad blocks: %s" % [bad])
		assert_between(b.space, 0.0, BotStyle.MAX_SPACE)
