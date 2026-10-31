extends GutTest
## Owner #117 (docs/design/life-skills.md §13, "The Tool Book"; §11): every tool a child has used has three stamps (Done
## it, By myself, Expert, like the Life Passport), kept in the profile (ProfileData.tools) so the existing backup carries
## them; a backup's merge never loses one. "You can use 23 tools" counts the tools used by themselves.


func test_a_new_tool_book_is_empty() -> void:
	var d := ToolData.new()
	assert_true(d.is_empty())
	assert_eq(d.can_use(), 0)


func test_a_finished_run_stamps_the_tools_it_used() -> void:
	var d := ToolData.new()
	var got := d.record([{"tool": "trowel", "hinted": false}, {"tool": "saw", "hinted": true}], false)
	assert_eq(d.stamps_of("trowel"), LifeData.DONE | LifeData.SELF, "used well with no hint: by myself")
	assert_eq(d.stamps_of("saw"), LifeData.DONE, "the coach helped: done it")
	assert_eq(int(got.trowel), LifeData.DONE | LifeData.SELF, "what is new this time")
	assert_eq(d.uses_of("trowel"), 1)


func test_a_tool_used_twice_in_a_run_needs_both_without_a_hint() -> void:
	var d := ToolData.new()
	d.record([{"tool": "trowel", "hinted": false}, {"tool": "trowel", "hinted": true}], false)
	assert_eq(d.stamps_of("trowel"), LifeData.DONE)
	assert_eq(d.uses_of("trowel"), 2)


func test_the_expert_try_with_no_hint_is_expert() -> void:
	var d := ToolData.new()
	d.record([{"tool": "spirit_level", "hinted": false}], true)
	assert_eq(d.stamps_of("spirit_level"), LifeData.DONE | LifeData.SELF | LifeData.EXPERT)


func test_stamps_are_never_lost_and_new_only_once() -> void:
	var d := ToolData.new()
	d.record([{"tool": "hammer", "hinted": false}], true)
	var again := d.record([{"tool": "hammer", "hinted": true}], false)
	assert_eq(d.stamps_of("hammer"), LifeData.DONE | LifeData.SELF | LifeData.EXPERT)
	assert_false(again.has("hammer"), "nothing new")


func test_only_the_books_tools_are_stamped() -> void:
	var d := ToolData.new()
	d.record([{"tool": "lightsaber", "hinted": false}, {"tool": "", "hinted": false}], false)
	assert_true(d.is_empty())


func test_you_can_use_counts_the_tools_used_by_yourself() -> void:
	var d := ToolData.new()
	d.record([{"tool": "trowel", "hinted": false}, {"tool": "tape", "hinted": false}, {"tool": "saw", "hinted": true}], false)
	assert_eq(d.can_use(), 2)


func test_it_survives_its_dictionary_and_cleans_bad_values() -> void:
	var d := ToolData.new()
	d.record([{"tool": "trowel", "hinted": false}], true)
	var e := ToolData.from_dict(d.to_dict())
	assert_eq(e.stamps_of("trowel"), d.stamps_of("trowel"))
	var junk := ToolData.from_dict({"s": {"trowel": 99, "nonsense": 1, "saw": "x"}, "u": {"trowel": -4}})
	assert_eq(junk.stamps_of("trowel"), LifeData.DONE | LifeData.SELF | LifeData.EXPERT, "clamped to the three stamps")
	assert_eq(junk.stamps_of("nonsense"), 0)
	assert_eq(junk.uses_of("trowel"), 0)
	assert_true(ToolData.from_dict("broken").is_empty())


func test_a_merge_keeps_every_stamp_and_the_most_uses() -> void:
	var a := ToolData.new()
	a.record([{"tool": "saw", "hinted": false}], false)
	var b := ToolData.new()
	b.record([{"tool": "saw", "hinted": true}, {"tool": "saw", "hinted": true}, {"tool": "hammer", "hinted": false}], true)
	a.merge_from(b)
	assert_eq(a.stamps_of("saw"), LifeData.DONE | LifeData.SELF)
	assert_eq(a.stamps_of("hammer"), LifeData.DONE | LifeData.SELF | LifeData.EXPERT)
	assert_eq(a.uses_of("saw"), 2)


# --- In the profile and its backup (owner #116 hooks in core/save) ---------------------------------------------------

func test_the_profile_keeps_the_tool_book() -> void:
	var p := ProfileData.new()
	p.tools.record([{"tool": "trowel", "hinted": false}], false)
	var q := ProfileData.from_json(p.to_json())
	assert_eq(q.tools.stamps_of("trowel"), LifeData.DONE | LifeData.SELF)
	assert_true(ProfileData.from_json('{"version": 1, "tools": "nonsense"}').tools.is_empty())


func test_the_backup_carries_it_and_its_merge_never_loses_a_stamp() -> void:
	var local := ProfileData.new()
	local.updated_at = 100
	local.tools.record([{"tool": "hammer", "hinted": false}], true)
	var remote := ProfileData.new()
	remote.updated_at = 200
	remote.tools.record([{"tool": "hammer", "hinted": true}], false)
	remote.universe_unlocked = 2
	var json := JSON.new()
	json.parse(ProfileBackup.to_backup(remote))
	assert_true((json.data as Dictionary).has("tools"))
	var out: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(remote)).profile
	assert_eq(out.tools.stamps_of("hammer"), LifeData.DONE | LifeData.SELF | LifeData.EXPERT)


func test_a_tool_stamp_is_progress() -> void:
	var p := ProfileData.new()
	assert_true(ProfileBackup.is_new(p))
	p.tools.record([{"tool": "tape", "hinted": true}], false)
	assert_false(ProfileBackup.is_new(p))
