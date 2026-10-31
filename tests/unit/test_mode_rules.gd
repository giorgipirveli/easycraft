extends GutTest
## Game modes (M2 §12.1): what Sandbox and Survivor each allow.


func test_sandbox_is_unlimited_with_gentle_monsters() -> void:
	for rule: StringName in [ModeRules.GHOST, ModeRules.FREE_FLY, ModeRules.UNLIMITED_BLOCKS, ModeRules.CHEATS,
			ModeRules.INFINITE_GOLD, ModeRules.DAMAGE, ModeRules.MONSTER_SPAWNS, ModeRules.GENTLE_MONSTERS]:
		assert_true(ModeRules.allows(ModeRules.SANDBOX, rule), "sandbox: %s" % rule)
	assert_false(ModeRules.allows(ModeRules.SANDBOX, ModeRules.LOSSES), "sandbox: a knock-out costs nothing")


func test_survivor_counts_everything_and_has_nights_to_survive() -> void:
	for rule: StringName in [ModeRules.DAMAGE, ModeRules.LOSSES, ModeRules.MONSTER_SPAWNS]:
		assert_true(ModeRules.allows(ModeRules.SURVIVOR, rule), "survivor: %s" % rule)
	for rule: StringName in [ModeRules.GHOST, ModeRules.FREE_FLY, ModeRules.UNLIMITED_BLOCKS, ModeRules.CHEATS,
			ModeRules.INFINITE_GOLD, ModeRules.GENTLE_MONSTERS]:
		assert_false(ModeRules.allows(ModeRules.SURVIVOR, rule), "survivor: no %s" % rule)


func test_an_unknown_mode_is_sandbox_and_an_unknown_rule_is_refused() -> void:
	assert_eq(ModeRules.valid(&"space"), ModeRules.SANDBOX)
	assert_eq(ModeRules.valid(ModeRules.SURVIVOR), ModeRules.SURVIVOR)
	assert_false(ModeRules.allows(ModeRules.SANDBOX, &"teleport_to_mars"))


func test_each_mode_has_its_own_save_slot() -> void:
	assert_ne(ModeRules.slot(ModeRules.SANDBOX), ModeRules.slot(ModeRules.SURVIVOR))
	assert_eq(ModeRules.slot(ModeRules.SANDBOX), "sandbox_1", "old Sandbox saves keep working")


## M3 Task 6 (spec §14.3): the Physics Lab (Moon, Zero-G, Slow motion) is a Sandbox thing.
func test_the_physics_lab_is_sandbox_only() -> void:
	assert_true(ModeRules.allows(ModeRules.SANDBOX, ModeRules.PHYSICS_LAB))
	assert_false(ModeRules.allows(ModeRules.SURVIVOR, ModeRules.PHYSICS_LAB))


## Owner feedback #44 (spec §12.20): MONSTER WAVE is a third mode — hearts and the Totem's waves, nothing to
## build, no flying, no night monsters, no bags, real gold (never ∞), its own arena slot per universe.
func test_monster_wave_is_a_mode_of_its_own() -> void:
	assert_eq(ModeRules.WAVE, &"wave")
	assert_eq(ModeRules.MODES, [ModeRules.SANDBOX, ModeRules.SURVIVOR, ModeRules.WAVE] as Array[StringName])
	assert_eq(ModeRules.valid(&"wave"), ModeRules.WAVE)
	for rule: StringName in [ModeRules.DAMAGE, ModeRules.TOTEM]:
		assert_true(ModeRules.allows(ModeRules.WAVE, rule), "wave: %s" % rule)
	for rule: StringName in [ModeRules.GHOST, ModeRules.FREE_FLY, ModeRules.FLYING, ModeRules.UNLIMITED_BLOCKS,
			ModeRules.CHEATS, ModeRules.INFINITE_GOLD, ModeRules.LOSSES, ModeRules.MONSTER_SPAWNS,
			ModeRules.GENTLE_MONSTERS, ModeRules.PHYSICS_LAB, ModeRules.BUILDING]:
		assert_false(ModeRules.allows(ModeRules.WAVE, rule), "wave: no %s" % rule)


func test_building_and_flying_are_sandbox_and_survivor_things() -> void:
	for mode: StringName in [ModeRules.SANDBOX, ModeRules.SURVIVOR]:
		assert_true(ModeRules.allows(mode, ModeRules.BUILDING), "%s builds" % mode)
		assert_true(ModeRules.allows(mode, ModeRules.FLYING), "%s flies (Survivor pays)" % mode)


## Owner feedback #44: Survivor has no Totem waves (and so no boss); Sandbox keeps its gentle waves.
func test_the_totem_stands_in_sandbox_and_monster_wave_not_survivor() -> void:
	assert_true(ModeRules.allows(ModeRules.SANDBOX, ModeRules.TOTEM))
	assert_true(ModeRules.allows(ModeRules.WAVE, ModeRules.TOTEM))
	assert_false(ModeRules.allows(ModeRules.SURVIVOR, ModeRules.TOTEM))


func test_each_universe_has_its_own_arena() -> void:
	assert_eq(ModeRules.slot(ModeRules.WAVE, 1), "wave_1")
	assert_eq(ModeRules.slot(ModeRules.WAVE, 3), "wave_3")
	assert_eq(ModeRules.slot(ModeRules.WAVE), "wave_1")
	assert_ne(ModeRules.slot(ModeRules.WAVE, 1), ModeRules.slot(ModeRules.SURVIVOR, 1))
