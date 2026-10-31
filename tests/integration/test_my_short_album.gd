extends GutTest
## MAKE MY SHORT: the album on this device (user://my_shorts/): small copies of the child's photos (kept when photo mode
## takes one, or copied from the game's photo folder when picked), stamp copies for Step by step, loaded for the player
## off the main thread. Nothing here is ever sent anywhere; the profile holds only the files' names.

var _root := ""
var _gallery := ""


func before_each() -> void:
	_root = "user://test_my_album_%d" % OS.get_process_id()
	_gallery = "user://test_my_gallery_%d" % OS.get_process_id()
	_wipe(_root)
	_wipe(_gallery)
	DirAccess.make_dir_recursive_absolute(_gallery)
	MyShortAlbum.use(_root, PackedStringArray([_gallery]))


func after_each() -> void:
	MyShortAlbum.use(MyShortAlbum.ROOT)
	MyShortAlbum.forget()
	_wipe(_root)
	_wipe(_gallery)


func _wipe(dir: String) -> void:
	for sub in ["", "photos", "builds"]:
		var d := dir.path_join(sub) if sub != "" else dir
		if DirAccess.dir_exists_absolute(d):
			for f in DirAccess.get_files_at(d):
				DirAccess.remove_absolute(d.path_join(f))
	for sub in ["photos", "builds", ""]:
		var d := dir.path_join(sub) if sub != "" else dir
		if DirAccess.dir_exists_absolute(d):
			DirAccess.remove_absolute(d)


func _png(w: int = 1280, h: int = 720, c: Color = Color(0.2, 0.6, 0.9)) -> PackedByteArray:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(c)
	img.fill_rect(Rect2i(w / 4, h / 4, w / 2, h / 2), Color(0.9, 0.3, 0.2))
	return img.save_png_to_buffer()


func test_a_photo_taken_is_kept_small_in_the_album() -> void:
	var file := MyShortAlbum.photo_file_for("user://photos/EasyCraft_20261001_101500.png")
	assert_eq(file, "p_20261001_101500.jpg")
	assert_true(MyShortRules.is_photo_file(file))
	assert_eq(MyShortAlbum.photo_file_for("EasyCraft_20261001_101500_2.png"), "p_20261001_101500_2.jpg")
	assert_eq(MyShortAlbum.keep_png_now(_png(), file), true)
	var img := Image.load_from_file(MyShortAlbum.photo_path(file))
	assert_not_null(img)
	assert_eq(img.get_width(), MyShortAlbum.PHOTO_WIDTH, "a phone's screen is made 640 wide")
	assert_eq(img.get_height(), 360)
	assert_lt(FileAccess.get_file_as_bytes(MyShortAlbum.photo_path(file)).size(), 120 * 1024)


func test_keeping_runs_off_the_main_thread() -> void:
	MyShortAlbum.keep_photo(_png(), "EasyCraft_20261001_101501.png")
	MyShortAlbum.finish()
	assert_true(FileAccess.file_exists(MyShortAlbum.photo_path("p_20261001_101501.jpg")))


func test_the_maker_lists_the_album_and_the_photo_folder_newest_first() -> void:
	MyShortAlbum.keep_png_now(_png(), "p_20261001_090000.jpg")
	var f := FileAccess.open(_gallery.path_join("EasyCraft_20261001_100000.png"), FileAccess.WRITE)
	f.store_buffer(_png(800, 450))
	f.close()
	var again := FileAccess.open(_gallery.path_join("EasyCraft_20261001_090000.png"), FileAccess.WRITE)
	again.store_buffer(_png())
	again.close()
	var list := MyShortAlbum.photos()
	assert_eq(list.size(), 2, "a photo already copied shows once")
	assert_eq(list[0].file, "p_20261001_100000.jpg")
	assert_eq(list[0].path, _gallery.path_join("EasyCraft_20261001_100000.png"), "not copied yet: from the folder")
	assert_eq(list[1].file, "p_20261001_090000.jpg")
	assert_eq(list[1].path, MyShortAlbum.photo_path("p_20261001_090000.jpg"))
	assert_true(MyShortAlbum.import_photo(list[0]), "picked: copied into the album")
	assert_true(FileAccess.file_exists(MyShortAlbum.photo_path("p_20261001_100000.jpg")))


func test_a_stamp_is_copied_for_step_by_step() -> void:
	var blocks := {Vector3i(0, 0, 0): BlockIds.PLANKS, Vector3i(0, 1, 0): BlockIds.GLASS, Vector3i(1, 2, 0): BlockIds.RED}
	var file := MyShortAlbum.keep_build(BuildCodec.encode(blocks), 1727771234)
	assert_true(MyShortRules.is_build_file(file), file)
	var back := MyShortAlbum.read_build(file)
	assert_eq(back.size(), 3)
	assert_eq(MyShortRules.layers_of(back), 3)
	assert_ne(MyShortAlbum.keep_build(BuildCodec.encode(blocks), 1727771234), file, "never over another copy")
	assert_eq(MyShortAlbum.read_build("b_missing.txt"), {})
	assert_eq(MyShortAlbum.read_build("../profile.json"), {}, "never a path")


func test_tidying_keeps_what_shorts_use_and_the_newest_photos() -> void:
	for i in MyShortAlbum.MAX_KEPT + 3:
		MyShortAlbum.keep_png_now(_png(64, 36), "p_20261001_%06d.jpg" % i)
	var used: Array[String] = ["p_20261001_000000.jpg", "b_1.txt"]
	MyShortAlbum.keep_build_as("b_1.txt", "x")
	MyShortAlbum.keep_build_as("b_2.txt", "y")
	MyShortAlbum.tidy(used)
	var left := DirAccess.get_files_at(_root.path_join("photos"))
	assert_eq(left.size(), MyShortAlbum.MAX_KEPT + 1, "the newest and the ones in use")
	assert_true(left.has("p_20261001_000000.jpg"), "a Short's photo stays")
	assert_false(left.has("p_20261001_000001.jpg"), "the oldest not in use goes")
	assert_eq(Array(DirAccess.get_files_at(_root.path_join("builds"))), ["b_1.txt"], "a stamp copy nobody uses goes")


func test_a_photo_loads_for_the_player_off_the_main_thread() -> void:
	MyShortAlbum.keep_png_now(_png(), "p_20261001_120000.jpg")
	var got := []
	var tex := MyShortAlbum.texture(MyShortAlbum.photo_path("p_20261001_120000.jpg"), func(t: Texture2D) -> void: got.append(t))
	assert_null(tex, "not yet: it loads on a worker")
	for i in 60:
		await wait_process_frames(1)
		if not got.is_empty():
			break
	assert_eq(got.size(), 1)
	assert_eq((got[0] as Texture2D).get_width(), MyShortAlbum.PHOTO_WIDTH)
	assert_eq(MyShortAlbum.texture(MyShortAlbum.photo_path("p_20261001_120000.jpg")), got[0], "kept for the next")
	var missing := []
	MyShortAlbum.texture(MyShortAlbum.photo_path("p_nope.jpg"), func(t: Texture2D) -> void: missing.append(t))
	for i in 30:
		await wait_process_frames(1)
		if not missing.is_empty():
			break
	assert_eq(missing, [null], "a missing photo answers null (the frame shows a camera instead)")
