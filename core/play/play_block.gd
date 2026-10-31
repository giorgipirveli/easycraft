class_name PlayBlock
extends RefCounted
## Owner #122 (docs/design/learning-is-play.md §4, §7; DEVELOPMENT.md "The play block"): a unit's optional `play` block,
## how units are written play-first from now:
##   "play": {
##     "hook": the problem that appears in the place (at most MAX_HOOK letters; read in 15 s),
##     "game": "generic" (the default: the generic mechanics, P0) or a signature game's id (P1 once it is built),
##     "params": {"maker": one of MAKERS (Make it's things), "costume": one of COSTUMES (Choose by doing's way)},
##     "coach": the coach's lines, one idea each, at most MAX_COACH_WORDS words (1-MAX_COACH lines),
##     "world_task": a real task in the open world (at most MAX_TASK letters)
##   }
## Every field may be left out; a unit without a block plays its exercises through the generic mechanics by type, with
## the hook of its main mechanic, coach lines taken from its cards (one short idea a card: never the "Quick memory"
## question or the world card) and the world task from its "Try it in the world" card.

const KEYS: Array[String] = ["hook", "game", "params", "coach", "world_task"]
const MAX_HOOK := 160
const MAX_COACH_WORDS := 12
const MAX_COACH := 8
const MAX_TASK := 220
## Make it's things (PlayMake): unit cubes in a tower, base-ten blocks, coins, fraction bars, a frog's jumps on a number
## line, cups of water in a jug, weights on a scale, digit wheels.
const MAKERS: Array[String] = ["tower", "base_ten", "coins", "fraction", "frog", "jug", "scale", "dial"]
## Choose by doing's ways (PlayChoose): give the right thing to the buddy, or take the right path to the gate.
const COSTUMES: Array[String] = ["give", "path"]
const GENERIC := "generic"
const WORLD_CARD := "Try it in the world:"
const MEMORY_CARD := "Quick memory"
## Sentences that start with these lean on the card before them ("It can be a street…"): never a coach line alone.
const LEANING: Array[String] = ["it", "they", "this", "these", "that", "those", "he", "she", "its", "their", "his", "her",
	"so", "but", "and", "then", "here", "there"]

## "" problems for a good block (or none at all); otherwise what is wrong, each in a few words.
static func problems(play: Variant) -> Array[String]:
	var out: Array[String] = []
	if play == null:
		return out
	if not play is Dictionary:
		return ["play must be an object"]
	var p: Dictionary = play
	for k: Variant in p:
		if not KEYS.has(str(k)):
			out.append("play: unknown field %s (%s)" % [k, ", ".join(KEYS)])
	if p.has("hook") and (not p.hook is String or str(p.hook).strip_edges() == "" or str(p.hook).length() > MAX_HOOK):
		out.append("play: the hook is words of at most %d letters" % MAX_HOOK)
	if p.has("game") and not p.game is String:
		out.append("play: game is a name (\"generic\" or a signature game's)")
	if p.has("params"):
		if not p.params is Dictionary:
			out.append("play: params is an object")
		else:
			var params: Dictionary = p.params
			if params.has("maker") and not MAKERS.has(str(params.maker)):
				out.append("play: maker is one of %s" % ", ".join(MAKERS))
			if params.has("costume") and not COSTUMES.has(str(params.costume)):
				out.append("play: costume is one of %s" % ", ".join(COSTUMES))
	if p.has("coach"):
		if not p.coach is Array or (p.coach as Array).is_empty() or (p.coach as Array).size() > MAX_COACH:
			out.append("play: coach is a list of 1-%d lines" % MAX_COACH)
		else:
			for line: Variant in p.coach:
				if not line is String or str(line).strip_edges() == "" or words(str(line)) > MAX_COACH_WORDS:
					out.append("play: a coach line is one idea of at most %d words: %s" % [MAX_COACH_WORDS, line])
	if p.has("world_task") and (not p.world_task is String or str(p.world_task).strip_edges() == ""
			or str(p.world_task).length() > MAX_TASK):
		out.append("play: the world task is words of at most %d letters" % MAX_TASK)
	return out


static func of(content: Dictionary) -> Dictionary:
	var p: Variant = content.get("play")
	return p if p is Dictionary else {}


static func params(content: Dictionary) -> Dictionary:
	var p: Variant = of(content).get("params")
	return p if p is Dictionary else {}


## The problem that appears in the place: the unit's own hook, else its main mechanic's.
static func hook(content: Dictionary) -> String:
	var h := str(of(content).get("hook", "")).strip_edges()
	if h != "":
		return h
	var main := PlayMechanics.main_of(content)
	return PlayMechanics.hook_of(main if main != "" else "choose")


## The coach's lines (see why): the block's, else one short idea from each card, else the unit's first goal.
static func coach(content: Dictionary, unit: Dictionary = {}) -> Array[String]:
	var out: Array[String] = []
	var own: Variant = of(content).get("coach")
	if own is Array:
		for l: Variant in own:
			if l is String and str(l).strip_edges() != "":
				out.append(str(l).strip_edges())
	if out.is_empty():
		out = derived_coach(content.get("lesson", []))
	if out.is_empty():
		var goals: Variant = unit.get("goals", [])
		if goals is Array and not (goals as Array).is_empty():
			var g := str(goals[0]).strip_edges().trim_suffix(".")
			if g != "" and words(g) <= MAX_COACH_WORDS - 3:
				out.append("Now you can %s." % (g.left(1).to_lower() + g.substr(1)))
	return out


## One idea a card: its first sentence of 3 to MAX_COACH_WORDS words that stands alone (not a question, not a list,
## not leaning on the sentence before), never from the "Quick memory" card or the world card.
static func derived_coach(cards: Variant) -> Array[String]:
	var out: Array[String] = []
	if not cards is Array:
		return out
	for i in (cards as Array).size():
		var card: Variant = cards[i]
		if not card is Dictionary:
			continue
		var text := str((card as Dictionary).get("text", "")).strip_edges()
		if text.begins_with(MEMORY_CARD) or text.begins_with(WORLD_CARD) or text.contains(WORLD_CARD):
			continue
		var line := _first_idea(text)
		if line != "" and not out.has(line):
			out.append(line)
		if out.size() >= MAX_COACH:
			break
	return out


static func _first_idea(text: String) -> String:
	for s: String in sentences(text):
		var n := words(s)
		if n < 3 or n > MAX_COACH_WORDS or not (s.ends_with(".") or s.ends_with("!")) or s.contains("?"):
			continue
		if s.trim_suffix(".").contains(":"):
			continue
		var first := s.split(" ")[0].to_lower().trim_suffix(",")
		if LEANING.has(first):
			continue
		if s.count(",") * 3 >= n:   # a list ("Horses, bison, deer and mammoths.")
			continue
		return s
	return ""


## The real task in the open world: the block's, else the world card's words without its "Next:", else a way to teach it.
static func world_task(content: Dictionary, unit: Dictionary = {}) -> String:
	var own := str(of(content).get("world_task", "")).strip_edges()
	if own != "":
		return own
	for card: Variant in content.get("lesson", []):
		if not card is Dictionary:
			continue
		var text := str((card as Dictionary).get("text", ""))
		var at := text.find(WORLD_CARD)
		if at < 0:
			continue
		var task := text.substr(at + WORLD_CARD.length()).strip_edges()
		var next := task.find("Next:")
		if next >= 0:
			task = task.left(next).strip_edges()
		if task != "":
			return task.left(1).to_upper() + task.substr(1)
	var title := str(unit.get("title", "")).strip_edges()
	if title == "":
		return "Teach it: show a grown-up or a friend what you found out today."
	return "Teach it: show a grown-up or a friend what you found out about %s." % title.to_lower()


## The sentences of `text`, each ending at a full stop or "!" followed by a space (or at the end).
static func sentences(text: String) -> Array[String]:
	var out: Array[String] = []
	var start := 0
	for i in text.length():
		var ch := text[i]
		if (ch == "." or ch == "!") and (i == text.length() - 1 or text[i + 1] == " "):
			var s := text.substr(start, i + 1 - start).strip_edges()
			if s != "":
				out.append(s)
			start = i + 1
	var rest := text.substr(start).strip_edges()
	if rest != "":
		out.append(rest)
	return out


static func words(text: String) -> int:
	var n := 0
	for w in text.strip_edges().split(" ", false):
		n += 1
	return n
