class_name SkillShown
extends RefCounted
## Owner #134 (docs/design/future-lessons.md §3.5, invisible assessment; ruling 3: no quiz screens in games): the bridge
## from what a game saw the child do to the School's record. A game never asks a question to check learning: it tells
## what the child showed, one event per challenge it judged (a level solved, a customer served fairly, a crystal freed),
## and `record` turns each unit's events into a round exactly as MasteryRules counts one: stars, the unit's gold once,
## spaced reviews, the grown-ups' page (it reads the same progress), a friend's reward (InviteData), a proud moment for a
## postcard and learning together (SocialSender). The School's own rounds and the play arena record through it too.
##
##     var shown := SkillShown.begin()                       # one per play session
##     shown.add("g4.maths.add_fractions", SkillShown.SOLVED) # each challenge the game judged, as it ends
##     SkillShown.pay_first_try(profile, today)              # an answer right the first time: the School's gold, capped
##     var results := shown.record(profile, today, save)     # at the end: {unit id: result}, saved once
##
## Kinds (KINDS):
## - SOLVED: solved with no help (no hint, no ghost step, no SHOW ME, no shown answer). The game's own trying on the way
##   is fine (a scale that tips, a cake that comes out lopsided): the game decides what one challenge is. Counts.
## - NEW_SETTING: solved with no help in a setting the child had not met (transfer, future-lessons.md §2). Counts, and
##   is kept apart (`result.transfer`).
## - HELPED: solved after a hint, the ghost or SHOW ME. Doesn't count.
## - SHOWN: the game showed the answer. Doesn't count.
## A unit's round needs ROUND_SIZE events to change a unit not mastered yet (a minute of three right is not a mastered
## unit: nothing is recorded, `recorded` false); fewer events of a mastered unit count as its review.

const SOLVED := "solved"
const NEW_SETTING := "new_setting"
const HELPED := "helped"
const SHOWN := "shown"
const KINDS: Array[String] = [SOLVED, NEW_SETTING, HELPED, SHOWN]
const COUNTS: Array[String] = [SOLVED, NEW_SETTING]

## {unit id: [{kind, note}]}, in the order the units were first shown.
var events := {}
var _order: Array[String] = []


static func begin() -> SkillShown:
	return SkillShown.new()


## One challenge the game judged for `unit_id` (one of KINDS; `note` says where, for the game's own notes). False (and
## nothing kept) for an unknown kind or no unit.
func add(unit_id: String, kind: String, note: String = "") -> bool:
	if unit_id == "" or not KINDS.has(kind):
		return false
	if not events.has(unit_id):
		events[unit_id] = []
		_order.append(unit_id)
	(events[unit_id] as Array).append({"kind": kind, "note": note})
	return true


func units() -> Array[String]:
	return _order.duplicate()


func total(unit_id: String) -> int:
	return (events.get(unit_id, []) as Array).size()


## The events that count (SOLVED and NEW_SETTING): MasteryRules' "right the first time".
func right_first(unit_id: String) -> int:
	return (events.get(unit_id, []) as Array).filter(func(e: Dictionary) -> bool: return COUNTS.has(str(e.kind))).size()


func transfer(unit_id: String) -> int:
	return (events.get(unit_id, []) as Array).filter(func(e: Dictionary) -> bool: return str(e.kind) == NEW_SETTING).size()


## Every unit's events recorded (`record_round`), then `save` called once when anything changed: {unit id: result}.
func record(profile: ProfileData, today: int, save: Callable = Callable()) -> Dictionary:
	var out := {}
	var changed := false
	var first_unit := false
	for id in _order:
		var r := record_round(profile, id, right_first(id), total(id), today)
		r.transfer = transfer(id)
		out[id] = r
		changed = changed or bool(r.recorded)
		first_unit = first_unit or bool(r.first_unit)
	if changed and save.is_valid():
		save.call()
	if first_unit:
		InviteSender.send_soon()   # after the save: the friend's reward goes to the server
	return out


## A unit's round of `total` challenges with `right_first` solved with no help, on `today` (the caller saves; when
## `first_unit`, InviteSender.send_soon() after saving): MasteryRules.after_round's result (progress, stars, mastered_now,
## remembered_now, pay) and `recorded`, `moment` (a proud moment for a postcard, {} for none), `first_unit` (a friend's
## reward is due). Too few challenges for a unit not mastered yet: nothing changes (`recorded` false).
static func record_round(profile: ProfileData, unit_id: String, right_first: int, total: int, today: int) -> Dictionary:
	var p := profile.school.progress(unit_id)
	if total <= 0 or (total < MasteryRules.ROUND_SIZE and MasteryRules.stars(p) < MasteryRules.MASTERED):
		var none := MasteryRules.after_round(p, 0, 0, today)
		none.recorded = false
		none.moment = {}
		none.first_unit = false
		return none
	var r := MasteryRules.after_round(p, right_first, total, today)
	profile.school.set_progress(unit_id, r.progress)
	if r.pay:
		EarnRules.credit(profile, EarnRules.UNIT_GOLD)
	r.recorded = true
	r.first_unit = bool(r.pay) and profile.invite.note_learned(today)   # owner #79: a friend's reward, once
	r.moment = {}
	if r.pay:   # owner #81, #82: a proud moment for a postcard and friends' cheers
		r.moment = moment_of(profile, unit_id)
		SocialSender.moment(r.moment, profile)
	SocialSender.learned(unit_id if r.pay else "", profile)   # owner #85: learning together
	return r


## The unit just mastered, or its whole grade's subject when that was the last one (the bigger moment).
static func moment_of(profile: ProfileData, unit_id: String) -> Dictionary:
	var u := Curriculum.unit(unit_id)
	var g := int(u.get("grade", 0))
	var subject := str(u.get("subject", ""))
	var written: Array[String] = []
	for x: Dictionary in Curriculum.units(g, subject):
		if Curriculum.has_content(str(x.id)) and not SpendRules.is_bonus(x):
			written.append(str(x.id))
	if not written.is_empty() and written.has(unit_id) and MasteryRules.all_mastered(profile.school, written):
		return PostcardRules.grade(g, subject)
	return PostcardRules.unit(unit_id, str(u.get("title", "")))


## An answer right the first time: the School's answer gold (EarnRules), within the day's cap; what was paid (the
## caller saves).
static func pay_first_try(profile: ProfileData, today: int) -> int:
	return EarnRules.answer_gold(profile, today)
