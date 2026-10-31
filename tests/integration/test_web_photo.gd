extends GutTest
## M7 Task 4 (spec §20.3): photos in the browser. A browser's user:// is hidden in its storage, so the shutter keeps the
## photo in the game (no file there: photos would crowd the storage the worlds live in) and the chip beside the shutter
## reads DOWNLOAD: it offers the photo as a file download (JavaScriptBridge.download_buffer), only where the grown-up
## photo-sharing switch allows (PhotoRules.may_share, as SHARE on Android). Android and the desktop keep their ways.

const PHONE_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.TOUCH_SCREEN: true}
const T := {"year": 2026, "month": 9, "day": 27, "hour": 12, "minute": 0, "second": 1}
const NAME := "EasyCraft_20260927_120001.png"

var DIR := "user://test_web_photo_%d/" % OS.get_process_id()
var allowed := false
var offered: Array[String] = []
var offered_png := PackedByteArray()
var answer: StringName = &"download"


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	allowed = false
	offered.clear()
	offered_png = PackedByteArray()
	answer = &"download"


func after_each() -> void:
	PlatformRules.simulated = {}
	get_tree().paused = false
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


static func _ground(cell: Vector3i) -> bool:
	return cell.y < 10


## Photo mode as it is made on this platform, in its own 1280 x 720 view, on LAN (nothing pauses); the sharing switch
## is `allowed`; `record`: the download is recorded instead of offered.
func _photo(record: bool = true) -> PhotoMode:
	var view := SubViewport.new()
	view.size = Vector2i(1280, 720)
	add_child_autofree(view)
	var target := Node3D.new()
	view.add_child(target)
	target.position = Vector3(0.5, 10.0, 0.5)
	var hud := Control.new()
	view.add_child(hud)
	var photo := PhotoMode.new()
	view.add_child(photo)
	photo.setup(target, hud, _ground)
	photo.folders = PackedStringArray([DIR])
	photo.clock = func() -> Dictionary: return T
	photo.share_allowed = func() -> bool: return allowed
	if record:
		photo.sharer = func(png: PackedByteArray, path: String) -> StringName:
			offered.append(path)
			offered_png = png
			return answer
	return photo


func _chip(photo: PhotoMode, text: String) -> PhotoChip:
	for c in photo.find_children("*", "PhotoChip", true, false):
		if (c as PhotoChip).text == text and (c as PhotoChip).is_visible_in_tree():
			return c
	return null


func _words(photo: PhotoMode) -> String:
	var out := ""
	for l in photo.find_children("*", "Label", true, false):
		if (l as Label).is_visible_in_tree():
			out += (l as Label).text + "\n"
	return out


func _shoot(photo: PhotoMode) -> void:
	photo.take_photo()
	await wait_for_signal(photo.photo_saved, 10, "the photo is taken")


func _with_photo_mode(body: Callable) -> void:
	var old := Game.net_mode
	Game.net_mode = &"host"
	await body.call()
	Game.net_mode = old


func test_in_a_browser_the_shutter_keeps_the_photo_without_a_file() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var photo := _photo()
	await _with_photo_mode(func() -> void:
		photo.open()
		await _shoot(photo)
		assert_eq(DirAccess.get_files_at(DIR).size(), 0, "nothing written into the browser's storage")
		assert_false(photo.last_png().is_empty(), "the photo is kept (the Memory Book reads it)")
		assert_eq(photo.last_path, NAME, "the name its download gets")
		assert_string_contains(_words(photo), "Photo taken!")
		assert_string_contains(_words(photo), "Pinch", "a phone browser gets the finger hint")
		photo.close())


func test_in_a_browser_download_shows_only_where_the_grown_up_switch_allows() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	var photo := _photo()
	await _with_photo_mode(func() -> void:
		photo.open()
		assert_null(_chip(photo, "DOWNLOAD"), "a child without a grown-up's yes: no DOWNLOAD")
		assert_null(_chip(photo, "FOLDER"), "and never FOLDER in a browser")
		await _shoot(photo)
		photo.share()   # even a call that slips through offers nothing
		assert_eq(offered.size(), 0)
		photo.close()
		allowed = true
		photo.open()
		assert_not_null(_chip(photo, "DOWNLOAD"), "DOWNLOAD with a grown-up's yes")
		photo.close())


func test_in_a_browser_download_offers_the_photo_as_a_file() -> void:
	PlatformRules.simulated = PHONE_BROWSER
	allowed = true
	var photo := _photo()
	await _with_photo_mode(func() -> void:
		photo.open()
		await _shoot(photo)
		assert_string_contains(_words(photo), "DOWNLOAD", "the message says how to keep it")
		photo.share()
		assert_eq(offered, [NAME] as Array[String], "offered under its timestamp name")
		assert_eq(offered_png, photo.last_png(), "the photo itself")
		assert_string_contains(_words(photo), "downloading")
		photo.close())


func test_the_download_way_never_opens_a_folder() -> void:
	# Not in a real browser (this run): nothing is offered and nothing else is tried instead.
	assert_eq(PhotoShare.share(PackedByteArray([1, 2, 3]), NAME, PlatformRules.PHOTO_DOWNLOAD), &"")


func test_the_chip_says_what_it_does_on_each_platform() -> void:
	assert_eq(PhotoShare.button_label(PlatformRules.PHOTO_GALLERY), "SHARE")
	assert_eq(PhotoShare.button_label(PlatformRules.PHOTO_DOWNLOAD), "DOWNLOAD")
	assert_eq(PhotoShare.button_label(PlatformRules.PHOTO_FOLDER), "FOLDER")


func test_on_the_desktop_the_shutter_still_saves_a_file() -> void:
	var photo := _photo()
	await _with_photo_mode(func() -> void:
		photo.open()
		await _shoot(photo)
		assert_eq(DirAccess.get_files_at(DIR).size(), 1, "user://photos, as before")
		assert_true(FileAccess.file_exists(photo.last_path))
		photo.close())
