extends GutTest
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5, §3.5b, §3.8, §3.10, §4.4 flat; the B2 brief): a child plays a
## voyage from start to end, flat (a phone, a tablet, a PC). The garden's hook (5.1: tap the can, it pours; tap the leaf),
## the dive, under the leaf, inside: one tap glides the avatar to a thing (at most 1.2 s) and acts (a door, a sugar, the
## gold pipe), the camera following and coming back to the overview; act 1, the weather, the bud full, the return, the
## world's answer and the end card. The record: every judged beat a SkillShown event for the unit, each solved one paid at
## once (EarnRules), the outcome a round's; the break holds everything; STOP FOR NOW records nothing but the plant keeps
## the bud's fill; Android Back asks before leaving. 5.T1, the desert night, plays the same way.

class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(language: String) -> bool:
		return language == "en"

	func speak(text: String, _language: String) -> void:
		said.append(text)


const UNIT := "g5.science.plants_air_water"

var host: LeafVoyageHost
var layer: CanvasLayer
var screen: Control
var voice: FakeVoice
var outcomes: Array = []
var stops: Array = []
var golds := 0
var _old_voice: ReadAloud.Voice
var _read_to_me := true
var _path := ""


func before_each() -> void:
	outcomes.clear()
	stops.clear()
	golds = 0
	voice = FakeVoice.new()
	_old_voice = ReadAloud.voice
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	_read_to_me = bool(Profile.data.settings.read_to_me)
	Profile.data.settings.read_to_me = true
	Profile.data.settings.reduce_motion = true
	_path = "user://test_leaf_host_%d.json" % OS.get_process_id()
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	screen = Control.new()
	layer.add_child(screen)


func after_each() -> void:
	if is_instance_valid(host) and not host.closed:
		host.close()
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	Profile.data.settings.read_to_me = _read_to_me
	Profile.data.settings.reduce_motion = false
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _content(voyage: String) -> Dictionary:
	return {"id": UNIT, "exercises": [], "play": {"game": "leaf_voyage", "params": {"voyage": voyage},
		"world_task": "Put a plant by a sunny window and one in a dark cupboard. Look after a week."}}


func _open(voyage: String = "5.1") -> LeafVoyageHost:
	host = LeafVoyageHost.new()
	host.progress_path = _path
	host.setup(UNIT, _content(voyage), 7, 0, {"title": "Plants grow from air and water"})
	host.first_try_gold = func() -> int:
		golds += 1
		return 5
	host.finished.connect(func(o: Dictionary) -> void: outcomes.append(o))
	host.stopped.connect(func(o: Dictionary) -> void: stops.append(o))
	host.open(screen)
	await wait_process_frames(2)
	host.set_process(false)   # time moves only when a test says so
	return host


func _step(seconds: float, dt: float = 0.1) -> void:
	var t := 0.0
	while t < seconds - 0.0001 and is_instance_valid(host) and not host.closed:
		host.step(dt)
		t += dt


func _tap(t: String) -> void:
	var at := host.screen_of(t)
	host.finger_down(at)
	host.finger_up(at)


func _said(id: String) -> bool:
	var spoken := Lang.t(SchoolSpeech.spoken(LeafVoyages.line(id)))
	return voice.said.has(spoken)


## Waters the soil (5.1) and touches the leaf, then waits through the dive into the leaf.
func _to_inside() -> void:
	if host.journey.has_can():
		_tap("can")
		_step(LeafVoyageHost.POUR_TIME + 0.2)
	_tap("leaf")
	_step(LeafJourney.DIVE_TIME + LeafJourney.UNDER_TIME + LeafVoyageHost.GLIDE_MAX + 0.4)


## The rule, played by taps: shut the doors in act 1 and in the heat, open them when it is cool, carry the sugar.
func _rule_tap() -> void:
	if host.busy():
		return
	var run := host.journey.run
	var w := run.weather_now()
	var want := run.phase == LeafRun.PLAY and bool(w.open)
	for i in run.sim.doors.size():
		if run.sim.doors[i] != want:
			_tap("door_%d" % i)
			return
	if run.carried() > 0:
		_tap("gold_pipe")
	elif run.sim.waiting() > 0 and run.phase == LeafRun.PLAY:
		_tap(host.waiting_sugar())


func _play_by_the_rule(limit: float = 600.0, dt: float = 0.1) -> void:
	var t := 0.0
	while t < limit and is_instance_valid(host) and host.journey.stage == LeafJourney.INSIDE:
		_rule_tap()
		host.step(dt)
		t += dt


# --- The garden and the dive ------------------------------------------------------------------------------------------

func test_the_voyage_opens_in_the_garden_with_its_hook_and_hides_the_screen() -> void:
	await _open()
	assert_eq(host.journey.stage, LeafJourney.HOOK)
	assert_false(layer.visible, "the voyage shows instead of the screen it came from")
	assert_true(_said("L1"), "Oh no! Our sunflower is drooping in the heat.")
	assert_true(host.garden.glowing().has("can"), "the can glows")
	assert_eq(host.hud.screen_words(), 0, "nothing to read")
	assert_true(PlayHost.any_open(get_tree()), "Back belongs to the voyage")


func test_a_tap_on_the_can_pours_then_a_tap_on_the_leaf_dives_inside() -> void:
	await _open()
	_tap("can")
	_step(LeafVoyageHost.POUR_TIME + 0.2)
	assert_true(host.journey.watered, "the can poured by itself")
	assert_true(host.garden.watered, "the soil darkened")
	assert_true(_said("L2"))
	_tap("leaf")
	assert_eq(host.journey.stage, LeafJourney.DIVE)
	_step(LeafJourney.DIVE_TIME * 0.5)
	assert_not_null(host.dive, "Size Magic's steps down onto the leaf")
	_step(LeafJourney.DIVE_TIME * 0.5 + LeafJourney.UNDER_TIME + LeafVoyageHost.GLIDE_MAX + 0.4)
	assert_eq(host.journey.stage, LeafJourney.INSIDE)
	assert_not_null(host.place)
	assert_true(host.place.is_visible_in_tree(), "inside the leaf")
	assert_false(host.garden.is_visible_in_tree(), "the garden waits for the return")
	assert_true(_said("L6"), "Look! The water is escaping through the doors.")


func test_a_tap_on_the_leaf_while_the_can_still_pours_dives_and_nothing_waits() -> void:
	await _open()
	_tap("can")
	_step(LeafVoyageHost.POUR_TIME * 0.7)
	assert_true(host.journey.watered, "watered, the can still pouring")
	_tap("leaf")
	_step(0.2)
	assert_eq(host.journey.stage, LeafJourney.DIVE)
	assert_false(host.busy(), "the pour ended with the dive: nothing waits for it")


func test_a_child_who_waits_in_the_garden_sees_the_ghost_show_the_can() -> void:
	await _open()
	_step(LeafJourney.GHOST_AFTER + 0.3)
	assert_true(host.hud.ghost.showing(), "the ghost finger shows the can")


# --- Inside: one tap glides and acts ----------------------------------------------------------------------------------

func test_inside_a_tap_on_a_door_glides_there_and_squeezes_it() -> void:
	await _open()
	await _to_inside()
	var run := host.journey.run
	assert_eq(run.phase, LeafRun.ACT1)
	var door := run.sim.doors.find(true)
	_tap("door_%d" % door)
	assert_true(host.busy(), "gliding")
	_step(LeafVoyageHost.GLIDE_MAX + 0.1)
	assert_false(run.sim.doors[door], "the door is shut, within the glide's 1.2 s")
	assert_lt(host.avatar.global_position.distance_to(host.place.to_global(host.place.view("door_%d" % door).feet)),
		0.3, "the avatar stands at the door")
	_step(LeafVoyageHost.DWELL + LeafVoyageHost.GLIDE_MAX + 0.2)
	assert_lt(host.camera.global_position.distance_to(host.place.camera_transform(LeafPlace.WORK).origin), 0.2,
		"the camera comes back to the overview, where every thing to tap is in sight")


func test_the_camera_button_gives_the_avatar_s_eyes_and_back() -> void:
	await _open()
	await _to_inside()
	host.toggle_camera()
	_step(LeafVoyageHost.GLIDE_MAX + 0.1)
	assert_true(host.first_person)
	assert_lt(host.camera.global_position.distance_to(host.avatar.eyes()), 0.15, "the avatar's eyes")
	host.toggle_camera()
	_step(LeafVoyageHost.GLIDE_MAX + 0.1)
	assert_false(host.first_person)


func test_keys_and_a_game_controller_fly_the_avatar_and_never_into_a_cell() -> void:
	await _open()
	await _to_inside()
	var start := host.avatar.global_position
	Input.action_press(&"move_forward")
	_step(1.0)
	Input.action_release(&"move_forward")
	var moved := host.avatar.global_position - start
	assert_gt(moved.length(), 1.0, "flew forward")
	assert_lt(moved.z, 0.0, "the way the camera looks (into the leaf)")
	var local := host.place.to_local(host.avatar.global_position + Vector3(0, LeafAvatar.HEIGHT * 0.5, 0))
	assert_true(host.place.space.free_at(local, LeafVoyageHost.AVATAR_RADIUS * 0.9), "never inside a cell or a column")
	Input.action_press(&"fly_up")
	_step(1.0)
	Input.action_release(&"fly_up")
	assert_gt(host.avatar.global_position.y, start.y + 1.0, "E (or Space) flies up")


func test_a_sugar_is_carried_to_the_gold_pipe_by_two_taps() -> void:
	await _open()
	await _to_inside()
	var run := host.journey.run
	run.sim.made = 3.0   # sugar waiting at the workshops (LeafSim's own tests build it)
	host.step(0.1)
	assert_gt(run.sim.waiting(), 0)
	_tap(host.waiting_sugar())
	_step(LeafVoyageHost.GLIDE_MAX + 0.1)
	assert_eq(run.carried(), 1, "picked up: on the avatar's back")
	assert_eq(host.avatar.carried, 1)
	_tap("gold_pipe")
	_step(LeafVoyageHost.GLIDE_MAX + 0.1)
	assert_eq(run.sim.delivered, 1, "it whooshes away to the bud")


func test_show_me_does_one_step_and_the_break_holds_everything() -> void:
	await _open()
	await _to_inside()
	var run := host.journey.run
	host.hud.show_me.emit()
	_step(LeafRun.GHOST_TAP + 0.2)
	assert_lt(run.sim.open_count(), run.sim.doors.size(), "the ghost shut a door")
	host.hud.open_break()
	var clock := run.clock
	_step(3.0)
	assert_eq(run.clock, clock, "a break holds the leaf, the weather and Hoot")
	host.hud.close_break()
	_step(0.5)
	assert_gt(run.clock, clock)


# --- The whole voyage, the record, the end card --------------------------------------------------------------------------

func test_5_1_plays_from_start_to_end_and_counts_like_a_round() -> void:
	await _open()
	await _to_inside()
	_play_by_the_rule()
	assert_eq(host.journey.stage, LeafJourney.RETURN, "the bud is full: the return")
	_step(LeafJourney.RETURN_TIME + LeafJourney.ANSWER_GAP * 6.0)
	assert_eq(host.journey.stage, LeafJourney.END)
	assert_true(_said("L22") and _said("L24") and _said("L26"), "the bloom, the idea, the end card's line")
	assert_true(host.hud.end_open(), "the end card")
	assert_eq(host.hud.screen_words(), 0, "pictures, stars and numbers only")
	assert_eq(host.garden.sunflower.bloom, 1.0, "the sunflower bloomed")
	var progress := LeafProgress.open_at(_path)
	assert_true(progress.done.has("5.1"), "the garden remembers the voyage")
	host.end_choice(LeafVoyageHost.BACK)
	assert_eq(outcomes.size(), 1, "finished once, when the child leaves the card")
	var o: Dictionary = outcomes[0]
	var shown: SkillShown = o.shown
	assert_gte(shown.total(UNIT), 7, "act 1 and the silent turns: at least 7 events")
	assert_eq(int(o.total), shown.total(UNIT))
	assert_eq(int(o.right_first), shown.right_first(UNIT))
	assert_gte(int(o.right_first), 6, "the rule masters it")
	assert_eq(golds, int(o.right_first), "each solved beat paid at once")
	assert_eq(PlaySignature.then_of(o), {}, "back: nothing opens next")
	assert_true(host.closed)


func test_the_end_card_offers_again_and_the_voyage_board() -> void:
	await _open()
	await _to_inside()
	_play_by_the_rule()
	_step(LeafJourney.RETURN_TIME + LeafJourney.ANSWER_GAP * 6.0)
	host.end_choice(LeafVoyageHost.NEXT)
	assert_true(host.hud.board_open(), "the voyage board: the sunflower and the cactus")
	assert_true(host.board_open_voyages().has("5.T1"), "the cactus opens once 5.1 is done")
	host.end_choice("5.T1")
	assert_eq(PlaySignature.then_of(outcomes[0]), {"voyage": "5.T1"}, "the caller opens the desert next")


func test_stop_for_now_records_nothing_but_keeps_the_buds_fill() -> void:
	await _open()
	await _to_inside()
	var run := host.journey.run
	run.sim.bud = 4.0
	host.hud.stop_for_now.emit()
	assert_eq(outcomes.size(), 0, "nothing recorded")
	assert_eq(stops.size(), 1)
	assert_true(host.closed)
	assert_true(layer.visible, "the screen is back")
	assert_almost_eq(float(LeafProgress.open_at(_path).plant("sunflower").bud), 4.0 / 12.0, 0.01, "never less plant")


func test_android_back_asks_before_leaving_and_a_second_back_carries_on() -> void:
	await _open()
	host.hud.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_true(host.hud.break_open())
	assert_eq(host.hud.break_words.text, PlayHud.LEAVE_WORDS)
	host.hud.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	assert_false(host.hud.break_open(), "a second Back carries on")
	assert_false(host.closed)


func test_the_desert_night_plays_from_start_to_end_as_new_setting_evidence() -> void:
	await _open("5.T1")
	assert_true(_said("D1"), "A cactus from the desert! It's hot and thirsty.")
	assert_false(host.garden.has_target("can"), "no watering can: the sand is dry")
	await _to_inside()
	assert_eq(host.place.dressing, "cactus")
	_play_by_the_rule()
	_step(LeafJourney.RETURN_TIME + LeafJourney.ANSWER_GAP * 4.0)
	assert_true(_said("D8") and _said("D9"), "the night flower and the rule in words")
	host.end_choice(LeafVoyageHost.BACK)
	var shown: SkillShown = outcomes[0].shown
	assert_eq(shown.total(UNIT), 6, "six beats: Day 1, Night 1, Dawn 1, Day 2, Night 2, Dawn 2")
	assert_gte(shown.transfer(UNIT), 5, "solved with no help in a new setting: NEW_SETTING")


# --- The real unit opens the voyage (data/play/mechanics.json, the unit's play block) ---------------------------------

func test_the_units_play_names_the_voyage_and_the_school_opens_it() -> void:
	Curriculum.clear_cache()
	var c := Curriculum.content(UNIT)
	assert_eq(PlaySignature.game_of(c), "leaf_voyage", "the unit's play block names the game")
	assert_eq(PlaySignature.host_for(c), "res://entities/play/leaf/leaf_voyage_host.gd", "the registry's host")
	assert_eq(LeafVoyageHost.voyage_of(c), "5.1", "its params choose the voyage")
	assert_eq(PlayMechanics.level(c), PlayMechanics.P1, "a deep game plays it")
	var school := SchoolScreen.new()
	school.profile = ProfileData.new()
	school.profile.school.grade = 5
	school.save_profile = func() -> void: pass
	school.today = func() -> int: return 20_000
	school.next_seed = func() -> int: return 7
	school.quests_path = "user://test_leaf_host_quests_%d.json" % OS.get_process_id()
	layer.add_child(school)
	await wait_process_frames(2)
	school.show_play(UNIT)
	await wait_process_frames(2)
	assert_true(school.play_host is LeafVoyageHost, "PLAY opens the voyage")
	assert_eq((school.play_host as LeafVoyageHost).voyage_id, "5.1")
	school.play_host.close()
