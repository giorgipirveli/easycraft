extends GutTest
## Owner #118 (docs/design/life-skills.md §14; Life L3b): the new practice places and the old ones' new corners. Every
## safe mistake's event has its gentle picture in its room (and it is taken away after), the hooks' too (Safe Streets'
## crossing, Real Builder's saw); the freeze stills the room's own motion (the running dog, the pan's flame, the
## seizure's pretend jerking); a warning dog shows its signs and a relaxed one doesn't; the dogs' places vary with the
## seed; the rooms stay within a mesh budget (each count printed for the notes).

const BUDGET := 320


func _room(exp_id: String, track: String, seed: int = 1) -> LifeRoom:
	var r := LifeRooms.make(str(LifeExperience.data(exp_id).room), track, LifeExperience.vars(exp_id, track, seed, "ge"))
	add_child_autofree(r)
	return r


func after_all() -> void:
	Audio.stop_all()


func test_every_safe_mistake_has_its_gentle_picture_and_it_goes_away() -> void:
	for exp_id: String in ["electricity", "animals", "medical", "kitchen", "safe_streets", "real_builder"]:
		for track: String in ["middle", "big"]:
			for expert: bool in [false, true]:
				var steps := RealBuilder.steps(track, expert, 1, "ge") if exp_id == RealBuilder.ID \
					else LifeExperience.steps(exp_id, track, expert, 1, "ge")
				for step in steps:
					if not LifeCheck.tries_mistake(step):
						continue
					var room := _room(exp_id, track)
					if str(step.get("react", "")) != "":
						room.react(str(step.react))
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


func test_the_freeze_stills_the_dog_the_flame_and_the_seizure() -> void:
	var animals := _room("animals", "middle") as AnimalsRoom
	animals.on_event("loose_dog")
	await wait_process_frames(3)
	animals.freeze(true)
	var at := animals.runner.position
	await wait_process_frames(5)
	assert_eq(animals.runner.position, at, "the running dog stands still")
	animals.freeze(false)
	await wait_process_frames(5)
	assert_ne(animals.runner.position, at, "and runs on after")
	var kitchen := _room("kitchen", "middle") as KitchenRoom
	kitchen.on_event("pan_fire")
	await wait_process_frames(3)
	kitchen.freeze(true)
	var s := kitchen.flame.scale
	await wait_process_frames(5)
	assert_eq(kitchen.flame.scale, s, "the flame stops flickering")
	kitchen.freeze(false)
	var medical := _room("medical", "big") as MedicalRoom
	medical.on_event("bobo_seizure")
	await wait_process_frames(3)
	medical.freeze(true)
	var r := medical.bobo.arm_near.rotation
	await wait_process_frames(5)
	assert_eq(medical.bobo.arm_near.rotation, r, "the pretend jerking stops")
	medical.freeze(false)
	medical.on_event("seizure_stops")
	await wait_process_frames(3)
	assert_false(medical.seizing)


func test_a_slow_danger_moment_slows_the_dog() -> void:
	var fast := _room("animals", "little") as AnimalsRoom
	var slow := _room("animals", "little") as AnimalsRoom
	slow.time_scale = LifeRun.SLOW_FIRST
	fast.on_event("loose_dog")
	slow.on_event("loose_dog")
	await wait_process_frames(10)
	var start := Vector3(-3.0, 0, -3.0)
	assert_gt(fast.runner.position.distance_to(start), slow.runner.position.distance_to(start) * 1.5,
		"on a first try the dog comes at half speed")


func test_a_warning_dog_shows_its_signs_and_a_relaxed_one_doesnt() -> void:
	var d := LifeDog.new()
	add_child_autofree(d)
	d.set_mood("warning")
	assert_true(d.lips.visible, "lips pulled back")
	assert_true(d.brow.visible, "a hard stare")
	assert_lt(d.tail.rotation.z, 0.0, "the tail held high")
	d.set_mood("relaxed")
	assert_false(d.lips.visible)
	assert_gt(d.tail.rotation.z, 0.0, "a low, loose tail")
	for m: String in ["body", "eyes", "lips", "tail", "side", "head", "neck", "nose"]:
		assert_not_null(d.mark(m), m)


func test_the_dogs_places_vary_with_the_seed() -> void:
	var seen := {}
	for seed in 8:
		var room := _room("animals", "middle", seed) as AnimalsRoom
		seen[snappedf(room.warning_x, 0.1)] = true
		assert_almost_eq(room.target_position("dog_warning").x - room.global_position.x, room.warning_x, 0.01)
		room.free()
	assert_gt(seen.size(), 1, "the warning dog isn't always in the same place")


func test_the_rooms_keep_to_the_mesh_budget() -> void:
	var counts: Array[String] = []
	for exp_id: String in ["electricity", "animals", "medical", "kitchen", "fire_escape"]:
		var per: Array[String] = []
		for track in LifeData.TRACKS:
			var room := _room(exp_id, track)
			var n := room.find_children("*", "MeshInstance3D", true, false).size()
			per.append(str(n))
			assert_lte(n, BUDGET, "%s.%s: %d meshes" % [exp_id, track, n])
			room.free()
		counts.append("%s %s" % [exp_id, " / ".join(per)])
	gut.p("LIFE_L3B_MESHES " + ", ".join(counts))
