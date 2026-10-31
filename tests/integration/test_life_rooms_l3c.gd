extends GutTest
## Owner #112, #118 (docs/design/life-skills.md §5 rows 7, 10, 11, §14 row 14; Life L3c): the three new practice rooms.
## Every safe mistake's event has its gentle picture (and it goes away after); Online City's play tablet shows one pretend
## page at a time, its chat buttons only on the chats, is picked up and held (flat in front of the view; in VR its face
## to the eyes), and asks for nothing to be typed; the man who says "come with me" only ever stands where he is; the school
## has a fire drill, never a lockdown; the practice metro's two lines meet at CENTRAL; the train comes in by the room's
## time (still while frozen) and stops; recycling goes into its bin, washing into its basket, toys back home, and the
## plant's soil darkens as it is watered; the rooms stay within the mesh budget (each count printed for the notes).

const BUDGET := 320


func _room(exp_id: String, track: String, seed: int = 1) -> LifeRoom:
	var r := LifeRooms.make(str(LifeExperience.data(exp_id).room), track, LifeExperience.vars(exp_id, track, seed, "ge"))
	add_child_autofree(r)
	return r


func _step(exp_id: String, track: String, step_id: String, expert := false) -> Dictionary:
	for s in LifeExperience.steps(exp_id, track, expert, 1, "ge"):
		if str(s.id) == step_id:
			return s
	return {}


func after_all() -> void:
	Audio.stop_all()


func test_every_safe_mistake_has_its_gentle_picture_and_it_goes_away() -> void:
	var seen := 0
	for exp_id: String in ["online_city", "find_way"]:
		for track: String in ["middle", "big"]:
			for expert: bool in [false, true]:
				for step in LifeExperience.steps(exp_id, track, expert, 1, "ge"):
					if not LifeCheck.tries_mistake(step):
						continue
					var room := _room(exp_id, track)
					room.step_started(step)
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
					seen += 1
	assert_eq(seen, 8, "four safe mistakes, each on both tries")


func test_the_tablet_shows_one_pretend_page_at_a_time() -> void:
	var room := _room("online_city", "middle") as OnlineRoom
	room.step_started(_step("online_city", "middle", "stranger"))
	assert_eq(room.page, "stranger")
	var shown := 0
	for p: String in room.pages:
		if (room.pages[p] as Node3D).visible:
			shown += 1
	assert_eq(shown, 1, "one page at a time")
	assert_true(room.target_node("block").is_visible_in_tree(), "BLOCK on a chat")
	assert_true(room.target_node("send_photo").is_visible_in_tree())
	assert_false(room.target_node("close_x").is_visible_in_tree(), "no X on a chat")
	room.step_started(_step("online_city", "middle", "popup"))
	assert_true(room.target_node("close_x").is_visible_in_tree(), "the pop-up's X")
	assert_false(room.target_node("block").is_visible_in_tree())
	assert_false(room.target_node("send_photo").is_visible_in_tree(), "the stranger's page has gone")


func test_nothing_on_the_tablet_asks_for_anything_personal_or_to_be_typed() -> void:
	for track in LifeData.TRACKS:
		var room := _room("online_city", track)
		assert_eq(room.find_children("*", "LineEdit", true, false).size(), 0, "nothing to type")
		for l: Node in room.find_children("*", "Label3D", true, false):
			var t := (l as Label3D).text.to_lower()
			for never: String in ["type your", "enter your", "your real name", "microphone", "http", "www", ".com"]:
				assert_false(t.contains(never), "%s: '%s' in '%s'" % [track, never, t])
		room.free()


func test_the_tablet_is_picked_up_and_held() -> void:
	var room := _room("online_city", "little") as OnlineRoom
	assert_false(room.holding, "on the table at first")
	assert_true(room.target_node("tablet_rest").is_visible_in_tree())
	room.step_done(_step("online_city", "little", "pick"))
	assert_true(room.holding, "in the child's hands")
	assert_false(room.target_node("tablet_rest").is_visible_in_tree(), "the table's spot goes (a hand at a button never meets it)")
	assert_eq(room.tablet.transform, room.held_rest, "flat: in front of the view")
	assert_eq(room.page, "home", "Online City's map")
	assert_true(room.is_held_target("app_game"), "the town's places are the tablet's own buttons")
	assert_false(room.is_held_target("gus"), "Gus is in the room")
	var head := Transform3D(Basis(), room.global_position + Vector3(0, 1.2, 1.2))
	var hand := Transform3D(Basis(), head.origin + Vector3(-0.2, -0.4, -0.3))
	var pose := room.hold_pose(hand, head)
	assert_gt(pose.basis.z.normalized().dot((head.origin - pose.origin).normalized()), 0.95, "its face turned to the eyes")
	assert_lt(pose.origin.distance_to(hand.origin), 0.25, "in the hand")
	room.tablet.global_transform = pose
	room.rest_held()
	assert_eq(room.tablet.transform, room.held_rest, "back in front of the flat view when the headset comes off")


func test_the_man_who_says_come_with_me_only_stands_where_he_is() -> void:
	var room := _room("find_way", "middle") as FindWayRoom
	var at := room.stranger.global_position
	var step := _step("find_way", "middle", "come_with")
	room.step_started(step)
	room.react("come_with")
	assert_true(room.stranger_words.visible, "his words: \"COME WITH ME!\"")
	await wait_process_frames(5)
	room.show_mistake("walk_off", true)
	await wait_process_frames(3)
	assert_eq(room.stranger.global_position, at, "never following, never grabbing: he stays where he stood")
	room.show_mistake("walk_off", false)
	room.step_done(step)
	assert_false(room.stranger_words.visible)
	assert_eq(room.stranger.global_position, at)


func test_the_school_has_a_fire_drill_never_a_lockdown() -> void:
	for track: String in ["little", "middle"]:
		var room := _room("find_way", track)
		assert_true(room.has_target("meeting_point"), track + ": the meeting point")
		assert_true(room.has_target("line_spot"), track + ": the line behind the teacher")
		for l: Node in room.find_children("*", "Label3D", true, false):
			var t := (l as Label3D).text.to_lower()
			for never: String in ["lockdown", "hide", "intruder"]:
				assert_false(t.contains(never), "%s: '%s'" % [track, t])
		room.free()


func test_the_practice_metros_two_lines_meet_at_central() -> void:
	var room := _room("find_way", "middle") as FindWayRoom
	var green := room.get_node("GreenLine") as Node3D
	var red := room.get_node("RedLine") as Node3D
	var central := room.target_position("station_central") - room.global_position
	assert_almost_eq(central.y, green.position.y, 0.06, "CENTRAL is on the green line")
	assert_almost_eq(central.x, red.position.x, 0.06, "and on the red line")
	for id: String in ["station_park", "station_market", "station_school"]:
		assert_almost_eq((room.target_position(id) - room.global_position).y, green.position.y, 0.06, id + ": green")
	for id: String in ["station_hill", "station_zoo", "station_river"]:
		assert_almost_eq((room.target_position(id) - room.global_position).x, red.position.x, 0.06, id + ": red")


func test_the_train_comes_in_by_the_rooms_time_and_stops() -> void:
	var room := _room("find_way", "big") as FindWayRoom
	room.react("train_coming")
	var from := room.train.position.x
	await wait_process_frames(5)
	assert_lt(room.train.position.x, from, "coming in")
	room.freeze(true)
	var still := room.train.position.x
	await wait_process_frames(5)
	assert_eq(room.train.position.x, still, "still while frozen")
	room.freeze(false)
	room.step_done(_step("find_way", "big", "platform"))
	assert_almost_eq(room.train.position.x, FindWayRoom.METRO.x + FindWayRoom.TRAIN_STOP, 0.01, "in, and stopped")


func test_recycling_washing_and_toys_go_to_their_homes() -> void:
	var room := _room("home_helper", "middle") as HomeHelperRoom
	var step := _step("home_helper", "middle", "jar")
	room.react(str(step.react))
	assert_true(is_instance_valid(room.item) and room.item.visible, "the jam jar on the counter")
	room.step_done(step)
	assert_false(room.item.visible, "into the GLASS bin")
	var sort := _step("home_helper", "middle", "sort")
	room.progress(sort, {"found": ["c_red", "c_blue"]})
	var basket: Vector3 = room.baskets.colours
	assert_lt(room.target_node("c_red").position.distance_to(basket), 0.3, "the red top into COLOURS")
	var little := _room("home_helper", "little") as HomeHelperRoom
	little.progress(_step("home_helper", "little", "tidy"), {"found": ["book"]})
	assert_eq(little.target_node("book").position, little.homes.book, "the book back on its shelf")


func test_the_plants_soil_darkens_as_it_is_watered() -> void:
	var room := _room("home_helper", "little") as HomeHelperRoom
	var step := _step("home_helper", "little", "plant")
	var dry := (room.plant_soil.material_override as StandardMaterial3D).albedo_color
	room.progress(step, {"level": 0.55})
	var damp := (room.plant_soil.material_override as StandardMaterial3D).albedo_color
	assert_lt(damp.v, dry.v, "damp soil is darker")


func test_the_rooms_stay_within_the_mesh_budget() -> void:
	for exp_id: String in ["online_city", "find_way", "home_helper"]:
		var counts: Array[String] = []
		for track in LifeData.TRACKS:
			var room := _room(exp_id, track)
			var n := room.find_children("*", "MeshInstance3D", true, false).size()
			counts.append(str(n))
			assert_lte(n, BUDGET, "%s.%s: %d meshes" % [exp_id, track, n])
			room.free()
		gut.p("LIFE3C_MESHES %s %s" % [exp_id, " / ".join(counts)])
