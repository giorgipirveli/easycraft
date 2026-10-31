extends GutTest
## Owner #118 (docs/design/life-skills.md §14; Life L3a): the three new practice places. Every safe mistake's event has
## its gentle picture in its room (and it is taken away after); the freeze stills the room's own motion (the rip's
## arrows, the shaking lamp); "more real" (Big) is modest: a little stronger, never anything new or scary; the rooms stay
## within a mesh budget (each count printed for the notes); the swimmers' places vary with the seed.

const BUDGET := 320


func _room(exp_id: String, track: String, seed: int = 1, intensity: String = LifeData.GENTLE) -> LifeRoom:
	var r := LifeRooms.make(str(LifeExperience.data(exp_id).room), track,
		LifeExperience.vars(exp_id, track, seed, "ge", intensity))
	add_child_autofree(r)
	return r


func after_all() -> void:
	Audio.stop_all()


func test_every_safe_mistake_has_its_gentle_picture_and_it_goes_away() -> void:
	for exp_id: String in ["water_safety", "poisons_cupboard", "earth_weather"]:
		for track: String in ["middle", "big"]:
			for expert: bool in [false, true]:
				for step in LifeExperience.steps(exp_id, track, expert, 1, "ge"):
					if not LifeCheck.tries_mistake(step):
						continue
					var room := _room(exp_id, track)
					var event := str(step.safe_mistake.event)
					room.show_mistake(event, true)
					var where := "%s.%s %s" % [exp_id, track, event]
					var holder := room.get_node_or_null(^"MistakePicture")
					assert_not_null(holder, where + ": a picture of what would happen")
					if holder:
						assert_gt(holder.get_child_count(), 0, where)
					room.show_mistake(event, false)
					assert_null(room.get_node_or_null(^"MistakePicture"), where + ": taken away after")
					room.free()


func test_the_freeze_stills_the_rip_and_the_shaking() -> void:
	var water := _room("water_safety", "middle") as WaterRoom
	water.on_event("rip_on")
	await wait_process_frames(3)
	water.freeze(true)
	var z := water.arrows[0].position.z
	await wait_process_frames(5)
	assert_eq(water.arrows[0].position.z, z, "the rip's arrows stand still")
	water.freeze(false)
	await wait_process_frames(5)
	assert_ne(water.arrows[0].position.z, z, "and drift on after")
	var earth := _room("earth_weather", "middle") as EarthRoom
	earth.on_event("shake_on")
	await wait_process_frames(3)
	earth.freeze(true)
	var r := earth.lamp.rotation.z
	await wait_process_frames(5)
	assert_eq(earth.lamp.rotation.z, r, "the lamp stops swaying")
	earth.freeze(false)


func test_slow_time_slows_the_rooms_own_motion() -> void:
	var a := _room("earth_weather", "middle") as EarthRoom
	var b := _room("earth_weather", "middle") as EarthRoom
	a.time_scale = 0.5
	a.on_event("shake_on")
	b.on_event("shake_on")
	await wait_process_frames(10)
	assert_almost_eq(a._shake_t, b._shake_t * 0.5, b._shake_t * 0.1 + 0.001, "half the room's time")


func test_more_real_is_modest() -> void:
	var gentle := _room("water_safety", "big", 1, LifeData.GENTLE) as WaterRoom
	var real := _room("water_safety", "big", 1, LifeData.REAL) as WaterRoom
	assert_false(gentle.more_real())
	assert_true(real.more_real())
	gentle.show_mistake("ice_cracks", true)
	real.show_mistake("ice_cracks", true)
	var n_gentle := gentle.get_node(^"MistakePicture").get_child_count()
	var n_real := real.get_node(^"MistakePicture").get_child_count()
	assert_gt(n_real, n_gentle, "a few more cracks")
	assert_lt(n_real, n_gentle * 2, "never much more")
	assert_eq(gentle.find_children("*", "Label3D", true, false).size(), real.find_children("*", "Label3D", true, false).size(),
		"nothing new to read or see")


func test_the_swimmers_places_vary_with_the_seed() -> void:
	var seen := {}
	for seed in 8:
		var room := _room("water_safety", "middle", seed) as WaterRoom
		seen[str(room.target_position("mo_quiet") - room.global_position)] = true
		room.free()
	assert_gt(seen.size(), 1, "the quiet friend isn't always in the same place")


func test_the_rooms_stay_within_the_mesh_budget() -> void:
	for exp_id: String in ["water_safety", "poisons_cupboard", "earth_weather"]:
		for track in LifeData.TRACKS:
			var room := _room(exp_id, track)
			var meshes := room.find_children("*", "MeshInstance3D", true, false).size()
			gut.p("LIFE_L3A_MESHES %s.%s %d" % [exp_id, track, meshes])
			assert_lte(meshes, BUDGET, "%s.%s" % [exp_id, track])
			room.free()
