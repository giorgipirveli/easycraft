class_name PlayTime
extends RefCounted
## Play time per day on this device (M4 Wave 2, agent F; spec §5.14 "parent corner: play time",
## §17.2 "see play time"): seconds per local date, for the grown-up area. Kept only on the device, in
## its own file (never profile.json or the server: nothing about a child's habits leaves the phone).
## PlayClock (a node under Session) adds the time the game is open and in front.

const PATH := "user://play_time.json"
const KEEP_DAYS := 7
## One step never counts more than this (a phone that slept with the game open counts nothing).
const MAX_STEP := 5.0
const _DATE := "^\\d{4}-\\d{2}-\\d{2}$"

var days := {}   # "YYYY-MM-DD" -> seconds (float)


## Today's local date, as the days are kept.
static func today() -> String:
	return Time.get_date_string_from_system()


func add(seconds: float, day: String) -> void:
	if not is_finite(seconds) or seconds <= 0.0:
		return
	days[day] = float(days.get(day, 0.0)) + minf(seconds, MAX_STEP)
	if days.size() > KEEP_DAYS:
		var keys := days.keys()
		keys.sort()
		for i in keys.size() - KEEP_DAYS:
			days.erase(keys[i])


func seconds_on(day: String) -> int:
	return int(days.get(day, 0.0))


func minutes_on(day: String) -> int:
	return int(seconds_on(day) / 60.0)


## "42 minutes", "2 hours 5 minutes" (for a grown-up).
static func words(minutes: int) -> String:
	if minutes <= 0:
		return "Less than a minute"
	var h := int(minutes / 60.0)
	var m := minutes % 60
	var parts: Array[String] = []
	if h > 0:
		parts.append(Lang.t("%d hour%s") % [h, Lang.plural_s(h)])
	if m > 0:
		parts.append(Lang.t("%d minute%s") % [m, Lang.plural_s(m)])
	return " ".join(parts)


static func load_from(path: String = PATH) -> PlayTime:
	return from_json(JsonStore.read_text(path))


func save_to(path: String = PATH) -> Error:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	return JsonStore.write_atomic(path, to_json())


static func from_json(text: String) -> PlayTime:
	var t := PlayTime.new()
	var json := JSON.new()
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return t
	var d: Variant = (json.data as Dictionary).get("days")
	if not (d is Dictionary):
		return t
	var date := RegEx.create_from_string(_DATE)
	for day: Variant in d:
		var s: Variant = d[day]
		if day is String and date.search(day) != null and typeof(s) in [TYPE_INT, TYPE_FLOAT] \
				and is_finite(float(s)) and float(s) > 0.0:
			t.days[day] = minf(float(s), 86400.0)
	return t


func to_json() -> String:
	return JSON.stringify({"days": days})
