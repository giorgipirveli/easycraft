class_name JsonStore
extends RefCounted
## Crash-safe JSON text files.
## Write: text that is not a JSON object is refused (a NaN saves as "nan", which would leave an
## unreadable file and, one save later, an unreadable backup); <path>.tmp is written and read back
## (a full disk must never replace a good file), the current file becomes <path>.bak, then the temp
## file is renamed over <path>.
## Read: the first of <path>, <path>.bak that parses as a JSON object.


static func write_atomic(path: String, text: String) -> Error:
	if not _is_object(text):
		push_warning("JsonStore: refused to save %s, the text is not a JSON object" % path)
		return ERR_INVALID_DATA
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	var stored := f.store_string(text)
	f.flush()
	f.close()
	if not stored or FileAccess.get_file_as_string(tmp) != text:
		DirAccess.remove_absolute(_abs(tmp))
		return ERR_FILE_CANT_WRITE
	if FileAccess.file_exists(path):
		DirAccess.rename_absolute(_abs(path), _abs(path + ".bak"))
	return DirAccess.rename_absolute(_abs(tmp), _abs(path))


## Returns "" when neither the file nor its backup holds a JSON object.
static func read_text(path: String) -> String:
	for candidate in [path, path + ".bak"]:
		if FileAccess.file_exists(candidate):
			var text := FileAccess.get_file_as_string(candidate)
			if _is_object(text):
				return text
	return ""


static func _is_object(text: String) -> bool:
	var json := JSON.new()   # not JSON.parse_string: that logs an engine error on bad text
	return json.parse(text) == OK and typeof(json.data) == TYPE_DICTIONARY


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)
