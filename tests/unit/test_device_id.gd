extends GutTest
## This install's id for signing in to the game server (Nakama device authentication, M4 spike).

const UUID_V4 := "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_device_id_%d/" % OS.get_process_id()


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func test_a_new_id_is_a_random_uuid() -> void:
	var re := RegEx.create_from_string(UUID_V4)
	var a := DeviceId.generate()
	var b := DeviceId.generate()
	assert_not_null(re.search(a), "UUID v4 form: %s" % a)
	assert_not_null(re.search(b), "UUID v4 form: %s" % b)
	assert_ne(a, b, "every install gets its own")


func test_valid_ids_fit_nakamas_limits() -> void:
	assert_true(DeviceId.is_valid(DeviceId.generate()))
	assert_true(DeviceId.is_valid("a".repeat(DeviceId.MIN_LENGTH)))
	assert_true(DeviceId.is_valid("b".repeat(DeviceId.MAX_LENGTH)))
	for bad: String in ["", "short", "a".repeat(DeviceId.MIN_LENGTH - 1), "c".repeat(DeviceId.MAX_LENGTH + 1),
			"has spaces in it", "ünïcode-device-id", "line\nbreak-1234"]:
		assert_false(DeviceId.is_valid(bad), "not a device id: %s" % bad)


func test_the_id_is_made_once_and_kept() -> void:
	var path := DIR + "device_id.json"
	var first := DeviceId.load_or_create(path)
	assert_true(DeviceId.is_valid(first))
	assert_true(FileAccess.file_exists(path), "kept in its own file")
	assert_eq(DeviceId.load_or_create(path), first, "the same account next time")


func test_a_broken_file_gets_a_new_id_that_is_kept() -> void:
	var path := DIR + "device_id.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("half-writ")
	f.close()
	var id := DeviceId.load_or_create(path)
	assert_true(DeviceId.is_valid(id))
	assert_eq(DeviceId.load_or_create(path), id)


func test_a_stored_id_that_nakama_would_refuse_is_replaced() -> void:
	var path := DIR + "device_id.json"
	JsonStore.write_atomic(path, JSON.stringify({"device_id": "tiny"}))
	var id := DeviceId.load_or_create(path)
	assert_ne(id, "tiny")
	assert_true(DeviceId.is_valid(id))


func test_the_real_file_is_its_own_not_the_profile() -> void:
	assert_ne(DeviceId.PATH, "user://profile.json", "a restored profile backup must not carry another phone's id")
