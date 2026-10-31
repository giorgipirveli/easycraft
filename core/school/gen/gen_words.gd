class_name GenWords
extends RefCounted
## Owner #68 (grade 4 English, L.4.1g "Words that sound alike"): the sets of words that sound alike, what each means,
## and our own sentences with a blank for G4EnglishGen. A sentence's word is written as it appears there (a capital at
## the start). Add a sentence: [text with one ___, the word, the level (1: to/too/two, there/their; 2: they're,
## your/you're; 3: its/it's)].

const SETS: Array = [["to", "too", "two"], ["there", "their", "they're"], ["your", "you're"], ["its", "it's"]]
const SHORT := {"to": "to = towards", "too": "too = also, or more than enough", "two": "two = 2",
	"there": "there = a place", "their": "their = belongs to them", "they're": "they're = they are",
	"your": "your = belongs to you", "you're": "you're = you are", "its": "its = belongs to it", "it's": "it's = it is"}
const MEANINGS := {"to": "\"to\" means towards, or comes before a doing word", "too": "\"too\" means also, or more than enough",
	"two": "\"two\" is the number 2", "there": "\"there\" is a place, or starts \"there is\"",
	"their": "\"their\" means belonging to them", "they're": "\"they're\" is short for \"they are\"",
	"your": "\"your\" means belonging to you", "you're": "\"you're\" is short for \"you are\"",
	"its": "\"its\" means belonging to it", "it's": "\"it's\" is short for \"it is\""}

const SENTENCES: Array = [
	["Zara walked ___ the market.", "to", 1],
	["Pip wants ___ build a tower.", "to", 1],
	["Nell likes ___ read stories at night.", "to", 1],
	["We flew ___ the Moon and back.", "to", 1],
	["Mimi baked ___ cakes for the party.", "two", 1],
	["Bram has ___ dogs and a cat.", "two", 1],
	["Tilly sold ___ lanterns this morning.", "two", 1],
	["This soup is ___ hot to eat.", "too", 1],
	["The box is ___ heavy to lift.", "too", 1],
	["My buddy is sleepy ___.", "too", 1],
	["The treasure chest is over ___.", "there", 1],
	["___ is a cave behind the waterfall.", "There", 1],
	["Put the planks ___, by the door.", "there", 1],
	["The friends fed ___ pets.", "their", 1],
	["The bats flapped ___ wings.", "their", 1],
	["___ buddy can fly!", "Their", 1],
	["___ going to the beach today.", "They're", 2],
	["I think ___ lost in the forest.", "they're", 2],
	["The goats say ___ hungry.", "they're", 2],
	["Is this ___ hat?", "your", 2],
	["Wash ___ hands before dinner.", "your", 2],
	["Please bring ___ map.", "your", 2],
	["___ a great builder!", "You're", 2],
	["I think ___ right about the rule.", "you're", 2],
	["Tell me when ___ ready.", "you're", 2],
	["___ raining again.", "It's", 3],
	["___ time for bed.", "It's", 3],
	["I think ___ going to snow.", "it's", 3],
	["The dog wagged ___ tail.", "its", 3],
	["The dragon spread ___ wings.", "its", 3],
	["The robot lost ___ key.", "its", 3],
]


## The set a word belongs to (lower case), [] for none.
static func sets_of(word: String) -> Array:
	for s: Array in SETS:
		if s.has(word.to_lower()):
			return s
	return []


## "Remember: to = towards, too = also…, two = 2."
static func reminder(word: String) -> String:
	var parts: Array[String] = []
	for w: String in sets_of(word):
		parts.append(SHORT[w])
	return "Remember: %s." % ", ".join(parts)


## `word` with a capital first letter when `like` has one.
static func cased(word: String, like: String) -> String:
	return word.capitalize().left(1) + word.substr(1) if like.left(1) == like.left(1).to_upper() else word
