class_name DiscoveryRules
extends RefCounted
## Owner #132 (W1; docs/devlog/parts/play-w1.md): learning inside the world. Where it plays, when Professor Hoot comes
## to invite the child, and how few words a W1 screen shows (owner #133: "no one will start reading in the game": a
## child never has to read; every line is spoken, the screen shows pictures, numbers and at most a few words).
##
## - DISCOVER (the HUD's MORE and the pause menu) is in every world but Monster Wave's arena (a fight).
## - Hoot's invitation comes to home worlds only (not the arena, not space): on each world's first visit, and in a world
##   seen before at most once a day (the day he last came anywhere). His memory: {"worlds": {key: day}, "day": day},
##   the newest MAX_WORLDS worlds (DiscoveryLog keeps it on this device).

## How many worlds Hoot remembers (the oldest visit is forgotten first: a world that old gets him once more).
const MAX_WORLDS := 64
## Seconds the child has stood in the world (no menu over it) before Hoot comes: a moment to look round first.
const HOOT_AFTER := 20.0
## Seconds his card waits quietly before it fades (no countdown shows; nothing is lost).
const HOOT_STAYS := 30.0
## The most words a W1 screen shows while playing (owner #133); numbers and signs are not counted.
const MAX_SCREEN_WORDS := 4

## Hoot's lines, spoken by themselves (PlayVoice.say: Play G0's automatic voice). The headset's says where DISCOVER
## is there (MORE, on the raised arm's panel, or the pause menu).
const HOOT_LINE := "Hoo hoo! I'm Professor Hoot. Want to play a discovery game? Tap the magnifying glass!"
const HOOT_LINE_VR := "Hoo hoo! I'm Professor Hoot. Want to play a discovery game? Find the magnifying glass in MORE!"
## DISCOVER's word, spoken when a pointer or a controller's focus comes to it.
const DISCOVER_WORD := "Discover!"
## Spoken as DISCOVER opens.
const OPEN_LINE := "Let's discover!"
## Owner #133 (the lead, 2026-10-18): DISCOVER with no subject starts a game at once (Hoot's pick); this is said first.
const PICK_LINE := "Here's a game for you. Let's play!"
## The word under the picture.
const DISCOVER_LABEL := "DISCOVER"


## DISCOVER is offered in `mode`'s world of `universe`.
static func discover_here(mode: StringName, _universe: int) -> bool:
	return mode != ModeRules.WAVE


## Professor Hoot comes to invite the child in `mode`'s world of `universe` (home worlds only).
static func hoot_here(mode: StringName, universe: int) -> bool:
	return mode != ModeRules.WAVE and SpaceRules.is_home(universe)


## The world a save slot holds now (a new world in the slot has a new seed: a new world for Hoot).
static func world_key(slot: String, seed: int) -> String:
	return "%s:%d" % [slot, seed]


## Hoot comes now to `world` on `today`: its first visit, else when he has not come anywhere today.
static func hoot_due(seen: Dictionary, world: String, today: int) -> bool:
	var worlds := _worlds(seen)
	if not worlds.has(world):
		return true
	return _day(seen) < today


## Hoot's memory after he came to `world` on `today`.
static func after_hoot(seen: Dictionary, world: String, today: int) -> Dictionary:
	var worlds := _worlds(seen).duplicate()
	worlds.erase(world)
	worlds[world] = today   # the newest last
	while worlds.size() > MAX_WORLDS:
		var oldest: String = ""
		var oldest_day := 0
		for k: String in worlds:
			if oldest == "" or int(worlds[k]) < oldest_day:
				oldest = k
				oldest_day = int(worlds[k])
		worlds.erase(oldest)
	return {"worlds": worlds, "day": maxi(_day(seen), today)}


## The words a child would have to read in `text` (runs of letters; numbers and signs are not words to read).
static func word_count(text: String) -> int:
	var n := 0
	for part in text.split(" ", false):
		for ch in part:
			if ch.to_lower() != ch.to_upper():
				n += 1
				break
	return n


static func _worlds(seen: Dictionary) -> Dictionary:
	var w: Variant = seen.get("worlds", {})
	return w if w is Dictionary else {}


static func _day(seen: Dictionary) -> int:
	var d: Variant = seen.get("day", 0)
	return int(d) if (d is int or d is float) else 0
