class_name BotTalk
extends RefCounted
## Who of the child's bot friends hears the child's words, who answers and who does what was asked (owner
## feedback #38, spec §12.14a), as pure rules. Only the child's own friends ever listen (a friend follows
## one child: BotFriend.leader_peer); the ones near the child hear everything, a friend named hears
## wherever it is, and calls ("come here", "help!", "where are you?") reach all of them. One friend
## answers for the group ("We're right behind you!"), the one the request is about when there is one
## (the builder for a build, the explorer for treasure); "where are you?" is answered by each.
## A friend is {name, leader, pos, personality, up (not knocked out)}.

const HEAR_RADIUS := 32.0         # the child's friends this close (sideways) hear them
## Heard by all the child's friends, wherever they are.
const CALLS: Array[StringName] = [BotIntents.FOLLOW, BotIntents.HELP, BotIntents.WHERE_ARE_YOU]
## The personality a request is about: that friend answers (and does it).
const PREFERS := {BotIntents.BUILD: BotRules.BUILDER, BotIntents.TREASURE: BotRules.EXPLORER,
	BotIntents.WHERE_TILLY: BotRules.EXPLORER, BotIntents.FIGHT: BotRules.FIGHTER}
## Everyone who hears does these.
const EVERYONE_ACTS: Array[StringName] = [BotIntents.FOLLOW, BotIntents.WAIT, BotIntents.HOME, BotIntents.SPACE,
	BotIntents.HELP, BotIntents.HIDE, BotIntents.DANCE, BotIntents.FIGHT, BotIntents.LOOK]
## One friend does these: the one the request is about (a builder builds, an explorer leads; with none
## near, the nearest friend tries), so a child gets one house, not three.
const ONE_ACTS: Array[StringName] = [BotIntents.BUILD, BotIntents.TREASURE, BotIntents.RACE, BotIntents.WHERE_TILLY]
## Each friend answers these itself.
const EACH_ANSWERS: Array[StringName] = [BotIntents.WHERE_ARE_YOU]
## Nothing to answer.
const SILENT: Array[StringName] = [BotIntents.ACK]


## The friends (indices into `bots`) who hear `parsed` (BotIntents.parse) from player `peer` standing at `child`.
static func listeners(parsed: Dictionary, peer: int, child: Vector3, bots: Array) -> Array[int]:
	var out: Array[int] = []
	var named := str(parsed.get("target", ""))
	for i in bots.size():
		var b: Dictionary = bots[i]
		if int(b.get("leader", -1)) != peer or not b.get("up", true):
			continue
		if named != "":
			if str(b.get("name", "")) == named:
				out.append(i)
			continue
		if CALLS.has(parsed.get("intent", &"")) or _flat(b.get("pos", Vector3.INF), child) <= HEAR_RADIUS:
			out.append(i)
	return out


## The friend who answers for the group: the one of the personality the request is about, else the nearest
## to the child; -1 when nobody hears.
static func answerer(intent: StringName, hearing: Array[int], bots: Array, child: Vector3) -> int:
	var best := -1
	var best_score := INF
	for i in hearing:
		var b: Dictionary = bots[i]
		var score := _flat(b.get("pos", Vector3.INF), child)
		if PREFERS.has(intent) and b.get("personality") == PREFERS[intent]:
			score -= 10000.0
		if score < best_score:
			best_score = score
			best = i
	return best


## The friends who do what was asked.
static func actors(intent: StringName, hearing: Array[int], bots: Array, child: Vector3) -> Array[int]:
	if EVERYONE_ACTS.has(intent):
		return hearing.duplicate()
	var out: Array[int] = []
	if ONE_ACTS.has(intent):
		var one := answerer(intent, hearing, bots, child)
		if one >= 0:
			out.append(one)
	return out


## The friends who answer in words.
static func speakers(intent: StringName, hearing: Array[int], bots: Array, child: Vector3) -> Array[int]:
	if SILENT.has(intent) or hearing.is_empty():
		return [] as Array[int]
	if EACH_ANSWERS.has(intent):
		return hearing.duplicate()
	return [answerer(intent, hearing, bots, child)] as Array[int]


## Words the bots don't understand get a kind hint when they were meant for the bots: always when the child
## is alone in the world, else only when a friend was named (chat between people is never interrupted).
static func wants_hint(parsed: Dictionary, others_present: bool) -> bool:
	return parsed.get("intent") == BotIntents.UNKNOWN and (not others_present or str(parsed.get("target", "")) != "")


static func _flat(a: Vector3, b: Vector3) -> float:
	if not a.is_finite() or not b.is_finite():
		return INF
	return Vector2(a.x - b.x, a.z - b.z).length()
