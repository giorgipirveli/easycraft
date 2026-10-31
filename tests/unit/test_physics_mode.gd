extends GutTest


func test_next_cycles_through_all_modes() -> void:
	assert_eq(PhysicsMode.next(PhysicsMode.Mode.NORMAL, true), PhysicsMode.Mode.FLY)
	assert_eq(PhysicsMode.next(PhysicsMode.Mode.FLY, true), PhysicsMode.Mode.GHOST)
	assert_eq(PhysicsMode.next(PhysicsMode.Mode.GHOST, true), PhysicsMode.Mode.NORMAL)


func test_gravity_only_in_normal() -> void:
	assert_true(PhysicsMode.has_gravity(PhysicsMode.Mode.NORMAL))
	assert_false(PhysicsMode.has_gravity(PhysicsMode.Mode.FLY))
	assert_false(PhysicsMode.has_gravity(PhysicsMode.Mode.GHOST))


func test_collision_off_only_in_ghost() -> void:
	assert_true(PhysicsMode.has_collision(PhysicsMode.Mode.NORMAL))
	assert_true(PhysicsMode.has_collision(PhysicsMode.Mode.FLY))
	assert_false(PhysicsMode.has_collision(PhysicsMode.Mode.GHOST))


func test_every_mode_has_a_name() -> void:
	for m in [PhysicsMode.Mode.NORMAL, PhysicsMode.Mode.FLY, PhysicsMode.Mode.GHOST]:
		assert_ne(PhysicsMode.display_name(m), "")


## M2 §12.1: Survivor has no Ghost mode; the switch goes NORMAL -> FLY -> NORMAL.
func test_the_switch_skips_ghost_when_it_is_not_allowed() -> void:
	assert_eq(PhysicsMode.next(PhysicsMode.Mode.NORMAL, false), PhysicsMode.Mode.FLY)
	assert_eq(PhysicsMode.next(PhysicsMode.Mode.FLY, false), PhysicsMode.Mode.NORMAL)
	assert_eq(PhysicsMode.next(PhysicsMode.Mode.GHOST, false), PhysicsMode.Mode.NORMAL, "leaving a saved ghost")
	assert_eq(PhysicsMode.next(PhysicsMode.Mode.FLY, true), PhysicsMode.Mode.GHOST, "Sandbox keeps it")
