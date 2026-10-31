class_name PlayQuests
extends RefCounted
## Owner #122 (docs/design/learning-is-play.md §4 "use it in the world", rule 6): the world tasks a child took with them
## from a unit's end (TAKE IT WITH ME), as quest cards on DISCOVER's map (MY QUESTS). Kept on this device only, in FILE:
## each card is the unit's id, the task's words (the game's own) and whether it is done: nothing personal, nothing sent,
## not in the profile's backup. Newest first, at most MAX (a full list lets the oldest done card go first, else the
## oldest).

const FILE := "user://play_quests.json"
const MAX := 24

var path := FILE
## {unit, task, done}, newest first.
var cards: Array[Dictionary] = []


static func open_at(file: String = FILE) -> PlayQuests:
	var q := PlayQuests.new()
	q.path = file
	if not FileAccess.file_exists(file):
		return q
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(file)) != OK or not json.data is Dictionary:
		return q
	for c: Variant in (json.data as Dictionary).get("cards", []):
		if c is Dictionary and str((c as Dictionary).get("unit", "")) != "" and q.cards.size() < MAX:
			q.cards.append({"unit": str(c.unit), "task": str(c.get("task", "")), "done": c.get("done") is bool and c.done})
	return q


## Takes a unit's world task with the child (to the front; once each).
func take(unit: String, task: String) -> void:
	for i in cards.size():
		if str(cards[i].unit) == unit:
			cards.remove_at(i)
			break
	cards.push_front({"unit": unit, "task": task, "done": false})
	while cards.size() > MAX:
		var gone := -1
		for i in range(cards.size() - 1, -1, -1):
			if bool(cards[i].done):
				gone = i
				break
		cards.remove_at(gone if gone >= 0 else cards.size() - 1)


func tick(unit: String) -> void:
	for c in cards:
		if str(c.unit) == unit:
			c.done = true


func has(unit: String) -> bool:
	return cards.any(func(c: Dictionary) -> bool: return str(c.unit) == unit)


func open_cards() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in cards:
		if not bool(c.done):
			out.append(c)
	return out


func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"cards": cards}))
	f.close()
