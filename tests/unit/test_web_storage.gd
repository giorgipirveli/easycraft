extends GutTest
## M7 Task 5 (spec §20.3): saves that survive a reload in the browser. Godot copies user:// to the browser's IndexedDB
## after a FileAccess write is closed; Voxel Tools writes a world's blocks with its own SQLite I/O, which does not (the
## lead's browser check, 2026-09-27: the edit was gone after a reload until a small file was written after the save).
## WebStorage writes that small stamp once the blocks are written, only in a browser, and asks the browser once to keep
## the site's storage.

const PHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}
const ANDROID := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}

## Per process: parallel test runs (other worktrees) share the same user:// folder.
var STAMP := "user://test_web_sync_%d.txt" % OS.get_process_id()


class FakeTracker:
	extends RefCounted
	var done := false

	func is_complete() -> bool:
		return done


func before_each() -> void:
	WebStorage.stamp_path = STAMP
	WebStorage.asked = false
	_remove()


func after_each() -> void:
	WebStorage.stamp_path = WebStorage.STAMP
	PlatformRules.simulated = {}
	_remove()


func _remove() -> void:
	if FileAccess.file_exists(STAMP):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(STAMP))


func test_in_a_browser_a_sync_writes_the_stamp() -> void:
	assert_true(WebStorage.sync(PHONE_BROWSER), "written")
	assert_true(FileAccess.file_exists(STAMP))
	assert_gt(FileAccess.get_file_as_string(STAMP).to_int(), 0, "a timestamp, so every sync writes something new")


func test_elsewhere_a_sync_writes_nothing() -> void:
	assert_false(WebStorage.sync(ANDROID))
	assert_false(WebStorage.sync({}), "the desktop")
	assert_false(FileAccess.file_exists(STAMP))


func test_without_features_it_asks_this_device() -> void:
	assert_false(WebStorage.sync(), "this test run is no browser")
	PlatformRules.simulated = PHONE_BROWSER
	assert_true(WebStorage.sync(), "a pretend phone browser")
	assert_true(FileAccess.file_exists(STAMP))


func test_the_stamp_waits_until_the_blocks_are_written() -> void:
	var tracker := FakeTracker.new()
	WebStorage.sync_when_written(tracker, PHONE_BROWSER)
	await wait_process_frames(3)
	assert_false(FileAccess.file_exists(STAMP), "not while the blocks are still being written")
	tracker.done = true
	await wait_process_frames(2)
	assert_true(FileAccess.file_exists(STAMP), "right after they are")


func test_a_save_that_never_finishes_still_syncs_the_rest() -> void:
	WebStorage.sync_when_written(FakeTracker.new(), PHONE_BROWSER, 50)
	await wait_seconds(0.3)
	assert_true(FileAccess.file_exists(STAMP), "after the wait, everything else is pushed")


func test_no_tracker_syncs_at_once() -> void:
	WebStorage.sync_when_written(null, PHONE_BROWSER)
	assert_true(FileAccess.file_exists(STAMP))


func test_off_the_web_nothing_waits_or_writes() -> void:
	var tracker := FakeTracker.new()
	WebStorage.sync_when_written(tracker, ANDROID)
	tracker.done = true
	await wait_process_frames(3)
	assert_false(FileAccess.file_exists(STAMP))


func test_the_browser_is_asked_once_to_keep_the_storage() -> void:
	assert_true(WebStorage.ask_persistent(PHONE_BROWSER), "the first time")
	assert_false(WebStorage.ask_persistent(PHONE_BROWSER), "never again in this run")


func test_elsewhere_nothing_is_asked() -> void:
	assert_false(WebStorage.ask_persistent(ANDROID))
	assert_false(WebStorage.ask_persistent({}))
	assert_false(WebStorage.asked, "and a browser would still be asked")
