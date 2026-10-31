class_name MyShortsData
extends RefCounted
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): the Shorts this child made, in the profile (ProfileData.my_shorts)
## on this device only: ProfileBackup leaves the whole field out of the account's server backup (DEVICE_ONLY_FIELDS),
## and a merge with the server's copy keeps this device's. Each is a small recipe (MyShortRules.clean_recipe) with its
## id ("mine:<n>", never used twice: a heart or a seen mark can't jump to a new Short) and when it was made; the photos
## and stamp copies it shows are files in the album beside it (MyShortAlbum), never in the profile. At most
## MyShortRules.MAX_SHORTS. Nothing here is ever counted or rewarded.

## The recipes, in the order they were made.
var shorts: Array[Dictionary] = []
## The next Short's number.
var next_id := 1


func is_empty() -> bool:
	return shorts.is_empty()


func count() -> int:
	return shorts.size()


func is_full() -> bool:
	return shorts.size() >= MyShortRules.MAX_SHORTS


## Keeps a new Short made at `now` (unix seconds): its id, or "" when the list is full or the recipe can't be made.
func add(recipe: Dictionary, now: int) -> String:
	if is_full():
		return ""
	var r := MyShortRules.clean_recipe(recipe)
	if r.is_empty():
		return ""
	r.id = MyShortRules.id_for(next_id)
	r.made = maxi(now, 0)
	next_id += 1
	shorts.append(r)
	return str(r.id)


## The Short `id` made again from `recipe` (CHANGE): false for no such Short or a recipe that can't be made.
func replace(id: String, recipe: Dictionary, _now: int) -> bool:
	var i := _index(id)
	var r := MyShortRules.clean_recipe(recipe)
	if i < 0 or r.is_empty():
		return false
	r.id = id
	r.made = int(shorts[i].get("made", 0))
	shorts[i] = r
	return true


func remove(id: String) -> bool:
	var i := _index(id)
	if i < 0:
		return false
	shorts.remove_at(i)
	return true


func has(id: String) -> bool:
	return _index(id) >= 0


## Short `id`'s recipe ({} for none).
func recipe(id: String) -> Dictionary:
	var i := _index(id)
	return shorts[i] if i >= 0 else {}


## The newest first (made last: the highest id).
func newest_first() -> Array[Dictionary]:
	var out := shorts.duplicate()
	out.reverse()
	return out


## Every album file a kept Short shows (its photos, its stamp's copy): the album never throws these away.
func files() -> Array[String]:
	var out: Array[String] = []
	for r in shorts:
		for f: String in r.get("photos", []):
			if not out.has(f):
				out.append(f)
		var build: Dictionary = r.get("build", {})
		if build.get("kind") == "stamp" and not out.has(str(build.file)):
			out.append(str(build.file))
	return out


func to_dict() -> Dictionary:
	return {"next": next_id, "shorts": shorts.duplicate(true)}


static func from_dict(v: Variant) -> MyShortsData:
	var d := MyShortsData.new()
	if not v is Dictionary:
		return d
	var list: Variant = (v as Dictionary).get("shorts")
	var highest := 0
	if list is Array:
		for item: Variant in list:
			if d.is_full():
				break
			var r := MyShortRules.clean_recipe(item)
			if r.is_empty() or not r.has("id") or d.has(str(r.id)):
				continue
			if not r.has("made"):
				r.made = 0
			d.shorts.append(r)
			highest = maxi(highest, int(str(r.id).trim_prefix(MyShortRules.PREFIX)))
	var next: Variant = (v as Dictionary).get("next")
	var n := int(next) if typeof(next) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(next)) and float(next) < 1e6 else 1
	d.next_id = maxi(maxi(n, 1), highest + 1)
	return d


func _index(id: String) -> int:
	for i in shorts.size():
		if str(shorts[i].get("id", "")) == id:
			return i
	return -1
