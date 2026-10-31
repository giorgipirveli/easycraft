extends GutTest
## Owner #115 (docs/design/success-skills.md §2, §3; the S2 brief): Success S2's four Life Experiences as data. They are
## Life's (the Passport's stamps, the before-and-after checks, Try it for real, every Life rule on every track), their
## data in data/success, their rooms Success's; each try varies a little; the guardrails hold in their words (never
## gambling, no real money, no pressure tricks except the one the Big track teaches to spot, honesty rewarded, success
## means many things); the brief's conversations, people and plans are there on the right tracks.

const IDS: Array[String] = ["goal_board", "talk_deal", "connections", "success_stories"]
const GAMBLING: Array[String] = ["bet", "bets", "gamble", "gambling", "lottery", "jackpot", "spin", "casino", "loot box",
	"prize draw", "odds"]


func _steps(id: String, track: String, expert: bool = false, seed: int = 1) -> Array[Dictionary]:
	return LifeExperience.steps(id, track, expert, seed, "ge")


func _step(id: String, track: String, step_id: String, expert: bool = false) -> Dictionary:
	for s in _steps(id, track, expert):
		if str(s.id) == step_id:
			return s
	return {}


func _all_words(id: String) -> String:
	return JSON.stringify(LifeExperience.data(id)).to_lower()


func test_the_four_are_life_experiences_with_success_data_and_rooms() -> void:
	assert_eq(SuccessExperiences.IDS, IDS + (["my_shop", "market_square"] as Array[String]),
		"S2's four, then S3's two (owner #115 (S3): test_success_s3_experiences.gd holds those)")
	for id in IDS:
		assert_has(LifeExperience.IDS, id)
		assert_false(LifeExperience.data(id).is_empty(), id)
		assert_eq(LifeExperience.problems(id), [] as Array[String], id)
		var area := str(LifeExperience.data(id).area)
		assert_eq(str(LifeCatalog.area(area).strand), "success", id + ": in the Success strand")
		for track in LifeData.TRACKS:
			var room := LifeRooms.make(str(LifeExperience.data(id).room), track)
			assert_true(SuccessExperiences.ROOMS.has(str(LifeExperience.data(id).room)), id)
			assert_ne(room.get_script(), LifeRoom, "%s.%s: its own room" % [id, track])
			assert_false(LifeCatalog.experience_unit(id, track).is_empty(), "%s.%s has its unit" % [id, track])
			room.free()


func test_each_try_varies_a_little() -> void:
	var seen := {}
	for seed in 30:
		var v := SuccessExperiences.vars("talk_deal", "little", seed)
		seen[str(v.gripe)] = true
		assert_ne(str(v.gripe_back), "")
	assert_eq(seen.size(), SuccessExperiences.GRIPES.size(), "Mo's complaint changes from try to try")
	var said := str(_step("talk_deal", "little", "mo_says").say)
	assert_false(said.contains("{"), said)


func test_the_rocket_goal_is_mission_controls_real_plan() -> void:
	var moon := {}
	for m in MissionRules.MISSIONS:
		if str(m.id) == "moon":
			moon = m
	assert_gt(SuccessExperiences.moon_gold(), 0)
	assert_eq(SuccessExperiences.moon_gold(), RocketPlan.gold(moon, 1))
	var words := JSON.stringify(_step("goal_board", "middle", "goal").choices)
	assert_string_contains(words, str(SuccessExperiences.moon_gold()))


func test_never_gambling_and_no_real_money() -> void:
	for id in IDS:
		var words := _all_words(id)
		for w in GAMBLING:
			assert_null(RegEx.create_from_string("\\b" + w + "\\b").search(words), "%s: %s" % [id, w])
		assert_false(words.contains("real money") and not words.contains("count real money with a grown-up"), id)


func test_the_only_pressure_trick_is_the_one_taught_to_spot() -> void:
	var found := 0
	for id in IDS:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for s in _steps(id, track, expert):
					var said := str(s.say).to_lower()
					if said.contains("now, or") or said.contains("gone for ever") or said.contains("only today"):
						found += 1
						assert_eq([id, track, expert], ["talk_deal", "big", true], "only the Big Expert try's lesson")
						assert_string_contains(JSON.stringify(s.choices[s.answer]).to_lower(), "grown-up")
	assert_eq(found, 1)


func test_listen_say_sorry_fix_it_on_the_little_track() -> void:
	var ids := _steps("talk_deal", "little").map(func(s: Dictionary) -> String: return str(s.id))
	for want: String in ["listen", "say_back", "sorry", "fix", "thanks", "robo_red", "turn"]:
		assert_has(ids, want)
	assert_lt(ids.find("listen"), ids.find("sorry"), "listen first")
	assert_lt(ids.find("sorry"), ids.find("fix"), "then sorry, then fix it")
	assert_eq(str(_step("talk_deal", "little", "fix").target), "bread")


func test_robo_does_exactly_what_was_said() -> void:
	for track: String in ["little", "middle"]:
		for expert: bool in [false, true]:
			for s in _steps("talk_deal", track, expert):
				if str(s.id).begins_with("robo_") and str(s.kind) == "choose":
					assert_eq(str(s.get("on_miss", "")), "robo_muddle", "%s %s: a muddled order, a muddled Robo" % [track, s.id])
					for i in (s.choices as Array).size():
						if i != int(s.answer):
							assert_string_contains(str(s.choices[i].why), "Robo", "%s %s: says what Robo did" % [track, s.id])


func test_a_win_win_deal_and_a_kept_promise_on_the_middle_track() -> void:
	assert_eq(str(_step("talk_deal", "middle", "shake").kind), "hold")
	assert_eq(str(_step("talk_deal", "middle", "shake").motion), "squeeze", "a handshake squeezes")
	assert_eq(str(_step("talk_deal", "middle", "deliver").book.promise), "ana")
	assert_false(_step("talk_deal", "middle", "offer_half", true).is_empty(), "the Expert try: half a crate")


func test_the_pitch_has_its_four_parts_in_order_and_a_polite_no() -> void:
	var order := _step("talk_deal", "big", "order")
	assert_eq(order.targets, ["card_problem", "card_idea", "card_why", "card_need"])
	assert_eq(str(order.device), "tablet")
	assert_false(_step("talk_deal", "big", "walk_away").is_empty())
	assert_false(_step("talk_deal", "big", "feedback_in").is_empty(), "taking feedback")
	assert_false(_step("talk_deal", "big", "feedback_out").is_empty(), "giving feedback")
	assert_eq(_step("talk_deal", "big", "eyes").targets, ["diaz", "ade", "kowalski"], "looking at each investor")


func test_the_goal_board_has_goals_steps_if_then_plans_and_a_gentle_habit() -> void:
	var little := _steps("goal_board", "little").map(func(s: Dictionary) -> String: return str(s.id))
	for want: String in ["goal", "build", "fall", "again", "save", "jar", "water", "forgot"]:
		assert_has(little, want)
	var plan := _step("goal_board", "middle", "plan")
	assert_string_contains(str(plan.choices[plan.answer].text), "When I finish a lesson")
	assert_eq(_step("goal_board", "big", "woop").targets, ["card_wish", "card_outcome", "card_obstacle", "card_plan"])
	var words := _all_words("goal_board")
	assert_false(words.contains("streak"), "never a streak")
	assert_false(words.contains("in a row"), "days kept, never days in a row")


func test_the_connections_book_steps_name_only_its_people() -> void:
	for track in LifeData.TRACKS:
		for expert: bool in [false, true]:
			for s in _steps("connections", track, expert) + _steps("talk_deal", track, expert):
				var book: Variant = s.get("book")
				if book == null:
					continue
				var entries: Array = book if book is Array else [book]
				for e: Dictionary in entries:
					for kind: String in e:
						assert_has(SuccessPeople.ACTIONS, kind)
						var who: Array = e[kind] if e[kind] is Array else [e[kind]]
						for id: Variant in who:
							assert_true(SuccessPeople.has(str(id)), "%s %s: %s" % [track, s.id, id])


func test_help_first_promises_introductions_mentors_and_people_different_from_you() -> void:
	var kinds := {}
	for track in LifeData.TRACKS:
		for s in _steps("connections", track):
			var book: Variant = s.get("book")
			if book == null:
				continue
			for e: Dictionary in (book if book is Array else [book]):
				for kind: String in e:
					kinds["%s.%s" % [track, kind]] = true
	for want: String in ["little.meet", "little.help", "little.promise", "middle.intro", "middle.promise", "middle.mentor",
			"big.intro", "big.mentor"]:
		assert_true(kinds.has(want), want)
	assert_false(_step("connections", "middle", "signs").is_empty(), "Sam signs: people different from you")
	assert_false(_step("connections", "big", "different").is_empty(), "Kenji is 80")
	assert_eq(str(_step("connections", "big", "online").device), "phone", "connections online, done safely")


func test_the_story_theatre_acts_real_stories_and_asks_which_skill() -> void:
	for track in LifeData.TRACKS:
		var stories := 0
		var skills := 0
		for s in _steps("success_stories", track):
			if s.has("story"):
				stories += 1
				assert_false(SuccessStories.story(str(s.story)).is_empty(), "%s %s: %s" % [track, s.id, s.story])
			if str(s.kind) == "choose" and str(s.say).to_lower().contains("which skill"):
				skills += 1
		assert_gte(stories, 3, track + ": three stories")
		assert_gte(skills, 3, track + ": 'Which skill did they use?'")


func test_the_success_units_meet_the_schools_bar_and_try_their_experience() -> void:
	for u in LifeCatalog.all_units():
		if not str(u.id).begins_with("life.") or not ["goals", "talk", "connections", "stories"].has(str(u.area)):
			continue
		assert_has(IDS, str(u.experience), str(u.id))
		assert_false(LifeCatalog.content(str(u.id)).is_empty(), str(u.id))
