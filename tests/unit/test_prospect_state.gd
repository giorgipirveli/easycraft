extends GutTest
## Prospecting's saved state (spec §26): a world keeps the quests started there (each waits at its step), the deposits
## found (MY MAP) and its oil wells' drums; the profile keeps the quests done once (their gold paid once), the finds and
## today's finding gold (a cap a day, EarnRules). A broken save gives an empty state; the backup never loses a find.

const GOLD_ID := "gold:1:0"
const OIL_ID := "oil:-1:2"


func test_a_quest_waits_at_its_step_and_finishes_once() -> void:
	var s := ProspectState.new()
	assert_true(s.is_empty())
	assert_false(s.start(DepositKinds.GOLD, "copper:1:0"), "a quest leads to its own kind's deposit")
	assert_false(s.start(&"unobtainium", GOLD_ID))
	assert_true(s.start(DepositKinds.GOLD, GOLD_ID))
	assert_eq(s.active, DepositKinds.GOLD)
	assert_eq(s.step_of(DepositKinds.GOLD), 0)
	assert_eq(s.advance(DepositKinds.GOLD, 0, 7), 1)
	assert_eq(s.advance(DepositKinds.GOLD, 0, 7), 1, "a step done twice moves it on once")
	assert_eq(s.advance(DepositKinds.GOLD, 1, 7), 2)
	assert_true(s.start(DepositKinds.OIL, OIL_ID), "another quest: the gold one waits")
	assert_eq(s.active, DepositKinds.OIL)
	assert_eq(s.step_of(DepositKinds.GOLD), 2, "still at its step")
	assert_true(s.start(DepositKinds.GOLD, "gold:5:5"), "picking it up again")
	assert_eq(s.deposit_of(DepositKinds.GOLD), GOLD_ID, "on its way to the same deposit")
	assert_eq(s.finish(DepositKinds.GOLD), GOLD_ID)
	assert_true(s.is_found(GOLD_ID))
	assert_eq(s.active, &"")
	assert_false(s.has_quest(DepositKinds.GOLD), "it can be told again, for the next deposit")
	assert_eq(s.finish(DepositKinds.GOLD), "", "done once")
	assert_eq(s.found, [GOLD_ID] as Array[String])


func test_an_oil_well_holds_a_few_drums() -> void:
	var s := ProspectState.new()
	s.start(DepositKinds.OIL, OIL_ID)
	assert_eq(s.drums_left(OIL_ID), 0, "no well until the quest marks the dome")
	assert_false(s.pump(OIL_ID))
	s.finish(DepositKinds.OIL)
	assert_eq(s.drums_left(OIL_ID), DepositRules.OIL_DRUMS)
	for i in DepositRules.OIL_DRUMS:
		assert_true(s.pump(OIL_ID))
	assert_false(s.pump(OIL_ID), "a well runs dry: the next quest finds more oil")
	assert_eq(s.drums_left(OIL_ID), 0)


func test_the_world_save_keeps_it_and_refuses_junk() -> void:
	var s := ProspectState.new()
	s.start(DepositKinds.OIL, OIL_ID)
	s.advance(DepositKinds.OIL, 0, 7)
	s.start(DepositKinds.GOLD, GOLD_ID)
	s.finish(DepositKinds.GOLD)
	var back := ProspectState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	assert_eq(back.to_dict(), s.to_dict())
	var meta := WorldMeta.new()
	meta.prospect = s.to_dict()
	var loaded := WorldMeta.from_json(meta.to_json())
	assert_eq(ProspectState.from_dict(loaded.prospect).to_dict(), s.to_dict(), "the world's save keeps it")
	for junk: Variant in [null, 3, "x", [], {"quests": {"gold": {"deposit": "oil:1:1", "step": 2}}},
			{"quests": {"gold": {"deposit": GOLD_ID, "step": -4}}}, {"found": ["nope", 5]}, {"wells": {"gold:1:1": 5}},
			{"active": "gold"}, {"quests": {"gold": {"deposit": GOLD_ID, "step": INF}}}]:
		var j := ProspectState.from_dict(junk)
		assert_true(j.is_empty(), "junk is refused: %s" % str(junk))
	var capped := ProspectState.from_dict({"wells": {OIL_ID: 9999}})
	assert_eq(capped.drums_left(OIL_ID), DepositRules.OIL_DRUMS, "never more than a well holds")


func test_the_first_quest_pays_once_then_finds_pay_a_little_a_day() -> void:
	var p := ProspectData.new()
	const DAY := 20400
	assert_eq(ProspectRewards.finish(p, DepositKinds.GOLD, DAY), EarnRules.PROSPECT_QUEST_GOLD, "the first gold quest")
	assert_eq(ProspectRewards.finish(p, DepositKinds.COPPER, DAY), EarnRules.PROSPECT_QUEST_GOLD, "the first copper quest")
	var paid := 0
	for i in 8:
		paid += ProspectRewards.finish(p, DepositKinds.GOLD, DAY)
	assert_eq(paid, EarnRules.PROSPECT_FIND_DAY_CAP, "finds pay up to the day's cap")
	assert_eq(ProspectRewards.finish(p, DepositKinds.GOLD, DAY + 1), EarnRules.PROSPECT_FIND_GOLD, "a new day")
	assert_eq(ProspectRewards.finish(p, DepositKinds.GOLD, DAY), 0, "a clock turned back never pays a day again")
	assert_eq(p.finds, 12)
	assert_eq(p.done, ["gold", "copper"] as Array[String])
	assert_eq(ProspectRewards.finish(p, &"nothing", DAY + 2), 0)
	assert_string_contains(ProspectRewards.words(100, DepositKinds.OIL, true), "first oil")
	assert_string_contains(ProspectRewards.words(0, DepositKinds.OIL, false), "your map")


func test_the_profile_keeps_it_and_the_backup_never_loses_a_find() -> void:
	var profile := ProfileData.new()
	ProspectRewards.finish(profile.prospect, DepositKinds.SALT, 100)
	var back := ProfileData.from_json(profile.to_json())
	assert_eq(back.prospect.done, ["salt"] as Array[String])
	assert_eq(back.prospect.finds, 1)
	var other := ProspectData.new()
	ProspectRewards.finish(other, DepositKinds.COAL, 100)
	ProspectRewards.finish(other, DepositKinds.COAL, 100)
	back.prospect.merge_from(other)
	assert_eq(back.prospect.done, ["salt", "coal"] as Array[String])
	assert_eq(back.prospect.finds, 2, "the bigger count")
	assert_false(ProfileBackup.is_new(back), "a find is progress")
	for junk: Variant in [null, {"done": ["plutonium", 4], "finds": -3}, {"finds": INF}, {"today": {"d": 1, "g": 9999}}]:
		var j := ProspectData.from_dict(junk)
		assert_true(j.is_empty() and j.today.is_empty(), "junk is refused: %s" % str(junk))


func test_earn_rules_list_the_prospecting_gold() -> void:
	var ids: Array[String] = []
	for row: Dictionary in EarnRules.TABLE:
		ids.append(str(row.id))
	assert_has(ids, "prospect_quest")
	assert_has(ids, "prospect_find")
	assert_lt(EarnRules.PROSPECT_FIND_DAY_CAP, EarnRules.ANSWER_DAY_CAP, "finding pays less a day than learning")
