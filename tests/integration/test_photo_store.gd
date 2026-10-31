extends GutTest
## Writing photos (M3 Task 16): the first folder that takes the file wins (on Android the gallery
## album, then the app's own folder); nowhere to write gives no path, never a crash.

const T := {"year": 2026, "month": 9, "day": 24, "hour": 9, "minute": 30, "second": 0}
const NOWHERE := "/proc/easycraft_no_such_place"

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var DIR := "user://test_photo_store_%d" % OS.get_process_id()


func after_each() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		for f in DirAccess.get_files_at(DIR):
			DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	if DirAccess.dir_exists_absolute(DIR):
		DirAccess.remove_absolute(DIR)


func _png() -> PackedByteArray:
	return Image.create_empty(8, 4, false, Image.FORMAT_RGB8).save_png_to_buffer()


## The engine reports the folder it could not make; that is the point of these tests.
func _expect_folder_error() -> void:
	var errors := get_errors()
	assert_gt(errors.size(), 0, "the engine says the folder could not be made")
	for e in errors:
		e.handled = true


func test_a_folder_that_cannot_be_written_falls_back_to_the_next() -> void:
	var path := PhotoFiles.write_png(_png(), PackedStringArray([NOWHERE, DIR]), T)
	_expect_folder_error()
	assert_eq(path, DIR.path_join("EasyCraft_20260924_093000.png"))
	var img := Image.load_from_file(path)
	assert_not_null(img)
	if img:
		assert_eq(img.get_size(), Vector2i(8, 4))


func test_the_folder_is_made_when_missing() -> void:
	var path := PhotoFiles.write_png(_png(), PackedStringArray([DIR]), T)
	assert_true(FileAccess.file_exists(path))


func test_nowhere_to_write_gives_no_path() -> void:
	assert_eq(PhotoFiles.write_png(_png(), PackedStringArray([NOWHERE]), T), "")
	_expect_folder_error()
