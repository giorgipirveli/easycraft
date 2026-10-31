class_name ShortFeed
extends RefCounted
## EasyCraft Shorts' feed (owner #94, spec §5.12b): never an endless algorithm, an order that teaches. Three lists:
## - HAND: the hand-made Shorts (ShortLibrary's order: how to build a rocket first);
## - LESSONS: a grade's Lessons in a minute, subject by subject in the School's order, unit by unit (not the Explorer
##   lessons, which a child opens with gold: their lesson is not given away);
## - LIKED: the child's hearts, the newest first;
## - MINE: the child's own Shorts (MAKE MY SHORT, spec §5.12b "As built (My Shorts)": MyShortsData, on this device), the
##   newest first; an entry carries its recipe and its Short is made when it plays (short_of: MyShortMaker).
## arrange(): a topic's Shorts stay together in their written order, topics with a Short not seen yet come first, and
## every entry says whether it was seen. An entry: {id, title, topic, kind, link, grade?, unit?, seen?}; the Short itself
## is made only when it is watched (ShortLibrary.get_short).

const HAND := &"hand"
const LESSON := &"lesson"
const LESSONS := &"lessons"
const LIKED := &"liked"
const MINE := &"mine"
const FILTERS: Array[StringName] = [HAND, LESSONS, LIKED, MINE]
const GRADES: Array[int] = [3, 4, 5, 6, 7]


## The feed for `filter` (LESSONS: grade `grade`'s; MINE and the hearts on them: `mine`'s), in its order, each entry
## marked seen or not.
static func build(filter: StringName, grade: int, data: ShortsData, mine: MyShortsData = null) -> Array:
	match filter:
		LESSONS:
			return arrange(lesson_entries(grade), data)
		MINE:
			return mine_entries(mine, data)
		LIKED:
			var out: Array = []
			for id in data.liked_ids():
				var e := entry_for(id, mine)
				if not e.is_empty():
					e.seen = data.is_seen(id)
					out.append(e)
			return out
	return arrange(hand_entries(), data)


static func hand_entries() -> Array:
	var out: Array = []
	for id in ShortLibrary.hand_ids():
		var e := entry_for(id)
		if not e.is_empty():
			out.append(e)
	return out


## Grade `grade`'s written units (not the Explorer lessons) as Lessons in a minute, in the School's order.
static func lesson_entries(grade: int) -> Array:
	var out: Array = []
	for s in Curriculum.subjects(grade):
		for u in Curriculum.units(grade, str(s.get("id", ""))):
			if u.has("file") and not bool(u.get("bonus", false)):
				out.append(_lesson_entry(str(u.id), u, str(s.id), grade))
	return out


## The child's own Shorts, the newest first.
static func mine_entries(mine: MyShortsData, data: ShortsData) -> Array:
	var out: Array = []
	if mine == null:
		return out
	for r in mine.newest_first():
		var e := _mine_entry(r)
		e.seen = data.is_seen(str(e.id))
		out.append(e)
	return out


static func _mine_entry(r: Dictionary) -> Dictionary:
	var short := MyShortMaker.make(r)
	return {"id": str(r.id), "title": str(short.get("title", "")), "topic": MyShortRules.TOPIC, "kind": MINE,
		"link": short.get("link", {}), "recipe": r}


## The Short an entry plays: a child's own made from its recipe, else the library's (hand-made or a lesson).
static func short_of(entry: Dictionary) -> Dictionary:
	if entry.get("kind") == MINE:
		return MyShortMaker.make(entry.get("recipe", {}))
	return ShortLibrary.get_short(str(entry.get("id", "")))


## One entry by the Short's id ({} when there is no such Short; a child's own needs `mine`).
static func entry_for(id: String, mine: MyShortsData = null) -> Dictionary:
	if MyShortRules.is_mine_id(id):
		return _mine_entry(mine.recipe(id)) if mine != null and mine.has(id) else {}
	var unit_id := LessonShort.unit_of(id)
	if unit_id != "":
		var u := Curriculum.unit(unit_id)
		if u.is_empty() or not u.has("file"):
			return {}
		return _lesson_entry(unit_id, u, str(u.subject), int(u.grade))
	var s := ShortLibrary.hand(id)
	if s.is_empty():
		return {}
	return {"id": id, "title": str(s.get("title", "")), "topic": str(s.get("topic", "")), "kind": HAND,
		"link": s.get("link", {})}


static func _lesson_entry(unit_id: String, u: Dictionary, subject: String, grade: int) -> Dictionary:
	return {"id": LessonShort.id_for(unit_id), "title": str(u.get("title", "")), "topic": subject, "kind": LESSON,
		"grade": grade, "unit": unit_id, "link": {ShortRules.LINK_UNIT: unit_id}}


## A topic's entries together (in the order they first come), topics with a Short not seen yet first, each marked.
static func arrange(entries: Array, data: ShortsData) -> Array:
	var topics: Array[String] = []
	var groups := {}
	for e: Dictionary in entries:
		var t := str(e.get("topic", ""))
		if not groups.has(t):
			groups[t] = []
			topics.append(t)
		var copy := e.duplicate()
		copy.seen = data.is_seen(str(e.id))
		(groups[t] as Array).append(copy)
	var fresh: Array = []
	var done: Array = []
	for t in topics:
		var all_seen := true
		for e: Dictionary in groups[t]:
			all_seen = all_seen and bool(e.seen)
		(done if all_seen else fresh).append_array(groups[t])
	return fresh + done


## Where the feed starts: the first Short not seen yet (the top when all were seen).
static func start_index(feed: Array) -> int:
	for i in feed.size():
		if not bool(feed[i].get("seen", false)):
			return i
	return 0
