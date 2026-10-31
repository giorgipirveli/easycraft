class_name PhotoFiles
extends RefCounted
## Where photos go and what they are called (M3 §14.14). Names are timestamps that never overwrite an
## earlier photo. Android saves into the phone's gallery (Pictures/EasyCraft; Godot writes shared
## storage through MediaStore, no permission needed on Android 10+), else into the app's own folder;
## desktop saves into user://photos.

const PREFIX := "EasyCraft_"
const EXTENSION := ".png"
const ALBUM := "EasyCraft"
const APP_FOLDER := "user://photos"


static func base_name(t: Dictionary) -> String:
	return PREFIX + "%04d%02d%02d_%02d%02d%02d" % [int(t.get("year", 0)), int(t.get("month", 0)), int(t.get("day", 0)),
		int(t.get("hour", 0)), int(t.get("minute", 0)), int(t.get("second", 0))]


## `folder`/EasyCraft_<timestamp>.png, or with _2, _3 ... when a photo of that second exists.
static func unique_path(folder: String, t: Dictionary, exists: Callable) -> String:
	var base := base_name(t)
	var path := folder.path_join(base + EXTENSION)
	var n := 2
	while exists.call(path):
		path = folder.path_join("%s_%d%s" % [base, n, EXTENSION])
		n += 1
	return path


## Folders to try, in order. `pictures_dir` is OS.get_system_dir(OS.SYSTEM_DIR_PICTURES).
static func folders(is_android: bool, pictures_dir: String) -> PackedStringArray:
	if is_android and pictures_dir != "":
		return PackedStringArray([pictures_dir.path_join(ALBUM), APP_FOLDER])
	return PackedStringArray([APP_FOLDER])


static func where_message(path: String, pictures_dir: String, is_android: bool) -> String:
	if pictures_dir != "" and path.begins_with(pictures_dir):
		return "Saved to your Gallery!"
	if is_android:
		return "Saved in the game's photo album!"
	return Lang.t("Photo saved in %s") % ProjectSettings.globalize_path(path.get_base_dir())


## M7 (spec §20.3): in a browser a photo is kept in the game, not written; DOWNLOAD offers it under this name.
static func download_name(t: Dictionary) -> String:
	return base_name(t) + EXTENSION


## M7: the shutter's words in a browser; `can_download`: DOWNLOAD shows (the grown-up switch allows sharing).
static func kept_message(can_download: bool) -> String:
	return "Photo taken! Tap DOWNLOAD to keep it." if can_download else "Photo taken!"


## Writes the PNG into the first folder that takes it; returns its path, or "" when none did.
static func write_png(png: PackedByteArray, into: PackedStringArray, t: Dictionary) -> String:
	for folder in into:
		if not DirAccess.dir_exists_absolute(folder):
			DirAccess.make_dir_recursive_absolute(folder)   # may fail (MediaStore needs none): the write decides
		var path := unique_path(folder, t, FileAccess.file_exists)
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			continue
		var ok := f.store_buffer(png)
		f.close()
		if ok:
			return path
	return ""
