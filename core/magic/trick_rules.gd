class_name TrickRules
extends RefCounted
## Tricks (M3 Task 20b, spec §14.21, research P2 "the buddy that learns your dance"): a child who does the same
## emote three times near their own buddy or pet teaches it that emote; afterwards, whenever they do it near it,
## it does its own version (a dance, a spin, a wave, a hop, a sit, a bow). Learned tricks are saved with the
## creature and never forgotten; there are no timers (research guard: no "practise every day"). Pure.
## A creature's state: {"learned": Array of emote Strings, "lessons": {emote String: count}}.

const TEACH_NEED := 3
## Creatures this close to the child (blocks) watch and learn.
const TEACH_RANGE := 8.0

const LEARNED := &"learned"       # this lesson taught it
const KNOWN := &"known"           # it knows it already: it does it with the child
const PRACTICE := &"practice"     # one more lesson counted

# What it does (Buddy.do_trick, Animal.do_trick).
const DANCE := &"dance"
const SPIN := &"spin"
const WAVE := &"wave"
const HOP := &"hop"
const SIT := &"sit"
const BOW := &"bow"
const MOVES: Array[StringName] = [DANCE, SPIN, WAVE, HOP, SIT, BOW]
const _MOVE_OF := {&"dance_hop": DANCE, &"dance_robot": DANCE, &"victory": DANCE, &"dance_star": SPIN, &"cheer": SPIN,
	&"wave": WAVE, &"clap": HOP, &"laugh": HOP, &"thumbs_up": HOP, &"sit": SIT, &"bow": BOW}


## What a creature does for `emote` (DANCE for an emote it has no move of its own for).
static func move_of(emote: StringName) -> StringName:
	return _MOVE_OF.get(emote, DANCE)


## One emote done near the creature: LEARNED (the third time), KNOWN (already learned), PRACTICE (counted), or &""
## for an unknown emote. Changes `state`.
static func lesson(state: Dictionary, emote: StringName) -> StringName:
	if not EmotePoses.has(emote):
		return &""
	if knows(state, emote):
		return KNOWN
	var lessons: Dictionary = state.get("lessons", {})
	var n := int(lessons.get(String(emote), 0)) + 1
	if n >= TEACH_NEED:
		lessons.erase(String(emote))
		var list: Array = state.get("learned", [])
		list.append(String(emote))
		state["learned"] = list
		state["lessons"] = lessons
		return LEARNED
	lessons[String(emote)] = n
	state["lessons"] = lessons
	return PRACTICE


static func knows(state: Dictionary, emote: StringName) -> bool:
	return (state.get("learned", []) as Array).has(String(emote))


static func lessons_of(state: Dictionary, emote: StringName) -> int:
	return int((state.get("lessons", {}) as Dictionary).get(String(emote), 0))


## The emotes learned (what is saved).
static func learned(state: Dictionary) -> Array:
	return (state.get("learned", []) as Array).duplicate()


## A state from saved emotes (lessons half done are not saved).
static func state_from(saved: Variant) -> Dictionary:
	return {"learned": clean(saved), "lessons": {}}


## Known emotes from a save, once each.
static func clean(v: Variant) -> Array:
	var out: Array = []
	if not v is Array:
		return out
	for e: Variant in v:
		if e is String and EmotePoses.has(StringName(e)) and not out.has(e):
			out.append(e)
	return out


## What a creature learned, by its move (whole sentences: they translate as they are).
const LEARNED_WORDS := {DANCE: "%s learned to dance!", SPIN: "%s learned to spin!", WAVE: "%s learned to wave!",
	HOP: "%s learned to hop!", SIT: "%s learned to sit!", BOW: "%s learned to bow!"}


static func learned_words(creature_name: String, emote: StringName) -> String:
	return Lang.t(LEARNED_WORDS[move_of(emote)]) % creature_name


## After `lessons` of TEACH_NEED.
static func practice_words(creature_name: String, lessons: int) -> String:
	return Lang.t("%s is watching you... %d more!") % [creature_name, maxi(TEACH_NEED - lessons, 1)]
