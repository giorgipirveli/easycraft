extends GutTest
## Owner #94 and #96 (spec §5.12b, the Reel Studio, round 2: learning reels): the new rigs as the stage draws them. A
## rider is drawn where its model carries it, a mark draws nothing, a fill of shapes is meshed like the world's blocks
## (AIR carving a cutaway), a walker's legs swing, the light fades into a sunset and the planets' day side turns with
## the sun keys, and still nothing but the game's own looks.

var _views: Array[Scene3DView] = []


func after_each() -> void:
	for v in _views:
		v.queue_free()
	_views.clear()


func _stage() -> Dictionary:
	return {"sky": [{"at": 0, "sky": "day"}, {"at": 4, "dur": 2, "sky": "night"}],
		"light": [{"at": 0, "light": "day"}, {"at": 4, "dur": 2, "light": "dusk"}],
		"sun": [{"at": 0, "sun": [0.3, 1, 0.2]}, {"at": 4, "dur": 2, "sun": [1, 0.05, 0]}],
		"models": [
			{"id": "plank", "model": "blocks", "fill": [{"box": [-3, 0, 0, 3, 0, 0], "block": "PLANKS"}], "at": [0, 1, 0],
				"moves": [{"do": "turn", "at": 1, "dur": 2, "to": [0, 0, -15]}]},
			{"id": "crate", "model": "blocks", "cells": [[0, 0, 0, "BARREL"]], "on": "plank", "at": [-2, 0.5, 0]},
			{"id": "eye", "model": "mark", "at": [0, 2, 8]},
			{"id": "hill", "model": "blocks", "at": [10, 0, 0], "fill": [{"cone": [0, 0, 0, 5, 5], "block": "STONE"},
				{"box": [-6, 0, 1, 6, 6, 6], "block": "AIR"}]},
			{"id": "me", "model": "avatar", "look": "explorer", "at": [4, 0, 0], "moves": [
				{"do": "move", "at": 0.5, "dur": 4, "to": [4, 0, -4]}, {"do": "legs", "at": 0.5, "dur": 4}]},
			{"id": "earth", "model": "planet", "body": "earth", "at": [0, 30, -60], "size": 8},
			{"id": "rope", "model": "blocks", "fill": [{"box": [0, -4, 0, 0, -1, 0], "block": "PLANKS"}], "at": [-5, 6, 0],
				"stretch": [0.2, 1, 0.2], "moves": [{"do": "grow", "at": 1, "dur": 2, "to": 0.5, "axis": "y"}]}],
		"effects": [{"kind": "rain", "at": [0, 12, 0], "from": 0, "to": 6}, {"kind": "lava", "at": [10, 5, 0], "from": 0, "to": 6}],
		"camera": [{"at": 0, "follow": "eye", "pos": [0, 0, 0], "look": [0, -1, -8]},
			{"at": 3, "follow": "eye", "pos": [0, 0, 0], "look": [0, 0, 0], "aim": "crate"}]}


func _view(s: Dictionary) -> Scene3DView:
	var v := Scene3DView.new()
	v.size = Vector2(180, 320)
	add_child(v)
	_views.append(v)
	v.build(s)
	return v


func test_a_rider_is_drawn_where_its_model_carries_it() -> void:
	var s := _stage()
	var v := _view(s)
	v.show_at(3.5)
	var crate: Scene3DModels.Built = v.models.crate
	var expect := StudioMotion.world(s, StudioRules.model(s, "crate"), 3.5)
	assert_almost_eq(crate.root.transform.origin.distance_to(expect.origin), 0.0, 0.0001)
	assert_gt(crate.root.transform.origin.y, 1.5, "the plank tipped it up")
	assert_true(crate.root.visible)


func test_a_mark_draws_nothing_but_a_camera_rides_with_it() -> void:
	var v := _view(_stage())
	var eye: Scene3DModels.Built = v.models.eye
	assert_eq(eye.root.get_child_count(), 0, "nothing to see")
	v.show_at(0.0)
	assert_almost_eq(v.camera.position.distance_to(Vector3(0, 2, 8)), 0.0, 0.0001)
	v.show_at(3.5)
	var to_crate := ((v.models.crate as Scene3DModels.Built).root.position - v.camera.position).normalized()
	assert_almost_eq((-v.camera.basis.z).dot(to_crate), 1.0, 0.0001, "the camera keeps the crate in its middle")


func test_a_blocks_model_is_meshed_on_a_worker_thread_and_shows_when_it_is_in() -> void:
	# A phone builds the next reel in the feed in a frame of its own: its block shapes (the volcano's island: 14,000
	# cells) are meshed on a worker thread, and the stage shows them the frame they are in (like the planets' maps).
	var s := _stage()   # shapes no earlier test has meshed (the full suite found this test's hill already kept)
	s.models[3].fill.append({"box": [6, 0, -6 - (Time.get_ticks_usec() % 40), 6, 0, -6], "block": "SAND"})
	var v := _view(s)
	var hill: Scene3DModels.Built = v.models.hill
	assert_true(v.building(), "still meshing just after the build")
	var frames := 0
	while v.building() and frames < 120:
		await get_tree().process_frame
		frames += 1
	assert_false(v.building(), "meshed within two seconds")
	assert_eq(hill.root.get_child_count(), 1, "and shown")
	var again := _view(s)
	assert_eq((again.models.hill as Scene3DModels.Built).root.get_child_count(), 1,
		"the same shapes again: from the cache at once (swiping back)")


func test_a_rendered_reel_meshes_its_blocks_at_once() -> void:
	var v := Scene3DView.new()
	v.quality = StudioRules.RENDER
	v.size = Vector2(180, 320)
	add_child(v)
	_views.append(v)
	var s := _stage()
	s.models[3].fill.append({"box": [-6, -1, -1, 6, -1, 0], "block": "SAND"})   # shapes not meshed before
	v.build(s)
	assert_false(v.building(), "the Movie Maker never films a missing island")
	assert_eq((v.models.hill as Scene3DModels.Built).root.get_child_count(), 1)


func test_a_fill_of_shapes_is_meshed_and_air_cuts_it_open() -> void:
	var v := _view(_stage())
	v.finish_building()
	var hill: Scene3DModels.Built = v.models.hill
	var mesh := (hill.root.get_child(0) as MeshInstance3D).mesh
	assert_gt(mesh.get_surface_count(), 0, "the cone is meshed")
	var cut := StudioShapes.cells(StudioRules.model(_stage(), "hill"))
	var whole := StudioShapes.cells({"fill": [{"cone": [0, 0, 0, 5, 5], "block": "STONE"}]})
	assert_lt(cut.size(), whole.size() * 0.75, "the front was carved away")
	for c: Vector3i in cut:
		assert_lt(c.z, 1, "nothing left in front of the cut")


func test_a_stretched_model_and_its_axis_grow_are_drawn() -> void:
	var v := _view(_stage())
	var rope: Scene3DModels.Built = v.models.rope
	v.show_at(0.0)
	assert_almost_eq((rope.root.basis * Vector3.UP).length(), 1.0, 0.0001)
	assert_almost_eq((rope.root.basis * Vector3.RIGHT).length(), 0.2, 0.0001, "thin as a rope")
	v.show_at(4.0)
	assert_almost_eq((rope.root.basis * Vector3.UP).length(), 0.5, 0.0001, "wound up to half")


func test_a_rope_is_drawn_from_its_start_to_its_end() -> void:
	var s := _stage()
	s.models.append({"id": "hook", "model": "mark", "at": [-2, 7, 0]})
	s.models.append({"id": "line", "model": "rope", "from": "hook", "to": "crate", "at": [0, 0, 0], "width": 0.1})
	var v := _view(s)
	v.show_at(3.5)
	var line: Scene3DModels.Built = v.models.line
	var end := StudioMotion.world(s, StudioRules.model(s, "crate"), 3.5).origin
	assert_almost_eq(line.root.transform.origin.distance_to(Vector3(-2, 7, 0)), 0.0, 0.0001, "from the hook")
	assert_almost_eq((line.root.transform * Vector3(0, 1, 0)).distance_to(end), 0.0, 0.001, "to the crate")
	assert_almost_eq((line.root.basis * Vector3.RIGHT).length(), 0.1, 0.0001, "as thin as its width")


func test_a_walker_swings_its_legs() -> void:
	var v := _view(_stage())
	var me: Scene3DModels.AvatarBuilt = v.models.me
	var legs := []
	for t: float in [1.0, 1.25, 1.5, 1.75]:
		v.show_at(t)
		legs.append(me.body._left_leg.rotation.x)
	assert_gt(legs.max() - legs.min(), 0.4, "the legs swing as it walks")
	v.show_at(5.0)
	assert_almost_eq(float(me.body._left_leg.rotation.x), 0.0, 0.0001, "and stand still when it stops")


func test_the_light_fades_into_a_sunset() -> void:
	var v := _view(_stage())
	v.show_at(1.0)
	var day := v.key.light_energy
	var day_color := v.key.light_color
	var earth: Scene3DModels.PlanetBuilt = v.models.earth
	var noon: Vector3 = earth.material.get_shader_parameter(&"sun_dir")
	v.show_at(7.0)
	assert_almost_eq(v.key.light_energy, float(StudioRules.light("dusk").key_energy), 0.0001)
	assert_ne(v.key.light_color, day_color, "warmer")
	assert_ne(day, v.key.light_energy)
	var dusk: Vector3 = earth.material.get_shader_parameter(&"sun_dir")
	assert_lt(dusk.y, noon.y, "the planets' day side follows the sun going down")
	assert_almost_eq((-v.key.global_basis.z).dot(-dusk.normalized()), 1.0, 0.001, "the key light shines from the sun")
	assert_true(v.sky.stars.visible, "a night sky shows the stars")


func test_a_planet_s_night_side_can_be_darker() -> void:
	var s := _stage()
	s.models.append({"id": "moon", "model": "planet", "body": "moon", "at": [0, 30, -80], "size": 4, "night": 0.03})
	var v := _view(s)
	var moon: Scene3DModels.PlanetBuilt = v.models.moon
	assert_almost_eq(float(moon.material.get_shader_parameter(&"night")), 0.03, 0.0001, "a phase reads only on a dark night side")
	var earth: Scene3DModels.PlanetBuilt = v.models.earth
	var level: Variant = earth.material.get_shader_parameter(&"night")
	assert_true(level == null or is_equal_approx(float(level), 0.12), "the flight's own level otherwise (the shader's 0.12)")
	s.models[s.models.size() - 1].night = 2.0
	assert_ne(Scene3DKind.stage_problem(s), "", "a night level is 0-1")


func test_the_new_rigs_draw_only_the_game_s_own_looks() -> void:
	var v := _view(_stage())
	v.show_at(3.0)
	var known := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			known[ShaderWarmup.key(d.material)] = true
	for m: Material in BlockLibrary.warmup_materials("blocky"):
		known[ShaderWarmup.key(ShaderWarmup.describe(m))] = true
	for m: Material in [FlightLooks.night_material(), FlightLooks.sun_material(), FlightLooks.earth_material(),
			GolemModels.glow_material(), Fx.material(), AvatarParts.part_material(), AvatarParts.part_glow_material(),
			AvatarParts.material(Color.RED)]:
		known[ShaderWarmup.key(ShaderWarmup.describe(m))] = true
	var found: Array[Material] = []
	_materials(v.viewport, found)
	for m in found:
		assert_true(known.has(ShaderWarmup.key(ShaderWarmup.describe(m))), "a shader the game already warms: %s" % m)


func _materials(n: Node, out: Array[Material]) -> void:
	if n is GeometryInstance3D:
		var g := n as GeometryInstance3D
		if g.material_override:
			out.append(g.material_override)
		var mesh: Mesh = null
		if n is MeshInstance3D:
			mesh = (n as MeshInstance3D).mesh
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh:
			mesh = (n as MultiMeshInstance3D).multimesh.mesh
		if mesh and not g.material_override:
			for s in mesh.get_surface_count():
				if mesh.surface_get_material(s):
					out.append(mesh.surface_get_material(s))
	for c in n.get_children():
		_materials(c, out)
