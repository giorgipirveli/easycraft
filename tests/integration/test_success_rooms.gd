extends GutTest
## Owner #115 (Success S2): what the four practice rooms do (Life's own room tests already check every target, view,
## tap band, VR reach, warmed shader and shadow for them): Mo's face goes from cross to happy as the child listens, says
## sorry and fixes it; Robo does something silly but harmless after a muddled order and the right thing after a clear
## one; Ms Ade comes round the table to shake hands; Bobo's blocks stack and wobble down gently; the habit plant only ever
## grows; the coins land in the jar; the village's people turn to each other when introduced; the Story Theatre shows one
## scene at a time with its place and year; the people wear their own clothes and names.


func before_all() -> void:
	Profile.data.settings.reduce_motion = true   # every move at once


func after_all() -> void:
	Profile.data.settings.reduce_motion = false
	Audio.stop_all()


func _room(exp_id: String, track: String) -> LifeRoom:
	var r := LifeRooms.make(str(LifeExperience.data(exp_id).room), track, LifeExperience.vars(exp_id, track, 1, "ge"))
	add_child_autofree(r)
	return r


func test_mo_is_heard_said_sorry_to_and_smiles() -> void:
	var r := _room("talk_deal", "little") as TalkSquare
	assert_false(r.mo.visible, "Mo comes when the try starts")
	r.react("mo_comes")
	assert_true(r.mo.visible)
	assert_eq(r.mo.feeling, "cross")
	r.react("mo_calm")
	assert_eq(r.mo.feeling, "calm")
	var bread := r.target_node("bread")
	var at := bread.position
	r.react("give_bread")
	assert_ne(bread.position, at, "the fresh loaf goes to Mo")
	r.react("mo_happy")
	assert_eq(r.mo.feeling, "happy", "never a scary face: cross, calm, happy")


func test_robo_muddles_harmlessly_and_then_does_exactly_the_clear_thing() -> void:
	var r := _room("talk_deal", "little") as TalkSquare
	r.react("robo_muddle")
	assert_not_null(r.robo.head.get_node_or_null("MuddleBox"), "a muddled order: a box on his head, silly and harmless")
	assert_eq(r.robo.feeling, "worried")
	await wait_seconds(TalkSquare.MUDDLE_SECONDS + 0.3)
	assert_null(r.robo.head.get_node_or_null("MuddleBox"), "the silly box is gone again")
	assert_eq(r.robo.feeling, "calm")
	var box := r.target_node("box_red")
	r.react("robo_red")
	assert_lt(box.position.distance_to(TalkSquare.BASKET_AT + Vector3(0, 0.2, 0)), 0.01, "the red box in the basket")


func test_ms_ade_comes_round_to_shake_hands() -> void:
	var r := _room("talk_deal", "big") as TalkSquare
	var ade := r.investors.ade as LifeBuddy
	assert_eq(ade.current_pose, "sit")
	r.react("ade_comes")
	assert_eq(ade.current_pose, "stand")
	assert_lt(ade.position.distance_to(r.target_position("ade_hand") - r.global_position), 0.9, "beside her hand's spot")


func test_bobos_tower_stacks_falls_gently_and_stacks_again() -> void:
	var r := _room("goal_board", "little") as GoalRoom
	var step := {"id": "build", "kind": "sequence", "targets": ["block_big", "block_mid", "block_small"]}
	r.progress(step, {"i": 3})
	var small := r.blocks.block_small as Node3D
	assert_gt(small.position.y, 0.5, "three blocks high")
	r.react("tower_falls")
	assert_lt(small.position.y, 0.2, "down on the mat, softly")
	assert_eq(r.bobo.feeling, "sad")
	r.react("tower_reset")
	assert_eq(r.bobo.feeling, "calm")


func test_the_plant_only_ever_grows_and_the_coins_land_in_the_jar() -> void:
	var r := _room("goal_board", "little") as GoalRoom
	r.react("days_pass")
	var grown := r.plant_stage
	assert_gt(grown, 1)
	r.react("plant_shows")
	assert_eq(r.plant_stage, grown, "a missed day never shrinks it")
	r.progress({"id": "jar", "kind": "taps", "target": "jar", "count": 2}, {"t": 2})
	assert_eq(r.jar_coins.size(), 2)


func test_the_week_turns_green_on_every_kept_day() -> void:
	var r := _room("goal_board", "middle") as GoalRoom
	r.react("week_starts")
	r.progress({"id": "week", "kind": "find", "targets": ["day_1", "day_2"]}, {"found": ["day_1", "day_2"]})
	var mat := (r.days.day_1 as MeshInstance3D).material_override as StandardMaterial3D
	assert_gt(mat.albedo_color.g, mat.albedo_color.r, "green")
	assert_true(r.cloud.visible, "Wednesday's cloud: the day forgotten")


func test_people_turn_to_each_other_when_introduced() -> void:
	var r := _room("connections", "middle") as VillageSquare
	var ana := r.person_node("ana")
	var before := ana.rotation.y
	r.react("ana_ivan")
	assert_ne(ana.rotation.y, before)
	assert_eq(ana.feeling, "happy")
	assert_eq(r.person_node("ivan").feeling, "happy")


func test_the_village_people_wear_their_own_clothes_and_names() -> void:
	var r := _room("connections", "big") as VillageSquare
	for id: String in ["amara", "mei", "kenji", "omar", "sam", "lina"]:
		var b := r.person_node(id)
		assert_not_null(b, id)
		var name_sign := b.find_child("Name", false, false) as Label3D
		assert_eq(name_sign.text, str(SuccessPeople.person(id).name).to_upper(), id)
	assert_not_null(r.person_node("omar").find_child("Wheelchair", true, false), "Omar's wheelchair")
	assert_not_null(r.person_node("amara").find_child("ChefHat", true, false), "the baker's hat")
	assert_not_null(r.person_node("kenji").find_child("Beard", true, false))


func test_a_promise_kept_the_next_morning() -> void:
	var r := _room("connections", "little") as VillageSquare
	r.react("lina_alone")
	assert_eq(r.lina.feeling, "sad")
	r.react("night")
	assert_lt(r.env.background_color.v, 0.5, "the night falls softly")
	r.react("morning")
	r.react("gift_given")
	assert_eq(r.lina.feeling, "happy")


func test_the_story_theatre_shows_one_scene_at_a_time() -> void:
	var r := _room("success_stories", "middle") as StoryStage
	r.react("scene_wright")
	assert_true((r.scenes.scene_wright as Node3D).visible)
	assert_false((r.scenes.scene_carver as Node3D).visible)
	assert_eq(r.backdrop.text, StoryStage.SCENE_WORDS.scene_wright)
	r.react("scene_carver")
	assert_false((r.scenes.scene_wright as Node3D).visible)
	assert_true((r.scenes.scene_carver as Node3D).visible)
	r.progress({"id": "rotate", "kind": "sequence", "targets": ["plot_peanuts", "plot_cotton"]}, {"i": 1})
	var mat := (r.target_node("plot_peanuts") as MeshInstance3D).material_override as StandardMaterial3D
	assert_gt(mat.albedo_color.g, 0.5, "the peanuts grow green")


func test_the_braille_dots_are_numbered_like_braille() -> void:
	var r := _room("success_stories", "little") as StoryStage
	var d1 := r.target_position("dot_1")
	var d2 := r.target_position("dot_2")
	var d4 := r.target_position("dot_4")
	assert_lt(d2.y, d1.y, "dot 2 is under dot 1 (1-2-3 down the left)")
	assert_gt(d4.x, d1.x, "dot 4 is on the right")
