class_name PlanetGuideRules
extends RefCounted
## Owner #88: "what should i do after i land on mercury, there should be some guides". A space world's explorer's
## checklist: its big sights (SpaceShape.sights(): where; the descriptor's sights: their names), nearest to the landing
## first, each ticked once found (SpaceSights keeps finds as "sight:<id>" in the world's secrets). The HUD's compass
## points to the nearest place not found yet (next); the landing card says what to explore (intro), each find how many
## are found and which is next (progress_words).


## [{id, name, pos, found}], nearest to `from` first; [] for a planet without sights.
static func checklist(sights: Array[Dictionary], names: Dictionary, found: Dictionary, from: Vector3) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Dictionary in sights:
		var id: StringName = s.id
		if not names.has(id):
			continue
		out.append({"id": id, "name": str(names[id].get("name", id)), "pos": s.pos,
			"found": found.has(SpaceSights.PREFIX + String(id))})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _flat(a.pos, from) < _flat(b.pos, from))
	return out


## The nearest place not found yet ({} when all are found).
static func next(list: Array[Dictionary], from: Vector3) -> Dictionary:
	var best := {}
	for e: Dictionary in list:
		if bool(e.found):
			continue
		if best.is_empty() or _flat(e.pos, from) < _flat(best.pos, from):
			best = e
	return best


## The landing card's words.
static func intro(planet: String, list: Array[Dictionary]) -> String:
	var names: Array[String] = []
	for e: Dictionary in list:
		names.append(str(e.name).to_lower() if names.size() > 0 else str(e.name))
	return "Welcome to %s! Explore %d %s: %s. Follow the red arrow, and each place tells you a real fact." % [planet,
		list.size(), "place" if list.size() == 1 else "places", ", ".join(names)]   # spec §21c: the Moon has 1 (its colony)


## After a find: "1 of 3 found! Next: The long cliff. Follow the arrow." or "You explored all 3 places! …".
static func progress_words(list: Array[Dictionary], from: Vector3) -> String:
	var done := list.filter(func(e: Dictionary) -> bool: return bool(e.found)).size()
	if done >= list.size():
		return "You explored all %d places here! The Star Map has more planets to visit." % list.size()
	return "%d of %d found! Next: %s. Follow the arrow." % [done, list.size(), str(next(list, from).name)]


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
