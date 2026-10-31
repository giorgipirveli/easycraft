extends GutTest
## Owner #67: a save stamps the groups of the child's choices that changed (ProfileBackup.stamp_changes through the
## Profile autoload's own script, on a file of this test's), so the newest choice wins per group on every device.

const ProfileScript := preload("res://autoloads/profile.gd")

var DIR := "user://test_profile_stamps_%d/" % OS.get_process_id()


func after_all() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))
	DirAccess.remove_absolute(DIR)


func _profile() -> Node:
	DirAccess.make_dir_recursive_absolute(DIR)
	var p: Node = ProfileScript.new()
	p.path = DIR + "profile.json"
	autofree(p)
	return p


func test_a_save_stamps_only_the_choices_that_changed() -> void:
	var p := _profile()
	p.load_profile()
	p.data.username = "Pip"
	p.save()
	assert_eq(p.data.stamps, {}, "a name and nothing else chosen")
	p.data.avatar.hat = &"bow"
	var before := int(Time.get_unix_time_from_system())
	p.save()
	assert_gte(int(p.data.stamps.get("look", 0)), before)
	assert_false(p.data.stamps.has("settings"))
	var again: Node = _profile()
	again.load_profile()
	assert_eq(again.data.stamps, p.data.stamps, "kept in the file")


func test_a_merged_choice_keeps_the_stamp_it_came_with() -> void:
	var p := _profile()
	p.load_profile()
	p.data.avatar.hat = &"flower_crown"   # ProfileSync copied another device's look in...
	p.data.stamps.look = 1_700_000_000   # ...with its own stamp
	p.save()
	assert_eq(int(p.data.stamps.look), 1_700_000_000)
