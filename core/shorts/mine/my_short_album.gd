class_name MyShortAlbum
extends RefCounted
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): the files a child's Shorts show, on this device only
## (user://my_shorts/; never in the profile, never sent anywhere):
## - photos/p_<when>.jpg: a small copy (PHOTO_WIDTH wide, JPG) of each photo photo mode takes (keep_photo, from the
##   sandbox: off the main thread, on every platform: a browser keeps its photos in the game, not in a folder), and of a
##   photo of the game's photo folder (PhotoFiles: user://photos on a computer, Pictures/EasyCraft on a phone) when the
##   maker picks it (import_photo). Its name comes from the photo's ("EasyCraft_20261001_101500.png" ->
##   "p_20261001_101500.jpg"), so one photo is one copy;
## - builds/b_<n>.txt: a copy of one of the child's stamps (BuildCodec text) for a Step by step, so the Short stays the
##   same when the stamp's slot is used again.
## tidy() keeps every file a kept Short uses and the newest MAX_KEPT photo copies. texture() loads a picture for the
## player and the maker on a worker thread (a phone takes tens of ms a photo: never in a frame) and keeps the last few.

const ROOT := "user://my_shorts"
const PHOTO_WIDTH := 640
const JPG_QUALITY := 0.82
## Photo copies kept for the maker besides the ones a Short shows.
const MAX_KEPT := 40
## Pictures kept loaded (the feed's three Shorts, the maker's grid).
const KEEP_TEXTURES := 24

static var _root := ROOT
static var _gallery := PackedStringArray()
static var _gallery_set := false
static var _tasks: Array[int] = []
static var _loading := {}          # path -> {task, box, waiters}
static var _textures := {}         # path -> Texture2D
static var _texture_order: Array[String] = []
static var _reaping := false
static var _photo_name := RegEx.create_from_string("^easycraft_([0-9]{8}_[0-9]{6}(_[0-9]{1,3})?)\\.png$")
static var _build_n := 0


## Tests: another folder for the album and the photo folders to look in (none: the game's own, PhotoFiles.folders).
static func use(root: String, gallery: Variant = null) -> void:
	_root = root
	_gallery_set = gallery is PackedStringArray
	_gallery = gallery if gallery is PackedStringArray else PackedStringArray()


static func root() -> String:
	return _root


static func photo_path(file: String) -> String:
	return _root.path_join("photos").path_join(file)


static func build_path(file: String) -> String:
	return _root.path_join("builds").path_join(file)


## The album's name for a photo of the game ("…/EasyCraft_20261001_101500.png" -> "p_20261001_101500.jpg"; "" for a
## file that is not the game's photo).
static func photo_file_for(path: String) -> String:
	var m := _photo_name.search(path.get_file().to_lower())
	return "p_%s.jpg" % m.get_string(1) if m else ""


# --- Keeping photos --------------------------------------------------------------------------------------------------

## A photo just taken (photo mode's PNG and the name it was saved under): its small copy is made on a worker thread.
static func keep_photo(png: PackedByteArray, saved_as: String) -> void:
	var file := photo_file_for(saved_as)
	if png.is_empty() or file == "" or FileAccess.file_exists(photo_path(file)):
		return
	DirAccess.make_dir_recursive_absolute(photo_path("").get_base_dir())
	var path := photo_path(file)
	_tasks.append(WorkerThreadPool.add_task(func() -> void: _write_copy(_image_from_png(png), path), false, "My Shorts photo"))
	_reap_later()


## The same, now (tests, tools).
static func keep_png_now(png: PackedByteArray, file: String) -> bool:
	if not MyShortRules.is_photo_file(file):
		return false
	DirAccess.make_dir_recursive_absolute(photo_path("").get_base_dir())
	return _write_copy(_image_from_png(png), photo_path(file))


## Every copy being made, finished (tests; leaving the game).
static func finish() -> void:
	for t in _tasks:
		WorkerThreadPool.wait_for_task_completion(t)
	_tasks.clear()


## The photos the maker offers, newest first: {file (its album name), path (where it is read from now)}; a photo of
## the game's folder not copied yet is read from there until it is picked (import_photo).
static func photos() -> Array[Dictionary]:
	var found := {}
	var dir := photo_path("").get_base_dir()
	if DirAccess.dir_exists_absolute(dir):
		for f in DirAccess.get_files_at(dir):
			if MyShortRules.is_photo_file(f):
				found[f] = {"file": f, "path": dir.path_join(f)}
	for folder in _folders():
		if not DirAccess.dir_exists_absolute(folder):
			continue
		for f in DirAccess.get_files_at(folder):
			var file := photo_file_for(f)
			if file != "" and not found.has(file):
				found[file] = {"file": file, "path": folder.path_join(f)}
	var names: Array = found.keys()
	names.sort()
	names.reverse()
	var out: Array[Dictionary] = []
	for n: String in names:
		out.append(found[n])
	return out


## A photo picked in the maker, in the album now (a folder's photo is copied): false when it can't be read.
static func import_photo(photo: Dictionary) -> bool:
	var file := str(photo.get("file", ""))
	if not MyShortRules.is_photo_file(file):
		return false
	if FileAccess.file_exists(photo_path(file)):
		return true
	var path := str(photo.get("path", ""))
	if not FileAccess.file_exists(path):
		return false
	DirAccess.make_dir_recursive_absolute(photo_path("").get_base_dir())
	return _write_copy(Image.load_from_file(path), photo_path(file))


static func _folders() -> PackedStringArray:
	if _gallery_set:
		return _gallery
	var gallery := PlatformRules.photo_save(PlatformRules.current()) == PlatformRules.PHOTO_GALLERY
	return PhotoFiles.folders(gallery, OS.get_system_dir(OS.SYSTEM_DIR_PICTURES) if gallery else "")


static func _image_from_png(png: PackedByteArray) -> Image:
	var img := Image.new()
	if img.load_png_from_buffer(png) != OK or img.is_empty():
		return null
	return img


## A copy at most PHOTO_WIDTH wide, as a JPG (a worker thread's job).
static func _write_copy(img: Image, path: String) -> bool:
	if img == null or img.is_empty():
		return false
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	if img.get_width() > PHOTO_WIDTH:
		img.resize(PHOTO_WIDTH, maxi(roundi(float(img.get_height()) * PHOTO_WIDTH / img.get_width()), 1), Image.INTERPOLATE_BILINEAR)
	return img.save_jpg(path, JPG_QUALITY) == OK


# --- Stamp copies --------------------------------------------------------------------------------------------------------

## A copy of a stamp's build (BuildCodec text) for a Step by step: its file name ("" when it could not be written).
static func keep_build(text: String, now: int) -> String:
	DirAccess.make_dir_recursive_absolute(build_path("").get_base_dir())
	var file := ""
	while true:
		_build_n += 1
		file = "b_%d_%d.txt" % [maxi(now, 0), _build_n]
		if not FileAccess.file_exists(build_path(file)):
			break
	return file if keep_build_as(file, text) else ""


static func keep_build_as(file: String, text: String) -> bool:
	if not MyShortRules.is_build_file(file):
		return false
	DirAccess.make_dir_recursive_absolute(build_path("").get_base_dir())
	var f := FileAccess.open(build_path(file), FileAccess.WRITE)
	if f == null:
		return false
	var ok := f.store_string(text)
	f.close()
	return ok


## A stamp copy's blocks ({} when it is missing or broken).
static func read_build(file: String) -> Dictionary:
	if not MyShortRules.is_build_file(file) or not FileAccess.file_exists(build_path(file)):
		return {}
	return BuildCodec.decode(FileAccess.get_file_as_string(build_path(file)), MyStampBook.LIMITS)


# --- Tidying -------------------------------------------------------------------------------------------------------------

## Keeps every file in `used` (MyShortsData.files) and the newest MAX_KEPT photo copies; the rest go.
static func tidy(used: Array[String]) -> void:
	var photos_dir := photo_path("").get_base_dir()
	if DirAccess.dir_exists_absolute(photos_dir):
		var names := Array(DirAccess.get_files_at(photos_dir)).filter(func(f: String) -> bool: return MyShortRules.is_photo_file(f))
		names.sort()
		names.reverse()
		var kept := 0
		for f: String in names:
			if used.has(f):
				continue
			kept += 1
			if kept > MAX_KEPT:
				DirAccess.remove_absolute(photos_dir.path_join(f))
	var builds_dir := build_path("").get_base_dir()
	if DirAccess.dir_exists_absolute(builds_dir):
		for f in DirAccess.get_files_at(builds_dir):
			if MyShortRules.is_build_file(f) and not used.has(f):
				DirAccess.remove_absolute(builds_dir.path_join(f))


# --- Pictures for the player and the maker --------------------------------------------------------------------------------

## The picture at `path` (a photo copy or a photo of the folder, made at most PHOTO_WIDTH wide) if it is loaded; else
## null, and it loads on a worker thread: `ready` is called with it (null when it can't be read) on the main thread.
static func texture(path: String, ready: Callable = Callable()) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	if not FileAccess.file_exists(path):
		if ready.is_valid():
			ready.call_deferred(null)
		return null
	if not _loading.has(path):
		var box := {}
		_loading[path] = {"box": box, "waiters": [], "task": WorkerThreadPool.add_task(func() -> void:
			var img := Image.load_from_file(path)
			if img != null and not img.is_empty() and img.get_width() > PHOTO_WIDTH:
				img.resize(PHOTO_WIDTH, maxi(roundi(float(img.get_height()) * PHOTO_WIDTH / img.get_width()), 1),
					Image.INTERPOLATE_BILINEAR)
			box.image = img, false, "My Shorts picture")}
	if ready.is_valid():
		(_loading[path].waiters as Array).append(ready)
	_reap_later()
	return null


## Forgets every loaded picture (tests; a deleted Short's photos).
static func forget() -> void:
	finish()
	for path: String in _loading:
		WorkerThreadPool.wait_for_task_completion(int(_loading[path].task))
	_loading.clear()
	_textures.clear()
	_texture_order.clear()


static func _reap_later() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or _reaping:
		return
	_reaping = true
	tree.process_frame.connect(func() -> void: _reap(), CONNECT_ONE_SHOT)


static func _reap() -> void:
	_reaping = false
	var waiting := false
	var left: Array[int] = []
	for t in _tasks:
		if WorkerThreadPool.is_task_completed(t):
			WorkerThreadPool.wait_for_task_completion(t)
		else:
			left.append(t)
	_tasks = left
	waiting = not left.is_empty()
	for path: String in _loading.keys():
		var job: Dictionary = _loading[path]
		if not WorkerThreadPool.is_task_completed(int(job.task)):
			waiting = true
			continue
		WorkerThreadPool.wait_for_task_completion(int(job.task))
		_loading.erase(path)
		var img: Image = job.box.get("image")
		var tex: Texture2D = ImageTexture.create_from_image(img) if img != null and not img.is_empty() else null
		if tex != null:
			_textures[path] = tex
			_texture_order.append(path)
			while _texture_order.size() > KEEP_TEXTURES:
				_textures.erase(_texture_order.pop_front())
		for w: Callable in job.waiters:
			if w.is_valid():
				w.call(tex)
	if waiting:
		_reap_later()
