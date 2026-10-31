class_name G4EnglishGen
extends RefCounted
## Owner #68 (spec §22.5): grade 4 English generators (Common Core L.4.1g, "Words that sound alike"): SchoolGen
## "g4e.<name>", `static func <name>(rng: RandomNumberGenerator, level: int) -> Dictionary`, seeded, level 1-3, each with
## a hint, a worked answer and `data`. The sentences are our own (GenWords).

const K := preload("res://core/school/gen/gen_kit.gd")


## "Choose the missing word: Zara walked ___ the market."
static func homophone_blank(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row := _sentence(rng, level)
	var sentence: String = row[0]
	var word: String = row[1]
	var choices: Array = []
	for w: String in GenWords.sets_of(word):
		choices.append(GenWords.cased(w, word))
	var ex := K.choice(rng, "Choose the missing word:  %s" % sentence, word, choices.filter(func(c: String) -> bool: return c != word),
		GenWords.reminder(word), "%s  (%s.)" % [sentence.replace("___", word), GenWords.MEANINGS[word.to_lower()]])
	ex.data = {"word": word}
	return ex


## "This sentence is written correctly: The bats flapped there wings." True or false?
static func homophone_check(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var row := _sentence(rng, level)
	var sentence: String = row[0]
	var word: String = row[1]
	var used := word
	if rng.randf() < 0.55:
		var others: Array = GenWords.sets_of(word).filter(func(w: String) -> bool: return w != word.to_lower())
		used = GenWords.cased(str(others[rng.randi_range(0, others.size() - 1)]), word)
	var shown := sentence.replace("___", used)
	var ex := K.truefalse("This sentence is written correctly:  \"%s\"" % shown, used == word, GenWords.reminder(word),
		"The right word is \"%s\": %s." % [word, GenWords.MEANINGS[word.to_lower()]])
	ex.data = {"word": word, "used": used}
	return ex


## A sentence of this level or an easier one (this level's sentences twice as often).
static func _sentence(rng: RandomNumberGenerator, level: int) -> Array:
	var pool: Array = []
	for row: Array in GenWords.SENTENCES:
		if int(row[2]) <= level:
			pool.append(row)
			if int(row[2]) == level:
				pool.append(row)
	return pool[rng.randi_range(0, pool.size() - 1)]
