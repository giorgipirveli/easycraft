class_name BotIntents
extends RefCounted
## What a child means when talking to their bot friends (owner feedback #38, spec §12.14a), on the device:
## no internet, no big model. A small scored matcher reads English (owner #52: English only), so a child's own
## words work:
## 1. clean the words: lower case, accents, apostrophes, stretched letters ("folllow" = "follow"), chat
##    words ("u", "plz", "thx", "wyd"), filler words ("please", "the");
## 2. find each word in the word list: exactly, by its ending ("following" = "follow"), or as a small
##    typo (one or two letters off, by length: "bild" = "build", "gaurd" = "guard");
## 3. a bot's name at the start or the end talks to that bot only ("Mossy, follow me");
## 4. score every intent: its keywords and phrases found in the sentence, a question cue for questions;
##    "don't" / "stop" turns a request around ("don't follow me" = give me space);
## 5. the best score wins; too low is "unknown" (the bot gives a kind hint).
## Pure and cheap: a sentence costs well under a millisecond on the desktop.

const EN := &"en"

# Requests
const FOLLOW := &"follow"            # follow me, come here
const WAIT := &"wait"                # wait, stay, stop
const HOME := &"home"                # go home (wait at the child's bed)
const SPACE := &"space"              # give me space, don't follow me
const BUILD := &"build"              # build a house / a tower / a wall
const TREASURE := &"treasure"        # explore, find treasure or secrets, where is the treasure?
const FIGHT := &"fight"              # fight, guard me, protect me
const HIDE := &"hide"                # run away, hide
const DANCE := &"dance"              # dance, do a trick
const RACE := &"race"                # race me
const HELP := &"help"                # help!
# Questions
const WHERE_TILLY := &"where_tilly"
const DOING := &"doing"
const HEARTS := &"hearts"
const NIGHT := &"night"
const NAME := &"name"
const WHAT_CAN_I_SAY := &"what_can_i_say"
const WHERE_ARE_YOU := &"where_are_you"
const HOW_ARE_YOU := &"how_are_you"
# Friendly words
const HELLO := &"hello"
const THANKS := &"thanks"
const PRAISE := &"praise"
const BYE := &"bye"
const LOOK := &"look"
const ACK := &"ack"                  # ok, yes, no, lol: no answer needed
const UNKNOWN := &"unknown"
## Every intent; on a tie the earlier one wins.
const INTENTS: Array[StringName] = [SPACE, FOLLOW, WAIT, HOME, BUILD, TREASURE, FIGHT, HIDE, DANCE, RACE, HELP,
	WHERE_TILLY, DOING, HEARTS, NIGHT, NAME, WHAT_CAN_I_SAY, WHERE_ARE_YOU, HOW_ARE_YOU,
	HELLO, THANKS, PRAISE, BYE, LOOK, ACK, UNKNOWN]
const QUESTIONS: Array[StringName] = [TREASURE, WHERE_TILLY, DOING, HEARTS, NIGHT, NAME, WHAT_CAN_I_SAY,
	WHERE_ARE_YOU, HOW_ARE_YOU]
## Requests a "don't" / "stop" turns into "stop that, wait" (follow turns into "give me space").
const STOPPABLE: Array[StringName] = [HOME, BUILD, TREASURE, FIGHT, HIDE, DANCE, RACE, LOOK]

# What to build
const HOUSE := &"house"
const TOWER := &"tower"
const WALL := &"wall"
const TRICK := &"trick"              # a dance request that asks for a trick
const TRICK_WORDS: Array[String] = ["trick", "flip", "backflip", "spin"]

const MAX_CHARS := 120               # like the chat: longer text is cut before any work
const THRESHOLD := 3.0               # a lower best score is "unknown"
const QUESTION_BONUS := 1.0

## [weight, words]: keywords (one word) and phrases (words in a row). Written as a child spells them;
## stretched letters don't matter.
const EN_WORDS := {
	FOLLOW: [[4, "follow"], [1, "follow me"], [2, "come"], [1, "here"], [2, "come here"], [2, "come with me"],
		[2, "come on"], [2, "come back"], [2, "over here"], [3, "this way"], [1, "lets"], [3, "lets go"],
		[1, "with me"], [3, "keep up"], [2, "close"], [3, "stay close"], [3, "stick with me"], [3, "catch up"],
		[1, "walk"], [2, "walk with me"], [2, "get over here"]],
	WAIT: [[4, "wait"], [3, "stay"], [3, "stop"], [1, "wait here"], [1, "stay here"], [2, "wait for me"],
		[4, "stand still"], [2, "still"], [4, "dont move"], [4, "freeze"], [3, "hold on"], [3, "hang on"],
		[4, "stay put"], [2, "stay there"], [3, "halt"], [2, "pause"]],
	HOME: [[4, "home"], [4, "go home"], [1, "house"], [3, "go to my house"], [2, "my house"], [3, "go to bed"],
		[2, "bed"], [1, "back home"], [2, "your home"]],
	SPACE: [[5, "go away"], [6, "leave me alone"], [3, "alone"], [5, "back off"], [5, "give me space"], [4, "space"],
		[5, "too close"], [4, "not so close"], [3, "move away"]],
	BUILD: [[5, "build"], [2, "make"], [2, "house"], [3, "tower"], [3, "wall"], [3, "castle"], [3, "hut"],
		[2, "bridge"], [1, "blocks"], [2, "with my blocks"], [1, "next to me"], [4, "construct"], [2, "craft"],
		[1, "tall"], [1, "big"], [2, "fence"], [2, "pillar"]],
	TREASURE: [[4, "treasure"], [4, "secret"], [3, "find"], [2, "find treasure"], [5, "explore"], [4, "search"],
		[3, "hunt"], [4, "adventure"], [4, "discover"], [2, "chest"], [1, "gold"], [1, "diamond"], [2, "look for"],
		[1, "hidden"], [1, "cave"], [1, "where"], [5, "arrow"], [5, "quest"], [5, "quests"], [4, "story"]],   # owner #45a
	FIGHT: [[5, "fight"], [5, "attack"], [4, "kill"], [5, "protect"], [5, "guard"], [5, "defend"], [4, "keep me safe"],
		[2, "safe"], [2, "monster"], [2, "zombie"], [2, "goblin"], [2, "slime"], [3, "hit"], [2, "beat"],
		[4, "battle"], [2, "get that"], [2, "get them"]],
	HIDE: [[5, "hide"], [3, "run"], [3, "run away"], [5, "flee"], [4, "escape"]],
	DANCE: [[6, "dance"], [5, "trick"], [3, "spin"], [4, "flip"], [5, "backflip"], [3, "party"], [3, "celebrate"],
		[3, "sing"], [2, "show me"], [2, "show off"], [2, "jump"]],
	RACE: [[6, "race"], [2, "race me"], [3, "compete"], [3, "faster"], [3, "who is faster"], [3, "competition"]],
	HELP: [[5, "help"], [1, "help me"], [3, "save me"], [4, "sos"], [4, "stuck"], [2, "need help"], [3, "i need you"],
		[3, "emergency"]],
	WHERE_TILLY: [[6, "tilly"], [5, "trader"], [5, "shop"], [5, "store"], [4, "market"], [3, "buy"], [3, "sell"],
		[5, "merchant"], [2, "take me to"], [1, "where"], [5, "shopkeeper"], [2, "keeper"]],
	DOING: [[5, "doing"], [3, "what are you doing"], [4, "up to"], [2, "what are you"]],
	HEARTS: [[6, "heart"], [6, "hearts"], [5, "health"], [5, "hp"], [3, "lives"], [3, "life"], [2, "how many"],
		[3, "hurt"], [2, "how much"], [2, "my health"]],
	NIGHT: [[5, "night"], [4, "dark"], [2, "day"], [3, "time"], [2, "what time"], [1, "soon"], [2, "sun"],
		[2, "moon"], [3, "evening"], [4, "sunset"], [2, "go down"]],
	NAME: [[6, "name"], [3, "your name"], [6, "who are you"], [3, "called"]],
	WHAT_CAN_I_SAY: [[6, "what can you"], [6, "what can i"], [7, "can you help"], [6, "what do i say"],
		[5, "commands"], [5, "how do i talk"]],
	WHERE_ARE_YOU: [[7, "where are you"], [6, "cant see you"], [6, "cant find you"], [6, "where did you go"],
		[5, "are you there"]],
	HOW_ARE_YOU: [[7, "how are you"], [5, "are you ok"], [6, "how is it going"], [5, "how do you feel"],
		[3, "you ok"]],
	HELLO: [[5, "hi"], [5, "hello"], [4, "hey"], [5, "hiya"], [5, "howdy"], [5, "good morning"], [3, "yo"],
		[4, "sup"], [4, "greetings"], [4, "what is up"], [2, "friend"]],
	THANKS: [[6, "thanks"], [6, "thank"], [1, "thank you"]],
	PRAISE: [[6, "good job"], [6, "well done"], [3, "nice"], [4, "nice build"], [3, "great"], [4, "awesome"],
		[3, "cool"], [4, "amazing"], [3, "wow"], [2, "love"], [5, "love you"], [5, "best friend"], [3, "best"],
		[2, "good"], [4, "good bot"], [3, "smart"], [4, "you rock"], [5, "good game"], [3, "yay"],
		[5, "well played"], [2, "did great"], [3, "super"], [3, "fantastic"], [3, "brilliant"]],
	BYE: [[6, "bye"], [6, "goodbye"], [5, "see you"], [6, "good night"], [3, "later"], [5, "got to go"],
		[5, "have to go"]],
	LOOK: [[4, "look"], [2, "look at this"], [1, "look here"], [3, "watch"], [5, "check this out"],
		[3, "over there"], [2, "see this"]],
	ACK: [[3, "ok"], [3, "yes"], [3, "no"], [3, "lol"], [3, "haha"], [2, "hmm"], [3, "sure"], [3, "alright"],
		[3, "maybe"], [3, "idk"], [3, "fine"]],
}

## Chat words and common spellings -> what they mean (applied to single words).
const SLANG := {
	"u": "you", "ur": "your", "r": "are", "ya": "you", "yu": "you", "plz": "please", "pls": "please",
	"plez": "please", "pleas": "please", "thx": "thanks", "thnx": "thanks", "thanx": "thanks", "tnx": "thanks",
	"thnks": "thanks", "thks": "thanks", "ty": "thank you", "tysm": "thank you so much", "tq": "thank you",
	"gj": "good job", "wp": "well played", "gg": "good game", "cya": "see you", "cu": "see you", "bb": "bye bye",
	"wat": "what", "wut": "what", "wht": "what", "waht": "what", "wot": "what", "whats": "what is",
	"wats": "what is", "wheres": "where is", "wer": "where", "wher": "where", "whre": "where", "were": "where",
	"whare": "where", "hows": "how is", "whos": "who is", "hw": "how", "hwo": "how", "im": "i am",
	"youre": "you are", "w8": "wait", "gr8": "great", "l8r": "later", "2": "to", "4": "for", "n": "and",
	"cmon": "come on", "cmn": "come on", "com": "come", "cum": "come", "her": "here", "wanna": "want to",
	"gonna": "going to", "gotta": "got to", "hom": "home", "halp": "help", "gimme": "give me", "lemme": "let me", "whatcha": "what are you",
	"watcha": "what are you", "whatchu": "what are you", "wachu": "what are you", "wyd": "what are you doing",
	"wya": "where are you", "hru": "how are you", "yeah": "yes", "yea": "yes", "yep": "yes", "yup": "yes",
	"ye": "yes", "nah": "no", "nope": "no", "naw": "no", "okay": "ok", "okie": "ok", "oki": "ok", "k": "ok",
	"kk": "ok", "okey": "ok", "lmao": "lol", "hlp": "help", "flw": "follow", "fllw": "follow", "folo": "follow",
	"doin": "doing", "goin": "going", "nite": "night", "luv": "love", "gud": "good", "gd": "good",
}
## Dropped before matching (they change nothing).
const FILLER: Array[String] = ["please", "the", "a", "an", "just", "um", "uh", "really", "so", "oh", "some", "now",
	"right", "very"]
## Words that mean "all of you" at the start or the end (dropped: everyone near hears).
const ALL_WORDS: Array[String] = ["everyone", "everybody", "all", "guys", "friends", "bots", "yall", "team", "gang"]
## A name may follow one of these ("hey Pip, ...").
const GREETINGS: Array[String] = ["hi", "hey", "hello", "yo", "ok", "oh"]
const QUESTION_WORDS: Array[String] = ["where", "what", "how", "when", "who", "which", "why", "is", "are", "am",
	"can", "could", "will", "do", "does", "did"]
const NEGATORS: Array[String] = ["dont", "not", "never", "stop", "quit"]
## More words the matcher should know (so typos of them are fixed, and details can be read).
const MORE_WORDS: Array[String] = ["me", "my", "mine", "you", "your", "i", "to", "for", "is", "are", "am", "can",
	"could", "will", "do", "does", "did", "what", "how", "when", "who", "which", "why", "near", "beside", "next",
	"by", "stuff", "block", "have", "there", "please", "going", "want", "give", "let", "got", "and", "it", "this",
	"that", "something", "big", "tall", "small", "little", "somewhere", "around", "us", "them", "go", "back",
	# everyday words, so they are never "fixed" into a request ("like" is not "life")
	"like", "play", "fun", "game", "know", "think", "say", "tell", "bad", "food", "eat", "sleep", "cat", "dog", "pig",
	"cow", "was", "be", "sky", "blue", "red", "green", "pizza", "water", "tree", "hat", "mom", "dad", "school"]

## What to build: a word -> what it means.
const BUILD_WHAT := {"house": HOUSE, "hut": HOUSE, "home": HOUSE, "tower": TOWER, "castle": TOWER, "pillar": TOWER,
	"wall": WALL, "fence": WALL}

static var _word_re := RegEx.create_from_string("[\\p{L}\\p{N}]+")
static var _loaded := false
static var _en := {}                 # squeezed English word -> the word as written
static var _en_by_len := {}          # length -> [squeezed words] (typo search)
static var _entries: Array = []      # [intent, weight, lang, PackedStringArray of words]
static var _slang := {}              # squeezed -> [squeezed words]
static var _filler := {}
static var _all := {}
static var _greet := {}
static var _question := {}
static var _negators := {}
static var _weight := {}             # word key -> its biggest one-word weight (a request word wins a typo tie)
static var _by_first := {}           # lang + first word key -> entries starting with it
static var _memo := {}               # a word as typed -> what it was read as (children repeat their words)
const MEMO_MAX := 1024


## What `text` means: {intent, target (the bot named, "" for all near), question, what (HOUSE / TOWER / WALL / &""),
## mine (with my blocks), near (next to me), lang (always EN), score}. `names`: the child's own bots.
static func parse(text: String, names: Array[String] = []) -> Dictionary:
	_load()
	var raw := text.substr(0, MAX_CHARS)
	var toks := _tokens(raw)
	var target := _take_name(toks, names)
	_drop_all_words(toks)
	var question := raw.contains("?") or (not toks.is_empty() and _question.has(str(toks[0].c)))
	var scores := {}
	var seen := {}
	for t: Dictionary in toks:
		var first := "%s:%s" % [t.lang, t.c]
		if seen.has(first):
			continue
		seen[first] = true
		for e: Array in _by_first.get(first, []):
			var words: PackedStringArray = e[3]
			if not _has(toks, words, e[2]):
				continue
			scores[e[0]] = float(scores.get(e[0], 0.0)) + float(e[1])
	if question:
		for q in QUESTIONS:
			if scores.has(q):
				scores[q] = float(scores[q]) + QUESTION_BONUS
	var best: StringName = UNKNOWN
	var best_score := 0.0
	for intent in INTENTS:
		if float(scores.get(intent, 0.0)) > best_score:
			best = intent
			best_score = float(scores[intent])
	if best_score < THRESHOLD:
		best = UNKNOWN
	var turned := _negated(toks, best)
	if turned != &"":
		best = turned
		best_score = maxf(best_score, THRESHOLD)
	var out := {"intent": best, "target": target, "question": question, "what": &"", "mine": false, "near": false,
		"lang": EN, "score": best_score}
	if best == BUILD:
		_build_details(toks, out)
	elif best == DANCE and toks.any(func(t: Dictionary) -> bool: return TRICK_WORDS.has(str(t.word))):
		out.what = TRICK
	return out


## The cleaned words of `text` as the matcher reads them (each known word as written in the word list).
static func words(text: String) -> Array[String]:
	_load()
	var out: Array[String] = []
	for t: Dictionary in _tokens(text.substr(0, MAX_CHARS)):
		out.append(str(t.word))
	return out


## The key of one word as the word list stores it (lower case, stretched letters squeezed).
static func key(word: String) -> String:
	return _squeeze(word.to_lower())


# --- Words ---

static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	for k: String in SLANG:
		var parts := PackedStringArray()
		for p in str(SLANG[k]).split(" ", false):
			parts.append(_squeeze(p))
		_slang[_squeeze(k)] = parts
	for w in FILLER:
		_filler[_squeeze(w)] = true
	for w in ALL_WORDS:
		_all[_squeeze(w)] = true
	for w in GREETINGS:
		_greet[_squeeze(w)] = true
	for w in QUESTION_WORDS:
		_question[_squeeze(w)] = true
	for w in NEGATORS:
		_negators[_squeeze(w)] = true
	for w in MORE_WORDS:
		_add_en(w)
	for intent: StringName in EN_WORDS:
		for e: Array in EN_WORDS[intent]:
			var words := PackedStringArray()
			for w in str(e[1]).split(" ", false):
				if not _filler.has(_squeeze(w)):
					words.append(_add_en(w))
			_entries.append([intent, float(e[0]), EN, words])
	for e: Array in _entries:
		var words: PackedStringArray = e[3]
		if words.size() == 1:
			_weight[words[0]] = maxf(float(_weight.get(words[0], 0.0)), float(e[1]))
		var first := "%s:%s" % [e[2], words[0]]
		if not _by_first.has(first):
			_by_first[first] = []
		(_by_first[first] as Array).append(e)


static func _add_en(w: String) -> String:
	var s := _squeeze(w)
	if not _en.has(s):
		_en[s] = w
		if not _en_by_len.has(s.length()):
			_en_by_len[s.length()] = []
		(_en_by_len[s.length()] as Array).append(s)
	return s


## The words of `raw`, cleaned and looked up: [{c: the word's key, lang: EN / &"" (unknown), word, raw}].
static func _tokens(raw: String) -> Array[Dictionary]:
	var text := ChatRules.normalize(raw).replace("'", "").replace("’", "").replace("`", "")
	var out: Array[Dictionary] = []
	for m in _word_re.search_all(text):
		var w := m.get_string()
		var s := _squeeze(w)
		var parts: PackedStringArray = _slang.get(s, PackedStringArray([s]))
		for p in parts:
			if _filler.has(p):
				continue
			out.append(_remember(p, func() -> Dictionary: return _resolve_latin(p)))
	return out


## A word read before is read the same way again (a copy: callers take words out of their lists).
static func _remember(w: String, read: Callable) -> Dictionary:
	if not _memo.has(w):
		if _memo.size() >= MEMO_MAX:
			_memo.clear()
		_memo[w] = read.call()
	return (_memo[w] as Dictionary).duplicate()


## A word: English (exactly, by its ending or a small typo), else unknown.
static func _resolve_latin(s: String) -> Dictionary:
	if _en.has(s):
		return _en_token(s, s)
	var e := _find(s, _en, _en_by_len, 3, true)
	if e != "":
		return _en_token(e, s)
	return {"c": s, "lang": &"", "word": s, "raw": s}


static func _en_token(s: String, as_typed: String) -> Dictionary:
	return {"c": s, "lang": EN, "word": _en[s], "raw": as_typed}


## The known word `w` stands for: itself, a known word it starts with (an ending of at most `ending`
## letters: "following"), an English -ing word ("dancing" = "dance"), or a word one or two
## letters off (by length). "" when none.
static func _find(w: String, vocab: Dictionary, by_len: Dictionary, ending: int, english := false) -> String:
	if vocab.has(w):
		return w
	var best := ""
	for cut in range(1, ending + 1):
		var stem := w.substr(0, w.length() - cut)
		if stem.length() >= 4 and vocab.has(stem):
			best = stem
			break
	if best != "":
		return best
	if english and w.ends_with("ing") and w.length() >= 5:
		var stem := w.substr(0, w.length() - 3)
		if vocab.has(stem):
			return stem
		if vocab.has(stem + "e"):
			return stem + "e"
	if w.length() < 4:
		return ""
	var limit := 2 if w.length() >= 7 else 1
	var best_rank := INF
	for n in range(w.length() - limit, w.length() + limit + 1):
		for cand: String in by_len.get(n, []):
			if cand.length() < 3:
				continue
			var d := _osa(w, cand, limit)
			if d > limit:
				continue
			var rank := _typo_rank(w, cand, d)
			if rank < best_rank:
				best_rank = rank
				best = cand
	return best


## Ranks a typo's candidates (smaller is better): fewer letters off, then the same letters swapped ("wiat" is
## "wait", not "what"), then the same first letter, then a request word over a plain one ("halp" is "help").
static func _typo_rank(w: String, cand: String, d: int) -> float:
	var rank := d * 100.0
	if _sorted(w) != _sorted(cand):
		rank += 50.0
	if cand[0] != w[0]:
		rank += 20.0
	return rank - minf(float(_weight.get(cand, 0.0)), 9.0)


static func _sorted(w: String) -> String:
	var letters := Array(w.split(""))
	letters.sort()
	return "".join(PackedStringArray(letters))


## Has the sentence `words` (keys of language `lang`) in a row?
static func _has(toks: Array[Dictionary], words: PackedStringArray, lang: StringName) -> bool:
	var n := words.size()
	for i in toks.size() - n + 1:
		var ok := true
		for j in n:
			var t: Dictionary = toks[i + j]
			if t.lang != lang or t.c != words[j]:
				ok = false
				break
		if ok:
			return true
	return false


# --- Names, "all of you", "don't" ---

## Takes a bot's name off the start (or after a greeting) or the end: the bot it names, or "".
static func _take_name(toks: Array[Dictionary], names: Array[String]) -> String:
	if toks.is_empty() or names.is_empty():
		return ""
	var spots: Array[int] = [0]
	if toks.size() > 1 and _greet.has(str(toks[0].raw)):
		spots.append(1)
	spots.append(toks.size() - 1)
	for i in spots:
		var n := _name_of(toks[i], names)
		if n != "":
			toks.remove_at(i)
			return n
	return ""


static func _name_of(t: Dictionary, names: Array[String]) -> String:
	var raw := str(t.raw)
	var known: bool = t.lang != &""
	for n in names:
		var s := _squeeze(n.to_lower())
		if raw == s:
			return n
		if not known and s.length() >= 4 and raw.length() >= 4 and _osa(raw, s, 1) <= 1:
			return n
	return ""


static func _drop_all_words(toks: Array[Dictionary]) -> void:
	for i in [toks.size() - 1, 1, 0]:
		if i < toks.size() and i >= 0 and _all.has(str(toks[i].raw)):
			if i == 1 and not _greet.has(str(toks[0].raw)):
				continue
			toks.remove_at(i)


## "don't follow me" / "stop following me" = give me space; "don't build" / "stop dancing" = stop that.
static func _negated(toks: Array[Dictionary], best: StringName) -> StringName:
	for i in toks.size():
		if not _negators.has(str(toks[i].c)) and not _negators.has(str(toks[i].raw)):
			continue
		for j in range(i + 1, mini(i + 3, toks.size())):
			var hit := _intent_of_word(toks[j])
			if hit == FOLLOW:
				return SPACE
			if STOPPABLE.has(hit) and best != SPACE:
				return WAIT
	return &""


## The request a single word stands for (its best single-word entry), or &"".
static func _intent_of_word(t: Dictionary) -> StringName:
	if t.lang == &"":
		return &""
	var best: StringName = &""
	var best_w := 0.0
	for e: Array in _entries:
		var words: PackedStringArray = e[3]
		if words.size() == 1 and e[2] == t.lang and words[0] == t.c and float(e[1]) > best_w:
			best = e[0]
			best_w = float(e[1])
	return best if best_w >= 3.0 else &""


static func _build_details(toks: Array[Dictionary], out: Dictionary) -> void:
	var words: Array[String] = []
	for t in toks:
		words.append(str(t.word))
	for w in words:
		if BUILD_WHAT.has(w):
			out.what = BUILD_WHAT[w]
			break
	var said := " %s " % " ".join(words)
	out.mine = said.contains(" my blocks ") or said.contains(" my block ") or said.contains(" mine ") \
		or said.contains(" my stuff ")
	out.near = said.contains(" next to me ") or said.contains(" near me ") or said.contains(" by me ") \
		or said.contains(" beside me ") or said.contains(" here ")


# --- Spelling ---

## Runs of one letter become one letter ("folllooow" = "folow"; the word list is read the same way).
static func _squeeze(w: String) -> String:
	var out := ""
	var last := ""
	for ch in w:
		if ch != last:
			out += ch
		last = ch
	return out


## Letters to change, add, drop or swap to turn `a` into `b` (optimal string alignment); limit + 1 when more.
static func _osa(a: String, b: String, limit: int) -> int:
	var n := a.length()
	var m := b.length()
	if absi(n - m) > limit:
		return limit + 1
	var before: Array[int] = []
	var prev: Array[int] = []
	var cur: Array[int] = []
	before.resize(m + 1)
	prev.resize(m + 1)
	cur.resize(m + 1)
	for j in m + 1:
		prev[j] = j
	for i in range(1, n + 1):
		cur[0] = i
		var row_min := i
		for j in range(1, m + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			var v := mini(mini(prev[j] + 1, cur[j - 1] + 1), prev[j - 1] + cost)
			if i > 1 and j > 1 and a[i - 1] == b[j - 2] and a[i - 2] == b[j - 1]:
				v = mini(v, before[j - 2] + 1)
			cur[j] = v
			row_min = mini(row_min, v)
		if row_min > limit:
			return limit + 1
		var t := before
		before = prev
		prev = cur
		cur = t
	return prev[m]
