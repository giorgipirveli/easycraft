class_name CreatureData
extends RefCounted
## The planets' robots and aliens in the profile (owner #86, spec §21f; ProfileData.creatures): the aliens this child
## met and befriended, the one alien buddy who comes along (its mini-buddy record lives in BuddyMagicData.minis like a
## boss's mini: the buddy system), the robots' quiz questions already paid (EarnRules.FACT_QUIZ_GOLD once per question)
## and the souvenirs owned (bought at a camp or on the Gold Shop's shelf, or a friend's gift). Account-wide, parsed
## field by field (unknown ids dropped), kept by the server backup (merge_from never loses a friend, a paid question or
## a souvenir). Nothing here has a date or a clock.

const MAX_IDS := 256

## Aliens met (CreatureWords.ALIENS ids, as Strings), in the order met.
var met: Array[String] = []
## Aliens befriended, in the order.
var friends: Array[String] = []
## The friend who comes along into every world ("" = none): one at a time (spec §21f).
var buddy := ""
## Quiz questions whose gold was paid (CreatureWords question ids).
var quiz: Array[String] = []
## Souvenirs owned (CreatureWords.SOUVENIRS ids).
var souvenirs: Array[String] = []


func is_empty() -> bool:
	return met.is_empty() and friends.is_empty() and buddy == "" and quiz.is_empty() and souvenirs.is_empty()


## Met `id` for the first time: true.
func meet(id: StringName) -> bool:
	return _add(met, String(id), CreatureWords.ALIENS.has(id))


func has_met(id: StringName) -> bool:
	return met.has(String(id))


## Befriended `id` (met too): true the first time.
func befriend(id: StringName) -> bool:
	meet(id)
	return _add(friends, String(id), CreatureWords.ALIENS.has(id))


func is_friend(id: StringName) -> bool:
	return friends.has(String(id))


## The question's gold was paid: true the first time.
func pay_question(id: String) -> bool:
	return _add(quiz, id, CreatureWords.question_ids().has(id))


func paid(id: String) -> bool:
	return quiz.has(id)


## A souvenir is owned now: true the first time.
func add_souvenir(id: String) -> bool:
	return _add(souvenirs, id, CreatureWords.SOUVENIRS.has(id))


func owns(id: String) -> bool:
	return souvenirs.has(id)


func to_dict() -> Dictionary:
	return {"met": met.duplicate(), "friends": friends.duplicate(), "buddy": buddy, "quiz": quiz.duplicate(),
		"souvenirs": souvenirs.duplicate()}


static func from_dict(v: Variant) -> CreatureData:
	var d := CreatureData.new()
	if not v is Dictionary:
		return d
	var src: Dictionary = v
	for id: String in _strings(src.get("met")):
		d.meet(StringName(id))
	for id: String in _strings(src.get("friends")):
		d.befriend(StringName(id))
	for id: String in _strings(src.get("quiz")):
		d.pay_question(id)
	for id: String in _strings(src.get("souvenirs")):
		d.add_souvenir(id)
	var b: Variant = src.get("buddy")
	if b is String and d.friends.has(b):
		d.buddy = b
	return d


## Keeps the best of both copies: every alien met and befriended, every paid question and souvenir; this copy's buddy,
## else the other's (a friend of this copy's).
func merge_from(other: CreatureData) -> void:
	for id in other.met:
		meet(StringName(id))
	for id in other.friends:
		befriend(StringName(id))
	for id in other.quiz:
		pay_question(id)
	for id in other.souvenirs:
		add_souvenir(id)
	if buddy == "" and friends.has(other.buddy):
		buddy = other.buddy


static func _strings(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for e: Variant in v:
			if e is String or e is StringName:
				out.append(String(e))
	return out


static func _add(list: Array[String], id: String, known: bool) -> bool:
	if not known or id == "" or list.has(id) or list.size() >= MAX_IDS:
		return false
	list.append(id)
	return true
