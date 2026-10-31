class_name MemoryRules
extends RefCounted
## The Memory Book's moments (M3 Task 21b; research R2, C5): the child's big moments, collected by themselves,
## each once — the first buddy woken, the first pet, the first night got through, every boss beaten, every new
## universe reached, playing with a friend, a Secret Book page done, levels 5 and 10... A moment keeps its date
## and, when the child took a photo soon after it (photo mode's files), that photo. Pure; MemoryBook keeps them
## on this device.

const MAX := 64
## A photo taken this long (seconds) after a moment goes with it (the newest moment still without one).
const PHOTO_WINDOW := 600
## The levels worth a memory.
const LEVELS: Array[int] = [5, 10, 20]
## Moments from counted events (Progress.counted): the kind (a family, or a family with its detail) that makes
## it, the words, the picture (ProgressPictures).
const MOMENTS: Array[Dictionary] = [
	{"id": &"first_buddy", "kind": &"buddy_woken", "words": "I woke up my first buddy!", "picture": &"wand"},
	{"id": &"first_pet", "kind": &"animal_tamed", "words": "I made a pet friend!", "picture": &"dog"},
	{"id": &"first_secret", "kind": &"secret_found", "words": "I found my first secret!", "picture": &"chest"},
	{"id": &"first_geode", "kind": &"secret_found/geode", "words": "I found a crystal geode!", "picture": &"geode"},
	{"id": &"first_monster", "kind": &"monster_defeated", "words": "I beat my first monster!", "picture": &"monster"},
	{"id": &"first_wave", "kind": &"wave_won", "words": "We won a Totem wave!", "picture": &"totem"},
	{"id": &"first_friend", "kind": &"friend_played", "words": "I played with a friend!", "picture": &"friends"},
	{"id": &"first_race", "kind": &"race_finished", "words": "I finished my first race!", "picture": &"flag"},
	{"id": &"first_ride", "kind": &"buddy_ridden", "words": "I rode on my buddy!", "picture": &"ride"},
	{"id": &"first_story", "kind": &"quest_done", "words": "I finished a story quest!", "picture": &"scroll"},
	{"id": &"first_craft", "kind": &"item_crafted", "words": "I crafted something!", "picture": &"table"},
	{"id": &"first_photo", "kind": &"photo_taken", "words": "My very first photo!", "picture": &"photo"},
]
## The first night got through in Survivor (MemoryDirector watches the sky).
const NIGHT := &"first_night"
const NIGHT_WORDS := "I made it through my first night!"
## "boss_<kind>": every boss (BossRules kinds) — "We beat the <name>!".
const BOSS_NAMES := {&"golem": "the Stone Golem", &"serpent": "the Sand Serpent", &"giant": "the Frost Giant",
	&"cake": "the Cake Monster", &"sky_dragon": "the Sky Dragon"}
const BOSS_PICTURES := {&"golem": &"golem", &"serpent": &"serpent", &"giant": &"giant", &"cake": &"cake",
	&"sky_dragon": &"dragon"}
const MONTHS: Array[String] =["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]


## The moments a counted event makes (its full kind, or its family).
static func for_event(kind: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	var family := LevelRules.family(kind)
	for m in MOMENTS:
		if m.kind == kind or m.kind == family:
			out.append(m.id)
	var s := String(kind)
	if family == LevelRules.BOSS and s.contains("/"):
		var boss := StringName(s.get_slice("/", 1))
		if _is_word(String(boss)):
			out.append(StringName("boss_" + String(boss)))
	return out


static func moment(id: StringName) -> Dictionary:
	for m in MOMENTS:
		if m.id == id:
			return m
	return {}


## Whether `id` is a moment: a MOMENTS row, the first night, "boss_<kind>", "universe_<u>" (u ≥ 2: the first is
## home), "page_<BookPages id>", "level_<LEVELS>".
static func is_moment(id: StringName) -> bool:
	var s := String(id)
	if not moment(id).is_empty() or id == NIGHT:
		return true
	if s.begins_with("boss_"):
		return _is_word(s.substr(5))
	if s.begins_with("universe_"):
		var u := s.substr(9)
		return u.is_valid_int() and u.to_int() >= 2 and u.to_int() <= UniverseRules.MAX_UNIVERSE
	if s.begins_with("page_"):
		return BookPages.is_page(s.substr(5))
	if s.begins_with("level_"):
		var n := s.substr(6)
		return n.is_valid_int() and LEVELS.has(n.to_int())
	return false


## A moment's words in the game's language (M3 Task 21a: the English is the key; whole sentences, no English
## article glued on: a new world's name follows a colon).
static func words_of(id: StringName) -> String:
	if not is_moment(id):
		return ""
	var m := moment(id)
	if not m.is_empty():
		return Lang.t(str(m.words))
	var s := String(id)
	if id == NIGHT:
		return Lang.t(NIGHT_WORDS)
	if s.begins_with("boss_"):
		return Lang.t("We beat %s!") % Lang.t(str(BOSS_NAMES.get(StringName(s.substr(5)), "a big boss")))
	if s.begins_with("universe_"):
		return Lang.t("I found a new world: %s!") % Lang.t(UniverseRegistry.display_name(s.substr(9).to_int()))
	if s.begins_with("page_"):
		return Lang.t("I finished a page of my Secret Book!")
	return Lang.t("I reached level %d!") % s.substr(6).to_int()


static func picture_of(id: StringName) -> StringName:
	var m := moment(id)
	if not m.is_empty():
		return m.picture
	var s := String(id)
	if id == NIGHT:
		return &"star"
	if s.begins_with("boss_"):
		return BOSS_PICTURES.get(StringName(s.substr(5)), &"trophy")
	if s.begins_with("universe_"):
		return &"island"
	if s.begins_with("page_"):
		return BookPages.page(s.substr(5)).get("picture", &"chest")
	if s.begins_with("level_"):
		return &"level"
	return &"lock"


## "2026-09-25" for a date dictionary (Time.get_date_dict_from_system()).
static func today(t: Dictionary) -> String:
	return "%04d-%02d-%02d" % [int(t.get("year", 0)), int(t.get("month", 0)), int(t.get("day", 0))]


## Whether `date` is "YYYY-MM-DD".
static func is_date(date: String) -> bool:
	var parts := date.split("-")
	if parts.size() != 3 or date.length() != 10:
		return false
	for p in parts:
		if not p.is_valid_int():
			return false
	var month := parts[1].to_int()
	var day := parts[2].to_int()
	return month >= 1 and month <= 12 and day >= 1 and day <= 31


## "25 Sep 2026" ("" for a date that isn't one).
static func date_words(date: String) -> String:
	if not is_date(date):
		return ""
	var parts := date.split("-")
	return "%d %s %s" % [parts[2].to_int(), Lang.t(MONTHS[parts[1].to_int() - 1]), parts[0]]


## The memory a photo taken at unix time `now` goes with: the newest one still without a photo, from at most
## PHOTO_WINDOW before; &"" for none.
static func photo_target(entries: Array, now: int) -> StringName:
	var best: Dictionary = {}
	for e: Variant in entries:
		if not e is Dictionary or str((e as Dictionary).get("photo", "")) != "":
			continue
		var t := int((e as Dictionary).get("t", 0))
		if t > now or now - t > PHOTO_WINDOW:
			continue
		if best.is_empty() or t >= int(best.t):
			best = e
	return StringName(str(best.id)) if not best.is_empty() else &""


static func _is_word(s: String) -> bool:
	if s == "" or s.length() > 24:
		return false
	for c in s:
		if not (c == "_" or (c >= "a" and c <= "z") or (c >= "0" and c <= "9")):
			return false
	return true
