class_name AltarBeats
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.10, rulings 4, 5, 14, 15; the lead's rulings 2 and 6;
## future-lessons.md §3.5, invisible assessment): the game never asks a question to check; it judges each altar from how
## it was freed, and each judged altar becomes one SkillShown event for the room's unit. Pure, no nodes.
##
## - SOLVED (the model's "solved"): the child freed it with no rule break, no help and within its move budget
##   (AltarSolver.budget: a one-move altar in one move). Its event is AltarHalls.solved_kind: SOLVED in the hall,
##   NEW_SETTING for the Great Altar (the lead's ruling 6) and in a transfer room, noted with where.
## - HELPED: freed by the child after a rule break, over budget, or after help (the ghost's step, SHOW ME, H16's hint):
##   right, but not the first time (MasteryRules), noted with why (the misconceptions: "one pan", "carried across",
##   "unfair share", "no twin"; "over budget"; "ghost step", "eye", "hint").
## - SHOWN: the ghost freed it.
## Taught altars (the hall's 1, 2 and 5) are not judged: a refused move there is how the rule is met.

const OVER_BUDGET := "over budget"
const GREAT := "the Great Altar"

var room_id := ""
var unit := ""
## Every altar seen, in order: {n, form, judged, outcome, kind, counts, note, ops, budget}.
var results: Array[Dictionary] = []


static func for_room(id: String) -> AltarBeats:
	var b := AltarBeats.new()
	b.room_id = id
	b.unit = AltarHalls.unit(id)
	return b


## How an altar was freed, as the model says it: SOLVED, HELPED or SHOWN.
static func outcome(moves: AltarMoves) -> String:
	if not moves.freed() or moves.freed_by != AltarMoves.CHILD:
		return SkillShown.SHOWN
	var limit := AltarSolver.budget(AltarSolver.min_ops(moves.start_state, moves.tools))
	if moves.breaks == 0 and not moves.helped and moves.ops <= limit:
		return SkillShown.SOLVED
	return SkillShown.HELPED


## Judges one freed altar (`altar`: its catalogue entry) and keeps the result; a taught altar is seen, not judged.
func judge(altar: Dictionary, moves: AltarMoves) -> Dictionary:
	var how := outcome(moves)
	var limit := AltarSolver.budget(AltarSolver.min_ops(moves.start_state, moves.tools))
	var judged := not bool(altar.get("taught", false))
	var kind := how
	if how == SkillShown.SOLVED:
		kind = AltarHalls.solved_kind(room_id, altar)
	var why: Array[String] = []
	for n: String in moves.notes:
		if not why.has(n):
			why.append(n)
	if moves.freed_by == AltarMoves.CHILD and moves.ops > limit:
		why.append(OVER_BUDGET)
	for h: String in moves.helps:
		why.append(h)
	if why.is_empty() and kind == SkillShown.NEW_SETTING:
		why.append(AltarHalls.setting(room_id) if AltarHalls.is_transfer(room_id) else GREAT)
	var r := {"n": int(altar.get("n", 0)), "form": str(altar.get("form", "")), "judged": judged, "outcome": how,
		"kind": kind, "counts": judged and SkillShown.COUNTS.has(kind), "note": ", ".join(why), "ops": moves.ops,
		"budget": limit}
	results.append(r)
	return r


## The judged altars' results, in order.
func judged() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Dictionary in results:
		if bool(r.judged):
			out.append(r)
	return out


func total() -> int:
	return judged().size()


## The judged altars freed first time (SOLVED and NEW_SETTING: MasteryRules' "right the first time").
func right_first() -> int:
	return judged().filter(func(r: Dictionary) -> bool: return bool(r.counts)).size()


## The room's events reach MasteryRules' bar (at least 5 of every 6: the hall's 7 of 8, the Sky Room's 5 of 6).
func masters() -> bool:
	return MasteryRules.is_mastery(right_first(), total())


## Adds every judged altar's event to `shown` (the room's unit); how many were added.
func record(shown: SkillShown) -> int:
	var added := 0
	for r: Dictionary in judged():
		if shown.add(unit, str(r.kind), str(r.note)):
			added += 1
	return added
