extends GutTest
## Owner #96 (spec §5.12b, the Reel Studio): a 3D stage in a Short. The `scene3d` actor and a cinematic reel's picture
## draw a stage of their own (a SubViewport with its own world, no shadows), show exactly the same frame at the same
## moment whether played or sought, render once per pose (a paused Short costs nothing), size their pixels to the
## screen, and draw only with the game's own looks (no new shader to compile).

var _players: Array[ShortPlayer] = []


func after_each() -> void:
	for p in _players:
		p.queue_free()
	_players.clear()
	ShortLibrary.clear_cache()


func _stage() -> Dictionary:
	return {"sky": [{"at": 0, "sky": "day"}, {"at": 2, "dur": 2, "sky": "space"}], "light": "studio", "models": [
		{"id": "rocket", "model": "rocket", "rocket": "moon", "at": [0, 0, 0], "moves": [
			{"do": "move", "at": 1, "dur": 6, "to": [0, 80, 0], "ease": "accel"}, {"do": "stage", "at": 4, "stage": 0}]},
		{"id": "earth", "model": "planet", "body": "earth", "at": [0, -300, -100], "size": 200},
		{"id": "rings", "model": "rings", "at": [60, 0, 0], "size": 5},
		{"id": "bits", "model": "ring_bits", "at": [60, 0, 0], "size": 5, "count": 50},
		{"id": "line", "model": "orbit_line", "radius": 20, "at": [0, 0, 0]},
		{"id": "ground", "model": "ground", "look": "moon", "at": [0, -1, 0], "size": 50},
		{"id": "pad", "model": "pad", "at": [0, -0.9, 0]},
		{"id": "sun", "model": "sun", "at": [-80, 40, -60], "size": 6},
		{"id": "me", "model": "avatar", "look": "astronaut", "at": [4, 0, 2], "moves": [{"do": "emote", "at": 0.5, "emote": "wave"}]},
		{"id": "cells", "model": "blocks", "cells": [[0, 0, 0, "STONE"], [1, 0, 0, "PAD_STRIPE"]], "at": [8, 0, 0]},
		{"id": "site", "model": "blocks", "build": "launch_tower", "at": [-30, 0, 0]},
		{"id": "puffs", "model": "clouds", "at": [0, -20, 0], "size": 40, "count": 6}],
		"effects": [{"kind": "flame", "on": "rocket", "from": 1, "to": 7}, {"kind": "smoke", "on": "rocket", "from": 1, "to": 6},
			{"kind": "billow", "at": [0, 0.3, 0], "from": 1, "to": 3}, {"kind": "sparkles", "at": [4, 2, 2], "from": 0, "to": 7}],
		"camera": [{"at": 0, "pos": [20, 5, 30], "look": [0, 5, 0], "fov": 45},
			{"at": 3, "follow": "rocket", "pos": [15, -5, 20], "look": [0, 5, 0], "fov": 50, "shake": 0.2},
			{"at": 7, "follow": "rocket", "pos": [-15, 2, 20], "look": [0, 5, 0], "fov": 50, "path": "orbit"}]}


func _short(actors: bool) -> Dictionary:
	var s := {"id": "stage_test", "title": "A stage", "topic": "rockets", "link": {"board": true}, "scenes": []}
	for i in 3:
		var scene := {"seconds": 8, "background": "space", "caption": "Look.", "say": "Look at it."}
		if actors:
			scene.actors = [{"kind": "scene3d", "at": [180, 220], "w": 300, "h": 360, "stage": _stage(),
				"moves": [{"do": "pop", "at": 0.2}]}]
		s.scenes.append(scene)
	s.scenes[2].caption = "What do you see?"
	if not actors:
		s.stage = _stage()
	return s


func _player(s: Dictionary, px: Vector2 = Vector2(288, 512)) -> ShortPlayer:
	var p := ShortPlayer.new()
	p.voice_on = false
	p.size = px
	add_child(p)
	_players.append(p)
	p.build(s)
	return p


func _pose(view: Scene3DView) -> Array:
	var out: Array = [view.camera.global_transform, view.camera.fov]
	for id: String in view.models:
		var b: Scene3DModels.Built = view.models[id]
		out.append([id, b.root.visible, b.root.transform])
		if b is Scene3DModels.RocketBuilt:
			for part: Array in (b as Scene3DModels.RocketBuilt).parts:
				out.append([(part[0] as Node3D).visible, (part[0] as Node3D).transform])
	for fx in view.effects:
		out.append([fx.visible, fx.shown(), fx.transform])
	return out


func test_the_scene3d_actor_draws_a_stage_of_its_own() -> void:
	var p := _player(_short(true))
	var actor: ShortActor = p.actors_of(0)[0]
	var view := Scene3DDrawer.view_of(actor)
	assert_not_null(view, "the actor holds a stage")
	assert_true(view.viewport.own_world_3d, "a world of its own: the game's is never in it")
	assert_eq(actor.size, Vector2(300, 360))
	for l: Light3D in [view.key, view.fill, view.rim, view.sun_light]:
		assert_false(l.shadow_enabled, "no shadows (phones)")
	assert_eq(view.models.size(), 12, "every model kind builds")
	assert_eq(view.effects.size(), 4)
	assert_eq(ShortCheck.problems(_short(true)), [] as Array[String])


func test_a_seek_shows_the_frame_playing_reaches() -> void:
	var p := _player(_short(false))
	var view := p.plate() as Scene3DView
	assert_not_null(view, "a cinematic reel's picture is its stage")
	p.play()
	var t := 0.0
	while t < 5.2:
		p.advance(1.0 / 30.0)
		t += 1.0 / 30.0
	var played := _pose(view)
	var at := p.time
	p.seek(1.0)
	p.seek(20.0)
	p.seek(at)
	assert_eq(_pose(view), played, "the same moment, the same frame")
	assert_eq(view.time, at)


func test_a_stage_renders_once_a_pose() -> void:
	var p := _player(_short(false))
	var view := p.plate() as Scene3DView
	p.seek(2.0)
	assert_eq(view.viewport.render_target_update_mode, SubViewport.UPDATE_ONCE, "a pose asks for one render")
	view.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED   # as after that render
	p.seek(2.0)
	assert_eq(view.viewport.render_target_update_mode, SubViewport.UPDATE_DISABLED,
		"the same moment again (a paused Short): nothing to draw")
	p.seek(2.5)
	assert_eq(view.viewport.render_target_update_mode, SubViewport.UPDATE_ONCE, "a new moment: one render")


func test_its_pixels_follow_the_player_on_the_screen() -> void:
	var p := _player(_short(false), Vector2(288, 512))
	await get_tree().process_frame
	var view := p.plate() as Scene3DView
	var scale := p.stage.get_screen_transform().get_scale().x
	assert_almost_eq(float(view.pixels().x), 360.0 * scale, 1.5, "one pixel a pixel on the screen")
	assert_lte(view.pixels().x, StudioRules.LIVE_MAX.x, "never more than a phone's player needs")


func test_the_stage_draws_only_the_game_s_own_looks() -> void:
	var p := _player(_short(false))
	var view := p.plate() as Scene3DView
	var known := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			known[ShaderWarmup.key(d.material)] = true
	for m: Material in BlockLibrary.warmup_materials("blocky"):
		known[ShaderWarmup.key(ShaderWarmup.describe(m))] = true
	# The game's own makers (their shaders compile where the game draws them: the flight's sky, Sun and nebula, the
	# golem's glow, the effects, the avatar, the Launch Site).
	for m: Material in [FlightLooks.night_material(), FlightLooks.sun_material(), FlightLooks.puff_material(Color.WHITE),
			FlightLooks.ground_material(), FlightLooks.earth_material(), GolemModels.glow_material(), Fx.material(),
			AvatarParts.part_material(), AvatarParts.part_glow_material(), AvatarParts.material(Color.RED),
			LaunchBuildings._shared_material()]:
		known[ShaderWarmup.key(ShaderWarmup.describe(m))] = true
	var found: Array[Material] = []
	_materials(view.viewport, found)
	assert_gt(found.size(), 5)
	for m in found:
		var k := ShaderWarmup.key(ShaderWarmup.describe(m))
		assert_true(known.has(k), "a shader the game already warms: %s" % k)


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
				var sm := mesh.surface_get_material(s)
				if sm:
					out.append(sm)
	for c in n.get_children():
		_materials(c, out)


func test_a_rocket_s_stage_falls_away_and_its_flame_moves_up() -> void:
	var p := _player(_short(false))
	var view := p.plate() as Scene3DView
	var rocket: Scene3DModels.RocketBuilt = view.models.rocket
	p.seek(3.9)
	var bottom: MeshInstance3D = rocket.parts[0][0]
	var together := bottom.transform
	var flame_before: Vector3 = rocket.anchor(3.9).origin
	p.seek(6.0)
	assert_ne(bottom.transform, together, "stage 1 let go")
	assert_lt(bottom.transform.origin.y, StudioMotion.transform(rocket.data, 6.0).origin.y - 5.0, "and fell behind")
	assert_gt(rocket.anchor(6.0).origin.y - StudioMotion.transform(rocket.data, 6.0).origin.y,
		flame_before.y - StudioMotion.transform(rocket.data, 3.9).origin.y, "the flame comes from stage 2's engines now")


func test_the_sky_darkens_and_the_stars_come_out() -> void:
	var p := _player(_short(false))
	var view := p.plate() as Scene3DView
	p.seek(0.5)
	assert_false(view.sky.stars.visible, "a day sky hides the stars")
	p.seek(4.5)
	assert_true(view.sky.stars.visible, "space shows them")


func test_every_cinematic_reel_checks() -> void:
	for f in DirAccess.get_files_at(ShortLibrary.CINEMATIC):
		if not f.ends_with(".json"):
			continue
		var s := ShortLibrary.get_short(f.get_basename())
		assert_false(s.is_empty(), f)
		assert_eq(ShortCheck.problems(s), [] as Array[String], f)
