class_name Lang
extends RefCounted
## The game's words are English, and only English (owner feedback #52, 2026-09-25: "please dont build game in
## georgian, i didnt ask it. remove it from game and never include"; M3 Task 21a's Georgian translation and its
## LANGUAGE choice were removed). No translation is registered, so tr() and Lang.t() give the English back; they stay
## where M3 Task 21a put them (a line filled in with % is still built from whole sentences).

const ENGLISH := "en"


## The game speaks English (the locale every Control and tr() follows).
static func apply() -> void:
	TranslationServer.set_locale(ENGLISH)


## The language the game speaks: always English.
static func current() -> String:
	return ENGLISH


## `text` as the game says it (English: no translation is registered).
static func t(text: String) -> String:
	return String(TranslationServer.translate(text))


## The English "a" or "an" before `thing`.
static func article(thing: String) -> String:
	return "an" if "AEIOU".contains(thing.left(1).to_upper()) else "a"


## The English plural "s" after a number: none after 1.
static func plural_s(n: int) -> String:
	return "" if n == 1 else "s"


## A count of blocks: "1 block", "12 blocks" (M3 Task 19: never "1 blocks").
static func blocks(n: int) -> String:
	return "1 block" if n == 1 else "%d blocks" % n
