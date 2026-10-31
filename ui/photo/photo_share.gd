class_name PhotoShare
extends RefCounted
## Sharing a photo (M3 Task 16) without a custom Android plugin. Godot 4.7's Android library already
## declares a FileProvider (authority "<package>.fileprovider", paths: the app's files dir, external
## storage and the external files dir), which OS.shell_open uses for local files. Here:
## 1. the Android share sheet: an ACTION_SEND intent built with JavaClassWrapper (Godot 4.4+) around
##    a FileProvider content:// URI of a copy in the app's own storage (readable on every Android);
## 2. if any step of that fails: OS.shell_open(file), Godot's own FileProvider + ACTION_VIEW path,
##    which opens the photo in the gallery viewer, whose own Share button does the rest.
## Desktop has no share sheet: it opens the photos folder. Not verifiable headless or by agents; see
## docs/devlog/parts/m3-task-16.md for what the emulator check covers. M7 (spec §20.3): a browser offers the photo as
## a file download (WebGlue.download); the way is PlatformRules.photo_save.

const MIME := "image/png"
const ACTION_SEND := "android.intent.action.SEND"
const EXTRA_STREAM := "android.intent.extra.STREAM"
const FLAG_GRANT_READ_URI_PERMISSION := 1
const FLAG_ACTIVITY_NEW_TASK := 0x10000000
## The copy that is shared: in the app's files dir, which the FileProvider always covers.
const SHARE_COPY := "user://photo_share.png"


static func authority(package_name: String) -> String:
	return package_name + ".fileprovider"


## The chip beside the shutter, for the way photos go here (PlatformRules.photo_save).
static func button_label(way: StringName) -> String:
	match way:
		PlatformRules.PHOTO_GALLERY:
			return "SHARE"
		PlatformRules.PHOTO_DOWNLOAD:
			return "DOWNLOAD"
	return "FOLDER"


## Shares the PNG bytes of the last photo. Returns what happened, for the message on screen:
## &"sheet" (the share sheet opened), &"viewer" (the photo opened in the gallery viewer),
## &"folder" (desktop: the folder opened), &"download" (a browser offered the file) or &"" (nothing worked).
## `way`: PlatformRules.photo_save (&"": this device's).
static func share(png: PackedByteArray, saved_path: String, way: StringName = &"") -> StringName:
	if way == &"":
		way = PlatformRules.photo_save(PlatformRules.current())
	if way == PlatformRules.PHOTO_DOWNLOAD:
		return &"download" if WebGlue.download(png, saved_path.get_file(), MIME) else &""
	if way != PlatformRules.PHOTO_GALLERY:
		var err := OS.shell_open(ProjectSettings.globalize_path(saved_path.get_base_dir()))
		return &"folder" if err == OK else &""
	var f := FileAccess.open(SHARE_COPY, FileAccess.WRITE)
	if f == null:
		return &""
	var ok := f.store_buffer(png)
	f.close()
	var copy := ProjectSettings.globalize_path(SHARE_COPY)
	if ok and _share_sheet(copy):
		return &"sheet"
	return &"viewer" if OS.shell_open(copy if ok else saved_path) == OK else &""


static func _share_sheet(path: String) -> bool:
	if not Engine.has_singleton("AndroidRuntime"):
		return false
	var runtime: Object = Engine.get_singleton("AndroidRuntime")
	var activity = runtime.call("getActivity")
	if activity == null:
		return false
	var file_class = JavaClassWrapper.wrap("java.io.File")
	var provider_class = JavaClassWrapper.wrap("androidx.core.content.FileProvider")
	var intent_class = JavaClassWrapper.wrap("android.content.Intent")
	if file_class == null or provider_class == null or intent_class == null:
		return false
	var file = file_class.call("File", path)
	var package_name = activity.call("getPackageName")
	if file == null or not package_name is String:
		return false
	var uri = provider_class.call("getUriForFile", activity, authority(package_name), file)
	var send = intent_class.call("Intent", ACTION_SEND)
	if uri == null or send == null:
		return false
	send.call("setType", MIME)
	send.call("putExtra", EXTRA_STREAM, uri)
	send.call("addFlags", FLAG_GRANT_READ_URI_PERMISSION)
	var chooser = intent_class.call("createChooser", send, "Share your photo")
	if chooser == null:
		chooser = send
	chooser.call("addFlags", FLAG_GRANT_READ_URI_PERMISSION | FLAG_ACTIVITY_NEW_TASK)
	activity.call("startActivity", chooser)
	return true
