extends GutTest
## M5 Task 2, the particle pass (spec §15.2): Fx keeps at most Fx.MAX_LIVE bursts alive (the oldest ends early),
## skips bursts far from this device's camera (a stand-in that is never drawn comes back, so callers can still set
## it up), and gives the big moments one style with the shared material: a buddy waking (gold stars), a portal
## (rainbow-gold), a level-up (gold stars rising round the child) and many-coloured confetti in one emitter.

var _cam: Camera3D


func before_each() -> void:
	Fx.reset_budget()


func after_each() -> void:
	for n in get_children():
		if n is CPUParticles3D:
			n.free()
	if is_instance_valid(_cam):
		_cam.free()
	Fx.reset_budget()


func _particles() -> Array[CPUParticles3D]:
	var list: Array[CPUParticles3D] = []
	for n in get_children():
		if n is CPUParticles3D and not n.is_queued_for_deletion():
			list.append(n)
	return list


func _camera_at(pos: Vector3) -> void:
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.global_position = pos
	_cam.current = true


func test_at_most_max_live_bursts_and_the_oldest_ends_early() -> void:
	var made: Array[CPUParticles3D] = []
	for i in Fx.MAX_LIVE + 6:
		made.append(Fx.burst(self, Vector3(i * 0.1, 0, 0), Color.RED))
	assert_eq(_particles().size(), Fx.MAX_LIVE, "never more than %d at once" % Fx.MAX_LIVE)
	assert_true(made[0].is_queued_for_deletion(), "the oldest ends early")
	assert_true(made[5].is_queued_for_deletion())
	assert_false(made[6].is_queued_for_deletion(), "the rest keep going")
	assert_false(made[-1].is_queued_for_deletion(), "the newest (the child's own action) always shows")
	assert_eq(Fx.live(), Fx.MAX_LIVE)
	assert_eq(Fx.cut, 6)


func test_finished_or_freed_bursts_leave_room() -> void:
	for i in Fx.MAX_LIVE:
		Fx.burst(self, Vector3.ZERO, Color.RED)
	for p in _particles():
		p.free()
	assert_eq(Fx.live(), 0, "gone bursts are not counted")
	var p := Fx.burst(self, Vector3.ZERO, Color.BLUE)
	assert_true(p.is_inside_tree())
	assert_eq(Fx.cut, 0)


func test_a_burst_far_from_the_camera_is_not_made() -> void:
	_camera_at(Vector3.ZERO)
	var near := Fx.burst(self, Vector3(0, 0, -10), Color.RED)
	var far := Fx.burst(self, Vector3(0, 0, -(Fx.FAR + 5.0)), Color.RED)
	assert_true(near.is_inside_tree(), "near: drawn")
	assert_not_null(far, "far: a stand-in comes back, so a caller can still set it up")
	assert_false(far.is_inside_tree(), "... but it is never drawn")
	far.scale_amount_min = 2.0   # callers do this: harmless
	assert_eq(_particles().size(), 1)
	assert_eq(Fx.skipped, 1)
	await wait_process_frames(1)
	assert_false(is_instance_valid(far), "and gone at the end of the frame")


func test_without_a_camera_every_burst_is_made() -> void:
	var p := Fx.burst(self, Vector3(500, 0, 0), Color.RED)
	assert_true(p.is_inside_tree(), "nothing to measure from: it shows")


func test_the_budget_counts_every_kind_of_effect() -> void:
	var body := Node3D.new()
	add_child_autofree(body)
	Fx.ripple(self, Vector3.ZERO)
	Fx.spikes(self, Vector3i.ZERO)
	Fx.coin_shower(self, Vector3.ZERO, 10)
	Fx.drips(body, 0.3)
	Fx.wake(self, Vector3.ZERO)
	assert_eq(Fx.live(), 5)


func test_a_buddy_waking_throws_gold_stars_that_float_up() -> void:
	var p := Fx.wake(self, Vector3(1, 2, 3))
	assert_eq(_particles().size(), 1, "one emitter")
	assert_same(p.mesh, Fx.star_mesh(), "stars")
	assert_same(p.mesh.surface_get_material(0), Fx.material(), "with the one shared material: no shader compile")
	assert_gt(p.gravity.y, 0.0, "they float up")
	assert_true(p.color.is_equal_approx(Fx.WAKE_GOLD), "gold")
	assert_between(p.amount, 6, 16, "a few, not a flood")


func test_a_portal_puts_out_rainbow_gold_sparkles() -> void:
	var p := Fx.portal(self, Vector3.ZERO)
	assert_eq(_particles().size(), 1, "one emitter")
	assert_same(p.mesh, Fx.star_mesh())
	assert_not_null(p.color_initial_ramp, "each sparkle its own colour")
	assert_gte(p.color_initial_ramp.get_point_count(), 6, "gold and the rainbow")
	assert_true(p.color_initial_ramp.get_color(0).is_equal_approx(Fx.WAKE_GOLD), "gold first (owner #43's golden portals)")
	assert_same(Fx.portal(self, Vector3.ONE).color_initial_ramp, p.color_initial_ramp, "one shared ramp")


func test_a_level_up_rises_round_the_child_bigger_for_a_giant() -> void:
	var small := Fx.level_up(self, Vector3.ZERO, 1.0)
	var giant := Fx.level_up(self, Vector3.ZERO, 3.0)
	assert_same(small.mesh, Fx.star_mesh())
	assert_gt(small.gravity.y, 0.0, "the stars rise")
	assert_eq(small.emission_shape, CPUParticles3D.EMISSION_SHAPE_RING, "round the child")
	assert_gt(giant.emission_ring_radius, small.emission_ring_radius, "round a giant too")
	assert_gt(giant.scale_amount_max, small.scale_amount_max)


func test_confetti_is_one_emitter_with_every_colour() -> void:
	var colors: Array[Color] = [Color("ffd23f"), Color("ff5c8a"), Color("3fc1ff"), Color("7be05e")]
	var p := Fx.confetti(self, Vector3.ZERO, colors)
	assert_eq(_particles().size(), 1, "one emitter, not one per colour")
	assert_eq(p.color_initial_ramp.get_point_count(), 4)
	assert_eq(p.color_initial_ramp.interpolation_mode, Gradient.GRADIENT_INTERPOLATE_CONSTANT, "each cube one colour")
	assert_same(Fx.confetti(self, Vector3.ONE, colors).color_initial_ramp, p.color_initial_ramp, "cached per colour list")


func test_the_star_is_a_small_shared_mesh_seen_from_both_sides() -> void:
	var star := Fx.star_mesh()
	assert_same(star, Fx.star_mesh())
	var faces := star.get_faces()
	assert_lte(faces.size() / 3, 40, "a handful of triangles")
	var normals_z := {}
	var arrays := star.surface_get_arrays(0)
	for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
		normals_z[signf(n.z)] = true
	assert_true(normals_z.has(1.0) and normals_z.has(-1.0), "a face each way: it shows while it spins")


## A defeated monster's confetti was one emitter per colour (four); now one.
func test_a_defeated_monster_bursts_into_one_confetti_emitter() -> void:
	var md := MonsterDirector.new()
	add_child_autofree(md)
	var root := get_tree().root
	var before := root.get_children().filter(func(n: Node) -> bool: return n is CPUParticles3D).size()
	md._rpc_burst(Vector3(0, 5, 0), MonsterDirector.BURST_CONFETTI)
	var after := root.get_children().filter(func(n: Node) -> bool: return n is CPUParticles3D and not n.is_queued_for_deletion())
	assert_eq(after.size() - before, 1)
	for n in after:
		n.free()


func after_all() -> void:
	Audio.stop_all()
