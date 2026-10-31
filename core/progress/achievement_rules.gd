class_name AchievementRules
extends RefCounted
## Badges for the trophy room (M3 Task 12, spec §14.11, research C5): each unlocked once by play, with
## a picture and a few words. None is for logging in or for time played.

## A badge's kind for "reach level N" (the need is the level).
const LEVEL := &"level"

const BADGES: Array[Dictionary] = [
	{"id": &"first_buddy", "kind": &"buddy_woken", "need": 1, "words": "First buddy!", "picture": &"wand"},
	{"id": &"buddy_crew", "kind": &"buddy_woken", "need": 10, "words": "10 buddies woken!", "picture": &"wand"},
	{"id": &"first_pet", "kind": &"animal_tamed", "need": 1, "words": "First pet!", "picture": &"dog"},
	{"id": &"first_secret", "kind": &"secret_found", "need": 1, "words": "First secret!", "picture": &"question"},
	{"id": &"crystal_cave", "kind": &"secret_found/geode", "need": 1, "words": "Crystal geode!", "picture": &"geode"},
	{"id": &"treasure_digger", "kind": &"secret_found/treasure", "need": 1, "words": "Treasure digger!", "picture": &"chest"},
	{"id": &"golden_catch", "kind": &"secret_found/golden", "need": 1, "words": "Golden catch!", "picture": &"golden"},
	{"id": &"met_wanderer", "kind": &"secret_found/wanderer", "need": 1, "words": "Met the Wanderer!", "picture": &"wanderer"},
	{"id": &"star_catcher", "kind": &"secret_found/star", "need": 1, "words": "Caught a star!", "picture": &"star"},
	{"id": &"secret_expert", "kind": &"secret_found", "need": 10, "words": "10 secrets!", "picture": &"chest"},
	{"id": &"first_monster", "kind": &"monster_defeated", "need": 1, "words": "First monster!", "picture": &"monster"},
	{"id": &"monster_buster", "kind": &"monster_defeated", "need": 50, "words": "50 monsters!", "picture": &"goblin"},
	{"id": &"totem_hero", "kind": &"wave_won", "need": 1, "words": "First wave won!", "picture": &"totem"},
	{"id": &"wave_master", "kind": &"wave_won", "need": 5, "words": "5 waves won!", "picture": &"totem"},
	{"id": &"golem", "kind": &"boss_beaten", "need": 1, "words": "Golem beaten!", "picture": &"golem"},
	{"id": &"builder", "kind": &"block_placed", "need": 100, "words": "100 blocks!", "picture": &"brick"},
	{"id": &"big_builder", "kind": &"block_placed", "need": 1000, "words": "1,000 blocks!", "picture": &"brick"},
	{"id": &"say_cheese", "kind": &"photo_taken", "need": 1, "words": "Say cheese!", "picture": &"photo"},
	{"id": &"explorer", "kind": &"area_explored", "need": 20, "words": "20 new places!", "picture": &"map"},
	{"id": &"together", "kind": &"friend_played", "need": 1, "words": "Played together!", "picture": &"friends"},
	{"id": &"first_race", "kind": &"race_finished", "need": 1, "words": "First race!", "picture": &"flag"},
	{"id": &"goal_getter", "kind": &"goal_done", "need": 5, "words": "5 goals done!", "picture": &"board"},
	{"id": &"level_5", "kind": LEVEL, "need": 5, "words": "Level 5!", "picture": &"level"},
	{"id": &"level_10", "kind": LEVEL, "need": 10, "words": "Level 10!", "picture": &"level"},
]


static func badge(id: StringName) -> Dictionary:
	for b: Dictionary in BADGES:
		if b.id == id:
			return b
	return {}


## Vector2i(how far, needed) toward a badge.
static func progress(d: ProgressData, id: StringName) -> Vector2i:
	var b := badge(id)
	if b.is_empty():
		return Vector2i.ZERO
	var have := d.level() if b.kind == LEVEL else d.count(b.kind)
	return Vector2i(mini(have, int(b.need)), int(b.need))


## Unlocks every badge that reached its number and returns the new ones (each once, in list order).
static func check(d: ProgressData) -> Array[StringName]:
	var out: Array[StringName] = []
	for b: Dictionary in BADGES:
		if d.achievements.has(String(b.id)):
			continue
		var p := progress(d, b.id)
		if p.x >= p.y:
			d.achievements.append(String(b.id))
			out.append(b.id)
	return out


static func unlocked_count(d: ProgressData) -> int:
	var n := 0
	for id in d.achievements:
		if not badge(StringName(id)).is_empty():
			n += 1
	return n
