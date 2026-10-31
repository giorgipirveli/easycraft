extends GutTest
## M2 Task 17 (owner feedback #21, research "Cozy / Normal / Brave"): a Survivor world's difficulty is
## chosen when it is made. Same gold in all three. Cozy: monsters hurt half as much (never 0) and a
## knock-out keeps your blocks; Brave: monsters hurt half again as much, and the world wears a badge.


func test_cozy_halves_monster_damage_but_never_to_nothing() -> void:
	assert_eq(DifficultyRules.damage(4, DifficultyRules.COZY), 2)
	assert_eq(DifficultyRules.damage(5, DifficultyRules.COZY), 2)
	assert_eq(DifficultyRules.damage(1, DifficultyRules.COZY), 1, "a hit is still a hit")


func test_normal_keeps_damage_and_brave_adds_half() -> void:
	assert_eq(DifficultyRules.damage(5, DifficultyRules.NORMAL), 5)
	assert_eq(DifficultyRules.damage(4, DifficultyRules.BRAVE), 6)
	assert_eq(DifficultyRules.damage(3, DifficultyRules.BRAVE), 5, "rounded up")


func test_no_damage_stays_no_damage_and_unknown_is_normal() -> void:
	for d: StringName in [DifficultyRules.COZY, DifficultyRules.NORMAL, DifficultyRules.BRAVE]:
		assert_eq(DifficultyRules.damage(0, d), 0)
		assert_eq(DifficultyRules.damage(-2, d), 0)
	assert_eq(DifficultyRules.damage(5, &"nightmare"), 5)


func test_each_choice_has_a_short_name_and_a_kind_line() -> void:
	for d: StringName in DifficultyRules.CHOICES:
		assert_ne(DifficultyRules.label(d), "")
		assert_lte(DifficultyRules.about(d).length(), 40, "short enough to read at a glance")
	assert_eq(DifficultyRules.CHOICES, [DifficultyRules.COZY, DifficultyRules.NORMAL, DifficultyRules.BRAVE] as Array[StringName])
	assert_true(DifficultyRules.has_badge(DifficultyRules.BRAVE))
	assert_false(DifficultyRules.has_badge(DifficultyRules.COZY), "no badge for Cozy: no shame either way")


func test_a_world_saves_its_difficulty() -> void:
	var m := WorldMeta.new_random()
	assert_eq(m.difficulty, DifficultyRules.NORMAL)
	m.difficulty = DifficultyRules.COZY
	assert_eq(WorldMeta.from_json(m.to_json()).difficulty, DifficultyRules.COZY)
	assert_eq(WorldMeta.from_json('{"seed": 5}').difficulty, DifficultyRules.NORMAL, "worlds from before")
	assert_eq(WorldMeta.from_json('{"seed": 5, "difficulty": "impossible"}').difficulty, DifficultyRules.NORMAL)
	assert_eq(WorldMeta.from_json('{"seed": 5, "difficulty": 3}').difficulty, DifficultyRules.NORMAL)
