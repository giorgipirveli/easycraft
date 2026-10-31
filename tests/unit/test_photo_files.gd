extends GutTest
## Where photos go and what they are called (M3 Task 16): a timestamp name that never overwrites an
## earlier photo; the phone's Pictures/EasyCraft album on Android (the app's own folder if that
## fails), user://photos on desktop.

const T := {"year": 2026, "month": 9, "day": 4, "hour": 7, "minute": 5, "second": 3}


func test_the_name_is_a_zero_padded_timestamp() -> void:
	assert_eq(PhotoFiles.base_name(T), "EasyCraft_20260904_070503")


func test_a_free_name_is_used_as_is() -> void:
	var none := func(_p: String) -> bool: return false
	assert_eq(PhotoFiles.unique_path("user://photos", T, none), "user://photos/EasyCraft_20260904_070503.png")


func test_a_taken_name_gets_a_number_and_never_overwrites() -> void:
	var taken := {}
	for i in 4:
		var path := PhotoFiles.unique_path("user://photos", T, func(p: String) -> bool: return taken.has(p))
		assert_false(taken.has(path), "never an existing file: %s" % path)
		taken[path] = true
	assert_true(taken.has("user://photos/EasyCraft_20260904_070503.png"))
	assert_true(taken.has("user://photos/EasyCraft_20260904_070503_2.png"))
	assert_true(taken.has("user://photos/EasyCraft_20260904_070503_4.png"))


func test_android_saves_to_the_gallery_album_first_then_the_app() -> void:
	assert_eq(PhotoFiles.folders(true, "/storage/emulated/0/Pictures"),
		PackedStringArray(["/storage/emulated/0/Pictures/EasyCraft", "user://photos"]))
	assert_eq(PhotoFiles.folders(true, ""), PackedStringArray(["user://photos"]), "no Pictures folder: the app's own")


func test_desktop_saves_to_user_photos() -> void:
	assert_eq(PhotoFiles.folders(false, "/home/kid/Pictures"), PackedStringArray(["user://photos"]))


func test_the_message_says_where_the_photo_went() -> void:
	var pics := "/storage/emulated/0/Pictures"
	assert_string_contains(PhotoFiles.where_message(pics + "/EasyCraft/a.png", pics, true), "Gallery")
	assert_string_contains(PhotoFiles.where_message("user://photos/a.png", pics, true), "game")
	var desktop := PhotoFiles.where_message("user://photos/a.png", "", false)
	assert_string_contains(desktop, ProjectSettings.globalize_path("user://photos"), "desktop shows the folder")
