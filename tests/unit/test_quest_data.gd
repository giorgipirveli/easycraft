extends GutTest
## Owner #45a (spec §14.17): a child's quests live in the profile's progress (ProgressData.quests) and the
## counts per universe next to the account-wide ones. Saved field by field, a chain in the middle comes back
## exactly where it was, nothing in it has a date, and the server backup keeps the best of both copies.


func test_counts_per_universe_sit_next_to_the_account_wide_ones() -> void:
	var d := ProgressData.new()
	d.record(&"secret_found/temple", 1, 2)
	d.record(&"secret_found/temple", 1, 1)
	d.record(&"secret_found/geode", 2, 2)
	assert_eq(d.count(&"secret_found/temple"), 2, "account-wide")
	assert_eq(d.count_in(&"secret_found/temple", 2), 1, "in the desert")
	assert_eq(d.count_in(&"secret_found", 2), 3, "a detail counts its family in its universe too")
	assert_eq(d.count_in(&"secret_found/temple", 3), 0)
	assert_eq(d.count_in(&"secret_found/temple", 0), 2, "universe 0: anywhere")
	d.record(&"photo_taken")
	assert_eq(d.count_in(&"photo_taken", 1), 0, "an event with no universe counts only account-wide")
	assert_eq(d.xp, 25 * 4 + 5, "XP as before: the universe adds no XP")


## The server backup takes 60 KB of profile: the counts per universe stay small whatever happens.
func test_the_counts_per_universe_stay_small() -> void:
	var d := ProgressData.new()
	for u in range(1, 12):
		for i in 100:
			d.record(StringName("monster_defeated/m%d" % i), 1, u)
	assert_eq(d.u_counts.size(), ProgressData.MAX_UNIVERSES)
	for u: String in d.u_counts:
		assert_lte((d.u_counts[u] as Dictionary).size(), ProgressData.MAX_U_KINDS)
	for c: Dictionary in QuestRules.CHAINS:
		d.quests.done.append(String(c.id))
		d.quests.places.append({"chain": String(c.id), "u": 1, "seed": 123456789, "x": -12345.5, "y": 64.0, "z": 98765.5})
	assert_lt(JSON.stringify(d.to_dict()).length(), ProfileBackup.MAX_CHARS / 2, "the whole progress fits the backup easily")


func test_a_chain_in_the_middle_survives_a_save_and_load() -> void:
	var d := ProgressData.new()
	QuestRules.start(d, &"zara_scarab")
	d.record(&"secret_found/treasure", 1, 2)
	QuestRules.check(d)
	QuestRules.start(d, &"tilly_pets")   # the desert story waits where it was
	d.record(&"animal_tamed/cat", 1, 1)
	QuestRules.check(d)
	d.record(&"monster_defeated/slime", 1, 1)
	d.quests.done.append("tilly_map")
	d.quests.places.append({"chain": "tilly_map", "u": 1, "seed": 42, "x": 1.5, "y": 30.0, "z": -7.5})
	var e := ProgressData.from_dict(JSON.parse_string(JSON.stringify(d.to_dict())))
	assert_eq(e.quests.active, &"tilly_pets")
	assert_eq(QuestRules.step_index(e, &"tilly_pets"), 1)
	assert_eq(QuestRules.step_progress(e, &"tilly_pets"), Vector2i(1, 3), "the slime beaten before the save")
	assert_eq(QuestRules.step_index(e, &"zara_scarab"), 1, "the waiting story too")
	assert_eq(e.quests.done, ["tilly_map"] as Array[String])
	assert_eq(e.quests.places.size(), 1)
	assert_eq(e.count_in(&"monster_defeated/slime", 1), 1)
	e.record(&"monster_defeated/slime", 2, 1)
	assert_eq(QuestRules.check(e).size(), 1, "and it goes on after the load")


func test_bad_quest_data_falls_back_field_by_field() -> void:
	var e := ProgressData.from_dict({"quests": {"active": "no_such_chain",
		"chains": {"tilly_map": {"step": 99, "start": "x", "extra": -3}, "made_up": {"step": 0}, "zara_scarab": "junk",
			"tilly_pets": {"step": 1, "start": 4, "extra": 2}},
		"done": ["bram_lantern", 7, "bram_lantern", "nope"], "places": [{"chain": "bram_lantern", "u": 3, "seed": 5,
			"x": 1, "y": 2, "z": 3}, {"chain": "nope"}, "junk", {"chain": "tilly_map", "u": 1, "seed": 1, "x": NAN, "y": 0, "z": 0}]},
		"u_counts": {"2": {"secret_found/temple": 3, "cheat": 9}, "x": {"photo_taken": 1}, "3": "junk", "0": {"photo_taken": 1}}})
	assert_eq(e.quests.active, &"", "an unknown chain is not followed")
	assert_false(e.quests.chains.has("made_up"))
	assert_false(e.quests.chains.has("zara_scarab"))
	assert_eq(int(e.quests.chains["tilly_map"].step), (QuestRules.chain(&"tilly_map").steps as Array).size(),
		"a step past the end: every step done, the rewards wait")
	assert_eq(int(e.quests.chains["tilly_map"].start), -1, "a bad start waits to be counted again")
	assert_eq(int(e.quests.chains["tilly_map"].extra), 0)
	assert_eq(e.quests.chains["tilly_pets"], {"step": 1, "start": 4, "extra": 2})
	assert_eq(e.quests.done, ["bram_lantern"] as Array[String])
	assert_eq(e.quests.places.size(), 1, "only whole places of known chains")
	assert_eq(e.u_counts, {"2": {"secret_found/temple": 3}})


func test_a_done_chain_is_never_also_waiting() -> void:
	var e := ProgressData.from_dict({"quests": {"active": "tilly_map", "chains": {"tilly_map": {"step": 1, "start": 0,
		"extra": 0}}, "done": ["tilly_map"]}})
	assert_eq(e.quests.active, &"")
	assert_false(e.quests.chains.has("tilly_map"))


func test_old_progress_without_quests_starts_them_fresh() -> void:
	var e := ProgressData.from_dict({"xp": 120, "counts": {"photo_taken": 2}})
	assert_eq(e.quests.active, &"")
	assert_true(e.quests.chains.is_empty())
	assert_true(e.quests.done.is_empty())
	assert_true(e.u_counts.is_empty())
	assert_eq(e.xp, 120)


## Never expiring: no date, time or day in a saved quest (a phone a year ahead changes nothing).
func test_nothing_in_a_saved_quest_has_a_date_or_a_timer() -> void:
	var d := ProgressData.new()
	QuestRules.start(d, &"mimi_cupcake")
	d.record(&"monster_defeated/gummy", 2, 4)
	d.quests.done.append("tilly_map")
	d.quests.places.append({"chain": "tilly_map", "u": 1, "seed": 42, "x": 1.0, "y": 2.0, "z": 3.0})
	var saved := JSON.stringify(d.to_dict()).to_lower()
	for key in ["time", "date", "day", "expire", "deadline", "streak", "last_login", "reset", "clock"]:
		assert_false(saved.contains(key), "no '%s' in the saved progress" % key)


func test_a_profile_with_a_finished_story_is_not_new() -> void:
	var p := ProfileData.new()
	assert_true(ProfileBackup.is_new(p))
	p.progress.quests.done.append("tilly_map")
	assert_false(ProfileBackup.is_new(p))


## The server backup (M4 F): the best of both copies — every story done, every place, the counts per universe.
func test_the_backup_merge_keeps_every_story_and_place() -> void:
	var local := ProgressData.new()
	local.quests.done.append("tilly_map")
	local.quests.places.append({"chain": "tilly_map", "u": 1, "seed": 1, "x": 1.0, "y": 2.0, "z": 3.0})
	local.record(&"monster_defeated/yeti", 2, 3)
	QuestRules.start(local, &"tilly_pets")
	var other := ProgressData.new()
	other.quests.done.append("zara_scarab")
	other.quests.places.append({"chain": "zara_scarab", "u": 2, "seed": 9, "x": 4.0, "y": 5.0, "z": 6.0})
	other.record(&"monster_defeated/yeti", 5, 3)
	QuestRules.start(other, &"bram_lantern")
	local.merge_from(other)
	assert_has(local.quests.done, "tilly_map")
	assert_has(local.quests.done, "zara_scarab")
	assert_eq(local.quests.places.size(), 2)
	assert_eq(local.count_in(&"monster_defeated/yeti", 3), 5, "the best count per universe")
	assert_eq(local.quests.active, &"tilly_pets", "the story being followed stays this copy's")
	local.merge_from(other)
	assert_eq(local.quests.places.size(), 2, "a place once")
