extends GutTest
## M3 Task 15 (spec §14.9, §5.10): the tutorial with Pip as pure rules — its steps in order (every line with an
## id), where it plays (solo Survivor only), the first-start offer, SKIP never asked again, stopping and going on
## from the same step, SETTINGS' replay, and the reward only once per profile — and the profile's record of it.

const MEADOWS := &"meadows"


func _here(mode: StringName = ModeRules.SURVIVOR, net: StringName = &"solo", online := false,
		game: StringName = SurvivorGames.CLASSIC, universe: StringName = MEADOWS) -> bool:
	return TutorialRules.plays_here(mode, net, online, game, universe)


# --- The steps ---

func test_the_steps_come_in_the_briefs_order_without_the_totem() -> void:
	assert_eq(TutorialRules.step_ids(), [&"move", &"jump", &"bridge", &"wall", &"hide", &"craft", &"tilly"] as Array[StringName])
	assert_eq(TutorialRules.count(), 7)
	assert_false(TutorialRules.step_ids().has(&"totem"), "owner #44: Survivor has no Totem waves")


func test_every_step_has_a_line_id_a_picture_and_short_words() -> void:
	var ids := {}
	for i in TutorialRules.count():
		var line := TutorialRules.line_id(i)
		assert_true(String(line).begins_with("tutorial_"), "step %d's line id: %s" % [i, line])
		assert_false(ids.has(line), "line ids are unique")
		ids[line] = true
		var pic := TutorialRules.picture(i)
		assert_eq(pic.size(), 2, "a picture: [kind, what]")
		assert_true(pic[0] in [&"hud", &"block"], "step %d's picture kind" % i)
		if pic[0] == &"hud":
			assert_true(HudIcons.knows(pic[1]), "step %d's HUD picture draws" % i)
		else:
			assert_true(BlockIds.is_valid(int(pic[1])) or ItemIds.is_item(int(pic[1])), "step %d's block picture" % i)
		var words := TutorialRules.words(i)
		assert_ne(words, "")
		assert_lt(words.split(" ").size(), 12, "very short words: %s" % words)


func test_every_line_of_the_tutorial_has_an_id() -> void:
	var lines := TutorialRules.LINES
	for id: StringName in lines:
		assert_true(String(id).begins_with("tutorial_"), str(id))
		assert_ne(str(lines[id]), "")
	for i in TutorialRules.count():
		assert_eq(TutorialRules.words(i), str(lines[TutorialRules.line_id(i)]), "a step's words are its line")


# --- Where it plays: solo Survivor only ---

func test_it_plays_only_in_a_solo_classic_survivor_world() -> void:
	assert_true(_here())
	assert_false(_here(ModeRules.SANDBOX), "never in Sandbox")
	assert_false(_here(ModeRules.WAVE), "never in Monster Wave")
	assert_false(_here(ModeRules.SURVIVOR, &"host"), "never when hosting a LAN game")
	assert_false(_here(ModeRules.SURVIVOR, &"client"), "never as a LAN guest")
	assert_false(_here(ModeRules.SURVIVOR, &"solo", true), "never online")
	assert_false(_here(ModeRules.SURVIVOR, &"solo", false, SurvivorGames.BUILD), "not in Build to Survive: night comes fast")
	for u: StringName in [&"desert", &"frost", &"candy"]:
		assert_true(_here(ModeRules.SURVIVOR, &"solo", false, SurvivorGames.CLASSIC, u), str(u))
	assert_false(_here(ModeRules.SURVIVOR, &"solo", false, SurvivorGames.CLASSIC, &"dragon"), "no ground to lay out on")


# --- The offer, skipping, stopping and going on ---

func test_the_first_survivor_start_offers_it() -> void:
	var t := TutorialData.new()
	assert_true(TutorialRules.wants_offer(t, true))
	assert_false(TutorialRules.wants_offer(t, false), "only where it plays")
	assert_false(TutorialRules.starts_now(t, true), "the child chooses first")
	assert_true(TutorialRules.holds_tip(t, true), "the shop tip waits for the offer")


func test_skip_gives_nothing_and_is_never_asked_again() -> void:
	var t := TutorialData.new()
	TutorialRules.skip(t)
	assert_eq(t.state, TutorialData.SKIPPED)
	assert_false(t.rewarded, "no reward")
	assert_false(TutorialRules.wants_offer(t, true), "never asked again")
	assert_false(TutorialRules.holds_tip(t, true))
	var again := TutorialData.from_dict(t.to_dict())
	assert_false(TutorialRules.wants_offer(again, true), "not even after a restart")


func test_a_stopped_tutorial_goes_on_from_the_step_it_stopped_at() -> void:
	var t := TutorialData.new()
	assert_eq(TutorialRules.begin(t), 0)
	assert_eq(t.state, TutorialData.STARTED)
	TutorialRules.advance(t, 0)
	TutorialRules.advance(t, 1)
	TutorialRules.advance(t, 2)
	assert_eq(t.step, 3, "three steps done")
	var saved := TutorialData.from_dict(t.to_dict())   # stopped (the X) or the game closed
	assert_true(TutorialRules.wants_offer(saved, true), "offered again next time")
	assert_true(TutorialRules.is_resume(saved))
	assert_eq(TutorialRules.begin(saved), 3, "it goes on at the wall")


func test_skipping_after_a_stop_is_never_asked_again_either() -> void:
	var t := TutorialData.new()
	TutorialRules.begin(t)
	TutorialRules.advance(t, 0)
	TutorialRules.skip(t)
	assert_false(TutorialRules.wants_offer(t, true))


func test_the_reward_comes_only_once() -> void:
	var t := TutorialData.new()
	TutorialRules.begin(t)
	for i in TutorialRules.count():
		TutorialRules.advance(t, i)
	assert_true(TutorialRules.finish(t), "the first finish rewards")
	assert_eq(t.state, TutorialData.DONE)
	assert_false(TutorialRules.wants_offer(t, true), "done: never offered again")
	TutorialRules.ask_replay(t)
	assert_true(TutorialRules.starts_now(t, true), "SETTINGS plays it again")
	assert_eq(TutorialRules.begin(t), 0, "a replay starts at the beginning")
	assert_false(t.replay, "asked once")
	assert_false(TutorialRules.finish(t), "no second reward")
	assert_eq(t.state, TutorialData.DONE)


func test_a_child_who_skipped_can_play_it_from_settings_and_earn_it_once() -> void:
	var t := TutorialData.new()
	TutorialRules.skip(t)
	TutorialRules.ask_replay(t)
	assert_true(TutorialRules.starts_now(t, true))
	assert_false(TutorialRules.starts_now(t, false), "waits for a solo Survivor game")
	assert_eq(TutorialRules.begin(t), 0)
	assert_eq(t.state, TutorialData.SKIPPED, "a replay never makes it offered again")
	assert_true(TutorialRules.finish(t), "finishing is what earns it")
	assert_false(TutorialRules.finish(t))


func test_a_replay_that_stops_does_not_come_back_as_an_offer() -> void:
	var t := TutorialData.new()
	TutorialRules.skip(t)
	TutorialRules.ask_replay(t)
	TutorialRules.begin(t)
	TutorialRules.advance(t, 0)
	assert_false(TutorialRules.wants_offer(t, true))
	assert_eq(TutorialRules.begin(t), 0, "SETTINGS again: from the start")


func test_the_reward() -> void:
	assert_eq(TutorialRules.REWARD_GOLD, 500)
	assert_eq(TutorialRules.EARN, AvatarCatalog.EARN_TUTORIAL)
	var hats := []
	for id: String in AvatarCatalog.ITEMS:
		if AvatarCatalog.ITEMS[id].get("earn", &"") == TutorialRules.EARN:
			hats.append(id)
	assert_eq(hats, ["hat.pip_cap"], "the free hat")


# --- The profile's record ---

func test_the_record_round_trips_and_reads_anything_safely() -> void:
	var t := TutorialData.new()
	assert_true(t.is_empty())
	t.state = TutorialData.STARTED
	t.step = 4
	t.replay = true
	var back := TutorialData.from_dict(t.to_dict())
	assert_eq(back.state, TutorialData.STARTED)
	assert_eq(back.step, 4)
	assert_true(back.replay)
	assert_false(back.is_empty())
	for bad: Variant in [null, 3, "x", [], {"state": "sleeping", "step": "a", "rewarded": "yes"}, {"step": 99}, {"step": -3}]:
		var d := TutorialData.from_dict(bad)
		assert_true(d.state in TutorialData.STATES, str(bad))
		assert_between(d.step, 0, TutorialRules.count() - 1, str(bad))
		assert_false(d.rewarded, str(bad))


func test_the_backup_merge_never_loses_a_reward_or_a_skip() -> void:
	var mine := TutorialData.new()
	mine.state = TutorialData.STARTED
	mine.step = 2
	var theirs := TutorialData.new()
	theirs.state = TutorialData.DONE
	theirs.rewarded = true
	mine.merge_from(theirs)
	assert_eq(mine.state, TutorialData.DONE)
	assert_true(mine.rewarded, "a reward is never paid twice")
	var a := TutorialData.new()
	var b := TutorialData.new()
	b.state = TutorialData.SKIPPED
	a.merge_from(b)
	assert_eq(a.state, TutorialData.SKIPPED, "a skip is never asked again on another phone")
	var c := TutorialData.new()
	c.state = TutorialData.STARTED
	c.step = 1
	var d := TutorialData.new()
	d.state = TutorialData.STARTED
	d.step = 5
	c.merge_from(d)
	assert_eq(c.step, 5, "the furthest step")


func test_the_profile_keeps_it_and_the_backup_merges_it() -> void:
	var p := ProfileData.new()
	TutorialRules.skip(p.tutorial)
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.tutorial.state, TutorialData.SKIPPED)
	var old := ProfileData.new()
	old.tutorial.rewarded = true
	old.tutorial.state = TutorialData.DONE
	var merged: ProfileData = ProfileBackup.merge(ProfileData.new(), ProfileBackup.to_backup(old)).profile
	assert_true(merged.tutorial.rewarded)
