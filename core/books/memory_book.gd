class_name MemoryBook
extends RefCounted
## The Memory Book's pages on this device (M3 Task 21b; research R2): each moment once (MemoryRules), with its
## date ("YYYY-MM-DD"), when it happened (unix seconds, to match a photo taken soon after) and its photo's
## file name (a small copy of the child's photo, next to the book). Kept in its own file, never in the profile
## or its server backup, never sent anywhere. The file's JSON has a version; a broken entry is left out and
## the rest load.

const VERSION := 1
const PATH := "user://memories/memory_book.json"
const MAX_NAME := 48

static var _current: MemoryBook
static var _current_path := PATH

## {"id": String, "date": String ("" when unknown), "t": int, "photo": String (a file name, "" = none)}, in the
## order they came.
var entries: Array[Dictionary] = []


## The device's book (loaded once; tests use their own with `use`).
static func current() -> MemoryBook:
	if _current == null:
		_current = load_from(_current_path)
	return _current


static func use(book: MemoryBook, path: String = PATH) -> void:
	_current = book
	_current_path = path


static func current_path() -> String:
	return _current_path


static func save_current() -> Error:
	return current().save_to(_current_path)


## Keeps moment `id` (once): true when it is new.
func add(id: StringName, date: String, t: int) -> bool:
	if has(id) or not MemoryRules.is_moment(id) or entries.size() >= MemoryRules.MAX:
		return false
	entries.append({"id": String(id), "date": date if MemoryRules.is_date(date) else "", "t": maxi(t, 0), "photo": ""})
	return true


func has(id: StringName) -> bool:
	return _index(id) >= 0


func newest_first() -> Array[Dictionary]:
	var out := entries.duplicate()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.t) > int(b.t))
	return out


## Gives memory `id` its photo (a plain file name next to the book); false when it has one already, there is
## no such memory, or the name isn't a plain file name.
func attach_photo(id: StringName, file: String) -> bool:
	var i := _index(id)
	if i < 0 or entries[i].photo != "" or not is_file_name(file):
		return false
	entries[i].photo = file
	return true


func photo_of(id: StringName) -> String:
	var i := _index(id)
	return str(entries[i].photo) if i >= 0 else ""


## Where memory `id`'s photo is ("" for none): beside the book's file.
func photo_path(id: StringName, book_path: String = PATH) -> String:
	var f := photo_of(id)
	return book_path.get_base_dir().path_join(f) if f != "" else ""


func _index(id: StringName) -> int:
	for i in entries.size():
		if entries[i].id == String(id):
			return i
	return -1


## A plain file name of letters, digits, _ and - with ".png" (never a path).
static func is_file_name(file: String) -> bool:
	if not file.ends_with(".png") or file.length() > MAX_NAME:
		return false
	for c in file.trim_suffix(".png"):
		if not (c == "_" or c == "-" or (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or (c >= "0" and c <= "9")):
			return false
	return file.length() > 4


func to_json() -> String:
	return JSON.stringify({"version": VERSION, "entries": entries}, "\t")


static func from_json(text: String) -> MemoryBook:
	var b := MemoryBook.new()
	var json := JSON.new()   # not JSON.parse_string: that logs an engine error on bad text
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return b
	var list: Variant = (json.data as Dictionary).get("entries")
	if not list is Array:
		return b
	for e: Variant in list:
		if not e is Dictionary:
			continue
		var d: Dictionary = e
		var id := StringName(str(d.get("id", "")))
		var t: Variant = d.get("t", 0)
		var when := int(t) if typeof(t) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(t)) and float(t) > 0.0 and float(t) < 1e12 else 0
		if b.add(id, str(d.get("date", "")), when):
			var photo := str(d.get("photo", ""))
			if photo != "":
				b.attach_photo(id, photo)
	return b


static func load_from(path: String = PATH) -> MemoryBook:
	return from_json(JsonStore.read_text(path))


func save_to(path: String = PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return JsonStore.write_atomic(path, to_json())
