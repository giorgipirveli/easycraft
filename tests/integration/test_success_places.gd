extends GutTest
## Owner #115 (Success S2): the Success strand's places on the Life map, inside the Life screen (the School's frame):
## the four new areas (Goals and habits, Talk and deal, Connections, Success stories) in one row of the map; an area
## with a place shows its button (MY GOAL BOARD, MY CONNECTIONS BOOK, THE STORY SHELF); the Goal Board makes a goal from
## pictures (a dream, a goal, steps, an if-then plan; the Big track's obstacle plan too) and the habit garden grows a
## plant on each kept day; the Connections Book shows the people met (their needs, their warmth in words, a mentor's
## tip); the story shelf reads the twenty stories and asks "Which skill did they use?"; the grown-ups' page says the
## goal, the habit's days, the people and the stories. Every page fits the frame and has a speaker.

class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


const DAY := 20_000

var profile: ProfileData
var saves := 0
var screen: LifeScreen
var voice: FakeVoice
var _old_voice: ReadAloud.Voice
var measure_path := ""


func before_each() -> void:
	ParentGate.reset_tries()
	profile = ProfileData.new()
	saves = 0
	_old_voice = ReadAloud.voice
	voice = FakeVoice.new()
	ReadAloud.voice = voice
	measure_path = "user://life_measure_success_%d.json" % OS.get_process_id()


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	if is_instance_valid(screen) and is_instance_valid(screen.host):
		screen.host.close()
	if FileAccess.file_exists(measure_path):
		DirAccess.remove_absolute(measure_path)
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _open(track: String = "middle") -> LifeScreen:
	profile.life.track = track
	screen = LifeScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	screen.locale = "ka_GE"
	screen.measure = LifeMeasure.new(measure_path)
	add_child_autofree(screen)
	await wait_process_frames(2)
	return screen


func _button(text: String) -> Button:
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree() and not (b as Button).disabled:
			return b
	return null


func _named(n: String) -> Node:
	var found := screen.find_children(n, "", true, false)
	return found[0] if not found.is_empty() else null


func _labels() -> String:
	var out: Array[String] = []
	for l in screen.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out.append((l as Label).text)
	for b in screen.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree():
			out.append((b as Button).text)
	return "\n".join(out)


func _press(text: String) -> void:
	var b := _button(text)
	assert_not_null(b, "a button %s" % text)
	if b:
		b.pressed.emit()
	await wait_process_frames(1)


func _fits(what: String) -> void:
	await wait_process_frames(2)
	var size := screen.get_combined_minimum_size()
	assert_lte(size.x, SchoolUi.FRAME.x, "%s is %s" % [what, size])
	assert_lte(size.y, SchoolUi.FRAME.y, "%s is %s" % [what, size])
	assert_gt(screen.find_children("ReadAloud", "", true, false).size(), 0, "%s has a speaker" % what)


# --- The map and the areas ---

func test_the_map_shows_the_success_strands_six_areas_in_one_row() -> void:
	await _open()
	for id: String in ["money", "thinking", "goals", "talk", "connections", "stories"]:
		assert_not_null(_named("Area_" + id), id)
	var goals := _named("Area_goals") as Control
	var money := _named("Area_money") as Control
	await wait_process_frames(1)
	assert_almost_eq(goals.get_global_rect().position.y, money.get_global_rect().position.y, 2.0, "one row")
	await _fits("map")


func test_an_area_with_a_place_shows_its_button() -> void:
	await _open("little")
	screen.show_area("goals")
	await wait_process_frames(1)
	assert_string_contains(_labels(), "One step at a time")
	assert_not_null(_button(SuccessPlaces.TITLES.goal_board))
	await _fits("goals area")
	screen.show_area("talk")
	await wait_process_frames(1)
	assert_null(_button(SuccessPlaces.TITLES.goal_board), "Talk and deal is its practice room only")
	screen.show_area("connections")
	await wait_process_frames(1)
	assert_not_null(_button(SuccessPlaces.TITLES.connections_book))
	screen.show_area("stories")
	await wait_process_frames(1)
	assert_not_null(_button(SuccessPlaces.TITLES.story_shelf))


func test_the_success_units_try_their_experiences() -> void:
	await _open("big")
	screen.show_unit("life.talk.pitch")
	await wait_process_frames(1)
	assert_not_null(_button("TRY IT"))
	assert_not_null(_named("Stamps"))


# --- The Goal Board and the habit garden ---

func test_a_goal_from_pictures_on_the_middle_track() -> void:
	await _open("middle")
	screen.show_success_place("goal_board")
	await wait_process_frames(1)
	assert_eq(screen.page, LifeScreen.SUCCESS)
	await _fits("the empty Goal Board")
	await _press(GoalBoardPage.MAKE)
	await _fits("the dreams")
	await _press(SuccessGoals.dream("moon").title)
	await _press(SuccessGoals.goal_of("moon", "moon_gold").title)
	await _fits("the steps")
	for s: String in ["learn", "save", "buy"]:
		await _press(SuccessGoals.step_of("moon", s).title)
	await _press("NEXT")
	await _fits("the plan")
	await _press(SuccessGoals.part("cues", "after_lesson").title)
	await _press(SuccessGoals.part("actions", "save_10").title)
	await _press("NEXT")
	await _fits("the goal made")
	assert_string_contains(_labels(), "When I finish a lesson, I put 10 gold aside for my goal.")
	await _press("DONE")
	assert_eq(str(profile.life.success.goal.d), "moon")
	assert_eq(profile.life.success.goal.s, ["learn", "save", "buy"])
	assert_gt(saves, 0)
	var words := _labels()
	assert_string_contains(words, "Save the gold for the Moon rocket")
	assert_string_contains(words, "Mission Control's rocket")
	await _fits("the Goal Board with its goal")


func test_the_little_track_picks_a_ready_plan() -> void:
	await _open("little")
	screen.show_success_place("goal_board")
	await wait_process_frames(1)
	await _press(GoalBoardPage.MAKE)
	await _press(SuccessGoals.dream("build").title)
	await _press(SuccessGoals.goal_of("build", "house").title)
	await _press("NEXT")   # Little: the first steps, ready-made
	await _press(SuccessGoals.plan_of("after_lesson", "save_10"))
	await _press("DONE")
	assert_eq(str(profile.life.success.goal.w), "after_lesson")
	assert_eq((profile.life.success.goal.s as Array).size(), 3)


func test_the_big_track_adds_an_obstacle_plan() -> void:
	await _open("big")
	screen.show_success_place("goal_board")
	await wait_process_frames(1)
	await _press(GoalBoardPage.MAKE)
	await _press(SuccessGoals.dream("life").title)
	await _press(SuccessGoals.goal_of("life", "self_2").title)
	for s: String in ["skill", "coach", "alone"]:
		await _press(SuccessGoals.step_of("life", s).title)
	await _press("NEXT")
	await _press(SuccessGoals.part("cues", "after_dinner").title)
	await _press(SuccessGoals.part("actions", "one_step").title)
	await _press("NEXT")
	await _fits("the obstacle plan")
	await _press(SuccessGoals.part("obstacles", "tired").title)
	await _press(SuccessGoals.part("responses", "tiny").title)
	await _press("NEXT")
	assert_string_contains(_labels(), "If I feel tired, then I do just a tiny part.")
	await _press("DONE")
	assert_eq(str(profile.life.success.goal.o), "tired")


func test_ticking_the_last_step_celebrates_once() -> void:
	SuccessGoals.set_goal(profile.life.success, profile, "build", "house", ["draw", "collect", "walls"], "saturday",
		"build_10", DAY - 3)
	SuccessGoals.tick(profile.life.success, 0)
	SuccessGoals.tick(profile.life.success, 1)
	await _open("middle")
	screen.show_success_place("goal_board")
	await wait_process_frames(1)
	var tick := _named("Step3") as Button   # the last step
	assert_not_null(tick)
	tick.pressed.emit()
	await wait_process_frames(1)
	assert_eq(profile.life.success.goals_reached, 1)
	assert_string_contains(_labels(), GoalBoardPage.REACHED)
	assert_not_null(_named("GoalReached"))


func test_the_habit_garden_grows_on_a_kept_day() -> void:
	await _open("middle")
	screen.show_success_place("goal_board")
	await wait_process_frames(1)
	await _press(GoalBoardPage.PICK_HABIT)
	await _fits("the habits")
	await _press(SuccessHabits.habit("water").title)
	assert_eq(str(profile.life.success.habit.h), "water")
	assert_string_contains(_labels(), SuccessHabits.ASK)
	await _press(GoalBoardPage.YES)
	assert_eq(SuccessHabits.days_kept(profile.life.success), 1)
	assert_string_contains(_labels(), SuccessHabits.GREW)
	assert_null(_button(GoalBoardPage.YES), "once a day")
	await _press(GoalBoardPage.CHANGE)
	await _press(GoalBoardPage.NOT_TODAY)
	assert_eq(SuccessHabits.days_kept(profile.life.success), 0, "today's answer changed")
	assert_string_contains(_labels(), "honest")
	await _fits("the habit garden")


# --- The Connections Book ---

func test_the_book_shows_the_people_met_and_waits_for_the_others() -> void:
	SuccessPeople.record(profile.life.success, [{"meet": ["amara", "omar"]}, {"help": "amara"}, {"mentor": "omar"}], DAY)
	await _open("middle")
	screen.show_success_place("connections_book")
	await wait_process_frames(1)
	var words := _labels()
	assert_string_contains(words, "Amara")
	assert_string_contains(words, ConnectionsBookPage.NOT_MET)
	await _fits("the Connections Book")
	(_named("Person_amara") as Button).pressed.emit()
	await wait_process_frames(1)
	words = _labels()
	assert_string_contains(words, "flour every morning")
	assert_string_contains(words, SuccessPeople.warmth_words("amara", int(profile.life.success.person("amara").w)))
	await _fits("a person's page")
	await _press("BACK")
	await _press("NEXT PAGE")   # Omar is on the book's second page
	(_named("Person_omar") as Button).pressed.emit()
	await wait_process_frames(1)
	assert_string_contains(_labels(), "Check twice, fix once.")
	assert_string_contains(_labels(), "wheelchair")


func test_the_book_has_pages_and_a_person_not_met_is_never_opened() -> void:
	await _open("middle")
	screen.show_success_place("connections_book")
	await wait_process_frames(1)
	var unmet := _named("Person_amara") as Button
	assert_true(unmet.disabled, "not met yet: nothing to open")
	await _press("NEXT PAGE")
	assert_not_null(_named("Person_" + str(SuccessPeople.list().back().id)))
	await _fits("the book's second page")


# --- The story shelf ---

func test_a_story_is_read_aloud_and_asks_which_skill() -> void:
	await _open("little")
	screen.show_success_place("story_shelf")
	await wait_process_frames(1)
	await _fits("the story shelf")
	(_named("Story_braille") as Button).pressed.emit()
	await wait_process_frames(1)
	var s := SuccessStories.story("braille")
	assert_string_contains(_labels(), str((s.lines as Array)[0]))
	assert_true(voice.said.has(str((s.lines as Array)[0])) or voice.said.any(func(t: String) -> bool:
		return t.contains("Louis")), "read aloud on the Little track")
	await _fits("a story")
	for i in (s.lines as Array).size() - 1:
		await _press("NEXT")
	await _press("NEXT")
	assert_string_contains(_labels(), str(s.question.say))
	await _fits("the story's question")
	var right := _named("Answer0") as Button
	assert_not_null(right)
	right.pressed.emit()
	await wait_process_frames(1)
	assert_true(profile.life.success.story_read("braille"))
	assert_true(bool(profile.life.success.story("braille").a))
	assert_gt(saves, 0)


func test_the_shelf_turns_pages_and_ticks_the_stories_read() -> void:
	profile.life.success.mark_story("curie", DAY, true)
	await _open("big")
	screen.show_success_place("story_shelf")
	await wait_process_frames(1)
	assert_string_contains(_labels(), "1 of 20")
	await _press("NEXT PAGE")
	assert_not_null(_named("Story_curie"))
	assert_not_null(_named("Story_curie").find_child("Read", true, false))


# --- A try, the grown-ups ---

func test_a_finished_connections_try_fills_the_book() -> void:
	await _open("little")
	profile.life.set_skill("connections.little", {"b": 2, "q": 3})   # the before-check was done
	screen.start_experience("connections", "little", false)
	await wait_process_frames(2)
	assert_eq(screen.page, LifeScreen.ROOM)
	var log: Array[Dictionary] = []
	for step in screen.host.run.steps:
		log.append({"id": str(step.id), "kind": str(step.kind), "seconds": 3.0, "hinted": false})
	screen._on_room_finished({"finished": true, "stamps": LifeData.DONE | LifeData.SELF, "hints": 0, "seconds": 300.0,
		"log": log})
	var d := profile.life.success
	for id: String in ["amara", "tomas", "lina"]:
		assert_true(d.met(id), id)
	assert_eq(int(d.person("amara").h), 1, "helped first")
	assert_eq(int(d.person("lina").p), 1, "a promise kept")


func test_a_finished_story_theatre_try_marks_its_stories() -> void:
	await _open("middle")
	profile.life.set_skill("success_stories.middle", {"b": 2, "q": 3})
	screen.start_experience("success_stories", "middle", false)
	await wait_process_frames(2)
	var log: Array[Dictionary] = []
	for step in screen.host.run.steps:
		log.append({"id": str(step.id), "kind": str(step.kind), "seconds": 3.0, "hinted": false})
	screen._on_room_finished({"finished": true, "stamps": LifeData.DONE, "hints": 1, "seconds": 300.0, "log": log})
	for id: String in ["wright", "carver", "nightingale"]:
		assert_true(profile.life.success.story_read(id), id)


func test_the_grown_ups_page_says_the_goal_the_habit_the_people_and_the_stories() -> void:
	var d := profile.life.success
	SuccessGoals.set_goal(d, profile, "moon", "moon_gold", ["learn", "save", "buy"], "after_lesson", "save_10", DAY - 5)
	SuccessHabits.choose(d, "water", DAY - 5)
	SuccessHabits.answer(d, DAY - 4, true)
	SuccessHabits.answer(d, DAY - 1, true)
	SuccessPeople.record(d, [{"meet": ["amara", "lina"]}, {"help": "amara"}], DAY)
	d.mark_story("braille", DAY, true)
	await _open("middle")
	screen.show_grown_ups_page()
	await wait_process_frames(2)
	var words := _labels()
	assert_string_contains(words, "Save the gold for the Moon rocket")
	assert_string_contains(words, "Kept on 2 days")
	assert_string_contains(words, "met 2 people")
	assert_string_contains(words, "read 1 of 20")
	await _fits("the grown-ups' page")
