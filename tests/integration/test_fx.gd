extends GutTest
## Particle bursts (block breaks, jump puffs). M1b acceptance on the emulator: in the REALISTIC style
## every break and landing made a 120-147 ms frame. Each burst made its own StandardMaterial3D; when
## the last burst faded, the material's shader was freed with it (in BLOCKY the blocky avatar's
## materials happen to share that shader and keep it alive), so the next burst compiled it again.
## Bursts now share one material (colour per burst via the particles' colour), kept for the game.


func _particles() -> Array[CPUParticles3D]:
	var list: Array[CPUParticles3D] = []
	for n in get_children():
		if n is CPUParticles3D:
			list.append(n)
	return list


func test_bursts_share_one_material_and_keep_their_colour() -> void:
	Fx.burst(self, Vector3.ZERO, Color.RED)
	Fx.burst(self, Vector3.ONE, Color.BLUE, 10, 2.5, 0.12, 0.35, 2.0)
	var ps := _particles()
	assert_eq(ps.size(), 2)
	var m0 := (ps[0].mesh as PrimitiveMesh).material
	var m1 := (ps[1].mesh as PrimitiveMesh).material
	assert_not_null(m0)
	assert_same(m0, m1, "one material for every burst: its shader is compiled once")
	assert_eq(ps[0].color, Color.RED, "each burst keeps its own colour")
	assert_eq(ps[1].color, Color.BLUE)
	assert_true((m0 as StandardMaterial3D).vertex_color_use_as_albedo, "the colour reaches the cubes")
	for p in ps:
		p.free()


func test_the_shared_material_outlives_every_burst() -> void:
	Fx.burst(self, Vector3.ZERO, Color.GREEN)
	var m := (_particles()[0].mesh as PrimitiveMesh).material
	var ref: WeakRef = weakref(m)
	m = null
	for p in _particles():
		p.free()
	assert_not_null(ref.get_ref(), "still there after the burst is gone")


## The first burst of a session still compiled the shared shader (one 107-127 ms frame on the
## emulator, right at the first break or jump). A tiny burst in front of the camera while the world
## loads compiles it where nobody notices.
func test_prewarm_draws_one_tiny_burst_in_front_of_the_camera() -> void:
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.global_position = Vector3(3, 40, -2)
	Fx.prewarm(cam)
	var ps := _particles()
	assert_eq(ps.size(), 1, "one burst")
	if ps.size() != 1:
		return
	var p := ps[0]
	var ahead := cam.to_local(p.global_position)
	assert_lt(ahead.z, -0.5, "in front of the camera, so it is really drawn")
	assert_lt(absf(ahead.x) + absf(ahead.y), 0.01, "in the middle of the view")
	assert_same((p.mesh as PrimitiveMesh).material, Fx.material(), "with the material every burst uses")
	assert_eq(p.amount, 1)
	p.free()


# --- Water effects (M2 Task 14, owner feedback #17) --------------------------------------------

## Every water effect, as the plain list of its particle nodes.
func _water_effects(body: Node3D) -> Array:
	Fx.splash(self, Vector3.ZERO, 0.5)
	Fx.ripple(self, Vector3.ONE)
	Fx.bubbles(self, Vector3(0, -2, 0))
	Fx.drips(body, 0.5)
	var list := []
	list.append_array(_particles())
	list.append_array(body.find_children("*", "CPUParticles3D", false, false))
	return list


func _free_particles() -> void:
	for p in _particles():
		p.free()


func test_water_effects_use_the_one_shared_material() -> void:
	var body := Node3D.new()
	add_child_autofree(body)
	var ps := _water_effects(body)
	assert_gte(ps.size(), 5, "splash drops and ring, a ripple, bubbles and drips")
	for p: CPUParticles3D in ps:
		assert_same((p.mesh as PrimitiveMesh).material, Fx.material(), "no material of its own: no shader compile")
	_free_particles()


func test_a_harder_entry_throws_more_and_faster_drops_and_a_wider_ring() -> void:
	Fx.splash(self, Vector3.ZERO, 0.15)
	var small := _particles()
	Fx.splash(self, Vector3.ZERO, 1.0)
	var big := _particles().filter(func(p: CPUParticles3D) -> bool: return not small.has(p))
	var drops := func(list: Array) -> CPUParticles3D:
		for p: CPUParticles3D in list:
			if p.mesh is BoxMesh:
				return p
		return null
	var ring := func(list: Array) -> CPUParticles3D:
		for p: CPUParticles3D in list:
			if p.mesh is TorusMesh:
				return p
		return null
	assert_not_null(drops.call(small))
	assert_not_null(drops.call(big))
	assert_not_null(ring.call(big), "a ring spreads on the surface")
	if drops.call(small) and drops.call(big) and ring.call(small) and ring.call(big):
		assert_gt(drops.call(big).amount, drops.call(small).amount, "more drops")
		assert_gt(drops.call(big).initial_velocity_max, drops.call(small).initial_velocity_max, "flying higher")
		assert_gt(ring.call(big).scale_amount_max, ring.call(small).scale_amount_max, "a wider ring")
		assert_lt(drops.call(big).spread, 60.0, "the drops fly up, not every way")
	_free_particles()


func test_ripples_share_one_flat_ring_that_spreads_on_the_surface() -> void:
	Fx.ripple(self, Vector3.ZERO)
	Fx.ripple(self, Vector3(3, 0, 0), 2.0)
	var ps := _particles()
	assert_eq(ps.size(), 2)
	assert_true(ps[0].mesh is TorusMesh, "a ring")
	assert_same(ps[0].mesh, ps[1].mesh, "one ring mesh for every ripple")
	assert_eq(ps[0].gravity, Vector3.ZERO, "it stays on the surface")
	assert_true(ps[0].split_scale)
	assert_gt(ps[0].scale_curve_x.sample(1.0), ps[0].scale_curve_x.sample(0.0) * 2.0, "it spreads out")
	assert_same(ps[0].scale_curve_x, ps[1].scale_curve_x, "shared curves")
	assert_lt((ps[0].mesh as TorusMesh).rings * (ps[0].mesh as TorusMesh).ring_segments, 200, "a cheap ring")
	_free_particles()


func test_bubbles_rise() -> void:
	Fx.bubbles(self, Vector3.ZERO)
	var ps := _particles()
	assert_eq(ps.size(), 1)
	assert_gt(ps[0].gravity.y, 0.0, "up to the surface")
	assert_lte(ps[0].amount, 6, "a few at a time")
	_free_particles()


func test_drips_fall_from_the_body_for_a_moment_then_stop() -> void:
	var body := Node3D.new()
	add_child_autofree(body)
	Fx.drips(body, 0.2)
	var ps := body.find_children("*", "CPUParticles3D", false, false)
	assert_eq(ps.size(), 1, "the body carries its drips")
	if ps.size() != 1:
		return
	var p := ps[0] as CPUParticles3D
	assert_true(p.emitting)
	assert_lt(p.gravity.y, 0.0, "they fall")
	assert_false(p.local_coords, "a drop stays where it fell")
	await wait_seconds(0.2 + p.lifetime + 0.4)
	assert_eq(body.find_children("*", "CPUParticles3D", false, false).size(), 0, "gone after a moment")
