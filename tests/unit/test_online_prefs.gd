extends GutTest
## OnlinePrefs (M4 Wave 1, Agent C): what this device remembers about online play, kept out of
## profile.json (a profile backup never carries another phone's mutes): when the stay-safe card was
## last seen and who is muted here.

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_online_prefs_%d/" % OS.get_process_id()


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func test_a_new_device_has_seen_nothing_and_mutes_nobody() -> void:
	var p := OnlinePrefs.load_from(DIR + "none.json")
	assert_eq(p.safe_card_seen, 0)
	assert_eq(p.muted, [] as Array[String])
	assert_false(p.is_muted("u-1"))


func test_it_keeps_the_card_time_and_the_mutes() -> void:
	var p := OnlinePrefs.new()
	p.safe_card_seen = 1_800_000_000
	assert_true(p.mute("u-1"))
	assert_false(p.mute("u-1"), "once")
	assert_true(p.mute("u-2"))
	assert_eq(p.save_to(DIR + "online.json"), OK)
	var q := OnlinePrefs.load_from(DIR + "online.json")
	assert_eq(q.safe_card_seen, 1_800_000_000)
	assert_true(q.is_muted("u-1"))
	assert_true(q.is_muted("u-2"))
	q.unmute("u-1")
	assert_false(q.is_muted("u-1"))


func test_broken_files_and_odd_values_fall_back_to_defaults() -> void:
	for text: String in ["", "{", "[1]", JSON.stringify({"safe_card_seen": "soon", "muted": "u-1"}),
			JSON.stringify({"safe_card_seen": -5, "muted": [1, "", null]})]:
		var p := OnlinePrefs.from_json(text)
		assert_eq(p.safe_card_seen, 0, text)
		assert_eq(p.muted.size(), 0, text)


func test_mutes_are_capped_and_ids_checked() -> void:
	var p := OnlinePrefs.new()
	assert_false(p.mute(""), "no id")
	assert_false(p.mute("x".repeat(OnlinePrefs.MAX_ID + 1)), "not a user id")
	for i in OnlinePrefs.MAX_MUTED + 5:
		p.mute("u-%d" % i)
	assert_eq(p.muted.size(), OnlinePrefs.MAX_MUTED, "the oldest go first")
	assert_false(p.is_muted("u-0"))
	assert_true(p.is_muted("u-%d" % (OnlinePrefs.MAX_MUTED + 4)))


func test_it_never_writes_the_profile_file() -> void:
	assert_ne(OnlinePrefs.PATH, "user://profile.json")
	assert_ne(OnlinePrefs.PATH, DeviceId.PATH)
