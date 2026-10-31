extends GutTest
## M2 Task 3, the lead's child-friendly build feedback: a ring on the face of the block a held finger
## is breaking fills up until it breaks (holding visibly does something), and a block just placed
## pops in (a glow growing from 0.8 to 1.0 that fades). One ring and one pop per local player,
## reused; their meshes and materials are made once and shared (no per-event meshes or materials).


func _ring() -> BreakRing:
	var r := BreakRing.new()
	add_child_autofree(r)
	return r


func _pop() -> PlacePop:
	var p := PlacePop.new()
	add_child_autofree(p)
	return p


func test_the_ring_lies_on_the_face_the_finger_is_on() -> void:
	var r := _ring()
	r.show_on(BlockHit.new(Vector3i(3, 4, 5), Vector3i(3, 5, 5), 2.0), 0.5)   # the top face
	assert_true(r.visible)
	assert_almost_eq(r.global_position, Vector3(3.5, 5.0 + BreakRing.LIFT, 5.5), Vector3.ONE * 0.001)
	assert_almost_eq(r.global_basis.z, Vector3.UP, Vector3.ONE * 0.001, "it faces out of the block")
	r.show_on(BlockHit.new(Vector3i(3, 4, 5), Vector3i(4, 4, 5), 2.0), 0.5)   # the +X side
	assert_almost_eq(r.global_position, Vector3(4.0 + BreakRing.LIFT, 4.5, 5.5), Vector3.ONE * 0.001)
	assert_almost_eq(r.global_basis.z, Vector3.RIGHT, Vector3.ONE * 0.001)
	r.show_on(BlockHit.new(Vector3i(3, 4, 5), Vector3i(3, 3, 5), 2.0), 0.5)   # a ceiling
	assert_almost_eq(r.global_basis.z, Vector3.DOWN, Vector3.ONE * 0.001)


func test_the_ring_fills_with_the_hold() -> void:
	var r := _ring()
	var hit := BlockHit.new(Vector3i.ZERO, Vector3i.UP, 1.0)
	r.show_on(hit, 0.0)
	assert_eq(r.fill_step(), 0)
	assert_true(r.visible, "the empty ring shows at once")
	r.show_on(hit, 0.5)
	assert_eq(r.fill_step(), BreakRing.STEPS / 2)
	r.show_on(hit, 1.0)
	assert_eq(r.fill_step(), BreakRing.STEPS)
	r.show_on(null, 0.5)
	assert_false(r.visible, "no block under the finger")


func test_rings_share_their_meshes_and_materials() -> void:
	var a := _ring()
	var b := _ring()
	var hit := BlockHit.new(Vector3i.ZERO, Vector3i.UP, 1.0)
	a.show_on(hit, 0.5)
	b.show_on(hit, 0.5)
	assert_not_null(a.fill_mesh())
	assert_same(a.fill_mesh(), b.fill_mesh())
	var before := a.fill_mesh()
	a.show_on(hit, 0.9)
	a.show_on(hit, 0.5)
	assert_same(a.fill_mesh(), before, "never a new mesh for a new frame")
	assert_same(BreakRing.feedback_material(BreakRing.FILL_COLOR), BreakRing.feedback_material(BreakRing.FILL_COLOR))


func test_a_placed_block_pops_in_and_the_glow_fades() -> void:
	var p := _pop()
	p.pop(Vector3i(1, 2, 3))
	assert_true(p.visible)
	assert_almost_eq(p.global_position, Vector3(1.5, 2.5, 3.5), Vector3.ONE * 0.001)
	assert_almost_eq(p.scale.x, PlacePop.START_SCALE, 0.001)
	await wait_seconds(PlacePop.FADE_TIME + 0.15)
	assert_almost_eq(p.scale.x, 1.0, 0.001)
	assert_false(p.visible, "gone once it faded")


func test_pops_share_one_mesh_and_one_material() -> void:
	var a := _pop()
	var b := _pop()
	assert_same(a.mesh, b.mesh)
	assert_same(a.mesh.surface_get_material(0), b.mesh.surface_get_material(0))


## The ring and the pop use one shader (a first use compiles it: see Fx), and it is compiled as the
## world appears: both are drawn once, tiny, in front of the camera.
func test_ring_and_pop_share_one_shader_setup() -> void:
	var ring_mat := BreakRing.feedback_material(BreakRing.FILL_COLOR)
	var pop_mat := _pop().mesh.surface_get_material(0) as StandardMaterial3D
	for m: StandardMaterial3D in [ring_mat, pop_mat]:
		assert_eq(m.shading_mode, BaseMaterial3D.SHADING_MODE_UNSHADED)
		assert_eq(m.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
		assert_true(m.no_depth_test)
		assert_eq(m.cull_mode, BaseMaterial3D.CULL_DISABLED)


func _interactor() -> BlockInteractor:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	return p.get_node("BlockInteractor")


func test_the_players_interactor_shows_and_hides_the_ring() -> void:
	var i := _interactor()
	i.show_break_progress(BlockHit.new(Vector3i.ZERO, Vector3i.UP, 1.0), 0.5)
	assert_true(i.break_ring.visible)
	assert_eq(i.break_ring.fill_step(), BreakRing.STEPS / 2)
	i.show_break_progress(BlockHit.new(Vector3i.ZERO, Vector3i.UP, 1.0), -1.0)
	assert_false(i.break_ring.visible, "the finger moved or lifted")
	i.show_break_progress(BlockHit.new(Vector3i.ZERO, Vector3i.UP, 1.0), 0.2)
	i.show_break_progress(null, 0.2)
	assert_false(i.break_ring.visible, "no block under the finger")


func test_the_ring_and_the_pop_are_drawn_once_as_the_world_appears() -> void:
	var i := _interactor()
	i.player.spawned.emit()
	assert_true(i.break_ring.visible, "drawn once, tiny")
	assert_true(i.place_pop.visible)
	assert_lt(i.place_pop.scale.x, 0.1)
	await wait_seconds(BreakRing.PREWARM_SECONDS + 0.1)
	assert_false(i.break_ring.visible, "then gone")
	assert_false(i.place_pop.visible)


## The look area says "no hold" every frame; that must not cut the prewarm short (it would never be
## drawn, and the first real hold would compile the shader).
func test_no_hold_does_not_cut_the_prewarm_short() -> void:
	var i := _interactor()
	i.player.spawned.emit()
	i.show_break_progress(null, -1.0)
	assert_true(i.break_ring.visible, "still drawn this frame")
	i.show_break_progress(BlockHit.new(Vector3i.ZERO, Vector3i.UP, 1.0), 0.3)
	assert_almost_eq(i.break_ring.global_basis.get_scale(), Vector3.ONE, Vector3.ONE * 0.001, "a real hold wins")
	await wait_seconds(BreakRing.PREWARM_SECONDS + 0.1)
	assert_true(i.break_ring.visible, "and the prewarm's end leaves it alone")
