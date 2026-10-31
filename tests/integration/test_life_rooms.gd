extends GutTest
## Owner #112 (docs/design/life-skills.md §5, §6): the practice rooms. Each Experience's room is built for every track,
## and every target its steps touch, hold, aim at or go to is there, with every view a step looks from; a room's events
## change what they should (the alarm, the smoke, a door, Bobo's recovery position, the customer); the one next thing
## glows; nothing in a room casts the rooms' own shadows (the Quest's budget).


func _room(exp_id: String, track: String, seed: int = 1) -> LifeRoom:
	var r := LifeRooms.make(str(LifeExperience.data(exp_id).room), track,
		LifeExperience.vars(exp_id, track, seed, "ge"))
	add_child_autofree(r)
	return r


func after_all() -> void:
	Audio.stop_all()


func test_every_step_finds_its_targets_and_views_in_its_room() -> void:
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			var room := _room(id, track)
			for expert: bool in [false, true]:
				for region: String in ["ge", "uk", "us", "au"]:
					for step: Dictionary in LifeExperience.steps(id, track, expert, 2, region):
						var where := "%s.%s %s (expert %s)" % [id, track, step.id, expert]
						for t in LifeCheck.targets_of(step):
							assert_true(room.has_target(t), "%s: target %s" % [where, t])
						for key: String in ["view", "goes"]:
							if step.has(key):
								assert_true(room.views.has(str(step[key])), "%s: view %s" % [where, step[key]])
			assert_true(room.views.has(room.start_view), "%s.%s: its start view" % [id, track])


## Flat play: everything a step wants touched is on the screen from that step's view (the room's events played in
## order, GET LOW kept on once a step asked for it), in front of the camera and inside the 1280 × 720 canvas.
func test_every_thing_to_tap_is_on_screen_from_its_steps_view() -> void:
	var view := SubViewport.new()   # the game's narrowest canvas (16:9; phones are wider): the headless window is square
	view.size = Vector2i(LifeRoomHud.CANVAS)
	add_child_autofree(view)
	var cam := Camera3D.new()
	cam.fov = 72.0
	view.add_child(cam)
	Profile.data.settings.reduce_motion = true   # every pose and door at once (the game eases them)
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				var room := _room(id, track)
				var low := false
				for step: Dictionary in LifeExperience.steps(id, track, expert, 2, "ge"):
					if str(step.get("react", "")) != "":
						room.react(str(step.react))
					room.step_started(step)
					if bool(step.get("stand", false)):
						low = false
					if bool(step.get("low", false)) or (str(step.kind) == "action" and str(step.get("action", "")) == "low"):
						low = true
					var t := room.camera_transform(str(step.get("view", room.start_view)))
					if low:
						t.origin.y -= room.low_drop()
					cam.global_transform = t
					var wanted: Array[String] = []
					match str(step.kind):
						"touch", "go", "hold", "hands", "taps", "point", "rhythm", "sweep", "sequence", "find":
							wanted = LifeCheck.targets_of(step)
						"rub", "pour", "breathe", "steady", "cross":   # Life L2's
							wanted = LifeCheck.targets_of(step)
						"coins":
							for v: Variant in step.coins:
								wanted.append("coin_%d" % int(v))
						"basket":
							for it: Dictionary in step.items:
								wanted.append(str(it.target))
							wanted.append("till")
					# under the coach's bar nothing can be tapped; the bottom keeps its controls' room for some kinds
					var free := Rect2(12, 150, LifeRoomHud.CANVAS.x - 24, 540)
					if str(step.kind) in ["coins", "basket", "rhythm", "sweep", "timelapse", "rub", "pour", "breathe", "steady"]:
						free = Rect2(12, 150, LifeRoomHud.CANVAS.x - 24, 350)
					for target in wanted:
						var where := "%s.%s %s (expert %s): %s" % [id, track, step.id, expert, target]
						var p := room.target_position(target)
						assert_false(cam.is_position_behind(p), where + " is behind the camera")
						var s := cam.unproject_position(p)
						assert_true(free.has_point(s), "%s is off the free screen at %s" % [where, s])
						assert_true(room.target_node(target).is_visible_in_tree(), where + " is hidden")
					if str(step.get("after", "")) != "":
						room.react(str(step.after))
					room.step_done(step)
				room.free()
	Profile.data.settings.reduce_motion = false


## VR: what a step needs the hands on (hold, both hands, the chest's beat, a "hand" reach) is within a child's reach of
## where the child stands for that step (the eye point; crouching and leaning reach about a metre), and what a laser
## may press or aim at is within its reach.
func test_in_vr_every_thing_is_within_reach_of_where_the_child_stands() -> void:
	Profile.data.settings.reduce_motion = true
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				var room := _room(id, track)
				for step: Dictionary in LifeExperience.steps(id, track, expert, 2, "ge"):
					if str(step.get("react", "")) != "":
						room.react(str(step.react))
					room.step_started(step)
					var eye := room.vr_stand(str(step.get("view", room.start_view))).origin
					var kind := str(step.kind)
					# a "trigger" reach is the controller's trigger itself (a pedal: Life L2's practice car), never a touch
					var hands := (kind in ["hold", "hands", "rhythm", "rub"] or str(step.get("reach", "any")) == "hand") \
						and str(step.get("reach", "any")) != "trigger"
					for target in LifeCheck.targets_of(step):
						if target == "coins_back" or target.begins_with("coin_") and kind != "coins":
							continue
						var d := eye.distance_to(room.target_position(target))
						var where := "%s.%s %s (expert %s): %s is %.2f m away" % [id, track, step.id, expert, target, d]
						if hands:
							assert_lte(d, 1.1, where + " (the hands must reach it)")
						else:
							assert_lte(d, LifeRoomHost.LASER, where + " (the laser must reach it)")
					if str(step.get("after", "")) != "":
						room.react(str(step.after))
					room.step_done(step)
				room.free()
	Profile.data.settings.reduce_motion = false


func test_the_phones_keys_appear_when_it_is_picked_up() -> void:
	var room := _room("little_lifesaver", "little")
	assert_false(room.target_node("key_1").is_visible_in_tree(), "hidden until the phone is picked up")
	room.step_done({"id": "phone", "kind": "touch", "target": "phone"})
	for d in 10:
		assert_true(room.target_node("key_%d" % d).is_visible_in_tree(), str(d))


func test_the_alarm_and_the_smoke() -> void:
	var house := _room("fire_escape", "middle") as PracticeHouse
	assert_false(house.smoke.visible)
	house.react("smoke_on")
	assert_true(house.smoke.visible, "a soft grey haze under the ceiling")
	assert_lt(house.smoke.position.y - house.smoke.mesh.size.y * 0.5, LifeRoom.EYE + 0.6, "low enough to be under")
	assert_gt(house.smoke.position.y - house.smoke.mesh.size.y * 0.5, LifeRoom.EYE - LifeReach.LOW_DROP,
		"getting low gets under it")


func test_a_door_swings_open_and_shut() -> void:
	var house := _room("fire_escape", "middle") as PracticeHouse
	var pivot := house.doors.door_hall.pivot as Node3D
	var closed_yaw := pivot.rotation.y
	house.react("door_hall_open")
	await wait_seconds(0.8)
	assert_ne(snappedf(pivot.rotation.y, 0.01), snappedf(closed_yaw, 0.01))
	house.react("door_hall_shut")
	await wait_seconds(0.8)
	assert_almost_eq(pivot.rotation.y, closed_yaw, 0.02)


func test_the_doorways_line_up_with_their_doors() -> void:
	var house := _room("fire_escape", "middle") as PracticeHouse
	assert_almost_eq(house.target_position("door_hall").z - house.global_position.z, 0.0, 0.05,
		"the hall door fills its gap in the wall")
	assert_almost_eq(house.target_position("door_garden").x - house.global_position.x, -3.0, 0.05)


func test_bobo_does_the_recovery_position() -> void:
	var room := _room("little_lifesaver", "middle") as FirstAidRoom
	room.react("buddy_lying")
	assert_eq(room.bobo.current_pose, "lie")
	room.react("roll_side")
	assert_eq(room.bobo.current_pose, "side")


func test_no_injury_is_ever_shown_only_a_soft_ouch_spot() -> void:
	var room := _room("little_lifesaver", "middle") as FirstAidRoom
	for o in room.bobo.ouch:
		var c := ((o as MeshInstance3D).material_override as StandardMaterial3D).albedo_color
		assert_lt(c.r - c.g, 0.4, "warm and soft, never red")


func test_the_customer_comes_and_the_cash_box_counts() -> void:
	var v := LifeExperience.vars("money_stall", "middle", 3, "ge")
	var room := _room("money_stall", "middle", 3) as MarketRoom
	room.react("customer_1")
	assert_true(room.customer.visible)
	assert_eq(room.box_count, int(v.first_paid))
	room.react("customer_2")
	room.step_done({"kind": "coins", "target": "hand", "sum": int(v.change)})
	assert_eq(room.box_count, int(v.takings), "the cash box holds the day's takings")


func test_the_trays_coins_are_the_tracks() -> void:
	var little := _room("money_stall", "little") as MarketRoom
	assert_true(little.target_node("coin_1").visible)
	assert_false(little.target_node("coin_20").visible)
	var big := _room("money_stall", "big") as MarketRoom
	assert_true(big.target_node("coin_20").visible)


func test_the_next_thing_glows_and_only_it() -> void:
	var room := _room("little_lifesaver", "little")
	room.glow(["phone"] as Array[String])
	assert_eq(room.glowing(), ["phone"] as Array[String])
	room.glow(["buddy_shoulder"] as Array[String])
	assert_eq(room.glowing(), ["buddy_shoulder"] as Array[String])
	room.glow([] as Array[String])
	assert_eq(room.glowing(), [] as Array[String])


func test_the_rooms_cast_no_shadows_of_their_own() -> void:
	for id in LifeExperience.IDS:
		var room := _room(id, "big")
		for m: Node in room.find_children("*", "GeometryInstance3D", true, false):
			assert_eq((m as GeometryInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, str(m.name))
		for l: Node in room.find_children("*", "Light3D", true, false):
			assert_false((l as Light3D).shadow_enabled)


## The web build compiles a shader at its first sight (a pause): every material and sign of the rooms draws with a
## shader the warm-up's census already holds (ShaderWarmup: the avatar's, the mirror wall's, the animals' tags).
func test_every_shader_in_the_rooms_is_one_the_game_already_warms() -> void:
	var census := {}
	var labels := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			census[ShaderWarmup.key(d.material)] = true
		if d.has("label"):
			labels[JSON.stringify(d.label, "", true)] = true
	for id in LifeExperience.IDS:
		for track in LifeData.TRACKS:
			var room := _room(id, track)
			room.react("bin_fire")
			room.glow(room.target_names())
			for g: Node in room.find_children("*", "MeshInstance3D", true, false):
				var m := (g as MeshInstance3D).material_override
				assert_true(census.has(ShaderWarmup.key(ShaderWarmup.describe(m))), "%s.%s %s: %s" % [id, track, g.name,
					ShaderWarmup.describe(m)])
			for l: Node in room.find_children("*", "Label3D", true, false):
				var props := ShaderWarmup.draws_of(l)
				for d: Dictionary in props:
					if d.has("label"):
						assert_true(labels.has(JSON.stringify(d.label, "", true)), "%s.%s %s: %s" % [id, track, l.name, d.label])


func test_a_vr_stand_is_a_childs_eye_above_the_floor() -> void:
	var room := _room("fire_escape", "middle")
	var t := room.vr_stand("bed")
	assert_almost_eq(t.origin.y - room.global_position.y, LifeRoom.EYE, 0.001)
