extends GutTest
## Owner #123 (2026-10-17): the phone app and the web game both said "v1.0.5" while they were different builds, so
## nobody could tell. Every export writes res://data/build_info.json (tools/write_build_info.py: the commit, the date,
## online play's fingerprint); the menu shows the build beside the version; a build without the file (the editor, the
## tests) shows the version alone.

var path := ""


func before_each() -> void:
	path = "user://build_info_test_%d.json" % OS.get_process_id()


func after_each() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _write(text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_the_label_shows_the_builds_date_and_commit() -> void:
	var info := {"commit": "90e976cc", "date": "2026-10-17T18:03:00+04:00", "net": "a1b2c3d4"}
	assert_eq(BuildInfo.label("1.0.6", info), "v1.0.6 (17 Oct, 90e976cc)")


func test_a_build_without_its_file_shows_the_version_alone() -> void:
	assert_eq(BuildInfo.label("1.0.6", {}), "v1.0.6")
	assert_eq(BuildInfo.read("user://no_such_build_info.json"), {})


func test_reading_keeps_only_what_an_export_writes() -> void:
	_write('{"commit": "90e976cc", "date": "2026-10-17T18:03:00+04:00", "net": "a1b2c3d4", "extra": 3}')
	assert_eq(BuildInfo.read(path), {"commit": "90e976cc", "date": "2026-10-17T18:03:00+04:00", "net": "a1b2c3d4"})
	_write('{"commit": "<b>x</b>", "date": 5, "net": "a1b2c3d4"}')
	assert_eq(BuildInfo.read(path), {"net": "a1b2c3d4"}, "a commit is hex, a date is a date")
	_write("not json")
	assert_eq(BuildInfo.read(path), {})


func test_online_plays_fingerprint_is_the_files_or_unknown() -> void:
	assert_eq(BuildInfo.net({"net": "a1b2c3d4"}), "a1b2c3d4")
	assert_eq(BuildInfo.net({}), "", "unknown (a developer's run)")
