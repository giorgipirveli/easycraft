extends GutTest
## Bees and butterflies over Green Meadows (owner feedback #41, spec §14.19): cheap ambient particles round this
## game's player — by day, outdoors, over the meadow's grass and bushes (our flowers) — never at night, in a
## cave or over sand and stone. One particle system each, the shared Fx material, nothing sent.


func test_they_fly_by_day_over_the_meadow_only() -> void:
	assert_true(InsectRules.on(DayCycle.NOON, 0.0, BlockIds.GRASS), "a sunny meadow")
	assert_true(InsectRules.on(DayCycle.NOON, 0.0, BlockIds.BUSH), "by the bushes")
	assert_false(InsectRules.on(0.95, 0.0, BlockIds.GRASS), "not at night")
	assert_false(InsectRules.on(DayCycle.NOON, 0.8, BlockIds.GRASS), "not in a cave")
	assert_false(InsectRules.on(DayCycle.NOON, 0.0, BlockIds.SAND), "not over the beach")
	assert_false(InsectRules.on(DayCycle.NOON, 0.0, BlockIds.STONE), "nor bare rock")


func test_only_green_meadows_has_them() -> void:
	assert_true(UniverseRegistry.descriptor(1).get("insects"), "Green Meadows")
	for u in range(2, 5):
		assert_false(UniverseRegistry.descriptor(u).get("insects") == true, "not universe %d" % u)


func test_a_few_cheap_particles_with_the_shared_material() -> void:
	var bugs := MeadowInsects.new()
	add_child_autofree(bugs)
	var systems := bugs.find_children("*", "CPUParticles3D", true, false)
	assert_eq(systems.size(), 2, "one for the butterflies, one for the bees")
	for p: CPUParticles3D in systems:
		assert_lte(p.amount, 16, "a few, not a swarm")
		assert_same(p.mesh.surface_get_material(0), Fx.material(), "the shared material: no new shader")
		assert_false(p.local_coords, "they stay in the world while the child walks")
		assert_false(p.emitting, "off until the meadow says so")


func test_they_come_and_go_with_the_meadow() -> void:
	var bugs := MeadowInsects.new()
	var ground := [BlockIds.GRASS]
	var t := [DayCycle.NOON]
	bugs.time_of_day = func() -> float: return t[0]
	bugs.ground = func() -> int: return ground[0]
	var who := Node3D.new()
	add_child_autofree(who)
	bugs.player = who
	add_child_autofree(bugs)
	bugs.tick(1.0)
	assert_true(bugs.flying(), "over the grass by day")
	t[0] = 0.95
	bugs.tick(1.0)
	assert_false(bugs.flying(), "gone at night")
	t[0] = DayCycle.NOON
	ground[0] = BlockIds.SAND
	bugs.tick(1.0)
	assert_false(bugs.flying(), "gone over the sand")
