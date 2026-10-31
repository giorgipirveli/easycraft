extends GutTest
## Owner #94 (the animations brief §2): the world's ambient life is pooled and budgeted: one particle system of
## fireflies and one multimesh of birds round this game's player, on only when LifeRules says, sharing materials the
## game already draws (no new shader), and cheap every frame; a broken tree or flower lets leaves or petals flutter;
## the Launch Site's tower light blinks and its flag waves.


func _life(t: Array, ground: Array) -> AmbientLife:
	var life := AmbientLife.new()
	var who := Node3D.new()
	add_child_autofree(who)
	life.player = who
	life.time_of_day = func() -> float: return t[0]
	life.ground = func() -> int: return ground[0]
	add_child_autofree(life)
	return life


func test_the_meadow_s_life_comes_and_goes_with_night_and_day() -> void:
	var t := [DayCycle.NOON]
	var ground := [BlockIds.GRASS]
	var life := _life(t, ground)
	life.tick(0.3)
	assert_true(life.birds.visible, "birds by day")
	assert_false(life.fireflies.emitting, "no fireflies by day")
	t[0] = 0.95
	life.tick(0.3)
	assert_false(life.birds.visible, "the birds roost at night")
	assert_true(life.fireflies.emitting, "fireflies at night over the grass")
	ground[0] = BlockIds.SAND
	life.tick(0.3)
	assert_false(life.fireflies.emitting, "not over the sand")
	life.player = null
	life.tick(0.3)
	assert_false(life.birds.visible)
	assert_false(life.fireflies.emitting, "nobody to see them")


func test_it_follows_the_player() -> void:
	var life := _life([DayCycle.NOON], [BlockIds.GRASS])
	(life.player as Node3D).global_position = Vector3(100, 20, -40)
	life.tick(0.3)
	assert_almost_eq(life.fireflies.global_position.x, 100.0, 0.01)
	assert_almost_eq(life.birds.middle().y, 20.0 + LifeRules.FLOCK_HEIGHT, 0.01, "the flock high over the player")
	(life.player as Node3D).global_position = Vector3(200, 20, -40)
	for i in 30:
		life.tick(0.1)
	assert_gt(life.birds.middle().x, 100.0, "the flock drifts after the player")
	assert_lt(life.birds.middle().x, 200.0, "gently, not in a jump")


func test_a_few_pooled_pieces_with_shared_materials() -> void:
	var life := _life([DayCycle.NOON], [BlockIds.GRASS])
	var f := life.fireflies
	assert_lte(f.amount, LifeRules.FIREFLIES, "a few, not a swarm")
	assert_same(f.mesh.surface_get_material(0), GolemModels.glow_material(), "the golem's glow: no new shader")
	assert_false(f.local_coords, "they stay put while the child walks")
	assert_eq(f.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	var b := life.birds
	assert_eq(b.multimesh.instance_count, b.count * 3, "a body and two wings a bird, in one multimesh")
	assert_same(b.multimesh.mesh.surface_get_material(0), Fx.material(), "Fx's particle material: no new shader")
	assert_true(b.multimesh.use_colors and b.multimesh.use_custom_data, "drawn exactly like a CPUParticles3D")
	assert_ne(b.multimesh.custom_aabb, AABB(), "a fixed bounding box: nothing recomputed as they fly")
	assert_eq(b.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func test_the_wings_beat_and_stay_on_the_body() -> void:
	var t := 0.1   # flapping then (LifeRules.bird_flap)
	var a := Birds.part_transform(0, 2, t)
	var b := Birds.part_transform(0, 2, t + 0.05)
	assert_ne(a.basis, b.basis, "a wing beats")
	for part in [1, 2]:
		var wing := Birds.part_transform(0, part, t)
		var body := Birds.part_transform(0, 0, t)
		assert_lt(wing.origin.distance_to(body.origin), Birds.BODY.x + Birds.WING.x, "wing %d at the body's side" % part)
	var left := Birds.part_transform(0, 1, t).origin - Birds.part_transform(0, 0, t).origin
	var right := Birds.part_transform(0, 2, t).origin - Birds.part_transform(0, 0, t).origin
	assert_lt(left.dot(right), 0.0, "one each side")


func test_every_frame_is_cheap() -> void:
	var life := _life([DayCycle.NOON], [BlockIds.GRASS])
	life.tick(0.3)
	var t0 := Time.get_ticks_usec()
	for i in 600:
		life.tick(1.0 / 60.0)
	var per := (Time.get_ticks_usec() - t0) / 600.0
	gut.p("MEASURE ambient life tick %.1f us (birds flying)" % per)
	assert_lt(per, 250.0, "a small share of a frame (phones 3-5x)")


func test_a_broken_tree_lets_its_leaves_flutter_down() -> void:
	var root := Node3D.new()
	add_child_autofree(root)
	Fx.reset_budget()
	Fx.break_block(root, Vector3i(0, 5, 0), BlockIds.STONE)
	assert_eq(root.get_child_count(), 1, "stone: its bits only")
	Fx.break_block(root, Vector3i(0, 5, 0), BlockIds.LEAVES)
	assert_eq(root.get_child_count(), 3, "leaves: its bits and the leaves fluttering")
	var leaves := root.get_child(2) as CPUParticles3D
	assert_lt(leaves.gravity.y, 0.0)
	assert_gt(leaves.gravity.y, -2.0, "they float down slowly")
	assert_same(leaves.mesh.surface_get_material(0), Fx.material(), "Fx's material")
	Fx.break_block(root, Vector3i(0, 5, 0), BlockIds.FLOWERS)
	assert_eq(root.get_child_count(), 5, "flowers: petals")


func test_the_launch_site_s_light_blinks_and_its_flag_waves() -> void:
	var site := LaunchBuildings.new()
	site.setup({"pos": Vector3i.ZERO, "facing": 0})
	add_child_autofree(site)
	var blinkers := site.find_children("*", "Blinker", true, false)
	var flags := site.find_children("*", "WavingFlag", true, false)
	assert_eq(blinkers.size(), 1, "the tower's warning light")
	assert_eq(flags.size(), 1, "a flag on Mission Control")
	var light: Blinker = blinkers[0]
	assert_same(light.light.mesh.surface_get_material(0), GolemModels.glow_material(), "the golem's glow")
	var seen := {}
	for i in 30:
		light._process(0.1)
		seen[light.light.visible] = true
	assert_eq(seen.size(), 2, "on and off")
	var flag: WavingFlag = flags[0]
	flag.wave(0.4)
	assert_ne(flag.hinges[2].rotation.y, 0.0, "it waves")
