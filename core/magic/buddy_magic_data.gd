class_name BuddyMagicData
extends RefCounted
## What the profile keeps for buddy magic (M3 Task 20b, spec §14.21; ProfileData.buddy_magic): the secret buddy
## shapes found (BuddyRecipes), the Buddy Album (every buddy this child woke: its name, its recipe, a small
## picture of its front (BuddyPicture), the universe and the time; the newest ALBUM_MAX kept, the older ones
## summarised as a count), the bosses' mini-buddies (MiniRules: boss kind -> {name, collar, happiness}, like Pip)
## and the tricks the profile's own pets learned (Pip, the baby dragon, the minis: key -> emotes; world pets and
## buddies keep theirs in the world's save). from_dict never fails; a backup merge never loses anything.

const ALBUM_MAX := 40
const NAME_MAX := 24
const KEY_MAX := 24
const MONTHS: Array[String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

## Recipe ids found, in the order found.
var found: Array[String] = []
## {name, recipe (a BuddyRecipes id or ""), pic (BuddyPicture code or ""), u (universe), at (unix seconds)}, oldest
## first.
var album: Array[Dictionary] = []
## Album entries summarised (the oldest beyond ALBUM_MAX).
var older := 0
## Every buddy this child ever woke.
var woken := 0
## Boss kind (String) -> the mini-buddy's record (PetRules.clean_pip).
var minis := {}
## A profile pet's key ("pip", "baby_dragon", "mini_golem") -> the emotes it learned (Array of String).
var tricks := {}


func is_empty() -> bool:
	return found.is_empty() and album.is_empty() and older == 0 and woken == 0 and minis.is_empty() and tricks.is_empty()


func has_found(recipe: StringName) -> bool:
	return found.has(String(recipe))


## A secret shape found: true the first time (only known recipes).
func add_found(recipe: StringName) -> bool:
	if not BuddyRecipes.is_recipe(recipe) or has_found(recipe):
		return false
	found.append(String(recipe))
	return true


## A buddy woken: into the album (cleaned), the oldest summarised beyond ALBUM_MAX.
func add_album(buddy_name: String, recipe: StringName, pic: String, universe: int, at: int) -> void:
	woken += 1
	album.append(clean_entry({"name": buddy_name, "recipe": String(recipe), "pic": pic, "u": universe, "at": at}))
	_trim()


func _trim() -> void:
	while album.size() > ALBUM_MAX:
		album.pop_front()
		older += 1
	woken = maxi(woken, album.size() + older)


## The emotes the profile pet `key` learned.
func tricks_of(key: String) -> Array:
	return (tricks.get(key, []) as Array).duplicate()


## One more trick for the profile pet `key`: true when new.
func add_trick(key: String, emote: StringName) -> bool:
	if not _good_key(key) or not EmotePoses.has(emote):
		return false
	var list: Array = tricks.get(key, [])
	if list.has(String(emote)):
		return false
	list.append(String(emote))
	tricks[key] = list
	return true


## "Frostpeak": where an album buddy was woken.
static func where_words(entry: Dictionary) -> String:
	return Lang.t(UniverseRegistry.display_name(int(entry.get("u", 1))))


## "25 Sep": when (the device's clock; "" before any).
static func when_words(entry: Dictionary) -> String:
	var at := int(entry.get("at", 0))
	if at <= 0:
		return ""
	var d := Time.get_date_dict_from_unix_time(at)
	return "%d %s" % [int(d.day), Lang.t(MONTHS[clampi(int(d.month) - 1, 0, 11)])]


static func clean_entry(e: Dictionary) -> Dictionary:
	var n := str(e.get("name", "Buddy")).strip_edges().substr(0, NAME_MAX)
	var recipe := str(e.get("recipe", ""))
	var pic := str(e.get("pic", ""))
	var u: Variant = e.get("u", 1)
	var at: Variant = e.get("at", 0)
	return {"name": n if n != "" else "Buddy", "recipe": recipe if BuddyRecipes.is_recipe(StringName(recipe)) else "",
		"pic": pic if BuddyPicture.is_valid(pic) else "",
		"u": clampi(int(u), 1, UniverseRules.MAX_UNIVERSE) if _num(u) and float(u) >= 1.0 and float(u) <= UniverseRules.MAX_UNIVERSE else 1,
		"at": int(at) if _num(at) and float(at) > 0.0 and float(at) < 1e12 else 0}


func to_dict() -> Dictionary:
	return {"found": found.duplicate(), "album": album.duplicate(true), "older": older, "woken": woken,
		"minis": minis.duplicate(true), "tricks": tricks.duplicate(true)}


## A clean copy of a saved dictionary (anything broken is left out).
static func from_dict(v: Variant) -> BuddyMagicData:
	var m := BuddyMagicData.new()
	if not v is Dictionary:
		return m
	var d: Dictionary = v
	var f: Variant = d.get("found")
	if f is Array:
		for r: Variant in f:
			if r is String:
				m.add_found(StringName(r))
	var a: Variant = d.get("album")
	if a is Array:
		for e: Variant in a:
			if e is Dictionary and m.album.size() < ALBUM_MAX:
				m.album.append(clean_entry(e))
	var o: Variant = d.get("older")
	m.older = clampi(int(o), 0, 1_000_000) if _num(o) else 0
	var w: Variant = d.get("woken")
	m.woken = clampi(int(w), 0, 1_000_000) if _num(w) else 0
	m._trim()
	var mi: Variant = d.get("minis")
	if mi is Dictionary:
		for kind: Variant in mi:
			var rec := PetRules.clean_pip(mi[kind])
			if MiniRules.gives_mini(StringName(str(kind))) and not rec.is_empty():
				m.minis[str(kind)] = rec
	var t: Variant = d.get("tricks")
	if t is Dictionary:
		for key: Variant in t:
			var list := TrickRules.clean(t[key])
			if key is String and _good_key(key) and not list.is_empty():
				m.tricks[key] = list
	return m


## Everything the other copy has that this one lacks (a backup merge: nothing earned is ever lost).
func merge_from(other: BuddyMagicData) -> void:
	for r in other.found:
		add_found(StringName(r))
	var seen := {}
	for e in album:
		seen["%d|%s" % [int(e.at), e.name]] = true
	var extra := 0
	for e in other.album:
		if not seen.has("%d|%s" % [int(e.at), e.name]):
			album.append(e.duplicate())
			extra += 1
	album.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return int(x.at) < int(y.at))
	older = maxi(older, other.older)
	woken = maxi(woken + extra, other.woken)
	_trim()
	for kind: String in other.minis:
		if not minis.has(kind):
			minis[kind] = (other.minis[kind] as Dictionary).duplicate()
	for key: String in other.tricks:
		for emote: String in other.tricks[key]:
			add_trick(key, StringName(emote))


static func _good_key(key: String) -> bool:
	if key == "" or key.length() > KEY_MAX:
		return false
	for i in key.length():
		var c := key.unicode_at(i)
		if not ((c >= 97 and c <= 122) or c == 95):   # a-z and _
			return false
	return true


static func _num(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))
