extends GutTest
## Owner #116 (docs/superpowers/plans/2026-10-16-vr-round4.md "Round 4b"): Real Builder's building site on Life L1's
## room framework. Every step finds its targets and views on every track; every tool step has its work (a frame for the
## engine); everything to tap is on the screen from its view; everything to touch is within a child's reach in VR; only
## warmed shaders, no shadows of its own; the walls are the brickwork's own plans, laid piece by piece, in bond; the
## events (the high block, the coach's test wall splitting, the team's rows rising, lintels, rafters, tiles, the mixer,
## goggles off, the sawdust puff) change what they should.

const FREE := Rect2(12, 150, 1256, 440)   # under the coach's bar, above the bottom's tool tray and controls


func _site(track: String) -> RealBuilderSite:
	var s := RealBuilderSite.new(track)
	add_child_autofree(s)
	return s


func after_all() -> void:
	Audio.stop_all()


func _all_steps(track: String) -> Array[Dictionary]:
	return RealBuilder.steps(track, false, 2, "ge") + RealBuilder.steps(track, true, 2, "ge")


func test_every_step_finds_its_targets_and_views() -> void:
	for track in LifeData.TRACKS:
		var site := _site(track)
		for step in _all_steps(track):
			var where := "%s %s" % [track, step.id]
			for t in LifeCheck.targets_of(step):
				assert_true(site.has_target(t), "%s: target %s" % [where, t])
			for key: String in ["view", "goes", "walk"]:
				if step.has(key):
					assert_true(site.views.has(str(step[key])), "%s: view %s" % [where, step[key]])
			if step.has("device"):
				var dev := ToolDevice.from(RealBuilder.devices()[str(step.device)])
				for o in dev.order:
					var t := str(o.do)
					assert_true(site.has_target(t) or site.has_target("%s_%s" % [step.device, t]), "%s: control %s" % [where, t])
			for g: Variant in step.get("gear", []):
				assert_true(site.has_target(str(g)), where + ": gear " + str(g))
		assert_true(site.views.has(site.start_view))


func test_every_tool_step_has_its_work() -> void:
	for track in LifeData.TRACKS:
		var site := _site(track)
		for step in _all_steps(track):
			if step.has("tool") or (str(step.get("motion", "")) == "press" and str(step.kind) == "touch" and not step.has("device")):
				assert_true(site.has_work(str(step.target)), "%s %s: a frame for %s" % [track, step.id, step.target])


func test_every_tool_is_on_the_bench() -> void:
	for track in LifeData.TRACKS:
		var site := _site(track)
		for t in RealBuilder.tools_of(track):
			if str(ToolBook.entry(t).kind) == "safety":
				assert_true(site.has_target(t), track + ": gear " + t)
			else:
				assert_true(site.props().has(t), track + ": " + t)
				var p: ToolProp = site.props()[t]
				assert_eq(p.grabbable.kind, &"tool", t + " is held and used")


func test_everything_to_tap_is_on_the_screen_from_its_view() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(LifeRoomHud.CANVAS)
	add_child_autofree(view)
	var cam := Camera3D.new()
	cam.fov = 72.0
	view.add_child(cam)
	for track in LifeData.TRACKS:
		for expert: bool in [false, true]:
			var site := _site(track)
			for step in RealBuilder.steps(track, expert, 2, "ge"):
				if str(step.get("react", "")) != "":
					site.react(str(step.react))
				site.step_started(step)
				cam.global_transform = site.camera_transform(str(step.get("view", site.start_view)))
				var wanted: Array[String] = []
				if str(step.kind) in ["touch", "go", "taps", "find", "sequence"]:
					wanted = LifeCheck.targets_of(step)
				for t in wanted:
					var where := "%s %s (expert %s): %s" % [track, step.id, expert, t]
					var p := site.target_position(t)
					assert_false(cam.is_position_behind(p), where + " is behind the camera")
					assert_true(FREE.has_point(cam.unproject_position(p)), "%s is off the free screen at %s" % [where,
						cam.unproject_position(p)])
					assert_true(site.target_node(t).is_visible_in_tree(), where + " is hidden")
				if str(step.get("after", "")) != "":
					site.react(str(step.after))
				site.step_done(step)


func test_in_vr_the_work_is_within_reach_of_where_the_child_stands() -> void:
	for track in LifeData.TRACKS:
		var site := _site(track)
		for step in _all_steps(track):
			site.step_started(step)
			var eye := site.vr_stand(str(step.get("view", site.start_view))).origin
			var t := str(step.get("target", ""))
			var where := "%s %s: %s" % [track, step.id, t]
			if site.has_work(t):
				var d := eye.distance_to(site.work_frame(t).origin)
				assert_lte(d, 1.25, "%s: the work is %.2f m away (a hand with its tool must reach it)" % [where, d])
			elif site.is_placement(t) and t.begins_with("course"):
				var c := eye.distance_to(site.target_position(t))
				assert_lte(c, 1.25, "%s: the row is %.2f m away" % [where, c])
			elif t != "":
				assert_lte(eye.distance_to(site.target_position(t)), LifeRoomHost.LASER, where + " (the laser reaches it)")


func test_only_warmed_shaders_and_no_shadows_of_its_own() -> void:
	var census := {}
	var labels := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			census[ShaderWarmup.key(d.material)] = true
		if d.has("label"):
			labels[JSON.stringify(d.label, "", true)] = true
	for track in LifeData.TRACKS:
		var site := _site(track)
		for e: String in ["test_wall", "rise_to_top", "finished"]:
			site.react(e)
		site.glow(site.target_names())
		for g: Node in site.find_children("*", "MeshInstance3D", true, false):
			var m := (g as MeshInstance3D).material_override
			assert_true(census.has(ShaderWarmup.key(ShaderWarmup.describe(m))), "%s %s: %s" % [track, g.name,
				ShaderWarmup.describe(m)])
			assert_eq((g as GeometryInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, str(g.name))
		for l: Node in site.find_children("*", "Label3D", true, false):
			for d: Dictionary in ShaderWarmup.draws_of(l):
				if d.has("label"):
					assert_true(labels.has(JSON.stringify(d.label, "", true)), "%s %s: %s" % [track, l.name, d.label])
		for l: Node in site.find_children("*", "Light3D", true, false):
			assert_false((l as Light3D).shadow_enabled)


func test_a_few_draws_even_for_a_whole_house() -> void:
	var site := _site("big")
	site.react("rise_to_top")
	site.step_done({"kind": "timelapse", "id": "to_top"})
	site.rafters_laid = site.rafter_count
	site.tiles_laid = site.tile_rows
	for t: String in ["lintel_window", "lintel_door"]:
		site.lay(t)
	site._rebuild()
	var n := 0
	for g: Node in site.find_children("*", "GeometryInstance3D", true, false):
		if (g as GeometryInstance3D).is_visible_in_tree():
			n += 1
	assert_lte(n, 110, "a house of %d bricks in %d draws" % [site.visible_pieces().size(), n])
	assert_gt(site.visible_pieces().size(), 1000, "every brick of a real small house")


# --- Laying -----------------------------------------------------------------------------------------------------

func test_a_course_is_laid_piece_by_piece_nearest_the_finger() -> void:
	var site := _site("little")
	var step: Dictionary = RealBuilder.steps("little", false, 1, "ge").filter(func(s: Dictionary) -> bool:
		return str(s.id) == "row_1")[0]
	site.step_started(step)
	var right: Dictionary = site.free_pieces("course_1")[2]
	var id := site.lay("course_1", site.to_global(right.centre as Vector3) + Vector3(0.05, 0, 0))
	assert_eq(id, str(right.id), "the one under the finger")
	assert_eq(site.laid_count("course_1"), 1)
	site.progress(step, {"t": 3})
	assert_eq(site.laid_count("course_1"), 3, "the rest follow the count")


func test_the_next_place_glows_unless_the_expert_lays_it_alone() -> void:
	var site := _site("little")
	var normal: Dictionary = RealBuilder.steps("little", false, 1, "ge").filter(func(s: Dictionary) -> bool:
		return str(s.id) == "row_2")[0]
	site.step_started(normal)
	site.glow(["course_2"] as Array[String])
	assert_true(site._ghost.visible, "a see-through block where the next one goes")
	var expert: Dictionary = RealBuilder.steps("little", true, 1, "ge").filter(func(s: Dictionary) -> bool:
		return str(s.id) == "row_2")[0]
	site.step_started(expert)
	site.glow(["course_2"] as Array[String])
	assert_false(site._ghost.visible, "no glow on the Expert try")


func test_the_little_wall_ends_up_in_bond() -> void:
	var site := _site("little")
	for c in 3:
		while site.lay("course_%d" % (c + 1)) != "":
			pass
	var pieces := site.visible_pieces()
	assert_eq(pieces.size(), 10)
	assert_eq(BrickBond.straight_joints(pieces), [])


func test_the_coachs_test_wall_shows_and_splits() -> void:
	for track: String in ["little", "middle"]:
		var site := _site(track)
		assert_false(site._test_wall.visible)
		site.react("test_wall")
		assert_true(site._test_wall.visible)
		assert_eq(BrickBond.straight_joints(site.test_bricks).size() > 0, true, "it has the straight joints")
		site.react("split")
		assert_true(site.split)
		site._rebuild()
		assert_lt(site._test_mortar.count, site._test_a.count, "the joint opens: no mortar across it")


func test_the_high_block_sits_proud_until_it_is_tapped_down() -> void:
	var site := _site("little")
	site.react("high_block")
	assert_true(site._high_up)
	assert_true(site.has_work("block_high"))
	site.react("block_down")
	assert_false(site._high_up)


func test_the_teams_rows_rise_during_the_time_lapse() -> void:
	var site := _site("middle")
	var step := {"kind": "timelapse", "seconds": 5.0, "id": "build_up"}
	site.react("rise_to_lintel")
	site.progress(step, {"t": 2.5})
	assert_between(site.team_upto, 8, 14, "half way up")
	site.step_done(step)
	assert_eq(site.team_upto, 21, "up to the lintel's row")
	assert_eq(site.laid_count("course_1"), 5, "and the child's own rows are all down")


func test_a_lintel_is_laid_over_the_doorway() -> void:
	var site := _site("middle")
	site.step_done({"kind": "touch", "target": "lintel_door", "id": "lintel"})
	assert_eq(site.laid_count("lintel_door"), 1)
	site._rebuild()
	assert_eq(site._lintels.count, 1)


func test_rafters_and_tiles_go_on_by_the_count() -> void:
	var site := _site("big")
	site.react("rise_to_top")
	site.progress({"kind": "taps", "target": "rafters", "count": 4}, {"t": 2})
	assert_eq(site.rafters_laid, 2)
	site.progress({"kind": "taps", "target": "tiles", "count": 5}, {"t": 5})
	assert_eq(site.tiles_laid, 5)
	assert_eq(site._tile_boxes(5).size(), 10, "both slopes")
	var low: Dictionary = site._tile_boxes(5)[0]
	var high: Dictionary = site._tile_boxes(5)[8]
	assert_gt((high.centre as Vector3).y, (low.centre as Vector3).y, "from the bottom up")


func test_goggles_off_go_back_on_the_saws_hook() -> void:
	var site := _site("middle")
	site.gear_on("goggles")
	site.react("goggles_off")
	assert_true(site._gear.goggles.visible)
	var hook := site.target_position("goggles")
	assert_lt(hook.distance_to(site.work_frame("rafter_cut").origin), 1.0, "near the saw: put them on there")


func test_the_mixer_shows_the_drum_and_the_mix() -> void:
	var site := _site("big")
	site.device_shows({"drum": "turning", "mix": "sandy"})
	assert_true(site.drum_turning)
	assert_true(site._mix.visible)
	site.device_shows({"drum": "still", "mix": "mortar"})
	assert_false(site.drum_turning)


func test_the_sawdust_puff_drifts_up_away_from_the_child() -> void:
	var site := _site("middle")
	site.react("sawdust")
	var puff := site.get_node("Sawdust") as Node3D
	assert_eq(puff.get_child_count(), 5)
	var cut := site.to_local(site.work_frame("rafter_cut").origin)
	for d: Node in puff.get_children():
		assert_lt((d as Node3D).position.distance_to(cut), 0.2, "at the work, never at a face")


func test_the_boxes_face_outwards() -> void:
	var b := BoxBatch.new("Test", Color.WHITE)
	add_child_autofree(b)
	b.set_boxes([{"centre": Vector3(1, 2, 3), "size": Vector3(0.2, 0.1, 0.4), "yaw": 0.7}])
	var arrays := b.mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_eq(v.size(), 36)
	for i in range(0, v.size(), 3):
		var face := (v[i + 2] - v[i]).cross(v[i + 1] - v[i])   # Godot's front faces wind clockwise
		assert_gt(face.dot(n[i]), 0.0, "triangle %d faces out" % (i / 3))
		assert_gt((v[i] - Vector3(1, 2, 3)).dot(n[i]), 0.0, "and away from the middle")
