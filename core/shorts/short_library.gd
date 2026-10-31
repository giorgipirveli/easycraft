class_name ShortLibrary
extends RefCounted
## Where Shorts come from (owner #94, spec §5.12b): the hand-made ones are data, `data/shorts/<id>.json`, listed in the
## feed's order in `data/shorts/shorts.json` ({"shorts": [ids]}); a Lesson in a minute ("lesson:<unit id>") is made
## from its School unit when it is first asked for (LessonShort). Both are kept once made (clear_cache for tests); a
## broken or missing file gives {} and the feed leaves it out.

const DIR := "res://data/shorts"
const INDEX := "res://data/shorts/shorts.json"
const CINEMATIC := "res://data/shorts/cinematic"
## Lessons in a minute kept at once (the feed asks for the one on the screen and its neighbours).
const KEEP_LESSONS := 8

static var _index: Array[String] = []
static var _hand := {}              # id -> its Short ({} when broken)
static var _lessons := {}           # id -> its Short
static var _lesson_order: Array[String] = []


## The hand-made Shorts' ids, in the feed's order.
static func hand_ids() -> Array[String]:
	if _index.is_empty():
		var d: Variant = _read(INDEX)
		if d is Dictionary and (d as Dictionary).get("shorts") is Array:
			for id: Variant in d.shorts:
				if id is String and not _index.has(id):
					_index.append(id)
	return _index


## A hand-made Short by id ({} when missing or broken): `data/shorts/<id>.json`, or a cinematic reel's
## (`data/shorts/cinematic/<id>.json`: the Reel Studio's, owner #96).
static func hand(id: String) -> Dictionary:
	if not _hand.has(id):
		var d: Variant = _read(DIR.path_join(id + ".json"))
		if d == null:
			d = _read(CINEMATIC.path_join(id + ".json"))
		_hand[id] = d if d is Dictionary and str((d as Dictionary).get("id", "")) == id else {}
	return _hand[id]


## Any Short by id: hand-made, or a Lesson in a minute made now (the last KEEP_LESSONS are kept).
static func get_short(id: String) -> Dictionary:
	if id.begins_with(LessonShort.PREFIX):
		if not _lessons.has(id):
			_lessons[id] = LessonShort.make(LessonShort.unit_of(id))
			_lesson_order.append(id)
			while _lesson_order.size() > KEEP_LESSONS:
				_lessons.erase(_lesson_order.pop_front())
		return _lessons[id]
	return hand(id)


static func clear_cache() -> void:
	_index.clear()
	_hand.clear()
	_lessons.clear()
	_lesson_order.clear()


static func _read(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return json.data
