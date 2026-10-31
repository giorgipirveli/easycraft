extends GutTest

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_json_store_%d/" % OS.get_process_id()


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func test_round_trip() -> void:
	assert_eq(JsonStore.write_atomic(DIR + "a.json", '{"x":1}'), OK)
	assert_eq(JsonStore.read_text(DIR + "a.json"), '{"x":1}')


func test_overwrite_replaces_contents() -> void:
	JsonStore.write_atomic(DIR + "a.json", '{"n":"first"}')
	JsonStore.write_atomic(DIR + "a.json", '{"n":"second"}')
	assert_eq(JsonStore.read_text(DIR + "a.json"), '{"n":"second"}')


func test_no_temp_file_left_behind() -> void:
	JsonStore.write_atomic(DIR + "a.json", '{"x":1}')
	assert_false(FileAccess.file_exists(DIR + "a.json.tmp"))


func test_missing_file_reads_empty() -> void:
	assert_eq(JsonStore.read_text(DIR + "missing.json"), "")


func test_stale_temp_file_does_not_replace_real_file() -> void:
	JsonStore.write_atomic(DIR + "a.json", '{"n":"good"}')
	var f := FileAccess.open(DIR + "a.json.tmp", FileAccess.WRITE)
	f.store_string("half-writ")
	f.close()
	assert_eq(JsonStore.read_text(DIR + "a.json"), '{"n":"good"}')


func test_previous_version_is_kept_as_backup() -> void:
	JsonStore.write_atomic(DIR + "b.json", '{"v":1}')
	JsonStore.write_atomic(DIR + "b.json", '{"v":2}')
	assert_eq(FileAccess.get_file_as_string(DIR + "b.json.bak"), '{"v":1}')


func test_broken_file_falls_back_to_backup() -> void:
	JsonStore.write_atomic(DIR + "c.json", '{"v":1}')
	JsonStore.write_atomic(DIR + "c.json", '{"v":2}')
	var f := FileAccess.open(DIR + "c.json", FileAccess.WRITE)
	f.store_string('{"v":')
	f.close()
	assert_eq(JsonStore.read_text(DIR + "c.json"), '{"v":1}')


func test_missing_main_file_falls_back_to_backup() -> void:
	JsonStore.write_atomic(DIR + "d.json", '{"v":1}')
	JsonStore.write_atomic(DIR + "d.json", '{"v":2}')
	DirAccess.remove_absolute(ProjectSettings.globalize_path(DIR + "d.json"))
	assert_eq(JsonStore.read_text(DIR + "d.json"), '{"v":1}')


## Review I1: a NaN that sneaks into a save turns into "nan", which is not JSON. Writing it would
## have made both the file and (on the next save) its backup unreadable, and loading re-seeds.
func test_a_save_that_does_not_parse_never_replaces_the_file() -> void:
	JsonStore.write_atomic(DIR + "e.json", '{"v":1}')
	JsonStore.write_atomic(DIR + "e.json", '{"v":2}')
	assert_ne(JsonStore.write_atomic(DIR + "e.json", '{"v":nan}'), OK, "refused")
	assert_eq(FileAccess.get_file_as_string(DIR + "e.json"), '{"v":2}', "the file is untouched")
	assert_eq(FileAccess.get_file_as_string(DIR + "e.json.bak"), '{"v":1}', "and so is its backup")
	assert_false(FileAccess.file_exists(DIR + "e.json.tmp"))
