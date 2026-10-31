class_name PlayReadless
extends RefCounted
## Owner #133 ("consider no one will start reading in the game … deliver education without just reading") and #134
## (docs/design/future-lessons.md §2's mute test, §6, §7): which of the School's challenges a child can play without
## reading a word, and what the rest owes (the reading debt).
## A challenge plays when:
## - its type's mechanic is kept (data/play/mechanics.json `status`): an action that is the answer (make a quantity,
##   order, connect, sort, put labels back, build, code, beat, mix, find). A written choice (WRITTEN_CHOICE) or a true-or-
##   false claim (CLAIM) is never dressed as a game: it stays in the School as it is;
## - every thing the child acts with (a card to sort, order, connect or put on a pin, and the bins) is a picture, a number
##   or a short name of at most `thing_words()` words (spoken when touched: PlayVoice), else LONG_THING;
## - its question, spoken, is short: at most `prompt_words()` words (one short sentence or two), else LONG_PROMPT.
## Numbers and symbols are not words (`words`: tokens with a letter). A unit plays (its page offers PLAY) when at least
## `min_round()` of its hand-written challenges play or one of its generators does (a generator never runs out: it plays
## when GEN_SAMPLES of its exercises at every level play).

const WRITTEN_CHOICE := "a written choice"
const CLAIM := "a true-or-false claim"
const LONG_PROMPT := "a long question"
const LONG_THING := "words to read on a thing"
const NO_GAME := "no game for its type"
const REASONS: Array[String] = [WRITTEN_CHOICE, CLAIM, LONG_PROMPT, LONG_THING, NO_GAME]
const GEN_SAMPLES := 3

static var _letter := RegEx.create_from_string("[A-Za-z]")
static var _gens := {}


static func _limits() -> Dictionary:
	var r: Variant = PlayMechanics.data().get("readless", {})
	return r if r is Dictionary else {}


static func thing_words() -> int:
	return int(_limits().get("thing_words", 3))


static func prompt_words() -> int:
	return int(_limits().get("prompt_words", 16))


static func min_round() -> int:
	return int(_limits().get("min_round", 3))


## At most this many words on the screen while a challenge is played (rule 0; PlayHud's caption and buttons).
static func screen_words() -> int:
	return int(_limits().get("screen_words", 7))


## The words in `text` a child would have to read: its tokens with a letter ("3/4" and "3,025 + 12" have none).
static func words(text: String) -> int:
	var n := 0
	for tok in text.split(" ", false):
		if _letter.search(tok) != null:
			n += 1
	return n


## The texts on the things a child acts with in `ex` (cards and bins); none for a quantity, a build, a robot, a beat, a
## colour or a point.
static func things(ex: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var keys: Array = []
	match str(ex.get("type", "")):
		"order":
			keys = ["items"]
		"sort":
			keys = ["items", "groups"]
		"match":
			keys = ["items", "matches"]
		"label":
			keys = ["labels"]
	for k: String in keys:
		var list: Variant = ex.get(k, [])
		if list is Array:
			for t: Variant in list:
				out.append(str((t as Dictionary).get("text", "")) if t is Dictionary else str(t))   # a picture: no words
	return out


## Why `ex` can't be played without reading (one of REASONS), or "" when it can.
static func why_not(ex: Dictionary) -> String:
	var type := str(ex.get("type", ""))
	if type == "choice":
		return WRITTEN_CHOICE
	if type == "truefalse":
		return CLAIM
	var m := PlayMechanics.of(type)
	if m == "" or str(PlayMechanics.entry(m).get("status", "kept")) != "kept":
		return NO_GAME
	for t in things(ex):
		if words(t) > thing_words():
			return LONG_THING
	if words(str(ex.get("prompt", ""))) > prompt_words():
		return LONG_PROMPT
	return ""


static func plays(ex: Dictionary) -> bool:
	return why_not(ex) == ""


## A generator plays when GEN_SAMPLES of its exercises at every level play (asked once, then kept).
static func generator_plays(gen_id: String) -> bool:
	if _gens.has(gen_id):
		return _gens[gen_id]
	var ok := SchoolGen.exists(gen_id)
	for level in [1, 2, 3]:
		for s in GEN_SAMPLES:
			if ok:
				var ex := SchoolGen.make(gen_id, 1009 * (s + 1) + level, level)
				ok = not ex.is_empty() and plays(ex)
	_gens[gen_id] = ok
	return ok


## `c` with only what plays: its playable hand-written challenges and generators (the unit itself is untouched). A
## unit whose play block names a built signature game (P1) also keeps what that game expresses.
static func content(c: Dictionary) -> Dictionary:
	var out := c.duplicate()
	var game := _game(c)
	var exercises: Array = []
	for ex: Variant in c.get("exercises", []):
		if ex is Dictionary and (plays(ex) or (game != "" and PlayMechanics.game_expresses(game, ex))):
			exercises.append(ex)
	out.exercises = exercises
	var gens: Array = []
	for g: Variant in c.get("generators", []):
		if g is Dictionary and generator_plays(str((g as Dictionary).get("gen", ""))):
			gens.append(g)
	out.generators = gens
	return out


## How many different challenges the unit plays (hand-written; a playable generator counts as never running out).
static func count(c: Dictionary) -> int:
	var p := content(c)
	return (p.exercises as Array).size()


## The unit is a game on its page (PLAY): enough of it plays without reading, or a signature game plays it (P1).
static func unit_plays(c: Dictionary) -> bool:
	if PlayMechanics.level(c) == PlayMechanics.P1:
		return true
	var p := content(c)
	return (p.exercises as Array).size() >= min_round() or not (p.generators as Array).is_empty()


## The built signature game the unit's play block names ("" for none).
static func _game(c: Dictionary) -> String:
	var play: Variant = c.get("play")
	var game := str((play as Dictionary).get("game", "")) if play is Dictionary else ""
	return game if PlayMechanics.signature_games().has(game) else ""


## The unit's reading debt: {playable, reading (hand-written challenges that need reading), why ({reason: count}),
## gens_playable, gens_reading, cards (the Book's cards: all words), card_words}.
static func debt(c: Dictionary) -> Dictionary:
	var why := {}
	var playable := 0
	var reading := 0
	var game := _game(c)
	for ex: Variant in c.get("exercises", []):
		if not ex is Dictionary:
			continue
		var r := "" if game != "" and PlayMechanics.game_expresses(game, ex) else why_not(ex)
		if r == "":
			playable += 1
		else:
			reading += 1
			why[r] = int(why.get(r, 0)) + 1
	var gp := 0
	var gr := 0
	for g: Variant in c.get("generators", []):
		if g is Dictionary:
			if generator_plays(str((g as Dictionary).get("gen", ""))):
				gp += 1
			else:
				gr += 1
	var cards := 0
	var card_words := 0
	for card: Variant in c.get("lesson", []):
		if card is Dictionary:
			cards += 1
			card_words += words(str((card as Dictionary).get("text", "")))
	return {"playable": playable, "reading": reading, "why": why, "gens_playable": gp, "gens_reading": gr,
		"cards": cards, "card_words": card_words}
