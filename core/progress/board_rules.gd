class_name BoardRules
extends RefCounted
## The adventure board (M3 Task 12, spec §5.8, research R4; it replaces daily missions): three picture
## goals the child picks from a fixed list, each counted from the moment it is picked, never expiring.
## A goal done gives its fixed reward once (a sticker, and in Survivor a little gold for challenge and
## discovery goals, research §1.8), then the child picks a new one. No dates, timers, resets or streaks.

const SLOTS := 3
## The host pays one player's goals at most this often (a real goal takes minutes; LAN is trusted, this
## only stops a flood of claims).
const CLAIM_GAP_MS := 20_000

## Owner #45a (spec §14.17): a goal may also say where its counter can rise ("modes"; none: every mode), the
## universe it counts in ("universe"; none: anywhere) and the animal it needs in the game ("species": listed
## only once that animal exists — the #41 animals pack).
const _S := ModeRules.SANDBOX
const _V := ModeRules.SURVIVOR
const _W := ModeRules.WAVE

## Every goal: id, the event kind it counts (LevelRules), how many, its words (4 at most), its picture
## (ProgressPictures) and its Survivor gold (0: a sticker only).
const GOALS: Array[Dictionary] = [
	{"id": &"tame_dog", "kind": &"animal_tamed/dog", "need": 1, "words": "Tame a dog", "picture": &"dog", "gold": 40},
	{"id": &"tame_cat", "kind": &"animal_tamed/cat", "need": 1, "words": "Tame a cat", "picture": &"cat", "gold": 40},
	{"id": &"tame_dogs", "kind": &"animal_tamed/dog", "need": 2, "words": "Tame 2 dogs", "picture": &"dog", "gold": 80},
	{"id": &"find_geode", "kind": &"secret_found/geode", "need": 1, "words": "Find a geode", "picture": &"geode", "gold": 60},
	{"id": &"dig_treasure", "kind": &"secret_found/treasure", "need": 1, "words": "Dig up treasure", "picture": &"chest", "gold": 60},
	{"id": &"hidden_room", "kind": &"secret_found/room", "need": 1, "words": "Find a hidden room", "picture": &"room", "gold": 60},
	{"id": &"solve_temple", "kind": &"secret_found/temple", "need": 1, "words": "Solve a temple", "picture": &"temple", "gold": 80},
	{"id": &"sky_island", "kind": &"secret_found/island", "need": 1, "words": "Reach a sky island", "picture": &"island", "gold": 80},
	{"id": &"golden_catch", "kind": &"secret_found/golden", "need": 1, "words": "Catch a golden animal", "picture": &"golden", "gold": 80},
	{"id": &"find_secrets", "kind": &"secret_found", "need": 3, "words": "Find 3 secrets", "picture": &"question", "gold": 60},
	{"id": &"beat_monsters", "kind": &"monster_defeated", "need": 5, "words": "Beat 5 monsters", "picture": &"monster", "gold": 40},
	{"id": &"beat_goblins", "kind": &"monster_defeated/goblin", "need": 3, "words": "Beat 3 goblins", "picture": &"goblin", "gold": 40},
	{"id": &"win_wave", "kind": &"wave_won", "need": 1, "words": "Win a wave", "picture": &"totem", "gold": 40,
		"modes": [_S, _W]},
	{"id": &"win_waves", "kind": &"wave_won", "need": 3, "words": "Win 3 waves", "picture": &"totem", "gold": 100,
		"modes": [_S, _W]},
	{"id": &"beat_golem", "kind": &"boss_beaten/golem", "need": 1, "words": "Beat the Stone Golem", "picture": &"golem",
		"gold": 150, "modes": [_S, _W]},
	{"id": &"explore", "kind": &"area_explored", "need": 5, "words": "Explore 5 places", "picture": &"map", "gold": 40},
	{"id": &"finish_race", "kind": &"race_finished", "need": 1, "words": "Finish a race", "picture": &"flag", "gold": 40},
	{"id": &"wake_buddy", "kind": &"buddy_woken", "need": 1, "words": "Wake a buddy", "picture": &"wand", "gold": 0},
	{"id": &"wake_buddies", "kind": &"buddy_woken", "need": 3, "words": "Wake 3 buddies", "picture": &"wand", "gold": 0},
	{"id": &"build_blocks", "kind": &"block_placed", "need": 100, "words": "Place 100 blocks", "picture": &"brick", "gold": 0},
	{"id": &"take_photo", "kind": &"photo_taken", "need": 1, "words": "Take a photo", "picture": &"photo", "gold": 0},
	{"id": &"take_photos", "kind": &"photo_taken", "need": 5, "words": "Take 5 photos", "picture": &"photo", "gold": 0},
	{"id": &"play_friend", "kind": &"friend_played", "need": 1, "words": "Play with a friend", "picture": &"friends", "gold": 0},
	# Owner #45a: the Sandstorm Desert (universe 2).
	{"id": &"beat_mummies", "kind": &"monster_defeated/mummy", "need": 3, "words": "Beat 3 mummies", "picture": &"mummy",
		"gold": 60, "modes": [_V, _W]},
	{"id": &"beat_scorpions", "kind": &"monster_defeated/scorpion", "need": 3, "words": "Beat 3 scorpions",
		"picture": &"scorpion", "gold": 60, "modes": [_V, _W]},
	{"id": &"beat_serpent", "kind": &"boss_beaten/serpent", "need": 1, "words": "Beat the Sand Serpent",
		"picture": &"serpent", "gold": 200, "modes": [_W]},
	{"id": &"solve_pyramid", "kind": &"secret_found/temple", "universe": 2, "need": 1, "words": "Solve a pyramid",
		"picture": &"pyramid", "gold": 100, "modes": [_V]},
	{"id": &"explore_desert", "kind": &"area_explored", "universe": 2, "need": 5, "words": "Explore 5 desert places",
		"picture": &"map", "gold": 60, "modes": [_V]},
	{"id": &"desert_secrets", "kind": &"secret_found", "universe": 2, "need": 3, "words": "Find 3 desert secrets",
		"picture": &"question", "gold": 100, "modes": [_V]},
	# Frostpeak (universe 3).
	{"id": &"beat_yetis", "kind": &"monster_defeated/yeti", "need": 3, "words": "Beat 3 yetis", "picture": &"yeti",
		"gold": 80, "modes": [_V, _W]},
	{"id": &"beat_bats", "kind": &"monster_defeated/bat", "need": 3, "words": "Beat 3 ice bats", "picture": &"bat",
		"gold": 80, "modes": [_V, _W]},
	{"id": &"beat_giant", "kind": &"boss_beaten/giant", "need": 1, "words": "Beat the Frost Giant", "picture": &"giant",
		"gold": 300, "modes": [_W]},
	{"id": &"igloo_room", "kind": &"secret_found/room", "universe": 3, "need": 1, "words": "Room under an igloo",
		"picture": &"room", "gold": 120, "modes": [_V]},
	{"id": &"ice_temple", "kind": &"secret_found/temple", "universe": 3, "need": 1, "words": "Find the ice temple",
		"picture": &"temple", "gold": 150, "modes": [_V]},
	{"id": &"explore_frost", "kind": &"area_explored", "universe": 3, "need": 5, "words": "Explore 5 snowy places",
		"picture": &"map", "gold": 80, "modes": [_V]},
	# The Candy Kingdom (universe 4).
	{"id": &"beat_gummies", "kind": &"monster_defeated/gummy", "need": 3, "words": "Beat 3 gummy bears",
		"picture": &"gummy", "gold": 100, "modes": [_V, _W]},
	{"id": &"beat_sneakers", "kind": &"monster_defeated/sneaker", "need": 3, "words": "Beat 3 candy sneakers",
		"picture": &"sneaker", "gold": 100, "modes": [_V, _W]},
	{"id": &"beat_cake", "kind": &"boss_beaten/cake", "need": 1, "words": "Beat the Cake Monster", "picture": &"cake",
		"gold": 400, "modes": [_W]},
	{"id": &"gingerbread", "kind": &"secret_found/temple", "universe": 4, "need": 1, "words": "Find a gingerbread house",
		"picture": &"house", "gold": 200, "modes": [_V]},
	{"id": &"explore_candy", "kind": &"area_explored", "universe": 4, "need": 5, "words": "Explore 5 candy places",
		"picture": &"map", "gold": 100, "modes": [_V]},
	# Crafting (Survivor).
	{"id": &"craft_table", "kind": &"item_crafted/crafting_table", "need": 1, "words": "Make a workbench",
		"picture": &"table", "gold": 30, "modes": [_V]},
	{"id": &"craft_things", "kind": &"item_crafted", "need": 10, "words": "Craft 10 things", "picture": &"table",
		"gold": 60, "modes": [_V]},
	{"id": &"craft_stone_pick", "kind": &"item_crafted/pickaxe_stone", "need": 1, "words": "Craft a stone pickaxe",
		"picture": &"pickaxe_stone", "gold": 40, "modes": [_V]},
	{"id": &"craft_glass", "kind": &"item_crafted/glass", "need": 1, "words": "Melt sand into glass", "picture": &"glass",
		"gold": 40, "modes": [_V]},
	{"id": &"craft_iron_sword", "kind": &"item_crafted/sword_iron", "need": 1, "words": "Craft an iron sword",
		"picture": &"sword_iron", "gold": 80, "modes": [_V]},
	# Monster Wave.
	{"id": &"arena_waves", "kind": &"wave_won/arena", "need": 3, "words": "Clear 3 arena waves", "picture": &"totem",
		"gold": 60, "modes": [_W]},
	{"id": &"arena_ten", "kind": &"wave_won/arena", "need": 10, "words": "Clear 10 arena waves", "picture": &"totem",
		"gold": 150, "modes": [_W]},
	# Pets (M3 Task 11) and the #41 animals (listed once they are in the game).
	{"id": &"tame_fox", "kind": &"animal_tamed/fox", "need": 1, "words": "Tame a fox", "picture": &"fox", "gold": 60,
		"modes": [_S, _V]},
	{"id": &"tame_parrot", "kind": &"animal_tamed/parrot", "need": 1, "words": "Tame a parrot", "picture": &"parrot",
		"gold": 60, "modes": [_S, _V]},
	{"id": &"feed_pets", "kind": &"pet_fed", "need": 3, "words": "Give 3 pet treats", "picture": &"treat", "gold": 0,
		"modes": [_S, _V]},
	{"id": &"tame_three", "kind": &"animal_tamed", "need": 3, "words": "Tame 3 animals", "picture": &"dog", "gold": 80,
		"modes": [_S, _V]},
	{"id": &"tame_horse", "kind": &"animal_tamed/horse", "species": &"horse", "need": 1, "words": "Tame a horse",
		"picture": &"horse", "gold": 60, "modes": [_S, _V]},
	{"id": &"tame_camel", "kind": &"animal_tamed/camel", "species": &"camel", "need": 1, "words": "Tame a camel",
		"picture": &"camel", "gold": 60, "modes": [_S, _V]},
	{"id": &"tame_penguin", "kind": &"animal_tamed/penguin", "species": &"penguin", "need": 1, "words": "Tame a penguin",
		"picture": &"penguin", "gold": 60, "modes": [_S, _V]},
	# The #42 treasures.
	{"id": &"find_shipwreck", "kind": &"secret_found/shipwreck", "need": 1, "words": "Find a shipwreck",
		"picture": &"shipwreck", "gold": 80, "modes": [_S, _V]},
	{"id": &"open_vault", "kind": &"secret_found/vault", "need": 1, "words": "Open a dungeon vault", "picture": &"vault",
		"gold": 150, "modes": [_S, _V]},
	{"id": &"haunted_house", "kind": &"secret_found/haunted", "need": 1, "words": "Visit a haunted house",
		"picture": &"haunted", "gold": 100, "modes": [_S, _V]},
	{"id": &"wishing_well", "kind": &"secret_found/well", "need": 1, "words": "Find a wishing well", "picture": &"well",
		"gold": 40, "modes": [_S, _V]},
	{"id": &"rainbow_end", "kind": &"secret_found/rainbow", "need": 1, "words": "Reach a rainbow's end",
		"picture": &"rainbow", "gold": 60, "modes": [_S, _V]},
	{"id": &"explore_mine", "kind": &"secret_found/mineshaft", "need": 1, "words": "Explore a mineshaft",
		"picture": &"mineshaft", "gold": 60, "modes": [_S, _V]},
	# Races, building and quests.
	{"id": &"finish_races", "kind": &"race_finished", "need": 3, "words": "Finish 3 races", "picture": &"flag", "gold": 80,
		"modes": [_S, _V]},
	{"id": &"gold_medal", "kind": &"race_finished/gold", "need": 1, "words": "Win a gold medal", "picture": &"medal",
		"gold": 80, "modes": [_S, _V]},
	{"id": &"build_500", "kind": &"block_placed", "need": 500, "words": "Place 500 blocks", "picture": &"brick", "gold": 0,
		"modes": [_S, _V]},
	{"id": &"ride_buddy", "kind": &"buddy_ridden", "need": 1, "words": "Ride a buddy", "picture": &"ride", "gold": 0,
		"modes": [_S, _V]},
	{"id": &"fly_dragon", "kind": &"buddy_ridden/fly", "need": 1, "words": "Fly a buddy dragon", "picture": &"dragon",
		"gold": 0, "modes": [_S, _V]},
	{"id": &"finish_quest", "kind": &"quest_done", "need": 1, "words": "Finish a quest story", "picture": &"scroll",
		"gold": 0, "modes": [_S, _V]},
	{"id": &"explore_far", "kind": &"area_explored", "need": 20, "words": "Explore 20 places", "picture": &"map",
		"gold": 100, "modes": [_S, _V]},
]
## A new board's goals (the child can change them): easy ones, the signature magic first.
const STARTERS: Array[StringName] = [&"take_photo", &"wake_buddy", &"find_secrets"]


static func goal(id: StringName) -> Dictionary:
	for g: Dictionary in GOALS:
		if g.id == id:
			return g
	return {}


static func gold_for(id: StringName) -> int:
	return int(goal(id).get("gold", 0))


## Where a goal's counter can rise (owner #45a): its "modes", or every mode.
static func modes_of(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(goal(id).get("modes", ModeRules.MODES))
	return out


## The universe a goal counts in (0: anywhere).
static func universe_of(id: StringName) -> int:
	return int(goal(id).get("universe", 0))


## Whether a goal can be picked: known, and its animal is in the game (the #41 animals come later).
static func available(id: StringName) -> bool:
	var g := goal(id)
	return not g.is_empty() and (not g.has("species") or AnimalRules.SPECIES.has(g.species))


## How many of a goal's kind this progress has, where the goal counts.
static func _count(d: ProgressData, g: Dictionary) -> int:
	return d.count_in(g.kind, int(g.get("universe", 0)))


static func empty_slot() -> Dictionary:
	return {"goal": "", "start": 0, "done": false}


## The board has its three slots; the very first time, the starter goals.
static func ensure_board(d: ProgressData) -> void:
	d.board = clean_board(d.board)
	if d.board_set:
		return
	for i in SLOTS:
		d.board[i] = {"goal": String(STARTERS[i]), "start": _count(d, goal(STARTERS[i])), "done": false}
	d.board_set = true


## Three slots from saved data: a known goal (once on the board) with a whole start of 0 or more.
static func clean_board(v: Variant) -> Array:
	var out: Array = []
	var seen := {}
	var src: Array = v if v is Array else []
	for i in SLOTS:
		var slot := empty_slot()
		var e: Variant = src[i] if i < src.size() else null
		if e is Dictionary:
			var id: Variant = e.get("goal")
			if id is String and not goal(StringName(id)).is_empty() and not seen.has(id):
				seen[id] = true
				slot.goal = id
				var s: Variant = e.get("start")
				slot.start = maxi(int(s), 0) if typeof(s) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(s)) else 0
				slot.done = ProgressData._bool(e.get("done"))
		out.append(slot)
	return out


## The goals the child can pick: every goal not on the board now, in list order.
static func choices(d: ProgressData) -> Array[StringName]:
	var out: Array[StringName] = []
	for g: Dictionary in GOALS:
		if not _on_board(d, g.id, -1) and available(g.id):
			out.append(g.id)
	return out


static func _on_board(d: ProgressData, id: StringName, except_slot: int) -> bool:
	for i in d.board.size():
		var slot: Dictionary = d.board[i]
		if i != except_slot and slot.goal == String(id) and not slot.done:
			return true
	return false


## Puts goal `id` in `slot` (replacing what was there, done or not), counting from now.
static func pick(d: ProgressData, slot: int, id: StringName) -> bool:
	if slot < 0 or slot >= SLOTS or not available(id) or _on_board(d, id, slot):
		return false
	if d.board.size() != SLOTS:
		d.board = clean_board(d.board)
	d.board[slot] = {"goal": String(id), "start": _count(d, goal(id)), "done": false}
	return true


## Vector2i(done so far, needed) for a slot; ZERO for an empty or unknown one.
static func progress(d: ProgressData, slot: int) -> Vector2i:
	if slot < 0 or slot >= d.board.size():
		return Vector2i.ZERO
	var s: Dictionary = d.board[slot]
	var g := goal(StringName(str(s.goal)))
	if g.is_empty():
		return Vector2i.ZERO
	var need := int(g.need)
	if s.done:
		return Vector2i(need, need)
	return Vector2i(clampi(_count(d, g) - int(s.start), 0, need), need)


## Marks goals that reached their number as done and returns them (each once).
static func check(d: ProgressData) -> Array[StringName]:
	var out: Array[StringName] = []
	for i in d.board.size():
		var s: Dictionary = d.board[i]
		if s.goal == "" or s.done:
			continue
		var p := progress(d, i)
		if p.y > 0 and p.x >= p.y:
			s.done = true
			out.append(StringName(str(s.goal)))
	return out


## Host: may a player's goal be paid now (the last paid at last_ms; -1 = never)?
static func host_allows(last_ms: int, now_ms: int) -> bool:
	return last_ms < 0 or now_ms - last_ms >= CLAIM_GAP_MS
