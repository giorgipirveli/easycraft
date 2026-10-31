class_name ShortsData
extends RefCounted
## EasyCraft Shorts in the profile (owner #94, spec §5.12b; ProfileData.shorts): the Shorts this child liked (a heart,
## kept on the device and in the account's backup: no counts, no one else ever sees it) and the ones already seen (the
## feed marks them and puts new ones first). Nothing here is ever a reward: watching gives nothing.
## - liked: {id: unix seconds}, positive when the heart was given, negative when it was taken back (so a backup's
##   merge keeps the newest choice for each Short: merge_from).
## - seen: ids, oldest first.

const MAX_LIKED := 400
const MAX_SEEN := 1500

var liked := {}
var seen: Array[String] = []

static var _id := RegEx.create_from_string("^[a-z0-9_.:]{2,64}$")


## A Short's id: a hand-made one ("rocket_parts") or a Lesson in a minute's ("lesson:g4.science.circuits").
static func valid_id(id: Variant) -> bool:
	return id is String and _id.search(id) != null


func is_empty() -> bool:
	return liked.is_empty() and seen.is_empty()


func is_liked(id: String) -> bool:
	return int(liked.get(id, 0)) > 0


## Gives `id` a heart at `now` (unix seconds); false for a bad id.
func like(id: String, now: int) -> bool:
	if not valid_id(id):
		return false
	liked[id] = maxi(now, 1)
	_trim_liked()
	return true


func unlike(id: String, now: int) -> void:
	if valid_id(id):
		liked[id] = -maxi(now, 1)
		_trim_liked()


## The heart: on when it was off, off when it was on. Returns whether it is on now.
func toggle_like(id: String, now: int) -> bool:
	if is_liked(id):
		unlike(id, now)
		return false
	return like(id, now)


## The liked Shorts, the newest heart first.
func liked_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in liked:
		if int(liked[id]) > 0:
			ids.append(id)
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(liked[a]) > int(liked[b]) or (int(liked[a]) == int(liked[b]) and a < b))
	return ids


func is_seen(id: String) -> bool:
	return seen.has(id)


func mark_seen(id: String) -> void:
	if not valid_id(id) or seen.has(id):
		return
	seen.append(id)
	if seen.size() > MAX_SEEN:
		seen = seen.slice(seen.size() - MAX_SEEN)


## A Short that is no more (a child deleted their own: MAKE MY SHORT): its heart and seen mark go.
func forget(id: String) -> void:
	liked.erase(id)
	seen.erase(id)


## Another copy's (a backup's): every Short seen in either is seen; each heart is the one given or taken back last.
func merge_from(other: ShortsData) -> void:
	for id: String in other.liked:
		var theirs := int(other.liked[id])
		if absi(theirs) > absi(int(liked.get(id, 0))):
			liked[id] = theirs
	_trim_liked()
	for id in other.seen:
		mark_seen(id)


func to_dict() -> Dictionary:
	return {"liked": liked.duplicate(), "seen": seen.duplicate()}


static func from_dict(v: Variant) -> ShortsData:
	var d := ShortsData.new()
	if not v is Dictionary:
		return d
	var hearts: Variant = (v as Dictionary).get("liked")
	if hearts is Dictionary:
		for id: Variant in hearts:
			var t: Variant = hearts[id]
			if valid_id(id) and typeof(t) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(t)) and absf(float(t)) >= 1.0 \
					and absf(float(t)) < 1e12:
				d.liked[id] = int(t)
	d._trim_liked()
	var list: Variant = (v as Dictionary).get("seen")
	if list is Array:
		for id: Variant in list:
			if valid_id(id):
				d.mark_seen(id)
	return d


## At most MAX_LIKED hearts (given or taken back): the oldest go first.
func _trim_liked() -> void:
	if liked.size() <= MAX_LIKED:
		return
	var ids: Array = liked.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return absi(int(liked[a])) < absi(int(liked[b])))
	for i in liked.size() - MAX_LIKED:
		liked.erase(ids[i])
