extends GutTest
## Owner #115 (docs/design/success-skills.md §2.6, [S7]; the brief: "a dream → a goal → steps → if-then plans ... tied to
## the child's real goals in the game (the rocket, a universe, a build)"): the Goal Board's rules. A dream from pictures,
## a goal you can check, steps in the child's order, an if-then plan ("When I finish a lesson, I put 10 gold aside for
## my goal."), on the Big track an obstacle plan too. Where the game can measure the goal it does (the rocket's gold,
## a flight, a universe opened, School lessons mastered, Life stamps by myself); otherwise the child ticks the steps.
## Reaching it is celebrated once and counted.

const DAY := 20_000

var d: SuccessData
var p: ProfileData


func before_each() -> void:
	d = SuccessData.new()
	p = ProfileData.new()


func _moon() -> Dictionary:
	for m in MissionRules.MISSIONS:
		if str(m.id) == "moon":
			return m
	return {}


func test_every_dream_has_goals_steps_and_pictures() -> void:
	var dreams := SuccessGoals.dreams()
	assert_gte(dreams.size(), 6)
	var ids: Array[String] = []
	for dream in dreams:
		ids.append(str(dream.id))
		assert_true(SuccessData.valid_id(dream.id), str(dream.id))
		assert_ne(str(dream.get("title", "")), "")
		assert_ne(str(dream.get("icon", "")), "")
		assert_gte((dream.goals as Array).size(), 1, str(dream.id))
		assert_gte((dream.steps as Array).size(), 4, str(dream.id))
		for g: Dictionary in dream.goals:
			assert_has(SuccessGoals.MEASURES, str(g.get("measure", "")), str(g))
		for s: Dictionary in dream.steps:
			assert_ne(str(s.get("title", "")), "", str(s))
	for want: String in ["moon", "universe", "build", "learn", "life", "own"]:
		assert_has(ids, want, "the game's own goals: the rocket, a universe, a build (and real life)")
	for list: String in ["cues", "actions", "obstacles", "responses"]:
		assert_gte(SuccessGoals.parts(list).size(), 4, list)


func test_setting_a_goal_keeps_the_childs_choices() -> void:
	assert_true(SuccessGoals.set_goal(d, p, "moon", "moon_gold", ["learn", "save", "buy"], "after_lesson", "save_10", DAY))
	assert_eq(str(d.goal.d), "moon")
	assert_eq(d.goal.s, ["learn", "save", "buy"])
	assert_eq(int(d.goal.c), DAY)
	assert_eq(SuccessGoals.plan_words(d), "When I finish a lesson, I put 10 gold aside for my goal.")
	assert_eq(SuccessGoals.obstacle_words(d), "")
	assert_true(SuccessGoals.set_obstacle(d, "friends", "after_step"))
	assert_eq(SuccessGoals.obstacle_words(d), "If my friends ask me to play, then I play after my step.")


func test_a_goal_from_unknown_parts_is_refused() -> void:
	assert_false(SuccessGoals.set_goal(d, p, "pony", "moon_gold", ["learn"], "after_lesson", "save_10", DAY))
	assert_false(SuccessGoals.set_goal(d, p, "moon", "master_3", ["learn"], "after_lesson", "save_10", DAY),
		"the goal must be the dream's")
	assert_false(SuccessGoals.set_goal(d, p, "moon", "moon_gold", ["fly_away"], "after_lesson", "save_10", DAY))
	assert_false(SuccessGoals.set_goal(d, p, "moon", "moon_gold", ["learn"], "sometime", "save_10", DAY))
	assert_true(d.goal.is_empty())


func test_steps_tick_and_untick() -> void:
	SuccessGoals.set_goal(d, p, "build", "house", ["draw", "collect", "walls"], "saturday", "build_10", DAY)
	SuccessGoals.tick(d, 1)
	assert_true(SuccessGoals.ticked(d, 1))
	assert_false(SuccessGoals.ticked(d, 0))
	SuccessGoals.tick(d, 1)
	assert_false(SuccessGoals.ticked(d, 1))


func test_the_rocket_goal_reads_the_childs_real_gold_and_mission_controls_plan() -> void:
	SuccessGoals.set_goal(d, p, "moon", "moon_gold", ["learn", "save", "buy"], "after_lesson", "save_10", DAY)
	var need := RocketPlan.gold(_moon(), 1)
	assert_gt(need, 0)
	p.survivor_gold = 100
	var pr := SuccessGoals.progress(d, p)
	assert_eq(int(pr.need), need)
	assert_eq(int(pr.have), 100)
	assert_false(bool(pr.reached))
	assert_string_contains(str(pr.words), str(need))
	p.survivor_gold = need + 5
	assert_true(bool(SuccessGoals.progress(d, p).reached))


func test_the_flight_goal_is_reached_by_flying_there() -> void:
	SuccessGoals.set_goal(d, p, "moon", "moon_fly", ["learn", "buy", "build"], "after_lesson", "save_10", DAY)
	assert_false(bool(SuccessGoals.progress(d, p).reached))
	p.missions.fly(int(_moon().world))
	assert_true(bool(SuccessGoals.progress(d, p).reached))


func test_the_universe_goal_is_the_next_one() -> void:
	p.universe_unlocked = 2
	SuccessGoals.set_goal(d, p, "universe", "next_universe", ["collect", "tools", "golem"], "open_game", "one_step", DAY)
	var pr := SuccessGoals.progress(d, p)
	assert_eq(int(pr.need), 3)
	assert_string_contains(str(pr.words), UniverseRegistry.LADDER[2].display_name)
	p.universe_unlocked = 3
	assert_true(bool(SuccessGoals.progress(d, p).reached))


func test_learning_goals_count_from_the_day_they_were_set() -> void:
	p.school.set_progress("g4.maths.big_numbers", {"s": 2, "r": 1})
	SuccessGoals.set_goal(d, p, "learn", "master_3", ["subject", "lesson", "practise"], "after_dinner", "one_round", DAY)
	assert_eq(int(SuccessGoals.progress(d, p).have), 0, "a unit mastered before the goal doesn't count")
	p.school.set_progress("g4.maths.compare_round", {"s": 2, "r": 1})
	p.life.set_unit("life.safe.call_for_help", {"s": 3, "r": 2})
	assert_eq(int(SuccessGoals.progress(d, p).have), 2)
	p.school.set_progress("g4.maths.add_subtract", {"s": 2, "r": 1})
	assert_true(bool(SuccessGoals.progress(d, p).reached))


func test_life_goals_count_by_myself_stamps_since_the_goal() -> void:
	SuccessGoals.set_goal(d, p, "life", "self_2", ["skill", "coach", "again"], "after_dinner", "one_step", DAY)
	p.life.set_skill("kitchen.little", {"s": LifeData.DONE | LifeData.SELF, "r": 1})
	assert_eq(int(SuccessGoals.progress(d, p).have), 1)
	p.life.set_skill("calm_corner.little", {"s": LifeData.DONE | LifeData.SELF, "r": 1})
	assert_true(bool(SuccessGoals.progress(d, p).reached))


func test_a_goal_the_game_cant_measure_is_the_childs_steps() -> void:
	SuccessGoals.set_goal(d, p, "build", "house", ["draw", "collect", "walls"], "saturday", "build_10", DAY)
	assert_eq(int(SuccessGoals.progress(d, p).need), 3)
	for i in 3:
		SuccessGoals.tick(d, i)
	assert_true(bool(SuccessGoals.progress(d, p).reached))


func test_reaching_a_goal_is_counted_once() -> void:
	SuccessGoals.set_goal(d, p, "build", "house", ["draw", "collect", "walls"], "saturday", "build_10", DAY)
	for i in 3:
		SuccessGoals.tick(d, i)
	assert_true(SuccessGoals.check_reached(d, p, DAY + 4), "the first time: celebrate")
	assert_false(SuccessGoals.check_reached(d, p, DAY + 5), "only once")
	assert_eq(d.goals_reached, 1)
	assert_eq(int(d.goal.x), DAY + 4)
	SuccessGoals.tick(d, 0)
	assert_eq(int(d.goal.x), DAY + 4, "a reached goal stays reached")


func test_the_grown_ups_line_says_the_goal_and_the_plan() -> void:
	assert_eq(SuccessGoals.grown_ups_line(d, p), "")
	SuccessGoals.set_goal(d, p, "moon", "moon_gold", ["learn", "save", "buy"], "after_lesson", "save_10", DAY)
	SuccessGoals.tick(d, 0)
	var line := SuccessGoals.grown_ups_line(d, p)
	assert_string_contains(line, "Save the gold for the Moon rocket")
	assert_string_contains(line, "When I finish a lesson")
	assert_string_contains(line, "1 of 3 steps")
	assert_string_contains(line, SchoolClock.short_date(DAY))
